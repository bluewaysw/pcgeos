/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	localize.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines localization structures and routines.
 *
 *	$Id: localize.h,v 1.1 97/04/04 15:57:29 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__LOCALIZE_H
#define __LOCALIZE_H

#include <Ansi/ctype.h>
#include <timedate.h>		/* TimerDateAndTime */
#include <file.h>   	    	/* FileDateAndTime */
#include <sllang.h>

/*
 *	Country codes
 */

typedef enum /* word */ {
    CT_UNITED_STATES=1,
    CT_CANADA,
    CT_UNITED_KINGDOM,
    CT_GERMANY,
    CT_FRANCE,
    CT_SPAIN,
    CT_ITALY,
    CT_DENMARK,
    CT_NETHERLANDS,
} CountryType;

/*
 *      DosToGeosStringStatus
 */

typedef enum /* byte */ {
    DTGSS_SUBSTITUTIONS=1,
    DTGSS_CODE_PAGE_NOT_SUPPORTED,
    DTGSS_CHARACTER_INCOMPLETE,
    DTGSS_INVALID_CHARACTER
} DosToGeosStringStatus;


/* Minimum mappable character (for use with DosCodePage) */

#define MIN_MAP_CHAR 0x80

#define CURRENCY_SYMBOL_LENGTH 	9

/* number formats */

typedef ByteFlags NumberFormatFlags;
#define NFF_LEADING_ZERO	0x01

/* currency formats */

typedef ByteFlags CurrencyFormatFlags;
#define CFF_LEADING_ZERO		0x20
#define CFF_SPACE_AROUND_SYMBOL		0x10
#define CFF_USE_NEGATIVE_SIGN		0x08
#define CFF_SYMBOL_BEFORE_NUMBER	0x04
#define CFF_NEGATIVE_SIGN_BEFORE_NUMBER	0x02
#define CFF_NEGATIVE_SIGN_BEFORE_SYMBOL	0x01

/* measurement system */

typedef ByteEnum MeasurementType;
#define MEASURE_US 0
#define MEASURE_METRIC 1

typedef ByteEnum DistanceUnit;
#define DU_POINTS 0
#define DU_INCHES 1
#define DU_CENTIMETERS 2
#define DU_MILLIMETERS 3
#define DU_PICAS 4
#define DU_EUR_POINTS 5
#define DU_CICEROS 6
#define DU_POINTS_OR_MILLIMETERS 7
#define DU_INCHES_OR_CENTIMETERS 8

#define LOCAL_DISTANCE_BUFFER_SIZE 32

typedef WordFlags LocalDistanceFlags;
#define LDF_FULL_NAMES	    	    0x8000
#define LDF_PRINT_PLURAL_IF_NEEDED  0x4000

/***/

extern word	/* XXX */
    _pascal LocalDistanceToAscii(char *buffer, WWFixedAsDWord value,
				 DistanceUnit distanceUnits,
				 word measurementType,
				 LocalDistanceFlags flags);

/***/

extern WWFixedAsDWord	/* XXX */
    _pascal LocalDistanceFromAscii(const char *buffer, DistanceUnit distanceUnits,
			   MeasurementType measurementType);

/***/

extern void	/* XXX */
    _pascal LocalFixedToAscii(char *buffer, WWFixedAsDWord value, word fracDigits);

/***/

extern WWFixedAsDWord	/* XXX */
    _pascal LocalAsciiToFixed(const char *buffer, char **parseEnd);

/* keyboard map types */

typedef enum /* word */ {
    KEYMAP_US_EXTD=1,
    KEYMAP_US,
    KEYMAP_UK_EXTD,
    KEYMAP_UK,
    KEYMAP_GERMANY_EXTD,
    KEYMAP_GERMANY,
    KEYMAP_SPAIN_EXTD,
    KEYMAP_SPAIN,
    KEYMAP_DENMARK_EXTD,
    KEYMAP_DENMARK,
    KEYMAP_BELGIUM_EXTD,
    KEYMAP_BELGIUM,
    KEYMAP_CANADA_EXTD,
    KEYMAP_CANADA,
    KEYMAP_ITALY_EXTD,
    KEYMAP_ITALY,
    KEYMAP_LATIN_AMERICA_EXTD,
    KEYMAP_LATIN_AMERICA,
    KEYMAP_NETHERLANDS,
    KEYMAP_NETHERLANDS_EXTD,
    KEYMAP_NORWAY_EXTD,
    KEYMAP_NORWAY,
    KEYMAP_PORTUGAL_EXTD,
    KEYMAP_PORTUGAL,
    KEYMAP_SWEDEN_EXTD,
    KEYMAP_SWEDEN,
    KEYMAP_SWISS_FRENCH_EXTD,
    KEYMAP_SWISS_FRENCH,
    KEYMAP_SWISS_GERMAN_EXTD,
    KEYMAP_SWISS_GERMAN,
    KEYMAP_FRANCE_EXTD,
    KEYMAP_FRANCE,
} KeyMapType;

