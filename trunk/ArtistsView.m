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
	
	// Create the storage arrays.
	m_pArtists = [[NSMutableArray alloc] init];
	m_pTableHeaders = [[NSMutableArray alloc] init];
	
	CGRect aRect = CGRectMake(0.0f, 48.0f, 320.0f, 480.0f - 16.0f - 32.0f - 50.0f);
	// Create the section list.
	m_pSectionList = [[UISectionList alloc] initWithFrame:aRect showSectionIndex:YES];
	[m_pSectionList setDataSource:self];
	[m_pSectionList reloadData];
	[self addSubview:m_pSectionList];

	// Get the real table.
	m_pTable = [m_pSectionList table];
	UITableColumn *col = [[UITableColumn alloc] initWithTitle: @"iMPDclient" identifier: @"column1" width: 320.0f];
	[m_pTable addTableColumn: col]; 
	[m_pTable setDelegate: self];
	[m_pTable setSeparatorStyle:1];
	[m_pTable setRowHeight:42.0f];
	
	// Create the navigation bar.
	UINavigationBar* nav = [[UINavigationBar alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 48.0f)];
	[nav showLeftButton:@"Playlist" withStyle:2 rightButton:nil withStyle:0];		// 2 = arrow left.
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
	// Clear the arrays.
	[m_pArtists removeAllObjects];
	[m_pTableHeaders removeAllObjects];
	// Get the list of artists.
	mpd_database_search_field_start(m_pMPD, MPD_TAG_ITEM_ARTIST);
	MpdData *data = mpd_database_search_commit(m_pMPD);
	if (data) {
		NSString* prevSection = @"";
		int count = 0;
		do {
			if (data->type == MPD_DATA_TYPE_TAG) {
				// Convert the name.
				NSString* artistname = [NSString stringWithCString: data->tag];
				// Determine the first letters for the section list.
				NSString* firstletter = [artistname substringWithRange:NSMakeRange(0,1)];
				if (![firstletter isEqual:prevSection]) {
					prevSection = [firstletter copy];
					// NSLog(@"%@ - %d", firstletter, count);
					NSMutableDictionary* cellDict = [[NSMutableDictionary alloc] initWithCapacity:2];
					[cellDict setObject:firstletter forKey:@"title"];
					[cellDict setObject:[[NSNumber alloc] initWithInt:count] forKey:@"beginRow"];
					[m_pTableHeaders addObject: cellDict];
					[cellDict release];
				}
				// Create artist object and add it to the array.
				UIImageAndTextTableCell *cell = [[UIImageAndTextTableCell alloc] init];
				[cell setTitle:artistname];
				[m_pArtists addObject:cell];
				[cell release];
				count++;
			}
			// Go to the next entry.
			data = mpd_data_get_next(data);
		} while(data);
	} else
		NSLog(@"No data found");
	// Update the table contents.
	[m_pSectionList reloadData];
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
		[m_pApp showPlaylistViewWithTransition:2];
}


- (void)tableRowSelected:(NSNotification*)notification 
{
	// Get selected cell and artist name.
	UIImageAndTextTableCell* pCell = [[notification object] cellAtRow:[[notification object] selectedRow] column:0];
	NSLog(@"Selected artist: %@", [pCell title]);
	// Show the albums of the selected artist.
	[pCell setSelected:FALSE withFade:TRUE];
	[m_pApp showAlbumsViewWithTransition:1 artist:[pCell title]];
}


- (int)numberOfSectionsInSectionList:(UISectionList *)aSectionList {
	return [m_pTableHeaders count];
}

- (NSString *)sectionList:(UISectionList *)aSectionList titleForSection:(int)section {
	return [[m_pTableHeaders objectAtIndex:section] objectForKey:@"title"];
}

- (int)sectionList:(UISectionList *)aSectionList rowForSection:(int)section {
	return [[[m_pTableHeaders objectAtIndex:section] valueForKey:@"beginRow"] intValue];
}

- (int) numberOfRowsInTable: (UITable *)table
{
	return [m_pArtists count];
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col
{
	return [m_pArtists objectAtIndex:row];
}

- (UITableCell *) table: (UITable *)table cellForRow: (int)row column: (int)col reusing: (BOOL) reusing
{
	return [self table: table cellForRow: row column: col];
}

@end
