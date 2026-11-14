#!/usr/bin/env ruby
$LOAD_PATH << File.expand_path("lib", __dir__)

begin
  require 'tk'
rescue LoadError
  warn "Ruby/Tk is not installed. See README.asciidoc for installation instructions."
  exit 1
end

require 'thread'
require 'fileutils'
require 'pk2_commands'
require 'pic14_f1'

class Pk2Gui
  def initialize
    @queue = Queue.new
    @busy = false
    @buttons = []
    build
    poll
  end

  def run
    Tk.mainloop
  end

  private

  def build
    @root = TkRoot.new do
      title "PICkit2 Programmer"
    end
    @root.geometry("780x520")
    @root.protocol("WM_DELETE_WINDOW") { @root.destroy }

    top = TkFrame.new(@root) do
      pack("side" => "top", "fill" => "x", "padx" => 8, "pady" => 6)
    end

    TkLabel.new(top) do
      text "Hex file:"
      pack("side" => "left")
    end

    initial_hex = ARGV[0] || load_last_hex
    initial_hex = Dir.glob("*.hex").first.to_s unless File.file?(initial_hex)
    @file_var = TkVariable.new(initial_hex)
    file_var = @file_var

    TkEntry.new(top) do
      textvariable file_var
      width 64
      pack("side" => "left", "padx" => 6, "fill" => "x", "expand" => true)
    end

    browse_proc = proc { browse }

    TkButton.new(top) do
      text "Browse..."
      command browse_proc
      pack("side" => "left")
    end

    controls = TkFrame.new(@root) do
      pack("side" => "top", "fill" => "x", "padx" => 8, "pady" => 4)
    end

    add_button(controls, "Program", proc { program_hex })
    add_button(controls, "Verify", proc { verify_hex })
    add_button(controls, "Read ID", proc { read_id })
    add_button(controls, "Power On", proc { set_power(true) })
    add_button(controls, "Power Off", proc { set_power(false) })

    log_frame = TkFrame.new(@root) do
      pack("side" => "top", "fill" => "both", "expand" => true, "padx" => 8, "pady" => 6)
    end

    @log = TkText.new(log_frame) do
      wrap "word"
      height 20
      width 80
      state "disabled"
      pack("side" => "left", "fill" => "both", "expand" => true)
    end

    scroll = TkScrollbar.new(log_frame) do
      pack("side" => "right", "fill" => "y")
    end

    scroll.command(proc { |*args| @log.yview(*args) })
    @log.yscrollcommand(proc { |first, last| scroll.set(first, last) })

    @status = TkLabel.new(@root) do
      text "Ready"
      anchor "w"
      pack("side" => "bottom", "fill" => "x", "padx" => 8, "pady" => 4)
    end
  end

  def add_button(parent, label, command)
    button = TkButton.new(parent) do
      text label
      command command
      pack("side" => "left", "padx" => 4)
    end
    @buttons << button
  end

  def browse
    options = { "filetypes" => [["Hex files", "*.hex"], ["All files", "*"]] }
    current = @file_var.value.to_s

    if File.file?(current)
      options["initialdir"] = File.dirname(current)
      options["initialfile"] = File.basename(current)
    elsif File.directory?(current)
      options["initialdir"] = current
    end

    file = Tk.getOpenFile(options).to_s
    return if file.empty?

    @file_var.value = file
    save_last_hex(file)
  end

  def last_hex_file
    config_dir = File.join(ENV["XDG_CONFIG_HOME"] || File.join(Dir.home, ".config"), "pickit2-f1xxx")
    File.join(config_dir, "last_hex")
  end

  def load_last_hex
    File.read(last_hex_file).strip
  rescue SystemCallError
    ""
  end

  def save_last_hex(path)
    FileUtils.mkdir_p(File.dirname(last_hex_file))
    File.write(last_hex_file, path)
  rescue SystemCallError
  end

  def program_hex
    run_async("Program #{File.basename(@file_var.value)}") do
      expected = parse_hex(@file_var.value)
      raise "No data records found in #{@file_var.value}" if expected.empty?

      pk = open_device
      begin
        pk.instance_variable_set(:@dataBuffer, expected)
        pk.enterPVMode("HVP")
        dev = pk.readChipID
        log("Device: #{dev ? dev[:deviceName] : 'unknown'}")
        pk.burn
        log("Programming complete")
        verify(pk, expected)
      ensure
        pk.exitPVMode
        pk.close
      end
    end
  end

  def verify_hex
    run_async("Verify #{File.basename(@file_var.value)}") do
      expected = parse_hex(@file_var.value)
      raise "No data records found in #{@file_var.value}" if expected.empty?

      pk = open_device
      begin
        pk.enterPVMode("HVP")
        verify(pk, expected)
      ensure
        pk.exitPVMode
        pk.close
      end
    end
  end

  def read_id
    run_async("Read device ID") do
      pk = open_device
      begin
        pk.enterPVMode("HVP")
        dev = pk.readChipID
        log(dev ? "Device: #{dev[:deviceName]}" : "Unknown device ID")
      ensure
        pk.exitPVMode
        pk.close
      end
    end
  end

  def set_power(on)
    run_async(on ? "Power on" : "Power off") do
      pk = open_device
      begin
        on ? pk.powerOn : pk.powerOff
        volts = pk.readVoltages
        log("VDD: %.2f V, VPP: %.2f V" % [volts[:vdd], volts[:vpp]])
      ensure
        pk.close
      end
    end
  end

  def open_device
    pk = PICkit2::Programmer.new
    pk.claim
    pk
  end

  def verify(pk, expected)
    errors = []
    program_entries = expected.select { |addr, _| addr < 0x10000 }
    config_entries = expected.select { |addr, _| addr >= 0x10000 && addr < 0x10400 }
    data_entries = expected.select { |addr, _| addr >= 0x1e000 && addr < 0x1e200 }

    unless program_entries.empty?
      max_addr = program_entries.map(&:first).max
      words = read_program_words(pk, 0, max_addr / 2 + 1)

      program_entries.each do |addr, word|
        actual = words[addr / 2]
        exp = word & 0x3fff
        next if actual == exp

        errors << "program 0x%05X expected %04X, read %s" %
                  [addr, exp, actual ? "%04X" % actual : "----"]
      end
    end

    unless config_entries.empty?
      config = pk.readConfigMemory(64)

      config_entries.each do |addr, word|
        actual = config[(addr - 0x10000) / 2]
        exp = word & 0x3fff
        next if actual == exp

        errors << "config 0x%05X expected %04X, read %s" %
                  [addr, exp, actual ? "%04X" % actual : "----"]
      end
    end

    unless data_entries.empty?
      log("Data EEPROM present in hex; verification not implemented for it")
    end

    if errors.empty?
      log("Verify OK: #{program_entries.size} program words, #{config_entries.size} config words")
      true
    else
      errors.each { |error| log(error) }
      log("Verify FAILED: #{errors.size} difference(s)")
      false
    end
  end

  def read_program_words(pk, start_word, count)
    pk.send(pk.execute_script(pk.write_bits_literal(0x16)))
    adjust_program_counter(pk, start_word * 2)

    words = []
    remaining = count

    while remaining > 0
      n = [remaining, 64].min
      script = [
        pk.write_bits_literal(4),
        pk.read_byte_buffer,
        pk.read_byte_buffer
      ]

      if n > 1
        script << pk.write_bits_literal(6)
        script << pk.loop(:commandsBack => 4, :iterations => n - 1)
      end

      answer = pk.receive(
        pk.clr_upload_buffer,
        pk.execute_script(script),
        pk.upload_data_nolen
      )
      answer << pk.receive(pk.upload_data_nolen) if n > 32

      words.concat(answer.unpack("S*").map { |x| x / 2 & 16383 }[0, n])
      remaining -= n
    end

    words
  end

  def adjust_program_counter(pk, target)
    current = 0

    while target - current > 511
      pk.send(
        pk.execute_script(
          pk.write_bits_literal(6),
          pk.loop(:commandsBack => 1, :iterations => 255)
        )
      )
      current += 512
    end

    if target - current == 2
      pk.send(pk.execute_script(pk.write_bits_literal(6)))
      current += 2
    end

    if current < target
      pk.send(
        pk.execute_script(
          pk.write_bits_literal(6),
          pk.loop(:commandsBack => 1, :iterations => (target - current - 2) / 2)
        )
      )
    end
  end

  def parse_hex(filename)
    data = []
    addr_hi = 0

    File.foreach(filename) do |line|
      match = line.match(/\A:(\h{2})(\h{4})(\h{2})(\h*)(\h{2})/)
      next unless match

      addr_lo = match[2].to_i(16)
      type = match[3].to_i(16)

      case type
      when 0x04
        addr_hi = match[4].to_i(16)
      when 0x00
        match[4].scan(/\h{4}/) do |dataword|
          word = dataword.to_i(16)
          data << [
            (addr_hi << 16) + addr_lo,
            ((word & 0xff) << 8) + (word >> 8)
          ]
          addr_lo += 2
        end
      end
    end

    data.sort
  end

  def run_async(name)
    if @busy
      log("Busy, please wait")
      return
    end

    @busy = true
    set_buttons(false)
    @status.configure("text" => name)
    log("== #{name} ==")

    Thread.new do
      begin
        yield
      rescue => e
        @queue << "#{e.class}: #{e.message}"
      ensure
        @queue << :done
      end
    end
  end

  def poll
    until @queue.empty?
      item = @queue.pop

      if item == :done
        @busy = false
        set_buttons(true)
        @status.configure("text" => "Ready")
      else
        append_log(item.to_s)
      end
    end

    Tk.after(100) { poll }
  end

  def log(message)
    @queue << message
  end

  def append_log(message)
    @log.configure("state" => "normal")
    @log.insert("end", message + "\n")
    @log.see("end")
    @log.configure("state" => "disabled")
  end

  def set_buttons(enabled)
    state = enabled ? "normal" : "disabled"
    @buttons.each { |button| button.configure("state" => state) }
  end
end

Pk2Gui.new.run
