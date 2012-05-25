require "libusb"

usb = LIBUSB::Context.new
device = usb.devices(:idVendor => 0x04d8, :idProduct => 0x0033).first
device.open do |handle|
  handle.claim_interface(0)
  handle.bulk_transfer(:endpoint => 1, :dataOut => "\x76")
  ver = handle.bulk_transfer(:endpoint => 129, :dataIn => 64)
  puts "Firmware version: #{ver[0].ord}.#{ver[1].ord}.#{ver[2].ord}" 
  (1..10).each do |i|
    handle.bulk_transfer(:endpoint => 1, :dataOut => "\xA6\x01\xF5")
    sleep 0.2
    handle.bulk_transfer(:endpoint => 1, :dataOut => "\xA6\x01\xF4")
    sleep 0.5
  end
  handle.release_interface(0)
end
