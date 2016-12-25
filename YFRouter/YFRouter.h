//
//  YFRouter.h
//  YFRouter
//
//  Created by laizw on 2016/11/28.
//  Copyright © 2016年 laizw. All rights reserved.
//

#import <UIKit/UIKit.h>

#define YFRouterDomain @"YFRouterDomain"

extern NSString * const YFRouterDefaultScheme;
extern NSString * const YFRouterSchemeKey;
extern NSString * const YFRouterPathKey;
extern NSString * const YFRouterURLKey;

typedef void(^YFRouterHandlerBlock)(NSDictionary *params);
typedef id(^YFRouterObjectHandlerBlock)(NSDictionary *params);

@interface YFRouter : NSObject

/**
 控制台输出控制
 建议不要关闭， YFRouter 只会输出错误和警告信息
 
 @param enable LogEnable
 */
+ (void)setLogEnable:(BOOL)enable;

/**
 在找不到当前节点的 handler 时候是否允许上一个节点的 Handler 接受处理
 eg.
 register: yf:///user --> myHandler
 route: yf:///user/follow
 如果允许，则会执行 myHandler，否则将 Route 失败，进入 UncaughtHandler
 
 默认为 NO

 @param shouldFallback 允许回滚到上一节点
 */
+ (void)shouldFallbackToLastHandler:(BOOL)shouldFallback;

/**
 未匹配的 URL 会进入这个 handler
 
 @param handler UncaughtHandler
 */
+ (void)registerUncaughtHandler:(YFRouterHandlerBlock)handler;

/**
 注册 URL
 如果 URL 包含 scheme:// 那么 URL 会绑定在该 scheme 中
 如果不包含 scheme，URL 会绑定在 defaultScheme 中
 
 @param url 注册的 URL
 @param handler URL 绑定的 Handler
 */
+ (void)registerURL:(NSString *)url handler:(YFRouterHandlerBlock)handler;

/**
 注册 URL，并且在 Handler 中返回一个对象

 @param url 注册的 URL
 @param handler URL 绑定的 ObjectHandler
 */
+ (void)registerURL:(NSString *)url objectHandler:(YFRouterObjectHandlerBlock)handler;

/**
 绑定 URL 和 对象
 使用 +objectForRoute:params: 获取
 
 注意: 如果 object 的类型是 id(^)(NSDictonry *)，那么获取的时候会直接执行该 block
 
 @param url 注册的 URL
 @param object URL 绑定的对象
 */
+ (void)registerURL:(NSString *)url object:(id)object;

/**
 取消注册 URL

 @param url 需要取消注册的 URL
 */
+ (void)unregisterURL:(NSString *)url;

/**
 取消注册 Scheme
 会取消该 Scheme 下的所有 URL

 @param scheme 需要取消注册的 Scheme
 */
+ (void)unregisterScheme:(NSString *)scheme;

/**
 是否能够处理 URL
 判断是否存在处理该 URL 的 Handler

 @param url 需要处理的 URL
 @return 返回结果
 */
+ (BOOL)canRoute:(NSString *)url;

/**
 处理 URL，可传入参数

 @param url 需要处理的 URL
 @param params 传入参数
 */
+ (void)route:(NSString *)url params:(NSDictionary *)params;

/**
 从 URL 中得到一个对象

 @param url 需要处理的 URL
 @param params 传入的参数
 @return 返回的对象
 */
+ (id)objectForRoute:(NSString *)url params:(NSDictionary *)params;

/**
 封装 NSURL，操作如 +(BOOL)canRoute:(NSString *)url
 不会使用默认 Scheme，需要指定 Scheme，否则返回 NO
 
 @param url 需要处理的 URL
 @return 返回结果
 */
+ (BOOL)canOpenURL:(NSURL *)url;

/**
 封装 NSURL，操作如 +(void)route:(NSString *)url params:(NSDictionary *)params;

 @param url 需要处理的 URL
 @param params 传入的参数
 */
+ (void)openURL:(NSURL *)url params:(NSDictionary *)params;

@end

