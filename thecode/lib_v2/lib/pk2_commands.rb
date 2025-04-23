module PICkit2
  
  # Helper methods for composing PICkit2 firmware commands
  # and scripts. Output is unflattened Array of integers.
  # Usage:
  # commandBlock = setvdd(5), execute_script(vdd_gnd_off, vdd_on)
  module Commands

    
    #-- script commands

    def vdd_on; [0xFF]; end
    def vdd_off; [0xFE]; end
    def vdd_gnd_on; [0xFD]; end
    def vdd_gnd_off; [0xFC]; end
    def vpp_on; [0xFB]; end
    def vpp_off; [0xFA]; end
    def vpp_pwm_on; [0xF9]; end
    def vpp_pwm_off; [0xF8]; end
    def mclr_gnd_on; [0xF7]; end
    def mclr_gnd_off; [0xF6]; end
    def busy_led_on; [0xF5]; end
    def busy_led_off; [0xF4]; end
    
    # Examples:
    #   set_icsp_pins(:pgc => 1, :pgd => 0)
    # PGC is "output" with logical "1" value
    # PGD is "output" with logical "0" value
    #   set.icsp_pins(:pgc => 0)
    #   or
    #   set.icsp_pins(:pgc => 0, :pgd => "input")
    # PGC is "output" with locical "0" value
    # PGD is "input"
    #   set.icsp_pins
    # PGC and PGD both are inputs
    def set_icsp_pins(a={})
      states = 3
      states = states ^ (1+a[:pgc]*4) if a[:pgc].class == Integer
      states = states ^ (2+a[:pgd]*8) if a[:pgd].class == Integer
      return [0xF3, states]
    end

    def write_byte_literal(b)
      [0xF2, b]
    end

    def write_byte_buffer; [0xF1]; end
    def read_byte_buffer; [0xF0]; end
    def read_byte; [0xEF]; end
    
    # Hash argument: :bits and :literal
    # or
    # one Integer argument for a literal.
    # Example:
    #   write_bits_literal(:bits => 6, :literal => 4)
    # is the same as:
    #   write_bits_literal(4)
    def write_bits_literal(arg)
      if arg.class == Integer then
	arg = {:bits => 6, :literal => arg}
      end
      return [0xEE, arg[:bits], arg[:literal]]
    end

    #--def write_bits_buffer; [0xED]; end
    #--def read_bits_buffer; [0xEC]; end
    #--def read_bits; [0xEB]; end
    
    def set_icsp_speed(us)
      return [0xEA, us]
    end
    
    # Loop method calculates index bytes from instruction count.
    # So give :commandsBack instead of "bytes back" and
    # number of :iterations in a hash argument.
    def loop(arg)
      [0xE9, arg[:commandsBack], arg[:iterations]]
    end
    
    def delay_long(ms)
      [0xE8, (ms/5.46).ceil]
    end

    def delay_short(us)
      [0xE7, (us/21.3).ceil]
    end
    
    #--def if_eq_goto; [0xE6]; end
    #--def if_gt_goto; [0xE5]; end
    #--def goto_index; [0xE4]; end
    def exit_script; [0xe3]; end
    #--def peek_sfr; [0xE2]; end
    #--def poke_sfr; [0xE1]; end
    def icdslave_rx; [0xE0]; end
    #--def icdslave_tx_lit; [0xDF]; end
    def icdslave_tx_buf; [0xDE]; end
    #--def loopbuffer; [0xDD]; end
    def icsp_states_buffer; [0xDC]; end
    def pop_download; [0xDB]; end
    #--def coreinst18; [0xDA]; end
    #--def coreinst24; [0xD9]; end
    def nop24; [0xD8]; end
    def visi24; [0xD7]; end
    def rd2_byte_buffer; [0xD6]; end
    #--def rd2_bits_buffer; [0xD5]; end
    #--def write_bufword_w; [0xD4]; end
    #--def write_bufbyte_w; [0xD3]; end
    #--def const_write_dl; [0xD2]; end
    #--def write_bits_lit_hld; [0xD1]; end
    #--def write_bits_buf_hld; [0xD0]; end
    
    # Parameter is the logical state. Without parameter AUX is input.
    #   set_aux(1) -- output, "1"
    #   set_aux(0) -- output, "0"
    #   set_aux    -- input
    def set_aux(a=2)
      [0xCF, (a*2+a/2)]
    end
  
    def aux_state_buffer; [0xCE]; end
    def i2c_start; [0xCD]; end
    def i2c_stop; [0xCC]; end
    #--def i2c_wr_byte_lit; [0xCB]; end
    def i2c_wr_byte_buf; [0xCA]; end
    def i2c_rd_byte_ack; [0xC9]; end
    def i2c_rd_byte_nack; [0xC8]; end
    #--def spi_wr_byte_lit; [0xC7]; end
    def spi_wr_byte_buf; [0xC6]; end
    def spi_rd_byte_buf; [0xC5]; end
    #--def spi_rdwr_byte_lit; [0xC4]; end
    def spi_rdwr_byte_buf; [0xC3]; end
    def icdslave_rx_bl; [0xC2]; end
    #--def icdslave_tx_lit_bl; [0xC1]; end
    def icdslave_tx_buf_b; [0xC0]; end
    def measure_pulse; [0xBF]; end
    #--def unio_tx; [0xBE]; end
    #--def unio_tx_rx; [0xBD]; end
    #--def jt2_setmode; [0xBC]; end
    #--def jt2_sendcmd; [0xBB]; end
    #--def jt2_xferdata8_lit; [0xBA]; end
    #--jt2_xferdata32_lit = [xB9]
    #--jt2_xfrfastdat_lit = [xB8]
    def jt2_xfrfastdat_buf; [0xB7]; end
    def jt2_xferinst_buf; [0xB6]; end
    def jt2_get_pe_resp; [0xB5]; end
    def jt2_wait_pe_resp; [0xB4]; end
    def jt2_pe_prog_resp; [0xB3]; end

    #-- firmware commands

    def enter_bootloader; [0x42]; end
    def no_operation; [0x5A]; end
    def firmware_version; [0x76]; end

    # :vdd required, :vfault, :vddlim are optional.
    # Also works as command.setvdd(volts)
    def setvdd(arg)
      arg.kind_of?(Numeric) && arg = {:vdd => arg}
      arg[:vfault] ||= arg[:vdd]*0.7
      arg[:vddlim] ||= (arg[:vfault]/5)*255
      ccp = ((arg[:vdd]*32)+10.5).floor << 6 
      return [0xA0, (ccp & 255), (ccp >> 8), arg[:vddlim].floor]
    end
    
    # :vpp required, :vfault is optional.
    # Also works as command.setvpp(volts)
    def setvpp(arg)
      arg.kind_of?(Numeric) && arg = {:vpp => arg}
      arg[:vfault] ||= arg[:vpp]*0.7
      [0xA1, 0x40, (arg[:vpp]*18.61).floor, (arg[:vfault]*18.61).floor]
    end

    def read_status; [0xA2]; end
    def read_voltages; [0xA3]; end

    # Parameter is the number of the script.
    def download_script(n,*pp)
      [0xA4, n, execute_script(pp)[1..-1]]
    end
    
    # :number - number of script
    # :times - iterations count
    def run_script(arg); [0xA5, arg[:number], arg[:times]]; end

    def execute_script(*s)
      while (s[0].class == Array) && ! s[0][0].kind_of?(Numeric)
	s = s[0]
      end
      s.keep_if {|q| q.is_a?(Array)}
      out = len = []
      s.each do |w|
	w.keep_if {|q| q.kind_of?(Numeric)}
	if w[0] == 0xE9 and w.length == 3 # loop command
	  sum = 0
	  len[-1*w[1]..-1].each {|x| sum += x }
	  w[1] = sum
	end
	out += w
	len << w.length
      end
      #oo=out
      #puts oo.insert(0,0xA6,out.length).map {|x| "%02X" % x}.inspect
      return out.insert(0,0xA6,out.length)
    end

    def clr_download_buffer; [0xA7]; end
    
    def download_data(*data)
      data[1] || data = data[0]
      data.insert(0, 0xA8, data.length)
    end
    
    def clr_upload_buffer; [0xA9]; end
    def upload_data; [0xAA]; end
    def clr_script_buffer; [0xAB]; end
    def upload_data_nolen; [0xAC]; end
    def end_of_buffer; [0xad]; end
    def reset; [0xAE]; end
    def script_buffer_chksm; [0xAF]; end
    #--def set_voltage_cals; [0xB0]; end
    #--def wr_internal_ee; [0xB1]; end
    #--def rd_internal_ee; [0xB2]; end
    #--def enter_uart_mode; [0xB3]; end
    def exit_uart_mode; [0xB4]; end
    #--def enter_learn_mode; [0xB5]; end
    def exit_learn_mode; [0xB6]; end
    #--def enable_pk2go_mode; [0xB7]; end
    #--def logic_analyzer_go; [0xB8]; end
    #--def copy_ram_upload; [0xB9]; end
    #--def read_osccal; [0x80]; end
    #--def write_osccal; [0x81]; end
    #--def start_checksum; [0x82]; end
    #--def verify_checksum; [0x83]; end
    #--def check_device_id; [0x84]; end
    def read_bandgap; [0x85]; end
    def write_cfg_bandgap; [0x86]; end
    #--def change_chksm_frmt; [0x87]; end

  end
  
end


