//
//  HYCMediator.m
//  HYCRouter
//
//  Created by eric on 2018/2/24.
//  Copyright © 2018年 eric. All rights reserved.
//

#import "HYCMediator.h"


#if TARGET_OS_IPHONE
#import <UIKit/UIApplication.h>
#endif

static NSLock *_hycMethodLock;

static NSMutableDictionary *_hycMethodSignCacheDic;

@class HYCBoxing;

@implementation HYCMediator

#pragma mark - Public Func

+ (id)performSelector:(NSString *)selstr withTarget:(NSString *)clzstr error:(NSError * __autoreleasing *)error,...{
    
    Class clz = NSClassFromString(clzstr);
    
    SEL sel = NSSelectorFromString(selstr);
    
    if (!clz) {
        NSString *errorDesc = [NSString stringWithFormat:@"No Class %@",clz];
        [self generateError:errorDesc error:error];
        return nil;
    }
    
    va_list argList;
    
    va_start(argList, error);
    
    NSArray *parametersArray = [self generateParametersArray:clz selector:sel argList:argList error:error];
    
    va_end(argList);
    
    return [self hyc_performSelector:sel withTarget:clz paramsArray:parametersArray error:error];
}

#pragma mark - Private func

+(id)hyc_performSelector:(SEL)sel withTarget:(Class)clz paramsArray:(NSArray *)array error:(NSError * __autoreleasing *)error{
    
    NSMethodSignature *methodSignature = [self hyc_getMethodSignWithClass:clz selector:sel];
    
    if (!methodSignature) {
        [self generateError:[NSString stringWithFormat:@"No SEL %@ in Class %@",[self getSelectorName:sel],clz] error:error];
        return nil;
    }
    
    NSInvocation *innvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    
    NSString *selName = [self getSelectorName:sel];
    
    HYCMethodDesc *desc = _hycMethodSignCacheDic[clz][selName];
    
    if (desc.isInstance) {
        id instance = [[clz alloc] init];
        [innvocation setTarget:instance];
    }else{
        [innvocation setTarget:clz];
    }
    
    [innvocation setSelector:sel];
    
    if ([methodSignature numberOfArguments] != (array.count + 2)){
        [self generateError:@"Not match arguments number" error:error];
        return nil;
    }
    
    for (NSInteger i = 2; i < [methodSignature numberOfArguments]; i++) {
        
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:i];
        
        id valObj = array[i - 2];
        
        switch (argumentType[0] == 'r' ? argumentType[1] : argumentType[0] ) {
            
            //Assign
            #define HYC_UNBOXING_ARG_CASE(_typeString, _type, _selector) \
            case _typeString: {                              \
            _type value = [valObj _selector];                     \
            [innvocation setArgument:&value atIndex:i];\
            break; \
            }
                HYC_UNBOXING_ARG_CASE('c', char, charValue)
                HYC_UNBOXING_ARG_CASE('C', unsigned char, unsignedCharValue)
                HYC_UNBOXING_ARG_CASE('s', short, shortValue)
                HYC_UNBOXING_ARG_CASE('S', unsigned short, unsignedShortValue)
                HYC_UNBOXING_ARG_CASE('i', int, intValue)
                HYC_UNBOXING_ARG_CASE('I', unsigned int, unsignedIntValue)
                HYC_UNBOXING_ARG_CASE('l', long, longValue)
                HYC_UNBOXING_ARG_CASE('L', unsigned long, unsignedLongValue)
                HYC_UNBOXING_ARG_CASE('q', long long, longLongValue)
                HYC_UNBOXING_ARG_CASE('Q', unsigned long long, unsignedLongLongValue)
                HYC_UNBOXING_ARG_CASE('f', float, floatValue)
                HYC_UNBOXING_ARG_CASE('d', double, doubleValue)
                HYC_UNBOXING_ARG_CASE('B', BOOL, boolValue)
                
            //Struct
            case '{':{
                
                NSString *typeString = [self extractStructName:[NSString stringWithUTF8String:argumentType]];
                
                NSValue *val = (NSValue *)valObj;
                
                #define HYC_UNBOXING_ARG_STRUCT(_type, _methodName) \
                if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
                _type value = [val _methodName];  \
                [innvocation setArgument:&value atIndex:i];  \
                break; \
                }
                
                HYC_UNBOXING_ARG_STRUCT(CGRect, CGRectValue)
                HYC_UNBOXING_ARG_STRUCT(CGPoint, CGPointValue)
                HYC_UNBOXING_ARG_STRUCT(CGSize, CGSizeValue)
                HYC_UNBOXING_ARG_STRUCT(NSRange, rangeValue)
                HYC_UNBOXING_ARG_STRUCT(CGAffineTransform, CGAffineTransformValue)
                HYC_UNBOXING_ARG_STRUCT(UIEdgeInsets, UIEdgeInsetsValue)
                HYC_UNBOXING_ARG_STRUCT(UIOffset, UIOffsetValue)
                HYC_UNBOXING_ARG_STRUCT(CGVector, CGVectorValue)
                
            }
                break;
                
            //SEL
            case ':':{
                NSString *selName = valObj;
                SEL selValue = NSSelectorFromString(selName);
                [innvocation setArgument:&selValue atIndex:i];
            }
                break;
                
            //Pointer
            case '*':
            {
                HYCBoxing *boxing = (HYCBoxing *)valObj;
                char * charPointer = boxing.charPoniter;
                [innvocation setArgument:&charPointer atIndex:i];
            }
                break;

                
            case '^':
            {
                HYCBoxing *boxing = (HYCBoxing *)valObj;
                void *pointer = boxing.poniter;
                id obj = *((__unsafe_unretained id *)pointer);
                CFRetain((__bridge void*)(obj));
                [innvocation setArgument:&pointer atIndex:i];
            }
                break;
                
            //Class
            case '#':
            {
                [innvocation setArgument:&valObj atIndex:i];
            }
                break;
            
            //Id
            case '@':
            {
                if([valObj isKindOfClass:[HYCBoxing class]]){
                    HYCBoxing *boxing = valObj;
                    id obj = boxing.obj;
                    [innvocation setArgument:&obj atIndex:i];
                }else{
                    [innvocation setArgument:&valObj atIndex:i];
                }
            }
                break;
            
                
            default:
                break;
        }
        
    }
    
    [innvocation invoke];
    
    const char *returnType = [methodSignature methodReturnType];
    
    if (strncmp(returnType,"v",1)!=0) {
        
        if (strncmp(returnType, "@", 1) == 0) {
            
            void *result;
            
            [innvocation getReturnValue:&result];
            
            if (result == NULL) {
                return nil;
            }
            
            id returnValue;
            
            if ([selName isEqualToString:@"alloc"] || [selName isEqualToString:@"new"] || [selName isEqualToString:@"copy"] || [selName isEqualToString:@"mutableCopy"]) {
                returnValue = (__bridge_transfer id)result;
            }else{
                returnValue = (__bridge id)result;
            }
            
            return returnValue;
            
        }else{
            
            switch (returnType[0] == 'r' ? returnType[1]:returnType[0]){
                
                //Assign
                #define HYC_RETURN_CASE(_typeString, _type) \
                case _typeString: {                              \
                _type returnValue; \
                [innvocation getReturnValue:&returnValue];\
                return @(returnValue); \
                break; \
                }
                    HYC_RETURN_CASE('c', char)
                    HYC_RETURN_CASE('C', unsigned char)
                    HYC_RETURN_CASE('s', short)
                    HYC_RETURN_CASE('S', unsigned short)
                    HYC_RETURN_CASE('i', int)
                    HYC_RETURN_CASE('I', unsigned int)
                    HYC_RETURN_CASE('l', long)
                    HYC_RETURN_CASE('L', unsigned long)
                    HYC_RETURN_CASE('q', long long)
                    HYC_RETURN_CASE('Q', unsigned long long)
                    HYC_RETURN_CASE('f', float)
                    HYC_RETURN_CASE('d', double)
                    HYC_RETURN_CASE('B', BOOL)
                
                //Struct
                case '{': {
                    NSString *typeString = [self extractStructName:[NSString stringWithUTF8String:returnType]];
                #define HYC_RETURN_STRUCT(_type) \
                if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
                _type result;   \
                [innvocation getReturnValue:&result];\
                NSValue * returnValue = [NSValue valueWithBytes:&(result) objCType:@encode(_type)];\
                return returnValue;\
                }
                    HYC_RETURN_STRUCT(CGRect)
                    HYC_RETURN_STRUCT(CGPoint)
                    HYC_RETURN_STRUCT(CGSize)
                    HYC_RETURN_STRUCT(NSRange)
                    HYC_RETURN_STRUCT(CGAffineTransform)
                    HYC_RETURN_STRUCT(UIEdgeInsets)
                    HYC_RETURN_STRUCT(UIOffset)
                    HYC_RETURN_STRUCT(CGVector)
                }
                    break;
                    
                case '*':
                {
                    char *returnValue;
                    [innvocation getReturnValue:&returnValue];
                    HYCBoxing *boxing = [[HYCBoxing alloc] init];
                    boxing.charPoniter = returnValue;
                    return boxing;
                }
                    break;
                    
                case '^':
                {
                    void * returnValue = nil;
                    [innvocation getReturnValue:&returnType];
                    HYCBoxing *boxing = [[HYCBoxing alloc] init];
                    boxing.poniter = returnValue;
                    return boxing;
                }
                    break;
                
                case '#':
                {
                    Class clz;
                    [innvocation getReturnValue:&clz];
                    HYCBoxing *boxing = [[HYCBoxing alloc] init];
                    boxing.clz = clz;
                    return boxing;
                }
                    break;
                
            }
            
        }
        
    }
    
    return nil;
}

