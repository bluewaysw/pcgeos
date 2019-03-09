/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  SWAT -- TCL procedure debugging
 * FILE:	  tclDebug.c
 *
 * AUTHOR:  	  Adam de Boor: Sep 27, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Tcl_Debug   	    Enter the debugger for some reason.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/27/88	  ardeb	    Initial version
 *	1/6/89	  ardeb	    Revised to use frames maintained by tcl, as well
 *			    as command flags (TCL_DEBUG flag defined for
 *			    this purpose).
 *
 * DESCRIPTION:
 *	The functions in this file implement a simple debugger for TCL
 *	commands in SWAT.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: tclDebug.c,v 4.13 97/04/18 16:52:54 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "cmd.h"
#include "event.h"
#include "tclDebug.h"
#include "ui.h"

#define Frame TclFrame
#include <tclInt.h>		/* Need internals of the frame, etc. */
#undef Frame

#include <compat/stdlib.h>
#include <ctype.h>
    
/*
 * Frame-specific flags
 */
#define TD_STOP	  	0x00000100  /* Stop on return from this frame */
#define TD_DEBUG    	0x00000200  /* Frame because of which debugger was
				     * invoked */

static Boolean	stopOnNextCall=FALSE;	/* Enter debugger on next call */
static Boolean	doStopOnNextCall=FALSE;	/* Debugger wants stopOnNextCall
					 * set true when it returns */
static Boolean	inDebugger=FALSE;	/* Set if in the debugger, so
					 * shouldn't look at TCL_DEBUG flags */

/*
 * The means by which we get access to all tcl calls
 */
static Tcl_Trace  tdTrace;
    
/*
 * The current temporary breakpoint, if any.
 */
typedef struct {
    const char 	    *name;
    Tcl_CmdProc	    *cmdProc;
    ClientData	    cData;
    Tcl_DelProc	    *delProc;
    int	    	    flags;
} TclTempBrk;

static Lst  	tempBrks = NILLST;


/***********************************************************************
 *				Tcl_Debug
 ***********************************************************************
 * SYNOPSIS:	  Main debugging routine. Invokes the debugger
 * CALLED BY:	  TclDebugCallProc, TclDebugReturnProc, etc.
 * RETURN:	  Nothing.
 * SIDE EFFECTS:  Possibly.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/27/88		Initial Revision
 *
 ***********************************************************************/
void
Tcl_Debug(TclDebugCode	why)	    /* Why we're entering the debugger */
{
    const char 	*debugger;
    const char 	*whyName;
    char 	*cmd;
    const char 	*argv[3];
    Tcl_Frame	*top;

    /*
     * Clear any temporary breakpoints set.
     */
    if (Lst_Open(tempBrks) == SUCCESS) {
	while (!Lst_IsAtEnd(tempBrks)) {
	    LstNode    ln;
	    TclTempBrk  *tb;

	    ln = Lst_Next(tempBrks);
	    tb = (TclTempBrk *)Lst_Datum(ln);
	    Tcl_OverrideCommand(interp, tb->name,
				tb->cmdProc,
				tb->flags,
				tb->cData,
				tb->delProc,
				0, 0, 0, 0);
	    free((malloc_t)tb);
	    Lst_Remove(tempBrks, ln);
	}
	Lst_Close(tempBrks);
    }
    
    /*
     * Locate the debugger
     */
    debugger = Tcl_GetVar(interp, "debugger", TRUE);
    if (debugger == NULL) {
	/*
	 * No debugger defined -- return now
	 */
	return;
    }

    /*
     * Figure out what to tell the debugger.
     */
    switch(why) {
	case TD_ENTER: 	    whyName = "enter"; break;
	case TD_EXIT: 	    whyName = "exit"; break;
	case TD_ERROR: 	    whyName = "error"; break;
	case TD_QUIT: 	    whyName = "quit"; break;
	case TD_RESET: 	    whyName = "reset"; break;
	case TD_TOPLEVEL:   whyName = "toplevel"; break;
	default:	    whyName = "other"; break;
    }
    
    /*
     * Merge the debugger's name, the reason for the stoppage and the
     * current result into a three-part command to be invoked in just a moment
     */
    argv[0] = debugger;
    argv[1] = whyName;
    argv[2] = interp->result;
    cmd = Tcl_Merge(3, (char **)argv);

    /*
     * Set the debug flag for the current frame so we know what's the first
     * frame before we entered the debugger
     */
    top = Tcl_CurrentFrame(interp);
    top->flags |= TD_DEBUG;

    /*
     * Invoke the debugger. It'll return when we're to continue. The
     * debugger's return value is the return value for the frame...
     * Make sure the call to the debugger isn't stopped by stopOnNextCall,
     * but if the thing's set, we want it to be set when we return, so
     * we slap the old value into doStopOnNextCall, which will cause
     * stopOnNextCall to be set when we're done...
     */
    doStopOnNextCall=stopOnNextCall;
    stopOnNextCall = FALSE;
    inDebugger = TRUE;
    
    (void)Tcl_Eval(interp, cmd, 0, 0);

    inDebugger = FALSE;

    top->flags &= ~TD_DEBUG;
    
    if (doStopOnNextCall) {
	doStopOnNextCall = FALSE;
	stopOnNextCall = TRUE;
    }

    free((malloc_t)cmd);
}


