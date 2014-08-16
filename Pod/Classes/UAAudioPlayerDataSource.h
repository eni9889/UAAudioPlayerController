//
//  BeamMusicPlayerDataSource.h
//  Part of UAAudioPlayerController (license: New BSD)
//  -> https://github.com/BeamApp/MusicPlayerViewController
//
//  Created by Moritz Haarmann on 30.05.12.
//  Copyright (c) 2012 BeamApp UG. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Block Type used to receive images from the BeamMusicPlayerDataSource
 */
typedef void(^UAAudioPlayerReceivingBlock)(UIImage* image, NSError** error);


@class UAAudioPlayerController;
@class UAAudioFile;

/**
 * The DataSource for the UAAudioPlayerController provides all data necessary to display
 * a player UI filled with the appropriate information. 
 */
@protocol UAAudioPlayerDataSource <NSObject>

/**
 * Returns the title of the given track and player as a NSString. You can return nil for no title.
 * @param player the UAAudioPlayerController that is making this request.
 * @param trackNumber the track number this request is for.
 * @return A string to use as the title of the track. If you return nil, this track will have no title.
 */
-(NSString*)musicPlayer:(UAAudioPlayerController*)player titleForTrack:(NSUInteger)trackNumber;

/**
 * Returns the artist for the given track in the given UAAudioPlayerController.
 * @param player the UAAudioPlayerController that is making this request.
 * @param trackNumber the track number this request is for.
 * @return A string to use as the artist name of the track. If you return nil, this track will have no artist name.
 */
-(NSString*)musicPlayer:(UAAudioPlayerController*)player artistForTrack:(NSUInteger)trackNumber;

/**
* Returns the album for the given track in the given UAAudioPlayerController.
 * @param player the UAAudioPlayerController that is making this request.
 * @param trackNumber the track number this request is for.
 * @return A string to use as the album name of the track. If you return nil, this track will have no album name.
*/
-(NSString*)musicPlayer:(UAAudioPlayerController*)player albumForTrack:(NSUInteger)trackNumber;

/**
 * Returns the length for the given track in the given UAAudioPlayerController. Your implementation must provide a 
 * value larger than 0.
 * @param player the UAAudioPlayerController that is making this request.
 * @param trackNumber the track number this request is for.
 * @return length in seconds
 */
-(CGFloat)musicPlayer:(UAAudioPlayerController*)player lengthForTrack:(NSUInteger)trackNumber;

/**
 * Returns the current position for the given track in the given UAAudioPlayerController.
 * @param player the UAAudioPlayerController that is making this request.
 * @param trackNumber the track number this request is for.
 * @return current position in seconds.
 */
-(CGFloat)musicPlayer:(UAAudioPlayerController*)player currentPositionForTrack:(NSUInteger)trackNumber;

/**
 * Returns the track for the given index.
 * @param trackIndex the track index.
 * @return an audio file corresponding to the trackIndex.
 */
-(UAAudioFile *)audioTrackAtIndex:(NSInteger)trackIndex;

@optional

/**
 * Returns the number of tracks for the given player. If you do not implement this method
 * or return anything smaller than 2, one track is assumed and the skip-buttons are disabled.
 * @param player the UAAudioPlayerController that is making this request.
 * @return number of available tracks, -1 if unknown
 */
-(NSInteger)numberOfTracksInPlayer:(UAAudioPlayerController*)player;

/**
 * Returns the artwork for a given track.
 *
 * The artwork is returned using a receiving block ( UAAudioPlayerReceivingBlock ) that takes an UIImage and an optional error. If you supply nil as an image, a placeholder will be shown.
 * @param player the UAAudioPlayerController that needs artwork.
 * @param trackNumber the index of the track for which the artwork is requested.
 * @param receivingBlock a block of type UAAudioPlayerReceivingBlock that needs to be called when the image is prepared by the receiver.
 * @see [UAAudioPlayerController preferredSizeForCoverArt]
 */
-(void)musicPlayer:(UAAudioPlayerController*)player artworkForTrack:(NSUInteger)trackNumber receivingBlock:(UAAudioPlayerReceivingBlock)receivingBlock;

@end
