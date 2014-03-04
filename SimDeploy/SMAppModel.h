//
//  SMAppModel.h
//  SimDeploy
//
//  Created by Jerry Jones on 12/31/11.
//  Copyright (c) 2011 Spaceman Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMAppModel : NSObject

@property (nonatomic, assign) BOOL deleteGUIDWhenFinished;

@property (nonatomic, retain) NSString *guidPath;
@property (nonatomic, retain) NSString *executablePath;
@property (nonatomic, retain) NSString *executableName;
@property (nonatomic, retain) NSDictionary *infoDictionary;
@property (nonatomic, retain) NSString *apkPath;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *launchIdentifier;
@property (nonatomic, retain) NSString *version;
@property (nonatomic, retain) NSString *marketingVersion;
@property (nonatomic, retain) NSString *iconPath;
@property (nonatomic, assign) BOOL iconIsPreRendered;

- (id)initWithPath:(NSString *)path;
- (NSString *)dumpApk:(NSString *)path;
- (NSString *)extractApk:(NSString *)path;

@end
