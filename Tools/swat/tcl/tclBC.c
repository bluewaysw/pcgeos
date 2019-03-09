/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1993 -- All Rights Reserved
 *
 * PROJECT:
 * MODULE:
 * FILE:	  tclByteCode.c
 *
 * AUTHOR:  	  Adam de Boor: Nov 23, 1993
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Name	  Date	    Description
 *	----	  ----	    -----------
 *	ardeb	  11/23/93  Initial version
 *
 * DESCRIPTION:
 *	Functions for implementing byte-compiled Tcl code.
 *
 *	The execution of the tokenized code is stack-based. Arguments are
 *	pushed onto the stack in left-to-right order, as it makes compiling
 *	the stuff much easier and doesn't make implementing the opcodes
 *	any harder.
 *
 *	Strings in the byte-code are stored with an initial count *and*
 *	are null-terminated, allowing for quick skip-over and in-place
 *	use.
 *
 *	Numbers (e.g. # of args or string/byte-code length) are stored
 *	unsigned in 1, 2, or 4 bytes, as dictated by the high 2 bits of
 *	the first byte. They are always stored in big-endian order.
 *
 * TODO:
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: tclBC.c,v 1.9 97/04/18 12:17:30 dbaumann Exp $";
#endif lint

#include <config.h>
#include <stdio.h>
#include <ctype.h>
#include <malloc.h>
#include <compat/string.h>
#include <compat/stdlib.h>
#include <compat/file.h>
#include <assert.h>

#if defined(unix)
#include <sys/signal.h>
#include <sys/file.h>
#include <sys/unistd.h>
#define O_TEXT	    0
#define O_BINARY    0
#endif /* unix */

#if defined(_MSDOS) || defined (_WIN32)
# ifndef _WIN32
#  include <stat.h>
# else
#  include <sys/stat.h>
# endif
#include <io.h>
#include <fcntl.h>
#include <dos.h>

#if defined(_LINUX)
#define F_OK 0
#define R_OK 1
#define W_OK 2
#endif
#define access(n,m) _access(n,m)

#define stat(n,s) _stat(n,s)

#endif /* _MSDOS || _WIN32 */

#include "tclInt.h"

static int bcDebug = 0;	    	/* If non-zero, then trace procedures will
				 * be called when possible during evaluation */


typedef enum {
    TBOP_PUSH,	    /* args: string
		     * stack: -- string */
    TBOP_PUSHV,	    /* args: varname
		     * stack: -- varval-string */
    TBOP_CALL,	    /* args: #args, procname
		     * stack: #args-string-args -- retval */
    TBOP_PCALL,	    /* args: #args, prim#
		     * stack: #args-string-args -- retval */
    TBOP_IF,	    /* args: #args
		     * stack: (test-expr body-code)+ [else-code] -- retval */
    TBOP_POP,	    /* args:
		     * stack: string/code -- */
    TBOP_CODE,	    /* args: #bytes, bytes
		     * stack: -- code */
    TBOP_FOR,	    /* args:
		     * stack: init-code test-expr next-code body-code -- retval
		     */
    TBOP_WHILE,	    /* args:
		     * stack: test-expr -- retval */
    TBOP_CASE,	    /* args: #args
		     * stack: string (pattern-list body-code)+ -- retval */
    TBOP_ARGCAT,    /* args: #strings
		     * stack: #strings-strings -- concatenation */
    TBOP_PROC,	    /* args: flags
		     * stack: name-string arg-string body-code -- retval */
    TBOP_HPROC,	    /* args: flags
		     * stack: name-string arg-string help-class-string
		     *	      help-string body-code -- retval */
    TBOP_RET,	    /* args:
		     * stack: retval -- */
    TBOP_RETZ,	    /* args:
		     * stack: -- */
    TBOP_FOREACH,   /* args:
		     * stack: var-name arg-list body-code -- retval */
    TBOP_PROTECT,   /* args:
		     * stack: body-code protect-code -- retval */
    TBOP_EXPR,	    /* args:
		     * stack: expr -- retval */
    TBOP_FEXPR,	    /* args:
		     * stack: expr -- retval */
    TBOP_PUSHE,	    /* args: #bytes, bytes
		     * stack: -- expr */
    TBOP_PUSHST,    /* args: #bytes, string-table-bytes
		     * stack: -- string-table */
    TBOP_POPST,	    /* args:
		     * stack: string-table -- */
} TclByteOpcode;

static unsigned long
	TBCCChangeStringReferences(TBCCData *dataPtr,
				   unsigned char *p,
				   unsigned long len,
				   const TBCCStringChange *changes);

#define ELT(n) (&iPtr->operands.stack[iPtr->operands.top-1-(n)])
#define TOP ELT(0)

#define INIT_BYTE_OP_STACK_SIZE	(5)
#define EXTEND_BYTE_OP_STACK_SIZE (5)

#define INIT_CODE_SIZE	(128)
#define EXTEND_CODE_SIZE (128)

/*
 * Numbers are encoded in 1, 2, or 4 bytes in big-endian order. The first byte
 * indicates how many others follow: if TBC_EXTENDED_NUM is set, the number
 * is at least 2 bytes long. If TBC_LONG_NUM is set, the number is 4 bytes
 * long. All numbers are unsigned.
 */
#define TBC_EXTENDED_NUM    0x80
#define TBC_LONG_NUM	    0x40
#define TBC_SHORT_NUM_MASK  0x3f
#define TBC_SIGN_BIT	    0x20
#define TBC_SIGNED_SHORT_NUM_MASK 0x1f

#define TBC_MAX_NUM 	    4


/***********************************************************************
 *				TclByteCodeFetchNum
 ***********************************************************************
 * SYNOPSIS:	    Fetch an encoded number out of a byte-code stream
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    the number, as an unsigned long
 * SIDE EFFECTS:    *bytePtr is advanced beyond the number.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/24/93	Initial Revision
 *
 ***********************************************************************/
unsigned long
TclByteCodeFetchNum(const unsigned char **bytePtr)
{
    const unsigned char *p;

    p = *bytePtr;
    if (*p & TBC_EXTENDED_NUM) {
	if (*p & TBC_LONG_NUM) {
	    *bytePtr += 4;
	    return ((unsigned long)(p[0]&TBC_SHORT_NUM_MASK) << 24) |
		((unsigned long)p[1] << 16) |
		    ((unsigned short)p[2] << 8) |
			p[3];
	} else {
	    *bytePtr += 2;
	    return ((unsigned short)(p[0]&TBC_SHORT_NUM_MASK) << 8) |
		p[1];
	}
    } else {
	*bytePtr += 1;
	return p[0];
    }
}


/***********************************************************************
 *				TclByteCodeFetchSignedNum
 ***********************************************************************
 * SYNOPSIS:	    Fetch an encoded signed number out of a byte-code stream
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    the number, as a long
 * SIDE EFFECTS:    *bytePtr is advanced beyond the number.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/24/93	Initial Revision
 *
 ***********************************************************************/
long
TclByteCodeFetchSignedNum(const unsigned char **bytePtr)
{
    const unsigned char *p;

    p = *bytePtr;
    if (*p & TBC_EXTENDED_NUM) {
	if (*p & TBC_LONG_NUM) {
	    *bytePtr += 4;
	    return ((((long)(p[0]&TBC_SHORT_NUM_MASK) << 26) >> 2) |
		((unsigned long)p[1] << 16) |
		    ((unsigned short)p[2] << 8) |
			p[3]);
	} else {
	    *bytePtr += 2;
	    return ((((unsigned short)(p[0]&TBC_SHORT_NUM_MASK) << 10) >> 2) |
		p[1]);
	}
    } else {
	*bytePtr += 1;
	return ((signed char)(p[0]&TBC_SHORT_NUM_MASK)<<2)>>2;
    }
}


/***********************************************************************
 *				TclByteCodeFetchString
 ***********************************************************************
 * SYNOPSIS:	    Extract a string from a byte-code sequence.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    the string, and the length
 * SIDE EFFECTS:    *bytePtr advanced beyond the null-terminated string
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/24/93	Initial Revision
 *
 ***********************************************************************/
const char *
TclByteCodeFetchString(Interp *iPtr,
		       const unsigned char **bytePtr,
		       unsigned long *lenPtr)
{
    const char	*result;
    unsigned long   length;

    length = TclByteCodeFetchNum(bytePtr);
    if (length == 0) {
	/*
	 * A length of 0 either indicates an empty string (for old code)
	 * or an indexed string. String indices start at 1, so if the next
	 * byte is non-zero (a null string has the null terminator following
	 * the 0 length byte), it's an indexed string.
	 */
	unsigned long stridx;

	stridx = TclByteCodeFetchNum(bytePtr);

	if ((stridx != 0) && (iPtr->strings.top != 0))
	{
	    unsigned short  num;
	    const unsigned char *bp;

	    bp = iPtr->strings.stack[iPtr->strings.top-1].eltData;

	    /*
	     * Figure the number of strings in the table. Things are stored
	     * little-endian because I like it and we can't rely on the words
	     * being word-aligned, so we have to build them from bytes.
	     */
	    num = *bp | (bp[1] << 8);

	    if (stridx <= num) {
		unsigned short offset = bp[2*stridx] | (bp[2*stridx+1] << 8);
		unsigned short next;

		result = (const char *)bp+offset;
		/*
		 * Figure the offset of the following string so we can compute
		 * the length of this one.
		 */
		if (stridx != num) {
		    next = bp[2*(stridx+1)] + (bp[2*(stridx+1)+1] << 8);
		} else {
		    /*
		     * Last string in the table, so next string offset is the
		     * size of the table.
		     */
		    next = iPtr->strings.stack[iPtr->strings.top-1].eltSize;
		}
		/*
		 * Compute the length
		 */
		length = next - offset - 1;
	    } else {
		/*
		 * Not in the table -- return a null string instead.
		 * XXX: return some recognizable error string instead?
		 */
		result = "";
		length = 0;
	    }
	} else {
	    /*
	     * Either it's a null string or it's an index and we don't have
	     * a string table. In either case, *bytePtr is set correctly,
	     * so return a null string.
	     */
	    result = "";
	}
    } else {
	/*
	 * Embedded string -- return the start of it and advance beyond the
	 * string and its null terminator.
	 */
	result = (const char *)(*bytePtr);
	*bytePtr += length + 1;
    }

    if (lenPtr) {
	*lenPtr = length;
    }

    return(result);
}

/***********************************************************************
 *				TclByteCodePush
 ***********************************************************************
 * SYNOPSIS:	    Push a string or code block onto the operand stack
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    interpreter's stack may be resized
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/23/93	Initial Revision
 *
 ***********************************************************************/
static void
TclByteCodePush(Interp	    	    	    *iPtr,
		enum TclByteStackElementType type,
		int			     dynamic,
		unsigned long		     size,
		const void		     *data)
{
    TclByteStack    *stack;

    if (type == TBSET_STRING_TABLE) {
	stack = &iPtr->strings;
    } else {
	stack = &iPtr->operands;
    }

    if (stack->size == 0) {
	stack->size = INIT_BYTE_OP_STACK_SIZE;
	stack->stack =
	    (TclByteStackElement *)malloc(stack->size *
					  sizeof(TclByteStackElement));
    } else if (stack->top == stack->size) {
	stack->size += EXTEND_BYTE_OP_STACK_SIZE;
	stack->stack =
	    (TclByteStackElement *)realloc((malloc_t)stack->stack,
					   (stack->size *
					    sizeof(TclByteStackElement)));
    }
    stack->stack[stack->top].eltType = type;
    stack->stack[stack->top].eltDynamic = dynamic;
    stack->stack[stack->top].eltSize = size;
    stack->stack[stack->top].eltData = data;

    stack->top += 1;
}

#define TBCInArgStore(elt) (((elt)->eltData >= (const void *)argStore) && ((elt)->eltData < (const void *)(&argStore[sizeof(argStore)])))

#define TclByteCodePopCommon(stck) \
    do {\
	assert((stck)->top != 0);\
	if ((stck)->stack[(stck)->top-1].eltDynamic) {\
	    free((malloc_t)(stck)->stack[(stck)->top-1].eltData);\
	} else if (TBCInArgStore(&(stck)->stack[(stck)->top-1])) {\
	    argTop = (char *)(stck)->stack[(stck)->top-1].eltData;\
	}\
	(stck)->top -= 1;\
    } while (0)

#define TclByteCodePop() TclByteCodePopCommon(&iPtr->operands)
#define TclByteCodeStringPop() TclByteCodePopCommon(&iPtr->strings)


/***********************************************************************
 *				TclByteCodePopArgs
 ***********************************************************************
 * SYNOPSIS:	    Pop a series of elements off the top of the operand
 *		    stack.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    any element data marked as dynamic is freed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
#define TclByteCodePopArgs(n) \
    do {\
	unsigned i;\
\
	for (i = 0; i < (n); i++) {\
	    TclByteCodePop();\
	}\
    } while (0)


/***********************************************************************
 *				TclByteCodeEvalOperand
 ***********************************************************************
 * SYNOPSIS:	    Evaluate the code body stored in the passed
 *		    stack element.
 * CALLED BY:	    (INTERNAL) TclByteCodeEval
 * RETURN:	    Tcl result
 * SIDE EFFECTS:    none here
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/24/93	Initial Revision
 *
 ***********************************************************************/
static int
TclByteCodeEvalOperand(Tcl_Interp   *interp,
		       const TclByteStackElement *elt)
{
    /* add this Tcl_Return here so that if the command is empty,
     * the result is the empty string
     */
    Tcl_Return(interp, NULL, TCL_STATIC);
    if (elt->eltType == TBSET_CODE) {
	return TclByteCodeEval(interp, elt->eltSize, elt->eltData);
    } else {
	return Tcl_Eval(interp,
			(const char *)elt->eltData,
			0,
			(const char **)NULL);
    }
}


/*
 *----------------------------------------------------------------------
 *
 * ByteProcDeleteProc --
 *
 *	This procedure is invoked just before a compiled procedure is
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

void
ByteProcDeleteProc(register ByteProc *procPtr)   /* Procedure to be deleted. */
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
 * ByteCodeProc --
 *
 *	When a compiled Tcl procedure gets invoked, this routine gets invoked
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
ByteCodeProc(ByteProc 	*procPtr,	/* Record describing procedure to be
					 * interpreted. */
	     Tcl_Interp *interp,	/* Interpreter in which procedure was
					 * invoked. */
	     int    	argc,	    	/* Count of number of arguments to this
					 * procedure. */
	     char   	**argv)	    	/* Argument values. */
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

	result = TclByteCodeEval(interp,
				 procPtr->size,
				 procPtr->code);
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
	ByteProcDeleteProc(procPtr);
    }
    return result;
}


/***********************************************************************
 *				TclByteCodeProcCmd
 ***********************************************************************
 * SYNOPSIS:	    Define a new byte-coded procedure.
 * CALLED BY:	    (INTERNAL) TclByteCodeEval
 * RETURN:	    TCL_OK if happiness reigns
 * SIDE EFFECTS:    existing command is biffed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
static int
TclByteCodeProcCmd(Tcl_Interp	    	*interp,
		   unsigned 	    	cmdFlags,
		   TclByteStackElement	*name,
		   TclByteStackElement	*args,
		   TclByteStackElement	*body)
{
    ByteProc *procPtr;
    int result;

    if (body->eltType == TBSET_STRING) {
	/*
	 * Byte-compile the string please.
	 */
	unsigned char *code;
	unsigned long len;

	code = TclByteCodeCompile(interp, (const char *)body->eltData, 0, 0, 0,
				  &len);
	if (code == 0) {
	    return (TCL_ERROR);
	}
	if (body->eltDynamic) {
	    free((char *)body->eltData);
	}
	body->eltData = code;
	body->eltDynamic = 1;
	body->eltType = TBSET_CODE;
	body->eltSize = len;
    }

    procPtr = (ByteProc *) malloc(sizeof(ByteProc)+body->eltSize);
    bcopy(body->eltData, procPtr->code, body->eltSize);
    procPtr->size = body->eltSize;

    assert(name->eltType == TBSET_STRING);
    assert(args->eltType == TBSET_STRING);

    result = TclProcCreateArgs(interp, (const char *)name->eltData,
			       (const char *)args->eltData,
			       &procPtr->argPtr, &cmdFlags);

    if (result == TCL_OK) {
	/*
	 * Register the command with the interpreter, binding our own InterpProc
	 * procedure to run it. If we were invoked as "defsubr", we make the
	 * name matching for our command be exact.
	 */
	procPtr->inuse = procPtr->delete = 0;

	Tcl_CreateCommand(interp,
			  (const char *)name->eltData,
			  (Tcl_CmdProc *)ByteCodeProc,
			  TCL_PROC | cmdFlags,
			  (ClientData) procPtr,
			  (Tcl_DelProc *)ByteProcDeleteProc);

	Tcl_Return(interp, NULL, TCL_STATIC);

	return TCL_OK;
    } else {
	TclDeleteVars(procPtr->argPtr);
	free((char *) procPtr);
	return result;
    }
}


/***********************************************************************
 *				TclByteCodeEval
 ***********************************************************************
 * SYNOPSIS:	    Evaluate a byte-code sequence
 * CALLED BY:	    (INTERNAL) ByteCodeProc, self
 * RETURN:	    standard Tcl return code + string in interp->result
 * SIDE EFFECTS:    just the usual.
 *
 * STRATEGY:
 *	    	strings are stored in-line as counted with a null-terminator.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/24/93	Initial Revision
 *
 ***********************************************************************/