typedef ByteEnum KeyboardType;
#define KT_NOT_EXTD   1
#define KT_EXTD 2
#define KT_BOTH 3

/* DOS code pages */

typedef enum /* word */ {
    CODE_PAGE_CURRENT=0,
    CODE_PAGE_US=437,
    CODE_PAGE_LATIN_1=819,
    CODE_PAGE_MULTILINGUAL=850,
    CODE_PAGE_MULTILINGUAL_EURO=858,
    CODE_PAGE_PORTUGUESE=860,
    CODE_PAGE_CANADIAN_FRENCH=863,
    CODE_PAGE_NORDIC=865,
    CODE_PAGE_JIS_X_0208_SJIS=932,
    CODE_PAGE_GB_2312_EUC=936,
    CODE_PAGE_KS_C_5601_UHC=949,
    CODE_PAGE_BIG_FIVE_BIG_FIVE=950,
    CODE_PAGE_JOHAB_JOHAB=1361,

    /* NOTE: the code page values below do not represent real DOS code pages,
       but instead represent standards related algorithmically to SJIS. */
    CODE_PAGE_JIS_X_0208_EUC_DB=65530,
    CODE_PAGE_JIS_X_0208_EUC=65531,
    CODE_PAGE_JIS_X_0208_DB=65534,
    CODE_PAGE_JIS_X_0208=65535
} DosCodePage;

/* Some commonly used names: */
#define CODE_PAGE_SJIS		CODE_PAGE_JIS_X_0208_SJIS
#define CODE_PAGE_EUC_DB	CODE_PAGE_JIS_X_0208_EUC_DB
#define CODE_PAGE_EUC		CODE_PAGE_JIS_X_0208_EUC
#define CODE_PAGE_JIS_DB	CODE_PAGE_JIS_X_0208_DB
#define CODE_PAGE_JIS		CODE_PAGE_JIS_X_0208


/* Date / Time formatting */

typedef enum /* word */ {
    DTF_LONG,
    DTF_LONG_CONDENSED,
    DTF_LONG_NO_WEEKDAY,
    DTF_LONG_NO_WEEKDAY_CONDENSED,
    DTF_SHORT,
    DTF_ZERO_PADDED_SHORT,
    DTF_MD_LONG,
    DTF_MD_LONG_NO_WEEKDAY,
    DTF_MD_SHORT,
    DTF_MY_LONG,
    DTF_MY_SHORT,
    DTF_YEAR,
    DTF_MONTH,
    DTF_DAY,
    DTF_WEEKDAY,
    DTF_HMS,
    DTF_HM,
    DTF_H,
    DTF_MS,
    DTF_HMS_24HOUR,
    DTF_HM_24HOUR,
} DateTimeFormat;

/* Low level formatting */

#define TOKEN_DELIMITER		'|'

#define TOKEN_TOKEN_DELIMITER	"DD"
						/* Weekday tokens. */
#define TOKEN_LONG_WEEKDAY	"LW"
#define TOKEN_SHORT_WEEKDAY	"SW"
						/* Month tokens. */
#define TOKEN_LONG_MONTH	"LM"
#define TOKEN_SHORT_MONTH	"SM"
#define TOKEN_NUMERIC_MONTH	"NM"
#define TOKEN_ZERO_PADDED_MONTH	"ZM"
#define TOKEN_SPACE_PADDED_MONTH "PM"
						/* Date tokens. */
#define TOKEN_LONG_DATE		"LD"
#define TOKEN_SHORT_DATE	"SD"
#define TOKEN_ZERO_PADDED_DATE	"ZD"
#define TOKEN_SPACE_PADDED_DATE	"PD"
						/* Year tokens. */
