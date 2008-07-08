//
//  OVPreferenceController.m
//  OpenVanilla
//
//  Created by zonble on 2008/7/4.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "OVPreferenceController.h"
#import "OVShortcutHelper.h"

@implementation OVPreferenceController

#pragma mark Initialize the environment.

- (void)setExcludeList
{
	NSEnumerator *enumerator;
	
	_moduleLibraries = [NSMutableDictionary new];
    NSDictionary *history = [_loader loadHistory];
	enumerator = [[history allKeys] objectEnumerator];
    NSString *loaderKey;
    while (loaderKey = [enumerator nextObject]) {
        NSArray *loaderNode = [history valueForKey:loaderKey];
        NSMutableDictionary *newnode = [NSMutableDictionary dictionary];
        NSEnumerator *loaderEnumerator = [loaderNode objectEnumerator];
        NSString *s;
        while (s = [loaderEnumerator nextObject])  {
			[newnode setValue:[NSNumber numberWithBool:TRUE] forKey:s];
		}
        [_moduleLibraries setValue:newnode forKey:[loaderKey lastPathComponent]];        
    }
	
	NSArray *loaderConfig = [_config valueForKey:@"OVLoader"];
	
    _excludeModuleList = [NSMutableArray arrayWithArray:[loaderConfig valueForKey:@"excludeModuleList"]];
	[_excludeModuleList retain];
    enumerator = [[loaderConfig valueForKey:@"excludeLibraryList"] objectEnumerator];
    NSString *s;
    while (s = [enumerator nextObject]) {
        NSDictionary *moduleLibrary = [_moduleLibraries valueForKey:s];
        if (moduleLibrary) 
			[_excludeModuleList addObjectsFromArray:[moduleLibrary allKeys]];
    }
}

- (int)outputFilterExists:(NSString *)identifier inArray:(NSArray *)outputFilterArray
{
	if (![outputFilterArray count])
		return -1;
	NSEnumerator *e = [outputFilterArray objectEnumerator];
	NSDictionary *d;
	int i = 0;
	while (d = [e nextObject]) {
		NSString *s = [d valueForKey:@"identifier"];		
		if ([s isEqualToString:identifier]) {
			return i;
		}
		i++;
	}
	return -1;
}

