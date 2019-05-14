module Chromiebara
  RSpec.describe Promise do
    include Promise::Await

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
          .catch { |err| err }
        expect(value).to eq error
      end
    end

    describe '#then' do
      it 'creates a new promise' do
        promise = Promise.new
        expect(promise.then).to be_a Promise
      end

      it 'passes the previous result on resolve' do
        fulfill = nil
        promise = Promise.new { |resolve, _| fulfill = resolve }
        previous_value = nil
        promise.then { |value| previous_value = value }
        fulfill.(3)
        expect(previous_value).to eq 3
      end

      it 'calls the block if the promise is already resolved' do
        fulfill = nil
        promise = Promise.new { |resolve, _| fulfill = resolve }
        fulfill.(3)
        previous_value = nil
        promise.then { |value| previous_value = value }
        expect(previous_value).to eq 3
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
        end.to raise_error Promise::UnhandledRejection
      end
    end

    describe '#catch' do
      it 'deals with rejected promises' do
        value = await Promise.new { |_, reject| reject.(3) }
          .catch { |error| error }
        expect(value).to eq 3
      end

      it 'catch the end of a promise chain' do
        value = await Promise.new { |_, reject| reject.(3) }
          .then { |_| 4 }
          .then { |_| 5 }
          .then { |_| 6 }
          .catch { |error| error }
        expect(value).to eq 3
      end
    end

    describe 'resolve' do
      it 'sets the value of the promise' do
        value = await Promise.new { |resolve, _| resolve.(3) }
        expect(value).to eq 3
      end

      it 'does not change the value of a fulfilled promise' do
        value = await Promise.new { |resolve, _| resolve.(3); resolve.(4) }
        expect(value).to eq 3
      end
    end

    describe 'rejection' do
      it 'sets the value of the promise' do
        value = await Promise.new { |_, reject| reject.(3) }
          .catch { |error| error }
        expect(value).to eq 3
      end

      it 'does not change the value of a fulfilled promise' do
        value = await Promise.new { |_, reject| reject.(3); reject.(4) }
          .catch { |error| error }
        expect(value).to eq 3
      end
    end
  end
end
