//
//  PLSStickerView.m
//  PLVideoEditor
//
//  Created by suntongmian on 2018/5/24.
//  Copyright © 2018年 Pili Engineering, Qiniu Inc. All rights reserved.
//

#import "PLSStickerView.h"

#define kPLSStickerViewBtnLength 16

@interface PLSStickerView ()
<
UITextViewDelegate
>

@property (nonatomic) UITextView *tf;

@property (nonatomic) UILabel *lb;
// 写入范围
@property (nonatomic, assign) CGRect inputRect;

@end

@implementation PLSStickerView

- (instancetype)initWithImage:(UIImage *)image{
    return [self initWithImage:image Type:StickerType_Sticker];
}

- (instancetype)initWithImage:(UIImage *)image Type:(StickerType)type{
    if (self = [super initWithImage:image]) {
        self.userInteractionEnabled = YES;
        _type = type;
        _oriScale = 1.0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextViewTextDidChangeNotification object:nil];
        
        [self setupUI];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews{
//    [super layoutSubviews];
    _dragBtn.center = CGPointMake(self.frame.size.width, self.frame.size.height);
    _closeBtn.center = CGPointMake(self.frame.size.width, 0);
    // 字样展示范围
    _lb.frame = CGRectMake(self.frame.size.width * _inputRect.origin.x,
                           self.frame.size.height * _inputRect.origin.y,
                           self.frame.size.width * _inputRect.size.width,
                           self.frame.size.height * _inputRect.size.height);
}

- (void)setupUI{
    _dragBtn = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sticker_rotate"]];
    _dragBtn.userInteractionEnabled = YES;
    [self addSubview:_dragBtn];
    
    _closeBtn = [[UIButton alloc] init];
    [_closeBtn setImage:[UIImage imageNamed:@"sticker_delete"] forState:UIControlStateNormal];
    [_closeBtn addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_closeBtn];
    
    _dragBtn.frame = CGRectMake(0, 0, kPLSStickerViewBtnLength, kPLSStickerViewBtnLength);
    _closeBtn.frame = CGRectMake(0, 0, kPLSStickerViewBtnLength, kPLSStickerViewBtnLength);
    if (_type == StickerType_SubTitle) {
        [self integrateTextViews];
    }
}

- (void)integrateTextViews {
    // TODO: 使用绘制方式替换lb
    if (!_tf) {
        [self addSubview:self.tf];
    }
    if (!_lb) {
        [self addSubview:self.lb];
    }
}

- (void)deintegrateTextViews {
    if (_tf) {
        [_tf removeFromSuperview];
        _tf = nil;
    }
    
    if (_lb) {
        [_lb removeFromSuperview];
        _lb = nil;
    }
}

- (void)close:(id)sender {
    if ([self.delegate respondsToSelector:@selector(stickerViewClose:)]) {
        [self.delegate stickerViewClose:self];
    }
    
    [self removeFromSuperview];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.alpha > 0.1 && !self.clipsToBounds) {
        for (UIView *subView in @[self.dragBtn, self.closeBtn]) {
            CGPoint subPoint = [self convertPoint:point toView:subView];
            UIView *resultView = [subView hitTest:subPoint withEvent:event];
            if (resultView) {
                return resultView;
            }
        }
    }
    
    return [super hitTest:point withEvent:event];
}

- (BOOL)becomeFirstResponder {
    if (![_tf canBecomeFirstResponder]) {
        return NO;
    }
    return [_tf becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    return [_tf resignFirstResponder];
}

#pragma mark - UITextFieldDelegate
- (void)textViewDidEndEditing:(UITextView *)textView {
    [_lb setText:_tf.text];
}

- (void)textDidChange:(NSNotification *)notify {
    _lb.text = _tf.text;
}

#pragma mark - Getter/Setter
- (void)setType:(StickerType)type {
    _type = type;
    if (type == StickerType_Sticker) {
        [self deintegrateTextViews];
    }else if (type == StickerType_SubTitle){
        [self integrateTextViews];
    }
}

- (void)setSelect:(BOOL)select{
    _select = select;
    if (select) {
        self.layer.borderWidth = 1;
        self.layer.borderColor = [[UIColor whiteColor] CGColor];
        self.closeBtn.hidden = NO;
        self.dragBtn.hidden = NO;
    }else{
        self.layer.borderWidth = 0;
        self.closeBtn.hidden = YES;
        self.dragBtn.hidden = YES;
    }
}

- (UITextView *)tf {
    if (!_tf) {
        _tf = [[UITextView alloc] initWithFrame:CGRectZero];
        _tf.delegate = self;
        _tf.returnKeyType = UIReturnKeyContinue;
        _tf.font = [UIFont systemFontOfSize:20];
    }
    return _tf;
}

- (UILabel *)lb {
    if(!_lb){
        // TODO:需要修正编辑范围
        _lb = [[UILabel alloc] initWithFrame:self.bounds];
        [_lb addSubview:_tf];
        _lb.numberOfLines = 0;
        _lb.text = @"";
        _lb.userInteractionEnabled = YES;
        _lb.adjustsFontSizeToFitWidth = YES;
    }
    return _lb;
}

- (CGAffineTransform)currentTransform {
    return self.transform;
}

// 根据图片素材（如图片：sticker_t_0）设置字体渲染范围
- (void)calcInputRectWithImgName:(NSString *)name {
    CGFloat x,y,w,h;
    char c = [name characterAtIndex:name.length-1];
    switch (c) {
        case '1':
            x = 25.0  / 243;
            y = 42.0  / 120;
            w = 172.0 / 243;
            h = 50.0  / 120;
            break;
        case '2':
            x = 55.0 / 198;
            y = 39.0 / 148;
            w = 90.0 / 198;
            h = 72.0 / 148;
            break;
        case '3':
            x = 22.0 / 189;
            y = 23.0 / 120;
            w = 102.0 / 189;
            h = 72.0 / 120;
            break;
        case '4':
            x = 105.0 / 294;
            y = 41.0 / 95;
            w = 158.0 / 294;
            h = 39.0 / 95;
            break;
        case '5':
            x = 23.0 / 151;
            y = 31.0 / 139;
            w = 90.0 / 151;
            h = 56.0 / 139;
            break;
        default:
            x = 0;
            y = 0;
            w = 1;
            h = 1;
            break;
    }
    
    _inputRect = CGRectMake(x, y, w, h);
}

@end

