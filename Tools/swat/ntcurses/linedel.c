/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		linedel.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: linedel.c,v 1.1 97/04/18 11:20:34 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Wdeleteln() routine of the PCcurses package			*/
/*								*/
/****************************************************************/
/* This version of curses is based on ncurses, a curses version	*/
/* originally written by Pavel Curtis at Cornell University.	*/
/* I have made substantial changes to make it run on IBM PC's,	*/
/* and therefore consider myself free to make it public domain.	*/
/*		Bjorn Larsson (...mcvax!enea!infovax!bl)	*/
/****************************************************************/
/* 1.4:  Use of short wherever possible. Portability		*/
/*	 improvements:					900114	*/
/* 1.3:	 MSC -W3, Turbo'C' -w -w-pro checkes:		881005	*/
/* 1.2:	 Max limits off by 1. Fixed thanks to S. Creps:	881002	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

char _curses_linedel_rcsid[] = "@(#)linedel.c    v.1.4  - 900114";

/****************************************************************/
/* Wdeleteln() deletes the line at the window cursor, and the	*/
/* lines below it are shifted up, inserting a blank line at	*/
/* the bottom of the window.					*/
/****************************************************************/

int	
wdeleteln(WINDOW *win)
{
    ntcCell		*temp;
    short	 	y;
    short		i;
    ntcCell 		blank;

    (void *)makeNtcCell(&blank, ' ');
    if (win->_flags & _STANDOUT) {
	(void *)hilight(&blank);
    }
    
    temp = win->_line[win->_cury];

    for (y = win->_cury; y < (win->_maxy - 1); y++) {
	win->_line[y] = win->_line[y+1];
	win->_minchng[y] = 0;
	win->_maxchng[y] = win->_maxx - 1;
    }
    
    win->_line[y] = temp;
    
    for (i = 0; i < win->_maxx; i++) {
	setNtcCell(&win->_line[y][i], &blank);
    }
    
    win->_minchng[y] = 0;
    win->_maxchng[y] = win->_maxx - 1;
    
    return(OK);
} /* wdeleteln */

/****************************************************************/
/* Deleteln() deletes the line at the stdscr cursor, and the	*/
/* lines below it are shifted up, inserting a blank line at	*/
/* the bottom of stdscr.					*/
/****************************************************************/

int 
deleteln(void)
{
    return(wdeleteln(stdscr));
} /* deleteln */

/****************************************************************/
/* Mvdeleteln() moves the cursor to a new position in stdscr,	*/
/* then deletes the line at the window cursor, and the lines	*/
/* below it are shifted up, inserting a blank line at the bot-	*/
/* tom of stdscr.						*/
/****************************************************************/

int 
mvdeleteln(int y, int x)
{
    if (wmove(stdscr,y,x) == ERR)
	return(ERR);
    return(wdeleteln(stdscr));
} /* mvdeleteln */

/****************************************************************/
/* Mvwdeleteln() moves the cursor to a new position in a win-	*/
/* dow, then deletes the line at the window cursor, and the	*/
/* lines below it are shifted up, inserting a blank line at	*/
/* the bottom of the window.					*/
/****************************************************************/

int 
mvwdeleteln(WINDOW *win, int y, int x)
{
    if (wmove(win,y,x) == ERR)
	return(ERR);
    return(wdeleteln(win));
} /* mvwdeleteln */
