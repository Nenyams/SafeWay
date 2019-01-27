/*
 * Copyright 2016 Google Inc. All rights reserved.
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
 * file except in compliance with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import UIKit
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController {
    let originViewController = GMSAutocompleteViewController()
    let destinationViewController = GMSAutocompleteViewController()
    var originLatitude = 0.0, originLongitude = 0.0, destinationLatitude = 0.0, destinationLongitude = 0.0
    var priorityValue = 0.0
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var safetySlider: UISlider!
    
    @IBAction func presentOriginViewController(_ sender: Any) {
            originViewController.delegate = self
            present(originViewController, animated: true, completion: nil)
        }
    @IBAction func presentDestinationViewController(_ sender: Any) {
        destinationViewController.delegate = self
        present(destinationViewController, animated: true, completion: nil)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
//        Test code for uploading - works!
//        let origin = Location(latitude: 50.2, longitude: 20.3)
//        let destination = Location(latitude: 2.3, longitude: 13.4)
//        let arriveBy = MapTime(hour: 23, minute: 14, timezone: -1)
//        let journey = JourneyRequest(origin: origin, destination: destination, arrive_by: arriveBy, safety_priority: 2)
//        self.upload(request: journey)
  }

//    func getLocation (_ input: GMSPlace) -> (location: ) {
        
//    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let journeyRequest = JourneyRequest {}
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        let origin = Location(latitude: Float(self.originLatitude),longitude: Float(self.originLongitude))
        let destination = Location(latitude: Float(self.destinationLatitude), longitude: Float(self.destinationLongitude))
        let journey = JourneyRequest(origin: origin, destination: destination, arrive_by: MapTime(date: self.datePicker.date), safety_priority: self.safetySlider.value)
        if let destinationViewController = segue.destination as? MapViewController{
            destinationViewController.journey = journey
            destinationViewController.findRoute()
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if self.originLatitude == 0.0 && self.destinationLongitude == 0.0{
            return false
        }
        return true
    }
}

extension ViewController:  GMSAutocompleteViewControllerDelegate {
   
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        if viewController == originViewController {
            originLatitude = place.coordinate.latitude
            originLongitude = place.coordinate.longitude
        }
        else {
            destinationLatitude = place.coordinate.latitude
            destinationLongitude = place.coordinate.longitude
        }
        //print(place.coordinate.latitude)
        //print(place.name)
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension URLSession {
    func synchronouslyExecute(_ request:URLRequest) -> (Data?, URLResponse?, NSError?) {
        var data: Data?, response: URLResponse?, error: NSError?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        dataTask(with: request, completionHandler: {
            data = $0; response = $1; error = $2 as NSError?
            semaphore.signal()
        }) .resume()
        let timeout = DispatchTime.now() + Double(10000)
//            / Double(NSEC_PER_SEC)
        
        semaphore.wait(timeout: timeout)
        
        return (data, response, error)
    }
}

struct JourneyRequest:Codable {
    var origin: Location
    var destination: Location
    var arrive_by: MapTime?
    var safety_priority: Float
}

struct Location:Codable {
    var latitude: Float
    var longitude: Float
}

struct MapTime:Codable{
    var hour: Int
    var minute: Int
    var timezone: Int
    
    init(date: Date) {
        let calendar = Calendar(identifier: .gregorian)
        self.hour = calendar.component(.hour, from: date)
        self.minute = calendar.component(.minute, from: date)
        self.timezone = 0
    }
}
