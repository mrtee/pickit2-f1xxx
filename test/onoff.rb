$LOAD_PATH << "./lib"
require 'pk2_commands'
require 'pic14_f1'

include PICkit2::Commands

pk = PICkit2::Programmer.new

pk.claim

pk.powerOn(3)

pk.waitForButtonPressed(600)

pk.powerOff

pk.close

