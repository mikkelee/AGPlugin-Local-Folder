//
//  LFPlugin.m
//  Local Folder
//
//  Created by Mikkel Eide Eriksen on 20/01/12.
//  Copyright (c) 2012 Mikkel Eide Eriksen. All rights reserved.
//

#import "LFPlugin.h"

#define LFLocalizedString(key, comment) NSLocalizedStringFromTableInBundle(key, nil, [NSBundle bundleForClass:[self class]], comment)

#define LFPluginName @"Local Folder"

@implementation LFPlugin {
    NSMutableDictionary *keyCache;
}

#pragma mark Initialization

- (id)init
{
    self = [super init];
    if (self) {
        keyCache = [NSMutableDictionary dictionaryWithCapacity:5];
    }
    
    return self;
}

#pragma mark User interface


#pragma mark AGPlugin protocol methods

+ (NSString *)pluginName
{
    return LFPluginName;
}

- (BOOL)getNewMetadataForTarget:(id<AGPluginMetadataTarget>)target
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setMessage:LFLocalizedString(@"select file", @"Please select a folder containing images")];
    [openPanel setCanChooseDirectories:YES];
    if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
        //TODO ask user for tags...?
        for (NSURL *url in [openPanel URLs]) {
            NSString *baseKey = (__bridge NSString *)CFUUIDCreateString( NULL, CFUUIDCreate( NULL ) );
            
            NSLog(@"uuid: %@", baseKey);
            
            NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithCapacity:3];
            
            [metadata setValue:[url lastPathComponent] forKey:AGMetadataNameKey];
            
            NSMutableDictionary *tags = [NSMutableDictionary dictionaryWithCapacity:4];
            [tags setObject:url forKey:@"Original path"];
            [metadata setObject:tags forKey:AGMetadataTagsKey];

            NSMutableArray *items = [NSMutableArray arrayWithCapacity:5];
            
            NSArray *propertyKeys = [NSArray arrayWithObjects:NSURLNameKey, NSURLLocalizedNameKey, NSURLAttributeModificationDateKey, NSURLTypeIdentifierKey, nil];
            
            NSArray *supportedTypes = [NSImage imageTypes];
            
            NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:url 
                                                           includingPropertiesForKeys:propertyKeys 
                                                                              options:NSDirectoryEnumerationSkipsHiddenFiles 
                                                                                error:nil];
            for (id file in files) {
                NSDictionary *properties = [file resourceValuesForKeys:propertyKeys error:nil];
                
                if (![supportedTypes containsObject:[properties valueForKey:NSURLTypeIdentifierKey]]) {
                    continue;
                }
                
                //NSLog(@"file: %@ %@ %@", [file className], file, properties);
                
                NSString *shortKey = [NSString stringWithFormat:@"%@/%@", baseKey, [properties valueForKey:NSURLLocalizedNameKey]];
                
                [keyCache setObject:file forKey:shortKey];
                NSMutableDictionary *item = [NSMutableDictionary dictionaryWithCapacity:3];
                
                [item setObject:[properties valueForKey:NSURLLocalizedNameKey] forKey:AGMetadataImageNameKey];
                [item setObject:shortKey forKey:AGMetadataImageKeyKey];
                
                NSMutableDictionary *tags = [NSMutableDictionary dictionaryWithCapacity:4];
                [tags setObject:[properties valueForKey:NSURLAttributeModificationDateKey] forKey:@"Last modified"];
                [tags setObject:[properties valueForKey:NSURLTypeIdentifierKey] forKey:@"Uniform Type Identifier"];
                [item setObject:tags forKey:AGMetadataImageTagsKey];
                
                [items addObject:item];
            }
            
            [metadata setObject:items forKey:AGMetadataItemsKey];
            
            [target pluginNamed:LFPluginName didLoadMetadata:metadata];
        }
        return YES;
    } else {
        return NO;    
    }
}

- (BOOL)loadImageForKey:(NSString *)key target:(id<AGPluginImageLoadTarget>)target
{
    NSURL *imageURL = [keyCache objectForKey:key];
    
    if ([imageURL checkResourceIsReachableAndReturnError:nil]) {
        NSData *imgData = [[NSData alloc] initWithContentsOfURL:imageURL];
        [target imageDataDidLoad:imgData];
    }    
    
    [keyCache removeObjectForKey:key];
    
    return YES;
}

- (BOOL)imageIsLoadingForKey:(NSString *)key
{
    return NO;
}

@end
