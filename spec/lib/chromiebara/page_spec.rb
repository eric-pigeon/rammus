module Chromiebara
  RSpec.describe Page do
    let!(:browser) { Launcher.launch }
    let!(:page) { browser.new_page }

    describe '#frames' do
      # TODO
    end

    describe '#goto' do
      # TODO
    end

    describe '#url' do
      it 'returns the pages current url' do
        expect(page.url).to eq "about:blank"
        page.goto server.empty_page
        expect(page.url).to eq server.empty_page
      end
    end
  end
end
