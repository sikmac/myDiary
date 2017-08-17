import UIKit

class CollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imgPicture: UIImageView!
    @IBOutlet weak var txtView: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblWeek: UILabel!
    @IBOutlet fileprivate weak var imageViewHeightLayoutConstraint: NSLayoutConstraint!
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let attributes = layoutAttributes as? PinterestLayoutAttributes {
            imageViewHeightLayoutConstraint.constant = attributes.photoHeight
        }
    }
    
    
}
