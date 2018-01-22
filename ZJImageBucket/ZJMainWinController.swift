//
//  ZJMainWinController.swift
//  ZJImageBucket
//
//  Created by 张剑 on 2018/1/22.
//  Copyright © 2018年 chenxt. All rights reserved.
//

import Cocoa
import TMCache

class ZJMainWinController: NSWindowController,NSWindowDelegate,NSTableViewDelegate,NSTableViewDataSource {
    
    @IBOutlet weak var view: NSView!
    @IBOutlet weak var topSegmentControl: NSSegmentedControl!
    @IBOutlet weak var imageViewOuter: NSView!
    @IBOutlet weak var tableViewOuter: NSView!
    
    @IBOutlet weak var tableView: NSTableView!
    var tableData:[ImageCellModel] = []
    
    @IBOutlet weak var imageView: NSImageView!
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.delegate = self;
        resetView()
        initTableView()
        initImageView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(uploadStateChange(noti:)), name: ZJUploadNotiName, object: nil)
    }
    
    func windowWillClose(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func uploadStateChange(noti: Notification){
        if let uploadModel = noti.object as? ImageUploadModel{
            if(uploadModel.state == 0){
                let progress = uploadModel.progress
                DispatchQueue.main.async {
                    self.progressIndicator.doubleValue = Double(progress)
                }
                
            }else if(uploadModel.state == 1){
                DispatchQueue.main.async {
                    self.progressIndicator.doubleValue = 0
                }
            }
        }
    }
    
    func initImageView(){
        
    }
    
    func initTableView(){
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
    }
    
    func reloadTableData(){
        self.tableData.removeAll()
        DispatchQueue.global().async {
            let object = TMCache.shared().object(forKey: "imageCache")
            if let obj = object as? [[String: AnyObject]] {
                AppCache.shared.imagesCacheArr = obj
                
                for item in obj{
                    let imageCellModel = ImageCellModel();
                    if let image = item["image"] as? NSImage{
                        image.scalingImage(width: 500)
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
            if(height>400){
                return 400
            }
            return height
        }else{
            return 200
        }
    }
    
    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        
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
}
