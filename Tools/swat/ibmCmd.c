/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Tcl-level patient-dependent interface
 * FILE:	  ibmCmd.c
 *
 * AUTHOR:  	  Adam de Boor: Apr 26, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	stop-catch  	    Prevent a FULLSTOP event from being generated
 *	    	    	    upon stopping.
 *	quit	    	    Exit swat
 *	set-masks   	    Tell stub what to mask when stopped
 *	patient	    	    Access patient data
 *	thread	    	    Access thread data
 *	switch	    	    Changed to a different thread/patient
 *	link	    	    Weird thing to set up artificial library links
 *	detach	    	    Stop examining PC
 *	attach	    	    Start examining PC
 *	sym-default 	    Specify default patient for symbols
 *	save-state  	    Save current thread state on a stack
 *	restore-state	    Restore most-recently saved state
 *	discard-state	    Discard most-recently saved state
 *	continue-patient    Allow machine to continue, stepping if sysStep
 *	    	    	    non-zero
 *	step-patient	    Execute a single instruction and return.
 *	current-registers   Return all machine registers for current thread
 *	stop-patient	    Make the PC stop, if possible
 *	io  	    	    Access I/O ports
 *	fill	    	    Fill a range of memory
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/26/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Tcl-level patient-dependent interface
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: ibmCmd.c,v 4.39 97/04/18 16:00:47 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "cmd.h"
#include "event.h"
#include "file.h"
#include "ibmInt.h"
#include "ibm86.h"
#include "private.h"
#include "type.h"
#include "expr.h"
#include "var.h"
#include "geos.h"
#include <objfmt.h>
#include <objSwap.h>
#include <compat/file.h>
#include <compat/stdlib.h>
#include <errno.h>

#if defined(_WIN32)
# include <winutil.h>
#endif

#if defined(_MSDOS) || defined(_WIN32)
# include "serial.h"
#endif

#if defined(_MSDOS)
extern const char *getenv();
#endif

extern int commMode;   /* from rpc.c */


/***********************************************************************
 *				IbmStopCatchCmd
 ***********************************************************************
 * SYNOPSIS:	    Execute the body, but prevent return to top level
 *	    	    if the patient stops.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    noFullStop is set TRUE during the interval.
 *
 * STRATEGY:	    Set noFullStop
 *	    	    Eval argument.
 *	    	    Clear noFullStop
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/27/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(stop-catch,IbmStopCatch,TCL_EXACT,NULL,swat_prog.event,
"Usage:\n\
    stop-catch <body>\n\
\n\
Examples:\n\
    \"stop-catch {go ProcCallModuleRoutine}\"\n\
	    	    	    Let the machine run until it reaches\n\
			    ProcCallModuleRoutine, but do not issue a FULLSTOP\n\
			    event when it gets there.\n\
\n\
Synopsis:\n\
    Allows a string of commands to be executed without a FULLSTOP event being\n\
    generated while they are executing.\n\
\n\
Notes:\n\
    * Why is this useful? A number of things happen when a FULLSTOP event\n\
      is dispatched, including notifying the user where the machine stopped.\n\
      This is inappropriate in something like \"istep\" or \"cycles\" that is\n\
      single-stepping the machine, for example.\n\
\n\
See also:\n\
    event, continue-patient, step-patient\n\
")
{
    int	    result;

    if (argc != 2) {
	Tcl_RetPrintf(interp, "Usage: %s <body>", argv[0]);
	return(TCL_ERROR);
    }
    
    noFullStop++;
    result = Tcl_Eval(interp, argv[1], 0, (const char **)NULL);
    noFullStop--;
    return(result);
}

/***********************************************************************
 *				IbmDetachGuts
 ***********************************************************************
 *
 * SYNOPSIS:	    Detach from GEOS
 * CALLED BY:	    IbmQuitCmd, IbmDetachCmd
 * RETURN:	    void
 * SIDE EFFECTS:    All patients are placed on the dead list,
 *		    'attached' is set to FALSE
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	1/22/97   	Initial Revision
 *
 ***********************************************************************/
void
IbmDetachGuts (int normal_exit, int argc, char **argv)
{
    MessageFlush("Detaching from GEOS...");
    
    if  (Patient_ByName("os2") == NullPatient &&
	 Patient_ByName("ms2") == NullPatient &&
	 Patient_ByName("ms3") == NullPatient &&
	 Patient_ByName("ms4") == NullPatient &&
	 Patient_ByName("ms7") == NullPatient &&
	 Patient_ByName("dri") == NullPatient)
    {
	normal_exit = 0;
    }
    /*
     * Perform a disconnect to make sure conditional breakpoints are out.
     */
    if (argc > 1) {
	if (argv[1][0] == 'l') {
	    IbmDisconnect(0);
	} else if (argv[1][0] == 'c' || normal_exit == 0) {
	    IbmDisconnect(RPC_GOODBYE);
	} else {
	    IbmDisconnect(RPC_EXIT);
	}
    } else {
	if (normal_exit == 0) {
	    IbmDisconnect(RPC_GOODBYE);
	} else {
	    IbmDisconnect(RPC_EXIT);
	}
    }
}	/* End of IbmDetachGuts.	*/


/***********************************************************************
 *				IbmQuitCmd
 ***********************************************************************
 * SYNOPSIS:	    Detach from the PC and exit.
 * CALLED BY:	    Tcl
 * RETURN:	    No.
 * SIDE EFFECTS:    Process exits.
 *
 * STRATEGY:	    None, for now.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(quit,IbmQuit,TCL_EXACT,NULL,top.running,
"Usage:\n\
    quit [<options>]\n\
\n\
Examples:\n\
    \"quit cont\"   continue PCGEOS and quit swat\n\
    \"quit det\"    detach from the PC and quit swat.\n\
\n\
Synopsis:\n\
    Stop the debugger and exit.\n\
\n\
Notes:\n\
    * The option argument may be one of the following (and may be abbreviated):\n\
          continue  	continue GEOS and exit Swat \n\
          leave	    	keep GEOS stopped and exit Swat\n\
\n\
      Anything else causes Swat to detach and exit.\n\
\n\
    * You can use these options if you want to pass debugging control off to\n\
      another person remotely logged into your UNIX workstation.\n\
\n\
See also:\n\
    detach.\n\
")
{
    int	normal_exit=1;

#if defined(unix)
    extern volatile exit();
#endif
    if (attached == TRUE) {
	IbmDetachGuts(normal_exit, argc, argv);
    }

    if (Ui_Exit) {
	(*Ui_Exit)();
    }
    exit(0);

#if defined(__HIGHC__) || defined(__BORLANDC__)
    return(0);        /* never gets executed, but makes HighC happy */
#endif

}

/***********************************************************************
 *				IbmSetMasksCmd
 ***********************************************************************
 * SYNOPSIS:	    Command to set the interrupt masks used while
 *	    	    SWAT is stopped.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    The masks be changed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(set-masks,IbmSetMasks,TCL_EXACT,NULL,swat_prog.obscure,
"Usage:\n\
    set-masks <mask1> <mask2>\n\
\n\
Examples:\n\
    \"set-masks 0xff 0xff\"	Allow no hardware interrupts to be handled\n\
				while the machine is stopped.\n\
\n\
Synopsis:\n\
    Sets the interrupt masks used while the Swat stub is active. Users should\n\
    use the \"int\" command.\n\
\n\
Notes:\n\
    * <mask1> is the mask for the first interrupt controller, with a 1 bit\n\
      indicating the interrupt should be held until the stub returns the\n\
      machine to GEOS. <mask2> is the mask for the second interrupt\n\
      controller.\n\
\n\
    * These masks are active only while the machine is executing in the stub,\n\
      which usually means only while the machine is stopped.\n\
\n\
See also:\n\
    int\n\
")
{
    MaskArgs	ma;

    if (argc != 3) {
	Tcl_Error(interp, "Usage: set-masks <mask1> <mask2>");
    }
    
    ma.ma_PIC1 = cvtnum(argv[1], NULL);
    ma.ma_PIC2 = cvtnum(argv[2], NULL);

    if (Rpc_Call(RPC_MASK,
		 sizeof(ma), typeMaskArgs, (Opaque)&ma,
		 0, NullType, NullOpaque) != RPC_SUCCESS)
    {
	Tcl_RetPrintf(interp, "Couldn't set masks: %s", Rpc_LastError());
	return (TCL_ERROR);
    } else {
	return (TCL_OK);
    }
}

/***********************************************************************
 *				IbmPatientCmd
 ***********************************************************************
 * SYNOPSIS:	    Handle the tcl  patient  command -- general purpose
 *	    	    access to data about the current patient
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/23/88	Initial Revision
 *
 ***********************************************************************/
