require 'xcodeproj'
project_path = 'THLHOSTSApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)
targets = project.targets

group = project.main_group.find_subpath('THLHOSTSApp/Views', false)
files_to_add = ['SettingsIconButton.swift']

files_to_add.each do |file_name|
  file_ref = group.find_file_by_path(file_name) || group.new_file(file_name)
  targets.each do |target|
    unless target.source_build_phase.files_references.include?(file_ref)
      target.add_file_references([file_ref])
      puts "Added #{file_name} to target: #{target.name}"
    end
  end
end

project.save
puts "Saved project"
