import Cocoa
import AFNetworking


class SMMSService: NSObject {
    static let shared = SMMSService()
    let api = "https://sm.ms/api/upload";
    
    
    func uploadImage(_ data: Data){
        
        var type = "";
        switch data.imageFormat {
        case .gif:
            type = "image/gif"
        case .jpeg:
            type = "image/jpeg"
        case .png:
            type = "image/png"
        case .unknown:
            type = "image/jpeg"
        }

        NotificationCenter.default.post(name: ZJUploadNotiName, object: ImageUploadModel(state: -1))
        let fileName = getDateString() + "\(timeInterval())" + "\(arc())" + data.imageFormat.rawValue
        
        let manager = AFHTTPSessionManager();
        
        manager.requestSerializer = AFJSONRequestSerializer.init();
        //manager.responseSerializer = AFHTTPResponseSerializer.init();
        manager.responseSerializer.acceptableContentTypes = ["application/json","text/json","text/plain","text/html"]
        manager.post(api, parameters: nil, constructingBodyWith: { (formData) in
            formData.appendPart(withFileData: data, name: "smfile", fileName: fileName, mimeType: type)
        }, progress: { (progress) in
            let imageUploadModel = ImageUploadModel(state:0);
            imageUploadModel.progress = Int(progress.fractionCompleted*100)
            NotificationCenter.default.post(name: ZJUploadNotiName, object: imageUploadModel)
        }, success: { (URLSessionDataTask, responseObject) in
            guard let re = responseObject as? [String:AnyObject] else {
                return
            }
            guard let url = re["data"]?.value(forKey: "url") as? String else{
                NotificationMessage("提示", informative: "文件不能大于5M,请压缩后上传！", isSuccess: false)
                NotificationCenter.default.post(name: ZJUploadNotiName, object: ImageUploadModel(state: 2))
                return
            }
            NotificationMessage("上传图片成功", isSuccess: true)
            NotificationCenter.default.post(name: ZJUploadNotiName, object: ImageUploadModel(state:1))
            NSPasteboard.general.clearContents()
            let picUrl = url;
            let picUrlS  = LinkType.getLink(path:picUrl,type:AppCache.shared.appConfig.linkType);
            NSPasteboard.general.setString(picUrlS, forType: .string)
            let cacheDic: [String: AnyObject] = ["image": NSImage(data: data)!, "url": picUrl as AnyObject]
            AppCache.shared.adduploadImageToCache(cacheDic)
        }) { (URLSessionDataTask, error) in
            NotificationCenter.default.post(name: ZJUploadNotiName, object: ImageUploadModel(state: 2))
            NotificationMessage("提示", informative: "文件不能大于5M,请压缩后上传！", isSuccess: false)
            //print(error);
            
        }
        
    }
    

}
