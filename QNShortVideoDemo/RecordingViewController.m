//
//  RecordingViewController.m
//  QNShortVideoDemo
//
//  Created by hxiongan on 2018/8/28.
//  Copyright © 2018年 hxiongan. All rights reserved.
//

#import "RecordingViewController.h"
#import "EditViewController.h"
#import <PLShortVideoKit/PLShortVideoKit.h>
#import "UIView+Alert.h"

#import "PLSFilterGroup.h"
#import "PLSProgressBar.h"
#import "PLSDeleteButton.h"
#import "PLSVerticalButton.h"

// TuSDK
#import "StickerScrollView.h"
#import <TuSDKVideo/TuSDKVideo.h>

@interface RecordingViewController ()
<
PLShortVideoRecorderDelegate,
UIGestureRecognizerDelegate,
StickerViewClickDelegate
>

@property (nonatomic, strong) PLShortVideoRecorder *shortVideoRecorder;

@property (nonatomic, strong) PLSFilterGroup *filterGroup;
@property (nonatomic, assign) NSInteger filterIndex;

@property (nonatomic, strong) PLSProgressBar *processBar;
@property (nonatomic, strong) PLSDeleteButton *deleteButton;
@property (nonatomic, strong) UIButton *stickerButton;
@property (nonatomic, strong) UIButton *recorderButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UISegmentedControl *rateSegment;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, strong) UIButton *musicButton;

@property (nonatomic, strong) UIImageView *filterImageView;
@property (nonatomic, strong) UILabel *filterNameLabel;

@property (nonatomic, strong) NSMutableArray *filterInfoArray;
// TuSDK
@property (nonatomic, strong) StickerScrollView *stickerView;
@property (nonatomic, strong) TuSDKFilterProcessor *filterProcessor;

@end

@implementation RecordingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化短视频录制
    [self setupRecorder];
    
    // 初始化滤镜
    [self setupFilter];
    
    // 初始化 UI
    [self setupUI];
    
    // 初始化贴纸
    [self setupSticker];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.shortVideoRecorder startCaptureSession];
}

- (void)viewWillDisappear:(BOOL)animated {
    if ([self.shortVideoRecorder isRecording]) {
        [self.shortVideoRecorder stopRecording];
    }
    [self.shortVideoRecorder stopCaptureSession];
    
    [super viewWillDisappear:animated];
}

- (void)setupRecorder {
    
    PLSVideoConfiguration *videoConfiguration = [PLSVideoConfiguration defaultConfiguration];
    videoConfiguration.position = AVCaptureDevicePositionFront;
    PLSAudioConfiguration *audioConfiguration = [PLSAudioConfiguration defaultConfiguration];
    
    self.shortVideoRecorder = [[PLShortVideoRecorder alloc] initWithVideoConfiguration:videoConfiguration audioConfiguration:audioConfiguration];
    self.shortVideoRecorder.delegate = self;
    [self.shortVideoRecorder setBeautifyModeOn:YES];
    [self.view addSubview:self.shortVideoRecorder.previewView];
    [self.shortVideoRecorder.previewView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)setupFilter {
    
    self.filterIndex = 0;
    self.filterGroup = [[PLSFilterGroup alloc] init];
    
    UISwipeGestureRecognizer *recognizer;
    // 添加右滑手势
    recognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.view addGestureRecognizer:recognizer];
    recognizer.delegate = self;
    // 添加左滑手势
    recognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.view addGestureRecognizer:recognizer];
    recognizer.delegate = self;
    
    // 添加下滑手势
    recognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [self.view addGestureRecognizer:recognizer];
    recognizer.delegate = self;
    
    self.filterInfoArray = [[NSMutableArray alloc] init];
    for (NSDictionary *filterInfoDic in self.filterGroup.filtersInfo) {
        NSString *name = [filterInfoDic objectForKey:@"name"];
        NSString *coverImagePath = [filterInfoDic objectForKey:@"coverImagePath"];
        
        NSDictionary *dic = @{
                              @"name"            : name,
                              @"coverImagePath"  : coverImagePath
                              };
        [self.filterInfoArray addObject:dic];
    }
}

