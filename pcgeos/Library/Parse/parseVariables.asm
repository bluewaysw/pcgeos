COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		parseVariables.asm

AUTHOR:		John Wedgwood, Jan 16, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/16/91	Initial revision
	witt	10/20/93	DBCS-ized token strings.

DESCRIPTION:
	Variables and tables for the parser library.

	$Id: parseVariables.asm,v 1.1 97/04/05 01:27:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

;------------------------------------------------------------------------------
;
; Tables describing the operators and their identifiers. Note that the entries
; in the tables match up. eg: The 2nd entry of the operator2IDTable is
; OP_GREATER_THAN_OR_EQUAL. The 2nd entry in the operator2Table is the 2
; character string corresponding to greater-than-or-equal.
; 
; The entries ending with _GRAPHIC represent the graphic characters available
; in PC/GEOS.  For example, OP_NOT_EQUAL_GRAPHIC is the same operator as
; OP_NOT_EQUAL, but it shows up on screen as an equals sign with a line through
; it.
;

operator2IDTable OperatorType \
			OP_NOT_EQUAL,
			OP_GREATER_THAN_OR_EQUAL,
			OP_LESS_THAN_OR_EQUAL

;  All operator2Table chars here MUST be strict ASCII (even under DBCS)!
operator2Table	char	'<', '>',	; <> : Not equal
			'>', '=',	; >= : Greater than or equal
			'<', '='	; <= : Less than or equal

operatorIDTable	OperatorType \
			OP_PERCENT_MODULO,
			OP_EXPONENTIATION,
			OP_MULTIPLICATION,
			OP_DIVISION,
			OP_ADDITION,
			OP_SUBTRACTION_NEGATION,
			OP_LESS_THAN,
			OP_GREATER_THAN,
			OP_EQUAL,
			OP_STRING_CONCAT,
			OP_DIVISION_GRAPHIC,
			OP_NOT_EQUAL_GRAPHIC,
			OP_LESS_THAN_OR_EQUAL_GRAPHIC,
			OP_GREATER_THAN_OR_EQUAL_GRAPHIC

if DBCS_PCGEOS
if PZ_PCGEOS
; Pizza operatorTable
operatorTable	wchar	'%',		; Percent/Modulo
			'^',		; Exponentiation
			'*',		; Multiplication
			'/',		; Division
			'+',		; Addition
			'-',		; Subtraction
			'<',		; Less than
			'>',		; Greater than
			'=',		; Equal
			'&',		; String concat
			C_DIVISION_SIGN,	; Division graphic char
			C_NOT_EQUAL_TO, 	; Not equal graphic char
			C_LESS_THAN_OVER_EQUAL_TO, ; Less than or equal graphic character
			C_GREATER_THAN_OVER_EQUAL_TO ; Greater than or equal graphic char
else
; DBCS operationTable
operatorTable	wchar	'%',		; Percent/Modulo
			'^',		; Exponentiation
			'*',		; Multiplication
			'/',		; Division
			'+',		; Addition
			'-',		; Subtraction
			'<',		; Less than
			'>',		; Greater than
			'=',		; Equal
			'&',		; String concat
			C_DIVISION_SIGN,	; Division graphic char
			C_NOT_EQUAL_TO, 	; Not equal graphic char
			C_LESS_THAN_OR_EQUAL_TO, ; Less than or equal graphic character
			C_GREATER_THAN_OR_EQUAL_TO ; Greater than or equal graphic char
endif
else
; SBCS operatorTable
operatorTable	char	'%',		; Percent/Modulo
			'^',		; Exponentiation
			'*',		; Multiplication
			'/',		; Division
			'+',		; Addition
			'-',		; Subtraction
			'<',		; Less than
			'>',		; Greater than
			'=',		; Equal
			'&',		; String concat
			C_DIVISION,	; Division graphic char
			C_NOTEQUAL,	; Not equal graphic char
			C_LESSEQUAL,	; Less than or equal graphic character
			C_GREATEREQUAL	; Greater than or equal graphic char
endif

;------------------------------------------------------------------------------
;
; Tables of function names and identifiers. These tables should match up.
; That is to say, if the n'th entry of the funcIDTable contains FUNCTION_ID_FOO
; then the n'th entry of the funcTable should contain the offset of the text
; of the function named "foo".
;
if PZ_PCGEOS
funcIDTable	FunctionID \
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
			FUNCTION_ID_DB		; PIZZA
