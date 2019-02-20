/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		termmisc.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: termmisc.c,v 1.1 97/04/18 11:24:37 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Miscellaneous Terminal routines of the PCcurses package     */
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

/* static variables or saving terminal modes */

char _curses_termmisc_rcsid[] = "@(#)termmisc.c   v.1.4  - 900114";

static bool savedacr;
static bool savedcbr;
static bool savedecho;
static bool savedraw;

/****************************************************************/
/* Fixterm(), resetterm(), saveoldterm, saveterm() gettmode(), */
/* setterm() and baudrate() function dummies for compatibility.        */
/****************************************************************/

int 
fixterm(void)
{
    return(OK);
} /* fixterm */

int 
resetterm(void)
{
    return(OK);
}

int 
saveoldterm(void)
{
    return(OK);
} /* saveoldterm */

int 
saveterm(void)
{
    return(OK);
} /* saveterm */

int 
gettmode(void)
{
    return(OK);
} /* gettmode */

int 
setterm(void)
{
    return(OK);
} /* setterm */

int 
baudrate(void)
{
    return(19200);
} /* baudrate */

/****************************************************************/
/* Erasechar(), killchar() returns std MSDOS erase chars.      */
/****************************************************************/

int 
erasechar(void)
{
    return(_DCCHAR);             /* character delete char */
} /* erasechar */

int 
killchar(void)
{
    return(_DLCHAR);             /* line delete char */
} /* killchar */

/****************************************************************/
/* Savetty() and resetty() saves and restores the terminal I/O */
/* settings.                                                   */
/****************************************************************/

int 
savetty(void)
{
    savedacr  = _cursvar.autocr;
    savedcbr  = _cursvar.cbreak;
    savedecho = _cursvar.echo;
    savedraw  = _cursvar.raw;
    return(OK);
} /* savetty */

int 
resetty(void)
{
    _cursvar.autocr = savedacr;
    _cursvar.cbreak = savedcbr;
    _cursvar.echo   = savedecho;
    _cursvar.raw    = savedraw;
    return(OK);
} /* resetty */

/****************************************************************/
/* Setupterm() sets up the terminal. On a PC, it is always suc-        */
/* cessful, and returns 1.                                     */
/****************************************************************/

int 
setupterm(void)
{
    return(1);
} /* setupterm */
