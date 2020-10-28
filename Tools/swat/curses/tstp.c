/*
 * Copyright (c) 1980 Regents of the University of California.
 * All rights reserved.  The Berkeley software License Agreement
 * specifies the terms and conditions for redistribution.
 */

#ifndef lint
static char sccsid[] = "@(#)tstp.c	5.1 (Berkeley) 6/7/85";
#endif not lint

# include	<signal.h>

# include	"curses.ext"

/*
 * handle stop and start signals
 *
 * @(#)tstp.c	5.1 (Berkeley) 6/7/85
 */
void tstp(int p) {

# ifdef SIGTSTP
#ifndef _LINUX
	SGTTY	tty;
#endif
	int	omask;
# ifdef DEBUG
	if (outf)
		fflush(outf);
# endif
#ifndef _LINUX
	tty = _tty;
#endif
	mvcur(0, COLS - 1, LINES - 1, 0);
	endwin();
	fflush(stdout);
	/* reset signal handler so kill below stops us */
	signal(SIGTSTP, SIG_DFL);
#ifndef _LINUX
#define	mask(s)	(1 << ((s)-1))
	omask = sigsetmask(sigblock(0) &~ mask(SIGTSTP));
#endif
	kill(0, SIGTSTP);
#ifndef _LINUX
	sigblock(mask(SIGTSTP));
#endif
	signal(SIGTSTP, tstp);
#ifndef _LINUX
	_tty = tty;
	stty(_tty_ch, &_tty);
#endif

	wrefresh(curscr);
# endif	SIGTSTP
}
