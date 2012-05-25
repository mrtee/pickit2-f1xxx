module PICkit2

  MIN_FW_VERSION_REQUIRED = "2.23.0"
  MAX_FW_VERSION_REQUIRED = "2.255.0"

  # Class for dealing with opening, closing the device, and transfering
  # 64-byte blocks
  #
  # Low level access:
  #
  #   $LOAD_PATH << "."
  #   require 'pickit2'
  #   device = PICkit2::Programmer.new
  #   device.claim
  #   device.send("\x76") # read firmware version
  #   ver = device.receive
  #   puts "Firmware version: #{ver[0].ord}.#{ver[1].ord}.#{ver[2].ord}"
  #   device.release
  #
  # High level access:
  #
  #   $LOAD_PATH << "."</tt>
  #   require 'pickit2'
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
    end
    alias_method :open, :claim

    # Close the device:
    #   device.release
    def release
      @mic.release_interface(0)
      @mic.close
    end
    alias_method :close, :release

    # Send command block string
    #   device.send(string)
    # It is not necessary for string to be 64 bytes long, the method extends
    # it to 64 bytes length by filling with 0xAD "END_OF_BUFFER" command bytes
    def send(block)
      puts block.inspect
      @mic.bulk_transfer(:endpoint => 1, :dataOut => block+"\xad"*(64-block.length))
      
    end

    # Receives 64 byte string block from the device
    #   block = device.receive
    # As an option it can send a command as well
    #   block = device.receive(block_string)
    def receive(*block)
      block[0] && send(block[0])
      return @mic.bulk_transfer(:endpoint => 129, :dataIn => 64)
    end
    alias_method :get, :receive

    # Read firmware version and check it against minimum and maximum values
    # Optional hash parameters :min and :max could be added. Otherwise the method
    # checks the firmware vaersion against built-in constants MIN_FW_VERSION_REQUIRED
    # and MAX_FW_VERSION_REQUIRED. Parameters should contain text like "2.32.0".
    # Method return the actual version in text form and in original 3-byte string form.
    # Method returns the boolean type of the check result. The :check hash symbol will
    # be true if the version matches the specified range
    #   ver = device.checkFirmwareVersion(:max => "2.40.0")
    #   puts("Firmware version: #{ver[:version_text]}")
    #   puts ver.inspect
    # or simply:
    # device.checkFirmwareVersion[:check] && puts("Version OK.")
    def checkFirmwareVersion(args = {:min => MIN_FW_VERSION_REQUIRED})
      def versionTextToMachineString(text)
        return text.split(/\./).map{|x|x.to_i}.pack("CCC")
      end
      args[:max] ||= MAX_FW_VERSION_REQUIRED
      answer = receive(Command.new {|x| x.firmware_version})[0..2]
      min = versionTextToMachineString(args[:min])
      max = versionTextToMachineString(args[:max])
      check = (answer >= min) & (answer <= max)
      version = String.new
      answer.each_byte {|x| version << x.to_s+"."}
      return {:check => check, :version_text => version[0..-2], :version_machineString => answer}
    end

    # Get status information and calculate boolean results.
    # :okForFirstRead will be true if the status is OK for a first time read
    # after reset.
    # :ok will be true for further checkings with no errors
    # :okUartToo is for further checkings but accepts if the device is in
    # UART mode
    # Example:
    #   device.readStatus[:okForFirstRead] || raise "Status error!"
    #   device.readStatus[:ok] || raise "Status error!"
    #
    def readStatus
      def b(j,x)
	return (j & (2**x)).zero?^true
      end
      answer = receive(Command.new {|x| x.read_status})[0..1]
      l = (answer.getbyte(0) & 127)
      h = answer.getbyte(1)
      return {
        :status_low => l, :status_high => h, :status16 => h*256+l,
	:buttonPressed => b(l,6), :vppError => b(l,5), :vddError => b(l,4),
	:vppOn => b(l,3), :vppGndOn => b(l,2), :vddOn => b(l,1),
	:vddGndOn => b(l,0), :downloadBufferOverflow => b(h,7),
	:scriptBufferOverflow => b(h,6), :runScriptOnEmptyScript => b(h,5),
	:scriptAbortDownloadEmpty => b(h,4), :scriptAbortUploadFull => b(h,3),
	:icdTransferTimeoutBusError => b(h,2), :uartModeEnabled => b(h,1),
	:resetSinceLastStatusRead => b(h,0),
	:okForFirstRead => ((l & 0x30) | (h & 0xfe)).zero?,
	:ok => ((l & 0x30) | h).zero?,
	:okUartToo => ((l & 0x30) | (h & 0xfd)).zero?
      }
    end

    # Read voltages, returns hash with :vdd and :vpp values
    def readVoltages
      a = receive(Command.new {|x| x.read_voltages})[0..3].unpack("S*")
      return {:vdd => @vddWas = a[0]/65536.0*5, :vpp => a[1]/65536.0*13.7}
    end

    # Vdd voltage result of the last readVoltages call
    attr_reader :vddWas

    # Switch Vdd on if the device is not externally powered.
    # Optionally voltage level can be passed as an argument.
    def VddOn(arg = nil)
      if readVoltages[:vdd] < 1.5 then
	send(Command.new {|cmd|

	  cmd.setvdd(arg) if arg
	  cmd.execute_script
	  cmd.vdd_gnd_off
	  cmd.vdd_on
	})
      end
    end

    # Switch Vdd off.
    def VddOff
      send(Command.new {|cmd|

	cmd.execute_script
	cmd.vdd_off
	cmd.vdd_gnd_off
      })
    end

    # Restore initial state of the device like after reset.
    def restoreInitState
      send(Command.new {|cmd|

	cmd.exit_uart_mode
	cmd.clr_download_buffer
	cmd.clr_upload_buffer
	cmd.execute_script
	  cmd.vpp_off
	  cmd.mclr_gnd_on
	  cmd.set_aux(0)
	  cmd.vpp_pwm_off
	  cmd.set_icsp_pins
	  cmd.delay_long(54.6)
	  cmd.set_aux
	  cmd.busy_led_off
	  cmd.vdd_off
	  cmd.vdd_gnd_on
	  cmd.set_iscp_speed(0)
	cmd.set_vdd(3.3)
	cmd.set_vpp(8.5)
      })
    end

  end

end


