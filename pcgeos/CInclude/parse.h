/***********************************************************************
*
*      Copyright (c) GeoWorks 1992 -- All Rights Reserved
*
* PROJECT:     PC/GEOS
* FILE:        parse.h
* AUTHOR:      Anna Lijphart: January, 1992
*
* DESCRIPTION:
*	C version of parse.def
*
*      $Id: parse.h,v 1.1 97/04/04 15:57:28 newdeal Exp $
*
***********************************************************************/

#ifndef __PARSEC_GOH
#define __PARSEC_GOH

#include <math.h>

typedef ByteEnum ScannerTokenType;
#define SCANNER_TOKEN_NUMBER 0
#define SCANNER_TOKEN_STRING 1
#define SCANNER_TOKEN_CELL 2
#define SCANNER_TOKEN_END_OF_EXPRESSION 3
#define SCANNER_TOKEN_OPEN_PAREN 4
#define SCANNER_TOKEN_CLOSE_PAREN 5
#define SCANNER_TOKEN_IDENTIFIER 6
#define SCANNER_TOKEN_OPERATOR 7
#define SCANNER_TOKEN_LIST_SEPARATOR 8

typedef struct {
    FloatNum	STND_value;	
} ScannerTokenNumberData;

typedef struct {
    word	STSD_start;
    word	STSD_length;
} ScannerTokenStringData;

/* 
 * 	CellRowColumn	record
 */

typedef WordFlags CellRowColumn;
#define    CRC_ABSOLUTE 	0x8000		
#define    CRC_VALUE		0x7fff		

typedef struct {
    CellRowColumn	CR_row;	
    CellRowColumn	CR_column;
} CellReference;

typedef struct {
    CellReference	CR_start;	
    CellReference	CR_end;
} CellRange;	

typedef	struct {
    CellReference	STCD_cellRef;
} ScannerTokenCellData;	

typedef ByteEnum OperatorType;
#define OP_RANGE_SEPARATOR 0
#define OP_NEGATION 1
#define OP_PERCENT 2
#define OP_EXPONENTIATION 3
#define OP_MULTIPLICATION 4
#define OP_DIVISION 5
#define OP_MODULO 6
#define OP_ADDITION 7
#define OP_SUBTRACTION 8
#define OP_EQUAL 9
#define OP_NOT_EQUAL 10
#define OP_LESS_THAN 11
#define OP_GREATER_THAN 12
#define OP_LESS_THAN_OR_EQUAL 13
#define OP_GREATER_THAN_OR_EQUAL 14
#define OP_STRING_CONCAT 15
#define OP_RANGE_INTERSECTION 16
#define OP_NOT_EQUAL_GRAPHIC 17
#define OP_DIVISION_GRAPHIC 18
#define OP_LESS_THAN_OR_EQUAL_GRAPHIC 19
#define OP_GREATER_THAN_OR_EQUAL_GRAPHIC 20

#define OP_PERCENT_MODULO 21
#define OP_SUBTRACTION_NEGATION 22


typedef struct {
    OperatorType	STOD_operatorID;	
} ScannerTokenOperatorData;

typedef struct {
    word	STID_start;
} ScannerTokenIdentifierData;	

typedef union {
    ScannerTokenNumberData	STD_number;
    ScannerTokenStringData	STD_string;
    ScannerTokenCellData	STD_cell;
    ScannerTokenIdentifierData	STD_identifier;
    ScannerTokenOperatorData	STD_operator;
} ScannerTokenData;

typedef struct {
    ScannerTokenType	ST_type;
    ScannerTokenData	ST_data;
} ScannerToken;

typedef ByteEnum ParserTokenType;
#define PARSER_TOKEN_NUMBER 0
#define PARSER_TOKEN_STRING 1
#define PARSER_TOKEN_CELL 2
#define PARSER_TOKEN_END_OF_EXPRESSION 3
#define PARSER_TOKEN_OPEN_PAREN 4
#define PARSER_TOKEN_CLOSE_PAREN 5
#define PARSER_TOKEN_NAME 6
#define PARSER_TOKEN_FUNCTION 7
#define PARSER_TOKEN_CLOSE_FUNCTION 8
#define PARSER_TOKEN_ARG_END 9
#define PARSER_TOKEN_OPERATOR 10

typedef struct {
    FloatNum	PTND_value;	
} ParserTokenNumberData;

typedef struct {
    word	PTSD_length;
} ParserTokenStringData;

typedef struct {
    CellReference	PTCD_cellRef;
} ParserTokenCellData;

typedef struct {
    word	PTFD_functionID;
} ParserTokenFunctionData;

typedef struct {	
    OperatorType	PTOD_operatorID;
} ParserTokenOperatorData;

typedef	struct {
    word	PTND_name;
} ParserTokenNameData;	

typedef union {
    ParserTokenNumberData	PTD_number;
    ParserTokenStringData	PTD_string;
    ParserTokenNameData		PTD_name;
    ParserTokenCellData		PTD_cell;
    ParserTokenFunctionData	PTD_function;
    ParserTokenOperatorData	PTD_operator;
} ParserTokenData;

