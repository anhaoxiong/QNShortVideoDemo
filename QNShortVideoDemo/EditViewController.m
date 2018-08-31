//
//  EditViewController.m
//  QNShortVideoDemo
//
//  Created by hxiongan on 2018/8/28.
//  Copyright © 2018年 hxiongan. All rights reserved.
//

#import "EditViewController.h"
#import <PLShortVideoKit/PLShortVideoKit.h>

#import "PLSStickerOverlayView.h"
#import "PLSStickerView.h"
#import "PLSStickerSelectView.h"
#import "PLSMusicSelectView.h"
#import "PLSAudioVolumeView.h"
#import "PLSVerticalButton.h"

// TuSDK mark
#import <TuSDK/TuSDK.h>
#import <TuSDKVideo/TuSDKVideo.h>
#import "EffectsView.h"

@interface EditViewController ()
<
PLSMusicSelectViewDelegate,
PLSStickerViewDelegate,
PLShortVideoEditorDelegate,
EffectsViewEventDelegate,
PLSStickerSelectViewDelegate,
PLSAudioVolumeViewDelegate,
UIGestureRecognizerDelegate,
PLSAVAssetExportSessionDelegate
>

@property (nonatomic, strong) UIProgressView *processView;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, strong) PLShortVideoEditor *shortVideoEditor;

@property (nonatomic, strong) PLSStickerSelectView *stickerSelecteView;
@property (nonatomic, strong) PLSStickerView *currentStickerView;
@property (nonatomic, strong) PLSStickerOverlayView *stickerOverlayView;
// 贴纸 gesture 交互相关
@property (assign, nonatomic) CGPoint loc_in;
@property (nonatomic, nonatomic) CGPoint ori_center;
@property (nonatomic, nonatomic) CGFloat curScale;
@property (nonatomic, strong) NSMutableArray *stickerArray;

@property (nonatomic, strong) PLSMusicSelectView *musicSelectView;

@property (nonatomic, strong) UIButton *playButton;

// 编辑信息, movieSettings, watermarkSettings, stickerSettingsArray, audioSettingsArray 为 outputSettings 的字典元素
@property (strong, nonatomic) NSMutableDictionary *outputSettings;
@property (strong, nonatomic) NSMutableDictionary *movieSettings;
@property (strong, nonatomic) NSMutableArray *audioSettingsArray;
@property (strong, nonatomic) NSMutableDictionary *backgroundAudioSettings;
@property (strong, nonatomic) NSMutableArray *stickerSettingsArray;

#pragma mark - TuSDK 特效
@property (assign, nonatomic) CGFloat videoTotalTime;
//特效处理类
@property (nonatomic, strong) TuSDKFilterProcessor *filterProcessor;
// 特效列表
@property (nonatomic, strong) NSArray<NSString *> *videoEffects;
// 随机色数组
@property (nonatomic, strong) NSArray<UIColor *> *displayColors;
// 特效栏
@property (nonatomic, strong) EffectsView *effectsView;
// 视频处理进度 0~1
@property (nonatomic, assign) CGFloat videoProgress;
// 当前正在编辑的特效
@property (nonatomic, strong) TuSDKMediaEffectData *editingEffectData;
// ===============    TuSDK   end ============
@end

@implementation EditViewController

- (void)dealloc {
    [self removeObserverUIApplicationStatusForShortVideoEditor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self observerUIApplicationStatusForShortVideoEditor];
    [self setupEditor];
    [self setupUI];
    [self setupEffect];
    
    self.stickerArray = [[NSMutableArray alloc] init];
    
    AVAsset *asset = self.movieSettings[PLSAssetKey];
    self.stickerOverlayView = [[PLSStickerOverlayView alloc] initWithFrame:[PLShortVideoTranscoder videoDisplay:asset bounds:self.shortVideoEditor.previewView.bounds rotate:(PLSPreviewOrientationPortrait)]];
    [self.view addSubview:self.stickerOverlayView];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTouchBGView:)];
    singleTap.cancelsTouchesInView = NO;
    singleTap.delegate = self;
    [self.view addGestureRecognizer:singleTap];

    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.shortVideoEditor.isEditing) {
        [self.shortVideoEditor startEditing];
    }
}

#pragma mark - UIGestureRecognizer 手势代理
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    CGPoint point = [touch locationInView:self.view];
    if (CGRectContainsPoint(self.effectsView.frame, point) ||
        CGRectContainsPoint(self.musicSelectView.frame, point) ||
        CGRectContainsPoint(self.stickerSelecteView.frame, point)) {
        return NO;
    }
    return YES;
}

