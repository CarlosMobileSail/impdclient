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
#import <WebCore/WebFontCache.h>

#import "SearchView.h"
#import "application.h"

//////////////////////////////////////////////////////////////////////////
// SearchTableCell: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation SearchTableCell

- (id)initWithSong:(NSString *)song artist:(NSString *)artistinfo
{
	self = [super init];
	song_name = [[UITextLabel alloc] initWithFrame: CGRectMake(36, 2, 260, 24)];
	artist_name = [[UITextLabel alloc] initWithFrame: CGRectMake(37, 26, 260, 17)];
		
	float c[] = { 0.0f, 0.0f, 0.0f, 0.0f };
	float h[] = { 1.0f, 1.0f, 1.0f, 1.0f };
	
	[song_name setText: song];
	[song_name setFont: [UIImageAndTextTableCell defaultTitleFont]];
	[song_name setBackgroundColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), c)];
	[song_name setHighlightedColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), h)];
	
	[artist_name setText: artistinfo];
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
	// Add the keyboard view to the main view and show it.
	[m_pApp->m_pMainView addSubview: m_pKeyboard];
	[self ShowKeyboard];
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
	[m_pTable setRowHeight:50.0f];

	// Create the navigation bar.
	UINavigationBar* nav = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 320, NAVBARHEIGHT)];
	[nav showLeftButton:nil withStyle:2 rightButton:@"Clear" withStyle:1];		// 1 = red.
	[nav setBarStyle: 1];	// Dark style.
	[nav setDelegate:self];
	[nav enableAnimation];

	// Create the search box.
	struct __GSFont* font = [NSClassFromString(@"WebFontCache") createFontWithFamily:@"Helvetica" traits:0 size:16];
	m_pSearchBox = [[UISearchField alloc] initWithFrame:CGRectMake(10, ([UINavigationBar defaultSize].height - [UISearchField defaultHeight]) / 2. + 4, 320 - 80., [UISearchField defaultHeight])];
	[m_pSearchBox setClearButtonStyle:0];
	[m_pSearchBox setFont:font];
	[m_pSearchBox setPaddingBottom:1.0f];
	[m_pSearchBox setPaddingTop:5.0f];
	[[m_pSearchBox textTraits] setAutoCapsType:0];
	[[m_pSearchBox textTraits] setReturnKeyType:6];		// 6 = key next to spacebar shows 'search'.
	[[m_pSearchBox textTraits] setEditingDelegate:self];
	[m_pSearchBox setText:@""];
	[m_pSearchBox setDisplayEnabled:YES];
	[nav addSubview:m_pSearchBox];
	// Set the focus to the search box.
	[m_pSearchBox becomeFirstResponder];
	
	// Create the keyboard.
	m_pKeyboard = [[UIKeyboard alloc] initWithDefaultSize];
	
	[self addSubview: nav];
	return self;
}

//////////////////////////////////////////////////////////////////////////
//  Other methods.
//////////////////////////////////////////////////////////////////////////

- (void)ShowSongs:(NSString *)searchtext
{
	if (!m_pMPD)
		return;
	NSLog(@"Searching for: '%@'", searchtext);
	// Clear the array.
	[m_pSongs removeAllObjects];
	// Get the list of songs.
	mpd_database_search_start(m_pMPD, FALSE);
	mpd_database_search_add_constraint(m_pMPD, MPD_TAG_ITEM_ANY, [searchtext cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	MpdData *data = mpd_database_search_commit(m_pMPD);
	if (data) {
		do {
			// Create album object and add it to the array.
			if (data->type == MPD_DATA_TYPE_SONG) {
				NSString* song = [NSString stringWithCString: data->song->title];
				NSString* info = [NSString stringWithFormat: @"%s, %s", data->song->artist, data->song->album];
				SearchTableCell* cell = [[SearchTableCell alloc] initWithSong:song artist:info];
				strcpy(cell->m_Path, data->song->file);
				[cell setImage:[UIImage applicationImageNamed:@"resources/add2.png"]];
				[m_pSongs addObject:cell];
				[cell release];
			}
			// Go to the next entry.
			data = mpd_data_get_next(data);
		} while(data);
	} else {
		NSLog(@"No data found");
		SearchTableCell* cell = [[SearchTableCell alloc] initWithSong:@"No matches found" artist:@""];
		strcpy(cell->m_Path, "");
		[m_pSongs addObject:cell];
		[cell release];
	}
	// Update the table contents.
	[m_pTable reloadData];
}

//////////////////////////////////////////////////////////////////////////
// Delegate methods.
//////////////////////////////////////////////////////////////////////////

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button
{
	NSLog(@"SearchView: button %d", button);
	if (button == 0) {
		[m_pSearchBox setText:@""];
		[m_pSongs removeAllObjects];
		[m_pTable reloadData];
		if (!m_KeyboardVisible)
			[self ShowKeyboard];
	}
}


- (void)tableRowSelected:(NSNotification*)notification 
{
	SearchTableCell* pCell = [m_pTable cellAtRow:[m_pTable selectedRow] column:0];
	if (strlen(pCell->m_Path) == 0)
		return;
	// Alert sheet attached to bottom of screen.
	UIAlertSheet *alertSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
	[alertSheet setBodyText:@"Add song to the playlist?"];
	[alertSheet addButtonWithTitle:@"Yes"];
	[alertSheet addButtonWithTitle:@"No"];
	[alertSheet setDelegate:self];
	[alertSheet presentSheetFromAboveView:self];
}


- (void)alertSheet:(UIAlertSheet*)sheet buttonClicked:(int)button
{
	if (button == 1) {
		// Get selected cell and song name.
		SearchTableCell* pCell = [m_pTable cellAtRow:[m_pTable selectedRow] column:0];
		NSLog(@"Selected song: %s", pCell->m_Path);
		[pCell setSelected:FALSE withFade:TRUE];
		mpd_playlist_add(m_pMPD, pCell->m_Path);
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

-(void)keyboardInput:(id)k shouldInsertText:(id)i isMarkedText:(int)b
{
	if ([i characterAtIndex:0] == 0xA) {
		//NSLog(@"user pressed search");
		[self KeyboardReturnPressed];
	}
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

//////////////////////////////////////////////////////////////////////////
// Keyboard methods.
//////////////////////////////////////////////////////////////////////////

- (void)KeyboardReturnPressed
{
	// Hide the keyboard.
	[self HideKeyboard];
	// Search the database.
	[self ShowSongs:[m_pSearchBox text]];
}


- (void)ShowKeyboard
{
	m_KeyboardVisible = YES;

	CGRect startFrame;
	CGRect endFrame;
	NSMutableArray *animations = [[NSMutableArray alloc] init];
	
	endFrame = CGRectMake(0.0f, 461 - [UIKeyboard defaultSize].height, 320, [UIKeyboard defaultSize].height);
	startFrame = endFrame;
	startFrame.origin.y = 480;
	
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
	
	startFrame = CGRectMake(0, 461 - [UIKeyboard defaultSize].height, 320, [UIKeyboard defaultSize].height);
	endFrame = startFrame;
	endFrame.origin.y = 480;
	
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
