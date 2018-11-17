
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 10/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial revision

DESCRIPTION:
		
	$Id: exportUtils.asm,v 1.1 97/04/07 11:41:47 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportTranslateName

DESCRIPTION:	Translate the name if possible

CALLED BY:	INTERNAL ()

PASS:		ExportStackFrame
		es:di - entry buffer

RETURN:		carry clear if translation successful
		carry set otherwise

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	code assumes names are 15 chars or less - no error checking is done...
	yet

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

ExportTranslateName	proc	near	uses	ax,di
	locals	local	ExportStackFrame
	.enter	inherit near

if 0
	add	di, es:[di].NLE_textLength
	add	di, size NameListEntry		; es:di <- definition

	;
	; check allowable definition
	;
	cmp	{byte} es:[di], PARSER_TOKEN_CELL
	jne	nope

	inc	di				; skip PARSER_TOKEN_CELL
	mov	ax, es:[di].CR_row
	xor	ax, ABS_REL_REF_BIT_MASK	; flip abs/rel reference bit
	mov	locals.ESF_data + offset LN_range.LR_startRow, ax

	mov	ax, es:[di].CR_column
	xor	ax, ABS_REL_REF_BIT_MASK	; flip abs/rel reference bit
	mov	locals.ESF_data + offset LN_range.LR_startCol, ax

	add	di, cs:parserTokenSizeTable+PARSER_TOKEN_CELL
	cmp	{byte} es:[di], PARSER_TOKEN_OPERATOR
	jne	nope

	inc	di				; skip PARSER_TOKEN_OPERATOR
	cmp	{byte} es:[di], OP_RANGE_SEPARATOR
	jne	nope

	add	di, cs:parserTokenSizeTable+PARSER_TOKEN_OPERATOR
	cmp	{byte} es:[di], PARSER_TOKEN_CELL
	jne	nope

	inc	di				; skip PARSER_TOKEN_CELL
	mov	ax, es:[di].CR_row
	xor	ax, ABS_REL_REF_BIT_MASK	; flip abs/rel reference bit
	mov	locals.ESF_data + offset LN_range.LR_endRow, ax

	mov	ax, es:[di].CR_column
	xor	ax, ABS_REL_REF_BIT_MASK	; flip abs/rel reference bit
	mov	locals.ESF_data + offset LN_range.LR_endCol, ax

	;
	; confirm end of expression
	;
	add	di, cs:parserTokenSizeTable+PARSER_TOKEN_CELL
	cmp	{byte} es:[di], PARSER_TOKEN_END_OF_EXPRESSION
	jne	nope

	;
	; translate name
	; copy 1st 16 chars for now...
	;
	push	cx,ds,si,es
	segmov	ds, es, si			; ds:si <- NameListEntry
	lea	si, locals.ESF_entryBuf
	mov	cx, ds:[si].NLE_textLength	; cx <- text length
	add	si, size NameListEntry		; ds:si <- name text

	lea	di, locals.ESF_data + offset LN_name	; es:di <- name text
	rep	movsb
	clr	al				; al <- null
	stosb					; terminate
	pop	cx,ds,si,es

	clc
	jmp	short done

nope:
	stc

done:
endif
	.leave
	ret
ExportTranslateName	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ExportTranslateFormat

DESCRIPTION:	Performs a best match translation of the GeoCalc format.

CALLED BY:	INTERNAL ()

PASS:		ax - GeoCalc format

RETURN:		al - Lotus format

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	right now, user-defined and time formats get mapped to GENERAL

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

if 0
ExportTranslateFormat	proc	near	uses	bx,dx,ds,si
	.enter
	;
	; deal with dates and times seperately
	;
	segmov	ds, cs				; ds <- cs
	or	ax, mask FFDT_DATE_TIME_OP
	jne	dateTimeOp

	and	ax, mask FFDT_FORMAT		; isolate format bits

	;
	; deal with user defined formats seperately
	;
	or	ax, FORMAT_ID_PREDEF
	je	userDefFormat

	;-----------------------------------------------------------------------
	; pre-defined format

	;
	; get 0 based offset and read translation off of a lookup table
	;
	and	ax, not FORMAT_ID_PREDEF	; clear pre-def bit
	clr	dx
	mov	bx, size FormatParams
	div	bx				; ax <- 0 based offset
	mov	si, offset ExportTranslateFormatTable

	cmp	ax, NUM_PRE_DEF_FORMATS
	jb	readTrans

readTrans:
	mov	al, ds:[si][bx]
	jmp	short done

userDefFormat:
	;-----------------------------------------------------------------------
	; user-defined format

	mov	al, LOTUS_FORMAT_GENERAL
	jmp	short done

dateTimeOp:
	and	ax, mask FFDT_FORMAT		; isolate format bits
	cmp	ax, DTF_START_TIME_FORMATS
	jae	timeFormat

	;-----------------------------------------------------------------------
	; date format

	mov	si, offset ExportTranslateDateFormatTable
	mov	bx, ax
	mov	al, ds:[si][bx]
	jmp	short done

	;-----------------------------------------------------------------------
	; time format

timeFormat:
	mov	al, LOTUS_FORMAT_GENERAL

done:
	.leave
	ret
ExportTranslateFormat	endp

;
; ??? = dubious
;
ExportTranslateFormatTable	label	byte
	byte	LOTUS_FORMAT_GENERAL
	byte	LOTUS_FORMAT_FIXED
	byte	LOTUS_FORMAT_FIXED		; fixed with commas
	byte	LOTUS_FORMAT_FIXED		; fixed integer
	byte	LOTUS_FORMAT_CURRENCY
	byte	LOTUS_FORMAT_CURRENCY		; currency with commas
	byte	LOTUS_FORMAT_CURRENCY		; currency integer
	byte	LOTUS_FORMAT_PERCENT
	byte	LOTUS_FORMAT_PERCENT		; percentage integer
	byte	LOTUS_FORMAT_GENERAL		; thousands ???
	byte	LOTUS_FORMAT_GENERAL		; millions ???
	byte	LOTUS_FORMAT_SCIENTIFIC

ExportTranslateDateFormatTable	label	byte
	byte	LOTUS_FORMAT_DMY		; long
	byte	LOTUS_FORMAT_DMY		; long condensed
	byte	LOTUS_FORMAT_DMY		; long no weekday
	byte	LOTUS_FORMAT_DMY		; long no weekday condensed
	byte	LOTUS_FORMAT_DMY		; short
	byte	LOTUS_FORMAT_DMY		; zero padded short
	byte	LOTUS_FORMAT_DM			; md long
	byte	LOTUS_FORMAT_DM			; md long no weekday
	byte	LOTUS_FORMAT_DM			; md short
	byte	LOTUS_FORMAT_MY			; my long
	byte	LOTUS_FORMAT_MY			; my short
	byte	LOTUS_FORMAT_MY			; month ???
	byte	LOTUS_FORMAT_DMY		; weekday ???
endif
