//
//  DataManager.m
//  ProjectManager
//
//  Created by Leon on 13-8-1.
//  Copyright (c) 2013年 Leon. All rights reserved.
//

#import "LXDataManager.h"

CGFloat const kErrorDur = 2.0f;
CGFloat const kSecondsToCache = 60*5;

ASICacheStoragePolicy const kCachePolicy = ASICachePermanentlyCacheStoragePolicy;

@implementation DataDownloadCache

- (BOOL)isCachedDataCurrentForRequest:(ASIHTTPRequest *)request
{
	[[self accessLock] lock];
	if (![self storagePath]) {
		[[self accessLock] unlock];
		return NO;
	}
	NSDictionary *cachedHeaders = [self cachedResponseHeadersForURL:[request url]];
	if (!cachedHeaders) {
		[[self accessLock] unlock];
		return NO;
	}
	NSString *dataPath = [self pathToCachedResponseDataForURL:[request url]];
	if (!dataPath) {
		[[self accessLock] unlock];
		return NO;
	}
    
	// New content is not different
	if ([request responseStatusCode] == 304) {
		[[self accessLock] unlock];
		return YES;
	}
    
	// If we already have response headers for this request, check to see if the new content is different
	// We check [request complete] so that we don't end up comparing response headers from a redirection with these
	if ([request responseHeaders] && [request complete]) {
        
		// If the Etag or Last-Modified date are different from the one we have, we'll have to fetch this resource again
		NSArray *headersToCompare = [NSArray arrayWithObjects:@"Etag",@"Last-Modified",nil];
		for (NSString *header in headersToCompare) {
			if (![[[request responseHeaders] objectForKey:header] isEqualToString:[cachedHeaders objectForKey:header]]) {
				[[self accessLock] unlock];
				return NO;
			}
		}
	}
    
    //修改就算 shouldRespectCacheControlHeaders = NO，当服务器声明不缓存的时候，本地secondsToCache也有效
	// Look for X-ASIHTTPRequest-Expires header to see if the content is out of date
    NSNumber *expires = [cachedHeaders objectForKey:@"X-ASIHTTPRequest-Expires"];
    if (expires) {
        if ([[NSDate dateWithTimeIntervalSince1970:[expires doubleValue]] timeIntervalSinceNow] >= 0) {
            [[self accessLock] unlock];
            return YES;
        }else{
            // No explicit expiration time sent by the server
            [[self accessLock] unlock];
            return NO;
        }
    }
    
    [[self accessLock] unlock];
	return YES;
}

@end

@implementation DataRequest

//只能在这里设置Request
- (void)setCache:(BOOL)cache
{
    _cache = cache;
    if (_cache) {
        //Cache
        //无视服务器的显式“请勿缓存”声明 (例如：cache-control 或者pragma: no-cache 头)
        [[DataDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
        [self setDownloadCache:[DataDownloadCache sharedCache]];
        //更新修改的
        [self setCachePolicy:ASIAskServerIfModifiedWhenStaleCachePolicy|ASIAskServerIfModifiedCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
        //永久
        [self setCacheStoragePolicy:kCachePolicy];
        
        [self setRequestMethod:@"GET"];
    }
}
@end

@implementation DataQueue

/*
- (void)setCache:(BOOL)cache
{
    _cache = cache;
    if (_cache) {
        //Cache
        [[DataDownloadCache sharedCache] setShouldRespectCacheControlHeaders:NO];
        //无视服务器的显式“请勿缓存”声明 (例如：cache-control 或者pragma: no-cache 头)
        for (ASIFormDataRequest *request in self.requests) {
            [request setDownloadCache:[DataDownloadCache sharedCache]];
            //更新修改的
            [request setCachePolicy:ASIAskServerIfModifiedCachePolicy|ASIFallbackToCacheIfLoadFailsCachePolicy];
            //永久
            [request setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
            
            [request setRequestMethod:@"GET"];
        }

    }
}
 */


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
    request.errorDur = kErrorDur;
    request.hud = [[MBProgressHUD alloc] init];
    request.secondsToCache = kSecondsToCache;
    
    __weak DataRequest *_request = request;
    //Start
    [request setStartedBlock:^{
        if (_request.showHUD) {
            if (_request.hudSuperView == nil) {
                UIWindow *window =[UIApplication sharedApplication].keyWindow;
                _request.hudSuperView = window;

            }
            [_request.hudSuperView addSubview:_request.hud];
            [_request.hudSuperView bringSubviewToFront:_request.hud];
            [_request.hud show:YES];
        }
    }];

    //Fail
    [request setFailedBlock:^{
        //移除Start的默认HUD
        [_request.hud removeFromSuperViewOnHide];
        [_request.hud hide:YES];
        
        //显示错误用的HUD
        MBProgressHUD *errorHUD = nil;
        UIWindow *window =[UIApplication sharedApplication].keyWindow;
        if (window != nil && _request.showError) {
            NSError *error = [_request error];
            NSLog(@"request error code:%li", (long)error.code);
            NSLog(@"request error: %@", error.localizedDescription);
            errorHUD = [MBProgressHUD showHUDAddedTo:window animated:YES];
            errorHUD.mode = MBProgressHUDModeText;
            errorHUD.detailsLabelText = NSLocalizedStringFromTable(@"ERROR_NETWORK", @"LXDataManagerLocalizable", @"");
            [errorHUD show:YES];
        }
        
        [errorHUD removeFromSuperViewOnHide];
        [errorHUD hide:YES afterDelay:_request.errorDur];
        
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
    queue.errorDur = kErrorDur;
    queue.hud = [[MBProgressHUD alloc] init];
    
    __weak DataQueue *_queue = queue;
    //Start
    [queue setQueueStart:^(ASIFormDataRequest * request) {
        
        if (_queue.showHUD) {
            //
            if (_queue.hudSuperView == nil) {
                UIWindow *window =[UIApplication sharedApplication].keyWindow;
                _queue.hudSuperView = window;
            }
            //Cache
            [_queue.hudSuperView addSubview:_queue.hud];
            [_queue.hudSuperView bringSubviewToFront:_queue.hud];
            [_queue.hud show:YES];
        }
    }];
    

    //Fail
    [queue setQueueFail:^(ASIHTTPRequest *request) {
        //移除Start的默认HUD
        [_queue.hud removeFromSuperViewOnHide];
        [_queue.hud hide:YES];
        
        //显示错误用的HUD
        MBProgressHUD *errorHUD = nil;
        UIWindow *window =[UIApplication sharedApplication].keyWindow;
        if (window != nil && _queue.showError) {
            NSError *error = [request error];
            NSLog(@"request error code:%li", (long)error.code);
            NSLog(@"request error: %@", error.localizedDescription);
            errorHUD = [MBProgressHUD showHUDAddedTo:window animated:YES];
            errorHUD.mode = MBProgressHUDModeText;
            errorHUD.detailsLabelText = NSLocalizedStringFromTable(@"ERROR_NETWORK", @"LXDataManagerLocalizable", @"");
            [errorHUD show:YES];
        }

        [errorHUD removeFromSuperViewOnHide];
        [errorHUD hide:YES afterDelay:_queue.errorDur];
        
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


+ (NSString *)cacheSize
{
    NSString *folderPath = [[DataDownloadCache sharedCache] storagePath];
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


+ (void)clearCache
{
    [[DataDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:kCachePolicy];
}



@end


