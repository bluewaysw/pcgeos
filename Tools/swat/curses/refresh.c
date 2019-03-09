/*
 * Copyright (c) 1980 Regents of the University of California.
 * All rights reserved.  The Berkeley software License Agreement
 * specifies the terms and conditions for redistribution.
 */

#ifndef lint
static char sccsid[] = "@(#)refresh.c	5.1 (Berkeley) 6/7/85";
#endif not lint

/*
 * make the current screen look like "win" over the area coverd by
 * win.
 */

# include	"curses.ext"

# ifdef DEBUG
# define	STATIC
# else
# define	STATIC	static
# endif

STATIC short	ly, lx;

STATIC bool	curwin;

WINDOW	*_win = NULL;

wrefresh(win)
reg WINDOW	*win;
{
	reg short	wy;
	reg int		retval;
	reg WINDOW	*orig;

	/*
	 * make sure were in visual state
	 */
	if (_endwin) {
#if !defined(_MSDOS)
		_puts(VS);
		_puts(TI);
#else
		DosInitScreen();
#endif	/* _MSDOS */
		_endwin = FALSE;
	}

	/*
	 * initialize loop parameters
	 */

	ly = curscr->_cury;
	lx = curscr->_curx;
	wy = 0;
	_win = win;
	curwin = (win == curscr);

	if (win->_clear || curscr->_clear || curwin) {
		if ((win->_flags & _FULLWIN) || curscr->_clear) {
#if !defined(_MSDOS)
			_puts(CL);
#else
			DosClearScreen();
#endif	/* _MSDOS */
			ly = 0;
			lx = 0;
			if (!curwin) {
				curscr->_clear = FALSE;
				curscr->_cury = 0;
				curscr->_curx = 0;
				werase(curscr);
			}
			touchwin(win);
		}
		win->_clear = FALSE;
	}
#if !defined(_MSDOS)	/* cursor-motion always possible under DOS */
	if (!CA) {
		if (win->_curx != 0)
			_putchar('\n');
		if (!curwin)
			werase(curscr);
	}
#endif /* !_MSDOS */

# ifdef DEBUG
	fprintf(outf, "REFRESH(%0.2o): curwin = %d\n", win, curwin);
	fprintf(outf, "REFRESH:\n\tfirstch\tlastch\n");
# endif
	for (wy = 0; wy < win->_maxy; wy++) {
# ifdef DEBUG
		fprintf(outf, "%d\t%d\t%d\n", wy, win->_firstch[wy],
			win->_lastch[wy]);
# endif
		if (win->_firstch[wy] != _NOCHANGE)
			if (makech(win, wy) == ERR) {
			    retval = ERR;
			    goto ret;
			} else {
				if (win->_firstch[wy] >= win->_ch_off)
					win->_firstch[wy] = win->_maxx +
							    win->_ch_off;
				if (win->_lastch[wy] < win->_maxx +
						       win->_ch_off)
					win->_lastch[wy] = win->_ch_off;
				if (win->_lastch[wy] < win->_firstch[wy])
					win->_firstch[wy] = _NOCHANGE;
			}
# ifdef DEBUG
		fprintf(outf, "\t%d\t%d\n", win->_firstch[wy],
			win->_lastch[wy]);
# endif
	}

	if (win == curscr)
		domvcur(ly, lx, win->_cury, win->_curx);
	else {
		if (win->_leave) {
			curscr->_cury = ly;
			curscr->_curx = lx;
			ly -= win->_begy;
			lx -= win->_begx;
			if (ly >= 0 && ly < win->_maxy && lx >= 0 &&
			    lx < win->_maxx) {
				win->_cury = ly;
				win->_curx = lx;
			}
			else
				win->_cury = win->_curx = 0;
		}
		else {
			domvcur(ly, lx, win->_cury + win->_begy,
				win->_curx + win->_begx);
			curscr->_cury = win->_cury + win->_begy;
			curscr->_curx = win->_curx + win->_begx;
		}
	}
	retval = OK;
ret:
	_win = NULL;
	fflush(stdout);
	return retval;
}

/*
 * make a change on the screen
 */
