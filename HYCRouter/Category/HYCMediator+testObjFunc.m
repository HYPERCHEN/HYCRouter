//
//  HYCMediator+testObjFunc.m
//  HYCRouter
//
//  Created by eric on 2018/2/26.
//  Copyright © 2018年 eric. All rights reserved.
//

#import "HYCMediator+testObjFunc.h"

@implementation HYCMediator (testObjFunc)

+(Class)HYCMediator_getClassFromString:(NSString *)str{
    
    HYCBoxing *boxing = [HYCMediator performSelector:@"getClassFromString:" withTarget:@"TestObj" error:nil,@"AppDelegate"];
    
    return boxing.clz;
    
}



@end
