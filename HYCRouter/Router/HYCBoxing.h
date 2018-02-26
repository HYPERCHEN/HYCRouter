//
//  HYCBoxing.h
//  HYCRouter
//
//  Created by eric on 2018/2/24.
//  Copyright © 2018年 eric. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HYCBoxing : NSObject

@property(nonatomic)id obj;

@property(nonatomic)void * poniter;

@property(nonatomic)char * charPoniter;

@property(nonatomic)Class clz;

+(instancetype)initObj:(id)obj;

+(instancetype)initPointer:(void *)poniter;

+(instancetype)initCharPointer:(char *)charpointer;

+(instancetype)initClass:(Class)clz;

@end


@interface HYCMethodDesc:NSObject

@property(nonatomic,strong)NSMethodSignature *signature;
@property(nonatomic)BOOL isInstance;

@end
