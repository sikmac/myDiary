import UIKit
import Social

class PostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    let myFormatter = DateFormatter()
    
    weak var tableViewController: ViewController!
    weak var collectionViewController: CollectionVController!
    
    var db:OpaquePointer? = nil
    var currentTextObjectYPosition:CGFloat = 0
    var myDatePicker :UIDatePicker!
    
    var selectedRow  = 0
    var postRecords = ""
    var dicCurrentRow: [String:Any?] = [:]
    var PostRecords = [[String:Any?]]()
    
    @IBOutlet weak var txtDate: UITextField!
    @IBOutlet weak var imgPicture: UIImageView!
    @IBOutlet weak var txtView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            db = appDelegate.getDB()
        }
        
        txtDate.delegate = self
        myFormatter.dateFormat = "yyyy-MM-dd EEE HH:mm"
        
        if self.tableViewController != nil {
            let dicCurrentRow = tableViewController.myRecords[postRecords]?[selectedRow]
            txtDate.text = dicCurrentRow?["CreateTime"] as? String
            txtView.text = dicCurrentRow?["TextView"] as! String
            guard let aPic = dicCurrentRow?["Photo"]! else {
                return
            }
            imgPicture.image = UIImage(data: aPic as! Data)
            self.PostRecords.append(dicCurrentRow!)
        } else {
            let dicCurrentRow = collectionViewController.myCVRecords[selectedRow]
            txtDate.text = dicCurrentRow["CreateTime"] as? String
            txtView.text = dicCurrentRow["TextView"] as! String
            guard let aPic = dicCurrentRow["Photo"]! else {
                return
            }
            imgPicture.image = UIImage(data: aPic as! Data)
            self.PostRecords.append(dicCurrentRow)
        }
