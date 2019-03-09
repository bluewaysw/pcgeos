/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  SWAT -- User Interface initialization and utilities
 * FILE:	  ui.c
 *
 * AUTHOR:  	  Adam de Boor: Dec  7, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Ui_Init	    	    Decide what interface to use and initialize it.
 *	Ui_Interrupt	    See if an interrupt has happened.
 *	Ui_TopLevel 	    Top-level command loop. Returns to top-most
 *	    	    	    level when called.
 *	Ui_AllowInterrupts  Enable or disable keyboard interrupts.
 *	Ui_ClearInterrupt   Clear any recognized interrupt.
 *	Ui_CheckInterrupt   See if an interrupt has occurred and return
 *	    	       	    to top level if so.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	12/ 7/88  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Initialization and general routines for the User-Interface.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: ui.c,v 4.14 97/04/18 16:58:37 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "cmd.h"
#include "event.h"
#include "file.h"
#include "tclDebug.h"
#include "rpc.h"
#include "ui.h"
#include <compat/stdlib.h>

#if defined(_WIN32)
# undef FIXED
# undef LONG
# define LONG LONG_biff
# define SID SID_biff
# define timeval timeval_biff
# undef timercmp
# define timercmp timercmp_biff
# define fd_set fd_set_biff
# include <compat/windows.h>
# undef fd_set
# undef timercmp
# undef timeval
# undef SID
# undef LONG
# define FIXED 0x80
#endif

#if defined(_WIN32)
# undef sleep
# define sleep(s) (Sleep((s) * 1000))
#endif

#include <signal.h>

#include "safesjmp.h"

#if defined(_WIN32)
# include <winutil.h>

HANDLE cntlcEvent;
#endif

static int  uiFlags;	    /* Flags for this module */
#define UI_INITIALIZED	1   	/* Module initialized (gone through Ui_TopLevel
				 * once) */
#if !defined(_MSDOS)
# define UI_IRQ	    	2   	/* Interrupt requested */
#else
extern byte _far *irq;	    	/* Maintained by keyboard-interrupt handler
				 * in serial.asm */
#endif

static int  current_level = 0;
static int  noInterruptCount=0;	/* Number of folks not wanting to allow
				 * interrupts */

extern void Shell_Init(void), Curses_Init(void);
void 	(*Message)(const char *fmt, ...); 	/* Standard messages */
void 	(*Warning)(const char *fmt, ...); 	/* Warning/error messages */
void 	(*MessageFlush)(const char *fmt, ...);	/* Immediate messages */
void 	(*Ui_ReadLine)(char *line); 	    /* Read a line o' input w/o
					     * paying attention to rpc's */
int  	(*Ui_NumColumns)(void);	    	    /* Number of columns available
					     * for formatting things. */
void	(*Ui_Exit)(void);	    	    /* Shutdown procedure */


