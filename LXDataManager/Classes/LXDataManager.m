//
//  DataManager.m
//  ProjectManager
//
//  Created by Leon on 13-8-1.
//  Copyright (c) 2013年 Leon. All rights reserved.
//

#import "LXDataManager.h"
#import <ASIDownloadCache.h>
#import <ASINetworkQueue.h>

NSString *const erroMessage = @"网络连接错误，请稍候再试";
CGFloat const hudDur = 1.5f;

@implementation DataRequest

//只能在这里设置Request
- (void)setCache:(BOOL)cache
{
    _cache = cache;
    if (_cache) {
        //Cache
        //无视服务器的显式“请勿缓存”声明 (例如：cache-control 或者pragma: no-cache 头)
        [[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
        [self setDownloadCache:[ASIDownloadCache sharedCache]];
        //更新修改的
        [self setCachePolicy:ASIAskServerIfModifiedCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
        //永久
        [self setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
        
        [self setRequestMethod:@"GET"];
    }
}
@end

@implementation DataQueue

- (void)setCache:(BOOL)cache
{
    _cache = cache;
    if (_cache) {
        //Cache
        [[ASIDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
        //无视服务器的显式“请勿缓存”声明 (例如：cache-control 或者pragma: no-cache 头)
        for (ASIFormDataRequest *request in self.requests) {
            [request setDownloadCache:[ASIDownloadCache sharedCache]];
            //更新修改的
            [request setCachePolicy:ASIAskServerIfModifiedCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
            //永久
            [request setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
            
            [request setRequestMethod:@"GET"];
        }

    }
}


@end


@implementation LXDataManager

+ (LXDataManager *)shareDataManager
{
   
    static LXDataManager *shareInstance = nil;
    if (shareInstance == nil) {
        @synchronized(self)
        {
            if (shareInstance == nil) {
                shareInstance = [[self alloc] init];
            }
        }
    }
    return shareInstance;
}



#pragma mark - 默认ASIFormDataRequest 处理
+ (DataRequest *)requestWithURL:(NSURL *)url callback:(void (^)(DataRequest *request, BOOL))callback{

    DataRequest *request = [DataRequest requestWithURL:url];
    //默认
    request.showHUD = YES;
    request.showError = YES;
    request.cache = NO;
    __weak DataRequest *_request = request;
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window != nil) {
        request.hud = [[MBProgressHUD alloc] initWithWindow:window];
    }
    
    //Start
    [request setStartedBlock:^{
        if (_request.showHUD) {
            [window addSubview:_request.hud];
            [window bringSubviewToFront:_request.hud];
            [_request.hud show:YES];
        }
    }];

    //Fail
    [request setFailedBlock:^{
        //
        if (window != nil && _request.showError) {
            NSError *error = [_request error];
            NSLog(@"request error code:%li", error.code);
            NSLog(@"request error: %@", error.localizedDescription);
            
            if (_request.hud.superview == nil) {
                [window addSubview:_request.hud];
                [window bringSubviewToFront:_request.hud];
            }
            _request.hud.mode = MBProgressHUDModeText;
            _request.hud.labelText = erroMessage;
            _request.hud.detailsLabelText = error.localizedDescription;
            [_request.hud show:YES];
        }
        
        [_request.hud removeFromSuperViewOnHide];
        [_request.hud hide:YES afterDelay:hudDur];
        
        callback(_request, NO);
    }];
    
    //Complete
    [request setCompletionBlock:^{
        //移出hud
        if (_request.showHUD) {
            [_request.hud removeFromSuperViewOnHide];
            [_request.hud hide:YES];
        }
        //返回
        callback(_request, YES);
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


+ (DataQueue *)requestWithRequests:(NSArray *)requests callback:(void (^)(DataQueue *dataQueue, BOOL success))callback
{
    //Queue
    DataQueue *queue = [[DataQueue alloc] init];
    queue.requests = requests;
    //默认配置
    queue.showHUD = YES;
    queue.showError = YES;
    queue.cache = NO;
    
    __weak DataQueue *_queue = queue;
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window != nil) {
        _queue.hud = [[MBProgressHUD alloc] initWithWindow:window];
    }
    
    //Start
    [queue setQueueStart:^(ASIFormDataRequest * request) {
        if (_queue.showHUD) {
            //Cache
            [window addSubview:_queue.hud];
            [window bringSubviewToFront:_queue.hud];
            [_queue.hud show:YES];
        }
    }];
    

    //Fail
    [queue setQueueFail:^(ASIHTTPRequest *request) {
        //
        if (window != nil && _queue.showError) {
            if (_queue.hud.superview == nil) {
                [window addSubview:_queue.hud];
                [window bringSubviewToFront:_queue.hud];
            }
            
            _queue.hud.mode = MBProgressHUDModeText;
            _queue.hud.labelText = erroMessage;
            _queue.hud.detailsLabelText = request.error.localizedDescription;
            [_queue.hud show:YES];
        }
        
        //
        [_queue.hud removeFromSuperViewOnHide];
        [_queue.hud hide:YES afterDelay:hudDur];
        
        callback(_queue, NO);
    }];
    
    //Complete
    [queue setQueueComplete:^(ASIHTTPRequest *request) {
        //
        if (_queue.hud) {
            [_queue.hud removeFromSuperViewOnHide];
            [_queue.hud hide:YES];
        }
        
        //
        callback(_queue, YES);
    }];
    
    
    //Progress
    [queue setShowAccurateProgress:YES];
    [queue setQueueProgress:^(long long bytes, long long total) {
        //
        if (_queue.showHUD && (_queue.hud.mode == MBProgressHUDModeAnnularDeterminate || _queue.hud.mode == MBProgressHUDModeDeterminateHorizontalBar|| _queue.hud.mode == MBProgressHUDModeDeterminate)) {
            _queue.hud.progress = (float)bytes/total;
        }
    }];
    
    
    //添加任务
    for (DataRequest *request in requests) {
        [queue addOperation:request];
    }
    
    return queue;
}

@end


