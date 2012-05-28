$LOAD_PATH << "./lib"
require 'pk2_commands'
#require 'usbcomm'
#require 'common'
require 'pic14_f1'

include PICkit2::Commands

pk = PICkit2::Programmer.new

pk.claim

pk.enterPVMode("HVP")
pk.writeData([2,4,6,8,10,12])
pk.exitPVMode

pk.enterPVMode("LVP")
puts pk.readProgramMemory.map {|x| "%04X" % x}.inspect
#pk.exitPVMode

sleep 0.2

#pk.enterPVMode("LVP")

sleep 0.2

pk.send(
  execute_script(
    write_bits_literal(2),
    write_byte_literal(0),
    write_byte_literal(0),
    write_bits_literal(9),
    delay_long(10)
  )
)

pk.exitPVMode

sleep 0.2

pk.enterPVMode("LVP")
puts pk.readProgramMemory.map {|x| "%04X" % x}.inspect
pk.exitPVMode


pk.close

