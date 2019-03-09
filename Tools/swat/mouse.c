/********************************************************************
*								     
*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     
*								     
* 	PROJECT:	PC GEOS					     
* 	MODULE:							     
* 	FILE:		mouse.c				     
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
*		mouse support for PC swat 
*	$Id: mouse.c,v 1.10 96/06/13 17:18:20 dbaumann Exp $							     
*							   	     
*********************************************************************/

#if defined(_MSDOS)

#include <config.h>
#include "swat.h"
#include "buf.h"
#include "cmd.h"
#include "rpc.h"
#include "ui.h"
#include "event.h"

#include <stdarg.h>
#include <ctype.h>
#include <signal.h>

#include "mouse.h"

static int mouseWatchCount = 0;

extern int mouseFD; 	/* -1 if no MouseDriver, else 2 */
extern char wrongNumArgsString[];
extern DosWordSelectScreenRegion(short click, short *start, short *end);

/*-
 *-----------------------------------------------------------------------
 *	MouseHandleMouseEvent --
 *	Handle incoming mouse event 
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	If it is a call, the appropriate server function is called. If
 *	it is a reply, the replied, remote and status fields of the
 *	RpcCall structure for the call are altered and the RpcCall
 *	structure removed from the list of calls for the socket.
 *
 *-----------------------------------------------------------------------
 */


void static
MouseHandleMouseEvent(int	    stream, /* Stream that's ready */
		      Rpc_Opaque    data,   /* Data we stored (UNUSED) */
		      int	    what)   /* What it's ready for (UNUSED) */
{
    BPress  bp;
    char    nme[15];
    char    execstring[30];

    if (mouseFD == -1)
    {
	return;
    }
    if (MouseGetNextEvent(&bp))
    {
	sprintf(nme, "{%04o %04o %03o}", bp.mouseX, bp.mouseY, bp.button);
	Tcl_SetVar(interp, "next_mouse_event", nme, 1);
	sprintf(execstring, "mouse-do-event %s", nme);
	Tcl_Eval(interp, execstring, 0, NULL);
    }
}

/***********************************************************************
 *				MouseGetMouseEvent
 ***********************************************************************
 * SYNOPSIS:	    get next mouse event, if any
 * CALLED BY:	    Tcl
 * RETURN:	    mouse event (x, y, and button status)
 * SIDE EFFECTS:    Maybe...
 *
 * STRATEGY:
 *	Turn on observation of stream 2.
 *	return next mouse event from queue if any
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(get-mouse-event,MouseGetMouseEvent, TCL_EXACT,NULL,swat_prog.input,
"Usage:\n\
    get-mouse-event\n\
\n\
Synopsis:\n\
    Gets the next mouse event\n\
\n\
See also:\n\
    top-level-read\n\
")
{
    /* open up the mouse stream */
    if (mouseFD == -1)
    {
	return TCL_OK;
    }
    Rpc_Wait();
    return TCL_OK;
}


/***********************************************************************
 *				MouseCallDriverCmd
 ***********************************************************************
 * SYNOPSIS:	    get next mouse event, if any
 * CALLED BY:	    Tcl
 * RETURN:	    mouse event (x, y, and button status)
 * SIDE EFFECTS:    Maybe...
 *
 * STRATEGY:
 *	Turn on observation of stream 2.
 *	return next mouse event from queue if any
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(mouse-call-driver, MouseCallDriver, TCL_EXACT,NULL,swat_prog.input,
"Usage:\n\
    get-call-driver <function number> [<arg1> [<arg2> [<arg3>]]]\n\
\n\
Synopsis:\n\
    calls a mouse driver function\n\
\n\
")
{
    int	arg1=0, arg2=0, arg3=0;

    if (mouseFD == -1)
    {
	Tcl_RetPrintf(interp, "No mouse driver present.");
	return TCL_OK;
    }

    switch (argc)
    {
	case 5: arg3 = atoi(argv[4]);
	case 4: arg2 = atoi(argv[3]);
	case 3: arg1 = atoi(argv[2]);
	case 2: break;
	case 1:
	default:
	    Tcl_RetPrintf(interp, wrongNumArgsString, argv[0]);
	    return TCL_ERROR;
    }

    
    MouseCallDriver(atoi(argv[1]), arg1, arg2, arg3);
    return TCL_OK;
}

/***********************************************************************
 *				MouseWordSelectCmd
 ***********************************************************************
 * SYNOPSIS:	    select a word
 * CALLED BY:	    Tcl
 * RETURN:	    nothing
 * SIDE EFFECTS:    Maybe...
 *
 * STRATEGY:
 *	Turn on observation of stream 2.
 *	return next mouse event from queue if any
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(mouse-word-select, MouseWordSelect, TCL_EXACT,NULL,swat_prog.input,
"Usage:\n\
    mouse-word-select <click>\n\
\n\
Synopsis:\n\
    do a word selection\n\
\n\
")
{
    short    start, end;

    if (argc != 2)
    {
	Tcl_RetPrintf(interp, wrongNumArgsString, argv[0]);
	return TCL_ERROR;
    }
    
    DosWordSelectScreenRegion(atoi(argv[1]), &start, &end);
    DosInvertScreenRegion(start, end);
    Mouse_SetMouseHighlight(start, end);
    return TCL_OK;
}

/*********************************************************************
 *			Mouse_SetMouseHighlight
 *********************************************************************
 * SYNOPSIS: 	    set the TLC variable mouse_highlight
 * CALLED BY:	    GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	3/29/93		Initial version			     
 * 
 *********************************************************************/