- (void)setupSticker {
    
    self.filterProcessor = [[TuSDKFilterProcessor alloc] initWithFormatType:kCVPixelFormatType_32BGRA isOriginalOrientation:NO];
    self.filterProcessor.outputPixelFormatType = lsqFormatTypeBGRA;
    [self.filterProcessor setEnableLiveSticker:YES];
    
    CGFloat stickerViewHeight = 246;
    self.stickerView = [[StickerScrollView alloc] initWithFrame:CGRectMake(0, self.view.lsqGetSizeHeight, self.view.lsqGetSizeWidth, stickerViewHeight)];
    self.stickerView.stickerDelegate = self;
    self.stickerView.cameraStickerType = lsqCameraStickersTypeSquare;
    self.stickerView.backgroundColor = [UIColor colorWithRed:0.22 green:0.22 blue:0.22 alpha:0.7];
    [self.view addSubview:self.stickerView];
    
    [self.stickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_bottom);
        make.height.equalTo(stickerViewHeight);
    }];
}

- (void)setupUI {
    
    self.processBar = [[PLSProgressBar alloc] initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, 8)];
    [self.view addSubview:self.processBar];
    [self.processBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.mas_topLayoutGuide).offset(50);
        make.height.equalTo(8);
    }];
    
    self.stickerButton = [[UIButton alloc] init];
    [self.stickerButton setImage:[UIImage imageNamed:@"sticker"] forState:(UIControlStateNormal)];
    [self.stickerButton sizeToFit];
    [self.stickerButton addTarget:self action:@selector(clickStickerButton:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:self.stickerButton];
    
    self.recorderButton = [[UIButton alloc] init];
    self.recorderButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.recorderButton setBackgroundImage:[UIImage imageNamed:@"btn_record_a"] forState:(UIControlStateNormal)];
    [self.recorderButton setTitle:@"点击拍摄" forState:(UIControlStateNormal)];
    [self.recorderButton setTitle:@"停止拍摄" forState:(UIControlStateSelected)];
    [self.recorderButton addTarget:self action:@selector(recordButtonEvent:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:self.recorderButton];
    [self.recorderButton sizeToFit];
    [self.recorderButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-60);
        make.size.equalTo(self.recorderButton.bounds.size);
    }];
    
    [self.stickerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.recorderButton);
        make.right.equalTo(self.recorderButton.mas_left).offset(-30);
        make.size.equalTo(self.stickerButton.bounds.size);
    }];
    
    self.deleteButton = [PLSDeleteButton getInstance];
    self.deleteButton.style = PLSDeleteButtonStyleNormal;
    [self.deleteButton setImage:[UIImage imageNamed:@"btn_del_a"] forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(deleteButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.deleteButton];
    self.deleteButton.hidden = YES;
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(CGSizeMake(50, 50));
        make.left.equalTo(self.recorderButton.mas_right).offset(30);
        make.centerY.equalTo(self.recorderButton);
    }];
    
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:self.view.bounds];
    self.activityIndicatorView.center = self.view.center;
    [self.activityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicatorView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    
    UIButton *beautifyButton = [[UIButton alloc] init];
    [beautifyButton setImage:[UIImage imageNamed:@"face-beauty-open"] forState:(UIControlStateSelected)];
    [beautifyButton setImage:[UIImage imageNamed:@"face-beauty-close"] forState:(UIControlStateNormal)];
    [beautifyButton addTarget:self action:@selector(beautifyButtonEvent:) forControlEvents:(UIControlEventTouchUpInside)];
    beautifyButton.selected = YES;
    
    UIButton *torchButton = [[UIButton alloc] init];
    [torchButton setImage:[UIImage imageNamed:@"flash"] forState:(UIControlStateNormal)];
    [torchButton addTarget:self action:@selector(torchButtonButtonEvent:) forControlEvents:(UIControlEventTouchUpInside)];
    
    UIButton *switchCameraButton = [[UIButton alloc] init];
    [switchCameraButton setImage:[UIImage imageNamed:@"camera-switch-end"] forState:(UIControlStateNormal)];
    [switchCameraButton addTarget:self action:@selector(switchCameraButtonEvent:) forControlEvents:(UIControlEventTouchUpInside)];
    
    [self.view addSubview:beautifyButton];
    [self.view addSubview:torchButton];
    [self.view addSubview:switchCameraButton];
    
    [beautifyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.top.equalTo(self.processBar.mas_bottom).offset(10);
        make.size.equalTo(CGSizeMake(44, 44));
    }];
    
    [torchButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(beautifyButton.mas_right).offset(10);
        make.size.top.equalTo(beautifyButton);
    }];
    
    [switchCameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(torchButton.mas_right).offset(10);
        make.size.top.equalTo(torchButton);
    }];
    
    self.nextButton = [[UIButton alloc] init];
    [self.nextButton setImage:[UIImage imageNamed:@"next_button"] forState:(UIControlStateNormal)];
    [self.nextButton addTarget:self action:@selector(nextButtonEvent:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:self.nextButton];
    [self.nextButton sizeToFit];
    
    [self.nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-30);
        make.centerY.equalTo(beautifyButton);
        make.size.equalTo(self.nextButton.bounds.size);
    }];
    
    self.rateSegment = [[UISegmentedControl alloc] initWithItems:@[@"极慢", @"慢", @"正常", @"快", @"极快"]];
    [self.rateSegment sizeToFit];
    self.rateSegment.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    self.rateSegment.layer.cornerRadius = 5;
    [self.view addSubview:self.rateSegment];
    self.rateSegment.selectedSegmentIndex = 2;
    [self.rateSegment addTarget:self action:@selector(rateSegmentChange:) forControlEvents:(UIControlEventValueChanged)];
    [self.rateSegment setTintColor:[UIColor clearColor]];
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithWhite:.5 alpha:1], NSForegroundColorAttributeName, [UIFont systemFontOfSize:16],NSFontAttributeName,nil];
    [self.rateSegment setTitleTextAttributes:dic forState:UIControlStateNormal];
    NSDictionary *dicS = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithWhite:1 alpha:1.0],NSForegroundColorAttributeName, [UIFont systemFontOfSize:16],NSFontAttributeName ,nil];
    [self.rateSegment setTitleTextAttributes:dicS forState:UIControlStateSelected];
    [self.rateSegment mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.recorderButton);
        make.bottom.equalTo(self.recorderButton.mas_top).offset(-30);
        make.size.equalTo(CGSizeMake(300, 35));
    }];
    
    CGSize size = CGSizeMake(38, 38);
    self.filterImageView = [[UIImageView alloc] init];
    self.filterImageView.layer.cornerRadius = size.width/2;
    self.filterImageView.clipsToBounds = YES;
    self.filterImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.filterImageView.frame = CGRectMake(self.view.bounds.size.width - 80, self.nextButton.frame.origin.y + 80, size.width, size.height);
    self.filterImageView.image = [UIImage imageWithContentsOfFile:[[self.filterInfoArray objectAtIndex:self.filterIndex] objectForKey:@"coverImagePath"]];
    [self.view addSubview:self.filterImageView];
    
    [self.filterImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-30);
        make.top.equalTo(self.nextButton.mas_bottom).offset(50);
        make.size.equalTo(size);
    }];
    
    self.filterNameLabel = [[UILabel alloc] init];
    self.filterNameLabel.font = [UIFont systemFontOfSize:14];
    self.filterNameLabel.text = [[self.filterInfoArray objectAtIndex:self.filterIndex] objectForKey:@"name"];
    self.filterNameLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.filterNameLabel];
    [self.filterNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.filterImageView);
        make.top.equalTo(self.filterImageView.mas_bottom).offset(10);
    }];
    
    self.musicButton = [[PLSVerticalButton alloc] init];
    self.musicButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.musicButton setImage:[UIImage imageNamed:@"music"] forState:(UIControlStateNormal)];
    [self.musicButton setTitle:@"音乐" forState:(UIControlStateNormal)];
    [self.musicButton addTarget:self action:@selector(musicButtonEvent:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:self.musicButton];
    [self.musicButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.filterImageView);
        make.size.equalTo(CGSizeMake(38, 70));
        make.top.equalTo(self.filterNameLabel.mas_bottom).offset(20);
    }];
    
    UIButton *backButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    [backButton setTintColor:[UIColor whiteColor]];
    [backButton setTitle:@"返回" forState:(UIControlStateNormal)];
    [backButton sizeToFit];
    [backButton addTarget:self action:@selector(backButtonEvent:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:backButton];
    [backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(20);
        make.bottom.equalTo(self.processBar.mas_top).offset(-10);
        make.size.equalTo(backButton.bounds.size);
    }];
}

