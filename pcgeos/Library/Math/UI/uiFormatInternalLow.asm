COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 10/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial revision

DESCRIPTION:
		
	$Id: uiFormatInternalLow.asm,v 1.1 97/04/05 01:23:24 newdeal Exp $

-------------------------------------------------------------------------------@

FloatFormatCode	segment	resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatNumDecimals,
		FormatDecimalOffset

DESCRIPTION:	Method handlers to update the float parameters with
		the user changes.

CALLED BY:	INTERNAL ()

PASS:		*ds:si - controller instance
		ds:di - controller instance

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

FormatNumDecimals	method dynamic FloatFormatClass,
	MSG_FORMAT_NUM_DECIMALS

	mov	di, offset UIFmtNumDecimals
	call	GetRange			; cx <- range value

	call	DerefDI
	mov	bx, ds:[di].formatInfoStrucHan
	call	MemLock
	mov	es, ax

	mov	es:FIS_curParams.FP_params.FFAP_FLOAT.decimalLimit, cl
	call	FormatUpdateSamples

	call	MemUnlock
	ret
FormatNumDecimals	endm

FormatDecimalOffset	method dynamic FloatFormatClass,
	MSG_FORMAT_DECIMAL_OFFSET

	mov	di, offset UIFmtDecimalOffset
	call	GetRange			; cx <- range value

	call	DerefDI
	mov	bx, ds:[di].formatInfoStrucHan
	call	MemLock
	mov	es, ax

	mov	es:FIS_curParams.FP_params.FFAP_FLOAT.decimalOffset, cl
	call	FormatUpdateSamples

	call	MemUnlock
	ret
FormatDecimalOffset	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatOptionStyleChange

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

FormatOptionStyleChange	method	dynamic FloatFormatClass,
			MSG_FORMAT_OPTION_STYLE_CHANGE

	mov	bx, ds:[di].formatInfoStrucHan
	call	MemLock
	mov	es, ax

	tst	cx
	jne	scientificChosen

	and	es:FIS_curParams.FP_params.FFAP_FLOAT.formatFlags, \
		not mask FFAF_SCIENTIFIC
	jmp	short done

scientificChosen:
	or	es:FIS_curParams.FP_params.FFAP_FLOAT.formatFlags, \
		mask FFAF_SCIENTIFIC

done:
	call	FormatUpdateSamples
	call	MemUnlock
	ret
FormatOptionStyleChange	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatOptionBooleanChange

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		cx - booleans selected
		bp - booleans changed

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

FormatOptionBooleanChange	method	dynamic FloatFormatClass,
				MSG_FORMAT_OPTION_BOOLEAN_CHANGE
	mov	dx, cx
	and	dx, bp		; dx <- bits to set

	not	cx
	and	cx, bp		; cx <- bits to clear

	mov	bx, ds:[di].formatInfoStrucHan
	push	bx
	call	MemLock
	mov	es, ax
EC<	call	ECCheckFormatInfoStruc_ES >

	mov	ax, mask FFAF_USE_COMMAS
	mov	bx, mask FO_COMMA
	call	FormatHandleBoolean

	mov	ax, mask FFAF_PERCENT
	mov	bx, mask FO_PCT
	call	FormatHandleBoolean

	mov	ax, mask FFAF_NO_LEAD_ZERO
	mov	bx, mask FO_LEAD_ZERO
	call	FormatHandleBoolean

	mov	ax, mask FFAF_NO_TRAIL_ZEROS
	mov	bx, mask FO_TRAIL_ZERO
	call	FormatHandleBoolean

	mov	ax, mask FFAF_SIGN_CHAR_TO_FOLLOW_HEADER
	mov	bx, mask FO_HEADER_SIGN_POS
	call	FormatHandleBoolean

	mov	ax, mask FFAF_SIGN_CHAR_TO_PRECEDE_TRAILER
	mov	bx, mask FO_TRAILER_SIGN_POS
	call	FormatHandleBoolean

	pop	bx
	call	MemUnlock
	ret
FormatOptionBooleanChange	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatHandleBoolean

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		ax - bit mask that will be used to set or clear format flags
		cx - boolean that has been cleared
		dx - boolean that has been set
		bx - mask to test cx and dx for the relevant bit
		es:0 - FormatInfoStruc

