/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Garbage Collection
 * FILE:	  gc.c
 *
 * AUTHOR:  	  Adam de Boor: Mar 21, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	gc  	    	    Garbage collect
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/21/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	A simple garbage collector. Located in a separate file to avoid
 *	polluting other files with things that should be kept hidden.
 *	Unfortunately, this thing has to examine many structures other
 *	things shouldn't see, hence...
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: gc.c,v 4.7 97/04/18 15:26:32 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "cmd.h"
#include "event.h"
#include "rpc.h"
#include "sym.h"
#include "type.h"
extern int  Type_Mark(Type);
#include "vector.h"
#include "gc.h"
#include <stddef.h>

extern Lst  dead;   	/* Dead patients whose symbols are still valid */
extern int  patientsChucked;
static Vector  sysTypes;    /* System types that need to be preserved always */

#define uint fooint
#define free foofree
#include "mallint.h"
#undef free
#undef uint

#if defined(unix)
#include <sys/resource.h>
#endif

static Dblk	prev, cur;
static int	psize, csize;

/*
 * Garbage-collect 5 minutes after detaching if haven't attached again.
 */
#define GC_TIME 	300
static Rpc_Event    gcEvent = (Rpc_Event)NULL;
static Boolean 	    initialized=FALSE;
static Boolean	    noAutoCollect = FALSE;

/***********************************************************************
 *				GC
 ***********************************************************************
 * SYNOPSIS:	    Perform garbage collection
 * CALLED BY:	    GCCmd, GCTimer
 * RETURN:	    TCL_OK if ok, TCL_ERROR if not
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/30/89		Initial Revision
 *
 ***********************************************************************/
static int
GC(char	    **msgPtr,	    	/* Value to return for "gc" command */
   Boolean  feedback,	    	/* TRUE to provide feedback during collection */
   Boolean  *somethingFreed)	/* If non-NULL, set to TRUE if anything freed
				 * up */
{
#if defined(unix)
    struct timeval  start, end;	    	/* Starting and ending times */
    struct rusage   startusage,	    	/* Starting usage */
		    endusage;	    	/* Ending usage (for getting user
					 * and system times) */
#endif
    register int    size;   	    	/* Sise of current block */
    register Dblk   p;	    	    	/* Current block */
    int	    	    freeblks,	    	/* Number of free blocks */
		    busyblks,	    	/* Number of in-use blocks */
		    freesize,	    	/* Bytes in free blocks */
		    busysize;	    	/* Bytes in in-use blocks */
    int	    	    recblks,	    	/* Recovered blocks */
		    recsize;	    	/* Bytes in recovered blocks */

    if (_lbound == NULL) {	/* no allocation yet */
	if (somethingFreed != NULL) {
	    *somethingFreed = FALSE;
	}
	*msgPtr = "_lbound == NULL?!";
	return(TCL_ERROR);
    }

#if defined(unix)
    gettimeofday(&start, NULL);
    getrusage(RUSAGE_SELF, &startusage);
#endif

    /*
     * Mark all registered system types
     */
    if (Vector_Length(sysTypes) != 0) {
	Type	    *tp = (Type *)Vector_Data(sysTypes);
	int 	    i = Vector_Length(sysTypes);

	while (i > 0) {
	    Type_Mark(*tp++);
	    i--;
	}
    }

    /*
     * Initialize statistics
     */
    recblks = recsize = freeblks = busyblks = freesize = busysize = 0;
    p = (Dblk)_lbound;
    cur = NULL; csize = 0;
    while (p < (Dblk) _ubound) {
	size = p->size;

	assert(size != 0);

	/*
	 * For debugging...
	 */
	prev = cur; psize = csize;
	cur = p; csize = size;

	if (p->tag == 0xff) {
	    freeblks++; freesize += size;
	} else {
	    switch(p->tag) {
		case TAG_TYPE:
		{
		    /*
		     * Unmarked type -- unreachable, so nuke it.
		     */
		    int	num, tsize;
		    
		    Type_Nuke((Opaque)p->data, &tsize, &num);
		    recblks += num+1; recsize += size+tsize;
		    free(p->data);
		    /*
		     * If block was combined, find the start of the
		     * combined block by looking for the first non-0xcc
		     * byte, which should be the tag of the previous block.
		     */
		    if (p->tag == 0xcc) {
			unsigned char *q = (unsigned char *)p;
			while (*q == 0xcc) {
			    q--;
			}
			q -= offsetof(struct dblk, data)-1;
			p = (Dblk)q;
		    }
		    break;
		}
		case TAG_HASHT|0x80:
		case TAG_TYPE|0x80:
		    /*
		     * Marked type, symbol, or symbol hash-table entry -- reset
		     * its tag so it's valid again.
		     */
		    p->tag &= 0x7f;
		    /*FALLTHRU*/
		default:
		    busyblks++; busysize += size;
		    break;
	    }
	}
	/*
	 * Get to the next real block. Note that if p is coalesced with the
	 * block before it, this should still work, though it will give
	 * an invalid number of free blocks. If coalesced with the block
	 * after it, this will miss the size of the next one, but give the
	 * correct block count...
	 */
	p = nextblk(p, p->size);
    }
#if defined(unix)
    /*
     * Fetch ending times
     */
    getrusage(RUSAGE_SELF, &endusage);
    gettimeofday(&end, 0);
    
    /*
     * Figure the amount of real and virtual time used...
     */
#define timesub(dest,src) dest.tv_usec -= src.tv_usec; if (dest.tv_usec < 0) { dest.tv_sec -= 1; dest.tv_usec += 1000000; } dest.tv_sec -= src.tv_sec

    timesub(end, start);
    timesub(endusage.ru_utime,startusage.ru_utime);
    timesub(endusage.ru_stime,startusage.ru_stime);
    
    if (feedback) {
	Message("   User      System     Elapsed\n");
	Message("%2d.%06d  %2d.%06d  %2d.%06d\n\n",
		endusage.ru_utime.tv_sec, endusage.ru_utime.tv_usec,
		endusage.ru_stime.tv_sec, endusage.ru_stime.tv_usec,
		end.tv_sec, end.tv_usec);
    }
#endif

    if (feedback) {
	Message("             bytes  blocks\n");
	Message("free       %7d   %5d\n", freesize, freeblks);
	Message("in-use     %7d   %5d\n", busysize, busyblks);
	Message("recovered  %7d   %5d\n", recsize, recblks);
	Message("\n%d in old arena, ", __mallinfo.arena);
	Message("%d after shrinking\n", shrinkheap());
    }

    *msgPtr = NULL;
    patientsChucked = 0;
    if (somethingFreed != NULL) {
	*somethingFreed = (recblks != 0);
    }
    return(TCL_OK);
}

