/*
 * Copyright (c) 1980 Regents of the University of California.
 * All rights reserved.  The Berkeley software License Agreement
 * specifies the terms and conditions for redistribution.
 */

#ifndef lint
static char sccsid[] = "@(#)printw.c	5.1 (Berkeley) 6/7/85";
#endif not lint

/*
 * printw and friends
 *
 */

# include	"curses.ext"

#include    <stdarg.h>
#include    <ctype.h>

/*
 *	This routine implements a printf on the standard screen.
 */
printw(char *fmt, ...)
{
    va_list	args;
    int res;

    va_start(args, fmt);
    res = _sprintw(stdscr, fmt, args);
    va_end(args);
    return(res);
}

/*
 *	This routine implements a printf on the given window.
 */
wprintw(WINDOW *win, char *fmt, ...)
{
    va_list	args;
    int		res;

    va_start(args, fmt);
    res = _sprintw(win, fmt, args);
    va_end(args);
    return(res);
}
/*
 *	This routine actually executes the printf and adds it to the window
 *
 *	This is really a modified version of "sprintf".  As such,
 * it assumes that sprintf interfaces with the other printf functions
 * in a certain way.  If this is not how your system works, you
 * will have to modify this routine to use the interface that your
 * "sprintf" uses.
 */
_snprintf(str, size, fmt, args)
    char    	*str;
    int	    	size;
    char    	*fmt;
    va_list 	args;
{
    FILE	junk;

    junk._flag = _IOWRT + _IOSTRG;
    junk._base = junk._ptr = str;
#if !defined(__HIGHC__)
    junk._bufsiz = size-1;
#endif
    junk._cnt = size-1;
    junk._file = -1;

# if defined(sun) || defined(__HIGHC__)
    vfprintf(&junk, fmt, args);
# else
    _doprnt(fmt, args, &junk);
# endif

    /*
     * Null-terminate, upping _cnt in case vfprintf filled up all the space
     * it was allowed to fill (lets us stick in the final null, for which
     * we saved room, above)
     */
    junk._cnt++;
    putc('\0', &junk);
}

_sprintw(win, fmt, args)
    WINDOW	*win;
    char	*fmt;
    va_list	args;
{
    char    	  	string[512];	/* Place for formatting things */
    char    	    	cfmt[64];   	/* Place to which to copy the format */
    register char	*cp;	    	/* Current position in fmt */
    char		*cpStart;   	/* Start of unprocessed part of fmt */
    va_list		nextArgs;   	/* End of args for current char */
    bool 	  	fancy;

    cpStart = cp = fmt;

    while (*cp != '\0') {
	if (*cp != '%') {
	    cp++;
	} else {
	    while (cpStart != cp) {
		waddch(win, *cpStart++);
	    }
	    cp++;
	    nextArgs = args;
	    fancy = FALSE;
	charswitch:
	    switch(*cp) {
		case '*':
		    /*
		     * Argument specifies width -- pop it now
		     */
		    (void)va_arg(nextArgs, int);
		    fancy = TRUE;
		case '+':
		case '-':
		case ' ':
		case '#':
		case '.':
		case 'l':
		case 'h':
		    cp++;
		    fancy = TRUE;
		    goto charswitch;
		case '0':
		case '1':
		case '2':
		case '3':
		case '4':
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
		    cp++;
		    while (isdigit(*cp)) {
			cp++;
		    }
		    fancy = TRUE;
		    goto charswitch;
		    
		case 'd':
		    cp++;
		    strncpy(cfmt, cpStart, cp-cpStart);
		    cfmt[cp-cpStart] = '\0';
		    (void)va_arg(nextArgs, int);
		    _snprintf(string, sizeof(string), cfmt, args);
		    waddstr(win, string);
		    break;
		    
		case 'u':
		case 'o':
		case 'X':
		case 'x':
		    cp++;
		    strncpy(cfmt, cpStart, cp-cpStart);
		    cfmt[cp-cpStart] = '\0';
		    (void)va_arg(nextArgs, unsigned int);
		    _snprintf(string, sizeof(string), cfmt, args);
		    waddstr(win, string);
		    break;
		    
		case 'E':
		case 'e':
		case 'f':
		case 'G':
		case 'g':
		    cp++;
		    strncpy(cfmt, cpStart, cp-cpStart);
		    cfmt[cp-cpStart] = '\0';
		    (void)va_arg(nextArgs, double);
		    _snprintf(string, sizeof(string), cfmt, args);
		    waddstr(win, string);
		    break;
		case 'c':
		    (void)va_arg(nextArgs, int);
		case '%':
		    cp++;
		    strncpy(cfmt, cpStart, cp-cpStart);
		    cfmt[cp-cpStart] = '\0';
		    _snprintf(string, sizeof(string), cfmt, args);
		    waddstr(win, string);
		    break;
		    
		case 's':
		    cp++;
		    if ((args == nextArgs) && !fancy) {
			char *s = va_arg(nextArgs, char *);
			waddstr(win, s);
		    } else {
			/*
			 * XXX: Should worry about length here, but what
			 * the heck?
			 */
			strncpy(cfmt, cpStart, cp-cpStart);
			cfmt[cp-cpStart] = '\0';
			(void)va_arg(nextArgs, char *);
			_snprintf(string, sizeof(string), cfmt, args);
			waddstr(win, string);
		    }
		    break;
	    }
	    cpStart = cp;
	    args = nextArgs;
	}
    }
    waddstr(win, cpStart);
}
