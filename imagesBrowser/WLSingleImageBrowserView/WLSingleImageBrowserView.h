//
//  WLSingleImageBrowserView.h
//
//  Created by wanglei on 16/2/4.
//  Copyright © 2016年 wanglei. All rights reserved.
//

#import <UIKit/UIKit.h>

//加载图片时, 进度条的样式
typedef NS_ENUM(NSInteger, WLProgressViewType) {
    ProgressViewTypeSingleCircle = 0,        //第一种样式, 默认样式
    ProgressViewTypePlainCircle,             //第二种样式
    ProgressViewTypeSystemIndicator,         //系统缓冲控件样式
    ProgressViewTypeNone                     //没有进度指示
};

@interface WLSingleImageBrowserView : UIView

@property (nonatomic, strong, readonly) UIImage *currentDisplayImage;
@property (nonatomic, assign) WLProgressViewType progressViewType;

//加载本地图片
-(instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image;

//加载网络图片
-(instancetype)initWithFrame:(CGRect)frame URLString:(NSString *)urlStr placeholderImage:(UIImage *)pImage failureImage:(UIImage *)fImage;

//重新恢复imageView的尺寸(由放大状态变为初始尺寸)
-(void)recoveryImageViewSize;

@end
