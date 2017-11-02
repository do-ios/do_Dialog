//
//  do_Dialog_App.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Dialog_App.h"
static do_Dialog_App* instance;
@implementation do_Dialog_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_Dialog_App alloc]init];
    return instance;
}
@end
