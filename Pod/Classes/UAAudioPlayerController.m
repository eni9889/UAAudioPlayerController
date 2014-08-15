//
//  AudioPlayer.m
//  MobileTheatre
//
//  Created by Matt Donnelly on 27/03/2010.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "UAAudioPlayerController.h"
#import "UAAudioPlayerTableViewCell.h"


@interface AVPlayer (UAAdditions)

-(float)duration;
-(BOOL)playing;
-(void)stop;

@end

@implementation AVPlayer (UAAdditions)

-(float)duration {
    return self.currentItem.duration.value / self.currentItem.duration.timescale;
}

-(BOOL)playing {
    return self.currentItem && self.rate > 0;
}

-(void)stop {
    [self pause];
}

@end

@interface UAAudioPlayerController ()
- (UIImage *)reflectedImage:(UIButton *)fromImage withHeight:(NSUInteger)height;
@end

void interruptionListenerCallback (void *userData, UInt32 interruptionState);

@implementation UAAudioPlayerController

static UAAudioPlayerController* _sharedInstance = nil;

@synthesize soundFiles;
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

@synthesize updateTimer;

@synthesize interrupted;
@synthesize repeatAll;
@synthesize repeatOne;
@synthesize shuffle;


+ (UAAudioPlayerController *)sharedInstance {
    @synchronized(self) {
        if (nil == _sharedInstance)
            _sharedInstance = [[UAAudioPlayerController alloc] initWithSoundFiles:nil atPath:@"/" andSelectedIndex:0];
    }
    return _sharedInstance;
}
+ (BOOL) sharedInstanceExist {
    return (_sharedInstance != nil);
}

void interruptionListenerCallback (void *userData, UInt32 interruptionState)
{
	UAAudioPlayerController *vc = (__bridge UAAudioPlayerController *)userData;
	if (interruptionState == kAudioSessionBeginInterruption)
		vc.interrupted = YES;
	else if (interruptionState == kAudioSessionEndInterruption)
		vc.interrupted = NO;
}

- (void)updateCurrentTime {
    NSString *current = [NSString stringWithFormat:@"%d:%02d", (int) (self.player.currentTime.value/self.player.currentTime.timescale) / 60, (int) (self.player.currentTime.value/self.player.currentTime.timescale) % 60, nil];
	NSString *dur = [NSString stringWithFormat:@"-%d:%02d", (int)((int)(self.player.duration -  (self.player.currentTime.value/self.player.currentTime.timescale))) / 60, (int)((int)(self.player.duration -  (self.player.currentTime.value/self.player.currentTime.timescale))) % 60, nil];
	
    itemDuration.text = dur;
	currentTime.text = current;
    
	self.progressSlider.value =  (self.player.currentTime.value/self.player.currentTime.timescale);
}

- (void)updateViewForPlayerState:(AVPlayer *)p
{
	NSString *title = [[soundFiles objectAtIndex:selectedIndex] title];
	NSString *artist = [[soundFiles objectAtIndex:selectedIndex] artist];
	NSString *album = [[soundFiles objectAtIndex:selectedIndex] album];
    
    self.marqueeLabel.text = [NSString stringWithFormat:@"%@ - %@ - %@", title, artist, album];
	
	[self updateCurrentTime];
	
	if (updateTimer)
		[updateTimer invalidate];
	
	if (self.player.playing) {
        playButton.hidden = YES;
        pauseButton.hidden = NO;
		self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateCurrentTime) userInfo:p repeats:YES];
	}
	else {
        pauseButton.hidden = YES;
        playButton.hidden = NO;
        
        updateTimer = nil;
	}
	
	if (![songTableView superview])
	{
        NSLog(@"%s: %@ %lu",__func__,artworkView,artworkView.state);
        [self.artworkView setImage:nil forState:UIControlStateNormal];
        UIImage *coverImage = [[soundFiles objectAtIndex:selectedIndex] coverImage];
		[self.artworkView setImage:coverImage forState:UIControlStateNormal];
	}
    
    [self.songTableView reloadData];
	
	if (repeatOne || repeatAll || shuffle)
		nextButton.enabled = YES;
	else
		nextButton.enabled = [self canGoToNextTrack];
	previousButton.enabled = [self canGoToPreviousTrack];
    
    if ([MPNowPlayingInfoCenter class] && [soundFiles count] >0 )
    {
        /* we're on iOS 5, so set up the now playing center */
        UAAudioFile *soundFile = [soundFiles objectAtIndex:selectedIndex];
        
        NSMutableDictionary *currentlyPlayingTrackInfo = [NSMutableDictionary dictionary];
        [currentlyPlayingTrackInfo setObject:[soundFile title] forKey:MPMediaItemPropertyTitle];
        [currentlyPlayingTrackInfo setObject:[soundFile artist] forKey:MPMediaItemPropertyArtist];
        [currentlyPlayingTrackInfo setObject:[NSNumber numberWithFloat:[soundFile duration]] forKey:MPMediaItemPropertyPlaybackDuration];
        [currentlyPlayingTrackInfo setObject:[NSNumber numberWithInt:1] forKey:MPNowPlayingInfoPropertyPlaybackRate];
        
        if ([[soundFiles objectAtIndex:selectedIndex] coverImage])
        {
            MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:[soundFile coverImage]];
            [currentlyPlayingTrackInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
        }
        
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = currentlyPlayingTrackInfo;
    }
}