#define PATIENT_NAME	    (ClientData)0
#define PATIENT_FULLNAME    (ClientData)1
#define PATIENT_THREADS	    (ClientData)2
#define PATIENT_RESOURCES   (ClientData)3
#define PATIENT_LIBS	    (ClientData)4
#define PATIENT_PATH	    (ClientData)5
#define PATIENT_DATA	    (ClientData)6
#define PATIENT_ALL 	    (ClientData)7
#define PATIENT_FIND	    (ClientData)8
#define PATIENT_STOPCMD	    (ClientData)9
static const CmdSubRec patientCmds[] = {
    {"find",   	PATIENT_FIND,	    1, 1, "<name>"},
    {"name", 	PATIENT_NAME,	    0, 1, "[<patient>]"},
    {"fullname",PATIENT_FULLNAME,   0, 1, "[<patient>]"},
    {"data", 	PATIENT_DATA,	    0, 1, "[<patient>]"},
    {"threads",	PATIENT_THREADS,    0, 1, "[<patient>]"},
    {"resources",PATIENT_RESOURCES, 0, 1, "[<patient>]"},
    {"libs", 	PATIENT_LIBS,	    0, 1, "[<patient>]"},
    {"path", 	PATIENT_PATH,	    0, 1, "[<patient>]"},
    {"all",  	PATIENT_ALL,	    0, 0, ""},
    {"stop", 	PATIENT_STOPCMD,    0, 1, "[<addr>]"},
    {NULL,   	(ClientData)NULL,	    	    0, 0, NULL}
};
DEFCMD(patient,IbmPatient,0,patientCmds,swat_prog,
"Usage:\n\
    patient find <name>\n\
    patient name [<patient>]\n\
    patient fullname [<patient>]\n\
    patient data [<patient>]\n\
    patient threads [<patient>]\n\
    patient resources [<patient>]\n\
    patient libs [<patient>]\n\
    patient path [<patient>]\n\
    patient all\n\
    patient stop [<addr>]\n\
\n\
Examples:\n\
    \"patient find geos\"	    Returns the patient token for the kernel, if it's\n\
			    been loaded yet.\n\
    \"patient fullname $p\"   Returns the permanent name for the patient whose\n\
			    token is stored in the variable p.\n\
    \"patient stop $data\"    Tells the dispatcher of the STEP event that it\n\
			    should keep the machine stopped when the STEP\n\
			    event has been handled by everyone.\n\
\n\
Synopsis:\n\
    This command provides access to the various pieces of information that are\n\
    maintained for each patient (geode) loaded by GEOS.\n\
\n\
Notes:\n\
    * Subcommands may be abbreviated uniquely.\n\
\n\
    * Swat always has the notion of a \"current patient\", whose name is displayed\n\
      in the prompt. It is this patient that is used if you do not provide\n\
      a token to one of the subcommands that accepts a patient token.\n\
\n\
    * \"patient name\" returns the name of a patient. The name is the non-\n\
      extension portion of the geode's permanent name. It will have a number\n\
      added to it if more than one instance of the geode is active on the\n\
      PC. Thus, if two GeoWrites are active, there will be two patients in Swat:\n\
      \"write\" and \"write2\".\n\
\n\
    * \"patient fullname\" returns the full permanent name of the patient. It is\n\
      padded with spaces to make up a full 12-character string. This doesn't\n\
      mean you can obtain the non-extension part by extracting the 0th\n\
      element of the result with the \"index\" command, however; you'll have\n\
      to use the \"range\" command to get the first 8 characters, then use\n\
      \"index\" to trim the trailing spaces off, if you want to.\n\
\n\
    * \"patient data\" returns a three-element list: {<name> <fullname>\n\
      <thread-number>} <name> and <fullname> are the same as returned by\n\
      the \"name\" and \"fullname\" subcommands. <thread-number> is the number\n\
      of the current thread for the patient. Each patient has a single thread\n\
      that is the one the user looked at most recently, and that is its current\n\
      thread. The current thread of the current patient is, of course, the\n\
      current thread for the whole debugger.\n\
\n\
    * \"patient threads\" returns a list of tokens, one for each of the patient's\n\
      threads, whose elements can be passed to the \"thread\" command to obtain\n\
      more information about the patient's threads (such as their numbers,\n\
      handle IDs, and the contents of their registers).\n\
\n\
    * \"patient resources\" returns a list of tokens, one for each of the\n\
      patient's resources, whose elements can be passed to the \"handle\" command\n\
      to obtain more information about the patient's resources (for example,\n\
      their names and handle IDs).\n\
\n\
    * \"patient libs\" returns a list of patient tokens, one for each of the\n\
      patient's imported libraries. The kernel has all the loaded device\n\
      drivers as its \"imported\" libraries.\n\
\n\
    * \"patient path\" returns the absolute path of the patient's executable.\n\
\n\
    * \"patient all\" returns a list of the tokens of all the patients known\n\
      to Swat.\n\
\n\
    * \"patient stop\" is used only in STEP, STOP and START event handlers to\n\
      indicate you want the machine to remain stopped once the event has\n\
      been dispatched to all interested parties. <addr> is the argument\n\
      passed in the STEP and STOP events. A START event handler should pass\n\
      nothing.\n\
\n\
    * A number of other commands provide patient tokens. \"patient find\" isn't\n\
      the only way to get one.\n\
\n\
See also:\n\
    thread, handle\n\
")
{
    Patient patient;
    char    *permName=0;

    if (clientData < PATIENT_ALL) {
	if (argc == 3) {
	    patient = (Patient)atoi(argv[2]);
	    if (!VALIDTPTR(patient, TAG_PATIENT)) {
		Tcl_RetPrintf(interp, "%s: not a patient", argv[2]);
		return(TCL_ERROR);
	    }
	} else {
	    patient = curPatient;
	    if (patient == NullPatient) {
		Tcl_Error(interp, "no current patient");
	    }
	}
	permName = patient->geode.v2 ? patient->geode.v2->geodeName : "";
    } else {
	patient = NullPatient;	/* For GCC */
    }
    
    switch((int)clientData) {
	case (int)PATIENT_DATA:
	    if (patient->curThread) {
		Tcl_RetPrintf(interp, "{%s} {%.12s} {%d}",
			      patient->name,
			      permName,
			      ((ThreadPtr)patient->curThread)->number);
	    } else {
		Tcl_RetPrintf(interp, "{%s} {%.12s} {}",
			      patient->name,
			      permName);
	    }
	    break;
	case (int)PATIENT_NAME:
	    /*
	     * Return just the name
	     */
	    Tcl_Return(interp, patient->name, TCL_VOLATILE);
	    break;
	case (int)PATIENT_FULLNAME:
	    /*
	     * Return the permanent name
	     */
	    Tcl_RetPrintf(interp,"%.12s", permName);
	    break;
	case (int)PATIENT_ALL:
	{
	    /*
	     * Return tokens for all known patients. We allocate 16 bytes per
	     * patient because it seems like a good number...
	     */
	    char	*retval, *cp;
	    LstNode	ln;
	    
	    cp = retval = (char *)malloc_tagged(Lst_Length(patients) * 16,
						TAG_ETC);
	    for (ln = Lst_First(patients); ln != NILLNODE; ln = Lst_Succ(ln)) {
		sprintf(cp, "%d ", (int)(Lst_Datum(ln)));
		cp += strlen(cp);
	    }
	    cp[-1] = '\0';
	    Tcl_Return(interp, retval, TCL_DYNAMIC);
	    break;
	}
	case (int)PATIENT_THREADS:
	    /*
	     * Return a list of tokens for all the threads for the current
	     * patient. Again, we allocate 16 bytes per because it's a nice number.
	     */
	    if (Lst_IsEmpty(patient->threads)) {
		Tcl_Return(interp, NULL, TCL_STATIC);
	    } else {
		char	*retval, *cp;
		LstNode	ln;
		
		cp = retval =
		    (char *)malloc_tagged(Lst_Length(patient->threads) * 16,
					  TAG_ETC);
		for (ln = Lst_First(patient->threads);
		     ln != NILLNODE;
		     ln = Lst_Succ(ln))
		{
		    sprintf(cp, "%d ", (int)(Lst_Datum(ln)));
		    cp += strlen(cp);
		}
		cp[-1] = '\0';
		Tcl_Return(interp, retval, TCL_DYNAMIC);
	    }
	    break;
	case (int)PATIENT_RESOURCES:
	    /*
	     * Return a list of tokens for the resource handles of the patient.
	     * 16 be the magic number...
	     */
	    if (patient->numRes) {
		char	*retval, *cp;
		int	    	i;
		
		cp = retval = (char *)malloc_tagged(patient->numRes * 16,
						    TAG_ETC);
		for (i = 0; i < patient->numRes; i++) {
		    sprintf(cp, "%d ", (int)(patient->resources[i].handle));
		    cp += strlen(cp);
		}
		cp[-1] = '\0';
		Tcl_Return(interp, retval, TCL_DYNAMIC);
	    } else {
		Tcl_Return(interp, NULL, TCL_STATIC);
	    }
	    break;
	case (int)PATIENT_LIBS:
	    /*
	     * Return a list of tokens for the libraries of the patient.
	     * 16 be the magic number...
	     */
	    if (patient->numLibs) {
		char	*retval, *cp;
		int	    	i;
		
		cp = retval = (char *)malloc_tagged(patient->numLibs * 16,
						    TAG_ETC);
		for (i = 0; i < patient->numLibs; i++) {
		    sprintf(cp, "%d ", (int)patient->libraries[i]);
		    cp += strlen(cp);
		}
		cp[-1] = '\0';
		Tcl_Return(interp, retval, TCL_DYNAMIC);
	    } else {
		Tcl_Return(interp, NULL, TCL_STATIC);
	    }
	    break;
	case (int)PATIENT_FIND:
	    /*
	     * Locate a patient by its name (not its permanent name)
	     */
	    patient = Patient_ByName(argv[2]);
	    if (patient != NullPatient) {
		Tcl_RetPrintf(interp, "%d", patient);
	    } else {
		Tcl_Return(interp, "nil", TCL_STATIC);
	    }
	    break;
	case (int)PATIENT_PATH:
	    /*
	     * Return the path to the patient's executable, making it absolute,
	     * by tacking on our initial directory, if the path isn't already
	     * so.
	     * NOTE: The Tcl_RetPrintf limits things to be TCL_RESULT_SIZE
	     * characters long.
	     */
#if defined(unix)
	    if (*patient->path != '/') {
#else
	    if (*patient->path != '/' && *patient->path != '\\' &&
		patient->path[1] != ':') {
#endif 
		Tcl_RetPrintf(interp, "%s/%s", cwd, patient->path);
	    } else {
		Tcl_Return(interp, patient->path, TCL_STATIC);
	    }
	    break;
	case (int)PATIENT_STOPCMD:
	    /*
	     * Flag that the machine is to remain stopped. If argument is
	     * given, it is expected to be the address of an integer to
	     * set true. Otherwise, we just set the PATIENT_STOP flag.
	     */
	    if (argc == 3) {
		int *stayStoppedPtr = (int *)atoi(argv[2]);

		if (stayStoppedPtr > (int *)&stayStoppedPtr)  {
		    *stayStoppedPtr = TRUE;
		} else {
		    Tcl_Error(interp, "what are you trying to prove?");
		}
	    } else {
		sysFlags |= PATIENT_STOP;
	    }
	    break;
    }
    return(TCL_OK);
}

/***********************************************************************
 *				IbmThreadCmd
 ***********************************************************************
 * SYNOPSIS:	    Return info about a thread.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK, etc...
 * SIDE EFFECTS:    Registers may be fetched.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 3/88	Initial Revision
 *
 ***********************************************************************/
#define THREAD_ID   	(ClientData)0
#define THREAD_REG   	(ClientData)1
#define THREAD_HANDLE  	(ClientData)2
#define THREAD_ENDSTACK	(ClientData)3
#define THREAD_NUMBER  	(ClientData)4
#define THREAD_STACK	(ClientData)5
#define THREAD_ALL   	(ClientData)6
static const CmdSubRec threadCmds[] = {
    {"id",   	THREAD_ID,  	1, 1, "<thread>"},
    {"register",THREAD_REG, 	2, 2, "<thread> <regName>"},
    {"handle",	THREAD_HANDLE,	1, 1, "<thread>"},
    {"endstack",THREAD_ENDSTACK,1, 1, "<thread>"},
    {"number",	THREAD_NUMBER,	1, 1, "<thread>"},
    {"all",  	THREAD_ALL, 	0, 0, ""},
    {"stack",	THREAD_STACK,	1, 1, "<thread>"},
    {NULL,	(ClientData)NULL,		0, 0, NULL}
};
DEFCMD(thread,IbmThread,TCL_EXACT,threadCmds,swat_prog|swat_prog.thread,
"Usage:\n\
    thread id <thread>\n\
    thread register <thread> <regName>\n\
    thread handle <thread>\n\
    thread endstack <thread>\n\
    thread number <thread>\n\
    thread all\n\
\n\
Examples:\n\
    \"thread register $t cx\"	Fetches the value for the CX register for the\n\
				given thread.\n\
    \"thread number $t\"	    	Fetches the number Swat assigned to the thread\n\
				when it was first encountered.\n\
\n\
Synopsis:\n\
    Returns information about a thread, given its thread token. Thread tokens\n\
    can be obtained via the \"patient threads\" command, or the \"handle other\"\n\
    command applied to a thread handle's token.\n\
\n\
Notes:\n\
    * Subcommands may be abbreviated uniquely.\n\
\n\
    * <thread> arguments can also be the handle token for a thread handle.\n\
\n\
    * \"thread id\" returns the handle ID, in decimal, of the thread's handle.\n\
      This is simply a convenience.\n\
\n\
    * \"thread register\" returns the contents of the given register in the\n\
      thread when it was suspended. All registers except \"pc\" are returned\n\
      as a single decimal number. \"pc\" is returned as two hexadecimal numbers\n\
      separated by a colon, being the cs:ip for the thread. Note that GEOS\n\
      doesn't actually save the AX and BX registers when it suspends a thread,\n\
      at least not where Swat can consistently locate them. These registers will\n\
      always hold 0xadeb unless the thread is the current thread for the\n\
      machine (as opposed to the current thread for Swat).\n\
\n\
    * \"thread handle\" returns the token for the thread's handle.\n\
\n\
    * \"thread endstack\" returns the maximum value SP can hold for the thread,\n\
      when it is operating off its own stack. Swat maintains this value so it\n\
      knows when to give up trying to decode the stack.\n\
\n\
    * \"thread number\" returns the decimal number Swat assigned the thread when\n\
      it first encountered it. The first thread for each patient is given \n\
      the number 0 with successive threads being given the highest thread number\n\
      known for the patient plus one.\n\
\n\
    * \"thread all\" returns a list of tokens for all the threads known to\n\
      Swat (for all patients).\n\
\n\
See also:\n\
    patient, handle\n\
")
{
    ThreadPtr	thread;

    if (clientData < THREAD_ALL) {
	thread = (ThreadPtr)atoi(argv[2]);
	if (!VALIDTPTR(thread,TAG_THREAD)) {
	    /*
	     * Allow the thing to be the token for a thread handle, too
	     */
	    if (VALIDTPTR(thread,TAG_HANDLE) &&
		Handle_IsThread(Handle_State((Handle)thread)))
	    {
		thread = (ThreadPtr)((Handle)thread)->otherInfo;
	    } else {
		Tcl_RetPrintf(interp, "%s: not a thread", argv[2]);
		return(TCL_ERROR);
	    }
	}
    } else {
	thread = NullThread;	/* For GCC */
    }
    switch((int)clientData) {
    case (int)THREAD_ALL:
	if (Lst_Length(allThreads) == 0) {
	    Tcl_Return(interp, "", TCL_STATIC);
	} else {
	    char	*retval, *cp;
	    LstNode	ln;
	    
	    cp = retval = (char *)malloc_tagged(Lst_Length(allThreads) * 16,
						TAG_ETC);

	    for (ln = Lst_First(allThreads); ln != NILLNODE; ln = Lst_Succ(ln))
	    {
		sprintf(cp, "%d ", (int)(Lst_Datum(ln)));
		cp += strlen(cp);
	    }
	    cp[-1] = '\0';
	    Tcl_Return(interp, retval, TCL_DYNAMIC);
	}
	break;
    case (int)THREAD_ID:
	Tcl_RetPrintf(interp, "%d", Handle_ID(thread->handle));
	break;
    case (int)THREAD_REG:
    {
	Reg_Data    *rd;
	
	rd = (Reg_Data *)Private_GetData(argv[3]);
	if (rd == (Reg_Data *)NULL) {
	    Tcl_RetPrintf(interp, "%s: unknown register", argv[3]);
	    return(TCL_ERROR);
	}
	if ((rd->type == REG_MACHINE) && (rd->number == REG_PC)) {
	    word    	cs, ip;

	    IbmReadThreadRegister16(thread, REG_MACHINE, REG_CS, &cs);
	    IbmReadThreadRegister16(thread, REG_MACHINE, REG_IP, &ip);
	    
	    Tcl_RetPrintf(interp, "%04xh:%04xh", cs, ip);
	} else {
	    word    	val;

	    IbmReadThreadRegister16(thread, rd->type, rd->number, &val);
	    Tcl_RetPrintf(interp, "%d", val);
	}
	break;
    }
    case (int)THREAD_HANDLE:
	Tcl_RetPrintf(interp, "%d", thread->handle);
	break;
    case (int)THREAD_ENDSTACK:
	Tcl_RetPrintf(interp, "%d", thread->stackBot);
	break;
    case (int)THREAD_NUMBER:
	Tcl_RetPrintf(interp, "%d", thread->number);
	break;
    case (int)THREAD_STACK:
	Tcl_RetPrintf(interp, "%d", thread->stack);
	break;
    }
    return(TCL_OK);
}

/***********************************************************************
 *				IbmSwitchCmd
 ***********************************************************************
 * SYNOPSIS:	    Switch contexts to a new patient and/or thread
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK or TCL_ERROR
 * SIDE EFFECTS:    A CHANGE event is dispatched and curPatient
 *	    	    altered.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 3/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(switch,IbmSwitch,0,NULL,top.stack|patient|thread|swat_prog.thread,
"Usage:\n\
    switch <thread-id>\n\
    switch [<patient>][:<thread-num>]\n\
\n\
Examples:\n\
    \"switch 3730h\"	    Switches Swat's current thread to be the one whose\n\
			    handle ID is 3730h.\n\
    \"switch :1\"	    	    Switches Swat's current thread to be thread number\n\
			    1 for the current patient.\n\
    \":1\"	    	    Switches Swat's current thread to be thread number\n\
			    1 for the current patient.\n\
    \"switch parallel:2\"	    Switches Swat's current thread to be thread number\n\
			    2 for the patient \"parallel\"\n\
    \"switch write\"  	    Switches Swat's current thread to be thread number\n\
			    0 (the process thread) for the patient \"write\"\n\
    \"switch\"	    	    Switches Swat's current thread to be the current\n\
			    thread on the PC.\n\
\n\
    \":\"	    	    Switches Swat's current thread to be the current\n\
			    thread on the PC.\n\
\n\
Synopsis:\n\
    This allows you to see what any thread in the system was doing, when the\n\
    machine stopped, by changing Swat's current thread, from which registers\n\
    and backtraces are fetched.\n\
\n\
Notes:\n\
    * The switching between threads in Swat has absolutely no effect on the\n\
      current thread as far as GEOS is concerned.\n\
\n\
    * If Swat's current thread and the PC's current thread are not the same,\n\
      the command prompt changes to show the patient and thread number in\n\
      brackets, rather than the parentheses they're normally in.\n\
\n\
    * The \"istep\" command will wait for Swat's current thread to become the\n\
      PC's current thread if it is invoked when the two aren't the same.\n\
\n\
    * Aliases exist that allow you to switch to any thread of the current\n\
      patient whose number is a single digit. For example \":1\" switches to\n\
      thread number 1 of the current patient.\n\
\n\
    * \":\" is a shortcut to get back to the PC's current thread.\n\
\n\
See also:\n\
    patient\n\
")
{
    Patient 	patient,    	/* New patient */
		oldPatient; 	/* ... */
    ThreadPtr	thread;	    	/* New thread */
    char    	*newargv[3];	/* New argv if called by a patient alias */
    char    	*newarg;    	/* New argument if called by patient alias
				 * with thread number arg */
    Boolean 	freeArgv1 = FALSE;

    thread = NullThread;	/* For GCC */

    /*
     * We can also be called as the result of typing a patient's name (aliases
     * created by IbmCreateAlias and nuked by IbmDestroyAlias). These aliases
     * have a non-null (meaningless) clientData argument to distinguish from the
     * regular "switch" command itself. In this case, we simply create a new
     * argv for the rest of the command. The user is allowed to give a thread
     * number as an argument to the alias, in which case we tack the number
     * onto the end of the patient name with a : between the two, as would
     * be expected by a normal switch.
     */
    if (clientData != (ClientData)NULL) {
	newargv[0] = "switch";
	newargv[1] = argv[0];
	newargv[2] = (char *)NULL;

	if (argc != 1) {
	    newarg = (char *)malloc(strlen(argv[0]) + 1 + strlen(argv[1]) + 1);
	    sprintf(newarg, "%s:%s", argv[0], argv[1]);
	    newargv[1] = newarg;
	    freeArgv1 = TRUE;
	}
	argv = newargv;
	argc = 2;
    }

    if (argc == 1) {
	thread = realCurThread;
	patient = Handle_Patient(thread->handle);
    } else if (argc != 2) {
	Tcl_Error(interp, "Usage: switch ([patient][:thread-num]|threadID)");
    } else if (index (argv[1], ':') == NULL) {
	/*
	 * Either a patient-only or a thread ID
	 */
	patient = Patient_ByName(argv[1]);
	if (patient == NullPatient) {
	    /*
	     * Not a known patient -- see if it's a thread handle's ID
	     */
	    char *cp;

	    word    id = cvtnum(argv[1], &cp);
	    Handle  handle = Handle_Lookup(id);

	    if ((handle == NullHandle) || (*cp != '\0')) {
		if (freeArgv1) {
		    free(argv[1]);
		}
		Tcl_RetPrintf(interp, "There is no thread %s.", argv[1]);
		return(TCL_ERROR);
	    }
	    /*
	     * Make sure it's actually a thread handle
	     */
	    if (Handle_IsThread(Handle_State(handle))) {
		/*
		 * The ThreadPtr for it is stored in the otherInfo field
		 * of the handle. Get the patient to which it belongs from
		 * the Handle module.
		 */
		thread = (ThreadPtr)handle->otherInfo;
		patient = Handle_Patient(handle);
	    } else {
		/*
		 * Not a thread handle -- bitch moan gripe complain
		 */
		if (freeArgv1) {
		    free(argv[1]);
		}
		Tcl_Error(interp, "That's not a thread handle");
	    }
	} else if (!Lst_IsEmpty(patient->threads)) {
	    /*
	     * Patient actually has threads, so switch to its 0th thread.
	     * XXX: Will it actually be the first one?
	     */
	    thread = (ThreadPtr)Lst_Datum(Lst_First(patient->threads));
	} else {
	    /*
	     * This is ok, but warn the user, at least until we're sure swat
	     * won't die from it...
	     */
	    Tcl_RetPrintf(interp, "Warning: %s has no threads.", argv[1]);
	    thread = NullThread;
	}
    } else if (argv[1][0] != ':') {
	/*
	 * Specifying both patient and thread number.
	 */
	char	*cp = index(argv[1], ':');

	*cp++ = '\0';
	/*
	 * Find the patient first...
	 */
	patient = Patient_ByName(argv[1]);
	if (patient == NullPatient) {
	    Tcl_RetPrintf(interp, "There is no patient named \"%s\".", argv[1]);
	    if (freeArgv1) {
		free(argv[1]);
	    }
	    return(TCL_ERROR);
	} else {
	    /*
	     * Now we've got a patient handle, look for a thread of the
	     * given number.
	     */
	    int	    tnum = atoi(cp);
	    LstNode ln;

	    for (ln = Lst_First(patient->threads);
		 ln != NILLNODE;
		 ln = Lst_Succ(ln))
	    {
		thread = (ThreadPtr)Lst_Datum(ln);

		if (thread->number == tnum) {
		    break;
		}
	    }
	    if (ln == NILLNODE) {
		Tcl_RetPrintf(interp, "%s has no thread number %d",
			      patient->name, tnum);
		if (freeArgv1) {
		    free(argv[1]);
		}
		return(TCL_ERROR);
	    }
	}
    } else {
	/*
	 * Switching to another thread of the same patient.
	 */
	int	    tnum = atoi(&argv[1][1]);
	LstNode ln;
	
	patient = curPatient;

	for (ln = Lst_First(patient->threads);
	     ln != NILLNODE;
	     ln = Lst_Succ(ln))
	{
	    thread = (ThreadPtr)Lst_Datum(ln);
	    
	    if (thread->number == tnum) {
		break;
	    }
	}
	if (ln == NILLNODE) {
	    Tcl_RetPrintf(interp, "%s has no thread number %d",
			  patient->name, tnum);
	    if (freeArgv1) {
		free(argv[1]);
	    }
	    return(TCL_ERROR);
	}
    }

    /*
     * Perform the actual switch, letting the world know about it.
     */
    oldPatient = curPatient;
    curPatient = patient;
    curPatient->curThread = (Thread)thread;

    (void)Event_Dispatch(EVENT_CHANGE, (Opaque)oldPatient);

    if (thread != NullThread) {
	/*
	 * Fetch the current frame for the new patient -- note this is done
	 * AFTER the CHANGE event is dispatched to make sure we don't
	 * get a cached frame...
	 */
	curPatient->frame = MD_CurrentFrame();
	curPatient->scope = curPatient->frame->scope;

	/* set the current XIP page up to be the current thead's current 
	 * XIP page
	Ibm_ReadRegister(REG_OTHER, "xipPage", &curXIPPage);
	 */
    } else {
	curPatient->frame = NullFrame;
	curPatient->scope = curPatient->global;
    }

    /*
     * Tell folks the stack changed, indicating it's due to a patient
     * change...
     */
    (void)Event_Dispatch(EVENT_STACK, (Opaque)TRUE);
    
    if (freeArgv1) {
	free(argv[1]);
    }
    return(TCL_OK);
}

