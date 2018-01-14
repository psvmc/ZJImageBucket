//
//  QSUtils.h
//  AliOSSTest
//
//  Created by psvmc on 2017/8/4.
//  Copyright © 2017年 psvmc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QSUtils : NSObject

+ (NSString *)calBase64Sha1WithData:(NSString *)data withSecret:(NSString *)key;

+ (NSString*)calBase64WithData:(uint8_t *)data;

@end
