//
//  XCFXcodeGenerate.h
//  AutoPropertyPlugin
//
//  Created by taoxian on 15/6/2.
//  Copyright (c) 2015年 taoxian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XCFConstants.h"

@class IDESourceCodeDocument;

@interface XCFXcodeGenerate : NSObject

+ (BOOL)canGenerateSelectedFiles;
+ (void)generateSelectedFilesWithEnumerationBlock:(void (^)(NSURL *url, NSError *error, BOOL *stop))enumerationBlock;

+ (BOOL)canGenerateActiveFile;
+ (void)generateActiveFileWithError:(NSError **)outError;

+ (BOOL)canGenerateSelectedLines;
+ (void)generateSelectedLinesWithError:(NSError **)outError;


@end
