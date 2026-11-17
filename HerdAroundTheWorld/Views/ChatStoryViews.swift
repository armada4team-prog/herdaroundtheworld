import SwiftUI

// Traveler chat: one conversation per Companion, for everyone who has carried them.
struct ChatView: View {
    let number: String
    @Environment(AppModel.self) private var model
    @State private var draft = ""

    var body: some View {
        let c = model.companion(number)
        let messages = model.chats[number] ?? []
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(c?.travelers ?? 0) travelers · everyone who’s carried \(c?.displayName ?? "#\(number)")")
                            .font(.herdBody(14)).foregroundStyle(Herd.body)
                        Label("Be kind. Phone numbers, emails and addresses are hidden automatically.", systemImage: "lock")
                            .font(.herdBody(13)).foregroundStyle(Herd.body)
                            .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Herd.beige, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        ForEach(messages) { message in
                            bubble(message).id(message.id)
                        }
                    }
                    .padding(20)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            composer
        }
        .herdBackground()
        .herdTitle("Travelers of #\(number)")
    }

    private func bubble(_ m: ChatMessage) -> some View {
        let mine = m.kind == .me
        return VStack(alignment: mine ? .trailing : .leading, spacing: 4) {
            Text(m.who).font(.herdBody(12, relativeTo: .caption)).foregroundStyle(Herd.body)
            Text(m.text)
                .font(.herdBody(15))
                .foregroundStyle(mine ? .white : (m.kind == .herd ? Herd.mintInk : Herd.ink))
                .padding(12)
                .background(mine ? Herd.sageDark : (m.kind == .herd ? Herd.mintSoft : .white),
                            in: UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: mine ? 18 : 6,
                                                       bottomTrailingRadius: mine ? 6 : 18, topTrailingRadius: 18, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
        .accessibilityElement(children: .combine)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Message the travelers of #\(number)", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(HerdFieldStyle())
            Button {
                model.sendChat(number, text: draft)
                draft = ""
            } label: {
                Image(systemName: "arrow.up").font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 44, height: 44).background(Herd.sageDark, in: Circle())
            }
            .accessibilityLabel("Send")
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Herd.cream)
        .overlay(alignment: .top) { Divider().overlay(Herd.line) }
    }
}

// Their story: the origin story by The Herd, then every traveler's chapter.
struct StoryView: View {
    let number: String
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        ScrollView {
            if let c = model.companion(number) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        CompanionBadge(companion: c, size: 70)
                        VStack(alignment: .leading) {
                            Eyebrow(text: c.label)
                            Text("Their story").font(.script(40, relativeTo: .largeTitle)).foregroundStyle(Herd.heading)
                        }
                    }

                    Card(background: Herd.butter) {
                        Eyebrow(text: "Chapter 1 · Their origin story, by The Herd", color: Herd.butterInk)
                        Text(c.originStory).font(.herdBody(15)).foregroundStyle(Herd.butterInk)
                    }

                    ForEach(Array(c.stops.enumerated().dropFirst().reversed()), id: \.element.id) { index, stop in
                        VStack(alignment: .leading, spacing: 8) {
                            if stop.note != nil { PhotoPlaceholder(height: 140) }
                            HStack {
                                Text(stop.city).font(.chunky(18, extraBold: false)).foregroundStyle(Herd.sageDark)
                                Spacer()
                                InfoPill(text: index == c.stops.count - 1 ? "Now" : "Stop \(index)", background: Herd.mintSoft, foreground: Herd.mintInk)
                            }
                            if let place = stop.place { Text(place).font(.herdBody(14)).foregroundStyle(Herd.ink) }
                            Text([stop.leftBy.map { "Left by \($0)" }, stop.when.isEmpty ? nil : stop.when].compactMap { $0 }.joined(separator: " · "))
                                .font(.herdBody(13)).foregroundStyle(Herd.body)
                            if let note = stop.note {
                                Text("“\(note)”").font(.herdBody(15)).foregroundStyle(Herd.ink)
                            }
                        }
                        .padding(14)
                        .background(.white)
                        .overlay(Rectangle().strokeBorder(Herd.sage, lineWidth: 2))
                    }

                    Button { router.push(.chat(number)) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Traveler chat · \(c.travelers) travelers").font(.chunky(17, extraBold: false)).foregroundStyle(Herd.ink)
                                Text("“\(model.chats[number]?.last?.text ?? "Say hi to the travelers before you.")”")
                                    .font(.herdBody(13)).foregroundStyle(Herd.body).lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Herd.sageDark)
                        }
                        .padding(14)
                        .background(Herd.beige, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    if c.status != .retired {
                        Button("Something happened to them?") { router.push(.broke(number)) }
                            .font(.herdBody(14)).foregroundStyle(Herd.sageDark)
                    }
                }
                .padding(20)
            }
        }
        .herdBackground()
        .herdTitle()
    }
}