int
TclByteCodeEval(Tcl_Interp    	    *interp,
		unsigned long  	    size,
		const unsigned char *data)
{
    const unsigned char   *p;
    Interp  	    *iPtr = (Interp *)interp;
    unsigned	    initTop = iPtr->operands.top;
    unsigned	    initSTop = iPtr->strings.top;
    int	    	    result = TCL_OK;
    const char	    *argvStore[16];
    const char 	    **argv = argvStore;
    int	    	    argc = sizeof(argvStore)/sizeof(argvStore[0]);
    char    	    argStore[256];
    char    	    *argTop = argStore;
    Frame   	    frame;

#define TRACE_BEFORE()	\
    if (bcDebug) {\
	Trace 	*tracePtr;\
\
	for (tracePtr = iPtr->tracePtr; tracePtr != NULL;\
	     tracePtr = tracePtr->nextPtr)\
	{\
	    if ((tracePtr->level < iPtr->numLevels) && tracePtr->level) {\
		continue;\
	    }\
	    (*tracePtr->callProc)(tracePtr->clientData, interp,\
				  (Tcl_Frame *)&frame);\
	}\
    }


#define TRACE_AFTER()	\
    if (bcDebug) {\
	Trace 	*tracePtr;\
\
	for (tracePtr = iPtr->tracePtr; tracePtr != NULL;\
	     tracePtr = tracePtr->nextPtr)\
	{\
	    if ((tracePtr->level < iPtr->numLevels) && tracePtr->level) {\
		continue;\
	    }\
	    (*tracePtr->returnProc)(tracePtr->clientData, interp,\
				    (Tcl_Frame *)&frame, result);\
	}\
    }


    iPtr->numLevels += 1;
    iPtr->cmdCount += 1;

    frame.protect = 0;
    frame.ext.cmdProc = 0;
    frame.ext.cmdFlags = 0;
    frame.ext.command = "bytecode";
    frame.sepArgs = 0;
    frame.ext.flags = 0;
    frame.ext.level = iPtr->numLevels;
    frame.ext.next = (Tcl_Frame *)iPtr->top;
    frame.ext.argv = argv;
    if (iPtr->top) {
	frame.localPtr = iPtr->top->localPtr;
    } else {
	frame.localPtr = &iPtr->globalFrame;
    }
    iPtr->top = &frame;

    p = data;

    while (p - data < size && result == TCL_OK) {
	TclByteOpcode op = *p++;

	switch (op) {
	case (int)TBOP_PUSH:
	{
	    /* args: string
	     * stack: -- string */
	    unsigned long   length;
	    const char *str = TclByteCodeFetchString(iPtr, &p, &length);

	    TclByteCodePush(iPtr, TBSET_STRING, 0, length, str);
	    continue;
	}
	case (int)TBOP_PUSHV:
	{
	    /* args: varname
	     * stack: -- varval-string */
	    const char *varname = TclByteCodeFetchString(iPtr, &p, NULL);
	    const char *val;

	    val = Tcl_GetVar(interp, varname, 0);

	    TclByteCodePush(iPtr, TBSET_STRING, 0, strlen(val), val);
	    continue;
	}
	case (int)TBOP_CODE:
	{
	    /* args: #bytes, bytes
	     * stack: -- code */
	    unsigned long length;

	    length = TclByteCodeFetchNum(&p);
	    TclByteCodePush(iPtr, TBSET_CODE, 0, length, p);

	    p += length;
	    continue;
	}
	case (int)TBOP_PUSHE:
	{
	    /* args: #bytes, bytes
	     * stack: -- code */
	    unsigned long length;

	    length = TclByteCodeFetchNum(&p);
	    TclByteCodePush(iPtr, TBSET_EXPR, 0, length, p);

	    p += length;
	    continue;
	}
	case (int)TBOP_PCALL:
	case (int)TBOP_CALL:
	{
	    /* args: #args, procname
	     * stack: #args-string-args -- retval */
	    unsigned long   nargs = TclByteCodeFetchNum(&p);
	    int	    	    i;
	    TclByteStackElement *arg;
	    Tcl_CmdProc	    *proc;
	    ClientData	    clientData;
	    unsigned	    extra = 0;

	    /*
	     * Make sure there are enough arguments on the operand stack.
	     */
	    assert(iPtr->operands.top - initTop >= nargs);

	    /*
	     * Setup argv for the command.
	     */
	    if (nargs + 1 > argc) {
		if (argv != argvStore) {
		    argv = (const char **)realloc((char *)argv,
						  ((nargs+2) *
						   sizeof(const char *)));
		} else {
		    argv = (const char **)malloc((nargs+2) *
						 sizeof(const char *));
		}
		frame.ext.argv = argv;
		frame.ext.flags |= TCL_FRAME_FREE_ARGV;
		argc = nargs + 1;
	    }
	    frame.ext.argc = nargs+1;

	    /*
	     * Locate the command record. If there's none, TclFindCmd will have
	     * set up iPtr->resultSpace properly, so we can just boogie.
	     */
	    if (op == TBOP_CALL) {
		const char *procname = TclByteCodeFetchString(iPtr, &p, NULL);
		Command 	    *cmd;

		if (*procname == '\0') {
		    /*
		     * This means the procedure to call was constructed
		     * as an extra argument on the stack.
		     */
		    extra = 1;
		    assert(ELT(nargs)->eltType == TBSET_STRING);

		    procname = ELT(nargs)->eltData;
		}

		cmd = TclFindCmd(iPtr, procname, 0);

		if (cmd == NULL) {
		    result = TCL_ERROR;
		    break;
		}
		proc = cmd->proc;
		clientData = cmd->clientData;
		frame.ext.cmdFlags = cmd->flags;
		argv[0] = procname;
	    } else {
		unsigned idx = TclByteCodeFetchNum(&p);

		if (idx >= numBuiltInCmds) {
		    Tcl_RetPrintf(interp, "unknown primitive #%d", idx);
		    result = TCL_ERROR;
		    break;
		}

		if (builtInCmds[idx]->data) {
		    if ((builtInCmds[idx]->data->subCommand == TCL_CMD_END) ||
			(builtInCmds[idx]->data->subCommand[0] == '\0' &&
			 builtInCmds[idx]->data[1].subCommand == TCL_CMD_END))
		    {
			/*
			 * The function of TclCmdCheckUsage has already
			 * been performed, so just call the procedure directly
			 */
			proc = builtInCmds[idx]->proc;
			clientData = builtInCmds[idx]->data->data;
		    } else {
			proc = TclCmdCheckUsage;
			clientData = (ClientData)builtInCmds[idx];
		    }
		} else {
		    proc = builtInCmds[idx]->proc;
		    clientData = 0;
		}
		argv[0] = builtInCmds[idx]->name;
		frame.ext.cmdFlags = builtInCmds[idx]->flags;
	    }


	    for (arg = ELT(nargs-1), i = 0; i < nargs; i++, arg++) {
		assert(arg->eltType == TBSET_STRING);
		argv[i+1] = arg->eltData;
	    }
	    argv[i+1] = (const char *)NULL;

	    frame.ext.cmdProc = proc;
	    frame.ext.cmdData = clientData;

	    /*
	     * Call the command after setting up interp->result and
	     * interp->dynamic as Tcl_Eval does.
	     */
	    Tcl_Return(interp, NULL, TCL_STATIC);

	    /*
	     * Call trace procedures, if any, then invoke the command.
	     */
	    TRACE_BEFORE();

	    result = (*proc)(clientData, interp, nargs+1, (char **)argv);

	    /*
	     * Pop the arguments off the stack.
	     */
	    TclByteCodePopArgs(nargs+extra);

	    /*
	     * Call the returnProcs for the traces
	     */
	    TRACE_AFTER();
	    break;
	}
	case (int)TBOP_IF:
	{
	    /* args: #args
	     * stack: (test-expr body-code)+ [else-code]  -- retval */
	    unsigned long   nargs = TclByteCodeFetchNum(&p);
	    int	    	    i;
	    TclByteStackElement *arg;

	    argv[0] = "bytecode if";
	    frame.ext.argc = 1;
	    frame.ext.cmdProc = 0;

	    TRACE_BEFORE();

	    /*
	     * Look for the proper body to execute, taking the first whose
	     * test-expr evaluates non-zero, or the last one that has no
	     * test-expr
	     */
	    for (arg = ELT(nargs-1), i = 0;
		 i < nargs;
		 i++, arg = ELT(nargs-1-i))
	    {
		int	testVal;

		if (i+1 != nargs) {
		    /*
		     * Must be at least 2 args left, so TOP is an expression.
		     * Evaluate it and pop the expression off the stack.
		     */
		    if (arg->eltType == TBSET_EXPR) {
			result = TclExprByteEval(interp,
						 arg->eltData,
						 arg->eltSize,
						 &testVal);
		    } else {
			assert(arg->eltType == TBSET_STRING);
			result = Tcl_Expr(interp, (const char *)arg->eltData,
					  &testVal);
		    }
		    i++;
		} else {
		    /*
		     * Final thing must be a code body. Pretend the result of
		     * evaluating the expression was true.
		     */
		    testVal = 1;
		}

		if (testVal) {
		    break;
		}
	    }

	    if (i != nargs) {
		/*
		 * arg is code to execute.
		 */
		result = TclByteCodeEvalOperand(interp, ELT(nargs-1-i));
	    } else {
		/*
		 * Result is the empty string.
		 */
		Tcl_Return(interp, NULL, TCL_STATIC);
	    }

	    /*
	     * Pop the args off the stack.
	     */
	    TclByteCodePopArgs(nargs);
	    TRACE_AFTER();
	    break;
	}
	case (int)TBOP_POP:
	    /* args:
	     * stack: string/code -- */
	    TclByteCodePop();
	    continue;
	case (int)TBOP_WHILE:
	{
	    /* args:
	     * stack: test-expr body-code -- retval */

	    argv[0] = "bytecode while";
	    frame.ext.argc = 1;
	    frame.ext.cmdProc = 0;

	    assert(iPtr->operands.top - initTop >= 2);

	    TRACE_BEFORE();

	    while (result == TCL_OK || result == TCL_CONTINUE) {
		int testVal;

		if (ELT(1)->eltType == TBSET_EXPR) {
		    result = TclExprByteEval(interp,
					     ELT(1)->eltData,
					     ELT(1)->eltSize,
					     &testVal);

		} else {
		    assert(ELT(1)->eltType == TBSET_STRING);

		    result = Tcl_Expr(interp, (const char *)ELT(1)->eltData,
				      &testVal);
		}

		if (result != TCL_OK || !testVal) {
		    break;
		}

		result = TclByteCodeEvalOperand(interp, ELT(0));
	    }

	    if (result == TCL_BREAK) {
		result = TCL_OK;
	    }
	    if (result == TCL_OK) {
		Tcl_Return(interp, (char *)NULL, TCL_STATIC);
	    }

	    TclByteCodePopArgs(2);
	    TRACE_AFTER();

	    break;
	}
	case (int)TBOP_FOR:
	{
	    /* args:
	     * stack: init-code test-expr next-code body-code -- retval */

	    argv[0] = "bytecode for";
	    frame.ext.argc = 1;
	    frame.ext.cmdProc = 0;

	    assert(iPtr->operands.top - initTop >= 4);

	    TRACE_BEFORE();

	    result = TclByteCodeEvalOperand(interp, ELT(3));

	    while (result == TCL_OK || result == TCL_CONTINUE) {
		int testVal;

		if (ELT(2)->eltType == TBSET_EXPR) {
		    result = TclExprByteEval(interp,
					     ELT(2)->eltData,
					     ELT(2)->eltSize,
					     &testVal);
		} else {
		    assert(ELT(2)->eltType == TBSET_STRING);

		    result = Tcl_Expr(interp, (const char *)ELT(2)->eltData,
				      &testVal);
		}

		if (result != TCL_OK || !testVal) {
		    break;
		}

		result = TclByteCodeEvalOperand(interp, ELT(0));
		if (result == TCL_OK || result == TCL_CONTINUE) {
		    result = TclByteCodeEvalOperand(interp, ELT(1));
		}
	    }

	    if (result == TCL_BREAK) {
		result = TCL_OK;
	    }
	    if (result == TCL_OK) {
		Tcl_Return(interp, (char *)NULL, TCL_STATIC);
	    }

	    TclByteCodePopArgs(4);

	    TRACE_AFTER();
	    break;
	}
	case (int)TBOP_CASE:
	{
	    /* args: #args
	     * stack: string (pattern-list body-code)+ -- retval */

	    TclByteStackElement	*def;	/* Body of default case */
	    unsigned long nargs;    	/* Number of args left to process */
	    const char *string;	    	/* String being matched */
	    TclByteStackElement *arg;
	    unsigned i;

	    argv[0] = "bytecode case";
	    frame.ext.argc = 1;
	    frame.ext.cmdProc = 0;

	    /*
	     * Extract the number of args for the case (including the string)
	     */
	    nargs = TclByteCodeFetchNum(&p);

	    /*
	     * Fetch the string to compare against the patterns & pop it.
	     */
	    assert(ELT(nargs-1)->eltType == TBSET_STRING);
	    string = ELT(nargs-1)->eltData;

	    /*
	     * Make sure the # of args is right and even (patterns & bodies
	     * must be paired)
	     */
	    assert(iPtr->operands.top - initTop >= nargs &&
		   !((nargs-1) & 1));

	    TRACE_BEFORE();

	    /*
	     * Indicate no default, as yet.
	     */
	    def = 0;

	    for (arg = ELT(nargs-2), i = 1; i < nargs; i += 2, arg += 2) {
		char	**patArgv;
		int 	patArgc;
		int 	j;

		/*
		 * Break up the pattern list into its individual patterns.
		 */
		assert(arg->eltType == TBSET_STRING);

		result = Tcl_SplitList(interp, arg->eltData,
				       &patArgc, &patArgv);
		if (result != TCL_OK) {
		    break;
		}

		/*
		 * Match each pattern against the string.
		 */
		for (j = 0; j < patArgc; j++) {
		    if (strcmp(patArgv[j], "default") == 0) {
			/*
			 * Found the default case. hold onto it.
			 */
			if (def != 0) {
			    free((char *)patArgv);
			    Tcl_Return(interp, "case has more than one default",
				       TCL_STATIC);
			    result = TCL_ERROR;
			    break;
			}

			/*
			 * Remember the body stack element in case nothing
			 * matches.
			 */
			def = arg+1;
		    } else if (Tcl_StringMatch(string, patArgv[j])) {
			break;
		    }
		}
		free((char *)patArgv);

		if (j != patArgc) {
		    /*
		     * We matched one of the patterns, so execute the body.
		     */
		    result = TclByteCodeEvalOperand(interp, arg+1);
		    break;
		}
		/*
		 * No match. Continue with the next pair.
		 */
	    }

	    if (i == nargs) {
		/*
		 * Nothing matched. Evaluate the default if one's there.
		 */
		if (def != 0) {
		    result = TclByteCodeEvalOperand(interp, def);
		} else {
		    /*
		     * No match, no default, but that's ok -- return the empty
		     * string.
		     */
		    Tcl_Return(interp, NULL, TCL_STATIC);
		}
	    }

	    /*
	     * Pop args off the stack.
	     */
	    TclByteCodePopArgs(nargs);

	    TRACE_AFTER();
	    break;
	}
	case (int)TBOP_ARGCAT:
	{
	    /* args: #strings
	     * stack: #strings-strings -- concatenation */
	    unsigned long nargs;
	    char *newstr, *next;
	    unsigned long len;
	    int	i;
	    TclByteStackElement *arg;
	    int dynamic;

	    nargs = TclByteCodeFetchNum(&p);

	    assert(iPtr->operands.top - initTop >= nargs);

	    dynamic = 0;

	    for (len = 1, i = 0, arg = ELT(nargs-1); i < nargs; i++, arg++) {
		assert(arg->eltType == TBSET_STRING);
		len += arg->eltSize;
		if (TBCInArgStore(arg)) {
		    dynamic = 1;
		}
	    }

	    if (!dynamic && argTop + len < &argStore[sizeof(argStore)]) {
		next = newstr = argTop;
		argTop += len;
	    } else {
		dynamic = 1;
		next = newstr = (char *)malloc(len);
	    }
	    for (i = 0, arg = ELT(nargs-1); i < nargs; i++, arg++) {
		bcopy(arg->eltData, next, arg->eltSize);
		next += arg->eltSize;
	    }
	    TclByteCodePopArgs(nargs);
	    *next = '\0';
	    TclByteCodePush(iPtr, TBSET_STRING, dynamic, len-1, newstr);
	    continue;
	}
	case (int)TBOP_PROC:
	{
	    /* args: flags
	     * stack: name-string arg-string body-code -- retval */
	    unsigned flags = TclByteCodeFetchNum(&p);

	    assert(iPtr->operands.top - initTop >= 3);

	    result = TclByteCodeProcCmd(interp, flags, ELT(2), ELT(1), ELT(0));
	    TclByteCodePopArgs(3);
	    break;
	}
	case (int)TBOP_HPROC:
	{
	    /* args: flags
	     * stack: name-string arg-string help-class-string help-string
	     *	      body-code -- retval */
	    unsigned flags = TclByteCodeFetchNum(&p);

	    assert(iPtr->operands.top - initTop >= 5);

	    result = TclByteCodeProcCmd(interp, flags, ELT(4), ELT(3), ELT(0));

	    if (result == TCL_OK && iPtr->helpSet != 0) {
		assert(ELT(1)->eltType == TBSET_STRING);
		assert(ELT(2)->eltType == TBSET_STRING);
		(*iPtr->helpSet)(ELT(4)->eltData,
				 ELT(2)->eltData,
				 ELT(1)->eltData);
	    }

	    TclByteCodePopArgs(5);
	    break;
	}
	case (int)TBOP_RET:
	    /* args:
	     * stack: retval -- */

	    assert(TOP->eltType == TBSET_STRING);

	    if (TBCInArgStore(TOP)) {
		/*
		 * In our private little heap. If it's small enough,
		 * copy it into resultSpace instead.
		 */
		if (TOP->eltSize + 1 <= sizeof(iPtr->resultSpace)) {
		    bcopy(TOP->eltData, iPtr->resultSpace, TOP->eltSize);
		    iPtr->resultSpace[TOP->eltSize] = '\0';

		    /*
		     * Return resultSpace, freeing any previous dynamic
		     * string.
		     */
		    Tcl_Return(interp, iPtr->resultSpace, TCL_STATIC);
		} else {
		    Tcl_Return(interp, TOP->eltData, TCL_VOLATILE);
		}
	    } else {
		/*
		 * Not in argStore, so we can return the thing directly.
		 * Note that we use TCL_VOLATILE instead of TCL_STATIC in the
		 * non-dynamic case, as the thing could be the value of a
		 * variable that's about to be nuked...
		 */
		Tcl_Return(interp, TOP->eltData,
			   TOP->eltDynamic ? TCL_DYNAMIC : TCL_VOLATILE);
		TOP->eltDynamic = 0;
	    }
	    TclByteCodePop();
	    result = TCL_RETURN;

	    break;
	case (int)TBOP_RETZ:
	    Tcl_Return(interp, NULL, TCL_STATIC);
	    result = TCL_RETURN;
	    break;
	case (int)TBOP_FOREACH:
	{
	    /* args:
	     * stack: var-name list-string body-code -- retval */
	    int listArgc, i;
	    char **listArgv;

	    argv[0] = "bytecode foreach";
	    frame.ext.argc = 1;
	    frame.ext.cmdProc = 0;

	    assert(iPtr->operands.top - initTop >= 3);
	    assert(ELT(2)->eltType == TBSET_STRING);
	    assert(ELT(1)->eltType == TBSET_STRING);

	    TRACE_BEFORE();

	    /*
	     * Break the list up into elements, and execute the command once
	     * for each value of the element.
	     */

	    result = Tcl_SplitList(interp, ELT(1)->eltData,
				   &listArgc, &listArgv);
	    if (result != TCL_OK) {
		break;
	    }
	    for (i = 0; i < listArgc; i++) {
		Tcl_SetVar(interp, ELT(2)->eltData, listArgv[i], 0);

		result = TclByteCodeEvalOperand(interp, ELT(0));
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
	    TclByteCodePopArgs(3);

	    TRACE_AFTER();
	    break;
	}
	case (int)TBOP_PROTECT:
	{
	    /* args:
	     * stack: body-code protect-code -- retval */
	    char *value;
	    int dynamic;

	    argv[0] = "bytecode protect";
	    frame.ext.argc = 1;
	    frame.ext.cmdProc = 0;

	    frame.protect = (char *)ELT(0)->eltData;
	    frame.psize =
		(ELT(0)->eltType == TBSET_STRING) ? 0 : ELT(0)->eltSize;

	    TRACE_BEFORE();

	    result = TclByteCodeEvalOperand(interp, ELT(1));
	    /*
	     * Save pointer to/duplicate result as necessary to preserve it
	     * from the evaluation of the protected command
	     */
	    if (iPtr->dynamic ||
		(iPtr->result != (const char *)iPtr->resultSpace))
	    {
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

	    frame.protect = 0;

	    /*
	     * Evaluate the protected command and blow away its return value
	     */
	    (void)TclByteCodeEvalOperand(interp, ELT(0));

	    Tcl_Return(interp, value, dynamic);
	    TclByteCodePopArgs(2);

	    TRACE_AFTER();
	    break;
	}
	case (int)TBOP_EXPR:
	{
	    /* args:
	     * stack: expr -- retval */
	    int	val;


	    argv[0] = "bytecode expr";
	    frame.ext.argc = 1;
	    frame.ext.cmdProc = 0;

	    assert (iPtr->operands.top - initTop >= 1);

	    TRACE_BEFORE();

	    if (ELT(0)->eltType == TBSET_EXPR) {
		result = TclExprByteEval(interp,
					 ELT(0)->eltData,
					 ELT(0)->eltSize,
					 &val);
	    } else {
		assert(ELT(0)->eltType == TBSET_STRING);

		result = Tcl_Expr(interp, (const char *)ELT(0)->eltData, &val);
	    }
	    if (result != TCL_ERROR) {
		Tcl_RetPrintf(interp, "%d", val);
	    }

	    TclByteCodePopArgs(1);

	    TRACE_AFTER();
	    break;
	}
	case (int)TBOP_FEXPR:
	{
	    /* args:
	     * stack: expr -- retval */
	    double	val;

	    argv[0] = "bytecode fexpr";
	    frame.ext.argc = 1;
	    frame.ext.cmdProc = 0;

	    assert (iPtr->operands.top - initTop >= 1);

	    TRACE_BEFORE();

	    if (ELT(0)->eltType == TBSET_EXPR) {
		result = TclFExprByteEval(interp,
					  ELT(0)->eltData,
					  ELT(0)->eltSize,
					  &val);
	    } else {
		assert(ELT(0)->eltType == TBSET_STRING);

		result = Tcl_FExpr(interp, (const char *)ELT(0)->eltData, &val);
	    }
	    if (result != TCL_ERROR) {
		Tcl_RetPrintf(interp, "%.16g", val);
	    }

	    TclByteCodePopArgs(1);

	    TRACE_AFTER();
	    break;
	}
	case (int)TBOP_PUSHST:
	{
	    /* args: #bytes, bytes
	     * stack: -- stringt */
	    unsigned long length;

	    length = TclByteCodeFetchNum(&p);
	    TclByteCodePush(iPtr, TBSET_STRING_TABLE, 0, length, p);

	    p += length;
	    continue;
	}
	case (int)TBOP_POPST:
	{
	    /* args:
	     * stack: string -- */

	    assert(iPtr->strings.top != 0);

	    TclByteCodeStringPop();
	    continue;
	}
	default:
	    Tcl_RetPrintf(interp, "unknown bytecode: %d", op);
	    result = TCL_ERROR;
	    break;
	}

	/*
	 * If not ok, get the heck out.
	 */
	if (result == TCL_OK) {
	    /*
	     * If next opcode not POP, push the result onto the operand
	     * stack.
	     */
	    if (p - data == size || *p != TBOP_POP) {
		if (!iPtr->dynamic && iPtr->result == iPtr->resultSpace) {
		    /*
		     * Result is in resultSpace variable, so we need to copy
		     * it lest it be biffed on the next call.
		     */
		    unsigned len = strlen(iPtr->result);

		    if (argTop + len + 1 < &argStore[sizeof(argStore)]) {
			/*
			 * It'll fit in our private stack, so put it there,
			 * rather than spending time mallocing room.
			 */
			bcopy(iPtr->result, argTop, len+1);
			iPtr->result = argTop;
			iPtr->dynamic = 0;
			argTop += len+1;
		    } else {
			char *cp = (char *)malloc(len+1);

			bcopy(iPtr->result, cp, len+1);
			iPtr->result = cp;
			iPtr->dynamic = 1;
		    }
		}
		TclByteCodePush(iPtr, TBSET_STRING, iPtr->dynamic,
				strlen(iPtr->result), iPtr->result);
		iPtr->dynamic = 0;
	    } else {
		/*
		 * Discard the result and skip the POP opcode.
		 */
		Tcl_Return(interp, NULL, TCL_STATIC);
		p++;
	    }
	}
    }

    assert(iPtr->operands.top >= initTop);

    if (result != TCL_OK) {
	/*
	 * In case of error, break, or return, clear all the shmutz off the
	 * stack that we put there.
	 *
	 * First find the earlier string table, if necessary.
	 */
	while (iPtr->strings.top != initSTop) {
	    TclByteCodeStringPop();
	}

	while (iPtr->operands.top != initTop) {
	    TclByteCodePop();
	}
    } else {
	/*
	 * Should be only one element on the stack, if any, and that's the
	 * return value.
	 */
	assert(iPtr->operands.top - initTop <= 1);
	assert(iPtr->operands.top >= initTop);

	if (iPtr->operands.top != initTop) {
	    assert(TOP->eltType == TBSET_STRING);

	    Tcl_Return(interp, TOP->eltData,
		       (TOP->eltDynamic ? TCL_DYNAMIC :
			(TBCInArgStore(TOP) ? TCL_VOLATILE : TCL_STATIC)));

	    TOP->eltDynamic = 0; /* String has been stolen... */
	    TclByteCodePop();
	}
    }

    /*
     * Free the argv allocated for calls, if any.
     */
    if (argv != argvStore) {
	free((char *)argv);
    }

    iPtr->numLevels -= 1;
    iPtr->top = (Frame *)frame.ext.next;

    return (result);
}

/***********************************************************************
 *				TclByteCodeResetStack
 ***********************************************************************
 * SYNOPSIS:	    Clear all the operands off the byte-code operand stack,
 *		    as the interpreter is being reset.
 * CALLED BY:	    (EXTERNAL) Tcl_TopLevel
 * RETURN:	    nothing
 * SIDE EFFECTS:    all dynamic operands are freed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/ 1/93	Initial Revision
 *
 ***********************************************************************/
void
TclByteCodeResetStack(Interp *iPtr)
{
    while (iPtr->operands.top != 0) {
	if (TOP->eltDynamic) {
	    free((malloc_t)TOP->eltData);
	}
	iPtr->operands.top -= 1;
    }
    while (iPtr->strings.top != 0) {
	if (iPtr->strings.stack[iPtr->strings.top-1].eltDynamic) {
	    free((malloc_t)iPtr->strings.stack[iPtr->strings.top-1].eltData);
	}
	iPtr->strings.top -= 1;
    }
}

/******************************************************************************
 *
 *			     COMPILATION
 *
 ******************************************************************************/
static void
TBCCDataInit(TBCCData	    *dataPtr,
	     int    	    noHelp,
	     int    	    allowJustVarRef,
	     TBCCStrings    *strings,
	     Tcl_Interp	    *interp)
{
    dataPtr->data = (unsigned char *)malloc(INIT_CODE_SIZE);
    dataPtr->tail = dataPtr->data;
    dataPtr->max = dataPtr->data + INIT_CODE_SIZE;
    dataPtr->noHelp = noHelp ? 1 : 0;
    dataPtr->allowJustVarRef = allowJustVarRef ? 1 : 0;
    dataPtr->interp = interp;
    dataPtr->level = 0;
    if (strings == 0) {
	dataPtr->strings = (TBCCStrings *)malloc(sizeof(TBCCStrings));
	dataPtr->strings->size = TBCC_STRING_INIT;
	dataPtr->strings->strings =
	    (unsigned char *)malloc(dataPtr->strings->size);
	dataPtr->strings->refs =
	    (unsigned short *)malloc(sizeof(unsigned short));

	/*
	 * Set the number of strings to 0
	 */
	dataPtr->strings->strings[0] =
	    dataPtr->strings->strings[1] = 0;
	/*
	 * Set the free pointer after the # of strings.
	 */
	dataPtr->strings->free = 2;
    } else {
	dataPtr->strings = strings;
    }
}


/***********************************************************************
 *				TBCCEnsureRoom
 ***********************************************************************
 * SYNOPSIS:	    Make sure there's enough room in the buffer for the
 *		    indicated additional bytes
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    dataPtr->data, dataPtr->tail, dataPtr->max updated
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/95	Initial Revision
 *
 ***********************************************************************/
static void
TBCCEnsureRoom(TBCCData	    	*dataPtr,
	       unsigned long	len)
{
    if (dataPtr->tail + len > dataPtr->max) {
	unsigned long tdiff;
	unsigned long newsize;

	/*
	 * Remember where the tail is currently, relative to the base, so we
	 * can reset the pointer should the buffer move.
	 */
	tdiff = dataPtr->tail - dataPtr->data;

	/*
	 * Make the buffer big enough for the data being copied in, plus
	 * the usual buffer-extension size.
	 */
	newsize = (dataPtr->tail + len + EXTEND_CODE_SIZE) - dataPtr->data;

	assert (newsize < 128*1024);

	dataPtr->data = (unsigned char *)realloc((malloc_t)dataPtr->data,
						 newsize);

	/*
	 * Reset the other pointers appropriately.
	 */
	dataPtr->max = dataPtr->data + newsize;
	dataPtr->tail = dataPtr->data + tdiff;
    }
}

/***********************************************************************
 *				TBCCOutputByte
 ***********************************************************************
 * SYNOPSIS:	    Append a byte to the passed buffer.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    buffer may move. dataPtr->tail incremented
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/30/93	Initial Revision
 *
 ***********************************************************************/
void
TBCCOutputByte(TBCCData *dataPtr,
	       unsigned char b)
{
    TBCCEnsureRoom(dataPtr, 1);

    *dataPtr->tail++ = b;
}


/***********************************************************************
 *				TBCCFormatNum
 ***********************************************************************
 * SYNOPSIS:	    Format the passed unsigned number into the passed
 *		    buffer for output.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    the number of bytes required
 * SIDE EFFECTS:    buffer overwritten
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/95	Initial Revision
 *
 ***********************************************************************/
static unsigned long
TBCCFormatNum(unsigned long n,
	     unsigned char buf[TBC_MAX_NUM])
{
    if (n < TBC_SHORT_NUM_MASK+1) {
	/*
	 * Fits in 1 byte...
	 */
	buf[0] = n;
	return(1);
    } else if (n < ((TBC_SHORT_NUM_MASK+1) << 8)) {
	/*
	 * Fits in 2 bytes -- store in big-endian order
	 */
	buf[0] = (n>>8) | TBC_EXTENDED_NUM;
	buf[1] = n & 0xff;
	return(2);
    } else {
	/*
	 * Store as full 4-byte number, in big-endian order.
	 */
	assert(n < (((unsigned long)TBC_SHORT_NUM_MASK+1) << 24));
	buf[0] = (n>>24) | TBC_EXTENDED_NUM | TBC_LONG_NUM;
	buf[1] = n >> 16;
	buf[2] = n >> 8;
	buf[3] = n & 0xff;
	return(4);
    }
}


/***********************************************************************
 *				TBCCOutputNum
 ***********************************************************************
 * SYNOPSIS:	    Use TBCCOutputByte to store an encoded number
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    1, 2, or 4 bytes are stored
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/30/93	Initial Revision
 *
 ***********************************************************************/
void
TBCCOutputNum(TBCCData *dataPtr,
	      unsigned long n)
{
    unsigned char   buf[TBC_MAX_NUM];
    unsigned long   len;

    len = TBCCFormatNum(n, buf);

    TBCCEnsureRoom(dataPtr, len);

    bcopy(buf, dataPtr->tail, len);

    dataPtr->tail += len;

}


/***********************************************************************
 *				TBCCOutputSignedNum
 ***********************************************************************
 * SYNOPSIS:	    Use TBCCOutputByte to store an encoded number
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    1, 2, or 4 bytes are stored
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/30/93	Initial Revision
 *
 ***********************************************************************/
void
TBCCOutputSignedNum(TBCCData *dataPtr,
		    long n)
{
#define FITS(n,bytes)	\
	(((n) & ((~TBC_SIGNED_SHORT_NUM_MASK) << (((bytes)-1)*8))) == \
	 (((n) & (TBC_SIGN_BIT << (((bytes)-1)*8))) ?\
	  ((~TBC_SIGNED_SHORT_NUM_MASK) << (((bytes)-1)*8)) : 0))

    if (FITS(n, 1)) {
	/*
	 * Fits in 1 byte...
	 */
	TBCCOutputByte(dataPtr, n & TBC_SHORT_NUM_MASK);
    } else if (FITS(n, 2)) {
	/*
	 * Fits in 2 bytes -- store in big-endian order
	 */
	TBCCOutputByte(dataPtr,
		       ((n>>8) & TBC_SHORT_NUM_MASK) | TBC_EXTENDED_NUM);
	TBCCOutputByte(dataPtr, n & 0xff);
    } else {
	/*
	 * Store as full 4-byte number, in big-endian order.
	 */
	assert(FITS(n, 4));
	TBCCOutputByte(dataPtr,
		       ((n>>24) & TBC_SHORT_NUM_MASK) |
		       TBC_EXTENDED_NUM | TBC_LONG_NUM);
	TBCCOutputByte(dataPtr, n >> 16);
	TBCCOutputByte(dataPtr, n >> 8);
	TBCCOutputByte(dataPtr, n & 0xff);
    }
}


/***********************************************************************
 *				TBCCOutputBytes
 ***********************************************************************
 * SYNOPSIS:	    Append a sequence of bytes to the buffer, performing
 *		    only 1 reallocation, if necessary
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    the usual
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/30/93	Initial Revision
 *
 ***********************************************************************/
void
TBCCOutputBytes(TBCCData *dataPtr,
	       const unsigned char *code,
	       unsigned long len)
{
    TBCCOutputNum(dataPtr, len);

    /* +1 is here for strings, which also use this routine */
    TBCCEnsureRoom(dataPtr, len + 1);

    bcopy(code, dataPtr->tail, len);
    dataPtr->tail += len;
}


/***********************************************************************
 *				TBCCOutputString
 ***********************************************************************
 * SYNOPSIS:	    Write a counted string to the output, adding the
 *		    necessary null terminator.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
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
void
TBCCOutputString(TBCCData *dataPtr,
		 const char *str,
		 unsigned long len)
{
    /*
     * Search for the string in the string table.
     */
    unsigned short  	    num;
    unsigned	    	    i;
    unsigned short  	    offset;
    unsigned char     	    *bp;

    /*
     * Put out the empty string in-line.
     */
    if (len == 0) {
	TBCCOutputByte(dataPtr, 0);
	TBCCOutputByte(dataPtr, 0);
	return;
    }

    num = dataPtr->strings->strings[0] | (dataPtr->strings->strings[1] << 8);

    for (bp = dataPtr->strings->strings+2, i = 0;
	 i < num;
	 i++, bp += 2)
    {
	const char    	    *tstr;

	offset = bp[0] | (bp[1] << 8);
	tstr = (const char *)(dataPtr->strings->strings+offset);
	if (str[0] == tstr[0] && strncmp(str, tstr, len) == 0 &&
	    tstr[len] == '\0')
	{
	    break;
	}
    }

    if (i == num) {
	/*
	 * Need to add the string to the table. First make sure there's enough
	 * room.
	 */
	int dorealloc = 0;
	unsigned char *strstart;

	if (dataPtr->strings->free + len + 1 + 2 > 65535) {
	    /*
	     * Won't fit in the table -- put it out straight.
	     */
	    TBCCOutputBytes(dataPtr, (const unsigned char *)str, len);
	    TBCCOutputByte(dataPtr, 0);
	    return;
	}

	while (len + 1 + 2 >
	       dataPtr->strings->size - dataPtr->strings->free)
	{
	    /*
	     * Adjust size by the requisite interval until it's big enough.
	     */
	    dataPtr->strings->size += TBCC_STRING_EXPAND;
	    dorealloc = 1;
	}

	/*
	 * Need to enlarge -- use realloc to do so.
	 */
	if (dorealloc) {
	    dataPtr->strings->strings =
		(unsigned char *)realloc((char *)dataPtr->strings->strings,
					 dataPtr->strings->size);
	}
	/*
	 * Make room for the pointer for the new string by copying the other
	 * strings up.
	 */
	strstart = dataPtr->strings->strings + (num+1)*2;
	bcopy(strstart,
	      strstart+2,
	      dataPtr->strings->free - (num+1)*2);

	/*
	 * Adjust the free offset to account for the move
	 */
	dataPtr->strings->free += 2;

	/*
	 * Increase the number of strings in the table.
	 */
	bp = dataPtr->strings->strings;
	*bp++ = num+1;
	*bp++ = (num+1) >> 8;

	dataPtr->strings->refs =
	    (unsigned short *)realloc((malloc_t)dataPtr->strings->refs,
				      (num+1)*sizeof(unsigned short));
	dataPtr->strings->refs[num] = 0;

	/*
	 * Now adjust the offsets for the existing strings by 2
	 */
	for (i = 0; i < num; i++) {
	    unsigned short offset;

	    offset = bp[0] | (bp[1] << 8);
	    offset += 2;
	    *bp++ = offset;
	    *bp++ = offset >> 8;
	}
	/*
	 * Set the offset for the new string
	 */
	*bp++ = dataPtr->strings->free;
	*bp++ = dataPtr->strings->free >> 8;

	/*
	 * Copy the new string in.
	 */
	strncpy(dataPtr->strings->strings + dataPtr->strings->free, str, len);

	/*
	 * Adjust the free pointer and null-terminate
	 */
	dataPtr->strings->free += len + 1;
	dataPtr->strings->strings[dataPtr->strings->free - 1] = '\0';

	/*
	 * i == num from the adjustment loop, and that's just what we need
	 * it to be.
	 */
    }
    /*
     * Count another reference to the string.
     */
    dataPtr->strings->refs[i] += 1;

    /*
     * Put out a 0 byte (to signal the indexed string) followed by the string
     * index (which is always 1-origin).
     */
    TBCCOutputByte(dataPtr, 0);
    TBCCOutputNum(dataPtr, i+1);
}


/***********************************************************************
 *				TBCCReplace
 ***********************************************************************
 * SYNOPSIS:	    Replace the indicated bytes in the code with the
 *		    passed bytes.
 * CALLED BY:	    (INTERNAL) TBCCReplaceNum,
 *			       TBCCChangeStringReferences
 * RETURN:	    nothing
 * SIDE EFFECTS:    dataPtr->data, dataPtr->tail, dataPtr->max updated
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/95	Initial Revision
 *
 ***********************************************************************/
static void
TBCCReplace(TBCCData	    	*dataPtr,
	    unsigned char   	*bp,	    /* Old bytes to replace */
	    unsigned	    	oldlen,	    /* The number of old bytes */
	    const unsigned char	*data,	    /* New bytes to use */
	    unsigned	    	len)	    /* The number of new bytes */
{
    int		    diff;

    assert (bp >= dataPtr->data && bp < dataPtr->tail);

    diff = len - oldlen;

    if (diff > 0) {
	unsigned long 	bpOff = bp - dataPtr->data;

	TBCCEnsureRoom(dataPtr, diff);

	bp = dataPtr->data + bpOff;
    }

    /*
     * Copy the old data up or down, as appropriate.
     */
    if (diff != 0) {
	bcopy(bp+oldlen, bp+len, dataPtr->tail - (bp+oldlen));
	dataPtr->tail += diff;
    }

    /*
     * Copy the new data into place.
     */
    if (data != 0) {
	bcopy(data, bp, len);
    }
}

/***********************************************************************
 *				TBCCReplaceNum
 ***********************************************************************
 * SYNOPSIS:	    Replace a number in the code with the passed bytes,
 *		    which may be a number or not; we don't care.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    dataPtr->data, dataPtr->tail, dataPtr->max updated
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/95	Initial Revision
 *
 ***********************************************************************/
static void
TBCCReplaceNum(TBCCData	    	    *dataPtr,
	       unsigned char	    *bp,    /* Start of number to replace */
	       const unsigned char  *data,  /* Data to replace it with */
	       unsigned	    	    len)
{
    unsigned char   *oldbp;

    oldbp = bp;
    TclByteCodeFetchNum((const unsigned char **)&bp);
    TBCCReplace(dataPtr, oldbp, bp - oldbp, data, len);
}


/***********************************************************************
 *				TBCCChangeReference
 ***********************************************************************
 * SYNOPSIS:	    Change a single string reference according to what
 *		    the string table says should happen, adjusting various
 *		    pointers and loop variables for our caller.
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    *pPtr, *basePtr, and *lenPtr adjusted
 *	    	    dataPtr->data, dataPtr->tail, dataPtr->max adjusted
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/95	Initial Revision
 *
 ***********************************************************************/
void
TBCCChangeReference(TBCCData	    	    *dataPtr,
		    unsigned char   	    **pPtr, 	/* IN: start of string
							 *     reference.
							 * OUT: past ref */
		    unsigned char   	    **basePtr,	/* IN: base of thing
							 *     containing ref.
							 * OUT: still base, but
							 *	possibly
							 *	moved */
		    unsigned long   	    *lenPtr,	/* IN: length of thing
							 *     with ref, or 0
							 * OUT: new length,
							 *	after ref
							 *	changed */
		    const TBCCStringChange  *changes)
{
    unsigned long   baseOff = *basePtr - dataPtr->data;
    unsigned char   *p = *pPtr;

    if ((*p != 0) || (p[1] == 0)) {
	unsigned long len = TclByteCodeFetchNum((const unsigned char **)&p);
	p += len + 1;
    } else {
	unsigned long i;

	p += 1;
	i = TclByteCodeFetchNum((const unsigned char **)&p);

	if (changes[i-1].data) {
	    /*
	     * Replacing the thing with the string itself.
	     */
	    unsigned char   buf[TBC_MAX_NUM];
	    unsigned long   lenlen;
	    unsigned long   pOff;
	    int	    	    diff;

	    pOff = *pPtr - dataPtr->data;

	    lenlen = TBCCFormatNum(changes[i-1].dataLen - 1, buf);

	    diff = (lenlen + changes[i-1].dataLen) - (p - *pPtr);

	    TBCCReplace(dataPtr, *pPtr, p - *pPtr, 0,
			lenlen + changes[i-1].dataLen);

	    p = dataPtr->data + pOff;
	    bcopy(buf, p, lenlen);
	    p += lenlen;
	    bcopy(changes[i-1].data, p, changes[i-1].dataLen);
	    p += changes[i-1].dataLen;

	    if (lenPtr) {
		*lenPtr += diff;
	    }
	    *basePtr = dataPtr->data + baseOff;
	} else if (changes[i-1].dataLen != i) {
	    /*
	     * Changing the index of the thing.
	     */
	    unsigned char   buf[TBC_MAX_NUM+1];
	    unsigned long   idxlen;
	    unsigned long   pOff;
	    int	    	    diff;

	    buf[0] = 0;		/* Signal string index */

	    idxlen = TBCCFormatNum(changes[i-1].dataLen, buf+1)+1;

	    pOff = *pPtr - dataPtr->data;

	    diff = idxlen - (p - *pPtr);

	    TBCCReplace(dataPtr, *pPtr, p - *pPtr, buf, idxlen);

	    p = dataPtr->data + pOff + idxlen;
	    if (lenPtr) {
		*lenPtr += diff;
	    }
	    *basePtr = dataPtr->data + baseOff;
	}
    }
    *pPtr = p;
}



/***********************************************************************
 *				TBCCChangeCodeStringReferences
 ***********************************************************************
 * SYNOPSIS:	    Change all the references to strings in the passed
 *		    bytecode
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    the code is expanded (or possibly shrunk) and the length
 *		    at the start adjusted
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/95	Initial Revision
 *
 ***********************************************************************/
void
TBCCChangeCodeStringReferences(TBCCData *dataPtr,
			       unsigned char **pPtr,
			       unsigned long *lenPtr,
			       const TBCCStringChange *changes)
{
    unsigned long   length; 	    	/* The length of the code to be
					 * changed */
    unsigned long   baseOff;   	    	/* Offset of *pPtr from the start
					 * of the containing block
					 * (dataPtr->data), for readjustment
					 * once all is complete. */
    unsigned char   *p;	    	    	/* Pointer into the code */
    unsigned char   buf[TBC_MAX_NUM];	/* Formatted new length */
    unsigned long   lenlen; 	    	/* Length of same */
    unsigned long   oldend; 	    	/* The old number of bytes from the
					 * start of the block to the end of
					 * this chunk of code, for adjusting
					 * *lenPtr at the end */

    /*
     * Remember the start of the data for fixing up the length
     */
    p = *pPtr;
    baseOff = p - dataPtr->data;

    /*
     * Find the length of the code and remember where it used to end.
     */
    length = TclByteCodeFetchNum((const unsigned char **)&p);
    oldend = (p + length) - dataPtr->data;

    /*
     * Fix up all the references in the code.
     */
    if (*p != TBOP_PUSHST) {
	length = TBCCChangeStringReferences(dataPtr, p, length, changes);

	/*
	 * Point back to the length.
	 */
	p = dataPtr->data + baseOff;

	/*
	 * Format the new length and put it over top of the old length.
	 */
	lenlen = TBCCFormatNum(length, buf);
	TBCCReplaceNum(dataPtr, p, buf, lenlen);

	/*
	 * Advance beyond the compressed code.
	 */
	p = dataPtr->data + baseOff + lenlen + length;

    } else {
	/*
	 * Embedded code has its own string table, so do nothing...
	 * XXX: This doesn't handle the case where a string table could come
	 * later in the code block, for some reason. happily, we don't ever
	 * create such a thing. If we ever do, we'll have to cope with
	 * pre-converted string references in the nested code block and
	 * assume that PUSHST and POPST opcodes are paired in some reasonable
	 * fashion.
	 */
	p += length;
    }

    *pPtr = p;

    /*
     * Adjust the length pointer, if given.
     */
    if (lenPtr) {
	*lenPtr += (p - dataPtr->data) - oldend;
    }
}


/***********************************************************************
 *				TBCCChangeStringReferences
 ***********************************************************************
 * SYNOPSIS:	    Change the string references in the passed code to
 *		    reflect the compression of the string table.
 * CALLED BY:	    (INTERNAL) TBCCCompressStringTable,
 *			       self,
 *			       TBCCChangeExprStringReferences
 * RETURN:	    the length of the new code
 * SIDE EFFECTS:    stuff moves
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/95	Initial Revision
 *
 ***********************************************************************/
static unsigned long
TBCCChangeStringReferences(TBCCData	    	    *dataPtr,
			   unsigned char	    *p,
			   unsigned long   	    len,
			   const TBCCStringChange   *changes)
{
    unsigned char *base = p;

/*    printf("Changing references in:\n");
    TclByteCodeDisasm(dataPtr->interp, p, len, dataPtr->level);
*/

    dataPtr->level += 2;

    while (p - base < len) {
	switch (*p++) {
	case (int)TBOP_PUSH:
	{
	    /* args: string
	     * stack: -- string */
	    TBCCChangeReference(dataPtr, &p, &base, &len, changes);
	    break;
	}
	case (int)TBOP_PUSHV:
	{
	    /* args: varname
	     * stack: -- varval-string */
	    TBCCChangeReference(dataPtr, &p, &base, &len, changes);
	    break;
	}
	case (int)TBOP_PCALL:
	{
	    /* args: #args, prim#
	     * stack: #args-string-args -- retval */
	    (void)TclByteCodeFetchNum((const unsigned char **)&p);
	    (void)TclByteCodeFetchNum((const unsigned char **)&p);
	    break;
	}
	case (int)TBOP_CALL:
	{
	    /* args: #args, procname
	     * stack: #args-string-args -- retval */
	    (void)TclByteCodeFetchNum((const unsigned char **)&p);
	    TBCCChangeReference(dataPtr, &p, &base, &len, changes);
	    break;
	}
	case (int)TBOP_IF:
	{
	    /* args: #args
	     * stack: (test-expr body-code)+ [else-code]  -- retval */
	    (void)TclByteCodeFetchNum((const unsigned char **)&p);
	    break;
	}
	case (int)TBOP_POP:
	    /* args:
	     * stack: string/code -- */
	    break;
	case (int)TBOP_CODE:
	{
	    /* args: #bytes, bytes
	     * stack: -- code */
	    unsigned long   baseOff;

	    baseOff = base - dataPtr->data;
	    TBCCChangeCodeStringReferences(dataPtr, &p, &len, changes);
	    base = dataPtr->data + baseOff;
	    break;
	}
	case (int)TBOP_WHILE:
	{
	    /* args:
	     * stack: test-expr body-code -- retval */
	    break;
	}
	case (int)TBOP_FOR:
	{
	    /* args:
	     * stack: init-code test-expr next-code body-code -- retval */
	    break;
	}
	case (int)TBOP_CASE:
	{
	    /* args: #args
	     * stack: string (pattern-list body-code)+ -- retval */

	    /*
	     * Extract the number of args for the case (including the string)
	     */
	    (void)TclByteCodeFetchNum((const unsigned char **)&p);
	    break;
	}
	case (int)TBOP_ARGCAT:
	{
	    /* args: #strings
	     * stack: #strings-strings -- concatenation */
	    (void)TclByteCodeFetchNum((const unsigned char **)&p);
	    break;
	}
	case (int)TBOP_PROC:
	{
	    /* args: flags
	     * stack: name-string arg-string body-code -- retval */
	    (void)TclByteCodeFetchNum((const unsigned char **)&p);
	    break;
	}
	case (int)TBOP_HPROC:
	{
	    /* args: flags
	     * stack: name-string arg-string help-class-string help-string
	     *	      body-code -- retval */
	    (void)TclByteCodeFetchNum((const unsigned char **)&p);
	    break;
	}
	case (int)TBOP_RET:
	    /* args:
	     * stack: retval -- */
	    break;
	case (int)TBOP_RETZ:
	    /* args:
	     * stack: -- */
	    break;
	case (int)TBOP_FOREACH:
	    /* args:
	     * stack: var-name list body-code -- retval */
	    break;
	case (int)TBOP_PROTECT:
	    /* args:
	     * stack: body-code protect-code -- retval */
	    break;
	case (int)TBOP_PUSHE:
	{
	    /*
	     * Change references within the expression
	     */
	    unsigned long pOff = p - dataPtr->data;
	    unsigned long elen =
		               TclByteCodeFetchNum((const unsigned char **)&p);
	    int	    	  elenlen = (p - dataPtr->data) - pOff;
	    unsigned long nlen;
	    unsigned char buf[TBC_MAX_NUM];
	    unsigned long lenlen;
	    unsigned long boff = base - dataPtr->data;

	    nlen = TclExprByteChangeStringReferences(dataPtr, p, elen, changes);
	    p = dataPtr->data + pOff;
	    lenlen = TBCCFormatNum(nlen, buf);
	    TBCCReplaceNum(dataPtr, p, buf, lenlen);

	    base = dataPtr->data + boff;
	    assert (dataPtr->data + pOff + nlen + lenlen >= base);
	    p = dataPtr->data + pOff + nlen + lenlen;
	    len += (nlen + lenlen) - (elen + elenlen);
	    break;
	}
	case (int)TBOP_EXPR:
	    break;
	case (int)TBOP_FEXPR:
	    break;
	case (int)TBOP_PUSHST:
	{
	    unsigned long len =
		               TclByteCodeFetchNum((const unsigned char **)&p);
	    p += len;
	    break;
	}
	case (int)TBOP_POPST:
	    break;
	}
	assert (p >= base);
    }

    dataPtr->level -= 2;
    assert(p >= base);
    return(p - base);
}

/***********************************************************************
 *				TBCCCompressStringTable
 ***********************************************************************
 * SYNOPSIS:	    Look at the number of references to each string
 *		    and decide if it was worth it to have it in the
 *		    string table, then adjust all the passed code
 *		    accordingly.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    the code may move
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	12/12/95	Initial Revision
 *
 ***********************************************************************/
static void
TBCCCompressStringTable(TBCCData    *dataPtr)
{
    unsigned 	    	numStrings; 	/* Number of strings in the current
					 * table */
    TBCCStringChange	*changes;   	/* What's happening to each string
					 * in the table */
    const unsigned char	*bp;	    	/* General pointer */
    unsigned 	    	i,  	    	/* Index into old table */
			j;	    	/* Index into new table */
    unsigned	    	newsize;    	/* Number of bytes of strings in the
					 * new table */
    unsigned char   	*newtable;
    unsigned char   	*newstr;

    numStrings = dataPtr->strings->strings[0] |
	(dataPtr->strings->strings[1] << 8);

    if (numStrings == 0) {
	return;
    }

    changes = (TBCCStringChange *)calloc(numStrings, sizeof(TBCCStringChange));

#ifdef DEBUG_STRING_COMPRESSION
    printf("compressing table at %x with %d strings over %d bytes of code:\n", dataPtr->strings, numStrings, dataPtr->tail - dataPtr->data);
#endif /* DEBUG_STRING_COMPRESSION */

    newsize = 0;

    for (j = 1, i = 0, bp = &dataPtr->strings->strings[2];
	 i < numStrings;
	 i++, bp += 2)
    {
	unsigned short	offset;
	unsigned short  next;
	unsigned    	refsize;
	unsigned    	strsize;

	/*
	 * Figure the offset of the next string so we can determine the length
	 * of this one.
	 */
	if (i == numStrings-1) {
	    next = dataPtr->strings->free;
	} else {
	    next = bp[2] | (bp[3] << 8);
	}

	/*
	 * Find the offset of this one.
	 */
	offset = bp[0] | (bp[1] << 8);

	/*
	 * Assume we'll be removing the index references to this string and
	 * point the change record to the string.
	 */
	changes[i].data = dataPtr->strings->strings+offset;
	changes[i].dataLen = next - offset;

	/*
	 * Compute how big each reference to this string would be.
	 */
	if (changes[i].dataLen - 1 < TBC_EXTENDED_NUM) {
	    /*
	     * Will fit in a non-extended number, so the string would have
	     * the size byte plus the string, with its null byte.
	     */
	    strsize = 1 + changes[i].dataLen;
	} else {
	    /*
	     * Must fit in a two-byte number for it to be in the table.
	     */
	    strsize = 2 + changes[i].dataLen;
	}

	/*
	 * Compute how big each index reference to the string is.
	 */
	if (i < TBC_EXTENDED_NUM) {
	    /*
	     * Initial null plus the index byte
	     */
	    refsize = 2;
	} else {
	    /*
	     * Initial null plus the index word
	     */
	    refsize = 3;
	}

	/*
	 * Now compare the size of the inline strings to the indexed references.
	 * Note that changes[i] is currently set up to change the indexed
	 * references to inline expansions.
	 */
#ifdef DEBUG_STRING_COMPRESSION
	printf("%4d: \"%.50s\" %d references (%d inline, %d indexed):",
	       i+1, changes[i].data, dataPtr->strings->refs[i], strsize,
	       refsize);
#endif /* DEBUG_STRING_COMPRESSION */

	changes[i].savings = (dataPtr->strings->refs[i] * strsize) -
	    (dataPtr->strings->refs[i] * refsize + 2 + changes[i].dataLen);

	if (changes[i].savings >= 0) {
	    /*
	     * The compressed references are smaller or the same size as
	     * the uncompressed versions, so leave the indexed references
	     * in, though we may reduce the index. The string will be in slot
	     * j in the end result.
	     */
	    newsize += changes[i].dataLen;

	    changes[i].data = 0;
	    changes[i].dataLen = j++;

#ifdef DEBUG_STRING_COMPRESSION
	    printf(" Changed to %d\n", changes[i].dataLen);
#endif /* DEBUG_STRING_COMPRESSION */

	}
#ifdef DEBUG_STRING_COMPRESSION
	else
	{
	    printf(" Deleted\n");
	}
#endif /* DEBUG_STRING_COMPRESSION */
    }

    /*
     * If all the strings are staying the same, we have nothing to do.
     */
    if (j == numStrings+1) {
	free((malloc_t)changes);
	return;
    }

    /*
     * Now make a second pass to determine whether there are too few
     * tokenized strings to justify the overhead of the table itself.
     * This only really happens if there are only one or two strings
     * left.
     */
    if (j < 4) {
	unsigned char	sizebuf[TBC_MAX_NUM];
	unsigned long	overhead;
	unsigned long	savings = 0;

	/*
	 * Compute the overhead for having the PUSHST and the POPST. It
	 * is the size of the opcodes (1 each) plus the size of the size of
	 * the table.
	 */
	overhead = TBCCFormatNum(newsize, sizebuf);
	overhead += 2;		/* one for PUSHST, one for POPST */

	/*
	 * Compute the total savings for having the string table using the
	 * changes table, where the savings were remembered for all the ones
	 * we're still keeping.
	 */
	for (i = 0; i < numStrings; i++) {
	    if (changes[i].data == 0) {
		savings += changes[i].savings;
	    }
	}

	if (savings <= overhead) {
	    /*
	     * Not worth it. Wipe out the entire table by restoring the
	     * string and length for those ones we were going to keep.
	     */
	    for (i = 0; i < numStrings; i++) {
		if (changes[i].data == 0) {
		    unsigned short offset;
		    unsigned short next;

		    /*
		     * Point to the offset to the string and compute the offset
		     */
		    bp = dataPtr->strings->strings + ((i+1) * 2);
		    offset = bp[0] + (bp[1] << 8);

		    /*
		     * Figure the offset of the next string so we can compute
		     * the length.
		     */
		    if (i == numStrings - 1) {
			next = dataPtr->strings->free;
		    } else {
			next = bp[2] | (bp[3] << 8);
		    }
		    /*
		     * Point the changes entry back at the string.
		     */
		    changes[i].data = dataPtr->strings->strings + offset;
		    changes[i].dataLen = next - offset;
		}
	    }
	    /*
	     * Set j to 1 to indicate no strings left.
	     */
	    j = 1;
	    newsize = 0;
	}
    }



    /*
     * Ok. We now know how we need to change the table. Now run through
     * the code doing it.
     */
    (void)TBCCChangeStringReferences(dataPtr,
				     dataPtr->data,
				     dataPtr->tail - dataPtr->data,
				     changes);

    /*
     * Now compress the table itself. First allocate the thing. j still
     * holds the index + 1 of the last string in the new table, from the
     * initial discovery loop.
     */
#ifdef DEBUG_STRING_COMPRESSION
    printf("--------------------\ncreating new table\n");
    printf("%d bytes in new table (%d strings)\n", newsize, j);
#endif /* DEBUG_STRING_COMPRESSION */

    newtable = (unsigned char *)malloc(j * sizeof(unsigned short) + newsize);
    newstr = newtable + j * sizeof(unsigned short);
    newtable[0] = j-1;
    newtable[1] = (j-1) >> 8;

    /*
     * Now loop through the old table copying the strings we're keeping into
     * their proper position in the new table. The new slots are assigned in
     * the same order as the old, so we can just have newstr run through the
     * string portion of the table.
     */
    for (i = 0, bp = &dataPtr->strings->strings[2];
	 i < numStrings;
	 i++, bp += 2)
    {
	if (changes[i].data == 0) {
	    /*
	     * Move the string down into the indicated slot.
	     */
	    unsigned	    len;
	    unsigned	    offset;

	    offset = bp[0] | (bp[1] << 8);

	    if (i == numStrings - 1) {
		len = dataPtr->strings->free - offset;
	    } else {
		len = (bp[2] | (bp[3] << 8)) - offset;
	    }
	    newtable[changes[i].dataLen * 2] = newstr - newtable;
	    newtable[changes[i].dataLen * 2 + 1] = (newstr - newtable) >> 8;
	    bcopy(&dataPtr->strings->strings[offset], newstr, len);
	    newstr += len;
	}
    }

    /*
     * Replace the old table with the new.
     */
    free((malloc_t)dataPtr->strings->strings);
    dataPtr->strings->strings = newtable;
    dataPtr->strings->size =
	dataPtr->strings->free = newstr - newtable;

#ifdef DEBUG_STRING_COMPRESSION
    printf("-----------------\nnew table:\n");
    for (i = 0; i < j-1; i++) {
	unsigned offset;

	offset= newtable[(i+1)*2] | (newtable[(i+1)*2+1] << 8);
	printf("%4d: \"%.50s\"\n", i+1, newtable+offset);
    }
#endif /* DEBUG_STRING_COMPRESSION */

    free((malloc_t)changes);
}


/***********************************************************************
 *				TBCCOutputPushIfNecessary
 ***********************************************************************
 * SYNOPSIS:	    Put out a PUSH opcode with the current argument
 *		    fragment, if it's there.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    *argCompsPtr is incremented if anything is written
 *		    out. dst should be reset to argv[argc] by the caller
 *		    in any case
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/30/93	Initial Revision
 *
 ***********************************************************************/
static void
TBCCOutputPushIfNecessary(TBCCData *dataPtr,
			  char *dst,	    /* first char after arg chars.
					     * will be after null byte if
					     * arg is empty and must be
					     * written out thus */
			  char **argv,
			  int argc,
			  unsigned *argCompsPtr,
			  int *needPopPtr)
{
    if (argc == 0 && *needPopPtr) {
	TBCCOutputByte(dataPtr, TBOP_POP);
	*needPopPtr = 0;
    }

    if (dst != argv[argc]) {
	TBCCOutputByte(dataPtr, TBOP_PUSH);
	if (dst[-1] == '\0') {
	    /*
	     * Special code to avoid writing two null-terminators.
	     */
	    TBCCOutputString(dataPtr, argv[argc], (dst-1) - argv[argc]);
	} else {
	    TBCCOutputString(dataPtr, argv[argc], dst - argv[argc]);
	}
	*argCompsPtr += 1;
    }
}


/***********************************************************************
 *				TBCCOutputCompiledArg
 ***********************************************************************
 * SYNOPSIS:	    Put out a CODE opcode with the passed string,
 *		    byte-compiled, as its contents.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    TCL_ERROR/TCL_OK
 * SIDE EFFECTS:    the usual
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/30/93	Initial Revision
 *
 ***********************************************************************/
static int
TBCCOutputCompiledArg(TBCCData *dataPtr,
		      Tcl_Interp *interp,
		      const char *arg,	/* String to compile */
		      int doPop,    	/* Non-zero if compiled code
					 * should discard its result */
		      TBCCStrings *strings) /* String table to use, or 0 if
					     * compiled arg should have its
					     * own */
{
    unsigned long length;
    unsigned char *nested;

    nested = TclByteCodeCompileTop(interp, arg, 0,
				   doPop ? TBCC_DISCARD : 0,
				   strings, 0, &length);
    if (nested == 0) {
	return (TCL_ERROR);
    }
    TBCCOutputByte(dataPtr, TBOP_CODE);
    TBCCOutputBytes(dataPtr, nested, length);

    free((char *)nested);
    return (TCL_OK);
}


/***********************************************************************
 *				TBCCOutputCompiledExpr
 ***********************************************************************
 * SYNOPSIS:	    Put out an operand that may be a compiled expression.
 * CALLED BY:	    (INTERNAL) TBCCIfArgProc, TBCCFixedArgProc,
 *			       TBCCExprArgProc
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    the expression is put out, either as a PUSHE or a
 *		    PUSHV opcode.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/11/94		Initial Revision
 *
 ***********************************************************************/
static int
TBCCOutputCompiledExpr(TBCCData *dataPtr,
		       Tcl_Interp *interp,
		       const char *arg,
		       int  allowJustVarRef)	/* Non-zero if an expression
						 * of just a variable reference
						 * should be compiled; if the
						 * variable is allowed to
						 * contain an expression, this
						 * should be false */
{
    TBCCData	data;
    int	    	result;

    TBCCDataInit(&data, 0, allowJustVarRef, dataPtr->strings, dataPtr->interp);
    result = TclExprByteCompile(interp, arg, &data);
    if (result == TCL_BREAK) {
	/*
	 * Expression is just a variable reference, so put that out instead.
	 * This is primarily a space optimization, but gives some speed
	 * improvement, too.
	 */
	int vlen;
	const char *name;

	while (*arg != '$') {
	    arg++;
	}
	/* scan off the variable name */
	name = TclProcScanVar(interp, arg, &vlen, NULL);

	TBCCOutputByte(dataPtr, TBOP_PUSHV);
	TBCCOutputString(dataPtr, name, vlen);
	result = TCL_OK;
    } else if (result == TCL_OK) {
	TBCCOutputByte(dataPtr, TBOP_PUSHE);
	TBCCOutputBytes(dataPtr, data.data, data.tail - data.data);
    }
    free((char *)data.data);
    return result;
}

/*
 * Definitions for compiling the various special primitives.
 */
typedef enum IfState {
    IFS_EXPR, IFS_CODE, IFS_OPT_ELSE, IFS_FINAL_CODE, IFS_DONE,
    IFS_OPT_THEN
} IfState;

typedef enum CaseState {
    CS_STRING, CS_OPT_IN, CS_PAT, CS_CODE
} CaseState;

typedef union {	    	    /* State variables for all possible commands */
    IfState 	ifState;
    CaseState	caseState;
} CmdState;

typedef struct _SpecialCmd *SpecialCmdPtr;

typedef void TBCCCmdInitProc(TBCCData *dataPtr,
			     CmdState *cmdStatePtr);

typedef int TBCCArgProc(TBCCData *dataPtr,
			Tcl_Interp *interp,
			unsigned argComps,
			unsigned wasQuoted,
			CmdState *cmdStatePtr,
			SpecialCmdPtr *curCmdPtr,
			char *dst,
			char **argv,
			int *argcPtr);

typedef int TBCCCompileProc(TBCCData *dataPtr,
			    Tcl_Interp *interp,
			    char **argv,
			    int argc,
			    CmdState cmdState,
			    SpecialCmdPtr curCmd);

static TBCCCmdInitProc	TBCCIfInitProc;
static TBCCCmdInitProc	TBCCCaseInitProc;
static TBCCCmdInitProc	TBCCNullInitProc;

static TBCCArgProc  	TBCCIfArgProc;
static TBCCArgProc	TBCCProcArgProc;
static TBCCArgProc	TBCCCaseArgProc;
static TBCCArgProc	TBCCRetArgProc;
static TBCCArgProc	TBCCFixedArgProc;
static TBCCArgProc	TBCCExprArgProc;
static TBCCArgProc	TBCCOtherArgProc;

static TBCCCompileProc  TBCCIfCompileProc;
static TBCCCompileProc	TBCCProcCompileProc;
static TBCCCompileProc	TBCCCaseCompileProc;
static TBCCCompileProc	TBCCRetCompileProc;
static TBCCCompileProc	TBCCFixedCompileProc;
static TBCCCompileProc	TBCCExprCompileProc;
static TBCCCompileProc	TBCCOtherCompileProc;

typedef struct _SpecialCmd {
    enum CmdType {
	CMD_IF, CMD_FOR, CMD_WHILE, CMD_PROC, CMD_DEFSUBR,
	CMD_DEFCOMMAND, CMD_DEFCMD, CMD_CASE, CMD_RET, CMD_FOREACH,
	CMD_PROTECT, CMD_EXPR, CMD_OTHER
    }   	    	token;	    	    /* So we know easily what special
					     * command we're compiling */
    const char  	*name;	    	    /* Name of the thing, for comparison
					     * purposes */
    TBCCCmdInitProc 	*initProc;  	    /* Function to call to initialize
					     * the CmdState variable for this
					     * command */
    TBCCArgProc	    	*argProc;   	    /* Function to call to compile
					     * an argument */
    TBCCCompileProc 	*compileProc;	    /* Function to call to compile the
					     * command opcode */
    unsigned   	    	numArgs;    	    /* Fixed number of args the command
					     * takes */
    unsigned	    	codeArgs;   	    /* Mask of arguments that are Tcl
					     * code and thus should be
					     * compiled if possible */
    unsigned	    	exprArgs;   	    /* Mask of arguments that are Tcl
					     * expressions and thus should be
					     * compiled if possible */
    TclByteOpcode   	opcode;	    	    /* Byte-code opcode to put out */
} SpecialCmd;

static SpecialCmd cmds[] = {
    {
	CMD_IF,
	"if",
	TBCCIfInitProc,
	TBCCIfArgProc,
	TBCCIfCompileProc
    },
    {
	CMD_FOR,
	"for",
	TBCCNullInitProc,
	TBCCFixedArgProc,
	TBCCFixedCompileProc,
	4,
	(1<<0)|(1<<2)|(1<<3),
	(1<<1),
	TBOP_FOR
    },
    {
	CMD_WHILE,
	"while",
	TBCCNullInitProc,
	TBCCFixedArgProc,
	TBCCFixedCompileProc,
	2,
	(1<<1),
	(1<<0),
	TBOP_WHILE
    },
    {
	CMD_PROC,
	"proc",
	TBCCNullInitProc,
	TBCCProcArgProc,
	TBCCProcCompileProc,
	0,
	0,
	0,
	TBOP_PROC
    },
    {
	CMD_DEFSUBR,
	"defsubr",
	TBCCNullInitProc,
	TBCCProcArgProc,
	TBCCProcCompileProc,
	0,
	0,
	0,
	TBOP_PROC
    },
    {
	CMD_DEFCOMMAND,
	"defcommand",
	TBCCNullInitProc,
	TBCCProcArgProc,
	TBCCProcCompileProc,
	0,
	0,
	0,
	TBOP_HPROC
    },
    {
	CMD_DEFCMD,
	"defcmd",
	TBCCNullInitProc,
	TBCCProcArgProc,
	TBCCProcCompileProc,
	0,
	0,
	0,
	TBOP_HPROC
    },
    {
	CMD_CASE,
	"case",
	TBCCCaseInitProc,
	TBCCCaseArgProc,
	TBCCCaseCompileProc
    },
    {
	CMD_RET,
	"return",
	TBCCNullInitProc,
	TBCCRetArgProc,
	TBCCRetCompileProc
    },
    {
	CMD_FOREACH,
	"foreach",
	TBCCNullInitProc,
	TBCCFixedArgProc,
	TBCCFixedCompileProc,
	3,
	(1<<2),
	0,
	TBOP_FOREACH
    },
    {
	CMD_PROTECT,
	"protect",
	TBCCNullInitProc,
	TBCCFixedArgProc,
	TBCCFixedCompileProc,
	2,
	(1<<0)|(1<<1),
	0,
	TBOP_PROTECT
    },
    {
	CMD_EXPR,
	"expr",
	TBCCNullInitProc,
	TBCCExprArgProc,
	TBCCExprCompileProc,
	1,
	0,
	(1<<0),
	TBOP_EXPR
    },
    {
	CMD_OTHER,
	0,
	TBCCNullInitProc,
	TBCCOtherArgProc,
	TBCCOtherCompileProc
    }
};


/***********************************************************************
 *				TBCCNullInitProc
 ***********************************************************************
 * SYNOPSIS:	    Do-nothing state-variable initialization procedure
 * CALLED BY:	    (INTERNAL) TclByteCompileLow
 * RETURN:	    nothing
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/14/94		Initial Revision
 *
 ***********************************************************************/
static void
TBCCNullInitProc(TBCCData   *dataPtr,
		 CmdState   *cmdStatePtr)
{
}


/***********************************************************************
 *				TBCCIfInitProc
 ***********************************************************************
 * SYNOPSIS:	    State-variable initialization procedure
 * CALLED BY:	    (INTERNAL TclByteCompileLow
 * RETURN:	    nothing
 * SIDE EFFECTS:    cmdStatePtr->ifState initialized
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/14/94		Initial Revision
 *
 ***********************************************************************/
static void
TBCCIfInitProc(TBCCData	*dataPtr,
	       CmdState	*cmdStatePtr)
{
    cmdStatePtr->ifState = IFS_EXPR;
}

/***********************************************************************
 *				TBCCIfCompileProc
 ***********************************************************************
 * SYNOPSIS:	    Finish compiling an "if"
 * CALLED BY:	    (INTERNAL) TclByteCodeCompileLow
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
static int
TBCCIfCompileProc(TBCCData *dataPtr,
		  Tcl_Interp *interp,
		  char **argv,
		  int argc,
		  CmdState cmdState,
		  SpecialCmdPtr curCmd)
{
    if (cmdState.ifState != IFS_DONE && cmdState.ifState != IFS_OPT_ELSE) {
	Tcl_Error(interp, "malformed \"if\": not enough arguments");
    }
    TBCCOutputByte(dataPtr, TBOP_IF);
    TBCCOutputNum(dataPtr, argc-1);
    return (TCL_OK);
}


/***********************************************************************
 *				TBCCIfArgProc
 ***********************************************************************
 * SYNOPSIS:	    Cope with the closure of another argument when
 *		    compiling an "if" command
 * CALLED BY:	    (INTERNAL) TclByteCodeCompileLow
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    stuff may be emitted.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
static int
TBCCIfArgProc(TBCCData 	    	    *dataPtr,	    /* For emitting code */
	      Tcl_Interp    	    *interp,	    /* For error messages */
	      unsigned 	    	    argComps,	    /* # of components in
						     * current arg, excluding
						     * what's in argv[*argcPtr]
						     * currently */
	      unsigned	    	    wasQuoted,
	      CmdState 	    	    *cmdStatePtr,   /* State of parsing "if" */
	      SpecialCmdPtr    	    *curCmdPtr,     /* For switching to a
						     * different type of
						     * command */
	      char  	    	    *dst,   	    /* After null-term in arg */
	      char  	    	    **argv, 	    /* Complete arg vector */
	      int   	    	    *argcPtr)       /* Arg # just finished */
{
    int	    result;

    /*
     * If "else" or "elif" allowed, look for them.
     */
    if (cmdStatePtr->ifState == IFS_OPT_ELSE) {
	if (strcmp(argv[*argcPtr], "else") == 0) {
	    cmdStatePtr->ifState = IFS_FINAL_CODE;
	    *argcPtr -= 1;	/* Discard argument */
	    return (TCL_OK);
	} else if (strcmp(argv[*argcPtr], "elif")==0) {
	    cmdStatePtr->ifState = IFS_EXPR;
	    *argcPtr -= 1;	/* Discard argument */
	    return (TCL_OK);
	}
	/*
	 * If absent optional else or elif, it means an "else" is missing, so
	 * this arg is the final body allowed.
	 */
	cmdStatePtr->ifState = IFS_FINAL_CODE;
    }

    /*
     * If a "then" is allowed here, look for it.
     */
    if (cmdStatePtr->ifState == IFS_OPT_THEN) {
	if (strcmp(argv[*argcPtr], "then") == 0) {
	    cmdStatePtr->ifState = IFS_CODE;
	    *argcPtr -= 1;	/* Discard argument */
	    return (TCL_OK);
	}
	/*
	 * If no "then", this thing must be code.
	 */
	cmdStatePtr->ifState = IFS_CODE;
    }

    if (cmdStatePtr->ifState == IFS_CODE || cmdStatePtr->ifState == IFS_FINAL_CODE) {
	/*
	 * If just a string, we can compile it now.
	 */
	if (argComps == 0) {
	    result = TBCCOutputCompiledArg(dataPtr, interp, argv[*argcPtr], 0,
					   dataPtr->strings);
	    if (result != TCL_OK) {
		return (result);
	    }

	    if (cmdStatePtr->ifState == IFS_CODE) {
		cmdStatePtr->ifState = IFS_OPT_ELSE;
	    } else {
		cmdStatePtr->ifState = IFS_DONE;
	    }
	    return (TCL_OK);
	} else {
	    /*
	     * Not just a string, so can't compile. Set the state for the
	     * next arg properly, though.
	     */
	    if (cmdStatePtr->ifState == IFS_FINAL_CODE) {
		cmdStatePtr->ifState = IFS_DONE;
	    } else {
		cmdStatePtr->ifState = IFS_OPT_ELSE;
	    }
	}
    } else if (cmdStatePtr->ifState == IFS_DONE) {
	Tcl_Return(interp, "too many arguments to \"if\"", TCL_STATIC);
	return (TCL_ERROR);
    } else {
	/*
	 * The next state following an expression is an optional THEN
	 */
	assert(cmdStatePtr->ifState == IFS_EXPR);
	cmdStatePtr->ifState = IFS_OPT_THEN;
	if (argComps == 0) {
	    return TBCCOutputCompiledExpr(dataPtr, interp, argv[*argcPtr],
					  wasQuoted);
	}
    }

    return (TBCCOtherArgProc(dataPtr, interp, argComps, wasQuoted, cmdStatePtr,
			     curCmdPtr, dst, argv, argcPtr));
}

