//
//  AppDelegate.m
//  TwoBrowser
//
//  Created by Chris J. Davis on 1/3/14.
//  Copyright (c) 2014 ___LEAGUEOFBEARDS___. All rights reserved.
//

#import "AppDelegate.h"
#import "INWindowButton.h"

@interface WebInspector : NSObject  { WebView *_webView; }
    - (id)initWithWebView:(WebView *)webView;
    - (void)detach:     (id)sender;
    - (void)show:       (id)sender;
    - (void)showConsole:(id)sender;
    - (void)hideConsole:(id)sender;
@end

@interface AppDelegate() <NSSplitViewDelegate>

- (IBAction)connectURL:(id)sender;
- (IBAction)reloadURL:(id)sender;

@end;

NSViewController *webViewController;

@implementation AppDelegate  { WebInspector *_inspector; }

@synthesize window;
@synthesize textField;
@synthesize mobileView;
@synthesize desktopView;
@synthesize theSplits = theSplits_;
@synthesize toggler;
@synthesize breakpoints;
@synthesize url;
@synthesize mWidthPop;
@synthesize urlButton;
@synthesize bookmarkAdd;
@synthesize pageTitle;
@synthesize pageFavicon;
@synthesize desktopWidth;
@synthesize mobileWidth;
@synthesize mobileSizeIcon;
@synthesize mWidthSetter;
@synthesize dWidthSetter;
@synthesize mWidthValue;
@synthesize dWidthValue;
@synthesize bitmap;
@synthesize pdfData;
@synthesize imageView;
@synthesize accessoryView;
@synthesize previewWindow;
@synthesize previewTitleView;

- (void) awakeFromNib {
    [self loadWelcome];
    NSAppleEventManager *eventManager = [NSAppleEventManager sharedAppleEventManager];
    [eventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // setup some cache defaults.
    int cacheSizeMemory = 4*1024*1024; // 4MB
    int cacheSizeDisk = 32*1024*1024; // 32MB
    NSArray *defaultBreaks = nil;
    
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory diskCapacity:cacheSizeDisk diskPath:@"nsurlcache"];
    [NSURLCache setSharedURLCache:sharedCache];
    
    NSAppleEventManager *eventManager = [NSAppleEventManager sharedAppleEventManager];
    [eventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    self.window.trafficLightButtonsLeftMargin = 9.0;
    self.window.fullScreenButtonRightMargin = 7.0;
    self.window.centerFullScreenButton = YES;
    self.window.titleBarHeight = 40.0;
    self.titleView.frame = self.window.titleBarView.bounds;
    self.titleView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.window.titleBarView addSubview:self.titleView];
    
    [theSplits_ setPosition:320 - 3 ofDividerAtIndex:0];
    
    NSMutableArray *retArray = [[NSMutableArray alloc] initWithArray:((NSMutableArray *) [[NSUserDefaults standardUserDefaults] objectForKey:@"userBreakpoints"])];
    
    if ([retArray count] == 0) {
        defaultBreaks = [NSArray arrayWithObjects:@"Breakpoints", @"320", @"360", @"768", @"800", @"980", nil];
        NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:defaultBreaks];
        [[NSUserDefaults standardUserDefaults] setObject:mutableArray forKey:@"userBreakpoints"];
    } else {
        defaultBreaks = retArray;
    }
    
    [breakpoints removeAllItems];
    [breakpoints addItemsWithTitles: defaultBreaks];
    
    NSRect leftFrame = [mobileView frame];
    NSRect rightFrame = [desktopView frame];
    
    [mobileWidth setStringValue:[NSString stringWithFormat: @"%.f", floor(leftFrame.size.width)]];
    [desktopWidth setStringValue:[NSString stringWithFormat: @"%.f", floor(rightFrame.size.width)]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webViewDidStartLoad:)name:WebViewProgressStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webViewFinishedLoading:)name:WebViewProgressFinishedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didResize:)name:NSSplitViewDidResizeSubviewsNotification object: nil];
    
    [theSplits_ setDelegate:self];
    [mobileView setPolicyDelegate:self];
    [desktopView setPolicyDelegate:self];
    
    if ([mobileView respondsToSelector:@selector(setMediaStyle:)]) {
        [mobileView setMediaStyle:@"screen"];
    }
    
    if ([desktopView respondsToSelector:@selector(setMediaStyle:)]) {
        [desktopView setMediaStyle:@"screen"];
    }
}

