//
//  DataManager.h
//  ProjectManager
//
//  Created by Leon on 13-8-1.
//  Copyright (c) 2013年 Leon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "MBProgressHUD.h"

@class ASIFormDataRequest;
@class ASINetworkQueue;

/** Ver 0.0.1
 数据中心，结合了ASIHttpRequest 和 MBProgress */
@interface LXDataManager : NSObject <ASIHTTPRequestDelegate>

@property (strong, nonatomic) ASINetworkQueue *asiNetworkQueue;

+ (LXDataManager *)shareDataManager;

/** ASIHttp 使用MBProgressHUD， 添加了ASIHTTP默认的Start，Fail和Complete消息处理
 @param url URL
 @param showHUD 是否显示HUD
 @param showErro 是否显示错误信息
 @param callback block回调提供(ASIFormDataRequest *request)
 */
+ (ASIFormDataRequest *)requestWithURL:(NSURL *)url showHUD:(BOOL)showHUD showError:(BOOL)showError callback:(void (^)(ASIFormDataRequest *request, BOOL))callback;

/** 默认显示错误信息 */
+ (ASIFormDataRequest *)requestWithURL:(NSURL *)url showHUD:(BOOL)showHUD callback:(void (^)(ASIFormDataRequest *request, BOOL))callback;

/** 默认显示HUD*/
+ (ASIFormDataRequest *)requestWithURL:(NSURL *)url callback:(void (^)(ASIFormDataRequest *request,BOOL))callback;

//+ (ASIHTTPRequest *)requestHTTPWithURL:(NSURL *)url showHUD:(BOOL)showHUD callback:(void (^)(ASIHTTPRequest *request))callback;

@end
