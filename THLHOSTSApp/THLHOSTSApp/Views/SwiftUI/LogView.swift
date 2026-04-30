import SwiftUI

struct LogView: View {
    @State private var logs: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    Text(logs)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.appCTA)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("bottom")
                }
                .background(Color.appBackground.opacity(0.95))
                .onChange(of: logs) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .navigationTitle("System Logs")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        HSBLogger.shared.clear()
                        refreshLogs()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        shareLogs()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                #endif
            }
        }
        .onAppear {
            refreshLogs()
            NotificationCenter.default.addObserver(forName: HSBLogger.didUpdateLogs, object: nil, queue: .main) { _ in
                refreshLogs()
            }
        }
    }
    
    private func refreshLogs() {
        self.logs = HSBLogger.shared.logs.joined(separator: "\n")
    }
    
    #if os(iOS)
    private func shareLogs() {
        let activityVC = UIActivityViewController(activityItems: [logs], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
            }
            rootVC.present(activityVC, animated: true)
        }
    }
    #endif
}

#Preview {
    LogView()
}