/***********************************************************************
 *				UiIrqCmd
 ***********************************************************************
 * SYNOPSIS:	    Set or get the interrupt pending flag
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    The UI_IRQ flag may change state
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(irq,UiIrq,TCL_EXACT,NULL,swat_prog,
"Usage:\n\
    irq\n\
    irq (no|yes)\n\
    irq (set|clear)\n\
\n\
Examples:\n\
    \"irq\"	    	    Returns non-zero if an interrupt is pending\n\
    \"irq no\"	    	    Disable recognition and acting on a break request\n\
			    from the keyboard.\n\
    \"irq set\"	    	    Pretend user typed Ctrl+C\n\
\n\
Synopsis:\n\
    Controls Swat's behaviour with respect to interrupt requests from the\n\
    keyboard.\n\
\n\
Notes:\n\
    * Swat maintains an interrupt-pending flag that is set when you type\n\
      Ctrl+C (it can also be set or cleared by this command). It delays acting\n\
      on the interrupt until the start of the next or the completion of the\n\
      current Tcl command, whichever comes first.\n\
\n\
    * When given no arguments, it returns the current state of the\n\
      interrupt-pending flag. This will only ever be non-zero if Swat is\n\
      ignoring the flag (since the command wouldn't actually return if the\n\
      flag were set and being paid attention to, as the interpreter would\n\
      act on the flag to vault straight back to the command prompt).\n\
\n\
    * If given \"no\" or \"yes\" as an argument, it causes Swat to ignore or\n\
      pay attention to the interrupt-pending flag, respectively.\n\
\n\
    * You can set or clear the flag by giving \"set\" or \"clear\" as an argument.\n\
\n\
See also:\n\
    none.\n\
")
{
    if (argc == 1) {
#if !defined(_MSDOS)
	Tcl_Return(interp, uiFlags & UI_IRQ ? "1" : "0", TCL_STATIC);
#else	
	Tcl_Return(interp, *irq ? "1" : "0", TCL_STATIC);
#endif
	return(TCL_OK);
    } else {
	char	*endStr;
	int 	arg = cvtnum(argv[1], &endStr);

	if (*endStr != '\0') {
	    if (strcmp(argv[1], "set") == 0) {
#if !defined(_MSDOS)
		uiFlags |= UI_IRQ;
#else
		*irq = TRUE;
#endif
	    } else if (strcmp(argv[1], "clear") == 0) {
#if !defined(_MSDOS)
		uiFlags &= ~UI_IRQ;
#else
		*irq = FALSE;
#endif
	    } else if (strcmp(argv[1], "no") == 0) {
		Ui_AllowInterrupts(0);
	    } else if (strcmp(argv[1], "yes") == 0) {
		Ui_AllowInterrupts(1);
	    } else {
		Tcl_Return(interp, "Usage: irq [(set|clear|no|yes|<num>)]",
			   TCL_STATIC);
		return(TCL_ERROR);
	    }
	} else if (arg) {
#if !defined(_MSDOS)
	    uiFlags |= UI_IRQ;
#else
	    *irq = TRUE;
#endif
	} else {
#if !defined(_MSDOS)
	    uiFlags &= ~UI_IRQ;
#else
	    *irq = FALSE;
#endif
	}
    }
    return(TCL_OK);
}

/***********************************************************************
 *				UiPromptCmd
 ***********************************************************************
 * SYNOPSIS:	    Prints the value of the prompt variable (defined in
 *	    	    case something bad happens...)
 * CALLED BY:	    Tcl (top-level-read)
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    Output is flushed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/11/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(prompt,UiPrompt,TCL_EXACT,NULL,swat_prog.input,
"Usage:\n\
    prompt\n\
\n\
Examples:\n\
    \"prompt\"	    Print a command prompt based on the value in the\n\
		    $prompt variable.\n\
\n\
Synopsis:\n\
    Prints a command prompt. Usually overridden by a Tcl procedure of the\n\
    same name.\n\
\n\
Notes:\n\
    * The format string is stored in the global \"prompt\" variable. It may\n\
      have a single %s, which will be replaced by the name of the current\n\
      patient.\n\
\n\
See also:\n\
    top-level-read\n\
")
{
    const char    *prompt = Tcl_GetVar(interp, "prompt", FALSE);

    if ((prompt != NULL) && *prompt != '\0') {
	MessageFlush(prompt, curPatient->name);
    } else {
	MessageFlush("=> ");
    }
    return(TCL_OK);
}

/***********************************************************************
 *				UiFlushCmd
 ***********************************************************************
 * SYNOPSIS:	    Flush output
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    Buffered output is flushed.
 *
 * STRATEGY:	    Just calls fflush(stdout)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 3/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(flush-output,UiFlush,TCL_EXACT,NULL,swat_prog.output,
"Usage:\n\
    flush-output\n\
\n\
Examples:\n\
    \"flush-output\"	Forces pending output to be displayed\n\
\n\
Synopsis:\n\
    Flushes any pending output (e.g. waiting for a newline) to the screen.\n\
\n\
Notes:\n\
\n\
See also:\n\
    echo.\n\
")
{
    MessageFlush("");
    return(TCL_OK);
}

/***********************************************************************
 *				UiCompletionCmd
 ***********************************************************************
 * SYNOPSIS:	    Return the completion of a list of names.
 * CALLED BY:	    Tcl
 * RETURN:	    The common prefix of all names
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	    Split the list of names into a vector.
 *	    Taking the first name as a reference, walk through each
 *	    	character in it, making sure it matches the same character
 *	    	in all the other names.
 *	    If a mismatch is found, return the characters of the first
 *	    	name up to the mismatch (this catches nulls).
 *	    If the end of the first name is reached, return the first name.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/14/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(completion,UiCompletion,TCL_EXACT,NULL,swat_prog,
"Usage:\n\
    completion <list-of-names>\n\
\n\
Examples:\n\
    \"completion $matches\"	Returns the common prefix for the elements\n\
				of the list stored in $matches\n\
\n\
Synopsis:\n\
    Figures the common prefix from a set of strings. Used for the various\n\
    forms of completion supported by top-level-read.\n\
\n\
Notes:\n\
\n\
See also:\n\
    top-level-read.\n\
")
{
    int	    num;    	/* Number of names */
    char    **names;	/* Vector of names */
    int	    i;	    	/* Current index into each name */
    int	    cur;    	/* Current name being checked */
    char    *match; 	/* Name against which to match */

    if (argc != 2) {
	Tcl_Error(interp, "Usage: completion <list-o'names>");
    }
    if (Tcl_SplitList(interp, argv[1], &num, &names) != TCL_OK) {
	return(TCL_ERROR);
    }
    if (num == 0) {
	Tcl_Return(interp, NULL, TCL_STATIC);
	return(TCL_OK);
    } else if (num == 1) {
	Tcl_Return(interp, names[0], TCL_VOLATILE);
	free((char *)names);
	return(TCL_OK);
    } else {
	match = names[0];
	for (i = 0; match[i]; i++) {
	    for (cur = 1; cur < num; cur++) {
		if (names[cur][i] != match[i]) {
		    if (i < TCL_RESULT_SIZE) {
			Tcl_RetPrintf(interp, "%.*s", i, match);
		    } else {
			/*
			 * Result too big to fit in resultSpace, so allocate
			 * another buffer for it.
			 */
			char	*cp = (char *)malloc(i+1);

			strncpy(cp, match, i);
			cp[i+1] = '\0';
			Tcl_Return(interp, cp, TCL_DYNAMIC);
		    }
		    free((char *)names);
		    return(TCL_OK);
		}
	    }
	}
	Tcl_Return(interp, match, TCL_VOLATILE);
	free((char *)names);
	return(TCL_OK);
    }
}
    

