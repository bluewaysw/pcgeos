/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Command Implementations
 * FILE:	  cmdAM.c
 *
 * AUTHOR:  	  Adam de Boor: Dec  4, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	dbg-me	    	    Dump core
 *	alias	    	    Create/examine command aliases
 *	alloc	    	    Print allocation statistics
 *	assign	    	    Modify memory
 *	autoload    	    Declare function to be loaded on demand
 *	break-taken 	    See if stopped b/c of a breakpoint
 *	dbg 	    	    Set/examine debugging flag
 *	defcmd  	    Define documented abbreviatable command
 *	defcommand    	    Define documented command
 *	defhelp	    	    Define help string
 *	defvar	    	    Define documented global variable
 *	explode	    	    Break string into list of chars
 *	frame	    	    Examine/play with stack frames
 *	getenv	    	    Return environment variable value
 *	load	    	    Load tcl file
 *	map 	    	    Apply command to list(s)
 *	mapconcat   	    Ditto but concatenate results as strings
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	12/ 4/88  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	This file contains command implementations whose names begin
 *	with the letters A through M.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: cmdAM.c,v 4.28 97/04/18 14:57:13 dbaumann Exp $";
#endif lint

#include <config.h>
#include <compat/stdlib.h>
#include "swat.h"
#include "cmd.h"
#include "private.h"
#include "sym.h"
#include "type.h"
#include "var.h"
#include "vector.h"
#include "expr.h"
#include "help.h"
#include <buf.h>
#include <ctype.h>
#include <sys/types.h>
#if defined(_WIN32)
# include <winutil.h>
#endif
/**********************************************************************
 *
 *	    	  COMMAND IMPLEMENTATIONS
 *
 *********************************************************************/

/*-
 *-----------------------------------------------------------------------
 * CmdDbgMe --
 *	Place ourself on the debug list.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Of course.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
DEFCMD(dbg-me, DbgMe, TCL_EXACT,NULL,obscure,
"Usage:\n\
    dbg-me\n\
\n\
Examples:\n\
    \"dbg-me\"		Causes Swat to dump core.\n\
\n\
Synopsis:\n\
    This command is only for debugging Swat and serves no useful purpose to\n\
    anyone but me.\n\
\n\
Notes:\n\
    * This obviously has no effect on DOS systems, and is unnecessary for Sun\n\
      systems where the debugger can attach to a running process.\n\
\n\
See also:\n\
    alloc, dbg, pid, rpc-dbg\n\
")
{
#if defined(unix)
    if (fork() == 0) {
	_abort();
    } else {
	Tcl_Return(interp, "Core dumped.", TCL_STATIC);
    }
#elif defined(_MSDOS)
    extern void PokeMDB(void);

    PokeMDB();
#elif defined(_WIN32)
    if (MessageFlush != NULL) {
	MessageFlush("dbg-me has no effect in WIN32\n");
    }
#endif
    return(TCL_OK);
}

/***************************************************
 *
 *	    	  ALIAS COMMAND
 *
 **************************************************/
typedef struct {
    char    	  *word;
    char	  *alias;
} AliasRec, *AliasPtr;

static Lst  aliases;	    /* All aliases */

/*-
 *-----------------------------------------------------------------------
 * CmdAliasCatch --
 *	Handler for aliased commands. From the AliasRec and the given
 *	args, build a new command for Tcl_Eval to execute.
 *
 * Results:
 *	Whatever Tcl_Eval returns.
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
static int
CmdAliasCatch(ClientData    clientData,	/* Description of alias */
	      Tcl_Interp    *interp,	/* Interpreter */
	      int	    argc,	/* Number of args */
	      char	    **argv)	/* The args themselves */
{
    AliasPtr	    	alias;	    /* Real description */
    char    	  	*cmd;	    /* Final command */
    register char 	*cp;	    /* General-purpose pointer into alias */
    int			start,	    /* First arg to interpolate */
			end;	    /* Last arg to interpolate */
    int			result;	    /* Result from Tcl_Eval */
    Buffer  	  	buf;	    /* Buffer in which new command is built */
    Boolean 	    	usedArg;    /* TRUE if used at least one arg. If
				     * none used, all the args are tacked on
				     * to the end to make writing aliases
				     * easier. */
    char    	    	**newargv;  /* New version of argv to avoid death
				     * while debugging an alias */

    alias = (AliasPtr)clientData;
    /*
     * Initialize an expandable buffer for the command
     */
    buf = Buf_Init(strlen(alias->alias) + 1);

    /*
     * Quote those args that need quoting...
     */
    newargv = (char **)calloc(argc+1, sizeof(char *));
    for (start = 1; start < argc; start++) {
	newargv[start] = Tcl_Merge(1, &argv[start]);
    }
    
    /*
     * Substitute for $n, $n-m, $n-, $n* and $* while copying the
     * alias into the buffer.
     */
    cp = alias->alias;
    usedArg = FALSE;
    
    while(*cp != '\0') {
	if (*cp != '$') {
	    Buf_AddByte(buf, (Byte)*cp);
	    cp++;
	} else if (isdigit(cp[1])) {
	    /*
	     * Figure starting arg number and skip over it
	     */
	    start = atoi(&cp[1]);
	    for (cp += 2; isdigit(*cp); cp++) {
		/* void */ ;
	    }

	    /*
	     * Find out if it's a range and set end appropriately.
	     */
	    switch(*cp) {
		case '-':
		    if (isdigit(cp[1])) {
			/*
			 * Ending arg given. Make sure it's in bounds.
			 */
			end = atoi(&cp[1]);
			if (end >= argc) {
			    end = argc - 1;
			}
			for (cp += 2; isdigit(*cp); cp++) {
			    /* void */ ;
			}
			break;
		    }
		    /*FALLTHRU*/
		case '*':
		    /*
		     * Range goes to the end of the arg list
		     */
		    end = argc - 1;
		    cp++;
		    break;
		default:
		    /*
		     * Single arg
		     */
		    end = -1;
	    }
	    
#define ADD_ARG(num,needSpace) \
	    if (num >= argc) { \
		Tcl_RetPrintf(interp, "%s: argument %d not given", argv[0], \
			      num);\
		return(TCL_ERROR);\
	    }\
	    Buf_AddBytes(buf, strlen(newargv[num]), (Byte *)newargv[num]); \
	    if (needSpace) {Buf_AddByte(buf, (Byte)' ');}

add_arg:
	    usedArg = TRUE;
	    if (end >= 0) {
		if (start <= end) {
		    /*
		     * Inserting a range of arguments.
		     */
		    while (start <= end) {
			ADD_ARG(start, start != end);
			start++;
		    }
		} else {
		    /*
		     * Add them in reverse.
		     */
		    while (start >= end) {
			ADD_ARG(start, start != end);
			start--;
		    }
		}
	    } else {
		/*
		 * Add just the one argument.
		 */
		ADD_ARG(start, 0);
	    }
	} else if (cp[1] == '*') {
	    /*
	     * Insert all our arguments
	     */
	    cp += 2;		/* Skip past $* */
	    if (argc != 1) {
		start = 1; end = argc - 1;
		goto add_arg;
	    }
	} else if (cp[1] == '#') {
	    /*
	     * Insert the number of arguments
	     */
	    char  	numBuf[20];

	    sprintf(numBuf, "%d", argc-1);
	    Buf_AddBytes(buf, strlen(numBuf), (Byte *)numBuf);

	    cp += 2;
	} else {
	    /*
	     * Add the dollar sign in literally.
	     */
	    Buf_AddByte(buf, (Byte)'$');
	    cp++;
	}
    }

    /*
     * If didn't use any args, place them all at the end of the command,
     * making sure there's at least one space between the command and the
     * args.
     */
    if (!usedArg) {
	Buf_AddByte(buf, (Byte)' ');

	for (start = 1; start < argc; start++) {
	    ADD_ARG(start, start != argc-1);
	}
    }
    
    /*
     * Null-terminate and get the new command
     */
    Buf_AddByte(buf, (Byte)'\0');
    cmd = (char *)Buf_GetAll(buf, (int *)NULL);

    /*
     * Evaluate and preserve the return value
     */
    result = Tcl_Eval(interp, cmd, 0, (const char **)NULL);

    /*
     * Destroy the command and its buffer structure, as well as the quoted
     * arguments.
     */
    Buf_Destroy(buf, TRUE);
    for (start = 1; start < argc; start++) {
	free(newargv[start]);
    }
    free((malloc_t)newargv);

    return(result);
}

/*-
 *-----------------------------------------------------------------------
 * CmdAliasFind --
 *	Find an alias by name. Callback function for CmdAlias and
 *	CmdUnalias via Lst_Find.
 *
 * Results:
 *	0 if it's the alias we want.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static int
CmdAliasFind(AliasPtr 	alias,
	     char	*aword)
{
    return(strcmp(alias->word, aword));
}


/***********************************************************************
 *				CmdNukeAlias
 ***********************************************************************
 * SYNOPSIS:	    Nuke the data for an alias
 * CALLED BY:	    Tcl when the alias command is deleted or overridden
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The memory is freed and the alias removed from the
 *	    	    list.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 4/88	Initial Revision
 *
 ***********************************************************************/
static void
CmdNukeAlias(ClientData	clientData)
{
    AliasPtr	alias = (AliasPtr)clientData;
    LstNode 	ln;

    /*
     * Find the thing in the list of aliases and remove it therefrom
     */
    ln = Lst_Member(aliases, (LstClientData)clientData);
    Lst_Remove(aliases, ln);

    /*
     * Free all the memory associated with it.
     */
    free(alias->word);
    free(alias->alias);
    free((char *)alias);
}
    
