import UIKit

@UIApplicationMain
class AppDelegate: UIResponder {
    var window: UIWindow?
}

extension AppDelegate: UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = MapController()
        window.makeKeyAndVisible()

        self.window = window

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if let controller = self.window?.rootViewController as? MapController {
            controller.synchronize()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        if let controller = self.window?.rootViewController as? MapController {
            controller.synchronize()
        }
    }
}
