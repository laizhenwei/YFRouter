//
//  ViewController.m
//  YFRouter
//
//  Created by laizw on 2016/11/28.
//  Copyright © 2016年 laizw. All rights reserved.
//

#import "ViewController.h"
#import "YFRouter.h"
#import <YFLog.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *registerURL;
@property (weak, nonatomic) IBOutlet UITextField *registerObject;
@property (weak, nonatomic) IBOutlet UITextField *routeURL;
@property (weak, nonatomic) IBOutlet UITextField *scheme;
@property (weak, nonatomic) IBOutlet UITextField *routeObject;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    YFLogTrace()
}
- (IBAction)canRoute:(id)sender {
    BOOL flag = [YFRouter canRoute:self.routeURL.text];
    YFVerbose(@"Can%@Route To %@", flag ? @" " : @" Not ", self.routeURL.text);
}

- (IBAction)route:(id)sender {
    [YFRouter route:self.routeURL.text params:nil];
}

- (IBAction)register:(id)sender {
    YFDebug(@"Register Handler For %@", self.registerURL.text);
    [YFRouter registerURL:self.registerURL.text handler:^(NSDictionary *params) {
        YFDebug(@"%@", params);
    }];
}
- (IBAction)unregister:(id)sender {
    YFDebug(@"Unregister %@", self.registerURL.text);

    [YFRouter unregisterURL:self.registerURL.text];
}
- (IBAction)unregisterScheme:(id)sender {
    YFDebug(@"Unregister Scheme: %@", self.scheme.text);
    [YFRouter unregisterScheme:self.scheme.text];
}

- (IBAction)fallback:(UISwitch *)sender {
    YFDebug(@"Should %@Fallback To Last Handler", sender.on ? @"" : @"Not ");
    [YFRouter shouldFallbackToLastHandler:sender.on];

}
- (IBAction)uncaught:(UISwitch *)sender {
    YFDebug(@"%@ Uncaught Handler", sender.on ? @"Register" : @"Unregister");
    if (sender.on) {
        [YFRouter registerUncaughtHandler:^(NSDictionary *params) {
            YFDebug(@"Uncaught Handler %@", params);
        }];
    } else {
        [YFRouter registerUncaughtHandler:nil];
    }
}

- (IBAction)registerObj:(id)sender {
    YFDebug(@"Register Object Handler For %@", self.registerObject.text);
    [YFRouter registerURL:self.registerObject.text objectHandler:^id(NSDictionary *params) {
        NSString *message = params[@"message"] ?: [NSString stringWithFormat:@"这是通过 %@ 获取的 alert", params[YFRouterURLKey]];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:params[@"title"] message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        return alert;
    }];
}

- (IBAction)routerObject:(id)sender {
    UIAlertController *alert = [YFRouter objectForRoute:self.routeObject.text params:nil];
    if (alert) {
        [self presentViewController:alert animated:YES completion:nil];
    }
}


@end
