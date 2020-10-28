/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Patient-dependent interface.
 * FILE:	  ibm.c
 *
 * AUTHOR:  	  Adam de Boor: Jul 20, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Ibm_Init  	    Initializes this module, and calls other
 *	    	  	    functions to read the symbol table, etc.
 *
 *	Ibm_NewGeode	    Creates and initializes a new patient.
 *	Ibm_Continue	    Continues the machine
 *	Ibm_SingleStep 	    Single-steps the machine
 *	Ibm_Step    	    Execute a single instruction
 *	Ibm_Continue	    Continue patient according to sysStep, et al.
 *	Ibm_ReadRegister    Read a register from the current thread
 *	Ibm_WriteRegister   Write a register to the current thread
 *	Ibm_StackEnd	    Return the bottom of the stack for the current
 *	    	    	    thread.
 *	Ibm_StackHandle	    Return the handle of the block in which the
 *			    current thread's stack resides.
 *
 * REVISION HISTORY:
 *	Date	    Name	    Description
 *	----	    ----	    -----------
 *	7/20/88	    ardeb	    Initial version
 *	4/26/89	    ardeb   	    Broke out commands into separate module.
 *
 * DESCRIPTION:
 *	This file implements the access to PC GEOS from the host computer.
 *	Actual communication with the stub is implemented by the Rpc
 *	module.
 *
 *	One note on the patientPriv field of each patient. This thing
 *	is initialized to 0 by Ibm_NewGeode and is set to non-zero when
 *	the patient needs to be biffed by IbmFlushState.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: ibm.c,v 4.71 97/04/18 15:46:18 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "cache.h"
#include "cmd.h"
#include "event.h"
#include "file.h"
#include "ibm.h"
#include "ibmInt.h"
#include "private.h"
#include "sym.h"
#include "type.h"
#include "ui.h"
#include "var.h"
#include "gc.h"
#include "ibm86.h"
#include "ibmCmd.h"
#include "ibmCache.h"
#include "geos.h"

#include <objSwap.h>
#include <objfmt.h>
#include <hash.h>

#include <stddef.h>

#include <ctype.h>
#include <compat/stdlib.h>
#include <compat/file.h>
#include <errno.h>

#if defined(unix)
 #include <sys/signal.h>
 #include <sys/times.h>
#endif

#if defined(_MSDOS) || defined(_WIN32)
# include <io.h>
# include <dos.h>
# if defined(_WIN32)
#  include "serial.h"
# ifndef __WATCOMC__
#  include <dir.h>
# endif
# endif
#endif

/* I just need a value for this that is neither TRUE or FALSE */
#if 0
#define	LOADER_INIT_MODE TRUE+FALSE+1
#define KERNEL_INIT_MODE LOADER_INIT_MODE+1
#endif

VMHandle    	idfile;	    /* For printf library routine */
int	    	geosRelease;	/* For VM library routines */


static ThreadPtr    loaderThread;

#if defined(SETUP)
int	    	needSetup = 1;
#endif

word  	kernelInternalSymbols[NUMBER_OF_INTERNAL_SYMBOLS];
word	kcodeResID=0;
word	curXIPPage; 	/* current virtual mapped in page, this page may or
			 * may not actually be the currently mapped in page
			 * on the target, but its the page we want swat to
			 * think of as mapped in so Handle_Find can find
			 * handles to a page that isn't mapped in
			 */
word	realXIPPage; 	/* page actually mapped in on target */

extern char wrongNumArgsString[];
extern int  gymResources;
extern const char gym_ext[];

extern Cache	fileCache;
extern int rpcDebug;


void IbmSetCurXIPPage(word xipPage);

#define LOADER_THREAD_ID    ((word)(loader->numRes+1))

/*
 * This is the size of buffers for object files. Since the object file
 * is only consulted when a handle has been discarded (i.e. rarely) and even
 * then the amount of I/O for it is limited, there's no need to allocate
 * an entire filesystem block-sized buffer for it. This size is much
 * more reasonable for our purposes.
 */
#define IBM_BUFFER_SIZE	512

/*
 * Registers we provide.
 */
static const struct {
    char    	  *name;
    Reg_Data	  data;
}	    registers[] = {
    {"curThread",    {REG_OTHER,	(int)"curThread"}},
    {"xipPage",	    {REG_OTHER,	(int)"xipPage"}}
};

/*
 * Exported variables
 */
Patient	    	    curPatient;	/* Currently-active patient. */
int	    	    sysFlags;	/* Flags to describe the PC's state */
word	    	    skipBP; 	/* Breakpoint number to skip (passed in
				 * RPC_SKIPBPT call) */
int  	    	    attached;	/* TRUE if attached to the PC */
int  	    	    tryingToAttach;	/* TRUE if in the process of
					   trying to attach, but not yet
					   attached to the PC */
Lst    	    	    dead;   	/* The Living Dead (exported for gc) */

word 	    	    kcsum;  	/* Kernel checksum (for use in re-attaching) */

long	    	    exeLoadBase; /* Start of load image in exe file loaded
				  * by DOS to bring up GEOS. Used to obtain
				  * actual offset in load image of kdata,
				  * primarily... */
Boolean	    	    kernelLoaded;   	/* Set TRUE when KERNEL_LOADED call
					 * comes in from the PC */
static Boolean	    loaderInitialized;	/* Set TRUE when PingPC complete */
int    	    	    stubType;	    	/* Type of stub on other side */
int	    	    patientsChucked;	/* Number of patients discarded due
					 * to datedness -- used by GC to
					 * decide if should run */
static Hash_Table   ignored;    /* Patients being ignored. Hashed on
				 * permanent name with data value
				 * being the serial number in the low word and
				 * the core block handle ID in the high word. */

Boolean	    	    noFullStop=FALSE;	/* Set TRUE when a stop of the patient
					 * shouldn't cause a FULLSTOP
					 * event to be dispatched */
Boolean	    	    bootstrap=FALSE; 	/* Bootstrap symbol info */
static Boolean	    initialized=FALSE;	/* Set TRUE when the system has
					 * gone through its full initialization
					 * process (i.e. has made it to
					 * top-level without incident). Used
					 * by Ibm_NewGeode to see if "detach"
					 * is a valid option when searching
					 * for a .geo file */
static char *stubNames[] = {
    "ems", "atron", "lowmem", "bsw", "zoomer"
};

/*
 * Type descriptions for RPC calls
 */
Type	    	    typeSegAddr, typeIbmRegs, typeHaltArgs, typeMaskArgs,
		    typeCallArgs, typeReadArgs, typeWriteArgs, typeFillArgs,
		    typeIOWArgs, typeAbsReadArgs, typeAbsWriteArgs,
		    typeAbsFillArgs, typeSpawnArgs, typeThreadExitArgs,
		    typeGeodeExitArgs, typeHelloArgs, typeHelloReply,
		    typeHelloGeode, typeHelloThread, typeGeosFileHeaderCore,
		    typeGeosFileHeader, typeExecutableFileHeader,
		    typeGeodeHeader,
		    typeGeosFileHeader2, typeExecutableFileHeader2,
		    typeGeodeHeader2,
		    typeIconToken,
		    typeWriteRegsArgs, typeStepReply, typeBeepReply,
                    typeReadXmsMemArgs,
#if 0
		    typeBeepReply1, typeHelloReply1,
    	    	    typeHelloArgs1,
#endif
    	    	    typeSetupReplyArgs;

static Type 	    typeGeodeName;  /* Type for fetching the name and type
				     * of a new geode */

/*
 * Description of the known halt codes.
 */
static const char *stopCodes[] = {
    "Interrupt 0: Divide by zero",
    "Interrupt 1: Single step complete",
    "Interrupt 2: Non-maskable interrupt",
    "Interrupt 3: Breakpoint trap",
    "Interrupt 4: Overflow interrupt",
    "Interrupt 5: Bounds check failed",
    "Interrupt 6: Illegal instruction",
    "Interrupt 7: Coprocessor not present",
    "Interrupt 8: Double-check trap",
    "Interrupt 9: Coprocessor memory fault",
    "Interrupt 10: Invalid task-state segment",
    "Interrupt 11: Segment not present",
    "Interrupt 12: Invalid stack segment",
    "Interrupt 13: Protection violation",
};

Lst  	    allThreads;	    	/* All known threads */
ThreadPtr   realCurThread;  	/* Actual current thread */

/******************************************************************************
 *
 *			  OBJECT FILE CACHE
 *
 ******************************************************************************/
Cache	    objectCache;
#define MAX_OBJECTS 	5   	/* Maximum number of entries in object file
				 * cache */


/***********************************************************************
 *				IbmEnsureObject
 ***********************************************************************
 * SYNOPSIS:	    Make sure the object file for the passed patient is
 *	    	    open.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Another object file may be closed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/24/90		Initial Revision
 *
 ***********************************************************************/
void
IbmEnsureObject(Patient	patient)
{
#if !defined(_MSDOS)
    Boolean 	new;
    Cache_Entry	entry;
    char    	*cp;
    int         returnCode;

    /* if we are using a gym file, then we have no way of knowing if
     * the geode is the correct version, so just don't use it, we don't
     * really need it anyways...its just more efficient
     */
    cp = rindex(patient->path, '.');
    if (strcmp(cp, gym_ext)) {
	entry = Cache_Enter(objectCache, (Address)patient, &new);
    } else {
	patient->object = -1;
	return;
    }
    if (entry != NullEntry) {
	if (new) {
	    genptr buffer;
	    char    geodename[128];

	    strcpy(geodename, patient->path);
	    cp = rindex(geodename, '.');
	    strcpy(cp, ".geo");
	    returnCode = FileUtil_Open(&patient->object, geodename,
				       O_RDONLY|O_BINARY, SH_DENYWR, 0666);
	    if (returnCode == FALSE) {
		patient->object = -1;
		return;
	    }
	    /*
	     * Reset the buffer for the object file.
	     * We don't need the thing to be 8k
	     * (or whatever size the filesystem blocks are)
	     * as we don't do much I/O to it anyway.
	     */
	    buffer = (genptr)malloc(IBM_BUFFER_SIZE);
#if 0
	    setvbuf(patient->object, buffer, _IOFBF, IBM_BUFFER_SIZE);
#endif
	    Cache_SetValue(entry, buffer);
	}
    } else {
	assert(0);
    }
#else
    patient->object = -1;
#endif
}


/***********************************************************************
 *				IbmObjectClose
 ***********************************************************************
 * SYNOPSIS:	    Close the cached object file stream for a patient
 * CALLED BY:	    Cache module
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The stream is closed and the buffer freed and
 *	    	    patient->object set to NULL.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/24/90		Initial Revision
 *
 ***********************************************************************/
static void
IbmObjectClose(Cache	    cache,
	       Cache_Entry  entry)
{
    Patient 	patient = (Patient)Cache_Key(objectCache, entry);
    Address 	buffer = (Address)Cache_GetValue(entry);

    if (patient->object != -1)
    {
	(void)FileUtil_Close(patient->object);
    }

    free((malloc_t)buffer);

    patient->object = -1;
}


/***********************************************************************
 *				IbmEnsureClosed
 ***********************************************************************
 * SYNOPSIS:	    Make sure the object file for the patient is closed.
 * CALLED BY:	    IbmOpenObject, IbmConnectCmd
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The object file is closed if it was open
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/24/90		Initial Revision
 *
 ***********************************************************************/
void
IbmEnsureClosed(Patient	patient)
{
    Cache_Entry entry;

    entry = Cache_Lookup(objectCache, (Address)patient);
    if (entry != (Cache_Entry)NULL) {
	Cache_InvalidateOne(objectCache, entry);
    }
}

/******************************************************************************
 *
 *		      HANDLE INTEREST PROCEDURES
 *
 ******************************************************************************/
static void IbmBiffPatient(Patient patient);

/***********************************************************************
 *				IbmStackInterest
 ***********************************************************************
 * SYNOPSIS:	    Interest procedure for thread stacks. Thread
 *		    stacks are supposed to be fixed, so in theory, this
 *		    procedure should never be called...
 * CALLED BY:	    Handle module
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/22/88	Initial Revision
 *
 ***********************************************************************/
static void
IbmStackInterest(Handle    	handle,	    /* Handle that changed */
	         Handle_Status 	status,	    /* What happened to it */
	         Opaque     	data)	    /* Our data */
{
    /*
     * If handle was freed, null out the 'stack' field for the thread to
     * indicate it needn't nuke the interest record. This could conceivably
     * happen if the kernel frees the stack before notifying us of the thread
     * exit. It shouldn't, but with Tony code, you never know...
     */
    if (status == HANDLE_FREE) {
	ThreadPtr	thread = (ThreadPtr)data;

	assert(VALIDTPTR(thread,TAG_THREAD));
	thread->stack = NullHandle;
    }
}
/******************************************************************************
 *
 *		       ERROR-CHECKING ROUTINES
 *
 ******************************************************************************/

/***********************************************************************
 *				IbmCheckPatient
 ***********************************************************************
 * SYNOPSIS:	    Verify that the fields of a patient record are
 *	    	    consistent.
 * CALLED BY:	    Lots of things
 * RETURN:	    Only if patient ok.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/31/89		Initial Revision
 *
 ***********************************************************************/
void
IbmCheckPatient(Patient	    patient)
{
    /*
     * Error-checking:
     *	- name is PNAME (or patient is kernel, since its name
     *	  is statically allocated).
     *	- path is PNAME (always dynamic).
     *	- global is a symbol.
     *	- frame is a frame or null.
     *	- core block is a handle or null.
     *	- geode is PATIENT or null. if null, patient must be the kernel, as
     *	  everything else must be a real geode.
     *	- current thread is a thread or null.
     *	- libraries array is PATIENT or geode has no libraries.
     *	- resources array is PATIENT.
     */
    assert(VALIDTPTR(patient->name, TAG_PNAME) ||
	   (patient == loader));
    assert(VALIDTPTR(patient->path, TAG_PNAME));
/*    assert(VALIDTPTR(patient->global, TAG_SYM) ||
	   (patient->global == NULL));*/
    assert(VALIDTPTR(patient->frame, TAG_FRAME) ||
	   (patient->frame == NULL));
    assert(VALIDTPTR(patient->core, TAG_HANDLE) || (patient->core == NULL));
    assert(VALIDTPTR(patient->geode.v1, TAG_PATIENT) ||
	   (patient->geode.v1 == NULL &&
	    (patient == loader || patient->dos)));
    assert(VALIDTPTR(patient->curThread,TAG_THREAD) ||
	   (patient->curThread == NULL));
    assert(VALIDTPTR(patient->libraries,TAG_PATIENT) ||
	   (patient->numLibs == 0));
    assert(VALIDTPTR(patient->resources,TAG_PATIENT) ||
	   (patient->numRes == 0));
}
/******************************************************************************
 *
 *			   UTILITY ROUTINES
 *
 ******************************************************************************/

/***********************************************************************
 *				IbmFindOtherInstance
 ***********************************************************************
 * SYNOPSIS:	    Locate another instance of a particular geode
 *		    in the list of active patients.
 * CALLED BY:	    HandleExit, Ibm_NewGeode, IbmBiffPatient
 * RETURN:	    the Patient of the other instance, or NullPatient if
 *		    there is no other instance
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 2/92	Initial Revision
 *
 ***********************************************************************/
Patient
IbmFindOtherInstance(GeodeName	    *gnPtr,    	/* Salient data about the
						 * patient */
		     Patient	    notThis,	/* If finding another instance
						 * of an active patient, this
						 * is the active patient whose
						 * Patient token isn't to be
						 * returned */
		     int   	    *nPtr)  	/* OUT: place to store the
						 * number of patients whose
						 * root name match
						 * gnPtr->geodeName. May be
						 * NULL */
{
    Patient 	first;
    int	    	n;
    LstNode 	ln;

    first = NullPatient;


    for (n = 0, ln=Lst_First(patients); ln != NILLNODE; ln=Lst_Succ(ln)){
	Patient	    thisPatient;

	thisPatient = (Patient)Lst_Datum(ln);
	if (thisPatient->geode.v2 != 0 &&
	    (!bcmp(thisPatient->geode.v2->geodeName,
		   gnPtr->name,
		   GEODE_NAME_SIZE)))
	{
	    /*
	     * If don't have a patient of this name yet, and this patient's
	     * name matches IN ALL PARTICULARS (i.e. its extension is the same,
	     * too -- need to make the distinction since patient names are
	     * formed just from the permanent name, not the extension, but the
	     * extension is significant in determining which version...),
	     * use the state from this patient later on.
	     */
	    if ((first == NullPatient) &&
		(!bcmp(thisPatient->geode.v2->geodeNameExt,
		       gnPtr->ext,
		       GEODE_NAME_EXT_SIZE)) &&
		(thisPatient->geode.v2->geodeSerial == gnPtr->serial) &&
		(thisPatient != notThis))
	    {
		first = thisPatient;
	    }
	    n++;
	}
    }

    if (nPtr) {
	*nPtr = n;
    }

    return(first);
}


/***********************************************************************
 *				IbmSetDir
 ***********************************************************************
 * SYNOPSIS:	    Set the current working directory based on the
 *	    	    location of the current patient's executable file
 * CALLED BY:	    IbmSwitchCmd,Ibm_Stop,Ibm_SingleStep,IbmHalt
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The current working directory is changed
 *
 * STRATEGY:	    If there's a path to the file, use its directory
 *	    	    part, else use the directory saved in 'cwd' when
 *	    	    we started up.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/11/88	Initial Revision
 *
 ***********************************************************************/
int
IbmSetDir(void)
{
    char    *cp;
    Patient p = curPatient->frame ? curPatient->frame->patient : curPatient;
    static Patient patientWithPath = NullPatient;

    if (p != patientWithPath) {
	patientWithPath = p;
	/*
	 * Change to the directory in which we found the current patient.
	 */
	if ((p == NullPatient) || ((cp = rindex(p->path, '/')) == NULL)) {
	    /*
	     * In our original working directory...
	     */
	    chdir(cwd);
	} else {
	    *cp = '\0';
	    chdir(p->path);
	    *cp = '/';
	}
    }
    return(EVENT_HANDLED);
}

/***********************************************************************
 *				IbmUseDefaultPatient
 ***********************************************************************
 * SYNOPSIS:	    The current thread is unknown, so use the 0th thread
 *	    	    from the kernel, if the beast is around, or the loader
 *	    	    if not.
 * CALLED BY:	    IbmSetCurPatient, IbmReset, others
 * RETURN:	    Nothing
 * SIDE EFFECTS:    realCurThread and curPatient set
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/22/91		Initial Revision
 *
 ***********************************************************************/
static void
IbmUseDefaultPatient(void)
{
    if (kernel != NULL) {
	curPatient = kernel;
	realCurThread = (ThreadPtr)Lst_Datum(Lst_First(kernel->threads));
    } else {
	curPatient = loader;
	realCurThread = (ThreadPtr)Lst_Datum(Lst_First(loader->threads));
    }
}

/***********************************************************************
 *				IbmSetCurPatient
 ***********************************************************************
 * SYNOPSIS:	    Set curPatient and its curThread field based on
 *	    	    the given thread ID
 * CALLED BY:	    IbmHalt, Ibm_Stop, IbmConnect
 * RETURN:	    Nothing
 * SIDE EFFECTS:    curPatient is altered.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/20/89		Initial Revision
 *
 ***********************************************************************/
static void
IbmSetCurPatient(word	threadID)
{
    Handle  	curThreadHandle = Handle_Lookup(threadID);

    if ((curThreadHandle == NullHandle) ||
	!Handle_IsThread(Handle_State(curThreadHandle)))
    {
	if (threadID != 0) {
	    /*
	     * Stub uses "0" when in the loader b/c it has no other idea what
	     * to use (XXX: use 1, and make loader handle IDs start from 2?)
	     */
	    Warning("Current thread (%04xh) unknown -- using kernel thread",
		    threadID);
	}
	IbmUseDefaultPatient();
    } else {
	curPatient = Handle_Patient(curThreadHandle);

	realCurThread = (ThreadPtr)curThreadHandle->otherInfo;
    }
    realCurThread->flags |= IBM_REGS_NEEDED;
    curPatient->curThread = (Thread)realCurThread;

    /*XXX*/
    IbmCheckPatient(curPatient);
}

/******************************************************************************
 *
 *		       STATE FLUSHING ROUTINES
 *
 ******************************************************************************/

/***********************************************************************
 *				IbmFlushRegs
 ***********************************************************************
 * SYNOPSIS:	  Mark a thread as needing its registers fetched and
 *	    	    write its registers if they're dirty.
 * CALLED BY:	  IbmFlushState via Lst_ForEach
 * RETURN:	  === 0
 * SIDE EFFECTS:  the IBM_REGS_NEEDED flag is set in the thread descriptor
 *
 * STRATEGY:	  None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/13/88		Initial Revision
 *
 ***********************************************************************/
static int
IbmFlushRegs(ThreadPtr	  	thread)	    /* Thread to flush */
{
    if (thread->flags & IBM_REGS_DIRTY) {
	WriteRegsArgs   wra;

	wra.wra_thread = Handle_ID(thread->handle);
	wra.wra_regs = thread->regs;

	if (Rpc_Call(RPC_WRITE_REGS,
		     sizeof(wra), typeWriteRegsArgs, (Opaque)&wra,
		     0, NullType, (Opaque)0) != RPC_SUCCESS)
	{
	    Warning("Couldn't install new registers: %s",
		    Rpc_LastError());
	}
	thread->flags &= ~IBM_REGS_DIRTY;
    }

    thread->flags |= IBM_REGS_NEEDED;
    return(0);
}

/***********************************************************************
 *				IbmFlushState
 ***********************************************************************
 * SYNOPSIS:	  Flush state to the PC that needs to be flushed.
 * CALLED BY:	  Ibm_Step, Ibm_Continue, IbmContinueCmd, EVENT_CONTINUE
 * RETURN:	  Nothing.
 * SIDE EFFECTS:  The registers and dirty data blocks are flushed.
 *
 * STRATEGY:	Flush the registers for all known threads.
 *	    	Invalidate all blocks in the cache.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/13/88		Initial Revision
 *
 ***********************************************************************/
