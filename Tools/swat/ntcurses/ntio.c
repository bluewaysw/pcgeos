/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		swat - ntcurses
FILE:		ntio.c

AUTHOR:		Dan Baumann, Apr 08, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	dbaumann	4/08/97   	Initial version

DESCRIPTION:

	

	$Id: ntio.c,v 1.1 97/04/18 11:22:13 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/**************

    Windows NT Curses Functions i/o for Win32 console mode

    Written by David Feinleib and the Windows NT marching band 6/15/92
    For use with PCCurses 1.4

****************/

#include <windows.h>
#include <stdio.h>
#include <io.h> /* eof() */

#include <curses.h>
#include "curspriv.h"
//#include <alloc.h>

extern HANDLE hConIn;
extern HANDLE hConOut;

static int cbreakOn = 1;

PCHAR_INFO 
GetFillChar(void)
{
    static CHAR_INFO ciFill = {NULL, NULL};  
    CONSOLE_SCREEN_BUFFER_INFO csbi;

    /* 
     * initialize the fill char the first time through, needs to match 
     * the current console attributes 
     */
    if (ciFill.Char.UnicodeChar == NULL) {
	ciFill.Char.UnicodeChar = ' ';
	GetConsoleScreenBufferInfo(hConOut, &csbi);
	ciFill.Attributes = csbi.wAttributes;
    }		     
    return &ciFill;
}

/*
 * makes an ntcCell out of ascii char a
 */
ntcCell*
makeNtcCell(ntcCell *pntc, char a) 
{
    PCHAR_INFO pci = GetFillChar();

    pntc->uniChar = a & 0xff;
    pntc->attr = pci->Attributes;

    return pntc;
}

ntcCell*
hilight(ntcCell *n)
{
    PCHAR_INFO pci;

    pci = GetFillChar();
    n->attr = (pci->Attributes >> 4) | ((pci->Attributes << 4) & 0xf0);
    return n;
}

void 
consoleCursor(int row, int column)
{
    COORD dwCursorPosition;

    if ((row == _cursvar.cursrow) && (column == _cursvar.curscol)) {
	return;
    }
    
    _cursvar.cursrow = row;
    _cursvar.curscol = column;

    dwCursorPosition.Y = row;
    dwCursorPosition.X = column;
    
    SetConsoleCursorPosition(hConOut, dwCursorPosition);
}

void 
consoleSetCell(short row, short column, ntcCell *c)
{
    DWORD dw;
    unsigned char a;

#if 0   
    /* 
     * turn on to debug sjis characters 
     */
    if (c->uniChar > 0xff) {
	char msg[1000];
	sprintf(msg, "complex char = %d", c->uniChar);
	MessageBox(NULL, msg, "ntcurses", MB_OK);
    }
#endif

    SetConsoleTextAttribute(hConOut, c->attr); 
    consoleCursor(row, column);
    if ((c->uniChar >> 8) != 0) {
	a = c->uniChar >> 8;
	WriteConsole(hConOut, &a, 1, &dw, NULL);
	column +=1;
    }
    a = c->uniChar & 0xff;
    WriteConsole(hConOut, &a, 1, &dw, NULL);

    /*
     * update the cursor position variable appropriately
     */
    column +=1;
    if (column >= COLS) {
	column = COLS - 1;
    }
    _cursvar.cursrow = row;
    _cursvar.curscol = column;
}

void 
consoleClearRect(short top, 
		 short left, 
		 short bottom, 
		 short right)
{
    static COORD origin = {0, 0};
    static COORD size;
    SMALL_RECT scrbuf;
    PCHAR_INFO sourcebuf, pci;
    int i;

    pci = GetFillChar();

    size.Y = bottom - top + 1;
    size.X = right - left + 1; 

    sourcebuf = (PCHAR_INFO)malloc((size.Y * size.X) * sizeof(CHAR_INFO));
    for (i = 0; i < (size.Y * size.X); i++) {
	sourcebuf[i].Char.UnicodeChar = pci->Char.UnicodeChar;
	sourcebuf[i].Attributes = pci->Attributes;
    }

    scrbuf.Top = top;
    scrbuf.Left = left;
    scrbuf.Bottom = bottom;
    scrbuf.Right = right;

    WriteConsoleOutput(hConOut, sourcebuf, size, origin, &scrbuf);

    free(sourcebuf);
}

void
consoleScrollWin(short desty, 
		 short destx,
		 short top, 
		 short left, 
		 short bottom, 
		 short right)
{ 
    COORD dwDestOrigin;
    SMALL_RECT srScrollRect;

    dwDestOrigin.Y = desty;      
    dwDestOrigin.X = destx;

    srScrollRect.Top = top;
    srScrollRect.Bottom = bottom;
    srScrollRect.Left = left;
    srScrollRect.Right = right;

    ScrollConsoleScreenBuffer(hConOut, 
			      &srScrollRect,
			      NULL,
			      dwDestOrigin,
			      GetFillChar());       
}