-(void)updateViewForPlayerInfo:(AVPlayer*)p
{
    float playerDuration = self.player.currentItem.duration.value / self.player.currentItem.duration.timescale;
	itemDuration.text = [NSString stringWithFormat:@"%d:%02d", (int)playerDuration / 60, (int)playerDuration % 60, nil];
	indexLabel.text = [NSString stringWithFormat:@"%lu of %lu", (selectedIndex + 1), (unsigned long)[soundFiles count]];
    self.progressSlider.minimumValue = 0.0f;
	self.progressSlider.maximumValue = playerDuration;
}

- (UAAudioPlayerController *)initWithSoundFiles:(NSMutableArray *)songs atPath:(NSString *)path andSelectedIndex:(int)index
{
	if (self = [super initWithNibName:@"UAAudioPlayerController" bundle:nil])
	{
		self.soundFiles = songs;
		self.soundFilesPath = path;
		selectedIndex = index;
        
		NSError *error = nil;
        
		self.player = [[AVPlayer alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:[self.player currentItem]];
        
        [self.player addObserver:self forKeyPath:@"status" options:0 context:nil];
        [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
        [self.player addObserver:self forKeyPath:@"currentItem.duration" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
        
		[self updateViewForPlayerInfo:player];
		[self updateViewForPlayerState:player];
		
		if (error)
			NSLog(@"%@", error);
	}
	
	return self;
}

- (void) setSoundFiles:(NSMutableArray *)songs atPath:(NSString *)path selectedIndex:(int)index {
    
    self.soundFiles = songs;
    self.soundFilesPath = path;
    self.selectedIndex = index;
    self.player.volume = 1.0;
    
    [self playItemAtIndex:selectedIndex];
    
    [self.songTableView reloadData];
    
    [self updateViewForPlayerInfo:player];
    [self updateViewForPlayerState:player];
    
}

- (void) setSelectedIndex:(NSUInteger)index {
    if ([soundFiles count]<=index)
        return;
    
    self.selectedIndex = index;
    self.player.volume = 1.0;
	
	for (UAAudioPlayerTableViewCell *cell in [songTableView visibleCells]) {
		cell.isSelectedIndex = NO;
	}
	
	UAAudioPlayerTableViewCell *cell = (UAAudioPlayerTableViewCell *)[songTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
	cell.isSelectedIndex = YES;
    
    [self playItemAtIndex:selectedIndex];
    
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])  [self setNeedsStatusBarAppearanceUpdate];
    
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
    
	updateTimer = nil;
	
	self.toggleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
	[toggleButton setImage:[UIImage imageNamed:@"player-playlist"] forState:UIControlStateNormal];
	[toggleButton addTarget:self action:@selector(showSongFiles) forControlEvents:UIControlEventTouchUpInside];
	
	UIBarButtonItem *songsListBarButton = [[UIBarButtonItem alloc] initWithCustomView:toggleButton];
	self.navigationItem.rightBarButtonItem = songsListBarButton;
	
	AudioSessionInitialize(NULL, NULL, interruptionListenerCallback, (__bridge void *)(self));
	AudioSessionSetActive(true);
	UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
	
	UAAudioFile *selectedSong = [self.soundFiles objectAtIndex:selectedIndex];
	self.title = [NSString stringWithFormat:@"%lu of %lu", selectedIndex + 1, (unsigned long)self.soundFiles.count];
    
    self.marqueeLabel.marqueeType = MLContinuous;
    self.marqueeLabel.animationDelay = 0.0f;
    self.marqueeLabel.fadeLength = 10.0f;
    self.marqueeLabel.rate = 50.0f;
    
	itemDuration.adjustsFontSizeToFitWidth = YES;
	currentTime.adjustsFontSizeToFitWidth = YES;
	progressSlider.minimumValue = 0.0;
    
    [artworkView setImage:[selectedSong coverImage] forState:UIControlStateNormal];
    
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
    
    [self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
    
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
    
	[player play];
    
    if([_delegate respondsToSelector:@selector(audioPlayer:didBeginPlaying:)]) {
        UAAudioFile* curr = (UAAudioFile *)[soundFiles objectAtIndex:selectedIndex];
        [_delegate audioPlayer:self didBeginPlaying:curr];
    }
	
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
    
    
}

- (void)dismissAudioPlayer
{
    if ([self respondsToSelector:@selector(presentingViewController)]){
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    }
    
    if([_delegate respondsToSelector:@selector(audioPlayerDidClose:)]) {
        [_delegate audioPlayerDidClose:self];
    }
}

- (void)showSongFiles
{
    BOOL songTableShowing = [self.containerView.subviews.lastObject isEqual:self.songTableView];
    
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:.5];
	
	[UIView setAnimationTransition:(songTableShowing ? UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
						   forView:self.toggleButton cache:YES];
	
    if (songTableShowing)
		[self.toggleButton setImage:[UIImage imageNamed:@"player-playlist"] forState:UIControlStateNormal];
	else
		[self.toggleButton setImage:self.artworkView.imageView.image forState:UIControlStateNormal];
	
	[UIView commitAnimations];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:.5];
	
	[UIView setAnimationTransition:(songTableShowing ? UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
						   forView:self.containerView cache:YES];
	
    if (songTableShowing) {
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
	
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
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
	
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
}

- (BOOL)canGoToNextTrack
{
    if (repeatOne || repeatAll || shuffle) {
        return YES;
    }
	else if (selectedIndex + 1 == [self.soundFiles count])
		return NO;
	else
		return YES;
}

- (BOOL)canGoToPreviousTrack
{
	if (selectedIndex == 0)
		return NO;
	else
		return YES;
}

-(void)play
{
    if (self.player.currentItem == nil && self.soundFiles.count > 0) {
        [self playItemAtIndex:selectedIndex];
    } else if (self.player.playing == YES)  {
		[self.player pause];
	}
	else {
		[self.player play];
	}
	
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
    
}

- (void)previous
{
	NSUInteger newIndex = selectedIndex - 1;
	selectedIndex = newIndex;
    
    [self playItemAtIndex:selectedIndex];
    
    if([_delegate respondsToSelector:@selector(audioPlayer:didStopPlaying:)]) {
        UAAudioFile* curr = (UAAudioFile *)[soundFiles objectAtIndex:selectedIndex];
        [_delegate audioPlayer:self didStopPlaying:curr];
    }
    
    if([_delegate respondsToSelector:@selector(audioPlayer:didBeginPlaying:)]) {
        UAAudioFile* curr = (UAAudioFile *)[soundFiles objectAtIndex:selectedIndex];
        [_delegate audioPlayer:self didBeginPlaying:curr];
    }
	
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
}

- (void)next
{
	NSUInteger newIndex;
	
	if (shuffle)
	{
		newIndex = rand() % [soundFiles count];
	}
	else if (repeatOne)
	{
		newIndex = selectedIndex;
	}
	else if (repeatAll)
	{
		if (selectedIndex + 1 == [self.soundFiles count])
			newIndex = 0;
		else
			newIndex = selectedIndex + 1;
	}
	else
	{
		newIndex = selectedIndex + 1;
	}
	
	selectedIndex = newIndex;
    
    [self playItemAtIndex:selectedIndex];
	
    if([_delegate respondsToSelector:@selector(audioPlayer:didStopPlaying:)]) {
        UAAudioFile* curr = (UAAudioFile *)[soundFiles objectAtIndex:selectedIndex];
        [_delegate audioPlayer:self didStopPlaying:curr];
    }
    
    if([_delegate respondsToSelector:@selector(audioPlayer:didBeginPlaying:)]) {
        UAAudioFile* curr = (UAAudioFile *)[soundFiles objectAtIndex:selectedIndex];
        [_delegate audioPlayer:self didBeginPlaying:curr];
    }
	
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
}

-(void)playItemAtIndex:(NSUInteger)aSelectedIndex {
    [self.player pause];
    
    AVPlayerItem *newItem = [[AVPlayerItem alloc] initWithURL:[(UAAudioFile *)[soundFiles objectAtIndex:aSelectedIndex] filePath]];
    [self.player replaceCurrentItemWithPlayerItem:newItem];
    
    [self.player play];
}

- (void)volumeSliderMoved:(UISlider *)sender
{
	player.volume = [sender value];
	[[NSUserDefaults standardUserDefaults] setFloat:[sender value] forKey:@"PlayerVolume"];
}

- (IBAction)progressSliderMoved:(UISlider *)sender
{
    [self.player seekToTime:CMTimeMake(sender.value, 1)];
	[self updateCurrentTime];
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
        if([_delegate respondsToSelector:@selector(audioPlayer:didBeginPlaying:)]) {
            UAAudioFile* curr = (UAAudioFile *)[soundFiles objectAtIndex:selectedIndex];
            [_delegate audioPlayer:self didBeginPlaying:curr];
        }
    } else {
		[self.player stop];
    }
    
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
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
    
    if([_delegate respondsToSelector:@selector(audioPlayer:didBeginPlaying:)]) {
        UAAudioFile* curr = (UAAudioFile *)[soundFiles objectAtIndex:selectedIndex];
        [_delegate audioPlayer:self didBeginPlaying:curr];
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
- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    return [soundFiles count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UAAudioPlayerTableViewCell *cell = (UAAudioPlayerTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UAAudioPlayerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
	
	cell.title = [[soundFiles objectAtIndex:indexPath.row] title];
	cell.number = [NSString stringWithFormat:@"%d.", (indexPath.row + 1)];
	cell.duration = [[soundFiles objectAtIndex:indexPath.row] durationInMinutes];
    
	cell.isEven = indexPath.row % 2;
	
	if (selectedIndex == indexPath.row)
		cell.isSelectedIndex = YES;
	else
		cell.isSelectedIndex = NO;
	
	return cell;
}


- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	
	selectedIndex = indexPath.row;
	
	for (UAAudioPlayerTableViewCell *cell in [aTableView visibleCells]) {
		cell.isSelectedIndex = NO;
	}
	
	UAAudioPlayerTableViewCell *cell = (UAAudioPlayerTableViewCell *)[aTableView cellForRowAtIndexPath:indexPath];
	cell.isSelectedIndex = YES;
	
    [self playItemAtIndex:selectedIndex];
	
    if([_delegate respondsToSelector:@selector(audioPlayer:didStopPlaying:)]) {
        UAAudioFile* curr = (UAAudioFile *)[soundFiles objectAtIndex:selectedIndex];
        [_delegate audioPlayer:self didStopPlaying:curr];
    }
    
    if([_delegate respondsToSelector:@selector(audioPlayer:didBeginPlaying:)]) {
        UAAudioFile* curr = (UAAudioFile *)[soundFiles objectAtIndex:selectedIndex];
        [_delegate audioPlayer:self didBeginPlaying:curr];
    }
	
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
}

- (BOOL)tableView:(UITableView *)table canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}


- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 44;
}


#pragma mark - Image Reflection

CGImageRef CreateGradientImage(int pixelsWide, int pixelsHigh)
{
	CGImageRef theCGImage = NULL;
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	
	CGContextRef gradientBitmapContext = CGBitmapContextCreate(NULL, pixelsWide, pixelsHigh,
															   8, 0, colorSpace, kCGImageAlphaNone);
    
	CGFloat colors[] = {0.0, 1.0, 1.0, 1.0};
	
	CGGradientRef grayScaleGradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
	CGColorSpaceRelease(colorSpace);
	
	CGPoint gradientStartPoint = CGPointZero;
	CGPoint gradientEndPoint = CGPointMake(0, pixelsHigh);
	
	CGContextDrawLinearGradient(gradientBitmapContext, grayScaleGradient, gradientStartPoint,
								gradientEndPoint, kCGGradientDrawsAfterEndLocation);
	CGGradientRelease(grayScaleGradient);
	
	theCGImage = CGBitmapContextCreateImage(gradientBitmapContext);
	CGContextRelease(gradientBitmapContext);
	
    return theCGImage;
}

CGContextRef MyCreateBitmapContext(int pixelsWide, int pixelsHigh)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	// create the bitmap context
	CGContextRef bitmapContext = CGBitmapContextCreate (NULL, pixelsWide, pixelsHigh, 8,
														0, colorSpace,
														// this will give us an optimal BGRA format for the device:
														(kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst));
	CGColorSpaceRelease(colorSpace);
	
    return bitmapContext;
}

- (UIImage *)reflectedImage:(UIButton *)fromImage withHeight:(NSUInteger)height
{
    if (height == 0)
		return nil;
    
	// create a bitmap graphics context the size of the image
	CGContextRef mainViewContentContext = MyCreateBitmapContext(fromImage.bounds.size.width, height);
	
	CGImageRef gradientMaskImage = CreateGradientImage(1, height);
	
	CGContextClipToMask(mainViewContentContext, CGRectMake(0.0, 0.0, fromImage.bounds.size.width, height), gradientMaskImage);
	CGImageRelease(gradientMaskImage);
    
	CGContextTranslateCTM(mainViewContentContext, 0.0, height);
	CGContextScaleCTM(mainViewContentContext, 1.0, -1.0);
	
	CGContextDrawImage(mainViewContentContext, fromImage.bounds, fromImage.imageView.image.CGImage);
	
	CGImageRef reflectionImage = CGBitmapContextCreateImage(mainViewContentContext);
	CGContextRelease(mainViewContentContext);
	
	UIImage *theImage = [UIImage imageWithCGImage:reflectionImage];
	
	CGImageRelease(reflectionImage);
	
	return theImage;
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
}

- (void)beginSeekingBackward
{
    [self.player setRate:-2.0f];
    [self updateNowPlayingInfoPlaybackRate:@(-2.0f)];
}

- (void)endSeeking
{
    [self play];
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
    [nowPlayingInfo setObject:@(self.player.currentTime.value / self.player.currentTime.timescale) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [playingInfoCenter setNowPlayingInfo:nowPlayingInfo];
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

#pragma mark - AudioPlayer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"%s: %@", __func__, keyPath);
    
    if (object == self.player && [keyPath isEqualToString:@"status"]) {
        if (self.player.status == AVPlayerStatusFailed) {
            NSLog(@"AVPlayer Failed");
            
        } else if (self.player.status == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
            [self.player play];
            
        } else if (self.player.status == AVPlayerItemStatusUnknown) {
            NSLog(@"AVPlayer Unknown");
            
        }
        
        [self updateViewForPlayerInfo:player];
		[self updateViewForPlayerState:player];
    } else if ([keyPath isEqualToString:@"rate"]) {
        if ([self.player rate]) {
            NSLog(@"Playing");
        }
        else {
            NSLog(@"Paused");
        }
        
        [self updateViewForPlayerInfo:player];
		[self updateViewForPlayerState:player];
    } else if ([keyPath isEqualToString:@"currentItem.duration"]) {
        NSLog(@"Got duration: %f", self.player.duration);
        [self updateViewForPlayerInfo:player];
		[self updateViewForPlayerState:player];
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    
	if ([self canGoToNextTrack]) {
        [self next];
    } else if (interrupted) {
		[self.player play];
        if([_delegate respondsToSelector:@selector(audioPlayer:didBeginPlaying:)]) {
            UAAudioFile* curr = (UAAudioFile *)[soundFiles objectAtIndex:selectedIndex];
            [_delegate audioPlayer:self didBeginPlaying:curr];
        }
    } else {
		[self.player stop];
    }
    
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
}

@end
