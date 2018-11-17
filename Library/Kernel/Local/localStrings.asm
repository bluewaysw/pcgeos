COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		localStrings.asm

AUTHOR:		John Wedgwood, Nov 28, 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/28/90	Initial revision

DESCRIPTION:
	Definitions of string resources.

What follows is a list of the resources and what is contained in each:
	MonthNames, 24 chunks:
		- First 12 chunks are long names of each month.
		- Second 12 chunks are abbreviations for each month.
	DaySuffixes, 31 chunks:
		- The suffixes for each day of the month.
		  eg: 1  -->>  1st	"st" is the suffix.
	WeekdayNames, 14 chunks:
		- First 7 chunks are long names of each weekday.
		- Second 7 chunks are abbreviations for each weekday.
	AMPMText, 6 chunks:
		- First 2 chunks are "am" and "pm" in lower-case.
		- Second 2 chunks are "am" and "pm" in capitalized.
		- Third 2 chunks are "am" and "pm" in all-caps.
	   The reason for storing the capitalized/up-cased versions of am/pm
	   is so we don't need to use the localization driver to do the
	   capitalization for us.

	FormatStrings, unknown # of chunks:
		- One chunk for each standard date/time format.
		  See the list of DateTimeFormat for more information.

	The order of the strings in the resources is important. The parsing
	code depends on it.

	$Id: localStrings.asm,v 1.1 97/04/05 01:17:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalStrings		segment lmem	LMEM_TYPE_GENERAL

.warn -unref

LocalDefString JanuaryLongName <"January", 0>
	localize "full name for January", MAX_MONTH_LENGTH;
LocalDefString FebruaryLongName <"February", 0>
	localize "full name for February", MAX_MONTH_LENGTH;
LocalDefString MarchLongName <"March", 0>
	localize "full name for March", MAX_MONTH_LENGTH;
LocalDefString AprilLongName <"April", 0>
	localize "full name for April", MAX_MONTH_LENGTH;
LocalDefString MayLongName <"May", 0>
	localize "full name for May", MAX_MONTH_LENGTH;
LocalDefString JuneLongName <"June", 0>
	localize "full name for June", MAX_MONTH_LENGTH;
LocalDefString JulyLongName <"July", 0>
	localize "full name for July", MAX_MONTH_LENGTH;
LocalDefString AugustLongName <"August", 0>
	localize "full name for August", MAX_MONTH_LENGTH;
LocalDefString SeptemberLongName <"September", 0>
	localize "full name for September", MAX_MONTH_LENGTH;
LocalDefString OctoberLongName <"October", 0>
	localize "full name for October", MAX_MONTH_LENGTH;
LocalDefString NovemberLongName	<"November", 0>
	localize "full name for November", MAX_MONTH_LENGTH;
LocalDefString DecemberLongName	<"December", 0>
	localize "full name for December", MAX_MONTH_LENGTH;


LocalDefString JanuaryShortName <"Jan", 0>
	localize "abbreviated name for January", MAX_MONTH_LENGTH;
LocalDefString FebruaryShortName <"Feb", 0>
	localize "abbreviated name for February", MAX_MONTH_LENGTH;
LocalDefString MarchShortName < "Mar", 0>
	localize "abbreviated name for March", MAX_MONTH_LENGTH;
LocalDefString AprilShortName < "Apr", 0>
	localize "abbreviated name for April", MAX_MONTH_LENGTH;
LocalDefString MayShortName < "May", 0>
	localize "abbreviated name for May", MAX_MONTH_LENGTH;
LocalDefString JuneShortName < "Jun", 0>
	localize "abbreviated name for June", MAX_MONTH_LENGTH;
LocalDefString JulyShortName < "Jul", 0>
	localize "abbreviated name for July", MAX_MONTH_LENGTH;
LocalDefString AugustShortName < "Aug", 0>
	localize "abbreviated name for August", MAX_MONTH_LENGTH;
LocalDefString SeptemberShortName <"Sep", 0>
	localize "abbreviated name for September", MAX_MONTH_LENGTH;
LocalDefString OctoberShortName <"Oct", 0>
	localize "abbreviated name for October", MAX_MONTH_LENGTH;
LocalDefString NovemberShortName <"Nov", 0>
	localize "abbreviated name for November", MAX_MONTH_LENGTH;
LocalDefString DecemberShortName <"Dec", 0>
	localize "abbreviated name for December", MAX_MONTH_LENGTH;

;-------------------------------------------

