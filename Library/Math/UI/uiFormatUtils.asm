COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		formatUtils.asm

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name			Description
	----			-----------
	FloatFormatGetListEntryWithToken
	FloatFormatLockFreeFormatEntry
	FloatFormatLockFormatEntry
	FloatFormatDeleteUpdateListEntries
	FloatFormatIsFormatTheSame?
	GetEntryPos
	SetEntryPos
	SelectEntry
	DeselectEntry
	SelDeselEntry
	AddAndSelectEntry
	DeleteEntry
	GetRange
	SetRange
	GetText
	SetText
	SetEnabled
	SetNotEnabled
	GetChildBlock
	DerefDI
	SendToOutput
	MyError
	ConfirmDialog
	CalcFormatUserStandardDialog
	StringLock
	GetFeaturesAndChildBlock
	SendListSetExcl
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial revision

DESCRIPTION:
		
	$Id: uiFormatUtils.asm,v 1.1 97/04/05 01:23:28 newdeal Exp $

-------------------------------------------------------------------------------@


FloatFormatCode	segment resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	UpdateMainSamples

DESCRIPTION:	

CALLED BY:	INTERNAL (FormatFormatSelected)

PASS:		es:0 - FormatInfoStruc
		FFA_stackFrame stack frame
		SamplesStruc stack frame

RETURN:		nothing

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

UpdateMainSamples	proc	near
	locals	local	FFA_stackFrame
	samples	local	SamplesStruc
	ForceRef locals
	.enter	inherit near

EC<	call	ECCheckFormatInfoStruc_ES >

	push	ds
	segmov	ds, es
	call	InitForSamples
	pop	ds

EC<	call	ECCheckFormatInfoStruc_ES >

	mov	bx, es:FIS_childBlk
	mov	dx, ss

	lea	ax, samples.SS_sample1Str
ifdef GPC_ONLY
	mov	di, offset UIFmtMainSample1Sample
else
	mov	di, offset UIFmtMainSample1
endif
	call	SetTextRO

	mov	dx, ss
	lea	ax, samples.SS_sample2Str
ifdef GPC_ONLY
	mov	di, offset UIFmtMainSample2Sample
else
	mov	di, offset UIFmtMainSample2
endif
	call	SetTextRO

	mov	dx, ss
	lea	ax, samples.SS_formatPosStr
	mov	di, offset UIFmtMainFormatStr
	call	SetTextRO

	.leave
	ret
UpdateMainSamples	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	UpdateUserDefSamples

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_FORMAT_UPDATE_USER_DEF_SAMPLES)

PASS:		es:0 - FormatInfoStruc

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

UpdateUserDefSamples	proc	near
	locals	local	FFA_stackFrame
	samples	local	SamplesStruc
	ForceRef locals
	.enter

EC<	call	ECCheckFormatInfoStruc_ES >

	push	ds
	segmov	ds, es
	call	InitForSamples
	pop	ds

EC<	call	ECCheckFormatInfoStruc_ES >

	mov	bx, es:FIS_childBlk
	mov	dx, ss

	lea	ax, samples.SS_sample1Str
ifdef GPC_ONLY
	mov	di, offset UIFmtSample1Sample
else
	mov	di, offset UIFmtSample1
endif
	call	SetTextRO

	lea	ax, samples.SS_sample2Str
ifdef GPC_ONLY
	mov	di, offset UIFmtSample2Sample
else
	mov	di, offset UIFmtSample2
endif
	call	SetTextRO

	lea	ax, samples.SS_formatPosStr
	mov	di, offset UIFmtFormatStr
	call	SetTextRO

	.leave
	ret
UpdateUserDefSamples	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitForSamples

DESCRIPTION:	

CALLED BY:	INTERNAL (UpdateMainSamples,
		UpdateUserDefSamples)

PASS:		FFA_stackFrame
		SamplesStruc stack frame
		ds:0 - FormatInfoStruc

RETURN:		

DESTROYED:	ax,cx,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		For DBCS, we allow scientific format, and limit the string
		size to a normal length.  Otherwise, our formatting buffers
		overflow the :1 thread's stack --> crash and burn..
		'stack space = 192 bytes'

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version
	witt	11/93		DBCS allow scientific notation for large numbs

-------------------------------------------------------------------------------@

InitForSamples	proc	near	uses	bx
	locals	local	FFA_stackFrame
	samples	local	SamplesStruc
	.enter	inherit near

