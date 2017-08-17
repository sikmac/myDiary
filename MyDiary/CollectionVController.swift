import UIKit
import AVFoundation

class CollectionVController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    // MARK: -collectionView in collectionViewController property
    let myRefreshControl = UIRefreshControl()
    
    var myRecords :[String:[[String:Any?]]] = [:]
    var days: [String]! = []
    var db:OpaquePointer? = nil
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            db = appDelegate.getDB()
        }
        getDataFromDB()
        
        let width = collectionView.frame.width / 2
        let layout = collectionView.collectionViewLayout as! PinterestLayout
        layout.cellPadding = 5
        layout.delegate = self
        layout.numberOfColumns = 2
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
        self.collectionView.reloadData()
        layout.invalidateLayout()
//        self.collectionView!.collectionViewLayout.invalidateLayout()
        
        //        let context = collectionView.collectionViewLayout.invalidationContext(forBoundsChange: collectionView.bounds)
        //        context.contentOffsetAdjustment = CGPoint.zero
        //        collectionView.collectionViewLayout.invalidateLayout(with: context)
        //        collectionView.layoutSubviews()
        
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
            postVC.postRecords = days[indexPath[0].section]
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //        let layout = collectionView.collectionViewLayout as! PinterestLayout
        //        layout.delegate = self
        getDataFromDB()
        //        self.collectionView.reloadData()
        //        self.collectionView!.collectionViewLayout.invalidateLayout()
    }
    func getDataFromDB() {
        days.removeAll()
        myRecords.removeAll()
        let sql = "SELECT Id,YearMonth,CreateDate,CreateWeek,CreateTime,Photo,TextView FROM records ORDER BY YearMonth DESC, CreateTime DESC"
        var statement:OpaquePointer? = nil
        sqlite3_prepare(db, sql.cString(using: String.Encoding.utf8), -1, &statement, nil)
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int(statement, 0)
            
            let sYearMonth = sqlite3_column_text(statement, 1)
            let yearMonth = String(cString: sYearMonth!)
            
            let sCreateDate = sqlite3_column_text(statement, 2)
            let createDate = String(cString: sCreateDate!)
            
            let sCreateWeek = sqlite3_column_text(statement, 3)
            let createWeek = String(cString: sCreateWeek!)
            
            let sCreateTime = sqlite3_column_text(statement, 4)
            let createTime = String(cString: sCreateTime!)
            
            var imgData:Data?
            if let totalBytes = sqlite3_column_blob(statement, 5) {
                let length = sqlite3_column_bytes(statement, 5)
                imgData = Data(bytes: totalBytes, count: Int(length))
            }
            let textView = String(cString: (sqlite3_column_text(statement, 6))!)
            if yearMonth != "" {
                if !days.contains(yearMonth) {
                    days.append(yearMonth)
                    myRecords[yearMonth] = []
                }
                myRecords[yearMonth]?.append([
                    "Id":"\(id)",
                    "CreateDate":"\(createDate)",
                    "CreateWeek":"\(createWeek)",
                    "Photo":imgData,
                    "TextView":"\(textView)",
                    "CreateTime":"\(createTime)"
                    ])
            }
        }
        sqlite3_finalize(statement)
        self.collectionView.reloadData()
        //        self.collectionView!.collectionViewLayout.invalidateLayout()
        //        collectionView!.collectionViewLayout.invalidateLayout()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return days.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let date = days[section]
        guard let records = myRecords[date] else {
            return 0
        }
        return records.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CVCell", for: indexPath) as! CollectionViewCell
        let date = days[indexPath.section]
        guard let records = myRecords[date] else {
            return cell
        }
        
        cell.lblDate.text = records[indexPath.row]["CreateDate"] as? String
        cell.lblWeek.text = records[indexPath.row]["CreateWeek"] as? String
        cell.txtView.text = records[indexPath.row]["TextView"] as? String
        cell.imgPicture.image = UIImage(data: ((records[indexPath.row]["Photo"]) as? Data)!)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "myDiaryHeaderView", for: indexPath) as! MyDiaryHeaderViewCollectionReusableView
            headerView.lblHeader.textColor = UIColor.lightGray
            headerView.lblHeader.adjustsFontSizeToFitWidth = true
            headerView.lblHeader.text = days[indexPath.section]
            
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
    }
    //MARK: -collectionView refresh
    //    func refreshList() {
    //        getDataFromDB()
    //        collectionView.reloadData()
    //        myRefreshControl.endRefreshing()
    //    }
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

extension CollectionVController: PinterestLayoutDelegate {
        func collectionView(collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: NSIndexPath, withWidth: CGFloat) -> CGFloat {
            let random = arc4random_uniform(4) + 1
            return CGFloat(random * 100)
        }
        func collectionView(collectionView: UICollectionView, heightForAnnotationAtIndexPath indexPath: NSIndexPath, withWidth: CGFloat) -> CGFloat {
            let random = arc4random_uniform(4) + 1
            return 60
        }
//    func collectionView(collectionView: UICollectionView, heightForItemAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        let random = arc4random_uniform(4) + 1
//        return CGFloat(random * 100)
//    }
    
}
