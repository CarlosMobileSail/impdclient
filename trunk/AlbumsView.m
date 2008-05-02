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
#import "application.h"

//////////////////////////////////////////////////////////////////////////
// AlbumsView: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation AlbumsView

- (void)Initialize:(MPDClientApplication* )pApp mpd:(MpdObj *)pMPD
{
	m_pApp = pApp;
	m_pMPD = pMPD;
}


- (id)initWithFrame:(struct CGRect)frame
{
	self = [super initWithFrame:frame];
	m_pApp = NULL;
	m_pMPD = NULL;

	// Create the storage array.
	m_pAlbums = [[NSMutableArray alloc] init];

	// Create the table.
	m_pTable = [[UITable alloc] initWithFrame: CGRectMake(0, NAVBARHEIGHT, 320, MAXHEIGHT)];
	[self addSubview: m_pTable]; 
	UITableColumn *col = [[UITableColumn alloc] initWithTitle: @"iMPDclient" identifier: @"column1" width: 320.0f];
	[m_pTable addTableColumn: col]; 
	[m_pTable setDelegate: self];
	[m_pTable setDataSource: self];
	[m_pTable setSeparatorStyle:1];
	[m_pTable setRowHeight:42.0f];

	// Create the navigation bar.
	UINavigationBar* nav = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 320, NAVBARHEIGHT)];
	[nav showLeftButton:@"Artists" withStyle:2 rightButton:nil withStyle:0];		// 2 = arrow left.
	[nav setBarStyle: 1];	// Dark style.
	[nav setDelegate:self];
	[nav enableAnimation];

	m_pTitle = [[UINavigationItem alloc] initWithTitle:@"--:--"];
	[nav pushNavigationItem: m_pTitle];

	[self addSubview: nav];
	return self;
}

//  --- OTHER METHODS -----------------------------------------------

- (void)ShowAlbums:(NSString *)artistname
{
	if (!m_pMPD)
		return;
	// Clear the array.
	[m_pAlbums removeAllObjects];
	// Get the list of albums.
	mpd_database_search_field_start(m_pMPD, MPD_TAG_ITEM_ALBUM);
	mpd_database_search_add_constraint(m_pMPD, MPD_TAG_ITEM_ARTIST, [artistname cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	MpdData *data = mpd_database_search_commit(m_pMPD);
	if (data) {
		int count = 0;
		do {
			if (data->type == MPD_DATA_TYPE_TAG) {
				// Create album object and add it to the array.
				UIImageAndTextTableCell *cell = [[UIImageAndTextTableCell alloc] init];
				[cell setTitle:[NSString stringWithCString: data->tag]];
				[cell setShowDisclosure: YES];
				[cell setDisclosureStyle: 2];
				[m_pAlbums addObject:cell];
				[cell release];
				count++;
			}
			// Go to the next entry.
			data = mpd_data_get_next(data);
		} while(data);
	} else
		NSLog(@"No data found");
	// Update the table contents.
	[m_pTable reloadData];
	[m_pTitle setTitle: artistname];
	m_pArtistName = [artistname copy];
}

//  --- DELEGATE METHODS -----------------------------------------------

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button
{
	NSLog(@"AlbumsView: button %d", button);
	if (button == 0)
		[m_pApp cleanUp];
	else if (button == 1)
		[m_pApp showArtistsViewWithTransition:2];
}


- (void)tableRowSelected:(NSNotification*)notification 
{
	// Get selected cell and album name.
	UIImageAndTextTableCell* pCell = [[notification object] cellAtRow:[[notification object] selectedRow] column:0];
	NSLog(@"Selected album: %@", [pCell title]);
	// Show the songs of the selected album.
	[pCell setSelected:FALSE withFade:TRUE];
	[m_pApp showSongsViewWithTransition:1 album:[pCell title] artist:m_pArtistName];
}


- (int) numberOfRowsInTable: (UITable *)table
{
	return [m_pAlbums count];
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col
{
	return [m_pAlbums objectAtIndex:row];
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col reusing: (BOOL) reusing
{
	return [self table: table cellForRow: row column: col];
}

@end
