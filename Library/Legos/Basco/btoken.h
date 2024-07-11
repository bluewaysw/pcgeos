/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		btoken.h

AUTHOR:		Roy Goldman, Dec 19, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	12/19/94		Initial version.

DESCRIPTION:
	Token information-- right now this same structure is used
	by scanner, parser, and code generator..

	It should be updated relatively soon.

	$Id: btoken.h,v 1.1 98/10/13 21:42:28 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _BTOKEN_H_
#define _BTOKEN_H_

#include <Legos/legtype.h>
#include <Legos/opcode.h>

/* First, all of the different tokens.... */

typedef enum {

    NULLCODE,

    /* The first five get associated with actual data which
       lives in the Token structure.  For all others,
       the token code says it all */
    
    CONST_INT,
    CONST_LONG,
    CONST_FLOAT,
    CONST_STRING,
    IDENTIFIER,
    INTERNAL_IDENTIFIER,	/* not a variable, just an ident string */

    NOT,

    AND,	/* FIRST_BINARY_OP */
    OR,
    XOR,
    MOD,

    MULTIPLY,
    ASTERISK = MULTIPLY,
    DIVIDE,
    MINUS,
    PLUS,
    LESS_GREATER,
    LESS_EQUAL,
    GREATER_EQUAL,
    LESS_THAN,
    GREATER_THAN,
    ASSIGN,	/* EQUALS sometimes gets converted to assign */
    BIT_AND,
    BIT_OR,
    BIT_XOR,
    EQUALS,	/* LAST_BINARY_OP */

    OPEN_PAREN,
    CLOSE_PAREN,
    OPEN_BRACKET,
    CLOSE_BRACKET,
    PERIOD,
    COMMA,
    CARET,

    IF,
    IF_DOWHILE,
    IF_LOOPUNTIL,
    DO,
    AS,
    TO,
/*    ON,*/

    ADD,
    DIM,
    END,
    FOR,
    LET,
    REM,
    SUB,

    CASE,
    ELSE,
    EXIT,
    LONG,
    LOOP,
    NEXT,
    STEP,
    THEN,
    WEND,

/*    ERROR,*/
    FLOAT,
    WHILE,
    UNTIL,

    RESUME,
    STRING,
    SELECT,
    STRUCT,

    ONERROR,

    FUNCTION,
    INTEGER,

    COMPONENT,
    COMPLEX,

    /* Some error markers */

    ERR_BAD_CHAR,
    ERR_NO_END_QUOTE,
    
    /* Some input structure markers */

    TOKEN_EOF,      /* Means we are at the string's NULL terminator,
		       which will also be a valid way to end a line */

    TOKEN_EOLS,      /* Means we hit one or more EOLS.  The token's
			line number is set to the line of the first,
			and the scanner automatically adjusts
			the lineNum counter for all EOLS... */

    NEGATIVE,	/* unary versions of plus and minus */
    POSITIVE,

    ARRAY_REF,	    /* IDENTIFIER sometimes gets converted to ARRAY_REF */
    ARRAY_REF_L1,
    ARRAY_REF_M1,
    ARRAY_REF_C1,

    STRUCT_REF,

    USER_FUNC,	    /* IDENTIFIER sometimes gets converted to USER_FUNC */
    USER_PROC,	    /* for procedures as opposed to functions */

    INTERNAL_NODE,
    PROPERTY,
    BC_PROPERTY,    /* byte compiled property */

    BUILT_IN_FUNC,  /* functions that are built in to the intepreter */
    EXCLAMATION,    
    ACTION,
    BC_ACTION,
    COLON,
    MODULE_REF,
    MODULE_CALL,
    EXPORT, 	    /* for exporting module variables */
    MODULE,
    DEBUG,   	    /* a code for setting breakpoints using a debug command */
    COERCE,
    ERR_OVERFLOW,
    STRUCTDECL,		/* Tree node used for struct type declarations */
    TYPENONE,		/* So there is a token that maps to TYPE_NONE
			 * right now just used for return value */
    GLOBAL,
    CONSTANT,	    /* used for const keyword */
    COMP_INIT,	/* used for optimized component initialization */
    LABEL,  	/* labels for gotos */
    TOKEN_GOTO,
    REDIM,
    PRESERVE,
    STACK_PROPERTY,	/* PROPERTY which prop name on stack */
    CUSTOM_PROPERTY,
    PUSH_ZERO,		/* Corresponds to OP_ZERO */
} TokenCode;

/* Values of token.data.key for ONERROR nodes */
#define KEY_GOTO_ZERO	0xffffffff
#define KEY_RESUME_NEXT	0xfffffffe

/* Construct an opcode lexically based on the current code */
#define TTOC(c) OP_ ## c

#include "mystdapp.h"

/* This macro will take a token code and return true
   if the next token is a valid line terminator: TOKEN_EOF, TOKEN_EOLS,
   or REM */

#define LINE_TERM(x) ( (x) == TOKEN_EOF || (x) == TOKEN_EOLS || (x) == REM)
#define FIRST_BINARY_OP AND
#define LAST_BINARY_OP EQUALS
#define BINARY_OP(x) ( (x) >= FIRST_BINARY_OP && (x) <= LAST_BINARY_OP )

/* Each token can store either an int, a long, a float,
   or a key which we can use to look up identifiers and
   string constants in a string table

   For operators, we store their precedence here..*/


typedef enum {
PREC_NOT,
PREC_MULTIPLY,
PREC_PLUS,
PREC_COMPARE,
PREC_EQUALS,
PREC_BIT_AND,
PREC_BIT_XOR,
PREC_BIT_OR,
PREC_AND,
PREC_XOR,
PREC_OR,
PREC_ASSIGN,
PREC_MINIMUM
} Precedence;

#define MIN_PREC PREC_MINIMUM

typedef union {
    int integer;
    long long_int;
    float num;
    dword key;
    byte precedence;    
} TokenData;


/* Tokens are the key unit processed by the parser... */

typedef struct 
{
    TokenCode	code;		/* Type of token */
    TokenData	data;		/* data stored with token */
    word	lineNum;
    LegosType	type;		/* Node's type, when it's in a tree */
    word	typeData;	/* Array:	element type
				 * struct:	string in task->structIndex
				 * component:	0xffff or string in
				 *		task->compTypeNameTable
				 */
} Token;


/* Convert a compiler token into an opcode if appropriate,
   otherwise OP_ILLEGAL */

Opcode 	    TokenToOpCode(TokenCode code);
LegosType   TokenToType(TokenCode code);
Boolean	    TokenIsKeyword(TokenCode code);
#endif /* _BTOKEN_H_ */

