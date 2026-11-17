import SwiftUI

// The Herd tab: greeting, your numbers, who you follow, the Originals, latest sightings and Instagram.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                greeting
                stats
                followingSection
                originalsSection
                sightingsSection
                learnLink
                stampsCard
                instagram
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .herdBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            Wordmark()
            Spacer()
            Button { router.push(.learn) } label: {
                Text("?").font(.chunky(18)).foregroundStyle(Herd.mintInk)
                    .frame(width: 40, height: 40).background(Herd.mintSoft, in: Circle())
            }
            .accessibilityLabel("How it works")
            Button { router.showLanguage = true } label: {
                Label(model.language.uppercased(), systemImage: "globe")
                    .font(.herdBody(14))
                    .foregroundStyle(Herd.mintInk)
                    .padding(.horizontal, 12).frame(height: 40)
                    .background(Herd.field, in: Capsule())
            }
            .accessibilityLabel("Language")
        }
        .padding(.top, 8)
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.nickname.isEmpty ? "Hi there!" : "Hi, \(model.nickname)!")
                .font(.script(40, relativeTo: .largeTitle))
                .foregroundStyle(Herd.heading)
            Text("Your herd is on the move. \(movedCount) Companions you follow moved this week.")
                .font(.herdBody(16))
                .foregroundStyle(Herd.body)
        }
    }

    private var movedCount: String {
        let n = model.followed.filter(\.movedThisWeek).count
        return n == 2 ? "Two" : "\(n)"
    }

    private var stats: some View {
        HStack(spacing: 10) {
            stat("\(model.companionsCarried)", "Companions carried", Herd.mintSoft, Herd.mintInk)
            stat("\(model.wishesGranted)", model.wishesGranted == 1 ? "Wish granted" : "Wishes granted", Herd.butter, Herd.butterInk)
            stat("\(model.herdSize)", "Travelers in your herd", Herd.pinkSoft, Herd.pinkInk)
        }
    }

    private func stat(_ number: String, _ label: String, _ bg: Color, _ fg: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(number).font(.chunky(26))
            Text(label).font(.herdBody(12, relativeTo: .caption)).fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(fg)
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .topLeading)
        .background(bg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var followingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Following").font(.script(30)).foregroundStyle(Herd.heading)
                Spacer()
                Button("See map") { router.tab = .map }
                    .font(.herdBody(14)).foregroundStyle(Herd.sageDark)
            }
            if model.followed.isEmpty {
                Text("Follow a Companion from their page to see their news here.")
                    .font(.herdBody(14)).foregroundStyle(Herd.body)
            }
            ForEach(model.followed) { companion in
                Button { router.push(.companion(companion.number, showHello: false)) } label: {
                    HStack(spacing: 12) {
                        CompanionBadge(companion: companion, size: 52)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(companion.label).font(.chunky(17, extraBold: false)).foregroundStyle(Herd.sageDark)
                            Text(news(for: companion)).font(.herdBody(14)).foregroundStyle(Herd.ink)
                            Text("\(companion.lastMoved) · \(companion.stopCount) stops").font(.herdBody(12, relativeTo: .caption)).foregroundStyle(Herd.body)
                        }
                        Spacer()
                        if companion.movedThisWeek {
                            Circle().fill(Herd.rose).frame(width: 9, height: 9).accessibilityLabel("New")
                        }
                    }
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Herd.line))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func news(for c: Companion) -> String {
        if c.wishGranted { return "Wish granted!" }
        return "Just arrived in \(c.current?.city ?? "somewhere new")"
    }

    private var originalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Meet the Originals").font(.script(30)).foregroundStyle(Herd.heading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(model.originals) { c in
                        Button { router.push(.companion(c.number, showHello: false)) } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                ZStack(alignment: .bottom) {
                                    Rectangle().fill(c.blobColor)
                                    CompanionFigure(glaze: c.glazeColor, showsShadow: false).frame(height: 62).padding(.bottom, 8)
                                }
                                .frame(width: 124, height: 96)
                                Text(c.label).font(.chunky(15, extraBold: false)).foregroundStyle(Herd.sageDark)
                                Text(c.current?.city ?? "").font(.herdBody(12, relativeTo: .caption)).foregroundStyle(Herd.body)
                            }
                            .padding(8)
                            .background(.white)
                            .overlay(Rectangle().strokeBorder(Herd.sage, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var sightingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Latest sightings").font(.script(30)).foregroundStyle(Herd.heading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    sighting(title: "#07 arrived in Santa Fe", text: "“On a café windowsill, watching the street.”", color: Herd.mintSoft, number: "07")
                    sighting(title: "#2’s wish came true!", text: "They saw the ocean in Lisbon.", color: Herd.butter, number: "2")
                }
            }
        }
    }

    private func sighting(title: String, text: String, color: Color, number: String) -> some View {
        Button { router.push(.companion(number, showHello: false)) } label: {
            VStack(alignment: .leading, spacing: 6) {
                PhotoPlaceholder(color: color, height: 110)
                Text(title).font(.chunky(15, extraBold: false)).foregroundStyle(Herd.sageDark)
                Text(text).font(.herdBody(13)).foregroundStyle(Herd.ink).fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 210, alignment: .leading)
            .padding(10)
            .background(.white)
            .overlay(Rectangle().strokeBorder(Herd.sage, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private var learnLink: some View {
        Button { router.push(.learn) } label: {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(Herd.mintInk)
                    .frame(width: 44, height: 44).background(Herd.mintSoft, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("How it works & where to pass one on").font(.chunky(16, extraBold: false)).foregroundStyle(Herd.ink)
                    Text("Wishes, stamps, good spots and places to avoid").font(.herdBody(13)).foregroundStyle(Herd.body)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Herd.sageDark)
            }
            .padding(14)
            .background(Herd.beige, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var stampsCard: some View {
        Card(background: Herd.pinkSoft) {
            Text("Two new stamps!").font(.chunky(22)).foregroundStyle(Herd.pinkInk)
            Text("You passed #3 on and granted their wish. Both stamps are in your Passport now.")
                .font(.herdBody(14)).foregroundStyle(Herd.pinkInk)
            Button("See my Passport") { router.tab = .passport }
                .buttonStyle(.herdPrimary)
                .fixedSize()
        }
    }

    private var instagram: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Companions on Instagram").font(.script(30)).foregroundStyle(Herd.heading)
            HStack(spacing: 8) {
                tile("#07 in Santa Fe", Herd.mintSoft)
                tile("#3 in Tokyo", Herd.pinkSoft)
                tile("#2 in Lisbon", Herd.butter)
            }
            (Text("Mention ") + Text("@growtheherdstudio").font(.herdBody(14, weight: .semibold)) + Text(" in your story and we’ll reshare it."))
                .font(.herdBody(14)).foregroundStyle(Herd.ink)
            Link("Follow @growtheherdstudio", destination: URL(string: "https://www.instagram.com/growtheherdstudio/")!)
                .font(.herdBody(14, weight: .medium))
        }
    }

    private func tile(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.herdBody(12, relativeTo: .caption))
            .foregroundStyle(Herd.ink)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(color)
    }
}
