COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		formatUI.asm

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial revision

DESCRIPTION:
	Routines that take care of updating the format representation
	and sample numbers in the number formatting dialog boxes.
	These routines run under the UI thread so that things are
	synchronized.
		
	$Id: uiFormat.asm,v 1.1 97/04/04 15:48:24 newdeal Exp $

-------------------------------------------------------------------------------@


UITrans segment resource

if 0
COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatNumDecimals
		FormatDecimalOffset
		FormatFixed
		FormatScientific
		FormatCommas
		FormatPercentage
		FormatLeadZero
		FormatTrailZeros
		FormatHeaderSignPos
		FormatTrailerSignPos

DESCRIPTION:	Method handlers to update the float parameters with
		the user changes.

CALLED BY:	INTERNAL ()

PASS:		

RETURN:		nothing

DESTROYED:	everything

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FormatNumDecimals	method dynamic DisplayTransClass,
	MSG_FORMAT_NUM_DECIMALS
	mov	si, offset UIFmtNumDecimals
	call	GetRange			; cx <- range value
	push	es
	GetResourceSegmentNS dgroup, es		; es = dgroup
	mov	es:curSelection.FP_params.FFAP_FLOAT.decimalLimit, cl
	pop	es
	call	FormatUpdateSamples
	ret
FormatNumDecimals	endm

FormatDecimalOffset	method dynamic DisplayTransClass,
	MSG_FORMAT_DECIMAL_OFFSET
	mov	si, offset UIFmtDecimalOffset
	call	GetRange			; cx <- range value
	mov	es:curSelection.FP_params.FFAP_FLOAT.decimalOffset, cl
	call	FormatUpdateSamples
	ret
FormatDecimalOffset	endm

FormatFixed		method dynamic DisplayTransClass,
	MSG_FORMAT_FIXED
	and	es:curSelection.FP_params.FFAP_FLOAT.formatFlags, not mask FFAF_SCIENTIFIC
	call	FormatUpdateSamples
	ret
FormatFixed		endm

FormatScientific	method dynamic DisplayTransClass,
	MSG_FORMAT_SCIENTIFIC
	or	es:curSelection.FP_params.FFAP_FLOAT.formatFlags, mask FFAF_SCIENTIFIC
	call	FormatUpdateSamples
	ret
FormatScientific	endm

FormatCommas		method dynamic DisplayTransClass,
	MSG_FORMAT_COMMAS
	mov	ax, mask FFAF_USE_COMMAS
	mov	si, offset UIFmtComma
	call	FormatHandleBoolean
	ret
FormatCommas		endm

FormatPercentage	method dynamic DisplayTransClass,
	MSG_FORMAT_PERCENTAGE
	mov	ax, mask FFAF_PERCENT
	mov	si, offset UIFmtPct
	call	FormatHandleBoolean
	ret
FormatPercentage	endm

FormatLeadZero		method dynamic DisplayTransClass,
	MSG_FORMAT_LEAD_ZERO
	mov	ax, mask FFAF_NO_LEAD_ZERO
	mov	si, offset UIFmtLead0
	call	FormatHandleBoolean
	ret
FormatLeadZero		endm

FormatTrailZeros	method dynamic DisplayTransClass,
	MSG_FORMAT_TRAIL_ZEROS
	mov	ax, mask FFAF_NO_TRAIL_ZEROS
	mov	si, offset UIFmtTrailZero
	call	FormatHandleBoolean
	ret
FormatTrailZeros	endm

FormatHeaderSignPos	method dynamic DisplayTransClass, 
	MSG_FORMAT_HEADER_SIGN_POS
	mov	ax, mask FFAF_SIGN_CHAR_TO_FOLLOW_HEADER
	mov	si, offset UIFmtHeaderSignPos
	call	FormatHandleBoolean
	ret
FormatHeaderSignPos	endm

FormatTrailerSignPos	method dynamic DisplayTransClass,
	MSG_FORMAT_TRAILER_SIGN_POS
	mov	ax, mask FFAF_SIGN_CHAR_TO_PRECEDE_TRAILER
	mov	si, offset UIFmtTrailerSignPos
	call	FormatHandleBoolean
	ret
