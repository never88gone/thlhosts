import SwiftUI

struct HostsListView: View {
    @ObservedObject var viewModel: HostsViewModel
    @State private var showingAddAlert = false
    @State private var newFileName = ""
    
    var body: some View {
        List {
            Section {
                ForEach(viewModel.hostsFiles) { file in
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(file.name)
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.appText)
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(file.isEnabled ? Color.appCTA : Color.appMutedText)
                                    .frame(width: 6, height: 6)
                                
                                Text(file.isEnabled ? "Active" : "Inactive")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(file.isEnabled ? .appCTA : .appMutedText)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(file.isEnabled ? Color.appCTA.opacity(0.15) : Color.appMutedText.opacity(0.1))
                                    )
                            }
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { file.isEnabled },
                            set: { _ in viewModel.toggleHosts(file) }
                        ))
                        #if os(iOS)
                        .toggleStyle(SwitchToggleStyle(tint: .appCTA))
                        #endif
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .glassBackground(cornerRadius: 12)
                    .onTapGesture {
                        viewModel.selectedFile = file
                    }
                    #if os(iOS)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteHosts(file)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    #endif
                }
            } header: {
                Text("Configurations")
                    .font(.caption.bold())
                    .foregroundColor(.appMutedText)
                    .textCase(.uppercase)
            }
        }
        #if os(tvOS)
        .listStyle(GroupedListStyle())
        #else
        .listStyle(InsetGroupedListStyle())
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddAlert = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                VPNStatusView(isEnabled: viewModel.isVPNEnabled)
            }
        }
        .alert("New Hosts File", isPresented: $showingAddAlert) {
            TextField("Name", text: $newFileName)
            Button("Cancel", role: .cancel) { newFileName = "" }
            Button("Add") {
                if !newFileName.isEmpty {
                    viewModel.addNewHosts(name: newFileName)
                    newFileName = ""
                }
            }
        } message: {
            Text("Enter a name for the new hosts configuration.")
        }
    }
}

struct VPNStatusView: View {
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isEnabled ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(isEnabled ? "VPN ON" : "VPN OFF")
                .font(.caption2.bold())
                .foregroundColor(isEnabled ? .green : .red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().stroke(isEnabled ? Color.green : Color.red, lineWidth: 1))
    }
}

#Preview {
    NavigationView {
        HostsListView(viewModel: HostsViewModel())
    }
}