/*-
 *-----------------------------------------------------------------------
 * CmdAliasFindPosition --
 *	Find where in the list an alias should go. The list is sorted
 *	alphabetically, so we return 0 only when we find an alias that is
 *	alphabetically-greater or equal to the one being inserted.
 *
 * Results:
 *	0 if the alias comes after the given word.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static int
CmdAliasFindPosition(AliasPtr	alias,
		     char	*aword)
{
    return (strcmp(alias->word, aword) <= 0);
}

/*-
 *-----------------------------------------------------------------------
 * CmdAliasPrint --
 *	Print out a single alias. Callback function for CmdAlias via
 *	Lst_ForEach when given no arguments.
 *
 * Results:
 *	=== 0.
 *
 * Side Effects:
 *	The alias is printed to the patient's i/o window.
 *
 *-----------------------------------------------------------------------
 */
static int
CmdAliasPrint(AliasPtr	alias)
{
    Message("%-10s %s\n", alias->word, alias->alias);
    return(0);
}

/*-
 *-----------------------------------------------------------------------
 * CmdAlias --
 *	Bind the first word to execute the succeeding words.
 *
 * Results:
 *	TCL_OK
 *
 * Side Effects:
 *	Any previous value of the command is superceeded and cannot
 *	be recovered.
 *
 *-----------------------------------------------------------------------
 */
DEFCMD(alias,Alias,0,NULL,support.binding,
"Usage:\n\
    alias [<name> [<body>]]\n\
\n\
Examples:\n\
    \"alias p print\"	    	    Execute \"print\" when the user types the\n\
				    command \"p\". Any arguments to \"p\" get\n\
				    passed to \"print\" in the order they were\n\
				    given.\n\
    \"alias while {for {} $1 {} $2}\" Executes an appropriate \"for\" loop when\n\
				    the \"while\" command is executed with its\n\
				    two arguments: a test expression and a\n\
				    body of commands to execute.\n\
    \"alias\" 	    	    	    Prints all the defined aliases.\n\
    \"alias while\"		    Prints what the \"while\" command is aliased\n\
				    to.\n\
\n\
Synopsis:\n\
    This is a short-cut to allow you to make commands you commonly type easier\n\
    to use, and to quickly define simple new commands.\n\
\n\
Notes:\n\
    * If you give no arguments the current aliases are all displayed.\n\
\n\
    * If you give a single argument, the name of an existing alias, the\n\
      command that will be executed when you use the alias is printed.\n\
\n\
    * The <body> string is usually in braces, as it usually involves whitespace\n\
      and can contain newlines for the longer aliases.\n\
\n\
    * You can use the pseudo-variables $1, $2, etc. in the <body> to represent\n\
      the 1st, 2nd, etc. argument given when the alias is invoked. They are\n\
      pseudo-variables as the \"var\" command will not operate on them, nor are\n\
      they available to any procedure invoked by the alias.\n\
\n\
    * You can also interpolate a range of the arguments using $<start>-<end>.\n\
      If you do not give an <end>, then the arguments from <start> to the last\n\
      one will be interpolated. \n\
\n\
    * $* will interpolate all the arguments.\n\
\n\
    * $# will interpolate the actual number of arguments.\n\
\n\
    * If you do not use any of these pseudo-variables, all the arguments given\n\
      to the alias will be appended to the <body>.\n\
\n\
    * Interpolation of the values for these pseudo-variables occurs regardless\n\
      of braces in the <body>.\n\
\n\
    * It is an error to specify an argument number when there are fewer than\n\
      that many arguments given to the alias.\n\
\n\
See also:\n\
    unalias\n\
")
{
    AliasPtr	  alias;

    if (aliases == (Lst)NULL) {
	aliases = Lst_Init(FALSE);
    }
    
    if (argc == 1) {
	Lst_ForEach(aliases, CmdAliasPrint, (LstClientData)NULL);
	return(TCL_OK);
    } else if (argc == 2) {
	LstNode	  	ln;

	ln = Lst_Find(aliases, (LstClientData)argv[1], CmdAliasFind);
	if (ln != NILLNODE) {
	    alias = (AliasPtr)Lst_Datum(ln);

	    Message("%s\n", alias->alias);
	}
    } else {
	LstNode	  	ln;
	int		nWords;
	char		**words;
	int		flags;

	alias = (AliasPtr)malloc_tagged(sizeof(AliasRec), TAG_ALIAS);
	
	alias->word = malloc_tagged(strlen(argv[1]) + 1, TAG_ALIAS);
	strcpy(alias->word, argv[1]);
	
	alias->alias = malloc_tagged(strlen(argv[2]) + 1, TAG_ALIAS);
	strcpy(alias->alias, argv[2]);

	/*
	 * Split the alias into words so we can see if the first word already
	 * exists as a command and can inherit the flags from it (other than
	 * TCL_EXACT and TCL_PROC and TCL_DEBUG...well, that leaves just
	 * TCL_NOEVAL, but we're being expandable here...) if so.
	 */
	if (Tcl_SplitList(interp, alias->alias, &nWords, &words) == TCL_OK) {
	    Tcl_CmdProc *junkProc;
	    ClientData  junkData;
	    Tcl_DelProc *junkDelProc;
	    const char 	*junkName;
	
	    if (Tcl_FetchCommand(interp, words[0], &junkName, &junkProc, &flags,
				 &junkData, &junkDelProc))
	    {
		flags &= ~(TCL_EXACT|TCL_PROC|TCL_DEBUG);
		flags |= TCL_EXACT;
	    } else {
		flags = TCL_EXACT;
	    }
	    free((char *)words);
	} else {
	    flags = TCL_EXACT;
	}

	/*
	 * Install the new command. If re-aliasing something, this will
	 * nuke the old data for it...
	 */
	Tcl_CreateCommand(interp, argv[1], CmdAliasCatch, flags,
			  (ClientData)alias, CmdNukeAlias);

	/*
	 * Now any old version is gone from the aliases list, we can put the
	 * new data in (in order, of course).
	 */
	ln = Lst_Find(aliases, (LstClientData)argv[1], CmdAliasFindPosition);
	if (ln == NILLNODE) {
	    (void)Lst_AtEnd(aliases, (LstClientData)alias);
	} else {
	    (void)Lst_Insert(aliases, ln, (LstClientData)alias);
	}
    }
    /*
     * Override the error messages generated by TCL when defining an alias
     * for the first time (TclFindCmd makes the result be "invoked \"..\"
     * which isn't a valid command name")
     */
    Tcl_Return(interp, "", TCL_STATIC);
    return(TCL_OK);
}


/***********************************************************************
 *				AllocCmd
 ***********************************************************************
 * SYNOPSIS:	    Print allocation statistics to a file
 * CALLED BY:	    TCL
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    The file is opened and stats printed to it.
 *
 * STRATEGY:	    Open the first arg to a FILE *, then call
 *	    	    	malloc_printstats(fprintf, FILE *)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(alloc,Alloc,TCL_EXACT,NULL,obscure,
"Usage:\n\
    alloc <file>\n\
\n\
Examples:\n\
    \"alloc foo.stats\"	Dumps the current memory usage information to the file\n\
			\"foo.stats\" in the current directory (as dictated by\n\
			the current stack frame).\n\
\n\
Synopsis:\n\
    Produces a raw dump of all the memory Swat is currently using, giving\n\
    the type of data in each block and the address from which the allocation\n\
    routine was called.\n\
\n\
Notes:\n\
    * The dump by itself isn't particularly useful, but a shell script exists\n\
      to process the dump into useful information. It lives in Tools/swat/stats\n\
      (as do previous raw and processed statistics) and is called \"pa\".\n\
\n\
    * If Swat is compiled with caller-tracing not enabled in the malloc package,\n\
      use \"panc\" to process the output, not \"pa\".\n\
\n\
See also:\n\
    dbg-me, dbg, pid, rpc-dbg\n\
")
{
    FILE    *f;
#if defined(unix)
    extern void fprintf(FILE *, const char *, ...);
#endif

#ifndef MEM_TRACE
    Warning("Memory tracing not enabled -- only printing block types");
#endif /* MEM_TRACE */
    f = fopen(argv[1], "w");
    if (f != NULL) {
	malloc_printstats((malloc_printstats_callback *)fprintf, (void *)f);
	fclose(f);
	return(TCL_OK);
    } else {
	Tcl_Error(interp, "Couldn't open file");
    }
}



/***********************************************************************
 *				CatchAutoLoad
 ***********************************************************************
 * SYNOPSIS:	    Catch a call to an auto-loaded procedure.
 * CALLED BY:	    Tcl
 * RETURN:	    Result of Tcl_Eval
 * SIDE EFFECTS:    The file to be loaded is and the function re-invoked.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 1/88	Initial Revision
 *
 ***********************************************************************/