/***********************************************************************
 *				UiColumnsCmd
 ***********************************************************************
 * SYNOPSIS:	    Return the number of columns available
 * CALLED BY:	    Tcl
 * RETURN:	    The number of columns available
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Call Ui_NumColumns and return the result...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/14/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(columns,UiColumns,TCL_EXACT,NULL,swat_prog.output,
"Usage:\n\
    columns\n\
\n\
Examples:\n\
    \"columns\"	    	Return the number of columns on the screen.\n\
\n\
Synopsis:\n\
    Retrieves the width of the screen, if known, to allow various commands\n\
    (most notably \"print\") to size their output accordingly.\n\
\n\
Notes:\n\
\n\
See also:\n\
    none.\n\
")
{
    Tcl_RetPrintf(interp, "%d", Ui_NumColumns());
    return(TCL_OK);
}
#if !defined(_MSDOS)

/***********************************************************************
 *				UiInterrupt
 ***********************************************************************
 * SYNOPSIS:	    Field an interrupt signal
 * CALLED BY:	    UNIX
 * RETURN:	    Nothing
 * SIDE EFFECTS:    UI_IRQ is set.
 *
 * STRATEGY:	    None
 *	    
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
void
UiInterrupt(void)
{
# if defined(_WIN32)   
    /* 
     * need to remind _WIN32 to catch interrupt each time 
     */
    typedef void (*signal_func)(int) ;
    signal(SIGINT, (signal_func)UiInterrupt);
    SetEvent(cntlcEvent);
# endif
    uiFlags |= UI_IRQ;
}

#endif


