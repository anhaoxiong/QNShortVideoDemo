//
//  FilterView.m
//  ImageArrTest
//
//  Created by tutu on 2017/3/10.
//  Copyright © 2017年 wen. All rights reserved.
//

#import "FilterView.h"
#import "FilterItemView.h"


@interface FilterView ()<FilterItemViewClickDelegate,TuSDKICSeekBarDelegate>{
    //数据源
    //滤镜code数组
    NSArray *_filters;

    //视图布局
    //滤镜滑动scroll
    UIScrollView *_filterScroll;
    //参数栏背景view
    UIView *_paramBackView;
    
    // ahx add, 替换 Localized
    NSDictionary *_localizedDics;
}

@end



@implementation FilterView


- (instancetype)initWithFrame:(CGRect)frame {
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

#pragma mark - 视图布局方法；
- (void)createFilterWith:(NSArray *)filterArr {
    _filters = filterArr;
    CGFloat viewHeight = self.bounds.size.height;
    
    if (self.canAdjustParameter) {
        //参数可调节
        //垂直布局方式： 5 + paramBackView + basicViewScroll  ，当调节参数增多时，修改自动调整在paramBackVidw中的中心位置
        [self createFilterChooseViewWith:CGRectMake(0, self.lsqGetSizeHeight/2 + 10, self.bounds.size.width, self.lsqGetSizeHeight/2 - 10)];
    }else{
        //参数不可调节
        //垂直布局方式： 20 + basicViewScroll + 5
        [self createFilterChooseViewWith:CGRectMake(0, 20, self.bounds.size.width, viewHeight - 25)];
    }
}

- (void)createFilterChooseViewWith:(CGRect)theFrame{

    //创建参数栏背景view
    _paramBackView = [[UIView alloc]initWithFrame:CGRectMake(0, 10, self.lsqGetSizeWidth, theFrame.origin.y - 15)];
    [self addSubview:_paramBackView];

    //创建滤镜scroll
    _filterScroll = [[UIScrollView alloc]initWithFrame:theFrame];
    _filterScroll.showsHorizontalScrollIndicator = false;
    _filterScroll.bounces = false;
    [self addSubview:_filterScroll];
    
    //滤镜view配置参数
    CGFloat contentWidth = 20.0;
    CGFloat basicHeight = theFrame.size.height - 25 ;
    CGFloat basicWidth = basicHeight * 2/3;
    
    //创建滤镜view
    NSInteger i = 200;
    _currentFilterTag = 200 + _currentFilterTag;
    for (NSString *name in _filters) {
        FilterItemView *basicView = [FilterItemView new];
        basicView.frame = CGRectMake(contentWidth, 15, basicWidth, basicHeight);
        NSString *title = [NSString stringWithFormat:@"lsq_filter_%@",name];
        NSString *imageName = [NSString stringWithFormat:@"lsq_filter_thumb_%@.jpg",name];
//        [basicView setViewInfoWith:imageName title:NSLocalizedString(title, @"滤镜") titleFontSize:14];
        [basicView setViewInfoWith:imageName title:_localizedDics[title] titleFontSize:14];
        basicView.clickDelegate = self;
        basicView.viewDescription = name;
        basicView.tag = i;
        [_filterScroll addSubview:basicView];
        if (i == _currentFilterTag) {
            [basicView refreshClickColor:lsqRGB(244, 161, 24)];
        }
        
        contentWidth += basicWidth + 12;
        i++;
    }
    _filterScroll.contentSize = CGSizeMake(contentWidth, _filterScroll.bounds.size.height);
    
}

//选择某个路径后创建上面的参数调节view
- (void)refreshAdjustParameterViewWith:(NSString *)filterDescription filterArgs:(NSArray *)args{
    
    if (_paramBackView) {
        [_paramBackView removeAllSubviews];
    }
    if (args.count < 1) return;
    
    //布局方式：10 + 参数栏整体居中
    CGFloat itemHeight = 30;
    CGFloat centerHeightInterval = _paramBackView.lsqGetSizeHeight/(args.count);
    CGFloat centerY = -centerHeightInterval/2;
    //创建参数栏
    for (int i = 0; i<args.count; i++) {

        TuSDKFilterArg *arg = args[i];
        centerY += centerHeightInterval;
        
        UIView *backView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.lsqGetSizeWidth, itemHeight)];
        backView.center = CGPointMake(self.lsqGetSizeWidth/2, centerY);
        [_paramBackView addSubview:backView];
        
        //参数名
        UILabel *nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(25, 0, 70, itemHeight)];
        nameLabel.textColor = lsqRGB(244, 161, 24);
        nameLabel.font = [UIFont systemFontOfSize:12];
        NSString *title = [NSString stringWithFormat:@"lsq_filter_set_%@", arg.key];
//        nameLabel.text = NSLocalizedString(title, @"参数");
        nameLabel.text = _localizedDics[title];
        [backView addSubview:nameLabel];
        
        //滑动条
        TuSDKICSeekBar *seekBar = [TuSDKICSeekBar initWithFrame:CGRectMake(100, 0, self.lsqGetSizeWidth - 125, itemHeight)];
        seekBar.delegate = self;
        seekBar.progress = ((TuSDKFilterArg *)args[i]).precent;
        seekBar.aboveView.backgroundColor = lsqRGB(244, 161, 24);
        seekBar.belowView.backgroundColor = lsqRGB(217, 217, 217);
        seekBar.tag = i;
        [backView addSubview: seekBar];
    }
    
}

#pragma mark - 事件响应方法；
#pragma mark -- 滤镜view点击的代理方法 BasicDisplayViewClickDelegate
//滤镜view点击的响应代理方法
- (void)clickBasicViewWith:(NSString *)viewDescription withBasicTag:(NSInteger)tag{
    if (tag == _currentFilterTag) {
        return;
    }
    for (UIView *view in _filterScroll.subviews) {
        if ([view isMemberOfClass:[FilterItemView class]]) {
            if (view.tag == _currentFilterTag) {
                //修改上一个点击效果；
                FilterItemView * theView = (FilterItemView *)view;
                [theView refreshClickColor:nil];
            }else if (view.tag == tag){
                //更显当前点击控件效果;
                FilterItemView * theView = (FilterItemView *)view;
                [theView refreshClickColor:lsqRGB(244, 161, 24)];
            }
        }
    }
    //记录新值
    _currentFilterTag = tag;

    //目前选择了某个滤镜
    if ([self.filterEventDelegate respondsToSelector:@selector(filterView:didSelectFilterCode:)]) {
        [self.filterEventDelegate filterView:self didSelectFilterCode:viewDescription];
    }
}


#pragma mark -- 滑动条调整代理方法 TuSDKICSeekBarDelegate
//滑动条调整的响应方法
- (void)onTuSDKICSeekBar:(TuSDKICSeekBar *)seekbar changedProgress:(CGFloat)progress{
    
    if ([self.filterEventDelegate respondsToSelector:@selector(filterView:didArgChangedOfIndex:precent:)]) {
        [self.filterEventDelegate filterView:self didArgChangedOfIndex:seekbar.tag precent:progress];
    }
}


@end