LocalDefString Suffix_1 <"st", 0>
	localize "suffix for ordinal 1 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_2 <"nd", 0>
	localize "suffix for ordinal 2 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_3 <"rd", 0>
	localize "suffix for ordinal 3 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_4 <"th", 0>
	localize "suffix for ordinal 4 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_5 <"th", 0>
	localize "suffix for ordinal 5 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_6 <"th", 0>
	localize "suffix for ordinal 6 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_7 <"th", 0>
	localize "suffix for ordinal 7 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_8 <"th", 0>
	localize "suffix for ordinal 8 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_9 <"th", 0>
	localize "suffix for ordinal 9 used in dates", MAX_DAY_LENGTH-2;

LocalDefString Suffix_10 <"th", 0>
	localize "suffix for ordinal 10 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_11 <"th", 0>
	localize "suffix for ordinal 11 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_12 <"th", 0>
	localize "suffix for ordinal 12 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_13 <"th", 0>
	localize "suffix for ordinal 13 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_14 <"th", 0>
	localize "suffix for ordinal 14 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_15 <"th", 0>
	localize "suffix for ordinal 15 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_16 <"th", 0>
	localize "suffix for ordinal 16 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_17 <"th", 0>
	localize "suffix for ordinal 17 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_18 <"th", 0>
	localize "suffix for ordinal 18 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_19 <"th", 0>
	localize "suffix for ordinal 19 used in dates", MAX_DAY_LENGTH-2;

LocalDefString Suffix_20 <"th", 0>
	localize "suffix for ordinal 20 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_21 <"st", 0>
	localize "suffix for ordinal 21 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_22 <"nd", 0>
	localize "suffix for ordinal 22 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_23 <"rd", 0>
	localize "suffix for ordinal 23 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_24 <"th", 0>
	localize "suffix for ordinal 24 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_25 <"th", 0>
	localize "suffix for ordinal 25 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_26 <"th", 0>
	localize "suffix for ordinal 26 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_27 <"th", 0>
	localize "suffix for ordinal 27 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_28 <"th", 0>
	localize "suffix for ordinal 28 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_29 <"th", 0>
	localize "suffix for ordinal 29 used in dates", MAX_DAY_LENGTH-2;

LocalDefString Suffix_30 <"th", 0>
	localize "suffix for ordinal 30 used in dates", MAX_DAY_LENGTH-2;
LocalDefString Suffix_31 <"st", 0>
	localize "suffix for ordinal 31 used in dates", MAX_DAY_LENGTH-2;

;-------------------------------------

LocalDefString SundayLongName	 <"Sunday", 0>
	localize "full name for Sunday", MAX_WEEKDAY_LENGTH;
LocalDefString MondayLongName	 <"Monday", 0>
	localize "full name for Monday", MAX_WEEKDAY_LENGTH;
LocalDefString TuesdayLongName	 <"Tuesday", 0>
	localize "full name for Tuesday", MAX_WEEKDAY_LENGTH;
LocalDefString WednesdayLongName <"Wednesday", 0>
	localize "full name for Wednesday", MAX_WEEKDAY_LENGTH;
LocalDefString ThursdayLongName <"Thursday", 0>
	localize "full name for Thursday", MAX_WEEKDAY_LENGTH;
LocalDefString FridayLongName	 <"Friday", 0>
	localize "full name for Friday", MAX_WEEKDAY_LENGTH;
LocalDefString SaturdayLongName <"Saturday", 0>
	localize "full name for Saturday", MAX_WEEKDAY_LENGTH;

LocalDefString SundayShortName	 <"Sun", 0>
	localize "abbreviated name for Sunday", MAX_WEEKDAY_LENGTH;
LocalDefString MondayShortName	 <"Mon", 0>
	localize "abbreviated name for Monday", MAX_WEEKDAY_LENGTH;
LocalDefString TuesdayShortName <"Tue", 0>
	localize "abbreviated name for Tuesday", MAX_WEEKDAY_LENGTH;
LocalDefString WednesdayShortName <"Wed", 0>
	localize "abbreviated name for Wednesday", MAX_WEEKDAY_LENGTH;
LocalDefString ThursdayShortName <"Thu", 0>
	localize "abbreviated name for Thursday", MAX_WEEKDAY_LENGTH;
LocalDefString FridayShortName	 <"Fri", 0>
	localize "abbreviated name for Friday", MAX_WEEKDAY_LENGTH;
LocalDefString SaturdayShortName <"Sat", 0>
	localize "abbreviated name for Saturday", MAX_WEEKDAY_LENGTH;

if PZ_PCGEOS
LocalDefString SundayLongNameJp	<"NichiYoBi", 0>
	localize "full name for Sunday (Japanese)", MAX_WEEKDAY_LENGTH;
