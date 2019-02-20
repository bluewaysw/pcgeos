/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		tabsize.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: tabsize.c,v 1.1 97/04/18 11:24:23 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Tabsize() routines of the PCcurses package                  */
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
/* 1.3:  MSC -W3, Turbo'C' -w -w-pro checkes:          881005  */
/* 1.2:         Rcsid[] string for maintenance:                881002  */
/* 1.0:         Release:                                       870515  */
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

char _curses_tabsize_rcsid[] = "@(#)tabsize.c    v.1.4  - 900114";

/****************************************************************/
/* Wtabsize(win,ts) sets the tabsize of window 'win' to 'ts',  */
/* and returns the original value.                             */
/****************************************************************/

int    wtabsize(WINDOW *win, int ts)
{
    short                 origval;
    
    origval = win->_tabsize;
    win->_tabsize = ts;
    return(origval);
} /* wtabsize*/

/****************************************************************/
/* Tabsize(ts) sets the tabsize of stdscr to 'ts', and returns */
/* the original value.                                         */
/****************************************************************/

int    tabsize(int ts)
{
    short                origval;
    
    origval = stdscr->_tabsize;
    stdscr->_tabsize = ts;
    return(origval);
} /* tabsize */
