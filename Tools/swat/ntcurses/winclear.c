/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		winclear.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: winclear.c,v 1.1 97/04/18 11:25:06 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Clear() routines of the PCcurses package                    */
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

#include <curses.h>
#include <curspriv.h>

char _curses_winclear_rcsid[] = "@(#)winclear.c   v.1.4  - 900114";

/****************************************************************/
/* Wclear() fills all lines of window 'win' with blanks, and   */
/* marks the window to be cleared at next refresh operation.   */
/****************************************************************/

void   
wclear(WINDOW *win)
{
    werase(win);
    win->_clear = TRUE;
} /* wclear */

/****************************************************************/
/* Clear() fills all lines of stdscr with blanks, and marks    */
/* marks sdtscr to be cleared at next refresh operation.       */
/****************************************************************/

void clear(void)
{
    werase(stdscr);
    stdscr->_clear = TRUE;
} /* clear */