// self.tapGes 手势的响应事件
- (void)onTouchBGView:(UITapGestureRecognizer *)touches {
    // 取消贴纸、字幕的选中状态
    if (_currentStickerView) {
        _currentStickerView.select = NO;
    }
    [self.view endEditing:YES];

    [self hideStickerSelectView];
    [self hideMusicSelectView];
    [self hideEffectView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupEditor {
    
    self.outputSettings = [[NSMutableDictionary alloc] init];
    self.movieSettings = [[NSMutableDictionary alloc] init];
    self.stickerSettingsArray = [[NSMutableArray alloc] init];
    self.audioSettingsArray = [[NSMutableArray alloc] init];
    
    self.outputSettings[PLSMovieSettingsKey] = self.movieSettings;
    self.outputSettings[PLSStickerSettingsKey] = self.stickerSettingsArray;
    self.outputSettings[PLSAudioSettingsKey] = self.audioSettingsArray;
    
    // 原始视频
    [self.movieSettings addEntriesFromDictionary:self.settings[PLSMovieSettingsKey]];
    self.movieSettings[PLSVolumeKey] = [NSNumber numberWithFloat:1.0];
    
    // 背景音乐
    self.backgroundAudioSettings = [[NSMutableDictionary alloc] init];
    self.backgroundAudioSettings[PLSVolumeKey] = [NSNumber numberWithFloat:1.0];
    
    // 视频编辑类
    AVAsset *asset = self.movieSettings[PLSAssetKey];
    self.shortVideoEditor = [[PLShortVideoEditor alloc] initWithAsset:asset videoSize:CGSizeZero];
    self.shortVideoEditor.delegate = self;
    self.shortVideoEditor.loopEnabled = YES;
    
    // 要处理的视频的时间区域
    CMTime start = CMTimeMake([self.movieSettings[PLSStartTimeKey] floatValue] * 1000, 1000);
    CMTime duration = CMTimeMake([self.movieSettings[PLSDurationKey] floatValue] * 1000, 1000);
    self.shortVideoEditor.timeRange = CMTimeRangeMake(start, duration);
    
    [self.view insertSubview:self.shortVideoEditor.previewView atIndex:0];
    [self.shortVideoEditor.previewView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)setupUI {
    
    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playButton setImage:[UIImage imageNamed:@"btn_play_bg_a"] forState:UIControlStateSelected];
    [self.playButton addTarget:self action:@selector(playButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.playButton];
    
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.shortVideoEditor.previewView).insets(UIEdgeInsetsMake(100, 0, 100, 0));
    }];
    
    UIButton *backButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    [backButton setTintColor:[UIColor whiteColor]];
    [backButton setTitle:@"返回" forState:(UIControlStateNormal)];
    [backButton sizeToFit];
    [backButton addTarget:self action:@selector(backButtonEvent:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:backButton];
    [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.top.equalTo(self.mas_topLayoutGuide).offset(30);
        make.size.equalTo(backButton.bounds.size);
    }];
    
    UIButton *textButton = [[PLSVerticalButton alloc] initWithFrame:CGRectMake(0, 0, 50, 70)];
    [textButton setTitle:@"文字" forState:(UIControlStateNormal)];
    textButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [textButton setImage:[UIImage imageNamed:@"text"] forState:(UIControlStateNormal)];
    [textButton addTarget:self action:@selector(clikcTextButton) forControlEvents:(UIControlEventTouchUpInside)];
    
    UIButton *volumeButton = [[PLSVerticalButton alloc] initWithFrame:CGRectMake(0, 0, 50, 70)];
    [volumeButton setTitle:@"音量" forState:(UIControlStateNormal)];
    volumeButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [volumeButton setImage:[UIImage imageNamed:@"volume"] forState:(UIControlStateNormal)];
    [volumeButton addTarget:self action:@selector(clikcVolumeButton) forControlEvents:(UIControlEventTouchUpInside)];
    
    UIButton *musicButton = [[PLSVerticalButton alloc] initWithFrame:CGRectMake(0, 0, 50, 70)];
    [musicButton setTitle:@"音乐" forState:(UIControlStateNormal)];
    musicButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [musicButton setImage:[UIImage imageNamed:@"music"] forState:(UIControlStateNormal)];
    [musicButton addTarget:self action:@selector(clikcMusicButton) forControlEvents:(UIControlEventTouchUpInside)];
    
    [self.view addSubview:textButton];
    [self.view addSubview:volumeButton];
    [self.view addSubview:musicButton];
    
    [musicButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-30);
        make.top.equalTo(self.mas_topLayoutGuide).offset(30);
        make.size.equalTo(CGSizeMake(40, 70));
    }];
    
    [volumeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(musicButton.mas_left).offset(-10);
        make.size.top.equalTo(musicButton);
    }];
    
    [textButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(volumeButton.mas_left).offset(-10);
        make.size.top.equalTo(volumeButton);
    }];
    
    self.processView = [[UIProgressView alloc] init];
    [self.view addSubview:self.processView];
    [self.processView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.mas_topLayoutGuide);
    }];
    
    UIButton *effectButton = [[PLSVerticalButton alloc] initWithFrame:CGRectMake(0, 0, 50, 70)];
    [effectButton setImage:[UIImage imageNamed:@"effect"] forState:(UIControlStateNormal)];
    effectButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [effectButton setTitle:@"特效" forState:(UIControlStateNormal)];
    [effectButton addTarget:self action:@selector(showEffectView) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:effectButton];
    
    [effectButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(30);
        make.bottom.equalTo(self.mas_bottomLayoutGuide).offset(-60);
        make.size.equalTo(musicButton);
    }];
    
    UIButton *nextButton = [[UIButton alloc] init];
    [nextButton setImage:[UIImage imageNamed:@"next_button"] forState:(UIControlStateNormal)];
    [nextButton addTarget:self action:@selector(nextButtonClick) forControlEvents:(UIControlEventTouchUpInside)];
    [nextButton sizeToFit];
    [self.view addSubview:nextButton];
    
    [nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-30);
        make.centerY.equalTo(effectButton);
        make.size.equalTo(nextButton.bounds.size);
    }];
    
    self.stickerSelecteView = [[PLSStickerSelectView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
    self.stickerSelecteView.delegate = self;
    [self.view addSubview:self.stickerSelecteView];
    
    self.musicSelectView = [[PLSMusicSelectView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
    self.musicSelectView.delegate = self;
    [self.view addSubview:self.musicSelectView];
    
    [self.stickerSelecteView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_bottom);
        make.height.equalTo(80);
    }];
    
    [self.musicSelectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_bottom);
        make.height.equalTo(80);
    }];
}