typedef struct {
    ParserTokenType	PT_type;	
    ParserTokenData	PT_data;
} ParserToken;	

/*
 * 	ParserFlags	record
 */
typedef ByteFlags ParserFlags;
#define	PF_HAS_LOOKAHEAD	    0x80
#define PF_CONTAINS_DISPLAY_FUNC    0x40
#define PF_OPERATORS	    	    0x20
#define PF_NUMBERS  	    	    0x10
#define PF_CELLS   	    	    0x08
#define PF_FUNCTIONS	    	    0x04
#define PF_NAMES    	    	    0x02
#define PF_NEW_NAMES	    	    0x01

typedef ByteEnum ParserScannerEvaluatorError;
/*
 * Scanner errors
 */
#define PSEE_BAD_NUMBER	    	    	    0
#define PSEE_BAD_CELL_REFERENCE	    	    1
#define PSEE_NO_CLOSE_QUOTE 	    	    2
#define PSEE_COLUMN_TOO_LARGE	    	    3
#define PSEE_ROW_TOO_LARGE  	    	    4
#define PSEE_ILLEGAL_TOKEN  	    	    5
/*
 * Parser errors
 */
#define PSEE_GENERAL	    	    	    6
#define PSEE_TOO_MANY_TOKENS	    	    7
#define PSEE_EXPECTED_OPEN_PAREN    	    8
#define PSEE_EXPECTED_CLOSE_PAREN   	    9
#define PSEE_BAD_EXPRESSION 	    	    10
#define PSEE_EXPECTED_END_OF_EXPRESSION	    11
#define PSEE_MISSING_CLOSE_PAREN    	    12
#define PSEE_UNKNOWN_IDENTIFIER	    	    13
#define PSEE_NOT_ENOUGH_NAME_SPACE  	    14
/*
 * Serious evaluator errors
 */
#define PSEE_OUT_OF_STACK_SPACE	    	    15
#define PSEE_NESTING_TOO_DEEP	    	    16
/*
 * Evaluator errors that are returned as the result of formulas.
 * These are returned on the argument stack.
 */
#define PSEE_ROW_OUT_OF_RANGE	    	    17
#define PSEE_COLUMN_OUT_OF_RANGE    	    18
#define PSEE_FUNCTION_NO_LONGER_EXISTS	    19
#define PSEE_BAD_ARG_COUNT  	    	    20
#define PSEE_WRONG_TYPE	    	    	    21
#define PSEE_DIVIDE_BY_ZERO 	    	    22
#define PSEE_UNDEFINED_NAME 	    	    23
#define PSEE_CIRCULAR_REF   	    	    24
#define PSEE_CIRCULAR_DEP   	    	    25
#define PSEE_CIRC_NAME_REF  	    	    26
#define PSEE_NUMBER_OUT_OF_RANGE    	    27
#define PSEE_GEN_ERR	    	    	    28
#define PSEE_NA	    	    	    	    29
/*
 * Dependency errors
 */
#define PSEE_TOO_MANY_DEPENDENCIES  	    30

#define PSEE_SSHEET_BASE 	0xc0
#define PSEE_FLOAT_BASE 	250
#define PSEE_APP_BASE		230

#define PSEE_FLOAT_POS_INFINITY     	    PSEE_FLOAT_BASE
#define PSEE_FLOAT_NEG_INFINITY	    	    (PSEE_FLOAT_BASE + 1)
#define PSEE_FLOAT_GEN_ERR	    	    (PSEE_FLOAT_BASE + 2)

#define  PSEE_PARSER_ERRORS PSEE_BAD_NUMBER, \
    PSEE_BAD_CELL_REFERENCE, \
    PSEE_NO_CLOSE_QUOTE, \
    PSEE_COLUMN_TOO_LARGE, \
    PSEE_ROW_TOO_LARGE, \
    PSEE_ILLEGAL_TOKEN, \
    PSEE_GENERAL, \
    PSEE_TOO_MANY_TOKENS, \
    PSEE_EXPECTED_OPEN_PAREN, \
    PSEE_EXPECTED_CLOSE_PAREN, \
    PSEE_BAD_EXPRESSION, \
    PSEE_EXPECTED_END_OF_EXPRESSION, \
    PSEE_MISSING_CLOSE_PAREN, \
    PSEE_UNKNOWN_IDENTIFIER, \
    PSEE_NOT_ENOUGH_NAME_SPACE, \
    PSEE_OUT_OF_STACK_SPACE, \
    PSEE_NESTING_TOO_DEEP, \
    PSEE_ROW_OUT_OF_RANGE, \
    PSEE_COLUMN_OUT_OF_RANGE, \
    PSEE_FUNCTION_NO_LONGER_EXISTS, \
    PSEE_BAD_ARG_COUNT, \
    PSEE_WRONG_TYPE, \
    PSEE_DIVIDE_BY_ZERO, \
    PSEE_UNDEFINED_NAME, \
    PSEE_CIRCULAR_REF, \
    PSEE_CIRCULAR_DEP, \
    PSEE_CIRC_NAME_REF, \
    PSEE_NUMBER_OUT_OF_RANGE, \
    PSEE_GEN_ERR, \
    PSEE_NA, \
    PSEE_TOO_MANY_DEPENDENCIES 

