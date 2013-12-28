//
//  AppDelegate.m
//  nuexperiment
//
//  Created by dawei on 12/28/13.
//  Copyright (c) 2013 dawei. All rights reserved.
//

#import "AppDelegate.h"
#import "NUExperimentViewController.h"
#import "Nu.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    NUExperimentViewController *controller = [NUExperimentViewController new];
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:controller];
    self.window.rootViewController = navi;
    [self runAllNuFeatureTest];
    return YES;
}

- (void)runAllNuFeatureTest {
    NuInit();
    
    [[Nu sharedParser] parseEval:@"(load \"nu\")"];
    [[Nu sharedParser] parseEval:@"(load \"test\")"];
    
    NSString *resourceDirectory = [[NSBundle mainBundle] resourcePath];
    
    NSArray *files = [[NSFileManager defaultManager]
                      contentsOfDirectoryAtPath:resourceDirectory
                      error:NULL];
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"^test_.*nu$" options:0 error:NULL];
    for (NSString *filename in files) {
        if ([[self ignoredTest] containsObject:filename]) continue;
        NSUInteger numberOfMatches = [regex numberOfMatchesInString:filename
                                                            options:0
                                                              range:NSMakeRange(0, [filename length])];
        if (numberOfMatches) {
            NSLog(@"loading %@", filename);
            NSString *s = [NSString stringWithContentsOfFile:[resourceDirectory stringByAppendingPathComponent:filename]
                                                    encoding:NSUTF8StringEncoding
                                                       error:NULL];
            [[Nu sharedParser] parseEval:s];
        }
    }
    NSLog(@"running tests");
    [[Nu sharedParser] parseEval:@"(NuTestCase runAllTests)"];
    NSLog(@"ok");
}

- (NSArray *) ignoredTest {
    return @[
             @"test_markup.nu",
             ];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
