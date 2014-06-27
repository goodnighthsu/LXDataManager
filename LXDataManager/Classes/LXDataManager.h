//
//  DataManager.h
//  ProjectManager
//
//  Created by Leon on 13-8-1.
//  Copyright (c) 2013年 Leon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ASIHTTPRequest.h>
#import <ASIFormDataRequest.h>
#import <ASINetworkQueue.h>
#import <ASIDownloadCache.h>

#import "MBProgressHUD.h"

/**DownloadCache
 @breif 修改了isCachedDataCurrentForRequest方法，当服务器声明不缓存的时候，本地secondsToCache也有效
 */
@interface DataDownloadCache : ASIDownloadCache

@end



/// DataRequest ASIFormDataRequest+HUD 
@interface DataRequest : ASIFormDataRequest
/**HUD
 @breif 只有当showHUD==YES，才实例hud。当hud.mode 为进度条类型显示进度（不包含MBProgressHUDModeCustomView）
 */
@property (strong, nonatomic) MBProgressHUD *hud;

/**Cache
 @breif 默认关闭
 条件：ASIAskServerIfModifiedWhenStaleCachePolicy|ASIAskServerIfModifiedCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy
 保存：ASICachePermanentlyCacheStoragePolicy
 可以通过[[DataDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICachePermanentlyCacheStoragePolicy] 清空
 */
@property (assign, nonatomic) BOOL cache;

///默认显示HUD
@property (assign, nonatomic) BOOL showHUD;

/**hud的SuperView
 @breif 默认window, 错误消息忽略hudSuperView, 显示在window
 */
@property (weak, nonatomic) UIView *hudSuperView;

/**错误显示时间
 @breif 默认 2s
 */
@property (assign, nonatomic) CGFloat errorDur;

///默认显示Error
@property (assign, nonatomic) BOOL showError;

@end



///DataQueue
@interface DataQueue : ASINetworkQueue

@property (strong, nonatomic) NSArray *requests;
@property (strong, nonatomic) MBProgressHUD *hud;

/**Cache Deprecated
 @breif 默认关闭, 开启之后默认无视服务器设置
 条件： ASIAskServerIfModifiedCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy
 保存：ASICachePermanentlyCacheStoragePolicy
 可以通过[[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICachePermanentlyCacheStoragePolicy] 清空
 */
@property (assign, nonatomic) BOOL cache __deprecated;

///默认显示HUD
@property (assign, nonatomic) BOOL showHUD;

/**hud的SuperView
 @breif 默认window, 错误消息忽略hudSuperView, 显示在window
 */
@property (weak, nonatomic) UIView *hudSuperView;

/**错误显示时间
 @breif 默认 2s
 */
@property (assign, nonatomic) CGFloat errorDur;

///默认显示Error
@property (assign, nonatomic) BOOL showError;


@end


///数据中心，结合了ASIHttpRequest 和 MBProgress
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

///Cache Size
+ (NSString *)cacheSize;

///Clear Cache
+ (void)clearCache;


@end


