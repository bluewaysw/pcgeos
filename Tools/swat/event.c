/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Event dispatching
 * FILE:	  event.c
 *
 * AUTHOR:  	  Adam de Boor: Sep 26, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Event_Dispatch	    Send an event to all interested procedures
 *	Event_Handle	    Register interest in an event
 *	Event_Delete	    Unregister interest in an event
 *	Event_Init  	    Initialize the module
 *	Event_Number	    Return event number of a registered handler
 *	Event_GetNewType    Get a new number for internal use (e.g. by a
 *	    	    	    small set of routines)
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/26/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	This file implements the internal event dispatching that drives
 *	most of Swat.
 *
 * 	Event handlers are stored in EventRec structures that are linked
 *	together in a list, whose head is kept in an array in our private
 *	data. The array is indexed by event number.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: event.c,v 4.13 97/04/18 15:10:58 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "cmd.h"
#include "event.h"
#include "private.h"
#include "sym.h"
#include "expr.h"

#include <compat/stdlib.h>
#include <ctype.h>

/*
 * Data to describe an event.
 */
typedef struct _Event {
    EventHandler    *func;	    /* Function to call */
    Opaque	    clientData;	    /* Data to pass it */
    short	    eventNum; 	    /* Event number being handled by func */
    short   	    flags;  	    /* Flags for handler */
    struct _Event   *next;    	    /* Next handler for this eventNum */
} EventRec, *EventPtr;

typedef struct _EventList {
    EventPtr	  first;    	    /* Head of queue */
    EventPtr	  last;	    	    /* Tail of queue */
} EventListRec, *EventListPtr;

/*
 * Private data for us.
 */
static EventListRec  	*handlers;  /* Array of handlers for events */
static int		last;	    /* Last event number defined */
static int	    	eventCount; /* Counter for Event_Cmd */
static Lst	  	tclEvents;  /* Events registered by Event_Cmd */
static int  	    	eventDbg=0; /* Non-zero to debug events */

/*
 * Tcl-level event
 */
typedef struct {
    Event   	  event;    	/* Actual Event */
    char	  *proc;    	/* Procedure to invoke */
    char	  *data;    	/* Client data to procedure */
    int		  id;	    	/* Event id number */
} TclEventRec, *TclEventPtr;

#define MAX_EVENT_ARG_SIZE  128	/* Greatest amount of space required by a
				 * TCL callData arg */

static const struct {
    char    	*name;
    char    	*argFmt;
    int	    	num;
}	tclExposed[] = {
    {"FULLSTOP","%.127s", EVENT_FULLSTOP},
    {"CONTINUE","%d",	EVENT_CONTINUE},
    {"START",	"%d",	EVENT_START},
    {"EXIT",	"%d",	EVENT_EXIT},
    {"STACK",	"%d",	EVENT_STACK},
    {"TRACE",	"%d",	EVENT_TRACE},	/* NOT RIGHT */
    {"DETACH",	"0x0",  EVENT_DETACH},
    {"RESET",	"0x0",	EVENT_RESET},
    {"ATTACH",	"0x0",	EVENT_ATTACH},
    {"RELOAD",	"0x0", 	EVENT_RELOAD},
    {"CHANGE",	"%d",	EVENT_CHANGE},
    {"STEP", 	"%d", 	EVENT_STEP},
    {"STOP", 	"%d",	EVENT_STOP},
    {"INT",  	"%d", 	EVENT_INT}
};

/***********************************************************************
 *				EventTclFind
 ***********************************************************************
 * SYNOPSIS:	    See if given event has desired ID
 * CALLED BY:	    INTERNAL via Lst_Find
 * RETURN:	    0 if id's match
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 3/88	Initial Revision
 *
 ***********************************************************************/
static int
EventTclFind(TclEventPtr    eventPtr,
	     int    	    id)
{
    return(eventPtr->id - id);
}
/*-
 *-----------------------------------------------------------------------
 * EventTclPrint --
 *	Print the event to the patient's main window.
 *
 * Results:
 *	=== 0
 *
 * Side Effects:
 *	The event is printed.
 *
 *-----------------------------------------------------------------------
 */
