import SwiftUI

// Welcome: a bouncing, twirling Companion. Tap them to come in.
struct SplashView: View {
    let onEnter: () -> Void
    @State private var bouncing = false
    @State private var spin = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Herd.cream.ignoresSafeArea()
            Blob(variant: 1).fill(Herd.pink).frame(width: 150, height: 170).offset(x: -170, y: -260)
            Blob(variant: 2).fill(Herd.butter).frame(width: 140, height: 140).offset(x: 170, y: -180)
            Blob(variant: 3).fill(Herd.mintSoft).frame(width: 200, height: 160).offset(x: 150, y: 320)

            VStack(spacing: 18) {
                Wordmark()
                Spacer()
                Button(action: onEnter) {
                    VStack(spacing: 14) {
                        ZStack(alignment: .bottom) {
                            Blob().fill(Herd.mintSoft).frame(width: 230, height: 220)
                            CompanionFigure(glaze: Herd.mint, waving: true, happy: true, showsShadow: true)
                                .frame(height: 170)
                                .offset(y: bouncing ? -26 : 0)
                                .rotation3DEffect(.degrees(spin), axis: (x: 0, y: 1, z: 0))
                                .padding(.bottom, 18)
                        }
                        Text("Tap me to say hi!")
                            .font(.herdBody(15, weight: .medium))
                            .foregroundStyle(Herd.sageDark)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Say hi and come in")
                Spacer()
                VStack(spacing: 6) {
                    Text("Herd Around the World")
                        .font(.script(40, relativeTo: .largeTitle))
                        .foregroundStyle(Herd.heading)
                    Text("Children of the clay, on the move")
                        .font(.herdBody(16))
                        .foregroundStyle(Herd.body)
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 30)
            }
            .padding(.top, 20)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { bouncing = true }
            withAnimation(.linear(duration: 3.2).repeatForever(autoreverses: false)) { spin = 360 }
        }
    }
}
