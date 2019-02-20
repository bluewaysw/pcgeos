/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS	
MODULE:		swat - ntcurses
FILE:		beep.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: beep.c,v 1.1 97/04/18 11:17:27 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/*                                                             */
/* Beep() and flash() routines of the PCcurses package         */
/*                                                             */
/****************************************************************/
/* This version of curses is based on ncurses, a curses version        */
/* originally written by Pavel Curtis at Cornell University.   */
/* I have made substantial changes to make it run on IBM PC's, */
/* and therefore consider myself free to make it public domain.        */
/*                             Bjorn Larsson (bl@infovox.se)   */
/****************************************************************/
/* 1.4:  Use short wherever possible. Portability              */
/*      improvements:                                  900114  */
/* 1.3:         MSC -W3, Turbo'C' -w -w-pro checkes:           881005  */
/* 1.2:         Rcsid[] string for maintenance:                881002  */
/* 1.0:         Release:                                       870515  */
/****************************************************************/

#include <windows.h>
#include "curses.h"
#include "curspriv.h"

char _curses_beep_rcsid[] = "@(#)beep.c       v.1.4  - 900114";

/****************************************************************/
/* Beep() sounds the terminal bell.                            */
/****************************************************************/

void   
beep(void)
{
    consoleBeep();
} /* beep */

/****************************************************************/
/* Flash() flashes the terminal screen.                         */
/****************************************************************/

void   
flash(void)
{
    consoleFlash();
} /* flash */
