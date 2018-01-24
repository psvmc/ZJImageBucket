//
//  ZJMainWinController.swift
//  ZJImageBucket
//
//  Created by 张剑 on 2018/1/22.
//  Copyright © 2018年 chenxt. All rights reserved.
//

import Cocoa
import TMCache

class ZJMainWinController: NSWindowController,NSWindowDelegate,NSTableViewDelegate,NSTableViewDataSource,DragDropImageViewDelegate {
    
    @IBOutlet weak var view: NSView!
    @IBOutlet weak var topSegmentControl: NSSegmentedControl!
    @IBOutlet weak var imageViewOuter: NSView!
    @IBOutlet weak var tableViewOuter: NSView!
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var tableBgLabel: NSTextField!
    var tableData:[ImageCellModel] = []
    
    @IBOutlet weak var imageView: DragDropImageView!
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.delegate = self;
        resetView()
        initTableView()
        initImageView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(uploadStateChange(noti:)), name: ZJUploadNotiName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(clearCacheNoti(noti:)), name: ZJClearCacheNotiName, object: nil)
        
    }
    
    func windowWillClose(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func uploadStateChange(noti: Notification){
        if let uploadModel = noti.object as? ImageUploadModel{
            DispatchQueue.main.async {
                if(uploadModel.state == 0){
                    let progress = uploadModel.progress
                    self.imageView.isHidden = true;
                    self.progressIndicator.isHidden = false;
                    self.progressIndicator.doubleValue = Double(progress)
                }else {
                    self.imageView.isHidden = false;
                    self.progressIndicator.isHidden = true;
                    self.progressIndicator.doubleValue = 100
                }
            }
        }
    }
    
    @objc func clearCacheNoti(noti: Notification){
        self.reloadTableData()
    }
    
    func initImageView(){
        self.imageView.delegate = self;
    }
    
    func initTableView(){
        self.tableView.selectionHighlightStyle = .none
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.intercellSpacing = NSSize.init(width: 0, height: 0)
    }
    
    func reloadTableData(){
        self.tableData.removeAll()
        DispatchQueue.global().async {
            let object = TMCache.shared().object(forKey: "imageCache")
            if let obj = object as? [[String: AnyObject]] {
                AppCache.shared.imagesCacheArr = obj
                for i in (0..<obj.count).reversed() {
                    let item = obj[i]
                    let imageCellModel = ImageCellModel();
                    if let image = item["image"] as? NSImage{
                        image.scalingImage(width: 300)
                        imageCellModel.image = image
                    }
                    if let url = item["url"] as? NSString{
                        imageCellModel.url = url
                    }
                    self.tableData.append(imageCellModel)
                }
            }
            
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
        
    }
    
    @IBAction func topSegmentClick(_ sender: NSSegmentedControl) {
        resetView()
    }
    func resetView(){
        if(topSegmentControl.selectedSegment == 0){
            imageViewOuter.isHidden = false;
            tableViewOuter.isHidden = true;
        }else{
            reloadTableData()
            imageViewOuter.isHidden = true;
            tableViewOuter.isHidden = false;
        }
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        AppDelegate.appDelegate.mainWinController = nil
        return true
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if(self.tableData.count > 0){
            self.tableView.isHidden = false;
            self.tableBgLabel.isHidden = true;
        }else{
            self.tableView.isHidden = true;
            self.tableBgLabel.isHidden = false;
        }
        return self.tableData.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let imageCellModel = self.tableData[row]
        let view = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as! NSTableCellView
        let image = imageCellModel.image
        view.imageView?.image = image
        return view
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let imageCellModel = self.tableData[row]
        let image = imageCellModel.image
        
        if let height = image?.size.height{
            if(height>200){
                return 200
            }
            return height
        }else{
            return 160
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = self.tableView.selectedRow
        let imageCellModel = self.tableData[row]
        if let url = imageCellModel.url{
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(LinkType.getLink(path: url as String, type: AppCache.shared.appConfig.linkType), forType: .string)
            NotificationMessage("图片链接获取成功", isSuccess: true)
        }
    }
    
    func dropComplete(_ filePath: String!) {
        do{
            let data = try Data.init(contentsOf: URL.init(fileURLWithPath: filePath))
            ImageService.shared.uploadImg(data: data)
        }catch{
            
        }
    }
}
