//
//  SMSimApplication.m
//  SimDeploy
//
//  Created by Jerry Jones on 12/31/11.
//  Copyright (c) 2011 Spaceman Labs. All rights reserved.
//

#import "SMAppModel.h"
#import "ZipArchive/ZipArchive.h"

@implementation SMAppModel

@synthesize deleteGUIDWhenFinished, guidPath, apkPath, infoDictionary, name, identifier, version, marketingVersion, iconPath, iconIsPreRendered;
@synthesize executableName;
@dynamic executablePath;

- (id)initWithPath:(NSString *)path;
{
	if (nil == path) {
		return nil;
	}
	
	self = [super init];
	if (nil == self) {
		return nil;
	}
	
    self.apkPath = path;
	self.infoDictionary = [NSDictionary alloc];
    
	NSString* apkInfo = [self dumpApk:path];
    NSLog(apkInfo);
    
    NSRegularExpression *nameRegex = [NSRegularExpression regularExpressionWithPattern:@"application-label:'([^']+)'" options:0 error:nil];
    NSTextCheckingResult *nameDump = [nameRegex firstMatchInString:apkInfo options:0 range:NSMakeRange(0, [apkInfo length])];
    if(nameDump){
        self.name = [apkInfo substringWithRange:[nameDump rangeAtIndex:1]];
    }else{
        self.name = [[path lastPathComponent] stringByDeletingPathExtension];
    }
    
    NSRegularExpression *vercodeRegex = [NSRegularExpression regularExpressionWithPattern:@"versionCode='([^']+)'" options:0 error:nil];
    NSTextCheckingResult *versionCodeDump = [vercodeRegex firstMatchInString:apkInfo options:0 range:NSMakeRange(0, [apkInfo length])];
    if(versionCodeDump){
        self.version = [apkInfo substringWithRange:[versionCodeDump rangeAtIndex:1]];
    }else{
        self.version = @"Unknown";
    }
    
    NSRegularExpression *vernameRegex = [NSRegularExpression regularExpressionWithPattern:@"versionName='([^']+)'" options:0 error:nil];
    NSTextCheckingResult *versionNameDump = [vernameRegex firstMatchInString:apkInfo options:0 range:NSMakeRange(0, [apkInfo length])];
    if(versionNameDump){
        self.marketingVersion = [apkInfo substringWithRange:[versionNameDump rangeAtIndex:1]];
    }else{
        self.marketingVersion = @"Unknown";
    }
    
    NSRegularExpression *packIDRegex = [NSRegularExpression regularExpressionWithPattern:@"package:\\s*name='([^']+)'" options:0 error:nil];
    NSTextCheckingResult *packIdDump = [packIDRegex firstMatchInString:apkInfo options:0 range:NSMakeRange(0, [apkInfo length])];
    if(packIdDump){
        self.identifier = [apkInfo substringWithRange:[packIdDump rangeAtIndex:1]];
        NSLog(self.identifier);
    }else{
        self.identifier = @"Unknown";
    }
	
	self.executableName = @"CFBundleExecutable";
	
//	self.name = infoDictionary[@"CFBundleDisplayName"];
//	self.identifier = infoDictionary[@"CFBundleIdentifier"];
//	self.version = infoDictionary[@"CFBundleVersion"];
//	self.marketingVersion = infoDictionary[@"CFBundleShortVersionString"];
//	self.executableName = infoDictionary[@"CFBundleExecutable"];
    
    
    //expand folder to extract icon
    NSString *apkArchivePath = [self extractApk:path];
    
    NSRegularExpression *iconRegex = [NSRegularExpression regularExpressionWithPattern:@"application-icon-\\d*:'([^']+)'" options:0 error:nil];
    NSTextCheckingResult *iconDump = [iconRegex firstMatchInString:apkInfo options:0 range:NSMakeRange(0, [apkInfo length])];
    if(iconDump){
        NSString *iconRes = [apkInfo substringWithRange:[iconDump rangeAtIndex:1]];
        self.iconPath = [apkArchivePath stringByAppendingPathComponent:iconRes];
        NSLog(self.iconPath);
    }else{
        self.iconPath = nil;
    }
    
    
	// Find biggest icon file
    //	NSString *biggestIconPath = nil;
    //	NSSize biggestSize = NSMakeSize(0.0f, 0.0f);
    //	for (NSString *iconName in infoDictionary[@"CFBundleIconFiles"]) {
    //
//    NSString *imgpath = @"";//[self.mainBundle.bundlePath stringByAppendingPathComponent:iconName];
//    NSImage *image = [[NSImage alloc] initWithContentsOfFile:imgpath];
//    NSSize imageSize = [image size];
//		NSString *nameWithoutExtension = [iconName stringByDeletingPathExtension];
//		if ([nameWithoutExtension hasSuffix:@"@2x"]) {
//			imageSize.width *= 2.0f;
//			imageSize.height *= 2.0f;
//		}
//		
//		if (imageSize.width > biggestSize.width || imageSize.height > biggestSize.height) {
//			biggestIconPath = path;
//			biggestSize = imageSize;
//		}
//	}
//	
//	self.iconPath = biggestIconPath;
	
	return self;
}

- (void)dealloc
{
	if (self.deleteGUIDWhenFinished) {
		[[NSFileManager defaultManager] removeItemAtPath:self.guidPath error:nil];
	}
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"{%@ %@ %@}", self.name, self.identifier, self.version];
}

- (NSString *)executablePath
{
	
	return self.apkPath;
}


- (NSString *)dumpApk:(NSString *)path {
    NSLog(@"dumping apk");
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *adbPath = [bundle pathForAuxiliaryExecutable: @"aapt"];
    NSTask *task = [[NSTask alloc] init];
    NSPipe *outputPipe = [NSPipe pipe];
    NSArray *args = [NSArray arrayWithObjects: @"dump", @"--values", @"badging", path, nil];
    NSFileHandle *outputHandle = [outputPipe fileHandleForReading];
    [task setStandardOutput: outputPipe];
    [task setLaunchPath: adbPath];
    [task setArguments: args];
    
    [task launch];
    
    NSMutableData *data = [[NSMutableData alloc] init];
    NSData *readData;
    
    while ((readData = [outputHandle availableData])
           && [readData length]) {
        [data appendData: readData];
    }
    
    NSString *outputString;
    outputString = [[NSString alloc]
                    initWithData: data
                    encoding: NSASCIIStringEncoding];
//    NSLog(outputString);
    return outputString;
}

- (NSString *)extractApk:(NSString *)path {
    
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSFileManager *fm = [NSFileManager defaultManager];
	
    // Find the application support directory in the home directory.
	NSString *appPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
	
    // Append the bundle ID to the URL for the
	// Application Support directory
	appPath = [appPath stringByAppendingPathComponent:bundleID];
	
	// If the directory does not exist, this method creates it.
	// This method call works in Mac OS X 10.7 and later only.
	NSError	*theError = nil;
	[fm createDirectoryAtPath:appPath withIntermediateDirectories:YES attributes:nil error:&theError];
    
	CFUUIDRef uuidObj = CFUUIDCreate(nil); //create a new UUID
	//get the string representation of the UUID
	NSString *uuidString = (NSString*)CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
	
	NSString *tempFile = [appPath stringByAppendingPathComponent:uuidString];
    
	CFRelease(uuidObj);
    
	NSError *error = nil;
	ZipArchive *za = [[ZipArchive alloc] init];
	NSString *tempApplicationPath = tempFile;
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
    
    NSLog(tempApplicationPath);
    return tempApplicationPath;
}

@end
