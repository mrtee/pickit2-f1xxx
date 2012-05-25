$LOAD_PATH << "./lib"
require 'pk2_commands'
#require 'usbcomm'
#require 'common'
require 'pic14_f1'

include PICkit2::Commands

pk = PICkit2::Programmer.new

pk.claim

puts pk.readStatus[:okForFirstRead]

puts pk.readChipID("HVP").to_s(2)

pk.enterPVMode

puts pk.readProgramMemory.map {|x| "%04X" % x}.inspect

pk.exitPVMode

pk.enterPVMode

puts pk.readDataMemory.map {|x| "%04X" % x}.inspect

pk.exitPVMode

pk.close

