//
//  SMSimDeploy.m
//  SimDeploy
//
//  Created by Jerry Jones on 12/29/11.
//  Copyright (c) 2011 Spaceman Labs. All rights reserved.
//

#import "SMSimDeployer.h"
#import "ZipArchive/ZipArchive.h"
#include <sys/types.h>
#include <sys/stat.h>
#import <ScriptingBridge/ScriptingBridge.h>

/* App bundle ID. Used to request that the simulator be brought to the foreground */
#define SIM_APP_BUNDLE_ID @"com.apple.iphonesimulator"

/* Load a class from the runtime-loaded iPhoneSimulatorRemoteClient framework */
#define C(name) NSClassFromString(@"" #name)

static NSString * const simulatorPrefrencesName = @"com.apple.iphonesimulator";
static NSString * const deviceProperty = @"SimulateDevice";
static NSString * const deviceIphoneRetina3_5Inch = @"iPhone Retina (3.5-inch)";
static NSString * const deviceIphoneRetina4_0Inch = @"iPhone Retina (4-inch)";
static NSString * const deviceIphone = @"iPhone";
static NSString * const deviceIpad = @"iPad";
static NSString * const deviceIpadRetina = @"iPad (Retina)";

@implementation SMSimDeployer

@synthesize download;
@synthesize simulators;
@synthesize downloadResponse;
@synthesize sdkRoot;

+ (SMSimDeployer *)defaultDeployer {
	static dispatch_once_t pred;
	static SMSimDeployer *shared = nil;
	
	dispatch_once(&pred, ^{
		shared = [[SMSimDeployer alloc] init];
	});
	
	return shared;
}

#pragma mark - Simulator

- (id)init
{
	self = [super init];
	if (nil == self) {
		return nil;
	}
	

	NSArray *roots = [DTiPhoneSimulatorSystemRoot knownRoots];
	for (DTiPhoneSimulatorSystemRoot *root in roots) {
		if (nil == sdkRoot) {
			self.sdkRoot = root;
			continue;
		}
		
		NSString *oldVersion = [sdkRoot sdkVersion];
		NSString *newVersion = [root sdkVersion];
		BOOL newer = ([newVersion compare:oldVersion options:NSNumericSearch] != NSOrderedAscending);
		
		if (newer) {
			self.sdkRoot = root;
		}		
	}

	
	return self;
}

- (void)changeDeviceType:(NSString *)family retina:(BOOL)retina isTallDevice:(BOOL)isTallDevice {
    NSString *devicePropertyValue;
    if (retina) {
        if ([family isEqualToString:@"ipad"]) {
            devicePropertyValue = deviceIpadRetina;
        }
        else {
            if (isTallDevice) {
                devicePropertyValue = deviceIphoneRetina4_0Inch;
            } else {
                devicePropertyValue = deviceIphoneRetina3_5Inch;
            }
        }
    } else {
        if ([family isEqualToString:@"ipad"]) {
            devicePropertyValue = deviceIpad;
        } else {
            devicePropertyValue = deviceIphone;
        }
    }
    CFPreferencesSetAppValue((__bridge CFStringRef)deviceProperty, (__bridge CFPropertyListRef)devicePropertyValue, (__bridge CFStringRef)simulatorPrefrencesName);
    CFPreferencesAppSynchronize((__bridge CFStringRef)simulatorPrefrencesName);
}

- (void)launchiOSSimulator
{
	[[NSWorkspace sharedWorkspace] launchApplication:@"iPhone Simulator.app"];
}

- (void)killiOSSimulator
{
//	system("killall \"iPhone Simulator\"");
	NSArray *runningSims = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.iphonesimulator"];
	for (NSRunningApplication *app in runningSims) {
		[app terminate];
	}
}

- (void)restartiOSSimulator
{
	[self killiOSSimulator];
	double delayInSeconds = 2.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self launchiOSSimulator];
	});

}


- (void)launchApplication:(SMAppModel *)app retina:(BOOL)retina tall:(BOOL)tall deviceType:(NSString *)dType
{
	if (nil == app) {
		return;
	}
	
	[self killiOSSimulator];
	
	if (nil != session) {
//		[session requestEndWithTimeout:0];
		session = nil;
	}
	
	double delayInSeconds = 0.1;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		DTiPhoneSimulatorApplicationSpecifier *appSpec;
		DTiPhoneSimulatorSessionConfig *config;
		NSError *error;
		
		/* Create the app specifier */
		NSString *path = app.mainBundle.bundlePath;
		appSpec = [DTiPhoneSimulatorApplicationSpecifier specifierWithApplicationPath:path];
		if (appSpec == nil) {
			NSLog(@"Could not load application specification for %@", app.mainBundle.bundlePath);
			return;
		}
		
		/* Set up the session configuration */
		config = [[DTiPhoneSimulatorSessionConfig alloc] init];
		[config setApplicationToSimulateOnStart: appSpec];
		[config setSimulatedSystemRoot: sdkRoot];
		[config setSimulatedApplicationShouldWaitForDebugger: NO];
		
		[config setSimulatedApplicationLaunchArgs:@[]];
		[config setSimulatedApplicationLaunchEnvironment:[[NSProcessInfo processInfo] environment]];
		
		[config setLocalizedClientName:@"Sim Deploy"];
		
        [config setSimulatedDeviceFamily:([dType isEqualToString:@"iphone"]) ? @1 : @2];
        
        [self changeDeviceType:dType retina:retina isTallDevice:tall];
		
		/* Start the session */
		session = [[DTiPhoneSimulatorSession alloc] init];
		[session setDelegate: self];
		[session setSimulatedApplicationPID: @35];
		//	if (uuid!=nil)
		//	{
		//		[session setUuid:uuid];
		//	}
		
		if (![session requestStartWithConfig:config timeout:35 error:&error]) {
			NSLog(@"Could not start simulator session: %@", error);
		}
	});
}

