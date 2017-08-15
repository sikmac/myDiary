import UIKit

class SlideMenuController: UIViewController {
    var mainNavigationController:UINavigationController!    // 主頁導覽控制器
    var mainViewController:ViewController!    // 主頁面控制器
    var menuViewController:SettingsViewController?    // 菜單頁控制器
    
    // 菜單頁當前狀態
    var currentState = MenuState.Collapsed {
        didSet {
            //菜單展開的时候，給主頁面邊緣添加陰影
            let shouldShowShadow = currentState != .Collapsed
            showShadowForMainViewController(shouldShowShadow: shouldShowShadow)
        }
    }
    
    // 菜單打開後主頁在屏幕右側露出部分的寬度
    let menuViewExpandedOffset: CGFloat = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //初始化主視圖
        mainNavigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainNavigaiton") as! UINavigationController
        view.addSubview(mainNavigationController.view)
        
        //指定Navigation Bar左側按鈕的事件
        mainViewController = mainNavigationController.viewControllers.first as! ViewController
        mainViewController.navigationItem.leftBarButtonItem?.action = #selector(SlideMenuController.showMenu)
        
        //添加拖動手勢
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: Selector(("handlePanGesture:")))
        mainNavigationController.view.addGestureRecognizer(panGestureRecognizer)
        
        //單擊收起菜單手勢
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SlideMenuController.handlePanGesture as (SlideMenuController) -> () -> ()))
        mainNavigationController.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    //導覽欄左側按鈕事件響應
    func showMenu() {
        //如果菜單是展開的則會收起，否則就展開
        if currentState == .Expanded {
            animateMainView(shouldExpand: false)
        }else {
            addMenuViewController()
            animateMainView(shouldExpand: true)
        }
    }
    
    //拖動手勢響應
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        switch(recognizer.state) {
        // 剛剛開始滑動
        case .began:
            // 判斷拖動方向
            let dragFromLeftToRight = (recognizer.velocity(in: view).x > 0)
            // 如果剛剛開始滑動的时候還處於主頁面，從左向右滑動加入側面菜單
            if (currentState == .Collapsed && dragFromLeftToRight) {
                currentState = .Expanding
                addMenuViewController()
            }
            
        // 如果是正在滑動，則偏移主視圖的座標實現跟隨手指位置移動
        case .changed:
            let positionX = recognizer.view!.frame.origin.x +
                recognizer.translation(in: view).x
            //頁面滑到最左側的話就不許要繼續往左移動
            recognizer.view!.frame.origin.x = positionX < 0 ? 0 : positionX
            recognizer.setTranslation(CGPoint.zero, in: view)
            
        // 如果滑動结束
        case .ended:
            //根據頁面滑動是否過半，判斷後面是自動展開還是收縮
            let hasMovedhanHalfway = recognizer.view!.center.x > view.bounds.size.width
            animateMainView(shouldExpand: hasMovedhanHalfway)
        default:
            break
        }
    }
    
    //單擊手勢響應
    func handlePanGesture() {
        //如果菜單是展開的點擊主頁部分則會收起
        if currentState == .Expanded {
            animateMainView(shouldExpand: false)
        }
    }
    
    // 添加菜單頁
    func addMenuViewController() {
        if (menuViewController == nil) {
            menuViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsView") as? SettingsViewController
            // 插入當前視圖並置顶
            view.insertSubview(menuViewController!.view, at: 0)
            
            // 建立父子關係
            addChildViewController(menuViewController!)
            menuViewController!.didMove(toParentViewController: self)
        }
    }
    
    //主頁自動展開、收起動畫
    func animateMainView(shouldExpand: Bool) {
        // 如果是用來展開
        if (shouldExpand) {
            // 更新當前狀態
            currentState = .Expanded
            // 動畫
            animateMainViewXPosition(targetPosition: mainNavigationController.view.frame.width -
                menuViewExpandedOffset)
        } else {    // 如果是用於隱藏
            // 動畫
            animateMainViewXPosition(targetPosition: 0) { finished in
                // 動畫结束之後更新狀態
                self.currentState = .Collapsed
                // 移除左側視圖
                self.menuViewController?.view.removeFromSuperview()
                // 釋放内存
                self.menuViewController = nil;
            }
        }
    }
    
    //主頁移動動畫（在x軸移動）
    func animateMainViewXPosition(targetPosition: CGFloat,
                                  completion: ((Bool) -> Void)! = nil) {
        //usingSpringWithDamping：1.0表示没有彈簧震動動畫
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping:1.0, initialSpringVelocity: 0, options: UIViewAnimationOptions(), animations: {
            self.mainNavigationController.view.frame.origin.x = targetPosition
        }, completion: completion)
    }
    
    //給主頁面邊緣添加、取消陰影
    func showShadowForMainViewController(shouldShowShadow: Bool) {
        if (shouldShowShadow) {
            mainNavigationController.view.layer.shadowOpacity = 0.8
        } else {
            mainNavigationController.view.layer.shadowOpacity = 0.0
        }
    }
}
// 菜單狀態
enum MenuState {
    case Collapsed  // 未顯示(收起)
    case Expanding   // 展開中
    case Expanded   // 展開
}
