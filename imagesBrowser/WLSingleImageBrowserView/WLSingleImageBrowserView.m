//
//  WLSingleImageBrowserView.m
//
//  Created by wanglei on 16/2/4.
//  Copyright © 2016年 wanglei. All rights reserved.
//

#import "WLSingleImageBrowserView.h"
#import "WLCircleProgressView.h"

@interface WLSingleImageBrowserView ()<UIScrollViewDelegate, NSURLSessionDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSString *imageUrlString;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, strong) UIImage *failureImage;

//在屏幕上显示图片所需的尺寸(最佳尺寸)与初始显示图片尺寸的比例, 双击放大时按此比例进行缩放
@property (nonatomic, assign) CGFloat originalMaxZoomScale;
//每次要缩放的比例
@property (nonatomic, assign) CGFloat newZoomScale;

@property (nonatomic, assign) CGFloat doubleTapLocation_X;
@property (nonatomic, assign) CGFloat doubleTapLocation_Y;
@property (nonatomic, assign) BOOL displayFromTop;
@property (nonatomic, assign) BOOL displayFromLeft;
@property (nonatomic, assign) BOOL displayFromBottom;
@property (nonatomic, assign) BOOL displayFromRight;
@property (nonatomic, assign) BOOL doubleTapZoom;

@property (nonatomic, strong) WLCircleProgressView *circleProgress;//自定义进度圆环
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;//系统缓冲控件

@end

@implementation WLSingleImageBrowserView

-(instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image{
    self = [super initWithFrame:frame];
    if (self) {
        self.image = image;
        self.doubleTapZoom = NO;
        [self initViewWithImage:self.image];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame URLString:(NSString *)urlStr placeholderImage:(UIImage *)pImage failureImage:(UIImage *)fImage{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        if (urlStr.length > 0) {
            self.placeholderImage = pImage;
            self.failureImage = fImage;
            self.doubleTapZoom = NO;
            self.imageUrlString = urlStr;
            [self initViewWithImage:self.placeholderImage];
            [self requestImageWithURLString:urlStr];
        }
    }
    return self;
}

#pragma mark - 请求网络图片
-(void)requestImageWithURLString:(NSString *)urlStr{
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.timeoutIntervalForRequest = 60;
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDownloadTask *downloadTask = [urlSession downloadTaskWithRequest:request];
    [downloadTask resume];
    
}

#pragma mark - NSURLSessionDownloadDelegate delegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    if (((NSHTTPURLResponse *)(downloadTask.response)).statusCode != 200) {
        
        [session invalidateAndCancel];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self logRequestImageFailureMessageWithError:nil];
            //更换图片
            self.imageView.image = self.failureImage;
            [self recoveryImageViewSize];
            
            self.scrollView.userInteractionEnabled = YES;
        });
        
        return;
    }
    
    CGFloat progress = (totalBytesWritten * 1.0) / (totalBytesExpectedToWrite * 1.0);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.circleProgress.progressValue = progress;
    });
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{
    
    NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:location.path];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //移除进度条
        [self.circleProgress removeFromSuperview];
        [self.indicatorView removeFromSuperview];
        
        //更换图片
        UIImage *image = [UIImage imageWithData:imageData];
        if (image != nil) {//成功
            self.imageView.image = image;
            [self recoveryImageViewSize];
            self.scrollView.userInteractionEnabled = YES;
        }else{//失败
            [self logRequestImageFailureMessageWithError:nil];
            //更换图片
            self.imageView.image = self.failureImage;
            [self recoveryImageViewSize];
            self.scrollView.userInteractionEnabled = YES;
            return;
        }
        
        //关闭连接
        [session invalidateAndCancel];
        
    });
    
}

//打印错误信息
-(void)logRequestImageFailureMessageWithError:(NSError *)error{
#ifdef DEBUG
    if (error == nil) {
        NSLog(@"Request image failure, response image data is nil!");
    }else{
        NSLog(@"Request image failure, error: %@", error.localizedDescription);
    }
#endif
}