+(NSArray *)generateParametersArray:(Class)clz selector:(SEL)sel argList:(va_list)argList error:(NSError * __autoreleasing *)error{
    
    NSMethodSignature *methodSignature = [self hyc_getMethodSignWithClass:clz selector:sel];
        
    NSMutableArray *parmArray = [@[] mutableCopy];
    
    for (NSInteger i = 2; i<[methodSignature numberOfArguments]; i++) {
        
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:i];
        
        switch ( argumentType[0] == 'r' ? argumentType[1] : argumentType[0] ) {
        
            //Assign
            #define HYC_BOXING_ARG_CASE(_typeString, _type)\
            case _typeString: {\
            _type value = va_arg(argList, _type);\
            [parmArray addObject:@(value)];\
            break; \
            }\

            HYC_BOXING_ARG_CASE('c', int)
            HYC_BOXING_ARG_CASE('C', int)
            HYC_BOXING_ARG_CASE('s', int)
            HYC_BOXING_ARG_CASE('S', int)
            HYC_BOXING_ARG_CASE('i', int)
            HYC_BOXING_ARG_CASE('I', unsigned int)
            HYC_BOXING_ARG_CASE('l', long)
            HYC_BOXING_ARG_CASE('L', unsigned long)
            HYC_BOXING_ARG_CASE('q', long long)
            HYC_BOXING_ARG_CASE('Q', unsigned long long)
            HYC_BOXING_ARG_CASE('f', double)
            HYC_BOXING_ARG_CASE('d', double)
            HYC_BOXING_ARG_CASE('B', int)
            
            //Struct
            case '{': {

            NSString *typeString = [self extractStructName:[NSString stringWithUTF8String:argumentType]];
            
            #define HYC_FWD_ARG_STRUCT(_type, _methodName) \
            if ([typeString rangeOfString:@#_type].location != NSNotFound) {    \
            _type val = va_arg(argList, _type);\
            NSValue* value = [NSValue _methodName:val];\
            [parmArray addObject:value];  \
            break; \
            }
                
            HYC_FWD_ARG_STRUCT(CGRect, valueWithCGRect)
            HYC_FWD_ARG_STRUCT(CGPoint, valueWithCGPoint)
            HYC_FWD_ARG_STRUCT(CGSize, valueWithCGSize)
            HYC_FWD_ARG_STRUCT(NSRange, valueWithRange)
            HYC_FWD_ARG_STRUCT(CGAffineTransform, valueWithCGAffineTransform)
            HYC_FWD_ARG_STRUCT(UIEdgeInsets, valueWithUIEdgeInsets)
            HYC_FWD_ARG_STRUCT(UIOffset, valueWithUIOffset)
            HYC_FWD_ARG_STRUCT(CGVector, valueWithCGVector)
                
            }
                break;
                
            //SEL (transfer the string)
            case ':': {
                SEL value = va_arg(argList, SEL);
                NSString *selValueName = NSStringFromSelector(value);
                [parmArray addObject:selValueName];
            }
                break;
            
            //Char * and Pointers
            case '^':
            {
                void * pointer = va_arg(argList, void**);
                [parmArray addObject:[HYCBoxing initPointer:pointer]];

            }
                break;
            
        
            case '*':
            {
                char *charPointer = va_arg(argList, char *);
                HYCBoxing *box = [HYCBoxing initCharPointer:charPointer];
                [parmArray addObject:box];
            }
                break;
                
            //Id
            case '@':
            {
                id value = va_arg(argList, id);
                if (value) {
                    [parmArray addObject:value];
                }else{
                    [parmArray addObject:[HYCBoxing initObj:value]];
                }
            }
                break;
            
            //Class
            case '#':
            {
                Class clz = va_arg(argList, Class);
                [parmArray addObject:[HYCBoxing initClass:clz]];
            }
                break;
                
            default:
            {
                [self generateError:@"unsupported arguments" error:error];
            }
                break;
        }
        
    }
    
    return parmArray;
}

