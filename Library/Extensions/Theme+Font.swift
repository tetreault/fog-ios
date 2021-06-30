import UIKit

extension UIFont {

    class func light(size: Double) -> UIFont {
        return UIFont.systemFont(ofSize: CGFloat(size), weight: UIFont.Weight.light)
    }

    class func regular(size: Double) -> UIFont {
        return UIFont.systemFont(ofSize: CGFloat(size), weight: UIFont.Weight.regular)
    }

    class func medium(size: Double) -> UIFont {
        return UIFont.systemFont(ofSize: CGFloat(size), weight: UIFont.Weight.medium)
    }

    class func bold(size: Double) -> UIFont {
        return UIFont.systemFont(ofSize: CGFloat(size), weight: UIFont.Weight.bold)
    }
}
