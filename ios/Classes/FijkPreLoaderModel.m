//
//  NSObject+FijkPreLoaderModel.m
//  fijkplayer
//
//  Created by ying lin on 2021/12/30.
//

#import "FijkPreLoaderModel.h"

@implementation FijkPreLoaderModel

- (instancetype)initWithURL: (NSString *)url loader: (KTVHCDataLoader *)loader {
    if (self = [super init])
    {
        _url = url;
        _loader = loader;
    }
    return self;
}

@end
