//
//  NUExperimentViewController.m
//  nuexperiment
//
//  Created by dawei on 12/28/13.
//  Copyright (c) 2013 dawei. All rights reserved.
//

#import "NUExperimentViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

typedef void(^TestAnimationBlock)(void);

@interface UIView (nu_block_api)
+ (RACSignal *)nu_animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations;
+ (RACSignal *)nu_animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations; // delay = 0.0, options = 0
@end

@implementation UIView (nu_block_api)
+ (RACSignal *)nu_animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self animateWithDuration:duration delay:delay options:options animations:animations completion:^(BOOL finished) {
            [subscriber sendNext:@(finished)];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}

+ (RACSignal *) nu_animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations {
    return [self nu_animateWithDuration:duration delay:0 options:0 animations:animations];
}

@end

@interface NUExperimentViewController ()
@property (nonatomic, strong) UIView *testview;
@end


@implementation NUExperimentViewController

- (void) loadView {
    [super loadView];
    self.testview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    self.testview.backgroundColor = [UIColor greenColor];
    [self.view addSubview:self.testview];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blueColor];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[[[[[[UIView nu_animateWithDuration:.7 animations:^{
        self.testview.frame = CGRectMake(0, 100, 50, 50);
    }] flattenMap:^RACStream *(id value) {
        return [UIView nu_animateWithDuration:.6 animations:^{
            self.testview.frame = CGRectMake(100, 100, 50, 50);
        }];
    }] flattenMap:^RACStream *(id value) {
        return [UIView nu_animateWithDuration:.5 animations:^{
            self.testview.frame = CGRectMake(100, 0, 50, 50);
        }];
    }] flattenMap:^RACStream *(id value) {
        return [UIView nu_animateWithDuration:.4 animations:^{
            self.testview.frame = CGRectMake(0, 0, 50, 50);
        }];
    }] repeat] take:100] subscribeCompleted:^{
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