/***********************************************************************
 *				IbmLinked
 ***********************************************************************
 * SYNOPSIS:	    See if a library is already linked to a patient.
 * CALLED BY:	    IbmLinkCmd
 * RETURN:	    TRUE if there's already a link.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Does a depth-first traversal of the libs links.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 7/89		Initial Revision
 *
 ***********************************************************************/
static int
IbmLinked(Patient lib,	    /* Library being linked */
	  Patient patient)  /* Patient it's being linked to */
{
    int	    i;

    for (i = 0; i < lib->numLibs; i++) {
	if ((lib->libraries[i] == patient) || IbmLinked(lib->libraries[i], patient)) {
	    return(1);
	}
    }
    return(0);
}
    

/***********************************************************************
 *				IbmLinkCmd
 ***********************************************************************
 * SYNOPSIS:	    Link another patient in as a library of the current
 *	    	    one.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 7/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(link,IbmLink,1,NULL,obscure,
"Usage:\n\
    link <library> [<patient>]\n\
\n\
Examples:\n\
    \"link motif\"	    Makes the library \"motif\" be a library of\n\
			    the current patient, so far as Swat is concerned.\n\
\n\
Synopsis:\n\
    Allows you to link a patient as an imported library of another patient,\n\
    even though the other patient doesn't actually import the patient. This\n\
    is useful only for symbol searches.\n\
\n\
Notes:\n\
    * sym-default is a much better way to have Swat locate symbols for\n\
      libraries that are loaded by GeodeUseLibrary.\n\
\n\
    * Cycles are not allowed. I.e. don't link your application as a library\n\
      of the UI, as it won't work...or if it does, it will make Swat die.\n\
\n\
    * The link persists across detach/attach sequences so long as the <patient>\n\
      isn't recompiled and downloaded.\n\
\n\
    * If you don't give <patient>, then the current patient will be the one\n\
      made to import <library>\n\
\n\
    * Both <library> and <patient> are patient *names*, not tokens.\n\
\n\
    * This command is really, really obscure and will probably go away.\n\
\n\
See also:\n\
    sym-default\n\
")
{
    Patient 	lib,	    	/* Library to link */
		patient;    	/* Patient to which to link it */

    if (argc == 2) {
	patient = curPatient;
	lib = Patient_ByName(argv[1]);
    } else if (argc == 3) {
	lib = Patient_ByName(argv[1]);
	patient = Patient_ByName(argv[2]);
    } else {
	Tcl_Error(interp, "Usage: link <library> [<patient>]");
    }

    if (lib == NULL) {
	Tcl_Error(interp, "Library not loaded yet.");
    }

    if (patient == NULL) {
	Tcl_Error(interp, "Patient not loaded yet.");
    }

    if (IbmLinked(lib, patient)) {
	Tcl_Error(interp, "Already a link going the other way. Don't confuse me, please");
    } else if (IbmLinked(patient, lib)) {
	Tcl_Error(interp, "Those two are already linked, silly.");
    }
    patient->libraries =
	    (Patient *)realloc_tagged((void *)patient->libraries,
				       (++patient->numLibs * sizeof(Patient)));
    patient->libraries[patient->numLibs-1] = lib;
    return(TCL_OK);
}
    

