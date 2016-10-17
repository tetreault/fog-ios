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
        let realm = try! Realm()

//        try! realm.write {
//            realm.deleteAll()
//        }

        return realm
    }()

    lazy var history: GPSHistory = {
        let history = GPSHistory()
        history.delegate = self
        var positions = Set<Position>(self.realm.objects(Position.self))

        print("Retrieving \(positions.count) positions.")

        let travel = Travel(with: positions)

        history.travels.append(travel)

        return history
    }()

    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.pausesLocationUpdatesAutomatically = false

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

        // Bonn office: +50.73396677,+7.09824396

//        let points = [
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.733956), longitude: CLLocationDegrees(7.098214)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734176), longitude: CLLocationDegrees(7.098603)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.733649), longitude: CLLocationDegrees(7.099952)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734431), longitude: CLLocationDegrees(7.10092)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734047), longitude: CLLocationDegrees(7.101789)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.73454), longitude: CLLocationDegrees(7.102401)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734356), longitude: CLLocationDegrees(7.102975)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734258), longitude: CLLocationDegrees(7.103603)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734431), longitude: CLLocationDegrees(7.104472)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734601), longitude: CLLocationDegrees(7.104649)),
//            ]
//        let points2 = [
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.669630), longitude: CLLocationDegrees(7.183780)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.669427), longitude: CLLocationDegrees(7.182988)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.669046), longitude: CLLocationDegrees(7.18346)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.66857), longitude: CLLocationDegrees(7.182409)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.669116), longitude: CLLocationDegrees(7.181304)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.698243), longitude: CLLocationDegrees(7.139955)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.730091), longitude: CLLocationDegrees(7.102103)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.732501), longitude: CLLocationDegrees(7.097222)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.733256), longitude: CLLocationDegrees(7.097723)),
//            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734176), longitude: CLLocationDegrees(7.098603)),
//        ]
//        let line2 = MKPolyline(coordinates: points2, count: points2.count)

        let points = self.history.travels.first!.coordinates
        let line = MKPolyline(coordinates: points, count: points.count)
        self.mapView.add(line)

        var circles = [MKCircle]()

        for travel in self.history.travels {
            for position in travel.positions {
                circles.append(MKCircle(center: position.coordinates, radius: CLLocationDistance(50.0)))
            }
        }

        self.mapView.addOverlays(circles)

        if self.isDebuggingPositions {
            var idx = 1
            for travel in self.history.travels {
                for position in travel.positions {
                    let pointAnnotation = MKPointAnnotation()
                    pointAnnotation.coordinate = position.coordinates
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
            var oldPositions = Set<Position>(self.realm.objects(Position.self))

            for travel in self.history.travels {
                print("Persisting \(travel.positions.count) positions.")
                oldPositions.subtract(travel.positions)
                for position in travel.positions {
                    self.realm.add(position)
                }
            }

            print("Removing outdated: \(oldPositions.count).")
            self.realm.delete(oldPositions)
        }
    }
}

extension MapController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        guard location.horizontalAccuracy <= 65.0 else { return }

        if let travel = self.history.travels.last {
            travel.update(with: location.coordinate)
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

    // Uncomment to draw paths for debugging
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKPolyline {
            let lineRenderer = MKPolylineRenderer(polyline: overlay)
            lineRenderer.lineWidth = 20
            lineRenderer.strokeColor = .magenta

            return lineRenderer
        } 
//        if let overlay = overlay as? MKCircle {
//            let circleRenderer = MKCircleRenderer(circle: overlay)
//            circleRenderer.fillColor = .red
//            circleRenderer.strokeColor = .magenta
//
//            return circleRenderer
//        }

        return MKOverlayRenderer(overlay: overlay)
    }
}

extension MapController: GPSHistoryDelegate {
    func historyDidChange(_ history: GPSHistory) {
        self.mapView.removeOverlays(self.mapView.overlays)

        var circles = [MKCircle]()
        for travel in self.history.travels {
            for position in travel.positions {
                circles.append(MKCircle(center: position.coordinates, radius: CLLocationDistance(50.0)))
            }
        }

        self.mapView.addOverlays(circles)
    }
}
