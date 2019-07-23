module Rammus
  RSpec.describe 'Emulation', browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }
    let(:iPhone) { Rammus.devices['iPhone 6'] }
    let(:iPhoneLandscape) { Rammus.devices['iPhone 6 landscape'] }

    describe 'Page#viewport' do
      it 'should get the proper viewport size' do
        expect(page.viewport).to eq(width: 800, height: 600)
        page.set_viewport width: 123, height: 456
        expect(page.viewport).to eq(width: 123, height: 456)
      end

      it 'should support mobile emulation' do
        await page.goto server.domain + 'mobile.html'
        expect(await page.evaluate_function "() => window.innerWidth").to eq 800
        page.set_viewport iPhone[:viewport]
        expect(await page.evaluate_function "() => window.innerWidth").to eq 375
        page.set_viewport width: 400, height: 300
        expect(await page.evaluate_function "() => window.innerWidth").to eq 400
      end

      it 'should support touch emulation' do
        await page.goto server.domain + 'mobile.html'
        expect(await page.evaluate_function "() => 'ontouchstart' in window").to eq false
        page.set_viewport iPhone[:viewport]
        expect(await page.evaluate_function "() => 'ontouchstart' in window").to eq true
        dispatch_touch = <<~JAVASCRIPT
        function dispatchTouch() {
          let fulfill;
          const promise = new Promise(x => fulfill = x);
          window.ontouchstart = function(e) {
            fulfill('Received touch');
          };
          window.dispatchEvent(new Event('touchstart'));

          fulfill('Did not receive touch');

          return promise;
        }
        JAVASCRIPT
        expect(await page.evaluate_function dispatch_touch).to eq 'Received touch'
        page.set_viewport width: 100, height: 100
        expect(await page.evaluate_function "() => 'ontouchstart' in window").to eq false

      end

      it 'should be detectable by Modernizr' do
        await page.goto server.domain + 'detect-touch.html'
        expect(await page.evaluate_function "() => document.body.textContent.trim()").to eq 'NO'
        page.set_viewport iPhone[:viewport]
        await page.goto server.domain + 'detect-touch.html'
        expect(await page.evaluate_function "() => document.body.textContent.trim()").to eq 'YES'
      end

      it 'should detect touch when applying viewport with touches' do
        page.set_viewport width: 800, height: 600, has_touch: true
        page.add_script_tag url: server.domain + 'modernizr.js'
        expect(await page.evaluate_function "() => Modernizr.touchevents").to eq true
      end

      it 'should support landscape emulation' do
        await page.goto server.domain + 'mobile.html'
        expect(await page.evaluate_function "() => screen.orientation.type").to eq 'portrait-primary'
        page.set_viewport iPhoneLandscape[:viewport]
        expect(await page.evaluate_function "() => screen.orientation.type").to eq 'landscape-primary'
        page.set_viewport width: 100, height: 100
        expect(await page.evaluate_function "() => screen.orientation.type").to eq 'portrait-primary'
      end
    end

    describe 'Page#emulate' do
      it 'should emulate mobile' do
        await page.goto server.domain + 'mobile.html'
        page.emulate iPhone
        expect(await page.evaluate_function "() => window.innerWidth").to eq 375
        expect(await page.evaluate_function "() => navigator.userAgent").to include 'iPhone'
      end

      it 'should support clicking' do
        page.emulate iPhone
        await page.goto server.domain + 'input/button.html'
        button = page.query_selector 'button'
        await page.evaluate_function "button => button.style.marginTop = '200px'", button
        button.click
        expect(await page.evaluate_function "() => result").to eq 'Clicked'
      end
    end

    describe 'Page#emulate_media' do
      it 'change the page emulated media' do
        expect(await page.evaluate_function "() => window.matchMedia('screen').matches").to eq true
        expect(await page.evaluate_function "() => window.matchMedia('print').matches").to eq false
        page.emulate_media 'print'
        expect(await page.evaluate_function "() => window.matchMedia('screen').matches").to eq false
        expect(await page.evaluate_function "() => window.matchMedia('print').matches").to eq true
        page.emulate_media
        expect(await page.evaluate_function "() => window.matchMedia('screen').matches").to eq true
        expect(await page.evaluate_function "() => window.matchMedia('print').matches").to eq false
      end

      it 'should throw in case of bad argument' do
        expect { page.emulate_media 'bad' }.to raise_error 'Unsupported media type: bad'
      end
    end
  end
end
