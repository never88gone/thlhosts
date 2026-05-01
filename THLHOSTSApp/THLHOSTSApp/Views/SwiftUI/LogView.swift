import SwiftUI

struct LogView: View {
    @State private var logs: String = ""
    @Environment(\.dismiss) var dismiss
    @State private var observer: NSObjectProtocol?
    
    var body: some View {
        #if os(tvOS)
        VStack(spacing: 0) {
            headerView
            logScrollView
        }
        .padding(60)
        .background(Color.appBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { setupObserver() }
        .onDisappear { teardownObserver() }
        #else
        NavigationView {
            VStack(spacing: 0) {
                logScrollView
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("system_log".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HSBLogger.shared.clear()
                        refreshLogs()
                    } label: {
                        Label("clear".localized, systemImage: "trash")
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { setupObserver() }
        .onDisappear { teardownObserver() }
        #endif
    }
    
    // MARK: - Log ScrollView (shared)
    
    private var logScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if logs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("暂无日志\n启动服务或切换配置后将在此显示运行记录")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                } else {
                    Text(logs)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.appText) // 柔和的白色
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("bottom")
                }
            }
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .padding()
            .onChange(of: logs) { _ in
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - tvOS Header
    
    #if os(tvOS)
    private var headerView: some View {
        HStack {
            Text("system_log".localized)
                .font(.largeTitle.bold())
                .foregroundColor(.appText)
            Spacer()
            Button("clear".localized) {
                HSBLogger.shared.clear()
                refreshLogs()
            }
            .buttonStyle(.bordered)
        }
        .padding(.bottom, 20)
    }
    #endif
    
    // MARK: - Helpers
    
    private func refreshLogs() {
        self.logs = HSBLogger.shared.logs.joined(separator: "\n")
    }
    
    private func setupObserver() {
        refreshLogs()
        observer = NotificationCenter.default.addObserver(
            forName: HSBLogger.didUpdateLogs, object: nil, queue: .main
        ) { _ in
            refreshLogs()
        }
    }
    
    private func teardownObserver() {
        if let obs = observer {
            NotificationCenter.default.removeObserver(obs)
            observer = nil
        }
    }
}

#Preview {
    LogView()
}
