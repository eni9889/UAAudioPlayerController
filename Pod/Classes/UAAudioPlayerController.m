//
//  AudioPlayer.m
//  MobileTheatre
//
//  Created by Matt Donnelly on 27/03/2010.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "UAAudioPlayerController.h"
#import "UAAudioPlayerTableViewCell.h"

#import <UIImageView+AFNetworking.h>

@interface UIViewController (Modal)
-(BOOL)isModal;
@end

@implementation UIViewController (Modal)

-(BOOL)isModal {
    
    BOOL isModal = NO;
    
    if (!isModal && [self respondsToSelector:@selector(presentingViewController)]) {
        
        isModal = ((self.presentingViewController && self.presentingViewController.presentedViewController == self) ||
                   (self.navigationController && self.navigationController.presentingViewController && self.navigationController.presentingViewController.presentedViewController == self.navigationController) ||
                   [[[self tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]]);
        
    }
    return isModal;        
    
}

@end

@interface UAAVPlayer : AVPlayer

@property (nonatomic, strong) id rateObserveToken;

-(float)duration;
-(BOOL)playing;
-(void)stop;

@end

@implementation UAAVPlayer

-(float)duration {
    return self.currentItem.duration.value / self.currentItem.duration.timescale;
}

-(BOOL)playing {
    return self.currentItem && self.rate != 0;
}

-(void)stop {
    [self pause];
}

@end

@interface UAAudioPlayerController ()
@end

void interruptionListenerCallback (void *userData, UInt32 interruptionState);

@implementation UAAudioPlayerController

static UAAudioPlayerController* _sharedInstance = nil;

@synthesize soundFilesPath;

@synthesize player;
@synthesize gradientLayer;

@synthesize playButton;
@synthesize pauseButton;
@synthesize nextButton;
@synthesize previousButton;
@synthesize toggleButton;
@synthesize repeatButton;
@synthesize shuffleButton;

@synthesize currentTime;
@synthesize itemDuration;
@synthesize indexLabel;
@synthesize marqueeLabel;

@synthesize volumeSlider;
@synthesize progressSlider;

@synthesize songTableView;

@synthesize artworkView;
@synthesize containerView;
@synthesize overlayView;

@synthesize selectedIndex = _selectedIndex;
@synthesize interrupted;
@synthesize repeatAll;
@synthesize repeatOne;
@synthesize shuffle;


+ (UAAudioPlayerController *)sharedInstance {
    @synchronized(self) {
        if (nil == _sharedInstance)
            _sharedInstance = [[UAAudioPlayerController alloc] init];
    }
    return _sharedInstance;
}

+ (BOOL) sharedInstanceExist {
    return (_sharedInstance != nil);
}

-(instancetype)initWithDelegate:(id<UAAudioPlayerDelegate>)aDelegate
                     dataSource:(id<UAAudioPlayerDataSource>)aDataSource {
    if (self = [self init]) {
        self.delegate = aDelegate;
        self.dataSource = aDataSource;
    }
    
    return self;
}

-(instancetype)init {
    if (self = [self initWithNibName:@"UAAudioPlayerController" bundle:nil]) {
        
        _selectedIndex = 0;
        self.player = [[UAAVPlayer alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:[self.player currentItem]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidStartPlaying:)
                                                     name:@"PlaybackStartedNotification"
                                                   object:[self.player currentItem]];
        
        [self.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
        [self.player addObserver:self forKeyPath:@"rate" options: NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
        [self.player addObserver:self forKeyPath:@"currentItem.duration" options: NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
        
        // Declare block scope variables to avoid retention cycles
        // from references inside the block
        __block UAAudioPlayerController *blockSelf = self;
        __block UAAVPlayer* blockPlayer = self.player;
        __block id startObs;
        __block id timeObs;
        
        // Setup boundary time observer to trigger when audio really begins,
        // specifically after 1/3 of a second playback
        startObs = [self.player addBoundaryTimeObserverForTimes:
               @[[NSValue valueWithCMTime:CMTimeMake(1, 3)]]
                                                queue:NULL
                                           usingBlock:^{
                                               
                                               // Raise a notificaiton when playback has started
                                               [[NSNotificationCenter defaultCenter]
                                                postNotificationName:@"PlaybackStartedNotification"
                                                object:nil];

                                           }];
        
        timeObs = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1)
                                                  queue:NULL
                                             usingBlock:^(CMTime time) {
                                                     CMTime endTime = CMTimeConvertScale (blockPlayer.currentItem.asset.duration, blockPlayer.currentTime.timescale, kCMTimeRoundingMethod_RoundHalfAwayFromZero);
                                                     if (CMTimeCompare(endTime, kCMTimeZero) != 0) {
                                                         [blockSelf syncScrubber];
                                                     }
                                                  }];

        
		[self updateViewForPlayerInfo];
		[self updateViewForPlayerState];
    }
    return self;
}


- (CMTime)playerItemDuration {
    AVPlayerItem *thePlayerItem = [self.player currentItem];
    if (thePlayerItem.status == AVPlayerItemStatusReadyToPlay){
        return([thePlayerItem duration]);
    }
    return(kCMTimeInvalid);
}

- (void)syncScrubber
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        self.progressSlider.minimumValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration) && (duration > 0)) {
        float minValue = [ self.progressSlider minimumValue];
        float maxValue = [ self.progressSlider maximumValue];
        
        double time = CMTimeGetSeconds([player currentTime]);
        
        [self.progressSlider setValue:(maxValue - minValue) * time / duration + minValue];
        
        NSString *current = [NSString stringWithFormat:@"%d:%02d", (int) (self.player.currentTime.value/self.player.currentTime.timescale) / 60, (int) (self.player.currentTime.value/self.player.currentTime.timescale) % 60, nil];
        currentTime.text = current;
        [self updateNowPlayingInfoPlaybackTime];
    }
}

