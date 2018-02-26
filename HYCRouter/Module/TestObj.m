//
//  TestObj.m
//  HYCRouter
//
//  Created by eric on 2018/2/26.
//  Copyright © 2018年 eric. All rights reserved.
//

#import "TestObj.h"

@implementation TestObj

+(Class)getClassFromString:(NSString *)str{
    return NSClassFromString(str);
}

@end
