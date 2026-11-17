import SwiftUI

// How it works, where to pass one on, places to avoid, wishes and stamps, Instagram.
struct LearnView: View {
    @Environment(Router.self) private var router

    private let steps: [(String, String, Color, String)] = [
        ("Find one", "magnifyingglass", Herd.pink, "Spot a little clay Companion on a shelf, a windowsill or a café table."),
        ("Meet them", "qrcode.viewfinder", Herd.mintSoft, "Scan the code on their bottom to see their number, wish and journey."),
        ("Travel together", "mappin.and.ellipse", Herd.butter, "Carry them a while, help their wish come true, and add your chapter."),
        ("Pass them on", "arrow.triangle.turn.up.right.circle", Color(hex: "E7ECE5"), "Hand them to a fellow traveler or leave them somewhere new, then log the spot.")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: "Art in Transit · Children of the clay")
                    Text("Find one. Carry one. Watch them go.").font(.script(38, relativeTo: .largeTitle)).foregroundStyle(Herd.heading)
                    Text("Companions are tiny travelers handmade by The Herd. Every traveler they meet becomes part of their story.")
                        .font(.herdBody(16)).foregroundStyle(Herd.body)
                }

                ForEach(steps, id: \.0) { step in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: step.1).font(.system(size: 20)).foregroundStyle(Herd.ink)
                            .frame(width: 52, height: 52).background(step.2, in: Blob(variant: step.0.count))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.0).font(.chunky(18, extraBold: false)).foregroundStyle(Herd.sageDark)
                            Text(step.3).font(.herdBody(15)).foregroundStyle(Herd.ink)
                        }
                    }
                }

                Text("How to pass one on").font(.script(32)).foregroundStyle(Herd.heading)
                Card(background: Herd.beige) {
                    Text("Best of all: hand them on").font(.chunky(18, extraBold: false)).foregroundStyle(Herd.ink)
                    Text("Give your Companion to a fellow traveler: a new friend, a host, someone heading somewhere fun.").font(.herdBody(15)).foregroundStyle(Herd.body)
                }
                Card(background: Herd.mintSoft) {
                    Text("Or leave them somewhere").font(.chunky(18, extraBold: false)).foregroundStyle(Herd.mintInk)
                    Text("Cafés, hostels, hotel lobbies, bookstores, libraries, or near a monument.").font(.herdBody(15)).foregroundStyle(Herd.mintInk)
                }
                Card(background: Herd.pinkSoft) {
                    Text("Please don’t").font(.chunky(18, extraBold: false)).foregroundStyle(Herd.pinkInk)
                    Text("Airport security areas, trails and parks (leave no trace), private property, or anywhere they could fall or block a path.")
                        .font(.herdBody(15)).foregroundStyle(Herd.pinkInk)
                }
                Card(background: Herd.butter) {
                    Text("Wishes and stamps").font(.chunky(18, extraBold: false)).foregroundStyle(Herd.butterInk)
                    Text("Every Companion carries a wish. Pass one on to earn a stamp in your Passport, and grant their wish to earn a special Wish Granted stamp. Stamps are yours to keep.")
                        .font(.herdBody(15)).foregroundStyle(Herd.butterInk)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Share on Instagram").font(.script(30)).foregroundStyle(Herd.heading)
                    Text("Add @growtheherdstudio as a collaborator on your post, or mention us in your story, and use #TheHerdCompanions.")
                        .font(.herdBody(15)).foregroundStyle(Herd.ink)
                    Link("Follow @growtheherdstudio", destination: URL(string: "https://www.instagram.com/growtheherdstudio/")!)
                        .buttonStyle(.herdSoft)
                }

                Text("No app needed to take part. Anyone can scan a Companion with their phone camera.")
                    .font(.herdBody(14)).foregroundStyle(Herd.body)
            }
            .padding(20)
        }
        .herdBackground()
        .herdTitle("How it works")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.showLanguage = true } label: { Image(systemName: "globe") }
                    .accessibilityLabel("Language")
            }
        }
    }
}

