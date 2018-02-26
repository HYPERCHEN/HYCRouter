//
//  HYCBoxing.m
//  HYCRouter
//
//  Created by eric on 2018/2/24.
//  Copyright © 2018年 eric. All rights reserved.
//

#import "HYCBoxing.h"

@implementation HYCBoxing

+(instancetype)initObj:(id)obj{
    HYCBoxing *boxing = [[HYCBoxing alloc] init];
    boxing.obj = obj;
    return boxing;
}

+(instancetype)initPointer:(void *)poniter{
    HYCBoxing *boxing = [[HYCBoxing alloc] init];
    boxing.poniter = poniter;
    return boxing;
}

+(instancetype)initClass:(Class)clz{
    HYCBoxing *boxing = [[HYCBoxing alloc] init];
    boxing.clz = clz;
    return boxing;
}

+(instancetype)initCharPointer:(char *)charpointer{
    HYCBoxing *boxing = [[HYCBoxing alloc] init];
    boxing.charPoniter = charpointer;
    return boxing;
}


@end

@implementation HYCMethodDesc




@end
