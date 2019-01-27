//
//  MapViewController.swift
//  map-with-marker
//
//  Created by Nene Yamasaki on 26/01/2019.
//  Copyright © 2019 William French. All rights reserved.
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController {

    @IBOutlet weak var myMap: GMSMapView!
    @IBOutlet weak var routeUpdate: UITextView!
    
    var route: GMSPath?
    var journey: JourneyRequest? //pased by ViewController.prepare(for:)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let camera = GMSCameraPosition.camera(withLatitude: 52.2053, longitude: 0.1218, zoom: 6.0)
            myMap.camera = camera
        
        // Creates a marker in the center of the map.
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 52.2053, longitude: 0.1218)
        marker.title = "Sydney"
        marker.snippet = "Australia"
        marker.map = myMap
        
        self.view.bringSubviewToFront(routeUpdate)
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
                self.setupRoute()
            }
        }
    }
    
    func setupRoute(){
        print("Setting up route...")
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

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

