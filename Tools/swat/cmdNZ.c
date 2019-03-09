/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Command Implementations
 * FILE:	  cmdNZ.c
 *
 * AUTHOR:  	  Adam de Boor: Dec  4, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	null	    	    See if argument is empty or nil
 *	pid 	    	    Return swat's process ID
 *	require	    	    Make sure a command is loaded
 *	scope	    	    Set the current patient's scope (OBSCURE)
 *	sleep	    	    Wait for a bit
 *	sort	    	    Sort a list in some fashion
 *	stream	    	    Access a file
 *	unalias	    	    Remove a command alias
 *	unassemble  	    Disassemble an instruction
 *	wait	    	    Wait for the patient to stop
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	12/ 4/88  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	This file contains implementations for commands whose names
 *	begin with the letters N through Z.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: cmdNZ.c,v 4.18 97/04/18 14:58:47 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "buf.h"
#include "cmd.h"
#include "expr.h"
#include "private.h"
#include "rpc.h" 	/* For SleepCmd */
#include "sym.h"
#include "type.h"
#include "value.h"
#include "var.h"
#include "ui.h"
#include <compat/stdlib.h>
#include <compat/file.h>
#include <ctype.h>
#include <errno.h>
#include "cmdNZ.h"

#define size_t suns_size_t2
#include <sys/types.h>
#undef size_t

#if defined(unix)
# include <sys/socket.h>
# include <sys/un.h>
# include <sys/signal.h>
#else
# include <process.h>
#endif

/***********************************************************************
 *				NullCmd
 ***********************************************************************
 * SYNOPSIS:	    See if argument is nil (empty list or just "nil")
 * CALLED BY:	    Tcl
 * RETURN:	    1 if it's nil, 0 if it's not
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/88	Initial Revision
 *
 ***********************************************************************/

DEFCMD(null,Null,TCL_EXACT,NULL,swat_prog|swat_prog.list|swat_prog.lisp,
"Usage:\n\
    null <val>\n\
\n\
Examples:\n\
    \"null $sym\"		Sees if the symbol token stored in $sym is the empty\n\
			string or \"nil\".\n\
\n\
Synopsis:\n\
    Checks to see if a string is either empty or \"nil\", special values returned\n\
    by many commands when something isn't found or doesn't apply. Returns non-\n\
    zero if <val> is either of these special values.\n\
\n\
Notes:\n\
    * The notion of \"nil\" as a value comes from lisp.\n\
\n\
See also:\n\
    index, range\n\
")
{
    if (argc != 2) {
	Tcl_Error(interp, "Usage: null <list>");
    }
    Tcl_Return(interp,
	       ((*argv[1] == '\0') || (strcmp(argv[1], "nil") == 0)) ? "1":"0",
	       TCL_STATIC);
    return(TCL_OK);
}


/***********************************************************************
 *				PIDCmd
 ***********************************************************************
 * SYNOPSIS:	    Return Swat's Process ID
 * CALLED BY:	    Tcl
 * RETURN:	    The pid
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/14/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(pid,PID,TCL_EXACT,NULL,obscure,
"Usage:\n\
    pid\n\
\n\
Examples:\n\
    \"pid\"	    	Return Swat's process ID.\n\
\n\
Synopsis:\n\
    This is useful only for debugging Swat when one wants to attach to it\n\
    using another debugger.\n\
\n\
Notes:\n\
    * This does nothing on DOS systems, where process IDs don't really exist.\n\
\n\
See also:\n\
    abort, alloc, dbg, rpc-dbg\n\
")
{
    Tcl_RetPrintf(interp, "%d", getpid());
    return(TCL_OK);
}


/***********************************************************************
 *				RequireCmd
 ***********************************************************************
 * SYNOPSIS:	    Make sure a command is loaded
 * CALLED BY:	    TCL
 * RETURN:	    TCL_OK/TCL_ERROR (result of source/load)
 * SIDE EFFECTS:    Command(s) may be defined
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/27/89		Initial Revision
 *
 ***********************************************************************/
extern Tcl_CmdProc CatchAutoLoad;

DEFCMD(require,Require,TCL_EXACT,NULL,swat_prog|swat_prog.load,
"Usage:\n\
    require <name> [<file>]\n\
\n\
Examples:\n\
    \"require fmtval print\"	Makes sure the procedure \"fmtval\" is defined,\n\
				loading the file \"print.tcl\" if it is not.\n\
\n\
Synopsis:\n\
    This is used to ensure that a particular function, not normally invoked\n\
    by the user but present in some file in the system library, is actually\n\
    loaded.\n\
\n\
Notes:\n\
    * If no <file> is given, a file with the same name (possibly plus \".tcl\")\n\
      as the function is assumed.\n\
\n\
See also:\n\
    autoload\n\
")
{
    Tcl_CmdProc	*cmdProc;
    int	    	flags;
    ClientData	data;
    Tcl_DelProc	*delProc;
    const char	*realName;
    
    if (argc < 2) {
	Tcl_Error(interp, "Usage: require <name> [<file>]");
    }
    
    if (!Tcl_FetchCommand(interp, argv[1], &realName, &cmdProc, &flags,
			  &data, &delProc) ||
	(cmdProc == CatchAutoLoad) ||
	(strcmp(argv[1], realName) != 0))
    {
	char	*loadCmd;
	int 	result;

	loadCmd = (char *)malloc(strlen("load ") + strlen(argv[argc-1]) + 1);

	sprintf(loadCmd, "load %s", argv[argc-1]);

	result = Tcl_Eval(interp, loadCmd, 0, 0);
	free(loadCmd);
	return(result);
    } else {
	/*
	 * Command defined -- must be ok (will be loaded automatically if
	 * only autoloaded).
	 */
	return(TCL_OK);
    }
}

