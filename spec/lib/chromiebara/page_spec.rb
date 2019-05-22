module Chromiebara
  RSpec.describe Page, browser: true do
    let!(:context) { browser.create_context }
    let!(:page) { context.new_page }

    describe '#close' do
      it 'should not be visible in browser.pages' do
        new_page = browser.new_page
        expect(browser.pages).to include new_page

        new_page.close
        expect(browser.pages).not_to include new_page
      end
    end

    describe '#cookies' do
      it 'should return empty array without cookies' do
        page.goto server.empty_page
        expect(page.cookies).to eq []
      end

      it 'should get a cookie' do
        page.goto(server.empty_page)
        page.evaluate("document.cookie = 'username=John Doe';")
        expect(page.cookies).to eq([
          {
            "name" => 'username',
            "value" => 'John Doe',
            "domain" => 'localhost',
            "path" => '/',
            "expires" => -1,
            "size" => 16,
            "httpOnly" => false,
            "secure" => false,
            "session" => true
          }
        ])
      end

      it 'should report httpOnly' do
        page.goto server.domain + 'http-cookie'
        cookie = page.cookies.first
        expect(cookie['httpOnly']).to eq true
      end

      it 'should get multiple cookies' do
        page.goto server.empty_page

        page.evaluate("document.cookie = 'username=John Doe'; document.cookie = 'password=1234';")
        cookies = page.cookies.sort { |a, b| a["name"] <=> b["name"] }
        expect(cookies).to eq([
          {
            "name" => 'password',
            "value" => '1234',
            "domain" => 'localhost',
            "path" => '/',
            "expires" => -1,
            "size" => 12,
            "httpOnly" => false,
            "secure" => false,
            "session" => true
          },
          {
            "name" => 'username',
            "value" => 'John Doe',
            "domain" => 'localhost',
            "path" => '/',
            "expires" => -1,
            "size" => 16,
            "httpOnly" => false,
            "secure" => false,
            "session" => true
          }
        ])
      end

      it 'should get cookies from multiple urls' do
        pending 'needs #set_cookie'
        page.set_cookie(
          { url: 'https://foo.com', name: 'doggo', value: 'woofs' },
          { url: 'https://bar.com', name: 'catto', value: 'purrs' },
          { url: 'https://baz.com', name: 'birdo', value: 'tweets' }
        )
        cookies = page.cookies('https://foo.com', 'https://baz.com')
        cookies.sort { |a, b| a["name"] <=> b["name"] }
        expect(cookies).to eq([
          {
            name: 'birdo',
            value: 'tweets',
            domain: 'baz.com',
            path: '/',
            expires: -1,
            size: 11,
            httpOnly: false,
            secure: true,
            session: true
          },
          {
            name: 'doggo',
            value: 'woofs',
            domain: 'foo.com',
            path: '/',
            expires: -1,
            size: 10,
            httpOnly: false,
            secure: true,
            session: true
          }
        ])
      end
    end

    describe '#set_cookie' do
      it 'sets cookies' do
        page.goto server.empty_page

        page.set_cookie name: 'password', value: '123456'
        expect(page.evaluate 'document.cookie').to eq 'password=123456'
      end

      it 'should isolate cookies in browser contexts' do
        context_2 = browser.create_context
        page_2 = context_2.new_page

        page.goto server.empty_page
        page_2.goto server.empty_page

        page.set_cookie name: 'page1cookie', value: 'page1value'
        page_2.set_cookie name: 'page2cookie', value: 'page2value'

        cookies_1 = page.cookies
        cookies_2 = page_2.cookies
        expect(cookies_1.length).to eq 1
        expect(cookies_2.length).to eq 1

        expect(cookies_1[0]["name"]).to eq 'page1cookie'
        expect(cookies_1[0]["value"]).to eq 'page1value'

        expect(cookies_2[0]["name"]).to eq 'page2cookie'
        expect(cookies_2[0]["value"]).to eq 'page2value'

        context_2.close
      end
    end

    describe '#delete_cookies' do
      # TODO
    end

    describe '#evaluate' do
      context 'passing javascript function' do
        it 'transfers NaN' do
          result = page.evaluate('a => a', 'NaN', function: true)
          expect(result).to eq 'NaN'
        end
      end

      it 'evaluates javascript' do
        result = page.evaluate '7 * 3'
        expect(result).to eq 21
      end
    end

    describe '#frames' do
      it 'returns all frames in the page' do
        page.goto server.domain + "frames/nested-frames.html"
        expected_frames = [
          "http://localhost:4567/frames/nested-frames.html",
          "http://localhost:4567/frames/two-frames.html",
          "http://localhost:4567/frames/frame.html",
          "http://localhost:4567/frames/frame.html",
          "http://localhost:4567/frames/frame.html"
        ]
        expect(page.frames.map(&:url)).to eq expected_frames
      end
    end

    describe '#url' do
      it 'returns the pages current url' do
        expect(page.url).to eq "about:blank"
        page.goto server.empty_page
        expect(page.url).to eq server.empty_page
      end
    end

    describe '#title' do
      xit 'should return the page title' do
        page.goto server.domain + "/title.html"
        expect(page.title).to eq 'Woof-Woof'
      end
    end
  end
end
