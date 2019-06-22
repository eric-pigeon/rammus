module Chromiebara
  RSpec.describe 'Input', browser: true do
    include Promise::Await
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    it 'should upload the file' do
      page.goto server.domain + 'input/fileupload.html'
      file_path = File.expand_path("../../../fixtures", __FILE__) + '/file-to-upload.txt'
      input = page.query_selector 'input'
      input.upload_file file_path
      expect(await page.evaluate_function "e => e.files[0].name", input).to eq 'file-to-upload.txt'
      expect(await page.evaluate_function "e => {
        const reader = new FileReader();
        const promise = new Promise(fulfill => reader.onload = fulfill);
        reader.readAsText(e.files[0]);
        return promise.then(() => reader.result);
      }", input).to eq "contents of the file\n"
    end
  end
end
