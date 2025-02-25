//
//  AuthenticationFailureController.m
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

#import "AuthenticationFailureController.h"

#import "AKSIPUserAgent.h"
#import "AKKeychain.h"

#import "AccountController.h"
#import "AppController.h"


NSString * const AKAuthenticationFailureControllerDidChangeUsernameAndPasswordNotification
    = @"AKAuthenticationFailureControllerDidChangeUsernameAndPassword";

@implementation AuthenticationFailureController

- (instancetype)initWithAccountController:(AccountController *)anAccountController {
    self = [super initWithWindowNibName:@"AuthenticationFailure"];
    if (self != nil) {
        [self setAccountController:anAccountController];
    }
    
    return self;
}

- (instancetype)init {
    return [self initWithAccountController:nil];
}

- (void)awakeFromNib {
    NSString *registrar = [[[self accountController] account] registrar];
    [[self  informativeText] setStringValue:
     [NSString stringWithFormat:
      NSLocalizedString(@"Telephone was unable to login to %@. Change user name or password and try again.",
                        @"Registrar authentication failed."), registrar]];
    
    NSString *username = [[[self accountController] account] username];
    NSString *serviceName = [NSString stringWithFormat:@"SIP: %@", [[[self accountController] account] registrar]];
    NSString *password = [AKKeychain passwordForServiceName:serviceName accountName:username];
    
    [[self usernameField] setStringValue:username];
    [[self passwordField] setStringValue:password];
}

- (IBAction)closeSheet:(id)sender {
    [NSApp endSheet:[sender window]];
    [[sender window] orderOut:self];
}

- (IBAction)changeUsernameAndPassword:(id)sender {
    [self closeSheet:sender];
    
    NSCharacterSet *spacesSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *username = [[[self usernameField] stringValue] stringByTrimmingCharactersInSet:spacesSet];
    
    if ([username length] > 0) {
        [[self accountController] removeAccountFromUserAgent];
        [[[self accountController] account] setUsername:username];
        
        [[self accountController] showConnectingState];
        
        // Add account to the user agent.
        [[[NSApp delegate] userAgent] addAccount:[[self accountController] account]
                                    withPassword:[[self passwordField] stringValue]];
        
        // Error connecting to registrar.
        if (![[self accountController] isAccountRegistered] &&
            [[[self accountController] account] registrationExpireTime] < 0) {
            
            [[self accountController] showUnavailableState];
            
            NSString *statusText;
            NSString *preferredLocalization = [[NSBundle mainBundle] preferredLocalizations][0];
            if ([preferredLocalization isEqualToString:@"Russian"]) {
                statusText = [[NSApp delegate] localizedStringForSIPResponseCode:
                              [[[self accountController] account] registrationStatus]];
            } else {
                statusText = [[[self accountController] account] registrationStatusText];
            }
            
            NSString *error;
            if (statusText == nil) {
                error = [NSString stringWithFormat:
                         NSLocalizedString(@"Error %d", @"Error #."),
                         [[[self accountController] account] registrationStatus]];
                error = [error stringByAppendingString:@"."];
            } else {
                error = [NSString stringWithFormat:
                         NSLocalizedString(@"The error was: \\U201C%d %@\\U201D.", @"Error description."),
                         [[[self accountController] account] registrationStatus], statusText];
            }
            
            [[self accountController] showRegistrarConnectionErrorSheetWithError:error];
        }
        
        if ([[self mustSaveCheckBox] state] == NSOnState) {
            NSString *serviceName = [NSString stringWithFormat:@"SIP: %@",
                                     [[[self accountController] account] registrar]];
            [AKKeychain addItemWithServiceName:serviceName
                                   accountName:username
                                      password:[[self passwordField] stringValue]];
        }
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:AKAuthenticationFailureControllerDidChangeUsernameAndPasswordNotification
                       object:self];
    }
    
    [[self passwordField] setStringValue:@""];
}

@end
