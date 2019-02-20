/***********************************************************************
 *
 *	Copyright (c) Geoworks 1997.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  swat - ntcurses
 * FILE:	  curses.h
 *
 * AUTHOR:  	  Dan Baumann: Apr 08, 1997
 *
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	dbaumann	4/08/97   	Initial version
 *
 * DESCRIPTION:
 *
 *	
 *
 *	$Id: curses.h,v 1.1 97/04/18 11:19:22 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _CURSES_H_
#define _CURSES_H_

#endif /* _CURSES_H_ */
/****************************************************************/
/*			    CURSES.H				*/
/* Header file for definitions and declarations for the		*/
/* PCcurses package. This should be #include'd in all user	*/
/* programs.							*/
/****************************************************************/
/* This version of curses is based on ncurses, a curses version	*/
/* originally written by Pavel Curtis at Cornell University.	*/
/* I have made substantial changes to make it run on IBM PC's,	*/
/* and therefore consider myself free to make it public domain.	*/
/*				Bjorn Larsson (bl@infovox.se)	*/
/****************************************************************/
/* 1.4:  Window origin mod in overlay() and overwrite(),	*/
/*	 on public (and very reasonable) request. Swapped	*/
/*	 #define'd values of OK and ERR; OK now 1, and		*/
/*	 ERR is 0/NULL. Conforms better to UNIX versions.	*/
/*	 borderchars[] removed from WINDOW struct since		*/
/*	 the border() functions were re-defined. Use of		*/
/*	 short wherever possible. Portability improve-		*/
/*	 ments, mispelled name of [w]setscrreg():	900114	*/
/* 1.3:	 All modules lint-checked with MSC '-W3' and		*/
/*	 Turbo'C' '-w -w-pro' switches. Support for		*/
/*	 border(), wborder() functions:			881005	*/
/* 1.2:	 Rcsid[] string in all modules, for mainte-		*/
/*	 nance:						881002	*/
/* 1.1:	 'Raw' output routines, revision info in		*/
/*	 curses.h:					880306	*/
/* 1.0:	 Release:					870515	*/
/****************************************************************/

// 6/19/92 DAF - changed _leave in WINDOW to _leavecurs to avoid conflict
// with NT C compiler

/* general definitions */
typedef struct {
    unsigned short uniChar;
    unsigned short attr;
} ntcCell;				/* the equivalent of CHAR_INFO */

