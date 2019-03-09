/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- X11 interface, Tty class private definitions
 * FILE:	  TtyP.h
 *
 * AUTHOR:  	  Adam de Boor: Apr 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Private header file for subclasses of Tty
 *
 *
 * 	$Id: TtyP.h,v 1.2 89/07/21 04:02:26 adam Exp $
 *
 ***********************************************************************/
#ifndef _TTYP_H_
#define _TTYP_H_

#include    <X11/AsciiTextP.h>
#include    "Tty.h"

/* New class fields */
typedef struct { int empty; } TtyClassPart;

/* Class record (Note: Tty is a subclass of Text) */
typedef struct _TtyClassRec {
    CoreClassPart 	core_class;
    SimpleClassPart	simple_class;
    TextClassPart 	text_class;
    TtyClassPart  	tty_class;
} TtyClassRec;

extern TtyClassRec	ttyClassRec;

/* New instance fields */
typedef struct _TtyPart {
    /* Resources */
    XtCallbackList	enter;	    /* Text entered */
    XtCallbackList	interrupt;  /* Interrupt character typed */
    char    	    	*geometry;  /* Initial geometry */
    /* Derived resources */
    XtTextPosition	markPos;    /* Position of mark */
    int	    	    	charWidth;  /* Width of a character */
    int	    	    	charHeight; /* Height of a character */
} TtyPart;

/* Instance record */
typedef struct _TtyRec {
    CorePart	  core;
    SimplePart	  simple;
    TextPart	  text;
    TtyPart	  tty;
} TtyRec;

#endif /* _TTYP_H_ */
