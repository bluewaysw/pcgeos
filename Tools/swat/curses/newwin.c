/*
 * Copyright (c) 1980 Regents of the University of California.
 * All rights reserved.  The Berkeley software License Agreement
 * specifies the terms and conditions for redistribution.
 */

#ifndef lint
static char sccsid[] = "@(#)newwin.c	5.1 (Berkeley) 6/7/85";
#endif not lint

/*
 * allocate space for and set up defaults for a new window
 *
 */

# include	"curses.ext"

char	*malloc();

# define	SMALLOC	(short *) malloc

static WINDOW	*makenew();

# undef		nl	/* don't need it here, and it interferes	*/

WINDOW *
newwin(num_lines, num_cols, begy, begx)
int	num_lines, num_cols, begy, begx;
{
	reg WINDOW	*win;
	reg char	*sp;
	reg int		i, by, bx, nl, nc;
	reg int		j;

	by = begy;
	bx = begx;
	nl = num_lines;
	nc = num_cols;

	if (nl == 0)
		nl = LINES - by;
	if (nc == 0)
		nc = COLS - bx;
	if ((win = makenew(nl, nc, by, bx)) == NULL)
		return ERR;
	if ((win->_firstch = SMALLOC(nl * sizeof win->_firstch[0])) == NULL) {
		free(win->_y);
		free(win);
		return NULL;
	}
	if ((win->_lastch = SMALLOC(nl * sizeof win->_lastch[0])) == NULL) {
		free(win->_y);
		free(win->_firstch);
		free(win);
		return NULL;
	}
	win->_nextp = win;
	for (i = 0; i < nl; i++) {
		win->_firstch[i] = _NOCHANGE;
		win->_lastch[i] = _NOCHANGE;
	}
	for (i = 0; i < nl; i++)
		if ((win->_y[i] = malloc(nc /** sizeof win->_y[0]*/)) == NULL) {
			for (j = 0; j < i; j++)
				free(win->_y[j]);
			free(win->_firstch);
			free(win->_lastch);
			free(win->_y);
			free(win);
			return ERR;
		}
		else
			for (sp = win->_y[i]; sp < win->_y[i] + nc; )
				*sp++ = ' ';
	win->_ch_off = 0;
# ifdef DEBUG
	fprintf(outf, "NEWWIN: win->_ch_off = %d\n", win->_ch_off);
# endif
	win->_orig = NULL;

	return win;
}

WINDOW* resizewin(WINDOW* win, int num_lines, int num_columns) 
{
    int j;
    if(num_lines < win->_maxy) {

        /* remove lines at the beginning */
        while(win->_cury >= num_lines) {

            int c=1;
            free(win->_y[0]);
            for(c=1; c < win->_maxy; c++)
            {
                win->_y[c-1] = win->_y[c];
            }
            win->_maxy--;
            win->_cury--;
        }

        /* free removed lines */
	    for (j = num_lines; j < win->_maxy; j++) 
        {
            free(win->_y[j]);
        }

        /* realloc the others */
        for(j = 0; j < num_lines; j++)
        {
            void *newLine = realloc(win->_y[j], num_columns);
            if(newLine == NULL)
            {
    	        return((WINDOW *) ERR);
            }
            win->_y[j] = newLine;
        }

        /* fill new chars */
        for(j=0; j < num_lines; j++) {
            int x=0;
            for(x=win->_maxx; x < num_columns; x++) {

                win->_y[j][x] = ' ';
            }

            win->_firstch[j]=0;
            win->_lastch[j]=num_columns-1;
        }

        win->_maxx = num_columns;
        win->_maxy = num_lines;
    }
    else /*if(num_lines > win->_maxy)*/ 
    {
        void *newMinChg;
        void *newMaxChg;

        /* more lines now */
        void** newLines = realloc(win->_y, sizeof(win->_y[0]) * num_lines);
        if(newLines == NULL)
        {
	        return((WINDOW *) ERR);
        }
        win->_y = newLines;

        newMinChg = realloc(win->_firstch, sizeof(win->_firstch[0]) * num_lines);
        if(newMinChg == NULL)
        {
	        return((WINDOW *) ERR);
        }
        win->_firstch = newMinChg;

        newMaxChg = realloc(win->_lastch, sizeof(win->_lastch[0]) * num_lines);
        if(newMaxChg == NULL)
        {
	        return((WINDOW *) ERR);
        }
        win->_lastch = newMaxChg;

        /* allocate new lines*/
        for(j = win->_maxy; j < num_lines; j++)
        {
            newLines[j] = calloc(num_columns,
					    sizeof(win->_y[0]));
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
            void *newLine = realloc(win->_y[j], sizeof(win->_y[0]) *num_columns);
            if(newLine == NULL)
            {
                /* free all new lines*/
                j = num_lines;
                j--;
                while(j >= 0)
                {
                    free(win->_y[j]);
                    j--;
                }
    	        return((WINDOW *) ERR);
            }
            win->_y[j] = newLine;
        }

        /* fill new chars */
        for(j=0; j < num_lines; j++) {
            int x=0;
            if(win->_maxx< num_columns)
            {
                for(x=win->_maxx; x < num_columns; x++) {

                    win->_y[j][x] = ' ';
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

                    win->_y[j][a] = ' ';
                }
            }

            win->_firstch[j]=0;
            win->_lastch[j]=num_columns-1;
        }

        win->_maxx = num_columns;
        win->_maxy = num_lines;
    }
    return win;
}

