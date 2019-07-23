require 'json'
require 'tmpdir'
require 'set'
require 'concurrent'

module Rammus
  class Error < StandardError; end
  class ProtocolError < Error; end
  class TimeoutError < Error; end
  class PageCrashed < Error; end

  require 'rammus/event_emitter'
  require 'rammus/promise'

  require 'rammus/launcher'
  require 'rammus/protocol'
  require 'rammus/browser'
  require 'rammus/dom_world'
  require 'rammus/browser_context'
  require 'rammus/web_socket_client'
  require 'rammus/chrome_client'
  require 'rammus/target'
  require 'rammus/page'
  require 'rammus/cdp_session'
  require 'rammus/lifecycle_watcher'
  require 'rammus/frame'
  require 'rammus/frame_manager'
  require 'rammus/protocol_logger'
  require 'rammus/device_descriptors'

  def self.devices
    DEVICE_DESCRIPTORS
  end

  def self.launch(headless: true, args: [])
    Launcher.launch headless: headless, args: args
  end
end
