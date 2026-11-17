import SwiftUI
import MapKit

// One page per Companion. A scan opens it with the hello card on top.
struct CompanionView: View {
    let number: String
    var startWithHello = false

    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var showHello = false

    var body: some View {
        Group {
            if let c = model.companion(number) {
                page(c)
                    .overlay {
                        if showHello {
                            HelloCard(companion: c) { withAnimation { showHello = false } }
                                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        }
                    }
            } else {
                ContentUnavailableView("We couldn’t find #\(number)", systemImage: "questionmark.circle",
                                       description: Text("Check the number on their bottom and try again."))
            }
        }
        .herdBackground()
        .herdTitle()
        .onAppear { if startWithHello { showHello = true } }
    }

    private func page(_ c: Companion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 16) {
                    CompanionBadge(companion: c, size: 104, waving: true)
                    VStack(alignment: .leading, spacing: 4) {
                        Eyebrow(text: "Art in Transit · No. \(c.number)")
                        Text(c.displayName).font(.script(40, relativeTo: .largeTitle)).foregroundStyle(Herd.heading)
                        InfoPill(text: c.status.label, background: c.status == .retired ? Color(hex: "F8DCC8") : Herd.mintSoft)
                    }
                    Spacer(minLength: 0)
                    VStack(spacing: 8) {
                        ShareLink(item: c.shareURL, subject: Text("Companion #\(c.number)"),
                                  message: Text("Follow Companion #\(c.number) around the world with The Herd.")) {
                            Image(systemName: "ellipsis")
                                .frame(width: 40, height: 40)
                                .background(Herd.mintSoft, in: Circle())
                        }
                        .accessibilityLabel("Share")
                        Button { withAnimation { showHello = true } } label: {
                            Image(systemName: "info")
                                .frame(width: 40, height: 40)
                                .background(Herd.mintSoft, in: Circle())
                        }
                        .accessibilityLabel("About #\(c.number)")
                    }
                    .foregroundStyle(Herd.mintInk)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        InfoPill(text: "\(c.stopCount) stops", background: Herd.beige)
                        InfoPill(text: "\(c.miles.formatted()) miles", background: Herd.butter, foreground: Herd.butterInk)
                        InfoPill(text: "\(c.travelers) travelers", background: Herd.beige)
                    }
                }

                WishCard(wish: c.wishSentence, granted: c.wishGranted)

                miniMap(c)

                VStack(spacing: 10) {
                    if c.status != .retired {
                        Button("I just found them") { router.push(.found(c.number)) }.buttonStyle(.herdPrimary)
                        Button("Pass them on") { router.push(.passOn(c.number)) }.buttonStyle(.herdSoft)
                    }
                    Toggle(isOn: Binding(get: { model.following.contains(c.number) }, set: { _ in model.toggleFollow(c.number) })) {
                        Text("Following · notify me when they move").font(.herdBody(15)).foregroundStyle(Herd.ink)
                    }
                    .tint(Herd.sageDark)
                    .padding(.horizontal, 4)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Where they’ve been").font(.script(30)).foregroundStyle(Herd.heading)
                    ForEach(Array(c.stops.enumerated().reversed()), id: \.element.id) { index, stop in
                        stopRow(stop, number: index + 1, isNow: index == c.stops.count - 1)
                    }
                }

                Button { router.push(.story(c.number)) } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Their story · \(c.stops.filter { $0.note != nil }.count + 1) chapters").font(.chunky(17, extraBold: false)).foregroundStyle(Herd.ink)
                            Text("Read every traveler’s chapter and the chat").font(.herdBody(13)).foregroundStyle(Herd.body)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Herd.sageDark)
                    }
                    .padding(14)
                    .background(Herd.beige, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)

                HStack {
                    Button("About #\(c.number)") { withAnimation { showHello = true } }
                    Spacer()
                    if c.status != .retired {
                        Button("Something happened to them?") { router.push(.broke(c.number)) }
                    }
                }
                .font(.herdBody(14))
                .foregroundStyle(Herd.sageDark)
            }
            .padding(20)
        }
    }

    private func miniMap(_ c: Companion) -> some View {
        let coords = c.stops.map(\.coordinate)
        return VStack(alignment: .leading, spacing: 6) {
            Map(initialPosition: .automatic, interactionModes: []) {
                MapPolyline(coordinates: coords).stroke(c.accentColor, style: StrokeStyle(lineWidth: 2.5, dash: [2, 6]))
                ForEach(Array(c.stops.enumerated()), id: \.element.id) { index, stop in
                    Annotation(index == c.stops.count - 1 ? stop.city : "", coordinate: stop.coordinate) {
                        Circle()
                            .fill(index == c.stops.count - 1 ? c.accentColor : c.accentColor.opacity(0.55))
                            .frame(width: index == c.stops.count - 1 ? 16 : 9, height: index == c.stops.count - 1 ? 16 : 9)
                            .overlay(Circle().strokeBorder(Herd.cream, lineWidth: 2))
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .frame(height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .accessibilityLabel("Map of #\(c.number)’s journey, now in \(c.current?.city ?? "")")
            HStack {
                Text("Live · updated \(c.lastMoved)").font(.herdBody(13)).foregroundStyle(Herd.body)
                Spacer()
                Button("World map →") { router.tab = .map }.font(.herdBody(13, weight: .medium))
            }
        }
    }

    private func stopRow(_ stop: Stop, number: Int, isNow: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.chunky(14, extraBold: false))
                .foregroundStyle(isNow ? .white : Herd.ink)
                .frame(width: 28, height: 28)
                .background(isNow ? Herd.rose : Herd.mintSoft, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(stop.city).font(.herdBody(16, weight: .medium)).foregroundStyle(Herd.ink)
                Text(meta(stop, isNow: isNow)).font(.herdBody(13)).foregroundStyle(Herd.body)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private func meta(_ stop: Stop, isNow: Bool) -> String {
        var parts: [String] = []
        if isNow { parts.append("Now") }
        if let place = stop.place { parts.append(place) }
        if let who = stop.leftBy { parts.append("left by \(who)") }
        if !stop.when.isEmpty { parts.append(stop.when) }
        return parts.joined(separator: " · ")
    }
}

// The card a finder sees right after scanning.
struct HelloCard: View {
    let companion: Companion
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Herd.ink.opacity(0.35).ignoresSafeArea().onTapGesture(perform: onClose)
            ScrollView {
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
                                .frame(width: 36, height: 36).background(Herd.field, in: Circle())
                        }
                        .foregroundStyle(Herd.ink)
                        .accessibilityLabel("Close")
                    }
                    CompanionBadge(companion: companion, size: 104, waving: true, happy: true)
                    Eyebrow(text: "Art in Transit · No. \(companion.number)")
                    Text("Hi, I’m \(companion.displayName)!")
                        .font(.script(38, relativeTo: .largeTitle))
                        .foregroundStyle(Herd.heading)
                        .multilineTextAlignment(.center)
                    Text(companion.blurb).font(.herdBody(15)).foregroundStyle(Herd.body).multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 2) {
                        Eyebrow(text: "My wish", color: Herd.butterInk)
                        Text("“\(companion.wishSentence)”").font(.script(22)).foregroundStyle(Color(hex: "4F4320"))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Herd.butter, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    HStack(spacing: 8) {
                        InfoPill(text: "\(companion.stopCount) stops", background: Herd.beige)
                        InfoPill(text: "Last seen in \(companion.current?.city ?? "")", background: Herd.beige)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow(text: "How this works")
                        NumberedRow(number: "1", text: "Take me along for a while, and help my wish come true if you can!")
                        NumberedRow(number: "2", text: "Leave me somewhere new for someone else to find.")
                        NumberedRow(number: "3", text: "Log the spot and add your chapter to my story.")
                        Text("Log where you leave me and earn a stamp in your Passport.")
                            .font(.herdBody(14)).foregroundStyle(Herd.pinkInk)
                            .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Herd.pinkSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(14)
                    .background(Herd.beige, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    Button("See where I’ve been ↓", action: onClose).buttonStyle(.herdPrimary)

                    (Text("You’ve found a piece of ") + Text("Art in Transit").font(.herdBody(13, weight: .semibold)) + Text(", a traveling art project by The Herd. No app, no sign-up, no cost."))
                        .font(.herdBody(13)).foregroundStyle(Herd.body).multilineTextAlignment(.center)
                }
                .padding(20)
                .background(Herd.cream, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                .padding(16)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .accessibilityAddTraits(.isModal)
    }
}
