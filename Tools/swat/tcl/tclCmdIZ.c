/* 
 * tclCmdIZ.c --
 *
 *	This file contains the top-level command routines for most of
 *	the Tcl built-in commands whose names begin with the letters
 *	I to Z.
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
static char *rcsid = "$Id: tclCmdIZ.c,v 1.44 97/04/18 12:22:08 dbaumann Exp $ SPRITE (Berkeley)";
#endif not lint

#include <config.h>
#include <ctype.h>
#include <stdio.h>
#include <sys/types.h>
#include <malloc.h>
#include <compat/string.h>
#include <compat/stdlib.h>
#include <compat/file.h>
#include <fileUtil.h>

#if defined(unix)
#include <sys/stat.h>
#include <sys/time.h>
#endif

#if defined(unix)
extern int sys_nerr;
extern char *sys_errlist[];
#endif /* unix */

#include "tclInt.h"

#if !defined(FALSE)
# define FALSE 0
#endif

/*
 * Library imports:
 */


/*
 *----------------------------------------------------------------------
 *
 * Tcl_IfCmd --
 *
 *	This procedure is invoked to process the "if" Tcl command.
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

static const Tcl_SubCommandRec ifCmds[] = {
    {TCL_CMD_ANY, 0, 1, TCL_CMD_NOCHECK,
      "<expr> [then] <truebody> (elif <expr> <truebody>)* [[else] <falsebody>]"
    },
    {TCL_CMD_END}
};


DEFCMD(if,Tcl_If,TCL_EXACT,ifCmds,swat_prog.tcl.conditional,
"Usage:\n\
    if <expr> [then] <truebody> (elif <expr> <truebody>)* [[else] <falsebody>]\n\
\n\
Examples:\n\
    \"if {$v > 3} {echo yes} {echo no}\"	Prints \"yes\" if $v is greater than\n\
					3, else it prints \"no\".\n\
    \"if {$v > 3} then {echo yes} else {echo no}\"    Ditto.\n\
    \"if {$v > 3} then {echo yes} elif {$v == 3} {echo maybe} else {echo no}\"\n\
\n\
Synopsis:\n\
    This is Tcl's conditional, as you'd expect from its name.\n\
\n\
Notes:\n\
    * The \"then\" and \"else\" keywords are optional, intended to delineate the\n\
      different sections of the command and make the whole easier to read.\n\
\n\
    * The \"elif\" keyword is *mandatory*, however, if you want to perform\n\
      additional tests.\n\
\n\
    * The <expr> arguments are normal Tcl expressions. If the result is\n\
      non-zero, the appropriate <truebody> is executed. If none of the <expr>\n\
      arguments evaluates non-zero, <falsebody> is executed.\n\
\n\
    * If a <truebody> is empty and the test evaluated non-zero, \"if\" will\n\
      return the result of the test. Otherwise \"if\" returns the result from\n\
      last command executed in whichever <truebody> or <falsebody> argument\n\
      was finally executed. It returns an empty string if no <expr> evaluated\n\
      non-zero and no <falsebody> was given.\n\
\n\
See also:\n\
    expr.\n\
")
{
    const char *condition, *cmd, *name;
    int result, value;


    name = argv[0];

    condition = argv[1];
    cmd = argv[2];
    if ((*cmd == 't') && (strcmp(cmd, "then") == 0)) {
	/*
	 * Use arg after "then"
	 */
	argc--;
	argv++;
	cmd = argv[2];
    }
    argc -= 3;
    argv += 3;
    if (argc < 0) {
	return(TCL_SUBUSAGE);
    }

    /*
     * Loop through the if/elif clauses looking for one whose condition is
     * true. If none found but there's an else clause, use that. When we
     * exit the loop, cmd points to the command to execute.
     */
    while (1) {
	/*
	 * Evaluate this condition.
	 */
	result = Tcl_Expr(interp, condition, &value);
	/*
	 * If error in condition, return that and its error message
	 */
	if (result != TCL_OK) {
	    return result;
	}
	/*
	 * If condition TRUE, break out now with cmd set properly
	 */
	if (value) {
	    break;
	}
	if (argc == 0) {
	    /*
	     * Ran out of conditions and clauses -- return OK, since it is.
	     */
	    return(TCL_OK);
	} else if ((**argv == 'e') && (strcmp(*argv, "elif") == 0)) {
	    /*
	     * Usage is "elif condition [then] command" so argc must be at
	     * least 3.
	     */
	    if (argc < 3) {
		return (TCL_SUBUSAGE);
	    } else {
		/*
		 * Set up condition for next iteration and cmd in case it's
		 * true.
		 */
		condition = argv[1];
		cmd = argv[2];
		if ((*cmd == 't') && (strcmp(cmd, "then") == 0)) {
		    argv++;
		    argc--;
		    cmd = argv[2];
		    if (argc < 3) {
			return (TCL_SUBUSAGE);
		    }
		}
		argv += 3;
		argc -= 3;
	    }
	} else {
	    if ((**argv == 'e') && (strncmp(*argv, "else", strlen(*argv))==0))
	    {
		/*
		 * Skip optional ELSE keyword
		 */
		argc--;
		argv++;
	    }
	    /*
	     * Should only be the ELSE clause left. If no command after ELSE
	     * keyword (argc now 0 but wasn't before) or there's something
	     * after the ELSE clause, complain.
	     */
	    if (argc != 1) {
		return (TCL_SUBUSAGE);
	    }
	    /*
	     * Use else clause and get out of here.
	     */
	    cmd = *argv;
	    argc--;
	    break;
	}
    }

    /*
     * Evaluate final command and return the result. If the final command
     * is empty and it's not the ELSE clause for the IF, assume the caller
     * wants to return the value of the expression.
     */
    if ((*cmd == '\0') && argc != 0) {
	Tcl_RetPrintf(interp, "%d", value);
	return(TCL_OK);
    } else {
	return(Tcl_Eval(interp, cmd, 0, (const char **) NULL));
    }
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_IndexCmd --
 *
 *	This procedure is invoked to process the "index" Tcl command.
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

static const Tcl_SubCommandRec indexCmds[] = {
    {TCL_CMD_ANY, 0, 	    1, 2, "<list> <index> [chars]"},
    {TCL_CMD_END}
};

