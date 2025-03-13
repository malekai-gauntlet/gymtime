import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?
    
    private override init() {
        super.init()
        print("📍 LocationManager: Initializing...")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        print("📍 LocationManager: Initial auth status: \(locationManager.authorizationStatus.rawValue)")
    }
    
    func requestLocationPermission() {
        print("📍 LocationManager: Requesting location permission...")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func getLastLocation() -> CLLocation? {
        print("📍 LocationManager: Getting last location: \(String(describing: lastLocation))")
        return lastLocation
    }
    
    // Convert location to address string using async/await
    func getLocationString() async -> String? {
        print("📍 LocationManager: Starting location string conversion...")
        
        guard let location = lastLocation else {
            print("❌ LocationManager: No last location available")
            return nil
        }
        
        print("📍 LocationManager: Last location found - Lat: \(location.coordinate.latitude), Long: \(location.coordinate.longitude)")
        
        let geocoder = CLGeocoder()
        print("📍 LocationManager: Starting reverse geocoding...")
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            guard let placemark = placemarks.first else {
                print("❌ LocationManager: No placemarks found")
                return nil
            }
            
            print("📍 LocationManager: Placemark found:")
            print("   Name: \(placemark.name ?? "nil")")
            print("   Thoroughfare: \(placemark.thoroughfare ?? "nil")")
            print("   Locality: \(placemark.locality ?? "nil")")
            print("   Administrative Area: \(placemark.administrativeArea ?? "nil")")
            print("   Country: \(placemark.country ?? "nil")")
            
            // Build the full address string
            var addressComponents: [String] = []
            
            // Add street address if available
            if let street = placemark.thoroughfare ?? placemark.name {
                addressComponents.append(street)
            }
            
            // Add city, state, and country if available
            var locationComponents: [String] = []
            if let city = placemark.locality {
                locationComponents.append(city)
            }
            if let state = placemark.administrativeArea {
                locationComponents.append(state)
            }
            if let country = placemark.country {
                locationComponents.append(country)
            }
            
            // Add the combined location components if we have any
            if !locationComponents.isEmpty {
                addressComponents.append(locationComponents.joined(separator: ", "))
            }
            
            // Join components with comma
            let fullAddress = addressComponents.joined(separator: ", ")
            print("✅ LocationManager: Generated full address: \(fullAddress)")
            return fullAddress
            
        } catch {
            print("❌ LocationManager: Geocoding error: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("📍 LocationManager: Authorization changed to: \(manager.authorizationStatus.rawValue)")
        locationStatus = manager.authorizationStatus
        
        if manager.authorizationStatus == .authorizedWhenInUse {
            print("📍 LocationManager: Authorized! Starting location updates...")
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("📍 LocationManager: Location updated - Lat: \(location.coordinate.latitude), Long: \(location.coordinate.longitude)")
        lastLocation = location
        locationManager.stopUpdatingLocation()
        print("📍 LocationManager: Stopped location updates")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ LocationManager: Failed to get location: \(error.localizedDescription)")
    }
} 