- (void)updateViewForPlayerState
{
	NSString *title = [self.dataSource musicPlayer:self titleForTrack:self.selectedIndex];
	NSString *artist = [self.dataSource musicPlayer:self artistForTrack:self.selectedIndex];
	NSString *album = [self.dataSource musicPlayer:self albumForTrack:self.selectedIndex];
    
    self.marqueeLabel.text = [NSString stringWithFormat:@"%@ - %@ - %@", title, artist, album];
	
	[self syncScrubber];
	
    NSLog(@"Current rate: %f", self.player.rate);
	if (self.player.playing) {
        playButton.hidden = YES;
        pauseButton.hidden = NO;
	}
	else {
        pauseButton.hidden = YES;
        playButton.hidden = NO;
	}
	
	if (!self.songTableShowing) {
        [self updateArtworkImage];
	}
    
    [self.songTableView reloadData];
	
	if (repeatOne || repeatAll || shuffle)
		nextButton.enabled = YES;
	else
		nextButton.enabled = [self canGoToNextTrack];
	previousButton.enabled = [self canGoToPreviousTrack];
    
}

-(void)updateArtworkImage {
    if ([self.dataSource respondsToSelector:@selector(musicPlayer:artworkURLForTrack:)]) {
        NSURL *artworkURL = [self.dataSource musicPlayer:self artworkURLForTrack:self.selectedIndex];
        [self.artworkView setImageWithURL:artworkURL placeholderImage:[UIImage imageNamed:@"AudioPlayerNoArtwork"]];
    } else {
        [self.artworkView setImage:[UIImage imageNamed:@"AudioPlayerNoArtwork"]];
    }
    if (self.songTableShowing)
		[self.toggleButton setImage:self.artworkView.image forState:UIControlStateNormal];
		
}

-(void)updateViewForPlayerInfo
{
    float playerDuration = [[self.dataSource audioTrackAtIndex:self.selectedIndex] duration];
    if (self.player.currentItem && !CMTIME_IS_INDEFINITE(self.player.currentItem.duration)) {
        playerDuration = self.player.currentItem.duration.value / self.player.currentItem.duration.timescale;
    }
    
    itemDuration.text = [NSString stringWithFormat:@"%d:%02d", (int)playerDuration / 60, (int)playerDuration % 60, nil];
	indexLabel.text = [NSString stringWithFormat:@"%lu of %lu", (self.selectedIndex + 1), (unsigned long)[self.dataSource numberOfTracksInPlayer:self]];
    
    self.progressSlider.minimumValue = 0.0f;
	self.progressSlider.maximumValue = playerDuration;
}

