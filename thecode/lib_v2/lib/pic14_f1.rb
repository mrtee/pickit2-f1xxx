require 'pk2_common'

module PICkit2

  # Programming PIC1xF1xxx series
  class Programmer

    require 'pic14_f1_device_datas'
    require 'pk2_commands'
    include Commands
    
    # Enter PIC microcontroller Program/Verify Mode.
    # Depending on the power source the method can automatically chose
    # between Vdd-First and Vpp-First entry modes. The Low Voltage
    # Programming (works with newer chips) also can be specified with a
    # parameter, like in this example:
    #   pic = PICkit2::PIC14.new
    #   pic.enterPVMode("HVP")
    # Without a parameter the method uses the Low Voltage entry mode which
    # is compatible with old PIC microcontrollers too.
    # (Currently the Vdd-First entry mode works only in LVP mode.)
    def enterPVMode(mode = "LVP")
      send(execute_script(busy_led_on))
      @modeWas = mode
      readVoltages
      case mode
      when "LVP"
	v = @vddWas < 1.5 # slef-powered?
	send(
	  execute_script(
	    vpp_off,
	    vpp_pwm_off,
	    set_icsp_speed(0),
	    set_icsp_pins(:pgd =>0, :pgc => 0),
	    mclr_gnd_on
	  ),
	  v && setvdd(3),
	  v && execute_script(
	    vdd_gnd_off,
	    vdd_on,
	    delay_long(50) # capacitor charging delay
	    ),
	  execute_script(
	    delay_short(250),
	    write_byte_literal("P".ord),
	    write_byte_literal("H".ord),
	    write_byte_literal("C".ord),
	    write_byte_literal("M".ord),
	    write_bits_literal(:bits => 1, :literal => 0)
	  )
	)
      
      when "HVP"
	if @vddWas > 1.5 then
	  #vddfirst
	  puts "ENTER Vdd-First"
	  send(
	    setvpp(8.5),
	    clr_upload_buffer,
	    execute_script(
	      vpp_off,
	      vpp_pwm_on,
	      mclr_gnd_on,
	      set_icsp_speed(0),
	      set_icsp_pins(:pgd =>0, :pgc => 0),
	      delay_long(110),
	      vpp_on,
	      mclr_gnd_off,
	      delay_long(110)  #!!! very important
	    )
	  )
	else 
	  #vppfirst
	  puts "ENTER Vpp-First"
	  send(
	    setvdd(3),
	    setvpp(8.5),
	    clr_upload_buffer,
	    execute_script(
	      set_icsp_speed(0),
	      set_icsp_pins(:pgd =>0, :pgc => 0),
	      vpp_pwm_on,
	      delay_long(110),
	      vpp_on,
	      vdd_gnd_off,
	      vdd_on,
	      delay_long(110)  #!!! very important
	    )
	  )
	end
      end
    end

    # Exit from Program/Verify Mode of a PIC microcontroller.
    # The method automatically handles all the powering and
    # programming entry mode cases.
    # (Currently the Vdd-First entry mode works only in LVP mode.)
    def exitPVMode
      case @modeWas
      when "LVP"
	v = @vddWas < 1.5
	send(
	  execute_script(
	    v && vdd_off,
	    v && vdd_gnd_on,
	    v && delay_long(50), # capacitor discharge time
	    v && vdd_gnd_off,
	    mclr_gnd_off
	  )
	)

      when "HVP"
	if @vddWas > 1.5 then
	  #Vdd-First
	  puts "EXIT Vdd remains"
	  send(
	    execute_script(
	      mclr_gnd_on,
	      vpp_off,
	      vpp_pwm_off,
	      set_icsp_pins,
	      mclr_gnd_off
	    )
	  )

	else
	  #Vpp-First
	  puts "EXIT Vpp-last"
	  send(

	    execute_script(
	      vdd_off,
	      vdd_gnd_on,
	      delay_long(50), # capacitor discharge time
	      vpp_off,
	      set_icsp_pins,
	      mclr_gnd_off,
	      vpp_pwm_off
	    )
	  )
	end
      end
      send(execute_script(busy_led_off))
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
      answer = receive(
	clr_upload_buffer,
	execute_script(
	  write_bits_literal(:bits => 6, :literal => 0),
	  write_byte_literal(0),
	  write_byte_literal(0),
	  write_bits_literal(:bits => 6, :literal => 6),
	  loop(:commandsBack => 1, :iterations => 5),
	  write_bits_literal(:bits => 6, :literal => 4),
	  read_byte_buffer,
	  read_byte_buffer
	),
	upload_data
      )
      exitPVMode if mode
      id = (answer[1..2].unpack("S")[0]/2&16383) >> 5
      return @deviceData = PIC14F1DeviceData[PIC14F1DeviceData.index {|i| i[:deviceID] == id}]
    end
    
    # Read 32 or 64 words from the program memory.
    # Word count can be specified in an argument.
    # Default is 64 if no argument specified.
    # Memory data will be returned in an Array of 14-bit values.
    def readProgramMemory(count=64,what=4)
      answer = receive(
        clr_upload_buffer,
	execute_script(
	  write_bits_literal(:bits => 6, :literal => 0x16), #reset address
	  write_bits_literal(what),
	  read_byte_buffer,
	  read_byte_buffer,
	  write_bits_literal(6),
	  loop(:commandsBack => 4, :iterations => count - 1)
	),
	upload_data_nolen
      )
      answer << receive(upload_data_nolen) if count > 32
      return answer.unpack("S*").map {|x| x/2&16383}
    end
    
    # Read 32 or 64 words from the data memory.
    # Word count can be specified in an argument.
    # Default is 64 if no argument specified.
    # Memory data will be returned in an Array of bytes.
    def readDataMemory(count=64)
      answer = receive(
        clr_upload_buffer,
	execute_script(
	  write_bits_literal(0x16),
	  write_bits_literal(5),
	  read_byte_buffer,
	  read_byte_buffer,
	  write_bits_literal(6),
	  loop(:commandsBack => 4, :iterations => count - 1)
	),
	upload_data_nolen
      )
      answer << receive(upload_data_nolen) if count > 32
      return answer.unpack("S*").map {|x| x/2&16383}
    end
    
    # !!!! 
    def readConfigMemory(count=64)
      answer = receive(
        clr_upload_buffer,
	execute_script(
	  write_bits_literal(0),
	  write_byte_literal(0),
	  write_byte_literal(0),
	  write_bits_literal(4),
	  read_byte_buffer,
	  read_byte_buffer,
	  write_bits_literal(6),
	  loop(:commandsBack => 4, :iterations => count - 1)
	),
	upload_data_nolen
      )
      answer << receive(upload_data_nolen) if count > 32
      return answer.unpack("S*").map {|x| x/2&16383}
    end

    # Bulk-Erase the Program Memory
    #   pic.bulkEraseProgramMemory("LVP")
    #   pic.bulkEraseProgramMemory("HVP")
    # Without parameters no PV Mode entry/exit is performed by the
    # method:
    #   pic.bulkEraseProgramMemory
    # In this case the mcu should be already in PV Mode and
    # it will stay there after the process.
    def bulkEraseProgramMemory(mode = false, c = 9)
      enterPVMode(mode) if mode
      send(
	execute_script(
	  #write_bits_literal(:bits => 6, :literal => 0),
	  #write_byte_literal(0),
	  #write_byte_literal(0),
	  write_bits_literal(:bits => 6, :literal => c),
	  delay_long(5)
	),
      )
      exitPVMode if mode
    end
    
    # Bulk-Erase the Data Memory
    #   pic.bulkEraseDataMemory("LVP")
    #   pic.bulkEraseDataMemory("HVP")
    # Without parameters no PV Mode entry/exit is performed by the
    # method:
    #   pic.bulkEraseDataMemory
    # In this case the mcu should be already in PV Mode and
    # it will stay there after the process.
    def bulkEraseDataMemory(mode = false)
      bulkEraseProgramMemory(mode, 11)
    end
  
    # Bulk-Erase Program and Data Memory
    #   pic.bulkErase("LVP")
    #   pic.bulkErase("HVP")
    # Without parameters no PV Mode entry/exit is performed by the
    # method:
    #   pic.bulkErase
    # In this case the mcu should be already in PV Mode and
    # it will stay there after the process.
    def bulkErase(mode = false)
      enterPVMode(mode) if mode
      bulkEraseProgramMemory
      bulkEraseDataMemory
      exitPVMode if mode
    end
  
    # program!
    def writeData(d)
      d += [0]*(32-d.length)
      send(
	clr_download_buffer,
        download_data(d),
	execute_script(
	  write_bits_literal(0x16), # reset address
	  write_bits_literal(:bits => 6, :literal => 2),
	  write_byte_buffer,
	  write_byte_buffer,
	  write_bits_literal(:bits => 6, :literal => 6),
	  write_bits_literal(:bits => 6, :literal => 2),
	  write_byte_buffer,
	  write_byte_buffer,
	  loop(:commandsBack => 4, :iterations => 14 ),
	  write_bits_literal(:bits => 6, :literal => 8),
	  delay_long(5),
	  write_bits_literal(:bits => 6, :literal => 6)
	)
      )
    end
    
    # data area!!!!!
    def writeDTM
      send(
	execute_script(
          write_bits_literal(0xb), #erase data
	  delay_long(5),
	  write_bits_literal(3),
	  write_byte_literal(4),
	  write_byte_literal(0),
	  write_bits_literal(0x8),
	  delay_long(5)
	)
      )
    end

    
    # config area!
    def writeUID
      send(
	execute_script(
	write_bits_literal(0),
	write_byte_literal(0),
	write_byte_literal(0),
	write_bits_literal(0x9),
	delay_long(5),
	write_bits_literal(6),
	write_bits_literal(6),
	write_bits_literal(2),
	write_byte_literal(0x6),
	write_byte_literal(0x2),
	write_bits_literal(8),
	delay_long(5),
	#write_bits_literal(6),
	#write_bits_literal(2),
	#write_byte_literal(0x4),
	#write_byte_literal(0x8),
	#write_bits_literal(8),
	#delay_long(5)
	)
      )
    end

    def readHexFile(filename)
      @dataBuffer = []
      addr_hi = 0
      File.open(filename,'r').each do |line|
	linescan = line.scan(/^:(\w{2})(\w{4})(\w{2})(\w*)(\w{2})/).flatten
	case linescan[2]
	when "04"
	  addr_hi = linescan[3].to_i(16)
	when "00"
	  addr_lo = linescan[1].to_i(16)
	  linescan[3].scan(/\w{4}/) do |dataword|
	    @dataBuffer << [(addr_hi << 16) + addr_lo, ((dataword.to_i(16) & 0xff) << 8) + (dataword.to_i(16) >> 8)]
	    addr_lo += 2
	  end
	end
      end
      @dataBuffer.sort!
      puts @dataBuffer.inspect
    end
 
    def writeConfigMemory
    end

    def writeProgramMemory
    end

    def writeDataMemory
    end

    def setAddress
    end

    def adjustProgramCounter(address)
      # roughly
      while address-@programCounter > 511 do
	puts "haho1"
	send(
	  execute_script(
	    write_bits_literal(:bits => 6, :literal => 6),
	    loop(:commandsBack => 1, :iterations => 255 )
	  )
	)
	@programCounter += 512
      end
      
      # accurately
      if address-@programCounter == 2 then
	puts "haho2"
	send(
	  execute_script(
	    write_bits_literal(:bits => 6, :literal => 6)
	  )
	)
	@programCounter += 2
      end
      if @programCounter < address then
	puts "haho3"
	send(
	  execute_script(
	    write_bits_literal(:bits => 6, :literal => 6),
	    loop(:commandsBack => 1, :iterations => (address-@programCounter-2)/2)
	  )
	)
	@programCounter = address
      end
    end


    def burn
      readChipID
      
      # config memory
      # detect if config area programming is needed or not
      if @dataBuffer.index {|x| @deviceData[:configurationMemory] === x[0]} then
	
	# erase config and program memory
	send(
	  execute_script(
	    write_bits_literal(0),
	    write_byte_literal(0),
	    write_byte_literal(0),
	    write_bits_literal(9),
	    delay_long(5)
	  )
	)

	# adjust program counter to start position
	@programCounter = @deviceData[:configurationMemory].begin

	#select each address/data pair and write them to the config memory
        @dataBuffer.select {|x| @deviceData[:configurationMemory] === x[0]}.each do |addressDataPair|
	  
	  adjustProgramCounter(addressDataPair[0])

	  # write to memory
	  send(
	    execute_script(
	      write_bits_literal(2),
	      write_byte_literal((addressDataPair[1] << 1) & 255),
              write_byte_literal((addressDataPair[1] << 1) >> 8),
	      write_bits_literal(8),
	      delay_long(5)
	    )
	  )

	end
      end

      # program memory
      # detect if program area programming is needed or not
      if @dataBuffer.index {|x| @deviceData[:programMemory] === x[0]} then
	
	# reset address and erase program memory
	send(
	  execute_script(
	    write_bits_literal(0x16),
	    # if program memory was not erased previously then do it
	    @dataBuffer.index {|x| @deviceData[:configurationMemory] === x[0]}.nil? && write_bits_literal(9),
	    delay_long(5)
	  )
	)

	# adjust program counter to start position
	@programCounter = @deviceData[:programMemory].begin

	      
	@deviceData[:programMemory].step(@deviceData[:numberOfLatches]*2).each do |bunchStart|
	  #puts "bunchStart: "+bunchStart.to_s
	  
	  # create a data bunch for parallel latching
	  # only if a block containd datas associated with it
	  if @dataBuffer.index {|x| (bunchStart..bunchStart+@deviceData[:numberOfLatches]*2-1) === x[0]} then
	    bunch = []
	    (bunchStart..bunchStart+@deviceData[:numberOfLatches]*2-1).step(2) do |bunchElementAddress|
	      if dataIndex = @dataBuffer.index {|i| bunchElementAddress == i[0]} then
		# translate a 14 bit word to the flash load format
		bunch << ((@dataBuffer[dataIndex][1] << 1) & 255) << ((@dataBuffer[dataIndex][1] << 1) >> 8)
	      else
		# emptiness is filled with 0x3fff's
		bunch << 254 << 127
	      end
	    end
	    
	    # position the program counter
	    adjustProgramCounter(bunchStart)
	    
	    #send the data bunch
	    send(
	      clr_download_buffer
	    )

	    # separate the send commands to avoid buffer overflow

	    until bunch == []
	    
	      send(
	        download_data(bunch.slice!(0,62))
		# separate per 62 bytes of each data transfer
	      )
	    
	    end

	    send(
	      execute_script(
		write_bits_literal(:bits => 6, :literal => 2),
		write_byte_buffer,
		write_byte_buffer,
		write_bits_literal(:bits => 6, :literal => 6),
		write_bits_literal(:bits => 6, :literal => 2),
		write_byte_buffer,
		write_byte_buffer,
		loop(:commandsBack => 4, :iterations => @deviceData[:numberOfLatches]-2),
		write_bits_literal(:bits => 6, :literal => 8),
		delay_long(5),
		write_bits_literal(:bits => 6, :literal => 6)
	      )
	    )
	    # adjust program counter to the next address range
	    
	    #writeData([1,2,3,4,5,6,7,8,9,10,11,12])
	    @programCounter += @deviceData[:numberOfLatches]*2
	  end
	
	end
      end
	
	
      # data memory
      # detect if particular chip has data memory
      if @deviceData[:dataMemory] then
        # detect if data memory is to be programmed at all
	if @dataBuffer.index {|x| @deviceData[:dataMemory] === x[0]} then
	  
	  # erase data memory
	  send(
	    execute_script(
	      write_bits_literal(0xb),
	      delay_long(5)
	    )
	  )

	  # adjust program counter to start position
	  @programCounter = @deviceData[:dataMemory].begin

	  #select each address/data pair and write them to the data memory
	  @dataBuffer.select {|x| @deviceData[:dataMemory] === x[0]}.each do |addressDataPair|
	    
	    adjustProgramCounter(addressDataPair[0])

	    # write to memory
	    send(
	      execute_script(
		write_bits_literal(3),
		write_byte_literal((addressDataPair[1] << 1) & 255),
		write_byte_literal((addressDataPair[1] << 1) >> 8),
		write_bits_literal(8),
		delay_long(5)
	      )
	    )
	  end
	end
      end



      
    # end of method
    end
    #end of class and module
  end
end

