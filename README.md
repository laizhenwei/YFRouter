# YFRouter

[![License](https://img.shields.io/github/license/mashape/apistatus.svg)](https://img.shields.io/github/license/laichanwai/YFRouter.svg) &nbsp; [![Support](https://img.shields.io/badge/support-iOS%208%2B%20-blue.svg?style=flat)](https://www.apple.com/nl/ios/) &nbsp; [![CI Status](https://travis-ci.org/laichanwai/YFRouter.svg?branch=master)](https://travis-ci.org/laizw/YFRouter) &nbsp; [![Pod](https://img.shields.io/cocoapods/v/YFRouter.svg?style=flat)](https://img.shields.io/cocoapods/v/YFRouter.svg?style=flat)

**iOS 组件化的时代到临**

YFRouter 是一个高效、轻量级的路由系统，帮你处理一系列的 URL Router 问题。

强烈建议配合 [YFMediator](https://github.com/laichanwai/YFMediator) 使用！！

## News

- 2016.12.25 [增加 URL - Object 绑定](#object-router)

## Usage

![2016121734431Route.gif](http://7xlykq.com1.z0.glb.clouddn.com/2016121734431Route.gif)

### URL Router

```objc
[YFRouter registerURL:@"YF:///feed/detail" handler:^(NSDictionary *params) {
    YFDebug(@"%@", params);
}];

[YFRouter route:@"YF:///feed/detail?id=001" params:nil];

-------------------
{
    YFSchemeKey = YF;
    YFPathKey = @"feed/detail";
    YFURLKey = "YF:///feed/detail?id=001";
    id = 001;
}
-------------------
```

`params` 自带 三个 Key

```
extern NSString * const YFRouterSchemeKey;
extern NSString * const YFRouterPathKey;
extern NSString * const YFRouterURLKey;
```

#### 模糊匹配

```objc
[YFRouter registerURL:@"YF:///feed/detail/:id" handler:^(NSDictionary *params) {
    YFDebug(@"%@", params);
}];

[YFRouter route:@"YF:///feed/detail/001" params:nil];

-------------------
{
    YFSchemeKey = YF;
    YFPathKey = @"feed/detail";
    YFURLKey = "YF:///feed/detail?id=001";
    id = 001;
}
-------------------
```

#### 自定义参数

```objc
[YFRouter registerURL:@"YF:///feed/detail" handler:^(NSDictionary *params) {
    YFDebug(@"%@", params);
}];

[YFRouter route:@"YF:///feed/detail?id=001" params:@{@"city" : @"shanghai"}];

-------------------
{
    YFSchemeKey = YF;
    YFPathKey = @"feed/detail";
    YFURLKey = "YF:///feed/detail?id=001";
    id = 001;
    city = shanghai;
}
-------------------
```

#### Object Router

![2016121717816object.gif](http://7xlykq.com1.z0.glb.clouddn.com/2016121717816object.gif)

通过 `URL` 获取对象，有两种方式，一种是通过绑定一个 `Object Handler` 来获取 `Object`，另一种是直接将 `URL` 和 `Object` 绑定。

- 绑定 Object Handler

```objc
[YFRouter registerURL:@"YF:///alert" objectHandler:^id(NSDictionary *params) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:params[@"title"] message:params[@"message"] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    return alert;
}];
```

- 绑定 Object

```objc
UIAlertController *alert = [UIAlertController alertControllerWithTitle:params[@"title"] message:params[@"message"] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];

[YFRouter registerURL:@"YF://alert" object:alert];
```

- 获取 Object

```objc
// 这种写法也是可以的
// [YFRouter objectForRoute:@"YF://alert" params:@{@"title" : @"Hello", @"message" : @"World"}];
UIAlertController *alert = [YFRouter objectForRoute:@"YF://alert?title=Hello&message=World" params:nil];
[self presentViewController:alert animated:YES completion:nil];
```

### YFRoutr 机制

#### URL 匹配机制

##### Scheme

YFRouter 有一个默认的 Scheme `YFRouterDefaultScheme`，住注册 URL 的时候如果 URL 不含有 Scheme，则会使用 YFRouter 默认的 Scheme。

```objc
extern NSString * const YFRouterDefaultScheme;

[YFRouter registerURL:@"my:///feed/detail" handler:handler]; // my:///feed/detail 

[YFRouter registerURL:@"/feed/detail" handler:handler]; // YFRouterScheme:///feed/detail 

```

##### URLPattern

标准的 Scheme 定义是 `scheme://`，URI 是 `/path`，完整的 URL 是 `scheme:///path`

在 YFRouter 中 URLPattern 是否以 `/` 开始都是可以的，即:

```
// 在 YFRouter 中他们是代表同一个 URL
scheme://feed/detail
scheme://feed/deatil/
scheme:///feed/detail
```

#### shouldFallbackToLastHandler

YFRouter 中有一个选项 `shouldFallbackToLastHandler`，默认是 NO

```objc
+ (void)shouldFallbackToLastHandler:(BOOL)shouldFallback;
```

我们在 YFRouter 中注册中里这个 URL

```
YF:///feed
```

我们现在让 `shouldFallbackToLastHandler` 设置为 `NO`，然后 Route 到这个 URL

```
YF:///feed/detail
```

会发现找不到对应的 Handler，因为关闭 `shouldFallbackToLastHandler` 之后，就是开启了严格匹配模式，只会找对应 URL `YF:///feed/detail` 的 Handler。

#### UncaughtHandler

使用这个方法注册一个 `UcaughtHandler`，所有未匹配到的 URL 都会进入这个方法。

```objc
+ (void)registerUncaughtHandler:(YFRouterHandlerBlock)handler;
```

## Installation

```ruby
pod "YFRouter"
```

ps. 建议在项目中利用默认 Scheme 和 `Target Action` 的方式来处理 URL

```objc
[YFRouter registerURL:@"/:target/:action" handler:^(NSDictionary *params) {
    id target = params[@"target"];
    id action = params[@"action"];
    
    // 根据 target 和 action 来处理业务
    // ...
}];

[YFRouter route:@"/user/login" params:...];
[YFRouter route:@"/user/search?text=laizw" params:...];
```

## Author

laizw, i@laizw.cn

## License

YFRouter is available under the MIT license. See the LICENSE file for more info.