/***********************************************************************
 *				IbmDetachCmd
 ***********************************************************************
 * SYNOPSIS:	    Detach from the PC
 * CALLED BY:	    Tcl	
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    All patients are placed on the dead list
 *	    	    'attached' is set FALSE
 *
 * STRATEGY:
 *	For each patient in patients list:
 *	    Signal an EVENT_EXIT for it.
 *	    Nuke its thread state
 *	    Flip it onto the dead list
 *	Set 'attached' to FALSE.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/16/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(detach,IbmDetach,0,NULL,top.running,
"Usage:\n\
    detach [<options>]\n\
\n\
Examples:\n\
    \"detach cont\"   continue GEOS and quit Swat\n\
\n\
Synopsis:\n\
    Detach swat from the PC.\n\
\n\
Notes:\n\
    * The option argument may be one of the following:\n\
          continue  	continue GEOS and detach Swat \n\
          leave	    	keep GEOS stopped and detach Swat\n\
\n\
      Anything else causes Swat to just detach and GEOS to exit.\n\
\n\
    * You can use these options if you want to pass debugging control off to\n\
      another person remotely logged into your UNIX workstation.\n\
\n\
See also:\n\
    attach, quit\n\
")
{
    int	normal_exit=1;

    if (attached == FALSE) {
	Tcl_Error(interp, "already detached");
    }

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
    
    IbmDetachGuts(normal_exit, argc, argv);
    
    Tcl_Return(interp, "detach completed", TCL_STATIC);
    return(TCL_OK);
}


/***********************************************************************
 *				IbmConnectCmd
 ***********************************************************************
 * SYNOPSIS:	    Re-attach to the PC
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK if could.
 * SIDE EFFECTS:    Symbols may be re-read, etc.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/16/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(connect,IbmConnect,0,NULL,top.running,
"Usage:\n\
    connect [<boot>]\n\
\n\
Examples:\n\
    \"connect\"   attach to the PC and stop; PC must already be running GEOS.\n\
\n\
Synopsis:\n\
    Connects Swat to the PC, which must already be running GEOS.\n\
\n\
Notes:\n\
    * The <boot> argument should be \"-b\" to bootstrap and \"+b\" to \n\
      not, where bootstrapping means to locate and read the symbols for\n\
      a geode only when the geode is encountered, usually as the owner of\n\
      some memory or thread handle you've made Swat look up.\n\
\n\
    * If you give no <boot> argument, Swat will use the most-recent one.\n\
\n\
    * By default, Swat will locate the symbols for all the geodes and threads\n\
      active on the PC when it attaches.\n\
\n\
    * If any geode has changed since you detached from the PC, the symbols\n\
      for it are re-read.\n\
\n\
See also:\n\
    attach (att), detach, quit\n\
")
{
    if (attached == TRUE) {
	Tcl_Error(interp, "already attached");
    }

    if (argc == 2) {
	if (strcmp(argv[1], "-b") == 0) {
	    bootstrap = 1;
	} else if (strcmp(argv[1], "+b") == 0) {
	    bootstrap = 0;
	}
    }

#if defined(_MSDOS)
    if (commMode == CM_SERIAL)
    {
# if defined(_WIN32)
	char		workbuf[50];
	long		comport = 0;
	long		baudrate = 0;
	Boolean		retval;
# endif
	const char	*tty=0;

	tty = File_FetchConfigData("port");
	if (tty == NULL)
	{
# if defined(_WIN32)
	    tty = NULL;
	    retval = Registry_FindDWORDValue(Tcl_GetVar(interp, 
							"file-reg-swat", 
							TRUE),
					     "SERIAL_COM_PORT", &comport);
	    if (retval != FALSE) {
		retval = Registry_FindDWORDValue(Tcl_GetVar(interp, 
							    "file-reg-swat", 
							    TRUE),
						 "SERIAL_BAUD_RATE", 
						 &baudrate);
		if (retval != FALSE) {
		    sprintf(workbuf, "%d,%d", comport, baudrate);
		    tty = workbuf;
		}
	    }
# else
	    tty = getenv("PTTY");
# endif
	    if ((tty == NULL) || (tty[0] == '\0'))
	    {
	    	Message("Unable to determine serial port to use\n");
		sleep(5);
	    	if (Ui_Exit) 
		{
		    (*Ui_Exit)();
	    	}
		exit(1);
	    }
	}
# if !defined(_WIN32)
	if (!Serial_Init(tty, 0)) 
# else
	if (Rpc_NtserialInit(tty) == FALSE) 
# endif
	{
	    MessageFlush("Unable to initialize serial port \"%s\".", tty);
	    if (Ui_Exit) 
	    {
		(*Ui_Exit)();
	    }
	    exit(1);
	}
    }
#endif
    if (!Ibm_PingPC(TRUE)) {
	/*
	 * interp->result already set to the reason for the failure.
	 */
	return(TCL_ERROR);
    }
    
    curPatient->frame = MD_CurrentFrame();

    /*
     * Send initial FULLSTOP event to start the ball rolling.
     */
    (void)Event_Dispatch(EVENT_FULLSTOP, (Opaque)"Attached to GEOS");

    Tcl_Return(interp, NULL, TCL_STATIC);
    return(TCL_OK);
}

