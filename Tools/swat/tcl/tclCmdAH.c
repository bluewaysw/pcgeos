/* 
 * tclCmdAH.c --
 *
 *	This file contains the top-level command routines for most of
 *	the Tcl built-in commands whose names begin with the letters
 *	A to H.
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
static char *rcsid = "$Id: tclCmdAH.c,v 1.53 97/05/23 13:53:51 weber Exp $ SPRITE (Berkeley)";
#endif not lint

#include <config.h>
#include <ctype.h>
#include <stdio.h>
#include <malloc.h>
#include <compat/string.h>
#include <sys/types.h>
#include <errno.h>
#include <compat/stdlib.h>

#if defined(unix)
# include <sys/signal.h>
# include <sys/file.h>
# include <sys/stat.h>
# include <sys/time.h>
# include <sys/resource.h>
# include <sys/wait.h>
# include <sys/dir.h>
# include <pwd.h>
extern int errno;
#else 
#include <compat/dirent.h>
#endif

#if defined(_MSDOS) || defined(_WIN32)
# include <io.h>
# include <process.h>
# include <fcntl.h>
# define F_OK 0
# define R_OK 1
# define W_OK 2
# if defined(_MSDOS)
#  include <stat.h>
#  include <dos.h>
#  define access(n,m) _access(n,m)
#  define stat(n,s) _stat(n,s)
# else  /* _WIN32 specific */
#  include <sys/stat.h>
#  if !defined(_MSC_VER)
#   define direct dirent
#  endif
# endif
#endif /* _MSDOS || _WIN32 */

#include "tclInt.h"

/*
 * Library imports:
 */

extern double atof(const char *);

/*
 *----------------------------------------------------------------------
 *
 * Tcl_BreakCmd --
 *
 *	This procedure is invoked to process the "break" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

static const Tcl_SubCommandRec breakCmds[] = {
    {TCL_CMD_END}	    /* No args allowed */
};

DEFCMD(break,Tcl_Break,TCL_EXACT,breakCmds,swat_prog.tcl.loop|tcl,
"Usage:\n\
    break\n\
\n\
Examples:\n\
    \"break\"	    Break out of the current loop.\n\
\n\
Synopsis:\n\
    Breaks out of the current loop or the current nested interpreter.\n\
\n\
Notes:\n\
    * Only the closest-enclosing loop can be exited via this command.\n\
\n\
    * If you've entered a nested interpreter, e.g. by calling a function\n\
      in the patient, use this to exit the interpreter and restore the\n\
      registers to what they were before you made the call.\n\
\n\
See also:\n\
    continue, for.\n\
")
{
    return TCL_BREAK;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_CaseCmd --
 *
 *	This procedure is invoked to process the "case" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

static const Tcl_SubCommandRec caseCmds[] = {
    {TCL_CMD_ANY, 0, 2, TCL_CMD_NOCHECK, "<string> [in] [<pat> <body>]+"},
    {TCL_CMD_END}
};

DEFCMD(case,Tcl_Case,TCL_EXACT,caseCmds,swat_prog.tcl.conditional,
"Usage:\n\
    case <string> [in] [<pat> <body>]+\n\
\n\
Examples:\n\
    \"[case $c in\n\
      {[0-9]} {\n\
         # do something with digit\n\
      }\n\
      default {\n\
	 # do something with non-digit\n\
      }\n\
     ]\"	    	    	Do one of two things depending on whether the character\n\
			in $c is a digit.\n\
\n\
Synopsis:\n\
    Perform one of a set of actions based on whether a string matches one or\n\
    more patterns.\n\
\n\
Notes:\n\
    * Each <pat> argument is a list of patterns of the form described for\n\
      the \"string match\" command.\n\
\n\
    * Each <pat> argument must be accompanied by a <body> to execute.\n\
\n\
    * If a <pat> contains the special pattern \"default,\" the associated <body>\n\
      will be executed if no other pattern matches. The difference between\n\
      \"default\" and \"*\" is a pattern of \"*\" causes the <body> to be executed\n\
      regardless of the patterns in the remaining <pat> arguments, while\n\
      \"default\" postpones the decision until all the remaining patterns have\n\
      been checked.\n\
\n\
    * You can give the literal \"in\" argument if you wish to enhance the\n\
      readability of your code.\n\
\n\
See also:\n\
    string, if.\n\
")
{
    char    *string = argv[1];	/* String to match */
    int	    i;	    	    	/* Current position in argv */
    int	    defaultIdx;	    	/* Index of default body */

    if (strcmp(argv[2], "in") == 0) {
	i = 3;
    } else {
	i = 2;
    }
    defaultIdx = 0;
    while (i < argc) {
	char	**patArgv;
	int 	patArgc;
	int 	j;

	if (Tcl_SplitList(interp, argv[i], &patArgc, &patArgv) != TCL_OK) {
	    return(TCL_ERROR);
	}

	for (j = 0; j < patArgc; j++) {
	    if (strcmp(patArgv[j], "default") == 0) {
		if (defaultIdx != 0) {
		    free((char *)patArgv);
		    Tcl_Error(interp, "case has more than one default");
		}
		
		defaultIdx = i+1;
	    } else if (Tcl_StringMatch(string, patArgv[j])) {
		break;
	    }
	}
	free((char *)patArgv);

	if (j != patArgc) {
	    /*
	     * We matched one of the patterns, so execute the body.
	     */
	    i += 1;
	    if (i == argc) {
		return(TCL_SUBUSAGE);
	    }
	    return(Tcl_Eval(interp, argv[i], 0, 0));
	}

	/*
	 * Advance to next arm of case
	 */
	i += 2;
	if (i > argc) {
	    return(TCL_SUBUSAGE);
	}
    }

    if (defaultIdx != 0) {
	/*
	 * Have a default case -- execute its body.
	 */
	return(Tcl_Eval(interp, argv[defaultIdx], 0, 0));
    } else {
	/*
	 * Nothing matched -- is ok.
	 */
	Tcl_Return(interp, NULL, TCL_STATIC);
	return(TCL_OK);
    }
}
    

/*
 *----------------------------------------------------------------------
 *
 * Tcl_CatchCmd --
 *
 *	This procedure is invoked to process the "catch" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

static const Tcl_SubCommandRec catchCmds[] = {
    {TCL_CMD_ANY, 0, 	    0, 1, "<command> [<varName>]"},
    {TCL_CMD_END}
};

DEFCMD(catch,Tcl_Catch,TCL_EXACT,catchCmds,swat_prog.tcl.error,
"Usage:\n\
    catch <command> [<varName>]\n\
\n\
Examples:\n\
    \"if {[catch {error-prone-command} result] == 0} {\n\
         # command was ok; use $result\n\
     }\"	    	    	    	Executes \"error-prone-command,\" placing the\n\
				result in $result, if the command completes\n\
				successfully.\n\
\n\
Synopsis:\n\
    Executes a command, retaining control even if the command generates an\n\
    error (which would otherwise cause execution to unwind completely).\n\
\n\
Notes:\n\
    * This returns an integer that indicates how <command> completed:\n\
	0   Completed successfully; $<varName> contains the result of the\n\
	    command.\n\
	1   Generated an error; $<varName> contains the error message.\n\
	2   Executed \"return\"; $<varName> contains the argument passed\n\
	    to \"return.\"\n\
	3   Executed \"break\"; $<varName> is empty.\n\
	4   Executed \"continue\"; $<varName> is empty.\n\
\n\
See also:\n\
    protect.\n\
")
{
    int result;

    result = Tcl_Eval(interp, argv[1], 0, (const char **) NULL);
    if (argc == 3) {
	Tcl_SetVar(interp, argv[2], interp->result, 0);
    }
    Tcl_RetPrintf(interp, "%d", result);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_ConcatCmd --
 *
 *	This procedure is invoked to process the "concat" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

static const Tcl_SubCommandRec concatCmds[] = {
    {TCL_CMD_ANY, 0, 	    0, TCL_CMD_NOCHECK, "<arg>+"},
    {TCL_CMD_END}
};

DEFCMD(concat,Tcl_Concat,TCL_EXACT,concatCmds,swat_prog.tcl.list|swat_prog.list|swat_prog.string,
"Usage:\n\
    concat <arg>+\n\
\n\
Examples:\n\
    \"concat $list1 $list2\"	Merges the lists in $list1 and $list2 into a\n\
				single list whose elements are the elements of\n\
				the two lists.\n\
\n\
Synopsis:\n\
    Concatenates multiple list arguments into a single list.\n\
\n\
Notes:\n\
    * There is a sometimes-subtle difference between this in the \"list\" command:\n\
      Given two lists, \"concat\" will form a list whose n elements are the\n\
      combined elements of the two component lists, while \"list\" will form a\n\
      list whose 2 elements are the two lists. For example,\n\
    	    concat a b {c d e} {f {g h}}\n\
      yields the list\n\
    	    a b c d e f {g h}\n\
\n\
See also:\n\
    list.\n\
")
{
    int totalSize, i, pmoved;
    register char *p;

    if (argc == 1) {
	return TCL_OK;
    }

    for (totalSize = 1, i = 1; i < argc; i++) {
	totalSize += strlen(argv[i]) + 1;
    }
    p = malloc((unsigned) totalSize);
    pmoved = 0;
    Tcl_Return(interp, p, TCL_DYNAMIC);
    for (i = 1; i < argc; i++) {
	int len;
	
	if (*argv[i] == 0) {
	    continue;
	}
	len = strlen(argv[i]);
	(void) bcopy(argv[i], p, len);
	p += len;
	*p = ' ';
	p++;
	pmoved = 1;
    }

    if (pmoved) {
	p[-1] = 0;
    } else {
	p[0] = 0;
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_ContinueCmd --
 *
 *	This procedure is invoked to process the "continue" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

static const Tcl_SubCommandRec continueCmds[] = {
    {TCL_CMD_END}	/* No args allowed */
};

