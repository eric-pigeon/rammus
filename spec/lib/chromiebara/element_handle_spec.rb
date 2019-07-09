module Chromiebara
  RSpec.describe ElementHandle, browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe '#bounding_box' do
      it 'returns the bounding box' do
        page.set_viewport width: 500, height: 500
        page.goto server.domain + 'grid.html'
        element_handle = page.query_selector '.box:nth-of-type(13)'
        box = element_handle.bounding_box
        expect(box).to eq(x: 100, y: 50, width: 50, height: 50)
      end

      it 'should handle nested frames' do
        page.set_viewport width: 500, height: 500
        page.goto server.domain + 'frames/nested-frames.html'
        nestedFrame = page.frames[1].child_frames[1]
        element_handle = nestedFrame.query_selector 'div'
        box = element_handle.bounding_box
        expect(box).to eq(x: 28, y: 260, width: 264, height: 18)
      end

      it 'should return nil for invisible elements' do
        await page.set_content '<div style="display:none">hi</div>'
        element = page.query_selector 'div'
        expect(element.bounding_box).to eq nil
      end

      it 'should force a layout' do
        page.set_viewport width: 500, height: 500
        await page.set_content '<div style="width: 100px; height: 100px">hello</div>'
        element_handle = page.query_selector 'div'
        await page.evaluate_function "element => element.style.height = '200px'", element_handle
        box = element_handle.bounding_box
        expect(box).to eq(x: 8, y: 8, width: 100, height: 200)
      end

      it 'should work with SVG nodes' do
        content = <<~HTML
        <svg xmlns="http://www.w3.org/2000/svg" width="500" height="500">
          <rect id="theRect" x="30" y="50" width="200" height="300"></rect>
        </svg>
        HTML
        await page.set_content content
        element = page.query_selector '#therect'
        pptr_bounding_box = element.bounding_box
        function = <<~JAVASCRIPT
        e => {
          const rect = e.getBoundingClientRect();
          return {x: rect.x, y: rect.y, width: rect.width, height: rect.height};
        }
        JAVASCRIPT
        web_bounding_box = await page.evaluate_function function, element
        web_bounding_box = web_bounding_box.map { |k, v| [k.to_sym, v] }.to_h
        expect(pptr_bounding_box).to eq web_bounding_box
      end
    end

    describe '#box_model' do
      it 'returns the box model' do
        page.goto server.domain + 'resetcss.html'

        # Step 1: Add Frame and position it absolutely.
        attach_frame page, 'frame1', server.domain + 'resetcss.html'
        function = <<~JAVASCRIPT
        () => {
          const frame = document.querySelector('#frame1');
          frame.style = `
            position: absolute;
            left: 1px;
            top: 2px;
          `;
        }
        JAVASCRIPT
        await page.evaluate_function function

        # Step 2: Add div and position it absolutely inside frame.
        frame = page.frames[1]
        function = <<~JAVASCRIPT
        () => {
          const div = document.createElement('div');
          document.body.appendChild(div);
          div.style = `
            box-sizing: border-box;
            position: absolute;
            border-left: 1px solid black;
            padding-left: 2px;
            margin-left: 3px;
            left: 4px;
            top: 5px;
            width: 6px;
            height: 7px;
          `;
          return div;
        }
        JAVASCRIPT
        div_handle = (await frame.evaluate_handle_function(function)).as_element

        # Step 3: query div's boxModel and assert box values.
        box = div_handle.box_model
        expect(box[:width]).to eq 6
        expect(box[:height]).to eq 7
        expect(box[:margin][0]).to eq({
          x: 1 + 4, # frame.left + div.left
          y: 2 + 5,
        })
        expect(box[:border][0]).to eq({
          x: 1 + 4 + 3, # frame.left + div.left + div.margin-left
          y: 2 + 5,
        })
        expect(box[:padding][0]).to eq({
          x: 1 + 4 + 3 + 1, # frame.left + div.left + div.marginLeft + div.borderLeft
          y: 2 + 5,
        })
        expect(box[:content][0]).to eq({
          x: 1 + 4 + 3 + 1 + 2, # frame.left + div.left + div.marginLeft + div.borderLeft + dif.paddingLeft
          y: 2 + 5,
        })
      end

      it 'should return null for invisible elements' do
        await page.set_content '<div style="display:none">hi</div>'
        element = page.query_selector 'div'
        expect(element.box_model).to eq nil
      end
    end

    describe '#content_frame' do
      it 'returns the frame' do
        page.goto server.empty_page
        attach_frame page, 'frame1', server.empty_page
        element_handle = page.query_selector '#frame1'
        frame = element_handle.content_frame
        expect(frame).to eq page.frames[1]
      end
    end

    describe '#click' do
      it 'click the element' do
        page.goto server.domain + 'input/button.html'
        button = page.query_selector 'button'
        button.click
        expect(await page.evaluate_function "() => result").to eq 'Clicked'
      end

      it 'should work for Shadow DOM v1' do
        page.goto server.domain + 'shadow.html'
        button_handle = await page.evaluate_handle_function "() => button"
        button_handle.click
        expect(await page.evaluate_function "() => clicked").to eq true
      end

      it 'should work for TextNodes' do
        page.goto server.domain + 'input/button.html'
        button_text_node = await page.evaluate_handle_function "() => document.querySelector('button').firstChild"
        expect { button_text_node.click }.to raise_error 'Node is not of type HTMLElement'
      end

      it 'should throw for detached nodes' do
        page.goto server.domain + 'input/button.html'
        button = page.query_selector 'button'
        await page.evaluate_function "button => button.remove()", button
        expect { button.click }. to raise_error 'Node is detached from document'
      end

      it 'should throw for hidden nodes' do
        page.goto server.domain + 'input/button.html'
        button = page.query_selector 'button'
        await page.evaluate_function "button => button.style.display = 'none'", button
        expect { button.click }.to raise_error 'Node is either not visible or not an HTMLElement'
      end

      it 'should throw for recursively hidden nodes' do
        page.goto server.domain + 'input/button.html'
        button = page.query_selector 'button'
        await page.evaluate_function "button => button.parentElement.style.display = 'none'", button
        expect { button.click }.to raise_error 'Node is either not visible or not an HTMLElement'
      end

      it 'should throw for <br> elements' do
        await page.set_content 'hello<br>goodbye'
        br = page.query_selector 'br'
        expect { br.click }.to raise_error 'Node is either not visible or not an HTMLElement'
      end
    end

    describe '#hover' do
      it 'hovers the element' do
        page.goto server.domain + 'input/scrollable.html'
        button = page.query_selector '#button-6'
        button.hover
        expect(await page.evaluate_function "() => document.querySelector('button:hover').id").to eq 'button-6'
      end
    end

    describe '#is_intersecting_viewport' do
      it 'should work' do
        page.goto server.domain + 'offscreenbuttons.html'
        11.times do |i|
          button = page.query_selector "#btn#{i}"
          # All but last button are visible.
          visible = i < 10
          expect(button.is_intersecting_viewport).to eq visible
        end
      end
    end
  end
end