#pragma mark - 重新调整 imageView 尺寸
//重新调整imageView尺寸, 限定到scrollView范围内显示
-(void)recoveryImageViewSize{
    
    UIImage *newImage = self.imageView.image;
    
    //计算尺寸
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize pixelSize = newImage.size;//图片像素尺寸
    CGSize originalPointSize = CGSizeMake(pixelSize.width/scale, pixelSize.height/scale);//屏幕上显示所需的尺寸(最佳尺寸), 有可能超过屏幕尺寸
    CGSize displaySize = [self countDisplaySizeWithScopeSize:self.scrollView.bounds.size originalSize:originalPointSize];
    //计算原点
    CGPoint originalPoint = CGPointMake(0, 0);
    originalPoint.x = (self.scrollView.bounds.size.width - displaySize.width) / 2.0f;
    originalPoint.y = (self.scrollView.bounds.size.height - displaySize.height) / 2.0f;
    
    //imageView
    CGRect imageView_frame = CGRectMake(originalPoint.x, originalPoint.y, displaySize.width, displaySize.height);//居中显示
    self.imageView.frame = imageView_frame;
    
    //重新设置scrollView, 防止更新图片时原设置不正确
    self.scrollView.contentSize = CGSizeMake(self.imageView.bounds.size.width, self.imageView.bounds.size.height);
    
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = (originalPointSize.width / displaySize.width) * 1.5f;//最大放大尺寸是原始所需尺寸的1.5倍
    self.originalMaxZoomScale = originalPointSize.width / displaySize.width;//双击放大时按此比例进行缩放
    if (self.originalMaxZoomScale == 1) {
        self.originalMaxZoomScale = self.scrollView.maximumZoomScale;
    }
    
}

#pragma mark - 初始化页面
-(void)initViewWithImage:(UIImage *)image{
    
    self.backgroundColor = [UIColor blackColor];
    
    //scrollView
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.backgroundColor = self.backgroundColor;
    self.scrollView.delegate = self;
    self.scrollView.bounces = YES;
    self.scrollView.scrollEnabled = YES;
    
    //计算尺寸
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize pixelSize = image.size;//图片像素尺寸
    CGSize originalPointSize = CGSizeMake(pixelSize.width/scale, pixelSize.height/scale);//屏幕上显示所需的尺寸(最佳尺寸), 有可能超过屏幕尺寸
    CGSize displaySize = [self countDisplaySizeWithScopeSize:self.scrollView.bounds.size originalSize:originalPointSize];
    //计算原点
    CGPoint originalPoint = CGPointMake(0, 0);
    originalPoint.x = (self.scrollView.bounds.size.width - displaySize.width) / 2.0f;
    originalPoint.y = (self.scrollView.bounds.size.height - displaySize.height) / 2.0f;
    
    //imageView
    CGRect imageView_frame = CGRectMake(originalPoint.x, originalPoint.y, displaySize.width, displaySize.height);//居中显示
    self.imageView = [[UIImageView alloc] initWithFrame:imageView_frame];
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.image = image;
    self.imageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapImageView:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.imageView addGestureRecognizer:doubleTap];
    
    //设置 scrollView
    self.scrollView.contentSize = CGSizeMake(self.imageView.bounds.size.width, self.imageView.bounds.size.height);
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = (originalPointSize.width / displaySize.width) * 1.5f;//最大放大尺寸是原始所需尺寸的1.5倍
    self.originalMaxZoomScale = originalPointSize.width / displaySize.width;//双击放大时按此比例进行缩放
    if (self.originalMaxZoomScale == 1) {
        self.originalMaxZoomScale = self.scrollView.maximumZoomScale;
    }
    
    [self.scrollView addSubview:self.imageView];
    [self addSubview:self.scrollView];
    
    //添加进度条
    if (self.imageUrlString.length > 0) {
        
        CGFloat circleSize = 20;
        CGRect circleProgressBacView_frame = CGRectMake((self.scrollView.bounds.size.width - circleSize * 2.0) / 2.0,
                                                        (self.scrollView.bounds.size.height - circleSize * 2.0) / 2.0,
                                                        circleSize * 2.0,
                                                        circleSize * 2.0);
        CGRect circlesSize = CGRectMake(circleSize+4, 2, circleSize, 4);
        WLCircleProgressView *circleProgress = [WLCircleProgressView viewWithFrame:circleProgressBacView_frame
                                                                       circlesSize:circlesSize];
        circleProgress.backgroundColor = [UIColor clearColor];
        circleProgress.progressValue = 0;
        circleProgress.backCircle.fillColor = [UIColor clearColor].CGColor;
        circleProgress.backCircle.strokeColor = [UIColor clearColor].CGColor;
        circleProgress.foreCircle.fillColor = [UIColor clearColor].CGColor;
        circleProgress.foreCircle.strokeColor = [UIColor whiteColor].CGColor;
        
        self.circleProgress = circleProgress;
        [self.scrollView addSubview:self.circleProgress];
        
    }
    
    if (self.imageUrlString.length > 0) {
        self.scrollView.userInteractionEnabled = NO;
    }
    
}

