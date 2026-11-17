import SwiftUI

// The little clay Companion from the designs: round head, rounded body, dot eyes, smile and blush.
// Drawn on a 60 × 80 grid, like the SVG in the designs.
struct CompanionFigure: View {
    var glaze: Color = Herd.mint
    var waving: Bool = false
    var happy: Bool = false
    var showsBlush: Bool = true
    var showsShadow: Bool = true

    var body: some View {
        Canvas { context, size in
            let s = min(size.width / 60, size.height / 80)
            let ox = (size.width - 60 * s) / 2
            let oy = (size.height - 80 * s) / 2
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
            func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: ox + x * s, y: oy + y * s, width: w * s, height: h * s)
            }
            let ink = Herd.ink

            if showsShadow {
                context.fill(Path(ellipseIn: r(12, 74.5, 36, 5)), with: .color(ink.opacity(0.14)))
            }

            // Body
            var body = Path()
            body.move(to: p(14, 46))
            body.addQuadCurve(to: p(30, 33), control: p(14, 33))
            body.addQuadCurve(to: p(46, 46), control: p(46, 33))
            body.addLine(to: p(46, 70))
            body.addQuadCurve(to: p(41, 75), control: p(46, 75))
            body.addLine(to: p(19, 75))
            body.addQuadCurve(to: p(14, 70), control: p(14, 75))
            body.closeSubpath()
            context.fill(body, with: .color(glaze))

            if waving {
                var arm = Path()
                arm.move(to: p(14, 44))
                arm.addQuadCurve(to: p(9, 27), control: p(6, 36))
                context.stroke(arm, with: .color(glaze), style: StrokeStyle(lineWidth: 6 * s, lineCap: .round))
            }

            // Head
            context.fill(Path(ellipseIn: r(16, 6, 28, 28)), with: .color(glaze))

            // Eyes
            if happy {
                var eyes = Path()
                eyes.move(to: p(23, 19)); eyes.addQuadCurve(to: p(27, 19), control: p(25, 16))
                eyes.move(to: p(33, 19)); eyes.addQuadCurve(to: p(37, 19), control: p(35, 16))
                context.stroke(eyes, with: .color(ink), style: StrokeStyle(lineWidth: 1.6 * s, lineCap: .round))
            } else {
                context.fill(Path(ellipseIn: r(23.2, 17.2, 3.6, 3.6)), with: .color(ink))
                context.fill(Path(ellipseIn: r(33.2, 17.2, 3.6, 3.6)), with: .color(ink))
            }

            // Smile (closed, so a happy open mouth has a full outline)
            var smile = Path()
            if happy {
                smile.move(to: p(24, 24))
                smile.addQuadCurve(to: p(36, 24), control: p(30, 31))
                smile.closeSubpath()
                context.fill(smile, with: .color(Herd.blush))
                context.stroke(smile, with: .color(ink), style: StrokeStyle(lineWidth: 1.6 * s, lineCap: .round, lineJoin: .round))
            } else {
                smile.move(to: p(26, 25))
                smile.addQuadCurve(to: p(34, 25), control: p(30, 28))
                context.stroke(smile, with: .color(ink), style: StrokeStyle(lineWidth: 1.5 * s, lineCap: .round))
            }

            if showsBlush {
                context.fill(Path(ellipseIn: r(18.8, 21.3, 4.4, 4.4)), with: .color(Herd.blush.opacity(0.8)))
                context.fill(Path(ellipseIn: r(36.8, 21.3, 4.4, 4.4)), with: .color(Herd.blush.opacity(0.8)))
            }
        }
        .aspectRatio(60 / 80, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

// Soft, lopsided "pebble" shape used behind figures and as decoration.
struct Blob: Shape {
    var variant: Int = 0

    func path(in rect: CGRect) -> Path {
        // Corner radii as fractions, echoing the CSS border-radius blobs in the designs.
        let sets: [[CGFloat]] = [
            [0.42, 0.58, 0.38, 0.62, 0.52, 0.40, 0.60, 0.48],
            [0.55, 0.45, 0.50, 0.50, 0.50, 0.60, 0.40, 0.50],
            [0.60, 0.40, 0.55, 0.45, 0.50, 0.60, 0.40, 0.50],
            [0.45, 0.55, 0.40, 0.60, 0.55, 0.45, 0.60, 0.40]
        ]
        let v = sets[abs(variant) % sets.count]
        let w = rect.width, h = rect.height
        let tl = CGSize(width: v[0] * w, height: v[4] * h)
        let tr = CGSize(width: v[1] * w, height: v[5] * h)
        let br = CGSize(width: v[2] * w, height: v[6] * h)
        let bl = CGSize(width: v[3] * w, height: v[7] * h)
        let k: CGFloat = 0.5523
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + tl.width, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - tr.width, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY + tr.height),
                   control1: CGPoint(x: rect.maxX - tr.width * (1 - k), y: rect.minY),
                   control2: CGPoint(x: rect.maxX, y: rect.minY + tr.height * (1 - k)))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br.height))
        p.addCurve(to: CGPoint(x: rect.maxX - br.width, y: rect.maxY),
                   control1: CGPoint(x: rect.maxX, y: rect.maxY - br.height * (1 - k)),
                   control2: CGPoint(x: rect.maxX - br.width * (1 - k), y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + bl.width, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.maxY - bl.height),
                   control1: CGPoint(x: rect.minX + bl.width * (1 - k), y: rect.maxY),
                   control2: CGPoint(x: rect.minX, y: rect.maxY - bl.height * (1 - k)))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl.height))
        p.addCurve(to: CGPoint(x: rect.minX + tl.width, y: rect.minY),
                   control1: CGPoint(x: rect.minX, y: rect.minY + tl.height * (1 - k)),
                   control2: CGPoint(x: rect.minX + tl.width * (1 - k), y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// A Companion standing in a soft blob, used on cards and headers.
struct CompanionBadge: View {
    let companion: Companion
    var size: CGFloat = 56
    var waving = false
    var happy = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Blob(variant: companion.number.count).fill(companion.blobColor)
            CompanionFigure(glaze: companion.glazeColor, waving: waving, happy: happy, showsShadow: false)
                .frame(height: size * 0.72)
                .padding(.bottom, size * 0.08)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
