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
#import <UIKit/UIPushButton.h>
#import <UIKit/UIThreePartButton.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UIDateLabel.h>
#import <UIKit/UITable.h>
#import <UIKit/UITableCell.h>
#import <UIKit/UITableColumn.h>
#import "application.h"


//////////////////////////////////////////////////////////////////////////
// MPD: callback functions.
//////////////////////////////////////////////////////////////////////////

void error_callback(MpdObj *mi, int errorid, char *msg, void *userdata)
{
	NSLog(@"Error [%d]: %s", errorid, msg);
}

void status_changed(MpdObj *mi, ChangedStatusType what, void *userdata)
{
	MPDClientApplication* pApp = (MPDClientApplication *)userdata;
	BOOL bHandled = FALSE;
	// First check the playing state.
	if (what & MPD_CST_STATE) {
		// The state of the player has changed. Update the button.
		[pApp UpdateButtonBar];
		bHandled = TRUE;
	}
	// Check the elapsed time.
	if (what & MPD_CST_ELAPSED_TIME) {
		// Update the interface.
		[pApp UpdateTitle];
		bHandled = TRUE;
	}
	if ((what & MPD_CST_PLAYLIST) || (what & MPD_CST_SONGID)) {
		// The playlist has changed.
		[pApp fill_playlist];		
		bHandled = TRUE;
	}
	if (!bHandled)
		NSLog(@"Status changed: 0x%08X", (int)what);
}


//////////////////////////////////////////////////////////////////////////
// DetailsCell: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation SongTableCell

- (id) initWithSong: (NSDictionary *)song
{
	self = [super init];
	song_name = [[UITextLabel alloc] initWithFrame: CGRectMake(34.0f, 3.0f, 260.0f, 29.0f)];
	artist_name = [[UITextLabel alloc] initWithFrame: CGRectMake(35.0f, 28.0f, 260.0f, 20.0f)];
	play_image = [[UIImageView alloc] initWithFrame: CGRectMake(10.0f, 17.0f, 16.0f, 16.0f)]; 
		
	float c[] = { 0.0f, 0.0f, 0.0f, 0.0f };
	float h[] = { 1.0f, 1.0f, 1.0f, 1.0f };
	float b[] = { 0.663f, 0.0f, 0.031f, 1.0f };		// Opaque red.
	
	[song_name setText: [song objectForKey: @"SONG"]];
	[song_name setFont: [UIImageAndTextTableCell defaultTitleFont]];
	[song_name setBackgroundColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), c)];
	[song_name setHighlightedColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), h)];
	
	[artist_name setText: [song objectForKey: @"ARTIST"]];
	[artist_name setFont: [UIDateLabel defaultFont]];
	[artist_name setColor: CGColorCreateCopyWithAlpha([artist_name color], 0.4f)];
	[artist_name setBackgroundColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), c)];
	[artist_name setHighlightedColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), h)];

	if ([song objectForKey: @"CURRENT"] == @"1")
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
// Application: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation MPDClientApplication


- (void)applicationWillTerminate:(NSNotification *)notification
{
	if (m_pMPD)
		mpd_free(m_pMPD);
    [self terminateWithSuccess];
}


- (void)cleanUp
{
    NSLog(@"cleanUP");
    [self applicationWillTerminate:nil];
}


- (void)open_connection
{
//	debug_set_output(stdout);
//	debug_set_level(4);			// DEBUG_INFO + 1
	
	// Create mpd object.
	m_pMPD = mpd_new("192.168.2.2", 6600, NULL);
	// Connect signals.
	mpd_signal_connect_error(m_pMPD, (ErrorCallback)error_callback, NULL);
	mpd_signal_connect_status_changed(m_pMPD, (StatusChangedCallback)status_changed, self);
	// Set timeout
	mpd_set_connection_timeout(m_pMPD, 10);

	if (mpd_connect(m_pMPD) != MPD_OK) {
		mpd_free(m_pMPD);
		m_pMPD = NULL;
	}
}


- (void)fill_playlist
{
	if (!m_pMPD)
		return;
	// Clear the songs array.
	[m_pSongs removeAllObjects];
	// Get the current song id, if any.
	int current_id = -1;
	mpd_Song* pSong = mpd_playlist_get_current_song(m_pMPD);
	if (pSong)
		current_id = pSong->id;
	// Get the current playlist.
	MpdData *data = mpd_playlist_get_changes(m_pMPD, -1);
	if (data) {
		int cnt = 0;
		do {
			if (data->type == MPD_DATA_TYPE_SONG) {
				// Create song object.
				NSMutableDictionary* song = [[NSMutableDictionary alloc] init];
				[song setObject:[NSString stringWithCString: data->song->title] forKey:@"SONG"];
				[song setObject:[NSString stringWithFormat: @"%s, %s", data->song->artist, data->song->album] forKey:@"ARTIST"];
				[song setObject:(current_id == data->song->id ? @"1" : @"0") forKey:@"CURRENT"];
				[song autorelease];
				// Add the song object to the array.
				[m_pSongs addObject:song];
			}
			// Go to the next entry.
			data = mpd_data_get_next(data);
		} while(data);
	}
	// Update the table contents.
    [m_pTable reloadData];
}


