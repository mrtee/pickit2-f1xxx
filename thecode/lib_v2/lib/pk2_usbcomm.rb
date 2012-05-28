module PICkit2

  # Class for dealing with opening, closing the device, and transfering
  # 64-byte blocks
  #
  # Low level access:
  #
  #   $LOAD_PATH << "./lib"
  #   require 'usbcomm'
  #   device = PICkit2::Programmer.new
  #   device.claim
  #   device.send("\x76") # read firmware version
  #   ver = device.receive
  #   puts "Firmware version: #{ver[0].ord}.#{ver[1].ord}.#{ver[2].ord}"
  #   device.release
  #
  # High level access:
  #
  #   $LOAD_PATH << "./lib"</tt>
  #   require 'usbcomm'
  #   device = PICkit2::Programmer.new
  #   device.claim
  #   puts device.checkFirmwareVersion.inspect
  #   device.release
  class Programmer
    require "libusb"
    
    # Find and open the device:
    #    device.claim
    def claim
      @usb = LIBUSB::Context.new
      @device = @usb.devices(:idVendor => 0x04d8, :idProduct => 0x0033).first
      @mic = @device.open
      @mic.claim_interface(0)
      self
    end
    alias_method :open, :claim

    # Close the device:
    #   device.release
    def release
      @mic.release_interface(0)
      @mic.close
    end
    alias_method :close, :release

    # Send command block to the device.
    # Input can be either string or unflattened Array of integers.
    #   device.send(cmd)
    # It is not necessary for string to be 64 bytes long, the method extends
    # it to 64 bytes length by filling with 0xAD "END_OF_BUFFER" command bytes
    def send(*block)
      if block[0].class == String
	block = block[0]
      else
	block = block.flatten.select {|q| q.kind_of?(Numeric)}.pack("C*")
      end
      @mic.bulk_transfer(:endpoint => 1, :dataOut => block+"\xad"*(64-block.length))
    end

    # Receives 64 byte string block from the device
    #   block = device.receive
    # As an option it can send a command as well
    #   block = device.receive(block_to_send)
    def receive(*block)
      block[0] && send(block)
      return @mic.bulk_transfer(:endpoint => 129, :dataIn => 64)
    end
    alias_method :get, :receive

  end

end