#define PSEE_FLOAT_ERRORS	\
    PSEE_PARSER_ERRORS, \
    PSEE_FLOAT_POS_INFINITY = PSEE_FLOAT_BASE, \
    PSEE_FLOAT_NEG_INFINITY, \
    PSEE_FLOAT_GEN_ERR

typedef struct {
    word        CP_row;
    word        CP_column;
    word        CP_maxRow;
    word        CP_maxColumn;
    void *      CP_callback;
    void *      CP_cellParams;	  /* ptr to an instance of SpreadsheetClass */
} CommonParameters;

typedef ByteEnum CallbackType;
#define CT_FUNCTION_TO_TOKEN 0
#define CT_NAME_TO_TOKEN 1
#define CT_CHECK_NAME_EXISTS 2
#define CT_CHECK_NAME_SPACE 3
#define CT_EVAL_FUNCTION 4
#define CT_LOCK_NAME 5
#define CT_UNLOCK 6
#define CT_FORMAT_FUNCTION 7
#define CT_FORMAT_NAME 8
#define CT_CREATE_CELL 9
#define CT_EMPTY_CELL 10
#define CT_NAME_TO_CELL 11
#define CT_FUNCTION_TO_CELL 12
#define CT_DEREF_CELL 13
#define CT_SPECIAL_FUNCTION 14

/*
 * Don't use the ParserParameters structure if you're calling ParseString.
 * Use the CParserParameters structure instead.
 */
typedef struct {
    CommonParameters	PP_common;
    word		PP_parserBufferSize;
    ParserFlags		PP_flags;
    dword		PP_textPtr;
    ScannerToken	PP_currentToken;
    ScannerToken	PP_lookAheadToken;
    byte		PP_error;	/* ParserScannerEvaluatorError */
    word		PP_tokenStart;
    word		PP_tokenEnd;
} ParserParameters;

typedef enum  /* word */ {
    SF_FILENAME,
    SF_PAGE,
    SF_PAGES,
} SpecialFunctions;

/*
 * C Callback structures:
 *	All callback structures have as the first byte the CallbackType,
 *	then any passed values, then a set of variables that are
 *	filled with return values.
 */

/* CT_FUNCTION_TO_TOKEN --
 *
 * Description:
 *	Convert a function name to a function id token.
 * Pass:
 *	callbackType  	= CT_FUNCTION_TO_TOKEN
 *	params 	      	= Pointer to ParserParameters
 *	text   	    	= Pointer to the text of the identifier
 *	length 	    	= Length of the identifier
 * Return:
 *	isFunctionName 	= set this to non-zero if the text is a function name
 *	funcID	      	= The Function-ID for the identifier
 */
typedef struct {
    char *  	    	text;
    word    	    	length;
    byte 	    	isFunctionName;
    word    	    	funcID;
} CT_FTT_CallbackStruct;

/* CT_NAME_TO_TOKEN --
 *
 * Description:
 *	Convert a name to a name id token.
 * Pass:
 *	callbackType  	= CT_NAME_TO_TOKEN
 *	params 	    	= Pointer to ParserParameters
 *	text   	    	= Pointer to the text of the identifier
 *	length 	    	= Length of the identifier
 * Return:
 *	nameID	      	= Token for the name
 *	errorOccurred 	= set to non-zero if an error occurred.
 *	error	     	= error code
 */
typedef struct {
    char *  	    	text;
    word    	    	length;
    word    	    	nameID;
    byte 	    	errorOccurred;
    byte    	    	error;
} CT_NTT_CallbackStruct;

/* CT_CHECK_NAME_EXISTS --
 *
 * Description:
 *	Check to see if a name already exists
 * Pass:
 *	callbackType  	= CT_CHECK_NAME_EXISTS
 *	params 	    	= Pointer to ParserParameters
 *	text   	    	= Pointer to the text of the identifier
 *	length 	    	= Length of the identifier
 * Return:
 *	nameExists  	= non-zero if the name does exist
 */
typedef struct {
    char *  	    	text;
    word    	    	length;
    byte	    	nameExists;
} CT_CNE_CallbackStruct;

/* CT_CHECK_NAME_SPACE
 * Description:
 *	Signal the need to allocate a certain number of names.
 *	This is used to avoid the problem of getting part way through
 *	allocating names for an expression and then finding we don't
 *	have any more space for names.
 * Pass:
 *	callbackType  	= CT_CHECK_NAME_SPACE
 *	params 	    	= Pointer to ParserParameters
 *	numToAllocate 	= # of names we want to allocate
 * Return:
 *	enoughSpace 	= set to non-zero if there was enough space.
 *	errorOccurred 	= set to non-zero if an error occurred.
 *	error	     	= error code
 */
