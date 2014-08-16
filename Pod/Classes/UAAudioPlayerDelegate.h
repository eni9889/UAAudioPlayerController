//
//  UAAudioPlayerDelegate.h
//  Part of UAAudioPlayerController (license: New BSD)
//  -> https://github.com/BeamApp/MusicPlayerViewController
//
//  Created by Moritz Haarmann on 30.05.12.
//  Copyright (c) 2012 BeamApp UG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
@class UAAudioPlayerController;


/**
 * The Delegate of the UAAudioPlayerController must adopt the UAAudioPlayerDelegate protocol to track changes
 * in the state of the music player.
 */
@protocol UAAudioPlayerDelegate <NSObject>

@optional

/**
 * Called by the player after the player started playing a song.
 * @param player the UAAudioPlayerController sending the message
 */
-(void)musicPlayerDidStartPlaying:(UAAudioPlayerController*)player;

/**
 * Called after a user presses the "play"-button but before the player actually starts playing.
 * @param player the UAAudioPlayerController sending the message
 * @return  If the value returned is NO, the player won't start playing. YES, tells the player to starts. Default is YES.
 */
-(BOOL)musicPlayerShouldStartPlaying:(UAAudioPlayerController*)player;

/**
 * Called after the player stopped playing. This method is called both when the current song ends 
 * and if the user stops the playback. 
 * @param player the UAAudioPlayerController sending the message
 */
-(void)musicPlayerDidStopPlaying:(UAAudioPlayerController*)player;

/**
 * Called after the player stopped playing the last track.
 * @param player the UAAudioPlayerController sending the message
 */
-(void)musicPlayerDidStopPlayingLastTrack:(UAAudioPlayerController*)player;


/**
 * Called before the player stops playing but after the user initiated the stop action.
 * @param player the UAAudioPlayerController sending the message
 * @return By returning NO here, the delegate may prevent the player from stopping the playback. Default YES.
 */
-(BOOL)musicPlayerShouldStopPlaying:(UAAudioPlayerController*)player;

/**
 * Called after the player seeked or scrubbed to a new position. This is mostly the result of a user interaction.
 * @param player the UAAudioPlayerController sending the message
 * @param position new position in seconds
 */
-(void)musicPlayer:(UAAudioPlayerController*)player didSeekToPosition:(CGFloat)position;

/**
 * Called before the player actually skips to the next song, but after the user initiated that action.
 *
 * If an implementation returns NO, the track will not be changed, if it returns YES the track will be changed. If you do not implement this method, YES is assumed. 
 * @param player the UAAudioPlayerController sending the message
 * @param track a NSUInteger containing the number of the new track
 * @return YES if the track can be changed, NO if not. Default YES.
 */
-(BOOL)musicPlayer:(UAAudioPlayerController*)player shouldChangeTrack:(NSUInteger)track;

/**
 * Called after the music player changed to a new track
 *
 * You can implement this method if you need to react to the player changing tracks.
 * @param player the UAAudioPlayerController changing the track
 * @param track a NSUInteger containing the number of the new track
 * @return the actual track the delegate has changed to
 */
-(NSInteger)musicPlayer:(UAAudioPlayerController*)player didChangeTrack:(NSUInteger)track;

/**
 * Called when the player changes it's shuffle state.
 *
 * YES indicates the player is shuffling now, i.e. randomly selecting a next track from the valid range of tracks, NO
 * means there is no shuffling.
 * @param player The UAAudioPlayerController that changes the shuffle state
 * @param shuffling YES if shuffling, NO if not
 */
-(void)musicPlayer:(UAAudioPlayerController*)player didChangeShuffleState:(BOOL)shuffling;

/**
 * Called when the player changes it's repeat mode.
 *
 * The repeat modes are taken from MediaPlayer framework and indicate whether the player is in No Repeat, Repeat Once or Repeat All mode.
 * @param player The UAAudioPlayerController that changes the repeat mode.
 * @param repeatMode a MPMusicRepeatMode indicating the currently active mode.
 */
-(void)musicPlayer:(UAAudioPlayerController*)player didChangeRepeatMode:(MPMusicRepeatMode)repeatMode;

@end

