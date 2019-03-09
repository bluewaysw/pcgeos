/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- X11 interface, button manipulation
 * FILE:	  button.c
 *
 * AUTHOR:  	  Adam de Boor: Jul 17, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/17/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions for handling the creation and deletion of buttons
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: button.c,v 1.2 89/07/21 04:02:37 adam Exp $";
#endif lint

#include    "swat.h"
#include    "cmd.h"
#include    "ui.h"
#include    "x11.h"

#define Boolean	  XtBool
#define Opaque	  XtOpaque
#include    <X11/StringDefs.h>
#include    <X11/IntrinsicP.h>
#include    <X11/Command.h>
#undef Boolean
#undef Opaque

static Widget	boxWidget;

/*-
 *-----------------------------------------------------------------------
 * ButtonCallback --
 *	Function called when a button is pressed. Prints out and
 *	executes the command kept in the closure for the button.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The command is executed.
 *
 *-----------------------------------------------------------------------
 */
static void
ButtonCallback(w, cmd, call_data)
    Widget  	  	w;
    char    	    	*cmd;	    	/* Command to eval */
    caddr_t		call_data;  	/* Passed data (nothing) */
{
    int	    	  	result;

    result = Tcl_Eval(interp, cmd, 0, (char **)NULL);

    if (result != TCL_OK) {
	MessageFlush("Error: %s\n", interp->result);
	XtTtySetFence(tty, -1);
    } else if (*interp->result != '\0') {
	MessageFlush("%s\n", interp->result);
	XtTtySetFence(tty, -1);
    }
}

/*-
 *-----------------------------------------------------------------------
 * ButtonDestroyCallback --
 *	Called when a button is destroyed to free up its private data.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	privPtr and its contents are freed.
 *
 *-----------------------------------------------------------------------
 */
static void
ButtonDestroyCallback(w, cmd, call_data)
    Widget  	  	w;
    char    	    	*cmd;
    caddr_t		call_data;
{
    free(cmd);
}

/***********************************************************************
 *				ButtonCmd
 ***********************************************************************
 * SYNOPSIS:	    Command to create/delete buttons
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK
 * SIDE EFFECTS:    A button will be added or deleted from the boxWidget
 *
 * STRATEGY:
 *	Rather than a large decimal number, this command uses the full
 *	widget name to name a button, allowing the name to be deduced
 *	by the user and typed in.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/18/89		Initial Revision
 *
 ***********************************************************************/
#define BUTTON_CREATE 	(ClientData)0
#define BUTTON_DELETE	(ClientData)1
static const CmdSubRec buttonCmds[] = {
    "create",	BUTTON_CREATE,	2, 2,	"<label> <command>",
    "destroy",	BUTTON_DELETE,	1, 1,	"<button>",
    "delete",	BUTTON_DELETE,	1, 1,	"<button>",
    NULL,   	NULL,	    	0, 0,	NULL
};
DEFCMD(button,Button,TCL_EXACT,buttonCmds,prog.window,
"This command implements the creation and destruction of buttons in the x11\n\
interface. When pressed, a button causes a TCL command to be evaluated.\n\
If the command produces a result, the result is printed and another prompt\n\
issued. A useful command for dealing with things like ``istep'' is\n\
provide-input, at which I suggest you look.\n\
\n\
The create subcommand takes a label to place in the button and the command\n\
to execute as its two arguments. A token is returned that may be used\n\
to delete the button. The token is actually the full name of the button,\n\
to make life a bit easier when deleting them from the command line.\n\
\n\
The delete (or destroy) subcommand takes the name of a button to nuke.")
{
    switch((int)clientData) {
	case BUTTON_CREATE:
	{
	    Arg	    	args[1];
	    char    	*cmd;
	    Widget	w;
	    
	    XtSetArg(args[0], XtNlabel, argv[2]);
	    
	    w = XtCreateManagedWidget(argv[2], commandWidgetClass,
				      boxWidget,
				      args, XtNumber(args));
	    if (w == (Widget)NULL) {
		Tcl_Error(interp, "Could not create button");
	    }
	    
	    cmd = (char *)malloc(strlen(argv[3])+1);
	    strcpy(cmd, argv[3]);

	    XtAddCallback(w, XtNcallback, ButtonCallback, (caddr_t)cmd);
	    XtAddCallback(w, XtNdestroyCallback, ButtonDestroyCallback,
			  (caddr_t)cmd);
	    
	    Tcl_Return(interp, X11_WidgetToName(w), TCL_DYNAMIC);
	    break;
	}
	case BUTTON_DELETE:
	{
	    Widget  	    w;	    /* Button to nuke */
	    extern Widget   shell;  /* Top-level shell */

	    w = XtNameToWidget(shell, argv[2]);
	    if (w == (Widget)NULL) {
		Tcl_RetPrintf(interp, "%s: no such button to destroy",
			      argv[2]);
		return(TCL_ERROR);
	    }
	    if (!XtIsSubclass(w, commandWidgetClass)) {
		Tcl_RetPrintf(interp, "%s: isn't a button",
			      argv[2]);
		return(TCL_ERROR);
	    }
	    XtDestroyWidget(w);
	    break;
	}
    }
    return(TCL_OK);
}

/*-
 *-----------------------------------------------------------------------
 * Button_Init --
 *	Initialize the button box.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Buttons are created.
 *
 *-----------------------------------------------------------------------
 */
void
Button_Init(box)
    Widget  	box;	    /* Box widget in which to place buttons */
{
    Cmd_Create(&ButtonCmdRec);

    boxWidget = box;

}