typedef struct {
    word    	    	numToAllocate;
    byte    	    	enoughSpace;
    byte 	    	errorOccurred;
    byte    	    	error;
} CT_CNS_CallbackStruct;

/* CT_EVAL_FUNCTION --
 *
 * Description:
 *	Evaluate a function with parameters.
 * Pass:
 *	callbackType  	= CT_CHECK_NAME_EXISTS
 *	params 	    	= Pointer to EvalParameters
 *	numArgs	    	= # of arguments
 *	funcID	    	= Function ID
 * Return:
 *	errorOccurred 	= set to non-zero if an error occurred.
 *	error	     	= error code
 */
typedef struct {
    word    	    	numArgs;
    word    	    	funcID;
    byte 	    	errorOccurred;
    byte    	    	error;
} CT_EF_CallbackStruct;

/* CT_LOCK_NAME
 *
 * Description:
 *	Lock a name definition.
 * Pass:
 *	callbackType  	= CT_LOCK_NAME
 *	params 	    	= Pointer to ParserParameters
 *	nameToken   	= Name token
 * Return:
 *	defPtr	    	= Far pointer to the definition
 *	errorOccurred 	= set to non-zero if an error occurred
 *	error	     	= error code
 */
typedef struct {
    word    	    	nameToken;
    byte *   	    	defPtr;
    byte 	    	errorOccurred;
    byte    	    	error;
} CT_LN_CallbackStruct;

/* CT_UNLOCK
 *
 * Description:
 *	Unlock a name/function definition.
 * Pass:
 *	callbackType  	= CT_UNLOCK
 *	params 	    	= Pointer to ParserParameters
 *	dataPtr	    	= Pointer to data to unlock
 * Return:
 *	nothing
 */
typedef struct {
    byte *       	    	dataPtr;
} CT_UL_CallbackStruct;

/* CT_FORMAT_FUNCTION
 *
 * Description:
 *	Format a function name into a buffer.
 * Pass:
 *	callbackType  	= CT_FORMAT_FUNCTION
 *	params	    	= Pointer to ParserParameters
 *	textPtr	    	= Pointer to place to store the text
 *	funcToken    	= Function token
 *	maxChars    	= Maximum number of characters that can be written
 * Return:
 *	resultPtr   	= Pointer past the inserted text
 *	numWritten  	= # of characters that were written
 */
typedef struct {
    char *  	    	textPtr;
    word    	    	funcToken;
    word    	    	maxChars;
    char *  	    	resultPtr;
    word    	    	numWritten;
} CT_FF_CallbackStruct;

/* CT_FORMAT_NAME
 *
 * Description:
 *	Format a name into a buffer.
 * Pass:
 *	callbackType  	= CT_FORMAT_NAME
 *	params	    	= Pointer to ParserParameters
 *	textPtr	    	= Pointer to place to store the text
 *	nameToken    	= Name token
 *	maxChars    	= Maximum number of characters that can be written
 * Return:
 *	resultPtr   	= Pointer past the inserted text
 *	numWritten  	= # of characters that were written
 */
typedef struct {
    char *  	    	textPtr;
    word    	    	nameToken;
    word    	    	maxChars;
    char *  	    	resultPtr;
    word    	    	numWritten;
} CT_FN_CallbackStruct;

/* CT_CREATE_CELL
 *
 * Description:
 *	Create a new empty cell. Used by the dependency code to
 *	create a cell to add dependencies to.
 * Pass:
 *	callbackType  	= CT_CREATE_CELL
 *	params 	    	= Pointer to ParserParameters
 *	row 	    	= Row of the cell to create
 *	column	    	= Column of the cell to create
 * Return:
 *	errorOccurred 	= set to non-zero if an error occurred
 *	error	     	= error code
 */
typedef struct {
    word    	    	row;
    word    	    	column;
    byte 	    	errorOccurred;
    byte    	    	error;
} CT_CC_CallbackStruct;

/* CT_EMPTY_CELL
 *
 * Description:
 *	Remove a cell if it's appropriate. This is called when a cell
 *	has its last dependency removed.
 * Pass:
 *	callbackType  	= CT_EMPTY_CELL
 *	params 	    	= Pointer to ParserParameters
 *	row 	    	= Row of the cell that now has no dependencies
 *	column	    	= Column of the cell that now has no dependencies
 * Return:
 *	errorOccurred 	= set to non-zero if an error occurred
 *	error	     	= error code
 */
typedef struct {
    word    	    	row;
    word    	    	column;
    byte 	    	errorOccurred;
    byte    	    	error;
} CT_EC_CallbackStruct;

/* CT_NAME_TO_CELL
 *
 * Description:
 *	Convert a name to a cell so we can add a dependency to it.
 * Pass:
 *	callbackType  	= CT_NAME_TO_CELL
 *	params 	    	= Pointer to ParserParameters
 *	nameToken   	= Name token
 * Return:
 *	row 	    	= Row of the cell containing the names dependencies
 *	column	    	= Column of the cell containing the names dependencies
 */