- (void)backButtonEvent:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)clickStickerButton:(UIButton *)button {
    if ([self stickerViewIsShow]) {
        [self hideStickerView];
    } else {
        [self showStickerView];
    }
}

// 删除上一段视频
- (void)deleteButtonEvent:(id)sender {
    if (_deleteButton.style == PLSDeleteButtonStyleNormal) {
        
        [self.processBar setLastProgressToStyle:PLSProgressBarProgressStyleDelete];
        _deleteButton.style = PLSDeleteButtonStyleDelete;
        
    } else if (_deleteButton.style == PLSDeleteButtonStyleDelete) {
        
        [self.shortVideoRecorder deleteLastFile];
        
        [self.processBar deleteLastProgress];
        
        _deleteButton.style = PLSDeleteButtonStyleNormal;
    }
}

// 录制视频
- (void)recordButtonEvent:(id)sender {
    if (self.shortVideoRecorder.isRecording) {
        self.recorderButton.selected = NO;
        [self.shortVideoRecorder stopRecording];
    } else {
        self.recorderButton.selected = YES;
        [self.shortVideoRecorder startRecording];
    }
}

- (void)beautifyButtonEvent:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    [self.shortVideoRecorder setBeautifyModeOn:sender.selected];
}

- (void)torchButtonButtonEvent:(UIButton *)sender {
    self.shortVideoRecorder.torchOn = !self.shortVideoRecorder.isTorchOn;
}

