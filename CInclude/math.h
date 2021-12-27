/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC/GEOS
 * FILE:	math.h
 * AUTHOR:	Anna Lijphart: January, 1992
 *
 * DESCRIPTION:
 *	C version of math.def.
 *
 *	$Id: math.h,v 1.1 97/04/04 15:57:24 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__MATH_H
#define __MATH_H

#define FPSIZE			 	10
#define DECIMAL_EXPONENT_UPPER_LIMIT	4932
#define DECIMAL_EXPONENT_LOWER_LIMIT	(-4932)
#define FACTORIAL_LIMIT			1754
#define DECIMAL_PRECISION 		15
#define SIGN_STR_LEN	 		5
#define PAD_STR_LEN	 		8

#define FP_DEFAULT_STACK_ELEMENTS	25
#define FP_DEFAULT_STACK_SIZE	(FP_DEFAULT_STACK_ELEMENTS*FPSIZE)
#define FP_MIN_STACK_ELEMENTS	5
#define FP_MIN_STACK_SIZE   	(FP_MIN_STACK_ELEMENTS*FPSIZE)

#define	FP_NAN	    	    	0x7fff

#define MAX_DIGITS_FOR_NORMAL_NUMBERS		DECIMAL_PRECISION
#define MAX_CHARS_FOR_COMMAS_IN_NORMAL_NUMBERS	(DECIMAL_PRECISION / 3 + 1)
#define MAX_DIGITS_FOR_HUGE_NUMBERS		64
#define MAX_CHARS_FOR_COMMAS_IN_HUGE_NUMBERS	\
				(MAX_DIGITS_FOR_HUGE_NUMBERS / 3 + 1)
#define MAX_CHARS_FOR_DECIMAL_POINT		1
#define MAX_CHARS_FOR_EXPONENT			6	
#define MAX_CHARS_FOR_PERCENATGE		1	
#define MAX_CHARS_FOR_NULL_TERM			1

#define MAX_CHARS_FOR_FORMAT_STUFF_IN_NORMAL_NUMBERS	 \
	(SIGN_STR_LEN * 2 + \
	 PAD_STR_LEN * 2 + \
	 MAX_CHARS_FOR_COMMAS_IN_NORMAL_NUMBERS + \
	 MAX_CHARS_FOR_DECIMAL_POINT + \
	 MAX_CHARS_FOR_EXPONENT + \
	 MAX_CHARS_FOR_PERCENATGE)

#define MAX_CHARS_FOR_FORMAT_STUFF_IN_HUGE_NUMBERS	 \
	(SIGN_STR_LEN * 2 + \
	 PAD_STR_LEN * 2 + \
	 MAX_CHARS_FOR_COMMAS_IN_HUGE_NUMBERS + \
	 MAX_CHARS_FOR_DECIMAL_POINT + \
	 MAX_CHARS_FOR_EXPONENT + \
	 MAX_CHARS_FOR_PERCENATGE)

#define MAX_CHARS_FOR_NORMAL_NUMBER	 \
	(MAX_DIGITS_FOR_NORMAL_NUMBERS + \
	 DECIMAL_PRECISION + \
	 MAX_CHARS_FOR_FORMAT_STUFF_IN_NORMAL_NUMBERS + \
	 MAX_CHARS_FOR_NULL_TERM)

#define MAX_CHARS_FOR_HUGE_NUMBER	\
	(MAX_DIGITS_FOR_HUGE_NUMBERS + \
	 MAX_CHARS_FOR_FORMAT_STUFF_IN_HUGE_NUMBERS + \
	 MAX_CHARS_FOR_NULL_TERM)


/******************************************************************************
;
;	NOTE!
;	For your buffers, you will need to use one of:
;	    a) FLOAT_TO_ASCII_NORMAL_BUF_LEN
;	    b) FLOAT_TO_ASCII_HUGE_BUF_LEN
;
;	The reason for having these two is as follows:
;	We normally switch formatting from fixed to scientific if the number
;	cannot fit.  Users can choose to override this automatic switching if
;	they use the FFAF_DONT_USE_SCIENTIFIC flag.  If they do this, numbers
;	will be padded with zeros on the right till the result is gotten.
;	Since the result is potentially huge, we still place a limit and
;	switch to scientific despite the request.
;
;	FLOAT_TO_ASCII_NORMAL_BUF_LEN is the size of the buffer that should be
;	passed to FloatFloatToAscii for "normal" operations.  Operations are
;	"normal" if the FFAF_DONT_USE_SCIENTIFIC flag is clear.  Operations
;	are "huge" otherwise.
;
;*****************************************************************************/

