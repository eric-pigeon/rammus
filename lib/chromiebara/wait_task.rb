module Chromiebara
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
      #if (helper.isString(polling))
      #  assert(polling === 'raf' || polling === 'mutation', 'Unknown polling option: ' + polling);
      #else if (helper.isNumber(polling))
      #  assert(polling > 0, 'Cannot poll with non-positive interval: ' + polling);
      #else
      #  throw new Error('Unknown polling options: ' + polling);

      @dom_world = dom_world
      @_polling = polling
      @_timeout = timeout
      @_predicate_body = "return (#{predicate_body})(...args)";
      #this._predicateBody = helper.isString(predicateBody) ? 'return (' + predicateBody + ')' : 'return (' + predicateBody + ')(...args)';
      @_args = args
      @_run_count = 0
      dom_world.wait_tasks << self
      @promise, @_resolve, @_reject = Promise.create
      # Since page navigation requires us to re-install the pageScript, we should track
      # timeout on our end.
      #if (timeout) {
      #  const timeoutError = new TimeoutError(`waiting for ${title} failed: timeout ${timeout}ms exceeded`);
      #  this._timeoutTimer = setTimeout(() => this.terminate(timeoutError), timeout);
      #}
      rerun
    end

    # @param {!Error} error
    #
    #terminate(error) {
    #  this._terminated = true;
    #  this._reject(error);
    #  this._cleanup();
    #}

    def rerun
      @_run_count += 1
      # @type {?Puppeteer.JSHandle}
      success = nil
      error = nil
      begin
        success = dom_world.execution_context.evaluate_handle_function(
          WAIT_FOR_PREDICATE_PAGE_FUNCTION,
          @_predicate_body,
          @_polling,
          @_timeout,
          *@_args
        )
      rescue => err
        error = err
      end

      #if (this._terminated || runCount !== this._runCount) {
      #  if (success)
      #    await success.dispose();
      #  return;
      #}

      # Ignore timeouts in pageScript - we track timeouts ourselves.
      # If the frame's execution context has already changed, `frame.evaluate` will
      # throw an error - ignore this predicate run altogether.
      #if (!error && await this._dom_world.evaluate(s => !s, success).catch(e => true)) {
      #  await success.dispose();
      #  return;
      #}

      #// When the page is navigated, the promise is rejected.
      #// We will try again in the new execution context.
      #if (error && error.message.includes('Execution context was destroyed'))
      #  return;

      #// We could have tried to evaluate in a context which was already
      #// destroyed.
      #if (error && error.message.includes('Cannot find context with specified id'))
      #  return;

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
        #this._dom_world._waitTasks.delete(this);
        #this._runningTask = null;
      end
  end
end