/***********************************************************************
 *				SymDefaultCmd
 ***********************************************************************
 * SYNOPSIS:	    Set the default patient to use for symbol lookups
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    defaultPatient is changed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/13/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(sym-default,IbmSymDefault,TCL_EXACT,NULL,top.print,
"Usage:\n\
    sym-default [<name>]\n\
\n\
Examples:\n\
    \"sym-default motif\"	    Make Swat look for any unknown symbols in the\n\
			    patient named \"motif\" once all other usual places\n\
			    have been searched.\n\
\n\
    \"sd motif\"	    Make Swat look for any unknown symbols in the\n\
			    patient named \"motif\" once all other usual places\n\
			    have been searched.\n\
Synopsis:\n\
    Specifies an additional place to search for symbols when all the usual\n\
    places have been searched to no avail.\n\
\n\
Notes:\n\
    * The named patient need not have been loaded yet when you execute this\n\
      command.\n\
\n\
    * A typical use of this is to make whatever program you're working on be\n\
      the sym-default in your .swat file so you don't need to worry about\n\
      whether it's the current one, or reachable from the current one, when\n\
      the machine stops and you want to examine the patient's state.\n\
\n\
    * If you don't give a name, you'll be returned the name of the current\n\
      sym-default.\n\
\n\
See also:\n\
    symbol, addr-parse\n\
")
{
    if (argc == 1) {
	if (defaultPatient != NULL) {
	    if (VALIDTPTR(defaultPatient, TAG_PNAME)) {
		Tcl_Return(interp, (char *)defaultPatient, TCL_STATIC);
	    } else {
		Tcl_Return(interp, defaultPatient->name, TCL_STATIC);
	    }
	} else {
	    Tcl_Return(interp, "none", TCL_STATIC);
	}
    } else if (argc > 2) {
	Tcl_Error(interp, "only one patient may be made the default");
    } else if (strcmp(argv[1], "none") == 0) {
	/*
	 * If defaultPatient is a patient name, free it.
	 */
	if (VALIDTPTR(defaultPatient, TAG_PNAME)) {
	    free((char *)defaultPatient);
	}
	defaultPatient = NULL;
    } else {
	Patient	patient = Patient_ByName(argv[1]);

	if (patient == NullPatient) {
	    defaultPatient = (Patient)malloc_tagged(strlen(argv[1])+1,
						    TAG_PNAME);
	    strcpy((char *)defaultPatient, argv[1]);
	    Tcl_RetPrintf(interp, "Warning: %s not loaded yet", argv[1]);
	    return(TCL_OK);
	} else {
	    defaultPatient = patient;
	}
    }
    return(TCL_OK);
}

/***********************************************************************
 *				IbmSaveStateCmd
 ***********************************************************************
 * SYNOPSIS:	    Save the state of the current thread.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    The current registers are stuffed at the head of the
 *	    	    thread's state stack.
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 4/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(save-state,IbmSaveState,1,NULL,swat_prog.patient|swat_prog.thread,
"Usage:\n\
    save-state\n\
\n\
Examples:\n\
    \"save-state\"	    Push the current register state onto the thread's\n\
			    state stack.\n\
\n\
Synopsis:\n\
    Records the state of the current thread (all its registers) for later\n\
    restoration by \"restore-state\".\n\
\n\
Notes:\n\
    * Swat maintains an internal state stack for each thread it knows, so\n\
      calling this has no effect on the PC.\n\
\n\
    * This won't save any memory contents, just the state of the thread's\n\
      registers.\n\
\n\
See also:\n\
    restore-state, discard-state\n\
")
{
    IbmRegs 	*cregs;
    ThreadPtr	cur;
    word    	junk;

    cur = (ThreadPtr)curPatient->curThread;
    if (cur == NullThread) {
	Tcl_Error(interp, "save-state: Current patient has no current thread");
    }
    /*
     * Make sure registers are loaded.
     */
    IbmReadThreadRegister16(cur, REG_MACHINE, REG_IP, &junk);
    cregs = (IbmRegs *)malloc_tagged(sizeof(IbmRegs), TAG_ETC);
    *cregs = cur->regs;
    (void)Lst_AtFront(cur->state, (LstClientData)cregs);

    return(TCL_OK);
}

