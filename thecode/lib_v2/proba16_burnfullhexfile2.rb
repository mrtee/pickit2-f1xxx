$LOAD_PATH << "./lib"
require 'pk2_commands'
#require 'usbcomm'
#require 'common'
require 'pic14_f1'

include PICkit2::Commands

pk = PICkit2::Programmer.new

pk.claim

pk.enterPVMode("LVP")
pk.writeUID
pk.exitPVMode

pk.enterPVMode("LVP")
pk.writeData([2,4,6,8,10,12])
pk.exitPVMode

pk.enterPVMode("LVP")
pk.writeDTM
pk.exitPVMode


pk.enterPVMode("LVP")

puts pk.readConfigMemory.map {|x| "%04X" % x}.inspect
puts pk.readProgramMemory.map {|x| "%04X" % x}.inspect
puts pk.readDataMemory.map {|x| "%04X" % x}.inspect

pk.exitPVMode

pk.readHexFile("../hexek/proba.X.production.hex")
#pk.readHexFile("../hexek/123_f1822.hex")

pk.enterPVMode("LVP")

pk.burn

puts
puts 

pk.exitPVMode


pk.enterPVMode("LVP")

puts pk.readConfigMemory.map {|x| "%04X" % x}.inspect
puts pk.readProgramMemory.map {|x| "%04X" % x}.inspect
puts pk.readDataMemory.map {|x| "%04X" % x}.inspect

pk.exitPVMode



pk.close

