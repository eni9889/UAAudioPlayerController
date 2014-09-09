//
//  AudioPlayer.h
//  MobileTheatre
//
//  Created by Matt Donnelly on 27/03/2010.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>

#import "UAAudioPlayerDataSource.h"
#import "UAAudioPlayerDelegate.h"
#import "UAAudioFile.h"
#import "MarqueeLabel.h"

@protocol UAAudioPlayerControllerDelegate;
@class UAAVPlayer;

@interface UAAudioPlayerController : UIViewController <AVAudioPlayerDelegate, UITableViewDelegate, UITableViewDataSource>
{
	NSString			*soundFilesPath;
    
	CAGradientLayer		*gradientLayer;
	
	UIButton			*toggleButton;
	UILabel				*indexLabel;
		
	UIView				*overlayView;
		
	BOOL				interrupted;
	BOOL				repeatAll;
	BOOL				repeatOne;
	BOOL				shuffle;
}

/// The UAAudioPlayerDelegate object that acts as the delegate of the receiving music player.
@property (nonatomic,assign) id<UAAudioPlayerDelegate> delegate;

/// The UAAudioPlayerDataSource object that acts as the data source of the receiving music player.
@property (nonatomic,assign) id<UAAudioPlayerDataSource> dataSource;

@property (nonatomic, copy) NSString *soundFilesPath;

@property (nonatomic, strong) UAAVPlayer *player;

@property (nonatomic, retain) CAGradientLayer *gradientLayer;

@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) IBOutlet UIButton *pauseButton;
@property (nonatomic, retain) IBOutlet UIButton *nextButton;
@property (nonatomic, retain) IBOutlet UIButton *previousButton;
@property (nonatomic, retain) IBOutlet UIButton *toggleButton;
@property (nonatomic, retain) IBOutlet UIButton *repeatButton;
@property (nonatomic, retain) IBOutlet UIButton *shuffleButton;

@property (nonatomic, retain) IBOutlet UILabel *currentTime;
@property (nonatomic, retain) IBOutlet UILabel *itemDuration;

@property (nonatomic, retain) UILabel *indexLabel;;
@property (nonatomic, retain) IBOutlet MarqueeLabel *marqueeLabel;


@property (nonatomic, strong) IBOutlet UISlider *progressSlider;
@property (nonatomic, strong) IBOutlet UITableView *songTableView;
@property (nonatomic, strong) IBOutlet UIImageView *artworkView;
@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet MPVolumeView *volumeSlider;

@property (nonatomic, retain) UIView *overlayView;

@property (nonatomic, assign) NSUInteger selectedIndex;
@property (nonatomic, assign) BOOL interrupted;
@property (nonatomic, assign) BOOL repeatAll;
@property (nonatomic, assign) BOOL repeatOne;
@property (nonatomic, assign) BOOL shuffle;


+ (UAAudioPlayerController *)sharedInstance;
+ (BOOL) sharedInstanceExist;

-(instancetype)initWithDelegate:(id<UAAudioPlayerDelegate>)aDelegate
                     dataSource:(id<UAAudioPlayerDataSource>)aDataSource;

- (void) setSelectedIndex:(NSUInteger)index;

- (void)dismissAudioPlayer;
- (void)showSongFiles;

- (BOOL)isPlaying;
- (BOOL)canGoToNextTrack;
- (BOOL)canGoToPreviousTrack;

- (void)play;
- (void)previous;
- (void)next;
- (void)volumeSliderMoved:(UISlider*)sender;
- (IBAction)progressSliderMoved:(UISlider*)sender;

- (void)toggleShuffle;
- (void)toggleRepeat;

- (void)reloadTracks;
- (void)destructPlayer;

@end