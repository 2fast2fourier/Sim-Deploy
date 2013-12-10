//
//  SMViewController.h
//  SimDeploy
//
//  Created by Jerry Jones on 1/2/12.
//  Copyright (c) 2012 Spaceman Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SMSimDeployer.h"
#import "SMFileDragView.h"
#import "SMIconView.h"
#import "SMAppInstallView.h"
#import "KGNoise.h"

@interface SMViewController : NSObject <NSAlertDelegate, SMFileDragViewDelegate>
{
	NSModalSession	modalSession;
	BOOL showingProgressIndicator;
	BOOL versionsAreTheSame;
}

@property (nonatomic, retain) SMAppModel *pendingApp;
@property (nonatomic, readonly) BOOL showingAppInfoView;

@property (nonatomic, retain) IBOutlet NSWindow *mainWindow;
@property (nonatomic, retain) IBOutlet KGNoiseView *mainView;

@property (nonatomic, retain) IBOutlet NSPanel *downloadURLSheet;
@property (nonatomic, retain) IBOutlet NSTextField *urlLabel;
@property (nonatomic, retain) IBOutlet NSTextField *downloadTextField;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, retain) IBOutlet NSButton *downloadButton;

@property (nonatomic, retain) IBOutlet NSView *controlContainer;
@property (nonatomic, retain) IBOutlet NSBox *boxView;
@property (nonatomic, retain) IBOutlet NSButton *downloadFromURLButton;
@property (nonatomic, retain) IBOutlet SMFileDragView *fileDragView;
@property (nonatomic, retain) IBOutlet NSTextField *orLabel;

@property (nonatomic, retain) IBOutlet SMAppInstallView *appInfoView;
@property (nonatomic, retain) IBOutlet NSTextField *titleLabel;
@property (nonatomic, retain) IBOutlet NSTextField *versionLabel;
@property (nonatomic, retain) IBOutlet NSTextField *installedVersionLabel;
@property (nonatomic, retain) IBOutlet NSButton *cancelButton;
@property (nonatomic, retain) IBOutlet NSButton *installButton;
@property (nonatomic, retain) IBOutlet NSButton *cleanInstallButton;
@property (nonatomic, retain) IBOutlet NSPopUpButton *simSelectionPopup;
@property (nonatomic, retain) IBOutlet NSPopUpButton *deviceSelectionPopup;
@property (nonatomic, retain) IBOutlet SMIconView *iconView;

@property (nonatomic, retain) IBOutlet NSPanel *installPanel;
@property (nonatomic, retain) IBOutlet NSTextField *installTitleLabel;
@property (nonatomic, retain) IBOutlet NSTextField *installMessageLabel;
@property (nonatomic, retain) IBOutlet NSProgressIndicator *installProgressIndicator;

- (IBAction)downloadFromURL:(id)sender;
- (IBAction)cancelDownloadFromURL:(id)sender;
- (void)downloadURLAtLocation:(NSString *)location;
- (IBAction)downloadAppAtTextFieldURL:(id)sender;

- (void)setAppInfoViewShowing:(BOOL)showing;
- (void)setupAppInfoViewWithApp:(SMAppModel *)app;
- (void)checkVersionsAndInstallApp:(SMAppModel *)app;
- (IBAction)updateSelectedSim:(id)sender;
- (IBAction)installPendingApp:(id)sender;
- (void)updateInstallButton;

- (IBAction)cleanInstall:(id)sender;
- (IBAction)install:(id)sender;
- (IBAction)cancelInstall:(id)sender;
- (void)showRestartAlertIfNeeded;

- (void)registerForDragAndDrop;
- (void)deregisterForDragAndDrop;

- (void)errorWithTitle:(NSString *)title message:(NSString *)message;

@end
