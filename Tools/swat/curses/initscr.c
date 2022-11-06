/*
 * Copyright (c) 1980 Regents of the University of California.
 * All rights reserved.  The Berkeley software License Agreement
 * specifies the terms and conditions for redistribution.
 */

#ifndef lint
static char sccsid[] = "@(#)initscr.c	5.1 (Berkeley) 6/7/85";
#endif not lint

# include	"curses.ext"
#if !defined(_MSDOS)
# include	<signal.h>
#endif /* !_MSDOS */
#include <termios.h>

extern char	*getenv();

#ifdef _LINUX
struct termios old_termios;
#endif

#ifdef _LINUX
void
exitscr() {
	static int fd=0;
	fd=fileno(stdin);	
	tcsetattr(fd, TCSANOW, &old_termios);
}
#endif


/*
 *	This routine initializes the current and standard screen.
 *
 */
WINDOW *
initscr() {

	reg char	*sp;
	void		tstp(int p);
	int 		nfd;

# ifdef DEBUG
	fprintf(outf, "INITSCR()\n");
# endif
#if !defined(_MSDOS)
	if (My_term)
		setterm(Def_term);
	else {
		for (_tty_ch = 0; _tty_ch < nfd; _tty_ch++)
			if (isatty(_tty_ch))
				break;
		gettmode();
		if ((sp = getenv("TERM")) == NULL)
			sp = Def_term;
		if(!setterm(sp)){
			printf("Warning: Terminal type ENV=%s unknown, not found in pcgeos/bin/termcap file. Using pure shell instead.\n", sp);
		}
# ifdef DEBUG
		fprintf(outf, "INITSCR: term = %s\n", sp);
# endif
	}
	_puts(TI);
	_puts(VS);
# ifdef SIGTSTP
	signal(SIGTSTP, tstp);
# endif
#else /* is _MSDOS */
#if !defined(_LINUX)
	setterm();
	DosInitScreen();
#endif
#endif
#ifdef _LINUX
	{
		static int fd=0;
		struct termios new;
		fd=fileno(stdin);	
		tcgetattr(fd, &old_termios);
		new=old_termios;
		new.c_lflag &= ~(ICANON|ECHO);
   		tcsetattr(fd, TCSANOW, &new);

		atexit(exitscr);
	}
#endif

	if (curscr != NULL) {
# ifdef DEBUG
		fprintf(outf, "INITSCR: curscr = 0%o\n", curscr);
# endif
		delwin(curscr);
	}
# ifdef DEBUG
	fprintf(outf, "LINES = %d, COLS = %d\n", LINES, COLS);
# endif
	if ((curscr = newwin(LINES, COLS, 0, 0)) == ERR)
		return ERR;
	clearok(curscr, TRUE);
	curscr->_flags &= ~_FULLLINE;
	if (stdscr != NULL) {
# ifdef DEBUG
		fprintf(outf, "INITSCR: stdscr = 0%o\n", stdscr);
# endif
		delwin(stdscr);
	}
	stdscr = newwin(LINES, COLS, 0, 0);
	return stdscr;
}

WINDOW * reinitscr() {

    int newLINES = 0;
    int newCOLS = 0;

# ifdef TIOCGWINSZ
	struct winsize win;
# endif

# ifdef TIOCGWINSZ
	if (ioctl(_tty_ch, TIOCGWINSZ, &win) >= 0) {
		if (newLINES == 0)
			newLINES = win.ws_row;
		if (newCOLS == 0)
			newCOLS = win.ws_col;
	}
# endif

	if (newLINES == 0)
		newLINES = tgetnum("li");
	if (newLINES <= 5)
		newLINES = 24;

	if (newCOLS == 0)
		newCOLS = tgetnum("co");
	if (newCOLS <= 4)
		newCOLS = 80;


    if((newLINES != LINES) || (newCOLS != COLS)) {
    
        LINES = newLINES;
        COLS = newCOLS;

		printf("NEW_SIZE %d %d,", COLS, LINES); fflush(stdout);


        if ((curscr = resizewin(curscr,LINES,COLS)) == (WINDOW *)ERR) {
            exit(1);
        }
        wrefresh(curscr);
        return(OK);
    }
    return (ERR);

	return OK;
}