/***********************************************************************
 *				TclDebugReset
 ***********************************************************************
 * SYNOPSIS:	    Tell the debugger a reset is in progress
 * CALLED BY:	    EVENT_RESET
 * RETURN:	    EVENT_HANDLED
 * SIDE EFFECTS:    ..
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/19/89		Initial Revision
 *
 ***********************************************************************/
static int
TclDebugReset(Event event, Opaque callData, Opaque clientData)
{
    Tcl_Debug(TD_RESET);
    return(EVENT_HANDLED);
}

/***********************************************************************
 *				TclDebugCallProc
 ***********************************************************************
 * SYNOPSIS:	  Function called before each Tcl command call
 * CALLED BY:	  Tcl_Eval
 * RETURN:	  Nothing
 * SIDE EFFECTS:  Another frame will be added to the stack.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/27/88		Initial Revision
 *
 ***********************************************************************/
/*ARGSUSED*/
static void
TclDebugCallProc(ClientData cd,		    /* NOT USED */
		 Tcl_Interp *interp,	    /* Interpreter being traced */
		 Tcl_Frame  *top)  	    /* Current frame */
{
    top->flags &= TCL_FRAME_FLAGS;

    if (!inDebugger && ((top->cmdFlags & TCL_DEBUG) || stopOnNextCall)) {
	stopOnNextCall = FALSE;	/* Request is satisfied, so reset */
	Tcl_Debug(TD_ENTER);
    }	

    Ui_TakeInterrupt();
}


/***********************************************************************
 *				TclDebugReturnProc
 ***********************************************************************
 * SYNOPSIS:	  Handle the return of a Tcl command
 * CALLED BY:	  Tcl_Eval
 * RETURN:	  Nothing
 * SIDE EFFECTS:  A frame is removed from the stack. If no commands
 *	    	  remain to be debugged, the trace is removed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/27/88		Initial Revision
 *
 ***********************************************************************/
/*ARGSUSED*/
static void
TclDebugReturnProc(ClientData	cd,		/* NOT USED */
		   Tcl_Interp	*interp,	/* Interpreter being traced */
		   Tcl_Frame	*top,	    	/* Current frame */
		   int		result)		/* Result code from call */
{
    if (top->flags & TD_STOP) {
	Tcl_Debug(TD_EXIT);
    } else if (result == TCL_ERROR) {
	const char    *debugOnError = Tcl_GetVar(interp, "debugOnError", TRUE);

	if (!inDebugger && atoi(debugOnError)) {
	    /*
	     * Enter the debugger as long as no-one's catching errors
	     * above this frame. We detect the catching by running up the
	     * stack looking for a frame whose command proc is Tcl_CatchCmd
	     * (too many cases when looking at the command string). If we
	     * make it to the top of the call stack w/o finding a frame with
	     * this function in it, we know no one's interested.
	     */
	    Tcl_Frame	*frame;

	    for (frame = top->next; frame; frame = frame->next) {
		if (frame->cmdProc == Tcl_CatchCmd) {
		    break;
		}
	    }
	    if (frame == NULL) {
		Tcl_Debug(TD_ERROR);
	    }
	}
    }
    Ui_TakeInterrupt();
}

/***********************************************************************
 *				DebugCmd
 ***********************************************************************
 * SYNOPSIS:	  Set a breakpoint at a tcl command
 * CALLED BY:	  user
 * RETURN:	  TCL_OK or TCL_ERROR
 * SIDE EFFECTS:  The function for the command is overridden.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/27/88		Initial Revision
 *
 ***********************************************************************/
