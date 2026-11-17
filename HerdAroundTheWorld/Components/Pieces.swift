import SwiftUI

// A Passport stamp: a round, slightly tilted stamp with a big word and a small word.
struct StampView: View {
    let stamp: Stamp
    var size: CGFloat = 96

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(Color(hex: stamp.background))
                Circle()
                    .strokeBorder(Color(hex: stamp.ring), style: StrokeStyle(lineWidth: 3, dash: stamp.isEmpty ? [5, 4] : []))
                VStack(spacing: 0) {
                    Text(stamp.big).font(.chunky(size * 0.24))
                    Text(stamp.small.uppercased())
                        .font(.herdBody(size * 0.1, relativeTo: .caption2))
                        .tracking(1)
                }
                .foregroundStyle(Color(hex: stamp.ink))
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(stamp.tilt))

            Text(stamp.label)
                .font(.herdBody(13, relativeTo: .caption))
                .foregroundStyle(Herd.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stamp.isEmpty ? "Empty stamp: \(stamp.label)" : "Stamp: \(stamp.label)")
    }
}

// Filter pill used on the map (same colours as the website map).
struct FilterChip: View {
    let filter: MapFilter
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let dot = filter.dot {
                    Circle().fill(Color(hex: dot)).frame(width: 8, height: 8)
                }
                Text(filter.label)
            }
            .font(.herdBody(14, relativeTo: .subheadline))
            .foregroundStyle(isOn ? Color.white : Color(hex: filter.foreground))
            .padding(.vertical, 9)
            .padding(.horizontal, 14)
            .background(isOn ? Herd.sageDark : Color(hex: filter.background), in: Capsule())
            .shadow(color: Herd.ink.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

// Small rounded info pill ("6 stops", "Last seen in Santa Fe").
struct InfoPill: View {
    let text: String
    var background: Color = Herd.cream
    var foreground: Color = Herd.ink

    var body: some View {
        Text(text)
            .font(.herdBody(14, relativeTo: .footnote))
            .foregroundStyle(foreground)
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .background(background, in: Capsule())
    }
}

// Wish card: yellow card with a star and the wish in handwriting.
struct WishCard: View {
    let wish: String
    var granted: Bool = false
    var note: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 22))
                .foregroundStyle(Herd.gold)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Eyebrow(text: granted ? "Their wish · granted!" : "Their wish · not granted yet", color: Herd.butterInk)
                Text("“\(wish)”")
                    .font(.script(26))
                    .foregroundStyle(Color(hex: "4F4320"))
                if let note {
                    Text(note)
                        .font(.herdBody(14))
                        .foregroundStyle(Herd.butterInk)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Herd.butter, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// Numbered step row ("1  Take me along for a while…").
struct NumberedRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.chunky(15, extraBold: false))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Color(hex: "8FAA9B"), in: Circle())
                .accessibilityHidden(true)
            Text(text)
                .font(.herdBody(15))
                .foregroundStyle(Herd.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// Segmented choice (App alert / Email / No thanks).
struct PillPicker<Value: Hashable>: View {
    let options: [(Value, String)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.0) { option in
                Button {
                    selection = option.0
                } label: {
                    Text(option.1)
                        .font(.herdBody(14, weight: .medium))
                        .foregroundStyle(selection == option.0 ? Color.white : Herd.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == option.0 ? Herd.sageDark : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == option.0 ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Herd.field, in: Capsule())
    }
}

// Radio-style option card (Handing them to someone / Leaving them somewhere).
struct ChoiceCard: View {
    let title: String
    let detail: String
    var badge: String? = nil
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isOn ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(Herd.sageDark)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title).font(.herdBody(16, weight: .medium)).foregroundStyle(Herd.ink)
                        if let badge {
                            Text(badge)
                                .font(.herdBody(12, relativeTo: .caption))
                                .foregroundStyle(Herd.mintInk)
                                .padding(.vertical, 3).padding(.horizontal, 8)
                                .background(Herd.mintSoft, in: Capsule())
                        }
                    }
                    Text(detail)
                        .font(.herdBody(14))
                        .foregroundStyle(Herd.body)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isOn ? Herd.sageDark : Herd.border, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

// Header used on pushed screens: back is handled by the navigation bar, so this just centres the wordmark.
struct HerdNavigationTitle: ViewModifier {
    var title: String? = nil

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if let title {
                        Text(title).font(.chunky(17, extraBold: false)).foregroundStyle(Herd.ink)
                    } else {
                        Wordmark()
                    }
                }
            }
            .toolbarBackground(Herd.cream, for: .navigationBar)
    }
}

extension View {
    func herdTitle(_ title: String? = nil) -> some View {
        modifier(HerdNavigationTitle(title: title))
    }

    // The cream page background used on every screen.
    func herdBackground() -> some View {
        background(Herd.cream.ignoresSafeArea())
    }
}

// Placeholder for traveler photos (until real photos come from the server).
struct PhotoPlaceholder: View {
    var label: String = "Traveler’s photo"
    var color: Color = Herd.sageBackground
    var height: CGFloat = 120

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(color)
            VStack(spacing: 6) {
                Image(systemName: "camera").font(.system(size: 20))
                Text(label).font(.herdBody(13, relativeTo: .caption))
            }
            .foregroundStyle(Herd.body)
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}
