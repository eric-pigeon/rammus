require 'json'
require 'tmpdir'
require 'set'
require 'concurrent'

module Chromiebara
  class ProtocolError < StandardError; end

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
end