#pragma mark -- User Infor Saving Times

- (void)handleBreakpointsSave:(NSArray *)breaks {
    NSMutableArray *retArray = [[NSMutableArray alloc] initWithArray:((NSMutableArray *) [[NSUserDefaults standardUserDefaults] objectForKey:@"userBreakpoints"])];
    NSLog(@"%@", retArray);
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSString *prefixToRemove = @"two://";
    NSString *filePrefix = @"file///";
    NSString *tmpString = nil;
    NSString *newString = nil;
    
//    NSURLRequest *localRequest = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:localFilePath]];
    
    if ([urlString hasPrefix:prefixToRemove]) {
        tmpString = [urlString substringFromIndex:[prefixToRemove length]];
        
        if ([tmpString hasPrefix:filePrefix]) {
            tmpString = [tmpString substringFromIndex:[filePrefix length]];
            tmpString = [NSString stringWithFormat:@"file:///%@", tmpString];
            [self connectURL:tmpString];
        } else {
            newString = tmpString;
            [self connectURL:newString];
        }
    }
}

#pragma mark -- respsonsive breakpoints

- (IBAction)chooseBreakpoint:(id)sender {
    switch (breakpoints.indexOfSelectedItem) {
        case 1:
            [mobileView setHidden:NO];
            [theSplits_ animateView:0 toDimension:320 - 3];
            break;
        case 2:
            [mobileView setHidden:NO];
            [theSplits_ animateView:0 toDimension:360 - 3];
            break;
        case 3:
            [mobileView setHidden:NO];
            [theSplits_ animateView:0 toDimension:768 - 3];
            break;
        case 4:
            [mobileView setHidden:NO];
            [theSplits_ animateView:0 toDimension:800 - 3];
            break;
        case 5:
            [mobileView setHidden:NO];
            [theSplits_ animateView:0 toDimension:980 - 3];
            break;
        default:
            [mobileView setHidden:NO];
            [theSplits_ animateView:0 toDimension:320 - 3];
        break;
    }
    
    NSInteger indexOfSelectedItem = [breakpoints indexOfSelectedItem];
    
    [breakpoints selectItemAtIndex:indexOfSelectedItem];
    
    toggler.selectedSegment = 0;
    
    NSRect leftFrame = [mobileView frame];
    NSRect rightFrame = [desktopView frame];
    
    [mobileWidth setStringValue:[NSString stringWithFormat: @"%.f", floor(leftFrame.size.width)]];
    [desktopWidth setStringValue:[NSString stringWithFormat: @"%.f", floor(rightFrame.size.width)]];
    [theSplits_ adjustSubviews];
}

#pragma mark -- SplitVIiew crap

- (IBAction)toggleControl:(id)sender {
    switch ((((NSSegmentedControl *)sender).selectedSegment)) {
        case 0:
            [theSplits_ setPosition:1 ofDividerAtIndex:0];
            [theSplits_ animateView:0 toDimension:320 + 0];
            [theSplits_ adjustSubviews];
            [mobileView setHidden:NO];
            [mobileWidth setHidden:NO];
            [mobileSizeIcon setHidden:NO];
            break;
        case 1:
            [mobileView setHidden:YES];
            [mobileWidth setHidden:YES];
            [mobileSizeIcon setHidden:YES];
            [theSplits_ animateView:0 toDimension:0];
            [theSplits_ adjustSubviews];
            break;
        default:
        break;
    }
}

- (void)didResize:(NSNotification *)notification {
    NSRect leftFrame = [mobileView frame];
    NSRect rightFrame = [desktopView frame];
    
    [mobileWidth setStringValue:[NSString stringWithFormat: @"%.f", floor(leftFrame.size.width)]];
    [desktopWidth setStringValue:[NSString stringWithFormat: @"%.f", floor(rightFrame.size.width)]];
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {
    NSView *m = [[splitView subviews] objectAtIndex:0];
    NSView *d = [[splitView subviews] objectAtIndex:1];
    
    if ( subview == d ) {
        return YES;
    } else if( subview == m ) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark -- webKit Specific

- (void)loadWelcome {
    NSString *localFilePath = [[NSBundle mainBundle] pathForResource:@"welcome" ofType:@"html"];
    NSURLRequest *localRequest = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:localFilePath]];
    [[mobileView mainFrame] loadRequest:localRequest];
    [[desktopView mainFrame] loadRequest:localRequest];
}

