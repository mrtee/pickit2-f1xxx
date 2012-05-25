$LOAD_PATH << "./lib"
require 'pk2_commands'
#require 'usbcomm'
#require 'common'
require 'pic14_f1'

include PICkit2::Commands

pk = PICkit2::Programmer.new

pk.claim

puts pk.readStatus.inspect

puts pk.checkFirmwareVersion.inspect

pk.send(execute_script(busy_led_on))

sleep 1

pk.restoreInitState

pk.close