typedef struct {
    word    	    	nameToken;
    word    	    	row;
    word    	    	column;
} CT_NTC_CallbackStruct;

/* CT_FUNCTION_TO_CELL
 *
 * Description:
 *	Convert a function to a cell so we can add a dependencies to
 *	it.
 * Pass:
 *	callbackType  	= CT_FUNCTION_TO_CELL
 *	params 	    	= Pointer to ParserParameters
 *	funcID	    	= Function-ID
 * Return:
 *	row 	    	= Row of the cell containing the functions dependencies
 *	    	    	= 0 if no dependency is required
 *	column	    	= Column of the cell containing the functions
 */
typedef struct {
    word    	    	funcID;
    word    	    	row;
    word    	    	column;
} CT_FTC_CallbackStruct;

/* CT_DEREF_CELL
 *
 * Description:
 *	Get the contents of a cell. The callback is responsible for
 *	popping the cell reference off the stack.
 * Pass:
 *	callbackType  	= CT_DEREF_CELL
 *	params 	    	= Pointer to EvalParameters
 *	argStack    	= Pointer to the argument stack
 *	opFnStack   	= Pointer to operator/function stack
 *	row 	    	= Row of the cell to dereference
 *	column	    	= Column of the cell to dereference
 *	derefFlags  	= DerefFlags
 * Return:
 *	newArgStack 	= New pointer to the argument stack
 *	errorOccurred 	= set to non-zero if an error occurred
 *	error	     	= error code
 */
typedef struct {
    byte *  	    	argStack;
    byte *  	    	opFnStack;
    word    	    	row;
    byte    	    	column;
    byte    	    	derefFlags;
    byte *  	    	newArgStack;
    byte 	    	errorOccurred;
    byte    	    	error;
} CT_DC_CallbackStruct;

/* CT_SPECIAL_FUNCTION
 *
 * Description:
 *	Get the value of one of the special functions.
 * Pass:
 *	callbackType  	= CT_SPECIAL_FUNCTION
 *	params 	    	= Pointer to EvalParameters
 *	argStack    	= Pointer to the argument stack
 *	opFnStack   	= Pointer to operator/function stack
 *	specialFunction	= Special function
 * Return:
 *	newArgStack 	= New pointer to the argument stack
 *	errorOccurred 	= set to non-zero if an error occurred
 *	error	     	= error code
 */
typedef struct {
    byte *  	    	argStack;
    byte *  	    	opFnStack;
    SpecialFunctions	specialFunction;
    byte *  	    	newArgStack;
    byte 	    	errorOccurred;
    byte    	    	error;
} CT_SF_CallbackStruct;

#define FUNCTION_ID_FIRST_EXTERNAL_FUNCTION_BASE	0x8000

typedef enum /* word */ {
    FUNCTION_ID_ABS,
    FUNCTION_ID_ACOS,
    FUNCTION_ID_ACOSH,
    FUNCTION_ID_AND,
    FUNCTION_ID_ASIN,
    FUNCTION_ID_ASINH,
    FUNCTION_ID_ATAN,
    FUNCTION_ID_ATAN2,
    FUNCTION_ID_ATANH,
    FUNCTION_ID_AVG,
    FUNCTION_ID_CHAR,
    FUNCTION_ID_CHOOSE,
    FUNCTION_ID_CLEAN,
    FUNCTION_ID_CODE,
    FUNCTION_ID_COLS,
    FUNCTION_ID_COS,
    FUNCTION_ID_COSH,
    FUNCTION_ID_COUNT,
    FUNCTION_ID_CTERM,
    FUNCTION_ID_DATE,
    FUNCTION_ID_DATEVALUE,
    FUNCTION_ID_DAY,
    FUNCTION_ID_DDB,
    FUNCTION_ID_ERR,
    FUNCTION_ID_EXACT,
    FUNCTION_ID_EXP,
    FUNCTION_ID_FACT,
    FUNCTION_ID_FALSE,
    FUNCTION_ID_FIND,
    FUNCTION_ID_FV,
    FUNCTION_ID_HLOOKUP,
    FUNCTION_ID_HOUR,
    FUNCTION_ID_IF,
    FUNCTION_ID_INDEX,
    FUNCTION_ID_INT,
    FUNCTION_ID_IRR,
    FUNCTION_ID_ISERR,
    FUNCTION_ID_ISNUMBER,
    FUNCTION_ID_ISSTRING,
    FUNCTION_ID_LEFT,
    FUNCTION_ID_LENGTH,
    FUNCTION_ID_LN,
    FUNCTION_ID_LOG,
    FUNCTION_ID_LOWER,
    FUNCTION_ID_MAX,
    FUNCTION_ID_MID,
    FUNCTION_ID_MIN,
    FUNCTION_ID_MINUTE,
    FUNCTION_ID_MOD,
    FUNCTION_ID_MONTH,
    FUNCTION_ID_N,
    FUNCTION_ID_NA,
    FUNCTION_ID_NOW,
    FUNCTION_ID_NPV,
    FUNCTION_ID_OR,
    FUNCTION_ID_PI,
    FUNCTION_ID_PMT,
    FUNCTION_ID_PRODUCT,
    FUNCTION_ID_PROPER,
    FUNCTION_ID_PV,
    FUNCTION_ID_RANDOM_N,
    FUNCTION_ID_RANDOM,
    FUNCTION_ID_RATE,
    FUNCTION_ID_REPEAT,
    FUNCTION_ID_REPLACE,
    FUNCTION_ID_RIGHT,
    FUNCTION_ID_ROUND,
    FUNCTION_ID_ROWS,
    FUNCTION_ID_SECOND,
    FUNCTION_ID_SIN,
    FUNCTION_ID_SINH,
    FUNCTION_ID_SLN,
    FUNCTION_ID_SQRT,
    FUNCTION_ID_STD,
    FUNCTION_ID_STDP,
    FUNCTION_ID_STRING,
    FUNCTION_ID_SUM,
    FUNCTION_ID_SYD,
    FUNCTION_ID_TAN,
    FUNCTION_ID_TANH,
    FUNCTION_ID_TERM,
    FUNCTION_ID_TIME,
    FUNCTION_ID_TIMEVALUE,
    FUNCTION_ID_TODAY,
    FUNCTION_ID_TRIM,
    FUNCTION_ID_TRUE,
    FUNCTION_ID_TRUNC,
    FUNCTION_ID_UPPER,
    FUNCTION_ID_VALUE,
    FUNCTION_ID_VAR,
    FUNCTION_ID_VARP,
    FUNCTION_ID_VLOOKUP,
    FUNCTION_ID_WEEKDAY,
    FUNCTION_ID_YEAR,
    FUNCTION_ID_FILENAME,
    FUNCTION_ID_PAGE,
    FUNCTION_ID_PAGES,
    FUNCTION_ID_DEGREES,
    FUNCTION_ID_RADIANS,
#ifdef DO_PIZZA
    FUNCTION_ID_DB,
#endif
    FUNCTION_ID_FIRST_EXTERNAL_FUNCTION=FUNCTION_ID_FIRST_EXTERNAL_FUNCTION_BASE
} FunctionID;

