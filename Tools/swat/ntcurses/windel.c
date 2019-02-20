/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		windel.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: windel.c,v 1.1 97/04/18 11:25:20 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Delwin() routine of the PCcurses package.                   */
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
/* 1.2:         Max limits off by 1. Fixed thanks to S. Creps: 881002  */
/* 1.0:         Release:                                       870515  */
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

#include <stdlib.h>

char _curses_windel_rcsid[] = "@(#)windel.c     v.1.4  - 900114";

/****************************************************************/
/* Delwin() deallocates all data allocated by 'win'. If 'win'  */
/* is a subwindow, it uses the original window's lines for sto-        */
/* rage, and thus the line arrays are not deallocated.         */
/****************************************************************/

void 
delwin(WINDOW *win)
{
    short i;

    /* 
     *subwindow uses 'parent's' lines 
     */
    if (! (win->_flags & _SUBWIN)) {
	for (i = 0; i < win->_maxy && win->_line[i]; i++) {
	    free(win->_line[i]);
	}
    }
    free(win->_minchng);
    free(win->_maxchng);
    free(win->_line);
    free(win);
  } /* delwin */
