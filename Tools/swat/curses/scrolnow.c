/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  scrollnow.c
 * FILE:	  scrollnow.c
 *
 * AUTHOR:  	  Adam de Boor: Jul 13, 1992
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/13/92	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: scrolnow.c,v 1.2 92/07/13 21:39:47 adam Exp $";
#endif lint
/*
 * scrollnow -- perform immediate scroll of a window quickly (using
 * insert/delete line commands)
 */
# include	"curses.ext"

scrollnow(win, dir)
    WINDOW  *win;
    int	    dir;
{
    int	    dely, insy;

    if (dir > 0) {
	dely = 0;
	insy = win->_maxy-1;
    } else {
	insy = 0;
	dely = win->_maxy-1;
    }
    
    /*
     * See if we can scroll it in an optimized fashion by deleting and
     * inserting lines on the screen. This can only be done for windows
     * that are of screen width, have no subwindows and aren't subwindows
     * themselves.
     */
    if ((win->_flags & (_FULLLINE|_NOSUBWIN)) == (_FULLLINE|_NOSUBWIN) &&
#if !defined(_MSDOS)
	((AL && DL) || (CS && (dir > 0 || SR))) &&
#endif
	!win->_orig)
    {
	char	*temp;	    /* Temporary line pointer */
	char	*end;	    /* End of line for same */
	int 	y;  	    /* Y coord of new line */
	int 	src;	    /* Source index for copies */
	int 	dst;	    /* Dest index for copies */
	int 	nuke;	    /* Y coord of line to be destroyed */

	nuke = dely;
	y = insy;
	
	insy += win->_begy;
	dely += win->_begy;

#if !defined(_MSDOS)
	if (CS && ((dir > 0) || SR)) {
	    extern char *tgoto();

	    if (! (win->_flags & _FULLWIN)) {
		/*
		 * Narrow the scrolling region to the desired window.
		 * Note not done if the window is marked as covering the
		 * whole screen.
		 */
		temp = tgoto(CS, win->_begy+win->_maxy-1, win->_begy);
		tputs(temp, 0, _putchar);
	    }
	    if (dir < 0) {
		/*
		 * Move to the top of the window to do the reverse
		 * scroll. Not sure if this is necessary, but I know it's
		 * needed for xterm...VT100 also homes the cursor on doing
		 * a CS, but not all things do, so make sure the cursor
		 * motion is absolute.
		 */
		temp = tgoto(CM, 0, win->_begy);
		tputs(temp, 1, _putchar);
		tputs(SR, win->_maxy, _putchar);
	    } else {
		/*
		 * Move to the bottom of the window to do the forward scroll.
		 * Again, not sure it's necessary in all cases, but I know
		 * it is for xterm.
		 */
		temp = tgoto(CM, 0, win->_begy+win->_maxy-1);
		tputs(temp, 1, _putchar);
		
		if (SF) {
		    tputs(SF, win->_maxy, _putchar);
		} else if (DO) {
		    tputs(DO, win->_maxy, _putchar);
		} else {
		    /*
		     * Assume \n will scroll...
		     */
		    tputs("\n", win->_maxy, _putchar);
		}
	    }
	    if (! (win->_flags & _FULLWIN)) {
		/*
		 * Reset the scrolling region to be full screen.
		 */
		temp = tgoto(CS, LINES-1, 0);
		tputs(temp, 0, _putchar);
	    }
	    /*
	     * Again, need to make sure we're back where we want to be,
	     * since some things (xterm) will home the cursor after a
	     * CS.
	     */
	    temp = tgoto(CM, curscr->_curx, curscr->_cury);
	    tputs(temp, 1, _putchar);
	} else {
	    /*
	     * Move to beginning of line to be deleted
	     */
	    mvcur(curscr->_cury, curscr->_curx, dely, 0);
	    /*
	     * Nuke it
	     */
	    tputs(DL, LINES-dely, _putchar);
	    /*
	     * Move to place to insert blank line.
	     */
	    mvcur(dely, 0, insy, 0);
	    /*
	     * Insert it
	     */
	    tputs(AL, LINES-insy, _putchar);
	    /*
	     * Move curscr to current position (no point shifting it back when
	     * we're just going to refresh anyway).
	     */
	    wmove(curscr, insy, 0);
	}
#else
	DosScrollWin(dely, insy);
#endif
	/*
	 * Rearrange the line pointers and blank out the last line.
	 */
	if (dir > 0) {
	    src = 1;
	    dst = 0;
	} else {
	    src = 0;
	    dst = 1;
	}
	/*
	 * Copy the lines.
	 */
	temp = win->_y[nuke];
	bcopy(&win->_y[src],&win->_y[dst],(win->_maxy-1) * sizeof(char *));
	bcopy(&win->_firstch[src],&win->_firstch[dst],
	      (win->_maxy-1)*sizeof(short));
	bcopy(&win->_lastch[src],&win->_lastch[dst],
	      (win->_maxy-1)*sizeof(short));
	win->_y[y] = temp;

	end = &temp[win->_maxx];
	while (temp < end) {
	    *temp++ = ' ';
	}
	win->_firstch[y] = _NOCHANGE;
	if (win != curscr) {
	    int	    by, ey;
	    /*
	     * Rearrange the line pointers and blank out the last for curscr
	     * now too.
	     */
	    y += win->_begy;
	    src += win->_begy;
	    dst += win->_begy;
	    nuke += win->_begy;

	    temp = curscr->_y[nuke];
	    bcopy(&curscr->_y[src],&curscr->_y[dst],
		  (win->_maxy-1) * sizeof(char *));
	    bcopy(&curscr->_firstch[src],&curscr->_firstch[dst],
		  (win->_maxy-1)*sizeof(short));
	    bcopy(&curscr->_lastch[src],&curscr->_lastch[dst],
		  (win->_maxy-1)*sizeof(short));
	    curscr->_y[y] = temp;
	    
	    end = &temp[curscr->_maxx];
	    while (temp < end) {
		*temp++ = ' ';
	    }
	    curscr->_firstch[y] = _NOCHANGE;
	}
	if (win != curscr) {
	    wrefresh(win);
	}
    } else {
	int oy, ox;

	getyx(win, oy, ox);
	wmove(win, dely, 0);
	wdeleteln(win);
	wmove(win, insy, 0);
	winsertln(win);
	wmove(win, oy, ox);
	wrefresh(win);
    }
    return OK;
}