STATIC
makech(win, wy)
reg WINDOW	*win;
short		wy;
{
    reg char	*nsp, *csp, *ce;
    reg short	wx, lch, y;
    reg int		nlsp, clsp; /* last space in lines		*/

    wx = win->_firstch[wy] - win->_ch_off;
    if (wx >= win->_maxx)
	return OK;
    else if (wx < 0)
	wx = 0;
    lch = win->_lastch[wy] - win->_ch_off;
    if (lch < 0)
	return OK;
    else if (lch >= win->_maxx)
	lch = win->_maxx - 1;
    y = wy + win->_begy;

    if (curwin)
	csp = " ";
    else
	csp = &curscr->_y[wy + win->_begy][wx + win->_begx];

    nsp = &win->_y[wy][wx];
    if (CE && !curwin) {
	ce = &win->_y[wy][win->_maxx];
	while (*--ce == ' ') {
	    if (ce <= win->_y[wy]) {
		break;
	    }
	}
	nlsp = ce - win->_y[wy];
	ce = CE;
    } else {
	ce = NULL;
    }

    while (wx <= lch) {
	if (*nsp != *csp) {
	    domvcur(ly, lx, y, wx + win->_begx);
# ifdef DEBUG
	    fprintf(outf, "MAKECH: 1: wx = %d, lx = %d\n", wx, lx);
# endif	
	    ly = y;
	    lx = wx + win->_begx;
	    while (wx <= lch && *nsp != *csp) {
		if (ce != NULL && wx >= nlsp && *nsp == ' ') {
		    /*
		     * check for clear to end-of-line
		     */
		    ce = &curscr->_y[ly][COLS - 1];
		    while (*ce == ' ')
			if (ce-- <= csp)
			    break;
		    clsp = ce - curscr->_y[ly] - win->_begx;
# ifdef DEBUG
		    fprintf(outf, "MAKECH: clsp = %d, nlsp = %d\n", clsp, nlsp);
# endif
		    if (clsp - nlsp >= strlen(CE) && clsp < win->_maxx) {
# ifdef DEBUG
			fprintf(outf, "MAKECH: using CE\n");
# endif
#if !defined(_MSDOS)
			_puts(CE);
#else
			DosClearToEndOfLine();
#endif
			lx = wx + win->_begx;
			while (wx++ <= clsp)
			    *csp++ = ' ';
			return OK;
		    }
		    ce = NULL;
		}
		/*
		 * enter/exit standout mode as appropriate
		 */
		if (SO && (*nsp&_STANDOUT) != (curscr->_flags&_STANDOUT)) {
		    if (*nsp & _STANDOUT) {
#if !defined(_MSDOS)
			_puts(SO);
#else
			DosStartStandOut();
#endif
			curscr->_flags |= _STANDOUT;
		    }
		    else {
#if !defined(_MSDOS)
			_puts(SE);
#else
			DosEndStandOut();
#endif
			curscr->_flags &= ~_STANDOUT;
		    }
		}
		wx++;
		if (wx >= win->_maxx && wy == win->_maxy - 1)
		    if (win->_scroll) {
			if ((curscr->_flags&_STANDOUT) &&
			    (win->_flags & _ENDLINE))
			{
			    if (!MS) {
#if !defined(_MSDOS)
				_puts(SE);
#else
				DosEndStandOut();
#endif
				curscr->_flags &= ~_STANDOUT;
			    }
			}
			if (!curwin)
			    _putchar((*csp = *nsp) & 0177);
			else
			    _putchar(*nsp & 0177);
			if (win->_flags&_FULLWIN && !curwin)
			    scroll(curscr);
#if 1
			ly = win->_begy+win->_maxy-1;
			lx = 0;
#else
			ly = win->_begy+win->_cury;
			lx = win->_begx+win->_curx;
#endif
			return OK;
		    }
		    else if (win->_flags&_SCROLLWIN) {
			lx = --wx;
			return ERR;
		    }
		if (!curwin)
		    _putchar((*csp++ = *nsp) & 0177);
		else
		    _putchar(*nsp & 0177);
# ifdef FULLDEBUG
		fprintf(outf,
			"MAKECH:putchar(%c)\n", *nsp & 0177);
# endif
#if !defined(_MSDOS)	/* No underscore possible under DOS */
		if (UC && (*nsp & _STANDOUT)) {
		    _putchar('\b');
		    _puts(UC);
		}
#endif
		nsp++;
	    }
# ifdef DEBUG
	    fprintf(outf, "MAKECH: 2: wx = %d, lx = %d\n", wx, lx);
# endif	
	    if (lx == wx + win->_begx) /* if no change */
		break;
	    lx = wx + win->_begx;
	    if (lx >= COLS && AM) {
		lx = 0;
		ly++;
		/*
		 * xn glitch: chomps a newline after auto-wrap.
		 * we just feed it now and forget about it.
		 */
#if !defined(_MSDOS)	/* No :xn: glitch under DOS */
		if (XN) {
		    _putchar('\n');
		    _putchar('\r');
		}
#endif
	    }
	}
	else if (wx <= lch)
	    while (wx <= lch && *nsp == *csp) {
		nsp++;
		if (!curwin)
		    csp++;
		++wx;
	    }
	else
	    break;
# ifdef DEBUG
	fprintf(outf, "MAKECH: 3: wx = %d, lx = %d\n", wx, lx);
# endif	
    }
    return OK;
}

/*
 * perform a mvcur, leaving standout mode if necessary
 */
STATIC
domvcur(oy, ox, ny, nx)
int	oy, ox, ny, nx; {

	if (curscr->_flags & _STANDOUT && !MS) {
#if !defined(_MSDOS)
		_puts(SE);
#else
		DosEndStandOut();
#endif
		curscr->_flags &= ~_STANDOUT;
	}
	mvcur(oy, ox, ny, nx);
}
