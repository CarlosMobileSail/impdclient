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

#import "AlbumsView.h"
#import "impdclientApp.h"

//////////////////////////////////////////////////////////////////////////
// AlbumsView: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation AlbumsView

- (void)dealloc
{
	// Release all objects.
	[_table release];
	[_albums release];
	[_title release];
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

	// Create the storage array.
	_albums = [[NSMutableArray alloc] init];

	// Create the table.
	_table = [[UITable alloc] initWithFrame: CGRectMake(0, NAVBARHEIGHT, 320, MAXHEIGHT)];
	[self addSubview: _table]; 
	UITableColumn* col = [[UITableColumn alloc] initWithTitle: @"iMPDclient" identifier: @"column1" width: 320.0f];
	[_table addTableColumn: col]; 
	[_table setDelegate: self];
	[_table setDataSource: self];
	[_table setSeparatorStyle:1];
	[_table setRowHeight:42.0f];

	// Create the navigation bar.
	_navBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 320, NAVBARHEIGHT)];
	[_navBar showLeftButton:@"Artists" withStyle:2 rightButton:nil withStyle:0];		// 2 = arrow left.
	[_navBar setBarStyle: 1];	// Dark style.
	[_navBar setDelegate:self];
	[_navBar enableAnimation];

	_title = [[UINavigationItem alloc] initWithTitle:@"--:--"];
	[_navBar pushNavigationItem: _title];

	[self addSubview: _navBar];
	return self;
}

//  --- OTHER METHODS -----------------------------------------------

- (void)showAlbums:(NSString *)artistName
{
	if (!_mpdServer)
		return;
	// Clear the array.
	[_albums removeAllObjects];
	// Get the list of albums.
	mpd_database_search_field_start(_mpdServer, MPD_TAG_ITEM_ALBUM);
	mpd_database_search_add_constraint(_mpdServer, MPD_TAG_ITEM_ARTIST, [artistName cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	MpdData *data = mpd_database_search_commit(_mpdServer);
	if (data) {
		int count = 0;
		do {
			if (data->type == MPD_DATA_TYPE_TAG) {
				// Create album object and add it to the array.
				UIImageAndTextTableCell* cell = [[UIImageAndTextTableCell alloc] init];
				[cell setTitle:[NSString stringWithCString: data->tag]];
				[cell setShowDisclosure: YES];
				[cell setDisclosureStyle: 2];
				[_albums addObject:cell];
				[cell release];
				count++;
			}
			// Go to the next entry.
			data = mpd_data_get_next(data);
		} while(data);
	} else
		NSLog(@"No data found");
	// Update the table contents.
	[_table reloadData];
	[_title setTitle: artistName];
	_artistName = [artistName copy];
}

//  --- DELEGATE METHODS -----------------------------------------------

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button
{
	NSLog(@"AlbumsView: button %d", button);
	if (button == 0)
		[_app cleanUp];
	else if (button == 1)
		[_app showArtistsViewWithTransition:2];
}


- (void)tableRowSelected:(NSNotification*)notification 
{
	// Get selected cell and album name.
	UIImageAndTextTableCell* cell = [[notification object] cellAtRow:[[notification object] selectedRow] column:0];
	NSLog(@"Selected album: %@", [cell title]);
	// Show the songs of the selected album.
	[cell setSelected:FALSE withFade:TRUE];
	[_app showSongsViewWithTransition:1 album:[cell title] artist:_artistName];
}


- (int) numberOfRowsInTable: (UITable *)table
{
	return [_albums count];
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col
{
	return [_albums objectAtIndex:row];
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col reusing: (BOOL) reusing
{
	return [self table: table cellForRow: row column: col];
}

@end