DEFCMD(continue,Tcl_Continue,TCL_EXACT,continueCmds,swat_prog.tcl.loop,
"Usage:\n\
    continue\n\
\n\
Examples:\n\
    \"continue\"	    Return to the top of the enclosing loop.\n\
\n\
Synopsis:\n\
    Skips the rest of the commands in the current loop iteration, continuing\n\
    at the top of the loop again.\n\
\n\
Notes:\n\
    * Only the closest-enclosing loop can be continued via this command.\n\
\n\
    * The <next> clause of the \"for\" command is not part of the current\n\
      iteration, i.e. it will be executed even if you execute this command.\n\
\n\
See also:\n\
    break, for.\n\
")
{
    return TCL_CONTINUE;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_ErrorCmd --
 *
 *	This procedure is invoked to process the "error" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

static const Tcl_SubCommandRec errorCmds[] = {
    {TCL_CMD_ANY, 0, 	    0, 0, "<message>"},
    {TCL_CMD_END}
};

DEFCMD(error,Tcl_Error,TCL_EXACT,errorCmds,swat_prog.tcl.error,
"Usage:\n\
    error <message>\n\
\n\
Examples:\n\
    \"error {invalid argument}\"	    Generates an error, giving the not-so-\n\
				    helpful message \"invalid argument\" to\n\
				    the caller's caller.\n\
\n\
Synopsis:\n\
    Generates an error that forces execution to unwind all the way out of\n\
    the interpreter, or to the closest \"catch\" command, whichever comes\n\
    first.\n\
\n\
Notes:\n\
    * Unless one of the procedures in the call stack has executed a \"catch\"\n\
      command, all procedures on the stack will be terminated with <message>\n\
      (and an indication of an error) being the result of the final one so\n\
      terminated.\n\
\n\
    * Any commands protected by the \"protect\" command will be executed.\n\
\n\
See also:\n\
    return, catch.\n\
")
{
    Tcl_Return(interp, argv[1], TCL_VOLATILE);
    return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_EvalCmd --
 *
 *	This procedure is invoked to process the "eval" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

static const Tcl_SubCommandRec evalCmds[] = {
    {TCL_CMD_ANY, 0, 	    0, 0, "<body>"},
    {TCL_CMD_END}
};

DEFCMD(eval,Tcl_Eval,TCL_EXACT,evalCmds,swat_prog.tcl,
"Usage:\n\
    eval <body>\n\
\n\
Examples:\n\
    \"eval $mangled_command\"	Evaluate the command contained in\n\
				$mangled_command and return its result.\n\
\n\
Synopsis:\n\
    Evaluates the passed string as a command and returns the result of\n\
    that evaluation.\n\
\n\
Notes:\n\
    * This command is useful when one needs to cobble together a command\n\
      from arguments or what have you. For example, if one of your\n\
      arguments is a list of arguments to pass to another command, the\n\
      only way to accomplish that is to say something like \"eval [concat\n\
      random-command $args]\", which will form a list whose first element\n\
      is the command to be executed, and whose remaining elements are the\n\
      arguments for the command. \"eval\" will then execute that list properly.\n\
\n\
    * If the executed command generates an error, \"eval\" will propagate that\n\
      error just like any other command.\n\
\n\
See also:\n\
    concat, list.\n\
")
{
    int result;

    result = Tcl_Eval(interp, argv[1], 0, (const char **) NULL);
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_ExecCmd --
 *
 *	This procedure is invoked to process the "exec" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */


static const Tcl_SubCommandRec execCmds[] = {
    {TCL_CMD_ANY, 0, 	    0, TCL_CMD_NOCHECK, "<command> <args>*"},
    {TCL_CMD_END}
};

DEFCMD(exec,Tcl_Exec,TCL_EXACT,execCmds,swat_prog.tcl,
"Usage:\n\
    exec <command> <args>*\n\
\n\
Examples:\n\
    \"echo [exec ls -CF]\"	    Invoke the \"ls\" command in the current\n\
				    directory, passing it \"-CF\" as arguments.\n\
				    Echo the output when the command completes.\n\
    \"exec /bin/cat < {hi mom}\"	    Invoke \"/bin/cat\", passing it the string\n\
				    \"hi mom\" as its input.\n\
			    \n\
\n\
Synopsis:\n\
    Executes an external command, passing it arguments and input. All output\n\
    from the command is returned as a string.\n\
\n\
Notes:\n\
    * This is not supported under DOS yet.\n\
\n\
    * If one of the arguments is \"<\", neither it nor the following argument is\n\
      given to the command directly. Rather, the following argument is given to\n\
      the command as its standard input.\n\
\n\
    * The command returns the exit code for the program, if it's one of the\n\
      five known to Tcl (see the \"catch\" command for details). If the exit\n\
      code is non-zero and not one of the five, \"exec\" will generate an error.\n\
\n\
    * All output (both standard output and standard error) is returned as\n\
      the string result of this command.\n\
\n\
See also:\n\
    catch.\n\
")
{
/*    extern int ExecHandlerProc();	/* Declared below. XXX remove */
    char *input = "";		        /* Points to the input remaining to
					 * send to the child process. */
    int inputSize;	                /* Number of bytes left to send. */
    char *output = NULL;	        /* Output received from child. */
    long outputSize;			/* Number of valid bytes at output. */
    long outputSpace;			/* Total space available at output. */
    int result, i;
    int pid = 0;			/* 0 means child process doesn't
					 * exist (yet).  Non-zero gives its
					 * id. */
#if defined(unix)
    int stdIn[2], stdOut[2], count, deadPid, maxID;
    union wait status;
#endif
    char *cmdName;

    /*
     * Fetch and discard our name
     */
    cmdName = argv[0];
    argv += 1; argc -= 1;

    /*
     * Look through the arguments for a standard input specification
     * ("< value" in two arguments).  If found, collapse it out.
     */
    for (i = 0; i < argc; i++) {
	if ((argv[i][0] != '<') || (argv[i][1] != 0)) {
	    continue;
	}
	i++;
	if (i >= argc) {
	    Tcl_RetPrintf(interp,
			  "specified \"<\" but no input in \"%.50s\" command",
			  cmdName);
	    return TCL_ERROR;
	}
	/*
	 * Record input string and copy the rest of the args down over it.
	 */
	input = argv[i];
	for (i++; i <= argc; i++) {
	    argv[i-2] = argv[i];
	}
	/*
	 * Two fewer args in the array now that < and input are gone
	 */
	argc -= 2;
    }

    if (argc < 1) {
	Tcl_RetPrintf(interp, "not enough arguments to \"%.50s\" command",
		      cmdName);
	return TCL_ERROR;
    }

    inputSize = strlen(input);

    /*
     * Create pipes for standard input and standard output/error, and
     * start up the new process.
     */
#if defined(unix)
    stdIn[0] = stdIn[1] = stdOut[0] = stdOut[1] = -1;
    if ((pipe(stdIn) < 0) || (pipe(stdOut) < 0)) {
	Tcl_RetPrintf(interp, "couldn't create pipes for \"%.50s\" command",
		      cmdName);
	result = TCL_ERROR;
	goto cleanup;
    }

    maxID = stdIn[1];
    if (stdOut[0] > maxID) {
	maxID = stdOut[0];
    }
    pid = vfork();
    if (pid == -1) {
	Tcl_RetPrintf(interp, "couldn't fork child for \"%.50s\" command",
		      cmdName);
	result = TCL_ERROR;
	goto cleanup;
    }
    if (pid == 0) {
	char errSpace[100];

	if ((dup2(stdIn[0], 0) < 0) ||
	    (dup2(stdOut[1], 1) < 0) ||
	    (dup2(stdOut[1], 2) < 0))
	{
	    char *err;

	    err = "forked process couldn't set up input/output";
	    write(stdOut[1], err, strlen(err));
	    _exit(1);
	}

	/*
	 * Close down the pipes since we don't need them anymore.
	 */
	close(stdIn[0]); close(stdIn[1]);
	close(stdOut[0]); close(stdOut[1]);

	/*
	 * Try and execute the thing using the search path.
	 */
	execvp(argv[0], argv);
	sprintf(errSpace, "couldn't find a \"%.50s\" to execute", argv[0]);
	write(1, errSpace, strlen(errSpace));
	_exit(1);
    }

    /*
     * In the parent, funnel input and output to/from the process.
     */

    outputSize = 0;
    outputSpace = 0;
    if ((inputSize && (fcntl(stdIn[1], F_SETFL, FNDELAY) == -1)) ||
	(fcntl(stdOut[0], F_SETFL, FNDELAY) == -1))
    {
	Tcl_RetPrintf(interp,
		      "couldn't set up non-blocking I/O to/from child in \"%.50s\"",
		      cmdName);
	result = TCL_ERROR;
	goto cleanup;
    }

    /*
     * Child hasn't exited yet...
     */
    result = -1;

    /*
     * Close the ends of the pipes we don't use
     */
    close(stdIn[0]); close(stdOut[1]);

    if (inputSize == 0) {
	close(stdIn[1]);
	stdIn[1] = -1;
    }

    while (1) {
	fd_set readMask, writeMask;

	/*
	 * Wait for something more to happen.
	 */

	if (result != -1) {
	    pid = 0;
	    break;
	}

	do {
	    FD_ZERO(&readMask);
	    FD_ZERO(&writeMask);
	    FD_SET(stdOut[0], &readMask);
	    if (stdIn[1] >= 0) {
		FD_SET(stdIn[1], &writeMask);
	    }
	} while (select(maxID+1, &readMask, &writeMask, (int *) NULL,
			(struct timeval *)NULL) <= 0);

	/* 
	 * Pass input to the child.
	 */

	if (inputSize > 0) {
	    count = inputSize;
	    if (count > 4096) {
		count = 4096;
	    }
	    count = write(stdIn[1], input, count);
	    if (count < 0) {
		if (errno != EWOULDBLOCK) {
		    Tcl_RetPrintf(interp,
				  "error writing stdin during \"%.50s\"",
				  cmdName);
		    result = TCL_ERROR;
		    goto cleanup;
		}
	    } else {
		input += count;
		inputSize -= count;
	    }
	}
	if ((inputSize == 0) && (stdIn[1] >= 0)) {
	    /*
	     * Close the writing side of the input pipe and remember that
	     * it's closed.
	     */
	    close(stdIn[1]);
	    stdIn[1] = -1;
	}

	/*
	 * See if the child has completed.
	 */

	deadPid = wait3(&status, WNOHANG, (struct rusage *) 0);
	if (deadPid == pid) {
	    result = status.w_T.w_Retcode;
	}

	/*
	 * Check for output from the child.  Note that this will always
	 * be done once after the child has died, to collect any remaining
	 * output.  Repeatedly read output until there isn't any more to
	 * read.
	 */

	while (1) {
	    if ((outputSpace - outputSize) < 100) {
		if (outputSpace == 0) {
		    /*
		     * Allocate initial room
		     */
		    outputSpace = 200;
		    output = malloc((unsigned)outputSpace);
		} else {
		    /*
		     * Use the realloc function if we've already got stuff --
		     * may save a copy.
		     */
		    outputSpace *= 2;
		    output = (char *)realloc(output, outputSpace);
		}
	    }
	    /*
	     * Read as much as we can
	     */
	    count=read(stdOut[0], output+outputSize, outputSpace-outputSize-1);

	    if (count < 0) {
		if (errno == EWOULDBLOCK) {
		    break;
		}
		Tcl_RetPrintf(interp,
			      "error reading stdout during \"%.50s\"",
			      cmdName);
		result = TCL_ERROR;
		goto cleanup;
	    } else if (count == 0) {
		break;
	    } else {
		outputSize += count;
	    }
	}
    }
    output[outputSize] = 0;
    Tcl_Return(interp, output, TCL_DYNAMIC);

    cleanup:
    if (pid != 0) {
	kill(pid, SIGQUIT);
    }
    if (stdIn[1] != -1) {
	close(stdIn[1]);
    }
    if (stdOut[0] != -1) {
	close(stdOut[0]);
    }
    return result;
#elif defined(_MSDOS)	/* now for _MSDOS */
    {
# define STDIN  0
# define STDOUT 1
        char	*filename="        ";
       	int 	cpid;
       	int  	outfptr, oldstdout;
	int 	redirect = 0;
	FILE	*outfile;

	union REGS  	dos_regs;

# if defined(USE_SPAWNLP)
        char 	*cmd;
# endif

	/*
	 * spawn a process to execute the next command and wait for it to
	 * finish before continuing (unless we exec a command.com shell)
	 */
	
	if (strcmp(argv[0], "command.com") || argc > 2)
	{
	    strcpy(filename, "TMXXXXXX");
	    filename = mktemp(filename);
	    outfptr = open(filename, O_CREAT | O_RDWR, S_IREAD | S_IWRITE);
	    if (outfptr == -1)
    	    {
		Tcl_RetPrintf(interp,
			      "error %d reading file %s in \"exec\"",
			      errno, filename);
		result = TCL_ERROR;
		goto cleanup;
	    }
	    redirect = 1;
	    oldstdout = dup(STDOUT);	/* save old STDOUT descriptor */
	/* the redirected stdout will get inherited by the spawned
	 * process so everything it would normally send to stdout will
	 * go to our file, how convenient
	 */
	    dup2(outfptr, STDOUT);	  /* redirect STDOUT to our file */
	    close(outfptr);
	}
# if defined(USE_SPAWNLP)
	cp = cmd;
	while(*cp && !isspace(*cp++));
	/* if the command has arguments, then to get just the command
	 * overwrite the space with a null '\0'
	 */
	if (*cp)
    	{
	    --cp;
	    *cp++ = '\0';
    	}
# endif

	/* ok, before we spawn this sucker we are going to free up any
	 * conventional memory we can so that the spawned process has a
	 * hope in hell of running at all (am I starting to sound like
	 * adam or what...:)
	 */
	dos_regs.w.eax = 0x00002536;  /* minimize/maximize memory */
	dos_regs.w.ebx = 0x00000001; /* minimize conventional memory */
	dos_regs.w.ecx = 0x00000000; /* no extra memory pages */
	_intdos(&dos_regs, &dos_regs);

	cpid = spawnvpe(P_WAIT, argv[0], argv, NULL);

	/* now lets grab back that memory */
	dos_regs.w.eax = 0x00002536;  /* minimize/maximize memory */
	dos_regs.w.ebx = 0x00000003; /* maximize conventional memory */
	dos_regs.w.ecx = 0x00000000; /* take everything, leave nothing */
	_intdos(&dos_regs, &dos_regs);

	if (cpid == -1)
	{
	    Tcl_RetPrintf(interp,
			  "spawn failed with code %d during \"%.50s\"",
			   errno, cmdName);
		result = TCL_ERROR;
		goto cleanup;
	}

	if (!redirect)
	{
	    result = TCL_OK;
	    goto cleanup;
	}
	/* fixup the stdout */
	dup2(oldstdout, STDOUT);
	close(oldstdout);
	/* now get the size of the file (= size of output) */
	outfile = fopen(filename, "rb");
	outputSize = 0;
	if (outfile != (FILE *)NULL)
	{
	    char    *cp;

	    fseek(outfile, 0L, SEEK_END);
	    outputSize = ftell(outfile);
	    fseek(outfile, 0L, SEEK_SET);
	    output = malloc(outputSize);
	    outputSpace = fread(output, 1, outputSize, outfile);
	    if (outputSpace != outputSize)
	    {
		Tcl_RetPrintf(interp,
			      "error reading file during \"%.50s\"",
			      cmdName);
		result = TCL_ERROR;
		goto cleanup;
	    }
	    cp = output;
	    while (*cp)
	    {
		if (*cp == '\r')
		{   
		    *cp = ' ';
		}
		cp++;
	    }
	}
	else
	{
	    /* now the command might have had no output and ran fine
	     * so only bitch if the spawn returned a non-zero value
	     */
	    	if (cpid)
		{
		    Tcl_RetPrintf(interp,
	    		      "error opening file during \"%.50s\"",
			      cmdName);
		    result = TCL_ERROR;
		    goto cleanup;
		}
	}
	output[outputSize] = 0;
	result = TCL_OK;
    	Tcl_Return(interp, output, TCL_DYNAMIC);
cleanup:
	if (outfile != (FILE *)NULL)
	{
	    fclose(outfile);
	    unlink(filename);
	}
	return result;
    }
#elif defined(_WIN32)  /* ifdef(unix) ends the elif _MSDOS case */
    Tcl_RetPrintf(interp, "exec command not supported under _WIN32 yet");
    return TCL_ERROR;
#endif /* ifdef unix ends the elif _WIN32 case */
}


/*
 *----------------------------------------------------------------------
 *
 * Tcl_ExprCmd --
 *
 *	This procedure is invoked to process the "expr" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */


static const Tcl_SubCommandRec exprCmds[] = {
    {TCL_CMD_ANY, 0, 	    0, 1, "<expr> [float]"},
    {TCL_CMD_END}
};

DEFCMD(expr,Tcl_Expr,TCL_EXACT,exprCmds,tcl|swat_prog.tcl,
"Usage:\n\
    expr <expr> [float]\n\
\n\
Examples:\n\
    \"expr 36*25\"	    Multiplies 36 by 25 and returns the result.\n\
    \"expr $i/6 float\"	    Divides the number in $i by 6 using floating-\n\
			    point arithmetic; the result is a real number.\n\
\n\
Synopsis:\n\
    Evaluates an arithmetic expression and returns its value.\n\
\n\
Notes:\n\
    * Most C operators are supported with the standard operator precedence.\n\
\n\
    * If you use a Tcl variable in the expression, the variable may only contain\n\
      a number; it may not contain an expression.\n\
\n\
    * The result of any Tcl command, in []'s of course, must be a number; it\n\
      may not be an expression.\n\
\n\
    * All the C and Esp radix specifiers are allowed.\n\
\n\
    * Bitwise and boolean operators (!, &, ^, |, &&, ||, >>, <<, ~) are not\n\
      permitted when the expression is being evaluated using floating-point\n\
      arithmetic.\n\
\n\
    * Integers that are greater than 2^32-1 that are passed to expr with the\n\
      float argument must end with a .0 to force them into floating point \n\
      form if the code is going to be byte-compiled\n\
\n\
See also:\n\
    none.\n\
")
{
    int result;

    if (argc == 3 && strncmp(argv[2], "float", strlen(argv[2])) != 0) {
	return(TCL_SUBUSAGE);
    }

    if (argc == 2) {
	int value;
	result = Tcl_Expr(interp, argv[1], &value);
	if (result != TCL_OK) {
	    return result;
	}
	/*
	 * Turn the integer result back into a string.
	 */
	
	Tcl_RetPrintf(interp, "%d", value);
    } else {
	double value;
	result = Tcl_FExpr(interp, argv[1], &value);
	if (result != TCL_OK) {
	    return result;
	} else {
	    Tcl_RetPrintf(interp, "%.16g", value);
	}
    }

    return TCL_OK;
}

/***********************************************************************
 *				TclFileMatch
 ***********************************************************************
 * SYNOPSIS:	    Search for matches of a pattern in the filesystem.
 * CALLED BY:	    Tcl_FileCmd
 * RETURN:	    TCL_OK and (possibly empty) list of matches, or
 *	    	    TCL_ERROR (if can't open directory, e.g.)
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	This isn't a full file matcher -- it only expands in the last
 *	component, rather than all nested ones, as I'm too lazy for
 *	now and I mostly want this thing for filename completion anyway.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/14/89		Initial Revision
 *
 ***********************************************************************/
static int
TclFileMatch(Tcl_Interp	    *interp,
	     char   	    *file)
{
    DIR	    	    *dir;
    const struct direct *dp;
    char    	    **argv;
    int	    	    argc;
    int	    	    nargc;
    char    	    *pat;
    int	    	    plen;
#if defined(_MSDOS) || defined(_WIN32)
    char    	    *cp;
    int	    	    freePat = 0;
#endif

    argc = 0;
    nargc = 1;
    argv = (char **)malloc(nargc * sizeof(char *));

    pat = rindex(file, '/');
    if (pat++ == NULL) {
	/*
	 * No leading components -- open . and make "file" be the whole pattern
	 */
	pat = file;
	dir = opendir(".");
	file = ".";
	plen = 0;
    } else if (pat == file + 1) {
	/*
	 * Matching in /, but we just nuked the entire directory name,
	 * which was "/". Compensate for this by setting file to "/" now.
	 */
	file = "/";
	plen = 1;
	dir = opendir(file);
    } else {
	/*
	 * Null-terminate the leading components for the open of the directory,
	 * but replace the trailing / afterward so loop has a slash where
	 * it needs it. To aid this, we make sure plen includes the slash.
	 */
	pat[-1] = '\0';
	dir = opendir(file);
	pat[-1] = '/';
	plen = pat - file;
    }

    if (dir == NULL) {
	Tcl_Error(interp, "file match: Cannot open directory");
    }
    
#if defined(_MSDOS) || defined(_WIN32)
    /*
     * If the pattern contains lower-case letters, upcase them, as we'll only
     * get uppercase back from readdir().
     */
    for (cp = pat; *cp != '\0'; cp++) {
	if (islower(*cp)) {
	    break;
	}
    }
    if (*cp != '\0') {
	/*
	 * Found a lower-case letter, so we need to duplicate the pattern
	 * and upcase the lower-case letters.
	 */
	char	*newpat;
	
	newpat = (char *)malloc(strlen(pat)+1);

	cp = newpat;
	while (*pat != '\0') {
	    if (islower(*pat)) {
		*cp++ = toupper(*pat);
		pat += 1;
	    } else {
		*cp++ = *pat++;
	    }
	}
	*cp = '\0';
	pat = newpat;
	freePat = 1;
    }
#endif /* _MSDOS  || _WIN32 */

    while ((dp = readdir(dir)) != NULL) {

#ifndef _WIN32
	if (dp->d_ino == 0) {
	    /*
	     * Sun readdir doesn't filter out entries with inode 0 (which
	     * indicates a free entry), so we do it ourselves.
	     */
	    continue;
	}
#endif /* ends the ndef _WIN32 */

	if ((dp->d_name[0] == '.' || *pat == '.') &&
	    (dp->d_name[0] != *pat))
	{
	    /*
	     * If either the pattern or the current entry begins with a .,
	     * the other must also. This follows UNIX conventions whereby
	     * files with a leading . are hidden from normal operations
	     * unless explicitly asked for.
	     */
	    continue;
	}

	if (Tcl_StringMatch(dp->d_name, pat)) {
	    /*
	     * Another match. Make a copy of the name in the argv we're
	     * building.
	     */
	    if (argc == nargc) {
		nargc += 2;
		argv = (char **)realloc((malloc_t)argv,
					nargc * sizeof(char *));
	    }

#ifndef _WIN32
	    argv[argc] = (char *)malloc(plen + 1 + dp->d_namlen + 1);
#else   /* _WIN32 case */
	    argv[argc] = (char *)malloc(plen + 1 + strlen(dp->d_name) + 1);
#endif  /* ifndef _WIN32 */

	   sprintf(argv[argc], "%.*s%s", plen, file, dp->d_name);
	    argc++;
	}
    }

    /*
     * Done with the directory, since we hit EOF
     */
    closedir(dir);

#if defined(_MSDOS) || defined(_WIN32)
    if (freePat) {
	free(pat);
    }
#endif /* _MSDOS  || _WIN32 */

    /*
     * Merge the results into a list for return.
     */
    Tcl_Return(interp, Tcl_Merge(argc, argv), TCL_DYNAMIC);

    /*
     * Free up all strings allocated, as well as their vector.
     */
    while(argc-- > 0) {
	free(argv[argc]);
    }
    free((malloc_t)argv);

    return(TCL_OK);
}


/***********************************************************************
 *				ExpandTilde
 ***********************************************************************
 * SYNOPSIS:	    Subroutine to perform ~ expansion on a filename,
 *		    under UNIX anyway
 * CALLED BY:	    (INTERNAL) Tcl_FileCmd
 * RETURN:	    the expanded path, which might be in the passed
 *		    buffer.
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/30/93	Initial Revision
 *
 ***********************************************************************/
static char *
ExpandTilde(char *f,	    	/* Name to expand */
	    char *path)	    	/* Buffer in which to place stuff, if
				 * necessary */
{
    char *file;
    
#if defined(unix)

    char *p;

    /*
     * Perform tilde expansion on the file name first...
     */
    if (f[0] == '~') {
	/*
	 * See if it's our home directory or someone else's that's wanted.
	 */
	p = (char *)index(f, '/') ;
	if (p == NULL) {
	    p = f + strlen(f);
	}

	if (p > &f[2]) {
	    /*
	     * Someone else's -- we have to consult the system about it.
	     */
	    char	c;
	    struct passwd   *pwd;
	    
	    /*
	     * Trim it down to just the user name
	     */
	    c = *p;
	    *p = '\0';

	    /*
	     * Find the info for that user
	     */
	    pwd = getpwnam(&f[1]);
	    if (pwd != (struct passwd *)NULL) {
		/*
		 * Concatenate the home directory for the user with the rest
		 * of the file name. Note the trailing slash if the file is
		 * just ~user
		 */
		*p = c;
		sprintf(path, "%s%s", pwd->pw_dir, p);
		file = path;
	    } else {
		/*
		 * User unknown -- don't expand
		 */
		file = f;
	    }
	    *p = c;
	} else {
	    /*
	     * It's our home directory that's wanted -- try to use the HOME
	     * envariable.
	     */
	    char    *home = (char *)getenv("HOME");

	    if (home == (char *)NULL) {
		/*
		 * No such luck -- must ask the system about the info for our
		 * uid. Sigh.
		 */
		struct passwd	*pwd;

		pwd = getpwuid(getuid());
		if (pwd != (struct passwd *)NULL) {
		    /*
		     * Same note regarding trailing slash applies.
		      */
		    sprintf(path, "%s%s", pwd->pw_dir, p);
		    file = path;
		} else {
		    /*
		     * We don't exist!
		     */
		    file = f;
		}
	    } else {
		/*
		 * Good. Just use what's in $HOME.
		 */
		sprintf(path, "%s%s", home, p);
		file = path;
	    }
	}
    } else {
#endif    /* unix */
	/*
	 * No expansion needed
	 */
	file = f;
#if defined(unix)
    }
#endif

    return (file);
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_FileCmd --
 *
 *	This procedure is invoked to process the "file" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

#define FILE_DIRNAME	(ClientData)0
#define FILE_EXECUTABLE	(ClientData)1
#define FILE_EXISTS 	(ClientData)2
#define FILE_EXPAND 	(ClientData)3
#define FILE_EXTENSION	(ClientData)4
#define FILE_ISDIR  	(ClientData)5
#define FILE_ISFILE 	(ClientData)6
#define FILE_OWNED  	(ClientData)7
#define FILE_READABLE	(ClientData)8
#define FILE_ROOTNAME	(ClientData)9
#define FILE_TAIL   	(ClientData)10
#define FILE_WRITABLE	(ClientData)11
#define FILE_MATCH  	(ClientData)12
#define FILE_NEWER  	(ClientData)13
static const Tcl_SubCommandRec fileCmds[] = {
    {"dirname",	    FILE_DIRNAME,	1, 1, "<name>"},
#if !defined(_MSDOS)
    {"executable",  FILE_EXECUTABLE,	1, 1, "<name>"},
#endif
    {"exists",	    FILE_EXISTS,    	1, 1, "<name>"},
    {"expand",	    FILE_EXPAND,    	1, 1, "<name>"},
    {"extension",   FILE_EXTENSION, 	1, 1, "<name>"},
    {"isdirectory", FILE_ISDIR,	    	1, 1, "<name>"},
    {"isfile",	    FILE_ISFILE,    	1, 1, "<name>"},
#if !defined(_MSDOS)
    {"owned",	    FILE_OWNED,	    	1, 1, "<name>"},
#endif
    {"readable",    FILE_READABLE,  	1, 1, "<name>"},
    {"rootname",    FILE_ROOTNAME,  	1, 1, "<name>"},
    {"tail", 	    FILE_TAIL,	    	1, 1, "<name>"},
    {"writable",    FILE_WRITABLE,  	1, 1, "<name>"},
    {"match",	    FILE_MATCH,	    	1, 1, "<pattern>"},
    {"newer",	    FILE_NEWER,	    	2, 2, "<name1> <name2>"},
    {TCL_CMD_END}
};

DEFCMD(file,Tcl_File,TCL_EXACT,fileCmds,swat_prog.tcl,
"Usage:\n\
    file dirname <name>\n\
    file executable <name>\n\
    file exists <name>\n\
    file expand <name>\n\
    file extension <name>\n\
    file isdirectory <name>\n\
    file isfile <name>\n\
    file owned <name>\n\
    file readable <name>\n\
    file rootname <name>\n\
    file tail <name>\n\
    file writable <name>\n\
    file match <pattern>\n\
    file newer <name1> <name2>\n\
\n\
Examples:\n\
    \"file match /staff/pcgeos/a*\"	Looks for all files/directories in\n\
					/staff/pcgeos whose name begins with\n\
					a (or A in the DOS world...)\n\
    \"file isdir $path\"	    	    	See if the path stored in $path refers\n\
					to a directory.\n\
    \"file tail $path\"	    	    	Return the final component of the path\n\
					stored in $path\n\
    \"file owned $path\"	    	    	Return non-zero if the file/directory\n\
					with the given path is owned by the\n\
					current user.\n\
\n\
Synopsis:\n\
    Performs various checks and manipulations of file and directory names. NOTE:\n\
    even in the DOS world, the forward slash is the path separator for this\n\
    command.\n\
\n\
Notes:\n\
    * Some subcommands are inappropriate for the DOS version: executable,\n\
      expand, and owned are not implemented.\n\
\n\
    * The predicate subcommands (executable, exists, isdirectory, isfile,\n\
      owned, readable, and writable) all return 1 if the path meets the\n\
      requirements, or 0 if it doesn't.\n\
\n\
    * \"file match\" takes a <pattern> made from the same components as are\n\
      described for \"string match\". It is *not* the same as the standard DOS\n\
      wildcarding, where '.' serves to separate the root pattern from the\n\
      extension pattern. For this command \"*.*\" would match only files that\n\
      actually have an extension.\n\
\n\
    * \"file dirname\" returns the directory portion of <name>. If <name> has\n\
      no directory portion, this returns \".\"\n\
\n\
    * \"file expand\" expands any home-directory specification in <name> and\n\
      returns the result as an absolute path.\n\
\n\
    * \"file rootname\" returns all leading directory components of <name>, plus\n\
      the text before its extension, without the \".\" that separates the name\n\
      from the extension.\n\
\n\
    * \"file tail\" returns all of the characters in <name> after the final\n\
      forward slash, or <name> if it contains no forward slashes.\n\
\n\
    * \"file newer\" returns 1 if <name1> was modified after <name2>. It\n\
      returns 0 otherwise.\n\
\n\
See also:\n\
    string.\n\
")
{
    char *p;
    int mode;
    int statOp = 0;
#if defined(_MSDOS)
    struct _stat statBuf;
    char    path[66];
#else
    struct stat statBuf;
    char    path[1024];
#endif

    char    *file;
    

    mode = -1;

    file = ExpandTilde(argv[2], path);
		
    switch ((int)clientData) {
	case (int)FILE_EXPAND:
	    Tcl_Return(interp, file, TCL_VOLATILE);
	    return(TCL_OK);
	case (int)FILE_DIRNAME:
	    p = rindex(file, '/');
	    if (p == NULL) {
		Tcl_Return(interp, ".", TCL_STATIC);
	    } else if (p == file) {
		Tcl_Return(interp, "/", TCL_STATIC);
	    } else {
		*p = 0;
		Tcl_Return(interp, file, TCL_VOLATILE);
		*p = '/';
	    }
	    return TCL_OK;
	case (int)FILE_ROOTNAME:
	    p = rindex(file, '.');
	    if (p == NULL) {
		Tcl_Return(interp, file, TCL_VOLATILE);
	    } else {
		*p = 0;
		Tcl_Return(interp, file, TCL_VOLATILE);
		*p = '.';
	    }
	    return TCL_OK;
	case (int)FILE_EXTENSION:
	    p = rindex(file, '.');
	    if (p != NULL) {
		Tcl_Return(interp, p, TCL_VOLATILE);
	    }
	    return TCL_OK;
	case (int)FILE_TAIL:
	    p = rindex(file, '/');
	    if (p != NULL) {
		Tcl_Return(interp, p+1, TCL_VOLATILE);
	    } else {
		Tcl_Return(interp, file, TCL_VOLATILE);
	    }
	    return TCL_OK;
	case (int)FILE_MATCH:
	    return TclFileMatch(interp, file);
	case (int)FILE_READABLE:
	    mode = R_OK;
	    break;
	case (int)FILE_WRITABLE:
	    mode = W_OK;
	    break;
#if defined(unix)
	case (int)FILE_EXECUTABLE:
	    mode = X_OK;
	    break;
#endif
	case (int)FILE_EXISTS:
	    mode = F_OK;
	    break;
	case (int)FILE_OWNED:
	    statOp = 0;
	    break;
	case (int)FILE_ISFILE:
	    statOp = 1;
	    break;
	case (int)FILE_ISDIR:
	    statOp = 2;
	    break;
        case (int)FILE_NEWER:
	    statOp = 3;
	    break;
    }

    if (mode != -1) {
	/*
	 * User has requested a mode check -- perform it now.
	 */
	Tcl_Return(interp, (access(file, mode) == -1) ? "0" : "1", TCL_STATIC);
    } else {
	if (stat(file, &statBuf) == -1) {
	    if (statOp == 3) {
		/*
		 * When checking for newer, absence of either file is
		 * an error.
		 */
		Tcl_RetPrintf(interp, "\"%.50s\" does not exist", argv[2]);
		return TCL_ERROR;
	    }
	    Tcl_Return(interp, "0", TCL_STATIC);
	    return TCL_OK;
	}
	switch (statOp) {
#if defined(unix)
	    case 0:
		mode = (geteuid() == statBuf.st_uid);
		break;
#endif
	    case 1:
		mode = (statBuf.st_mode & S_IFMT) == S_IFREG;
		break;
	    case 2:
		mode = (statBuf.st_mode & S_IFMT) == S_IFDIR;
		break;
	    case 3:
	    {
		time_t	mtime = statBuf.st_mtime;

		file = ExpandTilde(argv[3], path);
		if (stat(file, &statBuf) == -1) {
		    Tcl_RetPrintf(interp, "\"%.50s\" does not exist",
				  argv[3]);
		    return TCL_ERROR;
		}
		mode = statBuf.st_mtime < mtime;
		break;
	    }
	}

	Tcl_Return(interp, mode ? "1" : "0", TCL_STATIC);
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_ForCmd --
 *
 *	This procedure is invoked to process the "for" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

static const Tcl_SubCommandRec forCmds[] = {
    {TCL_CMD_ANY, 0, 	    3, 3, "<start> <test> <next> <body>"},
    {TCL_CMD_END}
};


DEFCMD(for,Tcl_For,TCL_EXACT,forCmds,swat_prog.tcl.loop,
"Usage:\n\
    for <start> <test> <next> <body>\n\
\n\
Examples:\n\
    \"for {var i 0} {$i < 10} {var i [expr $i+1]} {echo $i}\"\n\
	    	    	    	    Prints the numbers from 0 to 9.\n\
\n\
Synopsis:\n\
    This is Tcl's main looping construct. It functions similarly to the \"for\"\n\
    in C.\n\
\n\
Notes:\n\
    * <start> is a Tcl command string (which may involve multiple commands\n\
      over multiple lines, if desired) that is executed once at the very\n\
      start of the loop. It is always executed. If it returns an error, or\n\
      contains a \"break\" command, no part of the loop will execute.\n\
\n\
    * <test> is an arithmetic expression that is passed to the \"expr\" command.\n\
      If the result is non-zero, the <body> is executed.\n\
\n\
    * <next> is a Tcl command string (which may involve multiple commands\n\
      over multiple lines, if desired) that is executed at the end of each\n\
      iteration before <test> is evaluated again. If it returns an error, or\n\
      contains a \"break\" command, no part of the loop will execute.\n\
\n\
    * You can exit the loop prematurely by executing the \"break\" command in\n\
      any of the three Tcl command strings (<start>, <next>, or <body>).\n\
\n\
    * So long as there's no error, \"for\" always returns the empty string as\n\
      its result.\n\
\n\
See also:\n\
    foreach, break, continue.\n\
")
{
    int result, value;

    result = Tcl_Eval(interp, argv[1], 0, (const char **) NULL);

    while (result == TCL_OK || result == TCL_CONTINUE) {
	result = Tcl_Expr(interp, argv[2], &value);
	if (result != TCL_OK) {
	    return result;
	}
	if (!value) {
	    break;
	}
	result = Tcl_Eval(interp, argv[4], 0, (const char **) NULL);
	if (result == TCL_OK || result == TCL_CONTINUE) {
	    result = Tcl_Eval(interp, argv[3], 0, (const char **) NULL);
	}
    }
    if (result == TCL_BREAK) {
	result = TCL_OK;
    }
    if (result == TCL_OK) {
	Tcl_Return(interp, (char *) NULL, TCL_STATIC);
    }
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_ForeachCmd --
 *
 *	This procedure is invoked to process the "foreach" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

static const Tcl_SubCommandRec foreachCmds[] = {
    {TCL_CMD_ANY, 0, 	    2, 2, "<varName> <list> <body>"},
    {TCL_CMD_END}
};


DEFCMD(foreach,Tcl_Foreach,TCL_EXACT,foreachCmds,swat_prog.tcl.loop,
"Usage:\n\
    foreach <varName> <list> <body>\n\
\n\
Examples:\n\
    \"foreach el $list {echo poof = $el}\"	Prints each element of the\n\
						list $list preceded by the\n\
						profound words \"poof = \"\n\
\n\
Synopsis:\n\
    This is a looping construct to easily iterate over all the elements of\n\
    a list.\n\
\n\
Notes:\n\
    * <body> is evaluated once for each element in <list>. Before each\n\
      evaluation, the next element is placed in the variable <varName>.\n\
\n\
    * You can exit the loop prematurely by executing the \"break\" command.\n\
\n\
    * As long as there's no error, \"foreach\" always returns the empty string.\n\
\n\
See also:\n\
    for, break, continue.\n\
")
{
    int listArgc, i, result;
    char **listArgv;

    /*
     * Break the list up into elements, and execute the command once
     * for each value of the element.
     */

    result = Tcl_SplitList(interp, argv[2], &listArgc, &listArgv);
    if (result != TCL_OK) {
	return result;
    }
    for (i = 0; i < listArgc; i++) {
	Tcl_SetVar(interp, argv[1], listArgv[i], 0);

	result = Tcl_Eval(interp, argv[3], 0, (const char **) NULL);
	if (result != TCL_OK) {
	    if (result == TCL_CONTINUE) {
		result = TCL_OK;
	    } else if (result == TCL_BREAK) {
		result = TCL_OK;
		break;
	    } else {
		break;
	    }
	}
    }
    free((char *) listArgv);
    if (result == TCL_OK) {
	Tcl_Return(interp, (char *) NULL, TCL_STATIC);
    }
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_FormatCmd --
 *
 *	This procedure is invoked to process the "format" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */
static const Tcl_SubCommandRec formatCmds[] = {
    {TCL_CMD_ANY, 0, 	    0, TCL_CMD_NOCHECK, "<format> <args>*"},
    {TCL_CMD_END}
};


DEFCMD(format,Tcl_Format,TCL_EXACT,formatCmds,swat_prog.tcl|tcl,
"Much like the C function sprintf(3) (type \"man 3 sprintf\" from the shell for\n\
more information). The only difference is that %c takes a decimal number that\n\
is the ASCII code for a character and produces the proper character. Other\n\
arguments are converted into the proper C data type before being passed to\n\
sprintf for formatting. This can be used to convert numbers to hex or octal.")
{
    register char *format;	/* Used to read characters from the format
				 * string. */
    char newFormat[40];		/* A new format specifier is generated here. */
    int width;			/* Field width from field specifier, or 0 if
				 * no width given. */
    int precision;		/* Field precision from field specifier, or 0
				 * if no precision given. */
    int size;			/* Number of bytes needed for result of
				 * conversion, based on type of conversion
				 * ("e", "s", etc.) and width from above. */
    char *oneWordValue = NULL;	/* Used to hold value to pass to sprintf, if
				 * it's a one-word value. */
    double twoWordValue;	/* Used to hold value to pass to sprintf if
				 * it's a two-word value. */
    int useTwoWords;		/* 0 means use oneWordValue, 1 means use
				 * twoWordValue. */
    char *dst;			/* Where result is stored.  Starts off at
				 * interp->resultSpace, but may get dynamically
				 * re-allocated if this isn't enough. */
    int dstSize = 0;		/* Number of non-null characters currently
				 * stored at dst. */
    int dstSpace = TCL_RESULT_SIZE;
				/* Total amount of storage space available
				 * in dst (not including null terminator. */
    int noPercent;		/* Special case for speed:  indicates there's
				 * no field specifier, just a string to copy. */
    char **curArg;		/* Remainder of argv array. */

    /*
     * Make sure pointing at resultSpace
     */
    Tcl_Return(interp, NULL, TCL_STATIC);
    dst = (char *)interp->result;

    /*
     * This procedure is a bit nasty.  The goal is to use sprintf to
     * do most of the dirty work.  There are several problems:
     * 1. this procedure can't trust its arguments.
     * 2. we must be able to provide a large enough result area to hold
     *    whatever's generated.  This is hard to estimate.
     * 3. there's no way to move the arguments from argv to the call
     *    to sprintf in a reasonable way.  This is particularly nasty
     *    because some of the arguments may be two-word values (doubles).
     * So, what happens here is to scan the format string one % group
     * at a time, making many individual calls to sprintf.
     */

    curArg = argv+2;
    argc -= 2;
    for (format = argv[1]; *format != 0; ) {
	register char *newPtr = newFormat;

	width = precision = useTwoWords = noPercent = 0;

	/*
	 * Get rid of any characters before the next field specifier.
	 * Collapse backslash sequences found along the way.
	 */

	if (*format != '%') {
	    int bsSize;

	    oneWordValue = newFormat;
	    while ((*format != '%') && (*format != 0) &&
		   newPtr < &newFormat[sizeof(newFormat)])
	    {
		if (*format == '\\') {
		    *newPtr++ = Tcl_Backslash(format, &bsSize);
		    format += bsSize;
		} else {
		    *newPtr++ = *format++;
		}
	    }
	    size = newPtr - newFormat;
	    noPercent = 1;
	    goto doField;
	}

	if (format[1] == '%') {
	    oneWordValue = format;
	    format += 2;
	    size = 1;
	    noPercent = 1;
	    goto doField;
	}

	/*
	 * Parse off a field specifier, compute how many characters
	 * will be needed to store the result, and substitute for
	 * "*" size specifiers.
	 */

	*newPtr = '%';
	newPtr++;
	format++;
	if (*format == '-') {
	    *newPtr = '-';
	    newPtr++;
	    format++;
	}
	if (*format == '0') {
	    *newPtr = '0';
	    newPtr++;
	    format++;
	}
	if (isdigit(*format)) {
	    width = atoi(format);
	    do {
		format++;
	    } while (isdigit(*format));
	} else if (*format == '*') {
	    if (argc <= 0) {
		goto notEnoughArgs;
	    }
	    width = TclExprGetNum(*curArg, NULL);
	    argc--;
	    curArg++;
	    format++;
	}
	if (width != 0) {
	    sprintf(newPtr, "%d", width);
	    while (*newPtr != 0) {
		newPtr++;
	    }
	}
	if (*format == '.') {
	    *newPtr = '.';
	    newPtr++;
	    format++;
	}
	if (isdigit(*format)) {
	    precision = atoi(format);
	    do {
		format++;
	    } while (isdigit(*format));
	} else if (*format == '*') {
	    if (argc <= 0) {
		goto notEnoughArgs;
	    }
	    precision = atoi(*curArg);
	    argc--;
	    curArg++;
	    format++;
	}
	if (precision != 0) {
	    sprintf(newPtr, "%d", precision);
	    while (*newPtr != 0) {
		newPtr++;
	    }
	}
	if (*format == '#') {
	    *newPtr = '#';
	    newPtr++;
	    format++;
	}
	if (*format == 'l') {
	    format++;
	}
	*newPtr = *format;
	newPtr++;
	*newPtr = 0;
	if (argc <= 0) {
	    goto notEnoughArgs;
	}
	switch (*format) {
	    case 'D':
	    case 'd':
	    case 'O':
	    case 'o':
	    case 'X':
	    case 'x':
	    case 'U':
	    case 'u':
	    {
		char *end;
		
		oneWordValue = (char *)TclExprGetNum(*curArg, 
						     (const char **)&end);
		
		if (end == *curArg) {
		    Tcl_RetPrintf(interp,
				  "expected integer but got \"%.50s\" instead",
				  *curArg);
		    goto fmtError;
		}
		size = 40;
		break;
	    }
	    case 's':
		oneWordValue = *curArg;
		size = strlen(*curArg);
		break;
	    case 'c':
	    {
		char *end;
		
		oneWordValue = (void *)TclExprGetNum(*curArg,
						     (const char **)&end);
		
		if (end == *curArg) {
		    Tcl_RetPrintf(interp,
				  "expected integer but got \"%.50s\" instead",
				  *curArg);
		    goto fmtError;
		}
		size = 1;
		break;
	    }
	    case 'F':
	    case 'f':
	    case 'E':
	    case 'e':
	    case 'G':
	    case 'g':
		if (sscanf(*curArg, "%lf", &twoWordValue) != 1) {
		    Tcl_RetPrintf(interp,
				  "expected floating-point number but got \"%.50s\" instead",
				  *curArg);
		    goto fmtError;
		}
		useTwoWords = 1;
		size = 320;
		if (precision > 10) {
		    size += precision;
		}
		break;
	    case 0:
		Tcl_Return(interp,
			   "format string ended in middle of field specifier",
			   TCL_STATIC);
		goto fmtError;
	    default:
		Tcl_RetPrintf(interp, "bad field specifier \"%c\"", *format);
		goto fmtError;
	}
	argc--;
	curArg++;
	format++;

	/*
	 * Make sure that there's enough space to hold the formatted
	 * result, then format it.
	 */

	doField:
	if (width > size) {
	    size = width;
	}
	if ((dstSize + size) > dstSpace) {
	    char *newDst;
	    int newSpace;

	    newSpace = 2*(dstSize + size);
	    if (dst == (char *)interp->result) {
		newDst = (char *) malloc((unsigned) newSpace+1);
		if (dstSize != 0) {
		    bcopy(dst, newDst, dstSize);
		}
	    } else {
		newDst = (char *)realloc(dst, (unsigned)newSpace+1);
	    }
	    dst = newDst;
	    dstSpace = newSpace;
	}
	if (noPercent) {
	    bcopy(oneWordValue, dst+dstSize, size);
	    dstSize += size;
	    dst[dstSize] = 0;
	} else {
	    if (useTwoWords) {
		sprintf(dst+dstSize, newFormat, twoWordValue);
	    } else {
		sprintf(dst+dstSize, newFormat, oneWordValue);
	    }
	    dstSize += strlen(dst+dstSize);
	}
    }

    if (interp->result != (const char *)dst) {
	Tcl_Return(interp, dst, TCL_DYNAMIC);
    }
    return TCL_OK;

    notEnoughArgs:
    Tcl_RetPrintf(interp,
		  "invoked \"%.50s\" without enough arguments", argv[0]);
    fmtError:
    if (dstSpace != TCL_RESULT_SIZE) {
	free(dst);
    }
    return TCL_ERROR;
}

#if defined(_WIN32)
extern void SendToEmacs(char *msg);

static const Tcl_SubCommandRec elispSendCmds[] = {
    {TCL_CMD_ANY, 0, 	    0, 0, "<body>"},
    {TCL_CMD_END}
};

DEFCMD(elispSend,Tcl_ElispSend,TCL_EXACT,elispSendCmds,swat_prog.tcl, 
"Great help here")
{
    SendToEmacs(argv[1]);
    return TCL_OK;
}
#endif
