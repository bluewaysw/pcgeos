/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		charpick.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: charpick.c,v 1.1 97/04/18 11:18:37 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Winch() routine of the PCcurses package                     */
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
/* 1.2:         Rcsid[] string for maintenance:                881002  */
/* 1.0:         Release:                                       870515  */
/****************************************************************/

#include "curses.h"
#include "curspriv.h"

char _curses_charpick_rcsid[] = "@(#)charpick.c   v.1.4  - 900114";

/****************************************************************/
/* Winch(win) returns the character at the current position in */
/* window 'win'.                                               */
/****************************************************************/

ntcCell *
winch(WINDOW *win)
{
    return(&(win->_line[win->_cury][win->_curx]));
} /* winch */

/****************************************************************/
/* Inch() returns the character at the current cursor position */
/* in stdscr.                                                  */
/****************************************************************/

ntcCell *
inch(void)
{
    return(&(stdscr->_line[stdscr->_cury][stdscr->_curx]));
} /* inch */

/****************************************************************/
/* Mvinch() moves the stdscr cursor to a new position, then    */
/* returns the character at that position.                     */
/****************************************************************/

ntcCell *
mvinch(int y, int x)
{
    if (wmove(stdscr,y,x) == ERR)
	return(ERR);
    return(&(stdscr->_line[stdscr->_cury][stdscr->_curx]));
} /* mvinch */

/****************************************************************/
/* Mvwinch() moves the cursor of window 'win' to a new posi-   */
/* tion, then returns the character at that position.          */
/****************************************************************/

ntcCell *
mvwinch(WINDOW *win, int y, int x)
{
    if (wmove(win,y,x) == ERR)
	return(ERR);
    return(&(win->_line[win->_cury][win->_curx]));
} /* mvwinch */
