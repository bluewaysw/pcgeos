/* 
 * tclProc.c --
 *
 *	This file contains routines that implement Tcl procedures and
 *	variables.
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
static char *rcsid = "$Id: tclProc.c,v 1.40 97/04/18 12:26:35 dbaumann Exp $ SPRITE (Berkeley)";
#endif not lint

#include <config.h>
#include <stdio.h>
#include <ctype.h>
#include <malloc.h>
#include <compat/string.h>

#include "tclInt.h"

/*
 * Library imports:
 */

/*
 * Forward references to procedures defined later in this file:
 */

static Var *	FindVar(VarFrame *vf, const char *varName);
static int	InterpProc(); /* parms: register Proc *procPtr,
			       *        Tcl_Interp    *interp,
			       *        int           argc,
			       *        char          **argv
			       */
static Var *	NewVar(const char *name, const char *value);
static Var *	AddVar(const char *name, const char *value, VarFrame *vf);
static void    	ProcDeleteProc(); /* parms: register Proc *procPtr */

/*
 *----------------------------------------------------------------------
 *
 * Tcl_ProcCmd --
 *
 *	This procedure is invoked to process the "proc" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result value.
 *
 * Side effects:
 *	A new procedure gets created.
 *
 *----------------------------------------------------------------------
 */

static const Tcl_SubCommandRec procCmds[] = {
    {TCL_CMD_ANY, 0, 	    2, 2, "<procname> <args> <body>"},
    {TCL_CMD_END}
};

DEFCMD(defsubr,Tcl_Defsubr,TCL_EXACT,procCmds,swat_prog.proc|swat_prog.tcl.proc|swat_prog.def,
"Usage:\n\
    defsubr <procname> <args> <body>\n\
\n\
Examples:\n\
    \"defsubr poof {arg1 args} {return [list $arg1 $args]}\"\n\
	    	    	    	Defines a procedure poof that takes 1 or more\n\
				arguments and merges them into a list of two\n\
				elements.\n\
\n\
Synopsis:\n\
    This is the same as the \"proc\" command, except the new procedure's name\n\
    may not be abbreviated when it is invoked.\n\
\n\
Notes:\n\
    * See the documentation for \"proc\" for further information.\n\
\n\
See also:\n\
    proc.\n\
")
{
    return Tcl_ProcCmd(clientData, interp, argc, argv);
}

DEFCMD(proc,Tcl_Proc,TCL_EXACT,procCmds,swat_prog.proc|swat_prog.tcl.proc|swat_prog.def,
"Usage:\n\
    proc <procname> <args> <body>\n\
\n\
Examples:\n\
    \"proc poof {{arg1 one} args} {return [list $arg1 $args]}\"\n\
	    	    	    	Defines a procedure poof that takes 0 or more\n\
				arguments and merges them into a list of two\n\
				elements. If no argument is given, the result\n\
				will be the list {one {}}\n\
\n\
Synopsis:\n\
    Defines a new Tcl procedure that can be invoked by typing a unique\n\
    abbreviation of the procedure name.\n\
\n\
Notes:\n\
    * Any existing procedure or built-in command is overridden.\n\
\n\
    * <procname> is the name of the new procedure and can consist of pretty much\n\
      any character (even a space or tab, if you enclose the argument in\n\
      braces).\n\
\n\
    * <args> is the, possibly empty, list of formal parameters the procedure\n\
      accepts. Each element of the list can be either the name of local\n\
      variable, to which the corresponding actual parameter is assigned before\n\
      the first command of the procedure is executed, or a two-element list,\n\
      the first element of which is the local variable name, as above, and the\n\
      second element of which is the value to assign the variable if no actual\n\
      parameter is given.\n\
\n\
    * If the final formal parameter is named \"args\", the remaining actual\n\
      parameters from that position on are cobbled into a list and assigned\n\
      to the local variable $args. This allows a procedure to receive a\n\
      variable number of arguments (even 0, in which case $args will be\n\
      the empty list).\n\
\n\
    * If the only formal parameter is \"noeval\", all the actual parameters are\n\
      merged into a list and assigned to $noeval. Moreover, neither command-\n\
      nor variable-substitution is performed on the actual parameters.\n\
\n\
    * The return value for the procedure is specified by executing the \"return\"\n\
      command within the procedure. If no \"return\" command is executed, the\n\
      return value for the procedure is the empty string.\n\
\n\
See also:\n\
    defsubr, return.\n\
")
{
    register Proc *procPtr;
    int result;
    int cmdLen;
    unsigned cmdFlags = 0;


    cmdLen = strlen(argv[3]);
    procPtr = (Proc *) malloc(sizeof(Proc)+cmdLen+1);
    bcopy(argv[3], procPtr->command, cmdLen+1);

    result = TclProcCreateArgs(interp, argv[1], argv[2],
			       &procPtr->argPtr, &cmdFlags);

    if (result == TCL_OK) {
	/*
	 * Register the command with the interpreter, binding our own InterpProc
	 * procedure to run it. If we were invoked as "defsubr", we make the
	 * name matching for our command be exact.
	 */
	procPtr->inuse = procPtr->delete = 0;
	if (strcmp(argv[0], "defsubr") == 0) {
	    cmdFlags |= TCL_EXACT;
	}
	Tcl_CreateCommand(interp, argv[1], InterpProc,
			  TCL_PROC | cmdFlags,
			  (ClientData) procPtr, ProcDeleteProc);

	Tcl_Return(interp, NULL, TCL_STATIC);

	return TCL_OK;
    } else {
	TclDeleteVars(procPtr->argPtr);
	free((char *) procPtr);
	return result;
    }
}

