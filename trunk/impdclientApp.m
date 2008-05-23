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
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIHardware.h>

#import "impdclientApp.h"
#import "PlaylistView.h"
#import "ArtistsView.h"
#import "AlbumsView.h"
#import "SongsView.h"
#import "SearchView.h"
#import "PreferencesView.h"

//////////////////////////////////////////////////////////////////////////
// MPD: callback functions.
//////////////////////////////////////////////////////////////////////////

void error_callback(MpdObj *mi, int errorid, char *msg, void *userdata)
{
	MPDClientApplication* pApp = (MPDClientApplication *)userdata;
	// Is the connection lost?
	if (errorid == MPD_NOT_CONNECTED) {
		// Try to reconnect.
		[pApp openConnection];
	} else
		NSLog(@"Error [%d]: %s", errorid, msg);
}

void status_changed(MpdObj *mi, ChangedStatusType what, void *userdata)
{
	MPDClientApplication* pApp = (MPDClientApplication *)userdata;
	BOOL bHandled = FALSE;
	// First check the playing state.
	if (what & MPD_CST_STATE) {
		// The state of the player has changed. Update the button.
		[pApp updateButtonBar];
		bHandled = TRUE;
	}
	// Check the elapsed time.
	if (what & MPD_CST_ELAPSED_TIME) {
		// Update the interface.
		[pApp updateTitle];
		bHandled = TRUE;
	}
	if ((what & MPD_CST_PLAYLIST) || (what & MPD_CST_SONGID)) {
		// The playlist has changed.
		[pApp showPlaylist];
		bHandled = TRUE;
	}
	if (what & MPD_CST_BITRATE)
		bHandled = TRUE;
	if (!bHandled)
		NSLog(@"Status changed: 0x%08X", (int)what);
}

//////////////////////////////////////////////////////////////////////////
// Application: implementation.
//////////////////////////////////////////////////////////////////////////

@implementation MPDClientApplication

- (void)dealloc
{
	// Release all objects.
	[_timer release];
	[_buttonBar release];
	[_mainView release];
	[_hud release];
	[_transitionView release];
	[_window release];
	// Release all views.
	[_playlistView release];
	[_artistsView release];
	[_albumsView release];
	[_songsView release];
	[_searchView release];
	[_preferencesView release];
	// Call the base class.
	[super dealloc];
}


- (void)applicationDidFinishLaunching: (id) unused
{
	// Clear the pointers.
	_mpdServer = NULL;
	_playlistView = NULL;
	_artistsView = NULL;
	_albumsView = NULL;
	_songsView = NULL;
	_searchView = NULL;
	_preferencesView = NULL;
	
	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
	rect.origin.x = rect.origin.y = 0.0f;
	_window = [[UIWindow alloc] initWithContentRect: rect];
	_transitionView = [[UITransitionView alloc] initWithFrame:rect];
	_mainView = [[UIView alloc] initWithFrame:rect];
	[_window orderFront: self];
	[_window makeKey: self];
	[_window _setHidden: NO];
	[_window setContentView: _mainView];
	[_mainView addSubview:_transitionView];

	// Create the button bar.
	_buttonBar = [ [ UIButtonBar alloc ]
		initInView: _mainView
		withFrame: CGRectMake(0, 410, 320, BUTTONBARHEIGHT)
		withItemList: [ self buttonBarItems ] ];
	[_buttonBar setDelegate:self];
	[_buttonBar setBarStyle:1];
	[_buttonBar setButtonBarTrackingMode: 2];
	int buttons[6] = { 1, 2, 3, 4, 5};
	[_buttonBar registerButtonGroup:0 withButtons:buttons withCount: 5];
	[_buttonBar showButtonGroup: 0 withDuration: 0.0f];
	[_mainView addSubview: _buttonBar];

	_hud = [[UIProgressHUD alloc] initWithFrame:rect];
	[_hud setText:@"Waiting for server..."];
	[_mainView addSubview: _hud];
	
	// Create a timer (every 2 seconds, to save power: timer is checking server status through wifi).
	double tickIntervalM = 2;
	_timer = [NSTimer scheduledTimerWithTimeInterval: tickIntervalM
				target: self
				selector: @selector(timertick:)
				userInfo: nil
				repeats: YES];

	// Open a connection to the server.
	[self openConnection];
	// Show the playlist view?
	if (_isConnected)
		[self showPlaylistViewWithTransition:1];
	else {
		// Show the settings screen.
		[self showPreferencesViewWithTransition:4];
	}
}