- (void)webViewDidStartLoad:(NSNotification *)notification {
    [pageFavicon setHidden:YES];
    [self.progr startAnimation:[notification object]];
}

- (void)webViewFinishedLoading:(NSNotification *)notification {
    [self.progr stopAnimation:[notification object]];
    
    NSString * TitleString = [NSString stringWithFormat:@"Testing %@", [[notification object] mainFrameTitle]];
    NSString * newURLString = [NSString stringWithFormat:@"%@", [[notification object] mainFrameURL]];
    
    
    if( [self contains:@"file://" on:newURLString] == false ) {
        [textField setStringValue:newURLString];
    }
    
    [pageFavicon setHidden:NO];
    [pageTitle setStringValue:TitleString];
    [pageFavicon setImage:[[notification object] mainFrameIcon]];
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
    NSNumber *navType = [actionInformation objectForKey: @"WebActionNavigationTypeKey"];
    
    if( sender == mobileView && [navType isEqualToNumber:[NSNumber numberWithInt:0]] ) {
        [[desktopView mainFrame] loadRequest:request];
    } else if( sender == desktopView && [navType isEqualToNumber:[NSNumber numberWithInt:0]] ) {
        [[mobileView mainFrame] loadRequest:request];
    }
    
    [listener use];
}

- (IBAction)showInspector:(id)x {
    _inspector = [WebInspector.alloc initWithWebView:mobileView];
        [_inspector detach:mobileView];
        [_inspector showConsole:mobileView];
   
    _inspector = [WebInspector.alloc initWithWebView:desktopView];
        [_inspector detach:desktopView];
        [_inspector showConsole:desktopView];
}

-(BOOL)contains:(NSString *)StrSearchTerm on:(NSString *)StrText {
    return  [StrText rangeOfString:StrSearchTerm options:NSCaseInsensitiveSearch].location == NSNotFound ? FALSE : TRUE;
}

- (IBAction)connectURL:(id)sender {
    NSURL* rUrl = nil;
    NSString* urlString = nil;
    
    if( [sender isKindOfClass:[NSString class]] ) {
        urlString = sender;
        rUrl = [NSURL URLWithString:sender];
    } else {
        urlString = [sender stringValue];
        rUrl = [NSURL URLWithString:urlString];
    }
    
    if( [self contains:@"http://" on:urlString] == false ) {
        NSString* modifiedURLString = [NSString stringWithFormat:@"http://%@", urlString];
        rUrl = [NSURL URLWithString:modifiedURLString];
    }
    
    NSString* kMobileSafariUserAgent = @"Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8A293 Safari/6531.22.7";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:rUrl];
    [request setValue:kMobileSafariUserAgent forHTTPHeaderField:@"User-Agent"];
    
    [pageFavicon setHidden:YES];
    [self.progr startAnimation:sender];
    self.urlButton.intValue = 0;
    [self.url close];
        
    [[mobileView mainFrame] loadRequest:request];
    [[desktopView mainFrame] loadRequest:[NSMutableURLRequest requestWithURL:rUrl]];
    [textField resignFirstResponder];
}

- (IBAction)reloadURL:(id)sender {
    [[mobileView mainFrame] reload];
    [[desktopView mainFrame] reload];
}

#pragma mark -- Custom Window

- (void)setupCloseButton {
    INWindowButton *closeButton = [INWindowButton windowButtonWithSize:NSMakeSize(14, 16) groupIdentifier:nil];
    closeButton.activeImage = [NSImage imageNamed:@"close-active-color.tiff"];
    closeButton.activeNotKeyWindowImage = [NSImage imageNamed:@"close-activenokey-color.tiff"];
    closeButton.inactiveImage = [NSImage imageNamed:@"close-inactive-disabled-color.tiff"];
    closeButton.pressedImage = [NSImage imageNamed:@"close-pd-color.tiff"];
    closeButton.rolloverImage = [NSImage imageNamed:@"close-rollover-color.tiff"];
    self.window.closeButton = closeButton;
}

