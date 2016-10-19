import UIKit
import XCTest

class SummitPeekTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testQuadTreeInsertObject() {
        let testPoints = 10
        let testFrame = CGRect(x: 0, y: 0, width: 320, height: 480)
        let testQuad = QuadTree<Int>(frame: testFrame)

        for i in 0..<testPoints {
            let testX = Int(arc4random_uniform(320))
            let testY = Int(arc4random_uniform(480))
            let testPoint = CGPoint(x: testX, y: testY)
            XCTAssert(testQuad.insertObject(i, atPoint: testPoint), "Passed insertObject")
        }
    }

    func testQuadTreeInsertObjectPerformance() {
        let testPoints = 10
        let testFrame = CGRect(x: 0, y: 0, width: 320, height: 480)
        let testQuad = QuadTree<Int>(frame: testFrame)

        self.measure() {
            for i in 0 ..< testPoints {
                let testX = Int(arc4random_uniform(320))
                let testY = Int(arc4random_uniform(480))
                let testPoint = CGPoint(x: testX, y: testY)
                testQuad.insertObject(i, atPoint: testPoint)
            }
        }
    }

    func testQuadTreeQueryRegion() {
        let testPoints = 10
        let testFrame = CGRect(x: 0, y: 0, width: 320, height: 480)
        let testQuad = QuadTree<Int>(frame: testFrame)

        for i in 0 ..< testPoints {
            let testX = Int(arc4random_uniform(320))
            let testY = Int(arc4random_uniform(480))
            let testPoint = CGPoint(x: testX, y: testY)
            testQuad.insertObject(i, atPoint: testPoint)
        }

        let objectArray = testQuad.queryRegion(testFrame)
        XCTAssert(objectArray.count == testPoints, "Query Region contains all points")
    }

    func testQuadTreeQueryRegionPerformance() {
        let testPoints = 10
        let testFrame = CGRect(x: 0, y: 0, width: 320, height: 480)
        let testQuad = QuadTree<Int>(frame: testFrame)

        for i in 0 ..< testPoints {
            let testX = Int(arc4random_uniform(320))
            let testY = Int(arc4random_uniform(480))
            let testPoint = CGPoint(x: testX, y: testY)
            testQuad.insertObject(i, atPoint: testPoint)
        }

        self.measure() {
            testQuad.queryRegion(testFrame)
        }
    }
}