DEFCMD(debug,Debug,0,NULL,swat_prog.debug,
"Usage:\n\
    debug\n\
    debug <proc-name>+\n\
\n\
Examples:\n\
    \"debug\"	    Enter the Tcl debugger immediately\n\
    \"debug fooproc\" Enter the Tcl debugger when the interpreter is about\n\
		    to execute the command \"fooproc\".\n\
\n\
Synopsis:\n\
    Sets a breakpoint at the start of any Tcl command. Also serves as a\n\
    breakpoint in the middle of a Tcl procedure, if executed with no argument.\n\
\n\
Notes:\n\
    * The breakpoint for <proc-name> can be removed using the \"undebug\" command.\n\
\n\
    * <proc-name> need not be a Tcl procedure. Setting a breakpoint on a\n\
      built-in command is not for the faint-of-heart, however, as there are\n\
      some commands used by the Tcl debugger itself. Setting a breakpoint\n\
      on such a command will cause instant death.\n\
\n\
See also:\n\
    undebug.\n\
")
{
    int	    	    i;	    /* Index into argv */
    int	    	    flags;
    Tcl_CmdProc	    *cmdProc;
    ClientData	    cData;
    Tcl_DelProc	    *deleteProc;
    const char	    *realName;

    if (argc == 1) {
	Tcl_Debug(TD_OTHER);
	return(TCL_OK);
    }

    for (i = 1; i < argc; i++) {
	/*
	 * See if the command exists (and fetch the current state)
	 */
	if (!Tcl_FetchCommand(interp, argv[i], &realName,
			      &cmdProc, &flags, &cData,
			      &deleteProc))
	{
	    Tcl_RetPrintf(interp, "%s: not defined", argv[i]);
	    return(TCL_ERROR);
	}

	if (flags & TCL_DEBUG) {
	    /*
	     * If the TCL_DEBUG flag is set, command is already
	     * being debugged -- bitch.
	     */
	    Message("%s: already being debugged\n", realName);
	} else {
	    /*
	     * Else set the debug flag.
	     */
	    flags |= TCL_DEBUG;
	    Tcl_OverrideCommand(interp, realName,
				cmdProc, flags, cData, deleteProc,
				0, 0, 0, 0);
	}
    }
    
    return(TCL_OK);
}
    

/***********************************************************************
 *				UndebugCmd
 ***********************************************************************
 * SYNOPSIS:	  Clear a breakpoint at a tcl command
 * CALLED BY:	  user
 * RETURN:	  TCL_OK or TCL_ERROR
 * SIDE EFFECTS:  The old data for the command are put back.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/27/88		Initial Revision
 *
 ***********************************************************************/
DEFCMD(undebug,Undebug,0,NULL,swat_prog.debug,
"Usage:\n\
    undebug <proc-name>+\n\
\n\
Examples:\n\
    \"undebug fooproc\"	Cease halting execution each time \"fooproc\" is\n\
			executing.\n\
\n\
Synopsis:\n\
    Removes a breakpoint set by a previous \"debug\" command.\n\
\n\
Notes:\n\
\n\
See also:\n\
    debug.\n\
")
{
    int	    	  	i;

    for (i = 1; i < argc; i++) {
        Tcl_CmdProc     *cmdProc ;
	int 	    	flags;
	ClientData	clientData;
        Tcl_DelProc     *deleteProc ;
	const char  	*realName;

	/*
	 * First see if the command is defined (and get its current state)
	 */
	if (!Tcl_FetchCommand(interp, argv[i], &realName,
			      &cmdProc, &flags, &clientData,
			      &deleteProc))
	{
	    /*
	     * Choke.
	     */
	    Tcl_RetPrintf(interp, "%s: not defined", argv[i]);
	    return(TCL_ERROR);
	}

	if (flags & TCL_DEBUG) {
	    flags &= ~TCL_DEBUG;
	    Tcl_OverrideCommand(interp, realName, cmdProc, flags,
				clientData, deleteProc, 0, 0, 0, 0);
	} else {
	    Message("%s: not being debugged\n", argv[i]);
	}
    }
    return(TCL_OK);
}


/***********************************************************************
 *				TclDebugCmd
 ***********************************************************************
 * SYNOPSIS:	    Internal command for the debugger to use
 * CALLED BY:	    debugger function
 * RETURN:	    Various and sundry
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 4/89		Initial Revision
 *
 ***********************************************************************/