/*-
 *-----------------------------------------------------------------------
 * CmdSetScope --
 *	Alter the scope used for looking up symbols in CmdWhatIs.
 *
 * Results:
 *	TCL_OK if scope found, TCL_ERROR if not.
 *
 * Side Effects:
 *	patient->scope is altered for the new scope, if it is found.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
DEFCMD(scope,Scope,0,NULL,obscure,
"Usage:\n\
    scope [<scope-name>]\n\
\n\
Examples:\n\
    \"scope\"	    	    Returns the name of the current auxiliary\n\
			    scope.\n\
\n\
Synopsis:\n\
    This changes the auxiliary scope in which Swat looks first when trying\n\
    to resolve a symbol name in an address expression.\n\
\n\
Notes:\n\
    * This command isn't usually typed by users, but it is the reason you\n\
      can reference local labels after you've listed a function unrelated to\n\
      the current one.\n\
\n\
    * You most likely want to use the set-address Tcl procedure, rather than\n\
      this command.\n\
\n\
    * If <scope-name> is \"..\", the auxiliary scope will change to be the\n\
      lexical parent of the current scope.\n\
\n\
See also:\n\
    whatis, addr-parse\n\
")
{
    Sym	    	  sym;
    
    if (argc == 1) {
	if (Sym_IsNull(curPatient->scope)) {
	    Tcl_Return(interp, "nil", TCL_STATIC);
	}  else {
	    Tcl_Return(interp, Sym_FullName(curPatient->scope), TCL_DYNAMIC);
	}
    } else {
	sym = Sym_Lookup(argv[1], SYM_SCOPE, curPatient->global);
	if (Sym_IsNull(sym)) {
	    if (strcmp(argv[1], "..") == 0) {
		sym = Sym_Scope(curPatient->scope, TRUE);
		if (Sym_IsNull(sym)) {
		    Tcl_Error(interp, "Already at top level");
		} else {
		    Tcl_Return(interp, Sym_FullName(sym), TCL_DYNAMIC);
		    curPatient->scope = sym;
		}
	    } else {
		Tcl_RetPrintf(interp, "%s: no such scope is defined", argv[1]);
		return(TCL_ERROR);
	    }
	} else {
	    curPatient->scope = sym;
	    Tcl_Return(interp, argv[1], TCL_VOLATILE);
	}
    }
    return(TCL_OK);
}

/***********************************************************************
 *				SleepCmd
 ***********************************************************************
 * SYNOPSIS:	    Sleeps a given number of seconds
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/30/89		Initial Revision
 *
 ***********************************************************************/
static Boolean
SleepEvent(Rpc_Opaque data,
	   Rpc_Event event)
{
    *(Boolean *)data = TRUE;
    Rpc_EventDelete(event);
    return(TRUE);
}
DEFCMD(sleep,Sleep,TCL_EXACT,NULL,swat_prog,
"Usage:\n\
    sleep <seconds>\n\
\n\
Examples:\n\
    \"sleep 5\"	    	Pauses Swat for 5 seconds.\n\
\n\
Synopsis:\n\
    This pauses Tcl execution for the given number of seconds, or until the\n\
    user types Ctrl+C.\n\
\n\
Notes:\n\
    * Messages from the PC continue to be processed, so a FULLSTOP event will\n\
      be dispatched if the PC stops, but this command won't return until the\n\
      given length of time has elapsed.\n\
\n\
    * <seconds> is a real number, so \"1.5\" is a valid argument.\n\
\n\
    * Returns non-zero if it slept for the entire time, or 0 if the sleep\n\
      was interrupted by the user.\n\
\n\
See also:\n\
    time\n\
")
{
    extern double   atof();
    double  	    numSecs;
    struct timeval  interval;
    Rpc_Event	    event;
    Boolean 	    done;

    if (argc != 2) {
	Tcl_Error(interp, "Usage: sleep <seconds>");
    }
    /*
     * Convert the argument to a floating-point value
     */
    numSecs = atof(argv[1]);
    /*
     * Split that into seconds and microseconds
     */
    interval.tv_sec = numSecs;
    interval.tv_usec = 1000000 * (numSecs - interval.tv_sec);

    /*
     * Initialize loop variable
     */
    done = FALSE;
    /*
     * Set event to fire at end of desired time
     */
    event = Rpc_EventCreate(&interval, SleepEvent, &done);

    /*
     * Don't take interrupts during this time, just record them
     */
    Ui_AllowInterrupts(FALSE);
    /*
     * Loop until time expires or interrupt comes in, dealing with the
     * RPC system as usual.
     */
    while (!done && !Ui_Interrupt()) {
	Rpc_Wait();
    }
    /*
     * If event not taken, remove it, else it will be taken and scribble
     * on the stack...
     */
    if (!done) {
	Rpc_EventDelete(event);
    }
    /*
     * Clear any pending interrupts, then turn interrupts back on again
     */
    Ui_ClearInterrupt();
    Ui_AllowInterrupts(TRUE);

    /*
     * Return ok no matter what.
     */
    Tcl_Return(interp, done ? "1" : "0", TCL_STATIC);
    return(TCL_OK);
}
    

/***********************************************************************
 *				SortCmd
 ***********************************************************************
 * SYNOPSIS:	    Sort a list in one of a number of ways
 * CALLED BY:	    Tcl
 * RETURN:	    The sorted list
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Break the list into an argv
 *	    	    Figure out what routine to use
 *	    	    Call qsort on the array
 *	    	    Merge the array back into a list, which we return.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 2/88	Initial Revision
 *
 ***********************************************************************/

