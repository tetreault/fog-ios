import SweetUIKit
import CoreLocation
import MapKit

fileprivate let userPinReuseIdentifier = "userPin"

class MapController: UIViewController {
    var fetcher: Fetcher

    var latestCoordinate: CLLocationCoordinate2D?


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

        return view
    }()

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
        self.mapView.fillSuperview()
    }
}

extension MapController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
            self.mapView.setRegion(region, animated: true)
        }
    }
}
