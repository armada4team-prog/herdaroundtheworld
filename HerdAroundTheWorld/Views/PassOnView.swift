import SwiftUI
import PhotosUI

// Step 2 of 2: send them on their way (hand to someone or leave somewhere), with an optional photo and chapter.
struct PassOnView: View {
    let number: String
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    @State private var handToSomeone = true
    @State private var whereText = ""
    @State private var publicPlace = false
    @State private var photo: PhotosPickerItem? = nil
    @State private var photoImage: Image? = nil
    @State private var shareOK = true
    @State private var chapter = ""
    @State private var grantedWish = false
    @State private var wishPhoto: PhotosPickerItem? = nil
    @State private var wishImage: Image? = nil
    @State private var nickname = ""
    @State private var email = ""
    @State private var alertMe = true
    @State private var locating = false
    @State private var location = LocationHelper()

    private var canSubmit: Bool {
        !whereText.trimmingCharacters(in: .whitespaces).isEmpty
            && !nickname.trimmingCharacters(in: .whitespaces).isEmpty
            && (!grantedWish || wishImage != nil)
    }

    var body: some View {
        let c = model.companion(number)
        let name = c?.displayName ?? "#\(number)"
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Step 2 of 2 · Companion #\(number)")
                    Text("Send \(name) on their way").font(.script(40, relativeTo: .largeTitle)).foregroundStyle(Herd.heading)
                    Text("Thanks for traveling together. Tell us where they’re headed next.").font(.herdBody(16)).foregroundStyle(Herd.body)
                }

                if !model.nickname.isEmpty, model.holding.contains(number) {
                    Text("Welcome back, \(model.nickname)! We filled in your details from last time.")
                        .font(.herdBody(15)).foregroundStyle(Herd.mintInk)
                        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Herd.mintSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 10) {
                    FieldLabel(text: "How are you passing them on? *")
                    ChoiceCard(title: "Handing them to someone", detail: "Give them to a fellow traveler: a new friend, a host, someone heading somewhere fun.",
                               badge: "Most personal", isOn: handToSomeone) { handToSomeone = true; publicPlace = false }
                    ChoiceCard(title: "Leaving them somewhere", detail: "A café shelf, a hostel lobby, a little free library. Somewhere they’ll be found.",
                               isOn: !handToSomeone) { handToSomeone = false }
                }

                VStack(alignment: .leading, spacing: 8) {
                    FieldLabel(text: "Where? *")
                    TextField(handToSomeone ? "A city, like Santa Fe, NM" : "A city and a public place, like a café", text: $whereText)
                        .textFieldStyle(HerdFieldStyle())
                    Text("Please never use a home address. We only ever show a place name and city, never a street address.")
                        .font(.herdBody(13)).foregroundStyle(Herd.body)
                    Button {
                        locating = true
                        Task {
                            if let city = await location.currentCity() { whereText = city }
                            locating = false
                        }
                    } label: {
                        Label(locating ? "Finding your location…" : "Use my location", systemImage: "location")
                            .font(.herdBody(15)).foregroundStyle(Herd.mintInk)
                            .padding(.vertical, 10).padding(.horizontal, 16)
                            .background(Herd.mintSoft, in: Capsule())
                    }
                    .disabled(locating)
                }

