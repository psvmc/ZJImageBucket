import Cocoa
import MASPreferences
import TMCache
import Carbon

var statusItem: NSStatusItem!

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static var appDelegate:AppDelegate!
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var MarkdownItem: NSMenuItem!
    @IBOutlet weak var statusMenu: NSMenu!
    weak var cacheImageMenu: NSMenu!
    @IBOutlet weak var autoUpItem: NSMenuItem!
    @IBOutlet weak var uploadMenuItem: NSMenuItem!
    @IBOutlet weak var cacheImageMenuItem: NSMenuItem!
    
    
    @IBOutlet weak var defaultMenu: NSMenuItem!
    @IBOutlet weak var QNMenu: NSMenuItem!
    @IBOutlet weak var AliOSSMenu: NSMenuItem!
    
    
    var mainWinController:ZJMainWinController!;
    
    let pasteboardObserver = PasteboardObserver()
    lazy var preferencesWindowController: NSWindowController = {
        let imageViewController = ImagePreferencesViewController()
        let aliOSSViewController = AliOSSImagePreferencesViewController()
        let controllers = [imageViewController, aliOSSViewController]
        let wc = MASPreferencesWindowController(viewControllers: controllers, title: "设置")
        imageViewController.window = wc.window
        aliOSSViewController.window = wc.window
        return wc
    }()

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        registerHotKeys()
        initApp()
        
        self.window.center()
        self.mainWinController = ZJMainWinController.init(windowNibName: NSNib.Name(rawValue: "ZJMainWinController"))
        mainWinController.window?.makeKeyAndOrderFront(nil)
        mainWinController.window?.center()
        mainWinController.window?.level = .dock
        NSApp.activate(ignoringOtherApps: true)
        AppDelegate.appDelegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(uploadStateChange(noti:)), name: ZJUploadNotiName, object: nil)
    }
    
    @objc func uploadStateChange(noti: Notification){
        if let uploadModel = noti.object as? ImageUploadModel{
            DispatchQueue.main.async {
                if(uploadModel.state == -1){
                    statusItem.button?.image = NSImage(named: NSImage.Name(rawValue: "StatusIcon"))
                    statusItem.title = "准备上传"
                }else if(uploadModel.state == 0){
                    if(uploadModel.progress < 100){
                        let progress = uploadModel.progress*8/100
                        statusItem.button?.image = NSImage(named: NSImage.Name(rawValue: "loading-\(progress)"))
                        statusItem.title = "[\(uploadModel.progress)%]"
                    }
                }else if(uploadModel.state == 1){
                    statusItem.button?.image = NSImage(named: NSImage.Name(rawValue: "StatusIcon"))
                    statusItem.title = "Z图床"
                }else if(uploadModel.state == 2){
                    statusItem.button?.image = NSImage(named: NSImage.Name(rawValue: "StatusIcon"))
                    statusItem.title = "上传失败"
                }
            }
            
        }
    }
    
    func initApp()  {
        setupAppCache()
        
        NotificationCenter.default.addObserver(self, selector: #selector(notification), name: NSNotification.Name(rawValue: "MarkdownState"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setUploadDefault), name: NSNotification.Name(rawValue: "setDefault"), object: nil)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.highlightMode = true
        
        //设置状态栏图标和事件
        let iconImage = NSImage.init(named: NSImage.Name.init("StatusIcon"))
        statusItem.button?.image = iconImage
        statusItem.title = "Z图床"
        statusItem.button?.action = #selector(showMenu)
        statusItem.button?.target = self
        
        //添加图片拖动功能
        let statusBarButton = DragDestinationView(frame: (statusItem.button?.bounds)!)
        statusItem.button?.superview?.addSubview(statusBarButton, positioned: .below, relativeTo: statusItem.button)
    }
    
    
    func setupAppCache() {
        //首先重置状态
        defaultMenu.state = NSControl.StateValue(rawValue: 0)
        QNMenu.state = NSControl.StateValue(rawValue: 0)
        AliOSSMenu.state = NSControl.StateValue(rawValue: 0)
        
        switch AppCache.shared.appConfig.linkType {
        case .markdown:
            MarkdownItem.state = NSControl.StateValue(rawValue: 1)
        case .url:
            MarkdownItem.state = NSControl.StateValue(rawValue: 0)
        }
        
        switch AppCache.shared.appConfig.uploadType {
        case .defaultType:
            setupUploadMenuState(defaultMenu)
        case .QNType:
            setupUploadMenuState(QNMenu)
        case .AliOSSType:
            setupUploadMenuState(AliOSSMenu)
        }
        
        pasteboardObserver.addSubscriber(self)
        
        if AppCache.shared.appConfig.autoUp {
            pasteboardObserver.startObserving()
            autoUpItem.state = NSControl.StateValue(rawValue: 1)
        }
    }
    
    @objc func setUploadDefault() {
        setupUploadMenuState(defaultMenu)
    }
    
    @objc func notification(_ notification: Notification) {
        MarkdownItem.state = NSControl.StateValue(rawValue: Int(truncating: (notification.object as AnyObject) as! NSNumber))
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        NotificationCenter.default.removeObserver(self)
        AppCache.shared.appConfig.setInCache("appConfig")
    }
    
    //设置上传方式并缓存
    func setupUploadMenuState(_ uploadMenu : NSMenuItem) {
        var menu : NSMenuItem? = nil;
        switch AppCache.shared.appConfig.uploadType {
        case .defaultType:
            menu = defaultMenu
        case .QNType:
            menu = QNMenu
        case .AliOSSType:
            menu = AliOSSMenu
        }
        
        if menu == uploadMenu && menu?.state.rawValue == 1 {
            return
        } else if menu?.state.rawValue != 0 {
            menu?.state = NSControl.StateValue(rawValue: 1 - (menu?.state)!.rawValue)
        }
        
        uploadMenu.state = NSControl.StateValue(rawValue: 1 - uploadMenu.state.rawValue)
        
        switch uploadMenu {
        case defaultMenu:
            AppCache.shared.appConfig.uploadType = .defaultType
        case QNMenu:
            AppCache.shared.appConfig.uploadType = .QNType
        case AliOSSMenu:
            AppCache.shared.appConfig.uploadType = .AliOSSType
        default:
            break;
        }
        AppCache.shared.appConfig.setInCache("appConfig")
    }
    
    @objc func showMenu() {
        let pboard = NSPasteboard.general
        if let image = ZJPasteboardUtil.getImage(pboard){
            image.scalingImage()
            uploadMenuItem.image = image
        }else{
            uploadMenuItem.image = nil
        }
        let object = TMCache.shared().object(forKey: "imageCache")
        if let obj = object as? [[String: AnyObject]] {
            AppCache.shared.imagesCacheArr = obj
        }
        cacheImageMenuItem.submenu = makeCacheImageMenu(AppCache.shared.imagesCacheArr)
        statusItem.popUpMenu(statusMenu)
    }
    
    @IBAction func statusMenuClicked(_ sender: NSMenuItem) {
        switch sender.tag {
            
        case 1:// 上传
            let pboard = NSPasteboard.general
            if let  _  = ZJPasteboardUtil.getImageData(pboard){
                ImageService.shared.uploadImg(pboard)
            }else{
                NotificationMessage("提示", informative: "请先[拷贝]上传的图片,再点击上传！", isSuccess: false)
            }
            
        case 2:// 设置
            preferencesWindowController.showWindow(nil)
            preferencesWindowController.window?.center()
            NSApp.activate(ignoringOtherApps: true)
        case 3:// 退出
            NSApp.terminate(nil)
        case 4://帮助
            NSWorkspace.shared.open(URL(string: "http://www.psvmc.cn")!)
        case 6://自动上传
            sender.state = NSControl.StateValue(rawValue: 1 - sender.state.rawValue);
            AppCache.shared.appConfig.autoUp =  sender.state.rawValue == 1 ? true : false
            AppCache.shared.appConfig.autoUp ? pasteboardObserver.startObserving() : pasteboardObserver.stopObserving()
            AppCache.shared.appConfig.setInCache("appConfig")
            
        case 7://切换markdown
            sender.state = NSControl.StateValue(rawValue: 1 - sender.state.rawValue)
            AppCache.shared.appConfig.linkType = LinkType(rawValue: sender.state.rawValue)!
            guard let imagesCache = AppCache.shared.imagesCacheArr.last else {
                return
            }
            let picUrl = imagesCache["url"] as! String
            NSPasteboard.general.setString(LinkType.getLink(path: picUrl, type: AppCache.shared.appConfig.linkType), forType: .string)
            AppCache.shared.appConfig.setInCache("appConfig")
    
        case 10,11,12://选择10、默认方式上传 11、七牛方式上传 12、阿里云方式上传
            setupUploadMenuState(sender)
        case 19://清除历史
            clearImageCatch()
        case 20:
            clearCatch()
        case 100:
            self.showMainWindow()
        default:
            break
        }
        
    }
    
    func showMainWindow(){
        if(self.mainWinController == nil){
            self.mainWinController = ZJMainWinController.init(windowNibName: NSNib.Name(rawValue: "ZJMainWinController"))
        }
        self.mainWinController.window?.makeKeyAndOrderFront(nil)
        mainWinController.window?.level = .dock
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func clearCatch() {
        showAlert("提示", informative: "你将重置所有已设置的配置（包含上传模式）以及所有上传历史记录，确定这么做么？") { [weak self] in
            AppCache.shared.appConfig.removeAllCatch()
            self?.setupAppCache()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "clearCatch"), object: self)
        }
    }
    
    
    func clearImageCatch() {
        showAlert("提示", informative: "确认清除上传历史记录？") { [weak self] in
            AppCache.shared.appConfig.clearUploadImageCatch()
            self?.setupAppCache()
        }
    }
    
    func showAlert(_ message: String, informative: String, clickOK: @escaping () -> Void) {
        let arlert = NSAlert()
        arlert.messageText = message
        arlert.informativeText = informative
        arlert.addButton(withTitle: "确定")
        arlert.addButton(withTitle: "取消")
        arlert.alertStyle = .warning
        arlert.window.center()
        arlert.beginSheetModal(for: self.window!, completionHandler: { (response) in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                clickOK()
            }
        })
    }
    
    func makeCacheImageMenu(_ imagesArr: [[String: AnyObject]]) -> NSMenu {
        let menu = NSMenu()
        
        if imagesArr.count == 0 {
            let item = NSMenuItem(title: "没有历史", action: nil, keyEquivalent: "")
            menu.addItem(item)
        } else {
            for index in 0..<imagesArr.count {
                let item = NSMenuItem(title: "", action: #selector(cacheImageClick(_:)), keyEquivalent: "")
                item.tag = index
                let i = imagesArr[index]["image"] as? NSImage
                i?.scalingImage()
                item.image = i
                menu.insertItem(item, at: 0)
            }
        }
        
        return menu
    }
    
    @objc func cacheImageClick(_ sender: NSMenuItem) {
        NSPasteboard.general.clearContents()
        let picUrl = AppCache.shared.imagesCacheArr[sender.tag]["url"] as! String
        NSPasteboard.general.setString(LinkType.getLink(path: picUrl, type: AppCache.shared.appConfig.linkType), forType: .string)
        NotificationMessage("图片链接获取成功", isSuccess: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if(self.mainWinController == nil){
            self.mainWinController = ZJMainWinController.init(windowNibName: NSNib.Name(rawValue: "ZJMainWinController"))
        }
        self.mainWinController.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return true
    }
    
    
}


extension AppDelegate: NSUserNotificationCenterDelegate, PasteboardObserverSubscriber {
    // 强行通知
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        
    }
    
    func pasteboardChanged(_ pasteboard: NSPasteboard) {
        ImageService.shared.uploadImg(pasteboard)
    }
    
    func registerHotKeys() {
        var gMyHotKeyRef: EventHotKeyRef? = nil
        var gMyHotKeyIDU = EventHotKeyID()
        var eventType = EventTypeSpec()
        
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        gMyHotKeyIDU.signature = OSType(32)
        gMyHotKeyIDU.id = UInt32(kVK_ANSI_U);
        
        RegisterEventHotKey(UInt32(kVK_ANSI_U), UInt32(cmdKey), gMyHotKeyIDU, GetApplicationEventTarget(), 0, &gMyHotKeyRef)
        
        // Install handler.
        InstallEventHandler(GetApplicationEventTarget(), { (nextHanlder, theEvent, userData) -> OSStatus in
            var hkCom = EventHotKeyID()
            GetEventParameter(theEvent, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hkCom)
            switch hkCom.id {
            case UInt32(kVK_ANSI_U):
                let pboard = NSPasteboard.general
                ImageService.shared.uploadImg(pboard)
            default:
                break
            }
            
            return 33
        }, 1, &eventType, nil, nil)
        
    }
    

    
}

