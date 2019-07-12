import Cocoa

class DragDestinationView: NSView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        let pasteboardTypeFileURL  = NSPasteboard.PasteboardType.init("public.file-url")
        // 注册接受文件拖入的类型
        registerForDraggedTypes([pasteboardTypeFileURL
            ,.string])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pboard = sender.draggingPasteboard
        
        if checkImageFile(pboard) {
            statusItem.button?.image = NSImage(named: "upload")
            return NSDragOperation.copy
        } else {
            return NSDragOperation()
        }
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        NotificationCenter.default.post(name: ZJUploadNotiName, object: ImageUploadModel(state: 1))
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard
        return checkImageFile(pboard)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard
        ImageService.shared.uploadImg(pboard)
        return true
    }
}
