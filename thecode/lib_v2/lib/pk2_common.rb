require 'pk2_usbcomm'

module PICkit2

  MIN_FW_VERSION_REQUIRED = "2.23.0"
  MAX_FW_VERSION_REQUIRED = "2.255.0"

  # Common calls of the Programmer
  # Example of a program that waits for the button pressed and
  # blinks the "Busy" led:
  #
  #   LOAD_PATH << "./lib"
  #   require 'commands'
  #   require 'usbcomm'
  #   require 'common'
  #   include PICkit2::Commands
  #   
  #   pk = PICkit2::Programmer.new
  #   pk.claim
  #   
  #   puts "Press the Button!"
  #   pk.waitForButtonPressed(20)
  #   
  #   pk.send(execute_script(busy_led_on))
  #   puts "Busy led ON."
  #   sleep 2
  #   
  #   pk.send(execute_script(busy_led_off))
  #   puts "Busy led OFF.\n"
  #   
  #   puts "Firmware version is: "+pk.checkFirmwareVersion[:version_text]
  #   
  #   pk.close
  #
  class Programmer

    require 'pk2_commands'
    include Commands
    
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
      answer = receive(firmware_version)[0..2]
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
      answer = receive(read_status)[0..1]
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
      a = receive(read_voltages)[0..3].unpack("S*")
      return {:vdd => @vddWas = a[0]/65536.0*5, :vpp => a[1]/65536.0*13.7}
    end

    # Vdd voltage result of the last readVoltages call
    attr_reader :vddWas


    # Find out how is the prototype board powered. Possible answers:
    # "pickit" "self" "none"
    def getPowerMode
      if readStatus[:vddOn] == true
	"pickit"
      elsif readVoltages[:vdd] > 1
	"self"
      else
	"none"
      end
    end

    # Intelligently power up the device. If it is self powered, leave it alone.
    # Power voltage is 3.3 volts if otherwise not specified:
    #   powerOn
    # 3.3V
    #   powerOn(5)
    # 5V
    def powerOn(voltage=3.3)
      send(
	setvdd(voltage),
	(execute_script(vdd_gnd_off,vdd_on) if getPowerMode == "none")
      )
    end

    # Power off the prototype. Can still be self-powered afterwards.
    # Power voltage can be read via readVoltages method
    def powerOff
      send(execute_script(vdd_off))
    end

    # Wait (n) seconds for the button. If the it has been pressed
    # within that interval, the method returns true. In case of
    # timeout returns false.
    # (Checks the button every 1/2 seconds.)
    def waitForButtonPressed(seconds)
      readStatus
      while seconds > 0 and not readStatus[:buttonPressed]
	sleep 0.5
	seconds -= 0.5
      end
      seconds > 0
    end

    # Restore initial state of the device like after reset.
    def restoreInitState
      send(
	exit_uart_mode,
	clr_download_buffer,
	clr_upload_buffer,
	execute_script(
	  vpp_off,
	  mclr_gnd_off,
	  set_aux(0),
	  vpp_pwm_off,
	  set_icsp_pins,
	  delay_long(54.6),
	  set_aux,
	  busy_led_off,
	  vdd_off,
	  vdd_gnd_off,
	  set_icsp_speed(0)),
	setvdd(3.3),
	setvpp(8.5))
    end

  end

end


