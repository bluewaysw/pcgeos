/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  TCL -- Shell script manager
 * FILE:	  tsh.c
 *
 * AUTHOR:  	  Adam de Boor: May  1, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	echo	    	    Print strings to stdout
 *	stream	    	    access files and other streams
 *	exit	    	    go away
 *	system	    	    Execute a command giving it the tty
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/ 1/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Simple TCL shell mostly for scripts.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: tsh.c,v 1.6 96/06/13 17:23:22 dbaumann Exp $";
#endif lint

#include <config.h>
#include <stdio.h>
#include <sys/time.h>
#include <compat/string.h>
#include <ctype.h>
#include "setjmp.h"

#include "tcl.h"

#include <malloc.h>
#include <compat/file.h>

#if defined(unix)
#include <sys/file.h>
#elif defined(__HIGHC__)
#include <io.h>

#define L_SET SEEK_SET
#define L_XTND SEEK_END
#define L_INCR SEEK_CUR

void *idfile;			/* deal with printf in utils*/

#endif

Tcl_Interp *interp;

jmp_buf	    abortBuf;

unsigned malloc_tag(malloc_t foo) {return (0);}

/***********************************************************************
 *				cmdStream
 ***********************************************************************
 * SYNOPSIS:	    Stream I/O command
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    a stream may be opened or closed, etc.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 1/89		Initial Revision
 *
 ***********************************************************************/
