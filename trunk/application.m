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

#include "libmpd/libmpd.h"

//////////////////////////////////////////////////////////////////////////
// MPD: callback functions.
//////////////////////////////////////////////////////////////////////////

void error_callback(MpdObj *mi, int errorid, char *msg, void *userdata)
{
	printf("Error: ...\r\n");
}

void status_changed(MpdObj *mi, ChangedStatusType what)
{
	printf("Status changed...\r\n");
}


//////////////////////////////////////////////////////////////////////////
// DetailsCell: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation SongTableCell

- (id) initWithSong: (NSDictionary *)song
{
	self = [super init];
	song_name = [[UITextLabel alloc] initWithFrame: CGRectMake(9.0f, 3.0f, 260.0f, 29.0f)];
	artist_name = [[UITextLabel alloc] initWithFrame: CGRectMake(10.0f, 22.0f, 260.0f, 34.0f)];
	
	float c[] = { 0.0f, 0.0f, 0.0f, 0.0f };
	float h[] = { 1.0f, 1.0f, 1.0f, 1.0f };
	
	[song_name setText: [song objectForKey: @"SONG"]];
	[song_name setFont: [UIImageAndTextTableCell defaultTitleFont]];
	[song_name setBackgroundColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), c)];
	[song_name setHighlightedColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), h)];
	
	[artist_name setText: [song objectForKey: @"ARTIST"]];
	[artist_name setFont: [UIDateLabel defaultFont]];
	[artist_name setColor: CGColorCreateCopyWithAlpha([artist_name color], 0.4f)];
	[artist_name setBackgroundColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), c)];
	[artist_name setHighlightedColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), h)];
	
	[self addSubview: artist_name];
	[self addSubview: song_name];
	
//	[self setShowDisclosure: YES];
//	[self setDisclosureStyle: 2];
	
	return self;
}

- (void) drawContentInRect: (struct CGRect)rect selected: (BOOL) selected
{
    [song_name setHighlighted: selected];
    [artist_name setHighlighted: selected];
    
    [super drawContentInRect: rect selected: selected];
}

@end

//////////////////////////////////////////////////////////////////////////
// Application: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation MPDClientApplication

- (void)fill_playlist
{
	MpdObj *obj = NULL;
	
//	debug_set_output(stdout);
//	debug_set_level(4);			// DEBUG_INFO + 1
	
	// Create mpd object.
	obj = mpd_new("192.168.2.2", 6600, NULL);
	// Connect signals.
	mpd_signal_connect_error(obj,(ErrorCallback)error_callback, NULL);
	mpd_signal_connect_status_changed(obj,(StatusChangedCallback)status_changed, NULL);
	// Set timeout
	mpd_set_connection_timeout(obj, 10);

	if (mpd_connect(obj) == MPD_OK) {
		// Get the current playlist.
		MpdData *data = mpd_playlist_get_changes(obj,-1);
		if (data) {
			int cnt = 0;
			do {
				if (data->type == MPD_DATA_TYPE_SONG) {
					// Create song object.
					NSMutableDictionary *song = [[NSMutableDictionary alloc] init];
					[song setObject:[NSString stringWithCString: data->song->title] forKey:@"SONG"];
					[song setObject:[NSString stringWithFormat: @"%s, %s", data->song->artist, data->song->album] forKey:@"ARTIST"];
					[song autorelease];
					// Add the song object to the array.
					[songs addObject:song];
				}
				// Go to the next entry.
				data = mpd_data_get_next(data);
			} while(data);
		}
	}
	
	mpd_free(obj);
}


- (void) applicationDidFinishLaunching: (id) unused
{
    UIWindow *window;
	BOOL i = TRUE;
    window = [[UIWindow alloc] initWithContentRect: [UIHardware fullScreenApplicationContentRect]];

	// Create the storage array for the songs.
	songs = [[NSMutableArray alloc] init];
	// Open the current playlist.
	[self fill_playlist];
	
    UITable *table = [[UITable alloc] initWithFrame: CGRectMake(0.0f, 48.0f,
																320.0f, 480.0f - 16.0f - 32.0f)];
	[table setRowHeight:56.0f];
    UITableColumn *col = [[UITableColumn alloc] initWithTitle: @"HelloApp"
												   identifier: @"hello" width: 320.0f];
	
    [window orderFront: self];
    [window makeKey: self];
    [window _setHidden: NO];
	
    [table addTableColumn: col]; 
    [table setDataSource: self];
    [table setDelegate: self];
    [table reloadData];
	
    UINavigationBar *nav = [[UINavigationBar alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 48.0f)];
    [nav showLeftButton:@"Settings"	withStyle:2	// left arrow
		rightButton:@"Exit"	withStyle:3];	// brighter blue
    [nav setBarStyle: 0];
    [nav setDelegate:self];
    [nav enableAnimation];
	
    struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
    rect.origin.x = rect.origin.y = 0.0f;
    mainView = [[UIView alloc] initWithFrame: rect];
    [mainView addSubview: nav]; 
    [mainView addSubview: table]; 

    [window setContentView: mainView];
}

//  --- DELEGATE METHODS -----------------------------------------------

- (int) numberOfRowsInTable: (UITable *)table
{
    return [songs count];
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col
{
    SongTableCell *cell = [[SongTableCell alloc] initWithSong: [songs objectAtIndex: row]];
    return cell;
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col
    reusing: (BOOL) reusing
{
    return [self table: table cellForRow: row column: col];
}

@end
