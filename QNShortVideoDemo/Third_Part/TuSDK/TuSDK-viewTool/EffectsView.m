//
//  EffectsView.m
//  TuSDKVideoDemo
//
//  Created by wen on 13/12/2017.
//  Copyright © 2017 TuSDK. All rights reserved.
//

#import "EffectsView.h"
#import "EffectsItemView.h"
#import <TuSDK/TuSDK.h>

@interface EffectsView()<EffectsItemViewEventDelegate> {
    // 视图布局
    // 滤镜滑动scroll
    UIScrollView *_effectsScroll;
    // 参数栏背景view
    UIView *_paramBackView;
    
    // 美颜按钮
    UIButton *_clearFilterBtn;
    // 美颜的边框view
    UIView *_clearFilterBorderView;
    
    // ahx add, 替换 Localized
    NSDictionary *_localizedDics;
}
@end

@implementation EffectsView

- (void)setProgress:(CGFloat)progress;
{
    _progress = progress;
    _displayView.currentLocation = _progress;
}
- (void)setEffectsCode:(NSArray<NSString *> *)effectsCode;
{
    _effectsCode = effectsCode;
    [self createCustomView];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _localizedDics = @{
                           @"app_name":@"涂图 - TuSDK Video",
                           @"back" : @"返回",
                           @"live_camera_sample" : @"直播相机示例",
                           @"live_processor_sample" :@"图像引擎示例",
                           @"record_camera_sample" : @"视频录制示例",
                           @"record_camera_square_sample" : @"视频录制示例 - 正方画幅",
                           @"edit_camera_sample" : @"视频编辑示例",
                           
                           
                           @"beauty_on" : @"美颜已开启",
                           @"beauty_off" : @"美颜已关闭",
                           
                           @"lsq_filter_VideoFair" : @"自然",
                           @"lsq_filter_VideoYoungGirl" : @"粉嫩",
                           @"lsq_filter_VideoWhiteSkin" : @"美白",
                           @"lsq_filter_VideoFaceu01" : @"Faceu 01",
                           @"lsq_filter_VideoHuaJiao" : @"仿花椒",
                           @"lsq_filter_VideoJelly" : @"果冻",
                           
                           // Beauty
                           @"lsq_filter_SkinNature" : @"自然",
                           @"lsq_filter_SkinPink" : @"粉嫩",
                           @"lsq_filter_SkinJelly" : @"果冻",
                           @"lsq_filter_SkinNoir" : @"黑白",
                           @"lsq_filter_SkinRuddy" : @"红润",
                           @"lsq_filter_SkinPowder" : @"蜜粉",
                           @"lsq_filter_SkinSugar" : @"糖水色",
                           
                           @"lsq_reset" : @"重置",
                           @"lsq_filter_set_smoothing" : @"润滑",
                           @"lsq_filter_set_whitening" : @"白皙",
                           @"lsq_filter_set_blurSize" : @"强度",
                           @"lsq_filter_set_mixied" : @"效果",
                           @"lsq_filter_set_distanceFactor" : @"半径",
                           @"lsq_filter_set_eyeSize" : @"大眼",
                           @"lsq_filter_set_chinSize" : @"瘦脸",
                           
                           // new filter
                           @"lsq_filter_Original" : @"原始",
                           
                           @"lsq_filter_Normal" : @"原图",
                           
                           // 中文简体
                           @"lsq_filter_nature_1" : @"自然",
                           @"lsq_filter_whitening_1" : @"美白",
                           @"lsq_filter_timber_1" : @"小森林",
                           @"lsq_filter_pink_1" : @"粉嫩",
                           @"lsq_filter_ruddy_1" : @"红润",
                           @"lsq_filter_Relaxed_1" : @"轻松",
                           @"lsq_filter_Instant_1" : @"鲜艳",
                           @"lsq_filter_Artistic_1" : @"艺术",
                           @"lsq_filter_Olympus_1" : @"奥林巴斯",
                           @"lsq_filter_Beautiful_1" : @"唯美",
                           @"lsq_filter_Elad_1" : @"艾拉",
                           @"lsq_filter_Green_1" : @"翠绿",
                           @"lsq_filter_Qiushi_1" : @"秋实",
                           @"lsq_filter_Winter_1" : @"冬日",
                           @"lsq_filter_Elegant_1" : @"淡雅",
                           @"lsq_filter_Vatican_1" : @"梵蒂冈",
                           @"lsq_filter_Leica_1" : @"莱卡",
                           @"lsq_filter_Gloomy_1" : @"阴郁",
                           @"lsq_filter_SilentEra_1" : @"无声",
                           @"lsq_filter_s1950_1" : @"黑白",
                           
                           
                           // effect
                           @"lsq_filter_LiveShake01" : @"抖动",
                           @"lsq_filter_LiveMegrim01" : @"幻觉",
                           @"lsq_filter_EdgeMagic01" : @"魔法",
                           @"lsq_filter_LiveFancy01_1" : @"70s",
                           @"lsq_filter_LiveSoulOut01" : @"灵魂出窍",
                           @"lsq_filter_LiveSignal01" : @"信号",
                           };
    }
    return self;
}

