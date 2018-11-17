COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefintlDialog.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/22/93   	Initial version.

DESCRIPTION:
	

	$Id: prefintlDialog.asm,v 1.1 97/04/05 01:39:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TIME_DATE_TEXT_TO_RANGE_OBJ = 2
TIME_DATE_RANGE_TO_TEXT_OBJ = 2


COMMENT @----------------------------------------------------------------------

FUNCTION:	PrefIntlDialogInit

DESCRIPTION:	Handles opening of the formats dialog box.

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/90		Initial version

------------------------------------------------------------------------------@
PrefIntlDialogInit	method dynamic	PrefIntlDialogClass,
				MSG_PREF_INIT
		
		clr	es:formatsChanged		;nothing's changed
	
		mov	si, offset IntlList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock 

		mov_tr	cx, ax
		call	PrefIntlDialogSelectFormat
		call	PrefIntlUpdateCurrent
		ret			
PrefIntlDialogInit	endp
		
			

COMMENT @----------------------------------------------------------------------

ROUTINE:	SetFormatTitle

SYNOPSIS:	Set up a title in our summons.

CALLED BY:	PrefIntlDialogSelectFormat

PASS:		es -- dgroup

RETURN:		nothing



PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 7/90	Initial version

------------------------------------------------------------------------------@

SetFormatTitle	proc	near
	mov	cx, es:formatToEdit		;get the format being used
	mov	si, offset LongItemMkr		;assume long item
	cmp	cx, DTF_LONG			;
	je	setIt
	mov	si, offset ShortItemMkr
	cmp	cx, DTF_SHORT
	je	setIt
	mov	si, offset HMSItemMkr
	cmp	cx, DTF_HMS
	je	setIt
	mov	si, offset CurrencyItemMkr
	cmp	cx, DTF_CURRENCY
	je	setIt
	mov	si, offset NumericItemMkr
	cmp	cx, DTF_DECIMAL
	je	setIt
	mov	si, offset QuotesItemMkr
setIt:	
	mov	cx, si				;pass moniker in cx
	mov	si, offset IntlEditTitle	;glyph to set
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_USE_VIS_MONIKER	;set the title moniker
	call	ObjCallInstanceNoLock
	ret
SetFormatTitle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetIntlEditHelpContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the help context of the edit dialog box

CALLED BY:	PrefIntlDialogSelectFormat

PASS:		es - dgroup

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/26/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

currencyContext	char	"dbCurrency",0
numberContext 	char	"dbNumber",0
quoteContext 	char	"dbQuoteMarks",0
longContext	char	"dbLongDate",0
shortContext	char	"dbShortDate",0
timeContext	char	"dbTime",0

SetIntlEditHelpContext	proc near
		.enter

		mov	cx, es:formatToEdit
		mov	ax, offset longContext
		mov	bx, size longContext
		cmp	cx, DTF_LONG
		je	setIt

		mov	ax, offset shortContext
		mov	bx, size shortContext
		cmp	cx, DTF_SHORT
		je	setIt
		
		mov	ax, offset timeContext
		mov	bx, size timeContext
		cmp	cx, DTF_HMS
		je	setIt
		
		mov	ax, offset currencyContext
		mov	bx, size currencyContext
		cmp	cx, DTF_CURRENCY
		je	setIt
		
		mov	ax, offset numberContext
		mov	bx, size numberContext
		cmp	cx, DTF_DECIMAL
		je	setIt
		
		mov	ax, offset quoteContext
		mov	bx, size quoteContext

setIt:
		mov	dx, size AddVarDataParams
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].AVDP_data.segment, cs
		mov	ss:[bp].AVDP_data.offset, ax
		mov	ss:[bp].AVDP_dataSize, bx
		mov	ss:[bp].AVDP_dataType, ATTR_GEN_HELP_CONTEXT
		
		mov	si, offset IntlEdit
		mov	di, mask MF_CALL or mask MF_STACK
		mov	ax, MSG_META_ADD_VAR_DATA
		call	ObjCallInstanceNoLock
		add	sp, size AddVarDataParams
		
		.leave
		ret
SetIntlEditHelpContext	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupDecimal

SYNOPSIS:	Sets up dialog box for decimal format editing.

CALLED BY:	PrefIntlDialogInit

PASS:		es -- dgroup
		bx     -- handle of ui stuff

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 7/90		Initial version

------------------------------------------------------------------------------@

SetupDecimal	proc	near		uses	bx, cx
	.enter
	mov	si, offset DecimalInteraction
	call	PrefIntlSetUsable		;use this!
	
	call	LocalGetNumericFormat		;see what we get here.
	
	;
	; We need to copy this info into the original value locations.
	; al - leading zero flag, bx - thousands separator,
	; cx - decimal deparator, dx - list separator, ah - decimal digits
	;
	mov	es:originalLeadingZeroFlag, al
if DBCS_PCGEOS
	mov	es:originalDecimalDigits, ah
	clr	ax
	mov	es:originalThousandsSeparator, bx	;store
	mov	es:originalThousandsSeparator+2, ax	;null terminate
	mov	es:originalDecimalSeparator, cx
	mov	es:originalDecimalSeparator+2, ax	;null terminate
	mov	es:originalListSeparator, dx
	mov	es:originalListSeparator+2, ax		;null terminate
else
	clr	al
	mov	es:originalThousandsSeparator, bl	;store
	mov	es:originalThousandsSeparator+1, al	;null terminate
	mov	es:originalDecimalSeparator, cl
	mov	es:originalDecimalSeparator+1, al	;null terminate
	mov	es:originalListSeparator, dl
	mov	es:originalListSeparator+1, al		;null terminate
	mov	es:originalDecimalDigits, ah
endif
	
	call	LocalGetMeasurementType
	mov	es:originalMeasurementType, al		;store measurement type

	;
	; Set current values to original values.
	;
	push	ds
	segmov	ds, es
	mov	si, offset originalLeadingZeroFlag	
	mov	di, offset currentLeadingZeroFlag
	mov	cx, (offset currentLeadingZeroFlag - \
		     offset originalLeadingZeroFlag)	;bytes to copy
	rep	movsb
	pop	ds
	
	;
	; Now set all the appropriate gadgets.
	;
	mov	cl, es:originalDecimalDigits		;get decimal digits
	clr	ch
	mov	si, offset DecimalDigitsValue
	call	PrefIntlSetValue
	
	mov	cl, es:originalLeadingZeroFlag
	mov	si, offset LeadingZeroSpin
	call	PrefIntlSetSpin
	
	mov	cl, es:originalMeasurementType
	mov	si, offset MeasurementSpin
	call	PrefIntlSetSpin
	
	mov	bp, offset currentThousandsSeparator
	mov	si, offset ThousandsSepText
	call	PrefIntlSetText
	
	mov	bp, offset currentDecimalSeparator
	mov	si, offset DecimalSepText
	call	PrefIntlSetText
	
	mov	bp, offset currentListSeparator
	mov	si, offset ListSeparatorText
	call	PrefIntlSetText
	
	call	PrefIntlUpdateCurrent
	.leave
	ret
SetupDecimal	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupCurrency

SYNOPSIS:	Sets up dialog box for currency format editing.

CALLED BY:	PrefIntlDialogInit

PASS:		es -- dgroup
		bx     -- handle of ui stuff

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 7/90		Initial version

------------------------------------------------------------------------------@

SetupCurrency	proc	near		uses	bx, cx
	.enter
	mov	si, offset CurrencyInteraction
	call	PrefIntlSetUsable		

	;
	; Set this so we'll use the correct decimal point.  -cbh 1/25/93
	;
	call	LocalGetNumericFormat			;get decimal point
DBCS <	mov	es:currentDecimalSeparator, cx				>
DBCS <	mov	es:currentDecimalSeparator+2, 0		;null terminate	>
SBCS <	mov	es:currentDecimalSeparator, cl				>
SBCS <	mov	es:currentDecimalSeparator+1, 0		;null terminate	>
	
	mov	di, offset originalCurrencySymbol
	call	LocalGetCurrencyFormat		;see what we get here.
	
	;
	; Load up our local variables.  We already have the currency symbol,
	; we need to set things in registers:  al -- CurrencyFormatFlags,
	; ah - currency digits.
	
	mov	es:originalCurrencyFlags, al
	mov	es:originalCurrencyDigits, ah	;store
	
	;
	; Set current values to original values.
	;
	push	ds
	segmov	ds, es
	mov	si, offset originalCurrencyFlags
	mov	di, offset currentCurrencyFlags
	mov	cx, (offset currentCurrencyFlags - \
		     offset originalCurrencyFlags)	;bytes to copy
	rep	movsb
	pop	ds
	
	;
	; Now set all the appropriate gadgets.
	;
	
	mov	cl, es:originalCurrencyDigits		;get decimal digits
	clr	ch
	mov	si, offset CurrencyDigitsValue
	call	PrefIntlSetValue
	
	mov	bp, offset originalCurrencySymbol
	mov	si, offset SymbolText
	call	PrefIntlSetText
	
	clr	cx					;assume no leading zero
	mov	al, es:[currentCurrencyFlags]
	test	al, mask CFF_LEADING_ZERO
	jz	10$
	inc	cx					;make 1 if leading zero
10$:
	mov	si, offset CurrLeadingZeroSpin
	call	PrefIntlSetSpin
	
	clr	cx					;assume no leading zero
	test	al, mask CFF_SPACE_AROUND_SYMBOL
	jz	20$
	inc	cx					;make 1 if leading zero
20$:
	mov	si, offset SpaceAroundSpin
	call	PrefIntlSetSpin
	
	and	al, mask CFF_USE_NEGATIVE_SIGN or \
		    mask CFF_SYMBOL_BEFORE_NUMBER or \
		    mask CFF_NEGATIVE_SIGN_BEFORE_NUMBER or \
		    mask CFF_NEGATIVE_SIGN_BEFORE_SYMBOL
	call	CurrencyFlagsToOffset			;compute a spin offset
	mov	cl, al
	clr	ch
	mov	si, offset PlacementSpin		
	call	PrefIntlSetSpin				;set our placement spin
	
	call	PrefIntlUpdateCurrent			;update current values
	.leave
	ret
SetupCurrency	endp
		
		


COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupQuotes

SYNOPSIS:	Sets up dialog box for quotes editing.

CALLED BY:	PrefIntlDialogInit

PASS:		es -- dgroup
		ds - segment of UI objects

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 7/90		Initial version

------------------------------------------------------------------------------@

SetupQuotes	proc	near		uses	bx, cx
	.enter
	mov	si, offset QuotesInteraction
	call	PrefIntlSetUsable		
	
	; 
	; Get quotes from localization driver.
	;
	call	LocalGetQuotes			;ax,bx,cx,dx hold quotes
	
if DBCS_PCGEOS
	mov	es:originalSingleLeft, ax
	mov	es:originalSingleRight, bx
	mov	es:originalDoubleLeft, cx
	mov	es:originalDoubleRight, dx
	
	mov	es:currentSingleLeft, ax
	mov	es:currentSingleRight, bx
	mov	es:currentDoubleLeft, cx
	mov	es:currentDoubleRight, dx
	
	;
	; Set our example string so we can display it.
	;
	mov	es:exampleQuoteSingleLeft, ax
	mov	es:exampleQuoteSingleRight, bx
	mov	es:exampleQuoteDoubleLeft, cx
	mov	es:exampleQuoteDoubleRight, dx
else
	mov	es:originalSingleLeft, al
	mov	es:originalSingleRight, bl
	mov	es:originalDoubleLeft, cl
	mov	es:originalDoubleRight, dl
	
	mov	es:currentSingleLeft, al
	mov	es:currentSingleRight, bl
	mov	es:currentDoubleLeft, cl
	mov	es:currentDoubleRight, dl
	
	;
	; Set our example string so we can display it.
	;
	mov	es:exampleQuoteSingleLeft, al
	mov	es:exampleQuoteSingleRight, bl
	mov	es:exampleQuoteDoubleLeft, cl
	mov	es:exampleQuoteDoubleRight, dl
endif
	
	push	dx
	push	cx
	push	bx
	mov	si, offset FirstSingleText
	call	SetTextFromAL			;set single left quote obj
	
	pop	ax
	mov	si, offset LastSingleText
	call	SetTextFromAL			;set single right quote obj
	
	pop	ax				;restore double quotes
	mov	si, offset FirstDoubleText
	call	SetTextFromAL			;set left double quote obj
	
	pop	ax
	mov	si, offset LastDoubleText
	call	SetTextFromAL			;set double right quote obj
	
	call	PrefIntlUpdateCurrent		;update the example
	.leave
	ret
	
SetupQuotes	endp

		


COMMENT @----------------------------------------------------------------------

ROUTINE:	SetTextFromAL

SYNOPSIS:	Sets one of the single character text objects, based on al.

