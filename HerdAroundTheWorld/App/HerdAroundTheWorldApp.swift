import SwiftUI

@main
struct HerdAroundTheWorldApp: App {
    @State private var model = AppModel()
    @State private var router = Router()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                if showSplash {
                    SplashView { withAnimation(.easeInOut(duration: 0.35)) { showSplash = false } }
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .environment(model)
            .environment(router)
            .tint(Herd.sageDark)
            .onAppear(perform: openScreenFromLaunchArguments)
            .onOpenURL { url in
                // A scanned QR code (theherdstudio.com/c/07) opens that Companion's page with the hello card.
                if let number = AppModel.number(fromScan: url.absoluteString) {
                    showSplash = false
                    router.open(.companion(number, showHello: true), in: .scan)
                }
            }
        }
    }

    // Used by the automatic screenshot run on GitHub: `-uiScreen map` opens straight to that screen.
    // Normal launches don't pass this, so they start on the welcome screen as usual.
    private func openScreenFromLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-uiScreen"), i + 1 < args.count else { return }
        let screen = args[i + 1]
        showSplash = screen == "splash"
        switch screen {
        case "map": router.tab = .map
        case "scan": router.tab = .scan
        case "passport": router.tab = .passport
        case "activity": router.tab = .activity
        case "companion": router.open(.companion("07", showHello: false), in: .home)
        case "hello": router.open(.companion("07", showHello: true), in: .home)
        case "found": router.open(.found("07"), in: .home)
        case "passon": router.open(.passOn("07"), in: .home)
        case "wish": router.open(.wish("07"), in: .home)
        case "sent": router.open(.sent("07"), in: .home)
        case "broke": router.open(.broke("07"), in: .home)
        case "chat": router.open(.chat("07"), in: .home)
        case "story": router.open(.story("07"), in: .home)
        case "learn": router.open(.learn, in: .home)
        case "settings": router.open(.notificationSettings, in: .activity)
        case "signin": router.tab = .passport; router.showSignIn = true
        case "language": router.showLanguage = true
        default: router.tab = .home
        }
    }
}

// Five tabs, like the designs: The Herd · Map · Scan · Passport · Activity.
struct MainTabView: View {
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            tab(.home, title: "The Herd", symbol: "house") { HomeView() }
            tab(.map, title: "Map", symbol: "map") { MapScreen() }
            tab(.scan, title: "Scan", symbol: "qrcode.viewfinder") { ScanView() }
            tab(.passport, title: "Passport", symbol: "book.closed") { PassportView() }
            tab(.activity, title: "Activity", symbol: "bell") { ActivityView() }
        }
        .sheet(isPresented: $router.showSignIn) { SignInView() }
        .sheet(isPresented: $router.showLanguage) {
            LanguageView().presentationDetents([.fraction(0.72), .large])
        }
    }

    private func tab<Content: View>(_ tab: Router.Tab, title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack(path: router.path(for: tab)) {
            content()
                .navigationDestination(for: Route.self) { route in
                    RouteView(route: route)
                }
        }
        .tabItem { Label(title, systemImage: symbol) }
        .tag(tab)
    }
}

// Maps a Route to its screen.
struct RouteView: View {
    let route: Route

    var body: some View {
        switch route {
        case .companion(let number, let showHello): CompanionView(number: number, startWithHello: showHello)
        case .found(let number): FoundView(number: number)
        case .passOn(let number): PassOnView(number: number)
        case .wish(let number): WishView(number: number)
        case .sent(let number): SentView(number: number)
        case .broke(let number): BrokeView(number: number)
        case .chat(let number): ChatView(number: number)
        case .story(let number): StoryView(number: number)
        case .learn: LearnView()
        case .notificationSettings: NotificationSettingsView()
        }
    }
}
