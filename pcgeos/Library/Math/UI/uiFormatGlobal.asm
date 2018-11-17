COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Math UI
FILE:		uiFormatGlobal.asm

AUTHOR:		Cheng, 10/92

ROUTINES:
	Name			Description
	----			-----------
	FloatFormatInit
	FloatFormatInitFormatList
	FISGetFormatCount
	FloatFormatGetFormatParamsWithListEntry
	FloatFormatProcessFormatSelected
	FloatFormatInvokeUserDefDB
	FloatFormatUserDefOK
	FloatFormatCreateFormat
	FloatFormatGetFormatTokenWithName
	DoesNameMatch?
	FloatFormatDelete
	FloatFormatDeleteLow
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial revision

DESCRIPTION:
		
	$Id: uiFormatGlobal.asm,v 1.1 97/04/05 01:23:23 newdeal Exp $

-------------------------------------------------------------------------------@


FloatFormatCode	segment	resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatInit

DESCRIPTION:	Initialize a new format array.

CALLED BY:	EXTERNAL ()

PASS:		bx - VM file handle

RETURN:		ax - VM handle of format array

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFormatInit	proc	far
	uses	bx,cx,bp,es,di
	class	FloatFormatClass
	.enter

	;
	; Allocate a block to use for the format array
	;
	clr	ax				; ax <- no user ID
	mov	cx, size FormatArrayHeader + size FormatEntry
						; saves a VMAttach later
	call	VMAlloc
	push	ax				;save VM handle

	;
	; Lock and initalize the block
	;
	call	VMLock				; ax <- seg addr of block
	mov	es, ax				; es <- seg addr of block

	;
	; initialize the format array header
	;
	mov	es:FAH_signature, FORMAT_ARRAY_HDR_SIG
	mov	es:FAH_numFormatEntries, 1
	mov	es:FAH_numUserDefEntries, 0
	mov	es:FAH_formatArrayEnd, cx

	;
	; initialize the the first format entry
	;
	mov	di, size FormatArrayHeader
	mov	es:[di].FE_used, 0		; indicate entry free
EC<	mov	es:[di].FE_sig, FORMAT_ENTRY_SIG >

	;
	; Mark the block as dirty and release it
	;
	call	VMDirty
	call	VMUnlock
	pop	ax				;ax <- VM handle of array

	.leave
	ret
FloatFormatInit	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatInitFormatList

DESCRIPTION:	

CALLED BY:	EXTERNAL ()

PASS:		es:0 - FormatInfoStruc

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	don't set the selection in the init code
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatInitFormatList	proc	far
	uses	ax,bx,cx,dx,di,si,bp
	.enter

EC<	call	ECCheckFormatInfoStruc_ES >

	call	FISGetFormatCount	; cx <- pre-def, dx <- user-def
	add	dx, cx			; dx <- num entries

	xchg	cx, dx

	mov	bx, es:FIS_childBlk
	mov	si, offset FormatsList
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_CALL
	call	ObjMessage		; destroys ax,cx,dx,bp

	clr	cx			; don't really care what's selected
	mov	dx, -1			; set to indeterminate state
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage

	.leave
	ret
FloatFormatInitFormatList	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FISGetFormatCount

DESCRIPTION:	Return the count of the number of pre-defined and
		user-defined format entries.

CALLED BY:	INTERNAL (FormatDelete, ListGetNumberOfEntries,
		FormatInvokeUserDefDB, FloatFormatUpdateUI)

PASS:		es:0 - FormatInfoStruc

RETURN:		cx - number of pre-defined formats
		dx - number of user-defined formats

DESTROYED:	ax,bx,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FISGetFormatCount	proc	near
	uses	es,bp
	.enter

EC<	call	ECCheckFormatInfoStruc_ES >

	mov	cx, NUM_PRE_DEF_FORMATS
	mov	ax, es:FIS_userDefFmtArrayBlkHan
	mov	bx, es:FIS_userDefFmtArrayFileHan
	clr	dx
	tst	bx
	je	done
	call	VMLock			; ax <- segment, bp <- mem han

	mov	es, ax
EC<	cmp	es:FAH_signature, FORMAT_ARRAY_HDR_SIG >
EC<	ERROR_NE FLOAT_FORMAT_BAD_FORMAT_ARRAY >
	mov	dx, es:FAH_numUserDefEntries
	call	VMUnlock
done:
	.leave
	ret
FISGetFormatCount	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatGetFormatParamsWithListEntry

DESCRIPTION:	

CALLED BY:	EXTERNAL ()

PASS:		es:0 - FormatInfoStruc
		       with FIS_curSelection
			    FIS_userDefFmtArrayFileHan
			    FIS_userDefFmtArrayBlkHan

RETURN:		FID_curParams - FormatParams filled
		cx - format token
		carry set if error (FIS_curSelection = FORMAT_ID_INDETERMINATE)

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	If the list entry number falls into the user-defined category,
	we will store the list entry number in the format entry once an
	association has been determined.  This will allow
	FloatFormatChangeFormat and FloatFormatDeleteFormat to work
	on the correct entry given the list entry number.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatGetFormatParamsWithListEntry	proc	far
	uses	ax,bx,dx,ds,si,di,bp
	.enter