static int NumAsc(char **s1, char **s2) {return (cvtnum(*s1,0)-cvtnum(*s2,0));}
static int NumDesc(char **s1, char **s2){return (cvtnum(*s2,0)-cvtnum(*s1,0));}
static int AlAsc(char **s1, char **s2){return strcmp(*s1, *s2);}
static int AlDesc(char **s1, char **s2){return strcmp(*s2, *s1);}
DEFCMD(sort,Sort,TCL_EXACT,NULL,swat_prog.list,
"Usage:\n\
    sort [-r] [-n] [-u] <list>\n\
\n\
Examples:\n\
    \"sort -n $ids\"	Sorts the list in $ids into ascending numeric order.\n\
\n\
Synopsis:\n\
    This sorts a list into ascending or descending order, lexicographically\n\
    or numerically.\n\
\n\
Notes:\n\
    * If \"-r\" is given, the sort will be in descending order.\n\
\n\
    * If \"-u\" is given, duplicate elements will be elimiated.\n\
\n\
    * If \"-n\" is given, the elements are taken to be numbers (with the usual\n\
      radix specifiers possible) and are sorted accordingly.\n\
\n\
    * The sorted list is returned.\n\
\n\
See also:\n\
    map, foreach, mapconcat\n\
")
{
    Boolean desc = 0, numeric = 0, unique = 0;
    char    **listArgv;
    int	    listArgc;
    int	    i;
    char    *cp;

#if defined(_WIN32)  
    typedef int (*compareFunc)(const char **, const char **) ;
    static int  (*compare[4])(const void *, const void *) = {
	(compareFunc)AlAsc, (compareFunc)NumAsc, (compareFunc)AlDesc, (compareFunc)NumDesc
    };
#else
    static int  (*compare[4])(char **, char **) = {
	AlAsc, NumAsc, AlDesc, NumDesc
    };
#endif

    if (argc < 2) {
	Tcl_Error(interp, "Usage: sort [-r] [-n] <list>");
    }
    
    for (i = 1; i < argc-1; i++) {
	for (cp = argv[i]; *cp; cp++) {
	    if (*cp == 'r') {
		desc = 1;
	    } else if (*cp == 'n') {
		numeric = 1;
	    } else if (*cp == 'u') {
		unique = 1;
	    }
	}
    }
    if (Tcl_SplitList(interp, argv[argc-1], &listArgc, &listArgv)) {
	return(TCL_ERROR);
    }

    qsort(listArgv, listArgc, sizeof(char *), compare[numeric+2*desc]);

    if (unique) {
	if (numeric) {
	    for (i = 0; i < listArgc-1; i++) {
		if (cvtnum(listArgv[i], 0) == cvtnum(listArgv[i+1], 0)) {
		    /*
		     * Matches -- copy the next pointers down over this one
		     */
		    bcopy((char *)&listArgv[i+1], (char *)&listArgv[i],
			  (listArgc-(i+1))*sizeof(char *));
		    listArgc -= 1;
		}
	    }
	} else {
	    for (i = 0; i < listArgc-1; i++) {
		if (strcmp(listArgv[i], listArgv[i+1]) == 0) {
		    /*
		     * Strings match -- copy the next pointers down over this
		     * one.
		     */
		    bcopy((char *)&listArgv[i+1], (char *)&listArgv[i],
			  (listArgc-(i+1))*sizeof(char *));
		    listArgc -= 1;
		}
	    }
	}
    }
		    
	
    Tcl_Return(interp, Tcl_Merge(listArgc, listArgv), TCL_DYNAMIC);

    free((char *)listArgv);

    return(TCL_OK);
}


/***********************************************************************
 *				StreamWatchCmdHandler
 ***********************************************************************
 * SYNOPSIS:	    Handle the readiness of a stream by calling the
 *	    	    procedure bound to it.
 * CALLED BY:	    Rpc system
 * RETURN:	    nothing
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/21/91		Initial Revision
 *
 ***********************************************************************/
static void
StreamWatchCmdHandler(int   	    fd,    	/* Stream that's ready */
		      Rpc_Opaque    data,   	/* StreamWatchData * we stored*/
		      int   	    what)   	/* For what it's ready */
{
    char    	*cmdArgs[3];	    /* Arg vector for the command */
    char    	*conditions[3];	    /* Array of satisfied conditions */
    int	    	nconditions;	    /* Number of satisfied conditions */
    char    	*cmd;	    	    /* Merged cmdArgs yielding string to be
				     * evaluated by Tcl_Eval */
    char    	streamToken[16];    /* ASCII representation of the stream
				     * itself */
    Stream  	*stream;   	    /* The stream itself */

    /*
     * Figure what conditions have been satisfied.
     */
    nconditions = 0;
    if (what & RPC_READABLE) {
	conditions[nconditions++] = "read";
    }

    if (what & RPC_WRITABLE) {
	conditions[nconditions++] = "write";
    }

    if (what & RPC_EXCEPTABLE) {
	conditions[nconditions++] = "except";
    }

    /*
     * Form the command string
     */
    stream = (Stream *)data;
    
    sprintf(streamToken, "%d", (int)stream);
    
    cmdArgs[0] = stream->watchProc;
    cmdArgs[1] = streamToken;
    cmdArgs[2] = Tcl_Merge(nconditions, conditions);

    cmd = Tcl_Merge(3, cmdArgs);
    if (Tcl_Eval(interp, cmd, 0, (const char **)NULL) != TCL_OK) {
	if (interp->result) {
	    Warning("stream watch: error: %s\n", interp->result);
	}
    }

    free(cmdArgs[2]);
    free(cmd);
}
    

/***********************************************************************
 *				StreamReadChar
 ***********************************************************************
 * SYNOPSIS:	    Fetch a character from a stream.
 * CALLED BY:	    StreamCmd
 * RETURN:	
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/21/91		Initial Revision
 *
 ***********************************************************************/
static inline int
StreamReadChar(Stream *stream)
{
    if (stream->type == STREAM_SOCKET) {
	char    c;

	if (read(stream->sock, &c, 1) != 1) {
	    return (EOF);
	} else {
	    return(c);
	}
    } else {
	return (getc(stream->file));
    }
}
    

/***********************************************************************
 *				StreamCmd
 ***********************************************************************
 * SYNOPSIS:	    Provide access to streams
 * CALLED BY:	    Tcl
 * RETURN:	    Things
 * SIDE EFFECTS:    Maybe
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/ 7/89		Initial Revision
 *
 ***********************************************************************/
