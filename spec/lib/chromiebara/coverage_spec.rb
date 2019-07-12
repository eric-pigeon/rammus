module Chromiebara
  RSpec.describe 'Coverage', browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe 'JSCoverage' do
      it 'should work' do
        page.coverage.start_js_coverage
        await page.goto server.domain + 'jscoverage/simple.html', wait_until: :networkidle0
        coverage = page.coverage.stop_js_coverage
        expect(coverage.length).to eq 1
        expect(coverage[0][:url]).to include '/jscoverage/simple.html'
        expect(coverage[0][:ranges]).to eq([
          { start: 0, end: 17 },
          { start: 35, end: 61 },
        ])
      end

      it 'should report source_urls' do
        page.coverage.start_js_coverage
        await page.goto server.domain + 'jscoverage/sourceurl.html'
        coverage = page.coverage.stop_js_coverage
        expect(coverage.length).to eq 1
        expect(coverage[0][:url]).to eq 'nicename.js'
      end

      it 'should ignore eval() scripts by default' do
        page.coverage.start_js_coverage
        await page.goto server.domain + 'jscoverage/eval.html'
        coverage = page.coverage.stop_js_coverage
        expect(coverage.length).to eq 1
      end

      it 'shouldn\'t ignore eval() scripts if reportAnonymousScripts is true' do
        page.coverage.start_js_coverage report_anonymous_scripts: true
        await page.goto server.domain + 'jscoverage/eval.html'
        coverage = page.coverage.stop_js_coverage
        expect(coverage.detect { |entry| entry[:url].start_with? 'debugger://' }).not_to be_nil
        expect(coverage.length).to eq 2
      end

      it 'should ignore pptr internal scripts if reportAnonymousScripts is true' do
        page.coverage.start_js_coverage report_anonymous_scripts: true
        await page.goto server.empty_page
        await page.evaluate 'console.log("foo")'
        await page.evaluate_function "() => console.log('bar')"
        coverage = page.coverage.stop_js_coverage
        expect(coverage.length).to eq 0
      end

      it 'should report multiple scripts' do
        page.coverage.start_js_coverage
        await page.goto server.domain + 'jscoverage/multiple.html'
        coverage = page.coverage.stop_js_coverage
        expect(coverage.length).to eq 2
        coverage.sort! { |a, b| a[:url] <=> b[:url] }
        expect(coverage[0][:url]).to include '/jscoverage/script1.js'
        expect(coverage[1][:url]).to include '/jscoverage/script2.js'
      end

      it 'should report right ranges' do
        page.coverage.start_js_coverage
        await page.goto server.domain + 'jscoverage/ranges.html'
        coverage = page.coverage.stop_js_coverage
        expect(coverage.length).to eq 1
        entry = coverage[0]
        expect(entry[:ranges].length).to eq 1
        range = entry[:ranges][0]
        expect(entry[:text][range[:start]...range[:end]]).to eq "console.log('used!');"
      end

      it 'should report scripts that have no coverage' do
        page.coverage.start_js_coverage
        await page.goto server.domain + 'jscoverage/unused.html'
        coverage = page.coverage.stop_js_coverage
        expect(coverage.length).to eq 1
        entry = coverage[0]
        expect(entry[:url]).to include 'unused.html'
        expect(entry[:ranges].length).to eq 0
      end

      it 'should work with conditionals' do
        page.coverage.start_js_coverage
        await page.goto server.domain + 'jscoverage/involved.html'
        coverage = page.coverage.stop_js_coverage
        coverage.each { |part| part[:url].gsub!(/:\d{4}\//, ':<PORT>/') }
        expected = [
          {
            url: "http://localhost:<PORT>/jscoverage/involved.html",
            ranges: [
              { start: 0, end: 35 },
              { start: 50, end: 100 },
              { start: 107, end: 141 },
              { start: 148, end: 160 },
              { start: 168, end: 207 }
            ],
            text: <<~TEXT

            function foo() {
              if (1 > 2)
                console.log(1);
              if (1 < 2)
                console.log(2);
              let x = 1 > 2 ? 'foo' : 'bar';
              let y = 1 < 2 ? 'foo' : 'bar';
              let z = () => {};
              let q = () => {};
              q();
            }

            foo();
            TEXT
          }
        ]
        expect(coverage).to eq expected
      end

      describe '#reset_on_navigation' do
        it 'should report scripts across navigations when disabled' do
          page.coverage.start_js_coverage reset_on_navigation: false
          await page.goto server.domain + 'jscoverage/multiple.html'
          await page.goto server.empty_page
          coverage = page.coverage.stop_js_coverage
          expect(coverage.length).to eq 2
        end

        it 'should NOT report scripts across navigations when enabled' do
          page.coverage.start_js_coverage
          await page.goto server.domain + 'jscoverage/multiple.html'
          await page.goto server.empty_page
          coverage = page.coverage.stop_js_coverage
          expect(coverage.length).to eq 0
        end
      end

      xit 'should not hang when there is a debugger statement' do
        #await page.coverage.startJSCoverage();
        #await page.goto(server.empty_page);
        #await page.evaluate(() => {
        #  debugger;
        #});
        #await page.coverage.stopJSCoverage();
      end
    end

    describe 'CSSCoverage' do
      it 'should work' do
        page.coverage.start_css_coverage
        await page.goto server.domain + 'csscoverage/simple.html'
        coverage = page.coverage.stop_css_coverage
        expect(coverage.length).to eq 1
        expect(coverage[0][:url]).to include '/csscoverage/simple.html'
        expect(coverage[0][:ranges]).to eq [{ start: 1, end: 22 } ]
        range = coverage[0][:ranges][0]
        expect(coverage[0][:text][range[:start]...range[:end]]).to eq 'div { color: green; }'
      end

      it 'should report sourceURLs' do
        page.coverage.start_css_coverage
        await page.goto server.domain + 'csscoverage/sourceurl.html'
        coverage = page.coverage.stop_css_coverage
        expect(coverage.length).to eq 1
        expect(coverage[0][:url]).to eq 'nicename.css'
      end

      it 'should report multiple stylesheets' do
        page.coverage.start_css_coverage
        await page.goto server.domain + 'csscoverage/multiple.html'
        coverage = page.coverage.stop_css_coverage
        expect(coverage.length).to eq 2
        coverage.sort! { |a, b| a[:url] <=> b[:url] }
        expect(coverage[0][:url]).to include '/csscoverage/stylesheet1.css'
        expect(coverage[1][:url]).to include '/csscoverage/stylesheet2.css'
      end

      it 'should report stylesheets that have no coverage' do
        page.coverage.start_css_coverage
        await page.goto server.domain + 'csscoverage/unused.html'
        coverage = page.coverage.stop_css_coverage
        expect(coverage.length).to eq 1
        expect(coverage[0][:url]).to eq 'unused.css'
        expect(coverage[0][:ranges].length).to eq 0
      end

      it 'should work with media queries' do
        page.coverage.start_css_coverage
        await page.goto server.domain + 'csscoverage/media.html'
        coverage = page.coverage.stop_css_coverage
        expect(coverage.length).to eq 1
        expect(coverage[0][:url]).to include '/csscoverage/media.html'
        expect(coverage[0][:ranges]).to eq [{ start: 17, end: 38 }]
      end

      it 'should work with complicated usecases' do
        page.coverage.start_css_coverage
        await page.goto server.domain + 'csscoverage/involved.html'
        coverage = page.coverage.stop_css_coverage
        coverage.each { |part| part[:url].gsub!(/:\d{4}\//, ':<PORT>/') }
        expected = [
          {
            url: "http://localhost:<PORT>/csscoverage/involved.html",
            ranges: [
              { "start": 149, "end": 297 },
              { "start": 327, "end": 433 }
            ],
            text: <<~TEXT

            @charset \"utf-8\";
            @namespace svg url(http://www.w3.org/2000/svg);
            @font-face {
              font-family: \"Example Font\";
              src: url(\"./Dosis-Regular.ttf\");
            }

            #fluffy {
              border: 1px solid black;
              z-index: 1;
              /* -webkit-disabled-property: rgb(1, 2, 3) */
              -lol-cats: \"dogs\" /* non-existing property */
            }

            @media (min-width: 1px) {
              span {
                -webkit-border-radius: 10px;
                font-family: \"Example Font\";
                animation: 1s identifier;
              }
            }
            TEXT
          }
        ]

        expect(coverage).to eq expected
      end

      it 'should ignore injected stylesheets' do
        page.coverage.start_css_coverage
        page.add_style_tag content: 'body { margin: 10px;}'
        # trigger style recalc
        margin = await page.evaluate_function("() => window.getComputedStyle(document.body).margin")
        expect(margin).to eq '10px'
        coverage = page.coverage.stop_css_coverage
        expect(coverage.length).to eq 0
      end

      describe 'reset_on_navigation' do
        it 'should report stylesheets across navigations' do
          page.coverage.start_css_coverage reset_on_navigation: false
          await page.goto server.domain + 'csscoverage/multiple.html'
          await page.goto server.empty_page
          coverage = page.coverage.stop_css_coverage
          expect(coverage.length).to eq 2
        end

        it 'should NOT report scripts across navigations' do
          page.coverage.start_css_coverage
          await page.goto server.domain + 'csscoverage/multiple.html'
          await page.goto server.empty_page
          coverage = page.coverage.stop_css_coverage
          expect(coverage.length).to eq 0
        end
      end

      xit 'should work with a recently loaded stylesheet' do
        # TODO sometimes this test fails; the call to get the stylesheet contents
        # randomly fails sometimes
        page.coverage.start_css_coverage
        await page.evaluate_function("async url => {
          document.body.textContent = 'hello, world';

          const link = document.createElement('link');
          link.rel = 'stylesheet';
          link.href = url;
          document.head.appendChild(link);
          await new Promise(x => link.onload = x);
        }", server.domain + 'csscoverage/stylesheet1.css')
        coverage = page.coverage.stop_css_coverage
        expect(coverage.length).to eq 1
      end
    end
  end
end
