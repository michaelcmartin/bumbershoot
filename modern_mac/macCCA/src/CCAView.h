//
//  CCAView.h
//  CCA
//
//  Created by Michael Martin on 8/12/16.
//  Copyright © 2016 Bumbershoot Software. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "CCA.h"

@interface CCAView : NSView
@property CCAContext *cca;

- (instancetype) initWithFrame:(NSRect)frameRect model:(CCAContext *)model;
@end
