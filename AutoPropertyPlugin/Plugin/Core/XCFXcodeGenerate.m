//
//  XCFXcodeGenerate.m
//  AutoPropertyPlugin
//
//  Created by taoxian on 15/6/2.
//  Copyright (c) 2015年 taoxian. All rights reserved.
//

#import "XCFXcodeGenerate.h"
#import "XCFXcodePrivate.h"
#import "XCFDefaults.h"
#import "BBLogging.h"


#import "XCFClangFormatter.h"
#import "XCFUncrustifyFormatter.h"
#import "XCFFormatterUtilities.h"


NSString *XCFStringByTrimmingTrailingCharactersFromString(NSString *string, NSCharacterSet *characterSet)
{
    NSRange rangeOfLastWantedCharacter = [string rangeOfCharacterFromSet:[characterSet invertedSet] options:NSBackwardsSearch];
    
    if (rangeOfLastWantedCharacter.location == NSNotFound) {
        return @"";
    }
    return [string substringToIndex:rangeOfLastWantedCharacter.location + 1];
}


@implementation XCFXcodeGenerate


#pragma mark - Selected Files
+ (BOOL)canGenerateSelectedFiles;
{
    NSArray *selectedFiles = [XCFXcodeGenerate selectedSourceCodeFileNavigableItems];
    return (selectedFiles.count > 0);
}
+ (void)generateSelectedFilesWithEnumerationBlock:(void (^)(NSURL *url, NSError *error, BOOL *stop))enumerationBlock
{
    NSArray *fileNavigableItems = [XCFXcodeGenerate selectedSourceCodeFileNavigableItems];
    IDEWorkspace *currentWorkspace = [XCFXcodeGenerate currentWorkspaceDocument].workspace;

//    for (IDEFileNavigableItem *fileNavigableItem in fileNavigableItems) {
//        NSError *error = nil;
//        NSDocument *document = [IDEDocumentController retainedEditorDocumentForNavigableItem:fileNavigableItem error:nil];
//        
//        if ([document isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
//            IDESourceCodeDocument *sourceCodeDocument = (IDESourceCodeDocument *)document;
////            [XCFXcodeFormatter formatCodeOfDocument:sourceCodeDocument inWorkspace:currentWorkspace error:&error];
//            // [document saveDocument:nil];
//            
//            DDLogVerbose(@"sourceCodeDocument %@",sourceCodeDocument);
//            DDLogVerbose(@"currentWorkspace %@",currentWorkspace);
//        }
//        [IDEDocumentController releaseEditorDocument:document];
//        
//        BOOL __block stop = NO;
//        
//        if (enumerationBlock) {
//            enumerationBlock(document.fileURL, error, &stop);
//        }
//        if (stop) {
//            break;
//        }
//    }
}

#pragma mark - Active File
+ (BOOL)canGenerateActiveFile
{
    IDESourceCodeDocument *document = [XCFXcodeGenerate currentSourceCodeDocument];
    return (document != nil);
}
+ (void)generateActiveFileWithError:(NSError **)outError
{
    IDESourceCodeDocument *document = [XCFXcodeGenerate currentSourceCodeDocument];
    if (!document) {
        return;
    }
//    [[self class] formatDocument:document withError:outError];
}

#pragma mark - Selected Lines
+ (BOOL)canGenerateSelectedLines
{
    BOOL validated = NO;
    IDESourceCodeDocument *document = [XCFXcodeGenerate currentSourceCodeDocument];
    NSTextView *textView = [XCFXcodeGenerate currentSourceCodeTextView];
    
    if (document && textView) {
        NSArray *selectedRanges = [textView selectedRanges];
        validated = (selectedRanges.count > 0);
    }
    return validated;
}
+ (void)generateSelectedLinesWithError:(NSError **)outError
{
    IDESourceCodeDocument *document = [XCFXcodeGenerate currentSourceCodeDocument];
    NSTextView *textView = [XCFXcodeGenerate currentSourceCodeTextView];
    if (!document || !textView) {
        return;
    }
    IDEWorkspace *currentWorkspace = [XCFXcodeGenerate currentWorkspaceDocument].workspace;
    NSArray *selectedRanges = [textView selectedRanges];
    
    [XCFXcodeGenerate formatCodeAtRanges:selectedRanges document:document inWorkspace:currentWorkspace error:outError];
}