cmdStream(ClientData	junk,
	  Tcl_Interp	*interp,
	  int	    	argc,
	  char	    	**argv)
{
    FILE    *stream;
    int	    len;

    if (argc < 3) {
stream_usage:
	Tcl_Error(interp, "Usage: stream (open|read|print|write|rewind|seek|state|eof|close|flush) ...");
    }

    len = strlen(argv[1]);
    if (strncmp(argv[1], "open", len) == 0) {
	if (argc != 4) {
	    Tcl_Error(interp, "Usage: stream open <file> (r|w|a|r+|w+)");
	}

	stream = fopen(argv[2], argv[3]);

	if (stream == NULL) {
	    Tcl_Return(interp, "nil", TCL_STATIC);
	} else {
	    Tcl_RetPrintf(interp, "%d", stream);
	}
    } else if (strncmp(argv[1], "read", len) == 0) {
	if (argc != 4) {
	    Tcl_Error(interp, "Usage: stream read (line|list|char) <stream>");
	}

	stream = (FILE *)atoi(argv[3]);

	if (strcmp(argv[2], "char") == 0) {
	    int	    c = getc(stream);

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
		    break;
	    }
	} else if (strcmp(argv[2], "line") == 0) {
	    int	    c;
	    char    *base, *cp;
	    int	    left, size;

	    size = 256;
	    left = size-1;	/* Room for null */
	    base = cp = (char *)malloc(size);

	    while((c = getc(stream)) != EOF) {
		char	*addMe, tbuf[5];
		int 	addLen;

		switch(c) {
		    case '\\': addMe = "\\\\"; addLen = 2; break;
		    case '\n': addMe = "\\n"; addLen = 2; break;
		    case '\b': addMe = "\\b"; addLen = 2; break;
		    case '\r': addMe = "\\r"; addLen = 2; break;
		    case '\f': addMe = "\\f"; addLen = 2; break;
		    case '\033': addMe = "\\e"; addLen = 2; break;
		    case '\t': addMe = "\\t"; addLen = 2; break;
		    default:
			addMe = tbuf;
			if (!isprint(c)) {
			    addLen = 5;
			    sprintf(tbuf, "\\%03o", c);
			} else {
			    addLen = 1;
			    tbuf[0] = c;
			}
		}
		if (addLen > left) {
		    int	offset = cp - base;
		    left += 256;
		    size += 256;
		    base = (char *)realloc(base, size);
		    cp = base + offset;
		}
		left -= addLen;
		bcopy(addMe, cp, addLen);
		cp += addLen;
		if (c == '\n') {
		    break;
		}
	    }
	    *cp = '\0';

	    Tcl_Return(interp, base, TCL_DYNAMIC);
	} else if (strcmp(argv[2], "list") == 0) {
	    int	    c;
	    int	    level;
	    int	    done;
	    int	    left, size;
	    char    *base, *cp;

	    level = 0;
	    done = 0;

	    size = 256;
	    left = size-1;
	    base = cp = (char *)malloc(size);

	    while(!done) {
		char	tbuf[5];
		int 	addLen;

		c = getc(stream);

		switch(c) {
		    case EOF:
			addLen = 0;
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
			if (cp != base) {
			    if (level == 0) {
				addLen = 0;
				done = 1;
			    } else {
				tbuf[0] = c;
				addLen = 1;
			    }
			}
			break;
		    case '\\':
			/*
			 * Escaped character -- fetch and store w/o looking
			 * at it (except for EOF, of course).
			 */
			tbuf[0] = c;
			addLen = 1;
			c = getc(stream);
			if (c != EOF) {
			    tbuf[1] = c;
			    addLen++;
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
			    tbuf[0] = c;
			    addLen = 1;
			} else {
			    addLen = 0;
			}
			break;
		    case '}':
			level--;
			if (level == 0) {
			    addLen = 0;
			    done = 1;
			} else {
			    tbuf[0] = c;
			    addLen = 1;
			}
			break;
		    case '#':
			/*
			 * Handle comment lines. Comments are only paid
			 * attention to if we've not stored any characters.
			 * Otherwise, # is assumed to be a valid character
			 * in the list and we fall through to store it.
			 */
			if (cp == base) {
			    /*
			     * Skip to the end of the line and go back to the
			     * top.
			     */
			    while ((c = getc(stream)) != '\n' && c != EOF) {
				;
			    }
			    continue;
			}
			/*FALLTHRU*/
		    default:
			tbuf[0] = c;
			addLen = 1;
			break;
		}
		if (addLen) {
		    if (left < addLen) {
			int offset = cp - base;

			left += 256;
			size += 256;
			base = (char *)realloc(base, size);
			cp = base + offset;
		    }
		    left -= addLen;
		    bcopy(tbuf, cp, addLen);
		    cp += addLen;
		}
	    }
	    *cp = '\0';
	    Tcl_Return(interp, base, TCL_DYNAMIC);
	} else {
	    Tcl_Error(interp, "Usage: stream read (line|list|char) <stream>");
	}
    } else if (strncmp(argv[1], "print", len) == 0) {
	char	    *str;

	if (argc != 4) {
	    Tcl_Error(interp, "Usage: stream print <list> <stream>");
	}
	stream = (FILE *)atoi(argv[3]);

	/*
	 * Let Tcl_Merge deal with spaces etc.
	 */
	str = Tcl_Merge(1, &argv[2]);
	fprintf(stream, "%s\n", str);
	free(str);
    } else if (strncmp(argv[1], "write", len) == 0) {
	if (argc != 4) {
	    Tcl_Error(interp, "Usage: stream write <string> <stream>");
	}
	stream = (FILE *)atoi(argv[3]);
	fwrite(argv[2], strlen(argv[2]), 1, stream);
    } else if (strncmp(argv[1], "rewind", len) == 0) {
	if (argc != 3) {
	   Tcl_Error(interp, "Usage: stream rewind <stream>");
	}
	stream = (FILE *)atoi(argv[2]);
	fseek(stream, 0, L_SET);
    } else if (strncmp(argv[1], "seek", len) == 0) {
	int 	pos;
	int 	which;

	if (argc != 4) {
	    Tcl_Error(interp, "Usage: stream seek (<posn>|+<incr>|-<decr>|end) <stream>");
	}
	stream = (FILE *)atoi(argv[3]);

	switch (argv[2][0]) {
	    case '+':
		argv[2] += 1;
		/*FALLTHRU*/
	    case '-':
		pos = atoi(argv[2]);
		which = L_INCR;
		break;
	    case 'e':
		pos = 0;
		which = L_XTND;
		break;
	    default:
		pos = atoi(argv[2]);
		which = L_SET;
		break;
	}
	fseek(stream, pos, which);
	Tcl_RetPrintf(interp, "%d", ftell(stream));
    } else if (strncmp(argv[1], "state", len) == 0) {
	if (argc != 3) {
	    Tcl_Error(interp, "Usage: stream state <stream>");
	}
	stream = (FILE *)atoi(argv[2]);
	if (ferror(stream)) {
	    Tcl_Return(interp, "error", TCL_STATIC);
	} else if (feof(stream)) {
	    Tcl_Return(interp, "eof", TCL_STATIC);
	} else {
	    Tcl_Return(interp, "ok", TCL_STATIC);
	}
    } else if (strncmp(argv[1], "eof", len) == 0) {
	if (argc != 3) {
	    Tcl_Error(interp, "Usage: stream eof <stream>");
	}
	stream = (FILE *)atoi(argv[2]);

	Tcl_Return(interp, feof(stream) ? "1" : "0", TCL_STATIC);
    } else if (strncmp(argv[1], "close", len) == 0) {
	if (argc != 3) {
	    Tcl_Error(interp, "Usage: stream close <stream>");
	}
	stream = (FILE *)atoi(argv[2]);
	fclose(stream);
    } else if (strncmp(argv[1], "flush", len) == 0) {
	if (argc != 3) {
	    Tcl_Error(interp, "Usage: stream flush <stream>");
	}
	stream = (FILE *)atoi(argv[2]);
	fflush(stream);
    } else {
	goto stream_usage;
    }

    return(TCL_OK);
}


