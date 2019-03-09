/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- X11 interface, Tty class definitions
 * FILE:	  Tty.h
 *
 * AUTHOR:  	  Adam de Boor: Apr 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Header file for users of the Tty widget class.
 *
 *
 * 	$Id: Tty.h,v 1.2 89/07/21 04:02:17 adam Exp $
 *
 ***********************************************************************/
#ifndef _TTY_H_
#define _TTY_H_

#include    <X11/AsciiText.h>

/* Resources:

 Name		     Class		RepType		Default Value
 ----		     -----		-------		-------------
 background	     Background		pixel		White
 border		     BorderColor	pixel		Black
 borderWidth	     BorderWidth	int		1
 destroyCallback     Callback		Pointer		NULL
 displayPosition     TextPosition	int		0
 editType	     EditType		XtTextEditType	XttextRead
 enterCallback	     Callback		Pointer		NULL
 file		     File		String		NULL
 height		     Height		int		font height
 insertPosition	     TextPosition	int		0
 interruptCallback   Callback           Pointer         NULL
 leftMargin	     Margin		int		2
 mappedWhenManaged   MappedWhenManaged	Boolean		True
 prompt		     Prompt		String		none
 selectTypes	     SelectTypes	Pointer		(internal)
 selection	     Selection		Pointer		empty selection
 sensitive	     Sensitive		Boolean		True
 string		     String		String		NULL
 textOptions	     TextOptions	int		0
 width		     Width		int		100
 x		     Position		int		0
 y		     Position		int		0

*/
#define	XtNenterCallback    "enterCallback"
#define XtNinterruptCallback "interruptCallback"

#ifndef XtNgeometry
#define XtNgeometry 	    "geometry"
#define XtCGeometry 	    "Geometry"
#endif

typedef struct _TtyClassRec *TtyWidgetClass;
typedef struct _TtyRec	    *TtyWidget;
extern WidgetClass	    ttyWidgetClass;

extern void		    XtTtyPrompt();
extern void		    XtTtyPrintf(Widget w, char *fmt, ...);
extern void 	    	    XtTtyVPrintf();
extern void		    XtTtyPutString();
extern void 	    	    XtTtySetFence();	/* Set input fence to given
						 * position */
extern XtTextPosition	    XtTtyGetFence();
extern int  	    	    XtTtyNumColumns();
/*
 * Funky function to fetch a single character from the user. Second arg
 * is a pointer to a character through which the fetched character is
 * stored.
 */
extern void 	    	    XtTtyGetChar();
extern void 	    	    XtTtyCharGotten();

/*
 * See if anything beyond the fence (beyond the pale? Naaahh)
 */
extern Boolean	    	    XtTtyHaveInput();
#endif /* _TTY_H_ */
