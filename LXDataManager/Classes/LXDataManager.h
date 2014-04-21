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
#import "ASINetworkQueue.h"
#import "MBProgressHUD.h"


/// DataRequest ASIFormDataRequest+HUD 
@interface DataRequest : ASIFormDataRequest
/**HUD
 @breif 只有当showHUD==YES，才实例hud。当hud.mode 为进度条类型显示进度（不包含MBProgressHUDModeCustomView）
 */
@property (strong, nonatomic) MBProgressHUD *hud;

/**Cache
 @breif 默认关闭
 条件： ASIAskServerIfModifiedCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy
 保存：ASICachePermanentlyCacheStoragePolicy
 可以通过[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICachePermanentlyCacheStoragePolicy] 清空
 */
@property (assign, nonatomic) BOOL cache;

///默认显示HUD
@property (assign, nonatomic) BOOL showHUD;

///默认显示Error
@property (assign, nonatomic) BOOL showError;

@end

@interface DataQueue : ASINetworkQueue

@property (strong, nonatomic) NSArray *requests;
@property (strong, nonatomic) MBProgressHUD *hud;

/**Cache
 @breif 默认关闭
 条件： ASIAskServerIfModifiedCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy
 保存：ASICachePermanentlyCacheStoragePolicy
 可以通过[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICachePermanentlyCacheStoragePolicy] 清空
 */
@property (assign, nonatomic) BOOL cache;

///默认显示HUD
@property (assign, nonatomic) BOOL showHUD;

///默认显示Error
@property (assign, nonatomic) BOOL showError;


@end


/** Ver 0.1.1
 数据中心，结合了ASIHttpRequest 和 MBProgress */
@interface LXDataManager : NSObject <ASIHTTPRequestDelegate>

@property (strong, nonatomic) NSArray *requests;

+ (LXDataManager *)shareDataManager;

/** ASIHttp 使用MBProgressHUD， 添加了ASIHTTP默认的Start，Fail和Complete消息处理
 @param url URL
 @param callback block回调提供DataQuest 结果， success请求成功与否
 @return DataRequest
 */
+ (DataRequest *)requestWithURL:(NSURL *)url callback:(void (^)(DataRequest *request, BOOL success))callback;

/** 批量下载*/
+ (DataQueue *)requestWithRequests:(NSArray *)requests callback:(void (^)(DataQueue *dataQueue, BOOL success))callback;


@end


