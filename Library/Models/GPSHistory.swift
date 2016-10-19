import Foundation
import CoreLocation
import MapKit
import Realm
import RealmSwift

fileprivate let distanceOffset = CLLocationDistance(25)

protocol GPSHistoryDelegate: class {
    func historyDidChange(_ history: GPSHistory)
}

extension CLLocation {

    convenience init(position: Position) {
        let coordinate = CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)
        self.init(coordinate: coordinate, altitude: position.altitude, horizontalAccuracy: position.horizontalAccuracy, verticalAccuracy: position.verticalAccuracy, course: position.direction, speed: position.speed, timestamp: position.timestamp)
    }
}

class Position: Object {
    dynamic var travelID: String = UUID().uuidString

    dynamic var latitude: CLLocationDegrees = 0
    dynamic var longitude: CLLocationDegrees = 0

    dynamic var altitude: CLLocationDistance = 0
    dynamic var horizontalAccuracy: CLLocationAccuracy = 0
    dynamic var verticalAccuracy: CLLocationAccuracy = 0
    dynamic var direction: CLLocationDirection = 0
    dynamic var speed: CLLocationSpeed = 0
    dynamic var timestamp: Date = Date()

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }

    override var hashValue: Int {
        return (self.latitude + self.longitude).hashValue
    }

    open override class func indexedProperties() -> [String] {
        return ["travelID"]
    }

    convenience init(location: CLLocation) {
        self.init()

        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude

        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
        self.direction = location.course
        self.speed = location.speed
        self.timestamp = location.timestamp
    }
}

class Travel {
    fileprivate var history: GPSHistory?
    var travelID: String

    var ignoredCount: Int = 0

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
        guard self.positions.count > 2 else { return }

        var removed = Set<Position>()
        var ignored = Set<Position>()
        let currentPositions = Array(self.positions).sorted { (a, b) -> Bool in
            return a.timestamp.compare(b.timestamp) == .orderedAscending
        }

        for (position, comparison) in currentPositions.enumeratedWithCurrentAndNext() {
            if position == comparison || ignored.contains(comparison) {
                continue
            }

            let interval = comparison.timestamp.timeIntervalSince(position.timestamp)
            if interval < 5 && interval > 0 {
                removed.insert(position)
                ignored.insert(comparison)
            } else if interval < 0 {
                print("Something wrong!")
            }
        }

        self.positions = self.positions.subtracting(removed)
        print("Simplified from \(currentPositions.count) to \(self.positions.count). Removed: \(removed.count).")
    }

    func update(with location: CLLocation) {
        let position = Position(location: location)
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