#define TOKEN_LONG_YEAR		"LY"
#define TOKEN_SHORT_YEAR	"SY"
						/* 12-Hour tokens. */
#define TOKEN_12HOUR		  "HH"
#define TOKEN_ZERO_PADDED_12HOUR  "ZH"
#define TOKEN_SPACE_PADDED_12HOUR "PH"
						/* 24-Hour tokens. */
#define TOKEN_24HOUR		  "hh"
#define TOKEN_ZERO_PADDED_24HOUR  "Zh"
#define TOKEN_SPACE_PADDED_24HOUR "Ph"
						/* Minute tokens. */
#define TOKEN_MINUTE		  "mm"
#define TOKEN_ZERO_PADDED_MINUTE  "Zm"
#define TOKEN_SPACE_PADDED_MINUTE "Pm"
						/* Second tokens. */
#define TOKEN_SECOND		  "ss"
#define TOKEN_ZERO_PADDED_SECOND  "Zs"
#define TOKEN_SPACE_PADDED_SECOND "Ps"
						/* AM/PM tokens. */
#define TOKEN_AM_PM		"ap"
#define TOKEN_AM_PM_CAP		"Ap"
#define TOKEN_AM_PM_ALL_CAPS	"AP"

/* Maximum sizes */

#define MAX_MONTH_LENGTH	32
#define MAX_DAY_LENGTH		12
#define MAX_YEAR_LENGTH		12
#define MAX_WEEKDAY_LENGTH	32
#define MAX_SEPARATOR_LENGTH	8
#define TOKEN_LENGTH		4

/* Minimum size for buffer for formatted date/time strings */

#define DATE_TIME_BUFFER_SIZE	(MAX_MONTH_LENGTH \
			+ MAX_DAY_LENGTH \
			+ MAX_YEAR_LENGTH \
			+ MAX_WEEKDAY_LENGTH \
			+ MAX_SEPARATOR_LENGTH*5 \
			+ 1 + 1) / 2 * 2

#define DATE_TIME_FORMAT_SIZE	(TOKEN_LENGTH \
			+ TOKEN_LENGTH \
			+ TOKEN_LENGTH \
			+ TOKEN_LENGTH \
			+ (MAX_SEPARATOR_LENGTH*TOKEN_LENGTH*5) \
			+ 1 + 1) / 2 * 2

/***/

extern void	/*XXX*/
    _pascal LocalSetDateTimeFormat(const char *str, DateTimeFormat format);

/***/

extern void	/*XXX*/
    _pascal LocalGetDateTimeFormat(char *str, DateTimeFormat format);

/***/

extern word	/*XXX*/
    _pascal LocalFormatDateTime(char *str, DateTimeFormat format,
			const TimerDateAndTime *dateTime);


/***/

extern word	/*XXX*/
    _pascal LocalFormatFileDateTime(char *str, DateTimeFormat format,
			const FileDateAndTime *dateTime);

/***/

extern Boolean	/*XXX*/
    _pascal LocalParseDateTime(const char *str, DateTimeFormat format,
		       TimerDateAndTime *dateTime);

extern word	/*XXX*/
    _pascal LocalCustomParseDateTime(const char *str, const char *format,
		       TimerDateAndTime *dateTime);

extern word	/*XXX*/
    _pascal LocalCalcDaysInMonth(word year, word month);

/***/

extern void	/*XXX*/
    _pascal LocalUpcaseString(char *str, word size);

/***/

extern void	/*XXX*/
    _pascal LocalDowncaseString(char *str, word size);

/***/

extern sword	/*XXX*/
    _pascal LocalCmpStrings(const char *str1, const char *str2, word strSize);

/***/

extern sword	/*XXX*/
    _pascal LocalCmpStringsNoCase(const char *str1, const char *str2, word strSize);

/***/

extern sword	/*XXX*/
    _pascal LocalCmpStringsNoSpace(const char *str1, const char *str2, word strSize);

/***/

extern sword	/*XXX*/
    _pascal LocalCmpStringsNoSpaceCase(const char *str1, const char *str2, word strSize);

/***/

extern Boolean	/*XXX*/
    _pascal LocalIsSymbol(wchar ch);

/***/

extern Boolean	/*XXX*/
    _pascal LocalIsDateChar(wchar ch);

