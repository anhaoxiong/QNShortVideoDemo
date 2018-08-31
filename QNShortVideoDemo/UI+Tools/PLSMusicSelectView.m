//
//  PLSMusicSelectView.m
//  QNShortVideoDemo
//
//  Created by hxiongan on 2018/8/29.
//  Copyright © 2018年 hxiongan. All rights reserved.
//

#import "PLSMusicSelectView.h"

@interface PLSMusicSelectView ()
<
UICollectionViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout
>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *musicArray;

@end

@implementation PLSMusicSelectView


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(frame.size.height - 20, frame.size.height - 20);
        [layout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
        layout.minimumLineSpacing = 10;
        layout.minimumInteritemSpacing = 0;
        
        self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        [self.collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"stickerCell"];
        self.collectionView.backgroundColor = [UIColor colorWithWhite:.0 alpha:.5];
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.showsVerticalScrollIndicator = NO;
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        
        [self addSubview:self.collectionView];
        [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).insets(UIEdgeInsetsMake(-10, 0, -10, 0));
        }];
        
        self.musicArray = @[@"counter-6s.m4a", @"counter-35s.m4a", @"Fire_Breather.m4a", @"Greenery.m4a", @"If_I_Had_a_Chicken.m4a", @"Whistling_Down_the_Road.m4a"];
    }
    return self;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.musicArray.count + 1;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"stickerCell" forIndexPath:indexPath];
    
    const static int lableTag = 0x1234;
    
    UILabel *label = (UILabel *)[cell.contentView  viewWithTag:lableTag];
    if (!label) {
        label = [[UILabel alloc] initWithFrame:cell.contentView.bounds];
        label.tag = lableTag;
        label.font = [UIFont systemFontOfSize:14];
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.layer.cornerRadius = cell.bounds.size.width/2;
        label.clipsToBounds = YES;
        label.layer.borderWidth = 1;
        label.layer.borderColor = [UIColor whiteColor].CGColor;
        label.textColor = [UIColor whiteColor];
        [cell.contentView addSubview:label];
        
        cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.contentView.bounds];
        cell.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:.5];
        cell.selectedBackgroundView.layer.cornerRadius = cell.contentView.bounds.size.height/2;
    }
    
    if (0 == indexPath.row) {
        label.text = @"无";
    } else {
        label.text = self.musicArray[indexPath.row - 1];
    }
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    if (0 == indexPath.row) {
        [self.delegate musicSelectView:self didSelectedMusic:nil];
    } else {
        [self.delegate musicSelectView:self didSelectedMusic:self.musicArray[indexPath.row - 1]];
    }
}


@end
