import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = HostsViewModel()
    @State private var showingSettings = false
    @State private var showingPicker = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        Group {
            #if os(tvOS)
            stackView
            #elseif os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                splitView
            } else {
                stackView
            }
            #else
            splitView
            #endif
        }
        .background(Color.appBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
        #if os(iOS) || os(macOS)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .preferredColorScheme(.dark)
        }
        #endif
    }
    
    // MARK: - Layouts
    
    private var splitView: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            HostsListView(viewModel: viewModel, showingSettings: $showingSettings, showingPicker: $showingPicker)
                #if os(tvOS)
                .navigationTitle("")
                #else
                .navigationTitle("app_name".localized)
                #endif
        } detail: {
            if let selected = viewModel.selectedFile {
                HostsDetailView(viewModel: viewModel, file: selected)
            } else if viewModel.hostsFiles.isEmpty {
                EmptyStateView(serverIP: viewModel.serverIP, onImport: {
                    viewModel.triggerFileImport()
                })
            } else {
                // List not empty but nothing selected
                VStack(spacing: 20) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 50))
                        .foregroundColor(.appCTA.opacity(0.5))
                    Text("请从左侧选择一个配置")
                        .font(.headline)
                        .foregroundColor(.appSubText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.appBackground.ignoresSafeArea())
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    private var stackView: some View {
        NavigationStack {
            HostsListView(viewModel: viewModel, showingSettings: $showingSettings, showingPicker: $showingPicker)
                #if os(tvOS)
                .navigationTitle("")
                #else
                .navigationTitle("app_name".localized)
                #endif
                .navigationDestination(for: HostsFile.self) { file in
                    HostsDetailView(viewModel: viewModel, file: file)
                }
                .navigationDestination(isPresented: $showingSettings) {
                    SettingsView()
                }
                .navigationDestination(isPresented: $showingPicker) {
                    HostsPickerView(viewModel: viewModel)
                }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    MainView()
}

// MARK: - Picker View

struct HostsPickerView: View {
    @ObservedObject var viewModel: HostsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var focusedFileInPicker: HostsFile?
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: List of configurations
            VStack(alignment: .leading, spacing: 30) {
                Text("configurations".localized)
                    .font(.system(size: 60, weight: .bold))
                    .padding(.horizontal, 60)
                    .padding(.top, 60)
                
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(viewModel.hostsFiles) { file in
                            Button(action: {
                                viewModel.toggleHosts(file)
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(file.name)
                                            .font(.title2.bold())
                                        if file.isEnabled {
                                            Text("active".localized)
                                                .font(.caption)
                                                .foregroundColor(.appCTA)
                                        }
                                    }
                                    Spacer()
                                    if file.isEnabled {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.appCTA)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.bordered)
                            .onFocusChange { focused in
                                if focused {
                                    focusedFileInPicker = file
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 60)
                    .padding(.bottom, 60)
                }
            }
            .frame(width: 700)
            .background(Color.black.opacity(0.15))
            
            // Right: Content Preview
            VStack(alignment: .leading, spacing: 30) {
                if let file = focusedFileInPicker ?? viewModel.activeHostsFile ?? viewModel.hostsFiles.first {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(file.name)
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.appCTA)
                        
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("hosts_content".localized)
                        }
                        .font(.title3)
                        .foregroundColor(.secondary)
                    }
                    
                    ScrollView {
                        Text(file.content)
                            .font(.system(.title3, design: .monospaced))
                            .lineSpacing(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(40)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                } else {
                    Spacer()
                    VStack(spacing: 30) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 120))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("no_configs".localized)
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
            }
            .padding(80)
            .frame(maxWidth: .infinity)
            .background(Color.appBackground)
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .onAppear {
            focusedFileInPicker = viewModel.activeHostsFile ?? viewModel.hostsFiles.first
        }
    }
}

// MARK: - View Extensions

extension View {
    func onFocusChange(perform action: @escaping (Bool) -> Void) -> some View {
        self.modifier(FocusModifier(action: action))
    }
}

struct FocusModifier: ViewModifier {
    @FocusState private var isFocused: Bool
    let action: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: isFocused) { newValue in
                action(newValue)
            }
    }
}
