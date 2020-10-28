# ifndef lint
static char *rcsid = "$Id: egetstr.c,v 1.2 92/07/13 21:38:26 adam Exp $";
# endif

/*LINTLIBRARY*/

# include <sys/types.h>
# include <curses.h>

#if defined(_MSDOS) || defined(__WATCOMC__)
#undef getch
#include <conio.h>
#endif

/*
 * this is a file of routines to substitute for curses' idiotic
 * input routines.
 * 
 * wgetech will read one character from the given window in CBREAK mode
 *	and echo it on the screen, if necessary, watching out for
 *	line-editing characters
 *
 * wgetestr will read an entire line from the given window into the
 *	given string, which is assumed to be long enough to hold it.
 *	It does line-editing.
 *
 */

wgetech (win)
    WINDOW *win;
{
    reg	char	c;
    short		oflags;
    
    /*
     * refresh the thing first (gets the cursor where it's wanted)
     */
    wrefresh (win);	
    
    /*
     * if the window is a screen and it's not allowed to scroll and it's at
     * the bottom right corner, don't even bother to get a character.
     */
    if (!win->_scroll && (win->_flags&_FULLWIN) &&
	(win->_curx == win->_maxx - 1) && (win->_cury == win->_maxy - 1))
    {
	return(ERR);
    }

#if !defined(_MSDOS) && !defined(__WATCOMC__)
    /*
     * save the current tty modes
     */
    oflags = _tty.sg_flags;
    
    /*
     * then set it into cbreak noecho mode...always
     */
    _tty.sg_flags |= CBREAK;
    _tty.sg_flags &= ~ECHO;
    ioctl (_tty_ch, TIOCSETN, &_tty);
    
    c = getchar();
#else
    c = _getch();   /* XXX: EXTENDED CODES */
#endif
    
    /*
     * if the user wants echo and it's not the erase character, echo it.
     */
    if (_echoit && (c != erasechar()) && (c != killchar())) {
	waddch(win, c);
    }
    /*
     * if we're echoing and it's the erase character, delete the previous
     * character and leave the cursor there.
     */
    if (_echoit && c == erasechar()) {
	waddstr (win, "\b \b");
    }
    
#if !defined(_MSDOS) && !defined(__WATCOMC__)
    /*
     * reset the tty to its original state
     */
    _tty.sg_flags = oflags;
    ioctl (_tty_ch, TIOCSETN, &_tty);
#endif
    
    return (c);
}

/*
** wgetestr (win, str) WINDOW *win; char *str;
*/
# define Unput(str)	((--str < ostr) ? (++str,0) : 1)
# define NukeC(win)	if (_echoit) waddstr (win, "\b \b")
wgetestr (win, str)
    WINDOW  	*win;
    reg char 	*str;
{
    reg int	breakout,
		cx,
		cy;
    int		bx,
		by;
    char	*ostr = str;
#if !defined(_MSDOS) && !defined(__WATCOMC__)
    struct ltchars	ltc;
    short		oflags;
#define werasechar() ltc.t_werasc
#else
#define werasechar() ('W' & 0x1f)
#endif
    
    /*
     * if the window is a screen and it's not allowed to scroll and it's at
     * the bottom right corner, don't even bother to get a character.
     */
    if (!win->_scroll && (win->_flags&_FULLWIN) &&
	(win->_curx == win->_maxx - 1) && (win->_cury == win->_maxy - 1))
    {
	return(ERR);
    }

#if !defined(_MSDOS) && !defined(__WATCOMC__)
    /*
     * save the current tty modes
     */
    oflags = _tty.sg_flags;
    
    /*
     * then set it into cbreak noecho mode...always
     */
    _tty.sg_flags |= CBREAK;
    _tty.sg_flags &= ~ECHO;
    ioctl (_tty_ch, TIOCSETN, &_tty);
    
    ioctl (_tty_ch, TIOCGLTC, &ltc);
#endif /* !_MSDOS */
    
    breakout = 0;
    getyx (win, by, bx);

    /*
     * refresh the thing first (gets the cursor where it's wanted)
     */
    wrefresh (win);	
    
    /*
     * saves the current cursor postion, then gets a new character.
     * If the character is EOF or ERR or newline or return, breaks out
     * of the loop. If the character is the erase character, it sees if
     * wgetch() tried to back up beyond the line (cx == 0). If it did,
     * it backs up for it, as long as there's somewhere to go. It then
     * refreshes the screen. If the character is the kill character, it
     * moves back to the original screen position, clears it to the bottom
     * of the screen, resets the str pointer to the beginning.
     */
    do {
	getyx (win, cy, cx);
    
#if !defined(_MSDOS) && !defined(__WATCOMC__)
	*str = getchar();
#else
	*str = _getch();    /* XXX: EXTENDED CODES */
#endif
	switch (*str) {
	    case '\n':
	    case '\r':
		if (_echoit) {
		    waddch(win, '\n');
		}
		/*FALLTHRU*/
	    case EOF:
	    case ERR:
		breakout = 1;
		break;
	    default:
		if (*str == erasechar()) {
		    if (cx == 0) {
			if (win->_cury--) {
			    win->_curx = win->_maxx;
			}
		    }
		    str--;
		    if (str < ostr) {
			write(_tty_ch, "\007", 1);
			str++;
		    } else {
			waddstr(win, "\b \b");
		    }
		} else if (*str == killchar()) {
		    str = ostr;
		    if (_echoit) {
			wmove (win, by, bx);
			wclrtobot (win);
		    }
		} else if (*str == werasechar()) {
		    if  (Unput (str)) {
			while ((*str == ' ' || *str == '\t') && Unput (str)) {
			    NukeC(win);
			}
			while (str >= ostr && *str != ' ' && *str != '\t') {
			    str--;
			    NukeC(win);
			}
			/*
			 * Point str back at start of string, or past whitespace
			 * that stopped the loop...
			 */
			str++;
		    }
		} else if (_echoit) {
		    waddch(win, *str++);
		} else {
		    str++;
		}
	}
	if (_echoit) {
	    wrefresh (win);
	}
    } while ( ! breakout );
    
    *str = '\0';
    
#if !defined(_MSDOS) && !defined(__WATCOMC__)
    /*
     * reset the tty to its original state
     */
    _tty.sg_flags = oflags;
    ioctl (_tty_ch, TIOCSETN, &_tty);
#endif
    
    if (*str != ERR) {
	return (OK);
    } else {
	return (ERR);
    }
}