EC<	call	ECCheckFormatInfoStruc_DS >

	push	es
	segmov	es, ss, ax

	;
	; zero initialize the stack frame
	;
	push	di
	clr	al
	lea	di, locals
	mov	cx, size FFA_stackFrame
	rep	stosb

	lea	di, samples
	mov	cx, size SamplesStruc
	rep	stosb
	pop	di

	;
	; initialize the stack frame
	;
	mov	ax, ds:FIS_curParams.FFAP_FLOAT.formatFlags
	test	ax, mask FFDT_DATE_TIME_OP
	je	floatOp

	or	ax, mask FFDT_FROM_ADDR
	mov	locals.FFA_float.FFA_params.formatFlags, ax
	jmp	formatSample

floatOp:
	or	ax, mask FFAF_FROM_ADDR
DBCS<	and 	ax, not (mask FFAF_DONT_USE_SCIENTIFIC)     ; scientific OK  >
	mov	locals.FFA_float.FFA_params.formatFlags, ax

	mov	al, ds:FIS_curParams.FFAP_FLOAT.decimalOffset
	mov	locals.FFA_float.FFA_params.decimalOffset, al
SBCS<	mov	al, ds:FIS_curParams.FFAP_FLOAT.totalDigits		>
DBCS<	mov	al, DECIMAL_PRECISION	; what CheckFloatToAsciiParams wants  >
	mov	locals.FFA_float.FFA_params.totalDigits, al
	mov	al, ds:FIS_curParams.FFAP_FLOAT.decimalLimit
	mov	locals.FFA_float.FFA_params.decimalLimit, al

	clr	bx
	lea	ax, ds:FIS_curParams.FFAP_FLOAT.preNegative
	lea	cx, locals.FFA_float.FFA_params.preNegative
	call	HandleStr

	clr	bx
	lea	ax, ds:FIS_curParams.FFAP_FLOAT.postNegative
	lea	cx, locals.FFA_float.FFA_params.postNegative
	call	HandleStr

	clr	bx
	lea	ax, ds:FIS_curParams.FFAP_FLOAT.prePositive
	lea	cx, locals.FFA_float.FFA_params.prePositive
	call	HandleStr

	clr	bx
	lea	ax, ds:FIS_curParams.FFAP_FLOAT.postPositive
	lea	cx, locals.FFA_float.FFA_params.postPositive
	call	HandleStr

	mov	bx, mask FFAF_HEADER_PRESENT
	lea	ax, ds:FIS_curParams.FFAP_FLOAT.header
	lea	cx, locals.FFA_float.FFA_params.header
	call	HandleStr

	mov	bx, mask FFAF_TRAILER_PRESENT
	lea	ax, ds:FIS_curParams.FFAP_FLOAT.trailer
	lea	cx, locals.FFA_float.FFA_params.trailer
	call	HandleStr

	;
	; convert the numbers
	; *ds:si = instance, es = ss
	;

	mov	al, 0ffh			; positive number format
	lea	di, samples.SS_formatPosStr
	call	FloatGenerateFormatStr

	mov	al, 0				; negative number format
	lea	di, samples.SS_formatNegStr
	call	FloatGenerateFormatStr

	;
	; since we're pressed for space, we will combine the two
	; format strings on a single line seperated by a semi-colon.
	;
SBCS<	clr	al	>
DBCS<	clr	ax	>
	lea	di, samples.SS_formatPosStr
	mov	cx, -1
if DBCS_PCGEOS
	repne	scasw
	LocalPrevChar	esdi			; es:di <- null
	mov	ax, ';'
	stosw					; smash null.
	mov	ax, ' '
	stosw
	stosw
else
	repne	scasb
	dec	di				; es:di <- null
	mov	ax, ';' shl 8 or ' '
	stosw
	mov	al, ' '
	stosb
endif

	push	ds,si				; save instance ptr
	segmov	ds, ss
	lea	si, samples.SS_formatNegStr
	LocalCopyString

	segmov	ds, cs, ax
	mov	si, offset sample2Num
FXIP <	mov	cx, size FloatNum					>
FXIP <	call	SysCopyToStackDSSI		; ds:si = data in stack	>
	lea	di, samples.SS_sample2Str
	call	FloatFloatToAscii
FXIP <	call	SysRemoveFromStack		; release stack space	>
	pop	ds,si

formatSample:
	push	ds,si
	segmov	ds, cs, ax
	mov	si, offset sample1Num
FXIP <	mov	cx, size FloatNum					>
FXIP <	call	SysCopyToStackDSSI		; ds:si = data in stack	>
	lea	di, samples.SS_sample1Str
	call	FloatFloatToAscii
FXIP <	call	SysRemoveFromStack		; release stack space	>
	pop	ds,si

	pop	es

	.leave
	ret