- (void)switchCameraButtonEvent:(UIButton *)sender  {
    [self.shortVideoRecorder toggleCamera];
}

- (void)rateSegmentChange:(UISegmentedControl *)segment {
    if (self.shortVideoRecorder.isRecording) return;
    
    static NSInteger rates[] = {
        PLSVideoRecoderRateTopSlow,
        PLSVideoRecoderRateSlow,
        PLSVideoRecoderRateNormal,
        PLSVideoRecoderRateFast,
        PLSVideoRecoderRateTopFast
    };
    
    self.shortVideoRecorder.recoderRate = rates[segment.selectedSegmentIndex];
}

- (void)musicButtonEvent:(UIButton *)sender {
    self.musicButton.selected = !self.musicButton.selected;
    if (self.musicButton.selected) {
        // 背景音乐
        [self.view showTip:@"背景音乐已添加"];
        NSURL *audioURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Whistling_Down_the_Road" ofType:@"m4a"]];
        [self.shortVideoRecorder mixAudio:audioURL];
    } else{
        [self.view showTip:@"背景音乐已移除"];
        [self.shortVideoRecorder mixAudio:nil];
    }
}

- (void)nextButtonEvent:(id)sender {
    
    if ([self.shortVideoRecorder getTotalDuration] < self.shortVideoRecorder.minDuration) {
        NSString *str = [NSString stringWithFormat:@"请至少拍摄 %d 秒的视频", (int)self.shortVideoRecorder.minDuration];
        [self.view showTip:str];
        return;
    }
    
    AVAsset *asset = self.shortVideoRecorder.assetRepresentingAllFiles;
    [self playEvent:asset];
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UISwipeGestureRecognizer class]]) {
        UISwipeGestureRecognizer *swipeGesture = (UISwipeGestureRecognizer *)gestureRecognizer;
        if (swipeGesture.direction == UISwipeGestureRecognizerDirectionLeft ||
            swipeGesture.direction == UISwipeGestureRecognizerDirectionRight) {
            return ![self stickerViewIsShow];
        }
    }
    return YES;
}

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer{
    
    if(recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        self.filterIndex--;
        if (self.filterIndex < 0) {
            self.filterIndex = self.filterGroup.filtersInfo.count - 1;
        }
    }
    if(recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        self.filterIndex++;
        self.filterIndex %= self.filterGroup.filtersInfo.count;
    }
    if (recognizer.direction == UISwipeGestureRecognizerDirectionDown) {
        [self hideStickerView];
    }
    
    self.filterGroup.filterIndex = self.filterIndex;
    self.filterNameLabel.text = [[self.filterInfoArray objectAtIndex:self.filterIndex] objectForKey:@"name"];
    self.filterImageView.image = [UIImage imageWithContentsOfFile:[[self.filterInfoArray objectAtIndex:self.filterIndex] objectForKey:@"coverImagePath"]];
}

