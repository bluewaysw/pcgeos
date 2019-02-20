/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		charadd.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: charadd.c,v 1.1 97/04/18 11:17:42 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Addch() routines of the PCcurses package			*/
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
/* 1.1:	 Added 'raw' output routines (allows PC charac-		*/
/*	 ters < 0x20 to be displayed:			880306	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

#include <curses.h>
#include <curspriv.h>
char _curses_charadd_rcsid[] = "@(#)charadd.c    v.1.4  - 900114";

/****************************************************************/
/* Newline() does line advance and returns the new cursor line.	*/
/* If error, return -1.						*/
/****************************************************************/

static	short	
newline(WINDOW *win, short lin)
{
    if (++lin > (win->_maxy - 1)) {
	lin--;
	if (win->_scroll) {
	    scroll(win);
	} else {
	    return(-1);
	}
    }
    return(lin);
  } /* newline */

/****************************************************************/
/* _chaddWide() inserts character 'c' at the current cursor posi*/
/* tion in window 'win'. If xlat is TRUE, _chaddWide() will handle*/
/* things like tab, newline, cr etc.; otherwise the character	*/
/* is simply output.						*/
/****************************************************************/

int 
_chaddWide(register WINDOW *win, ntcCell *c, bool xlat)
{
    short	x = win->_curx;
    short	y = win->_cury;
    short	newx;
    ntcCell 	ch, temp;
    short	ts = win->_tabsize;

    setNtcCell(&ch, c);

    if (y >= win->_maxy  ||  x >= win->_maxx  ||  y < 0  ||  x < 0) {
	return(ERR);
    }

    if (xlat) {
	switch (ch.uniChar) {
	case '\t':
	    for (newx = ((x/ts) + 1) * ts; x < newx; x++) {
		if (waddch(win, ' ') == ERR)
		    return(ERR);
		if (win->_curx == 0)	/* if tab to next line */
		    return(OK);		/* exit the loop */
	    }
	    return(OK);
	case '\n':  
	    /* 
	     * if lf -> crlf 
	     */
	    if (_cursvar.autocr && !(_cursvar.raw)) {
		x = 0;
	    }
	    if ((y = newline(win, y)) < 0) {
		return(ERR);
	    }
	    win->_cury = y;
	    win->_curx = x;
	    return(OK);
	case '\r':  
	    x = 0;
	    win->_curx = x;
	    return(OK);
	case '\b':  
	    /* 
	     * no back over left margin 
	     */
	    if (--x < 0) {
		x = 0;
	    }
	    win->_curx = x;
	    return(OK);
	case 0x7f:  
	    if (waddch(win, '^') == ERR) {
		return(ERR);
	    }
	    return(waddch(win, '?'));
	default:
	    break;
	}  /* switch */
	/* 
	 * handle control chars 
	 */
	if (ch.uniChar < ' ') {
	    if (waddch(win,'^') == ERR) {
		return(ERR);
	    }
	    return(waddchWide(win, makeNtcCell(&temp, c->uniChar + '@')));
	}
    }   /* if xlat*/
    
    if (win->_flags & _STANDOUT) {
	(void *)hilight(&ch);
    }

    /* 
     * only if data change 
     */
    if (sameNtcCell(&win->_line[y][x], &ch) == FALSE) {
	if (win->_minchng[y] == _NO_CHANGE) {
	    win->_minchng[y] = win->_maxchng[y] = x;
	} else {
	    if (x < win->_minchng[y]) {
		win->_minchng[y] = x;
	    } else {
		if (x > win->_maxchng[y]) {
		    win->_maxchng[y] = x;
		}
	    }
	}
    }
    setNtcCell(&win->_line[y][x], &ch);
    x++;

    /* 
     * wrap around test 
     */
    if (x >= win->_maxx) {
	x = 0;
	if ((y = newline(win, y)) < 0) {
	    return(ERR);
	}
    }

    win->_curx = x;
    win->_cury = y;

    return(OK);
} /* _chaddWide */

/****************************************************************/
/* Addch() inserts character 'c' at the current cursor posi-	*/
/* tion in stdscr, and takes any actions as dictated by the	*/
/* character.							*/
/****************************************************************/

int 
addch(unsigned char c)
{
    ntcCell temp;

    return (_chaddWide(stdscr, makeNtcCell(&temp, c), TRUE));
} /* addch */

int 
addchWide(ntcCell *c)
{
    return (_chaddWide(stdscr, c, TRUE));
} /* addch */

