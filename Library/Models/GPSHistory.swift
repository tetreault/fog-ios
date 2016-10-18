import Foundation
import CoreLocation
import MapKit
import Realm
import RealmSwift

protocol GPSHistoryDelegate: class {
    func historyDidChange(_ history: GPSHistory)
}

class Position: Object {
    dynamic var latitude: CLLocationDegrees = 0
    dynamic var longitude: CLLocationDegrees = 0
    dynamic var travelID: String = UUID().uuidString

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }

    override var hashValue: Int {
        return (self.latitude + self.longitude).hashValue
    }

    open override class func indexedProperties() -> [String] {
        return ["travelID"]
    }
}

class Travel {
    fileprivate var history: GPSHistory?
    var travelID: String

    var positions = Set<Position>() {
        didSet {
            self.history?.travelDidChange(self)
        }
    }

    var coordinates: [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        for position in self.positions {
            coordinates.append(position.coordinate)
        }

        return coordinates
    }

    func simplify() {
//        guard self.positions.count > 2 else { return }        
//        let polygon = MKPolygon(coordinates: self.coordinates, count: self.positions.count)
//        dump(polygon)
//        var positions = Set<Position>()
//
//        for coordinate in coordinates {
//            let position = Position()
//            position.longitude = coordinate.longitude
//            position.latitude = coordinate.latitude
//            position.travelID = self.travelID
//
//            positions.insert(position)
//        }
//        print("Simplified from \(self.coordinates.count) points down to \(positions.count).")
//
//        self.positions = positions
    }

    func update(with coordinate: CLLocationCoordinate2D) {
        let position = Position()
        position.longitude = coordinate.longitude
        position.latitude = coordinate.latitude
        position.travelID = self.travelID

        self.positions.insert(position)

        self.simplify()
    }

    init(travelID: String? = nil, positions: Set<Position> = []) {
        self.positions = positions
        self.travelID = travelID ?? UUID().uuidString
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

    func travel(for key: String) -> Travel? {
        for travel in self.travels {
            if travel.travelID == key {
                return travel
            }
        }

        return nil
    }
}
