//
//  RCTVideoAdsManager.h
//  react-native-video
//
//  Created by Jens Andersson on 20/06/2019.
//

#import <Foundation/Foundation.h>
#import "RCTVideo.h"
@import GoogleInteractiveMediaAds;

NS_ASSUME_NONNULL_BEGIN

@interface RCTVideoAdsManager : NSObject

- (instancetype)initWithVideo: (RCTVideo *)video player: (AVPlayer *)player;
- (void)requestAds;

@end

NS_ASSUME_NONNULL_END
