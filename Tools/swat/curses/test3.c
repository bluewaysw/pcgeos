#include    "curses.h"

void *idfile;	    /* for printf from utils library */

main()
{
    char    str[128];
    WINDOW  *w;

    initscr();

    w = newwin(5, COLS, 0, 0);
    mvwaddstr(w, 0, 0, "Hi there: ");
    wgetestr(w, str);
    wprintw(w, "Very good! \"%s\"\n how profound.", str);
    wrefresh(w);
    mvcur(0, COLS, LINES-1, 0);
    endwin();
}
