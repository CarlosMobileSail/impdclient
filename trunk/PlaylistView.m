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
#import "application.h"

//////////////////////////////////////////////////////////////////////////
// SongTableCell: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation PlaylistTableCell

- (id)initWithSong:(NSString *)song artist:(NSString *)artistinfo current:(BOOL)bCurrent
{
	self = [super init];
	song_name = [[UITextLabel alloc] initWithFrame: CGRectMake(36, 3, 260, 29)];
	artist_name = [[UITextLabel alloc] initWithFrame: CGRectMake(37, 28, 260, 20)];
	play_image = [[UIImageView alloc] initWithFrame: CGRectMake(10, 17, 16, 16)]; 
		
	float c[] = { 0.0f, 0.0f, 0.0f, 0.0f };
	float h[] = { 1.0f, 1.0f, 1.0f, 1.0f };
	
	[song_name setText:song];
	[song_name setFont:[UIImageAndTextTableCell defaultTitleFont]];
	[song_name setBackgroundColor:CGColorCreate(CGColorSpaceCreateDeviceRGB(), c)];
	[song_name setHighlightedColor:CGColorCreate(CGColorSpaceCreateDeviceRGB(), h)];
	
	[artist_name setText:artistinfo];
	[artist_name setFont:[UIDateLabel defaultFont]];
	[artist_name setColor:CGColorCreateCopyWithAlpha([artist_name color], 0.4f)];
	[artist_name setBackgroundColor:CGColorCreate(CGColorSpaceCreateDeviceRGB(), c)];
	[artist_name setHighlightedColor:CGColorCreate(CGColorSpaceCreateDeviceRGB(), h)];

	if (bCurrent)
		[play_image setImage:[UIImage applicationImageNamed:@"resources/play_small.png"]];

	[self addSubview: artist_name];
	[self addSubview: song_name];
	[self addSubview: play_image];
	return self;
}

- (void) drawContentInRect: (struct CGRect)rect selected: (BOOL) selected
{
	[song_name setHighlighted: selected];
	[artist_name setHighlighted: selected];
	[play_image setHighlighted: selected];
	
	[super drawContentInRect: rect selected: selected];
}

@end

//////////////////////////////////////////////////////////////////////////
// PlaylistTable: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation PlaylistTable

- (void)Initialize
{
	lastClickX = -1;
	lastClickY = -1;
	last.tv_sec = 0;
	last.tv_usec = 0;
}


- (double)getTimeDifference
{
	struct timezone tz;
	struct timeval tv;
	struct timeval dt;
	// Get the time of day.
	gettimeofday(&tv, &tz);
	// Determine the difference.
	dt.tv_sec = tv.tv_sec - last.tv_sec;
	dt.tv_usec = tv.tv_usec - last.tv_usec;
	last.tv_sec = tv.tv_sec;
	last.tv_usec = tv.tv_usec;
	return (double)dt.tv_sec + (double)dt.tv_usec * 0.000001l;
}

- (void)mouseUp:(GSEvent *)event
{
	CGPoint p = GSEventGetLocationInWindow(event);
	if (([self getTimeDifference] <= 0.5) && (lastClickX <= (p.x + 10)) && (lastClickX >= (p.x - 10))  && (lastClickY <= (p.y + 10)) && (lastClickY >= (p.y - 10))) {
		[_delegate doubleTap:self];
	} else {
		lastClickX = p.x;
		lastClickY = p.y;
	}
	// Call the base class.
	[super mouseUp:event];
}

@end

//////////////////////////////////////////////////////////////////////////
// PlaylistView: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation PlaylistView

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
	m_Editing = FALSE;
	
	// Create the storage array for the songs.
	m_pSongs = [[NSMutableArray alloc] init];
	// Create the table.
	m_pTable = [[PlaylistTable alloc] initWithFrame: CGRectMake(0, NAVBARHEIGHT, 320, MAXHEIGHT)];
	[m_pTable Initialize];
	[self addSubview: m_pTable]; 

	[m_pTable setRowHeight:56.0f];
	UITableColumn *col = [[UITableColumn alloc] initWithTitle: @"iMPDclient"
												   identifier: @"column1" width: 320.0f];
	[m_pTable addTableColumn: col]; 
	[m_pTable setDataSource: self];
	[m_pTable setDelegate: self];
	[m_pTable setAllowsReordering:YES];
	[m_pTable setSeparatorStyle:1];
	[m_pTable setDoubleAction:@selector(StartPlaySelected:)];

	// Create the navigation bar.
	UINavigationBar* nav = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 320, NAVBARHEIGHT)];
	[nav showLeftButton:@"Edit" withStyle:0 rightButton:@"Clear All" withStyle:1];	// 1 = red.
	[nav setBarStyle: 1];	// Dark style.
	[nav setDelegate:self];
	[nav enableAnimation];
	
	m_pTitle = [[UINavigationItem alloc] initWithTitle:@"--:--"];
	[nav pushNavigationItem: m_pTitle];
	
	[self addSubview: nav];
	return self;
}

