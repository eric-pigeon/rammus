module Rammus
  class WaitTask
    include Promise::Await

    attr_reader :promise, :dom_world

    # @param {!DOMWorld} dom_world
    # @param {Function|string} predicateBody
    # @param {string|number} polling
    # @param {number} timeout
    # @param {!Array<*>} args
    #
    def initialize(dom_world, predicate_body, title, polling, timeout, *args)
      if polling.is_a? String
        raise "Unknown polling option: #{polling}" unless polling == 'raf' || polling == 'mutation'
      elsif polling.is_a? Numeric
        raise "Cannot poll with non-positive interval: #{polling}" if polling.negative?
      else
        raise "Unknown polling options: #{polling}"
      end

      @dom_world = dom_world
      @_polling = polling
      @_timeout = timeout
      @_predicate_body = if args.empty?
                           "return (#{predicate_body})"
                         else
                           "return (#{predicate_body})(...args)";
                         end
      @_args = args
      @_run_count = 0
      dom_world.wait_tasks << self
      @promise, @_resolve, @_reject = Promise.create
      @_terminated = false
      # Since page navigation requires us to re-install the page script, we should track
      # timeout on our end.
      if timeout && timeout != 0
        @_timeout_timer = Concurrent::ScheduledTask.execute(timeout) do
          terminate TimeoutError.new "waiting for #{title} failed: timeout #{timeout}s exeeded"
        end
      end
      Concurrent.global_io_executor.post { rerun }
    end

    # @param {!Error} error
    #
    def terminate(error)
      @_terminated = true
      @_reject.(error)
      cleanup
    end

    def rerun
      @_run_count += 1
      # @type {?Puppeteer.JSHandle}
      success = nil
      error = nil
      begin
        success = await dom_world.execution_context.evaluate_handle_function(
          WAIT_FOR_PREDICATE_PAGE_FUNCTION,
          @_predicate_body,
          @_polling,
          @_timeout * 1000, # javascript set timeout is in milliseconds
          *@_args
        ), 0
      rescue => err
        error = err
      end

      #if (this._terminated || runCount !== this._runCount) {
      if @_terminated
        await success.dispose if success

        return
      end

      # Ignore timeouts in pageScript - we track timeouts ourselves.
      # If the frame's execution context has already changed, `frame.evaluate` will
      # throw an error - ignore this predicate run altogether.
      if error.nil? && (await dom_world.evaluate_function("s => !s", success).catch { |err| true })
        success.dispose
        return
      end

      # When the page is navigated, the promise is rejected.
      # We will try again in the new execution context.
      return if error&.message&.include? 'Execution context was destroyed'

      # We could have tried to evaluate in a context which was already
      # destroyed.
      return if error&.message&.include? 'Cannot find context with specified id'

      if error
        @_reject.(error)
      else
        @_resolve.(success)
      end

      cleanup
    end

    private

      WAIT_FOR_PREDICATE_PAGE_FUNCTION = <<~JAVASCRIPT
      /**
       * @param {string} predicateBody
       * @param {string} polling
       * @param {number} timeout
       * @return {!Promise<*>}
       */
      async function waitForPredicatePageFunction(predicateBody, polling, timeout, ...args) {
        const predicate = new Function('...args', predicateBody);
        let timedOut = false;
        if (timeout)
          setTimeout(() => timedOut = true, timeout);
        if (polling === 'raf')
          return await pollRaf();
        if (polling === 'mutation')
          return await pollMutation();
        if (typeof polling === 'number')
          return await pollInterval(polling);

        /**
         * @return {!Promise<*>}
         */
        function pollMutation() {
          const success = predicate.apply(null, args);
          if (success)
            return Promise.resolve(success);

          let fulfill;
          const result = new Promise(x => fulfill = x);
          const observer = new MutationObserver(mutations => {
            if (timedOut) {
              observer.disconnect();
              fulfill();
            }
            const success = predicate.apply(null, args);
            if (success) {
              observer.disconnect();
              fulfill(success);
            }
          });
          observer.observe(document, {
            childList: true,
            subtree: true,
            attributes: true
          });
          return result;
        }

        /**
         * @return {!Promise<*>}
         */
        function pollRaf() {
          let fulfill;
          const result = new Promise(x => fulfill = x);
          onRaf();
          return result;

          function onRaf() {
            if (timedOut) {
              fulfill();
              return;
            }
            const success = predicate.apply(null, args);
            if (success)
              fulfill(success);
            else
              requestAnimationFrame(onRaf);
          }
        }

        /**
         * @param {number} pollInterval
         * @return {!Promise<*>}
         */
        function pollInterval(pollInterval) {
          let fulfill;
          const result = new Promise(x => fulfill = x);
          onTimeout();
          return result;

          function onTimeout() {
            if (timedOut) {
              fulfill();
              return;
            }
            const success = predicate.apply(null, args);
            if (success)
              fulfill(success);
            else
              setTimeout(onTimeout, pollInterval);
          }
        }
      }
      JAVASCRIPT

      def cleanup
        #clearTimeout(this._timeoutTimer);
        dom_world.wait_tasks.delete self
        #this._runningTask = null;
      end
  end
end