#define STREAM_OPEN 	(ClientData)0
#define STREAM_READ 	(ClientData)1
#define STREAM_PRINT	(ClientData)2
#define STREAM_WRITE	(ClientData)3
#define STREAM_SEEK 	(ClientData)4
#define STREAM_REWIND	(ClientData)5
#define STREAM_STATE	(ClientData)6
#define STREAM_EOF  	(ClientData)7
#define STREAM_CLOSE	(ClientData)8
#define STREAM_FLUSH	(ClientData)9
#define STREAM_WATCH 	(ClientData)10
#define STREAM_IGNORE	(ClientData)11
static const CmdSubRec streamCmds[] = {
    {"open", 	STREAM_OPEN,	2, 2, "<file> (r|w|a|r+|w+)"},
    {"read", 	STREAM_READ,	2, 2, "(line|list|char) <stream>"},
    {"print",	STREAM_PRINT,	2, 2, "<list> <stream>"},
    {"write",	STREAM_WRITE,	2, 2, "<string> <stream>"},
    {"rewind",	STREAM_REWIND,	1, 1, "<stream>"},
    {"seek", 	STREAM_SEEK,	2, 2, "(<posn>|+<incr>|-<decr>|end) <stream>"},
    {"state",	STREAM_STATE,	1, 1, "<stream>"},
    {"eof",  	STREAM_EOF, 	1, 1, "<stream>"},
    {"close",	STREAM_CLOSE,	1, 1, "<stream>"},
    {"flush",	STREAM_FLUSH,	1, 1, "<stream>"},
    {"watch", 	STREAM_WATCH,	3, 3, "<stream> <what> <procName>"},
    {"ignore",	STREAM_IGNORE,	1, 1, "<stream>"},
    {NULL,   	(ClientData)NULL,	    	0, 0, NULL}
};
DEFCMD(stream,Stream,1,streamCmds,swat_prog.load|swat_prog.file,
"Usage:\n\
    stream open <file> (r|w|a|r+|w+)\n\
    stream read (line|list|char) <stream>\n\
    stream print <list> <stream>\n\
    stream write <string> <stream>\n\
    stream rewind <stream>\n\
    stream seek (<posn>|+<incr>|-<decr>|end) <stream>\n\
    stream state <stream>\n\
    stream eof <stream>\n\
    stream close <stream>\n\
    stream flush <stream>\n\
    stream watch <stream> <what> <procName>\n\
    stream ignore <stream>\n\
\n\
Examples:\n\
    \"var s [stream open kmap.def w]\"	Open the file \"kmap.def\" for writing,\n\
					creating it if it wasn't there before,\n\
					and truncating any existing file.\n\
    \"stream write $line $s\" 	    	Write the string in $line to the\n\
					open stream.\n\
    \"while {![stream eof $s]} {\n\
	var line [stream read line $s]\n\
	echo $line\n\
    }\"	    	    	    	    	Read and echo the contents of the\n\
					stream whose token is in $s.\n\
\n\
Synopsis:\n\
    This allows you to read, write, create and otherwise manipulate files\n\
    from Tcl.\n\
\n\
Notes:\n\
    * Subcommands may be abbreviated uniquely.\n\
\n\
    * Streams are a precious resource, so you should be sure to always\n\
      close them when you are done. This means stream access should usually\n\
      be performed under the wings of a \"protect\" command so the stream\n\
      gets closed even if the user types Ctrl+C.\n\
\n\
    * Swat's current directory changes as you change stack frames, with the\n\
      directory always being the one that holds the executable file for the\n\
      patient to which the function in the current frame belongs. If the <file>\n\
      given to \"stream open\" isn't absolute, it will be affected by this.\n\
\n\
    * The global variable file-init-dir contains the absolute path of the\n\
      directory in which Swat was started. It can be quite useful when forming\n\
      the <file> argument to \"stream open\".\n\
\n\
    * The second argument to \"stream open\" is the access mode of the file.\n\
      The meanings of the 5 possible values are:\n\
	r   read-only access. The <file> must already exist.\n\
	w   write-only access. If <file> doesn't already exist, it will be\n\
	    created. If it does exist, it will be truncated.\n\
	a   append mode. The file is opened for writing only. If <file>\n\
	    doesn't already exist, it will be created. If it does exist,\n\
	    writing will commence at its end.\n\
	r+  read/write. The <file> must already exist. A single read/write\n\
	    position is maintained, and it starts out at the start of the file.\n\
	w+  read/write. If <file> doesn't already exist, it will be created.\n\
	    If it does exist, it will be truncated. A single read/write\n\
	    position is maintained, and it starts out at the start of the file.\n\
\n\
    * \"stream read\" can read data from the stream in one of three formats:\n\
	line	Returns all the characters from the current position up to\n\
		the first newline or the end of the file, whichever comes\n\
		first. The newline, if seen, is placed at the end of the string\n\
		as \\n. Any other non-printable characters or backslashes\n\
		are similarly escaped.\n\
	list	Reads a single list from the stream, following all the usual\n\
		rules of Tcl list construction. If the character at the current\n\
		read position is a left brace, this will read to the matching\n\
		right brace, bringing in newlines and other whitespace. If\n\
		there is whitespace at the inital read position, it is\n\
		skipped. Standard Tcl comments before the start of the list\n\
		are also skipped over (so if the first non-whitespace char-\n\
		acter encountered is #, the characters up to the following\n\
		newline or end-of-file will also be skipped).\n\
	char	This reads a single character from the stream. If the character\n\
		isn't printable ASCII, it will be returned as one of the\n\
		regular Tcl backslash escapes.\n\
      If there's nothing left to read, you will get an empty string back.\n\
\n\
    * \"stream write\" writes the string exactly as given, without interpreting\n\
      backslash escapes. If you want to include a newline or something of the\n\
      sort in the string, you'll need to use the \"format\" command to generate\n\
      the string, or place the whole thing in braces and have the newlines\n\
      in there literally.\n\
\n\
    * While the syntax for \"stream print\" is the same as for \"stream write\",\n\
      there is a subtle difference between the two. \"stream write\" will\n\
      write the string as it's given, while \"stream print\" is intended to\n\
      write out data to be read back in by \"stream read list\". Thus the\n\
      command\n\
	stream write {foo biff} $s\n\
      would write the string \"foo biff\" to the stream. In contrast,\n\
	stream print {foo biff} $s\n\
      would write \"{foo biff}\" followed by a newline.\n\
\n\
    * To ensure that all data you have written has made it to disk, use the\n\
      \"stream flush\" command. Nothing is returned.\n\
\n\
    * \"stream rewind\" repositions the read/write position at the start of\n\
      the stream. \"stream seek\" gives you finer control over the position.\n\
      You can set the stream to an absolute position (obtained from a previous\n\
      call to \"stream seek\") by passing the byte number as a decimal number.\n\
      You can also move forward or backward in the file a relative amount by\n\
      specifying the number of bytes to move, preceded by a \"+\", for forward,\n\
      or a \"-\", for backward. Finally, you can position the pointer at the\n\
      end of the file by specifying a position of \"end\".\n\
\n\
    * \"stream seek\" returns the new read/write position, so a call of\n\
      \"stream seek +0 $s\" will get you the current position without changing \n\
      anything. If the seek couldn't be performed, -1 is returned.\n\
\n\
    * \"stream state\" returns one of three strings: \"error\", if there's been\n\
      some error accessing the file, \"eof\" if the read/write position is at\n\
      the end of the file, or \"ok\" if everything's fine. \"stream eof\" is a\n\
      shortcut for figuring if you've reached the end of the file.\n\
\n\
    * \"stream close\" shuts down the stream. The stream token should never\n\
      again be used.\n\
\n\
    * \"stream watch\" and \"stream ignore\" are valid only on UNIX and only make\n\
      sense if the stream is open to a device or a socket. \"stream watch\" causes\n\
      the procedure <procName> to be called whenever the stream is ready for\n\
      the access indicated by <what>, which is a list of conditions chosen\n\
      from the following set:\n\
	read	the stream has data that may be read.\n\
	write	the stream has room for data to be written to it.\n\
      When the stream is ready, the procedure is called:\n\
	<procName> <stream> <what>\n\
      where <what> is the list of operations for which the stream is ready.\n\
\n\
See also:\n\
    protect, source, file\n\
")
{
    Stream  *stream=0;

    if (clientData > STREAM_OPEN) {
	/*
	 * Extract and check the stream token
	 */
	int	    argNum;

	if (clientData < STREAM_REWIND) {
	    /*
	     * Two-arg functions: stream is the second of the two (arg 3)
	     */
	    argNum = 3;
	} else {
	    /*
	     * One-arg functions.
	     */
	    argNum = 2;
	}
	
	stream = (Stream *)atoi(argv[argNum]);
	if (!VALIDTPTR(stream,TAG_STREAM)) {
	    Tcl_RetPrintf(interp, "%s: not a stream", argv[argNum]);
	    return(TCL_ERROR);
	}
    }

    switch((int)clientData) {
	case STREAM_OPEN:
	{
	    int	success = FALSE;

	    stream = (Stream *)malloc_tagged(sizeof(Stream), TAG_STREAM);
	    stream->watchProc = (char *)NULL;
	    
	    stream->file = fopen(argv[2], argv[3]);
	    
	    /*
	     * Special case handling of connecting to a UNIX socket (for use in
	     * talking to emacs...
	     */
	    if (stream->file == NULL) {
#if defined(unix)
		if (errno == EOPNOTSUPP) {
		    stream->sock = socket(AF_UNIX, SOCK_STREAM, 0);
		    if (stream->sock >= 0) {
			struct sockaddr_un  saddr;
			int 	    	saddrlen;
		    
			saddr.sun_family = AF_UNIX;
			(void)strcpy(saddr.sun_path, argv[2]);
			saddrlen = strlen(argv[2]) + sizeof(saddr.sun_family);
		    
			if (connect(stream->sock, &saddr, saddrlen) < 0) {
			    (void)close(stream->sock);
			} else {
			    signal(SIGPIPE, SIG_IGN);
			    success = TRUE;
			    fcntl(stream->sock, F_SETFL, FNBIO);
			    stream->type = STREAM_SOCKET;
			    stream->sockErr = FALSE;
			}
		    }
		}
#endif
	    } else {
		stream->type = STREAM_FILE;
		success = TRUE;
	    }
	    if (!success) {
		free((char *)stream);
		Tcl_Return(interp, "nil", TCL_STATIC);
	    } else {
		Tcl_RetPrintf(interp, "%d", stream);
	    }
	    break;
	}
	case STREAM_READ:
	    if (strcmp(argv[2], "char") == 0) {
		int	    c = StreamReadChar(stream);
		
		switch(c) {
		    case EOF:
			Tcl_Return(interp, "eof", TCL_STATIC);
			break;
		    case '\n':
			Tcl_Return(interp, "\\n", TCL_STATIC);
			break;
		    case '\b':
			Tcl_Return(interp, "\\b", TCL_STATIC);
			break;
		    case '\r':
			Tcl_Return(interp, "\\r", TCL_STATIC);
			break;
		    case '\f':
			Tcl_Return(interp, "\\f", TCL_STATIC);
			break;
		    case '\033':
			Tcl_Return(interp, "\\e", TCL_STATIC);
			break;
		    case '\t':
			Tcl_Return(interp, "\\t", TCL_STATIC);
			break;
		    default:
			if (!isprint(c)) {
			    Tcl_RetPrintf(interp, "\\%03o", c);
			} else {
			    Tcl_RetPrintf(interp, "%c", c);
			}
		}
	    } else if (strcmp(argv[2], "line") == 0) {
		Buffer  buf;
		int	    c;
		
		buf = Buf_Init(80);
		
		while(((c = StreamReadChar(stream)) != '\n') && (c != EOF)) {
		    switch(c) {
			case '\\':
			    Buf_AddBytes(buf, 2, (Byte *)"\\\\");
			    break;
			case '\n':
			    Buf_AddBytes(buf, 2, (Byte *)"\\n");
			    break;
			case '\b':
			    Buf_AddBytes(buf, 2, (Byte *)"\\b");
			    break;
			case '\r':
			    Buf_AddBytes(buf, 2, (Byte *)"\\r");
			    break;
			case '\f':
			    Buf_AddBytes(buf, 2, (Byte *)"\\f");
			    break;
			case '\033':
			    Buf_AddBytes(buf, 2, (Byte *)"\\e");
			    break;
			case '\t':
			    Buf_AddBytes(buf, 2, (Byte *)"\\t");
			    break;
			default:
			    if (!isprint(c)) {
				char	b[5];
				
				sprintf(b, "\\%03o", c);
				Buf_AddBytes(buf, 4, (Byte *)b);
			    } else {
				Buf_AddByte(buf, (Byte)c);
			    }
		    }
		}
		if (c == '\n') {
		    Buf_AddBytes(buf, 2, (Byte *)"\\n");
		}
		Buf_AddByte(buf, (Byte)'\0');
		
		Tcl_Return(interp, (char *)Buf_GetAll(buf, NULL), TCL_DYNAMIC);
		Buf_Destroy(buf, FALSE);
	    } else if (strcmp(argv[2], "list") == 0) {
		Buffer  buf;
		int	    c;
		int	    level;
		int	    done;
		
		level = 0;
		done = 0;
		buf = Buf_Init(80);
		
		while(!done) {
		    c = StreamReadChar(stream);
		    
		    switch(c) {
			case EOF:
			    done = 1;
			    break;
			case '\n':
			case ' ':
			case '\t':
			case '\r':
			case '\f':
			    /*
			     * If not w/in a list, whitespace of any variety
			     * means the end of the list. Skip any initial
			     * whitespace, though, by only doing this if there's
			     * stuff in the buffer.
			     */
			    if (Buf_Size(buf) != 0) {
				if (level == 0) {
				    done = 1;
				} else {
				    Buf_AddByte(buf, (Byte)c);
				}
			    }
			    break;
			case '\\':
			    /*
			     * Escaped character -- fetch and store w/o looking
			     * at it (except for EOF, of course).
			     */
			    Buf_AddByte(buf, (Byte)c);
			    c = StreamReadChar(stream);
			    if (c != EOF) {
				Buf_AddByte(buf, (Byte)c);
			    }
			    break;
			case '{':
			    level++;
			    if (level != 1) {
				/*
				 * Only store nested braces -- we strip off the
				 * enclosing ones else we'll return a list of
				 * a list.
				 */
				Buf_AddByte(buf, (Byte)c);
			    }
			    break;
			case '}':
			    level--;
			    if (level == 0) {
				done = 1;
			    } else {
				Buf_AddByte(buf, (Byte)c);
			    }
			    break;
			case '#':
			    /*
			     * Handle comment lines. Comments are only paid
			     * attention to if we've not stored any characters.
			     * Otherwise, # is assumed to be a valid character
			     * in the list and we fall through to store it.
			     */
			    if (Buf_Size(buf) == 0) {
				/*
				 * Skip to the end of the line and go back to
				 * the top.
				 */
				while ((c = StreamReadChar(stream)) != '\n' &&
				       c != EOF)
				{
				    ;
				}
				continue;
			    }
			    /*FALLTHRU*/
			default:
			    Buf_AddByte(buf, (Byte)c);
			    break;
		    }
		}
		Buf_AddByte(buf, (Byte)'\0');
		Tcl_Return(interp, (char *)Buf_GetAll(buf, NULL), TCL_DYNAMIC);
		Buf_Destroy(buf, FALSE);
	    } else {
		return(TCL_SUBUSAGE);
	    }
	    break;
	case STREAM_PRINT:
	{
	    char	*str;
	    int	    	len;
	    
	    /*
	     * Let Tcl_Merge deal with spaces etc.
	     */
	    argv[3] = "\n";
	    str = Tcl_Merge(2, &argv[2]);
	    len = strlen(str);
	    if (stream->type == STREAM_SOCKET) {
		if (write(stream->sock, str, len) < len) {
		    stream->sockErr = TRUE;
		}
	    } else {
		(void)fwrite(str, len, 1, stream->file);
	    }
	    free(str);
	    break;
	}
	case STREAM_WRITE:
	{
	    int	len = strlen(argv[2]);
	    
	    if (stream->type == STREAM_SOCKET) {
		if (write(stream->sock, argv[2], len) < len) {
		    stream->sockErr = TRUE;
		}
	    } else {
		(void)fwrite(argv[2], len, 1, stream->file);
	    }
	    break;
	}
	case STREAM_REWIND:
	    if (stream->type == STREAM_SOCKET) {
		(void)fseek(stream->file, 0, SEEK_SET);
	    }
	    break;
	case STREAM_SEEK:
	    if (stream->type == STREAM_FILE) {
		int 	pos;
		int 	which;
	    
		switch (argv[2][0]) {
		    case '+':
			argv[2] += 1;
			/*FALLTHRU*/
		    case '-':
			pos = cvtnum(argv[2], NULL);
			which = SEEK_CUR;
			break;
		    case 'e':
			pos = 0;
			which = SEEK_END;
			break;
		    default:
			pos = cvtnum(argv[2], NULL);
			which = SEEK_SET;
			break;
		}
		if (fseek(stream->file, pos, which) < 0) {
		    Tcl_Return(interp, "-1", TCL_STATIC);
		} else {
		    Tcl_RetPrintf(interp, "%d", ftell(stream->file));
		}
	    } else {
		Tcl_Return(interp, "-1", TCL_STATIC);
	    }
	    break;
	case STREAM_STATE:
	    if (stream->type == STREAM_FILE) {
		if (ferror(stream->file)) {
		    Tcl_Return(interp, "error", TCL_STATIC);
		} else if (feof(stream->file)) {
		    Tcl_Return(interp, "eof", TCL_STATIC);
		} else {
		    Tcl_Return(interp, "ok", TCL_STATIC);
		}
	    } else {
		Tcl_Return(interp, stream->sockErr ? "error" : "ok",
			   TCL_STATIC);
	    }
	    break;
	case STREAM_EOF:
	    if (stream->type == STREAM_FILE) {
		Tcl_Return(interp, feof(stream->file) ? "1" : "0",
			   TCL_STATIC);
	    } else {
		Tcl_Return(interp, "0", TCL_STATIC);
	    }
	    break;
	case STREAM_CLOSE:
	    if (stream->type == STREAM_FILE) {
		fclose(stream->file);
	    } else {
		close(stream->sock);
	    }
	    free((char *)stream);
	    break;
	case STREAM_FLUSH:
	    if (stream->type == STREAM_FILE) {
		fflush(stream->file);
	    }
	    break;
	case STREAM_WATCH:
	{
	    char    	    **conditions;
	    int	    	    nconditions;
	    int	    	    condMask;
	    int	    	    i;

	    /*
	     * Figure the conditions for which we're to watch by breaking
	     * the list into its component pieces.
	     */
	    if (Tcl_SplitList(interp, argv[3], &nconditions,
			      &conditions) != TCL_OK)
	    {
		return(TCL_ERROR);
	    }

	    condMask = 0;
	    for (i = 0; i < nconditions; i++) {
		if (strcmp(conditions[i], "read") == 0) {
		    condMask |= RPC_READABLE;
		} else if (strcmp(conditions[i], "write") == 0) {
		    condMask |= RPC_WRITABLE;
		} else if (strcmp(conditions[i], "except") == 0) {
		    condMask |= RPC_EXCEPTABLE;
		} else {
		    Tcl_RetPrintf(interp, "stream condition %s unknown",
				  conditions[i]);
		    free((char *)conditions);
		    return(TCL_ERROR);
		}
	    }
	    free((char *)conditions);

	    if (stream->watchProc != NULL) {
		free(stream->watchProc);
	    }
	    stream->watchProc = (char *)malloc_tagged(strlen(argv[4])+1,
						      TAG_STREAM);
	    strcpy(stream->watchProc, argv[4]);
	    
	    /*
	     * Finally, tell the RPC system to watch the beast.
	     */
	    Rpc_Watch(stream->type == STREAM_SOCKET ?
		      stream->sock :
		      fileno(stream->file),
		      condMask, StreamWatchCmdHandler,
		      (Rpc_Opaque)stream);
	    break;
	}
	case STREAM_IGNORE:
	{
	    if (stream->watchProc == NULL) {
		Tcl_RetPrintf(interp, "stream %d not being watched", stream);
		return(TCL_ERROR);
	    } else {
		free(stream->watchProc);
		stream->watchProc = NULL;
		if (stream->type == STREAM_SOCKET) {
		    Rpc_Ignore(stream->sock);
		} else {
		    Rpc_Ignore(fileno(stream->file));
		}
	    }
	    break;
	}
    }

    return(TCL_OK);
}
		

