import SwiftUI

// Activity tab: news about your Companions, plus the one gentle reminder.
struct ActivityView: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Wordmark()
                    Spacer()
                    Button { router.push(.notificationSettings) } label: {
                        Image(systemName: "slider.horizontal.3")
                            .frame(width: 44, height: 44).background(Herd.mintSoft, in: Circle())
                    }
                    .foregroundStyle(Herd.mintInk)
                    .accessibilityLabel("Notification settings")
                }
                Text("Activity").font(.script(40, relativeTo: .largeTitle)).foregroundStyle(Herd.heading)

                if let number = model.reminderFrom, let c = model.companion(number) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("From \(c.displayName)", systemImage: "circle.fill")
                            .font(.herdBody(12, relativeTo: .caption))
                            .foregroundStyle(Herd.pinkInk)
                            .labelStyle(DotLabelStyle())
                        Text("Hi again! You found me in \(c.current?.city ?? "your city") about a month ago. Ready to send me on my next adventure?")
                            .font(.herdBody(15)).foregroundStyle(Herd.ink)
                        HStack(spacing: 10) {
                            Button("Pass me on") { router.push(.passOn(c.number)) }.buttonStyle(.herdPrimary)
                            Button("Still traveling") { model.reminderFrom = nil }.buttonStyle(.herdOutline)
                        }
                    }
                    .padding(16)
                    .background(Herd.pinkSoft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                section("Today", items: model.activity.filter(\.isToday))
                section("This week", items: model.activity.filter { !$0.isToday })
            }
            .padding(20)
        }
        .herdBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func section(_ title: String, items: [ActivityItem]) -> some View {
        if !items.isEmpty {
            Eyebrow(text: title)
            ForEach(items) { item in
                Button {
                    if let route = item.route { router.push(route) } else { router.tab = .passport }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.symbol)
                            .foregroundStyle(Color(hex: item.foreground))
                            .frame(width: 40, height: 40)
                            .background(Color(hex: item.background), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.herdBody(15, weight: .medium)).foregroundStyle(Herd.ink).multilineTextAlignment(.leading)
                            Text(item.meta).font(.herdBody(13)).foregroundStyle(Herd.body).multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct DotLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.font(.system(size: 6))
            configuration.title
        }
    }
}
