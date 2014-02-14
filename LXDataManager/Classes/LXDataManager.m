//
//  DataManager.m
//  ProjectManager
//
//  Created by Leon on 13-8-1.
//  Copyright (c) 2013年 Leon. All rights reserved.
//

#import "LXDataManager.h"

static LXDataManager *shareInstance = nil;
@implementation LXDataManager

+ (LXDataManager *)shareDataManager
{
    @synchronized(self)
    {
        if (shareInstance == nil) {
            shareInstance = [[self alloc] init];
        }
    }
    
    return shareInstance;
}

#pragma mark - 默认ASIFormDataRequest 处理
+ (ASIFormDataRequest *)requestWithURL:(NSURL *)url showHUD:(BOOL)showHUD showError:(BOOL)showError callback:(void (^)(ASIFormDataRequest *request, BOOL))callback{
    
    ASIFormDataRequest *_request = [ASIFormDataRequest requestWithURL:url];
    __weak ASIFormDataRequest *request = _request;
    
    //Start
    [request setStartedBlock:^{
        //显示loading
        if (showHUD) {
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
            hud.removeFromSuperViewOnHide = YES;
        }
    }];
    
    //Fail
    [request setFailedBlock:^{
        //
        if (showError) {
            NSError *error = [request error];
            NSLog(@"request error code:%i", error.code);
            NSLog(@"request error: %@", error.localizedDescription);
            
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            [MBProgressHUD hideAllHUDsForView:window animated:NO];
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
            hud.removeFromSuperViewOnHide = YES;
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"网络连接错误，请稍候再试";
            hud.detailsLabelText = error.localizedDescription;
            [hud hide:YES afterDelay:1.0];
        }
        
        callback(request, NO);
    }];
    
    //Complete
    [request setCompletionBlock:^{
        //移出所有hud
        if (showHUD) {
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            [MBProgressHUD hideAllHUDsForView:window animated:YES];
        }
        
        //返回
        callback(request, YES);
    }];
    
    return request;
}

#pragma mark - ASIFormDataRequest 默认显示错误信息
+ (ASIFormDataRequest *)requestWithURL:(NSURL *)url showHUD:(BOOL)showHUD callback:(void (^)(ASIFormDataRequest *request, BOOL))callback{
    
    __autoreleasing ASIFormDataRequest *request = [LXDataManager requestWithURL:url showHUD:showHUD showError:YES callback:callback];

    return  request;
}

#pragma mark - ASIFormDataRequest 默认显示HUD
+ (ASIFormDataRequest *)requestWithURL:(NSURL *)url callback:(void (^)(ASIFormDataRequest *request, BOOL success))callback{
    __autoreleasing ASIFormDataRequest *request = [LXDataManager requestWithURL:url showHUD:YES callback:callback];
    
    return request;
}
/*
+ (ASIHTTPRequest *)requestHTTPWithURL:(NSURL *)url showHUD:(BOOL)showHUD callback:(void (^)(ASIHTTPRequest *request))callback{
    
    ASIHTTPRequest *_request = [ASIHTTPRequest requestWithURL:url];
    __weak ASIHTTPRequest *request = _request;
    
    //Start
    [request setStartedBlock:^{
        //显示loading
        if (showHUD) {
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
            hud.removeFromSuperViewOnHide = YES;
        }
    }];
    
    //Fail
    [request setFailedBlock:^{
        //
        NSError *error = [request error];
        NSLog(@"request error code:%i", error.code);
        NSLog(@"request error: %@", error.localizedDescription);
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        MBProgressHUD *hud = [MBProgressHUD HUDForView:window];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"网络连接错误，请稍候再试";
        hud.detailsLabelText = error.localizedDescription;
        [hud hide:YES afterDelay:kHUDNormal];
        
        callback(nil);
    }];
    
    //Complete
    [request setCompletionBlock:^{
        //移出所有hud
        if (showHUD) {
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            [MBProgressHUD hideAllHUDsForView:window animated:YES];
        }
        
        //返回
        callback(request);
    }];
    
    return  request;
}
 */

@end
