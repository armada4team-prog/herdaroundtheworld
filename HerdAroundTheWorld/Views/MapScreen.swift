import SwiftUI
import MapKit

// World map: one dot per Companion. Tap a dot (or a row in Most active) to zoom to their journey.
struct MapScreen: View {
    @Environment(AppModel.self) private var model
    @Environment(Router.self) private var router
    @State private var filter: MapFilter = .all
    @State private var selected: String? = nil
    @State private var position: MapCameraPosition = .automatic
    @State private var search = ""

    private var visible: [Companion] { model.companions.filter { model.matches($0, filter: filter) } }
    private var selectedCompanion: Companion? { selected.flatMap { model.companion($0) } }

    var body: some View {
        ZStack(alignment: .top) {
            map
            VStack(alignment: .leading, spacing: 10) {
                searchBar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MapFilter.allCases) { f in
                            FilterChip(filter: f, isOn: filter == f) { filter = f; clearSelection() }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 2)
                }
                .padding(.horizontal, -16)
                HStack {
                    if selected != nil {
                        Button { clearSelection() } label: {
                            Label("Whole world", systemImage: "arrow.down.right.and.arrow.up.left")
                                .font(.herdBody(14)).foregroundStyle(Herd.ink)
                                .padding(.vertical, 9).padding(.horizontal, 14)
                                .background(Herd.cream, in: Capsule())
                                .shadow(color: Herd.ink.opacity(0.12), radius: 6, y: 3)
                        }
                    }
                    Spacer()
                    Text("\(visible.count) Companions")
                        .font(.herdBody(12, relativeTo: .caption)).foregroundStyle(Herd.ink)
                        .padding(.vertical, 7).padding(.horizontal, 12)
                        .background(Herd.cream, in: Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .safeAreaInset(edge: .bottom) { bottomCard }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var map: some View {
        Map(position: $position, selection: $selected) {
            if let c = selectedCompanion {
                MapPolyline(coordinates: c.stops.map(\.coordinate))
                    .stroke(c.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 7]))
                ForEach(c.stops.dropLast()) { stop in
                    Annotation("", coordinate: stop.coordinate) {
                        Circle().fill(c.accentColor.opacity(0.6)).frame(width: 9, height: 9)
                            .overlay(Circle().strokeBorder(Herd.cream, lineWidth: 1.5))
                    }
                }
            }
            ForEach(visible) { c in
                if let now = c.current {
                    Annotation(c.number == selected ? "#\(c.number) · now" : "", coordinate: now.coordinate) {
                        Circle()
                            .fill(c.accentColor)
                            .frame(width: c.number == selected ? 18 : 12, height: c.number == selected ? 18 : 12)
                            .overlay(Circle().strokeBorder(Herd.cream, lineWidth: 2))
                            .accessibilityLabel("Companion #\(c.number), \(now.city)")
                    }
                    .tag(c.number)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .onChange(of: selected) { _, number in
            guard let number, let c = model.companion(number) else { return }
            withAnimation(.easeInOut) { position = .region(region(for: c.stops.map(\.coordinate))) }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Herd.sageDark)
            TextField("Find a Companion: #07", text: $search)
                .font(.herdBody(16))
                .keyboardType(.numberPad)
                .submitLabel(.search)
                .onSubmit(find)
            if !search.isEmpty {
                Button("Go", action: find).font(.herdBody(15, weight: .medium))
            }
        }
        .padding(.horizontal, 16).frame(height: 50)
        .background(Herd.cream, in: Capsule())
        .shadow(color: Herd.ink.opacity(0.12), radius: 8, y: 4)
    }

    private func find() {
        guard let c = model.companion(search) else { return }
        filter = .all
        selected = c.number
        search = ""
    }

    private func clearSelection() {
        selected = nil
        withAnimation(.easeInOut) { position = .automatic }
    }

    @ViewBuilder private var bottomCard: some View {
        if let c = selectedCompanion {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    CompanionBadge(companion: c, size: 52)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.label).font(.chunky(18, extraBold: false)).foregroundStyle(Herd.sageDark)
                        Text("\(c.current?.city ?? "") · \(c.lastMoved)").font(.herdBody(13)).foregroundStyle(Herd.body)
                        Text("Wish: \(c.wish)").font(.herdBody(13)).foregroundStyle(Herd.butterInk)
                    }
                    Spacer()
                }
                HStack(spacing: 8) {
                    legendDot(c.accentColor.opacity(0.6), "Where they’ve been")
                    legendDot(c.accentColor, "Where #\(c.number) is now")
                }
                Button("Open their page") { router.push(.companion(c.number, showHello: false)) }
                    .buttonStyle(.herdPrimary)
            }
            .padding(16)
            .background(Herd.cream, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: Herd.ink.opacity(0.18), radius: 12, y: 6)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Capsule().fill(Color(hex: "DCDDD6")).frame(width: 40, height: 5).frame(maxWidth: .infinity)
                HStack(alignment: .firstTextBaseline) {
                    Text("Most active").font(.script(26)).foregroundStyle(Herd.heading)
                    Spacer()
                    Text("\(model.companions.count) Companions").font(.herdBody(12, relativeTo: .caption)).foregroundStyle(Herd.body)
                }
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(model.mostActive.enumerated()), id: \.element.id) { index, c in
                            Button { filter = .all; selected = c.number } label: {
                                HStack(spacing: 10) {
                                    Text("\(index + 1)").font(.chunky(13, extraBold: false)).foregroundStyle(Herd.sage).frame(width: 20)
                                    Circle().fill(c.accentColor).frame(width: 10, height: 10)
                                    Text("#\(c.number)").font(.chunky(14, extraBold: false)).foregroundStyle(Herd.sageDark)
                                    Text(c.current?.city ?? "").font(.herdBody(14)).foregroundStyle(Herd.ink)
                                    Spacer()
                                    Text("\(c.stopCount) stops").font(.herdBody(12, relativeTo: .caption)).foregroundStyle(Herd.body)
                                }
                                .padding(.vertical, 9)
                            }
                            .buttonStyle(.plain)
                            Divider().overlay(Herd.line)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 8)
            .background(Herd.cream, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: Herd.ink.opacity(0.18), radius: 12, y: 6)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private func legendDot(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(text).font(.herdBody(12, relativeTo: .caption)).foregroundStyle(Herd.ink)
        }
    }

    private func region(for coords: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard let first = coords.first else { return MKCoordinateRegion(.world) }
        var minLat = first.latitude, maxLat = first.latitude, minLon = first.longitude, maxLon = first.longitude
        for c in coords {
            minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * 1.6, 4), longitudeDelta: max((maxLon - minLon) * 1.4, 4))
        return MKCoordinateRegion(center: center, span: span)
    }
}
