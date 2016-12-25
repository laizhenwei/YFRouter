//
//  YFRouter.m
//  YFRouter
//
//  Created by laizw on 2016/11/28.
//  Copyright © 2016年 laizw. All rights reserved.
//

#import "YFRouter.h"
#import "YFRouterWorker.h"

#define YFWorkerInitURL(__ap__) \
YFURL *routerUrl = [YFURL urlWithString:url params:__ap__]; \
YFRouterWorker *worker = [self routerForScheme:routerUrl.scheme ?: YFRouterDefaultScheme];

#define YFWorkerURLError(__return__) \
if (url.length <= 0) { \
YFFlagError(YES, YFRouterDomain, @"URL is nil"); \
return __return__; }

#define YFWorlerOperation(__op__, __ap__) YFWorkerInitURL(__ap__) \
YFWorkerURLError() \
[worker __op__:routerUrl];

#define YFWorkerReturnOperation(__op__, __ap__, __return__) YFWorkerInitURL(__ap__) \
YFWorkerURLError(__return__) \
return [worker __op__:routerUrl];

#define YFWorlerObjectOperation YFWorkerInitURL(nil) \
NSParameterAssert(object != nil); \
NSParameterAssert(url.length > 0); \
[worker add:routerUrl object:object];

NSString * const YFRouterDefaultScheme  = @"YFRouterScheme";
NSString * const YFRouterSchemeKey      = @"YFSchemeKey";
NSString * const YFRouterPathKey        = @"YFPathKey";
NSString * const YFRouterURLKey         = @"YFURLKey";


static NSMutableDictionary *_routerWorkers;

@implementation YFRouter
+ (void)load {
    [self setLogEnable:YES];
}

#pragma mark - Life Circle
+ (id)routerForScheme:(NSString *)scheme {
    if (scheme.length <= 0) {
        YFFlagError(YES, YFRouterDomain, @"Scheme is nil");
        return nil;
    }
    
    if (!_routerWorkers) {
        _routerWorkers = @{}.mutableCopy;
    }
    
    scheme = [scheme lowercaseString];
    YFRouter *router = _routerWorkers[scheme];
    if (!router) {
        router = [[YFRouterWorker alloc] initWithScheme:scheme];
        [_routerWorkers setObject:router forKey:scheme];
    }
    return router;
}

+ (void)unregisterScheme:(NSString *)scheme {
    scheme = [scheme lowercaseString];
    if (!_routerWorkers[scheme]) {
        YFFlagError(YES, YFRouterDomain, @"Scheme: %@ Not Found", scheme);
    }
    [_routerWorkers removeObjectForKey:scheme];
}

#pragma mark - Public
+ (void)setLogEnable:(BOOL)enable {
    if (enable) {
        [YFLogger addLoggerWithDomain:YFRouterDomain];
    } else {
        [YFLogger removeLoggerWithDomain:YFRouterDomain];
    }
}

+ (void)shouldFallbackToLastHandler:(BOOL)shouldFallback {
    [YFRouterWorker shouldFallbackToLastHandler:shouldFallback];
}

+ (void)registerUncaughtHandler:(YFRouterHandlerBlock)handler {
    [YFRouterWorker registerUncaughtHandler:handler];
}

+ (void)registerURL:(NSString *)url handler:(YFRouterHandlerBlock)object {
    YFWorlerObjectOperation
}

+ (void)registerURL:(NSString *)url objectHandler:(YFRouterObjectHandlerBlock)object {
    YFWorlerObjectOperation
}

+ (void)registerURL:(NSString *)url object:(id)object; {
    YFWorlerObjectOperation
}

+ (void)unregisterURL:(NSString *)url {
    YFWorlerOperation(remove, nil)
}

+ (BOOL)canRoute:(NSString *)url {
    YFWorkerReturnOperation(canOpen, nil, NO)
}

+ (void)route:(NSString *)url params:(NSDictionary *)params {
    YFWorlerOperation(open, params)
}

+ (id)objectForRoute:(NSString *)url params:(NSDictionary *)params {
    YFWorkerReturnOperation(object, params, nil)
}

+ (BOOL)canOpenURL:(NSURL *)url {
    if (!url || !_routerWorkers[url.scheme]) return NO;
    return [self canRoute:url.absoluteString];
}

+ (void)openURL:(NSURL *)url params:(NSDictionary *)params {
    [self route:url.absoluteString params:params];
}

@end

#undef YFWorkerInitURL
#undef YFWorkerURLError
#undef YFWorlerOperation
#undef YFWorkerReturnOperation
#undef YFWorlerHandlerOperation