static void FreeSourceCmd(ClientData data) { free((malloc_t)data); }
int
CatchAutoLoad(ClientData    data,
	      Tcl_Interp    *interp,
	      int   	    argc,
	      char  	    **argv)
{
    char    	    *sourcecmd;
    char    	    *cmd;
    int	    	    result;

    cmd = Tcl_Merge(argc, argv);
    
    /*
     * Make a private copy of the source command before we try and evaluate
     * it since (presumably) the sourcing of the file will cause the data
     * for us to be deleted (since the command that invoked us will be
     * redefined). When this happens, other data may be allocated over it and
     * the interpreter will go off into south indiana and return us an error
     * we don't deserve.
     */
    sourcecmd = (char *)malloc(strlen((char *)data) + 1);
    strcpy(sourcecmd, (char *)data);
    result = Tcl_Eval(interp, sourcecmd, 0, 0);
    
    if (result == TCL_OK) {
	/*
	 * Re-form command (note "sourcecmd" has theoretically been freed when
	 * we were overridden).
	 */
	Tcl_CmdProc *cmdProc;
	int 	    junkFlags;
	ClientData  junkData;
	Tcl_DelProc *junkDelProc;
	const char  *realName;

	/*
	 * Make sure we were overridden so we don't recurse infinitely...
	 */
	Tcl_FetchCommand(interp, argv[0], &realName, &cmdProc, &junkFlags,
			 &junkData, &junkDelProc);
	if (cmdProc == CatchAutoLoad) {
	    Tcl_RetPrintf(interp,
			  "autoload: %s not redefined when \"%s\" executed",
			  realName, sourcecmd);
	    result = TCL_ERROR;
	} else {
	    result = Tcl_Eval(interp, cmd, 0, 0);
	}
    }
    free(sourcecmd);
    free(cmd);
    return(result);
}


/***********************************************************************
 *				AutoloadCmd
 ***********************************************************************
 * SYNOPSIS:	    Handle the autoload command
 * CALLED BY:	
 * RETURN:	
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 1/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(autoload,Autoload,TCL_EXACT,NULL,swat_prog.load|swat_prog.file,
"Usage:\n\
    autoload <function> <flags> <file> [<class> <docstring>]\n\
\n\
Examples:\n\
    \"autoload ewatch 0 emacs\"	    load the file \"emacs.tcl\" when the\n\
				    ewatch command is first executed. The\n\
				    user may abbreviate the command.\n\
    \"autoload cycles 1 timing\"      load the file \"timing.tcl\" when the\n\
				    cycles command is first executed. The\n\
				    user must type the command completely.\n\
    \"autoload print 2 print\"	    load the file \"print.tcl\" when the\n\
				    print command is first executed. The\n\
				    user may abbreviate the command and\n\
				    the Tcl interpreter will not evaluate\n\
				    its arguments.\n\
\n\
Synopsis:\n\
    This command allows the first invocation of a command to automatically\n\
    force the transparent reading of a file of Tcl commands.\n\
\n\
Notes:\n\
    * autoload takes 3 or 5 arguments: the command, an integer with bit\n\
      flags telling how the interpreter should invoke the command, the file\n\
      that should be read to define the command (this may be absolute or on\n\
      load-path) and an optional help class and string for the command.\n\
\n\
    * The help class and string need only be given if the file to be loaded\n\
      isn't part of the system library (doesn't have its help strings ex-\n\
      tracted when Swat is built).\n\
\n\
    * The <flags> argument has the following bit-flags:\n\
	Bit	Meaning if Set\n\
	----------------------\n\
	 0	User must type the command's name exactly. The command will\n\
		be defined by \"defsubr\" or \"defcommand\" when <file> is\n\
		loaded.\n\
	 1	The interpreter will not evaluate arguments passed to the\n\
		command. All arguments will be merged into a single string\n\
		and passed to the command as one argument. The command will\n\
		use the special \"noeval\" argument when it is defined.\n\
\n\
See also:\n\
    defsubr, defcmd, defcommand, proc\n\
")
{
    Tcl_CmdProc	    *junkProc;
    int	    	    junkFlags;
    ClientData	    junkClientData;
    Tcl_DelProc	    *junkDelProc;
    const char	    *realName;

    if (argc != 4 && argc != 6) {
	Tcl_Error(interp,
		  "Usage: autoload <func> <flags> <file> [<class> <docstring>]");
    } else {
	int	flags = cvtnum(argv[2], (char **)0);

	flags = (flags & 1 ? TCL_EXACT : 0) | (flags & 2 ? TCL_NOEVAL : 0);

	/*
	 * If command not yet defined, or command to autoload is a prefix of
	 * an existing abbreviatable command, define the command to call
	 * our intercept routine.
	 */
	if (!Tcl_FetchCommand(interp, argv[1], &realName,
			      &junkProc, &junkFlags,
			      &junkClientData, &junkDelProc) ||
	    ((flags & TCL_EXACT) && strcmp(argv[1], realName) != 0))
	{
	    char	*sourcecmd = (char *)malloc_tagged(strlen("load ")+
							   strlen(argv[3])+1,
							   TAG_ETC);

	    sprintf(sourcecmd, "load %s", argv[3]);
	    Tcl_CreateCommand(interp, argv[1], CatchAutoLoad,
			      flags,
			      (ClientData)sourcecmd,
			      FreeSourceCmd);
	    if (argc == 6) {
		Help_Store(argv[1], argv[4], argv[5]);
	    }
	}
    }
    return(TCL_OK);
}

/*-
 *-----------------------------------------------------------------------
 * CmdBrkTaken --
 *	See if the patient stopped because it took a breakpoint.
 *
 * Results:
 *	1 if it did, 0 if it didn't.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
DEFCMD(break-taken,BrkTaken,TCL_EXACT,NULL,swat_prog.breakpoint,
"Usage:\n\
    break-taken [<flag>]\n\
\n\
Examples:\n\
    \"break-taken\"   	Returns 1 if the machine stopped because of a\n\
			breakpoint.\n\
    \"break-taken 0\"	Specify that no breakpoint was actually taken to\n\
			stop the machine.\n\
\n\
Synopsis:\n\
    This is used to determine if the machine stopped because a breakpoint\n\
    was hit and taken.\n\
\n\
Notes:\n\
    * Setting the break-taken flag is a rather obscure operation. It is\n\
      useful primarily in complex commands that single-step the machine\n\
      until a particular address is reached, or a breakpoint is taken when\n\
      a breakpoint must be used to skip over a procedure call, or condense\n\
      multiple iterations of an instruction with a REP prefix into 1. For\n\
      an example of this use, refer to the \"cycles\" command.\n\
\n\
See also:\n\
    brk, irq\n\
")
{
    if (argc != 1) {
	/*
	 * Wants to set the breakpoint flag.
	 */
	if (atoi(argv[1])) {
	   sysFlags |= PATIENT_BREAKPOINT;
	} else {
	    sysFlags &= ~PATIENT_BREAKPOINT;
	}
	Tcl_Return(interp, NULL, TCL_STATIC);
    } else {
	Tcl_Return(interp, (sysFlags&PATIENT_BREAKPOINT) ? "1" : "0",
		   TCL_STATIC);
    }
    return(TCL_OK);
}

    

/***********************************************************************
 *				DebugCmd
 ***********************************************************************
 * SYNOPSIS:	    Set our internal debug flag
 * CALLED BY:	    Tcl
 * RETURN:	    State of debug flag
 * SIDE EFFECTS:    debug may be altered
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/10/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(dbg,Dbg,TCL_EXACT,NULL,obscure,
"Usage:\n\
    dbg [<flag>]\n\
\n\
Examples:\n\
    \"dbg 1\"	Set Swat's internal debug flag.\n\
\n\
Synopsis:\n\
    This is useful only when debugging Swat itself.\n\
\n\
Notes:\n\
    * When the debug flag is set, Swat will print out a number of bits of\n\
      debugging information, including changes in handle state, and errors not\n\
      normally deemed important enough to notify the user. In addition, if the\n\
      user chooses to abort when asked, Swat will generate a core dump,\n\
      rather than cleaning up and exiting.\n\
\n\
See also:\n\
    dbg-me, alloc, pid, rpc-dbg\n\
")
{
    if (argc > 1) {
	debug = atoi(argv[1]);
    }
    Tcl_Return(interp, debug ? "1" : "0", TCL_STATIC);
    return(TCL_OK);
}


/***********************************************************************
 *				DefacommandCmd
 ***********************************************************************
 * SYNOPSIS:	    Define a command with help string.
 * CALLED BY:	    Tcl
 * RETURN:	    Nothing
 * SIDE EFFECTS:    A new command is created and its help string registered
 *
 * STRATEGY:	    Extract the help string from the argv and register it.
 *		    Copy the body down and invoke Tcl_ProcCmd as "proc" to
 *		    	create the new procedure.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/14/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(defcmd,Defacommand,TCL_EXACT,NULL,swat_prog.def|swat_prog.proc|swat_prog.tcl.proc,
"Usage:\n\
    defcmd <name> <args> <help-class> <help-string> <body>\n\
\n\
Examples:\n\
    look in almost any .tcl file in the system library for an example, as\n\
    one is too large to give here.\n\
\n\
Synopsis:\n\
    This creates a new Tcl procedure with on-line help whose name may be\n\
    uniquely abbreviated when the user wishes to invoke it.\n\
\n\
Notes:\n\
    * <help-class> is a Tcl list of places in which to store the <help-string>,\n\
      with the levels in the help tree separated by periods. The leaf node\n\
      for each path is added by this command and is <name>, so a command\n\
      \"foo\" with <help-class> \"swat_prog.tcl\" would have its <help-string>\n\
      stored as \"swat_prog.tcl.foo\".\n\
\n\
    * Because the name you choose for a procedure defined this way can have\n\
      an impact on the unique abbreviation for some other command, you should\n\
      use this sparingly.\n\
\n\
See also:\n\
    defcommand, proc, help\n\
")
{
    Tcl_Frame	*top;

    if (argc == 5) {
	Warning("%s: old-style definition -- defaulting to class \"top\"",
		argv[1]);
	argv[5] = argv[4];
	argv[4] = argv[3];
	argv[3] = "top";
    } else if (argc != 6) {
	Tcl_Error(interp,
		  "Usage: defcmd <cmd> <args> <class> <help> <body>");
    }
    Help_Store(argv[1], argv[3], argv[4]);

    argv[0] = "proc";	/* Create a procedure, not a subr */
    argv[3] = argv[5];
    argv[4] = 0;

    /*
     * Prevent ugly death if stopped in Tcl debugger...
     */
    top = Tcl_CurrentFrame(interp);
    top->argc = 4;
    
    return Tcl_ProcCmd(clientData, interp, 4, argv);
}
/***********************************************************************
 *				DefcommandCmd
 ***********************************************************************
 * SYNOPSIS:	    Define a subroutine with help string.
 * CALLED BY:	    Tcl
 * RETURN:	    Nothing
 * SIDE EFFECTS:    A new subroutine is created and its help string registered
 *
 * STRATEGY:	    Extract the help string from the argv and register it.
 *		    Copy the body down and invoke Tcl_ProcCmd as "defsubr"
 *	    	    	to create the new subroutine.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/14/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(defcommand,Defcommand,TCL_EXACT,NULL,swat_prog.def|swat_prog.proc|swat_prog.tcl.proc,
"Usage:\n\
    defcommand <name> <args> <help-class> <help-string> <body>\n\
\n\
Examples:\n\
    look in almost any .tcl file in the system library for an example, as\n\
    one is too large to give here.\n\
\n\
Synopsis:\n\
    This creates a new Tcl procedure with on-line help whose name must be\n\
    given exactly when the user wishes to invoke it.\n\
\n\
Notes:\n\
    * <help-class> is a Tcl list of places in which to store the <help-string>,\n\
      with the levels in the help tree separated by periods. The leaf node\n\
      for each path is added by this command and is <name>, so a command\n\
      \"foo\" with <help-class> \"swat_prog.tcl\" would have its <help-string>\n\
      stored as \"swat_prog.tcl.foo\".\n\
\n\
See also:\n\
    defcmd, proc, help\n\
")
{
    Tcl_Frame	    *top;
    
    if (argc == 5) {
	Warning("%s: old-style definition -- defaulting to class \"top\"",
		argv[1]);
	argv[5] = argv[4];
	argv[4] = argv[3];
	argv[3] = "top";
    } else if (argc != 6) {
	Tcl_Error(interp,
		  "Usage: defcommand <cmd> <args> <class> <help> <body>");
    }
    Help_Store(argv[1], argv[3], argv[4]);

    argv[0] = "defsubr";	/* Create a subroutine, not a procedure */
    argv[3] = argv[5];
    argv[4] = 0;

    /*
     * Prevent ugly death if stopped in Tcl debugger...
     */
    top = Tcl_CurrentFrame(interp);
    top->argc = 4;
    
    return Tcl_ProcCmd(clientData, interp, 4, argv);
}

