import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: -tableView in tableViewController property
//    let fullsize = UIScreen.main.bounds.size
    let myFormatter = DateFormatter()
    let myRefreshControl = UIRefreshControl()    //建立UIRefreshControl，存在常數myRefreshControl中
    
    var dicRow = [String:Any?]()    //記錄單一資料行（離線資料集）
    var currentDate: Date = Date()
    var myRecords: [String:[[String:Any?]]] = [:]    //記錄查詢到的資料表
    var db: OpaquePointer? = nil    //資料庫連線（從AppDelegate取得）
    var days: [String]! = []
//    var selectedId = 0
    // MARK: -tableView in viewController property
//    @IBOutlet weak var lblCurrentYearMonth: UILabel!
        //先將tableView建立屬性
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {    //從AppDelegate取得資料庫連線
            db = appDelegate.getDB()
//            print("連線成功１")
        }
        getDataFromDB()    //準備離線資料集(呼叫讀取資料庫資料的函式)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.refreshControl = myRefreshControl    //產生下拉更新元件
        self.myRefreshControl.addTarget(self, action: #selector(self.refreshList), for: .valueChanged)    //對應下拉更新的事件
        tableView.refreshControl?.attributedTitle = NSAttributedString(string: "更新中...")    //指定下拉更新的附帶文字
        
//        tableView.contentOffset = CGPoint(x: 0.0, y: 44.0)
    }
    //由導覽線換頁時
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segue1" {
            let postVC = segue.destination as! PostViewController
            postVC.tableViewController = self    //傳遞第一頁的執行實體給第二頁（引用型別傳遞）
            
            guard let rowIndex = tableView.indexPathForSelectedRow else {
                return
            }
//            print(rowIndex.row)
            postVC.selectedRow = rowIndex.row
            postVC.postRecords = days[rowIndex.section]
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getDataFromDB()
//        tableView.reloadData()    //畫面重現時，請TableView立即重整資料
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
        tableView.reloadData()
    }
    // MARK: Table view data source
    //要顯示幾個Section(建立幾筆陣列資料這需更動)
    func numberOfSections(in tableView: UITableView) -> Int {
        return days.count
    }
    //Section裡面要顯示的row數
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let date = days[section]
        guard let records = myRecords[date] else {
            return 0
        }
        return records.count
    }
    //每一列TableViewCell要顯示的資料
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCellController    //先產出cell
        
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

    //為多個section增加title
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return days[section]
    }
    //設定section title(header)的高度
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    //得知選擇了哪個row, section
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //選擇(點擊)後會變灰色，得取消選擇才復原
        tableView.deselectRow(at: indexPath, animated: true)
        
//        self.navigationController?.pushViewController(PostViewController(), animated: true)
    }
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//            tableView.reloadData()
//    }
    // MARK: Functional Methods
    //MARK: -tableView refresh
    //refreshList方法裡要把更新後的資料存進tableDate裡
    //讓tableView執行reloadData方法更新資料
    //使用UIRefresh的endRreshing方法，讓refreshController停止轉動並隱藏
    func refreshList() {

        getDataFromDB()
        tableView.reloadData()
        myRefreshControl.endRefreshing()
    }
    //MARK: -Buttons
    @IBAction func btnChange(_ sender: UIButton) {
//        self.dismiss(animated: true, completion: nil)
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let tableVC = mainStoryboard.instantiateViewController(withIdentifier: "collectionView")
        self.navigationController?.pushViewController(tableVC, animated: true)
//        print("tableView被釋放")
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
//        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let addViewController = storyboard?.instantiateViewController(withIdentifier: "AddView") as! AddViewController
        addViewController.tableViewController = self
        self.navigationController?.pushViewController(addViewController, animated: true)
//        show(addViewController, sender: nil)
    }
}

