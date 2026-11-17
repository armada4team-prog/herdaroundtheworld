import SwiftUI

// "Thank you! They're on their way." — postcard, Instagram tips and the new stamp.
struct SentView: View {
    let number: String
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var copied = false

    var body: some View {
        let c = model.companion(number)
        let city = c?.current?.city ?? ""
        let caption = "Companion #\(number) is in \(city)! Thanks for traveling with me. @growtheherdstudio #TheHerdCompanions"
        ScrollView {
            VStack(spacing: 16) {
                Text("Thank you! They’re on their way.").font(.script(40, relativeTo: .largeTitle)).foregroundStyle(Herd.heading)
                    .multilineTextAlignment(.center)
                Text("Your chapter is on their map now. Photos appear after a quick look, usually within a few days.")
                    .font(.herdBody(16)).foregroundStyle(Herd.body).multilineTextAlignment(.center)
                if let c, c.miles > 0 {
                    InfoPill(text: "★ Milestone: #\(number) has traveled \(c.miles.formatted()) miles!", background: Herd.butter, foreground: Herd.butterInk)
                }

                if let c {
                    Postcard(companion: c)
                    HStack(spacing: 10) {
                        Button(copied ? "Copied!" : "Copy caption") {
                            UIPasteboard.general.string = caption
                            copied = true
                        }
                        .buttonStyle(.herdSoft)
                        ShareLink(item: postcardImage(c), preview: SharePreview("Greetings from \(city)!", image: postcardImage(c))) {
                            Text("Save postcard")
                        }
                        .buttonStyle(.herdPrimary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Share it on Instagram").font(.chunky(22, extraBold: false)).foregroundStyle(Herd.ink)
                    NumberedRow(number: "1", text: "Posting? Tap Tag people → Invite collaborator → @growtheherdstudio. It shows on both our pages, and it stays yours.")
                    NumberedRow(number: "2", text: "Story? Mention @growtheherdstudio and we’ll reshare it.")
                    Text(caption)
                        .font(.herdBody(14)).foregroundStyle(Herd.ink)
                        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(18)
                .background(Herd.beige, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                Card(background: Herd.pinkSoft) {
                    Text("New stamp: Passed on #\(number)").font(.chunky(22)).foregroundStyle(Herd.pinkInk)
                    Text("Added to your Passport after a quick review.").font(.herdBody(15)).foregroundStyle(Herd.pinkInk)
                }

                Button("See their journey") { router.replaceTop(with: .companion(number, showHello: false)) }.buttonStyle(.herdPrimary)
                Button("See my Passport") { router.paths[router.tab] = []; router.tab = .passport }
                    .font(.herdBody(15)).foregroundStyle(Herd.sageDark)
            }
            .padding(20)
        }
        .herdBackground()
        .herdTitle("Sent on their way")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { router.paths[router.tab] = [] }.font(.herdBody(16, weight: .medium))
            }
        }
    }

    @MainActor private func postcardImage(_ c: Companion) -> Image {
        let renderer = ImageRenderer(content: Postcard(companion: c).frame(width: 350).padding(10).background(Herd.cream))
        renderer.scale = 3
        if let ui = renderer.uiImage { return Image(uiImage: ui) }
        return Image(systemName: "photo")
    }
}

struct Postcard: View {
    let companion: Companion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottom) {
                Rectangle().fill(Herd.sageBackground)
                CompanionFigure(glaze: companion.glazeColor, waving: true, happy: true, showsShadow: false)
                    .frame(height: 110).padding(.bottom, 10)
                VStack {
                    HStack {
                        InfoPill(text: "Your photo", background: Herd.cream)
                        Spacer()
                        Text("#\(companion.number)")
                            .font(.chunky(18)).foregroundStyle(Herd.sageDark)
                            .frame(width: 60, height: 68)
                            .overlay(Rectangle().strokeBorder(Color(hex: "8FAA9B"), style: StrokeStyle(lineWidth: 2, dash: [4, 3])))
                            .rotationEffect(.degrees(6))
                    }
                    Spacer()
                }
                .padding(12)
            }
            .frame(height: 200)
            Text("Greetings from \(companion.current?.city ?? "the road")!").font(.script(28)).foregroundStyle(Herd.heading)
            Text("\(companion.displayName) · Companion #\(companion.number) · Stop \(companion.stops.count) · theherdstudio.com/c/\(companion.number)")
                .font(.herdBody(13)).foregroundStyle(Herd.body)
        }
        .padding(12)
        .background(.white)
        .overlay(Rectangle().strokeBorder(Herd.sage, lineWidth: 2))
        .accessibilityElement(children: .combine)
    }
}
