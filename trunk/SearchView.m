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
#import <UIKit/UITextLabel.h>
#import <UIKit/UIDateLabel.h>	// For defaultFont.
#import <UIKit/UITable.h>
#import <UIKit/UITableCell.h>
#import <UIKit/UITableColumn.h>
#import <UIKit/UISearchField.h>
#import <UIKit/UIFrameAnimation.h>

#import "SearchView.h"
#import "application.h"

//////////////////////////////////////////////////////////////////////////
// SearchTableCell: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation SearchTableCell

- (id) initWithSong: (NSDictionary *)song
{
	self = [super init];
	song_name = [[UITextLabel alloc] initWithFrame: CGRectMake(36, 3, 260, 29)];
	artist_name = [[UITextLabel alloc] initWithFrame: CGRectMake(37, 28, 260, 20)];
		
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
// SearchView: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation SearchView

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
	[nav showLeftButton:nil withStyle:2 rightButton:nil withStyle:0];		// 2 = arrow left.
	[nav setBarStyle: 1];	// Dark style.
	[nav setDelegate:self];
	[nav enableAnimation];

	// Create the search box.
	UISearchField* searchBox = [[UISearchField alloc] initWithFrame:CGRectMake(30, ([UINavigationBar defaultSize].height - [UISearchField defaultHeight]) / 2., 320 - 60., [UISearchField defaultHeight])];
	[searchBox setClearButtonStyle:2];
	[searchBox setFont:[UITextLabel defaultFont]];
	[[searchBox textTraits] setReturnKeyType:6];
	[[searchBox textTraits] setEditingDelegate:self];
	[searchBox setText:@""];
	[searchBox setDisplayEnabled:YES];
	[nav addSubview:searchBox];

	// Create the keyboard.
	m_pKeyboard = [[UIKeyboard alloc] initWithFrame:CGRectMake(0, 410 - [UIKeyboard defaultSize].height, 320, [UIKeyboard defaultSize].height)];
	[self addSubview: m_pKeyboard];
	m_KeyboardVisible = YES;
	
	[self addSubview: nav];
	return self;
}

//  --- OTHER METHODS -----------------------------------------------

- (void)ShowSongs:(NSString *)searchtext
{
	if (!m_pMPD)
		return;
	// Clear the array.
	[m_pSongs removeAllObjects];
	// Get the list of songs.
	mpd_database_search_start(m_pMPD, TRUE);
	mpd_database_search_add_constraint(m_pMPD, MPD_TAG_ITEM_ALBUM, [searchtext cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	MpdData *data = mpd_database_search_commit(m_pMPD);
	if (data) {
		do {
			// Create album object and add it to the array.
			SearchTableCell* cell = [[SearchTableCell alloc] init];
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
}

//  --- DELEGATE METHODS -----------------------------------------------

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button
{
	NSLog(@"SongsView: button %d", button);
	if (button == 0)
		[m_pApp cleanUp];
	else if (button == 1)
		[m_pApp showArtistsViewWithTransition:2];
}


- (void)tableRowSelected:(NSNotification*)notification 
{
	// Get selected cell and song name.
	SearchTableCell* pCell = [[notification object] cellAtRow:[[notification object] selectedRow] column:0];
	NSLog(@"Selected song: %@", [pCell title]);
	[pCell setSelected:FALSE withFade:TRUE];
	// Add all songs?
	if ([[notification object] selectedRow] == 0) {
		int i;
		for (i = 1;i < [m_pSongs count];i++) {
			pCell = [m_pSongs objectAtIndex:i];
			mpd_playlist_queue_add(m_pMPD, pCell->m_Path);
		}
	} else
		mpd_playlist_queue_add(m_pMPD, pCell->m_Path);
	// Flush the queue.
	mpd_playlist_queue_commit(m_pMPD);
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

- (void)keyboardInputChangedSelection:(id)whatisthis
{
	// when i tap the search field, hide if keyboard is already there, or show if it isn't
	if (!m_KeyboardVisible)
		[self ShowKeyboard];
}

- (void)scrollerWillStartDragging:(id)whatisthis
{
	// hide keyboard when start scrolling
	if (m_KeyboardVisible)
		[self HideKeyboard];
}

//  --- KEYBOARD METHODS -----------------------------------------------

- (void)keyboardReturnPressed
{
	[self HideKeyboard];
}

- (void)ShowKeyboard
{
	m_KeyboardVisible = YES;

	CGRect startFrame;
	CGRect endFrame;
	NSMutableArray *animations = [[NSMutableArray alloc] init];
	
	endFrame = CGRectMake(0.0f, 410 - [UIKeyboard defaultSize].height, 320, [UIKeyboard defaultSize].height);
	startFrame = endFrame;
	startFrame.origin.y = 245.0 + 216.;
	
	[m_pKeyboard setFrame:startFrame];
	
	UIFrameAnimation *keyboardAnimation = [[UIFrameAnimation alloc] initWithTarget:m_pKeyboard];
	[keyboardAnimation setStartFrame:startFrame];
	[keyboardAnimation setEndFrame:endFrame];
	[keyboardAnimation setSignificantRectFields:2];
	[keyboardAnimation setDelegate:self];
	[animations addObject:keyboardAnimation];
	[keyboardAnimation release];
	
	[[UIAnimator sharedAnimator] addAnimations:animations withDuration:.5 start:YES];
}

- (void)HideKeyboard
{
	m_KeyboardVisible = NO;
	
	CGRect startFrame;
	CGRect endFrame;
	NSMutableArray *animations = [[NSMutableArray alloc] init];
	
	startFrame = CGRectMake(0, 410 - [UIKeyboard defaultSize].height, 320, [UIKeyboard defaultSize].height);
	endFrame = startFrame;
	endFrame.origin.y = 245.0 + 216.;
	
	[m_pKeyboard setFrame:startFrame];
		
	UIFrameAnimation *keyboardAnimation = [[UIFrameAnimation alloc] initWithTarget:m_pKeyboard];
	[keyboardAnimation setStartFrame:startFrame];
	[keyboardAnimation setEndFrame:endFrame];
	[keyboardAnimation setSignificantRectFields:2];
	[keyboardAnimation setDelegate:self];
	[animations addObject:keyboardAnimation];
	[keyboardAnimation release];
	
	[[UIAnimator sharedAnimator] addAnimations:animations withDuration:.5 start:YES];
}


@end
