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
	UIView* m_pMainView;

@protected
	UITransitionView* m_pTransitionView;
	PlaylistView* m_pPlaylistView;
	ArtistsView* m_pArtistsView;
	AlbumsView* m_pAlbumsView;
	SongsView* m_pSongsView;
	SearchView* m_pSearchView;
	PreferencesView* m_pPreferencesView;

	UIButtonBar* m_pButtonBar;
	BOOL m_ShowPlaylist;
	BOOL m_ShowPreferences;
	BOOL m_Connected;
	int m_ReconnectCount;

	MpdObj* m_pMPD;
	NSTimer* m_pTimer;
}
- (void)cleanUp;
- (void)open_connection;
- (void)UpdateTitle;
- (void)ShowPlaylist;
- (void)UpdateButtonBar;
- (id)timertick: (NSTimer *)timer;

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
