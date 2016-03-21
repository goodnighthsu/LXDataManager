//
//  MainViewController.h
//  LXDataManager
//
//  Created by Leon on 14/6/26.
//  Copyright (c) 2014年 Leon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DataQueue;
@interface MainViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIView *view1;
@property (nonatomic, weak) IBOutlet UIView *view2;

//@property (nonatomic, strong) DataQueue *queue;

- (IBAction)onRefresh:(id)sender;
- (IBAction)onClearCache:(id)sender;
- (IBAction)onCacheSize:(id)sender;

- (IBAction)onTotal:(id)sender;

@end