void 
consoleFlash(void)
{
    /*
     * not working yet
     * XXXdan
     */
#if 0
    COORD cooStart = {0, 0};
    DWORD lpcWritten = 0;
    PCHAR_INFO ci = GetFillChar();

    FillConsoleOutputAttribute(hConOut,
			       ((ci->Attributes & 0xf0) >> 8) |
			       ((ci->Attributes & 0x0f) << 8),
			       LINES * COLS,
			       cooStart,
			       &lpcWritten);

    FillConsoleOutputAttribute(hConOut,
			       ci->Attributes,
			       LINES * COLS,
			       cooStart,
			       &lpcWritten);
# endif
    return;
}

void 
consoleBeep(void)
{
    Beep(500,			/* tone 37 - 32,767 */
	 20);			/* duration in milliseconds */
}

bool 
consoleKeytst(void)
{
    INPUT_RECORD        inputrec[81];
    DWORD               dwRead;
    int                 i;

    if (PeekConsoleInput(hConIn, (PINPUT_RECORD)inputrec, 80,
			  &dwRead)) {
	for (i = 0; i < dwRead; i++) {
	    if ((inputrec[i].EventType == KEY_EVENT) && 
		(inputrec[i].Event.KeyEvent.bKeyDown == TRUE)) 
	    {
		return (TRUE);
	    }
	    if ((inputrec[i].EventType == MOUSE_EVENT) && 
		(inputrec[i].Event.MouseEvent.dwEventFlags == 0) &&
		((inputrec[i].Event.MouseEvent.dwButtonState == 1) ||
		 (inputrec[i].Event.MouseEvent.dwButtonState == 2)))
		return (TRUE);
	}
    }
    return (FALSE);
}

int
consoleConvertKeyToDos(int ntVirtualKey)
{
    switch (ntVirtualKey) {
    case HOME_EXTENDED:
	return HOME_ASCII;
    case END_EXTENDED:
	return END_ASCII;
    case PAGE_UP_EXTENDED:
	return PAGE_UP_ASCII;
    case PAGE_DOWN_EXTENDED:
	return PAGE_DOWN_ASCII;
    case UP_ARROW_EXTENDED:
	return UP_ARROW_ASCII;
    case DOWN_ARROW_EXTENDED:
	return DOWN_ARROW_ASCII;
    case LEFT_ARROW_EXTENDED:
	return LEFT_ARROW_ASCII;
    case RIGHT_ARROW_EXTENDED:
	return RIGHT_ARROW_ASCII;
    default:
	return 0;      /* not a supported key */
    }
}

unsigned long
consoleGetChar(void)
{
    DWORD dwRead;
    INPUT_RECORD inputEvent;
    unsigned long valueReturned;

    while (1) {
	ReadConsoleInput(hConIn, &inputEvent, 1, &dwRead);
	if (dwRead == 0) {
	    continue;
	}
	if (inputEvent.EventType == KEY_EVENT) {
	    if (inputEvent.Event.KeyEvent.bKeyDown == TRUE) {
		if (inputEvent.Event.KeyEvent.uChar.AsciiChar != 0) {
		    valueReturned = inputEvent.Event.KeyEvent.uChar.AsciiChar;
		    break;
		} else {
		    valueReturned = consoleConvertKeyToDos(
			inputEvent.Event.KeyEvent.wVirtualKeyCode);
		    if (valueReturned != 0) {
			break;
		    }
		}
	    }
	    /* 
	     * else skip it - we want only key releases
	     * note - if key is held down and repeats we get key up events
	     */
	} else if (inputEvent.EventType == MOUSE_EVENT) {
	    if ((inputEvent.Event.MouseEvent.dwEventFlags == 0) &&
		((inputEvent.Event.MouseEvent.dwButtonState == 1) ||
		 (inputEvent.Event.MouseEvent.dwButtonState == 2)))
	    {
		valueReturned = 0x01000000 
		    |
		  ((inputEvent.Event.MouseEvent.dwButtonState & 0xff) << 16)
		    |
		  ((inputEvent.Event.MouseEvent.dwMousePosition.Y & 0xff) << 8)
		    |
		  ((inputEvent.Event.MouseEvent.dwMousePosition.X & 0xff));
		break;
	    }
	}
	/* 
	 * else, we discard the event and get another one
	 */
    }

    return (valueReturned);
}

int 
consoleGcmode(void)
{
    return (0); /* need to convert between con info (%) and bits */
}

/* 
 * sets cursor size 
 */
void 
consoleCmode(int startrow, int endrow)
{
}


int 
consoleGcb(void)
{
    return (cbreakOn); 
}

void 
consoleScb(int setting)
{
    cbreakOn = setting;
}
