//
//  NSJSONSerialization+RemoveNull.m
//  LXDataManager
//
//  Created by Leon on 16/3/21.
//  Copyright © 2016年 Leon. All rights reserved.
//

#import "NSJSONSerialization+RemoveNull.h"

@implementation NSJSONSerialization (RemoveNull)

//移除 [NSNull null]
+ (id)JSONRemoveNullWithData:(NSData *)data options:(NSJSONReadingOptions)opt error:(NSError *__autoreleasing *)error
{
    id result = [NSJSONSerialization JSONObjectWithData:data options:opt error:error];
    if ([result isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray arrayWithArray:result];
        [NSJSONSerialization recursiveWithArray:array];
        return array;
    }else{
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:result];
        [NSJSONSerialization recursiveWithDictionary:dic];
        return dic;
    }
}

+ (void)recursiveWithDictionary:(NSMutableDictionary *)originDic
{
    //1 移除所有null
    [NSJSONSerialization removeNullValueWithDic:originDic];
    
    NSArray *allkeysValue = [originDic allKeys];
    for (NSString *key in allkeysValue) {
        NSDictionary *dic = originDic[key];
        if ([dic isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *mutableDic = [NSMutableDictionary dictionaryWithDictionary:dic];
            originDic[key] = mutableDic;
            [NSJSONSerialization recursiveWithDictionary:mutableDic];
        }
        
        //
        NSArray *array = originDic[key];
        if ([array isKindOfClass:[NSArray class]]) {
            NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:array];
            originDic[key] = mutableArray;
            [NSJSONSerialization recursiveWithArray:mutableArray];
        }
    }
}

+ (void)recursiveWithArray:(NSMutableArray *)originArray
{
    for (NSInteger n = 0; n < originArray.count ; n++) {
        id subObject = originArray[n];
        if ([subObject isKindOfClass:[NSArray class]]) {
            NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:subObject];
            [originArray replaceObjectAtIndex:n withObject:mutableArray];
            [NSJSONSerialization recursiveWithArray:mutableArray];
        }
        
        if ([subObject isKindOfClass:[NSDictionary class]]) {
            [NSJSONSerialization recursiveWithDictionary:subObject];
        }
    }
}

//移除Dictironary 中的[NSNull null]
+ (void)removeNullValueWithDic:(NSMutableDictionary *)dic
{
    NSArray *keysNullValue = [dic allKeysForObject:[NSNull null]];
    [dic removeObjectsForKeys:keysNullValue];
}


@end
