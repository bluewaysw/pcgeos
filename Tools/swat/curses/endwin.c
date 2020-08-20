/*
 * Copyright (c) 1980 Regents of the University of California.
 * All rights reserved.  The Berkeley software License Agreement
 * specifies the terms and conditions for redistribution.
 */

#ifndef lint
static char sccsid[] = "@(#)endwin.c	5.1 (Berkeley) 6/7/85";
#endif not lint

/*
 * Clean things up before exiting
 *
 */

# include	"curses.ext"

endwin()
{
#if !defined (_MSDOS) && !defined(__WATCOMC__)
	resetty();
	_puts(VE);
	_puts(TE);
#else
#if !defined(_LINUX)
	DosResetScreen();
#endif
#endif
	if (curscr) {
		if (curscr->_flags & _STANDOUT) {
#if !defined(_MSDOS)
			_puts(SE);
#else
			DosEndStandOut();
#endif
			curscr->_flags &= ~_STANDOUT;
		}
		_endwin = TRUE;
	}
}