#define FLOAT_TO_ASCII_NORMAL_BUF_LEN	\
	(((MAX_CHARS_FOR_NORMAL_NUMBER + 1) / 2) * 2)

#define FLOAT_TO_ASCII_HUGE_BUF_LEN	\
	(((MAX_CHARS_FOR_HUGE_NUMBER + 1) / 2) * 2)

#define YEAR_LENGTH	365
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

#define DATE_NUMBER_MIN		1
#define DATE_NUMBER_MAX		73049
	
/*
 *	FloatExponent	record
 */
typedef WordFlags FloatExponent;
#define	FE_SIGN		0x8000		
#define	FE_EXPONENT	0x7fff

typedef struct {
	word	F_mantissa_wd0;	
	word	F_mantissa_wd1;	
	word	F_mantissa_wd2;	
	word	F_mantissa_wd3;	
	FloatExponent	F_exponent;
} FloatNumStruct;
/*
 * This is just used for C stubs needed to have formal parameters
 * of 64 bits, the mantissa is bits 0-52 and exponent is 53-64
 */
typedef struct {
	word 	IEEE64F_word1;	
	word 	IEEE64F_word2;	
	word 	IEEE64F_word3;	
	word 	IEEE64F_word4;	
} IEEE64FloatNum;

#define FLOAT_EXPONENT(x) (((FloatNumStruct *)x)->F_exponent)

typedef double IEEE64Number;
#ifndef __WATCOM__ /* Watcom does not (yet) support 80bit long doubles */
typedef long double FloatNumber;
typedef long double FloatNum;
#endif /* ifndef __WATCOM__ */

/*
 *	FloatAsciiToFloatFlags	record
 */
typedef ByteFlags FloatAsciiToFloatFlags;
#define	FAF_PUSH_RESULT		0x02
#define	FAF_STORE_NUMBER	0x01

/*
 * FloatFloatToAsciiFormatFlags	record
 */
typedef WordFlags FloatFloatToAsciiFormatFlags;
#define	FFAF_FLOAT_RESERVED			0x8000		
#define	FFAF_FROM_ADDR				0x4000		
#define	FFAF_DONT_USE_SCIENTIFIC		0x0200		
#define	FFAF_SCIENTIFIC				0x0100			
#define	FFAF_PERCENT				0x0080				
#define	FFAF_USE_COMMAS				0x0040			
#define	FFAF_NO_TRAIL_ZEROS			0x0020
#define	FFAF_NO_LEAD_ZERO			0x0010
#define	FFAF_HEADER_PRESENT			0x0008			
#define	FFAF_TRAILER_PRESENT			0x0004			
#define	FFAF_SIGN_CHAR_TO_FOLLOW_HEADER		0x0002	
#define	FFAF_SIGN_CHAR_TO_PRECEDE_TRAILER	0x0001	

typedef	struct {
	FloatFloatToAsciiFormatFlags	formatFlags;
	byte	decimalOffset;	
	byte	totalDigits;	
	byte	decimalLimit;
#ifdef DO_DBCS
	wchar	preNegative[SIGN_STR_LEN+1];
	wchar	postNegative[SIGN_STR_LEN+1]; 
	wchar	prePositive[SIGN_STR_LEN+1]; 
	wchar	postPositive[SIGN_STR_LEN+1]; 
	wchar	header[PAD_STR_LEN+1]; 
	wchar	trailer[PAD_STR_LEN+1]; 
#else
	char	preNegative[SIGN_STR_LEN+1];
	char	postNegative[SIGN_STR_LEN+1]; 
	char	prePositive[SIGN_STR_LEN+1]; 
	char	postPositive[SIGN_STR_LEN+1]; 
	char	header[PAD_STR_LEN+1]; 
	char	trailer[PAD_STR_LEN+1]; 
#endif
	byte	FFTAP_unused;
} FloatFloatToAsciiParams;

typedef struct {
	FloatFloatToAsciiParams	FFA_params;
	word			FFA_startNumber;
	word			FFA_decimalPoint;
	word			FFA_endNumber;
	word			FFA_numChars;
	word			FFA_startExponent;
	word			FFA_bufSize;
	word			FFA_saveDI;
	word			FFA_numSign;
	byte			FFA_startSigCount;
	byte			FFA_sigCount;
	byte			FFA_noMoreSigInfo;
	byte			FFA_startDecCount;
	byte			FFA_decCount;
	word			FFA_decExponent;
	word			FFA_curExponent;
	byte			FFA_useCommas;
	byte			FFA_charsToComma;
#ifdef DO_DBCS
	wchar			FFA_commaChar;
	wchar			FFA_decimalChar;
#else
	char			FFA_commaChar;
	char			FFA_decimalChar;
#endif
} FloatFloatToAsciiData;