EC<	call	ECCheckFormatInfoStruc_ES >

	mov	ax, es:FIS_curSelection
	cmp	ax, FORMAT_ID_INDETERMINATE
	stc
	LONG je	exit

EC<	cmp	ax, FORMAT_ID_PREDEF		; Is it a PreDef token?	 >
EC<	ERROR_AE FLOAT_FORMAT_BAD_FORMAT_ENTRY 	; should be entry number >

	mov	bx, es:FIS_userDefFmtArrayFileHan
	mov	cx, es:FIS_userDefFmtArrayBlkHan
	mov	di, offset FIS_curParams

	cmp	ax, NUM_PRE_DEF_FORMATS
	jge	userDefFmt

	;-----------------------------------------------------------------------
	; predefined format

NOFXIP<	segmov	ds, dgroup, cx						>
FXIP <	mov	cx, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			;ds = dgroup		>
FXIP <	mov_tr	bx, cx				;restore bx		>
	mov	cx, size FormatParams
	mul	cx				; dx:ax <- offset
	mov	si, ax
	add	si, offset FormatPreDefTbl
EC<	cmp	ds:[si].FP_signature, FORMAT_PARAMS_ID >
EC<	ERROR_NE FLOAT_FORMAT_BAD_PARAMS >

	rep	movsb
	mov	cx, ax
	or	cx, FORMAT_ID_PREDEF
	jmp	short done

userDefFmt:
	;-----------------------------------------------------------------------
	; user-defined format

	xchg	ax, cx				; ax <- user def array han
						; cx <- list entry number
	call	VMLock				; ax <- segment, bp <- mem han
	mov	ds, ax				; ds:si <- first format entry
	mov	si, size FormatArrayHeader

EC<	cmp	ds:FAH_signature, FORMAT_ARRAY_HDR_SIG >
EC<	ERROR_NE FLOAT_FORMAT_BAD_FORMAT_ARRAY >
EC<	mov	dx, ds:FAH_formatArrayEnd >

	;
	; loop to locate entry
	;
locateLoop:
	cmp	ds:[si].FE_used, 0		; is entry used?
	je	next				; next if not

EC<	cmp	ds:[si].FE_used, -1 >		; check for legal flag
EC<	ERROR_NE FLOAT_FORMAT_BAD_FORMAT_ENTRY >
;EC<	cmp	ds:[si].FE_sig, FORMAT_ENTRY_SIG >
;EC<	ERROR_NE FLOAT_FORMAT_BAD_ENTRY_SIGNATURE >
	cmp	cx, ds:[si].FE_listEntryNumber
	je	found

next:
	add	si, size FormatEntry		; inc offset
EC<	cmp	si, dx >			; error if offset exceeds end
EC<	ERROR_AE FLOAT_FORMAT_BAD_FORMAT_LIST >
	jmp	short locateLoop		; loop

found:
	;
	; copy FormatParams over
	; ds:si = FormatEntry
	;
	push	si				; save format token
	mov	cx, size FormatParams
	rep	movsb
	call	VMUnlock
	pop	cx				; retrieve format token
	
done:
	mov	es:FIS_curToken, cx
	clc

exit:
	.leave
	ret
FloatFormatGetFormatParamsWithListEntry	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatGetFormatParamsWithToken

DESCRIPTION:	

CALLED BY:	EXTERNAL ()

PASS:		es:0 - FormatInfoStruc
		       with FIS_curToken
			    FIS_userDefFmtArrayFileHan
			    FIS_userDefFmtArrayBlkHan
		dx:bp - buffer to place FormatParams

RETURN:		buffer filled

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatGetFormatParamsWithToken	proc	far
	uses	ax,bx,cx,dx,bp,ds,si,es,di
	.enter

EC<	call	ECCheckFormatInfoStruc_ES >

	mov	cx, es:FIS_curToken
	push	dx,bp
	call	FloatFormatLockFormatEntry	; ds:si <- address of entry
						; bp - mem handle
						; dx - offset to end of array
	pop	es,di
	mov	cx, size FormatParams
	rep	movsb
	call	VMUnlock

	.leave
	ret
FloatFormatGetFormatParamsWithToken	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatProcessFormatSelected

DESCRIPTION:	

CALLED BY:	EXTERNAL ()

PASS:		es:0 - FormatInfoStruc

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		Under DBCS, this routine allocates 1098 bytes of stack!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatProcessFormatSelected	proc	far
	uses	ax,bx,cx,dx,di
	locals	local	FFA_stackFrame
	samples	local	SamplesStruc
	ForceRef locals
	ForceRef samples

if DBCS_PCGEOS
	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di
endif

	.enter


