/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		winerase.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: winerase.c,v 1.1 97/04/18 11:25:33 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/*                                                             */
/* Erase() routines of the PCcurses package                    */
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

char _curses_winerase_rcsid[] = "@(#)winerase.c   v.1.4  - 900114";

/****************************************************************/
/* Werase() fills all lines of window 'win' with blanks and po-        */
/* sitions the cursor at home in the scroll region.            */
/****************************************************************/

void   werase(WINDOW *win)
{
    ntcCell               *end;
    ntcCell               *start;
    short               y;
    ntcCell  		blank;

    (void *)makeNtcCell(&blank, ' ');
    if (win->_flags & _STANDOUT) {
	(void *)hilight(&blank);
    }

    for (y = 0; y <= (win->_maxy - 1); y++) {   /* clear all lines */
	start = win->_line[y];
	end = &start[win->_maxx - 1];
	while (start <= end) {                    /* clear all line */
	    setNtcCell(start, &blank);
	    start++;
	}
	win->_minchng[y] = 0;
	win->_maxchng[y] = win->_maxx - 1;
    }
    win->_cury = 0;                           /* cursor home */
    win->_curx = 0;
} /* werase */

/****************************************************************/
/* Erase() fills all lines of stdscr with blanks and positions */
/* the cursor at home in the scroll region.                    */
/****************************************************************/

void erase(void)
{
    werase(stdscr);
} /* erase */