/***********************************************************************
 *				TBCCFixedCompileProc
 ***********************************************************************
 * SYNOPSIS:	    Finish compiling something that always takes the
 *		    same number of args.
 * CALLED BY:	    (INTERNAL) TclByteCodeCompileLow
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
static int
TBCCFixedCompileProc(TBCCData *dataPtr,
		  Tcl_Interp *interp,
		  char **argv,
		  int argc,
		  CmdState cmdState,
		   SpecialCmdPtr curCmd)
{
    if (argc != curCmd->numArgs + 1) {
	Tcl_RetPrintf(interp, "malformed \"%s\": not enough arguments",
		      curCmd->name);
	return (TCL_ERROR);
    }
    TBCCOutputByte(dataPtr, curCmd->opcode);
    return (TCL_OK);
}


/***********************************************************************
 *				TBCCFixedArgProc
 ***********************************************************************
 * SYNOPSIS:	    Cope with the closure of another argument when
 *		    compiling a command that takes a fixed number of args
 * CALLED BY:	    (INTERNAL) TclByteCodeCompileLow
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    stuff may be emitted.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
static int
TBCCFixedArgProc(TBCCData    	    *dataPtr,	    /* For emitting code */
	      Tcl_Interp    	    *interp,	    /* For error messages */
	      unsigned 	    	    argComps,	    /* # of components in
						     * current arg, excluding
						     * what's in argv[*argcPtr]
						     * currently */
	      unsigned	    	    wasQuoted,
	      CmdState 	    	    *cmdStatePtr,   /* State of parsing "if" */
	      SpecialCmdPtr   	    *curCmdPtr,     /* For switching to a
						     * different type of
						     * command */
	      char  	    	    *dst,   	    /* After null-term in arg */
	      char  	    	    **argv, 	    /* Complete arg vector */
	      int   	    	    *argcPtr)  	    /* Arg # just finished */
{
    if ((argComps == 0) &&
	((*curCmdPtr)->codeArgs & (1 << ((*argcPtr) - 1))))
    {
	return (TBCCOutputCompiledArg(dataPtr, interp, argv[*argcPtr], 1,
				      dataPtr->strings));
    } else if ((argComps == 0) &&
	       ((*curCmdPtr)->exprArgs & (1 << ((*argcPtr) - 1))))
    {
	return (TBCCOutputCompiledExpr(dataPtr, interp, argv[*argcPtr],
				       wasQuoted));
    } else if (*argcPtr > (*curCmdPtr)->numArgs) {
	Tcl_RetPrintf(interp, "too many arguments to \"%s\"",
		      (*curCmdPtr)->name);
	return (TCL_ERROR);
    }

    return (TBCCOtherArgProc(dataPtr, interp, argComps, wasQuoted, cmdStatePtr,
			     curCmdPtr, dst, argv, argcPtr));
}

