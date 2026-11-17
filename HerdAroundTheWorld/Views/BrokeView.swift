import SwiftUI

// "Something happened" — broke, chipped or lost. Every journey deserves an ending.
struct BrokeView: View {
    let number: String
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    enum What: Hashable { case broke, chipped, lost }
    @State private var what: What = .broke
    @State private var whereText = ""
    @State private var chapter = ""
    @State private var sendHome = true
    @State private var nickname = ""
    @State private var sent = false

    private var canSubmit: Bool { !whereText.isEmpty && !nickname.isEmpty }

    var body: some View {
        let c = model.companion(number)
        let name = c?.displayName ?? "#\(number)"
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if sent {
                    VStack(spacing: 10) {
                        Image(systemName: "heart.fill").font(.system(size: 34)).foregroundStyle(Herd.rose)
                        Text("Thank you for telling us").font(.script(36)).foregroundStyle(Herd.heading)
                        Text(what == .chipped
                             ? "We’ve noted the chip. \(name) can keep traveling."
                             : "Everyone who followed \(name) will get a note, and their journey is kept safe on their page.")
                            .font(.herdBody(16)).foregroundStyle(Herd.body).multilineTextAlignment(.center)
                        Button("Back to their page") { router.replaceTop(with: .companion(number, showHello: false)) }
                            .buttonStyle(.herdPrimary).padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: "Companion #\(number)")
                        Text("Oh no, did something happen to \(name)?").font(.script(36, relativeTo: .largeTitle)).foregroundStyle(Herd.heading)
                        Text("Clay is fragile, and accidents happen on the road. Thank you for letting everyone know. Every journey deserves an ending.")
                            .font(.herdBody(16)).foregroundStyle(Herd.body)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        FieldLabel(text: "What happened? *")
                        ChoiceCard(title: "They broke", detail: "Their journey ends here.", isOn: what == .broke) { what = .broke }
                        ChoiceCard(title: "They got chipped, but can keep traveling", detail: "Their journey continues.", isOn: what == .chipped) { what = .chipped }
                        ChoiceCard(title: "They got lost", detail: "Their journey ends where they were last seen.", isOn: what == .lost) { what = .lost }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel(text: "Where? *")
                        TextField("A city, like Lisbon, Portugal", text: $whereText).textFieldStyle(HerdFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel(text: what == .chipped ? "Add a note (optional)" : "Write their last chapter")
                        TextField("What happened, and what did they mean to you?", text: $chapter, axis: .vertical)
                            .lineLimit(3...6).textFieldStyle(HerdFieldStyle())
                    }

                    if what == .broke {
                        Card(background: Herd.mintSoft) {
                            Text("Want to send the pieces home?").font(.chunky(18, extraBold: false)).foregroundStyle(Herd.mintInk)
                            Text("If you can, The Herd would love to have them back in the studio. We’ll email you how.")
                                .font(.herdBody(14)).foregroundStyle(Herd.mintInk)
                            Toggle("Yes, tell me how", isOn: $sendHome).font(.herdBody(15)).tint(Herd.sageDark)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel(text: "Your name or nickname *")
                        TextField("Shown on their page", text: $nickname).textFieldStyle(HerdFieldStyle())
                    }

                    if what != .chipped {
                        Text("Everyone who followed \(name) will get a note, and their page will show a Retired badge with their whole journey kept safe.")
                            .font(.herdBody(14)).foregroundStyle(Herd.body)
                    }

                    Button(what == .chipped ? "Send the note" : "Share their last chapter") {
                        model.reportBroken(number, lost: what == .lost, chipped: what == .chipped)
                        withAnimation { sent = true }
                    }
                    .buttonStyle(.herdPrimary)
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)
                }
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.immediately)
        .herdBackground()
        .herdTitle("Something happened")
        .onAppear { if nickname.isEmpty { nickname = model.nickname } }
    }
}