/***********************************************************************
 *				DefhelpCmd
 ***********************************************************************
 * SYNOPSIS:	    Allows the definition of help strings for internal
 *	    	    nodes of the help tree.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    A help string may be (but probably isn't) entered.
 *
 * STRATEGY:	    Just call Help_Store after verifying args.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/14/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(defhelp,Defhelp,TCL_EXACT,NULL,swat_prog.def|swat_prog.help,
"Usage:\n\
    defhelp <topic> <help-class> <help-string>\n\
\n\
Examples:\n\
    \"defhelp breakpoint top {Commands relating to the setting of breakpoints}\"\n\
	    	    	Sets the help for \"breakpoint\" in the \"top\" category\n\
			to the given string.\n\
\n\
Synopsis:\n\
    This is used to define the help string for an internal node of the help\n\
    tree (a node that is used in the path for some other real topic, such\n\
    as a command or a variable).\n\
\n\
Notes:\n\
    * This cannot be used to override a string that resides in the DOC file.\n\
\n\
    * You only really need this if you have defined your own help-topic\n\
      category.\n\
\n\
    * <help-class> is a list of places in which to store the <help-string>,\n\
      with the levels in the help tree separated by periods, and the different\n\
      paths where the string should be stored separated by vertical bars.\n\
      The leaf node for each path is added by this command and is <name>,\n\
      so a topic \"foo\" with <help-class> \"swat_prog.tcl\" would have its\n\
      <help-string> stored as \"swat_prog.tcl.foo\".\n\
\n\
See also:\n\
    help\n\
")
{
    if (argc != 4) {
	Tcl_Error(interp, "Usage: defhelp <topic> <help-class> <help-string>");
    }
    Help_Store(argv[1], argv[2], argv[3]);

    return(TCL_OK);
}


/***********************************************************************
 *				DefvarCmd
 ***********************************************************************
 * SYNOPSIS:	    Define a global variable
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    The variable is defined and the value given assigned
 *	    	    to it if the variable wasn't defined before. The
 *	    	    assignment takes place in the global scope.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/30/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(defvar,Defvar,1,NULL,swat_prog.def|swat_prog.var,
"Usage:\n\
    defvar <name> <value> [<help-class> <help-string>]\n\
\n\
Examples:\n\
    \"defvar printRegions 0\"	Defines \"printRegions\" as a global variable and\n\
				gives it the value 0, if it didn't have one\n\
				already.\n\
\n\
Synopsis:\n\
    This command is used in .tcl files to define a global variable and give\n\
    it an initial value, should the variable not have been defined before.\n\
\n\
Notes:\n\
    * If the variable is one the user may want to change, as opposed to one\n\
      that is used to hold data internal to a command across invocations of\n\
      the command, you will want to give it on-line help using the\n\
      <help-class> and <help-string> arguments.\n\
\n\
    * <help-class> is a Tcl list of places in which to store the <help-string>,\n\
      with the levels in the help tree separated by periods. The leaf node\n\
      for each path is added by this command and is <name>, so a variable\n\
      \"foo\" with <help-class> \"variable.output\" would have its <help-string>\n\
      stored as \"variable.output.foo\".\n\
\n\
See also:\n\
    var, help\n\
")
{
    if (argc != 5 && argc != 3) {
	Tcl_Error(interp,
		  "Usage: defvar <variable> <default-value> [<class> <help>]");
    }
    if (strcmp(Tcl_GetVar(interp, argv[1], TRUE), "") == 0) {
	Tcl_SetVar(interp, argv[1], argv[2], TRUE);
    }
    if (argc == 5) {
	Help_Store(argv[1], argv[3], argv[4]);
    }
    
    Tcl_Return(interp, NULL, TCL_STATIC);
    return(TCL_OK);
}


/***********************************************************************
 *				ExplodeCmd
 ***********************************************************************
 * SYNOPSIS:	    Blow a string into a list of its component chars
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK and the new list
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 3/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(explode,Explode,TCL_EXACT,NULL,swat_prog.proc|swat_prog,
"Usage:\n\
    explode <string> [<sep-set>]\n\
\n\
Examples:\n\
    \"explode $args\"	Breaks the string stored in the variable \"args\"\n\
			into a list of its individual letters.\n\
    \"explode $file /\"	Breaks the string stored in the variable \"file\"\n\
			into a list of its components, using \"/\" as the\n\
			boundary between components when performing the split.\n\
\n\
Synopsis:\n\
    Breaks a string into a list of its component letters, allowing them to\n\
    be handled quickly via a foreach loop, or the map or mapconcat commands.\n\
\n\
Notes:\n\
    * This is especially useful for parsing command switches.\n\
\n\
See also:\n\
    foreach, index, range\n\
")
{
    char    *cp;
    int	    len;

    if (argc == 2) {
	Buffer  result;
	result = Buf_Init(0);

	for (cp = argv[1]; *cp; cp++) {
	    if (isspace(*cp)) {
		Buf_AddByte(result, (Byte)'{');
		Buf_AddByte(result, (Byte)*cp);
		Buf_AddByte(result, (Byte)'}');
	    } else {
		if (*cp == '{') {
		    Buf_AddBytes(result, 2, (Byte *)"\\{");
		} else if (*cp == '}') {
		    Buf_AddBytes(result, 2, (Byte *)"\\}");
		} else if (*cp == '\\') {
		    Buf_AddBytes(result, 2, (Byte *)"\\\\");
		} else {
		    Buf_AddByte(result, (Byte)*cp);
		}
	    }
	    Buf_AddByte(result, (Byte)' ');
	}

	cp = (char *)Buf_GetAll(result, &len);
	cp[len-1] = '\0';
	Buf_Destroy(result, FALSE);
    } else if (argc == 3) {
	Vector	args;
	Boolean	atStart;
	char	*sep;
	char	*victim;

	victim = (char *)malloc(strlen(argv[1])+1);
	strcpy(victim, argv[1]);

	args = Vector_Create(sizeof(char *), ADJUST_ADD, 10, 10);
	for (cp = victim, atStart = TRUE; *cp != '\0'; cp++) {
	    /*
	     * If at the start of a new element, store its address at the end
	     * of the vector.
	     */
	    if (atStart) {
		Vector_Add(args, VECTOR_END, (void *)&cp);
		atStart = FALSE;
	    }
	    /*
	     * See if the current character is in the set of separators.
	     */
	    for (sep = argv[2]; *sep != '\0'; sep++) {
		if (*cp == *sep) {
		    /*
		     * It's a separator, so biff it, note we need to start a
		     * new element next time, and break out of this search
		     * loop.
		     */
		    *cp = '\0';
		    atStart = TRUE;
		    break;
		} else if (sep[1] == '-') {
		    /*
		     * Separator is a range. See if the char falls within
		     * the range.
		     */
		    if ((*cp > *sep) && (*cp <= sep[2])) {
			/*
			 * Yes. Do as above.
			 */
			*cp = '\0';
			atStart = TRUE;
			break;
		    }
		    /*
		     * Advance over the first two chars of the range, leaving
		     * the loop to advance over the third.
		     */
		    if (sep[2] != '\0') {
			sep += 2;
		    } else {
			Tcl_Error(interp,
				  "explode: missing end of range");
		    }
		}
	    }
	}
	/*
	 * Merge all the elements into a single list and biff the vector
	 * itself. Then free the copy of argv[1], since everything's been
	 * duplicated into the result of the Tcl_Merge.
	 */
	cp = Tcl_Merge(Vector_Length(args), (char **)Vector_Data(args));
	Vector_Destroy(args);
	free((malloc_t)victim);
    } else {
	Tcl_Error(interp, "Usage: explode <string> [<sep-set>]");
    }
    
    Tcl_Return(interp, cp, TCL_DYNAMIC);
    return(TCL_OK);
}
    
