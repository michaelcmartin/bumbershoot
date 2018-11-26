//
//  CCAView.m
//  CCA
//
//  Created by Michael Martin on 8/12/16.
//  Copyright © 2016-8 Bumbershoot Software. Published under the
//  2-clause BSD license.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//
//  1. Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above
//     copyright notice, this list of conditions and the following
//     disclaimer in the documentation and/or other materials provided
//     with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
//  CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
//  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
//  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
//  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
//  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//  SUCH DAMAGE.
//

#import "CCAView.h"

static CGFloat palette[16][3] = {
    {0.0, 0.0, 0.0},
    {0.0, 0.0, 0.67},
    {0.0, 0.67, 0.0},
    {0.0, 0.67, 0.67},
    {0.67, 0.0, 0.0},
    {0.67, 0.0, 0.67},
    {0.67, 0.33, 0.0},
    {0.67, 0.67, 0.67},
    {0.33, 0.33, 0.33},
    {0.33, 0.33, 1.0},
    {0.33, 1.0, 0.33},
    {0.33, 1.0, 1.0},
    {1.0, 0.33, 0.33},
    {1.0, 0.33, 1.0},
    {1.0, 1.0, 0.33},
    {1.0, 1.0, 1.0}
};

@implementation CCAView

- (instancetype) initWithFrame:(NSRect)frameRect model:(CCAContext *)model {
    if (!model) {
        return nil;
    }
    if (self = [super initWithFrame:frameRect]) {
        self.cca = model;
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    int y, x;
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    CGFloat x0 = self.bounds.origin.x;
    CGFloat y0 = self.bounds.origin.y;
    CGFloat boxWidth = self.bounds.size.width / CCA_WIDTH;
    CGFloat boxHeight = self.bounds.size.height / CCA_HEIGHT;
    CCA *grid = self.cca->front;
    for (y = 0; y < CCA_HEIGHT; ++y) {
        for (x = 0; x < CCA_WIDTH; ++x) {
            CGRect r;
            unsigned char i = grid->grid[y][x];
            CGContextSetRGBFillColor(ctx, palette[i][0], palette[i][1], palette[i][2], 1.0);
            // This could be dramatically improved with strength reduction
            r.origin.x = x0 + x * boxWidth;
            r.origin.y = y0 + y * boxHeight;
            r.size.width = boxWidth + 1;
            r.size.height = boxHeight + 1;
            CGContextFillRect(ctx, r);
        }
    }
}

- (void)resetModel {
    if (self.cca) {
        CCA_scramble(self.cca);
    }
}

- (void)modelStep {
    if (self.cca) {
        CCA_step(self.cca);
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseUp:(NSEvent *)event {
    [self resetModel];
}
@end
