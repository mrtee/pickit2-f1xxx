load 'inc.rb'
if ARGV
  File.open(ARGV[0],'r').each do |one_line|
    match=one_line.match(/<payloadbytes>(.*)<\/payloadbytes>/)
    if match && match[1][124..127] == "adad"
      #puts match[1]
      disAsmBlock(:block => hexToString(match[1].gsub(/(..)/,'\1 ')))
      puts"---"
    end
  end
end

