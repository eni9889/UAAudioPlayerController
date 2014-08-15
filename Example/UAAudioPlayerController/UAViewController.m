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

@interface UAViewController ()

@end

@implementation UAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSURL *fileURL = [NSURL URLWithString:@"https://api.soundcloud.com/tracks/293/stream?client_id=88542d62a809958f62af28b8958fe8a2"];
    UAAudioFile *file = [[UAAudioFile alloc] initWithRemoteFilePath:fileURL title:@"Flickermood"
                                                             artist:@"Forss"
                                                              album:@"Electronic"
                                                           duration:[NSNumber numberWithInt:213890/1000]];
    
    UAAudioPlayerController *audioPlayer = [[UAAudioPlayerController alloc] initWithSoundFiles:@[file]
                                                                                        atPath:[[NSBundle mainBundle] bundlePath] andSelectedIndex:0];
	[self.navigationController pushViewController:audioPlayer animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
