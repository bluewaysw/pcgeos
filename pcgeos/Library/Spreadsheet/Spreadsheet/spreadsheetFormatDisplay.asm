
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial revision

DESCRIPTION:
		
	$Id: spreadsheetFormatDisplay.asm,v 1.1 97/04/07 11:14:01 newdeal Exp $

-------------------------------------------------------------------------------@


if 0
global	FormatDisplayNumber:far

idata	segment

FormatPreDefTbl	label	byte

;*******************************************************************************
;	PRE-DEFINED NUMBER FORMAT TABLES
;*******************************************************************************

FormatGeneralTbl	FormatParams <
    < FFAP_FLOAT <
	mask FFAF_NO_TRAIL_ZEROS,
	0,				; decimal offset
	DECIMAL_PRECISION,		; sig limit
	DECIMAL_PRECISION-1,		; decimal limit
	<"-", 0>,			; pre negative
	<0>,				; post negative
	<0>,				; pre positive
	<0>,				; post positive
	<0>,				; header
	<0>				; trailer
      >
    >,
    <"General", 0>			; name
>

FormatFixedTbl		FormatParams <
    < FFAP_FLOAT <
	mask FFAF_DONT_USE_SCIENTIFIC,	; default flags
	0,				; decimal offset
	MAX_DIGITS_FOR_HUGE_NUMBERS,	; sig limit
	2,				; decimal limit
	<"-", 0>,			; pre negative
	<0>,				; post negative
	<0>,				; pre positive
	<0>,				; post positive
	<0>,				; header
	<0>				; trailer
      >
    >,
    <"Fixed", 0>			; name
>

FormatFixedWithCommasTbl		FormatParams <
    < FFAP_FLOAT <
	mask FFAF_USE_COMMAS or \
	mask FFAF_DONT_USE_SCIENTIFIC,	; default flags
	0,				; decimal offset
	MAX_DIGITS_FOR_HUGE_NUMBERS,	; sig limit
	2,				; decimal limit
	<"-", 0>,			; pre negative
	<0>,				; post negative
	<0>,				; pre positive
	<0>,				; post positive
	<0>,				; header
	<0>				; trailer
      >
    >,
    <"Fixed With Commas", 0>		; name
>

FormatFixedIntegerTbl		FormatParams <
    < FFAP_FLOAT <
	mask FFAF_DONT_USE_SCIENTIFIC,	; default flags
	0,				; decimal offset
	MAX_DIGITS_FOR_HUGE_NUMBERS,	; sig limit
	0,				; decimal limit
	<"-", 0>,			; pre negative
	<0>,				; post negative
	<0>,				; pre positive
	<0>,				; post positive
	<0>,				; header
	<0>				; trailer
      >
    >,
    <"Fixed Integer", 0>		; name
>

FormatCurrencyTbl	FormatParams <
    < FFAP_FLOAT <
	mask FFAF_HEADER_PRESENT or \
	mask FFAF_SIGN_CHAR_TO_FOLLOW_HEADER or \
	mask FFAF_DONT_USE_SCIENTIFIC,
	0,				; decimal offset
	MAX_DIGITS_FOR_HUGE_NUMBERS,	; sig limit
	2,				; decimal limit
	<"(", 0>,			; pre negative
	<")", 0>,			; post negative
	<0>,				; pre positive
	<" ", 0>,			; post positive, space so that things
					; line up
	<"$", 0>,			; header
	<0>				; trailer
      >
    >,
    <"Currency", 0>			; name
>

FormatCurrencyWithCommasTbl	FormatParams <
    < FFAP_FLOAT <
	mask FFAF_HEADER_PRESENT or \
	mask FFAF_SIGN_CHAR_TO_FOLLOW_HEADER or \
	mask FFAF_DONT_USE_SCIENTIFIC or \
	mask FFAF_USE_COMMAS,
	0,				; decimal offset
	MAX_DIGITS_FOR_HUGE_NUMBERS,	; sig limit
	2,				; decimal limit
	<"(", 0>,			; pre negative
	<")", 0>,			; post negative
	<0>,				; pre positive
	<" ", 0>,			; post positive, space so that things
					; line up
	<"$", 0>,			; header
	<0>				; trailer
      >
    >,
    <"Currency With Commas", 0>		; name