typedef WordFlags FunctionType;
#define FT_ALL	    	    	0xffff
#define FT_PRINT    	    	0x0100
#define FT_TRIGONOMETRIC    	0x0080
#define FT_LOGICAL  	    	0x0040
#define FT_STATISTICAL	    	0x0020
#define FT_STRING   	    	0x0010
#define FT_TIME_DATE	    	0x0008
#define FT_FINANCIAL	    	0x0004
#define FT_MATH	    	    	0x0002
#define FT_INFORMATION	    	0x0001

typedef ByteEnum EvalStackOperatorType;
#define ESOT_OPERATOR 0
#define ESOT_FUNCTION 1
#define ESOT_OPEN_PAREN 2
#define ESOT_TOP_OF_STACK 3

typedef struct {
    FunctionID	EFD_functionID;	
    word	EFD_nArgs;
} EvalFunctionData;

typedef struct {
    OperatorType	EOD_opType;
} EvalOperatorData;

typedef union {
    EvalOperatorData	ESOD_operator;	
    EvalFunctionData	ESOD_function;
} EvalStackOperatorData;

typedef struct {
    EvalStackOperatorType	OSE_type;
    EvalStackOperatorType	OSE_data;
} OperatorStackElement;	

typedef ByteEnum NumberType;
#define NT_VALUE 0
#define NT_BOOLEAN 1
#define NT_DATE_TIME 2

/*
 *	EvalStackArgumentType	record
 */

typedef ByteFlags EvalStackArgumentType;
#define	ESAT_EMPTY	0x80 
#define ESAT_ERROR	0x40
#define ESAT_RANGE	0x20
#define ESAT_STRING	0x10
#define ESAT_NUMBER	0x08
#define ESAT_NUM_TYPE	0x03

#define ESAT_TOP_OF_STACK  0
#define ESAT_NAME	 (ESAT_RANGE  | ESAT_STRING)
#define ESAT_FUNCTION	 (ESAT_NUMBER | ESAT_STRING)


typedef struct {
    word	END_name;
} EvalNameData;	

typedef struct {
    word	ESD_length;
} EvalStringData;

#define	MAX_STRING_LENGTH	511

typedef struct {
    CellReference	ERD_firstCell;
    CellReference	ERD_lastCell;
} EvalRangeData;

typedef struct {
    byte	EED_errorCode;	/* ParserScannerEvaluatorError */
} EvalErrorData;	

typedef union {
    EvalStringData	ESAD_string;
    EvalRangeData	ESAD_range;
    EvalErrorData	ESAD_error;
} EvalStackArgumentData;

typedef struct {
    EvalStackArgumentType	ASE_type;
    EvalStackArgumentData	ASE_data;
} ArgumentStackElement;

#define	MINIMUM_STACK_SPACE	((2 * size ArgumentStackElement) + \
				 (2 * size OperatorStackElement))

/*
 * 	EvalFlags	record
 */
