# frozen_string_literal: true

module Rammus
  RSpec.describe 'Workers', browser: true do
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    it 'Page#workers' do
      Concurrent::Promises.zip(
        Concurrent::Promises.resolvable_future.tap { |future| page.once :worker_created, future.method(:fulfill) },
        page.goto(server.domain + 'worker/worker.html')
      ).wait!
      worker = page.workers[0]
      expect(worker.url).to include 'worker.js'

      expect(worker.evaluate_function('() => self.workerFunction()').value!)
        .to eq 'worker function result'

      page.goto(server.empty_page).wait!
      expect(page.workers.length).to eq 0
    end

    it 'should emit created and destroyed events' do
      worker_created_promise = Concurrent::Promises.resolvable_future.tap do |future|
        page.once :worker_created, future.method(:fulfill)
      end
      worker_object = page.evaluate_handle_function('() => new Worker("data:text/javascript,1")').value!
      worker = worker_created_promise.value!
      worker_this = worker.evaluate_handle_function('() => this').value!
      worker_destroyed_promise = Concurrent::Promises.resolvable_future.tap do |future|
        page.once :worker_destroyed, future.method(:fulfill)
      end
      page.evaluate_function('workerObj => workerObj.terminate()', worker_object).wait!
      expect(worker_destroyed_promise.value!).to eq worker
      expect { worker_this.get_property 'self' }.to raise_error(/Most likely the worker has been closed./)
    end

    it 'should report console logs' do
      message, _ = Concurrent::Promises.zip(
        Concurrent::Promises.resolvable_future.tap { |future| page.once :console, future.method(:fulfill) },
        page.evaluate_function("() => new Worker(`data:text/javascript,console.log(1)`)")
      ).value!
      expect(message.text).to eq '1'
      expect(message.location).to eq(
        url: 'data:text/javascript,console.log(1)',
        line_number: 0,
        column_number: 8
      )
    end

    it 'should have JSHandles for console logs' do
      log_promise = Concurrent::Promises.resolvable_future.tap do |future|
        page.on :console, future.method(:fulfill)
      end
      page.evaluate_function("() => new Worker(`data:text/javascript,console.log(1,2,3,this)`)").wait!
      log = log_promise.value!
      expect(log.text).to eq '1 2 3 JSHandle@object'
      expect(log.args.length).to eq 4
      log.args.map { |arg| arg.get_property('origin').json_value }
      expect(log.args[3].get_property('origin').json_value).to eq 'null'
    end

    it 'should have an execution context' do
      worker_created_promise = Concurrent::Promises.resolvable_future.tap do |future|
        page.once :worker_created, future.method(:fulfill)
      end
      page.evaluate_function("() => new Worker(`data:text/javascript,console.log(1)`)").wait!
      worker = worker_created_promise.value!
      expect(worker.execution_context.evaluate('1+1').value!).to eq 2
    end

    it 'should report errors' do
      error_promise = Concurrent::Promises.resolvable_future.tap do |future|
        page.on :page_error, future.method(:fulfill)
      end
      page.evaluate_function("() => new Worker(`data:text/javascript, throw new Error('this is my error');`)").wait!
      error_log = error_promise.value!
      expect(error_log.message).to include 'this is my error'
    end
  end
end
