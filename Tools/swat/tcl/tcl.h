/*
 * tcl.h --
 *
 *	This header file describes the externally-visible facilities
 *	of the Tcl interpreter.
 *
 * Copyright 1987 Regents of the University of California
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appear in all copies.  The University of California
 * makes no representations about the suitability of this
 * software for any purpose.  It is provided "as is" without
 * express or implied warranty.
 *
 * $Id: tcl.h,v 1.39 97/04/18 12:16:01 dbaumann Exp $ SPRITE (Berkeley)
 */

#ifndef _TCL
#define _TCL

/*
 * Miscellaneous declarations (to allow Tcl to be used stand-alone,
 * without the rest of Sprite).
 */

#ifndef NULL
#define NULL 0
#endif

#if defined(__HIGHC__)
typedef unsigned long ClientData;
#elif !defined(_SPRITE)
typedef int *ClientData;
#endif
/*
 * Data structures defined opaquely in this module.  The definitions
 * below just provide dummy types.  A few fields are made visible in
 * Tcl_Interp structures, namely those for returning string values.
 * Note:  any change to the Tcl_Interp definition below must be mirrored
 * in the "real" definition in tclInt.h.
 */

typedef struct {
    const char *result;		/* Points to result string returned by last
				 * command. */
    int dynamic;		/* Non-zero means result is dynamically-
				 * allocated and must be freed by Tcl_Eval
				 * before executing the next command. */
    char *(*helpFetch)(const char *name, const char *class);
    	    	    	    	/* Function to call to return the help string
				 * for a function when -help argument is
				 * given. Null if -help isn't supported */
    void (*helpSet)(const char *name, const char *class, const char *str);
    	    	    	    	/* Function to call when a procedure with
				 * help is defined. */
    void (*output)(const char *fmt, ...);
} Tcl_Interp;

typedef int Tcl_CmdProc(ClientData clientData,
			Tcl_Interp *interp,
			int argc,
			char **argv);
typedef void Tcl_DelProc(ClientData clientData);
#define NoDelProc ((Tcl_DelProc *)0)

typedef struct _TclFrame {
    int	    	    	level;      /* Frame's level */
    const char 	    	*command;   /* Command being executed */
    Tcl_CmdProc	    	*cmdProc;   /* Handling function */
    int	    	    	cmdFlags;   /* Flags for the command */
    ClientData	    	cmdData;    /* Data for same */
    int	    	    	argc;       /* Argument count */
    const char 	    	**argv;     /* Argument vector */
    int	    	    	flags;	    /* Flags (TCL_FRAME_FLAGS may not be used
				     * by outside world) */
    struct _TclFrame	*next;	    /* Next frame in stack */
} Tcl_Frame;
#define TCL_FRAME_FLAGS	0xff	    /* Reserve low 8 bits for internal use */

typedef int *Tcl_Trace;

typedef void Tcl_TraceCallProc(ClientData clientData,
			       Tcl_Interp *interp,
			       Tcl_Frame *frame);
typedef void Tcl_TraceRetProc(ClientData clientData,
			      Tcl_Interp *interp,
			      Tcl_Frame *frame,
			      int result);
/*
 * When a TCL command returns, the string pointer interp->result points to
 * a string containing return information from the command.  In addition,
 * the command procedure returns an integer value, which is one of the
 * following:
 *
 * TCL_OK		Command completed normally;  interp->result contains
 *			the command's result.
 * TCL_ERROR		The command couldn't be completed successfully;
 *			interp->result describes what went wrong.
 * TCL_RETURN		The command requests that the current procedure
 *			return;  interp->result contains the procedure's
 *			return value.
 * TCL_BREAK		The command requests that the innermost loop
 *			be exited;  interp->result is meaningless.
 * TCL_CONTINUE		Go on to the next iteration of the current loop;
 *			interp->result is meaninless.
 */

#define TCL_OK		0
#define TCL_ERROR	1
#define TCL_RETURN	2
#define TCL_BREAK	3
#define TCL_CONTINUE	4

#define TCL_RESULT_SIZE 199

