/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		prntscan.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:



	$Id: prntscan.c,v 1.1 97/04/18 11:22:57 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Printw() and scanw() routines of the PCcurses package	*/
/*								*/
/****************************************************************/
/* This version of curses is based on ncurses, a curses version	*/
/* originally written by Pavel Curtis at Cornell University.	*/
/* I have made substantial changes to make it run on IBM PC's,	*/
/* and therefore consider myself free to make it public domain.	*/
/*				Bjorn Larsson (bl@infovox.se)	*/
/****************************************************************/
/*		     IMPLEMENTATION NOTE 1			*/
/* These routines make a local copy of their parameter stack,	*/
/* assuming at most 5 'double' arguments were passed (== 40	*/
/* bytes == 20 int's == 10 long's == 10-20 pointers {depending	*/
/* on memory model}, etc). This means the invokation of the	*/
/* routines themself require at least 80 bytes of stack just	*/
/* for the parameters, and the sprintf() and sscanf() functions	*/
/* will require more. Therefore, this module should be compiled	*/
/* with stack checking on to avoid stack overflow errors.	*/
/****************************************************************/
/*		     IMPLEMENTATION NOTE 2			*/
/* This curses version is also used in a special environment	*/
/* with a 68000 CPU. The 68K compiler used has a bug in the	*/
/* standard library, which means that sprintf will not print	*/
/* newlines right. Therefore a workaround has been included in	*/
/* this file, conditionalized by '#if BUG68K'. This does not	*/
/* affect the PC version in any way, except the source is a	*/
/* little more obscure...					*/
/****************************************************************/
/* 1.4:  Use of short wherever possible. Portability		*/
/*	 improvements. 68K bug workaround:		900114	*/
/* 1.3:	 MSC -W3, Turbo'C' -w -w-pro checkes:		881005	*/
/* 1.2:	 Rcsid[] string for maintenance:		881002	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

/* XXX: evil hack to get around initial dumbness, remove */
#define NO_GETCHAR_HOSAGE

#include <curses.h>
#include <curspriv.h>
#include <stdarg.h>
#include <stdio.h>
#include <ctype.h>
//#include <alloc.h>

#ifdef __BORLANDC__
/* In BorlandC (at least under WinNT), the FILE structure is not the
   same as the Unix/MetaC one.  So here's some hacks to make it look
   more compatible.  We're still going to have to set "level" as well,
   see below...  */
#define _cnt	bsize
#define _base	buffer
#define _ptr	curp
#define _flag	flags
#define _file	fd
#define _IOSTRG (0)
#define _IOWRT	_F_WRIT
#include <limits.h>		/* for setting level to INT_MIN */
#include <math.h>		/* for modf() */

/* XXX: I'm too lazy to do these correctly, for now.  Feel free to
   come flame me for forgetting to implement them later. */
#define isinf(x) (0)
#define isnan(x) (0)
#endif

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
#include <limits.h>		/* for setting level to INT_MIN */
#include <math.h>		/* for modf() */

/* XXX: I'm too lazy to do these correctly, for now.  Feel free to
   come flame me for forgetting to implement them later. */
#define isinf(x) (0)
#define isnan(x) (0)
#endif

char _curses_prntscan_rcsid[] = "@(#)prntscan.c   v.1.4  - 900114";

static	int	pblen(void);		/* gets length of buffer */

static	char	printscanbuf[513];	/* buffer used during I/O */

extern char *strncpy(char *dest, const char *src, size_t maxlen);

/*
 *	This routine actually executes the printf and adds it to the window
 *
 *	This is really a modified version of "sprintf".  As such,
 * it assumes that sprintf interfaces with the other printf functions
 * in a certain way.  If this is not how your system works, you
 * will have to modify this routine to use the interface that your
 * "sprintf" uses.
 */
void
__snprintf(unsigned char *str, int size, const char *fmt, va_list args)
{
	
# if defined(sun) || defined(__HIGHC__) || defined(__WATCOMC__)
    vsprintf(str, fmt, args);
# else

    FILE	junk;

    junk._flag = _IOWRT + _IOSTRG;
    junk._base = junk._ptr = str;
#if !defined(__HIGHC__) && !defined(__BORLANDC__)
    junk._bufsiz = size-1;
#endif
#if defined(__BORLANDC__)
    junk.level = 0;
#endif
    junk._cnt = size-1;
    junk._file = -1;

# if defined(sun) || defined(__HIGHC__) || defined(__BORLANDC__) || defined(_WIN32)
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
#endif
}

void
ntcCellsToChars(unsigned char *result, ntcCell *from, int units)
{
    int i;

    for(i=0; i < units; i++) {
	result[i] = from[i].uniChar;
    }
}

