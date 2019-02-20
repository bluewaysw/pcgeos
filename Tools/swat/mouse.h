/********************************************************************
*								     
*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     
*								     
* 	PROJECT:	PC GEOS					     
* 	MODULE:							     
* 	FILE:		mouse.h				     
*								     
*	AUTHOR:		jimmy lefkowitz				     
*								     
*	REVISION HISTORY:					     
*								     
*	Name	Date		Description			     
*	----	----		-----------			     
*	jimmy	2/ 3/93		Initial version			     
*								     
*	DESCRIPTION:						     
* 	    	definitions for the mouse module
*	$Id: mouse.h,v 1.4 96/05/20 18:48:41 dbaumann Exp $							     
*							   	     
*********************************************************************/
#ifndef _MOUSE_H_
#define _MOUSE_H_

typedef struct 
{
    char   mouseX;
    char   mouseY;
    char   button;
} BPress;

#define MOUSEINIT 0		/* Initialize mouse */
#define MOUSESHOW 1		/* Show cursor */
#define MOUSEHIDE 2		/* Hid cursor */
#define MOUSESTAT 3		/* Return status. BX = buttons, */
				/* CX = X (pixels) DX = Y (pixels) */
#define MOUSEWARP 4		/* Change mouse position. CX = X (pixels) */
				/* DX = Y (pixels) */
#define MOUSELIMX 7		/* Set X limits. CX = min (pixels), */
				/* DX = max (pixels) */
#define MOUSELIMY 8		/* Set Y limits. CX = min (pixels), */
				/* DX = max (pixels) */
#define MOUSETEXT 10		/* Define text cursor.BX = 1 for hardware or */
				/* 0 for software. CX = screen mask. DX = */
				/* cursor mask */
#define MOUSEHANDL12		/* Define handler. CX = call mask. ES:DX is */
				/* handler address. */
#define MOUSEACCEL30		/* Set mouse accelerator. BX = type, */
				/* ES:DX = vector address */
#define MOUSEMODE 33		/* Set mouse mode. BX = 0 for read mode, */
				/* 1 for keyboard emulation mode and 2 for */


void Mouse_HideCursor(void);
void Mouse_ShowCursor(void);
void Mouse_Init(void);
void Mouse_Watch(void);
void Mouse_Ignore(void);
void Mouse_SetMouseHighlight(int value1, int value2);

#endif /* _MOUSE_H */
