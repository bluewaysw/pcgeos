/*
 * Copyright (c) 1980 Regents of the University of California.
 * All rights reserved.  The Berkeley software License Agreement
 * specifies the terms and conditions for redistribution.
 *
 *	@(#)curses.h	5.1 (Berkeley) 6/7/85

 */

# ifndef WINDOW

# include	<stdio.h>
 
#if !defined(_MSDOS) && !defined(__WATCOMC__)
# include	<sgtty.h>
#endif
#include <sys/ioctl.h>

# define	bool	char
# define	reg	register

# define	TRUE	(1)
# define	FALSE	(0)
# define	ERR	(0)
# define	OK	(1)

# define	_ENDLINE	001
# define	_FULLWIN	002
# define	_SCROLLWIN	004
# define	_FLUSH		010
# define	_FULLLINE	020
# define	_IDLINE		040
# define    	_NOSUBWIN   	0100
# define	_STANDOUT	0200
# define	_NOCHANGE	-1

# define	_puts(s)	tputs(s, 0, _putchar)

#if !defined(_MSDOS) && !defined(__WATCOMC__)
typedef	struct sgttyb	SGTTY;
#endif

/*
 * Capabilities from termcap
 */

#undef HZ

extern bool     AM, BS, CA, DA, DB, EO, HC, HZ, IN, MI, MS, NC, NS, OS, UL,
		XB, XN, XT, XS, XX;
extern char	*AL, *BC, *BT, *CD, *CE, *CL, *CM, *CR, *CS, *DC, *DL,
		*DM, *DO, *ED, *EI, *K0, *K1, *K2, *K3, *K4, *K5, *K6,
		*K7, *K8, *K9, *HO, *IC, *IM, *IP, *KD, *KE, *KH, *KL,
		*KR, *KS, *KU, *LL, *MA, *ND, *NL, *RC, *SC, *SE, *SF,
		*SO, *SR, *TA, *TE, *TI, *UC, *UE, *UP, *US, *VB, *VS,
		*VE, *AL_PARM, *DL_PARM, *UP_PARM, *DOWN_PARM,
		*LEFT_PARM, *RIGHT_PARM;
extern char	PC;

/*
 * From the tty modes...
 */

extern bool	GT, NONL, UPPERCASE, normtty, _pfast;

struct _win_st {
	short		_cury, _curx;
	short		_maxy, _maxx;
	short		_begy, _begx;
	short		_flags;
	short		_ch_off;
	bool		_clear;
	bool		_leavecurs;
	bool		_scroll;
	char		**_y;
	short		*_firstch;
	short		*_lastch;
	struct _win_st	*_nextp, *_orig;
};

# define	WINDOW	struct _win_st

extern bool	My_term, _echoit, _rawmode, _endwin;

#define	TTYTYPESIZ	50
extern char	*Def_term, ttytype[TTYTYPESIZ];

extern int	LINES, COLS, _tty_ch, _res_flg;

#if !defined(_MSDOS) && !defined(__WATCOMC__)
extern SGTTY	_tty;
#endif

extern WINDOW	*stdscr, *curscr;

/*
 *	Define VOID to stop lint from generating "null effect"
 * comments.
 */
# ifdef lint
int	__void__;
# define	VOID(x)	(__void__ = (int) (x))
# else
# define	VOID(x)	(void)(x)
# endif

/*
 * pseudo functions for standard screen
 */
# define	addch(ch)	VOID(waddch(stdscr, ch))
# define	getch()		VOID(wgetch(stdscr))
# define	addstr(str)	VOID(waddstr(stdscr, str))
# define	getstr(str)	VOID(wgetstr(stdscr, str))
# define	move(y, x)	VOID(wmove(stdscr, y, x))
# define	clear()		VOID(wclear(stdscr))
# define	erase()		VOID(werase(stdscr))
# define	clrtobot()	VOID(wclrtobot(stdscr))
# define	clrtoeol()	VOID(wclrtoeol(stdscr))
# define	insertln()	VOID(winsertln(stdscr))
# define	deleteln()	VOID(wdeleteln(stdscr))
# define	refresh()	VOID(wrefresh(stdscr))
# define	inch()		VOID(winch(stdscr))
# define	insch(c)	VOID(winsch(stdscr,c))
# define	delch()		VOID(wdelch(stdscr))
# define	standout()	VOID(wstandout(stdscr))
# define	standend()	VOID(wstandend(stdscr))

/*
 * mv functions
 */
