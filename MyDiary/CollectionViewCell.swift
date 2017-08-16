import UIKit

class CollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imgPicture: UIImageView!
    @IBOutlet weak var txtView: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblWeek: UILabel!
    @IBOutlet fileprivate weak var imageViewHeightLayoutConstraint: NSLayoutConstraint!
    
    
}
