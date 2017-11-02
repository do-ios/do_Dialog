//
//  do_Dialog_SM.m
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Dialog_SM.h"

#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"
#import "doJsonHelper.h"
#import "doSourceFile.h"
#import "doIApp.h"
#import "doISourceFS.h"
#import "doServiceContainer.h"
#import "doIPage.h"
#import "doUIContainer.h"
#import <UIKit/UIKit.h>
#import "doDialogView.h"


@implementation do_Dialog_SM
{
    doDialogView *dialogView;
    NSString *data;
    id<doIScriptEngine> openScritEngine;
    NSString *openCallbackName;
}
#pragma mark - 方法
#pragma mark - 同步异步方法的实现
//同步
- (void)close:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    data = [doJsonHelper GetOneText:_dictParas :@"data" :@""];
    [dialogView close];
    doInvokeResult *invokeResult = [[doInvokeResult alloc]init];
    [invokeResult SetResultText:data];
    [openScritEngine Callback:openCallbackName :invokeResult];
    dialogView.data = nil;
}
- (void)getData:(NSArray *)parms
{
    //自己的代码实现
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    [_invokeResult SetResultText:dialogView.data];
    //_invokeResult设置返回值
}

- (void)hideKeyboard:(NSArray *)parms {
    if (dialogView != nil) {
        [[UIApplication sharedApplication].keyWindow endEditing:YES];
    }
}

//异步
- (void)open:(NSArray *)parms
{
    //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    openScritEngine = _scritEngine;
    openCallbackName = [parms objectAtIndex:2];
    
    NSString *pagePath = [doJsonHelper GetOneText: _dictParas: @"path" :nil];
    
    NSString *inputData = [doJsonHelper GetOneText: _dictParas: @"data" :@""];
    BOOL supportClickClose = [doJsonHelper GetOneBoolean:_dictParas :@"supportClickClose" :YES];
    
    if (!pagePath || pagePath.length == 0) {
        @throw [NSException exceptionWithName:@"" reason:@"path 不能为空！" userInfo:nil];
    }
    //当前控制器
    UIViewController *curVC = (UIViewController *)_scritEngine.CurrentPage.PageView;
    doSourceFile * _sourceFile = [_scritEngine.CurrentApp.SourceFS GetSourceByFileName:pagePath];
    if (_sourceFile == nil)
    {
        @throw [NSException exceptionWithName:@"doDialog" reason:[NSString stringWithFormat:@"试图打开一个无效的页面文件:%@",pagePath] userInfo:nil];
    }
    id<doIPage> doPage = _scritEngine.CurrentPage;
    dialogView = [[doDialogView alloc]initWithFrame:curVC.view.bounds];
    dialogView.data = inputData;
    dialogView.supportClickClose = supportClickClose;
    dispatch_async(dispatch_get_main_queue(), ^{
        doUIContainer *uiContiainer = [[doUIContainer alloc]init:doPage];
        [uiContiainer LoadFromFile:_sourceFile :nil :nil];
        [uiContiainer LoadDefalutScriptFile:pagePath];
        doUIModule *insertViewModel = uiContiainer.RootView;
        if (!insertViewModel) {
            @throw [NSException exceptionWithName:@"doDialog" reason:@"创建view失败" userInfo:nil];
        }
        UIView *insertView = (UIView *)insertViewModel.CurrentUIModuleView;
        
        UIView *view = [[UIView alloc] initWithFrame:insertView.frame];
        [view addSubview:insertView];
        dialogView.contentView = view;
        [dialogView show:curVC];
    });
}

@end
