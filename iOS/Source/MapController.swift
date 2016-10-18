import SweetUIKit
import CoreLocation
import MapKit
import Realm
import RealmSwift

fileprivate let userPinReuseIdentifier = "userPin"

class MapController: UIViewController {
    var isTrackingUser = true

    var isDebuggingPositions = false

    lazy var realm: Realm = {
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 1,

            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 1) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        Realm.Configuration.defaultConfiguration = config

        let realm = try! Realm()

        return realm
    }()

    lazy var history: GPSHistory = {
        let history = GPSHistory()
        history.delegate = self
        var positions = Set<Position>(self.realm.objects(Position.self))
        print("Retrieving \(positions.count) positions.")

        let travel = Travel()
        if positions.count > 0 {
//            var grouped = [String: [Position]]()
//
//            for position in positions {
//                var group = grouped[position.travelID] ?? [Position]()
//                group.append(position)
//                grouped[position.travelID] = group
//            }
//
//            for (key, value) in grouped {
//                var travel = history.travel(for: key) ?? Travel(travelID: key)
//                travel.positions.formUnion(value)
//                history.travels.append(travel)
//            }

            travel.positions.formUnion(positions)
        }

        history.travels.append(travel)

        return history
    }()

    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = true

        return manager
    }()

    lazy var mapView: MKMapView = {
        let view = MKMapView(withAutoLayout: true)
        view.showsUserLocation = true
        view.delegate = self

        return view
    }()

    lazy var fogLayer: FogLayer = {
        return FogLayer()
    }()

    lazy var displayLink: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(MapController.updateDisplayLink))

        return link
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.locationManager.startUpdatingLocation()

        self.view.addSubview(self.mapView)
        self.view.layer.addSublayer(self.fogLayer)

        self.mapView.fillSuperview()
        self.displayLink.add(to: RunLoop.main, forMode: .commonModes)

        if self.isDebuggingPositions {
            var idx = 1
            for travel in self.history.travels {
                for position in travel.positions {
                    let pointAnnotation = MKPointAnnotation()
                    pointAnnotation.coordinate = position.coordinate
                    pointAnnotation.title = "point: \(idx)"

                    idx += 1

                    self.mapView.addAnnotation(pointAnnotation)
                }
            }
        }
    }

    func circlePath(with overlay: MKCircle) -> UIBezierPath {
        let region = MKCoordinateRegionForMapRect(overlay.boundingMapRect)
        let frame = self.mapView.convertRegion(region, toRectTo: self.mapView)

        let path = UIBezierPath(roundedRect: frame, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: frame.width / 2, height: frame.height / 2))

        return path
    }

    func linePath(with overlay: MKPolyline) -> UIBezierPath {
        let path = UIBezierPath()

        var points = [CGPoint]()
        for mapPoint in UnsafeBufferPointer(start: overlay.points(), count: overlay.pointCount) {
            let coordinate = MKCoordinateForMapPoint(mapPoint)
            let point = self.mapView.convert(coordinate, toPointTo: self.view)
            points.append(point)
        }

        if let first = points.first {
            path.move(to: first)
        }
        for point in points {
            path.addLine(to: point)
        }
        for point in points.reversed() {
            path.addLine(to: point)
        }

        path.close()

        return path
    }

    func updateDisplayLink() {
        self.fogLayer.frame = self.mapView.frame

        let path = UIBezierPath()
        for overlay in self.mapView.overlays {
            if let overlay = overlay as? MKCircle {
                path.append(self.circlePath(with: overlay))
            } else if let overlay = overlay as? MKPolyline {
                let linePath = self.linePath(with: overlay)
                linePath.lineWidth = 20
                path.append(linePath)
            }
        }

        path.lineJoinStyle = .round
        path.lineCapStyle = .round

        self.fogLayer.path = path
        self.fogLayer.setNeedsDisplay()
    }

    func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        guard let view = self.mapView.subviews.first else { return false }
        guard let gestureRecognizers = view.gestureRecognizers else { return false }

        for recognizer in gestureRecognizers {
            if recognizer.state == .began || recognizer.state == .ended {
                return true
            }
        }

        return false
    }

    func synchronize() {
        try! self.realm.write {
            for travel in self.history.travels {
                travel.simplify()
                print("Persisting \(travel.positions.count) positions.")
                for position in travel.positions {
                    self.realm.add(position)
                }
            }
        }
    }
}

extension MapController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        guard location.horizontalAccuracy <= 65.0 else {
            print("Too innacurate to be saved.")
            
            return
        }

        if let travel = self.history.travels.last {
            travel.update(with: location)
        }

        if self.isTrackingUser {
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
            self.mapView.setRegion(region, animated: true)
        }
    }
}

extension MapController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.isTrackingUser = !self.mapViewRegionDidChangeFromUserInteraction()
    }

//    // Uncomment to draw paths for debugging
//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        if let overlay = overlay as? MKPolyline {
//            let lineRenderer = MKPolylineRenderer(polyline: overlay)
//            lineRenderer.lineWidth = 20
//            lineRenderer.strokeColor = .magenta
//
//            return lineRenderer
//        }
//                if let overlay = overlay as? MKCircle {
//                    let circleRenderer = MKCircleRenderer(circle: overlay)
//                    circleRenderer.fillColor = .red
//                    circleRenderer.strokeColor = .magenta
//        
//                    return circleRenderer
//                }
//
//        return MKOverlayRenderer(overlay: overlay)
//    }
}

extension MapController: GPSHistoryDelegate {

    func historyDidChange(_ history: GPSHistory) {
        self.mapView.removeOverlays(self.mapView.overlays)

        var circles = [MKCircle]()
        for travel in self.history.travels {
            for position in travel.positions {
                circles.append(MKCircle(center: position.coordinate, radius: CLLocationDistance(15.0)))
            }
        }

        self.mapView.addOverlays(circles)
    }
}
