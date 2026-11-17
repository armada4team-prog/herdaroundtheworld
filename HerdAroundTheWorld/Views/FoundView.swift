import SwiftUI

// Step 1 of 2: "I found them" — a quick log so everyone knows the Companion is safe.
struct FoundView: View {
    let number: String
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var city = ""
    @State private var nickname = ""
    @State private var checkIn: CheckIn = .appAlert
    @State private var email = ""
    @State private var alsoTellMe = true
    @State private var done = false
    @State private var locating = false
    @State private var location = LocationHelper()

    private var canSubmit: Bool {
        !city.trimmingCharacters(in: .whitespaces).isEmpty && !nickname.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        let c = model.companion(number)
        let name = c?.displayName ?? "#\(number)"
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if done { doneView(name) } else { form(name) }
            }
            .padding(20)
        }
        .herdBackground()
        .herdTitle("I found them")
        .onAppear { if nickname.isEmpty { nickname = model.nickname } }
    }

    @ViewBuilder
    private func form(_ name: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(text: "Step 1 of 2 · Companion #\(number)")
            Text("You found \(name)!").font(.script(40, relativeTo: .largeTitle)).foregroundStyle(Herd.heading)
            Text("Let everyone know \(name) is safe with you. It takes a few seconds. You’ll log where they go next when you pass them on.")
                .font(.herdBody(16)).foregroundStyle(Herd.body)
        }

        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(text: "Where are you? *")
            TextField("City, like Santa Fe, NM", text: $city).textFieldStyle(HerdFieldStyle()).textContentType(.addressCity)
            Button {
                locating = true
                Task {
                    if let found = await location.currentCity() { city = found }
                    locating = false
                }
            } label: {
                Label(locating ? "Finding your city…" : "Use my city", systemImage: "location")
                    .font(.herdBody(15)).foregroundStyle(Herd.mintInk)
                    .padding(.vertical, 10).padding(.horizontal, 16)
                    .background(Herd.mintSoft, in: Capsule())
            }
            .disabled(locating)
        }

        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(text: "Your name or nickname *")
            TextField("Shown on their page", text: $nickname).textFieldStyle(HerdFieldStyle()).textContentType(.nickname)
        }

        VStack(alignment: .leading, spacing: 10) {
            FieldLabel(text: "Want \(name) to check in with you?")
            Text("In about a month, \(name) will send one friendly nudge to help you pass them on. Totally optional.")
                .font(.herdBody(14)).foregroundStyle(Herd.body)
            PillPicker(options: [(CheckIn.appAlert, "App alert"), (.email, "Email"), (.none, "No thanks")], selection: $checkIn)
            if checkIn == .appAlert {
                Text("We’ll send one gentle app alert in about a month. Nothing else.").font(.herdBody(13)).foregroundStyle(Herd.body)
            }
            if checkIn == .email {
                TextField("you@email.com", text: $email)
                    .textFieldStyle(HerdFieldStyle())
                    .keyboardType(.emailAddress).textContentType(.emailAddress).textInputAutocapitalization(.never)
            }
            if checkIn != .none {
                Toggle("Also tell me where #\(number) goes after me", isOn: $alsoTellMe)
                    .font(.herdBody(15)).foregroundStyle(Herd.ink).tint(Herd.sageDark)
                Text("Never shown publicly. Never shared.").font(.herdBody(13)).foregroundStyle(Herd.body)
            }
        }

        Button("Log my find →") {
            model.logFind(number, city: city, nickname: nickname, checkIn: checkIn, email: checkIn == .email ? email : nil)
            withAnimation { done = true }
        }
        .buttonStyle(.herdPrimary)
        .disabled(!canSubmit)
        .opacity(canSubmit ? 1 : 0.5)
    }

    @ViewBuilder
    private func doneView(_ name: String) -> some View {
        VStack(spacing: 10) {
            if let c = model.companion(number) {
                CompanionBadge(companion: c, size: 120, waving: true, happy: true)
            }
            Text("Logged! Enjoy your time together.").font(.script(36)).foregroundStyle(Herd.heading).multilineTextAlignment(.center)
            Text("Take \(name) along for your trip. When you’re ready, scan them again and tap “I’m passing them on.”")
                .font(.herdBody(16)).foregroundStyle(Herd.body).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)

        Card(background: Herd.beige) {
            Text("Travel tips from \(name)").font(.chunky(18, extraBold: false)).foregroundStyle(Herd.ink)
            NumberedRow(number: "1", text: "Snap a photo of me somewhere fun. It makes a great chapter.")
            NumberedRow(number: "2", text: "Keep me a little while, then send me on. A week or two is perfect.")
        }

        Button("I’m passing them on now") { router.replaceTop(with: .passOn(number)) }.buttonStyle(.herdPrimary)
        Button("See their full story") { router.replaceTop(with: .story(number)) }.buttonStyle(.herdOutline)
    }
}