#pragma mark - Helpers
+ (id)currentEditor
{
    NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController *workspaceController = (IDEWorkspaceWindowController *)currentWindowController;
        IDEEditorArea *editorArea = [workspaceController editorArea];
        IDEEditorContext *editorContext = [editorArea lastActiveEditorContext];
        
        return [editorContext editor];
    }
    return nil;
}

+ (IDEWorkspaceDocument *)currentWorkspaceDocument
{
    NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];
    id document = [currentWindowController document];
    
    if (currentWindowController && [document isKindOfClass:NSClassFromString(@"IDEWorkspaceDocument")]) {
        return (IDEWorkspaceDocument *)document;
    }
    return nil;
}

+ (IDESourceCodeDocument *)currentSourceCodeDocument
{
    if ([[XCFXcodeGenerate currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        IDESourceCodeEditor *editor = [XCFXcodeGenerate currentEditor];
        return editor.sourceCodeDocument;
    }
    if ([[XCFXcodeGenerate currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        IDESourceCodeComparisonEditor *editor = [XCFXcodeGenerate currentEditor];
        DDLogVerbose(@"editor %@",[editor.keyTextView.textStorage string]);
        if ([[editor primaryDocument] isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
            IDESourceCodeDocument *document = (IDESourceCodeDocument *)editor.primaryDocument;
            return document;
        }
    }
    return nil;
}


#pragma mark Formatting

+ (CFOFormatter *)formatterForString:(NSString *)inputString presentedURL:(NSURL *)presentedURL error:(NSError **)outError
{
    NSString *selectedFormatter = [[NSUserDefaults standardUserDefaults] stringForKey:XCFDefaultsKeySelectedFormatter];
    
    if ([selectedFormatter isEqualToString:XCFDefaultsFormatterValueClang]) {
        XCFClangFormatter *formatter = [[XCFClangFormatter alloc] initWithInputString:inputString presentedURL:presentedURL];
        formatter.style = [[NSUserDefaults standardUserDefaults] stringForKey:XCFDefaultsKeyClangStyle];
        
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:XCFDefaultsKeyClangStyle] isEqualToString:CFOClangStyleFile]) {
            NSURL *configurationFileURL = [XCFClangFormatter configurationFileURLForPresentedURL:presentedURL];
            DDLogVerbose(@"Formatting using Clang Format at path “%@“ with configuration at path “%@“", [[formatter class] resolvedExecutableURLWithError:nil].path, configurationFileURL.path);
        }
        else {
            DDLogVerbose(@"Formatting using Clang Format at path “%@“ with style “%@“", [[formatter class] resolvedExecutableURLWithError:nil].path, formatter.style);
        }
        
        return formatter;
    }
    else if ([selectedFormatter isEqualToString:XCFDefaultsFormatterValueUncrustify]) {
        XCFUncrustifyFormatter *formatter = [[XCFUncrustifyFormatter alloc] initWithInputString:inputString presentedURL:presentedURL];
        formatter.configurationFileURL = [XCFUncrustifyFormatter configurationFileURLForPresentedURL:presentedURL];
        
        if (!formatter.configurationFileURL) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"No configuration file was found for Uncrustify. To create a configuration file, open the Preferences."};
            NSError *error = [NSError errorWithDomain:XCFErrorDomain code:XCFFormatterMissingConfigurationError userInfo:userInfo];
            
            if (outError) {
                *outError = error;
            }
            return nil;
        }
        DDLogVerbose(@"Formatting using Uncrustify at path “%@“ with configuration file at path “%@“", [[formatter class] resolvedExecutableURLWithError:nil].path, formatter.configurationFileURL.path);
        return formatter;
    }
    else {
        NSAssert(NO, @"Missing case");
    }
    return nil;
}

+ (BOOL)formatCodeOfDocument:(IDESourceCodeDocument *)document inWorkspace:(IDEWorkspace *)workspace error:(NSError **)outError
{
    NSError *error = nil;
    
    DVTSourceTextStorage *textStorage = [document textStorage];
    
    NSString *originalString = [NSString stringWithString:textStorage.string];
    
    if (textStorage.string.length > 0) {
        CFOFormatter *formatter = [[self class] formatterForString:textStorage.string presentedURL:document.fileURL error:&error];
        NSString *formattedCode = [formatter stringByFormattingInputWithError:&error];
        
        if (formattedCode) {
            [textStorage beginEditing];
            
            if (![formattedCode isEqualToString:textStorage.string]) {
                [textStorage replaceCharactersInRange:NSMakeRange(0, textStorage.string.length) withString:formattedCode withUndoManager:[document undoManager]];
            }
//            [XCFXcodeGenerate normalizeCodeAtRange:NSMakeRange(0, textStorage.string.length) document:document];
            [textStorage endEditing];
        }
    }
    
    if (error && outError) {
        *outError = error;
    }
    
    BOOL codeHasChanged = (originalString && ![originalString isEqualToString:textStorage.string]);
    return codeHasChanged;
}

