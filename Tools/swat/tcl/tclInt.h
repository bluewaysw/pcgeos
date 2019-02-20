/*
 * tclInt.h --
 *
 *	Declarations of things used internally by the TCL interpreter.
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
 * $Id: tclInt.h,v 1.31 97/04/18 12:25:06 dbaumann Exp $ SPRITE (Berkeley)
 */

#ifndef _TCLINT
#define _TCLINT

#ifndef _TCL
#include "tcl.h"
#endif

/*
 * The structure below defines one TCL command, by associating a procedure
 * with a textual string.
 */

typedef struct Command {
    Tcl_CmdProc	*proc;		/* Procedure to process command. */
    int     	flags;
    ClientData 	clientData;	/* Arbitrary value to pass to proc. */
    Tcl_DelProc *deleteProc;	/* Procedure to invoke when deleting
				 * command. */
    struct Command *nextPtr;	/* Pointer to next command in list, or NULL
				 * for end of list. */
    char    	name[4];	/* Name of command.  The actual size of this
				 * portion is as large as is necessary to
				 * hold the characters.  This must be the
				 * last subfield of the record. */
} Command;

#define CMD_SIZE(nameLength) ((unsigned) sizeof(Command) + (nameLength) - 3)

/*
 * DEFCMD is used to create a Tcl_CommandRec for entering a built-in command
 * into the interpreter. It creates a function <FuncPref>Cmd to handle the
 * command, and <FuncPref>CmdRec whose address should be passed off to
 * Tcl_CommandCreateByRec to install the command.
 *
 * cmdData should be NULL or the address of an array of Tcl_SubCommandRec
 * records describing the arguments the command expects.
 *
 * The helpString does not actually reside in the interpreter's memory.
 * Rather, it is extracted by the makedoc program and placed in the
 * documentation file in Swat's library directory. I.e. without Swat, the
 * help string is nothing.
 */
#undef DEFCMD
#undef DEFCMDNOPROC

#define DEFCMD(string,FuncPref,flgs,cmdData,class,helpString) \
extern Tcl_CmdProc FuncPref##Cmd; \
const Tcl_CommandRec FuncPref##CmdRec = { #string, #class, FuncPref##Cmd, 0, cmdData, flgs }; \
int \
FuncPref##Cmd(ClientData clientData, Tcl_Interp *interp, int argc, char **argv)

#define DEFCMDNOPROC(string,FuncPref,flgs,cmdData,class,helpString) \
extern Tcl_CmdProc FuncPref##Cmd; \
const Tcl_CommandRec FuncPref##CmdRec = { #string, #class, FuncPref##Cmd, 0, cmdData, flgs };

extern int TclCmdCheckUsage(ClientData, Tcl_Interp *, int argc, char **argv);
extern const Tcl_CommandRec	Tcl_BCCmdRec;
extern const Tcl_CommandRec	Tcl_BreakCmdRec;
extern const Tcl_CommandRec  	Tcl_CaseCmdRec;
extern const Tcl_CommandRec	Tcl_CatchCmdRec;
extern const Tcl_CommandRec	Tcl_ConcatCmdRec;
extern const Tcl_CommandRec	Tcl_ContinueCmdRec;
extern const Tcl_CommandRec	Tcl_DefsubrCmdRec;
extern const Tcl_CommandRec	Tcl_ErrorCmdRec;
extern const Tcl_CommandRec	Tcl_EvalCmdRec;
extern const Tcl_CommandRec	Tcl_ExecCmdRec;
extern const Tcl_CommandRec	Tcl_ExprCmdRec;
extern const Tcl_CommandRec	Tcl_FileCmdRec;
extern const Tcl_CommandRec	Tcl_ForCmdRec;
extern const Tcl_CommandRec	Tcl_ForeachCmdRec;
extern const Tcl_CommandRec	Tcl_FormatCmdRec;
extern const Tcl_CommandRec	Tcl_GlobalCmdRec;
extern const Tcl_CommandRec	Tcl_IfCmdRec;
extern const Tcl_CommandRec	Tcl_InfoCmdRec;
extern const Tcl_CommandRec	Tcl_IndexCmdRec;
extern const Tcl_CommandRec	Tcl_LengthCmdRec;
extern const Tcl_CommandRec	Tcl_ListCmdRec;
extern const Tcl_CommandRec	Tcl_ProcCmdRec;
extern const Tcl_CommandRec  	Tcl_ProtectCmdRec;
extern const Tcl_CommandRec	Tcl_RangeCmdRec;
extern const Tcl_CommandRec	Tcl_ReturnCmdRec;
extern const Tcl_CommandRec	Tcl_ScanCmdRec;
extern const Tcl_CommandRec	Tcl_SourceCmdRec;
extern const Tcl_CommandRec	Tcl_StringCmdRec;
extern const Tcl_CommandRec	Tcl_TimeCmdRec;
extern const Tcl_CommandRec  	Tcl_UplevelCmdRec;
extern const Tcl_CommandRec	Tcl_VarCmdRec;
extern const Tcl_CommandRec	Tcl_ElispSendCmdRec;
/*
 * The structure below defines a variable, which associates a string name
 * with a string value.  To cut down on the number of malloc's and free's
 * (particularly for procedure parameters), space for both the variable's
 * name and initial value is allocated at the end of the structure (in
 * "storage").  If the variable's value changes later, a new dynamic
 * string is allocated, if there is insufficient space in the current
 * storage area.
 */