InitForSamples	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	HandleStr

DESCRIPTION:	Copies string into 'stack frame' variable (including C_NULL
		terminator).  If some string actually there, bit OR's in
		flags from BX.

CALLED BY:	INTERNAL (InitForSamples)

PASS:		bx - mask to OR into formatFlags if a string is present
		FFA_stackFrame
		ds:0 - FormatInfoStruc
		ds:ax - address of string var
		es:cx - address of stack frame field

RETURN:		"stack frame field" buffer filled in (cx destroyed)

DESTROYED:	ax,cx,di,si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version
	witt	11/93		DBCS-ized with LocalXxx macros

-------------------------------------------------------------------------------@

HandleStr	proc	near	uses	si
	class	FloatFormatClass
	FHS_local	local	FFA_stackFrame
	.enter inherit near

EC<	call	ECCheckFormatInfoStruc_DS >

	push	di
	mov	si, ax			; 'string var' is source
	mov	di, cx
	LocalGetChar	cx, dssi, NO_ADVANCE	; cl <- first char (save)

	LocalCopyString

	pop	di			; retrieve ptr to instance

	jcxz	done			; jump if zero length string

	or	ds:FIS_curParams.FFAP_FLOAT.formatFlags, bx
	or	FHS_local.FFA_float.FFA_params.formatFlags, bx
done:
	.leave
	ret
HandleStr	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FISSendToOutput

DESCRIPTION:	

CALLED BY:	INTERNAL (FloatFormatUpdateUI, FloatFormatRequestMoniker)

PASS:		ax - message to send to output
		bx - child block of controller
		cx - current selection, value to place in FIS_curSelection
		*ds:si - float controller

RETURN:		none

DESTROYED:	ax,cx,bx,es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

FISSendToOutput	proc	near
	push	ax				; save message
	push	cx				; save list entry #
	call	InitFormatInfoStruc		; es <- FormatInfoStruc
	pop	es:FIS_curSelection

	call	MemUnlock

	;-----------------------------------------------------------------------
	; send FormatInfoStruc to output

	mov	cx, bx				; cx <- handle

	pop	ax				; retrieve message
	call	SendToOutput
	ret
FISSendToOutput	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFormatInfoStruc

DESCRIPTION:	Allocate a FormatInfoStruc.

CALLED BY:	INTERNAL (FISSendToOutput, FormatInvokeUserDefDB)

PASS:		bx - child block
		*ds:si - float controller

RETURN:		bx - mem handle
		es - seg addr of formatInfoStruc

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version
	Don	1/95		Combined with useless subroutine

-------------------------------------------------------------------------------@

InitFormatInfoStruc	proc	near	uses	ax,cx
	.enter
	push	bx
	call	GetChildBlockAndFeatures	;ax <- features
	push	ax
	mov	ax, size FormatInfoStruc
	mov	cx, (mask HAF_ZERO_INIT or mask HAF_LOCK \
		or mask HAF_NO_ERR) shl 8 \
		or mask HF_SHARABLE or mask HF_SWAPABLE
	call	MemAlloc

	mov	es, ax
	mov	es:FIS_signature, FORMAT_INFO_STRUC_ID
	pop	es:FIS_features
	pop	es:FIS_childBlk
	mov	es:FIS_chooseFmtListChunk, offset FormatsList
	.leave
	ret
InitFormatInfoStruc	endp



if ERROR_CHECK

ECCheckFormatInfoStruc_DS	proc	near
	pushf
	cmp	ds:FIS_signature, FORMAT_INFO_STRUC_ID
	ERROR_NE FLOAT_FORMAT_BAD_FORMAT_INFO_STRUC
	test	ds:FIS_features, not (mask FFCFeatures)
	ERROR_NZ FLOAT_FORMAT_BAD_FORMAT_INFO_STRUC
	popf
	ret
ECCheckFormatInfoStruc_DS	endp

ECCheckFormatInfoStruc_ES	proc	near
	pushf
	cmp	es:FIS_signature, FORMAT_INFO_STRUC_ID
	ERROR_NE FLOAT_FORMAT_BAD_FORMAT_INFO_STRUC
	test	es:FIS_features, not (mask FFCFeatures)
	ERROR_NZ FLOAT_FORMAT_BAD_FORMAT_INFO_STRUC
	popf
	ret
ECCheckFormatInfoStruc_ES	endp

endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatGetListEntryWithToken

DESCRIPTION:	Return the list entry number given the format token.
		If the format entry is user-defined, it must have been
		added by FloatFormatAddFormat. If the format is indeterminate,
		return 0.

		FloatFormatGetFormatToken performs the reverse function
		by returning a token given the list entry number.