static int
IbmFlushState(Event event, Opaque callData, Opaque clientData)
{
    LstNode	ln;

    /*
     * Flush all modified registers and make sure we fetch registers for
     * all threads when we need them...
     */
    Lst_ForEach(allThreads, IbmFlushRegs, (LstClientData)NULL);

    /*
     * Clear the extra scope for all patients, so if a new version of a
     * patient is downloaded behind GEOS's back, we don't end up with
     * a lingering symbol that's no longer valid.
     */
    for (ln = Lst_First(patients); ln != NILLNODE; ln = Lst_Succ(ln)) {
	Patient patient = (Patient)Lst_Datum(ln);

	patient->scope = patient->global;
    }

    /*
     * Force all dirty data blocks to be flushed.
     */
    Cache_InvalidateAll(dataCache, TRUE);

    if (realCurThread && (realCurThread->flags & IBM_THREAD_GONE)) {
	/*
	 * Now that anyone who may need the current state of the machine
	 * has used that state, destroy the current thread.
	 *
	 * Nuke saved state list and the Handle for the thread.
	 */

	/*
	 * If stack handle hasn't been freed yet, free it now, as the kernel
	 * won't actually tell us when the thing goes away...Note that we
	 * can't free the thing if it's a resource handle (nor do we need
	 * to). Instead, we just need to unregister interest in the thing
	 * (freeing a non-resource handle will automatically remove our
	 * interest record for us).
	 */
	if (realCurThread->stack) {
	    if (Handle_State(realCurThread->stack) & HANDLE_RESOURCE) {
		Handle_NoInterest(realCurThread->stack,
				  IbmStackInterest,
				  (Opaque)realCurThread);
	    } else {
		Handle_Free(realCurThread->stack);
	    }
	}

	Lst_Destroy(realCurThread->state, (void (*)())free);
	Handle_Free(realCurThread->handle);

	/*
	 * Find and remove realCurThread from the list of all threads.
	 */
	ln = Lst_Member(allThreads, (LstClientData)realCurThread);
	assert(ln != NILLNODE);
	Lst_Remove(allThreads, ln);

	/*
	 * Free thread descriptor itself
	 */
	free((char *)realCurThread);

	/*
	 * Change the curThread field of the current patient so the
	 * error-checking code doesn't choke.
	 */
	if (!Lst_IsEmpty(curPatient->threads)) {
	    curPatient->curThread =
		(Thread)Lst_Datum(Lst_First(curPatient->threads));
	} else {
	    /*
	     * Patient has no threads -- set curThread NULL to avoid
	     * failed assertion...
	     */
	    curPatient->curThread = (Thread)NULL;
	}
	realCurThread = (ThreadPtr)curPatient->curThread;

	/*
	 * If current patient marked for biffing, do so now.
	 */
	if (curPatient->patientPriv != NullOpaque) {
	    IbmBiffPatient(curPatient);
	}
    }

    return(EVENT_HANDLED);
}

/******************************************************************************
 *
 *			   REGISTER ACCESS
 *
 ******************************************************************************/

/***********************************************************************
 *				IbmEnsureRegs
 ***********************************************************************
 * SYNOPSIS:	    Make sure the thread has valid registers
 * CALLED BY:	    IbmReadThreadRegister, IbmWriteThreadRegister
 * RETURN:	    TRUE if the registers are valid, FALSE if they
 *	    	    aren't
 * SIDE EFFECTS:    Registers will be fetched for the thread if they're
 *	    	    not already present.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 2/95	Initial Revision
 *
 ***********************************************************************/
static Boolean
IbmEnsureRegs(ThreadPtr thread)
{
    if (thread->flags & IBM_REGS_NEEDED) {
	word	id = Handle_ID(thread->handle);

#if REGS_32
/* TESTING -- LES!!! */
/* Try to cause the xipPage to be bad for checking */
/* as well as the extended flags */
thread->regs.reg_xipPage = 0xFEFE ;
thread->regs.reg_eflags = 0xFDFDFDFD ;
#endif

	if (Rpc_Call(RPC_READ_REGS,
		     sizeof(id), type_Word, (Opaque)&id,
		     sizeof(thread->regs), typeIbmRegs,
		     (Opaque)&thread->regs) != RPC_SUCCESS)
	{
	    Warning("Couldn't read registers for thread %d of %s: %s",
		    thread->number,
		    Handle_Patient(thread->handle)->name,
		    Rpc_LastError());
	    return(FALSE);
	}
	thread->flags &= ~IBM_REGS_NEEDED;
	/*
	 * Older stubs can return garbage for reg_xipPage for the kernel
	 * thread if you attach after the system is running. If the thing
	 * is garbage and the thread is the kernel thread, just set it to
	 * HANDLE_NOT_XIP -- ardeb 11/2/95
	 */
	if (!VALID_XIP(thread->regs.reg_xipPage) &&
	    Handle_ID(thread->handle) == HID_KTHREAD)
	{
	    thread->regs.reg_xipPage = HANDLE_NOT_XIP;
	}
    }
    return(TRUE);
}

/***********************************************************************
 *				IbmReadThreadRegister
 ***********************************************************************
 * SYNOPSIS:	    Read a register from a thread.
 * CALLED BY:	    Ibm_ReadRegister, IbmThreadCmd
 * RETURN:	    TRUE and the value if could, FALSE if couldn't
 *	    	    fetch the register or the args were invalid.
 * SIDE EFFECTS:    Registers will be fetched for the thread if they're
 *	    	    not already present.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 3/88	Initial Revision
 *
 ***********************************************************************/
Boolean
IbmReadThreadRegister(ThreadPtr	    thread,
		      RegType	    regType,
		      int   	    regNum,
		      regval        *valuePtr)
{
    Boolean 	result = TRUE;

    assert(VALIDTPTR(thread, TAG_THREAD));

    if (!IbmEnsureRegs(thread)) {
	return(FALSE);
    }

    if (regType == REG_MACHINE) {
	switch(regNum) {
	    case REG_AX:
	    case REG_BX:
	    case REG_CX:
	    case REG_DX:
	    case REG_SP:
	    case REG_BP:
	    case REG_SI:
	    case REG_DI:
	    case REG_ES:
	    case REG_CS:
	    case REG_SS:
	    case REG_DS:
		/*
		 * One of the twelve general registers -- we can just index
		 * straight into the state for the thread.
		 */
		*valuePtr = thread->regs.reg_regs[RegisterMapping(regNum)];
		break;
	    case REG_AL:
	    case REG_BL:
	    case REG_CL:
	    case REG_DL:
		/*
		 * Low-half of arithmetic registers -- index and mask
		 */
		*valuePtr = thread->regs.reg_regs[RegisterMapping(regNum-REG_AL)] & 0xff;
		break;
	    case REG_AH:
	    case REG_BH:
	    case REG_CH:
	    case REG_DH:
		/*
		 * High-half of arithmetic registers -- index, shift and mask
		 */
		*valuePtr = (thread->regs.reg_regs[RegisterMapping(regNum-REG_AH)]>>8)&0xff;
		break;
	    case REG_SR:
		/*
		 * Special code for the flags register -- fetch it
		 */
#if REGS_32
                *valuePtr = (word)thread->regs.reg_eflags;
#else
                *valuePtr = thread->regs.reg_flags;
#endif
		break;
	    case REG_IP:
		/*
		 * Instruction pointer -- fetch it
		 */
		*valuePtr = thread->regs.reg_ip;
		break;
	    case REG_PC:
		/*
		 * 32-bit PC -- shift CS and add IP
		 */
		*(Opaque *)valuePtr =
		    (Opaque)MakeAddress(thread->regs.reg_regs[RegisterMapping(REG_CS)],
			     thread->regs.reg_ip);
		break;
#if REGS_32
            case REG_EAX:
            case REG_EBX:
            case REG_ECX:
            case REG_EDX:
            case REG_ESP:
            case REG_EBP:
            case REG_ESI:
            case REG_EDI:
                *valuePtr = *((regval *)(thread->regs.reg_regs + RegisterMapping(regNum))) ;
                break;
            case REG_FS:
            case REG_GS:
		*valuePtr = thread->regs.reg_regs[RegisterMapping(regNum)];
                break ;
            case REG_EIP:
		*valuePtr = thread->regs.reg_ip;
                break ;
#endif
            default:
		/*
		 * Bogus
		 */
		result = FALSE;
		break;
	}
    } else {
	char	*regName = (char *)regNum;

	if (strcmp(regName, "curThread") == 0) {
	    *valuePtr = Handle_ID(realCurThread->handle);
	} else if (strcmp(regName, "xipPage") == 0) {
	    *valuePtr = thread->regs.reg_xipPage;
	    assert(VALID_XIP(*valuePtr));
	} else {
	    /*
	     * What non-machine registers should we support?
	     */
	    result = FALSE;
	}
    }

    /*
     * If patient actually running, mark the thread as needing registers
     * again so we get the most up-to-date versions next time.
     */
    if (sysFlags & PATIENT_RUNNING) {
	thread->flags |= IBM_REGS_NEEDED;
    }

    return(result);
}

Boolean
IbmReadThreadRegister16(ThreadPtr	    thread,
		      RegType	    regType,
		      int   	    regNum,
		      word        *valuePtr)
{
    Boolean ret ;
    regval value ;
    ret = IbmReadThreadRegister(thread, regType, regNum, &value) ;
    *valuePtr = (word)value ;
    return ret ;
}


/***********************************************************************
 *				Ibm_ReadRegister
 ***********************************************************************
 * SYNOPSIS:	  Read the contents of an 8086 register
 * CALLED BY:	  GLOBAL
 * RETURN:	  TRUE if could read the register. FALSE if not.
 * SIDE EFFECTS:  The register's value is stored in the given place.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/13/88		Initial Revision
 *
 ***********************************************************************/
Boolean
Ibm_ReadRegister(RegType    regType,    /* Type of register to read */
		 int 	    regNum,	/* Register number */
		 regval     *valuePtr)	/* Place to store value */
{
    ThreadPtr	cur = (ThreadPtr)curPatient->curThread;

    if (cur == NullThread) {
	Warning("Can't read register -- no current thread");
	return(FALSE);
    }

    return (IbmReadThreadRegister(cur, regType, regNum, valuePtr));
}

/* Simpler routine to just read a 16 bit value */
Boolean
Ibm_ReadRegister16(RegType    regType,    /* Type of register to read */
		 int 	    regNum,	/* Register number */
		 word      *valuePtr)	/* Place to store value */
{
    regval value ;
    Boolean ret ;

    ret = Ibm_ReadRegister(regType, regNum, &value) ;
    if (ret)
        *valuePtr = (word)value ;

    return ret ;
}

/***********************************************************************
 *				Ibm_WriteRegister
 ***********************************************************************
 * SYNOPSIS:	  Write the contents of an 8086 register
 * CALLED BY:	  GLOBAL
 * RETURN:	  TRUE if could write the register. FALSE if not.
 * SIDE EFFECTS:  The new value is stored in the proper place.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/13/88		Initial Revision
 *
 ***********************************************************************/
Boolean
Ibm_WriteRegister(RegType    regType,    /* Type of register to read */
		 int	    regNum, 	/* Register number */
		 regval	    value)      /* Value to store */
{
    ThreadPtr	    cur = (ThreadPtr)curPatient->curThread;
    Boolean 	    result = TRUE;

    if (cur == NullThread) {
	Warning("Can't write register -- no current thread");
	return(FALSE);
    }
    if (!IbmEnsureRegs(cur)) {
	return(FALSE);
    }

    if (regType == REG_MACHINE) {
	switch(regNum) {
	case REG_AX:
	case REG_BX:
	case REG_CX:
	case REG_DX:
	case REG_SP:
	case REG_BP:
	case REG_SI:
	case REG_DI:
	case REG_ES:
	case REG_CS:
	case REG_SS:
	case REG_DS:
#if REGS_32
        case REG_FS:
        case REG_GS:
#endif /* REGS_32 */
	    /*
	     * One of the twelve general registers -- we can just index
	     * straight into the state for the thread.
	     */
	    cur->regs.reg_regs[RegisterMapping(regNum)] = value;
	    cur->flags |= IBM_REGS_DIRTY;
	    break;
	case REG_AL:
	case REG_BL:
	case REG_CL:
	case REG_DL:
	    /*
	     * Low-half of arithmetic registers -- index and mask
	     */
	    cur->regs.reg_regs[RegisterMapping(regNum - REG_AL)] &= 0xff00;
	    cur->regs.reg_regs[RegisterMapping(regNum - REG_AL)] |= value&0xff;
	    cur->flags |= IBM_REGS_DIRTY;
	    break;
	case REG_AH:
	case REG_BH:
	case REG_CH:
	case REG_DH:
	    /*
	     * High-half of arithmetic registers -- index, shift and mask
	     */
	    cur->regs.reg_regs[RegisterMapping(regNum-REG_AH)] &= 0xff;
	    cur->regs.reg_regs[RegisterMapping(regNum-REG_AH)] |= (value & 0xff) << 8;
	    cur->flags |= IBM_REGS_DIRTY;
	    break;
#if REGS_32
        case REG_EAX:
        case REG_EBX:
        case REG_ECX:
        case REG_EDX:
        case REG_ESI:
        case REG_EDI:
        case REG_EBP:
        case REG_ESP:
	    *((dword *)&cur->regs.reg_regs[RegisterMapping(regNum-REG_EAX)]) = value ;
            cur->flags |= IBM_REGS_DIRTY ;
            break ;
#endif /* REGS_32 */
	case REG_SR:
	    /*
	     * Special code for the flags register -- store it
	     */
#if REGS_32
            cur->regs.reg_eflags = (cur->regs.reg_eflags & 0xFFFF0000) | value;
#else
            cur->regs.reg_flags = value ;
#endif
	    cur->flags |= IBM_REGS_DIRTY;
	    break;
#if REGS_32
        case REG_EIP:
            /* Fall into REG_IP -- we don't currently support true EIP register modification */
#endif
	case REG_IP:
	    /*
	     * Instruction pointer -- store it.
	     */
	    cur->regs.reg_ip = value;
	    cur->flags |= IBM_REGS_DIRTY;
	    break;
        case REG_PC:
	    Warning("Attempt to write a LONG register");
	    /*FALLTHRU*/
	default:
	    /*
	     * Bogus
	     */
	    result = FALSE;
	    break;
	}
    } else {
	/*
	 * What non-machine registers should we support?
	 */
	result = FALSE;
    }

    /*
     * If patient actually running, flush the registers out now and mark
     * the thread as still needing registers.
     */
    if (sysFlags & PATIENT_RUNNING) {
	if (cur->flags & IBM_REGS_DIRTY) {
	    (void)IbmFlushRegs(cur);
	}
	cur->flags |= IBM_REGS_NEEDED;
    }

    return(result);
}

/******************************************************************************
 *
 *			  INTERFACE ROUTINES
 *
 ******************************************************************************/

/***********************************************************************
 *				Ibm_MaybeUnignore
 ***********************************************************************
 * SYNOPSIS:	    See if the passed patient is being ignored and
 *	    	    try to unignore it if the user wants us to.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    TRUE if patient has been unignored.
 * SIDE EFFECTS:    An entry in the "ignored" table may be biffed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/18/91		Initial Revision
 *
 ***********************************************************************/
Boolean
Ibm_MaybeUnignore(char *name)
{
    Hash_Search	search;
    Hash_Entry	*entry;
    int	    	namelen = strlen(name);

    for (entry = Hash_EnumFirst(&ignored, &search);
	 entry != NullHash_Entry;
	 entry = Hash_EnumNext(&search))
    {
	/*
	 * See if the name for this entry matches the patient being sought.
	 * The comparison is made a little more difficult by the name in the
	 * entry being space-padded to GEODE_NAME_SIZE and followed by the
	 * extension
	 */
	if ((strncmp(entry->key.name, name, namelen) == 0) &&
	    ((namelen == GEODE_NAME_SIZE) || (entry->key.name[namelen] == ' ')))
	{
	    char    answer[32];

	    Message("Patient \"%.*s\" was ignored -- would you like to unignore it?[yn](y) ", namelen, name);
	    Ui_ReadLine(answer);

	    if ((answer[0] != 'n') && (answer[0] != 'N')) {
		/*
		 * User wants to unignore it -- extract the core block from the
		 * entry, then biff the entry and try to look up that handle.
		 * If the geode's still around, the Handle_Lookup will cause
		 * the geode to be created and the user asked for the path to
		 * the thing's executable.
		 */
		word	coreID = ((dword)Hash_GetValue(entry) >> 16) & 0xffff;

		Hash_DeleteEntry(&ignored, entry);
		if (Handle_Lookup(coreID) != NullHandle) {
		    return(TRUE);
		} else {
		    Message("Unable to locate \"%s\", core block handle %04xh\n",
			    name, coreID);
		}

	    }
	    break;
	}
    }
    return(FALSE);
}

/***********************************************************************
 *				Ibm_StackEnd
 ***********************************************************************
 * SYNOPSIS:	    Find the offset to the bottom of the current
 *		    thread's stack.
 * CALLED BY:	    Ibm86BuildFrame and others
 * RETURN:	    The aforementioned offset.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Return the stackBot field of the current thread of
 *	    	    the current patient.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
word
Ibm_StackEnd(void)
{
    Handle  stack = Ibm_StackHandle();

    if (stack != NullHandle) {
	return(Handle_Size(stack));
    } else {
	return (0);
    }
}


/***********************************************************************
 *				Ibm_StackHandle
 ***********************************************************************
 * SYNOPSIS:	    Retrieve the handle for the current frame's block
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The handle
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
Handle
Ibm_StackHandle(void)
{
    regval  	ss;

    MD_GetFrameRegister(curPatient->frame, REG_MACHINE, REG_SS, &ss);
    return (Handle_Find(MakeAddress(ss, 0)));
}


/***********************************************************************
 *				Ibm_SingleStep
 ***********************************************************************
 * SYNOPSIS:	  Make the current thread execute a single instruction
 * CALLED BY:	  GLOBAL
 * RETURN:	  TRUE if it could be done and FALSE if it couldn't
 * SIDE EFFECTS:  Dirty registers are written, cache blocks flushed, etc.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/12/88		Initial Revision
 *
 ***********************************************************************/
Boolean
Ibm_SingleStep(void)
{
    ThreadPtr	    cur = realCurThread;
    word    	    tid = Handle_ID(realCurThread->handle);
    Boolean 	    stayStopped;

    if (cur != (ThreadPtr)curPatient->curThread) {
	Warning("%s #%d not really current thread\n", curPatient->name,
		curPatient->curThread ?
		((ThreadPtr)curPatient->curThread)->number : 0);
	/*
	 * Switch to the real current patient/thread.
	 */
	curPatient = Handle_Patient(cur->handle);
	curPatient->curThread = (Thread)cur;
    }

    do {
	StepReply   sr;

	/*
	 * Tell the world we're stepping this patient.
	 */
	(void)Event_Dispatch(EVENT_CONTINUE, CONTINUE_STEP);

	/*
	 * Actually do it.
	 */
	sysFlags &= ~PATIENT_STOPPED;
	sysFlags |= PATIENT_RUNNING;

	if (Rpc_Call(RPC_STEP, 0, NullType, (Opaque)NULL,
		     sizeof(sr), typeStepReply, (Opaque)&sr) != RPC_SUCCESS)
	{
	    /*
	     * If we didn't get a reply for some other reason than that the PC
	     * stopped in some other way (as reflected by the PATIENT_STOPPED
	     * flag being set), tell the user about it.
	     */
	    if (!(sysFlags & PATIENT_STOPPED)) {
		Warning("Couldn't single-step PC: %s", Rpc_LastError());
	    }
	    return(FALSE);
	} else {

	    IbmSetCurXIPPage(sr.sr_curXIPPage);

	    if (sr.sr_thread != tid) {
		IbmSetCurPatient(sr.sr_thread);
	    }

	    cur->flags &= ~(IBM_REGS_NEEDED|IBM_REGS_DIRTY);
	    cur->regs = sr.sr_regs;
	    cur->regs.reg_xipPage = sr.sr_curXIPPage;

	    sysFlags &= ~(PATIENT_SKIPBPT|PATIENT_RUNNING|PATIENT_BREAKPOINT|PATIENT_STOP);
	    sysFlags |= PATIENT_STOPPED;
	    stayStopped = FALSE;

	    curPatient->frame = MD_CurrentFrame();
	    (void)IbmSetDir();

	    if (Event_Dispatch(EVENT_STEP,
			       (Opaque)&stayStopped) != EVENT_HANDLED)
	    {
		stayStopped = TRUE;
		break;
	    } else if (stayStopped || Ui_Interrupt()) {
		break;
	    } else if (sysFlags & PATIENT_RUNNING) {
		return(TRUE);
	    }
	}
    } while (sysStep);

    if (stayStopped) {
	Tcl_SetVar(interp, "lastHaltCode", stopCodes[1], TRUE);
	if (!noFullStop) {
	    /*
	     * Machine staying stopped -- notify everyone of the fact, giving
	     * the reason as the piece of data.
	     */
	    Event_Dispatch(EVENT_FULLSTOP, (Opaque)stopCodes[1]);

	    /*
	     * If actually keeping the thing stopped, abort any calls we have
	     * in progress.
	     */
	    Rpc_Abort();
	}
    } else {
	/*
	 * If not supposed to stay stopped sysStep must be 0 or we would
	 * have looped, so continue the patient normally.
	 */
	Ibm_Continue();
    }
    return(TRUE);
}


/***********************************************************************
 *				Ibm_Stop
 ***********************************************************************
 * SYNOPSIS:	  Stop the patient, or try to.
 * CALLED BY:	  GLOBAL
 * RETURN:	  Nothing
 * SIDE EFFECTS:  The patient be stopped. The actual halt notification
 *	is done via an RPC_HALT call.
 *
 * STRATEGY:
 *	Issue the RPC_INTERRUPT RPC to the PC. Note this will only work
 *	if the stub is using interrupt-driven I/O. If the stub is on
 *	the atron, a warning message is printed and the command ignored.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/14/88		Initial Revision
 *
 ***********************************************************************/
void
Ibm_Stop(void)
{
    word    threadID;	    	/* ID of current thread */

    /*
     * Note we think the beast is stopped
     */
    sysFlags &= ~PATIENT_RUNNING;
    if (Rpc_Call(RPC_INTERRUPT,
		 0, NullType, (Opaque)0,
		 sizeof(threadID), type_Word,
		 (Opaque)&threadID) != RPC_SUCCESS)
    {
	char	answer[32];

	sysFlags |= PATIENT_RUNNING; /* Nope... */
	Warning("Couldn't stop GEOS: %s", Rpc_LastError());
	MessageFlush("Would you like to detach? [yn](y) ");

	Ui_ReadLine(answer);

	if ((answer[0] != 'n') && (answer[0] != 'N')) {
	    sysFlags &= ~(PATIENT_RUNNING|PATIENT_BREAKPOINT|PATIENT_SKIPBPT);
	    sysFlags |= PATIENT_STOPPED;

	    IbmDisconnect(RPC_GOODBYE);
	    Tcl_SetVar(interp, "lastHaltCode", "PC Detached", TRUE);
	}
    } else {
	/*
	 * Figure out the current thread, etc. from the thread ID we were
	 * given. The registers will be fetched on the fly.
	 */
	IbmSetCurPatient(threadID);
	/*
	 This assertion can fail if an RPC_HALT call came in while the
	 RPC_INTERRUPT call was being performed. In this case, the registers
	 are valid, so we're fine. This was mostly to catch bugs, which aren'
	 t here anymore :)
	assert(cur->flags & IBM_REGS_NEEDED);
	 */

	sysFlags &= ~(PATIENT_RUNNING|PATIENT_BREAKPOINT|PATIENT_SKIPBPT);
	sysFlags |= PATIENT_STOPPED;
	curPatient->frame = MD_CurrentFrame();
	(void)IbmSetDir();

	if (!noFullStop) {
	    (void)Event_Dispatch(EVENT_FULLSTOP, (Opaque)"GEOS Halted");
	}
	Tcl_SetVar(interp, "lastHaltCode", "PC Halted", TRUE);
    }
}

/***********************************************************************
 *				Ibm_LostContact
 ***********************************************************************
 * SYNOPSIS:	  Clean up ibm stuff because stub is gone
 * CALLED BY:	  RpcSendV, RpcHandleStream, RpcWait
 * RETURN:	  Nothing
 * SIDE EFFECTS:  attach is set to FALSE the communications are disconnected
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	1/23/96		Initial Revision
 *
 ***********************************************************************/
void
Ibm_LostContact(void)
{
    MessageFlush("Lost connection to GEOS\n");
    sysFlags &= ~(PATIENT_RUNNING|PATIENT_BREAKPOINT|PATIENT_SKIPBPT);
    sysFlags |= PATIENT_STOPPED;

    IbmDisconnect(0);

    Ui_TopLevel();
}