- (void)setUpModules
{
	NSEnumerator *enumerator;
	
	NSDictionary *menuManagerDictionary = [_config valueForKey:@"OVMenuManager"];
	NSArray *outputFilterOrderConfigArray = [menuManagerDictionary valueForKey:@"outputFilterOrder"];
	NSMutableArray *outputFilterOrderArray = [NSMutableArray array];
	enumerator = [outputFilterOrderConfigArray objectEnumerator];
	NSString *outputFilterIdentfier;
	
	while (outputFilterIdentfier = [enumerator nextObject]) {
		NSMutableDictionary *d = [NSMutableDictionary dictionary];
		[d setValue:outputFilterIdentfier forKey:@"identifier"];
		[outputFilterOrderArray addObject:d];
	}
		
	NSArray *moduleLists = [_loader moduleList];
	if (!moduleLists) {
		moduleLists = [NSArray array];
	}
	
	const char *locale = [_loader service]->locale();	

	enumerator = [moduleLists objectEnumerator];
	CVModuleWrapper *w;
	
	while (w = [enumerator nextObject]) {
        OVModule *ovm = [w module];
		NSString *identifier = [w identifier];
        NSString *localizedName = [NSString stringWithUTF8String:ovm->localizedName(locale)];
		NSDictionary *dictionary = [_config valueForKey:identifier];
		BOOL enabled = ![_excludeModuleList containsObject:identifier];
		NSString *shortcut = [menuManagerDictionary valueForKey:identifier];
		
		if (!dictionary) {
			dictionary = [NSDictionary dictionary];
		}
		
		if ([[w moduleType] isEqualToString:@"OVInputMethod"]) {
			// The Generic Input Method modules.
			if ([identifier isEqualToString:@"OVIMPhonetic"]) {
				OVIMPhoneticController *moduleCotroller = [[OVIMPhoneticController alloc] initWithIdentifier:identifier localizedName:localizedName dictionary:dictionary enabled:enabled delegate:self shortcut:shortcut];
				[m_moduleListController addInputMethod:moduleCotroller];
			}			
			else if ([identifier isEqualToString:@"OVIMPOJ-Holo"]) {
				OVIMPOJHoloController *moduleCotroller = [[OVIMPOJHoloController alloc] initWithIdentifier:identifier localizedName:localizedName dictionary:dictionary enabled:enabled delegate:self shortcut:shortcut];
				[m_moduleListController addInputMethod:moduleCotroller];
			}
			else if ([identifier isEqualToString:@"OVIMTibetan"]) {				
				OVIMTibetanController *moduleCotroller = [[OVIMTibetanController alloc] initWithIdentifier:identifier localizedName:localizedName dictionary:dictionary enabled:enabled delegate:self shortcut:shortcut];
				[m_moduleListController addInputMethod:moduleCotroller];
			}
			else if ([identifier hasPrefix:@"OVIMGeneric-"]) {
				OVIMGenericController *moduleCotroller = [[OVIMGenericController alloc] initWithIdentifier:identifier localizedName:localizedName dictionary:dictionary enabled:enabled delegate:self shortcut:shortcut];
				[m_moduleListController addInputMethod:moduleCotroller];				
			}
			// The Input Methods with extra settings.
			else if ([dictionary count]) {
				OVTableModuleController *moduleCotroller = [[OVTableModuleController alloc] initWithIdentifier:identifier localizedName:localizedName dictionary:dictionary enabled:enabled delegate:self shortcut:shortcut];
				[m_moduleListController addInputMethod:moduleCotroller];
			}
			// The Input Methods without extar settings.
			else {
				OVModuleController *moduleCotroller = [[OVModuleController alloc] initWithIdentifier:identifier localizedName:localizedName dictionary:dictionary enabled:enabled delegate:self shortcut:shortcut];
				[m_moduleListController addInputMethod:moduleCotroller];
			}
		}
		else if ([[w moduleType] isEqualToString:@"OVOutputFilter"]) {
			int i = [self outputFilterExists:identifier inArray:outputFilterOrderArray];
			if (i >= 0) {
				NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:[outputFilterOrderArray objectAtIndex:i]];
				[d setValue:localizedName forKey:@"localizedName"];
//				[d setValue:dictionary forKey:@"dictionary"];
				[d setValue:shortcut forKey:@"shortcut"];
				[d setValue:[NSNumber numberWithBool:enabled] forKey:@"enabled"];
				[outputFilterOrderArray replaceObjectAtIndex:i withObject:d];
			}
			else {
				NSMutableDictionary *d = [NSMutableDictionary dictionary];
				[d setValue:identifier forKey:@"identifier"];
				[d setValue:localizedName forKey:@"localizedName"];
//				[d setValue:dictionary forKey:@"dictionary"];
				[d setValue:shortcut forKey:@"shortcut"];				
				[d setValue:[NSNumber numberWithBool:enabled] forKey:@"enabled"];					
				[outputFilterOrderArray addObject:d];
			}			
		}
	}
	
	enumerator = [outputFilterOrderArray objectEnumerator];
	NSDictionary *d;
	while (d = [enumerator nextObject]) {
		NSString *identifier = [d valueForKey:@"identifier"];
		NSString *localizedName = [d valueForKey:@"localizedName"];
//		NSDictionary *dictionary = [d valueForKey:@"dictionary"];
		BOOL enabled = [[d valueForKey:@"enabled"] boolValue];
		NSString *shortcut = [d valueForKey:@"shortcut"];
		OVModuleController *moduleCotroller = [[OVModuleController alloc] initWithIdentifier:identifier localizedName:localizedName dictionary:nil enabled:enabled delegate:self shortcut:shortcut];
		[m_moduleListController addOutputFilter:moduleCotroller];
	}
	
	[m_moduleListController expandAll];
}

- (void)setDisplayController
{
	NSString *identifier = @"OVDisplayServer";
	NSString *localizedName = @"";
	NSDictionary *dictionary = [_config valueForKey:identifier];
	NSDictionary *menuManagerDictionary = [_config valueForKey:@"OVMenuManager"];	
	NSString *shortcut = [menuManagerDictionary valueForKey:@"fastIMSwitch"];
	m_displayController = [[OVDisplayController alloc] initWithIdentifier:identifier localizedName:localizedName dictionary:dictionary enabled:NO delegate:self shortcut:shortcut];
}

- (void)awakeFromNib
{	
	[[self window] setDelegate:self];
			
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@""];
	[toolbar setDelegate:self];
	[toolbar autorelease];
	[toolbar setSelectedItemIdentifier:GeneralToolbarItemIdentifier];	
	[[self window] setToolbar:toolbar];
	
	_loader = [CVEmbeddedLoader new];
    _config = [[NSMutableDictionary dictionaryWithDictionary:[[_loader config] dictionary]] retain];
	
	[self setExcludeList];
	[self setUpModules];
	[self setDisplayController];

	[self setActiveView:[m_displayController view] animate:NO];	
	[[self window] setTitle:MSG(GeneralToolbarItemIdentifier)];
	[[self window] center];
}

- (void) dealloc
{
	[_loader release];
	[_config release];
	[_moduleLibraries release];
	[_excludeModuleList release];
	[super dealloc];
}

#pragma mark The main User Interface of the preference tool.

- (void)setActiveView:(NSView *)view animate:(BOOL)flag
{	
	NSRect windowFrame = [[self window] frame];
	windowFrame.size.height = [view frame].size.height + WINDOW_TITLE_HEIGHT;
	windowFrame.size.width = [view frame].size.width;
	windowFrame.origin.y = NSMaxY([[self window] frame]) - ([view frame].size.height + WINDOW_TITLE_HEIGHT);

	if ([[u_mainView subviews] count] != 0)
		[[[u_mainView subviews] objectAtIndex:0] removeFromSuperview];
	
	[[self window] setFrame:windowFrame display:YES animate:flag];		
	[u_mainView setFrame:[view frame]];
	[u_mainView addSubview:view];
}