/***************************************************
 *
 *	    	  FRAME COMMAND
 *
 **************************************************/

/*-
 *-----------------------------------------------------------------------
 * CmdFrame --
 *	Commands to access a stack frame.
 *
 * Results:
 *	TCL_OK or TCL_ERROR.
 *
 * Side Effects:
 *	A stack frame may be created or destroyed.
 *
 *-----------------------------------------------------------------------
 */
#define FRAME_TOP   	(ClientData)0
#define FRAME_CUR   	(ClientData)1
#define FRAME_GET   	(ClientData)2
#define FRAME_FUNCTION	(ClientData)3
#define FRAME_FUNCSYM	(ClientData)4
#define FRAME_SCOPE 	(ClientData)5
#define FRAME_INFO  	(ClientData)6
#define FRAME_RETADDR   (ClientData)7
#define FRAME_PATIENT  	(ClientData)8
#define FRAME_REGISTER	(ClientData)9
#define FRAME_NEXT  	(ClientData)10
#define FRAME_PREV  	(ClientData)11
#define FRAME_SET   	(ClientData)12
#define FRAME_SETREG	(ClientData)13
#define FRAME_NUMBER	(ClientData)14

static const CmdSubRec	frameCmds[] = {
    {"top",  	FRAME_TOP,  	0, 0, ""},
    {"cur",  	FRAME_CUR,  	0, 0, ""},
    {"next", 	FRAME_NEXT, 	1, 1, "<frame>"},
    {"prev", 	FRAME_PREV, 	1, 1, "<frame>"},
    {"get",  	FRAME_GET,  	4, 4, "<ss> <sp> <cs> <ip>"},
    {"function",FRAME_FUNCTION,	0, 1, "[<frame>]"},
    {"funcsym",	FRAME_FUNCSYM,	0, 1, "[<frame>]"},
    {"scope",	FRAME_SCOPE,	0, 1, "[<frame>]"},
    {"info", 	FRAME_INFO, 	0, 1, "[<frame>]"},
    {"retaddr", FRAME_RETADDR,	0, 1, "[<frame>]"},
    {"patient",	FRAME_PATIENT,	0, 1, "[<frame>]"},
    {"register",FRAME_REGISTER,	1, 2, "<regName> [<frame>]"},
    {"set",  	FRAME_SET,  	1, 2, "<frame> [<notify>]"},
    {"setreg",	FRAME_SETREG,	2, 3, "<regName> <value> [<frame>]"},
    {CMD_ANY,	FRAME_NUMBER,	0, 0, "[(+|-|#)]<number>"},
    {NULL,   	(ClientData)NULL,	    	0, 0, NULL}
};
DEFCMD(frame,Frame,0,frameCmds,top.stack|swat_prog.stack,
"Usage:\n\
    frame top\n\
    frame cur\n\
    frame get <ss> <sp> <cs> <ip>\n\
    frame next <frame>\n\
    frame prev <frame>\n\
    frame function [<frame>]\n\
    frame funcsym [<frame>]\n\
    frame scope [<frame>]\n\
    frame info [<frame>]\n\
    frame retaddr [<frame>]\n\
    frame patient [<frame>]\n\
    frame register <regName> [<frame>]\n\
    frame set <frame> [<notify>]\n\
    frame setreg <regName> <value> [<frame>]\n\
    frame +<number>\n\
    frame -<number>\n\
    frame <number>\n\
\n\
Examples:\n\
    \"var f [frame top]\"		Fetches the token for the frame at the top\n\
				of the current thread's stack and stores it\n\
				in the variable \"f\"\n\
    \"var f [frame next $f]\"	Fetches the token for the next frame up the\n\
				stack (away from the top) from that whose token\n\
				is in $f\n\
    \"frame register ax $f\"  	Returns the value of the AX register in the\n\
				given frame.\n\
    \"frame 1\"	    	    	Sets the current frame for the current thread\n\
				to be the top-most one.\n\
\n\
Synopsis:\n\
    This command provides access to the stack-decoding functions of Swat. Most\n\
    of the subcommands deal with frame tokens, but a few also handle frame\n\
    numbers, for the convenience of the user.\n\
\n\
Notes:\n\
    * Subcommands may be abbreviated uniquely.\n\
\n\
    * Stack decoding works by heuristic, rather than relying on the presence\n\
      of a created stack frame pointed to by BP in each function. Because\n\
      of this, it can occasionally get confused.\n\
\n\
    * Frame tokens are valid only while the target machine is stopped and are\n\
      invalidated when it is continued.\n\
\n\
    * Each frame records the address on the stack where each register was\n\
      most-recently pushed (i.e. by the frame closest to it on the way toward\n\
      the top of the stack). Register pushes are looked for only at the\n\
      start of a function in what can be considered the function prologue.\n\
\n\
    * \"frame register\" and \"frame setreg\" allow you to get or set the value\n\
      held in a register in the given frame. For \"setreg\", <value> is a\n\
      standard address expression, only the offset of which is used to set\n\
      the register.\n\
\n\
    * \"frame register\" returns all registers but \"pc\" as a decimal number.\n\
      \"pc\" is formatted as two hex numbers (each preceded by \"0x\") separated\n\
      by a colon.\n\
\n\
    * \"frame info\" prints out information on where the register values for\n\
      \"frame register\" and \"frame setreg\" are coming from/going to for the\n\
      given or currently-selected frame. Because of the speed that can be\n\
      gained by only pushing registers when you absolutely have to, there\n\
      are many functions in GEOS that do not push the registers they\n\
      save at their start, so Swat does not notice that they are actually\n\
      saved. It is good to make sure a register value is coming from a reliable\n\
      source before deciding your program has a bug simply because the value\n\
      returned by \"frame register\" is invalid.\n\
\n\
    * For any subcommand where the <frame> token is optional, the currently-\n\
      selected frame will be used if you give no token.\n\
\n\
    * \"frame cur\" returns the token for the currently-selected stack frame.\n\
\n\
    * \"frame set\" is what sets the current frame, when set by a Tcl procedure.\n\
\n\
    * \"frame +<number>\" selects the frame <number> frames up the stack (away\n\
      from the top) from the current frame. \"frame -<number>\" goes the other\n\
      way.\n\
\n\
    * \"frame <number>\" selects the frame with the given number, where the\n\
      top-most frame is considered frame number 1 and numbers count up from\n\
      there.\n\
\n\
    * \"frame funcsym\" returns the symbol token for the function active in the\n\
      given (or current) frame. If no known function is active, you get \"nil\".\n\
\n\
    * \"frame scope\" returns the full name of the scope that is active in the\n\
      given (or current) frame. This will be different from the function if,\n\
      for example, one is in the middle of an \"if\" that contains variables\n\
      that are local to it only.\n\
\n\
    * \"frame function\" returns the name of the function active in the given\n\
      (or current) frame. If no known function is active, you get the cs:ip\n\
      for the frame, formatted as two hex numbers separated by a colon.\n\
\n\
    * \"frame patient\" returns the token for the patient that owns the function\n\
      in which the frame is executing.\n\
\n\
See also:\n\
    addr-parse, switch\n\
")
{
    Frame		*frame;

    if (sysFlags & PATIENT_DIED || (curPatient->curThread == NullThread))
    {
	Tcl_Error(interp, "Patient not active/has no threads");
    }
    
    if (clientData >= FRAME_FUNCTION && clientData <= FRAME_PATIENT) {
	/*
	 * Handle frame for optional-frame commands
	 */
	if (argc == 3) {
	    frame = (Frame *)atoi(argv[2]);
	} else {
	    frame = curPatient->frame;
	}
	if (!MD_FrameValid(frame)) {
	    Tcl_Error(interp, "frame not valid");
	}
    } else if (clientData >= FRAME_NEXT && clientData <= FRAME_SET) {
	/*
	 * Fetch frame for mandatory-frame commands.
	 */
	frame = (Frame *)atoi(argv[2]);
	if (!MD_FrameValid(frame)) {
	    Tcl_Error(interp, "frame not valid");
	}
    } else {
	frame = (Frame *)NULL;
    }

    /*
     * Those subcommands that return a frame place their return value in
     * "frame" and drop through. Those that return other information or
     * don't return a frame, return from w/in the conditional.
     */
    switch((int)clientData) {
    case FRAME_GET:
	frame = MD_GetFrame((word)cvtnum(argv[2], NULL),
			    (word)cvtnum(argv[3], NULL), 
			    (word)cvtnum(argv[4], NULL),
			    (word)cvtnum(argv[5], NULL));
	break;
    case FRAME_TOP:
	frame = MD_CurrentFrame();
	if (curPatient->frame == NullFrame) {
	    curPatient->frame = frame;
	}
	break;
    case FRAME_NEXT:
	frame = MD_NextFrame(frame);
	break;
    case FRAME_PREV:
	frame = MD_PrevFrame(frame);
	break;
    case FRAME_CUR:
	frame = curPatient->frame;
	break;
    case FRAME_FUNCSYM:
	Tcl_Return(interp, Sym_ToAscii(frame->function), TCL_STATIC);
	return(TCL_OK);
    case FRAME_FUNCTION:
	if (!Sym_IsNull(frame->function)) {
	    Tcl_Return(interp, Sym_Name(frame->function), TCL_STATIC);
	    return(TCL_OK);
	} else if (frame->handle != NullHandle) {
	    regval	ip;
	    
	    if (MD_GetFrameRegister(frame, REG_MACHINE, REG_IP, &ip)) {
		Tcl_RetPrintf(interp, "%04xh:%04xh",
			      Handle_Segment(frame->handle), ip);
		return(TCL_OK);
	    } else {
		Tcl_Error(interp, "Couldn't read frame pc");
	    }
	} else {
	    Address 	pc;
            regval      value ;
	    
	    if (MD_GetFrameRegister(frame, REG_MACHINE, REG_PC, &value)) {
                pc = (Address)value ;
		Tcl_RetPrintf(interp, "%04xh:%04xh",
                              SegmentOf(pc),
                              OffsetOf(pc)) ;
		return(TCL_OK);
	    } else {
		Tcl_Error(interp, "Couldn't read frame pc");
	    }
	}
    case FRAME_SCOPE:
	if (!Sym_IsNull(frame->scope)) {
	    Tcl_Return(interp, Sym_FullName(frame->scope), TCL_DYNAMIC);
	} else {
	    Tcl_RetPrintf(interp, "%s::", curPatient->name);
	}
	return(TCL_OK);
    case FRAME_RETADDR:
    {
	GeosAddr    ga;
	char	    retString[12];

	ga = MD_FrameRetaddr(frame);
	sprintf(retString, "%05xh %05xh", (unsigned int)(ga.handle),
		(unsigned int)(ga.offset));
	Tcl_Return(interp, retString, TCL_VOLATILE);
	return TCL_OK;
    }
    case FRAME_INFO:
    {
	char	*cp = ((Sym_IsNull(frame->function)) ? "?" :
		       Sym_FullName(frame->function));
	regval    cs, ip, fp;
	
	Message("Function: %s   ", cp);
	if (!Sym_IsNull(frame->function)) {
	    free(cp);
	}
	
	if (frame->handle) {
	    cs = Handle_Segment(frame->handle);
	} else {
	    MD_GetFrameRegister(frame, REG_MACHINE, REG_CS, &cs);
	}
	MD_GetFrameRegister(frame, REG_MACHINE, REG_IP, &ip);
	MD_GetFrameRegister(frame, REG_MACHINE, REG_FP, &fp);
	Message("Address %04xh:%04xh    fp = %04xh\n", cs, ip, fp);
	
	MD_FrameInfo(frame);
	return(TCL_OK);
    }
    case FRAME_PATIENT:
	Tcl_RetPrintf(interp, "%d", frame->patient);
	return(TCL_OK);
    case FRAME_REGISTER:
    {
	regval	reg;
	Reg_Data	*data;
	
	if (argc == 4) {
	    frame = (Frame *)atoi(argv[3]);
	} else {
	    frame = curPatient->frame;
	}
	if (!MD_FrameValid(frame)) {
	    Tcl_Error(interp, "frame not valid");
	}
	
	data = (Reg_Data *)Private_GetData(argv[2]);
	if (data == (Reg_Data *)NULL) {
	    Tcl_Error(interp, "No such register defined");
	}
	if (data->type == REG_MACHINE && data->number == REG_PC) {
	    /*
	     * PC needs to be returned as segment:offset.
	     */
	    if (frame->handle != NullHandle) {
		regval	ip;
		
		if (MD_GetFrameRegister(frame, REG_MACHINE,
					REG_IP, &ip))
		{
		    Tcl_RetPrintf(interp, "%04xh:%04xh",
				  Handle_Segment(frame->handle), ip);
		    return(TCL_OK);
		} else {
		    Tcl_Error(interp, "Couldn't read frame pc");
		}
	    } else {
		Address 	pc;
                regval          value ;
		
		if (MD_GetFrameRegister(frame, REG_MACHINE,
					REG_PC, &value))
		{
                    pc = (Address)value ;
		    Tcl_RetPrintf(interp, "%04xh:%04xh",
                                  SegmentOf(pc),
                                  OffsetOf(pc)) ;
		    return(TCL_OK);
		} else {
		    Tcl_Error(interp, "Couldn't read frame pc");
		}
	    }
	} else if (! MD_GetFrameRegister(frame, data->type,
					 data->number,
					 &reg))
	{
	    Tcl_Error(interp, "Couldn't read frame register");
	} else {
	    Tcl_RetPrintf(interp, "%d", reg);
	    return(TCL_OK);
	}
    }
    case FRAME_SETREG:
    {
	Reg_Data    *data;
	GeosAddr    addr;
	Type	    valType;
	
	if (argc == 5) {
	    frame = (Frame *)atoi(argv[4]);
	} else {
	    frame = curPatient->frame;
	}
	if (!MD_FrameValid(frame)) {
	    Tcl_Error(interp, "frame not valid");
	}
	
	data = (Reg_Data *)Private_GetData(argv[2]);
	if (data == (Reg_Data *)NULL) {
	    Tcl_Error(interp, "No such register defined");
	}
	if (!Expr_Eval(argv[3], NullFrame, &addr, &valType, FALSE)) {
	    Tcl_RetPrintf(interp, "Could not parse value to which to set %s",
			  argv[2]);
	    return(TCL_ERROR);
	}

	if (data->type == REG_MACHINE && data->number == REG_PC) {
	    word    	cs, ip;

	    if (addr.handle == NullHandle) {
		Tcl_Error(interp, "Cannot set PC to an absolute address");
	    }

	    cs = Handle_Segment(addr.handle);
	    ip = (word)addr.offset;
	    if (cs == 0) {
		Tcl_RetPrintf(interp, "handle %04xh is not resident, so it has no segment to assign to CS",
			      Handle_ID(addr.handle));
		return(TCL_ERROR);
	    }

	    if (!MD_SetFrameRegister(frame, REG_MACHINE, REG_CS, cs)) {
		Tcl_Error(interp, "unable to write frame CS");
	    }
	    if (!MD_SetFrameRegister(frame, REG_MACHINE, REG_IP, ip)) {
		Tcl_Error(interp, "unable to write frame IP");
	    }
	} else {
	    if (addr.handle == ValueHandle) {
		regval	    value;

		switch(Type_Class(valType)) {
		    case TYPE_POINTER:
			if ((data->type == REG_MACHINE) &&
			    ((data->number == REG_DS) ||
			     (data->number == REG_ES) ||
			     (data->number == REG_CS) ||
			     (data->number == REG_SS) 
#if REGS_32                             
                             ||
                             (data->number == REG_FS) ||
                             (data->number == REG_GS)
#endif
                             ))
			{
			    /*
			     * Segment register. Pointer, by definition,
			     * is a far pointer, so use its segment.
			     */
			    assert(Type_Sizeof(valType) == 4);

			    value = (*(dword *)addr.offset) >> 16;
			} else {
			    /*
			     * Just use the offset portion of the pointer,
			     * since the register isn't a segment register.
			     */
			    value = (*(dword *)addr.offset) & 0xffff ;
			}
			break;
		    default:
		    {
#if REGS_32
                        regval	*newval = (regval *)Var_Cast((genptr)addr.offset,
							   valType,
							   type_Long);
#else
                        regval	*newval = (regval *)Var_Cast((genptr)addr.offset,
							   valType,
							   type_Word);
#endif
                        if (newval != NULL) {
			    /*
			     * Cast successful. Free the old value and set
			     * condition to be the new value as a word.
			     */
			    free((malloc_t)addr.offset);
			    addr.offset = (Address)newval;
			    value = *newval;
			} else {
			    /*
			     * Cast failed, so generate an error after freeing
			     * the value.
			     */
			    free((malloc_t)addr.offset);
			    Tcl_RetPrintf(interp,
					  "%s: cannot be cast to a word",
					  argv[3]);
			    return(TCL_ERROR);
			}
			break;
		    }
		}
		free((malloc_t)addr.offset);
		
		if (!MD_SetFrameRegister(frame, data->type,
					 data->number,
					 value))
		{
		    Tcl_RetPrintf(interp, "Couldn't write frame register %s",
				  argv[2]);
		    return(TCL_ERROR);
		}
	    } else {
		if ((data->type == REG_MACHINE) &&
		    ((data->number == REG_DS) ||
		     (data->number == REG_ES) ||
		     (data->number == REG_CS) ||
		     (data->number == REG_SS)))
		{
		    if (! MD_SetFrameRegister(frame, data->type,
					      data->number,
					      Handle_Segment(addr.handle)))
		    {
			Tcl_RetPrintf(interp,
				      "Couldn't write frame register %s",
				      argv[2]);
			return(TCL_ERROR);
		    }
		} else {
		    if (!MD_SetFrameRegister(frame, data->type,
					     data->number,
					     (regval)addr.offset))
		    {
			Tcl_RetPrintf(interp,
				      "Couldn't write frame register %s",
				      argv[2]);
			return(TCL_ERROR);
		    }
		}
	    }
	}
	return(TCL_OK);
    }
    case FRAME_NUMBER:
	if (index("#+-0123456789", argv[1][0]) != (char *)NULL) {
	    /*
	     * Switch the current frame to be the one indicated.
	     */
	    int 	  relative = 0;
	    int 	  frameNum;
	    Frame	  *prev;
	    
	    if (argv[1][0] == '#') {
		argv[1] += 1;
	    }
	    if (argv[1][0] == '+') {
		relative = 1;
		argv[1] += 1;
	    } else if (argv[1][0] == '-') {
		relative = -1;
		argv[1] += 1;
	    }
	    
	    frameNum = atoi(argv[1]);
	    
	    prev = (Frame *)NULL;
	    
	    if (relative == 0) {
		frame = MD_CurrentFrame();
		frameNum -= 1;
		
		while((frameNum > 0) && (frame != NullFrame)) {
		    frame = MD_NextFrame(frame);
		    frameNum -= 1;
		}
		if (frameNum > 0 || frame == NullFrame) {
		    Tcl_Error(interp, "Not that many frames in the stack");
		}
		
	    } else if (relative > 0) {
		frame = curPatient->frame;
		
		while((frameNum > 0) && (frame != NullFrame)) {
		    frame = MD_NextFrame(frame);
		    frameNum -= 1;
		}
		
		if (frameNum > 0 || frame == NullFrame) {
		    Tcl_Error(interp, "Can't go up that many frames");
		}
	    } else {
		frame = curPatient->frame;
		
		while((frameNum > 0) && (frame != NullFrame)) {
		    frame = MD_PrevFrame(frame);
		    frameNum -= 1;
		}
		if (frameNum > 0 || frame == NullFrame) {
		    Tcl_Error(interp, "Can't go down that many frames");
		}
	    }
	    
	    curPatient->frame = frame;
	    curPatient->scope = frame->scope;
	    
#if 0
	set_file_and_line:
	    if (frame->function) {
		Address	    pc;
		
		Sym_GetFuncData(frame->function, &curPatient->file, (Type *)NULL);
		if (curPatient->file != NullFile) {
		    MD_GetFrameRegister(frame, REG_MACHINE,
					REG_PC, (word *)&pc);
		    curPatient->line = Source_GetLine(curPatient->file, pc,
						      &curPatient->file);
		} else {
		    curPatient->line = -1;
		}
	    } else {
		curPatient->file = NullFile;
		patient->line = -1;
	    }
#endif
	    Status_Changed();
	    Tcl_Return(interp, NULL, TCL_STATIC);
	    return(TCL_OK);
	} else {
	    return(TCL_USAGE);
	}
    case FRAME_SET:
	curPatient->frame = frame;
	if (argc == 3 || atoi(argv[3])) {
	    Status_Changed();
	}
	curPatient->scope = frame->scope;
	Tcl_Return(interp, NULL, TCL_STATIC);
	/*goto set_file_and_line;*/
	return(TCL_OK);
    }
    
    if (frame == NullFrame) {
	Tcl_Return(interp, "nil", TCL_STATIC);
    } else {
	Tcl_RetPrintf(interp, "%d", frame);
    }

    return(TCL_OK);
}
#if defined(_WIN32)
/*
 * for link list of env variables we have retrieved
 */
