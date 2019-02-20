/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1988-1993 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Entry point, global variables, utilities
 * FILE:	  swat.c
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Punt	    	    Abort with message
 *	abort	    	    Query to abort
 *	cvtnum	    	    Convert a number from ASCII based on radix
 *	    	    	    characters
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Main file for Swat -- utilities and entry point.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: swat.c,v 4.30 97/04/18 16:42:26 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "event.h"
#include "private.h"
#include "ui.h"
#include "gc.h"
#include "cmd.h"
#include "file.h"
#include "type.h"
#include "break.h"
#include "value.h"
#include "src.h"
#include "ibmXms.h"
#include <compat/stdlib.h>
#include "mallint.h"

#include <ctype.h>
#include <stdarg.h>

#if defined(unix)
# include <sys/signal.h>
#else
# include    <signal.h>
int	    reallyExit = 0;
#endif

#if defined(_MSDOS)
# include <mouse.h>
#endif

#if defined(_WIN32)
# include <conio.h>
#endif
/*
 *	    GLOBAL VARIABLES
 */
int  	    debug;
int	    swap;
int	    sysStep;
Tcl_Interp  *interp;
Patient	    defaultPatient;
Table	    privateDataTable;
int	    dbcsRelease = 0;

Frame	    *(*MD_GetFrame)(word ss, word sp, word cs, word ip);
Frame 	    *(*MD_CurrentFrame)(void);
Frame 	    *(*MD_NextFrame)(Frame *curFrame);
Frame 	    *(*MD_PrevFrame)(Frame *curFrame);
Frame 	    *(*MD_CopyFrame)(Frame *frame);
Boolean     (*MD_FrameValid)(const Frame *frame);
void 	    (*MD_DestroyFrame)(Frame *frame);
void	    (*MD_FrameInfo)(Frame *frame);
GeosAddr    (*MD_ReturnAddress)(void);
GeosAddr    (*MD_FunctionStart)(Handle handle, word offset);
GeosAddr    (*MD_FrameRetaddr)(Frame *frame);
Boolean     (*MD_GetFrameRegister)(Frame *frame,
				   RegType regType, int regNum,
				   regval *valuePtr);
Boolean     (*MD_SetFrameRegister)(Frame *frame,
				   RegType regType, int regNum,
				   regval value);
Opaque 	    (*MD_SetBreak)(Handle handle, Address address);
void 	    (*MD_ClearBreak)(Handle handle, Address address, Opaque data);
Boolean     (*MD_Decode)(Handle handle, Address offset, char *buffer,
			 int *instSizePtr, char *decode);
#if defined(_WIN32)
int win32dbg;		  /* whether or not to be verbose w/ error messages */
#endif

void	Usage(void);

Boolean symCache=TRUE;
Boolean ignoreSymSerial=FALSE;

#if defined(__HIGHC__)
/*
 * Avoid conflict with "abort" module of hc386.lib, which defines this
 * variable, on which we seem to depend...
 */
int	    _mwdefault_raise = 0;
#endif


/***********************************************************************
 *				Status_Changed
 ***********************************************************************
 * SYNOPSIS:	    Signal a status change
 * CALLED BY:	    FrameCmd and others
 * RETURN:	    Nothing
 * SIDE EFFECTS:    A STACK event is dispatched.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/23/89		Initial Revision
 *
 ***********************************************************************/
void
Status_Changed(void)
{
    (void)Event_Dispatch(EVENT_STACK, (Opaque)NULL);
}



/***********************************************************************
 *				abort
 ***********************************************************************
 * SYNOPSIS:	    See if the user really wants to abort.
 * CALLED BY:	    Error routines
 * RETURN:	
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/30/88	Initial Revision
 *
 ***********************************************************************/