CALLED BY:	SetupQuotes

PASS:		*ds:si -- object to set
		es - dgroup
		al      -- character to use as text in object
				(ax for DBCS)

RETURN:		nothing

DESTROYED:	parseBuffer, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/28/90	Initial version

------------------------------------------------------------------------------@

SetTextFromAL	proc	near

		.enter
if DBCS_PCGEOS
		mov	{wchar}es:parseBuffer, ax	;store character here
		clr	{wchar}es:parseBuffer+2		;null terminate
else
		mov	es:parseBuffer, al		;store character here
		clr	es:parseBuffer+1		;null terminate
endif
		mov	bp, offset parseBuffer		;here's our text
		call	PrefIntlSetText			;set it
		.leave
		ret
SetTextFromAL	endp
			

COMMENT @----------------------------------------------------------------------

ROUTINE:	SetAllSpinsMinMax

SYNOPSIS:	Sets spin minimum and maximum for all the spin gadgets.

CALLED BY:	SetupTimeSpecificStuff, SetupDateSpecificStuff

PASS:		ds -- dgroup
		
RETURN:		nothing

DESTROYED:	ax, dx, di, si, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 7/90		Initial version

------------------------------------------------------------------------------@

SetAllSpinsMinMax	proc	near		
if PZ_PCGEOS	;Koji. Japanese or English spin.
	mov	cx, es:formatToEdit		;see what we're doing
	mov	di, offset shortValueTable
	cmp	cx, DTF_SHORT
	je	setValue			;set Short date formats
	mov	di, offset timeValueTable
	cmp	cx, DTF_HMS
	je	setValue			;set Time formats
EC <	cmp	cx, DTF_LONG						>
EC <	ERROR_NE	-1						>
	mov	di, offset longJapaneseValueTable
	call	GetDateLanguageSelection	;get language selection
	tst	ax				;Japanese?
	jnz	setValue			;if so, set Japanese formats
	mov	di, offset longEnglishValueTable;if not, set English formats
else
	mov	cx, es:formatToEdit		;see what we're doing
	mov	di, offset longValueTable
	cmp	cx, DTF_LONG
	je	setValue
	mov	di, offset shortValueTable
	cmp	cx, DTF_SHORT
	je	setValue
	mov	di, offset timeValueTable
endif
setValue:
	mov	cx, {word} es:[di]			;get max,min from table
	mov	si, offset FormatElement2
	call	SetSpinMinMax
	
	mov	cx, {word} es:[di]+2			;get max,min from table
	mov	si, offset FormatElement4
	call	SetSpinMinMax
	
	mov	cx, {word} es:[di]+4			;get max,min from table
	mov	si, offset FormatElement6
	call	SetSpinMinMax
	
	mov	cx, {word} es:[di]+6			;get max,min from table
	mov	si, offset FormatElement8
	call	SetSpinMinMax
	ret
SetAllSpinsMinMax	endp


if PZ_PCGEOS	;Koji
COMMENT @----------------------------------------------------------------------

ROUTINE:	GetDateLanguageSelection

SYNOPSIS:	Get DateLanguageGroup item selection value

CALLED BY:	INTERANAL

PASS:		ds -- dgroup
		
RETURN:		ax - value
			TRUE	- Japanese
			FALSE	- English

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	koji	9/13/93		Initial version

------------------------------------------------------------------------------@
GetDateLanguageSelection		proc	near
	uses	cx, dx, bp, si
	.enter
	mov	si, offset DateLanguageGroup
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjCallInstanceNoLock
	.leave
	ret
GetDateLanguageSelection		endp
endif




COMMENT @----------------------------------------------------------------------

ROUTINE:	SetSpinMinMax

SYNOPSIS:	Sets spin minimum and maximum.   Also figures out whether to
		set the thing usable or not.  If there's nothing to set, it
		will be set not usable.

CALLED BY:	SetupTimeSpecificStuff, SetupDateSpecificStuff

PASS:		*ds:si -- object
		cl -- minimum
		ch -- maximum

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 7/90		Initial version

------------------------------------------------------------------------------@

SetSpinMinMax	proc	near			
	;
	; Set the thing not usable if min and max are DTT_BLANK.
	;
	mov	ax, MSG_GEN_SET_USABLE	;assume it's cool
	cmp	cl, DTT_BLANK
	jne	10$				;not blank, branch
	cmp	cl, ch				;max is not blank, branch
	jne	10$
	mov	ax, MSG_GEN_SET_NOT_USABLE
10$:
	push	ax
	call	SetIt				;set the thing usable or not
	pop	ax
	push	si
	sub	si, TIME_DATE_TEXT_TO_RANGE_OBJ	;delete preceding text object
	call	SetIt
	pop	si				;back to our range
	
	push	cx
	clr	ch
	mov	ax, MSG_CUSTOM_SPIN_SET_MIN_VALUE
	call	ObjCallInstanceNoLock 

	pop	dx
	mov	cl, dh				
	clr	ch
	mov	ax, MSG_CUSTOM_SPIN_SET_MAX_VALUE
	call	ObjCallInstanceNoLock
	ret
SetSpinMinMax	endp

	

COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupTimeDateCommon

SYNOPSIS:	Sets up time and date editing dialog box stuff.

CALLED BY:	PrefIntlDialogInit

PASS:		es -- dgroup
		bx     -- handle of ui stuff

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 7/90		Initial version

------------------------------------------------------------------------------@

SetupTimeDateCommon	proc	near
if PZ_PCGEOS	;Koji
	call	GetDateLanguageFromInitFile	;get Language value from .ini
	;
	; set date language selection value
	;
	mov_tr	cx, ax				;cx <- Language selection value
	mov	si, offset DateLanguageGroup	;ds:si - object to set
	clr	dx				;mark determine
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjCallInstanceNoLock		;set value to object

	call	UsableDateLanguage		;usable or unusable

endif
	call	SetAllSpinsMinMax		;set appropriate mins and maxs
	mov	si, offset TimeDateInteraction
	call	PrefIntlSetUsable		;use this stuff!
	;
	; get date format from .ini file, if any.
	;
	mov	di, offset dgroup:[formatOriginal]
	mov	si, es:formatToEdit
	call	LocalGetDateTimeFormat			
	call	ResetCurrentAndParse	;set current string to original,
					;  and parse into UI objects.

	call	PrefIntlUpdateCurrent	;update examples (added 1/23/93
					;   cbh -- somehow this used
					;   to happen another way)

	ret
SetupTimeDateCommon	endp


if PZ_PCGEOS	;Koji
COMMENT @----------------------------------------------------------------------

ROUTINE:	UsableDateLanguage

SYNOPSIS:	Sets DateLanguageGroup to usable or unusable.

CALLED BY:	SetupTimeDateCommon

PASS:		ds -- dgroup
		
RETURN:		nothing

DESTROYED:	ax, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		if LongDateFormat
			usable DateLanguage item group
		else if ShortDateFormat or TimeFormat
			unusable DateLanguage item group
		endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	koji	9/13/93		Initial version

------------------------------------------------------------------------------@

UsableDateLanguage		proc	near
	mov	si, offset DateLanguageGroup
	cmp	es:formatToEdit, DTF_LONG	;long date format?
	je	doUsable			;yes, usable!
	call	PrefIntlSetNotUsable
	jmp	exit
doUsable:
	call	PrefIntlSetUsable
exit:
	ret
UsableDateLanguage		endp
endif



COMMENT @----------------------------------------------------------------------

ROUTINE:	ResetCurrentAndParse

SYNOPSIS:	Sets current date format string to original, and parses it
		into UI objects.

CALLED BY:	PrefIntlDialogInit, PrefIntlReset

PASS:		es -- dgroup
		ds - segment of UI objects

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 6/90		Initial version

------------------------------------------------------------------------------@

ResetCurrentAndParse	proc	near
		uses	ds
		.enter
	;
	; Use original name as current editable name.
	;
		segmov	ds, es
		mov	si, offset formatOriginal
		mov	di, offset formatCurrent
		LocalCopyString
	;
	; Parse the current string into the appropriate gadgets.
	;

		mov	si, offset formatCurrent	;source buffer
		mov	ax, offset FormatElement1	;first element
							;to dump into
		.leave

		FALL_THRU	ParseDateFormat
	
ResetCurrentAndParse	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	ParseDateFormat

SYNOPSIS:	Parse the date format passed into the appropriate UI gadgets.

CALLED BY:	PrefIntlDialogInit

PASS:		es:si -- source buffer to use
		es -- dgroup
		*ds:ax -- first UI element to dump into

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REGISTER USAGE:
	 	dl -- keep number of character-spin gadget pairs we've done
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 5/90		Initial version

------------------------------------------------------------------------------@

ParseDateFormat	proc	near
	mov	cx, DATE_FORMAT_GADGET_PAIRS	;do four pairs of gadgets
doPair:
	call	ParseDateText			;set the text object gadget
	add	ax, TIME_DATE_TEXT_TO_RANGE_OBJ	;move to next gadget
						;  (expected to be consecutive)
	call	ParseDateToken			;set the spin gadget
	add	ax, TIME_DATE_RANGE_TO_TEXT_OBJ	;move to next gadget
						;  (expected to be consecutive,
						;   after hints chunk)
	loop	doPair				;go do another pair
	ret
ParseDateFormat	endp

CheckHack <TIME_DATE_TEXT_TO_RANGE_OBJ eq (offset FormatElement2 - \
	  	offset FormatElement1)
CheckHack <TIME_DATE_TEXT_TO_RANGE_OBJ eq (offset FormatElement4 - \
	  	offset FormatElement3)
CheckHack <TIME_DATE_TEXT_TO_RANGE_OBJ eq (offset FormatElement6 - \
	  	offset FormatElement5)
CheckHack <TIME_DATE_TEXT_TO_RANGE_OBJ eq (offset FormatElement8 - \
	  	offset FormatElement7)
		
CheckHack <TIME_DATE_RANGE_TO_TEXT_OBJ eq (offset FormatElement3 - \
	  	offset FormatElement2)
CheckHack <TIME_DATE_RANGE_TO_TEXT_OBJ eq (offset FormatElement5 - \
	  	offset FormatElement4)
CheckHack <TIME_DATE_RANGE_TO_TEXT_OBJ eq (offset FormatElement7 - \
	  	offset FormatElement6)
	


COMMENT @----------------------------------------------------------------------

ROUTINE:	ParseDateText

SYNOPSIS:	Parse text preceding a token.

CALLED BY:	ParseDateFormat

PASS:		es:si   -- pointer to source text to parse
		*ds:ax -- handle of UI object to dump into

RETURN:		ax -- update to next UI object
		es:si -- update to new point in the text, pointing at null
			 byte or start of new token

DESTROYED:	dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 5/90		Initial version

------------------------------------------------------------------------------@

ParseDateText	proc	near		uses	ax, cx
	.enter
	;
	; Read all characters up until a '|' or null
	;
	mov	di, offset parseBuffer	;my parse buffer
	push	ax			;save gadget handle
	mov	cx, MAX_SEPARATOR_LENGTH ;store no more chars than this...
doChar:
if DBCS_PCGEOS
	cmp	{wchar} es:[si], 0	;no more string to parse?
	jz	done			;no, done
	cmp	{wchar} es:[si], TOKEN_DELIMITER	;token?
	jne	load			;no, normal character, load and store
	;
	; We've appeared to have hit a token.  If a '|DD|', we will store a
	; a token delimiter instead.
	;
	cmp	{wchar} es:[si]+2, TOKEN_TOKEN_CHAR_1
	jne	done
	cmp	{wchar} es:[si]+4, TOKEN_TOKEN_CHAR_2
	jne	done			;normal token, we're done with text.
	cmp	{wchar} es:[si]+6, TOKEN_DELIMITER
	jne	done			;not so normal, lets not screw ourselves
	add	si, 8			;skip over special token
	mov	ax, TOKEN_DELIMITER	;we'll store a token delimiter
	jmp	store
load:
	lodsw	es:			;get a character now
store:
	stosw				;store into buffer
	loop	doChar			;go do another char, if possible
done:
	clr	ax			;store a null
	stosw
else
	cmp	{byte} es:[si], 0	;no more string to parse?
	jz	done			;no, done
	cmp	{byte} es:[si], TOKEN_DELIMITER	;token?
	jne	load			;no, normal character, load and store
	;
	; We've appeared to have hit a token.  If a '|DD|', we will store a
	; a token delimiter instead.
	;
	cmp	{word} es:[si]+1, TOKEN_TOKEN_DELIMITER
	jne	done			;normal token, we're done with text.
	cmp	{byte} es:[si]+3, TOKEN_DELIMITER
	jne	done			;not so normal, lets not screw ourselves
	add	si, 4			;skip over special token
	mov	al, TOKEN_DELIMITER	;we'll store a token delimiter
	jmp	store