FormatTrailerSignPos	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatHandleBoolean

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		ax - bit mask that will be used to set or clear in
		     curSelection.FP_params.FFAP_FLOAT.formatFlags
		si - offset to list entry
		es - dgroup

RETURN:		nothing

DESTROYED:	ax,bx,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FormatHandleBoolean	proc	near
	push	es
	GetResourceSegmentNS dgroup, es	; es = dgroup
	push	ax			; save bit mask
	call	GetUserState
	pop	ax			; retrieve bit mask

	mov	di, offset curSelection.FP_params.FFAP_FLOAT.formatFlags
	jnz	selected

	not	ax
	and	es:[di], ax		; clear bit
	jmp	short done

selected:
	or	es:[di], ax		; set bit

done:
	pop	es
	GOTO	FormatUpdateSamples
FormatHandleBoolean	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatHandleChar

DESCRIPTION:	Intercepts MSG_META_TEXT_USER_MODIFIED so that the samples can be
		updated as the user types.

CALLED BY:	INTERNAL ()

PASS:		cx:dx - od of text edit object

RETURN:		nothing

DESTROYED:	ax,bx,cx,di,si,ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FormatHandleChar	method dynamic DisplayTransClass,
	MSG_META_TEXT_USER_MODIFIED

	GetResourceSegmentNS dgroup, es	; es = dgroup
	push	cx,dx			; save od
	cmp	dx, offset UIFmtPreNegative
	mov	di, offset curSelection.FP_params.FFAP_FLOAT.preNegative
	je	updateSamples

	cmp	dx, offset UIFmtPostNegative
	mov	di, offset curSelection.FP_params.FFAP_FLOAT.postNegative
	je	updateSamples

	cmp	dx, offset UIFmtPrePositive
	mov	di, offset curSelection.FP_params.FFAP_FLOAT.prePositive
	je	updateSamples

	cmp	dx, offset UIFmtPostPositive
	mov	di, offset curSelection.FP_params.FFAP_FLOAT.postPositive
	je	updateSamples

	cmp	dx, offset UIFmtHeader
	mov	di, offset curSelection.FP_params.FFAP_FLOAT.header
	je	updateSamples

	cmp	dx, offset UIFmtTrailer
	mov	di, offset curSelection.FP_params.FFAP_FLOAT.trailer
	je	updateSamples

	pop	ax			; clear stack
	pop	ax
	jmp	short exit

updateSamples:
	mov	si, dx			; si <- offset
	push	di			; save var offset
	call	GetText			; bx <- handle, if any
	pop	di
	jc	clearEntry

	call	MemLock
	mov	ds, ax
	clr	si
	LocalCopyString			; from vistext to our buffer

	call	MemFree

done:
	call	FormatUpdateSamples

	pop	bx,si			; retrieve od
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	clr	di
	call	ObjMessage

exit:
	ret

clearEntry:
SBCS<	clr	al						>
DBCS<	clr	ax						>
	LocalPutChar	esdi, ax
	jmp	short done
FormatHandleChar	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatUpdateSamples

DESCRIPTION:	

CALLED BY:	INTERNAL
			(FormatNumDecimals,
			FormatDecimalOffset,
			FormatFixed,
			FormatScientific,
			FormatCommas,
			FormatPercentage,
			FormatLeadZero,
			FormatTrailZeros,
			FormatHeaderSignPos,
			FormatTrailerSignPos,
			FormatHandleChar)

PASS:		nothing

RETURN:		nothing

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	We send a message off to the process because we are running under
	the UI thread and the UI thread does not have a floating point
	stack initialized.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FormatUpdateSamples	proc	near
	mov	ax, MSG_FORMAT_UPDATE_USER_DEF_SAMPLES
	push	es
	GetResourceSegmentNS dgroup, es
	mov	bx, es:processHandle
	pop	es
	clr	di
	call	ObjMessage
	ret
FormatUpdateSamples	endp

endif

UITrans ends
