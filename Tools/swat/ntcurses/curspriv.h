/***********************************************************************
 *
 *	Copyright (c) Geoworks 1997.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  swat - ntcurses
 * FILE:	  curspriv.h
 *
 * AUTHOR:  	  Dan Baumann: Apr 08, 1997
 *
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	dbaumann	4/08/97   	Initial version
 *
 * DESCRIPTION:
 *
 *	
 *
 *	$Id: curspriv.h,v 1.1 97/04/18 11:19:37 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _CURSPRIV_H_
#define _CURSPRIV_H_

#endif /* _CURSPRIV_H_ */
/****************************************************************/
/*			   CURSPRIV.H				*/
/* Header file for definitions and declarations for the		*/
/* PCcurses package. These definitions should not be gene-	*/
/* rally accessible to programmers.				*/
/****************************************************************/
/* This version of curses is based on ncurses, a curses version	*/
/* originally written by Pavel Curtis at Cornell University.	*/
/* I have made substantial changes to make it run on IBM PC's,	*/
/* and therefore consider myself free to make it public domain.	*/
/*				Bjorn Larsson (bl@infovox.se)	*/
/****************************************************************/
/* 1.4:  ERR/ OK redefinied in curses.h. Use of short		*/
/*	 wherever possible Portability improvements:	900114	*/
/* 1.3:	 All modules lint-checked with MSC '-W3' and		*/
/*	 Turbo'C' '-w -w-pro' switches:			881005	*/
/* 1.2:	 Support (by #ifdef UCMASM) for uppercase-only		*/
/*	 assembly routine names. If UCMASM if defined,		*/
/*	 all assembler names are #defined as upper case.	*/
/*	 Not needed if you do "MASM /MX. Also missing		*/
/* 	 declaration of cursesscroll(). Fixes thanks to		*/
/*	 N.D. Pentcheff:				881002	*/ 
/* 1.1:	 Add _chadd() for raw output routines:		880306	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

typedef unsigned long DWORD;

#define	CURSES_RCS_ID	"@(#)PCcurses     v.1.4  - 900114"

/* window properties */

#define	_SUBWIN		1		/* window is a subwindow */
#define	_ENDLINE	2		/* last winline is last screen line */
#define	_FULLWIN	4		/* window fills screen */
#define	_SCROLLWIN	8		/* window lwr rgt is screen lwr rgt */
#define _STANDOUT	16		/* chars add should be hi-lited */
/* Miscellaneous */

#define	_INBUFSIZ	200		/* size of terminal input buffer */
#define	_NO_CHANGE	-1		/* flags line edge unchanged */

#define	_BREAKCHAR	0x03		/* ^C character */
#define _DCCHAR		0x08		/* Delete Char char (BS) */
#define _DLCHAR		0x1b		/* Delete Line char (ESC) */
#define	_GOCHAR		0x11		/* ^Q character */
#define	_PRINTCHAR	0x10		/* ^P character */
#define	_STOPCHAR	0x13		/* ^S character */
#define	 NUNGETCH	10		/* max # chars to ungetch() */

/* type declarations */

typedef	struct
  {
  short	   cursrow;			/* position of physical cursor */
  short	   curscol;
  bool	   autocr;			/* if lf -> crlf */
  bool	   cbreak;			/* if terminal unbuffered */
  bool	   echo;			/* if terminal echo */
  bool	   raw;				/* if terminal raw mode */
  bool	   refrbrk;			/* if premature refresh brk allowed */
  bool     orgcbr;			/* original MSDOS ^-BREAK setting */
  }	cursv;

/* External variables */

extern	cursv   _cursvar;		/* curses variables */

/* Curses internal functions, not to be used by programmers */

extern	int	_chaddWide(register WINDOW	*win,
			   ntcCell		 *c,
			   bool			 xlat);
extern	bool	_pendch(void);
extern	void	_putc(char chr, DWORD attr);

extern void consoleCursor(int row, int column);
extern void consoleSetCell(short row, short column, ntcCell *ch);
extern void consoleClearRect(short top, short left, short bottom, 
			     short right);
extern void consoleScrollWin(short desty, short destx, short top, 
			     short left, short bottom, short right);
extern void consoleFlash(void);
extern void consoleBeep(void);
extern bool consoleKeytst(void);
extern unsigned long consoleGetChar(void);
extern int consoleGcmode(void);
extern void consoleCmode(int startrow, int endrow);
extern int consoleGcb(void);
extern void consoleScb(int setting);


