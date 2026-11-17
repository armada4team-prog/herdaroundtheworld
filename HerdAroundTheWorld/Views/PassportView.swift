import SwiftUI

// Passport tab: your travels, stamps and herd.
struct PassportView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Wordmark()
                    Spacer()
                    ShareLink(item: URL(string: "https://theherdstudio.com")!, message: Text("I’m part of The Herd’s Companions project! Find one, carry one, watch them go.")) {
                        Image(systemName: "ellipsis").frame(width: 40, height: 40).background(Herd.mintSoft, in: Circle())
                    }
                    .foregroundStyle(Herd.mintInk)
                    .accessibilityLabel("Share")
                }

                if model.email == nil {
                    Button { router.showSignIn = true } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope")
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Save your Passport").font(.herdBody(15, weight: .semibold))
                                Text("Add your email so your stamps are never lost").font(.herdBody(13))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(Herd.butterInk)
                        .padding(14)
                        .background(Herd.butter, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                passportCover

                HStack(spacing: 10) {
                    tile("Map", "Where everyone is", Herd.mintSoft, Herd.mintInk) { router.tab = .map }
                    tile("Found one?", "Scan a Companion", Herd.pinkSoft, Herd.pinkInk) { router.tab = .scan }
                }

                Text("Stamps").font(.script(32)).foregroundStyle(Herd.heading)
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(model.stamps) { StampView(stamp: $0) }
                    StampView(stamp: Stamp(big: "?", small: "Next", label: "Your next Companion", background: "FDF8F3", ring: "B9C9BF", ink: "566E62", tilt: 0, isEmpty: true))
                    StampView(stamp: Stamp(big: "?", small: "Next", label: "Grant another wish", background: "FDF8F3", ring: "B9C9BF", ink: "566E62", tilt: 0, isEmpty: true))
                }

                Card(background: Herd.beige) {
                    Text("Your herd: \(model.herdSize) travelers in 5 countries").font(.chunky(18, extraBold: false)).foregroundStyle(Herd.ink)
                    Text("Everyone who carried the same Companions as you. You’re connected, even if you’ve never met.")
                        .font(.herdBody(14)).foregroundStyle(Herd.body)
                }
            }
            .padding(20)
        }
        .herdBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var passportCover: some View {
        ZStack(alignment: .topTrailing) {
            Blob(variant: 1).fill(Color.white.opacity(0.12)).frame(width: 130, height: 110).offset(x: 30, y: -30)
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Herd Around the World · Passport", color: Herd.mintSoft)
                Text(model.nickname.isEmpty ? "Your travels" : "\(model.nickname)’s travels")
                    .font(.script(36, relativeTo: .largeTitle)).foregroundStyle(.white)
                HStack(alignment: .top) {
                    coverStat("\(model.companionsCarried)", "Companions carried")
                    coverStat("\(model.milesCarried)", "Miles carried")
                    coverStat("\(model.herdSize)", "Travelers in your herd")
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Herd.sageDark, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func coverStat(_ n: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(n).font(.chunky(24)).foregroundStyle(.white)
            Text(label).font(.herdBody(12, relativeTo: .caption)).foregroundStyle(Herd.mintSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func tile(_ title: String, _ detail: String, _ bg: Color, _ fg: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.chunky(16, extraBold: false))
                Text(detail).font(.herdBody(12, relativeTo: .caption))
            }
            .foregroundStyle(fg)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bg, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
