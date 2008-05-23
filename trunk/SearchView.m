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
#import "impdclientApp.h"

//////////////////////////////////////////////////////////////////////////
// SearchTableCell: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation SearchTableCell

- (void)dealloc
{
	// Release all objects.
	[_songName release];
	[_artistName release];
	// Call the base class.
	[super dealloc];
}


- (id)initWithSong:(NSString *)song artist:(NSString *)artistInfo
{
	self = [super init];
	_songName = [[UITextLabel alloc] initWithFrame: CGRectMake(36, 2, 260, 24)];
	_artistName = [[UITextLabel alloc] initWithFrame: CGRectMake(37, 26, 260, 17)];
		
	float c[] = { 0.0f, 0.0f, 0.0f, 0.0f };
	float h[] = { 1.0f, 1.0f, 1.0f, 1.0f };
	
	[_songName setText: song];
	[_songName setFont: [UIImageAndTextTableCell defaultTitleFont]];
	[_songName setBackgroundColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), c)];
	[_songName setHighlightedColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), h)];
	
	[_artistName setText: artistInfo];
	[_artistName setFont: [UIDateLabel defaultFont]];
	[_artistName setColor: CGColorCreateCopyWithAlpha([_artistName color], 0.4f)];
	[_artistName setBackgroundColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), c)];
	[_artistName setHighlightedColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), h)];

	[self addSubview: _artistName];
	[self addSubview: _songName];
	return self;
}


- (void) drawContentInRect: (struct CGRect)rect selected: (BOOL) selected
{
	[_songName setHighlighted: selected];
	[_artistName setHighlighted: selected];
	[super drawContentInRect: rect selected: selected];
}

@end

//////////////////////////////////////////////////////////////////////////
// SearchView: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation SearchView

- (void)dealloc
{
	// Release all objects.
	[_table release];
	[_searchBox release];
	[_keyboard release];
	[_navBar release];
	// Call the base class.
	[super dealloc];
}


- (void)initialize:(MPDClientApplication *)app mpd:(MpdObj *)mpdServer
{
	_app = app;
	_mpdServer = mpdServer;
	// Add the keyboard view to the main view and show it.
	[_app->_mainView addSubview: _keyboard];
	[self showKeyboard];
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
	UITableColumn *col = [[UITableColumn alloc] initWithTitle: @"iMPDclient" identifier: @"column1" width: 320.0f];
	[_table addTableColumn: col]; 
	[_table setDelegate: self];
	[_table setDataSource: self];
	[_table setSeparatorStyle:1];
	[_table setRowHeight:50.0f];

	// Create the navigation bar.
	_navBar = [[UINavigationBar alloc] initWithFrame: CGRectMake(0, 0, 320, NAVBARHEIGHT)];
	[_navBar showLeftButton:@"Artists" withStyle:2 rightButton:@"Clear" withStyle:1];		// 1 = red.
	[_navBar setBarStyle: 1];	// Dark style.
	[_navBar setDelegate:self];
	[_navBar enableAnimation];

	// Create the search box.
	struct __GSFont* font = [NSClassFromString(@"WebFontCache") createFontWithFamily:@"Helvetica" traits:0 size:16];
	_searchBox = [[UISearchField alloc] initWithFrame:CGRectMake(70, ([UINavigationBar defaultSize].height - [UISearchField defaultHeight]) / 2. + 4, 320 - 140., [UISearchField defaultHeight])];
	[_searchBox setClearButtonStyle:0];
	[_searchBox setFont:font];
	[_searchBox setPaddingBottom:1.0f];
	[_searchBox setPaddingTop:5.0f];
	[[_searchBox textTraits] setAutoCapsType:0];
	[[_searchBox textTraits] setReturnKeyType:6];		// 6 = key next to spacebar shows 'search'.
	[[_searchBox textTraits] setEditingDelegate:self];
	[_searchBox setText:@""];
	[_searchBox setDisplayEnabled:YES];
	[_navBar addSubview:_searchBox];
	// Set the focus to the search box.
	[_searchBox becomeFirstResponder];
	
	// Create the keyboard.
	_keyboard = [[UIKeyboard alloc] initWithDefaultSize];
	
	[self addSubview: _navBar];
	return self;
}

//////////////////////////////////////////////////////////////////////////
//  Other methods.
//////////////////////////////////////////////////////////////////////////

