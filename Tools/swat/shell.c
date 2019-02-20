/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  SWAT -- Shell-like User Interface
 * FILE:	  shell.c
 *
 * AUTHOR:  	  Adam de Boor: Nov 10, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Shell_Init	    Initialize the module
 *	ShellReadLine 	    Read a single line from the input stream
 *	ShellNumColumns	    Return width of output area
 *	ShellMessage   	    Print a friendly message
 *	ShellMessageFlush   Same, but do it NOW
 *	ShellWarning   	    Print a warning message. Supplies newline.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	11/10/88  ardeb	    Initial version
 *	12/7/88	  ardeb	    Converted to procedure vectors and split into
 *	    	    	    ui.c and shell.c...
 *
 * DESCRIPTION:
 *	The functions in this file implement the simple shell-like UI for
 *	SWAT.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: shell.c,v 4.7 97/04/18 16:34:46 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "cmd.h"
#include "rpc.h"
#include "ui.h"

#include <buf.h>
#include <stdarg.h>
#include <ctype.h>
#include <compat/stdlib.h>
#if defined(_WIN32)
# include <io.h>
# include <initscr.h>
# include <conio.h>
#endif

static Buffer  	input;	    	    	/* Buffer into which input is read */
static int  	shellFlags;    	    	/* State flags for the interface */
#define SHELL_READCMD  	    0x00000001	/* Set if reading a TCL command, i.e.
					 * if braces/brackets must balance */
#define SHELL_INPUTAVAIL    0x00000004  /* Set if input available */
#define INPUT_LINE_LENGTH   (256)       /* Max length of input line */


/***********************************************************************
 *				ShellReadInput
 ***********************************************************************
 * SYNOPSIS:	    Read line of available input from stdin into the input
 *		    buffer.
 * CALLED BY:	    Rpc_Wait
 * RETURN:	    Nothing
 * SIDE EFFECTS:    SHELL_INPUTAVAIL will be set if a full line has been
 *		    received
 *
 * STRATEGY:
 *	Read as many characters as possible into the input buffer.
 *	If not reading a command, set the INPUTAVAIL flag and return.
 *	Else, see if the braces/brackets are balanced. If so, set
 *	    INPUTAVAIL and return.
 *	Else just return.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
static void
ShellReadInput(int    	    stream,
	       Rpc_Opaque   data,	    /* UNUSED */
	       int    	    state)	    /* UNUSED */
{
    char    	line[INPUT_LINE_LENGTH];
    int	    	cc = 0;

#if !defined(_WIN32)
    cc = read(stream, line, sizeof(line));
#else
# define _DCCHAR		0x08		/* Delete Char char (BS) */
# define _DLCHAR		0x1b		/* Delete Line char (ESC) */

    while (cc < (INPUT_LINE_LENGTH - 1)) {
	line[cc] = (char) getch();
	if (line[cc] == '\n') {
	    line[cc] = '\r';    /* XXXdan-q hack for multi-line fix */
	    break;
	}
	if (line[cc] == '\r') {
	    putch(line[cc]);
	    break;
	}
	if (line[cc] == _DCCHAR) {
	    if (cc > 0) {
		cc--;
		putch(_DCCHAR);
		putch(' ');
		putch(_DCCHAR);
	    }
	} else {
	    if (line[cc] == _DLCHAR) {
		while (cc > 0) {
		    cc--;
		    putch(_DCCHAR);
		    putch(' ');
		    putch(_DCCHAR);
		}
	    } else {
		putch(line[cc]);
		cc++;
	    } /* else */
	}
    } /* while */

    putch('\n');
    cc++;
#endif

    Buf_AddBytes(input, cc, (Byte *)line);

    if (shellFlags & SHELL_READCMD) {
	char	*cp = (char *)Buf_GetAll(input, &cc);
	int braces, brackets, numBytes;
	
	for (braces = 0, brackets = 0; cc > 0; cp++, cc--) {
	    switch (*cp) {
		case '\\':
		    (void)Tcl_Backslash(cp, &numBytes);
		    cp += numBytes-1;
		    cc -= numBytes-1;
		    break;
		case '{':
		    if (braces > 0 || isspace(cp[-1])) {
			braces++;
		    }
		    break;
		case '}':
		    if (braces) {
			braces--;
		    }
		    break;
		case '[':
		    if (!braces) {
			brackets++;
		    }
		    break;
		case ']':
		    if (!braces && brackets) {
			brackets--;
		    }
		    break;
	    }
	}
	if ((braces > 0) || (brackets > 0)) {
	    return;
	}
    }
    /*
     * Tell ReadLineCmd to do its thing.
     */
    shellFlags |= SHELL_INPUTAVAIL;
}
	