/***********************************************************************
 *				TBCCExprCompileProc
 ***********************************************************************
 * SYNOPSIS:	    Finish compiling an EXPR or FEXPR thing
 * CALLED BY:	    (INTERNAL) TclByteCodeCompileLow
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
static int
TBCCExprCompileProc(TBCCData *dataPtr,
		  Tcl_Interp *interp,
		  char **argv,
		  int argc,
		  CmdState cmdState,
		   SpecialCmdPtr curCmd)
{
    if (argc == 2) {
	TBCCOutputByte(dataPtr, TBOP_EXPR);
    } else if (argc == 3) {
	TBCCOutputByte(dataPtr, TBOP_FEXPR);
    } else {
	Tcl_RetPrintf(interp, "malformed \"%s\": not enough arguments",
		      curCmd->name);
	return (TCL_ERROR);
    }
    return (TCL_OK);
}


/***********************************************************************
 *				TBCCExprArgProc
 ***********************************************************************
 * SYNOPSIS:	    Cope with the closure of another argument when
 *		    compiling a command that takes a fixed number of args
 * CALLED BY:	    (INTERNAL) TclByteCodeCompileLow
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    stuff may be emitted.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
static int
TBCCExprArgProc(TBCCData    	    *dataPtr,	    /* For emitting code */
	      Tcl_Interp    	    *interp,	    /* For error messages */
	      unsigned 	    	    argComps,	    /* # of components in
						     * current arg, excluding
						     * what's in argv[*argcPtr]
						     * currently */
	      unsigned		    wasQuoted,
	      CmdState 	    	    *cmdStatePtr,   /* State of parsing "if" */
	      SpecialCmdPtr   	    *curCmdPtr,     /* For switching to a
						     * different type of
						     * command */
	      char  	    	    *dst,   	    /* After null-term in arg */
	      char  	    	    **argv, 	    /* Complete arg vector */
	      int   	    	    *argcPtr)  	    /* Arg # just finished */
{
    if ((argComps == 0) && (*argcPtr == 1)) {
	return (TBCCOutputCompiledExpr(dataPtr, interp, argv[*argcPtr],
				       wasQuoted));
    } else if (*argcPtr > 2) {
	Tcl_RetPrintf(interp, "too many arguments to \"%s\"",
		      (*curCmdPtr)->name);
	return (TCL_ERROR);
    } else if (*argcPtr == 1) {
	return (TBCCOtherArgProc(dataPtr, interp, argComps, wasQuoted,
				 cmdStatePtr, curCmdPtr, dst, argv, argcPtr));
    } else if (argComps != 0) {
	Tcl_Error(interp, "second argument to \"expr\" must be the string \"float\" or some substring of it");
    } else {
	/*
	 * Leave 2d arg unoutput.
	 */
	return (TCL_OK);
    }
}

