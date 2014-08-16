//
//  UAViewController.m
//  UAAudioPlayerController
//
//  Created by Enea Gjoka on 08/15/2014.
//  Copyright (c) 2014 Enea Gjoka. All rights reserved.
//

#import "UAViewController.h"
#import "UAAudioFile.h"
#import "UAAudioPlayerController.h"

@interface UAViewController () <UAAudioPlayerDataSource, UAAudioPlayerDelegate>
@property (nonatomic, strong) UAAudioPlayerController *audioPlayer;
@end

@implementation UAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    UAAudioPlayerController *audioPlayer = [[UAAudioPlayerController alloc] initWithDelegate:self
                                                                                  dataSource:self];
	[self presentViewController:[[UINavigationController alloc] initWithRootViewController:audioPlayer] animated:YES completion:nil];
}

/**
 * Returns the title of the given track and player as a NSString. You can return nil for no title.
 * @param player the BeamMusicPlayerViewController that is making this request.
 * @param trackNumber the track number this request is for.
 * @return A string to use as the title of the track. If you return nil, this track will have no title.
 */
-(NSString*)musicPlayer:(UAAudioPlayerController*)player titleForTrack:(NSUInteger)trackNumber {
    return @"Flickermood";
}

/**
 * Returns the artist for the given track in the given BeamMusicPlayerViewController.
 * @param player the BeamMusicPlayerViewController that is making this request.
 * @param trackNumber the track number this request is for.
 * @return A string to use as the artist name of the track. If you return nil, this track will have no artist name.
 */
-(NSString*)musicPlayer:(UAAudioPlayerController*)player artistForTrack:(NSUInteger)trackNumber {
    
    return @"Forss";
}

/**
 * Returns the album for the given track in the given BeamMusicPlayerViewController.
 * @param player the BeamMusicPlayerViewController that is making this request.
 * @param trackNumber the track number this request is for.
 * @return A string to use as the album name of the track. If you return nil, this track will have no album name.
 */
-(NSString*)musicPlayer:(UAAudioPlayerController*)player albumForTrack:(NSUInteger)trackNumber {
    return @"Electronic";
}

-(NSInteger)numberOfTracksInPlayer:(UAAudioPlayerController*)player {
    return 3;
}

-(UAAudioFile *)audioTrackAtIndex:(NSInteger)trackIndex {
    NSURL *fileURL = [NSURL URLWithString:@"http://api.soundcloud.com/tracks/162647276/stream?client_id=88542d62a809958f62af28b8958fe8a2"];
    UAAudioFile *file = [[UAAudioFile alloc] initWithRemoteFilePath:fileURL title:@"Flickermood"
                                                             artist:@"Forss"
                                                              album:@"Electronic"
                                                           duration:[NSNumber numberWithInt:213890/1000]];
    return file;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