/***********************************************************************
 *				Ibm_Continue
 ***********************************************************************
 * SYNOPSIS:	  Give the patient free reign.
 * CALLED BY:	  GLOBAL
 * RETURN:	  TRUE if could and FALSE if couldn't continue it.
 * SIDE EFFECTS:  state is flushed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/12/88		Initial Revision
 *
 ***********************************************************************/
Boolean
Ibm_Continue(void)
{
    word    arg = 0;

    if (sysStep) {
	/*
	 * Do special handling for single-stepping
	 */
	return (Ibm_SingleStep());
    } else {
	/*
	 * Change to the real current thread so people don't get
	 * confused. Still need to dispatch the CHANGE event to make sure
	 * Ibm86 doesn't get confused....
	 */
	Patient	    patient;

	patient = Handle_Patient(realCurThread->handle);
	if ((patient != curPatient) ||
	    (patient->curThread != (Thread)realCurThread))
	{
	    Patient oldPatient = curPatient;

	    curPatient = patient;
	    patient->curThread = (Thread)realCurThread;

	    (void)Event_Dispatch(EVENT_CHANGE, (Opaque)oldPatient);
	}

	/*
	 * Tell the world we're continuing this patient.
	 */
	(void)Event_Dispatch(EVENT_CONTINUE, CONTINUE_FULL);

	/*
	 * Actually do it.
	 */
	sysFlags &= ~ PATIENT_STOPPED;
	sysFlags |= PATIENT_RUNNING;
	if (sysFlags & PATIENT_SKIPBPT) {
	    arg = skipBP;
	}

	return (Rpc_Call((unsigned short)((sysFlags & PATIENT_SKIPBPT) ?
			  RPC_SKIPBPT : RPC_CONTINUE),
			 sizeof(arg), type_Word, (Opaque)&arg,
                         0, NullType, (Opaque)NULL) == RPC_SUCCESS);
    }
}

/***********************************************************************
 *				Ibm_NewThread
 ***********************************************************************
 * SYNOPSIS:	    Note the existence of a new thread.
 * CALLED BY:	    IbmConnect, IbmSpawn, Handle_Lookup, Ibm_Init
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Lots
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/22/88	Initial Revision
 *
 ***********************************************************************/
Handle
Ibm_NewThread(word   	id, 	    /* ID for new thread */
	      word   	ownerID,    /* ID of owner of thread */
	      regval   	ss, 	    /* Current SS */
	      regval   	sp, 	    /* Maximum SP */
	      Boolean	notify,	    /* TRUE if should print a message about */
				    /* the thread/patient. */
	      int    	flags)	    /* Additional flags to use when creating
				     * the Handle */

{
    Handle  	owner;	    	/* Handle of core block of owner */
    Patient 	patient;    	/* Patient to which thread belongs */
    ThreadPtr	thread;	    	/* New thread descriptor */
    LstNode	ln;

    /*
     * Find the Handle and Patient for the patient that owns the thread
     */
    owner = Handle_Lookup(ownerID);
    if (owner == NullHandle) {
	/*
	 * Could have been aborted -- return null for the thread as well.
	 */
	return(NullHandle);
#if 0
	Punt("Couldn't find handle for owner (%04xh) of new thread %04xh",
	     ownerID, id);
#endif
    }

    /*
     * 5/4/94: HACK HACK HACK HACK
     *
     * To allow a very nice optimization in Handle_Lookup and Handle_Patient, we
     * perform an extra Handle_Owner on the owner handle to catch the case
     * where a geode handle was found by address due to showcalls -L *before*
     * the handle owned itself. The handle remains in the table as owned by the
     * geode that's loading the thing. When we do the Handle_Lookup, it doesn't
     * actually refresh the handle's data, nor does Handle_Patient, so we force
     * the data to be refreshed by getting the owner of the owner... -- ardeb
     */
    (void)Handle_Owner(owner);

    patient = Handle_Patient(owner);

    /*
     * Allocate a new ThreadRec for it and initialize the easy parts --
     * the state stack, flags and handle.
     */
    thread = (ThreadPtr)malloc_tagged(sizeof(ThreadRec), TAG_THREAD);

    thread->state = Lst_Init(FALSE);
    thread->flags = IBM_REGS_NEEDED;
    thread->handle = Handle_Create(patient, id,
				   owner,
				   (Address)0,
				   0,
				   HANDLE_THREAD|flags,
				   (Opaque)thread, HANDLE_NOT_XIP);

    realCurThread = thread;
    patient->curThread = (Thread)thread;
    patient->scope = patient->global;
    curPatient = patient;

    /*
     * Find the handle for the block in which the thread's stack resides.
     *
     * NOTE: DO NOT DO THIS IF SS is 0. This implies the thread is the
     * kernel or loader thread and we CANNOT call RPC_BLOCK_FIND if we're not
     * attached. IbmMakeFakeThread will fill in the stack and stackBot fields
     * after we're through.
     */

    if (ss != 0) {
	thread->stack = Handle_Find(MakeAddress(ss, 0));
	thread->stackBot = sp;
    } else {
	thread->stack = NullHandle;
    }

    /*
     * Register interest in the stack so we don't flush its handle when we
     * continue.
     */
    if (thread->stack) {
	Handle_Interest(thread->stack, IbmStackInterest, (Opaque)thread);
    }

    /*
     * Give this thread a number that is one greater than that possessed
     * by any other thread for the patient.
     */
    thread->number = 0;

    for (ln=Lst_First(patient->threads); ln!=NILLNODE; ln=Lst_Succ(ln)) {
	int	n = ((ThreadPtr)Lst_Datum(ln))->number+1;

	if (n > thread->number) {
	    thread->number = n;
	}
    }

    if (notify) {
	MessageFlush("Thread %d created for patient %s\n", thread->number,
		     patient->name);
    }

    /*
     * Append it to the list of threads for the patient.
     */
    Lst_AtEnd(patient->threads, (LstClientData)thread);
    Lst_AtEnd(allThreads, (LstClientData)thread);

    /*
     * Set up the current frame for use by the expression parser, etc., in
     * case EVENT_START dispatch causes us to go back to top-level...
     */
    if (notify) {
	curPatient->frame = MD_CurrentFrame();

	(void)Event_Dispatch(EVENT_START, (Opaque)patient);
    }

    return(thread->handle);
}


/***********************************************************************
 *				Ibm_LoaderMoved
 ***********************************************************************
 * SYNOPSIS:	    Adjust the handles for the loader to account for its
 *	    	    new position in life.
 * CALLED BY:	    Handle module
 * RETURN:	    nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/22/91		Initial Revision
 *
 ***********************************************************************/
void
Ibm_LoaderMoved(word	baseSeg)    /* New base segment of the loader */
{
    int	    i;

    for (i = 1; i < loader->numRes; i++) {
	if (!(loader->resources[i].flags & RESF_READ_ONLY)) {
	    Handle_Change(loader->resources[i].handle,
			  HANDLE_ADDRESS|HANDLE_SIZE,
			  0,
                          MakeAddress(
                              baseSeg,
                              loader->resources[i].offset - exeLoadBase),
//                              (baseSeg<<4) + loader->resources[i].offset - exeLoadBase,
			  loader->resources[i].size,
			  0, -1);
	}
    }
}

/******************************************************************************
 *
 *			  PATIENT INIT/EXIT
 *
 ******************************************************************************/

/***********************************************************************
 *				IbmBiffPatient
 ***********************************************************************
 * SYNOPSIS:	    Nuke the last remnants of a patient
 * CALLED BY:	    IbmGeodeExit, IbmFlushState, IbmNukeAllPatients
 * RETURN:	    Nothing
 * SIDE EFFECTS:    An EXIT event is sent for the patient and the
 *		    patient is transfered from the patients list to the
 *		    dead list.
 *		    defaultPatient will become just a name if patient
 *		    is the default one.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/12/89		Initial Revision
 *
 ***********************************************************************/
static void
IbmBiffPatient(Patient patient)
{
    LstNode	ln, tln;

    IbmDestroyAlias(patient->name);

    if (curPatient == patient) {
	IbmUseDefaultPatient();
    }

    (void)Event_Dispatch(EVENT_EXIT, (Opaque)patient);

    /*
     * Destroy the state for all the patient's threads, if it has any left.
     */
    Lst_Open(patient->threads);
    while ((tln = Lst_Next(patient->threads)) != NILLNODE) {
	ThreadPtr	thread = (ThreadPtr)Lst_Datum(tln);

	if ((patient != loader) || (thread->number != 0)){
	    if (thread->stack) {
		Handle_NoInterest(thread->stack,
				  IbmStackInterest,
				  (Opaque)thread);
	    }

	    Lst_Destroy(thread->state, (void (*)())free);
	    Handle_Free(thread->handle);
	    free((malloc_t)thread);
	    Lst_Remove(patient->threads, tln);
	}
    }
    Lst_Close(patient->threads);

    if (Lst_IsEmpty(patient->threads)) {
	patient->curThread = (Thread)NULL;
    } else {
	patient->curThread =
	    (Thread)Lst_Datum(Lst_First(patient->threads));
    }

    patient->scope = NullSym;

    ln = Lst_Member(patients, (LstClientData)patient);
    Lst_Remove(patients, ln);
    (void)Lst_AtFront(dead, (LstClientData)patient);

    /*
     * Make sure the object file is closed.
     */
    IbmEnsureClosed(patient);

    /*
     * Close the symbol file, so the user can remake the beast in another
     * task/window/whatever. Do this only if this is the final instance of
     * the geode in the system...
     */
    if ((patient->geode.v2 == 0) ||
	IbmFindOtherInstance((GeodeName *)&patient->geode.v2->geodeFileType,
			     patient,
			     (int *)NULL) == NullPatient)
    {
	VMClose(patient->symFile);
    }
    patient->symFile = (Opaque)NULL;

    /*
     * If the patient's a driver, remove it from the array of libraries of the
     * loader.
     */
    if (patient->geode.v2 &&
	  (patient->geode.v2->geodeAttr & GA_DRIVER))
    {
	int 	i;
	int 	j;
	Patient	system = loader;

	for (j = i = 0; i < system->numLibs; i++) {
	    system->libraries[j] = system->libraries[i];
	    if (system->libraries[i] != patient) {
		j++;
	    }
	}
	system->numLibs = j;
    }

    /*
     * If dead patient is the default one, revert defaultPatient to be
     * the patient's name, rather than its handle.
     */
    if (defaultPatient == patient) {
	char *cp = (char *)malloc_tagged(strlen(defaultPatient->name)+1,
					 TAG_PNAME);
	strcpy(cp, defaultPatient->name);
	defaultPatient = (Patient)cp;
    }
}

/***********************************************************************
 *				IbmOpenSymFile
 ***********************************************************************
 * SYNOPSIS:	    Open the patient's symbol file, if possible.
 * CALLED BY:	    IbmOpenObject, IbmLocateCorpse
 * RETURN:	    TRUE if successful
 * SIDE EFFECTS:    patient->symFile set to file handle, if successful
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/ 1/92		Initial Revision
 *
 ***********************************************************************/
static Boolean
IbmOpenSymFile(Patient	patient)
{
    Patient 	    	other;

    if (patient->geode.v2) {
	    other = IbmFindOtherInstance(
			      (GeodeName *)&patient->geode.v2->geodeFileType,
			      patient,
			      (int *)NULL);
    } else {
	other = NullPatient;
    }

    if (other == NullPatient) {
	char	    	*path;
	char	    	*suffix;
	short	    	status;
	ObjHeader   	*hdr;
	VMBlockHandle	map;
	short	    	major, minor;

	path = (char *)malloc(strlen(patient->path)+4+1);
	/*
	 * Form the name for the symbols file and open it first.
	 */
	strcpy(path, patient->path);
	suffix = rindex(path, '.');
	if (!strcmp(suffix, ".geo") || !strcmp(suffix, ".GEO") ||
	    !strcmp(suffix, ".exe") || !strcmp(suffix, ".EXE"))
	{
	    strcpy(suffix, ".sym");
	}
	if (access(path, R_OK) < 0)
	{
	    Warning("Could not find \"%s\"\n", path);
	    free(path);
	    return(FALSE);
	}

	patient->symFile = VMOpen(VMO_OPEN|FILE_DENY_W|FILE_ACCESS_R,
				  0, path, &status);
	if (patient->symFile == NULL) {
	    if (status == EINVAL) {
		Warning("Could not open \"%s\" -- file is damaged\n",
			path);
	    } else {
		Warning("Could not open \"%s\"\n", path);
	    }
	    free(path);
	    return(FALSE);
	}
	malloc_settag(patient->symFile, TAG_VMFILE);

	/*
	 * Make sure the thing's got a compatible symbol file protocol.
	 */

	if (VMGetVersion(patient->symFile) > 1) {
	    GeosFileHeader2 	gfh;

	    VMGetHeader(patient->symFile, (genptr)&gfh);
	    major = swaps(gfh.protocol.major);
	    minor = swaps(gfh.protocol.minor);
	} else {
	    GeosFileHeader  	gfh;

	    VMGetHeader(patient->symFile, (genptr)&gfh);
	    major = swaps(gfh.core.protocol.major);
	    minor = swaps(gfh.core.protocol.minor);
	}

	if ((major != OBJ_PROTOCOL_MAJOR) || (minor > OBJ_PROTOCOL_MINOR)) {
	    Warning("\"%s\" is incompatible with this version of Swat\n", path);
	    VMClose(patient->symFile);
	    free(path);
	    return(FALSE);
	}

	map = VMGetMapBlock(patient->symFile);
	if (map == 0) {
	    VMClose(patient->symFile);
	    return(FALSE);
	}

	hdr = (ObjHeader *)VMLock(patient->symFile, map, (MemHandle *)NULL);
	switch (hdr->magic)
	{
	    case SWOBJMAGIC:
	    	/*
		 * If file was written in the other order, set a relocation
		 * routine for the file so blocks get byte-swapped properly.
		 */
		ObjSwap_Header(hdr);
		VMSetReloc(patient->symFile, ObjSwap_Reloc);
		/* FALLTHRU */
	    case OBJMAGIC:
	    	patient->symfileFormat = SYMFILE_FORMAT_OLD;
		break;
	    case SWOBJMAGIC_NEW_FORMAT:
		ObjSwap_Header(hdr);
		VMSetReloc(patient->symFile, ObjSwap_Reloc_NewFormat);
		/* FALLTHRU */
	    case OBJMAGIC_NEW_FORMAT:
		patient->symfileFormat = SYMFILE_FORMAT_NEW;
		break;
	    default:
		Warning("\"%s\" is not a symbol file\n", path);
		VMUnlock(patient->symFile, map);
		VMClose(patient->symFile);
		free(path);
		return(FALSE);
	}
	VMUnlock(patient->symFile, map);
	free(path);
    } else {
	patient->symFile = other->symFile;
    }

    return(TRUE);
}


/***********************************************************************
 *				IbmLocateCorpse
 ***********************************************************************
 * SYNOPSIS:	    Try and find a dead patient that matches the
 *	    	    given name and serial number.
 * CALLED BY:	    Ibm_NewGeode
 * RETURN:	    The patient handle of the corpse or NullPatient if
 *	    	    none available.
 * SIDE EFFECTS:    If patients of the same name but different serial
 *	    	    number are found on the dead list, they are nuked,
 *	    	    as far as is possible.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/20/89		Initial Revision
 *
 ***********************************************************************/
static Patient
IbmLocateCorpse(Handle	    core,   	    /* Core block handle */
		GeodeName   *gnp,   	    /* Name/Serial # */
		word	    coreID, 	    /* Handle ID of core block */
		Address	    coreAddress,    /* Address of core block */
		int	    coreSize)	    /* Size of... right. */
{
    LstNode 	ln; 	    /* Node in dead list */
    Patient 	patient=0;  /* Current patient */
    int	    	i;  	    /* Counter for locating resource ids */
    Patient 	shared=0;   /* Set non-zero when we encounter the patient
			     * that owns the shared resources for a set
			     * of patient's we're throwing away. */

    (void)Lst_Open(dead);
    while((ln = Lst_Next(dead)) != NILLNODE) {
	patient = (Patient)Lst_Datum(ln);

	if ((patient != loader) &&
	    (bcmp(patient->geode.v2->geodeName,
		  gnp->name,
		  GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE) == 0))
	{
	    if ((patient->geode.v2->geodeSerial != gnp->serial) ||
		!IbmOpenSymFile(patient))
	    {
		/*
		 * Same patient, different edition -- need to free up the
		 * handles to nuke any breakpoints that are lying around.
		 * Unfortunately, we can't nuke much else, as everything's
		 * intertwined with no reference counts. Note that all
		 * old copies of this patient will be nuked in turn, that's
		 * why we can free things up in this way.
		 */

		/*
		 * Let the world know this patient is dead (mostly for
		 * patient-specific breakpoints...)
		 */
		(void)Event_Dispatch(EVENT_DESTROY, (Opaque)patient);

		/*
		 * Free any non-shared resource handles for all versions
		 * of the patient (primary or not). Do first so symFile is
		 * still open when interest procedures called for the handles.
		 *
		 * For any shared resources, we free them only if this is the
		 * patient that owns them.
		 */
		for (i = 1; i < patient->numRes; i++) {
		    if (!(patient->resources[i].flags & RESF_READ_ONLY)) {
			Handle_Free(patient->resources[i].handle);
			patient->resources[i].handle = NullHandle;
		    } else if (Handle_Patient(patient->resources[i].handle) ==
			       patient)
		    {
			shared = patient;
		    }
		}

		/*
		 * Close the object file, if it's open.
		 */
		IbmEnsureClosed(patient);

		/*
		 * Nuke the resources array and mark the patient as
		 * fully toasted.
		 */
		if (patient != shared) {
		    free((malloc_t)patient->resources);
		    patient->resources = NULL;
		    patient->numRes = 0;
		}

		/*
		 * Remove the thing from the dead list
		 */
		(void)Lst_Remove(dead, ln);
		patientsChucked += 1;

		/* if we have send down a new copy of a geode and some its
		 * files are open, then we get screwed, so lets just shut
		 * all files to be safe
		 */
		Cache_InvalidateAll(fileCache, TRUE);
	    } else {
		word	tableOff;

		MessageFlush("Re-using patient %s\n", patient->name);

		/*
		 * Create the handle for the core block so we can use it for
		 * reading. Bit of a kludge, but its symbol is the global
		 * scope...
		 */
		patient->resources[0].handle = patient->core = core;
		patient->core->otherInfo = 0;
		Handle_SetOwner(core, patient);

/* CORE		Handle_Interest(patient->core, IbmCoreInterest,
				(Opaque)patient); */

		/*
		 * Re-initialize the resources. We only call Handle_Reset for
		 * those resources that aren't shared, or for those that
		 * are but have their ID set to 0 (i.e. there is no other
		 * instance of the geode in the system. If there were,
		 * the instances here would have the same Handle so the
		 * ID would be non-zero).
		 */
		Var_FetchInt(2, patient->core,
			     (Address)(offsetof(GeodeHeader2,resHandleOff) -
				       offsetof(GeodeHeader2,geodeHandle)),
			     (genptr)&tableOff);
		for (i = 1; i < patient->numRes; i++) {
		    if (!(patient->resources[i].flags & RESF_READ_ONLY) ||
			(Handle_ID(patient->resources[i].handle) == 0))
		    {
			word    	resid;

			/*
			 * Fetch new ID of resource
			 */
			Var_FetchInt(2, patient->core,
				     (Address)(tableOff+2*i),
				     (genptr)&resid);

			Handle_Reset(patient->resources[i].handle, resid);
		    }
		}
		/*
		 * Re-establish symbol table with newly-open symbol file.
		 */
		Sym_Init(patient);

		/*
		 * Exhume the patient in preparation for its resurrection
		 */
		Lst_Remove(dead, ln);

		/*
		 * XXX This needs to be re-examined.
		 */
		for (i = 0; i < patient->numLibs; i++) {
		    if (patient->libraries[i]->numRes == 0) {
			/*
			 * Library went away -- find the new version of the
			 * same thing. There must be one or this patient
			 * couldn't be active.
			 */
			patient->libraries[i] =
			    Patient_ByName(patient->libraries[i]->name);

			/*
			 * WRONG! The new version could have been ignored,
			 * so we need to check for a null return after all.
			 */
			if (patient->libraries[i] == NULL) {
			    if (i != patient->numLibs-1) {
				bcopy((char *)&patient->libraries[i+1],
				      (char *)&patient->libraries[i],
				      patient->numLibs - (i + 1));
			    }
			    patient->numLibs -= 1;
			}
		    }
		}

		/*
		 * All done.
		 */
		break;
	    }
	}
    }
    Lst_Close(dead);

    /*
     * Deal with nuking shared resources for a patient that's been reloaded.
     */
    if (shared != 0) {
	/*
	 * This is the patient that owns the shared resources,
	 * so we can nuke the various shared data structures
	 *
	 * Free the path and libraries
	 */
	for (i = 1; i < shared->numRes; i++) {
	    if (shared->resources[i].handle != NullHandle) {
		Handle_Free(shared->resources[i].handle);
	    }
	}

	free((malloc_t)shared->resources);
	shared->resources = NULL;
	shared->numRes = 0;

	if (shared->symFile) {
	    VMClose(shared->symFile);
	}
	free(shared->path);
	free((malloc_t)shared->libraries);
    }


    return(ln != NILLNODE ? patient : NullPatient);
}

/***********************************************************************
 *				IbmOpenObject
 ***********************************************************************
 * SYNOPSIS:	    Locate and open the executable for the patient
 * CALLED BY:	    Ibm_NewGeode
 * RETURN:	    TRUE if successful
 * SIDE EFFECTS:    The path and object fields are filled in
 *	    	    If told to detach, we will go back to top level, not
 *	    	    return.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/20/89		Initial Revision
 *
 ***********************************************************************/
Boolean
IbmOpenObject(Patient	    patient,	/* Patient whose object is to be
					 * opened */
	      GeodeName	    *gnp,   	/* Name/Serial number */
	      char  	    *name,  	/* Name as a null-terminated string */
	      word  	    coreID) 	/* Handle ID of core block */
{
    Hash_Entry	    *entry; 	/* Entry into ignored table */

    patient->path = File_FindGeode(name, (unsigned short)swaps(gnp->serial),
				   gnp->fileType, initialized);

    patient->srcRootEnd = 0;

    if (patient->path == (char *)NULL) {
	if (attached == TRUE) {
	    /*
	     * Still attached => user is ignoring this patient.
	     * Enter the name and serial number into the ignored
	     * table so we don't re-prompt.
	     */
	    entry = Hash_CreateEntry(&ignored, (Address)name, NULL);
	    Hash_SetValue(entry, gnp->serial | (coreID << 16));
	}
	return(FALSE);
    } else {
	char	*suffix;

	if (!IbmOpenSymFile(patient)) {
	    return(FALSE);
	}

	/*
	 * Mark the path as being allocated by us (for error-checking)
	 */
	malloc_settag(patient->path, TAG_PNAME);

	/*
	 * Open the file
	 */
	IbmEnsureObject(patient);
	suffix = index(patient->path, '.');
	if (suffix != NULL && strcmp(suffix, gym_ext))
	{
	    gymResources = 0;
	}
	return(TRUE);
    }
}


/***********************************************************************
 *				Ibm_ReadFromObjectFile
 ***********************************************************************
 * SYNOPSIS:	    get info from a geode file one way on another
 * CALLED BY:	    global
 * RETURN:
 * SIDE EFFECTS:
 *
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	8/93		Initial Revision
 *
 ***********************************************************************/