- (void) setSelectedIndex:(NSUInteger)index {
    if ([self.dataSource numberOfTracksInPlayer:self]<=index)
        return;
    
    _selectedIndex = index;
    self.player.volume = 1.0;
	
	for (UAAudioPlayerTableViewCell *cell in [songTableView visibleCells]) {
		cell.isSelectedIndex = NO;
	}
	
	UAAudioPlayerTableViewCell *cell = (UAAudioPlayerTableViewCell *)[songTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
	cell.isSelectedIndex = YES;
    
    [self playItemAtIndex:self.selectedIndex];
	[self updateViewForPlayerInfo];
	[self updateViewForPlayerState];
    [self updateArtworkImage];
}

- (BOOL)setUpAudioSession
{
    BOOL success = NO;
    NSError *error = nil;
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    success = [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (!success) {
        NSLog(@"%@ Error setting category: %@",
              NSStringFromSelector(_cmd), [error localizedDescription]);
        // Exit early
        return success;
    }
    
    success = [session setActive:YES error:&error];
    if (!success) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    return success;
}

- (BOOL)tearDownAudioSession
{
    NSError *deactivationError = nil;
    BOOL success = [[AVAudioSession sharedInstance] setActive:NO error:&deactivationError];
    if (!success) {
        NSLog(@"%@", [deactivationError localizedDescription]);
    }
    return success;
}

- (void)beginInterruption {
    self.interrupted = YES;
    [self.player pause];
}

- (void)endInterruption {
    self.interrupted = NO;
    if (AVAudioSessionInterruptionOptionShouldResume) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1), dispatch_get_main_queue(), ^{
            [self.player play];
        });
    }
}

- (void) onAudioSessionEvent: (NSNotification *) notification
{
    //Check the type of notification, especially if you are sending multiple AVAudioSession events here
    NSLog(@"Interruption notification name %@", notification.name);
    
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        NSLog(@"Interruption notification received %@!", notification);
        
        //Check to see if it was a Begin interruption
        if ([[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] isEqualToNumber:[NSNumber numberWithInt:AVAudioSessionInterruptionTypeBegan]]) {
            NSLog(@"Interruption began!");
            [self beginInterruption];
            
        } else if([[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] isEqualToNumber:[NSNumber numberWithInt:AVAudioSessionInterruptionTypeEnded]]){
            NSLog(@"Interruption ended!");
            [self endInterruption];
        }
    }
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])  [self setNeedsStatusBarAppearanceUpdate];
    
    if (self.isModal) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                              target:self
                                                                                              action:@selector(dismissAudioPlayer)];
    }
    
    // Set itself as the first responder
    [self becomeFirstResponder];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
	self.view.backgroundColor = [UIColor whiteColor];
    
    // Add a bottomBorder.
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, self.containerView.frame.size.height - 1.0f, self.containerView.frame.size.width, 1.0f);
    bottomBorder.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    [self.containerView.layer addSublayer:bottomBorder];
    
	self.toggleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
	[toggleButton setImage:[UIImage imageNamed:@"player-playlist"] forState:UIControlStateNormal];
	[toggleButton addTarget:self action:@selector(showSongFiles) forControlEvents:UIControlEventTouchUpInside];
	
	UIBarButtonItem *songsListBarButton = [[UIBarButtonItem alloc] initWithCustomView:toggleButton];
	self.navigationItem.rightBarButtonItem = songsListBarButton;
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self setUpAudioSession];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAudioSessionEvent:) name:AVAudioSessionInterruptionNotification object:nil];
	
	self.title = [NSString stringWithFormat:@"%lu of %lu", self.selectedIndex + 1, (unsigned long)[self.dataSource numberOfTracksInPlayer:self]];
    
    self.marqueeLabel.marqueeType = MLContinuous;
    self.marqueeLabel.animationDelay = 0.0f;
    self.marqueeLabel.fadeLength = 10.0f;
    self.marqueeLabel.rate = 50.0f;
    
	itemDuration.adjustsFontSizeToFitWidth = YES;
	currentTime.adjustsFontSizeToFitWidth = YES;
	progressSlider.minimumValue = 0.0;
    
	[previousButton addTarget:self action:@selector(previous) forControlEvents:UIControlEventTouchUpInside];
	previousButton.showsTouchWhenHighlighted = YES;
	previousButton.enabled = [self canGoToPreviousTrack];
    
	[playButton addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
	playButton.showsTouchWhenHighlighted = YES;
    
	[pauseButton addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
	pauseButton.showsTouchWhenHighlighted = YES;
	
	[nextButton addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
	nextButton.showsTouchWhenHighlighted = YES;
	nextButton.enabled = [self canGoToNextTrack];
    
    [repeatButton addTarget:self action:@selector(toggleRepeat) forControlEvents:UIControlEventTouchUpInside];
    [shuffleButton addTarget:self action:@selector(toggleShuffle) forControlEvents:UIControlEventTouchUpInside];
	
    UIImage *minImage = [UIImage imageNamed:@"player_volumeslider_min"];
    UIImage *maxImage = [UIImage imageNamed:@"player_volumeslider_max"];
	
    minImage = [minImage resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 1, 1)];
    maxImage = [maxImage resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 1, 1)];
    
    [self.volumeSlider setMinimumVolumeSliderImage:minImage
                                          forState:UIControlStateNormal];
    [self.volumeSlider setMaximumVolumeSliderImage:maxImage
                                          forState:UIControlStateNormal];
    
    [self.volumeSlider setShowsRouteButton:YES];
    [self.volumeSlider setShowsVolumeSlider:YES];
    
    [progressSlider setThumbImage:[UIImage imageNamed:@"player_progress_thumb"]
                         forState:UIControlStateNormal];
    [progressSlider setMinimumTrackImage:[[UIImage imageNamed:@"player_progress_min"]
                                          stretchableImageWithLeftCapWidth:2 topCapHeight:2] forState:UIControlStateNormal];
    [progressSlider setMaximumTrackImage:[[UIImage imageNamed:@"player_progress_max"]
                                          stretchableImageWithLeftCapWidth:2 topCapHeight:2] forState:UIControlStateNormal];
    
    [progressSlider addTarget:self action:@selector(progressSliderMoved:)
             forControlEvents:UIControlEventValueChanged];
    progressSlider.maximumValue = self.player.duration;
    progressSlider.minimumValue = 0.0;
    
    
	self.songTableView.showsVerticalScrollIndicator = NO;
    
	UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
	v.backgroundColor = [UIColor clearColor];
	[self.songTableView setTableFooterView:v];
    
    [self updateViewForPlayerInfo];
	[self updateViewForPlayerState];
    [self updateArtworkImage];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    
	[self updateViewForPlayerInfo];
	[self updateViewForPlayerState];
    
    
}