- (void)backButtonEvent:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)clikcTextButton {
    [self showTextbar];
}

- (void)clikcVolumeButton {

    NSNumber *movieVolume = self.movieSettings[PLSVolumeKey];
    NSNumber *musicVolume = self.backgroundAudioSettings[PLSVolumeKey];
    
    PLSAudioVolumeView *volumeView = [[PLSAudioVolumeView alloc] initWithMovieVolume:[movieVolume floatValue] musicVolume:[musicVolume floatValue]];
    volumeView.delegate = self;
    [volumeView showAtView:self.view];
}

- (void)clikcMusicButton {
    if ([self musicSelectViewIsShow]) {
        [self hideMusicSelectView];
        [self hideStickerSelectView];
        [self hideEffectView];
    } else {
        [self showMusicSelecttView];
    }
}

- (BOOL)stickerSelectViewIsShow {
    return self.stickerSelecteView.frame.origin.y < self.view.bounds.size.height;
}

- (void)showStickerSelectView {
    if (![self stickerSelectViewIsShow]) {
        [self.stickerSelecteView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.bottom.equalTo(self.mas_bottomLayoutGuide);
            make.height.equalTo(self.stickerSelecteView.bounds.size.height);
        }];
    }
}

- (void)hideStickerSelectView {
    if ([self stickerSelectViewIsShow]) {
        [self.stickerSelecteView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.top.equalTo(self.view.mas_bottom);
            make.height.equalTo(self.stickerSelecteView.bounds.size.height);
        }];
        
        [UIView animateWithDuration:.3 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

- (BOOL)musicSelectViewIsShow {
    return self.musicSelectView.frame.origin.y < self.view.bounds.size.height;
}

- (void)showMusicSelecttView {
    if (![self musicSelectViewIsShow]) {
        [self.musicSelectView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.bottom.equalTo(self.mas_bottomLayoutGuide);
            make.height.equalTo(self.musicSelectView.bounds.size.height);
        }];
        
        [UIView animateWithDuration:.3 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

- (void)hideMusicSelectView {
    if ([self musicSelectViewIsShow]) {
        [self.musicSelectView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.top.equalTo(self.view.mas_bottom);
            make.height.equalTo(self.musicSelectView.bounds.size.height);
        }];
        [UIView animateWithDuration:.3 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

- (void)playButtonClicked:(UIButton *)button {
    if (self.shortVideoEditor.isEditing) {
        [self.shortVideoEditor stopEditing];
        self.playButton.selected = YES;
    } else {
        [self.shortVideoEditor startEditing];
        self.playButton.selected = NO;
    }
}

#pragma mark - 程序的状态监听
- (void)observerUIApplicationStatusForShortVideoEditor {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shortVideoEditorWillResignActiveEvent:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shortVideoEditorDidBecomeActiveEvent:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)removeObserverUIApplicationStatusForShortVideoEditor {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)shortVideoEditorWillResignActiveEvent:(id)sender {
    NSLog(@"[self.shortVideoEditor UIApplicationWillResignActiveNotification]");
    [self.shortVideoEditor stopEditing];
    self.playButton.selected = YES;
}

- (void)shortVideoEditorDidBecomeActiveEvent:(id)sender {
    NSLog(@"[self.shortVideoEditor UIApplicationDidBecomeActiveNotification]");
    [self.shortVideoEditor startEditing];
    self.playButton.selected = NO;
}


// 添加文字

- (void)showTextbar {
    [self.shortVideoEditor stopEditing];
    
    self.playButton.selected = YES;
    
    // 1. 创建贴纸
    NSString *imgName = @"sticker_t_0";
    UIImage *image = [UIImage imageNamed:imgName];
    PLSStickerView *stickerView = [[PLSStickerView alloc] initWithImage:image Type:StickerType_SubTitle];
    stickerView.delegate = self;
    [stickerView calcInputRectWithImgName:imgName];
    
    _currentStickerView.select = NO;
    stickerView.select = YES;
    _currentStickerView = stickerView;
    
    // 2. 添加至stickerOverlayView上
    [self.stickerOverlayView addSubview:stickerView];
    [self.stickerArray addObject:stickerView];
    
    stickerView.frame = CGRectMake((self.stickerOverlayView.frame.size.width - image.size.width * 0.5) * 0.5,
                                   (self.stickerOverlayView.frame.size.height - image.size.height * 0.5) * 0.5,
                                   image.size.width * 0.5, image.size.height * 0.5);
    
    UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveGestureRecognizerEvent:)];
    [stickerView addGestureRecognizer:panGes];
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerEvent:)];
    [stickerView addGestureRecognizer:tapGes];
    UIPinchGestureRecognizer *pinGes = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureRecognizerEvent:)];
    [stickerView addGestureRecognizer:pinGes];
    [stickerView.dragBtn addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(scaleAndRotateGestureRecognizerEvent:)]];
    
    UITapGestureRecognizer *doubleTapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(startTextEditing:)];
    doubleTapGes.numberOfTapsRequired = 2;
    [stickerView addGestureRecognizer:doubleTapGes];
}

