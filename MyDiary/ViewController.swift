import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: -tableView in tableViewController property
    let myFormatter = DateFormatter()
    let myRefreshControl = UIRefreshControl()
    
    var dicRow = [String:Any?]()
    var currentDate: Date = Date()
    var myRecords: [String:[[String:Any?]]] = [:]
    var db: OpaquePointer? = nil
    var days: [String]! = []
    
    @IBOutlet var tableView: UITableView!
//    //MARK: -側滑menu元件
//    var mainNavigationController:UINavigationController!    // 主页导航控制器
////    var self = self    // 主页面控制器
//    var menuViewController:SettingsViewController?    // 菜单页控制器
//    
//    // 菜单页当前状态
//    var currentState = MenuState.collapsed {
//        didSet {
//            //菜单展开的时候，给主页面边缘添加阴影
//            let shouldShowShadow = currentState != .collapsed
//            showShadowForMainViewController(shouldShowShadow)
//        }
//    }
//    let menuViewExpandedOffset: CGFloat = 60    // 菜单打开后主页在屏幕右侧露出部分的宽度
//    //==========================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            db = appDelegate.getDB()
        }
        getDataFromDB()
        
        tableView.delegate = self
        tableView.dataSource = self
        
//        tableView.refreshControl = myRefreshControl
//        self.myRefreshControl.addTarget(self, action: #selector(ViewController.refreshList), for: .valueChanged)
//        tableView.refreshControl?.attributedTitle = NSAttributedString(string: "更新中...")
//        tableView.contentOffset = CGPoint(x: 0.0, y: 44.0)
////MARK: -側滑menu元件
//        //初始化主视图
//        mainNavigationController = UIStoryboard(name: "Main", bundle: nil)
//            .instantiateViewController(withIdentifier: "tableView") as! UINavigationController
//        view.addSubview(mainNavigationController.view)
//        
////        //指定Navigation Bar左侧按钮的事件
////        self = mainNavigationController.viewControllers.first //as! MainViewController
////        self.navigationItem.leftBarButtonItem?.action = #selector(ViewController.showMenu)
//        
//        //添加拖动手势
//        let panGestureRecognizer = UIPanGestureRecognizer(target: self,
//                                                          action: #selector(ViewController.handlePanGesture(_:)))
//        mainNavigationController.view.addGestureRecognizer(panGestureRecognizer)
//        
//        //单击收起菜单手势
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
//                                                          action: #selector(ViewController.handlePanGesture as (ViewController) -> () -> ()))
//        mainNavigationController.view.addGestureRecognizer(tapGestureRecognizer)
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
//    //导航栏左侧按钮事件响应
//    func showMenu() {
//        //如果菜单是展开的则会收起，否则就展开
//        if currentState == .expanded {
//            animateMainView(false)
//        }else {
//            addMenuViewController()
//            animateMainView(true)
//        }
//    }
//    
//    //拖动手势响应
//    func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
//        
//        switch(recognizer.state) {
//        // 刚刚开始滑动
//        case .began:
//            // 判断拖动方向
//            let dragFromLeftToRight = (recognizer.velocity(in: view).x > 0)
//            // 如果刚刚开始滑动的时候还处于主页面，从左向右滑动加入侧面菜单
//            if (currentState == .collapsed && dragFromLeftToRight) {
//                currentState = .expanding
//                addMenuViewController()
//            }
//            
//        // 如果是正在滑动，则偏移主视图的坐标实现跟随手指位置移动
//        case .changed:
//            let positionX = recognizer.view!.frame.origin.x +
//                recognizer.translation(in: view).x
//            //页面滑到最左侧的话就不许要继续往左移动
//            recognizer.view!.frame.origin.x = positionX < 0 ? 0 : positionX
//            recognizer.setTranslation(CGPoint.zero, in: view)
//            
//        // 如果滑动结束
//        case .ended:
//            //根据页面滑动是否过半，判断后面是自动展开还是收缩
//            let hasMovedhanHalfway = recognizer.view!.center.x > view.bounds.size.width
//            animateMainView(hasMovedhanHalfway)
//        default:
//            break
//        }
//    }
//    
//    //单击手势响应
//    func handlePanGesture() {
//        //如果菜单是展开的点击主页部分则会收起
//        if currentState == .expanded {
//            animateMainView(false)
//        }
//    }
//    
//    // 添加菜单页
//    func addMenuViewController() {
//        if (menuViewController == nil) {
//            menuViewController = UIStoryboard(name: "Main", bundle: nil)
//                .instantiateViewController(withIdentifier: "menuView") as? MenuViewController
//            
//            // 插入当前视图并置顶
//            view.insertSubview(menuViewController!.view, at: 0)
//            
//            // 建立父子关系
//            addChildViewController(menuViewController!)
//            menuViewController!.didMove(toParentViewController: self)
//        }
//    }
//    
//    //主页自动展开、收起动画
//    func animateMainView(_ shouldExpand: Bool) {
//        // 如果是用来展开
//        if (shouldExpand) {
//            // 更新当前状态
//            currentState = .expanded
//            // 动画
//            animateMainViewXPosition(mainNavigationController.view.frame.width -
//                menuViewExpandedOffset)
//        } else {     // 如果是用于隐藏
//            // 动画
//            animateMainViewXPosition(0) { finished in
//                // 动画结束之后s更新状态
//                self.currentState = .collapsed
//                // 移除左侧视图
//                self.menuViewController?.view.removeFromSuperview()
//                // 释放内存
//                self.menuViewController = nil;
//            }
//        }
//    }
//
//    //主页移动动画（在x轴移动）
//    func animateMainViewXPosition(_ targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
//        //usingSpringWithDamping：1.0表示没有弹簧震动动画
//        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0,
//                       initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
//                        self.mainNavigationController.view.frame.origin.x = targetPosition
//        }, completion: completion)
//    }
//    
//    //给主页面边缘添加、取消阴影
//    func showShadowForMainViewController(_ shouldShowShadow: Bool) {
//        if (shouldShowShadow) {
//            mainNavigationController.view.layer.shadowOpacity = 0.8
//        } else {
//            mainNavigationController.view.layer.shadowOpacity = 0.0
//        }
//    }
//}
//
//// 菜单状态枚举
//enum MenuState {
//    case collapsed  // 未显示(收起)
//    case expanding   // 展开中
//    case expanded   // 展开
//}

    //MARK: -tableView refresh
    func refreshList() {
        getDataFromDB()
        tableView.reloadData()
        myRefreshControl.endRefreshing()
    }
    //MARK: -Buttons
    @IBAction func btnChange(_ sender: UIButton) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let tableVC = mainStoryboard.instantiateViewController(withIdentifier: "collectionView")
        self.navigationController?.pushViewController(tableVC, animated: true)
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
    @IBAction func btnAdd(_ sender: UIBarButtonItem) {
        let addViewController = storyboard?.instantiateViewController(withIdentifier: "AddView") as! AddViewController
        addViewController.tableViewController = self
        self.navigationController?.pushViewController(addViewController, animated: true)
    }
    
//    @IBAction func btnAdd(_ sender: UIButton) {
//        let addViewController = storyboard?.instantiateViewController(withIdentifier: "AddView") as! AddViewController
//        addViewController.tableViewController = self
//        self.navigationController?.pushViewController(addViewController, animated: true)
//    }


}
