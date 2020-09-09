/*
 * Copyright (c) 1980 Regents of the University of California.
 * All rights reserved.  The Berkeley software License Agreement
 * specifies the terms and conditions for redistribution.
 */

#ifndef lint
static char sccsid[] = "@(#)printw.c	5.1 (Berkeley) 6/7/85";
#endif not lint


#ifdef __WATCOMC__
/* In WATCOM C (at least under WinNT), the FILE structure is not the
   same as the Unix/MetaC one.  So here's some hacks to make it look
   more compatible.  We're still going to have to set "level" as well,
   see below...  */
//#define _cnt	bsize
#define _base	_ptr
//#define _ptr	curp
//#define _flag	flags
#define _file	_handle
#define _bufsiz	_bufsize
#define _IOSTRG (0)
#define _IOWRT	_WRITE
#endif

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
void my_snprintf(str, size, fmt, args)
    char    	*str;
    int	    	size;
    char    	*fmt;
    va_list 	args;
{

# if defined(sun) || defined(__HIGHC__) || defined(__WATCOMC__)
    vsprintf(str, fmt, args);
# else
    FILE	junk;

    junk._flag = _IOWRT + _IOSTRG;
    junk._base = junk._ptr = str;
#if !defined(__HIGHC__)
    junk._bufsiz = size-1;
#endif
    junk._cnt = size-1;
    junk._file = -1;
    _doprnt(fmt, args, &junk);

    /*
     * Null-terminate, upping _cnt in case vfprintf filled up all the space
     * it was allowed to fill (lets us stick in the final null, for which
     * we saved room, above)
     */
    junk._cnt++;
    putc('\0', &junk);
# endif
}

int _sprintw(win, fmt, args)
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
	    va_copy(nextArgs, args);
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
		    my_snprintf(string, sizeof(string), cfmt, args);
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
		    my_snprintf(string, sizeof(string), cfmt, args);
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
		    my_snprintf(string, sizeof(string), cfmt, args);
		    waddstr(win, string);
		    break;
		case 'c':
		    (void)va_arg(nextArgs, int);
		case '%':
		    cp++;
		    strncpy(cfmt, cpStart, cp-cpStart);
		    cfmt[cp-cpStart] = '\0';
		    my_snprintf(string, sizeof(string), cfmt, args);
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
			my_snprintf(string, sizeof(string), cfmt, args);
			waddstr(win, string);
		    }
		    break;
	    }
	    cpStart = cp;
	    va_copy(args, nextArgs);
	}
    }
    waddstr(win, cpStart);
}
