/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		charins.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: charins.c,v 1.1 97/04/18 11:18:24 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Winsch() routine of the PCcurses package			*/
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
/* 1.1:	 Added 'raw' output routines (allows PC charac-		*/
/*	 ters < 0x20 to be displayed:			880306	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

char _curses_charins_rcsid[] = "@(#)charins.c    v.1.4  - 900114";

/****************************************************************/
/* _Chins() inserts character 'c' at the cursor position in	*/
/* window 'win'. If xlat is true, normal character translation	*/
/* is performed; If xlat is false, the character is output 'as	*/
/* is'.								*/
/****************************************************************/

static	int	
_chinsWide(WINDOW *win, ntcCell *c, bool xlat)
{
    ntcCell	*temp1;
    ntcCell	*temp2;
    ntcCell	*end;
    short	 x = win->_curx;
    short	 y = win->_cury;
    short	 maxx = win->_maxx - 1;
    unsigned char hb;	/* highbyte of c */
    unsigned char lb;	/* lowbyte of c */

    hb = (c->uniChar >> 8) & 0xff;
    lb = c->uniChar & 0xff;

    if((hb == 0) && (lb < ' ') && 
       (lb == '\n' || lb == '\r' || lb == '\t' || lb == '\b'))
	return(_chaddWide(win, c, xlat));

    end = &win->_line[y][x];
    temp1 = &win->_line[y][maxx];
    temp2 = temp1 - 1;
    if((hb == 0) && (lb < ' ') && xlat)	/* if CTRL-char make space for 2 */
	temp2--;
    while (temp1 > end) {
	setNtcCell(temp1, temp2);
	temp1--;
	temp2--;
    }
    win->_maxchng[y] = maxx;
    if ((win->_minchng[y] == _NO_CHANGE) || (win->_minchng[y] > x))
	win->_minchng[y] = x;
    return(_chaddWide(win,c,xlat));		/* fixes CTRL-chars too */
} /* _chins */

/****************************************************************/
/* Insch() inserts character 'c' at the cursor position in	*/
/* stdscr. The cursor is advanced.				*/
/****************************************************************/

int 
insch(char c)
{
    ntcCell temp;

    return(_chinsWide(stdscr, makeNtcCell(&temp, c), TRUE));
} /* insch */


int 
inschWide(ntcCell *ntc)
{
    return(_chinsWide(stdscr, ntc, TRUE));
} /* inschWide */

/****************************************************************/
/* Winsch() inserts character 'c' at the cursor position in	*/
/* window 'win'. The cursor is advanced.			*/
/****************************************************************/

int 
winsch(WINDOW *win, char c)
{
    ntcCell temp;

    return(_chinsWide(win, makeNtcCell(&temp, c), TRUE));
} /* winsch */

int 
winschWide(WINDOW *win, ntcCell *ntc)
{
    return(_chinsWide(win, ntc, TRUE));
} /* winschWide */

/****************************************************************/
/* Mvinsch() moves the stdscr cursor to a new position, then	*/
/* inserts character 'c' at the cursor position in stdscr. The	*/
/* cursor is advanced.						*/
/****************************************************************/

int 
mvinsch(int y, int x, char c)
{
    ntcCell temp;

    if (wmove(stdscr,y,x) == ERR)
	return(ERR);
    return(_chinsWide(stdscr, makeNtcCell(&temp, c), TRUE));
} /* mvinsch */

int 
mvinschWide(int y, int x, ntcCell *ntc)
{
    if (wmove(stdscr,y,x) == ERR)
	return(ERR);
    return(_chinsWide(stdscr, ntc,TRUE));
} /* mvinschWide */

/****************************************************************/
/* Mvwinsch() moves the cursor of window 'win' to a new posi-	*/
/* tion, then inserts character 'c' at the cursor position in	*/
/* window 'win'. The cursor is advanced.			*/
/****************************************************************/

int 
mvwinsch(WINDOW *win, int y, int x, char c)
{
    ntcCell temp;

    if (wmove(win,y,x) == ERR)
	return(ERR);

    return(_chinsWide(win, makeNtcCell(&temp, c), TRUE));
} /* mvwinsch */

int 
mvwinschWide(WINDOW *win, int y, int x, ntcCell *ntc)
{
    if (wmove(win,y,x) == ERR)
	return(ERR);

    return(_chinsWide(win, ntc, TRUE));
} /* mvwinschWide */

/****************************************************************/
/* Insrawch() inserts character 'c' at the cursor position in	*/
/* stdscr. Control characters are not interpreted, and the	*/
/* cursor is advanced.						*/
/****************************************************************/

int 
insrawch(char c)
{
    ntcCell temp;
    return(_chinsWide(stdscr, makeNtcCell(&temp, c), FALSE));
} /* insrawch */

int 
insrawchWide(ntcCell *ntc)
{
    return(_chinsWide(stdscr, ntc, FALSE));
} /* insrawchWide */

/****************************************************************/
/* Winsrawch() inserts character 'c' at the cursor position in	*/
/* window 'win'. Control characters are not interpreted, and	*/
/* the cursor is advanced.					*/
/****************************************************************/

int 
winsrawch(WINDOW *win, char c)
{
    ntcCell temp;

    return(_chinsWide(win, makeNtcCell(&temp, c), FALSE));
} /* winsrawch */

int 
winsrawchWide(WINDOW *win, ntcCell *ntc)
{
    return(_chinsWide(win, ntc, FALSE));
} /* winsrawchWide */

/****************************************************************/
/* Mvinsrawch() moves the stdscr cursor to a new position, then	*/
/* inserts character 'c' at the cursor position in stdscr.	*/
/* Control characters are not interpreted, and	the cursor is	*/
/* advanced.							*/
/****************************************************************/

int 
mvinsrawch(int y, int x, char c)
{
    ntcCell temp;

    if (wmove(stdscr,y,x) == ERR)
	return(ERR);

    return(_chinsWide(stdscr, makeNtcCell(&temp, c), FALSE));
} /* mvinsrawch */

int 
mvinsrawchWide(int y, int x, ntcCell *ntc)
{
    if (wmove(stdscr,y,x) == ERR)
	return(ERR);
    return(_chinsWide(stdscr, ntc, FALSE));
} /* mvinsrawchWide */

/****************************************************************/
/* Mvwinsrawch() moves the cursor of window 'win' to a new	*/
/* position, then inserts character 'c' at the cursor position	*/
/* in window 'win'. Control characters are not interpreted, and	*/
/* the cursor is advanced.					*/
/****************************************************************/

int 
mvwinsrawch(WINDOW *win, int y, int x, char c)
{
    ntcCell temp;
    if (wmove(win,y,x) == ERR)
	return(ERR);

    return(_chinsWide(win, makeNtcCell(&temp, c), FALSE));
} /* mvwinsrawch */

int 
mvwinsrawchWide(WINDOW *win, int y, int x, ntcCell *ntc)
{
    if (wmove(win,y,x) == ERR)
	return(ERR);

    return(_chinsWide(win, ntc, FALSE));
} /* mvwinsrawchWide */
