pattern = /http:\/\/www.oreilly.com.*\.pdf/

output = `ruby oreilly.rb  `

#puts output

Dir.mkdir("Categories") unless Dir.exists?("Categories") 
Dir.chdir("Categories")

changed = false 
folder_name = "" 

output.each_line do |line|
  if(line.include?("## ") &&  !line.include?("### "))
    folder_name = line.gsub!(/[^[a-zA-Z]]/,"")
    if (changed == false)
      Dir.mkdir(folder_name) unless Dir.exists?(folder_name)
      Dir.chdir(folder_name)
      changed = true
    else
      Dir.chdir("..")
      Dir.mkdir(folder_name) unless Dir.exists?(folder_name)
      Dir.chdir(folder_name)
    end
  end
  if(pattern.match(line))
    url = line.match(pattern)
    system("wget -N #{url}")
  end
end

puts "Done"