/***********************************************************************
 *				Ui_Interrupt
 ***********************************************************************
 * SYNOPSIS:	    See if we've been interrupted
 * CALLED BY:	    GLOBAL
 * RETURN:	    TRUE if so
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Check UI_IRQ and return TRUE if set.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
Boolean
Ui_Interrupt(void)
{
#if !defined(_MSDOS)
    return(uiFlags & UI_IRQ);
#else
    return (*irq);
#endif
}

/***********************************************************************
 *				Ui_CheckInterrupt
 ***********************************************************************
 * SYNOPSIS:	    See if an interrupt is pending and take it if
 *	    	    UI_IRQ_OK is set in uiFlags.
 * CALLED BY:	    TclDebugCallProc, TclDebugReturnProc
 * RETURN:	    Nothing
 * SIDE EFFECTS:    If the interrupt is taken, the system will return
 *	    	    to top level.
 *
 * STRATEGY:	    None, really.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/16/89		Initial Revision
 *
 ***********************************************************************/
Boolean
Ui_CheckInterrupt(void)
{
    return (Ui_Interrupt()  && !noInterruptCount);
}

/***********************************************************************
 *				Ui_TakeInterrupt
 ***********************************************************************
 * SYNOPSIS:	    See if an interrupt is pending and take it if
 *	    	    UI_IRQ_OK is set in uiFlags.
 * CALLED BY:	    TclDebugCallProc, TclDebugReturnProc
 * RETURN:	    Nothing
 * SIDE EFFECTS:    If the interrupt is taken, the system will return
 *	    	    to top level.
 *
 * STRATEGY:	    None, really.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/16/89		Initial Revision
 *
 ***********************************************************************/
void
Ui_TakeInterrupt(void)
{
    if (Ui_Interrupt()  && !noInterruptCount) {
	Ui_ClearInterrupt();
	noInterruptCount++; /* Ignore interrupts while we're cleaning up */
	Ui_TopLevel();
    }
}

/***********************************************************************
 *				Ui_AllowInterrupts
 ***********************************************************************
 * SYNOPSIS:	    Set the UI_IRQ_OK flag to the passed one.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    UI_IRQ_OK is altered
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/16/89		Initial Revision
 *
 ***********************************************************************/
void
Ui_AllowInterrupts(Boolean  flag)
{
    if (flag) {
	noInterruptCount--;
    } else {
	noInterruptCount++;
    }
}

/***********************************************************************
 *				Ui_ClearInterrupt
 ***********************************************************************
 * SYNOPSIS:	    Clear the interrupt-pending flag
 * CALLED BY:	    GLOBAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    UI_IRQ is cleared
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
void
Ui_ClearInterrupt(void)
{
#if !defined(_MSDOS)
    uiFlags &= ~UI_IRQ;
#else
    *irq = FALSE;
#endif
#if defined(_WIN32)
    ResetEvent(cntlcEvent);
#endif
}

/***********************************************************************
 *				UiReturnToTopLevelCmd
 ***********************************************************************
 * SYNOPSIS:	    Function used by top-level to actually return to
 *	    	    the top-level loop
 * CALLED BY:	    top-level
 * RETURN:	    No
 * SIDE EFFECTS:    All in-progress calls are aborted.
 *
 * STRATEGY:	    Just calls Ui_TopLevel -- it will do the rest.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 3/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(return-to-top-level,UiReturnToTopLevel,1,NULL,swat_prog,
"Usage:\n\
    return-to-top-level\n\
\n\
Examples:\n\
    \"return-to-top-level\"	Returns to the top-level interpreter\n\
\n\
Synopsis:\n\
    Forces execution to return to the top-level interpreter loop, unwinding\n\
    intermediate calls (protected commands still have their protected\n\
    clauses executed, but nothing else is).\n\
\n\
Notes:\n\
\n\
See also:\n\
    top-level, protect.\n\
")
{
    Ui_TopLevel();
    /*XXX*/
    return(TCL_OK);
}

