//
//  ViewController.m
//  QNShortVideoDemo
//
//  Created by hxiongan on 2018/8/28.
//  Copyright © 2018年 hxiongan. All rights reserved.
//

#import "ViewController.h"
#import "RecordingViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *recordingButton = [UIButton buttonWithType:(UIButtonTypeSystem)];
    [recordingButton setTitle:@"点击拍摄" forState:(UIControlStateNormal)];
    [recordingButton sizeToFit];
    [recordingButton addTarget:self action:@selector(clickRecordingButton:) forControlEvents:(UIControlEventTouchUpInside)];

    [self.view addSubview:recordingButton];

    [recordingButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)clickRecordingButton:(UIButton *)button {
    RecordingViewController *recordingController = [[RecordingViewController alloc] init];
    [self presentViewController:recordingController animated:YES completion:nil];
}

@end
