/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Curses-windowed User Interface
 * FILE:	  curses.c
 *
 * AUTHOR:  	  Adam de Boor: Dec  7, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	beep	    	    Make a noise
 *	read-line   	    Read a line of input/a command, optionally
 *	    	    	    initializing input buffer to contain something
 *	read-char   	    Read a single character from the user, echoed
 *	    	    	    or not.
 *	save	    	    Set size of scroll buffer, or write the whole
 *	    	    	    thing out to a file.
 *	echo	    	    Produce output
 *	system	    	    Execute a command, giving it controll of the
 *	    	    	    terminal.
 *	wcreate	    	    Create a new window.
 *	wdelete	    	    Delete a window
 *	wpush	    	    Push to another window for I/O purposes
 *	wpop	    	    Return to previous window
 *	winverse    	    Turn on inverse mode in current window
 *	wmove	    	    Move to a certain coordinate in the current
 *	    	    	    window (relative or absolute)
 *	wclear	    	    Clear the current window.
 *	wrefresh    	    Make sure current window is in sync with
 *	    	    	    display.
 *	wtop	    	    Tell whether to create windows on top or
 *	    	    	    bottom of screen.
 *	Curses_Init 	    Initialize the module, if possible.
 *	scroll	    	    Scroll a window nicely, saving nuked line
 *	    	    	    in scroll buffer if window is main one.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	12/ 7/88  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to implement a windowed user-interface using curses.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: curses.c,v 4.38 97/04/18 15:09:19 dbaumann Exp $";
#endif lint

#include <config.h>
#include <compat/stdlib.h>
#include "swat.h"
#include "buf.h"
#include "cmd.h"
#include "event.h"
#include "file.h"
#include "rpc.h"
#include "ui.h"
#include "mouse.h"
#include "src.h"
#include "shell.h"
#include "cmdNZ.h"
#ifdef _LINUX
#include <sys/ioctl.h>
#include <curses/curses.h>
#include <termios.h>

#define TIOCGETP        0x7408
#define TIOCSETP        0x7409
#define TIOCSETN        0x740a          /* TIOCSETP wo flush */
#define TIOCGLTC    0x7474          /* get special local chars */
#define TIOCSLTC    0x7475          /* set special local chars */

#define SWATWCTL_FOCUS		"swatwctl focus >/dev/null 2>&1"
#define SWATWCTL_RESTORE	"swatwctl restore >/dev/null 2>&1"

#else
#include <ntcurses/curses.h>
#endif
#include <compat/file.h>

#if defined(_WIN32)
# include <curspriv.h>
#endif

#include <stdarg.h>
#include <ctype.h>
#include <signal.h>

#if defined(_MSDOS)
# include <bios.h>
# include <graph.h>
#endif

#if defined(unix)
static struct ltchars	ltc;	    	/* Original local terminal chars */
static char 	    	*BL;	    	/* Audible bell, if not ^G */
#endif

#if defined(_WIN32)
# define _y		_line		/* in the WINDOW structure */
# define _firstch	_minchng
# define _lastch	_maxchng
# define wgetestr wgetstr

# define AM TRUE             /* (autowrap on) is TRUE */
# define XN FALSE            /* (??? about newline) is FALSE */
# define NONL FALSE          /* (not do return after linefeed) is FALSE */
#endif

#if defined(_WIN32) || defined(__WATCOMC__)
#define WADDSTR_CAST unsigned char *
#else
#define WADDSTR_CAST char *
#endif

/*
 * NT curses has a four byte representation of a character (unicode + attr)
 */

#if !defined(_WIN32)
typedef char		cursesChar;
# define EQUAL_CHARS(c1, c2)	 	((c1) == (c2))
# define ASSIGN_CHAR_W_CONST(res, val) 	((res) = (val))
# define ASSIGN_CHAR_W_VAR(res, val) 	((res) = (val))
# define WPRINTW 			wprintw
#else	/* now the WIN32 version */
typedef ntcCell		cursesChar;	/* defined in ntcurses/curses.h */
# define EQUAL_CHARS(ntc, c) 	       (((ntc).uniChar) == (unsigned short)(c))
# define ASSIGN_CHAR_W_VAR(ntcRes, val) 	setNtcCell(&(ntcRes), &(val))
# define ASSIGN_CHAR_W_CONST(ntcRes, val) makeNtcCell(&(ntcRes), (val))
# define WPRINTW 			wprintwWide
#endif

#if defined(_WIN32) || defined(__WATCOMC__)
extern  int	_sprintw(WINDOW *win, const char *fmt, va_list args);
# define _putchar(c) putchar(c)  /* not used in WIN32 */
#else
extern int  	    	_putchar(char c);
#endif
extern int wprintw(WINDOW *win, char *fmt, ...);

static char 	    	backPage,   	/* Character to go back a page */
			forwPage,   	/* Ditto to go forward a page */
			backHPage,  	/* Ditto to go backward a half page */
			forwHPage,  	/* Ditto to go forward a half page */
			backLine,   	/* Ditto to go backward a line */
			forwLine,   	/* Ditto to go forward a line */
			redraw;	    	/* Redraw entire screen */

#define NUM_CLE_CHARS 11
#define CLEC_BEGINNING_OF_LINE 0
#define CLEC_END_OF_LINE 1
#define CLEC_BACKWARD_CHAR 2
#define CLEC_FORWARD_CHAR 3
#define CLEC_BACKWARD_WORD 4
#define CLEC_FORWARD_WORD 5
/* There's no CLEC_BACK_DELETE_CHAR, it's just backspace */
#define CLEC_FORWARD_DELETE_CHAR 6
/* There's no CLEC_BACK_DELETE_WORD, it's just ctrl-w */
#define CLEC_FORWARD_DELETE_WORD 7
#define CLEC_KILL_REGION 8
#define CLEC_YANK 9
#define CLEC_KILL_LINE 10

/*
 * Current input handler function
 */
typedef struct _CursesInputState {
    const char	*endChars;  	    /* Characters that cause immediate
				     * return*/
    const char	*wordChars; 	    /* Characters that delineate words */
    char	cleChars[NUM_CLE_CHARS+1];
    	    	    	    	    /* Command-line editing chars in force */
    void    	(*inProc)(unsigned char c, struct _CursesInputState *state);
    Buffer  	input;	    	    /* Current input */
    int	    	lineLength; 	    /* Length of current line(from buffer
				     * start or most-recent newline) */
    int  	cursPos; 	    /* Cursor's position within the current
				     * line */
    int  	markPos; 	    /* Mark's position within the current
				     * line */
    int	    	flags;
#define CISF_LINEREADY      1	    /* Line waiting for pickup */
#define CISF_READCMD	    2	    /* Reading a command, so brackets/braces
				     * must be balanced before the line's
				     * done */
    struct _CursesInputState *next; /* Next in stack of input stuff */
} CursesInputState;

static CursesInputState	*inStateTop = 0;

static char defEndChars[] = "";
static char defWordChars[] = " \t";
static char defCleChars[NUM_CLE_CHARS] = "aebfrvdtkyu";

/*
 * Scroll buffer definitions
 */
typedef struct _line {
    cursesChar 	    *line;  	/* The buffered line itself */
    struct _line    *next;  	/* Next in the queue */
    struct _line    *prev;  	/* Previous in the queue */
} LineRec, *LinePtr;
#define NullLine    ((LinePtr)NULL)

static LinePtr	lineHead;   	/* Head of scroll buffer */
static LinePtr	lineTail;   	/* Tail of the scroll buffer */
static LinePtr	lineCur;    	/* Line at the top of the window if we've
				 * scrolled backwards. NULL if we've not */
static int  	numSaved;   	/* Number of saved lines */
static int  	maxSaved=1000;	/* Maximum number of lines saved in the
				 * scroll buffer. */
static cursesChar	*junkLine=NULL; 	/* Junk line for scrolling purposes */

/*
 * Window-stack.
 */
static Lst	windowStack;	/* Stack of windows we've switched to */
static Lst  	windows;    	/* Known windows (other than cmdWin and
				 * borderWin) */
static WINDOW	*curWin;    	/* Current window */
static WINDOW	*cmdWin;    	/* Main I/O window */
static WINDOW	*borderWin; 	/* Border between I/O and display windows.
				 * Only active if !Lst_IsEmpty(windows) */
#define MIN_CMD_HEIGHT	5   	/* Minimum height of the I/O window */
static Boolean	windowsOnTop;	/* TRUE if allocated windows should go at the
				 * top of the screen */

/*
 * Other state
 */
static int	cursesFlags;	/* State-flags for interface */
#define CURSES_ECHO 	    4	    /* Echo characters as they're read */


static Buffer   cutBuf = NULL;         /* Place to store cut lines & words */
static int  	cutLength; 	/* Length of current cut item */

static void CursesInputChar(unsigned char c, CursesInputState *state);
		    	    	/* Forward declaration */
static int CursesNumColumns(void);

static char *keyBindings[256];
char wrongNumArgsString[] = "%s called with wrong number of arguments";

#if defined(_MSDOS)
typedef struct _highlightInfo {
    int	    	scroll_mode;	/* sees if we are scrolling around or not */
    int    	partly_on_screen;  	/* used in CursesUpdateHighlight */
    int	    	active;	    	/* non-zero if interesting things are afoot */
    int	    	on_screen_height; /* how many lines are still on screen */
    LinePtr 	firstline;  	/* first line of highlighted region */
    int	    	first_offset;	/* offset into first line */
    LinePtr 	lastline;   	/* last line of highlighted region */
    int	    	last_offset; 	/* offset into first line */
} HighlightInfo;

static HighlightInfo	highlightinfo;

#define ON  1
#define OFF 0
#define SAVE 1
#define REMOVE 0

#endif

void  CursesInsertHighlightInfoText(void);

#if defined(_MSDOS)
static void  CursesInsertMouseHighlightText(void);
static char *CursesGetMouseHighlight(int *value1, int *value2);
#endif /* _MSDOS */

static void CursesScrollInput(unsigned char c, CursesInputState *state);
static void CursesEndScroll(CursesInputState *state);
extern DosInvertScreenRegion(short start, short end);
extern DosCopyScreenRegion(char *buf, short start, short end);

#if defined(unix)

/***********************************************************************
 *				CursesTstp
 ***********************************************************************
 * SYNOPSIS:	    Copy of curses 'tstp' function that also resets
 *	    	    ltchars.
 * 	    	    From	    @(#)tstp.c	5.1 (Berkeley) 6/7/85
 * CALLED BY:	    UNIX on SIGTSTP receipt
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 9/88	Initial Revision
 *
 ***********************************************************************/
static void
CursesTstp(void)
{
#ifndef _LINUX
    struct sgttyb   osgb;
    struct ltchars  oltc;
#endif
    int	omask;

#ifndef _LINUX
    osgb = _tty;
#endif
    mvcur(0, COLS - 1, LINES - 1, 0);
    endwin();
    /*
     * Restore ltchars too (dsuspc...)
     */
#ifndef _LINUX
    ioctl(_tty_ch, TIOCGLTC, &oltc);
    ioctl(_tty_ch, TIOCSLTC, &ltc);
#endif

    fflush(stdout);

    /* reset signal handler so kill below stops us */
    signal(SIGTSTP, SIG_DFL);

    /* Unblock the signal */
#define	mask(s)	(1 << ((s)-1))
    omask = sigsetmask(sigblock(0) &~ mask(SIGTSTP));

    /* Redeliver it */
    kill(getpid(), SIGTSTP);

    /* Block it again*/
    sigblock(mask(SIGTSTP));

    /* Reset signal handler to us for next time... */
    signal(SIGTSTP, CursesTstp);

    /* Reset terminal modes to what we want */
#ifndef _LINUX
    _tty = osgb;
    ioctl(_tty_ch, TIOCSETN, &_tty);
    ioctl(_tty_ch, TIOCSLTC, &oltc);
#endif

    /* Redisplay the screen */
    wrefresh(curscr);
}
#endif

#if defined(_MSDOS)
#define	scrollnow_hideMouse(win, lines) (Mouse_HideCursor(),scrollnow(win,lines),Mouse_ShowCursor())
#else
#define scrollnow_hideMouse(win, lines) scrollnow(win, lines)
#endif

#if defined(_MSDOS)

/*********************************************************************
 *			CursesInsertHighlightedTextCmd
 *********************************************************************
 * SYNOPSIS: 	    	get the highlighted text into the command line
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:	    	this is a toughy...
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	2/25/93		Initial version
 *
 *********************************************************************/
DEFCMD(insert-highlighted-text,CursesInsertHighlightedText,TCL_EXACT,NULL,swat_prog.mouse,
"")
{
    /*
     * Ok, either we have text highlighted off-screen, on-screen or both
     */
    if (highlightinfo.active == 0)
    {
	CursesInsertMouseHighlightText();
	return;
    }
    if (highlightinfo.scroll_mode)
    {
	CursesEndScroll(inStateTop);
    }
    /*
     * Let's see if the stuff in highlightinfo is above, below or on the
     * screen.
     * If we are in scroll mode, then all the highlighted stuff must be
     * in the highlightinfo
     */
    CursesInsertHighlightInfoText();
    if (highlightinfo.scroll_mode == 1)
    {
	return;
    }

    CursesInsertMouseHighlightText();
    return;
}

/*********************************************************************
 *			CursesInsertMouseHighlightText
 *********************************************************************
 * SYNOPSIS: 	    insert text from video memory
 * CALLED BY:       CursesInsertHighlightedText
 * RETURN:          nothing
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	2/25/93		Initial version
 *
 *********************************************************************/
static void
CursesInsertMouseHighlightText(void)
{
    int	    value1, value2;
    char    *hl, *text, *cp;

    hl = CursesGetMouseHighlight(&value1, &value2);

    if (hl != NULL)
    {
	/*
	 * Need one extra byte to null terminate it.
	 */
	text = (char *)malloc((value2 - value1)/2+1+1);
	cp = text;
	DosCopyScreenRegion(text, value1, value2);
	text[(value2-value1)/2+1] = '\0';
	while(*cp)
	{
	    (* inStateTop->inProc)(*cp++, inStateTop);
	}
	free(text);
    }
}

/*********************************************************************
 *			CursesInsertHighlightInfoText
 *********************************************************************
 * SYNOPSIS: 	    	insert the text from the highlightinfo
 * CALLED BY:	    	CursesInsertHighlightedText
 * RETURN:              nothing
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	2/25/93		Initial version
 *
 *********************************************************************/
static void
CursesInsertHighlightInfoText(void)
{
    LinePtr	lp;

    lp = highlightinfo.firstline;

    while (lp != NULL)
    {
	char    *cp;
	int    	length;

	cp = lp->line;
	length = strlen(cp);
	/*
	 * If it's the first or last line then we may not need the
	 * whole line.
	 */
	if (lp == highlightinfo.firstline)
	{
	    cp += highlightinfo.first_offset/2;
	    length -= highlightinfo.first_offset/2;
        }
	if (lp == highlightinfo.lastline)
	{
	    length -= ((CursesNumColumns()<<1)-highlightinfo.last_offset)/2;
	    length++;
	}
	while (--length)
	{
	    (* inStateTop->inProc)(*cp++, inStateTop);
	}
	if (lp == highlightinfo.lastline)
	{
	    break;
	}
	lp = lp->prev;
    };

}

/*********************************************************************
 *			CursesClearHighlightInfoCmd
 *********************************************************************
 * SYNOPSIS:        clear out the highlightinfo variable
 * CALLED BY:	    tcl
 * RETURN:          nothing
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	2/23/93		Initial version
 *
 *********************************************************************/
DEFCMD(clear-highlightinfo,CursesClearHighlightInfo,TCL_EXACT,NULL,swat_prog.mouse,
"Usage:\n\
    clear-highlightinfo\n\
\n\
Synopsis:\n\
    clears out the C data structure for highlightinfo (INTERNAL USE ONLY)\n\
\n\
See also:\n\
    none.\n\
")
{
    if (argc != 1)
    {
	Tcl_RetPrintf(interp, wrongNumArgsString, argv[0]);
	return TCL_ERROR;
    }
    highlightinfo.firstline = NULL;
    highlightinfo.lastline = NULL;
    highlightinfo.on_screen_height = 0;
    highlightinfo.partly_on_screen = 0;
    highlightinfo.active = 0;

    return TCL_OK;
}

/*********************************************************************
 *			CursesGetMouseHighlight
 *********************************************************************
 * SYNOPSIS: 	    get values from mouse_highlight TCL variable
 * CALLED BY:
 * RETURN:  	    pointer to string if mouse_highlight is non-null,
 *	    	    value1 and value are the two elements that make up
 *	    	    mouse_highlight conveniently swapped into ascending
 *	    	    order if not already so by chance...
 *	    	    else NULL if mouse_highlight is a null value
 *
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	2/24/93		Initial version
 *
 *********************************************************************/
static char *
CursesGetMouseHighlight(int *value1, int *value2)
{
    char    **argv; 	    	/* argv, argc used for Tcl_SplitList() */
    int     argc;
    char    *hl;

    hl = (char *)Tcl_GetVar(interp, "mouse_highlight", TRUE);
    if (hl[0] != '\0')
    {
    	Tcl_SplitList(interp, hl, &argc, &argv);
    	*value1 = atoi(argv[0]);
    	*value2 = atoi(argv[1]);
	if (*value1 > *value2)
	{
	    *value1 = *value2;
	    *value2 = atoi(argv[0]);
	}
    	free((malloc_t)argv);
	return hl;
    }
    return NULL;
}

/*********************************************************************
 *			CursesConvertMouseHighlightToCoords
 *********************************************************************
 * SYNOPSIS: 	    convert data from mouse_highlight to coordinates
 * CALLED BY:	    GLOBAL
 * RETURN:  	    values in passed in parameters, NULL if none
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	2/24/93		Initial version
 *
 *********************************************************************/
char *
CursesConvertMouseHighlightToCoords(int *startX,
				    int *startY,
				    int *endX,
				    int *endY)
{
    char    *hl;
    int	    value1, value2;

    hl = CursesGetMouseHighlight(&value1, &value2);
    if (hl == NULL)
    {
	return NULL;
    }

    *startY = value1 / (CursesNumColumns() << 1);
    *endY = value2 / (CursesNumColumns() << 1);
    *startX = value1 % (CursesNumColumns() << 1);
    *endX = value2 % (CursesNumColumns() << 1);
    return hl;
}

/*********************************************************************
 *			CursesUpdateScrolledHighlightCmd
 *********************************************************************
 * SYNOPSIS: 	    update a change in highlight status during a scroll
 * CALLED BY:	    TCL
 * RETURN:          nothing
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	2/24/93		Initial version
 *
 *********************************************************************/
DEFCMD(update-scrolled-highlight,CursesUpdateScrolledHighlight,TCL_EXACT,NULL,swat_prog.mouse,
"Usage:\n\
    update-scrolled-highlight\n\
\n\
Synopsis:\n\
    updates the highlightinfo from TCL\n\
\n\
See also:\n\
    none.\n\
")
{
    if (argc != 1)
    {
	Tcl_RetPrintf(interp, wrongNumArgsString, argv[0]);
	return TCL_ERROR;
    }

    /* since we are not in scroll mode this isn't relevant
     */
    if (highlightinfo.scroll_mode == 0)
    {
	return TCL_OK;
    }
    else
    {
	int 	startX, startY, endX, endY;
	LinePtr	lp;


	/* if the firstline == NULL then the user must have scrolled
	 * and then started highlighting stuff (the dweeb ;) so we must
	 * initialize our struct to reflect the new state of affairs
	 */
	if (CursesConvertMouseHighlightToCoords(&startX, &startY,
						&endX, &endY) == (char *)NULL)
	{
	    return TCL_OK;
	}
	lp = lineCur;	    /* points to top of screen */

	/* now just go through the linked list, as we get to
	 * the appropriate Y positions, stuff in the pointers
	 * startY always comes before endY...(it better or we're screwed)
	 */
	while (1)
	{
	    assert (lp != NULL);
	    if (startY == 0)
	    {
		highlightinfo.firstline = lp;
	    }
	    if (endY == 0)
	    {
		highlightinfo.lastline = lp;
		break;
	    }
	    --startY;
	    --endY;
	    lp = lp->prev;
	}
	highlightinfo.on_screen_height = endY - startY + 1;
	highlightinfo.active = 1;
	highlightinfo.first_offset = startX;
	highlightinfo.last_offset = endX;
    }

    return TCL_OK;
}


/*********************************************************************
 *			CursesUpdateHighlight
 *********************************************************************
 * SYNOPSIS: 	update the highlight global tcl variable to reflect reality
 * CALLED BY:	global
 * RETURN:  	nothing
 * SIDE EFFECTS: puts correct value into TCL variable mouse_highlight
 * STRATEGY:	lines can mean two things:
 *                  in scroll mode, lines is normally zero; the only time
 *                  it's non-zero is when we are finishing up scroll mode,
 *                  in which case it's the starting Y position of the
 *	    	    highlighted region on the screen
 *
 *	    	    when not in scroll mode, lines is the number of lines
 *	    	    that the command line is scrolled
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	2/17/93		Initial version
 *
 *********************************************************************/