else
funcIDTable	FunctionID \
			FUNCTION_ID_ABS,	; Standard
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
			FUNCTION_ID_DEGREES,
			FUNCTION_ID_ERR,
			FUNCTION_ID_EXACT,
			FUNCTION_ID_EXP,
			FUNCTION_ID_FACT,
			FUNCTION_ID_FALSE,
			FUNCTION_ID_FILENAME,
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
			FUNCTION_ID_PAGE,
			FUNCTION_ID_PAGES,
			FUNCTION_ID_PI,
			FUNCTION_ID_PMT,
			FUNCTION_ID_PRODUCT,
			FUNCTION_ID_PROPER,
			FUNCTION_ID_PV,
			FUNCTION_ID_RADIANS,
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
			FUNCTION_ID_YEAR
endif

;
; The following is a list of functions which should not be evaluated unless
; they are being displayed.
;
displayOnlyTable FunctionID \
			FUNCTION_ID_FILENAME,
			FUNCTION_ID_PAGE,
			FUNCTION_ID_PAGES

if PZ_PCGEOS
funcTable	nptr	offset dgroup:absName,
			offset dgroup:acosName,
			offset dgroup:acoshName,
			offset dgroup:andName,
			offset dgroup:asinName,
			offset dgroup:asinhName,
			offset dgroup:atanName,
			offset dgroup:atan2Name,
			offset dgroup:atanhName,
			offset dgroup:avgName,
			offset dgroup:charName,
			offset dgroup:chooseName,
			offset dgroup:cleanName,
			offset dgroup:codeName,
			offset dgroup:colsName,
			offset dgroup:cosName,
			offset dgroup:coshName,
			offset dgroup:countName,
			offset dgroup:ctermName,
			offset dgroup:dateName,
			offset dgroup:datevalueName,
			offset dgroup:dayName,
			offset dgroup:ddbName,
			offset dgroup:errName,
			offset dgroup:exactName,
			offset dgroup:expName,
			offset dgroup:factName,
			offset dgroup:falseName,
			offset dgroup:findName,
			offset dgroup:fvName,
			offset dgroup:hlookupName,
			offset dgroup:hourName,
			offset dgroup:ifName,
			offset dgroup:indexName,
			offset dgroup:intName,
			offset dgroup:irrName,
			offset dgroup:iserrName,
			offset dgroup:isnumberName,
			offset dgroup:isstringName,
			offset dgroup:leftName,
			offset dgroup:lengthName,
			offset dgroup:lnName,
			offset dgroup:logName,
			offset dgroup:lowerName,
			offset dgroup:maxName,
			offset dgroup:midName,
			offset dgroup:minName,
			offset dgroup:minuteName,
			offset dgroup:modName,
			offset dgroup:monthName,
			offset dgroup:nName,
			offset dgroup:naName,
			offset dgroup:nowName,
			offset dgroup:npvName,
			offset dgroup:orName,
			offset dgroup:piName,
			offset dgroup:pmtName,
			offset dgroup:productName,
			offset dgroup:properName,
			offset dgroup:pvName,
			offset dgroup:randomnName,
			offset dgroup:randomName,
			offset dgroup:rateName,
			offset dgroup:repeatName,
			offset dgroup:replaceName,
			offset dgroup:rightName,
			offset dgroup:roundName,
			offset dgroup:rowsName,
			offset dgroup:secondName,
			offset dgroup:sinName,
			offset dgroup:sinhName,
			offset dgroup:slnName,
			offset dgroup:sqrtName,
			offset dgroup:stdName,
			offset dgroup:stdpName,
			offset dgroup:stringName,
			offset dgroup:sumName,
			offset dgroup:sydName,
			offset dgroup:tanName,
			offset dgroup:tanhName,
			offset dgroup:termName,
			offset dgroup:timeName,
			offset dgroup:timevalueName,
			offset dgroup:todayName,
			offset dgroup:trimName,
			offset dgroup:trueName,
			offset dgroup:truncName,
			offset dgroup:upperName,
			offset dgroup:valueName,
			offset dgroup:varName,
			offset dgroup:varpName,
			offset dgroup:vlookupName,
			offset dgroup:weekdayName,
			offset dgroup:yearName,
			offset dgroup:fileNameName,
			offset dgroup:pageName,
			offset dgroup:pagesName,
			offset dgroup:degreesName,
			offset dgroup:radiansName,
			offset dgroup:declinebalanceName	; Pizza