- (NSArray *)buttonBarItems 
{
	BOOL bIsPlaying = (mpd_player_get_state(m_pMPD) == MPD_PLAYER_PLAY);
	NSLog(@"buttonBarItems");
	return [ NSArray arrayWithObjects:
    [ NSDictionary dictionaryWithObjectsAndKeys:
           @"buttonBarItemTapped:", kUIButtonBarButtonAction,
           bIsPlaying ? @"resources/pause.png" : @"resources/play.png", kUIButtonBarButtonInfo,
           @"resources/play.png", kUIButtonBarButtonSelectedInfo,
           [ NSNumber numberWithInt: 1], kUIButtonBarButtonTag,
           self, kUIButtonBarButtonTarget,
           (bIsPlaying ? @"Pause" : @"Play"), kUIButtonBarButtonTitle,
           @"0", kUIButtonBarButtonType,
           nil 
           ],
    [ NSDictionary dictionaryWithObjectsAndKeys:
           @"buttonBarItemTapped:", kUIButtonBarButtonAction,
           @"resources/previous.png", kUIButtonBarButtonInfo,
           @"resources/previous.png", kUIButtonBarButtonSelectedInfo,
           [ NSNumber numberWithInt: 2], kUIButtonBarButtonTag,
           self, kUIButtonBarButtonTarget,
           @"Previous", kUIButtonBarButtonTitle,
           @"0", kUIButtonBarButtonType,
           nil 
           ],
    [ NSDictionary dictionaryWithObjectsAndKeys:
           @"buttonBarItemTapped:", kUIButtonBarButtonAction,
           @"resources/next.png", kUIButtonBarButtonInfo,
           @"resources/next.png", kUIButtonBarButtonSelectedInfo,
           [ NSNumber numberWithInt: 3], kUIButtonBarButtonTag,
           self, kUIButtonBarButtonTarget,
           @"Next", kUIButtonBarButtonTitle,
           @"0", kUIButtonBarButtonType,
           nil 
           ],
    [ NSDictionary dictionaryWithObjectsAndKeys:
           @"buttonBarItemTapped:", kUIButtonBarButtonAction,
           @"resources/stop.png", kUIButtonBarButtonInfo,
           @"resources/stop.png", kUIButtonBarButtonSelectedInfo,
           [ NSNumber numberWithInt: 4], kUIButtonBarButtonTag,
           self, kUIButtonBarButtonTarget,
           @"Stop", kUIButtonBarButtonTitle,
           @"0", kUIButtonBarButtonType,
           nil 
           ],
    [ NSDictionary dictionaryWithObjectsAndKeys:
           @"buttonBarItemTapped:", kUIButtonBarButtonAction,
           @"resources/volume.png", kUIButtonBarButtonInfo,
           @"resources/volume.png", kUIButtonBarButtonSelectedInfo,
           [ NSNumber numberWithInt: 5], kUIButtonBarButtonTag,
           self, kUIButtonBarButtonTarget,
           @"Volume", kUIButtonBarButtonTitle,
           @"0", kUIButtonBarButtonType,
           nil 
           ],
    nil
  ];
}


- (void)buttonBarItemTapped:(id) sender 
{
	int button = [sender tag];
	switch (button) {
	case 1:
		NSLog(@"Play/Pause");
		// Is the player playing?
		if (mpd_player_get_state(m_pMPD) == MPD_PLAYER_PLAY)
			mpd_player_pause(m_pMPD);
		else
			mpd_player_play(m_pMPD);
		break;
	case 2:
		NSLog(@"Previous");
		mpd_player_prev(m_pMPD);
		break;
	case 3:
		NSLog(@"Next");
		mpd_player_next(m_pMPD);
		break;
	case 4:
		NSLog(@"Stop");
		mpd_player_stop(m_pMPD);
		break;        
	case 5:
		NSLog(@"Volume");
		break;
	}
}


