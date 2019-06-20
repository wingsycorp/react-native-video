//
//  RCTVideoAdsManager.m
//  react-native-video
//
//  Created by Jens Andersson on 20/06/2019.
//

#import "RCTVideoAdsManager.h"

@interface RCTVideoAdsManager () <IMAAdsLoaderDelegate, IMAAdsManagerDelegate>


/// Content video player.
@property(nonatomic, weak) RCTVideo *video;

/// Content video player.
@property(nonatomic, weak) AVPlayer *player;

// SDK
/// Entry point for the SDK. Used to make ad requests.
@property(nonatomic, strong) IMAAdsLoader *adsLoader;

/// Playhead used by the SDK to track content video progress and insert mid-rolls.
@property(nonatomic, strong) IMAAVPlayerContentPlayhead *contentPlayhead;

/// Main point of interaction with the SDK. Created by the SDK as the result of an ad request.
@property(nonatomic, strong) IMAAdsManager *adsManager;

@end

@implementation RCTVideoAdsManager

// Ad tag
NSString *const kTestAppAdTagUrl = @"https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&"
@"iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&"
@"output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&"
@"correlator=";

- (instancetype)initWithVideo: (RCTVideo *)video player: (AVPlayer *)player {
  self = [super init];
  if(self) {
    self.player = player;
    self.video = video;
    // Set up our content playhead and contentComplete callback.
    self.contentPlayhead = [[IMAAVPlayerContentPlayhead alloc] initWithAVPlayer:self.player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.player.currentItem];
    [self setupAdsLoader];
  }

  return self;
}

#pragma mark SDK Setup

- (void)setupAdsLoader {
  self.adsLoader = [[IMAAdsLoader alloc] initWithSettings:nil];
  self.adsLoader.delegate = self;
}

- (void)requestAds {
  // Create an ad display container for ad rendering.
  IMAAdDisplayContainer *adDisplayContainer =
  [[IMAAdDisplayContainer alloc] initWithAdContainer:self.video companionSlots:nil];
  // Create an ad request with our ad tag, display container, and optional user context.
  IMAAdsRequest *request = [[IMAAdsRequest alloc] initWithAdTagUrl:kTestAppAdTagUrl
                                                adDisplayContainer:adDisplayContainer
                                                   contentPlayhead:self.contentPlayhead
                                                       userContext:nil];
  [self.adsLoader requestAdsWithRequest:request];
}

- (void)contentDidFinishPlaying:(NSNotification *)notification {
  // Make sure we don't call contentComplete as a result of an ad completing.
  if (notification.object == self.player.currentItem) {
    [self.adsLoader contentComplete];
  }
}

#pragma mark AdsLoader Delegates

- (void)adsLoader:(IMAAdsLoader *)loader adsLoadedWithData:(IMAAdsLoadedData *)adsLoadedData {
  // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
  self.adsManager = adsLoadedData.adsManager;
  self.adsManager.delegate = self;
  // Create ads rendering settings to tell the SDK to use the in-app browser.
  IMAAdsRenderingSettings *adsRenderingSettings = [[IMAAdsRenderingSettings alloc] init];
//  adsRenderingSettings.webOpenerPresentingController = self;
  // Initialize the ads manager.
  [self.adsManager initializeWithAdsRenderingSettings:adsRenderingSettings];
}

- (void)adsLoader:(IMAAdsLoader *)loader failedWithErrorData:(IMAAdLoadingErrorData *)adErrorData {
  // Something went wrong loading ads. Log the error and play the content.
  NSLog(@"Error loading ads: %@", adErrorData.adError.message);
  [self.player play];
}

#pragma mark AdsManager Delegates

- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdEvent:(IMAAdEvent *)event {
  // When the SDK notified us that ads have been loaded, play them.
  NSLog(@"%ld", (long)event.type);
  if (event.type == kIMAAdEvent_LOADED) {
    [adsManager start];
    
  }
}

- (void)adsManager:(IMAAdsManager *)adsManager didReceiveAdError:(IMAAdError *)error {
  // Something went wrong with the ads manager after ads were loaded. Log the error and play the
  // content.
  NSLog(@"AdsManager error: %@", error.message);
  [self.player play];
}

- (void)adsManagerDidRequestContentPause:(IMAAdsManager *)adsManager {
  // The SDK is going to play ads, so pause the content.
  [self.player pause];
}

- (void)adsManagerDidRequestContentResume:(IMAAdsManager *)adsManager {
  // The SDK is done playing ads (at least for now), so resume the content.
  [self.player play];
}


@end
