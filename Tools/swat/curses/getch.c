/*
 * Copyright (c) 1980 Regents of the University of California.
 * All rights reserved.  The Berkeley software License Agreement
 * specifies the terms and conditions for redistribution.
 */

#ifndef lint
static char sccsid[] = "@(#)getch.c	5.3 (Berkeley) 4/16/86";
#endif not lint

# include	"curses.ext"

#if defined(_MSDOS)
#undef getch
#include <conio.h>
#include <bios.h>
#endif

/*
 *	This routine reads in a character from the window.
 *
 */
wgetch(win)
reg WINDOW	*win; {

	reg bool	weset = FALSE;
	reg char	inp;

	if (!win->_scroll && (win->_flags&_FULLWIN)
	    && win->_curx == win->_maxx - 1 && win->_cury == win->_maxy - 1)
		return ERR;
# ifdef DEBUG
	fprintf(outf, "WGETCH: _echoit = %c, _rawmode = %c\n", _echoit ? 'T' : 'F', _rawmode ? 'T' : 'F');
# endif
#if !defined(_MSDOS)
	if (_echoit && !_rawmode) {
		cbreak();
		weset++;
	}
	inp = getchar();
#else
	DosSyncBiosCursor();
	inp = _bios_keybrd(_KEYBRD_READ);   /* XXX: EXTENDED CODES */
	if (inp == '\r') {
	    inp = '\n';
	}
	if (_echoit) {
	    _putchar(inp);
	}
#endif

# ifdef DEBUG
	fprintf(outf,"WGETCH got '%s'\n",unctrl(inp));
# endif
	if (_echoit) {
		mvwaddch(curscr, win->_cury + win->_begy,
			win->_curx + win->_begx, inp);
		waddch(win, inp);
	}
#if !defined(_MSDOS)
	if (weset)
		nocbreak();
#endif
	return inp;
}
