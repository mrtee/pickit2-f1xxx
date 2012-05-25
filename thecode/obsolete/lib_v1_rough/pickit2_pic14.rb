$LOAD_PATH << "."
require 'pickit2_programmer'
require 'pickit2_command'

module PICkit2

  class PIC14

    # The underlying Programmer device can be accessible here
    # including its methods (claim, send etc.)
    # Example:
    #   dev = PICkit2::Programmer.new
    #   pic = PICkit2::PIC14.new(dev)
    #   pic.tool.claim
    # Device handle can be replaced later
    #   pic = PICkit2::PIC14.new(old_dev)
    #   old_dev.release
    #   new_dev = PICkit2::Programmer.new
    #   new_dev.claim
    #   pic.tool = new_dev
    attr_accessor :tool

    # With no parameters
    #   pic = PICkit2::PIC14.new
    # will get a handle from the Programmer class.
    # Optionally a previously created device handle can be
    # specified:
    #   dev = PICkit2::Programmer.new
    #   pic = PICkit2::PIC14.new(dev)
    def initialize(d=Programmer.new)
      @tool = d
    end

    # Enter PIC microcontroller Program/Verify Mode.
    # Depending on the power source the method can automatically chose
    # between Vdd-First and Vpp-First entry modes. The Low Voltage
    # Programming (works with newer chips) also can be specified with a
    # parameter, like in this example:
    #   pic = PICkit2::PIC14.new
    #   pic.enterPVMode("LVP")
    # Without a parameter the method uses the High Voltage entry mode which
    # is compatible with old PIC microcontrollers too.
    # (Currently only the Vpp-First entry mode is working.)
    def enterPVMode(mode = "HVP")
      @modeWas = mode
      @tool.readVoltages
      case mode
      when "LVP"
	puts "LVP fixit!"
      when "HVP"
	if @tool.vddWas > 1.5 then
	  #vddfirst
	  puts "Vdd-First fixit!"
	else 
	  #vppfirst
	  @tool.send(Command.new {|cmd|

	    cmd.setvdd(3.3)
	    cmd.setvpp(8.5)
	    cmd.clr_upload_buffer
	    cmd.execute_script
	      cmd.set_icsp_speed(0)
	      cmd.set_icsp_pins(:pgd =>0, :pgc => 0)
	      cmd.vpp_pwm_on
	      cmd.delay_long(110)
	      cmd.vpp_on
	      cmd.vdd_gnd_off
	      cmd.vdd_on
	      cmd.delay_long(110)  #!!! very important
	  })
	end
      end
    end

    # Exit from Program/Verify Mode of a PIC microcontroller.
    # The method automatically handles all the powering and
    # programming entry mode cases.
    # (Currently only the Vpp-First entry mode is working.)
    def exitPVMode
      case @modeWas
      when "LVP"
	puts "LVP fixit!"
      when "HVP"
	if @tool.vddWas > 1.5 then
	  puts "Vdd-First fixit!"
	else
	  #Vpp-First
	  @tool.send(Command.new {|cmd|

	    cmd.execute_script
	      cmd.vdd_off
	      cmd.vdd_gnd_on
	      cmd.vpp_off
	      cmd.mclr_gnd_off
	      cmd.vpp_pwm_off
	  })
	end
      end
    end

    # Read PIC mcu Device ID (4-bit revision not included)
    # Parameter specifies the Program/Verify Mode entry/exit type:
    #   puts pic.readChipID("HVP")i
    #   puts pic.readChipID("LVP")
    # Without parameters no PV Mode entry/exit is performed by the
    # method:
    #   puts pic.readChipID
    # In this case the mcu should be already in PV Mode and
    # it will stay there after the Device ID reading process.
    def readChipID(mode = false)
      enterPVMode(mode) if mode
      answer = @tool.receive(Command.new {|cmd|

	cmd.clr_upload_buffer
	cmd.execute_script
	  cmd.write_bits_literal(:bits => 6, :literal => 0)
	  cmd.write_byte_literal(0)
	  cmd.write_byte_literal(0)
	  cmd.write_bits_literal(:bits => 6, :literal => 6)
	  cmd.loop(:commandsBack => 1, :iterations => 5)
	  cmd.write_bits_literal(:bits => 6, :literal => 4)
	  cmd.read_byte_buffer
	  cmd.read_byte_buffer
	cmd.upload_data
      })
      exitPVMode if mode
      return (answer[1..2].unpack("S")[0]/2&16383) >> 5
    end
    
    # Read 32 or 64 words from the program memory.
    # Word count can be specified in an argument.
    # Default is 64 if no argument specified.
    # Memory data will be returned in an Array of 14-bit values.
    def readProgramMemory(count=64,what=4)
      answer = @tool.receive(Command.new {|cmd|

        cmd.clr_upload_buffer
	cmd.execute_script
	  cmd.write_bits_literal(what)
	  cmd.read_byte_buffer
	  cmd.read_byte_buffer
	  cmd.write_bits_literal(6)
	  cmd.loop(:commandsBack => 4, :iterations => count - 1)
	cmd.upload_data_nolen
      })
      answer << @tool.receive(Command.new.upload_data_nolen) if count > 32
      return answer.unpack("S*").map {|x| x/2&16383}
    end
    
    # Read 32 or 64 words from the data memory.
    # Word count can be specified in an argument.
    # Default is 64 if no argument specified.
    # Memory data will be returned in an Array of bytes.
    def readDataMemory(count=64)
      readProgramMemory(count,5)
    end

  end


end