- (void)startTextEditing:(UITapGestureRecognizer *)tapGes {
    _currentStickerView = (PLSStickerView *)[tapGes view];
    _currentStickerView.select = YES;
    [_currentStickerView becomeFirstResponder];
}

- (void)moveGestureRecognizerEvent:(UIPanGestureRecognizer *)panGes {
    
    if ([[panGes view] isKindOfClass:[PLSStickerView class]]){
        CGPoint loc = [panGes locationInView:self.view];
        PLSStickerView *view = (PLSStickerView *)[panGes view];
        if (_currentStickerView.select) {
            if ([_currentStickerView pointInside:[_currentStickerView convertPoint:loc fromView:self.view] withEvent:nil]){
                view = _currentStickerView;
            }
        }
        if (!view.select) {
            return;
        }
        if (panGes.state == UIGestureRecognizerStateBegan) {
            _loc_in = [panGes locationInView:self.view];
            _ori_center = view.center;
        }
        
        CGFloat x;
        CGFloat y;
        x = _ori_center.x + (loc.x - _loc_in.x);
        
        y = _ori_center.y + (loc.y - _loc_in.y);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0 animations:^{
                view.center = CGPointMake(x, y);
            }];
        });
    }
}

- (void)tapGestureRecognizerEvent:(UITapGestureRecognizer *)tapGes {
    
    if ([[tapGes view] isKindOfClass:[PLSStickerView class]]){
        
        [self.shortVideoEditor stopEditing];
        self.playButton.selected = YES;
        
        PLSStickerView *view = (PLSStickerView *)[tapGes view];
        
        if (view != _currentStickerView) {
            _currentStickerView.select = NO;
            view.select = YES;
            _currentStickerView = view;
        } else {
            view.select = !view.select;
            if (view.select) {
                _currentStickerView = view;
            }else{
                _currentStickerView = nil;
            }
        }
    }
}

- (void)pinchGestureRecognizerEvent:(UIPinchGestureRecognizer *)pinGes {
    if ([[pinGes view] isKindOfClass:[PLSStickerView class]]){
        PLSStickerView *view = (PLSStickerView *)[pinGes view];
        
        if (pinGes.state ==UIGestureRecognizerStateBegan) {
            view.oriTransform = view.transform;
        }
        
        if (pinGes.state ==UIGestureRecognizerStateChanged) {
            _curScale = pinGes.scale;
            CGAffineTransform tr = CGAffineTransformScale(view.oriTransform, pinGes.scale, pinGes.scale);
            
            view.transform = tr;
        }
        
        // 当手指离开屏幕时,将lastscale设置为1.0
        if ((pinGes.state == UIGestureRecognizerStateEnded) || (pinGes.state == UIGestureRecognizerStateCancelled)) {
            view.oriScale = view.oriScale * _curScale;
            pinGes.scale = 1;
        }
    }
}

- (void)scaleAndRotateGestureRecognizerEvent:(UIPanGestureRecognizer *)gesture {
    if (_currentStickerView.isSelected) {
        CGPoint curPoint = [gesture locationInView:self.view];
        if (gesture.state == UIGestureRecognizerStateBegan) {
            _loc_in = [gesture locationInView:self.view];
        }
        
        if (gesture.state == UIGestureRecognizerStateBegan) {
            _currentStickerView.oriTransform = _currentStickerView.transform;
        }
        
        // 计算缩放
        CGFloat preDistance = [self getDistance:_loc_in withPointB:_currentStickerView.center];
        CGFloat curDistance = [self getDistance:curPoint withPointB:_currentStickerView.center];
        CGFloat scale = curDistance / preDistance;
//        // 计算弧度
        CGFloat preRadius = [self getRadius:_currentStickerView.center withPointB:_loc_in];
        CGFloat curRadius = [self getRadius:_currentStickerView.center withPointB:curPoint];
        CGFloat radius = curRadius - preRadius;
        radius = - radius;
        CGAffineTransform transform = CGAffineTransformScale(_currentStickerView.oriTransform, scale, scale);
        _currentStickerView.transform = CGAffineTransformRotate(transform, radius);
        
        if (gesture.state == UIGestureRecognizerStateEnded ||
            gesture.state == UIGestureRecognizerStateCancelled) {
            _currentStickerView.oriScale = scale * _currentStickerView.oriScale;
        }
    }
}