#if defined(__GNUC__)
volatile
#endif
void
abort(void)
{
    char    ans[32];
#if defined(unix)
    extern volatile void _abort(void);
    extern volatile void exit(int status);
#else
    extern void PokeMDB(void);
#endif
    extern volatile void Ui_TopLevel(void);

#if !defined(unix)
    if (reallyExit) {
	_exit(1);
    }
#endif

    while (1) {
#if defined(unix)
	MessageFlush("Do you want to abort (pid = %d)?[ynr] ", getpid());
#elif defined(_MSDOS)
	MessageFlush("\nDo you want to abort?[ynp] ");
#else
	MessageFlush("\nDo you want to abort?[yn] ");
#endif
	Ui_ReadLine(ans);
	if (ans[0] == 'N' || ans[0] == 'n') {
	    /*
	     * Doesn't want to abort, but can't continue, so go back to top
	     * level.
	     */
	    MessageFlush("Returning to top level\n");
	    Ui_TopLevel();
	} else if (ans[0] == 'R' || ans[0] == 'r') {
	    /*
	     * Wants to retry the operation. Probably me trying to pin down
	     * a bug...I'm sure this will cause gcc to have fits...
	     */
	    return;
#if defined(_MSDOS)
	} else if (ans[0] == 'P' || ans[0] == 'p') {
	    PokeMDB();
#endif
	} else if (ans[0] != 'y' && ans[0] != 'Y') {
	    MessageFlush("I'm afraid that's not acceptable...\n");
	} else {
	    break;
	}
    }

    if (Ui_Exit) {
	(*Ui_Exit)();
    }

    /*
     * Do real abort
     */
#if defined(unix)
    if (debug) {
	_abort();
    } else {
	exit(0);
    }
#else
    reallyExit = TRUE;
    exit(0);
#endif
}
#if defined(unix)
void busErr(void) {Message("Bus Error..."); abort();}
void segv(void) {Message("Segmentation Violation..."); abort(); }
#endif

/*-
 *-----------------------------------------------------------------------
 * Punt --
 *	Warn the user something evil has happened and abort.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The program abort()s
 *
 *-----------------------------------------------------------------------
 */
/*VARARGS1*/
volatile void
Punt(const char   *msg, ...)
{
#if defined(unix)
    extern volatile void exit(int status);
#endif
    va_list args;

    va_start(args, msg);

#if defined(_WIN32)
    if (MessageFlush != NULL) {
	char resultmsg[1000];

	vsprintf(resultmsg, msg, args);
	strcat(resultmsg, "\n");
	MessageFlush(resultmsg);
    } else
#endif
    {
	vprintf(msg, args);
	putchar('\n');
	fflush(stdout);
    }

    va_end(args);

    if (MessageFlush != NULL) {
        /*
	 * UI initialized -- use regular abort() function
	 */
	abort();
    } else {
	/*
	 * Exit now...
	 */
#if defined(_WIN32)
	/*
	 * pause so user can see error message before window closes
	 */
	fprintf(stdout, "\n\nPress any key to exit swat\n");
	fflush(stdout);
	getch();
#endif
	exit(1);
    }
}

#if defined(_WIN32)

/***********************************************************************
 *				Swat_Death
 ***********************************************************************
 *
 * SYNOPSIS:	    abort after 
 * CALLED BY:	    EXTERNAL
 * RETURN:	    void
 * SIDE EFFECTS:    exits swat
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	1/17/97   	Initial Revision
 *
 ***********************************************************************/
void
Swat_Death (void)
{
    /*
     * pause so user can see error message before window closes
     */
    if (MessageFlush != NULL) {
	MessageFlush("\n\nPress any key to exit swat\n");
    } else {
	fprintf(stdout, "\n\nPress any key to exit swat\n");
    }
    getch();
    if (Ui_Exit) {
	(*Ui_Exit)();
    }
    exit(1);
}	/* End of RpcDeath.	*/
#endif


/***********************************************************************
 *				cvtnum
 ***********************************************************************
 * SYNOPSIS:	    Converts a number from ascii to an integer, paying
 *	    	    attention to radix indicators, etc.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    the integer and the end-of-number pointer
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 5/88	Initial Revision
 *
 ***********************************************************************/
