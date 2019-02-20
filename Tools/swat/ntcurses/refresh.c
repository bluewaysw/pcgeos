/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		refresh.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: refresh.c,v 1.1 97/04/18 11:23:11 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Wrefresh() and wnoutrefresh() routines of the PCcurses	*/
/* package							*/
/*								*/
/****************************************************************/
/* This version of curses is based on ncurses, a curses version	*/
/* originally written by Pavel Curtis at Cornell University.	*/
/* I have made substantial changes to make it run on IBM PC's,	*/
/* and therefore consider myself free to make it public domain.	*/
/*				Bjorn Larsson (bl@infovox.se)	*/
/****************************************************************/
/* 1.4:  Use of short wherever possible. Refresh() slig-	*/
/*	 htly faster. Portability improvements:		900114	*/
/* 1.3:	 MSC -W3, Turbo'C' -w -w-pro checkes:		881005	*/
/* 1.2:	 Max limits off by 1. Fixed thanks to S. Creps:	881002	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

char _curses_refresh_rcsid[] = "@(#)refresh.c    v.1.4  - 900114";

/****************************************************************/
/* Wrefresh() updates window win's area of the physical screen.	*/
/****************************************************************/
void 
wrefresh(WINDOW	*win)
{
    register ntcCell *thepos;	/* position in window */
    register ntcCell *endpos;	/* end position in window */
    register ntcCell *scrpos;	/* position in curscr */
    short   y;			/* y position in window */
    short   scry;		/* y position in console/imgwin */
    short   scrx;		/* x position in console/imgwin */

    if (win->_clear) {
	/* 
	 * this isn't quite right - so removed for now
	 *
	 * consoleClearRect(win->_begy, win->_begx, 
	 *	 win->_begy + win->_maxy - 1,
	 *	 win->_begx + win->_maxx - 1);
	 */
	win->_clear = FALSE;
	/* 
	 * XXXdan decide how to deal with clearing
	 * should nuke that part of curscr and clear that rect of
	 * console
	 */
    }

    for (y=0, scry=win->_begy; y < win->_maxy; y++, scry++) {
	if (win->_minchng[y] != _NO_CHANGE) {
	    thepos = &(win->_line[y][win->_minchng[y]]);
	    endpos = &(win->_line[y][win->_maxchng[y]]);
	    scrx  = win->_minchng[y] + win->_begx;
	    scrpos = &(curscr->_line[scry][scrx]);

	    /* 
	     * copy line to screen keeping curscr up to date
	     */
	    while (thepos <= endpos) {
		/*
		 * curscr gets redrawn entirely, or if not, only the
		 * cells that are different from curscr's
		 */
		if ((win == curscr) || 
		    (sameNtcCell(thepos, scrpos) == FALSE)) 
		{
		    /*
		     * look at the attribute byte first
		     */
		    if (thepos->uniChar != VOID_CELL) {
			consoleSetCell(scry, scrx, thepos);
		    }
		    setNtcCell(scrpos, thepos);
		}
		thepos++;
		scrpos++;
		scrx++;
	    }
	    win->_minchng[y] = _NO_CHANGE;
	} 
	win->_maxchng[y] = _NO_CHANGE;
    }

    if (!win->_leavecurs) {
	mvcur(0, 0, win->_begy + win->_cury, win->_begx + win->_curx);
    }

} /* wrefresh */

/****************************************************************/
/* Refresh() updates stdscr's area of the physical screen.	*/
/****************************************************************/

void 
refresh(void)
{
    wrefresh(stdscr);
} /* refresh */