#define TD_TOP	    (ClientData)0
#define TD_NEXT_CALL (ClientData)1
#define TD_TBRK	    (ClientData)2
/* things after this take <tcl-frame> as first arg */
#define TD_NEXT	    (ClientData)10
#define TD_ARGS	    (ClientData)11
#define TD_GETF	    (ClientData)12
#define TD_SETF	    (ClientData)13
#define TD_PREV	    (ClientData)14
#define TD_EVAL	    (ClientData)15
#define TD_COMPLETE (ClientData)16
static const CmdSubRec	tclDebugCmds[] = {
    {"top",  	TD_TOP,	    0, 0,   ""},
    {"next", 	TD_NEXT,    1, 1,   "<tcl-frame>"},
    {"prev", 	TD_PREV,    1, 1,   "<tcl-frame>"},
    {"args", 	TD_ARGS,    1, 1,   "<tcl-frame>"},
    {"getf", 	TD_GETF,    1, 1,   "<tcl-frame>"},
    {"setf", 	TD_SETF,    2, 2,   "<tcl-frame> <flags>"},
    {"eval", 	TD_EVAL,    2, 2,   "<tcl-frame> <expr>"},
    {"complete",TD_COMPLETE,1, 1,   "<tcl-frame>"},
    {"next-call",TD_NEXT_CALL,0,0,   ""},
    {"tbrk", 	TD_TBRK,    1, TCL_CMD_NOCHECK,   "<proc>+"},
    {NULL,   	(ClientData)NULL,	    0, 0,   NULL}
};
DEFCMD(tcl-debug,TclDebug,TCL_EXACT,tclDebugCmds,swat_prog.debug,
"Usage:\n\
    tcl-debug top \n\
    tcl-debug next <tcl-frame>\n\
    tcl-debug prev <tcl-frame>\n\
    tcl-debug args <tcl-frame>\n\
    tcl-debug getf <tcl-frame>\n\
    tcl-debug setf <tcl-frame> <flags>\n\
    tcl-debug eval <tcl-frame> <expr>\n\
    tcl-debug complete <tcl-frame>\n\
    tcl-debug next-call \n\
    tcl-debug tbrk <proc>+\n\
\n\
Examples:\n\
    \"var f [tcl-debug top]\" 	Sets $f to be the frame at which the debugger\n\
				was entered.\n\
    \"var f [tcl-debug next $f]\"	Retrieves the next frame down (away from the\n\
				top) the Tcl call stack from $f.\n\
			   \n\
\n\
Synopsis:\n\
    This provides access to the internals of the Tcl interpreter for the Tcl\n\
    debugger (which is written in Tcl, not C). It will not function except\n\
    after the debugger has been entered.\n\
\n\
Notes:\n\
    * Note on subcommand\n\
\n\
    * Another note on a subcommand or usage\n\
\n\
See also:\n\
    debug.\n\
")
{
    Tcl_Frame	*frame;
    
    /*
     * Extract frame for the commands that take one. Note that we trust the
     * debugger, after a fashion, partly because we can't assign a tag to these
     * frames, since they're internal to the interpreter.
     */
    if (clientData >= TD_NEXT) {
	frame = (Tcl_Frame *)atoi(argv[2]);
	if (frame == NULL) {
	    Tcl_Error(interp, "tcl-debug: invalid frame");
	}
    } else {
	frame = NULL;		/* To keep GCC from whining */
    }

    switch((int)clientData) {
	case TD_TOP:
	    /*
	     * Find the first frame at which the debugger was entered
	     */
	    for (frame = Tcl_CurrentFrame(interp);
		 frame && (frame->flags & TD_DEBUG) == 0;
		 frame = frame->next)
	    {
		;
	    }
	    Tcl_RetPrintf(interp, "%d", frame);
	    break;
	case TD_NEXT:
	    if (frame->next) {
		Tcl_RetPrintf(interp, "%d", frame->next);
	    } else {
		Tcl_Return(interp, "nil", TCL_STATIC);
	    }
	    break;
	case TD_PREV:
	{
	    Tcl_Frame	*prev, *cur;

	    for (prev = NULL, cur = Tcl_CurrentFrame(interp);
		 cur->level > frame->level;
		 prev = cur, cur = cur->next)
	    {
		;
	    }
	    if (prev) {
		Tcl_RetPrintf(interp, "%d", prev);
	    } else {
		Tcl_Return(interp, "nil", TCL_STATIC);
	    }
	    break;
	}
	case TD_ARGS:
	    /*
	     * Fetch the arguments for the frame as a list.
	     */
	    Tcl_Return(interp,
		       Tcl_Merge(frame->argc, (char **)frame->argv),
		       TCL_DYNAMIC);
	    break;
	case TD_GETF:
	    /*
	     * Fetch the flags for a frame
	     */
	    Tcl_RetPrintf(interp, "%d", frame->flags);
	    break;
	case TD_SETF:
	{
	    /*
	     * Set the flags for a frame
	     */
	    int	flags = cvtnum(argv[3], NULL);

	    frame->flags = flags;
	    break;
	}
	case TD_COMPLETE:
	    /*
	     * See if a frame is complete or if we're still gathering
	     * arguments.
	     */
	    Tcl_Return(interp, frame->cmdProc ? "1" : "0", TCL_STATIC);
	    break;
	case TD_EVAL:
	{
	    Interp	*iPtr;
	    int	    	code;
	    TclFrame	*tf;
	    VarFrame	*vf;
	    
	    /*
	     * Switch interpreter into context of frame
	     */
	    iPtr = (Interp *)interp;

	    /*
	     * Switch our own variable context -- don't want to change
	     * frames as that would cause a core leak should the user quit
	     * from a nested invocation of the debugger.
	     */
	    tf = iPtr->top;
	    vf = tf->localPtr;
	    tf->localPtr = ((TclFrame *)frame)->localPtr;

	    /*
	     * Evaluate the command now that the context's been set up.
	     */
	    code = Tcl_Eval(interp, argv[3], 0, 0);

	    /*
	     * Go back to our own context again.
	     */
	    tf->localPtr = vf;

	    return(code);
	}
	case TD_NEXT_CALL:
	    doStopOnNextCall = TRUE;
	    break;
        case TD_TBRK:
	{
	    TclTempBrk	*tb;	    /* Structure for bpt being set */
	    const char 	*realName;  /* Full name of command for which bpt
				     * is being set */
	    char    	*saveName;  /* Pointer to buffer into which realName is
				     * copied. */
	    Tcl_CmdProc	*cmdProc;   /* Procedure implementing the command for
				     * which bpt is being set */
	    int	    	flags;	    /* Flags for command */
	    Tcl_DelProc	*delProc;   /* Tcl_DelProc for command */
	    ClientData	cData;	    /* ClientData for command */
	    int	    	i;  	    /* Index into argv */

	    /*
	     * First make sure all the specified commands actually exist,
	     * so we don't have to worry about unsetting breakpoints should
	     * one of the commands not exist.
	     */
	    for (i = 2; i < argc; i++) {
		if (!Tcl_FetchCommand(interp, argv[i], &realName,
				      &cmdProc, &flags, &cData,
				      &delProc))
		{
		    Tcl_RetPrintf(interp, "%s: not a defined command",
				  argv[i]);
		    return(TCL_ERROR);
		}
	    }
	    
	    /*
	     * Now set the TCL_DEBUG flag for each command, remembering its
	     * parameters (easier to do this now than when clearing the
	     * bpt...) in our list so we can restore the flags to their
	     * original value.
	     */
	    for (i = 2; i < argc; i++) {
		(void)Tcl_FetchCommand(interp, argv[i], &realName,
				       &cmdProc, &flags, &cData,
				       &delProc);

		if (!(flags & TCL_DEBUG)) {
		    tb = (TclTempBrk *)malloc(sizeof(TclTempBrk) +
					      strlen(realName) + 1);
		    saveName = (char *)(tb+1);
		    strcpy(saveName, realName);
		    tb->name = saveName;
		    tb->cmdProc = cmdProc;
		    tb->cData = cData;
		    tb->flags = flags;
		    tb->delProc = delProc;
		    (void)Lst_AtEnd(tempBrks, (LstClientData)tb);

		    Tcl_OverrideCommand(interp, realName, cmdProc,
					flags | TCL_DEBUG,
					cData, delProc,
					0, 0, 0, 0);
		}
	    }
	    break;
	}
    }
    return(TCL_OK);
}
	    

/***********************************************************************
 *				TclDebug_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize this module
 * CALLED BY:	    Ui_TopLevel
 * RETURN:  	    Nothing
 * SIDE EFFECTS:    Commands and a trace are entered.
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/88	Initial Revision
 *
 ***********************************************************************/
void
TclDebug_Init(void)
{
    stopOnNextCall = FALSE; 
    tdTrace = Tcl_CreateTrace(interp, 0,
			      TclDebugCallProc, TclDebugReturnProc,
			      (ClientData)NULL);

    (void) Event_Handle(EVENT_RESET, 0, TclDebugReset, NullOpaque);
    tempBrks = Lst_Init(FALSE);
    
    Cmd_Create(&DebugCmdRec);
    Cmd_Create(&UndebugCmdRec);
    Cmd_Create(&TclDebugCmdRec);
}
