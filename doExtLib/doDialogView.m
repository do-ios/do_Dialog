//
//  doDialogView.m
//  Do_Test
//
//  Created by yz on 16/3/21.
//  Copyright © 2016年 DoExt. All rights reserved.
//

#import "doDialogView.h"


static NSString *didBeginEdit = @"DODidBeginEditNotification";
static NSString *keyboardShow = @"DOKeyboardShowNotification";
static NSString *keyboardHide = @"DOKeyboardHideNotification";

static CFTimeInterval dialogDuration = .3;

@interface doDialogView()<UIGestureRecognizerDelegate>

@property (nonatomic,assign) CGRect originFrame;
@end

@implementation doDialogView
{
    CGRect _keyBoardFrame;

    UIView *_firstResponse;
}
@synthesize supportClickClose = _supportClickClose;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0];
        [self registerNotification];
    }
    return self;
}

- (void)setContentView:(UIView *)contentView
{
    _contentView = contentView;
    UIView *subView = [_contentView.subviews firstObject];
    if (subView) {
        [subView addObserver:self forKeyPath:@"frame" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"frame"]) {
        NSValue *valueOld = (NSValue *)[change valueForKey:@"old"];
        NSValue *valueNew = (NSValue *)[change valueForKey:@"new"];
        
        CGFloat heightOld = CGRectGetHeight([valueOld CGRectValue]);
        CGFloat heightNew = CGRectGetHeight([valueNew CGRectValue]);
        
        if (heightOld != heightNew) {
            CGRect r = _contentView.frame;
            r.size.height = heightNew;

            _contentView.frame = r;
        }
    }
}


- (void)registerNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShow:) name:keyboardShow object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHide:) name:keyboardHide object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBeginEdit:) name:didBeginEdit object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)show:(UIViewController *)currentVC
{
    if (_supportClickClose) {
        UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dialogViewTap:)];
        viewTap.delegate = self;
        [self addGestureRecognizer:viewTap];
    }
    _contentView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2);
    _contentView.layer.masksToBounds = NO;
    
    CALayer *shadLayer = [CALayer layer];
    shadLayer.frame = _contentView.layer.frame;
    shadLayer.shadowOffset = CGSizeMake(6, 6);
    shadLayer.shadowRadius = 10;
    shadLayer.cornerRadius = 10;
    shadLayer.shadowOpacity = 1;
    [self.layer addSublayer:shadLayer];
    
    _contentView.layer.cornerRadius = 10;
    _contentView.alpha = 0;
    _contentView.clipsToBounds = YES;
    [self addSubview:self.contentView];
    [currentVC.view addSubview:self];
    [self animationWithView:_contentView];
}
-(void)animationWithView:(UIView *)view
{
    view.transform = CGAffineTransformMakeScale(1.1, 1.1);
    [UIView animateWithDuration:dialogDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:.4];
        view.alpha = .97;
        view.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
    }];
}

- (void)close
{
    UIView *subView = [_contentView.subviews firstObject];
    if (subView) {
        [subView removeObserver:self forKeyPath:@"frame"];
    }
    [UIView animateWithDuration:dialogDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _contentView.transform = CGAffineTransformMakeScale(.9, .9);
        self.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0];
        _contentView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.contentView removeFromSuperview];
        [self removeFromSuperview];
        _contentView.transform = CGAffineTransformIdentity;
    }];
}
- (void)dialogViewTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint location  = [recognizer locationInView:self];
    if (CGRectContainsPoint(_contentView.frame, location)) {
        return;
    }
    self.data = nil;
    [self close];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if(touch.view != self){
        return NO;
    }else
        return YES;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
#pragma mark - keyboard
//开始编辑的时候收到抬起的通知，键盘消失的时候收到放下通知（键盘放下通知不能放到文本框结束编辑的时候，否则在bottomview有两个文本框互相切换的时候，borderview会上下反复收放）
- (void)keyboardShow:(NSNotification *)noti
{
    _firstResponse = [noti object];
    if ([self findFirstResponder:self]) {
        NSDictionary *info = [noti userInfo];
        NSValue *value = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
        _keyBoardFrame = [value CGRectValue];
        
        [self responseKeyBoard:YES];
    }
}
- (void)didBeginEdit:(NSNotification *)noti
{
    _firstResponse = [noti object];
    if ([self findFirstResponder:self]) {
        [self responseKeyBoard:YES];
    }
}
- (void)keyboardHide:(NSNotification *)noti
{
    _firstResponse = [noti object];
    if ([self findFirstResponder:self]) {
        [self responseKeyBoard:NO];
    }
}
- (BOOL)findFirstResponder:(UIView *)view {
    NSArray *subviews = [view subviews];
    
    BOOL isFirst = NO;
    
    if ([subviews count] == 0)
        isFirst = NO;
    
    for (UIView *subview in subviews) {
        if ([subview isEqual:_firstResponse]) {
            isFirst = YES;
            break;
        }else{
            isFirst = [self findFirstResponder:subview];
            if (isFirst) {
                break;
            }
        }
        
    }
    return isFirst;
}

- (void)responseKeyBoard:(BOOL)isShow
{
    CGFloat restHeight = [self diffHeightInRootView];
    CGFloat diffHeight = restHeight - CGRectGetHeight(_contentView.frame);
    CGPoint p = _contentView.center;
    CGFloat textDiffHeight = CGRectGetMaxY([self rectInRootView])-CGRectGetMinY(_keyBoardFrame);
    if (isShow) {
        if (textDiffHeight<0 && diffHeight<0) {
            return;
        }
        if (CGRectGetHeight(_keyBoardFrame)>0) {
            if (diffHeight>=0) {
                p.y = restHeight/2;
            }else
                p.y -= textDiffHeight;
        }
    }else
        p = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2);

    [UIView animateWithDuration:.3 animations:^{
        _contentView.center = p;
    }];
}

- (CGFloat)diffHeightInRootView
{
    UIView *rootView = self;
    CGFloat diffHeight = CGRectGetHeight(rootView.frame) - CGRectGetHeight(_keyBoardFrame);
    return diffHeight;
}


- (CGRect)rectInRootView
{
    UIView *rootView = self;
    CGRect rect = [_firstResponse convertRect:_firstResponse.bounds toView:rootView];
    return rect;
}
@end
