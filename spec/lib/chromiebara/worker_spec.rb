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

    it 'should report console logs' do
      message, _ = await Promise.all(
        Promise.new { |resolve, _| page.once :console, resolve },
        page.evaluate_function("() => new Worker(`data:text/javascript,console.log(1)`)")
      )
      expect(message.text).to eq '1'
      expect(message.location).to eq({
        url: 'data:text/javascript,console.log(1)',
        line_number: 0,
        column_number: 8,
      })
    end

    it 'should have JSHandles for console logs' do
      log_promise = Promise.new { |resolve, _| page.on :console, resolve }
      page.evaluate_function "() => new Worker(`data:text/javascript,console.log(1,2,3,this)`)"
      log = await log_promise
      expect(log.text).to eq '1 2 3 JSHandle@object'
      expect(log.args.length).to eq 4
      log.args.map { |arg| arg.get_property('origin').json_value }
      expect(log.args[3].get_property('origin').json_value).to eq 'null'
    end

    it 'should have an execution context' do
      worker_created_promise = Promise.new { |resolve, _|  page.once :worker_created, resolve }
      page.evaluate_function "() => new Worker(`data:text/javascript,console.log(1)`)"
      worker = await worker_created_promise
      expect(worker.execution_context.evaluate '1+1').to eq 2
    end

    it 'should report errors' do
      error_promise = Promise.new { |resolve, _| page.on :page_error, resolve }
      page.evaluate_function "() => new Worker(`data:text/javascript, throw new Error('this is my error');`)"
      error_log = await error_promise
      expect(error_log.message).to include 'this is my error'
    end
  end
end
