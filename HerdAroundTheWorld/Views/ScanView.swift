import SwiftUI
import VisionKit

// Scan tab: point the camera at the code on a Companion's bottom, or type their number.
struct ScanView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var typing = false
    @State private var typed = ""
    @State private var found: Companion? = nil
    @State private var notFound = false
    @FocusState private var numberFocused: Bool

    @MainActor private var cameraAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack { Wordmark(); Spacer() }
            VStack(spacing: 6) {
                Text("Found a Companion?").font(.script(38, relativeTo: .largeTitle)).foregroundStyle(Herd.heading)
                Text("Flip them over and point your camera at the code on their bottom.")
                    .font(.herdBody(16)).foregroundStyle(Herd.body).multilineTextAlignment(.center)
            }

            if typing || !cameraAvailable {
                typePanel
            } else {
                camera
                Button("Or type their number instead") { typing = true; numberFocused = true }
                    .font(.herdBody(15, weight: .medium))
                    .foregroundStyle(Herd.sageDark)
            }
            Spacer()
        }
        .padding(20)
        .herdBackground()
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear { found = nil }
    }

    private var camera: some View {
        ZStack {
            CodeScanner { payload in
                guard found == nil, let number = AppModel.number(fromScan: payload), let c = model.companion(number) else { return }
                found = c
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    router.push(.companion(c.number, showHello: true))
                    found = nil
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Herd.cream, style: StrokeStyle(lineWidth: 4, dash: [26, 14]))
                .frame(width: 200, height: 200)

            if let c = found {
                VStack(spacing: 2) {
                    Text("Hi! It’s #\(c.number), \(c.displayName)").font(.chunky(17, extraBold: false))
                    Text("Opening their page…").font(.herdBody(13))
                }
                .foregroundStyle(Herd.mintInk)
                .padding(.vertical, 10).padding(.horizontal, 16)
                .background(Herd.mintSoft, in: Capsule())
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 16)
            }
        }
        .frame(height: 380)
        .accessibilityLabel("Camera viewfinder. Point it at the code on the Companion’s bottom.")
    }

    private var typePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type their number").font(.chunky(20, extraBold: false)).foregroundStyle(Herd.ink)
            Text("It’s printed on their bottom, under the code: “No. 07”.").font(.herdBody(14)).foregroundStyle(Herd.body)
            HStack(spacing: 6) {
                Text("No.").font(.chunky(24)).foregroundStyle(Herd.sageDark)
                TextField("07", text: $typed)
                    .font(.chunky(24, extraBold: false))
                    .keyboardType(.numberPad)
                    .focused($numberFocused)
                    .accessibilityLabel("Companion number")
            }
            .padding(.horizontal, 16).frame(height: 60)
            .background(Herd.field, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            if notFound {
                Text("We couldn’t find that number. Check their bottom and try again.")
                    .font(.herdBody(14)).foregroundStyle(Herd.pinkInk)
            }
            Button("Find them →") {
                if let c = model.companion(typed) {
                    notFound = false
                    typed = ""
                    router.push(.companion(c.number, showHello: true))
                } else {
                    notFound = true
                }
            }
            .buttonStyle(.herdPrimary)
            .disabled(typed.isEmpty)
            if cameraAvailable {
                Button("Back to the camera") { typing = false; notFound = false }
                    .font(.herdBody(15)).foregroundStyle(Herd.sageDark)
                    .frame(maxWidth: .infinity)
            } else {
                Text("The camera isn’t available here, so type their number instead.")
                    .font(.herdBody(13)).foregroundStyle(Herd.body)
            }
        }
        .padding(18)
        .background(Herd.beige, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// Wraps Apple's live QR scanner (VisionKit). Calls back with the text in the code.
struct CodeScanner: UIViewControllerRepresentable {
    let onCode: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        if !controller.isScanning { try? controller.startScanning() }
    }

    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: Coordinator) {
        controller.stopScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }

    @MainActor final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCode: (String) -> Void
        init(onCode: @escaping (String) -> Void) { self.onCode = onCode }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                if case .barcode(let code) = item, let text = code.payloadStringValue {
                    onCode(text)
                    return
                }
            }
        }
    }
}
