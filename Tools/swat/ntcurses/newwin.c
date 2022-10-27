/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		newwin.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: newwin.c,v 1.1 97/04/18 11:21:59 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Newwin(), subwin() routines of the PCcurses package		*/
/*								*/
/****************************************************************/
/* This version of curses is based on ncurses, a curses version	*/
/* originally written by Pavel Curtis at Cornell University.	*/
/* I have made substantial changes to make it run on IBM PC's,	*/
/* and therefore consider myself free to make it public domain.	*/
/*				Bjorn Larsson (bl@infovox.se)	*/
/****************************************************************/
/* 1.4:  References to win->borderchar[] removed due to		*/
/*	 re-defined border() functions. Use of short		*/
/*	 wherever possible. Bug in subwin() did not		*/
/*	 allow subwin to be the same size as the origi-		*/
/*	 nal window. Portability improvements:		900114	*/
/* 1.3:  MSC '-W3', Turbo'C' '-w -w-pro' checks.		*/
/*	 Support for border(), wborder() functions:	881005	*/
/* 1.2:	 Other max limits off by 1. Fixed thanks to		*/
/*	 S. Creps:					881002	*/
/* 1.1:	 Fix in subwin: '+/-1' error when checking that		*/
/*	 subwindow fits in parent window:		880305	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

#include <stdio.h>
#include <curses.h>
#include <curspriv.h>

#include <stdlib.h>

char _curses_newwin_rcsid[] = "@(#)newwin.c     v.1.4  - 900114";

/****************************************************************/
/* NewwinMakenew() allocates all data for a new window except the	*/
/* actual lines themselves.					*/
/****************************************************************/

static WINDOW *
NewwinMakenew(int num_lines, int num_columns, int begy, int begx)
{
    short	i;
    WINDOW	*win;

    /* 
     * allocate the window structure itself 
     */
    if ((win = (WINDOW *) malloc(sizeof(WINDOW))) == NULL) {
	return ((WINDOW *) ERR);
    }
    
    /* 
     * allocate the line pointer array 
     */
    if ((win->_line = (ntcCell **) calloc(num_lines, 
					  sizeof (ntcCell *))) == NULL) {
	free(win);
	return((WINDOW *) ERR);
    }
    
    /* 
     * allocate the minchng and maxchng arrays 
     */
    if ((win->_minchng = (short *) calloc(num_lines, 
					 sizeof(short))) == NULL) {
	free(win);
	free(win->_line);
	return((WINDOW *) ERR);
    }
    if ((win->_maxchng = (short *) calloc(num_lines, 
					 sizeof(short))) == NULL) {
	free(win);
	free(win->_line);
	free(win->_minchng);
	return((WINDOW *) ERR);
    }
    
    /* 
     * initialize window variables 
     */
    win->_curx      = 0;
    win->_cury      = 0;
    win->_maxy      = num_lines;
    win->_maxx      = num_columns;
    win->_begy      = begy;
    win->_begx      = begx;
    win->_flags     = 0;
    win->_tabsize   = 8;
    win->_clear     = (bool) ((num_lines == LINES) && (num_columns == COLS));
    win->_leavecurs = FALSE;
    win->_scroll    = FALSE;
    win->_nodelay   = FALSE;
    win->_keypad    = FALSE;
    
    /* 
     * init to say window changed 
     */
    for (i = 0; i < win->_maxy; i++) {
	win->_minchng[i] = 0;
	win->_maxchng[i] = win->_maxx - 1;
    }
    
    /* 
     * set flags for window properties 
     */
    if ((begy + num_lines) == LINES) {
	win->_flags |= _ENDLINE;
	if ((begx == 0) && (num_columns == COLS) && (begy == 0)) {
	    win->_flags |= _FULLWIN;
	}
    }

    if (((begy + num_lines) == LINES)
        &&
	((begx + num_columns) == COLS)) {

	win->_flags |= _SCROLLWIN;
    }
    return(win);
} /* NewwinMakenew */

/****************************************************************/
/* newwin() creates a new window with size num_lines * num_co-	*/
/* lumns, and origin begx,begy relative to the SCREEN. Special	*/
/* case: if num_lines and/or num_columns is 0, the remainder of	*/
/* the screen is used.						*/
/****************************************************************/

WINDOW *newwin(int	num_lines,
	       int	num_columns,
	       int	begy,
	       int	begx)
{
    WINDOW	*win;
    ntcCell	*ptr;
    short	i, j;

    if (num_lines == 0) {
	num_lines = LINES - begy;
    }
    if (num_columns == 0) {
	num_columns = COLS - begx;
    }
    win = NewwinMakenew(num_lines, num_columns, begy, begx);
    if (win == (WINDOW *) ERR) {
	return ((WINDOW *) ERR);
    }
    /* 
     * make and clear the lines 
     */
    for (i = 0; i < num_lines; i++) {
	if((win->_line[i] = (ntcCell *) calloc(num_columns,
					    sizeof(ntcCell))) == NULL) {
	    /* 
	     *  if error, free all the data 
	     */
	    for (j = 0; j < i; j++) {
		free(win->_line[j]);
	    }
	    free(win->_minchng);
	    free(win->_maxchng);
	    free(win->_line);
	    free(win);
	    return((WINDOW *) ERR);
	} else {
	    for (ptr = win->_line[i]; ptr < win->_line[i] + num_columns;) {
		(void *)makeNtcCell(ptr, ' ');
		ptr++;
	    }
	}
    }
    return(win);
} /* newwin */

