//
//  NUExperimentViewController.m
//  nuexperiment
//
//  Created by dawei on 12/28/13.
//  Copyright (c) 2013 dawei. All rights reserved.
//

#import "NUExperimentViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "Nu.h"

typedef void(^TestAnimationBlock)(void);

@interface UIView (nu_block_api)
+ (RACSignal *)nu_animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(NuBlock *) nu_block_animation;
+ (RACSignal *)nu_animateWithDuration:(NSTimeInterval)duration animations:(NuBlock *) nu_block_animation; // delay = 0.0, options = 0
@end

@implementation UIView (nu_block_api)
+ (RACSignal *)nu_animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(NuBlock *) nu_block_animation {
    if (![nu_block_animation respondsToSelector:@selector(evalWithArguments:context:)]) return nil;
    
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self animateWithDuration:duration delay:delay options:options animations:^{
            [nu_block_animation evalWithArguments:nil context:nil];
        } completion:^(BOOL finished) {
            [subscriber sendNext:@(finished)];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}

+ (RACSignal *) nu_animateWithDuration:(NSTimeInterval)duration animations:(NuBlock *)nu_block_animation{
    return [self nu_animateWithDuration:duration delay:0 options:0 animations:nu_block_animation];
}

@end

@interface RACSignal (nu_block_api)
- (RACDisposable *) nu_subscribeCompleted:(NuBlock *) complete;
@end

@implementation RACSignal (nu_block_api)
- (RACDisposable *) nu_subscribeCompleted:(NuBlock *)complete {
    if (![complete respondsToSelector:@selector(evalWithArguments:context:)]) return [self subscribeCompleted:^{}];
    
    return [self subscribeCompleted:^{
        [complete evalWithArguments:nil context:nil];
    }];
}
@end

@interface RACStream (nu_block_api)
- (instancetype)nu_flattenMap:(NuBlock *) nu_block;
@end

@implementation RACStream (nu_block_api)
- (instancetype)nu_flattenMap:(NuBlock *) nu_block {
    return [self flattenMap:^RACStream *(id value) {
        return [nu_block evalWithArguments:[NuCell cellWithCar:value cdr:nil] context:nil];
    }];
}

@end

@interface NUExperimentViewController ()
@property (nonatomic, strong) UIView *testview;
@property (nonatomic, strong) UIImage *image;
@end


@implementation NUExperimentViewController

- (instancetype) init {
    self = [super init];
    if (self == nil) return nil;
    [self reEvalNu];
    return self;
}

- (void) loadView {
    [super loadView];
    self.testview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    self.testview.backgroundColor = [UIColor greenColor];
    [self.view addSubview:self.testview];
    self.image = [UIImage imageNamed:@"test.jpg"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blueColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reEvalNu)];
}

- (void)reEvalNu {
    NSURL *nuURL = [[NSBundle mainBundle] URLForResource:@"nuexp" withExtension:@"nu"];
    NSString *nu = [[NSString alloc] initWithContentsOfURL:nuURL encoding:NSUTF8StringEncoding error:nil];
    [[Nu sharedParser] parseEval:nu];
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
