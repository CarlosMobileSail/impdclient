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

#import <Foundation/Foundation.h>
#import <Foundation/NSDictionary.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UITextLabel.h>
#import <UIKit/UITableCell.h>

#import "libmpd/libmpd.h"

//////////////////////////////////////////////////////////////////////////
// Forward declarations.
//////////////////////////////////////////////////////////////////////////

@class MPDClientApplication;

//////////////////////////////////////////////////////////////////////////
// PlaylistTableCell: class definition.
//////////////////////////////////////////////////////////////////////////

@interface PlaylistTableCell : UITableCell
{
	UITextLabel *song_name;
	UITextLabel *artist_name;
	UIImageView* play_image;
}
- (id) initWithSong: (NSDictionary *)song;
@end


//////////////////////////////////////////////////////////////////////////
// PlaylistView: class definition.
//////////////////////////////////////////////////////////////////////////

@interface PlaylistView : UIView
{
	UINavigationBar* m_pNavigationBar;
	UINavigationItem* m_pTitle;
	BOOL m_Editing;

	MpdObj* m_pMPD;
	MPDClientApplication* m_pApp;
	
	NSMutableArray* m_pSongs;
	UITable* m_pTable;
}
- (id)initWithFrame:(struct CGRect)frame;
- (void)Initialize:(MPDClientApplication* )pApp mpd:(MpdObj *)pMPD;

- (void)ShowPlaylist;
- (void)UpdateTitle;
- (void)StartPlaySelected:(id)sender;
@end