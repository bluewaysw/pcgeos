/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		setterm.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: setterm.c,v 1.1 97/04/18 11:23:40 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Raw(), noraw(), echo(), noecho(), nl(), nonl(),  cbreak(),	*/
/* nocbreak(), crmode(), nocrmode() and refrbrk() routines of	*/
/* the PCcurses package.					*/
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
/* 1.2:	 Rcsid[] string for maintenance:		881002	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

char _curses_setterm_rcsid[] = "@(#)setterm.c    v.1.4  - 900114";

/****************************************************************/
/* Raw() and noraw() sets or clears raw mode.			*/
/****************************************************************/

void  
raw(void)
{
    _cursvar.raw = TRUE;
    consoleScb(FALSE);			/* disallow ^BREAK on disk I/O */
    flushinp();
} /* raw */

void  
noraw(void)
{
    _cursvar.raw = FALSE;
    consoleScb(_cursvar.orgcbr);	/* restore original ^BREAK status */
} /* noraw */

/****************************************************************/
/* Echo() and noecho() sets or clears echo mode.		*/
/****************************************************************/

void  
echo(void)
{
    _cursvar.echo = TRUE;
} /* echo */

void  
noecho(void)
{
    _cursvar.echo = FALSE;
} /* noecho */

/****************************************************************/
/* Nl() and nonl() sets or clears autocr mapping mode.		*/
/****************************************************************/

void  
nl(void)
{
    _cursvar.autocr = TRUE;
} /* nl */

void  
nonl(void)
{
    _cursvar.autocr = FALSE;
} /* nonl */

/****************************************************************/
/* Cbreak(), nocbreak(), crmode() amd nocrmode()  sets or	*/
/* clears cbreak mode.						*/
/****************************************************************/

void  
cbreak(void)
{
    _cursvar.cbreak = TRUE;
} /* cbreak */

void  
nocbreak(void)
{
    _cursvar.cbreak = FALSE;
} /* nocbreak */

void  
crmode(void)
{
    _cursvar.cbreak = TRUE;
} /* crmode */

void  
nocrmode(void)
{
    _cursvar.cbreak = FALSE;
} /* nocrmode */

/****************************************************************/
/* Refrbrk() sets or unsets the screen refresh break flag. If	*/
/* this flag is set, and there is any input available, any	*/
/* screen refresh will be prematurely terminated, anticipating	*/
/* more screen updates. This flag is FALSE by default.		*/
/****************************************************************/

void	
refrbrk(bool bf)
{
    _cursvar.refrbrk = bf;
} /* refrbrk */