- (void)dismissAudioPlayer
{
    if ([self respondsToSelector:@selector(presentingViewController)]){
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    }

}
-(BOOL)songTableShowing {
    return [self.containerView.subviews.lastObject isEqual:self.songTableView];
}

- (void)showSongFiles
{
    
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:.5];
	
	[UIView setAnimationTransition:(self.songTableShowing ? UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
						   forView:self.toggleButton cache:YES];
	
    if (self.songTableShowing)
		[self.toggleButton setImage:[UIImage imageNamed:@"player-playlist"] forState:UIControlStateNormal];
	else
		[self.toggleButton setImage:self.artworkView.image forState:UIControlStateNormal];
	
	[UIView commitAnimations];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:.5];
	
	[UIView setAnimationTransition:(self.songTableShowing ? UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
						   forView:self.containerView cache:YES];
	
    if (self.songTableShowing) {
		[self.containerView sendSubviewToBack:self.songTableView];
	}
	else {
		[self.containerView sendSubviewToBack:self.artworkView];
	}
	
	[UIView commitAnimations];
}

- (void)toggleShuffle
{
	if (shuffle)
	{
		shuffle = NO;
		[shuffleButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"player-shuffle-off" ofType:@"png"]] forState:UIControlStateNormal];
	}
	else
	{
		shuffle = YES;
		[shuffleButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"player-shuffle-on" ofType:@"png"]] forState:UIControlStateNormal];
	}
	
	[self updateViewForPlayerInfo];
	[self updateViewForPlayerState];
}

- (void)toggleRepeat
{
	if (repeatOne)
	{
		[repeatButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"player-repeat-none" ofType:@"png"]]
					  forState:UIControlStateNormal];
		repeatOne = NO;
		repeatAll = NO;
	}
	else if (repeatAll)
	{
		[repeatButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"player-repeat-one" ofType:@"png"]]
					  forState:UIControlStateNormal];
		repeatOne = YES;
		repeatAll = NO;
	}
	else
	{
		[repeatButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"player-repeat-all" ofType:@"png"]]
					  forState:UIControlStateNormal];
		repeatOne = NO;
		repeatAll = YES;
	}
	
	[self updateViewForPlayerInfo];
	[self updateViewForPlayerState];
}