/*
 * Flag values passed to Tcl_Return (see the man page for details):
 */

#define TCL_STATIC	0
#define TCL_DYNAMIC	1
#define TCL_VOLATILE	2

/*
 * Flags for command type given to Tcl_CreateCommand.
 */
#define TCL_EXACT   	1   	/* Name must be matched exactly to be
				 * invoked */
#define TCL_PROC    	2   	/* If command has its own variable scope */
#define TCL_DEBUG   	4   	/* Procedure being debugged */
#define TCL_NOEVAL  	8   	/* Do not evaluate arguments, variable or
				 * nested command or otherwise. Equivalent to
				 * lisp "lexpr" */

/*
 * Structures & interface for automatic subcommand parsing.
 */
typedef struct {    	/* Description of a particular subcommand */
    const char 	*subCommand;	/* Subcommand (argv[1]). If empty (not null),
				 * used for subcommand that matches nothing
				 * else. */
    ClientData	data;	    	/* Data to pass if recognized */
    int	    	minArgs;    	/* Minimum # of args (after subcommand) */
    int	    	maxArgs;    	/* Maximum # of args (after subcommand) */
    const char 	*usage;	    	/* Usage string */
} Tcl_SubCommandRec;

#define TCL_CMD_ANY  	""   /* Constant for matching any subcommand */
#define TCL_CMD_NOCHECK	-1  /* Constant for things that take any number of
			     * arguments. Placed in the minArgs or maxArgs
			     * field, it causes that limit not to be checked.
			     */
#define TCL_CMD_END 	(const char *)NULL  /* subCommand field to mark the
					     * end of the array */

#define TCL_SUBUSAGE	-1  /* When returned by a usage-checked command,
			     * causes the usage for the subcommand to be
			     * returned. */
#define TCL_USAGE   	-2  /* When returned by a usage-checked command,
			     * causes the usage for the whole command to
			     * be returned */
typedef struct {    	/* Description of entire command */
    const char	    	    *name;	/* Name by which command is invoked */
    const char 	    	    *helpClass;	/* Class of command */
    Tcl_CmdProc	    	    *proc;	/* Procedure to handle the command */
    Tcl_DelProc	    	    *delProc;	/* Procedure to call if command
					 * is deleted/overridden */
    const Tcl_SubCommandRec *data;  	/* Possible subcommands. May be
					 * 0 if command wants to handle them
					 * by itself. */
    int	    	    	    flags;    	/* Flags for Tcl_CreateCommand */
} Tcl_CommandRec;

extern void 	    	Tcl_CreateCommandByRec(Tcl_Interp *interp,
					       const Tcl_CommandRec *cmdRec);

/*
 * Exported Tcl procedures: 
 */
extern char		Tcl_Backslash(const char *src, int *readPtr);
extern void		Tcl_CreateCommand(Tcl_Interp *interp,
					  const char *cmdName,
					  Tcl_CmdProc *proc,
					  int flags,
					  ClientData clientData,
					  Tcl_DelProc *deleteProc);
extern int		Tcl_OverrideCommand(Tcl_Interp *interp,
					    const char *cmdName,
					    Tcl_CmdProc *cmdProc,
					    int flags,
					    ClientData clientData,
					    void (*deleteProc)(),
					    Tcl_CmdProc **cmdProcPtr,
					    int *flagsPtr,
					    ClientData *clientDataPtr,
					    Tcl_DelProc **deleteProcPtr);
extern int		Tcl_FetchCommand(Tcl_Interp *interp,
					 const char *cmdName,
					 const char **realNamePtr,
					 Tcl_CmdProc **cmdProcPtr,
					 int *flagsPtr,
					 ClientData *clientDataPtr,
					 Tcl_DelProc **deleteProcPtr);
extern Tcl_Interp *	Tcl_CreateInterp(void);
extern void		Tcl_TopLevel(Tcl_Interp *interp);
extern Tcl_Trace	Tcl_CreateTrace(Tcl_Interp *interp,
					int level,
					Tcl_TraceCallProc *callProc,
					Tcl_TraceRetProc *returnProc,
					ClientData clientData);
