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
            #if os(iOS) || os(macOS)
            .listRowBackground(Color.appSecondary)
            #endif
            
            #if os(tvOS)
            Section(header: Text("vpn_usage_title".localized).foregroundColor(.appSubText)) {
                Text("vpn_usage_desc".localized)
                    .font(.caption)
                    .foregroundColor(.appSubText)
            }
            #if os(iOS) || os(macOS)
            .listRowBackground(Color.appSecondary)
            #endif
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
            #if os(iOS) || os(macOS)
            .listRowBackground(Color.appSecondary)
            #endif
            
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
        ScrollView {
            VStack(spacing: 30) {
                Image(systemName: "envelope.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.appCTA)
                    .padding(.top, 40)
                    
                Text("contact_us".localized)
                    .font(.system(size: 50, weight: .bold))
                    
                Text("contact_desc".localized)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    
                VStack(spacing: 20) {
                    ContactCard(
                        icon: "link",
                        title: "github".localized,
                        subtitle: "never88gone",
                        url: "https://github.com/never88gone"
                    )
                    
                    ContactCard(
                        icon: "paperplane.fill",
                        title: "telegram".localized,
                        subtitle: "@tanghulutvos",
                        url: "https://t.me/tanghulutvos"
                    )
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("contact_us".localized)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.appBackground.ignoresSafeArea())
        #endif
    }
}

struct ContactCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let url: String
    
    var body: some View {
        Button(action: {
            if let targetURL = URL(string: url) {
                #if os(iOS)
                UIApplication.shared.open(targetURL)
                #endif
            }
        }) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(.appCTA)
                    .frame(width: 40)
                    
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding()
            #if os(tvOS)
            .padding(.vertical, 8)
            #endif
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("privacy_policy".localized)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