/***********************************************************************
 *				TBCCProcCompileProc
 ***********************************************************************
 * SYNOPSIS:	    Finish compiling a "proc" or "defsubr"
 * CALLED BY:	    (INTERNAL) TclByteCodeCompileLow
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
static int
TBCCProcCompileProc(TBCCData *dataPtr,
		  Tcl_Interp *interp,
		  char **argv,
		  int argc,
		  CmdState cmdState,
		    SpecialCmdPtr curCmd)
{
    if (argc != (curCmd->opcode == TBOP_PROC ? 4 : 6)) {
	Tcl_RetPrintf(interp, "malformed \"%s\": not enough arguments",
		      argv[0]);
	return (TCL_ERROR);
    }

    if (dataPtr->noHelp) {
	/*
	 * When not compiling in help, the opcode is always PROC
	 */
	TBCCOutputByte(dataPtr, TBOP_PROC);
    } else {
	TBCCOutputByte(dataPtr, curCmd->opcode);
    }
    if (curCmd->opcode == TBOP_PROC) {
	TBCCOutputNum(dataPtr, argv[0][0] == 'p' ? 0 : TCL_EXACT);
    } else {
	TBCCOutputNum(dataPtr, argv[0][4] == 'm' ? 0 : TCL_EXACT);
    }
    return (TCL_OK);
}


