import UIKit

extension UIFont {

    class func light(_ size: Double) -> UIFont {
        return UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightLight)
    }

    class func regular(_ size: Double) -> UIFont {
        return UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightRegular)
    }

    class func medium(_ size: Double) -> UIFont {
        return UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightMedium)
    }

    class func bold(_ size: Double) -> UIFont {
        return UIFont.systemFont(ofSize: CGFloat(size), weight: UIFontWeightBold)
    }
}
