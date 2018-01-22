//
//  ZJMainWinController.swift
//  ZJImageBucket
//
//  Created by 张剑 on 2018/1/22.
//  Copyright © 2018年 chenxt. All rights reserved.
//

import Cocoa

class ZJMainWinController: NSWindowController,NSWindowDelegate {
    
    @IBOutlet weak var topSegmentControl: NSSegmentedControl!
    @IBOutlet weak var imageViewOuter: NSView!
    @IBOutlet weak var tableViewOuter: NSView!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.delegate = self;
        resetView()
    }
    @IBAction func topSegmentAction(_ sender: Any) {
        resetView()
    }
    
    @IBAction func topSegmentClick(_ sender: NSSegmentedControl) {
        print(topSegmentControl.selectedSegment)
    }
    func resetView(){
         print(topSegmentControl.selectedSegment)
        if(topSegmentControl.selectedSegment == 0){
            imageViewOuter.isHidden = false;
            tableViewOuter.isHidden = true;
        }else{
            imageViewOuter.isHidden = true;
            tableViewOuter.isHidden = false;
        }
    }
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        print("windowShouldClose")
        return true
    }
    
    func windowDidMove(_ notification: Notification) {
        print("windowDidMove")
    }
}
