//
//  AudioFile.m
//  MobileTheatre
//
//  Created by Matt Donnelly on 28/06/2010.
//  Copyright 2010 Matt Donnelly. All rights reserved.
//

#import "UAAudioFile.h"

@implementation UAAudioFile

@synthesize filePath;
@synthesize fileInfoDict;
@synthesize coverImage = _coverImage;

- (instancetype)initWithLocalFilePath:(NSURL *)path {
	
    if (self = [super init])  {
		self.filePath = path;
		self.fileInfoDict = [self songID3Tags];
	}
	
	return self;
}

- (instancetype)initWithRemoteFilePath:(NSURL *)path andInfoDict:(NSDictionary *)infoDict {
    
    if (self = [super init]) {
		self.filePath = path;
		self.fileInfoDict = infoDict;
	}
	
	return self;
}

- (instancetype)initWithRemoteFilePath:(NSURL *)path
                                 title:(NSString *)title
                                artist:(NSString *)artist
                                 album:(NSString *)album
                              duration:(NSNumber *)duration {
    
    NSMutableDictionary * dictionary  = [NSMutableDictionary dictionary];
    
    if (title) dictionary[kUADictionaryTitle]     = title;
    if (artist) dictionary[kUADictionaryArtist]    = artist;
    if (album) dictionary[kUADictionaryAlbum]     = album;
    if (duration) dictionary[kUADictionaryDuration]  = duration;
	
	return [self initWithRemoteFilePath:path andInfoDict:dictionary];
}

- (NSDictionary *)songID3Tags
{	
	AudioFileID fileID = nil;
	OSStatus error = noErr;
	
	error = AudioFileOpenURL((__bridge CFURLRef)self.filePath, kAudioFileReadPermission, 0, &fileID);
	if (error != noErr) {
        NSLog(@"AudioFileOpenURL failed");
    }
	
	UInt32 id3DataSize  = 0;
    char *rawID3Tag    = NULL;
	
    error = AudioFileGetPropertyInfo(fileID, kAudioFilePropertyID3Tag, &id3DataSize, NULL);
    if (error != noErr)
        NSLog(@"AudioFileGetPropertyInfo failed for ID3 tag");
	
    rawID3Tag = (char *)malloc(id3DataSize);
    if (rawID3Tag == NULL)
        NSLog(@"could not allocate %d bytes of memory for ID3 tag", (unsigned int)id3DataSize);
    
    error = AudioFileGetProperty(fileID, kAudioFilePropertyID3Tag, &id3DataSize, rawID3Tag);
    if( error != noErr )
        NSLog(@"AudioFileGetPropertyID3Tag failed");
	
	UInt32 id3TagSize = 0;
    UInt32 id3TagSizeLength = 0;
	
	error = AudioFormatGetProperty(kAudioFormatProperty_ID3TagSize, id3DataSize, rawID3Tag, &id3TagSizeLength, &id3TagSize);
	
    if (error != noErr) {
        NSLog( @"AudioFormatGetProperty_ID3TagSize failed" );
        switch(error) {
            case kAudioFormatUnspecifiedError:
                NSLog( @"Error: audio format unspecified error" ); 
                break;
            case kAudioFormatUnsupportedPropertyError:
                NSLog( @"Error: audio format unsupported property error" ); 
                break;
            case kAudioFormatBadPropertySizeError:
                NSLog( @"Error: audio format bad property size error" ); 
                break;
            case kAudioFormatBadSpecifierSizeError:
                NSLog( @"Error: audio format bad specifier size error" ); 
                break;
            case kAudioFormatUnsupportedDataFormatError:
                NSLog( @"Error: audio format unsupported data format error" ); 
                break;
            case kAudioFormatUnknownFormatError:
                NSLog( @"Error: audio format unknown format error" ); 
                break;
            default:
                NSLog( @"Error: unknown audio format error" ); 
                break;
        }
    }	
	
	CFDictionaryRef piDict = nil;
    UInt32 piDataSize = sizeof(piDict);
	
    error = AudioFileGetProperty(fileID, kAudioFilePropertyInfoDictionary, &piDataSize, &piDict);
    if (error != noErr)
        NSLog(@"AudioFileGetProperty failed for property info dictionary");
	
	free(rawID3Tag);
    
    NSMutableDictionary * dictionary  = [NSMutableDictionary dictionary];
    
    if ([(__bridge NSDictionary*)piDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Title]])
        dictionary[kUADictionaryTitle]    = [(__bridge NSDictionary*)piDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Title]];
    
    if ([(__bridge NSDictionary*)piDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Artist]])
        dictionary[kUADictionaryArtist]   = [(__bridge NSDictionary*)piDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Artist]];
    
    if ([(__bridge NSDictionary*)piDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Album]])
        dictionary[kUADictionaryAlbum]    = [(__bridge NSDictionary*)piDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_Album]];
    
    if ([(__bridge NSDictionary*)piDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_ApproximateDurationInSeconds]])
        dictionary[kUADictionaryDuration] = [(__bridge NSDictionary*)piDict objectForKey:[NSString stringWithUTF8String:kAFInfoDictionary_ApproximateDurationInSeconds]];
	
	return dictionary;
}

- (NSString *)title
{
	if ([self.fileInfoDict objectForKey:kUADictionaryTitle]) {
		return [self.fileInfoDict objectForKey:kUADictionaryTitle];
	}
	
	else {
		NSString *url = [filePath absoluteString];
		NSArray *parts = [url componentsSeparatedByString:@"/"];
		return [parts objectAtIndex:[parts count]-1];
	}
	
	return nil;
}

- (NSString *)artist
{
	if ([self.fileInfoDict objectForKey:kUADictionaryArtist])
		return [self.fileInfoDict objectForKey:kUADictionaryArtist];
	else
		return @"";
}

- (NSString *)album
{
	if ([self.fileInfoDict objectForKey:kUADictionaryAlbum])
		return [self.fileInfoDict objectForKey:kUADictionaryAlbum];
	else
		return @"";
}

- (float)duration
{
	if ([self.fileInfoDict objectForKey:kUADictionaryDuration])
		return [[self.fileInfoDict objectForKey:kUADictionaryDuration] floatValue];
	else
		return 0;
}

- (NSString *)durationInMinutes
{	
	return [NSString stringWithFormat:@"%d:%02d", (int)[self duration] / 60, (int)[self duration] % 60, nil];
}

- (UIImage *)coverImage
{
    if (_coverImage == nil)
    {
        _coverImage = [UIImage imageNamed:@"AudioPlayerNoArtwork.png"];
    }
	return _coverImage;
}

@end