WINDOW *
subwin(orig, num_lines, num_cols, begy, begx)
reg WINDOW	*orig;
int		num_lines, num_cols, begy, begx;
{
	reg int		i;
	reg WINDOW	*win;
	reg int		by, bx, nl, nc;

	by = begy;
	bx = begx;
	nl = num_lines;
	nc = num_cols;

	/*
	 * make sure window fits inside the original one
	 */
# ifdef	DEBUG
	fprintf(outf, "SUBWIN(%0.2o, %d, %d, %d, %d)\n", orig, nl, nc, by, bx);
# endif
	if (by < orig->_begy || bx < orig->_begx
	    || by + nl > orig->_maxy + orig->_begy
	    || bx + nc > orig->_maxx + orig->_begx)
		return ERR;
	if (nl == 0)
		nl = orig->_maxy + orig->_begy - by;
	if (nc == 0)
		nc = orig->_maxx + orig->_begx - bx;
	if ((win = makenew(nl, nc, by, bx)) == NULL)
		return ERR;
	win->_nextp = orig->_nextp;
	orig->_nextp = win;
	win->_orig = orig;
	_set_subwin_(orig, win);
	orig->_flags &= ~_NOSUBWIN;
	return win;
}

/*
 * this code is shared with mvwin()
 */
_set_subwin_(orig, win)
register WINDOW	*orig, *win;
{
	register int	i, j, k;

	j = win->_begy - orig->_begy;
	k = win->_begx - orig->_begx;
	win->_ch_off = k;
# ifdef DEBUG
	fprintf(outf, "_SET_SUBWIN_: win->_ch_off = %d\n", win->_ch_off);
# endif
	win->_firstch = &orig->_firstch[j];
	win->_lastch = &orig->_lastch[j];
	for (i = 0; i < win->_maxy; i++, j++)
		win->_y[i] = &orig->_y[j][k];

}

/*
 *	This routine sets up a window buffer and returns a pointer to it.
 */
static WINDOW *
makenew(num_lines, num_cols, begy, begx)
int	num_lines, num_cols, begy, begx; {

	reg int		i;
	reg WINDOW	*win;
	reg int		by, bx, nl, nc;

	by = begy;
	bx = begx;
	nl = num_lines;
	nc = num_cols;

# ifdef	DEBUG
	fprintf(outf, "MAKENEW(%d, %d, %d, %d)\n", nl, nc, by, bx);
# endif
	if ((win = (WINDOW *) malloc(sizeof *win)) == NULL)
		return NULL;
# ifdef DEBUG
	fprintf(outf, "MAKENEW: nl = %d\n", nl);
# endif
	if ((win->_y = (char **) malloc(nl * sizeof win->_y[0])) == NULL) {
		free(win);
		return NULL;
	}
# ifdef DEBUG
	fprintf(outf, "MAKENEW: nc = %d\n", nc);
# endif
	win->_cury = win->_curx = 0;
	win->_clear = FALSE;
	win->_maxy = nl;
	win->_maxx = nc;
	win->_begy = by;
	win->_begx = bx;
	win->_flags = _NOSUBWIN;
	win->_scroll = win->_leavecurs = FALSE;
	_swflags_(win);
# ifdef DEBUG
	fprintf(outf, "MAKENEW: win->_clear = %d\n", win->_clear);
	fprintf(outf, "MAKENEW: win->_leave = %d\n", win->_leave);
	fprintf(outf, "MAKENEW: win->_scroll = %d\n", win->_scroll);
	fprintf(outf, "MAKENEW: win->_flags = %0.2o\n", win->_flags);
	fprintf(outf, "MAKENEW: win->_maxy = %d\n", win->_maxy);
	fprintf(outf, "MAKENEW: win->_maxx = %d\n", win->_maxx);
	fprintf(outf, "MAKENEW: win->_begy = %d\n", win->_begy);
	fprintf(outf, "MAKENEW: win->_begx = %d\n", win->_begx);
# endif
	return win;
}

_swflags_(win)
register WINDOW	*win;
{
	win->_flags &= ~(_ENDLINE|_FULLLINE|_FULLWIN|_SCROLLWIN);
	if (win->_begx + win->_maxx == COLS) {
		win->_flags |= _ENDLINE;
		if (win->_begx == 0) {
#if !defined(_MSDOS)	/* Always set _FULLLINE for dos, so scrolling
			 * is fast */
			if (AL && DL)
#endif
				win->_flags |= _FULLLINE;
			if (win->_maxy == LINES && win->_begy == 0)
				win->_flags |= _FULLWIN;
		}
		if (win->_begy + win->_maxy == LINES)
			win->_flags |= _SCROLLWIN;
	}
}
