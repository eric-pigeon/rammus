# module Chromiebara
#   class Driver < Capybara::Driver::Base
#     attr_reader :app, :options
#
#     def initialize(app, options = {})
#       @app       = app
#       @options   = options
#       # generate_browser_options
#       @browser   = nil
#       @inspector = nil
#       @client    = nil
#       @launcher  = nil
#       @started   = false
#     end
#
#     def visit(url)
#       # @started = true
#       browser.visit(url)
#     end
#
#     private
#
#       # logger should be an object that behaves like IO or nil
#       def browser_logger
#         options.fetch(:browser_logger, $stdout)
#       end
#
#       def browser
#         @browser ||=
#           begin
#             Browser.new(client, browser_logger) do |browser|
#             end
#           end
#       end
#
#       def client
#         @client ||=
#           begin
#           end
#       end
#
#       def launcher
#         @launcher ||= Launcher.launch(
#           headless: options.fetch(:headless, true),
#           browser_options: browser_options
#         )
#       end
#
#       def browser_options
#         {}
#       end
#   end
# end