/*-
 *-----------------------------------------------------------------------
 * CmdUnalias --
 *	Remove any existing alias for the given word.
 *
 * Results:
 *	TCL_OK.
 *
 * Side Effects:
 *	Any AliasRec and command for the given word are removed.
 *
 *-----------------------------------------------------------------------
 */
DEFCMD(unalias,Unalias,0,NULL,support.binding,
"Usage:\n\
    unalias <name>+\n\
\n\
Examples:\n\
    \"unalias p\"		Removes \"p\" as an alias for \"print\"\n\
\n\
    \"purge p\" 		Removes \"p\" as an alias for \"print\"\n\
\n\
Synopsis:\n\
    This removes any alias for the given command(s).\n\
\n\
Notes:\n\
    * In fact, this actually can be used to delete any command at all,\n\
      including Tcl procedures and Swat built-in commands. Once they're\n\
      gone, however, there's no way to get them back.\n\
\n\
See also:\n\
    alias\n\
")
{
    while (argc > 1) {
	Tcl_DeleteCommand(interp, argv[1]);
	argv++, argc--;
    }
    return(TCL_OK);
}

/*-
 *-----------------------------------------------------------------------
 * CmdUnassemble --
 *	Simple disassembler. Takes address and returns string for it.
 *	If second arg given, also instructs MD_Decode to decode the args
 *	as well. Note that buffers are generous to avoid trashing the
 *	stack in case of bugs.
 *
 * Results:
 *	Returned string is a list of 4 elements:
 *	    {symbolic address} {instruction} {length} {args}
 *	If args not desired, {args} is empty.
 *
 * Side Effects:
 *	None
 *
 *-----------------------------------------------------------------------
 */