/***********************************************************************
 *				TclProcCreateArgs
 ***********************************************************************
 * SYNOPSIS:	    Break up a string into argument variables and default
 *		    values, for use by TclProcBindArgs
 * CALLED BY:	    (EXTERNAL) Tcl_ProcCmd, TclByteProc
 * RETURN:	    return code + string
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/23/93	Initial Revision
 *
 ***********************************************************************/
int
TclProcCreateArgs(Tcl_Interp	*interp,
		  const char	*procName,
		  const char	*argString,
		  Var	    	**argPtrPtr,
		  unsigned	*cmdFlagsPtr)
{
    int result, argCount, i;
    char **argArray;
    Var	**argNextPtr;
    
    /*
     * Break up the argument list into argument specifiers, then process
     * each argument specifier.
     */

    result = Tcl_SplitList(interp, argString, &argCount, &argArray);
    if (result != TCL_OK) {
	return result;
    }

    *argPtrPtr = (Var *)NULL;

    argNextPtr = argPtrPtr;
    
    for (i = 0; i < argCount; i++) {
	int fieldCount, nameLength, valueLength;
	char **fieldValues;
	register Var *argPtr;

	/*
	 * Now divide the specifier up into name and default.
	 */

	result = Tcl_SplitList(interp, argArray[i], &fieldCount,
			       &fieldValues);
	if (result != TCL_OK) {
	    break;
	}
	if (fieldCount > 2) {
	    Tcl_RetPrintf(interp,
			  "too many fields in argument specifier \"%.50s\"",
			  argArray[i]);
	    result = TCL_ERROR;
	    break;
	}
	if ((fieldCount == 0) || (*fieldValues[0] == 0)) {
	    Tcl_RetPrintf(interp,
			  "procedure \"%.50s\" has argument with no name",
			  procName);
	    result = TCL_ERROR;
	    break;
	}
	/*
	 * Find the length of the name and default value, for use in allocating
	 * the Var structure.
	 */
	nameLength = strlen(fieldValues[0]);
	if (fieldCount == 2) {
	    valueLength = strlen(fieldValues[1]);
	} else {
	    valueLength = 0;
	}
	/*
	 * Allocate and link in the Var structure for this arg.
	 */
	argPtr = *argNextPtr = (Var *)malloc(VAR_SIZE(nameLength, valueLength));
	argNextPtr = &argPtr->nextPtr;

	/*
	 * Now copy in the name and default value, setting the variable's
	 * value to NULL if there is no default value.
	 */
	bcopy(fieldValues[0], argPtr->name, nameLength+1);
	if (fieldCount == 2) {
	    argPtr->value = argPtr->name + nameLength + 1;
	    bcopy(fieldValues[1], argPtr->value, valueLength+1);
	} else {
	    argPtr->value = NULL;
	}
	/*
	 * Initialize the rest of the thing and biff the fieldValues array, as
	 * we need it no longer.
	 */
	argPtr->valueLength = valueLength;
	argPtr->flags = 0;
	argPtr->nextPtr = NULL;
	free((char *) fieldValues);

	/*
	 * If only argument is "noeval", set the TCL_NOEVAL flag for the
	 * command. No need to have a special case in InterpProc as there is
	 * for "args" since Tcl_Eval will merge everything into a single
	 * argument, whose name will be "noeval"...
	 */
	if ((argCount == 1) && (strcmp(argPtr->name, "noeval") == 0)) {
	    *cmdFlagsPtr |= TCL_NOEVAL;
	}
    }

    free((char *) argArray);
    return (result);
}