/***********************************************************************
 *				UiTopLevelCmd
 ***********************************************************************
 * SYNOPSIS:	    Actual top-level loop.
 * CALLED BY:	    Ui_TopLevel via Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 4/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(top-level,UiTopLevel,1,NULL,swat_prog.input,
"Usage:\n\
    top-level\n\
\n\
Examples:\n\
    \"top-level\"	    Begin reading and interpreting Tcl commands in a nested\n\
		    interpreter.\n\
\n\
Synopsis:\n\
    This is the top-most read-eval-print loop of the Swat Tcl interpreter.\n\
\n\
Notes:\n\
    * This command will only return if the user issues the \"break\" command.\n\
      Else it loops infinitely, reading and executing and printing the results\n\
      of Tcl commands.\n\
\n\
See also:\n\
    top-level-read.\n\
")
{
    int	    result;
    char    *cmd;
    static char	top_level_read[] = "top-level-read";
    
    current_level++;
    while (1) {
	/*
	 * Let the debugger know we made it back to command level
	 */
	Tcl_Debug(TD_TOPLEVEL);

	/*
	 * Fetch line to execute
	 */
	if (Tcl_Eval(interp, top_level_read, 0, (const char **)NULL)!=TCL_OK) {
	    MessageFlush("Error: %s\n", interp->result);
	    continue;
	}
    
	/*
	 * Evalute the line we got
	 */
	if (interp->dynamic) {
	    interp->dynamic = 0;
	    cmd = (char *)interp->result;
	} else {
	    cmd = (char *)malloc_tagged(strlen(interp->result)+1, TAG_ETC);
	    strcpy(cmd, interp->result);
	}
    
	result = Tcl_Eval(interp, cmd, 0, (const char **)NULL);
	free(cmd);
    
	/*
	 * If interrupted, note that
	 */
#if !defined(_MSDOS)
	if (uiFlags & UI_IRQ) {
	    Message("Interrupt\n");
	    uiFlags &= ~UI_IRQ;
	}
#else
	if (*irq) {
	    Message("Interrupt\n");
	    *irq = FALSE;
	}
#endif
    
	noInterruptCount = 0;

	/*
	 * Check the result code. If it's an error, print the message.
	 * Else, if it returned ok and actually gave us something, print
	 * out what it said.
	 */
	if (result == TCL_BREAK) {
	   break;
	} else if (result != TCL_OK) {
	    Message("Error: %s\n", interp->result);
	} else if (interp->result && *interp->result) {
	    Message("%s\n", interp->result);
	}
    }
    current_level--;
    return(TCL_OK);
}

/***********************************************************************
 *				UiCurrentLevelCmd
 ***********************************************************************
 * SYNOPSIS:	    Return the current nesting of interpreter loops.
 * CALLED BY:	    Tcl
 * RETURN:	    The nesting (1 means at top-level loop).
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 4/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(current-level,UiCurrentLevel,1,NULL,swat_prog.input,
"Usage:\n\
    current-level\n\
\n\
Examples:\n\
    \"var l [current-level]\"	Store the current interpreter nesting level\n\
				in $l.\n\
\n\
Synopsis:\n\
    Returns the number of invocations of \"top-level\" (i.e. the main\n\
    command input loop) currently active.\n\
\n\
Notes:\n\
    * This is currently used only to modify the command prompt to indicate\n\
      the current nesting level.\n\
\n\
    * The top-most command loop is level 1.\n\
\n\
See also:\n\
    prompt, top-level.\n\
")
{
    Tcl_RetPrintf(interp, "%d", current_level);
    return(TCL_OK);
}

/***********************************************************************
 *				Ui_TopLevel
 ***********************************************************************
 * SYNOPSIS:	    Go back to the top level of command processing
 * CALLED BY:	    main,...
 * RETURN:	    No
 * SIDE EFFECTS:    Interpreter state is popped
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
volatile void
Ui_TopLevel(void)
{
    static jmp_buf  toplevel;	/* Thing to pop stack state too */
    /*
     * Simple top-level in case we can't source swat.tcl correctly...
     * Checks for existence of top-level-read first before defining it,
     * as it may have been brought in by the File module.
     */
    static char	    deftop_level[] =
	"if {[string c [info commands top-level-read] {}]==0} {\n\
             defsubr top-level-read {} {\n\
                 irq clear\n\
                 prompt\n\
                 return [read-line 1]\n\
             }\n\
         }";
#if defined(__GNUC__)
    extern volatile void longjmp(jmp_buf, int);
