//
//  NSObject_Extension.m
//  AutoPropertyPlugin
//
//  Created by taoxian on 15/6/1.
//  Copyright (c) 2015年 taoxian. All rights reserved.
//


#import "NSObject_Extension.h"
#import "AutoPropertyPlugin.h"

@implementation NSObject (Xcode_Plugin_Template_Extension)

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[AutoPropertyPlugin alloc] initWithBundle:plugin];
        });
    }
}
@end
