//
//  SMSimDeploy.h
//  SimDeploy
//
//  Created by Jerry Jones on 12/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMAppModel.h"
#import "SMSimulatorModel.h"

@interface SMSimDeployer : NSObject <NSURLDownloadDelegate>
{
	void (^downloadCompletionBlock)(BOOL);
	BOOL downloading;
	NSString *tempFile;
}

@property (nonatomic, retain) SMAppModel *downloadedApplication;
@property (nonatomic, retain) NSArray *simulators;

+ (SMSimDeployer *)defaultDeployer;


- (void)cleanup;
- (void)resetTempArchivePath;
- (void)launchiOSSimulator;
- (void)killiOSSimulator;
- (void)restartiOSSimulator;

//- (void)deleteApplicationWithBundleIdentifier:(NSString *)bundleIdentifier;



- (void)downloadAppAtURL:(NSURL *)url completion:(void(^)(BOOL failed))completion;
- (BOOL)unzipAppArchive;

@end