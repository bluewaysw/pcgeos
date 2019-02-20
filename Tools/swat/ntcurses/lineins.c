/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		lineins.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: lineins.c,v 1.1 97/04/18 11:20:48 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Winsertln() routine of the PCcurses package			*/
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
/* 1.1:	 Mvinsertln() and friends were misrenamed:	880305	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

char _curses_lineins_rcsid[] = "@(#)lineins.c    v.1.4  - 900114";

/****************************************************************/
/* Winsertln() inserts a blank line instead of the cursor line	*/
/* in window 'win' and pushes other lines down.			*/
/****************************************************************/

int	
winsertln(WINDOW *win)
{
    ntcCell		*temp;
    short		y;
    short		i;
    ntcCell 		blank;

    (void *)makeNtcCell(&blank, ' ');
    if (win->_flags & _STANDOUT) {
	(void *)hilight(&blank);
    }
    
    temp = win->_line[win->_maxy - 1];
    
    for (y = win->_maxy - 1; y > win->_cury;  y--) {
	win->_line[y] = win->_line[y-1];
	win->_minchng[y] = 0;
	win->_maxchng[y] = win->_maxx - 1;
    }
    
    win->_line[y] = temp;
    
    for (i=0; i<win->_maxx; i++) {
	setNtcCell(&win->_line[y][i], &blank);
    }
    
    win->_minchng[y] = 0;
    win->_maxchng[y] = win->_maxx - 1;
    
    return(OK);
} /* winsertln */

/****************************************************************/
/* Insertln() inserts a blank line instead of the cursor line	*/
/* in stdscr and pushes other lines down.			*/
/****************************************************************/

int 
insertln(void)
{
    return(winsertln(stdscr));
} /* insertln */

/****************************************************************/
/* Mvinsertln() moves the stdscr cursor to a new positions, in-	*/
/* serts a blank line instead of the cursor line and pushes	*/
/* other lines down.						*/
/****************************************************************/

int 
mvinsertln(int y, int x)
{
    if (wmove(stdscr,y,x) == ERR)
	return(ERR);
    return(winsertln(stdscr));
} /* mvinsertln */

/****************************************************************/
/* Mvwinsertln() moves the cursor in window 'win' to a new po-	*/
/* si tions, inserts a blank line instead of the cursor line	*/
/* and pushes other lines down.					*/
/****************************************************************/

int 
mvwinsertln(WINDOW *win, int y, int x)
{
    if (wmove(win,y,x) == ERR)
	return(ERR);
    return(winsertln(win));
} /* mvwinsertln */
