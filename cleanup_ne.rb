require 'xcodeproj'

project_path = 'THLHOSTSApp/THLHOSTSApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

ne_target = project.targets.find { |t| t.name == 'THLHOSTSNetworkExtension' }

if ne_target
  puts "Cleaning up THLHOSTSNetworkExtension..."
  sources_phase = ne_target.source_build_phase
  
  # List of allowed files in the extension
  allowed_files = ['PacketTunnelProvider.swift', 'HostsManager.swift']
  
  sources_phase.files_references.each do |file_ref|
    if file_ref && file_ref.path
      filename = File.basename(file_ref.path)
      unless allowed_files.include?(filename)
        puts "Removing #{filename} from THLHOSTSNetworkExtension sources..."
        sources_phase.remove_file_reference(file_ref)
      end
    else
      # Remove broken references (null/no path)
      puts "Removing broken reference from THLHOSTSNetworkExtension sources..."
      # Finding the specific build file to remove is easier by filtering the files array
    end
  end
  
  # Clean up the files array directly to remove (null) entries
  sources_phase.files.each do |build_file|
    if build_file.file_ref.nil?
      puts "Removing null BuildFile from THLHOSTSNetworkExtension..."
      sources_phase.files.delete(build_file)
    end
  end
  
  project.save
  puts "Cleanup complete!"
else
  puts "Target THLHOSTSNetworkExtension not found!"
end
