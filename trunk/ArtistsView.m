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
#import "application.h"

//////////////////////////////////////////////////////////////////////////
// ArtistTableCell: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation ArtistTableCell

- (id) initWithArtist: (NSDictionary *)artist
{
	self = [super init];
	artist_name = [[UITextLabel alloc] initWithFrame: CGRectMake(10.0f, 5.0f, 260.0f, 30.0f)];
		
	float c[] = { 0.0f, 0.0f, 0.0f, 0.0f };
	float h[] = { 1.0f, 1.0f, 1.0f, 1.0f };
	
	[artist_name setText: [artist objectForKey: @"ARTIST"]];
	[artist_name setFont: [UIImageAndTextTableCell defaultTitleFont]];
	[artist_name setBackgroundColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), c)];
	[artist_name setHighlightedColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), h)];

	[self addSubview: artist_name];
	[self setShowDisclosure: YES];
	[self setDisclosureStyle: 2];
	return self;
}

- (void) drawContentInRect: (struct CGRect)rect selected: (BOOL) selected
{
    [artist_name setHighlighted: selected];
    [super drawContentInRect: rect selected: selected];
}

@end

//////////////////////////////////////////////////////////////////////////
// ArtistsView: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation ArtistsView

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
	
	// Create the storage array for the songs.
	m_pArtists = [[NSMutableArray alloc] init];
    // Create the table.
    m_pTable = [[UITable alloc] initWithFrame: CGRectMake(0.0f, 48.0f, 320.0f, 480.0f - 16.0f - 32.0f - 50.0f)];
    [self addSubview: m_pTable]; 

    [m_pTable setRowHeight:38.0f];
    UITableColumn *col = [[UITableColumn alloc] initWithTitle: @"iMPDclient"
												   identifier: @"column1" width: 320.0f];
    [m_pTable addTableColumn: col]; 
    [m_pTable setDataSource: self];
    [m_pTable setDelegate: self];
	[m_pTable setSeparatorStyle:1];

    // Create the navigation bar.
	UINavigationBar* nav = [[UINavigationBar alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 48.0f)];
    [nav showLeftButton:@"Playlist" withStyle:2 rightButton:@"Exit" withStyle:3];	// 3 = brighter blue.
    [nav setBarStyle: 1];	// Dark style.
    [nav setDelegate:self];
    [nav enableAnimation];

	m_pTitle = [[UINavigationItem alloc] initWithTitle:@"--:--"];
	[nav pushNavigationItem: m_pTitle];
	
    [self addSubview: nav];
    return self;
}

//  --- OTHER METHODS -----------------------------------------------

- (void)ShowArtists
{
	if (!m_pMPD)
		return;
	// Clear the songs array.
	[m_pArtists removeAllObjects];
	// Get the list of artists.
	mpd_database_search_field_start(m_pMPD, MPD_TAG_ITEM_ARTIST);
	MpdData *data = mpd_database_search_commit(m_pMPD);
	if (data) {
		do {
			if (data->type == MPD_DATA_TYPE_TAG) {
				// Create song object.
				NSMutableDictionary* artist = [[NSMutableDictionary alloc] init];
				[artist setObject:[NSString stringWithCString: data->tag] forKey:@"ARTIST"];
				[artist autorelease];
				// Add the song object to the array.
				[m_pArtists addObject:artist];
			}
			// Go to the next entry.
			data = mpd_data_get_next(data);
		} while(data);
	} else
		NSLog(@"No data found");
	// Update the table contents.
	[m_pTable reloadData];
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
    NSLog(@"ArtistView: button %d", button);
    if (button == 0)
		[m_pApp cleanUp];
    else if (button == 1)
		[m_pApp showSongsViewWithTransition:2];
}

- (int) numberOfRowsInTable: (UITable *)table
{
    return [m_pArtists count];
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col
{
	ArtistTableCell *cell = [[ArtistTableCell alloc] initWithArtist: [m_pArtists objectAtIndex: row]];
    return cell;
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col 
    reusing: (BOOL) reusing
{
    return [self table: table cellForRow: row column: col];
}

@end