- (BOOL)canGoToNextTrack
{
    if (repeatOne || repeatAll || shuffle) {
        return YES;
    }
	else if (self.selectedIndex + 1 == [self.dataSource numberOfTracksInPlayer:self])
		return NO;
	else
		return YES;
}

- (BOOL)canGoToPreviousTrack
{
	if (self.selectedIndex == 0)
		return NO;
	else
		return YES;
}

-(void)play
{
    if (self.player.currentItem == nil && [self.dataSource numberOfTracksInPlayer:self] > 0) {
        
        [self playItemAtIndex:self.selectedIndex];
        if ([_delegate respondsToSelector:@selector(musicPlayer:didChangeTrack:)]) {
            [_delegate musicPlayer:self didChangeTrack:self.selectedIndex];
        }
        
    } else if (self.player.playing == YES)  {
		[self.player pause];
        if([_delegate respondsToSelector:@selector(musicPlayerDidStopPlaying:)]) {
            [_delegate musicPlayerDidStopPlaying:self];
        }
	}
	else {
		
        [self.player play];
        if([_delegate respondsToSelector:@selector(musicPlayerDidStartPlaying:)]) {
            [_delegate musicPlayerDidStartPlaying:self];
        }
	}
	
	[self updateViewForPlayerInfo];
	[self updateViewForPlayerState];
    
}

- (void)previous
{
	NSUInteger newIndex = self.selectedIndex - 1;
	self.selectedIndex = newIndex;
    
    [self playItemAtIndex:self.selectedIndex];
	
	[self updateViewForPlayerInfo];
	[self updateViewForPlayerState];
}

- (void)next
{
	NSUInteger newIndex;
	
	if (shuffle) {
		newIndex = rand() % [self.dataSource numberOfTracksInPlayer:self];
	}
	else if (repeatOne) {
		newIndex = self.selectedIndex;
	}
	else if (repeatAll) {
		if (self.selectedIndex + 1 == [self.dataSource numberOfTracksInPlayer:self])
			newIndex = 0;
		else
			newIndex = self.selectedIndex + 1;
	}
	else{
		newIndex = self.selectedIndex + 1;
	}
	
	self.selectedIndex = newIndex;
    
    [self playItemAtIndex:self.selectedIndex];
}

-(void)playItemAtIndex:(NSUInteger)aSelectedIndex {
    
    if([_delegate respondsToSelector:@selector(musicPlayerDidStopPlaying:)]) {
        [_delegate musicPlayerDidStopPlaying:self];
    }
    
    AVPlayerItem *newItem = [[AVPlayerItem alloc] initWithURL:[[self.dataSource audioTrackAtIndex:self.selectedIndex] filePath]];
    [self.player replaceCurrentItemWithPlayerItem:newItem];
    [self.player play];
    
    if([_delegate respondsToSelector:@selector(musicPlayerDidStartPlaying:)]) {
        [_delegate musicPlayerDidStartPlaying:self];
    }
    
    [self updateViewForPlayerInfo];
	[self updateViewForPlayerState];
    [self initNowPlayingInfoForNewTrack];
}

- (void)volumeSliderMoved:(UISlider *)sender
{
	player.volume = [sender value];
	[[NSUserDefaults standardUserDefaults] setFloat:[sender value] forKey:@"PlayerVolume"];
}

- (IBAction)progressSliderMoved:(UISlider *)sender
{
    [self.player seekToTime:CMTimeMake(sender.value, 1)];
	[self syncScrubber];
}


#pragma mark -
#pragma mark AVPlayer delegate


- (void)audioPlayerDidFinishPlaying:(AVPlayer *)p successfully:(BOOL)flag
{
	if (flag == NO)
		NSLog(@"Playback finished unsuccessfully");
	
	if ([self canGoToNextTrack]) {
        [self next];
    } else if (interrupted) {
		[self.player play];
        if([_delegate respondsToSelector:@selector(musicPlayerDidStartPlaying:)]) {
            [_delegate musicPlayerDidStartPlaying:self];
        }
    } else {
		[self.player stop];
    }
    
	[self updateViewForPlayerInfo];
	[self updateViewForPlayerState];
}