/***********************************************************************
 *				cmdEcho
 ***********************************************************************
 * SYNOPSIS:	    Print strings to stdout
 * CALLED BY:	    TCL
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    if -n not given as first arg, a newline is added
 *	    	    to the last string.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 1/89		Initial Revision
 *
 ***********************************************************************/
int
cmdEcho(ClientData clientData,
	Tcl_Interp *interp,
	int argc,
	char **argv)
{
    int	    	i;
    int	    	noNL;

    if ((argc > 1) && (strcmp(argv[1], "-n") == 0)) {
	noNL = 1;
	argc--;
	argv++;
    } else {
	noNL = 0;
    }
    for (i = 1; i < argc; i++) {
	printf("%s%s", argv[i], i == argc-1 ? "": " ");
    }
    if (!noNL) {
	printf("\n");
    }
    return (TCL_OK);
}


/***********************************************************************
 *				cmdSystem
 ***********************************************************************
 * SYNOPSIS:	    Pass a command to the shell to execute, giving it
 *	    	    complete control of the tty.
 * CALLED BY:	    TCL
 * RETURN:	    The return code from system & TCL_OK
 * SIDE EFFECTS:    None?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 1/89		Initial Revision
 *
 ***********************************************************************/
cmdSystem(ClientData	junk,
	  Tcl_Interp	*interp,
	  int	    	argc,
	  char	    	**argv)
{
    if (argc != 2) {
	Tcl_Error(interp, "Usage: system <command>");
    }
    Tcl_RetPrintf(interp, "%d", system(argv[1]));
    return(TCL_OK);
}

int
cmdExit(ClientData clientData,
	Tcl_Interp *interp,
	int argc,
	char **argv)
{
    extern void exit(int);

    exit(0);
}