typedef struct _envVarNode { 
    char 	*name;
    char 	*value;
    struct _envVarNode *next;
} envVarNode;
#endif	

/***********************************************************************
 *				GetenvCmd
 ***********************************************************************
 * SYNOPSIS:	    Return an environment variable's value.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK and value or TCL_OK and nil if no such var
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    WIN32 is special with the addition of the registry -
 *		    try registry under swat, then ntsdk, then try getenv 
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	1/ 3/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(getenv,Getenv,1,NULL,swat_prog,
"Usage:\n\
    getenv <name>\n\
\n\
Examples:\n\
    \"getenv PTTY\"	Fetches the value of the PTTY environment variable.\n\
\n\
Synopsis:\n\
    Returns the value for a variable defined in Swat's environment.\n\
\n\
Notes:\n\
    * If the variable isn't defined, this returns the empty string.\n\
\n\
See also:\n\
    var, string\n\
")
{
    extern char	*getenv();
    char    	*result;
#if defined(_WIN32)
    char	workbuf[256];
    Boolean	retval;
    static envVarNode *envVarHead = NULL;
    envVarNode 	*envVarCur, *envVarNew;
    long 	dw;
#endif

    if (argc != 2) {
	Tcl_Error(interp, "Usage: getenv <name>");
    }
#if !defined(_WIN32)
    result = getenv(argv[1]);
#else /* WIN32*/ 
    /* 
     * strategy - use a link list to store env variables retrieved.
     *            This way each variable is only allocated space once.
     *            The initial look up is in the registry as a string
     *            under Swat, next under ntsdk, then as a dword under
     *            those places, finally to the system to see if the
     *            nt environment variable is set. 
     */
    result = NULL;
    
    /*
     * check if we already have retrieved the value and 
     * allocated space for it
     */
    envVarCur = envVarHead;
    while (envVarCur != NULL) {
	if (strcmpi(envVarCur->name, argv[1]) == 0) {
	    result = envVarCur->value;
	    break;
	}
	envVarCur = envVarCur->next;
    }
    
    if (envVarCur == NULL) {
	/* 
	 * haven't yet retrieved the value
	 */
	retval = Registry_FindStringValue(Tcl_GetVar(interp, "file-reg-swat", 
						     TRUE),
					  argv[1], workbuf, sizeof(workbuf));
	if ((retval == FALSE) || (workbuf[0] == '\0')) {
	    retval = Registry_FindStringValue(Tcl_GetVar(interp, 
							 "file-reg-ntsdk",
							 TRUE),
					      argv[1], workbuf, 
					      sizeof(workbuf));
	    if ((retval == FALSE) || (workbuf[0] == '\0')) {
		retval = Registry_FindDWORDValue(Tcl_GetVar(interp, 
							    "file-reg-swat",
							    TRUE),
						 argv[1],
						 &dw);
		if (retval == FALSE) {
		    retval = Registry_FindDWORDValue(Tcl_GetVar(interp, 
							     "file-reg-ntsdk",
								TRUE),
						     argv[1],
						     &dw);
		    if (retval == FALSE) {
			char arg1up[256];
			int i;

			for (i=0; (i<strlen(argv[1])) && (i<255); i++) {
			    arg1up[i] = toupper(argv[1][i]);
			}
			arg1up[i] = '\0';
			result = getenv(arg1up);
		    } else {
			sprintf(workbuf, "%d", dw);
			result = workbuf;
		    }
		} else {
		    sprintf(workbuf, "%d", dw);
		    result = workbuf;
		}
	    } else {
		result = workbuf;
	    }
	} else {
	    result = workbuf;
	}

	/*
	 * allocate space for the resulting link list node, 
	 * this will never get freed
	 */
	if (result != NULL) {
	    envVarNew = (envVarNode *)malloc(sizeof(envVarNode));
	    envVarNew->name = (char *)malloc((strlen(argv[1]) + 1) 
					      * sizeof(char));
	    strcpy(envVarNew->name, argv[1]);
	    envVarNew->value = (char *)malloc((strlen(result) + 1) 
					      * sizeof(char));
	    strcpy(envVarNew->value, result);
	    result = envVarNew->value;
	    envVarNew->next = envVarHead;
	    envVarHead = envVarNew;
	}
    }