static int
EventTclPrint(TclEventPtr   tclEvent)
{
    char    	  	*eventName=NULL;
    char    	  	buf[20];
    int	    	    	i;
    int	    	    	num;

    num = Event_Number(tclEvent->event);
    
    for (i = Number(tclExposed)-1; i >= 0; i--) {
	if (tclExposed[i].num == num) {
	    eventName = tclExposed[i].name;
	    break;
	}
    }
    if (i < 0) {
	sprintf(buf, "#%d", num);
	eventName = buf;
    }

    if (tclEvent->data) {
	Message("[event%d] %-10s: [%s <arg> %s]\n", tclEvent->id, eventName,
		tclEvent->proc, tclEvent->data);
    } else {
	Message("[event%d] %-10s: [%s <arg>]\n",
		tclEvent->id, eventName, tclEvent->proc);
    }
    return(0);
}

/*-
 *-----------------------------------------------------------------------
 * EventTclCatch --
 *	Catch an event for a Tcl procedure.
 *
 * Results:
 *	Whatever the procedure returns.
 *
 * Side Effects:
 *	The procedure is called.
 *
 *-----------------------------------------------------------------------
 */
static int
EventTclCatch(Event	    event,
	      Opaque	    callData,
	      Opaque	    clientData)
{
    char    	    	*args[3];
    char    	    	argData[MAX_EVENT_ARG_SIZE];
    char    	  	*command;
    int			result;
    int	    	    	num, i;
    char    	    	*argFmt = "%.128s"; /* Default format */
    TclEventPtr     	tclEvent = (TclEventPtr)clientData;

    num = Event_Number(event);
    for (i = Number(tclExposed)-1; i >= 0; i--) {
	if (num == tclExposed[i].num) {
	    argFmt = tclExposed[i].argFmt;
	    break;
	}
    }

    sprintf(argData, argFmt, callData);
    
    i = 2;
    args[0] = tclEvent->proc;
    args[1] = argData;
    if (tclEvent->data) {
	args[2] = tclEvent->data;
	i++;
    }

    command = Tcl_Merge(i, args);

    if (Tcl_Eval(interp, command, 0, (const char **)NULL) != TCL_OK) {
	Warning("%s: %s", tclEvent->proc, interp->result);
	result = EVENT_NOT_HANDLED;
    } else if (strcmp(interp->result, "EVENT_HANDLED") == 0) {
	result = EVENT_HANDLED;
    } else if (strcmp(interp->result, "EVENT_STOP_HANDLING") == 0){
	result = EVENT_STOP_HANDLING;
    } else if (strcmp(interp->result, "EVENT_NOT_HANDLED") == 0) {
	result = EVENT_NOT_HANDLED;
    } else {
	result = EVENT_HANDLED;
    }

    free(command);

    Tcl_Return(interp, NULL, TCL_STATIC);
    return(result);
}

/*-
 *-----------------------------------------------------------------------
 * Event_Cmd --
 *	Tcl-level access to this module.
 *
 * Results:
 *	TCL_OK if arguments ok. TCL_ERROR if not.
 *
 * Side Effects:
 *	An event handler is registered or deleted.
 *
 *-----------------------------------------------------------------------
 */
#define EVENT_HANDLE	(ClientData)0
#define EVENT_DELETE	(ClientData)1
#define EVENT_CREATE	(ClientData)2
#define EVENT_LIST  	(ClientData)3
#define EVENT_DISPATCH	(ClientData)4
#define EVENT_DEBUG 	(ClientData)5

static const CmdSubRec eventCmds[] = {
    {"handle", EVENT_HANDLE, 2, CMD_NOCHECK, "<eventName> <handler> [<data>]"},
    {"delete",	EVENT_DELETE,	1, 1, "<event>"},
    {"dispatch",	EVENT_DISPATCH,	2, 2, "<eventName> <arg>"},
    {"create",	EVENT_CREATE,	0, 0, ""},
    {"list", 	EVENT_LIST, 	0, 0, ""},
    {"debug", 	EVENT_DEBUG,	1, 1, "<n>"},
    {NULL,   	(ClientData)NULL,	    	0, 0, NULL}
};

