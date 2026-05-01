import SwiftUI

struct LogView: View {
    @State private var logs: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            #if os(tvOS)
            headerView
            #endif
            
            ScrollViewReader { proxy in
                ScrollView {
                    Text(logs)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("bottom")
                }
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .onChange(of: logs) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            
            #if !os(tvOS)
            .navigationTitle("system_log".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("clear".localized) {
                        HSBLogger.shared.clear()
                        refreshLogs()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("done".localized) { dismiss() }
                }
            }
            #endif
        }
        #if os(tvOS)
        .padding(60)
        .background(Color.appBackground.ignoresSafeArea())
        #endif
        .onAppear {
            refreshLogs()
            NotificationCenter.default.addObserver(forName: HSBLogger.didUpdateLogs, object: nil, queue: .main) { _ in
                refreshLogs()
            }
        }
    }
    
    #if os(tvOS)
    private var headerView: some View {
        HStack {
            Text("system_log".localized)
                .font(.largeTitle.bold())
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
    
    private func refreshLogs() {
        self.logs = HSBLogger.shared.logs.joined(separator: "\n")
    }
}

#Preview {
    LogView()
}
