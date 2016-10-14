import Foundation
import Networking

class Fetcher {

    var networking: Networking

    init(baseURL: String) {
        self.networking = Networking(baseURL: baseURL)
    }
}