/***********************************************************************
 *				GCCmd
 ***********************************************************************
 * SYNOPSIS:	    Perform garbage collection on symbols and types
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    Memory be freed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/21/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(gc,GC,TCL_EXACT,NULL,support,
"Implements a simple garbage collector to scavenge unreferenced symbols and\n\
types. If given an argument, turns on extensive heap checking, which\n\
slows things down enormously, but does ensure the heap is in good shape.")
{
    char    *msg;
    int	    val;
    int	    d_l=0;    	    	/* Initial debug level */


    if (argc != 1) {
	if (strcmp(argv[1], "off") == 0) {
	    noAutoCollect = TRUE;
	    if (gcEvent != (Rpc_Event)NULL) {
		Rpc_EventDelete(gcEvent);
		gcEvent = NULL;
	    }
	    return (TCL_OK);
	} else if (strcmp(argv[1], "register") == 0) {
	    int	    i;

	    for (i = 2; i < argc; i++) {
		GC_RegisterType(Type_ToToken(argv[i]));
	    }
	    return(TCL_OK);
	}
	d_l = malloc_debug(2);
    }
    
    if (gcEvent != NULL) {
	/*
	 * User is garbage collecting of his/her own volition -- disable the
	 * automatic collection.
	 */
	Rpc_EventDelete(gcEvent);
	gcEvent = (Rpc_Event)NULL;
    }

#ifdef MEM_TRACE
    MessageFlush("Verifying heap consistency...");
    malloc_verify();
    MessageFlush("done\n");
#endif /* MEM_TRACE */

    val = GC(&msg, TRUE, (Boolean *)NULL);
    
    Tcl_Return(interp, msg, TCL_STATIC);

    /*
     * Reset debug level
     */
    if (argc != 1) {
	malloc_debug(d_l);
    }

    return(val);
}


/***********************************************************************
 *				GCTimer
 ***********************************************************************
 * SYNOPSIS:	    Perform garbage collection a certain time after
 *	    	    detaching from the patient if we haven't attached
 *	    	    again.
 * CALLED BY:	    Rpc event
 * RETURN:	    FALSE (no need to stay awake)
 * SIDE EFFECTS:    gcEvent is deleted and NULLed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/30/89		Initial Revision
 *
 ***********************************************************************/
static Boolean
GCTimer(Rpc_Opaque  	clientData,
	Rpc_Event   	event)
{
    char    	*msg;
    
    Rpc_EventDelete(event);
    gcEvent = (Rpc_Event)NULL;

    MessageFlush("\nGarbage collecting...\n");

    /*
     * Make sure the heap is consistent before we try this...
     */
#ifdef MEM_TRACE
    MessageFlush("Verifying heap consistency...");
    malloc_verify();
    MessageFlush("done\n");
#endif /* MEM_TRACE */

/*	malloc_debug(2);*/
    (void)GC(&msg, TRUE, (Boolean *)NULL);
/*	malloc_debug(1);*/

    MessageFlush("We now return you to your regular program\n");

    return(FALSE);
}


