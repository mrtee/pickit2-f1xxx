out1=File.open("sc.txt",'w')

File.open("scforras.txt",'r').each do |one_line|
    #out1.puts("")
    #out1.puts("    #"+one_line)
    szam=one_line.match(/.+0(x..).*/)[1]
    betu=one_line.match(/.+"(.+)".*/)[1].downcase
    length=one_line.match(/:dataLength => (.).*/)
    case length
      when nil
        l=""
        k=""
      else
        l="("+(length[1].to_i+1).to_s+")"
        k="#"
    end

    out1.puts("    #{k}def #{betu}(args); etc#{l}; @block << \"\\#{szam}\"; end")
  
end

out1.close

