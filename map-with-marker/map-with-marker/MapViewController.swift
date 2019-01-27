//
//  MapViewController.swift
//  map-with-marker
//
//  Created by Nene Yamasaki on 26/01/2019.
//  Copyright © 2019 William French. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import GooglePlacePicker

class MapViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var myMap: GMSMapView!
    @IBOutlet weak var routeUpdate: UITextView!
    var route: GMSPath?
    var journey: JourneyRequest? //pased by ViewController.prepare(for:)
    var zoomLevel: Float = 100.0
    
    var locationManager: CLLocationManager!
    var placePicker: GMSPlacePickerViewController!
    var currentLatitude: Double!
    var currentLongitude: Double!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Current Location
        var locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        //placesClient = GMSPlacesClient.shared()
        
        let camera = GMSCameraPosition.camera(withLatitude: 52.2053, longitude: 0.1218, zoom: zoomLevel)
            myMap.camera = camera
    }
    

    func upload(request: JourneyRequest) -> (Data?, URLResponse?, NSError?) {
        let encoder = JSONEncoder()
        let requestData = try! encoder.encode(request)
        let url = URL(string: "https://safeway19.herokuapp.com/safeway/route")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = requestData
        let (data, response, error) = URLSession.shared.synchronouslyExecute(request)
        print(response)
        if data != nil{
            print(String(data: data!, encoding: .utf8))
        }
        return (data, response, error)
    }
    
    func findRoute(){
        let networkQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
        let sv = MapViewController.displaySpinner(onView: self.view)
        networkQueue.async {
            let (data, response, error) = self.upload(request: self.journey!)
            MapViewController.removeSpinner(spinner: sv)
            DispatchQueue.main.async {
                self.setupRoute(data: data)
            }
        }
    }
    
    func setupRoute(data: Data!){
        print("Setting up route...")
        let decoder = JSONDecoder()
        let journeyInfo = try! decoder.decode(RouteInformation.self, from: data)
        print(journeyInfo)
        let path = GMSPath(fromEncodedPath: journeyInfo.overview_polyline.points)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 5
        polyline.spans = [GMSStyleSpan(color: .orange)]
        print(polyline)
        polyline.map = self.myMap
        let northEastCoords = CLLocationCoordinate2DMake(CLLocationDegrees(journeyInfo.bounds.northeast.lat), CLLocationDegrees(journeyInfo.bounds.northeast.lng))
        let southWestCoords = CLLocationCoordinate2DMake(CLLocationDegrees(journeyInfo.bounds.southwest.lat), CLLocationDegrees(journeyInfo.bounds.southwest.lng))
        let bounds = GMSCoordinateBounds(coordinate: northEastCoords, coordinate: southWestCoords)
        let update = GMSCameraUpdate.fit(bounds, withPadding: 50.0)
        myMap.moveCamera(update)
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]){
        // 1
        let location:CLLocation = locations.last!
        self.currentLatitude = location.coordinate.latitude
        self.currentLongitude = location.coordinate.longitude
        
        // 2
        let coordinates = CLLocationCoordinate2DMake(self.currentLatitude, self.currentLongitude)
        let marker = GMSMarker(position: coordinates)
        marker.title = "I am here"
        marker.map = self.myMap
        self.myMap.animate(toLocation: coordinates)
    }
}

//extension MapViewController: CLLocationManagerDelegate {
//    // Handle incoming location events.
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        let location: CLLocation = locations.last!
//        print("Location: \(location)")
//
//        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
//                                              longitude: location.coordinate.longitude,
//                                              zoom: zoomLevel)
//
//        if myMap.isHidden {
//            myMap.isHidden = false
//            myMap.camera = camera
//        } else {
//            myMap.animate(to: camera)
//        }
//    }
//
//    // Handle authorization for the location manager.
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        switch status {
//        case .restricted:
//            print("Location access was restricted.")
//        case .denied:
//            print("User denied access to location.")
//            // Display the map using the default location.
//            myMap.isHidden = false
//        case .notDetermined:
//            print("Location status not determined.")
//        case .authorizedAlways: fallthrough
//        case .authorizedWhenInUse:
//            print("Location status is OK.")
//        }
//    }
//}

extension MapViewController {
    class func displaySpinner(onView : UIView) -> UIView {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        return spinnerView
    }
    
    class func removeSpinner(spinner :UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
    }
}


struct RouteInformation: Codable{
    var bounds: Bounds
    var legs: [RouteLeg]
    var overview_polyline: PolyLine
}

struct Bounds: Codable{
    var northeast: Loc
    var southwest: Loc
}

struct RouteLeg: Codable{
    var distance: ValueWrapper
    var duration: ValueWrapper
}

struct ValueWrapper: Codable{
    var value: Float
}

struct PolyLine: Codable{
    var points: String
}

struct Loc: Codable{
    var lat: Float
    var lng: Float
}
