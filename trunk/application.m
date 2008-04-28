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

#import "application.h"
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
		[pApp open_connection];
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
		[pApp ShowPlaylist];
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
	
	// Create mpd object?
	if (!m_pMPD) {
		m_pMPD = mpd_new("192.168.2.2", 6600, NULL);
		// Connect signals.
		mpd_signal_connect_error(m_pMPD, (ErrorCallback)error_callback, self);
		mpd_signal_connect_status_changed(m_pMPD, (StatusChangedCallback)status_changed, self);
		// Set timeout
		mpd_set_connection_timeout(m_pMPD, 10);
	}
	NSLog(@"opening connection to mpd");
	// Try to connect.
	if (mpd_connect(m_pMPD) == MPD_OK) {
		m_Connected = TRUE;
		m_ReconnectCount = 0;
	} else
		m_Connected = FALSE;
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
		NSLog(@"Preferences");
		if (m_ShowPreferences)
			[self showPlaylistViewWithTransition:5];
		else
			[self showPreferencesViewWithTransition:4];
		break;
	case 5:
		NSLog(@"Add");
		if (m_ShowPlaylist)
			[self showArtistsViewWithTransition:1];
		else
			[self showPlaylistViewWithTransition:2];
		break;
	}
}


- (UIButtonBar *)createButtonBar 
{
	UIButtonBar *buttonBar;
	buttonBar = [ [ UIButtonBar alloc ] 
		initInView: m_pMainView
		withFrame: CGRectMake(0, 410, 320, BUTTONBARHEIGHT)
		withItemList: [ self buttonBarItems ] ];
	[buttonBar setDelegate:self];
	[buttonBar setBarStyle:1];
	[buttonBar setButtonBarTrackingMode: 2];

	int buttons[6] = { 1, 2, 3, 4, 5};
	[buttonBar registerButtonGroup:0 withButtons:buttons withCount: 5];
	[buttonBar showButtonGroup: 0 withDuration: 0.0f];
	return buttonBar;
}


- (void)UpdateButtonBar
{
	int tagNumber = 1;
	BOOL bIsPlaying = (mpd_player_get_state(m_pMPD) == MPD_PLAYER_PLAY);
	NSLog(@"Updating button: %d", bIsPlaying);
	UIImage *image = [UIImage applicationImageNamed: (bIsPlaying ? @"resources/pause.png" : @"resources/play.png")];
	[ [ m_pButtonBar viewWithTag:tagNumber ]  setImage:image];
}


- (void)UpdateTitle
{
	if (m_ShowPlaylist) {
		if (m_pPlaylistView)
			[m_pPlaylistView UpdateTitle];
	} else {
		if (m_pArtistsView)
			[m_pArtistsView UpdateTitle];
	}
}


- (void)ShowPlaylist
{
	if (m_pPlaylistView)
		[m_pPlaylistView ShowPlaylist]; 
}


- (id)timertick: (NSTimer *)timer
{
	// Service the mpd status handler.
	if (m_pMPD) {
		if (mpd_status_update(m_pMPD) == MPD_NOT_CONNECTED) {
			m_ReconnectCount++;
			if (m_ReconnectCount > 20 || m_Connected) {
				// Try to reconnect once every 5 seconds.
				[self open_connection];
				m_ReconnectCount = 0;
			}
		}
	}
}


- (void)applicationDidFinishLaunching: (id) unused
{
    UIWindow *window;

	// Clear the pointers.
	m_pMPD = NULL;
	m_pPlaylistView = NULL;
	m_pArtistsView = NULL;
	m_pAlbumsView = NULL;
	m_pSongsView = NULL;
	
	struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
	rect.origin.x = rect.origin.y = 0.0f;
	window = [[UIWindow alloc] initWithContentRect: rect];
	m_pTransitionView = [[UITransitionView alloc] initWithFrame:rect];
	m_pMainView = [[UIView alloc] initWithFrame:rect];
	[window orderFront: self];
	[window makeKey: self];
	[window _setHidden: NO];
	[window setContentView: m_pMainView];
	[m_pMainView addSubview:m_pTransitionView];

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

	// Open a connection to the server.
	[self open_connection];
	// Show the playlist view.
	[self showPlaylistViewWithTransition:1];
}


- (void)showPlaylistViewWithTransition:(int)trans
{
	if (!m_pPlaylistView) {
		m_pPlaylistView = [[PlaylistView alloc] initWithFrame:CGRectMake(0, 0, 320, MAXHEIGHT)];
		[m_pPlaylistView Initialize:self mpd:m_pMPD];
	}
	m_ShowPlaylist = TRUE;
	m_ShowPreferences = FALSE;
	[m_pTransitionView transition:trans toView:m_pPlaylistView];
}


- (void)showArtistsViewWithTransition:(int)trans
{
	if (!m_pArtistsView) {
		m_pArtistsView = [[ArtistsView alloc] initWithFrame:CGRectMake(0, 0, 320, MAXHEIGHT)];
		[m_pArtistsView Initialize:self mpd:m_pMPD];
	}
	m_ShowPlaylist = FALSE;
	[m_pArtistsView ShowArtists];
	[m_pTransitionView transition:trans toView:m_pArtistsView];
}


- (void)showAlbumsViewWithTransition:(int)trans artist:(NSString *)name
{
	if (!m_pAlbumsView) {
		m_pAlbumsView = [[AlbumsView alloc] initWithFrame:CGRectMake(0, 0, 320, MAXHEIGHT)];
		[m_pAlbumsView Initialize:self mpd:m_pMPD];
	}
	m_ShowPlaylist = FALSE;
	[m_pAlbumsView ShowAlbums:name];
	[m_pTransitionView transition:trans toView:m_pAlbumsView];
}


- (void)showSongsViewWithTransition:(int)trans album:(NSString *)albumname artist:(NSString *)name
{
	if (!m_pSongsView) {
		m_pSongsView = [[SongsView alloc] initWithFrame:CGRectMake(0, 0, 320, MAXHEIGHT)];
		[m_pSongsView Initialize:self mpd:m_pMPD];
	}
	m_ShowPlaylist = FALSE;
	[m_pSongsView ShowSongs:albumname artist:name];
	[m_pTransitionView transition:trans toView:m_pSongsView];
}


- (void)showSearchViewWithTransition:(int)trans
{
	if (!m_pSearchView) {
		m_pSearchView = [[SearchView alloc] initWithFrame:CGRectMake(0, 0, 320, MAXHEIGHT)];
		[m_pSearchView Initialize:self mpd:m_pMPD];
	}
	m_ShowPlaylist = FALSE;
	[m_pTransitionView transition:trans toView:m_pSearchView];
}


- (void)showPreferencesViewWithTransition:(int)trans
{
	if (!m_pPreferencesView) {
		m_pPreferencesView = [[PreferencesView alloc] initWithFrame:CGRectMake(0, 0, 320, MAXHEIGHT)];
		[m_pPreferencesView Initialize:self mpd:m_pMPD];
	}
	m_ShowPlaylist = FALSE;
	m_ShowPreferences = TRUE;
	[m_pTransitionView transition:trans toView:m_pPreferencesView];
}

@end
