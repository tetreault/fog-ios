public extension Collection where Index == Int {
    typealias InternalElement = Iterator.Element

    public func enumeratedWithCurrentAndNext() -> [(current: Iterator.Element, next: Iterator.Element)] {
        let count = self.count as! Int
        var enumeratedItems = [(InternalElement, InternalElement)]()

        for (index, item) in self.enumerated() {
            var nextItem: Iterator.Element? = .none
            let nextIndex = index + 1

            if nextIndex < count {
                nextItem = self[nextIndex]
                if let nextItem = nextItem {
                    enumeratedItems.append((item, nextItem))
                }
            }
        }

        return enumeratedItems
    }

    public func enumeratedPairs() -> [(current: Iterator.Element, next: Iterator.Element)] {
        let count = self.count as! Int
        var enumeratedItems = [(InternalElement, InternalElement)]()

        var i = 0
        while i < count {
            let item = self[i]
            var nextItem: Iterator.Element? = .none
            i += 1

            if i < count {
                nextItem = self[i]
                if let nextItem = nextItem {
                    enumeratedItems.append((item, nextItem))
                    i += 1
                }
            }
        }

        return enumeratedItems
    }
}
