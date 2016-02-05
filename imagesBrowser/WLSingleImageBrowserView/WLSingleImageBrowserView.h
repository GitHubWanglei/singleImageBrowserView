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

-(instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image;

-(instancetype)initWithFrame:(CGRect)frame URLString:(NSString *)urlStr placeholderImage:(UIImage *)pImage failureImage:(UIImage *)fImage;

-(void)recoveryImageViewSize;

@end
