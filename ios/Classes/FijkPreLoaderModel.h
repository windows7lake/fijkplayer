//
//  NSObject+FijkPreLoaderModel.h
//  fijkplayer
//
//  Created by ying lin on 2021/12/30.
//

#import <Foundation/Foundation.h>
#import <KTVHTTPCache/KTVHCDataLoader.h>

NS_ASSUME_NONNULL_BEGIN

@interface FijkPreLoaderModel : NSObject

/// 加载的URL
@property (nonatomic, copy, readonly) NSString *url;
/// 请求URL的Loader
@property (nonatomic, strong, readonly) KTVHCDataLoader *loader;

- (instancetype)initWithURL: (NSString *)url loader: (KTVHCDataLoader *)loader;

@end

NS_ASSUME_NONNULL_END