void
charsToNtcCells(ntcCell *result, unsigned char *from, int units)
{
    int i;

    for(i=0; i < units; i++) {
	(void *)makeNtcCell(&result[i], from[i]);
    }
}

int
strlenWide(ntcCell *str)
{
    int i;

    i = 0;
    while (str[i].uniChar != (unsigned short)0) {
	i++;
    }

    return i;
}

void
__snprintfWide(ntcCell *str, int size, const char *fmt, va_list args)
{
    unsigned char *str2;
    int  units;

    units = size/sizeof(ntcCell);

    str2 = (unsigned char *)malloc(units * sizeof(unsigned char));

    __snprintf(str2, units, fmt, args);

    charsToNtcCells(str, str2, units);

    free(str2);
}

int
_sprintw(WINDOW *win, const char *fmt, va_list args)
{
    unsigned char  	string[512];	/* Place for formatting things */
    char 	    	cfmt[64];   	/* Place to which to copy the format*/
    register const char	*cp;	    	/* Current position in fmt */
    const char		*cpStart;   	/* Start of unprocessed part of fmt */
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
		__snprintf(string, sizeof(string), cfmt, args);
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
		__snprintf(string, sizeof(string), cfmt, args);
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
		__snprintf(string, sizeof(string), cfmt, args);
		waddstr(win, string);
		break;
	    case 'c':
		(void)va_arg(nextArgs, int);
	    case '%':
		cp++;
		strncpy(cfmt, cpStart, cp-cpStart);
		cfmt[cp-cpStart] = '\0';
		__snprintf(string, sizeof(string), cfmt, args);
		waddstr(win, string);
		break;

	    case 's':
		cp++;
		if ((args == nextArgs) && !fancy) {
		    unsigned char *s = va_arg(nextArgs, unsigned char *);
		    waddstr(win, s);
		} else {
		    /*
		     * XXX: Should worry about length here, but what
		     * the heck?
		     */
		    strncpy(cfmt, cpStart, cp-cpStart);
		    cfmt[cp-cpStart] = '\0';
		    (void)va_arg(nextArgs, char *);
		    __snprintf(string, sizeof(string), cfmt, args);
		    waddstr(win, string);
		}
		break;
	    }
	    cpStart = cp;
	    va_copy(args, nextArgs);
	}
    }
    waddstr(win, (unsigned char *)cpStart);
    return TRUE;
}

/*
 * strncpyWide()
 * helper function to copy wide strings
 */
ntcCell *
strncpyWide(ntcCell *dest, ntcCell *src, int len)
{
    ntcCell *start = dest;
    ntcCell zeroCell;

    makeNtcCell(&zeroCell, '\0');

    while(len != 0) {
	setNtcCell(dest, src);
	if (sameNtcCell(dest, &zeroCell) == TRUE) {
	    return start;
	}
	dest++;
	src++;
	len--;
    }
    return start;
}

int
_sprintwWide(WINDOW *win, char *fmt, va_list args)
{
    unsigned char  	string[512];	/* Place for formatting things */
    ntcCell    	  	stringWide[512];/* Place for formatting things */
    char    	    	cfmt[64];   	/* Place to which to copy the format*/
    register char	*cp;	    	/* Current position in fmt */
    char		*cpStart;   	/* Start of unprocessed part of fmt */
    char**		nextArgs;   	/* End of args for current char */
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
		__snprintf(string, sizeof(string), cfmt, args);
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
		__snprintf(string, sizeof(string), cfmt, args);
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
		__snprintf(string, sizeof(string), cfmt, args);
		waddstr(win, string);
		break;
	    case 'c':
		(void)va_arg(nextArgs, int);
	    case '%':
		cp++;
		strncpy(cfmt, cpStart, cp-cpStart);
		cfmt[cp-cpStart] = '\0';
		__snprintf(string, sizeof(string), cfmt, args);
		waddstr(win, string);
		break;

	    case 's':
		cp++;
		if ((args == nextArgs) && !fancy) {
		    ntcCell *s = va_arg(nextArgs, ntcCell *);
		    waddstrWide(win, s);
		} else {
		    /*
		     * XXX: Should worry about length here, but what
		     * the heck?
		     */
		    strncpy(cfmt, cpStart, cp-cpStart);
		    cfmt[cp-cpStart] = '\0';
		    (void)va_arg(nextArgs, ntcCell *);
		    __snprintfWide(stringWide, sizeof(stringWide), cfmt, args);
		    waddstrWide(win, stringWide);
		}
		break;
	    }
	    cpStart = cp;
	    args = nextArgs;
	}
    }
    waddstr(win, (unsigned char *)cpStart);
    return TRUE;
}

#if 0
/*
 * version that had the format string in wide format
 */