DEFCMD(event,Event,TCL_EXACT,eventCmds,swat_prog.event,
"Much of swat's function is driven by events that it dispatches internally\n\
from various places. As some of these events signal happenings that could\n\
be of interest to a swat programmer, they are made available via this\n\
command. Options for this command are:\n\
    handle <eventName> <handler> [<data>]\n\
 	    The <handler> procedure is invoked each time an event of type\n\
	    <eventName> is dispatched. The handler receives two arguments:\n\
	    an event-specific piece of data, and the <data> given in this\n\
	    command. A handler procedure should be declared:\n\
	    	  proc <handler> {arg data} {<body>}\n\
	    Returns an <event-name> for later use in deleting it.\n\
	    The <handler> should return one of \"EVENT_HANDLED\",\n\
	    \"EVENT_NOT_HANDLED\" or \"EVENT_STOP_HANDLING\". If it\n\
	    returns \"EVENT_STOP_HANDLING\", the event will not be\n\
	    dispatched to any other handlers of that event.\n\
    delete <event>\n\
	    Deletes the event handler with the given name, as returned by\n\
	    an \"event handle\" command.\n\
    dispatch <eventName> <arg>\n\
	    Dispatches an the given event with the piece of data to all\n\
	    handlers of that event. If <eventName> is a pre-defined event\n\
	    type, <arg> will be converted to the appropriate type before\n\
	    being dispatched, else it is passed as a string.\n\
    create\n\
    	    Returns a number that represents a new event type. Handlers may\n\
	    then be defined for and events dispatched of the new type.\n\
    list\n\
    	    Lists all tcl-registered events by their event-names and the\n\
	    handler function\n\
\n\
Events currently defined are:\n\
    FULLSTOP	Generated when patient stops for a while. Argument is\n\
		string telling why the patient stopped.\n\
    CONTINUE	Generated just before the patient is continued. The\n\
		argument is non-zero if going to single-step.\n\
    TRACE   	Generated when the execution of a source line completes\n\
    	    	and the patient is in line-trace mode.\n\
    START	Generated when a new patient/thread is created. Argument\n\
		is patient token of patient involved.\n\
    EXIT	Generated when a patient exits. Argument is patient token of\n\
		patient involved.\n\
    STACK	Current stack frame has changed. The argument is non-zero\n\
		if the stack change comes from a change in patients/threads\n\
		or zero if the change comes from actually going up or down\n\
		the stack in the current patient.\n\
    DETACH	Detaching from the PC. arg is always 0x0.\n\
    RESET   	Returning to top level. arg is always 0x0.\n\
    ATTACH  	Attached to the PC. arg is always 0x0.\n\
    RELOAD	Kernel was reloaded. Arg is always 0x0\n\
    CHANGE	Current patient has changed. Argument is the token for the\n\
		previous patient.\n\
    STEP    	Machine has stepped a single instruction. Arg is value to\n\
		pass to \"patient stop\" if you wish the machine to stay\n\
		stopped.\n\
    STOP    	Machine has hit a breakpoint. Arg is value to pass to \n\
		\"patient stop\" if you wish the machine to stay stopped.\n\
    INT	    	Machine has hit some other interrupt that's being caught.\n\
		Arg is the interrupt number. The machine will remain stopped\n\
		unless it is continued with \"continue-patient\".")
{
    int	    	  	eventNum=0;
    TclEventPtr	  	tclEvent;

    switch ((int)clientData) {
	case EVENT_HANDLE:
	{
	    /*
	     * event handle <event> <handler-proc> [<data>...]
	     *
	     * Sets handler-proc to be called when the given event arrives.
	     * All pieces of data are merged into a single list and passed
	     * as a single list. Returns an event token.
	     */
	    int 	i;
	    
	    for (i = Number(tclExposed) - 1; i >= 0; i--) {
		if (strcmp(argv[2], tclExposed[i].name) == 0) {
		    eventNum = tclExposed[i].num;
		    break;
		}
	    }
	    
	    /*
	     * Not a named event. Maybe numeric?
	     */
	    if (i < 0) {
		eventNum = atoi(argv[2]);
		if (eventNum <= 0 || eventNum > last) {
		    Tcl_RetPrintf(interp, "%s: unknown event type", argv[2]);
		    return(TCL_ERROR);
		}
	    }
	    
	    tclEvent = (TclEventPtr)malloc_tagged(sizeof(TclEventRec),
						  TAG_EVENT);
	    tclEvent->event = Event_Handle(eventNum, 0, EventTclCatch,
					   (Opaque)tclEvent);
	    tclEvent->proc = malloc_tagged(strlen(argv[3]) + 1, TAG_EVENT);
	    strcpy(tclEvent->proc, argv[3]);
	    if (argc == 5) {
		tclEvent->data = (char *)malloc(strlen(argv[4])+1);
		strcpy(tclEvent->data, argv[4]);
	    } else if (argc > 4) {
		tclEvent->data = Tcl_Merge(argc-4, argv+4);
	    } else {
		tclEvent->data = (char *)NULL;
	    }
	    (void)Lst_AtEnd(tclEvents, (LstClientData)tclEvent);
	    eventCount += 1;
	    tclEvent->id = eventCount;
	    Tcl_RetPrintf(interp, "event%d", tclEvent->id);
	    break;
	}
	case EVENT_DELETE:
	{
	    /*
	     * Delete a registered event. We just snag the event id number from
	     * the end of the arg, find the event with that number, and remove
	     * it from the list, freeing and deleting its associated data and
	     * events.
	     */
	    LstNode	  	ln;
	    int 	  	id;
	    
	    if (argv[2][0] == 'e') {
		sscanf(argv[2], "event%d", &id);
	    } else {
		id = atoi(argv[2]);
	    }
	    
	    ln = Lst_Find(tclEvents, (LstClientData)id, EventTclFind);
	    if (ln == NILLNODE) {
		Tcl_RetPrintf(interp, "%s: no such event registered", argv[2]);
		return(TCL_ERROR);
	    } else {
		tclEvent = (TclEventPtr)Lst_Datum(ln);
		
		Lst_Remove(tclEvents, ln);
		free(tclEvent->proc);
		if (tclEvent->data) {
		    free(tclEvent->data);
		}
		Event_Delete(tclEvent->event);
		
		free((char *)tclEvent);
	    }
	    break;
	}
	case EVENT_LIST:
	    /*
	     * List all active event handlers
	     */
	    Lst_ForEach(tclEvents, EventTclPrint, (LstClientData)NULL);
	    break;
	    
	case EVENT_CREATE:
	{
	    /*
	     * Create a new event type.
	     */
	    char	  buf[20];
	    int	  newType = Event_GetNewType();
	    
	    sprintf(buf, "%d", newType);
	    Tcl_Return(interp, buf, TCL_VOLATILE);
	    break;
	}
	case EVENT_DISPATCH:
	{
	    /*
	     * Dispatch an event, with data
	     */
	    Opaque	  	callData;
	    int		result;
	    int 	    	i;
	    
	    for (i = Number(tclExposed)-1; i >= 0; i--) {
		if (strcmp(argv[2], tclExposed[i].name) == 0) {
		    eventNum = tclExposed[i].num;
		    break;
		}
	    }
	    if (i < 0) {
		eventNum = atoi(argv[2]);
	    }
	    switch(eventNum) {
		case EVENT_FULLSTOP:
		    callData = (Opaque)argv[3];
		    break;
		case EVENT_CONTINUE:
		    if (strcmp(argv[3], "full") == 0) {
			callData = CONTINUE_FULL;
		    } else if (strcmp(argv[3], "step") == 0) {
			callData = CONTINUE_STEP;
		    } else if (strcmp(argv[3], "half") == 0) {
			callData = CONTINUE_HALF;
		    } else {
			callData = (Opaque)atoi(argv[3]);
		    }
		    break;
		case EVENT_TRACE:
		{
		    static GeosAddr	addr;
		    
		    Expr_Eval(argv[3], NullFrame, &addr, (Type *)NULL, TRUE);
		    callData = (Opaque)&addr;
		    break;
		}
		case EVENT_START:
		    callData = (Opaque)atoi(argv[3]);
		    if (!VALIDTPTR(callData, TAG_PATIENT)) {
			Tcl_RetPrintf(interp, "%s: invalid patient", argv[3]);
			return(TCL_ERROR);
		    }
		    break;
		case EVENT_STACK:
		    callData = (Opaque)atoi(argv[3]);
		    break;
		default:
		    if (eventNum < EVENT_LAST) {
			Tcl_Error(interp, "Not allowed to dispatch that one");
		    } else if (eventNum > last) {
			Tcl_Error(interp, "Event out of range");
		    } else {
			callData = (Opaque)argv[4];
		    }
		    break;
	    }
	    
	    result = Event_Dispatch(eventNum, callData);
	    
	    switch(result) {
		case EVENT_NOT_HANDLED:
		    Tcl_Return(interp, "EVENT_NOT_HANDLED", TCL_STATIC);
		    break;
		case EVENT_HANDLED:
		    Tcl_Return(interp, "EVENT_HANDLED", TCL_STATIC);
		    break;
	    }
	    break;
	}
	case EVENT_DEBUG:
	    eventDbg = atoi(argv[2]);
	    Tcl_RetPrintf(interp, "%d", eventDbg);
	    break;
    }
    return(TCL_OK);
}

