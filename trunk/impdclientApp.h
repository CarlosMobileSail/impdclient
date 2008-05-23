/*******************************************************************************
 * iPhone Project : iMPDclient                                                 *
 * Copyright (C) 2008 Boris Nagels <joogels@gmail.com>                         *
 *******************************************************************************
 * $LastChangedDate:: 2008-01-29 22:02:23 +0100 (Tue, 29 Jan 2008)           $ *
 * $LastChangedBy:: boris                                                    $ *
 * $LastChangedRevision:: 140                                                $ *
 * $Id:: application.h 140 2008-01-29 21:02:23Z boris                        $ *
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

#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIProgressHUD.h>

#import "libmpd/libmpd.h"

//////////////////////////////////////////////////////////////////////////
// Forward declarations.
//////////////////////////////////////////////////////////////////////////

@class PlaylistView;
@class ArtistsView;
@class AlbumsView;
@class SongsView;
@class SearchView;
@class PreferencesView;

#define TITLEHEIGHT		19
#define NAVBARHEIGHT	48
#define BUTTONBARHEIGHT	50
#define MAXHEIGHT		480 - TITLEHEIGHT - NAVBARHEIGHT - BUTTONBARHEIGHT	// Screenheight - title - navbar - buttonbar.

//////////////////////////////////////////////////////////////////////////
// MPDClientApplication: class definition.
//////////////////////////////////////////////////////////////////////////

@interface MPDClientApplication :  UIApplication
{
@public
	UIView* _mainView;

@protected
	UIWindow* _window;
	UITransitionView* _transitionView;
	UIProgressHUD* _hud;
	
	PlaylistView* _playlistView;
	ArtistsView* _artistsView;
	AlbumsView* _albumsView;
	SongsView* _songsView;
	SearchView* _searchView;
	PreferencesView* _preferencesView;

	UIButtonBar* _buttonBar;
	BOOL _showPlaylist;
	BOOL _showPreferences;
	BOOL _isConnected;
	int _reconnectCount;

	MpdObj* _mpdServer;
	NSTimer* _timer;
}
- (void)dealloc;
- (void)cleanUp;

- (void)openConnection;
- (void)updateTitle;
- (void)showPlaylist;
- (NSArray *)buttonBarItems;
- (void)updateButtonBar;
- (id)timertick: (NSTimer *)timer;
- (void)waitingForServer:(BOOL)isWaiting;

- (void)showPlaylistViewWithTransition:(int)trans;
- (void)showArtistsViewWithTransition:(int)trans;
- (void)showAlbumsViewWithTransition:(int)trans artist:(NSString *)name;
- (void)showSongsViewWithTransition:(int)trans album:(NSString *)albumname artist:(NSString *)name;
- (void)showSearchViewWithTransition:(int)trans;
- (void)showPreferencesViewWithTransition:(int)trans;
@end

//////////////////////////////////////////////////////////////////////////
// MPDClientApplication: externals.
//////////////////////////////////////////////////////////////////////////

extern NSString *kUIButtonBarButtonAction;
extern NSString *kUIButtonBarButtonInfo;
extern NSString *kUIButtonBarButtonInfoOffset;
extern NSString *kUIButtonBarButtonSelectedInfo;
extern NSString *kUIButtonBarButtonStyle;
extern NSString *kUIButtonBarButtonTag;
extern NSString *kUIButtonBarButtonTarget;
extern NSString *kUIButtonBarButtonTitle;
extern NSString *kUIButtonBarButtonTitleVerticalHeight;
extern NSString *kUIButtonBarButtonTitleWidth;
extern NSString *kUIButtonBarButtonType;