else
funcTable	nptr	offset dgroup:absName,			; Standard
			offset dgroup:acosName,
			offset dgroup:acoshName,
			offset dgroup:andName,
			offset dgroup:asinName,
			offset dgroup:asinhName,
			offset dgroup:atanName,
			offset dgroup:atan2Name,
			offset dgroup:atanhName,
			offset dgroup:avgName,
			offset dgroup:charName,
			offset dgroup:chooseName,
			offset dgroup:cleanName,
			offset dgroup:codeName,
			offset dgroup:colsName,
			offset dgroup:cosName,
			offset dgroup:coshName,
			offset dgroup:countName,
			offset dgroup:ctermName,
			offset dgroup:dateName,
			offset dgroup:datevalueName,
			offset dgroup:dayName,
			offset dgroup:ddbName,
			offset dgroup:degreesName,
			offset dgroup:errName,
			offset dgroup:exactName,
			offset dgroup:expName,
			offset dgroup:factName,
			offset dgroup:falseName,
			offset dgroup:fileNameName,
			offset dgroup:findName,
			offset dgroup:fvName,
			offset dgroup:hlookupName,
			offset dgroup:hourName,
			offset dgroup:ifName,
			offset dgroup:indexName,
			offset dgroup:intName,
			offset dgroup:irrName,
			offset dgroup:iserrName,
			offset dgroup:isnumberName,
			offset dgroup:isstringName,
			offset dgroup:leftName,
			offset dgroup:lengthName,
			offset dgroup:lnName,
			offset dgroup:logName,
			offset dgroup:lowerName,
			offset dgroup:maxName,
			offset dgroup:midName,
			offset dgroup:minName,
			offset dgroup:minuteName,
			offset dgroup:modName,
			offset dgroup:monthName,
			offset dgroup:nName,
			offset dgroup:naName,
			offset dgroup:nowName,
			offset dgroup:npvName,
			offset dgroup:orName,
			offset dgroup:pageName,
			offset dgroup:pagesName,
			offset dgroup:piName,
			offset dgroup:pmtName,
			offset dgroup:productName,
			offset dgroup:properName,
			offset dgroup:pvName,
			offset dgroup:radiansName,
			offset dgroup:randomnName,
			offset dgroup:randomName,
			offset dgroup:rateName,
			offset dgroup:repeatName,
			offset dgroup:replaceName,
			offset dgroup:rightName,
			offset dgroup:roundName,
			offset dgroup:rowsName,
			offset dgroup:secondName,
			offset dgroup:sinName,
			offset dgroup:sinhName,
			offset dgroup:slnName,
			offset dgroup:sqrtName,
			offset dgroup:stdName,
			offset dgroup:stdpName,
			offset dgroup:stringName,
			offset dgroup:sumName,
			offset dgroup:sydName,
			offset dgroup:tanName,
			offset dgroup:tanhName,
			offset dgroup:termName,
			offset dgroup:timeName,
			offset dgroup:timevalueName,
			offset dgroup:todayName,
			offset dgroup:trimName,
			offset dgroup:trueName,
			offset dgroup:truncName,
			offset dgroup:upperName,
			offset dgroup:valueName,
			offset dgroup:varName,
			offset dgroup:varpName,
			offset dgroup:vlookupName,
			offset dgroup:weekdayName,
			offset dgroup:yearName
endif

CheckHack <(length funcIDTable) eq (length funcTable)>

