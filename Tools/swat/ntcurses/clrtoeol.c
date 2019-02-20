/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		clrtoeol.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: clrtoeol.c,v 1.1 97/04/18 11:19:08 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Wclrtoeol() routine of the PCcurses package			*/
/*								*/
/****************************************************************/
/* This version of curses is based on ncurses, a curses version	*/
/* originally written by Pavel Curtis at Cornell University.	*/
/* I have made substantial changes to make it run on IBM PC's,	*/
/* and therefore consider myself free to make it public domain.	*/
/*				Bjorn Larsson (bl@infovox.se)	*/
/****************************************************************/
/* 1.4:  Use of short wherever possible. Portability		*/
/*	 improvements, misspelled name of mvcrltoeol():	900114	*/
/* 1.3:	 MSC -W3, Turbo'C' -w -w-pro checkes:		881005	*/
/* 1.2:	 Max limits off by 1. Fixed thanks to S. Creps:	880210	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

char _curses_clrtoeol_rcsid[] = "@(#)clrtoeol.c   v.1.4  - 900114";

/****************************************************************/
/* Wclrtoeol() fills the half of the cursor line to the right	*/
/* of the cursor in window 'win' with blanks.			*/
/****************************************************************/

int	
wclrtoeol(WINDOW *win)
{
    ntcCell		*maxx;
    ntcCell		*ptr;
    ntcCell		*end;
    static short	y;
    static short	x;
    static short	minx;
    ntcCell 		blank;

    (void *)makeNtcCell(&blank, ' ');
    if (win->_flags & _STANDOUT) {
	(void *)hilight(&blank);
    }
    
    y = win->_cury;
    x = win->_curx;
    
    end = &win->_line[y][win->_maxx - 1];
    minx = _NO_CHANGE;
    maxx = &win->_line[y][x];
    for (ptr = maxx; ptr <= end; ptr++)	{
	if (sameNtcCell(ptr, &blank) == FALSE) {
	    maxx = ptr;
	    if (minx == _NO_CHANGE) {
		minx = (int) (ptr - win->_line[y]);
	    }
	    setNtcCell(ptr, &blank);
	}
    }
    
    if (minx != _NO_CHANGE) {
	if ((win->_minchng[y] > minx) || (win->_minchng[y] == _NO_CHANGE)) {
	    win->_minchng[y] = minx;
	}
	if (win->_maxchng[y] < (int) (maxx - win->_line[y])) {
	    win->_maxchng[y] = (int) (maxx - win->_line[y]);
	}
    }
    return(OK);
} /* wclrtoeol */

/****************************************************************/
/* Clrtoeol() fills the half of the cursor line to the right	*/
/* of the cursor in stdscr with blanks.				*/
/****************************************************************/

int 
clrtoeol(void)
{
    return(wclrtoeol(stdscr));
} /* clrtoeol */

/****************************************************************/
/* Mvclrtoeol() moves the cursor to a new position in stdscr	*/
/* and fills the right half of the cursor line with blanks.	*/
/****************************************************************/

int 
mvclrtoeol(int y, int x)
{
    if (wmove(stdscr,y,x) == ERR)
	return(ERR);
    return(wclrtoeol(stdscr));
} /* mvclrtoeol */

/****************************************************************/
/* Mvwclrtoeol() moves the cursor to a new position in window	*/
/* 'win', and fills the right half of the cursor line with	*/
/* blanks.							*/
/****************************************************************/

int 
mvwclrtoeol(WINDOW *win, int y, int x)
{
    if (wmove(win,y,x) == ERR)
	return(ERR);
    return(wclrtoeol(win));
} /* mvwclrtoeol */