/***********************************************************************
 *				TBCCProcArgProc
 ***********************************************************************
 * SYNOPSIS:	    Cope with the closure of another argument when
 *		    compiling a "proc" or "defsubr" command
 * CALLED BY:	    (INTERNAL) TclByteCodeCompileLow
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    stuff may be emitted.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
static int
TBCCProcArgProc(TBCCData    	    *dataPtr,	    /* For emitting code */
	      Tcl_Interp    	    *interp,	    /* For error messages */
	      unsigned 	    	    argComps,	    /* # of components in
						     * current arg, excluding
						     * what's in argv[*argcPtr]
						     * currently */
	      unsigned    	    wasQuoted,
	      CmdState 	    	    *cmdStatePtr,   /* State of parsing "if" */
	      SpecialCmdPtr   	    *curCmdPtr,     /* For switching to a
						     * different type of
						     * command */
	      char  	    	    *dst,   	    /* After null-term in arg */
	      char  	    	    **argv, 	    /* Complete arg vector */
	      int   	    	    *argcPtr)  	    /* Arg # just finished */
{
    int	    result;
    int	    lastArg = (((*curCmdPtr)->opcode == TBOP_PROC) ? 3 : 5);

    if (argComps == 0 && *argcPtr == lastArg) {
	result = TBCCOutputCompiledArg(dataPtr, interp, argv[*argcPtr], 0,
				       (TBCCStrings *)0);
	if (result != TCL_OK) {
	    if (interp->result == ((Interp *)interp)->resultSpace) {
		char *cp = (char *)interp->result + strlen(interp->result);

		sprintf(cp, ", compiling \"%.50s\"", argv[1]);
	    } else {
		sprintf(((Interp *)interp)->resultSpace,
			"%s, compiling \"%.50s\"", interp->result, argv[1]);
		if (interp->dynamic) {
		    free((char *)interp->result);
		}
		interp->dynamic = 0;
		interp->result = ((Interp *)interp)->resultSpace;
	    }
	}
	return (result);
    } else if (*argcPtr == 1 && argComps != 0) {
	/*
	 * If procedure name built at run-time, switch to using regular Tcl
	 * primitive to define a regular procedure, not a compiled one.
	 */
	*((SpecialCmd **)curCmdPtr) = &cmds[(sizeof(cmds)/sizeof(cmds[0]))-1];
    } else if (dataPtr->noHelp &&
	       ((*curCmdPtr)->opcode == TBOP_HPROC) &&
	       (*argcPtr == 3 || *argcPtr == 4))
    {
	if (argComps != 0) {
	    Tcl_RetPrintf(interp, "run-time-generated help string for \"%.50s\" not supported when compiling without help -- file cannot be compiled", argv[1]);
	    return (TCL_ERROR);
	}
	/*
	 * Just don't put the thing out, but leave *argcPtr alone so we know
	 * which argument is really the code...
	 */
	return (TCL_OK);
    } else if (*argcPtr > lastArg) {
	Tcl_RetPrintf(interp, "too many arguments to \"%s\"", argv[0]);
	return (TCL_ERROR);
    }

    return (TBCCOtherArgProc(dataPtr, interp, argComps, wasQuoted, cmdStatePtr,
			     curCmdPtr, dst, argv, argcPtr));
}
/***********************************************************************
 *				TBCCCaseInitProc
 ***********************************************************************
 * SYNOPSIS:	    State-variable initialization for parsing a case
 * CALLED BY:	    (INTERNAL) TclByteCompileLow
 * RETURN:	    nothing
 * SIDE EFFECTS:    cmdStatePtr->caseState set
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/14/94		Initial Revision
 *
 ***********************************************************************/
static void
TBCCCaseInitProc(TBCCData	*dataPtr,
		 CmdState	*cmdStatePtr)
{
    cmdStatePtr->caseState = CS_STRING;
}

/***********************************************************************
 *				TBCCCaseCompileProc
 ***********************************************************************
 * SYNOPSIS:	    Finish compiling a "case"
 * CALLED BY:	    (INTERNAL) TclByteCodeCompileLow
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
static int
TBCCCaseCompileProc(TBCCData *dataPtr,
		  Tcl_Interp *interp,
		  char **argv,
		  int argc,
		  CmdState cmdState,
		    SpecialCmdPtr curCmd)
{
    if (cmdState.caseState != CS_PAT) {
	Tcl_Error(interp, "malformed \"case\": missing code body");
    }
    TBCCOutputByte(dataPtr, TBOP_CASE);
    TBCCOutputNum(dataPtr, argc-1);
    return (TCL_OK);
}


/***********************************************************************
 *				TBCCCaseArgProc
 ***********************************************************************
 * SYNOPSIS:	    Cope with the closure of another argument when
 *		    compiling an "case" command
 * CALLED BY:	    (INTERNAL) TclByteCodeCompileLow
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    stuff may be emitted.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
static int
TBCCCaseArgProc(TBCCData    	    *dataPtr,	    /* For emitting code */
	      Tcl_Interp    	    *interp,	    /* For error messages */
	      unsigned 	    	    argComps,	    /* # of components in
						     * current arg, excluding
						     * what's in argv[*argcPtr]
						     * currently */
	      unsigned    	    wasQuoted,
	      CmdState 	    	    *cmdStatePtr,   /* State of parsing "if" */
	      SpecialCmdPtr   	    *curCmdPtr,     /* For switching to a
						     * different type of
						     * command */
	      char  	    	    *dst,   	    /* After null-term in arg */
	      char  	    	    **argv, 	    /* Complete arg vector */
	      int   	    	    *argcPtr)  	    /* Arg # just finished */
{
    int	    result;

    if (cmdStatePtr->caseState == CS_OPT_IN) {
	if (strcmp(argv[*argcPtr], "in") == 0) {
	    cmdStatePtr->caseState = CS_PAT;
	    *argcPtr -= 1;	/* Discard argument */
	    return (TCL_OK);
	}
	cmdStatePtr->caseState = CS_PAT;
    }
    if (cmdStatePtr->caseState == CS_CODE) {
	if (argComps == 0) {
	    result = TBCCOutputCompiledArg(dataPtr, interp, argv[*argcPtr], 0,
					   dataPtr->strings);

	    cmdStatePtr->caseState = CS_PAT;
	    return (result);
	}
	cmdStatePtr->caseState = CS_PAT;
    } else if (cmdStatePtr->caseState == CS_STRING) {
	cmdStatePtr->caseState = CS_OPT_IN;
    } else {
	cmdStatePtr->caseState = CS_CODE;
    }

    return (TBCCOtherArgProc(dataPtr, interp, argComps, wasQuoted, cmdStatePtr,
			     curCmdPtr, dst, argv, argcPtr));
}

/***********************************************************************
 *				TBCCRetCompileProc
 ***********************************************************************
 * SYNOPSIS:	    Finish compiling a "return"
 * CALLED BY:	    (INTERNAL) TclByteCodeCompileLow
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
static int
TBCCRetCompileProc(TBCCData *dataPtr,
		  Tcl_Interp *interp,
		  char **argv,
		  int argc,
		  CmdState cmdState,
		   SpecialCmdPtr curCmd)
{
    TBCCOutputByte(dataPtr, argc == 2 ? TBOP_RET : TBOP_RETZ);
    return (TCL_OK);
}


/***********************************************************************
 *				TBCCRetArgProc
 ***********************************************************************
 * SYNOPSIS:	    Cope with the closure of another argument when
 *		    compiling a "return" command
 * CALLED BY:	    (INTERNAL) TclByteCodeCompileLow
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    stuff may be emitted.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
static int
TBCCRetArgProc(TBCCData    	    *dataPtr,	    /* For emitting code */
	      Tcl_Interp    	    *interp,	    /* For error messages */
	      unsigned 	    	    argComps,	    /* # of components in
						     * current arg, excluding
						     * what's in argv[*argcPtr]
						     * currently */
	      unsigned	    	    wasQuoted,
	      CmdState 	    	    *cmdStatePtr,   /* State of parsing "if" */
	      SpecialCmdPtr   	    *curCmdPtr,     /* For switching to a
						     * different type of
						     * command */
	      char  	    	    *dst,   	    /* After null-term in arg */
	      char  	    	    **argv, 	    /* Complete arg vector */
	      int   	    	    *argcPtr)  	    /* Arg # just finished */
{
    if (*argcPtr > 1) {
	Tcl_Return(interp, "too many arguments to \"return\"", TCL_STATIC);
	return (TCL_ERROR);
    }

    return (TBCCOtherArgProc(dataPtr, interp, argComps, wasQuoted, cmdStatePtr,
			     curCmdPtr, dst, argv, argcPtr));
}

/***********************************************************************
 *				TBCCOtherCompileProc
 ***********************************************************************
 * SYNOPSIS:	    Finish compiling an arbitrary command
 * CALLED BY:	    (INTERNAL) TclByteCodeCompileLow
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
static int
TBCCOtherCompileProc(TBCCData *dataPtr,
		  Tcl_Interp *interp,
		  char **argv,
		  int argc,
		  CmdState cmdState,
		     SpecialCmdPtr curCmd)
{
    unsigned i;

    for (i = 0; i < numBuiltInCmds; i++) {
	if (strcmp(builtInCmds[i]->name, argv[0]) == 0) {
	    /*
	     * If the thing has subcommands and the first and only one is
	     * TCL_CMD_ANY (an empty string), perform the usage check now,
	     * rather than run-time, to make life faster and quicker.
	     */
	    if (builtInCmds[i]->data) {
		if (builtInCmds[i]->data->subCommand == TCL_CMD_END) {
		    /*
		     * Command accepts no arguments.
		     */
		    if (argc != 1) {
			Tcl_RetPrintf(interp,
				      "too many args given for primitive \"%s\"",
				      argv[0]);
			return (TCL_ERROR);
		    }
		} else if (builtInCmds[i]->data->subCommand[0] == '\0' &&
			   builtInCmds[i]->data[1].subCommand == TCL_CMD_END)
		{
		    if (builtInCmds[i]->data->minArgs != TCL_CMD_NOCHECK &&
			(argc-2) < builtInCmds[i]->data->minArgs)
		    {
			Tcl_RetPrintf(interp,
				      "not enough args given for primitive \"%s\"",
				      argv[0]);
			return (TCL_ERROR);
		    }
		    if (builtInCmds[i]->data->maxArgs != TCL_CMD_NOCHECK &&
			(argc-2) > builtInCmds[i]->data->maxArgs)
		    {
			Tcl_RetPrintf(interp,
				      "too many args given for primitive \"%s\"",
				      argv[0]);
			return (TCL_ERROR);
		    }
		}
	    }
	    TBCCOutputByte(dataPtr, TBOP_PCALL);
	    TBCCOutputNum(dataPtr, argc-1);
	    TBCCOutputNum(dataPtr, i);
	    return (TCL_OK);
	}
    }

    TBCCOutputByte(dataPtr, TBOP_CALL);
    TBCCOutputNum(dataPtr, argc-1);
    TBCCOutputString(dataPtr, argv[0], strlen(argv[0]));
    return (TCL_OK);
}


/***********************************************************************
 *				TBCCOtherArgProc
 ***********************************************************************
 * SYNOPSIS:	    Cope with the closure of another argument when
 *		    compiling an arbitrary command
 * CALLED BY:	    (INTERNAL) TclByteCodeCompileLow
 * RETURN:	    TCL_OK/TCL_ERROR
 * SIDE EFFECTS:    stuff may be emitted.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
static int
TBCCOtherArgProc(TBCCData   	    *dataPtr,	    /* For emitting code */
	      Tcl_Interp    	    *interp,	    /* For error messages */
	      unsigned 	    	    argComps,	    /* # of components in
						     * current arg, excluding
						     * what's in argv[*argcPtr]
						     * currently */
	      unsigned	    	    wasQuoted,
	      CmdState 	    	    *cmdStatePtr,   /* State of parsing "if" */
	      SpecialCmdPtr   	    *curCmdPtr,     /* For switching to a
						     * different type of
						     * command */
	      char  	    	    *dst,   	    /* After null-term in arg */
	      char  	    	    **argv, 	    /* Complete arg vector */
	      int   	    	    *argcPtr)  	    /* Arg # just finished */
{
    int	    result;

    if (argComps != 0) {
	/*
	 * Don't force empty string push if already have something in this
	 * argument (dst advanced past null when we get here...).
	 */
	dst--;
    }
    /*
     * If any chars still pending in the arg, push them onto the operand stack.
     */
    result = 0;
    TBCCOutputPushIfNecessary(dataPtr, dst, argv, *argcPtr, &argComps, &result);

    /*
     * Concatenate all the strings that make up this argument.
     */
    if (argComps > 1) {
	TBCCOutputByte(dataPtr, TBOP_ARGCAT);
	TBCCOutputNum(dataPtr, argComps);
    }
    return (TCL_OK);
}


