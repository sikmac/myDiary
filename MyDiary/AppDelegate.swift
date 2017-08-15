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
                
                let sql = "create table if not exists records (Id INTEGER primary key autoincrement,YearMonth TEXT,CreateDate TEXT,CreateWeek TEXT,CreateTime DATETIME,Photo BLOB,TextView TEXT)"
                if sqlite3_exec(db, sql.cString(using: String.Encoding.utf8), nil, nil, nil) == SQLITE_OK {
//                    print("Success11111!")
                } else {
//                    print ("Failed11111!")
                }
            }
        } else if sqlite3_open(destinationDB, &db) == SQLITE_OK {
//            print("資料庫開啟成功！")
        } else {
//            print("資料庫開啟失敗！")
            db = nil
        }
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

