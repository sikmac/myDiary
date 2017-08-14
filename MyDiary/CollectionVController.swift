import UIKit

class CollectionVController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    // MARK: -collectionView in collectionViewController property
    @IBOutlet weak var collectionView: UICollectionView!    //先將collectionView建立屬性
    
    let myRefreshControl = UIRefreshControl()    //建立UIRefreshControl，存在常數myRefreshControl中
    var myRecords :[String:[[String:Any?]]] = [:]
    var days: [String]! = []
    
    var db:OpaquePointer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {    //從AppDelegate取得資料庫連線
            db = appDelegate.getDB()
            //            print("連線成功１")
        }
        getDataFromDB()    //準備離線資料集(呼叫讀取資料庫資料的函式)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.refreshControl = myRefreshControl
        self.myRefreshControl.addTarget(self, action: #selector(self.refreshList), for: .valueChanged)
        collectionView.refreshControl?.attributedTitle = NSAttributedString(string: "更新中...")    //指定下拉更新的附帶文字
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segue2" {
            let postVC = segue.destination as! PostViewController
            postVC.collectionViewController = self    //傳遞第一頁的執行實體給第二頁（引用型別傳遞）
            
            guard let indexPath = collectionView.indexPathsForSelectedItems else {
                return
            }
//            print(indexPath[0].section)
//            print(rowIndex.first!)
//            let date = days[section]
//            guard let records = myRecords[date] else {
//                return
//            }
//            postVC.postRecords = records[section]

//            postVC.selectedRow = rowIndex
//            print(rowIndex)
            postVC.selectedItem = indexPath[0].row
            postVC.postItemRecords = days[indexPath[0].section]
//            postVC.
        }
    }
    //要顯示幾個Section(建立幾筆陣列資料這需更動)
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return days.count
    }
    //Section裡面要顯示的Item數
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let date = days[section]
        guard let records = myRecords[date] else {
            return 0
        }
        return records.count
    }
    //每一列collectionViewItem要顯示的資料
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CVCell", for: indexPath) as! CollectionViewCell   //先產出cell
        let date = days[indexPath.section]
        guard let records = myRecords[date] else {
            return cell
        }
        
        // 顯示的內容
        cell.lblDate.text = records[indexPath.row]["CreateDate"] as? String
        cell.lblWeek.text = records[indexPath.row]["CreateWeek"] as? String
        cell.txtView.text = records[indexPath.row]["TextView"] as? String
        cell.imgPicture.image = UIImage(data: ((records[indexPath.row]["Photo"]) as? Data)!)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        //        let headerView = collectionView.dequeueReusableSupplementaryView（ofKind:kind withReuseIdentifier："myDiaryHeaderView" for:indexPath）as! MyDiaryHeaderViewCollectionReusableView
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
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //        print("selected section: \(indexPath.section)")
        //        print("selected: \(indexPath.item)")
        //        if indexPath.section == 0 {
        //            print("selected name:\(diaryArray[indexPath.row])")
        //        } else {
        //            print("selected name:\(diarySecondArray[indexPath.row])")
        //        }
    }
    func getDataFromDB() {
        //清除所有的陣列元素
        days.removeAll()
        myRecords.removeAll()        //arrTable = [[String:Any?]]()
        let sql = "SELECT Id,YearMonth,CreateDate,CreateWeek,CreateTime,Photo,TextView FROM records ORDER BY YearMonth DESC, CreateTime DESC"    //準備查詢指令
        var statement:OpaquePointer? = nil    //宣告查詢結果的變數（連線資料集）
        sqlite3_prepare(db, sql.cString(using: String.Encoding.utf8), -1, &statement, nil)    //執行查詢指令（-1代表不限定sql指令的長度，最後一個參數為預留參數，目前沒有作用）
        //往下讀一筆，如果讀到資料時
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int(statement, 0)
            //            print("id:\(id)")
            let sYearMonth = sqlite3_column_text(statement, 1)
            let yearMonth = String(cString: sYearMonth!)
            //            print("yearMonth:\(yearMonth)")
            let sCreateDate = sqlite3_column_text(statement, 2)
            let createDate = String(cString: sCreateDate!)
            //            print("createDate:\(createDate)")
            let sCreateWeek = sqlite3_column_text(statement, 3)
            let createWeek = String(cString: sCreateWeek!)
            //            print("createWeek:\(createWeek)")
            let sCreateTime = sqlite3_column_text(statement, 4)
            let createTime = String(cString: sCreateTime!)
            //            print("createWeek:\(createTime)")
            
            //取得第四個欄位（照片）
            var imgData:Data?    //用於記載檔案的每一個位元資料
            if let totalBytes = sqlite3_column_blob(statement, 5) {    //讀取檔案每一個位元的資料
                let length = sqlite3_column_bytes(statement, 5)     //讀取檔案長度
                imgData = Data(bytes: totalBytes, count: Int(length))    //將數位圖檔資訊，初始化成為Data物件
            }
            let textView = String(cString: (sqlite3_column_text(statement, 6))!)    //轉換第二個欄位（swift字串）
            if yearMonth != "" {
                //                print("1days:\(days)")
                if !days.contains(yearMonth) {
                    //                    print("2days:\(days)")
                    days.append(yearMonth)
                    //                    print("3days:\(days)")
                    myRecords[yearMonth] = []
                }
                //                myRecords[yearMonth]?.append([
                myRecords[yearMonth]?.append([
                    "Id":"\(id)",
                    "CreateDate":"\(createDate)",
                    "CreateWeek":"\(createWeek)",
                    "Photo":imgData,
                    "TextView":"\(textView)",
                    "CreateTime":"\(createTime)"
                    ])
                //print("dic array:\(dicRow)")
                //                myRecords[yearMonth]?.append(dicRow)
                //                print("myRecords：\(myRecords)")
                
            }
        }
        sqlite3_finalize(statement)    //關閉連線資料集
        //                print("myRecords：\(myRecords)")
        collectionView.reloadData()
    }
    //MARK: -collectionView refresh
    //refreshList方法裡要把更新後的資料存進collectionDate裡
    //讓collectionView執行reloadData方法更新資料
    //使用UIRefresh的endRreshing方法，讓refreshController停止轉動並隱藏
    func refreshList() {
        //        diaryArray = diarySecondArray
        //        diarySecondArray = diaryRefreshArray
        getDataFromDB()
        collectionView.reloadData()
        myRefreshControl.endRefreshing()
    }
    //MARK: -Buttons
    @IBAction func btnBack(_ sender: UIButton) {
        //self.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
        print("collection被釋放")
    }
    @IBAction func btnCalender(_ sender: UIBarButtonItem) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let calenderViewController = mainStoryboard.instantiateViewController(withIdentifier: "CalenderView")
        self.navigationController?.pushViewController(calenderViewController, animated: true)
    }
    @IBAction func btnSettings(_ sender: UIBarButtonItem) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let settingsViewController = mainStoryboard.instantiateViewController(withIdentifier: "SettingsView")
        self.navigationController?.pushViewController(settingsViewController, animated: true)
    }
    @IBAction func btnAdd(_ sender: UIButton) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let addViewController = mainStoryboard.instantiateViewController(withIdentifier: "AddView")
        self.navigationController?.pushViewController(addViewController, animated: true)
    }
    
}