#endif
    Tcl_Return(interp, result ? result : "", TCL_STATIC);

    return(TCL_OK);
}

/***********************************************************************
 *				MapCmd
 ***********************************************************************
 * SYNOPSIS:	    Apply a command expression to the elements of a list
 *	    	    or lists, returning a list of the results.
 * CALLED BY:	    TCL
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Use Tcl_SplitList to break the lists apart.
 *	    	    Bind each element to its variable in turn,
 *	    	    evaluating the command expression and saving the
 *	    	    result.
 *	    	    Use Tcl_Merge to form the results into a list, which
 *	    	    is returned.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/14/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(map,Map,TCL_EXACT,NULL,swat_prog.list,
"Usage:\n\
    map <var-list> <data-list>+ <body>\n\
\n\
Examples:\n\
    \"map {i j} {a b} {c d} {list $i $j}\"\n\
	    	    	    Executes the command \"list $i $j\" with i and j\n\
			    assigned to successive elements of the lists\n\
			    {a b} and {c d}, respectively, merging the\n\
			    results into the list {{a c} {b d}}\n\
\n\
Synopsis:\n\
    This applies a command string to the successive elements of one or more\n\
    lists, binding each element in turn to a variable and evaluating the\n\
    command string. The results of all the evaluations are merged into a\n\
    result list.\n\
\n\
Notes:\n\
    * The number of variables given in <var-list> must match the number of\n\
      <data-list> arguments you give.\n\
\n\
    * All the <data-list> arguments must have the same number of elements.\n\
\n\
    * You do not specify the result of the <body> with the \"return\" command.\n\
      Rather, the result of <body> is the result of the last command executed\n\
      within <body>.\n\
\n\
See also:\n\
    mapconcat, foreach\n\
")
{
    char    	**vars,
		***lists,
		**results;
    int	    	n;
    int	    	numElts;
    int	    	numLists;
    int	    	i, j;
    int	    	result;

    if (argc < 4) {
	Tcl_Error(interp, "Usage: map <var-list> <data-list>+ <body>");
    }

    /*
     * Find the names of all the variables
     */
    if (Tcl_SplitList(interp, argv[1], &numLists, &vars) != TCL_OK) {
	return(TCL_ERROR);
    }
    /*
     * Make sure the number of variables matches the number of lists. Since
     * there are three arguments besides the lists, we subtract 3 from argc
     * for the check...
     */
    if (numLists != argc-3) {
	free((char *)vars);
	Tcl_Error(interp,
		  "map: number of lists doesn't match number of variables");
    }

    if (numLists > 1) {
	/*
	 * Make sure no duplicate variables were given...
	 * XXX: Do this really? Seems a waste of time...
	 */
	for (i = 0; i < numLists; i++) {
	    for (j = i+1; j < numLists; j++) {
		if ((vars[i][1] == vars[j][1]) &&
		    (strcmp(vars[i], vars[j]) == 0))
		{
		    free((char *)vars);
		    Tcl_RetPrintf(interp,
				  "map: variables %d and %d are the same",
				  i, j);
		    return(TCL_ERROR);
		}
	    }
	}
    }
    
    lists = (char ***)malloc(numLists * sizeof(char **));

    /*
     * Break each list into its pieces
     */
    numElts = 0;		/* For GCC */
    for (i = 0; i < numLists; i++) {
	if (Tcl_SplitList(interp, argv[2+i], &n, &lists[i]) != TCL_OK) {
	    /*
	     * Error in one of the lists -- clean up after ourselves.
	     */
clean_up:
	    free((char *)vars);
	    for (i--; i >= 0; i--) {
		free((char *)lists[i]);
	    }
	    free((char *)lists);
	    return(TCL_ERROR);
	}
	if (i == 0) {
	    numElts = n;
	} else if (n != numElts) {
	    Tcl_Return(interp, "map: lists not of same length", TCL_STATIC);
	    goto clean_up;
	}
    }

    /*
     * Allocate room for the results
     */
    results = (char **)malloc(numElts * sizeof(char *));

    result = TCL_OK;

    for (j = 0; j < numElts; j++) {
	/*
	 * Bind all the variables.
	 */
	for (i = 0; i < numLists; i++) {
	    Tcl_SetVar(interp, vars[i], lists[i][j], FALSE);
	}
	/*
	 * Evaluate the command
	 */
	result = Tcl_Eval(interp, argv[argc-1], 0, 0);
	if (result == TCL_BREAK) {
	    break;
	} else if (result != TCL_OK && result != TCL_CONTINUE) {
	    /*
	     * Leave result set to error string from command.
	     */
	    goto finish;
	}
	/*
	 * Save the result, making sure we've got sole ownership of it.
	 */
	if (interp->dynamic) {
	    /*
	     * Just use the result, being sure to set dynamic FALSE so
	     * Tcl_Eval won't free the thing.
	     */
	    results[j] = (char *)interp->result;
	    interp->dynamic = FALSE;
	} else {
	    /*
	     * If static, make a dynamic copy of it so it doesn't go away
	     * (might be in the interpreter's resultSpace).
	     */
	    results[j] = (char *)malloc(strlen(interp->result) + 1);
	    strcpy(results[j], interp->result);
	}
    }
    /*
     * Merge all the results into a single list.
     */
    Tcl_Return(interp, Tcl_Merge(j, results), TCL_DYNAMIC);
    result = TCL_OK;

 finish:
    /*
     * Clean up after ourselves. Only thing we have to be careful of
     * is the number of results we got -- if we hit an error in the middle,
     * only the first j results will be set.
     */
    while(--j >= 0) {
	free(results[j]);
    }
    free((malloc_t)results);
    for (i = 0; i < numLists; i++) {
	free((char *)lists[i]);
    }
    free((malloc_t)lists);
    free((char *)vars);

    return(result);
}