WINDOW* resizewin(WINDOW* win, int num_lines, int num_columns) 
{
    int j;
    if(num_lines < win->_maxy) {

        /* remove lines at the beginning */
        while(win->_cury >= num_lines) {

            int c=1;
            free(win->_line[0]);
            for(c=1; c < win->_maxy; c++)
            {
                win->_line[c-1] = win->_line[c];
            }
            win->_maxy--;
            win->_cury--;
        }

        /* free removed lines */
	    for (j = num_lines; j < win->_maxy; j++) 
        {
            free(win->_line[j]);
        }

        /* realloc the others */
        for(j = 0; j < num_lines; j++)
        {
            ntcCell *newLine = (ntcCell *) realloc(win->_line[j], sizeof(ntcCell)*num_columns);
            if(newLine == NULL)
            {
    	        return((WINDOW *) ERR);
            }
            win->_line[j] = newLine;
        }

        /* fill new chars */
        for(j=0; j < num_lines; j++) {
            int x=0;
            for(x=win->_maxx; x < num_columns; x++) {

                (void *)makeNtcCell(&win->_line[j][x], ' ');
            }

            win->_minchng[j]=0;
            win->_maxchng[j]=num_columns-1;
        }

        win->_maxx = num_columns;
        win->_maxy = num_lines;
    }
    else /*if(num_lines > win->_maxy)*/ 
    {
        void *newMinChg;
        void *newMaxChg;

        /* more lines now */
        ntcCell** newLines = realloc(win->_line, sizeof(ntcCell*) * num_lines);
        if(newLines == NULL)
        {
	        return((WINDOW *) ERR);
        }
        win->_line = newLines;

        newMinChg = realloc(win->_minchng, sizeof(short) * num_lines);
        if(newMinChg == NULL)
        {
	        return((WINDOW *) ERR);
        }
        win->_minchng = newMinChg;

        newMaxChg = realloc(win->_maxchng, sizeof(short) * num_lines);
        if(newMaxChg == NULL)
        {
	        return((WINDOW *) ERR);
        }
        win->_maxchng = newMaxChg;

        /* allocate new lines*/
        for(j = win->_maxy; j < num_lines; j++)
        {
            newLines[j] = (ntcCell *) calloc(num_columns,
					    sizeof(ntcCell));
            if(newLines[j] == NULL)
            {
                /* free all new lines*/
                j--;
                while(j >= num_lines)
                {
                    free(newLines[j]);
                    j--;
                }
    	        return((WINDOW *) ERR);
            }
        }

        /* realloc the others */
        for(j = 0; j < win->_maxy; j++)
        {
            ntcCell *newLine = (ntcCell *) realloc(win->_line[j], sizeof(ntcCell)*num_columns);
            if(newLine == NULL)
            {
                /* free all new lines*/
                j = num_lines;
                j--;
                while(j >= 0)
                {
                    free(win->_line[j]);
                    j--;
                }
    	        return((WINDOW *) ERR);
            }
            win->_line[j] = newLine;
        }

        /* fill new chars */
        for(j=0; j < num_lines; j++) {
            int x=0;
            if(win->_maxx< num_columns)
            {
                for(x=win->_maxx; x < num_columns; x++) {

                    (void *)makeNtcCell(&win->_line[j][x], ' ');
                }
            }
            if(j >= win->_maxy)
            {
                int width = win->_maxx;
                int a=0;
                if(width >= num_columns)
                {
                    width = num_columns;
                }
                for(a=0; a < width; a++) 
                {

                    (void *)makeNtcCell(&win->_line[j][a], ' ');
                }
            }

            win->_minchng[j]=0;
            win->_maxchng[j]=num_columns-1;
        }

        win->_maxx = num_columns;
        win->_maxy = num_lines;
    }
    return win;
}

/****************************************************************/
/* Subwin() creates a sub-window in the 'orig' window, with	*/
/* size num_lines * num_columns, and with origin begx, begy	*/
/* relative to the SCREEN. Special case: if num_lines and/or	*/
/* num_columns is 0, the remainder of the original window is	*/
/* used. The subwindow uses the original window's line buffers	*/
/* to store it's own lines.					*/
/****************************************************************/

WINDOW *subwin(WINDOW	*orig,
	       int	num_lines, 
	       int	num_columns,
	       int	begy,
	       int	begx)
{
    WINDOW	*win;
    short	i, j, k;

    /* 
     * make sure window fits inside the original one 
     */
    if (begy < orig->_begy || 
	begx < orig->_begx ||
	(begy + num_lines) > (orig->_begy + orig->_maxy) ||
	(begx + num_columns) > (orig->_begx + orig->_maxx)) {

	return((WINDOW *) ERR);
    }

    if (num_lines == 0) {
	num_lines = orig->_maxy - (begy - orig->_begy);
    }
    if (num_columns == 0) {
	num_columns = orig->_maxx - (begx - orig->_begx);
    }
    win = NewwinMakenew(num_lines, num_columns, begy, begx);
    if (win == (WINDOW *) ERR) {
	return((WINDOW *) ERR);
    }

    /* 
     * set line pointers the same as in the original window 
     */
    j = begy - orig->_begy;
    k = begx - orig->_begx;
    for (i = 0; i < num_lines; i++)
	win->_line[i] = (orig->_line[j++]) + k;
    win->_flags |= _SUBWIN;
    return(win);
} /* subwin */