- (void)showSongs:(NSString *)searchText
{
	if (!_mpdServer)
		return;
	NSLog(@"Searching for: '%@'", searchText);
	// Clear the array.
	[_songs removeAllObjects];
	// Get the list of songs.
	mpd_database_search_start(_mpdServer, FALSE);
	mpd_database_search_add_constraint(_mpdServer, MPD_TAG_ITEM_ANY, [searchText cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	MpdData *data = mpd_database_search_commit(_mpdServer);
	if (data) {
		do {
			// Create album object and add it to the array.
			if (data->type == MPD_DATA_TYPE_SONG) {
				NSString* song = [NSString stringWithCString: data->song->title];
				NSString* info = [NSString stringWithFormat: @"%s, %s", data->song->artist, data->song->album];
				SearchTableCell* cell = [[SearchTableCell alloc] initWithSong:song artist:info];
				strcpy(cell->_path, data->song->file);
				[cell setImage:[UIImage applicationImageNamed:@"resources/add2.png"]];
				[_songs addObject:cell];
				[cell release];
			}
			// Go to the next entry.
			data = mpd_data_get_next(data);
		} while(data);
	} else {
		NSLog(@"No data found");
		SearchTableCell* cell = [[SearchTableCell alloc] initWithSong:@"No matches found" artist:@""];
		strcpy(cell->_path, "");
		[_songs addObject:cell];
		[cell release];
	}
	// Update the table contents.
	[_table reloadData];
}

//////////////////////////////////////////////////////////////////////////
// Delegate methods.
//////////////////////////////////////////////////////////////////////////

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button
{
	NSLog(@"SearchView: button %d", button);
	if (button == 0) {
		[_searchBox setText:@""];
		[_songs removeAllObjects];
		[_table reloadData];
		if (!_keyboardVisible)
			[self showKeyboard];
	} else {
		// Go back to the artist view.
		[_app showArtistsViewWithTransition:2];
		[self hideKeyboard];
	}
}


- (void)tableRowSelected:(NSNotification*)notification 
{
	SearchTableCell* pCell = [_table cellAtRow:[_table selectedRow] column:0];
	if (strlen(pCell->_path) == 0)
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
		SearchTableCell* pCell = [_table cellAtRow:[_table selectedRow] column:0];
		NSLog(@"Selected song: %s", pCell->_path);
		[pCell setSelected:FALSE withFade:TRUE];
		mpd_playlist_add(_mpdServer, pCell->_path);
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

-(void)keyboardInput:(id)k shouldInsertText:(id)i isMarkedText:(int)b
{
	if ([i characterAtIndex:0] == 0xA) {
		//NSLog(@"user pressed search");
		[self keyboardReturnPressed];
	}
}

- (void)keyboardInputChangedSelection:(id)whatisthis
{
	// when i tap the search field, hide if keyboard is already there, or show if it isn't
	if (!_keyboardVisible)
		[self showKeyboard];
}

- (void)scrollerWillStartDragging:(id)whatisthis
{
	// hide keyboard when start scrolling
	if (_keyboardVisible)
		[self hideKeyboard];
}

//////////////////////////////////////////////////////////////////////////
// Keyboard methods.
//////////////////////////////////////////////////////////////////////////

- (void)keyboardReturnPressed
{
	// Hide the keyboard.
	[self hideKeyboard];
	// Search the database.
	[self showSongs:[_searchBox text]];
}


- (void)showKeyboard
{
	_keyboardVisible = YES;

	CGRect startFrame;
	CGRect endFrame;
	NSMutableArray *animations = [[NSMutableArray alloc] init];
	
	endFrame = CGRectMake(0.0f, 461 - [UIKeyboard defaultSize].height, 320, [UIKeyboard defaultSize].height);
	startFrame = endFrame;
	startFrame.origin.y = 480;
	
	[_keyboard setFrame:startFrame];
	
	UIFrameAnimation *keyboardAnimation = [[UIFrameAnimation alloc] initWithTarget:_keyboard];
	[keyboardAnimation setStartFrame:startFrame];
	[keyboardAnimation setEndFrame:endFrame];
	[keyboardAnimation setSignificantRectFields:2];
	[keyboardAnimation setDelegate:self];
	[animations addObject:keyboardAnimation];
	[keyboardAnimation release];
	
	[[UIAnimator sharedAnimator] addAnimations:animations withDuration:.5 start:YES];
}


- (void)hideKeyboard
{
	_keyboardVisible = NO;
	
	CGRect startFrame;
	CGRect endFrame;
	NSMutableArray *animations = [[NSMutableArray alloc] init];
	
	startFrame = CGRectMake(0, 461 - [UIKeyboard defaultSize].height, 320, [UIKeyboard defaultSize].height);
	endFrame = startFrame;
	endFrame.origin.y = 480;
	
	[_keyboard setFrame:startFrame];
		
	UIFrameAnimation *keyboardAnimation = [[UIFrameAnimation alloc] initWithTarget:_keyboard];
	[keyboardAnimation setStartFrame:startFrame];
	[keyboardAnimation setEndFrame:endFrame];
	[keyboardAnimation setSignificantRectFields:2];
	[keyboardAnimation setDelegate:self];
	[animations addObject:keyboardAnimation];
	[keyboardAnimation release];
	
	[[UIAnimator sharedAnimator] addAnimations:animations withDuration:.5 start:YES];
}

@end