typedef struct Var {
    char *value;		/* Current value of variable (either points
				 * to static space after name, or to dynamic
				 * space if VAR_DYNAMIC is set). */
    int valueLength;		/* Number of bytes of storage at the place
				 * referred to by value, not including space
				 * for NULL terminator. */
    int flags;			/* Miscellaneous flags:  see below. */
    struct Var *globalPtr;	/* If VAR_GLOBAL is set, this points to the
				 * global variable corresponding to name. */
    struct Var *nextPtr;	/* Next variable in list, or NULL for end
				 * of list. */
    char name[4];		/* Storage space for variable's name (and
				 * initial value).  The name is at the
				 * beginning, and is null-terminated.
				 * May contain more than 4 bytes (see
				 * VAR_SIZE macro below). */
} Var;

#define VAR_SIZE(nameLength, valueLength) \
	((unsigned) sizeof(Var) + (nameLength) + (valueLength) - 2)

/*
 * Variable flags:
 *
 * VAR_DYNAMIC:		1 means the storage space for the value was
 *			dynamically allocated, and must eventually be
 *			freed.
 * VAR_GLOBAL:		Used only in local variables.  Means that this
 *			is really a global variable.
 */

#define VAR_DYNAMIC	1
#define VAR_GLOBAL	2

/*
 * The structure below defines a command procedure, which consists of
 * a collection of Tcl commands plus information about arguments and
 * variables.
 */

typedef struct Proc {
    Var *argPtr;		/* Pointer to first in list of variables
				 * giving names to the procedure's arguments.
				 * The order of the variables is the same
				 * as the order of the arguments.  The "value"
				 * fields of the variables are the default
				 * values. */
    short   inuse;  	    	/* Count of nested calls to this procedure */
    short   delete; 	    	/* Non-zero if record must be freed when inuse
				 * goes to 0 */
    char command[LABEL_IN_STRUCT]; /* Command that constitutes the body of
				     * the procedure. */
} Proc;

/*
 * The structure below defines a compiled command procedure, which consists of
 * a collection of Tcl commands plus information about arguments and
 * variables.
 */

typedef struct ByteProc {
    Var *argPtr;		/* Pointer to first in list of variables
				 * giving names to the procedure's arguments.
				 * The order of the variables is the same
				 * as the order of the arguments.  The "value"
				 * fields of the variables are the default
				 * values. */
    short   inuse;  	    	/* Count of nested calls to this procedure */
    short   delete; 	    	/* Non-zero if record must be freed when inuse
				 * goes to 0 */
    unsigned long size;	    	/* Number of bytes of byte-code */
    unsigned char code[LABEL_IN_STRUCT]; /* Start of the byte-code */
} ByteProc;

/*
 * The structure below defines a trace.  This is used to allow Tcl
 * clients to find out whenever a command is about to be executed.
 */

typedef struct Trace {
    int     	    	level;	    /* Only trace commands at nesting level
				     * less than or equal to this. If 0, trace
				     * at all levels. */
    Tcl_TraceCallProc	*callProc;  /* Procedure to call to trace command. */
    Tcl_TraceRetProc	*returnProc;/* Procedure to call when command returns*/
    ClientData 	    	clientData; /* Arbitrary value to pass to proc. */
    struct Trace    	*nextPtr;   /* Next in list of traces for this
				     * interpreter */
} Trace;

/*
 * True to the adage "any problem can be solved by another level of
 * indirection", we have another stack of frames giving the contexts of
 * nested procedures. Each call frame points to one of these (allocated
 * by InterpProc as one of its local variables) and all local variables/
 * arguments for the procedure are kept here. This avoids the sometimes
 * nightmarish bookkeeping entailed by the interpreter's (nice) tendency
 * to bring recently-used variables to the head of the list, wreaking
 * havoc for any frames between the referencer and the frame of the variable's
 * owning procedure.
 */
typedef struct _VarFrame {
    Var	    	    	*vars;
    struct _VarFrame	*next;
} VarFrame;


/*
 * Internal version of Tcl_Frame, with added fields for local variables, etc.
 */
