//
//  ViewController.swift
//  NextStop
//
//  Created by Meirkhan Nishonov on 19.08.2024.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate  {
    
    let map = MKMapView()
    
    let coordinate = CLLocationCoordinate2D(latitude: 40.728, longitude: -74)
    
    let manager = CLLocationManager()
    
    let pinImage: UIImage? = {
        guard let image = UIImage(named: "pin") else { return nil }

        let newSize = CGSize(width: 20, height: 20)  // Desired size
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }()

    
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(map)
        map.frame = view.bounds
        
        map.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)), animated: false)
        
        map.delegate = self
        
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongTapGesture(_:)))

        map.addGestureRecognizer(longTapGesture)
        
        
//        addCustomPin()
        
        
    }
    @objc func handleLongTapGesture(_ gestureRecognizer: UILongPressGestureRecognizer){
        
        if gestureRecognizer.state != UIGestureRecognizer.State.ended{
            let touchLocation = gestureRecognizer.location(in: map)
            let locationCoordinate = map.convert(touchLocation, toCoordinateFrom: map)
            
            let pin = MKPointAnnotation()
            pin.coordinate = locationCoordinate
            pin.title = "Pinned location"
            pin.subtitle = "Created for testing"
            
            map.addAnnotation(pin)
        }
        
        if gestureRecognizer.state != UIGestureRecognizer.State.began{
            return
        }
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
    }
   
//    func addCustomPin(){
//        let pin = MKPointAnnotation()
//        pin.coordinate = coordinate
//        pin.title = "Pinned location"
//        pin.subtitle = "Created for testing"
//        
//        map.addAnnotation(pin)
//        
//    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKAnnotationView) else {
            return nil
        }
        
        var annotationView = map.dequeueReusableAnnotationView(withIdentifier: "custom")
        
        if annotationView == nil {
            
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "custom")
            annotationView?.canShowCallout = true
            
        }else{
            annotationView?.annotation = annotation
        }
        
        annotationView?.image = pinImage
        
        return annotationView
        
        
    }
    
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        if let location = locations.first {
            manager.startUpdatingLocation()
            
            render(location)
        }
    }
    
    func render(_ location: CLLocation){
        
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        
        let region = MKCoordinateRegion(center: coordinate, span: span)
        
        map.setRegion(region, animated: true)
        
        
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        pin.title = "Pinned location"
        pin.subtitle = "Created for testing"
        
        map.addAnnotation(pin)
        
    }


}