int
cvtnum(const char *cp,
       char **endPtr)
{
    /*
     * Constant -- figure out the radix (can be specified either masm's
     * way or C's way) and convert to an integer, returning that
     * integer and CONSTANT.
     */
    int		base = 10, baseSet = 0;
    const char 	*start = cp, *end = 0;
    char    	c;
    int	    	n;
    int	    	negate = 0;

    if (*cp == '-') {
	cp++;
	negate = 1;
	start++;
    } else if (*cp == '+') {
	cp++;
	start++;
    }
    
    /*
     * Read in all valid digits (valid == in hex set)
     */
    if (*cp == '0') {
	/*
	 * Deal with C syntax first, looking for an x or an X after the
	 * 0. If so, set the base to be 16 and throw away the two
	 * characters. Otherwise, store the 0 at the front of id.
	 */
	c = *++cp;
	if ((c == 'x') || (c == 'X')) {
	    baseSet = base = 16;
	    start = ++cp;
	}
    }
    
    while (isxdigit(*cp)) {
	cp++;
    }
    
    /*
     * See if stopped on one of the MASM base identifiers. The ones
     * that aren't valid hex digits are h, q and o. b and d we deal
     * with later.
     */
    if (!baseSet) {
	switch (*cp) {
	    case 'h':
	    case 'H':
		baseSet = base = 16;
		end = cp+1;
		break;
	    case 'q':
	    case 'Q':
	    case 'o':
	    case 'O':
		baseSet = base = 8;
		end = cp+1;
		break;
	}
    }
    
    if (!baseSet && (*start == '0')) {
	/*
	 * If it begins with a 0, and we haven't already decided on a
	 * base, it's base 8.
	 */
	baseSet = base = 8;
	end = (char *)cp;
    } 
    
    /*
     * If base still isn't set, the terminator wasn't a radix indicator,
     * nor do we have a C-style radix indication. Unfortunately, the
     * radix characters b and d are both valid hex digits. If they
     * come at the end of the scanned number, they are radix
     * characters.
     */
    if (!baseSet) {
	switch (cp[-1]) {
	    case 'b':
	    case 'B':
		base = 2;
		/*FALLTHRU*/
	    case 'd':
	    case 'D':
		baseSet = 1;
		end = cp--;
		break;
	    default:
		end = cp;
		break;
	}
    } else if (end == NULL) {
	end = cp;
    }
    
    n = 0;

    /*
     * If only a radix char, signal our displeasure by indicating nothing
     * parsed.
     */
    if (start == cp) {
	end = start;
    }

    while (start < cp) {
	int d;
	
	n *= base;
	if (isdigit(*start)) {
	    d = *start++ - '0';
	} else if (*start <= 'F') {
	    d = *start++ - 'A' + 10;
	} else {
	    d = *start++ - 'a' + 10;
	}
	if (d >= base) {
	    /*
	     * If out-of-bounds, stop now. This will likely cause death
	     * in the expression parser, but that's what happens when you
	     * forget a radix character at the end. Better than getting
	     * 25 for "1f"...
	     */
	    end = cp = start-1;
	} else {
	    n += d;
	}
    }

    if (endPtr) {
	*endPtr = (char *)end;
    }

    return(negate ? -n: n);
}
    