- (void)killApp:(SMAppModel *)app
{
	NSString *command = [NSString stringWithFormat:@"killall %@", app.executablePath];
	 (void)system([command cStringUsingEncoding:NSASCIIStringEncoding]);
}

#pragma mark - Paths

- (NSString *)applicationDirectoryPath
{
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSFileManager *fm = [NSFileManager defaultManager];
	
    // Find the application support directory in the home directory.
	NSString *path = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
	
    // Append the bundle ID to the URL for the
	// Application Support directory
	path = [path stringByAppendingPathComponent:bundleID];
	
	// If the directory does not exist, this method creates it.
	// This method call works in Mac OS X 10.7 and later only.
	NSError	*theError = nil;
	[fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&theError];
	
    return path;
}

- (NSString *)tempArchivePath
{
	NSString *applicationDirectoryPath = [self applicationDirectoryPath];
	return [applicationDirectoryPath stringByAppendingPathComponent:@"temp.zip"];
}

- (void)deleteTempFile
{
	[[NSFileManager defaultManager] removeItemAtPath:tempFile error:nil];
	tempFile = nil;
}

- (void)cleanup
{
	NSString *applicationDirectoryPath = [self applicationDirectoryPath];
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:applicationDirectoryPath error:nil];
	for (NSString *path in contents) {
		NSString *fullPath = [applicationDirectoryPath stringByAppendingPathComponent:path];
		[[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
	}
}

- (NSString *)tempApplicationPath
{
	if (nil != tempFile) {
		return tempFile;
	}
	
	NSString *applicationDirectoryPath = [self applicationDirectoryPath];
	CFUUIDRef uuidObj = CFUUIDCreate(nil); //create a new UUID
	//get the string representation of the UUID
	NSString *uuidString = (NSString*)CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
	
	tempFile = [applicationDirectoryPath stringByAppendingPathComponent:uuidString];

	CFRelease(uuidObj);
	
	return tempFile;
}

//- (void)deleteApplicationWithBundleIdentifier:(NSString *)bundleIdentifier
//{
//
//	NSArray *applicationPaths = [self applicationDirectories];
//	
//	for (NSString *path in applicationPaths) {
//		NSDictionary *plist = [self infoPlistForApplicationAtPath:path];
//		if (nil == plist) {
//			continue;
//		}
//		
//		NSString *thisBundleId = [plist objectForKey:@"CFBundleIdentifier"];
//		if ([thisBundleId isEqualToString:bundleIdentifier]) {
//			[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
//			break;
//		}
//	}
//}

- (NSString *)simulatorDirectoryPath
{
	// Find the application support directory in the home directory.
	NSString *applicationSupport = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
	NSString *simulator = [applicationSupport stringByAppendingPathComponent:@"iPhone Simulator"];
	return simulator;
}

#pragma mark - Accessors

- (NSArray *)simulators
{
	if (nil != simulators) {
		return simulators;
	}
	
    NSMutableArray *sims = [NSMutableArray array];
	
	NSString *simulatorPath = [self simulatorDirectoryPath];
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:simulatorPath error:nil];
	for (NSString *path in contents) {
		NSString *fullPath = [simulatorPath stringByAppendingPathComponent:path];
		
		// Check for preferences to determine if the simulator is valid
		NSString *springboardPlistPath = [fullPath stringByAppendingPathComponent:@"Library/Preferences/com.apple.springboard.plist"];
		if (NO == [[NSFileManager defaultManager] fileExistsAtPath:springboardPlistPath isDirectory:NULL]) {
			continue;
		}

		SMSimulatorModel *sim = [[SMSimulatorModel alloc] initWithPath:fullPath];
		if (nil == sim) {
			continue;
		}
        
        [sims addObject:sim];
	}
    
    // Sort by version
    [sims sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if([obj1 isNewerThan:obj2])
            return NSOrderedAscending;
        else
            return NSOrderedDescending;
    }];
	
	self.simulators = [sims copy];
	return self.simulators;
}

#pragma mark - 



- (void)downloadAppAtURL:(NSURL *)url percentComplete:(void(^)(CGFloat percentComplete))percentComplete completion:(void(^)(BOOL failed))completion
{
	downloadCompletionBlock = [completion copy];
	
	percentCompleteBlock = [percentComplete copy];
	
	[self deleteTempFile];
	
	[[NSFileManager defaultManager] removeItemAtPath:[self tempArchivePath] error:nil];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0f];
	self.download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
	[download setDestination:[self tempArchivePath] allowOverwrite:YES];
}

