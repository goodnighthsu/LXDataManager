//
//  DataManager.m
//  ProjectManager
//
//  Created by Leon on 13-8-1.
//  Copyright (c) 2013年 Leon. All rights reserved.
//

#import "LXDataManager.h"
#import "NSJSONSerialization+RemoveNull.h"

CGFloat const kErrorDur = 2.0f;

//#define kErrorNetwork  NSLocalizedStringFromTableInBundle(@"Network error, please try again later", @"LXDataManagerLocalizable", [LXDataManager bundle], nil)
#define kErrorNetwork  @"网络未连接，请稍后再试"
#define kHUDClass @"MBProgressHUD"

ASICacheStoragePolicy const kCacheStoragePolicy = ASICachePermanentlyCacheStoragePolicy;


@implementation DataRequest
//只能在这里设置Request
- (void)setCache:(BOOL)cache
{
    _cache = cache;
    if (_cache) {
        //Cache
        [self setDownloadCache:[ASIDownloadCache sharedCache]];
    }else
    {
        [self setDownloadCache:nil];
    }
}

- (void)startAsynchronous
{
    if (self.useLocalCache) {
        [self directUseLocalCache];
    }else{
        [super startAsynchronous];
    }
}

- (void)startSynchronous
{
    if (self.useLocalCache) {
        [self directUseLocalCache];
    }else{
        [super startSynchronous];
    }
}

//直接使用本地的cache，不进入队列
- (void)directUseLocalCache
{
    NSData *data = [[ASIDownloadCache sharedCache] cachedResponseDataForURL:self.url];
    [self setRawResponseData:[NSMutableData dataWithData:data]];
    if (self.callback != nil) {
        self.callback(self, YES);
    }
}

- (PMKPromise *)promise
{
    return [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
        DataRequest *tempRequest = [LXDataManager requestWithURL:url callback:^(id result, BOOL success) {
            resolve(result);
        }];
        
        tempRequest.showHUD = NO;
        tempRequest.showError = NO;
        tempRequest.cache = self.cache;
        tempRequest.useLocalCache = self.useLocalCache;
        tempRequest.isJSON = self.isJSON;
        tempRequest.isRemoveNull = self.isRemoveNull;
        
        [tempRequest startAsynchronous];
    }];
}

@end


#pragma mark - DataQueue
@implementation DataQueue

- (void)go
{
    //不cache 或没有cache
    for (DataRequest *request in self.requests) {
        [self addOperation:request];
    }

    //没有reqeusts 直接完成
    if (self.requests.count == 0) {
        self.queueComplete(self, YES);
        return;
    }
    
    [super go];
}

@end

#pragma mark - LXDataManager
@implementation LXDataManager

+ (LXDataManager *)shareDataManager
{
    static LXDataManager *dataManager = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        dataManager = [[self alloc] init];
        dataManager.defaultErrorNetwork = kErrorNetwork;
        dataManager.defaultErrorDur = kErrorDur;
        dataManager.defaultHudClassName = kHUDClass;
    });
    
    return dataManager;
    
}