int
Ibm_ReadFromObjectFile(Patient 	patient,    /* patient whose geode to read */
		       word 	size, 	    /* amount of data to read */
		       dword	offset,	    /* offset in file to read from */
		       genptr 	destination, /* buffer to put data in */
		       int  	seektype,   /* file seek type */
		       word 	dataType,   /* type of data to read */
		       word 	dataValue1, /* values depend on data type */
		       word 	dataValue2)
{
    int long bytesRead = 0;
#if defined(_WIN32)
    int tries;
#endif

    if (patient->object == -1)
    {
	/* special case for reading from the very beginning of the file */
	if (offset == 0)
	{
	    destination += sizeof(GeosFileHeader2);
	    size -= sizeof(GeosFileHeader2);
	    offset = sizeof(GeosFileHeader2);
	}
#if defined(_WIN32)
	tries = 0;
    tryagain:
#endif
	if (Rpc_ReadFromGeode(patient, offset, size, dataType, destination,
			      dataValue1, dataValue2) == TCL_ERROR)
	{
#if defined(_WIN32)
	    if ((tries < 4)) {
		if (win32dbg) {
		    if (MessageFlush != NULL) {
			MessageFlush("Problem reading from geode file, "
				     "trying again\n");
		    }
		}
		/*
		 * wait for a second for the communication to quiet down
		 * and hopefully the stub will restabilize
		 */
		sleep(1);
		tries ++;
		goto tryagain;
	    }
#endif
	    if (dataType >= GEODE_DATA_GEODE) {
		MessageFlush("Error in geode read!\n");
	    }

	    return (TCL_ERROR);
	}
    } else {
	(void)FileUtil_Seek(patient->object, offset, seektype);
	(void)FileUtil_Read(patient->object, destination, size, &bytesRead);
    }
    return TCL_OK;
}



/***********************************************************************
 *				Ibm_NewGeode
 ***********************************************************************
 * SYNOPSIS:	    Initialize a new patient based on its core block
 * CALLED BY:	    Handle_Find, Handle_Lookup, IbmConnect
 * RETURN:	    The Handle for the core block.
 * SIDE EFFECTS:    A new Patient is created, initialized and
 *	    	    appended to the  patients  list.
 *
 * STRATEGY:
 *	- Create the Handle for the core block based on the passed info.
 *	- Create a new Patient
 *	- Use the new handle to read the name & type of geode from the PC
 *	- Use the name & type to find the .geo file, setting up the
 *	  rest of the fields required by Ibm_InitPatient.
 *	- Call Ibm_InitPatient.
 *	- If patient is a driver, link it as a library of the loader/kernel.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/15/88	Initial Revision
 *
 ***********************************************************************/
Patient
Ibm_NewGeode(Handle 	core,	    	/* Core block's handle */

	     word	id,	    	/* Handle ID */
	     Address	dataAddress,    /* Absolute address of core block*/
	     int	size)  	    	/* Size of core block */
{
    Patient 	    patient;	    /* New patient */
    GeodeName	    gn;	    	    /* Name/Type data from PC */
    char    	    *cp;    	    /* General char pointer */
    int	    	    n;	    	    /* Number of patients of the given name */
    Patient 	    first;  	    /* First patient of the given name */
    word    	    *handles;  	    /* Table of resource handles */
    dword    	    *offsets;       /* Table of resource offsets */
    word	    *libraries;	    /* Table of library segments */
    word    	    *flags; 	    /* Table of resource allocation flags */
    int	    	    i;  	    /* General index var */
    char    	    name[GEODE_NAME_SIZE+GEODE_NAME_EXT_SIZE+1];
    Hash_Entry	    *entry;
    word    	    realNumRes;
    word	    tableOff;       /* Offset of any table in core block.
				     * Used for fetching resource handle IDs
				     * and imported library segs */

    Lst	    	    *ln;
    long    	    curObjPos;	    /* current position in object file */

    /*
     * Shut off interrupts so all memory reads are deterministic.
     */
    Ui_AllowInterrupts(FALSE);
    /*
     * We can't create a core handle until we have the patient and we don't
     * want to create a Patient handle until we see if we've got a dead one
     * around here, so the read of the name needs to be absolute...
     * 9/5/91:
     * This runs into trouble if the core block is either swapped or is
     * moving on the heap (moving on the heap causes problems anyway; we'll
     * get to that in a moment), as dataAddress will be zero. To deal with
     * this, we don't use Var_Fetch and an absolute address, as we used
     * to, but bypass our data cache to fetch the data with a direct
     * RPC. -- ardeb
     */
    if (!Var_Fetch(typeGeodeName, core,
		   (Address)(offsetof(GeodeHeader2, geodeFileType) -
			     offsetof(GeodeHeader2, geodeHandle)),
		   (genptr)&gn))
    {
	Ui_AllowInterrupts(TRUE);
	return NullPatient;
    }

    /*
     * See if the thing is being ignored. First need to copy the name
     * into  name  and null-terminate it.
     */
    bcopy(gn.name, name, GEODE_NAME_SIZE+GEODE_NAME_EXT_SIZE);
    name[GEODE_NAME_SIZE+GEODE_NAME_EXT_SIZE] = '\0';

    entry = Hash_FindEntry(&ignored, (Address)name);
    if (entry != NULL) {
	if (((int)Hash_GetValue(entry) == -1) ||
	    (gn.serial == (word)((dword)Hash_GetValue(entry) & 0xffff)))
	{
	    /*
	     * Same name, same serial number, same rank...just kidding.
	     * But seriously, this thing's being ignored, so just return
	     * Null now -- don't ask the user again.  Need to update
	     * the entry to hold the current core block ID, though,
	     * in case the user decides to unignore it.
	     */
	    Hash_SetValue(entry, gn.serial | (id << 16));
	    Ui_AllowInterrupts(TRUE);
	    return(NullPatient);
	} else {
	    /*
	     * Old version -- nuke this entry from the table...yes?
	     */
	    Hash_DeleteEntry(&ignored, entry);
	}
    }

    /*
     * See if there's a dead version around
     */
    patient = IbmLocateCorpse(core, &gn, id, dataAddress, size);
    if (patient != NullPatient) {
	(void)Lst_AtEnd(patients, (LstClientData)patient);
	goto done;
    }

    /*
     * No dead version, so we have to make a new one...
     *
     * First, allocate the patient record itself.
     */
    patient = (Patient)calloc_tagged(1, sizeof(*patient), TAG_PATIENT);

    /*
     * Create the handle for the core block so we can use it for reading.
     */
    patient->core = core;
/*CORE    Handle_Interest(patient->core, IbmCoreInterest, (Opaque)patient);*/

    patient->path = (char *)NULL;

    /*
     * Find out how many of this geode are already in the system. The number
     * (0-origin) is left in n. At the same time, we record the first
     * patient of the same name that we encounter so we can snarf the
     * symbol table etc. from it.
     */
    first = IbmFindOtherInstance(&gn, NullPatient, &n);

    for (n = 0, ln=Lst_First(patients); ln != NILLNODE; ln=Lst_Succ(ln)){
	Patient	    thisPatient;

	thisPatient = (Patient)Lst_Datum(ln);
	if ((thisPatient->geode.v2 != 0) &&
	    (!bcmp(thisPatient->geode.v2->geodeName,
		   gn.name,
		   GEODE_NAME_SIZE)))
	{
	    /*
	     * If don't have a patient of this name yet, and this patient's
	     * name matches IN ALL PARTICULARS (i.e. its extension is the same,
	     * too -- need to make the distinction since patient names are
	     * formed just from the permanent name, not the extension, but the
	     * extension is significant in determining which version...),
	     * use the state from this patient later on.
	     */
	    if ((first == NullPatient) &&
		(!bcmp(thisPatient->geode.v2->geodeName,
		       gn.name,
		       GEODE_NAME_SIZE+GEODE_NAME_EXT_SIZE)) &&
		(thisPatient->geode.v2->geodeSerial == gn.serial))
	    {
		first = thisPatient;
	    }
	    n++;
	}
    }

    if (first != NullPatient) {
	/*
	 * Wheee. Steal the relevant fields
	 */
	patient->path = first->path;
	patient->symFile = first->symFile;
	patient->geode = first->geode;
	IbmEnsureObject(patient);
    } else {
	if (!IbmOpenObject(patient, &gn, name, id)) {
	    free((malloc_t)patient);
	    Ui_AllowInterrupts(TRUE);
	    if (attached == FALSE) {
		/*
		 * If no longer attached, we need to get back to the top
		 * level so we stop trying to attach, if that's what we're
		 * doing. If that's not what we're doing, it makes no
		 * difference if we go back to top level -- that's where
		 * we'd end up on our return anyway...
		 */
		Ui_TopLevel();
	    }
	    return(NullPatient);
	}

	/*
	 * Read in the header of the file for later use
	 * XXX: This should probably do more error checking, but I'm tired of
	 * EC code.
	 */
	patient->geode.v2 = (Geode2Ptr)malloc_tagged(sizeof(GeodeHeader2),
							 TAG_PATIENT);
	assert(patient->geode.v2 != (Geode2Ptr)NULL);
	curObjPos = sizeof(GeodeHeader2) - sizeof(GeosFileHeader2);
	if (Ibm_ReadFromObjectFile(patient, sizeof(GeodeHeader2),
			  0, (genptr)patient->geode.v2, SEEK_SET,
			     GEODE_DATA_HEADER, 0, 0) == TCL_ERROR)
	{
	    return NullPatient;
	}
	if (swap) {
	    Var_SwapValue(VAR_FETCH, typeGeodeHeader2,
			      sizeof(GeodeHeader2),
			      (genptr)patient->geode.v2);
	}

	/*
	 * Give this patient the serial number of the thing on the PC, *not*
	 * what comes from the executable, so if the user says to use something
	 * even though the serial number is different, we don't keep asking
	 * about it each time the sap attaches.
	 *  	    -- ardeb 3/8/94
	 */
	patient->geode.v2->geodeSerial = gn.serial;
    }

    /*
     * Remove trailing blanks from the name, ignoring the extension
     */
    for (cp = gn.name + (GEODE_NAME_SIZE-1); *cp == ' ' && cp > gn.name; cp--)
    {
	;
    }

    /*
     * Allocate enough room for the name plus its number, if it'll have any.
     */
    patient->name = (char *)malloc_tagged((cp + 1) - gn.name + ((n>0) ? 4 : 1),
					  TAG_PNAME);

    /*
     * If there's already a copy of this geode in the system, make the name
     * be <geodeName><n>, otherwise just make it <geodeName>.
     */
    if (n > 0) {
	sprintf(patient->name, "%.*s%d", cp - gn.name + 1, gn.name, n+1);
    } else {
	sprintf(patient->name, "%.*s", cp - gn.name + 1, gn.name);
    }

    /*
     * Initialize the tables, etc., we need: threads list, resources table,
     * libraries table.
     */
    patient->threads 	    = Lst_Init(FALSE);
    patient->curThread	    = (Thread)NULL;
    patient->numRes 	    = patient->geode.v2->resCount;

    /* if we are using a gym file then we can only use as many of the
     * resources as the gym file knows about
     */

    realNumRes = patient->numRes;
    if (gymResources > 0 && gymResources < patient->numRes)
    {
	patient->numRes = gymResources;
    }
    gymResources = 0;
    patient->resources 	    = (ResourcePtr)calloc_tagged(patient->numRes,
							 sizeof(ResourceRec),
							 TAG_PATIENT);
    if (first == NullPatient) {
	patient->numLibs    =  patient->geode.v2->libCount;
	patient->libraries  = (Patient *)calloc_tagged(patient->numLibs,
						      sizeof(Patient),
						      TAG_PATIENT);
    } else {
	patient->numLibs    = first->numLibs;
	patient->libraries  = first->libraries;
    }

    Handle_SetOwner(core, patient);

    /*
     * Read the handle table from the patient's core block into  handles .
     */
    handles = (word *)malloc(patient->numRes * sizeof(word));
    Var_FetchInt(2, patient->core,
		 (Address)(offsetof(GeodeHeader2,resHandleOff) -
			   offsetof(GeodeHeader2,geodeHandle)),
		 (genptr)&tableOff);
    Ibm_ReadBytes(patient->numRes * sizeof(word),
		  patient->core, (Address)tableOff,
		  (genptr)handles);

    /*
     * Assign our version of the handles to their proper resource descriptors.
     * Resource 0 is always the core block.
     */
    patient->resources[0].handle = patient->core;
    patient->core->otherInfo = 0;
    for (i = 1; i < patient->numRes; i++) {
	patient->resources[i].handle =
	    Handle_CreateResource(patient, swaps(handles[i]), (unsigned short)i);
    }
    free((malloc_t)handles);

    if (first != NullPatient) {
	/*
	 * Copy the libraries and symbols from the first patient in the list
	 * with the same name
	 */
	Sym_Copy(first, patient);
	for (i = 0; i < patient->numRes; i++) {
	    patient->resources[i].offset = first->resources[i].offset;
	    patient->resources[i].flags = first->resources[i].flags;
	}
    } else {
	/*
	 * Now for imported libraries. Read in the imported-library descriptors
	 * from the patient's core block, find the geode to which those blocks
	 * belong and record their patient handles.
	 */
	if (patient->numLibs != 0) {
	    word    *lp;

	    lp = libraries = (word *)malloc(patient->numLibs * sizeof(word));
	    Var_FetchInt(2, patient->core,
			 (Address)(offsetof(GeodeHeader2,libOffset) -
				   offsetof(GeodeHeader2,geodeHandle)),
			 (genptr)&tableOff);
	    Ibm_ReadBytes(patient->numLibs * sizeof(word),
			  patient->core, (Address)tableOff,
			  (genptr)libraries);

	    for (i = 0; i < patient->numLibs; i++, lp++) {
		Handle	handle;

		/*
		 * Look up the handle stored in the table for this library.
		 */
		handle = Handle_Lookup(swaps(*lp));

		if (handle == NullHandle) {
		    /*
		     * Library being ignored...
		     */
		    i--;		/* Compensate for i++, above */
		    patient->numLibs--;
		} else {
		    /*
		     * Then who owns it
		     */
		    patient->libraries[i] = Handle_Patient(handle);
		}
	    }
	    free((malloc_t)libraries);
	}
	/*
	 * Object file might have gotten flushed by libraries...
	 */
	IbmEnsureObject(patient);
	/*
	 * Read the symbols for the patient now.
	 */
	IbmCheckPatient(patient);
	Sym_Init(patient);
	/*
	 * Now figure out where the various resources lie in the object file.
	 * The swapping of these things is more difficult, as they're
	 * longwords. Ick. However, we don't actually need to query the PC for
	 * the info as it's in the .geo file itself. Hooray.
	 * 7/93: this has now been changed to get the data from the geodes
	 * on the PC itself as we are getting rid of geodes up on the swat
	 * side...jimmy
	 */
	curObjPos = sizeof(GeodeHeader2) +
	      sizeof(ImportedLibraryEntry) * patient->numLibs +
	      4 * patient->geode.v2->exportEntryCount +
	      2 * realNumRes;

	offsets = (dword *)malloc(patient->numRes * sizeof(dword));
	if (Ibm_ReadFromObjectFile(patient, (word)(patient->numRes * sizeof(dword)),
	    			   curObjPos, (genptr)offsets,
				   SEEK_SET, GEODE_DATA_OFFSETS,
				   0, 0) != TCL_ERROR)
	{
	    for (i = 0; i < patient->numRes; i++) {
		if (swap) {
		    dword	d = offsets[i];

		    patient->resources[i].offset = (((d & 0xff) << 24) |
						((d & 0xff00) << 8) |
						((d >> 8) & 0xff00) |
						((d >> 24) & 0xff));
		} else {
		    patient->resources[i].offset = offsets[i];
		}
		/*
		 * In the new filesystem, these offsets do not include the
		 * file header.
		 */
		patient->resources[i].offset += sizeof(GeosFileHeader2);
	    }
	}
	curObjPos += sizeof(dword) * realNumRes;
	free((malloc_t)offsets);
	    /*
	     * Finally, we need to read in the resource allocation flags. These
	     * follow the resource size table, at which the file is currently
	     * positioned. Each size entry is two bytes, so...
	     */
       	flags = (word *)malloc(patient->numRes * 2);
	if (Ibm_ReadFromObjectFile(patient, (word)(patient->numRes * 2),
			    	   curObjPos, (genptr)flags, SEEK_CUR,
				   GEODE_DATA_FLAGS, 0, 0) == TCL_ERROR)
	{
	    free((malloc_t)flags);
	    return NullPatient;
	}
	for (i = 0; i < patient->numRes; i++) {
	    patient->resources[i].flags = swaps(flags[i]);

	    if (patient->resources[i].flags & RESF_READ_ONLY) {
		Handle_MakeReadOnly(patient->resources[i].handle);
	    }
	}
	free((malloc_t)flags);
    }
    patient->scope = patient->global;
    patient->line = -1;
    patient->file = NULL;

    /*
     * Finally let Ibm86 put its hooks into the patient, then add it to the
     * list of known ones.
     */

    /* try adding the patient to the list of patients before Ibm86_Init so
     * that Sym_GetFuncData has a prayer of working with generic symbol files
     * note that I also had to add a call to this before the 'goto done' above
     */
    (void)Lst_AtEnd(patients, (LstClientData)patient);
    Ibm86_Init(patient);

done:

    IbmCreateAlias(patient->name);


    /*
     * If the new patient is a device driver, expand the libraries array for
     * the kernel/loader and place this new patient at the end.
     */
    if ((patient->geode.v2->geodeAttr & GA_DRIVER) ||
	(strcmp(patient->name, "klib") == 0))
    {
	int 	i;
	Patient	system = loader;

	for (i = 0; i < system->numLibs; i++) {
	    if (system->libraries[i] == patient) {
		break;
	    }
	}
	if (i == system->numLibs) {
	    system->numLibs++;
	    system->libraries =
		(Patient *)realloc_tagged((char *)system->libraries,
					  (i+1) * sizeof(Patient));
	    system->libraries[i] = patient;
	}
    }

    /*
     * If the defaultPatient is a name and it matches the patient whose core
     * we're returning, point defaultPatient at this patient instead.
     */
    if (VALIDTPTR(defaultPatient, TAG_PNAME) &&
	strcmp(patient->name, (char *)defaultPatient) == 0)
    {
	free((char *)defaultPatient);
	defaultPatient = patient;
    }

    /*
     * Set so FlushState doesn't biff us...
     */
    patient->patientPriv = NullOpaque;

    Ui_AllowInterrupts(TRUE);
    /*
     * Tell the world this thing's around.
     */

    /* if its the kernel, wait until we are ready, do the Event_Dispatch in
     * IbmKernelLoaded
     */
    if (strcmp(patient->name, "geos")) {
	(void)Event_Dispatch(EVENT_START, (Opaque)patient);
    }

    return(patient);
}

/*****************************************************************************
 *
 *		       CONNECTION/DISCONNECTION
 *
 ****************************************************************************/

/***********************************************************************
 *				IbmSizeKData
 ***********************************************************************
 * SYNOPSIS:	    Interest procedure for init code. Notices when the
 *	    	    code is discarded and resizes kdata to match its
 *	    	    final size.
 * CALLED BY:	    Handle module
 * RETURN:	    Nothing
 * SIDE EFFECTS:    kernel->core will change size if status is
 *	    	    HANDLE_DISCARD.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/18/89		Initial Revision
 *
 ***********************************************************************/
static void
IbmSizeKData(Handle 	    kinit,
	     Handle_Status  status,
	     Opaque 	    junk)
{
    if (status == HANDLE_DISCARD) {
	Sym	    	sym;	    /* For lastHandle variable */
	Address 	offset;	    /* Offset of same */
	word    	lastHandle; /* Final value of same */

	/*
	 * Locate the lastHandle variable
	 */
	sym = Sym_Lookup("lastHandle", SYM_VAR, kernel->global);
	assert(!Sym_IsNull(sym));
	Sym_GetVarData(sym, NULL, NULL, &offset);

	/*
	 * Fetch its value
	 */
	assert(Var_FetchInt(2, kernel->core, offset, (genptr)&lastHandle));

	/*
	 * Adjust kdata's size accordingly
	 */
	Handle_Change(kernel->core, HANDLE_SIZE, 0, (Address)0,
		      	    	    	lastHandle, 0, -1);

	/*
	 * Nuke this procedure's interest in the handle
	 */
	Handle_NoInterest(kinit, IbmSizeKData, NULL);
    }
}

#if 0
/***********************************************************************
 *				IbmConnect
 ***********************************************************************
 * SYNOPSIS:	    Initialize connection w/pc (Release 1)
 * CALLED BY:	    Ibm_PingPC
 * RETURN:	    TRUE if could
 * SIDE EFFECTS:    patients list is set up.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/11/88	Initial Revision
 *
 ***********************************************************************/