load:
	lodsb	es:			;get a character now
store:
	stosb				;store into buffer
	loop	doChar			;go do another char, if possible
done:
	clr	al			;store a null
	stosb
endif
	pop	ax			;restore handle
	;
	; Text is now in tempBuffer.  Let's set the text gadget to have our
	; text.
	;
	mov	bp, offset parseBuffer	;here's our text
	push	si
	mov	si, ax			;UI object in *ds:si
	call	PrefIntlSetText		;set it
	pop	si
	.leave
	ret
ParseDateText	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	ParseDateToken

SYNOPSIS:	Parse the next date token, if any, and set a UI object.

CALLED BY:	ParseDateFormat

PASS:		es:si   -- pointer to source text to parse, pointing at the
			   start of a 4-character token, if we're 
			   lucky.
		*ds:ax --  UI object to dump into

RETURN:		ax -- update to next UI object
		es:si -- update to new point in the text

DESTROYED:	dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 5/90		Initial version

------------------------------------------------------------------------------@

ParseDateToken	proc	near		uses 	ax, cx
	.enter
	push	ax
	clr	cx			   ;assume no token
if DBCS_PCGEOS
	cmp	{wchar} es:[si], 0	   ;no more string to parse?
	jz	done			   ;no, done
	inc	si
	inc	si			   ;skip the token delimiter
	lodsw	es:			   ;load a token into ax
	lodsw	es:			   ;al = 2nd char of token
	mov	ah, es:[si][-4]		   ;ah = 1st char of token
	xchg	al, ah			   ;ax = token
	mov	cx, TOKEN_COUNT		   ;load number of tokens to try
	mov	di, offset dateTokenTable
	repne	scasw			   ;see if it's around
	mov	cx, 0			   ;assume no luck (may be unnecessary)
	jne	done			   ;we failed here, get out 
	sub	di, offset dateTokenTable  ;else get offset
	shr	di, 1			   ;divide by 2 to get element number
	mov	cx, di			   ;
	;
	; Find trailing '|' wherever it is.  If it ain't the next character,
	; we'll forget about our original token idea.
	;
	
findDelimiter:
	cmp	{wchar} es:[si], 0	   ;null terminated here?
	jz	done			   ;yes, get out, not sweating the lack
					   ;   of a finishing delimiter
	lodsw	es:			   ;this should be the guy
	cmp	ax, TOKEN_DELIMITER	   ;is it?
else
	cmp	{byte} es:[si], 0	   ;no more string to parse?
	jz	done			   ;no, done
	inc	si			   ;skip the token delimiter
	lodsw	es:			   ;load a token into ax
	mov	cx, TOKEN_COUNT		   ;load number of tokens to try
	mov	di, offset dateTokenTable
	repne	scasw			   ;see if it's around
	mov	cx, 0			   ;assume no luck (may be unnecessary)
	jne	done			   ;we failed here, get out 
	sub	di, offset dateTokenTable  ;else get offset
	shr	di, 1			   ;divide by 2 to get element number
	mov	cx, di			   ;
	;
	; Find trailing '|' wherever it is.  If it ain't the next character,
	; we'll forget about our original token idea.
	;
	
findDelimiter:
	cmp	{byte} es:[si], 0	   ;null terminated here?
	jz	done			   ;yes, get out, not sweating the lack
					   ;   of a finishing delimiter
	lodsb	es:			   ;this should be the guy
	cmp	al, TOKEN_DELIMITER	   ;is it?
endif
	je	done			   ;yes, branch
	clr	cx			   ;forget the token, this is a mess.
	jmp	findDelimiter
done:
	pop	ax			   ;restore object handle
	push	si			   ;save source buffer pointer
	mov	si, ax
	call	PrefIntlSetSpin
	pop	si			   ;restore source buffer pointer
	.leave
	ret
ParseDateToken	endp


		

COMMENT @----------------------------------------------------------------------

METHOD:		PrefIntlApply -- 
		MSG_PREF_INTL_EDIT_APPLY for PrefIntlDialogClass

DESCRIPTION:	Handles an apply for the edit box.

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 6/90		Initial version

------------------------------------------------------------------------------@

PrefIntlApply	method PrefIntlDialogClass, MSG_PREF_INTL_EDIT_APPLY
	
	call	PrefIntlUpdateCurrent	;set current values
	
	mov	cx, es:formatToEdit	;get our formatting choice
	cmp	cx, DTF_CURRENCY	;doing currency?	
	jne	10$
	call	ApplyCurrency		;do apply on currency stuff
	jmp	short dismiss		;and skip to next choice
10$:
	cmp	cx, DTF_DECIMAL		
	jne	20$
	call	ApplyDecimal		;do apply on decimal stuff
	jc	exit			;don't dismiss if error
	jmp	short dismiss
20$:
	cmp	cx, DTF_QUOTES
	jne	30$
	call	ApplyQuotes
	jmp	short dismiss
30$:
	;
	; Make sure something changed.  If not, nothing to write back.
	;
	mov	si, offset formatCurrent	
	mov	di, offset formatOriginal
	call	CmpString	
	je	dismiss

	call	CheckForBadFormats		;multiple tokens?
	jc	exit				;yes, complain and exit
	
	mov	es:formatsChanged, TRUE		;set this flag
	
	;
	; Write the new date format to the .ini file.
	;
if PZ_PCGEOS	;Koji
	call	GetDateLanguageSelection	;ax - date language selection
	call	SetDateLanguageToInitFile	;set date language to ini.file
endif
	call	SetAllRelatedFormats		;set all the different formats
	;
	; Change original name to match new current name.
	;
	push	ds
	segmov	ds, es
	mov	si, offset formatCurrent
	mov	di, offset formatOriginal
	LocalCopyString				;destroys ax,cx,di,si
	pop	ds

	call	DoOtherExamples			;set other time/date examples
dismiss:
	mov	si, offset IntlEdit
	call	MyDismissInteraction		;dismiss the interaction
exit:
	ret
PrefIntlApply	endm

MyDismissInteraction	proc	near
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjCallInstanceNoLock
	ret
MyDismissInteraction	endp

			


COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckForBadFormats

SYNOPSIS:	Checks for duplicate tokens. Complains if there are.

CALLED BY:	PrefIntlApply

PASS:		ds -- dgroup

RETURN:		carry set if there was a problem.

DESTROYED:	si, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
        Assumes only the last token can be zero, or empty.	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/21/91		Initial version

------------------------------------------------------------------------------@

CheckForBadFormats	proc	near
	mov	al, es:firstTokenSuffix		;get all the suffixes entered
	mov	ah, es:secondTokenSuffix
	mov	bl, es:thirdTokenSuffix
	mov	bh, es:fourthTokenSuffix
if PZ_PCGEOS	;Koji
	mov	cl, al				;modify Japanese token
	call	ModJpToken
	mov	al, cl
	mov	cl, ah
	call	ModJpToken
	mov	ah, cl
	mov	cl, bl
	call	ModJpToken
	mov	bl, cl
	tst	bh
	jz	10$
	mov	cl, bh
	call	ModJpToken
	mov	bh, cl
else
	tst	bh
	jz	10$
endif
	cmp	bh, al				;make sure none match (nulls
	je	error				;  are OK)
	cmp	bh, ah
	je	error
	cmp	bh, bl
	je 	error
10$:
	tst	bl
	jz	20$
	cmp	bl, al
	je	error
	cmp	bl, ah
	je 	error
20$:
	cmp	al, ah				;(these are never null)
	jne	check12HourAMPM			;nope, try other stuff
error:
	mov	si, offset badFormatString
	jmp	short doError
	
check12HourAMPM:
	cmp	es:firstTokenSuffix, 'H'	;see if 12 hour format
	jne	OK
	cmp	es:fourthTokenSuffix, 'p'	;using am/pm?
	je	OK				;yes, exit OK
	cmp	es:fourthTokenSuffix, 'P'	;using AM/PM?
	je	OK				;yes, exit OK	
	mov	si, offset noAMPMString		;else say no AM or PM
doError:
	mov	bx, handle Strings
	call	DoError				;put up error box
	stc					;signal an error
	jmp	short exit			;and exit
OK:
	clc					;say OK
exit:
	ret
CheckForBadFormats	endp


if PZ_PCGEOS	;Koji
COMMENT @----------------------------------------------------------------------

ROUTINE:	ModJpToken

SYNOPSIS:	Modify Japanese Token for checking.

CALLED BY:	CheckForBadFormats

PASS:		cl - token suffix

RETURN:		cl - token suffix. possibly modified.

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Koji	11/12/93	Initial version

------------------------------------------------------------------------------@
ModJpToken	proc	near
	cmp	cl, 'G'		;Japanese Gengo year?
	jne	exit
	mov	cl, 'Y'
exit:
	ret
ModJpToken	endp
endif



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetAllRelatedFormats

SYNOPSIS:	Sets all the formats we need to set.  From the parent format,
		builds out all of the formats related to it and sets them in
		the localization driver.

CALLED BY:	PrefIntlApply

PASS:		es:currentFormat -- set to current major format string

RETURN:		es:currentFormat -- still set to the same format string

DESTROYED:	si, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@

SetAllRelatedFormats	proc	near
	call	GetRelatedFormatList		;es:si <- list of formats
EC <	tst	si						>
EC <	ERROR_Z	-1						>
	;
	; ds:si points to a list of formats to create.  Let's create them
	; one by one.
	;
doFormat:
	mov	cl, es:[si]			;get a format
	tst	cl
	js	exit				;none left (-1), exit
	clr	ch				;cx <- format
	push	cx
	push	si
	call	UpdateDateFormat		;format in currentFormat
	pop	si
	pop	cx
	
	push	si
	mov	di, offset formatCurrent	;new format
	mov	si, cx				;format enum into si
	call	LocalSetDateTimeFormat			
	pop	si
	inc	si				;next format to do
	jmp	short doFormat			;loop to do another
exit:
	ret
SetAllRelatedFormats	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	GetRelatedFormatList

SYNOPSIS:	Points to a list of related formats to the one being edited.

CALLED BY:	SetAllRelatedFormats

PASS:		es -- dgroup

RETURN:		es:si -- pointing to a null terminated list of related formats
			(or si null if not one of these base formats)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@

GetRelatedFormatList	proc	near
	mov	cx, es:formatToEdit		;see what we're doing
	mov	si, offset longFormats
	cmp	cx, DTF_LONG
	je	exit
	
	mov	si, offset shortFormats
	cmp	cx, DTF_SHORT
	je	exit
	
	mov	si, offset timeFormats
	cmp	cx, DTF_HMS
	je	exit
	clr	si				;return null if none of these
exit:	
	ret
GetRelatedFormatList	endp




COMMENT @----------------------------------------------------------------------

METHOD:		PrefIntlDone -- 
		MSG_PREF_INTL_DIALOG_DONE for PrefIntlDialogClass

DESCRIPTION:	Called when user finally exists from the formats list box.

PASS:		ax 	- MSG_PREF_INTL_DIALOG_DONE

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/20/90		Initial version

------------------------------------------------------------------------------@

