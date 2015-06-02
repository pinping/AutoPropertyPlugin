//
//  AutoPropertyPlugin.h
//  AutoPropertyPlugin
//
//  Created by taoxian on 15/6/1.
//  Copyright (c) 2015年 taoxian. All rights reserved.
//

#import <AppKit/AppKit.h>

@class AutoPropertyPlugin;

static AutoPropertyPlugin *sharedPlugin;

@interface AutoPropertyPlugin : NSObject

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end