LocalDefString MondayLongNameJp	<"GetuYoBi", 0>
	localize "full name for Monday (Japanese)", MAX_WEEKDAY_LENGTH;
LocalDefString TuesdayLongNameJp <"KaYoBi", 0>
	localize "full name for Tuesday (Japanese)", MAX_WEEKDAY_LENGTH;
LocalDefString WednesdayLongNameJp <"SuiYoBi", 0>
	localize "full name for Wednesday (Japanese)", MAX_WEEKDAY_LENGTH;
LocalDefString ThursdayLongNameJp <"MokuYoBi", 0>
	localize "full name for Thursday (Japanese)", MAX_WEEKDAY_LENGTH;
LocalDefString FridayLongNameJp	<"KinYoBi", 0>
	localize "full name for Friday (Japanese)", MAX_WEEKDAY_LENGTH;
LocalDefString SaturdayLongNameJp <"DoYoBi", 0>
	localize "full name for Saturday (Japanese)", MAX_WEEKDAY_LENGTH;

LocalDefString SundayShortNameJp <"(Nichi)", 0>
	localize "abbreviated name for Sunday (Japanese)", MAX_WEEKDAY_LENGTH;
LocalDefString MondayShortNameJp <"(Getu)", 0>
	localize "abbreviated name for Monday (Japanese)", MAX_WEEKDAY_LENGTH;
LocalDefString TuesdayShortNameJp <"(Ka)", 0>
	localize "abbreviated name for Tuesday (Japanese)", MAX_WEEKDAY_LENGTH;
LocalDefString WednesdayShortNameJp <"(Sui)", 0>
	localize "abbreviated name for Wednesday (Japanese)", MAX_WEEKDAY_LENGTH;
LocalDefString ThursdayShortNameJp <"(Moku)", 0>
	localize "abbreviated name for Thursday (Japanese)", MAX_WEEKDAY_LENGTH;
LocalDefString FridayShortNameJp <"(Kin)", 0>
	localize "abbreviated name for Friday (Japanese)", MAX_WEEKDAY_LENGTH;
LocalDefString SaturdayShortNameJp <"(Do)", 0>
	localize "abbreviated name for Saturday (Japanese)", MAX_WEEKDAY_LENGTH;
endif

;-------------------------------------

LocalDefString AMText <"am", 0>
	localize "lowercase suffix for times before noon", 10;
LocalDefString PMText <"pm", 0>
	localize "lowercase suffix for times after noon", 10;

LocalDefString AMCapText <"Am", 0>
	localize "mixed case suffix for times before noon", 10;
LocalDefString PMCapText <"Pm", 0>
	localize "mixed case suffix for times after noon", 10;

LocalDefString AMAllCapsText <"AM", 0>
	localize "uppercase suffix for times before noon", 10;
LocalDefString PMAllCapsText <"PM", 0>
	localize "uppercase suffix for times after noon", 10;

;-------------------------------------

;   These are the default date-time format strings.  They are replaced
;   on startup by any format strings defined in the .ini file by the user.
;   Do not rearrange!


LocalDefString DateLong <"|LW|, |LM| |LD|, |LY|", 0
	localize "long date format (eg. Sunday, March 5th, 1990)  LW=long weekday, LM=long month, LD=long date, LY=long year", DATE_TIME_FORMAT_SIZE;

LocalDefString LongCondensed <"|SW|, |SM| |SD|, |LY|", 0
	localize "condensed long date (eg. Sun, Mar 5, 1990)  SW=short weekday, SM=short month, SD=short date, LY=long year", DATE_TIME_FORMAT_SIZE;

LocalDefString LongNoWeekday <"|LM| |LD|, |LY|", 0
	localize "long date, no weekday format (eg. March 5th, 1990)  LM=long month, LD=long date, LY=long year", DATE_TIME_FORMAT_SIZE;

LocalDefString LongNoWeekdayCondensed <"|SM| |SD|, |LY|", 0
	localize "condensed long date, no weekday format (eg. Mar 5, 1990)  SM=short month, SD=short date, LY=long year", DATE_TIME_FORMAT_SIZE;

LocalDefString DateShort <"|NM|/|SD|/|SY|", 0
	localize "short date format (eg. 3/5/90)  NM=numeric month, SD=short date, SY=short year", DATE_TIME_FORMAT_SIZE;

