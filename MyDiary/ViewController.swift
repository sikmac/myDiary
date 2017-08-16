import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: -tableView in tableViewController property
    let myFormatter = DateFormatter()
    let myRefreshControl = UIRefreshControl()
    
    var db: OpaquePointer? = nil
    var dicRow = [String:Any?]()
    var currentDate: Date = Date()
    var myRecords: [String:[[String:Any?]]] = [:]
    var days: [String]! = []
    
    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            db = appDelegate.getDB()
        }
        getDataFromDB()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
        
//        tableView.refreshControl = myRefreshControl
//        self.myRefreshControl.addTarget(self, action: #selector(ViewController.refreshList), for: .valueChanged)
//        tableView.refreshControl?.attributedTitle = NSAttributedString(string: "更新中...")
//        tableView.contentOffset = CGPoint(x: 0.0, y: 44.0)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segue1" {
            let postVC = segue.destination as! PostViewController
            postVC.tableViewController = self
            
            guard let rowIndex = tableView.indexPathForSelectedRow else {
                return
            }
            postVC.selectedRow = rowIndex.row
            postVC.postRecords = days[rowIndex.section]
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getDataFromDB()
//        tableView.reloadData()

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
        tableView.reloadData()
    }
    // MARK: Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return days.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let date = days[section]
        guard let records = myRecords[date] else {
            return 0
        }
        return records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCellController
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

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return days[section]
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    //MARK: -tableView refresh
//    func refreshList() {
//        getDataFromDB()
//        tableView.reloadData()
//        myRefreshControl.endRefreshing()
//    }
    //MARK: -Buttons
    @IBAction func btnChange(_ sender: UIButton) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let tableVC = mainStoryboard.instantiateViewController(withIdentifier: "collectionView")
        self.navigationController?.pushViewController(tableVC, animated: true)
    }
    @IBAction func btnSettings(_ sender: UIBarButtonItem) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let settingsViewController = mainStoryboard.instantiateViewController(withIdentifier: "SettingsView")
        self.navigationController?.pushViewController(settingsViewController, animated: true)
    }
    @IBAction func btnAdd(_ sender: UIBarButtonItem) {
        let addViewController = storyboard?.instantiateViewController(withIdentifier: "AddView") as! AddViewController
        addViewController.tableViewController = self
        self.navigationController?.pushViewController(addViewController, animated: true)
    }
}