/*
 *	FloatFloatToDateTimeFlags	record
 */
typedef WordFlags FloatFloatToDateTimeFlags;
#define	FFDT_DATE_TIME_OP	0x8000	
#define	FFDT_FROM_ADDR		0x4000	
#define	FFDT_FORMAT		0x3fff		

typedef	struct {
	FloatFloatToDateTimeFlags	FFA_dateTimeFlags;
	word	FFA_year;
	byte	FFA_month;
	byte	FFA_day;
	byte	FFA_weekday;
	byte	FFA_hours;
	byte	FFA_minutes;
	byte	FFA_seconds;
} FloatFloatToDateTimeParams;	

typedef struct {
	FloatFloatToDateTimeParams	FFA_dateTimeParams;
} FloatFloatToDateTimeData;

typedef union {
	FloatFloatToAsciiData	FFA_float;
	FloatFloatToDateTimeData	FFA_dateTime;
} FFA_stackFrame;

typedef union {
	FloatFloatToAsciiParams		FFAP_FLOAT;
	FloatFloatToDateTimeParams	FFAP_DATE_TIME;
} FloatFloatToAsciiParams_Union;

/*
 *	RandomGenInitFlags	record
 */
typedef ByteFlags RandomGenInitFlags;
#define	RGIF_USE_SEED		0x80
#define	RGIF_GENERATE_SEED	0x40

#define	FLOAT_ERROR_CODES_ENUM_START	250

typedef ByteEnum FloatErrorType;
#define FLOAT_POS_INFINITY   FLOAT_ERROR_CODES_ENUM_START
#define FLOAT_NEG_INFINITY 1
#define FLOAT_GEN_ERR 2


typedef ByteEnum    FloatStackType;
#define FLOAT_STACK_GROW 0
#define FLOAT_STACK_WRAP 1
#define FLOAT_STACK_ERROR 2

/****************************************************
 	    Format and Format Controller related
*****************************************************/

#define	MAX_FORMATS		10
#define	NUM_NUMBER_FORMATS	12
#define	NUM_DATE_TIME_FORMATS	19
#define	NUM_PRE_DEF_FORMATS	31
#define	FORMAT_NAME_LENGTH	40 
#define	FORMAT_ID_PREDEF	0x8000
#define	FORMAT_ARRAY_HDR_SIG	(('y' << 8) | 'c')
#define	FORMAT_ENTRY_SIG	(('t' << 8) | 'c')
#define	FORMAT_PARAMS_ID	0x63
#define	FORMAT_INFO_STRUC_ID	(('y' << 8) | 'c')

typedef struct {
    word	FAH_signature;
    word	FAH_numFormatEntries;
    word	FAH_numUserDefEntries;
    word	FAH_formatArrayEnd;
} FormatArrayHeader;

/*
 * WARNING!  If you change the size of the FormatParams typedef,
 * be sure to update the enum values in the FormatIdType declaration
 * below.
 */
typedef struct {
    FloatFloatToAsciiParams_Union	FP_params;
#ifdef DO_DBCS
    wchar	FP_formatName[FORMAT_NAME_LENGTH+1];
#else
    char	FP_formatName[FORMAT_NAME_LENGTH+1];
#endif
    word	FP_nameHan;
    word	FP_nameOff;
    word	FP_listEntryNum;
    word	FP_signature;
} FormatParams;

typedef struct {
    FormatParams FE_params;
    word	FE_listEntryNumber;
    byte	FE_used;
    word	FE_sig;
} FormatEntry;

typedef struct {
    word	FIS_signature;
    FileHandle	FIS_userDefFmtArrayFileHan;
    VMBlockHandle FIS_userDefFmtArrayBlkHan;
    word	FIS_childBlk;
    word	FIS_chooseFmtListChunk;
    word	FIS_features;
    byte	FIS_editFlag;
    word	FIS_curSelection;
    word	FIS_curToken;
    FormatParams FIS_curParams;
} FormatInfoStruc;

