import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = HostsViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        Group {
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                splitView
            } else {
                stackView
            }
            #elseif os(tvOS) || os(macOS)
            splitView
            #else
            stackView
            #endif
        }
        .background(Color.appBackground.ignoresSafeArea())
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        // Apply global styles if needed
    }
    
    // MARK: - Layouts
    
    private var splitView: some View {
        NavigationSplitView {
            HostsListView(viewModel: viewModel)
                .navigationTitle("THLHOSTS")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        settingsButton
                    }
                }
        } detail: {
            if let selected = viewModel.selectedFile {
                HostsDetailView(viewModel: viewModel, file: selected)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select a hosts file to view details")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var stackView: some View {
        NavigationStack {
            HostsListView(viewModel: viewModel)
                .navigationTitle("THLHOSTS")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        settingsButton
                    }
                }
                .navigationDestination(for: HostsFile.self) { file in
                    HostsDetailView(viewModel: viewModel, file: file)
                }
        }
    }
    
    private var settingsButton: some View {
        Button(action: { showingSettings = true }) {
            Image(systemName: "gearshape")
        }
    }
}

#Preview {
    MainView()
}
