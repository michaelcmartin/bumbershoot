//
//  AppDelegate.m
//  CCA
//
//  Created by Michael Martin on 11/15/16.
//  Copyright © 2016-8 Bumbershoot Software. All rights reserved.
//

#import "AppDelegate.h"
#import "MainView.h"
#import "CCA.h"

@interface AppDelegate ()

@property NSWindow *displayWindow;
@property (strong, nonatomic) NSTimer *timer;
@property CCAContext *model;
@end

@implementation AppDelegate

-(id)init
{
    if(self = [super init]) {
        CCA_seed_random();
        self.model = CCA_alloc();
    }
    return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSMenu *menuBar, *appMenu;
    NSMenuItem *appMenuItem, *resetMenuItem, *quitMenuItem;
    MainView *mainView;
    NSRect contentFrame = NSMakeRect(0.0, 0.0, 500.0, 500.0);
    NSUInteger windowStyleMask = NSTitledWindowMask | NSResizableWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask;

    menuBar = [NSMenu new];
    appMenuItem = [NSMenuItem new];
    [menuBar addItem:appMenuItem];
    appMenu = [NSMenu new];
    resetMenuItem = [[NSMenuItem alloc] initWithTitle:@"Reset"
                                               action:@selector(resetModel)
                                        keyEquivalent:@"r"];
    quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit CCA"
                                              action:@selector(terminate:)
                                       keyEquivalent:@"q"];
    [appMenu addItem:resetMenuItem];
    [appMenu addItem:quitMenuItem];
    [appMenuItem setSubmenu:appMenu];
    [NSApp setMainMenu:menuBar];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    self.displayWindow = [[NSWindow alloc] initWithContentRect:contentFrame styleMask:windowStyleMask backing:NSBackingStoreBuffered defer:NO];
    self.displayWindow.backgroundColor = [NSColor windowBackgroundColor];
    self.displayWindow.title = @"The Cyclic Cellular Automaton";
    [self.displayWindow setStyleMask:windowStyleMask];

    mainView = [[MainView alloc ]initWithFrame:contentFrame model:self.model];
    self.displayWindow.contentView = mainView;
    resetMenuItem.target = mainView.ccaView;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [NSApp activateIgnoringOtherApps:YES];
    [self.displayWindow makeKeyAndOrderFront:self];
    self.timer = [NSTimer timerWithTimeInterval:0.05 target:self.displayWindow.contentView selector:@selector(tick:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.timer invalidate];
    CCA_free(self.model);
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication {
    return YES;
}

@end
