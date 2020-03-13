module Rammus
  RSpec.describe Tracing, browser: true do
    before { @_context = browser.create_context }
    after { @_context.close }
    let(:context) { @_context }
    let!(:page) { context.new_page }

    let(:output_file) { File.expand_path("../../tmp/trace.json", File.dirname(__FILE__)) }
    after { File.delete output_file if File.exist? output_file }

    it 'should output a trace' do
      page.tracing.start screenshots: true, path: output_file
      page.goto(server.domain + 'grid.html').wait!
      page.tracing.stop
      expect(File.exist? output_file).to eq true
    end

    it 'should run with custom categories if provided' do
      page.tracing.start path: output_file, categories: ['disabled-by-default-v8.cpu_profiler.hires']
      page.tracing.stop

      trace_json = JSON.parse File.read output_file
      expect(trace_json["metadata"]["trace-config"]).to include 'disabled-by-default-v8.cpu_profiler.hires'
    end

    it 'should throw if tracing on two pages' do
      page.tracing.start(path: output_file)
      new_page = browser.new_page
      expect { new_page.tracing.start path: output_file }
        .to raise_error Errors::ProtocolError, /Tracing has already been started/
      new_page.close
      page.tracing.stop
    end

    it 'should return a buffer' do
      trace = page.tracing.start(screenshots: true, path: output_file) do
        page.goto(server.domain + 'grid.html').wait!
      end
      buf = File.read output_file
      expect(trace).to eq buf
    end

    it 'should work without options' do
      trace = page.tracing.start do
        page.goto(server.domain + 'grid.html').wait!
      end
      expect(trace).not_to be_nil
    end

    it 'should support without a path' do
      trace = page.tracing.start screenshots: true do
        page.goto(server.domain + 'grid.html').wait!
      end
      expect(trace).to include 'screenshot'
    end
  end
end
