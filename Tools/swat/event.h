/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Header File for Event module
 * FILE:	  event.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Constant, function and type declarations for the Event module
 *
 *
 * 	$Id: event.h,v 4.4 97/04/18 15:12:33 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _EVENT_H
#define _EVENT_H

typedef int EventHandler(Event event, Opaque callData, Opaque clientData);

extern void 	Event_Init (void);
extern Event 	Event_Handle (int eventNum, short flags,
			      EventHandler *func,
			      Opaque clientData);
extern void 	Event_Delete (Event event);
extern int  	Event_Dispatch (int eventNum, Opaque callData);
extern int  	Event_GetNewType (void);
extern int  	Event_Number(Event event);

/*
 * Handler return codes (also returned by Event_Dispatch)
 */
#define EVENT_STOP_HANDLING 0
#define EVENT_HANDLED	    1
#define EVENT_NOT_HANDLED   2

/*
 * Flags for handlers.
 */
#define EVENT_MBL   	1	    /* Must be last handler on the chain */

/*
 * Predefined event types
 */
#define EVENT_STOP	0	    /* Patient has stopped.
				     * callData = current frame */
#define EVENT_STEP	1   	    /* Single-step completed.
				     * callData = current frame */
#define EVENT_FULLSTOP	2	    /* Patient will remain stopped.
				     * callData = reason for stop (string) */

#define EVENT_CHANGE	3   	    /* Our idea of the current patient has
				     * changed. callData is old patient */

#define EVENT_EXIT	4	    /* Patient has exited. callData is dead
				     * patient. */

#define EVENT_CONTINUE	7   	    /* Patient being continued
				     * callData = CONTINUE_* constant */
#define CONTINUE_FULL	((Opaque)0)   	/* Full stop to free-run */
#define CONTINUE_STEP	((Opaque)1)   	/* Full stop to single-step */
#define CONTINUE_HALF	((Opaque)2)   	/* Half stop (e.g. RPC) to free-run */
#define CONTINUE_DETACH	((Opaque)3) 	/* Full stop to detach */

#define EVENT_STACK	8   	    /* The current stack frame has changed. */
#define EVENT_TRACE	9   	    /* The execution of a source line has
				     * completed and we're tracing. callData is
				     * the current pc */
#define EVENT_START	10  	    /* Application/thread started */
#define EVENT_DETACH	11  	    /* Detaching */
#define EVENT_ATTACH	12  	    /* Newly attached */
#define EVENT_RESET 	13  	    /* Returned to top level */
#define EVENT_DESTROY	14  	    /* Patient being destroyed.
				     * callData = patient going away */
#define EVENT_RELOAD	15  	    /* Kernel was reloaded */
#define EVENT_INT   	16  	    /* Some caught interrupt other than a
				     * breakpoint has been taken. callData is
				     * the interrupt number. */
#define EVENT_LAST	16   	    /* Last predefined event number */

#endif /* _EVENT_H */