- (void)createCustomView
{
    _displayView = [[EffectsDisplayView alloc]initWithFrame:CGRectMake(10, 15, self.lsqGetSizeWidth - 70, 60)];
    [self addSubview:_displayView];

    CGFloat effectItemHeight = 0.44*self.lsqGetSizeHeight;
    CGFloat effectItemWidth = effectItemHeight * 13/18;
    CGFloat offsetX = effectItemWidth + 10 + 7;
    CGFloat bottom = self.lsqGetSizeHeight/15;
    CGRect effectsScrollFrame = CGRectMake(10, self.lsqGetSizeHeight - effectItemHeight - bottom, self.bounds.size.width - 20, effectItemHeight);
    
    // 创建滤镜scroll
    _effectsScroll = [[UIScrollView alloc]initWithFrame:effectsScrollFrame];
    _effectsScroll.showsHorizontalScrollIndicator = false;
    _effectsScroll.bounces = false;
    [self addSubview:_effectsScroll];
    
    // 滤镜view配置参数
    CGFloat centerX = effectItemWidth/2;
    CGFloat centerY = _effectsScroll.lsqGetSizeHeight/2;
    
    // 创建滤镜view
    CGFloat itemInterval = 7;
    for (int i = 0; i < _effectsCode.count; i++) {
        EffectsItemView *basicView = [EffectsItemView new];
        basicView.frame = CGRectMake(0, 0, effectItemWidth, effectItemHeight);
        basicView.center = CGPointMake(centerX, centerY);
        NSString *title = [NSString stringWithFormat:@"lsq_filter_%@", _effectsCode[i]];
        NSString *imageName = [NSString stringWithFormat:@"lsq_filter_thumb_%@",_effectsCode[i]];
        
        NSLog(@"特效 %@",imageName);
//        [basicView setViewInfoWith:imageName title:NSLocalizedString(title,@"特效") titleFontSize:12];
        [basicView setViewInfoWith:imageName title:_localizedDics[title] titleFontSize:12];
        basicView.eventDelegate = self;
        basicView.effectCode = _effectsCode[i];
        [_effectsScroll addSubview:basicView];

        centerX += effectItemWidth + itemInterval;
    }
    _effectsScroll.contentSize = CGSizeMake(centerX - effectItemWidth/2, _effectsScroll.bounds.size.height);
}

#pragma mark - EffectsItemViewEventDelegate

- (void)touchBeginWithSelectCode:(NSString *)effectCode;
{
    if ([self.effectEventDelegate respondsToSelector:@selector(effectsView:didSelectMediaEffectCode:)]) {
        [self.effectEventDelegate effectsView:self didSelectMediaEffectCode:effectCode];
    }
}

- (void)touchEndWithSelectCode:(NSString *)effectCode;
{
    if ([self.effectEventDelegate respondsToSelector:@selector(effectsView:didDeSelectMediaEffectCode:)]) {
        [self.effectEventDelegate effectsView:self didDeSelectMediaEffectCode:effectCode];
    }
}



@end


