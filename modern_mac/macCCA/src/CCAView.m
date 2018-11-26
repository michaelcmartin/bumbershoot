//
//  CCAView.m
//  CCA
//
//  Created by Michael Martin on 8/12/16.
//  Copyright © 2016 Bumbershoot Software. All rights reserved.
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
    CGContextRef ctx = [[NSGraphicsContext currentContext] CGContext];
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

@end
