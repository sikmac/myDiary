import UIKit

class CollectionVController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    // MARK: -collectionView in collectionViewController property
    @IBOutlet weak var collectionView: UICollectionView!
    let myRefreshControl = UIRefreshControl()
    var myRecords :[String:[[String:Any?]]] = [:]
    var days: [String]! = []
    
    var db:OpaquePointer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            db = appDelegate.getDB()
        }
        getDataFromDB()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.refreshControl = myRefreshControl
        self.myRefreshControl.addTarget(self, action: #selector(self.refreshList), for: .valueChanged)
        collectionView.refreshControl?.attributedTitle = NSAttributedString(string: "更新中...")
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
        self.getDataFromDB()
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
        collectionView.reloadData()
    }
    //MARK: -collectionView refresh
    func refreshList() {
        getDataFromDB()
        collectionView.reloadData()
        myRefreshControl.endRefreshing()
    }
    //MARK: -Buttons
    @IBAction func btnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
        print("collection被釋放")
    }
//    @IBAction func btnSettings(_ sender: UIBarButtonItem) {
//        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        let settingsViewController = mainStoryboard.instantiateViewController(withIdentifier: "SettingsView")
//        self.navigationController?.pushViewController(settingsViewController, animated: true)
//    }
//    @IBAction func btnSettings(_ sender: UIBarButtonItem) {
//        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        let settingsViewController = mainStoryboard.instantiateViewController(withIdentifier: "SettingsView")
//        self.navigationController?.pushViewController(settingsViewController, animated: true)
//    }
    @IBAction func btnAdd(_ sender: UIButton) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let addViewController = mainStoryboard.instantiateViewController(withIdentifier: "AddView")
        self.navigationController?.pushViewController(addViewController, animated: true)
    }
}