- (void)toggleActivePreferenceView:(id)sender
{
	NSView *view;
	
	if ([[sender itemIdentifier] isEqualToString:GeneralToolbarItemIdentifier])
		view = [m_displayController view];
	else if ([[sender itemIdentifier] isEqualToString:ModulesToolbarItemIdentifier])
		view = [m_moduleListController view];
	
	[self setActiveView:view animate:YES];
	[[self window] setTitle:MSG([sender itemIdentifier])];
}

#pragma mark NSWindow delegate methods.

- (void)windowWillClose:(NSNotification *)notification
{
	// We will terminate the application when the main window is closed.
	[NSApp terminate:self];
}

#pragma mark NSObject delegate methods.

- (void)changeFont:(id)sender
{
	[m_displayController changeFont:sender];
}

#pragma mark Methods to update configurations.
// Most of the methods are defined in NSObjectUpdateConfig.h.

- (BOOL)updateConfigWithIdentifer:(NSString *)identifier dictionary:(NSDictionary *)dictionary
{
	if (!identifier || ![identifier length])
		return NO;
	if (!dictionary)
		return NO;
	
	[_config setValue:dictionary forKey:identifier];
	
	return YES;
}
- (void)writeConfigWithIdentifer:(NSString *)identifier dictionary:(NSDictionary *)dictionary
{
	if ([self updateConfigWithIdentifer:identifier dictionary:dictionary])
		[self writeConfig];
}
- (void)updateOutputFilterOrder:(NSArray *)order
{
	NSMutableDictionary *menuManagerDictionary = [NSMutableDictionary dictionaryWithDictionary:[_config valueForKey:@"OVMenuManager"]];
	[menuManagerDictionary setValue:order forKey:@"outputFilterOrder"];
	[self writeConfigWithIdentifer:@"OVMenuManager" dictionary:menuManagerDictionary];
}
- (void)setNewExcludeList
{
	NSMutableArray *newLibExclude = [NSMutableArray array];
    NSMutableArray *newModeExclude = [NSMutableArray array];
	
	NSLog([_moduleLibraries description]);
	
	NSEnumerator *enumerator = [[_moduleLibraries allKeys] objectEnumerator];
	NSString *libraryName;
	while (libraryName = [enumerator nextObject]) {
		NSDictionary *node = [_moduleLibraries valueForKey:libraryName];
		NSArray *modulesInNode = [node allKeys];
		NSMutableArray *disabledModules = [NSMutableArray array];
		NSEnumerator *e = [modulesInNode objectEnumerator];
		while (NSString *identifier = [e nextObject]) {
			if ([_excludeModuleList containsObject:identifier])
				[disabledModules addObject:identifier];
		}
		if ([modulesInNode count] == [disabledModules count]) {
			[newLibExclude addObject:libraryName];
		}
		else {
			if ([disabledModules count]) {
				[newModeExclude addObjectsFromArray:disabledModules];
			}
		}
	}
	NSMutableDictionary *loaderConfig = [NSMutableDictionary dictionaryWithDictionary:[_config valueForKey:@"OVLoader"]];
	[loaderConfig setValue:newLibExclude forKey:@"excludeLibraryList"];	
	[loaderConfig setValue:newModeExclude forKey:@"excludeModuleList"];
	[self writeConfigWithIdentifer:@"OVLoader" dictionary:loaderConfig];	
	
}
- (void)addModuleToExcludeList:(NSString *)identifier
{
	[_excludeModuleList addObject:identifier];
	[self setNewExcludeList];
}
- (void)removeModuleFromExcludeList:(NSString *)identifier
{
	[_excludeModuleList removeObject:identifier];
	[self setNewExcludeList];
}
- (void)updateShortcut:(NSString *)shortcut forModule:(NSString *)identifier
{
	NSMutableDictionary *menuManagerDictionary = [NSMutableDictionary dictionaryWithDictionary:[_config valueForKey:@"OVMenuManager"]];
	[menuManagerDictionary setValue:shortcut forKey:identifier];
	[self writeConfigWithIdentifer:@"OVMenuManager" dictionary:menuManagerDictionary];
}
- (NSString *)beepSound
{
	NSString *beepSound = [[_config valueForKey:@"OVLoader"] valueForKey:@"beepSound"];
	return beepSound;
}
- (void)updateBeepSound:(NSString *)beepSound
{
	NSLog(@"updateBeepSound: %@",  beepSound);
	NSMutableDictionary *loaderConfig = [NSMutableDictionary dictionaryWithDictionary:[_config valueForKey:@"OVLoader"]];
	[loaderConfig setValue:beepSound forKey:@"beepSound"];
	[self writeConfigWithIdentifer:@"OVLoader" dictionary:loaderConfig];
}
- (void)writeConfig
{
	[[_loader config] sync];
	[[[_loader config] dictionary] removeAllObjects];
	[[[_loader config] dictionary] addEntriesFromDictionary:_config];
	[[_loader config] sync];
}


@end