DBCS< EC< call	ECCheckStack		>	>
EC<	call	ECCheckFormatInfoStruc_ES >

	call	FloatFormatGetFormatParamsWithListEntry	; cx <- token
	mov	es:FIS_curToken, cx
	mov	bx, es:FIS_childBlk

	;
	; enable format rep and sample 1
	;
	mov	di, offset UIFmtMainFormatStr
	call	SetEnabledNoFixup
ifdef GPC_ONLY
	mov	di, offset UIFmtMainSample1Group
else
	mov	di, offset UIFmtMainSample1
endif
	call	SetEnabledNoFixup

	;-----------------------------------------------------------------------
	; disable Create trigger if selected format is a Date/Time

	test	es:FIS_curParams.FP_params.FFAP_FLOAT.formatFlags, \
					mask FFDT_DATE_TIME_OP
	je	notDateEnableTriggers			; branch if not

	mov	di, offset UIFmtMainFormatGroup
	call	SetNotEnabledNoFixup
ifdef GPC_ONLY
	mov	di, offset UIFmtMainSample2Group
else
	mov	di, offset UIFmtMainSample2
endif
	call	SetNotEnabledNoFixup
	push	cx
ifdef GPC_ONLY
	mov	di, offset UIFmtMainSample2Base
else
	mov	di, offset UIFmtMainSample2
endif
	mov	cx, offset UIFmtMainSample2NullMoniker
	call	useMoniker
	pop	cx

	test	es:FIS_features, mask FCF_DEFINE_FORMATS
	jz	processEditDel

	mov	di, offset UIFmtMainTriggerCreate
	call	SetNotEnabledNoFixup
	jmp	processEditDel

notDateEnableTriggers:
	mov	di, offset UIFmtMainFormatGroup
	call	SetEnabledNoFixup
ifdef GPC_ONLY
	mov	di, offset UIFmtMainSample2Group
else
	mov	di, offset UIFmtMainSample2
endif
	call	SetEnabledNoFixup
	push	cx
ifdef GPC_ONLY
	mov	di, offset UIFmtMainSample2Base
else
	mov	di, offset UIFmtMainSample2
endif
	mov	cx, offset UIFmtMainSample2MainMoniker
	call	useMoniker
	pop	cx

	test	es:FIS_features, mask FCF_DEFINE_FORMATS
	jz	processEditDel

	mov	di, offset UIFmtMainTriggerCreate
	call	SetEnabledNoFixup

processEditDel:
	;-----------------------------------------------------------------------
	; disable Edit and Delete triggers if the selected format is pre-defined

	test	es:FIS_features, mask FCF_DEFINE_FORMATS
	jz	doUpdate				;branch if no create

	mov	di, offset UIFmtMainTriggerDelete
	test	cx, FORMAT_ID_PREDEF			; pre-def format?
	je	enableTriggers				; branch if not

	call	SetNotEnabledNoFixup
	mov	di, offset UIFmtMainTriggerEdit
	call	SetNotEnabledNoFixup
	jmp	short doUpdate

enableTriggers:
	call	SetEnabledNoFixup
	mov	di, offset UIFmtMainTriggerEdit
	call	SetEnabledNoFixup

doUpdate:

EC<	call	ECCheckFormatInfoStruc_ES >
	call	UpdateMainSamples

	.leave
if DBCS_PCGEOS
	pop	di
	call	ThreadReturnStackSpace
endif
	ret

useMoniker	label	near
	push	ax, cx, dx, bp, si	
	mov	si, di

ifndef GPC_ONLY
	; First, we'll see if we are using the correct moniker.
	; If so, we do nothing to avoid flashing on the screen

	push	cx				; save new moniker
	mov	ax, MSG_GEN_GET_VIS_MONIKER
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			; current moniker -> ax
	pop	cx
	cmp	ax, cx				; compare current & new monikers
	je	doneMoniker			; if equal, we're done
endif

	; The moniker is different, so use a new one

ifdef GPC_ONLY
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	mov	dx, bx				; ^ldx:bp = text
	mov	bp, cx
	clr	cx				; null-terminated
else
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
endif
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
ifdef GPC_ONLY
	mov	ax, MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE
	mov	cx, (mask VTS_EDITABLE or mask VTS_SELECTABLE) shl 8
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
endif
doneMoniker::
	pop	ax, cx, dx, bp, si
	retn
FloatFormatProcessFormatSelected	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatInvokeUserDefDB

DESCRIPTION:	

CALLED BY:	EXTERNAL ()

PASS:		es:0 - FormatInfoStruc

RETURN:		nothing, ds is not fixed up

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatInvokeUserDefDB	proc	far
	uses	ax,bx,cx,dx,di,si,bp
	.enter

EC<	call	ECCheckFormatInfoStruc_ES >

if 0
	;-----------------------------------------------------------------------
	; preliminary check to see that space exists

	push	dx
	call	FloatFormatGetFormatCount
	cmp	dx, MAX_FORMATS
	pop	dx
	jl	proceed

	mov	bp, offset formatTooManyFormats
	call	MyError
	ret

