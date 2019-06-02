module Chromiebara
  RSpec.describe "Query Selector", browser: true do
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe 'Page.query_selector_evaluate_function' do
      it 'should work' do
        page.set_content '<section id="testAttribute">43543</section>'
        id_attribute = page.query_selector_evaluate_function 'section', 'e => e.id'
        expect(id_attribute).to eq 'testAttribute'
      end

      it 'should accept arguments' do
        page.set_content '<section>hello</section>'
        text = page.query_selector_evaluate_function 'section', '(e, suffix) => e.textContent + suffix', ' world!'
        expect(text).to eq 'hello world!'
      end

      it 'should accept ElementHandles as arguments' do
        page.set_content '<section>hello</section><div> world</div>'
        div_handle = page.query_selector 'div'
        text = page.query_selector_evaluate_function 'section', '(e, div) => e.textContent + div.textContent', div_handle
        expect(text).to eq 'hello world'
      end

      it 'should throw error if no element is found' do
        expect do
          page.query_selector_evaluate_function 'section', 'e => e.id'
        end.to raise_error(/failed to find element matching selector 'section'/)
      end
    end

    describe 'Page.query_selector_all_evaluate_function' do
      it 'evaluates the function passing in the query selector results' do
        page.set_content '<div>hello</div><div>beautiful</div><div>world!</div>'
        divs_count = page.query_selector_all_evaluate_function 'div', 'divs => divs.length'
        expect(divs_count).to eq 3
      end
    end

    describe 'Page#query_selector' do
      it 'should query existing element' do
        page.set_content '<section>test</section>'
        element = page.query_selector 'section'
        expect(element).not_to be_nil
      end

      it 'should return null for non-existing element' do
        element = page.query_selector 'non-existing-element'
        expect(element).to eq nil
      end
    end

    describe 'Page#query_selector_all' do
      it 'should query existing elements' do
        page.set_content '<div>A</div><br/><div>B</div>'
        elements = page.query_selector_all 'div'
        expect(elements.length).to eq 2
        values = elements.map { |element| page.evaluate_function 'e => e.textContent', element }
        expect(values).to eq ['A', 'B']
      end

      it 'should return empty array if nothing is found' do
        page.goto server.empty_page
        elements = page.query_selector_all 'div'
        expect(elements.length).to eq 0
      end
    end

    describe 'Page#xpath' do
      it 'should query existing element' do
        page.set_content '<section>test</section>'
        elements = page.xpath '/html/body/section'
        expect(elements[0]).not_to be_nil
        expect(elements.length).to eq 1
      end

      it 'should return empty array for non-existing element' do
        element = page.xpath '/html/body/non-existing-element'
        expect(element).to eq []
      end

      it 'should return multiple elements' do
        page.set_content '<div></div><div></div>'
        elements = page.xpath '/html/body/div'
        expect(elements.length).to eq 2
      end
    end

    describe 'ElementHandle#query_selector' do
      it 'should query existing element' do
        page.goto server.domain + 'playground.html'
        page.set_content '<html><body><div class="second"><div class="inner">A</div></div></body></html>'
        html = page.query_selector 'html'
        second = html.query_selector '.second'
        inner = second.query_selector '.inner'
        content = page.evaluate_function 'e => e.textContent', inner
        expect(content).to eq 'A'
      end

      it 'should return null for non-existing element' do
        page.set_content '<html><body><div class="second"><div class="inner">B</div></div></body></html>'
        html = page.query_selector 'html'
        second = html.query_selector '.third'
        expect(second).to eq nil
      end
    end

    describe 'ElementHandle#query_selector_evaluate_function' do
      it 'should work' do
        page.set_content '<html><body><div class="tweet"><div class="like">100</div><div class="retweets">10</div></div></body></html>'
        tweet = page.query_selector '.tweet'
        content = tweet.query_selector_evaluate_function '.like', "node => node.innerText"
        expect(content).to eq '100'
      end

      it 'should retrieve content from subtree' do
        html_content = '<div class="a">not-a-child-div</div><div id="myId"><div class="a">a-child-div</div></div>'
        page.set_content html_content
        element_handle = page.query_selector '#myId'
        content = element_handle.query_selector_evaluate_function '.a', "node => node.innerText"
        expect(content).to eq 'a-child-div'
      end

      it 'should throw in case of missing selector' do
        html_content = '<div class="a">not-a-child-div</div><div id="myId"></div>'
        page.set_content html_content
        element_handle = page.query_selector '#myId'
        expect { element_handle.query_selector_evaluate_function '.a', "node => node.innerText" }
          .to raise_error "Error: failed to find element matching selector '.a'"
      end
    end

    describe 'ElementHandle#query_selector_all_evaluate_function' do
      it 'should work' do
        page.set_content '<html><body><div class="tweet"><div class="like">100</div><div class="like">10</div></div></body></html>'
        tweet = page.query_selector '.tweet'
        content = tweet.query_selector_all_evaluate_function '.like', "nodes => nodes.map(n => n.innerText)"
        expect(content).to eq ['100', '10']
      end

      it 'should retrieve content from subtree' do
        html_content = '<div class="a">not-a-child-div</div><div id="myId"><div class="a">a1-child-div</div><div class="a">a2-child-div</div></div>'
        page.set_content html_content
        element_handle = page.query_selector '#myId'
        content = element_handle.query_selector_all_evaluate_function '.a', "nodes => nodes.map(n => n.innerText)"
        expect(content).to eq ['a1-child-div', 'a2-child-div']
      end

      it 'should not throw in case of missing selector' do
        html_content = '<div class="a">not-a-child-div</div><div id="myId"></div>'
        page.set_content html_content
        element_handle = page.query_selector '#myId'
        nodes_length = element_handle.query_selector_all_evaluate_function '.a', "nodes => nodes.length"
        expect(nodes_length).to eq 0
      end
    end

    describe 'ElementHandle#query_selector_all' do
      it 'should query existing elements' do
        page.set_content '<html><body><div>A</div><br/><div>B</div></body></html>'
        html = page.query_selector 'html'
        elements = html.query_selector_all 'div'
        expect(elements.length).to eq 2
        values = elements.map { |element| page.evaluate_function "e => e.textContent", element }
        expect(values).to eq ['A', 'B']
      end

      it 'should return empty array for non-existing elements' do
        page.set_content '<html><body><span>A</span><br/><span>B</span></body></html>'
        html = page.query_selector 'html'
        elements = html.query_selector_all 'div'
        expect(elements.length).to eq 0
      end
    end

    describe 'ElementHandle#xpath' do
      it 'should query existing element' do
        page.goto server.domain + 'playground.html'
        page.set_content '<html><body><div class="second"><div class="inner">A</div></div></body></html>'
        html = page.query_selector 'html'
        second = html.xpath "./body/div[contains(@class, 'second')]"
        inner = second[0].xpath "./div[contains(@class, 'inner')]"
        content = page.evaluate_function "e => e.textContent", inner[0]
        expect(content).to eq 'A'
      end

      it 'should return null for non-existing element' do
        page.set_content '<html><body><div class="second"><div class="inner">B</div></div></body></html>'
        html = page.query_selector 'html'
        second = html.xpath "/div[contains(@class, 'third')]"
        expect(second).to eq []
      end
    end
  end
end
