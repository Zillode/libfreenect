begin
  require 'rubygems'
rescue LoadError
  #nop
end

require 'ffi'

module FFI::Freenect
  extend FFI::Library
  ffi_lib 'freenect', 'freenect_sync'


	COUNTS_PER_G = 819

	DEVICE_MOTOR = 0x01
	DEVICE_CAMERA = 0x02
	DEVICE_AUDIO = 0x04

	DEVICE_FLAGS = enum( :device_motor,		DEVICE_MOTOR,
											 :device_camera,	DEVICE_CAMERA,
											 :device_audio,		DEVICE_AUDIO)

	RESOLUTION_LOW = 0
	RESOLUTION_MEDIUM = 1
	RESOLUTION_HIGH = 2
	RESOLUTION_DUMMY = 2147483647

	RESOLUTIONS = enum( :resolution_low,		RESOLUTION_LOW,
										 :resolution_medium,	RESOLUTION_MEDIUM,
										 :resolution_high,		RESOLUTION_HIGH,
										 :resolution_dummy,		RESOLUTION_DUMMY)

	VIDEO_RGB = 0
	VIDEO_BAYER = 1
	VIDEO_IR_8BIT = 2
	VIDEO_IR_10BIT = 3
	VIDEO_IR_10BIT_PACKED = 4
	VIDEO_YUV_RGB = 5
	VIDEO_YUV_RAW = 6
	VIDEO_DUMMY = 2147483647

  VIDEO_FORMATS = enum( :rgb,         VIDEO_RGB,
                       :bayer,        VIDEO_BAYER,
                       :ir_8bit,      VIDEO_IR_8BIT,
                       :ir_10,				VIDEO_IR_10BIT,
                       :ir_10bit,     VIDEO_IR_10BIT,
                       :yuv_rgb,      VIDEO_YUV_RGB,
                       :yuv_raw,      VIDEO_YUV_RAW,
											 :video_dummy,	VIDEO_DUMMY)

	DEPTH_11BIT = 0
	DEPTH_10BIT = 1
	DEPTH_11BIT_PACKED = 2
	DEPTH_10BIT_PACKED = 3
	DEPTH_DUMMY = 2147483647

  DEPTH_FORMATS = enum( :depth_11bit,         DEPTH_11BIT,
                       :depth_10bit,          DEPTH_10BIT,
                       :depth_11bit_packed,   DEPTH_11BIT_PACKED,
                       :depth_10bit_packed,   DEPTH_10BIT_PACKED,
											 :depth_dummy,					DEPTH_DUMMY)

	class VideoOrDepthFormat < FFI::Union
		layout	:dummy,					:int32_t,
						:video_format,	VIDEO_FORMATS,
						:depth_format,	DEPTH_FORMATS
	end

  class FrameMode < FFI::Struct
    layout :reserved,								:int32_t,
           #:resolution,							RESOLUTIONS, # TODO
           :resolution,							:int32_t,
					 #:video_or_depth_format,	VideoOrDepthFormat, # TODO
					 :video_or_depth_format,  :int32_t,
					 :bytes,									:int32_t,
					 :width,									:int16_t,
					 :height,									:int16_t,
					 :data_bits_per_pixel,		:int8_t,
					 :padding_bits_per_pixel,	:int8_t,
					 :framerate,							:int8_t,
					 :is_valid,								:int8_t
  end


	LED_OFF    = 0
	LED_GREEN  = 1
	LED_RED    = 2
	LED_YELLOW = 3
	LED_BLINK_GREEN = 4
	# 5 is same as 4, LED blink Green
	LED_BLINK_RED_YELLOW = 6

  LED_OPTIONS = enum( :off,               LED_OFF,
                      :green,             LED_GREEN,
                      :red,               LED_RED,
                      :yellow,            LED_YELLOW,
                      :blink_green,       LED_BLINK_GREEN,
                      :blink_red_yellow,  LED_BLINK_RED_YELLOW)


	TILT_STATUS_STOPPED = 0x00
	TILT_STATUS_LIMIT = 0x01
	TILT_STATUS_MOVING = 0x04

  TILT_STATUS_CODES = enum( :stopped,  TILT_STATUS_STOPPED,
                            :limit,    TILT_STATUS_LIMIT,
                            :moving,   TILT_STATUS_MOVING)


	class RawTiltState < FFI::Struct
    layout :accelerometer_x,  :int16_t,
           :accelerometer_y,  :int16_t,
           :accelerometer_z,  :int16_t,
           :tilt_angle,       :int8_t,
           :tilt_status,      TILT_STATUS_CODES
  end

	typedef :pointer, :freenect_context
  typedef :pointer, :freenect_device
  typedef :pointer, :freenect_usb_context # actually a libusb_context

	LOG_FATAL = 0
	LOG_ERROR = 1
	LOG_WARNING = 2
	LOG_NOTICE = 3
	LOG_INFO = 4
	LOG_DEBUG = 5
	LOG_SPEW = 6
	LOG_FLOOD = 7

  LOGLEVELS = enum( :fatal,   LOG_FATAL,
                    :error,   LOG_ERROR,
                    :warning, LOG_WARNING,
                    :notice,  LOG_NOTICE,
                    :info,    LOG_INFO,
                    :debug,   LOG_DEBUG,
                    :spew,    LOG_SPEW,
                    :flood,   LOG_FLOOD)


  attach_function :freenect_init, [:freenect_context, :freenect_usb_context], :int
  attach_function :freenect_shutdown, [:freenect_context], :int
  callback :freenect_log_cb, [:freenect_context, LOGLEVELS, :string], :void
  attach_function :freenect_set_log_level, [:freenect_context, LOGLEVELS], :void
  attach_function :freenect_set_log_callback, [:freenect_context, :freenect_log_cb], :void
  attach_function :freenect_process_events, [:freenect_context], :int
  attach_function :freenect_num_devices, [:freenect_context], :int
  attach_function :freenect_select_subdevices, [:freenect_context, DEVICE_FLAGS], :void
  attach_function :freenect_open_device, [:freenect_context, :freenect_device, :int], :int
  attach_function :freenect_close_device, [:freenect_device], :int
  attach_function :freenect_set_user, [:freenect_device, :pointer], :void
  attach_function :freenect_get_user, [:freenect_device], :pointer
  callback :freenect_depth_cb, [:freenect_device, :pointer, :uint32], :void
  callback :freenect_video_cb, [:freenect_device, :pointer, :uint32], :void
  attach_function :freenect_set_depth_callback, [:freenect_device, :freenect_depth_cb], :void
  attach_function :freenect_set_video_callback, [:freenect_device, :freenect_video_cb], :void
  attach_function :freenect_set_depth_buffer, [:freenect_device, :pointer], :int
  attach_function :freenect_set_video_buffer, [:freenect_device, :pointer], :int
  attach_function :freenect_start_depth, [:freenect_device], :int
  attach_function :freenect_start_video, [:freenect_device], :int
  attach_function :freenect_stop_depth, [:freenect_device], :int
  attach_function :freenect_stop_video, [:freenect_device], :int
  attach_function :freenect_update_tilt_state, [:freenect_device], :int
  attach_function :freenect_get_tilt_state, [:freenect_device], RawTiltState
  attach_function :freenect_get_tilt_degs, [:freenect_device], :double
  attach_function :freenect_set_tilt_degs, [:freenect_device, :double], :int
  attach_function :freenect_get_tilt_status, [RawTiltState], TILT_STATUS_CODES
  attach_function :freenect_set_led, [:freenect_device, LED_OPTIONS], :int
  attach_function :freenect_get_mks_accel, [RawTiltState, :pointer, :pointer, :pointer], :void
  attach_function :freenect_get_video_mode_count, [], :int
	attach_function :freenect_get_video_mode, [:int], FrameMode
	attach_function :freenect_get_current_video_mode, [:freenect_device], FrameMode
	attach_function :freenect_find_video_mode, [RESOLUTIONS, VIDEO_FORMATS], FrameMode
	attach_function :freenect_set_video_mode, [:freenect_device, FrameMode], :int
	attach_function :freenect_get_depth_mode_count, [], :int
	attach_function :freenect_get_depth_mode, [:int], FrameMode
	attach_function :freenect_get_current_depth_mode, [:freenect_device], FrameMode
	attach_function :freenect_find_depth_mode, [RESOLUTIONS, DEPTH_FORMATS], FrameMode
	attach_function :freenect_set_depth_mode, [:freenect_device, FrameMode], :int

end