DEFCMD(unassemble,Unassemble,0,NULL,swat_prog.memory,
"Usage:\n\
    unassemble [<addr> [<decode-args>]]\n\
\n\
Examples:\n\
    \"unassemble cs:ip 1\"	Disassemble the instruction at cs:ip and\n\
				return a string that shows the values of\n\
				the arguments involved.\n\
\n\
Synopsis:\n\
    This decodes data as machine instructions and returns them to you for\n\
    you to display as you like. It is not usually typed from the command\n\
    line.\n\
\n\
Notes:\n\
    * The return value is always a four-element list:\n\
	{<symbolic-addr> <instruction> <size> <args>}\n\
      where <symbolic-addr> is the address expressed as an offset from some\n\
      named symbol, <instruction> is the decoded instruction (without any\n\
      leading whitespace), <size> is the size of the instruction (in bytes)\n\
      and <args> is a string displaying the values of the instruction\n\
      operands, if <decode-args> was given and non-zero (it is the empty string\n\
      if <decode-args> is missing or 0).\n\
\n\
    * If <addr> is missing or \"nil\", the instruction at the current frame's\n\
      cs:ip is what you'll get back.\n\
\n\
See also:\n\
    listi, format-instruction, mangle-softint\n\
")
{
    GeosAddr	    	addr;	    	/* Address at which to disassemble */
    char		buffer[256];	/* Buffer for instruction itself */
    char    	    	args[512];  	/* Buffer for args */
    int	    	  	size;	    	/* Size of the instruction */
    Sym	    	    	sym;	    	/* Symbol for symbolic address */
    Address 	    	baseAddr;   	/* Address of sym (for figuring
					 * offset) */
    Boolean 	    	getArgs;    	/* True if should get args too */
    char    	    	*retv[4];
    char    	    	addrExp[256];
    char    	    	sizeBuf[32];

    if ((argc < 2) || (strcmp(argv[1], "nil") == 0)) {
	/*
	 * Wants to use CS:IP (in current frame)
	 */
	regval	ip;
	Frame	*frame = MD_CurrentFrame();

	if (frame->handle != NullHandle) {
	    /*
	     * If frame is executing in a handle, use handle:ip
	     */
	    addr.handle = frame->handle;
	    Ibm_ReadRegister(REG_MACHINE, REG_IP, &ip);
	    addr.offset = (Address)ip;
	} else {
	    /*
	     * Else must use absolute address -- NullHandle:pc
	     */
	    addr.handle = NullHandle;
	    Ibm_ReadRegister(REG_MACHINE, REG_PC, (regval *)&addr.offset);
	}
    } else if (!Expr_Eval(argv[1], NullFrame, &addr, (Type *)0, TRUE)) {
	Tcl_Error(interp, "Invalid address");
    }

    getArgs = ((argc > 2) && (atoi(argv[2]) > 0));

    /*
     * Find a symbol for the address being disassembled, if one's around.
     */
    sym = Sym_LookupAddr(addr.handle, addr.offset, SYM_LABEL|SYM_FUNCTION);
    if (!Sym_IsNull(sym)) {
	Sym_GetFuncData(sym, (Boolean *)NULL, &baseAddr, (Type *)NULL);
    }
    
    /*
     * Actually decode the instruction
     */
    if (MD_Decode(addr.handle, addr.offset, buffer, &size,
			   getArgs ? args : NULL) == FALSE)
    {
	Tcl_Return(interp, "", TCL_STATIC);
	return TCL_ERROR;
    }

    /*
     * Form the return value. If there's a label nearby, return the address
     * symbolically.
     */
    retv[0] = addrExp;
    retv[1] = buffer;
    sprintf(sizeBuf, "%d", size);
    retv[2] = sizeBuf;
    retv[3] = args;
    if (!getArgs) {
	args[0] = '\0';
    }
    if (!Sym_IsNull(sym)) {
	if (addr.offset == baseAddr) {
	    /*
	     * Exactly at the label -- don't print "+0"
	     */
	    retv[0] = Sym_Name(sym);
	} else {
	    /*
	     * Offset from label
	     */
	    sprintf(addrExp, "%s+%d", Sym_Name(sym), addr.offset - baseAddr);
	}
    } else if (addr.handle != NullHandle) {
	/*
	 * No label nearby, but we know the segment so print it segment:offset
	 */
	sprintf(addrExp, "%04xh:%04xh", Handle_Segment(addr.handle),
		(unsigned int)(addr.offset));
    } else {
	/*
	 * Print it as an absolute address.
	 */
	sprintf(addrExp, "%05xh", (unsigned int)(addr.offset));
    }
    Tcl_Return(interp, Tcl_Merge(4, retv), TCL_DYNAMIC);
    return(TCL_OK);
}
	   
