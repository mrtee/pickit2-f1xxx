module PICkit2
  PIC14F1DeviceData = 
    {
    :deviceName => "PIC16F1825",
    :deviceID => 0b100111011,
    :programMemory => (0..0x3fff),
    :dataMemory => (0x1e000..0x1e1ff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 32,
    :numberOfLatches => 32,
    :configurationWord1 => 0x1000e,
    :configurationWord2 => 0x10010
  },
    {
    :deviceName => "PIC12F1822",
    :deviceID => 0b100111000,
    :programMemory => (0..0xfff),
    :dataMemory => (0x1e000..0x1e1ff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 16,
    :numberOfLatches => 16,
    :configurationWord1 => 0x1000e,
    :configurationWord2 => 0x10010
  },
    {
    :deviceName => "PIC12LF1822",
    :deviceID => 0b101000000,
    :programMemory => (0..0xfff),
    :dataMemory => (0x1e000..0x1e1ff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 16,
    :numberOfLatches => 16,
    :configurationWord1 => 0x1000e,
    :configurationWord2 => 0x10010
  }
end
