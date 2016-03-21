//
//  NSJSONSerialization+RemoveNull.h
//  LXDataManager
//
//  Created by Leon on 16/3/21.
//  Copyright © 2016年 Leon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSJSONSerialization (RemoveNull)

+ (id)JSONRemoveNullWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError *__autoreleasing *)error;

@end