typedef ByteFlags EvalFlags;
#define EF_MAKE_DEPENDENCIES	0x80
#define EF_ONLY_NAMES		0x40
#define EF_KEEP_LAST_CELL	0x20
#define EF_NO_NAMES		0x10
#define EF_ERROR_PUSHED		0x08

#define	EVAL_MAX_NESTED_LEVELS	32

typedef struct {
    CommonParameters	EP_common;		
    EvalFlags		EP_flags;
    word		EP_fpStack;
    word		EP_depHandle;	
    word		EP_nestedLevel;	
    dword		EP_nestedAddresses[EVAL_MAX_NESTED_LEVELS];
    byte    	    	EP_align;
	/* align word */
} EvalParameters;

/*
 *	DerefFlags	record
 */
typedef ByteFlags DerefFlags;
#define	DF_DONT_POP_ARGUMENT 0x80		

typedef struct {
    CommonParameters	FP_common;
    word		FP_nChars;	
} FormatParameters;

typedef struct {
    CommonParameters	DP_common;
    dword		DP_dep;	
    dword		DP_prev;
    byte		DP_prevIsCell;	
    word		DP_chunk;
    /* align	word: */
    byte    	    	DP_align;
} DependencyParameters;

typedef struct {
    dword		DLH_next;
} DependencyListHeader;	

typedef struct {
    word	D_row;
    byte	D_column;
} Dependency;

#define	DEPENDENCY_BLOCK_MAX_SIZE	(sizeof(DependencyListHeader) +	\
					 (1000 * sizeof(Dependency)))

typedef struct {
    word	DB_size;
} DependencyBlock;

/*
 * A pointer to this union is passed to the parse library stub to communicate
 * with the C callback routines.
 */
typedef union {
    CT_FTT_CallbackStruct   CT_ftt;    
    CT_NTT_CallbackStruct   CT_ntt;    
    CT_CNE_CallbackStruct   CT_cne;    
    CT_CNS_CallbackStruct   CT_cns;    
    CT_EF_CallbackStruct    CT_ef;    
    CT_LN_CallbackStruct    CT_ln;    
    CT_UL_CallbackStruct    CT_ul;    
    CT_FF_CallbackStruct    CT_ff;    
    CT_FN_CallbackStruct    CT_fn;    
    CT_CC_CallbackStruct    CT_cc;    
    CT_EC_CallbackStruct    CT_ec;    
    CT_NTC_CallbackStruct   CT_ntc;    
    CT_FTC_CallbackStruct   CT_ftc;    
    CT_DC_CallbackStruct    CT_dc;    
    CT_SF_CallbackStruct    CT_sf;  
} C_CallbackUnion;

/*
 * The C_CallbackStruct is used by the C stub to call a C callback
 * function and return its results correctly to ParseString or whoever
 * made the callback.
 */
typedef struct {
    CallbackType    	    C_callbackType;
    union {
	ParserParameters     *CP_params;
	FormatParameters     *CF_params;
	EvalParameters	     *CE_params;
	DependencyParameters *DP_params;
    } C_params;
    word    	    	    C_returnDS;
    C_CallbackUnion    	    C_u;

    /* align word... so we need a throwaway byte. */
    byte    	    	    C_align;
} C_CallbackStruct;

/*
 * The CParserStruct is identical to the ParserParameters structure,
 * except that it has some extra information for assembly stub use.
 */
typedef struct {
    ParserParameters	C_parameters;
    PCB(void,  	    	C_callbackPtr,(C_CallbackStruct *));
    	    	    	/* Points to a C callback function that returns void */
    C_CallbackStruct 	C_callbackStruct;
    	    	    	/* The callback structure defined above. */
} CParserStruct;

/*
 * The CFormatStruct is identical to the FormatParameters structure,
 * except that it has some extra information for assembly stub use.
 */
typedef struct {
    FormatParameters	CF_parameters;
    PCB(void,  	    	CF_callbackPtr,(C_CallbackStruct *));
    	    	    	/* Points to a C callback function that returns void */
    C_CallbackStruct	CF_callbackStruct;
    	    	    	/* The callback structure defined above. */
} CFormatStruct;

/*
 * The CEvalStruct is identical to the EvalParameters structure,
 * except that it has some extra information for assembly stub use.
 */
typedef struct {
    EvalParameters	CE_parameters;
    PCB(void,  	    	CE_callbackPtr,(C_CallbackStruct *));
    	    	    	/* Points to a C callback function that returns void */
    C_CallbackStruct	CE_callbackStruct;
    	    	    	/* The callback structure defined above. */
} CEvalStruct;

/*
 * The CDependencyStruct is identical to the DependencyParameters structure,
 * except that it has some extra information for assembly stub use.
 */
typedef struct {
    DependencyParameters DP_parameters;
    PCB(void,  	    	 DP_callbackPtr,(C_CallbackStruct *));
    	    	    	 /* Points to a C callback function that returns void */
    C_CallbackStruct	 DP_callbackStruct;
    	    	    	 /* The callback structure defined above. */
} CDependencyStruct;

