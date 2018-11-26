//
//  main.m
//  CCA
//
//  Created by Michael Martin on 11/15/16.
//  Copyright © 2016 Bumbershoot Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

/* This code has been adapted from the minimalist Cocoa app at
 * http://www.cocoawithlove.com/2010/09/minimalist-cocoa-programming.html
 * by Matt Gallagher. It's been modified to rely on an app delegate for
 * managing the application itself, and also to play nicely with ARC in the
 * post-Lion world.  */

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        AppDelegate *delegate = [AppDelegate new];

        [application setDelegate:delegate];
        [application run];
    }
    return EXIT_SUCCESS;
}