/***********************************************************************
 *				IbmRestoreStateCmd
 ***********************************************************************
 * SYNOPSIS:	    Restore the most-recently-saved state
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK or TCL_ERROR
 * SIDE EFFECTS:    All registers for the current thread are restored.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 4/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(restore-state,IbmRestoreState,1,NULL,swat_prog.patient|swat_prog.thread,
"Usage:\n\
    restore-state\n\
\n\
Examples:\n\
    \"restore-state\"	    	Set all registers for the current thread to\n\
				the values saved by the most recent save-state.\n\
\n\
Synopsis:\n\
    Pops all the registers for a thread from the internal state stack.\n\
\n\
Notes:\n\
    * This is the companion to the \"save-state\" command.\n\
\n\
    * All the thread's registers are affected by this command.\n\
\n\
See also:\n\
    save-state\n\
")
{
    IbmRegs 	*cregs;
    ThreadPtr	cur;

    cur = (ThreadPtr)curPatient->curThread;
    if (cur == NullThread) {
	Tcl_Error(interp, "restore-state: no current thread");
    }
    if (Lst_IsEmpty(cur->state)) {
	Tcl_Error(interp, "restore-state: no state saved");
    }
    cregs = (IbmRegs *)Lst_DeQueue(cur->state);
    cur->regs = *cregs;
    cur->flags &= ~IBM_REGS_NEEDED;
    cur->flags |= IBM_REGS_DIRTY;

    free((char *)cregs);

    return(TCL_OK);
}

/***********************************************************************
 *				IbmDiscardStateCmd
 ***********************************************************************
 * SYNOPSIS:	    Throw away the top-most saved state.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    The top-most state record is freed and chucked.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 4/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(discard-state,IbmDiscardState,1,NULL,swat_prog.thread|swat_prog.patient,
"Usage:\n\
    discard-state\n\
\n\
Examples:\n\
    \"discard-state\"	    	Throw away the values for all the thread's\n\
				registers saved by the most-recent save-state\n\
\n\
Synopsis:\n\
    Throw away the state saved by the most-recent save-state command.\n\
\n\
Notes:\n\
    * This is usually only used in response to some error that makes it\n\
      pointless to return to the point where the save-state was performed.\n\
\n\
See also:\n\
    save-state, restore-state\n\
")
{
    ThreadPtr	cur;

    cur = (ThreadPtr)curPatient->curThread;
    if (cur == NullThread) {
	Tcl_Error(interp, "discard-state: no current thread");
    }
    if (Lst_IsEmpty(cur->state)) {
	Tcl_Error(interp, "discard-state: no state saved");
    }
    free((char *)Lst_DeQueue(cur->state));

    return(TCL_OK);
}
/*-
 *-----------------------------------------------------------------------
 * IbmContinueCmd --
 *	Continue the patient.
 *
 * Results:
 *	TCL_OK.
 *
 * Side Effects:
 *	The patient is continued using Ibm_Continue.
 *
 *-----------------------------------------------------------------------
 */
DEFCMD(continue-patient,IbmContinue,TCL_EXACT,NULL,swat_prog.patient,
"Usage:\n\
    continue-patient\n\
\n\
Examples:\n\
    \"continue-patient\"	    	Allow the machine to continue executing\n\
				GEOS.\n\
\n\
Synopsis:\n\
    Tell the stub to let the machine continue where it left off.\n\
\n\
Notes:\n\
    * This command does not wait for the machine to stop again before it\n\
      returns; once the machine is running, you're free to do whatever you\n\
      want, whether it's calling \"wait\", or examining memory periodically.\n\
\n\
See also:\n\
    step-patient\n\
")
{
    if (attached == FALSE) {
	Tcl_Error(interp, "not attached");
    }
	    
    /*
     * Make sure atBreakpoint is clear so the srcwin will properly display
     * the source code for the next breakpoint we hit.
     */
    Tcl_SetVar(interp, "atBreakpoint", "", TRUE);

    /*
     * Continue in the usual way.
     */
    Ibm_Continue();

    Tcl_Return(interp, NULL, TCL_STATIC);
    return(TCL_OK);
}

/***********************************************************************
 *				IbmStepCmd
 ***********************************************************************
 * SYNOPSIS:	    Execute a single instruction in the patient
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    The patient be stepped...
 *
 * STRATEGY:	    Just calls Ibm_SingleStep().
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/27/88	Initial Revision
 *
 ***********************************************************************/
static int
IbmStepEvent(Event event, Opaque callData, Opaque clientData)
{
    /*
     * Make sure the machine stays stopped...
     */
    *(Boolean *)callData = TRUE;
    return(EVENT_HANDLED);
}

DEFCMD(step-patient,IbmStep,TCL_EXACT,NULL,swat_prog.patient,
"Usage:\n\
    step-patient\n\
\n\
Examples:\n\
    \"step-patient\"	    	Execute a single instruction on the PC.\n\
\n\
Synopsis:\n\
    Causes the PC to execute a single instruction, returning only when the\n\
    instruction has been executed.\n\
\n\
Notes:\n\
    * Unlike the continue-patient command, this command will not return\n\
      until the machine has stopped again.\n\
\n\
    * No other thread will be allowed to run, as timer interrupts will be\n\
      turned off while the instruction is being executed.\n\
\n\
See also:\n\
    continue-patient\n\
")
{
    Event   	stepEvent;
    
    if (attached == FALSE) {
	Tcl_Error(interp, "not attached");
    }
    /*
     * Make sure the stop flag goes up when the single step is complete...
     */
    stepEvent = Event_Handle(EVENT_STEP, 0, IbmStepEvent, (ClientData)NULL);
    /*
     * Perform the step
     */
    Ibm_SingleStep();
    /*
     * Nuke the event we registered -- it's unnecessary now.
     */
    Event_Delete(stepEvent);
    return(TCL_OK);
}

/***********************************************************************
 *				IbmRegsCmd
 ***********************************************************************
 * SYNOPSIS:	    Print out the registers for the current thread.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    The registers will be fetched if not already
 *	    	    present.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/25/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(current-registers,IbmRegs,TCL_EXACT,NULL,swat_prog.thread|swat_prog.patient,
"Usage:\n\
    current-registers\n\
\n\
Examples:\n\
    \"current-registers\"		Returns a list of the current registers for\n\
				the current thread.\n\
\n\
Synopsis:\n\
    Returns all the registers for the current thread as a list of decimal\n\
    numbers.\n\
\n\
Notes:\n\
    * The mapping from element number to register name is contained in the\n\
      global variable \"regnums\", which is an assoc-list whose elements\n\
      contain the name of the register, then the element number.\n\
\n\
    * For your own consumption, the list is ordered ax, cx, dx, bx, sp, bp,\n\
      si, di, es, cs, ss, ds, ip, flags. You should use the \"regnums\" variable\n\
      when programming, however, as this may change at some point (e.g. to\n\
      accommodate the additional registers in the 386)\n\
\n\
    * If running in 32-bit register mode (\"stub-regs-are-32\" variable), the list\n\
      is extended with 32-bit values in the following order:\n\
      eax, ecx, edx, ebx, esp, ebp, esi, edi, fs, gs, eip.\n\
      \"regnums\" also contains this data.\n\
\n\
\n\
See also:\n\
    regnums\n\
")
{
    ThreadPtr	thread = (ThreadPtr)curPatient->curThread;

    if (thread == NullThread) {
	Tcl_Error(interp, "current patient has no registers");
    }
    
    if (thread->flags & IBM_REGS_NEEDED) {
	word	tid = Handle_ID(thread->handle);
	
	if (Rpc_Call(RPC_READ_REGS,
		     sizeof(tid), type_Word, (Opaque)&tid,
		     sizeof(IbmRegs), typeIbmRegs, (Opaque)&thread->regs))
	{
	    Tcl_Return(interp, "Couldn't read registers", TCL_STATIC);
	    return(TCL_ERROR);
	} else {
	    thread->flags &= ~(IBM_REGS_NEEDED|IBM_REGS_DIRTY);
	}
    }
    Tcl_RetPrintf(interp, 
#if REGS_32
        "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %ld %ld %ld %ld %ld %ld %ld %ld %d %d %ld",
#else
        "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d",
#endif
                  thread->regs.reg_regs[RegisterMapping(REG_AX)],
		  thread->regs.reg_regs[RegisterMapping(REG_CX)],
		  thread->regs.reg_regs[RegisterMapping(REG_DX)],
		  thread->regs.reg_regs[RegisterMapping(REG_BX)],
		  thread->regs.reg_regs[RegisterMapping(REG_SP)],
		  thread->regs.reg_regs[RegisterMapping(REG_BP)],
		  thread->regs.reg_regs[RegisterMapping(REG_SI)],
		  thread->regs.reg_regs[RegisterMapping(REG_DI)],
		  thread->regs.reg_regs[RegisterMapping(REG_ES)],
		  thread->regs.reg_regs[RegisterMapping(REG_CS)],
		  thread->regs.reg_regs[RegisterMapping(REG_SS)],
		  thread->regs.reg_regs[RegisterMapping(REG_DS)],
		  thread->regs.reg_ip,
#if REGS_32
                  (word)thread->regs.reg_eflags,
#else
                  thread->regs.reg_flags,
#endif
		  thread->regs.reg_xipPage
#if REGS_32
                  ,
                  Reg32(thread->regs, RegisterMapping(REG_EAX)),
                  Reg32(thread->regs, RegisterMapping(REG_ECX)),
                  Reg32(thread->regs, RegisterMapping(REG_EDX)),
                  Reg32(thread->regs, RegisterMapping(REG_EBX)),
                  Reg32(thread->regs, RegisterMapping(REG_ESP)),
                  Reg32(thread->regs, RegisterMapping(REG_EBP)),
                  Reg32(thread->regs, RegisterMapping(REG_ESI)),
                  Reg32(thread->regs, RegisterMapping(REG_EDI)),
		  thread->regs.reg_regs[RegisterMapping(REG_FS)],
		  thread->regs.reg_regs[RegisterMapping(REG_GS)],
                  thread->regs.reg_ip
#endif
                  );

    /*
     * If machine running, discard the registers we just fetched as they're
     * no longer valid.
     */
    if (sysFlags & PATIENT_RUNNING) {
	thread->flags |= IBM_REGS_NEEDED;
    }
    return(TCL_OK);
}