/* The CParserReturnStruct is used in the ParseString stub. */
typedef struct {
    byte    	    	PRS_errorCode;
    word    	    	PRS_textOffsetStart;
    word    	    	PRS_textOffsetEnd;
    byte *  	    	PRS_lastTokenPtr;
} CParserReturnStruct;

#define	YEAR_LENGTH	365
#define YEAR_MAX	2099
#define YEAR_MIN	1900
#define MONTH_MAX	12
#define MONTH_MIN	1
#define DAY_MAX		31
#define DAY_MIN		1

#define HOUR_MAX	23
#define HOUR_MIN	0
#define MINUTE_MAX	59
#define MINUTE_MIN	0
#define SECOND_MAX	59
#define SECOND_MIN	0
	
#define	MAX_REFERENCE_SIZE	6*sizeof(TCHAR)
#define MAX_RANGE_REF_SIZE  	16*sizeof(TCHAR)
/*
 * Maximum size for function argument descriptions for ParserGetFunctionArgs()
 */
#define	MAX_FUNCTION_ARGS_SIZE	    	256*sizeof(TCHAR)
#define	MAX_FUNCTION_NAME_SIZE	    	20*sizeof(TCHAR)
#define MAX_FUNCTION_DESCRIPTION_SIZE	256*sizeof(TCHAR)

extern word
    _pascal ParserGetNumberOfFunctions(FunctionType funcType);

extern word
    _pascal ParserGetFunctionMoniker(FunctionID funcID,
				     FunctionType funcType,
			     	    char *textPtr);

extern word
    _pascal ParserGetFunctionArgs(FunctionID funcID,
				  FunctionType funcType,
			     	  char *textPtr);

extern word
    _pascal ParserGetFunctionDescription(FunctionID funcID,
					 FunctionType funcType,
					 char *textPtr);

extern void
    _pascal ParserFormatColumnReference (word colNum, 
			   char *buffer, 
			   word bufferSize);

extern int
    _pascal ParserParseString (char *textBuffer,
		 byte *tokenBuffer, 
		 CParserStruct *parserParams,
		 CParserReturnStruct *retval);

extern int
    _pascal ParserFormatExpression (byte *tokenBuffer, 
		      char *textBuffer,
		      CFormatStruct *formatParams);

extern int
    _pascal ParserEvalExpression (byte *tokenBuffer, 
		    byte *scratchBuffer,
		    byte *resultsBuffer,
		    word bufSize,
		    CEvalStruct *evalParams);

#ifdef __HIGHC__
pragma Alias (ParserGetNumberOfFunctions, "PARSERGETNUMBEROFFUNCTIONS");
pragma Alias (ParserGetFunctionMoniker, "PARSERGETFUNCTIONMONIKER");
pragma Alias (ParserGetFunctionArgs, "PARSERGETFUNCTIONARGS");
pragma Alias (ParserGetFunctionDescription, "PARSERGETFUNCTIONDESCRIPTION");
pragma Alias (ParserFormatColumnReference, "PARSERFORMATCOLUMNREFERENCE");
pragma Alias (ParserParseString, "PARSERPARSESTRING");
pragma Alias (ParserFormatExpression, "PARSERFORMATEXPRESSION");
pragma Alias (ParserEvalExpression, "PARSEREVALEXPRESSION");
/*
pragma Alias (ParserEvalPushArgument, "PARSEREVALPUSHARGUMENT");
pragma Alias (ParserEvalPopNArgs, "PARSEREVALPOPNARGS");
pragma Alias (ParserEvalForeachArg, "PARSEREVALFOREACHARG");
pragma Alias (ParserEvalPushNumericConstant, "PARSEREVALPUSHNUMERICCONSTANT");
pragma Alias (ParserEvalPushNumericConstantWord, "PARSEREVALPUSHNUMERICCONSTANTWORD");
pragma Alias (ParserEvalPushStringConstant, "PARSEREVALPUSHSTRINGCONSTANT");
pragma Alias (ParserEvalPushCellReference, "PARSEREVALPUSHCELLREFERENCE");
pragma Alias (ParserEvalPushRange, "PARSEREVALPUSHRANGE");
pragma Alias (ParserEvalRangeIntersection, "PARSEREVALRANGEINTERSECTION");
pragma Alias (ParserEvalPropagateEvalError, "PARSEREVALPROPAGATEEVALERROR");
pragma Alias (ParserAddDependencies, "PARSERADDDEPENDENCIES");
pragma Alias (ParserRemoveDependencies, "PARSERREMOVEDEPENDENCIES");
pragma Alias (ParserForeachReference, "PARSERFOREACHREFERENCE");
pragma Alias (ParserForeachToken, "PARSERFOREACHTOKEN");
pragma Alias (ParserForeachPrecedent, "PARSERFOREACHPRECEDENT");
pragma Alias (ParserFormatRowReference, "PARSERFORMATROWREFERENCE");
pragma Alias (ParserFormatWordConstant, "PARSERFORMATWORDCONSTANT");
*/
#endif
#endif	
