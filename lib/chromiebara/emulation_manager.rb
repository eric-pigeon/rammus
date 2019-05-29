module Chromiebara
  class EmulationManager
    include Promise::Await

    attr_reader :client

    # @param [Chromiebara::CDPSession] client
    #
    def initialize(client)
      @client = client;
      @_emulating_mobile = false
      @_has_touch = false
    end

    # @return [Boolean]
    #
    def emulate_viewport(width:, height:, device_scale_factor: 1, is_mobile: false, has_touch: false, is_landscape: false)
      # /** @type {Protocol.Emulation.ScreenOrientation} */
      screen_orientation = is_landscape ? { angle: 90, type: 'landscapePrimary' } : { angle: 0, type: 'portraitPrimary' }

      await Promise.all(
        client.command(Protocol::Emulation.set_device_metrics_override(
          mobile: is_mobile,
          width: width,
          height: height,
          device_scale_factor: device_scale_factor,
          screen_orientation: screen_orientation
        )),
        client.command(Protocol::Emulation.set_touch_emulation_enabled enabled: has_touch)
      )

      reload_needed = @_emulating_mobile != is_mobile || @_has_touch != has_touch
      @_emulating_mobile = is_mobile
      @_hasTouch = has_touch
      reload_needed
    end
  end
end
