import Cocoa
import MASPreferences

class AliOSSImagePreferencesViewController: NSViewController, MASPreferencesViewController {
    var viewIdentifier: String = "AliOSSImagePreferences"

	var toolbarItemLabel: String? { get { return "阿里云" } }
	var toolbarItemImage: NSImage? { get { return NSImage(named: "oss-setting") } }
	var window: NSWindow?
	@IBOutlet weak var statusLabel: NSTextField!
	@IBOutlet weak var accessKeyTextField: NSTextField!
	@IBOutlet weak var secretKeyTextField: NSTextField!
	@IBOutlet weak var bucketTextField: NSTextField!
	@IBOutlet weak var urlPrefixTextField: NSTextField!
	@IBOutlet weak var checkButton: NSButton!
    @IBOutlet weak var markTextField: NSTextField!
    @IBOutlet weak var AliOSSZonePopButton: NSPopUpButton!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
	override func viewDidLoad() {
		super.viewDidLoad()
		
        NotificationCenter.default.addObserver(self, selector: #selector(clearCatch), name: NSNotification.Name(rawValue: "clearCatch"), object: nil)
        setupSubViews()
	}
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        setupSubViews()
    }
    
    func setupSubViews() {
        guard let oss =  AppCache.shared.ossConfig else {
            resetView()
            return
        }
        statusLabel.cell?.title = "配置成功"
        statusLabel.textColor = .magenta
        AliOSSZonePopButton.selectItem(withTag: oss.zone);
        accessKeyTextField.cell?.title = oss.accessKey;
        secretKeyTextField.cell?.title = oss.secretKey;
        bucketTextField.cell?.title = oss.bucket;
    }
    
    func resetView() {
        AliOSSZonePopButton.selectItem(withTag: 1)
        statusLabel.cell?.title = "请配置图床"
        statusLabel.textColor = .red
        accessKeyTextField.cell?.title = ""
        secretKeyTextField.cell?.title = ""
        bucketTextField.cell?.title = ""
        accessKeyTextField.becomeFirstResponder()
    }
    
    @objc func clearCatch() {
        setupSubViews()
    }
    
    
    @IBAction func resetInput(_ sender: NSButton) {
        resetView()
    }

    @IBAction func selectAliOSSZone(_ sender: NSMenuItem) {
        AliOSSZonePopButton.select(sender);
    }
    
	@IBAction func setQiniuConfig(_ sender: AnyObject) {
		if (accessKeyTextField.cell?.title.count == 0 ||
			secretKeyTextField.cell?.title.count == 0 ||
			bucketTextField.cell?.title.count == 0 ) {
				showAlert("有配置信息未填写", informative: "请仔细填写")
				return
		}
		
		let ack = (accessKeyTextField.cell?.title)!
		let sek = (secretKeyTextField.cell?.title)!
		let bck = (bucketTextField.cell?.title)!
        
        let ossConfig = AliOSSConfig(accessKey: ack, bucket: bck, secretKey: sek, zone: (AliOSSZonePopButton.selectedItem?.tag)!)
        
        print(ossConfig)
        
        checkButton.title = "验证中"
        checkButton.isEnabled = false
        OSSClient.shared.getOSSBucketIsAvaliable(endPoint: ossConfig.zoneHost, ossConfig.accessKey, ossConfig.secretKey, bucketName: ossConfig.bucket, bucketLocation: ossConfig.location) { [weak self] (avaliableType) in
            self?.checkButton.isEnabled = true
            self?.checkButton.title = "验证配置"
            
            switch avaliableType {
            case .none:
                self?.showAlert("验证失败", informative: "验证失败，请仔细填写信息。")
            case .fail:
                self?.showAlert("验证失败", informative: "验证失败，请重试。")
            case .errorLocation:
                self?.showAlert("验证失败", informative: "所选区域与Bucket所在区域不匹配")
            case .sucess:
                self?.statusLabel.cell?.title = "配置成功"
                self?.statusLabel.textColor = .magenta
                self?.showAlert("验证成功", informative: "配置成功")
                ossConfig.setInCache("AliOSS_User_Config");
                AppCache.shared.ossConfig = ossConfig;
                AppCache.shared.appConfig.setInCache("appConfig")
            }
        }
	}
	
	func showAlert(_ message: String, informative: String) {
		let arlert = NSAlert()
		arlert.messageText = message
		arlert.informativeText = informative
		arlert.addButton(withTitle: "确定")
        arlert.icon = message == "验证成功" ? NSImage(named: "Icon_32x32") :  NSImage(named: "Failure")
		arlert.beginSheetModal(for: self.window!, completionHandler: { (response) in
			
		})
	}
	
}