DEFCMD(index,Tcl_Index,TCL_EXACT,indexCmds,swat_prog.list|swat_prog.tcl|swat_prog.string,
"Usage:\n\
    index <list> <index>\n\
    index <string> <index> char\n\
\n\
Examples:\n\
    \"index {a b c} 1\"	    	Extracts \"b\" from the list.\n\
    \"index {hi mom} 3 char\" 	Extracts \"m\" from the string.\n\
\n\
Synopsis:\n\
    \"index\" is used to retrieve a single element or character from a list\n\
    or string.\n\
\n\
Notes:\n\
    * Elements and characters are numbered from 0.\n\
\n\
    * If you request an element or character from beyond the end of the <list>\n\
      or <string>, you'll receive an empty list or string as a result.\n\
\n\
See also:\n\
    range.\n\
")
{
    const char *p, *element;
    int index, size, parenthesized, result;
    char *res;

    p = argv[1];
    index = atoi(argv[2]);
    if (!isdigit(*argv[2]) || (index < 0)) {
	badIndex:
	Tcl_RetPrintf(interp, "bad index \"%.50s\"", argv[2]);
	return TCL_ERROR;
    }
    if (argc == 3) {
	for ( ; index >= 0; index--) {
	    result = TclFindElement(interp, p, &element, &p, &size,
		    &parenthesized);
	    if (result != TCL_OK) {
		return result;
	    }
	}
	if (size >= TCL_RESULT_SIZE) {
	    res = (char *)malloc((unsigned)size+1);
	    Tcl_Return(interp, res, TCL_DYNAMIC);
	} else {
	    res = (char *)( ((Interp *)interp)->resultSpace );
	    Tcl_Return(interp, res, TCL_STATIC);
	}
	if (parenthesized) {
	    bcopy(element, res, size);
	    res[size] = '\0';
	} else {
	    TclCopyAndCollapse(size, element, res);
	}
    } else if ((argc == 4) &&
	       (strncmp(argv[3], "chars", strlen(argv[3])) == 0))
    {
	size = strlen(p);
	if (index >= size) {
	    goto badIndex;
	}
	Tcl_Return(interp, NULL, TCL_STATIC);
	res = (char *)interp->result;
	res[0] = p[index];
	res[1] = '\0';
    } else {
	return (TCL_SUBUSAGE);
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_InfoCmd --
 *
 *	This procedure is invoked to process the "info" Tcl command.
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

#define INFO_ARGS   	(ClientData)0
#define INFO_BODY   	(ClientData)1
#define INFO_CMDCOUNT	(ClientData)2
#define INFO_COMMANDS	(ClientData)3
#define INFO_DEFAULT	(ClientData)4
#define INFO_GLOBALS	(ClientData)5
#define INFO_LOCALS 	(ClientData)6
#define INFO_PROCS   	(ClientData)7
#define INFO_VARS   	(ClientData)8
#define INFO_ARGLIST	(ClientData)9
static const Tcl_SubCommandRec infoCmds[] = {
    {"args", 	INFO_ARGS,  	1, 2, "<procname> [<pattern>]"},
    {"arglist",	INFO_ARGLIST,	1, 1, "<procname>"},
    {"body", 	INFO_BODY,  	1, 1, "<procname>"},
    {"cmdcount",	INFO_CMDCOUNT,	0, 0, ""},
    {"commands",	INFO_COMMANDS,	0, 1, "[<pattern>]"},
    {"default",	INFO_DEFAULT,	3, 3, "<procname> <arg> <varname>"},
    {"globals",	INFO_GLOBALS,	0, 1, "[<pattern>]"},
    {"locals",	INFO_LOCALS,	0, 1, "[<pattern>]"},
    {"procs",	INFO_PROCS, 	0, 1, "[<pattern>]"},
    {"vars", 	INFO_VARS,   	0, 1, "[<pattern>]"},
    {TCL_CMD_END}
};


DEFCMD(info,Tcl_Info,TCL_EXACT,infoCmds,swat_prog.tcl,
"Usage:\n\
    info args <procname> [<pattern>]\n\
    info arglist <procname>\n\
    info body <procname>\n\
    info cmdcount \n\
    info commands [<pattern>]\n\
    info default <procname> <arg> <varname>\n\
    info globals [<pattern>]\n\
    info locals [<pattern>]\n\
    info procs [<pattern>]\n\
    info vars [<pattern>]\n\
\n\
Examples:\n\
    \"info args fmtval\"	    Retrieves the names of the arguments for the\n\
			    \"fmtval\" command so you know in what order to\n\
			    pass things.\n\
    \"info body print-frame\" Retrieves the string that is the body of the\n\
			    \"print-frame\" Tcl procedure.\n\
    \"info commands *reg*\"   Retrieves a list of commands whose names contain\n\
			    the string \"reg\"\n\
\n\
Synopsis:\n\
    This command provides information about a number of data structures\n\
    maintained by the Tcl interpreter.\n\
\n\
Notes:\n\
    * All the <pattern> arguments are standard wildcard patterns as are used\n\
      for the \"string match\" and \"case\" commands. See \"string\" for a description\n\
      of these patterns.\n\
\n\
    * \"info args\" returns the complete list of arguments for a Tcl procedure,\n\
      or only those matching the <pattern>, if one is given. The arguments\n\
      are returned in the order in which they must be passed to the procedure.\n\
\n\
    * \"info arglist\" returns the complete list of arguments, and their default\n\
      values, for a Tcl procedure.\n\
\n\
    * \"info body\" returns the command string that is the body of the given\n\
      Tcl procedure.\n\
\n\
    * \"info cmdcount\" returns the total number of commands the Tcl interpreter\n\
      has executed in its lifetime.\n\
\n\
    * \"info commands\" returns the list of all known commands, either built-in\n\
      or as Tcl procedures, known to the interpreter. You may also specify a\n\
      pattern to restrict the commands to those whose names match the pattern.\n\
\n\
    * \"info default\" returns non-zero if the argument named <arg> for the\n\
      given Tcl procedure has a default value. If it does, that default value\n\
      is stored in the variable whose name is <varname>.\n\
\n\
    * \"info globals\" returns the list of all global variables accessible within\n\
      the current variable scope (i.e. only those that have been declared global\n\
      with the \"global\" command, unless you issue this command from the command-\n\
      line, which is at the global scope), or those that match the given\n\
      pattern.\n\
\n\
    * \"info locals\" returns the list of all local variables, or those that match\n\
      the given pattern.\n\
\n\
    * \"info procs\" returns the list of all known Tcl procedures, or those that\n\
      match the given pattern.\n\
\n\
    * \"info vars\" returns the list of all known Tcl variables in the current\n\
      scope, either local or global. You may also give a pattern to restrict the\n\
      list to only those that match.\n\
\n\
See also:\n\
    proc, defcmd, defcommand, defsubr.\n\
")
{
    register Interp *iPtr = (Interp *) interp;
    Proc *procPtr;          /* Info for procedure being processed */
    Var *varPtr = NULL;     /* Current global/local variable being processed */
    Command *cmdPtr = NULL; /* Current command-chain element being processed */
    int cmdIndex = 0;       /* Index of next chain to process */

    /*
     * When collecting a list of things (e.g. args or vars) "flag" tells
     * what kind of thing is being collected, according to the definitions
     * below.
     */

    enum {
	VARS, LOCALS, PROCS, CMDS, VARLIST
    } flag = VARS;

#   define ARG_SIZE 20
    char *argSpace[ARG_SIZE];
    int argSize;
    char *pattern;

    pattern = NULL;

    switch ((int)clientData) {
	case (int)INFO_ARGS:
	    procPtr = TclFindProc(iPtr, argv[2]);
	    if (procPtr == NULL) {
		infoNoSuchProc:
		Tcl_RetPrintf(interp,
			      "info requested on \"%s\", which isn't a procedure",
			      argv[2]);
		return TCL_ERROR;
	    }
	    flag = VARS;
	    varPtr = procPtr->argPtr;
	    pattern = argv[3];
	    break;
	case (int)INFO_ARGLIST:
	    procPtr = TclFindProc(iPtr, argv[2]);
	    if (procPtr == NULL) {
		goto infoNoSuchProc;
	    }
	    flag = VARLIST;
	    varPtr = procPtr->argPtr;
	    break;
	case (int)INFO_BODY:
	    procPtr = TclFindProc(iPtr, argv[2]);
	    if (procPtr == NULL) {
		goto infoNoSuchProc;
	    }
	    Tcl_Return(interp, procPtr->command, TCL_STATIC);
	    return TCL_OK;
	case (int)INFO_CMDCOUNT:
	    Tcl_RetPrintf(interp, "%d", iPtr->cmdCount);
	    return TCL_OK;
	case (int)INFO_DEFAULT:
	    procPtr = TclFindProc(iPtr, argv[2]);
	    if (procPtr == NULL) {
		goto infoNoSuchProc;
	    }
	    for (varPtr = procPtr->argPtr;
		 varPtr != NULL;
		 varPtr = varPtr->nextPtr)
	    {
		if (strcmp(argv[3], varPtr->name) == 0) {
		    if (varPtr->value != NULL) {
			Tcl_SetVar((Tcl_Interp *) iPtr, argv[4], varPtr->value, 0);
			Tcl_Return(interp, "1", TCL_STATIC);
		    } else {
			Tcl_SetVar((Tcl_Interp *) iPtr, argv[4], "", 0);
			Tcl_Return(interp, "0", TCL_STATIC);
		    }
		    return TCL_OK;
		}
	    }
	    Tcl_RetPrintf(interp,
			  "procedure \"%s\" doesn't have an argument \"%s\"",
			  argv[2], argv[3]);
	    return TCL_ERROR;
	case (int)INFO_GLOBALS:
	    flag = VARS;
	    varPtr = iPtr->globalFrame.vars;
	    pattern = argv[2];
	    break;
	case (int)INFO_LOCALS:
	    flag = LOCALS;
	    varPtr = iPtr->top->localPtr->vars;
	    pattern = argv[2];
	    break;
	case (int)INFO_PROCS:
	    flag = PROCS;
	    cmdIndex = 0;
	    cmdPtr = NULL;
	    pattern = argv[2];
	    break;
	case (int)INFO_COMMANDS:
	    flag = CMDS;
	    cmdIndex = 0;
	    cmdPtr = NULL;
	    pattern = argv[2];
	    break;
	case (int)INFO_VARS:
	    flag = VARS;
	    varPtr = iPtr->top->localPtr->vars;
	    pattern = argv[2];
	    break;
    }

    /*
     * At this point we have to assemble a list of something or other.
     * Collect them in an expandable argv-argc array.
     */

    argv = argSpace;
    argSize = ARG_SIZE;
    argc = 0;
    while (1) {
	/*
	 * Increase the size of the argument array if necessary to
	 * accommodate another string.
	 */
	char *name;

	if (argc == argSize) {
	    argSize *= 2;
	    if (argv != argSpace) {
		argv = (char **) realloc((char *)argv,
					 (unsigned) argSize*sizeof(char *));
	    } else {
		argv = (char **) malloc((unsigned) argSize*sizeof(char *));
		bcopy((char *) argSpace, (char *)argv, argc*sizeof(char *));
	    }
	}

	if (flag == VARLIST) {
	    if (varPtr == NULL) {
		/*
		 * End of list -- get out of here.
		 */
		break;
	    }
	    
	    if (varPtr->valueLength != 0) {
		/*
		 * Has default -- form list of variable's name and value.
		 */
		char *vargv[2];
		
		vargv[0] = varPtr->name;
		vargv[1] = varPtr->value;

		name = Tcl_Merge(2, vargv);
	    } else {
		/*
		 * No default -- just copy the arg's name so we don't need
		 * to worry about whether it should be freed or not down
		 * below.
		 */
		int len = strlen(varPtr->name);
		
		name = (char *)malloc(len+1);
		bcopy(varPtr->name, name, len+1);
	    }
	    varPtr = varPtr->nextPtr;
	} else if (flag == PROCS || flag == CMDS) {
	    /*
	     * If we exhausted the previous chain, start with the next one.
	     */
	    while ((cmdPtr == NULL) && (cmdIndex < TCL_CMD_CHAINS)) {
		cmdPtr = iPtr->commands[cmdIndex++];
	    }

	    if (flag == PROCS) {
		while (cmdIndex < TCL_CMD_CHAINS) {
		    for ( ; cmdPtr != NULL; cmdPtr = cmdPtr->nextPtr) {
			if (TclIsProc(cmdPtr)) {
			    break;
			}
		    }
		    if ((cmdPtr == NULL) && (cmdIndex < TCL_CMD_CHAINS)) {
			/*
			 * No more procs in that chain, so advance to the
			 * next one.
			 */
			cmdPtr = iPtr->commands[cmdIndex++];
		    } else {
			break;
		    }
		}
	    }
	    if (cmdPtr == NULL) {
		break;
	    }
	    name = cmdPtr->name;
	    cmdPtr = cmdPtr->nextPtr;
	} else {
	    if (flag == LOCALS) {
		for ( ; varPtr != NULL; varPtr = varPtr->nextPtr) {
		    if (!(varPtr->flags & VAR_GLOBAL)) {
			break;
		    }
		}
	    }
	    if (varPtr == NULL) {
		break;
	    }
	    name = varPtr->name;
	    varPtr = varPtr->nextPtr;
	}
	if (!pattern || Tcl_StringMatch(name, pattern)) {
	    argv[argc] = (char *)name;
	    argc++;
	}
    }

    Tcl_Return(interp, Tcl_Merge(argc, argv), TCL_DYNAMIC);
    if (flag == VARLIST) {
	/*
	 * Free dynamically-allocated names.
	 */
	while (argc-- > 0) {
	    free(argv[argc]);
	}
    }
    if (argv != argSpace) {
	free((char *) argv);
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_LengthCmd --
 *
 *	This procedure is invoked to process the "length" Tcl command.
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
static const Tcl_SubCommandRec lengthCmds[] = {
    {TCL_CMD_ANY, 0, 	    0, 1, "<list> [chars]"},
    {TCL_CMD_END}
};


DEFCMD(length,Tcl_Length,TCL_EXACT,lengthCmds,swat_prog.list|swat_prog.string|swat_prog.tcl.list,
"Usage:\n\
    length <list>\n\
    length <string> char\n\
\n\
Examples:\n\
    \"length $args\"	Returns the number of elements in the list $args\n\
    \"length $str char\"	Returns the number of characters in the string $str\n\
\n\
Synopsis:\n\
    Determines the number of characters in a string, or elements in a list.\n\
\n\
See also:\n\
    index, range.\n\
")
{
    int count;
    const char *p;

    p = argv[1];
    if (argc == 2) {
	const char *element;
	int result;

	for (count = 0; *p != 0 ; count++) {
	    result = TclFindElement(interp, p, &element, &p, (int *) NULL,
		    (int *) NULL);
	    if (result != TCL_OK) {
		return result;
	    }
	    if (*element == 0) {
		break;
	    }
	}
    } else if ((argc == 3)
	    && (strncmp(argv[2], "chars", strlen(argv[2])) == 0)) {
	count = strlen(p);
    } else {
	return (TCL_SUBUSAGE);
    }
    Tcl_RetPrintf(interp, "%d", count);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_ListCmd --
 *
 *	This procedure is invoked to process the "list" Tcl command.
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

static const Tcl_SubCommandRec listCmds[] = {
    {TCL_CMD_ANY, 0, 	    0, TCL_CMD_NOCHECK, "<arg>+"},
    {TCL_CMD_END}
};


DEFCMD(list,Tcl_List,TCL_EXACT,listCmds,swat_prog.list|swat_prog.tcl.list,
"Usage:\n\
    list <arg>+\n\
\n\
Examples:\n\
    \"list a b {c d e} {f {g h}}\"	Returns the list\n\
					\"a b {c d e} {f {g h}}\"\n\
\n\
Synopsis:\n\
    Joins any number of arguments into a single list, applying quoting\n\
    braces and backslashes as necessary to form a valid Tcl list.\n\
\n\
Notes:\n\
    * If you use the \"index\" command on the result, the 0th element will be\n\
      the first argument that was passed, the 1st element will be the second\n\
      argument that was passed, etc.\n\
\n\
    * The difference between this command and the \"concat\" command is subtle.\n\
      Given the above arguments, \"concat\" would return \"a b c d e f {g h}\"\n\
\n\
See also:\n\
    concat, index, range.\n\
")
{
    Tcl_Return(interp, Tcl_Merge(argc-1, argv+1), TCL_DYNAMIC);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_ProtectCmd --
 *
 *	This procedure is invoked to process the "protect" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result -- from the main command (arg 1).
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */
static const Tcl_SubCommandRec protectCmds[] = {
    {TCL_CMD_ANY, 0, 	    1, 1, "<body> <cleanup>"},
    {TCL_CMD_END}
};

DEFCMD(protect,Tcl_Protect,TCL_EXACT,protectCmds,swat_prog.tcl.error,
"Usage:\n\
    protect <body> <cleanup>\n\
\n\
Examples:\n\
    \"protect {\n\
	var s [stream open $file w]\n\
	# do stuff with the stream\n\
     } {\n\
	catch {stream close $s}\n\
     }\"	    	    	    	Perform some random operations on a file\n\
				making sure the stream gets closed, even if\n\
				the user types control-C.\n\
\n\
Synopsis:\n\
    Allows one to ensure that clean-up for a sequence of commands will always\n\
    happen, even if the user types control-C to interrupt the command.\n\
\n\
Notes:\n\
    * Since the interrupt can come at any time during the <body>, the <cleanup>\n\
      command string should not rely on any particular variables being set.\n\
      Hence the \"catch\" command used in the <cleanup> clause of the example.\n\
\n\
    * The <cleanup> clause will also be executed if any command in the <body>\n\
      generates an error.\n\
\n\
See also:\n\
    catch.\n\
")
{
    Frame   *frame; 	    	    	/* Current frame */
    Interp  *iPtr = (Interp *)interp;	/* Internal version of interpreter */
    int	    result; 	    	    	/* Result code */
    char    *value; 	    	    	/* Result value */
    int	    dynamic;	    	    	/* Non-zero if our return value is
					 * dynamically-allocated */

    /*
     * Set up the protected command for the current frame.
     */
    frame = iPtr->top;
    frame->protect = argv[2];
    frame->psize = 0;
    
    /*
     * Evaluate the main command and save its result.
     */
    result = Tcl_Eval(interp, argv[1], 0, 0);

    /*
     * Save pointer to/duplicate result as necessary to preserve it from
     * the evaluation of the protected command
     */
    if (iPtr->dynamic || (iPtr->result != (const char *)iPtr->resultSpace)) {
	value = (char *)iPtr->result;
	dynamic = iPtr->dynamic;
    } else {
	int 	len = strlen(iPtr->result);

	value = (char *)malloc(len+1);
	bcopy(iPtr->result, value, len+1);
	dynamic = 1;
    }

    /*
     * Reset return value for evaluating the protected command
     */
    iPtr->dynamic = 0;
    iPtr->result = iPtr->resultSpace;

    frame->protect = 0;
    
    /*
     * Evaluate the protected command and blow away its return value
     */
    (void)Tcl_Eval(interp, argv[2], 0, 0);
    if (iPtr->dynamic) {
	free((malloc_t)iPtr->result);
    }

    /*
     * Return value of main command
     */
    iPtr->result = value;
    iPtr->dynamic = dynamic;
    return(result);
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_RangeCmd --
 *
 *	This procedure is invoked to process the "range" Tcl command.
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

static const Tcl_SubCommandRec rangeCmds[] = {
    {TCL_CMD_ANY, 0, 	    2, 3, "<list> <start> <end> [chars]"},
    {TCL_CMD_END}
};

DEFCMD(range,Tcl_Range,TCL_EXACT,rangeCmds,swat_prog.list|swat_prog.string|swat_prog.tcl.list,
"Usage:\n\
    range <list> <start> <end>\n\
    range <string> <start> <end> char\n\
\n\
Examples:\n\
    \"range {a b c} 1 end\"	Returns {b c} (element 1 to the end)\n\
    \"range {hi mom} 3 end chars\"  	Returns \"mom\"\n\
\n\
Synopsis:\n\
    Extracts a range of characters from a string, or elements from a list.\n\
\n\
Notes:\n\
    * If you give an ending index that is greater than the number of elements in\n\
      the list (characters in the string), it will be adjusted to be the index\n\
      of the last element (character).\n\
\n\
    * If you give a starting index that is greater than the number of elements\n\
      in the list (characters in the string), the result will be the empty list\n\
      (string).\n\
\n\
    * You can give <end> as \"end\" (without the quotation marks, of course) to\n\
      indicate the extraction should go to the end of the list (string).\n\
\n\
    * The range is inclusive, so \"range {a b c} 0 0\" returns \"a\".\n\
\n\
    * Neither index may be less than 0 or \"range\" will generate an error.\n\
\n\
See also:\n\
    index\n\
")
{
    int first, last, result;
    const char *begin, *end;
    char c;
    const char *dummy;
    int count;

    first = atoi(argv[2]);
    if (!isdigit(*argv[2]) || (first < 0)) {
	Tcl_RetPrintf(interp, "bad range specifier \"%.50s\"", argv[2]);
	return TCL_ERROR;
    }
    if ((*argv[3] == 'e') && (strncmp(argv[3], "end", strlen(argv[3])) == 0)) {
	last = -1;
    } else {
	last = atoi(argv[3]);
	if (!isdigit(*argv[3]) || (last < 0)) {
	    Tcl_RetPrintf(interp, "bad range specifier \"%.50s\"", argv[3]);
	    return TCL_ERROR;
	}
    }

    if (argc == 5) {
	count = strlen(argv[4]);
	if ((count == 0) || (strncmp(argv[4], "chars", count) != 0)) {
	    return (TCL_SUBUSAGE);
	}

	/*
	 * Extract a range of characters.
	 */

	count = strlen(argv[1]);
	if (first >= count) {
	    Tcl_Return(interp, NULL, TCL_STATIC);
	    return TCL_OK;
	}
	begin = argv[1] + first;
	if ((last == -1) || (last >= count)) {
	    /*
	     * Use count-1 to account for "last + 1" below, else we point
	     * beyond the string's end, which can cause a segfault if the
	     * string's null byte is the final byte of the process' address
	     * space (don't laugh, it happened).
	     */
	    last = count-1;
	} else if (last < first) {
	    Tcl_Return(interp, NULL, TCL_STATIC);
	    return TCL_OK;
	}
	end = argv[1] + last + 1;
    } else {
	/*
	 * Extract a range of fields.
	 */

	for (count = 0, begin = argv[1]; count < first; count++) {
	    result = TclFindElement(interp, begin, &dummy, &begin, (int *) NULL,
		    (int *) NULL);
	    if (result != TCL_OK) {
		return result;
	    }
	    if (*begin == 0) {
		break;
	    }
	}
	if (last == -1) {
	    Tcl_Return(interp, begin, TCL_VOLATILE);
	    return TCL_OK;
	}
	if (last < first) {
	    Tcl_Return(interp, NULL, TCL_STATIC);
	    return TCL_OK;
	}
	for (count = first, end = begin; (count <= last) && (*end != 0);
		count++) {
	    result = TclFindElement(interp, end, &dummy, &end, (int *) NULL,
		    (int *) NULL);
	    if (result != TCL_OK) {
		return result;
	    }
	}
	/*
	 * Trim off any trailing spaces
	 */
	while(isspace(*--end)) {
	    ;
	}
	end++;
    }
    c = *end;
    *(char *)end = 0;
    Tcl_Return(interp, begin, TCL_VOLATILE);
    *(char *)end = c;
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_ReturnCmd --
 *
 *	This procedure is invoked to process the "return" Tcl command.
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
DEFCMD(return,Tcl_Return,TCL_EXACT,NULL,swat_prog.proc,
"Usage:\n\
    return [<string>]\n\
\n\
Examples:\n\
    \"return $val\"	Returns the string in $val as the value for the current\n\
			Tcl procedure.\n\
\n\
Synopsis:\n\
    Causes an immediate return from the current Tcl procedure, with or without\n\
    a value.\n\
\n\
Notes:\n\
    * Every Tcl procedure returns a string for a value. If the procedure was\n\
      called via command substitution (having been placed between square\n\
      brackets as the argument to another command), the return value takes\n\
      the place of the command invocation.\n\
\n\
    * Execution of the current procedure terminates immediately, though any\n\
      <cleanup> clause for a containing \"protect\" command will still be\n\
      executed.\n\
\n\
    * If no \"return\" command is invoked within a Tcl procedure, the procedure\n\
      returns the empty string by default.\n\
\n\
See also:\n\
    error, proc, defsubr, defcommand, defcmd.\n\
")
{
    if (argc > 2) {
	Tcl_RetPrintf(interp,
		      "Usage: %.50s [<value>]",
		      argv[0]);
	return TCL_ERROR;
    }
    if (argc == 2) {
	Tcl_Return(interp, argv[1], TCL_VOLATILE);
    }
    return TCL_RETURN;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_ScanCmd --
 *
 *	This procedure is invoked to process the "scan" Tcl command.
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

static const Tcl_SubCommandRec scanCmds[] = {
    {TCL_CMD_ANY, 0, 1, TCL_CMD_NOCHECK, "<string> <format> <varName>*"},
    {TCL_CMD_END}
};

DEFCMD(scan,Tcl_Scan,TCL_EXACT,scanCmds,swat_prog.string,
"Usage:\n\
    scan <string> <format> <varName>*\n\
\n\
Examples:\n\
    \"scan $input {my name is %s} name\"	Trims the leading string \"my name is \"\n\
					from the string in $input and stores\n\
					the rest of the string within the\n\
					variable $name\n\
\n\
Synopsis:\n\
    \"scan\" parses fields from an input string, given the string and a format\n\
    string that defines the various types of fields. The fields are assigned\n\
    to variables within the caller's scope.\n\
\n\
Notes:\n\
    * The <format> string consists of literal text, which must be matched\n\
      explicitly, and field definitions. The <varName> arguments are names\n\
      of variables to which each successive field value is assigned.\n\
\n\
    * A single whitespace character (space or tab) will match any number\n\
      of whitespace characters in the input string.\n\
\n\
    * Fields are specified as for the standard C library routine \"sscanf\":\n\
	%c  	A single character. The field value stored is the decimal\n\
		number of the ASCII code for the character scanned. So if\n\
		the character were a space, the variable would receive the\n\
		string \"32\".\n\
	%d	A signed decimal integer is parsed and stored.\n\
	%o	An octal integer is parsed and stored, as a decimal number.\n\
	%x	A hexadecimal integer is parsed and stored, as a decimal number.\n\
	%i	A signed integer, following the standard C radix-specification\n\
		standard, is parsed and stored as a decimal number.\n\
	%f  	A floating-point number is parsed as a \"float\" and stored\n\
		without exponent, unless the exponent is less than -4.\n\
	%s  	A whitespace-terminated string is parsed and stored.\n\
	%[<char-class>]\n\
		A string consisting only of the characters in the given\n\
		character class (see \"string match\" for details on character\n\
		classes) is parsed and stored. The normal leading-whitespace\n\
		skipping is suppressed.\n\
	%%  	Matches a single percent sign in the input.\n\
\n\
    * If the % of a field specifier is followed by an *, the field is parsed\n\
      as usual, consuming characters from the string, but the result is not\n\
      stored anywhere and you should not specify a variable to receive the\n\
      value.\n\
\n\
    * The maximum length of a field may be specified by giving a decimal number\n\
      between the % and the field-type character. So \"%10s\" will extract out\n\
      a string of at most 10 characters.\n\
\n\
    * There is currently a limit of 5 fields.\n\
\n\
See also:\n\
    format\n\
")
{
    int arg1Length;			/* Number of bytes in argument to be
					 * scanned.  This gives an upper limit
					 * on string field sizes. */
#   define MAX_FIELDS 5
    typedef struct {
	char fmt;			/* Format for field. */
	int size;			/* How many bytes to allow for
					 * field. */
	char *location;			/* Where field will be stored. */
    } Field;
    Field fields[MAX_FIELDS];		/* Info about all the fields in the
					 * format string. */
    register Field *curField;
    int numFields = 0;			/* Number of fields actually
					 * specified. */
    int suppress;			/* Current field is assignment-
					 * suppressed. */
    int totalSize = 0;			/* Number of bytes needed to store
					 * all results combined. */
    char *results;			/* Where scanned output goes.  */
    int numScanned = 0;   		/* sscanf's result. */
    register char *fmt;
    int i;

    if (argc < 3) {
	Tcl_RetPrintf(interp,
		      "too few args: should be \"%.50s string format varName ...\"",
		      argv[0]);
	return TCL_ERROR;
    }

    /*
     * This procedure operates in three stages:
     * 1. Scan the format string, collecting information about each field.
     * 2. Allocate an array to hold all of the scanned fields.
     * 2. Call sscanf to do all the dirty work, and have it store the
     *    parsed fields in the array.
     * 3. Pick off the fields from the array and assign them to variables.
     */

    arg1Length = (strlen(argv[1]) + 4) & ~03;
    for (fmt = argv[2]; *fmt != 0; fmt++) {
	if (*fmt != '%') {
	    continue;
	}
	fmt++;
	if (*fmt == '*') {
	    suppress = 1;
	    fmt++;
	} else {
	    suppress = 0;
	}
	while (isdigit(*fmt)) {
	    fmt++;
	}
	if (suppress) {
	    continue;
	}
	if (numFields == MAX_FIELDS) {
	    Tcl_RetPrintf(interp,
			  "can't have more than %d fields in \"%.50s\"", MAX_FIELDS,
			  argv[0]);
	    return TCL_ERROR;
	}
	curField = &fields[numFields];
	numFields++;
	switch (*fmt) {
	    case 'D':
	    case 'O':
	    case 'X':
	    case 'd':
	    case 'o':
	    case 'x':
		curField->fmt = 'd';
		curField->size = sizeof(int);
		break;

	    case 's':
		curField->fmt = 's';
		curField->size = arg1Length;
		break;

	    case 'c':
		curField->fmt = 'c';
		curField->size = sizeof(int);
		break;

	    case 'E':
	    case 'F':
		curField->fmt = 'F';
		curField->size = 8;
		break;

	    case 'e':
	    case 'f':
		curField->fmt = 'f';
		curField->size = 4;
		break;

	    case '[':
		curField->fmt = 's';
		curField->size = arg1Length;
		do {
		    fmt++;
		} while (*fmt != ']');
		break;

	    default:
		Tcl_RetPrintf(interp, "bad scan conversion character \"%c\"",
			      *fmt);
		return TCL_ERROR;
	}
	totalSize += curField->size;
    }

    if (numFields != (argc-3)) {
	Tcl_Return(interp,
		   "different numbers of variable names and field specifiers",
		   TCL_STATIC);
	return TCL_ERROR;
    }

    /*
     * Step 2:
     */

    results = (char *) malloc((unsigned) totalSize);
    for (i = 0, totalSize = 0, curField = fields;
	 i < numFields;
	 i++, curField++)
    {
	curField->location = results + totalSize;
	totalSize += curField->size;
    }

    /*
     * Step 3:
     */

    switch(numFields) {
    case 0:
	numScanned = 0;
	break;
    case 1:
	numScanned = sscanf(argv[1], argv[2], fields[0].location);
	break;
    case 2:
	numScanned = sscanf(argv[1], argv[2], fields[0].location,
			    fields[1].location);
	break;
    case 3:
	numScanned = sscanf(argv[1], argv[2], fields[0].location,
			    fields[1].location, fields[2].location);
	break;
    case 4:
	numScanned = sscanf(argv[1], argv[2], fields[0].location,
			    fields[1].location, fields[2].location,
			    fields[3].location);
	break;
    case 5:
	numScanned = sscanf(argv[1], argv[2], fields[0].location,
			    fields[1].location, fields[2].location,
			    fields[3].location, fields[4].location);
	break;
	/* IF YOU INCREASE MAX_FIELDS, ADD MORE CASES HERE */
    }

    /*
     * Step 4:
     */

    if (numScanned < numFields) {
	numFields = numScanned;
    }
    for (i = 0, curField = fields; i < numFields; i++, curField++) {
	switch (curField->fmt) {
	    char string[30];

	    case 'd':
		sprintf(string, "%d", *((int *) curField->location));
		Tcl_SetVar(interp, argv[i+3], string, 0);
		break;

	    case 'c':
		sprintf(string, "%d", *((char *) curField->location) & 0xff);
		Tcl_SetVar(interp, argv[i+3], string, 0);
		break;

	    case 's':
		Tcl_SetVar(interp, argv[i+3], curField->location, 0);
		break;

	    case 'F':
		sprintf(string, "%g", *((double *) curField->location));
		Tcl_SetVar(interp, argv[i+3], string, 0);
		break;

	    case 'f':
		sprintf(string, "%g", *((float *) curField->location));
		Tcl_SetVar(interp, argv[i+3], string, 0);
		break;
	}
    }
    free(results);
    Tcl_RetPrintf(interp, "%d", numScanned);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_SourceCmd --
 *
 *	This procedure is invoked to process the "source" Tcl command.
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

static const Tcl_SubCommandRec sourceCmds[] = {
    {TCL_CMD_ANY, 0, 	    0, 0, "<file>"},
    {TCL_CMD_END}
};

DEFCMD(source,Tcl_Source,TCL_EXACT,sourceCmds,
       swat_prog.load|swat_prog.file,
"Usage:\n\
    source <file>\n\
\n\
Examples:\n\
    \"source coolness\"	    Evaluates all commands within the file\n\
			    \"coolness.tcl\" in the current directory.\n\
\n\
Synopsis:\n\
    Reads and evaluates commands from a file.\n\
\n\
Notes:\n\
    * If <file> has no extension and doesn't exist, \"source\" will append \".tcl\"\n\
      to the end and try and read that file.\n\
\n\
See also:\n\
    none.\n\
")
{
    FileType fileId;
    int result;
    char *cmdBuffer;
    unsigned long fileSize;
    int returnCode;
    int bytesRead = 0;

#if defined(_MSDOS) || defined(_WIN32)
    char    *mappedName;
    int	    len;
    char    *src, *dest;
#else
    struct stat statBuf;
#endif

    if (argc != 2) {
	Tcl_Return(interp, "Usage: source <file>", TCL_STATIC);
	return TCL_ERROR;
    }
#if defined(_MSDOS) || defined(_WIN32)
    /*
     * Map forward slashes to backward slashes for DOS...allocate enough
     * room to append .tcl if need be...
     */
    len = strlen(argv[1]);
    mappedName = (char *)malloc(len+4+1);
    src = argv[1];
    dest = mappedName;
    while (*src != '\0') {
	if (*src == '/') {
	    *dest++ = '\\';
	    src += 1;
	} else {
	    *dest++ = *src++;
	}
    }
    *dest = '\0';
    
    returnCode = FileUtil_Open(&fileId, mappedName, O_RDONLY|O_TEXT, 
			       SH_DENYWR, 0);
    if (returnCode == FALSE) {
	if ((len < 4) ||
	    (src[-1] != 'L' && src[-1] != 'l') ||
	    (src[-2] != 'C' && src[-2] != 'c') ||
	    (src[-3] != 'T' && src[-3] != 't') ||
	    (src[-4] != '.'))
	{
	    /*
	     * Doesn't already end in .tcl, so append that and try again.
	     */
	    strcpy(dest, ".TCL");
	    returnCode = FileUtil_Open(&fileId, mappedName, 
				       O_RDONLY|O_TEXT, SH_DENYWR, 0);
	}
	if (returnCode == FALSE) {
	    free((malloc_t)mappedName);
	    Tcl_RetPrintf(interp, "couldn't open file \"%.50s\"", argv[1]);
	    return TCL_ERROR;
	}
    }
    free((malloc_t)mappedName);
#else
    returnCode = FileUtil_Open(&fileId, argv[1], O_RDONLY|O_TEXT, 
			      SH_DENYWR, 0);
    if (returnCode == FALSE) {
	int 	  len = strlen(argv[1]);
	char	  *cp = argv[1] + len;

	if (*--cp != 'l' || *--cp != 'c' || *--cp != 't' || *--cp != '.') {
	    char *tclName = (char *)malloc(len+4+1);

	    sprintf(tclName, "%s.tcl", argv[1]);
	    returnCode = FileUtil_Open(&fileId, tclName, O_RDONLY|O_TEXT,
				      SH_DENYWR, 0);
	    free(tclName);
	}
	if (fileId < 0) {
	    Tcl_RetPrintf(interp, "couldn't open file \"%.50s\"", argv[1]);
	    return TCL_ERROR;
	}
    }
#endif
    fileSize = FileUtil_Seek(fileId, 0L, SEEK_END);
    if (fileSize == -1L) {
	char errmsg[512];

	FileUtil_SprintError(errmsg, "error seeking in file \"%.50s\"", 
			     argv[1]);
	Tcl_RetPrintf(interp, "%s", errmsg);
	(void)FileUtil_Close(fileId);
	return TCL_ERROR;
    }
    (void)FileUtil_Seek(fileId, 0L, SEEK_SET);
	
    cmdBuffer = (char *) malloc(fileSize+1);

    /* Don't check "read" return value against "fileSize" as CR-LF -> LF
     * compression will cause fewer bytes to be read... */
    returnCode = FileUtil_Read(fileId, cmdBuffer, fileSize, &bytesRead);
    if (returnCode == FALSE) {
	char errmsg[512];

	FileUtil_SprintError(errmsg, "error reading in file \"%.50s\"", 
			     argv[1]);
	Tcl_RetPrintf(interp, "%s", errmsg);
	(void)FileUtil_Close(fileId);
	free(cmdBuffer);
	return TCL_ERROR;
    }

    (void)FileUtil_Close(fileId);
    cmdBuffer[bytesRead] = '\0';
    result = Tcl_Eval(interp, cmdBuffer, 0, (const char **) NULL);
    free(cmdBuffer);
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_StringCmd --
 *
 *	This procedure is invoked to process the "string" Tcl command.
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

#define STRING_COMPARE	(ClientData)0
#define STRING_FIRST	(ClientData)1
#define STRING_LAST 	(ClientData)2
#define STRING_MATCH	(ClientData)3
#define STRING_SUBST	(ClientData)4

static const Tcl_SubCommandRec stringCmds[] = {
    {"compare", STRING_COMPARE, 2, 3, "<string1> <string2> [no_case]"},
    {"first", 	STRING_FIRST,	2, 3, "<substring> <string> [no_case]"},
    {"last", 	STRING_LAST,	2, 3, "<substring> <string> [no_case]"},
    {"match", 	STRING_MATCH,	2, 2, "<string> <pattern>"},
    {"subst",	STRING_SUBST,	3, 4, "<string> <search> <replace> [global]"},
    {TCL_CMD_END}
};
DEFCMD(string,Tcl_String,TCL_EXACT,stringCmds,swat_prog.string,
"Usage:\n\
    string compare <string1> <string2> [no_case]\n\
    string first <substring> <string> [no_case]\n\
    string last <substring> <string> [no_case]\n\
    string match <string> <pattern>\n\
    string subst <string> <search> <replace> [global]\n\
\n\
Examples:\n\
    \"if {[string c [index $args 1] all] == 0}\"	Do something if the 2nd element\n\
						of the list in $args is the\n\
						string \"all\".\n\
    \"while {[string m [index $args 0] -*]}\" 	Loop while the first element\n\
						of the list in $args begins with\n\
						a hyphen.\n\
\n\
Synopsis:\n\
    Examine strings in various ways.\n\
\n\
Notes:\n\
    * \"string subst\" searches <string> for occurrences of <search> and\n\
      replaces them with <replace>. If 5th argument is given as \"global\"\n\
      (it may be abbreviated), then all (non-overlapping) occurrences of\n\
      <search> will be replaced. If 5th argument is absent, only the first\n\
      occurrence will be replaced.\n\
\n\
    * \"string compare\" compares the two strings character-by-character. It\n\
      returns -1, 0, or 1 depending on whether <string1> is lexicographically\n\
      less than, equal to, or greater than <string2>. If the no_case parameter\n\
      is passed than it does a case insensitive compare.\n\
\n\
    * \"string first\" searches <string> for the given <substring>. If it finds\n\
      it, it returns the index of the first character in the first such match.\n\
      If <substring> isn't part of <string>, it returns -1. If the no_case paramaeter is passed is does the search ignoring case\n\
\n\
    * \"string last\" is much like \"string first\", except it returns the index\n\
      of the first character of the last match for the <substring> within\n\
      <string>. If there is no match, it returns -1.\n\
\n\
    * \"string match\" compares <string> against <pattern> and returns 1 if\n\
      the two match, or 0 if they do not. For the strings to match, their\n\
      contents must be identical, except that the following special sequences\n\
      may appear in <pattern> with the following results:\n\
	*   		Matches any sequence of characters, including none.\n\
	?   		Matches any single character\n\
	[<char-class>]	Matches a single character within the given set. The\n\
			elements of the set are specified as single characters,\n\
			or as ranges of the form <start>-<end>. Thus [0-9x]\n\
			matches a single character that is a numeric digit or\n\
			the letter x.\n\
	[^<char-class>]	Matches a single character *not* within the given set.\n\
	\\*	    	Matches an asterisk.\n\
	\\?	    	Matches a question mark.\n\
	\\[	    	Matches an open-bracket.\n\
\n\
See also:\n\
    case\n\
")
{
    int length;
    register char *p, c, *p1, *p2, *p2_start;
    int match;
    int first = 0;

    switch((int)clientData) {
	case (int)STRING_COMPARE:
	    if (argc == 5) 
	    {
		char	*cp1 = argv[2];
		char	*cp2 = argv[3];
		
		match = 0;
		while(1)
		{
		    if (toupper(*cp1) != toupper(*cp2))
		    {
			match = *cp1 < *cp2 ? -1 : 1;
			break;
		    }
		    if (!(*cp1))
		    {
			break;
		    }
		    cp1++;
		    cp2++;
		}
	    }
	    else
	    {
	    	match = strcmp(argv[2], argv[3]);
	    }
	    if (match > 0) {
		Tcl_Return(interp, "1", TCL_STATIC);
	    } else if (match < 0) {
		Tcl_Return(interp, "-1", TCL_STATIC);
	    } else {
		Tcl_Return(interp, "0", TCL_STATIC);
	    }
	    return TCL_OK;
	case (int)STRING_FIRST:
	    first = 1;
	    break;
	case (int)STRING_LAST:
	    first = 0;
	    break;
	case (int)STRING_MATCH:
	    Tcl_RetPrintf(interp, "%d", Tcl_StringMatch(argv[2], argv[3]));
	    return TCL_OK;
	case (int)STRING_SUBST:
	{
	    int	global;
	    
	    if (argc == 6) {
		if (!strncmp(argv[5], "global", strlen(argv[5]))) {
		    global = 1;
		} else {
		    return (TCL_SUBUSAGE);
		}
	    } else {
		global = 0;
	    }
		    
	    Tcl_Return(interp, Tcl_StringSubst(argv[2],
					       argv[3],
					       argv[4],
					       global),
		       TCL_DYNAMIC);
	    return TCL_OK;
	}
    }

    /* if the no_case argument was given then convert the strings to
     * all upper case so that we get a match regardless of case...
     */
    if (argc == 5)
    {
	char	*tp1, *tp2;

	p = argv[2];
	tp1 = p1 = malloc(strlen(p)+1);
	while (*p) 
	{
	    *tp1 = toupper(*p);
	    tp1++;
	    p++;
	}
	p = argv[3];
	tp2 = p2 = malloc(strlen(p)+1);
	while (*p) 
	{
	    *tp2 = toupper(*p);
	    tp2++;
	    p++;
	}
	*tp1 = *tp2 = '\0';
    }
    else
    {
	p1 = argv[2];
	p2 = argv[3];
    }

    p2_start = p2;
    match = -1;
    c = *p1;
    length = strlen(p1);
    for (; *p2 != 0; p2++) {
	if (*p2 != c) {
	    continue;
	}
	if (strncmp(p1, p2, length) == 0) {
	    match = p2-p2_start;
	    if (first) {
		break;
	    }
	}
    }
    Tcl_RetPrintf(interp, "%d", match);
    if (argc == 5)
    {
	free(p1);
	free(p2_start);
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Tcl_TimeCmd --
 *
 *	This procedure is invoked to process the "time" Tcl command.
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
static const Tcl_SubCommandRec timeCmds[] = {
    {TCL_CMD_ANY, 0, 	    0, 1, "<body> [<count>]"},
    {TCL_CMD_END}
};

DEFCMD(time,Tcl_Time,TCL_EXACT,timeCmds,swat_prog.obscure,
"Usage:\n\
    time <body> <count>\n\
\n\
Examples:\n\
    time {time-critical-proc 3} 1000	Executes \"time-critical-proc\" 1000\n\
					times.\n\
\n\
Synopsis:\n\
    This command is used to measure the time needed to execute a command.\n\
\n\
Notes:\n\
    * Any command or sequence of commands may be timed.\n\
\n\
    * The number of microseconds spent in each iteration is returned with\n\
      the number, as a real number, first, followed by the text \"microseconds\n\
      per iteration\" for human consumption.\n\
")
{
#if defined(unix)
    int count, i, result;
    struct timeval start, stop;
    struct timezone tz;
    int micros;
    double timePer;

    if (argc == 2) {
	count = 1;
    } else {
	if (sscanf(argv[2], "%d", &count) != 1) {
	    Tcl_RetPrintf(interp, "bad count \"%.50s\" given to \"%.50s\"",
			  argv[2], argv[0]);
	    return TCL_ERROR;
	}
    }
    gettimeofday(&start, &tz);
    for (i = count ; i > 0; i--) {
	result = Tcl_Eval(interp, argv[1], 0, (const char **) NULL);
	if (result != TCL_OK) {
	    return result;
	}
    }
    gettimeofday(&stop, &tz);
    micros = (stop.tv_sec - start.tv_sec)*1000000
	    + (stop.tv_usec - start.tv_usec);
    timePer = micros;
    Tcl_RetPrintf(interp, "%.2f microseconds per iteration",
		  (double)timePer/count);
    return TCL_OK;
#else /* is _MSDOS and _WIN32 */
    Tcl_Error(interp, "time command not supported for DOS");
#endif
}

/***********************************************************************
 *				Tcl_UplevelCmd
 ***********************************************************************
 * SYNOPSIS:	    Evaluate a command in some other context
 * CALLED BY:	    Tcl
 * RETURN:	    result of the command
 * SIDE EFFECTS:    not really
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/90		Initial Revision
 *
 ***********************************************************************/

static const Tcl_SubCommandRec uplevelCmds[] = {
    {TCL_CMD_ANY, 0, 	    1, TCL_CMD_NOCHECK, "(<level>|<function>) <body>"},
    {TCL_CMD_END}
};
DEFCMD(uplevel,Tcl_Uplevel,TCL_EXACT,uplevelCmds,swat_prog,
"Usage:\n\
    uplevel <level> <body>\n\
    uplevel <function> <body>\n\
\n\
Examples:\n\
    \"uplevel print-frame {var found 1}\"	    Sets $found to 1 within the\n\
					    variables belonging to the\n\
					    nearest invocation of print-frame\n\
					    on the call stack.\n\
    \"uplevel 0 {var foo-table}\"		    Retrieves the value of the\n\
					    global variable foo-table.\n\
    \"uplevel 1 {var found 1}\"		    Sets $found to 1 within the\n\
					    scope of the procedure that\n\
					    called the one executing the\n\
					    \"uplevel\" command.\n\
\n\
Synopsis:\n\
    Provides access to the variables of another procedure for fairly specialized\n\
    purposes.\n\
\n\
Notes:\n\
    * <level> is a signed integer with the following meaning:\n\
	> 0	Indicates the number of scopes to go up. For example, if you\n\
		say \"uplevel 1 {var foo 36}\", you would modify (or create) the\n\
		variable \"foo\" in your caller's scope.\n\
	<= 0	Indicates the number of scopes to go down from the global one.\n\
		\"uplevel 0 <body>\" will execute <body> in the top-most scope,\n\
		which means that no local variables are involved, and any\n\
		variables created by the commands in <body> persist as global\n\
		variables.\n\
\n\
    * <function> is the name of a function known to be somewhere on the call\n\
      stack. If the named function isn't on the call stack anywhere, \"uplevel\"\n\
      generates an error.\n\
\n\
    * <body> may be spread over multiple arguments, allowing the command to\n\
      be executed to use variables local to the current procedure as arguments\n\
      without having to use the \"list\" command to form the <body>.\n\
\n\
See also:\n\
    global.\n\
")
{
    Interp  	*iPtr = (Interp *)interp;
    VarFrame	*vf, *oldVF;
    int	    	level;
    int	    	result;
    char    	*cmd;
    int	    	cmdDynamic;

    oldVF = iPtr->top->localPtr;
    
    if (!isdigit(argv[1][0]) && (argv[1][0] != '-') && (argv[1][0] != '+')) {
	/*
	 * Specifies a function for which to search.
	 */
	Frame	    *f;

	for (f = iPtr->top; f != NULL; f = (Frame *)f->ext.next) {
	    if (strcmp(f->ext.argv[0], argv[1]) == 0) {
		/*
		 * Found it.
		 */
		break;
	    }
	}
	if (f == NULL) {
	    Tcl_RetPrintf(interp, "%s not active", argv[1]);
	    return(TCL_ERROR);
	}

	vf = f->localPtr;
    } else {
	level = atoi(argv[1]);

	if (level <= 0) {
	    /*
	     * Adjust the desired level by the number of levels needed to get up
	     * to the top-most frame (vf->next is NULL). This will give us the
	     * number of frames to go up in the next loop, below.
	     */
	    for (vf = iPtr->top->localPtr; vf->next != NULL; vf = vf->next) {
		level++;
	    }
	}
	/*
	 * Save the current frame and go up the indicated number of frames.
	 */
	for (vf = oldVF; level > 0 && vf; vf = vf->next, level--) {
	    ;
	}
	if (level > 0) {
	    Tcl_Error(interp, "uplevel: not that many frames available");
	}
    }

    /*
     * If not just a single <body>, merge them all into a single list for
     * evaluation.
     */
    if (argc != 3) {
	cmd = Tcl_Merge(argc-2, &argv[2]);
	cmdDynamic = 1;
    } else {
	cmd = argv[2];
	cmdDynamic = 0;
    }

    /*
     * Change our own frame to match the desired one, then evaluate the passed
     * command.
     */
    iPtr->top->localPtr = vf;
    result = Tcl_Eval(interp, cmd, 0, 0);
    /*
     * Revert the scope back to what we had before.
     */
    iPtr->top->localPtr = oldVF;

    if (cmdDynamic) {
	free(cmd);
    }

    return(result);
}
    
    
