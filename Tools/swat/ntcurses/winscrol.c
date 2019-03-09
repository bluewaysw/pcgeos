/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		winscrol.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: winscrol.c,v 1.1 97/04/18 11:26:01 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/****************************************************************/
/* Scroll() routine of the PCcurses package                    */
/*                                                             */
/****************************************************************/
/* This version of curses is based on ncurses, a curses version        */
/* originally written by Pavel Curtis at Cornell University.   */
/* I have made substantial changes to make it run on IBM PC's, */
/* and therefore consider myself free to make it public domain.        */
/*                             Bjorn Larsson (bl@infovox.se)   */
/****************************************************************/
/* 1.4:  Use of short wherever possible. Portability           */
/*      improvements:                                  900114  */
/* 1.3:         MSC -W3, Turbo'C' -w -w-pro checkes:           881005  */
/* 1.2:         Max limits off by 1. Fixed thanks to S. Creps: 881002  */
/* 1.0:         Release:                                       870515  */
/****************************************************************/

#include <curses.h>
#include <curspriv.h>

char _curses_winscrol_rcsid[] = "@(#)winscrol.c   v.1.4  - 900114";

/****************************************************************/
/* Scroll() scrolls the scrolling region of 'win', but only if */
/* scrolling is allowed and if the cursor is inside the scrol- */
/* ling region.                                                        */
/****************************************************************/

#if 0

void   
scroll(WINDOW *win)
{
    fprintf(stderr, "called scroll() in ntcurses\n");
    sleep(10);
}
  /* XXXdan curious if this gets called */

    short                 i;
    char                *ptr;
    char                *temp;
    short  blank;

    blank = ' ';


    if  ((!win->_scroll)                /* check if window scrolls */
	 || (win->_cury < 0)          /* and cursor in region */
	 || (win->_cury > (win->_maxy - 1))
	 ) {
	return;
    }

    temp = win->_line[0];
    for (i = 0; i < (win->_maxy - 1); i++) {
       /* 
	* re-arrange line pointers 
	*/
	win->_line[i] = win->_line[i+1];
	    win->_minchng[i] = 0;
	    win->_maxchng[i] = win->_maxx - 1;
    }

    /* 
     * make a blank line 
     */
    for (ptr = temp; ptr - temp < win->_maxx; ptr++) {
	*ptr = blank;                             
    }

    win->_line[win->_maxy - 1] = temp;
    if (win->_cury > 0) {
	win->_cury--;    
    }
    win->_minchng[win->_maxy - 1] = 0;
    win->_maxchng[win->_maxy - 1] = win->_maxx - 1;
} /* scroll */
#endif

#if 0
void 
scrollnow(WINDOW *win, int dir) 
{
    int	    dely, insy;
    int oy, ox;
    
    if (dir > 0) {
	dely = 0;
	insy = win->_maxy - 1;
    } else {
	insy = 0;
	dely = win->_maxy - 1;
    }
    
    getyx(win, oy, ox);
    wmove(win, dely, 0);
    wdeleteln(win);
    wmove(win, insy, 0);
    winsertln(win);
    wmove(win, oy, ox);
    wrefresh(win);
    
    return OK;
}

#else

void 
scrollnow(WINDOW *win, int dir) 
{
    ntcCell		*end;
    ntcCell		*temp, *temp2;
    short	 	y;		/* line number relative to win */
    int 		i;
    ntcCell		blank;


    (void *)makeNtcCell(&blank, ' ');
    if (win->_flags & _STANDOUT) {
	(void *)hilight(&blank);
    }

    if (dir > 0) {
	/*
	 * scroll lines up the window and the current screen 
	 */
	temp = win->_line[0];
	temp2 = curscr->_line[win->_begy];
	
	for (y = 0; y < (win->_maxy - 1); y++) {
	    win->_line[y] = win->_line[y+1];
	    win->_minchng[y] = win->_minchng[y+1];
	    win->_maxchng[y] = win->_maxchng[y+1];
	    curscr->_line[win->_begy + y] = curscr->_line[win->_begy + y+1];
	}
	
	win->_line[y] = temp;
	curscr->_line[win->_begy + y] = temp2;
	
	/*
	 * XXXdan perhaps blanks should be hi-lited if standout is on
	 */
	for (i = 0; i < win->_maxx; i++) {
	    setNtcCell(&(win->_line[y][i]), &blank);
	    setNtcCell(&(curscr->_line[win->_begy + y][i]), &blank);
	}
	
	win->_minchng[y] = 0;
	win->_maxchng[y] = win->_maxx - 1;

	consoleScrollWin(win->_begy + 0, 
			 0,
			 win->_begy + 1,
			 0,
			 win->_begy + (win->_maxy - 1),
			 win->_maxx - 1);
    } else {
	/*
	 * scroll lines down the window and the current screen 
	 */
	temp = win->_line[win->_maxy - 1];
	temp2 = curscr->_line[win->_begy + win->_maxy - 1];
	
	for (y = win->_maxy - 1; y > 0; y--) {
	    win->_line[y] = win->_line[y-1];
	    win->_minchng[y] = win->_minchng[y-1];
	    win->_maxchng[y] = win->_maxchng[y-1];
	    curscr->_line[win->_begy + y] = curscr->_line[win->_begy + y-1];
	}
	
	win->_line[y] = temp;
	curscr->_line[win->_begy + y] = temp2;
	
	/*
	 * XXXdan perhaps blanks should be hi-lited if standout is on
	 */
	for (i=0; i<win->_maxx; i++) {
	    setNtcCell(&(win->_line[y][i]), &blank);
	    setNtcCell(&(curscr->_line[win->_begy + y][i]), &blank);
	}
	
	win->_minchng[y] = 0;
	win->_maxchng[y] = win->_maxx - 1;

	consoleScrollWin(win->_begy + 1, 
			 0,
			 win->_begy + 0,
			 0,
			 win->_begy + (win->_maxy - 1) - 1,
			 win->_maxx - 1);
    }
    wrefresh(win);
}
#endif