typedef struct {
    Tcl_Frame	    ext;    	/* External form */
    VarFrame   	    *localPtr;	/* Local variables for frame */
    char    	    *protect;	/* Protected-command to evaluate in case of
				 * abort... */
    unsigned long   psize;  	/* 0 if protect is a string, non-zero if it's
				 * byte-code */
    char    	    *copyStart;	/* Storage for copied command line pieces */
    char    	    *copyEnd;	/* End of same */
    void    	    **sepArgs;	/* Null-terminated array of separately-allocated
				 * arguments that must be freed */
} Frame;

/*
 * Flags for stack frames
 */
#define TCL_FRAME_FREE_ARGS 	1
#define TCL_FRAME_FREE_ARGV 	2
#define TCL_FRAME_FREE_SEPARGS	4

/*
 * This structure defines an interpreter, which is a collection of commands
 * plus other state information related to interpreting commands, such as
 * variable storage.  The lists of commands and variables are sorted by usage:
 * each time a command or variable is used it is pulled to the front of its
 * list.
 */

#define TCL_CMD_CHAINS	32  	/* Number of chains on which commands are
				 * linked. Must be a power of two for current
				 * implementation. Commands are chained off
				 * their first character. */
#define TCL_CMD_GET_CHAIN(name) ((name)[0] & (TCL_CMD_CHAINS-1))

typedef struct _TclByteStackElement {
    enum TclByteStackElementType {
	TBSET_STRING,
	TBSET_CODE,
	TBSET_EXPR,
	TBSET_STRING_TABLE
    }	    	    eltType;
    int	    	    eltDynamic;
    unsigned long   eltSize;
    const void	    *eltData;
} TclByteStackElement;

typedef struct _TclByteStack {
    struct _TclByteStackElement *stack;	/* The array of elements */
    unsigned	    	    	size;	/* The size of the array */
    unsigned	    	    	top;	/* The index of the first free element
					 * in the stack */
} TclByteStack;

typedef struct Interp {

    /*
     * Note:  the first four fields must match exactly the first
     * fields in a Tcl_Interp struct (see tcl.h).  If you change
     * one, be sure to change the other.
     */

    const char *result;		/* Points to result returned by last
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
#if defined(__HIGHC__) || defined(__WATCOMC__)
    int (*output)(const char *fmt, ...);
#else
    void (*output)(const char *fmt, ...);
#endif

    Command *commands[TCL_CMD_CHAINS];
    	    	    	    	/* First command in list containing all
				 * commands defined for this table. */
    VarFrame globalFrame;   	/* List of global variables */
    int numLevels;		/* Keeps track of how many nested calls to
				 * Tcl_Eval are in progress for this
				 * interpreter.  It's used to delay deletion
				 * of the table until all Tcl_Eval invocations
				 * are completed. */
    int cmdCount;		/* Total number of times Tcl_Eval has been
				 * called for this interpreter. */
    int flags;			/* Various flag bits.  See below. */
    Trace *tracePtr;		/* List of traces for this interpreter. */
    Frame *top;  	    	/* Top-most frame */

    TclByteStack    operands; 	/* Operands */
    TclByteStack    strings;	/* String tables */

    char resultSpace[TCL_RESULT_SIZE];
				/* Static space for storing small results. */
} Interp;

/*
 * Flag bits for Interp structures:
 *
 * DELETED:		Non-zero means the interpreter has been deleted:
 *			don't process any more commands for it, and destroy
 *			the structure as soon as all nested invocations of
 *			Tcl_Eval are done.
 */

#define DELETED 1

/*
 * Procedures shared among Tcl modules but not used by the outside
 * world:
 */

extern void		TclCopyAndCollapse(int count, const char *src,
					   char *dst);
extern void		TclDeleteVars(Var *varPtr);
extern Command *	TclFindCmd(Interp *iPtr, const char *cmdName,
				   int exact);
extern int		TclFindElement(Tcl_Interp *interp,
				       const char *list,
				       const char **elementPtr,
				       const char **nextPtr,
				       int *sizePtr,
				       int *bracePtr);
extern Proc *		TclFindProc(Interp *iPtr, const char *procName);
#define TclIsProc(cmdPtr) ((cmdPtr)->flags & TCL_PROC)

extern int  	    	TclProcCreateArgs(Tcl_Interp *interp,
					  const char *procName,
					  const char *argString,
					  Var **argPtrPtr,
					  unsigned *cmdFlagsPtr);
extern int  	    	TclProcBindArgs(Interp *iPtr,
					Var *formalPtr,
					char **argv,
					int argc,
					VarFrame *framePtr);

extern const char   	*TclProcScanVar(Tcl_Interp *interp,
					const char *string,
					int *lenPtr,
					const char **termPtr);