>

FormatCurrencyIntegerTbl	FormatParams <
    < FFAP_FLOAT <
	mask FFAF_HEADER_PRESENT or \
	mask FFAF_SIGN_CHAR_TO_FOLLOW_HEADER or \
	mask FFAF_DONT_USE_SCIENTIFIC,
	0,				; decimal offset
	MAX_DIGITS_FOR_HUGE_NUMBERS,	; sig limit
	0,				; decimal limit
	<"(", 0>,			; pre negative
	<")", 0>,			; post negative
	<0>,				; pre positive
	<" ", 0>,			; post positive, space so that things
					; line up
	<"$", 0>,			; header
	<0>				; trailer
      >
    >,
    <"Currency Integer", 0>		; name
>

FormatPercentageTbl	FormatParams <
    < FFAP_FLOAT <
	mask FFAF_PERCENT or \
	mask FFAF_DONT_USE_SCIENTIFIC,
	0,				; decimal offset
	MAX_DIGITS_FOR_HUGE_NUMBERS,	; sig limit
	2,				; decimal limit
	<"-", 0>,			; pre negative
	<0>,				; post negative
	<0>,				; pre positive
	<0>,				; post positive
	<0>,				; header
	<0>				; trailer
      >
    >,
    <"Percentage", 0>			; name
>

FormatPercentageIntegerTbl	FormatParams <
    < FFAP_FLOAT <
	mask FFAF_PERCENT or \
	mask FFAF_DONT_USE_SCIENTIFIC,
	0,				; decimal offset
	MAX_DIGITS_FOR_HUGE_NUMBERS,	; sig limit
	0,				; decimal limit
	<"-", 0>,			; pre negative
	<0>,				; post negative
	<0>,				; pre positive
	<0>,				; post positive
	<0>,				; header
	<0>				; trailer
      >
    >,
    <"Percentage Integer", 0>		; name
>

FormatThousandsTbl	FormatParams <
    < FFAP_FLOAT <
	mask FFAF_DONT_USE_SCIENTIFIC,
	-3,				; decimal offset
	MAX_DIGITS_FOR_HUGE_NUMBERS,	; sig limit
	2,				; decimal limit
	<"-", 0>,			; pre negative
	<0>,				; post negative
	<0>,				; pre positive
	<0>,				; post positive
	<0>,				; header
	<0>				; trailer
      >
    >,
    <"Thousands", 0>			; name
>

FormatMillionsTbl	FormatParams <
    < FFAP_FLOAT <
	mask FFAF_DONT_USE_SCIENTIFIC,
	-6,				; decimal offset
	MAX_DIGITS_FOR_HUGE_NUMBERS,	; sig limit
	2,				; decimal limit
	<"-", 0>,			; pre negative
	<0>,				; post negative
	<0>,				; pre positive
	<0>,				; post positive
	<0>,				; header
	<0>				; trailer
      >
    >,
    <"Millions", 0>			; name
>

FormatScientificTbl	FormatParams <
    < FFAP_FLOAT <
	mask FFAF_SCIENTIFIC,		; flags
	0,				; decimal offset
	DECIMAL_PRECISION,		; sig limit
	2,				; decimal limit
	<"-", 0>,			; pre negative
	<0>,				; post negative
	<0>,				; pre positive
	<0>,				; post positive
	<0>,				; header
	<0>				; trailer
      >
    >,
    <"Scientific", 0>			; name
>

;*******************************************************************************
;	PRE_DEFINED DATE AND TIME FORMAT TABLES
;*******************************************************************************

FormatDateLong			FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_LONG
      >
    >,
    <"Date - Long", 0>			;name
>

FormatDateLongCondensed		FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_LONG_CONDENSED
      >
    >,
    <"Date - Long, Condensed", 0>	;name
>

FormatDateLongNoWeekday		FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_LONG_NO_WEEKDAY
      >
    >,
    <"Date - Long, No Weekday", 0>	;name
