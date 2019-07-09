require 'chromiebara'
require 'support/test_server'
require 'support/match_screenshot'
require 'support/test_emitter'
if RUBY_ENGINE != "jruby"
  require 'byebug'
end

class Server
  def domain
    'http://localhost:4567/'
  end

  def cross_process_domain
    'http://127.0.0.1:4567/'
  end

  def port
    4567
  end

  def empty_page
    domain + "empty.html"
  end

  def set_content_security_policy(path, policy)
    TestServer.instance.set_content_security_policy path, policy
  end

  def set_route(path, &block)
    TestServer.instance.set_route path, &block
  end

  def hang_route(path)
    TestServer.instance.hang_route path
  end

  def set_redirect(from, to)
    TestServer.instance.set_redirect from, to
  end

  def set_auth(path, username, password)
    TestServer.instance.set_auth path, username, password
  end

  def wait_for_request(path)
    TestServer.instance.wait_for_request path
  end

  def enable_gzip(path)
    TestServer.instance.enable_gzip path
  end

  def reset
    TestServer.instance.reset
  end
end

module SeverHelper
  extend RSpec::SharedContext

  let(:server) { Server.new }

  def attach_frame(page, frame_id, url)
    function = <<~JAVASCRIPT
    async function attachFrame(frameId, url) {
      const frame = document.createElement('iframe');
      frame.src = url;
      frame.id = frameId;
      document.body.appendChild(frame);
      await new Promise(x => frame.onload = x);
      return frame;
    }
    JAVASCRIPT
    handle = await page.evaluate_handle_function function, frame_id, url
    handle.as_element.content_frame
  end

  def detach_frame(page, frame_id)
    function = <<~JAVASCRIPT
      function detachFrame(frameId) {
        const frame = document.getElementById(frameId);
        frame.remove();
      }
    JAVASCRIPT
    await page.evaluate_function function, frame_id
  end

  def is_favicon(request)
    request.url.include? 'favicon.ico'
  end

  def wait_event(emitter, event_name, predicate = nil, &block)
    predicate ||= block || ->(_) { true }

    Chromiebara::Promise.new do |resolve, _|
      listener = -> (event) do
        next unless predicate.(event)

        emitter.remove_listener event_name, listener
        resolve.(event)
      end
      emitter.on event_name, listener
    end
  end

  after(:each) { server.reset }

  shared_context 'browser', browser: true do
    include Chromiebara::Promise::Await

    before(:context) { @_browser = Chromiebara::Launcher.launch }

    let(:browser) { @_browser }

    after(:context) { @_browser.close }
  end

  shared_context 'page', page: true do
    include Chromiebara::Promise::Await

    before(:context) { @_browser = Chromiebara.launch }
    before { @_context = browser.create_context }

    let(:browser) { @_browser }
    let(:context) { @_context }
    let(:page) { context.new_page }

    before do
      page.on :error, ->(error) do
        raise error if page.listener_count(:error) == 1
      end
    end

    after(:context) { @_browser.close }
    after { @_context.close }
  end
end

RSpec.configure do |config|
  config.include SeverHelper
  config.include MatchScreenshot

  config.before(:suite) do
    #Thread.new { TestApp.run! }
    Thread.new { TestServer.start! }
  end

  config.after(:suite) do
    #TestApp.stop!
    TestServer.stop!
  end
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

# The settings below are suggested to provide a good initial experience
# with RSpec, but feel free to customize to your heart's content.
=begin
  # This allows you to limit a spec run to individual examples or groups
  # you care about by tagging them with `:focus` metadata. When nothing
  # is tagged with `:focus`, all examples get run. RSpec also provides
  # aliases for `it`, `describe`, and `context` that include `:focus`
  # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus
=end

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  config.disable_monkey_patching!

  config.warnings = true

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = "doc"
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end
