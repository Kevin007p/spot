import Foundation
import CoreLocation

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        locationManager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func distance(to lat: Double, lng: Double) -> Double? {
        guard let userLocation else { return nil }
        let placeLocation = CLLocation(latitude: lat, longitude: lng)
        return userLocation.distance(from: placeLocation) / 1609.34 // meters to miles
    }
}