LocalDefString ZeroPaddedShort <"|ZM|/|ZD|/|SY|", 0
	localize "zero padded short date format (eg. 03/05/90)  ZM=zero padded numeric month, ZD=zero padded short date, SY=short year", DATE_TIME_FORMAT_SIZE;

	;
	; Language Independent Partial Dates
	;
LocalDefString MDD_Long <"|LW|, |LM| |LD|", 0
	localize "long month,day,date format (eg. Sunday, March 5th)  LW=long weekday, LM=long month, LD=long date", DATE_TIME_FORMAT_SIZE;

LocalDefString MD_Long <"|LM| |LD|", 0
	localize "long month,date format (eg. March 5th)  LM=long month, LD=long date", DATE_TIME_FORMAT_SIZE;

LocalDefString MD_Short <"|NM|/|SD|", 0
	localize "short month,date format (eg. 3/5)  NM=numeric month, SD=short date", DATE_TIME_FORMAT_SIZE;



LocalDefString MY_Long <"|LM| |LY|", 0
	localize "long month,year format (eg. March 1990)  LM=long month, LY=long year", DATE_TIME_FORMAT_SIZE;


LocalDefString MY_Short <"|NM|/|SY|", 0
	localize "short month,year format (eg. 3/90)  LM=long month, SY=short year", DATE_TIME_FORMAT_SIZE;




LocalDefString Year <"|LY|", 0
	localize "year only format (eg. 1990)  LY=long year", DATE_TIME_FORMAT_SIZE;

LocalDefString Month <"|LM|", 0
	localize "month only format (eg. March)  LM=long month", DATE_TIME_FORMAT_SIZE;

LocalDefString Day <"|LD|", 0
	localize "date only format (eg. 5th)  LM=long date", DATE_TIME_FORMAT_SIZE;

LocalDefString Weekday <"|LW|", 0
	localize "weekday only format (eg. Monday)  LW=long weekday", DATE_TIME_FORMAT_SIZE;

	;
	; language Independent Times
	;

LocalDefString HMS <"|HH|:|Zm|:|Zs| |AP|", 0
	localize "12-hour hours,minutes,seconds format (eg. 1:05:31 PM)  HH=12 hour, Zm=zero padded minutes, Zs=zero padded seconds, AP=uppercase time suffix", DATE_TIME_FORMAT_SIZE;

LocalDefString HM <"|HH|:|Zm| |AP|", 0
	localize "12-hour hours,minutes format (eg. 1:05 PM)  HH=12 hour, Zm=zero padded minutes, AP=uppercase time suffix", DATE_TIME_FORMAT_SIZE;

LocalDefString H <"|HH| |AP|", 0
	localize "12-hour hours format (eg. 1 PM)  HH=12 hour, AP=uppercase time suffix", DATE_TIME_FORMAT_SIZE;

LocalDefString MS <"|mm|:|Zs|", 0
	localize "minutes,seconds format (eg. 5:31)  mm=minutes, Zs=zero padded seconds", DATE_TIME_FORMAT_SIZE;


	;
	; Explicit 24 Hour formats.
	;
LocalDefString HMS_24Hour <"|hh|:|Zm|:|Zs|", 0
	localize "24-hour hours,minutes,seconds format (eg. 13:05:31)  hh=24 hour, Zm=zero padded minutes, Zs=zero padded seconds", DATE_TIME_FORMAT_SIZE;

LocalDefString HM_24Hour <"|hh|:|Zm|", 0
	localize "24-hour hours,minutes format (eg. 13:05) hh=24 hour, Zm=zero padded minutes", DATE_TIME_FORMAT_SIZE;

;-------------------------------------

	;
	; Boolean currency stuff
	;
LocalDefString symbolBeforeNumber <"1", 0>
	localize "0/1: currency symbol before number (0 = 3.45$  1 = $3.45)", 1, 1;

LocalDefString spaceAroundSymbol <"0", 0>
	localize "0/1: space around currency symbol (0 = $3.45  1 = $ 3.45)", 1, 1;

if DBCS_PCGEOS
 useNegativeSign chunk.wchar "0", 0 
else
 useNegativeSign chunk.char "0", 0 
endif
	localize "0/1: - or () in currency (0 = ($3.45)  1 = -$3.45)", 1, 1;

LocalDefString negativeSignBeforeNumber <"1", 0>
	localize "0/1: - before number in currency (0 = 3.45-  1 = -3.45)", 1, 1;

LocalDefString negativeSignBeforeSymbol <"1", 0>
	localize "0/1: - before currency symbol (0 = $-3.45  1 = -$3.45)", 1, 1;

