/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Curses Screen Library -- DOS video support
 * FILE:	  dos.c
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
 *	Functions for video support under MS DOS
 *
 * NOTES:
 *	Must set:
 *	    CE = ""
 *	    CA = TRUE	(cursor-motion possible)
 *	    SO = ""
 *	    AM = TRUE 	(auto-wrap always on)
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: dos.c,v 1.7 93/07/31 23:33:12 jenny Exp $";
#endif lint

#if defined(_MSDOS)

#include    "curses.ext"

#include    <graph.h>
#include    <pharlap.h>
#include    <dos.h>

extern void DosModeSet43Line(void);
extern void DosModeSet50Line(void);
extern void DosModeSet25Line(void);

static struct _videoconfig config;
static int  initLines;	    	/* Initial number of lines for EGA/VGA */

static unsigned curx, cury;
static unsigned addrPort;

#define	NORMAL_SCREEN_ATTR  0x07
static unsigned char curAttr = NORMAL_SCREEN_ATTR; /* White FG, black BG */

#define CURSOR_HIGH 0xe	    /* CRT register # for high byte of cursor
			     * location */
#define CURSOR_LOW  0xf	    /* CRT register # for low byte of cursor
			     * location */

#define PointToCur(p)	FP_SET((p), ((cury * 80) + curx) * 2, SS_SCREEN)

void
DosGoto(unsigned column, unsigned row)
{
    unsigned	cursorPos;
    
    cury = row;
    curx = column;

    /*
     * The CRTC's view of memory is skewed by 1 bit (the hardware adds an
     * extra zero so the CRTC can access the whole buffer in words), so
     * rather than multiplying Y by 160 and X by 2, we only need to multiply
     * Y by 80 and add X to it to form the word address in the refresh
     * buffer.
     *
     * We don't do video pages (yet), so we don't need to worry about the
     * offset to the start of the page.
     */
    cursorPos = (row * 80) + column;

    _outb(addrPort, CURSOR_HIGH);
    _outb(addrPort+1, cursorPos >> 8);

    _outb(addrPort, CURSOR_LOW);
    _outb(addrPort+1, cursorPos);
}

void
DosSyncBiosCursor(void)
{
    /* Synchronize the bios'es cursor position with our own, so echoed chars
     * end up in the right place. Called only before fetching a character
     * that's to be echoed, to avoid slowing down redisplay */
    union REGS r;

    r.h.ah = 2;
    r.h.bh = 0;
    r.h.dh = cury;
    r.l.dl = curx;

    int86(0x10, &r, &r);
}
    
void
DosScrollWin(int dely,	/* Line to delete (i.e. dest of scroll) */
	     int insy)	/* Line to insert (i.e. inclusive end of scroll) */
{
    unsigned short _far *dest;
    unsigned short _far *src;
    unsigned x;
    unsigned short space = ' ' | (curAttr << 8);

    if (insy < dely) {
	/*
	 * Scrolling down. Move insy to insy+1
	 */
	FP_SET(dest, (insy+1) * 160, SS_SCREEN);
	FP_SET(src, insy * 160, SS_SCREEN);
	_move_right(src, dest, (dely - insy) * 160);
    } else {
	/*
	 * Scrolling up. Move dely+1 to dely
	 */
	FP_SET(dest, dely * 160, SS_SCREEN);
	FP_SET(src, (dely+1) * 160, SS_SCREEN);
	_move(src, dest, (insy - dely) * 160);
    }
    FP_SET(src, insy * 160, SS_SCREEN);
    for (x = 0; x < COLS; x++) {
	*src++ = space;
    }
}

void
DosNewLine(void)
{
    /* Linefeed+CR & scroll if going past bottom of screen */
    if (cury == LINES-1) {
	DosScrollWin(0, cury);
	DosGoto(0, cury);
    } else {
	DosGoto(0, cury+1);
    }
}

void
DosInitScreen(void)
{
    /* Go back into the preferred video mode; used after ending things,
     * and returning to the video mode active on start-up, when resuming
     * operation (would have put out VS and TI strings) */

    if ((config.adapter == _EGA) &&
	(initLines != 43))
    {
	DosModeSet43Line();
    } else if ((config.adapter == _VGA) &&
	       (initLines != 50))
    {
	DosModeSet50Line();
    }
}

void
DosResetScreen(void)
{
    /* Restore screen to what it was when setterm() was called */
    DosSyncBiosCursor();
    if (((config.adapter == _EGA) ||
	 (config.adapter == _VGA)) &&
	(LINES != initLines))
    {
	if (initLines == 43) {
	    DosModeSet43Line();
	} else {
	    DosModeSet25Line();
	}
    }
}

void
DosClearScreen(void)
{
    unsigned short _far *p;
    unsigned short space = ' ' | (curAttr << 8);
    unsigned short n;

    n = (COLS * 2) * LINES;

    FP_SET(p, 0, SS_SCREEN);

    /*
     * Must store in p[0] and p[1] to cope with rep movsd compiler uses...
     */
    p[0] = space;
    p[1] = space;
    
    _move(p, p+2, n-4);

    DosGoto(0,0);
}

void
DosClearToEndOfLine(void)
{
    unsigned short _far *p;
    unsigned short space;
    unsigned x;

    PointToCur(p);

    space = ' ' | (NORMAL_SCREEN_ATTR << 8);
    
    for (x = curx; x < COLS; x++) {
	*p++ = space;
    }
}

void
DosStartStandOut(void)
{
    curAttr = ((curAttr & 0xf) << 4) | ((curAttr >> 4) & 0xf);
}

