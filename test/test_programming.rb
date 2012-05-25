$LOAD_PATH << "./lib"
require 'pk2_commands'
#require 'usbcomm'
#require 'common'
require 'pic14_f1'

include PICkit2::Commands

pk = PICkit2::Programmer.new

pk.claim

=begin

pk.enterPVMode("HVP")
pk.writeUID
pk.exitPVMode

pk.enterPVMode("HVP")
pk.writeData([2,4,6,8,10,12])
pk.exitPVMode

pk.enterPVMode("HVP")
pk.writeDTM
pk.exitPVMode


pk.enterPVMode("HVP")

puts pk.readConfigMemory.map {|x| "%04X" % x}.inspect
puts pk.readProgramMemory.map {|x| "%04X" % x}.inspect
puts pk.readDataMemory.map {|x| "%04X" % x}.inspect

pk.exitPVMode

=end

pk.readHexFile("helloworld.hex")

pk.enterPVMode("HVP")

pk.burn

pk.exitPVMode


=begin
pk.enterPVMode("LVP")

puts pk.readConfigMemory.map {|x| "%04X" % x}.inspect
puts pk.readProgramMemory.map {|x| "%04X" % x}.inspect
puts pk.readDataMemory.map {|x| "%04X" % x}.inspect

pk.exitPVMode
=end

puts "press enter to power on"
gets

pk.powerOn

puts "press enter to power off"
gets
pk.powerOff

pk.close