PrefIntlDone	method PrefIntlDialogClass, MSG_PREF_INTL_DIALOG_DONE

	tst	es:formatsChanged		;see if anything`s changed
	jz	done				;no, just dismiss

	push	si	
	mov	bx, handle formatChangeConfirmation
	mov	si, offset formatChangeConfirmation
	call	ConfirmDialog
	pop	si

	jnc	reboot

done:
	call	MyDismissInteraction
	ret

reboot:

	mov	ax, MSG_PREF_DIALOG_REBOOT
	GOTO	ObjCallInstanceNoLock

PrefIntlDone	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	ConfirmDialog

CALLED BY:	

PASS:		^lbx:si - string to display

RETURN:		carry clear if affirmative
		carry set otherwise

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial version
	CDB	4/22/92		cleaned up.
------------------------------------------------------------------------------@
ConfirmDialog	proc	near
		uses	ax
		.enter

		clr	ax
		push	ax, ax		; SDOP_helpContext
		push	ax, ax		; SDOP_customTriggers
		push	ax, ax		; SDOP_stringArg2
		push	ax, ax		; SDOP_stringArg1
		push	bx, si		; SDOP_customString

	
		mov	ax, (CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
			(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)

		push	ax		; SDOP_customFlags

	CheckHack <size StandardDialogOptrParams eq 22>

		call	UserStandardDialogOptr

		cmp	ax, IC_YES	; clears carry if equal
		je	done
		stc
done:
		.leave
		ret
ConfirmDialog	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	ApplyCurrency

SYNOPSIS:	Does an apply on the currency dialog box.

CALLED BY:	PrefIntlApply

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/13/90	Initial version

------------------------------------------------------------------------------@

ApplyCurrency	proc	near
	;
	; Compare current values to original ones.
	;
	push	ds
	segmov	ds, es
	mov	si, offset originalCurrencyFlags
	mov	di, offset currentCurrencyFlags
	mov	cx, (offset currentCurrencyFlags - \
		     offset originalCurrencyFlags)	;bytes to compare
	repe	cmpsb
	pop	ds

	je	exit					;still the same, exit
	
	mov	es:formatsChanged, TRUE		;set this flag
	;
	; Set the new currency formats, using our current values.
	;
	mov	al, es:currentCurrencyFlags
	mov	ah, es:currentCurrencyDigits
	mov	di, offset currentCurrencySymbol
	
	call	LocalSetCurrencyFormat		;see what we get here.
exit:
	ret
ApplyCurrency	endp

		
		


COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateCurrencyValues

SYNOPSIS:	Updates currency values from UI gadgets.

CALLED BY:	ApplyCurrency

PASS:		es -- dgroup

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 3/91		Initial version

------------------------------------------------------------------------------@

UpdateCurrencyValues	proc	near
	;
	; Now set current values based on all the appropriate gadgets.
	;
	mov	si, offset CurrencyDigitsValue
	call	PrefIntlGetValue
	mov	es:currentCurrencyDigits, cl
	
	mov	dx, offset currentCurrencySymbol
	mov	si, offset SymbolText
	call	PrefIntlGetTextIntoBuffer
	
	clr	es:currentCurrencyFlags
	mov	si, offset CurrLeadingZeroSpin
	call	PrefIntlGetSpin
	tst	cl					;is this set?
	jz	10$
	or	es:currentCurrencyFlags, mask CFF_LEADING_ZERO
10$:
	mov	si, offset SpaceAroundSpin
	call	PrefIntlGetSpin
	tst	cl
	jz	20$
	or	es:currentCurrencyFlags, mask CFF_SPACE_AROUND_SYMBOL
20$:
	mov	si, offset PlacementSpin		
	call	PrefIntlGetSpin				;get offset
	mov	al, cl
	call	CurrencyOffsetToFlags			;compute a spin offset
	or	es:currentCurrencyFlags, al
	ret
UpdateCurrencyValues	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	CurrencyFlagsToOffset, CurrencyOffsetToFlags

SYNOPSIS:	Converts 4 currency flags into a offset into the format spin.

CALLED BY:	whomever

PASS:		al -- currency flags  (offset for CurrencyOffsetToFlags)
		es -- dgroup

RETURN:		al -- currency offset (flags for CurrencyOffsetToFlags)

DESTROYED:	cx, di, ah

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/14/90		Initial version

------------------------------------------------------------------------------@

CurrencyFlagsToOffset	proc	near
	clr	ah
	mov	di, ax
	mov	al, es:currFormatTable[di]	;look up appropriate offset
	ret
CurrencyFlagsToOffset	endp

CurrencyOffsetToFlags	proc	near
	mov	cx, length currFormatTable
	mov	di, offset currFormatTable
	repne	scasb				;search for first offset
	sub	di, (offset currFormatTable)+1	;get offset to the match
	mov	ax, di				;and return in al
	ret
CurrencyOffsetToFlags	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	ApplyDecimal

SYNOPSIS:	Does an apply on the numeric dialog box.

CALLED BY:	PrefIntlApply

PASS:		es - dgroup

RETURN:		carry set on error (if decimalSeparator == listSeparator)

DESTROYED:	anything

vPSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/13/90	Initial version
	JDM	93.03.26	Fixed arguments to LocalSetNumericFormat.

------------------------------------------------------------------------------@

ApplyDecimal	proc	near

	push	ds
	segmov	ds, es
	mov	si, offset originalLeadingZeroFlag	
	mov	di, offset currentLeadingZeroFlag
	mov	cx, (offset currentLeadingZeroFlag - \
		     offset originalLeadingZeroFlag)	;bytes to copy
	repe	cmpsb
	pop	ds

	je	exit				;everything still matches, exit

	; Ensure that the listSeparator is not the same as the decimalSeparator

SBCS <	mov	al, es:[currentDecimalSeparator]			>
SBCS <	cmp	al, es:[currentListSeparator]				>
DBCS <	mov	ax, es:[currentDecimalSeparator]			>
DBCS <	cmp	ax, es:[currentListSeparator]				>
	jne	continue

	mov	bx, handle badSeparatorString
	mov	si, offset badSeparatorString
	call	DoError
	stc					;error
	jmp	exit

continue:
	mov	es:formatsChanged, TRUE		;set this flag
	;
	; Set the new numeric formats, using our current values.
	;
	clr	bx, dx, cx
if DBCS_PCGEOS
	mov	ah, es:currentDecimalDigits
	mov	bx, es:currentThousandsSeparator
	mov	cx, es:currentDecimalSeparator
	mov	dx, es:currentListSeparator
	mov	al, es:currentLeadingZeroFlag
else
	mov	ah, es:currentDecimalDigits
	mov	bl, es:currentThousandsSeparator
	mov	cl, es:currentDecimalSeparator
	mov	dl, es:currentListSeparator
	mov	al, es:currentLeadingZeroFlag
endif
	call	LocalSetNumericFormat		;set in localization driver
	
	mov	al, es:currentMeasurementType
	call	LocalSetMeasurementType		;set in localization driver
	clc					;no error
exit:
	ret
ApplyDecimal	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateDecimalValues

SYNOPSIS:	Gets currenct decimal values from UI gadgets.

CALLED BY:	ApplyDecimal

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 3/91		Initial version

------------------------------------------------------------------------------@

UpdateDecimalValues	proc	near
	;
	; Get data from all the appropriate gadgets.
	;
	mov	si, offset DecimalDigitsValue
	call	PrefIntlGetValue
	mov	es:currentDecimalDigits, cl		;get decimal digits
	
	mov	si, offset LeadingZeroSpin
	call	PrefIntlGetSpin
	mov	es:currentLeadingZeroFlag, cl
	
	mov	si, offset MeasurementSpin
	call	PrefIntlGetSpin
	mov	es:currentMeasurementType, cl
	
	mov	si, offset ThousandsSepText
	mov	dx, offset currentThousandsSeparator
	call	PrefIntlGetTextIntoBuffer
	
	mov	si, offset DecimalSepText
	mov	dx, offset currentDecimalSeparator
	call	PrefIntlGetTextIntoBuffer
	
	mov	si, offset ListSeparatorText
	mov	dx, offset currentListSeparator
	call	PrefIntlGetTextIntoBuffer
	ret
UpdateDecimalValues	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	ApplyQuotes

SYNOPSIS:	Does an apply for the quotes dialog box.

CALLED BY:	PrefIntlApply

PASS:		nothing

RETURN:		nothing

DESTROYED:	anything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/28/90		Initial version

------------------------------------------------------------------------------@

ApplyQuotes	proc	near
if DBCS_PCGEOS
	mov	ax, es:currentSingleLeft
	mov	bx, es:currentSingleRight
	mov	cx, es:currentDoubleLeft
	mov	dx, es:currentDoubleRight

	cmp	ax, es:originalSingleLeft
	jne	updateThings			;something changed, branch
	cmp	bx, es:originalSingleRight
	jne	updateThings			;something changed, branch
	cmp	cx, es:originalDoubleLeft
	jne	updateThings			;something changed, branch
	cmp	dx, es:originalDoubleRight
	jz	updateThings			;nothing changed, exit
else
	mov	bx, {word} es:currentDoubleLeft
	mov	ax, {word} es:currentSingleLeft
	
	cmp	bx, {word} es:originalDoubleLeft  
	jne	updateThings			;something changed, branch
	cmp	ax, {word} es:originalSingleLeft  
	jz	updateThings			;nothing changed, exit
endif
	
updateThings:	
	mov	es:formatsChanged, TRUE		  ;set this flag
	
if DBCS_PCGEOS
	mov	es:originalSingleLeft, ax
	mov	es:originalSingleRight, bx
	mov	es:originalDoubleLeft, cx
	mov	es:originalDoubleRight, dx
else
	mov	{word} es:originalSingleLeft, ax  ;store new originals
	mov	{word} es:originalDoubleLeft, bx
endif
	
	; 
	; Set quotes in localization driver.
	;
if not DBCS_PCGEOS
	clr	cx, dx
	mov	dl, bh
	mov	cl, bl
	clr	bx
	mov	bl, ah
	clr	ah
endif
	call	LocalSetQuotes			;ax,bx,cx,dx hold quotes
	ret
ApplyQuotes	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateQuoteValues

SYNOPSIS:	Updates quote values from UI objects.

CALLED BY:	ApplyQuotes

PASS:		es -- dgroup

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 3/91		Initial version

------------------------------------------------------------------------------@

UpdateQuoteValues	proc	near
	mov	si, offset LastSingleText
	call	GetTextIntoAL
if DBCS_PCGEOS
	mov	es:currentSingleRight, ax
	mov	es:exampleQuoteSingleRight, ax	;update example quotes in text
	
	mov	si, offset FirstSingleText
	call	GetTextIntoAL
	mov	es:currentSingleLeft, ax
	mov	es:exampleQuoteSingleLeft, ax
	
	mov	si, offset LastDoubleText
	call	GetTextIntoAL
	mov	es:currentDoubleRight, ax
	mov	es:exampleQuoteDoubleRight, ax	;update example quote in text
	
	mov	si, offset FirstDoubleText
	call	GetTextIntoAL
	mov	es:currentDoubleLeft, ax
	mov	es:exampleQuoteDoubleLeft, ax
else
	mov	ah, al				;put right single quote in ah
	
	mov	si, offset FirstSingleText
	call	GetTextIntoAL
	mov	{word} es:currentSingleLeft, ax
	mov	es:exampleQuoteSingleLeft, al	;update example quotes in text
	mov	es:exampleQuoteSingleRight, ah
	
	mov	si, offset LastDoubleText
	call	GetTextIntoAL
	mov	ah, al				;put right single quote in ah
	
	mov	si, offset FirstDoubleText
	call	GetTextIntoAL
	mov	{word} es:currentDoubleLeft, ax
	mov	es:exampleQuoteDoubleLeft, al
	mov	es:exampleQuoteDoubleRight, ah	;update example quote in text
endif
	ret
UpdateQuoteValues	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	GetTextIntoAL

SYNOPSIS:	Reads text from object, putting first character in AL.

CALLED BY:	ApplyQuotes

PASS:		*ds:si  -- object to read from
		es - dgroup 

RETURN:		al -- first text character
			(ax for DBCS)

DESTROYED:	parseBuffer, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/28/90	Initial version

------------------------------------------------------------------------------@

GetTextIntoAL	proc	near
	push	ax
	mov	dx, offset parseBuffer
	call	PrefIntlGetTextIntoBuffer
	pop	ax
SBCS <	mov	al, es:parseBuffer					>
DBCS <	mov	ax, {wchar}es:parseBuffer				>
	ret
GetTextIntoAL	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateDateFormat

SYNOPSIS:	Updates the date format from UI gadgets.

CALLED BY:	PrefIntlApply

PASS:		cx -- format to build
		es -- dgroup
		
RETURN:		es:formatCurrent -- set to built out string

DESTROYED:	

PSEUDO CODE/STRATEGY:
       Uses:
       		es:di	-- source buffer to use
		^lbx:ax -- first UI element to dump from
		bp	-- format being built

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 6/90	Initial version

------------------------------------------------------------------------------@
UpdateDateFormat	proc	near

	mov	di, offset formatCurrent	;destination buffer
	mov	ax, offset FormatElement1	;first element to dump from
	mov	bp, cx
	
	mov	cx, DATE_FORMAT_GADGET_PAIRS	;do four pairs of gadgets

	push	si
	mov	si, bp				;get modification flags
	shl	si, 1
	test	es:formatModificationTable[si], mask FAF_REMOVE_LEADING_TEXT
	pop	si
	jz	beginUpdate			;not set, start our update, c=0
	stc					;else ignore leading text

beginUpdate:
	pushf
doPair:
	popf					;see if we should ignore text
	jc	10$				;yes, branch
	call	UpdateDateText			;get the text object data
10$:
	add	ax, TIME_DATE_TEXT_TO_RANGE_OBJ	;move to next gadget
						;  (expected to be consecutive)
	call	UpdateDateToken			;get the spin gadget data
	pushf					;save carry flag
	call	CheckForTextTrimming		;may need to trim trailing text
	add	ax, TIME_DATE_RANGE_TO_TEXT_OBJ	;move to next gadget
						;  (expected to be consecutive,
						;   after hints chunk)
	loop	doPair				;go do another pair
	popf					;unload carry flag
	;
	; Null terminate our fine string.
	;
SBCS <	clr	al							>
SBCS <	stosb								>
DBCS <	clr	ax							>
DBCS <	stosw								>
	ret
UpdateDateFormat	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateDateText

SYNOPSIS:	Updates our date format string, using the passed text object.

CALLED BY:	UpdateDateFormat

PASS:		es:di   -- buffer pointer to copy to
		*ds:ax -- UI element to get text from
		bp      -- format being built out, with 
				IGNORE_TEXT_ON_THIS_PASS if we're to ignore
				the text.

RETURN:		es:di -- updated

DESTROYED:	dx, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 6/90	Initial version

------------------------------------------------------------------------------@

UpdateDateText	proc	near

	uses	cx, ax, bp

	.enter
	;
	; Copy text from UI object into the parse buffer.
	;
		
	mov	si, ax				;object in *ds:si
	mov     ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	dx, es				;cx:dx is destination
	mov	bp, offset parseBuffer		;  (the parse buffer)
	call	ObjCallInstanceNoLock 
	mov	ax, si			  	;restore object handle
	
	;
	; Now character by character, copy the parse buffer stuff into
	; our destination.
	;
	jcxz	exit
	mov	si, offset parseBuffer		;our source
doChar:
if DBCS_PCGEOS
	lodsw	es:				;get a char
	cmp	ax, TOKEN_DELIMITER		;is it a token delimiter?
	jne	10$				;no, branch
	stosw					;else store a "|DD|" instead
	mov	ax, TOKEN_TOKEN_CHAR_1
	stosw
.assert (TOKEN_TOKEN_CHAR_2 eq TOKEN_TOKEN_CHAR_1)
	stosw
	mov	ax, TOKEN_DELIMITER
10$:
	stosw					;store the character
else
	lodsb	es:				;get a char
	cmp	al, TOKEN_DELIMITER		;is it a token delimiter?
	jne	10$				;no, branch
	stosb					;else store a "|DD|" instead
	mov	ax, TOKEN_TOKEN_DELIMITER
	stosw
	mov	al, TOKEN_DELIMITER
10$:
	stosb					;store the character
endif
	loop	doChar				;do another char if necessary
exit:
		
	.leave
	ret
UpdateDateText	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateDateToken

SYNOPSIS:	Updates our date format string, using the passed spin object.

CALLED BY:	UpdateDateFormat

PASS:		es:di   -- buffer pointer to copy to
		^lbx:ax -- UI element to get token from
		bp      -- format being built out
		cx	-- number of tokens to do

RETURN:		es:di -- updated
		carry set if token is being ignored, and the text after it
			should also be ignored.

DESTROYED:	dx, si


PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 6/90		Initial version

------------------------------------------------------------------------------@

UpdateDateToken	proc	near		uses	ax, bp
	.enter
	push	cx				 ;
	mov	si, ax				 ;object in ^lbx:si
	push	di
	call	PrefIntlGetSpin
	pop	di
	
	clr	ax				 ;set to no token
	tst	cx				 ;"none" chosen?
	jz	exit				 ;yes, exit, no token
	cmp	cx, TIME_TOKEN_START		 ;the other "none" chosen?
	je	exit				 ;yes, exit, no token
	
	mov	si, cx				 ;put token index in si
	dec	si				 ;subtract off the "none"
	shl	si, 1				 ;double for word offset
	mov	ax, {word} es:dateTokenTable[si] ;get token for it from table
	
	call	CheckForFormatModifications	 ;do any necessary modifications
	jnc	storeToken			 ;everything's cool, store token
	cmp	ah, 's'				 ;seconds being removed?
	je	exitKeepTrailingText		 ;yes,want to keep text after it
	stc					 ;else we'll remove next text
	jmp	short exit
		
storeToken:
if DBCS_PCGEOS
	mov	{wchar} es:[di], TOKEN_DELIMITER ;store starting delimiter
	inc	di
	inc	di
	push	ax
	clr	ah
	stosw					 ;store token char 1
	pop	ax
	push	ax
	mov	al, ah
	clr	ah
	stosw					 ;store token char 2
	mov	{wchar} es:[di], TOKEN_DELIMITER ;store ending delimiter
	inc	di
	inc	di
	pop	ax				 ;restore token
else
	mov	{byte} es:[di], TOKEN_DELIMITER	 ;store starting delimiter
	inc	di
	stosw					 ;store token
	mov	{byte} es:[di], TOKEN_DELIMITER	 ;store ending delimiter
	inc	di
endif
	
exitKeepTrailingText:
	clc					 ;say we stored the token
exit:
	;
	; Before exiting, we need to save some of the token information.
	; ax <- token just entered, or zero.
	;
	pop	cx				 ;restore tokens-to-do
	pushf					 ;save carry
	mov	bp, DATE_FORMAT_GADGET_PAIRS	 ;index into table = 
	sub	bp, cx				 ;  (4-tokensLeft)*2
	shl	bp, 1				 ;double for word offset
	mov	es:firstToken[bp], ax		 ;we save all the tokens
						 ;  for later error checking
	popf
	.leave
	ret
UpdateDateToken	endp


		


COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckForFormatModifications

SYNOPSIS:	Does any format modifications that are necessary here.

CALLED BY:	UpdateDateToken

PASS:		ax -- token being looked at
		bp -- format being created
		es:di -- pointing to next character to add
		di

RETURN:		carry set if token is not to be used
		ax -- token, possibly modified
		es:di -- possibly changed

DESTROYED:	dx, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/15/91		Initial version

------------------------------------------------------------------------------@

CheckForFormatModifications	proc	near
	push	bx
	mov	si, bp				;get modification flags
	shl	si, 1
	mov	dx, es:formatModificationTable[si]
	and	dx, mask FAF_REMOVE_WEEKDAY or \
		    	 mask FAF_REMOVE_YEAR or \
			 mask FAF_REMOVE_MONTH or \
			 mask FAF_REMOVE_DAY or \
			 mask FAF_REMOVE_SECONDS or \
			 mask FAF_REMOVE_MINUTES or \
			 mask FAF_REMOVE_HOURS or \
			 mask FAF_REMOVE_AM_PM or \
		   	 mask FAF_CONDENSE_DATE or \
			 mask FAF_ZERO_PAD_DATE or \
			 mask FAF_CONVERT_TO_24_HOUR or \
			 mask FAF_USE_FIRST_TOKEN_IN_MINUTES

	tst	dx				;any modifications need be done?
	jz	exit				;no, exit
	;
	; Flags in dx.  We'll shift them out, one by one, and call the
	; appropriate modification routine for those bits that are set.
	;
	mov	bx, offset modificationRoutines
	
filterLoop:
	rcr	dx, 1				 ;rotate a flag into carry
	jnc	10$				 ;not filtering this, branch
	call	{word} cs:[bx]			 ;else call the filter routine
	jc	exit				 ;match found, exit
10$:
	add	bx, 2				 ;point to next routine
	cmp	bx, offset eModificationRoutines ;see if past end of table
	jbe	filterLoop			 ;nope, do another bit
	clc					 ;else no problems found
exit:
	pop	bx
	ret
CheckForFormatModifications	endp

				
modificationRoutines		word		\
	offset	ModRemoveWeekday,		;FAF_REMOVE_WEEKDAY
	offset	ModRemoveYear,			;FAF_REMOVE_YEAR
	offset  ModRemoveMonth,			;FAF_REMOVE_MONTH
	offset	ModRemoveDay,			;FAF_REMOVE_DAY
	offset	ModRemoveSeconds,		;FAF_REMOVE_SECONDS
	offset	ModRemoveMinutes,		;FAF_REMOVE_MINUTES
	offset  ModRemoveHours, 		;FAF_REMOVE_HOURS
	offset	ModRemoveAMPM,			;FAF_REMOVE_AM_PM
	offset	ModCondenseDate,		;FAF_CONDENSE_DATE
	offset 	ModZeroPadDate,			;FAF_ZERO_PAD_DATE
	offset	ModConvertTo24Hour,		;FAF_CONVERT_TO_24_HOUR
	offset	ModUseFirstTokenInMinutes	;FAF_USE_FIRST_TOKEN_IN_MINUTES
eModificationRoutines		label	word
	




COMMENT @----------------------------------------------------------------------

ROUTINE:	ModRemoveWeekday

SYNOPSIS:	Removes a weekday token, if any.

CALLED BY:	CheckForFormatModifications

PASS:		ax -- token to look at
		es:di -- pointing to next character to add

RETURN:		ax -- token returned, possibly modified
		carry set if we won't use the token
		es:di -- possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@

ModRemoveWeekday	proc	near
if PZ_PCGEOS	;Koji
	cmp	ah, 'B'			;Japanese weekday token?
	je	removeIt		;if so, remve it
	cmp	ah, 'W'			;weekday token?
	clc				;assume not
	jne	exit			;branch if not
removeIt:
	stc				;now we'll remove it
else
	cmp	ah, 'W'				;weekday token?
	clc					;assume not
	jne	exit				;branch if not
	stc					;else we'll remove it
endif
exit:
	ret

ModRemoveWeekday	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	ModRemoveYear

SYNOPSIS:	Removes a year token, if any.

CALLED BY:	CheckForFormatModifications

PASS:		ax -- token to look at
		es:di -- pointing to next character to add

RETURN:		ax -- token returned, possibly modified
		carry set if we won't use the token
		es:di -- possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@

ModRemoveYear	proc	near
if PZ_PCGEOS	;Koji
	cmp	ah, 'Y'				;year token?
	je	removeIt			;remve it
	cmp	ah, 'G'				;Japanese year token?
	clc					;assume not
	jne	exit				;branch if not
removeIt:
	stc					;now we'll remove it	
else
	cmp	ah, 'Y'				;year token?
	clc					;assume not
	jne	exit				;branch if not
	stc					;else we'll remove it
endif

exit:
	ret
ModRemoveYear	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	ModRemoveMonth

SYNOPSIS:	Removes a month token, if any.

CALLED BY:	CheckForFormatModifications

PASS:		ax -- token to look at
		es:di -- pointing to next character to add

RETURN:		ax -- token returned, possibly modified
		carry set if we won't use the token
		es:di -- possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@

ModRemoveMonth	proc	near
	cmp	ah, 'M'				;month token?
	clc					;assume not
	jne	exit				;branch if not
	stc					;else we'll remove it
exit:
	ret
ModRemoveMonth	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	ModRemoveSeconds

SYNOPSIS:	Removes a seconds token, if any.

CALLED BY:	CheckForFormatModifications

PASS:		ax -- token to look at
		es:di -- pointing to next character to add

RETURN:		ax -- token returned, possibly modified
		carry set if we won't use the token
		es:di -- possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@

ModRemoveSeconds	proc	near
	cmp	ah, 's'				;seconds token?
	clc					;assume not
	jne	exit				;branch if not
	stc					;else we'll remove it
exit:
	ret
ModRemoveSeconds	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	ModRemoveMinutes

SYNOPSIS:	Removes a minutes token, if any.

CALLED BY:	CheckForFormatModifications

PASS:		ax -- token to look at
		es:di -- pointing to next character to add

RETURN:		ax -- token returned, possibly modified
		carry set if we won't use the token
		es:di -- possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@

ModRemoveMinutes	proc	near
	cmp	ah, 'm'				;minutes token?
	clc					;assume not
	jne	exit				;branch if not
	stc					;else we'll remove it
exit:
	ret
ModRemoveMinutes	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	ModUseFirstTokenInMinutes

SYNOPSIS:	If this is a minutes token, we'll look at the prefix of the
		main format's first token (the hour) and use that accordingly,
		to figure out whether zero padding is appropriate or not.
		If the guy zero or space padded the hour in the HMS format,
		we'll do the same for minutes in the MS format.

CALLED BY:	CheckForFormatModifications

PASS:		ax -- token to look at
		es:di -- pointing to next character to add

RETURN:		ax -- token returned, possibly modified
		carry set if we won't use the token
		es:di -- possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@

ModUseFirstTokenInMinutes	proc	near
	cmp	ah, 'm'				;minutes token?
	jne	exit				;branch if not
	mov	al, es:firstTokenPrefix		;use prefix of hour token
	cmp	al, 'h'				;if it was non-padded,
	je	nonPadded			;   branch to make "mm"
	cmp	al, 'H'
	jne	exit				;padded, already correct
nonPadded:
	mov	al, ah				;now 'mm' (TOKEN_MINUTE)
exit:
	clc					;use the thing in any case
	ret
ModUseFirstTokenInMinutes	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	ModRemoveHours

SYNOPSIS:	Removes a hours token, if any.

CALLED BY:	CheckForFormatModifications

PASS:		ax -- token to look at
		es:di -- pointing to next character to add

RETURN:		ax -- token returned, possibly modified
		carry set if we won't use the token
		es:di -- possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@

ModRemoveHours	proc	near
	cmp	ah, 'h'				;hours token?
	stc					;assume so
	je	exit				;branch if so
	cmp	ah, 'H'				;the other one?
	stc					;
	je	exit				;branch if so
	clc					;else we're OK
exit:
	ret
ModRemoveHours	endp

			


COMMENT @----------------------------------------------------------------------

ROUTINE:	ModRemoveAMPM

SYNOPSIS:	Removes a AMPM token, if any.  Also will delete preceding
		text if we're ignoring this thing.

CALLED BY:	CheckForFormatModifications

PASS:		ax -- token to look at
		es:di -- pointing to next character to add

RETURN:		ax -- token returned, possibly modified
		carry set if we won't use the token
		es:di -- possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@

ModRemoveAMPM	proc	near
	cmp	ah, 'p'				;AM PM token?
	je	ignore				;branch if so
	cmp	ah, 'P'				;capitalized am-pm?
	je	ignore				;yes, ignore it
	clc					;else we'll leave it alone
	jmp	short exit
ignore:
	call	RemovePrecedingText		;remove any text preceding
	stc					;we'll want to ignore it
exit:
	ret
ModRemoveAMPM	endp
		


COMMENT @----------------------------------------------------------------------

ROUTINE:	ModRemoveDay

SYNOPSIS:	Removes a day token, if any.

CALLED BY:	CheckForFormatModifications

PASS:		ax -- token to look at
		es:di -- pointing to next character to add

RETURN:		ax -- token returned, possibly modified
		carry set if we won't use the token
		es:di -- possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@

ModRemoveDay	proc	near
	cmp	ah, 'D'				;day token?
	clc					;assume not
	jne	exit				;branch if not
	stc					;else we'll remove it
exit:
	ret
ModRemoveDay	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	ModCondenseDate

SYNOPSIS:	Condenses a weekday, month, or day token, if any.

CALLED BY:	CheckForFormatModifications

PASS:		ax -- token to look at
		es:di -- pointing to next character to add

RETURN:		ax -- token returned, possibly modified
		carry set if we won't use the token
		es:di -- possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@

ModCondenseDate	proc	near
if PZ_PCGEOS	;Koji
	push	ax
	call	GetDateLanguageSelection	;get language selection
	tst	ax				;Japanese?
	pop	ax
	jnz	doCondence			;yes, Condence it
	cmp	ax, TOKEN_LONG_YEAR		;year token?
	je	exit				;yes, don't mess with it
doCondence:
else
	cmp	ax, TOKEN_LONG_YEAR		;year token?
	je	exit				;yes, don't mess with it
endif
	cmp	al, 'L'				;long day, month, or weekday?
	jne	exit				;no, exit
	mov	al, 'S'				;else we'll convert to short
exit:
	clc					;keep the token in any case
	ret
ModCondenseDate	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	ModZeroPadDate

SYNOPSIS:	Zero-pads a short weekday, month, or day token, if any.

CALLED BY:	CheckForFormatModifications

PASS:		ax -- token to look at
		es:di -- pointing to next character to add

RETURN:		ax -- token returned, possibly modified
		carry set if we won't use the token
		es:di -- possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@

ModZeroPadDate	proc	near
	cmp	ax, TOKEN_NUMERIC_MONTH		;numeric month?
	je	zeroPad				;yes, zero pad it
	cmp	ax, TOKEN_SHORT_DATE		;numeric date?
	jne	exit				;no, exit
zeroPad:
	mov	al, 'Z'				;else make zero padded
exit:
	clc					;keep the token in any case
	ret
ModZeroPadDate	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	ModConvertTo24Hour

SYNOPSIS:	Converts hour to 24-hour, if necessary.

CALLED BY:	CheckForFormatModifications

PASS:		ax -- token to look at
		es:di -- pointing to next character to add

RETURN:		ax -- token returned, possibly modified
		carry set if we won't use the token
		es:di -- possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@

ModConvertTo24Hour	proc	near
	cmp	ah, 'H'				;check for 12 hour tokens
	jne	exit				;no match, exit
	mov	ah, 'h'				;else replace with 24 hour
	cmp	al, 'H'				;if TOKEN_12HOUR
	jne	exit
	mov	al, 'h'				;then the first char changes too
exit:
	clc					;keep the token in any case
	ret
ModConvertTo24Hour	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckForTextTrimming

SYNOPSIS:	See if we need to trim trailing text.

CALLED BY:	UpdateDateFormat

PASS:		es:di -- pointing past last character deposited
		cx    -- number of tokens left to do:
				= 1 if we've done the fourth token
				= 2 if we've done the third token
		bp    -- format being built out
				
RETURN:		es:di -- possibly changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
      		Will die horribly if no tokens have been deposited

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@

CheckForTextTrimming	proc	near
	push	si
	mov	si, bp					;get modification flags
	shl	si, 1
	mov	dx, es:formatModificationTable[si]
	cmp	cx, 1					;on the last token?
	jne	10$
	test	dx, mask FAF_CLEAN_UP_AFTER_FOUR_TOKENS
	jnz	cleanup					;cleaning up, exit
	
	test	dx, mask FAF_CLEAN_UP_SPACES_AFTER_FOUR_TOKENS
	jz	exit					;not doing spaces, exit
	call	RemovePrecedingSpaces			;remove spaces
	jmp	short exit				;else go do cleanup
10$:			
	cmp	cx, 2					;on third token?
	jne	exit					;no, exit
	test	dx, mask FAF_CLEAN_UP_AFTER_THREE_TOKENS
	jz	exit					;not cleaning up, exit
cleanup:
if PZ_PCGEOS	;Koji
 	cmp	es:formatToEdit, DTF_LONG	;long date?
	jne	20$				;if not, clean up
	push	ax				;will be destroyed
	call	GetDateLanguageSelection	;get language
	tst	ax				;Japanese?
	pop	ax
	jz	20$				;if not, clean up
	cmp	bp, DTF_MONTH			;month only? clean up
	jne	exit				;no, Don't clean up
						;suffix is necessary
20$:
endif
	call	RemovePrecedingText			;remove any prev text
exit:
	pop	si
	
	ret
CheckForTextTrimming	endp

			


COMMENT @----------------------------------------------------------------------

ROUTINE:	RemovePrecedingText

SYNOPSIS:	Removes any text added before the current point.  Stops
		when it encounters a delimiter.

CALLED BY:	CheckForTextTrimming, ModRemoveAMPM

PASS:		es:di -- past last character added

RETURN:		es:di -- adjusted appropriately

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/17/91		Initial version

------------------------------------------------------------------------------@

RemovePrecedingText	proc	near
if DBCS_PCGEOS
	cmp	{wchar} es:[di]-2, TOKEN_DELIMITER	;last char a token?
	jne	removeChar				;no, remove it
	cmp	{wchar} es:[di]-4, TOKEN_TOKEN_CHAR_2    ;special non-token?
	jne	exit
	cmp	{wchar} es:[di]-6, TOKEN_TOKEN_CHAR_1    ;special non-token?
	jne	exit					;no, real token, done
	sub	di, 6					;else we'll back up
							;  over the entire token
removeChar:
	dec	di					;else nuke a character
	dec	di
else
	cmp	{byte} es:[di]-1, TOKEN_DELIMITER	;last char a token?
	jne	removeChar				;no, remove it
	cmp	{word} es:[di]-3, TOKEN_TOKEN_DELIMITER ;special non-token?
	jne	exit					;no, real token, done
	sub	di, 3					;else we'll back up
							;  over the entire token
removeChar:
	dec	di					;else nuke a character
endif
	jmp	short RemovePrecedingText
exit:
	ret
RemovePrecedingText	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	RemovePrecedingSpaces

SYNOPSIS:	Removes any text added before the current point.  Stops
		when it encounters a delimiter.

CALLED BY:	CheckForTextTrimming, ModRemoveAMPM

PASS:		es:di -- past last character added

RETURN:		es:di -- adjusted appropriately

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/17/91		Initial version

------------------------------------------------------------------------------@

RemovePrecedingSpaces	proc	near
if DBCS_PCGEOS
	cmp	{wchar} es:[di]-2, C_SPACE		;see if space
	jne	exit					;no, we're done
	dec	di					;else nuke the space
	dec	di
else
	cmp	{byte} es:[di]-1, ' '			;see if space
	jne	exit					;no, we're done
	dec	di					;else nuke the space
endif
	jmp	short RemovePrecedingSpaces
exit:
	ret
RemovePrecedingSpaces	endp




COMMENT @----------------------------------------------------------------------

METHOD:		PrefIntlReset -- 
		MSG_PREF_INTL_DIALOG_RESET for PrefIntlDialogClass

DESCRIPTION:	Resets the formats entries.

PASS:		ds 	- dgroup
		es     	- segment of MetaClass
		ax 	- MSG_PREF_INTL_DIALOG_RESET

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 6/90		Initial version

------------------------------------------------------------------------------@

PrefIntlReset	method PrefIntlDialogClass, MSG_PREF_INTL_DIALOG_RESET
	mov	cx, es:[formatToEdit]		
	call	PrefIntlDialogSelectFormat
	call	PrefIntlUpdateCurrent	;set the example
	
	ret
PrefIntlReset	endm

			
			


COMMENT @----------------------------------------------------------------------

METHOD:		PrefIntlDialogSelectFormat

DESCRIPTION:	Selects a format to edit.

PASS:		es     	- dgroup
		*ds:si  - PrefIntlDialog object
		cx	- format

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 7/90		Initial version

------------------------------------------------------------------------------@

PrefIntlDialogSelectFormat	method PrefIntlDialogClass,
					MSG_PREF_INTL_DIALOG_SELECT_FORMAT 

	mov	es:formatToEdit, cx	;store the format to use.
	
	call	SetFormatTitle		;set a nice title at the top	

	call	SetIntlEditHelpContext
		
	mov	cx, es:formatToEdit	;get our formatting choice
	cmp	cx, DTF_CURRENCY	;doing currency?	
	jne	10$
	call	SetupCurrency		;else set up currency box
	jmp	short 20$		;and skip to next choice
10$:
	mov	si, offset CurrencyInteraction
	call	PrefIntlSetNotUsable		;don't use currency stuff
20$:
	cmp	cx, DTF_DECIMAL		;doing decimal?
	jne	30$
	call	SetupDecimal		;else set up decimal box
	jmp	short 40$		;and skip to next choice
30$:
	mov	si, offset DecimalInteraction
	call	PrefIntlSetNotUsable		;don't use decimal stuff
40$:
	cmp	cx, DTF_QUOTES		;doing quotes?
	jne	50$			;no, branch
	call	SetupQuotes		;else set up quotes box
	jmp	90$
50$:
	mov	si, offset QuotesInteraction
	call	PrefIntlSetNotUsable		;don't use quotes stuff
	
	cmp	cx, DTF_END_DATE_FORMATS
	jb	setTimeDate

	cmp	cx, DTF_END_TIME_FORMATS
	jae	90$			;not doing date or time, get out

setTimeDate:
	call	SetupTimeDateCommon	;do common stuff.
	jmp	exit			;and we're done.
90$:
	mov	si, offset TimeDateInteraction
	call	PrefIntlSetNotUsable		;don't use time date stuff
exit:
	;	
	; Reset the window so it redoes its size after all this.
	;
	mov	si, offset IntlEdit
	mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
	call	SetIt
	ret
PrefIntlDialogSelectFormat	endm


			


COMMENT @----------------------------------------------------------------------

ROUTINE:	PrefIntlSetUsable, PrefIntlSetNotUsable

SYNOPSIS:	Sets an object usable.

CALLED BY:	utility

PASS:		si -- object handle

RETURN:		nothing

DESTROYED:	ax, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 7/90	Initial version

------------------------------------------------------------------------------@

PrefIntlSetUsable	proc	near
	mov	ax, MSG_GEN_SET_USABLE
	GOTO	SetIt
PrefIntlSetUsable	endp
		
PrefIntlSetNotUsable	proc	near
	mov	ax, MSG_GEN_SET_NOT_USABLE
	FALL_THRU	SetIt
PrefIntlSetNotUsable	endp
		
SetIt		proc	near
		push	cx
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
		pop	cx
		ret
SetIt		endp




COMMENT @----------------------------------------------------------------------

METHOD:		PrefIntlUpdateCurrent -- 
		MSG_PREF_INTL_DIALOG_UPDATE_CURRENT for PrefIntlDialogClass

SYNOPSIS:	Updates the current values from the appropriate UI gadgets,
		and updates the example gadgets.

PASS:		nothing

RETURN:		nothing

DESTROYED:	bx, si, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/10/90		Initial version

------------------------------------------------------------------------------@

PrefIntlUpdateCurrent	method PrefIntlDialogClass, 
				       MSG_PREF_INTL_DIALOG_UPDATE_CURRENT
	uses	ax, cx
	.enter

	mov	cx, es:formatToEdit		;get the current format
	
	cmp	cx, DTF_CURRENCY		;doing currency?	
	jne	checkDecimal

	;
	; Update the currency example
	;
	call	UpdateCurrencyValues
	call	UpdateCurrencyExample		;update currency example
	jmp	setFullExample			;set it

checkDecimal:
	cmp	cx, DTF_DECIMAL			;doing decimal?
	jne	checkQuotes
	;
	; Update the decimal example
	;
	call	UpdateDecimalValues
	call	UpdateDecimalExample
	jmp	setFullExample			;and finish up

checkQuotes:
	cmp	cx, DTF_QUOTES			;doing quotes?
	jne	checkTimeDate			;no, branch
	;
	; Update the quotes example
	;
	call	UpdateQuoteValues

	push	ds
	segmov	ds, es
	mov	si, offset exampleQuoteText	;copy to tempExampleBuffer
	mov	di, offset tempExampleBuffer
	LocalCopyString
	pop	ds
		
	jmp	setFullExample

checkTimeDate:
	;
	; Update the time/date stuff.
	;
	;
	; Update the current string from the appropriate gadgets.
	;
	mov	cx, es:formatToEdit		;this is the format we'll use
	call	UpdateDateFormat
	
;	call	TimerGetDateAndTime		;use today's date

	mov	ax, 1994			;use my own example now:
	mov	bx, 9 shl 8 or 3		;Monday, 9 Mar 1994
	mov	cx, 8 shl 8 or 1		; 8:05:04
	mov	dx, 4 shl 8 or 5

	push	ds
	segmov	ds, es
	mov	si, offset formatCurrent
	mov	di, offset tempExampleBuffer
	call	LocalCustomFormatDateTime	;get localized date/time
	pop	ds

setFullExample:
	mov	si, offset tempExampleBuffer
	mov	di, offset exampleBuffer	;example changed?
	call	CmpString	
	je	exit				;no, exit
	
	;
	; Set the example in the edit dialog box.
	;

	mov	bp, offset tempExampleBuffer	;here's our text
	mov	si, offset ExampleText		;object to set
	push	bp
	call	PrefIntlSetText			;set it
	pop	bp
	
	;
	; Set the example in the format list dialog box.  We're hoping that
	; example buffer has been set up at this point.
	;

	mov	si, offset IntlExample	;object to set
	call	PrefIntlSetText			;set it

	
	;
	; For time and date, we have other format examples to show.
	;
	call	DoOtherExamples			;do examples of related formats
	
	;
	; Formally set the exampleBuffer now.
	;
	push	ds
	segmov	ds, es
	mov	si, offset tempExampleBuffer	;copy to exampleBuffer
	mov	di, offset exampleBuffer
	LocalCopyString
	pop	ds

exit:
	.leave
	ret
	
PrefIntlUpdateCurrent	endm

CmpString	proc	near
	uses	ds, cx
	.enter
	clr	cx
	segmov	ds, es
	call	LocalCmpStrings
	.leave
	ret
CmpString	endp


				


COMMENT @----------------------------------------------------------------------

ROUTINE:	DoOtherExamples

SYNOPSIS:	If doing date or time, put up other examples.  Will avoid 
		setting an object with the main format here.

CALLED BY:	PrefIntlUpdateCurrent

PASS:		 -- dgroup

RETURN:		es:otherExampleBuffer -- should match tempExampleBuffer

DESTROYED:	

PSEUDO CODE/STRATEGY:
       set the text for all related formats, example the last one in the list
       		(which the base format) and a couple of lame examples.
       after we've found all the ones we want to print, we'll zero the text
       		for any objects left over.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/16/91		Initial version

------------------------------------------------------------------------------@
DISTANCE_BETWEEN_EXAMPLES = 2
			  
DoOtherExamples	proc	near
	CheckHack <DISTANCE_BETWEEN_EXAMPLES eq (offset IntlExample4 - \
			offset IntlExample3)>
	CheckHack <DISTANCE_BETWEEN_EXAMPLES eq (offset IntlExample5 - \
			offset IntlExample4)>
	CheckHack <DISTANCE_BETWEEN_EXAMPLES eq (offset IntlExample6 - \
			offset IntlExample5)>
	CheckHack <DISTANCE_BETWEEN_EXAMPLES eq (offset IntlExample7 - \
			offset IntlExample6)>
		
	call	GetRelatedFormatList		;es:si <- list of formats
	tst	si				;anything to do?
	jnz	10$				;yes, branch
	mov	si, offset otherFormats		;else pass this hack that
10$:						;   will null out all examples
	mov	di, offset IntlExample2	;first place to put example
	
doExample:
	mov	cl, es:[si]			;get a format
	clr	ch
	cmp	cl, DTF_MONTH			;skip these
	je	nextExample
	cmp	cl, DTF_WEEKDAY
	je	nextExample
	
	push	si

	mov	si, cx				;keep format in si
	mov	ax, 1994			;use my own example now:
	mov	bx, 9 shl 8 or 3		;Monday, 9 Mar 1994
	mov	cx, 8 shl 8 or 1		; 8:05:04
	mov	dx, 4 shl 8 or 5
	
	push	di
	mov	di, offset otherExampleBuffer	;es:di - place to store string
	call	LocalFormatDateTime		;get localized date/time
	pop	di

	pop	si
	
	cmp	di, offset IntlExample7		;past the last example?
	ja	exit				;yes, we're all done now
	
	push	si
	mov	bp, offset otherExampleBuffer	;here's our text
	
	cmp	{byte} es:[si]+1, -1		;are we on the last example?
	jnz	setObject			;no, set object
	mov	bp, offset nullTerminator 	;else store a null string 
	
setObject:
	mov	si, di				;pass object to set
	call	PrefIntlSetText			;set it
	pop	si				;restore pointer
	
nextExample:
	cmp	{byte} es:[si]+1, -1		;are we on the last example?
	jz	nextObject			;yes, stay there, we
						;won't use it

	inc	si				;else move to next exmaple
	
nextObject:
	add	di, DISTANCE_BETWEEN_EXAMPLES	;next object
	jmp	doExample			;do another one

exit:
	ret
DoOtherExamples	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateCurrencyExample

SYNOPSIS:	Figures out an example for the currency format.

CALLED BY:	PrefIntlUpdateCurrent

PASS:		es -- dgroup

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
        if !useNegativeSign
       		add '('
	if useNegativeSign & negativeSignInFront & negativeBeforeSymbol
		add '-'
	if symInFront
		add symbol
	if symInFront & spaceAroundSymbol
		add ' ' 
	if useNegativeSign & negativeInFront & !negativeBeforeSymbol
		add '-'
	if leadingZero
		add '0'
	add '.'
	for  i = 1 to decimalPlaces add '9'
	if useNegativeSign & !negativeInFront & negativeBeforeSymbol
		add '-'
	if !symInFront $ spaceAroundSymbol
		add ' '
	if !symInFront
		add symbol
	if useNegativeSign & !negativeInFront & !negativeBeforeSymbol
		add '-'
	if !useNegativeSign
       		add ')'

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 3/91		Initial version

------------------------------------------------------------------------------@
	
UpdateCurrencyExample	proc	near
	mov	di, offset tempExampleBuffer	;place to put new example
	
	mov	cx, (mask CFF_USE_NEGATIVE_SIGN) shl 8
	mov	al, '('
	call	AddToExampleIfNeeded		
	
	mov	cx, mask CFF_USE_NEGATIVE_SIGN or \
		    mask CFF_NEGATIVE_SIGN_BEFORE_NUMBER or \
		    mask CFF_NEGATIVE_SIGN_BEFORE_SYMBOL
	mov	al, '-'
	call	AddToExampleIfNeeded
	
	mov	cx, mask CFF_SYMBOL_BEFORE_NUMBER
	clr	al				;this means add the symbol
	call	AddToExampleIfNeeded
	
	mov	cx, mask CFF_SYMBOL_BEFORE_NUMBER or \
		    mask CFF_SPACE_AROUND_SYMBOL
	mov	al, ' '
	call	AddToExampleIfNeeded
	
	mov	cx, mask CFF_USE_NEGATIVE_SIGN or \
		    mask CFF_NEGATIVE_SIGN_BEFORE_NUMBER or \
		    (mask CFF_NEGATIVE_SIGN_BEFORE_SYMBOL shl 8)
	mov	al, '-'
	call	AddToExampleIfNeeded
	
SBCS <	mov	ax, '3' shl 8 or '1'					>
SBCS <	stosw								>
DBCS <	mov	ax, '1'							>
DBCS <	stosw								>
DBCS <	mov	ax, '3'							>
DBCS <	stosw								>

	mov	cl, es:currentCurrencyDigits
	clr	ch
	jcxz	10$

SBCS <	mov	al, es:currentDecimalSeparator				>
SBCS <	stosb								>
DBCS <	mov	ax, es:currentDecimalSeparator				>
DBCS <	stosw								>
	
SBCS <	mov	al, '2'				;fill out after decimal with 9's>
DBCS <	mov	ax, '2'				;fill out after decimal with 9's>
	cmp	cx, 10				;don't print too many digits
	jbe	5$
	mov	cx, 10
5$:
SBCS <	rep	stosb							>
DBCS <	rep	stosw							>
10$:
	mov	cx, mask CFF_USE_NEGATIVE_SIGN or \
		    (mask CFF_NEGATIVE_SIGN_BEFORE_NUMBER shl 8) or \
		    mask CFF_NEGATIVE_SIGN_BEFORE_SYMBOL
	mov	al, '-'
	call	AddToExampleIfNeeded
	
	mov	cx, (mask CFF_SYMBOL_BEFORE_NUMBER shl 8) or \
		    mask CFF_SPACE_AROUND_SYMBOL
	mov	al, ' '
	call	AddToExampleIfNeeded
	
	mov	cx, (mask CFF_SYMBOL_BEFORE_NUMBER shl 8)
	clr	al				;this means add the symbol
	call	AddToExampleIfNeeded
	
	mov	cx, mask CFF_USE_NEGATIVE_SIGN or \
		    (mask CFF_NEGATIVE_SIGN_BEFORE_NUMBER shl 8) or \
		    (mask CFF_NEGATIVE_SIGN_BEFORE_SYMBOL shl 8)
	mov	al, '-'
	call	AddToExampleIfNeeded
	
	mov	cx, (mask CFF_USE_NEGATIVE_SIGN) shl 8
	mov	al, ')'
	call	AddToExampleIfNeeded		
	
DBCS <	clr	ax							>
DBCS <	stosw					;null byte		>
SBCS <	clr	al							>
SBCS <	stosb					;null byte		>
	ret
UpdateCurrencyExample	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	AddToExampleIfNeeded

SYNOPSIS:	Adds a character to the example if the appropriate flags are
		set or cleared.

CALLED BY:	UpdateCurrencyExample

PASS:		es:di 	-- point to dest buffer
		al	-- character to add if needed
		cl	-- flags which must be set in currentCurrencyFlags
		ch	-- flags which must be cleared in currentCurrencyFlags

RETURN:		es:di 	-- updated appropriately

DESTROYED:	dl, ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 3/91		Initial version

------------------------------------------------------------------------------@

AddToExampleIfNeeded	proc	near
	mov	dl, cl				;get flags that should be set
	mov	dh, es:currentCurrencyFlags	;get current flags
	and	dl, dh				;AND with flags
	cmp	dl, cl				;still all set?
	jne	exit				;no, get out
	
	not	dh				;invert current flags
	and	dh, ch				;AND with flags to be cleared
	cmp	dh, ch				;are they all there?
	jne	exit				;no, get out
	
 	tst	al				;do we want to store
						;the symbol?
	jz	doSymbol			;yes, go do it
SBCS <	stosb					;else store the character>
DBCS <	clr	ah				;SBCS -> DBCS		>
DBCS <	stosw					;else store the character>
	jmp	exit				;and exit

doSymbol:
	push	ds
	segmov	ds, es
	mov	si, offset currentCurrencySymbol
	LocalCopyString
	pop	ds

DBCS <	dec	di							>
	dec	di				;back up before null byte
exit:
	ret
AddToExampleIfNeeded	endp


			


COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateDecimalExample

SYNOPSIS:	Updates the decimal example.

CALLED BY:	PrefIntlUpdateCurrent

PASS:		es -- dgroup

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di,si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 3/91		Initial version

------------------------------------------------------------------------------@

UpdateDecimalExample	proc	near

	mov	di, offset tempExampleBuffer	;place to put new example
	
if DBCS_PCGEOS
	mov	ax, '1'
	stosw
	mov	ax, '3'
	stosw
	mov	ax, es:currentThousandsSeparator
	stosw
	mov	ax, '1'
	stosw
	mov	ax, '4'
	stosw
	mov	ax, '5'
	stosw
else
	mov	ax, '3' shl 8 or '1'
	stosw
	mov	al, es:currentThousandsSeparator
	stosb
	mov	ax, '4' shl 8 or '1'
	stosw
	mov	al, '5'
	stosb
endif

	mov	cl, es:currentDecimalDigits
	clr	ch
	tst	cl
	jz	10$

if DBCS_PCGEOS
	mov	ax, es:currentDecimalSeparator
	stosw
	mov	ax, '2'				;fill out after decimal with 9's
	cmp	cx, 10				;don't print too many digits
	jbe	5$
	mov	cx, 10
5$:
	rep	stosw
10$:
	mov	ax, C_SPACE			;stick in a space
	stosw
else
	mov	al, es:currentDecimalSeparator
	stosb
	mov	al, '2'				;fill out after decimal with 9's
	cmp	cx, 10				;don't print too many digits
	jbe	5$
	mov	cx, 10
5$:
	rep	stosb
10$:
	mov	al, ' '				;stick in a space
	stosb
endif
	
	push	ds
	mov	bx, handle Strings
	call	MemLock
	mov	ds, ax				;ds points to Strings chunk
	
	mov	si, offset inText		;assume inches
	tst	es:currentMeasurementType
	jz	20$				;we are doing US, branch
	mov	si, offset cmText		;else use "cm"
20$:
	mov	si, ds:[si]			;dereference source string

	LocalCopyString

	call	MemUnlock
	pop	ds				;restore ds

	ret
UpdateDecimalExample	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefIntlSetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text in the text object

CALLED BY:	SetupDecimal, SetupCurrency, SetTextFromAL

PASS:		*ds:si - text object
		bp - offset in dgroup to text buffer

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/22/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefIntlSetText		proc near
		uses	ax,cx,dx
		.enter
		
		mov	dx, segment dgroup
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		clr	cx			;specify null termination
		call	ObjCallInstanceNoLock
		.leave
		ret
		
PrefIntlSetText		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefIntlSetValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the GenValue

CALLED BY:	

PASS:		*ds:si - GenValue object
		cx - value to set

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/22/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefIntlSetValue	proc	near
		uses	ax,cx,dx,bp
		.enter
		clr	bp
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		call	ObjCallInstanceNoLock
		.leave
		ret
PrefIntlSetValue	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefIntlSetSpin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the value for a Custom Spin object

CALLED BY:	

PASS:		cx - value to store

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/22/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefIntlSetSpin	proc	near
	uses	ax, cx, dx, bp
	.enter
	clr	bp
	mov	ax, MSG_CUSTOM_SPIN_SET_VALUE
	call	ObjCallInstanceNoLock

	mov	cx, si				;mark modified
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	ObjCallInstanceNoLock
	.leave
	ret
PrefIntlSetSpin	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	PrefIntlGetValue

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		*ds:si  - od of GenValue object

RETURN:		cx - value

DESTROYED:	ax,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

------------------------------------------------------------------------------@

PrefIntlGetValue	proc	near
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	call	ObjCallInstanceNoLock
	mov	cx, dx			; just return integer
	ret
PrefIntlGetValue	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	PrefIntlGetTextIntoBuffer

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		*ds:si - text object
		es:dx - pointer to buffer 

RETURN:		cx - number of characters retrieved (not including null term)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

------------------------------------------------------------------------------@

PrefIntlGetTextIntoBuffer	proc	near
	uses dx, bp
	.enter

	mov	bp, dx
	mov	dx, es
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjCallInstanceNoLock 

	.leave
	ret

PrefIntlGetTextIntoBuffer	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	PrefIntlGetSpin

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		*ds:si - custom spin object

RETURN:		cx - spin value

DESTROYED:	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

------------------------------------------------------------------------------@

PrefIntlGetSpin	proc	near
	uses	dx, bp
	.enter

	mov	ax, MSG_CUSTOM_SPIN_GET_VALUE
	call	ObjCallInstanceNoLock
	.leave
	ret
PrefIntlGetSpin	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	DoError

DESCRIPTION:	Beeps and puts up error message

CALLED BY:	CheckForBadFormats

PASS:		^lbx:si - OD of error string


RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version
	Chris	1/ 2/91		Expanded to handle arguments

------------------------------------------------------------------------------@

DoError	proc	near
		clr	ax
		push	ax, ax		; SDOP_helpContext
		push	ax, ax		; SDOP_customTriggers
		push	ax, ax		; SDOP_stringArg2
		push	ax, ax		; SDOP_stringArg1
		push	bx, si		; SDOP_customString

		mov	ax, (CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
		    (GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	

		push	ax		; SDOP_customFlags

	CheckHack <size StandardDialogOptrParams eq 22>

		call	UserStandardDialogOptr

		ret
DoError	endp


if PZ_PCGEOS	;Koji
COMMENT @----------------------------------------------------------------------

METHOD:		PrefIntlDateSelectLanguage

DESCRIPTION:	Select date format.

PASS:		es     	- dgroup
		*ds:si  - PrefIntlDialog object
		cx	- DateLanguage selection value
			TRUE	- Japanese
			FALSE	- English

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	koji	9/10/93		Initial version

------------------------------------------------------------------------------@

PrefIntlDateSelectLanguage		method PrefIntlDialogClass,
				MSG_PREF_INTL_DATE_SELECT_LANGUAGE
	push	cx
	call	SaveDateSpin		;save current date format
	call	SetAllSpinsMinMax	;set Japanese or English Spin
	pop	cx			;cx <- DateLanguage selection
	call	SetDateDefault		;set new date format
	call	PrefIntlUpdateCurrent
	ret
PrefIntlDateSelectLanguage		endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	SaveDateSpin

SYNOPSIS:	save current Date text.

CALLED BY:	PrefIntlDateSelectLanguage

PASS:		es     	- dgroup
		*ds:si  - PrefIntlDialog object

RETURN:		nothing

DESTROYED:	ax, cx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	koji	9/15/93		Initial version

------------------------------------------------------------------------------@

SaveDateSpin			proc	near
	mov	si, offset FormatElement2
	call	PrefIntlGetSpin			;get current spin value
	mov	es:currentDateSpin1, cx		;save it
	mov	si, offset FormatElement4
	call	PrefIntlGetSpin			;get current spin value
	mov	es:currentDateSpin2, cx		;save it
	mov	si, offset FormatElement6
	call	PrefIntlGetSpin			;get current spin value
	mov	es:currentDateSpin3, cx		;save it
	mov	si, offset FormatElement8
	call	PrefIntlGetSpin			;get current spin value
	mov	es:currentDateSpin4, cx		;save it
	ret
SaveDateSpin			endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	SetDateDefault

SYNOPSIS:	set Date format text.

CALLED BY:	PrefIntlDateSelectLanguage

PASS:		es     	- dgroup
		*ds:si  - PrefIntlDialog object
		cx	- DateLanguage selection value
			TRUE	- Japanese
			FALSE	- English

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	get current Spin value of FormatElement.
	if current Spin value is out of range
		set default value to FormatElements
	endif
	if Japanese
		set Japanese default (1994Nen 3Gatu 9Ka Getuyobi)
	else
		set English default (Monday, March 9th, 1994)
	endif

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	koji	9/14/93		Initial version

------------------------------------------------------------------------------@
SetDateDefault		proc	near
	mov	si, offset FormatElement2	;ds:si - element to set
	mov	dx, es:currentDateSpin1		;dx - current Spin value
	jcxz	setUsFormat			;not Japanese? set US format
	mov	cx, DTT_LONG_YEAR		;cx - default: 1994
	call	ReplaceSpinValue		;set Spin value
	mov	si, offset FormatElement4
	mov	dx, es:currentDateSpin2
	mov	cx, DTT_NUMERIC_MONTH		;cx - default: 3
	call	ReplaceSpinValue		;set Spin value
	mov	si, offset FormatElement6
	mov	dx, es:currentDateSpin3
	mov	cx, DTT_SHORT_DATE		;cx - default: 9
	call	ReplaceSpinValue		;set Spin value
	mov	si, offset FormatElement8
	mov	dx, es:currentDateSpin4
	mov	cx, DTT_LONG_WEEKDAY_JP		;cx - default: Getuyobi
	call	ReplaceSpinValue		;set Spin value

	mov	si, offset FormatElement3	;ds:si - elemnt to set
	mov	bp, offset JpDateSeparator1	;dx:bp - text: Nen
	call	PrefIntlSetChunkToText		;set text
	mov	si, offset FormatElement5
	mov	bp, offset JpDateSeparator2	;dx:bp - text: Gatu
	call	PrefIntlSetChunkToText		;set text
	mov	bp, offset JpDateSeparator3	;dx:bp - text: Ka
	jmp	done
setUsFormat:					;set US format
	mov	cx, DTT_LONG_WEEKDAY		;cx - default: Monday
	call	ReplaceSpinValue		;set Spin value
	mov	si, offset FormatElement4
	mov	dx, es:currentDateSpin2
	mov	cx, DTT_LONG_MONTH		;cx - default: March
	call	ReplaceSpinValue		;replace Spin value
	mov	si, offset FormatElement6
	mov	dx, es:currentDateSpin3
	mov	cx, DTT_LONG_DATE		;cx - default: 9th
	call	ReplaceSpinValue		;set Spin value
	mov	si, offset FormatElement8
	mov	dx, es:currentDateSpin4
	mov	cx, DTT_LONG_YEAR		;cx - default: 1994
	call	ReplaceSpinValue		;set Spin value

	mov	si, offset FormatElement3	;ds:si - elemnt to set
	mov	bp, offset UsDateSeparator1	;dx:bp - text
	call	PrefIntlSetChunkToText		;set text
	mov	si, offset FormatElement5
	mov	bp, offset UsDateSeparator2	;dx:bp - text
	call	PrefIntlSetChunkToText		;set text
	mov	bp, offset UsDateSeparator1	;dx:bp - text
done:
	mov	si, offset FormatElement7	;ds:si - object to set
	call	PrefIntlSetChunkToText		;set text
	ret
SetDateDefault		endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	ReplaceSpinValue

SYNOPSIS:	replace spin value

PASS:		es     	- dgroup
		*ds:si  - custom spin object
		cx	- new value (default)
		dx	- old value

CALLED BY:	setDateDefault

RETURN:		nothing

DESTROYED:	ax, bx, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if value is out of range
		set new Spin value
	endif

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	koji	9/14/93		Initial version

------------------------------------------------------------------------------@
ReplaceSpinValue	proc	near
	mov	ax, MSG_CUSTOM_SPIN_GET_MIN_MAX	;get spin min max
	call	ObjCallInstanceNoLock		;al - min, ah - max
	cmp	dl, al				;old value < min ? set new
	jl	doIt
	cmp	dl, ah				;old value > max ? set new
	jg	doIt
	mov	cx, dx				;set old value
doIt:
	call	PrefIntlSetSpin			;set spin value
	ret
ReplaceSpinValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefIntlSetChunkToText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the chunk in the text object

CALLED BY:	setDateDefault

PASS:		*ds:si - text object
		bp - offset in String block to chunk

RETURN:		nothing 

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       koji	11/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefIntlSetChunkToText		proc near
	mov	dx, handle Strings			;^ldx:bp - chunk
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR 	;chunk -> text obj
	clr	cx					;null terminated
	call	ObjCallInstanceNoLock
	ret
PrefIntlSetChunkToText		endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	GetDateLanguageFromInitFile

SYNOPSIS:	get date language from .ini file.

CALLED BY:	SetupTimeDateCommon

PASS:		nothing

RETURN:		ax	- DateLanguage
			TRUE 	- Japanese
			FALSE	- English

DESTROYED:	cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	koji	10/22/93	Initial version

------------------------------------------------------------------------------@
GetDateLanguageFromInitFile	proc	near
	push	ds
	mov	cx, cs
	mov	dx, offset dateLanguageKey	;cx:dx <- key
	mov	ds, cx
	mov	si, offset dateLanguageCategory	;ds:si <- category
	mov	ax, TRUE			;set default as Japanese
	call	InitFileReadBoolean		;look into .ini file
	pop	ds
	ret
GetDateLanguageFromInitFile	endp

COMMENT @----------------------------------------------------------------------

ROUTINE:	SetDateLanguageToInitFile

SYNOPSIS:	set date language to .ini file.

CALLED BY:	PrefIntlApply

PASS:		ax	- DateLanguage
			TRUE	- Japanese
			FALSE	- English

RETURN:		nothing

DESTROYED:	cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	koji	10/22/93	Initial version

------------------------------------------------------------------------------@
SetDateLanguageToInitFile	proc	near
	push	ds
	mov	cx, cs
	mov	dx, offset dateLanguageKey	;cx:dx <- key
	mov	ds, cx
	mov	si, offset dateLanguageCategory	;ds:si <- category
	call	InitFileWriteBoolean		;put it into .ini file
	pop	ds
	ret
SetDateLanguageToInitFile	endp

dateLanguageCategory	char	"dateLanguage", 0
dateLanguageKey		char	"Japanese", 0

endif