CALLED BY:	INTERNAL (FloatFormatUpdateUI)

PASS:		cx - format token

RETURN:		cx - list entry number

DESTROYED:	ax,bx,dx,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFormatGetListEntryWithToken	proc	near	uses	ds,si,es,bp
	.enter

	test	cx, FORMAT_ID_PREDEF
	je	userDef

	; If the token is FORMAT_ID_INDETERMINATE, just return 0.
	; This happens when the list is initialized.
	;
	cmp	cx, FORMAT_ID_INDETERMINATE
	jne	determinate
	clr	cx
	jmp	done

determinate:
	mov	ax, cx
	and	ax, not FORMAT_ID_PREDEF	; ax <- offset into table
	clr	dx
	mov	cx, size FormatParams
	div	cx
EC<	tst	dx >
EC<	ERROR_NE FLOAT_FORMAT_ASSERTION_FAILED >

	mov	cx, ax				; cx <- list entry
	jmp	short done

userDef:
EC<	call	ECCheckFormatInfoStruc_ES >
	call	FloatFormatLockFormatEntry	; ds:si <- format entry
						; bp <- VM mem handle
						; dx <- offset to end of array
	mov	cx, ds:[si].FE_listEntryNumber
	call	VMUnlock

done:
	.leave
	ret
FloatFormatGetListEntryWithToken	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatLockFreeFormatEntry

DESCRIPTION:	Tries to locate a free FormatEntry.  If none is found,
		resize the format array to create one.

		NOTE: Caller must unlock the VM block if this routine is
		successful.

CALLED BY:	INTERNAL (FloatFormatAddFormat)

PASS:		es:0 - FormatInfoStruc

RETURN:		carry clear if successful
		    ds:si - address of FormatEntry (di = format token)
		    bp - mem handle
		carry set otherwise
		    cx - FloatFormatFormatError
			FLOAT_FORMAT_FORMAT_TOO_MANY_FORMATS
			FLOAT_FORMAT_FORMAT_CANNOT_ALLOC
		    (no locked block in event of error)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFormatLockFreeFormatEntry	proc	near	uses	bx,dx
	.enter
EC<	call	ECCheckFormatInfoStruc_ES >

	mov	ax, es:FIS_userDefFmtArrayBlkHan	; ax <- VM handle
	mov	bx, es:FIS_userDefFmtArrayFileHan	; bx <- VM file handle
	call	VMLock				; bp <- mem handle

	mov	ds, ax
EC<	cmp	ds:FAH_signature, FORMAT_ARRAY_HDR_SIG >
EC<	ERROR_NE FLOAT_FORMAT_BAD_FORMAT_ARRAY >

	mov	si, size FormatArrayHeader	; es:di <- first format entry
	mov	cx, size FormatEntry
	mov	dx, ds:FAH_formatArrayEnd	; dx <- end

searchLoop:
	cmp	ds:[si].FE_used, 0	; free?
	je	done			; branch if so

EC<	call	ECCheckUsedEntry >
	add	si, cx			; di <- addr of next boolean
	cmp	si, dx			; past end?
	jb	searchLoop		; loop if not

	;
	; all entries taken, expansion needed
	;
	cmp	ds:FAH_numUserDefEntries, MAX_FORMATS
	je	tooManyFormats

	mov	ax, dx			; ax <- current size in bytes
	add	ax, cx			; inc ax by size of entry
	push	ax			; save end of array
	mov	ch, mask HAF_ZERO_INIT
	xchg	bx, bp
	call	MemReAlloc
	mov	bp, bx
	pop	si			; retrieve end of array
	mov	cx, FLOAT_FORMAT_CANNOT_ALLOC
	jc	error

	mov	ds, ax
	mov	ds:FAH_formatArrayEnd, si
	sub	si, size FormatEntry	; si <- offset to empty entry

EC<	mov	ds:[si].FE_sig, FORMAT_ENTRY_SIG >
	clc

done:
	.leave
	ret

tooManyFormats:
	mov	cx, FLOAT_FORMAT_TOO_MANY_FORMATS
error:
	call	VMUnlock
	stc
	jmp	short done
FloatFormatLockFreeFormatEntry	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatLockFormatEntry

DESCRIPTION:	Lock and return the format entry with the given token.
		The token must belong to a user-defined format.

		Caller must unlock the VM block.

CALLED BY:	EXTERNAL (also FloatFormatGetFormatToken,
			  FloatFormatChangeFormat,
			  FloatFormatDeleteFormat)