static void
CursesUpdateHighlight(int lines)
{
    int	    value1, value2; 	/* original values from mouse_highlight */
    int	    minvalue;	    	/* min (value1, value2) */
    int	    maxvalue;	    	/* max (value1, value2) */
    int	    columns, row_bytes; /* number of columns, and bytes in a row */
    char    *hl;
    int     startY, endY;	    /* start and end Y coordinates */
    int     startX, endX;	    /* start and end X coordinates */

    /*
     * If the highlight is stored in the mouse_highlight tcl variable...
     */
    if (CursesConvertMouseHighlightToCoords(&startX, &startY,
					    &endX, &endY) != (char *) NULL) {
	/*
	 * ...then check if it's in the command window; if not, we have
	 * nothing to do.
	 */
	if ((startY >= cmdWin->_maxy) || (endY < cmdWin->_begy))
	    return;
    }

    /*
     * 2 bytes be character in the frame buffer, so the number of bytes
     * in a row is the number of columns * 2
     */
    columns = CursesNumColumns();
    row_bytes = (columns << 1);

    /*
     * If we've been scrolling...
     */
    if (highlightinfo.scroll_mode)
    {
	LinePtr lp=NULL;
	int 	ypos=0;     	    /* y position on the screen */
	int 	vidStart, vidEnd;   /* video memory start and end */

	/*
	 * ...but our highlight is all onscreen, we leave in delight.
	 */
	if (!highlightinfo.active)
	{
	    return;
	}

	/*
	 * Our highlight is currently at least partly offscreen, so we
	 * investigate further.
	 */
	if (highlightinfo.firstline == NULL)
	{
	    /* one way to get here is when the user is
	     * scrolling around and then hit some other key so that
	     * the scroll buf goes back to the non-scroll mode and
	     * the screen is brought back to the command line, and the
	     * entire highlighted region got moved back entirely onto
	     * the screen, so just figure out the new screen coordinates
	     * of the highlighted region
	     * in this case, lines tells us how far onto the screen we
	     * got, if lines is zero, then we didn't get onto the screen
	     * so get outa town
	     */
	    highlightinfo.active = 0;	/* no longer active */
	    if (lines)
	    {
	    	ypos = lines-1;
	    }
	    else
	    {
		return;
	    }
	}
	else
	{
	    /* let's see if the region will end up on the screen
	     */
	    lp = lineCur;

	    while (lp != NULL && lp != highlightinfo.lastline &&
		       	     lp != highlightinfo.firstline)
	    {
		lp = lp->prev;
		ypos++;
	    }
	    if (ypos >= cmdWin->_maxy || lp == NULL)
		{
		    /* didn't make it, oh well
		     */
		    return;
		}
	}

	/* so at least part of the thing needs to be highlighted
	 * all we need to do is set up the mouse_highlight variable
	 * and everything should just work...
	 * to do this, we must figure out the screen coordinates
	 * that need to be lit up
	 * if we found the firstline, then go forward until we
	 * find the secondline, otherwise the firstline must be
	 * off the screen

	 * if lines is non-zero then lines tells us where to start
	 * the region and we know that the whole region is on the
	 * screen, so just use its height to figure out endY
	 */
	startY = endY = ypos;
	if (lines)
	{
	    startY = ypos;
	    endY = startY + highlightinfo.on_screen_height;
	}
	else
	{
	    if (lp == highlightinfo.firstline)
	    {
	    	while (endY < cmdWin->_maxy &&
		       lp != highlightinfo.lastline)
	    	{
		    endY++;
		    lp = lp->prev;
	    	}
	    }
	    else
	    {
	    	startY = 0;
	    }
	}

	/* ok we have the starting and ending Y values, now let's get
	 * the X values
	 */
	startX = highlightinfo.first_offset;
	endX = highlightinfo.last_offset;
	vidStart = (startY * row_bytes) + startX;
	vidEnd = (endY * row_bytes) + endX;
	Mouse_SetMouseHighlight(vidStart, vidEnd);
	return;
    }	/* if scroll mode and not already on the screen */

    /*
     * If we get here, we have not been scrolling, which means if there's
     * any highlight it must be indicated by the mouse_highlight variable.
     */
    hl = CursesGetMouseHighlight(&value1, &value2);
    if (hl == NULL)
    {
	/*
	 * There is no highlight.
	 */
	return;
    }

    value2 -= row_bytes * lines;
    value1 -= row_bytes * lines;
    minvalue = value1;
    maxvalue = value2;

    /* if the thing is completely off the screen and was off the
     * the screen then do nothing
     */
    if (maxvalue < 0 && highlightinfo.partly_on_screen == 0)
    {
	Tcl_SetVar(interp, "mouse_highlight", "", TRUE);
	return;
    }

    if (minvalue < 0)
    {
	LinePtr	lp=lineCur;
	LinePtr lptemp=NULL;
	int 	height;

	height = (maxvalue - minvalue)/row_bytes + 1;
	minvalue += row_bytes;
	value1 = 0;
	if (highlightinfo.firstline == NULL)
	{
	    highlightinfo.active = 1;
	    /* ok this is our first step off the screen for the highlighted
	     * region, set up all the relevant info
	     */
	    if (lp == NULL)
	    {
	    /* if lp is NULL then we have not yet started to scroll around
	     */
	    	lp = lineHead;
	    }
	    else
	    {
	    	/* get us just off screen
		 */
	    	lp = lp->next;
	    }
	    /* figure out offset of the first line, since we start at one off
	     * the screen, we move up minvalue by one line
	     */
	    while (minvalue < 0 && lp != NULL)
	    {
	    	lp = lp->prev;
	    	minvalue += row_bytes;
	    }
	    highlightinfo.firstline = lp;
	    highlightinfo.first_offset = minvalue % row_bytes;
	    while (height > 0 && lines > 0 && lp != NULL)
	    {
	    	lptemp = lp;   	/* remember last one in case we go too far */
	    	lp = lp->next;
	    	--height;
		--lines;
	    }
	    /* ok, if we didn't get to the end, then some of the highlighted
	     * region is still on the screen, thus not in the line buffer
	     * so record that information so we can recreate the highlighted
	     * region correctly
	     */
	    highlightinfo.on_screen_height = height;
	    highlightinfo.last_offset = maxvalue % row_bytes;
	    if (lp == NULL || height > 0)
	    {
	    	highlightinfo.lastline = lptemp;
		highlightinfo.partly_on_screen = 1;
	    }
	    else
	    {
	    	highlightinfo.lastline = lp;
		highlightinfo.partly_on_screen = 0;
	    }
    	}
    	else /* highlightinfo.firstline != NULL case */
	{
	    int	deltaheight = 0;
	    /*
	     * ok, so we already have some of the highlighted region off
	     * screen, so just adjust the highlightinfo.lastline as the
	     * first line is not changing (I think)
	     */
	    lp = highlightinfo.lastline;
	    lp = lp->prev;

	    /* ok, then the remaining height should take us to the end
	     * of the highlighted region, if we run out of line buffers first
	     * then we have found the lastline field for our highlightinfo
	     */
	    while (height > 0 && lines > 0 && lp != NULL)
	    {
	    	lptemp = lp;   	/* remember last one in case we go too far */
	    	lp = lp->prev;
	    	--height;
		--lines;
		deltaheight++;
	    }
	    highlightinfo.lastline = lptemp;
	    if (height > 0)
	    {
		highlightinfo.partly_on_screen = 1;
	    }
	    else
	    {
		highlightinfo.partly_on_screen = 0;
		Tcl_SetVar(interp, "mouse_highlight", "", TRUE);
	    }
	    highlightinfo.on_screen_height -= deltaheight;
	}
    }

    if (minvalue > 0 || highlightinfo.partly_on_screen == 1)
    {
	Mouse_SetMouseHighlight(value1, value2);
    }
}

/*********************************************************************
 *			CursesUpdateNewMouseHighlight
 *********************************************************************
 * SYNOPSIS: 	    	updating stuff on the screen
 * CALLED BY:	    	CursesScrollInput
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	3/ 1/93		Initial version
 *
 *********************************************************************/
static void
CursesUpdateNewMouseHighlight(int lines)
{
    int 	value1, value2, xvalue, oldvalue1, oldvalue2;
    char	*hl;
    int		max_screen, row_bytes, i;
    int	    	forward = (lines > 0);
    LinePtr	lp, lineScreenEnd;
    int	    	chopped_height=0;
    int         startX, endX, startY, endY;

    assert(highlightinfo.scroll_mode != 0);

    /*
     * Leave things alone if there's no highlight or it's not in the
     * command window.
     */
    if (CursesConvertMouseHighlightToCoords(&startX, &startY,
					    &endX, &endY) == (char *) NULL)
	 return;
    if ((startY >= cmdWin->_maxy) || (endY < cmdWin->_begy))
	return;


    row_bytes = CursesNumColumns() << 1;
    hl = CursesGetMouseHighlight(&oldvalue1, &oldvalue2);
    lp = lineCur;
    max_screen = (cmdWin->_maxy * row_bytes) - 2;
    for (i = cmdWin->_maxy-1; i > 0; i--)
    {
	lp = lp->prev;
    }
    lineScreenEnd = lp;

    if (hl != NULL)
    {
    	value1 = oldvalue1 - lines * row_bytes;
    	value2 = oldvalue2 - lines * row_bytes;
	if (forward)
	{
	    /* if value2 is zero we just scrolled off the screen */
	    if (value2 < 0)
	    {
		highlightinfo.on_screen_height = 0;
		Tcl_SetVar(interp, "mouse_highlight", "", TRUE);
		return;
	    }
	    /* ok, if value1 < 0 then we are partially off the screen */
	    if (value1 < 0)
	    {
		chopped_height = (value1/row_bytes) - 1;
		value1 = 0;
	    }
	    if (oldvalue2 == max_screen)
	    {
		/* now we need to see if the thing is partially or
		 * totally on the screen
		 */

		lp = highlightinfo.firstline;
		highlightinfo.on_screen_height = chopped_height;
		while (lp != highlightinfo.lastline)
		{
		    highlightinfo.on_screen_height++;
		    if (lp == lineScreenEnd)
		    {
			break;
		    }
		    lp = lp->prev;
		}
		if (lp != lineScreenEnd)
		{
		    /* ok, we are totally on the screen
		     */
		    value2 = (value1/row_bytes) * row_bytes;
		    value2 += row_bytes * highlightinfo.on_screen_height;
		    value2 += highlightinfo.last_offset;
		}
		else
		{
		    if (lineScreenEnd == highlightinfo.lastline)
		    {
		    	value2 = max_screen - row_bytes + 2 +
			        	highlightinfo.last_offset;
		    }
		    else
		    {
		    	value2 = max_screen;
		    }
		}
	    }
	    Mouse_SetMouseHighlight(value1, value2);
	    xvalue = (cmdWin->_maxy - lines) * row_bytes;
	    DosInvertScreenRegion(xvalue, value2);
	    return;
	}

	/* ok we are going backwards, pretty similiar to forward */
	xvalue = max_screen;
	if (value1 > xvalue)
	{
	    /* we went right off the bottom so do nothing */
	    Tcl_SetVar(interp, "mouse_highlight", "", TRUE);
	    return;
	}
	if (value2 > xvalue)
	{
	    chopped_height = ((xvalue - value2)/row_bytes) - 1;
	    value2 = xvalue;
	}
	if (oldvalue1 == 0)
	{
	    lp = highlightinfo.lastline;
	    highlightinfo.on_screen_height = chopped_height;
	    while (lp != highlightinfo.firstline)
	    {
		highlightinfo.on_screen_height++;
		if (lp == lineCur)
		{
		    break;
		}
		lp = lp->next;
	    }

	    if (lp != lineCur)
	    {
		/* ok, we are totally on the screen
		 */
		value1 = (value2/row_bytes) * row_bytes;
		value1 -= row_bytes * highlightinfo.on_screen_height;
		value1 += highlightinfo.first_offset;
	    }
	    else
	    {
	    	if (lineCur == highlightinfo.firstline)
		{
	    value1 = highlightinfo.first_offset;
		}
		else
		{
		    value1 = 0;
		}
	    }
	}
	Mouse_SetMouseHighlight(value1, value2);
	xvalue = (-lines * row_bytes) - 2;
	DosInvertScreenRegion(value1, xvalue);
	return;
    }
    /* so we were completely off the screen, we need to make sure that
     * we didn't creep onto the screen
     */
    highlightinfo.on_screen_height = 0;
    if (forward)
    {
	lp = highlightinfo.lastline;
	while (lp != highlightinfo.firstline && lp != lineScreenEnd)
	{
	    lp = lp->next;
	}
	if (lp != lineScreenEnd)
	{
	    int	ypos = cmdWin->_maxy - 1;
	    /*
	     * Either we didn't get on the screen at all, or we got
	     * completely on the screen so we don't overlap the boundary
	     * so lets see if we are on the screen
	     */
	    lp = lineScreenEnd;
	    while (lp != NULL && lp != highlightinfo.lastline)
	    {
		lp = lp->next;
		--ypos;
	    }
	    if (lp == NULL || ypos < 0)
	    {
		/* ok we didn't make it, then return */
		return;
	    }
	    /* so ypos tells us the y position of the bottom, lets see
	     * if the top is still on the screen
	     */
	    highlightinfo.on_screen_height = 1;
	    while (lp != highlightinfo.firstline)
	    {
		highlightinfo.on_screen_height++;
		if (lp == lineCur)
		{
		    break;
		}
		lp = lp->next;
	    }
	    if (lp == highlightinfo.firstline)
	    {
		value1 = ((ypos - highlightinfo.on_screen_height + 1)
		    	* row_bytes) + highlightinfo.first_offset;
	    }
	    else
	    {
		value1 = 0;
	    }
	    value2 = (ypos * row_bytes) + highlightinfo.last_offset;
	}
	else
	{
	    int	height = 1;

	    /* ok, so we got to the first highlighted stuff on the screen
	     * so set up the mouse_highlight variable and set the
	     * on_screen_height
	     */
	    value1 = -1;
	    while (lp != highlightinfo.firstline)
	    {
		height++;
		lp = lp->next;
		if (lp == lineCur)
		{
		    highlightinfo.on_screen_height = 0;
		    value1 = 0;
		    break;
		}
	    }
	    highlightinfo.on_screen_height += height;
	    value2 = max_screen;
	    if (value1 == -1)
	    {
		value1 = (max_screen + 2) - (height * row_bytes);
		value1 += highlightinfo.first_offset;
	    }
	    if (highlightinfo.lastline == lineScreenEnd)
	    {
		value2 -= (row_bytes - highlightinfo.last_offset - 2);
	    }
	}
    }
    else  /* ok backwards case */
    {
	/* first, see if the we just moved partially on */
	lp = highlightinfo.firstline;
	while (lp != lineCur && lp != highlightinfo.lastline)
	{
	    lp = lp->prev;
	}
	if (lp != lineCur)
	{
	    int ypos=0;

	    /* ok, we either went all the way on, or not at all on */
	    lp = lineCur;
	    while (lp != highlightinfo.firstline && lp != NULL)
	    {
	    	ypos++;
		lp = lp->prev;
	    }
	    if (lp == NULL || ypos >= cmdWin->_maxy)
	    {
		/* didn't make it, sigh */
		return;
	    }
	    highlightinfo.on_screen_height = 1;
	    while (lp != highlightinfo.lastline)
	    {
		highlightinfo.on_screen_height++;
		lp = lp->prev;
		if (lp == lineScreenEnd)
		{
		    break;
		}
	    }
	    if (lp == highlightinfo.lastline)
	    {
		value2 = ((ypos + highlightinfo.on_screen_height - 1)
			  * row_bytes) + highlightinfo.last_offset;
	    }
	    else
	    {
		value2 = (cmdWin->_maxy * row_bytes) - 2;
	    }
	    value1 = (ypos * row_bytes) + highlightinfo.first_offset;
	}
	else
	{
	    int height = 1;

	    /* ok, so we got to the first highlighted stuff on the screen
	     * so set up the mouse_highlight variable and set the
	     * on_screen_height
	     */
	    value2 = -1;
	    while (lp != highlightinfo.lastline)
	    {
		height++;
		lp = lp->prev;
		if (lp == lineScreenEnd)
		{
		    highlightinfo.on_screen_height = 0;
		    value2 = (cmdWin->_maxy * row_bytes) - 2;
		    break;
		}
	    }
	    highlightinfo.on_screen_height += height;
	    value1 = 0;
	    if (value2 == -1)
	    {
		value2 = row_bytes * (highlightinfo.on_screen_height-1);
		value2 += highlightinfo.last_offset;
	    }
	    if (highlightinfo.firstline == lineCur)
	    {
		value1 += highlightinfo.first_offset;
	    }
	}
    }

    Mouse_SetMouseHighlight(value1, value2);
    DosInvertScreenRegion(value1, value2);
    return;
}

/*
 * end of _MSDOS - mouse and highlighting stuff
 */


/*********************************************************************
 *			CursesInvertScreenRegionCmd
 *********************************************************************
 * SYNOPSIS: 	    Invert a character on the screen
 * CALLED BY:	    TCL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	2/ 8/93		Initial version
 *
 *********************************************************************/
DEFCMD(invert-screen-region,CursesInvertScreenRegion,TCL_EXACT,NULL,swat_prog.mouse,
"INTERNAL\n\
Usage:\n\
    invert-screen-region <start> <end>\n\
\n\
Examples:\n\
    \"invert-screen-region 3 10\"	Inverts region from from 3 to 10.\n\
\n\
Synopsis:\n\
    Inverts a set of characters on the screen\n\
\n\
Notes:\n\
    * <start> and <end> are offsets within the character frame buffer. This\n\
      implies that only \"lines\" of characters may be inverted, not rect-\n\
      angles.\n\
\n\
See also:\n\
    none.\n\
")
{
    short start, end;

    if (argc != 3)
    {
	Tcl_RetPrintf(interp, wrongNumArgsString, argv[0]);
	return TCL_ERROR;
    }

    start = atoi(argv[1]);
    end = atoi(argv[2]);

    if ((start >= 0) && (end >= 0) && (start <= end))
	DosInvertScreenRegion(start, end);

    return TCL_OK;
}


/*********************************************************************
 *			CursesToggleHighlight
 *********************************************************************
 * SYNOPSIS: 	    Toggle the highlighted region on the screen
 * CALLED BY:	    CursesScrollInput
 * RETURN:          nothing
 * SIDE EFFECTS:    none
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jenny	6/28/93		Initial version
 *
 *********************************************************************/
static void
CursesToggleHighlight(int onOff, int saveRemove)
{
    int startX, endX, startY, endY;

    /*
     * Leave things alone if there's no highlight or it's not in the
     * command window.
     */
    if (CursesConvertMouseHighlightToCoords(&startX, &startY,
					    &endX, &endY) == (char *) NULL)
	 return;
    if ((startY >= cmdWin->_maxy) || (endY < cmdWin->_begy))
	return;
    /*
     * Toggle the highlighted region and clear out the return value
     * since we don't want it.
     */
    Tcl_Eval(interp, "unhighlight-mouse", 0, NULL);
    Tcl_Return(interp, NULL, TCL_STATIC);
    /*
     * Clear the mouse_highlight variable if appropriate.
     */
    if (onOff == OFF && saveRemove == REMOVE)
	Tcl_SetVar(interp, "mouse_highlight", "", TRUE);
}
#endif /* _MSDOS specific code */


/***********************************************************************
 *				scroll
 ***********************************************************************
 * SYNOPSIS:	    Usurpation of curses' own "scroll" routine to
 *	    	    implement the main window's scroll buffer.
 * CALLED BY:	    curses
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The top-most line is added to the line list and
 *	    	    a new one allocated.
 *
 * STRATEGY:	    If the window being scrolled is the cmdWin (it should
 *	    	    be, for now):
 *	    	    	if the line buffer hasn't reached its limit, create
 *	    	    	    and link in a new LineRec pointing to the current
 *	    	    	    top-most line (_y[0] in the window), then allocate
 *	    	    	    a new top-most line for curses to move to the
 *	    	    	    bottom.
 *	    	    	else take the line in the last LineRec and move it
 *	    	    	    to the top-most line. place the previous top-most
 *	    	    	    line in the now-free LineRec and place the
 *	    	    	    LineRec at the front of the queue.
 *	    	    	call scrollnow to actually scroll the window.
 *	    	Else call scrollnow to scroll the window.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
void
scroll(WINDOW *win)
{
    /*
     * Special-case code for scrolling the current screen. Used only when a
     * character is placed in the lower right corner of the screen and the
     * window can scroll... (that's the only time we'll be called with
     * win == curscr, anyway). This code is taken from curses' own scroll().
     */
    if (win == curscr) {
	register int	oy, ox;

	getyx(win, oy, ox);
	wmove(win, 0, 0);
	wdeleteln(win);
	wmove(win, oy, ox);

	/*
	 * If terminal doesn't autowrap or it eats a newline after, feed it
	 * a newline to either do the scroll (!AM) or to give it something
	 * to munch on (XN). Otherwise, we assume the character we just put
	 * out will scroll the screen.
	 */
	if (!AM || XN) {
	    _putchar('\n');
	}
	if (!NONL) {
	    win->_curx = 0;
	}
	return;
    }

    if (win == cmdWin) {
	/*
	 * Save line to be scrolled off if the window being scrolled is the
	 * command window.
	 */
	LinePtr	lp;

	if (numSaved < maxSaved) {
	    lp = (LinePtr)malloc_tagged(sizeof(LineRec), TAG_CURSES);
	    lp->line = win->_y[0];
	    win->_y[0] = (cursesChar *)malloc_tagged(win->_maxx
						     * sizeof(cursesChar),
						     TAG_CURSES);
	    numSaved++;
	} else {
	    /*
	     * Take the last record off the end and use it.
	     */
	    cursesChar    *l;

	    lp = lineTail;
	    lineTail = lp->prev;
	    lineTail->next = NullLine;

	    l = lp->line;
	    lp->line = win->_y[0];
	    win->_y[0] = l;
	}
	/*
	 * Link new record in at head.
	 */
	lp->next = lineHead;
	lp->prev = NullLine;

	if (lineTail == NullLine) {
	    /*
	     * First record in chain -- make it both head and tail
	     */
	    lineHead = lineTail = lp;
	} else {
	    lineHead->prev = lp;
	    lineHead = lp;
	}
    }
    /*
     * Scroll the window immediately -- this will also refresh the thing.
     */
    scrollnow_hideMouse(win, 1);
