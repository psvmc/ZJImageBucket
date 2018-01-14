import Cocoa

class ImageService: NSObject {
    static let shared = ImageService()
    public func uploadImg(_ pboard: NSPasteboard) {
        var data : Data? = ZJPasteboardUtil.getImageData(pboard)
        if data?.imageFormat == .unknown {
            let imageRep = NSBitmapImageRep(data: data!)
            data = imageRep?.representation(using: .jpeg, properties: [:])
        }
        if let data = data{
            switch AppCache.shared.appConfig.uploadType {
            case .defaultType:
                SMMSService.shared.uploadImage(data)
            case .QNType:
                QNService.shared.QiniuSDKUpload(data)
            case .AliOSSType:
                OSSClient.shared.AliOSSUpload(data)
            }
        }
    }
    
}