/*-
 *-----------------------------------------------------------------------
 * Event_Init --
 *	Initialize event dispatching.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Probably.
 *
 *-----------------------------------------------------------------------
 */
void
Event_Init(void)
{
    tclEvents = Lst_Init(FALSE);
    eventCount = 0;
    last = EVENT_LAST;
    handlers =	(EventListRec *)calloc_tagged(EVENT_LAST+1,
					      sizeof(EventListRec),
					      TAG_EVENT);

    Cmd_Create(&EventCmdRec);
}

/*-
 *-----------------------------------------------------------------------
 * Event_Dispatch --
 *	Dispatch an event.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The handlers for the event number are called.
 *
 *-----------------------------------------------------------------------
 */
int
Event_Dispatch(int	eventNum,
	       Opaque	callData)
{
    register EventPtr  	ep;
    register EventPtr	nextEvent;
    int			result = EVENT_NOT_HANDLED;
    static const char	*names[] = {
	"EVENT_STOP",
	"EVENT_STEP",
	"EVENT_FULLSTOP",
	"EVENT_CHANGE",
	"EVENT_EXIT",
	"5", "6",
	"EVENT_CONTINUE",
	"EVENT_STACK",
	"EVENT_TRACE",
	"EVENT_START",
	"EVENT_DETACH",
	"EVENT_ATTACH",
	"EVENT_RESET",
	"EVENT_DESTROY",
	"EVENT_RELOAD",
	"EVENT_INT",
    };
	

    if (eventNum > last) {
	Warning("Event_Dispatch: event number %d out of range",
		eventNum);
    } else {
	if (eventDbg && eventNum < sizeof(names)/sizeof(names[0])) {
	    Message("Dispatching %s(%d [%xh])\n", names[eventNum],
		    callData, callData);
	}
	
	for (ep = handlers[eventNum].first;
	     ep != (EventPtr)NULL;
	     ep = nextEvent)
	{
	    nextEvent = ep->next;
	    switch ((* ep->func) ((Event)ep, callData, ep->clientData))
	    {
		case EVENT_STOP_HANDLING:
		    nextEvent = (EventPtr)NULL;
		case EVENT_HANDLED:
		    result = EVENT_HANDLED;
		    break;
	    }
	}
    }

    return(result);
}