/***********************************************************************
 *				ShellReadLineCmd
 ***********************************************************************
 * SYNOPSIS:	    Read a line of input from the user.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK and the line as a dynamic result
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Set up the input buffer.
 *	    	    Call Rpc_Wait until SHELL_INPUTAVAIL becomes true.
 *	    	    Return buffer data, destroying input buffer.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(read-line,ShellReadLine, TCL_EXACT,NULL,swat_prog.input,
"Reads a single line of input from the user. If optional argument CMD is\n\
non-zero, the line is interpreted as a TCL command and will not be returned\n\
until all braces/brackets are balanced. The final newline is stripped")
{
    char    	*cp;
    int	    	length;

    fflush(stdout);

#if defined(_MSDOS)
    Mouse_Watch();
#endif
    Rpc_Watch(0, RPC_READABLE, ShellReadInput, (ClientData)NULL); 

    input = Buf_Init(256);
    if (argc > 1 && atoi(argv[1]) > 0) {
	shellFlags |= SHELL_READCMD;
    } else {
	shellFlags &= ~SHELL_READCMD;
    }

    shellFlags &= ~SHELL_INPUTAVAIL;

    while (!(shellFlags & SHELL_INPUTAVAIL)) {
	Rpc_Wait();
    }

    cp = (char *)Buf_GetAll(input, &length);

    cp[length-1] = '\0';

    Buf_Destroy(input, FALSE);

    Rpc_Ignore(0);

#if defined(_MSDOS)
    Mouse_Ignore();
#endif
    Tcl_Return(interp, cp, TCL_DYNAMIC);
    return(TCL_OK);
}

/***********************************************************************
 *				ShellReadCharCmd
 ***********************************************************************
 * SYNOPSIS:	    Command to read a single character
 * CALLED BY:	
 * RETURN:	
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 5/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(read-char,ShellReadChar,TCL_EXACT,NULL,swat_prog.input,
"Reads a single character from the user. This will actually read an entire\n\
line and return just the first character...")
{
    char    	*cp;

    fflush(stdout);

#if defined(_MSDOS)
    Mouse_Watch();
#endif
    Rpc_Watch(0, RPC_READABLE, ShellReadInput, (ClientData)NULL);

    input = Buf_Init(16);
    shellFlags &= ~(SHELL_READCMD|SHELL_INPUTAVAIL);

    while (!(shellFlags & SHELL_INPUTAVAIL)) {
	Rpc_Wait();
    }

    cp = (char *)Buf_GetAll(input, (int *)NULL);

    cp[1] = '\0';

    Buf_Destroy(input, FALSE);

    Rpc_Ignore(0);
#if defined(_MSDOS)
    Mouse_Ignore();
#endif
    Tcl_Return(interp, cp, TCL_DYNAMIC);
    return(TCL_OK);
}

/***********************************************************************
 *				ShellMessage
 ***********************************************************************
 * SYNOPSIS:	    Print a friendly message to the user
 * CALLED BY:	    GLOBAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Not here
 *
 * STRATEGY:	    Call _doprnt properly.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
static void
ShellMessage(const char *fmt, ...)
{
    va_list 	args;

    va_start(args, fmt);

    vfprintf(stdout, fmt, args);

    va_end(args);
}

/***********************************************************************
 *				ShellMessageFlush
 ***********************************************************************
 * SYNOPSIS:	    Give a message to the user and make sure it
 *		    gets out NOW
 * CALLED BY:	    GLOBAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Call _doprnt and fflush properly
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
static void
ShellMessageFlush(const char *fmt, ...)
{
    va_list 	args;

    va_start(args, fmt);
    vfprintf(stdout, fmt, args);
    va_end(args);
    fflush(stdout);
}
/*-
 *-----------------------------------------------------------------------
 * CmdEcho --
 *	Print the arguments.
 *
 * Results:
 *	TCL_OK.
 *
 * Side Effects:
 *	The arguments are displayed.
 *
 *-----------------------------------------------------------------------
 */
