import UIKit

class MapController: UIViewController {
    var fetcher: Fetcher

    public init(fetcher: Fetcher) {
        self.fetcher = fetcher
        
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