#if defined(_MSDOS)
    CursesUpdateHighlight(1);
#endif
    return;
}


/***********************************************************************
 *				CursesBeep
 ***********************************************************************
 * SYNOPSIS:	    Ring the terminal's bell.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:	    If VB (visible bell termcap) is non-null, send that
 *	    	    string. Else just send BL if it's non-null, or
 *	    	    a bell (\007).
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 5/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(beep,CursesBeep,1,NULL,swat_prog.output,
"Usage:\n\
    beep\n\
\n\
Examples:\n\
    \"beep\"	Honk at the user.\n\
\n\
Synopsis:\n\
    Alerts the user to something. If the terminal supports a visible bell,\n\
    that's how the alert is issued, else it uses an audible bell.\n\
\n\
Notes:\n\
    * This is not supported under DOS for now.\n\
\n\
See also:\n\
    none.\n\
")
{
#if defined(unix)
    if (VB) {
	_puts(VB);
    } else if (BL) {
	_puts(BL);
    } else {
	_puts("\007");
    }

    fflush(stdout);
#elif defined(_WIN32)
    beep();
#elif defined(_MSDOS)
    fflush(stdout);
#endif
    return(TCL_OK);
}


/***********************************************************************
 *				CursesScrollInput
 ***********************************************************************
 * SYNOPSIS:	    Handle a scroll-buffer input character.
 * CALLED BY:	    CursesStartScroll and CursesReadInput
 * RETURN:	    Nothing
 * SIDE EFFECTS:    inProc may revert to CursesInputChar.
 *	    	    The screen pointers may change...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
static void
CursesScrollInput(unsigned char c, CursesInputState *state)
{
    int	    	i, lines = 0;
    LinePtr 	lp;
#if defined(_MSDOS)
    char    	*mh;
    int	    	value1 = -1, value2 = -1;

    /*
     * If the mouse is active then don't do anything as it's
     * just too messy to deal with
     */
    mh = (char *)Tcl_GetVar(interp, "mousemode", TRUE);
    if (mh[0] != '\0')
    {
	return;
    }
#endif

    if (c == forwPage) {
	/*
	 * Get to first line of next page
	 */
	for (lp = lineCur, i = cmdWin->_maxy; i > 0 && lp != NullLine; i--) {
	    lp = lp->prev;
	}
	if (lp != NullLine) {
#if defined(_MSDOS)
	    /*
	     * Before we scroll, turn off the highlighted region and hide
	     * the cursor.
	     */
	    CursesToggleHighlight(OFF, REMOVE);
	    Mouse_HideCursor();
#endif
	    /*
	     * Not at the end of the chain yet, so we can go forward some
	     * lines, anyway, if not an entire page...
	     */
	    lineCur = lp;	/* Set top-of-window */

	    /*
	     * See if there's a full page of lines left in the chain,
	     * setting up the window on the assumption there are.
	     */
	    for(i = 0; i < cmdWin->_maxy && lp != NullLine; i++) {

		cmdWin->_y[i] = lp->line;
		lp = lp->prev;
	    }
	    if (lp == NullLine && i != cmdWin->_maxy) {
		/*
		 * Not a full page of lines below lineCur, so start
		 * at the bottom and work back a full page.
		 */
		for (i = cmdWin->_maxy-1, lp = lineHead; i >= 0; i--) {
		    cmdWin->_y[i] = lp->line;
		    lp = lp->next;
		}
		/*
		 * lp points beyond the first line, so set lineCur to its
		 * prev pointer
		 */
		lineCur = lp->prev;
	    }
	    /*
	     * Update the entire window.
	     */
	    touchwin(cmdWin);
	    wrefresh(cmdWin);
#if defined(_MSDOS)
	    /*
	     * Update the highlighted region; then reinvert it and show
	     * the cursor.
	     */
	    CursesUpdateHighlight(0);
	    CursesToggleHighlight(ON, SAVE);
	    Mouse_ShowCursor();
#endif
	}
    } else if (c == backPage) {
	if (lineCur != lineTail) {
#if defined(_MSDOS)
	    /*
	     * Before we scroll, turn off the highlighted region and hide
	     * the cursor.
	     */
	    CursesToggleHighlight(OFF, REMOVE);
	    Mouse_HideCursor();
#endif
	    for(lp = lineCur->next, i = cmdWin->_maxy-1;
		i >=0 && lp != NullLine;
		i--, lp = lp->next)
	    {
		cmdWin->_y[i] = lp->line;
	    }

	    if (lp == NullLine) {
		/*
		 * Not a full page of lines below lineCur, so start
		 * at the top and work forward a full page. If we got to
		 * the end of the page (its end coincided with the end of
		 * the list), there's no point in doing the loop -- the
		 * window's set up already.
		 */
		if (i >= 0) {
		    for (i = 0, lp = lineTail; i < cmdWin->_maxy; i++) {
			cmdWin->_y[i] = lp->line;
			lp = lp->prev;
		    }
		}
		lineCur = lineTail;
	    } else {
		/*
		 * lp is above the screen -- set lineCur properly
		 */
		lineCur = lp->prev;
	    }
	    /*
	     * Update the entire window.
	     */
	    touchwin(cmdWin);
	    wrefresh(cmdWin);
#if defined(_MSDOS)
	    /*
	     * Update the highlighted region; then reinvert it and show
	     * the cursor.
	     */
	    CursesUpdateHighlight(0);
	    CursesToggleHighlight(ON, SAVE);
	    Mouse_ShowCursor();
#endif
	}
    } else if (c == forwHPage) {
	int 	my = cmdWin->_maxy-1;

	/*
	 * Grab highlight values for later.
	 */
	if (junkLine == NULL) {
	    junkLine = (cursesChar *)malloc_tagged(cmdWin->_maxx
						   * sizeof(cursesChar),
						   TAG_CURSES);
	}
	/*
	 * Get to the LineRec beyond the one on the bottom of the screen
	 */
	for (i = cmdWin->_maxy,lp = lineCur; i > 0; lp = lp->prev, i--) {
	    ;
	}
	/*
	 * Scroll in _maxy/2 lines...one at a time (to avoid trashing things
	 * and to make the scrolling smoother).
	 */
	for (i = cmdWin->_maxy/2; i < cmdWin->_maxy && lp != NullLine; i++) {
	    /*
	     * Preserve _y[0]
	     */
	    cmdWin->_y[0] = junkLine;
	    /*
	     * Scroll once -- this will move junkLine to be in _maxy-1
	     */
	    scrollnow_hideMouse(cmdWin,1);
	    lines++;
	    assert(cmdWin->_y[my] == junkLine);
	    /*
	     * Put in proper line and mark it as all modified
	     */
	    cmdWin->_y[my] = lp->line;
	    touchline(cmdWin,my,0,cmdWin->_maxx-1);
	    /*
	     * Go to next line to display and advance the top-of-window ptr.
	     */
	    lp = lp->prev;
	    lineCur = lineCur->prev;
	}
	/* now undo our deviousness...and update any new piece that
	 * might have gotton scrolled on
	 */
	wrefresh(cmdWin);
#if defined(_MSDOS)
	CursesUpdateNewMouseHighlight(lines);
#endif
    } else if (c == backHPage) {
	int my = cmdWin->_maxy-1;

	if (junkLine == NULL) {
	    junkLine = (cursesChar *)malloc_tagged(cmdWin->_maxx
						   * sizeof(cursesChar),
						   TAG_CURSES);
	}
	/*
	 * Trick the highlight update code into doing the right thing.
	 */
	for (i = cmdWin->_maxy/2, lp = lineCur->next;
	     i >0 && lp != NullLine;
	     i--)
	{
	    /*
	     * Preserve line in _y[_maxy-1]
	     */
	    cmdWin->_y[my] = junkLine;
	    /*
	     * Scroll screen down -- moves junkLine to _y[0]
	     */
	    scrollnow_hideMouse(cmdWin,-1);
	    --lines;
	    assert(cmdWin->_y[0] == junkLine);
	    /*
	     * Store in new line at top and mark it as all modified
	     */
	    cmdWin->_y[0] = lp->line;
	    touchline(cmdWin,0,0,cmdWin->_maxx-1);
	    /*
	     * Work up the chain.
	     */
	    lp = lp->next;
	    lineCur = lineCur->next;
	}
	wrefresh(cmdWin);
#if defined(_MSDOS)
	CursesUpdateNewMouseHighlight(lines);
#endif
    } else if (c == forwLine) {
	if (junkLine == NULL) {
	    junkLine = (cursesChar *)malloc_tagged(cmdWin->_maxx
						   * sizeof(cursesChar),
						   TAG_CURSES);
	}
	/*
	 * Get to the LineRec beyond the one on the bottom of the screen
	 */
	for (i = cmdWin->_maxy,lp = lineCur; i > 0; lp = lp->prev, i--) {
	    ;
	}
	if (lp != NullLine) {
	    cmdWin->_y[0] = junkLine;
	    scrollnow_hideMouse(cmdWin, 1);
	    lines++;
	    assert(cmdWin->_y[cmdWin->_maxy-1] == junkLine);
	    cmdWin->_y[cmdWin->_maxy-1] = lp->line;
	    touchline(cmdWin, cmdWin->_maxy-1, 0, cmdWin->_maxx-1);
	    lineCur = lineCur->prev;
	}
	wrefresh(cmdWin);
#if defined(_MSDOS)
	CursesUpdateNewMouseHighlight(lines);
#endif
    } else if (c == backLine) {
	if (junkLine == NULL) {
	    junkLine = (cursesChar *)malloc_tagged(cmdWin->_maxx
						   * sizeof(cursesChar),
						   TAG_CURSES);
	}
	if (lineCur->next != NullLine) {
	    lineCur = lineCur->next;
	    cmdWin->_y[cmdWin->_maxy-1] = junkLine;
	    scrollnow_hideMouse(cmdWin,-1);
	    --lines;
	    cmdWin->_y[0] = lineCur->line;
	    touchline(cmdWin, 0, 0, cmdWin->_maxx-1);
	}
	wrefresh(cmdWin);
#if defined(_MSDOS)
	CursesUpdateNewMouseHighlight(lines);
#endif
    } else if (c == redraw) {
	wrefresh(curscr);
#if defined(_MSDOS)
	{
	    int 	value1, value2;

	    if (CursesGetMouseHighlight(&value1, &value2) != NULL)
	    {
		DosInvertScreenRegion(value1, value2);
	    }
	}
#endif
    } else {
	CursesEndScroll(state);
	/*
	 * Process the character normally
	 */
	CursesInputChar(c, state);
    }
}


/***********************************************************************
 *				CursesEndScroll
 ***********************************************************************
 * SYNOPSIS:	    Return the scroll buffer to its unscrolled condition
 * CALLED BY:	    CursesScrollInput, insert-highlighted-text
 * RETURN:	    nothing
 * SIDE EFFECTS:    the line list is restored and those structures
 *		    allocated to track the original screen contents are
 *		    freed.
 *	    	    inProc is set to CursesInputChar
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 1/93		Initial Revision
 *
 ***********************************************************************/
static void
CursesEndScroll(CursesInputState *state)
{
    LinePtr 	lp;
    int	    	i;

#if defined(_MSDOS)
    int 	lines=0;	/* Y position of start of highlight region */
    /*
     * Turn the onscreen highlight off but leave the mouse_highlight tcl
     * variable alone for the time being.
     */
    CursesToggleHighlight(OFF, SAVE);
    highlightinfo.on_screen_height = 0;
#endif
    for (i = cmdWin->_maxy-1, lp = lineHead; i >= 0; i--) {
	cmdWin->_y[i] = lp->line;
	lineHead = lp->next;

#if defined(_MSDOS)
	/*
	 * We must make sure to update our highlighted region which
	 * might rely on some of these pointers being freed
	 * if any of the highlighted regions pointers are being freed
	 * then we don't need them anyways because that region is back
	 * on the screen, so just update the pointers to be accurate
	 * lines will tell us how far onto the screen the thing ends up
	 */
	if (lines)
	{
	    lines++;
	}
	if (highlightinfo.lastline == lp)
	{
	    /*
	     * We always hit the lastline first, if the firstline is
	     * different then just update the last line to the next one
	     * if it's the same then the whole thing is back on the
	     * screen so just null out the pointers
	     */
	    if (highlightinfo.firstline == lp)
	    {
		highlightinfo.firstline = highlightinfo.lastline = NULL;
		lines++; /* lines is zero before this, so now lines=1 */
	    }
	    else
	    {
		highlightinfo.lastline = lp->next;
		highlightinfo.on_screen_height++;
	    }
	}
#endif
	free((void *)lp);
	lp = lineHead;
    }
    lineHead->prev = NullLine;
    scrollok(cmdWin, 1);
    touchwin(cmdWin);
    wrefresh(cmdWin);

    lineCur = NULL;
    state->inProc = CursesInputChar;
#if defined(_MSDOS)
    if (lines)
    {
	CursesUpdateHighlight(lines);
    }
    else
    {
	/*
	 * The thing is either completely or partially off the screen
	 */
	if (highlightinfo.on_screen_height == 0)
	{
	    /*
	     * The thing is completely off the screen; just null out the
	     * mouse_highlight variable and all is well
	     */
	    Tcl_SetVar(interp, "mouse_highlight", "", TRUE);
	}
	else
	{
	    int startVid, endVid;

	    startVid = highlightinfo.first_offset;
	    endVid = (highlightinfo.on_screen_height - 1) *
		CursesNumColumns();
	    endVid += highlightinfo.last_offset;
	    Mouse_SetMouseHighlight(startVid, endVid);
	}
    }

    highlightinfo.scroll_mode = 0;
    Tcl_Eval(interp, "unhighlight-mouse", 0, NULL);
    /*
     * Now clear out the return value since I don't want it.
     */
    Tcl_Return(interp, NULL, TCL_STATIC);
#endif
}


/***********************************************************************
 *				CursesStartScroll
 ***********************************************************************
 * SYNOPSIS:	    Activate the scroll buffer if the given character
 *	    	    is a scroll-control key.
 * CALLED BY:	    CursesReadInput
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The handler for stdin will be changed if the
 *	    	    scroll buffer is indeed activated.
 *
 * STRATEGY:
 *	    If the given character is a scroll-command character, place
 *	    all the current screen lines on the head of the scroll buffer
 *	    queue, switch over to CursesScrollInput for regular input
 *	    processing, and call it to handle the given character.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
static void
CursesStartScroll(char c, CursesInputState *state)
{
    /*
     * Have to go backward before we can go forward...
     */
    if (((c == backPage) || (c == backHPage) || (c == backLine)) &&
	(lineTail != NullLine))
    {
	int 	i;
	LinePtr	lp;
#if defined(_MSDOS)
	int 	startY, endY, startX, endX;
#endif
	/*
	 * Handle input characters in CursesScrollInput until a non-scroll
	 * key is hit.
	 */
	state->inProc = CursesScrollInput;
#if defined(_MSDOS)
	highlightinfo.scroll_mode = 1;
	if (CursesConvertMouseHighlightToCoords(&startX, &startY,
						&endX, &endY) == (char *)NULL)
	{
	    startY = endY = -1;
	}
#endif
	/*
	 * Create LineRec's for all the active screen lines, then pass the
	 * buck to CursesScrollInput.
	 */
	lineCur = lineHead;	/* Save head pointer for later use */
	for (i = 0; i < cmdWin->_maxy; i++) {
	    lp = (LinePtr)malloc_tagged(sizeof(LineRec), TAG_CURSES);
	    lp->line = cmdWin->_y[i];
	    lp->next = lineHead;
	    lineHead->prev = lp;

	    lp->prev = NullLine;
	    lineHead = lp;

#if defined(_MSDOS)
	    /*
	     * Theoretically, if startY hits any of these i's, then so will
	     * endY...
	     */
	    if (startY == i)
	    {
		if (highlightinfo.firstline == NULL)
		{
		    highlightinfo.firstline = lp;
		    highlightinfo.first_offset = startX;
		}
	    }
	    if (endY == i)
	    {
		highlightinfo.lastline = lp;
		highlightinfo.active = 1;
		highlightinfo.on_screen_height = endY - startY + 1;
		highlightinfo.scroll_mode = 1;
		highlightinfo.last_offset = endX;
	    }
#endif
	}
	lineCur = lineCur->prev;
	scrollok(cmdWin, 0);
	CursesScrollInput(c, state);
    }
}

/***********************************************************************
 *				CursesBackSpace
 ***********************************************************************
 * SYNOPSIS:	    Handle deleting the character before the cursor.
 * CALLED BY:	    CursesInputChar
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The character is blanked out...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
static void
CursesBackSpace(WINDOW *win, Boolean destroy)
{
#if defined(_MSDOS)
    int curX, curY;

    curX = win->_curx - 1;
    curY = win->_cury;
#endif
    if (win->_curx == 0) {
	/*
	 * Curses won't line-wrap for us...
	 */
	if (win->_cury > 0) {
	    if (destroy) {
		win->_cury--;
		win->_curx = win->_maxx-1;
		waddch(win, ' ');
		win->_cury--;
		win->_curx = win->_maxx-1;
	    } else {
		win->_cury--;
		win->_curx = win->_maxx-1;
	    }
	}
    } else {
	/*
	 * Let them do all the hard work...
	 */
	if (destroy) {
	    waddstr(win, (WADDSTR_CAST)"\b \b");
	} else {
	    waddch(win, '\b');
	}
    }
#if defined (_MSDOS)
{
    int	startX, startY, endX, endY;
    /*
     * If there was no highlight onscreen, leave.
     */
    if (CursesConvertMouseHighlightToCoords(&startX, &startY,
					    &endX, &endY) == (char *)NULL)
	return;
    /*
     * Check whether we're within the highlight and get rid of it if so.
     */
    if ((curY >= startY) && (curY <= endY)) {
	int value1;
	/*
	 * If we're on the same line as the highlight we need to see if
	 * our X position falls within it; if not, scoot.
	 */
	if ((curY == endY) && !((curX >= (startX / 2)) && (curX <= (endX / 2))))
	    return;
	/*
	 * The backspacing inverted the highlight at our current position,
	 * so we have to flip it back before we turn everything off.
	 */
	value1 = 2 * (curY * CursesNumColumns() + curX);
	DosInvertScreenRegion(value1, value1);

	CursesToggleHighlight(OFF, REMOVE);
    }
}
#endif
}

static Rpc_Event    showMatchEvent;


/***********************************************************************
 *				CursesEndMatch
 ***********************************************************************
 * SYNOPSIS:	    Reset the cursor to its old location.
 * CALLED BY:	    Rpc module
 * RETURN:	    FALSE (No need to return on our account)
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 4/89		Initial Revision
 *
 ***********************************************************************/
static Boolean
CursesEndMatch(Rpc_Opaque   data,
	       Rpc_Event    ev)
{
    int	x, y;

    x = ((unsigned long)data >> 16) & 0xffff;
    y = (unsigned long)data & 0xffff;

    mvcur(curscr->_cury, curscr->_curx, y, x);
    curscr->_cury = y;
    curscr->_curx = x;

    /*
     * Make sure the cursor moves...
     */
    fflush(stdout);

    /*
     * Nuke the event that called us
     */
    Rpc_EventDelete(ev);
    showMatchEvent = 0;

    return(FALSE);
}


/***********************************************************************
 *				CursesShowMatch
 ***********************************************************************
 * SYNOPSIS:	    Show the matching open brace/bracket/paren for a
 *	    	    second.
 * CALLED BY:	    CursesInputChar
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The cursor is moved and an event registered to move
 *	    	    the cursor back again after a second.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 4/89		Initial Revision
 *
 ***********************************************************************/