/***********************************************************************
 *				TclByteCodeCompileLow
 ***********************************************************************
 * SYNOPSIS:	    Recursive function to perform the actual
 *	    	    compilation, storing the results in a single
 *		    buffer.
 * CALLED BY:	    (INTERNAL) TclByteCodeCompile, self
 * RETURN:	    non-zero on error
 * SIDE EFFECTS:    buffer is expanded
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
int
TclByteCodeCompileLow(Tcl_Interp *interp,   /* Token for command interpreter
					     * (returned by a previous call to
					     * Tcl_CreateInterp). */
		      const char *cmd,	    /* Pointer to TCL command to
					     * compile. */
		      char  termChar,	    /* Return when this character is
					     * found in the command stream.
					     * This is either 0, ']'.   If
					     * termChar is 0, then individual
					     * commands are terminated by
					     * newlines, although this procedure
					     * doesn't return until it sees the
					     * end of the string. */
		      const char **termPtr, /* If non-NULL, fill in the address
					     * it points to with the address of
					     * the char. that terminated cmd.
					     * This character will be either
					     * termChar or the null at the end
					     * of cmd. */
		      TBCCData	*dataPtr)
{
    /*
     * While processing the command, make a local copy of
     * the command characters.  This is needed in order to
     * terminate each argument with a null character, replace
     * backslashed-characters, etc.  The copy starts out in
     * a static string (for speed) but gets expanded into
     * dynamically-allocated strings if necessary.  The constant
     * BUFFER indicates how much space there must be in the copy
     * in order to pass through the main loop below (e.g., must
     * have space to copy both a backslash and its following
     * characters).
     */

#   define NUM_CHARS 200
#   define BUFFER 5
    char    	    copyStorage[NUM_CHARS];
    char    	    *copy=copyStorage;	    /* Pointer to current copy. */
    unsigned   	    copySize = NUM_CHARS;   /* Size of current copy. */
    register char   *dst;		    /* Points to next place to copy
					     * a character. */
    char    	    *limit;		    /* When dst gets here, must make
					     * the copy larger. */

    /*
     * This procedure generates an (argv, argc) array for the command,
     * It starts out with stack-allocated space but uses dynamically-
     * allocated storage to increase it if needed.
     */

#   define NUM_ARGS 32
    char    	    *argStorage[NUM_ARGS];
    char    	    **argv = argStorage;
    int     	    argc;
    int     	    argSize = NUM_ARGS;

    int     	    openBraces=0;   	/* Count of how many nested open braces
					 * there are at the current point in
					 * the current argument */
    int	    	    sawBraces=0;    	/* Non-zero if current arg was in
					 * braces */
    int	    	    openBrackets=0; 	/* Count of how many open command
					 * substitutions are active. Used only
					 * when processing noeval things */
    register const char   *src;		/* Points to current character
					 * in cmd. */
    const char 	    *argStart;		/* Location in cmd of first character
					 * in current argument;  it's used to
					 * detect that nothing has been read
					 * from the current argument. */
    int     	    result=TCL_OK;	/* Return value. */
    int     	    i;
    register Interp *iPtr = (Interp *) interp;
    const char 	    *tmp;
    const char 	    *syntaxMsg;
    unsigned	    argComps;	    	/* Number of components that must be
					 * concatenated to form the argument */
    SpecialCmd	    *curCmd = NULL;
    CmdState   	    cmdState;
    int	    	    complete;
    int	    	    needPop = 0;    	/* Set non-zero if compile a second
					 * command, so first command's result
					 * should be discarded */
    int	    	    noeval;	    	/* Set if TCL_NOEVAL command
					 * encountered, meaning no variable or
					 * command or backslash substitution
					 * should occur, and the remainder of
					 * the command should be put into a
					 * single argument */

    src = cmd;
    result = TCL_OK;

    /*
     * There can be many sub-commands (bracketed or separated by
     * newlines) in one command string.  This outer loop iterates over
     * the inner commands.
     */

    while ((*src != termChar) && (result == TCL_OK)) {

	/*
	 * Skim off leading white space, skip comments, and handle brackets
	 * at the beginning of the command by recursing.
	 */

	while (isspace(*src)) {
	    src += 1;
	}
	if (*src == '#') {
	    for (src++; *src != 0; src++) {
		if (*src == '\n') {
		    src++;
		    break;
		}
	    }
	    continue;
	}
	/*
	 * If the first character of the command is a [, the command within
	 * is executed and its output discarded (unless it's the only command
	 * in the string). This allows multi-line commands by placing it
	 * in brackets -- if this weren't done, the result would be executed,
	 * which would be bad.
	 *
	 * Switches back to calling frame before recursing so there's not a
	 * bogus frame in the middle (we don't have anything to assign to our
	 * frame yet).
	 *
	 * XXX: If Tcl_TopLevel is called while in the nested Tcl_Eval,
	 * anything we've allocated dynamically will be left dangling.
	 */
	if (*src == '[') {
	    /*
	     * If we've already compiled something from this
	     * string, discard its result.
	     */
	    if (needPop) {
		TBCCOutputByte(dataPtr, TBOP_POP);
		needPop = 0;
	    }

	    result = TclByteCodeCompileLow(interp, src+1, ']', &tmp, dataPtr);
	    needPop = 1;
	    src = tmp+1;
	    continue;
	}

	/*
	 * Set up the first argument (the command name).  Note that
	 * the arg pointer gets set up BEFORE the first real character
	 * of the argument has been found.
	 */

	dst = copy;
	argc = 0;
	limit = copy + copySize - BUFFER;

	noeval = 0;
	complete = 0;
	argv[0] = dst;
	argComps = 0;
	argStart = src;

	/*
	 * Skim off the command name and arguments by looping over
	 * characters and processing each one according to its type.
	 */

	while (1) {
	    switch (*src) {

		/*
		 * All braces are treated as normal characters
		 * unless the first character of the argument is an
		 * open brace.  In that case, braces nest and
		 * the argument terminates when all braces are matched.
		 * Internal braces are also copied like normal chars.
		 */

		case '{': {
		    if ((openBraces == 0) && (src == argStart)) {
			/*
			 * 9/29/92: I changed this, at one point to
			 * find the length of the quoted argument and
			 * enlarge the block just once, but it ended up
			 * just processing the characters twice, rather than
			 * once, and only rarely (I think the number was
			 * 1/70th of the time) was it ever worth it (i.e. was
			 * the argument so big the dest had to be enlarged).
			 * I doubt it has much effect either way. The
			 * code is in revision 1.60, though, if you ever want
			 * it back again -- ardeb.
			 */
			sawBraces = openBraces = 1;
			break;
		    } else {
			*dst++ = '{';
			/*
			 * Only balance braces if inside an argument in braces.
			 */
			if (openBraces) {
			    openBraces++;
			}
		    }
		    break;
		}

		case '}': {
		    if (openBraces == 1) {
			const char *p;

			openBraces = 0;

			checkbrace:

			if (isspace(src[1]) || (src[1] == termChar) ||
			    (src[1] == 0))
			{
			    break;
			}
			for (p = src+1;
			     (*p != 0) && (!isspace(*p)) &&
			     (*p != termChar) && (p < src+20);
			     p++)
			{
			    /* null body */
			}
			Tcl_RetPrintf(interp,
				      "argument in braces followed by \"%.*s\" instead of space",
				      p-(src+1), src+1);
			result = TCL_ERROR;
			goto done;
		    } else {
			*dst++ = '}';
			if (openBraces != 0) {
			    openBraces--;
			}
		    }
		    break;
		}

		case '[': {

		    /*
		     * Open bracket: if not in middle of braces, then execute
		     * following command and substitute result into argument.
		     */

		    if (openBraces != 0) {
			*dst++ = '[';
		    } else if (noeval) {
			*dst++ = '[';
			openBrackets += 1;
		    } else {
			TBCCOutputPushIfNecessary(dataPtr, dst, argv, argc,
						   &argComps, &needPop);
			dst = argv[argc];

			if (TclByteCodeCompileLow(interp, src+1, ']', &tmp,
						  dataPtr) != TCL_OK)
			{
			    result = TCL_ERROR;
			    goto done;
			}
			src = tmp;

			argComps += 1;
		    }
		    break;
		}

		case '$': {
		    if (openBraces != 0 || noeval) {
			*dst++ = '$';
		    } else {
			/*
			 * Parse off a variable name and copy its value.
			 */
			int len;
			const char *name = TclProcScanVar(interp, src, &len,
							  &tmp);

			TBCCOutputPushIfNecessary(dataPtr, dst, argv, argc,
						  &argComps, &needPop);
			dst = argv[argc];

			TBCCOutputByte(dataPtr, TBOP_PUSHV);
			TBCCOutputString(dataPtr, name, len);
			argComps += 1;

			src = tmp-1;
		    }
		    break;
		}

		case ']': {
		    if (openBraces == 0) {
			if (noeval) {
			    if (openBrackets-- == 0 && termChar == ']') {
				openBrackets = 0;
				complete = 1;
				goto close_arg;
			    }
			} else if (termChar == ']') {
			    complete = 1;
			    goto close_arg;
			}
		    }
		    *dst++ = ']';
		    break;
		}

		case '\n': {

		    /*
		     * A newline can be either a command terminator
		     * or a space character.  If it's a space character,
		     * just fall through to the space code below.
		     */

		    if (openBraces == 0) {
			if (noeval) {
			    if (!openBrackets && termChar == 0) {
				complete = 1;
				goto close_arg;
			    }
			} else if (termChar == 0) {
			    complete = 1;
			    goto close_arg;
			}
		    }
		}
		    /*FALLTHRU*/
		case '\r':
		case ' ':
		case '\t': {
		    if (openBraces > 0 ||
			(noeval &&
			 (((curCmd != NULL) && (curCmd->token == CMD_OTHER))
			  || openBrackets)))
		    {

			/*
			 * Quoted space.  Copy it into the argument.
			 */

			*dst++ = *src;
		    } else {

			/*
			 * Argument separator.  Find the start of the next
			 * argument;  if none, then exit the loop.  Otherwise,
			 * null-terminate the current argument and set up for
			 * the next one.  Expand the argv array if it's about
			 * to overflow (watch out!  leave space both for next
			 * arg and for NULL pointer that gets added to the
			 * end of argv when the command is complete).
			 */

		    close_arg:

			*dst++ = 0;
			noeval = 0;

			if (argc == 0) {
			    /*
			     * Special handling for the first argument,
			     * as we need to (a) keep it around for a while,
			     * and (b) figure if it's a special one where
			     * we byte-compile some of its args.
			     */
			    int	j;

			    if (complete && src == argStart) {
				/*
				 * Empty line, so just get out of this loop.
				 */
				goto cmdComplete;
			    }

			    if (argComps != 0) {
				/*
				 * Command to call is formed by a concatenation
				 * of things. Wheee.
				 */
				curCmd =
				    &cmds[(sizeof(cmds)/sizeof(cmds[0]))-1];

				TBCCOtherArgProc(dataPtr, interp, argComps,
						 sawBraces, &cmdState, &curCmd,
						 dst, argv, &argc);
			    } else {

				for (j = 0;
				     j < sizeof(cmds)/sizeof(cmds[0]);
				     j++)
				{
				    if (cmds[j].name == 0) {
					break;
				    } else if (strcmp(argv[0], cmds[j].name)==0)
				    {
					break;
				    }
				}
				curCmd = &cmds[j];

				if (curCmd->token == CMD_OTHER) {
				    Command	*cmd = TclFindCmd(iPtr,
								  argv[0], 0);

				    if (cmd != 0 && (cmd->flags & TCL_NOEVAL)) {
					noeval = 1;
				    }
				} else if (curCmd->token == CMD_EXPR) {
				    noeval = 1;
				}

			    }

			    /*
			     * Perform whatever initialization of parse-state
			     * variables the command requires.
			     */
			    (*curCmd->initProc) (dataPtr, &cmdState);

			    /*
			     * If we've already compiled something from this
			     * string, discard its result.
			     */
			    if (needPop) {
				TBCCOutputByte(dataPtr, TBOP_POP);
				needPop = 0;
			    }
			} else {
			    if (!complete || argComps != 0 || src != argStart)
			    {
				result = (*curCmd->argProc) (dataPtr,
							     interp,
							     argComps,
							     sawBraces,
							     &cmdState,
							     &curCmd,
							     dst,
							     argv,
							     &argc);
			    } else {
				goto cmdComplete;
			    }
			    if (result != TCL_OK) {
				goto done;
			    }
			}

			sawBraces = 0;
			argc += 1;

			if (complete) {
			    goto cmdComplete;
			}

			if (argc >= argSize-1) {
			    argSize *= 2;
			    if (argv == argStorage) {
				char **newArgs;

				newArgs = (char **)
				    malloc((unsigned) argSize*sizeof(char *));
				bcopy(argv, newArgs, argc * sizeof(char *));
				argv = newArgs;
			    } else {
				argv =
				    (char **)realloc((malloc_t)argv,
						     (unsigned)argSize*
						     sizeof(char *));
			    }
			}

			argv[argc] = dst;

			while (((i = src[1]) == ' ') || (i == '\t') ||
			       ((i == '\n') && (termChar != 0)) ||
			       (i == '\r'))
			{
			    src++;
			}
			argStart = src+1;
			argComps = 0;

		    }
		    break;
		}

		case '\\': {
		    int numRead;

		    /*
		     * If we're in an argument in braces then the
		     * backslash doesn't get collapsed.  However whether
		     * we're in braces or not the characters inside the
		     * backslash sequence must not receive any additional
		     * processing:  make src point to the last character
		     * of the sequence.
		     */

		    *dst = Tcl_Backslash(src, &numRead);
		    if (noeval || openBraces > 0) {
			while (numRead-- > 0) {
			    *dst++ = *src++;
			}
			src--;
		    } else {
			src += numRead-1;
			dst++;
		    }
		    break;
		}

		case 0: {

		    /*
		     * End of string.  Make sure that braces were
		     * properly matched.  Also, it's only legal to
		     * terminate a command by a null character if termChar
		     * is zero.
		     */

		    if (openBraces != 0) {
			syntaxMsg = "unmatched brace";
			goto syntaxError;
		    } else if (termChar != 0) {
			if (termChar == ']') {
			    syntaxMsg = "unmatched bracket";
			} else {
			    syntaxMsg = "termination character not found";
			}
			goto syntaxError;
		    }
		    complete = 1;
		    goto close_arg;
		}

		default: {
		    *dst++ = *src;
		    break;
		}
	    }
	    src += 1;

	    /*
	     * Make sure that we're not running out of space in the
	     * string copy area.  If we are, allocate a larger area
	     * and copy the string.  Be sure to update all of the
	     * relevant pointers too.
	     */

	    if (dst >= limit) {
		char 	    *newCopy;
		ptrdiff_t   delta;

		copySize *= 2;
		newCopy = (char *) malloc((unsigned) copySize);
		bcopy(copy, newCopy, (dst-copy));
		delta = newCopy - copy;
		dst += delta;
		for (i = 0; i <= argc; i++) {
		    if (argv[i] >= copy && argv[i] <= limit)
		    {
			argv[i] += delta;
		    }
		}
		if (copy != copyStorage) {
		    free((char *) copy);
		}
		copy = newCopy;
		limit = newCopy + copySize - BUFFER;
	    }
	}

	cmdComplete:

	noeval = 0;
	if (argc == 0) {
	    continue;
	}

	/*
	 * Invoke the compiler for the command
	 */
	result = (*curCmd->compileProc)(dataPtr, interp, argv, argc,
					cmdState, curCmd);

	needPop = 1;
    }

    done:
    if (termPtr != NULL) {
	*termPtr = src;
    }

    /*
     * Free up any extra resources that were allocated.
     */

    if (copy != copyStorage) {
	free((char *) copy);
    }
    if (argv != argStorage) {
	free((char *) argv);
    }

    return result;

    /*
     * Syntax error:  generate a two-line message to pinpoint the error.
     * The first line contains a swatch of the command (without any
     * embedded newlines) and the second line contains a caret.
     */

    syntaxError: {
	const char *first, *last;

	for (first = src; ((first != cmd) && (first[-1] != '\n')); first--) {
	    /* Null loop body. */
	}
	for (last = src; ((*last != 0) && (*last!= '\n')); last++) {
	    /* Null loop body. */
	}
	if ((src - first) > 60) {
	    first = src - 60;
	}
	if ((last - first) > 70) {
	    last = first + 70;
	}
	if (last == first) {
	    Tcl_RetPrintf(interp, "%s", syntaxMsg);
	} else {
	    /*
	     * We need to make sure the caret lines up with the place of
	     * error by using tab characters wherever the source string
	     * uses them, and spaces everywhere else.
	     */
	    char	*cp;
	    char	*cp2;

	    Tcl_Return(interp, NULL, TCL_STATIC);

	    strcpy(iPtr->resultSpace, syntaxMsg);
	    cp = iPtr->resultSpace + strlen(syntaxMsg);

	    *cp++ = '\n';
	    cp2 = cp + (last-first);
	    *cp2++ = '\n';

	    while (first != last) {
		if (first <= src) {
		    if (*first != '\t') {
			*cp2++ = ' ';
		    } else {
			*cp2++ = '\t';
		    }
		    if (first == src) {
			*cp2++ = '^';
			*cp2++ = '\0';
		    }
		}
		*cp++ = *first++;
	    }
	    if (first == src) {
		*cp2++ = '^';
		*cp2++ = '\0';
	    }
	}
	result = TCL_ERROR;
    }

    goto done;
}


/*
 *-----------------------------------------------------------------
 *
 * TclByteCodeCompile --
 *
 *	Compile a string into byte-code
 *
 * Results:
 *	If the compilation is successful, the base of the byte-code
 *	    block is returned, with its length returned in *sizePtr.
 *	If the compilation fails, 0 is returned, and interp->result
 *	    is the message explaining the failure.
 *
 * Side effects:
 *	Almost certainly;  depends on the command.
 *
 *-----------------------------------------------------------------
 */
unsigned char *
TclByteCodeCompile(Tcl_Interp 	*interp,    /* Token for command interpreter
					     * (returned by a previous call to
					     * Tcl_CreateInterp). */
		   const char 	*cmd,	    /* Pointer to TCL command to
					     * compile. */
		   char	    	termChar,   /* Return when this character is
					     * found in the command stream.
					     * This is either 0, ']'.   If
					     * termChar is 0, then individual
					     * commands are terminated by
					     * newlines, although this procedure
					     * doesn't return until it sees the
					     * end of the string. */
		   int 	    	flags,	    /* TBCC_* flags */
		   const char **termPtr,    /* If non-NULL, fill in the address
					     * it points to with the address of
					     * the char. that terminated cmd.
					     * This character will be either
					     * termChar or the null at the end
					     * of cmd. */
		   unsigned long *sizePtr)
{
    return TclByteCodeCompileTop(interp, cmd, termChar, flags, 0, termPtr,
				 sizePtr);
}


/***********************************************************************
 *				TclByteCodeCompileTop
 ***********************************************************************
 * SYNOPSIS:	    Start off byte-compilation, possibly using a passed
 *		    in string table. Otherwise, we're the same as
 *		    TclByteCodeCompile
 * CALLED BY:	    (INTERNAL) TclByteCodeCompile,
 *			       TBCCOutputCOmpiledArg
 * RETURN:	    the base of the compiled output
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/95	Initial Revision
 *
 ***********************************************************************/
unsigned char *
TclByteCodeCompileTop(Tcl_Interp    *interp,	/* Token for command interpreter
						 * (returned by a previous
						 * call to Tcl_CreateInterp). */
		      const char    *cmd,    	/* Pointer to TCL command to
						 * compile. */
		      char	    termChar,   /* Return when this character is
						 * found in the command stream.
						 * This is either 0, ']'.   If
						 * termChar is 0, then individ-
						 * ual commands are terminated
						 * by newlines, although this
						 * procedure doesn't return
						 * until it sees the end of the
						 * string. */
		      int 	    flags,	/* TBCC_* flags */
		      TBCCStrings   *strings,	/* String table to use, or 0 to
						 * create one */
		      const char    **termPtr,  /* If non-NULL, fill in the
						 * address it points to with the
						 * address of the char. that
						 * terminated cmd. This
						 * character will be either
						 * termChar or the null at the
						 * end of cmd. */
		      unsigned long *sizePtr)
{
    TBCCData	data;

    TBCCDataInit(&data, flags & TBCC_NOHELP, 0, strings, interp);

    if (TclByteCodeCompileLow(interp, cmd, termChar, termPtr, &data) == TCL_OK)
    {
	if ((flags & TBCC_DISCARD) && (data.tail - data.data) != 0) {
	    TBCCOutputByte(&data, TBOP_POP);
	}
	/*
	 * Prepend the string table to the final result if we weren't passed
	 * one.
	 */
	if (strings == 0) {
	    TBCCCompressStringTable(&data);

	    if (data.strings->free != 2) {
		unsigned    	pushStart;
		unsigned char	*newdata;
		unsigned    	dsize, ssize;

		/*
		 * Append the opcode to pop the string table from the
		 * string table stack.
		 */
		TBCCOutputByte(&data, TBOP_POPST);

		/*
		 * Now we use the existing routines to create the opcode to
		 * push the string table and the bytes that hold the size
		 * of the string table. These will eventually be placed
		 * at the start of the final code block, so we remember where
		 * they start.
		 */
		pushStart = data.tail - data.data;
		ssize = data.strings->free;

		TBCCOutputByte(&data, TBOP_PUSHST);
		TBCCOutputNum(&data, ssize);

		/*
		 * Allocate new memory to hold the string table and the
		 * compiled code.
		 */
		dsize = data.tail - data.data;

		newdata = (unsigned char *)malloc(dsize + ssize);

		/*
		 * Copy the PUSHST + size to the front of the new area.
		 */
		bcopy(&data.data[pushStart], newdata,
		      dsize - pushStart);
		/*
		 * Copy the string table into the new area.
		 */
		bcopy(data.strings->strings,
		      &newdata[dsize - pushStart],
		      ssize);
		/*
		 * Copy the remainder of the code
		 */
		bcopy(data.data, &newdata[(dsize - pushStart) + ssize],
		      pushStart);
		/*
		 * Free the old data and fix up the data pointers for the new
		 * area.
		 */
		free((char *)data.data);
		data.data = newdata;
		data.max = data.tail = data.data + (dsize + ssize);
	    }
	    /*
	     * Free the string table.
	     */
	    free((malloc_t)data.strings->refs);
	    free((malloc_t)data.strings->strings);
	    free((malloc_t)data.strings);
	}
	/*
	 * Shrink the code to fit and return the size.
	 */
	*sizePtr = data.tail - data.data;
	realloc((char *)data.data, data.tail - data.data);
	return (data.data);
    } else {
	free((char *)data.data);
	return (0);
    }
}