/***********************************************************************
 *				IbmStopCmd
 ***********************************************************************
 * SYNOPSIS:	    Stop the PC
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    The patient be stopped.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/27/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(stop-patient,IbmStop,TCL_EXACT,NULL,swat_prog.patient,
"Usage:\n\
    stop-patient\n\
\n\
Examples:\n\
    \"stop-patient\"	    	Stops the PC.\n\
\n\
Synopsis:\n\
    Stops the PC, in case you continued it and didn't wait for it to\n\
    stop on its own.\n\
\n\
Notes:\n\
    * This is different from the \"stop\" subcommand of the \"patient\" command.\n\
\n\
See also:\n\
    continue-patient\n\
")
{
    if (attached == FALSE) {
	Tcl_Error(interp, "not attached");
    }
    
    noFullStop++;
    Ibm_Stop();
    noFullStop--;

    return(TCL_OK);
}

/***********************************************************************
 *				IbmIOCmd
 ***********************************************************************
 * SYNOPSIS:	    Handler for "io" command to access I/O ports.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK and value...
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/13/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(io,IbmIO,1,NULL,system|lib_app_driver.net,
"Usage:\n\
    io [w] <port> [<value>]\n\
\n\
Examples:\n\
    \"io 21h\"	    	    	    Reads byte-sized I/O port 21h\n\
    \"io 20h 10\"	    	    	    Writes decimal 10 to byte-sized I/O port 20h\n\
\n\
Synopsis:\n\
    Provides access to any I/O port on the PC.\n\
\n\
Notes:\n\
    * If you give the optional first argument \"w\", Swat will perform a\n\
      16-bit I/O read or write, rather than the default 8-bit access. Be aware\n\
      that most devices don't handle this too well.\n\
\n\
    * <port> must be a number (in whatever radix); it cannot be a register\n\
      or other complex expression.\n\
\n\
    * If you don't give a <value>, you will be returned the contents of the\n\
      I/O port (it will not be printed to the screen).\n\
\n\
See also:\n\
    \n\
")
{
    Rpc_Proc	procNum;
    int	    	pnum;
    word    	port;

    if (argc < 2) {
io_usage:
	Tcl_Error(interp, "Usage: io [w] <port> [<value>]");
    }
    if (strcmp(argv[1], "w") == 0) {
	procNum = RPC_READ_IO16;
	pnum = 2;
    } else {
	procNum = RPC_READ_IO8;
	pnum = 1;
    }

    if (argv[pnum] == NULL) {
	goto io_usage;
    }

    port = cvtnum(argv[pnum], NULL);
    if (argv[pnum+1] != NULL) {
	IoWriteArgs iowa;

	iowa.iow_port = port;
	iowa.iow_value = cvtnum(argv[pnum+1], NULL);
	procNum += 2;
	if (Rpc_Call(procNum,
		     sizeof(iowa), typeIOWArgs, (Opaque)&iowa,
		     0, NullType, NullOpaque) != RPC_SUCCESS)
	{
	    Tcl_Return(interp, Rpc_LastError(), TCL_STATIC);
	    return(TCL_ERROR);
	} else {
	    Tcl_Return(interp, NULL, TCL_STATIC);
	}
    } else {
	word	w;
	
	if (Rpc_Call(procNum,
		     sizeof(word), type_Word, (Opaque)&port,
		     sizeof(word), type_Word, &w) != RPC_SUCCESS)
	{
	    Tcl_Return(interp, Rpc_LastError(), TCL_STATIC);
	    return(TCL_ERROR);
	} else {
	    Tcl_RetPrintf(interp, "%xh (%d)", w, w);
	}
    }
    return(TCL_OK);
}


/***********************************************************************
 *				IbmFillCmd
 ***********************************************************************
 * SYNOPSIS:	    Fill an area of memory with a single value
 * CALLED BY:	    TCL
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    Blocks affected are flushed to the PC before the fill
 *	    	    operation.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/26/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(fill,IbmFill,0,NULL,top.memory,
"Usage:\n\
    fill (byte|word) <addr> <length> <value>\n\
\n\
Examples:\n\
    \"fill b ds:20 10 0\"	    	Fills 10 bytes starting at ds:20 with 0\n\
\n\
Synopsis:\n\
    Allows you to quickly fill an area of memory with a particular value.\n\
\n\
Notes:\n\
    * This doesn't seem to work quite yet.\n\
\n\
    * <addr>, <length> and <value> are standard address expressions, so they\n\
      can be whatever you like. Only the offset portion of the <length> and\n\
      <value> expressions are used, however.\n\
\n\
    * If <addr> falls inside a block on the heap, <length> may not take the\n\
      fill outside the bounds of the block.\n\
\n\
    * \"byte\" and \"word\" may be abbreviated if you like.\n\
\n\
See also:\n\
")
{
    GeosAddr	addr,	    /* Address of start of fill */
		length,	    /* Number of bytes/words to fill */
		value;	    /* Value to store */
    Rpc_Proc	procNum;    /* Procedure to call */
    int	    	nbytes;	    /* Number of bytes affected */
    IbmKey  	key;	    /* Key for flushing affected blocks */
    int	    	i;  	    /* Number of bytes still affected */

    if (argc != 5) {
	Tcl_Error(interp,
		  "Usage: fill (b[yte]|w[ord]) <addr> <length> <value>");
    }

    if (!Expr_Eval(argv[2], NullFrame, &addr, (Type *)NULL, TRUE)) {
	Tcl_Error(interp, "couldn't parse <addr>");
    } else if (!Expr_Eval(argv[3], NullFrame, &length, (Type *)NULL, TRUE))
    {
	Tcl_Error(interp, "couldn't parse <length>");
    } else if (!Expr_Eval(argv[4], NullFrame, &value, (Type *)NULL, TRUE)){
	Tcl_Error(interp, "couldn't parse <value>");
    } else if (argv[1][0] == 'b') {
	procNum = RPC_FILL_MEM8;
	nbytes = (int)length.offset;
    } else if (argv[1][0] == 'w') {
	procNum = RPC_FILL_MEM16;
	nbytes = (int)length.offset * 2;
    } else {
	Tcl_Error(interp, "fill: first arg should be \"byte\" or \"word\"");
    }

    /*
     * Flush any blocks in the cache that are in the area covered. We
     * offset nbytes by the number of bytes in the first block in which
     * we're not really interested, but get because it's a package deal.
     */
    key.handle = addr.handle;
    key.offset = (Address)((dword)addr.offset & ~(cacheBlockSize-1));

    for (i = nbytes + ((dword)addr.offset & (cacheBlockSize-1));
	 i > 0;
	 i -= cacheBlockSize)
    {
	Cache_Entry entry;

	entry = Cache_Lookup(dataCache, (Address)&key);
	if (entry != NullEntry) {
	    /*
	     * Block's in the cache -- nuke it.
	     */
	    Cache_InvalidateOne(dataCache, entry);
	}
	key.offset += cacheBlockSize;
    }

    /*
     * Perform the actual fill after making sure the parameters are w/in
     * bounds.
     */
    if (addr.handle == NullHandle) {
	/*
	 * Perform absolute fill -- only make sure we won't be wrapping
	 * around.
	 */
	AbsFillArgs afa;
	
	procNum += RPC_FILL_ABS8 - RPC_FILL_MEM8;
	afa.afa_segment = SegmentOf(addr.offset) ;
	afa.afa_offset = OffsetOf(addr.offset) ;

	if ((dword)afa.afa_offset + nbytes > 0xffff) {
	    Tcl_Error(interp, "fill would overflow 64k block");
	}
	afa.afa_length = (word)length.offset;
	afa.afa_value = (word)value.offset;

	if (Rpc_Call(procNum,
		     sizeof(afa), typeAbsFillArgs, (Opaque)&afa,
		     0, NullType, NullOpaque) != RPC_SUCCESS)
	{
	    Tcl_RetPrintf(interp, "couldn't fill memory: %s", Rpc_LastError());
	    return(TCL_ERROR);
	}
    } else {
	/*
	 * Handle-relative: make sure it doesn't go outside the handle
	 */
	FillArgs    fa;

	if ((dword)addr.offset + nbytes > Handle_Size(addr.handle)) {
	    Tcl_Error(interp, "fill would overflow block bounds");
	}

	fa.fa_handle = Handle_ID(addr.handle);
	fa.fa_offset = (word)addr.offset;
	fa.fa_length = (word)length.offset;
	fa.fa_value = (word)value.offset;
	if (Rpc_Call(procNum,
		     sizeof(fa), typeFillArgs, (Opaque)&fa,
		     0, NullType, NullOpaque) != RPC_SUCCESS)
	{
	    Tcl_RetPrintf(interp, "couldn't fill memory: %s", Rpc_LastError());
	    return(TCL_ERROR);
	}
    }

    return(TCL_OK);
}
	

/***********************************************************************
 *				IbmCreateAlias
 ***********************************************************************
 * SYNOPSIS:	    Create a command alias for a patient or one of its
 *	    	    threads, allowing the user to switch more easily
 *	    	    between threads (e.g. using command completion)
 * CALLED BY:	    Ibm_NewGeode, Ibm_NewThread
 * RETURN:	    Nothing
 * SIDE EFFECTS:    If a command of the desired name isn't already
 *	    	    registered, we make one.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/23/90		Initial Revision
 *
 ***********************************************************************/
void
IbmCreateAlias(char 	*name)
{
    Tcl_CmdProc	*proc;	    	    /* Vars for Tcl_FetchCommand */
    int	    	flags;
    ClientData	clientData;
    Tcl_DelProc	*delProc;
    const char	*realName;

    if (Tcl_FetchCommand(interp, name, &realName,
			 &proc, &flags, &clientData, &delProc))
    {
	/*
	 * Command already exists -- don't add another one.
	 */
	return;
    } else {
	Tcl_CreateCommand(interp, name, IbmSwitchCmd, TCL_EXACT,
			  (ClientData)1, NoDelProc);
    }
}

/***********************************************************************
 *				IbmDestroyAlias
 ***********************************************************************
 * SYNOPSIS:	    Nuke a patient alias.
 * CALLED BY:	    IbmBiffPatient
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The command is removed if it refered to "switch"
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/23/90		Initial Revision
 *
 ***********************************************************************/
void
IbmDestroyAlias(char 	*name)
{
    Tcl_CmdProc	*proc;	    	    /* Vars for Tcl_FetchCommand */
    int	    	flags;
    ClientData	clientData;
    Tcl_DelProc	*delProc;
    const char	*realName;

    if (!Tcl_FetchCommand(interp, name, &realName, &proc, &flags, &clientData,
			  &delProc))
    {
	/*
	 * Command doesn't exist -- nothing to nuke.
	 */
	return;
    } else if (proc == IbmSwitchCmd) {
	Tcl_DeleteCommand(interp, name);
    }
}