PASS:		es:0 - FormatInfoStruc
		cx - format token

RETURN:		ds:si - address of FormatEntry (di = format token)
		bp - mem handle
		dx - offset to end of format array

DESTROYED:	ax,bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFormatLockFormatEntry	proc	near	uses	di
	.enter
EC<	call	ECCheckFormatInfoStruc_ES >

EC<	test	cx, FORMAT_ID_PREDEF >
EC<	ERROR_NE	FLOAT_FORMAT_BAD_USER_DEF_TOKEN >

	mov	ax, es:FIS_userDefFmtArrayBlkHan
	mov	bx, es:FIS_userDefFmtArrayFileHan	; bx <- VM file handle
	call	VMLock

	mov	ds, ax				; ds:si <- format entry
	mov	si, cx
	mov	dx, ds:FAH_formatArrayEnd

EC<	cmp	ds:FAH_signature, FORMAT_ARRAY_HDR_SIG >
EC<	ERROR_NE FLOAT_FORMAT_BAD_FORMAT_ARRAY >
EC<	cmp	ds:[si].FE_used, 0 >		; valid content?
EC<	je	ok >				; branch if so
EC<	cmp	ds:[si].FE_used, -1 >		; valid content?
EC<	ERROR_NE FLOAT_FORMAT_BAD_FORMAT_ENTRY >	; error if not
EC< ok: >

	.leave
	ret
FloatFormatLockFormatEntry	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatDeleteUpdateListEntries

DESCRIPTION:	Update the list entry number field in the format entry if
		necessary.

CALLED BY:	INTERNAL (FloatFormatDeleteFormat)

PASS:		es:0 - format array
		ds:si - deleted format entry
		dx - offset to end of array

RETURN:		

DESTROYED:	ax,cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	ax <- list entry number of deleted entry
	for all format entries
	    if list entry number > ax
		dec list entry number

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFormatDeleteUpdateListEntries	proc	near	uses	di
	.enter
EC<	cmp	ds:FAH_signature, FORMAT_ARRAY_HDR_SIG >
EC<	ERROR_NE FLOAT_FORMAT_BAD_FORMAT_ARRAY >

	mov	ax, ds:[si].FE_listEntryNumber
	mov	cx, size FormatEntry

	mov	di, size FormatArrayHeader	; ds:di <- first entry
updateLoop:
	cmp	ds:[di].FE_used, 0
	je	next

EC<	push	si >
EC<	mov	si, di >
EC<	call	ECCheckUsedEntry >
EC<	pop	si >
	cmp	ax, ds:[di].FE_listEntryNumber
EC<	ERROR_E FLOAT_FORMAT_BAD_FORMAT_LIST >
	jg	next

	dec	ds:[di].FE_listEntryNumber

next:
	add	di, cx			; next format entry
	cmp	di, dx			; done?
	jl	updateLoop
EC<	ERROR_G	FLOAT_FORMAT_ASSERTION_FAILED >
	.leave
	ret
FloatFormatDeleteUpdateListEntries	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	FloatFormatIsFormatTheSame?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Checks to see if the FormatParams for the given token
		match the FormatParams that are passed.

CALLED BY:	INTERNAL ()

PASS:		es:0 - FormatInfoStruc
		cx - format token
		dx:bp - FormatParams

RETURN:		cx - FLOAT_FORMAT_FORMAT_PARAMS_MATCH /
		     FLOAT_FORMAT_FORMAT_PARAMS_DONT_MATCH

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatFormatIsFormatTheSame?	proc	far
	uses	ds,es,di,si,bp
	.enter
EC<	call	ECCheckFormatInfoStruc_ES >

	push	dx,bp				; save address of params
	call	FloatFormatLockFormatEntry	; ds:si <- format entry
						; bp <- VM mem handle
						; dx <- offset to end of array
	pop	es,di				; retrieve address of name

	add	si, offset FE_params
;	mov	cx, size FormatParams
	mov	cx, offset FP_nameHan
	repe	cmpsb
	tst	cx

	call	VMUnlock			; unlock format entry

	mov	cx, FLOAT_FORMAT_PARAMS_MATCH
	je	done
	mov	cx, FLOAT_FORMAT_PARAMS_DONT_MATCH

done:

	.leave
EC<	call	ECCheckFormatInfoStruc_ES >
	ret
FloatFormatIsFormatTheSame?	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetEntryPos

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		bx:di - offset to list object

RETURN:		cx - selection (identifier of selected object)

DESTROYED:	ax,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@