                if !handToSomeone {
                    VStack(alignment: .leading, spacing: 10) {
                        FieldLabel(text: "How exact should the map be?")
                        ChoiceCard(title: "Public place", detail: "Shows the place name, like “café on the plaza, Santa Fe,” so the next person can find them.",
                                   isOn: publicPlace) { publicPlace = true }
                        ChoiceCard(title: "Just the city", detail: "Shows “Santa Fe, NM” only. Always used when you hand them to someone.",
                                   isOn: !publicPlace) { publicPlace = false }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    FieldLabel(text: "Add a photo (optional)")
                    photoPicker(selection: $photo, image: $photoImage, prompt: "A photo from your time together, or their new spot", tint: Color(hex: "8FAA9B"))
                    Label("We remove the hidden location data from photos, so only the spot you choose above is shared.", systemImage: "lock")
                        .font(.herdBody(13)).foregroundStyle(Herd.body)
                    Toggle("It’s OK for The Herd to share my photo on their website and Instagram, with credit.", isOn: $shareOK)
                        .font(.herdBody(15)).foregroundStyle(Herd.ink).tint(Herd.sageDark)
                }

                VStack(alignment: .leading, spacing: 8) {
                    FieldLabel(text: "Add your chapter to their story")
                    TextField("Where did you go together? Who are you passing them to, and why?", text: $chapter, axis: .vertical)
                        .lineLimit(4...8)
                        .textFieldStyle(HerdFieldStyle())
                }

                if let c, !c.wishGranted {
                    wishSection(c)
                }

                VStack(alignment: .leading, spacing: 8) {
                    FieldLabel(text: "Your name or nickname *")
                    TextField("Shown on their page", text: $nickname).textFieldStyle(HerdFieldStyle())
                }

                VStack(alignment: .leading, spacing: 8) {
                    FieldLabel(text: "Email (optional)")
                    TextField("you@email.com", text: $email)
                        .textFieldStyle(HerdFieldStyle())
                        .keyboardType(.emailAddress).textContentType(.emailAddress).textInputAutocapitalization(.never)
                    Text("Optional. Your stamps are always saved in the app. Never shown publicly.").font(.herdBody(13)).foregroundStyle(Herd.body)
                    Toggle("Alert me each time #\(number) moves", isOn: $alertMe).font(.herdBody(15)).foregroundStyle(Herd.ink).tint(Herd.sageDark)
                }

                Text("Your sighting shows up right away. Photos and new wishes appear after a quick look, usually within a few days. Your new stamps appear in your Passport after that review.")
                    .font(.herdBody(14)).foregroundStyle(Herd.pinkInk)
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Herd.pinkSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button("Send them on their way →") { submit() }
                    .buttonStyle(.herdPrimary)
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)
            }
            .padding(20)
        }
        .herdBackground()
        .herdTitle("Pass them on")
        .onAppear { if nickname.isEmpty { nickname = model.nickname } }
    }

    private func wishSection(_ c: Companion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Did you grant their wish?", systemImage: "star.fill")
                .font(.herdBody(16, weight: .semibold)).foregroundStyle(Color(hex: "4F4320"))
            Text("“\(c.wishSentence)”").font(.script(24)).foregroundStyle(Color(hex: "4F4320"))
            ChoiceCard(title: "Yes, we did it!", detail: "Add a photo of the moment below. You’ll choose their next wish and earn a Wish Granted stamp.",
                       isOn: grantedWish) { grantedWish = true }
            ChoiceCard(title: "Not this time", detail: "That’s okay. The next traveler can try.", isOn: !grantedWish) { grantedWish = false }
            if grantedWish {
                Text("A photo of the wish coming true *").font(.herdBody(15, weight: .semibold)).foregroundStyle(Color(hex: "4F4320"))
                photoPicker(selection: $wishPhoto, image: $wishImage, prompt: "Add the photo", tint: Herd.gold)
                Text("Required for the Wish Granted stamp. It’s added once we see your photo.").font(.herdBody(13)).foregroundStyle(Herd.butterInk)
            }
        }
        .padding(16)
        .background(Herd.butter, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func photoPicker(selection: Binding<PhotosPickerItem?>, image: Binding<Image?>, prompt: String, tint: Color) -> some View {
        PhotosPicker(selection: selection, matching: .images, photoLibrary: .shared()) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Herd.beige)
                RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(tint, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                if let img = image.wrappedValue {
                    img.resizable().scaledToFill().clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)).padding(4)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "camera").font(.system(size: 24))
                        Text(prompt).font(.herdBody(14)).multilineTextAlignment(.center)
                    }
                    .foregroundStyle(Herd.ink).padding(.horizontal, 16)
                }
            }
            .frame(height: image.wrappedValue == nil ? 120 : 200)
            .clipped()
        }
        .onChange(of: selection.wrappedValue) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self), let ui = UIImage(data: data) {
                    image.wrappedValue = Image(uiImage: ui)
                }
            }
        }
    }

    private func submit() {
        let trimmed = whereText.trimmingCharacters(in: .whitespaces)
        var city = trimmed
        var place: String? = nil
        if !handToSomeone && publicPlace, let comma = trimmed.firstIndex(of: ",") {
            place = String(trimmed[..<comma])
            city = String(trimmed[trimmed.index(after: comma)...]).trimmingCharacters(in: .whitespaces)
        }
        model.passOn(number, city: city, place: place, handedToSomeone: handToSomeone, chapter: chapter, nickname: nickname, grantedWish: grantedWish)
        if alertMe { model.following.insert(number) }
        if !email.isEmpty { model.email = email }
        router.replaceTop(with: grantedWish ? .wish(number) : .sent(number))
    }
}