proceed:
endif
	;-----------------------------------------------------------------------
	; deal with name (clear format name field)

	mov	bx, es:FIS_childBlk
	mov	dx, cs
	mov	ax, offset nullString
	mov	di, offset UIFmtNameGroup
	call	SetText

	;-----------------------------------------------------------------------
	; deal with ranges

	mov	al, es:FIS_curParams.FP_params.FFAP_FLOAT.decimalLimit
	cbw					; possibly negative, so...
	mov	dx, ax
	mov	di, offset UIFmtNumDecimals
	call	SetRange

	mov	al, es:FIS_curParams.FP_params.FFAP_FLOAT.decimalOffset
	cbw
	mov	dx, ax
	mov	di, offset UIFmtDecimalOffset
	call	SetRange

	;-----------------------------------------------------------------------
	; deal with fixed/scientific

	mov	ax, es:FIS_curParams.FP_params.FFAP_FLOAT.formatFlags

	push	ax
	clr	cx				; assume fixed format
	mov	di, offset UIFmtBooleanComp1
	test	ax, mask FFAF_SCIENTIFIC	; check bit
	je	setUIFmt			; branch if assumption correct
	inc	cx				; else modify
setUIFmt:
	call	SetEntryPosNoFixup		; ax intact
	pop	ax

	;-----------------------------------------------------------------------
	; deal with booleans

	clr	cx

	test	ax, mask FFAF_USE_COMMAS
	je	10$
	or	cx, mask FO_COMMA
10$:
	test	ax, mask FFAF_PERCENT
	je	20$
	or	cx, mask FO_PCT
20$:
	test	ax, mask FFAF_NO_LEAD_ZERO
	je	30$
	or	cx, mask FO_LEAD_ZERO
30$:
	test	ax, mask FFAF_NO_TRAIL_ZEROS
	je	40$
	or	cx, mask FO_TRAIL_ZERO
40$:
	test	ax, mask FFAF_SIGN_CHAR_TO_FOLLOW_HEADER
	je	50$
	or	cx, mask FO_HEADER_SIGN_POS
50$:
	test	ax, mask FFAF_SIGN_CHAR_TO_PRECEDE_TRAILER
	je	60$
	or	cx, mask FO_TRAILER_SIGN_POS
60$:
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	bx, es:FIS_childBlk
	push	si
	mov	si, offset UIFmtBooleanComp2
	clr	di
	call	ObjMessage			; destroys ax,cx,dx,bp
	pop	si

	;-----------------------------------------------------------------------
	; deal with strings

	mov	bx, es:FIS_childBlk
	mov	dx, es

	lea	ax, es:FIS_curParams.FP_params.FFAP_FLOAT.preNegative
	mov	di, offset UIFmtPreNegative
	call	SetText

	lea	ax, es:FIS_curParams.FP_params.FFAP_FLOAT.postNegative
	mov	di, offset UIFmtPostNegative
	call	SetText

	lea	ax, es:FIS_curParams.FP_params.FFAP_FLOAT.prePositive
	mov	di, offset UIFmtPrePositive
	call	SetText

	lea	ax, es:FIS_curParams.FP_params.FFAP_FLOAT.postPositive
	mov	di, offset UIFmtPostPositive
	call	SetText

	lea	ax, es:FIS_curParams.FP_params.FFAP_FLOAT.header
	mov	di, offset UIFmtHeader
	call	SetText

	lea	ax, es:FIS_curParams.FP_params.FFAP_FLOAT.trailer
	mov	di, offset UIFmtTrailer
	call	SetText

	call	FormatUpdateSamples

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	si, offset UIFmtUserDefDB
	clr	di
	call	ObjMessage			; destroys ax,cx,dx,bp

if 1
	; deal with name (set format name with cursor at start)

	mov	bx, es:FIS_childBlk
	mov	dx, es
	lea	ax, es:FIS_curParams.FP_formatName
	mov	di, offset UIFmtNameGroup
	call	SetTextStart
endif

ifdef GPC_ONLY
	mov	bx, es:FIS_childBlk
	mov	cx, NUM_TEXT_OBJS
	clr	di
textLoop:
	push	cx, di
	mov	si, cs:textObjList[di]
	mov	ax, MSG_META_DUMMY		; force building Vis part
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	clr	cl				; set
	mov	ch, mask VTS_EDITABLE or mask VTS_SELECTABLE ; clear
	mov	ax, MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, di
	add	di, size lptr
	loop	textLoop
endif

	.leave
	ret
FloatFormatInvokeUserDefDB	endp

SBCS <nullString	char	0					>
DBCS <nullString	wchar	0					>

ifdef GPC_ONLY

textObjList	label	lptr
	lptr	offset	UIFmtFormatStr,
		offset	UIFmtSample1Base,
		offset	UIFmtSample1Sample,
		offset	UIFmtSample2Base,
		offset	UIFmtSample2Sample
NUM_TEXT_OBJS = ($-textObjList) / (size lptr)

endif



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatUserDefOK

DESCRIPTION:	

CALLED BY:	EXTERNAL ()

PASS:		es:0 - FormatInfoStruc

RETURN:		cx - non zero if error
		ds is not fixed up

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	free formatInfoStrucHan

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatUserDefOK	proc	far
	uses	ax,bx,di,si,bp
	.enter

EC<	call	ECCheckFormatInfoStruc_ES >

	;-----------------------------------------------------------------------
	; send APPLY to GenInteraction

	mov	ax, MSG_GEN_APPLY
	call	FloatFormatCallUserDefDB

	;-----------------------------------------------------------------------
	; get name

	mov	bx, es:FIS_childBlk
	mov	di, offset UIFmtNameGroup
	call	GetTextNoFixup			; bx <- text block
	jnc	10$

	call	MemFree
	mov	bp, offset formatNoName
	call	MyError
	stc
	jmp	short exit

10$:
	;-----------------------------------------------------------------------
	; update name in FormatInfoStruc

	push	ds
	call	MemLock
	mov	ds, ax
	clr	si				; ds:si <- string
	mov	di, offset FIS_curParams + offset FP_formatName

	LocalCopyString

	call	MemFree
	pop	ds

	call	FloatFormatCreateFormat
	jc	exit

EC<	call	ECCheckFormatInfoStruc_ES >

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	FloatFormatCallUserDefDB
	clc

exit:
	pushf
	mov	ax, MSG_META_GET_OBJ_BLOCK_OUTPUT
	call	FloatFormatCallUserDefDB	; ^lcx:dx = FloatFormat ctrl
	movdw	bxsi, cxdx
	mov	ax, MSG_META_DELETE_VAR_DATA
	mov	cx, TEMP_FLOAT_CTRL_USER_DEFINE_ACTIVE
	mov	di, mask MF_CALL
	call	ObjMessage
	popf

	mov	cx, 0				; don't nuke carry
	jnc	done
	dec	cx
done:
	.leave
	ret
FloatFormatUserDefOK	endp

FloatFormatCallUserDefDB	proc	near
	mov	bx, es:FIS_childBlk		; bx <- child block
	mov	si, offset UIFmtUserDefDB
	mov	di, mask MF_CALL
	call	ObjMessage
	ret
FloatFormatCallUserDefDB	endp



COMMENT @-----------------------------------------------------------------------
FUNCTION:	FloatFormatCreateFormat

DESCRIPTION:

CALLED BY:	INTERNAL ()

PASS:		es:0 - FormatInfoStruc

RETURN:		carry set if error

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatCreateFormat	proc	near
	.enter

EC<	call	ECCheckFormatInfoStruc_ES >

	;-----------------------------------------------------------------------
	; is name unique?

	call	FloatFormatGetFormatTokenWithName ; cx <- token, dest ax,bx,dx
	cmp	cx, FLOAT_FORMAT_FORMAT_NAME_NOT_FOUND
	je	nameUnique

EC<	call	ECCheckFormatInfoStruc_ES >

	;
	; name not unique
	; this is ok if editing and maintaining the same name
	;
	cmp	es:FIS_editFlag, 0		; editing?
	je	nameNotUnique			; error if not

	cmp	cx, es:FIS_curToken		; else same token?
	je	nameUnique			; ok if so

nameNotUnique:
	mov	bp, offset formatNameNotUnique
	jmp	short error

nameUnique:
	;-----------------------------------------------------------------------
	; get spreadsheet library to perform the operation

EC<	call	ECCheckFormatInfoStruc_ES >

	cmp	es:FIS_editFlag, 0		; editing?
	je	defining			; branch if not

	;
	; editing
	; get the format token for the selected list entry
	;
	mov	cx, es:FIS_curSelection
	call	FloatFormatGetFormatToken	; cx <- format token

	mov	dx, es				; dx:bp <- buffer
	mov	bp, offset FIS_curParams
	call	FloatFormatChangeFormat	; nukes es,di,bp
	jmp	short doOp


defining:
	mov	dx, es				; dx:bp <- buffer
	mov	bp, offset FIS_curParams
	call	FloatFormatAddFormat		; nukes ax,bx,es,di,bp

doOp:
	cmp	cx, FLOAT_FORMAT_TOO_MANY_FORMATS
	mov	bp, offset formatTooManyFormats
	je	error

	cmp	cx, FLOAT_FORMAT_CANNOT_ALLOC
	mov	bp, offset formatAllocError
	je	error


	; Require user to update UI by sending out both format notifications
	; after adding, deleting or changing a format.  Nuke intervening code
	; if that works. -- cah 3/14/93

if 0
	;-----------------------------------------------------------------------
	; update the dynamic list

EC<	call	ECCheckFormatInfoStruc_ES >

	cmp	es:FIS_editFlag, 0
	je	addEntry
	
	mov	cx, es:FIS_curSelection
	push	cx
	mov	di, offset FormatsList
	call	DeleteEntry
	pop	cx

	dec	cx
	call	AddAndSelectEntry
	jmp	short done

