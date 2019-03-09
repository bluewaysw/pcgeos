/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		setmode.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: setmode.c,v 1.1 97/04/18 11:23:26 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Terminal mode routines of the PCcurses package.		*/
/*								*/
/****************************************************************/
/* This version of curses is based on ncurses, a curses version	*/
/* originally written by Pavel Curtis at Cornell University.	*/
/* I have made substantial changes to make it run on IBM PC's,	*/
/* and therefore consider myself free make it public domain.	*/
/*				Bjorn Larsson (bl@infovox.se)	*/
/****************************************************************/
/* BUT: this particualr module was written by			*/
/*	N. Dean Pentcheff  (dean@violet.berkeley.edu)		*/
/* It provides PC Curses versions of:				*/
/*	reset_prog_mode();					*/
/*	reset_shell_mode();					*/
/*	set_prog_mode();					*/
/*	set_shell_mode();					*/
/*								*/
/* B. Larsson took the liberty to mofify it's style slightly	*/
/* when incorporating it into PCcurses v.1.2. The routines in	*/
/* this module do a similar thing to savetty() and resetty().	*/
/****************************************************************/
/* 1.4:  Use of short wherever possible. Portability		*/
/*	 improvements:					900114	*/
/* 1.3:	 MSC -W3, Turbo'C' -w -w-pro checkes:		881005	*/
/* 1.2:	 Style clean-up, rcsid[] string for main-		*/
/*	 tenance:					881002	*/
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

struct cttyset
{
    bool	been_set;
    bool	oautocr;
    bool	ocbreak;
    bool	oecho;
    bool	oraw;
};

char _curses_setmode_rcsid[] = "@(#)setmode.c    v.1.4  - 900114";

static	struct cttyset pr_tty = {FALSE};/* tty modes for prog_mode  */

/****************************************************************/
/* Def_prog_mode() saves the current tty status, to be recalled	*/
/* later by reset_prog_mode.					*/
/****************************************************************/

void def_prog_mode()
{
    pr_tty.been_set = TRUE;
    pr_tty.oautocr = _cursvar.autocr;
    pr_tty.ocbreak = _cursvar.cbreak;
    pr_tty.oecho	= _cursvar.echo;
    pr_tty.oraw	= _cursvar.raw;
} /* def_prog_mode */

/****************************************************************/
/* Reset_prog_mode() resets tty modes to the values saved in a	*/
/* call to def_prog_mode.					*/
/****************************************************************/

void reset_prog_mode()
{
    if (pr_tty.been_set == TRUE)
	{
	    _cursvar.autocr	= pr_tty.oautocr;
	    _cursvar.cbreak	= pr_tty.ocbreak;
	    _cursvar.echo	= pr_tty.oecho;
	    _cursvar.raw	= pr_tty.oraw;
	} /* if */
} /* reset_prog_mode */

/****************************************************************/
/* Def_shell_mode() saves the tty status, to be recalled by	*/
/* reset_shell_mode. A noop in PCcurses.			*/
/****************************************************************/

void def_shell_mode()
{
} /* def_shell_mode */

/****************************************************************/
/* Reset_shell_mode() resets the tty status to the status it	*/
/* had before curses began.					*/
/****************************************************************/

void reset_shell_mode()
{
    _cursvar.autocr	= TRUE;
    _cursvar.cbreak	= FALSE;
    _cursvar.echo	= TRUE;
    _cursvar.raw	= FALSE;
} /* reset_shell_mode */
