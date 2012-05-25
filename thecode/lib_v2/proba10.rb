$LOAD_PATH << "./lib"
require 'pk2_commands'
#require 'usbcomm'
#require 'common'
require 'pic14_f1'

include PICkit2::Commands

pk = PICkit2::Programmer.new


pk.readHexFile("../hexek/proba.X.production.hex")


=begin
pk.claim

pk.enterPVMode("HVP")
pk.bulkEraseProgramMemory
z=[]
x = 0x1234
x1 = x << 1
z = [ x1 & 255, x1 >> 8 ]
pk.writeData(z+[1,1,2,2,3,3,4,4,0,3,0,3,0,3,0,2])


pk.close
=end
