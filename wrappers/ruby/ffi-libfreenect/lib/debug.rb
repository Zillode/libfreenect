require 'freenect'
@ctx = Freenect.init()
@dev = @ctx.open_device(0)
#@dev.get_current_video_mode.should be_nil # at first
#@dev.set_video_mode(:resolution_medium, :bayer)
#@dev.set_video_mode(Freenect::RESOLUTION_LOW, Freenect::VIDEO_BAYER)
@dev.set_video_mode(2, 3)
fm = @dev.get_current_video_mode
fm.resolution.should == :resolution_medium
fm.video_or_depth_format.should == :bayer
@dev.set_video_mode(:resolution_low, :rgb)
fm = @dev.get_current_video_mode
fm.resolution.should == :resolution_low
fm.video_or_depth_format.should == :rgb

