//
//  YFRouterWorker.h
//  YFRouter
//
//  Created by laizw on 2016/12/11.
//  Copyright © 2016年 laizw. All rights reserved.
//

#import "YFRouter.h"

@interface YFURL : NSObject

@property (nonatomic, copy, readonly) NSString *urlString;
@property (nonatomic, copy, readonly) NSString *scheme;
@property (nonatomic, copy, readonly) NSArray *pathComponents;
@property (nonatomic, copy, readonly) NSDictionary *params;

+ (instancetype)urlWithString:(NSString *)urlString params:(NSDictionary *)params;

@end

@interface YFRouterWorker : YFRouter

@property (nonatomic, copy) NSString *scheme;

- (instancetype)initWithScheme:(NSString *)scheme;

- (void)add:(YFURL *)url handler:(id)handler;

- (void)remove:(YFURL *)url;

- (BOOL)canOpen:(YFURL *)url;

- (void)open:(YFURL *)url;

- (id)object:(YFURL *)url;

@end