int
_sprintwWide(WINDOW *win, ntcCell *fmt, va_list args)
{
    ntcCell    	  	string[512];	/* Place for formatting things */
    ntcCell    	    	cfmt[64];   	/* Place to which to copy the format*/
    register ntcCell	*cp;	    	/* Current position in fmt */
    ntcCell		*cpStart;   	/* Start of unprocessed part of fmt */
    va_list		nextArgs;   	/* End of args for current char */
    bool 	  	fancy;
    ntcCell		temp;

    cpStart = cp = fmt;

    while (sameNtcCell(cp, makeNtcCell(&temp, '\0')) == FALSE) {
	if (sameNtcCell(cp, makeNtcCell(&temp, '%')) == FALSE) {
	    cp++;
	} else {
	    while (cpStart != cp) {
		waddchWide(win, cpStart++);
	    }
	    cp++;
	    nextArgs = args;
	    fancy = FALSE;
	charswitch:
	    switch(cp->uniChar) {
	    case (unsigned short)'*':
		/*
		 * Argument specifies width -- pop it now
		 */
		(void)va_arg(nextArgs, int);
		fancy = TRUE;
	    case (unsigned short)'+':
	    case (unsigned short)'-':
	    case (unsigned short)' ':
	    case (unsigned short)'#':
	    case (unsigned short)'.':
	    case (unsigned short)'l':
	    case (unsigned short)'h':
		cp++;
		fancy = TRUE;
		goto charswitch;
	    case (unsigned short)'0':
	    case (unsigned short)'1':
	    case (unsigned short)'2':
	    case (unsigned short)'3':
	    case (unsigned short)'4':
	    case (unsigned short)'5':
	    case (unsigned short)'6':
	    case (unsigned short)'7':
	    case (unsigned short)'8':
	    case (unsigned short)'9':
		cp++;
		while (isdigit(cp->uniChar)) {
		    cp++;
		}
		fancy = TRUE;
		goto charswitch;

	    case (unsigned short)'d':
		cp++;
		strncpyWide(cfmt, cpStart, cp-cpStart);
		(void *)makeNtcCell(&(cfmt[cp-cpStart]), '\0');
		(void)va_arg(nextArgs, int);
		__snprintfWide(string, sizeof(string), cfmt, args);
		waddstrWide(win, string);
		break;

	    case (unsigned short)'u':
	    case (unsigned short)'o':
	    case (unsigned short)'X':
	    case (unsigned short)'x':
		cp++;
		strncpyWide(cfmt, cpStart, cp-cpStart);
		(void *)makeNtcCell(&(cfmt[cp-cpStart]), '\0');
		(void)va_arg(nextArgs, unsigned int);
		__snprintfWide(string, sizeof(string), cfmt, args);
		waddstrWide(win, string);
		break;

	    case (unsigned short)'E':
	    case (unsigned short)'e':
	    case (unsigned short)'f':
	    case (unsigned short)'G':
	    case (unsigned short)'g':
		cp++;
		strncpyWide(cfmt, cpStart, cp-cpStart);
		(void *)makeNtcCell(&(cfmt[cp-cpStart]), '\0');
		(void)va_arg(nextArgs, double);
		__snprintfWide(string, sizeof(string), cfmt, args);
		waddstrWide(win, string);
		break;
	    case (unsigned short)'c':
		(void)va_arg(nextArgs, int);
	    case (unsigned short)'%':
		cp++;
		strncpyWide(cfmt, cpStart, cp-cpStart);
		(void *)makeNtcCell(&(cfmt[cp-cpStart]), '\0');
		__snprintfWide(string, sizeof(string), cfmt, args);
		waddstrWide(win, string);
		break;

	    case (unsigned short)'s':
		cp++;
		if ((args == nextArgs) && !fancy) {
		    ntcCell *s = va_arg(nextArgs, ntcCell *);
		    waddstrWide(win, s);
		} else {
		    /*
		     * XXX: Should worry about length here, but what
		     * the heck?
		     */
		    strncpyWide(cfmt, cpStart, cp-cpStart);
		    (void *)makeNtcCell(&(cfmt[cp-cpStart]), '\0');
		    (void)va_arg(nextArgs, char *);
		    __snprintfWide(string, sizeof(string), cfmt, args);
		    waddstrWide(win, string);
		}
		break;
	    }
	    cpStart = cp;
	    args = nextArgs;
	}
    }
    waddstrWide(win, cpStart);
    return TRUE;
}
#endif

/****************************************************************/
/* Printw(fmt,args) does a printf() in stdscr.			*/
/****************************************************************/

int
printw(char *fmt, double A1, double A2, double A3, double A4, double A5)
{
    sprintf(printscanbuf,fmt,A1,A2,A3,A4,A5);
    if(waddstr(stdscr,(unsigned char *)printscanbuf) == ERR)
	return(ERR);
    return(pblen());
} /* printw */

