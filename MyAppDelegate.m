//
//  MyAppDelegate.m
//  Blitz
//
//  Created by Kevin Mitchell on 10/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MyAppDelegate.h"
#import "CounterView.h"

@implementation MyAppDelegate

@synthesize windowControllers;
@synthesize preferencesWindowController;
@synthesize secondsElapsed;
@synthesize keynote;
@synthesize running;
@synthesize timer;

//  Following function stolen from http://cocoa.karelia.com/Foundation_Categories/NSColor__Instantiat.m
static NSData* colorDataFromHexRGB( NSString *inColorString ) {
	NSColor *result = nil;
	unsigned int colorCode = 0;
	unsigned char redByte, greenByte, blueByte;

	if (nil != inColorString) {
		NSScanner *scanner = [NSScanner scannerWithString:inColorString];
		(void) [scanner scanHexInt:&colorCode];	// ignore error
	}
	redByte		= (unsigned char) (colorCode >> 16);
	greenByte	= (unsigned char) (colorCode >> 8);
	blueByte	= (unsigned char) (colorCode);	// masks off high bits
	result = [NSColor
              colorWithCalibratedRed: (float)redByte	/ 0xff
              green: (float)greenByte/ 0xff
              blue:	(float)blueByte	/ 0xff
              alpha: 1.0];
	return [NSArchiver archivedDataWithRootObject:result];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          colorDataFromHexRGB(@"2c8fff"), kCounterViewRingForeground,
                          colorDataFromHexRGB(@"32303d"), kCounterViewRingBackground,
                          colorDataFromHexRGB(@"0046ff"), kCounterViewWedgeForeground,
                          colorDataFromHexRGB(@"000000"), kCounterViewWedgeBackground,
                          nil];

    [preferences registerDefaults:dict];
}

- (IBAction)startStopReset:(id)sender
{
    if (self.running)
    {
        [self.timer invalidate];
        self.timer = nil;
        self.running = false;
    }
    else if (secondsElapsed > 0)
    {
        self.secondsElapsed = 0;
    }
    else
    {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / UPDATES_PER_SECOND)
                                                      target:self
                                                    selector:@selector(tick:)
                                                    userInfo:nil
                                                     repeats:YES];
        self.running = true;
    }
}

- (void) setSecondsElapsed:(NSTimeInterval)elapsed
{
    secondsElapsed = elapsed;

    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithDouble:self.secondsElapsed],
                              @"secondsElapsed",
                              0, nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:UpdateSecondsElapsed
                                                        object:self
                                                      userInfo:userInfo];
}

- (void) advanceSlide {
    if (keynote.isRunning) {
        [keynote showNext];
    }
    else {
        NSLog(@"Keynote is not running");
    }
}

- (void) tick:(NSTimer*) timer {
    if ((NUMBER_OF_SLIDES * SECONDS_PER_SLIDE - self.secondsElapsed) > (1.0f / UPDATES_PER_SECOND / 2.0f))
    {
        self.secondsElapsed += 1.0 / UPDATES_PER_SECOND;

        bool justAboutDone = (self.secondsElapsed > ((NUMBER_OF_SLIDES * SECONDS_PER_SLIDE) - (1.0f / UPDATES_PER_SECOND / 2.0f)));
        if ( !justAboutDone &&
            ((int)floor(UPDATES_PER_SECOND * self.secondsElapsed) % (UPDATES_PER_SECOND * SECONDS_PER_SLIDE) == 0))
            [self advanceSlide];
    }
    else
    {
        // Can just stop the timer here.
        [self startStopReset:self];
    }

}

- (IBAction)showFloatingCounters:(id)sender
{
    self.keynote = [SBApplication applicationWithBundleIdentifier:@"com.apple.iWork.Keynote"];

    // If it can't be found by bundle, try finding it by location.
    if (![self.keynote respondsToSelector:@selector(showNext)]) {
        self.keynote = [SBApplication applicationWithURL:[NSURL URLWithString:@"file:///Applications/Keynote.app"]];
    }

    if (![self.keynote respondsToSelector:@selector(showNext)]) {
        NSRunAlertPanel(@"Can't find Keynote", @"Can't find Keynote; timer will run but slides won't advance;", @"OK", nil, nil);
        self.keynote = nil;
    }


    self.windowControllers = [NSMutableArray array];
    
    for (NSScreen *screen in [NSScreen screens])
    {
        NSWindowController *controller = [[[NSWindowController alloc] initWithWindowNibName:@"CounterWindow"] autorelease];
        [windowControllers addObject:controller];
        
        NSRect screenFrame = [screen frame];
        NSWindow *window = [controller window];
        NSRect windowFrame = [window frame];
        NSPoint windowOrigin;
        windowOrigin.x = screenFrame.origin.x + screenFrame.size.width - windowFrame.size.width - 20;

        if (TOP_ON_AUDIENCE_SCREEN || ([screen isEqual:[NSScreen mainScreen]] && [[NSScreen screens] count] > 1))
            windowOrigin.y = screenFrame.origin.y + screenFrame.size.height - windowFrame.size.height - 40;
        else
             windowOrigin.y = screenFrame.origin.y + 20;

        [window setFrameOrigin:windowOrigin];
        
        // This makes it float.
        [window setLevel:CGShieldingWindowLevel()];
        
        [controller showWindow:self];
    }
}

- (IBAction)showPreferences:(id)sender
{
    if (self.preferencesWindowController == nil)
        self.preferencesWindowController = [[NSWindowController alloc] initWithWindowNibName:@"Preferences"];

    [self.preferencesWindowController showWindow:self];
}

- (IBAction)resetPreferences:(id)sender
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences removeObjectForKey:kCounterViewRingForeground];
    [preferences removeObjectForKey:kCounterViewRingBackground];
    [preferences removeObjectForKey:kCounterViewWedgeForeground];
    [preferences removeObjectForKey:kCounterViewWedgeBackground];
}
@end