DEFCMD(echo,ShellEcho,TCL_EXACT,NULL,swat_prog.output,
"Prints its arguments, separated by spaces. If the first argument is -n, no\n\
newline is printed. The arguments are printed separated by spaces.")
{
    int	    	i;
    Boolean	noNL;

    if ((argc > 1) && (strcmp(argv[1], "-n") == 0)) {
	noNL = TRUE;
	argc--;
	argv++;
    } else {
	noNL = FALSE;
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
 *				ShellWarning
 ***********************************************************************
 * SYNOPSIS:	    Print a warning for the user. Prints a newline.
 * CALLED BY:	    GLOBAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Print "Warning:", the message, "\n" to stderr and
 *		    flush.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
static void
ShellWarning(const char *fmt, ...)
{
    va_list 	args;

    fputs("Warning: ", stderr);

    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);
    putc('\n', stderr);
    fflush(stderr);
}

/***********************************************************************
 *				ShellNumColumns
 ***********************************************************************
 * SYNOPSIS:	    Find the number of columns in the I/O window
 * CALLED BY:	    Help_Cmd
 * RETURN:	    The number of columns available for output
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
static int
ShellNumColumns(void)
{
    return(79);			/* emacs only allows 79... */
}

/***********************************************************************
 *				ShellReadLine
 ***********************************************************************
 * SYNOPSIS:	    Read a line for a C function.
 * CALLED BY:	    GLOBAL
 * RETURN:	    Buffer filled in
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:	    Just calls gets. Buffer is assumed large enough.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
static void
ShellReadLine(char *line)
{
    gets(line);
}

/***********************************************************************
 *				ShellSystemCmd
 ***********************************************************************
 * SYNOPSIS:	    Execute a command in a sub-shell. This is here b/c
 *	    	    of the special things (resetting the terminal, refreshing
 *	    	    upon return, etc.) that may need doing in other
 *		    interfaces.
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    Rpc's are ignored while the command is executing.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 6/88	Initial Revision
 *
 ***********************************************************************/
DEFCMD(system,ShellSystem,TCL_EXACT,NULL,swat_prog.external,
"Cause a shell to execute the first argument. The shell used is the bourne\n\
shell, so tilde's aren't expanded. Doesn't return until the command completes\n\
and the output isn't saved anywhere.")
{
    int	rval = system(argv[1]);

    if (rval) {
	Tcl_RetPrintf(interp, "%d", rval);
    }
    
    return (rval ? TCL_ERROR : TCL_OK);
}

/***********************************************************************
 *				Shell_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize a shell-like interface
 * CALLED BY:	    Ui_Init
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The procedure vectors be set
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 7/88	Initial Revision
 *
 ***********************************************************************/
void
Shell_Init(void)
{
    shellFlags = 0;

    Message = ShellMessage;
    Warning = ShellWarning;
    MessageFlush = ShellMessageFlush;
    Ui_NumColumns = ShellNumColumns;
    Ui_ReadLine = ShellReadLine;
    Ui_Exit = (void (*)(void))NULL;

    Cmd_Create(&ShellReadLineCmdRec);
    Cmd_Create(&ShellReadCharCmdRec);
    Cmd_Create(&ShellEchoCmdRec);
    Cmd_Create(&ShellSystemCmdRec);

#if defined(_WIN32)
    Initscr_PrepConsole();
#endif

    Tcl_SetVar(interp, "window-system", "shell", TRUE);
}
