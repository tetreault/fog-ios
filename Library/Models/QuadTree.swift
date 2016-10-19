import UIKit

/**
 QuadTree class implementation following Wikipedia.
 Swift type T may be any object, similar to Array definition
 */
class QuadTree<T> {

    // MARK: Variable Declarations
    typealias Object = (T, CGPoint)

    /// Max number of objects stored by the quadrant
    let nodeCapacity = 4

    /// The boundary of the tree
    let boundary: CGRect!
    /// The objects contained in the quadrant
    var objects: [Object]!

    /// Child Quad Trees
    var northWest: QuadTree?
    var northEast: QuadTree?
    var southWest: QuadTree?
    var southEast: QuadTree?

    // MARK: - Class Functions
    /**
     Initializer for the QuadTree class

     :param: frame Boundary frame for the QuadTree

     :returns: QuadTree class
     */

    init(frame theBoundary: CGRect) {
        self.boundary = theBoundary
        self.objects = [Object]()
    }

    /**
     Inserts an object into the quad tree, dividing the tree if necessary

     :param: object Any object
     :param: atPoint location of the object

     :returns: true if object was added, false if not
     */
    @discardableResult
    func insertObject(_ object: T, atPoint point: CGPoint) -> Bool {
        // Check to see if the region contains the point
        if boundary.contains(point) == false {
            return false
        }

        // If there is enough space add the point
        if objects.count < nodeCapacity {
            objects.append((object, point))
            return true
        }

        // Otherwise, subdivide and add the point to whichever child will accept it
        if northWest == nil {
            subdivide()
        }

        if northWest != nil && northWest!.insertObject(object, atPoint: point) {
            return true
        } else if northEast != nil && northEast!.insertObject(object, atPoint: point) {
            return true
        } else if southWest != nil && southWest!.insertObject(object, atPoint: point) {
            return true
        } else if southEast != nil && southEast!.insertObject(object, atPoint: point) {
            return true
        }

        // If all else fails...
        return false
    }

    /**
     Querys all objects within a region of the QuadTree

     :param: region The region of interest
     :returns: Array of objects that lie within the region of interest
     */
    @discardableResult
    func queryRegion(_ region: CGRect) -> [T] {
        var objectsInRegion = [T]()

        if !(boundary.intersects(region)) {
            return objectsInRegion
        }

        for (object, point) in objects {
            if region.contains(point) {
                objectsInRegion.append(object)
            }
        }

        // If there are no children stop here
        if northWest == nil {
            return objectsInRegion
        }

        // Otherwise add the points from the children
        if northWest != nil {
            objectsInRegion += northWest!.queryRegion(region)
        }
        if northEast != nil {
            objectsInRegion += northEast!.queryRegion(region)
        }
        if southWest != nil {
            objectsInRegion += southWest!.queryRegion(region)
        }
        if southEast != nil {
            objectsInRegion += southEast!.queryRegion(region)
        }

        return objectsInRegion
    }

    // MARK: - Private Functions
    /**
     Function to subdivide a QuadTree into 4 smaller QuadTrees
     */
    fileprivate func subdivide() {
        let size = CGSize(width: boundary.width / 2.0, height: boundary.height / 2.0)

        northWest = QuadTree(frame: CGRect(origin: CGPoint(x: boundary.minX, y: boundary.minY), size: size))
        northEast = QuadTree(frame: CGRect(origin: CGPoint(x: boundary.midX, y: boundary.minY), size: size))
        southWest = QuadTree(frame: CGRect(origin: CGPoint(x: boundary.minX, y: boundary.midY), size: size))
        southEast = QuadTree(frame: CGRect(origin: CGPoint(x: boundary.midX, y: boundary.midY), size: size))
    }
}
