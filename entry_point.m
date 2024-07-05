@import AppKit;
@import Metal;
@import QuartzCore;

#include "main_view.m"

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate
{
	NSWindow *window;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	[self createMainMenu];

	NSRect rect = NSMakeRect(100, 100, 500, 400);
	NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskResizable |
	                          NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
	window = [[NSWindow alloc] initWithContentRect:rect
	                                     styleMask:style
	                                       backing:NSBackingStoreBuffered
	                                         defer:NO];

	MainView *view = [[MainView alloc] initWithFrame:rect];
	window.contentView = view;

	[window makeKeyAndOrderFront:nil];

	[NSApp activate];
}

- (void)createMainMenu
{
	NSMenu *mainMenu = [[NSMenu alloc] init];

	NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
	[mainMenu addItem:appMenuItem];

	NSMenu *appMenu = [[NSMenu alloc] init];
	appMenuItem.submenu = appMenu;

	NSString *quitMenuItemTitle = [NSString stringWithFormat:@"Quit %@", [self appName]];
	NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitMenuItemTitle
	                                                      action:@selector(terminate:)
	                                               keyEquivalent:@"q"];

	[appMenu addItem:quitMenuItem];

	NSApp.mainMenu = mainMenu;
}

- (NSString *)appName
{
	NSBundle *bundle = NSBundle.mainBundle;
	return [bundle objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleNameKey];
}

@end

int
main(void)
{
	[NSApplication sharedApplication];
	AppDelegate *appDelegate = [[AppDelegate alloc] init];
	NSApp.delegate = appDelegate;
	[NSApp run];
}