static void
CursesShowMatch(char	open,	/* Character to match */
		char	close)	/* Character that triggered this */
{
    int	    	    x, y;   	/* Search counters */
    Rpc_Opaque	    eventData; 	/* Data to pass to CursesEndShowMatch --
				 * This is the current x (in the high word)
				 * or'ed with the current y (in the low) */
    struct timeval  oneSec; 	/* Showmatch interval */
    int	    	    nesting;

    wrefresh(curWin);

    y = curWin->_cury;
    x = curWin->_curx;

    /*
     * Set up for event to call CursesEndMatch, in case a match is found.
     */
    eventData = (Rpc_Opaque)(((curWin->_begx + x) << 16) | (curWin->_begy + y));

    oneSec.tv_sec = 1;
    oneSec.tv_usec = 0;

    /*
     * Back up to the closing character...
     */
    if (--x < 0) {
	x = curWin->_maxx-1;
	if (--y < 0) {
	    return;
	}
    }
    /*
     * Make sure the closer wasn't escaped.
     */
    if (--x < 0) {
	x = curWin->_maxx-1;
	if (--y < 0) {
	    return;
	}
    }
    if (EQUAL_CHARS(curWin->_y[y][x], '\\') == TRUE) {
	if (--x < 0) {
	    x = curWin->_maxx-1;
	    if (--y < 0) {
		return;
	    }
	}
	if (EQUAL_CHARS(curWin->_y[y][x], '\\') == FALSE) {
	    /*
	     * Closing delimiter is escaped -- don't show match.
	     */
	    return;
	}
    }
    nesting = 0;
    while (y >= 0) {
	if (EQUAL_CHARS(curWin->_y[y][x], open) == TRUE) {
	    if (--x < 0) {
		x = curWin->_maxx-1;
		if (--y < 0) {
		    /*
		     * Was at upper-left -- don't know if it was escaped or
		     * not, so reset to upper-left and assume it wasn't.
		     */
		    y = x = 0;
		    if (nesting) {
			/*
			 * If nested, can't possibly be a match on screen.
			 */
			return;
		    } else {
			goto found_match;
		    }
		}
	    }
	    if (EQUAL_CHARS(curWin->_y[y][x], '\\') == TRUE) {
		/*
		 * Have to make sure the \ is really escaping the open, not
		 * escaped itself.
		 */
		if (--x < 0) {
		    x = curWin->_maxx-1;
		    if (--y < 0) {
			/*
			 * Don't know if was escaped itself, but do know
			 * open delimiter was, so assume nothing to show.
			 */
			return;
		    }
		}
		if (EQUAL_CHARS(curWin->_y[y][x], '\\') == FALSE) {
		    /*
		     * Backslash not escaped, so continue search with this
		     * character.
		     */
		    continue;
		}
		/*
		 * If w/in a list, just lower the nesting level and
		 * continue the search.
		 */
		if (nesting) {
		    nesting--;
		    continue;
		}
		/*
		 * Shift focus to escaped backslash so code below can
		 * shift it to the open delimiter.
		 */
		if (++x == curWin->_maxx) {
		    x = 0; y++;
		}
	    } else if (nesting) {
		nesting--;
		continue;
	    }
	    /*
	     * Reset x,y to point to the open delimiter (we know y is in
	     * bounds, so no need to check it).
	     */
	    if (++x == curWin->_maxx) {
		x = 0; y++;
	    }
	    found_match:
	    x += curWin->_begx;
	    y += curWin->_begy;
	    mvcur(curscr->_cury, curscr->_curx, y, x);
	    curscr->_cury = y;
	    curscr->_curx = x;
	    fflush(stdout);
	    /*
	     * Set a timeout to shift the cursor back again.
	     */
	    showMatchEvent = Rpc_EventCreate(&oneSec,
					     CursesEndMatch,
					     eventData);
	    break;
	} else if (EQUAL_CHARS(curWin->_y[y][x], close) == TRUE) {
	    if (--x < 0) {
		x = curWin->_maxx-1;
		if (--y < 0) {
		    return;
		}
	    }
	    if (EQUAL_CHARS(curWin->_y[y][x], '\\') == TRUE) {
		if (--x < 0) {
		    x = curWin->_maxx-1;
		    if (--y < 0) {
			return;
		    }
		}
		if (EQUAL_CHARS(curWin->_y[y][x], '\\') == FALSE) {
		    /*
		     * Closer escaped -- don't up the nesting level
		     */
		    continue;
		}
	    } else {
		/*
		 * Up the nesting level, but we need to check the current
		 * character (it may be an opener), so we continue without
		 * adjusting x and y.
		 */
		nesting++;
		continue;
	    }

	    /*
	     * Unescaped closer -- up the nesting level so we know the next
	     * opener isn't really the one we want.
	     */
	    nesting++;
	}

	/*
	 * Retreat to next character.
	 */
	if (--x < 0) {
	    x = curWin->_maxx-1;
	    if (--y < 0) {
		return;
	    }
	}
    }
}



/***********************************************************************
 *				CursesHonk
 ***********************************************************************
 * SYNOPSIS:	    Alert the user by jumping up and down
 * CALLED BY:	    CursesInputChar
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The screen may flash or the computer may beep
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	11/ 8/96	Initial Revision
 *
 ***********************************************************************/
static void
CursesHonk(void)
{
#if !defined(_WIN32)
		    write(_tty_ch, "\007", 1);
#else
		    beep();
#endif
}


/***********************************************************************
 *				CursesInputChar
 ***********************************************************************
 * SYNOPSIS:	    Handle the receipt of a single character for the
 *	    	    current input line.
 * CALLED BY:	    CursesReadInput, CursesScrollInput
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The CISF_LINEREADY flag may be set, characters erased
 *	    	    from the screen, etc.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
static void
CursesInputChar(unsigned char c, CursesInputState *state)
{
#if defined(unix)
# define werasechar() (ltc.t_werasc)
# define ctrlspace() ('\000')
#else
# define werasechar()	('W' & 0x1f)
# define ctrlx()	('X' & 0x1f)
# define ctrlspace() ('\000' & 0x1f)
#endif

    int    len, curX, curY;
    char   *clec, *cp;

    if (cursesFlags & CURSES_ECHO) {
	if (c == erasechar()) {
	    if (state->cursPos == state->lineLength) {
		/*
		 * If any characters in the line, nuke one
		 */
		if (--state->lineLength >= 0) {
		    CursesBackSpace(curWin, TRUE);
		    state->cursPos--;
		    /*
		     * Nuke the character from the input buffer
		     */
		    Buf_DelBytes(state->input, 1);

		    /*
		     * If the mark was at the end, drag it along here
		     */
		    if (state->markPos > state->lineLength) {
			state->markPos = state->lineLength;
		    }
		} else {
		    state->lineLength++;
		    CursesHonk();
		}
	    } else {
		if (--state->cursPos >= 0) {
		    /*
		     * If any characters in the line, nuke one
		     */
		    CursesBackSpace(curWin, TRUE);
		    state->lineLength--;
		    if (state->markPos > state->cursPos) {
			state->markPos--;
		    }

		    /*
		     * Nuke the character from the input buffer
		     */
		    Buf_DelBytesMiddle(state->input, 1, state->cursPos);

		    /*
		     * If we're in the middle of the command, we'll have to
		     * fill in the space we just made...
		     */
		    curX = curWin->_curx;
		    curY = curWin->_cury;
		    waddstr(curWin, ((WADDSTR_CAST)Buf_GetAll(state->input,
							      &len)) +
			    state->cursPos);
		    waddch(curWin, ' ');
 		    curWin->_curx = curX;
		    curWin->_cury = curY;
		} else {
		    state->cursPos++;
		    CursesHonk();
		}
	    }
#if defined(unix)
	} else if (c == killchar()) {
#else
	} else if ((c == killchar()) || (c == ctrlx())) {
#endif
	    Buffer    tempBuf;
	    /*
	     * Sync up state->cursPos with lineLength to magically solve
	     * the problem of reading a line where the guy hit return
	     * in the middle of everything
	     */
	    if (state->cursPos < state->lineLength) {
		waddstr(curWin, ((WADDSTR_CAST)Buf_GetAll(state->input,
							  &len)) +
			state->cursPos);
		state->cursPos = state->lineLength;
	    }

	    /*
	     * Delete as many bytes as are in the current line.
	     */
	    Buf_DelBytes(cutBuf, cutLength);

	    /*
	     * We'll switch input & cutBuf, so that cutBuf = the current
	     * line without much hassle.
	     */
	    tempBuf = state->input;
	    state->input = cutBuf;
	    cutBuf = tempBuf;
	    cutLength = state->lineLength;

	    /*
	     * Erase them...
	     */
	    while (state->lineLength--) {
		CursesBackSpace(curWin, TRUE);
	    }

	    state->lineLength = state->cursPos = 0;
	    state->markPos = -1;
	} else if (c == werasechar()) {
	    /*
	     * If any characters in the line, erase a space-separated word,
	     * leaving the cursor where the first character of the word
	     * used to be.
	     */
	    if (state->cursPos) {
		int 	oldLength = state->lineLength;

		/*
		 * Start at state->cursPos
		 */
		cp = (char *)Buf_GetAll(state->input, &len) + state->cursPos;

		/*
		 * First get back to the end of the word...
		 */
		while (state->cursPos && (index(state->wordChars, *--cp))) {
		    CursesBackSpace(curWin, TRUE);
		    state->lineLength--;
		    state->cursPos--;
		}
		/*
		 * Still more to go -- get back to the preceding whitespace
		 * or the start of the line, whichever comes first.
		 */

		while (state->cursPos && !(index(state->wordChars, *cp))) {
		    CursesBackSpace(curWin, TRUE);
		    state->lineLength--;
		    state->cursPos--;
		    cp--;
		}

		/*
		 * Set the mark here.
		 */
		state->markPos = state->cursPos;

		/*
		 * Nuke those bytes, saving 'em in cutBuf
		 */
		Buf_DelBytes(cutBuf, cutLength);
		Buf_AddBytes(cutBuf,
			     oldLength - state->lineLength,
			     Buf_GetAll(state->input, &len)
			      + state->cursPos);
		cutLength = oldLength - state->lineLength;
		Buf_DelBytesMiddle(state->input,
				   oldLength - state->lineLength,
				   state->cursPos);

		curX = curWin->_curx;
		curY = curWin->_cury;
		waddstr(curWin, ((WADDSTR_CAST)Buf_GetAll(state->input,
							  &len)) +
			state->cursPos);
		while (oldLength-- > state->lineLength) {
		    waddch(curWin, ' ');
		}
		curWin->_curx = curX;
		curWin->_cury = curY;
	    }
	} else if (c == ctrlspace()) {
	    /*
	     * Set the mark.
	     */
	    state->markPos = state->cursPos;
	} else if (c == state->cleChars[CLEC_YANK]) {
	    if (cutLength) {
		char    tempC;

		/*
		 * Set the mark here.
		 */
		state->markPos = state->cursPos;

		/*
		 * Spew the cut buffer out right here.
		 */
		waddstr(curWin, (WADDSTR_CAST)Buf_GetAll(cutBuf, &len));
		waddstr(curWin, ((WADDSTR_CAST)Buf_GetAll(state->input,
							  &len)) +
			state->cursPos);

		/*
		 * Add the bytes in at the proper location, natch'
		 */
		Buf_AddBytesMiddle(state->input,
				   cutLength,
				   Buf_GetAll(cutBuf, &len),
				   state->cursPos);
		state->cursPos += cutLength;
		state->lineLength += cutLength;

		/*
		 * Do the rewind, fast-forward trick again.
		 */
		cp = (char *)Buf_GetAll(state->input, &len);
		while (len--) {
		    CursesBackSpace(curWin, FALSE);
		}

		tempC = cp[state->cursPos];
		cp[state->cursPos]= 0;
		waddstr(curWin, (WADDSTR_CAST)cp);
		cp[state->cursPos] = tempC;
	    }
	} else if (state->lineLength && /* XXXdan verify = (not ==) is okay */
		   (clec = index(state->cleChars, c)) &&
		   ((c != '\004') || (state->cursPos < state->lineLength)))
	{
	    switch (clec-state->cleChars) {
		case CLEC_BEGINNING_OF_LINE:
		    /*
		     * Count state->cursPos back to
		     * the beginning of the line.
		     */
		    while (state->cursPos--) {
			CursesBackSpace(curWin, FALSE);
		    }
		    state->cursPos = 0;
		    break;
		case CLEC_END_OF_LINE:
		    /*
		     * Move state->cursPos to lineLength
		     */
		    if (state->cursPos < state->lineLength) {
			waddstr(curWin,
				((WADDSTR_CAST)Buf_GetAll(state->input,
							  &len)) +
				state->cursPos);
		    state->cursPos = state->lineLength;
		    }
		    break;
		case CLEC_BACKWARD_CHAR:
		    /*
		     * If any characters in the line, back up over it.
		     */
		    if (state->cursPos) {
			CursesBackSpace(curWin, FALSE);
			state->cursPos--;
		    }
		    break;
		case CLEC_FORWARD_CHAR:
		    /*
		     * Move state->cursPos one up through the string
		     */
		    if (state->cursPos < state->lineLength) {
			waddch(curWin,
			       Buf_GetAll(state->input,
					  &len)[state->cursPos]);
			state->cursPos++;
		    }
		    break;
		case CLEC_BACKWARD_WORD:
		    if (state->cursPos) {
			/*
			 * First get back to the end of the word...
			 */
			cp = (char *)Buf_GetAll(state->input, &len) +
			    state->cursPos;
			while (state->cursPos &&
			       (index(state->wordChars, *--cp)))
			{
			    CursesBackSpace(curWin, FALSE);
			    state->cursPos--;
			}
			/*
			 * Still more to go -- get back to the preceding
			 * whitespace or the start of the line,
			 * whichever comes first.
			 */

			while (state->cursPos &&
			       !(index(state->wordChars, *cp)))
			{
			    CursesBackSpace(curWin, FALSE);
			    state->cursPos--;
			    cp--;
			}
		    }
		    break;
		case CLEC_FORWARD_WORD:
		    if (state->cursPos < state->lineLength) {
			/*
			 * First get back to the end of the word...
			 */
			cp = (char *)Buf_GetAll(state->input, &len) +
			    state->cursPos;
			while ((state->cursPos < state->lineLength) &&
			       (index(state->wordChars, *cp)))
			{
			    waddch(curWin, *cp++);
			    state->cursPos++;
			}
			/*
			 * Still more to go -- get back to the preceding
			 * whitespace or the start of the line, whichever
			 * comes first.
			 */

			while ((state->cursPos < state->lineLength) &&
			       !(index(state->wordChars, *cp)))
			{
			    waddch(curWin, *cp++);
			    state->cursPos++;
			}
		    }
		    break;
		case CLEC_FORWARD_DELETE_CHAR:
		    /*
		     * Same as a forward char + delete
		     */
		    waddch(curWin,
			   Buf_GetAll(state->input, &len)[state->cursPos]);
		    state->cursPos++;
		    CursesInputChar((unsigned char)erasechar(), state);
		    break;
		case CLEC_FORWARD_DELETE_WORD:
		    if (state->cursPos < state->lineLength) {
			/*
			 * We'll just set the mark, forward-word, kill-region
			 */
			CursesInputChar(ctrlspace(), state);
			CursesInputChar(state->cleChars[CLEC_FORWARD_WORD],
					state);
			CursesInputChar(state->cleChars[CLEC_KILL_REGION],
					state);
		    }
		    break;
		case CLEC_KILL_LINE:
		    CursesInputChar((unsigned char)killchar(), state);
		    break;
		case CLEC_KILL_REGION:
		    /*
		     * If there's a mark, then kill the text
		     * between the cursor and the mark.
		     */
		    if ((state->markPos >= 0) &&
			(state->markPos != state->cursPos))
		    {
			int    tempPos;

			if (state->markPos > state->cursPos) {
			    char   tempC;
			    /*
			     * The mark is ahead of the cursor,
			     * so we'll have to fast forward the
			     * cursor there in order to backspace
			     * over the selection.
			     */
			    cp = (char *)Buf_GetAll(state->input, &len);
			    tempC = cp[state->markPos];
			    cp[state->markPos] = 0;
			    waddstr(curWin, (WADDSTR_CAST)(cp +
							   state->cursPos));
			    cp[state->markPos] = tempC;

			    tempPos = state->cursPos;
			    state->cursPos = state->markPos;
			    state->markPos = tempPos;
			}

			/*
			 * At this point, the mark should be behind us,
			 * so let's just back up and erase until
			 * state->cursPos = state->markPos.
			 */
			tempPos = state->cursPos;
			while (state->cursPos > state->markPos) {
			    CursesBackSpace(curWin, TRUE);
			    state->lineLength--;
			    state->cursPos--;
			}

			Buf_DelBytes(cutBuf, cutLength);
			cutLength = tempPos - state->cursPos;
			Buf_AddBytes(cutBuf, cutLength,
				     (Buf_GetAll(state->input, &len) +
				      state->cursPos));
			Buf_DelBytesMiddle(state->input,
					   tempPos - state->cursPos,
					   state->cursPos);

			curX = curWin->_curx;
			curY = curWin->_cury;
			waddstr(curWin,
				((WADDSTR_CAST)Buf_GetAll(state->input,
							  &len)) +
				state->cursPos);

			while (tempPos-- > state->cursPos) {
			    waddch(curWin, ' ');
			}
			curWin->_curx = curX;
			curWin->_cury = curY;
		    } else {
			/*
			 * Kill the rest of the line by spewing to the end,
			 * then backspacing over it all.
			 */
			if (state->cursPos < state->lineLength) {
			    waddstr(curWin,
				    ((WADDSTR_CAST)Buf_GetAll(state->input,
							      &len)) +
				    state->cursPos);
			    Buf_DelBytes(cutBuf, cutLength);
			    Buf_AddBytes(cutBuf,
					 state->lineLength - state->cursPos,
					 (Buf_GetAll(state->input, &len) +
					  state->cursPos));
			    cutLength = state->lineLength - state->cursPos;
			    Buf_DelBytes(state->input,
					 state->lineLength - state->cursPos);
			    while (state->lineLength > state->cursPos) {
				CursesBackSpace(curWin, TRUE);
				state->lineLength--;
			    }
			}
		    }
		    break;
		case CLEC_YANK:
		break;
	    }
	} else if (c == redraw) {
	    wrefresh(curscr);

#if defined(_MSDOS)
	{
	    int 	value1, value2;

	    if (CursesGetMouseHighlight(&value1, &value2) != NULL)
	    {
		DosInvertScreenRegion(value1, value2);
	    }
	}
#endif
	} else if (c != 0 && (index(state->endChars, c) != NULL)) {
	    /*
	     * Character is in the list of things to cause immediate return,
	     * so do so. Chop whatever tail we've got goin' first.
	     */
/*	    CursesInputChar('\013'); */
	    /*
	     * Sync up state->cursPos with state->lineLength to magically
	     * solve the problem of reading a line where the guy hit
	     * return in the middle of everything
	     */
	    if (state->cursPos < state->lineLength) {
		waddstr(curWin,
			((WADDSTR_CAST)Buf_GetAll(state->input, &len)) +
			state->cursPos);
		state->cursPos = state->lineLength;
	    }

	    Buf_AddByte(state->input, (Byte)c);
	    state->flags |= CISF_LINEREADY;
	} else if (!iscntrl(c) || isspace(c)) {
#if defined(_WIN32)
	    if ((c == UP_ARROW_ASCII) ||
		(c == DOWN_ARROW_ASCII) ||
		(c == LEFT_ARROW_ASCII) ||
		(c == RIGHT_ARROW_ASCII) ||
		(c == PAGE_UP_ASCII) ||
		(c == PAGE_DOWN_ASCII) ||
		(c == HOME_ASCII) ||
		(c == END_ASCII))
	    {
		if (c == UP_ARROW_ASCII) {
		    /*
		     * make up-arrow act like cntl-p since it
		     * isn't bound to scroll up
		     */
		    c = 0x10;
		} else if (c == DOWN_ARROW_ASCII) {
		    /*
		     * make down-arrow act like cntl-n since it
		     * isn't bound to scroll up
		     */
		    c = 0x0E;
		} else {
		    /*
		     * don't do anything for the other special keys
		     */
		    goto check_end;
		}
		if (state->cursPos < state->lineLength) {
		    waddstr(curWin,
			    ((WADDSTR_CAST)Buf_GetAll(state->input, &len))
			    + state->cursPos);
		    state->cursPos = state->lineLength;
		}

		Buf_AddByte(state->input, (Byte)c);
		state->flags |= CISF_LINEREADY;
	    }
	    /*
	     * Space, tab, newline or other printable character -- store it
	     * away and up the line length
	     */
	    else
#endif   /* _WIN32 case */
		if (c == '\t') {

		Boolean tabs2spaces = FALSE;
		/*
		 * does cntl-] cause immediate return?
		 */
		if (index(state->endChars, '\035') != NULL) {
		    /*
		     * Tab - if no white-space yet, then treat as cmd
		     *       completion, else space to next tab-stop
		     */
		    int i;
		    Boolean noWhiteSpace = TRUE;
		    char *buff;
		    int bufsize;

		    buff = (char *)Buf_GetAll(state->input, &bufsize);
		    if (bufsize == 0) {
			noWhiteSpace = FALSE;
		    } else {
			for(i=0; i<bufsize; i++) {
			    if (isspace(buff[i]) != 0) {
				noWhiteSpace = FALSE;
				break;
			    }
			}
		    }
		    if (noWhiteSpace == TRUE) {
			/*
			 * Sync up state->cursPos with state->lineLength
			 * to magically solve the problem of reading a line
			 * where the guy hit return in the middle of
			 * everything
			 */
			if (state->cursPos < state->lineLength) {
			    waddstr(curWin,
				    ((WADDSTR_CAST)Buf_GetAll(state->input,
							      &len)) +
				    state->cursPos);
			    state->cursPos = state->lineLength;
			}

			Buf_AddByte(state->input, (Byte)'\035');
			state->flags |= CISF_LINEREADY;
		    } else {
			tabs2spaces = TRUE;
		    }
		} else {
		    tabs2spaces = TRUE;
		}
		if (tabs2spaces == TRUE) {
		    /*

		     * Turn tabs into spaces so they can be deleted properly
		     */
		    Buf_AddBytes(state->input, (8 - (curWin->_curx & 7)),
				 (Byte *)"        ");
		    state->lineLength += 8 - (curWin->_curx & 7);
		    state->cursPos += 8 - (curWin->_curx & 7);
		    waddch(curWin, c);
		}
	    } else {
		if (c == '\n') {
		    /*
		     * Sync up state->cursPos with state->lineLength to
		     * magically solve the problem of reading a line where
		     * the guy hit return in the middle of everything
		     */
		    if (state->cursPos < state->lineLength) {
			waddstr(curWin,
				((WADDSTR_CAST)Buf_GetAll(state->input,
							  &len)) +
				state->cursPos);
			state->cursPos = state->lineLength;
		    }
		}
		if (state->cursPos == state->lineLength) {
		    Buf_AddByte(state->input, (Byte)c);
		    waddch(curWin, c);
		} else {
		    char    tempC;
		    /*
		     * We're in the middle of the line here, so we
		     * need to deal with inserting the thing.
		     */
		    Buf_AddByteMiddle(state->input, (Byte)c, state->cursPos);
		    /*
		     * Spew the character out, and remember the position.
		     * This prob'ly gets all fucked if it causes the
		     * window to wrap, but...
		     */
		    cp = (char *)Buf_GetAll(state->input, &len);
		    waddstr(curWin, (WADDSTR_CAST)(cp + state->cursPos));

		    /*
		     * Well, I was right. It screwed up, so let's try
		     * going to the beginning of the line and spewing
		     * out
		     */
		    while (len--) {
			CursesBackSpace(curWin, FALSE);
		    }
		    tempC = cp[state->cursPos + 1];
		    cp[state->cursPos + 1]= 0;
		    waddstr(curWin, (WADDSTR_CAST)cp);
		    cp[state->cursPos + 1] = tempC;
		}
		state->lineLength++;
		if (state->markPos > state->cursPos) {
		    state->markPos++;
		}
		state->cursPos++;
	    }
	    /*
	     * Perform show-match and avoid screen refresh
	     */
	    switch (c) {
		case ']': CursesShowMatch('[', ']'); goto check_end;
		case ')': CursesShowMatch('(', ')'); goto check_end;
		case '}': CursesShowMatch('{', '}'); goto check_end;
	    }
	} else {
	    CursesStartScroll(c, state);
	}
	wrefresh(curWin);
    } else {
	/*
	 * If not echoing, not doing line-editing either, so stuff the char
	 * right in the buffer.
	 */
	Buf_AddByte(state->input, (Byte)c);
    }