- (void)playerDecodeErrorDidOccur:(AVPlayer *)p error:(NSError *)error
{
	NSLog(@"ERROR IN DECODE: %@\n", error);
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Decode Error"
														message:[NSString stringWithFormat:@"Unable to decode audio file with error: %@", [error localizedDescription]]
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
	[alertView show];
}

- (void)audioPlayerBeginInterruption:(AVPlayer *)player
{
	// perform any interruption handling here
	printf("(apbi) Interruption Detected\n");
	[[NSUserDefaults standardUserDefaults] setFloat:self.player.currentTime.value / self.player.currentTime.timescale forKey:@"Interruption"];
}

- (void)audioPlayerEndInterruption:(AVPlayer *)player
{
	// resume playback at the end of the interruption
	printf("(apei) Interruption ended\n");
	[self.player play];
    
    if([_delegate respondsToSelector:@selector(musicPlayerDidStartPlaying:)]) {
        [_delegate musicPlayerDidStartPlaying:self];
    }
    
	// remove the interruption key. it won't be needed
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Interruption"];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource numberOfTracksInPlayer:self];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UAAudioPlayerTableViewCell *cell = (UAAudioPlayerTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UAAudioPlayerTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
	}
    
    NSURL *artworkURL = [self.dataSource musicPlayer:self artworkURLForTrack:indexPath.row];
    [[cell imageView] setImageWithURL:artworkURL  placeholderImage:[UIImage imageNamed:@"AudioPlayerNoArtwork"]];
	
	cell.textLabel.text = [self.dataSource musicPlayer:self titleForTrack:indexPath.row];
    cell.detailTextLabel.text = [self.dataSource musicPlayer:self artistForTrack:indexPath.row];
    
    
	if (self.selectedIndex == indexPath.row)
		cell.isSelectedIndex = YES;
	else
		cell.isSelectedIndex = NO;
    
    if (self.selectedIndex == indexPath.row) {
        self.player.playing ? [cell setTrackState:NAKPlaybackIndicatorViewStatePlaying] : [cell setTrackState:NAKPlaybackIndicatorViewStatePaused];
    } else {
        [cell setTrackState:NAKPlaybackIndicatorViewStateStopped];
    }
	
	return cell;
}


- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	
	self.selectedIndex = indexPath.row;
	
	for (UAAudioPlayerTableViewCell *cell in [aTableView visibleCells]) {
		cell.isSelectedIndex = NO;
	}
	
	UAAudioPlayerTableViewCell *cell = (UAAudioPlayerTableViewCell *)[aTableView cellForRowAtIndexPath:indexPath];
	cell.isSelectedIndex = YES;
	
    [self playItemAtIndex:self.selectedIndex];
	
	[self updateViewForPlayerInfo];
	[self updateViewForPlayerState];
}

- (BOOL)tableView:(UITableView *)table canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}


- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44;
}

- (UIModalPresentationStyle) modalPresentationStyle {
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 30200)
    if ([[UIDevice currentDevice] respondsToSelector: @selector(userInterfaceIdiom)])
        return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? UIModalPresentationFormSheet : UIModalPresentationCurrentContext;
#endif
    return UIModalPresentationCurrentContext;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)beginSeekingForward
{
    [self.player setRate:2.0f];
    [self updateNowPlayingInfoPlaybackRate:@(2.0f)];
}

- (void)beginSeekingBackward
{
    [self.player setRate:-2.0f];
    [self updateNowPlayingInfoPlaybackRate:@(-2.0f)];
}

- (void)endSeeking
{
    [self play];
    [self updateNowPlayingInfoPlaybackRate:@(1.0f)];
}

- (void)seekToBeginning
{
    [self.player seekToTime:CMTimeMake(0, 1)];
}

/**
 * Keeps the MPNowPlayingInfoPropertyPlaybackRate and MPNowPlayingInfoPropertyElapsedPlaybackTime properties in sync when playback rate is changed.
 *
 * @param playbackRate The new playback rate of the AVPlayer.
 */