- (SMAppModel *)unzipAppArchive
{
	return [self unzipAppArchiveAtPath:[self tempArchivePath]];
}

- (SMAppModel *)unzipAppArchiveAtPath:(NSString *)path
{	
//	[self resetTempArchivePath];
//	self.downloadedApplication = nil;
	
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	ZipArchive *za = [[ZipArchive alloc] init];
	NSString *tempApplicationPath = [self tempApplicationPath];
	[fm removeItemAtPath:tempApplicationPath error:&error];
	
	if ([za UnzipOpenFile:path]) {
		BOOL success = [za UnzipFileTo:tempApplicationPath overWrite:YES];
		if (NO == success) {
			NSLog(@"Invalid Zip");
			return NO;
		}
		[za UnzipCloseFile];
	} else {
		NSLog(@"Invalid Zip");
		return NO;
	}
	
	// Try to find an application bundle
	
	NSArray *contents = [fm contentsOfDirectoryAtPath:tempApplicationPath error:&error];
	for (NSString *path in contents) {
		NSString *fullPath = [tempApplicationPath stringByAppendingPathComponent:path];
		NSBundle *bundle = [NSBundle bundleWithPath:fullPath];
		
		if (nil == bundle) {
			continue;
		}
		
		SMAppModel *appModel = [[SMAppModel alloc] initWithBundle:bundle];
		if (nil != appModel) {
			[appModel setDeleteGUIDWhenFinished:YES];
			
			// Some bug causes the executable to lose it's +x permissions. Do that here.
			NSString *executable = (appModel.infoDictionary)[@"CFBundleExecutable"];
			NSString *executablePath = [appModel.mainBundle.bundlePath stringByAppendingPathComponent:executable];
						
			const char *path = [executablePath cStringUsingEncoding:NSASCIIStringEncoding];
			
			/* Get the current mode. */
			struct stat buf;
			int error = stat(path, &buf);
			/* check and handle error */
			
			/* Make the file user-executable. */
			mode_t mode = buf.st_mode;
			mode |= S_IXUSR;
			error = chmod(path, mode);
			/* check and handle error */
			
			return appModel;
		}
	}

	return NO;
}

- (void)finishedInstallingApplication
{	
	if (installQueue.operationCount > 0) {
//		NSLog(@"too many pending: %li", installQueue.operationCount);
		return;
	}
	
	installQueue = nil;
	
	if (nil != installCompletion) {
		dispatch_async(dispatch_get_main_queue(), installCompletion);
		installCompletion = nil;
	}
	
	
}

- (void)installApplication:(SMAppModel *)app clean:(BOOL)clean completion:(void(^)(void))completion
{
	if (nil != installQueue) {
		return;
	}
		
	installQueue = [[NSOperationQueue alloc] init];
	[installQueue setName:@"com.spacemanlabs.simdeploy.install"];
	
	installCompletion = [completion copy];
	
	for (SMSimulatorModel *sim in self.simulators) {
		[installQueue addOperationWithBlock:^{
			[sim installApplication:app upgradeIfPossible:!clean];
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				[self finishedInstallingApplication];
			}];
		}];
	}
}

#pragma mark - NSURLDownloadDelegate

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
    // Reset the progress, this might be called multiple times.
    // bytesReceived is an instance variable defined elsewhere.
    bytesReceived = 0;
	
    // Retain the response to use later.
	self.downloadResponse = nil;
    [self setDownloadResponse:response];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
	long long expectedLength = [[self downloadResponse] expectedContentLength];
	
    bytesReceived = bytesReceived + length;
	
    if (expectedLength != NSURLResponseUnknownLength) {
        // If the expected content length is
        // available, display percent complete.
        CGFloat percentComplete = (bytesReceived/(CGFloat)expectedLength)*100.0;
		
		if (nil != percentCompleteBlock) {
			percentCompleteBlock(percentComplete);
		}
    } else {
        // If the expected content length is
        // unknown, just log the progress.
		if (nil != percentCompleteBlock) {
			percentCompleteBlock(-1.0f);
		}
//        NSLog(@"Bytes received - %i",bytesReceived);
    }	
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
	if (nil != downloadCompletionBlock) {
		downloadCompletionBlock(NO);
	}
	
	downloadCompletionBlock = nil;
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	if (nil != downloadCompletionBlock) {
		downloadCompletionBlock(YES);
	}
	
	downloadCompletionBlock = nil;
}

#pragma mark - Simulator

// from DTiPhoneSimulatorSessionDelegate protocol
- (void) session: (DTiPhoneSimulatorSession *) aSession didEndWithError: (NSError *) error {
    // Do we care about this?
    NSLog(@"Did end with error: %@", error);
	session = nil;
}

// from DTiPhoneSimulatorSessionDelegate protocol
- (void) session: (DTiPhoneSimulatorSession *)aSession didStart: (BOOL) started withError: (NSError *) error {
    if(!started){
        NSLog(@"Error starting simulator: %@", error);
        session = nil;
    }
}


@end
