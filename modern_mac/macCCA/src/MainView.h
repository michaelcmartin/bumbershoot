//
//  MainView.h
//  CCA
//
//  Created by Michael Martin on 8/12/16.
//  Copyright © 2016-8 Bumbershoot Software. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "CCAView.h"

@interface MainView : NSView
@property (nonatomic, nullable) CCAView *ccaView;
@property (nonatomic, nullable) NSButton *resetButton;
- (nullable instancetype) initWithFrame:(NSRect)frameRect model:(nonnull CCAContext *)model;
- (void) tick:(nonnull NSTimer *)timer;
@end
