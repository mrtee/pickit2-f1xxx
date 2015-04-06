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
    :deviceName => "PIC12LF1840",
    :deviceID => 0b011011110,
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
    :deviceName => "PIC16LF1825",
    :deviceID => 0b101000011,
    :programMemory => (0..0x3fff),
    :dataMemory => (0x1e000..0x1e1ff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 32,
    :numberOfLatches => 32,
    :configurationWord1 => 0x1000e,
    :configurationWord2 => 0x10010
  },
    {
    :deviceName => "PIC16F1829",
    :deviceID => 0b100111111,
    :programMemory => (0..0x3fff),
    :dataMemory => (0x1e000..0x1e1ff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 32,
    :numberOfLatches => 32,
    :configurationWord1 => 0x1000e,
    :configurationWord2 => 0x10010
  },
    {
    :deviceName => "PIC16LF1829",
    :deviceID => 0b101000111,
    :programMemory => (0..0x3fff),
    :dataMemory => (0x1e000..0x1e1ff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 32,
    :numberOfLatches => 32,
    :configurationWord1 => 0x1000e,
    :configurationWord2 => 0x10010
  },
    {
    :deviceName => "PIC16F1455",
    :deviceID => 0b0011000000100001,
    :programMemory => (0..0x3fff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 32,
    :numberOfLatches => 8,
    :configurationWord1 => 0x1000e,
    :configurationWord2 => 0x10010
  },
    {
    :deviceName => "PIC16LF1455",
    :deviceID => 0b0011000000100101,
    :programMemory => (0..0x3fff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 32,
    :numberOfLatches => 8,
    :configurationWord1 => 0x1000e,
    :configurationWord2 => 0x10010
  },
    {
    :deviceName => "PIC16F1459",
    :deviceID => 0b0011000000100011,
    :programMemory => (0..0x3fff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 32,
    :numberOfLatches => 8,
    :configurationWord1 => 0x1000e,
    :configurationWord2 => 0x10010
  },
    {
    :deviceName => "PIC16LF1459",
    :deviceID => 0b0011000000100111,
    :programMemory => (0..0x3fff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 32,
    :numberOfLatches => 8,
    :configurationWord1 => 0x1000e,
    :configurationWord2 => 0x10010
  },
    {
    :deviceName => "PIC16F1938",
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
    :deviceName => "PIC16LF1938",
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
    :deviceName => "PIC16F1947",
    :deviceID => 0b100101001,
    :programMemory => (0..0x7fff),
    :dataMemory => (0x1e000..0x1e1ff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 32,
    :numberOfLatches => 8,
    :configurationWord1 => 0x1000e,
    :configurationWord2 => 0x10010
  },
    {
    :deviceName => "PIC16F1827",
    :deviceID => 0b100111101,
    :programMemory => (0..0xfff),
    :dataMemory => (0x1e000..0x1e1ff),
    :configurationMemory => (0x10000..0x103ff),
    :rowSize => 32,
    :numberOfLatches => 8,
    :configurationWord1 => 0x1000e,
    :configurationWord2 => 0x10010
  },
    {
    :deviceName => "PIC16LF1827",
    :deviceID => 0b101000101,
    :programMemory => (0..0xfff),
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
