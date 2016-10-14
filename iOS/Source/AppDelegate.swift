import UIKit

@UIApplicationMain
class AppDelegate: UIResponder {
    var window: UIWindow?

    lazy var fetcher: Fetcher = {
        let fetcher = Fetcher(baseURL: "https://server.com")

        return fetcher
    }()
}

extension AppDelegate: UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = MapController(fetcher: self.fetcher)
        window.makeKeyAndVisible()

        self.window = window

        return true
    }
}
