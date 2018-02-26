//
//  ViewController.m
//  HYCRouter
//
//  Created by eric on 2018/2/24.
//  Copyright © 2018年 eric. All rights reserved.
//

#import "ViewController.h"
#import "HYCMediator+testObjFunc.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    NSLog(@"%@",[HYCMediator HYCMediator_getClassFromString:@"ViewController"]);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
