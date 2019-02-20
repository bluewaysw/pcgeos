/*
 * tcl.c --
 *
 *	Test driver for TCL.
 *
 * Copyright 1987 Regents of the University of California
 * All rights reserved.
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appear in all copies.  The University of California
 * makes no representations about the suitability of this
 * software for any purpose.  It is provided "as is" without
 * express or implied warranty.
 */

#ifndef lint
static char rcsid[] = "$Id: tcl.c,v 1.9 97/04/18 12:14:33 dbaumann Exp $ SPRITE (Berkeley)";
#endif not lint

#include <config.h>
#include <compat/string.h>
#include <compat/stdlib.h>

#if defined(_MSDOS) || defined(_WIN32) || defined(_LINUX)
# include <stdio.h>
# include <time.h>
#else  /* not (_MSDOS or _WIN32) */
# include <sys/time.h>
#endif

#include <ctype.h>
#include "setjmp.h"
#include <malloc.h>
#include "tcl.h"

Tcl_Interp *interp;
/*
 * Data for a procedure being debugged
 */
typedef struct {
    int	    	  (*cmdProc)();
    ClientData	  clientData;
    void    	  (*deleteProc)();
} DebugData;

typedef struct _Frame {
    int	    	  (*cmdProc)();
    int	    	  level;
    int	    	  stopOnReturn;
    ClientData	  clientData;
    int	    	  argc;
    char    	  **argv;
    struct _Frame *next;
} Frame;

Frame	    *stack = (Frame *)NULL;
int	    stepping = 0;
int	    skipCalls = 0;
int	    numDebug = 0;
Tcl_Trace   debugTrace;

jmp_buf	    abortBuf;

int
cmdUndebug(ClientData	  	clientData,
	   Tcl_Interp	  	*interp,
	   int	    	  	argc,
	   char    	  	**argv);

void
debugClean(DebugData *dd)
{
    free((char *)dd);

    numDebug--;

    if (numDebug == 0) {
	Tcl_DeleteTrace(interp, debugTrace);
	debugTrace = NULL;
    }
}

int
debugCatch(DebugData *dd,
	   Tcl_Interp interp,
	   int argc,
	   char **argv)
{
    return ((* dd->cmdProc) (dd->clientData, interp, argc, argv));
}

void
debugFrame(Frame *f, int abbrev)
{
    int	    	  i;

    printf("%c [%s", f->stopOnReturn ? 'b' : ' ', f->argv[0]);

    for (i = 1; i < f->argc; i++) {
	int 	  j;
	char 	  *cp;

	for (cp = f->argv[i]; *cp; cp++) {
	    if (isspace(*cp)) {
		break;
	    }
	}

	if (*cp || cp == f->argv[i]) {
	    printf(" {");
	    for (j = 0, cp = f->argv[i]; (!abbrev || j < 10) && *cp; cp++,j++){
		if (*cp == '\n') {
		    printf("\\n");
		    j -= 2;
		} else if (*cp == '\t') {
		    printf("\\t");
		    j -= 2;
		} else {
		    putchar(*cp);
		}
	    }
	    if (*cp) {
		printf("...}");
	    } else {
		printf("}");
	    }
	} else {
	    printf(" %s", f->argv[i]);
	}
    }
    printf("]\n");
}

