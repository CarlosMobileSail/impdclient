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
#import "impdclientApp.h"

//////////////////////////////////////////////////////////////////////////
// SongTableCell: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation SongTableCell
@end

//////////////////////////////////////////////////////////////////////////
// SongsView: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation SongsView

- (void)dealloc
{
	// Release all objects.
	[_table release];
	[_songs release];
	[_title release];
	[_navBar release];
	// Call the base class.
	[super dealloc];
}


- (void)initialize:(MPDClientApplication* )app mpd:(MpdObj *)mpdServer
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
	_songs = [[NSMutableArray alloc] init];

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
	[_navBar showLeftButton:@"Albums" withStyle:2 rightButton:nil withStyle:0];		// 2 = arrow left.
	[_navBar setBarStyle: 1];	// Dark style.
	[_navBar setDelegate:self];
	[_navBar enableAnimation];

	_title = [[UINavigationItem alloc] initWithTitle:@"--:--"];
	[_navBar pushNavigationItem: _title];

	[self addSubview: _navBar];
	return self;
}

//  --- OTHER METHODS -----------------------------------------------

- (void)showSongs:(NSString *)albumName artist:(NSString *)name
{
	if (!_mpdServer)
		return;
	// Clear the array.
	[_songs removeAllObjects];
	// Add the 'add all' item.
	SongTableCell *cell = [[SongTableCell alloc] init];
	[cell setTitle:@"All songs"];
	[cell setImage:[UIImage applicationImageNamed:@"resources/add.png"]];
	[_songs addObject:cell];
	[cell release];
	// Get the list of songs.
	mpd_database_search_start(_mpdServer, TRUE);
	mpd_database_search_add_constraint(_mpdServer, MPD_TAG_ITEM_ALBUM, [albumName cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	MpdData *data = mpd_database_search_commit(_mpdServer);
	if (data) {
		do {
			// Create album object and add it to the array.
			cell = [[SongTableCell alloc] init];
			if (data->type == MPD_DATA_TYPE_TAG)
				[cell setTitle:[NSString stringWithCString: data->tag]];
			if (data->type == MPD_DATA_TYPE_SONG) {
				[cell setTitle:[NSString stringWithFormat: @"%s %s", data->song->track, data->song->title]];
				strcpy(cell->_path, data->song->file);
			}
			[cell setImage:[UIImage applicationImageNamed:@"resources/add2.png"]];
			[_songs addObject:cell];
			[cell release];
			// Go to the next entry.
			data = mpd_data_get_next(data);
		} while(data);
	} else
		NSLog(@"No data found");
	// Update the table contents.
	[_table reloadData];
	[_title setTitle: albumName];
	_artistName = [name copy];
	_albumName = [albumName copy];
}


- (BOOL)addSong:(NSString *)name
{
	// Find the full path and add it to the playlist.
	mpd_database_search_field_start(_mpdServer, MPD_TAG_ITEM_FILENAME);
	mpd_database_search_add_constraint(_mpdServer, MPD_TAG_ITEM_ARTIST, [_artistName cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	mpd_database_search_add_constraint(_mpdServer, MPD_TAG_ITEM_ALBUM, [_albumName cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	mpd_database_search_add_constraint(_mpdServer, MPD_TAG_ITEM_TITLE, [name cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	MpdData* data = mpd_database_search_commit(_mpdServer);
	BOOL bSuccess = FALSE;
	if (data) {
		if (data->type == MPD_DATA_TYPE_TAG) {
			// Add the song to the current playlist.
			mpd_playlist_queue_add(_mpdServer, data->tag);
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
		[_app cleanUp];
	else if (button == 1)
		[_app showAlbumsViewWithTransition:2 artist:_artistName];
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
		SongTableCell* pCell = [_table cellAtRow:[_table selectedRow] column:0];
		NSLog(@"Selected song: %@", [pCell title]);
		// Anwer of the clear question is yes: add the song(s) to the list.
		if ([_table selectedRow] == 0) {
			// Add all songs.
			int i;
			for (i = 1;i < [_songs count];i++) {
				pCell = [_songs objectAtIndex:i];
				mpd_playlist_queue_add(_mpdServer, pCell->_path);
			}
		} else {
			[pCell setSelected:FALSE withFade:TRUE];
			mpd_playlist_queue_add(_mpdServer, pCell->_path);
		}
		// Flush the queue.
		mpd_playlist_queue_commit(_mpdServer);
		// Go back to the album view.
		[_app showAlbumsViewWithTransition:2 artist:_artistName];
	}
	[sheet dismiss];
}

- (int) numberOfRowsInTable: (UITable *)table
{
	return [_songs count];
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col
{
	return [_songs objectAtIndex:row];
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col reusing: (BOOL) reusing
{
	return [self table: table cellForRow: row column: col];
}

@end