RETURN:		nothing

DESTROYED:	ax,bx,di,bp,es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FormatHandleBoolean	proc	near
	class	FloatFormatClass
	.enter

EC<	call	ECCheckFormatInfoStruc_ES >

	mov	di, offset FIS_curParams.FP_params.FFAP_FLOAT.formatFlags

	test	bx, cx
	je	checkSelect

	not	ax
	and	es:[di], ax
	jmp	short done

checkSelect:
	test	bx, dx
	je	exit

	or	es:[di], ax		; set bit

done:
	call	FormatUpdateSamples	; bx,cx,dx intact

exit:
	.leave
	ret
FormatHandleBoolean	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatHandleChar

DESCRIPTION:	Intercepts MSG_META_TEXT_USER_MODIFIED so that the samples can be
		updated as the user types.

CALLED BY:	INTERNAL ()

PASS:		*ds:si - controller instance
		ds:di - controller instance
		cx:dx - od of text edit object
		es - dgroup

RETURN:		nothing

DESTROYED:	ax,bx,cx,di,es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version
	witt	11/93		DBCS-ized

-------------------------------------------------------------------------------@

FormatHandleChar	method dynamic FloatFormatClass,
	MSG_META_TEXT_USER_MODIFIED

	mov	bx, ds:[di].formatInfoStrucHan

	cmp	dx, offset UIFmtPreNegative
	jne	10$
	mov	di, offset FIS_curParams.FP_params.FFAP_FLOAT.preNegative
	jmp	short updateSamples
10$:
	cmp	dx, offset UIFmtPostNegative
	jne	20$
	mov	di, offset FIS_curParams.FP_params.FFAP_FLOAT.postNegative
	jmp	short updateSamples
20$:
	cmp	dx, offset UIFmtPrePositive
	jne	30$
	mov	di, offset FIS_curParams.FP_params.FFAP_FLOAT.prePositive
	jmp	short updateSamples
30$:
	cmp	dx, offset UIFmtPostPositive
	jne	40$
	mov	di, offset FIS_curParams.FP_params.FFAP_FLOAT.postPositive
	jmp	short updateSamples
40$:
	cmp	dx, offset UIFmtHeader
	jne	50$
	mov	di, offset FIS_curParams.FP_params.FFAP_FLOAT.header
	jmp	short updateSamples
50$:
	cmp	dx, offset UIFmtTrailer
	jne	60$
	mov	di, offset FIS_curParams.FP_params.FFAP_FLOAT.trailer
	jmp	short updateSamples
60$:
	pop	ax			; clear stack
	pop	ax
	jmp	short exit

updateSamples:
	call	MemLock			; lock FormatInfoStruc
	push	bx
	mov	es, ax
	call	GetChildBlockAndFeatures
	mov	es:FIS_childBlk, bx
	mov	es:FIS_features, ax

EC<	call	ECCheckFormatInfoStruc_ES >

	mov	bx, cx
	push	di			; save string offset
	mov	di, dx			; di <- offset
	call	GetText			; bx <- handle, if any
	pop	di			; retrieve string offset
	jc	clearEntry

	push	ds
	call	MemLock
	mov	ds, ax
	clr	si
	LocalCopyString

	call	MemFree
	pop	ds

done:

	call	FormatUpdateSamples
	pop	bx
	call	MemUnlock
	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage

exit:
	ret

clearEntry:
	call	MemFree
SBCS<	clr	al							>
DBCS<	clr	ax							>
	LocalPutChar	esdi, ax
	jmp	short done
FormatHandleChar	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatUpdateSamples

DESCRIPTION:	

CALLED BY:	INTERNAL()

PASS:		es:0 - FormatInfoStruc

RETURN:		ax,di

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

FormatUpdateSamples	proc	near	uses	bx,cx,dx
	.enter

	;
	; since UpdateUserDefSamples allocates almost 600 bytes (more in
	; DBCS) of local stack space, make sure we've got enough
	;
	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

EC<	call	ECCheckFormatInfoStruc_ES >
	call	UpdateUserDefSamples

	mov	dx, di		; in case we actually return di, which I doubt
	pop	di
	call	ThreadReturnStackSpace
	mov	di, dx

	.leave
	ret
FormatUpdateSamples	endp

FloatFormatCode	ends
