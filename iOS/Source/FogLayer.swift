import UIKit
import CoreGraphics

class FogLayer: CALayer {

    var path: UIBezierPath? {
        didSet {
            self.setNeedsDisplay()
        }
    }

    var backgroundImageColor: UIColor

    override init() {
        self.backgroundImageColor = UIColor(patternImage: #imageLiteral(resourceName: "fog"))
        super.init()
    }

    override init(layer: Any) {
        self.backgroundImageColor = UIColor(patternImage: #imageLiteral(resourceName: "fog"))
        super.init(layer: layer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func draw(in ctx: CGContext) {
        UIGraphicsPushContext(ctx)

        self.backgroundImageColor.withAlphaComponent(0.75).setFill()
        UIColor.clear.setStroke()

        ctx.fill(self.bounds)
        ctx.setBlendMode(.clear)

        self.path?.fill()

        UIGraphicsPopContext()
    }
}
