import Cocoa

enum LinkType : Int {
    case url = 0
    case markdown = 1
    static func getLink(path:String,type:LinkType) -> String{
        let name = NSString(string: path).lastPathComponent
        switch type {
        case .markdown:
            return "![" + name + "](" + path  + ")"
        case .url:
            return path
        }
    }
}

var ZJUploadNotiName = NSNotification.Name.init("image_upload_progress")

enum UploadType : Int {
    case defaultType = 0
    case QNType = 1
    case AliOSSType = 2
}

class AppConfig: NSObject ,NSCoding ,DiskCache{
    var linkType : LinkType = .markdown //链接模式
    var autoUp : Bool = false //是否自动上传
    var useDefServer : Bool = true //是否配置好 ， true 未配置， false 已配置
    
    var uploadType : UploadType = .defaultType //上传模式
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(linkType.rawValue.description, forKey: "linkType")
        aCoder.encode(autoUp.hashValue.description, forKey: "autoUp")
        aCoder.encode(useDefServer.hashValue.description, forKey: "useDefServer")
     
        aCoder.encode(uploadType.rawValue.description, forKey: "uploadType")
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard  let _ = aDecoder.decodeObject(forKey: "linkType") else {
            return nil
        }
        guard  let _ = aDecoder.decodeObject(forKey: "uploadType") else {
            return nil
        }
        autoUp = Bool(truncating: NSNumber(value: Int(aDecoder.decodeObject(forKey: "autoUp") as! String)!))
        linkType = LinkType(rawValue: Int(aDecoder.decodeObject(forKey: "linkType") as! String)! )!
        useDefServer = Bool(truncating: NSNumber(value: Int(aDecoder.decodeObject(forKey: "useDefServer") as! String)!))
        
        uploadType = UploadType(rawValue: Int(aDecoder.decodeObject(forKey: "uploadType") as! String)! )!
        
        super.init()
    }
    override init() {
        super.init();
        setInCache("appConfig");
    }
}
