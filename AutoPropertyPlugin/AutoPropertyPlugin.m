//
//  AutoPropertyPlugin.m
//  AutoPropertyPlugin
//
//  Created by taoxian on 15/6/1.
//  Copyright (c) 2015年 taoxian. All rights reserved.
//

#import "AutoPropertyPlugin.h"
#import "XCFLoggingUtilities.h"
#import "XCFXcodeGenerate.h"

@interface AutoPropertyPlugin()

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, strong, readwrite) NSString *url;

@end

@implementation AutoPropertyPlugin

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource access
        [XCFLoggingUtilities setUpLogger];
        
        self.bundle = plugin;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
        
        DDLogVerbose(@"AutoPropertyPlugin Version %@ loaded", [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"]);
    }
    return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
    //removeObserver
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
    NSMenuItem *editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
    
    if (editMenuItem) {
        [[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];
        
        NSMenu *formatCodeMenu = [[NSMenu alloc] initWithTitle:@"自动生成属性"];
        
        NSMenuItem *menuItem;
        menuItem = [[NSMenuItem alloc] initWithTitle:@"生成选择文件" action:@selector(formatSelectedFiles:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [formatCodeMenu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"生成当前文件" action:@selector(formatActiveFile:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [formatCodeMenu addItem:menuItem];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"生成选择代码" action:@selector(formatSelectedLines:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [formatCodeMenu addItem:menuItem];
        
        [formatCodeMenu addItem:[NSMenuItem separatorItem]];
        
        menuItem = [[NSMenuItem alloc] initWithTitle:@"打开日志" action:@selector(viewLog:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [formatCodeMenu addItem:menuItem];
        
        NSMenuItem *formatCodeMenuItem = [[NSMenuItem alloc] initWithTitle:@"自动生成属性" action:nil keyEquivalent:@""];
        [formatCodeMenuItem setSubmenu:formatCodeMenu];
        [[editMenuItem submenu] addItem:formatCodeMenuItem];
            
        
    }
}

// Sample Action, for menu item:
- (void)doMenuAction
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Hello, World"];
    [alert runModal];
    
    [[NSWorkspace sharedWorkspace] selectFile:self.url inFileViewerRootedAtPath:nil];
}



#pragma mark - Actions
- (IBAction)formatSelectedFiles:(id)sender
{
    // should be improved to show all generated errors and not only the last one
//    __block NSError *lastError = nil;
//    [XCFXcodeFormatter formatSelectedFilesWithEnumerationBlock:^(NSURL *url, NSError *error, BOOL *stop) {
//        if (error) {
//            DDLogError(@"%@", error);
//            lastError = error;
//        }
//    }];
//    
//    if (lastError) {
//        [self presentFormattingError:lastError];
//    }
}

- (IBAction)formatActiveFile:(id)sender
{
    NSError *error = nil;
    [XCFXcodeGenerate generateActiveFileWithError:&error];
    
    if (error) {
        DDLogError(@"%@", error);
    }
}

- (IBAction)formatSelectedLines:(id)sender
{
    NSError *error = nil;
    [XCFXcodeGenerate generateSelectedLinesWithError:&error];
    if (error) {
        DDLogError(@"%@", error);
    }
}



- (IBAction)viewLog:(id)sender
{
    NSURL *logFileURL = [XCFLoggingUtilities mostRecentLogFileURL];
    
    if (logFileURL) {
        [[NSWorkspace sharedWorkspace] openURL:logFileURL];
    }
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