void
doDebug(void)
{
    while(1) {
	char	  cmd[1000], *p;
	int 	  i, result;

	clearerr(stdin);

	printf("[tcl] ");
	fflush(stdout);

	gets(cmd);
	p = index(cmd, ' ');
	if (p == (char *)NULL) {
	    p = cmd + strlen(cmd);
	}
	i = p - cmd;

	if (strncmp(cmd, "step", i) == 0) {
	    stepping = 1;
	    skipCalls = 0;
	    break;
	} else if (strncmp(cmd, "cont", i) == 0) {
	    stepping = 0;
	    skipCalls = 0;
	    break;
	} else if (strncmp(cmd, "eval", i) == 0) {
	    char	*oldResult;
	    int	result;

	    stepping = skipCalls = 0;
	    oldResult = malloc(strlen(interp->result) + 1);
	    strcpy(oldResult, interp->result);

	    result = Tcl_Eval(interp, p, 0, 0);
	    if (result == TCL_OK) {
		if (*interp->result != 0) {
		    printf("%s\n", interp->result);
		}
	    } else {
		if (result == TCL_ERROR) {
		    printf("Error");
		} else {
		    printf("Returned code %d", result);
		}
		if (*interp->result != 0) {
		    printf(": %s\n", interp->result);
		} else {
		    printf("\n");
		}
	    }
	    Tcl_Return(interp, oldResult, TCL_DYNAMIC);
	} else if (strncmp(cmd, "next", i) == 0) {
	    stepping = 0; skipCalls = 1;
	    break;
	} else if (strncmp(cmd, "where", i) == 0) {
	    Frame	*f;

	    for (f = stack; f != (Frame *)NULL; f = f->next) {
		debugFrame(f, 1);
	    }
	} else if (strncmp(cmd, "frame", i) == 0) {
	    debugFrame(stack, 0);
	} else if (strncmp(cmd, "quit", i) == 0) {
	    Frame *f;

	    skipCalls = 1;
	    stepping = 0;
	    for (f = stack; f != (Frame *)NULL; f = f->next) {
		f->stopOnReturn = 0;
	    }
	    break;
	} else if (strncmp(cmd, "abort", i) == 0) {
	    Frame *f;

	    while(stack) {
		f = stack->next;
		free((char *)stack);
		stack = f;
	    }
	    stepping = 0;
	    skipCalls = 0;
	    Tcl_TopLevel(interp);
	    longjmp(abortBuf, 1);
	} else if (strncmp(cmd, "undebug", i) == 0) {
	    char  *argv[3];

	    argv[0] = "undebug";
	    argv[1] = stack->argv[0];
	    argv[2] = NULL;

	    cmdUndebug(NULL, interp, 2, argv);
	} else if (strncmp(cmd, "help", i) == 0) {
	    printf("Available commands:\n");
	    printf("\ts[tep]    - Step to next tcl call\n");
	    printf("\tn[ext]    - Finish current call, ignoring nested calls\n");
	    printf("\t            and breakpoints\n");
	    printf("\tc[ont]    - Finish current call, but stop at any breakpoints\n");
	    printf("\tw[here]   - Print current call stack\n");
	    printf("\th[elp]    - Get this message\n");
	    printf("\tf[rame]   - Print current frame in long form\n");
	    printf("\te[val]    - Evaluate command in interpreter. Stops at any\n");
	    printf("\t            breakpoints you've set.\n");
	    printf("\tq[uit]    - Get back to top level, finishing out all\n");
	    printf("\t            current frames without stopping.\n");
	    printf("\ta[bort]   - Get back to top level without finishing\n");
	    printf("\t            current calls\n");
	    printf("\tu[ndebug] - Remove a breakpoint from the current frame\n");
	} else {
	    printf("Unknown command: %.*s\n", i, cmd);
	}
    }
}

void
debugCallProc(ClientData  cd,
	      Tcl_Interp  *interp,
	      int	  level,
	      char	  *command,
	      int	  (*cmdProc)(),
	      ClientData  cmdData,
	      int	  argc,
	      char	  **argv)
{
    Frame	  *top;

    top = (Frame *)malloc(sizeof(Frame));
    top->cmdProc = cmdProc;
    top->clientData = cmdData;
    top->argc = argc;
    top->argv = argv;
    top->next = stack;
    top->level = level;
    top->stopOnReturn = 0;
    stack = top;

    if (((cmdProc == debugCatch) && !skipCalls) || stepping) {
	/*
	 * Either we hit a function being debugged and weren't told
	 * to skip over calls, or we're single stepping, so we decide
	 * to stop and wait for further orders.
	 */
	printf("stopped in %s\n", argv[0]);

	stack->stopOnReturn = 1;
	debugFrame(stack, 1);

	doDebug();
    }
}

void
debugReturnProc(ClientData	cd,
		Tcl_Interp	*interp,
		int		level,
		char		*command,
		int		(*cmdProc)(),
		ClientData	cmdData,
		int		result)
{
    Frame	  *top;

    /*
     * We'll get called on the return from cmdDebug, but we won't have a
     * stack set up at that point, so we still need to check to make sure
     * we actually have a stack at this point.
     */
    if (stack) {
	if (stack->stopOnReturn) {
	    printf("%s returning ", stack->argv[0]);
	    switch(result) {
	    case TCL_OK:
		printf("\"%s\"\n", interp->result);
		break;
	    case TCL_ERROR:
		printf("error \"%s\"\n", interp->result);
		break;
	    case TCL_BREAK:
		printf("break\n");
		break;
	    case TCL_CONTINUE:
		printf("continue\n");
		break;
	    default:
		printf("code %d \"%s\"\n", result, interp->result);
		break;
	    }

	    doDebug();
	}

	top = stack->next;
	free((char *)stack);
	stack = top;
	if (stack == (Frame *)NULL) {
	    skipCalls = 0;
	}
    }
}