/*-
 *-----------------------------------------------------------------------
 * Event_Handle --
 *	Create a handler for the given event number.
 *
 * Results:
 *	An Event token for later use.
 *
 * Side Effects:
 *	An EventRec is added to the list of handlers.
 *
 *-----------------------------------------------------------------------
 */
Event
Event_Handle(int	    eventNum,
	     short  	    flags,
	     EventHandler   *func,
	     Opaque	    clientData)
{
    EventPtr		ep;

    ep = (EventPtr)malloc_tagged(sizeof(EventRec), TAG_EVENT);

    ep->func = func;
    ep->flags = flags;
    ep->clientData = clientData;
    ep->eventNum = eventNum;
    ep->next = (EventPtr)NULL;

    if (handlers[eventNum].first == (EventPtr)NULL) {
	handlers[eventNum].last = handlers[eventNum].first = ep;
    } else {
	if (handlers[eventNum].last->flags & EVENT_MBL) {
	    /*
	     * If the current tail handler insists on being last, link this
	     * thing in before it. We test the MBL flag rather than looking
	     * for the last thing on the list to allow several MBL things (even
	     * if they can't all be the very last one, at least they can
	     * come close :)
	     */
	    EventPtr	tep;

	    tep = handlers[eventNum].first;
	    while (tep->next != NULL && (tep->next->flags & EVENT_MBL) == 0) {
		tep = tep->next;
	    }

	    if (tep == handlers[eventNum].first) {
		/*
		 * None w/o the MBL flag -- link it as the first entry
		 */
		ep->next = tep;
		handlers[eventNum].first = ep;
	    } else {
		ep->next = tep->next;
		tep->next = ep;
	    }
	} else {
	    /*
	     * Just tack the thing on to the end
	     */
	    handlers[eventNum].last->next = ep;
	    handlers[eventNum].last = ep;
	}
    }

    return ((Event)ep);
}