#pragma mark - 默认ASIFormDataRequest 处理
+ (void)configRequest:(DataRequest *)request
{
    //默认配置
    //失效的、错误的 （不检查更新，检查更新会产生服务器请求）
    [request setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
    //永久
    request.cacheStoragePolicy = ASICachePermanentlyCacheStoragePolicy;
    
    [request setRequestMethod:@"GET"];
    
    request.errorDur = [LXDataManager shareDataManager].defaultErrorDur;
    //HUD
    NSString *hudName = [LXDataManager shareDataManager].defaultHudClassName;
    HUDView *hud = [[NSClassFromString(hudName) alloc] init];
    if ([hud isKindOfClass:[MBProgressHUD class]])
    {
        ((MBProgressHUD *)hud).removeFromSuperViewOnHide = YES;
    }
    request.hud = hud;
    
    DataRequest  *_request = request;
    //Start
    [request setStartedBlock:^{
        if (_request.showHUD) {
            
            if (_request.hudSuperView == nil) {
                //避免Keyboard遮挡
                //不使用 [[UIApplication sharedApplication].windows lastObject]
                //参看http://help.bugtags.com/hc/kb/article/77692/
                UIWindow *window = [LXDataManager lastWindow];
                _request.hudSuperView = window;
            }
            
            if (_request.hudSuperView != nil) {
                for (UIView *subView in _request.hudSuperView.subviews) {
                    if ([subView isKindOfClass:[MBProgressHUD class]]) {
                        [subView removeFromSuperview];
                    }
                }
                
                [_request.hudSuperView addSubview:_request.hud];
                [_request.hudSuperView bringSubviewToFront:_request.hud];
                [_request.hud show:YES];
            }
        }
    }];
    
    //Fail
    [request setFailedBlock:^{
        //移除Start的默认HUD
        [_request.hud hide:YES];
        
        //显示错误用的HUD
        MBProgressHUD *errorHUD = nil;
        UIWindow *window = [LXDataManager lastWindow];
        if (window != nil && _request.showError && !_request.cancelled) {
            errorHUD = [MBProgressHUD showHUDAddedTo:window animated:YES];
            errorHUD.removeFromSuperViewOnHide = YES;
            errorHUD.mode = MBProgressHUDModeText;
            errorHUD.detailsLabelText = [LXDataManager shareDataManager].defaultErrorNetwork;
            [errorHUD show:YES];
            
            [errorHUD hide:YES afterDelay:_request.errorDur];
        }
        
        if (_request.callback != nil) {
            _request.callback(_request.error, NO);
        }
    }];
    
    //Complete
    [request setCompletionBlock:^{
        //移除hud
        if (_request.showHUD) {
            [_request.hud hide:YES];
        }
        //返回
        if (request.callback != nil) {
            if (_request.isJSON) {
                [LXDataManager parseJSONWithRequest:_request callback:^(NSDictionary *dic, BOOL succsss) {
                    _request.callback(dic, succsss);
                }];
            }else{
                _request.callback(_request, YES);
            }
        }
    }];
    
    //进度
    __block unsigned long long download = 0;
    __block CGFloat progress;
    [request setBytesReceivedBlock:^(unsigned long long size, unsigned long long total) {
        //
        if (_request.showHUD) {
            download += size;
            progress = (float)download/total;
            if ([_request.hud isKindOfClass:[MBProgressHUD class]]) {
                MBProgressHUD *hud = (MBProgressHUD *)_request.hud;
                hud.progress = progress;
            }else if ([_request.hud respondsToSelector:@selector(setProgress:)])
            {
                [_request.hud setProgress:progress];
            }
        }
    }];
}

+ (DataRequest *)requestWithURL:(NSURL *)url callback:(void (^)(id, BOOL))callback{
    __autoreleasing DataRequest *request = [DataRequest requestWithURL:url];
    //默认
    request.showHUD = YES;
    request.showError = YES;
    request.cache = NO;
    request.useLocalCache = NO;
    request.isJSON = NO;
    request.isRemoveNull = YES;
    request.callback = callback;
    
    [LXDataManager configRequest:request];
    
    return request;
}

#pragma mark - JSON Request
+ (DataRequest *)JSONRequestWithURL:(NSURL *)url callback:(void (^)(id json, BOOL success))callback;
{
    DataRequest *request = [LXDataManager requestWithURL:url callback:^(DataRequest *result, BOOL success) {
        if (success)
        {
            [LXDataManager parseJSONWithRequest:result callback:^(id dic, BOOL parseSuccess) {
                if (callback != nil)
                {
                    callback(dic, parseSuccess);
                }
            }];
            
        }else{
            if (callback != nil) {
                callback(nil, NO);
            }
        }
    }];
    
    return request;
}

+ (void)parseJSONWithRequest:(DataRequest *)request callback:(void (^)(id dic, BOOL succsss))callback
{
    BOOL success = YES;
    NSError *error = nil;
    NSMutableDictionary *dic = nil;
    id parseResult = nil;
    if (request.isRemoveNull) {
        parseResult = [NSJSONSerialization JSONRemoveNullWithData:request.responseData options:NSJSONReadingMutableContainers error:&error];
    }else
    {
        parseResult = [NSJSONSerialization JSONObjectWithData:request.responseData options:NSJSONReadingMutableContainers error:&error];
    }
    
    if ([parseResult isKindOfClass:[NSArray class]]) {
        dic = [NSMutableDictionary dictionary];
        [dic setObject:parseResult forKey:@"result"];
    }
    
    if ([parseResult isKindOfClass:[NSDictionary class]]) {
        dic = parseResult;
    }
    
    if (error != nil) {
        //解析失败
        NSLog(@"JSON parse error: %@", error.description);
        dic = nil;
        success = NO;
        callback(error, NO);
    }else{
        callback(dic, YES);
    }
}

#pragma mark - 默认DataQueue处理
+ (DataQueue *)requestWithRequests:(NSArray *)requests callback:(void (^)(DataQueue *queue, BOOL success))callback
{
    //Queue
    __autoreleasing DataQueue *queue = [[DataQueue alloc] init];
    queue.requests = requests;
    //默认配置
    queue.showHUD = YES;
    queue.showError = YES;
    queue.errorDur = [LXDataManager shareDataManager].defaultErrorDur;
        
    //HUD
    NSString *hudName = [LXDataManager shareDataManager].defaultHudClassName;
    HUDView *hud = [[NSClassFromString(hudName) alloc] init];
    if ([hud isKindOfClass:[MBProgressHUD class]])
    {
        ((MBProgressHUD *)hud).removeFromSuperViewOnHide = YES;
    }
    queue.hud = hud;
    
    DataQueue *_queue = queue;
    
    //Start
    [queue setQueueStart:^() {
        if (_queue.showHUD) {
            //
            UIWindow *window = [LXDataManager lastWindow];
            if (_queue.hudSuperView == nil && window != nil) {
                _queue.hudSuperView = window;
            }
            
            //Cache
            if (_queue.hudSuperView != nil) {
                for (UIView *subView in _queue.hudSuperView.subviews) {
                    if ([subView isKindOfClass:[MBProgressHUD class]]) {
                        [subView removeFromSuperview];
                    }
                }
                
                [_queue.hudSuperView addSubview:_queue.hud];
                [_queue.hudSuperView bringSubviewToFront:_queue.hud];
                [_queue.hud show:YES];
            }
        }
    }];
    
    //Fail
    [queue setQueueFail:^(ASIHTTPRequest *request) {
        //移除Start的默认HUD
        [_queue.hud hide:YES];
        
        //显示错误用的HUD
        MBProgressHUD *errorHUD = nil;
        UIWindow *window = [LXDataManager lastWindow];
        if (window != nil && _queue.showError && !request.cancelled) {
            errorHUD = [MBProgressHUD showHUDAddedTo:window animated:YES];
            errorHUD.removeFromSuperViewOnHide = YES;
            errorHUD.mode = MBProgressHUDModeText;
            errorHUD.detailsLabelText = [LXDataManager shareDataManager].defaultErrorNetwork;
            [errorHUD show:YES];
            [errorHUD hide:YES afterDelay:_queue.errorDur];
        }
        if (callback != nil) {
            callback(_queue, NO);
        }
    }];
    
    //Complete
    [queue setQueueComplete:^() {
        if (_queue.hud) {
            [_queue.hud hide:YES];
        }
        if (callback != nil) {
            callback(_queue, YES);
        }
    }];
    
    //Progress
    [queue setShowAccurateProgress:YES];
    [queue setQueueProgress:^(long long bytes, long long total) {
        //
        if (_queue.showHUD) {
            CGFloat progress = (float)bytes/total;
            if ([_queue.hud isKindOfClass:[MBProgressHUD class]]) {
                MBProgressHUD *hud = (MBProgressHUD *)_queue.hud;
                hud.progress = progress;
            }else if ([_queue.hud respondsToSelector:@selector(setProgress:)])
            {
                [_queue.hud setProgress:progress];
            }

        }
    }];
    
    return queue;
}

#pragma mark - CacheSize
+ (NSString *)cacheSize
{
    NSString *folderPath = [[ASIDownloadCache sharedCache] storagePath];
    folderPath = [folderPath stringByAppendingPathComponent:@"PermanentStore"];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];
    
    NSString *file;
    unsigned long long int folderSize = 0;
    
    while (file = [contentsEnumurator nextObject]) {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:file] error:nil];
        folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
    }
    
    //This line will give you formatted size from bytes ....
    NSString *folderSizeStr = [NSByteCountFormatter stringFromByteCount:folderSize countStyle:NSByteCountFormatterCountStyleFile];
    return folderSizeStr;
}


#pragma mark - ClearCache
+ (void)clearCache
{
    [[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:kCacheStoragePolicy];
}

#pragma mark - Resource Bundle
+ (NSBundle *)bundle
{
    __autoreleasing NSBundle *bundle;
    
    NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"LXDataManager" withExtension:@"bundle"];
    
    if (bundleURL) {
        // LXDataManager.bundle will likely only exist when used via CocoaPods
        bundle = [NSBundle bundleWithURL:bundleURL];
    } else {
        bundle = [NSBundle mainBundle];
    }
    
    return bundle;
}

#pragma mark - Last Window
+ (UIWindow *)lastWindow
{
    NSArray *windows = [UIApplication sharedApplication].windows;
    for(UIWindow *window in [windows reverseObjectEnumerator])
    {
        if ([window isKindOfClass:[UIWindow class]] &&
            CGRectEqualToRect(window.bounds, [UIScreen mainScreen].bounds) && [NSStringFromClass([window class]) isEqualToString:@"UITextEffectsWindow"])
        {
            return window;
        }
    }
    
    return [UIApplication sharedApplication].keyWindow;
}
@end


