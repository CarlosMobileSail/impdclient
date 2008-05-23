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
#import <UIKit/UIDateLabel.h>
#import <UIKit/UITable.h>
#import <UIKit/UITableCell.h>
#import <UIKit/UITableColumn.h>

#import "PlaylistView.h"
#import "impdclientApp.h"

//////////////////////////////////////////////////////////////////////////
// SongTableCell: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation PlaylistTableCell

- (void)dealloc
{
	// Release all objects.
	[_songName release];
	[_artistName release];
	[_playImage release];
	// Call the base class.
	[super dealloc];
}


- (id)initWithSong:(NSString *)song artist:(NSString *)artistInfo current:(BOOL)currentSong
{
	self = [super init];
	_songName = [[UITextLabel alloc] initWithFrame: CGRectMake(36, 3, 260, 29)];
	_artistName = [[UITextLabel alloc] initWithFrame: CGRectMake(37, 28, 260, 20)];
	_playImage = [[UIImageView alloc] initWithFrame: CGRectMake(10, 17, 16, 16)]; 
		
	float c[] = { 0.0f, 0.0f, 0.0f, 0.0f };
	float h[] = { 1.0f, 1.0f, 1.0f, 1.0f };
	
	[_songName setText:song];
	[_songName setFont:[UIImageAndTextTableCell defaultTitleFont]];
	[_songName setBackgroundColor:CGColorCreate(CGColorSpaceCreateDeviceRGB(), c)];
	[_songName setHighlightedColor:CGColorCreate(CGColorSpaceCreateDeviceRGB(), h)];
	
	[_artistName setText:artistInfo];
	[_artistName setFont:[UIDateLabel defaultFont]];
	[_artistName setColor:CGColorCreateCopyWithAlpha([_artistName color], 0.4f)];
	[_artistName setBackgroundColor:CGColorCreate(CGColorSpaceCreateDeviceRGB(), c)];
	[_artistName setHighlightedColor:CGColorCreate(CGColorSpaceCreateDeviceRGB(), h)];

	if (currentSong)
		[_playImage setImage:[UIImage applicationImageNamed:@"resources/play_small.png"]];

	[self addSubview: _artistName];
	[self addSubview: _songName];
	[self addSubview: _playImage];
	return self;
}

- (void) drawContentInRect: (struct CGRect)rect selected: (BOOL) selected
{
	[_songName setHighlighted: selected];
	[_artistName setHighlighted: selected];
	[_playImage setHighlighted: selected];
	
	[super drawContentInRect: rect selected: selected];
}

@end

//////////////////////////////////////////////////////////////////////////
// PlaylistTable: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation PlaylistTable

- (void)initialize
{
	_lastClickX = -1;
	_lastClickY = -1;
	_last.tv_sec = 0;
	_last.tv_usec = 0;
}


- (double)getTimeDifference
{
	struct timezone tz;
	struct timeval tv;
	struct timeval dt;
	// Get the time of day.
	gettimeofday(&tv, &tz);
	// Determine the difference.
	dt.tv_sec = tv.tv_sec - _last.tv_sec;
	dt.tv_usec = tv.tv_usec - _last.tv_usec;
	_last.tv_sec = tv.tv_sec;
	_last.tv_usec = tv.tv_usec;
	return (double)dt.tv_sec + (double)dt.tv_usec * 0.000001l;
}

- (void)mouseUp:(GSEvent *)event
{
	CGPoint p = GSEventGetLocationInWindow(event);
	if (([self getTimeDifference] <= 0.5) && (_lastClickX <= (p.x + 10)) && (_lastClickX >= (p.x - 10))  && (_lastClickY <= (p.y + 10)) && (_lastClickY >= (p.y - 10))) {
		[_delegate doubleTap:self];
	} else {
		_lastClickX = p.x;
		_lastClickY = p.y;
	}
	// Call the base class.
	[super mouseUp:event];
}

@end

//////////////////////////////////////////////////////////////////////////
// PlaylistView: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation PlaylistView

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
	m_Editing = FALSE;
	
	// Create the storage array for the songs.
	_songs = [[NSMutableArray alloc] init];
	// Create the table.
	_table = [[PlaylistTable alloc] initWithFrame: CGRectMake(0, NAVBARHEIGHT, 320, MAXHEIGHT)];
	[_table initialize];
	[self addSubview: _table]; 

	[_table setRowHeight:56.0f];
	UITableColumn *col = [[UITableColumn alloc] initWithTitle: @"iMPDclient"
												   identifier: @"column1" width: 320.0f];
	[_table addTableColumn: col]; 
	[_table setDataSource: self];
	[_table setDelegate: self];
	[_table setAllowsReordering:YES];
	[_table setSeparatorStyle:1];
	[_table setDoubleAction:@selector(StartPlaySelected:)];

	// Create the navigation bar.
	_navBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 320, NAVBARHEIGHT)];
	[_navBar showLeftButton:@"Modify" withStyle:0 rightButton:@"Clear All" withStyle:1];	// 1 = red.
	[_navBar setBarStyle: 1];	// Dark style.
	[_navBar setDelegate:self];
	[_navBar enableAnimation];
	
	_title = [[UINavigationItem alloc] initWithTitle:@"--:--"];
	[_navBar pushNavigationItem: _title];
	
	[self addSubview: _navBar];
	return self;
}

