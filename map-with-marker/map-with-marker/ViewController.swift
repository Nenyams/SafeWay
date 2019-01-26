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

class ViewController: UIViewController {

    @IBOutlet weak var origin: UITextField!
    @IBOutlet weak var destination: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        Test code for uploading - works!
//        let origin = Location(latitude: 50.2, longitude: 20.3)
//        let destination = Location(latitude: 2.3, longitude: 13.4)
//        let arriveBy = MapTime(hour: 23, minute: 14, timezone: -1)
//        let journey = JourneyRequest(origin: origin, destination: destination, arrive_by: arriveBy, safety_priority: 2)
//        self.upload(request: journey)
  }

    func upload(request: JourneyRequest){
        let encoder = JSONEncoder()
        let requestData = try! encoder.encode(request)
        let url = URL(string: "https://safeway19.herokuapp.com/safeway/route")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = requestData
        let (data, response, error) = URLSession.shared.synchronouslyExecute(request)
        print(response, String(data: data!, encoding: .utf8))
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
        let timeout = DispatchTime.now() + Double(10000000000) / Double(NSEC_PER_SEC)
        
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
