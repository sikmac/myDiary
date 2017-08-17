import UIKit

protocol PinterestLayoutDelegate {
        func collectionView(collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat
        func collectionView(collectionView: UICollectionView, heightForAnnotationAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat
//    func collectionView(collectionView: UICollectionView, heightForItemAtIndexPath indexPath: NSIndexPath) -> CGFloat
}

class PinterestLayoutAttributes: UICollectionViewLayoutAttributes {
    
    var photoHeight: CGFloat = 0.0
    
    override func copy(with zone: NSZone?) -> Any {
        let copy = super.copy(with: zone) as! PinterestLayoutAttributes
        copy.photoHeight = photoHeight
        return copy
    }
    
    
    func isEqual(object: AnyObject?) -> Bool {
        if let attributes = object as? PinterestLayoutAttributes {
            if( attributes.photoHeight == photoHeight  ) {
                return super.isEqual(object)
            }
        }
        return false
    }
}

class PinterestLayout: UICollectionViewLayout {
    
    var cellPadding: CGFloat = 0    //
    var delegate: PinterestLayoutDelegate!
    var numberOfColumns = 1
    

    
    private var cache = [PinterestLayoutAttributes]()
    
    private var contentHeight: CGFloat = 0.0
    private var width: CGFloat {
        get {
            let insets = collectionView!.contentInset
            return collectionView!.bounds.width - (insets.left + insets.right)
//            return collectionView!.bounds.width
        }
    }
    
    override class var layoutAttributesClass : AnyClass {
        return PinterestLayoutAttributes.self
    }
    override var collectionViewContentSize: CGSize {
        return CGSize(width: width, height: contentHeight)
    }
    override func prepare() {
        if cache.isEmpty{
            let columnWidth = width / CGFloat(numberOfColumns)
            
            var xOffset = [CGFloat]()
            
            for column in 0 ..< numberOfColumns {
                xOffset.append(CGFloat(column) * columnWidth)
            }
            var yOffset = [CGFloat](repeating: 0, count: numberOfColumns)
            var column = 0
            for item in 0..<collectionView!.numberOfItems(inSection: 0) {
                let indexPath = NSIndexPath(item: item, section: 0)
                
            let width = columnWidth - cellPadding * 2
            let photoHeight = delegate.collectionView(collectionView: collectionView!, heightForPhotoAtIndexPath: indexPath, withWidth: width)
            let annotationHeight = delegate.collectionView(collectionView: collectionView!, heightForAnnotationAtIndexPath: indexPath, withWidth: width)
            let height = cellPadding + photoHeight + annotationHeight + cellPadding
//改寫                let height = delegate.collectionView(collectionView: collectionView!, heightForItemAtIndexPath: indexPath)
                let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
                let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
                let attributes = PinterestLayoutAttributes(forCellWith: indexPath as IndexPath)
                attributes.frame = insetFrame
                attributes.photoHeight = photoHeight
                cache.append(attributes)
                contentHeight = max(contentHeight, frame.maxY)
                yOffset[column] = yOffset[column] + height
                column = column >= (numberOfColumns - 1) ? 0 : column + 1
            }
        }
    }
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                layoutAttributes.append(attributes)
            }
        }
        return layoutAttributes
    }
    
    override func invalidateLayout() {
        super.invalidateLayout()
        cache.removeAll()
    }
}