addEntry:
	call	FloatFormatGetFormatCount	; cx <- pre-def
						; dx <- user-def
	add	cx, dx
	dec	cx				; cx <- 0 based offset
	dec	cx				; position before ins
	call	AddAndSelectEntry
endif

done::
	clc

exit:
	.leave
	ret

error:
	call	MyError
	stc
	jmp	short exit

FloatFormatCreateFormat	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatGetFormatTokenWithName

DESCRIPTION:	Locates a format entry given the name.

		NOTE:
		It is up to the user of the float controller library to ensure
		uniqueness.  The float controller library does not require it.
		All it does is search for the first name that matches, so
		if name uniqueness is important to you, perform a check with
		this routine before calling MSG_FLOAT_FORMAT_ADD_FORMAT.

CALLED BY:	EXTERNAL (also FloatFormatCreateFormat)

PASS:		es:0 - FormatInfoStruc

RETURN:		cx - format token of format entry containing name
		     FLOAT_FORMAT_FORMAT_NAME_NOT_FOUND if not found

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFormatGetFormatTokenWithName	proc	far
	uses	ax,bx,dx,bp,ds,si,di
	.enter

EC<	call	ECCheckFormatInfoStruc_ES >

	;
	; retieve resource handle holding the name
	;
	mov	di, offset FIS_curParams + offset FP_formatName ; es:di <- name

	;-----------------------------------------------------------------------
	; search pre-defined format table

NOFXIP<	segmov	ds, dgroup, ax						>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			;ds = dgroup		>
	mov	si, offset FormatPreDefTbl	; ds:si <- pre def table

	mov	bx, size FormatParams		; bx <- bytes to next entry
	mov	dx, offset FormatPreDefTblEnd	; dx <- end of table
locPreDefLoop:
EC<	cmp	ds:[si].FP_signature, FORMAT_PARAMS_ID >
EC<	ERROR_NE FLOAT_FORMAT_BAD_PARAMS >

	call	DoesNameMatch?
	jc	nextPreDef

	;
	; found in pre-def table
	;
	sub	si, offset FormatPreDefTbl
	or	si, FORMAT_ID_PREDEF		; indicate origin
	clc					; indicate success
	jmp	short done

nextPreDef:
	add	si, bx				; si <- offset to next entry
	cmp	si, dx				; at end yet?
	jl	locPreDefLoop			; loop if not
EC<	ERROR_G FLOAT_FORMAT_ASSERTION_FAILED >

	;-----------------------------------------------------------------------
	; search user-defined format array

EC<	call	ECCheckFormatInfoStruc_ES >

	mov	cx, size FormatArrayHeader	; specify first entry
	call	FloatFormatLockFormatEntry	; ds:si <- format entry
						; bp <- VM mem handle
						; dx <- offset to end of array

	mov	bx, size FormatEntry
locLoop:
	cmp	ds:[si].FE_used, 0		; is entry in use?
	je	next				; next entry if not

EC<	call	ECCheckUsedEntry >
	call	DoesNameMatch?
	jnc	foundInUserDef

next:
	add	si, bx				; else next entry
	cmp	si, dx				; end of array?
	jl	locLoop				; loop if not
EC<	ERROR_G FLOAT_FORMAT_ASSERTION_FAILED >

	mov	si, FLOAT_FORMAT_FORMAT_NAME_NOT_FOUND	; indicate no match

foundInUserDef:
	call	VMUnlock

done:

EC<	call	ECCheckFormatInfoStruc_ES >
	mov	cx, si				; cx <- format token / error
	.leave
	ret
FloatFormatGetFormatTokenWithName	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoesNameMatch?

DESCRIPTION:	

CALLED BY:	INTERNAL (FloatFormatGetFormatTokenWithName)

PASS:		es:di - null terminated name1
		ds:si - FormatParams structure

RETURN:		carry clear if match, set otherwise

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version
	witt	11/93		DBCS-ized string compare

-------------------------------------------------------------------------------@

DoesNameMatch?	proc	near	uses	di,si
	.enter

	add	si, offset FP_formatName
matchLoop:
	LocalGetChar ax, esdi, NO_ADVANCE
SBCS<	cmpsb						>
DBCS<	cmpsw						>
	jne	noMatch

	LocalIsNull	ax
	jne	matchLoop			; not finished..

	clc
	jmp	short done

noMatch:
	stc

done:
	.leave
	ret
DoesNameMatch?	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatDelete

DESCRIPTION:	

CALLED BY:	EXTERNAL ()

PASS:		es:0 - FormatInfoStruc

RETURN:		carry clear if format deleted
		    cx - format token of deleted format
		carry set if delete aborted

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

FloatFormatDelete	proc	far
	uses	ax,bx,cx,dx,di,si,bp
	.enter
