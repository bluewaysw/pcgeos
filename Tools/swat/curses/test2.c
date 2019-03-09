#include "curses.h"

#define YPOSBOX		 0
#define XPOSBOX		 0
#define YBOX		20
#define XBOX	        80

#define YPOSSBOX	 2
#define XPOSSBOX	10
#define YSBOX	        17
#define XSBOX	        66

speckle(WINDOW *w, char c, int height)
{
    int	i,j,k;
    
    for (i = 0, k = 0; i < height; i++, k = (k + 1) % 7) {
	for (j = 0; j < COLS; j++, k = (k + 1) % 7) {
	    if (k) {
		mvwaddch(w, i, j, c);
	    } else {
		mvwaddch(w, i, j, 'k');
	    }
	}
    }
}

main()
{
    WINDOW  *foo, *foo2, *foo3;
    int	    i, j, k;

#define LINES1	2
#define LINES2	10
#define LINES3 	12
    initscr();
    foo = newwin(LINES1, COLS, 0, 0);
    foo2 = newwin(LINES2, COLS, LINES1, 0);
    foo3 = newwin(LINES3, COLS, LINES1+LINES2, 0);

    speckle(foo, '1', LINES1);
    speckle(foo2, '2', LINES2);
    speckle(foo3, '3', LINES3);
    wrefresh(foo);
    wrefresh(foo2);
    wrefresh(foo3);

/*    sleep(1);*/
    scrollok(foo2, 1); scrollok(foo,1);
    
    mvwaddstr(foo, 0, 0, "Hit return when done: ");
    wrefresh(foo);
/*    cbreak();*/
    while(1) {
	wrefresh(foo);
	switch(wgetch(foo)) {
	    case 'u':
		scrollnow(foo2, 1);
		break;
	    case 'd':
		scrollnow(foo2, -1);
		break;
	    case 8:
		break;
	    default:
		mvcur(0,COLS-1,LINES-1,0);	/* move to bottom of screen */
		endwin();
		exit(0);
	}
    }
}