#ifdef DO_DBCS
typedef enum {
    FORMAT_ID_GENERAL	    	    	    = 0x8000,
    FORMAT_ID_FIXED		    	    = 0x80b4,
    FORMAT_ID_FIXED_WITH_COMMAS	    	    = 0x8168,
    FORMAT_ID_FIXED_INTEGER	    	    = 0x821c,
    FORMAT_ID_CURRENCY		    	    = 0x82d0,
    FORMAT_ID_CURRENCY_WITH_COMMAS 	    = 0x8384,
    FORMAT_ID_CURRENCY_INTEGER  	    = 0x8438,
    FORMAT_ID_PERCENTAGE 	    	    = 0x84ec,
    FORMAT_ID_PERCENTAGE_INTEGER 	    = 0x85a0,
    FORMAT_ID_THOUSANDS 	    	    = 0x8654,
    FORMAT_ID_MILLIONS  	    	    = 0x8708,
    FORMAT_ID_SCIENTIFIC 	    	    = 0x87bc,

    FORMAT_ID_DATE_LONG 	    	    = 0x8870,
    FORMAT_ID_DATE_LONG_CONDENSED 	    = 0x8924,
    FORMAT_ID_DATE_LONG_NO_WKDAY 	    = 0x89d8,
    FORMAT_ID_DATE_LONG_NO_WKDAY_CONDENSED  = 0x8a8c,
    FORMAT_ID_DATE_SHORT 	    	    = 0x8b40,
    FORMAT_ID_DATE_SHORT_ZERO_PADDED        = 0x8bf4,
    FORMAT_ID_DATE_LONG_MD 	    	    = 0x8ca8,
    FORMAT_ID_DATE_LONG_MD_NO_WKDAY         = 0x8d5c,
    FORMAT_ID_DATE_SHORT_MD     	    = 0x8e10,
    FORMAT_ID_DATE_LONG_MY 	    	    = 0x8ec4,
    FORMAT_ID_DATE_SHORT_MY     	    = 0x8f78,
    FORMAT_ID_DATE_YEAR 	    	    = 0x902c,
    FORMAT_ID_DATE_MONTH 	    	    = 0x90e0,
    FORMAT_ID_DATE_DAY  	    	    = 0x9194,
    FORMAT_ID_DATE_WEEKDAY 	    	    = 0x9248,

    FORMAT_ID_TIME_HMS			    = 0x92fc,
    FORMAT_ID_TIME_HM			    = 0x93b0,
    FORMAT_ID_TIME_H			    = 0x9464,
    FORMAT_ID_TIME_MS			    = 0x9518,
    FORMAT_ID_TIME_HMS_24HR		    = 0x95cc,
    FORMAT_ID_TIME_HM_24HR		    = 0x9680,

    FORMAT_ID_INDETERMINATE     	    = 0xffff
} FormatIdType;
#else
typedef enum {
    FORMAT_ID_GENERAL	    	    	    = 0x8000,
    FORMAT_ID_FIXED		    	    = 0x8061,
    FORMAT_ID_FIXED_WITH_COMMAS	    	    = 0x80c2,
    FORMAT_ID_FIXED_INTEGER	    	    = 0x8123,
    FORMAT_ID_CURRENCY		    	    = 0x8184,
    FORMAT_ID_CURRENCY_WITH_COMMAS 	    = 0x81e5,
    FORMAT_ID_CURRENCY_INTEGER  	    = 0x8246,
    FORMAT_ID_PERCENTAGE 	    	    = 0x82a7,
    FORMAT_ID_PERCENTAGE_INTEGER 	    = 0x8308,
    FORMAT_ID_THOUSANDS 	    	    = 0x8369,
    FORMAT_ID_MILLIONS  	    	    = 0x83ca,
    FORMAT_ID_SCIENTIFIC 	    	    = 0x842b,

    FORMAT_ID_DATE_LONG 	    	    = 0x848c,
    FORMAT_ID_DATE_LONG_CONDENSED 	    = 0x84ed,
    FORMAT_ID_DATE_LONG_NO_WKDAY 	    = 0x854e,
    FORMAT_ID_DATE_LONG_NO_WKDAY_CONDENSED  = 0x85af,
    FORMAT_ID_DATE_SHORT 	    	    = 0x8610,
    FORMAT_ID_DATE_SHORT_ZERO_PADDED        = 0x8671,
    FORMAT_ID_DATE_LONG_MD 	    	    = 0x86d2,
    FORMAT_ID_DATE_LONG_MD_NO_WKDAY         = 0x8733,
    FORMAT_ID_DATE_SHORT_MD     	    = 0x8794,
    FORMAT_ID_DATE_LONG_MY 	    	    = 0x87f5,
    FORMAT_ID_DATE_SHORT_MY     	    = 0x8856,
    FORMAT_ID_DATE_YEAR 	    	    = 0x88b7,
    FORMAT_ID_DATE_MONTH 	    	    = 0x8918,
    FORMAT_ID_DATE_DAY  	    	    = 0x8979,
    FORMAT_ID_DATE_WEEKDAY 	    	    = 0x89da,

    FORMAT_ID_TIME_HMS			    = 0x8a3b,
    FORMAT_ID_TIME_HM			    = 0x8a9c,
    FORMAT_ID_TIME_H			    = 0x8afd,
    FORMAT_ID_TIME_MS			    = 0x8b5e,
    FORMAT_ID_TIME_HMS_24HR		    = 0x8bbf,
    FORMAT_ID_TIME_HM_24HR		    = 0x8c20,

    FORMAT_ID_INDETERMINATE     	    = 0xffff
} FormatIdType;
#endif

