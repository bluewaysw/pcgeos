/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		charget.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: charget.c,v 1.1 97/04/18 11:18:09 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Getch() routines of the PCcurses package			*/
/*								*/
/****************************************************************/
/* This version of curses is based on ncurses, a curses version	*/
/* originally written by Pavel Curtis at Cornell University.	*/
/* I have made substantial changes to make it run on IBM PC's,	*/
/* and therefore consider myself free to make it public domain.	*/
/*				Bjorn Larsson (bl@infovox.se)	*/
/****************************************************************/
/* 1.4:  Routines that ended in while-loops now end		*/
/*	 with return(ERR) to avoid compiler warnings.		*/
/*	 Use of short wherever possible. Portability		*/
/*	 improvements:					900114	*/
/* 1.3:	 MSC -W3, Turbo'C' -w -w-pro checkes:		881005	*/
/* 1.2:	 #undef:ine of getch now covers all the file, to	*/
/*	 make sure this module's getch() calls go to DOS,	*/
/*	 not to the PCCurses 'getch()' function. Fixed		*/
/*	 thanks to N.D. Pentcheff:			881002	*/
/* 1.1:	 Bug fixes: call to _curseskeytest() changed		*/
/*	 _curseskeytst(). Test of that routine also		*/
/*	 lacked () in one place:			870907	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

static	unsigned long	rawgetch(void);		/* get raw char via BIOS */
static	unsigned long	sysgetch(void);		/* get char via system */
static	unsigned long	validchar(unsigned long c);		/* keypad xlate and char check */

char _curses_charget_rcsid[] = "@(#)charget.c    v.1.4  - 900114";

static	unsigned long buffer[_INBUFSIZ];	/* character buffer */
static	unsigned long pindex = 0;		/* putter index */
static	unsigned long gindex = 1;		/* getter index */
static	WINDOW *w;			/* to reduce stack usage */
static	unsigned long ungind = 0;		/* wungetch() push index */
static	unsigned long ungch[NUNGETCH];	/* array of ungotten chars */

/* Table for key code translation of function keys in keypad mode */
/* These values are for strict IBM keyboard compatibles only */

static	unsigned long kptab[] =
  {
  0x3b,KEY_F(1),  0x3c,KEY_F(2),  0x3d,KEY_F(3),  0x3e,KEY_F(4),
  0x3f,KEY_F(5),  0x40,KEY_F(6),  0x41,KEY_F(7),  0x42,KEY_F(8),
  0x43,KEY_F(9),  0x44,KEY_F(10), 0x47,KEY_HOME,  0x48,KEY_UP,
  0x49,KEY_PPAGE, 0x4b,KEY_LEFT,  0x4d,KEY_RIGHT, 0x4f,KEY_LL,
  0x50,KEY_DOWN,  0x51,KEY_NPAGE, 0x52,KEY_IC,    0x53,KEY_DC,
  0x54,KEY_F(11), 0x55,KEY_F(12), 0x56,KEY_F(13), 0x57,KEY_F(14),
  0x58,KEY_F(15), 0x59,KEY_F(16), 0x5a,KEY_F(17), 0x5b,KEY_F(18),
  0x5c,KEY_F(19), 0x5d,KEY_F(20), 0x5e,KEY_F(21), 0x5f,KEY_F(22),
  0x60,KEY_F(23), 0x61,KEY_F(24), 0x62,KEY_F(25), 0x63,KEY_F(26),
  0x64,KEY_F(27), 0x65,KEY_F(28), 0x66,KEY_F(29), 0x67,KEY_F(30),
  0x73,KEY_LEFT,  0x74,KEY_RIGHT,  0x75,KEY_LL,   0x76,KEY_NPAGE,
  0x77,KEY_HOME,  0x84,KEY_PPAGE,  0x100,        -1
  };

/****************************************************************/
/* Wgetch(win) gets a character from the terminal, in normal,	*/
/* cbreak or raw mode, optionally echoing to window  'win'.	*/
/****************************************************************/

unsigned long
wgetch(WINDOW *win)
{
    unsigned long	key;
    unsigned long	cbr;

    if (ungind) {				/* if ungotten char exists */
	return(ungch[--ungind]);		/* remove and return it */
    }

    if ((!_cursvar.raw) && (!_cursvar.cbreak)) {/* if normal */
	if (gindex < pindex) {			/* and data in buffer */
	    return(buffer[gindex++]);
	}
    }

    w = win;					/* static for speed & stack */
    pindex = 0;					/* prepare to buffer data */
    gindex = 0;
    while(1) {					/* loop for any buffering */

	if (_cursvar.raw) {			/* get a raw character */
	    key = rawgetch();
	} else {				/* get a system character */
	    cbr = consoleGcb();			/* get ^BREAK status */
	    consoleScb(_cursvar.orgcbr);	/* if break return proper */
	    key = sysgetch();
	    consoleScb(cbr);			/* restore as it was */
	}
	if (w->_nodelay && (key == -1))	{	/* if nodelay and no char */
	    return(-1);
	}
#if 0
	{
	/* 
	 * for debugging purposes you can turn this on
	 * to see what keys we really got
	 */
	    unsigned long h,t,o;
	    ntcCell temp;

	    waddch(w, '['));
	    h = (key & 0xff)/100;
	    waddch(w, '0'));
	    t = ((key & 0xff) - h*100)/10;
	    waddch(w, '0'));
	    o = ((key & 0xff) - h*100) - t*10;
	    waddch(w, '0'));
	    waddch(w, ']'));
	}
