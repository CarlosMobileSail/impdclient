/*******************************************************************************
 * iPhone Project : iMPDclient                                                 *
 * Copyright (C) 2008 Boris Nagels <joogels@gmail.com>                         *
 *******************************************************************************
 * $LastChangedDate:: 2008-01-29 22:02:23 +0100 (Tue, 29 Jan 2008)           $ *
 * $LastChangedBy:: boris                                                    $ *
 * $LastChangedRevision:: 140                                                $ *
 * $Id:: application.m 140 2008-01-29 21:02:23Z boris                        $ *
 *******************************************************************************
 *  This program is free software: you can redistribute it and/or modify       *
 *  it under the terms of the GNU General Public License as published by       *
 *  the Free Software Foundation, either version 3 of the License, or          *
 *  (at your option) any later version.                                        *
 *                                                                             *
 *  This program is distributed in the hope that it will be useful,            *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of             *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *
 *  GNU General Public License for more details.                               *
 *                                                                             *
 *  You should have received a copy of the GNU General Public License          *
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.      *
 *******************************************************************************/
 
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UISliderControl.h>

#import "PreferencesView.h"
#import "impdclientApp.h"

//////////////////////////////////////////////////////////////////////////
// PreferencesView: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation PreferencesView

- (void)dealloc
{
	// Release all objects.
	[_hostnameCell release];
	[_portCell release];
	[_volumeCell release];
	[_volumeSlider release];
	[_table release];
	[_navBar release];
	// Call the base class.
	[super dealloc];
}


- (void)initialize:(MPDClientApplication *)app mpd:(MpdObj *)mpdServer
{
	_app = app;
	_mpdServer = mpdServer;
	// Set the values to the correct ones.
	int volume = mpd_status_get_volume(_mpdServer);
	[_volumeSlider setValue: volume];
}


-(id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	_navBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 320, NAVBARHEIGHT)];
	[_navBar setDelegate:self];
	[_navBar setBarStyle: 1];	// Dark style.
	[_navBar enableAnimation]; 
 	[_navBar showLeftButton:@"Hide" withStyle:0 rightButton:@"About" withStyle:0];
	[_navBar pushNavigationItem: [[UINavigationItem alloc] initWithTitle: @"Preferences"]];
	[self addSubview:_navBar];

	_table = [[UIPreferencesTable alloc] initWithFrame:CGRectMake(0, NAVBARHEIGHT, 320, MAXHEIGHT)];
	[_table setDataSource:self];
	[_table setDelegate:self];
	[_table reloadData];
	[self addSubview:_table];
	
	// Get the hostname and port number.
	NSUserDefaults* pDefaults = [NSUserDefaults standardUserDefaults];
	NSString* hostname = [pDefaults stringForKey:@"hostname"];
	int port = [pDefaults integerForKey:@"port"];
	_hostnameCell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 48.0f, frame.size.width, 48.0f)];
	[_hostnameCell setTitle:@"Hostname:"];
	[[[_hostnameCell textField] textTraits] setAutoCapsType:0];
	[_hostnameCell setValue:hostname];
	
	_portCell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 48.0f, frame.size.width, 48.0f)];
	[_portCell setTitle:@"Port:"];
	[[[_portCell textField] textTraits] setAutoCapsType:0];
	[[[_portCell textField] textTraits] setPreferredKeyboardType:2];		// numbers only.
	[_portCell setValue:[NSString stringWithFormat: @"%i", port]];

	_volumeCell = [[UIPreferencesTableCell alloc] init];
	[_volumeCell setTitle:@"Volume"];
	[_volumeCell setShowSelection:NO];
	
	_volumeSlider = [[UISliderControl alloc] initWithFrame:CGRectMake(90, 12, 210, 24)];
	[_volumeSlider setMinValue:0.0];
	[_volumeSlider setMaxValue:100.0];
	[_volumeSlider setShowValue:YES];
	[_volumeSlider addTarget:self action:@selector(changeVolume) forEvents:1|4]; // mouseDown | mouseDragged
	[_volumeCell addSubview:_volumeSlider];
	
	return self;
}


- (void)changeVolume
{
	int volume = [_volumeSlider value];
	mpd_status_set_volume(_mpdServer, volume);
	//	NSLog(@"Change volume %d", volume);
}


- (void)saveSettings
{
	NSUserDefaults* pDefaults = [NSUserDefaults standardUserDefaults];
	[pDefaults setObject:[_hostnameCell value] forKey:@"hostname"];
	[pDefaults setInteger:[[_portCell value] intValue] forKey:@"port"];
}


- (void)displayAbout
{
	UIAlertSheet * hotSheet = [[UIAlertSheet alloc]
							   initWithTitle:@"iMPDclient v1.0"
							   buttons:[NSArray arrayWithObject:NSLocalizedString(@"OK", nil)]
							   defaultButtonIndex:0
							   delegate:self
							   context:self];
	
	[hotSheet setBodyText:@"iPod remote for your MPD server. Copyright 2008, Boris Nagels"];
	[hotSheet setDimsBackground:YES];
	[hotSheet setRunsModal:YES];
	[hotSheet setShowsOverSpringBoardAlerts:NO];
	[hotSheet popupAlertAnimated:YES];	
}

//////////////////////////////////////////////////////////////////////////
// Datasource Methods
//////////////////////////////////////////////////////////////////////////

- (int)numberOfGroupsInPreferencesTable:(UIPreferencesTable *)table
{
	return 2;
}

- (float)preferencesTable:(id)table heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposedHeight;
{
	return 48.0f;
}

- (int)preferencesTable:(UIPreferencesTable *)table numberOfRowsInGroup:(int)group
{
	if (group == 0)
		return 2;
	if (group == 1)
		return 1;
	return 0;
}

- (id)preferencesTable:(id)preferencesTable titleForGroup:(int)group
{
	NSString *title = nil;
	switch (group) {
	case 0:
		title = @"Server information:";
		break;
	case 1:
		title = @"Server settings:";
		break;
	}
	return title;
}

- (UIPreferencesTableCell *)preferencesTable:(UIPreferencesTable *)table cellForRow:(int)row inGroup:(int)group
{
	if (group == 0) {
		switch (row) {
		case 0:	return _hostnameCell;	break;
		case 1:	return _portCell;		break;
		}
	}
	if (group == 1) {
		switch (row) {
		case 0: return _volumeCell;	break;
		}
	}
	return nil;
}

//////////////////////////////////////////////////////////////////////////
// Navigation Methods
//////////////////////////////////////////////////////////////////////////

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button 
{
	NSLog(@"PreferencesView: button %d", button);
	if (button == 1) {
		[_app showPlaylistViewWithTransition:5];
		// Save the settings.
		[self saveSettings];
	} else {
		// Show the about dialog.
		[self displayAbout];
	}
}


- (void)alertSheet:(id)sheet buttonClicked:(int)buttonIndex
{
	// Just close and release all sheets.
	[sheet dismissAnimated:YES];
	[sheet release];
}

@end