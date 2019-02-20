/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		overlay.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: overlay.c,v 1.1 97/04/18 11:22:42 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Overlay() and overwrite() functions of the PCcurses package	*/
/*								*/
/****************************************************************/
/* This version of curses is based on ncurses, a curses version	*/
/* originally written by Pavel Curtis at Cornell University.	*/
/* I have made substantial changes to make it run on IBM PC's,	*/
/* and therefore consider myself free to make it public domain.	*/
/*				Bjorn Larsson (bl@infovox.se)	*/
/****************************************************************/
/* 1.4:  Overlaying window will not line up with over-		*/
/*	 layed window's origin, but at it's 'own' origin	*/
/*	 relative to the overlayed's origin. Use of short	*/
/*	 wherever possible. Portability improvements:	900114	*/
/* 1.3:	 MSC -W3, Turbo'C' -w -w-pro checks:		881005	*/
/* 1.2:	 Max limits off by 1. Fixed thanks to S. Creps:	881002	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

char _curses_overlay_rcsid[] = "@(#)overlay.c    v.1.4  - 900114";

/****************************************************************/
/* Overlay() overwrites 'win1' upon 'win2', with 'win1' appea-	*/
/* ring in 'win2' at it own origin relative to 'win2's origin.	*/
/* This is a departure, but a desirable one, from the initial	*/
/* definition of this function. Overlay is transparent; blanks	*/
/* from 'win1' are not copied to 'win2'.			*/
/****************************************************************/

void 
overlay(WINDOW *win1, WINDOW *win2)
{
    short		*minchng;
    short		*maxchng;
    ntcCell		*w1ptr;
    ntcCell		*w2ptr;
    short		 col;
    short		 line;
    short		 last_line;
    short		 last_col;

    last_col = min(win1->_maxx + win1->_begx, win2->_maxx) - 1;
    last_line = min(win1->_maxy + win1->_begy, win2->_maxy) - 1;
    minchng = win2->_minchng + win1->_begy;
    maxchng = win2->_maxchng + win1->_begy;
    
    for(line = win1->_begy;  line <= last_line;  line++) {
	register short   fc, lc;
	
	w1ptr = win1->_line[line - win1->_begy];
	w2ptr = win2->_line[line] + win1->_begx;
	fc = _NO_CHANGE;
	
	for(col = win1->_begx;  col <= last_col;  col++) {
	    if (w1ptr->uniChar != ' ') {
		setNtcCell(w2ptr, w1ptr);
		if (win2->_flags & _STANDOUT) {
		    (void *)hilight(w2ptr);
		}
		if (fc == _NO_CHANGE)
		    fc = col;
		lc = col;
	    }
	    w1ptr++;
	    w2ptr++;
	}
	
	if (*minchng == _NO_CHANGE) {
	    *minchng = fc;
	    *maxchng = lc;
	} else {
	    if (fc != _NO_CHANGE) {
		if (fc < *minchng)
		    *minchng = fc;
		if (lc > *maxchng)
		    *maxchng = lc;
	    }
	}
	minchng++;
	maxchng++;
    }
} /* overlay */

/****************************************************************/
/* Overwrite() overwrites 'win1' upon 'win2', with 'win1' ap-	*/
/* pearing in 'win2' at it own origin relative to 'win2's ori-	*/
/* gin. This is a departure, but a desirable one, from the	*/
/* initial definition of this function. Overwrite is non-trans-	*/
/* parent; blanks from 'win1' are copied to 'win2'.		*/
/****************************************************************/

void	
overwrite(WINDOW *win1, WINDOW *win2)
{
    short		*minchng;
    short		*maxchng;
    ntcCell		*w1ptr;
    ntcCell		*w2ptr;
    short		 col;
    short		 line;
    short		 last_line;
    short		 last_col;
    
    last_col = min(win1->_maxx + win1->_begx, win2->_maxx) - 1;
    last_line = min(win1->_maxy + win1->_begy, win2->_maxy) - 1;
    minchng = win2->_minchng + win1->_begy;
    maxchng = win2->_maxchng + win1->_begy;
    
    for(line = win1->_begy;  line <= last_line;  line++) {
	register short   fc, lc;
	
	w1ptr = win1->_line[line - win1->_begy];
	w2ptr = win2->_line[line] + win1->_begx;
	fc = _NO_CHANGE;
	
	for(col = win1->_begx;  col <= last_col;  col++) {
	    if (w1ptr->uniChar != w2ptr->uniChar) {
		setNtcCell(w2ptr, w1ptr);
		if (win2->_flags & _STANDOUT) {
		    (void *)hilight(w2ptr);
		}
		if (fc == _NO_CHANGE)
		    fc = col;
		lc = col;
	    }
	    w1ptr++;
	    w2ptr++;
	}
	
	if (*minchng == _NO_CHANGE) {
	    *minchng = fc;
	    *maxchng = lc;
	} else {
	    if (fc != _NO_CHANGE) {
		if (fc < *minchng)
		    *minchng = fc;
		if (lc > *maxchng)
		    *maxchng = lc;
	    }
	}
	minchng++;
	maxchng++;
    }
} /* overwrite */
