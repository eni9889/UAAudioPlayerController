// SpotTableViewCell.m
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "UAAudioPlayerTableViewCell.h"

@interface UAAudioPlayerTableViewCell ()
@property (nonatomic, strong)  NAKPlaybackIndicatorView *indicator;
@end

@implementation UAAudioPlayerTableViewCell
@synthesize indicator = _indicator;
@synthesize isSelectedIndex;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    
    [self setBackgroundColor:[UIColor clearColor]];
    
    self.imageView.backgroundColor = self.backgroundColor;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.imageView setImage:[UIImage imageNamed:@"noAtwork.png"]];
    
    self.indicator = [[NAKPlaybackIndicatorView alloc] initWithFrame:CGRectZero];
    
    self.accessoryView = self.indicator;
    [self.indicator sizeToFit];
    self.indicator.state = NAKPlaybackIndicatorViewStateStopped;
    
    return self;
}

- (void)setTrackState:(NAKPlaybackIndicatorViewState)state {
    self.indicator.state = state;
}

- (void)dealloc
{
    self.imageView.image = nil;
    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
    
}

#pragma mark - UITableViewCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect imageViewFrame = self.imageView.frame;
    imageViewFrame.origin = CGPointMake(5.0f, 1.0f);
    imageViewFrame.size = CGSizeMake(47.5f, 48.0f);
    self.imageView.frame = imageViewFrame;
    
    CGRect textLabelFrame = self.textLabel.frame;
    CGRect detailTextLabelFrame = self.detailTextLabel.frame;
    
    textLabelFrame.origin.x = 64.00f;
    detailTextLabelFrame.origin.x = 64.00f;
    
    self.textLabel.frame = textLabelFrame;
    self.detailTextLabel.frame = detailTextLabelFrame;
    
}

@end