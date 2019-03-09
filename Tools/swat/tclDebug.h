/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Tcl debugger
 * FILE:	  tclDebug.h
 *
 * AUTHOR:  	  Adam de Boor: May  4, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/ 4/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for the Tcl debugger
 *
 *
* 	$Id: tclDebug.h,v 4.1 96/05/20 18:53:55 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _TCLDEBUG_H_
#define _TCLDEBUG_H_

/*
 * The reasons for entering the debugger. For TD_ERROR, TD_EXIT and TD_OTHER,
 * interp->result is passed to the debugger.
 */
typedef enum {
    TD_ENTER,	    /* Entering debugged function */
    TD_EXIT,	    /* Exiting debugged function */
    TD_ERROR,	    /* Error and debugOnError is non-zero */
    TD_QUIT,	    /* Quit typed and debugOnQuit is non-zero */
    TD_OTHER,	    /* Stopping for some other reason */
    TD_RESET,	    /* Reset underway */
    TD_TOPLEVEL,    /* Made it back to top level */
}	TclDebugCode;

extern void Tcl_Debug (TclDebugCode  why);
extern void TclDebug_Init(void);

#endif /* _TCLDEBUG_H_ */
