/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		initscr.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: initscr.c,v 1.1 97/04/18 11:20:06 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Initscr() routine of the PCcurses package                   */
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
/* 1.1:         Revision string in the code:                   880306  */
/* 1.0:         Release:                                       870515  */
/****************************************************************/

#include "curses.h"
#include "curspriv.h"

#include <windows.h>
#include <stdlib.h>
#include <dos.h>
#include <stdio.h>

char _curses_initscr_rcsid[] = "@(#)initscr.c    v.1.4  - 900114";
char _curses_revcod[] =  CURSES_RCS_ID;
char _curses_cpyrgt[] = "Author B. Larsson - Public Domain";

WINDOW *curscr;                        /* the current screen image */
WINDOW *stdscr;                        /* the default screen window */

cursv   _cursvar;              /* curses variables */
int    LINES;                  /* terminal height */
int    COLS;		       /* terminal width */

HANDLE hConIn = NULL;
HANDLE hConOut = NULL;

void 
Initscr_PrepConsole(void) 
{
    DWORD dwMode;

    hConOut = CreateFile("CONOUT$", GENERIC_READ | GENERIC_WRITE,
			 FILE_SHARE_READ | FILE_SHARE_WRITE,
			 NULL, OPEN_EXISTING, 0, NULL);
    if (hConOut == INVALID_HANDLE_VALUE) {
	printf("problem creating hconout\n");
    }
    
    hConIn = CreateFile("CONIN$", GENERIC_READ | GENERIC_WRITE,
			FILE_SHARE_READ | FILE_SHARE_WRITE,
			NULL, OPEN_EXISTING, 0, NULL);
    if (hConIn == INVALID_HANDLE_VALUE) {
	printf("problem creating hconin\n");
    }
    
    if (GetConsoleMode(hConOut, &dwMode)) {
	dwMode &= ~ENABLE_WRAP_AT_EOL_OUTPUT;
	SetConsoleMode(hConOut, dwMode);
    }

    if (GetConsoleMode(hConIn, &dwMode)) {
	dwMode &= ~ENABLE_LINE_INPUT;
        dwMode &= ~ENABLE_ECHO_INPUT;
	dwMode &= ~ENABLE_WINDOW_INPUT;
	dwMode |= ENABLE_MOUSE_INPUT;
	SetConsoleMode(hConIn, dwMode);
    }
}

int 
InitscrGetLines(void)
{
    CONSOLE_SCREEN_BUFFER_INFO csInfo;
    BOOL returnCode;

    returnCode = GetConsoleScreenBufferInfo(hConOut, &csInfo);
    if (returnCode == FALSE) {
	fprintf(stderr,"error=%d\n", GetLastError());
	return (0);
    }
    return (csInfo.dwSize.Y);
}

int 
InitscrGetCols(void)
{
    CONSOLE_SCREEN_BUFFER_INFO csInfo;
    BOOL returnCode;

    returnCode = GetConsoleScreenBufferInfo(hConOut, &csInfo);
    if (returnCode == FALSE) {
	fprintf(stderr, "error=%d\n", GetLastError());
	return (0);
    }
    return (csInfo.dwSize.X); 
}

/****************************************************************/
/* Initscr() does neccessary initializations for the PCcurses  */
/* package. It MUST be called before any other curses routines.	       */
/****************************************************************/

int 
initscr(void)
{
    _cursvar.cursrow   = -1;	       /* Initial cursor unknown */
    _cursvar.curscol   = -1;
    _cursvar.autocr    = TRUE;		 /* lf -> crlf by default */
    _cursvar.raw       = FALSE;		 /* tty I/O modes */
    _cursvar.cbreak    = FALSE;
    _cursvar.echo      = TRUE;
    _cursvar.refrbrk   = FALSE;		 /* no premature end of refresh */
    _cursvar.orgcbr    = (bool)consoleGcb();/* original ^BREAK setting */

    Initscr_PrepConsole();
    LINES = InitscrGetLines();
    COLS = InitscrGetCols();

    if ((curscr = newwin(LINES,COLS,0,0)) == (WINDOW *)ERR) {
	exit(1);
    }
    if ((stdscr = newwin(LINES,COLS,0,0)) == (WINDOW *)ERR) {
	exit(1);
    }
    curscr->_clear = FALSE;
    consoleClearRect(0, 0, LINES - 1, COLS - 1);
    return(OK);
  } /* initscr */
