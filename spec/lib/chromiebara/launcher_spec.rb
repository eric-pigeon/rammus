module Chromiebara
  RSpec.describe Launcher do
    describe 'Launcher.launch' do
      it 'use data dir' do
        browser = Launcher.launch

        expect(Dir.empty? browser.tmpdir).to eq false
      end
    end
  end
end