/***********************************************************************
 *				IbmDosSymCmd
 ***********************************************************************
 * SYNOPSIS:	    
 * CALLED BY:	    
 * RETURN:	    
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/16/93		Initial Revision
 *
 ***********************************************************************/
DEFCMD(dossym,IbmDosSym,TCL_EXACT,NULL,obscure,
"Usage:\n\
    dossym <patient-name> <symfile> <exefile> <baseseg>\n\
\n\
Examples:\n\
    \"dossym cserv cs.sym cs.exe 0x467\"	Creates a patient called \"cserv\"\n\
					for a DOS TSR or driver located\n\
					at 0x467:0, using the symbolic\n\
					info in cs.sym. The driver was\n\
					loaded from cs.exe\n\
\n\
Synopsis:\n\
    Allows one to more easily debug TSRs and device drivers, assuming you\n\
    have their .map file converted to a .sym file via map2sym\n\
\n\
Notes:\n\
    * If a patient named <patient-name> already exists, it will be destroyed.\n\
\n\
See also:\n\
    none.\n\
")
{
    Patient 	    	patient;
    short	    	status;
    ObjHeader   	*hdr;
    VMBlockHandle	map;
    short	    	major, minor;
    static word	    	nextHandleID = 0;
    ObjSegment	    	*seg;
    word    	    	baseSeg;
    word    	    	size;
    int	    	    	i;
    Handle  	    	dos;
    byte    	    	sig;
    
    
    if (argc != 4) {
	Tcl_Error(interp, "Usage: dossym <patient-name> <symfile> <baseseg>");
    }

    baseSeg = cvtnum(argv[3], 0);

    /*
     * Look in the DOS block header to find the size of the memory block so
     * none of the handles we create go beyond the pale.
     */
    /* TBD:  Are we really able to do anything with a baseSeg-1 situation? */
    Ibm_ReadBytes(1,NullHandle, (Address)(((dword)baseSeg-1)<<4), (genptr)&sig);
    if (sig != 'M') {
	/*
	 * Assume pointed to first code seg, while block holds the PSP too, and
	 * subtract 16 (we're talking paragraphs here) from baseSeg to get to
	 * the start of the block.
	 */
	Var_FetchInt(2, NullHandle, (Address)((((dword)baseSeg-16-1)<<4)+3),
		     (genptr)&size);
	size -= 16;
    } else {
	Var_FetchInt(2, NullHandle, (Address)((((dword)baseSeg-1)<<4)+3),
		     (genptr)&size);
    }

    patient = Patient_ByName(argv[1]);
    if (patient != NullPatient) {
	if (!patient->dos) {
	    Tcl_RetPrintf(interp, "Non-DOS patient %s already exists",
			  argv[1]);
	    return(TCL_ERROR);
	}
	Tcl_Error(interp, "Can't do this yet.");
	/* nuke old patient here */
    }

    patient = (Patient)calloc_tagged(1, sizeof(PatientRec), TAG_PATIENT);
    patient->name = (char *)malloc_tagged(strlen(argv[1])+1, TAG_PNAME);
    strcpy(patient->name, argv[1]);
    patient->path = (char *)malloc_tagged(strlen(argv[2])+1, TAG_PNAME);
    strcpy(patient->path, argv[2]);

    patient->symFile = VMOpen(VMO_OPEN|FILE_DENY_W|FILE_ACCESS_R, 0,
			      patient->path, &status);
    if (patient->symFile == NULL) {
	if (status == EINVAL) {
	    Tcl_RetPrintf(interp, "Could not open \"%s\" -- file is damaged",
			  patient->path);
	} else {
	    Tcl_RetPrintf(interp, "Could not open \"%s\"", patient->path);
	}
clean_up:
	free((malloc_t)patient->path);
	free((malloc_t)patient->name);
	free((malloc_t)patient);
	return(TCL_ERROR);
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
	Tcl_RetPrintf(interp,
		      "\"%s\" is incompatible with this version of Swat",
		      patient->path);
	VMClose(patient->symFile);
	goto clean_up;
    }
    
    map = VMGetMapBlock(patient->symFile);
    if (map == 0) {
	VMClose(patient->symFile);
	Tcl_RetPrintf(interp, "\"%s\" has no map block", patient->path);
	goto clean_up;
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
	    Tcl_RetPrintf(interp, "\"%s\" is not a symbol file\n",
			  patient->path);
	    VMUnlock(patient->symFile, map);
	    VMClose(patient->symFile);
	    goto clean_up;
    }

    patient->numRes = hdr->numSeg;
    patient->resources = (ResourcePtr)calloc_tagged(patient->numRes,
						    sizeof(ResourceRec),
						    TAG_PATIENT);

    curPatient = patient;
    patient->dos = TRUE;
    Sym_Init(patient);

    if (nextHandleID == 0) {
	nextHandleID = loader->numRes + 10;
    }

    /*
     * Initialize resources[0].handle to Null so we can use it as the
     * owner in the loop (Handle_Create takes a Null owner as meaning it
     * owns itself)
     */
    patient->resources[0].handle =
	Handle_Create(patient,
		      nextHandleID,
		      NullHandle,
		      0,
		      0,
		      HANDLE_PROCESS|HANDLE_KERNEL|HANDLE_MEMORY|HANDLE_DISCARDABLE|HANDLE_DISCARDED,
		      (Opaque)0, HANDLE_NOT_XIP);

    /*
     * RESIZE DOSSeg HANDLE TO NOT OVERLAP THIS THING.
     */
    i = IbmFindLRes("DOSSeg");
    assert(i != 0);
    dos = loader->resources[i].handle;
    
    if (Handle_Segment(dos) + (Handle_Size(dos) >> 4) > baseSeg) {
	Handle_Change(dos, HANDLE_SIZE,
		      0, 0, 
                      MakeAddress(baseSeg-Handle_Segment(dos), 0), 
                      0, -1);
    }
    
    /*
     * Create handles for all the resources, making them non-resident
     * loader memory handles. The "core block" is made a PROCESS handle,
     * b/c that's sort of what it is...
     *
     */
    for (i = 1, seg = ObjFirstEntry(hdr, ObjSegment)+1, nextHandleID++;
	 i < patient->numRes;
	 i++, seg++, nextHandleID++)
    {
	Address	addr = MakeAddress(baseSeg + seg->data, 0) ;
	dword	ssize = patient->resources[i].size;
	long    flags = HANDLE_KERNEL|HANDLE_MEMORY|HANDLE_FIXED|HANDLE_IN;

	if (baseSeg + seg->data >= baseSeg + size) {
	    addr = 0;
	    flags = HANDLE_KERNEL|HANDLE_MEMORY|HANDLE_DISCARDED;
	} else if (baseSeg+seg->data+((ssize+15) >> 4) > baseSeg+size) {
	    ssize -= seg->data + ((ssize+15)>>4) - size;
	}
	
	patient->resources[i].handle =
	    Handle_Create(patient,	    	    	    /* Patient */
			  nextHandleID,  	    	    	    /* ID */
			  patient->resources[0].handle,  /* Owner */
			  addr,
			  ssize,
			  flags,    	        /* other (resid) */
			  (Opaque)i, HANDLE_NOT_XIP);
    }
    
    /*
     * Set up the rest of the cruft.
     */
    patient->core = patient->resources[0].handle;
    patient->geode.v2 = (Geode2Ptr)NULL;
    patient->threads = Lst_Init(FALSE);
    patient->curThread = (Thread)NULL;

    VMUnlock(patient->symFile, map);

    patient->scope = patient->global;
    patient->line = -1;

    (void)Lst_AtEnd(patients, (LstClientData)patient);
    IbmCreateAlias(patient->name);

    Ibm86_Init(patient);

    
    for (i = 0; i < loader->numLibs; i++) {
	if (loader->libraries[i] == patient) {
	    break;
	}
    }
    if (i == loader->numLibs) {
	loader->numLibs++;
	loader->libraries =
	    (Patient *)realloc_tagged((char *)loader->libraries,
				      (i+1) * sizeof(Patient));
	loader->libraries[i] = patient;
    }

    (void)Event_Dispatch(EVENT_START, (Opaque)patient);

    Tcl_RetPrintf(interp, "%d", patient);
    return(TCL_OK);
}
    

/***********************************************************************
 *				IbmCmd_Init
 ***********************************************************************
 * SYNOPSIS:	    Register all commands provided by this here module
 * CALLED BY:	    Ibm_Init
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Yeah. Read the synopsis, twit.
 *
 * STRATEGY:	    Look, I told you to read the synopsis, didn't I?
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/26/89		Initial Revision
 *
 ***********************************************************************/
void
IbmCmd_Init(void)
{
    Cmd_Create(&IbmContinueCmdRec);
    Cmd_Create(&IbmStepCmdRec);
    Cmd_Create(&IbmStopCmdRec);
    Cmd_Create(&IbmRegsCmdRec);
    Cmd_Create(&IbmStopCatchCmdRec);
    Cmd_Create(&IbmSwitchCmdRec);
    Cmd_Create(&IbmPatientCmdRec);
    Cmd_Create(&IbmThreadCmdRec);
    Cmd_Create(&IbmSetMasksCmdRec);
    Cmd_Create(&IbmSaveStateCmdRec);
    Cmd_Create(&IbmRestoreStateCmdRec);
    Cmd_Create(&IbmDiscardStateCmdRec);
    Cmd_Create(&IbmSymDefaultCmdRec);
    Cmd_Create(&IbmDetachCmdRec);
    Cmd_Create(&IbmConnectCmdRec);
    Cmd_Create(&IbmIOCmdRec);
    Cmd_Create(&IbmLinkCmdRec);
    Cmd_Create(&IbmFillCmdRec);
    Cmd_Create(&IbmDosSymCmdRec);
}
