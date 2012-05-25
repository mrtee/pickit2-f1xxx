$LOAD_PATH << "."
require 'pickit2_pic14'
pic = PICkit2::PIC14.new
pic.tool.claim

puts pic.tool.readStatus[:okForFirstRead]

puts pic.readChipID("HVP").to_s(2)

pic.enterPVMode

puts pic.readProgramMemory.map {|x| "%04X" % x}.inspect

pic.exitPVMode

pic.enterPVMode

puts pic.readDataMemory.map {|x| "%04X" % x}.inspect

pic.exitPVMode

pic.tool.close


