require 'xcodeproj'

project_path = 'THLHOSTSApp/THLHOSTSApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# --- 1. Utility Methods ---
def duplicate_target(project, src_target_name, new_target_name, platform_sdk, supported_platforms, device_family)
  src_target = project.targets.find { |t| t.name == src_target_name }
  unless src_target
    puts "Source target #{src_target_name} not found!"
    return nil
  end
  
  if project.targets.any? { |t| t.name == new_target_name }
    puts "Target #{new_target_name} already exists, updating settings..."
    t = project.targets.find { |t| t.name == new_target_name }
    t.build_configurations.each do |config|
      config.build_settings['SUPPORTS_MACCATALYST'] = 'YES'
      config.build_settings['SWIFT_VERSION'] = '5.0'
    end
    return t
  end

  puts "Duplicating #{src_target_name} to #{new_target_name}..."
  
  # Create new target
  new_target = project.new_target(src_target.symbol_type, new_target_name, src_target.platform_name, src_target.deployment_target)
  new_target.product_name = new_target_name
  
  # Copy build phases and files
  src_target.build_phases.each do |phase|
    # Create new phase of the same type
    new_phase = project.new(phase.class)
    new_target.build_phases << new_phase
    
    phase.files.each do |file|
      # Avoid duplicating Info.plist if possible, or handle it carefully
      next if file.file_ref && file.file_ref.path && file.file_ref.path.include?('Info.plist')
      
      # Add file reference to the new phase
      new_phase.add_file_reference(file.file_ref)
    end
  end
  
  # Update Build Settings
  new_target.build_configurations.each do |config|
    config.build_settings['SDKROOT'] = platform_sdk
    config.build_settings['SUPPORTED_PLATFORMS'] = supported_platforms
    config.build_settings['TARGETED_DEVICE_FAMILY'] = device_family
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']}.ios"
    config.build_settings['INFOPLIST_FILE'] = 'THLHOSTSApp/Info.plist' # Reuse existing plist for now
    config.build_settings['SUPPORTS_MACCATALYST'] = 'YES'
    config.build_settings['SWIFT_VERSION'] = '5.0'
  end

  return new_target
end

# --- 2. Create iOS Target ---
ios_target = duplicate_target(project, 'THLHOSTSApp', 'THLHOSTSApp_iOS', 'iphoneos', 'iphonesimulator iphoneos', '1,2')

# --- 2.1 Add Logic Files to Apps ---
# Since there is no framework, we add logic files directly to the apps
puts "Adding shared logic files to Apps..."
logic_group = project.main_group.children.find { |c| c.isa == 'PBXGroup' && c.name == 'NetworkExtension' } || project.main_group.new_group('NetworkExtension', 'NetworkExtension')

logic_files = ['HostsManager.swift']
logic_file_refs = []

logic_files.each do |f|
  logic_file_refs << (logic_group.find_file_by_path(f) || logic_group.new_reference(f))
end

# Add to tvOS App
tv_target = project.targets.find { |t| t.name == 'THLHOSTSApp' }
if tv_target
  tv_target.add_file_references(logic_file_refs)
end

# Add to iOS App
if ios_target
  ios_target.add_file_references(logic_file_refs)
end

# --- 3. Create Network Extension Target ---
ne_target_name = 'THLHOSTSNetworkExtension'
ne_target = project.targets.find { |t| t.name == ne_target_name }

unless ne_target
  puts "Creating Network Extension Target: #{ne_target_name}..."
  ne_target = project.new_target(:app_extension, ne_target_name, :ios)
  
  # Add files (Provider + Logic)
  ne_files = ['PacketTunnelProvider.swift', 'HostsManager.swift']
  ne_files.each do |f|
    file_ref = logic_group.find_file_by_path(f) || logic_group.new_reference(f)
    ne_target.add_file_references([file_ref])
  end
  
  # Configure Build Settings
  ne_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.nevergone.huluge.tvbox.extension'
    config.build_settings['INFOPLIST_FILE'] = 'NetworkExtension/Info.plist'
    config.build_settings['SDKROOT'] = 'iphoneos'
    config.build_settings['SUPPORTED_PLATFORMS'] = 'iphonesimulator iphoneos'
    config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
    config.build_settings['SWIFT_VERSION'] = '5.0'
  end
end

# --- 4. Link Extension to App ---
if ios_target && ne_target
  puts "Linking Network Extension to iOS App..."
  embed_phase = ios_target.copy_files_build_phases.find { |p| p.dst_subfolder_spec == '13' }
  unless embed_phase
    embed_phase = ios_target.new_copy_files_build_phase('Embed App Extensions')
    embed_phase.dst_subfolder_spec = '13'
  end
  
  unless embed_phase.files_references.include?(ne_target.product_reference)
    build_file = embed_phase.add_file_reference(ne_target.product_reference)
    build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  end
  
  unless ios_target.dependencies.any? { |d| d.target == ne_target }
    ios_target.add_dependency(ne_target)
  end
end

project.save
puts "Project updated successfully!"
