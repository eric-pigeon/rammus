# class WaitTask {
#   /**
#    * @param {!DOMWorld} domWorld
#    * @param {Function|string} predicateBody
#    * @param {string|number} polling
#    * @param {number} timeout
#    * @param {!Array<*>} args
#    */
#   constructor(domWorld, predicateBody, title, polling, timeout, ...args) {
#     if (helper.isString(polling))
#       assert(polling === 'raf' || polling === 'mutation', 'Unknown polling option: ' + polling);
#     else if (helper.isNumber(polling))
#       assert(polling > 0, 'Cannot poll with non-positive interval: ' + polling);
#     else
#       throw new Error('Unknown polling options: ' + polling);
#
#     this._domWorld = domWorld;
#     this._polling = polling;
#     this._timeout = timeout;
#     this._predicateBody = helper.isString(predicateBody) ? 'return (' + predicateBody + ')' : 'return (' + predicateBody + ')(...args)';
#     this._args = args;
#     this._runCount = 0;
#     domWorld._waitTasks.add(this);
#     this.promise = new Promise((resolve, reject) => {
#       this._resolve = resolve;
#       this._reject = reject;
#     });
#     // Since page navigation requires us to re-install the pageScript, we should track
#     // timeout on our end.
#     if (timeout) {
#       const timeoutError = new TimeoutError(`waiting for ${title} failed: timeout ${timeout}ms exceeded`);
#       this._timeoutTimer = setTimeout(() => this.terminate(timeoutError), timeout);
#     }
#     this.rerun();
#   }
#
#   /**
#    * @param {!Error} error
#    */
#   terminate(error) {
#     this._terminated = true;
#     this._reject(error);
#     this._cleanup();
#   }
#
#   async rerun() {
#     const runCount = ++this._runCount;
#     /** @type {?Puppeteer.JSHandle} */
#     let success = null;
#     let error = null;
#     try {
#       success = await (await this._domWorld.executionContext()).evaluateHandle(waitForPredicatePageFunction, this._predicateBody, this._polling, this._timeout, ...this._args);
#     } catch (e) {
#       error = e;
#     }
#
#     if (this._terminated || runCount !== this._runCount) {
#       if (success)
#         await success.dispose();
#       return;
#     }
#
#     // Ignore timeouts in pageScript - we track timeouts ourselves.
#     // If the frame's execution context has already changed, `frame.evaluate` will
#     // throw an error - ignore this predicate run altogether.
#     if (!error && await this._domWorld.evaluate(s => !s, success).catch(e => true)) {
#       await success.dispose();
#       return;
#     }
#
#     // When the page is navigated, the promise is rejected.
#     // We will try again in the new execution context.
#     if (error && error.message.includes('Execution context was destroyed'))
#       return;
#
#     // We could have tried to evaluate in a context which was already
#     // destroyed.
#     if (error && error.message.includes('Cannot find context with specified id'))
#       return;
#
#     if (error)
#       this._reject(error);
#     else
#       this._resolve(success);
#
#     this._cleanup();
#   }
#
#   _cleanup() {
#     clearTimeout(this._timeoutTimer);
#     this._domWorld._waitTasks.delete(this);
#     this._runningTask = null;
#   }
# }