#pragma mark - 设置进度条样式
-(void)setProgressViewType:(WLProgressViewType)progressViewType{
    
    if (self.imageUrlString == nil) {
        return;
    }
    
    switch (progressViewType) {
        case ProgressViewTypePlainCircle:
        {
            [self.indicatorView removeFromSuperview];
            self.indicatorView = nil;
            [self.circleProgress removeFromSuperview];
            self.circleProgress = nil;
            
            CGFloat circleSize = 20;
            CGRect circleProgressBacView_frame = CGRectMake((self.scrollView.bounds.size.width - circleSize * 2) / 2.0,
                                                            (self.scrollView.bounds.size.height - circleSize * 2) / 2.0,
                                                            circleSize * 2,
                                                            circleSize * 2);
            CGRect circlesSize = CGRectMake(circleSize+4, 2, circleSize, circleSize);
            WLCircleProgressView *circleProgress = [WLCircleProgressView viewWithFrame:circleProgressBacView_frame
                                                                           circlesSize:circlesSize];
            //阴影
            circleProgress.backgroundColor = [UIColor clearColor];
            circleProgress.backCircle.shadowColor = [UIColor grayColor].CGColor;
            circleProgress.backCircle.shadowRadius = 3;
            circleProgress.backCircle.shadowOffset = CGSizeMake(0, 0);
            circleProgress.backCircle.shadowOpacity = 1;
            circleProgress.backCircle.fillColor = [UIColor clearColor].CGColor;
            circleProgress.backCircle.strokeColor = [UIColor colorWithRed:250/255.0 green:250/255.0 blue:250/255.0 alpha:0.9].CGColor;
            
            circleProgress.foreCircle.lineCap = @"butt";
            circleProgress.foreCircle.fillColor = [UIColor clearColor].CGColor;
            circleProgress.foreCircle.strokeColor = [UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:0.5].CGColor;;
            circleProgress.progressValue = 0.0;
            
            self.circleProgress = circleProgress;
            [self.scrollView addSubview:self.circleProgress];
            
        }
            break;
        case ProgressViewTypeSingleCircle:
        {
            //Do nothing here
            
        }
            break;
        case ProgressViewTypeSystemIndicator:
        {
            [self.indicatorView removeFromSuperview];
            self.indicatorView = nil;
            [self.circleProgress removeFromSuperview];
            self.circleProgress = nil;
            
            UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            CGRect indicatorView_frame = CGRectMake((self.scrollView.bounds.size.width - 30) / 2.0,
                                                    (self.scrollView.bounds.size.height - 30) / 2.0,
                                                    30,
                                                    30);
            indicatorView.frame = indicatorView_frame;
            indicatorView.color = [UIColor whiteColor];
            indicatorView.backgroundColor = [UIColor clearColor];
            [indicatorView startAnimating];
            
            self.indicatorView = indicatorView;
            [self.scrollView addSubview:self.indicatorView];
        }
            break;
        case ProgressViewTypeNone:
        {
            [self.indicatorView removeFromSuperview];
            self.indicatorView = nil;
            [self.circleProgress removeFromSuperview];
            self.circleProgress = nil;
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - 双击图片
-(void)doubleTapImageView:(UITapGestureRecognizer *)gesture{
    
    CGFloat newScale = (self.scrollView.zoomScale == 1) ? self.originalMaxZoomScale : 1.0f;
    CGPoint location = [gesture locationInView:gesture.view];
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:location];
    
    self.displayFromTop = NO;
    self.displayFromLeft = NO;
    self.displayFromBottom = NO;
    self.displayFromRight = NO;
    self.newZoomScale = newScale;
    self.doubleTapZoom = YES;
    if (newScale > 1) {//双击放大时,判断点击位置
        
        if (location.y < self.scrollView.bounds.size.height / 2.0 / self.originalMaxZoomScale) {
            self.displayFromTop = YES;
        }
        if (location.x < self.scrollView.bounds.size.width / 2.0 / self.originalMaxZoomScale) {
            self.displayFromLeft = YES;
        }
        if (location.y > self.imageView.bounds.size.height - self.scrollView.bounds.size.height / 2.0 / self.originalMaxZoomScale) {
            self.displayFromBottom = YES;
        }
        if (location.x > self.imageView.bounds.size.width - self.scrollView.bounds.size.width / 2.0 / self.originalMaxZoomScale) {
            self.displayFromRight = YES;
        }
        
        self.doubleTapLocation_X = location.x;
        self.doubleTapLocation_Y = location.y;
        
    }
    
    [self.scrollView zoomToRect:zoomRect animated:YES];
    
}

#pragma mark - UIScrollView delegate
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView{
    
    //imageView 居中显示
    CGFloat xcenter = scrollView.center.x , ycenter = scrollView.center.y;
    xcenter = scrollView.contentSize.width > scrollView.frame.size.width ? scrollView.contentSize.width/2 : xcenter;
    ycenter = scrollView.contentSize.height > scrollView.frame.size.height ? scrollView.contentSize.height/2 : ycenter;
    [self.imageView setCenter:CGPointMake(xcenter, ycenter)];
    
    //双击时,从双击处开始放大
    if (self.doubleTapZoom == YES) {
        
        if (self.displayFromTop == YES && self.displayFromLeft == NO && self.displayFromRight == NO) {//靠近顶部
            if (self.newZoomScale > 1) {
                [self.scrollView setContentOffset:CGPointMake(self.doubleTapLocation_X * self.originalMaxZoomScale - self.scrollView.bounds.size.width / 2.0,
                                                              0) animated:NO];
            }
        }else if (self.displayFromTop == YES && self.displayFromLeft == YES){//靠近左上
            [self.scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
        }else if (self.displayFromTop == YES && self.displayFromRight == YES){//靠近右上
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, 0) animated:NO];
        }else if (self.displayFromBottom == YES && self.displayFromLeft == NO && self.displayFromRight == NO){//靠近底部
            if (self.newZoomScale > 1) {
                CGPoint contentOffset = CGPointMake(self.doubleTapLocation_X * self.originalMaxZoomScale - self.scrollView.bounds.size.width / 2.0,
                                                    self.scrollView.contentOffset.y);
                [self.scrollView setContentOffset:contentOffset animated:NO];
            }
        }else if (self.displayFromBottom == YES && self.displayFromLeft == YES){//靠近左下
            [self.scrollView setContentOffset:CGPointMake(0, self.scrollView.contentOffset.y) animated:NO];
        }else if (self.displayFromBottom == YES && self.displayFromRight == YES){//靠近右下
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.contentOffset.x, self.scrollView.contentOffset.y) animated:NO];
        }else if (self.displayFromRight == YES){//靠近右边
            if (self.newZoomScale > 1) {
                CGPoint contentOffset = CGPointMake(self.scrollView.contentOffset.x,
                                                    self.doubleTapLocation_Y * self.originalMaxZoomScale - self.scrollView.bounds.size.height / 2.0);
                [self.scrollView setContentOffset:contentOffset animated:NO];
            }
        }else if (self.displayFromLeft == YES){//靠近左边
            if (self.newZoomScale > 1) {
                CGPoint contentOffset = CGPointMake(0,
                                                    self.doubleTapLocation_Y * self.originalMaxZoomScale - self.scrollView.bounds.size.height / 2.0);
                [self.scrollView setContentOffset:contentOffset animated:NO];
            }
        }else{//双击靠近中间位置, 从双击处定点放大
            if (self.newZoomScale > 1) {
                CGPoint contentOffset = CGPointMake(self.doubleTapLocation_X * self.originalMaxZoomScale - self.scrollView.bounds.size.width / 2.0,
                                                    self.doubleTapLocation_Y * self.originalMaxZoomScale - self.scrollView.bounds.size.height / 2.0);
                [self.scrollView setContentOffset:contentOffset animated:NO];
            }
        }
        
    }
    self.doubleTapZoom = NO;
    
}

