import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // We can wrap the existing managers
    @State private var selectedLanguage = HSBHostsLanguageManager.shared.currentLanguage
    @State private var selectedTheme = ThemeManager.shared.currentTheme
    @State private var showingLogs = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $selectedTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.localizedName).tag(theme)
                        }
                    }
                    .onChange(of: selectedTheme) { newValue in
                        ThemeManager.shared.currentTheme = newValue
                    }
                }
                
                Section(header: Text("Language")) {
                    Picker("Language", selection: $selectedLanguage) {
                        Text("English").tag("en")
                        Text("简体中文").tag("zh-Hans")
                    }
                    .onChange(of: selectedLanguage) { newValue in
                        HSBHostsLanguageManager.shared.currentLanguage = newValue
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button {
                        showingLogs = true
                    } label: {
                        Label("System Logs", systemImage: "terminal")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingLogs) {
                LogView()
            }
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
}

#Preview {
    SettingsView()
}
