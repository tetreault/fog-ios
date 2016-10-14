import SweetUIKit
import CoreLocation
import MapKit
import CoreImage

fileprivate let userPinReuseIdentifier = "userPin"

class MapController: UIViewController {
    var fetcher: Fetcher

    var latestCoordinate: CLLocationCoordinate2D?

    var isTrackingUser = true

    var isDebuggingPositions = false

    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        manager.desiredAccuracy = 25.0 // meters

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

    var visitedLines = [MKPolyline]()

    public init(fetcher: Fetcher) {
        self.fetcher = fetcher

        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.locationManager.startUpdatingLocation()

        self.view.addSubview(self.mapView)
        self.view.layer.addSublayer(self.fogLayer)

        self.mapView.fillSuperview()
        self.displayLink.add(to: RunLoop.main, forMode: .commonModes)

        // Bonn office: +50.73396677,+7.09824396
        let center = CLLocationCoordinate2D(latitude: CLLocationDegrees(50.7339560964271), longitude: CLLocationDegrees(7.098214368263295))
        let circle = MKCircle(center: center, radius: CLLocationDistance(150.0)) // meter radius

        let points = [CLLocationCoordinate2D(latitude: CLLocationDegrees(50.7350560964271), longitude: CLLocationDegrees(7.098214368263295)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.7360560964271), longitude: CLLocationDegrees(7.098314368263295)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.7370560964271), longitude: CLLocationDegrees(7.099414368263295)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.7380560964271), longitude: CLLocationDegrees(7.099514368263295)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.7390560964271), longitude: CLLocationDegrees(7.098614368263295)),
        ]
        let line = MKPolyline(coordinates: points, count: points.count)

        self.mapView.addOverlays([circle, line])

        if self.isDebuggingPositions {
            var idx = 1
            for point in points {
                let pointAnnotation = MKPointAnnotation()
                pointAnnotation.coordinate = point
                pointAnnotation.title = "point: \(idx)"

                idx += 1

                self.mapView.addAnnotation(pointAnnotation)
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
        path.lineWidth = 30

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
}

extension MapController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

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
//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        if let overlay = overlay as? MKPolyline {
//            let lineRenderer = MKPolylineRenderer(polyline: overlay)
//            lineRenderer.lineWidth = 20
//            lineRenderer.strokeColor = .magenta
//
//            return lineRenderer
//        }
//
//        return MKOverlayRenderer(overlay: overlay)
//    }
}