//        print("postrecords:\(PostRecords)")
        
        txtView.layer.cornerRadius = 10
        txtView.layer.borderWidth = 2.0
        txtView.layer.borderColor = (UIColor.init(red: 0.8, green: 0.75, blue: 1, alpha: 1)).cgColor
        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = 10
        let attributes = [NSFontAttributeName:UIFont.systemFont(ofSize: 18),
                          NSParagraphStyleAttributeName: paraph]
        txtView.attributedText = NSAttributedString(string: txtView.text!, attributes: attributes)
        
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeKeyBoard))
        self.view.addGestureRecognizer(tapGesture)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "修改", style:.plain, target: self, action: #selector(btnUpdateAction))
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func doneTouched(_ sender:UIBarButtonItem) {
        txtDate.text = myFormatter.string(from: myDatePicker.date)
        closeKeyBoard()
    }
    
    func cancelTouched(_ sender:UIBarButtonItem) {
        closeKeyBoard()
    }
    
    func btnUpdateAction() {
        if txtDate.text == "" || txtView.text == "" || imgPicture.image == nil {
            let alert = UIAlertController(title: "輸入訊息錯誤", message: "資料輸入不完整，無法修改資料！", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        let updateId = PostRecords[0]["Id"] as? String
//        let createTime = (txtDate.text)!
//        let yearMonth = (createTime as NSString).substring(to: 7)
//        let currentDate = (createTime as NSString).substring(to: 10)
//        let createDate = (currentDate as NSString).substring(from: 8)
//        let createWeek = (createTime as NSString).substring(from: 17)
        
        let pickTime = (txtDate.text)!
        let createTime = (pickTime as NSString).substring(to: 14)
//        print("createTime:\(createTime)")
        let yearMonth = (createTime as NSString).substring(to: 7)
//        print("yearMonth:\(yearMonth)")
        let currentDate = (createTime as NSString).substring(to: 10)
//        print("currentDate:\(currentDate)")
        let createWeek = (createTime as NSString).substring(from: 11)
//        print("createWeek:\(createWeek)")
        
        let monthDate = (currentDate as NSString).substring(from: 5)
//        print("monthDate:\(monthDate)")
        let createDate = (currentDate as NSString).substring(from: 8)
//        print("createDate:\(createDate)")

        
        if db != nil {
            
            var statement:OpaquePointer? = nil
            let imageData = UIImageJPEGRepresentation(imgPicture.image!, 0.8)! as NSData
            let sql = String(format: "UPDATE records SET Id='%@', CreateDate='%@', YearMonth='%@', Photo=?, TextView='%@', CreateTime='%@', CreateWeek='%@' WHERE Id = '%@'", updateId!, createDate, yearMonth, txtView.text!, txtDate.text!, createWeek, updateId!)
            sqlite3_prepare_v2(db, sql.cString(using: String.Encoding.utf8), -1, &statement, nil)
            sqlite3_bind_blob(statement, 1, imageData.bytes, Int32(imageData.length), nil)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                let alert = UIAlertController(title: "資料庫訊息", message: "資料修改成功！", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "確定", style: .default, handler: {
                    (result) -> Void
                    in
                    _ = self.navigationController?.popViewController(animated: false)
                }))
                present(alert, animated: true, completion: nil)
                
                dicCurrentRow["CreateTime"] = txtDate.text!
                dicCurrentRow["TextView"] = txtView.text!
                dicCurrentRow["Photo"] = UIImageJPEGRepresentation(imgPicture.image!, 0.7)
//                print("String：\(String(describing: UIImageJPEGRepresentation(imgPicture.image!, 0.7)))")
            } else {
                let alert = UIAlertController(title: "資料庫訊息", message: "資料修改失敗！", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "確定", style: .destructive, handler: nil))
                present(alert, animated: true, completion: nil)
            }
            sqlite3_finalize(statement)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imgPicture.image = image
        picker.dismiss(animated: true, completion: nil)
    }
    
    func keyboardWillShow(_ sender:Notification) {
        
        if let keyboardHeight = (sender.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? NSValue)?.cgRectValue.size.height {
            print("鍵盤高度：\(keyboardHeight)")
            let visiableHeight = self.view.frame.size.height - keyboardHeight
            if currentTextObjectYPosition > visiableHeight {
                self.view.frame.origin.y = -(self.currentTextObjectYPosition-visiableHeight+10)            }
        }
    }
    
    func keyboardWillHide() {
        self.view.frame.origin.y = 0
    }
    
    func closeKeyBoard() {
        for subView in self.view.subviews {
            if subView is UITextField || subView is UITextView {
                subView.resignFirstResponder()
            }
        }
    }
    //MARK: -BUTTON
    @IBAction func btnTakePicture(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .camera
            imagePickerController.delegate = self
            show(imagePickerController, sender: self)
        } else {
            print("找不到相機！")
        }
    }
    
    @IBAction func btnPhotoAlbum(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .photoLibrary
            imagePickerController.delegate = self
            show(imagePickerController, sender: self)
        } else {
            print("找不到相簿！")
        }
    }
    
    @IBAction func btnShare(_ sender: UIButton) {
        // Display the share menu
        let shareMenu = UIAlertController(title: nil, message: "Share using", preferredStyle: .actionSheet)
        let twitterAction = UIAlertAction(title: "Twitter", style: UIAlertActionStyle.default) {
            (action) in
            //	檢查Twitter是否可以取得。否則的話，顯示⼀個錯誤訊息
            guard SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter) else {
                let	alertMessage	=	UIAlertController(title:	"Twitter Unavailable",	message: "You haven't registered your Twitter account.Please go to Settings > Twitter to create one.", preferredStyle: .alert)
                alertMessage.addAction(UIAlertAction(title:	"OK", style: .default, handler: nil))
                self.present(alertMessage, animated: true, completion: nil)
                return
            }
            // Display Tweet Composer
            if let tweetComposer = SLComposeViewController(forServiceType: SLServiceTypeTwitter)	{
                tweetComposer.setInitialText(self.PostRecords[0]["TextView"] as! String)
                tweetComposer.add(self.imgPicture.image)
                self.present(tweetComposer, animated: true, completion: nil)
            }
        }
        let facebookAction = UIAlertAction(title: "Facebook", style: UIAlertActionStyle.default) {
            (action) in
            //	檢查Facebook是否可以取得。否則的話，顯示⼀個錯誤訊息
            guard SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook) else {
                let	alertMessage	= UIAlertController(title:	"Facebook Unavailable", message: "You haven't registered your Facebook account.Please go to Settings > Facebook to create one.", preferredStyle: .alert)
                alertMessage.addAction(UIAlertAction(title:	"OK", style: .default, handler: nil))
                self.present(alertMessage, animated: true, completion: nil)
                return
            }
            // Display Facebook Composer
            if let fbComposer = SLComposeViewController(forServiceType: SLServiceTypeFacebook)	{
                fbComposer.setInitialText(self.PostRecords[0]["TextView"] as! String)
                fbComposer.add(self.imgPicture.image)
                self.present(fbComposer, animated: true, completion: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        shareMenu.addAction(twitterAction)
        shareMenu.addAction(facebookAction)
        shareMenu.addAction(cancelAction)
        
        self.present(shareMenu, animated: true, completion: nil)
    }
    
    @IBAction func btnDelete(_ sender: UIButton) {
        
        let alert = UIAlertController(title: "警告！", message: "確認刪除資料？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "確定刪除", style: .default, handler: {
            (result) -> Void in
            let sql = String(format: "DELETE FROM records where Id='%@'", (self.PostRecords[0]["Id"] as? String)!)
            var statement:OpaquePointer? = nil
            sqlite3_prepare(self.db, sql.cString(using: .utf8), -1, &statement, nil)
            if sqlite3_step(statement) == SQLITE_DONE {
                let alert = UIAlertController(title: "資料庫訊息", message: "資料刪除成功！", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "確定", style: .default, handler: { (result) -> Void
                    in
                    _ = self.navigationController?.popViewController(animated: false)
                }
                ))
                self.present(alert, animated: true, completion: nil)
            }
            sqlite3_finalize(statement)
//            self.collectionViewController.collectionView.reloadData()
//            self.collectionViewController.collectionView.collectionViewLayout.invalidateLayout()
        }
            )
        )
        let cancelAction = UIAlertAction(title: "取消刪除", style: .default, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}