// 距离
- (CGFloat)getDistance:(CGPoint)pointA withPointB:(CGPoint)pointB {
    CGFloat x = pointA.x - pointB.x;
    CGFloat y = pointA.y - pointB.y;
    
    return sqrt(x*x + y*y);
}

// 角度
- (CGFloat)getRadius:(CGPoint)pointA withPointB:(CGPoint)pointB {
    CGFloat x = pointA.x - pointB.x;
    CGFloat y = pointA.y - pointB.y;
    return atan2(x, y);
}

// 获取视频／音频文件的总时长
- (CGFloat)getFileDuration:(NSURL*)URL {
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:URL options:opts];
    
    CMTime duration = asset.duration;
    float durationSeconds = CMTimeGetSeconds(duration);
    
    return durationSeconds;
}

- (void)updateMusic:(CMTimeRange)timeRange volume:(NSNumber *)volume {
    // 更新 背景音乐 的 播放时间区间、音量
    [self.shortVideoEditor updateMusic:timeRange volume:volume];
    
    self.backgroundAudioSettings[PLSLocationStartTimeKey] = [NSNumber numberWithFloat:0.f];
    self.backgroundAudioSettings[PLSLocationDurationKey] = self.movieSettings[PLSDurationKey];
}

- (void)addMusic:(NSURL *)musicURL timeRange:(CMTimeRange)timeRange volume:(NSNumber *)volume {
    
    if (!self.shortVideoEditor.isEditing) {
        [self.shortVideoEditor startEditing];
        self.playButton.selected = NO;
    }
    
    // 添加／移除 背景音乐
    [self.shortVideoEditor addMusic:musicURL timeRange:timeRange volume:volume loopEnable:YES];
    
    self.backgroundAudioSettings[PLSLocationStartTimeKey] = [NSNumber numberWithFloat:0.f];
    self.backgroundAudioSettings[PLSLocationDurationKey] = self.movieSettings[PLSDurationKey];
}

// 加载拼接视频的动画
- (void)loadActivityIndicatorView {
    if (!self.activityIndicatorView) {
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:self.view.bounds];
        self.activityIndicatorView.center = self.view.center;
        [self.activityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.activityIndicatorView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    }
    
    if ([self.activityIndicatorView isAnimating]) {
        [self.activityIndicatorView stopAnimating];
        [self.activityIndicatorView removeFromSuperview];
    }
    
    [self.view addSubview:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
}

// 移除拼接视频的动画
- (void)removeActivityIndicatorView {
    [self.activityIndicatorView removeFromSuperview];
    [self.activityIndicatorView stopAnimating];
}


- (void)nextButtonClick {
    [self.shortVideoEditor stopEditing];
    self.playButton.selected = YES;
    
    // TuSDK mark 导出带视频特效的视频时，先重置标记位
    [self resetExportVideoEffectsMark];
    // TuSDK end
    
    [self loadActivityIndicatorView];
    
    // 贴纸信息
    [self.stickerSettingsArray removeAllObjects];
    for (int i = 0; i < self.stickerArray.count; i++) {
        
        NSMutableDictionary *stickerSettings = [[NSMutableDictionary alloc] init];
        PLSStickerView *stickerView = [self.stickerArray objectAtIndex:i];
        stickerView.hidden = NO;
        
        CGAffineTransform transform = stickerView.transform;
        CGFloat widthScale = sqrt(transform.a * transform.a + transform.c * transform.c);
        CGFloat heightScale = sqrt(transform.b * transform.b + transform.d * transform.d);
        CGSize viewSize = CGSizeMake(stickerView.bounds.size.width * widthScale, stickerView.bounds.size.height * heightScale);
        CGPoint viewCenter =  CGPointMake(stickerView.frame.origin.x + stickerView.frame.size.width / 2, stickerView.frame.origin.y + stickerView.frame.size.height / 2);
        CGPoint viewPoint = CGPointMake(viewCenter.x - viewSize.width / 2, viewCenter.y - viewSize.height / 2);
        
        stickerSettings[PLSStickerKey] = stickerView;
        stickerSettings[PLSSizeKey] = [NSValue valueWithCGSize:viewSize];
        stickerSettings[PLSPointKey] = [NSValue valueWithCGPoint:viewPoint];
        
        CGFloat rotation = atan2f(transform.b, transform.a);
        rotation = rotation * (180 / M_PI);
        stickerSettings[PLSRotationKey] = [NSNumber numberWithFloat:rotation];
        
        stickerSettings[PLSStartTimeKey] = [NSNumber numberWithFloat:0];
        stickerSettings[PLSDurationKey] = [NSNumber numberWithFloat:self.videoTotalTime];
        stickerSettings[PLSVideoPreviewSizeKey] = [NSValue valueWithCGSize:self.stickerOverlayView.frame.size];
        stickerSettings[PLSVideoOutputSizeKey] = [NSValue valueWithCGSize:CGSizeZero];
        
        [self.stickerSettingsArray addObject:stickerSettings];
    }
    
    // 添加背景音乐信息
    [self.audioSettingsArray insertObject:self.backgroundAudioSettings atIndex:0];
    
    AVAsset *asset = self.movieSettings[PLSAssetKey];
    PLSAVAssetExportSession *exportSession = [[PLSAVAssetExportSession alloc] initWithAsset:asset];
    exportSession.outputFileType = PLSFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputSettings = self.outputSettings;
    exportSession.delegate = self;
    exportSession.isExportMovieToPhotosAlbum = YES;

    
    __weak typeof(self) weakSelf = self;
    [exportSession setCompletionBlock:^(NSURL *url) {
        NSLog(@"Asset Export Completed");
        
        // TuSDK mark 视频特效预览，先重置标记位
        [weakSelf resetPreviewVideoEffectsMark];
        // TuSDK end
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.view showTip:@"视频已保存到相册"];
            [weakSelf removeActivityIndicatorView];
        });
    }];
    
    [exportSession setFailureBlock:^(NSError *error) {
        NSLog(@"Asset Export Failed: %@", error);
        
        // TuSDK mark 视频特效预览，先重置标记位
        [weakSelf resetPreviewVideoEffectsMark];
        // TuSDK end
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf removeActivityIndicatorView];
            [weakSelf.view showTip:error.localizedDescription];
        });
    }];
    
    [exportSession setProcessingBlock:^(float progress) {
        // 更新进度 UI
        NSLog(@"Asset Export Progress: %f", progress);
    }];
    
    [exportSession exportAsynchronously];
}