#define	mvwaddch(win,y,x,ch)	VOID(wmove(win,y,x)==ERR?ERR:waddch(win,ch))
#define	mvwgetch(win,y,x)	VOID(wmove(win,y,x)==ERR?ERR:wgetch(win))
#define	mvwaddstr(win,y,x,str)	VOID(wmove(win,y,x)==ERR?ERR:waddstr(win,str))
#define mvwgetstr(win,y,x,str)  VOID(wmove(win,y,x)==ERR?ERR:wgetstr(win,str))
#define	mvwinch(win,y,x)	VOID(wmove(win,y,x)==ERR?ERR:winch(win))
#define	mvwdelch(win,y,x)	VOID(wmove(win,y,x)==ERR?ERR:wdelch(win))
#define	mvwinsch(win,y,x,c)	VOID(wmove(win,y,x)==ERR?ERR:winsch(win,c))
#define	mvaddch(y,x,ch)		mvwaddch(stdscr,y,x,ch)
#define	mvgetch(y,x)		mvwgetch(stdscr,y,x)
#define	mvaddstr(y,x,str)	mvwaddstr(stdscr,y,x,str)
#define mvgetstr(y,x,str)       mvwgetstr(stdscr,y,x,str)
#define	mvinch(y,x)		mvwinch(stdscr,y,x)
#define	mvdelch(y,x)		mvwdelch(stdscr,y,x)
#define	mvinsch(y,x,c)		mvwinsch(stdscr,y,x,c)

/*
 * pseudo functions
 */

#define	clearok(win,bf)	 (win->_clear = bf)
#define	leaveok(win,bf)	 (win->_leavecurs = bf)
#define	scrollok(win,bf) (win->_scroll = bf)
#define flushok(win,bf)	 (bf ? (win->_flags |= _FLUSH):(win->_flags &= ~_FLUSH))
#define	getyx(win,y,x)	 y = win->_cury, x = win->_curx
#define	winch(win)	 (win->_y[win->_cury][win->_curx] & 0177)

#if !defined(_MSDOS) && !defined(__WATCOMC__)
#define raw()	 (_tty.sg_flags|=RAW, _pfast=_rawmode=TRUE, ioctl(_tty_ch,TIOCSETN,&_tty))
#define noraw()	 (_tty.sg_flags&=~RAW,_rawmode=FALSE,_pfast=!(_tty.sg_flags&CRMOD),ioctl(_tty_ch,TIOCSETN,&_tty))
#define cbreak() (_tty.sg_flags |= CBREAK, _rawmode = TRUE, ioctl(_tty_ch,TIOCSETN,&_tty))
#define nocbreak() (_tty.sg_flags &= ~CBREAK,_rawmode=FALSE,ioctl(_tty_ch,TIOCSETN,&_tty))
#define crmode() cbreak()	/* backwards compatability */
#define nocrmode() nocbreak()	/* backwards compatability */
#define echo()	 (_tty.sg_flags |= ECHO, _echoit = TRUE, ioctl(_tty_ch, TIOCSETN, &_tty))
#define noecho() (_tty.sg_flags &= ~ECHO, _echoit = FALSE, ioctl(_tty_ch, TIOCSETN, &_tty))
#define nl()	 (_tty.sg_flags |= CRMOD,_pfast = _rawmode,ioctl(_tty_ch, TIOCSETN, &_tty))
#define nonl()	 (_tty.sg_flags &= ~CRMOD, _pfast = TRUE, ioctl(_tty_ch, TIOCSETN, &_tty))
#define	savetty() ((void) ioctl(_tty_ch, TIOCGETP, &_tty), _res_flg = _tty.sg_flags)
#define	resetty() (_tty.sg_flags = _res_flg, (void) ioctl(_tty_ch, TIOCSETN, &_tty))

#define	erasechar()	(_tty.sg_erase)
#define	killchar()	(_tty.sg_kill)
#define baudrate()	(_tty.sg_ospeed)

#else
#define erasechar() 	(0x7f)
#define killchar()  	('X' & 0x1f)
#define echo() 	    	(_echoit = TRUE)
#define noecho()    	(_echoit = FALSE)
#endif

WINDOW	*initscr(), *reinitscr(), *newwin(), *subwin();
char	*longname(), *getcap();

/*
 * Used to be in unctrl.h.
 */
#define	unctrl(c)	_unctrl[(c) & 0177]
extern char *_unctrl[];
# endif /* WINDOW */
