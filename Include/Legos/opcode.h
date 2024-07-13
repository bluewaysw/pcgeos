/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		opcode.h

AUTHOR:		Roy Goldman, Dec 24, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	12/24/94		Initial version.

DESCRIPTION:
	Opcodes for our virtual machine.

	Moved to main include directory because bugger returns
	variables with types, which are opcodes, to the builder.
	Probably not the best place though... maybe we could
	eventually keep a subset of types...

	$Id: opcode.h,v 1.1 97/12/05 12:16:28 gene Exp $

	$Revision: 1.1 $

	Liberty version control
	$Id: opcode.h,v 1.1 97/12/05 12:16:28 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _OPCODE_H_
#define _OPCODE_H_

typedef enum {


    /* Constants */

    OP_INTEGER_CONST,		/* 0 */
    OP_LONG_CONST,		/* 1 */
    OP_FLOAT_CONST,
    OP_STRING_CONST,

    /* Runtime type coercion */

    OP_COERCE, 

    OP_ILLEGAL,			/* 5 */

    /* Break interrupt flag which is inserted into the code
       by the debugger */

    OP_BREAK,

    /* Function info */
    
    OP_START_FUNCTION,
    OP_END_FUNCTION,
    OP_START_PROCEDURE,
    OP_END_PROCEDURE,		/* 10 */
    OP_CALL,
    OP_MODULE_CALL_PROC,
    OP_MODULE_CALL_FUNC,
    OP_CALL_PRIMITIVE,

    /* Variables */

    /* rvals for arrays of 1 dimension, with constant, local or global
     * variable as the index
     */
    OP_LOCAL_ARRAY_REF_C1_RV,
    OP_LOCAL_ARRAY_REF_L1_RV,
    OP_LOCAL_ARRAY_REF_M1_RV,
    OP_MODULE_ARRAY_REF_C1_RV,
    OP_MODULE_ARRAY_REF_L1_RV,
    OP_MODULE_ARRAY_REF_M1_RV,

    OP_LOCAL_VAR_RV,
    OP_MODULE_VAR_RV,
    OP_LOCAL_ARRAY_REF_RV,
    OP_MODULE_ARRAY_REF_RV,
    OP_ARRAY_REF_RV,
    OP_PROPERTY_RV,
    OP_BC_PROPERTY_RV,
    OP_MODULE_REF_RV,  /* token used to indicate cross module reference */

    OP_LOCAL_ARRAY_REF_C1_LV,
    OP_LOCAL_ARRAY_REF_L1_LV,
    OP_LOCAL_ARRAY_REF_M1_LV,
    OP_MODULE_ARRAY_REF_C1_LV,
    OP_MODULE_ARRAY_REF_L1_LV,
    OP_MODULE_ARRAY_REF_M1_LV,

    OP_LOCAL_VAR_LV,
    OP_MODULE_VAR_LV,
    OP_LOCAL_ARRAY_REF_LV,
    OP_MODULE_ARRAY_REF_LV,
    OP_ARRAY_REF_LV,
    OP_PROPERTY_LV,
    OP_BC_PROPERTY_LV,  /* getting and setting byte compiled properties */
    OP_MODULE_REF_LV,  /* token used to indicate cross module reference */

    OP_ACTION_PROC,
    OP_BC_ACTION_PROC,
    OP_ACTION_FUNC,
    OP_BC_ACTION_FUNC,

    OP_DIM,

    /* Binary Operators */
    OP_ADD_INT,
    OP_ADD_LONG,
    OP_SUB_INT,
    OP_SUB_LONG,
    OP_MULTIPLY_INT,
    OP_MULTIPLY_LONG,
    OP_DIVIDE_INT,
    OP_DIVIDE_LONG,

    OP_AND_INT,
    OP_AND_LONG,
    OP_OR_INT,
    OP_OR_LONG,

    OP_EQUALS_INT,
    OP_EQUALS_LONG,
    OP_EQUALS_STRING,
    OP_LESS_THAN_INT,
    OP_LESS_THAN_LONG,
    OP_LESS_EQUAL_INT,
    OP_LESS_EQUAL_LONG,
    OP_GREATER_THAN_INT,
    OP_GREATER_THAN_LONG,
    OP_GREATER_EQUAL_INT,
    OP_GREATER_EQUAL_LONG,
    OP_LESS_GREATER_INT,
    OP_LESS_GREATER_LONG,
    OP_LESS_GREATER_STRING,

    OP_ADD,
    OP_SUB,
    OP_MULTIPLY,
    OP_DIVIDE,
    OP_LESS_THAN,
    OP_GREATER_THAN,
    OP_LESS_GREATER,
    OP_LESS_EQUAL,
    OP_GREATER_EQUAL,
    OP_EQUALS,
    OP_AND,
    OP_OR,
    OP_XOR,
    OP_MOD,

    /* Unary operators */

    OP_NEGATIVE_INT,
    OP_NEGATIVE_LONG,
    OP_POSITIVE_INT,
    OP_POSITIVE_LONG,
    OP_NOT_INT,
    OP_NOT_LONG,

    OP_NEGATIVE,
    OP_POSITIVE,
    OP_NOT,

    /* Stack operations */

    OP_DUP,
    OP_POP,

    /* General Assignment */

    OP_ASSIGN,

    /* Funky assignment opcodes */

    /* Direct assignments: bit copies from <C>onstants/<L>ocals/<M>odule Level

       variables to <L>ocal/<M>odule variables.
    */

    OP_DIR_ASSIGN_LL,           /* OPCODE_FIRST_ASSIGN */
    OP_DIR_ASSIGN_LM,
    OP_DIR_ASSIGN_LC,
    OP_DIR_ASSIGN_ML,
    OP_DIR_ASSIGN_MM,
    OP_DIR_ASSIGN_MC,
    OP_DIR_ASSIGN_ARRAY_REF_C,
    OP_DIR_ASSIGN_ARRAY_REF_L,
    OP_DIR_ASSIGN_ARRAY_REF_M,
    OP_EXP_ASSIGN_L,
    OP_EXP_ASSIGN_M,            /* OPCODE_LAST_ASSIGN */

    /* Branching */
    
    OP_BEQ,
    OP_BEQ_REL,
    OP_BEQ_SEG,

    OP_BNE,
    OP_BNE_REL,
    OP_BNE_SEG,
    
    OP_JMP,
    OP_JMP_REL,
    OP_JMP_SEG,

    /* other stuff */

    OP_DEBUG,

    OP_FOR_LM1_UNTYPED,
    OP_FOR_LM_TYPED,

    OP_NEXT_L1_INT,
    OP_NEXT_M1_INT,
    OP_NEXT_LM,

    OP_POP_LOOP,

    OP_ZERO,   /* Compact code representation for 0. */

    OP_CALL_WITH_TYPE_CHECK,

    OP_SWAP,     /* Swap top two elements on the stack. */

    OP_STRUCT_REF_RV,
    OP_STRUCT_REF_LV,
    OP_DIM_STRUCT,
    
    OP_ASSIGN_TYPED,
    
    OP_LOCAL_VAR_RV_REFS,
    OP_MODULE_VAR_RV_REFS,
    OP_COMP_INIT,
    OP_DIM_PRESERVE,

    OP_STACK_PROPERTY_RV,
    OP_STACK_PROPERTY_LV,
    OP_STACK_ACTION_PROC,
    OP_STACK_ACTION_FUNC,
    OP_NO_OP,
    
    /* Error recovery */
    OP_EHAN_PUSH,
    OP_EHAN_POP,
    OP_EHAN_MODIFY,
    OP_EHAN_RESUME,
    OP_LINE_BEGIN,		/* Beginning-of-line marker */
    OP_LINE_BEGIN_NEXT,		/* ...with added "next line" info */

    OP_BIT_AND,
    OP_BIT_AND_INT,
    OP_BIT_AND_LONG,
    OP_BIT_OR,
    OP_BIT_OR_INT,
    OP_BIT_OR_LONG,
    OP_BIT_XOR,
    OP_BIT_XOR_INT,
    OP_BIT_XOR_LONG,

    OP_LOCAL_VAR_RV_INDEX,
    OP_LOCAL_VAR_RV_INDEX_REFS,
    OP_LOCAL_VAR_LV_INDEX,

    OP_MODULE_VAR_RV_INDEX,
    OP_MODULE_VAR_RV_INDEX_REFS,
    OP_MODULE_VAR_LV_INDEX,

    OP_CUSTOM_PROPERTY_LV,
    OP_CUSTOM_PROPERTY_RV,
    
    OP_EXP_ASSIGN_L_INDEX,
    OP_EXP_ASSIGN_M_INDEX,

    OP_BYTE_INTEGER_CONST,
    OP_BYTE_STRING_CONST,

    OP_NUM_OPS,			/* Keep this last */
} Opcode;

#define OPCODE_FIRST_ASSIGN OP_DIR_ASSIGN_LL
#define OPCODE_LAST_ASSIGN OP_EXP_ASSIGN_M
#define OPCODE_IS_ASSIGN(x) (((x) >= OPCODE_FIRST_ASSIGN && (x) <= OPCODE_LAST_ASSIGN) || (x == OP_ASSIGN))

#define OP_UNKNOWN OP_ILLEGAL
#endif /* _OPCODE_H_ */
