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
    UAAudioPlayerController *audioPlayer = [[UAAudioPlayerController alloc] initWithSoundFiles:nil
                                                                                        atPath:[[NSBundle mainBundle] bundlePath] andSelectedIndex:0];
	[self.navigationController pushViewController:audioPlayer animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