// PLSStickerViewDelegate
- (void)stickerViewClose:(PLSStickerView *)stickerView {
    [self.stickerArray removeObject:stickerView];
}

// PLSAudioVolumeViewDelegate
- (void)audioVolumeView:(PLSAudioVolumeView *)volumeView movieVolumeChangedTo:(CGFloat)movieVolume musicVolumeChangedTo:(CGFloat)musicVolume {
    
    self.movieSettings[PLSVolumeKey] = [NSNumber numberWithFloat:movieVolume];
    self.backgroundAudioSettings[PLSVolumeKey] = [NSNumber numberWithFloat:musicVolume];
    
    self.shortVideoEditor.volume = movieVolume;
    
    [self updateMusic:kCMTimeRangeZero volume:self.backgroundAudioSettings[PLSVolumeKey]];
}

// PLSStickerSelectViewDelegate
- (void)stickerSelectView:(PLSStickerSelectView *)selectView didSelectedImage:(UIImage *)image {
    
}

// PLSMusicSelectViewDelegate
- (void)musicSelectView:(PLSMusicSelectView *)musicSelectView didSelectedMusic:(NSString *)musicName {
    
    // 音乐
    if (!musicName) {
        // ****** 要特别注意此处，无音频 URL ******
        self.backgroundAudioSettings[PLSURLKey] = [NSNull null];
        self.backgroundAudioSettings[PLSStartTimeKey] = [NSNumber numberWithFloat:0.f];
        self.backgroundAudioSettings[PLSDurationKey] = [NSNumber numberWithFloat:0.f];
        self.backgroundAudioSettings[PLSNameKey] = musicName;
        
    } else {
        
        NSURL *musicUrl = [[NSBundle mainBundle] URLForResource:musicName withExtension:nil];
        self.backgroundAudioSettings[PLSURLKey] = musicUrl;
        self.backgroundAudioSettings[PLSStartTimeKey] = [NSNumber numberWithFloat:0.f];
        self.backgroundAudioSettings[PLSDurationKey] = [NSNumber numberWithFloat:[self getFileDuration:musicUrl]];
        self.backgroundAudioSettings[PLSNameKey] = musicName;
        
    }
    
    NSURL *musicURL = self.backgroundAudioSettings[PLSURLKey];
    CMTimeRange musicTimeRange= CMTimeRangeMake(CMTimeMake([self.backgroundAudioSettings[PLSStartTimeKey] floatValue] * 1000, 1000), CMTimeMake([self.backgroundAudioSettings[PLSDurationKey] floatValue] * 1000, 1000));
    NSNumber *musicVolume = self.backgroundAudioSettings[PLSVolumeKey];
    [self addMusic:musicURL timeRange:musicTimeRange volume:musicVolume];
    
}

- (CVPixelBufferRef)shortVideoEditor:(PLShortVideoEditor *)editor didGetOriginPixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)timestamp {
    
    // TuSDK mark 特效处理
    self.videoProgress = CMTimeGetSeconds(timestamp) / self.videoTotalTime;
    CVPixelBufferRef tempPixelBuffer = [self.filterProcessor syncProcessPixelBuffer:pixelBuffer frameTime:timestamp];
    [self.filterProcessor destroyFrameData];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.effectsView.displayView updateLastSegmentViewProgress:self.videoProgress];
        self.effectsView.displayView.currentLocation = self.videoProgress;
        // TuSDK mark end
        
        self.processView.progress = self.videoProgress;
    });
    
    return tempPixelBuffer;
}


- (void)shortVideoEditor:(PLShortVideoEditor *)editor didReadyToPlayForAsset:(AVAsset *)asset timeRange:(CMTimeRange)timeRange {
    
    // TuSDK mark
    self.videoProgress = 0.0;
    self.playButton.selected = NO;
}