>

FormatDateLongNoWeekdayCondensed	FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_LONG_NO_WEEKDAY_CONDENSED
      >
    >,
    <"Date - Long, Condensed, No Weekday", 0>	;name
>

FormatDateShort			FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_SHORT
      >
    >,
    <"Date - Short", 0>			;name
>

FormatDateShortZeroPadded	FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_ZERO_PADDED_SHORT
      >
    >,
    <"Date - Short, Zero Padded", 0>	;name
>

FormatDateLongMD		FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_MD_LONG
      >
    >,
    <"Date - Long, Month & Day", 0>	;name
>

FormatDateLongMDNoWeekday	FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_MD_LONG_NO_WEEKDAY
      >
    >,
    <"Date - Long, Month & Day, No Weekday", 0>	;name
>

FormatDateShortMD		FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_MD_SHORT
      >
    >,
    <"Date - Short, Month & Day", 0>	;name
>

FormatDateLongMY		FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_MY_LONG
      >
    >,
    <"Date - Long, Month & Year", 0>	;name
>

FormatDateShortMY		FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_MY_SHORT
      >
    >,
    <"Date - Short, Month & Year", 0>	;name
>

FormatDateMonth			FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_MONTH
      >
    >,
    <"Date - Month", 0>			;name
>

FormatDateWeekday		FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_WEEKDAY
      >
    >,
    <"Date - Weekday", 0>		;name
>

FormatTimeHMS			FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_HMS
      >
    >,
    <"Time - Hour Min Sec", 0>		;name
>

FormatTimeHM			FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_HM
      >
    >,
    <"Time - Hour Min", 0>		;name
>

FormatTimeH			FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_H
      >
    >,
    <"Time - Hour", 0>			;name
>

FormatTimeMS			FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_MS
      >
    >,
    <"Time - Min Sec", 0>		;name
>

FormatTimeHMS_24hr		FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_HMS_24HOUR
      >
    >,
    <"Time - Hour Min Sec 24hr", 0>	;name
>

FormatTimeHM_24hr		FormatParams <
    < FFAP_DATE_TIME <
      mask FFDT_DATE_TIME_OP or DTF_HM_24HOUR
      >
    >,
    <"Time - Hour Min 24hr", 0>		;name
>

FormatPreDefTblEnd	label	byte

ForceRef	FormatGeneralTbl
ForceRef	FormatFixedTbl
ForceRef	FormatFixedWithCommasTbl
ForceRef	FormatFixedIntegerTbl
ForceRef	FormatCurrencyTbl
ForceRef	FormatCurrencyWithCommasTbl
ForceRef	FormatCurrencyIntegerTbl
ForceRef	FormatPercentageTbl
ForceRef	FormatPercentageIntegerTbl
ForceRef	FormatThousandsTbl
ForceRef	FormatMillionsTbl
ForceRef	FormatScientificTbl

ForceRef	FormatDateLong
ForceRef	FormatDateLongCondensed
ForceRef	FormatDateLongNoWeekday
ForceRef	FormatDateLongNoWeekdayCondensed
ForceRef	FormatDateShort
ForceRef	FormatDateShortZeroPadded
ForceRef	FormatDateLongMD
ForceRef	FormatDateLongMDNoWeekday
ForceRef	FormatDateShortMD
ForceRef	FormatDateLongMY
ForceRef	FormatDateShortMY
ForceRef	FormatDateMonth
ForceRef	FormatDateWeekday
ForceRef	FormatTimeHMS
ForceRef	FormatTimeHM
ForceRef	FormatTimeH
ForceRef	FormatTimeMS
ForceRef	FormatTimeHMS_24hr
ForceRef	FormatTimeHM_24hr
idata	ends

DrawCode	segment resource



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatDisplayNumber

DESCRIPTION:	Displays the number using the format token.

CALLED BY:	INTERNAL ()

PASS:		ax - format token
		bx:cx - spreadsheet instance
		ds:si - address of number to display
		es:di - address at which to store result

