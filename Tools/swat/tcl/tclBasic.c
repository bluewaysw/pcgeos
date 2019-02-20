/* 
 * tclBasic.c --
 *
 *	Contains the basic facilities for TCL command interpretation,
 *	including interpreter creation and deletion, command creation
 *	and deletion, and command parsing and execution.
 *
 * Copyright 1987 Regents of the University of California
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appear in all copies.  The University of California
 * makes no representations about the suitability of this
 * software for any purpose.  It is provided "as is" without
 * express or implied warranty.
 */

#ifndef lint
static char *rcsid = "$Id: tclBasic.c,v 1.71 97/04/18 12:19:05 dbaumann Exp $ SPRITE (Berkeley)";
#endif not lint

#include <config.h>
#include <stdio.h>
#include <stddef.h>
#include <ctype.h>
#include <malloc.h>
#include <compat/string.h>
#include "tclInt.h"

/*
 * Built-in commands, and the procedures associated with them.
 *
 * NOTE: THE INDICES INTO THIS ARRAY ARE STORED IN BYTE-COMPILED CODE.
 * DO NOT CHANGE THE ORDER OF THESE THINGS IN ANY WAY, SHAPE, OR FORM.
 * Adding to the end of the array is ok, so long as you realize that
 * code compiled with the new array will be incompatible with earlier
 * interpreters.
 */

const Tcl_CommandRec *const builtInCmds[] = {
    &Tcl_BCCmdRec,
    &Tcl_BreakCmdRec,
    &Tcl_CaseCmdRec,
    &Tcl_CatchCmdRec,
    &Tcl_ConcatCmdRec,
    &Tcl_ContinueCmdRec,
    &Tcl_DefsubrCmdRec,
    &Tcl_ErrorCmdRec,
    &Tcl_EvalCmdRec,
    &Tcl_ExecCmdRec,
    &Tcl_ExprCmdRec,
    &Tcl_FileCmdRec,
    &Tcl_ForCmdRec,
    &Tcl_ForeachCmdRec,
    &Tcl_FormatCmdRec,
    &Tcl_GlobalCmdRec,
    &Tcl_IfCmdRec,
    &Tcl_IndexCmdRec,
    &Tcl_InfoCmdRec,
    &Tcl_LengthCmdRec,
    &Tcl_ListCmdRec,
    &Tcl_ProcCmdRec,
    &Tcl_ProtectCmdRec,
    &Tcl_RangeCmdRec,
    &Tcl_ReturnCmdRec,
    &Tcl_ScanCmdRec,
    &Tcl_SourceCmdRec,
    &Tcl_StringCmdRec,
    &Tcl_TimeCmdRec,
    &Tcl_UplevelCmdRec,
    &Tcl_VarCmdRec,
#if defined(_WIN32)
    &Tcl_ElispSendCmdRec
#endif
};

const unsigned numBuiltInCmds = sizeof(builtInCmds)/sizeof(builtInCmds[0]);


/*
 *----------------------------------------------------------------------
 *
 * Tcl_CreateInterp --
 *
 *	Create a new TCL command interpreter.
 *
 * Results:
 *	The return value is a token for the interpreter, which may be
 *	used in calls to procedures like Tcl_CreateCmd, Tcl_Eval, or
 *	Tcl_DeleteInterp.
 *
 * Side effects:
 *	The command interpreter is initialized with an empty variable
 *	table and the built-in commands.
 *
 *----------------------------------------------------------------------
 */

Tcl_Interp *
Tcl_CreateInterp(void)
{
    register Interp *iPtr;
    register const Tcl_CommandRec * const *cmdRecPtr;
    register int i;
#if defined(__HIGHC__) || defined(__BORLANDC__)
    extern int printf(const char *fmt, ...);
#else
    extern void printf(const char *fmt, ...);
#endif

    iPtr = (Interp *) calloc(1, sizeof(Interp));
    iPtr->result = iPtr->resultSpace;
    iPtr->output = printf;

    /*
     * Create the built-in commands.  Do it here, rather than calling
     * Tcl_CreateCommand, because it's faster (there's no need to check
     * for a pre-existing command by the same name).
     */

    for (cmdRecPtr = builtInCmds,
	 i = sizeof(builtInCmds)/sizeof(builtInCmds[0]);
	 i > 0;
	 cmdRecPtr++, i--)
    {
	Tcl_CreateCommandByRec((Tcl_Interp *)iPtr, *cmdRecPtr);
    }

    return (Tcl_Interp *) iPtr;
}



/*
 *----------------------------------------------------------------------
 *
 * Tcl_TopLevel --
 *
 *	Return an interpreter to its top-level state. This assumes the
 *	caller will unwind the various levels of C procedure calls...
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Any local variables are destroyed. numLevels is reset to 0.
 *	protect strings for frames are evaluated.
 *
 *----------------------------------------------------------------------
 */
void
Tcl_TopLevel(Tcl_Interp	*interp)
{
    register Interp	*iPtr;
    register Frame  	*frame, *nextFrame;
    void    	    	**fp;
    

    iPtr = (Interp *)interp;

    for (frame = iPtr->top; frame != NULL; frame = nextFrame) {
	nextFrame = (Frame *)frame->ext.next;

	/*
	 * Evaluate any protected command in its context.
	 */
	if (frame->protect) {
	    if (frame->psize) {
		(void)TclByteCodeEval(interp, frame->psize,
				      (unsigned char *)frame->protect);
	    } else {
		(void)Tcl_Eval(interp, frame->protect, 0, 0);
	    }
	}

	/*
	 * Free any separately-allocated arguments
	 */
	if (frame->sepArgs) {
	    for (fp = frame->sepArgs; *fp != (void *)NULL; fp++) {
		free(*fp);
	    }
	}
	if (frame->ext.flags & TCL_FRAME_FREE_SEPARGS) {
	    free((malloc_t)frame->sepArgs);
	}
	
	/*
	 * Free args and argv if requested by Tcl_Eval
	 */
	if (frame->ext.flags & TCL_FRAME_FREE_ARGS) {
	    free((malloc_t)frame->copyStart);
	}
	if (frame->ext.flags & TCL_FRAME_FREE_ARGV) {
	    free((malloc_t)frame->ext.argv);
	}
	
	/*
	 * If the frame is for a command procedure (and the scope has
	 * actually been set up), we need to free up its local variables.
	 */
	if ((frame->ext.cmdFlags & TCL_PROC) &&
	    (!frame->ext.next ||
	     frame->localPtr != ((Frame *)frame->ext.next)->localPtr))
	{
	    TclDeleteVars(frame->localPtr->vars);

	    frame->localPtr->vars = (Var *)NULL;
	}

	/*
	 * Switch to the next frame up.
	 */
	iPtr->top = nextFrame;
    }

    iPtr->numLevels = 0;
    /*
     * Clear any byte-code operands.
     */
    TclByteCodeResetStack(iPtr);
}
	     