int
main(int    argc,
     char   **argv)
{
    extern char	    *Version(void);
    char    	    *kernelFile;
    int	    	    ac;
    char	    **av;
    const char 	    *sourceBranch;
    int	    	    startup = ST_NONE;
    int	    	    cont=0;
#if defined(unix)
    int	    	    waitForAttach = 0;
#elif defined(_WIN32)
    char	    *sdkVersion;

    win32dbg = FALSE;
#endif

    /*
     * Figure out the name of the kernel to use.
     */
    kernelFile = "geosec.exe";

    for (ac = argc, av = &argv[1]; ac > 1; ac--, av++) {
        if (**av == '-' || **av == '/') {
	    switch (av[0][1]) 
	    {
	        case 'C':
		    if (av[0][2] == '\0') {
			symCache = FALSE;
		    }
		    break;
		case 'h':
		case 'H':
		    if (av[0][2] == '\0') {
		    	(void)Usage();
			exit(0);
		    }
		    break;
#if defined(unix)
	        case 'w':
		    if (av[0][2] == '\0') {
			waitForAttach = 1;
		    }
		    break;
#endif
		case 'D':
		    if (av[0][2] == '\0') {
			debug += 1;
			/*
			 * Turn on argument-checks in the malloc routines
			 */
			malloc_debug(debug);
		    }
		    break;
		case 'k':
		case 'K':
		    if (av[0][2] == '\0') {
		    	if (ac > 2) 
			{
		    	    kernelFile = av[1];
			    av++, ac--;
			}
		     	else 
			{
		    	    printf("-k needs kernel name as arg\n");
			    printf("Using %s...\n", kernelFile);
		    	}
		    }
		    break;
			
		case 'n':
		case 'N':
		    if (av[0][2] == '\0') {
		    	startup = ST_NON_EC_S;
			cont = 1;
		    }
		    break;
		case 's':
		case 'S':
	       	case 'r':
		case 'R':
		        startup = ST_EC_S;
		    	switch (av[0][2])
			{
		    	    case 'n':
	            	    case 'N':
				if (av[0][3] == '\0') {
				    startup = ST_NON_EC_S;
				    if (av[0][1] == 'r' || av[0][1] == 'R')
				    {
					cont = 1;
				    }
				}
		    	    	break;
	            	    case 's':
	            	    case 'S':
				if (av[0][3] != '\0') {
				    break;
				}
			    case '\0':
				if ((av[0][1] == 'r' || av[0][1] == 'R') && 
				     (av[0][2] == '\0'))
				{
				    cont = 1;
				}
				break;
		       }
		case 'I':
		case 'i':
		 	ignoreSymSerial = TRUE;
		 	break;
	    }
	}
    }

    /*
     * Initialize the list of all patients
     */
    patients = Lst_Init(FALSE);

    /* if we have no startup flag, pass in the EC startup, as if GEOS is
     * already running it will ignore this, and if not it will crank up
     * the EC version if it can
     */
    if (startup == ST_NONE) {
	startup = ST_EC_S;
#if defined(_MSDOS)
	cont = 1;
#endif
    }
    /*
     * Catch these since the kernel won't let us ignore them from the debugger,
     * nor can we continue after receiving them, but we may be able to longjmp
     * out of them...
     */
#if defined(unix)
    signal(SIGBUS, busErr);
    signal(SIGSEGV, segv);
    signal(SIGPIPE, SIG_IGN);	/* For "stream" command to sockets... */
#endif

    /*
     * Create main interpreter for the system
     */
    interp = Tcl_CreateInterp();
	
    GC_Init();
    Cmd_Init();
    
    File_Init(&argc, argv);

    Event_Init();
    Private_Init();
    Type_Init();
    Break_Init();
    Value_Init();
    Ui_Init(&argc, argv);
    Src_Init();
    IbmXms_Init();
#if defined(_MSDOS)
    Mouse_Init();
#endif
    /* Report the version of Swat and the version of GEOS */
    sourceBranch = Tcl_GetVar(interp, "file-branch", 1);
    if (*sourceBranch == '\0') {
	sourceBranch = "trunk";
    }
    MessageFlush("%s.\nUsing the %s version of GEOS.\n", 
		 Version(), sourceBranch);
#if defined(_WIN32)
    sdkVersion = Tcl_GetVar(interp, "file-reg-ntsdk", 1);
    if (strrchr(sdkVersion, '\\') != NULL) {
	sdkVersion = strrchr(sdkVersion, '\\');
	sdkVersion++;
    }
    MessageFlush("SDK version: %s\n", sdkVersion, 1);

    if (win32dbg == TRUE) {
	MessageFlush("Debug Mode: ON\n");
    }
#endif


#if defined(unix)
    if (waitForAttach) {
	MessageFlush("Waiting for debugger attach.\n");
	abort();
    }
#endif
    /*
     * Allocate a Patient handle for the loader and let Ibm_Init fill
     * everything in.
     */
    loader = (Patient)calloc_tagged(1, sizeof(struct _Patient), TAG_PATIENT);

    Ibm_Init(kernelFile, &argc, argv, startup);
    if (cont)
    {
	Tcl_SetVar(interp, "continueStartup", "TRUE", 1);
    }
	
    /*
     * Set the global "argv" variable to be the remaining arguments.
     */
    Tcl_SetVar(interp, "argv", Tcl_Merge(argc, argv), 1);

    /*
     * Go run things -- this never returns.
     */
    Ui_TopLevel();

#if defined(__HIGHC__) || defined(__BORLANDC__)
    return 0;   /* never gets executed, but makes HighC happy */
#endif

}
			
/*VARARGS1*/
void
dprintf(char *msg, ...)
{
    extern int debug;

    if (debug) {
	va_list args;
	
	va_start(args, msg);
	Message(msg, args);
	va_end(args);
    }
}

/*********************************************************************
 *			Usage
 *********************************************************************
 * SYNOPSIS: 	    show options for swat
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	7/30/93		Initial version			     
 * 
 *********************************************************************/
void
Usage(void)
{
    printf("Usage: swat [-N]\n");
    printf("-N is used to start up the NON-EC version of GEOS\n");
    printf("-C is used to disable symbol file path caching\n");
    printf("-net <net address> is used to run swat over the network\n");
    printf("If geos is already running, or you want to run the EC version\n");
    printf("	no flag is needed\n");
}





