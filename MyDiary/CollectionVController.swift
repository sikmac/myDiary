import UIKit
import AVFoundation

class CollectionVController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, PinterestLayoutDelegate {
    // MARK: -collectionView in collectionViewController property
    let myRefreshControl = UIRefreshControl()
    
    var myCVRecords: [[String:Any?]] = []
    var days: [String]! = []
    var db:OpaquePointer? = nil
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            db = appDelegate.getDB()
        }
        getDataFromDB()
        
        let layout = collectionView.collectionViewLayout as! PinterestLayout
        layout.delegate = self
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        self.collectionView.reloadData()
        layout.invalidateLayout()
        
//        collectionView.refreshControl = myRefreshControl
//        self.myRefreshControl.addTarget(self, action: #selector(self.refreshList), for: .valueChanged)
//        collectionView.refreshControl?.attributedTitle = NSAttributedString(string: "更新中...")
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segue2" {
            let postVC = segue.destination as! PostViewController
            postVC.collectionViewController = self
            guard let indexPath = collectionView.indexPathsForSelectedItems else {
                return
            }
            postVC.selectedRow = indexPath[0].row
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getDataFromDB()
    }
    func getDataFromDB() {
        days.removeAll()
        myCVRecords.removeAll()
        let sql = "SELECT Id,MonthDate,CreateWeek,CreateTime,Photo,TextView FROM records ORDER BY MonthDate DESC, CreateTime DESC"
        print("sql:\(sql)")
        var statement:OpaquePointer? = nil
        sqlite3_prepare(db, sql.cString(using: String.Encoding.utf8), -1, &statement, nil)
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int(statement, 0)
            let sMonthDate = sqlite3_column_text(statement, 1)
            let monthDate = String(cString: sMonthDate!)
            let sCreateWeek = sqlite3_column_text(statement, 2)
            let createWeek = String(cString: sCreateWeek!)
            let sCreateTime = sqlite3_column_text(statement, 3)
            let createTime = String(cString: sCreateTime!)
            var imgData:Data?
            if let totalBytes = sqlite3_column_blob(statement, 4) {
                let length = sqlite3_column_bytes(statement, 4)
                imgData = Data(bytes: totalBytes, count: Int(length))
            }
            
            let textView = String(cString: (sqlite3_column_text(statement, 5))!)
            
            myCVRecords.append([
                "Id":"\(id)",
                "MonthDate":"\(monthDate)",
                "CreateWeek":"\(createWeek)",
                "Photo":imgData,
                "TextView":"\(textView)",
                "CreateTime":"\(createTime)"
                ])
        }
        sqlite3_finalize(statement)
        self.collectionView.reloadData()
        
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myCVRecords.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CVCell", for: indexPath) as! CollectionViewCell
        cell.lblDate.text = myCVRecords[indexPath.row]["MonthDate"] as? String
        cell.lblWeek.text = myCVRecords[indexPath.row]["CreateWeek"] as? String
        cell.txtView.text = myCVRecords[indexPath.row]["TextView"] as? String
        cell.imgPicture.image = UIImage(data: ((myCVRecords[indexPath.row]["Photo"]) as? Data)!)
        
        return cell
    }
        //MARK: -collectionView refresh
    //    func refreshList() {
    //        getDataFromDB()
    //        collectionView.reloadData()
    //        myRefreshControl.endRefreshing()
    //    }
    
    func collectionView(collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: NSIndexPath, withWidth: CGFloat) -> CGFloat {
        let photo = UIImage(data: ((myCVRecords[indexPath.row]["Photo"]) as? Data)!)?.decompressedImage
        let boundingRect = CGRect(x: 0, y: 0, width: withWidth, height: CGFloat(MAXFLOAT))
        let rect = AVMakeRect(aspectRatio: (photo?.size)!, insideRect: boundingRect)
        return rect.size.height
    }
    func collectionView(collectionView: UICollectionView, heightForAnnotationAtIndexPath indexPath: NSIndexPath, withWidth: CGFloat) -> CGFloat {
//        let annotationPadding = CGFloat(4)
//        let annotationHeaderHeight = CGFloat(17)
////        let photo = photos[indexPath.item]
////        let font = UIFont(name: "AvenirNext-Regular", size: 10)!
////        let commentHeight = photo.heightForComment(font, width: width)
//        let height = annotationPadding + annotationHeaderHeight + annotationPadding
//        return height
//        let random = arc4random_uniform(4) + 1
        return 60    //Date+Week的高度
        
    }
    
    //MARK: -Buttons
    @IBAction func btnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func btnSettings(_ sender: UIBarButtonItem) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let settingsViewController = mainStoryboard.instantiateViewController(withIdentifier: "SettingsView")
        self.navigationController?.pushViewController(settingsViewController, animated: true)
    }
    @IBAction func btnAdd(_ sender: UIBarButtonItem) {
        let addViewController = storyboard?.instantiateViewController(withIdentifier: "AddView") as! AddViewController
        addViewController.collectionViewController = self
        self.navigationController?.pushViewController(addViewController, animated: true)
    }
}

extension UIImage {
    var decompressedImage: UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        draw(at: CGPoint.zero)
        let decompressedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return decompressedImage!
    }
}