/***********************************************************************
 *				TclByteCodeDisasm
 ***********************************************************************
 * SYNOPSIS:	    Disassemble a section of byte-code
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    none
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
void
TclByteCodeDisasm(Tcl_Interp *interp,
		  const unsigned char *p,
		  unsigned long size,
		  unsigned indent)
{
    const unsigned char *base = p;
    Interp *iPtr = (Interp *)interp;

    while (p - base < size) {
	(*interp->output)("%*s", indent, "");

	switch (*p++) {
	case (int)TBOP_PUSH:
	{
	    /* args: string
	     * stack: -- string */
	    unsigned long   length;
	    const char *str = TclByteCodeFetchString((Interp *)interp,
						     &p, &length);

	    (*interp->output)("%-10s \"%s\"\n", "PUSH", str);
	    break;
	}
	case (int)TBOP_PUSHV:
	{
	    /* args: varname
	     * stack: -- varval-string */
	    const char *varname = TclByteCodeFetchString((Interp *)interp,
							 &p, NULL);

	    (*interp->output)("%-10s \"%s\"\n", "VARREF", varname);
	    break;
	}
	case (int)TBOP_PCALL:
	{
	    /* args: #args, prim#
	     * stack: #args-string-args -- retval */
	    unsigned long   nargs = TclByteCodeFetchNum(&p);
	    unsigned 	    idx = TclByteCodeFetchNum(&p);

	    if (idx >= numBuiltInCmds) {
		(*interp->output)("%-10s %lu, %d (?)\n", "PRIMCALL",
				  nargs, idx);
	    } else {
		(*interp->output)("%-10s %lu, %d (%s)\n", "PRIMCALL",
				  nargs, idx, builtInCmds[idx]->name);
	    }
	    break;
	}
	case (int)TBOP_CALL:
	{
	    /* args: #args, procname
	     * stack: #args-string-args -- retval */
	    unsigned long   nargs = TclByteCodeFetchNum(&p);
	    const char	    *procname = TclByteCodeFetchString((Interp *)interp,
							       &p, NULL);

	    (*interp->output)("%-10s %lu, \"%s\"\n", "CALL", nargs, procname);
	    break;
	}
	case (int)TBOP_IF:
	{
	    /* args: #args
	     * stack: (test-expr body-code)+ [else-code]  -- retval */
	    unsigned long   nargs = TclByteCodeFetchNum(&p);

	    (*interp->output)("%-10s %lu\n", "IF", nargs);
	    break;
	}
	case (int)TBOP_POP:
	    /* args:
	     * stack: string/code -- */
	    (*interp->output)("%-10s\n", "POP");
	    break;
	case (int)TBOP_CODE:
	{
	    /* args: #bytes, bytes
	     * stack: -- code */
	    unsigned long length;

	    length = TclByteCodeFetchNum(&p);

	    (*interp->output)("%-10s %d byte%s:\n", "CODE", length,
			      length==1 ? "" : "s");
	    TclByteCodeDisasm(interp, p, length, indent+4);

	    p += length;
	    break;
	}
	case (int)TBOP_WHILE:
	{
	    /* args:
	     * stack: test-expr body-code -- retval */

	    (*interp->output)("%-10s\n", "WHILE");
	    break;
	}
	case (int)TBOP_FOR:
	{
	    /* args:
	     * stack: init-code test-expr next-code body-code -- retval */

	    (*interp->output)("%-10s\n", "FOR");
	    break;
	}
	case (int)TBOP_CASE:
	{
	    /* args: #args
	     * stack: string (pattern-list body-code)+ -- retval */

	    unsigned long nargs;    	/* Number of args left to process */

	    /*
	     * Extract the number of args for the case (including the string)
	     */
	    nargs = TclByteCodeFetchNum(&p);

	    (*interp->output)("%-10s %lu\n", "CASE", nargs);
	    break;
	}
	case (int)TBOP_ARGCAT:
	{
	    /* args: #strings
	     * stack: #strings-strings -- concatenation */
	    unsigned long nargs;

	    nargs = TclByteCodeFetchNum(&p);

	    (*interp->output)("%-10s %lu\n", "ARGCAT", nargs);
	    break;
	}
	case (int)TBOP_PROC:
	{
	    /* args: flags
	     * stack: name-string arg-string body-code -- retval */
	    unsigned flags = TclByteCodeFetchNum(&p);

	    (*interp->output)("%-10s\n",
			      flags & TCL_EXACT ? "DEFSUBR" : "PROC");
	    break;
	}
	case (int)TBOP_HPROC:
	{
	    /* args: flags
	     * stack: name-string arg-string help-class-string help-string
	     *	      body-code -- retval */
	    unsigned flags = TclByteCodeFetchNum(&p);

	    (*interp->output)("%-10s\n",
			      flags & TCL_EXACT ? "DEFCOMMAND" : "DEFCMD");
	    break;
	}
	case (int)TBOP_RET:
	    /* args:
	     * stack: retval -- */
	    (*interp->output)("%-10s\n", "RET");
	    break;
	case (int)TBOP_RETZ:
	    /* args:
	     * stack: -- */
	    (*interp->output)("%-10s\n", "RETZ");
	    break;
	case (int)TBOP_FOREACH:
	    /* args:
	     * stack: var-name list body-code -- retval */
	    (*interp->output)("%-10s\n", "FOREACH");
	    break;
	case (int)TBOP_PROTECT:
	    /* args:
	     * stack: body-code protect-code -- retval */
	    (*interp->output)("%-10s\n", "PROTECT");
	    break;
	case (int)TBOP_PUSHE:
	{
	    unsigned long len = TclByteCodeFetchNum(&p);

	    (*interp->output)("%-10s %d byte%s:\n", "PUSHEXPR", len,
			      len == 1 ? "" : "s");
	    TclExprByteDisasm(interp, p, len, indent+4);
	    p += len;
	    break;
	}
	case (int)TBOP_EXPR:
	    (*interp->output)("%-10s\n", "EXPR");
	    break;
	case (int)TBOP_FEXPR:
	    (*interp->output)("%-10s\n", "FEXPR");
	    break;
	case (int)TBOP_PUSHST:
	{
	    unsigned long len = TclByteCodeFetchNum(&p);
	    unsigned short num;

	    num = p[0] | (p[1] << 8);

	    (*interp->output)("%-10s %d string%s, %d byte%s\n", "PUSHST",
			      num, num == 1 ? "" : "s",
			      len, len == 1 ? "" : "s");

	    TclByteCodePush(iPtr, TBSET_STRING_TABLE, 0, len, p);

	    p += len;
	    break;
	}
	case (int)TBOP_POPST:
	{
	    (*interp->output)("%-10s\n", "POPST");

	    if (iPtr->strings.stack[iPtr->strings.top-1].eltDynamic) {
		free((malloc_t)iPtr->strings.stack[iPtr->strings.top-1].eltData);
	    }
	    iPtr->strings.top -= 1;
	    break;
	}
	}
    }
}


/***********************************************************************
 *				TBCReadFile
 ***********************************************************************
 * SYNOPSIS:	    Read the passed file into a buffer in memory to be
 *		    interpreted.
 * CALLED BY:	    (INTERNAL)
 * RETURN:	    pointer to the read bytes, *sizePtr set
 *	    	    0 on error (interp->result holds error string)
 * SIDE EFFECTS:    file opened and closed.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/12/96		Initial Revision
 *
 ***********************************************************************/
const unsigned char tlcMagic[] = { 0, 0xad, 0xb0 }; /* We write & read these */
const unsigned char tlcOldMagic[] = { 0, 0xad, 0xeb }; /* We read these */

unsigned char *
TBCReadFile(Tcl_Interp *interp, const char *inname, unsigned long *sizePtr)
{
    int 	freeInName = 0;
    int 	fd;
    unsigned char *contents;
    unsigned long size;

    fd = open((char *)inname, O_RDONLY | O_BINARY, 0);
    if (fd < 0) {
	char *newname;

	newname = (char *)malloc(strlen(inname) + 4 + 1);
	sprintf(newname, "%s.tlc", inname);

	fd = open(newname, O_RDONLY | O_BINARY, 0);
	if (fd < 0) {
	    free((char *)newname);
	    Tcl_RetPrintf(interp, "unable to open %s", inname);
	    return (0);
	} else {
	    inname = newname;
	}
    }

    size = lseek(fd, 0L, SEEK_END);
    contents = (unsigned char *)malloc(size);
    (void)lseek(fd, 0L, SEEK_SET);
    if (read(fd, contents, size) != size) {
	(void)close(fd);
	Tcl_RetPrintf(interp, "unable to read %s", inname);
	free((char *)contents);
	if (freeInName) {
	    free((char *)inname);
	}
	return(0);
    }
    (void)close(fd);
    if ((bcmp(contents, tlcMagic, sizeof(tlcMagic)) != 0) &&
	(bcmp(contents, tlcOldMagic, sizeof(tlcOldMagic)) != 0))
    {
	Tcl_RetPrintf(interp, "%s is not a compiled Tcl file", inname);
	free((char *)contents);
	if (freeInName) {
	    free((char *)inname);
	}
	return(0);
    }
    *sizePtr = size - sizeof(tlcMagic);
    return (contents);
}


/***********************************************************************
 *				Tcl_BCCmd
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/29/93	Initial Revision
 *
 ***********************************************************************/
#define BC_LIST	    (ClientData)0
#define BC_DISASM   (ClientData)1
#define BC_COMPILE  (ClientData)2
#define BC_FCOMP    (ClientData)3
#define BC_FLOAD    (ClientData)4
#define BC_FDISASM  (ClientData)5
#define BC_DEBUG    (ClientData)6

static const Tcl_SubCommandRec bcCmds[] = {
    {"list", 	BC_LIST,    1, 1, "<proc>"},
    {"disasm",	BC_DISASM,  1, 1, "<proc>"},
    {"compile",	BC_COMPILE, 1, 1, "<proc>"},
    {"fcompile",BC_FCOMP,   1, 2, "<file> [<nohelp>]"},
    {"fload",	BC_FLOAD,   1, 1, "<file>"},
    {"fdisasm",	BC_FDISASM, 1, 1, "<file>"},
    {"debug", 	BC_DEBUG,   0, 1, "[1|0]"},
    {TCL_CMD_END}
};

DEFCMD(bc,Tcl_BC,TCL_EXACT,bcCmds,swat_prog.byte_code,
"Usage:\n\
    bc list <proc>\n\
    bc disasm <proc>\n\
    bc compile <proc>\n\
    bc fcompile <file> [<nohelp>]\n\
    bc fload <file>\n\
    bc fdisasm <file>\n\
    bc debug [1|0]\n\
\n\
Examples:\n\
    \"bc compile poof\"	    Compiles the body of the procedure \"poof\" and\n\
			    replaces the existing procedure with its compiled\n\
			    form.\n\
    \"bc fcomp bptutils.tcl\" Creates the file \"bptutils.tlc\" that contains a\n\
			    stream of compiled Tcl that will do exactly what\n\
			    sourcing bptutils.tcl does, except the resulting\n\
			    procedures will be compiled Tcl, not interpreted\n\
			    Tcl.\n\
    \"bc fload bptutils.tlc\" Loads a file containing a stream of compiled Tcl\n\
			    code.\n\
\n\
Synopsis:\n\
    The \"bc\" command allows you to create and examine compiled Tcl code.\n\
    Compiled Tcl is not nearly as readable or changeable as interpreted Tcl\n\
    code, but it's 30-50% faster.\n\
\n\
Notes:\n\
    * The \"list\" subcommand doesn't work as yet. Eventually it will attempt to\n\
      construct a more readable form of compiled code. For now, the raw\n\
      opcodes will have to do.\n\
\n\
    *\n\
See also:\n\
    source\n\
")
{
    switch ((int)clientData) {
    case BC_LIST:
	Tcl_Error(interp, "list unsupported");
    case BC_DISASM:
    {
	Command	    *cmdPtr;
	ByteProc    *bprocPtr;

	cmdPtr = TclFindCmd((Interp *)interp, argv[2], 0);
	if (cmdPtr == 0 || cmdPtr->proc != (Tcl_CmdProc *)ByteCodeProc) {
	    Tcl_RetPrintf(interp, "%s is not a compiled procedure",
			  argv[2]);
	    return (TCL_ERROR);
	}
	bprocPtr = (ByteProc *)cmdPtr->clientData;
	TclByteCodeDisasm(interp, bprocPtr->code, bprocPtr->size, 0);
	break;
    }
    case BC_COMPILE:
    {
	Proc	*procPtr = TclFindProc((Interp *)interp,
				       argv[2]);
	ByteProc    *bprocPtr;
	unsigned char *code;
	unsigned long len;
	Var 	    *arg, *newArg, **prevArg;
	Command *cmdPtr;

	if (procPtr == NULL) {
	    Tcl_RetPrintf(interp, "%s is not a defined procedure",
			  argv[2]);
	    return (TCL_ERROR);
	}

	code = TclByteCodeCompile(interp, procPtr->command, 0, 0, 0, &len);
	if (code == 0) {
	    return (TCL_ERROR);
	}

	bprocPtr = (ByteProc *)malloc(sizeof(ByteProc) + len);
	bprocPtr->inuse = bprocPtr->delete = 0;

	for (arg = procPtr->argPtr, prevArg = &bprocPtr->argPtr;
	     arg != 0;
	     arg = arg->nextPtr, prevArg = &newArg->nextPtr)
	{
	    newArg = (Var *)malloc(VAR_SIZE(strlen(arg->name),
					    arg->value?strlen(arg->value):0));
	    newArg->valueLength = arg->valueLength;
	    strcpy(newArg->name, arg->name);
	    if (arg->value) {
		newArg->value = (char *)newArg + (arg->value - (char *)arg);
		strcpy(newArg->value, arg->value);
	    } else {
		newArg->value = 0;
	    }
	    newArg->flags = arg->flags;
	    newArg->globalPtr = arg->globalPtr;
	    *prevArg = newArg;
	}
	*prevArg = 0;

	bprocPtr->size = len;
	bcopy(code, bprocPtr->code, len);
	cmdPtr = TclFindCmd((Interp *)interp, argv[2], 0);
	Tcl_CreateCommand(interp,
			  argv[2],
			  (Tcl_CmdProc *)ByteCodeProc,
			  TCL_PROC | cmdPtr->flags,
			  (ClientData)bprocPtr,
			  (Tcl_DelProc *)ByteProcDeleteProc);

	Tcl_Return(interp, NULL, TCL_STATIC);
	break;
    }
    case BC_FCOMP:
    {
	char	*outname;
	const char *cp;
	const char *inname;
	int 	freeInName = 0;
	int 	fd;
	char	*contents;
	unsigned long size;
	unsigned char *code;

	fd = open(argv[2], O_RDONLY | O_BINARY, 0);
	if (fd < 0) {
	    char *newname;

	    newname = (char *)malloc(strlen(argv[2]) + 4 + 1);
	    sprintf(newname, "%s.tcl", argv[2]);
	    inname = newname;
	    freeInName = 1;

	    fd = open((char *)inname, O_RDONLY | O_BINARY, 0);
	    if (fd < 0) {
		free((char *)inname);
		Tcl_RetPrintf(interp, "unable to open %s", argv[2]);
		return (TCL_ERROR);
	    }
	} else {
	    inname = argv[2];
	}

	size = lseek(fd, 0L, SEEK_END);
	contents = (char *)malloc(size+1);
	(void)lseek(fd, 0L, SEEK_SET);
	if (read(fd, contents, size) != size) {
	    (void)close(fd);
	    free((char *)contents);
	    if (freeInName) {
		free((char *)inname);
	    }
	    Tcl_RetPrintf(interp, "unable to read %s", inname);
	    return(TCL_ERROR);
	}
	(void)close(fd);

	contents[size] = '\0';
	code = TclByteCodeCompile(interp,
				  contents,
				  0,
				  TBCC_DISCARD | (argc == 3 ? 0 : TBCC_NOHELP),
				  0,
				  (unsigned long *)&size);

	free((char *)contents);

	if (code == 0) {
	    if (freeInName) {
		free((char *)inname);
	    }
	    return(TCL_ERROR);
	}

	cp = strrchr(inname, '.');
	if (cp == NULL) {
	    cp = inname + strlen(inname);
	}
	outname = (char *)malloc(cp - inname + 4 + 1);
	sprintf(outname, "%.*s.tlc", cp - inname, inname);
	fd = open(outname, O_CREAT | O_TRUNC | O_WRONLY, 0666);
	if (fd < 0) {
	    Tcl_RetPrintf(interp, "cannot create %s", outname);
	    if (freeInName) {
		free((char *)inname);
	    }
	    free((char *)code);
	    return (TCL_ERROR);
	}
	if ((write(fd, tlcMagic, sizeof(tlcMagic)) != sizeof(tlcMagic)) ||
	    (write(fd, code, size) != size))
	{
	    Tcl_RetPrintf(interp, "cannot write %s", outname);
	    if (freeInName) {
		free((char *)inname);
	    }
	    free((char *)code);
	    return (TCL_ERROR);
	}
	(void) close(fd);
	if (freeInName) {
	    free((char *)inname);
	}
	free((char *)code);
	Tcl_Return(interp, 0, TCL_STATIC);
	return(TCL_OK);
    }
    case BC_FLOAD:
    {
	int result;
	unsigned char *contents;
	unsigned long size;

	contents = TBCReadFile(interp, argv[2], &size);
	if (contents == 0) {
	    result = TCL_ERROR;
	} else {
	    result = TclByteCodeEval(interp, size, contents+sizeof(tlcMagic));
	    free((char *)contents);
	}
	return (result);
    }
    case BC_FDISASM:
    {
	unsigned char *contents;
	unsigned long size;

	contents = TBCReadFile(interp, argv[2], &size);
	if (contents == 0) {
	    return (TCL_ERROR);
	} else {
	    TclByteCodeDisasm(interp, contents+sizeof(tlcMagic), size, 0);
	    free((char *)contents);
	    return (TCL_OK);
	}
    }
    case BC_DEBUG:
	if (argc == 2) {
	    Tcl_RetPrintf(interp, "%d", bcDebug);
	} else {
	    bcDebug = atoi(argv[2]);
	}
	return (TCL_OK);
    }
    return (TCL_OK);
}
