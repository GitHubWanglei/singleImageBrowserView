//
//  ViewController.m
//  imagesBrowser
//
//  Created by lihongfeng on 16/2/4.
//  Copyright © 2016年 wanglei. All rights reserved.
//

#import "ViewController.h"
#import "WLSingleImageBrowserView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    CGRect rect = CGRectMake(50, 50, 200, 300);
    
//    WLSingleImageBrowserView *v = [[WLSingleImageBrowserView alloc] initWithFrame:self.view.bounds image:[UIImage imageNamed:@"placeholderImage.jpg"]];
//    v.progressViewType = ProgressViewTypeSingleCircle;
//    [self.view addSubview:v];
    
//    NSString *urlString = @"http://img.pconline.com.cn/images/upload/upc/tx/wallpaper/12";
    NSString *urlString = @"http://img.pconline.com.cn/images/upload/upc/tx/wallpaper/1212/06/c1/16396010_1354784049722.jpg";
    WLSingleImageBrowserView *v1 = [[WLSingleImageBrowserView alloc] initWithFrame:self.view.bounds
                                                                         URLString:urlString
                                                                  placeholderImage:[UIImage imageNamed:@"placeholderImage.jpg"]
                                                                      failureImage:[UIImage imageNamed:@"failureImage"]];
    
//    ProgressViewTypePlainCircle, ProgressViewTypeSystemIndicator, ProgressViewTypeNone
//    v1.progressViewType = ProgressViewTypePlainCircle;
    [self.view addSubview:v1];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
