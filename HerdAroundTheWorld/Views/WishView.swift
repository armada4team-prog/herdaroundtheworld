import SwiftUI

// "You made my wish come true!" — the traveler picks the next wish.
struct WishView: View {
    let number: String
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var pick = "I want to ride a train."
    @State private var custom = ""
    @State private var grantedWish = ""

    private let ideas = ["I want to ride a train.", "I want to meet a dog.", "I want to see snow.",
                         "I want to go to a concert.", "I want to visit a library.", "I want to watch a sunrise."]

    private var chosen: String {
        let text = custom.trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? pick : "I want to \(text)."
    }

    var body: some View {
        let c = model.companion(number)
        let name = c?.displayName ?? "#\(number)"
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 10) {
                    if let c { CompanionBadge(companion: c, size: 130, waving: true, happy: true) }
                    InfoPill(text: "★ Wish granted · Companion #\(number)", background: Herd.cream, foreground: Herd.butterInk)
                    Text("You made my wish come true!").font(.script(40, relativeTo: .largeTitle)).foregroundStyle(Herd.heading)
                        .multilineTextAlignment(.center)
                    Text("“\(grantedWish)” Thanks to you, \(name) finally did. Everyone following them will hear the news.")
                        .font(.herdBody(16)).foregroundStyle(Herd.ink).multilineTextAlignment(.center)
                }
                .padding(.vertical, 22).padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(Herd.butter, in: RoundedRectangle(cornerRadius: 26, style: .continuous))

                Card(background: Herd.pinkSoft) {
                    Eyebrow(text: "Your new stamp", color: Herd.pinkInk)
                    Text("Wish Granted").font(.chunky(26)).foregroundStyle(Herd.pinkInk)
                    Text("A special stamp for your Passport, added after a quick look at your photo. Everyone following \(name) will see you made it happen.")
                        .font(.herdBody(15)).foregroundStyle(Herd.pinkInk)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("You get to choose their next wish").font(.chunky(22, extraBold: false)).foregroundStyle(Herd.sageDark)
                    Text("It goes on their page for the next traveler to try.").font(.herdBody(15)).foregroundStyle(Herd.body)
                }

                FlowLayout(spacing: 10) {
                    ForEach(ideas, id: \.self) { idea in
                        Button { pick = idea; custom = "" } label: {
                            Text(idea)
                                .font(.herdBody(15)).foregroundStyle(Herd.ink)
                                .padding(.vertical, 11).padding(.horizontal, 14)
                                .background(pick == idea && custom.isEmpty ? Herd.mintSoft : .white, in: Capsule())
                                .overlay(Capsule().strokeBorder(pick == idea && custom.isEmpty ? Herd.sageDark : Herd.border, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(pick == idea && custom.isEmpty ? .isSelected : [])
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    FieldLabel(text: "Or write your own")
                    HStack(spacing: 6) {
                        Text("I want to").font(.herdBody(16)).foregroundStyle(Herd.ink)
                        TextField("…", text: $custom)
                            .font(.herdBody(16))
                            .onChange(of: custom) { _, value in if value.count > 50 { custom = String(value.prefix(50)) } }
                        Text("\(custom.count)/50").font(.herdBody(13)).foregroundStyle(Herd.body)
                    }
                    .padding(.horizontal, 14).frame(height: 52)
                    .background(Herd.field, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Text("Keep it kind, safe and doable. Wishes are checked automatically, then The Herd gives them a quick look. Until it’s approved, their page shows a wish from the list.")
                        .font(.herdBody(13)).foregroundStyle(Herd.body)
                }

                Card(background: Herd.beige) {
                    Eyebrow(text: "On their page")
                    Text("Next wish: “\(chosen)”").font(.script(24)).foregroundStyle(Herd.heading)
                    Text("Wish chosen by \(model.nickname.isEmpty ? "you" : model.nickname), who granted their last one.").font(.herdBody(14)).foregroundStyle(Herd.body)
                }

                Button("Set their next wish →") {
                    // List wishes go live right away. A custom wish waits for The Herd's approval,
                    // so the selected list wish shows on their page until then.
                    model.setNextWish(number, wish: pick)
                    router.replaceTop(with: .sent(number))
                }
                .buttonStyle(.herdPrimary)
            }
            .padding(20)
        }
        .herdBackground()
        .herdTitle("Wish granted")
        .onAppear { if grantedWish.isEmpty { grantedWish = c.map { "I wanted to \($0.wish)." } ?? "" } }
    }
}

// Wraps chips onto as many lines as needed.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: min(widest, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