- (BOOL)stickerViewIsShow {
    return self.stickerView.frame.origin.y < self.view.bounds.size.height;
}

- (void)showStickerView {
    if (![self stickerViewIsShow]) {
        
        [self.stickerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.left.right.equalTo(self.view);
            make.height.equalTo(self.stickerView.bounds.size.height);
        }];
        
        [self.view setNeedsUpdateConstraints];
        [self.view updateConstraintsIfNeeded];

        [UIView animateWithDuration:.25 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

- (void)hideStickerView {
    if ([self stickerViewIsShow]) {
        
        [self.stickerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.top.equalTo(self.view.mas_bottom);
            make.height.equalTo(self.stickerView.bounds.size.height);
        }];
        
        [self.view setNeedsUpdateConstraints];
        [self.view updateConstraintsIfNeeded];
        
        [UIView animateWithDuration:.25 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}

// 加载拼接视频的动画
- (void)loadActivityIndicatorView {
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

#pragma mark - 输出路径
- (NSURL *)exportAudioMixPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:path]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    NSString *fileName = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_mix.mp4",nowTimeStr]];
    return [NSURL fileURLWithPath:fileName];
}


#pragma mark -- 下一步
- (void)playEvent:(AVAsset *)asset {
    
    // 获取当前会话的所有的视频段文件
    NSArray *filesURLArray = [self.shortVideoRecorder getAllFilesURL];
    NSLog(@"filesURLArray:%@", filesURLArray);
    
    __block AVAsset *movieAsset = asset;
    if (self.musicButton.selected) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [self loadActivityIndicatorView];
        // MusicVolume：1.0，videoVolume:0.0 即完全丢弃掉拍摄时的所有声音，只保留背景音乐的声音
        [self.shortVideoRecorder mixWithMusicVolume:1.0 videoVolume:0.0 completionHandler:^(AVMutableComposition * _Nullable composition, AVAudioMix * _Nullable audioMix, NSError * _Nullable error) {
            AVAssetExportSession *exporter = [[AVAssetExportSession alloc]initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
            NSURL *outputPath = [self exportAudioMixPath];
            exporter.outputURL = outputPath;
            exporter.outputFileType = AVFileTypeMPEG4;
            exporter.shouldOptimizeForNetworkUse= YES;
            exporter.audioMix = audioMix;
            [exporter exportAsynchronouslyWithCompletionHandler:^{
                switch ([exporter status]) {
                    case AVAssetExportSessionStatusFailed: {
                        NSLog(@"audio mix failed：%@", [[exporter error] description]);
                    } break;
                    case AVAssetExportSessionStatusCancelled: {
                        NSLog(@"audio mix canceled");
                    } break;
                    case AVAssetExportSessionStatusCompleted: {
                        NSLog(@"audio mix success");
                        movieAsset = [AVAsset assetWithURL:outputPath];
                    } break;
                    default: {
                        
                    } break;
                }
                dispatch_semaphore_signal(semaphore);
            }];
        }];
        [self removeActivityIndicatorView];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    // 设置音视频、水印等编辑信息
    NSMutableDictionary *outputSettings = [[NSMutableDictionary alloc] init];
    // 待编辑的原始视频素材
    NSMutableDictionary *plsMovieSettings = [[NSMutableDictionary alloc] init];
    plsMovieSettings[PLSAssetKey] = movieAsset;
    plsMovieSettings[PLSStartTimeKey] = [NSNumber numberWithFloat:0.f];
    plsMovieSettings[PLSDurationKey] = [NSNumber numberWithFloat:[self.shortVideoRecorder getTotalDuration]];
    plsMovieSettings[PLSVolumeKey] = [NSNumber numberWithFloat:1.0f];
    outputSettings[PLSMovieSettingsKey] = plsMovieSettings;
    
    EditViewController *videoEditViewController = [[EditViewController alloc] init];
    videoEditViewController.settings = outputSettings;
    videoEditViewController.filesURLArray = filesURLArray;
    [self presentViewController:videoEditViewController animated:YES completion:nil];
}


#pragma mark -- PLShortVideoRecorderDelegate 视频录制回调
- (CVPixelBufferRef)shortVideoRecorder:(PLShortVideoRecorder *)recorder cameraSourceDidGetPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
    // 进行滤镜处理
    pixelBuffer = [self.filterGroup.currentFilter process:pixelBuffer];
    
    // TuSDK 进行贴纸处理
    pixelBuffer =  [self.filterProcessor syncProcessPixelBuffer:pixelBuffer];
    [self.filterProcessor destroyFrameData];
    
    return pixelBuffer;
}

// 开始录制一段视频时
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didStartRecordingToOutputFileAtURL:(NSURL *)fileURL {
    NSLog(@"start recording fileURL: %@", fileURL);
    
    [self.processBar addProgressView];
    [self.processBar startShining];
}

// 正在录制的过程中
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didRecordingToOutputFileAtURL:(NSURL *)fileURL fileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration {
    [self.processBar setLastProgressToWidth:fileDuration / self.shortVideoRecorder.maxDuration * self.processBar.frame.size.width];
    
    self.deleteButton.hidden = YES;
    self.nextButton.hidden = YES;
    self.musicButton.hidden = YES;
    self.rateSegment.enabled = NO;
}

// 删除了某一段视频
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didDeleteFileAtURL:(NSURL *)fileURL fileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration {

    if (totalDuration <= 0.0000001f) {
        self.deleteButton.hidden = YES;
        self.nextButton.hidden = YES;
        self.musicButton.hidden = NO;
    }
}


// 完成一段视频的录制时
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didFinishRecordingToOutputFileAtURL:(NSURL *)fileURL fileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration {
    
    [self.processBar stopShining];
    
    self.deleteButton.hidden = NO;
    self.recorderButton.selected = NO;
    self.nextButton.hidden = NO;
    self.rateSegment.enabled = YES;
    
    if (totalDuration >= self.shortVideoRecorder.maxDuration) {
        [self nextButtonEvent:nil];
    }
}

// 在达到指定的视频录制时间 maxDuration 后，如果再调用 [PLShortVideoRecorder startRecording]，直接执行该回调
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didFinishRecordingMaxDuration:(CGFloat)maxDuration {
    
    AVAsset *asset = self.shortVideoRecorder.assetRepresentingAllFiles;
    [self playEvent:asset];
    self.recorderButton.selected = NO;
}

- (void)clickStickerViewWith:(TuSDKPFStickerGroup *)stickGroup
{
    if (!stickGroup) {
        //为nil时 移除已有贴纸组；
        [_filterProcessor removeMediaEffectsWithType:TuSDKMediaEffectDataTypeSticker];
        [self hideStickerView];
        return;
    }
    //展示对应贴纸组；
    [self.filterProcessor showGroupSticker:stickGroup];
}

@end