- (void)shortVideoEditor:(PLShortVideoEditor *)editor didReachEndForAsset:(AVAsset *)asset timeRange:(CMTimeRange)timeRange {

    // =============    TuSDK mark
    self.videoProgress = 1.0;
    //TuSDK mark - progress 为 1 时，也需要进行 effectCode 判断，因为添加过程中，effectsEndWithCode: 执行之前来限制正在添加的过程中不进行特效切换
    [self effectsView:self.effectsView didDeSelectMediaEffectCode:[(TuSDKMediaSceneEffectData *)_editingEffectData effectsCode]];
    
    _editingEffectData = nil;
    self.effectsView.displayView.currentLocation = self.videoProgress;
    // =============    TuSDK end
}

// PLSAVAssetExportSessionDelegate 合成视频文件给视频数据加滤镜效果的回调
- (CVPixelBufferRef)assetExportSession:(PLSAVAssetExportSession *)assetExportSession didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)timestamp {
   
    CVPixelBufferRef tempPixelBuffer = pixelBuffer;
    
    // TuSDK mark
    tempPixelBuffer = [self.filterProcessor syncProcessPixelBuffer:pixelBuffer frameTime:timestamp];
    [self.filterProcessor destroyFrameData];
    // TuSDK end
    
    return tempPixelBuffer;
}

- (void)setupEffect {
    
    [self initEffectsData];
    
    self.videoTotalTime = CMTimeGetSeconds(self.shortVideoEditor.timeRange.duration);

    self.effectsView = [[EffectsView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 200)];
    self.effectsView.effectEventDelegate = self;
    self.effectsView.effectsCode = self.videoEffects;
    self.effectsView.backgroundColor = [UIColor colorWithWhite:.0 alpha:.5];
    
    // 撤销特效的按钮
    UIButton *revocationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [revocationButton setImage:[UIImage imageNamed:@"btn_revocation"] forState:UIControlStateNormal];
    [revocationButton addTarget:self action:@selector(didTouchUpRemoveSceneMediaEffectButton:) forControlEvents:UIControlEventTouchUpInside];
    revocationButton.frame = CGRectMake(self.effectsView.lsqGetSizeWidth - 40, 30, 30, 30);
    
    [self.effectsView addSubview:revocationButton];
    [self.view addSubview:self.effectsView];
    [self.effectsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_bottom);
        make.height.equalTo(200);
    }];
    
    [revocationButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(CGSizeMake(44, 44));
        make.right.equalTo(self.effectsView);
        make.top.equalTo(self.effectsView).offset(35);
    }];
    
    [self setupTuSDKFilter];
}

- (BOOL)effectViewIsShow {
    return self.effectsView.frame.origin.y < self.view.bounds.size.height;
}