static Boolean
IbmConnect(void)
{
    static HelloArgs1 ha1;    	/* Args for connection call */
    HelloReply1	    *hr1;    	/* Pointer into reply buffer for base info */
    word	    *hg;    	/* Current geode */
    word	    *ht;    	/* Current thread */
    char    	    reply[RPC_MAX_HELLO];
    Sym	    	    sym;    	/* Desired symbol for initializing ha */
    int	    	    i;	    	/* Index for geode and thread setup */
    static struct {
	char	*name;
	word	*storage;
	short	class;
    }	    	    initSyms[] = {
	"HandleTable",	    &ha1.ha1_HandleTable,     	SYM_VAR,
	"currentThread",    &ha1.ha1_currentThread,   	SYM_VAR,
	"geodeListPtr",	    &ha1.ha1_geodeListPtr,    	SYM_VAR,
	"threadListPtr",    &ha1.ha1_threadListPtr,   	SYM_VAR,
	"dosLock",   	    &ha1.ha1_dosLock,  	    	SYM_VAR,
	"heapSem",  	    &ha1.ha1_heapSem, 	    	SYM_VAR,
	"lastHandle",	    &ha1.ha1_lastHandle,	SYM_VAR,
	"BG_initSegment",   &ha1.ha1_initSeg, 	    	SYM_VAR,
	"sysECLevel", 	    &ha1.ha1_sysECLevel,    	SYM_VAR,
	"DebugLoadResource",&ha1.ha1_DebugLoadResource,	SYM_FUNCTION,
	"DebugMemory",	    &ha1.ha1_DebugMemory,	SYM_FUNCTION,
	"DebugProcess",	    &ha1.ha1_DebugProcess,    	SYM_FUNCTION,
	"MemLock",  	    &ha1.ha1_MemLock, 	    	SYM_FUNCTION,
	"EndGeos",  	    &ha1.ha1_EndGeos, 	    	SYM_FUNCTION,
	"BlockOnLongQueue", &ha1.ha1_BlockOnLongQueue,	SYM_FUNCTION,
	"FileReadFar", 	    &ha1.ha1_FileRead,	    	SYM_FUNCTION,
	"FilePosFar", 	    &ha1.ha1_FilePos,	    	SYM_FUNCTION,
    };

    /*
     * The symbol module places the segment offset in the offset field of the
     * resource record for its own use, but we need to get kdata's offset
     * from somewhere (stub could also decode it from the relocation info, but
     * ick).
     */
    ha1.ha1_kdata = SegmentOf(kernel->resources[1].offset - exeLoadBase) ;
    ha1.ha1_bootstrap = bootstrap;

    /*
     * Fetch the offsets of all needed symbols and store them away.
     */
    for (i = 0; i < Number(initSyms); i++) {
	Address	offset;

	sym = Sym_Lookup(initSyms[i].name, initSyms[i].class, kernel->global);
	assert(!Sym_IsNull(sym));

	switch (initSyms[i].class) {
	    case SYM_VAR:
		Sym_GetVarData(sym, NULL, NULL, &offset);
		break;
	    case SYM_FUNCTION:
		Sym_GetFuncData(sym, NULL, &offset, (Type *)NULL);
		break;
	}
	*initSyms[i].storage = (word)offset;
    }

    tryingToAttach = TRUE;

    if (Rpc_Call(RPC_HELLO,
		 sizeof(ha1), typeHelloArgs1, (Opaque)&ha1,
		 sizeof(reply), typeHelloReply1, (Opaque)reply) != RPC_SUCCESS)
    {
	/*
	 * Ibm_PingPC will print why this failed...
	 */

	/*
	 * we are done trying to attach
	 */
	tryingToAttach = FALSE;
	/*
	 * Nope -- don't allow communication
	 */
	attached = FALSE;

	return(FALSE);
    } else {
	char	varVal[16];

	/*
	 * we are done trying to attach
	 */
	tryingToAttach = FALSE;
	/*
	 * Yep -- allow communication
	 */
	attached = TRUE;

	kernelLoaded = TRUE;

	hr1 = (HelloReply1 *)reply;

	stubType = hr1->hr1_stubType;

	Tcl_SetVar(interp, "stub-type", stubNames[stubType], TRUE);

	Tcl_SetVar(interp, "attached", "1", TRUE);

	/*
	 * Set up the address TCL variables from the patient.
	 */
	sprintf(varVal, "%04xh:%04xh", hr1->hr1_sysTablesSeg,
		hr1->hr1_sysTablesOff);
	Tcl_SetVar(interp, "DOSTables", varVal, TRUE);

	sprintf(varVal, "%04xh:0", hr1->hr1_psp);
	Tcl_SetVar(interp, "PSPAddr", varVal, TRUE);

	sprintf(varVal, "%d", hr1->hr1_mask1);
	Tcl_SetVar(interp, "IC1Mask", varVal, TRUE);

	sprintf(varVal, "%d", hr1->hr1_mask2);
	Tcl_SetVar(interp, "IC2Mask", varVal, TRUE);

	sprintf(varVal, "%04xh:%04xh", hr1->hr1_stubSeg,
		hr1->hr1_irqHandlers);
	Tcl_SetVar(interp, "irqhandlers", varVal, TRUE);

	/*
	 * Finish setting up the handles for the kernel. HID_KDATA and
	 * HID_KCODE (resources 0 and 1) are always resident and fixed, but
	 * we needed the hr1_baseSeg to assign them their proper address.
	 *
	 * For HID_KINIT, the segment is discarded if the kernel has been
	 * initialized. Otherwise, it's where the stub says it is and is
	 * resident and discardable (note that Ibm_Init assumes the kernel is
	 * initialized when it sets up kernel resource 2).
	 *
	 * 6/25/91: changed to set the sizes to the initial resource sizes
	 * to deal with people exiting, rather than restarting, after running
	 * a DOS program -- ardeb
	 */
	Handle_Change(kernel->resources[KRES_KDATA].handle,
		      HANDLE_ADDRESS|HANDLE_SIZE,
		      0,
                      MakeAddress(hr1->hr1_baseSeg, (kernel->resources[KRES_KDATA].offset -
				  exeLoadBase),
		      kernel->resources[KRES_KDATA].size,
		      0, -1);
	Handle_Change(kernel->resources[KRES_KCODE].handle,
		      HANDLE_ADDRESS|HANDLE_SIZE,
		      0,
                      MakeAddress(hr1->hr1_baseSeg, (kernel->resources[KRES_KCODE].offset -
				  exeLoadBase)),
		      kernel->resources[KRES_KCODE].size,
		      0, -1);
	Handle_Change(kernel->resources[KRES_KROUT].handle,
		      HANDLE_ADDRESS|HANDLE_SIZE,
		      0,
                      MakeAddress(hr1->hr1_baseSeg, (kernel->resources[KRES_KROUT].offset -
				  exeLoadBase)),
		      kernel->resources[KRES_KROUT].size,
		      0, -1);

	if (hr1->hr1_initSeg) {
	    Handle_Change(kernel->resources[KRES_KINIT].handle,
			  HANDLE_ADDRESS|HANDLE_FLAGS|HANDLE_SIZE,
			  0,
                          MakeAddress(hr1->hr1_baseSeg, 0),
			  kernel->resources[KRES_KINIT].size,
			  HANDLE_MEMORY|HANDLE_KERNEL|HANDLE_IN|HANDLE_DISCARDABLE, -1);
	    /*
	     * Set kdata's size to its static dimension and register an
	     * interest proc for the init code. When the segment is
	     * discarded, we'll fetch the last handle address and size kdata
	     * appropriately.
	     */
	    Handle_Change(kernel->resources[KRES_KDATA].handle,
			  HANDLE_SIZE,
			  0,
			  (Address)0,
			  kernel->resources[KRES_KDATA].size,
			  0, -1);

	    Handle_Interest(kernel->resources[KRES_KINIT].handle,
			    IbmSizeKData,
			    NULL);
	} else {
	    /*
	     * Initialization complete -- size kdata off the handle table
	     */
	    Handle_Change(kernel->resources[KRES_KDATA].handle,
			  HANDLE_SIZE,
			  0,
			  (Address)0,
			  hr1->hr1_lastHandle,
			  0, -1);
	}

	/*
	 * Make the DOS segment cover the whole range from 0x400 to hr1_psp.
	 */
	Handle_Change(kernel->resources[KRES_DOS].handle,
		      HANDLE_SIZE|HANDLE_ADDRESS,
		      0,
                      MakeAddress(0x40, 0),
		      (hr1->hr1_psp - 0x40) << 4,
		      0, -1);

	/*
	 * Set the base address of the PSP segment -- the size is always
	 * 256 bytes and set in Ibm_Init.
	 */
	Handle_Change(kernel->resources[KRES_PSP].handle,
		      HANDLE_ADDRESS,
		      0,
                      MakeAddress(hr1->hr1_psp, 0),
		      0,
		      0, -1);

	if (hr1->hr1_stubSeg < hr1->hr1_baseSeg) {
	    /*
	     * Make the SWAT segment cover the rest (up to the kernel)
	     */
	    Handle_Change(kernel->resources[KRES_SWAT].handle,
			  HANDLE_SIZE|HANDLE_ADDRESS,
			  0,
                          MakeAddress(hr1->hr1_baseSeg, 0),
			  (hr1->hr1_baseSeg - hr1->hr1_stubSeg) << 4,
			  0, -1);
	} else if (stubType == STUB_BSW) {
	    /*
	     * Must be running in high memory -- say it's 64K so we
	     * can access all parts of the trace buffer etc.
	     */
	    Handle_Change(kernel->resources[KRES_SWAT].handle,
			  HANDLE_SIZE|HANDLE_ADDRESS,
			  0,
                          MakeAddress(hr1->hr1_baseSeg, 0),
			  65536,
			  0, -1);
	}

	/*
	 * Tell everyone the kernel has started.
	 */
	Event_Dispatch(EVENT_START, (Opaque)kernel);

	if (!bootstrap) {
	    /*
	     * If not bootstrapping, pay attention to the geode and thread
	     * info returned by the stub (shouldn't be any if bootstrapping,
	     * but what the heck...).
	     */
	    for (i = hr1->hr1_numGeodes, hg = (word *)(hr1+1);
		 i > 0;
		 i--, hg++)
	    {
		(void)Handle_Lookup(swaps(*hg));
	    }

	    /*
	     * Now handle all the extant threads. The thread list begins with
	     * the youngest thread, but we want to number from the oldest, so
	     * we run through the thread descriptors in reverse order.
	     */
	    for (i = hr1->hr1_numThreads,
		 ht = ((word *)hg)+hr1->hr1_numThreads-1;
		 i > 0;
		 i--, ht--)
	    {
		Handle_Lookup(swaps(*ht));
	    }
	}

	/*
	 * If kernel finished initializing, the curThread we get back
	 * from the stub is valid (and may not be the kernel :)
	 */
	if (!hr1->hr1_initSeg) {
	    IbmSetCurPatient(hr1->hr1_curThread);
	} else {
	    IbmSetCurPatient(0);
	}

	/*
	 * Make sure the SKIPBPT flag and friends are cleared.
	 */
	sysFlags &= ~(PATIENT_RUNNING|PATIENT_SKIPBPT|PATIENT_BREAKPOINT|PATIENT_STOP);
	sysFlags |= PATIENT_STOPPED;

	/*
	 * Tell the world we're attached
	 */
	(void)Event_Dispatch(EVENT_ATTACH, NullOpaque);

	return(TRUE);
    }
}

#endif

/***********************************************************************
 *				IbmNukeAllPatients
 ***********************************************************************
 * SYNOPSIS:	    Biff all remaining patients and threads
 * CALLED BY:	    IbmDisconnect, IbmDosRun
 * RETURN:	    Nothing
 * SIDE EFFECTS:    All existing threads are biffed, except the main
 *	    	    kernel/loader thread, and all patients but the loader are
 *	    	    placed on the dead list.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/27/90		Initial Revision
 *
 ***********************************************************************/
static void
IbmNukeAllPatients(int preserveSystem)
{
    LstNode	ln, tln;
    Patient 	patient;

    for (ln = Lst_Last(patients); ln != NILLNODE; ln = tln) {
	tln = Lst_Pred(ln);
	patient = (Patient)Lst_Datum(ln);
	if (!patient->dos) {
	    IbmBiffPatient(patient);
	}
    }

    /*
     * Re-initialize the patients list, taking the kernel/loader off the
     * dead list and putting it back on the patients list, so we've some
     * context to work with.
     */
    patient = loader;
    if (Lst_IsEmpty(loader->threads)) {
        (void)Lst_AtEnd(loader->threads, (LstClientData)loaderThread);
    }
    kernel = NULL;

    ln = Lst_Member(dead, (LstClientData)patient);
    assert(ln != NILLNODE);
    Lst_Remove(dead, ln);

    (void)Lst_AtEnd(patients, (LstClientData)patient);
    if (!IbmOpenSymFile(patient)) {
	Punt("Couldn't re-open %s's symbol file", "loader");
    }
    /*
     * Re-establish symbol table with newly-open symbol file.
     */
    Sym_Init(patient);

    /*
     * Nuke the list of all threads, then re-create it and stuff the
     * kernel/loader thread on it.
     */
    Lst_Destroy(allThreads, NOFREE);
    allThreads = Lst_Init(FALSE);
    (void)Lst_AtEnd(allThreads,
		    Lst_Datum(Lst_First(loader->threads)));
}

/***********************************************************************
 *				IbmDisconnect
 ***********************************************************************
 * SYNOPSIS:	    Disconnect from the PC, sending it a final RPC
 * CALLED BY:	    IbmDetachCmd, IbmSysExit, Ibm_Stop, Ibm_LostContact
 * RETURN:	    Nothing
 * SIDE EFFECTS:    All patients are placed on the dead list.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 6/89		Initial Revision
 *
 ***********************************************************************/
void
IbmDisconnect(Rpc_Proc	procNum)    /* Procedure to call to tell the PC to
				     * go away. 0 means don't call anything.
				     * -1 means don't actually detach, just
				     * close everything down and leave us
				     * with the loader */
{
    int 	i, j;
    /*
     * XXX: What if machine is running (waitForPatient was 0)?
     */

#if defined(_MSDOS)
    /*
     * make sure timeouts are enabled so we don't get stuck here doing an
     * rpc call trying to contact the target machine.
     */
    rpcDebug &= ~RD_NO_TIMEOUT;
#endif

    /*
     * Tell everyone we're going away... This flushes everything to the PC.
     */

    if (procNum != 0) {
	(void)Event_Dispatch(EVENT_DETACH, NullOpaque);
    }

    IbmNukeAllPatients(FALSE);

    /*
     * Reset current patient to be the kernel/loader and nuke all drivers
     * except those patients created with dossym.
     */

    curPatient = loader;
    realCurThread =
	(ThreadPtr)(curPatient->curThread =
		    (Thread)Lst_Datum(Lst_First(loader->threads)));
    for (j = i = 0; i < loader->numLibs; i++) {
	if (loader->libraries[i]->dos) {
	    loader->libraries[j++] = loader->libraries[i];
	}
    }
    loader->numLibs = j;

    /*
     * All breakpoints should have been disabled by now, so tell everyone
     * the thing is continuing (and flush all state), then send the message
     * we were told to send to the stub.
     */
    if (procNum != 0) {
	(void)Event_Dispatch(EVENT_CONTINUE, CONTINUE_DETACH);
    }
    if (procNum != (Rpc_Proc)-1) {
	if (procNum != 0) {
	    Rpc_Exit(procNum);
	}
	(void)Rpc_Disconnect(procNum == RPC_EXIT);

	/*
	 * Signal a lack of attachment (fear of commitment?)
	 */
	Tcl_SetVar(interp, "attached", "0", TRUE);


	/* reset xip stuff in case we reattach to a non-XIP system */
	curXIPPage = realXIPPage = HANDLE_NOT_XIP;
	Tcl_SetVar(interp, "curXIPPage", "-1", TRUE);

	attached = FALSE;
#if defined(SETUP)
	needSetup = 1;
#endif
    }
}



/***********************************************************************
 *				IbmMakeFakeThread
 ***********************************************************************
 * SYNOPSIS:	    Create the kernel/loader thread.
 * CALLED BY:	    Ibm_PingPC, IbmKernelLoaded
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The kernel thread is created and its stack and
 *		    stackBot fields are filled in correctly.
 *
 * STRATEGY:
 *	The problem here is that when the kernel thread is created, we
 *	don't know where kdata actually lies, so we need to artificially
 *	fill in the stack field of the kernel thread with kdata, then
 *	go questing for "endStack", since we don't have the current SP
 *	(nor would it help in all cases, as the kernel thread might not
 *	be running when we attach).
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/20/89		Initial Revision
 *
 ***********************************************************************/
static void
IbmMakeFakeThread(Patient   patient,	/* Patient for which to make the fake
					 * thread */
		  word 	    id)	    	/* Handle ID for the beast */
{
    ThreadPtr	kthread;
    dword   	offset;

    Ibm_NewThread(id, Handle_ID(patient->core), 0, 0, FALSE, HANDLE_KERNEL);
    patient->curThread = (Thread)Lst_Datum(Lst_First(patient->threads));
    kthread = (ThreadPtr)patient->curThread;

    if (patient->geode.v2 != NULL) {
	/*
	 * If it's a geode, the stack is in dgroup, also known as resource #1.
	 */
	word	udataSize;

	IbmEnsureObject(patient);
	offset = offsetof(ExecutableFileHeader2, udataSize);

	Ibm_ReadFromObjectFile(patient, sizeof(udataSize), offset,
			       (char *)&udataSize, SEEK_SET,
			       GEODE_DATA_UDATA_SIZE, 0, 0);
	if (swap) {
	    udataSize = swaps(udataSize);
	}
	kthread->stackBot =
		(patient->resources[1].size + udataSize + 15) & ~0xf;
	kthread->stack = patient->resources[1].handle;
    } else {
	/*
	 * Else it's a .exe file and the end of the stack can be found by
	 * determining the size of the STACK-type segment.
	 * XXX: can also just use the initial SP stored in the exe header.
	 */
	VMBlockHandle	map;
	ObjHeader   	*hdr;
	ObjSegment  	*seg;
	int 	    	i;

	map = VMGetMapBlock(patient->symFile);
	hdr = (ObjHeader *)VMLock(patient->symFile, map, (MemHandle *)NULL);
	seg = (ObjSegment *)(hdr+1);

	for (i = 0; i < hdr->numSeg; seg++) {
	    if (seg->type == SEG_STACK) {
		kthread->stackBot = seg->size;
		break;
	    } else if (seg->type != SEG_LIBRARY) {
		i++;
	    }
	}
	kthread->stack = patient->resources[i].handle;
	VMUnlock(patient->symFile, map);
    }
}


/***********************************************************************
 *				IbmInitKernel
 ***********************************************************************
 * SYNOPSIS:	    Initialize the kernel patient once the object and
 *	    	    symbol files have been opened
 * CALLED BY:	    Ibm_PingPC
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The resources record has its handles filled in...
 *	    	    Symbols for the kernel are read in.
 *	    	    Kernel thread created
 *	    	    Kernel made current patient
 *	    	    File offsets for resources determined.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/21/89		Initial Revision
 *
 ***********************************************************************/
void
IbmInitKernel(void)
{
    static struct {
	word	    id;
	Address	    addr;
	int 	    size;
	int 	    flags;
    }	    kres[] = {
    {   HID_KDATA, (Address)0, 	    	    0, 	HANDLE_FIXED|HANDLE_PROCESS },
    { 	HID_KCODE, (Address)0, 	    	    0, 	HANDLE_FIXED },
    {	HID_KROUT, (Address)0,	    	    0,	HANDLE_FIXED },
    { 	HID_KINIT, (Address)0,	    	    0, 	HANDLE_DISCARDABLE|HANDLE_DISCARDED },
    {	HID_DOS,   (Address)0,  	    0,	HANDLE_FIXED },
    {	HID_SWAT,  (Address)0,	    	    0, 	HANDLE_FIXED },
    {	HID_BIOS,  (Address)0xf0000,  0x10000,	HANDLE_FIXED|HANDLE_IN },
    {	HID_PSP,   (Address)0,	    	  256,	HANDLE_FIXED },
    };
    int	    i;

    /*
     * Initialize resources[KRES_KDATA].handle to Null so we can use it as the
     * owner in the loop (Handle_Create takes a Null owner as meaning it
     * owns itself)
     */
    kernel->resources[KRES_KDATA].handle = NullHandle;

    for (i = 0; i < Number(kres); i++) {
	kernel->resources[i+1].handle =
	    Handle_Create(kernel,
			  kres[i].id,
			  kernel->resources[KRES_KDATA].handle,
			  kres[i].addr,
			  kres[i].size,
			  kres[i].flags|HANDLE_KERNEL|HANDLE_MEMORY,
			  (Opaque)(i+1), HANDLE_NOT_XIP);
    }

    /*
     * Make resource 0 into the kernel's core block (that's where the kernel
     * stack is...). Note that the symbol stays the same, however...just
     * thought I'd throw that in, point that out, etc.
     */

    kernel->core = kernel->resources[0].handle =
	kernel->resources[KRES_KDATA].handle;

    kernel->geode.v1 = (GeodePtr)NULL;

    kernel->threads = Lst_Init(FALSE);
    kernel->curThread = (Thread)NULL;
    kernel->name = "geos";

    /*
     * Set initial patient in case kernel not initialized
     */
    curPatient = kernel;
    kernel->scope = kernel->global;
    kernel->line = -1;


    /*
     * Read in the symbol table
     */
    Sym_Init(kernel);

    /*
     * Create the kernel thread.
     */
    IbmMakeFakeThread(kernel, HID_KTHREAD);
    realCurThread = (ThreadPtr)kernel->curThread;

    /*
     * Indicate handle sizes for the three modules of the kernel. The
     * size field of the resource record is filled in by Sym_Init. Note that
     * kdata's size is set by IbmConnect().
     */
    Handle_Change(kernel->resources[KRES_KCODE].handle, HANDLE_SIZE,
		  0,
		  (Address)0,
		  kernel->resources[KRES_KCODE].size,
		  0, -1);
    Handle_Change(kernel->resources[KRES_KROUT].handle, HANDLE_SIZE,
		  0,
		  (Address)0,
		  kernel->resources[KRES_KROUT].size,
		  0, -1);
    Handle_Change(kernel->resources[KRES_KINIT].handle, HANDLE_SIZE,
		  0,
		  (Address)0,
		  kernel->resources[KRES_KINIT].size,
		  0, -1);
}

/******************************************************************************
 *	    	    	    	    	    	    	    	    	      *
 *			     RPC HANDLERS				      *
 *									      *
 *****************************************************************************/

/***********************************************************************
 *				IbmHalt
 ***********************************************************************
 * SYNOPSIS:	    Field an RPC_HALT call
 * CALLED BY:	    Rpc module
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Yes.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/15/88	Initial Revision
 *
 ***********************************************************************/
static void
IbmHalt(Rpc_Message 	msg,
	int 	    	dataLen,
	Rpc_Opaque  	data,
	Rpc_Opaque  	clientData)
{
    HaltArgs	    *ha = (HaltArgs *)data;
    ThreadPtr	    cur;
    const char 	    *why;
    char    	    stopCode[20];
    Boolean 	    stayStopped;

    IbmSetCurXIPPage(ha->ha_curXIPPage);
    IbmSetCurPatient(ha->ha_thread);
    cur = (ThreadPtr)curPatient->curThread;

    cur->regs = ha->ha_regs;
    cur->regs.reg_xipPage = ha->ha_curXIPPage;
    cur->flags &= ~(IBM_REGS_NEEDED|IBM_REGS_DIRTY);

    /*
     * Acknowledge the call
     */
    Rpc_Return(msg, 0, (Rpc_Opaque)NULL);

    if (sysFlags & PATIENT_RUNNING) {
	stayStopped = FALSE;
    } else {
	stayStopped = TRUE;
    }
    /*
     * Adjust flags to reflect machine's current state
     */
    sysFlags &= ~(PATIENT_SKIPBPT|PATIENT_RUNNING|PATIENT_BREAKPOINT);
    sysFlags |= PATIENT_STOPPED;

    /*
     * Decode the current frame and change to the proper directory
     * in case we remain stopped.
     */
    curPatient->frame = MD_CurrentFrame();
    (void)IbmSetDir();

    if ((ha->ha_reason == RPC_HALT_BPT) &&
	(Event_Dispatch(EVENT_STOP,
			(Opaque)&stayStopped)!=EVENT_NOT_HANDLED) &&
	!stayStopped &&
	!Ui_Interrupt())
    {
	/*
	 * Send the continue message only if machine isn't running already.
	 */
	if (! (sysFlags & PATIENT_RUNNING)) {
	    Ibm_Continue();
	}
	return;
    } else if (ha->ha_reason != RPC_HALT_BPT) {
	(void)Event_Dispatch(EVENT_INT, (Opaque)(dword)ha->ha_reason);
	if (sysFlags & PATIENT_RUNNING) {
	    return;
	}
    }

    /*
     * If event not handled (the stop was unexpected) or the breakpoint
     * should be taken (stayStopped is set), or the machine stopped for
     * some reason other than a breakpoint, keep it stopped.
     */

    if (ha->ha_reason < Number(stopCodes)) {
	why = stopCodes[ha->ha_reason];
    } else {
	sprintf(stopCode, "Interrupt %d", ha->ha_reason);
	why = (const char *)stopCode;
    }

    Tcl_SetVar(interp, "lastHaltCode", why, TRUE);

    if (!noFullStop) {
	/*
	 * Machine staying stopped -- notify everyone of the fact, giving
	 * the reason as the piece of data.
	 */
	Event_Dispatch(EVENT_FULLSTOP, (Opaque)why);

	/*
	 * If actually keeping the thing stopped, abort any calls we have
	 * in progress and go back to the top level.
	 */
/*	    Rpc_Abort();*/
	/*Ui_TopLevel();*/
    }
}

/***********************************************************************
 *				IbmSpawnCommon
 ***********************************************************************
 * SYNOPSIS:	    Common code to handle a call that a geode's been
 *	    	    spawned.
 * CALLED BY:	    IbmSpawn, IbmKernelLoaded
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Geode be spawned...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/24/91		Initial Revision
 *
 ***********************************************************************/
static void
IbmSpawnCommon(SpawnArgs    *sa)
{
    sysFlags &= ~(PATIENT_RUNNING|PATIENT_BREAKPOINT|PATIENT_STOP|PATIENT_SKIPBPT);
    sysFlags |= PATIENT_STOPPED;

    if (sa->sa_sp != 0) {
	Ibm_NewThread(sa->sa_thread, sa->sa_owner, sa->sa_ss, sa->sa_sp, TRUE,
		      0);
    } else {
	Handle	h;

	/*
	 * Driver/Library load -- need to look up the handle and its Patient
	 * record and dispatch a START event after setting up the curPatient
	 * and realCurThread in case the machine remains stopped.
	 * 6/4/91 -- START event now dispatched by Ibm_NewGeode where necessary.
	 */
	/*
	 * First setup the current thread.
	 * 6/4/91 -- we don't do this if it's the kernel being spawned (the
	 * current thread remains the loader) to prevent ugly things from
	 * happening should the current thread be executing in non-kernel
	 * code when we attach, in which case MD_CurrentFrame() could well
	 * attempt to refer to something in the geode, which would cause us
	 * to attempt to load symbols etc. for the geode before having loaded
	 * those for the kernel. That way madness lies... -- ardeb
	 */
	if (kernelLoaded) {
	    IbmSetCurPatient(sa->sa_thread);
	    curPatient->frame = MD_CurrentFrame();
	}

	/*
	 * Now lookup the handle of the library/driver -- forces the symbols
	 * to be read in as well.
	 */
	h = Handle_Lookup(sa->sa_owner);
	/*
	 * 5/4/94: force the handle to be validated, so we know who really
	 * owns it, in case the handle was found during the geode-load
	 * process when it didn't own itself... -- ardeb.
	 */
	if (h != NullHandle) {
	    (void)Handle_Owner(h);
	}
    }
}

/***********************************************************************
 *				IbmSpawnFinish
 ***********************************************************************
 * SYNOPSIS:	Finish off a spawn, replying (finally) to the message
 *	    	that caused this all, notifying everyone, etc.
 * CALLED BY:	IbmSpawn, IbmKernelLoaded
 * RETURN:	nothing
 * SIDE EFFECTS:reply message sent, EVENT_CONTINUE maybe sent,
 *	    	RPC_INTERRUPT maybe sent.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/27/91		Initial Revision
 *
 ***********************************************************************/
static void
IbmSpawnFinish(Rpc_Message  	msg,	    /* Message to which to reply */
	       const char   	*name)      /* Name of patient just spawned */
{
    /*
     * If no one wants it to stay stopped, and the beast isn't running already,
     * tell folks the patient's continuing and send back the return value for
     * the KERNEL_LOADED rpc.
     */
    if (((sysFlags & PATIENT_STOP) == 0) && (sysFlags & PATIENT_STOPPED)) {
	/*
	 * Handle implied continue...
	 */
implied_continue:
	(void)Event_Dispatch(EVENT_CONTINUE, CONTINUE_HALF);

	sysFlags &= ~PATIENT_STOPPED;
	sysFlags |= PATIENT_RUNNING;
    } else if (sysFlags & PATIENT_STOPPED) {
	/*
	 * Machine hasn't been continued yet, so send it an RPC_INTERRUPT
	 * to tell it to stay stopped once we return from the
	 * RPC_KERNEL_LOADED
	 */
	word	threadID;

	if (Rpc_Call(RPC_INTERRUPT,
		     0, NullType, (Opaque)0,
		     sizeof(threadID), type_Word,
		     (Opaque)&threadID) != RPC_SUCCESS)
	{
	    Warning("Couldn't keep the PC stopped: %s", Rpc_LastError());
	    goto    implied_continue;
	}
	if (!noFullStop) {
	    char	*spmsg;

	    spmsg = (char *)malloc(strlen(name) + sizeof(" spawned"));

	    sprintf(spmsg, "%s spawned", name);

	    Event_Dispatch(EVENT_FULLSTOP, (Opaque)spmsg);
	    free(spmsg);
	}
    }
    Rpc_Return(msg, 0, (Opaque)NULL);
}

/***********************************************************************
 *				IbmSpawn
 ***********************************************************************
 * SYNOPSIS:	    Handle the spawning of a new thread.
 * CALLED BY:	    Rpc module
 * RETURN:	    Nothing
 * SIDE EFFECTS:    New Patient may be created. New ThreadRec definitely
 *	    	    is.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/15/88	Initial Revision
 *
 ***********************************************************************/
static void
IbmSpawn(Rpc_Message	msg,
	 int	    	len,
	 Rpc_Opaque 	data,
	 Rpc_Opaque 	clientData)
{
    Patient patient;
    Handle  handle;

    IbmSetCurXIPPage(((SpawnArgs *)data)->sa_xipPage);
    IbmSpawnCommon((SpawnArgs *)data);

    /* changed this to actually get the name of the new patient rather than
     * the name of the current patient as, if the new patient does not have
     * its own thread, it won't become the current patient in SpawnCommon and
     * thus its name won't be displayed properly
     * - jimmy, 5/94
     */
    handle = Handle_Lookup(((SpawnArgs *)data)->sa_owner);
    if (handle != NullHandle) {
	patient = Handle_Patient(handle);
    } else {
	patient = curPatient;
    }
    IbmSpawnFinish(msg, patient->name);
}


/*********************************************************************
 *			IbmSetCurXIPPage
 *********************************************************************
 * SYNOPSIS: 	set the current xip page
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	5/18/94		Initial version
 *
 *********************************************************************/
void
IbmSetCurXIPPage(word xipPage)
{
    char    curXIPPageBuf[8];

    realXIPPage = curXIPPage = xipPage;
    assert(VALID_XIP(curXIPPage));
    sprintf(curXIPPageBuf, "%d", xipPage);
    Tcl_SetVar(interp, "curXIPPage", curXIPPageBuf, TRUE);
}


/*********************************************************************
 *			IbmSetup
 *********************************************************************
 * SYNOPSIS: 	    to the RPC_HELLO call
 * CALLED BY:	    IbmKernelLoaded/Ibm_NewGeode
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	7/19/93		Initial version
 *
 *********************************************************************/
static int
IbmSetup(Patient kernel)
{
    if (Rpc_Call(RPC_SETUP, Type_Sizeof(type_Void), type_Void, "",
		 sizeof(kernelInternalSymbols), typeSetupReplyArgs,
		 (Opaque)&kernelInternalSymbols) != RPC_SUCCESS)
    {
	return RPC_CANTSEND;
    }
#if defined(SETUP)
    needSetup = 0;
#endif
    return RPC_SUCCESS;
}

/*********************************************************************
 *			IbmHello
 *********************************************************************
 * SYNOPSIS: 	    to the RPC_HELLO call
 * CALLED BY:	    IbmKernelLoaded/Ibm_NewGeode
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	7/19/93		Initial version
 *
 *********************************************************************/
static int
IbmHello(void)
{
    static  HelloArgs	ha;

    int	    	    	i;
    HelloReply	    *hr;    	/* Pointer into reply buffer for base info */
    word	    *hg;    	/* Current geode */
    word	    *ht;    	/* Current thread */
    char    	    reply[RPC_MAX_HELLO];
    char    	    kv[5];

#if defined(SETUP)
    if (needSetup)
    {
	IbmSetup(kernel);
    }
#endif
    /*
     * Figure resource ID for kcode
     */
    for (i = 1; i < kernel->numRes; i++)
    {
	if (strcmp(Sym_Name(kernel->resources[i].sym), "kcode") == 0)
	{
	    kcodeResID = i;
	    break;
	}
    }

    IbmSetup(kernel);
    ha.ha_bootstrap = bootstrap;
    if (Rpc_Call(RPC_HELLO,
		 sizeof(ha), typeHelloArgs, (Opaque)&ha,
		 sizeof(reply), typeHelloReply, (Opaque)reply) != RPC_SUCCESS)
    {
	return RPC_CANTSEND;
    }
	/*
	 * Now process the reply we got back.
	 */
    hr = (HelloReply *)reply;

    IbmSetCurXIPPage(hr->hr_curXIPPage);

    sprintf(kv, "%d", hr->hr_kernelVersion);
    Tcl_SetVar(interp, "kernelVersion", kv, TRUE);

    if (!bootstrap)
    {
	/*
	 * If not bootstrapping, pay attention to the geode and thread
	 * info returned by the stub (shouldn't be any if bootstrapping,
	 * but what the heck...).
	 */
	for (i = hr->hr_numGeodes, hg = (word *)(hr+1);
	     i > 0;
	     i--, hg++)
	{
	    (void)Handle_Lookup(swaps(*hg));
	}

	/*
	 * Now handle all the extant threads. The thread list begins with
	 * the youngest thread, but we want to number from the oldest, so
	 * we run through the thread descriptors in reverse order.
	 */
	for (i = hr->hr_numThreads,
	     ht = ((word *)hg)+hr->hr_numThreads-1;
	     i > 0;
	     i--, ht--)
	{
	    Handle_Lookup(swaps(*ht));
	}
    }

    /*
     * Make the current thread the one we got back from the stub.
     */
    IbmSetCurPatient(hr->hr_curThread);

    return RPC_SUCCESS;
}

/***********************************************************************
 *				IbmKernelLoaded
 ***********************************************************************
 * SYNOPSIS:	    Initialize connection w/pc, telling it  all sorts of
 *	    	    neat secrets about the kernel.
 * CALLED BY:	    Ibm_Init, IbmConnectCmd
 * RETURN:	    TRUE if could
 * SIDE EFFECTS:    patients list is set up.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/11/88	Initial Revision
 *
 ***********************************************************************/
static void
IbmKernelLoaded(Rpc_Message 	msg,
		int 	    	dataLen,
		Rpc_Opaque  	data,
		Rpc_Opaque  	clientData)
{
    int	    	    i;	    	/* Index for geode and thread setup */
    ThreadPtr	    thread;
    LstNode 	    ln;

    /*
     * If loader not initialized yet, we probably died before and the poor
     * person is attempting to reattach while the stub is spewing
     * KERNEL_LOADED calls...
     */
    if (!loaderInitialized || kernel != 0) {
	Rpc_Error(msg, RPC_NOPROC);
	return;
    }


    /*
     * Handle the creation of the kernel itself. First say the current
     * thread is the loader's fake one.
     */
    ((SpawnArgs *)data)->sa_thread =
	Handle_ID(((ThreadPtr)Lst_Datum(Lst_First(loader->threads)))->handle);
    IbmSpawnCommon((SpawnArgs *)data);
    kernel = (Patient)Lst_Datum(Lst_Last(patients));
    if (strcmp(kernel->name, "loader") == 0) {
	MessageFlush("Kernel not found.  Make sure it isn't ignored.\n");
	abort();
    }
    kernelLoaded = TRUE;

    /*
     * Create the kernel scheduler thread if the kernel has no threads yet.
     */
    if (Lst_IsEmpty(kernel->threads)) {
	IbmMakeFakeThread(kernel, HID_KTHREAD);
    }

    IbmSetCurPatient(HID_KTHREAD);
    thread = (ThreadPtr)kernel->curThread;

    if (!(((ThreadPtr)loader->curThread)->flags & IBM_REGS_NEEDED)) {
	/*
	 * Copy all registers from the loader thread (if it has them). The
	 * reg_xipPage is garbage until the kernel is actually loaded, so
	 * initialize it to something viable.
	 */
	thread->regs = ((ThreadPtr)loader->curThread)->regs;
	thread->regs.reg_xipPage = HANDLE_NOT_XIP;
	thread->flags &= ~IBM_REGS_NEEDED;
    }

    kernel->frame = MD_CurrentFrame();

    /*
     * Nuke the loader's thread so it doesn't get in the user's way.
     */
    ln = Lst_First(loader->threads);
    Lst_Remove(loader->threads, ln);
    ln = Lst_Member(allThreads, (LstClientData)loaderThread);
    Lst_Remove(allThreads, ln);

    /*
     * Now ship all the real segments for the loader out to never-never
     * land so they don't interfere with our lookup of segments during
     * the processing of the HelloReply.
     */
    for (i = 1; i < loader->numRes; i++) {
	if (!(loader->resources[i].flags & RESF_READ_ONLY)) {
	    Handle_Change(loader->resources[i].handle,
			  HANDLE_ADDRESS|HANDLE_FLAGS,
			  0,    /* ID */
			  0,    /* Address (=> nuked) */
			  0,    /* Size */
			  HANDLE_KERNEL|HANDLE_MEMORY|HANDLE_DISCARDED|HANDLE_DISCARDABLE, -1);   /* flags */
	}
    }

    if (IbmHello() != RPC_SUCCESS)
    {
	Warning("Could not contact PC: %s", Rpc_LastError());
	Rpc_Return(msg, 0, (Rpc_Opaque)NULL);
	return;
    }
    (void)Event_Dispatch(EVENT_START, (Opaque)kernel);
    IbmSpawnFinish(msg, "geos");
}

/***********************************************************************
 *				IbmThreadDestroy
 ***********************************************************************
 * SYNOPSIS:	    Handle the exit of a thread
 * CALLED BY:	    Rpc module
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Yes.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/15/88	Initial Revision
 *
 ***********************************************************************/
static void
IbmThreadDestroy(Rpc_Message	msg,
	      int		len,
	      Rpc_Opaque	data,
	      Rpc_Opaque 	clientData)
{
    LstNode 		ln;    	    	/* General list node */
    ThreadExitArgs	*tea;  	    	/* Real version of data */
    Handle  		handle;	    	/* Handle that's exiting (thread or
					 * core block) */
    Patient 		patient;    	/* Patient that's exiting */

    tea = (ThreadExitArgs *)data;
    handle = Handle_Lookup(tea->tea_handle);

    if (handle == NullHandle) {
	/*
	 * No need to issue the continue event (dangerous to do so anyway since
	 * we probably don't have curPatient->curThread set up correctly)
	 * since "nothing has changed", though Handle_Lookup may have done
	 * things.... This should never happen anyway :) [does happen
	 * if the dude ignores something that later dies, but c'est la vie]
	 */
	goto ret;
    } else {
	/*
	 * Switch to thread that's exiting
	 */
	IbmSetCurPatient(tea->tea_handle);
	patient = curPatient;

	/*
	 * Locate the node for the thread in the patient's threads list
	 */
	ln = Lst_Member(curPatient->threads, (LstClientData)realCurThread);

	assert (ln != NILLNODE);

	/*
	 * Remove the thread now so we can re-use ln later
	 */
	Lst_Remove(curPatient->threads, ln);

	/*
	 * Note that thread is gone so IbmFlushState will destroy it
	 */
	realCurThread->flags |= IBM_THREAD_GONE;

	MessageFlush("Thread %d of %s exited %d\n", realCurThread->number,
		     patient->name, tea->tea_status);
    }
    /*
     * Now tell everyone the machine is continuing.
     */
    (void)Event_Dispatch(EVENT_CONTINUE, CONTINUE_HALF);

ret:
    /*
     * And tell the machine to continue
     */
    Rpc_Return(msg, 0, (Opaque)0);
}


/***********************************************************************
 *				IbmGeodeExit
 ***********************************************************************
 * SYNOPSIS:	    Handle the exit of a geode
 * CALLED BY:	    Rpc module
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Yes.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/15/88	Initial Revision
 *
 ***********************************************************************/
static void
IbmGeodeExit(Rpc_Message	msg,
	     int		len,
	     Rpc_Opaque		data,
	     Rpc_Opaque 	clientData)
{
    GeodeExitArgs	*gea;  	    	/* Real version of data */
    Handle  		handle;	    	/* Handle that's exiting (thread or
					 * core block) */
    Patient 		patient;    	/* Patient that's exiting */

    gea = (GeodeExitArgs *)data;
    handle = Handle_Lookup(gea->gea_handle);

    if (handle == NullHandle) {
	/*
	 * No need to issue the continue event (dangerous to do so anyway since
	 * we probably don't have curPatient->curThread set up correctly)
	 * since "nothing has changed", though Handle_Lookup may have done
	 * things.... This should never happen anyway :) [does happen
	 * if the dude ignores something that later dies, but c'est la vie]
	 */
	goto ret;
    } else {
	/*
	 * Switch to the current thread.
	 */
	IbmSetCurPatient(gea->gea_curThread);

	/*
	 * Tell the world this geode is going away
	 */
	patient = Handle_Patient(handle);

	MessageFlush("%s exited.\n", patient->name);

	if (Lst_IsEmpty(patient->threads)) {
	    /*
	     * If there are no threads for the patient, we can biff the thing
	     */
	    IbmBiffPatient(patient);
	} else {
	    /*
	     * Mark the patient as needing biffing.
	     */
	    patient->patientPriv = (Opaque)1;
	}
    }

    /*
     * It's somewhat unsanitary to leave the current patient a corpse,
     * as various nasty things can happen (e.g. if the user, who shall remain
     * nameless, downloads a new version of the patient via the network
     * and restarts it, causing the old Patient [which is still curPatient]
     * to decompose in a big way, leading the VM file handle to be re-used
     * as a scroll buffer line, causing instant death when a breakpoint
     * address is looked up in said scope...).
     */
    IbmUseDefaultPatient();

    /*
     * Now tell everyone the machine is continuing.
     */
    (void)Event_Dispatch(EVENT_CONTINUE, CONTINUE_HALF);

ret:
    /*
     * And tell the machine to continue
     */
    Rpc_Return(msg, 0, (Opaque)0);
}

/***********************************************************************
 *				IbmSysExit
 ***********************************************************************
 * SYNOPSIS:	    Handle the exit of GEOS itself
 * CALLED BY:	    Rpc_Wait
 * RETURN:	    Nothing
 * SIDE EFFECTS:    attached is set FALSE and all patients are placed
 *	    	    on the dead list.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 6/89		Initial Revision
 *
 ***********************************************************************/
static void
IbmSysExit(Rpc_Message	msg,
	   int		len,
	   Rpc_Opaque	data,
	   Rpc_Opaque 	clientData)
{
    const char	*autoDetach;

    /*
     * Set the current patient to the kernel/loader and set the current frame
     * so commands work as they should.
     */
    IbmSetCurPatient(LOADER_THREAD_ID);
    curPatient->frame = MD_CurrentFrame();

    if (VALIDTPTR(defaultPatient,TAG_PATIENT)) {
	/*
	 * If default patient is a real patient, save its name for use when
	 * we re-attach
	 */
	char	*cp;

	cp = (char *)malloc_tagged(strlen(defaultPatient->name)+1, TAG_PNAME);
	strcpy(cp, defaultPatient->name);
	defaultPatient = (Patient)cp;
    }

    /*
     * Notify everyone of the exit of GEOS.
     */
    (void)Event_Dispatch(EVENT_FULLSTOP, (Opaque)"GEOS Exited");

    Rpc_Return(msg, 0, (Rpc_Opaque)NULL);

    /*
     * See if the autodetach variable is defined. If it is and it's 0,
     * we will remain attached until the user tells us to detach.
     */
    autoDetach = Tcl_GetVar(interp, "autodetach", TRUE);
    if (!strcmp(autoDetach, "") || atoi(autoDetach)) {
	/*
	 * Disconnect and tell the stub to go away. No reply is required.
	 */
	IbmDisconnect(RPC_EXIT);

	/*
	 * Go back to top-level
	 */
	noFullStop = 0;
	Ui_TopLevel();
    } else {
	/*
	 * Remember that everything's gone, but don't actually detach from
	 * the PC.
	 */
	IbmDisconnect(-1);
	sysFlags &= ~(PATIENT_SKIPBPT|PATIENT_RUNNING|PATIENT_BREAKPOINT|PATIENT_STOP);
	sysFlags |= PATIENT_STOPPED;
    }
}

/***********************************************************************
 *				IbmReloadSys
 ***********************************************************************
 * SYNOPSIS:	    System is about to be reloaded after running an
 *	    	    application under DOS -- set up as if for
 *	    	    initialization.
 * CALLED BY:	    RPC_RELOAD_SYS
 * RETURN:	    Nothing
 * SIDE EFFECTS:    kinit is "reloaded" and kdata shrunk to its
 *	    	    original size, with an interest procedure registered
 *	    	    for discard of kinit to size it properly.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 2/89	Initial Revision
 *
 ***********************************************************************/
static void
IbmReloadSys(Rpc_Message    msg,
	     int	    len,
	     Rpc_Opaque	    data,
	     Rpc_Opaque     clientData)
{
    word    	kseg = *(word *)data;

    Ibm_LoaderMoved(kseg);

    (void)Event_Dispatch(EVENT_RELOAD, NullOpaque);

    /*
     * Tell world machine is continuing so any breakpoints in kinit get
     * installed...
     */
    (void)Event_Dispatch(EVENT_CONTINUE, CONTINUE_HALF);

    Rpc_Return(msg, 0, (Rpc_Opaque)NULL);
}


/***********************************************************************
 *				IbmDosRun
 ***********************************************************************
 * SYNOPSIS:	    Take note that GEOS is leaving to run a DOS app.
 * CALLED BY:	    RPC_DOS_RUN
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Segments are biffed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/23/90		Initial Revision
 *
 ***********************************************************************/
static void
IbmDosRun(Rpc_Message	msg,
	  int	    	len,
	  Rpc_Opaque	data,
	  Rpc_Opaque    clientData)
{
/*    word	size = *(word *)data;	why don't we care about the size
					anymore? */

    IbmNukeAllPatients(TRUE);

    /*
     * Reset current patient to be the kernel/loader and nuke all drivers
     */
    curPatient = loader;
    realCurThread =
	(ThreadPtr)(curPatient->curThread =
			(Thread)Lst_Datum(Lst_First(curPatient->threads)));
    curPatient->numLibs = 0;

    /*
     * All breakpoints should have been disabled by now, so tell everyone the
     * thing is continuing (and flush all state), then send a reply to the
     * message that got us going...
     */
    (void)Event_Dispatch(EVENT_CONTINUE, CONTINUE_HALF);

    Rpc_Return(msg, 0, (Opaque)NULL);
}

/***********************************************************************
 *				IbmReset
 ***********************************************************************
 * SYNOPSIS:	    Deal with a return to top level
 * CALLED BY:	    EVENT_RESET
 * RETURN:	    EVENT_HANDLED
 * SIDE EFFECTS:    noFullStop set to 0
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/18/89		Initial Revision
 *
 ***********************************************************************/
static int
IbmReset(Event event, Opaque callData, Opaque clientData)
{
    noFullStop = 0;

    if (realCurThread == NULL) {
	/*
	 * This can happen if someone stops the machine in the handle routines
	 * (e.g. from a handle interest procedure) immediately after a
	 * thread has exited -- realCurThread remains NULL from IbmFlushState.
	 * We've no way to fetch the actual current patient (the stub has
	 * overwritten the thing) so we just pretend it's the kernel...
	 */
	Warning("Current thread can't be determined -- using kernel thread");
	IbmUseDefaultPatient();
    }

    /*XXX*/
    IbmCheckPatient(curPatient);

    return(EVENT_HANDLED);
}



/***********************************************************************
 *				IbmCreateTypes
 ***********************************************************************
 * SYNOPSIS:	    Create the type descriptions used for communication
 *	    	    with the PC.
 * CALLED BY:	    Ibm_Init
 * RETURN:	    nothing
 * SIDE EFFECTS:    the external type* variables are filled in and their
 *	    	    type descriptions registered with the garbage collector
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/16/91		Initial Revision
 *
 ***********************************************************************/
static void
IbmCreateTypes(void)
{
    typeSegAddr =
	Type_CreatePackedStruct("offset", type_Word,
				"segment", type_Word,
				(char *)0);
    GC_RegisterType(typeSegAddr);

    typeIbmRegs =
	Type_CreatePackedStruct("reg_regs",
				Type_CreateArray(0, REG_NUM_REGS-1,
						 type_Int,
						 type_Word),
				"reg_ip", type_Word,
#if REGS_32
                                "reg_flags", type_Long,
#else
                                "reg_flags", type_Word,
#endif
				"reg_xipPage", type_Word,
				(char *)0);
    GC_RegisterType(typeIbmRegs);

    typeHaltArgs =
	Type_CreatePackedStruct("ha_regs", typeIbmRegs,
				"ha_reason", type_Word,
				"ha_thread", type_Word,
				"ha_curXIPPage", type_Word,
				(char *)0);
    GC_RegisterType(typeHaltArgs);

    typeMaskArgs =
	Type_CreatePackedStruct("ma_PIC1", type_Byte,
				"ma_PIC2", type_Byte,
				(char *)0);
    GC_RegisterType(typeMaskArgs);

    typeCallArgs =
	Type_CreatePackedStruct("ca_thread", type_Word,
				"ca_offset", type_Word,
				"ca_segment", type_Word,
				(char *)0);
    GC_RegisterType(typeCallArgs);

    typeStepReply =
	Type_CreatePackedStruct("sr_regs", typeIbmRegs,
				"sr_thread", type_Word,
				"sr_curXIPPage", type_Word,
				(char *)0);
    GC_RegisterType(typeStepReply);

    typeReadArgs =
	Type_CreatePackedStruct("ra_offset", type_Word,
				"ra_handle", type_Word,
				"ra_numBytes", type_Word,
				(char *)0);
    GC_RegisterType(typeReadArgs);

    typeWriteArgs =
	Type_CreatePackedStruct("wa_offset", type_Word,
				"wa_handle", type_Word,
				(char *)0);
    GC_RegisterType(typeWriteArgs);

    typeFillArgs =
	Type_CreatePackedStruct("fa_offset", type_Word,
				"fa_handle", type_Word,
				"fa_numBytes", type_Word,
				"fa_value", type_Word,
				(char *)0);
    GC_RegisterType(typeFillArgs);

    typeIOWArgs =
	Type_CreatePackedStruct("iow_port", type_Word,
				"iow_value", type_Word,
				(char *)0);
    GC_RegisterType(typeIOWArgs);

    typeAbsReadArgs =
	Type_CreatePackedStruct("ara_offset", type_Word,
				"ara_segment", type_Word,
				"ara_numBytes", type_Word,
				(char *)0);
    GC_RegisterType(typeAbsReadArgs);

    typeAbsWriteArgs =
	Type_CreatePackedStruct("awa_offset", type_Word,
				"awa_segment", type_Word,
				(char *)0);
    GC_RegisterType(typeAbsWriteArgs);

    typeAbsFillArgs =
	Type_CreatePackedStruct("afa_offset", type_Word,
				"afa_segment", type_Word,
				"afa_numBytes", type_Word,
				"afa_value", type_Word,
				(char *)0);
    GC_RegisterType(typeAbsFillArgs);

    typeSpawnArgs =
	Type_CreatePackedStruct("sa_thread", type_Word,
				"sa_owner", type_Word,
				"sa_ss", type_Word,
				"sa_sp", type_Word,
				"sa_xipPage", type_Word,
				(char *)0);
    GC_RegisterType(typeSpawnArgs);

    typeThreadExitArgs =
	Type_CreatePackedStruct("tea_handle", type_Word,
				"tea_status", type_Word,
				(char *)0);
    GC_RegisterType(typeThreadExitArgs);

    typeGeodeExitArgs =
	Type_CreatePackedStruct("gea_handle", type_Word,
				"gea_curThread", type_Word,
				(char *)0);
    GC_RegisterType(typeGeodeExitArgs);

#if 0
    typeHelloArgs1 =
	Type_CreatePackedStruct("ha1_kdata", type_Word,
				"ha1_bootstrap", type_Word,
				"ha1_HandleTable", type_Word,
				"ha1_currentThread", type_Word,
				"ha1_geodeListPtr", type_Word,
				"ha1_threadListPtr", type_Word,
				"ha1_dosLock", type_Word,
				"ha1_heapSem", type_Word,
				"ha1_lastHandle", type_Word,
				"ha1_initSeg", type_Word,
				"ha1_sysECLevel", type_Word,
				"ha_DebugLoadResource", type_Word,
				"ha_DebugMemory", type_Word,
				"ha_DebugProcess", type_Word,
				"ha_MemLock", type_Word,
				"ha_EndGeos", type_Word,
				"ha_BlockOnLongQueue", type_Word,
				"ha_FileRead", type_Word,
				"ha_FilePos", type_Word,
				(char *)0);
    GC_RegisterType(typeHelloArgs1);
#endif

    typeHelloArgs =
	Type_CreatePackedStruct("ha_bootstrap", type_Word,
				"ha_currentThread", type_Word,
				(char *)0);
    GC_RegisterType(typeHelloArgs);

    typeSetupReplyArgs =
	Type_CreatePackedStruct(
				"sa_kernelHasTable", type_Word,
				"sa_tableSize", type_Word,
				"sa_currentThread", type_Word,
				"sa_geodeListPtr", type_Word,
				"sa_threadListPtr", type_Word,
				"sa_dosLock", type_Word,
				"sa_heapSem", type_Word,
				"sa_DebugLoadResource", type_Word,
				"sa_DebugMemory", type_Word,
				"sa_DebugProcess", type_Word,
				"sa_MemLock", type_Word,
				"sa_EndGeos", type_Word,
				"sa_BlockOnLongQueue", type_Word,
				"sa_FileRead", type_Word,
				"sa_FilePos", type_Word,
				"sa_sysECBlock", type_Word,
				"sa_sysECChecksum", type_Word,
				"sa_sysECLevel", type_Word,
				"sa_systemCounter", type_Word,
				"sa_errorFlag", type_Word,
				"sa_ResourceCallInt", type_Word,
				"sa_ResourceCallInt_end", type_Word,
				"sa_FatalError", type_Word,
				"sa_FatalError_end", type_Word,
				"sa_SendMessage", type_Word,
				"sa_SendMessage_end", type_Word,
				"sa_CallFixed", type_Word,
				"sa_CallFixed_end", type_Word,
				"sa_ObjCallMethodTable", type_Word,
				"sa_ObjCallMethodTable_end", type_Word,
				"sa_CallMethodCommonLoadESDI", type_Word,
				"sa_CallMethodCommonLoadESDI_end", type_Word,
				"sa_ObjCallMethodTableSaveBXSI", type_Word,
				"sa_ObjCallMethodTableSaveBXSI_end", type_Word,
				"sa_CallMethodCommon", type_Word,
				"sa_CallMethodCommon_end", type_Word,
				"sa_MessageDispatchDefaultCallBack", type_Word,
				"sa_MessageDispatchDefaultCallBack_end", type_Word,
				"sa_MessageProcess", type_Word,
				"sa_MessageProcess_end", type_Word,
				"sa_OCCC_callInstanceCommon", type_Word,
				"sa_OCCC_callInstanceCommon_end", type_Word,
				"sa_OCCC_no_save_to_test", type_Word,
				"sa_OCCC_no_save_to_test_end", type_Word,
				"sa_OCCC_save_no_test", type_Word,
				"sa_OCCC_save_no_test_end", type_Word,
				"sa_Idle", type_Word,
				"sa_Idle_end", type_Word,
				"sa_curXIPPage", type_Word,
				"sa_MapXIPPageFar", type_Word,
				"sa_MAPPING_PAGE_SIZE", type_Word,
				"sa_MAPPING_PAGE_ADDRESS", type_Word,
				(char *)0);
    GC_RegisterType(typeSetupReplyArgs);
#if 0
    typeHelloReply1 =
	Type_CreatePackedStruct("hr_baseSeg", 	    type_Word,
				"hr_initSeg", 	    type_Word,
				"hr_stubSeg", 	    type_Word,
				"hr_stubType", 	    type_Byte,
				"hr_pad",   	    type_Byte,
				"hr_numGeodes",     type_Word,
				"hr_numThreads",    type_Word,
				"hr_curThread",     type_Word,
				"hr_lastHandle",    type_Word,
				"hr_sysTablesOff",  type_Word,
				"hr_sysTablesSeg",  type_Word,
				"hr_psp",   	    type_Word,
				"hr_mask1", 	    type_Byte,
				"hr_mask2", 	    type_Byte,
				"hr_irqHandlers",   type_Word,
				(char *)0);
    GC_RegisterType(typeHelloReply1);
#endif
    typeHelloReply =
	Type_CreatePackedStruct("hr_numGeodes",     type_Word,
				"hr_numThreads",    type_Word,
				"hr_curThread",     type_Word,
				"hr_kernelVersion", type_Word,
				"hr_curXIPPage",    type_Word,
				(char *)0);
    GC_RegisterType(typeHelloReply);

    typeIconToken =
	Type_CreatePackedStruct("chars",
				  Type_CreateArray(0, 4-1, type_Int,
							type_Char),
				"manufID", type_Word,
				(char *)0);
    GC_RegisterType(typeIconToken);

    typeGeosFileHeaderCore =
	Type_CreatePackedStruct("signature",
				  Type_CreateArray(0, 3, type_Int, type_Char),
				"type", type_Word,
				"flags", type_Word,
				"release",
				  Type_CreateArray(0, 3, type_Int, type_Word),
				"protocol",
				  Type_CreateArray(0, 1, type_Int, type_Word),
				"token", typeIconToken,
				"creator", typeIconToken,
				"longName",
				  Type_CreateArray(0,GFH_LONGNAME_BUFFER_SIZE-1,
						   type_Int, type_Char),
				(char *)0);
    GC_RegisterType(typeGeosFileHeaderCore);

    typeGeosFileHeader =
	Type_CreatePackedStruct("core", typeGeosFileHeaderCore,
				"userNotes",
				  Type_CreateArray(0, 100-1, type_Int,
							type_Char),
				"reserved",
				  Type_CreateArray(0, 32-1, type_Int,
							type_Char),
				(char *)0);
    GC_RegisterType(typeGeosFileHeader);


    typeExecutableFileHeader =
	Type_CreatePackedStruct("geosFileHeader", typeGeosFileHeader,
				"attributes", type_Word,
				"fileType", type_Word,
				"kernelProtocol",
				  Type_CreateArray(0, 1, type_Int, type_Word),
				"resourceCount", type_Word,
				"importLibraryCount", type_Word,
				"exportEntryCount", type_Word,
				"udataSize", type_Word,
				"classOffset", type_Word,
				"classSegment", type_Word,
				"appObjChunkHandle", type_Word,
				"appObjResource", type_Word,
				(char *)0);
    GC_RegisterType(typeExecutableFileHeader);

    typeGeodeHeader =
	Type_CreatePackedStruct("execHeader", typeExecutableFileHeader,
				"geodeHandle", type_Word,
				"geodeAttributes", type_Word,
				"geodeFileType", type_Word,
				"geodeRelease",
				  Type_CreateArray(0, 3, type_Int, type_Word),
				"geodeProtocol",
				  Type_CreateArray(0, 1, type_Int, type_Word),
				"geodeSerial", type_Word,
				"geodeName",
				Type_CreateArray(0, GEODE_NAME_SIZE-1,
						 type_Int, type_Char),
				"geodeNameExt",
				Type_CreateArray(0, GEODE_NAME_EXT_SIZE-1,
						 type_Int, type_Char),
				"geodeToken", typeIconToken,
				"geodeRefCount", type_Word,
				"driverTableOffset", type_Word,
				"driverTableHandle", type_Word,
				"libraryEntryOffset", type_Word,
				"libraryEntryHandle", type_Word,
				"exportLibTabOff", type_Word,
				"exportEntryCnt", type_Word,
				"libraryCount", type_Word,
				"libraryOffset", type_Word,
				"resourceCount", type_Word,
				"resourceHandleOff", type_Word,
				"resourcePosOff", type_Word,
				"resourceRelocOff", type_Word,
				(char *)0);
    GC_RegisterType(typeGeodeHeader);

    typeGeosFileHeader2 =
	Type_CreatePackedStruct("signature",
				  Type_CreateArray(0, 3, type_Int, type_Char),
				"longName",
				  Type_CreateArray(0,GFH_LONGNAME_BUFFER_SIZE-1,
						   type_Int, type_Char),
				"type", type_Word,
				"flags", type_Word,
				"release",
				  Type_CreateArray(0, 3, type_Int, type_Word),
				"protocol",
				  Type_CreateArray(0, 1, type_Int, type_Word),
				"token", typeIconToken,
				"creator", typeIconToken,
				"userNotes",
				  Type_CreateArray(0, GFH_USER_NOTES_SIZE-1,
						   type_Int, type_Char),
				"notice",
				  Type_CreateArray(0, GFH_RESERVED_SIZE-1,
						   type_Int, type_Char),
				"createdDate", type_Word,
				"createdTime", type_Word,
				"password",
				 Type_CreateArray(0, FILE_PASSWORD_SIZE-1,
						  type_Int, type_Char),
				"desktop",
				 Type_CreateArray(0, FILE_DESKTOP_INFO_SIZE-1,
						  type_Int, type_Byte),
				"reserved",
				 Type_CreateArray(0, FILE_FUTURE_USE_SIZE-1,
						  type_Int, type_Byte),

				(char *)0);
    GC_RegisterType(typeGeosFileHeader2);


    typeExecutableFileHeader2 =
	Type_CreatePackedStruct("geosFileHeader", typeGeosFileHeader2,
				"attributes", type_Word,
				"fileType", type_Word,
				"unused",
				  Type_CreateArray(0, 1, type_Int, type_Word),
				"resourceCount", type_Word,
				"importLibraryCount", type_Word,
				"exportEntryCount", type_Word,
				"udataSize", type_Word,
				"classOffset", type_Word,
				"classSegment", type_Word,
				"appObjChunkHandle", type_Word,
				"appObjResource", type_Word,
				(char *)0);
    GC_RegisterType(typeExecutableFileHeader2);

    typeGeodeHeader2 =
	Type_CreatePackedStruct("execHeader", typeExecutableFileHeader2,
				"geodeHandle", type_Word,
				"geodeAttributes", type_Word,
				"geodeFileType", type_Word,
				"geodeRelease",
				  Type_CreateArray(0, 3, type_Int, type_Word),
				"geodeProtocol",
				  Type_CreateArray(0, 1, type_Int, type_Word),
				"geodeSerial", type_Word,
				"geodeName",
				Type_CreateArray(0, GEODE_NAME_SIZE-1,
						 type_Int, type_Char),
				"geodeNameExt",
				Type_CreateArray(0, GEODE_NAME_EXT_SIZE-1,
						 type_Int, type_Char),
				"geodeToken", typeIconToken,
				"geodeRefCount", type_Word,
				"driverTableOffset", type_Word,
				"driverTableHandle", type_Word,
				"libraryEntryOffset", type_Word,
				"libraryEntryHandle", type_Word,
				"exportLibTabOff", type_Word,
				"exportEntryCnt", type_Word,
				"libraryCount", type_Word,
				"libraryOffset", type_Word,
				"resourceCount", type_Word,
				"resourceHandleOff", type_Word,
				"resourcePosOff", type_Word,
				"resourceRelocOff", type_Word,
				(char *)0);
    GC_RegisterType(typeGeodeHeader2);

    typeGeodeName =
	Type_CreatePackedStruct("fileType", type_Word,
				"release",
				  Type_CreateArray(0, 3, type_Int, type_Word),
				"protocol",
				  Type_CreateArray(0, 1, type_Int, type_Word),
				"serial", type_Word,
				"name",
				Type_CreateArray(0, GEODE_NAME_SIZE-1,
						 type_Int, type_Char),
				"ext",
				Type_CreateArray(0, GEODE_NAME_EXT_SIZE-1,
						 type_Int, type_Char),
				(char *)0);
    GC_RegisterType(typeGeodeName);

    typeWriteRegsArgs =
	Type_CreatePackedStruct("wra_thread", type_Word,
				"wra_regs", typeIbmRegs,
				(char *)0);
    GC_RegisterType(typeWriteRegsArgs);
#if 0
    typeBeepReply1 =
	Type_CreatePackedStruct("br1_csum", type_Word,
				"br1_rev", type_Word,
				(char *)0);
    GC_RegisterType(typeBeepReply1);
#endif
    typeBeepReply =
	Type_CreatePackedStruct("br_csum", type_Word,
				"br_rev", type_Word,
				"br_baseSeg", type_Word,
				"br_stubSeg", type_Word,
				"br_stubSize", type_Word,
				"br_stubType", type_Byte,
				"br_kernelLoaded", type_Byte,
				"br_sysTablesOff",  type_Word,
				"br_sysTablesSeg",  type_Word,
				"br_psp",   	    type_Word,
				"br_mask1", 	    type_Byte,
				"br_mask2", 	    type_Byte,
				"br_irqHandlers",   type_Word,
				(char *)0);
    GC_RegisterType(typeBeepReply);

    typeReadXmsMemArgs =
	Type_CreatePackedStruct("RXMA_size",           type_Long,
				"RXMA_sourceOffset",   type_Long,
				"RXMA_sourceHandle",   type_Word,
				"RXMA_procSegment",    type_Word,
				"RXMA_procOffset",     type_Word,
				(char *)0);
    GC_RegisterType(typeReadXmsMemArgs);
}


/***********************************************************************
 *				IbmFindLRes
 ***********************************************************************
 * SYNOPSIS:	    Find the resource ID of a module of the loader.
 * CALLED BY:	    Ibm_PingPC, ?
 * RETURN:	    0 if no such resource exists, else its ID (index
 *	    	    into kernel->resources)
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/16/91		Initial Revision
 *
 ***********************************************************************/
int
IbmFindLRes(const char    *name)
{
    int	    i;

    for (i = loader->numRes - 1; i > 0; i--) {
	if (Sym_IsNull(loader->resources[i].sym))
	{
	    continue;
	}
	if (strcmp(Sym_Name(loader->resources[i].sym), name) == 0) {
	    break;
	}
    }
    return(i);
}

/***********************************************************************
 *				Ibm_PingPC
 ***********************************************************************
 * SYNOPSIS:	    Send a BEEP to the PC to see if it's around, then
 *	    	    set up symbol information for the loader, assuming
 *	    	    the kernel's not there. If that's wrong, well, we'll
 *	    	    find out soon enough, won't we?
 *
 * CALLED BY:	    Ibm_Init, IbmConnectCmd
 * RETURN:	    TRUE if we were able to ping the PC.
 * SIDE EFFECTS:    lots.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/16/91		Initial Revision
 *
 ***********************************************************************/
Boolean
Ibm_PingPC(Boolean initialized)	    /* TRUE if Swat's been fully initialized */
{
    BeepReply	br; 	    /* Answer from stub for RPC_BEEP */
    char	varVal[16];
    word    	ocsum;
    int	    	i;
    word	    	headerSize; /* Size of .exe header (w/relocations) */
    Boolean	returnVal;

#if defined(_MSDOS)
    /* make sure timeouts are enabled so we don't get stuck here doing an
     * rpc call trying to contact the target machine which may not be there.
     */
    rpcDebug &= ~RD_NO_TIMEOUT;
#endif

    /*
     * Save so we know when to re-read things.
     */
    ocsum = kcsum;

    /*
     * Reconnect the RPC system.
     */
    tryingToAttach = TRUE;
    loaderInitialized = kernelLoaded = FALSE;
    returnVal = Rpc_Connect();
    if (returnVal == FALSE) {
	goto	attach_error;
    }

    /* do this here, before the beep, otherwise things are not good! */
    if (Rpc_ReadFromGeode(loader, (dword)EXE_HEADERSIZE_OFF,
			  sizeof(headerSize), GEODE_DATA_LOADER,
			    (char *)&headerSize, 0, 0) == TCL_ERROR)
    {
	Tcl_RetPrintf(interp, "Can't contact GEOS: %s", Rpc_LastError());
	goto	attach_error;
    }
    /*
     * See if the stub's alive and get the loader's checksum so we know which
     * one to look for...
     */
    if (Rpc_Call(RPC_BEEP, 0, NullType, NullOpaque,
		 sizeof(br), typeBeepReply, (Opaque)&br) != RPC_SUCCESS)
    {
	Tcl_RetPrintf(interp, "Cannot contact GEOS: %s", Rpc_LastError());
attach_error:
	tryingToAttach = FALSE;
	/*
	 * Let the connection go.
	 */
	(void)Rpc_Disconnect(1);
	return(FALSE);
    } else if (br.br_rev != RPC_REVISION) {
	if (br.br_rev != RPC_REVISION1) {
	    Tcl_RetPrintf(interp,
			  "Can't deal with PC: version mismatch (stub revision level %d, should be %d (for v2.0) or %d (for v1.X))",
			  br.br_rev, RPC_REVISION, RPC_REVISION1);
attach_error_goodbye:
	    Rpc_Exit(RPC_GOODBYE);
	    goto attach_error;
	} else {
	    /* no longer support 1.X */
	    assert(0);
	}

    }

#if GEOS32
    if (!br.br_stubType & STUB_GEOS32)  {
	Tcl_RetPrintf(
            interp,
            "Can't deal with PC: Stub IS NOT a GEOS32 version.");
	goto attach_error_goodbye;
    } else {
        Tcl_SetVar(interp, "stub-is-geos32", "1", TRUE) ;
    }
#else
    if (br.br_stubType & STUB_GEOS32)  {
	Tcl_RetPrintf(
            interp,
            "Can't deal with PC: Stub IS a GEOS32 version.  Swat is not compiled for this mode.");
	goto attach_error_goodbye;
    } else {
        Tcl_SetVar(interp, "stub-is-geos32", "0", TRUE) ;
    }
#endif

#if REGS_32
    /* Make sure we are using a 32 bit register aware version. */
    if (!(br.br_stubType & STUB_32BIT_REGS))  {
	Tcl_RetPrintf(
            interp,
            "Can't deal with PC: Stub IS NOT a 32-bit register version.");
	goto attach_error_goodbye;
    } else {
        Tcl_SetVar(interp, "stub-regs-are-32", "1", TRUE) ;
    }
#else
    /* Make sure we are NOT using a 32 bit register aware version. */
    if (br.br_stubType & STUB_32BIT_REGS)  {
	Tcl_RetPrintf(
            interp,
            "Can't deal with PC: Stub *IS* a 32-bit register version.  Swat is compiled for only 16-bit registers.");
	goto attach_error_goodbye;
    } else {
        Tcl_SetVar(interp, "stub-regs-are-32", "0", TRUE) ;
    }
#endif

    tryingToAttach = FALSE;
    attached = TRUE;

    kcsum = br.br_csum;

    Tcl_SetVar(interp, "geos-release", "2", TRUE);
    geosRelease = 2;

    stubType = br.br_stubType & STUB_TYPE_MASK;

    Tcl_SetVar(interp, "stub-type", stubNames[stubType], TRUE);


    /*
     * Set up the address TCL variables from the patient.
     */
    sprintf(varVal, "%04xh:%04xh", br.br_sysTablesSeg,
	    br.br_sysTablesOff);
    Tcl_SetVar(interp, "DOSTables", varVal, TRUE);

    sprintf(varVal, "%04xh:0", br.br_psp);
    Tcl_SetVar(interp, "PSPAddr", varVal, TRUE);

    sprintf(varVal, "%d", br.br_mask1);
    Tcl_SetVar(interp, "IC1Mask", varVal, TRUE);

    sprintf(varVal, "%d", br.br_mask2);
    Tcl_SetVar(interp, "IC2Mask", varVal, TRUE);

    sprintf(varVal, "%04xh:%04xh", br.br_stubSeg, br.br_irqHandlers);
    Tcl_SetVar(interp, "irqhandlers", varVal, TRUE);

    /*
     * No libraries used by the loader, but we treat all device drivers as
     * loader libraries. In Ibm_NewGeode, it will do a realloc of
     * loader->libraries when it detects the loading of a driver geode, but
     * realloc doesn't deal with NULL, so we allocate one slot anyway, even
     * though numLibs starts at 0.
     */
    loader->numLibs = 0;
    if (loader->libraries == NULL) {
	loader->libraries = (Patient *)malloc_tagged(sizeof(Patient),
						     TAG_PATIENT);
    }


    if (!initialized || (ocsum != kcsum)) {
	/*
	 * Never found the loader before, or there's a new one about.
	 */
	GeodeName	kgn;	    /* Fake structure for finding/opening the
				     * loader's object file */
	VMHandle	oldSym;	    /* Previously open symbol file */
	char    	*oldPath;   /* Path to previous version of loader */
	VMHandle	newSym;	    /* Newly open symbol file */
	LstNode 	ln;
	ThreadPtr	kthread;
	int	    	i;
	VMBlockHandle	map;
	ObjHeader   	*hdr;
	char	    	*sysName = "loader";


	oldPath = loader->path;
	oldSym = loader->symFile;
	IbmEnsureClosed(loader);
	loader->path = NULL;
	loader->symFile = (VMHandle)NULL;

	/*
	 * Try and find the loader (geode type 4) or the kernel (geode type 0).
	 */
	kgn.fileType = 4;		/* Kernel file type */
	kgn.serial = kcsum;
	strcpy(kgn.name, sysName);
	strcpy(kgn.ext, "");
	attached = FALSE;		/* Do not attempt to disconnect if
					 * user quits should we not be able to
					 * locate the loader. */
	if (!IbmOpenObject(loader, &kgn, sysName, 1)) {
	    Tcl_RetPrintf(interp, "cannot find a %s with the right checksum.",
			  sysName);
	    loader->path = oldPath;
	    loader->symFile = oldSym;
	    goto attach_error_goodbye;
	}

	if (initialized) {
	    /*
	     * Since this is a new loader, we need to clean up after the old
	     * one.
	     *
	     * Wheeee. The breakpoint module, at least, likes to look up
	     * addresses so it can preserve breakpoints across patient
	     * destructions. Sadly, at the moment loader->symFile could very
	     * easily give the wrong address mapping to it, so we replace
	     * it with the old symbol file at least until all the handles
	     * are free...
	     */
	    newSym = loader->symFile;
	    loader->symFile = oldSym;

	    /*
	     * Consistency, consistency...
	     */
	    (void)Event_Dispatch(EVENT_DESTROY, (Opaque)loader);

	    /*
	     * Free all loader handles to nuke any breakpoints. We start from
	     * 1 for release 1, b/c resource 0 and 1 are the same (the kernel
	     * has no real coreblock in release 1, so kdata serves in its
	     * place)
	     */
	    for (i = 0; i < loader->numRes; i++) {
		Handle_Free(loader->resources[i].handle);
	    }

	    /*
	     * Blow away the loader thread so it can arise, phoenix-like, from
	     * the ashes of the old...
	     */
	    kthread = (ThreadPtr)Lst_Datum(Lst_First(loader->threads));

	    Lst_Destroy(kthread->state, (void (*)())free);
	    Handle_Free(kthread->handle);

	    /*
	     * Find and remove kthread from the list of all threads.
	     */
	    ln = Lst_Member(allThreads, (LstClientData)kthread);
	    assert(ln != NILLNODE);
	    Lst_Remove(allThreads, ln);
	    Lst_Destroy(loader->threads, NOFREE);

	    /*
	     * Free thread descriptor itself
	     */
	    free((char *)kthread);
	    loader->curThread = (Thread)NULL;

	    loader->symFile = newSym;
	}


	/*
	 * Figure the number of loader resources from the .sym file.
	 */
	attached = TRUE;

	map = VMGetMapBlock(loader->symFile);
	hdr = (ObjHeader *)VMLock(loader->symFile, map, (MemHandle *)NULL);

	loader->numRes = 0;
	for (i = 0; i < hdr->numSeg; i++) {
	    if (((ObjSegment *)(hdr+1))[i].type != SEG_LIBRARY) {
		loader->numRes++;
	    }
	}
	VMUnlock(loader->symFile, map);

	/*
	 * If this is our first time through, allocate an array for the
	 * resource descriptors. If we've already been here before, just resize
	 * the array to make it big enough for the current number of resources.
	 */
	if (!initialized) {
	    loader->resources = (ResourcePtr)calloc_tagged(loader->numRes,
							   sizeof(ResourceRec),
							   TAG_PATIENT);
	} else {
	    loader->resources =
		(ResourcePtr)realloc_tagged((void *)loader->resources,
					    loader->numRes*sizeof(ResourceRec));
	    bzero (loader->resources, loader->numRes * sizeof(ResourceRec));
	}


	/*
	 * (re-)read the symbol table for the thing.
	 */
	curPatient = loader;
	Sym_Init(loader);

	/*
	 * Initialize resources[0].handle to Null so we can use it as the
	 * owner in the loop (Handle_Create takes a Null owner as meaning it
	 * owns itself)
	 */
	loader->resources[0].handle = NullHandle;

	/*
	 * Create handles for all the resources, making them non-resident
	 * loader memory handles. The "core block" is made a PROCESS handle,
	 * b/c that's sort of what it is...
	 */
	for (i = 0; i < loader->numRes; i++) {
	    loader->resources[i].handle =
		Handle_Create(loader,	    	    	    /* Patient */
				  (word)(i+1),  	    	    	    /* ID */
				  loader->resources[0].handle,  /* Owner */
				  0,    	    	    	    /* Address */
				  loader->resources[i].size,    /* Size */
				  (i == 0 ? HANDLE_PROCESS : 0)|HANDLE_KERNEL|HANDLE_MEMORY|HANDLE_DISCARDABLE|HANDLE_DISCARDED,
				  (Opaque)i,   	    	    /* other (resid) */
			      	  HANDLE_NOT_XIP);
	    }

	loader->core = loader->resources[0].handle;
	loader->geode.v2 = (Geode2Ptr)NULL;
	loader->threads = Lst_Init(FALSE);
	loader->curThread = (Thread)NULL;
	loader->name = "loader";

	/*
	 * Set up the file offsets for the real segments. Note that absolute
	 * and library segments have a size of 0, so this s/b ok.
	 */
	IbmEnsureObject(loader);
	/*
	 * Byte-swap as necessary
	 */
	if (swap) {
	    headerSize = ((headerSize&0xff) << 8) | ((headerSize >> 8)&0xff);
	}
	exeLoadBase = headerSize << 4;

	loader->resources[0].offset = exeLoadBase;

	for (i = 1; i < loader->numRes; i++) {
	    /* XXX: do segment sizes reflect actual aligned file sizes? */
	    loader->resources[i].offset = loader->resources[i-1].offset +
		loader->resources[i-1].size;
	}

	/*
	 * If we've re-initialized our loader info, get rid of the old info
	 * now.
	 */
	if (initialized) {
	    VMClose(oldSym);
	    free(oldPath);
	    patientsChucked += 1;
	}
    }

    curPatient = loader;
    loader->scope = loader->global;
    loader->line = -1;

    /*
     * Use the data from the BeepReply to set the addresses and sizes of
     * the resources for the loader.
     */
    Ibm_LoaderMoved(br.br_baseSeg);

    /*
     * Make the DOS segment cover the whole range from 0x400 to the stub.
     * If we were already initialized, leave the size alone, as we assume
     * the stub hasn't moved, while the DOSSeg handle might have been shrunk
     * by something defined with dossym.
     */
    i = IbmFindLRes("DOSSeg");
    if (i > 0) {
	Handle_Change(loader->resources[i].handle,
		      (initialized ? 0 : HANDLE_SIZE)|HANDLE_ADDRESS,
		      0,
                      MakeAddress(0x40, 0),
		      (br.br_stubSeg - 0x40) << 4,
		      0, -1);
	/* so we know it's fake... */
	loader->resources[i].flags = RESF_READ_ONLY;
    }

    /*
     * Set the base address of the PSP segment -- the size is always
     * 256 bytes and set in Ibm_Init.
     */
    i = IbmFindLRes("PSP");
    if (i > 0) {
	Handle_Change(loader->resources[i].handle,
			  HANDLE_ADDRESS|HANDLE_SIZE,
			  0,
                          MakeAddress(br.br_psp, 0),
			  256,
			  0, -1);
	/* so we know it's fake... */
	loader->resources[i].flags = RESF_READ_ONLY;
    }

    /*
     * Make the Swat segment cover what it says it covers.
     */
    i = IbmFindLRes("SwatSeg");
    if (i > 0) {
	Handle_Change(loader->resources[i].handle,
			  HANDLE_SIZE|HANDLE_ADDRESS,
			  0,
                          MakeAddress(br.br_stubSeg, 0),
			  br.br_stubSize,
			  0, -1);
	/* so we know it's fake... */
	loader->resources[i].flags = RESF_READ_ONLY;
    }

    /*
     * Make the BIOS segment cover the 64K at f000
     */
    i = IbmFindLRes("BIOSSeg");
    if (i > 0) {
	Handle_Change(loader->resources[i].handle,
			  HANDLE_SIZE|HANDLE_ADDRESS,
			  0,
#if GEOS32
                          MakeAddress(br.br_biosseg, 0),
#else
                          (Address)0xf0000,
#endif
                          65536,
			  0, -1);
	/* so we know it's fake... */
	loader->resources[i].flags = RESF_READ_ONLY;
    }

#if GEOS32
    /*
     * Make the Swat segment cover what it says it covers.
     */
    i = IbmFindLRes("LoaderStackSeg");
    if (i > 0) {
	Handle_Change(loader->resources[i].handle,
			  HANDLE_SIZE|HANDLE_ADDRESS,
			  0,
                          MakeAddress(br.br_kstack, 0),
			  br.br_kstacksize,
			  0, -1);
	/* so we know it's fake... */
	loader->resources[i].flags = RESF_READ_ONLY;
    }
#endif

    /*
     * Place the loader at the end of the list of active patients
     */
    if (Lst_IsEmpty(patients)) {
	(void)Lst_AtEnd(patients, (LstClientData)loader);
    }
    IbmCreateAlias(loader->name);

    /*
     * Let MD module get its hooks into the loader if this is a new one.
     */
    if (!initialized || (kcsum != ocsum)) {
	Ibm86_Init(loader);
    }

    /*
     * Create a fake thread where we can store the current registers. Its
     * handle ID is not 0, b/c that's the kernel thread, but 1 greater
     * than the number of resources in the loader (unless that would make it
     * the special loader ID from the old time).
     */
    if (Lst_IsEmpty(loader->threads)) {
	IbmMakeFakeThread(loader, (word)(loader->numRes + 1));
	loaderThread = (ThreadPtr)Lst_Datum(Lst_First(loader->threads));
    }

    Tcl_SetVar(interp, "attached", "1", TRUE);

    /*
     * Tell the world the loader has started.
     */
    (void)Event_Dispatch(EVENT_START, (Opaque)loader);
    loaderInitialized = TRUE;
    /*
     * Tell the world we're attached
     */
    (void)Event_Dispatch(EVENT_ATTACH, NullOpaque);

    /*
     * If the stub's about to tell us about the loader, wait until it does
     * so before we return. This avoids ugliness about switching patients
     * while stopped at the command prompt...
     * XXX: what if stub dies at this moment?
     */
    if (br.br_kernelLoaded) {

	while (kernelLoaded == FALSE) {
#if defined(_WIN32)   /* experiment on WIN32 only - XXXdan */
	    if (Ui_Interrupt() == TRUE) {
		if (MessageFlush != NULL) {
		    MessageFlush("There may have been a problem due to swat"
				 " trying to attach to GEOS while GEOS was not"
				 " idle\n");
		}
		return(FALSE);
	    }
#endif
	    Rpc_Wait();
	}
    }

    sysFlags = PATIENT_STOPPED;
#if defined(_MSDOS)
/*
 * invalidate the fileCache, this is over kill but its better than
 * not clearing it, and I don't have time to figure out what's wrong with
 * the PC src cache stuff now...
 */
    Cache_InvalidateAll(fileCache, TRUE);

/*
 * prevent rpc calls from timing out.  fixes problem where swat will
 * sometimes timeout and die when running under Windoze as a background
 * process.
 * Of course, this causes you to have to totally kill the debugger if the
 * PC goes off the deep end, rather than allowing you to gracefully detach.
 * -- ardeb 4/3/96
 */
# if 0
    rpcDebug |= RD_NO_TIMEOUT;
# endif
#endif

    return(TRUE);
}

/*********************************************************************
 *			nap
 *********************************************************************
 * SYNOPSIS: sleep in increments of 100th of seconds
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	7/ 7/93		Initial version
 *
 *********************************************************************/
#if 0
void nap(short ticks)
{
#if defined(unix)
    struct tms	t;
    clock_t 	ct;

    ticks = (60 * ticks) / 100;	    /* convert to 60ths of seconds */
    times(&t);
    ct = t.tms_stime;

    while (t.tms_stime < ct + ticks)
    {
	times(&t);
    }
#else
    struct dostime_t t;
    short    	     ct;

    _dos_gettime(&t);
    ct = t.hsecond + ticks;
    if (ct > 100)
    {
	ct = ct - 100;
    }
    while (t.hsecond != ct)
    {
	_dos_gettime(&t);
    }
#endif
}
#endif

#if defined(_MSDOS)
/*********************************************************************
 *			sleep
 *********************************************************************
 * SYNOPSIS: take a nap
 * CALLED BY:	Ibm_Init
 * RETURN:  nothing
 * SIDE EFFECTS: time passes, what more can I say???
 * STRATEGY: wait for (now) time to equal start time + naptime
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	10/22/92		Initial version
 *
 *********************************************************************/
void
sleep(unsigned long naptime)
{
    time_t s=0, t;

    time(&t);
    while ((unsigned long)t + naptime > (unsigned long)s)
    {
	time(&s);
    }
}

#endif

#if defined(_MSDOS)
# define Rpc_Rss    Serial_Rss
# define Rpc_Rssn   Serial_Rssn
# define Rpc_Rsn    Serial_Rsn
# define Rpc_Rs     Serial_Rs
#endif

/***********************************************************************
 *				AttachLowCmd
 ***********************************************************************
 * SYNOPSIS:	    do a low level attach talking to serial port directly
 * CALLED BY:	    Tcl
 * RETURN:	    nothing
 * SIDE EFFECTS:    stuff send across serial line to target pc
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy   8/93	    	Initial Version
 *
 ***********************************************************************/
DEFCMD(attach-low, AttachLow, TCL_EXACT,NULL,swat_prog.input,
"Usage:\n\
    attach-low	arg\n\
\n\
Synopsis:\n\
    reconnect to the remote PC\n\
\n\
")
{
    if (argc > 2)
    {
	    Tcl_RetPrintf(interp, wrongNumArgsString, argv[0]);
	    return TCL_ERROR;
    }

    tryingToAttach = TRUE;

    if (argc == 1)
    {
	Rpc_Rss();
    }
    else
    {
	switch (argv[1][0])
	{
	    case '0':
	    	Rpc_Rs();
		break;
	    case '1':
	    	Rpc_Rss();
		break;
	    case '2':
	    	Rpc_Rsn();
		break;
	    case '3':
	    	Rpc_Rssn();
		break;
	    default:
	    	Tcl_RetPrintf(interp, "Bad agrument to attach-low\n");
		tryingToAttach = FALSE;
		return TCL_ERROR;
	}
    }
    tryingToAttach = FALSE;
    return TCL_OK;
}


/***********************************************************************
 *				Ibm_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize this module and several others, creating
 *		    a Patient handle for the kernel and contacting
 *		    the PC.
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Many.
 *
 * STRATEGY:
 *	Create the Type descriptions for communication with the host
 *	Initialize the RPC system, and the Handle module (this can't
 *	    be initialized until after the RPC system b/c it registers
 *	    Rpc servers)
 *	Create the resource descriptors for the kernel's three segments,
 *	    with associated handles.
 *	Find the appropriate kernel to use (either in the current
 *	    development tree or in the KERNELDIR)
 *	Read the kernel's symbols with Sym_Init.
 *	Build the args for the initial handshake with the PC and contact
 *	the PC.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/31/88	Initial Revision
 *
 ***********************************************************************/
void
Ibm_Init(char 	*file,	    /* File containing kernel */
	 int 	*argcPtr,   /* Current argument count */
	 char 	**argv,     /* Current argument vector */
	 StartupType	startup) /* 1 if we should tell the stub to start up */
{
    int	    	one = 1;    /* For determining our byte-order */
    char	**nav;	    /* Place to store next unknown arg in argv */
    char    	**av;	    /* Current arg in argv */
    int		ac; 	    /* Number of current arg */
    extern CmdRec IbmQuitCmdRec;    /* Need to enter this ourselves... */

#if defined(unix)
    /*
     * XTerm gives this to us ignored, may it rot in hell. This causes us
     * to live on long after our purpose in life has expired, should xterm
     * itself quit this vale of tears before us. This is not good, as we
     * then have a swat hanging out, snarfing rpc packets (or pieces thereof)
     * without any evidence of the swat on-screen.
     */
    (void)signal(SIGHUP, SIG_DFL);
#endif

#if defined(_MSDOS)
    /* disable mouse during init phase */
    Tcl_SetVar(interp, "mousemode", "_disabled", TRUE);
#endif
    /*
     * Enter the registers we provide.
     */
    for (ac = 0; ac < Number(registers); ac++) {
	Private_Enter(registers[ac].name, (Opaque)&registers[ac].data,
		      NULL);
    }

    /*
     * Register quit command so if we abort in here, the user can get out
     */
    Cmd_Create(&IbmQuitCmdRec);
    IbmCmd_Init();


    /*
     * XXX: Load stub's symbol table and use those things...?
     */
    /*
     * Create communication types
     */
    IbmCreateTypes();

    /*
     * Start up the data cache
     */
    IbmCache_Init();

    /*
     * Initialize the object file cache
     */
    objectCache = Cache_Create(CACHE_LRU, MAX_OBJECTS, CACHE_ADDRESS,
			       IbmObjectClose);

    /*
     * Initialize the lists we maintain...
     */
    allThreads = Lst_Init(FALSE);
    dead = Lst_Init(FALSE);

    /*
     * Initialize the table of ignored geodes...
     */
    Hash_InitTable(&ignored, 0, HASH_STRING_KEYS, 0);

    /*
     * Check for flags we support
     */
    for (av = nav = &argv[1], ac = *argcPtr-1; ac > 0; ac--, av++) {
	if (strcmp(*av, "-b") == 0) {
	    bootstrap = TRUE;
	    *argcPtr -= 1;
	} else {
	    /*
	     * Copy the argument (down)
	     */
	    *nav++ = *av;
	}
    }

    /*
     * Set the global swapping flag. On a big-endian machine, *(char *)&one
     * will be 0 (&one gives the address of the MSB, which is 0), while
     * on a little-endian machine, it will be one (&one gives the LSB, which
     * is 1).
     */
    swap = (*(char *)&one != 1);

    /*
     * Initialize the rpc system
     */
    Rpc_Init(argcPtr, argv);


    /*
     * Register the KERNEL_LOAD server now in case we're talking to 2.0
     */
    Rpc_ServerCreate(RPC_KERNEL_LOAD, IbmKernelLoaded, typeSpawnArgs,
		     NullType, (Rpc_Opaque)NULL);

    /*
     * Initialize the handle module since we now need to create handles and
     * it can register its Rpc servers.
     */
    Handle_Init();

    /*
     * if the startup flag is non-zero, then send the Stub a signal to
     * crank things up and then do the ping
     */

    switch (startup)
    {
	case ST_EC_S:
	    Rpc_Rss();
	    break;
	case ST_NON_EC_S:
	    Rpc_Rssn();
	    break;
	case ST_NON_EC:
	    Rpc_Rsn();
	    break;
	case ST_EC:
	    Rpc_Rs();
	    break;
    }

    /*
     * See if the PC is there and set up variables and handles for the loader
     * appropriately
     */
    if (!Ibm_PingPC(FALSE)) {
#if defined(_WIN32)
	if (MessageFlush != NULL) {
	    MessageFlush((char *)interp->result);
	    Swat_Death();
	} else
#endif
	{
	    Punt((char *)interp->result);
	}
	/*NOTREACHED*/
    }

    /*
     * Catch continuation and detach events so we can flush state to the PC
     * before the machine continues. The flushing must be the last thing
     * done before the machine continues, so we specify that.
     */
    Event_Handle(EVENT_CONTINUE, EVENT_MBL, IbmFlushState, NullOpaque);
    Event_Handle(EVENT_DETACH, EVENT_MBL, IbmFlushState, NullOpaque);

    /*
     * Register interest in stack change events so we can change the
     * current directory to match
     */
    Event_Handle(EVENT_STACK, 0, (EventHandler *)IbmSetDir, NullOpaque);

    /*
     * Reset various pieces of state upon a return to top level
     */
    Event_Handle(EVENT_RESET, 0, IbmReset, NullOpaque);

    /*
     * Register the version-specific RPC servers now.
     */
    Rpc_ServerCreate(RPC_EXIT, IbmSysExit, NullType, NullType,
			 (Rpc_Opaque)NULL);
    Rpc_ServerCreate(RPC_RELOAD_SYS, IbmReloadSys, type_Word, NullType,
			 (Rpc_Opaque)NULL);
    Rpc_ServerCreate(RPC_DOS_RUN, IbmDosRun, type_Word, NullType,
			 (Rpc_Opaque)NULL);

    /*
     * Register the servers that don't change between versions.
     */
    Rpc_ServerCreate(RPC_HALT, IbmHalt, typeHaltArgs, NullType,
		     (Rpc_Opaque)NULL);
    Rpc_ServerCreate(RPC_SPAWN, IbmSpawn, typeSpawnArgs, NullType,
		     (Rpc_Opaque)NULL);
    Rpc_ServerCreate(RPC_THREAD_EXIT, IbmThreadDestroy, typeThreadExitArgs,
		     NullType, (Rpc_Opaque)NULL);
    Rpc_ServerCreate(RPC_GEODE_EXIT, IbmGeodeExit, typeGeodeExitArgs, NullType,
		     (Rpc_Opaque)NULL);

    /*
     * Set up the stack info for the current patient.
     */
    curPatient->frame = MD_CurrentFrame();
    (void)IbmSetDir();

    /* allow mouse events to be processed */
#if defined(_MSDOS)
    Tcl_SetVar(interp, "mousemode", "", TRUE);
#endif
    /*
     * All done -- initialization succeeded
     */

    initialized = TRUE;
    Cmd_Create(&AttachLowCmdRec);
}
