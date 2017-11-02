//
//  doDialogView.h
//  Do_Test
//
//  Created by yz on 16/3/21.
//  Copyright © 2016年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface doDialogView : UIView
@property (nonatomic,strong) NSString *data;
@property (nonatomic,strong) UIView *contentView;
@property (nonatomic,assign) BOOL supportClickClose;

- (void)show:(UIViewController *)currentVC;
- (void)close;
@end