;
; One entry for each name referenced in the funcTable. The length of the
; function name should be stored immediately before the text of the function
; name.
;
absName		byte	3, "ABS"
acosName	byte	4, "ACOS"
acoshName	byte	5, "ACOSH"
andName		byte	3, "AND"
asinName	byte	4, "ASIN"
asinhName	byte	5, "ASINH"
atanName	byte	4, "ATAN"
atan2Name	byte	5, "ATAN2"
atanhName	byte	5, "ATANH"
avgName		byte	3, "AVG"
charName	byte	4, "CHAR"
chooseName	byte	6, "CHOOSE"
cleanName	byte	5, "CLEAN"
codeName	byte	4, "CODE"
colsName	byte	4, "COLS"
cosName		byte	3, "COS"
coshName	byte	4, "COSH"
countName	byte	5, "COUNT"
ctermName	byte	5, "CTERM"
dateName	byte	4, "DATE"
datevalueName	byte	9, "DATEVALUE"
dayName		byte	3, "DAY"
ddbName		byte	3, "DDB"
errName		byte	3, "ERR"
exactName	byte	5, "EXACT"
expName		byte	3, "EXP"
factName	byte	4, "FACT"
falseName	byte	5, "FALSE"
findName	byte	4, "FIND"
fvName		byte	2, "FV"
hlookupName	byte	7, "HLOOKUP"
hourName	byte	4, "HOUR"
ifName		byte	2, "IF"
indexName	byte	5, "INDEX"
intName		byte	3, "INT"
irrName		byte	3, "IRR"
iserrName	byte	5, "ISERR"
isnumberName	byte	8, "ISNUMBER"
isstringName	byte	8, "ISSTRING"
leftName	byte	4, "LEFT"
lengthName	byte	6, "LENGTH"
lnName		byte	2, "LN"
logName		byte	3, "LOG"
lowerName	byte	5, "LOWER"
maxName		byte	3, "MAX"
midName		byte	3, "MID"
minName		byte	3, "MIN"
minuteName	byte	6, "MINUTE"
modName		byte	3, "MOD"
monthName	byte	5, "MONTH"
nName		byte	1, "N"
naName		byte	2, "NA"
nowName		byte	3, "NOW"
npvName		byte	3, "NPV"
orName		byte	2, "OR"
piName		byte	2, "PI"
pmtName		byte	3, "PMT"
productName	byte	7, "PRODUCT"
properName	byte	6, "PROPER"
pvName		byte	2, "PV"
randomnName	byte	7, "RANDOMN"
randomName	byte	6, "RANDOM"
rateName	byte	4, "RATE"
repeatName	byte	6, "REPEAT"
replaceName	byte	7, "REPLACE"
rightName	byte	5, "RIGHT"
roundName	byte	5, "ROUND"
rowsName	byte	4, "ROWS"
secondName	byte	6, "SECOND"
sinName		byte	3, "SIN"
sinhName	byte	4, "SINH"
slnName		byte	3, "SLN"
sqrtName	byte	4, "SQRT"
stdName		byte	3, "STD"
stdpName	byte	4, "STDP"
stringName	byte	6, "STRING"
sumName		byte	3, "SUM"
sydName		byte	3, "SYD"
tanName		byte	3, "TAN"
tanhName	byte	4, "TANH"
termName	byte	4, "TERM"
timeName	byte	4, "TIME"
timevalueName	byte	9, "TIMEVALUE"
todayName	byte	5, "TODAY"
trimName	byte	4, "TRIM"
trueName	byte	4, "TRUE"
truncName	byte	5, "TRUNC"
upperName	byte	5, "UPPER"
valueName	byte	5, "VALUE"
varName		byte	3, "VAR"
varpName	byte	4, "VARP"
vlookupName	byte	7, "VLOOKUP"
weekdayName	byte	7, "WEEKDAY"
yearName	byte	4, "YEAR"
fileNameName	byte	8, "FILENAME"
pageName	byte	4, "PAGE"
pagesName	byte	5, "PAGES"
degreesName	byte	7, "DEGREES"
radiansName	byte	7, "RADIANS"
PZ < declinebalanceName  byte  2,"DB"				>

;------------------------------------------------------------------------------
;
; A table giving the size of the data associated with each parser token.
;
parserTokenSizeTable	byte	size ParserTokenNumberData,
				size ParserTokenStringData,
				size ParserTokenCellData,
				0,		; END_OF_EXPRESSION
				0,		; OPEN_PAREN
				0,		; CLOSE_PAREN
				size ParserTokenNameData,
				size ParserTokenFunctionData,
				0,		; CLOSE_FUNCTION
				0,		; ARG_END
				size ParserTokenOperatorData

;------------------------------------------------------------------------------
;
; A list of pointers to strings for each operator. Used by the formatting code
; to generate strings for the operators.
;
; This table depends on the order of the operators being defined in the same
; order that these strings are defined.
;
opFormatTable	word	\
	offset	dgroup:RangeSepString,	;RANGE_SEPARATOR

	offset	dgroup:NegString,	;NEGATION
	offset	dgroup:PercString,	;PERCENT

	offset	dgroup:ExpString,	;EXPONENTIATION
	offset	dgroup:MultString,	;MULTIPLICATION
	offset	dgroup:DivString,	;DIVISION
	offset	dgroup:ModString,	;MODULO
	offset	dgroup:AddString,	;ADDITION
	offset	dgroup:SubString,	;SUBTRACTION

	offset	dgroup:EQString,	;EQUAL
	offset	dgroup:NEString,	;NOT_EQUAL
	offset	dgroup:LTString,	;LESS_THAN
	offset	dgroup:GTString,	;GREATER_THAN
	offset	dgroup:LEString,	;LESS_THAN_OR_EQUAL
	offset	dgroup:GEString,	;GREATER_THAN_OR_EQUAL
	offset	dgroup:ConcatString,	;STRING_CONCAT
	offset	dgroup:RangeIntString,	;RANGE_INTERSECTION
	offset	dgroup:NEGraphString,	;NOT_EQUAL_GRAPHIC
	offset	dgroup:DivGraphString,	;DIVISION_GRAPHIC
	offset	dgroup:LEGraphString,	;LESS_THAN_OR_EQUAL_GRAPHIC
	offset	dgroup:GEGraphString	;GREATER_THAN_OR_EQUAL_GRAPHIC

