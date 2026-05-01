import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("app_language") var appLanguage: String = "system"
    @State private var selectedTheme = ThemeManager.shared.currentTheme
    @State private var showingLogs = false
    
    var body: some View {
        #if os(tvOS)
        content
            .background(Color.appBackground.ignoresSafeArea())
        #else
        NavigationView {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("done".localized) { dismiss() }
                    }
                }
        }
        #endif
    }
    
    private var content: some View {
        Form {
            Section(header: Text("settings".localized)) {
                Picker("theme".localized, selection: $selectedTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.localizedName).tag(theme)
                    }
                }
                .onChange(of: selectedTheme) { newValue in
                    ThemeManager.shared.currentTheme = newValue
                }
                
                Picker("language".localized, selection: $appLanguage) {
                    Text("follow_system".localized).tag("system")
                    Text("简体中文").tag("zh-Hans")
                    Text("English").tag("en")
                }
                .onChange(of: appLanguage) { newValue in
                    HSBHostsLanguageManager.shared.setLanguage(newValue)
                }
            }
            
            #if os(tvOS)
            Section(header: Text("vpn_usage_title".localized)) {
                Text("vpn_usage_desc".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            #endif
            
            Section(header: Text("about".localized)) {
                NavigationLink(destination: AboutDetailView()) {
                    Label("about".localized, systemImage: "info.circle")
                }
                
                NavigationLink(destination: ContactView()) {
                    Label("contact_us".localized, systemImage: "envelope")
                }
                
                NavigationLink(destination: PrivacyPolicyView()) {
                    Label("privacy_policy".localized, systemImage: "shield.lefthalf.filled")
                }
                
                #if os(tvOS)
                NavigationLink(destination: LogView()) {
                    Label("system_log".localized, systemImage: "terminal")
                }
                #else
                Button {
                    showingLogs = true
                } label: {
                    Label("system_log".localized, systemImage: "terminal")
                }
                #endif
            }
            
            Section {
                HStack {
                    Text("version".localized)
                    Spacer()
                    Text(getVersionString())
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("settings".localized)
        #if os(iOS)
        .sheet(isPresented: $showingLogs) {
            LogView()
        }
        #endif
    }
    
    private func getVersionString() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Subviews

struct AboutDetailView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Image(systemName: " globe") // Placeholder or real AppIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundColor(.appCTA)
                    .padding(.top, 60)
                
                Text("app_name".localized)
                    .font(.system(size: 60, weight: .bold))
                
                Text("about_content".localized)
                    .font(.title3)
                    .padding()
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("about".localized)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct ContactView: View {
    var body: some View {
        List {
            Section(header: Text("contact_desc".localized)) {
                Link(destination: URL(string: "https://github.com/never88gone")!) {
                    HStack {
                        Label("github".localized, systemImage: "link")
                        Spacer()
                        Text("never88gone")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Label("telegram".localized, systemImage: "paperplane")
                    Spacer()
                    Text("@tanghulutvos")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("contact_us".localized)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("privacy_policy".localized)
                    .font(.largeTitle.bold())
                
                Text("privacy_desc".localized)
                    .font(.title3)
                
                Spacer()
            }
            .padding(60)
        }
        .navigationTitle("privacy_policy".localized)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