/*
 *----------------------------------------------------------------------
 *
 * Tcl_CurrentFrame --
 *
 *	Return the top-most frame in the current call stack.
 *
 * Results:
 *	See above.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */
Tcl_Frame *
Tcl_CurrentFrame(Tcl_Interp *interp)
{
    Interp  *iPtr = (Interp *)interp;

    return ((Tcl_Frame *)iPtr->top);
}


/*
 *----------------------------------------------------------------------
 *
 * Tcl_DeleteInterp --
 *
 *	Delete an interpreter and free up all of the resources associated
 *	with it.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The interpreter is destroyed.  The caller should never again
 *	use the interp token.
 *
 *----------------------------------------------------------------------
 */

void
Tcl_DeleteInterp(Tcl_Interp *interp)	/* Token for command interpreter
					 * (returned by a previous call to
					 * Tcl_CreateInterp). */
{
    Interp *iPtr = (Interp *) interp;
    register Command *cmdPtr;
    int	    i;
    register Trace *tracePtr;

    /*
     * If the interpreter is in use, delay the deletion until later.
     */

    iPtr->flags |= DELETED;
    if (iPtr->numLevels != 0) {
	return;
    }
    for (i = 0; i < TCL_CMD_CHAINS; i++) {
	Command *nextCmd;
	
	for (cmdPtr = iPtr->commands[i]; cmdPtr != NULL; cmdPtr = nextCmd) {
	    if (cmdPtr->deleteProc != 0) { 
		(*cmdPtr->deleteProc)(cmdPtr->clientData);
	    }
	    nextCmd = cmdPtr->nextPtr;
	    free((char *) cmdPtr);
	}
	iPtr->commands[i] = NULL;
    }

    TclDeleteVars(iPtr->globalFrame.vars);
    for (tracePtr=iPtr->tracePtr; tracePtr!=NULL; tracePtr=tracePtr->nextPtr) {
	free((char *) tracePtr);
    }
    if (iPtr->operands.size) {
	free((malloc_t)iPtr->operands.stack);
    }
    if (iPtr->strings.size) {
	free((malloc_t)iPtr->strings.stack);
    }
    free((char *) iPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_CreateCommand --
 *
 *	Define a new command in a command table.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	If a command named cmdName already exists for interp, it is
 *	deleted.  In the future, when cmdName is seen as the name of
 *	a command by Tcl_Eval, proc will be called with the following
 *	syntax:
 *
 *	int
 *	proc(clientData, interp, argc, argv)
 *	    ClientData clientData;
 *	    Tcl_Interp *interp;
 *	    int argc;
 *	    char **argv;
 *	{
 *	}
 *
 *	The clientData and interp arguments are the same as the corresponding
 *	arguments passed to this procedure.  Argc and argv describe the
 *	arguments to the command, in the usual UNIX fashion (argv[argv] will
 *	be NULL).  Proc must return a code like TCL_OK or TCL_ERROR.  It
 *	can also set interp->result ("" is the default value if proc doesn't
 *	set it) and interp->dynamic (0 is the default).  See tcl.h for more
 *	information on these variables.
 *
 *	When the command is deleted from the table, deleteProc will be called
 *	in the following way:
 *
 *	void
 *	deleteProc(clientData)
 *	    ClientData clientData;
 *	{
 *	}
 *
 *	DeleteProc allows command implementors to perform their own cleanup
 *	when commands (or interpreters) are deleted.
 *
 *----------------------------------------------------------------------
 */

void
Tcl_CreateCommand(Tcl_Interp	*interp,	/* Token for command
						 * interpreter (returned by
						 * a previous call to
						 * Tcl_CreateInterp). */
		  const char	*cmdName,	/* Name of command. */
		  Tcl_CmdProc	*proc,	    	/* Command procedure to
						 * associate with cmdName. */
		  int	    	flags,	    	/* Flags for the command
						 * (TCL_EXACT, eg.) */
		  ClientData	clientData,	/* Arbitrary one-word value
						 * to pass to proc. */
		  Tcl_DelProc	*deleteProc)	/* If not NULL, gives a
						 * procedure to call when
						 * this command is deleted. */
{
    Interp *iPtr = (Interp *) interp;
    register Command *cmdPtr;
    int	nameLength = strlen(cmdName);

    Tcl_DeleteCommand(interp, cmdName);
    cmdPtr = (Command *) malloc(CMD_SIZE(nameLength));
    cmdPtr->proc = proc;
    cmdPtr->flags = flags;
    cmdPtr->clientData = clientData;
    cmdPtr->deleteProc = deleteProc;
    
    cmdPtr->nextPtr = iPtr->commands[TCL_CMD_GET_CHAIN(cmdName)];
    iPtr->commands[TCL_CMD_GET_CHAIN(cmdName)] = cmdPtr;
    bcopy(cmdName, cmdPtr->name, nameLength+1);
}


/***********************************************************************
 *				Tcl_CreateCommandByRec
 ***********************************************************************
 * SYNOPSIS:	    Define a new command using a command record.
 * CALLED BY:	    GLOBAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    See Tcl_CreateCommand.
 *
 * STRATEGY:
 *	    Delete the command if it already exists.
 *	    If the command record has a non-null 'data' pointer, use
 *	    	TclCmdCheckUsage as the handler instead of that stored
 *	    	in the record.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/23/91		Initial Revision
 *
 ***********************************************************************/
void
Tcl_CreateCommandByRec(Tcl_Interp   	    *interp,
		       const Tcl_CommandRec *cmdRec)
{
    Tcl_CmdProc	    *proc;
    ClientData	    data;

    if (cmdRec->data != 0) {
	proc = TclCmdCheckUsage;
	data = (ClientData)cmdRec;
    } else {
	proc = cmdRec->proc;
	data = (ClientData)NULL;
    }

    Tcl_CreateCommand(interp, cmdRec->name, proc, cmdRec->flags, data,
		      cmdRec->delProc);
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_OverrideCommand --
 *
 *	Override the values for a command in an interpreter, returning
 *	the old values so they may be replaced later. This function
 *	is intended to allow functions to catch procedure calls, e.g.
 *	for debugging.
 *
 * Results:
 *	If the command doesn't exist in the table then 0 is returned.
 *	Otherwise 1 is returned and cmdProcPtr, cmdClientDataPtr and
 *	deleteProcPtr are filled in.
 *
 * Side effects:
 *	The command will be brought to the front of the list by
 *	TclFindCmd if it is found, and its values will be changed.
 *
 *----------------------------------------------------------------------
 */
int
Tcl_OverrideCommand(Tcl_Interp	*interp,
		    const char	*cmdName,   	    /* Name of command to
						     * change */
		    Tcl_CmdProc	*cmdProc,	    /* Command procedure to
						     * associate with cmdName.*/
		    int	    	flags,	    	    /* New flags */
		    ClientData	clientData,	    /* Arbitrary one-word value
						     * to pass to proc. */
		    Tcl_DelProc	*deleteProc,        /* If not NULL, gives a
						     * procedure to call when
						     * this command is deleted*/
		    Tcl_CmdProc	**cmdProcPtr,	    /* Place to store old
						     * handler */
		    int	    	*flagsPtr,  	    /* Storage for old flags */
		    ClientData	*clientDataPtr,	    /* Storage for old CD */
		    Tcl_DelProc	**deleteProcPtr)    /* Storage for old delProc*/
{
    register Command 	*cmdPtr;

    cmdPtr = TclFindCmd((Interp *)interp, cmdName, 1);

    if (cmdPtr == (Command *)NULL) {
	return(0);
    } else {
	if (cmdProcPtr) *cmdProcPtr = cmdPtr->proc;
	if (flagsPtr) *flagsPtr = cmdPtr->flags;
	if (clientDataPtr) *clientDataPtr = cmdPtr->clientData;
	if (deleteProcPtr) *deleteProcPtr = cmdPtr->deleteProc;
	cmdPtr->proc = cmdProc;
	cmdPtr->flags = flags;
	cmdPtr->clientData = clientData;
	cmdPtr->deleteProc = deleteProc;
	return(1);
    }
}	

/*
 *----------------------------------------------------------------------
 *
 * Tcl_FetchCommand --
 *
 *	Return the cmdProc, clientData and deleteProc values for a
 *	function, if it exists.
 *
 * Results:
 *	If the command doesn't exist in the table then 0 is returned.
 *	Otherwise 1 is returned and cmdProcPtr, cmdClientDataPtr and
 *	deleteProcPtr are filled in.
 *
 * Side effects:
 *	The command will be brought to the front of the list by
 *	TclFindCmd if it is found.
 *
 *----------------------------------------------------------------------
 */
int
Tcl_FetchCommand(Tcl_Interp 	*interp,
		 const char    	*cmdName,
		 const char 	**realNamePtr,
		 Tcl_CmdProc 	**cmdProcPtr,
		 int	    	*flagsPtr,
		 ClientData 	*clientDataPtr,
		 Tcl_DelProc    **deleteProcPtr)
{
    register Command 	*cmdPtr;

    cmdPtr = TclFindCmd((Interp *)interp, cmdName, 0);

    if (cmdPtr == (Command *)NULL) {
	return(0);
    } else {
	*realNamePtr = cmdPtr->name;
	*cmdProcPtr = cmdPtr->proc;
	*flagsPtr = cmdPtr->flags;
	*clientDataPtr = cmdPtr->clientData;
	*deleteProcPtr = cmdPtr->deleteProc;
	return(1);
    }
}	

/*
 *----------------------------------------------------------------------
 *
 * Tcl_DeleteCommand --
 *
 *	Remove the given command from the given interpreter.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	CmdName will no longer be recognized as a valid command for
 *	interp.
 *
 *----------------------------------------------------------------------
 */

void
Tcl_DeleteCommand(Tcl_Interp	*interp,    /* Token for command interpreter
					     * (returned by a previous call to
					     * Tcl_CreateInterp). */
		  const char	*cmdName)   /* Name of command to remove. */
{
    Interp *iPtr = (Interp *) interp;
    Command *cmdPtr;

    cmdPtr = TclFindCmd(iPtr, cmdName, 1);
    if (cmdPtr != NULL) {
	if (cmdPtr->deleteProc != 0) {
	    (*cmdPtr->deleteProc)(cmdPtr->clientData);
	}
	/*
	 * Unlink -- was put at start of chain, so easy to do.
	 */
	iPtr->commands[TCL_CMD_GET_CHAIN(cmdName)] = cmdPtr->nextPtr;
	free((char *) cmdPtr);
    }
}

/*
 *-----------------------------------------------------------------
 *
 * Tcl_Eval --
 *
 *	Parse and execute a command in the Tcl language.
 *
 * Results:
 *	The return value is one of the return codes defined in
 *	tcl.h (such as TCL_OK), and interp->result contains a string
 *	value to supplement the return code.  The value of interp->result
 *	will persist only until the next call to Tcl_Eval:  copy it
 *	or lose it!
 *
 * Side effects:
 *	Almost certainly;  depends on the command.
 *
 *-----------------------------------------------------------------
 */
int
Tcl_Eval(Tcl_Interp *interp,	/* Token for command interpreter (returned by a
				 * previous call to Tcl_CreateInterp). */
	 const char *cmd,	/* Pointer to TCL command to interpret. */
	 char	    termChar,	/* Return when this character is found in the
				 * command stream.  This is either 0, ']'.   If
				 * termChar is 0, then individual commands are
				 * terminated by newlines, although this
				 * procedure doesn't return until it sees the
				 * end of the string. */
	 const char **termPtr)	/* If non-NULL, fill in the address it points
				 * to with the address of the char. that
				 * terminated cmd.  This character will be
				 * either termChar or the null at the end of
				 * cmd. */
{
    /*
     * While processing the command, make a local copy of
     * the command characters.  This is needed in order to
     * terminate each argument with a null character, replace
     * backslashed-characters, etc.  The copy starts out in
     * a static string (for speed) but gets expanded into
     * dynamically-allocated strings if necessary.  The constant
     * BUFFER indicates how much space there must be in the copy
     * in order to pass through the main loop below (e.g., must
     * have space to copy both a backslash and its following
     * characters).
     */

#   define NUM_CHARS 200
#   define BUFFER 5
    char    	    copyStorage[NUM_CHARS];
    char    	    *copy=copyStorage;	    /* Pointer to current copy. */
    unsigned   	    copySize = NUM_CHARS;   /* Size of current copy. */
    register char   *dst;		    /* Points to next place to copy
					     * a character. */
    char    	    *limit;		    /* When dst gets here, must make
					     * the copy larger. */

    /*
     * This procedure generates an (argv, argc) array for the command,
     * It starts out with stack-allocated space but uses dynamically-
     * allocated storage to increase it if needed.
     */

#   define NUM_ARGS 32
    char    	    *argStorage[NUM_ARGS];
    char    	    **argv = argStorage;
    int     	    argc;
    int     	    argSize = NUM_ARGS;

    /*
     * Things to track any separately-allocated args that we usurp.
     */
    void    	    *sepArgStorage[NUM_ARGS];
    int	    	    sepArgc=0;
    int	       	    sepArgSize = NUM_ARGS;

    int     	    openBraces=0;   	/* Count of how many nested open braces
					 * there are at the current point in
					 * the current argument */

    register const char   *src;		/* Points to current character
					 * in cmd. */
    const char 	    *argStart;		/* Location in cmd of first character
					 * in current argument;  it's used to
					 * detect that nothing has been read
					 * from the current argument. */
    int     	    result=TCL_OK;	/* Return value. */
    int     	    i;
    register Interp *iPtr = (Interp *) interp;
    char 	    *errRes = NULL;
    Command 	    *cmdPtr;
    const char 	    *tmp;
    const char 	    *syntaxMsg = NULL;
    register Trace  *tracePtr;
    Frame   	    frame;  	    	/* Frame for this command */

    /*
     * Set up the result so that if there's no command at all in
     * the string then this procedure will return TCL_OK.
     */
    if (iPtr->dynamic) {
	free((char *) iPtr->result);
	iPtr->dynamic = 0;
    }
    
    iPtr->result = iPtr->resultSpace;
    iPtr->resultSpace[0] = 0;
    

    iPtr->numLevels++;
    iPtr->cmdCount++;
    src = cmd;
    result = TCL_OK;

    /*
     * Initialize Frame for this level
     */
    frame.ext.level = iPtr->numLevels;
    frame.ext.next = (Tcl_Frame *)iPtr->top;
    frame.ext.flags = 0;
    frame.sepArgs = sepArgStorage;
    if (iPtr->top) {
	frame.localPtr = iPtr->top->localPtr;
    } else {
	frame.localPtr = &iPtr->globalFrame;
    }
    cmdPtr = (Command *)NULL;
    iPtr->top = &frame;
    
    /*
     * There can be many sub-commands (bracketed or separated by
     * newlines) in one command string.  This outer loop iterates over
     * the inner commands.
     */

    while ((*src != termChar) && (result == TCL_OK)) {

	/*
	 * Skim off leading white space, skip comments, and handle brackets
	 * at the beginning of the command by recursing.
	 */
    
	while (isspace(*src)) {
	    src += 1;
	}
	if (*src == '#') {
	    for (src++; *src != 0; src++) {
		if (*src == '\n') {
		    src++;
		    break;
		}
	    }
	    continue;
	}
	/*
	 * If the first character of the command is a [, the command within
	 * is executed and its output discarded (unless it's the only command
	 * in the string). This allows multi-line commands by placing it
	 * in brackets -- if this weren't done, the result would be executed,
	 * which would be bad.
	 *
	 * Switches back to calling frame before recursing so there's not a
	 * bogus frame in the middle (we don't have anything to assign to our
	 * frame yet).
	 *
	 * XXX: If Tcl_TopLevel is called while in the nested Tcl_Eval,
	 * anything we've allocated dynamically will be left dangling.
	 */
	if (*src == '[') {
	    iPtr->top = (Frame *)frame.ext.next;
	    result = Tcl_Eval(interp, src+1, ']', &tmp);
	    iPtr->top = &frame;
	    src = tmp+1;
	    continue;
	}

	/*
	 * Set up the first argument (the command name).  Note that
	 * the arg pointer gets set up BEFORE the first real character
	 * of the argument has been found.
	 */
    
	dst = copy;
	argc = 0;
	frame.protect = (char *)NULL;
	frame.ext.cmdProc = 0;
	frame.ext.cmdFlags = 0;
	frame.copyStart = copy;
	frame.copyEnd = limit = copy + copySize - BUFFER;
	frame.ext.command = src;

	argv[0] = dst;
	argStart = src;

	/*
	 * Skim off the command name and arguments by looping over
	 * characters and processing each one according to its type.
	 */
    
	while (1) {
	    switch (*src) {
    
		/*
		 * All braces are treated as normal characters
		 * unless the first character of the argument is an
		 * open brace.  In that case, braces nest and
		 * the argument terminates when all braces are matched.
		 * Internal braces are also copied like normal chars.
		 */
    
		case '{': {
		    if ((openBraces == 0) && (src == argStart)) {
			/*
			 * 9/29/92: I changed this, at one point to
			 * find the length of the quoted argument and
			 * enlarge the block just once, but it ended up
			 * just processing the characters twice, rather than
			 * once, and only rarely (I think the number was
			 * 1/70th of the time) was it ever worth it (i.e. was
			 * the argument so big the dest had to be enlarged).
			 * I doubt it has much effect either way. The
			 * code is in revision 1.60, though, if you ever want
			 * it back again -- ardeb.
			 */
			openBraces = 1;
			break;
		    } else {
			*dst++ = '{';
			/*
			 * Only balance braces if inside an argument in braces.
			 */
			if (openBraces) {
			    openBraces++;
			}
		    }
		    break;
		}

		case '}': {
		    if (openBraces == 1) {
			const char *p;

			openBraces = 0;

			checkbrace:

			if (isspace(src[1]) || (src[1] == termChar) ||
			    (src[1] == 0))
			{
			    break;
			}
			for (p = src+1;
			     (*p != 0) && (!isspace(*p)) &&
			     (*p != termChar) && (p < src+20);
			     p++)
			{
			    /* null body */
			}
			Tcl_RetPrintf(interp,
				      "argument in braces followed by \"%.*s\" instead of space",
				      p-(src+1), src+1);
			result = TCL_ERROR;
			goto done;
		    } else {
			*dst++ = '}';
			if (openBraces != 0) {
			    openBraces--;
			}
		    }
		    break;
		}
    
		case '[': {
    
		    /*
		     * Open bracket: if not in middle of braces, then execute
		     * following command and substitute result into argument.
		     */

		    if (openBraces != 0) {
			*dst++ = '[';
		    } else {
			int length;
    
			/*
			 * Set up partial frame. cmdProc is NULL to indicate
			 * we're still working on it...
			 */
			frame.ext.argc = argc;
			frame.ext.argv = (const char **)argv;
			frame.sepArgs[sepArgc] = (void *)NULL;
			
			result = Tcl_Eval(interp, src+1, ']', &tmp);
			src = tmp;
			if (result != TCL_OK) {
			    goto done;
			}
    
			/*
			 * Copy the return value into the current argument.
			 * May have to enlarge the argument storage.  When
			 * enlarging, get more than enough to reduce the
			 * likelihood of having to enlarge again.  This code
			 * is used for $-processing also.
			 */
			copyResult:

			if ((iPtr->result!=(const char *)iPtr->resultSpace) &&
			    (dst == argv[argc]) &&
			    ((i = src[1]) == '\n' || i == '\r' ||
			     i == ' ' || i == '\t' || i == '\0' ||
			     i == termChar))
			{
			    /*
			     * If result is the only thing in this argument and
			     * it's not in resultSpace, don't bother copying
			     * the thing to our local storage, just use it
			     * directly.
			     */
			    argv[argc] = (char *)iPtr->result;
			    if (iPtr->dynamic) {
				/*
				 * If arg is dynamic, record that it needs
				 * to be freed, storing its address in
				 * the sepArgs array, rather than relying
				 * on argv remaining the same during the
				 * call.
				 */
				frame.sepArgs[sepArgc++] = (char *)iPtr->result;
				if (sepArgc == sepArgSize) {
				    if (frame.sepArgs == sepArgStorage) {
					frame.sepArgs =
					    (void **)malloc((sepArgc*2)*
							    sizeof(void *));
					bcopy(sepArgStorage,
					      frame.sepArgs,
					      sepArgc*sizeof(void *));
				    } else {
					frame.sepArgs =
					    (void **)realloc((malloc_t)frame.sepArgs,
							     (sepArgc*2)*
							     sizeof(void *));
				    }
				    frame.ext.flags |= TCL_FRAME_FREE_SEPARGS;
				}
				iPtr->dynamic = 0;
			    }
			} else {
			    length = strlen(iPtr->result);
			    if ((limit - dst) < length) {
				char *newCopy;
				ptrdiff_t delta;
				char **av;
				
				copySize = length + NUM_CHARS + (dst - copy);
				newCopy = (char *) malloc((unsigned) copySize);
				bcopy(copy, newCopy, (dst-copy));
				delta = newCopy - copy;
				dst += delta;
				for (av = &argv[argc]; av >= argv; av--) {
				    if (*av >= copy && *av <= limit) {
					*av += delta;
				    }
				}
				if (copy != copyStorage) {
				    free((char *) copy);
				}
				frame.copyStart = copy = newCopy;
				frame.copyEnd = limit =
				    newCopy + copySize - BUFFER;
				frame.ext.flags |= TCL_FRAME_FREE_ARGS;
			    }

			    bcopy(iPtr->result, dst, length);
			    dst += length;
			}
		    }
		    break;
		}

		case '$': {
		    if (openBraces != 0) {
			*dst++ = '$';
		    } else {

			/*
			 * Parse off a variable name and copy its value.
			 */
    	    	    	if (iPtr->dynamic) {
			    free((malloc_t)iPtr->result);
			    iPtr->dynamic = 0;
			}
			iPtr->result = Tcl_ParseVar(interp, src, &tmp);
			src = tmp-1;
			goto copyResult;
		    }
		    break;
		}

		case ']': {
		    if ((openBraces == 0) && (termChar == ']')) {
			goto cmdComplete;
		    }
		    *dst++ = ']';
		    break;
		}
    
		case '\n': {

		    /*
		     * A newline can be either a command terminator
		     * or a space character.  If it's a space character,
		     * just fall through to the space code below.
		     */
    
		    if ((openBraces == 0) && (termChar == 0)) {
			goto cmdComplete;
		    }
		}
		    /*FALLTHRU*/
		case '\r':
		case ' ':
		case '\t': {
		    if (openBraces > 0) {
    
			/*
			 * Quoted space.  Copy it into the argument.
			 */
    
			*dst++ = *src;
		    } else {

			/*
			 * Argument separator.  Find the start of the next
			 * argument;  if none, then exit the loop.  Otherwise,
			 * null-terminate the current argument and set up for
			 * the next one.  Expand the argv array if it's about
			 * to overflow (watch out!  leave space both for next
			 * arg and for NULL pointer that gets added to the
			 * end of argv when the command is complete).
			 */
    
			*dst++ = 0;

			argc++;
			if (argc >= argSize-1) {
			    argSize *= 2;
			    if (argv == argStorage) {
				char **newArgs;
				
				newArgs = (char **)
				    malloc((unsigned) argSize*sizeof(char *));
				bcopy(argv, newArgs, argc * sizeof(char *));
				argv = newArgs;
				frame.ext.flags |= TCL_FRAME_FREE_ARGV;
			    } else {
				argv =
				    (char **)realloc((malloc_t)argv,
						     (unsigned)argSize*
						     sizeof(char *));
			    }
			}
			
			argv[argc] = dst;

			while (((i = src[1]) == ' ') || (i == '\t') ||
			       ((i == '\n') && (termChar != 0)) ||
			       (i == '\r'))
			{
			    src++;
			}
			argStart = src+1;

			/*
			 * If this is the first arg, look up the associated
			 * command so we can deal with the TCL_NOEVAL flag.
			 * We don't handle a non-existent command at this
			 * level, though, as we need to get to the end
			 * of the command string.
			 */
			if (argc == 1) {
			    cmdPtr = TclFindCmd(iPtr, (const char *)argv[0],0);
			    if (cmdPtr == NULL) {
				errRes = (char*)malloc(strlen(iPtr->result)+1);
				strcpy(errRes, iPtr->result);
			    } else if (cmdPtr->flags & TCL_NOEVAL) {
				int openBrackets=0; /* Count of nested open
						     * square brackets. */
				int len;

				for (src++; *src != '\0'; src++) {
				    if (*src == '{') {
					openBraces++;
				    } else if (openBraces && *src == '}') {
					openBraces--;
				    } else if (!openBraces) {
					if (*src == '[') {
					    openBrackets++;
					} else if (*src == ']') {
					    if ((openBrackets-- == 0) &&
						(termChar == ']'))
					    {
						openBrackets = 0;
						break;
					    }
					} else if (!openBrackets &&
						   termChar == 0 &&
						   *src == '\n')
					{
					    break;
					}
				    }
				}
				if (openBraces) {
				    syntaxMsg = "unmatched brace";
				    goto syntaxError;
				} else if (openBrackets) {
				    syntaxMsg = "unmatched bracket";
				    goto syntaxError;
				} else if (termChar && (*src != termChar)) {
				    if (termChar == ']') {
					syntaxMsg = "unmatched bracket";
				    } 
				    goto syntaxError;
				}
				
				len = src-argStart;

				if ((limit - dst) < len) {
				    /*
				     * Not enough room in dst for whole thing --
				     * enlarge copy to fit.
				     */
				    char    	*newCopy;
				    ptrdiff_t   delta;
				    char    	**av;
				    
				    copySize = len + NUM_CHARS + (dst - copy);
				    
				    newCopy = (char *) malloc(copySize);
				    bcopy(copy, newCopy, (dst-copy));
				    
				    delta = newCopy - copy;
				    dst += delta;
				    for (av = &argv[argc]; av >= argv; av--) {
					if (*av >= copy && *av <= limit) {
					    *av += delta;
					}
				    }
				    
				    if (copy != copyStorage) {
					free((char *) copy);
				    }
				    
				    frame.copyStart = copy = newCopy;
				    frame.copyEnd = limit =
					newCopy + copySize - BUFFER;
				    frame.ext.flags |= TCL_FRAME_FREE_ARGS;
				}
				
				/*
				 * Copy the thing into the destination
				 */
				bcopy(argStart, dst, len);
				dst += len;
				
				/* This'll null-terminate the arg for us... */
				goto cmdComplete;
			    }

			}
		    }
		    break;
		}
    
		case '\\': {
		    int numRead;

		    /*
		     * If we're in an argument in braces then the
		     * backslash doesn't get collapsed.  However whether
		     * we're in braces or not the characters inside the
		     * backslash sequence must not receive any additional
		     * processing:  make src point to the last character
		     * of the sequence.
		     */

		    *dst = Tcl_Backslash(src, &numRead);
		    if (openBraces > 0) {
			while (numRead-- > 0) {
			    *dst++ = *src++;
			}
			src--;
		    } else {
			src += numRead-1;
			dst++;
		    }
		    break;
		}
    
		case 0: {
    
		    /*
		     * End of string.  Make sure that braces were
		     * properly matched.  Also, it's only legal to
		     * terminate a command by a null character if termChar
		     * is zero.
		     */

		    if (openBraces != 0) {
			syntaxMsg = "unmatched brace";
			goto syntaxError;
		    } else if (termChar != 0) {
			if (termChar == ']') {
			    syntaxMsg = "unmatched bracket";
			} else {
			    syntaxMsg = "termination character not found";
			}
			goto syntaxError;
		    }
		    goto cmdComplete;
		}
    
		default: {
		    *dst++ = *src;
		    break;
		}
	    }
	    src += 1;
    
	    /*
	     * Make sure that we're not running out of space in the
	     * string copy area.  If we are, allocate a larger area
	     * and copy the string.  Be sure to update all of the
	     * relevant pointers too.
	     */
    
	    if (dst >= limit) {
		char 	    *newCopy;
		ptrdiff_t   delta;
    
		copySize *= 2;
		newCopy = (char *) malloc((unsigned) copySize);
		bcopy(copy, newCopy, (dst-copy));
		delta = newCopy - copy;
		dst += delta;
		for (i = 0; i <= argc; i++) {
		    if (argv[i] >= copy && argv[i] <= limit)
		    {
			argv[i] += delta;
		    }
		}
		if (copy != copyStorage) {
		    free((char *) copy);
		}
		frame.copyStart = copy = newCopy;
		frame.copyEnd = limit = newCopy + copySize - BUFFER;

		frame.ext.flags |= TCL_FRAME_FREE_ARGS;
	    }
	}
    
	/*
	 * Terminate the last argument.  If the interpreter has been
	 * deleted then return;  if there's no command, then go on to
	 * the next iteration.
	 */

	cmdComplete:

	if (iPtr->flags & DELETED) {
	    goto done;
	}
	if (src != argStart) {
	    *dst = 0;
	    argc++;
	} else if (argc == 0) {
	    continue;
	}
	argv[argc] = NULL;
	frame.sepArgs[sepArgc] = (void *)NULL;

	/*
	 * Clear out the result area.  This has already been done once,
	 * but a result may have been regenerated by a bracketed command.
	 */

	if (iPtr->dynamic) {
	    free((char *) iPtr->result);
	    iPtr->dynamic = 0;
	}
	iPtr->result = iPtr->resultSpace;
	iPtr->resultSpace[0] = 0;

	/*
	 * If only the command for an argument, need to locate the cmdPtr here,
	 * else it's done when the first arg is terminated.
	 */
	if (argc == 1) {
	    cmdPtr = TclFindCmd(iPtr, (const char *)argv[0], 0);
	    if (cmdPtr == NULL) {
		errRes = (char *)malloc(strlen(iPtr->result)+1);
		strcpy(errRes, iPtr->result);
	    }
	}

	if (cmdPtr == NULL) {
	    result = TCL_ERROR;
	    iPtr->result = errRes;
	    iPtr->dynamic = 1;
	    goto done;
	}

	/*
	 * Now we're committed, set up the rest of the frame.
	 */
	frame.ext.cmdProc = cmdPtr->proc;
	frame.ext.cmdFlags = cmdPtr->flags;
	frame.ext.cmdData = cmdPtr->clientData;
	frame.ext.argc = argc;
	frame.ext.argv = (const char **)argv;
	
	/*
	 * Call trace procedures, if any, then invoke the command.
	 */

	for (tracePtr = iPtr->tracePtr; tracePtr != NULL;
	     tracePtr = tracePtr->nextPtr)
	{
	    if ((tracePtr->level < iPtr->numLevels) && tracePtr->level) {
		continue;
	    }
	    (*tracePtr->callProc)(tracePtr->clientData, interp,
				  (Tcl_Frame *)&frame);
	}

	/*
	 * Invoke the command
	 */
	result = (*cmdPtr->proc)(cmdPtr->clientData, interp, argc, argv);

	/*
	 * Call the returnProcs for the traces
	 */
	for (tracePtr = iPtr->tracePtr; tracePtr != NULL;
	     tracePtr = tracePtr->nextPtr)
	{
	    if ((tracePtr->level < iPtr->numLevels) && tracePtr->level) {
		continue;
	    }
	    (*tracePtr->returnProc)(tracePtr->clientData, interp,
				    (Tcl_Frame *)&frame, result);
	}

	for (i = sepArgc-1; i >= 0; i--) {
	    free(frame.sepArgs[i]);
	}
	sepArgc = 0;
    }

    done:
    if (termPtr != NULL) {
	*termPtr = src;
    }

    /*
     * Free up any extra resources that were allocated.
     */

    for (i = sepArgc-1; i >= 0; i--) {
	free(frame.sepArgs[i]);
    }

    if (frame.ext.flags & TCL_FRAME_FREE_SEPARGS) {
	free((char *)frame.sepArgs);
    }
    if (frame.ext.flags & TCL_FRAME_FREE_ARGS) {
	free((char *) copy);
    }
    if (frame.ext.flags & TCL_FRAME_FREE_ARGV) {
	free((char *) argv);
    }
    
    iPtr->numLevels--;
    if (iPtr->numLevels == 0) {
	if ((result != TCL_OK) && (result != TCL_ERROR)) {
	    if (result == TCL_BREAK) {
		Tcl_Return(interp, "invoked \"break\" outside of a loop",
			   TCL_STATIC);
	    } else if (result == TCL_CONTINUE) {
		 Tcl_Return(interp, "invoked \"continue\" outside of a loop",
			    TCL_STATIC);
	    } else if (result == TCL_RETURN) {
		Tcl_Return(interp, "invoked \"return\" outside of a procedure",
			   TCL_STATIC);
	    } else {
		Tcl_RetPrintf(interp, "command returned bad code: %d",
			      result);
	    }
	    result = TCL_ERROR;
	}
	if (iPtr->flags & DELETED) {
	    Tcl_DeleteInterp(interp);
	}
    }
    iPtr->top = (Frame *)frame.ext.next;

    return result;

    /*
     * Syntax error:  generate a two-line message to pinpoint the error.
     * The first line contains a swatch of the command (without any
     * embedded newlines) and the second line contains a caret.
     */

    syntaxError: {
	const char *first, *last;

	for (first = src; ((first != cmd) && (first[-1] != '\n')); first--) {
	    /* Null loop body. */
	}
	for (last = src; ((*last != 0) && (*last!= '\n')); last++) {
	    /* Null loop body. */
	}
	if ((src - first) > 60) {
	    first = src - 60;
	}
	if ((last - first) > 70) {
	    last = first + 70;
	}
	if (last == first) {
	    Tcl_RetPrintf(interp, "%s", syntaxMsg);
	} else {
	    /*
	     * We need to make sure the caret lines up with the place of
	     * error by using tab characters wherever the source string
	     * uses them, and spaces everywhere else.
	     */
	    char	*cp;
	    char	*cp2;

	    Tcl_Return(interp, NULL, TCL_STATIC);

	    strcpy(iPtr->resultSpace, syntaxMsg);
	    cp = iPtr->resultSpace + strlen(syntaxMsg);

	    *cp++ = '\n';
	    cp2 = cp + (last-first);
	    *cp2++ = '\n';

	    while (first != last) {
		if (first <= src) {
		    if (*first != '\t') {
			*cp2++ = ' ';
		    } else {
			*cp2++ = '\t';
		    }
		    if (first == src) {
			*cp2++ = '^';
			*cp2++ = '\0';
		    }
		}
		*cp++ = *first++;
	    }
	    if (first == src) {
		*cp2++ = '^';
		*cp2++ = '\0';
	    }
	}
	result = TCL_ERROR;
    }

    goto done;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_CreateTrace --
 *
 *	Arrange for a procedure to be called to trace command execution.
 *
 * Results:
 *	The return value is a token for the trace, which may be passed
 *	to Tcl_DeleteTrace to eliminate the trace.
 *
 * Side effects:
 *	From now on, proc will be called just before a command procedure
 *	is called to execute a Tcl command.  Calls to callProc will have the
 *	following form:
 *
 *	void
 *	callProc(clientData, interp, frame)
 *	    ClientData clientData;
 *	    Tcl_Interp *interp;
 *	    Tcl_Frame *frame;
 *	{
 *	}
 *
 *	while those to returnProc will be:
 *
 *	void
 *	returnProc(clientData, interp, frame, result)
 *	    ClientData clientData;
 *	    Tcl_Interp interp;
 *	    Tcl_Frame *frame;
 *	    int result;
 *
 *	The clientData and interp arguments to both procs will be the same
 *	as the corresponding arguments to this procedure. frame is a pointer
 *	to a Tcl_Frame structure describing the current state of things.
 *	For returnProc, result is the integer returned by the command. Neither
 *	proc returns a value.
 *
 *----------------------------------------------------------------------
 */

Tcl_Trace
Tcl_CreateTrace(Tcl_Interp  *interp,		/* Interpreter in which to
						 * create the trace. */
		int	    level,		/* Only call proc for commands
						 * at nesting level <= level (1
						 * => top level, 0 => all
						 * levels) */
		Tcl_TraceCallProc   *callProc,	/* Procedure to call before
						 * executing each command */
	    	Tcl_TraceRetProc    *returnProc,/* Procedure to call after
						 * executing each command */
		ClientData  clientData)		/* Arbitrary one-word value to
						 * pass to proc. */
{
    register Trace *tracePtr;
    register Interp *iPtr = (Interp *) interp;

    tracePtr = (Trace *) malloc(sizeof(Trace));
    tracePtr->level = level;
    tracePtr->callProc = callProc;
    tracePtr->returnProc = returnProc;
    tracePtr->clientData = clientData;
    tracePtr->nextPtr = iPtr->tracePtr;
    iPtr->tracePtr = tracePtr;

    return (Tcl_Trace) tracePtr;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_DeleteTrace --
 *
 *	Remove a trace.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	From now on there will be no more calls to the procedure given
 *	in trace.
 *
 *----------------------------------------------------------------------
 */

void
Tcl_DeleteTrace(Tcl_Interp  *interp,	/* Interpreter that contains trace. */
		Tcl_Trace   trace)	/* Token for trace (returned previously
					 * by Tcl_CreateTrace). */
{
    register Interp *iPtr = (Interp *) interp;
    register Trace *tracePtr = (Trace *) trace;
    register Trace *tracePtr2;

    if (iPtr->tracePtr == tracePtr) {
	iPtr->tracePtr = tracePtr->nextPtr;
	free((char *) tracePtr);
    } else {
	for (tracePtr2 = iPtr->tracePtr;
	     tracePtr2 != NULL;
	     tracePtr2 = tracePtr2->nextPtr)
	{
	    if (tracePtr2->nextPtr == tracePtr) {
		tracePtr2->nextPtr = tracePtr->nextPtr;
		free((char *) tracePtr);
		return;
	    }
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TclFindCmd --
 *
 *	Find a particular command in an interpreter.
 *
 * Results:
 *	If the command doesn't exist in the table then NULL is returned.
 *	Otherwise the return value is a pointer to the command.
 *
 * Side effects:
 *	If the command is found, it is relinked at the front of iPtr's
 *	command list so it will be found more quickly in the future.
 *
 *----------------------------------------------------------------------
 */

Command *
TclFindCmd(Interp   *iPtr,	/* Interpreter in which to search. */
	   const char *cmdName,	/* Desired command. */
	   int      exact)  	/* Non-zero if an exact match is required */
{
    register Command *prev;
    register Command *cur;
    register Command *match;
    register Command *matchPrev = NULL;
    Command **firstPtr;
    register int cmdLen;
    register char c;
    int	i;  
    int	err;


    c = *cmdName;
    cmdLen = strlen(cmdName);
    match = (Command *)NULL;
    err = 0;

    /*
     * (re-)initialize the result
     */
    if (iPtr->dynamic) {
	free((char *) iPtr->result);
	iPtr->dynamic = 0;
    }
    
    iPtr->result = iPtr->resultSpace;
    iPtr->resultSpace[0] = 0;

    firstPtr = &iPtr->commands[TCL_CMD_GET_CHAIN(cmdName)];
    
    for (i=0,prev = NULL, cur = *firstPtr; cur != NULL;
	 prev = cur, cur = cur->nextPtr)
    {
	/*
	 * Check the first character here before wasting time calling
	 * strcmp.
	 */

	if ((cur->name[0] == c) &&
	    (strncmp(cur->name, cmdName, cmdLen) == 0))
	{
	    if (cur->name[cmdLen] == '\0') {
		/*
		 * Prefer an exact match if we can get it.
		 */
		match = cur;
		matchPrev = prev;
		if (err) {
		    /*
		     * Make sure we don't return an error
		     */
		    iPtr->resultSpace[0] = '\0';
		    err = 0;
		}
		break;
	    } else if (!exact && !(cur->flags & TCL_EXACT)) {
		if (match == (Command *)NULL) {
		    match = cur;
		    matchPrev = prev;
		} else {
		    if (*iPtr->result == '\0') {
			sprintf(iPtr->resultSpace,
				"%.50s ambiguous. Matches: %s, %s",
				cmdName, match->name, cur->name);
			err = 1;
		    } else {
			/*
			 * since we only have a 200 byte buffer
			 * if there are more than five commands that
			 * match, then show the first 5 and then 
			 * put out some dots to indicate that there are
			 * in fact others
			 */
			if (i < 5)
			{
			    strcat(iPtr->resultSpace, ", ");
			    strcat(iPtr->resultSpace, cur->name);
			}
			else if (i == 5)
			{
			    strcat(iPtr->resultSpace, " ... ");
			}			    
			i++;
		    }
		}
	    }
	}
    }

    if (match == (Command *)NULL) {
	sprintf(iPtr->resultSpace,
		"invoked \"%.50s\", which isn't a valid command name",
		cmdName);
	return NULL;
    } else if (err) {
	return NULL;
    }

    /*
     * Shift the command to the front of the list.
     */
    if (matchPrev != NULL) {
	matchPrev->nextPtr = match->nextPtr;
	match->nextPtr = *firstPtr;
	*firstPtr = match;
    }
    return match;
}
