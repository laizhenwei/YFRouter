//
//  YFRouterWorker.m
//  YFRouter
//
//  Created by laizw on 2016/12/11.
//  Copyright © 2016年 laizw. All rights reserved.
//

#import "YFRouterWorker.h"
#import <objc/runtime.h>

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
            _scheme = [scheme lowercaseString];
            
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
        _path = components.percentEncodedPath;
        if ([[_path substringToIndex:1] isEqualToString:@"/"]) _path = [_path substringFromIndex:1];
        
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

static NSString * const YFRouterWorkerObjectKey = @"YFRouterWorkerObjectKey";
static YFRouterHandlerBlock uncaughtHandler;
static BOOL shouldFallbackToLastHandler;

@interface YFRouterWorker ()
@property (nonatomic, strong) NSMutableDictionary *routers;
@end

@implementation YFRouterWorker

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

- (void)add:(YFURL *)url object:(id)object {
    [self routersForURL:url][YFRouterWorkerObjectKey] = object;
}

- (void)remove:(YFURL *)url {
    NSMutableArray *pathComponent = [url.pathComponents mutableCopy];
    [pathComponent addObject:YFRouterWorkerObjectKey];
    [self unregisterSubRoutersWithPathComponents:pathComponent];
}

- (BOOL)canOpen:(YFURL *)url {
    YFObject *result = [self searchRouterURL:url];
    return result.value != nil;
}

- (void)open:(YFURL *)url {
    YFObject *result = [self searchRouterURL:url];
    NSMutableDictionary *newParams = [self paramsFromResult:result URL:url];
    if (result.value) {
        ((YFRouterHandlerBlock)result.value)(newParams);
    } else if (uncaughtHandler) {
        uncaughtHandler(newParams);
    } else {
        YFFlagError(YES, YFRouterDomain, @"Handler For URL: %@ Not Found", url.urlString);
    }
}

- (YFObject *)object:(YFURL *)url {
    YFObject *result = [self searchRouterURL:url];
    YFObject *object = [[YFObject alloc] init];
    if (result.value) {
        static YFRouterObjectHandlerBlock block = ^id(NSDictionary *params) {return nil;};
        object.value = result.value;
        object.params = [[self paramsFromResult:result URL:url] copy];
        if ([result.value isKindOfClass:NSClassFromString(@"NSBlock")] && BlockSigal(block) == BlockSigal(result.value)) {
            object.value = ((YFRouterObjectHandlerBlock)result.value)(object.params);
        }
    } else {
        YFFlagError(YES, YFRouterDomain, @"Object Not Found");
    }
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

- (NSMutableDictionary *)paramsFromResult:(YFObject *)result URL:(YFURL *)url {
    NSMutableDictionary *newParams = @{}.mutableCopy;
    [newParams addEntriesFromDictionary:@{
                                          YFRouterSchemeKey : self.scheme,
                                          YFRouterPathKey   : url.path,
                                          YFRouterURLKey    : url.urlString
                                          }];
    [newParams addEntriesFromDictionary:result.params];
    [newParams addEntriesFromDictionary:url.params];
    return newParams;
}

- (YFObject *)searchRouterURL:(YFURL *)url {
    #define YFHandleNotFound \
    { if (shouldFallbackToLastHandler) break; \
    object.params = params.copy; \
    return object; }
    
    NSMutableDictionary *routers = [self.routers copy];
    NSMutableDictionary *params = @{}.mutableCopy;
    
    YFObject *object = [[YFObject alloc] init];
    for (NSString *path in url.pathComponents) {
        if (routers.count <= 0) YFHandleNotFound;
        // 优先匹配给定路径
        if (routers[path]) {
            routers = routers[path];
            continue;
        }
        NSArray *fuzzyKeys = [routers.allKeys filteredArrayUsingPredicate:self.predicate];
        if (fuzzyKeys.count <= 0) YFHandleNotFound;
        
        // 同一节点出现多个匹配
        if (fuzzyKeys.count > 1) {
            YFFlagWarning(YES, YFRouterDomain, @"There Are More Than One FuzzyKeys %@", routers.allKeys);
        }
        NSString *key = fuzzyKeys[0];
        params[[key substringFromIndex:1]] = path;
        routers = routers[key];
    }
    object.value = routers[YFRouterWorkerObjectKey];
    object.params = params.copy;
    return object;

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

#pragma mark - Helper
struct BlockDescriptor {
    unsigned long reserved;
    unsigned long size;
    void *rest[1];
};

struct Block {
    void *isa;
    int flags;
    int reserved;
    void *invoke;
    struct BlockDescriptor *descriptor;
};

static const char *BlockSigal(id blockObj) {
    struct Block *block = (__bridge void *)blockObj;
    struct BlockDescriptor *descriptor = block->descriptor;
    
    int copyDisposeFlag = 1 << 25;
    int signatureFlag = 1 << 30;
    
    assert(block->flags & signatureFlag);
    
    int index = 0;
    if(block->flags & copyDisposeFlag) index += 2;
    
    return descriptor->rest[index];
}

@end
