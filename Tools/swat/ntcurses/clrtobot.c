/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		clrtobot.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: clrtobot.c,v 1.1 97/04/18 11:18:52 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Wclrtobot() routine of the PCcurses package			*/
/*								*/
/****************************************************************/
/* This version of curses is based on ncurses, a curses version	*/
/* originally written by Pavel Curtis at Cornell University.	*/
/* I have made substantial changes to make it run on IBM PC's,	*/
/* and therefore consider myself free to make it public domain.	*/
/*				Bjorn Larsson (bl@infovox.se)	*/
/****************************************************************/
/* 1.4:  Use of short wherever possible. Portability		*/
/*	 improvements:					900114	*/
/* 1.3:	 MSC -W3, Turbo'C' -w -w-pro checkes:		881005	*/
/* 1.2:	 Max limits off by 1. Fixed thanks to S. Creps:	881002	*/
/* 1.1:	 Renamed clrbot() to clrtobot(). Reported by		*/
/*	 Eric Roscos:					870907	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

char _curses_clrtobot_rcsid[] = "@(#)clrtobot.c   v.1.4  - 900114";

/****************************************************************/
/* Wclrtobot() fills the right half of the cursor line of	*/
/* window 'win', and all lines below it with blanks.		*/
/****************************************************************/

int	
wclrtobot(WINDOW *win)
{
    short		y;
    short		minx;
    static short	startx;
    static ntcCell	*ptr;
    static ntcCell	*end;
    static ntcCell	*maxx;

    ntcCell 		blank;

    (void *)makeNtcCell(&blank, ' ');
    if (win->_flags & _STANDOUT) {
	(void *)hilight(&blank);
    }

    startx = win->_curx;
    for (y = win->_cury; y < win->_maxy; y++) {
	minx = _NO_CHANGE;
	end = &win->_line[y][win->_maxx - 1];
	for (ptr = &win->_line[y][startx]; ptr <= end; ptr++) {
	    if (sameNtcCell(ptr, &blank) == FALSE) {
		maxx = ptr;
		if (minx == _NO_CHANGE) {
		    minx = (int) (ptr - win->_line[y]);
		}
		setNtcCell(ptr, &blank);
	    }
	}
	if (minx != _NO_CHANGE) {
	    if ((win->_minchng[y] > minx) ||
		(win->_minchng[y] == _NO_CHANGE)) {
		win->_minchng[y] = minx;
	    }
	    if (win->_maxchng[y] < (int) (maxx - win->_line[y])) {
		win->_maxchng[y] = (int) (maxx - win->_line[y]);
	    }
	}
	startx = 0;
    }
    return(OK);
} /* wclrtobot */

/****************************************************************/
/* Clrtobot() fills the right half of the cursor line of	*/
/* stdscr, and all lines below it with blanks.			*/
/****************************************************************/

int 
clrtobot(void)
{
    return(wclrtobot(stdscr));
} /* clrtobot */

/****************************************************************/
/* Mvclrtobot() moves the cursor to a new position in stdscr	*/
/* and fills the right half of the cursor line, and all lines	*/
/* below it with blanks.					*/
/****************************************************************/

int 
mvclrtobot(int y, int x)
{
    if (wmove(stdscr,y,x) == ERR) {
	return(ERR);
    }
    return(wclrtobot(stdscr));
} /* mvclrtobot */

/****************************************************************/
/* Mvwclrtobot() moves the cursor to a new position in window	*/
/* 'win', and fills the right half of the cursor line, and all	*/
/* lines below it with blanks.					*/
/****************************************************************/

int 
mvwclrtobot(WINDOW *win, int y, int x)
{
    if (wmove(win,y,x) == ERR) {
	return(ERR);
    }
    return(wclrtobot(win));
} /* mvwclrtobot */
