import SwiftUI

// The Herd's colours, taken from the designs (cream + sage, pastel blobs).
extension Color {
    init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

enum Herd {
    static let cream = Color(hex: "FDF8F3")
    static let beige = Color(hex: "F6EFE7")
    static let field = Color(hex: "F1EAE3")
    static let sageBackground = Color(hex: "E7ECE5")
    static let sage = Color(hex: "6E8B7D")
    static let sageDark = Color(hex: "5B7869")
    static let ink = Color(hex: "3F5A4C")
    static let heading = Color(hex: "4F6B5D")
    static let body = Color(hex: "566E62")
    static let mint = Color(hex: "A8DCC9")
    static let mintSoft = Color(hex: "DDF0E8")
    static let mintInk = Color(hex: "2F4A3D")
    static let pink = Color(hex: "F6D3D3")
    static let pinkSoft = Color(hex: "FBE4E2")
    static let pinkInk = Color(hex: "6B3F3A")
    static let butter = Color(hex: "F9EBB5")
    static let butterInk = Color(hex: "5A4C1E")
    static let rose = Color(hex: "D98C86")
    static let gold = Color(hex: "E0B94A")
    static let line = Color(hex: "EDE6DC")
    static let border = Color(hex: "E3DCD2")
    static let blush = Color(hex: "F2B4B0")
}

// Fonts: Fira Sans (body), Shadows Into Light Two (handwritten headings), Baloo 2 (chunky numbers and labels).
// Each size scales with the reader's Dynamic Type setting.
extension Font {
    static func script(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom("ShadowsIntoLightTwo-Regular", size: size, relativeTo: style)
    }

    static func herdBody(_ size: CGFloat = 16, weight: HerdWeight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(weight.fontName, size: size, relativeTo: style)
    }

    static func chunky(_ size: CGFloat, extraBold: Bool = true, relativeTo style: Font.TextStyle = .headline) -> Font {
        .custom(extraBold ? "Baloo2-ExtraBold" : "Baloo2-Bold", size: size, relativeTo: style)
    }
}

enum HerdWeight {
    case regular, medium, semibold

    var fontName: String {
        switch self {
        case .regular: return "FiraSans-Regular"
        case .medium: return "FiraSans-Medium"
        case .semibold: return "FiraSans-SemiBold"
        }
    }
}

// Small uppercase label used above headings ("ART IN TRANSIT · NO. 07").
struct Eyebrow: View {
    let text: String
    var color: Color = Herd.sageDark

    var body: some View {
        Text(text.uppercased())
            .font(.herdBody(13, relativeTo: .caption))
            .tracking(1)
            .foregroundStyle(color)
    }
}

// Pill-shaped buttons from the designs.
struct HerdButtonStyle: ButtonStyle {
    enum Kind { case primary, soft, outline }
    var kind: Kind = .primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.herdBody(15, weight: .medium))
            .tracking(0.6)
            .textCase(.uppercase)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .foregroundStyle(foreground)
            .padding(.vertical, 16)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(background, in: Capsule())
            .overlay {
                if kind == .outline {
                    Capsule().strokeBorder(Herd.sageDark, lineWidth: 2)
                }
            }
            .opacity(configuration.isPressed ? 0.8 : 1)
            .contentShape(Capsule())
    }

    private var foreground: Color {
        switch kind {
        case .primary: return .white
        case .soft: return Herd.mintInk
        case .outline: return Herd.ink
        }
    }

    private var background: Color {
        switch kind {
        case .primary: return Herd.sageDark
        case .soft: return Herd.mint
        case .outline: return .clear
        }
    }
}

extension ButtonStyle where Self == HerdButtonStyle {
    static var herdPrimary: HerdButtonStyle { HerdButtonStyle(kind: .primary) }
    static var herdSoft: HerdButtonStyle { HerdButtonStyle(kind: .soft) }
    static var herdOutline: HerdButtonStyle { HerdButtonStyle(kind: .outline) }
}

// Rounded card used all over the designs.
struct Card<Content: View>: View {
    var background: Color = Herd.beige
    var padding: CGFloat = 16
    var corner: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { content }
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

// Text field look from the designs (beige fill, rounded).
struct HerdFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.herdBody(16))
            .foregroundStyle(Herd.ink)
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .background(Herd.field, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct FieldLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.herdBody(16, weight: .semibold))
            .foregroundStyle(Herd.sageDark)
    }
}

// "THE HERD" wordmark used in headers.
struct Wordmark: View {
    var body: some View {
        Text("THE HERD")
            .font(.chunky(22))
            .foregroundStyle(Herd.sageDark)
            .accessibilityLabel("The Herd")
    }
}
