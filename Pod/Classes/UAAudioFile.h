//
//  AudioFile.h
//  MobileTheatre
//
//  Created by Matt Donnelly on 28/06/2010.
//  Copyright 2010 Matt Donnelly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


@interface UAAudioFile : NSObject 
{
	NSURL			*filePath;
	NSDictionary	*fileInfoDict;
}

@property (nonatomic, retain) NSURL *filePath;
@property (nonatomic, retain) NSDictionary *fileInfoDict;
@property (nonatomic, retain) UIImage *coverImage;

- (UAAudioFile *)initWithPath:(NSURL *)path;
- (NSDictionary *)songID3Tags;
- (NSString *)title;
- (NSString *)artist;
- (NSString *)album;
- (float)duration;
- (NSString *)durationInMinutes;

@end