EC<	call	ECCheckFormatInfoStruc_ES >

	;-----------------------------------------------------------------------
	; get user to confirm deletion

	mov	bx, handle formatConfirmDeleteStr
	mov	si, offset formatConfirmDeleteStr
	mov	cx, es				; cx:dx <- format name
	mov	dx, offset FIS_curParams.FP_formatName
	call	ConfirmDialog
	jc	done

	;-----------------------------------------------------------------------
	; perform deletion

	mov	cx, es:FIS_curToken
	call	FloatFormatDeleteLow	; nukes ax,bx,cx,dx,di,bp

done:
EC<	call	ECCheckFormatInfoStruc_ES >
	.leave
	ret
FloatFormatDelete	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatDeleteLow

DESCRIPTION:	Deletes the given format from the format array.

CALLED BY:	INTERNAL (FloatFormatDelete)

PASS:		es:0 - FormatInfoStruc
		cx - format token to delete

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	zero out the FE_used field in the format entry
	update the list entry numbers
	decrement the FAH_numUserDefEntries in the format array
	for all styles that use the format,
		replace the format with FORMAT_ID_GENERAL

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFormatDeleteLow	proc	near	uses	ds,si,es
	.enter
EC<	call	ECCheckFormatInfoStruc_ES >

	;-----------------------------------------------------------------------
	; free format entry

	call	FloatFormatLockFormatEntry	; ds:si <- format entry
						; bp <- VM mem handle
						; dx <- offset to end of array
	mov	ds:[si].FE_used, 0

	call	FloatFormatDeleteUpdateListEntries	; dest ax,cx

	dec	ds:FAH_numUserDefEntries	; dec count
EC<	ERROR_L	FLOAT_FORMAT_ASSERTION_FAILED >

	call	VMDirty
	call	VMUnlock
	mov	cx, si

	.leave
	ret
FloatFormatDeleteLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatFormatGetModifiedFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create new format from modification of existing format

CALLED BY:	GLOBAL
PASS:		es:0	= FormatInfoStruc
			es:[FIS_curToken] = existing format to modify
			es:[FIS_userDefFmtArrayFileHan] = user def array
			es:[FIS_userDefFmtArrayBlkHan] = user def array
		dx	= FloatModifyFormatFlags
RETURN:		ax = token of modified format
			(same as FIS_curToken if error)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Does not handle date formats.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FloatFormatGetModifiedFormat	proc	far
	uses	bx, cx, dx, bp, si, di, ds
	.enter
EC <	call	ECCheckFormatInfoStruc_ES				>
	;
	; get params for existing format to modify
	;
	mov	cx, es:[FIS_curToken]
	test	cx, FORMAT_ID_PREDEF
	jz	findUserDef
	;
	; get params for pre-defined format
	;	cx = pre-defined FormatIdType
	;
	call	getPreDefFormat
	jmp	 short haveExistingFormat

findUserDef:
	;
	; get params for user-defined format
	;
	mov	bx, es:[FIS_userDefFmtArrayFileHan]
	mov	ax, es:[FIS_userDefFmtArrayBlkHan]
	call	VMLock				; ax = segment, bp = mem han
	mov	ds, ax
EC <	cmp	ds:[FAH_signature], FORMAT_ARRAY_HDR_SIG		>
EC <	ERROR_NE FLOAT_FORMAT_BAD_FORMAT_ARRAY				>
	mov	si, cx				; ds:si = desired user def
EC <	cmp	ds:[si].FE_used, -1		; check for legal flag	>
EC <	ERROR_NE FLOAT_FORMAT_BAD_FORMAT_ENTRY				>
if ((offset FE_params) ne 0)
	add	si, offset FE_params
endif
	mov	di, offset FIS_curParams
	mov	cx, size FIS_curParams
	rep movsb
	call	VMUnlock
haveExistingFormat:
	;
	; make requested modifications
	;	dx = FloatModifyFormatFlags
	;
	test	dx, mask FMFF_COMMA
	jz	afterComma
	;
	; toggle commas
	;
	xornf	es:[FIS_curParams].FP_params.FFAP_FLOAT.formatFlags,
							mask FFAF_USE_COMMAS
afterComma:
	test	dx, mask FMFF_CURRENCY
	jz	afterCurrency
	;
	; set currency mode, retaining comma and decimal settings
	;
	mov	cx, FORMAT_ID_CURRENCY
	call	modifyFromPreDefFormat
afterCurrency:
	test	dx, mask FMFF_PERCENTAGE
	jz	afterPercentage
	;
	; set percentage mode, retaining comma and decimal settings
	;
	mov	cx, FORMAT_ID_PERCENTAGE
	call	modifyFromPreDefFormat
afterPercentage:
	test	dx, mask FMFF_SET_DECIMALS
	jz	afterDecimals
	;
	; modify number of decimals
	;
.assert ((offset FMFF_DECIMALS) eq 0)
	andnf	dl, mask FMFF_DECIMALS		; dl = decimals
	mov	es:[FIS_curParams].FP_params.FFAP_FLOAT.decimalLimit, dl
	andnf	es:[FIS_curParams].FP_params.FFAP_FLOAT.formatFlags,
						not mask FFAF_NO_TRAIL_ZEROS