RETURN:		carry set if the number couldn't be formatted correctly

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	Things hardwired right now:
	    sig limit = DECIMAL_PRECISION
	    format flags will have  mask FFAF_FROM_ADDR

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FormatDisplayNumber	proc	far	uses	bx,cx,dx
	FDN_local	local	FFA_stackFrame
	.enter

	mov	dx, ax
	and	dx, FORMAT_ID_PREDEF
	je	userDef

	call	FormatDisplay_PreDef
	jmp	short doConvert

userDef:
	call	FormatDisplay_UserDef

doConvert:
	or	FDN_local.FFA_params.formatFlags, mask FFAF_FROM_ADDR
	call	FloatFloatToAscii
	jnc	quit
	;
	; The number couldn't be formatted... Copy a fake error.
	;
	mov	{byte} es:[di],   '#'
	mov	{byte} es:[di+1], '!'
	mov	{byte} es:[di+2], 'F'
	mov	{byte} es:[di+3], 'M'
	mov	{byte} es:[di+4], 'T'
	mov	{byte} es:[di+5],  0
quit:
	.leave
	ret
FormatDisplayNumber	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatDisplay_PreDef

DESCRIPTION:	Initialize the FFA_stackFrame with a pre-defined format
		in preparation for a call to FloatFloatToAscii.

CALLED BY:	INTERNAL (FormatDisplayNumber)

PASS:		ax - format token
		ss:bp - FFA_stackFrame

RETURN:		FFA_stackFrame.FFA_params initialized

DESTROYED:	ax,cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FormatDisplay_PreDef	proc	near	uses	ds,si,es,di
	FD_local	local	FFA_stackFrame
	.enter	inherit near

	;
	; get offset into lookup table
	;
	and	ax, not FORMAT_ID_PREDEF	; ax <- 0 based offset
	add	ax, offset FormatPreDefTbl	; ax <- real offset to params
	mov	si, ax

	;
	; see that si is within the lookup table bounds
	;
EC<	cmp	si, offset FormatPreDefTbl >
EC<	ERROR_B FORMAT_BAD_PRE_DEF_TOKEN >
EC<	cmp	si, offset FormatPreDefTblEnd >
EC<	ERROR_AE FORMAT_BAD_PRE_DEF_TOKEN >

	;
	; copy params from lookup table into stack frame
	;
	segmov  ds, dgroup, ax			; ds:si <- lookup table
	segmov	es, ss, ax			; es:di <- stack frame params
	lea	di, FD_local.FFA_params
	mov	cx, size FloatFloatToAsciiParams
	rep	movsb

	.leave
	ret
FormatDisplay_PreDef	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatDisplay_UserDef

DESCRIPTION:	Initialize the FFA_stackFrame with a user defined format
		in preparation for a call to FloatFloatToAscii.

CALLED BY:	INTERNAL (FormatDisplayNumber)

PASS:		ax - format token
		bx:cx - spreadsheet instance
		ss:bp - FFA_stackFrame

RETURN:		FFA_stackFrame.FFA_params initialized

DESTROYED:	ax,bx,cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FormatDisplay_UserDef	proc	near	uses	ds,si,es,di
	FD_local	local	FFA_stackFrame
	.enter	inherit near

	mov	ds, bx				; ds:di <- spreadsheet instance
	mov	di, cx
	mov	cx, ax				; cx <- token

	push	bp
	call	SpreadsheetLockFormatEntryFar	; es:di <- FormatEntry
						; bp - mem handle
						; ax,bx,dx,si destroyed
	mov	bx, bp				; bx <- VM mem handle
	pop	bp				; retrieve stack frame ptr

	segmov	ds, es, si			; ds:si <- FormatEntry
	mov	si, di
	segmov	es, ss, di			; es:di <- stack frame
	lea	di, FD_local.FFA_params
	mov	cx, size FloatFloatToAsciiParams
	rep	movsb				; copy params

	push	bp				; save stack frame ptr
	mov	bp, bx
	call	VMUnlock
	pop	bp				; retrieve stack frame ptr

	.leave
	ret
FormatDisplay_UserDef	endp

DrawCode	ends
endif