extern int  	    	TclByteCodeEval(Tcl_Interp *interp,
					unsigned long size,
					const unsigned char *data);
extern unsigned char 	*TclByteCodeCompile(Tcl_Interp *interp,
					    const char *cmd,
					    char termChar,
					    int flags,
					    const char **termPtr,
					    unsigned long *sizePtr);
#define TBCC_DISCARD	    0x0001  /* Generate code to discard final result */
#define TBCC_NOHELP 	    0x0002  /* Leave out the help strings in any command
				     * that uses them (defcommand & defcmd) */

extern void 	    	TclByteCodeResetStack(Interp *iPtr);
extern int TclExprGetNum(register const char *string,
			 register const char **termPtr);

/*
 * String table built during compilation.
 */
typedef struct {
    unsigned char   *strings;	    	/* Base of the table */
    unsigned 	    free;   	    	/* Offset to put the next string */
    unsigned	    size;   	    	/* Size of the block strings
					 * points to */
    unsigned short  *refs;  	    	/* Number of references to each
					 * string */
#define TBCC_STRING_INIT    (128)
#define TBCC_STRING_EXPAND  (128)
} TBCCStrings;

typedef struct {
    unsigned char	*data;	/* Start of the string, or 0 if encoded
				 * string should remain encoded. */
    unsigned short   	dataLen;/* Length of the string, or the new index,
				 * if data is 0 */
    short   	    	savings;/* Number of bytes saved by tokenizing */
} TBCCStringChange;

extern unsigned char *TclByteCodeCompileTop(Tcl_Interp *interp,
					    const char *cmd,
					    char termChar,
					    int flags,
					    TBCCStrings *strings,
					    const char **termPtr,
					    unsigned long *sizePtr);
/*
 * Structure passed around to allow easy appending to and expansion of
 * the current byte-code output.
 */
typedef struct {
    unsigned char   *data;
    unsigned char   *tail;
    unsigned char   *max;
    TBCCStrings	    *strings;
    unsigned	    noHelp:1,	    	    /* Set to avoid including the help
					     * stuff when compiling a defcommand
					     * or defcmd invocation */
		    allowJustVarRef:1;	    /* Set when compiling the test
					     * expression for if, while, or
					     * for, indicating that having
					     * just a variable reference is
					     * fine; the variable will not
					     * contain an expression */
    Tcl_Interp	    *interp;
    unsigned	    level;
} TBCCData;

extern int  	    TclExprByteCompile(Tcl_Interp *interp,
				       const char *str,
				       TBCCData *dataPtr);

extern void 	    TBCCOutputByte(TBCCData *dataPtr, unsigned char b);
extern void 	    TBCCOutputNum(TBCCData *dataPtr, unsigned long n);
extern void 	    TBCCOutputBytes(TBCCData *dataPtr, const unsigned char *bytes, unsigned long len);
extern void 	    TBCCOutputString(TBCCData *dataPtr, const char *str, unsigned long len);
extern void 	    TBCCOutputSignedNum(TBCCData *dataPtr, long n);
extern unsigned long	TclByteCodeFetchNum(const unsigned char **bytePtr);
extern long 	    TclByteCodeFetchSignedNum(const unsigned char **bytePtr);
extern const char   *TclByteCodeFetchString(Interp *iPtr,
					    const unsigned char **bytePtr,
					    unsigned long *lenPtr);

extern const Tcl_CommandRec *const builtInCmds[];
extern const unsigned numBuiltInCmds;

extern int  	    TclExprByteEval(Tcl_Interp *interp,
				    const unsigned char *expr,
				    unsigned long len,
				    int *valuePtr);

extern int  	    TclFExprByteEval(Tcl_Interp *interp,
				     const unsigned char *expr,
				     unsigned long len,
				     double *valuePtr);
extern void 	    TclByteCodeDisasm(Tcl_Interp *interp,
				      const unsigned char *p,
				      unsigned long size,
				      unsigned indent);

extern void 	    TclExprByteDisasm(Tcl_Interp *interp,
				      const unsigned char *p,
				      unsigned long len,
				      unsigned indent);

extern unsigned long
	TclExprByteChangeStringReferences(TBCCData *dataPtr,
					  unsigned char *p,
					  unsigned long len,
					  const TBCCStringChange *changes);

extern void 	    TBCCChangeReference(TBCCData *dataPtr,
					unsigned char **pPtr,
					unsigned char **basePtr,
					unsigned long *lenPtr,
					const TBCCStringChange *changes);

extern void TBCCChangeCodeStringReferences(TBCCData *dataPtr,
					   unsigned char **pPtr,
					   unsigned long *lenPtr,
					   const TBCCStringChange *changes);

#endif _TCLINT
