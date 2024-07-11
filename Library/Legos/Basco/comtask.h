/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		comtask.h

AUTHOR:		jimmy, Nov  1, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/ 1/95	Initial version.

DESCRIPTION:
	definition of CompileTask

	$Id: comtask.h,v 1.1 98/10/13 21:42:43 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _COMTASK_H_
#define _COMTASK_H_

#include <Legos/fido.h>


enum errcodes {NONE,
		   E_INTERNAL,
		   E_SYNTAX,
		   E_NOPROGFILE,

		   E_INVALID_ARRAY_INDEX, /* unused */
		   E_INVALID_ARGUMENT,	  /* unused */
		   E_HALT_NO_ERROR,	  /* unused */

		   E_BAD_FORMAL_PARAM,
		   E_BAD_FUNCTION_DECL,
		   E_NO_ENDFUNCTION,
		   E_NO_ENDIF,
		   E_NO_ENDSELECT,
		   E_NO_LOOP,
		   E_NO_NEXT,
		   E_NO_THEN,
		   E_NO_AS,
		   E_NO_TO,
		   E_NO_EQUALS,
		   E_BAD_KEYWORD_USE,
		   E_NO_CASE,
		   E_BAD_TYPE,
		   E_BAD_COMPONENT_TYPE,
		   E_BAD_EXIT,
		   E_ELSE_NOT_LAST,
		   E_SUB_NOT_RVAL,
		   E_BAD_NUM_PARAMS,
		   E_TWO_OPERATORS_IN_A_ROW,
		   E_TWO_OPERANDS_IN_A_ROW,
		   E_BAD_USE_UNARY_OPERATOR,
		   E_VARIABLE_ALREADY_DEFINED,
		   E_CONSTANT_ALREADY_DEFINED,
		   E_FUNCTION_INSIDE_FUNCTION,
		   E_CODE_OUTSIDE_FUNCTION,
		   E_NO_ARRAY_DIM,
		   E_EXPECT_BINARY,
		   E_EXPECT_BINARY_OPERAND,
		   E_EXPECT_OPEN_PAREN,
		   E_EXPECT_CLOSE_PAREN,
		   E_EXPECT_COMMA,
		   E_NO_FUNCTION,
		   E_ONE_UNARY,
		   E_FUNC_NOT_USED_AS_RVAL,
		   E_UNDECLARED,
		   E_TYPE_MISMATCH,
		   E_BAD_LOOP_VAR,
		   E_OVERFLOW,
		   E_TOO_MANY_PARAMS,
		   E_TOO_FEW_PARAMS,
		   E_EXPECT_FUNC,
		   E_EXPECT_IDENT,
		   E_STRUCT_DEFN_NOT_ALLOWED,
		   E_EXPECT_INTEGRAL_TYPE,
		   E_EXPECT_STRUCT_TYPE,
		   E_UNDEFINED_STRUCT_FIELD,
		   E_UNDEFINED_STRUCT,
		   E_INVALID_STRUCT_FOR_AGG,
		   E_ARRAY_ASSIGN_DISALLOWED,
		   E_CONSTANT_NEEDED_HERE,
		   E_NO_END_QUOTE,
		   E_BAD_CHAR,
		   E_UNRESOLVED_ACTION,
		   E_UNDEFINED_LABEL,
		   E_NOT_CONSTANT_EXPRESSION,
		   E_NO_EOL,
		   E_NO_DIM,
		   E_NO_STRUCT,
		   E_ARRAY_PROP_NOT_ALLOWED,
		   E_NEED_EXPLICIT_STRUCT_FIELD,
		   E_UNABLE_TO_DELETE_FUNCTION,
		   E_ROUTINE_TOO_BIG,
		   E_NO_EHAN,
		   E_BAD_EXPORT,
		   E_DANGLING_RVAL,
		   E_DUPLICATE_LABEL,
		   E_MALFORMED_LABEL,
		   E_JUMPING_INTO_BLOCK,
		   E_EHAN_IN_BLOCK,
		   E_RESUME_INTO_BLOCK,
		   E_CONSTANT_USE_BEFORE_DECL,
		   E_LAST_ERROR
};
		   
		   
typedef enum errcodes ErrorCode;

typedef MemHandle TaskHan;


typedef byte CompileFlags;

/* this is used when a constant changes value, causing a full
 * recompile (for now anyways) */
#define COMPILE_NEEDS_FULL_RECOMPILE  0x01

#define COMPILE_BUILD_TIME  	0x02

/* for now I am just adding NO_OPs for functions calls so its easy to
 * set breakpoints at them */
#define COMPILE_OPTIMIZE    	0x04

