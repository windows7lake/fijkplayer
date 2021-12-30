//
//  NSObject+FijkHttpCache.m
//  fijkplayer
//
//  Created by ying lin on 2021/12/30.
//

#import "FijkHttpCache.h"
#import "FijkPreLoaderModel.h"
#import <KTVHTTPCache/KTVHTTPCache.h>

@interface FijkHttpCache()<KTVHCDataLoaderDelegate>

/// 预加载的模型数组
@property (nonatomic, strong) NSMutableArray<FijkPreLoaderModel *> *preloadArr;

@end

@implementation FijkHttpCache

// Provides a global static variable.
static FijkHttpCache *_instance = nil;

+ (instancetype)defaultStore {
    return [[self.class alloc] init];
}

/** Returns a new instance of the receiving class.
 */
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (_instance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _instance = [super allocWithZone:zone];
        });
    }
    
    return _instance;
}

- (instancetype)init {
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _instance = [super init];
        [_instance setup];
    });
    
    return _instance;
}

/** Sets initial value for some member variables.
 */
- (void)setup {
    _preloadPrecent = 0.1;
    [self initialize];
}

- (void)initialize {
    [KTVHTTPCache logSetConsoleLogEnable:NO];
    NSError *error = nil;
    [KTVHTTPCache proxyStart:&error];
    if (error) {
        NSLog(@"Proxy Start Failure, %@", error);
    }
    [KTVHTTPCache encodeSetURLConverter:^NSURL *(NSURL *URL) {
//        NSLog(@"URL Filter reviced URL : %@", URL);
        return URL;
    }];
    [KTVHTTPCache downloadSetUnacceptableContentTypeDisposer:^BOOL(NSURL *URL, NSString *contentType) {
        return NO;
    }];
    // 设置缓存最大容量
    [KTVHTTPCache cacheSetMaxCacheLength:1024 * 1024 * 1024];
    NSLog(@"Proxy initialize complete");
}

- (NSString *)getProxyUrl:(NSString *)url {
    NSURL *aUrl = [NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:
                                      NSUTF8StringEncoding]];
    // 如果有缓存，直接取本地缓存
    NSURL *proxyUrl = [KTVHTTPCache cacheCompleteFileURLWithURL:aUrl];
    NSString *urlStr;
    if (proxyUrl) {
        urlStr = proxyUrl.absoluteString;
        NSLog(@"getProxyUrl cacheCompleteFileURLWithURL: %@", urlStr);
    } else {
        // 设置代理
        urlStr = [KTVHTTPCache proxyURLWithOriginalURL:aUrl].absoluteString;
        NSLog(@"getProxyUrl proxyURLWithOriginalURL: %@", urlStr);
    }
    return urlStr;
}

- (void)preload: (NSString *)urlStr {
    [self cancelAllPreload];
    FijkPreLoaderModel *preModel = [self getPreloadModel: urlStr];
    if (preModel) {
       @synchronized (self.preloadArr) {
           [self.preloadArr addObject:preModel];
       }
    }
    [self processLoader];
}

/// 取消所有的预加载
- (void)cancelAllPreload {
    @synchronized (self.preloadArr) {
        if (self.preloadArr.count == 0) {
            return;
        }
        [self.preloadArr enumerateObjectsUsingBlock:^(FijkPreLoaderModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj.loader close];
        }];
        [self.preloadArr removeAllObjects];
    }
}

- (FijkPreLoaderModel *)getPreloadModel: (NSString *)urlStr {
    if (!urlStr)
        return nil;
    // 判断是否已在队列中
    __block Boolean res = NO;
    @synchronized (self.preloadArr) {
        [self.preloadArr enumerateObjectsUsingBlock:^(FijkPreLoaderModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.url isEqualToString:urlStr])
            {
                res = YES;
                *stop = YES;
            }
        }];
    }
    if (res)
        return nil;
    NSURL *proxyUrl = [KTVHTTPCache proxyURLWithOriginalURL: [NSURL URLWithString:urlStr]];
    KTVHCDataCacheItem *item = [KTVHTTPCache cacheCacheItemWithURL:proxyUrl];
    double cachePrecent = 1.0 * item.cacheLength / item.totalLength;
    // 判断缓存已经超过10%了
    if (cachePrecent >= self.preloadPrecent)
        return nil;
    KTVHCDataRequest *req = [[KTVHCDataRequest alloc] initWithURL:proxyUrl headers:[NSDictionary dictionary]];
    KTVHCDataLoader *loader = [KTVHTTPCache cacheLoaderWithRequest:req];
    FijkPreLoaderModel *preModel = [[FijkPreLoaderModel alloc] initWithURL:urlStr loader:loader];
    return preModel;
}

- (void)processLoader {
    @synchronized (self.preloadArr) {
        if (self.preloadArr.count == 0)
            return;
        FijkPreLoaderModel *model = self.preloadArr.firstObject;
        model.loader.delegate = self;
        [model.loader prepare];
    }
}

/// 根据loader，移除预加载任务
- (void)removePreloadTask: (KTVHCDataLoader *)loader {
    @synchronized (self.preloadArr) {
        FijkPreLoaderModel *target = nil;
        for (FijkPreLoaderModel *model in self.preloadArr) {
            if ([model.loader isEqual:loader]) {
                target = model;
                break;
            }
        }
        if (target)
            [self.preloadArr removeObject:target];
    }
}

- (void)ktv_loader:(KTVHCDataLoader *)loader didChangeProgress:(double)progress {
    if (progress >= self.preloadPrecent) {
        [loader close];
        [self removePreloadTask:loader];
        [self processLoader];
    }
}

- (void)ktv_loader:(KTVHCDataLoader *)loader didFailWithError:(NSError *)error {
    // 若预加载失败的话，就直接移除任务，开始下一个预加载任务
    [self removePreloadTask:loader];
    [self processLoader];
}

- (void)ktv_loaderDidFinish:(KTVHCDataLoader *)loader {
}

@end
