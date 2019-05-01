module Chromiebara
  RSpec.describe Page do
    let!(:browser) { Launcher.launch }
    let!(:page) { browser.new_page }

    describe '#frames' do
      # todo
    end

    describe '#goto' do
    end

    describe '#url' do
      it 'returns the pages current url' do
        expect(page.url).to eq "about:blank"
        # expect(page.url()).toBe('about:blank');
        # await page.goto(server.EMPTY_PAGE);
        # expect(page.url()).toBe(server.EMPTY_PAGE);
      end
    end
  end
end