- (void)applicationWillTerminate:(NSNotification *)notification
{
	if (_mpdServer)
		mpd_free(_mpdServer);
	[self terminateWithSuccess];
}


- (void)cleanUp
{
	NSLog(@"cleanUP");
	[self applicationWillTerminate:nil];
}

//////////////////////////////////////////////////////////////////////////
// libmpd: related functions.
//////////////////////////////////////////////////////////////////////////

- (void)openConnection
{
	[self waitingForServer:YES];
	// Create mpd object?
	if (!_mpdServer) {
		_mpdServer = mpd_new_default();
		// Connect signals.
		mpd_signal_connect_error(_mpdServer, (ErrorCallback)error_callback, self);
		mpd_signal_connect_status_changed(_mpdServer, (StatusChangedCallback)status_changed, self);
		// Set timeout
		mpd_set_connection_timeout(_mpdServer, 10);
	}
	// Get the settings from the user defaults.
	NSUserDefaults* pDefaults = [NSUserDefaults standardUserDefaults];
	NSString* hostname = [pDefaults stringForKey:@"hostname"];
	int serverport = [pDefaults integerForKey:@"port"];
	if (!hostname) {
		// Set the initial value.
		hostname = @"192.168.2.2";
		serverport = 6600;
		// Save the default values.
		[pDefaults setObject:hostname forKey:@"hostname"];
		[pDefaults setInteger:serverport forKey:@"port"];
	}
	// Open the connection to the server.
	NSLog(@"Opening connection to server: '%@', %i", hostname, serverport);
	mpd_set_hostname(_mpdServer, (char *)[hostname cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	mpd_set_port(_mpdServer, serverport);
	// Try to connect.
	if (mpd_connect(_mpdServer) == MPD_OK) {
		_isConnected = TRUE;
		_reconnectCount = 0;
	} else
		_isConnected = FALSE;
	[self waitingForServer:NO];
}

//////////////////////////////////////////////////////////////////////////
// Buttonbar: related functions.
//////////////////////////////////////////////////////////////////////////

- (NSArray *)buttonBarItems 
{
	BOOL bIsPlaying = (mpd_player_get_state(_mpdServer) == MPD_PLAYER_PLAY);
	NSLog(@"buttonBarItems");
	return [ NSArray arrayWithObjects:
	[ NSDictionary dictionaryWithObjectsAndKeys:
		@"buttonBarItemTapped:", kUIButtonBarButtonAction,
		bIsPlaying ? @"resources/pause.png" : @"resources/play.png", kUIButtonBarButtonInfo,
		bIsPlaying ? @"resources/pause.png" : @"resources/play.png", kUIButtonBarButtonSelectedInfo,
		[ NSNumber numberWithInt: 1], kUIButtonBarButtonTag,
		self, kUIButtonBarButtonTarget,
		@"Play/Pause", kUIButtonBarButtonTitle,
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
		@"resources/settings.png", kUIButtonBarButtonInfo,
		@"resources/settings.png", kUIButtonBarButtonSelectedInfo,
		[ NSNumber numberWithInt: 4], kUIButtonBarButtonTag,
		self, kUIButtonBarButtonTarget,
		@"Settings", kUIButtonBarButtonTitle,
		@"0", kUIButtonBarButtonType,
		nil
	],
	[ NSDictionary dictionaryWithObjectsAndKeys:
		@"buttonBarItemTapped:", kUIButtonBarButtonAction,
		@"resources/music_add.png", kUIButtonBarButtonInfo,
		@"resources/music_add.png", kUIButtonBarButtonSelectedInfo,
		[ NSNumber numberWithInt: 5], kUIButtonBarButtonTag,
		self, kUIButtonBarButtonTarget,
		@"Add", kUIButtonBarButtonTitle,
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
		if (mpd_player_get_state(_mpdServer) == MPD_PLAYER_PLAY)
			mpd_player_pause(_mpdServer);
		else
			mpd_player_play(_mpdServer);
		break;
	case 2:
		NSLog(@"Previous");
		mpd_player_prev(_mpdServer);
		[_buttonBar showSelectionForButton:1];
		break;
	case 3:
		NSLog(@"Next");
		mpd_player_next(_mpdServer);
		[_buttonBar showSelectionForButton:1];
		break;
	case 4:
		NSLog(@"Preferences");
		if (_showPreferences) {
			[_preferencesView saveSettings];
			[self showPlaylistViewWithTransition:5];
		} else
			[self showPreferencesViewWithTransition:4];
		break;
	case 5:
		NSLog(@"Add");
		if (_showPlaylist)
			[self showArtistsViewWithTransition:1];
		break;
	}
}


- (void)updateButtonBar
{
	int tagNumber = 1;
	BOOL bIsPlaying = (mpd_player_get_state(_mpdServer) == MPD_PLAYER_PLAY);
	NSLog(@"Updating button: %d", bIsPlaying);
	// Select the play button and set the proper image and text.
	UIImage* image = [UIImage applicationImageNamed: (bIsPlaying ? @"resources/pause.png" : @"resources/play.png")];
	[_buttonBar showSelectionForButton:1];
	[[_buttonBar viewWithTag:tagNumber] setImage:image];
}

//////////////////////////////////////////////////////////////////////////
// Other functions.
//////////////////////////////////////////////////////////////////////////

- (void)waitingForServer:(BOOL)isWaiting
{
	// Show the alert sheet?
	[_hud show:(isWaiting ? YES : NO)];
}


- (void)updateTitle
{
	if (_showPlaylist) {
		if (_playlistView)
			[_playlistView updateTitle];
	} else {
		if (_artistsView)
			[_artistsView updateTitle];
	}
}


- (void)showPlaylist
{
	if (_playlistView)
		[_playlistView showPlaylist]; 
}


- (id)timertick: (NSTimer *)timer
{
	// Service the mpd status handler.
	if (_mpdServer) {
		if (mpd_status_update(_mpdServer) == MPD_NOT_CONNECTED && !_showPreferences) {
			_reconnectCount++;
			if (_reconnectCount > 20 || _isConnected) {
				// Try to reconnect once every 5 seconds.
				[self openConnection];
				_reconnectCount = 0;
			}
		}
	}
}


- (void)showPlaylistViewWithTransition:(int)trans
{
	if (!_playlistView) {
		_playlistView = [[PlaylistView alloc] initWithFrame:CGRectMake(0, 0, 320, MAXHEIGHT + BUTTONBARHEIGHT)];
		[_playlistView initialize:self mpd:_mpdServer];
	}
	_showPlaylist = TRUE;
	_showPreferences = FALSE;
	[_transitionView transition:trans toView:_playlistView];
	[self updateButtonBar];
}


- (void)showArtistsViewWithTransition:(int)trans
{
	if (!_artistsView) {
		_artistsView = [[ArtistsView alloc] initWithFrame:CGRectMake(0, 0, 320, MAXHEIGHT + BUTTONBARHEIGHT)];
		[_artistsView initialize:self mpd:_mpdServer];
	}
	_showPlaylist = FALSE;
	[_artistsView showArtists];
	[_transitionView transition:trans toView:_artistsView];
	[self updateButtonBar];
}


- (void)showAlbumsViewWithTransition:(int)trans artist:(NSString *)name
{
	if (!_albumsView) {
		_albumsView = [[AlbumsView alloc] initWithFrame:CGRectMake(0, 0, 320, MAXHEIGHT + BUTTONBARHEIGHT)];
		[_albumsView initialize:self mpd:_mpdServer];
	}
	_showPlaylist = FALSE;
	[_albumsView showAlbums:name];
	[_transitionView transition:trans toView:_albumsView];
}


- (void)showSongsViewWithTransition:(int)trans album:(NSString *)albumName artist:(NSString *)name
{
	if (!_songsView) {
		_songsView = [[SongsView alloc] initWithFrame:CGRectMake(0, 0, 320, MAXHEIGHT + BUTTONBARHEIGHT)];
		[_songsView initialize:self mpd:_mpdServer];
	}
	_showPlaylist = FALSE;
	[_songsView showSongs:albumName artist:name];
	[_transitionView transition:trans toView:_songsView];
}


- (void)showSearchViewWithTransition:(int)trans
{
	if (!_searchView) {
		_searchView = [[SearchView alloc] initWithFrame:CGRectMake(0, 0, 320, MAXHEIGHT + BUTTONBARHEIGHT)];
		[_searchView initialize:self mpd:_mpdServer];
	}
	_showPlaylist = FALSE;
	[_transitionView transition:trans toView:_searchView];
	[_searchView showKeyboard];
}


- (void)showPreferencesViewWithTransition:(int)trans
{
	if (!_preferencesView) {
		_preferencesView = [[PreferencesView alloc] initWithFrame:CGRectMake(0, 0, 320, MAXHEIGHT + BUTTONBARHEIGHT)];
		[_preferencesView initialize:self mpd:_mpdServer];
	}
	_showPlaylist = FALSE;
	_showPreferences = TRUE;
	[_transitionView transition:trans toView:_preferencesView];
	[self updateButtonBar];
}

@end
