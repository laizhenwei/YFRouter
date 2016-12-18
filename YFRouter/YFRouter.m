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

#define YFWorlerOperation(__op__, __ap__) YFWorkerInitURL(__ap__) \
[worker __op__:routerUrl];

#define YFWorkerReturnOperation(__op__, __ap__) YFWorkerInitURL(__ap__) \
return [worker __op__:routerUrl];

#define YFWorlerHandlerOperation YFWorkerInitURL(nil) \
[worker add:routerUrl handler:handler];

NSString * const YFRouterDefaultScheme  = @"YFRouterScheme";
NSString * const YFRouterSchemeKey      = @"YFSchemeKey";
NSString * const YFRouterPathKey        = @"YFPathKey";
NSString * const YFRouterURLKey         = @"YFURLKey";
NSString * const YFRouterDomain         = @"YFRouterDomain";

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
    
    YFRouter *router = _routerWorkers[scheme];
    if (!router) {
        router = [[YFRouterWorker alloc] initWithScheme:scheme];
        [_routerWorkers setObject:router forKey:scheme];
    }
    return router;
}

+ (void)unregisterScheme:(NSString *)scheme {
    if (!_routerWorkers[scheme]) {
        YFFlagError(YES, YFRouterDomain, @"Scheme: %@ Not Found", scheme);
    }
    [_routerWorkers removeObjectForKey:scheme];
}

#pragma mark - Public
+ (void)setLogEnable:(BOOL)enable {
    if (enable) {
        [YFLogger addLoggerDomain:YFRouterDomain];
    } else {
        [YFLogger removeLoggerDomain:YFRouterDomain];
    }
}

+ (void)shouldFallbackToLastHandler:(BOOL)shouldFallback {
    [YFRouterWorker shouldFallbackToLastHandler:shouldFallback];
}

+ (void)registerUncaughtHandler:(YFRouterHandlerBlock)handler {
    [YFRouterWorker registerUncaughtHandler:handler];
}

+ (void)registerURL:(NSString *)url handler:(YFRouterHandlerBlock)handler {
    NSParameterAssert(handler != nil);
    NSParameterAssert(url.length > 0);
    YFWorlerHandlerOperation
}

+ (void)registerURL:(NSString *)url objectHandler:(YFRouterObjectHandlerBlock)handler {
    NSParameterAssert(handler != nil);
    NSParameterAssert(url.length > 0);
    YFWorlerHandlerOperation
}

+ (void)unregisterURL:(NSString *)url {
    if (url.length <= 0) {
        YFFlagError(YES, YFRouterDomain, @"URL is nil");
        return;
    }
    YFWorlerOperation(remove, nil)
}

+ (BOOL)canRoute:(NSString *)url {
    if (url.length <= 0) {
        YFFlagError(YES, YFRouterDomain, @"URL is nil");
        return NO;
    }
    YFWorkerReturnOperation(canOpen, nil)
}

+ (void)route:(NSString *)url params:(NSDictionary *)params {
    if (url.length <= 0) {
        YFFlagError(YES, YFRouterDomain, @"URL is nil");
        return;
    }
    YFWorlerOperation(open, params)
}

+ (id)objectForRoute:(NSString *)url params:(NSDictionary *)params {
    if (url.length <= 0) {
        YFFlagError(YES, YFRouterDomain, @"URL is nil");
        return nil;
    }
    YFWorkerReturnOperation(object, params)
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
#undef YFWorlerOperation
#undef YFWorkerReturnOperation
#undef YFWorlerHandlerOperation
