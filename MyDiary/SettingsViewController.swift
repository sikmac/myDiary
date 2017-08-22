import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
    let fullSize :CGSize = UIScreen.main.bounds.size
//    let myUserDefaults = UserDefaults.standard
//    var soundOpen:Int? = 0
//    var mySwitch :UISwitch!
    var myTableView :UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.view.backgroundColor = UIColor.black
//        self.navigationController?.navigationBar.isTranslucent = false

        self.automaticallyAdjustsScrollViewInsets = false
        self.title = "關於"
        
        // 建立 UITableView
        myTableView = UITableView(frame: CGRect(x: 0, y: 50, width: fullSize.width, height: fullSize.height), style: .grouped)
        myTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        myTableView.delegate = self
        myTableView.dataSource = self
        myTableView.allowsSelection = true
//        myTableView.backgroundColor = UIColor.black
        myTableView.separatorColor = UIColor.init(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
        self.view.addSubview(myTableView)
        
    }
    
    
    // MARK: Button actions
    
    func goFB() {
        let requestUrl = URL(string: "https://www.facebook.com/SIKMAC")
        UIApplication.shared.open(requestUrl!, options: ["":""], completionHandler: nil)
    }
    
//    func goIconSource() {
//        let requestUrl = URL(string: "http://www.flaticon.com/")
//        UIApplication.shared.open(requestUrl!, options: ["":""], completionHandler: nil)
//    }
    
    
    // MARK: UITableViewDelegate methods
    // 必須實作的方法：每一組有幾個 cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // 必須實作的方法：每個 cell 要顯示的內容
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 取得 tableView 目前使用的 cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
        
        cell.backgroundColor = UIColor(red: 0.8, green: 0.75, blue: 1.0, alpha: 1)
        
        let button = UIButton(frame: CGRect(x: 15, y: 0, width: fullSize.width, height: 40))
        button.setTitleColor(UIColor.white, for: .normal)
        button.contentHorizontalAlignment = .left
        
            button.addTarget(self, action: #selector(SettingsViewController.goFB), for: .touchUpInside)
            button.setTitle("在 Facebook 上與我們聯絡", for: .normal)
        
        cell.contentView.addSubview(button)
        
        return cell
    }
    
    // 點選 cell 後執行的動作
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 取消 cell 的選取狀態
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // 有幾組 section
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // 每個 section 的標題
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        var title = "來源"
//        if section == 0 {
//            title = "支援"
//        }
        
        return "支援"
    }
    
    // section header 樣式
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView: UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        headerView.textLabel!.textColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    }
    
}


