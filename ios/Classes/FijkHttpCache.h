//
//  FijkHttpCache.h
//  fijkplayer
//
//  Created by ying lin on 2021/12/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FijkHttpCache : NSObject

/// 预加载的的百分比，默认10%
@property (nonatomic, assign) double preloadPrecent;

- (void)preload: (NSString *)urlStr;

- (NSString *)getProxyUrl:(NSString *)url;

- (void)cancelAllPreload;

- (void)processLoader;

/** Constructs a store singleton with class method.
 
 @return A store singleton.
 */
+ (instancetype)defaultStore;

/** Disable this method to make sure the class has only one instance.
 */
+ (instancetype)new NS_UNAVAILABLE;

/** Disable this method to make sure the class has only one instance.
 */
- (id)copy NS_UNAVAILABLE;

/** Disable this method to make sure the class has only one instance.
 */
- (id)mutableCopy NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
