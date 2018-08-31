//
//  FilterView.h
//  ImageArrTest
//
//  Created by tutu on 2017/3/10.
//  Copyright © 2017年 wen. All rights reserved.
//



#import <UIKit/UIKit.h>
#import <TuSDKVideo/TuSDKVideo.h>

@class FilterView;

//滤镜栏事件代理
@protocol FilterViewEventDelegate <NSObject>

@optional
/**
 滤镜参数改变

 @param filterView 滤镜视图
 @param index 参数索引
 @param precent 参数值
 */
- (void)filterView:(FilterView *)filterView didArgChangedOfIndex:(NSUInteger)index precent:(CGFloat)precent;

/**
 点击选择新滤镜

 @param effectCode 选中滤镜的code
 */
- (void)filterView:(FilterView *)filterView didSelectFilterCode:(NSString *)effectCode;

@end


@interface FilterView : UIView

//是否能够调节参数，默认false; 不调节参数时，不会创建滤镜的参数栏
@property (nonatomic, assign) BOOL canAdjustParameter;
//滤镜事件的代理
@property (nonatomic, assign) id<FilterViewEventDelegate> filterEventDelegate;
//当前选中的滤镜的tag值
@property (nonatomic, assign) NSInteger currentFilterTag;


//根据滤镜数组创建滤镜view
- (void)createFilterWith:(NSArray *)filterArr;

/**
 改变滤镜后，需重新设置滤镜参数栏view

 @param filterDescription 当前滤镜的code
 @param args 当前滤镜的参数数组
 */
- (void)refreshAdjustParameterViewWith:(NSString *)filterDescription filterArgs:(NSArray<TuSDKFilterArg *> *)args;

@end

