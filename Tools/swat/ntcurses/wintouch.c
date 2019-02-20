/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		wintouch.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: wintouch.c,v 1.1 97/04/18 11:26:16 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Touchwin() routine of the PCcurses package                  */
/*                                                             */
/****************************************************************/
/* This version of curses is based on ncurses, a curses version        */
/* originally written by Pavel Curtis at Cornell University.   */
/* I have made substantial changes to make it run on IBM PC's, */
/* and therefore consider myself free to make it public domain.        */
/*                             Bjorn Larsson (bl@infovox.se)   */
/****************************************************************/
/* 1.4:  Use of short wherever possible. Portability           */
/*      improvements:                                  900114  */
/* 1.3:         MSC -W3, Turbo'C' -w -w-pro checkes:           881005  */
/* 1.2:         Max limits off by 1. Fixed thanks to S. Creps: 881002  */
/* 1.0:         Release:                                       870515  */
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

char _curses_wintouch_rcsid[] = "@(#)wintouch.c   v.1.4  - 900114";

/****************************************************************/
/* touchwin() marks all lines of window 'win' as changed, from */
/* the first to the last character on the line.                        */
/****************************************************************/

void 
touchwin(WINDOW *win)
{
    short y;

    for (y = 0; y < win->_maxy; y++) {
	win->_minchng[y] = 0;
	win->_maxchng[y] = win->_maxx - 1;
    }
} /* touchwin */


/****************************************************************/
/* touchline() marks the line of window 'win' as changed
/****************************************************************/

void 
touchline(WINDOW *win, int y, int min, int max)
{
    win->_minchng[y] = min;
    win->_maxchng[y] = max;
}

