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
        .preferredColorScheme(.dark)
        .toolbarColorScheme(.dark, for: .navigationBar)
        #endif
    }
    
    private var content: some View {
        Form {
            Section(header: Text("settings".localized).foregroundColor(.appSubText)) {
                Picker("language".localized, selection: $appLanguage) {
                    Text("follow_system".localized).tag("system")
                    Text("简体中文").tag("zh-Hans")
                    Text("English").tag("en")
                }
                .onChange(of: appLanguage) { newValue in
                    HSBHostsLanguageManager.shared.setLanguage(newValue)
                }
            }
            .listRowBackground(Color.appSecondary)
            
            #if os(tvOS)
            Section(header: Text("vpn_usage_title".localized).foregroundColor(.appSubText)) {
                Text("vpn_usage_desc".localized)
                    .font(.caption)
                    .foregroundColor(.appSubText)
            }
            .listRowBackground(Color.appSecondary)
            #endif
            
            Section(header: Text("about".localized).foregroundColor(.appSubText)) {
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
            .listRowBackground(Color.appSecondary)
            
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
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        #endif
        #if os(iOS)
        .sheet(isPresented: $showingLogs) {
            LogView()
                .preferredColorScheme(.dark)
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
                Image(systemName: "globe") // Fixed: removed leading space
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundColor(.appCTA)
                    .padding(.top, 60)
                
                Text("app_name".localized)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.appText)
                
                Text("about_content".localized)
                    .font(.title3)
                    .foregroundColor(.appSubText)
                    .padding()
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("about".localized)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.appBackground.ignoresSafeArea())
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
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        #endif
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("privacy_policy".localized)
                    .font(.largeTitle.bold())
                    .foregroundColor(.appText)
                
                Text("privacy_desc".localized)
                    .font(.title3)
                    .foregroundColor(.appSubText)
                
                Spacer()
            }
            .padding(60)
        }
        .navigationTitle("privacy_policy".localized)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.appBackground.ignoresSafeArea())
        #endif
    }
}