- (void)updateNowPlayingInfoPlaybackRate:(NSNumber *)playbackRate
{
    MPNowPlayingInfoCenter *playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionaryWithDictionary:playingInfoCenter.nowPlayingInfo];
    [nowPlayingInfo setObject:playbackRate forKey:MPNowPlayingInfoPropertyPlaybackRate];
    [playingInfoCenter setNowPlayingInfo:nowPlayingInfo];
}

/**
 * Keeps the MPNowPlayingInfoPropertyElapsedPlaybackTime properties in sync.
 */
- (void)updateNowPlayingInfoPlaybackTime
{
    MPNowPlayingInfoCenter *playingInfoCenter = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary *nowPlayingInfo = [NSMutableDictionary dictionaryWithDictionary:playingInfoCenter.nowPlayingInfo];
    [nowPlayingInfo setObject:@(self.player.currentTime.value / self.player.currentTime.timescale) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [playingInfoCenter setNowPlayingInfo:nowPlayingInfo];
}

-(void)initNowPlayingInfoForNewTrack {
    
    if ([MPNowPlayingInfoCenter class] && [self.dataSource numberOfTracksInPlayer:self] > 0 ) {
        /* we're on iOS 5, so set up the now playing center */
        UAAudioFile *soundFile = [self.dataSource audioTrackAtIndex:self.selectedIndex];
        
        NSMutableDictionary *currentlyPlayingTrackInfo = [NSMutableDictionary dictionary];
        [currentlyPlayingTrackInfo setObject:[soundFile title] forKey:MPMediaItemPropertyTitle];
        [currentlyPlayingTrackInfo setObject:[soundFile artist] forKey:MPMediaItemPropertyArtist];
        [currentlyPlayingTrackInfo setObject:[NSNumber numberWithFloat:[soundFile duration]] forKey:MPMediaItemPropertyPlaybackDuration];
        [currentlyPlayingTrackInfo setObject:[NSNumber numberWithFloat:self.player.rate] forKey:MPNowPlayingInfoPropertyPlaybackRate];
        [currentlyPlayingTrackInfo setObject:[NSNumber numberWithFloat:self.player.currentTime.value / self.player.currentTime.timescale] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        
        if ([soundFile coverImage]) {
            MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:[soundFile coverImage]];
            [currentlyPlayingTrackInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
        }
        
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = currentlyPlayingTrackInfo;
    }
}

//Make sure we can recieve remote control events
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    //if it is a remote control event handle it correctly
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlPlay:
                [self play];
                break;
                
            case UIEventSubtypeRemoteControlPause:
                [self play];
                break;
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [self play];
                break;
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                if ([self canGoToPreviousTrack]) [self previous];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                if ([self canGoToNextTrack]) [self next];
                break;
                
            case UIEventSubtypeRemoteControlBeginSeekingBackward:
                [self beginSeekingBackward];
                break;
            case UIEventSubtypeRemoteControlEndSeekingBackward:
                [self endSeeking];
                break;
            case UIEventSubtypeRemoteControlBeginSeekingForward:
                [self beginSeekingForward];
                break;
            case UIEventSubtypeRemoteControlEndSeekingForward:
                [self endSeeking];
                
            default:
                break;
        }
    }
}

#pragma mark - AudioPlayer KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"%s: %@ change: %@", __func__, keyPath, change);
    
    if (object == self.player && [keyPath isEqualToString:@"status"]) {
        
        switch (self.player.status) {
            case AVPlayerStatusFailed:
                NSLog(@"AVPlayerStatusFailed");
                break;
            case AVPlayerStatusReadyToPlay:
                NSLog(@"AVPlayerStatusReadyToPlay");
                [self.player play];
                break;
            default:
                 NSLog(@"AVPlayerItemStatusUnknown");
                break;
        }
        
        [self updateViewForPlayerInfo];
		[self updateViewForPlayerState];
    }
}

-(void)playerItemDidStartPlaying:(NSNotification *)notification {
    NSLog(@"%s: %@", __func__, notification);
    
    [self updateViewForPlayerInfo];
    [self updateViewForPlayerState];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    
	if ([self canGoToNextTrack]) {
        [self next];
    } else if (interrupted) {
		[self.player play];
        if([_delegate respondsToSelector:@selector(musicPlayerDidStartPlaying:)]) {
            [_delegate musicPlayerDidStartPlaying:self];
        }
    } else {
		[self.player stop];
    }
    
	[self updateViewForPlayerInfo];
	[self updateViewForPlayerState];
}

@end
