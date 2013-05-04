module PICkit2

  # hint
  # programMemory: datasheet*2
  # dataMemory: 1e000+datasheet*2
  # configurationMemory: 10000+datasheet*2

  PIC14F1DeviceData = 
    {
    :deviceName => "PIC12F1840",
    :deviceID => 0b011011100,
    :programMemory => (0..0x1fff),
    :dataMemory => (0x1e000..0x1e1ff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 32,
    :numberOfLatches => 32,
    :configurationWord1 => 0x1000e,
    :configurationWord2 => 0x10010
  },
    {
    :deviceName => "PIC16F1847",
    :deviceID => 0b010100100,
    :programMemory => (0..0x3fff),
    :dataMemory => (0x1e000..0x1e1ff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 32,
    :numberOfLatches => 32,
    :configurationWord1 => 0x1000e,
    :configurationWord2 => 0x10010
  },
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
    :deviceName => "PIC12F1938",
    :deviceID => 0b100011101,
    :programMemory => (0..0x7fff),
    :dataMemory => (0x1e000..0x1e1ff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 32,
    :numberOfLatches => 8,
    :configurationWord1 => 0x1000e,
    :configurationWord2 => 0x10010
  },
    {
    :deviceName => "PIC12LF1938",
    :deviceID => 0b100100101,
    :programMemory => (0..0x7fff),
    :dataMemory => (0x1e000..0x1e1ff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 32,
    :numberOfLatches => 8,
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