//  --- OTHER METHODS -----------------------------------------------

- (void)showPlaylist
{
	if (!_mpdServer)
		return;
	// Clear the songs array.
	[_songs removeAllObjects];
	// Get the current song id, if any.
	int current_id = -1, row = 0, current_row = -1;
	mpd_Song* pSong = mpd_playlist_get_current_song(_mpdServer);
	if (pSong)
		current_id = pSong->id;
	// Get the current playlist.
	MpdData *data = mpd_playlist_get_changes(_mpdServer, -1);
	if (data) {
		do {
			if (data->type == MPD_DATA_TYPE_SONG) {
				// Is this the current song?
				if (current_id == data->song->id)
					current_row = row;
				// Create the new song.
				NSString* song = [NSString stringWithCString: data->song->title];
				int length = data->song->time;
				NSString* info = [NSString stringWithFormat: @"%s, %s (%d:%02d)", data->song->artist, data->song->album, length / 60, length % 60];
				PlaylistTableCell* cell = [[PlaylistTableCell alloc] initWithSong:song artist:info current:(current_id == data->song->id)];
				cell->_songID = data->song->id;
				// Add the song object to the array.
				[_songs addObject:cell];
				[cell release];
				row++;
			}
			// Go to the next entry.
			data = mpd_data_get_next(data);
		} while(data);
	} else
		NSLog(@"No data found");
	// Update the table contents.
	[_table reloadData];
	// Scroll to the current song?
	if (current_row != -1)
		[_table scrollRowToVisible:current_row];
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
	NSLog(@"SongView: button %d", button);
	if (button == 0) {
		// Alert sheet attached to bootom of Screen.
		UIAlertSheet* alertSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
		[alertSheet setBodyText:@"Clear the playlist?"];
		[alertSheet setDestructiveButton: [alertSheet addButtonWithTitle:@"Yes"]];
		[alertSheet addButtonWithTitle:@"No"];
		[alertSheet setDelegate:self];
		[alertSheet presentSheetFromAboveView:self];
	} else if (button == 1) {
		m_Editing = !m_Editing;
		if (m_Editing) {
			[_table enableRowDeletion:YES animated:YES];
			[navbar showLeftButton:@"Finished" withStyle:0 rightButton:nil withStyle:0];
		} else {
			[_table enableRowDeletion:NO animated:YES];
			[navbar showLeftButton:@"Modify" withStyle:0 rightButton:@"Clear All" withStyle:1];
		}
	}
}

- (void)alertSheet:(UIAlertSheet*)sheet buttonClicked:(int)button
{
	if (button == 1) {
		// Anwer of the clear question is yes: clear it.
		mpd_playlist_clear(_mpdServer);
	}
	[sheet dismiss];
}

- (void)doubleTap:(id)sender
{
	NSLog(@"Double tap detected!");
	// Get the selected row and start playing that song.
	PlaylistTableCell* pCell = [_table cellAtRow:[_table selectedRow] column:0];
	mpd_player_play_id(_mpdServer, pCell->_songID);
}

- (int)numberOfRowsInTable: (UITable *)table
{
	return [_songs count];
}

- (UITableCell *)table: (UITable *)table cellForRow: (int)row column: (int)col
{
	return [_songs objectAtIndex:row];
}

- (UITableCell *)table: (UITable *)table cellForRow: (int)row column: (int)col reusing: (BOOL) reusing
{
	return [self table: table cellForRow: row column: col];
}

- (BOOL)table:(UITable*)table canDeleteRow: (int)row
{
	return YES;
}

- (void)table:(UITable*)table deleteRow: (int)row
{
	NSLog(@"table:deleteRow: %d", row);
	// Remove the song from the playlist.
	mpd_playlist_delete_pos(_mpdServer, row);
}

- (BOOL)table:(UITable*)table canMoveRow: (int)row
{
	return (row == 0) ? NO : YES;
}

-(int)table:(UITable*)table movedRow: (int)row toRow: (int)dest
{
	NSLog(@"table:movedRow:toRow: %i, %i", row, dest);
	mpd_playlist_move_pos(_mpdServer, row, dest);
	return dest;
}

@end