- (void)setupMinimizeButton {
    INWindowButton *button = [INWindowButton windowButtonWithSize:NSMakeSize(14, 16) groupIdentifier:nil];
    button.activeImage = [NSImage imageNamed:@"minimize-active-color.tiff"];
    button.activeNotKeyWindowImage = [NSImage imageNamed:@"minimize-activenokey-color.tiff"];
    button.inactiveImage = [NSImage imageNamed:@"minimize-inactive-disabled-color.tiff"];
    button.pressedImage = [NSImage imageNamed:@"minimize-pd-color.tiff"];
    button.rolloverImage = [NSImage imageNamed:@"minimize-rollover-color.tiff"];
    self.window.minimizeButton = button;
}

- (void)setupZoomButton {
    INWindowButton *button = [INWindowButton windowButtonWithSize:NSMakeSize(14, 16) groupIdentifier:nil];
    button.activeImage = [NSImage imageNamed:@"zoom-active-color.tiff"];
    button.activeNotKeyWindowImage = [NSImage imageNamed:@"zoom-activenokey-color.tiff"];
    button.inactiveImage = [NSImage imageNamed:@"zoom-inactive-disabled-color.tiff"];
    button.pressedImage = [NSImage imageNamed:@"zoom-pd-color.tiff"];
    button.rolloverImage = [NSImage imageNamed:@"zoom-rollover-color.tiff"];
    self.window.zoomButton = button;
}

#pragma mark -- NSPopOvers

- (BOOL)buttonIsPressed:(NSButton *)sender {
    return sender.intValue == 1;
}

