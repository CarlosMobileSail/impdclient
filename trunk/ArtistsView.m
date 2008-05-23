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
#import <UIKit/UITable.h>
#import <UIKit/UITableCell.h>
#import <UIKit/UITableColumn.h>

#import "ArtistsView.h"
#import "impdclientApp.h"

//////////////////////////////////////////////////////////////////////////
// ArtistsView: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation ArtistsView

- (void)dealloc
{
	// Release all objects.
	[_table release];
	[_artists release];
	[_tableHeaders release];
	[_sectionList release];
	[_navBar release];
	// Call the base class.
	[super dealloc];
}


- (void)initialize:(MPDClientApplication *)app mpd:(MpdObj *)mpdServer
{
	_app = app;
	_mpdServer = mpdServer;
}


- (id)initWithFrame:(struct CGRect)frame
{
	self = [super initWithFrame:frame];
	_app = NULL;
	_mpdServer = NULL;
	
	// Create the storage arrays.
	_artists = [[NSMutableArray alloc] init];
	_tableHeaders = [[NSMutableArray alloc] init];
	
	CGRect aRect = CGRectMake(0, NAVBARHEIGHT, 320, MAXHEIGHT);
	// Create the section list.
	_sectionList = [[UISectionList alloc] initWithFrame:aRect showSectionIndex:YES];
	[_sectionList setDataSource:self];
	[_sectionList reloadData];
	[self addSubview:_sectionList];

	// Get the real table.
	_table = [_sectionList table];
	UITableColumn *col = [[UITableColumn alloc] initWithTitle: @"iMPDclient" identifier: @"column1" width: 320];
	[_table addTableColumn: col]; 
	[_table setDelegate: self];
	[_table setSeparatorStyle:1];
	[_table setRowHeight:42.0f];

	// Create the navigation bar.
	_navBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 320, NAVBARHEIGHT)];
	[_navBar showLeftButton:@"Playlist" withStyle:2 rightButton:@"Search" withStyle:3];		// 2 = arrow left, 3 = blue.
	[_navBar setBarStyle: 1];	// Dark style.
	[_navBar setDelegate:self];
	[_navBar enableAnimation];

	_title = [[UINavigationItem alloc] initWithTitle:@"--:--"];
	[_navBar pushNavigationItem: _title];
	
	[self addSubview: _navBar];
	return self;
}

//  --- OTHER METHODS -----------------------------------------------

- (void)showArtists
{
	if (!_mpdServer)
		return;
	// Clear the arrays.
	[_artists removeAllObjects];
	[_tableHeaders removeAllObjects];
	// Get the list of artists.
	mpd_database_search_field_start(_mpdServer, MPD_TAG_ITEM_ARTIST);
	MpdData *data = mpd_database_search_commit(_mpdServer);
	if (data) {
		NSString* prevSection = @"";
		int count = 0;
		do {
			if (data->type == MPD_DATA_TYPE_TAG) {
				// Convert the name.
				NSString* artistName = [NSString stringWithCString: data->tag];
				// Determine the first letters for the section list.
				NSString* firstLetter = [artistName substringWithRange:NSMakeRange(0,1)];
				if (![firstLetter isEqual:prevSection]) {
					prevSection = [firstLetter copy];
					// NSLog(@"%@ - %d", firstletter, count);
					NSMutableDictionary* cellDict = [[NSMutableDictionary alloc] initWithCapacity:2];
					[cellDict setObject:firstLetter forKey:@"title"];
					[cellDict setObject:[[NSNumber alloc] initWithInt:count] forKey:@"beginRow"];
					[_tableHeaders addObject: cellDict];
					[cellDict release];
				}
				// Create artist object and add it to the array.
				UIImageAndTextTableCell* cell = [[UIImageAndTextTableCell alloc] init];
				[cell setTitle:artistName];
				[_artists addObject:cell];
				[cell release];
				count++;
			}
			// Go to the next entry.
			data = mpd_data_get_next(data);
		} while(data);
	} else
		NSLog(@"No data found");
	// Update the table contents.
	[_sectionList reloadData];
}


- (void)updateTitle
{
	int totalTime = mpd_status_get_total_song_time(_mpdServer);
	int elapsedTime = mpd_status_get_elapsed_song_time(_mpdServer);
	NSString* str = [NSString stringWithFormat:@"%d:%02d - %d:%02d", elapsedTime / 60, elapsedTime % 60, totalTime / 60, totalTime % 60];
	[_title setTitle: str]; 
}

//  --- DELEGATE METHODS -----------------------------------------------

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button
{
	NSLog(@"ArtistView: button %d", button);
	if (button == 0)
		[_app showSearchViewWithTransition:1];
	else if (button == 1)
		[_app showPlaylistViewWithTransition:2];
}


- (void)tableRowSelected:(NSNotification*)notification 
{
	// Get selected cell and artist name.
	UIImageAndTextTableCell* cell = [[notification object] cellAtRow:[[notification object] selectedRow] column:0];
	NSLog(@"Selected artist: %@", [cell title]);
	// Show the albums of the selected artist.
	[cell setSelected:FALSE withFade:TRUE];
	[_app showAlbumsViewWithTransition:1 artist:[cell title]];
}


- (int)numberOfSectionsInSectionList:(UISectionList *)aSectionList {
	return [_tableHeaders count];
}

- (NSString *)sectionList:(UISectionList *)aSectionList titleForSection:(int)section {
	return [[_tableHeaders objectAtIndex:section] objectForKey:@"title"];
}

- (int)sectionList:(UISectionList *)aSectionList rowForSection:(int)section {
	return [[[_tableHeaders objectAtIndex:section] valueForKey:@"beginRow"] intValue];
}

- (int) numberOfRowsInTable: (UITable *)table
{
	return [_artists count];
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col
{
	return [_artists objectAtIndex:row];
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col reusing: (BOOL) reusing
{
	return [self table: table cellForRow: row column: col];
}

@end