typedef ByteEnum SpreadsheetFormatError;
#define FLOAT_FORMAT_NO_ERROR			0
#define FLOAT_FORMAT_TOO_MANY_FORMATS		1
#define FLOAT_FORMAT_CANNOT_ALLOC		2

#define	FLOAT_FORMAT_FORMAT_NAME_NOT_FOUND	0x7fff
#define	FLOAT_FORMAT_PARAMS_MATCH		TRUE
#define	FLOAT_FORMAT_PARAMS_DONT_MATCH		FALSE

/****************************************************
 	    Initialization and shutdown routines
*****************************************************/
extern void _pascal FloatInit(word stackSize, FloatStackType stackType);
extern void _pascal FloatExit(void);


/*****************************************************
  	comparison routines
******************************************************/
extern sword _pascal FloatComp(void);
extern sword _pascal FloatCompAndDrop(void);
extern sword _pascal FloatCompESDI(FloatNum *);
extern word _pascal FloatEq0(void);
extern word _pascal FloatLt0(void);
extern word _pascal FloatGt0(void);


/****************************************************
  	    stack manipulation routines
*****************************************************/
extern word _pascal FloatPushNumber(FloatNum *number);
extern word _pascal FloatPopNumber(FloatNum *number);
extern void _pascal FloatRoll(word num);
extern void _pascal FloatRollDown(word num);
extern void _pascal FloatPick(word num);
extern void _pascal FloatSwap(void);
extern void _pascal FloatOver(void);
extern void _pascal FloatSetStackPointer(word newValue);
extern int _pascal FloatGetStackPointer(void);


/***************************************************************
  conversion routines to and from different formats of numbers

  Geos80 : same as standard IEEE 80 bit format floatint point
  Float  : same as Geos80
  IEEE64 : standard 64 bit format floating point
  IEEE32 : standard 32 bit format floating point
  Dword  : 64 bit signed integer
  Word   : 32 bit signed integer
  (to go from FloatToWord just use FloatToDword and take low 32 bits)
****************************************************************/
extern void _pascal FloatGeos80ToIEEE64(double *num);
extern void _pascal FloatGeos80ToIEEE32(float *num);
extern void _pascal FloatIEEE64ToGeos80(double *num);
extern void _pascal FloatIEEE32ToGeos80(float *num);
extern void _pascal FloatDwordToFloat(long num);
extern void _pascal FloatWordToFloat(word num);
extern long _pascal FloatFloatToDword(void);


/******************************************************
  	    useful constants
*******************************************************/
extern void _pascal Float0(void);
extern void _pascal Float1(void);
extern void _pascal FloatMinus1(void);
extern void _pascal FloatMinusPoint5(void);
extern void _pascal FloatPoint5(void);
extern void _pascal Float2(void);
extern void _pascal Float5(void);
extern void _pascal Float10(void);
extern void _pascal Float3600(void);
extern void _pascal Float16384(void);
extern void _pascal Float86400(void);
extern void _pascal FloatPi(void);
extern void _pascal FloatPiDiv2(void);

