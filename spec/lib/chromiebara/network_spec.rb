module Chromiebara
  RSpec.describe 'Screenshot', browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    describe 'Page Events :request' do
      it 'should fire for navigation requests' do
        requests = []
        page.on :request, -> (request) do
          next if is_favicon request
          requests << request
        end
        page.goto server.empty_page
        expect(requests.length).to eq 1
      end

      it 'should fire for iframes' do
        requests = []
        page.on :request, -> (request) do
          next if is_favicon request
          requests << request
        end
        page.goto server.empty_page
        attach_frame page, 'frame1', server.empty_page
        expect(requests.length).to eq 2
      end

      it 'should fire for fetches' do
        requests = []
        page.on :request, -> (request) do
          next if is_favicon request
          requests << request
        end
        page.goto server.empty_page
        page.evaluate_function "() => fetch('/empty.html')"
        expect(requests.length).to eq 2
      end
    end

    describe 'Request#frame' do
      it 'should work for main frame navigation request' do
        requests = []
        page.on :request, -> (request) do
          next if is_favicon request
          requests << request
        end
        page.goto server.empty_page
        expect(requests.length).to eq 1
        expect(requests[0].frame).to eq page.main_frame
      end

      it 'should work for subframe navigation request' do
        page.goto server.empty_page
        requests = []
        page.on :request, -> (request) do
          next if is_favicon request
          requests << request
        end
        attach_frame page, 'frame1', server.empty_page
        expect(requests.length).to eq 1
        expect(requests[0].frame).to eq page.frames[1]
      end

      it 'should work for fetch requests' do
        page.goto server.empty_page
        requests = []
        page.on :request, -> (request) do
          next if is_favicon request
          requests << request
        end
        page.evaluate_function "() => fetch('/digits/1.png')"
        expect(requests.length).to eq 1
        expect(requests[0].frame).to eq page.main_frame
      end
    end

    describe 'Request#headers' do
      it 'should work' do
        response = page.goto server.empty_page
        expect(response.request.headers['user-agent']).to include 'Chrome'
      end
    end

    describe 'Response#headers' do
      it 'should work' do
        response = page.goto server.domain + 'foo-header'
        expect(response.headers['foo']).to eq 'bar'
      end
    end

    describe 'Response#from_cache' do
      it 'should return |false| for non-cached content' do
        response = page.goto server.empty_page
        expect(response.from_cache).to eq false
      end

      it 'should work' do
        responses = {}
        page.on :response, -> (request) do
          next if is_favicon request
          responses[request.url.split('/').pop] = request
        end

        # Load and re-load to make sure it's cached.
        page.goto server.domain + 'cached/one-style.html'
        page.reload

        expect(responses.size).to eq 2
        expect(responses['one-style.css'].status).to eq 200
        expect(responses['one-style.css'].from_cache).to eq true
        expect(responses['one-style.html'].status).to eq 304
        expect(responses['one-style.html'].from_cache).to eq false
      end
    end

    describe 'Response#from_service_worker' do
      it 'should return |false| for non-service-worker content' do
        response = page.goto server.empty_page
        expect(response.from_service_worker).to eq false
      end

      it 'Response#from_service_worker' do
        responses = {}
        page.on :response, -> (request) do
          next if is_favicon request
          responses[request.url.split('/').pop] = request
        end

        # Load and re-load to make sure serviceworker is installed and running.
        page.goto server.domain + 'serviceworkers/fetch/sw.html',  wait_until: :networkidle2
        page.evaluate_function 'async() => await window.activationPromise'
        page.reload

        expect(responses.size).to eq 2
        expect(responses['sw.html'].status).to eq 200
        expect(responses['sw.html'].from_service_worker).to eq true
        expect(responses['style.css'].status).to eq 200
        expect(responses['style.css'].from_service_worker).to eq true
      end
    end

    describe 'Request#post_data' do
      it 'should work' do
        page.goto server.empty_page
        request = nil
        page.on :request, -> (r) { request = r }
        page.evaluate_function "() => fetch('./post', { method: 'POST', body: JSON.stringify({foo: 'bar'})})"
        expect(request).not_to be_nil
        expect(request.post_data).to eq '{"foo":"bar"}'
      end

      #it('should be |undefined| when there is no post data', async({page, server}) => {
      #  const response = await page.goto(server.EMPTY_PAGE);
      #  expect(response.request().postData()).toBe(undefined);
      #});
    end

    #describe('Response.text', function() {
    #  it('should work', async({page, server}) => {
    #    const response = await page.goto(server.PREFIX + '/simple.json');
    #    expect(await response.text()).toBe('{"foo": "bar"}\n');
    #  });
    #  it('should return uncompressed text', async({page, server}) => {
    #    server.enableGzip('/simple.json');
    #    const response = await page.goto(server.PREFIX + '/simple.json');
    #    expect(response.headers()['content-encoding']).toBe('gzip');
    #    expect(await response.text()).toBe('{"foo": "bar"}\n');
    #  });
    #  it('should throw when requesting body of redirected response', async({page, server}) => {
    #    server.setRedirect('/foo.html', '/empty.html');
    #    const response = await page.goto(server.PREFIX + '/foo.html');
    #    const redirectChain = response.request().redirectChain();
    #    expect(redirectChain.length).toBe(1);
    #    const redirected = redirectChain[0].response();
    #    expect(redirected.status()).toBe(302);
    #    let error = null;
    #    await redirected.text().catch(e => error = e);
    #    expect(error.message).toContain('Response body is unavailable for redirect responses');
    #  });
    #  it('should wait until response completes', async({page, server}) => {
    #    await page.goto(server.EMPTY_PAGE);
    #    // Setup server to trap request.
    #    let serverResponse = null;
    #    server.setRoute('/get', (req, res) => {
    #      serverResponse = res;
    #      // In Firefox, |fetch| will be hanging until it receives |Content-Type| header
    #      // from server.
    #      res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    #      res.write('hello ');
    #    });
    #    // Setup page to trap response.
    #    let requestFinished = false;
    #    page.on('requestfinished', r => requestFinished = requestFinished || r.url().includes('/get'));
    #    // send request and wait for server response
    #    const [pageResponse] = await Promise.all([
    #      page.waitForResponse(r => !utils.isFavicon(r.request())),
    #      page.evaluate(() => fetch('./get', { method: 'GET'})),
    #      server.waitForRequest('/get'),
    #    ]);

    #    expect(serverResponse).toBeTruthy();
    #    expect(pageResponse).toBeTruthy();
    #    expect(pageResponse.status()).toBe(200);
    #    expect(requestFinished).toBe(false);

    #    const responseText = pageResponse.text();
    #    // Write part of the response and wait for it to be flushed.
    #    await new Promise(x => serverResponse.write('wor', x));
    #    // Finish response.
    #    await new Promise(x => serverResponse.end('ld!', x));
    #    expect(await responseText).toBe('hello world!');
    #  });
    #});

    #describe('Response.json', function() {
    #  it('should work', async({page, server}) => {
    #    const response = await page.goto(server.PREFIX + '/simple.json');
    #    expect(await response.json()).toEqual({foo: 'bar'});
    #  });
    #});

    #describe('Response.buffer', function() {
    #  it('should work', async({page, server}) => {
    #    const response = await page.goto(server.PREFIX + '/pptr.png');
    #    const imageBuffer = fs.readFileSync(path.join(__dirname, 'assets', 'pptr.png'));
    #    const responseBuffer = await response.buffer();
    #    expect(responseBuffer.equals(imageBuffer)).toBe(true);
    #  });
    #  it('should work with compression', async({page, server}) => {
    #    server.enableGzip('/pptr.png');
    #    const response = await page.goto(server.PREFIX + '/pptr.png');
    #    const imageBuffer = fs.readFileSync(path.join(__dirname, 'assets', 'pptr.png'));
    #    const responseBuffer = await response.buffer();
    #    expect(responseBuffer.equals(imageBuffer)).toBe(true);
    #  });
    #});

    #describe('Response.statusText', function() {
    #  it('should work', async({page, server}) => {
    #    server.setRoute('/cool', (req, res) => {
    #      res.writeHead(200, 'cool!');
    #      res.end();
    #    });
    #    const response = await page.goto(server.PREFIX + '/cool');
    #    expect(response.statusText()).toBe('cool!');
    #  });
    #});

    #describe('Network Events', function() {
    #  it('Page.Events.Request', async({page, server}) => {
    #    const requests = [];
    #    page.on('request', request => requests.push(request));
    #    await page.goto(server.EMPTY_PAGE);
    #    expect(requests.length).toBe(1);
    #    expect(requests[0].url()).toBe(server.EMPTY_PAGE);
    #    expect(requests[0].resourceType()).toBe('document');
    #    expect(requests[0].method()).toBe('GET');
    #    expect(requests[0].response()).toBeTruthy();
    #    expect(requests[0].frame() === page.mainFrame()).toBe(true);
    #    expect(requests[0].frame().url()).toBe(server.EMPTY_PAGE);
    #  });
    #  it('Page.Events.Response', async({page, server}) => {
    #    const responses = [];
    #    page.on('response', response => responses.push(response));
    #    await page.goto(server.EMPTY_PAGE);
    #    expect(responses.length).toBe(1);
    #    expect(responses[0].url()).toBe(server.EMPTY_PAGE);
    #    expect(responses[0].status()).toBe(200);
    #    expect(responses[0].ok()).toBe(true);
    #    expect(responses[0].request()).toBeTruthy();
    #    const remoteAddress = responses[0].remoteAddress();
    #    // Either IPv6 or IPv4, depending on environment.
    #    expect(remoteAddress.ip.includes('::1') || remoteAddress.ip === '127.0.0.1').toBe(true);
    #    expect(remoteAddress.port).toBe(server.PORT);
    #  });

    #  it('Page.Events.RequestFailed', async({page, server}) => {
    #    await page.setRequestInterception(true);
    #    page.on('request', request => {
    #      if (request.url().endsWith('css'))
    #        request.abort();
    #      else
    #        request.continue();
    #    });
    #    const failedRequests = [];
    #    page.on('requestfailed', request => failedRequests.push(request));
    #    await page.goto(server.PREFIX + '/one-style.html');
    #    expect(failedRequests.length).toBe(1);
    #    expect(failedRequests[0].url()).toContain('one-style.css');
    #    expect(failedRequests[0].response()).toBe(null);
    #    expect(failedRequests[0].resourceType()).toBe('stylesheet');
    #    if (CHROME)
    #      expect(failedRequests[0].failure().errorText).toBe('net::ERR_FAILED');
    #    else
    #      expect(failedRequests[0].failure().errorText).toBe('NS_ERROR_FAILURE');
    #    expect(failedRequests[0].frame()).toBeTruthy();
    #  });
    #  it('Page.Events.RequestFinished', async({page, server}) => {
    #    const requests = [];
    #    page.on('requestfinished', request => requests.push(request));
    #    await page.goto(server.EMPTY_PAGE);
    #    expect(requests.length).toBe(1);
    #    expect(requests[0].url()).toBe(server.EMPTY_PAGE);
    #    expect(requests[0].response()).toBeTruthy();
    #    expect(requests[0].frame() === page.mainFrame()).toBe(true);
    #    expect(requests[0].frame().url()).toBe(server.EMPTY_PAGE);
    #  });
    #  it('should fire events in proper order', async({page, server}) => {
    #    const events = [];
    #    page.on('request', request => events.push('request'));
    #    page.on('response', response => events.push('response'));
    #    page.on('requestfinished', request => events.push('requestfinished'));
    #    await page.goto(server.EMPTY_PAGE);
    #    expect(events).toEqual(['request', 'response', 'requestfinished']);
    #  });
    #  it('should support redirects', async({page, server}) => {
    #    const events = [];
    #    page.on('request', request => events.push(`${request.method()} ${request.url()}`));
    #    page.on('response', response => events.push(`${response.status()} ${response.url()}`));
    #    page.on('requestfinished', request => events.push(`DONE ${request.url()}`));
    #    page.on('requestfailed', request => events.push(`FAIL ${request.url()}`));
    #    server.setRedirect('/foo.html', '/empty.html');
    #    const FOO_URL = server.PREFIX + '/foo.html';
    #    const response = await page.goto(FOO_URL);
    #    expect(events).toEqual([
    #      `GET ${FOO_URL}`,
    #      `302 ${FOO_URL}`,
    #      `DONE ${FOO_URL}`,
    #      `GET ${server.EMPTY_PAGE}`,
    #      `200 ${server.EMPTY_PAGE}`,
    #      `DONE ${server.EMPTY_PAGE}`
    #    ]);

    #    // Check redirect chain
    #    const redirectChain = response.request().redirectChain();
    #    expect(redirectChain.length).toBe(1);
    #    expect(redirectChain[0].url()).toContain('/foo.html');
    #    expect(redirectChain[0].response().remoteAddress().port).toBe(server.PORT);
    #  });
    #});

    #describe('Request.isNavigationRequest', () => {
    #  it('should work', async({page, server}) => {
    #    const requests = new Map();
    #    page.on('request', request => requests.set(request.url().split('/').pop(), request));
    #    server.setRedirect('/rrredirect', '/frames/one-frame.html');
    #    await page.goto(server.PREFIX + '/rrredirect');
    #    expect(requests.get('rrredirect').isNavigationRequest()).toBe(true);
    #    expect(requests.get('one-frame.html').isNavigationRequest()).toBe(true);
    #    expect(requests.get('frame.html').isNavigationRequest()).toBe(true);
    #    expect(requests.get('script.js').isNavigationRequest()).toBe(false);
    #    expect(requests.get('style.css').isNavigationRequest()).toBe(false);
    #  });
    #  it('should work with request interception', async({page, server}) => {
    #    const requests = new Map();
    #    page.on('request', request => {
    #      requests.set(request.url().split('/').pop(), request);
    #      request.continue();
    #    });
    #    await page.setRequestInterception(true);
    #    server.setRedirect('/rrredirect', '/frames/one-frame.html');
    #    await page.goto(server.PREFIX + '/rrredirect');
    #    expect(requests.get('rrredirect').isNavigationRequest()).toBe(true);
    #    expect(requests.get('one-frame.html').isNavigationRequest()).toBe(true);
    #    expect(requests.get('frame.html').isNavigationRequest()).toBe(true);
    #    expect(requests.get('script.js').isNavigationRequest()).toBe(false);
    #    expect(requests.get('style.css').isNavigationRequest()).toBe(false);
    #  });
    #  it('should work when navigating to image', async({page, server}) => {
    #    const requests = [];
    #    page.on('request', request => requests.push(request));
    #    await page.goto(server.PREFIX + '/pptr.png');
    #    expect(requests[0].isNavigationRequest()).toBe(true);
    #  });
    #});

    #describe('Page.setExtraHTTPHeaders', function() {
    #  it('should work', async({page, server}) => {
    #    await page.setExtraHTTPHeaders({
    #      foo: 'bar'
    #    });
    #    const [request] = await Promise.all([
    #      server.waitForRequest('/empty.html'),
    #      page.goto(server.EMPTY_PAGE),
    #    ]);
    #    expect(request.headers['foo']).toBe('bar');
    #  });
    #  it('should throw for non-string header values', async({page, server}) => {
    #    let error = null;
    #    try {
    #      await page.setExtraHTTPHeaders({ 'foo': 1 });
    #    } catch (e) {
    #      error = e;
    #    }
    #    expect(error.message).toBe('Expected value of header "foo" to be String, but "number" is found.');
    #  });
    #});

    #describe_fails_ffox('Page.authenticate', function() {
    #  it('should work', async({page, server}) => {
    #    server.setAuth('/empty.html', 'user', 'pass');
    #    let response = await page.goto(server.EMPTY_PAGE);
    #    expect(response.status()).toBe(401);
    #    await page.authenticate({
    #      username: 'user',
    #      password: 'pass'
    #    });
    #    response = await page.reload();
    #    expect(response.status()).toBe(200);
    #  });
    #  it('should fail if wrong credentials', async({page, server}) => {
    #    // Use unique user/password since Chrome caches credentials per origin.
    #    server.setAuth('/empty.html', 'user2', 'pass2');
    #    await page.authenticate({
    #      username: 'foo',
    #      password: 'bar'
    #    });
    #    const response = await page.goto(server.EMPTY_PAGE);
    #    expect(response.status()).toBe(401);
    #  });
    #  it('should allow disable authentication', async({page, server}) => {
    #    // Use unique user/password since Chrome caches credentials per origin.
    #    server.setAuth('/empty.html', 'user3', 'pass3');
    #    await page.authenticate({
    #      username: 'user3',
    #      password: 'pass3'
    #    });
    #    let response = await page.goto(server.EMPTY_PAGE);
    #    expect(response.status()).toBe(200);
    #    await page.authenticate(null);
    #    // Navigate to a different origin to bust Chrome's credential caching.
    #    response = await page.goto(server.CROSS_PROCESS_PREFIX + '/empty.html');
    #    expect(response.status()).toBe(401);
    #  });
    #});
  end
end