/* If this next byte is true, generate code as normal.  It should
 * default to be true.  If it's false, then we temporarily suspend
 * code generation, set codeSize to zero, and then instead of
 * generating code we only increment codeSize.  This will make for an
 * easy way to "pre-scan" a parse tree to see how big the code it
 * generates will be, then creating a new segment if necessary.  Turn
 * it back on when finished. */
#define COMPILE_CODE_GEN_ON 	0x08

/* If this is true, all variables must be declared. Otherwise,
 * variables don't need to be. */
#define COMPILE_FORCE_DECLS 	0x10

/* On iff generating code for a routine and that routine has an error
 * handler. */
#define COMPILE_HAS_ERROR_TRAP	0x20

/* Set if generating non-segmented (flat) code.  Used by Liberty.
 * If this is changed, all functions must go through code generation again.
 *
 */
#define COMPILE_NO_SEGMENTS	0x40

typedef struct
{
    MemHandle	task_han;   	    	/* mem handle of task */
    TCHAR	filename[13];
    VMFileHandle vmHandle;   	    	/* vm file for interpreter state */

    MemHandle	func_han;	        /* list of functions, like scopes */

    VMBlockHandle code_han;   	    	/* handle for code */

    sword	current_func;		/* current function we are adding to,
					   -1 means we're not currently
					   in a function...*/
    ErrorCode   err_code;               /* Current error state */


    optr	interpreterObj;		/* optr to object associated with */
					/* this task. */

    byte	clean;		/* ctask can be CLEAN or INITIALIZED
				 * {Init/Clean}CompileTask perform this
				 * function.  This byte is so CleanCompileTask
				 * doesn't try to delete stuff that
				 * hasn't been allocated yet...
				 */
    /* - Variable tables and var analysis state */

    MemHandle	vtabHeap;		/* var table state */
    optr	structIndex;		/* STable of structure names */
    
    /* - SCAN/PARSE: */

    word ln;                            /* Line number of parse error */
    word funcNumber;		/* Function number of parse error
				 * Also current function during parsing
				 * and code generation
				 */

    optr    	stringConstTable;
    optr    	stringIdentTable;       /* Idents and other non-string-consts
					 * found during compilation */
    optr    	exportTable;	    	/* string table for exported stuff */
    optr        stringFuncTable;        /* map func name to funcTable index */
    optr    	stringBuiltInFuncTable;	/* strings for built in functions */
    MemHandle 	funcTable;		/* Stores FTabEntries */
    
    /* - CODEGEN:
     */
    VMBlockHandle codeBlock;	/* harray -- elts are segments of bytecode */
    /* As we generate code we keep track  of all the line numbers
     * of all the routines in one huge array...
     */
    VMBlockHandle hugeLineArray;

    /* The following are all valid PER Function.
     */
    VMBlockHandle tree;		/* Current func's AST */
    word	ip;		/* 0-based 'address' for next insn emitted */
    word	segIp;		/* offset of ip within current segment */
    word	curSeg;		/* current seg (element # in task->codeBlock)*/
    byte*	segPtr;		/* Pointer to locked-down curSeg*/
    MemHandle	labels;		/* Per function label generation heap */
    VMBlockHandle globalRefs; 	/* one global list of global references 
				 * that is kept around between compiles */
    word	codeSize;

    word	endRoutineLabel;/* Label points to end of sub/function */
    word	resumeNextLabel;/* Label points to "resume next" code */

    /* - Random shme
     */
    MemHandle	bugHandle;  /* debugging info */
    FTaskHan	fidoTask;   /* used for compile time component typing */
    optr    	compTypeNameTable;/* table of component type names */
    MemHandle	compTypeObjBlock; /* object blocks for components */

    MemHandle	lineBuffer;

    optr    	symbolicConstantTable;
    byte    	compileID;  /* this gets incremented for each succsive
			     * compile with the same compile task so keep
			     * track of things like variable redimming
			     * and such
			     */
    byte    	    liberty;
    CompileFlags    flags;
} Task;

/* these are just useful when a local task variable is around */
#define VTAB_HEAP task->vtabHeap

#define STRUCT_TABLE task->structIndex
#define ID_TABLE task->stringIdentTable
#define CONST_TABLE task->stringConstTable
#define FUNC_TABLE task->stringFuncTable
#define EXPORT_TABLE task->exportTable
#define BUILT_IN_FUNC_TABLE task->stringBuiltInFuncTable
#define SYMBOLIC_CONST_TABLE task->symbolicConstantTable
typedef Task  *TaskPtr;


#endif /* _COMTASK_H_ */
