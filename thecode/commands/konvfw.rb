out1=File.open("fw.txt",'w')

File.open("fwforras.txt",'r').each do |one_line|
    #out1.puts("")
    #out1.puts("    #"+one_line)
    szam=one_line.match(/.+0(x..).*/)[1]
    betu=one_line.match(/.+"(.+)".*/)[1].downcase
    length=one_line.match(/:dataLength => (.).*/)
    case length
      when nil
        k=""
      else k="#"
    end

    out1.puts("    #{k}def #{betu}(args); @block << \"\\#{szam}\"; end")
  
end

out1.close

