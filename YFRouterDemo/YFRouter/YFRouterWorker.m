//
//  YFRouterWorker.m
//  YFRouter
//
//  Created by laizw on 2016/12/11.
//  Copyright © 2016年 laizw. All rights reserved.
//

#import "YFRouterWorker.h"

@implementation YFURL

+ (instancetype)urlWithString:(NSString *)urlString params:(NSDictionary *)params {
    return [[YFURL alloc] initWithString:urlString params:params];
}

- (instancetype)initWithString:(NSString *)urlString params:(NSDictionary *)params {
    if (!urlString) return nil;
    if (self = [super init]) {
        
        // URL
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        _urlString = urlString;
        
        // Scheme
        NSRange range = [urlString rangeOfString:@"://"];
        if (range.length > 0) {
            NSString *scheme = [urlString substringToIndex:range.location];
            _scheme = scheme;
            
            urlString = [urlString substringFromIndex:range.location + 3];
        }
        
        NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
        // Path Components
        NSMutableArray *pathComponent = @[].mutableCopy;
        for (NSString *path in [components.percentEncodedPath componentsSeparatedByString:@"/"]) {
            if (path.length <= 0) continue;
            [pathComponent addObject:path];
        }
        _pathComponents = pathComponent.copy;
        
        // Parameters
        NSMutableDictionary *newParams = @{}.mutableCopy;
        for (NSURLQueryItem *item in components.queryItems) {
            if (item.value == nil) continue;
            newParams[item.name] = item.value;
        }
        if (params) [newParams addEntriesFromDictionary:params];
        _params = newParams.copy;
        
    }
    return self;
}

@end

static NSString * const YFRouterWorkerBlockKey = @"YFRouterWorkerBlockKey";
static YFRouterHandlerBlock uncaughtHandler;
static BOOL shouldFallbackToLastHandler;

@interface YFRouterWorker ()
@property (nonatomic, strong) NSMutableDictionary *routers;
@end

@implementation YFRouterWorker

+ (void)load {
    [YFLogger addLoggerDomain:YFRouterDomain];
}

#pragma mark - Public
- (instancetype)initWithScheme:(NSString *)scheme {
    if (self = [super init]) {
        self.scheme = scheme;
        YFFlagInfo(YES, YFRouterDomain, @"Create Router For Scheme: %@", scheme);
    }
    return self;
}

+ (void)shouldFallbackToLastHandler:(BOOL)shouldFallback {
    shouldFallbackToLastHandler = shouldFallback;
}

+ (void)registerUncaughtHandler:(YFRouterHandlerBlock)handler {
    if (!handler) {
        uncaughtHandler = nil;
        return;
    }
    uncaughtHandler = [handler copy];
}

- (void)add:(YFURL *)url handler:(id)handler {
    [self routersForURL:url][YFRouterWorkerBlockKey] = handler;
}

- (void)remove:(YFURL *)url {
    NSMutableArray *pathComponent = [url.pathComponents mutableCopy];
    [pathComponent addObject:YFRouterWorkerBlockKey];
    [self unregisterSubRoutersWithPathComponents:pathComponent];
}

- (BOOL)canOpen:(YFURL *)url {
    __block BOOL canOpen = NO;
    [self searchRouterURL:url result:^(id handler, NSDictionary *params) {
        if (handler) canOpen = YES;
    }];
    return canOpen;
}

- (void)open:(YFURL *)url {
    [self searchRouterURL:url result:^(YFRouterHandlerBlock handler, NSDictionary *params) {
        NSMutableDictionary *newParams = @{}.mutableCopy;
        [newParams addEntriesFromDictionary:@{
                                              YFRouterSchemeKey : self.scheme,
                                              YFRouterURLKey    : url.urlString
                                              }];
        if (handler) {
            [newParams addEntriesFromDictionary:params];
            [newParams addEntriesFromDictionary:url.params];
            handler(newParams);
        } else if (uncaughtHandler) {
            uncaughtHandler(newParams);
        } else {
            YFFlagError(YES, YFRouterDomain, @"Handler For URL: %@ Not Found", url.urlString);
        }
    }];
}

- (id)object:(YFURL *)url {
    __block id object;
    [self searchRouterURL:url result:^(YFRouterObjectHandlerBlock handler, NSDictionary *params) {
        if (handler) {
            NSMutableDictionary *newParams = @{}.mutableCopy;
            [newParams addEntriesFromDictionary:@{
                                                  YFRouterSchemeKey : self.scheme,
                                                  YFRouterURLKey    : url.urlString
                                                  }];
            [newParams addEntriesFromDictionary:params];
            [newParams addEntriesFromDictionary:url.params];
            object = handler(newParams);
        } else {
            YFFlagError(YES, YFRouterDomain, @"Object Handler Not Found");
        }
    }];
    return object;
}

#pragma mark - Private
- (NSMutableDictionary *)routersForURL:(YFURL *)url {
    NSMutableDictionary *routers = self.routers;
    for (int i = 0; i < url.pathComponents.count; i++) {
        NSString *key = url.pathComponents[i];
        if (!routers[key]) {
            routers[key] = @{}.mutableCopy;
        }
        routers = routers[key];
    }
    return routers;
}

- (void)searchRouterURL:(YFURL *)url result:(void (^)(id, NSDictionary *))result {
    NSMutableDictionary *routers = [self.routers copy];
    NSMutableDictionary *params = @{}.mutableCopy;
    
    // 是否允许上一个路径节点的 Handler 处理 URL
#define YFHandleNotFound \
{ if (shouldFallbackToLastHandler) break; \
if (result) result(nil, params); \
result = nil; \
return; }
    
    for (NSString *path in url.pathComponents) {
        // 找不到该节点
        if (routers.count <= 0) YFHandleNotFound;
        // 优先匹配给定路径
        if (routers[path]) {
            routers = routers[path];
            continue;
        }
        // 获取所有模糊匹配
        NSArray *fuzzyKeys = [routers.allKeys filteredArrayUsingPredicate:self.predicate];
        // 找不到模糊匹配
        if (fuzzyKeys.count <= 0) YFHandleNotFound;
        // 同一节点出现多个匹配
        if (fuzzyKeys.count > 1) { // 报警告
            YFFlagWarning(YES, YFRouterDomain, @"There Are More Than One FuzzyKeys %@", routers.allKeys);
        }
        // 默认匹配（随机）
        NSString *key = fuzzyKeys[0];
        params[[key substringFromIndex:1]] = path;
        routers = routers[key];
    }
    if (result) result(routers[YFRouterWorkerBlockKey], params);
    result = nil;
    
#undef YFHandleNotFound
}

- (void)unregisterSubRoutersWithPathComponents:(NSMutableArray *)pathComponents {
    if (pathComponents.count <= 0) return;
    NSString *key = pathComponents.lastObject;
    [pathComponents removeLastObject];
    NSMutableDictionary *routers;
    @synchronized (self.routers) {
        if (pathComponents.count) {
            routers= [self.routers valueForKeyPath:[pathComponents componentsJoinedByString:@"."]];
        } else {
            routers = self.routers;
        }
        if (!routers) return;
        [routers removeObjectForKey:key];
    }
    if (routers.count < 1) {
        [self unregisterSubRoutersWithPathComponents:pathComponents];
    }
}

#pragma mark - Getter
- (NSMutableDictionary *)routers {
    if (!_routers) {
        _routers = @{}.mutableCopy;
    }
    return _routers;
}

- (NSPredicate *)predicate {
    static NSPredicate *predicate = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        predicate = [NSPredicate predicateWithFormat:@"self BEGINSWITH ':'"];
    });
    return predicate;
}

@end