- (void)showEffectView {
    if (![self effectViewIsShow]) {
        
        [self.shortVideoEditor stopEditing];
        self.playButton.selected = YES;
        
        [self.effectsView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.view);
            make.height.equalTo(self.effectsView.bounds.size.height);
        }];
        
        [UIView animateWithDuration:.3 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

- (void)hideEffectView {
    if ([self effectViewIsShow]) {
        [self.effectsView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.top.equalTo(self.view.mas_bottom);
            make.height.equalTo(self.effectsView.bounds.size.height);
        }];
        
        [UIView animateWithDuration:.3 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

// 特效按钮点击事件
- (void)effectsButtonClick:(UIButton *)btn {
    
    [self hideMusicSelectView];
    [self hideStickerSelectView];
    
    [self showEffectView];
}

// 设置 TuSDK
- (void)setupTuSDKFilter {
    // 视频总时长
    self.videoTotalTime = CMTimeGetSeconds(self.shortVideoEditor.timeRange.duration);
    
    // 传入图像的方向是否为原始朝向(相机采集的原始朝向)，SDK 将依据该属性来调整人脸检测时图片的角度。如果没有对图片进行旋转，则为 YES
    BOOL isOriginalOrientation = NO;
    
    self.filterProcessor = [[TuSDKFilterProcessor alloc] initWithFormatType:kCVPixelFormatType_32BGRA isOriginalOrientation:isOriginalOrientation];
    self.filterProcessor.delegate = self;
    self.filterProcessor.mediaEffectDelegate = self;
    // 默认关闭动态贴纸功能，即关闭人脸识别功能
    self.filterProcessor.enableLiveSticker = NO;
}

// 初始化相关数据
- (void)initEffectsData {
    self.videoEffects = @[@"LiveShake01", @"LiveMegrim01", @"EdgeMagic01", @"LiveFancy01_1", @"LiveSoulOut01", @"LiveSignal01"];
    self.displayColors = [self getRandomColorWithCount:self.videoEffects.count];
}

- (NSArray<UIColor *> *)getRandomColorWithCount:(NSInteger)count {
    NSMutableArray *colorArr = [NSMutableArray new];
    for (int i = 0; i < count; i++) {
        UIColor *color = [UIColor colorWithRed:random()%255/255.0 green:random()%255/255.0 blue:random()%255/255.0 alpha:1];
        [colorArr addObject:color];
    }
    return colorArr;
}

/** 移除最后添加的场景特效 */
- (void)didTouchUpRemoveSceneMediaEffectButton:(UIButton *)button
{
    if (self.shortVideoEditor.isEditing) {
        [self.shortVideoEditor stopEditing];
        self.playButton.selected = YES;
    }
    
    [self.effectsView.displayView removeLastSegment];
    
    // 移除最后一个指定类型的特效
    
    /** 1. 通过 mediaEffectsWithType: 获取指定类型的已有特效信息 */
    NSArray<TuSDKMediaEffectData *> *mediaEffects = [_filterProcessor mediaEffectsWithType:TuSDKMediaEffectDataTypeScene];
    /** 2. 获取最后一次添加的特效 */
    TuSDKMediaEffectData *lastMediaEffectData = [mediaEffects lastObject];
    /** 3. 通过 removeMediaEffect： 移除指定特效 */
    [_filterProcessor removeMediaEffect:lastMediaEffectData];
}

#pragma mark TuSDKFilterProcessorMediaEffectDelegate

/**
 当前正在应用的特效
 
 @param processor TuSDKFilterProcessor
 @param mediaEffectData 正在预览特效
 @since 2.2.0
 */
- (void)onVideoProcessor:(TuSDKFilterProcessor *)processor didApplyingMediaEffect:(TuSDKMediaEffectData *)mediaEffectData;
{
    // 当前是否为滤镜特效
    if (mediaEffectData.effectType == TuSDKMediaEffectDataTypeFilter) {
        
    }
}

/**
 特效被移除通知
 
 @param processor TuSDKFilterProcessor
 @param mediaEffects 被移除的特效列表
 @since      v2.2.0
 */
- (void)onVideoProcessor:(TuSDKFilterProcessor *)processor didRemoveMediaEffects:(NSArray<TuSDKMediaEffectData *> *)mediaEffects;
{
    // 当特效数据被移除时触发该回调，以下情况将会触发：
    
    // 1. 当特效不支持添加多个时 SDK 内部会自动移除不可叠加的特效
    // 2. 当开发者调用 removeMediaEffect / removeMediaEffectsWithType: / removeAllMediaEffects 移除指定特效时
    
}

#pragma mark EffectsViewEventDelegate

/**
 按下了场景特效 触发编辑功能
 
 @param effectsView 特效视图
 @param effectCode 特效代号
 */
- (void)effectsView:(EffectsView *)effectsView didSelectMediaEffectCode:(NSString *)effectCode
{
    // 启动视频预览
    [self.shortVideoEditor startEditing];
    self.playButton.selected = NO;
    
    if (self.videoProgress >= 1) {
        self.videoProgress = 0;
    }
    
    // 添加特效步骤
    
    // step 1: 构建指定类型的特效数据
    _editingEffectData = [[TuSDKMediaSceneEffectData alloc] initWithEffectsCode:effectCode];
    
    // step 2: 设置特效触发时间
    //    提示： 由于开始编辑特殊特效时不知道结束时间，添加特效时可以将结束时间设置为一个特大值（实现全程预览），结束编辑时再置为正确结束时间。
    _editingEffectData.atTimeRange = [TuSDKTimeRange makeTimeRangeWithStart:[self.shortVideoEditor currentTime] end:CMTimeMake(INTMAX_MAX, 1)];
    
    // step 3: 使用 addMediaEffect： 添加特效
    [self.filterProcessor addMediaEffect:_editingEffectData];
    
    // 开始更新特效 UI
    [self.effectsView.displayView addSegmentViewBeginWithStartLocation:self.videoProgress WithColor:[self.displayColors objectAtIndex:[self.videoEffects indexOfObject:effectCode]]];
}

/**
 结束编辑场景特效
 
 @param effectsView 场景特效视图
 @param effectCode 场景特效代号
 */
- (void)effectsView:(EffectsView *)effectsView didDeSelectMediaEffectCode:(NSString *)effectCode;
{
    if (self.editingEffectData)
    {
        // 停止视频预览
        [self.shortVideoEditor stopEditing];
        self.playButton.selected = YES;
        
        // 结束视频特效处理
        self.editingEffectData.atTimeRange = [TuSDKTimeRange makeTimeRangeWithStart: self.editingEffectData.atTimeRange.start end:[self.shortVideoEditor currentTime]];
        self.editingEffectData = nil;
        // 结束更新特效 UI
        [self.effectsView.displayView addSegmentViewEnd];
        
    }
}

// 清除已添加的所有特效
- (void)clearAllEffectsHistory {
    [self.effectsView.displayView removeAllSegment];
    [self.filterProcessor removeAllMediaEffect];
}

- (void)resetExportVideoEffectsMark {
    [self.filterProcessor switchFilterWithCode:nil];
}

// 重置标志位
- (void)resetPreviewVideoEffectsMark {
    [self.filterProcessor switchFilterWithCode:nil];
}

#pragma mark - TuSDKFilterProcessorDelegate
// 滤镜切换的回调
- (void)onVideoProcessor:(TuSDKFilterProcessor *)processor filterChanged:(TuSDKFilterWrap *)newFilter {
    // nothing
    NSLog(@"%s", __func__);
}

// =================    TuSDK end    ================

@end