/***/

extern Boolean	/*XXX*/
    _pascal LocalIsTimeChar(wchar ch);

/***/

extern Boolean	/*XXX*/
    _pascal LocalIsNumChar(wchar ch);

/***/

extern Boolean	/*XXX*/
    _pascal LocalIsDosChar(wchar ch);

/* LocalIs[*] macros for is[*] functions defined in Ansi/ctype.h */

#define LocalIsUpper(ch)  isupper((ch))
#define LocalIsLower(ch)  islower((ch))
#define LocalIsAlpha(ch)  isalpha((ch))
#define LocalIsPunct(ch)  ispunct((ch))
#define LocalIsSpace(ch)  isspace((ch))
#define LocalIsCntrl(ch)  iscntrl((ch))
#define LocalIsDigit(ch)  isdigit((ch))
#define LocalIsXDigit(ch) isxdigit((ch))
#define LocalIsPrint(ch)  isprint((ch))
#define LocalIsGraph(ch)  isgraph((ch))

#ifdef DO_DBCS
/***/

extern Boolean	/*XXX*/
    _pascal LocalDosToGeos(wchar *geosStr, char *dosStr, word *strSize, wchar defaultChar, DosCodePage *codePage, word diskHandle, DosToGeosStringStatus *status, word *backupBytes);

/***/

extern Boolean	/*XXX*/
    _pascal LocalGeosToDos(char *dosStr, wchar *geosStr, word *strSize, wchar defaultChar, DosCodePage *codePage, word diskhandle, DosToGeosStringStatus *status, word *backupBytes);

/***/

#else

/***/

extern Boolean	/*XXX*/
    _pascal LocalDosToGeos(char *str, word strSize, wchar defaultChar);

/***/

extern Boolean	/*XXX*/
    _pascal LocalGeosToDos(char *str, word strSize, wchar defaultChar);

/***/

#endif


typedef struct {
    wchar	frontSingle;
    wchar	endSingle;
    wchar	frontDouble;
    wchar	endDouble;
} LocalQuotes;

extern void	/*XXX*/
    _pascal LocalGetQuotes(LocalQuotes *quotes);

/***/

extern void	/*XXX*/
    _pascal LocalSetQuotes(const LocalQuotes *quotes);

/***/

extern word	/*XXX*/
    _pascal LocalCustomFormatDateTime(char *str, const char *format,
			      const TimerDateAndTime *dateTime);

/***/

typedef struct {
    byte	numberFormatFlags;
    byte	decimalDigits;
    wchar	thousandsSeparator;
    wchar	decimalSeparator;
    wchar	listSeparator;
} LocalNumericFormat;

extern void	/*XXX*/
    _pascal LocalGetNumericFormat(LocalNumericFormat *buf);

/***/

extern void	/*XXX*/
    _pascal LocalSetNumericFormat(const LocalNumericFormat *buf);

/***/

typedef struct {
    byte	currencyFormatFlags;
    byte	currencyDigits;
    wchar	thousandsSeparator;
    wchar	decimalSeparator;
    wchar	listSeparator;
} LocalCurrencyFormat;

extern void	/*XXX*/
    _pascal LocalGetCurrencyFormat(LocalCurrencyFormat *buf, char *symbol);

/***/

extern void	/*XXX*/
    _pascal LocalSetCurrencyFormat(const LocalCurrencyFormat *buf, const char *symbol);

/***/

typedef ByteFlags LocalCmpStringsDosToGeosFlags;
#define LCSDTG_NO_CONVERT_STRING_2	0x02
#define LCSDTGF_NO_CONVERT_STRING_1	0x01

extern sword	/*XXX*/
    _pascal LocalCmpStringsDosToGeos(const char *str1, const char *str2, word strSize,
			     wchar defaultChar,
			     LocalCmpStringsDosToGeosFlags flags);

/***/

extern Boolean /*XXX*/
    _pascal LocalIsCodePageSupported(DosCodePage codePage);

extern Boolean	/*XXX*/
    _pascal LocalCodePageToGeos(char *str, word strSize, DosCodePage codePage,
			wchar defaultChar);

/***/

extern Boolean	/*XXX*/
    _pascal LocalGeosToCodePage(char *str, word strSize, DosCodePage codePage,
			wchar defaultChar);

/***/

