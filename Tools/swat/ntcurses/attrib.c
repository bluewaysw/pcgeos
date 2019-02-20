/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		attrib.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: attrib.c,v 1.1 97/04/18 11:17:03 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Character attribute routines of the PCcurses package		*/
/*								*/
/****************************************************************/
/* This version of curses is based on ncurses, a curses version	*/
/* originally written by Pavel Curtis at Cornell University.	*/
/* I have made substantial changes to make it run on IBM PC's,	*/
/* and therefore consider myself free make it public domain.	*/
/*				Bjorn Larsson (bl@infovox.se)	*/
/****************************************************************/
/* 1.4:  Portability improvements:			900114	*/
/* 1.3:	 MSC -W3, Turbo'C' -w -w-pro checkes:		881005	*/
/* 1.2:	 Rcsid[] string for maintenance:		881002	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

char _curses_attrib_rcsid[] = "@(#)attrib.c     v.1.4  - 900114";

/****************************************************************/
/* Wstandout() starts standout mode in window 'win'.		*/
/****************************************************************/

void	
wstandout(WINDOW *win)
{
    win->_flags |= _STANDOUT;
} /* wstandout */

/****************************************************************/
/* Wstandend() ends standout mode in window 'win'.		*/
/****************************************************************/

void	
wstandend(WINDOW *win)
{
    win->_flags &= ~_STANDOUT;
} /* wstandend */

/****************************************************************/
/* Standout() starts standout mode  in stdscr.	        	*/
/****************************************************************/

void	
standout(void)
{
    wstandout(stdscr);
} /* standout */

/****************************************************************/
/* Standend() ends standout mode in stdscr			*/
/****************************************************************/

void	
standend(void)
{
    wstandend(stdscr);
} /* standend */