check_end:
    /*
     * See if we've gotten a complete line of input
     */
    if (c == '\n') {
	/*
	 * Mark another line boundary in any case...
	 */
	state->lineLength = state->cursPos = 0;
	state->markPos = -1;

	if (state->flags & CISF_READCMD) {
	    /*
	     * Make sure the brackets and braces are balanced.
	     */
	    int	    	cc;
	    int     	braces,
			brackets,
			numBytes;

	    cp = (char *)Buf_GetAll(state->input, &cc);
	    for (braces = 0, brackets = 0; cc > 0; cp++, cc--) {
		switch (*cp) {
		    case '\\':
			(void)Tcl_Backslash(cp, &numBytes);
			cp += numBytes-1;
			cc -= numBytes-1;
			break;
		    case '{':
			if (braces > 0 || isspace(cp[-1])) {
			    braces++;
			}
			break;
		    case '}':
			if (braces) {
			    braces--;
			}
			break;
		    case '[':
			if (!braces) {
			    brackets++;
			}
			break;
		    case ']':
			if (!braces && brackets) {
			    brackets--;
			}
			break;
		}
	    }
	    if ((braces == 0) && (brackets == 0)) {
		state->flags |= CISF_LINEREADY;
	    }
	} else {
	    state->flags |= CISF_LINEREADY;
	}
    }
    if (state->flags & CISF_LINEREADY) {
	/*
	 * Don't accept any more input until this line is processed.
	 */
	Rpc_Ignore(0);
#if defined(_MSDOS)
	/*
	 * Turn off mouse stuff in the main window.
	 */
	Mouse_Ignore();
#endif
    }
}

/*********************************************************************
 *			CursesCheckKeyBinding
 *********************************************************************
 * SYNOPSIS: 	    execute the command bound to a keystroke (if any)
 * CALLED BY:	    CursesReadInput
 * RETURN:  	    true if key is bound to something non-null
 * SIDE EFFECTS:    function executed (maybe)
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	1/25/93		Initial version
 *
 *********************************************************************/
static int
CursesCheckKeyBinding(unsigned char c)
{
    if (keyBindings[c] == (char *)NULL)
    {
	return 0;
    }
    Tcl_Eval(interp, keyBindings[c], 0, NULL);
    return 1;
}

#if defined(unix) || defined(_LINUX)
int getch2() {
   static int ch=-1, fd=0;
   struct termios new, old;
   fd=fileno(stdin);
   tcgetattr(fd, &old);
   new=old;
   new.c_lflag &= ~(ICANON|ECHO);
   tcsetattr(fd, TCSANOW, &new);
   ch = getchar();
   tcsetattr(fd, TCSANOW, &old);
   return ch;
}
#endif

/***********************************************************************
 *				CursesReadInput
 ***********************************************************************
 * SYNOPSIS:	    Process input from the terminal
 * CALLED BY:	    Callback function for CursesReadLineCmd via Rpc_Wait
 * RETURN:	    Nothing
 * SIDE EFFECTS:    A character is added to the buffer, or others may
 *	    	    be nuked...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
static void
CursesReadInput(int 	    stream,
		Rpc_Opaque  data,
		int 	    state)
{
    unsigned char    	buf[1];
    unsigned char    	*cp;
    int	    	i;
    unsigned long chr;
    CursesInputState	*istate = (CursesInputState *)data;

#if defined(unix) || defined(_LINUX)
    chr = getch2();
#if defined(_LINUX)
    /* map ESC code to PC like scan codes for selected codes */
    if (chr == 0x1B) {
	(void)getch2();
	chr = getch2();
	switch ( chr ) {
	    case 'A':
	    	chr = 0xC8;
		break;
	    case 'B':
    	    	chr = 0xD0;
    		break;
	    case 'C':
	    	chr = 0xCD;
		break;
	    case 'D':
    	    	chr = 0xCB;
    		break;
	    case 0x35:	/* page up */
		(void)getch2();	/* skip 0x7E following */
	    	chr = 0xC9;
		break;
	    case 0x36:	/* page down */
		(void)getch2();	/* skip 0x7E following */
    	    	chr = 0xD1;
    		break;
	    case 0x48:	/* pos1 */
	 	//(void)getch2();	/* skip 0x7E following */
        	chr = 0xC7;
        	break;
	    case 0x46:	/* end */
		//(void)getch2();	/* skip 0x7E following */
            	chr = 0xCF;
            	break;

	    default:
	    	chr = 0x80;
		break;
	}
    }
#endif
    buf[0] = chr;
    i = 1;
    if (buf[0] == '\r') {
	buf[0] = '\n';
    }
#elif defined(_WIN32)
    chr = getch();
    if ((chr & 0x01000000) != 0) {
	/*
	 * detected a mouse click
	 */
	char execString[19 + 4 + 1 + 4 + 1 + 5 + 1];

	sprintf(execString, "win32-button-press %d %d %s",
		(chr & 0xff00) >> 8,
		chr & 0xff,
		(((chr & 0xff0000) >> 16) == 1) ? "left" : "right");
	Tcl_Eval(interp, execString, 0, NULL);
	return;
    }
    buf[0] = chr;
    i = 1;
    if (buf[0] == '\r') {
	buf[0] = '\n';
    }
#elif defined(_MSDOS)
    /*
     * Must check with the keyboard bios explicitly to see if a key is
     * present, to deal with Ctrl+C and Ctrl+Break, which trigger the
     * _kbhit() function, but then cause us to block in wgetch() when the
     * signal is triggered instead.
     */
    if (!_bios_keybrd(_KEYBRD_READY)) {
    	return;
    }
    chr = _bios_keybrd(_KEYBRD_READ);
    buf[0] = (char)(chr & 0xff);
    if (buf[0] == '\r') {
	buf[0] = '\n';
    }

    /*
     * if the low byte is zero then we have a non-ascii value, the high byte
     * is the scan code, so we translate the scan code into a non-ascii
     * value by adding 0xff
     */
    i = 1;
    if (!buf[0])
    {
	chr = 0x80 + (chr >> 8);
    }
#endif

    /*
     * see if this key is currently bound to anything, if so then
     * execute whatever tcl routine it's bound to and be done with it
     */
    if (CursesCheckKeyBinding((unsigned char)(chr & 0xff))) {
	return;
    }

    for (cp = buf; i > 0; cp++, i--) {
	/*
	 * Nuke the showmatch event if it's registered.
	 */
	if (showMatchEvent) {
	    Rpc_EventDelete(showMatchEvent);
	    showMatchEvent = 0;
	}

	(* istate->inProc)(*cp, istate);
    }
}


/*********************************************************************
 *			CursesBindKeyCmd
 *********************************************************************
 * SYNOPSIS: 	binds a key to a function
 * CALLED BY:	global
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	1/27/93		Initial version
 *
 *********************************************************************/
DEFCMD(bind-key,CursesBindKey,TCL_EXACT,NULL,support.binding,
"Usage:\n\
    bind-key <ascii_value> <function>\n\
\n\
Examples:\n\
    \"bind-key \\321 scroll_srcwin_down\" binds scroll-down key \n\
                                    to the scroll_srcwin_down tcl routine\
\n\
Synopsis:\n\
    binds the ascii value to a function\
\n\
See also:\n\
    alias, unbind-key\n\
")
{
    unsigned char	chr;

    if (argc != 3)
    {
	Tcl_RetPrintf(interp, wrongNumArgsString, argv[0]);
	return TCL_ERROR;
    }
    sscanf(argv[1], "%c", (char *)&chr);
    if (keyBindings[chr] != NULL)
    {
	keyBindings[chr] = realloc(keyBindings[chr], strlen(argv[2])+1);
    }
    else
    {
	keyBindings[chr] = malloc(strlen(argv[2])+1);
    }
    strcpy(keyBindings[chr], argv[2]);
    Tcl_Return(interp, argv[2], TCL_OK);
    return TCL_OK;
}

/*********************************************************************
 *			CursesUnbindKeyCmd
 *********************************************************************
 * SYNOPSIS: 	binds a key to a function
 * CALLED BY:	global
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	1/27/93		Initial version
 *
 *********************************************************************/
DEFCMD(unbind-key,CursesUnbindKey,TCL_EXACT,NULL,support.binding,
"Usage:\n\
    unbind-key <ascii_value>\n\
\n\
Examples:\n\
    \"unbind-key \\321\" unbinds scroll-down key \n\
\n\
Synopsis:\n\
    unbinds the passed ascii value \
\n\
See also:\n\
    alias, bind-key\n\
")
{
    unsigned char	chr;

    if (argc != 2)
    {
	Tcl_RetPrintf(interp, wrongNumArgsString, argv[0]);
	return TCL_ERROR;
    }
    sscanf(argv[1], "%c", (char *)&chr);
    if (keyBindings[chr] != NULL)
    {
	free(keyBindings[chr]);
	keyBindings[chr] = (char *)NULL;
    }

    Tcl_Return(interp, argv[1], TCL_OK);
    return TCL_OK;
}

/*********************************************************************
 *			CursesGetKeyBindingCmd
 *********************************************************************
 * SYNOPSIS: 	binds a key to a function
 * CALLED BY:	global
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	1/27/93		Initial version
 *
 *********************************************************************/
DEFCMD(get-key-binding,CursesGetKeyBinding,TCL_EXACT,NULL,support.binding,
"Usage:\n\
    get-key-binding <char>\n\
\n\
Synopsis:\n\
    gets key binding for given key\
\n\
Example:\n\
    \"get-key-binding c\"  	gets key binding for the characeter c\n\
    \"get-key-binding \\045\"	gets key binding for the % key\n\
See also:\n\
    alias, bind-key, unbind-key\n\
")
{
    unsigned char    chr;

    if (argc != 2)
    {
	Tcl_RetPrintf(interp, wrongNumArgsString, argv[0]);
	return TCL_ERROR;
    }
    sscanf(argv[1], "%c", (char *)&chr);
    Tcl_Return(interp, keyBindings[chr]==NULL ? "" : keyBindings[chr], TCL_OK);
    return TCL_OK;
}

/***********************************************************************
 *				CursesReadLineCmd
 ***********************************************************************
 * SYNOPSIS:	    Read a line of input from the current window.
 * CALLED BY:	    Tcl
 * RETURN:	    The line input minus its newline
 * SIDE EFFECTS:    Maybe...
 *
 * STRATEGY:
 *	Turn on observation of stream 0.
 *	Figure out if we're going for a command and set CURSES_READCMD
 *	    accordingly.
 *	Loop on Rpc_Wait until CURSES_LINEREADY is set.
 *	Return the line after nuking the final newline.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(read-line,CursesReadLine,TCL_EXACT,NULL,swat_prog.input,
"Usage:\n\
    read-line [<isTcl> [<initial input> [<special chars>]]]\n\
\n\
Examples:\n\
    \"read-line\"			reads a single line of text.\n\
    \"read-line 1\"		reads a TCL command.\n\
    \"read-line 1 {go }\"		reads a TCL command that starts with \"go \"\n\
    \"read-line 1 {} {\e\4}\"	reads a TCL command, considering escape\n\
				and control-d cause for immediate return,\n\
				regardless of whether braces and brackets\n\
				are balanced\n\
\n\
Synopsis:\n\
    Reads a line of input from the user, optionally handling multi-line\n\
    Tcl commands, initial editable input, and special immediate-return\n\
    characters.\n\
\n\
Notes:\n\
    * If <isTcl> is non-zero, the input may span multiple lines, as\n\
      read-line will not return until all braces and brackets are\n\
      properly balanced, according to the rules of TCL. This behaviour\n\
      may be overridden by the <special chars> argument.\n\
\n\
    * If <initial input> is given and non-empty, it is taken to be the\n\
      initial contents of the input line and may be edited by the user\n\
      just as if s/he had typed it in. The string is *not* automatically\n\
      displayed, however; that is up to the caller.\n\
\n\
    * <special chars> is an optional string of characters that will cause\n\
      this routine to return immediately. The character that caused the\n\
      immediate return is left as the last character of the string returned.\n\
      You may use standard backslash escapes to specify the characters. This\n\
      will return even if the user is entering a multi-line Tcl command whose\n\
      braces and brackets are not yet balanced.\n\
\n\
    * The user's input is returned as a single string with the final newline\n\
      stripped off.\n\
\n\
See also:\n\
    top-level-read\n\
")
{
    char    	    	*cp;
    int	    	    	length;
    CursesInputState	state;

#if defined(_LINUX)
    system(SWATWCTL_FOCUS);
#endif
    wrefresh(cmdWin);
    fflush(stdout);

    Rpc_Push(0);

    Rpc_Watch(0, RPC_READABLE, CursesReadInput, (Rpc_Opaque)&state);
#if defined(_MSDOS)
    Mouse_Watch();
#endif

    /*
     * Save old input values
     * XXX: use structure passed as opaque data to Rpc_Watch instead
     */
    state.inProc = CursesInputChar;

    state.input = Buf_Init(256);
    state.cursPos = state.lineLength = 0;
    state.markPos = -1;

    if (cutBuf == NULL) {
	cutBuf = Buf_Init(256);
	cutLength = 0;
    }
    if (argc > 1 && atoi(argv[1]) > 0) {
	state.flags = CISF_READCMD;
    } else {
	state.flags = 0;
    }
    /*
     * Add any initial input to the buffer first.
     */
    if (argc > 2) {
	/*
	 * Figure the number of characters on the last line of the initial
	 * input.
	 */
	for (cp = argv[2], state.lineLength = 0; *cp != '\0'; cp++) {
	    if (*cp != '\n') {
		state.lineLength++;
	    } else {
		state.lineLength = 0;
	    }
	}
	state.cursPos = state.lineLength;
	Buf_AddBytes(state.input, strlen(argv[2]), (Byte *)argv[2]);
    }

    /*
     * Form array of immediate-return chars if argument given.
     */
    if (argc > 3) {
	char	**endList;
	int 	numEndElts;
	int	e;

	if (Tcl_SplitList(interp, argv[3], &numEndElts, &endList) != TCL_OK) {
	    return(TCL_ERROR);
	}

	for (length = 0, e = 0; e < numEndElts; e++) {
	    length += strlen(endList[e]);
	}
	state.endChars = cp = (char *)malloc_tagged(length+1, TAG_CURSES);

	for (e = 0; e < numEndElts; e++) {
	    strcpy(cp, endList[e]);
	    cp += strlen(cp);
	}
	free((char *)endList);
    } else {
	/*
	 * Immediate-return chars not given, so set to empty string.
	 */
	state.endChars = defEndChars;
    }

    /*
     * Form array of word-delineating chars if argument given.
     */
    if (argc > 4) {
	char	**wordList;
	int 	numWordElts;
	int	e;

	if (Tcl_SplitList(interp, argv[4], &numWordElts, &wordList) != TCL_OK)
	{
	    return(TCL_ERROR);
	}

	for (length = 0, e = 0; e < numWordElts; e++) {
	    length += strlen(wordList[e]);
	}
	state.wordChars = cp = (char *)malloc_tagged(length+1, TAG_CURSES);

	for (e = 0; e < numWordElts; e++) {
	    strcpy(cp, wordList[e]);
	    cp += strlen(cp);
	}
	free((char *)wordList);
    } else {
	/*
	 * Immediate-return chars not given, so just use space & \t
	 */
	state.wordChars = defWordChars;
    }

    /*
     * Fill in the user specified command line editing keystrokes, if passed
     */
    if (argc > 5) {
	char	**cleList;
	int 	numCleElts;
	int     e;

	if (Tcl_SplitList(interp, argv[5], &numCleElts, &cleList) != TCL_OK) {
	    return(TCL_ERROR);
	}

	if (strlen(cleList[0]) != NUM_CLE_CHARS) {
	    cp = defCleChars;
	} else {
	    cp = cleList[0];
	}
	/*
	 * Use the passed string. We'll assume that a-z and A-Z have
	 * an implied <ctrl> in front of 'em.
	 */
	for (e = 0; e < NUM_CLE_CHARS; e++) {
	    if ((cleList[0][e] >= 'a') && (cleList[0][e] <= 'z')) {
		state.cleChars[e] = cleList[0][e] - 'a' + '\001';
	    } else if ((cleList[0][e] >= 'A') && (cleList[0][e] <= 'Z')) {
		state.cleChars[e] = cleList[0][e] - 'A' + '\001';
	    } else {
		state.cleChars[e] = cleList[0][e];
	    }
	}
	free((char *)cleList);
    } else {
	int    e;
	/*
	 * cle chars not given, so screw command line editing
	 */
	for (e = 0; e < NUM_CLE_CHARS; e++) {
	    state.cleChars[e] = (char)-1;
	}
    }
    /*
     * Null-terminate cleChars array so strchr() can be used on it.
     */
    state.cleChars[NUM_CLE_CHARS] = '\0';

    state.next = inStateTop;
    inStateTop = &state;

    while (!(state.flags & CISF_LINEREADY)) {
	Rpc_Wait();
    }

    cp = (char *)Buf_GetAll(state.input, &length);

    if (cp[length-1] == '\n') {
	cp[length-1] = '\0';
    }

    Buf_Destroy(state.input, FALSE);

#if 0
    Buf_Destroy(cutBuf, FALSE);
#endif

    if (state.endChars != defEndChars) {
	free((char *)state.endChars);
    }

    if (state.wordChars != defWordChars) {
	free((char *)state.wordChars);
    }

    /*
     * Pop to previous input parameters.
     */
    inStateTop = state.next;

    Rpc_Pop(0);

#if defined(_LINUX)
    system(SWATWCTL_RESTORE);
#endif

    /*
     * Clear the interrrupt-pending flag to avoid annoying people
     */
    Ui_ClearInterrupt();

    Tcl_Return(interp, cp, TCL_DYNAMIC);
    return(TCL_OK);
}

