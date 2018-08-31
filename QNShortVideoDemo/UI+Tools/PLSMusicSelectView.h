//
//  PLSMusicSelectView.h
//  QNShortVideoDemo
//
//  Created by hxiongan on 2018/8/29.
//  Copyright © 2018年 hxiongan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLSMusicSelectView;
@protocol PLSMusicSelectViewDelegate<NSObject>

- (void)musicSelectView:(PLSMusicSelectView *)musicSelectView didSelectedMusic:(NSString *)musicName;

@end

@interface PLSMusicSelectView : UIView

@property (nonatomic, weak) id<PLSMusicSelectViewDelegate> delegate;

@end