LocalDefString currencyLeadingZero <"1", 0>
	localize "0/1: leading zero in currency (0 = $.45  1 = $0.45)", 1, 1;

	;
	; Boolean decimal stuff
	;
LocalDefString leadingZero <"1", 0>
	localize "0/1: leading zero in numbers (0 = .45  1= 0.45)", 1, 1;

LocalDefString thousandsSeparator <",", 0>
	localize "character for separator between thousands (eg. 1,234,456)", 1, 1;

	;
	; Decimal & currency stuff
	;
LocalDefString decimalSeparator <".", 0>
	localize "character for decimal point (eg. 3.45)", 1, 1;

LocalDefString listSeparator <",", 0>
	localize "character for list separator -- it must be different than the character for the decimal separator", 1, 1;

LocalDefString currencySymbol <"$", 0>
	localize "string for currency symbol", CURRENCY_SYMBOL_LENGTH-1;

LocalDefString currencyDigits <"2", 0>
	localize "number of digits after decimal point for currency", 1, 1;

LocalDefString decimalDigits <"2", 0>
	localize "number of digits after decimal point for numbers", 1, 1;

if PZ_PCGEOS
LocalDefString measurementType <"1", 0>
	localize "0/1: measurement type (0 = U.S.  1 = metric)", 1, 1;
else
LocalDefString measurementType <"0", 0>
	localize "0/1: measurement type (0 = U.S.  1 = metric)", 1, 1;
endif

;-----------------------------------

LocalDefString DateChars <" 0123456789", 0>
	localize "legal characters used in dates (excluding month & day names)";

LocalDefString TimeChars <" 0123456789AaPpMm", 0>
	localize "legal characters used in times (including suffixes)";

LocalDefString NumChars  <"0123456789+-", 0>
	localize "legal characters used in integer numbers";

;-----------------------------------


if DBCS_PCGEOS
QUOTES_CHUNK_SIZE	=	10

LocalDefString Quotes	<C_APOSTROPHE_QUOTE, C_APOSTROPHE_QUOTE, C_QUOTATION_MARK, C_QUOTATION_MARK, 0>
else
QUOTES_CHUNK_SIZE	=	5

LocalDefString Quotes	<C_QUOTESNGLEFT, C_QUOTESNGRIGHT, C_QUOTEDBLLEFT, C_QUOTEDBLRIGHT, 0>
endif
	localize "characters for single left, single right, double left, and double right quotation marks";

;-----------------------------------

RealDistanceUnit	equ	DU_POINTS_OR_MILLIMETERS

LocalDefString LocalUnitPointString <"pt">
localize "abbreviation for points"

LocalDefString LocalUnitInchString <"in">
localize "abbreviation for inches"

LocalDefString LocalUnitCMString <"cm">
localize "abbreviation for centimeters"

LocalDefString LocalUnitMMString <"mm">
localize "abbreviation for millimeters"

LocalDefString LocalUnitPicaString <"pi">
localize "abbreviation for picas"

LocalDefString LocalUnitEuroPointString <"ep">
localize "abbreviation for European points"

LocalDefString LocalUnitCiceroString <"ci">
localize "abbreviation for Ciceros"

;
; table of chunk handles of each of the strings above.
; DO NOT change the order!!!
;
LocalUnitStringTable	chunk
	lptr	offset LocalUnitPointString
	lptr	offset LocalUnitInchString
	lptr	offset LocalUnitCMString
	lptr	offset LocalUnitMMString
	lptr	offset LocalUnitPicaString
	lptr	offset LocalUnitEuroPointString
	lptr	offset LocalUnitCiceroString
LocalUnitStringTable	endc

				; points
				; inches
				; centimeters
				; millimeters
				; picas
				; european points
				; ciceros

LocalDefString LocalUnitLongStrings <"point", 0>
	localize "this and following strings are the singular form of the full names of points, inches, centimeters, millimeters, picas, european points, and ciceros";
	LocalDefString <"inch", 0>
	LocalDefString <"centimeter", 0>
	LocalDefString <"millimeter", 0>
	LocalDefString <"pica", 0>
	LocalDefString <"european point", 0>
	LocalDefString <"cicero", 0>

LocalDefString LocalUnitLongPluralStrings	<"points", 0>
	localize "this and following strings are the plural form of the full names of points, inches, centimeters, millimeters, picas, european points, and ciceros";
	LocalDefString <"inches", 0>
	LocalDefString <"centimeters", 0>
	LocalDefString <"millimeters", 0>
	LocalDefString <"picas", 0>
	LocalDefString <"european points", 0>
	LocalDefString <"ciceros", 0>
.warn	@unref


LocalStrings	ends