/***********************************************************************
 *				CursesReadCharCmd
 ***********************************************************************
 * SYNOPSIS:	    Read a single character from the terminal
 * CALLED BY:	    Tcl
 * RETURN:	    The character read (as a string).
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    ...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
static void
CursesReadChar(int 	    stream,
	       Rpc_Opaque   data,   	/* Pointer to storage spot. Initialized
					 * to echo flag */
	       int 	    state)
{
    unsigned int    chr;
    Boolean doEcho = *(char *)data;
#if defined(_MSDOS) || defined(_WIN32)
    char    	    buf[1];
#endif

#if defined(unix) || defined(_LINUX)
    chr = getch2();
#elif defined(_WIN32)
    /* is this section going to work right, maybe getchar()?
     * same as above */
    chr = buf[0] = getch();
    if (buf[0] == '\r') {
	buf[0] = '\n';
    }
#elif defined(_MSDOS)
    /*
     * Must check with the keyboard bios explicitly to see if a key is
     * present, to deal with Ctrl+C and Ctrl+Break, which trigger the
     * _kbhit() function, but then cause us to block in wgetch() when the
     * signal is triggered instead.
     */
    if (!_bios_keybrd(_KEYBRD_READY)) {
    	return;
    }
    chr = _bios_keybrd(_KEYBRD_READ);
    buf[0] = (char)(chr & 0xff);
    if (buf[0] == '\r') {
	buf[0] = '\n';
    }
    /* if the low byte is zero then we have a non-ascii value, the high byte
     * is the scan code, so we translate the scan code into a non-ascii
     * value by adding 0xff
     */
    if (!buf[0])
    {
	chr = 0x80 + (chr >> 8);
    }

#endif
    /* here we see if the inputed key was bound to anything, if so
     * the bound code is run and we return 0x80 which is a special
     * token telling the caller to ignore this input
     */
    if (CursesCheckKeyBinding((unsigned char)(chr & 0xff)))
    {
	*(char *)data = 0x80;
    } else {
    	*(char *)data = chr;
    }
    if (doEcho) {
	waddch(curWin, (unsigned char)chr);
	wrefresh(curWin);
    }
}

/***********************************************************************
 *				CursesReadCharCmd
 ***********************************************************************
 * SYNOPSIS:	    Command to read a single character from the user
 * CALLED BY:	    Tcl
 * RETURN:	    The character read.
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *	Uses CursesReadChar to read just a single character.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/12/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(read-char,CursesReadChar,TCL_EXACT,NULL,swat_prog.input,
"Usage:\n\
    read-char [<echo>]\n\
\n\
Examples:\n\
    \"read-char 0\"	Read a single character from the user and don't echo it.\n\
\n\
Synopsis:\n\
    Reads a character from the user.\n\
\n\
Notes:\n\
    * If <echo> is non-zero or absent, the character typed will be echoed.\n\
\n\
See also:\n\
    read-line.\n\
")
{
    signed char c;

    /*
     * Make sure the screen's up-to-date
     */
    wrefresh(curWin);
    fflush(stdout);

    Rpc_Push(0);

#if defined(_LINUX)
    system(SWATWCTL_FOCUS);
#endif

    Rpc_Watch(0, RPC_READABLE, CursesReadChar, (Rpc_Opaque)&c);
#if defined(_MSDOS)
    Mouse_Watch();
#endif

    if (argc == 2 && !atoi(argv[1])) {
	c = 0;
    } else {
	c = -1;
    }

    while(c == 0 || c == -1) {
	Rpc_Wait();
    }
    Rpc_Pop(0);
#if defined(_MSDOS)
    Mouse_Ignore();
#endif
#if defined(_LINUX)
    system(SWATWCTL_RESTORE);
#endif
    Tcl_RetPrintf(interp, "%c", c);
    return(TCL_OK);
}

/***********************************************************************
 *				CursesNumColumns
 ***********************************************************************
 * SYNOPSIS:	    Return the number of columns available
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The number of columns
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
static int
CursesNumColumns(void)
{
    return COLS;
}

/***********************************************************************
 *				CursesSaveCmd
 ***********************************************************************
 * SYNOPSIS:	    Set the size of the scroll buffer.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    Scroll buffer may be trimmed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 9/88	Initial Revision
 *	eds 	6/15/89	    	Made help string comprehensible.
 *
 ***********************************************************************/

#define MAX_PATH 128
DEFCMD(save,CursesSave,TCL_EXACT,NULL,top.support,
"Usage:\n\
    save (<#lines> | <filename>)\n\
\n\
Examples:\n\
    \"save 1000\"	    	    Save the last 1000 lines that scroll off the screen.\n\
    \"save puffball\" 	    Save the contents of the entire scroll buffer to\n\
			    the file \"puffball\".\n\
\n\
Synopsis:\n\
    Controls the scrollback buffer Swat maintains for its main command window.\n\
\n\
Notes:\n\
    * If the argument is numeric, it sets the number of lines to save (the\n\
      default is 1,000).\n\
\n\
    * If the argument is anything else, it's taken to be the name of a file\n\
      in which the current buffer contents (including the command window)\n\
      should be saved. If the <filename> is relative, it is taken relative\n\
      to the directory in which the executable for the patient to which the\n\
      current stack frame's function belongs is located. If the file already\n\
      exists, it is overwritten.\n\
\n\
See also:\n\
    none.\n\
")
{
    LinePtr 	lp;

    if (argc == 2) {
	char    *firstArg;
	int 	n;
	long    numWritten = 0;
	int     returnCode;
	char	*cp;
	char	*dataStart;
#if defined(_WIN32)
	char	*asciiBuf;
	int	j;
#endif

	n = cvtnum(argv[1], &firstArg);
	if ((firstArg == argv[1]) || (*firstArg != '\0')) {
	    /*
	     * Argument not numeric -- treat it as a file name
	     */
	    FileType f;
	    int	     i;
	    const char *path;

	    if (File_CheckAbsolute(argv[1]) == FALSE) {
		path = File_PathConcat((char *)Tcl_GetVar(interp, "file-devel-dir",
						  TRUE),
				       argv[1], 0);
	    } else {
		path = argv[1];
	    }

	    returnCode = FileUtil_Open(&f, path, O_WRONLY|O_TEXT|O_CREAT,
				       SH_DENYWR, 0666);
	    if (returnCode == FALSE) {
		char errmsg[512];

		FileUtil_SprintError(errmsg, "problem openning save file");
		MessageFlush("%s", errmsg);
		Tcl_RetPrintf(interp, "Couldn't open %s", path);
		if (path != argv[1]) {
		    free((char *)path);
		}
		return(TCL_ERROR);
	    }

	    MessageFlush("Saving to %s: ", path);
#if defined(_WIN32)
	    asciiBuf = (char *)malloc(COLS * sizeof(char));
#endif
	    /*
	     * Print all the lines in the buffer, trimming of any
	     * whitespace at the end of each line.
	     */

	    for (lp = lineTail; lp != NULL; lp = lp->prev) {
#if defined(_WIN32)
		for(j=0;j<COLS;j++) {
		    if ((lp->line[j].uniChar >> 8) != 0) {
			/*
			 * non-ascii unicode character
			 */
			asciiBuf[j] = '~';
		    } else {
			asciiBuf[j] = lp->line[j].uniChar & 0xff;
		    }
		}
		cp = &asciiBuf[COLS];
		dataStart = asciiBuf;
#else
		cp = &lp->line[COLS];
		dataStart = lp->line;
#endif
		while (isspace(*--cp) && (cp > dataStart)) {
		    ;
		}
		FileUtil_Write(f, dataStart, (cp-dataStart) + 1, &numWritten);
		FileUtil_Write(f, "\r\n", 2, &numWritten);
	    }

	    /*
	     * Ditto for those currently on-screen
	     */
	    for (i = 0; i < cmdWin->_maxy; i++) {
#if defined(_WIN32)
		for(j=0;j<COLS;j++) {
		    if ((cmdWin->_y[i][j].uniChar >> 8) != 0) {
			/*
			 * non-ascii unicode character
			 */
			asciiBuf[j] = '~';
		    } else {
			asciiBuf[j] = cmdWin->_y[i][j].uniChar & 0xff;
		    }
		}
		cp = &asciiBuf[COLS];
		dataStart = asciiBuf;
#else
		cp = &cmdWin->_y[i][COLS];
		dataStart = cmdWin->_y[i];
#endif
		while (isspace(*--cp) && (cp > dataStart)) {
		    ;
		}
		FileUtil_Write(f, dataStart, (cp - dataStart) + 1,
			       &numWritten);
		FileUtil_Write(f, "\r\n", 2, &numWritten);
	    }
	    (void)FileUtil_Close(f);
#if defined(_WIN32)
	    free(asciiBuf);
#endif
	    if (path != argv[1]) {
		free((char *)path);
	    }

	} else {
	    if (n < LINES) {
		n = LINES;
	    }

	    maxSaved = n;

	    for (lp=lineTail; numSaved > maxSaved; lp=lineTail, numSaved--) {
		free((void *)lp->line);
		lineTail = lineTail->prev;
		free((void *)lp);
	    }
	}
    }

    Tcl_RetPrintf(interp, "%d lines", maxSaved);
    return(TCL_OK);
}

#ifdef _WIN32
/***********************************************************************
 *				CursesSLogCmd
 ***********************************************************************
 * SYNOPSIS:	    Set the size of the scroll buffer.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    Scroll buffer may be trimmed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *      kliu    10/30/96        Initial version
 *
 ***********************************************************************/
DEFCMD(slog,CursesSLog,TCL_EXACT,NULL,top.support,
"Usage:\n\
     slog <filestream>\n\
\n\
Examples:\n\
    \"slog $stream1\" 	    Save the contents of the scroll buffer and contents in \n\
                            current window to stream1. \n\
\n\
Synopsis:\n\
    Saves the contents in scroll buffer up to the number of lines set by \"save\",\n\
    to the screen provided by the user. The contents in the current window will be \n\
    saved up to the current position. \n\
\n\
See also:\n\
    save, stream \n\
")
{
    LinePtr 	lp;
    Stream      *stream = 0;
    ntcCell        *cp;
    int         i;


    if (argc != 2) {
	Tcl_RetPrintf(interp, wrongNumArgsString, argv[0]);
	return (TCL_ERROR);
    }

    stream = (Stream *)atoi(argv[1]);
    if (!VALIDTPTR(stream,TAG_STREAM)) {
	Tcl_RetPrintf(interp, "%s: not a stream", argv[1]);
	return(TCL_ERROR);
    }

    if (stream->type != STREAM_FILE) {
	Tcl_RetPrintf(interp, "%s: not a file stream", argv[1]);
	return (TCL_ERROR);
    }

    /*
     * Print all the lines in the buffer, trimming of any whitespace
     * at the end of each line.
     */

    for (lp = lineTail; lp != NULL; lp = lp->prev) {
	cp = &lp->line[COLS];
        while (isspace((*--cp).uniChar) && cp > (lp->line)) {
	    ;
	}
	fprintf(stream->file, "%.*s\n", cp - lp->line + 1, lp->line);
    }

    /*
     * Ditto for those currently on-screen
     */
    for (i = 0; i < cmdWin->_cury; i++) {
	cp = &cmdWin->_y[i][COLS];
	while (isspace((*--cp).uniChar) && cp > cmdWin->_y[i]) {
	    ;
	}

	fprintf(stream->file, "%.*s\n", cp-cmdWin->_y[i] + 1, cmdWin->_y[i]);
    }

    return(TCL_OK);
}


/***********************************************************************
 *				CursesSBClrCmd
 ***********************************************************************
 * SYNOPSIS:	    Clear contents in scroll buffer.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	kliu    10/30/96        Initial version
 *
 ***********************************************************************/
DEFCMD(sbclr,CursesSBClr,TCL_EXACT,NULL,swat_prog.output,
"Usage: \n\
    sbclr \n\
\n\
Synposis: \n\
      Frees all the lines saved in the scroll buffer. \n\
\n\
Notes: \n\
      Use \"wclear\" in conjun \n\
\n\
See also: \n\
      wclear \n\
")
{
    LinePtr lp;

    if (argc != 1) {
	Tcl_RetPrintf(interp, wrongNumArgsString, argv[0]);
	return (TCL_ERROR);
    }

    /* free all lines in the scroll buffer */

    for (lp = lineTail; numSaved > 0; lp=lineTail, numSaved--) {
	free((char *)lp->line);
	lineTail = lineTail->prev;
	free((char *)lp);
    }
    lineTail = lineHead = lineCur = NullLine;
    return (TCL_OK);
}
#endif


/***********************************************************************
 *				CursesEchoCmd
 ***********************************************************************
 * SYNOPSIS:	    Print output to the current window
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 9/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(echo,CursesEcho,TCL_EXACT,NULL,swat_prog.output,
"Usage:\n\
    echo [-n] <string>+\n\
\n\
Examples:\n\
    \"echo -n yes?\"	Prints \"yes?\" without a newline.\n\
    \"echo hi mom\"   	Prints \"hi mom\" followed by a newline.\n\
\n\
Synopsis:\n\
    Prints its arguments, separated by spaces.\n\
\n\
Notes:\n\
    * If the first argument is \"-n\", no newline is printed after the arguments.\n\
\n\
See also:\n\
    flush-output.\n\
")
{
    int	    	i;
    Boolean	noNL;

    if ((argc > 1) && (strcmp(argv[1], "-n") == 0)) {
	noNL = TRUE;
	argc--;
	argv++;
    } else {
	noNL = FALSE;
    }
    for (i = 1; i < argc; i++) {

	/*
	 * Process line by line, because internal format buffer
	 * is limited to 512 bytes.
	 */
	char*		ptr = argv[i];
	while(*ptr) {

	    char*	eol = ptr;
	    while((*eol != 0) && (*eol != '\n')) eol++;

	    {
	    	char 	saved = *eol;

	    	*eol = NULL;
	    	wprintw(curWin, ptr);
	    	*eol = saved;
            	ptr = eol;
		if( *ptr != NULL ) {
		    ptr++;
		    waddch(curWin, '\n');
	        }
	    }
        }
	if(i != argc-1) {
	    waddch(curWin, ' ');
	}
    }

    if (!noNL) {
	/*
	 * Refreshes here are line-buffered. In addition, we only do the
	 * refresh if not on the last line of the window. If we're on
	 * the last line of the window, scroll should be called and the
	 * window refreshed. Of course, this only applies if the
	 * window can be scrolled, so we notice that as well....
	 */
	waddch(curWin, '\n');

	if (curWin->_scroll && (curWin->_cury!=curWin->_maxy)) {
	    wrefresh(curWin);
	}
    }
    return (TCL_OK);
}

/***********************************************************************
 *				CursesSystemCmd
 ***********************************************************************
 * SYNOPSIS:	    Fork a shell to execute a command
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK and the code returned by system()
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(system,CursesSystem,TCL_EXACT,NULL,swat_prog.external,
"Usage:\n\
    system <command>\n\
\n\
Examples:\n\
    \"system {chkdsk d:}\"	Runs the chkdsk command on your D drive\n\
    \"system {vi /tmp/whuffle}\"	Runs vi to edit /tmp/whuffle\n\
\n\
Synopsis:\n\
    Causes Swat to execute another program, giving it complete control of the\n\
    screen.\n\
\n\
Notes:\n\
    * A shell is always used to execute the command. Under UNIX, this is the\n\
      Bourne shell, so tildes in file names aren't expanded. Under DOS, this\n\
      is what your COMSPEC environment variable says to use.\n\
\n\
    * This command doesn't return until the command it runs is done. The output\n\
      of the command goes straight to the screen and isn't saved anywhere.\n\
\n\
    * Returns the numeric code with which the command executed. This is usually\n\
      0 if the command was happy, or non-zero if it wasn't.\n\
\n\
See also:\n\
    exec\n\
")
{
    int	    	    rval;
#if defined(unix)
    struct sgttyb   osgb;
    struct ltchars  oltc;
#endif

    if (argc != 2) {
	Tcl_Error(interp, "Usage: system <command>");
    }

    /*
     * Take down window system...
     */
#if defined(unix)
    osgb = _tty;
#endif
    mvcur(0, COLS-1, LINES-1, 0);
    endwin();
#if defined(unix)
    ioctl(_tty_ch, TIOCGLTC, &oltc);
    ioctl(_tty_ch, TIOCSLTC, &ltc);
#endif
    fflush(stdout);

#if defined(unix)
    /*
     * Don't do anything special if the user stops the command we're executing
     */
    signal(SIGTSTP, SIG_DFL);
#endif

    /*
     * Invoke the command
     */
    rval = system(argv[1]);

    /*
     * Put windows back up
     */
#if defined(unix)
    _tty = osgb;
    (void)ioctl(_tty_ch, TIOCSETN, &_tty);
    (void)ioctl(_tty_ch, TIOCSLTC, &oltc);
#endif
    wrefresh(curscr);

    /*
     * Catch stops again
     */
#if defined(unix)
    signal(SIGTSTP, CursesTstp);
#endif

    Tcl_RetPrintf(interp, "%d", rval);
    return(TCL_OK);
}

/***********************************************************************
 *				CursesWCreateCmd
 ***********************************************************************
 * SYNOPSIS:	    Create a window of the given number of lines
 * CALLED BY:	    Tcl
 * RETURN:	    A token for the window
 * SIDE EFFECTS:    cmdWin is shrunk and the extra lines pushed into the
 *	    	    scroll buffer.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 9/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(wcreate,CursesWCreate,TCL_EXACT,NULL,swat_prog.window,
"Usage:\n\
    wcreate <num-lines>\n\
\n\
Examples:\n\
    \"wcreate 3\"	    Creates a 3-line window just below the command window.\n\
\n\
Synopsis:\n\
    Creates a window into which output may be placed without disturbing or\n\
    being disturbed by the main command window.\n\
\n\
Notes:\n\
    * Whether the window appears immediately below or above the main command\n\
      window is determined by the \"wtop\" command. By default, windows appear\n\
      below the main window.\n\
\n\
    * The window is always the full width of the screen.\n\
\n\
    * If there aren't <num-lines> available on the screen, this generates an\n\
      error.\n\
\n\
    * Returns a window token to be used for later references to the window.\n\
\n\
See also:\n\
    wdelete, wpush, wrefresh, wpop.\n\
")
{
    int	    height;
    LinePtr lp;
    int	    i;
    WINDOW  *w;

    if (argc != 2) {
	Tcl_Error(interp, "Usage: wcreate <height>");
    }

    height = atoi(argv[1]);

    if (height <= 0) {
	Tcl_RetPrintf(interp, "%d is an illegal window size", height);
	return(TCL_ERROR);
    }

    if (cmdWin->_maxy - height < MIN_CMD_HEIGHT) {
	Tcl_RetPrintf(interp, "screen too small to hold %d-line window",
		      height);
	return(TCL_ERROR);
    }
    if (windowsOnTop) {
	if (borderWin != (WINDOW *)NULL) {
	    w = newwin(height, 0, cmdWin->_begy-1, 0);
	} else {
	    w = newwin(height, 0, 0, 0);
	}
    } else {
	if (borderWin != (WINDOW *)NULL) {
	    w = newwin(height, 0, cmdWin->_maxy+1-height, 0);
	} else {
	    w = newwin(height, 0, cmdWin->_maxy-height, 0);
	}
    }

    if (w == NULL) {
	Tcl_Error(interp, "Couldn't allocate new window");
    }

    /*
     * It's ok to leave the cursor after the last change when refreshing this
     * thing as it (1) draws attention to the thing and (2) makes no
     * difference as any changes to it will immediately be counteracted by
     * the fetching of input from the cmdWin.
     */
    leaveok(w, TRUE);

    malloc_settag((char *)w, TAG_CWIN);
    (void)Lst_AtEnd(windows, (LstClientData)w);

    if (borderWin == (WINDOW *)NULL) {
	if (windowsOnTop) {
	    borderWin = newwin(1, 0, height, 0);
	} else {
	    borderWin = newwin(1, 0, cmdWin->_maxy-height-1, 0);
	}
	malloc_settag((char *)borderWin, TAG_CWIN);
	height += 1;
	for (i = 0; i < COLS; i++) {
	    waddch(borderWin, '=');
	}
    }

    /*
     * Make sure cmdWin is in synch so we needn't deal with firstch and
     * lastch
     */
    wrefresh(cmdWin);

    /*
     * Shift the top lines into the save buffer.
     */
    for (i = 0; i < height; i++) {
	if (cmdWin->_cury == cmdWin->_maxy - 1) {
	    /*
	     * No more lines to biff. Save the top-most line in the scroll
	     * buffer.
	     */
	    if (windowsOnTop) {
		if (numSaved < maxSaved) {
		    lp = (LinePtr)malloc_tagged(sizeof(LineRec), TAG_CURSES);
		    numSaved++;
		} else {
		    lp = lineTail;
		    free((void *)lp->line);
		    lineTail = lineTail->prev;
		    lineTail->next = NullLine;
		}

		lp->line = cmdWin->_y[i];
		lp->prev = NullLine;
		lp->next = lineHead;

		if (lineTail != NullLine) {
		    lineHead->prev = lp;
		    lineHead = lp;
		} else {
		    lineHead = lineTail = lp;
		}
	    } else {
		scroll(cmdWin);
	    }
	} else {
	    if (windowsOnTop) {
		/*
		 * Shift the window down one line, nuking the final one.
		 */
		scrollnow_hideMouse(cmdWin, -1);
	    }
	    /*
	     * Increase _cury to deal with subtraction when this loop is
	     * done.
	     */
	    cmdWin->_cury += 1;
	}
    }

    /*
     * Adjust max and beginning y, then copy the remaining lines to the
     * top of the window -- no need to refresh since they're still the
     * same on-screen.
     */
    cmdWin->_maxy -= height;
    cmdWin->_cury -= height;
    if (windowsOnTop) {
	cmdWin->_begy += height;
	bcopy((char *)&cmdWin->_y[height], (char *)&cmdWin->_y[0],
	      cmdWin->_maxy * sizeof(cursesChar *));
	/*
	 * Shift the border to just above the command window and redraw it
	 */
	mvwin(borderWin, cmdWin->_begy - 1, 0);
    } else {
	/*
	 * Free up excess lines allocated by scrolling.
	 */
	for (i = cmdWin->_maxy; i < cmdWin->_maxy+height; i++) {
	    free((void *)cmdWin->_y[i]);
	}
	/*
	 * Shift the border to just below the command window and redraw it
	 */
	mvwin(borderWin, cmdWin->_maxy, 0);
    }

    cmdWin->_flags &= ~_FULLWIN;

    wrefresh(borderWin);
    /*
     * Make sure the whole thing is updated when the window is first
     * refreshed.
     */
    touchwin(w);

    Tcl_RetPrintf(interp, "%d", w);
    return(TCL_OK);
}