GetEntryPos	proc	near	uses	bx,dx,bp,si
	.enter
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, di				; si <- list offset
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ax <- pos
	mov	cx, ax
	.leave
	ret
GetEntryPos	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SetEntryPos

DESCRIPTION:	Sends a MSG_GEN_LIST_SET_EXCL to the list object.

CALLED BY:	INTERNAL (Set*Entry)

PASS:		cx - identifier
		dx - indeterminate state (for SetEntryPosViaOutput only)
		bx:di - list object

RETURN:		nothing

DESTROYED:	ax,cx,dx,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

------------------------------------------------------------------------------@

SetEntryPos	proc	near	uses	si
	ForceRef SetEntryPos
	.enter
	mov	si, di
	mov	di, mask MF_FIXUP_DS
	call	SetEntryPosLow
	.leave
	ret
SetEntryPos	endp

SetEntryPosNoFixup	proc	near	uses	si
	.enter
	mov	si, di			
	clr	di
	call	SetEntryPosLow
	.leave
	ret
SetEntryPosNoFixup	endp

SetEntryPosViaOutput	proc	near	uses	si
	.enter
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	SendEventViaOutput
	.leave
	ret
SetEntryPosViaOutput	endp

SetEntryPosLow	proc	near	uses	bp
	.enter

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx				; specify determinate
	call	ObjMessage
	.leave
	ret
SetEntryPosLow	endp

SendEventViaOutput	proc	near
	uses	cx, dx, di
	.enter
	;
	; We need to mess around a bit here so things stay synchronized.
	; We record the MSG...SET...SELECTION with the format list
	; as the destination.  Then we record that message with
	; MSG_META_DISPATCH_EVENT controller's output as the destination.
	;
	push	si
	mov	si, di				;^lbx:si <- OD of list
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di				;cx <- recorded message
	pop	si				;*ds:si <- FloatControl
	clr	dx				;dx <- MessageFlags for event
	mov	ax, MSG_META_DISPATCH_EVENT
	call	SendToOutput

	.leave
	ret
SendEventViaOutput	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	AddAndSelectEntry

DESCRIPTION:	Issues a MSG_GEN_LIST_ADD_ENTRY followed by a
		MSG_GEN_LIST_SET_EXCL.

CALLED BY:	INTERNAL (FloatFormatCreateFormat)

PASS:		es:0 - FormatInfoStruc
		cx - number of the entry AFTER which to insert

RETURN:		nothing, ds is not fixed up

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@
if 0
AddAndSelectEntry	proc	near	uses	si,bp
	.enter
if 0

EC<	call	ECCheckFormatInfoStruc_ES >

	push	cx
	mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
	mov	cx, GDLP_LAST			; temp line
	mov	dx, 1				; add 1 item
	mov	bx, es:FIS_childBlk		; bx <- child block
	mov	si, offset FormatsList
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	cx
	inc	cx

	mov	es:FIS_curSelection, cx
	mov	bx, es:FIS_childBlk
	mov	di, offset FormatsList
	call	SetEntryPosNoFixup

	call	FloatFormatProcessFormatSelected

	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov	cx, -1				; mark modified
	mov	bx, es:FIS_childBlk		; bx <- child block
	mov	si, offset FormatsList
	mov	di, mask MF_CALL
	call	ObjMessage

endif

	.leave
	ret
AddAndSelectEntry	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DeleteEntry

DESCRIPTION:	

CALLED BY:	INTERNAL (FloatFormatCreateFormat, FormatDelete)

PASS:		es:0 - FormatInfoStruc
		di - offset to gen list
		cx - number of the entry to delete

RETURN:		nothing, ds is not fixed up

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

if 0
DeleteEntry	proc	near	uses	si,bp
	.enter
EC<	call	ECCheckFormatInfoStruc_ES >

	mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
	mov	bx, es:FIS_childBlk		; bx <- child block
	mov	dx, 1
	mov	si, di
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret
DeleteEntry	endp
endif



COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetRange

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		*ds:si - float controller instance
		di - offset of range object

RETURN:		cx - range value

DESTROYED:	ax,bx,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@

GetRange	proc	near	uses	si,bp
	.enter
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	call	GetChildBlock			; bx <- child block
	mov	si, di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;dx.cx <- value
	mov	cx, dx
	.leave
	ret
GetRange	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetRange

DESCRIPTION:	

CALLED BY:	INTERNAL (FloatFormatInvokeUserDefDB)

PASS:		es:0 - FormatInfoStruc
		di - offset of range object
		dx - value

RETURN:		nothing
		ds is not fixed up

DESTROYED:	ax,bx,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@