- (IBAction)setMWidth:(id)sender {
    if( [self buttonIsPressed:mWidthSetter] ) {
         NSRect leftFrame = [mobileView frame];
        [mWidthValue setStringValue:[NSString stringWithFormat: @"%.f", floor(leftFrame.size.width)]];
        [[self mWidthPop] showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
    } else {
        self.mWidthSetter.intValue = 0;
        [self.mWidthPop close];
    }
}

- (IBAction)setDWidth:(id)sender {
//    if( [self buttonIsPressed:dWidthSetter] ) {
//        NSRect leftFrame = [desktopView frame];
//        [dWidthValue setStringValue:[NSString stringWithFormat: @"%.f", floor(leftFrame.size.width)]];
//        [[self dWidthPop] showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
//    } else {
//        self.dWidthSetter.intValue = 0;
//        [self.dWidthPop close];
//    }
}

- (IBAction)showURL:(id)sender {
    if( [self buttonIsPressed:urlButton] ) {
        [[self url] showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
    } else {
        self.urlButton.intValue = 0;
        [self.url close];
    }
}

- (IBAction)openURL:(id)sender {
    [[self url] showRelativeToRect:[urlButton bounds] ofView:urlButton preferredEdge:NSMaxYEdge];
}

- (IBAction)manualChangeM:(id)sender {
    [mobileView setHidden:NO];
    [theSplits_ animateView:0 toDimension:[sender integerValue] - 3];
    
    NSRect leftFrame = [mobileView frame];
    NSRect rightFrame = [desktopView frame];
    self.mWidthSetter.intValue = 0;
    [self.mWidthPop close];
    [mobileWidth setStringValue:[NSString stringWithFormat: @"%.f", floor(leftFrame.size.width)]];
    [desktopWidth setStringValue:[NSString stringWithFormat: @"%.f", floor(rightFrame.size.width)]];
    [theSplits_ adjustSubviews];
}

- (IBAction)manualChangeD:(id)sender {
    [mobileView setHidden:NO];
    [theSplits_ animateView:1 toDimension:[sender integerValue] - 3];
    
    NSRect leftFrame = [mobileView frame];
    NSRect rightFrame = [desktopView frame];
    
    self.mWidthSetter.intValue = 0;
    [self.mWidthPop close];
    
    [mobileWidth setStringValue:[NSString stringWithFormat: @"%.f", floor(leftFrame.size.width)]];
    [desktopWidth setStringValue:[NSString stringWithFormat: @"%.f", floor(rightFrame.size.width)]];
    [theSplits_ adjustSubviews];
}

#pragma -- Helper/Conveience functions

- (IBAction)clearCache:(id)sender {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (IBAction)getImageFromWeb:(id)sender {
    CGSize contentSize = CGSizeMake([[mobileView stringByEvaluatingJavaScriptFromString:@"document.body.scrollWidth;"] floatValue],
                                    [[mobileView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight;"] floatValue]);

    NSView *viewport = [[[mobileView mainFrame] frameView] documentView]; // width/height of html page
	NSRect viewportBounds = [viewport bounds];
    NSRect frame = NSMakeRect(0.0, 0.0, contentSize.width, contentSize.height);
    
    NSWindow *hiddenWindow = [[NSWindow alloc] initWithContentRect: NSMakeRect( -1000,-1000, contentSize.width, contentSize.height ) styleMask: NSTitledWindowMask | NSClosableWindowMask backing:NSBackingStoreNonretained defer:NO];
    WebView *hiddenWebView = [[WebView alloc] initWithFrame:frame frameName:@"Hidden.Frame" groupName:nil];

    NSString *hURL = [textField stringValue];
    [hiddenWindow setContentView:hiddenWebView];
    
    [[hiddenWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:hURL]]];
    [hiddenWebView lockFocus];
    
    while ([hiddenWebView isLoading]) {
        [hiddenWebView setNeedsDisplay:NO];
        [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate dateWithTimeIntervalSinceNow:1.0] inMode:NSDefaultRunLoopMode dequeue:YES];
    }
    
    [hiddenWebView setNeedsDisplay:YES];
    
    bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:viewportBounds];
    
    [hiddenWebView unlockFocus];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSPicturesDirectory, NSUserDomainMask, YES);
    NSString *theDesktopPath = [paths objectAtIndex:0];
    
    NSMutableString *filename = [NSMutableString stringWithFormat:@"%@", [mobileView mainFrameTitle]];
    
    [filename replaceOccurrencesOfString:@" - " withString:@"." options:NSLiteralSearch range:NSMakeRange(0, [filename length])];
    [filename replaceOccurrencesOfString:@" " withString:@"." options:NSLiteralSearch range:NSMakeRange(0, [filename length])];
    
    NSString *savePath = [NSString stringWithFormat:@"%@/%@.%@", theDesktopPath, filename, @"png"];
    [[bitmap representationUsingType:NSPNGFileType properties:nil] writeToFile:savePath atomically:YES];
}

//- (IBAction)getImageFromWeb:(id)sender {
//    if ([mobileView respondsToSelector:@selector(setMediaStyle:)]) {
//        [mobileView setMediaStyle:@"screen"];
//    }
//
//    CGSize contentSize = CGSizeMake([[mobileView stringByEvaluatingJavaScriptFromString:@"document.body.scrollWidth;"] floatValue],
//                                    [[mobileView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight;"] floatValue]);
//
//    NSLog(@"%f", contentSize.height);
//    
//    CGRect aFrame = [[[mobileView mainFrame] frameView] documentView].frame;
//
//    aFrame.size.height = contentSize.height;
//
//    pdfData = [[[[mobileView mainFrame] frameView] documentView] dataWithPDFInsideRect:[[[mobileView mainFrame] frameView] documentView].frame];
//    bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:aFrame];
//
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSPicturesDirectory, NSUserDomainMask, YES);
//    NSString *theDesktopPath = [paths objectAtIndex:0];
//
//    NSMutableString *filename = [NSMutableString stringWithFormat:@"%@", [mobileView mainFrameTitle]];
//
//    [filename replaceOccurrencesOfString:@" - " withString:@"." options:NSLiteralSearch range:NSMakeRange(0, [filename length])];
//    [filename replaceOccurrencesOfString:@" " withString:@"." options:NSLiteralSearch range:NSMakeRange(0, [filename length])];
//
//    NSString *savePath = [NSString stringWithFormat:@"%@/%@.%@", theDesktopPath, filename, @"png"];
//
//    [[bitmap representationUsingType:NSPNGFileType properties:nil] writeToFile:savePath atomically:YES];
//}

@end