/***********************************************************************
 *				CursesWFindCmd
 ***********************************************************************
 * SYNOPSIS:	    Find the window containing the given position
 * CALLED BY:	    Tcl
 * RETURN:	    token for window
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 1/93		Initial Revision
 *
 ***********************************************************************/
DEFCMD(wfind,CursesWFind,TCL_EXACT,NULL,swat_prog.window,
"Usage:\n\
    wfind <x> <y>\n\
\n\
Examples:\n\
    \"wfind $mousex $mousey\"	Return the token for the window under the mouse\n\
\n\
Synopsis:\n\
    Locates the window that contains a given screen coordinate and returns\n\
    its token.\n\
\n\
Notes:\n\
    * Returns {} if no window under the given point\n\
\n\
See also:\n\
    wdim\n\
")
{
    LstNode ln;
    WINDOW  *w;
    int	    x, y;

    if (argc != 3) {
	Tcl_Error(interp, "Usage: wfind <x> <y>");
    }

    x = cvtnum(argv[1], NULL);
    y = cvtnum(argv[2], NULL);

#define InWindow(w,x,y) \
    (((w)->_begx <= (x) && (x) < (w)->_begx + (w)->_maxx) && \
     ((w)->_begy <= (y) && (y) < (w)->_begy + (w)->_maxy))

    if (InWindow(cmdWin, x, y)) {
	Tcl_RetPrintf(interp, "%d", cmdWin);
	return(TCL_OK);
    } else if (borderWin != NULL && InWindow(borderWin, x, y)) {
	Tcl_RetPrintf(interp, "%d", borderWin);
	return(TCL_OK);
    }

    for (ln = Lst_First(windows); ln != NILLNODE; ln = Lst_Succ(ln)) {
	w = (WINDOW *)Lst_Datum(ln);

	if (InWindow(w,x,y)) {
	    Tcl_RetPrintf(interp, "%d", w);
	    return(TCL_OK);
	}
    }

    Tcl_Return(interp, NULL, TCL_STATIC);
    return(TCL_OK);
}


/***********************************************************************
 *				CursesWDimCmd
 ***********************************************************************
 * SYNOPSIS:	    Return the dimensions of the given window
 * CALLED BY:	    Tcl
 * RETURN:	    origin + width/height
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 1/93		Initial Revision
 *
 ***********************************************************************/
DEFCMD(wdim,CursesWDim,TCL_EXACT,NULL,swat_prog.window,
"Usage:\n\
    wdim <window>\n\
\n\
Examples:\n\
    \"wdim $window\"	Returns the origin & dimensions of the given window\n\
\n\
Synopsis:\n\
    Extracts the origin and dimensions of a window, for use in calculating\n\
    the layout of echoed things, for example.\n\
\n\
Notes:\n\
    * The value returned is a 4-list: {width height origin-x origin-y}\n\
\n\
    * Coordinates are 0-origin\n\
\n\
See also:\n\
    wfind\n\
")
{
    WINDOW  *w;

    if (argc != 2) {
	Tcl_Error(interp, "Usage: wdim <window>");
    }
    w = (WINDOW *)atoi(argv[1]);
    if (!VALIDTPTR(w,TAG_CWIN)) {
	Tcl_RetPrintf(interp, "%s: not a window", argv[1]);
	return(TCL_ERROR);
    }

    Tcl_RetPrintf(interp, "%d %d %d %d",
		  w->_maxx, w->_maxy, w->_begx, w->_begy);
    return(TCL_OK);
}

/***********************************************************************
 *				CursesWDeleteCmd
 ***********************************************************************
 * SYNOPSIS:	    Delete a window from the screen
 * CALLED BY:	    Tcl
 * RETURN:	    Nothing
 * SIDE EFFECTS:    All windows below it are moved up and cmdWin expanded
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 9/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(wdelete,CursesWDelete,TCL_EXACT,NULL,swat_prog.window,
"Usage:\n\
    wdelete <window>\n\
\n\
Examples:\n\
    \"wdelete [index $disp 2]\"	Deletes the window whose token is stored as\n\
				the 3rd element of $disp\n\
\n\
Synopsis:\n\
    Deletes a window and enlarges the command window accordingly.\n\
\n\
Notes:\n\
    * If \"wtop 1\" has been executed, all windows below the one being deleted\n\
      shuffle up, else all windows above the one being deleted shuffle down.\n\
\n\
See also:\n\
    wcreate\n\
")
{
    LstNode 	wln, ln;
    LinePtr 	lp;
    int	    	i;
    WINDOW  	*w;
    int	    	y;

#if defined(_MSDOS)
    int 	startX, startY, endX, endY;
    int     lines = 1;
    Boolean scrolledUp = FALSE;
#endif
#if defined(_WIN32)
    int		j;
#endif

    if (argc != 2) {
	Tcl_Error(interp, "Usage: wdelete <window>");
    }

    w = (WINDOW *)atoi(argv[1]);
    if (!VALIDTPTR(w,TAG_CWIN)) {
	Tcl_RetPrintf(interp, "%s: not a window", argv[1]);
	return(TCL_ERROR);
    }
    if (w == cmdWin) {
	Tcl_Error(interp, "deleting the command window is not allowed");
    }

    if (w == borderWin) {
	Tcl_Error(interp, "deleting the border window is not allowed");
    }

    wln = Lst_Member(windows, (LstClientData)w);
    assert(wln != NILLNODE);

    wrefresh(cmdWin);

    /*
     * Shift all windows "above" this one to cover it.
     */
    if (windowsOnTop) {
	y = w->_begy;
	delwin(w);
	for (ln = Lst_Succ(wln); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    w = (WINDOW *)Lst_Datum(ln);

	    mvwin(w, y, 0);
	    wrefresh(w);
	    y += w->_maxy;
	}
    } else {

#if defined(_MSDOS)
	/*
	 * So, do we have a highlight onscreen?
	 */
	if (CursesConvertMouseHighlightToCoords(&startX,
						&startY,
						&endX,
						&endY) != (char *) NULL) {
	    /*
	     * Yes. Set the amount by which we will adjust the highlight if
	     * it turns out we need to.
	     */
	    lines = -(w->_maxy);
	    /*
	     * Are we at the bottom of the cmdWin?
	     */
	    if (cmdWin->_cury >= cmdWin->_maxy - 1) {
		/*
		 * Yes. We will have to scroll the cmdWin down in order
		 * to fill the space left when we get rid of window w, which
		 * means we'll have to move the highlight.
		 */
		scrolledUp = TRUE;
	    }
	    /*
	     * If there's a highlight onscreen (lines <= 0) and if it
	     * needs updating (scrolledUp == TRUE), then we turn it off
	     * at its old position now, before we start scrolling. We
	     * save the mouse_highlight tcl variable however, since we'll
	     * need it to calculate the new position.
	     */
	    if (lines <= 0 && scrolledUp) {
		CursesToggleHighlight(OFF, SAVE);
	    }
	}
#endif
	y = w->_begy+w->_maxy;
	delwin(w);
	for (ln = Lst_Succ(wln); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    w = (WINDOW *)Lst_Datum(ln);

	    y -= w->_maxy;
	    mvwin(w, y, 0);
	    wrefresh(w);
	}
    }

    Lst_Remove(windows, wln);
    if (!Lst_IsEmpty(windows)) {
	/*
	 * Shift the border window last
	 */
	if (windowsOnTop) {
	    mvwin(borderWin, y++, 0);
	} else {
	    mvwin(borderWin, --y, 0);
	}
	wrefresh(borderWin);
    } else {
	/*
	 * Nuke the border window since it's unnecessary.
	 */
	delwin(borderWin);
	borderWin = (WINDOW *)NULL;
	y = windowsOnTop ? 0 : LINES;
	cmdWin->_flags |= _FULLWIN;
    }

    /*
     * Make room for the new lines
     */
    if (windowsOnTop) {
	i = cmdWin->_begy-y;
	cmdWin->_begy = y;
	/*
	 * Shift the lines up to make room at the top.
	 */
	bcopy((char *)&cmdWin->_y[0], (char *)&cmdWin->_y[i],
	      cmdWin->_maxy * sizeof(cursesChar *));
	cmdWin->_maxy += i;
	cmdWin->_cury += i;

	for (lp = lineHead, i--; i >= 0; i--, lp = lineHead) {
	    cmdWin->_y[i] = lp->line;
	    touchline(cmdWin,i,0,cmdWin->_maxx-1);
	    lineHead = lineHead->next;
	    free((char *)lp);
	}

    } else {

	i = y - cmdWin->_maxy;

	/*
	 * Scroll in the lines from the scroll buffer.
	 */
	if (junkLine == (cursesChar *)NULL) {
	    junkLine = (cursesChar *)malloc_tagged(cmdWin->_maxx
						   * sizeof(cursesChar),
						   TAG_CURSES);
	}
	for (lp = lineHead, i--; i >= 0; i--, lp = lineHead) {
	    if (lp == NullLine) {
		/*
		 * Creation was optimized to just (visually) steal a portion
		 * of cmdWin, rather than scrolling things off, so just give
		 * the portion back again. The extra lines in the _y array
		 * were freed during that transition, so we need to allocate
		 * a new line for it.
		 */
#if !defined(_WIN32)
		memset(junkLine, ' ', cmdWin->_maxx);
#else
		for(j=0; j<cmdWin->_maxx; j++) {
		    makeNtcCell(&junkLine[j], ' ');
		}

#endif
		cmdWin->_y[cmdWin->_maxy++] = junkLine;
		junkLine = (cursesChar *)malloc_tagged(cmdWin->_maxx
						       * sizeof(cursesChar),
						       TAG_CURSES);
		touchline(cmdWin,cmdWin->_maxy-1,0,cmdWin->_maxx-1);
	    } else {
		/*
		 * Give scrollnow something to move around.
		 */
		cmdWin->_y[cmdWin->_maxy++] = junkLine;
		/*
		 * Scroll window down (shifts junkLine to _y[0]...).
		 */
		scrollnow_hideMouse(cmdWin,-1);
		/*
		 * Replace first line with saved line and force complete
		 * update.
		 */
		cmdWin->_y[0] = lp->line;
		touchline(cmdWin,0,0,cmdWin->_maxx-1);
		/*
		 * Take line out of the scroll buffer.
		 */
		lineHead = lineHead->next;
		free((char *)lp);
	    }
	    /*
	     * Keep _cury in the same place, relatively. Can't just add i to
	     * it before we go through all this, as that places _cury out
	     * of bounds and causes vscrollnow to louse things up on systems
	     * where scrolling can't be done intelligently.
	     */
	    cmdWin->_cury += 1;
	}
#if defined(_MSDOS)
	/*
	 * Check if there's a highlight onscreen (lines <= 0) and if it
	 * needs updating (scrolledUp == TRUE).
	 */
	if (lines <= 0 && scrolledUp) {
	    /*
	     * If the borderWin's not around at this point, it must be that
	     * we just deleted it; we know we had it when we entered this
	     * routine since there had to have been at least two real windows
	     * up: the cmdWin and the window we wanted to get rid of, and
	     * when we have two or more windows, we also have the borderWin.
	     * If it's not here now, we adjust the amount by which to move
	     * the highlight.
	     */
	    if (!borderWin) {
		lines--;
	    }
	    /*
	     * Update the mouse_highlight tcl variable and turn the highlight
	     * on at the new position.
	     */
	    CursesUpdateHighlight(lines);
	    CursesToggleHighlight(ON, SAVE);
	}
#endif

    }

    if (lineHead == NullLine) {
	lineTail = NullLine;
    }

    wrefresh(cmdWin);
    return(TCL_OK);
}
/***********************************************************************
 *				CursesWPushCmd
 ***********************************************************************
 * SYNOPSIS:	    Push to a new window for echoing, etc.
 * CALLED BY:	    Tcl
 * RETURN:	    Nothing
 * SIDE EFFECTS:    curWin is pushed onto the stack, then changed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 9/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(wpush,CursesWPush,TCL_EXACT,NULL,swat_prog.window,
"Usage:\n\
    wpush <window>\n\
\n\
Examples:\n\
    \"wpush $disp\"	Makes all I/O to pass through the window whose token\n\
			is in $disp\n\
\n\
Synopsis:\n\
    Redirects all input and output to pass through the indicated window.\n\
\n\
Notes:\n\
    * The previous I/O window may be recovered by means of the wpop command.\n\
\n\
    * No output will appear in the window until either wrefresh is invoked,\n\
      or you echo a newline to the window.\n\
\n\
See also:\n\
    wpop, wrefresh.\n\
")
{
    WINDOW  *w;

    w = (WINDOW *)atoi(argv[1]);
    if (!VALIDTPTR(w,TAG_CWIN)) {
	Tcl_RetPrintf(interp, "%s: not a window", argv[1]);
	return(TCL_ERROR);
    }
    (void)Lst_AtFront(windowStack, (LstClientData)curWin);
    curWin = w;
    return(TCL_OK);
}

/***********************************************************************
 *				CursesWPopCmd
 ***********************************************************************
 * SYNOPSIS:	    Pop to the previous window.
 * CALLED BY:	    Tcl
 * RETURN:	    Nothing
 * SIDE EFFECTS:    curWin is altered
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 9/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(wpop,CursesWPop,TCL_EXACT,NULL,swat_prog.window,
"Usage:\n\
    wpop\n\
\n\
Examples:\n\
    \"wpop\"	Return to the previous window for I/O\n\
\n\
Synopsis:\n\
    Restores the window that was overridden by the most recent \"wpush\" to\n\
    I/O supremacy.\n\
\n\
See also:\n\
    wpush.\n\
")
{
    if (Lst_IsEmpty(windowStack)) {
	Tcl_Error(interp, "window stack empty");
    }
    curWin = (WINDOW *)Lst_DeQueue(windowStack);
    return(TCL_OK);
}

/***********************************************************************
 *				CursesWInverseCmd
 ***********************************************************************
 * SYNOPSIS:	    Set the stand-out mode for the current window
 * CALLED BY:	    Tcl
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The standout mode is altered for the current window.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 9/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(winverse,CursesWInverse,TCL_EXACT,NULL,swat_prog.window|swat_prog.output,
"Usage:\n\
    winverse ( 1 | 0 )\n\
\n\
Examples:\n\
    \"winverse 1\"	Set the current window to invert future characters\n\
			echoed to it.\n\
\n\
Synopsis:\n\
    Allows you to highlight characters echoed to the current window.\n\
\n\
Notes:\n\
    * The state of the inverse flag for the window remains past a wpop.\n\
\n\
See also:\n\
    echo.\n\
")
{
    if (argc != 2) {
	Tcl_Error(interp, "Usage: winverse (1|0)");
    }
    if (atoi(argv[1])) {
	wstandout(curWin);
    } else {
	wstandend(curWin);
    }
    return(TCL_OK);
}

/***********************************************************************
 *				CursesWMoveCmd
 ***********************************************************************
 * SYNOPSIS:	    Move the current position for the current window.
 * CALLED BY:	    Tcl
 * RETURN:	    Nothing
 * SIDE EFFECTS:    _curx and _cury for the window may be changed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 9/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(wmove,CursesWMove,TCL_EXACT,NULL,swat_prog.window,
"Usage:\n\
    wmove [+|-]<x> [+|-]<y>\n\
\n\
Examples:\n\
    \"wmove +0 +3\"	Move the cursor down three lines\n\
    \"wmove 0 0\"		Move to the current window's upper-left corner\n\
\n\
Synopsis:\n\
    Moves the cursor for the current window, thereby adjust where input is\n\
    echoed and where output goes.\n\
\n\
Notes:\n\
    * The <x> and <y> values may be either absolute or relative. If an argument\n\
      begins with a + or a -, it is relative (thus \"+0\" means no change). If\n\
      it begins with just a digit, it is absolute.\n\
\n\
    * <x> and <y> are decimal numbers, only.\n\
\n\
    * If the move would take the cursor outside the window, an error will\n\
      be generated.\n\
\n\
    * Returns the new cursor position as {x y}\n\
\n\
See also:\n\
    wdim.\n\
")
{
    int	    y, x;

    if (argc != 3) {
	Tcl_Error(interp, "Usage: wmove [(+|-)]<x-coord> [(+|-)]<y-coord>");
    }
    getyx(curWin, y, x);

    if ((*argv[1] == '-') || (*argv[1] == '+')) {
	x += atoi(argv[1]);
    } else {
	x = atoi(argv[1]);
    }
    if ((*argv[2] == '-') || (*argv[2] == '+')) {
	y += atoi(argv[2]);
    } else {
	y = atoi(argv[2]);
    }
    if (wmove(curWin, y, x) == ERR) {
	Tcl_Error(interp, "coordinates outside window");
    } else {
	Tcl_RetPrintf(interp, "%d %d", curWin->_curx, curWin->_cury);
	return(TCL_OK);
    }
}

/***********************************************************************
 *				CursesWClearCmd
 ***********************************************************************
 * SYNOPSIS:	    Clear the current window.
 * CALLED BY:	    Tcl
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The window be cleared, mahn
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 9/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(wclear,CursesWClear,TCL_EXACT,NULL,swat_prog.window,
"Usage:\n\
    wclear\n\
\n\
Examples:\n\
    \"wclear\"	Erase the current window\n\
\n\
Synopsis:\n\
    Clears all the characters in the current window to spaces.\n\
\n\
Notes:\n\
    * This does not actually update the screen, on the assumption that you're\n\
      clearing the window in order to write new stuff into it, so changing the\n\
      screen would be wasted work. Use wrefresh if you want the window to\n\
      appear clear on-screen as well.\n\
\n\
See also:\n\
    wrefresh.\n\
")
{
    wclear(curWin);
    return(TCL_OK);
}

/***********************************************************************
 *				CursesWRefreshCmd
 ***********************************************************************
 * SYNOPSIS:	    Update the current window on the screen
 * CALLED BY:	    Tcl
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The window is refreshed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 9/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(wrefresh,CursesWRefresh,TCL_EXACT,NULL,swat_prog.window,
"Usage:\n\
    wrefresh\n\
\n\
Examples:\n\
    \"wrefresh\"	    Make the screen reflect the window's current contents\n\
\n\
Synopsis:\n\
    Synchronizes the current window with the screen, so the are of the screen\n\
    covered by the window looks like what's in the window.\n\
\n\
Notes:\n\
    * You need only use this if you don't echo a newline, as echoing a newline\n\
      refreshes the current window.\n\
\n\
See also:\n\
    none.\n\
")
{
    wrefresh(curWin);
    return(TCL_OK);
}

/***********************************************************************
 *				CursesWTopCmd
 ***********************************************************************
 * SYNOPSIS:	    Set the windowsOnTop flag and move windows if nec'y
 * CALLED BY:	    Tcl
 * RETURN:	    Nothing
 * SIDE EFFECTS:    All known windows could change sides of the screen.
 *
 * STRATEGY:
 *	    If no windows defined, just change windowsOnTop.
 *	    Otherwise, delete or insert lines at the top of the screen
 *	    	to position cmdWin at the proper place, then shift
 *	    	all current windows into place.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(wtop,CursesWTop,TCL_EXACT,NULL,window,
"Usage:\n\
    wtop ( 1 | 0 )\n\
\n\
Examples:\n\
    \"wtop 1\"	    Places windows created with \"wcreate\" above the command\n\
		    window\n\
\n\
Synopsis:\n\
    Allows you to have all the displays, regwins, etc., placed above the main,\n\
    scrolling input window, if you so desire.\n\
\n\
Notes:\n\
    * Any window already existing when you invoke this command will move to\n\
      the appropriate side of the command window.\n\
\n\
    * By default, windows are created below the command window, i.e. \"wtop 0\"\n\
      is the default setting.\n\
\n\
See also:\n\
    wcreate.\n\
")
{
    Boolean	    nWOT;

#if !defined(_WIN32) && !defined(__WATCOMC__)
    extern int	    _putchar(char c);
#endif
    LstNode 	    ln;
    WINDOW  	    *w;
    int	    	    y;

    if (argc != 2) {
	Tcl_Error(interp, "Usage: wtop <flag>");
    }

    nWOT = atoi(argv[1]);

    if (Lst_IsEmpty(windows) || (windowsOnTop == nWOT)) {
	windowsOnTop = nWOT;
    } else if (nWOT) {
#if defined(unix)
	if (AL || AL_PARM) {
	    int     i;
	    char    **savey = (char **)malloc((LINES-cmdWin->_maxy)
						 * sizeof(cursesChar));
	    /*
	     * Move to upper-left corner of the screen for shiftage of cmdWin
	     */
	    mvcur(curscr->_cury, curscr->_curx, 0, 0);
	    curscr->_cury = curscr->_curx = 0;

	    /*
	     * Moving windows to the top -- make room up there.
	     */
	    if (AL_PARM) {
		/*
		 * Can insert many at once -- do so.
		 */
		_puts(tgoto(AL_PARM, LINES-cmdWin->_maxy, 0));
	    } else {
		/*
		 * Insert the lines one at a time...
		 */

		for (i = LINES - cmdWin->_maxy; i > 0; i--) {
		    _puts(AL);
		}
	    }
	    cmdWin->_begy = LINES-cmdWin->_maxy;
	    bcopy(&curscr->_y[cmdWin->_maxy], savey,
		  (LINES-cmdWin->_maxy) * sizeof(cursesChar));
	    bcopy(&curscr->_y[0], &curscr->_y[cmdWin->_begy],
		  cmdWin->_maxy * sizeof(cursesChar));
	    bcopy(&curscr->_firstch[0], &curscr->_firstch[cmdWin->_begy],
		  cmdWin->_maxy * sizeof(curscr->_firstch[0]));
	    bcopy(&curscr->_lastch[0], &curscr->_lastch[cmdWin->_begy],
		  cmdWin->_maxy * sizeof(curscr->_lastch[0]));
	    /*
	     * Zero out all the lines in savey so there is no correspondence
	     * between the windows and what curses thinks is on the screen.
	     * This will force the windows to be properly refreshed.
	     */
	    for (i = LINES-cmdWin->_maxy-1; i >= 0; i--) {
		bzero(savey[i], COLS);
		curscr->_firstch[i] = 0;
		curscr->_lastch[i] = COLS-1;
	    }
	    bcopy(savey, &curscr->_y[0],
		  (LINES-cmdWin->_maxy) * sizeof(cursesChar));
	    free((malloc_t)savey);
	} else {
#endif	/* unix */
	    /*
	     * Windows on top -- shift the command window down the slow way.
	     */
	    mvwin(cmdWin, LINES-cmdWin->_maxy, 0);
	    wrefresh(cmdWin);
#if defined(unix)
	}
