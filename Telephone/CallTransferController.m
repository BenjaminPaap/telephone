//
//  CallTransferController.m
//  Telephone
//
//  Copyright (c) 2008-2016 Alexey Kuznetsov
//  Copyright (c) 2016 64 Characters
//
//  Telephone is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Telephone is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

#import "CallTransferController.h"

#import "AKNSWindow+Resizing.h"
#import "AKSIPCall.h"

#import "AccountController.h"
#import "ActiveCallTransferViewController.h"
#import "CallController+Protected.h"
#import "EndedCallTransferViewController.h"


@interface CallTransferController ()

// Source call controller.
@property(nonatomic, weak) CallController *sourceCallController;

// Active account transfer view controller.
@property(nonatomic, strong) ActiveAccountTransferViewController *activeAccountTransferViewController;

// A Boolean value indicating whether the source call has been transferred.
@property(nonatomic, assign) BOOL sourceCallTransferred;

@end


@implementation CallTransferController

- (void)setSourceCallController:(CallController *)callController {
    if (_sourceCallController == callController) {
        return;
    }
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    if (_sourceCallController != nil) {
        [nc removeObserver:self
                      name:AKSIPCallTransferStatusDidChangeNotification
                    object:[_sourceCallController call]];
    }
    
    if (callController != nil) {
        [nc addObserver:self
               selector:@selector(sourceCallControllerSIPCallTransferStatusDidChange:)
                   name:AKSIPCallTransferStatusDidChangeNotification
                 object:[callController call]];
    }
    
    [self setSourceCallTransferred:NO];
    
    _sourceCallController = callController;
}

- (instancetype)initWithSourceCallController:(CallController *)callController {
    AccountController *accountController = callController.accountController;
    if ((self = [self initWithWindowNibName:@"CallTransfer"
                          accountController:accountController
                           ringtonePlayback:accountController.ringtonePlayback
                                   delegate:accountController])) {
        [self setSourceCallController:callController];
        _activeAccountTransferViewController = [[ActiveAccountTransferViewController alloc] initWithAccountController:accountController];
    }
    return self;
}

- (void)windowDidLoad {
    [self showInitialState:self];
}

- (void)transferCall {
    [[[self sourceCallController] call] attendedTransferToCall:[self call]];
}

- (IBAction)closeSheet:(id)sender {
    if ([[self sourceCallController] isCallActive] && [[self sourceCallController] isCallOnHold]) {
        [[self sourceCallController] toggleCallHold];
    }
    [NSApp endSheet:[sender window]];
    [[sender window] orderOut:sender];
}

- (IBAction)showInitialState:(id)sender {
    if ([self isCallActive]) {
        [self hangUpCall];
    }
    
    if (![[self sourceCallController] isCallActive]) {
        [self closeSheet:self];
    }
    
    [self removeViewControllersIfNeeded];
    [self showActiveAccountTransferView];
    [self makeCallDestinationFieldFirstResponder];
}

- (void)removeViewControllersIfNeeded {
    if ([self countOfViewControllers] > 0) {
        [[self viewControllers] removeAllObjects];
        [self patchResponderChain];
    }
}

- (void)showActiveAccountTransferView {
    [self setCallInfoViewResizingWindow:[[self activeAccountTransferViewController] view]];
}

- (void)makeCallDestinationFieldFirstResponder {
    if ([self.activeAccountTransferViewController.callDestinationField acceptsFirstResponder]) {
        [self.window makeFirstResponder:self.activeAccountTransferViewController.callDestinationField];
    }
}


#pragma mark -
#pragma mark CallController methods

- (CallTransferController *)callTransferController {
    return nil;
}

- (IncomingCallViewController *)incomingCallViewController {
    return nil;
}

// Substitutes ActiveCallTransferViewController.
- (ActiveCallViewController *)activeCallViewController {
    if (_activeCallViewController == nil) {
        _activeCallViewController
            = [[ActiveCallTransferViewController alloc] initWithNibName:@"ActiveCallTransferView" callController:self];
        [_activeCallViewController setRepresentedObject:[self call]];
    }
    return _activeCallViewController;
}

// Substitutes EndedCallTransferViewController.
- (EndedCallViewController *)endedCallViewController {
    if (_endedCallViewController == nil) {
        _endedCallViewController
            = [[EndedCallTransferViewController alloc] initWithNibName:@"EndedCallTransferView" callController:self];
        [_endedCallViewController setRepresentedObject:[self call]];
    }
    return _endedCallViewController;
}

- (void)acceptCall {
    // Do nothing.
}


#pragma mark -
#pragma mark AKSIPCall notifications

- (void)SIPCallCalling:(NSNotification *)notification {
    [super SIPCallCalling:notification];
    ActiveCallTransferViewController *activeCallTransferViewController
        = (ActiveCallTransferViewController *)[self activeCallViewController];
    [[activeCallTransferViewController transferButton] setEnabled:NO];
}

- (void)SIPCallEarly:(NSNotification *)notification {
    [super SIPCallEarly:notification];
    ActiveCallTransferViewController *activeCallTransferViewController
        = (ActiveCallTransferViewController *)[self activeCallViewController];
    [[activeCallTransferViewController transferButton] setEnabled:NO];
}

- (void)SIPCallDidConfirm:(NSNotification *)notification {
    [super SIPCallDidConfirm:notification];
    ActiveCallTransferViewController *activeCallTransferViewController
        = (ActiveCallTransferViewController *)[self activeCallViewController];
    [[activeCallTransferViewController transferButton] setEnabled:YES];
}

- (void)SIPCallDidDisconnect:(NSNotification *)notification {
    [super SIPCallDidDisconnect:notification];
    if ([self sourceCallTransferred]) {
        [self closeSheet:self];
    }
}

- (void)SIPCallMediaDidBecomeActive:(NSNotification *)notification {
    [super SIPCallMediaDidBecomeActive:notification];
    ActiveCallTransferViewController *activeCallTransferViewController
        = (ActiveCallTransferViewController *)[self activeCallViewController];
    [[activeCallTransferViewController transferButton] setEnabled:YES];
}

- (void)SIPCallDidRemoteHold:(NSNotification *)notification {
    [super SIPCallDidRemoteHold:notification];
    ActiveCallTransferViewController *activeCallTransferViewController
        = (ActiveCallTransferViewController *)[self activeCallViewController];
    [[activeCallTransferViewController transferButton] setEnabled:NO];
}


#pragma mark -
#pragma mark Source Call Controller's call notification

- (void)sourceCallControllerSIPCallTransferStatusDidChange:(NSNotification *)notification {
    AKSIPCall *sourceCall = [notification object];
    NSDictionary *userInfo = [notification userInfo];
    BOOL isFinal = [userInfo[@"AKFinalTransferNotification"] boolValue];
    
    if (isFinal && [sourceCall transferStatus] == PJSIP_SC_OK) {
        [self setSourceCallTransferred:YES];
        if (![self isCallActive]) {
            [self closeSheet:self];
        }
    }
}

@end