afterDecimals:
	;
	; see if this matches existing pre-defined or user-defined format
	;
NOFXIP<	segmov	ds, dgroup, ax						>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			; ds = dgroup		>
	mov	si, offset FormatPreDefTbl	; ds:si = pre def table
searchPreDefLoop:
EC <	cmp	ds:[si].FP_signature, FORMAT_PARAMS_ID			>
EC <	ERROR_NE FLOAT_FORMAT_BAD_PARAMS				>
	push	si, di
.assert ((offset FP_params) eq 0)
	mov	di, offset FIS_curParams.FP_params.FFAP_FLOAT
	mov	cx, size FloatFloatToAsciiParams	; just compare format
	repe cmpsb
	pop	si, di
	LONG je	foundMatchingPreDef
	add	si, size FormatParams
	cmp	si, (offset FormatPreDefTbl) + \
			((FormatIdType) and (not FORMAT_ID_PREDEF))
	jb	searchPreDefLoop
	;
	; not found in pre-defined formats, check user-defined formats
	;
	mov	bx, es:[FIS_userDefFmtArrayFileHan]
	mov	ax, es:[FIS_userDefFmtArrayBlkHan]
	call	VMLock				; ax = segment, bp = mem han
	mov	ds, ax
EC <	cmp	ds:[FAH_signature], FORMAT_ARRAY_HDR_SIG		>
EC <	ERROR_NE FLOAT_FORMAT_BAD_FORMAT_ARRAY				>
	mov	si, size FormatArrayHeader
	mov	cx, ds:[FAH_numUserDefEntries]
	jcxz	userDefNotFound
searchUserDefLoop:
EC <	cmp	ds:[si].FE_used, -1		; check for legal flag	>
EC <	ERROR_NE FLOAT_FORMAT_BAD_FORMAT_ENTRY				>
	push	si, di, cx
if ((offset FE_params) ne 0)
	add	si, offset FE_params
endif
	mov	di, offset FIS_curParams.FP_params.FFAP_FLOAT
	mov	cx, size FloatFloatToAsciiParams	; just compare format
	repe cmpsb
	pop	si, di, cx
	je	foundMatchingUserDef
	add	si, size FormatEntry
	loop	searchUserDefLoop
userDefNotFound:
	call	VMUnlock
	;
	; neither pre-defined or user-defined found, must add new entry
	;
	mov	di, offset FIS_curParams.FP_formatName	; es:di = name field
	clr	dx
	mov	ax, ds:[FAH_numUserDefEntries]		; dx.ax = number
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii			; generate unique name
	mov	dx, es
	mov	bp, offset FIS_curParams		; add this
	call	FloatFormatAddFormat			; dx = token
	mov	ax, dx					; ax = token
	jnc	done					; added successfully
	mov	ax, es:[FIS_curToken]			; else return original
	jmp	short done

foundMatchingUserDef:
	call	VMUnlock
	mov	ax, si					; ax = token
	jmp	short done

foundMatchingPreDef:
	sub	si, offset FormatPreDefTbl
	mov	ax, si
	ornf	ax, FORMAT_ID_PREDEF			; ax = token
done:
	.leave
	ret

;
; Pass:	cx = pre-defined FormatIdType
;	ax = FloatFloatToAsciiFormatFlags
;	bl = decimal limit
;
modifyFromPreDefFormat	label	near
	mov	ax, es:[FIS_curParams].FP_params.FFAP_FLOAT.formatFlags
	mov	bl, es:[FIS_curParams].FP_params.FFAP_FLOAT.decimalLimit
	push	ax, bx
	call	getPreDefFormat
	pop	ax, bx
						; ax = flags to keep
	andnf	ax, mask FFAF_USE_COMMAS or mask FFAF_NO_TRAIL_ZEROS
	andnf	es:[FIS_curParams].FP_params.FFAP_FLOAT.formatFlags,
			not (mask FFAF_USE_COMMAS or mask FFAF_NO_TRAIL_ZEROS)
	ornf	es:[FIS_curParams].FP_params.FFAP_FLOAT.formatFlags, ax
	mov	es:[FIS_curParams].FP_params.FFAP_FLOAT.decimalLimit, bl
	retn

;
; Pass:	cx = pre-defined FormatIdType
;
getPreDefFormat	label	near
	andnf	cx, not FORMAT_ID_PREDEF	; cx = predef token
NOFXIP<	segmov	ds, dgroup, ax						>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			; ds = dgroup		>
	mov	si, offset FormatPreDefTbl	; ds:si = pre def table
	add	si, cx				; ds:si = desired pre def
EC <	cmp	ds:[si].FP_signature, FORMAT_PARAMS_ID			>
EC <	ERROR_NE FLOAT_FORMAT_BAD_PARAMS				>
	mov	di, offset FIS_curParams
	mov	cx, size FIS_curParams
	rep movsb
	retn

FloatFormatGetModifiedFormat	endp

FloatFormatCode	ends