#endif

	/*
	 * Move the windows into position from the top down.
	 */
	y = 0;

	for (ln = Lst_First(windows); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    w = (WINDOW *)Lst_Datum(ln);
	    mvwin(w, y, 0);
	    y += w->_maxy;
	    wrefresh(w);
	}
	mvwin(borderWin, y, 0);
	wrefresh(borderWin);
	windowsOnTop = nWOT;
    } else {
#if defined(unix)
	if (DL || DL_PARM) {
	    int	    i;
	    char    **savey = (char **)malloc((LINES-cmdWin->_maxy)
					      * sizeof(cursesChar));
	    /*
	     * Move to upper-left corner of the screen for shiftage of cmdWin
	     */
	    mvcur(curscr->_cury, curscr->_curx, 0, 0);
	    curscr->_cury = curscr->_curx = 0;

	    /*
	     * Moving windows to the bottom -- nuke them from the top.
	     */
	    if (DL_PARM) {
		_puts(tgoto(DL_PARM, LINES-cmdWin->_maxy, 0));
	    } else {
		/*
		 * Nuke the lines o n e  b y  o n e .
		 */

		for (i = LINES - cmdWin->_maxy; i > 0; i--) {
		    _puts(DL);
		}
	    }
	    bcopy(&curscr->_y[0], savey,
		  (LINES-cmdWin->_maxy) * sizeof(cursesChar));
	    bcopy(&curscr->_y[cmdWin->_begy], &curscr->_y[0],
		  cmdWin->_maxy * sizeof(cursesChar));
	    bcopy(&curscr->_firstch[cmdWin->_begy], &curscr->_firstch[0],
		  cmdWin->_maxy * sizeof(curscr->_firstch[0]));
	    bcopy(&curscr->_lastch[cmdWin->_begy], &curscr->_lastch[0],
		  cmdWin->_maxy * sizeof(curscr->_lastch[0]));
	    /*
	     * Zero out all the lines in savey so there is no correspondence
	     * between the windows and what curses thinks is on the screen.
	     * This will force the windows to be properly refreshed.
	     */
	    for (i = LINES-cmdWin->_maxy-1; i >= 0; i--) {
		bzero(savey[i], COLS);
		curscr->_firstch[i+cmdWin->_maxy] = 0;
		curscr->_lastch[i+cmdWin->_maxy] = COLS-1;
	    }
	    bcopy(savey, &curscr->_y[cmdWin->_maxy],
		  (LINES-cmdWin->_maxy) * sizeof(cursesChar));
	    cmdWin->_begy = 0;
	    free((malloc_t)savey);
	} else {
#endif	/* unix */
	    /*
	     * Shift the command window up the slow way.
	     */
	    mvwin(cmdWin, 0, 0);
	    wrefresh(cmdWin);
#if defined(unix)
	}
#endif

	/*
	 * Move the windows into position from the bottom up.
	 */
	y = LINES;

	for (ln = Lst_First(windows); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    w = (WINDOW *)Lst_Datum(ln);
	    y -= w->_maxy;
	    mvwin(w, y, 0);
	    wrefresh(w);
	}
	mvwin(borderWin, y-1, 0);
	wrefresh(borderWin);
	windowsOnTop = nWOT;
    }
    return(TCL_OK);
}

/***********************************************************************
 *				CursesCmdWinCmd
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 1/93		Initial Revision
 *
 ***********************************************************************/
DEFCMD(cmdwin,CursesCmdWin,TCL_EXACT,NULL,swat_prog.window,
"Usage:\n\
    cmdwin\n\
\n\
Examples:\n\
    \"cmdwin\"	    	Returns the token for the main input window\n\
\n\
Synopsis:\n\
    Fetches the token for the main input/output window in which the text\n\
    cursor normally resides.\n\
\n\
Notes:\n\
    * This command exists primarily to make finding the dimensions of the\n\
      command window easier, but you may find it useful for other reasons.\n\
\n\
See also:\n\
    wdim\n\
")
{
    Tcl_RetPrintf(interp, "%d", cmdWin);
    return(TCL_OK);
}

/***********************************************************************
 *				CursesWarning
 ***********************************************************************
 * SYNOPSIS:	    Print a warning for the user. Prints a newline.
 * CALLED BY:	    GLOBAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Print "Warning:", the message, "\n" to cmdWin and
 *		    update.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/07/88	Initial Revision
 *
 ***********************************************************************/
static void
CursesWarning(const char *fmt, ...)
{
    va_list 	args;

    waddstr(cmdWin, (WADDSTR_CAST)"Warning: ");

    va_start(args, fmt);
    _sprintw(cmdWin, fmt, args);
    waddch(cmdWin, '\n');
    wrefresh(cmdWin);
    va_end(args);
}

/***********************************************************************
 *				CursesMessage
 ***********************************************************************
 * SYNOPSIS:	    Print a friendly message to the user
 * CALLED BY:	    GLOBAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Not here
 *
 * STRATEGY:	    Call _sprintw properly.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
static void
CursesMessage(const char *fmt, ...)
{
    va_list 	args;

    va_start(args, fmt);
    _sprintw(curWin, fmt, args);
    va_end(args);
}

/***********************************************************************
 *				CursesMessageFlush
 ***********************************************************************
 * SYNOPSIS:	    Give a message to the user and make sure it
 *		    gets out NOW
 * CALLED BY:	    GLOBAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Call _sprintw and wrefresh properly
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
static void
CursesMessageFlush(const char *fmt, ...)
{
    va_list 	args;

    va_start(args, fmt);
    _sprintw(curWin, fmt, args);
    wrefresh(curWin);
    va_end(args);
}

/***********************************************************************
 *				CursesReadLine
 ***********************************************************************
 * SYNOPSIS:	    Read a line from the user while ignoring other
 *	    	    things...
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The line buffer is filled.
 *
 * STRATEGY:	    Call wgetestr()
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
static void
CursesReadLine(char *line)
{
    echo();
    wrefresh(cmdWin);
    fflush(stdout);
    wgetestr(cmdWin, line);
    noecho();
}

/***********************************************************************
 *				CursesExit
 ***********************************************************************
 * SYNOPSIS:	    Take down the window system in preparation for exit
 * CALLED BY:	    quit command
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Cursor is moved to ll and tty reset.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
static void
CursesExit(void)
{
    /*
     * Move to lower-left corner
     */
    mvcur(0, COLS-1, LINES-1, 0);
    /*
     * Reset tty
     */
    endwin();
#if defined(__HIGHC__)
    _clearscreen(_GWINDOW);
    _setvideomode(_TEXTC80);
#endif
}

/*********************************************************************
 *			DssLowCmd
 *********************************************************************
 * SYNOPSIS: C implementation for guts of dss display command
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	1/13/94		Initial version
 *
 *********************************************************************/
DEFCMD(dss_low, DssLow,TCL_EXACT,NULL,swat_prog.patient,
"")
{
    cursesChar	*screen_text, *curline, *cp;
    int	    	lines, lineCount, start, curcol, truecur;
    char    	*curfile, *srcwinmode;
    int	    	notdocwin, found_line;
    int	    	returnVal;
#if defined(_WIN32)
    unsigned short	*screen_text_dblByte;
    cursesChar		sample;
    int			i;
#endif

    /* do the display stuff in C for speed */

    if (argc != 8)
    {
	Tcl_RetPrintf(interp, wrongNumArgsString, argv[0]);
	return TCL_ERROR;
    }

    /* get all the arguments into nicely named variables */
    lines = atoi(argv[1]);
    start = atoi(argv[2]);
    curfile = argv[3];
    curcol = atoi(argv[4]);
    srcwinmode = argv[5];
    truecur = atoi(argv[6]);
    found_line = atoi(argv[7]);

    notdocwin = strcmp(srcwinmode, "_docwin") ? 6 : 0;

    screen_text = (cursesChar *)malloc(sizeof(cursesChar) *
				       (lines * COLS + 1));
#if defined(_WIN32)
    screen_text_dblByte = (unsigned short *)malloc(sizeof(unsigned short) *
						   (lines * COLS + 1));
    returnVal = Src_ReadLine(interp, curfile, argv[2], argv[1],
			     NULL, screen_text_dblByte);
    (void *)makeNtcCell(&sample, ' ');
    for(i=0; i<(lines * COLS); i++) {
	screen_text[i].uniChar = screen_text_dblByte[i];
	screen_text[i].attr = sample.attr;
    }
    free((void *)screen_text_dblByte);
#else
    returnVal = Src_ReadLine(interp, curfile, argv[2], argv[1],
			     screen_text, NULL);
#endif
    /*
     * put a null terminator at the end to prevent wandering off into
     * space
     */
    ASSIGN_CHAR_W_CONST(screen_text[lines * COLS], '\0');

    if (returnVal == TCL_ERROR) {
	free((void *)screen_text);
	return returnVal;
    }
    curline = screen_text;

#if defined(_WIN32)
    /*
     * maybe there is a better way to prevent gunk from getting on the
     * screen, but for now this will do
     */
    wclear(curWin);
    wprintw(curWin, "View file %s\n", curfile);
#endif
    /*
     * do one line at time so we can prevent wrapping and highlight current
     * line that set breakpoints by line number
     */
    for(lineCount = lines; lineCount > 0; lineCount--, start++) {
	cursesChar	temp;
	int 		count, newline;
	cursesChar	tbuf[1024];
	int	 	tcount;

	count = 0;
	cp = curline;

	memset(tbuf, ' ', sizeof(tbuf));

	while(count < COLS + curcol) {
	    if (EQUAL_CHARS(*cp, '\0') == TRUE) {
		ASSIGN_CHAR_W_CONST(tbuf[count], '\0');
		break;
	    }
	    if (EQUAL_CHARS(*cp, '\011') == TRUE) {
		for (tcount = (8 - (count & 07));
		     (tcount > 0) && (count < COLS + curcol);
		     tcount--)
		{
		    ASSIGN_CHAR_W_CONST(tbuf[count], ' ');
		    count++;
		}
	    } else {
#if !defined(_WIN32)
		ASSIGN_CHAR_W_VAR(tbuf[count], *cp);
#else
		if ((cp->uniChar >> 8) != 0) {
		    /*
		     * sjis character - make sure we have room for both
		     * the byte, plus the place-holder byte
		     */
		    if (count < (COLS + curcol - (notdocwin + 1) - 1)) {
			ASSIGN_CHAR_W_VAR(tbuf[count], *cp);
			count++;
			makeNtcCell(&tbuf[count], VOID_CELL);
			tbuf[count].attr = VOID_CELL;
		    } else {
			ASSIGN_CHAR_W_CONST(tbuf[count], ' ');
		    }
		} else {
		    ASSIGN_CHAR_W_VAR(tbuf[count], *cp);
		}
#endif
		count++;
	    }
 	    cp++;
	}

	/*
	 * check to see if there is a newline to the left of the visible
	 * portion of the screen
	 */
	cp = tbuf;
	newline = 0;
	while(cp - tbuf < curcol) {
	    if(EQUAL_CHARS(*cp, '\0') == TRUE) {
		goto all_done;
	    }
	    if(EQUAL_CHARS(*cp, '\012') == TRUE) {
		/*
		 * if there is, print a newline and go to next line
		 */
	        if (notdocwin) {
		    wprintw(curWin, "%4d: \n", start);
		} else {
		    wprintw(curWin, "\n", start);
		}
		while (EQUAL_CHARS(*curline, '\012') == FALSE) {
		    curline++;
		}
		curline++;
		newline = 1;
		break;
	    }
	    cp++;
	}
	if (newline) {
	    /*
	     * we found a newline so go back to top of loop
	     */
	    continue;
	}
	count = 0;

	while ((EQUAL_CHARS(*cp, '\0') == FALSE) &&
	       (EQUAL_CHARS(*cp, '\012') == FALSE) &&
	       (EQUAL_CHARS(*cp, '\r') == FALSE) &&
	       (count < (COLS - (notdocwin + 1))))
	{
	    cp++;
	    count++;
	}
	ASSIGN_CHAR_W_VAR(temp, *cp);
	ASSIGN_CHAR_W_CONST(*cp, '\0');

	/*
	 * output as much as we can
	 */
	if (notdocwin) {
	    wprintw(curWin, "%4d: ", start);
	}
	if (truecur == start || found_line == start) {
	    wstandout(curWin);
	    WPRINTW(curWin, "%s\n", tbuf+curcol);
	    wstandend(curWin);
	} else {
	    WPRINTW(curWin, "%s\n", tbuf+curcol);
	}
	/*
	 * check to see if we are done
	 */
	if (EQUAL_CHARS(temp, '\0') == TRUE) {
	    break;
	}
	/*
	 * if not, replace the character we biffed
	 */
	ASSIGN_CHAR_W_VAR(*cp, temp);
	cp = curline;
	/* now get to the start of the next line */
	while((EQUAL_CHARS(*cp, '\0') == FALSE)
	      && (EQUAL_CHARS(*cp, '\012') == FALSE))
	{
	    cp++;
	}

	if (EQUAL_CHARS(*cp, '\0') == TRUE) {
	    break;
	}
	cp++;
	curline = cp;
    }
all_done:
    if ((EQUAL_CHARS(*cp, '\0') == TRUE)
	&& (cp == &screen_text[lines * COLS])
	&& (lineCount > 0))
    {
	WPRINTW(curWin, "...\n");
    }

    free((void *)screen_text);
    Tcl_Return(interp, "", TCL_STATIC);
    return TCL_OK;
}


/***********************************************************************
 *				CursesResetInput
 ***********************************************************************
 * SYNOPSIS:	    Cope with the user resetting and bringing us back to
 *	    	    top-level.
 * CALLED BY:	    EVENT_RESET
 * RETURN:	    EVENT_HANDLED
 * SIDE EFFECTS:    inStateTop eventually set to 0 again
 *	    	    input buffers freed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/24/95	Initial Revision
 *
 ***********************************************************************/
static int
CursesResetInput(Event event, Opaque callData, Opaque clientData)
{
    /*
     * First free up the state of any nested read-line things.
     */
    while (inStateTop != 0) {
	CursesInputState    *state;

	state = inStateTop;
	inStateTop = state->next;

	Buf_Destroy(state->input, TRUE);
	if (state->endChars != defEndChars) {
	    free((char *)state->endChars);
	}
	if (state->wordChars != defWordChars) {
	    free((char *)state->wordChars);
	}
	free((char *)state);
    }
    /*
     * Discard any pushed watch/ignore states for the keyboard.
     */
    while (Rpc_Pop(0)) {
	;
    }
    /*
     * And ignore the keyboard until told otherwise; the mouse will take
     * care of itself.
     */
    Rpc_Ignore(0);
    return (EVENT_HANDLED);
}

/***********************************************************************
 *				Curses_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize this system
 * CALLED BY:	    Ui_Init
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None...yet
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
void
Curses_Init(void)
{
    int	i;

    /* make sure all the key bindings are initialized to NULL */
    for(i = 0; i < 256; i++)
    {
	keyBindings[i] = NULL;
    }
#if defined(_MSDOS)
    highlightinfo.firstline = NULL;
    highlightinfo.scroll_mode = 0;
    highlightinfo.active = 0;
#endif
    if (initscr() == ERR) {
	/*
	 * If we couldn't init for curses, go into dumb-mode
	 */
	Shell_Init();
    } else {
	/*
	 * Don't need stdscr since we do our own windows
	 */
	delwin(stdscr);

	/*
	 * Character-by-character and don't echo until we tell it to.
	 */
#if defined(unix) || defined(_WIN32)
	cbreak();
#endif
	noecho();
	cursesFlags = CURSES_ECHO;
#undef CTRL
#define CTRL(c) (c & 037)
#if defined(unix)
	ioctl(_tty_ch, TIOCGLTC, &ltc);
	/*
	 * Make sure the delayed suspend character is inoperative (it's
	 * usually ctrl-Y, which we use)
	 */
	if (ltc.t_dsuspc == CTRL('y')) {
	    char    c = ltc.t_dsuspc;

	    ltc.t_dsuspc = -1;
	    ioctl(_tty_ch, TIOCSLTC, &ltc);
	    ltc.t_dsuspc = c;
	}
#endif

	forwPage = CTRL('f');
	backPage = CTRL('b');
	forwHPage = CTRL('d');
	backHPage = CTRL('u');
	forwLine = CTRL('e');
	backLine = CTRL('y');
	redraw = CTRL('l');

	/*
	 * Create initial window to be the whole screen. It's allowed to
	 * scroll (we want it to :). Then put it up (blank) on the screen
	 */
	cmdWin = newwin(LINES, COLS, 0, 0);
	malloc_settag((char *)cmdWin, TAG_CWIN);
	scrollok(cmdWin, 1);
	wrefresh(cmdWin);
#if defined(unix)
	BL = getcap("bl");
#endif

	/*
	 * Initialize window stack and make the command window the current
	 * one.
	 */
	windowStack = Lst_Init(FALSE);
	windows = Lst_Init(FALSE);
	borderWin = (WINDOW *)NULL;
	curWin = cmdWin;
	windowsOnTop = FALSE;

	/*
	 * Initialize the scroll buffer
	 */
	lineHead = lineTail = lineCur = (LinePtr)NULL;
	numSaved = 0;

	/*
	 * Set up vectors for other folks to use
	 */
	Event_Handle(EVENT_RESET, 0, CursesResetInput, NullOpaque);

	Message = CursesMessage;
	Warning = CursesWarning;
	MessageFlush = CursesMessageFlush;
	Ui_NumColumns = CursesNumColumns;
	Ui_ReadLine = CursesReadLine;
	Ui_Exit = CursesExit;
#if defined(unix)
	(void)signal(SIGTSTP, CursesTstp);
#endif

	/*
	 * Install the commands we support
	 */
	Cmd_Create(&CursesReadLineCmdRec);
	Cmd_Create(&CursesReadCharCmdRec);
	Cmd_Create(&CursesEchoCmdRec);
	Cmd_Create(&CursesSystemCmdRec);
	Cmd_Create(&CursesSaveCmdRec);
	/*Cmd_Create(&CursesSLogCmdRec);*/
	/*Cmd_Create(&CursesSBClrCmdRec);*/
	Cmd_Create(&CursesWCreateCmdRec);
	Cmd_Create(&CursesWDeleteCmdRec);
	Cmd_Create(&CursesWPushCmdRec);
	Cmd_Create(&CursesWPopCmdRec);
	Cmd_Create(&CursesWInverseCmdRec);
	Cmd_Create(&CursesWMoveCmdRec);
	Cmd_Create(&CursesWClearCmdRec);
	Cmd_Create(&CursesWRefreshCmdRec);
	Cmd_Create(&CursesWTopCmdRec);
	Cmd_Create(&CursesBeepCmdRec);

	Cmd_Create(&CursesBindKeyCmdRec);
	Cmd_Create(&CursesUnbindKeyCmdRec);
	Cmd_Create(&CursesGetKeyBindingCmdRec);

	Cmd_Create(&CursesWFindCmdRec);
	Cmd_Create(&CursesWDimCmdRec);
	Cmd_Create(&CursesCmdWinCmdRec);

	Cmd_Create(&DssLowCmdRec);
#if defined(_MSDOS)
	Cmd_Create(&CursesInvertScreenRegionCmdRec);
	Cmd_Create(&CursesClearHighlightInfoCmdRec);
	Cmd_Create(&CursesUpdateScrolledHighlightCmdRec);
	Cmd_Create(&CursesInsertHighlightedTextCmdRec);
#endif
	Tcl_SetVar(interp, "window-system", "curses", TRUE);
    }
}
