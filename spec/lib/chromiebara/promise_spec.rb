module Chromiebara
  RSpec.describe Promise do
    include Promise::Await

    describe '.resolve' do
      it 'returns a resolved promise with the value' do
        value = await Promise.resolve 4
        expect(value).to eq 4
      end
    end

    describe '.reject' do
      it 'returns a rejected promise with the value' do
        value = await Promise.reject(4).catch { |v| v }, 0.01
        expect(value).to eq 4
      end
    end

    describe '.all' do
      it 'returns all values' do
        promise1 = Promise.resolve(3)
        promise2 = 42;

        results = await Promise.all(promise1, promise2)
        expect(results).to eq [3, 42]
      end
    end

    describe '.race' do
      it 'returns the first promise to complete' do
        promise_1, resolve_1, _ = Promise.create
        promise_2, resolve_2, _ = Promise.create

        Thread.new { sleep 10; resolve_1.("one") }
        Thread.new { sleep 0.001; resolve_2.("two") }

        promise_3 = Promise.race(promise_1, promise_2)
        expect(await promise_3).to eq "two"
      end
    end

    describe '.create' do
      it "returns a promise and it's fulfill methods" do
        promise, resolve, reject = Promise.create

        expect(promise).to be_a Promise
        expect(resolve).to be_a Method
        expect(reject).to be_a Method
      end
    end

    describe '#initialize' do
      it 'yields resolve and reject' do
        resolve, reject = nil, nil
        _promise = Promise.new do |res, rej|
          resolve = res
          reject = rej
        end

        expect(resolve).to be_a Method
        expect(reject).to be_a Method
      end

      it 'rejects the promise if the block raises an error' do
        error = RuntimeError.new("failed")
        value = await Promise.new { |_, _| raise error }
          .catch { |err| err }, 0.01
        expect(value).to eq error
      end
    end

    describe '#then' do
      it 'creates a new promise' do
        promise = Promise.new
        expect(promise.then).to be_a Promise
      end

      it 'passes the previous result on resolve' do
        promise, fulfill, _reject = Promise.create
        previous_value = nil
        next_promse = promise.then { |value| previous_value = value }
        fulfill.(3)
        await next_promse, 0.1
        expect(previous_value).to eq 3
      end

      it 'calls the block if the promise is already resolved' do
        fulfill = nil
        promise = Promise.new { |resolve, _| fulfill = resolve }
        fulfill.(3)
        previous_value = nil
        await promise.then { |value| previous_value = value }, 0.1
        expect(previous_value).to eq 3
      end

      it 'rejects the promise if the on_resolve throws an error' do
        value = await Promise.resolve(nil)
          .then { raise "failed" }
          .catch { |error| error.message }, 0.01
        expect(value).to eq "failed"
      end

      it 'allows multiple promises to chain' do
        promise_1, resolve, _reject = Promise.create

        promise_2 = promise_1.then { 4 }
        promise_3 = promise_1.then { 5 }
        resolve.(true)

        expect(await promise_2, 0.01).to eq 4
        expect(await promise_3, 0.01).to eq 5
      end

      it 'works after catch' do
        result = Promise.resolve(3).catch { |err| 0 }.then { |num| num * 2 }

        expect(await result).to eq 6

        result = Promise.reject(3).catch { |err| 1 }.then { |num| num * 2 }

        expect(await result).to eq 2
      end
    end

    describe '#await' do
      it 'raises an error after timeout' do
        promise = Promise.new
        expect { promise.await 0.00001 }.to raise_error Timeout::Error
      end

      it 'raises UnhandledRejection if there is not a rejection handler' do
        expect do
          await Promise.new { |_fulfill, reject| reject.("Failed!") }
        end.to raise_error Promise::UnhandledRejection, 'Failed!'
      end

      it 'raises the value if the value is an Exception' do
        expect do
          await Promise.new { |_resolve, reject| reject.(StandardError.new 'Failed!') }
        end.to raise_error 'Failed!'
      end

      it 'rejects with an error' do
        promise = Promise.new
        expect { promise.await 0.00001, error: 'Timed out!' }
          .to raise_error Timeout::Error, 'Timed out!'
      end
    end

    describe '#catch' do
      it 'deals with rejected promises' do
        value = await Promise.new { |_, reject| reject.(3) }
          .catch { |error| error }, 0.01
        expect(value).to eq 3
      end

      it 'catch the end of a promise chain' do
        value = await Promise.reject(3)
          .then { |_| 4 }
          .then { |_| 5 }
          .then { |_| 6 }
          .catch { |error| error }, 0.01
        expect(value).to eq 3
      end
    end

    describe 'resolving promises' do
      it 'sets the value of the promise' do
        value = await Promise.new { |resolve, _| resolve.(3) }
        expect(value).to eq 3
      end

      it 'does not change the value of a fulfilled promise' do
        value = await Promise.new { |resolve, _| resolve.(3); resolve.(4) }
        expect(value).to eq 3
      end

      context 'when the value is a fulfilled promise' do
        it 'resolves with the value of that promise' do
          value = await Promise.resolve(Promise.resolve 4), 0.01
          expect(value).to eq 4
        end

        it 'rejects if the promise rejects' do
          value = await Promise.resolve(Promise.reject(false)).catch { 5 }, 0.01
          expect(value).to eq 5
        end
      end

      context 'when the value is a pending promise' do
        it 'waits for that promise to fulfill' do
          promise_1, _resolve, _reject = Promise.create
          promise_2 = Promise.resolve promise_1
          expect { await promise_2, 0.01 }.to raise_error Timeout::Error
        end

        it 'resolves with the value of that promise' do
          promise_1, resolve, _reject = Promise.create
          promise_2 = Promise.resolve promise_1
          resolve.(true)
          expect(await promise_2, 0.01).to eq true
        end
      end
    end

    describe 'rejecting promises' do
      it 'sets the value of the promise' do
        value = await Promise.new { |_, reject| reject.(3) }
          .catch { |error| error }, 0.01
        expect(value).to eq 3
      end

      it 'does not change the value of a fulfilled promise' do
        value = await Promise.new { |_, reject| reject.(3); reject.(4) }
          .catch { |error| error }, 0.01
        expect(value).to eq 3
      end

      context 'when the value is a fulfilled promise' do
        it 'rejects with the value of that promise' do
          value = await Promise.reject(Promise.resolve 4).catch { |v| v }, 0.01
          expect(value).to eq 4
        end
      end

      context 'when the value is a pending promise' do
        it 'waits for that promise to fulfill' do
          promise_1, _resolve, _reject = Promise.create
          promise_2 = Promise.reject(promise_1).catch { |v| v }
          expect { await promise_2, 0.01 }.to raise_error Timeout::Error
        end

        it 'rejects with the value of that promise' do
          promise_1, resolve, _reject = Promise.create
          promise_2 = Promise.reject(promise_1).catch { |v| v }
          resolve.(true)
          expect(await promise_2, 0.01).to eq true
        end
      end
    end
  end
end