if DBCS_PCGEOS
NEString	wchar	4," <> ";
GEString	wchar	4," >= ";
LEString	wchar	4," <= ";
ExpString	wchar	1,"^";
MultString	wchar	1,"*";
DivString	wchar	1,"/";
AddString	wchar	3," + ";
LTString	wchar	3," < ";
GTString	wchar	3," > ";
EQString	wchar	3," = ";
PercString	wchar	1,"%";
ModString	wchar	3," % ";
SubString	wchar	3," - ";
NegString	wchar	1,"-";
RangeSepString	wchar	1,":";
ConcatString	wchar	3," & ";
RangeIntString	wchar	3," # ";
NEGraphString	wchar	3," ",C_NOT_EQUAL_TO," ";
DivGraphString	wchar	3," ",C_DIVISION_SIGN," ";
if PZ_PCGEOS
LEGraphString	wchar	3," ",C_LESS_THAN_OVER_EQUAL_TO," ";
GEGraphString	wchar	3," ",C_GREATER_THAN_OVER_EQUAL_TO," ";
else
LEGraphString	wchar	3," ",C_LESS_THAN_OR_EQUAL_TO," ";
GEGraphString	wchar	3," ",C_GREATER_THAN_OR_EQUAL_TO," ";
endif
else
NEString	byte	4," <> ";
GEString	byte	4," >= ";
LEString	byte	4," <= ";
ExpString	byte	1,"^";
MultString	byte	1,"*";
DivString	byte	1,"/";
AddString	byte	3," + ";
LTString	byte	3," < ";
GTString	byte	3," > ";
EQString	byte	3," = ";
PercString	byte	1,"%";
ModString	byte	3," % ";
SubString	byte	3," - ";
NegString	byte	1,"-";
RangeSepString	byte	1,":";
ConcatString	byte	3," & ";
RangeIntString	byte	3," # ";
NEGraphString	byte	3," \255 ";	/* C_NOTEQUAL = 0xad 	 */
DivGraphString	byte	3," \326 ";	/* C_DIVISION = 0xd6 	 */
LEGraphString	byte	3," \262 ";	/* C_LESSEQUAL = 0xb2 	 */
GEGraphString	byte	3," \263 ";	/* C_GREATEREQUAL = 0xb3 */
endif

;------------------------------------------------------------------------------
;
; A table defining the precedence of each operator.
; The higher the number, the higher the precedence.
; The reason that there is such a large gap between the precedences is so that
; it will be easier to add new operators later. These new operators can have
; precedences between the existing operators and you won't need to adjust
; the values of the existing operators.
;
opPrecedenceTable	byte	200,		; ":"  Range separator
				170,		; "-"  Unary negation
				170,		; "%"  Unary percent
				140,		; "^"  Exponentiatio
				110,		; "*"  Multiplication
				110,		; "/"  Division
				80,		; "%"  Modulo
				50,		; "+"  Addition
				50,		; "-"  Subtraction
				20,		; "="  Equal
				20,		; "<>" Not equal
				20,		; "<"  Less than
				20,		; ">"  Greater than
				20,		; "<=" Less than or equal
				20,		; ">=" Greater than or equal
				50,		; "&"  String concatenation
				190,		; "#"  Range intersection
				20,		; C_NOTEQUAL Not equal
				110,		; C_DIVISION Division
				20,		; C_LESSEQUAL Less than or equal
				20		; C_GREATEREQUAL > or equal

if DBCS_PCGEOS
decimalSep	wchar	"."
listSep		wchar	","
argEndString	wchar	", "
else
decimalSep	char	"."
listSep		char	","
argEndString	char	", "
endif

idata	ends

;*****************************************************************************

udata	segment

udata	ends

