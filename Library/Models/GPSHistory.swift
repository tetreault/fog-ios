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

extension UIBezierPath {
    func nextPointFrom(point: CGPoint) -> CGPoint? {
        let index  = self.index(of: point)
        guard index != NSNotFound  else { return nil }

        let newIndex = index.advanced(by: 1)

        guard newIndex < self.points.count else { return nil }

        return self.points[newIndex].cgPointValue
    }

}

func intersection(p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint) -> CGPoint? {
    let x1 = p1.x, x2 = p2.x, x3 = p3.x, x4 = p4.x
    let y1 = p1.y, y2 = p2.y, y3 = p3.y, y4 = p4.y

    let z1 = (x1 - x2), z2 = (x3 - x4), z3 = (y1 - y2), z4 = (y3 - y4)
    let d = (z1 * z4) - (z3 * z2)

    // If d is zero, there is no intersection
    if (d == 0) {
        return nil
    }

    // Get the x and y
    let pre = (x1*y2 - y1*x2), post = (x3*y4 - y3*x4)
    let x = ( pre * z2 - z1 * post ) / d
    let y = ( pre * z4 - z3 * post ) / d

    // Check if the x and y coordinates are within both lines
    if ( x < min(x1, x2) || x > max(x1, x2) || x < min(x3, x4) || x > max(x3, x4) ) {
        return nil
    }

    if ( y < min(y1, y2) || y > max(y1, y2) || y < min(y3, y4) || y > max(y3, y4) ) {
        return nil
    }

    // we got an intersection
    return CGPoint(x: x, y: y)
}

struct Component {
    var a: CGPoint
    var b: CGPoint

    var startPoint: CGPoint
    var intersectionPoint: CGPoint
    var endPoint: CGPoint

    var length: CGFloat
}

struct Segment {
    var current: CGPoint
    var next: CGPoint

    func intersections(with path: UIBezierPath) -> [Component] {
        let totalLength = sqrt(pow(self.current.x - self.next.x, 2) + pow(self.current.y + self.next.y, 2))

        var returns = [Component]()

        for pointValue in path.points {
            let c = pointValue.cgPointValue
            guard let n = path.nextPointFrom(point: c) else { continue }

            if n.equalTo(self.next) {
                continue
            }

            if let intersection = intersection(p1: self.current, p2: self.next, p3: c, p4: n) {
                let length = sqrt(pow(self.current.x - intersection.x, 2) + pow(self.current.y - intersection.y, 2))

                if length > 0.1 && length < totalLength {
                    let component = Component(a: self.current, b: self.next, startPoint: c, intersectionPoint: intersection, endPoint: n, length: length)
                    returns.append(component)
                }
            }
        }

        return returns
    }
}

func simplify(path: UIBezierPath) -> UIBezierPath {
    var points = [CGPoint]()

    let firstPoint = path.currentPoint
    var currentPoint = firstPoint

    points.append(currentPoint)

    var nextPoint = path.nextPointFrom(point: currentPoint)

    while currentPoint.y != firstPoint.y && currentPoint.y != firstPoint.y {
        guard let next = nextPoint else { fatalError() }

        let segment = Segment(current: currentPoint, next: next)
        let intersections = segment.intersections(with: path)

        if intersections.count == 0 {
            points.append(next)
            currentPoint = next
            nextPoint = path.nextPointFrom(point: currentPoint)
        } else {
            let closestIntersection = intersections.first!

            points.append(closestIntersection.intersectionPoint)
            currentPoint = closestIntersection.intersectionPoint
            nextPoint = closestIntersection.endPoint
        }
    }

    let simplifiedPath = UIBezierPath()
    simplifiedPath.move(to: firstPoint)

    for point in points {
        simplifiedPath.addLine(to: point)
    }

    simplifiedPath.close()

    return simplifiedPath
}

struct Converter {
    static func boxSize(forMeters meters: Double) -> Int {
        var size = 60
        if meters > 150 && meters <= 400 {
            size = 45
        } else if meters > 400 && meters <= 600 {
            size = 35
        } else if meters > 600 && meters <= 1000 {
            size = 25
        } else if meters > 1000 && meters <= 2000 {
            size = 15
        } else if meters > 2000 {
            size = 10
        }

        return size
    }

    static func radiusSize(forMeters meters: Double) -> Int {
        var size = 25
        if meters > 150 && meters <= 400 {
            size = 35
        } else if meters > 400 && meters <= 600 {
            size = 45
        } else if meters > 6000 && meters <= 1000 {
            size = 55
        } else if meters > 1000 {
            size = 70
        }

        return size
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

    var location: CLLocation {
        return CLLocation(coordinate: self.coordinate, altitude: self.altitude, horizontalAccuracy: self.horizontalAccuracy, verticalAccuracy: self.verticalAccuracy, course: self.direction, speed: self.speed, timestamp: self.timestamp)
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
        return

        guard self.positions.count > 2 else { return }

        self.simplify(timeOffset: 5.0) // second
        self.simplify(distanceOffset: 15.0) // meter
    }

    fileprivate func simplify(timeOffset: TimeInterval) {
        return
        var removed = Set<Position>()
        let currentPositions = Array(self.positions).sorted { (a, b) -> Bool in
            return a.timestamp.compare(b.timestamp) == .orderedAscending
        }

        for (position, comparison) in currentPositions.enumeratedPairs() {
            let interval = comparison.timestamp.timeIntervalSince(position.timestamp)
            if interval < timeOffset && interval > 0 {
                removed.insert(position)
            } else if interval < 0 {
                print("Something wrong!")
            }
        }

        self.positions = self.positions.subtracting(removed)
        print("Simplified with timestamp from \(currentPositions.count) to \(self.positions.count). Removed: \(removed.count).")
    }

    fileprivate func simplify(distanceOffset: Double) {
        var removed = Set<Position>()

        let zeroLocation = CLLocation(latitude: 0, longitude: 0)
        let currentPositions = Array(self.positions).sorted { (a, b) -> Bool in
            let distanceA = a.location.distance(from: zeroLocation)
            let distanceB = b.location.distance(from: zeroLocation)

            return distanceA > distanceB
        }

        for (position, comparison) in currentPositions.enumeratedPairs() {
            let distance = position.location.distance(from: comparison.location)

            if distance < distanceOffset {
                removed.insert(position)
            }
        }

        self.positions = self.positions.subtracting(removed)
        print("Simplified with distance from \(currentPositions.count) to \(self.positions.count). Removed: \(removed.count).")
    }

    func update(with location: CLLocation) {
        let position = Position(location: location)
        position.travelID = self.travelID

        let offset = 5.0 // meters
        let containsLocation = self.positions.contains { (p) -> Bool in
            return (p.location.distance(from: location) <= offset)
        }

        if containsLocation {
            print("Ignore location")
            return
        }

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