extern wchar	/*XXX*/
    _pascal LocalCodePageToGeosChar(wchar ch, DosCodePage codePage, wchar defaultChar);

/***/

extern wchar	/*XXX*/
    _pascal LocalGeosToCodePageChar(wchar ch, DosCodePage codePage, wchar defaultChar);

#ifdef DO_DBCS

/***/

extern Boolean	/*XXX*/
    _pascal LocalDosToGeosChar(wchar *ch, DosCodePage codePage, word diskHandle, DosToGeosStringStatus *status, word *backup);

/***/

extern Boolean	/*XXX*/
    _pascal LocalGeosToDosChar(wchar *ch, DosCodePage codePage, word diskHandle, DosToGeosStringStatus *status);

/***/

#else

/***/

extern wchar	/*XXX*/
    _pascal LocalDosToGeosChar(wchar ch, wchar defaultChar);

/***/

extern wchar	/*XXX*/
    _pascal LocalGeosToDosChar(wchar ch, wchar defaultChar);

/***/

#endif

extern DosCodePage	/*XXX*/
    _pascal LocalGetCodePage(void);

/***/


/*
 * SYNOPSIS:	Set the code page used by the system as the "DOS" code page.
 * 
 * PASS:        DosCodePage dcp - code page number.
 *  
 * RETURNS:     Handle - Handle of selected code page.  Zero if code page not
 *                       known.
 */
extern Handle
    _pascal LocalSetCodePage(DosCodePage dcp);

/***/


extern MeasurementType	/*XXX*/
    _pascal LocalGetMeasurementType(void);

/***/

extern void	/*XXX*/
    _pascal LocalSetMeasurementType(MeasurementType meas);

/***/

extern word	/*XXX*/
    _pascal LocalLexicalValue(wchar ch);

/***/

extern word	/*XXX*/
    _pascal LocalLexicalValueNoCase(wchar ch);

/***/

extern word	/*XXX*/
    _pascal LocalStringSize(const char *str);

/***/

extern word	/*XXX*/
    _pascal LocalStringLength(const char *str);

/***/

extern word	/* StandardLanguage */
    _pascal LocalGetLanguage(void);

/***/

#define GENGO_LONG_NAME_LENGTH	8
#define GENGO_SHORT_NAME_LENGTH	4

/***/

extern Boolean
    _pascal LocalAddGengoName(const char *longGengo, const char *shortGengo,
				word year, word month, word day);

/***/

extern Boolean
    _pascal LocalRemoveGengoName(word year, word month, word day,
					word *errorType);

/***/

typedef struct {
    word	year;
    byte	month;
    byte	date;
    wchar	longName[GENGO_LONG_NAME_LENGTH+1];
    wchar	shortName[GENGO_SHORT_NAME_LENGTH+1];
} GengoNameData;

extern Boolean	/*XXX*/
    _pascal LocalGetGengoInfo(word entryNum, GengoNameData *gengoInfo);

extern void
    _pascal LocalSetTimezone(sword offsetGMT, Boolean useDST);

extern sword
    _pascal LocalGetTimezone(Boolean *useDST);

extern void
    _pascal LocalNormalizeDateTime(TimerDateAndTime *destTDAT,
				   TimerDateAndTime *srcTDAT,
				   sword timezone);

extern sword
    _pascal LocalCompareDateTimes(TimerDateAndTime *timedate1,
				  TimerDateAndTime *timedate2);

extern word
    _pascal LocalCalcDayOfWeek(word year, word month, word day);