//  --- OTHER METHODS -----------------------------------------------

- (void)ShowPlaylist
{
	if (!m_pMPD)
		return;
	// Clear the songs array.
	[m_pSongs removeAllObjects];
	// Get the current song id, if any.
	int current_id = -1, row = 0, current_row = -1;
	mpd_Song* pSong = mpd_playlist_get_current_song(m_pMPD);
	if (pSong)
		current_id = pSong->id;
	// Get the current playlist.
	MpdData *data = mpd_playlist_get_changes(m_pMPD, -1);
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
				PlaylistTableCell* pCell = [[PlaylistTableCell alloc] initWithSong:song artist:info current:(current_id == data->song->id)];
				pCell->m_SongID = data->song->id;
				// Add the song object to the array.
				[m_pSongs addObject:pCell];
				row++;
			}
			// Go to the next entry.
			data = mpd_data_get_next(data);
		} while(data);
	} else
		NSLog(@"No data found");
	// Update the table contents.
	[m_pTable reloadData];
	// Scroll to the current song?
	if (current_row != -1)
		[m_pTable scrollRowToVisible:current_row];
}


- (void)UpdateTitle
{
	int totalTime = mpd_status_get_total_song_time(m_pMPD);
	int elapsedTime = mpd_status_get_elapsed_song_time(m_pMPD);
	NSString* str = [NSString stringWithFormat:@"%d:%02d - %d:%02d", elapsedTime / 60, elapsedTime % 60, totalTime / 60, totalTime % 60];
	[m_pTitle setTitle: str]; 
}

//  --- DELEGATE METHODS -----------------------------------------------

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button
{
	NSLog(@"SongView: button %d", button);
	if (button == 0) {
		// Alert sheet attached to bootom of Screen.
		UIAlertSheet *alertSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
		[alertSheet setBodyText:@"Clear the playlist?"];
		[alertSheet setDestructiveButton: [alertSheet addButtonWithTitle:@"Yes"]];
		[alertSheet addButtonWithTitle:@"No"];
		[alertSheet setDelegate:self];
		[alertSheet presentSheetFromAboveView:self];
	} else if (button == 1) {
		m_Editing = !m_Editing;
		if (m_Editing) {
			[m_pTable enableRowDeletion:YES animated:YES];
			[navbar showLeftButton:@"Done" withStyle:0 rightButton:nil withStyle:0];
		} else {
			[m_pTable enableRowDeletion:NO animated:YES];
			[navbar showLeftButton:@"Edit" withStyle:0 rightButton:@"Clear All" withStyle:1];
		}
	}
}

- (void)alertSheet:(UIAlertSheet*)sheet buttonClicked:(int)button
{
	if (button == 1) {
		// Anwer of the clear question is yes: clear it.
		mpd_playlist_clear(m_pMPD);
	}
	[sheet dismiss];
}

- (void)doubleTap:(id)sender
{
	NSLog(@"Double tap detected!");
	// Get the selected row and start playing that song.
	PlaylistTableCell* pCell = [m_pTable cellAtRow:[m_pTable selectedRow] column:0];
	mpd_player_play_id(m_pMPD, pCell->m_SongID);
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

- (BOOL)table:(UITable*)table canDeleteRow: (int)row
{
	return YES;
}

- (void)table:(UITable*)table deleteRow: (int)row
{
	NSLog(@"table:deleteRow: %d", row);
	// Remove the song from the playlist.
	mpd_playlist_delete_pos(m_pMPD, row);
}

- (BOOL)table:(UITable*)table canMoveRow: (int)row
{
	return (row == 0) ? NO : YES;
}

-(int)table:(UITable*)table movedRow: (int)row toRow: (int)dest
{
	NSLog(@"table:movedRow:toRow: %i, %i", row, dest);
	mpd_playlist_move_pos(m_pMPD, row, dest);
	return dest;
}

@end