/*-
 *-----------------------------------------------------------------------
 * CmdWait --
 *	Wait for the patient to stop. If the interrupt character is
 *	typed during this wait, the patient is stopped.
 *
 * Results:
 *	TCL_OK plus 1 if the patient was interrupted or 0 if not.
 *
 * Side Effects:
 *	The patient will be interrupted if Ui_Interrupt returns true.
 *	Events are dispatched. Um...
 *
 *-----------------------------------------------------------------------
 */
DEFCMD(wait,Wait,TCL_EXACT,NULL,swat_prog.patient,
"Usage:\n\
    wait\n\
\n\
Examples:\n\
    \"wait\"	    	Wait for the target PC to halt.\n\
\n\
Synopsis:\n\
    This is used after the machine has been continued with \"continue-patient\"\n\
    to wait for the machine to stop again. Its use is usually hidden by\n\
    calling \"cont\" or \"next\".\n\
\n\
Notes:\n\
    * This returns 0 if the patient halted naturally (because it hit a\n\
      breakpoint), and 1 if it was interrupted (by the user typing Ctrl+C to\n\
      Swat).\n\
\n\
    * Most procedures won't need to use this function.\n\
\n\
See also:\n\
    continue-patient, waitForPatient\n\
")
{
    int	    result = 0;
    
    Ui_AllowInterrupts(FALSE);
    while(sysFlags & PATIENT_RUNNING) {
	if (Ui_Interrupt()) {
	    result = 1;
	    Ui_ClearInterrupt();    /* So fetching of data during FULLSTOP
				     * handling doesn't get aborted */
	    Ibm_Stop();
	} else {
	    Rpc_Wait();
	}
    }
    Ui_AllowInterrupts(TRUE);
    Tcl_RetPrintf(interp, "%d", result);
    return(TCL_OK);
}


