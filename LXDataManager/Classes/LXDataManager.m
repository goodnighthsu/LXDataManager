//
//  DataManager.m
//  ProjectManager
//
//  Created by Leon on 13-8-1.
//  Copyright (c) 2013年 Leon. All rights reserved.
//

#import "LXDataManager.h"

CGFloat const kErrorDur = 2.0f;

#define kErrorNetwork  NSLocalizedStringFromTableInBundle(@"Network error, please try again later", @"LXDataManagerLocalizable", [LXDataManager bundle], nil)

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

#pragma mark - 默认ASIFormDataRequest 处理
+ (DataRequest *)requestWithURL:(NSURL *)url callback:(void (^)(DataRequest *result, BOOL))callback{
    __autoreleasing DataRequest *request = [DataRequest requestWithURL:url];
    //默认
    request.showHUD = YES;
    request.showError = YES;
    request.cache = NO;
    request.useLocalCache = NO;
    request.callback = callback;
    //默认配置
    //失效的、错误的 （不检查更新，检查更新会产生服务器请求）
    [request setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
    //永久
    request.cacheStoragePolicy = ASICachePermanentlyCacheStoragePolicy;

    [request setRequestMethod:@"GET"];
    
    request.errorDur = kErrorDur;
    request.hud = [[MBProgressHUD alloc] init];
    request.hud.removeFromSuperViewOnHide = YES;
    
    DataRequest __weak *_request = request;
    //Start
    [request setStartedBlock:^{
        if (_request.showHUD) {
            
            if (_request.hudSuperView == nil) {
                UIWindow *window =[UIApplication sharedApplication].keyWindow;
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
        UIWindow *window =[UIApplication sharedApplication].keyWindow;
        if (window != nil && _request.showError && !_request.cancelled) {
            NSError *error = [_request error];
            NSLog(@"request error code:%li", (long)error.code);
            NSLog(@"request error: %@", error.localizedDescription);
            
            errorHUD = [MBProgressHUD showHUDAddedTo:window animated:YES];
            errorHUD.removeFromSuperViewOnHide = YES;
            errorHUD.mode = MBProgressHUDModeText;
            errorHUD.detailsLabelText = kErrorNetwork;
            [errorHUD show:YES];
            
            [errorHUD hide:YES afterDelay:_request.errorDur];
        }
        
        if (callback != nil) {
             callback(_request, NO);
        }
    }];
    
    //Complete
    [request setCompletionBlock:^{
        //移除hud
        if (_request.showHUD) {
            [_request.hud hide:YES];
        }
        //返回
        if (callback != nil) {
            callback(_request, YES);
        }
    }];
    
    //进度
    __block unsigned long long download = 0;
    __block CGFloat progress;
    [request setBytesReceivedBlock:^(unsigned long long size, unsigned long long total) {
        //
        if (_request.showHUD && (_request.hud.mode == MBProgressHUDModeAnnularDeterminate || _request.hud.mode == MBProgressHUDModeDeterminateHorizontalBar || _request.hud.mode == MBProgressHUDModeDeterminate)) {
            download += size;
            progress = (float)download/total;
            _request.hud.progress = progress;
        }
    }];
    
    return request;
}


#pragma mark 默认DataQueue处理
+ (DataQueue *)requestWithRequests:(NSArray *)requests callback:(void (^)(DataQueue *queue, BOOL success))callback
{
    //Queue
    __autoreleasing DataQueue *queue = [[DataQueue alloc] init];
    queue.requests = requests;
    //默认配置
    queue.showHUD = YES;
    queue.showError = YES;
    queue.errorDur = kErrorDur;
        
    queue.hud = [[MBProgressHUD alloc] init];
    queue.hud.removeFromSuperViewOnHide = YES;
    
    DataQueue __weak  *_queue = queue;
    
    //Start
    [queue setQueueStart:^() {
        if (_queue.showHUD) {
            //
            UIWindow *window =[UIApplication sharedApplication].keyWindow;
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
        UIWindow *window =[UIApplication sharedApplication].keyWindow;
        if (window != nil && _queue.showError && !request.cancelled) {
            NSError *error = [request error];
            NSLog(@"request error code:%li", (long)error.code);
            NSLog(@"request error: %@", error.localizedDescription);
            errorHUD = [MBProgressHUD showHUDAddedTo:window animated:YES];
            errorHUD.removeFromSuperViewOnHide = YES;
            errorHUD.mode = MBProgressHUDModeText;
            errorHUD.detailsLabelText = kErrorNetwork;
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
        if (_queue.showHUD && (_queue.hud.mode == MBProgressHUDModeAnnularDeterminate || _queue.hud.mode == MBProgressHUDModeDeterminateHorizontalBar|| _queue.hud.mode == MBProgressHUDModeDeterminate)) {
            _queue.hud.progress = (float)bytes/total;
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
@end


