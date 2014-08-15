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
#import "UAAudioFile.h"
#import <MediaPlayer/MediaPlayer.h>
#import "MarqueeLabel.h"

@protocol UAAudioPlayerControllerDelegate;

@interface UAAudioPlayerController : UIViewController <AVAudioPlayerDelegate, UITableViewDelegate, UITableViewDataSource>
{
	NSMutableArray		*soundFiles;
	NSString			*soundFilesPath;
	NSUInteger			selectedIndex;
	
	AVPlayer		*player;
	
	CAGradientLayer		*gradientLayer;
	
	UIButton			*toggleButton;
	UILabel				*indexLabel;
		
	UIView				*overlayView;
	
	NSTimer				*updateTimer;
	
	BOOL				interrupted;
	BOOL				repeatAll;
	BOOL				repeatOne;
	BOOL				shuffle;
}

@property (nonatomic,assign) id <UAAudioPlayerControllerDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *soundFiles;
@property (nonatomic, copy) NSString *soundFilesPath;

@property (nonatomic, retain) AVPlayer *player;

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
@property (nonatomic, strong) IBOutlet UIButton *artworkView;
@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet MPVolumeView *volumeSlider;

@property (nonatomic, retain) UIView *overlayView;

@property (nonatomic, retain) NSTimer *updateTimer;

@property (nonatomic, assign) BOOL interrupted;
@property (nonatomic, assign) BOOL repeatAll;
@property (nonatomic, assign) BOOL repeatOne;
@property (nonatomic, assign) BOOL shuffle;


+ (UAAudioPlayerController *)sharedInstance;
+ (BOOL) sharedInstanceExist;

- (UAAudioPlayerController *)initWithSoundFiles:(NSMutableArray *)songs atPath:(NSString *)path andSelectedIndex:(int)index;

- (void) setSoundFiles:(NSMutableArray *)songs atPath:(NSString *)path selectedIndex:(int)index;
- (void) setSelectedIndex:(NSUInteger)index;

- (void)dismissAudioPlayer;
- (void)showSongFiles;

- (BOOL)canGoToNextTrack;
- (BOOL)canGoToPreviousTrack;

- (void)play;
- (void)previous;
- (void)next;
- (void)volumeSliderMoved:(UISlider*)sender;
- (IBAction)progressSliderMoved:(UISlider*)sender;

- (void)toggleShuffle;
- (void)toggleRepeat;

@end


@protocol UAAudioPlayerControllerDelegate <NSObject>
@required
@optional
- (void) audioPlayer:(UAAudioPlayerController*)player
     didBeginPlaying:(UAAudioFile*)audio;

- (void) audioPlayer:(UAAudioPlayerController*)player
      didStopPlaying:(UAAudioFile*)audio;

- (void) audioPlayerDidClose:(UAAudioPlayerController*)player;
@end