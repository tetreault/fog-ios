import CoreImage
// import SweetUIKit
import CoreLocation
import MapKit

fileprivate let userPinReuseIdentifier = "userPin"

class MapController: UIViewController {
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
        let view = MKMapView(frame: UIScreen.main.bounds /* withAutoLayout: true */ )
        view.showsUserLocation = true
        view.delegate = self

        return view
    }()

    lazy var fogLayer: FogLayer = {
        FogLayer()
    }()

    lazy var displayLink: CADisplayLink = {
        let link = CADisplayLink(target: self, selector: #selector(MapController.updateDisplayLink))

        return link
    }()

    var visitedLines = [MKPolyline]()

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.startUpdatingLocation()

        view.addSubview(mapView)
        view.layer.addSublayer(fogLayer)

        // self.mapView.fillSuperview()
        displayLink.add(to: RunLoop.main, forMode: RunLoop.Mode.common)

        // Bonn office: +50.73396677,+7.09824396

        let points = [
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.733956), longitude: CLLocationDegrees(7.098214)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734176), longitude: CLLocationDegrees(7.098603)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.733649), longitude: CLLocationDegrees(7.099952)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734431), longitude: CLLocationDegrees(7.10092)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734047), longitude: CLLocationDegrees(7.101789)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.73454), longitude: CLLocationDegrees(7.102401)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734356), longitude: CLLocationDegrees(7.102975)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734258), longitude: CLLocationDegrees(7.103603)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734431), longitude: CLLocationDegrees(7.104472)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734601), longitude: CLLocationDegrees(7.104649)),
        ]

        let points2 = [
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.669630), longitude: CLLocationDegrees(7.183780)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.669427), longitude: CLLocationDegrees(7.182988)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.669046), longitude: CLLocationDegrees(7.18346)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.66857), longitude: CLLocationDegrees(7.182409)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.669116), longitude: CLLocationDegrees(7.181304)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.698243), longitude: CLLocationDegrees(7.139955)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.730091), longitude: CLLocationDegrees(7.102103)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.732501), longitude: CLLocationDegrees(7.097222)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.733256), longitude: CLLocationDegrees(7.097723)),
            CLLocationCoordinate2D(latitude: CLLocationDegrees(50.734176), longitude: CLLocationDegrees(7.098603)),
        ]

        let line1 = MKPolyline(coordinates: points, count: points.count)
        let line2 = MKPolyline(coordinates: points2, count: points2.count)

        mapView.addOverlays([line1, line2])

        var circles = [MKCircle]()

        for point in points {
            circles.append(MKCircle(center: point, radius: CLLocationDistance(50.0)))
        }

        for point in points2 {
            circles.append(MKCircle(center: point, radius: CLLocationDistance(50.0)))
        }

        mapView.addOverlays(circles)

        if isDebuggingPositions {
            var idx = 1
            for point in points {
                let pointAnnotation = MKPointAnnotation()
                pointAnnotation.coordinate = point
                pointAnnotation.title = "point: \(idx)"

                idx += 1

                mapView.addAnnotation(pointAnnotation)
            }
        }
    }

    func circlePath(with overlay: MKCircle) -> UIBezierPath {
        let region = MKCoordinateRegion(overlay.boundingMapRect)
        let frame = mapView.convert(region, toRectTo: mapView)

        let path = UIBezierPath(roundedRect: frame, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: frame.width / 2, height: frame.height / 2))

        return path
    }

    func linePath(with overlay: MKPolyline) -> UIBezierPath {
        let path = UIBezierPath()

        var points = [CGPoint]()
        for mapPoint in UnsafeBufferPointer(start: overlay.points(), count: overlay.pointCount) {
            let coordinate = mapPoint.coordinate
            let point = mapView.convert(coordinate, toPointTo: view)
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

    @objc func updateDisplayLink() {
        fogLayer.frame = mapView.frame

        let path = UIBezierPath()
        for overlay in mapView.overlays {
            if let overlay = overlay as? MKCircle {
                path.append(circlePath(with: overlay))
            } else if let overlay = overlay as? MKPolyline {
                let linePath = self.linePath(with: overlay)
                linePath.lineWidth = 20
                path.append(linePath)
            }
        }

        path.lineJoinStyle = .round
        path.lineCapStyle = .round

        fogLayer.path = path
        fogLayer.setNeedsDisplay()
    }

    func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        guard let view = mapView.subviews.first else { return false }
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

        if isTrackingUser {
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
            mapView.setRegion(region, animated: true)
        }
    }
}

extension MapController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        isTrackingUser = !mapViewRegionDidChangeFromUserInteraction()
    }

//    // Uncomment to draw paths for debugging
//        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//            if let overlay = overlay as? MKPolyline {
//                let lineRenderer = MKPolylineRenderer(polyline: overlay)
//                lineRenderer.lineWidth = 20
//                lineRenderer.strokeColor = .magenta
//
//                return lineRenderer
//            }
//
//            return MKOverlayRenderer(overlay: overlay)
//        }
}
