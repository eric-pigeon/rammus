module Chromiebara
  RSpec.describe Page, browser: true do
    let!(:page) { browser.new_page }

    describe '#frames' do
      it 'returns all frames in the page' do
        page.goto server.domain + "frames/nested-frames.html"
        # page.goto server.domain + "frames/nested-frames.html"
        # all lifecycle events happen before Page.navigated(which updates the url) happen
        expected_frames = [
          "http://localhost:4567/frames/nested-frames.html",
          "http://localhost:4567/frames/two-frames.html",
          "http://localhost:4567/frames/frame.html",
          "http://localhost:4567/frames/frame.html",
          "http://localhost:4567/frames/frame.html"
        ]
        expect(page.frames.map(&:url)).to eq expected_frames
      end
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

    describe '#title' do
      xit 'should return the page title' do
        page.goto server.domain + "/title.html"
        expect(page.title).to eq 'Woof-Woof'
      end
    end
  end
end