/****************************************************************/
/* Wprintw(win,fmt,args) does a printf() in window 'win'.	*/
/****************************************************************/
int
wprintw(WINDOW *win, char *fmt, ...)
{
    va_list	args;
    int		res;

    va_start(args, fmt);
    res = _sprintw(win, fmt, args);
    va_end(args);
    return(res);
}

int
wprintwWide(WINDOW *win, char *fmt, ...)
{
    va_list	args;
    int		res;

    va_start(args, fmt);
    res = _sprintwWide(win, fmt, args);
    va_end(args);
    return(res);
}

/****************************************************************/
/* Mvprintw(fmt,args) moves the stdscr cursor to a new posi-	*/
/* tion, then does a printf() in stdscr.			*/
/****************************************************************/

int
mvprintw(int y, int x, char *fmt, double A1, double A2,
	 double A3, double A4, double A5)
{
    if (wmove(stdscr,y,x) == ERR)
	return(ERR);
    sprintf(printscanbuf,fmt,A1,A2,A3,A4,A5);

    if(waddstr(stdscr,(unsigned char *)printscanbuf) == ERR)
	return(ERR);
    return(pblen());
} /* mvprintw */

/****************************************************************/
/* Mvwprintw(win,fmt,args) moves the window 'win's cursor to	*/
/* a new position, then does a printf() in window 'win'.	*/
/****************************************************************/

int
mvwprintw(WINDOW *win, int y, int x, char *fmt,
	  double A1, double A2, double A3, double A4, double A5)
{
    if (wmove(win,y,x) == ERR)
	return(ERR);

    sprintf(printscanbuf,fmt,A1,A2,A3,A4,A5);

    if(waddstr(win, (unsigned char *)printscanbuf) == ERR)
	return(ERR);
    return(pblen());
} /* mvwprintw */

/****************************************************************/
/* Wscanw(win,fmt,args) gets a string via window 'win', then	*/
/* scans the string using format 'fmt' to extract the values	*/
/* and put them in the variables pointed to the arguments.	*/
/****************************************************************/

int
wscanw(WINDOW *win, char *fmt, double A1, double A2, double A3,
       double A4, double A5)
{
    wrefresh(win);				/* set cursor */
    if (wgetstr(win,printscanbuf) == ERR)		/* get string */
	return(ERR);
    return(sscanf(printscanbuf,fmt,A1,A2,A3,A4,A5));
} /* wscanw */

/****************************************************************/
/* Scanw(fmt,args) gets a string via stdscr, then scans the	*/
/* string using format 'fmt' to extract the values and put them	*/
/* in the variables pointed to the arguments.			*/
/****************************************************************/

int
scanw(char *fmt, double A1, double A2, double A3, double A4, double A5)
{
    wrefresh(stdscr);				/* set cursor */
    if (wgetstr(stdscr,printscanbuf) == ERR)	/* get string */
	return(ERR);
    return(sscanf(printscanbuf,fmt,A1,A2,A3,A4,A5));
} /* scanw */

/****************************************************************/
/* Mvscanw(y,x,fmt,args) moves stdscr's cursor to a new posi-	*/
/* tion, then gets a string via stdscr and scans the string	*/
/* using format 'fmt' to extract the values and put them in the	*/
/* variables pointed to the arguments.				*/
/****************************************************************/

int
mvscanw(int y, int x, char *fmt, double A1, double A2,
	double A3, double A4, double A5)
{
    if (wmove(stdscr,y,x) == ERR)
	return(ERR);
    wrefresh(stdscr);				/* set cursor */
    if (wgetstr(stdscr,printscanbuf) == ERR)	/* get string */
	return(ERR);
    return(sscanf(printscanbuf,fmt,A1,A2,A3,A4,A5));
} /* mvscanw */

/****************************************************************/
/* Mvwscanw(win,y,x,fmt,args) moves window 'win's cursor to a	*/
/* new position, then gets a string via 'win' and scans the	*/
/* string using format 'fmt' to extract the values and put them	*/
/* in the variables pointed to the arguments.			*/
/****************************************************************/

int
mvwscanw(WINDOW *win, int y, int x, char *fmt,
	 double A1, double A2, double A3, double A4, double A5)
{
    if (wmove(win,y,x) == ERR)
	return(ERR);
    wrefresh(win);				/* set cursor */
    if (wgetstr(win,printscanbuf) == ERR)		/* get string */
	return(ERR);
    return(sscanf(printscanbuf,fmt,A1,A2,A3,A4,A5));
} /* mvwscanw */

/****************************************************************/
/* Pblen() returns the length of the string in printscanbuf.	*/
/****************************************************************/

static	int
pblen(void)
{
    char *p = printscanbuf;

    while(*p++);
    return((int) (p - printscanbuf - 1));
} /* plben */