int
cmdDebug(ClientData	  	clientData,
	 Tcl_Interp	  	*interp,
	 int	    	  	argc,
	 char    	  	**argv)
{
#if 0
    int	    	  	i;
    DebugData	  	*dd;

    for (i = 1; i < argc; i++) {
	dd = (DebugData *)malloc(sizeof(DebugData));
	const char *realName;

	if (!Tcl_FetchCommand(interp, argv[i], &realName,
			      &dd->cmdProc, &dd->clientData,
			      &dd->deleteProc))
	{
	    Tcl_RetPrintf(interp, "%s: not defined", argv[i]);
	    return(TCL_ERROR);
	}

	if (dd->cmdProc == debugCatch) {
	    printf("%s: already being debugged\n", argv[i]);
	} else {
	    Tcl_OverrideCommand(interp, realName,
				debugCatch, (ClientData)dd, debugClean,
				&dd->cmdProc, &dd->clientData,
				&dd->deleteProc);
	    numDebug++;
	}
    }

    if (debugTrace == (Tcl_Trace)NULL) {
	debugTrace = Tcl_CreateTrace(interp, 0, debugCallProc, debugReturnProc,
				     (ClientData)NULL);
    }
#endif
    return(TCL_OK);
}

int
cmdUndebug(ClientData	  	clientData,
	   Tcl_Interp	  	*interp,
	   int	    	  	argc,
	   char    	  	**argv)
{
#if 0
    int	    	  	i;

    for (i = 1; i < argc; i++) {
	int 	  	(*cmdProc)();
	ClientData	clientData;
	void		(*deleteProc)();
	DebugData 	*dd;
	const char  	*realName;

	if (!Tcl_FetchCommand(interp, argv[i], &realName,
			      &cmdProc, &clientData,
			      &deleteProc))
	{
	    Tcl_RetPrintf(interp, "%s: not defined", argv[i]);
	    return(TCL_ERROR);
	}

	if (cmdProc != debugCatch) {
	    printf("%s: not being debugged\n", argv[i]);
	} else {
	    dd = (DebugData *)clientData;

	    Tcl_OverrideCommand(interp, realName,
				dd->cmdProc, dd->clientData, dd->deleteProc,
				&cmdProc, &clientData, &deleteProc);
	    debugClean(dd);
	}
    }
#endif
    return(TCL_OK);
}

int
cmdEcho(ClientData clientData,
	Tcl_Interp *interp,
	int argc,
	char **argv)
{
    int i;

    for (i = 1; ; i++) {
	if (argv[i] == NULL) {
	    if (i != argc) {
	    echoError:
		Tcl_RetPrintf(interp,
		    "argument list wasn't properly NULL-terminated in \"%s\" command",
		    argv[0]);
	    }
	    break;
	}
	if (i >= argc) {
	    goto echoError;
	}
	fputs(argv[i], stdout);
	if (i < (argc-1)) {
	    printf(" ");
	}
    }
    printf("\n");
    return TCL_OK;
}

void
deleteProc(ClientData clientData)
{
    printf("Deleting command with clientData \"%s\".\n", clientData);
}

int
cmdDelete(ClientData clientData,
	  Tcl_Interp *interp,
	  int argc,
	  char **argv)
{
    if (argc != 2) {
	interp->result = "syntax: delete command";
	return TCL_ERROR;
    }

    if (strcmp(argv[1], "*") == 0) {
	Tcl_DeleteInterp(interp);
    } else {
	Tcl_DeleteCommand(interp, argv[1]);
    }
    return TCL_OK;
}

void
traceCallProc(ClientData clientData,
	      Tcl_Interp *interp,
              Tcl_Frame *frame)
{
    int i;

    printf("Level %d, clientData 0x%x, interp 0x%x, calling \"%s\"\n",
	   frame->level, clientData, interp, frame->command);
    printf("    cmdProc 0x%x, cmdClientData 0x%x\n",
	   frame->cmdProc, frame->cmdData);
    for (i = 0; i < frame->argc; i++) {
	printf("        argv[%d] = \"%s\"\n", i, frame->argv[i]);
    }

}

void
traceReturnProc(ClientData clientData,
		Tcl_Interp *interp,
                Tcl_Frame *frame,
		int result)
{
    switch (result) {
    case TCL_OK:
	printf ("%s returns \"%s\"\n", frame->command, interp->result);
	break;
    case TCL_ERROR:
	printf("%s returns error \"%s\"\n", frame->command, interp->result);
	break;
    case TCL_BREAK:
	printf("%s returns BREAK\n", frame->command);
	break;
    case TCL_CONTINUE:
	printf("%s returns CONTINUE\n", frame->command);
	break;
    }
}

