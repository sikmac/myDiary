import UIKit

class TableViewCellController: UITableViewCell {

    @IBOutlet weak var imgPicture: UIImageView!
    @IBOutlet weak var txtView: UILabel!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblWeek: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }

}
