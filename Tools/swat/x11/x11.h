/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- X11 interface, common definitions
 * FILE:	  x11.h
 *
 * AUTHOR:  	  Adam de Boor: Jul 18, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/18/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Common definitions for the X11 interface
 *
 *
 * 	$Id: x11.h,v 1.1 89/07/21 04:03:12 adam Exp $
 *
 ***********************************************************************/
#ifndef _X11_H_
#define _X11_H_

#define Boolean XtBool
#define Opaque  XtOpaque
#include    <X11/StringDefs.h>
#include    <X11/Intrinsic.h>
#undef Opaque
#undef Boolean

extern	Widget	    shell,  	/* Top-most window */
		    tty,    	/* Main I/O window */
		    curWin;  	/* Current text window */
extern XtAppContext ctxt;   	/* Context to which above are attached */
extern Display	    *dpy;   	/* Display connection */
extern Time 	    lastEvent;	/* Timestamp from last-received event */

/*
 * State Of The Interface
 */
extern int  	x11Flags;
#define X11_GETCHAR 	0x00000001  /* Set if fetching a character */
#define X11_ECHO    	0x00000002  /* Set if should echo fetched character */
#define X11_GETCMD  	0x00000004  /* Set if fetching a command */
#define X11_GETLINE 	0x00000008  /* Set if fetching just a line */

#endif /* _X11_H_ */