#endif
	if ((key == '\r') && _cursvar.autocr && !_cursvar.raw) {
	    /* translate cr */
	    key = '\n';
	}
	if (_cursvar.echo && (key < 0x100)) {	/* check if echo */
	    waddch(w, key);
	    wrefresh(w);
	}
	if (_cursvar.raw || _cursvar.cbreak) {	/* if no buffering */
	    return(key);
	}
	if (pindex < _INBUFSIZ-2) {		/* if no overflow, */
	    buffer[pindex++] = key;		/* put data in buffer */
	}
	if ((key == '\n') || (key == '\r')) {	/* if we got a line */
	    return(buffer[gindex++]);
	}
    } /* while */
/*    return (ERR);	*/			/* Can't happen */
} /* wgetch */

/****************************************************************/
/* Flushinp() kills any pending input characters.		*/
/****************************************************************/

void 
flushinp(void)
{
    while(consoleKeytst()) {		/* empty keyboard buffer */
	(void) consoleGetChar();
    }

    while(consoleKeytst()) {		/* empty system's buffers */
	(void) consoleGetChar();
    }
    gindex = 1;				/* set indices to kill buffer */
    pindex = 0;
    ungind = 0;				/* clear ungch array */
} /* flushinp */

/****************************************************************/
/* Wungetch() pushes back it's argument on the input stream. If	*/
/* OK, returns 1, otherwise returns 0.				*/
/****************************************************************/

unsigned long
wungetch(unsigned long ch)
{
    if (ungind >= NUNGETCH) {		/* pushback stack full */
	return(0);
    }
    ungch[ungind++] = ch;
    return(1);
} /* wungetch() */

/****************************************************************/
/* Mvgetch() first moves the stdscr cursor to a new location,	*/
/* then does a wgetch() on stdscr.				*/
/****************************************************************/

unsigned long	
mvgetch(int y, int x)
{
    wmove(stdscr,y,x);
    return(wgetch(stdscr));
} /* mvgetch */

/****************************************************************/
/* Mvwgetch() first moves the cursor of window 'win' to a new	*/
/* location, then does a wgetch() in 'win'.			*/
/****************************************************************/

unsigned long
mvwgetch(WINDOW *win, int y, int x)
{
    wmove(win,y,x);
    return(wgetch(win));
} /* mvwgetch */

/****************************************************************/
/* rawgetch() gets a character without any interpretation at	*/
/* all and returns it. If keypad mode is active for the desig-	*/
/* nated window, function key translation will be performed.	*/
/* Otherwise, function keys are ignored.If nodelay mode is	*/
/* active in the window, then rawgetch() returns -1 if no cha-	*/
/* racter is available.						*/
/****************************************************************/

static unsigned long
rawgetch(void)
{
    unsigned long	c;
    
    if (w->_nodelay && !consoleKeytst()) {
	return(-1);
    }
    while(1) { 					/* loop to get valid char */
	if ((c = validchar(consoleGetChar())) >= 0) {
	    return(c);
	}
    }
    /* return (ERR);	*/				/* Can't happen */
} /* rawgetch */

/****************************************************************/
/* Sysgetch() gets a character with normal ^S, ^Q, ^P and ^C	*/
/* interpretation and returns it. If keypad mode is active for	*/
/* the designated window, function key translation will be per-	*/
/* formed. Otherwise, function keys are ignored. If nodelay	*/
/* mode is active in the window, then sysgetch() returns -1 if	*/
/* no character is available.					*/
/****************************************************************/

static unsigned long
sysgetch(void)
{
    unsigned long	c;

    while(1) {
	c = consoleGetChar();
	if (c != 0) {				/* if not a function key */
	    return(c);				/* avoids sign-extending */
	}
	c = consoleGetChar();
	if ((c = validchar(c << 8)) >= 0) {	/* get & check next char */
	    return(c);
	}
    }
    /* return (ERR);	*/				/* Can't happen */
} /* sysgetch */

/****************************************************************/
/* Validchar(c) chacks that 'c' is a valid character, and	*/
/* if so returns it, with function key translation applied if	*/
/* 'w' has keypad mode set. If char is invalid, returns -1.	*/
/****************************************************************/

static unsigned long
validchar(unsigned long c)
{
    unsigned long *scanp;

    if ((c & 0x01000000) != 0) {	/* special case, mouse click */
	return(c);
    }
    if (c == 0x0300) {			/* special case, ^@ = NULL */
	return(0);
    }
    if (!(c & 0xff00)) {		/* normal character */
	return(c);
    }
  if (!(w->_keypad)) {			/* skip f keys if not keypad mode */
      return(-1);
  }
  c = (c >> 8) & 0xff;
  scanp = kptab;
  while(*scanp <= c) {			/* search for value */
					/* (stops on table entry 0x100) */
      if (*scanp++ == c) {
	  return(*scanp);		/* found, return it */
      }
      scanp++;
  }
  return(-1);				/* not found, invalid */
} /* validchar */

/****************************************************************/
/* _pendch() returns 1 if there is any character avai-		*/
/* lable, and 0 if there is none. This is not for programmer	*/
/* usage, but for the updatew routines.				*/
/****************************************************************/

bool	
_pendch(void)
{
    if (ungind)				/* ungotten char */
	return(TRUE);
    if (pindex > gindex)			/* buffered char */
	return(TRUE);
    if (_cursvar.raw)			/* raw mode test */
	return(consoleKeytst());
    return((bool)consoleKeytst());		/* normal mode test */
} /* _pendch */
