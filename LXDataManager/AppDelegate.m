//
//  AppDelegate.m
//  LXDataManager
//
//  Created by Leon on 14-2-13.
//  Copyright (c) 2014年 Leon. All rights reserved.
//

#import "AppDelegate.h"
#import "LXDataManager.h"
#import <ASIDownloadCache.h>
#import <ASINetworkQueue.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    //@"http://dldir1.qq.com/qqfile/qq/QQ5.3/10716/QQ5.3.exe"
    /*
    DataRequest *request =  [LXDataManager requestWithURL:[NSURL URLWithString:@"http://dldir1.qq.com/qqfile/qq/QQ5.3/10716/QQ5.3.exe"] callback:^(ASIFormDataRequest *request, BOOL success) {
        //
        NSLog(@"response: %@", request.responseString);

    }];
    request.hud.mode = MBProgressHUDModeDeterminate;
    request.cache = NO;
    request.showHUD = YES;
    request.showError = YES;
    [request startAsynchronous];
    */
    
    
    
    DataRequest *request1 = [DataRequest requestWithURL:[NSURL URLWithString:@"http://www.baidu.com/"]];
    DataRequest *request2 = [DataRequest requestWithURL:[NSURL URLWithString:@"http://www.qq.com/"]];
    //DataRequest *request3 = [DataRequest requestWithURL:[NSURL URLWithString:@"http://dldir1.qq.com/qqfile/qq/QQ5.3/10716/QQ5.3.exe"]];
    NSString *path3 = [NSTemporaryDirectory() stringByAppendingPathComponent:@"request2"];
    [request2 setDownloadDestinationPath:path3];
    NSArray *requests = @[request1, request2];
    DataQueue *queue = [LXDataManager requestWithRequests:requests callback:^(DataQueue *dataQueue, BOOL success) {
        if (success) {
            //
            NSLog(@"response: %@",((ASIFormDataRequest *)dataQueue.requests[1]).downloadDestinationPath);
            return;
        }
        
        NSLog(@"error: %@", requests);
    }];
    
    queue.hud.mode = MBProgressHUDModeIndeterminate;
    queue.cache = NO;
    [queue go];


    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
