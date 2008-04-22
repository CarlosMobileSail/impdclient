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

#import "SongsView.h"
#import "application.h"

//////////////////////////////////////////////////////////////////////////
// SongTableCell: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation SongTableCell
@end

//////////////////////////////////////////////////////////////////////////
// SongsView: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation SongsView

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
	m_pSongs = [[NSMutableArray alloc] init];

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
	[nav showLeftButton:@"Albums" withStyle:2 rightButton:nil withStyle:0];		// 2 = arrow left.
	[nav setBarStyle: 1];	// Dark style.
	[nav setDelegate:self];
	[nav enableAnimation];

	m_pTitle = [[UINavigationItem alloc] initWithTitle:@"--:--"];
	[nav pushNavigationItem: m_pTitle];

	[self addSubview: nav];
	return self;
}

//  --- OTHER METHODS -----------------------------------------------

- (void)ShowSongs:(NSString *)albumname artist:(NSString *)name
{
	if (!m_pMPD)
		return;
	// Clear the array.
	[m_pSongs removeAllObjects];
	// Add the 'add all' item.
	SongTableCell *cell = [[SongTableCell alloc] init];
	[cell setTitle:@"All songs"];
	[cell setImage:[UIImage applicationImageNamed:@"resources/add.png"]];
	[m_pSongs addObject:cell];
	[cell release];
	// Get the list of songs.
	mpd_database_search_start(m_pMPD, TRUE);
	mpd_database_search_add_constraint(m_pMPD, MPD_TAG_ITEM_ALBUM, [albumname cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	MpdData *data = mpd_database_search_commit(m_pMPD);
	if (data) {
		do {
			// Create album object and add it to the array.
			cell = [[SongTableCell alloc] init];
			if (data->type == MPD_DATA_TYPE_TAG)
				[cell setTitle:[NSString stringWithCString: data->tag]];
			if (data->type == MPD_DATA_TYPE_SONG) {
				[cell setTitle:[NSString stringWithFormat: @"%s %s", data->song->track, data->song->title]];
				strcpy(cell->m_Path, data->song->file);
			}
			[cell setImage:[UIImage applicationImageNamed:@"resources/add2.png"]];
			[m_pSongs addObject:cell];
			[cell release];
			// Go to the next entry.
			data = mpd_data_get_next(data);
		} while(data);
	} else
		NSLog(@"No data found");
	// Update the table contents.
	[m_pTable reloadData];
	[m_pTitle setTitle: albumname];
	m_pArtistName = [name copy];
	m_pAlbumName = [albumname copy];
}


- (BOOL)AddSong:(NSString *)name
{
	// Find the full path and add it to the playlist.
	mpd_database_search_field_start(m_pMPD, MPD_TAG_ITEM_FILENAME);
	mpd_database_search_add_constraint(m_pMPD, MPD_TAG_ITEM_ARTIST, [m_pArtistName cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	mpd_database_search_add_constraint(m_pMPD, MPD_TAG_ITEM_ALBUM, [m_pAlbumName cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	mpd_database_search_add_constraint(m_pMPD, MPD_TAG_ITEM_TITLE, [name cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	MpdData* data = mpd_database_search_commit(m_pMPD);
	BOOL bSuccess = FALSE;
	if (data) {
		if (data->type == MPD_DATA_TYPE_TAG) {
			// Add the song to the current playlist.
			mpd_playlist_queue_add(m_pMPD, data->tag);
			NSLog(@"Added file: %s", data->tag);
			bSuccess = TRUE;
		}
	}
	return bSuccess;
}

//  --- DELEGATE METHODS -----------------------------------------------

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button
{
	NSLog(@"SongsView: button %d", button);
	if (button == 0)
		[m_pApp cleanUp];
	else if (button == 1)
		[m_pApp showAlbumsViewWithTransition:2 artist:m_pArtistName];
}


- (void)tableRowSelected:(NSNotification*)notification 
{
	// Alert sheet attached to bottom of screen.
	UIAlertSheet *alertSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
	[alertSheet setBodyText:@"Add song(s) to the playlist?"];
	[alertSheet addButtonWithTitle:@"Yes"];
	[alertSheet addButtonWithTitle:@"No"];
	[alertSheet setDelegate:self];
	[alertSheet presentSheetFromAboveView:self];
}


- (void)alertSheet:(UIAlertSheet*)sheet buttonClicked:(int)button
{
	if (button == 1) {
		// Get selected cell and song name.
		SongTableCell* pCell = [m_pTable cellAtRow:[m_pTable selectedRow] column:0];
		NSLog(@"Selected song: %@", [pCell title]);
		// Anwer of the clear question is yes: add the song(s) to the list.
		if ([m_pTable selectedRow] == 0) {
			// Add all songs.
			int i;
			for (i = 1;i < [m_pSongs count];i++) {
				pCell = [m_pSongs objectAtIndex:i];
				mpd_playlist_queue_add(m_pMPD, pCell->m_Path);
			}
		} else {
			[pCell setSelected:FALSE withFade:TRUE];
			mpd_playlist_queue_add(m_pMPD, pCell->m_Path);
		}
		// Flush the queue.
		mpd_playlist_queue_commit(m_pMPD);
		// Go back to the album view.
		[m_pApp showAlbumsViewWithTransition:2 artist:m_pArtistName];
	}
	[sheet dismiss];
}

- (int) numberOfRowsInTable: (UITable *)table
{
	return [m_pSongs count];
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col
{
	return [m_pSongs objectAtIndex:row];
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col reusing: (BOOL) reusing
{
	return [self table: table cellForRow: row column: col];
}

@end
