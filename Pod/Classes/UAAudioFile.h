//
//  AudioFile.h
//  MobileTheatre
//
//  Created by Matt Donnelly on 28/06/2010.
//  Copyright 2010 Matt Donnelly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


#define kUADictionaryTitle    @"title"
#define kUADictionaryArtist   @"artist"
#define kUADictionaryAlbum    @"album"
#define kUADictionaryDuration @"duration"

@interface UAAudioFile : NSObject

@property (nonatomic, retain) NSURL *filePath;
@property (nonatomic, retain) NSDictionary *fileInfoDict;
@property (nonatomic, retain) UIImage *coverImage;

- (instancetype)initWithLocalFilePath:(NSURL *)path;
- (instancetype)initWithRemoteFilePath:(NSURL *)path
                           andInfoDict:(NSDictionary *)infoDict;
- (instancetype)initWithRemoteFilePath:(NSURL *)path
                                 title:(NSString *)title
                                artist:(NSString *)artist
                                 album:(NSString *)album
                              duration:(NSNumber *)duration;

- (NSString *)title;
- (NSString *)artist;
- (NSString *)album;
- (float)duration;

- (NSString *)durationInMinutes;

@end
