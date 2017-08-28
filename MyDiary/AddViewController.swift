import UIKit
import AVFoundation
import AssetsLibrary
import AVKit

class AddViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITextViewDelegate, AVCaptureFileOutputRecordingDelegate {
    
    let myFormatter = DateFormatter()
    
    weak var tableViewController:ViewController!
    weak var collectionViewController: CollectionVController!
    
    var db:OpaquePointer? = nil
    var currentTextObjectYPosition:CGFloat = 0
    var myDatePicker :UIDatePicker!
    var myRecords = [String:[[String:Any?]]]()
    var newDays = [String]()
    
    let captureSession = AVCaptureSession()
    var cameraPreviewLayer = AVCaptureVideoPreviewLayer()
    
    @IBOutlet weak var imgPicture: UIImageView!
    @IBOutlet weak var txtView: UITextView!
    @IBOutlet weak var txtDate: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            db = appDelegate.getDB()
        }
        
        txtDate.delegate = self
        myFormatter.dateFormat = "yyyy-MM-dd EEE HH:mm"
        
        txtView.layer.cornerRadius = 10
        txtView.layer.borderWidth = 2.0
        txtView.layer.borderColor = (UIColor.init(red: 0.8, green: 0.75, blue: 1, alpha: 1)).cgColor
        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = 10
        let attributes = [NSFontAttributeName:UIFont.systemFont(ofSize: 18),
                          NSParagraphStyleAttributeName: paraph]
        txtView.attributedText = NSAttributedString(string: txtView.text!, attributes: attributes)
        
        txtView.backgroundColor = UIColor.white
        txtView.text = "我是placeholder"
        txtView.textColor = UIColor.gray
        txtView.delegate = self
        //        view.addSubview(txtView)
        
        
        // UIDatePicker
        myDatePicker = UIDatePicker()
        myDatePicker.datePickerMode = .dateAndTime
        myDatePicker.locale = Locale(identifier: "zh_TW")
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
        
        //        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "儲存", style:.plain, target: self, action: #selector(btnSaveAction))
        //        let saveImg = UIImage(named: "btnSave.png")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "btnSave.png"), style: .plain, target: self, action: #selector(btnSaveAction))
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func doneTouched(_ sender:UIBarButtonItem) {
        let date = myFormatter.string(from: myDatePicker.date)
        //        print("date:\(date)")
        txtDate.text = date
        closeKeyBoard()
    }
    
    func cancelTouched(_ sender:UIBarButtonItem) {
        closeKeyBoard()
    }
    // MARK: UITextField Delegate Methods
    func btnSaveAction() {
        if txtDate.text == "" || txtView.text == "" || imgPicture.image == nil {
            let alert = UIAlertController(title: "輸入訊息錯誤", message: "資料輸入不完整，無法新增資料！", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "確定", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return  //直接離開函式
        }
        
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
            let sql = String(format: "INSERT INTO records (CreateDate,YearMonth,MonthDate,Photo,TextView,CreateTime,CreateWeek) VALUES ('%@','%@','%@',?,'%@','%@','%@')", createDate, yearMonth, monthDate, txtView.text!, txtDate.text!, createWeek)
            
            sqlite3_prepare_v2(db, sql.cString(using: String.Encoding.utf8), -1, &statement, nil)
            sqlite3_bind_blob(statement, 1, imageData.bytes, Int32(imageData.length), nil)
            if sqlite3_step(statement) == SQLITE_DONE {
                let alert = UIAlertController(title: "資料庫訊息", message: "資料新增成功！", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "確定", style: .default, handler: {
                    (result) -> Void
                    in
                    _ = self.navigationController?.popViewController(animated: false)
                }))
                
                present(alert, animated: true, completion: nil)
                
                if self.tableViewController != nil {
                    if !newDays.contains(yearMonth) {
                        newDays.append(yearMonth)
                        tableViewController.myRecords[yearMonth] = []
                    }
                    tableViewController.myRecords[yearMonth]?.append([
                        "CreateDate":"\(createDate)",
                        "MonthDate":"\(monthDate)",
                        "CreateWeek":"\(createWeek)",
                        "CreateTime":"\(createTime)",
                        "Photo":imageData,
                        "TextView":txtView.text!
                        ])
                } else {
                    collectionViewController.myCVRecords.append([
                        //                        "Id":"\(id)",
                        "MonthDate":"\(monthDate)",
                        "CreateWeek":"\(createWeek)",
                        "Photo":imageData,
                        "TextView":txtView.text!,
                        "CreateTime":"\(createTime)"
                        ])
                    
                }
            } else {
                let alert = UIAlertController(title: "資料庫訊息", message: "資料新增失敗！", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "確定", style: .destructive, handler: nil))
                present(alert, animated: true, completion: nil)
            }
            sqlite3_finalize(statement)
        }
    }
    //MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imgPicture.image = image
        picker.dismiss(animated: true, completion: nil)
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
        if error != nil {
            print(error)
            return
        }
        
    }
    
    func keyboardWillShow(_ sender:Notification) {
        if let keyboardHeight = (sender.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? NSValue)?.cgRectValue.size.height {
            let visiableHeight = self.view.frame.size.height - keyboardHeight
            if currentTextObjectYPosition > visiableHeight {
                self.view.frame.origin.y = -(self.currentTextObjectYPosition-visiableHeight+10)
            }
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
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if txtView.text.characters.count < 1 {
            txtView.text = "我是placeholder"
            txtView.textColor = UIColor.gray
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if (txtView.text == "我是placeholder") {
            txtView.text = ""
            txtView.textColor = UIColor.black
        }
    }
    
    //MARK: -Buttons
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
    
    @IBAction func btnCamera(_ semder: UIButton) {
        
            //確認裝置是否有相機可使用
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.sourceType = .camera
            //確認是否有後方鏡頭
//            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
//                imagePickerController.cameraDevice = .rear
                //設定是拍照還是錄影
                imagePickerController.cameraCaptureMode = .video
//                imagePickerController.allowsEditing = true
                imagePickerController.delegate = self
                show(imagePickerController, sender: self)
//            }
        } else {
            print("找不到相機！")
        }

    }
}