/********************************************************
  	    miscellaneous math routines
*********************************************************/
extern void _pascal FloatAbs(void);
extern void _pascal FloatAdd(void);
extern void _pascal FloatArcCos(void);
extern void _pascal FloatArcCosh(void);
extern void _pascal FloatArcSin(void);
extern void _pascal FloatArcSinh(void);
extern void _pascal FloatArcTan(void);
extern void _pascal FloatArcTan2(void);
extern void _pascal FloatArcTanh(void);
extern void _pascal FloatCos(void);
extern void _pascal FloatCosh(void);
extern word _pascal FloatDepth(void);
extern void _pascal FloatDIV(void);
extern void _pascal FloatDivide(void);
extern void _pascal FloatDivide2(void);
extern void _pascal FloatDivide10(void);
extern void _pascal FloatDrop(void);
extern void _pascal FloatDup(void);
extern void _pascal FloatExp(void);
extern void _pascal FloatExponential(void);
extern void _pascal FloatFactorial(void);
extern void _pascal FloatFrac(void);
extern void _pascal FloatInt(void);
extern void _pascal FloatIntFrac(void);
extern void _pascal FloatInverse(void);
extern void _pascal FloatLg(void);
extern void _pascal FloatLg10(void);
extern void _pascal FloatLn(void);
extern void _pascal FloatLn1plusX(void);
extern void _pascal FloatLn2(void);
extern void _pascal FloatLn10(void);
extern void _pascal FloatLog(void);
extern void _pascal FloatMax(void);
extern void _pascal FloatMin(void);
extern void _pascal FloatMod(void);
extern void _pascal FloatMultiply(void);
extern void _pascal FloatMultiply2(void);
extern void _pascal FloatMultiply10(void);
extern void _pascal FloatNegate(void);
extern void _pascal FloatRandom(void);
extern void _pascal FloatRandomize(RandomGenInitFlags rgiflag, dword seed);
extern void _pascal FloatRandomN(void);
extern void _pascal FloatRot(void);
extern void _pascal FloatRound(byte numDecimalPlaces);
extern void _pascal FloatSin(void);
extern void _pascal FloatSinh(void);
extern void _pascal FloatSqr(void);
extern void _pascal FloatSqrt(void);
extern void _pascal FloatSqrt2(void);
extern void _pascal FloatSub(void);
extern void _pascal FloatTan(void);
extern void _pascal FloatTanh(void);
extern void _pascal Float10ToTheX(void);
extern void _pascal FloatTrunc(void);
extern void _pascal FloatEpsilon (void);



/********************************************************
  	    number string routines
*********************************************************/
extern Boolean 	/* XXX */
    _pascal FloatAsciiToFloat(word floatAtoFflags, word stringLength, 
				void *string, void *resultLocation);


/******************************************************************************
;
;	NOTE!
;	For your buffers, you will need to use one of:
;	    a) FLOAT_TO_ASCII_NORMAL_BUF_LEN
;	    b) FLOAT_TO_ASCII_HUGE_BUF_LEN
;
;	The reason for having these two is as follows:
;	We normally switch formatting from fixed to scientific if the number
;	cannot fit.  Users can choose to override this automatic switching if
;	they use the FFAF_DONT_USE_SCIENTIFIC flag.  If they do this, numbers
;	will be padded with zeros on the right till the result is gotten.
;	Since the result is potentially huge, we still place a limit and
;	switch to scientific despite the request.
;
;	FLOAT_TO_ASCII_NORMAL_BUF_LEN is the size of the buffer that should be
;	passed to FloatFloatToAscii for "normal" operations.  Operations are
;	"normal" if the FFAF_DONT_USE_SCIENTIFIC flag is clear.  Operations
;	are "huge" otherwise.
;
;*****************************************************************************/
extern word /* XXX */
    _pascal FloatFloatToAscii_StdFormat(char *string, FloatNum *number,
				FloatFloatToAsciiFormatFlags format,
				word numDigits, word numFractionalDigits);
extern word /* XXX */
    _pascal FloatFloatToAscii(FFA_stackFrame *stackFrame, char *resultString, 
				FloatNum *number);

extern word /* XXX */
    _pascal FloatFloatIEEE64ToAscii_StdFormat(char *string, IEEE64FloatNum number,
				FloatFloatToAsciiFormatFlags format,
				word numDigits, word numFractionalDigits);

extern void _pascal FloatTimeNumberGetSeconds(void);
extern word	/*XXX*/
    _pascal FloatStringGetDateNumber(char *dateString);
extern word	/*XXX*/
    _pascal FloatStringGetTimeNumber(char *timeString);
extern byte _pascal FloatGetDaysInMonth(word year, byte month);
extern void _pascal FloatTimeNumberGetMinutes(void);
extern void _pascal FloatTimeNumberGetHour(void);
extern FloatErrorType _pascal FloatGetDateNumber(word year, byte month, byte day);
extern FloatErrorType 
    	_pascal FloatGetTimeNumber(byte hours, byte minutes, byte seconds);
extern void _pascal FloatDateNumberGetWeekday(void);
extern word _pascal FloatDateNumberGetYear(void);
extern void _pascal FloatDateNumberGetMonthAndDay(byte *month, byte *day);
extern word _pascal FloatGetNumDigitsInIntegerPart(void);

extern void _pascal FloatFormatNumber(FormatIdType formatToken,
				      word userDefBlkHan,
				      word userDefFileHan,
				      FloatNum *floatNum,
				      char *resultLocation);


