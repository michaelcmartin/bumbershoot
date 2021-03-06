//
//  MainView.m
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

#import "MainView.h"
#import "CCAView.h"

@interface MainView ()
@property (strong, nonatomic) NSArray<NSLayoutConstraint *> *constraints;
@property CCAContext *model;
@end

@implementation MainView

- (instancetype) initWithFrame:(NSRect)frameRect model:(CCAContext *)model {
    if (self = [super initWithFrame:frameRect]) {
        CCAView *ccaView = [[CCAView alloc] initWithFrame:frameRect model:model];
        [ccaView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:ccaView];
        self.ccaView = ccaView;
        self.model = model;

        NSButton *resetButton = [NSButton new];
        [resetButton setButtonType:NSMomentaryLightButton];
        [resetButton setBezelStyle:NSRoundedBezelStyle];
        [resetButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [resetButton setTitle:@"Reset"];
        [self addSubview:resetButton];
        self.resetButton = resetButton;
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self computeConstraints];

        self.resetButton.target = self.ccaView;
        self.resetButton.action = @selector(resetModel);
    }

    return self;
}

- (void) computeConstraints {
    if (self.constraints != nil) {
        for (NSLayoutConstraint *constraint in self.constraints) {
            [self removeConstraint:constraint];
        }
    }
    self.constraints = @[[NSLayoutConstraint constraintWithItem:self.ccaView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:8.0],
                         [NSLayoutConstraint constraintWithItem:self.ccaView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:8.0],
                         [NSLayoutConstraint constraintWithItem:self.ccaView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-8.0],
                         [NSLayoutConstraint constraintWithItem:self.ccaView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:300],
                         [NSLayoutConstraint constraintWithItem:self.ccaView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:300],
                         [NSLayoutConstraint constraintWithItem:self.resetButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.ccaView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0],
                         [NSLayoutConstraint constraintWithItem:self.resetButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.ccaView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:8.0],
                         [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.resetButton attribute:NSLayoutAttributeBottom multiplier:1.0 constant:8.0],
                         ];
    for (NSLayoutConstraint *constraint in self.constraints) {
        [self addConstraint:constraint];
    }
}

- (void)tick:(NSTimer *)timer {
    if (timer.valid) {
        [self.ccaView modelStep];
    }
}

@end
