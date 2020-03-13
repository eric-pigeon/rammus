module Rammus
  RSpec.describe 'Screenshot', browser: true do
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe 'Page#screenshot' do
      it 'should work' do
        page.set_viewport width: 500, height: 500
        page.goto(server.domain + 'grid.html').wait!
        screenshot = page.screenshot
        expect(screenshot).to match_screenshot('screenshot-sanity.png')
      end

      it 'should clip rect' do
        page.set_viewport width: 500, height: 500
        page.goto(server.domain + 'grid.html').wait!
        screenshot = page.screenshot clip: { x: 50, y: 100, width: 150, height: 100 }
        expect(screenshot).to match_screenshot('screenshot-clip-rect.png')
      end

      it 'should work for offscreen clip' do
        pending 'not sure'
        page.set_viewport width: 500, height: 500
        page.goto(server.domain + 'grid.html').wait!
        screenshot = page.screenshot clip: { x: 50, y: 600, width: 100, height: 100 }
        expect(screenshot).to match_screenshot 'screenshot-offscreen-clip.png'
      end

      # TODO
      # it('should run in parallel', async({page, server}) => {
      #   await page.setViewport({width: 500, height: 500});
      #   await page.goto(server.PREFIX + '/grid.html');
      #   const promises = [];
      #   for (let i = 0; i < 3; ++i) {
      #     promises.push(page.screenshot({
      #       clip: {
      #         x: 50 * i,
      #         y: 0,
      #         width: 50,
      #         height: 50
      #       }
      #     }));
      #   }
      #   const screenshots = await Promise.all(promises);
      #   expect(screenshots[1]).toBeGolden('grid-cell-1.png');
      # });

      it 'should take full_page screenshots' do
        page.set_viewport width: 500, height: 500
        page.goto(server.domain + 'grid.html').wait!
        screenshot = page.screenshot full_page: true
        expect(screenshot).to match_screenshot 'screenshot-grid-fullpage.png'
      end

      # TODO
      #it('should run in parallel in multiple pages', async({page, server, context}) => {
      #  const N = 2;
      #  const pages = await Promise.all(Array(N).fill(0).map(async() => {
      #    const page = await context.newPage();
      #    await page.goto(server.PREFIX + '/grid.html');
      #    return page;
      #  }));
      #  const promises = [];
      #  for (let i = 0; i < N; ++i)
      #    promises.push(pages[i].screenshot({ clip: { x: 50 * i, y: 0, width: 50, height: 50 } }));
      #  const screenshots = await Promise.all(promises);
      #  for (let i = 0; i < N; ++i)
      #    expect(screenshots[i]).toBeGolden(`grid-cell-${i}.png`);
      #  await Promise.all(pages.map(page => page.close()));
      #});

      it 'should allow transparency' do
        page.set_viewport width: 100, height: 100
        page.goto(server.empty_page).wait!
        screenshot = page.screenshot omit_background: true
        expect(screenshot).to match_screenshot 'transparent.png'
      end

      # TODO need jpeg library
      #it_fails_ffox('should render white background on jpeg file', async({page, server}) => {
      #  await page.setViewport({ width: 100, height: 100 });
      #  await page.goto(server.EMPTY_PAGE);
      #  const screenshot = await page.screenshot({omitBackground: true, type: 'jpeg'});
      #  expect(screenshot).toBeGolden('white.jpg');
      #});

      it 'should work with odd clip size on Retina displays' do
        screenshot = page.screenshot clip: { x: 0, y: 0, width: 11, height: 11 }
        expect(screenshot).to match_screenshot 'screenshot-clip-odd-size.png'
      end

      it 'should return base64' do
        page.set_viewport width: 500, height: 500
        page.goto(server.domain + 'grid.html').wait!
        screenshot = page.screenshot encoding: 'base64'
        expect(Base64.decode64 screenshot).to match_screenshot 'screenshot-sanity.png'
      end
    end

    describe 'ElementHandle#screenshot' do
      it 'should work' do
        page.set_viewport width: 500, height: 500
        page.goto(server.domain + 'grid.html').wait!
        page.evaluate_function('() => window.scrollBy(50, 100)').wait!
        element_handle = page.query_selector '.box:nth-of-type(3)'
        screenshot = element_handle.screenshot
        expect(screenshot).to match_screenshot 'screenshot-element-bounding-box.png'
      end

      it 'should take into account padding and border' do
        page.set_viewport width: 500, height: 500
        content = <<~HTML
          something above
          <style>div {
            border: 2px solid blue;
            background: green;
            width: 50px;
            height: 50px;
          }
          </style>
          <div></div>
        HTML
        page.set_content(content).wait!
        element_handle = page.query_selector 'div'
        screenshot = element_handle.screenshot
        expect(screenshot).to match_screenshot 'screenshot-element-padding-border.png'
      end

      it 'should capture full element when larger than viewport' do
        page.set_viewport width: 500, height: 500

        content = <<~HTML
          something above
          <style>
          div.to-screenshot {
            border: 1px solid blue;
            width: 600px;
            height: 600px;
            margin-left: 50px;
          }
          ::-webkit-scrollbar{
            display: none;
          }
          </style>
          <div class="to-screenshot"></div>
        HTML
        page.set_content(content).wait!
        element_handle = page.query_selector 'div.to-screenshot'
        screenshot = element_handle.screenshot
        expect(screenshot).to match_screenshot 'screenshot-element-larger-than-viewport.png'

        expect(page.evaluate_function('() => ({ w: window.innerWidth, h: window.innerHeight })').value!)
          .to eq "w" => 500, "h" => 500
      end

      it 'should scroll element into view' do
        page.set_viewport width: 500, height: 500
        content = <<~HTML
          something above
          <style>div.above {
            border: 2px solid blue;
            background: red;
            height: 1500px;
          }
          div.to-screenshot {
            border: 2px solid blue;
            background: green;
            width: 50px;
            height: 50px;
          }
          </style>
          <div class="above"></div>
          <div class="to-screenshot"></div>
        HTML
        page.set_content(content).wait!
        element_handle = page.query_selector 'div.to-screenshot'
        screenshot = element_handle.screenshot
        expect(screenshot).to match_screenshot 'screenshot-element-scrolled-into-view.png'
      end

      it 'should work with a rotated element' do
        page.set_viewport width: 500, height: 500
        content = <<~HTML
          <div style="position:absolute; top: 100px; left: 100px; width: 100px; height: 100px; background: green; transform: rotateZ(200deg);">&nbsp;</div>
        HTML
        page.set_content(content).wait!
        element_handle = page.query_selector 'div'
        screenshot = element_handle.screenshot
        expect(screenshot).to match_screenshot 'screenshot-element-rotate.png'
      end

      it 'should fail to screenshot a detached element' do
        page.set_content('<h1>remove this</h1>').wait!
        element_handle = page.query_selector 'h1'
        page.evaluate_function('element => element.remove()', element_handle).wait!
        expect { element_handle.screenshot }.to raise_error 'Node is either not visible or not an HTMLElement'
      end

      it 'should not hang with zero width/height element' do
        page.set_content('<div style="width: 50px; height: 0"></div>').wait!
        div = page.query_selector 'div'
        expect { div.screenshot }.to raise_error 'Node has 0 height.'
      end

      it 'should work for an element with fractional dimensions' do
        page.set_content('<div style="width:48.51px;height:19.8px;border:1px solid black;"></div>').wait!
        element_handle = page.query_selector 'div'
        screenshot = element_handle.screenshot
        expect(screenshot).to match_screenshot 'screenshot-element-fractional.png'
      end

      it 'should work for an element with an offset' do
        page.set_content('<div style="position:absolute; top: 10.3px; left: 20.4px;width:50.3px;height:20.2px;border:1px solid black;"></div>').wait!
        element_handle = page.query_selector 'div'
        screenshot = element_handle.screenshot
        expect(screenshot).to match_screenshot 'screenshot-element-fractional-offset.png'
      end
    end
  end
end
