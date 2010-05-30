task :"update-external-includes" do
	Dir.glob("External/{Auspicion,Hammer}").each do |external|
		Dir.glob("#{external}/{Classes,Other Sources}").each do |folder|
			puts folder
			%x{mkdir -p "External/Include/#{File.basename(external)}"}
			puts %x{find "#{folder}" -name '*.h' -exec ln -s '../../../\{\}' "External/Include/#{File.basename(external)}" \\;}
		end
	end
end