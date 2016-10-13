import Foundation
import Networking

class Fetcher {

    var networking: Networking

    init(baseURL: String) {
        self.networking = Networking(baseURL: baseURL)
    }

//    func someResource(_ completion: @escaping (_ error: NSError?) -> ()) {
//        self.networking.GET("/someResource") { JSON, error in
//            if let JSON = JSON as? [[String : AnyObject]] {
//                Sync.changes(JSON, inEntityNamed: "SomeEntityName", dataStack: self.data, completion: { error in
//                    completion(error)
//                })
//            } else {
//                completion(error)
//            }
//        }
//    }
}
