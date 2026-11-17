import CoreLocation

// "Use my city": asks once for location, then turns it into a city name only (never a street address).
final class LocationHelper: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @MainActor private var continuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    @MainActor func currentCity() async -> String? {
        guard let location = await requestLocation() else { return nil }
        let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location)
        guard let place = placemarks?.first else { return nil }
        let city = place.locality ?? place.subAdministrativeArea ?? place.name ?? ""
        let region = place.isoCountryCode == "US" ? (place.administrativeArea ?? "") : (place.country ?? "")
        return [city, region].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    @MainActor private func requestLocation() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            default:
                finish(nil)
            }
        }
    }

    @MainActor private func finish(_ location: CLLocation?) {
        continuation?.resume(returning: location)
        continuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                if self.continuation != nil { manager.requestLocation() }
            case .denied, .restricted:
                self.finish(nil)
            default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in self.finish(locations.last) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish(nil) }
    }
}
