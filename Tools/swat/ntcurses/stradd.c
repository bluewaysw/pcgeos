/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		stradd.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: stradd.c,v 1.1 97/04/18 11:23:54 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Addstr() routines of the PCcurses package                   */
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

char _curses_stradd_rcsid[] = "@(#)stradd.c     v.1.4  - 900114";

/****************************************************************/
/* Waddstr() inserts string 'str' at the current cursor posi-  */
/* tion in window 'win', and takes any actions as dictated by  */
/* the characters.                                             */
/****************************************************************/

int    
waddstr(WINDOW *win, unsigned char *str)
{
    while (*str) {
	if (waddch(win, *str++) == ERR)
	    return(ERR);
    }
    return(OK);
} /* waddstr */

int    
waddstrWide(WINDOW *win, ntcCell *str)
{
    while (str->uniChar != '\0') {
	if (waddchWide(win, str++) == ERR)
	    return(ERR);
    }
    return(OK);
} /* waddstr */

/****************************************************************/
/* Addstr() inserts string 'str' at the current cursor posi-   */
/* tion in stdscr, and takes any actions as dictated by the    */
/* characters.                                                 */
/****************************************************************/

int 
addstr(unsigned char *str)
{
    return (waddstr(stdscr,str));
} /* addstr */

int 
addstrWide(ntcCell *str)
{
    return (waddstrWide(stdscr,str));
} /* addstrWide */

/****************************************************************/
/* Mvaddstr() move to a new position in stdscr, then inserts   */
/* string 'str' at the new position, taking any actions as dic-        */
/* tated by the characters.                                    */
/****************************************************************/

int 
mvaddstr(int y, int x, unsigned char *str)
{
    if (wmove(stdscr,y,x) == ERR)
	return (ERR);
    return (waddstr(stdscr,str));
} /* mvaddstr */

int 
mvaddstrWide(int y, int x, ntcCell *str)
{
    if (wmove(stdscr,y,x) == ERR)
	return (ERR);
    return (waddstrWide(stdscr,str));
} /* mvaddstrWide */

/****************************************************************/
/* Mvwaddstr() move to a new position in window 'win', then    */
/* inserts string 'str' at the new position, taking any actions        */
/* as dictated by the characters.                              */
/****************************************************************/

int 
mvwaddstr(WINDOW *win, int y, int x, unsigned char *str)
{
    if (wmove(win,y,x) == ERR)
	return (ERR);
    return (waddstr(win,str));
} /* mvwaddstr */

int 
mvwaddstrWide(WINDOW *win, int y, int x, ntcCell *str)
{
    if (wmove(win,y,x) == ERR)
	return (ERR);
    return (waddstrWide(win,str));
} /* mvwaddstrWide */
