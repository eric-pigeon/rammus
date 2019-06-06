module Chromiebara
  RSpec.describe 'Workers', browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    it 'Page#workers' do
      await Promise.all(
        Promise.new { |resolve, _| page.once :worker_created, resolve },
        page.goto(server.domain + 'worker/worker.html')
      )
      worker = page.workers[0]
      expect(worker.url).to include 'worker.js'

      expect(worker.evaluate_function '() => self.workerFunction()').to eq 'worker function result'

      page.goto server.empty_page
      expect(page.workers.length).to eq 0
    end

    it 'should emit created and destroyed events' do
      worker_created_promise = Promise.new { |resolve, _| page.once :worker_created, resolve }
      worker_object = page.evaluate_handle_function '() => new Worker("data:text/javascript,1")'
      worker = await worker_created_promise
      worker_this = worker.evaluate_handle_function '() => this'
      worker_destroyed_promise = Promise.new { |resolve, _| page.once :worker_destroyed, resolve }
      page.evaluate_function 'workerObj => workerObj.terminate()', worker_object
      expect(await worker_destroyed_promise).to eq worker
      expect { worker_this.get_property 'self' }.to raise_error(/Most likely the worker has been closed./)
    end

    #it('should report console logs', async function({page}) {
    #  const [message] = await Promise.all([
    #    waitEvent(page, 'console'),
    #    page.evaluate(() => new Worker(`data:text/javascript,console.log(1)`)),
    #  ]);
    #  expect(message.text()).toBe('1');
    #  expect(message.location()).toEqual({
    #    url: 'data:text/javascript,console.log(1)',
    #    lineNumber: 0,
    #    columnNumber: 8,
    #  });
    #});
    #it('should have JSHandles for console logs', async function({page}) {
    #  const logPromise = new Promise(x => page.on('console', x));
    #  await page.evaluate(() => new Worker(`data:text/javascript,console.log(1,2,3,this)`));
    #  const log = await logPromise;
    #  expect(log.text()).toBe('1 2 3 JSHandle@object');
    #  expect(log.args().length).toBe(4);
    #  expect(await (await log.args()[3].getProperty('origin')).jsonValue()).toBe('null');
    #});
    #it('should have an execution context', async function({page}) {
    #  const workerCreatedPromise = new Promise(x => page.once('workercreated', x));
    #  await page.evaluate(() => new Worker(`data:text/javascript,console.log(1)`));
    #  const worker = await workerCreatedPromise;
    #  expect(await (await worker.executionContext()).evaluate('1+1')).toBe(2);
    #});
    #it('should report errors', async function({page}) {
    #  const errorPromise = new Promise(x => page.on('pageerror', x));
    #  await page.evaluate(() => new Worker(`data:text/javascript, throw new Error('this is my error');`));
    #  const errorLog = await errorPromise;
    #  expect(errorLog.message).toContain('this is my error');
    #});
  end
end