#ifdef __HIGHC__
pragma Alias(Float0, "FLOAT0");
pragma Alias(Float1, "FLOAT1");
pragma Alias(FloatAsciiToFloat, "FLOATASCIITOFLOAT");
pragma Alias(FloatComp, "FLOATCOMP");
pragma Alias(FloatCompAndDrop, "FLOATCOMPANDDROP");
pragma Alias(FloatCompESDI, "FLOATCOMPESDI");
pragma Alias(FloatEq0, "FLOATEQ0");
pragma Alias(FloatExit, "FLOATEXIT");
pragma Alias(FloatFloatIEEE64ToAscii_StdFormat,
	     "FLOATFLOATIEEE64TOASCII_STDFORMAT");
pragma Alias(FloatFloatToAscii, "FLOATFLOATTOASCII");
pragma Alias(FloatFloatToAscii_StdFormat, "FLOATFLOATTOASCII_STDFORMAT");
pragma Alias(FloatInit, "FLOATINIT");
pragma Alias(FloatPopNumber, "FLOATPOPNUMBER");
pragma Alias(FloatPushNumber, "FLOATPUSHNUMBER");
pragma Alias(FloatRound, "FLOATROUND");
pragma Alias(FloatStringGetDateNumber, "FLOATSTRINGGETDATENUMBER");
pragma Alias(FloatStringGetTimeNumber, "FLOATSTRINGGETTIMENUMBER");
pragma Alias(FloatMinus1, "FLOATMINUS1");
pragma Alias(FloatMinusPoint5, "FLOATMINUSPOINT5");
pragma Alias(FloatPoint5, "FLOATPOINT5");
pragma Alias(Float2, "FLOAT2");
pragma Alias(Float5, "FLOAT5");
pragma Alias(Float10, "FLOAT10");
pragma Alias(Float3600, "FLOAT3600");
pragma Alias(Float16384, "FLOAT16384");
pragma Alias(Float86400, "FLOAT86400");
pragma Alias(FloatAbs, "FLOATABS");
pragma Alias(FloatAdd, "FLOATADD");
pragma Alias(FloatArcCos, "FLOATARCCOS");
pragma Alias(FloatArcCosh, "FLOATARCCOSH");
pragma Alias(FloatArcSin, "FLOATARCSIN");
pragma Alias(FloatArcSinh, "FLOATARCSINH");
pragma Alias(FloatArcTan, "FLOATARCTAN");
pragma Alias(FloatArcTan2, "FLOATARCTAN2");
pragma Alias(FloatArcTanh, "FLOATARCTANH");
pragma Alias(FloatCos, "FLOATCOS");
pragma Alias(FloatCosh, "FLOATCOSH");
pragma Alias(FloatDepth, "FLOATDEPTH");
pragma Alias(FloatDIV, "FLOATDIV");
pragma Alias(FloatDivide, "FLOATDIVIDE");
pragma Alias(FloatDivide2, "FLOATDIVIDE2");
pragma Alias(FloatDivide10, "FLOATDIVIDE10");
pragma Alias(FloatDwordToFloat, "FLOATDWORDTOFLOAT");
pragma Alias(FloatWordToFloat, "FLOATWORDTOFLOAT");
pragma Alias(FloatFloatToDword, "FLOATFLOATTODWORD");
pragma Alias(FloatDrop, "FLOATDROP");
pragma Alias(FloatDup, "FLOATDUP");
pragma Alias(FloatEpsilon, "FLOATEPSILON");
pragma Alias(FloatExp, "FLOATEXP");
pragma Alias(FloatExponential, "FLOATEXPONENTIAL");
pragma Alias(FloatFactorial, "FLOATFACTORIAL");
pragma Alias(FloatFrac, "FLOATFRAC");
pragma Alias(FloatGeos80ToIEEE64, "FLOATGEOS80TOIEEE64");
pragma Alias(FloatIEEE64ToGeos80, "FLOATIEEE64TOGEOS80");
pragma Alias(FloatGeos80ToIEEE32, "FLOATGEOS80TOIEEE32");
pragma Alias(FloatIEEE32ToGeos80, "FLOATIEEE32TOGEOS80");
pragma Alias(FloatInt, "FLOATINT");
pragma Alias(FloatIntFrac, "FLOATINTFRAC");
pragma Alias(FloatInverse, "FLOATINVERSE");
pragma Alias(FloatLg, "FLOATLG");
pragma Alias(FloatLg10, "FLOATLG10");
pragma Alias(FloatLn, "FLOATLN");
pragma Alias(FloatLn1plusX, "FLOATLN1PLUSX");
pragma Alias(FloatLn2, "FLOATLN2");
pragma Alias(FloatLn10, "FLOATLN10");
pragma Alias(FloatLog, "FLOATLOG");
pragma Alias(FloatMax, "FLOATMAX");
pragma Alias(FloatMin, "FLOATMIN");
pragma Alias(FloatMod, "FLOATMOD");
pragma Alias(FloatMultiply, "FLOATMULTIPLY");
pragma Alias(FloatMultiply2, "FLOATMULTIPLY2");
pragma Alias(FloatMultiply10, "FLOATMULTIPLY10");
pragma Alias(FloatNegate, "FLOATNEGATE");
pragma Alias(FloatOver, "FLOATOVER");
pragma Alias(FloatPi, "FLOATPI");
pragma Alias(FloatPiDiv2, "FLOATPIDIV2");
pragma Alias(FloatPick, "FLOATPICK");
pragma Alias(FloatRandom, "FLOATRANDOM");
pragma Alias(FloatRandomize, "FLOATRANDOMIZE");
pragma Alias(FloatRot, "FLOATROT");
pragma Alias(FloatSin, "FLOATSIN");
pragma Alias(FloatSinh, "FLOATSINH");
pragma Alias(FloatSqr, "FLOATSQR");
pragma Alias(FloatSqrt, "FLOATSQRT");
pragma Alias(FloatSqrt2, "FLOATSQRT2");
pragma Alias(FloatSub, "FLOATSUB");
pragma Alias(FloatSwap, "FLOATSWAP");
pragma Alias(FloatTan, "FLOATTAN");
pragma Alias(FloatTanh, "FLOATTANH");
pragma Alias(Float10ToTheX, "FLOAT10TOTHEX");
pragma Alias(FloatTrunc, "FLOATTRUNC");
pragma Alias(FloatGetStackPointer, "FLOATGETSTACKPOINTER");
pragma Alias(FloatGetDaysInMonth, "FLOATGETDAYSINMONTH");
pragma Alias(FloatTimeNumberGetHour, "FLOATTIMENUMBERGETHOUR");
pragma Alias(FloatTimeNumberGetMinutes, "FLOATTIMENUMBERGETMINUTES");
pragma Alias(FloatTimeNumberGetSeconds, "FLOATTIMENUMBERGETSECONDS");
pragma Alias(FloatGetDateNumber, "FLOATGETDATENUMBER");
pragma Alias(FloatGetTimeNumber, "FLOATGETTIMENUMBER");
pragma Alias(FloatDateNumberGetYear, "FLOATDATENUMBERGETYEAR");
pragma Alias(FloatDateNumberGetWeekday, "FLOATDATENUMBERGETWEEKDAY");
pragma Alias(FloatDateNumberGetMonthAndDay, "FLOAATDATENUMBERGETMONTHANDDAY");
pragma Alias(FloatGt0, "FLOATGT0");
pragma Alias(FloatLt0, "FLOATLT0");
pragma Alias(FloatSetStackPointer, "FLOATSETSTACKPOINTER");
pragma Alias(FloatRoll, "FLOATROLL");
pragma Alias(FloatRollDown, "FLOATROLLDOWN");
pragma Alias(FloatGetNumDigitsInIntegerPart, "FLOATGETNUMDIGITSININTEGERPART");
pragma Alias(FloatRandomN, "FLOATRANDOMN");
/******************
pragma Alias(FloatGenerateFormatStr, "FLOATGENERATEFORMATSTR");
******************/
pragma Alias(FloatFormatNumber, "FLOATFORMATNUMBER");

