module Chromiebara
  RSpec.describe Response do
    describe '#await' do
      it 'raises an error after timeout' do
        expect { Response.new.await 0.01 }.to raise_error Timeout::Error
      end
    end
  end
end
