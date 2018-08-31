//
//  PLSStickerSelectView.h
//  QNShortVideoDemo
//
//  Created by hxiongan on 2018/8/29.
//  Copyright © 2018年 hxiongan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLSStickerSelectView;
@protocol PLSStickerSelectViewDelegate<NSObject>

- (void)stickerSelectView:(PLSStickerSelectView *)selectView didSelectedImage:(UIImage *)image;

@end

@interface PLSStickerSelectView : UIView

@property (nonatomic, weak) id<PLSStickerSelectViewDelegate> delegate;

@end