void
Mouse_SetMouseHighlight(int value1, int value2)
{
    char    buf[10];

    sprintf(buf, "%d %d", value1, value2);
    Tcl_SetVar(interp, "mouse_highlight", buf, TRUE);
}


/*********************************************************************
 *			Mouse_Watch
 *********************************************************************
 * SYNOPSIS: 	    	turn on mouse stream in RPC system and show moue
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	3/11/93		Initial version			     
 * 
 *********************************************************************/
void
Mouse_Watch(void)
{
    if (!mouseWatchCount++) {
	Rpc_Watch(2, RPC_READABLE, MouseHandleMouseEvent, (Rpc_Opaque)NULL);
	MouseShowCursor();
    }
}


/*********************************************************************
 *			Mouse_Ignore
 *********************************************************************
 * SYNOPSIS: 	    turn of PRC mouse stream
 * CALLED BY:	    GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	3/11/93		Initial version			     
 * 
 *********************************************************************/
void
Mouse_Ignore(void)
{
    if (!--mouseWatchCount) {
	MouseHideCursor();
	Rpc_Ignore(2);
    }
}


/***********************************************************************
 *				MouseReset
 ***********************************************************************
 * SYNOPSIS:	    Cope with return to top-level
 * CALLED BY:	    EVENT_RESET
 * RETURN:	    EVENT_HANDLED
 * SIDE EFFECTS:    mouse is ignored, mouseWatchCount set to 0
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/23/95	Initial Revision
 *
 ***********************************************************************/
static int
MouseReset(Event event, Opaque calldata, Opaque clientData)
{
    if (mouseWatchCount) {
	MouseHideCursor();
    }
    mouseWatchCount = 0;
    Rpc_Ignore(2);
    return(EVENT_HANDLED);
}

/*********************************************************************
 *			Mouse_Init
 *********************************************************************
 * SYNOPSIS: 	    initialize mouse stuff
 * CALLED BY:	    main
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	2/ 3/93		Initial version			     
 * 
 *********************************************************************/
void Mouse_Init(void)
{
    	Cmd_Create(&MouseGetMouseEventCmdRec);
	Cmd_Create(&MouseCallDriverCmdRec);
	Cmd_Create(&MouseWordSelectCmdRec);

	Event_Handle(EVENT_RESET, 0, MouseReset, NullOpaque);

	Tcl_Eval(interp, "load mouse", 0, NULL);
}


/*********************************************************************
 *			MouseHideCursor
 *********************************************************************
 * SYNOPSIS: 	    	hide the cursor
 * CALLED BY:	    	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	3/19/93		Initial version			     
 * 
 *********************************************************************/
void Mouse_HideCursor(void)
{
    if (mouseFD != -1)
    {
	MouseCallDriver(MOUSEHIDE);
    }
}

/*********************************************************************
 *			MouseShowCursor
 *********************************************************************
 * SYNOPSIS: 	    	show the cursor
 * CALLED BY:	    	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	3/19/93		Initial version			     
 * 
 *********************************************************************/
void Mouse_ShowCursor(void)
{
    if (mouseFD != -1)
    {
	MouseCallDriver(MOUSESHOW);
    }
}

#endif

