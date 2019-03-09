/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		chardel.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: chardel.c,v 1.1 97/04/18 11:17:56 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Wdelch() routine of the PCcurses package			*/
/*								*/
/****************************************************************/
/* This version of curses is based on ncurses, a curses version	*/
/* originally written by Pavel Curtis at Cornell University.	*/
/* I have made substantial changes to make it run on IBM PC's,	*/
/* and therefore consider myself free to make it public domain.	*/
/*				Bjorn Larsson (bl@infovox.se)	*/
/****************************************************************/
/* 1.4:  Use short wherever possible. Portability		*/
/*	 improvements:					900114	*/
/* 1.3:	 MSC -W3, Turbo'C' -w -w-pro checkes:		881005	*/
/* 1.2:	 Max limits off by 1. Fixed thanks to S. Creps:	881002	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

char _curses_chardel_rcsid[] = "@(#)chardel.c    v.1.4  - 900114";

/****************************************************************/
/* Wdelch() deletes the character at the window cursor, and the	*/
/* characters to the right of it are shifted left, inserting a	*/
/* space at the last position of the line.			*/
/****************************************************************/

int wdelch(WINDOW *win)
{
    ntcCell *temp1;
    ntcCell *temp2;
    ntcCell *end;
    short y = win->_cury;
    short x = win->_curx;

    end = &win->_line[y][win->_maxx - 1];
    temp1 = &win->_line[y][x];
    temp2 = temp1 + 1;

    while (temp1 < end) {
	setNtcCell(temp1, temp2);
	temp1++;
	temp2++;
    }

    (void *)makeNtcCell(temp1, ' ');
    if (win->_flags & _STANDOUT) {
	(void *)hilight(temp1);
    }

    win->_maxchng[y] = win->_maxx - 1;

    if (win->_minchng[y] == _NO_CHANGE || win->_minchng[y] > x) {
	win->_minchng[y] = x;
    }
    return(OK);
} /* wdelch */

/****************************************************************/
/* Delch() deletes the character at the stdscr cursor, and the	*/
/* characters to the right of it are shifted left, inserting a	*/
/* space at the last position of the line.			*/
/****************************************************************/

int 
delch(void)
{
    return(wdelch(stdscr));
} /* delch */

/****************************************************************/
/* Mvdelch() moves the stdscr cursor to a new position, then	*/
/* deletes the character at the stdscr cursor, and the charac-	*/
/* ters to the right of it are shifted left, inserting a space	*/
/* at the last position of the line.				*/
/****************************************************************/

int 
mvdelch(int y, int x)
{
    if (wmove(stdscr,y,x) == ERR)
	return(ERR);
    return(wdelch(stdscr));
} /* mvdelch */

/****************************************************************/
/* Mvwdelch() moves the cursor of window 'win' to a new posi-	*/
/* tion, then deletes the character at the stdscr cursor, and	*/
/* the characters to the right of it are shifted left, inser-	*/
/* ting a space at the last position of the line.		*/
/****************************************************************/

int 
mvwdelch(WINDOW *win, int y, int x)
{
    if (wmove(win,y,x) == ERR) {
	return(ERR);
    }
    return(wdelch(win));
} /* mvwdelch */
