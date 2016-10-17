import Foundation
import CoreLocation
import Realm
import RealmSwift

protocol GPSHistoryDelegate: class {
    func historyDidChange(_ history: GPSHistory)
}

class Position: Object {
    dynamic var latitude: CLLocationDegrees = 0
    dynamic var longitude: CLLocationDegrees = 0

    var coordinates: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }

    override var hashValue: Int {
        return (self.latitude + self.longitude).hashValue
    }
}

class Travel {
    fileprivate var history: GPSHistory?

    var positions = Set<Position>() {
        didSet {
            self.history?.travelDidChange(self)
        }
    }

    fileprivate var coordinates: [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        for point in self.positions {
            coordinates.append(point.coordinates)
        }

        return coordinates
    }

    func update(with coordinate: CLLocationCoordinate2D) {
        if self.coordinates.count > 10 {
            var coordinates = SwiftSimplify.simplify(self.coordinates)
            coordinates.append(coordinate)

            var positions = Set<Position>()
            for coordinate in coordinates {
                let position = Position()
                position.longitude = coordinate.longitude
                position.latitude = coordinate.latitude

                positions.insert(position)
            }
            
            self.positions = positions
        } else {
            let position = Position()
            position.longitude = coordinate.longitude
            position.latitude = coordinate.latitude
            
            self.positions.insert(position)
        }
    }

    init(with positions: Set<Position> = []) {
        self.positions = positions
    }
}

class GPSHistory {
    weak var delegate: GPSHistoryDelegate?

    fileprivate var historyFilePath: String {
        get {
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.absoluteString.appending("/history.json")
        }
    }

    var travels = [Travel]() {
        didSet {
            for travel in self.travels {
                travel.history = self
            }
        }
    }

    init(with travels: [Travel] = []) {
        self.travels = travels
    }

    fileprivate func travelDidChange(_ travel: Travel) {
        self.delegate?.historyDidChange(self)
    }
}