main(argc, argv)
    int	    argc;
    char    **argv;
{
    char cmd[1000], *p;
    register char *p2;
    int c, i, result;

    /*
     * Create the interpreter and the four commands we support
     */
    interp = Tcl_CreateInterp();
    Tcl_CreateCommand(interp, "echo", cmdEcho, 0, (ClientData)0, NoDelProc);
    Tcl_CreateCommand(interp, "exit", cmdExit, 0, (ClientData)0, NoDelProc);
    Tcl_CreateCommand(interp, "stream", cmdStream, 0, (ClientData)0,NoDelProc);
    Tcl_CreateCommand(interp, "system", cmdSystem, 0, (ClientData)0,NoDelProc);

    /*
     * Set up the standard stream variables
     */
    sprintf(cmd, "%d", stdin);
    Tcl_SetVar(interp, "stdin", cmd, 1);
    sprintf(cmd, "%d", stdout);
    Tcl_SetVar(interp, "stdout", cmd, 1);
    sprintf(cmd, "%d", stderr);
    Tcl_SetVar(interp, "stderr", cmd, 1);

    if (argc > 1) {
	/*
	 * argv[1] is file to source. Merge remaining args together and
	 * place in args variable
	 */
	char	*args = Tcl_Merge(argc-2, argv+2);

	Tcl_SetVar(interp, "args", args, 1);

	/*
	 * Source the file. It should execute whatever it wants with the
	 * args we've placed in the args variable.
	 */
	switch (Tcl_SourceCmd((ClientData)0, interp, 2, argv)) {
	    case TCL_OK:
		if (*interp->result) {
		    printf("%s\n", interp->result);
		}
		exit(0);
	    default:
		if (*interp->result) {
		    printf("Error: %s\n", interp->result);
		}
		exit(1);
	}
    }

    /*
     * Interactive use. Set the prompt variable.
     */
    Tcl_SetVar(interp, "prompt", "% ", 1);

    (void)setjmp(abortBuf);	/* Top level re-entry */

    while (1) {
	const char *prompt = Tcl_GetVar(interp, "prompt", 1);

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
		/*
		 * Use whatever we've got as the last command we execute
		 */
		break;
	    }
	    /*
	     * Store the character
	     */
	    *p++ = c;

	    if (c == '\n') {
		/*
		 * end-of-line: See if we've got a complete command by
		 * checking the balancing of brackets and braces
		 */
		register char *p2;
		int braces, brackets, numBytes;

		for (p2 = cmd, braces = 0, brackets = 0; p2 != p; p2++) {
		    switch (*p2) {
			case '\\':
			    Tcl_Backslash(p2, &numBytes);
			    p2 += numBytes-1;
			    break;
			case '{':
			    /*
			     * Braces only matter inside other braces or
			     * after whitespace
			     */
			    if (braces || (p2 != cmd && isspace(p2[-1]))) {
				braces++;
			    }
			    break;
			case '}':
			    /*
			     * Endbraces matter only inside braces
			     */
			    if (braces) {
				braces--;
			    }
			    break;
			case '[':
			    /*
			     * Brackets only matter outside braces
			     */
			    if (!braces) {
				brackets++;
			    }
			    break;
			case ']':
			    /*
			     * Endbrackets only matter inside brackets
			     */
			    if (brackets) {
				brackets--;
			    }
			    break;
		    }
		}
		if ((braces == 0) && (brackets == 0)) {
		    /*
		     * In balance -- use command we've gotten
		     */
		    break;
		}
	    }
	}

	/*
	 * Null-terminate command
	 */
	*p = 0;

	/*
	 * Evaluate that puppy
	 */
	result = Tcl_Eval(interp, cmd, 0, (const char **)&p);
	if (result == TCL_OK) {
	    if (*interp->result != 0) {
		/*
		 * Non-empty result: print it out
		 */
		printf("%s\n", interp->result);
	    }
	} else if ((result == TCL_ERROR) &&
		   strncmp(interp->result, "invoked",
			   sizeof("invoked") - 1) == 0)
	{
	    /*
	     * Non-existent command invoked: try and execute it as a
	     * program. We pass the whole thing to sh to deal with I/O
	     * redirection and pipes, etc.
	     */
	    int	result = system(cmd);

	    if (result != 0) {
		printf("Error %d\n", result);
	    }
	} else {
	    /*
	     * Non-success: If TCL_ERROR preface with Error, else
	     * tell what code returned.
	     */
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