#define VOID_CELL 0xff			/* 
					 * signals that the cell is really
					 * a place-holder (used after an
					 * SJIS char because they take up
					 * two bytes on the screen
					 */

#define UP_ARROW_EXTENDED	0x26
#define DOWN_ARROW_EXTENDED	0x28
#define LEFT_ARROW_EXTENDED	0x25
#define RIGHT_ARROW_EXTENDED	0x27
#define PAGE_UP_EXTENDED	0x21
#define PAGE_DOWN_EXTENDED	0x22
#define HOME_EXTENDED		0x24
#define END_EXTENDED		0x23

#define UP_ARROW_ASCII		0xc8		
#define DOWN_ARROW_ASCII	0xd0
#define LEFT_ARROW_ASCII	0xcb
#define RIGHT_ARROW_ASCII	0xcd
#define PAGE_UP_ASCII		0xc9
#define PAGE_DOWN_ASCII		0xd1
#define HOME_ASCII		0xc7
#define END_ASCII		0xcf

#ifndef	 bool
#define  bool		char		/* boolean type */
#endif

#ifndef	 TRUE
#define	 TRUE		1		/* booleans */
#endif

#ifndef	 FALSE
#define	 FALSE		0
#endif

#define	 ERR		0		/* general error flag */
#define	 OK		1		/* general OK flag */

/* functions defined as macros */

#define getch()	   wgetch(stdscr)	/* using macroes allows you to use */
#define	ungetch(c) wungetch(c)		/* #undef getch/ungetch in your */
					/* programs to use MSC/TRC getch() */
					/* and ungetch() routines */

#define getyx(win,y,x)   	(y = (win)->_cury, x = (win)->_curx)


#ifndef max
#define max(a,b) (((a) > (b)) ? (a) : (b))
#endif
#ifndef min
#define min(a,b) (((a) < (b)) ? (a) : (b))
#endif

/* function and keypad key definitions. Many are just for compatibility */

#define KEY_BREAK      0x101        /* Not on PC */
#define KEY_DOWN       0x102        /* The four arrow keys */
#define KEY_UP         0x103
#define KEY_LEFT       0x104
#define KEY_RIGHT      0x105
#define KEY_HOME       0x106        /* Home key */
#define KEY_BACKSPACE  0x107        /* Not on PC */
#define KEY_F0         0x108        /* Function keys. Space for */
#define KEY_F(n)       (KEY_F0+(n)) /*  64 keys is reserved. */
#define KEY_DL         0x148        /* Not on PC */
#define KEY_IL         0x149        /* Insert line */
#define KEY_DC         0x14a        /* Delete character */
#define KEY_IC         0x14b        /* Insert char or enter insert mode */
#define KEY_EIC        0x14c        /* Exit insert char mode */
#define KEY_CLEAR      0x14d        /* Clear screen */
#define KEY_EOS        0x14e        /* Clear to end of screen */
#define KEY_EOL        0x14f        /* Clear to end of line */
#define KEY_SF         0x150        /* Scroll 1 line forward */
#define KEY_SR         0x151        /* Scroll 1 line backwards (reverse) */
#define KEY_NPAGE      0x152        /* Next page */
#define KEY_PPAGE      0x153        /* Previous page */
#define KEY_STAB       0x154        /* Set tab */
#define KEY_CTAB       0x155        /* Clear tab */
#define KEY_CATAB      0x156        /* Clear all tabs */
#define KEY_ENTER      0x157        /* Enter or send (unreliable) */
#define KEY_SRESET     0x158        /* soft (partial) reset (unreliable) */
#define KEY_RESET      0x159        /* reset or hard reset (unreliable) */
#define KEY_PRINT      0x15a        /* print or copy */
#define KEY_LL         0x15b        /* home down or bottom (lower left) */
#define KEY_ABORT      0x15c        /*  Abort/Terminate key (any) */
#define KEY_SHELP      0x15d        /* Short help */
#define KEY_LHELP      0x15e        /* Long help */

/* type declarations */

typedef struct
  {
  short	   _cury;			/* Current pseudo-cursor */
  short	   _curx;
  short	   _maxy;			/* Max coordinates */
  short	   _maxx;
  short	   _begy;			/* Origin on screen */
  short	   _begx;
  short	   _flags;			/* Window properties */
  short	   _tabsize;			/* Tab character size */
  bool	   _clear;			/* Causes clear at next refresh */
  bool	   _leavecurs;			/* Leaves cursor as it happens */
  bool	   _scroll;			/* Allows window scrolling */
  bool	   _nodelay;			/* Input character wait flag */
  bool	   _keypad;			/* Flags keypad key mode active */
  ntcCell **_line;			/* Pointer to line pointer array */
  short	  *_minchng;			/* First changed character in line */
  short	  *_maxchng;			/* Last changed character in line */
  }	WINDOW;

/* External variables */

extern	int	LINES;			/* terminal height */
extern	int	COLS;			/* terminal width */
extern	WINDOW *curscr;			/* the current screen image */
extern	WINDOW *stdscr;			/* the default screen window */

/* PCcurses function declarations */

	/* put char in stdscr */
extern	int	 addch(unsigned char c);
	/* put wide char in stdscr */
extern	int	 addchWide(ntcCell *c);
	/* put char in stdscr, raw */
extern	int	 addrawch(unsigned char c);
extern	int	 addrawchWide(ntcCell *c);
	/* put string in stdscr */
extern	int	 addstr(unsigned char *str);
	/* set stdscr char attributes */
extern	void	 attrset(int attrs);
	/* clear attribute(a) stdscr */
extern	void	 attroff(int attrs);
	/* add attribute(s) stdscr */
extern	void	 attron(int attrs);
	/* compatibility dummy */
extern	int	 baudrate(void);
	/* sound bell */
extern	void	 beep(void);
	/* Set non-std box characters */
extern	void	 border(  int		 l,
  int		 r,
  int		 t,
  int		 b,
  int		 tl,
  int		 tr,
  int		 bl,
  int		 br
);
	/* draw a box around a window */
extern	void	 box(  WINDOW	*win,
  char		 v,
  char		 h
);
	/* set terminal cbreak mode */
extern	void	 cbreak(void);
	/* clear stdscr */
extern	void	 clear(void);
	/* marks a window for screen clear */
extern	void	 clearok(WINDOW	*win,  bool		 flag);
	/* clear end of stdscr */
extern	int	 clrtobot(void);
	/* clear end of line in stdscr */
extern	int	 clrtoeol(void);
	/* set terminal cbreak mode */
extern	void	 crmode(void);
	/* turns off hardware cursor */
extern	void	 cursoff(void);
	/* turns on hardware cursor */
extern	void	 curson(void);
	/* save TTY modes */
extern	void	 def_prog_mode(void);
	/* compatibility dummy */
extern	void	 def_shell_mode(void);
	/* delete a char in stdscr */
extern	int	 delch(void);
	/* delete a line in stdscr */
extern	int	 deleteln(void);
	/* delete a window or a subwindow */
extern	void	 delwin(WINDOW *win);
	/* update physical screen */
extern  void	 doupdate(void);
	/* set terminal echo mode */
extern	void	 echo(void);
	/* cleanup and finitialization */
extern	int	 endwin(void);
	/* erase stdscr */
extern	void	 erase(void);
	/* return char kill character */
extern	int	 erasechar(void);
	/* compatibility dummy */
extern	int	 fixterm(void);
	/* flash terminal screen */
extern	void	 flash(void);
	/* kill pending keyboard input */
extern	void	 flushinp(void);
	/* get string to stdscr and buffer */
extern  int	 getstr(char *str);
	/* compatibility dummy */
extern	int	 gettmode(void);
	/* use ins/del line (dummy) */
extern	void	 idlok(void);
	/* curses initialization */
extern	int	 initscr(void);
	/* get char at stdscr cursor */
extern  ntcCell *inch(void);
	/* insert character in stdscr */
extern	int	 insch(char c);
extern	int	 inschWide(ntcCell *ntc);
	/* insert character in stdscr, raw */
extern	int	 insrawch(char c);
extern	int	 insrawchWide(ntcCell *ntc);
	/* insert new line in stdscr */
extern	int	 insertln(void);
	/* marks a window for keypad usage */
extern	void	 keypad(  WINDOW	*win,
  bool		 flag
);
	/* return line kill character */
extern	int	 killchar(void);
	/* terminal description */
extern	char	*longname(void);
	/* marks window for cursor 'leave' */
extern	void	 leaveok(WINDOW	*win,
  bool		 flag);
	/* marks window for meta (dummy) */
extern	void	 meta(void);
	/* move cursor in stdscr */
extern	int	 move(int y, int x);
	/* move & put char in stdscr */
extern	int	 mvaddch(int x, int y, unsigned char c);
extern	int	 mvaddchWide(int x, int y, ntcCell *c);
	/* move & put char in stdscr, raw */
extern	int	 mvaddrawch(int	x, int y, unsigned char	 c);
	/* move & put char in stdscr, raw */
extern	int	 mvaddrawchWide(int	 x,
  int	 y,
  ntcCell *c);
	/* move & put string in stdscr */
extern	int	 mvaddstr(int y, int x, unsigned char *str);
	/* move & clear end of stdscr */
extern	int	 mvclrtobot(int y,
  int x);
	/* move & clear lineend in stdscr */
extern	int	 mvclrtoeol(  int y,
  int x);
	/* move terminal cursor */
extern	int	 mvcur(int oldy, int oldx, int newy, int newx);
	/* move & delete a char in stdscr */
extern	int	 mvdelch(  int y,
  int x);
	/* move & delete a line in stdscr */
extern	int	 mvdeleteln(  int y,
  int x);
	/* move & get char to stdscr */
extern	unsigned long	 mvgetch(int y,
  int x);
	/* move & get string to stdscr */
extern	int	 mvgetstr(int y,
  int x,
  char *str);
	/* move & get char at stdscr cursor */
extern	ntcCell	*mvinch(int y, int x);
extern	int	 mvinsch(  int  y,
  int  x,
  char c
);	/* move & insert char in stdscr */
extern int 	 mvinschWide(int y, int x, ntcCell *c);
	/* move & insert raw char in stdscr */
extern	int	 mvinsrawch(  int  y,
  int  x,
  char c
);
extern	int	 mvinsrawchWide(int y, int x, ntcCell *c);
	/* move & insert new line in stdscr */
extern	int	 mvinsertln(int y,
  int x);
	/* move & print string in stdscr */
extern	int	 mvprintw();
	/* move & get values via stdscr */
extern	int	 mvscanw();
	/* mv & put char in a window */
extern	int	 mvwaddch(WINDOW *win, int x, int y, unsigned char c);

extern	int	 mvwaddchWide(WINDOW *win, int x, int y, ntcCell *c);
	/* move & put char in a window, raw */
extern	int	 mvwaddrawch(WINDOW *win,
  int	  x,
  int	  y,
  unsigned char	  c);
extern	int	 mvwaddrawchWide(WINDOW *win, int x, int y, ntcCell *c);
	/* move & put string in a window */
extern	int	 mvwaddstr(  WINDOW *win,
  int    y,
  int    x,
  unsigned char   *str);
extern	int	 mvwaddstrWide(WINDOW *win, int y, int x, ntcCell *str);
	/* move & clear end of a window */
extern	int	 mvwclrtobot(  WINDOW *win,
  int y,
  int x
);
	/* move & clear lineend in a window */
extern	int	 mvwclrtoeol(WINDOW *win,
  int y,
  int x);
	/* move & delete a char in a window */
extern	int	 mvwdelch(  WINDOW *win,
  int y,
  int x
);
	/* move & delete a line in a window */
extern	int	 mvwdeleteln(WINDOW *win,
  int y,
  int x);
	/* move & get char to a window */
extern	unsigned long	 mvwgetch(  WINDOW *win,
  int y,
  int x
);
	/* move & get string to a window */
extern	int	 mvwgetstr(  WINDOW *win,
  int	  y,
  int	  x,
  char	 *str
);
	/* move & get char at window cursor */
extern	ntcCell	*mvwinch(WINDOW *win, int y, int x);
extern	int	 mvwinsch(  WINDOW *win,
  int  y,
  int  x,
  char c
);	/* move & insert char in a window */
extern int 	 mvwinschWide(WINDOW *win, int y, int x, ntcCell *c);
extern	int	 mvwinsrawch(  WINDOW *win,
  int  y,
  int  x,
  char c

);	/* move & insert raw char in window */
extern	int	 mvwinsrawchWide(WINDOW *win, int y, int x, ntcCell *ntc);
	/* move & insert new line in window */
extern	int	 mvwinsertln(WINDOW *win,  int y,  int x);
extern	int	 mvwin(  WINDOW       *win,
  int           begy, int begx
);	/* move window */
	/* move & print string in a window */
extern	int	 mvwprintw();
	/* move & get values via a window */
extern	int	 mvwscanw();
	/* create a window */
extern	WINDOW	*newwin(  int	num_lines,
  int	num_columns,
  int	begy,
  int	begx
);
	/* set terminal cr-crlf map mode */
extern	void	 nl(void);
	/* unset terminal cbreak mode */
extern	void	 nocbreak(void);
	/* unset terminal cbreak mode */
extern	void	 nocrmode(void);
	/* marks window for no input wait */
extern	void	 nodelay(  WINDOW	*win,
  bool		 flag);
	/* unset terminal echo mode */
extern	void	 noecho(void);
	/* unset terminal cr-crlf map mode */
extern	void	 nonl(void);
	/* unset raw terminal mode */
extern	void	 noraw(void);
	/* overlay one window on another */
extern	void	 overlay(WINDOW	*win1, WINDOW *win2);
	/* overwrite one window on another */
extern	void	 overwrite(WINDOW	*win1, WINDOW *win2);
	/* print string in stdscr */
extern	int	 printw();
	/* set raw terminal mode */
extern	void	 raw(void);
	/* set screen refresh break mode */
extern	void	 refrbrk(bool	bf);
	/* refresh stdscr */
extern	void	 refresh(void);
	/* compatibility dummy */
extern	int	 resetterm(void);
	/* restore terminal I/O modes */
extern	int	 resetty(void);
	/* restore terminal I/O modes */
extern	void	 reset_prog_mode(void);
	/* set terminal to default modes */
extern	void	 reset_shell_mode(void);
	/* compatibility dummy */
extern	int	 saveoldterm(void);
	/* compatibility dummy */
extern	int	 saveterm(void);
	/* save terminal I/O modes */
extern	int	 savetty(void);
	/* get values via stdscr */
extern	int	 scanw();
	/* scroll region in a window */
extern	void	 scroll(WINDOW *win);
	/* marks a window to allow scroll */
extern	void	 scrollok(WINDOW	*win,
  bool		 flag);
extern  void     scrollnow(WINDOW *win, int dir);
	/* compatibility dummy */
extern	int	 setterm(void);
	/* set up terminal (no-op) */
extern	int	 setupterm(void);
	/* start normal chars in stdscr */
extern	void	 standend(void);
	/* start standout chars in stdscr */
extern	void	 standout(void);
extern	WINDOW	*subwin(  WINDOW	*orig,
	/* create a sub-window */
  int		 num_lines, int num_columns, int begy, int begx);
	/* set/get tabsize of stdscr */
extern	int	 tabsize(int ts);
	/* mark a window as modified */
extern	void	 touchwin(WINDOW       *win);
	/* mark a line as modified */
extern	void	 touchline(WINDOW *win, int y, int sx, int ex);	
	/* char-to-string converter */
extern	char	*unctrl(char c);
	/* put char in a window */
extern	int	 waddch(WINDOW *win, unsigned char c); 
	/* put char in a window */
extern	int	 waddchWide(WINDOW *win, ntcCell *c);
	/* put char in a window, raw */
extern	int	 waddrawch(WINDOW *win, unsigned char c);
	/* put char in a window, raw */
extern	int	 waddrawchWide(WINDOW *win, ntcCell *c);
	/* put string in a window */
extern	int	 waddstr(WINDOW *win, unsigned char *str);
extern	int	 waddstrWide(WINDOW *win, ntcCell *str);
	/* clear a window */
extern	void	 wclear(WINDOW *win);
	/* clear end of a window */
extern	int	 wclrtobot(WINDOW *win);
	/* clear end of line in a window */
extern	int	 wclrtoeol(WINDOW	*win);
	/* delete a char in a window */
extern	int	 wdelch(WINDOW	*win);
	/* delete a line in a window */
extern	int	 wdeleteln(WINDOW	*win);
	/* erase a window */
extern	void	 werase(WINDOW *win);
	/* get char to a window */
extern	unsigned long	 wgetch(WINDOW	*win);
	/* get string to window and buffer */
extern  int	 wgetstr(WINDOW	*win, char *str);
	/* get char at window cursor */
extern	ntcCell *winch(WINDOW *win);
	/* insert character in a window */
extern	int	 winsch(  WINDOW *win, char c);
extern	int	 winschWide(WINDOW *win, ntcCell *ntc);
	/* insert raw character in a window */
extern	int	 winsrawch(WINDOW *win, char c);
extern	int	 winsrawchWide(WINDOW *win, ntcCell *ntc);
	/* insert new line in a window */
extern	int	 winsertln(WINDOW	*win);
	/* move cursor in a window */
extern	int	 wmove(WINDOW *win, int y, int x);
	/* create screen image, w/o display */
extern	void	 wnoutrefresh(WINDOW *win);
	/* print string in a * window */
extern	int	 wprintw(WINDOW *win, char *fmt, ...);
extern	int	 wprintwWide(WINDOW *win, char *fmt, ...);
	/* refresh screen */
extern	void	 wrefresh(WINDOW *win);
	/* get values via a window */
extern	int	 wscanw();
	/* start normal chars in window */
extern	void	 wstandend(  WINDOW	*win);
	/* start standout chars in window */
extern	void	 wstandout(  WINDOW	*win);
	/* set/get tabsize of a window */
extern	int	 wtabsize(  WINDOW       *win, int ts);
	/* character push-back */
extern	unsigned long	 wungetch(unsigned long 	ch);
extern  ntcCell  *makeNtcCell(ntcCell *pntc, char a);
extern	ntcCell  *hilight(ntcCell *n);
extern	void	ntcCellToChar(char *result, ntcCell *from, int units);
extern	void	charToNtcCell(ntcCell *result, char *from, int units);
extern	ntcCell *strncpyWide(ntcCell *dest, ntcCell *src, int len);
#define sameNtcCell(pNtc, pNtc2) ((((pNtc)->uniChar) == (pNtc2)->uniChar) &&	            			 (((pNtc)->attr) == (pNtc2)->attr))
#define setNtcCell(pNtc, pNtc2) (pNtc)->uniChar = (pNtc2)->uniChar,				                (pNtc)->attr = (pNtc2)->attr
