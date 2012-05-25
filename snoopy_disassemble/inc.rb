load 'scriptcommands.rb'
load 'fwcommands.rb'

def stringToHex(str)
  return str.unpack("H*")[0].gsub(/(..)/, '\1 ').rstrip
end

def hexToString(hex)
  return hex.scan(/\S\S/).pack("H2"*hex.scan(/\S\S/).length)
end

def disAsmCmd(args) # :block, :position, :isScript
  table = FWCOMMANDS
  table = SCRIPTCOMMANDS if args[:isScript] 
  command = args[:block].getbyte(args[:position])
  id = table.index{|x|x[:id]==command}
  name = table[id][:name]
  isLast = table[id][:isLast]
  switchToScript = table[id][:switchToScript]
  switchToFirmware = table[id][:switchToFirmware]
  parameters = ""
  newPosition = args[:position]+1
  newPosition += table[id][:dataLength] if table[id][:dataLength]
  if table[id][:dataLength] # complex commands
    data = args[:block][args[:position]+1..args[:position]+1+table[id][:dataLength]].unpack("C*")
    parameters = case name

                 # firmware commands

                 when "SETVDD" then "Vdd=#{((((data[1]*256+data[0])/64.0)-10.5)/32).round(1)}V, Vfault=#{(data[2]/255.0*5).round(1)}V"
		 when "SETVPP" then "Vpp=#{(data[1]/18.61).round(1)}V, Vfault=#{(data[2]/18.61).round(1)}V"
                 when "DOWNLOAD_SCRIPT" then "##{data[0]}, Length=#{data[1]}"
                 when "RUN_SCRIPT" then "##{data[0]}, #{data[1]} times (0 is 256)"
		 when "EXECUTE_SCRIPT" then "Length=#{data[0]}"
                 when "DOWNLOAD_DATA" then "Length=#{data[0]}"
                 when "SET_VOLTAGE_CALS" then "adc_calfactor=#{(data[1]+data[0]/256).round(10)}, vdd_offset=#{[data[2]].chr.unpack("c")[0]}, vdd_calfactor=#{(((1/64+[data[2]].chr.unpack("c")[0])*data[3])/2).round(10)}"
                 when "WR_INTERNAL_EE" then "StartAddress=#{data[0].to_s(16)}h, Length=#{data[1]}"
                 when "RD_INTERNAL_EE" then "StartAddress=#{data[0].to_s(16)}h, Length=#{data[1]}"
                 when "ENTER_UART_MODE" then "Baud=#{(65536-((1/(data[0]+data[1]*256)-3e-6)/1.67e-7)).round}"
                 when "ENTER_LEARN_MODE" then "#{data[3]*128+128}K EEPROM"
                 when "ENABLE_PK2GO_MODE" then "#{data[3]*128+128}K EEPROM"
                 when "LOGIC_ANALYZER_GO" then "(see docs)"
                 when "COPY_RAM_UPLOAD" then "StartAddress=#{((data[0]+data[1]*256)&4095).to_s(16)}h"
                 when "READ_OSCCAL" then "Value=#{(data[0]+data[1]*256).to_s(16)}h"
                 when "WRITE_OSCCAL" then "Value=#{data[0]+data[1]*256}"
                 when "START_CHECKSUM" then "Format=#{data[1]}"
                 when "VERIFY_CHECKSUM" then "Checksum=#{(data[0]+data[1]*256).to_s(16)}h"
                 when "CHECK_DEVICE_ID" then "Mask=#{(data[0]+data[1]*256).to_s(16)}h, Value=#{(data[2]+data[3]*256).to_s(16)}h"
                 when "CHANGE_CHKSM_FRMT" then "Format=#{data[0]}"

                 # script commands

                 when "SET_ICSP_PINS" then "DATA=#{"input"*((data[0]&2)/2)+((data[0]&8)/8).to_s*(((data[0]&2)^2)/2)}, CLOCK=#{"input"*(data[0]&1)+((data[0]&4)/4).to_s*((data[0]&1)^1)}"
		 when "WRITE_BYTE_LITERAL" then "Byte=#{data[0].to_s(16)}h"
                 when "WRITE_BITS_LITERAL" then "Bits=#{data[0]}, literal=#{data[1].to_s(16)}h"
                 when "WRITE_BITS_BUFFER" then "Bits=#{data[0]}"
                 when "READ_BITS_BUFFER" then "Bits=#{data[0]}"
                 when "READ_BITS" then "Bits=#{data[0]}"
                 when "SET_ICSP_SPEED" then "Rate=#{data[0]} us"
                 when "LOOP" then "Bytes_back=#{data[0]}, iterations=#{data[1]} (0 = 256)"
                 when "DELAY_LONG" then "Delay=#{5.46*data[0]} ms (0 = #{5.46*256} ms)"
                 when "DELAY_SHORT" then "Delay=#{21.3*data[0]} us (0 = #{21.3*256} us)"
                 when "IF_EQ_GOTO" then "Byte for comparison=#{data[0].to_s(16)}h, signed offset=#{data[0].chr.unpack("c")[0]}"
                 when "IF_GT_GOTO" then "Byte for comparison=#{data[0].to_s(16)}h, signed offset=#{data[0].chr.unpack("c")[0]}"
                 when "GOTO_INDEX" then "Signed offset=#{data[0].chr.unpack("c")[0]}"


                 when "PEEK_SFR" then "SFR Low=#{data[0].to_s(16)}h"
                 when "POKE_SFR" then "SFR Low=#{data[0].to_s(16)}h, byte to write=#{data[1].to_s(16)}h"
                 when "ICDSLAVE_TX_LIT" then "Byte to be transmitted=#{data[0].to_s(16)}h"
                 when "LOOPBUFFER" then "Bytes_back=#{data[0]}"
                 when "COREINST18" then "LSb=#{data[0].to_s(16)}h, MSb=#{data[1].to_s(16)}h"
                 when "COREINST24" then "Low=#{data[0].to_s(16)}h, Mid=#{data[1].to_s(16)}, Upper=#{data[2].to_s(16)}h"
                 when "RD2_BITS_BUFFER" then "Bits=#{data[0]}"
                 when "WRITE_BUFWORD_W" then "PIC24 W register=#{data[0]}"
                 when "WRITE_BUFBYTE_W" then "PIC24 W register=#{data[0]}"
                 when "CONST_WRITE_DL" then "Byte constant=#{data[0]}"
                 when "WRITE_BITS_LIT_HLD" then "Bits=#{data[0]}, Literal=#{data[1]}"
                 when "WRITE_BITS_BUF_HLD" then "Bits=#{data[0]}"
                 when "SET_AUX" then "AUX logic level=#{(data[0]&2)/2}, AUX direction=#{(data[0]&1)} (1 = input, 0 = output)"
                 when "I2C_WR_BYTE_LIT" then "Byte to be sent=#{data[0].to_s(16)}h"
                 when "SPI_WR_BYTE_LIT" then "Byte to be sent=#{data[0].to_s(16)}h"
                 when "SPI_RDWR_BYTE_LIT" then "Byte to be sent=#{data[0].to_s(16)}h"
                 when "ICDSLAVE_TX_LIT_BL" then "Byte to be transmitted=#{data[0].to_s(16)}h"
                 when "UNIO_TX" then "Device address=#{data[0].to_s(16)}h, Bytes to transmit=#{data[1].to_s(16)}h"
                 when "UNIO_TX_RX" then "Device address=#{data[0].to_s(16)}h, Bytes to transmit=#{data[1].to_s(16)}h, Bytes to transmit=#{data[2].to_s(16)}h"
                 when "JT2_SETMODE" then "Number of bits=#{data[0]}, TMS value=#{data[1].to_s(16)}h"
                 when "JT2_SENDCMD" then "Command value=#{data[0].to_s(16)}h"
                 when "JT2_XFERDATA8_LIT" then "Byte value to transfer=#{data[0].to_s(16)}h"
                 when "JT2_XFERDATA32_LIT" then "Value=#{((((data[3]*256)+data[2]*256)+data[1])*256+data[0]).to_s(16)}h"
                 when "JT2_XFRFASTDAT_LIT" then "Value=#{((((data[3]*256)+data[2]*256)+data[1])*256+data[0]).to_s(16)}h"

    end

  end

  hexRepresentation = stringToHex(args[:block][args[:position]..newPosition-1])
  return {:name => name, :newPosition => newPosition, :switchToScript => switchToScript, :isLast => isLast, \
    :switchToFirmware => switchToFirmware, :parameters => parameters, :hexRepresentation => hexRepresentation.rstrip, \
    :dumpData => table[id][:dumpData]}
end

def disAsmBlock(args) # :block
  position = 0
  script = false
  scriptEndPos = 255
  begin
    line = disAsmCmd(:block => args[:block], :position => position, :isScript => script)
    position = line[:newPosition]
    case script
    when true then printf"%-25s%s%-22s%s\n", line[:hexRepresentation], "  ", line[:name], line[:parameters]
    when false then printf"%-25s%-24s%s\n", line[:hexRepresentation], line[:name], line[:parameters]
    end

    if line[:dumpData]
      puts(stringToHex(args[:block][position..position+args[:block].getbyte(position-1)-1]))
      position += args[:block].getbyte(position-1)
    end

    if line[:switchToScript]
      script = true
      scriptEndPos = args[:block].getbyte(position-1)+position
    end

    if line[:switchToFirmware]
      script = false
      position = scriptEndPos
    end

    if position == scriptEndPos && script
      script = false
      scriptEndPos = 255
    end

  end until line[:isLast] || position > 63

end   

