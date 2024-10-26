//
//  ViewController.swift
//  NextStop
//
//  Created by Meirkhan Nishonov on 19.08.2024.
//

import UIKit
import MapKit
import CoreLocation
import UserNotifications

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    let map = MKMapView()
    let coordinate = CLLocationCoordinate2D(latitude: 40.728, longitude: -74)
    let manager = CLLocationManager()
    
    let pinImage: UIImage? = {
        guard let image = UIImage(named: "pin") else { return nil }
        let newSize = CGSize(width: 20, height: 30)  // Desired size
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }()
    
    let userLocationImage: UIImage? = UIImage(systemName: "location.circle.fill") // Custom user location icon
    
    var checherAnnotaion: Bool = false
    var AnnotationPinFirst = MKPointAnnotation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(map)
        map.frame = view.bounds
        map.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)), animated: false)
        map.delegate = self
        map.showsUserLocation = true // Enable user location
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        map.addGestureRecognizer(tapGesture)
        
        setupLocationButton()
        requestNotificationAuthorization()
    }
    
    @objc func handleTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        let touchLocation = gestureRecognizer.location(in: map)
        let locationCoordinate = map.convert(touchLocation, toCoordinateFrom: map)
        
        if checherAnnotaion {
            map.removeAnnotation(AnnotationPinFirst)
        }
        
        let pin = MKPointAnnotation()
        pin.coordinate = locationCoordinate
        pin.title = "Pinned location"
        pin.subtitle = "Created for testing"
        
        map.addAnnotation(pin)
        AnnotationPinFirst = pin
        checherAnnotaion = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func setupLocationButton() {
        let locationButton = UIButton(type: .system)
        locationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        locationButton.tintColor = .systemBlue
        locationButton.backgroundColor = .white
        locationButton.layer.cornerRadius = 25
        locationButton.layer.shadowColor = UIColor.black.cgColor
        locationButton.layer.shadowOpacity = 0.3
        locationButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        locationButton.layer.shadowRadius = 2
        
        locationButton.addTarget(self, action: #selector(centerMapOnUserLocation), for: .touchUpInside)
        
        locationButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(locationButton)
        
        NSLayoutConstraint.activate([
            locationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            locationButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            locationButton.widthAnchor.constraint(equalToConstant: 50),
            locationButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func centerMapOnUserLocation() {
        if let userLocation = manager.location {
            let region = MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            map.setRegion(region, animated: true)
        }
    }
    
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
        }
    }
    
    func sendProximityNotification() {
        let content = UNMutableNotificationContent()
        content.title = "You're near the pinned location!"
        content.body = "You are within 50 meters of your destination."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "ProximityNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            // Customize the user location view
            var userLocationView = map.dequeueReusableAnnotationView(withIdentifier: "userLocation") as? MKAnnotationView
            if userLocationView == nil {
                userLocationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "userLocation")
            }
            userLocationView?.image = userLocationImage
            return userLocationView
        }
        
        // Customize the pin annotation view
        var annotationView = map.dequeueReusableAnnotationView(withIdentifier: "custom")
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "custom")
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        annotationView?.image = pinImage
        return annotationView
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.first else { return }
        
        // Calculate distance to annotation
        if checherAnnotaion {
            let annotationLocation = CLLocation(latitude: AnnotationPinFirst.coordinate.latitude, longitude: AnnotationPinFirst.coordinate.longitude)
            let distance = userLocation.distance(from: annotationLocation)
            
            // Send notification if within 50 meters
            if distance <= 50 {
                sendProximityNotification()
            }
            
            // Show directions if annotation exists
            showDirections(to: AnnotationPinFirst.coordinate)
        }
    }
    
    func showDirections(to destination: CLLocationCoordinate2D) {
        guard let userLocation = manager.location else { return }
        
        let sourcePlacemark = MKPlacemark(coordinate: userLocation.coordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlacemark)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { response, error in
            guard let response = response, let route = response.routes.first else {
                print("Error calculating directions: \(String(describing: error))")
                return
            }
            
            self.map.removeOverlays(self.map.overlays)
            self.map.addOverlay(route.polyline, level: .aboveRoads)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.systemBlue
            renderer.lineWidth = 5.0
            return renderer
        }
        return MKOverlayRenderer()
    }
}
