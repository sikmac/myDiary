import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    private var db:OpaquePointer? = nil    //宣告資料庫連線變數
    
    func getDB() -> OpaquePointer? {
        return db
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let destinationDB = NSHomeDirectory() + "/Documents/sqlite3.db"    //取得資料庫的目的地路徑
        print("path：\(destinationDB)")
        //檢查目的地的資料庫是否已經存在
        if !FileManager.default.fileExists(atPath: destinationDB) {    //如果不存在
            if sqlite3_open(destinationDB, &db) == SQLITE_OK {
                print("Success!")
                let sql = "create table if not exists records (Id INTEGER primary key autoincrement,YearMonth TEXT,MonthDate TEXT,CreateDate TEXT,CreateWeek TEXT,CreateTime DATETIME,Photo BLOB,TextView TEXT)"
                if sqlite3_exec(db, sql.cString(using: String.Encoding.utf8), nil, nil, nil) == SQLITE_OK {
                } else {
                }
            }
        } else if sqlite3_open(destinationDB, &db) == SQLITE_OK {
        } else {
            db = nil
        }
        // 設定導覽列預設底色
        UINavigationBar.appearance().barTintColor = UIColor.init(red: 0.3, green: 0.59, blue: 0.8, alpha: 1)
        
        // 設定導覽列預設按鈕顏色
        UINavigationBar.appearance().tintColor = UIColor.white
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        sqlite3_close(db)    //關閉資料庫
    }
    
}

