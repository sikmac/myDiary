import UIKit

class PostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    let myFormatter = DateFormatter()
    
    weak var tableViewController: ViewController!    //記錄上一頁的執行實體
    weak var collectionViewController: CollectionVController!
    
    var db:OpaquePointer? = nil    //資料庫連線（從AppDelegate取得）
    var currentTextObjectYPosition:CGFloat = 0    //記錄目前輸入元件的Y軸底緣位置
    
    var selectedRow  = 0  //記錄上一頁選定的資料索引值
    var postRecords = ""
    
    var selectedItem = 0
    var postItemRecords = ""
    
    var dicCurrentRow: [String:Any?] = [:]
////    var myRecords: [String:[[String:Any?]]] = [:]
    var myDatePicker :UIDatePicker!

    @IBOutlet weak var txtDate: UITextField!
    @IBOutlet weak var imgPicture: UIImageView!
    @IBOutlet weak var txtView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            db = appDelegate.getDB()            
        }

        txtDate.delegate = self
        myFormatter.dateFormat = "yyyy-MM-dd HH:mm EEE"
        
////        print("selected：\(tableViewController.myRecords[postRecords]![selectedRow])")
////        print("selected：\(collectionViewController.myRecords[postItemRecords]![selectedItem])")
//        //記錄選定列的字典
        if self.tableViewController != nil {
            let dicCurrentRow = tableViewController.myRecords[postRecords]?[selectedRow]
            txtDate.text = dicCurrentRow?["CreateTime"] as? String
            txtView.text = dicCurrentRow?["TextView"] as! String
            guard let aPic = dicCurrentRow?["Photo"]! else {
                return
            }
            imgPicture.image = UIImage(data: aPic as! Data)
        } else {
            let dicCurrentRow = collectionViewController.myRecords[postItemRecords]?[selectedItem]
            txtDate.text = dicCurrentRow?["CreateTime"] as? String
            txtView.text = dicCurrentRow?["TextView"] as! String
            guard let aPic = dicCurrentRow?["Photo"]! else {
                return
            }
            imgPicture.image = UIImage(data: aPic as! Data)
        }
        
        // UIDatePicker
        myDatePicker = UIDatePicker()
        myDatePicker.datePickerMode = .dateAndTime
        myDatePicker.locale = Locale(identifier: "zh_TW")
        myDatePicker.date = myFormatter.date(from: txtDate.text!)!
        txtDate.inputView = myDatePicker
        
        // UIDatePicker 取消及完成按鈕
        let toolBar = UIToolbar()
        toolBar.barTintColor = UIColor.clear
        toolBar.sizeToFit()
        toolBar.barStyle = .default
        toolBar.tintColor = UIColor.white
        let cancelBtn = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(AddViewController.cancelTouched(_:)))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneBtn = UIBarButtonItem(title: "完成", style: .plain, target: self, action: #selector(AddViewController.doneTouched(_:)))
        toolBar.items = [cancelBtn, space, doneBtn]
        txtDate.inputAccessoryView = toolBar
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeKeyBoard))    //宣告點按手勢，並且指定對應呼叫的方法
        self.view.addGestureRecognizer(tapGesture)    //把點按手勢加到底面上
        
        // 導覽列右邊修改按鈕
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "修改", style:.plain, target: self, action: #selector(btnUpdateAction))
        //註冊鍵盤彈出的通知
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        //註冊鍵盤收起的通知
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // 選取日期時 按下完成
    func doneTouched(_ sender:UIBarButtonItem) {
        txtDate.text = myFormatter.string(from: myDatePicker.date)
//        myDatePicker.date = myFormatter.date(from: txtDate.text!)!
//        print("date:\(date)")
//        txtDate.text = date
        closeKeyBoard()
    }
    // 選取日期時 按下取消
    func cancelTouched(_ sender:UIBarButtonItem) {
        closeKeyBoard()
    }
    // MARK: UITextField Delegate Methods
    // 儲存功能
    func btnUpdateAction() {
        //進行輸入資料檢查
        if txtDate.text == "" || txtView.text == "" || imgPicture.image == nil {
            let alert = UIAlertController(title: "輸入訊息錯誤", message: "資料輸入不完整，無法修改資料！", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return  //直接離開函式
        }
        //        print("aaaaaaaaaa")
        
        //        let createTime = myFormatter.string(from: Date())
        let createTime = (txtDate.text)!
        let updateId = tableViewController.myRecords[postRecords]![selectedRow]["Id"] as? String
        let yearMonth = (createTime as NSString).substring(to: 7)
        let currentDate = (createTime as NSString).substring(to: 10)
        let createDate = (currentDate as NSString).substring(from: 8)
        let createWeek = (createTime as NSString).substring(from: 17)
        //        print("bbbbbbbbbbb")
        //檢查資料庫連線
        if db != nil {
            //            print("cccccccccc")
            var statement:OpaquePointer? = nil    //宣告儲存執行結果的變數
            let imageData = UIImageJPEGRepresentation(imgPicture.image!, 0.8)! as NSData    //準備要存入的圖片
//            let sql = String(format: "UPDATE records SET (Id,CreateDate,YearMonth,Photo,TextView,CreateTime,CreateWeek) values ('%@','%@','%@',?,'%@','%@','%@') where Id = '%@'", updateId!, createDate, yearMonth, txtView.text!, txtDate.text!, createWeek, updateId!)    //準備SQL的插入指令
            let sql = String(format: "UPDATE records SET Id='%@', CreateDate='%@', YearMonth='%@', Photo=?, TextView='%@', CreateTime='%@', CreateWeek='%@' where Id = '%@'", updateId!, createDate, yearMonth, txtView.text!, txtDate.text!, createWeek, updateId!)    //準備SQL的插入指令
//                        print("新增指令1.：\(sql)")
            sqlite3_prepare_v2(db, sql.cString(using: String.Encoding.utf8), -1, &statement, nil)     //準備執行SQL指令
            //將照片存入資料庫欄位（第二個參數1，指的是SQL指令?所在的位置，此位置從1起算）
            sqlite3_bind_blob(statement, 1, imageData.bytes, Int32(imageData.length), nil)
            //執行SQL指令
            //            print("新增指令2.：\(sql)")
            if sqlite3_step(statement) == SQLITE_DONE {
                //                print("資料新增成功！")
                let alert = UIAlertController(title: "資料庫訊息", message: "資料修改成功！", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "確定", style: .default, handler: {
                    (result) -> Void
                    in
                    _ = self.navigationController?.popViewController(animated: false)
                }))
                present(alert, animated: true, completion: nil)
                
//                tableViewController.myRecords[postRecords]![selectedRow]["name"] = txtName.text
//                tableViewController.myRecords[postRecords]![selectedRow]["address"] = txtAddress.text
//                tableViewController.myRecords[postRecords]![selectedRow]["phone"] = txtPhone.text
//                tableViewController.myRecords[postRecords]![selectedRow]["email"] = txtEmail.text
                tableViewController.myRecords[postRecords]![selectedRow]["CreateTime"] = txtDate.text!
                tableViewController.myRecords[postRecords]![selectedRow]["TextView"] = txtView.text!
                tableViewController.myRecords[postRecords]![selectedRow]["Photo"] = UIImageJPEGRepresentation(imgPicture.image!, 0.7)
                
                //                if yearMonth != "" {
//                if !newDays.contains(yearMonth) {
//                    newDays.append(yearMonth)
//                    tableViewController.myRecords[yearMonth] = []
//                    
//                }
//                
//                tableViewController.myRecords[yearMonth]?.append([
//                    "CreateWeek":"\(createWeek)",
//                    "CreateDate":"\(createDate)",
//                    "CreateTime":"\(createTime)",
//                    "Photo":imageData,
//                    "TextView":txtView.text!
//                    ])
                //                }
                print("修改資料：\(tableViewController.myRecords)")
            } else {
                //                print("資料修改失敗！")
                let alert = UIAlertController(title: "資料庫訊息", message: "資料修改失敗！", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "確定", style: .destructive, handler: nil))
                present(alert, animated: true, completion: nil)
            }
            sqlite3_finalize(statement)    //關閉連線指令
        }
    }

    //MARK: UIImagePickerControllerDelegate
    //影像挑選控制器完成影像挑選時
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        //        print("info=\(info)")
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage    //取得拍照或相簿中的相片
        imgPicture.image = image    //將取得的照片，顯示於照片欄位
        picker.dismiss(animated: true, completion: nil)    //移除影像挑選控制器
    }
    //由鍵盤彈出通知呼叫的函式
    func keyboardWillShow(_ sender:Notification) {
        //        print("鍵盤彈出")
        //        print("userInfo=\(String(describing: sender.userInfo))")
        if let keyboardHeight = (sender.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? NSValue)?.cgRectValue.size.height {
            print("鍵盤高度：\(keyboardHeight)")
            let visiableHeight = self.view.frame.size.height - keyboardHeight    //計算可視高度
            //如果輸入元件的Y軸底緣位置，比可視高度還大，代表輸入元件被鍵盤遮住
            if currentTextObjectYPosition > visiableHeight {
                self.view.frame.origin.y = -(self.currentTextObjectYPosition-visiableHeight+10)    //往上移動Y軸底緣位置和可視高度之間的差值(並拉開10點的差距)
            }
        }
    }
    //由鍵盤收合通知呼叫的函式
    func keyboardWillHide() {
        //        print("鍵盤收合")
        self.view.frame.origin.y = 0    //Y軸移回原點
    }
    //由點按手勢呼叫
    func closeKeyBoard() {
        //        print("感應到點按手勢")
        //掃描self.view底下所有的可視元件，收起鍵盤
        for subView in self.view.subviews {
            if subView is UITextField || subView is UITextView {
                subView.resignFirstResponder()    //只要是可以彈出鍵盤的元件，就請它收起鍵盤
            }
        }
    }
    //MARK: -Buttons
    //相機按鈕
    @IBAction func btnTakePicture(_ sender: UIButton) {
        //檢查裝置是否配備相機
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()    //初始化影像挑選控制器
            imagePickerController.sourceType = .camera    //指定影像挑選控制器為相機
            imagePickerController.delegate = self    //指定影像挑選控制器的代理人
            show(imagePickerController, sender: self)    //顯示影像挑選控制器（現在為相機）
        } else {
            print("找不到相機！")
        }
    }
    //相簿按鈕
    @IBAction func btnPhotoAlbum(_ sender: UIButton) {
        //檢查裝置是否有相簿
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePickerController = UIImagePickerController()    //初始化影像挑選控制器
            imagePickerController.sourceType = .photoLibrary    //指定影像挑選控制器為相簿
            imagePickerController.delegate = self    //指定影像挑選控制器的代理人
            show(imagePickerController, sender: self)    //顯示影像挑選控制器（現在為相機）
        } else {
            print("找不到相簿！")
        }
    }
    
}
