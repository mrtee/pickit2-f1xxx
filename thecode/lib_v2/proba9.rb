$LOAD_PATH << "./lib"
require 'pk2_commands'
#require 'usbcomm'
#require 'common'
require 'pic14_f1'

include PICkit2::Commands

pk = PICkit2::Programmer.new

pk.claim

pk.enterPVMode("HVP")
#puts pk.readChipID.to_s(2)
pk.bulkEraseProgramMemory
z=[]
#=begin
x = 0x1234
x1 = x << 1
z = [ x1 & 255, x1 >> 8 ]
#=end
pk.writeData(z+[1,1,2,2,3,3,4,4,0,3,0,3,0,3,0,2])

#puts pk.readStatus[:okForFirstRead]


#sleep 1


#puts pk.readProgramMemory.map {|x| "%04X" % x}.inspect

pk.exitPVMode

#sleep 1

#puts pk.readStatus.inspect

#pk.enterPVMode("LVP")

#puts pk.readDataMemory.map {|x| "%04X" % x}.inspect

#pk.exitPVMode

#puts pk.readStatus.inspect

pk.close

