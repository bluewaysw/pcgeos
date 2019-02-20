/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		strget.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: strget.c,v 1.1 97/04/18 11:24:09 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Getstr() routines of the PCcurses package			*/
/*								*/
/****************************************************************/
/* This version of curses is based on ncurses, a curses version	*/
/* originally written by Pavel Curtis at Cornell University.	*/
/* I have made substantial changes to make it run on IBM PC's,	*/
/* and therefore consider myself free to make it public domain.	*/
/*				Bjorn Larsson (bl@infovox.se)	*/
/****************************************************************/
/* 1.4:  Use of short wherever possible. Portability		*/
/*	 improvements, echo bug, fix for signed character	*/
/*	 (for 8-bit ASCII):				900114	*/
/* 1.3:	 MSC -W3, Turbo'C' -w -w-pro checkes:		881005	*/
/* 1.2:	 Max limits of by 1. Block nest error in function	*/
/*	 backchar(). Fixed thanks to S. Creps:		881002	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

static	char	*backchar(char *s);

char _curses_strget_rcsid[] = "@(#)strget.c     v.1.4  - 900114";

static	bool	 oldecho;
static	bool	 oldcbreak;
static  bool     oldnodelay;
static	char	*strbeg;
static	WINDOW  *w;
static	short	 xbeg;

/****************************************************************/
/* Wgetstr(win,str) reads in a string (terminated by \n or \r)	*/
/* to the buffer pointed to by 'str', and displays the input	*/
/* in window 'win'. The user's erase and kill characters are	*/
/* active.							*/
/****************************************************************/

int 
wgetstr(WINDOW *win, char *str)
{
    w		  = win;
    strbeg	  = str;		/* keep start for backspacing */
    oldcbreak       = _cursvar.cbreak;	/* remember states */
    oldecho         = _cursvar.echo;
    oldnodelay      = w->_nodelay;
    _cursvar.echo   = FALSE;		/* we do echo ourselves */
    _cursvar.cbreak = TRUE;		/* no wait for chars */
    w->_nodelay   = FALSE;		/* don't return 'NOCHARS' */
    xbeg = w->_curx;			/* remember screen start x-position */
    
    wrefresh(w);			/* sets cursor at right place */
    while ((*str = (char) getch()) != '\n') {
	if (*str == '\r')
	    break;
	if (*str == _DCCHAR) {
	    if (str > strbeg) {
		str = backchar(str);
	    }
	} else {
	    if (*str == _DLCHAR) {
		while (str > strbeg)
		    str = backchar(str);
	    } else {
		if (oldecho) {			/* check if echo */
		    waddch(w,*str++);
		    wrefresh(w);
		} else {
		    str++;
		}
	    }
	}
    }
    
    waddch(w,'\n');
    wrefresh(w);
    
    *str = '\0';
    _cursvar.echo   = oldecho;
    _cursvar.cbreak = oldcbreak;
    win->_nodelay   = oldnodelay;
    return(OK);
} /* wgetstr */

/****************************************************************/
/* Getstr(str) reads in a string (terminated by \n or \r) to	*/
/* the buffer pointed to by 'str', and displays the input in	*/
/* stdscr. The user's erase and kill characters are active.	*/
/****************************************************************/

int 
getstr(char *str)
{
    return(wgetstr(stdscr,str));
} /* getstr */

/****************************************************************/
/* Mvgetstr(y,x,str) moves the stdscr cursor to a new position,	*/
/* then reads in a string (terminated by \n or \r) to the buf-	*/
/* fer pointed to by 'str', and displays the input in stdscr.	*/
/* The user's erase and kill characters are active.		*/
/****************************************************************/

int 
mvgetstr(int y, int x, char *str)
{
    if (wmove(stdscr,y,x) == ERR)
	return(ERR);
    return(wgetstr(stdscr,str));
} /* mvgetstr */

/****************************************************************/
/* Mvwgetstr(win,y,x,str) moves the 'win' cursor to a new	*/
/* position, then reads in a string (terminated by \n or \r)	*/
/* to the buffer pointed to by 'str', and displays the input in	*/
/* stdscr. The user's erase and kill characters are active.	*/
/****************************************************************/

int 
mvwgetstr(WINDOW *win, int y, int x, char *str)
{
    if (wmove(win,y,x) == ERR)
	return(ERR);
    return(wgetstr(win,str));
} /* mvwgetstr */

/****************************************************************/
/* Backchar() does a character delete with screen erase, even	*/
/* up to previous lines. It will not back-scroll if the begi-	*/
/* ning of the string has scrolled off the window. Steps back	*/
/* pointer 's', and returns the new value.			*/
/****************************************************************/

static char *backchar(char *s)
{
    static short nbs;
    static short x;
    static char *p;
    static short ts;
    
    x =  xbeg;
    ts =  w->_tabsize;
    
    s--;						/* step back string */
    nbs = 1;					/* step at least one pos */
    if (((*s & 0xe0) == 0) || (*s == 0x7f))	/* ctrl-char has size 2 */
	nbs++;
    if (*s == '\t') {				/* tabs are very special */
	for (p = strbeg; p < s ;p++) {	/* find x-pos of last char */
	    if (*p == '\t')			/* go to next tab */
		x = ((x/ts)+1) * ts;
	    else {
		/* control character */
		if (((*p & 0xe0) == 0) || (*p == 0x7f))
		    x += 2;
		else				/* normal char */
		    x++;
	    } /* else */
	    if (x >= w->_maxx)			/* go to next line? */
		x = 0;
	} /* for */
	if (!(w->_curx))			/* if step-over newline */
	    nbs = w->_maxx - x;
	else					/* in-line tab */
	    nbs = w->_curx - x;			/* positions to erase */
    } /* if */
    
    if ((int) oldecho) {			/* check if echo */
	while(nbs--) {				/* do so many */
	    if (w->_curx > 0)			/* if not at line beginning */
		waddstr(w,(unsigned char *)"\b \b");
	    else
		if (w->_cury) {			/* if not on top line */
		    /* put space at line end */
		    mvwaddch(w,w->_cury-1,w->_maxx -1,' ');
		    /* and go there again */
		    wmove(w,w->_cury-1,w->_maxx - 1);
		} /* else */
	} /* while */
	wrefresh(w);				/* redraw screen */
    }
    *(s+1) = '\0';				/* make string terminated */
    return(s);
} /* backchar */