extern void		Tcl_DeleteCommand(Tcl_Interp *interp,
					  const char *cmdName);
extern void		Tcl_DeleteInterp(Tcl_Interp *interp);
extern void		Tcl_DeleteTrace(Tcl_Interp *interp,
					Tcl_Trace trace);
extern int		Tcl_Eval(Tcl_Interp *interp,
				 const char *cmd,
				 char termChar,
				 const char **termPtr);
extern int		Tcl_Expr(Tcl_Interp *interp,
				 const char *string,
				 int *valuePtr);
extern int		Tcl_FExpr(Tcl_Interp *interp,
				 const char *string,
				 double *valuePtr);
extern const char *	Tcl_GetVar(Tcl_Interp *interp,
				   const char *varName,
				   int global);
/* XXX:should be const char * const *argv, but then can't pass const char ** w/o
 * warning, so screw it */
extern char *		Tcl_Merge(int argc, char **argv);
extern const char *	Tcl_ParseVar(Tcl_Interp *,
				     const char *string,
				     const char **termPtr);
extern void		Tcl_Return(Tcl_Interp *interp,
				   const char *string,
				   int status);
extern void 	    	Tcl_RetPrintf(Tcl_Interp *interp,
				      const char *format,
				      ...);
extern void		Tcl_SetVar(Tcl_Interp *interp,
				   const char *varName,
				   const char *newValue,
				   int global);
extern int		Tcl_SplitList(Tcl_Interp *interp,
				      const char *list,
				      int *argcPtr,
				      char ***argvPtr);
extern int  	    	Tcl_StringMatch(const char *string,
					const char *pattern);
extern char  	    	*Tcl_StringSubst(const char *string,
					 const char *search,
					 const char *replace,
					 int global);
extern Tcl_Frame    	*Tcl_CurrentFrame(Tcl_Interp *interp);

/*
 * Built-in Tcl command procedures:
 */

extern Tcl_CmdProc  	Tcl_BCCmd;
extern Tcl_CmdProc	Tcl_BreakCmd;
extern Tcl_CmdProc  	Tcl_CaseCmd;
extern Tcl_CmdProc	Tcl_CatchCmd;
extern Tcl_CmdProc	Tcl_ConcatCmd;
extern Tcl_CmdProc	Tcl_ContinueCmd;
extern Tcl_CmdProc	Tcl_ErrorCmd;
extern Tcl_CmdProc	Tcl_EvalCmd;
extern Tcl_CmdProc	Tcl_ExecCmd;
extern Tcl_CmdProc	Tcl_ExprCmd;
extern Tcl_CmdProc	Tcl_FileCmd;
extern Tcl_CmdProc	Tcl_ForCmd;
extern Tcl_CmdProc	Tcl_ForeachCmd;
extern Tcl_CmdProc	Tcl_FormatCmd;
extern Tcl_CmdProc	Tcl_GlobalCmd;
extern Tcl_CmdProc	Tcl_IfCmd;
extern Tcl_CmdProc	Tcl_InfoCmd;
extern Tcl_CmdProc	Tcl_IndexCmd;
extern Tcl_CmdProc	Tcl_LengthCmd;
extern Tcl_CmdProc	Tcl_ListCmd;
extern Tcl_CmdProc	Tcl_ProcCmd;
extern Tcl_CmdProc  	Tcl_ProtectCmd;
extern Tcl_CmdProc	Tcl_RangeCmd;
extern Tcl_CmdProc	Tcl_ReturnCmd;
extern Tcl_CmdProc	Tcl_ScanCmd;
extern Tcl_CmdProc	Tcl_SourceCmd;
extern Tcl_CmdProc	Tcl_StringCmd;
extern Tcl_CmdProc	Tcl_TimeCmd;
extern Tcl_CmdProc  	Tcl_UplevelCmd;
extern Tcl_CmdProc	Tcl_VarCmd;

#define Tcl_Error(interp, msg) \
	Tcl_Return(interp, msg, TCL_STATIC); return(TCL_ERROR)

#endif _TCL
