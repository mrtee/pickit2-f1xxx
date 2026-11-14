#!/usr/bin/env ruby
$LOAD_PATH << "./lib"
require 'pk2_commands'
require 'pic14_f1'

include PICkit2::Commands

filename = ARGV.shift || "blink.hex"

pk = PICkit2::Programmer.new
pk.claim

pk.readHexFile(filename)
expected = pk.instance_variable_get(:@dataBuffer)

pk.enterPVMode("HVP")
begin
  dev = pk.readChipID
  if dev
    puts "Device: #{dev[:deviceName]}"
  else
    puts "Unknown device ID!"
  end

  prog = pk.readProgramMemory(64)
  config = pk.readConfigMemory(64)

  puts "Program memory 0x0000..0x%04X:" % ((prog.length - 1) * 2)
  prog.each_with_index { |w, i| printf("  %04X: %04X\n", i * 2, w) }

  puts "Config memory 0x10000..0x%05X:" % (0x10000 + (config.length - 1) * 2)
  config.each_with_index { |w, i| printf("  %05X: %04X\n", 0x10000 + i * 2, w) }

  ok = true
  expected.each do |addr, word|
    if addr < 0x2000
      area = "program"
      actual = prog[addr / 2]
      exp = word & 0x3fff
    elsif addr >= 0x10000 && addr < 0x10400
      area = "config"
      actual = config[(addr - 0x10000) / 2]
      exp = word & 0x3fff
    else
      next
    end

    if actual.nil?
      puts "MISSING:  #{area} 0x%05X expected %04X (address not read)" % [addr, exp]
      ok = false
    elsif actual != exp
      puts "MISMATCH: #{area} 0x%05X expected %04X, read %04X" % [addr, exp, actual]
      ok = false
    else
      puts "OK:       #{area} 0x%05X = %04X" % [addr, exp]
    end
  end

  puts(ok ? "VERIFY: PASS" : "VERIFY: FAIL")
ensure
  pk.exitPVMode
  pk.close
end
