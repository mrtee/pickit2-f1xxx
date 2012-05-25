$LOAD_PATH << "./lib"
require 'pk2_commands'
#require 'usbcomm'
#require 'common'
require 'pic14_f1'

include PICkit2::Commands

pk = PICkit2::Programmer.new

pk.claim
#puts pk.readStatus.inspect

pk.enterPVMode("HVP")
puts pk.readChipID.inspect

#puts pk.readProgramMemory.map {|x| "%04X" % x}.inspect
pk.exitPVMode

#puts "erasing program memory"

pk.enterPVMode("HVP")
#pk.bulkEraseProgramMemory
puts pk.readConfigMemory.map {|x| "%04X" % x}.inspect
pk.exitPVMode

#pk.readHexFile("../hexek/proba.X.production.hex")

#pk.enterPVMode("HVP")

#puts "burning"

#pk.burn

#pk.exitPVMode

#pk.enterPVMode("HVP")

#puts pk.readProgramMemory.map {|x| "%04X" % x}.inspect
#pk.exitPVMode

pk.close

