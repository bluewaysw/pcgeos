/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		move.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: move.c,v 1.1 97/04/18 11:21:31 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Wmove() routine of the PCcurses package                     */
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

#include "curses.h"
#include "curspriv.h"

char _curses_move_rcsid[] = "@(#)move.c       v.1.4  - 900114";

/****************************************************************/
/* Wmove() moves the cursor in window 'win' to position (x,y). */
/****************************************************************/

int
wmove(WINDOW *win, int y, int x)
{
    if ((x < 0)||(x >= win->_maxx)||(y < 0)||(y > (win->_maxy - 1))) {
	return(ERR);
    }
    win->_curx = x;
    win->_cury = y;
    return(OK);
} /* wmove */

/****************************************************************/
/* Move() moves the cursor in stdscr to position (x,y).                */
/****************************************************************/

int move(int y, int x)
{
    return(wmove(stdscr,y,x));
} /* move */