/***********************************************************************
 *				MapConcatCmd
 ***********************************************************************
 * SYNOPSIS:	    Apply a command expression to the elements of a list
 *	    	    or lists, returning the concatenation of the results
 *	    	    as a single string.
 * CALLED BY:	    TCL
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Use Tcl_SplitList to break the lists apart.
 *	    	    Bind each element to its variable in turn,
 *	    	    evaluating the command expression and saving the
 *	    	    result.
 *	    	    Merge the results into a single string, bracketing
 *	    	    it with braces if it contains whitespace
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/14/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(mapconcat,MapConcat,TCL_EXACT,NULL,swat_prog.list,
"Usage:\n\
    mapconcat <var-list> <data-list>+ <body>\n\
\n\
Examples:\n\
    \"mapconcat {i j} {a b} {c d} {list $i $j}\"\n\
	    	    	    Executes the command \"list $i $j\" with i and j\n\
			    assigned to successive elements of the lists\n\
			    {a b} and {c d}, respectively, merging the\n\
			    results into the string "a cb d"\n\
\n\
Synopsis:\n\
    This applies a command string to the successive elements of one or more\n\
    lists, binding each element in turn to a variable and evaluating the\n\
    command string. The results of all the evaluations are merged into a\n\
    result string by concatenating each of the results with no space between\n\
    results.\n\
\n\
Notes:\n\
    * The number of variables given in <var-list> must match the number of\n\
      <data-list> arguments you give.\n\
\n\
    * All the <data-list> arguments must have the same number of elements.\n\
\n\
    * You do not specify the result of the <body> with the \"return\" command.\n\
      Rather, the result of <body> is the result of the last command executed\n\
      within <body>.\n\
\n\
See also:\n\
    map, foreach\n\
")
{
    char    	**vars,	    	/* List of variables */
		***lists,   	/* List of lists */
		**results;  	/* List of results */
    int	    	n;  	    	/* General counter */
    int	    	numElts;    	/* Number of elements in each list */
    int	    	numLists;   	/* Number of lists/variables */
    int	    	i, j;	    	/* Indices into vars and results etc. */
    int	    	result;	    	/* Return code */
    char    	*retval, *cp;	/* For concatentation */
    int	    	len;

    if (argc < 4) {
	Tcl_Error(interp,
		  "Usage: mapconcat <varlist> <list1>...<listn> <tcl-command>");
    }

    /*
     * Find the names of all the variables
     */
    if (Tcl_SplitList(interp, argv[1], &numLists, &vars) != TCL_OK) {
	return(TCL_ERROR);
    }
    /*
     * Make sure the number of variables matches the number of lists. Since
     * there are three arguments besides the lists, we subtract 3 from argc
     * for the check...
     */
    if (numLists != argc-3) {
	free((char *)vars);
	Tcl_Error(interp,
		  "mapconcat: number of lists doesn't match number of variables");
    }

    if (numLists > 1) {
	/*
	 * Make sure no duplicate variables were given...
	 * XXX: Do this really? Seems a waste of time...
	 */
	for (i = 0; i < numLists; i++) {
	    for (j = i+1; j < numLists; j++) {
		if ((vars[i][1] == vars[j][1]) &&
		    (strcmp(vars[i], vars[j]) == 0))
		{
		    free((char *)vars);
		    Tcl_RetPrintf(interp,
				  "mapconcat: variables %d and %d are the same",
				  i, j);
		    return(TCL_ERROR);
		}
	    }
	}
    }
    
    lists = (char ***)malloc(numLists * sizeof(char **));

    /*
     * Break each list into its pieces
     */
    numElts = 0;		/* For GCC */
    for (i = 0; i < numLists; i++) {
	if (Tcl_SplitList(interp, argv[2+i], &n, &lists[i]) != TCL_OK) {
	    /*
	     * Error in one of the lists -- clean up after ourselves.
	     */
clean_up:
	    free((char *)vars);
	    for (i--; i >= 0; i--) {
		free((char *)lists[i]);
	    }
	    free((malloc_t)lists);
	    return(TCL_ERROR);
	}
	if (i == 0) {
	    numElts = n;
	} else if (n != numElts) {
	    Tcl_Return(interp,
		       "mapconcat: lists not of same length", TCL_STATIC);
	    goto clean_up;
	}
    }

    /*
     * Allocate room for the results
     */
    results = (char **)malloc(numElts * sizeof(char *));

    result = TCL_OK;

    for (j = 0; j < numElts; j++) {
	/*
	 * Bind all the variables.
	 */
	for (i = 0; i < numLists; i++) {
	    Tcl_SetVar(interp, vars[i], lists[i][j], FALSE);
	}
	/*
	 * Evaluate the command
	 */
	result = Tcl_Eval(interp, argv[argc-1], 0, 0);
	if (result == TCL_BREAK) {
	    break;
	} else if (result != TCL_OK && result != TCL_CONTINUE) {
	    /*
	     * Leave result set to error string from command.
	     */
	    goto finish;
	}
	/*
	 * Save the result, making sure we've got sole ownership of it.
	 */
	if (interp->dynamic) {
	    /*
	     * Just use the result, being sure to set dynamic FALSE so
	     * Tcl_Eval won't free the thing.
	     */
	    results[j] = (char *)interp->result;
	    interp->dynamic = FALSE;
	} else {
	    /*
	     * If static, make a dynamic copy of it so it doesn't go away
	     * (might be in the interpreter's resultSpace).
	     */
	    results[j] = (char *)malloc(strlen(interp->result) + 1);
	    strcpy(results[j], interp->result);
	}
    }
    /*
     * Merge all the results into a single string, making sure not to muck
     * up j.
     */

    result = TCL_OK;

    for (len=1, i = 0; i < j; i++) {
	len += strlen(results[i]);
    }
    retval = cp = (char *)malloc(len);
    for (i = 0; i < j; i++) {
	char	*cp2 = results[i];

	while (*cp2) {
	    *cp++ = *cp2++;
	}
    }
    *cp = '\0';
    
    Tcl_Return(interp, retval, TCL_DYNAMIC);

 finish:
    /*
     * Clean up after ourselves. Only thing we have to be careful of
     * is the number of results we got -- if we hit an error in the middle,
     * only the first j results will be set.
     */
    while(--j >= 0) {
	free(results[j]);
    }
    free((malloc_t)results);
    for (i = 0; i < numLists; i++) {
	free((char *)lists[i]);
    }
    free((malloc_t)lists);
    free((char *)vars);

    return(result);
}