/***********************************************************************
 *				GCDetach
 ***********************************************************************
 * SYNOPSIS:	    Start the collection timer going
 * CALLED BY:	    EVENT_DETACH
 * RETURN:	    EVENT_HANDLED
 * SIDE EFFECTS:    gcEvent is created to invoke collection.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/30/89		Initial Revision
 *
 ***********************************************************************/
static int
GCDetach(Event	event,
	 Opaque	callData,
	 Opaque	clientData)
{
    struct timeval  gcTime;

    if (!noAutoCollect && gcEvent == NULL) {
	gcTime.tv_sec = GC_TIME;
	gcTime.tv_usec = 0;
	gcEvent = Rpc_EventCreate(&gcTime, GCTimer, NullOpaque);
    }
    
    return(EVENT_HANDLED);
}

/***********************************************************************
 *				GCAttach
 ***********************************************************************
 * SYNOPSIS:	    Turn off the collection timer
 * CALLED BY:	    EVENT_ATTACH
 * RETURN:	    EVENT_HANDLED
 * SIDE EFFECTS:    gcEvent is deleted and NULLed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/30/89		Initial Revision
 *
 ***********************************************************************/
static int
GCAttach(Event	event,
	 Opaque	callData,
	 Opaque	clientData)
{
    if (gcEvent) {
	Rpc_EventDelete(gcEvent);
	gcEvent = (Rpc_Event)NULL;
    }
    return(EVENT_HANDLED);
}

/***********************************************************************
 *				GC_RegisterType
 ***********************************************************************
 * SYNOPSIS:	    Register a system type that's not to be nuked
 * CALLED BY:	    Ibm_Init, Break_Init, Handle_Init
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The Type is added to the sysTypeslist.
 *
 * STRATEGY:	    There is no need for a count of the people who want
 *	    	    this type preserved, as we just slap the thing onto
 *	    	    the end of the vector each time, and UnregisterType
 *	    	    just biffs one match...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/23/89		Initial Revision
 *
 ***********************************************************************/
void
GC_RegisterType(Type	type)
{
    /*
     * Deal with the registering of our two event handlers, since GC_Init
     * is called before the event module is initialized. We know the
     * event module has been initialized by the time this function
     * is called, however.
     */
    if (!initialized) {
	Event_Handle(EVENT_ATTACH, 0, GCAttach, NullOpaque);
	Event_Handle(EVENT_DETACH, 0, GCDetach, NullOpaque);
	initialized = TRUE;
    }
    
    Vector_Add(sysTypes, VECTOR_END, &type);
}

/***********************************************************************
 *				GC_UnregisterType
 ***********************************************************************
 * SYNOPSIS:	    Stop protecting a type from garbage collection
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The type is removed from sysTypes
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/19/89	Initial Revision
 *
 ***********************************************************************/
void
GC_UnregisterType(Type	type)
{
    int	    i = Vector_Length(sysTypes);
    Type    *tp = (Type *)Vector_Data(sysTypes);
    
    while (i > 0) {
	if (bcmp((genptr)&type, (genptr)tp, sizeof(type)) == 0) {
	    *tp = NullType;
	    break;
	} else {
	    tp++, i--;
	}
    }
}

/***********************************************************************
 *				GC_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize the garbage collector
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    sysTypes is initialized and GCCmd entered.
 *
 * STRATEGY:	    None, really.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/23/89		Initial Revision
 *
 ***********************************************************************/
void
GC_Init(void)
{
    sysTypes = Vector_Create(sizeof(Type), ADJUST_ADD, 10, 10);
    Cmd_Create(&GCCmdRec);
}


/***********************************************************************
 *				malloc_err
 ***********************************************************************
 * SYNOPSIS:	    Error handler for running out of memory, etc.
 * CALLED BY:	    malloc()
 * RETURN:	    that depends
 * SIDE EFFECTS:    might garbage collect.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/26/93		Initial Revision
 *
 ***********************************************************************/
void
malloc_err(Boolean isFatal,
	   const char *msg)
{
    if (isFatal) {
	/*
	 * Out of memory. Try garbage-collecting to recover some.
	 */
	char	*junk;
	Boolean	somethingFreed;

	if ((GC(&junk, FALSE, &somethingFreed) == TCL_OK) &&
	    somethingFreed)
	{
	    /*
	     * There's a chance...
	     */
	    return;
	}
	/* XXX: truncate scroll buffer? get rid of VM blocks? */
    }
    Punt(msg);
}