/***********************************************************************
 *				TclProcBindArgs
 ***********************************************************************
 * SYNOPSIS:	    Bind the argv array to the formal parameters of the
 *		    procedure as variables in a new scope
 * CALLED BY:	    (EXTERNAL) InterpProc
 * RETURN:	    error code + string
 * SIDE EFFECTS:    vars are created. If happy, new variable scope is
 *		    entered.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/23/93	Initial Revision
 *
 ***********************************************************************/
int
TclProcBindArgs(Interp *iPtr,
		Var *formalPtr,
		char **argv,
		int argc,
		VarFrame *framePtr)
{
    char **args;
    register Var *argPtr;
    int result = TCL_OK;
    char *value;
    
    /*
     * Change the scope for our own call frame to match the new scope we're
     * about to create.
     */
    framePtr->vars = NULL;
    framePtr->next = iPtr->top->localPtr;
    iPtr->top->localPtr = framePtr;

    /*
     * Bind the formal args to the actual ones as local variables
     */
    for (args = argv+1, argc -= 1;
	 formalPtr != NULL;
	 formalPtr = formalPtr->nextPtr, args++, argc--)
    {
	/*
	 * Handle the special case of the last formal being "args".  When
	 * it occurs, assign it a list consisting of all the remaining
	 * actual arguments.
	 */

	if ((formalPtr->nextPtr == NULL) &&
	    (strcmp(formalPtr->name, "args") == 0))
	{
	    argPtr = NewVar(formalPtr->name, "");
	    if (argc > 0) {
		argPtr->value = Tcl_Merge(argc, args);
		argPtr->flags |= VAR_DYNAMIC;
		argPtr->valueLength = strlen(argPtr->value);
		argc = 0;
	    }
	} else {
	    if (argc > 0) {
		value = *args;
	    } else if (formalPtr->value != NULL) {
		value = formalPtr->value;
	    } else {
		sprintf(iPtr->resultSpace,
			"no value given for parameter \"%s\" to \"%s\"",
			formalPtr->name, argv[0]);
		result = TCL_ERROR;
		break;
	    }
	    argPtr = NewVar(formalPtr->name, value);
	}
	argPtr->nextPtr = framePtr->vars;
	framePtr->vars = argPtr;
    }

    if (result == TCL_OK && argc > 0) {
	sprintf(iPtr->resultSpace, "called \"%s\" with too many arguments",
		argv[0]);
	result = TCL_ERROR;
    }

    return result;
}