int
cmdTrace(ClientData clientData,		/* Not used. */
	 Tcl_Interp *interp,
	 int argc,
	 char *argv[])
{
    int length, level;
    Tcl_Trace trace;

    if (argc != 3) {
	interp->result = "wrong # args: should be \"trace create|delete arg\"";
	return TCL_ERROR;
    }
    if (strcmp(argv[1], "create") == 0) {
	if (sscanf(argv[2], "%d", &level) != 1) {
	    interp->result = "bad arg to \"trace create\"";
	    return TCL_ERROR;
	}

	printf("New trace is 0x%x\n",
		Tcl_CreateTrace(interp, level, traceCallProc,
				traceReturnProc, (ClientData) 47));
	return TCL_OK;
    } else if (strcmp(argv[1], "delete") == 0) {
	if (sscanf(argv[2], "%x", &trace) != 1) {
	    interp->result = "bad arg to \"trace delete\"";
	    return TCL_ERROR;
	}
	Tcl_DeleteTrace(interp, trace);
	return TCL_OK;
    }
    Tcl_RetPrintf(interp, "bad option (%s) to \"trace\": must be create or delete", argv[1]);
    return TCL_ERROR;
}

void
main(void)
{
    char cmd[1000], *p;
    register char *p2;
    int c, i, result;
    extern void exit();

    interp = Tcl_CreateInterp();
    Tcl_CreateCommand(interp, "echo", cmdEcho, 0, (ClientData) "echo",
		      deleteProc);
    Tcl_CreateCommand(interp, "delete", cmdDelete, 0, (ClientData) "delete",
		      deleteProc);
    Tcl_CreateCommand(interp, "trace", cmdTrace, 0, (ClientData) "trace",
		      deleteProc);
    Tcl_CreateCommand(interp, "exit", (Tcl_CmdProc *)exit, 0, (ClientData)0,
		      NoDelProc);
    Tcl_CreateCommand(interp, "debug", cmdDebug, 0, (ClientData)0, NoDelProc);
    Tcl_CreateCommand(interp, "undebug", cmdUndebug, 0, (ClientData)0,
		      NoDelProc);

    Tcl_SetVar(interp, "prompt", "% ", 1);

    (void)setjmp(abortBuf);

    while (1) {
	const char  *prompt = Tcl_GetVar(interp, "prompt", 1);

	clearerr(stdin);
	fputs(prompt, stdout);
	fflush(stdout);
	p = cmd;
	while (1) {
	    c = getchar();
	    if (c == EOF) {
		if (p == cmd) {
		    exit(0);
		}
		goto gotCommand;
	    }
	    *p = c;
	    p++;
	    if (c == '\n') {
		register char *p2;
		int parens, brackets, numBytes;

		for (p2 = cmd, parens = 0, brackets = 0; p2 != p; p2++) {
		    switch (*p2) {
			case '\\':
			    Tcl_Backslash(p2, &numBytes);
			    p2 += numBytes-1;
			    break;
			case '{':
			    parens++;
			    break;
			case '}':
			    parens--;
			    break;
			case '[':
			    brackets++;
			    break;
			case ']':
			    brackets--;
			    break;
		    }
		}
		if ((parens <= 0) && (brackets <= 0)) {
		    goto gotCommand;
		}
	    }
	}
	gotCommand:
	*p = 0;

	result = Tcl_Eval(interp, cmd, 0, &p);
	if (result == TCL_OK) {
	    if (*interp->result != 0) {
		printf("%s\n", interp->result);
	    }
	} else if ((result == TCL_ERROR) &&
		   strncmp(interp->result, "invoked",
			   sizeof("invoked") - 1) == 0)
	{
	    char  *newCmd;

	    newCmd = malloc(strlen("exec ") + strlen(cmd) + 1);

	    sprintf(newCmd, "exec %s", cmd);
	    result = Tcl_Eval(interp, newCmd, 0, (char **)NULL);
	    if (result == TCL_ERROR) {
		printf("Error ");
	    }
	    if (interp->result[0] != '\0') {
		printf("%s\n", interp->result);
	    }
	    free(newCmd);
	} else {
	    if (result == TCL_ERROR) {
		printf("Error");
	    } else {
		printf("Returned code %d", result);
	    }
	    if (*interp->result != 0) {
		printf(": %s\n", interp->result);
	    } else {
		printf("\n");
	    }
	}
    }
}
