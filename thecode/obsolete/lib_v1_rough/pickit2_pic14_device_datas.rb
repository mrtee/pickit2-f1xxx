module PICkit2
  PIC14DeviceData = 
    {
    :deviceName => "PIC12HV615",
    :deviceID = 0b100001101,
    :programMemory => (0..0x3ff),
    :programMemoryVirtual => (0..0x1fff),             
    :configurationMemory => (0x2000..0x2008),
    :configurationMemoryVirtual => (0x2000..0x203f)
  },
    {
    :deviceName => "PIC12F1822",
    :deviceID => 0b100111000,
    :programMemory => (0..0x7ff),
    :programMemoryVirtual => (0..0x7fff),
    :dataMemory => (0xf000..0xf0ff),
    :configurationMemory => (0x8000..0x800a),
    :configurationMemoryVirtual => (0x8000..0xffff),
    :features => %w{LowVoltageProgramming },
    :vpp => [8, 9],
    :vdd => [2.1, 5.5]
  },
    {
    :deviceName => "PIC16HV785",
    :deviceID => 0b1010001,
    :programMemory => (0..0x7ff),
    :programMemoryVirtual => (0..0x1fff),             
    :dataMemory => (0x2100..0x21ff),
    :configurationMemory => (0x2000..0x2009),
    :configurationMemoryVirtual => (0x2000..0x3fff)
  }
=begin    {
    :deviceName => "PIC",
    :deviceID => 0b,
    :programMemory => (0..0x),
    :programMemoryVirtual => (0..0x),             
    :dataMemory => (0x..0x),
    :configurationMemory => (0x..0x),
    :configurationMemoryVirtual => (0x..0xffff)
  },
    {
    :deviceName => "PIC",
    :deviceID => 0b,
    :programMemory => (0..0x),
    :programMemoryVirtual => (0..0x),             
    :dataMemory => (0x..0x),
    :configurationMemory => (0x..0x),
    :configurationMemoryVirtual => (0x..0xffff)
  }
=end
=begin
      PIC12F615 10 0001 100 x xxxx
      PIC12HV615 10 0001 101 x xxxx
      PIC12F617 01 0011 011 x xxxx
      PIC16F616 01 0010 010 x xxxx
      PIC16HV616 01 0010 011 x xxxx
      PIC12F609 10 0010 010 x xxxx
      PIC12HV609 10 0010 100 x xxxx
      PIC16F610 10 0010 011 x xxxx
      PIC16HV610 10 0010 101 x xxxx
=end
