//
//  MainViewController.m
//  LXDataManager
//
//  Created by Leon on 14/6/26.
//  Copyright (c) 2014年 Leon. All rights reserved.
//

#import "MainViewController.h"
#import "LXDataManager.h"
#import <PromiseKit/PromiseKit.h>

#define kRequest_Once

@interface LineProgressHUD : UIView

@property (nonatomic, strong) UIView *progressView;
@property (nonatomic, strong) UIView *bgView;

- (void)show:(BOOL)ani;
- (void)hide:(BOOL)ani;
- (void)setProgress:(CGFloat)progress;

@end

@implementation LineProgressHUD

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initializeUI];
    }
    
    return self;
}

- (void)initializeUI
{
    //Bg
    self.bgView = [[UIView alloc] init];
    self.bgView.frame = CGRectMake(0, 0, 320, 1);
    self.bgView.backgroundColor = [UIColor grayColor];
    [self addSubview:self.bgView];
    
    //Progress
    self.progressView = [[UIView alloc] init];
    self.progressView.frame = CGRectMake(0, 0, 0, 1);
    self.progressView.backgroundColor = [UIColor blueColor];
    [self addSubview:self.progressView];
    
    self.frame = CGRectMake(0, 100, 320, 1);
}

- (void)show:(BOOL)ani
{
    self.alpha = 0;
    if (ani) {
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 1;
        }];
    }else
    {
        self.alpha = 1;
    }
}

- (void)hide:(BOOL)ani
{
    if (ani) {
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 0;
        }completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    }else{
        self.alpha = 0;
        [self removeFromSuperview];
    }
}

- (void)setProgress:(CGFloat)progress
{
    CGSize size = self.bgView.bounds.size;
    [UIView animateWithDuration:0.25 animations:^{
        self.progressView.frame = CGRectMake(0, 0, size.width*progress, size.height);
    }];
}

@end

@interface MainViewController ()

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    }

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button
- (IBAction)onRefresh:(id)sender
{
    [LXDataManager shareDataManager].defaultErrorNetwork = @"网络连接中断";
    [LXDataManager shareDataManager].defaultHudClassName = @"LineProgressHUD";
    
    //Promise Request
    [self promiseRequest];
    //JSON Request
    //[self JSONRequest];
    
    /*
#ifdef kRequest_Once
    //@"http://dldir1.qq.com/qqfile/qq/QQ5.3/10716/QQ5.3.exe"
    //@"http://cn.bing.com/"

    DataRequest *request =  [LXDataManager requestWithURL:[NSURL URLWithString:@"http://dldir1.qq.com/qqfile/qq/QQ5.3/10716/QQ5.3.exe"] callback:^(DataRequest *result, BOOL success) {
        NSLog(@"result: %@", result.responseString);
    }];
    
//    MBProgressHUD *hud = (MBProgressHUD *)request.hud;
//    hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    //request.hud.color = [UIColor clearColor];
    request.cache = YES;
    request.secondsToCache = 5;
    request.showHUD = YES;
    request.showError = YES;
//    request.hudSuperView = self.view1;
    request.validatesSecureCertificate = NO;
//    request.useLocalCache = YES;
    [request startAsynchronous];
#else 
    DataRequest *request1 = [DataRequest requestWithURL:[NSURL URLWithString:@"http://cn.bing.com/"]];

    DataRequest *request2 = [DataRequest requestWithURL:[NSURL URLWithString:@"http://www.baidu.com/"]];

    DataRequest *request3 = [DataRequest requestWithURL:[NSURL URLWithString:@"http://www.qq.com/"]];
    
    //NSString *path3= [NSTemporaryDirectory() stringByAppendingPathComponent:@"request2"];
    //[request2 setDownloadDestinationPath:path3];
    
    DataRequest *request4 = [DataRequest requestWithURL:[NSURL URLWithString:@"http://dldir1.qq.com/qqfile/qq/QQ5.3/10716/QQ5.3.exe"]];
    request4.validatesSecureCertificate = NO;

    NSArray *requests = @[request1, request2, request3, request4];
    __weak NSArray *datas = requests;
    DataQueue *queue = [LXDataManager requestWithRequests:datas callback:^(DataQueue *result, BOOL success) {
        if (success) {
            for (DataRequest *request in result.requests) {
                NSLog(@"response: %@", request.responseString);
            }
            NSLog(@"success");
            return;
        }
       NSLog(@"error: %@", requests);
    }];
    
    queue.showHUD = YES;
//    queue.hud.mode = MBProgressHUDModeAnnularDeterminate;
    queue.hudSuperView = self.view2;
    //queue.hud.dimBackground = YES;
    //queue.hud.color = [UIColor clearColor];
    //queue.secondsToCache = 5;
    //queue.hud.animationType = MBProgressHUDAnimationZoom;
    [queue go];
    
#endif
     */
}

- (void)promiseRequest
{
    NSURL *url = [NSURL URLWithString:@"http://127.0.0.1:3000/api/user/1"];
    DataRequest *request1 = [DataRequest requestWithURL:url];
    request1.isJSON = YES;
    
    DataRequest *request2 = [DataRequest requestWithURL:url];
    request2.isJSON = YES;
    
    id promise1 = [request1 promise];
    id promise2 = [request2 promise];
    
    PMKWhen(@[promise1, promise2]).then(^(NSArray *results)
                                        {
                                            NSLog(@"results: %@", results);
                                        });
    
//    [AnyPromise when:(@[promise1, promise2])].then(^(NSArray *results)
//                                                  {
//                                                      NSLog(@"results: %@", results);
//                                                  });
    
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    hud.removeFromSuperViewOnHide = YES;
//    
//    [request1 promise].then(^(NSDictionary *dic)
//                            {
//                                NSLog(@"result: %@", dic);
//                                NSURL *url2 = [NSURL URLWithString:@"http://127.0.0.1:3000/api/user/2"];
//                                DataRequest *request2 = [DataRequest requestWithURL:url2];
//                                request2.isJSON = YES;
//                                return [request2 promise];
//                            })
//    .then(^(NSDictionary *dic)
//          {
//              NSLog(@"result2: %@", dic);
//          })
//    .catch(^(NSError *error)
//           {
//               NSLog(@"error: %@", error.description);
//           })
//    .finally(^
//             {
//                 [hud hide:YES];
//             });
}

- (void)JSONRequest
{
    NSURL *url = [NSURL URLWithString:@"http://127.0.0.1:3000/api/user/1"];
    DataRequest *request = [LXDataManager JSONRequestWithURL:url callback:^(NSDictionary *json, BOOL success) {
        NSLog(@"json: %@", json);
    }];
    
    [request startAsynchronous];
}


-(IBAction)onClearCache:(id)sender
{
    [[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
}

- (IBAction)onCacheSize:(id)sender
{
    NSLog(@"Cache Size: %@", [LXDataManager cacheSize]);
}

- (IBAction)onTotal:(id)sender
{
    NSLog(@"total: %i", self.view2.subviews.count);
}

@end
