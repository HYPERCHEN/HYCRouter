# HYCRouter

An iOS Router Mediator imitated and modified by popular framework

Mainly refer to the `JSPatch`,`VKMsgSend`,`CTMediator`.
 
## Solve the problem

If there are a method `+(Class)getClassFromString:(NSString *)str` in `TestObj` class. Normally, we need import `TestObj.h`. But how can we run this method without importing?

Firstly we can use the `performSelector`:

```
[self performSelector:selector withObject:obj withObject:obj2];
```
But there are still have two problem:

* it can not support more than 2 parameters
* it needs judge `[Obj class]` or `[obj]` as the `self` parameter to run the method.

Secondly we can use the `NSInvocation` :

```
[CTMediator selector:sel ... parameterArray:@{@"key":@"object"}];
```
In this way , it must be `id` object so that could put into the dictionary.

Therefore, if there are a way could allow more than 2 parameters and use the NSInvocation to call a method.

Refer to the `VKMsgSend`, we can use the `va_list` which used in the `C/C++` frameworks.

So the main process to solve as followings:

* use the va_list to get parameters
* box the parameters as id object and put into an array
* unbox and cast id type to the parameters use in invocation
* if method has return value, boxing the value as id.

## Usage 

```
#import "HYCMediator.h"
```
Use:

```
+ (id)performSelector:(NSString *)sel withTarget:(NSString *)clz error:(NSError * __autoreleasing *)error,...;
```

Example return the pointer or class type (using HYCBoxing.Property)

```
+(Class)HYCMediator_getClassFromString:(NSString *)str{

    HYCBoxing *boxing = [HYCMediator performSelector:@"getClassFromString:" withTarget:@"TestObj" error:nil,@"AppDelegate"];
    
    return boxing.clz;
}
```

More detail u can see in source code :)






