module PICkit2

  # Class for assembling a command string block
  #   block = PicKit2::Command.new
  #   block.execute_script
  #   block.vpp_off
  #   block.vpp_gnd_on
  #   block.busy_led_on
  #   device.send(block)
  # It is possible to insert commands while initializing:
  #   cmd = PICkit2::Command.new {|x|
  #                               x.no_operation
  #                               x.enter_bootloader
  #                              }
  # or
  #   cmd = PICkit2::Command.new.enter_bootloader
  class Command < String
    
    def initialize(&firstCommand)
      firstCommand && firstCommand.call(self)
      return self
    end


    #-- firmware commands

    def enter_bootloader; self << "\x42"; end
    def no_operation; self << "\x5A"; end
    def firmware_version; self << "\x76"; end

    # :vdd required, :vfault, :vddlim are optional.
    # Also works as command.setvdd(volts)
    def setvdd(arg)
      arg.kind_of?(Numeric) && arg = {:vdd => arg}
      arg[:vfault] ||= arg[:vdd]*0.7
      arg[:vddlim] ||= (arg[:vfault]/5)*255
      ccp = ((arg[:vdd]*32)+10.5).floor << 6 
      self << "\xA0" << (ccp & 255) << (ccp >> 8)
      self << arg[:vddlim].floor
    end
    
    # :vpp required, :vfault is optional.
    # Also works as command.setvpp(volts)
    def setvpp(arg)
      arg.kind_of?(Numeric) && arg = {:vpp => arg}
      arg[:vfault] ||= arg[:vpp]*0.7
      self << "\xA1\x40" << (arg[:vpp]*18.61).floor.chr << (arg[:vfault]*18.61).floor.chr
    end

    def read_status; self << "\xA2"; end
    def read_voltages; self << "\xA3"; end

    # Parameter is the number of the script.
    def download_script(n); self << "\xA4" << n.chr; resetScriptCounters; end
    
    # :script - number of script
    # :times - iterations count
    def run_script(arg); self << "\xA5" << arg[:script] << arg[:times]; end

    def execute_script; self << "\xa6"; resetScriptCounters; end    
    def clr_download_buffer; self << "\xA7"; end
    def download_data(data); self << "\xA8"+data.length.chr+data.map {|x| x*2}.pack("S*"); end
    def clr_upload_buffer; self << "\xA9"; end
    def upload_data; self << "\xAA"; end
    def clr_script_buffer; self << "\xAB"; end
    def upload_data_nolen; self << "\xAC"; end
    def end_of_buffer; self << "\xad"; end
    def reset; self << "\xAE"; end
    def script_buffer_chksm; self << "\xAF"; end
    #--def set_voltage_cals; self << "\xB0"; end
    #--def wr_internal_ee; self << "\xB1"; end
    #--def rd_internal_ee; self << "\xB2"; end
    #--def enter_uart_mode; self << "\xB3"; end
    def exit_uart_mode; self << "\xB4"; end
    #--def enter_learn_mode; self << "\xB5"; end
    def exit_learn_mode; self << "\xB6"; end
    #--def enable_pk2go_mode; self << "\xB7"; end
    #--def logic_analyzer_go; self << "\xB8"; end
    #--def copy_ram_upload; self << "\xB9"; end
    #--def read_osccal; self << "\x80"; end
    #--def write_osccal; self << "\x81"; end
    #--def start_checksum; self << "\x82"; end
    #--def verify_checksum; self << "\x83"; end
    #--def check_device_id; self << "\x84"; end
    def read_bandgap; self << "\x85"; end
    def write_cfg_bandgap; self << "\x86"; end
    #--def change_chksm_frmt; self << "\x87"; end

    #-- script commands

    def vdd_on; etc; self << "\xFF"; end
    def vdd_off; etc; self << "\xFE"; end
    def vdd_gnd_on; etc; self << "\xFD"; end
    def vdd_gnd_off; etc; self << "\xFC"; end
    def vpp_on; etc; self << "\xFB"; end
    def vpp_off; etc; self << "\xFA"; end
    def vpp_pwm_on; etc; self << "\xF9"; end
    def vpp_pwm_off; etc; self << "\xF8"; end
    def mclr_gnd_on; etc; self << "\xF7"; end
    def mclr_gnd_off; etc; self << "\xF6"; end
    def busy_led_on; etc; self << "\xF5"; end
    def busy_led_off; etc; self << "\xF4"; end
    
    # Examples:
    #   cmd.set_icsp_pins(:pgc => 1, :pgd => 0)
    # PGC is "output" with logical "1" value
    # PGD is "output" with logical "0" value
    #   cmd.set.icsp_pins(:pgc => 0)
    #   or
    #   cmd.set.icsp_pins(:pgc => 0, :pgd => "input")
    # PGC is "output" with locical "0" value
    # PGD is "input"
    #   cmd.set.icsp_pins
    # PGC and PGD both are inputs
    def set_icsp_pins(a={})
      etc(2)
      states = 3
      states = states ^ (1+a[:pgc]*4) if a[:pgc].class == Fixnum
      states = states ^ (2+a[:pgd]*8) if a[:pgd].class == Fixnum
      self << "\xF3" << states.chr
    end

    def write_byte_literal(b); etc(2); self << "\xF2" << b.chr; end
    def write_byte_buffer; etc; self << "\xF1"; end
    def read_byte_buffer; etc; self << "\xF0"; end
    def read_byte; etc; self << "\xEF"; end
    
    # Hash argument: :bits and :literal
    # or
    # one Fixnum argument for a literal.
    # Example:
    #   cmd.write_bits_literal(:bits => 6, :literal => 4)
    # is the same as:
    #   cmd.write_bits_literal(4)
    def write_bits_literal(arg)
      if arg.class == Fixnum then
	arg = {:bits => 6, :literal => arg}
      end
      etc(3)
      self << "\xEE"
      self << arg[:bits].chr << arg[:literal].chr
    end

    #--def write_bits_buffer; etc(2); self << "\xED"; end
    #--def read_bits_buffer; etc(2); self << "\xEC"; end
    #--def read_bits; etc(2); self << "\xEB"; end
    def set_icsp_speed(us); etc(2); self << "\xEA"+us.chr; end
    
    # Loop method calculates index bytes from instruction count.
    # So give :commandsBack instead of "bytes back" and
    # number of :iterations in a hash argument.
    def loop(arg)
      self << "\xE9"
      bytesBack = 0
      @cmdLengths[@cmdLengths.length-arg[:commandsBack]..-1].each {|x| bytesBack += x}
      self << bytesBack.chr << arg[:iterations].chr
      etc(3)
    end
    
    def delay_long(ms); etc(2); self << "\xE8" << (ms/5.46).ceil.chr; end
    def delay_short(us); etc(2); self << "\xE7" << (us/21.3).ceil.chr; end
    #--def if_eq_goto; etc(3); self << "\xE6"; end
    #--def if_gt_goto; etc(3); self << "\xE5"; end
    #--def goto_index; etc(2); self << "\xE4"; end
    def exit_script; etc; self << "\xe3"; end
    #--def peek_sfr; etc(2); self << "\xE2"; end
    #--def poke_sfr; etc(3); self << "\xE1"; end
    def icdslave_rx; etc; self << "\xE0"; end
    #--def icdslave_tx_lit; etc(2); self << "\xDF"; end
    def icdslave_tx_buf; etc; self << "\xDE"; end
    #--def loopbuffer; etc(2); self << "\xDD"; end
    def icsp_states_buffer; etc; self << "\xDC"; end
    def pop_download; etc; self << "\xDB"; end
    #--def coreinst18; etc(3); self << "\xDA"; end
    #--def coreinst24; etc(4); self << "\xD9"; end
    def nop24; etc; self << "\xD8"; end
    def visi24; etc; self << "\xD7"; end
    def rd2_byte_buffer; etc; self << "\xD6"; end
    #--def rd2_bits_buffer; etc(2); self << "\xD5"; end
    #--def write_bufword_w; etc(2); self << "\xD4"; end
    #--def write_bufbyte_w; etc(2); self << "\xD3"; end
    #--def const_write_dl; etc(2); self << "\xD2"; end
    #--def write_bits_lit_hld; etc(3); self << "\xD1"; end
    #--def write_bits_buf_hld; etc(2); self << "\xD0"; end
    
    # Parameter is the logical state. Without parameter AUX is input.
    #   cmd.set_aux(1) -- output, "1"
    #   cmd.set_aux(0) -- output, "0"
    #   cmd.set_aux    -- input
    def set_aux(a=2); etc(2); self << "\xCF" << (a*2+a/2).chr; end
  
    def aux_state_buffer; etc; self << "\xCE"; end
    def i2c_start; etc; self << "\xCD"; end
    def i2c_stop; etc; self << "\xCC"; end
    #--def i2c_wr_byte_lit; etc(2); self << "\xCB"; end
    def i2c_wr_byte_buf; etc; self << "\xCA"; end
    def i2c_rd_byte_ack; etc; self << "\xC9"; end
    def i2c_rd_byte_nack; etc; self << "\xC8"; end
    #--def spi_wr_byte_lit; etc(2); self << "\xC7"; end
    def spi_wr_byte_buf; etc; self << "\xC6"; end
    def spi_rd_byte_buf; etc; self << "\xC5"; end
    #--def spi_rdwr_byte_lit; etc(2); self << "\xC4"; end
    def spi_rdwr_byte_buf; etc; self << "\xC3"; end
    def icdslave_rx_bl; etc; self << "\xC2"; end
    #--def icdslave_tx_lit_bl; etc(2); self << "\xC1"; end
    def icdslave_tx_buf_b; etc; self << "\xC0"; end
    def measure_pulse; etc; self << "\xBF"; end
    #--def unio_tx; etc(3); self << "\xBE"; end
    #--def unio_tx_rx; etc(4); self << "\xBD"; end
    #--def jt2_setmode; etc(3); self << "\xBC"; end
    #--def jt2_sendcmd; etc(2); self << "\xBB"; end
    #--def jt2_xferdata8_lit; etc(2); self << "\xBA"; end
    #--def jt2_xferdata32_lit; etc(5); self << "\xB9"; end
    #--def jt2_xfrfastdat_lit; etc(5); self << "\xB8"; end
    def jt2_xfrfastdat_buf; etc; self << "\xB7"; end
    def jt2_xferinst_buf; etc; self << "\xB6"; end
    def jt2_get_pe_resp; etc; self << "\xB5"; end
    def jt2_wait_pe_resp; etc; self << "\xB4"; end
    def jt2_pe_prog_resp; etc; self << "\xB3"; end


    private

    def etc(length=1)
      self[@scriptLengthIndex] = (self.getbyte(@scriptLengthIndex)+length).chr
      @cmdLengths << length
    end

    def resetScriptCounters
      self << "\x00"
      @scriptLengthIndex = self.length-1
      @cmdLengths = []
    end

  end
  
end


