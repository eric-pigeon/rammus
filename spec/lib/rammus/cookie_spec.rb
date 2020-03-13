module Rammus
  RSpec.describe 'Cookies', browser: true do
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe '#cookies' do
      it 'should return empty array without cookies' do
        page.goto(server.empty_page).wait!
        expect(page.cookies).to eq []
      end

      it 'should get a cookie' do
        page.goto(server.empty_page).wait!
        page.evaluate("document.cookie = 'username=John Doe';").wait!
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
            "session" => true,
            "priority" => "Medium"
          }
        ])
      end

      it 'should report httpOnly' do
        server.set_route '/empty.html' do |req, res|
          res.set_cookie 'http_cookie', value: 'test-cookie', http_only: true
          res.finish
        end
        page.goto(server.empty_page).wait!
        cookie = page.cookies.first
        expect(cookie['httpOnly']).to eq true
      end

      it 'should properly report "Strict" sameSite cookie' do
        server.set_route '/empty.html' do |req, res|
          res.set_cookie 'cooky', same_site: :strict
          res.finish
        end
        page.goto(server.empty_page).wait!
        cookies = page.cookies
        expect(cookies.length).to eq 1
        expect(cookies[0]["sameSite"]).to eq 'Strict'
      end

      it 'should properly report "Lax" sameSite cookie' do
        server.set_route '/empty.html' do |req, res|
          res.set_cookie 'cooky', same_site: :lax
          res.finish
        end
        page.goto(server.empty_page).wait!
        cookies = page.cookies
        expect(cookies.length).to eq 1
        expect(cookies[0]["sameSite"]).to eq 'Lax'
      end

      it 'should get multiple cookies' do
        page.goto(server.empty_page).wait!

        page.evaluate("document.cookie = 'username=John Doe'; document.cookie = 'password=1234';").wait!
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
            "session" => true,
            "priority" => "Medium"
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
            "session" => true,
            "priority" => "Medium"
          }
        ])
      end

      it 'should get cookies from multiple urls' do
        page.set_cookie(
          { url: 'https://foo.com', name: 'doggo', value: 'woofs' },
          { url: 'https://bar.com', name: 'catto', value: 'purrs' },
          { url: 'https://baz.com', name: 'birdo', value: 'tweets' }
        )
        cookies = page.cookies('https://foo.com', 'https://baz.com')
        cookies.sort { |a, b| a["name"] <=> b["name"] }
        expect(cookies).to eq([
          {
            "name" => 'birdo',
            "value" => 'tweets',
            "domain" => 'baz.com',
            "path" => '/',
            "expires" => -1,
            "size" => 11,
            "httpOnly" => false,
            "secure" => true,
            "session" => true,
            "priority" => "Medium"
          },
          {
            "name" => 'doggo',
            "value" => 'woofs',
            "domain" => 'foo.com',
            "path" => '/',
            "expires" => -1,
            "size" => 10,
            "httpOnly" => false,
            "secure" => true,
            "session" => true,
            "priority" => "Medium"
          }
        ])
      end
    end

    describe '#set_cookie' do
      it 'sets cookies' do
        page.goto(server.empty_page).wait!

        page.set_cookie name: 'password', value: '123456'
        expect(page.evaluate('document.cookie').value!).to eq 'password=123456'
      end

      it 'should isolate cookies in browser contexts' do
        context_2 = browser.create_context
        page_2 = context_2.new_page

        page.goto(server.empty_page).wait!
        page_2.goto(server.empty_page).wait!

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

      it 'should set multiple cookies' do
        page.goto(server.empty_page).wait!
        page.set_cookie(
          { name: 'password', value: '123456' },
          { name: 'foo', value: 'bar' }
        )
        cookies = page.evaluate("document.cookie.split(';').map(cookie => cookie.trim()).sort();").value!
        expect(cookies).to eq ["foo=bar", "password=123456"]
      end

      it 'should have expires set to -1 for session cookies' do
        page.goto(server.empty_page).wait!
        page.set_cookie name: 'password', value: '123456'
        cookie = page.cookies.first
        expect(cookie["session"]).to eq true
        expect(cookie["expires"]).to eq(-1)
      end

      it 'should set cookie with reasonable defaults' do
        page.goto(server.empty_page).wait!
        page.set_cookie name: 'password', value: '123456'
        expect(page.cookies).to eq [
          "name" => 'password',
          "value" => '123456',
          "domain" => 'localhost',
          "path" => '/',
          "expires" => -1,
          "size" => 14,
          "httpOnly" => false,
          "secure" => false,
          "session" => true,
          "priority" => "Medium"
        ]
      end

      it 'should set a cookie with a path' do
        page.goto(server.domain + 'grid.html').wait!
        page.set_cookie(name: 'gridcookie', value: 'GRID', path: '/grid.html')
        expect(page.cookies).to eq([
          "name" => 'gridcookie',
          "value" => 'GRID',
          "domain" => 'localhost',
          "path" => '/grid.html',
          "expires" => -1,
          "size" => 14,
          "httpOnly" => false,
          "secure" => false,
          "session" => true,
          "priority" => "Medium"
        ])
        expect(page.evaluate('document.cookie').value!).to eq 'gridcookie=GRID'
        page.goto(server.empty_page).wait!
        expect(page.cookies).to eq []
        expect(page.evaluate('document.cookie').value!).to eq ''
        page.goto(server.domain + 'grid.html').wait!
        expect(page.evaluate('document.cookie').value!).to eq 'gridcookie=GRID'
      end

      it 'should not set a cookie on a blank page' do
        page.goto('about:blank').wait!

         expect {page.set_cookie({ name: 'example-cookie', value: 'best' }) }
           .to raise_error Errors::ProtocolError, /At least one of the url and domain needs to be specified/
      end

      it 'should not set a cookie with blank page URL' do
        page.goto(server.empty_page).wait!
        expect do
          page.set_cookie(
            { name: 'example-cookie', value: 'best' },
            { url: 'about:blank', name: 'example-cookie-blank', value: 'best' }
          )
        end.to raise_error RuntimeError, /Blank page can not have cookie "example-cookie-blank"/
      end

      it 'should not set a cookie on a data URL page' do
        page.goto('data:,Hello%2C%20World!').wait!

        expect { page.set_cookie name: 'example-cookie', value: 'best' }
          .to raise_error(Errors::ProtocolError, /At least one of the url and domain needs to be specified/)
      end

      it 'should default to setting secure cookie for HTTPS websites' do
        page.goto(server.empty_page).wait!
        secure_url = 'https://example.com'
        page.set_cookie url: secure_url, name: 'foo', value: 'bar'
        cookie, * = page.cookies secure_url
        expect(cookie["secure"]).to eq true
      end

      it 'should be able to set unsecure cookie for HTTP website' do
        page.goto(server.empty_page).wait!
        http_url = 'http://example.com'
        page.set_cookie url: http_url, name: 'foo', value: 'bar'
        cookie, * = page.cookies http_url
        expect(cookie["secure"]).to eq false
      end

      it 'should set a cookie on a different domain' do
        page.goto(server.empty_page).wait!
        page.set_cookie url: 'https://www.example.com', name: 'example-cookie', value: 'best'
        expect(page.evaluate('document.cookie').value!).to eq ''
        expect(page.cookies).to eq []
        expect(page.cookies 'https://www.example.com').to eq [{
          "name" => 'example-cookie',
          "value" => 'best',
          "domain" => 'www.example.com',
          "path" => '/',
          "expires" => -1,
          "size" => 18,
          "httpOnly" => false,
          "secure" => true,
          "session" => true,
          "priority" => "Medium"
        }]
      end

      it 'should set cookies from a frame' do
        pending 'broken'
        await page.goto server.domain + "empty.html"
        page.set_cookie name: 'localhost-cookie', value: 'best'
        function = <<~JAVASCRIPT
          src => {
             let fulfill;
             const promise = new Promise(x => fulfill = x);
             const iframe = document.createElement('iframe');
             document.body.appendChild(iframe);
             iframe.onload = fulfill;
             iframe.src = src;
             return promise;
          }
        JAVASCRIPT
        await page.evaluate_function function, server.cross_process_domain
        page.set_cookie name: '127-cookie', value: 'worst', url: server.cross_process_domain
        expect(await page.evaluate('document.cookie')).to eq 'localhost-cookie=best'
        expect(await page.frames[1].evaluate('document.cookie')).to eq '127-cookie=worst'

        expect(page.cookies).to eq([{
          "name" => 'localhost-cookie',
          "value" => 'best',
          "domain" => 'localhost',
          "path" => '/',
          "expires" => -1,
          "size" => 20,
          "httpOnly" => false,
          "secure" => false,
          "session" => true
        }])

        expect(page.cookies(server.cross_process_domain)).to eq([{
          "name" => '127-cookie',
          "value" => 'worst',
          "domain" => '127.0.0.1',
          "path" => '/',
          "expires" => -1,
          "size" => 15,
          "httpOnly" => false,
          "secure" => false,
          "session" => true
        }])
      end
    end

    describe '#delete_cookies' do
      it 'deletes cookies' do
        page.goto(server.empty_page).wait!
        page.set_cookie(
          { name: 'cookie1', value: '1' },
          { name: 'cookie2', value: '2' },
          { name: 'cookie3', value: '3' }
        )
        expect(page.evaluate('document.cookie').value!).to eq 'cookie1=1; cookie2=2; cookie3=3'
        page.delete_cookie(name: 'cookie2')
        expect(page.evaluate('document.cookie').value!).to eq 'cookie1=1; cookie3=3'
      end
    end
  end
end
