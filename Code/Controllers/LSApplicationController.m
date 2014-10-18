//
//  LSAppController.m
//  LayerSample
//
//  Created by Kevin Coleman on 6/30/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import "LSApplicationController.h"
#import "LSUtilities.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface LSApplicationController () <LYRClientDelegate>

@property (nonatomic) NSURL *baseURL;

@end

@implementation LSApplicationController

+ (instancetype)controllerWithBaseURL:(NSURL *)baseURL layerClient:(LYRClient *)layerClient persistenceManager:(LSPersistenceManager *)persistenceManager
{
    NSParameterAssert(baseURL);
    NSParameterAssert(layerClient);
    return [[self alloc] initWithBaseURL:baseURL layerClient:layerClient persistenceManager:persistenceManager];
}

- (id)initWithBaseURL:(NSURL *)baseURL layerClient:(LYRClient *)layerClient persistenceManager:(LSPersistenceManager *)persistenceManager
{
    self = [super init];
    if (self) {
        _layerClient = layerClient;
        _layerClient.delegate = self;
        _persistenceManager = persistenceManager;
        _APIManager = [LSAPIManager managerWithBaseURL:baseURL layerClient:layerClient];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveLayerClientWillBeginSynchronizationNotification:) name:LYRClientWillBeginSynchronizationNotification object:layerClient];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveLayerClientDidFinishSynchronizationNotification:) name:LYRClientDidFinishSynchronizationNotification object:layerClient];

    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layerClient:(LYRClient *)client didReceiveAuthenticationChallengeWithNonce:(NSString *)nonce
{
    NSLog(@"Layer Client did recieve authentication challenge with nonce: %@", nonce);
    LSUser *user = self.APIManager.authenticatedSession.user;
    if (user) {
        [self.APIManager authenticateWithEmail:user.email password:user.password nonce:nonce completion:^(NSString *identityToken, NSError *error) {
            if (identityToken) {
                [self.layerClient authenticateWithIdentityToken:identityToken completion:^(NSString *authenticatedUserID, NSError *error) {
                    if (authenticatedUserID) {
                        NSLog(@"Silent auth in response to auth challenge successfull");
                    } else {
                        LSAlertWithError(error);
                    }
                }];
            } else {
                LSAlertWithError(error);
            }
        }];
    }
}

- (void)layerClient:(LYRClient *)client didAuthenticateAsUserID:(NSString *)userID
{
    NSLog(@"Layer Client did recieve authentication nonce");
}

- (void)layerClientDidDeauthenticate:(LYRClient *)client
{
    [self.APIManager deauthenticate];
    NSLog(@"Layer Client did deauthenticate");
}

- (void)layerClient:(LYRClient *)client didFinishSynchronizationWithChanges:(NSArray *)changes
{
    NSLog(@"Layer Client did finish sychronization");
}

- (void)layerClient:(LYRClient *)client didFailSynchronizationWithError:(NSError *)error
{
    NSLog(@"Layer Client did fail synchronization with error: %@", error);
}

- (void)layerClient:(LYRClient *)client willAttemptToConnect:(NSUInteger)attemptNumber afterDelay:(NSTimeInterval)delayInterval maximumNumberOfAttempts:(NSUInteger)attemptLimit
{
    if (attemptNumber == 1) {
        [SVProgressHUD showWithStatus:@"Connecting to Layer"];
    } else {
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"Connecting to Layer in %lus (%lu of %lu)", (NSUInteger)delayInterval, (unsigned long)attemptNumber, (unsigned long)attemptLimit]];
    }
}

- (void)layerClientDidConnect:(LYRClient *)client
{
    [SVProgressHUD showSuccessWithStatus:@"Connected to Layer"];
}

- (void)layerClient:(LYRClient *)client didLoseConnectionWithError:(NSError *)error
{
    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Lost Connection: %@", [error localizedDescription]]];
}

- (void)layerClientDidDisconnect:(LYRClient *)client
{
    [SVProgressHUD showSuccessWithStatus:@"Disconnected from Layer"];
}

- (void)didReceiveLayerClientWillBeginSynchronizationNotification:(NSNotification *)notification
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didReceiveLayerClientDidFinishSynchronizationNotification:(NSNotification *)notification
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

+ (NSString *)versionString
{
    NSString *marketingVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSString *bundleVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    
    NSDictionary *buildInformation = [[NSBundle mainBundle] infoDictionary][@"LYRBuildInformation"];
    NSString *versionString = nil;
    if (buildInformation) {
        NSString *layerKitVersion = buildInformation[@"LYRBuildLayerKitVersion"];
        versionString = [NSString stringWithFormat:@"LayerSample v%@ (%@) - LayerKit v%@", marketingVersion, bundleVersion, layerKitVersion];
    } else {
        versionString = [NSString stringWithFormat:@"LayerSample v%@ (%@)", marketingVersion, bundleVersion];
    }
    
    return versionString;
}

+ (NSString *)buildInformationString
{
    NSDictionary *buildInformation = [[NSBundle mainBundle] infoDictionary][@"LYRBuildInformation"];
    
    if (!buildInformation) {
        return [NSString stringWithFormat:@"Non-Release Build"];
    }
    
    NSString *buildSHA = buildInformation[@"LYRBuildShortSha"];
    NSString *builderName = buildInformation[@"LYRBuildBuilderName"];
    NSString *builderEmail = buildInformation[@"LYRBuildBuilderEmail"];
    
    return [NSString stringWithFormat:@"Built by %@ (%@) SHA: %@", builderName, builderEmail, buildSHA];
}

+ (NSString *)layerServerHostname
{
    NSString *configURLString = [[NSUserDefaults standardUserDefaults] objectForKey:@"LAYER_CONFIGURATION_URL"];
    NSURL *URL = [NSURL URLWithString:configURLString];
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
    return URLComponents.host;
}

@end
