//
//  PLSStickerSelectView.m
//  QNShortVideoDemo
//
//  Created by hxiongan on 2018/8/29.
//  Copyright © 2018年 hxiongan. All rights reserved.
//

#import "PLSStickerSelectView.h"

@interface PLSStickerSelectView ()
<
UICollectionViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout
>

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSArray *stickerPathArray;

@end

@implementation PLSStickerSelectView

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
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"sticker.bundle" ofType:nil];
        self.stickerPathArray = [NSFileManager.defaultManager contentsOfDirectoryAtPath:path error:nil];
        
    }
    return self;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.stickerPathArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"stickerCell" forIndexPath:indexPath];
    
    const static int imageViewTag = 0x1234;
    
    UIImageView *imageView = (UIImageView *)[cell.contentView  viewWithTag:imageViewTag];
    if (!imageView) {
        imageView = [[UIImageView alloc] initWithFrame:cell.contentView.bounds];
        imageView.tag = imageViewTag;
        [cell.contentView addSubview:imageView];
        
        cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.contentView.bounds];
        cell.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:.5];
        cell.selectedBackgroundView.layer.cornerRadius = cell.contentView.bounds.size.height/2;
    }
    imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"sticker.bundle/%@" , self.stickerPathArray[indexPath.row]]];

    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"sticker.bundle/%@" , self.stickerPathArray[indexPath.row]]];
    [self.delegate stickerSelectView:self didSelectedImage:image];
}

@end
