//
//  ImageUploadModel.swift
//  ZJImageBucket
//
//  Created by 张剑 on 2018/1/23.
//  Copyright © 2018年 chenxt. All rights reserved.
//

import Foundation

class ImageUploadModel{
    var state:Int = 0; // -1准备上传 0 上传中 1上传完成 2上传失败
    var progress:Int = 0; // 0--100
    
    init(state:Int,progress:Int) {
        self.state = state;
        self.progress = progress;
    }
    
    init(state:Int) {
        self.state = state;
    }
}