/*
 *----------------------------------------------------------------------
 *
 * Tcl_GetVar --
 *
 *	Return the value of a Tcl variable.
 *
 * Results:
 *	The return value points to the current value of varName.  If
 *	the variable is not defined in interp, either as a local or
 *	global variable, then a pointer to an empty string is returned.
 *	Note:  the return value is only valid up until the next call to
 *	Tcl_SetVar;  if you depend on the value lasting longer than that,
 *	then make yourself a private copy.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

const char *
Tcl_GetVar(Tcl_Interp	*interp,    /* Command interpreter in which varName is
				     * to be looked up. */
	   const char	*varName,   /* Name of a variable in interp. */
	   int		global)	    /* If non-zero, use only a global variable*/
{
    Var *varPtr;
    Interp *iPtr = (Interp *) interp;

    varPtr = FindVar(global?&iPtr->globalFrame :iPtr->top->localPtr, varName);

    if (varPtr == NULL) {
	return "";
    }
    if (varPtr->flags & VAR_GLOBAL) {
	varPtr = varPtr->globalPtr;
    }
    if (varPtr->value == NULL) {
	return "";
    }
    return varPtr->value;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_SetVar --
 *
 *	Change the value of a variable.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	If varName is defined as a local or global variable in interp,
 *	its value is changed to newValue.  If varName isn't currently
 *	defined, then a new global variable by that name is created.
 *
 *----------------------------------------------------------------------
 */

void
Tcl_SetVar(Tcl_Interp	*interp,    /* Command interpreter in which varName is
				     * to be looked up. */
	   const char	*varName,   /* Name of a variable in interp. */
	   const char	*newValue,  /* New value for varName. */
	   int		global)	    /* If non-zero, use only a global variable*/
{
    register Var *varPtr;
    VarFrame	*vf;
    register Interp *iPtr = (Interp *) interp;
    int valueLength;

    vf = global ? &iPtr->globalFrame : iPtr->top->localPtr;

    varPtr = FindVar(vf, varName);
    if (varPtr == NULL) {
	(void)AddVar(varName, newValue, vf);
    } else {
	if (varPtr->flags & VAR_GLOBAL) {
	    varPtr = varPtr->globalPtr;
	}
	valueLength = strlen(newValue);
	/*
	 * If new value is larger than the old, or the old is a lot larger than
	 * the new (8* or more), free the old value and allocate a new one.
	 */
	if (valueLength > varPtr->valueLength ||
	    (varPtr->valueLength > (valueLength << 3)))
	{
	    if (varPtr->flags & VAR_DYNAMIC) {
		free(varPtr->value);
	    }
	    /* XXX: shrink variable structure if non-dynamic value is large */
	    varPtr->value = (char *) malloc((unsigned) valueLength + 1);
	    varPtr->flags |= VAR_DYNAMIC;
	    varPtr->valueLength = valueLength;
	}
	bcopy(newValue, varPtr->value, valueLength+1);
    }
}

const char *
TclProcScanVar(Tcl_Interp *interp,
	       const char *string,  	/* Points to $ */
	       int *lenPtr, 	    	/* Length of variable name stored
					 * here */
	       const char **termPtr)	/* First char past var spec stored
					 * here */
{
    const char *name;
    
    /*
     * There are two cases:
     * 1. The $ sign is followed by an open curly brace.  Then the variable
     *    name is everything up to the next close curly brace.
     * 2. The $ sign is not followed by an open curly brace.  Then the
     *    variable name is everything up to the next character that isn't
     *    a letter, digit, or underscore.
     */

    string++;
    if (*string == '{') {
	string++;
	name = string;
	while ((*string != '}') && (*string != 0)) {
	    string++;
	}
	if (termPtr != 0) {
	    if (*string != 0) {
		*termPtr = string+1;
	    } else {
		*termPtr = string;
	    }
	}
    } else {
	name = string;
	while (isalnum(*string) || (*string == '_')) {
	    string++;
	}
	if (termPtr != 0) {
	    *termPtr = string;
	}
    }

    *lenPtr = string-name;
    return(name);
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_ParseVar --
 *
 *	Given a string starting with a $ sign, parse off a variable
 *	name and return its value.
 *
 * Results:
 *	The return value is the contents of the variable given by
 *	the leading characters of string.  If termPtr isn't NULL,
 *	*termPtr gets filled in with the address of the character
 *	just after the last one in the variable specifier.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

const char *
Tcl_ParseVar(Tcl_Interp	    *interp,	/* Context for looking up variable. */
	     register const char *string,/* String containing variable name.
					 * First character must be "$". */
	     const char **termPtr)  	/* If non-NULL, points to word to fill
					 * in with character just after last
					 * one in the variable specifier. */
    
{
    const char	*name, *result;
    char *varname;
    int len;

    name = TclProcScanVar(interp, string, &len, termPtr);
    
    varname = (char *)malloc(len+1);
    bcopy(name, varname, len);
    varname[len] = '\0';
    result = Tcl_GetVar(interp, (const char *)varname, 0);
    free(varname);
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_VarCmd --
 *
 *	This procedure is invoked to process the "index" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result value.
 *
 * Side effects:
 *	A variable's value may be changed.
 *
 *----------------------------------------------------------------------
 */

DEFCMD(var,Tcl_Var,TCL_EXACT,NULL,swat_prog.tcl.var|tcl,
"Usage:\n\
    var <name>\n\
    var (<name> <value>)+\n\
\n\
Examples:\n\
    \"echo [var poof]\"	    Prints the value stored in the variable \"poof\"\n\
    \"var a b c d\"   	    Assigns the string \"b\" to the variable \"a\", and\n\
			    the string \"d\" to the variable \"c\".\n\
    \"var yes $no no $yes\"   Exchanges the values of the \"yes\" and \"no\" variables\n\
\n\
Synopsis:\n\
    This is the means by which variables are defined in Tcl. Less often, it is\n\
    also used to retrieve the value of a variable (usually that's done via\n\
    variable substitution).\n\
\n\
Notes:\n\
    * If you give only one argument, the value of that variable will be\n\
      returned. If the variable has never been given a value, the variable\n\
      will be created and assigned the empty string, then the empty string\n\
      will be returned.\n\
\n\
    * You can set value of a variable by giving the value as the second\n\
      argument, after the variable name. No value is returned by the \"var\"\n\
      command in this case.\n\
\n\
    * You can assign values to multiple variables \"in parallel\" by giving\n\
      successive name/value pairs. \n\
\n\
    * If invoked in a procedure on a variable that has not been declared global\n\
      (using the \"global\" command), this applies to the local variable of the\n\
      given name, even if it has no value yet.\n\
\n\
See also:\n\
    global.\n\
")
{
    if (argc == 2) {
	interp->result = Tcl_GetVar(interp, argv[1], 0);
	return TCL_OK;
    } else if ((argc >= 3) && (argc & 1)) {
	/*
	 * Need special processing here to deal with Tcl_Eval's usurpation of
	 * variable values into argument vectors. If we're setting a variable
	 * from the value of another, but setting the value of that other
	 * first, the second assignment could well refer to free memory or
	 * a modified value, resulting in an incorrect assignment.
	 */
	int i;
	int j;
	char	**copies;

	copies = (char **)calloc(argc, sizeof(char *));

	for (i = 1; i < argc; i += 2) {
	    Var	*v = FindVar(((Interp *)interp)->top->localPtr, argv[i]);

	    if (v != (Var *)0) {
		for (j = 2; j < argc; j += 2) {
		    if (argv[j] == v->value) {
			int	len = strlen(argv[j])+1;
			
			copies[j] = (char *)malloc(len);
			bcopy(argv[j], copies[j], len);
			argv[j] = copies[j];
			break;
		    }
		}
	    }
	}

	for (i = 1; i < argc; i += 2) {
	    Tcl_SetVar(interp, argv[i], argv[i+1], 0);
	}

	for (i = 2; i < argc; i += 2) {
	    if (copies[i] != 0) {
		free(copies[i]);
	    }
	}
	free((char *)copies);
	return TCL_OK;
    } else {
	Tcl_RetPrintf(interp,
		      "Usage: %.50s <varName> [<newValue> [<varName> <newValue>]+]",
		      argv[0]);
	return TCL_ERROR;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_GlobalCmd --
 *
 *	This procedure is invoked to process the "global" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result value.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

static const Tcl_SubCommandRec globalCmds[] = {
    {TCL_CMD_ANY, 0, 	    0, TCL_CMD_NOCHECK, "<varName>+"},
    {TCL_CMD_END}
};


DEFCMD(global,Tcl_Global,TCL_EXACT,globalCmds,swat_prog.tcl.var,
"Usage:\n\
    global <varName>+\n\
\n\
Examples:\n\
    \"global attached\"	When next the \"attached\" variable is fetched or\n\
			set, get it from the global scope, not the local one.\n\
\n\
Synopsis:\n\
    Declares the given variables to be from the global scope.\n\
\n\
Notes:\n\
    * For the duration of the procedure in which this command is executed (but\n\
      not in any procedure it invokes), the global variable of the given name\n\
      will be used when the variable is fetched or set.\n\
\n\
    * If no global variable of the given name exists, the setting of that\n\
      variable will define it in the global scope.\n\
\n\
See also:\n\
    var.\n\
")
{
    register Var *varPtr;
    register Interp *iPtr = (Interp *) interp;
    Var *gVarPtr;

    /*
     * Check to see if local vars already coming from global and do nothing
     * if so. Need to check this, rather than curProc, as uplevel can play
     * with our mind...
     */
    if (iPtr->top->localPtr == &iPtr->globalFrame) {
	return TCL_OK;
    }

    for (argc--, argv++; argc > 0; argc--, argv++) {
	gVarPtr = FindVar(&iPtr->globalFrame, *argv);
	if (gVarPtr == NULL) {
	    gVarPtr = AddVar(*argv, "", &iPtr->globalFrame);
	}
	varPtr = AddVar(*argv, "", iPtr->top->localPtr);
	varPtr->flags |= VAR_GLOBAL;
	varPtr->globalPtr = gVarPtr;
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * TclFindProc --
 *
 *	Given the name of a procedure, return a pointer to the
 *	record describing the procedure.
 *
 * Results:
 *	NULL is returned if the name doesn't correspond to any
 *	procedure.  Otherwise the return value is a pointer to
 *	the procedure's record.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

Proc *
TclFindProc(Interp  *iPtr,	/* Interpreter in which to look. */
	    const char *procName)	/* Name of desired procedure. */
{
    Command *cmdPtr;

    cmdPtr = TclFindCmd(iPtr, procName, 0);
    if (cmdPtr == NULL) {
	return NULL;
    }
    if (cmdPtr->proc != InterpProc) {
	return NULL;
    }
    return (Proc *) cmdPtr->clientData;
}

/*
 *----------------------------------------------------------------------
 *
 * TclDeleteVars --
 *
 *	Biff a list of variables. This procedure is used, e.g., by
 *	Tcl_DeleteInterp, Tcl_TopLevel, InterpProc and ProcDeleteProc
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Variables are deleted.
 *
 *----------------------------------------------------------------------
 */

void
TclDeleteVars(Var	*varPtr)	/* Interpreter to nuke. */
{
    register Var *nextPtr;

    while (varPtr != NULL) {
	nextPtr = varPtr->nextPtr;
	if (varPtr->flags & VAR_DYNAMIC) {
	    free(varPtr->value);
	}
	free((char *) varPtr);
	varPtr = nextPtr;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * InterpProc --
 *
 *	When a Tcl procedure gets invoked, this routine gets invoked
 *	to interpret the procedure.
 *
 * Results:
 *	A standard Tcl result value, usually TCL_OK.
 *
 * Side effects:
 *	Depends on the commands in the procedure.
 *
 *----------------------------------------------------------------------
 */

static int
InterpProc(register Proc    *procPtr,	/* Record describing procedure to be
					 * interpreted. */
	   Tcl_Interp	    *interp,	/* Interpreter in which procedure was
					 * invoked. */
	   int		    argc,	/* Count of number of arguments to this
					 * procedure. */
	   char		    **argv)	/* Argument values. */
{
    register Interp *iPtr = (Interp *) interp;
    int result;
    VarFrame	frame;

    procPtr->inuse++;

    result = TclProcBindArgs(iPtr, procPtr->argPtr, argv, argc, &frame);

    if (result == TCL_OK) {
	/*
	 * Invoke the commands in the procedure's body.
	 */
	
	result = Tcl_Eval(interp, procPtr->command, 0, (const char **) NULL);
	if (result == TCL_RETURN) {
	    result = TCL_OK;
	} else if (result == TCL_OK) {
	    /*
	     * Body didn't return anything, so make sure result is empty.
	     */
	    Tcl_Return(interp, (char *) NULL, TCL_STATIC);
	} else if (result == TCL_BREAK) {
	    Tcl_Return(interp, "invoked \"break\" outside of a loop", TCL_STATIC);
	    result = TCL_ERROR;
	} else if (result == TCL_CONTINUE) {
	    Tcl_Return(interp, "invoked \"continue\" outside of a loop",
		       TCL_STATIC);
	    result = TCL_ERROR;
	}
    }

    /*
     * Delete all of the procedure's local variables, and restore the
     * locals from the calling procedure.
     */

    TclDeleteVars(frame.vars);

    /*
     * Return to previous scope
     */
    iPtr->top->localPtr = frame.next;
    if ((--procPtr->inuse == 0) && procPtr->delete) {
	ProcDeleteProc(procPtr);
    }
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * ProcDeleteProc --
 *
 *	This procedure is invoked just before a command procedure is
 *	removed from an interpreter.  Its job is to release all the
 *	resources allocated to the procedure.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Memory gets freed.
 *
 *----------------------------------------------------------------------
 */

static void
ProcDeleteProc(register Proc	*procPtr)   /* Procedure to be deleted. */
{
    if (procPtr->inuse) {
	procPtr->delete = 1;
    } else {
	TclDeleteVars(procPtr->argPtr);
	free((char *) procPtr);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * FindVar --
 *
 *	Locate the Var structure corresponding to varName, if there
 *	is one defined in a given list.
 *
 * Results:
 *	The return value points to the Var structure corresponding to
 *	the current value of varName in varListPtr, or NULL if varName
 *	isn't currently defined in the list.
 *
 * Side effects:
 *	If the variable is found, it is moved to the front of the list.
 *
 *----------------------------------------------------------------------
 */

static Var *
FindVar(VarFrame *vf,	    	/* Pointer to frame to search */
	const char *varName)	/* Desired variable. */
{
    register Var *prev, *cur;
    register char c;

    c = *varName;

    /*
     * Local variables take precedence over global ones.  Check the
     * first character immediately, before wasting time calling strcmp.
     */

    for (prev = NULL, cur = vf->vars; cur != NULL;
	 prev = cur, cur = cur->nextPtr)
    {
	if ((cur->name[0] == c) && (strcmp(cur->name, varName) == 0)) {
	    if (prev != NULL) {
		prev->nextPtr = cur->nextPtr;
		cur->nextPtr = vf->vars;
		vf->vars = cur;
	    }
	    return cur;
	}
    }
    return NULL;
}

/*
 *----------------------------------------------------------------------
 *
 * NewVar --
 *
 *	Create a new variable with the given name and initial value.
 *
 * Results:
 *	The return value is a pointer to the new variable.  The variable
 *	will not have been linked into any particular list, and its
 *	nextPtr field will be NULL.
 *
 * Side effects:
 *	Storage gets allocated.
 *
 *----------------------------------------------------------------------
 */

static Var *
NewVar(const char *name,  /* Name for variable. */
       const char *value) /* Value for variable. */
{
    register Var *varPtr;
    int nameLength, valueLength, realValueLength;

    nameLength = strlen(name);
    realValueLength = valueLength = strlen(value);
    if (valueLength < 20) {
	valueLength = 20;
    }
    varPtr = (Var *) malloc(VAR_SIZE(nameLength, valueLength));
    bcopy(name, varPtr->name, nameLength+1);
    varPtr->value = varPtr->name + nameLength + 1;
    bcopy(value, varPtr->value, realValueLength+1);
    varPtr->valueLength = valueLength;
    varPtr->flags = 0;
    varPtr->globalPtr = NULL;
    varPtr->nextPtr = NULL;
    return varPtr;
}


/***********************************************************************
 *				AddVar
 ***********************************************************************
 * SYNOPSIS:	    Add a variable to a frame
 * CALLED BY:	    INTERNAL
 * RETURN:	    The newly-created variable.
 * SIDE EFFECTS:    None, really
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 9/90		Initial Revision
 *
 ***********************************************************************/
static Var *
AddVar(const char *name,
       const char *value,
       VarFrame	*vf)
{
    Var     *result = NewVar(name, value);

    result->nextPtr = vf->vars;
    vf->vars = result;

    return(result);
}