SetRange	proc	near	uses	si,bp
	.enter
EC<	call	ECCheckFormatInfoStruc_ES >

	mov	ax, MSG_GEN_VALUE_SET_VALUE
	mov	bx, es:FIS_childBlk
	clr	cx, bp			; clear fraction, make determinate
	mov	si, di
	clr	di
	call	ObjMessage
	.leave
	ret
SetRange	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetText

DESCRIPTION:	

CALLED BY:	INTERNAL (FloatFormatUserDefOK, FormatHandleChar)

PASS:		es:0 - FormatInfoStruc
		bx:di - OD of text object

RETURN:		bx - mem handle
		carry set if string length is null

DESTROYED:	ax,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@

GetTextNoFixup	proc	near	uses	si
	.enter
	mov	si, di
	mov	di, mask MF_CALL	
	call	GetTextLow
	.leave
	ret
GetTextNoFixup	endp

GetText	proc	near	uses	si
	.enter
	mov	si, di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	GetTextLow
	.leave
	ret
GetText	endp

GetTextLow	proc	near	uses	cx,dx,bp
	.enter
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx			;specify mem block creation
	call	ObjMessage
	mov	bx, cx

	tst	ax			; null string?
	stc				; assume null
	je	done			; branch if assumption correct
	clc				; else flag string present
done:
	.leave
	ret
GetTextLow	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetText

DESCRIPTION:	Moves a C_NULL terminated string to a GenText object.
		Replaces all existing text with new text.

CALLED BY:	INTERNAL ()

PASS:		bx - handle of text object
		di - offset to text object
		dx:ax - null terminated string

RETURN:		ds is not fixed up

DESTROYED:	ax,cx,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

SetText	proc	near	uses	dx,si,bp
	.enter
	mov	bp, ax
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx
	mov	si, di
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret
SetText	endp

SetTextRO	proc	near	uses	dx,si,bp
	.enter
	mov	bp, ax
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx
	mov	si, di
	mov	di, mask MF_CALL
	call	ObjMessage
ifdef GPC_ONLY
	mov	ax, MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE
	mov	cx, (mask VTS_SELECTABLE or mask VTS_EDITABLE) shl 8
	mov	di, mask MF_CALL
	call	ObjMessage
endif
	.leave
	ret
SetTextRO	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetTextStart

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		bx - handle of text object
		di - offset to text object
		dx:ax - null terminated string

RETURN:		ds is not fixed up

DESTROYED:	ax,cx,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

SetTextStart	proc	near	uses	dx,si,bp
	.enter
	mov	si, di				; ^lbx:si = text object
	push	dx, ax
	mov	ax, MSG_META_SUSPEND
	call	callObj
	pop	dx, bp				; dx:bp = text
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx
	call	callObj
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	clr	cx, dx
	call	callObj
	mov	ax, MSG_META_UNSUSPEND
	call	callObj
	.leave
	ret

callObj	label	near
	mov	di, mask MF_CALL
	call	ObjMessage
	retn
SetTextStart	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SetEnabled

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		bx:di - offset to object

RETURN:		

DESTROYED:	ax,cx,dx,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

------------------------------------------------------------------------------@

SetEnabledNoFixup	proc	near	uses	si
	.enter
	mov	si, di
	clr	di
	call	SetEnabledLow
	.leave
	ret
SetEnabledNoFixup	endp

SetEnabledLow	proc	near	uses	bp
	.enter
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessage
	.leave
	ret
SetEnabledLow	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SetNotEnabled

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		bx:di - offset to object

RETURN:		

DESTROYED:	ax,cx,dx,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

------------------------------------------------------------------------------@

SetNotEnabled	proc	near	uses	si
	.enter
	mov	si, di
	mov	di, mask MF_FIXUP_DS
	call	SetNotEnabledLow
	.leave
	ret
SetNotEnabled	endp

SetNotEnabledNoFixup	proc	near	uses	si
	.enter
	mov	si, di
	clr	di
	call	SetNotEnabledLow
	.leave
	ret
SetNotEnabledNoFixup	endp

SetNotEnabledLow	proc	near	uses	bp
	.enter
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessage
	.leave
	ret
SetNotEnabledLow	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetChildBlock

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		*ds:si - float controller instance

RETURN:		bx - handle of child block

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

GetChildBlock	proc	near	uses	ax
	.enter
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData		; ds:bx <- GenControlUpdateUIParams
	mov	bx, ds:[bx].TGCI_childBlock
	.leave
	ret
GetChildBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChildBlockAndFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get child block and features for the controller

CALLED BY:	UTILITY

