//
//  HYCMediator.h
//  HYCRouter
//
//  Created by eric on 2018/2/24.
//  Copyright © 2018年 eric. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HYCBoxing.h"

@interface HYCMediator : NSObject

+ (id)performSelector:(NSString *)sel withTarget:(NSString *)clz error:(NSError * __autoreleasing *)error,...;

@end

