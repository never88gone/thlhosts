import SwiftUI
import CoreImage.CIFilterBuiltins

struct EmptyStateView: View {
    let serverIP: String
    var onImport: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 32) {
            #if os(tvOS)
            tvOSGuide
            #else
            iOSGuide
            #endif
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
    }
    
    private var tvOSGuide: some View {
        VStack(spacing: 50) {
            Image(systemName: "tv.and.mediabox")
                .font(.system(size: 150)) // Larger icon for TV
                .foregroundColor(.appCTA)
                .shadow(color: Color.appCTA.opacity(0.4), radius: 30)
            
            VStack(spacing: 20) {
                Text("scan_to_upload".localized)
                    .font(.system(size: 76, weight: .bold, design: .rounded)) // Title size per HIG
                Text("phone_upload_guide".localized)
                    .font(.system(size: 38, weight: .medium)) // Headline size per HIG
                    .foregroundColor(.appMutedText)
            }
            
            HStack(spacing: 100) {
                VStack(spacing: 32) {
                    if let qrImage = generateQRCode(from: "http://\(serverIP):9971") {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 350, height: 350)
                            .padding(40)
                            .background(Color.white)
                            .cornerRadius(30)
                    }
                    
                    Text("http://\(serverIP):9971")
                        .font(.system(size: 34, weight: .semibold, design: .monospaced))
                        .foregroundColor(.appCTA)
                }
                .padding(60)
                .glassBackground(cornerRadius: 60)
                
                VStack(alignment: .leading, spacing: 40) {
                    StepItem(number: "1", text: "step_1_wifi".localized)
                    StepItem(number: "2", text: "step_2_scan".localized)
                    StepItem(number: "3", text: "step_3_upload".localized)
                }
            }
        }
    }
    
    private var iOSGuide: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.appCTA)
            
            VStack(spacing: 8) {
                Text("no_configs".localized)
                    .font(.title2.bold())
                    .foregroundColor(.appText)
                Text("import_guide".localized)
                    .foregroundColor(.appSubText)
            }
            
            HStack(spacing: 16) {
                Button(action: {
                    onImport?()
                }) {
                    Label("Import File", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .padding()
                        .frame(minWidth: 160)
                        .background(Color.appCTA)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}

struct StepItem: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(number)
                .font(.headline)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.appCTA))
                .foregroundColor(.black)
            
            Text(text)
                .font(.headline)
        }
    }
}
