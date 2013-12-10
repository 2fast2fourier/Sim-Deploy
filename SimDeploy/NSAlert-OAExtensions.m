// Copyright 1997-2009 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "NSAlert-OAExtensions.h"


@implementation NSAlert (OAExtensions)

+ (void)beginAlertSheet:(NSString *)title message:(NSString *)message defaultButton:(NSString *)defaultButton alternateButton:(NSString *)alternate otherButton:(NSString *)other window:(NSWindow *)window completion:(OAAlertSheetCompletionHandler)completion
{
	NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:title];
	[alert setInformativeText:message];
	    
    if (defaultButton)
        [alert addButtonWithTitle:defaultButton];
    if (alternate)
        [alert addButtonWithTitle:alternate];
    if (other)
        [alert addButtonWithTitle:other];
    
    [alert beginSheetModalForWindow:window completionHandler:completion];
    [alert release]; // retained by the runner while the sheet is up

}

@end

void OABeginAlertSheet(NSString *title, NSString *defaultButton, NSString *alternateButton, NSString *otherButton, NSWindow *docWindow, OAAlertSheetCompletionHandler completionHandler, NSString *msgFormat, ...)
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:title];
    
    if (msgFormat) {
        va_list args;
        va_start(args, msgFormat);
        NSString *informationalText = [[NSString alloc] initWithFormat:msgFormat arguments:args];
        va_end(args);
        
        [alert setInformativeText:informationalText];
        [informationalText release];
    }
    
    if (defaultButton)
        [alert addButtonWithTitle:defaultButton];
    if (alternateButton)
        [alert addButtonWithTitle:alternateButton];
    if (otherButton)
        [alert addButtonWithTitle:otherButton];
    
    [alert beginSheetModalForWindow:docWindow completionHandler:completionHandler];
    [alert release]; // retained by the runner while the sheet is up
}

