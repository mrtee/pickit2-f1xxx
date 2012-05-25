$LOAD_PATH << "."
require 'pickit2_pic14'
pic = PICkit2::PIC14.new
pic.tool.claim

puts pic.tool.readStatus[:okForFirstRead]

#pic.enterPVMode



puts pic.readChipID("HVP").to_s(2)

#pic.exitPVMode
pic.enterPVMode

puts


c=PICkit2::Command.new

c.clr_upload_buffer
c.execute_script

#c.write_bits_literal(0x16)


c.write_bits_literal(4)
c.read_byte_buffer
c.read_byte_buffer
c.write_bits_literal(6)
c.loop(:commandsBack => 4, :iterations => 31)


c.upload_data_nolen

pic.tool.send(c)


d=pic.tool.receive

puts d.unpack("C*").map {|x| x.to_s(16)}.inspect

puts d.unpack("S*").map {|x| "%04X" % (x/2&16383)}.inspect


pic.exitPVMode

pic.tool.close