+(NSMethodSignature *)hyc_getMethodSignWithClass:(Class)clz selector:(SEL)sel{
    
    NSMethodSignature *signature;
    
    if(!_hycMethodLock){
        _hycMethodLock = [[NSLock alloc] init];
    }
    
    [_hycMethodLock lock];
    
    if (!_hycMethodSignCacheDic) {
        _hycMethodSignCacheDic = [@{} mutableCopy];
    }
    
    if (!_hycMethodSignCacheDic[clz]) {
        _hycMethodSignCacheDic[(id<NSCopying>)clz] = [@{} mutableCopy];
    }
    
    NSString *selName = [self getSelectorName:sel];
    
    HYCMethodDesc *desc = _hycMethodSignCacheDic[clz][selName];
    
    NSMethodSignature *methodSiganture = desc.signature;
    
    if (!methodSiganture) {
        
        //Search from instance method
        methodSiganture = [clz instanceMethodSignatureForSelector:sel];
        
        HYCMethodDesc *desc = [[HYCMethodDesc alloc] init];
        
        if (methodSiganture) {
            
            desc.signature = methodSiganture;
            desc.isInstance = YES;
            
            _hycMethodSignCacheDic[clz][selName] = desc;
            
        }else{
            
            methodSiganture = [clz methodSignatureForSelector:sel];
            
            desc.signature = methodSiganture;
            desc.isInstance = NO;
            
            if (methodSiganture) {
                _hycMethodSignCacheDic[clz][selName] = desc;
            }
            
        }
        
    }
    
    signature = methodSiganture;
    
    [_hycMethodLock unlock];
    
    return signature;
}

#pragma mark - Helper func
+(NSString *)extractStructName:(NSString *)typeEncodingString{
    
    NSArray *array = [typeEncodingString componentsSeparatedByString:@"="];
    NSString *typeString = array[0];
    __block int firstVaildIndex = 0;
    
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        unichar c = [typeEncodingString characterAtIndex:idx];
        if (c=='{'||c=='_') {
            firstVaildIndex++;
        }else{
            *stop = YES;
        }
    }];
    
    return [typeString substringFromIndex:firstVaildIndex];
    
}

+(NSString *)getSelectorName:(SEL)selector{
    const char *selNameCstr = sel_getName(selector);
    NSString *selName = [[NSString alloc]initWithUTF8String:selNameCstr];
    return selName;
}

+(void)generateError:(NSString *)errorDesc error:(NSError **)error{
    
    if (error) {
        *error = [NSError errorWithDomain:errorDesc code:0 userInfo:nil];
    }
    
    NSLog(@"HYCMediator:%@",errorDesc);
    
}

#pragma mark - Singleton
+ (instancetype)sharedInstance{
    static HYCMediator *mediator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mediator = [[HYCMediator alloc] init];
    });
    return mediator;
}



@end
