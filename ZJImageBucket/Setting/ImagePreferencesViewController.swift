import Cocoa
import MASPreferences

class ImagePreferencesViewController: NSViewController, MASPreferencesViewController {
    var viewIdentifier: String = "ImagePreferences"
    
	var toolbarItemLabel: String? { get { return "七牛云" } }
	var toolbarItemImage: NSImage? { get { return NSImage(named: "qiniu-setting") } }
	var window: NSWindow?
	@IBOutlet weak var statusLabel: NSTextField!
	@IBOutlet weak var accessKeyTextField: NSTextField!
	@IBOutlet weak var secretKeyTextField: NSTextField!
	@IBOutlet weak var bucketTextField: NSTextField!
	@IBOutlet weak var urlPrefixTextField: NSTextField!
	@IBOutlet weak var checkButton: NSButton!
    @IBOutlet weak var markTextField: NSTextField!
    @IBOutlet weak var QNZonePopButton: NSPopUpButton!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
	override func viewDidLoad() {
		super.viewDidLoad()
        setupSubViews()
        NotificationCenter.default.addObserver(self, selector: #selector(clearCatch), name: NSNotification.Name(rawValue: "clearCatch"), object: nil)
	}
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        setupSubViews()
    }
    
    func setupSubViews() {
        guard let qc =  AppCache.shared.qnConfig else{
            resetView()
            return
        }
        statusLabel.cell?.title = "配置成功"
        statusLabel.textColor = .magenta
        QNZonePopButton.selectItem(withTag: qc.zone);
        accessKeyTextField.cell?.title = qc.accessKey;
        secretKeyTextField.cell?.title = qc.secretKey;
        bucketTextField.cell?.title = qc.scope;
        urlPrefixTextField.cell?.title = qc.picUrlPrefix;
        markTextField.cell?.title = qc.mark;
    }
    
    func resetView() {
        QNZonePopButton.selectItem(withTag: 1)
        statusLabel.cell?.title = "请配置图床"
        statusLabel.textColor = .red
        accessKeyTextField.cell?.title = ""
        secretKeyTextField.cell?.title = ""
        bucketTextField.cell?.title = ""
        urlPrefixTextField.cell?.title = ""
        markTextField.cell?.title = ""
        accessKeyTextField.becomeFirstResponder()
    }
    
    @objc func clearCatch() {
        setupSubViews()
    }
    
    @IBAction func resetInput(_ sender: NSButton) {
        resetView()
    }
	
    @IBAction func selectQNZone(_ sender: NSMenuItem) {
        QNZonePopButton.select(sender);
    }
    
    
    
	@IBAction func setQiniuConfig(_ sender: AnyObject) {
		if (accessKeyTextField.cell?.title.count == 0 ||
			secretKeyTextField.cell?.title.count == 0 ||
			bucketTextField.cell?.title.count == 0 ||
			urlPrefixTextField.cell?.title.count == 0) {
				showAlert("有配置信息未填写", informative: "请仔细填写")
				return
		}
		
		urlPrefixTextField.cell?.title = (urlPrefixTextField.cell?.title.replacingOccurrences(of: " ", with: ""))!
		
		if !(urlPrefixTextField.cell?.title.hasPrefix("http://"))! && !(urlPrefixTextField.cell?.title.hasPrefix("https://"))! {
			urlPrefixTextField.cell?.title = "http://" + (urlPrefixTextField.cell?.title)!
		}
		
		if !(urlPrefixTextField.cell?.title.hasSuffix("/"))! {
			urlPrefixTextField.cell?.title = (urlPrefixTextField.cell?.title)! + "/"
		}
		
		let ack = (accessKeyTextField.cell?.title)!
		let sek = (secretKeyTextField.cell?.title)!
		let bck = (bucketTextField.cell?.title)!
        let urlPrefix = (urlPrefixTextField.cell?.title)!
		let qnConfig =  QNConfig(picUrlPrefix: urlPrefix, accessKey: ack, scope: bck, secretKey: sek, mark: (markTextField.cell?.title)!, zone: (QNZonePopButton.selectedItem?.tag)!)
		checkButton.title = "验证中"
		checkButton.isEnabled = false
        QNService.shared.register(config:qnConfig)
        QNService.shared.createToken()
        QNService.shared.verifyQNConfig(zone: QNZonePopButton.selectedItem?.tag) { (result) in
            self.checkButton.isEnabled = true
            self.checkButton.title = "验证配置"
            _ = result.Success(success: { (succObj) in
                self.statusLabel.cell?.title = "配置成功"
                self.statusLabel.textColor = .magenta
                self.showAlert("验证成功", informative: "配置成功")
                qnConfig.setInCache("QN_Use_Config");
                AppCache.shared.qnConfig = qnConfig;
                AppCache.shared.appConfig.useDefServer = false
                AppCache.shared.appConfig.setInCache("appConfig")
            })
            
            _ = result.Failure(failure: { (failObj) in
                self.statusLabel.cell?.title = "验证失败！"
                self.statusLabel.textColor = .magenta
                self.showAlert("验证失败", informative: "验证失败，请仔细填写信息。")
            })
        }
	}
	
	func showAlert(_ message: String, informative: String) {
		let arlert = NSAlert()
		arlert.messageText = message
		arlert.informativeText = informative
		arlert.addButton(withTitle: "确定")
        arlert.icon = message == "验证成功" ? NSImage(named: "Icon_32x32") :  NSImage(named: "upload_fail")
		arlert.beginSheetModal(for: self.window!, completionHandler: { (response) in
			
		})
	}
	
}
