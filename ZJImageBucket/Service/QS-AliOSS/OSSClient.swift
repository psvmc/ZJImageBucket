import Alamofire

class OSSClient: NSObject {
    
    static let shared = OSSClient()
    override init() {}
    
    public enum OSSAvaliableType {
        case fail
        case sucess
        case errorLocation
        case none
    }
    
    func getUploadType(_ data: Data) -> String {
        var c: uint8 = 0
        data.copyBytes(to: &c, count: 1)
        switch c {
        case 0xFF:
            //jpeg
            return "image/jpeg"
        case 0x89:
            //png
            return "image/png"
        case 0x49:
            //tiff
            return "image/tiff"
        case 0x4D:
            //tiff
            return "image/tiff"
        case 0x52:
            //webp
            guard data.count > 12, let str = String(data: data.subdata(in: 0..<13), encoding: .ascii), str.hasPrefix("RIFF"), str.hasPrefix("WEBP") else {
                return "application/octet-stream"
            }
            return "application/octet-stream"
        default:
            return "application/octet-stream"
        }
    }
    
    func getOSSServiceBuckets(endPoint host:String, _ accessKeyId:String, _ accessKeySecret:String, _ completeBlock:@escaping (_ buckets:[OSSBucketModel]?, _ error:Error?) -> Void) {
        let date:String = (NSDate.oss_clockSkewFixed()! as NSDate).oss_asStringValue()! as String
        let unCodeStr = "GET\n\napplication/octet-stream\n" + date + "\n/"
        let base64Str = QSUtils.calBase64Sha1(withData: unCodeStr, withSecret: accessKeySecret)! as String
        let authorization = "OSS" + " " + accessKeyId + ":" + base64Str
        let header = ["Content-Type":"application/octet-stream",
                      "Host":host,
                      "Date":date,
                      "Authorization":authorization
                     ]
        let requestURL = URL(string:"https://" + host)!
        Alamofire.request(requestURL, method: .get, parameters: nil, encoding: URLEncoding.default, headers: header).responseData { response in
            print(response)
            switch response.result {
            case .success:
                let buckets = XMLParser(data: response.result.value!)
                
                let delegate = OSSBucketModelParser()
                buckets.delegate = delegate
                buckets.parse()
                let bucketList = delegate.bucketList
                for bucket in bucketList {
                    print(bucket)
                }
                completeBlock(bucketList,nil)
            case .failure(let error):
                completeBlock(nil,error)
                print(error)
            }
        }
    }
    
    func getOSSBucketIsAvaliable(endPoint host:String, _ accessKeyId:String, _ accessKeySecret:String, bucketName bucket:String, bucketLocation location:String,_ completeBlock:@escaping (_ hasBucket:OSSAvaliableType) -> Void) {
        getOSSServiceBuckets(endPoint: host, accessKeyId, accessKeySecret) { (bucketList,error) in
            if error != nil {
                completeBlock(.fail)
                return;
            }
            if (bucketList != nil && (bucketList?.count)! > 0) {
                for obj in bucketList! {
                    if (obj.name == bucket && obj.location == location) {
                        completeBlock(.sucess)
                        return;
                    } else if (obj.name == bucket && obj.location != location) {
                        completeBlock(.errorLocation)
                        return;
                    }
                }
                completeBlock(.none)
            } else {
                completeBlock(.none)
            }
        }
    }
    
    func putImageToOSSBucket(endPoint host:String, bucketName bucket:String, imageName objectKey:String, imageData data:Data, _ accessKeyId:String, _ accessKeySecret:String, _ completeBlock:@escaping (_ uploadResult:Bool) -> Void) {
        let contentType = getUploadType(data)
        let date = (NSDate.oss_clockSkewFixed()! as NSDate).oss_asStringValue()! as String
        let unCodeStr = "PUT\n\n" + contentType + "\n" + date + "\n/" + bucket + "/" + objectKey
        let base64Str = QSUtils.calBase64Sha1(withData: unCodeStr, withSecret: accessKeySecret)! as String
        let authorization = "OSS" + " " + accessKeyId + ":" + base64Str
        let hostStr = bucket + "." + host
        let header = ["Content-Type":contentType,
                      "Host":hostStr,
                      "Date":date,
                      "Authorization":authorization
                      ]
        let requestURL = URL(string:"https://" + hostStr + "/" + objectKey)!
        Alamofire.upload(data, to: requestURL, method: .put, headers: header).uploadProgress(closure: { (progress) in
            let imageUploadModel = ImageUploadModel();
            imageUploadModel.state = 0
            imageUploadModel.progress = Int(progress.fractionCompleted*10)
            NotificationCenter.default.post(name: ZJUploadNotiName, object: imageUploadModel)
            
        }).responseString { response in
            let imageUploadModel = ImageUploadModel();
            imageUploadModel.state = 1
            imageUploadModel.progress = 0
            NotificationCenter.default.post(name: ZJUploadNotiName, object: imageUploadModel)
            switch response.result {
                
            case .success:
                print(response)
                completeBlock(true)
                
            case .failure(let error):
                print(error)
                completeBlock(false)
            }
        }
    }
}


extension OSSClient {
    
    public func AliOSSUpload(_ data:Data?) {
        guard let ossConfig =  AppCache.shared.ossConfig else{
            NotificationMessage("上传图片失败", informative: "请在设置中配置图床")
            return
        }
        if let data = data {
            let fileName = getDateString() + "\(timeInterval())" + "\(arc())" + data.imageFormat.rawValue
            
            OSSClient.shared.putImageToOSSBucket(endPoint: ossConfig.zoneHost, bucketName: ossConfig.bucket, imageName: fileName, imageData: data, ossConfig.accessKey, ossConfig.secretKey, { (uploadResult) in
                if uploadResult {
                    NotificationMessage("上传图片成功", isSuccess: true)
                    NSPasteboard.general.clearContents()
                
                    let picUrl = "https://" + ossConfig.bucket + "." + ossConfig.zoneHost + "/" + fileName
                    let picUrlS  = LinkType.getLink(path:picUrl,type:AppCache.shared.appConfig.linkType)
                    NSPasteboard.general.setString(picUrlS, forType: .string)
                    let cacheDic: [String: AnyObject] = ["image": NSImage(data:data)!, "url": picUrl as AnyObject]
                    AppCache.shared.adduploadImageToCache(cacheDic)
                } else {
                    NotificationMessage("上传图片失败", informative: "可能是配置信息错误，或者是Token过去。请仔细检查配置信息，或重新上传")
                    return
                }
            })
        }
    }
}
