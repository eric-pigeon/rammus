require 'json'
require 'tmpdir'
require 'set'
require 'concurrent'

module Chromiebara
  class Error < StandardError; end
  class ProtocolError < Error; end
  class TimeoutError < Error; end
  class PageCrashed < Error; end

  require 'chromiebara/event_emitter'
  require 'chromiebara/promise'

  require 'chromiebara/launcher'
  require 'chromiebara/protocol'
  require 'chromiebara/browser'
  require 'chromiebara/dom_world'
  require 'chromiebara/browser_context'
  require 'chromiebara/web_socket_client'
  require 'chromiebara/chrome_client'
  require 'chromiebara/target'
  require 'chromiebara/page'
  require 'chromiebara/cdp_session'
  require 'chromiebara/lifecycle_watcher'
  require 'chromiebara/frame'
  require 'chromiebara/frame_manager'
  require 'chromiebara/protocol_logger'
  require 'chromiebara/device_descriptors'

  def self.devices
    DEVICE_DESCRIPTORS
  end

  def self.launch(headless: true, args: [])
    Launcher.launch headless: headless, args: args
  end
end