void
DosEndStandOut(void)
{
    curAttr = ((curAttr & 0xf) << 4) | ((curAttr >> 4) & 0xf);
}

char
_putchar(c)
    char c;
{
    switch(c) {
	case '\n':
	    DosNewLine();
	    break;
	case '\r':
	    DosClearToEndOfLine();
	    DosGoto(0, cury);
	    break;
	case '\b':
	    if (curx == 0) {
		if (cury == 0) {
		    DosGoto(COLS-1, 0);
		} else {
		    DosGoto(COLS-1, cury-1);
		}
	    } else {
		DosGoto(curx-1, cury);
	    }
	    break;
	default:
	{
	    volatile char _far *p;
	    
	    PointToCur(p);
	    *p++ = c;
	    *p++ = curAttr;
	    if (curx == COLS-1) {
		DosNewLine();
	    } else {
		DosGoto(curx+1, cury);
	    }
	    break;
	}
    }
}

int
setterm(void)
{
    if (_getvideoconfig(&config) == NULL) {
	return ERR;
    }
    
    LINES = config.numtextrows;
    COLS = config.numtextcols;
    CA = TRUE;
    CE = "";
    AM = TRUE;
    BS = TRUE;
    MS = FALSE;
    SO = "so";
    SE = "se";
    UPPERCASE = FALSE;
    GT = FALSE;
    NONL = FALSE;

    switch(config.adapter) {
	case _EGA:
	case _VGA:
	{
	    /*
	     * Fetch the current number of rows, since high c is so lame as
	     * to not provide it to us.
	     */
	    unsigned char _far *nrowsPtr;

	    FP_SET(nrowsPtr, 0x484, SS_DOSMEM);
	    initLines = (*nrowsPtr) + 1;

	    if ((config.adapter == _EGA) &&
		(initLines != 43))
	    {
		DosModeSet43Line();
		LINES = 43;
	    } else if ((config.adapter == _VGA) &&
		       (initLines != 50))
	    {
		DosModeSet50Line();
		LINES = 50;
	    } else {
		LINES = initLines;
	    }
	    /*FALLTHRU*/
	}
	case _CGA:
	case _MDPA:
	case _MCGA:
	    addrPort = 0x3d4;
	    break;
	case _HGC:
	    addrPort = 0x3b4;
	    break;
    }
}

/*********************************************************************
 *			DosInvertScreenRegion
 *********************************************************************
 * SYNOPSIS: 	    invert a section of the screen
 * CALLED BY:	    GLOBAL
 * RETURN:  	    void
 * SIDE EFFECTS:    inverts a section of the screen
 * STRATEGY:	    Direct Video memory access
 *	    	    just nibble swat upper byte of each frame in the frame
 *	    	    buffer within the specified range
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	2/ 8/93		Initial version			     
 * 
 *********************************************************************/
DosInvertScreenRegion(short start, short end)
{	
    unsigned short _far *p;
    unsigned short c;

    /* video memory has columns of 80 frames per row, 2 bytes per frame */
    FP_SET(p, start, SS_SCREEN);
    while(start <= end)
    {
    	c = p[0];
    	c = (c & 0x00ff) | ((c & 0x0f00) << 4) | ((c & 0xf000) >> 4);
    	p[0] = c;
	p++;
	start+=2;
    }
}

/*********************************************************************
 *			DosCopyScreenRegion
 *********************************************************************
 * SYNOPSIS: 	    copy text from a section of the screen
 * CALLED BY:	    GLOBAL
 * RETURN:  	    void
 * SIDE EFFECTS:    
 * STRATEGY:	    Direct Video memory access
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	2/ 8/93		Initial version			     
 * 
 *********************************************************************/
DosCopyScreenRegion(char *buf, short start, short end)
{	
    short _far *p;
    short c;

    /* video memory has columns of 80 frames per row, 2 bytes per frame */
    FP_SET(p, start, SS_SCREEN);
    while(start <= end)
    {
	/* just get ascii value */
    	*buf++ = (p[0] & 0xff);
	p++;
	start+=2;
    }
}

/*********************************************************************
 *			DosWordSelectScreenRegion
 *********************************************************************
 * SYNOPSIS: 	    do a word selection in screen memory
 * CALLED BY:	    GLOBAL
 * RETURN:  	    start and end values in passed in variables
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	3/10/93		Initial version			     
 * 
 *********************************************************************/
int
inword (char c)
{
    if (isalnum(c))
	return TRUE;
    else if ((c == '_') || (c == '^') || (c == ':'))
	return TRUE;
    return FALSE;
}

DosWordSelectScreenRegion(short	click, short *start, short *end)
{
    short _far *p;
    short   cp=click;
    char    c;

    /*
     * video memory has columns of 80 frames per row, 2 bytes per frame
     */
    FP_SET(p, click, SS_SCREEN);
    if (!inword(p[0] & 0xff))
    {
    /*
     * If the clicked on character is neither alphanumberic nor one of the
     * special characters we want also included in "words", just return it.
     */
	*start = *end = click;
	return;
    }
    while(1)
    {
    	c = (p[0] & 0xff);
	if (!inword(c))
	{
	    break;
	}
	cp -= 2;
	--p;
    }
    *start = cp+2;
    cp = click;
    FP_SET(p, click, SS_SCREEN);
    while(1)
    {
    	c = (p[0] & 0xff);
	if (!inword(c))
	{
	    break;
	}
	cp += 2;
	p++;
    }
    *end = cp-2;
}
    
#endif /* _MSDOS */
