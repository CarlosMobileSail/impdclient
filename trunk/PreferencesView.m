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
#import "application.h"

//////////////////////////////////////////////////////////////////////////
// PreferencesView: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation PreferencesView

- (void)Initialize:(MPDClientApplication* )pApp mpd:(MpdObj *)pMPD
{
	m_pApp = pApp;
	m_pMPD = pMPD;
	// Set the values to the correct ones.
	int volume = mpd_status_get_volume(m_pMPD);
	[m_pVolumeSlider setValue: volume];
}


-(id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	m_pNavBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 320, NAVBARHEIGHT)];
	[m_pNavBar setDelegate:self];
	[m_pNavBar setBarStyle: 1];	// Dark style.
	[m_pNavBar enableAnimation]; 
	[m_pNavBar showButtonsWithLeftTitle:@"Close" rightTitle:nil leftBack:nil];
 	[m_pNavBar pushNavigationItem: [[UINavigationItem alloc] initWithTitle: @"Preferences"]];
	[self addSubview:m_pNavBar];

	m_pTable = [[UIPreferencesTable alloc] initWithFrame:CGRectMake(0, NAVBARHEIGHT, 320, MAXHEIGHT)];
	[m_pTable setDataSource:self];
	[m_pTable setDelegate:self];
	[m_pTable reloadData];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationsUpdated:) name:@"HostnameUpdated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(countriesUpdated:) name:@"PortUpdated" object:nil];
	[self addSubview:m_pTable];
	
	m_pHostnameCell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 48.0f, frame.size.width, 48.0f)];
	[m_pHostnameCell setTitle:@"Hostname:"];
	[m_pHostnameCell setValue:@"192.168.2.2"];
	
	m_pPortCell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 48.0f, frame.size.width, 48.0f)];
	[m_pPortCell setTitle:@"Port:"];
	[m_pPortCell setValue:@"6600"];

	m_pVolumeCell = [[UIPreferencesTableCell alloc] init];
	[m_pVolumeCell setTitle:@"Volume"];
	[m_pVolumeCell setShowSelection:NO];
	
	m_pVolumeSlider = [[UISliderControl alloc] initWithFrame:CGRectMake(90, 12, 210, 24)];
	[m_pVolumeSlider setMinValue:0.0];
	[m_pVolumeSlider setMaxValue:100.0];
	[m_pVolumeSlider setShowValue:YES];
	[m_pVolumeSlider addTarget:self action:@selector(changeVolume) forEvents:1|4]; // mouseDown | mouseDragged
	[m_pVolumeCell addSubview:m_pVolumeSlider];
	
	return self;
}

- (void) dealloc
{
	[super dealloc];
	
	[m_pHostnameCell release];
	[m_pPortCell release];

	[m_pTable release];
	[m_pNavBar release];
}

- (void)countriesUpdated:(NSNotification *)notification
{
}

- (void)locationsUpdated:(NSNotification *)notification
{
//	[_citycell setTitle:[[ms dataManager] getDefaultCountry]];
//	[_citycell setValue:[[ms dataManager] getDefaultCity]];
}

- (void)changeVolume
{
	int volume = [m_pVolumeSlider value];
//	NSLog(@"Change volume %d", volume);
	mpd_status_set_volume(m_pMPD, volume);
}

#pragma mark ---------------Datasource Methods---------------

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
		case 0:	return m_pHostnameCell;	break;
		case 1:	return m_pPortCell;		break;
		}
	}
	if (group == 1) {
		switch (row) {
		case 0: return m_pVolumeCell;	break;
		}
	}
	return nil;
}

- (void)tableRowSelected:(NSNotification *)notification 
{
	int i = [m_pTable selectedRow];
	switch (i){
		case  1: 
		{
			[[m_pTable cellAtRow:i column:0] setSelected:YES];
//			[ms  showEditKeywordViewWithTransition:1];
			break;
		}
		case  3: 
		{
			[[m_pTable cellAtRow:i column:0] setSelected:YES];
//			[ms  showDefaultCountryViewWithTransition:1];
			break;
		}
		default:
		{
			[[m_pTable cellAtRow:i column:0] setSelected:NO];
			break; 
		}
	}
}

#
#pragma mark ---------------Navigation Methods---------------

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button 
{
	NSLog(@"PreferencesView: button %d", button);
	if (button == 1)
		[m_pApp showPlaylistViewWithTransition:5];
}

@end