/*-
 *-----------------------------------------------------------------------
 * Event_Delete --
 *	Remove an event handler.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The EventRec is removed from the list and freed.
 *
 *-----------------------------------------------------------------------
 */
void
Event_Delete(Event  event)
{
    EventPtr		ep;	/* Event to delete */
    EventPtr	  	cur;	/* Current event in chain */
    EventPtr	  	prev;	/* Previous event (used instead of an
				 * EventPtr * as we need to alter the .last
				 * pointer when deleting the last one) */


    ep = (EventPtr)event;

    prev = NULL;

    for (cur = handlers[ep->eventNum].first;
	 cur != ep && cur != NULL;
	 cur = cur->next)
    {
	prev = cur;
    }

    if (cur != ep) {
	Warning("Event_Delete: event %xh doesn't exist", event);
    } else {
	/*
	 * Unlink from previous
	 */
	if (prev) {
	    prev->next = ep->next;
	} else {
	    handlers[ep->eventNum].first = ep->next;
	}
	/*
	 * Adjust last if it was...
	 */
	if (handlers[ep->eventNum].last == ep) {
	    handlers[ep->eventNum].last = prev;
	}
	free((char *)ep);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Event_Number --
 *	Return the event number for which the given Event is registered.
 *
 * Results:
 *	The event number.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
int
Event_Number(Event  event)
{
    return (((EventPtr)event)->eventNum);
}

/*-
 *-----------------------------------------------------------------------
 * Event_GetNewType --
 *	Return the next event number available.
 *
 * Results:
 *	The next event number for the patient.
 *
 * Side Effects:
 *	The handlers array is lengthened and last altered.
 *
 *-----------------------------------------------------------------------
 */
int
Event_GetNewType(void)
{
    int			newType;

    last += 1;
    newType = last;
    
    handlers =
	(EventListRec *)realloc_tagged((char *)handlers,
				       (unsigned)((last + 1) *
						  sizeof(EventListRec)));

    handlers[last].first = (EventPtr)NULL;

    return(newType);
}