#pragma mark - other method
// 把 originalSize 限定在 scopeSize 范围内并按原始宽高比例显示
-(CGSize)countDisplaySizeWithScopeSize:(CGSize)scopeSize originalSize:(CGSize)originalSize {
    CGSize displaySize = originalSize;
    if (originalSize.height > scopeSize.height || originalSize.width > scopeSize.width) {
        CGFloat heightReduceScale = scopeSize.height / originalSize.height;
        CGFloat widthReduceScale = scopeSize.width / originalSize.width;
        CGFloat reduceScale = (heightReduceScale < widthReduceScale) ? heightReduceScale : widthReduceScale;
        displaySize.height = originalSize.height * reduceScale;
        displaySize.width = originalSize.width * reduceScale;
    }
    return displaySize;
}

//计算显示的区域
- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    CGRect zoomRect;
    zoomRect.size.height = [self.scrollView frame].size.height / scale;
    zoomRect.size.width  = [self.scrollView frame].size.width  / scale;
    zoomRect.origin.x = center.x - (zoomRect.size.width  / self.scrollView.maximumZoomScale);
    zoomRect.origin.y = center.y - (zoomRect.size.height / self.scrollView.maximumZoomScale);
    return zoomRect;
}

-(UIImage *)currentDisplayImage{
    return self.imageView.image;
}

@end





