#ifdef __HIGHC__
pragma Alias(LocalSetDateTimeFormat, "LOCALSETDATETIMEFORMAT");
pragma Alias(LocalGetDateTimeFormat, "LOCALGETDATETIMEFORMAT");
pragma Alias(LocalFormatDateTime, "LOCALFORMATDATETIME");
pragma Alias(LocalFormatFileDateTime, "LOCALFORMATFILEDATETIME");
pragma Alias(LocalParseDateTime, "LOCALPARSEDATETIME");
pragma Alias(LocalCustomParseDateTime, "LOCALCUSTOMPARSEDATETIME");
pragma Alias(LocalCalcDaysInMonth, "LOCALCALCDAYSINMONTH");
pragma Alias(LocalUpcaseString, "LOCALUPCASESTRING");
pragma Alias(LocalDowncaseString, "LOCALDOWNCASESTRING");
pragma Alias(LocalCmpStrings, "LOCALCMPSTRINGS");
pragma Alias(LocalCmpStringsNoCase, "LOCALCMPSTRINGSNOCASE");
pragma Alias(LocalCmpStringsNoSpace, "LOCALCMPSTRINGSNOSPACE");
pragma Alias(LocalCmpStringsNoSpaceCase, "LOCALCMPSTRINGSNOSPACECASE");
pragma Alias(LocalIsSymbol, "LOCALISSYMBOL");
pragma Alias(LocalIsDateChar, "LOCALISDATECHAR");
pragma Alias(LocalIsTimeChar, "LOCALISTIMECHAR");
pragma Alias(LocalIsNumChar, "LOCALISNUMCHAR");
pragma Alias(LocalIsDosChar, "LOCALISDOSCHAR");
pragma Alias(LocalDosToGeos, "LOCALDOSTOGEOS");
pragma Alias(LocalGeosToDos, "LOCALGEOSTODOS");
pragma Alias(LocalGetQuotes, "LOCALGETQUOTES");
pragma Alias(LocalSetQuotes, "LOCALSETQUOTES");
pragma Alias(LocalCustomFormatDateTime, "LOCALCUSTOMFORMATDATETIME");
pragma Alias(LocalGetNumericFormat, "LOCALGETNUMERICFORMAT");
pragma Alias(LocalSetNumericFormat, "LOCALSETNUMERICFORMAT");
pragma Alias(LocalGetCurrencyFormat, "LOCALGETCURRENCYFORMAT");
pragma Alias(LocalSetCurrencyFormat, "LOCALSETCURRENCYFORMAT");
pragma Alias(LocalCmpStringsDosToGeos, "LOCALCMPSTRINGSDOSTOGEOS");
pragma Alias(LocalIsCodePageSupported, "LOCALISCODEPAGESUPPORTED");
pragma Alias(LocalCodePageToGeos, "LOCALCODEPAGETOGEOS");
pragma Alias(LocalGeosToCodePage, "LOCALGEOSTOCODEPAGE");
pragma Alias(LocalCodePageToGeosChar, "LOCALCODEPAGETOGEOSCHAR");
pragma Alias(LocalGeosToCodePageChar, "LOCALGEOSTOCODEPAGECHAR");
pragma Alias(LocalDosToGeosChar, "LOCALDOSTOGEOSCHAR");
pragma Alias(LocalGeosToDosChar, "LOCALGEOSTODOSCHAR");
pragma Alias(LocalGetCodePage, "LOCALGETCODEPAGE");
pragma Alias(LocalSetCodePage, "LOCALSETCODEPAGE");
pragma Alias(LocalGetMeasurementType, "LOCALGETMEASUREMENTTYPE");
pragma Alias(LocalSetMeasurementType, "LOCALSETMEASUREMENTTYPE");
pragma Alias(LocalLexicalValue, "LOCALLEXICALVALUE");
pragma Alias(LocalLexicalValueNoCase, "LOCALLEXICALVALUENOCASE");
pragma Alias(LocalStringSize, "LOCALSTRINGSIZE");
pragma Alias(LocalStringLength, "LOCALSTRINGLENGTH");
pragma Alias(LocalDistanceToAscii, "LOCALDISTANCETOASCII");
pragma Alias(LocalDistanceFromAscii, "LOCALDISTANCEFROMASCII");
pragma Alias(LocalFixedToAscii, "LOCALFIXEDTOASCII");
pragma Alias(LocalAsciiToFixed, "LOCALASCIITOFIXED");
pragma Alias(LocalGetLanguage, "LOCALGETLANGUAGE");
pragma Alias(LocalAddGengoName, "LOCALADDGENGONAME");
pragma Alias(LocalRemoveGengoName, "LOCALREMOVEGENGONAME");
pragma Alias(LocalGetGengoInfo, "LOCALGETGENGOINFO");
pragma Alias(LocalSetTimezone, "LOCALSETTIMEZONE");
pragma Alias(LocalGetTimezone, "LOCALGETTIMEZONE");
pragma Alias(LocalNormalizeDateTime, "LOCALNORMALIZEDATETIME");
pragma Alias(LocalCompareDateTimes, "LOCALCOMPAREDATETIMESS");
#endif

#endif