// Save your Passport: optional email sign-in by link, no password.
struct SignInView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var sent = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if sent {
                        Image(systemName: "envelope").font(.system(size: 40)).foregroundStyle(Herd.butterInk)
                            .frame(width: 120, height: 110).background(Herd.butter, in: Blob())
                        Text("Check your email").font(.script(38)).foregroundStyle(Herd.heading)
                        Text("We sent a link to \(email). Tap it on this phone and you’re in. Your stamps are saved.")
                            .font(.herdBody(16)).foregroundStyle(Herd.body).multilineTextAlignment(.center)
                        Button("Use a different email") { sent = false }.font(.herdBody(15)).foregroundStyle(Herd.sageDark)
                        Button("Done") { dismiss() }.buttonStyle(.herdPrimary)
                    } else {
                        Image(systemName: "book.closed").font(.system(size: 40)).foregroundStyle(Herd.ink)
                            .frame(width: 120, height: 110).background(Herd.mintSoft, in: Blob())
                        Text("Keep your stamps safe").font(.script(38)).foregroundStyle(Herd.heading)
                        Text("Right now your Passport and stamps live only on this phone. Add your email to keep them if you change phones, and to see them on the website too.")
                            .font(.herdBody(16)).foregroundStyle(Herd.body).multilineTextAlignment(.center)
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel(text: "Your email")
                            TextField("you@email.com", text: $email)
                                .textFieldStyle(HerdFieldStyle())
                                .keyboardType(.emailAddress).textContentType(.emailAddress).textInputAutocapitalization(.never)
                        }
                        Button("Email me a sign-in link") {
                            model.email = email
                            withAnimation { sent = true }
                        }
                        .buttonStyle(.herdPrimary)
                        .disabled(!email.contains("@"))
                        .opacity(email.contains("@") ? 1 : 0.5)
                        VStack(alignment: .leading, spacing: 8) {
                            Label("No password to remember, ever", systemImage: "checkmark")
                            Label("Never shown publicly or shared", systemImage: "checkmark")
                            Label("Optional: finding and passing on never need it", systemImage: "checkmark")
                        }
                        .font(.herdBody(14)).foregroundStyle(Herd.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Button("Not now") { dismiss() }.font(.herdBody(15)).foregroundStyle(Herd.sageDark)
                    }
                }
                .padding(22)
            }
            .herdBackground()
            .herdTitle("Save your Passport")
        }
    }
}

// Choose a language. Travelers' own chapters and chat stay in the language they were written in.
struct LanguageView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    private let languages = [("en", "English", "English"), ("es", "Español", "Spanish"), ("fr", "Français", "French"), ("ja", "日本語", "Japanese")]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose your language").font(.script(32)).foregroundStyle(Herd.heading)
                ForEach(languages, id: \.0) { lang in
                    Button {
                        model.language = lang.0
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.1).font(.herdBody(17, weight: .medium)).foregroundStyle(Herd.ink)
                                Text(lang.2).font(.herdBody(13)).foregroundStyle(Herd.body)
                            }
                            Spacer()
                            Image(systemName: model.language == lang.0 ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22)).foregroundStyle(model.language == lang.0 ? Herd.sageDark : Herd.border)
                        }
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(model.language == lang.0 ? Herd.sageDark : Herd.border, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(model.language == lang.0 ? .isSelected : [])
                }
                Text("Travelers’ chapters and chat messages stay in the language they were written in.")
                    .font(.herdBody(13)).foregroundStyle(Herd.body)
                Spacer()
            }
            .padding(20)
            .herdBackground()
            .herdTitle("Language")
        }
    }
}

// Notification settings (the slider button on Activity).
struct NotificationSettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                Toggle("A Companion I’ve carried moves", isOn: $model.notificationPrefs.carriedMoves)
                Toggle("A Companion I follow moves", isOn: $model.notificationPrefs.followedMoves)
                Toggle("A wish is granted", isOn: $model.notificationPrefs.wishesGranted)
                Toggle("Someone replies to me in a chat", isOn: $model.notificationPrefs.chatReplies)
                Toggle("New stamps in my Passport", isOn: $model.notificationPrefs.newStamps)
                Toggle("The one-month reminder to pass a Companion on", isOn: $model.notificationPrefs.monthlyReminder)
            } header: {
                Text("Tell me when")
            }
            Section {
                Toggle("Also send these by email", isOn: $model.notificationPrefs.byEmail)
                    .disabled(model.email == nil)
                Toggle("Quiet hours (10pm – 8am)", isOn: $model.notificationPrefs.quietHours)
            } header: {
                Text("How")
            } footer: {
                Text(model.email == nil ? "Add your email in Passport to get emails too." : "Emails go to \(model.email ?? "").")
            }
            Section {
                Button("Delete my data", role: .destructive) {
                    model.email = nil
                    model.nickname = ""
                }
            } footer: {
                Text("Removes your email and nickname from The Herd. Your chapters stay on the Companions’ pages without your name.")
            }
        }
        .font(.herdBody(15))
        .tint(Herd.sageDark)
        .scrollContentBackground(.hidden)
        .herdBackground()
        .herdTitle("Notifications")
    }
}