#undef abs
#undef labs
extern int _pascal abs(int __i);
extern long   _pascal labs(long);
#define abs(i) (_abs(i))
#define labs(i) (_abs(i))

#endif

typedef struct {double x, y;} complex;

extern double _pascal cabs(complex __c);   /* non-ansi versions of cabs and hypot */
extern double _pascal hypot(double __x, double __y);
extern double _pascal atof(const char *);
extern double _pascal sin(double __x);
extern double _pascal cos(double __x);
extern double _pascal asin(double __x);
extern double _pascal acos(double __x);
extern double _pascal tan(double __x);
extern double _pascal atan(double __x);
extern double _pascal sinh(double __x);
extern double _pascal cosh(double __x);
extern double _pascal tanh(double __x);
extern double _pascal asinh(double __x);
extern double _pascal acosh(double __x);
extern double _pascal atanh(double __x);
extern double _pascal sqrt(double __x);

/* can't use this in .h file */
/*@protominor NDO2000BorlandCMath*/
extern double _pascal pow(double  __x, double __y);
/*@protoreset*/

/* New 3/3/99 */
extern double _pascal floor(double __x);
extern double _pascal log(double __x);
extern double _pascal fabs(double __x);
extern double _pascal exp(double __x);
extern double _pascal frand(void);


extern double _pascal atan2(double __x, double __y);
extern double _pascal fmod(double __x, double __y);
extern double _pascal log10(double __x);
#endif