- (UIButtonBar *)createButtonBar 
{
	NSLog(@"createButtonBar");
	UIButtonBar *buttonBar;
	buttonBar = [ [ UIButtonBar alloc ] 
		initInView: m_pMainView
		withFrame: CGRectMake(0.0f, 410.0f, 320.0f, 50.0f)
		withItemList: [ self buttonBarItems ] ];
	[buttonBar setDelegate:self];
	[buttonBar setBarStyle:1];
	[buttonBar setButtonBarTrackingMode: 2];

	int buttons[5] = { 1, 2, 3, 4, 5};
	[buttonBar registerButtonGroup:0 withButtons:buttons withCount: 5];
	[buttonBar showButtonGroup: 0 withDuration: 0.0f];
	return buttonBar;
}


- (void) UpdateButtonBar
{
	int tagNumber = 1;
	BOOL bIsPlaying = (mpd_player_get_state(m_pMPD) == MPD_PLAYER_PLAY);
	NSLog(@"Updating button: %d", bIsPlaying);
	UIImage *image = [UIImage applicationImageNamed: (bIsPlaying ? @"resources/pause.png" : @"resources/play.png")];
	[ [ m_pButtonBar viewWithTag:tagNumber ]  setImage:image];
}


- (void) UpdateTitle
{
	int totalTime = mpd_status_get_total_song_time(m_pMPD);
	int elapsedTime = mpd_status_get_elapsed_song_time(m_pMPD);
	NSString* str = [NSString stringWithFormat:@"%d:%02d - %d:%02d", elapsedTime / 60, elapsedTime % 60, totalTime / 60, totalTime % 60];
	[m_pTitle setTitle: str]; 
}


- (id) timertick: (NSTimer *)timer
{
	// Service the mpd status handler.
	mpd_status_update(m_pMPD);
}


- (void) applicationDidFinishLaunching: (id) unused
{
    UIWindow *window;
	BOOL i = TRUE;

	// Create the storage array for the songs.
	m_pMPD = NULL;
	m_pSongs = [[NSMutableArray alloc] init];
	
    struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
    rect.origin.x = rect.origin.y = 0.0f;
    window = [[UIWindow alloc] initWithContentRect: rect];
    m_pMainView = [[UIView alloc] initWithFrame: rect];
    [window orderFront: self];
    [window makeKey: self];
    [window _setHidden: NO];
    [window setContentView: m_pMainView];

    // Create the table.
    m_pTable = [[UITable alloc] initWithFrame: CGRectMake(0.0f, 48.0f, 320.0f, 480.0f - 16.0f - 32.0f - 50.0f)];
    [m_pMainView addSubview: m_pTable]; 

    [m_pTable setRowHeight:56.0f];
    UITableColumn *col = [[UITableColumn alloc] initWithTitle: @"iMPDclient"
												   identifier: @"column1" width: 320.0f];
    [m_pTable addTableColumn: col]; 
    [m_pTable setDataSource: self];
    [m_pTable setDelegate: self];
	[m_pTable setAllowsReordering:YES];
	[m_pTable setSeparatorStyle:1];

    // Create the navigation bar.
	UINavigationBar* nav = [[UINavigationBar alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 48.0f)];
    [nav showLeftButton:@"Edit" withStyle:0 rightButton:@"Exit" withStyle:3];	// 3 = brighter blue.
    [nav setBarStyle: 1];	// Dark style.
    [nav setDelegate:self];
    [nav enableAnimation];

	m_pTitle = [[UINavigationItem alloc] initWithTitle:@"--:--"];
	[nav pushNavigationItem: m_pTitle];
	
    [m_pMainView addSubview: nav]; 

    // Create the button bar.
    m_pButtonBar = [ self createButtonBar ];
    [m_pMainView addSubview: m_pButtonBar];

    // Create a timer (every 0.2 seconds).
	double tickIntervalM = 0.2;
    m_pTimer = [NSTimer scheduledTimerWithTimeInterval: tickIntervalM
                target: self
                selector: @selector(timertick:)
                userInfo: nil
                repeats: YES];
    
	// Open the current playlist.
	[self open_connection];
	[self fill_playlist];
}

//  --- DELEGATE METHODS -----------------------------------------------

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button
{
    NSLog(@"Button pressed: %d", button);
    if (button == 0)
		[self cleanUp];
    else if (button == 1) {
    	if (m_Editing) {
			[m_pTable enableRowDeletion:YES animated:YES];
			[navbar showLeftButton:@"Done" withStyle:0 rightButton:@"Exit" withStyle:3];
    	} else {
    		[m_pTable enableRowDeletion:NO animated:YES];
    		[navbar showLeftButton:@"Edit" withStyle:0 rightButton:@"Exit" withStyle:3];
    	}
    	m_Editing = !m_Editing;
    }
}

- (int) numberOfRowsInTable: (UITable *)table
{
    return [m_pSongs count];
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col
{
    SongTableCell *cell = [[SongTableCell alloc] initWithSong: [m_pSongs objectAtIndex: row]];
    return cell;
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col 
    reusing: (BOOL) reusing
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
