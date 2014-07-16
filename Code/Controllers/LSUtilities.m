//
//  LSUtilities.m
//  LayerSample
//
//  Created by Kevin Coleman on 7/1/14.
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//

#import "LSPersistenceManager.h"

BOOL LSIsRunningTests(void)
{
    return NSClassFromString(@"XCTestCase") != Nil;
}

NSString *LSApplicationHost()
{
    if (LSIsRunningTests()) {
        return [NSProcessInfo processInfo].environment[@"LAYER_TEST_HOST"] ?: @"10.66.0.35";
    }
    return @"199.223.234.118";
}

NSString *LSRailsHost()
{
    if (LSIsRunningTests()) {
        return @"10.66.0.12";
    }
    return @"199.223.234.118";
}

NSURL *LSLayerBaseURL(void)
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@:7072", LSApplicationHost()]];
}

NSURL *LSRailsBaseURL(void)
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:8080", LSRailsHost()]];
}

NSUUID *LSLayerAppID(void)
{
	return [[NSUUID alloc] initWithUUIDString:@"00000000-0000-1000-8000-000000000000"];
}

NSString *LSApplicationDataDirectory(void)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
}

NSString *LSLayerPersistencePath(void)
{
    if (LSIsRunningTests()) {
        return nil;
    }
    return [LSApplicationDataDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqllite", LSLayerAppID()]];
}

LSPersistenceManager *LSPersitenceManager(void)
{
    if (LSIsRunningTests()){
        return [LSPersistenceManager persistenceManagerWithInMemoryStore];
    }
    return [LSPersistenceManager persistenceManagerWithStoreAtPath:[LSApplicationDataDirectory() stringByAppendingPathComponent:@"PersistentObjects"]];
}

void LSAlertWithError(NSError *error)
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Unexpected Error"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

CGRect LSImageRectForThumb(CGSize size, NSUInteger maxConstraint)
{
    CGRect thumbRect;
    if (size.width > size.height) {
        double ratio = maxConstraint/size.width;
        double height = size.height * ratio;
        thumbRect = CGRectMake(0, 0, maxConstraint, height);
    } else {
        double ratio = maxConstraint/size.height;
        double width = size.width * ratio;
        thumbRect = CGRectMake(0, 0, width, maxConstraint);
    }
    return thumbRect;
}