+ (BOOL)formatCodeAtRanges:(NSArray *)ranges document:(IDESourceCodeDocument *)document inWorkspace:(IDEWorkspace *)workspace error:(NSError **)outError
{
    DVTSourceTextStorage *textStorage = [document textStorage];
    
    NSError *error = nil;
//    CFOFormatter *formatter = [[self class] formatterForString:textStorage.string presentedURL:document.fileURL error:&error];
//    NSArray *fragments = [formatter fragmentsByFormattingInputAtRanges:ranges error:&error];
//
    NSString *originalString = [NSString stringWithString:textStorage.string];
    
    for (NSValue *inputRangeValue in ranges) {
        NSRange range = [inputRangeValue rangeValue];
        NSString *substring = [originalString substringWithRange:range];
        
        DDLogVerbose(@"inputRangeValue %@",NSStringFromRange(range));
        DDLogVerbose(@"substring %@",substring);
    }
    
    BOOL codeHasChanged = (![originalString isEqualToString:textStorage.string]);
    return codeHasChanged;
}




+ (NSTextView *)currentSourceCodeTextView
{
    if ([[XCFXcodeGenerate currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        IDESourceCodeEditor *editor = [XCFXcodeGenerate currentEditor];
        return editor.textView;
    }
    
    if ([[XCFXcodeGenerate currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        IDESourceCodeComparisonEditor *editor = [XCFXcodeGenerate currentEditor];
        return editor.keyTextView;
    }
    
    return nil;
}

+ (NSArray *)selectedSourceCodeFileNavigableItems
{
    NSMutableArray *mutableArray = [NSMutableArray array];
    id currentWindowController = [[NSApp keyWindow] windowController];
    
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController *workspaceController = currentWindowController;
        IDEWorkspaceTabController *workspaceTabController = [workspaceController activeWorkspaceTabController];
        IDENavigatorArea *navigatorArea = [workspaceTabController navigatorArea];
        id currentNavigator = [navigatorArea currentNavigator];
        
        if ([currentNavigator isKindOfClass:NSClassFromString(@"IDEStructureNavigator")]) {
            IDEStructureNavigator *structureNavigator = currentNavigator;
            
            for (id selectedObject in structureNavigator.selectedObjects) {
                NSArray *arrayOfFiles = [self recursivlyCollectFileNavigableItemsFrom:selectedObject];
                
                if (arrayOfFiles.count) {
                    [mutableArray addObjectsFromArray:arrayOfFiles];
                }
            }
        }
    }
    
    if (mutableArray.count) {
        return [NSArray arrayWithArray:mutableArray];
    }
    return nil;
}

+ (NSArray *)recursivlyCollectFileNavigableItemsFrom:(IDENavigableItem *)selectedObject
{
    id items = nil;
    
    if ([selectedObject isKindOfClass:NSClassFromString(@"IDEGroupNavigableItem")]) {
        // || [selectedObject isKindOfClass:NSClassFromString(@"IDEContainerFileReferenceNavigableItem")]) { //disallow project
        NSMutableArray *mItems = [NSMutableArray array];
        IDEGroupNavigableItem *groupNavigableItem = (IDEGroupNavigableItem *)selectedObject;
        
        for (IDENavigableItem *child in groupNavigableItem.childItems) {
            NSArray *childItems = [self recursivlyCollectFileNavigableItemsFrom:child];
            
            if (childItems.count) {
                [mItems addObjectsFromArray:childItems];
            }
        }
        
        items = mItems;
    }
    else if ([selectedObject isKindOfClass:NSClassFromString(@"IDEFileNavigableItem")]) {
        IDEFileNavigableItem *fileNavigableItem = (IDEFileNavigableItem *)selectedObject;
        NSString *uti = fileNavigableItem.documentType.identifier;
        
        if ([[NSWorkspace sharedWorkspace] type:uti conformsToType:(NSString *)kUTTypeSourceCode]) {
            items = @[fileNavigableItem];
        }
    }
    
    return items;
}




@end