#endif


    if (uiFlags & UI_INITIALIZED) {
	/*
	 * If we've been here before, reinitialize the debugger state and
	 * the interpreter state, then jump back to the top-level loop,
	 * below.
	 */
	Rpc_Abort();
	(void)Event_Dispatch(EVENT_RESET, NullOpaque);
	Tcl_TopLevel(interp);
	longjmp(toplevel, 1);
    } else {
	uiFlags |= UI_INITIALIZED;
	/* 
	 *we need to call setjmp before we source swat at it might do
	 * a continue, so if the user exits GEOS we come back into
	 * UI_TopLevel and longjmp gets called, so we better havee called
	 * setjmp
	 */
	if (!setjmp(toplevel)) 
	{
	    /*
	     * Create a default top-level function in case things choke.
	     */
	    (void)Tcl_Eval(interp, deftop_level, 0, 0);
	    MessageFlush("Sourcing swat.tcl...");

	    /*
	     * Use the "load" command, now defined in file-err.tcl, to load
	     * swat.tcl, searching the load path in a nice manner.
	     */
	    if (Tcl_Eval(interp, "load swat.tcl", 0, 0) != TCL_OK) {
		static char quit_cmd[] = "quit leave";
	    
		Warning("\nError in \"load swat.tcl\": %s", interp->result);
		(void)Tcl_Eval(interp, quit_cmd, 0, 0);
	    }

	    /*
	     * Initialize the debugger now that all the heavy-duty
	     * commands have been processed
	     */
	    TclDebug_Init();

	    /* 
	     * if we did a continueStartup, then no need to printout this
	     * stuff
	     */

	    if (!strcmp(Tcl_GetVar(interp, "continueStartup", TRUE), ""))
	    {
		MessageFlush("done\n");
		/*
		 * Deliver initial FULLSTOP event to get the ball rolling.
		 * Momentarily turn off interrupts, else cntl-c hoses da prompt
		 */
		Ui_AllowInterrupts(0);
		(void)Event_Dispatch(EVENT_FULLSTOP, (Opaque)"GEOS Attached");
		Ui_AllowInterrupts(1);
	    }
	}
	noInterruptCount = 0;

	while(1) {
	    /*
	     * top-level must be in an array so it's not placed in
	     * read-only memory, else when we debug something and have to play
	     * with the command, we die hard.
	     */
	    static char top_level_cmd[] = "top-level";

	    current_level = 0;
	    (void)Tcl_Eval(interp, top_level_cmd, 0, 0);
	}
    }
}

/***********************************************************************
 *				Ui_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize the user-interface
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Ui procedure vectors are loaded
 *
 * STRATEGY:	    Figure what sort of terminal we're running on.
 *	    	    If it's "dumb" or "emacs", call Shell_Init, else
 *	    	    call Curses_Init.
 *	    	    Install our commands.
 *	    	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
void
Ui_Init(int 	*argcPtr,
	char	**argv)
{
#if defined(unix)
    extern char	*getenv(char *);
    char    	*term;
#elif defined(_WIN32)
    char	term[256];
    Boolean	returnCode;
#endif

#if defined(unix) || defined(_WIN32)
    typedef void (*signal_func)(int) ;
    signal(SIGINT, (signal_func)UiInterrupt);
# if defined(unix)
    signal(SIGQUIT, Ui_TopLevel);
# endif
#endif

    uiFlags = 0;

    Cmd_Create(&UiIrqCmdRec);
    Cmd_Create(&UiPromptCmdRec);
    Cmd_Create(&UiFlushCmdRec);
    Cmd_Create(&UiCompletionCmdRec);
    Cmd_Create(&UiColumnsCmdRec);
    Cmd_Create(&UiReturnToTopLevelCmdRec);
    Cmd_Create(&UiTopLevelCmdRec);
    Cmd_Create(&UiCurrentLevelCmdRec);

#if defined(_WIN32)
    cntlcEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
#endif

#if !defined(_MSDOS)
# if !defined(_WIN32)
    term = getenv("TERM");
# else
    returnCode = Registry_FindStringValue(Tcl_GetVar(interp, "file-reg-swat", 
						     TRUE),
					  "TERM", term, sizeof(term));
    
    if (returnCode == FALSE) {
	term[0] = '\0';
    }
# endif
    if ((term == NULL) 
	|| (term[0] == '\0') 
	|| (strcmp(term, "dumb") == 0) 
	|| (strcmp(term, "emacs") == 0))
    {
	Shell_Init();
    } else {
	Curses_Init();
    }
#else
    Curses_Init();
#endif /* !_MSDOS */
    interp->output = Message;
}