PASS:		*ds:si - float controller instance
RETURN:		bx - handle of child block
		ax - features that are "on"
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetChildBlockAndFeatures		proc	near
	.enter
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData		; ds:bx <- GenControlUpdateUIParams
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	.leave
	ret
GetChildBlockAndFeatures		endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	DerefDI

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		*ds:si - float controller instance

RETURN:		ds:di - float controller instance

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

DerefDI	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].FloatFormat_offset
	ret
DerefDI	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SendToOutput

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		*ds:si - controller
		ax - message to send
		cx, dx, bp - data for message

RETURN:		none

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	8/92		Initial version

-------------------------------------------------------------------------------@

SendToOutput	proc	near	uses	bx,di
	.enter

	clr	bx,di
	call	GenControlOutputActionRegs

	.leave
	ret
SendToOutput	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MyError

DESCRIPTION:	Beeps and puts up error message in a summons.

CALLED BY:	INTERNAL ()

PASS:		bp - chunk handle of error string in Strings

RETURN:		nothing

DESTROYED:	bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@

MyError	proc	near	uses	ds
	.enter

	mov	bx, handle ControlStrings
	call	MemLock
	mov	di, ax
	mov	ds, ax
	mov	bp, ds:[bp]
	mov	ax, (CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
		(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	call	CalcFormatUserStandardDialog
	call	MemUnlock

	.leave
	ret
MyError	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ConfirmDialog

DESCRIPTION:	

CALLED BY:	INTERNAL (MtdHanPrinterDelete)

PASS:		bx:si - resource handle, chunk handle of error string
		cx:dx - addr of argument string

RETURN:		carry clear if affirmative
		carry set otherwise

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial version

------------------------------------------------------------------------------@

ConfirmDialog	proc	near
	mov	ax, (CDT_QUESTION shl offset CDBF_DIALOG_TYPE) or \
		(GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)

	push	bx		;save resource handle

	;get di:bp to point to the error string

	push	dx
	call	StringLock	;dx:bp <- string
	mov	di, dx
	pop	dx

	;pass di:bp = error string
	;pass cx:dx = argument string
	call	CalcFormatUserStandardDialog

	pop	bx		;retrieve resource handle
	call	MemUnlock

	cmp	ax, IC_YES
	clc
	je	done
	stc
done:
	ret
ConfirmDialog	endp

;
; pass:
;	ax - CustomDialogBoxFlags
;	di:bp = error string
;	cx:dx = arg 1
;	bx:si = arg 2
; returns:
;	ax = InteractionCommand response
; destroys:
;	nothing
CalcFormatUserStandardDialog	proc	near

	; we must push 0 on the stack for SDP_helpContext

	push	bp, bp			;push dummy optr
	mov	bp, sp			;point at it
	mov	ss:[bp].segment, 0
	mov	bp, ss:[bp].offset

.assert (offset SDP_customTriggers eq offset SDP_stringArg2+4)
	push	ax		; don't care about SDP_customTriggers
	push	ax
.assert (offset SDP_stringArg2 eq offset SDP_stringArg1+4)
	push	bx		; save SDP_stringArg2 (bx:si)
	push	si
.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
	push	cx		; save SDP_stringArg1 (cx:dx)
	push	dx
.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
	push	di		; save SDP_customString (di:bp)
	push	bp
.assert (offset SDP_customString eq offset SDP_customFlags+2)
.assert (offset SDP_customFlags eq 0)
	push	ax		; save SDP_type, SDP_customFlags
				; pass params on stack
	call	UserStandardDialog
	ret
CalcFormatUserStandardDialog	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	StringLock

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		bx - resource handle
		si - chunk handle

RETURN:		dx:bp - string

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/90		Initial version

------------------------------------------------------------------------------@

StringLock	proc	near
	uses	ax, ds
	.enter

	call	MemLock			;ax <- seg addr of resource
	mov	ds, ax
	xchg	dx, ax			;dx = segment of string
        mov	bp, ds:[si]		;deref string chunk

	.leave
	ret
StringLock	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetFeaturesAndChildBlock

DESCRIPTION:	

CALLED BY:	INTERNAL (NOT USED)

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

if 0
GetFeaturesAndChildBlock	proc	near
EC <	push	es, di							>
EC <	mov	di, segment GenControlClass				>
EC <	mov	es, di							>
EC <	mov	di, offset GenControlClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	FLOAT_FORMAT_OBJECT_ERROR			>
EC <	pop	es, di							>
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData			;ds:bx = data
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	ret
GetFeaturesAndChildBlock	endp
endif


FloatFormatCode	ends
