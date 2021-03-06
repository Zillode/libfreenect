
require 'ffi/freenect'
require 'freenect/context'

module Freenect
  RawTiltState = FFI::Freenect::RawTiltState

  class DeviceError < StandardError
  end

  class Device
    # Returns a device object tracked by its ruby object reference ID stored
    # in user data.
    #
    # This method is intended for internal use.
    def self.by_reference(devp)
      unless devp.null? or (refp=FFI::Freenect.freenect_get_user(devp)).null?
        obj=ObjectSpace._id2ref(refp.read_long_long)
        return obj if obj.is_a?(Device)
      end
    end

    def initialize(ctx, idx)
      dev_p = ::FFI::MemoryPointer.new(:pointer)
      @ctx = ctx

      if ::FFI::Freenect.freenect_open_device(@ctx.context, dev_p, idx) != 0
        raise DeviceError, "unable to open device #{idx} from #{ctx.inspect}"
      end

      @dev = dev_p.read_pointer
      save_object_id!()
    end

    def closed?
      @ctx.closed? or (@dev_closed == true)
    end

    def close
      unless closed?
        if ::FFI::Freenect.freenect_close_device(@dev) == 0
          @dev_closed = true
        end
      end
    end

    def device
      if closed?
        raise DeviceError, "this device is closed and can no longer be used"
      else
        return @dev
      end
    end

    def context
      @ctx
    end

		# Defines a handler for depth events.
    #
    # @yield [device, depth_buf, timestamp]
    # @yieldparam device     A pointer to the device that generated the event.
    # @yieldparam depth_buf  A pointer to the buffer containing the depth data.
    # @yieldparam timestamp  A timestamp for the event?
    def set_depth_callback(&block)
      @depth_callback = block
      ::FFI::Freenect.freenect_set_depth_callback(self.device, @depth_callback)
    end

    alias on_depth set_depth_callback

    # Defines a handler for video events.
    #
    # @yield [device, video_buf, timestamp]
    # @yieldparam device     A pointer to the device that generated the event.
    # @yieldparam video_buf  A pointer to the buffer containing the video data.
    # @yieldparam timestamp  A timestamp for the event?
    def set_video_callback(&block)
      @video_callback = block
      ::FFI::Freenect.freenect_set_video_callback(self.device, @video_callback)
    end

    alias on_video set_video_callback

    def start_depth
      unless(::FFI::Freenect.freenect_start_depth(self.device) == 0)
        raise DeviceError, "Error in freenect_start_depth()"
      end
    end

    def start_video
      unless(::FFI::Freenect.freenect_start_video(self.device) == 0)
        raise DeviceError, "Error in freenect_start_video()"
      end
    end

		def stop_depth
      unless(::FFI::Freenect.freenect_stop_depth(self.device) == 0)
        raise DeviceError, "Error in freenect_stop_depth()"
      end
    end

    def stop_video
      unless(::FFI::Freenect.freenect_stop_video(self.device) == 0)
        raise DeviceError, "Error in freenect_stop_video()"
      end
    end

		def update_tilt_state
			ret = ::FFI::Freenect.freenect_update_tilt_state(self.device)
			if ret == 0
				return true
			else
				raise DeviceError, "freenect_update_tilt_state returned error."
			end
		end

    def get_tilt_state
      unless (p=::FFI::Freenect.freenect_get_tilt_state(self.device)).null?
        return RawTiltState.new(p)
      else
        raise DeviceError, "freenect_get_tilt_state() returned a NULL tilt_state"
      end
    end

    alias tilt_state get_tilt_state

    # Returns the current tilt angle
    def get_tilt_degrees
      ::FFI::Freenect.freenect_get_tilt_degs(self.device)
    end

    alias tilt get_tilt_degrees

    # Sets the tilt angle.
    # Maximum tilt angle range is between +30 and -30
    def set_tilt_degrees(angle)
      ::FFI::Freenect.freenect_set_tilt_degs(self.device, angle)
    end

    alias tilt= set_tilt_degrees

		def get_tilt_status(rts)
			unless rts.is_a?(Freenect::RawTiltState)
				raise ArgumentError, 'Argument is no RawTiltState'
			end
			return ::FFI::Freenect.freenect_get_tilt_status(rts)
		end

    # Sets the led to one of the following accepted values:
    #   :off,               Freenect::LED_OFF
    #   :green,             Freenect::LED_GREEN
    #   :red,               Freenect::LED_RED
    #   :yellow,            Freenect::LED_YELLOW
    #   :blink_green,       Freenect::LED_BLINK_GREEN
    #   :blink_red_yellow,  Freenect::LED_BLINK_RED_YELLOW
    #
    # Either the symbol or numeric constant can be specified.
    def set_led(mode)
      return(::FFI::Freenect.freenect_set_led(self.device, mode) == 0)
    end

    alias led= set_led

		# Returns an array with dx, dy and dz
		def get_mks_accel(rts)
			unless rts.is_a?(Freenect::RawTiltState)
				raise ArgumentError, 'Argument is no RawTiltState'
			end
			dx_x = FFI::MemoryPointer.new(:double)
			dy_y = FFI::MemoryPointer.new(:double)
			dz_p = FFI::MemoryPointer.new(:double)
			::FFI::Freenect.freenect_get_mks_accel(rts, dx_p, dy_p, dz_p)
			return [dx.read_double, dy.read_double, dz.read_double]
		end

		def get_video_mode_count
			return ::FFI::Freenect.freenect_get_video_mode_count()
		end

		def get_video_mode(mode_num)
			unless (p=::FFI::Freenect.freenect_get_video_mode(mode_num)).null?
				return FrameMode.new(p)
			else
				raise DeviceError, "freenect_get_video_mode(mode_num) returned a NULL frame mode"
			end
		end

		def get_current_video_mode
			unless (p=::FFI::Freenect.freenect_get_current_video_mode(self.device)).null?
				return FrameMode.new(p)
			else
				raise DeviceError, "freenect_get_current_video_mode(dev) returned a NULL frame mode"
			end
		end

    def set_video_mode(res, mode)
			fm = nil
			puts "R: " + res.to_s + " " + mode.to_s
			unless (p=::FFI::Freenect.freenect_find_video_mode(res, mode)).null?
				fm = FrameMode.new(p)
			else
				raise DeviceError, "set_video_mode failed to find the video_mode"
			end
      ret = ::FFI::Freenect.freenect_set_video_format(
								self.device,
								fm)
      if (ret== 0)
        return true
      else
        raise DeviceError, "Error calling freenect_set_video_format"
      end
    end

		def get_depth_mode_count
			return ::FFI::Freenect.freenect_get_depth_mode_count()
		end

		def get_depth_mode(mode_num)
			return ::FFI::Freenect.freenect_get_depth_mode(mode_num)
		end

		def get_current_depth_mode
			return ::FFI::Freenect.freenect_get_current_depth_mode(self.device)
		end

    def set_depth_mode(res, mode)
      ret = ::FFI::Freenect.freenect_set_depth_format(
								self.device,
								::FFI::Freenect.freenect_find_depth_mode(res, mode))
      if (ret== 0)
        return true
      else
        raise DeviceError, "Error calling freenect_set_depth_format"
      end
    end

    alias depth_mode= set_depth_mode

 		def reference_id
      unless (p=::FFI::Freenect.freenect_get_user(device)).null?
        p.read_long_long
      end
    end

    private
    def set_depth_buffer(buf)
    end

    def set_video_buffer(buf)
    end

    def save_object_id!
      objid_p = FFI::MemoryPointer.new(:long_long)
      objid_p.write_long_long(self.object_id)
      ::FFI::Freenect.freenect_set_user(self.device, objid_p)
    end

    def update_tilt_state
      ::FFI::Freenect.freenect_update_tilt_state(self.device)
    end

  end
end