/****************************************************************/
/* Waddch() inserts character 'c' at the current cursor posi-	*/
/* tion in window 'win', and takes any actions as dictated by	*/
/* the character.						*/
/****************************************************************/

int 
waddch(WINDOW *win, unsigned char c)
{
    ntcCell temp;

    return (_chaddWide(win, makeNtcCell(&temp, c), TRUE));
} /* waddch */

int 
waddchWide(WINDOW *win, ntcCell *c)
{
    return (_chaddWide(win,c,TRUE));
} /* waddch */

/****************************************************************/
/* Mvaddch() moves to position in stdscr, then inserts charac-	*/
/* ter 'c' at that point, and takes any actions as dictated by	*/
/* the character.						*/
/****************************************************************/

int 
mvaddch(int x, int y, unsigned char c)
{
    ntcCell temp;

    if (wmove(stdscr,y,x) == ERR) {
	return(ERR);
    }

    return (_chaddWide(stdscr, makeNtcCell(&temp, c), TRUE));
} /* mvaddch */

int 
mvaddchWide(int x, int y, ntcCell *c)
{
    if (wmove(stdscr,y,x) == ERR) {
	return(ERR);
    }
    return (_chaddWide(stdscr,c,TRUE));
} /* mvaddch */

/****************************************************************/
/* Mvwaddch() moves to position in window 'win', then inserts	*/
/* character 'c' at that point in the window, and takes any	*/
/* actions as dictated by the character.			*/
/****************************************************************/

int 
mvwaddch(WINDOW *win, int x, int y, unsigned char c)
{
    ntcCell temp;

    if (wmove(win,y,x) == ERR) {
	return(ERR);
    }

    return (_chaddWide(win, makeNtcCell(&temp, c), TRUE));
} /* mvwaddch */


int 
mvwaddchWide(WINDOW *win, int x, int y, ntcCell *c)
{
    if (wmove(win,y,x) == ERR) {
	return(ERR);
    }
    return (_chaddWide(win,c,TRUE));
} /* mvwaddch */

/****************************************************************/
/* Addrawch() inserts character 'c' at the current cursor	*/
/* position in stdscr, disregarding any traditional interpre-	*/
/* tation of the character.					*/
/****************************************************************/

int 
addrawch(unsigned char c)
{
    ntcCell temp;

    return (_chaddWide(stdscr, makeNtcCell(&temp, c), TRUE));
} /* addrawch */

int 
addrawchWide(ntcCell *c)
{
    return (_chaddWide(stdscr,c,FALSE));
} /* addrawch */

/****************************************************************/
/* Waddrawch() inserts character 'c' at the current cursor	*/
/* position in window 'win', disregarding any traditional in-	*/
/* terpretation of the character.				*/
/****************************************************************/

int 
waddrawch(WINDOW *win, unsigned char c)
{
    ntcCell temp;

    return (_chaddWide(win, makeNtcCell(&temp, c), FALSE));
} /* waddrawch */

int 
waddrawchWide(WINDOW *win, ntcCell *c)
{
    return (_chaddWide(win,c,FALSE));
} /* waddrawch */

/****************************************************************/
/* Mvaddrawch() moves to position in stdscr, then inserts cha-	*/
/* racter 'c' at that point, disregarding any traditional in-	*/
/* terpretation of the character.				*/
/****************************************************************/

int 
mvaddrawch(int x, int y, unsigned char c)
{
    ntcCell temp;

    if (wmove(stdscr,y,x) == ERR) {
	return(ERR);
    }
    return (_chaddWide(stdscr, makeNtcCell(&temp, c), FALSE));
} /* mvaddrawch */

int 
mvaddrawchWide(int x, int y, ntcCell *c)
{
    if (wmove(stdscr,y,x) == ERR) {
	return(ERR);
    }
    return (_chaddWide(stdscr,c,FALSE));
} /* mvaddrawch */

/****************************************************************/
/* Mvwaddrawch() moves to position in window 'win', then in-	*/
/* serts character 'c' at that point in the window, disregar-	*/
/* ding any traditional interpretation of the character.	*/
/****************************************************************/

int 
mvwaddrawch(WINDOW *win, int x, int y, unsigned char c)
{
    ntcCell temp;

    if (wmove(win,y,x) == ERR) {
	return(ERR);
    }

    return (_chaddWide(win, makeNtcCell(&temp, c), FALSE));
} /* mvwaddrawch */

int 
mvwaddrawchWide(WINDOW *win, int x, int y, ntcCell *c)
{
    if (wmove(win,y,x) == ERR) {
	return(ERR);
    }
    return (_chaddWide(win,c,FALSE));
} /* mvwaddrawch */
