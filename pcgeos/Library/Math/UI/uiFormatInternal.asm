
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		formatList.asm

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial revision

DESCRIPTION:
	Routines for dealing with the UIFmtMainListGroup GenList.

	$Id: uiFormatInternal.asm,v 1.1 97/04/05 01:23:27 newdeal Exp $

-------------------------------------------------------------------------------@


FloatFormatCode	segment resource

;
; The samples have been converted for speed:
;	1234.567
;	  -0.567
; If you change them, change these!
;
sample1Num	FloatNum <0x9fbe, 0x2f1a, 0x24dd, 0x9a52, 0x4009>

sample2Num	FloatNum <0xf3b6, 0xd4fd, 0xe978, 0x9126, 0xbffe>



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatFormatSelected

DESCRIPTION:	Will disable "Delete Format" trigger if the chose format is
		pre-defined.

CALLED BY:	INTERNAL (MSG_FORMAT_SELECTED)

PASS:		*ds:si - instance

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if selected item is a pre-defined format then
	    update sample area
	else
	    get target to update the sample area
	endif

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FormatFormatSelected	method	FloatFormatClass,
			MSG_FORMAT_SELECTED

	call	GetChildBlock			; bx <- child block
	mov	di, offset FormatsList
	call	GetEntryPos			; cx <- entry pos, dest ax,dx,di
	tst	cx
	js	done

	mov	ax, MSG_FLOAT_CTRL_FORMAT_SELECTED
	call	FISSendToOutput

done:
	ret
FormatFormatSelected	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatDelete

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_FORMAT_DELETE)

PASS:		*ds:si - float controller instance

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

FormatDelete	method dynamic FloatFormatClass, MSG_FORMAT_DELETE
	call	GetChildBlock			; bx <- child block
	mov	di, offset FormatsList
	call	GetEntryPos			; cx <- entry pos, dest ax,dx,di
	tst	cx
	js	done

	mov	ax, MSG_FLOAT_CTRL_FORMAT_DELETE
	call	FISSendToOutput

done:
	ret
FormatDelete	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatApply

DESCRIPTION:	User has chosen a format.  Get the token and store it in
		the cell's attribute structure.

CALLED BY:	INTERNAL (MSG_FORMAT_APPLY)

PASS:		

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

FormatApply	method dynamic FloatFormatClass, MSG_FORMAT_APPLY
	call	GetChildBlock			; bx <- child block
	mov	di, offset FormatsList
	call	GetEntryPos			; cx <- entry pos, dest ax,dx,di
	tst	cx
	js	done

	mov	ax, MSG_FLOAT_CTRL_FORMAT_APPLY
	call	FISSendToOutput

done:
	ret
FormatApply	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatGetFormatCount

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

if 0
FloatFormatGetFormatCount	proc	near	uses	es,bp
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
FloatFormatGetFormatCount	endp
endif



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatGetFormatToken

DESCRIPTION:	Returns the format token that was assigned to the list entry
		number.

		This is useful for applications (eg. GeoCalc) that do not
		save the format token returned by FloatFormatGetFormatInfo.

		The routine that returns a list entry number given a token
		is FloatFormatGetListEntryWithToken.

		NOTE:
		-----
		As written, this routine does not deal with pre-defined
		formats. This is because the only routines that call this
		in GeoCalc currently are the Editing and Deleting routines,
		and these operations aren't allowed on pre-defined formats.

CALLED BY:	INTERNAL (FloatFormatCreateFormat)

PASS:		es:0 - FormatInfoStruc
		cx - list entry number

RETURN:		cx - format token

DESTROYED:	bx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFormatGetFormatToken	proc	near	uses	ds,si,bp
	.enter
EC<	call	ECCheckFormatInfoStruc_ES >
EC<	cmp	cx, NUM_PRE_DEF_FORMATS >
EC<	ERROR_L	FLOAT_FORMAT_BAD_PARAMS >

	push	cx
	mov	cx, size FormatArrayHeader	; give first token
	call	FloatFormatLockFormatEntry	; ds:si <- format entry
						; bp <- VM mem handle
						; dx <- offset to end of array
	pop	cx				; retrieve list entry number
	mov	bx, size FormatEntry

locLoop:
	cmp	ds:[si].FE_used, 0		; is entry in use?
	je	next				; next entry if not

EC<	call	ECCheckUsedEntry >
	cmp	cx, ds:[si].FE_listEntryNumber	; match?
	je	found

next:
	add	si, bx				; else next entry
EC<	cmp	si, dx >			; error if past end
EC<	ERROR_GE FLOAT_FORMAT_BAD_FORMAT_LIST >
	jmp	short locLoop

found:
	call	VMUnlock
	mov	cx, si				; cx <- format token
	.leave
	ret
FloatFormatGetFormatToken	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatAddFormat

DESCRIPTION:	Add the given format to the format array.

CALLED BY:	INTERNAL (FormatUserDefOK)

PASS:		es:0 - FormatInfoStruc
		dx:bp - ptr to a FormatParams structure

RETURN:		carry set if error
		cx - FloatFormatFormatError
		if cx = FLOAT_FORMAT_NO_ERROR
		    dx - token

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFormatAddFormat	proc	far
	uses	ax,bx,ds,di,si,bp
	.enter
EC<	call	ECCheckFormatInfoStruc_ES >

	mov	bx, bp			; bx <- offset
	call	FloatFormatLockFreeFormatEntry
					; ds:si <- address of FormatEntry
					; (si = token), bp - mem handle
					; cx <- error code
					; nukes ax
	jc	done

	;
	; allocation successful
	;

	mov	ax, ds:FAH_numUserDefEntries	; assign list entry num
	add	ax, NUM_PRE_DEF_FORMATS
	mov	ds:[si].FE_listEntryNumber, ax

	inc	ds:FAH_numUserDefEntries
	mov	ds:[si].FE_used, -1	; mark entry as used

	push	es
	segmov	es, ds
	mov	di, si
	mov	ds, dx			; ds:si <- FormatParams
	mov	dx, si			; dx <- new token
	mov	si, bx

EC<	cmp	ds:[si].FP_signature, FORMAT_PARAMS_ID >
EC<	ERROR_NE FLOAT_FORMAT_BAD_PARAMS >

	mov	cx, size FormatParams
	rep	movsb
	pop	es
EC<	call	ECCheckFormatInfoStruc_ES >

	call	VMDirty
	call	VMUnlock
	mov	cx, FLOAT_FORMAT_NO_ERROR
	clc
done:
	.leave
	ret
FloatFormatAddFormat	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFormatChangeFormat

DESCRIPTION:	Replaces the parameters of the given format.

CALLED BY:	INTERNAL (FormatUserDefOK)

PASS:		es:0 - FormatInfoStruc
		cx - format token of format to delete
		dx:bp - ptr to a FormatParams structure

RETURN:		cx - 0 if successful
		     -1 otherwise

DESTROYED:	di,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFormatChangeFormat	proc	near	uses	ds,si,es
	.enter
EC<	call	ECCheckFormatInfoStruc_ES >

	push	dx,bp
	call	FloatFormatLockFormatEntry	; ds:si <- format entry
						; bp <- VM mem handle
	segmov	es, ds
	mov	di, si
	pop	ds,si
	mov	cx, size FormatParams
	rep	movsb

	call	VMDirty
	call	VMUnlock
	.leave
	ret
FloatFormatChangeFormat	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ECCheckUsedEntry

DESCRIPTION:	Check to see that the format entry is good.

CALLED BY:	INTERNAL ()

PASS:		ds:si - format entry

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Don't check FE_sig, since it is not set in non-ec files.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

if	ERROR_CHECK

ECCheckUsedEntry	proc	near
	cmp	ds:FAH_signature, FORMAT_ARRAY_HDR_SIG
	ERROR_NE FLOAT_FORMAT_BAD_FORMAT_ARRAY

	cmp	si, ds:FAH_formatArrayEnd
	ERROR_GE FLOAT_FORMAT_BAD_FORMAT_ARRAY

	cmp	ds:[si].FE_used, -1
	ERROR_NE FLOAT_FORMAT_BAD_FORMAT_ENTRY

;	cmp	ds:[si].FE_sig, FORMAT_ENTRY_SIG
;	ERROR_NE FLOAT_FORMAT_BAD_ENTRY_SIGNATURE
	ret
ECCheckUsedEntry	endp

endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatInvokeUserDefDB

DESCRIPTION:	Initialize the settings in the Define Format dialog box.

CALLED BY:	INTERNAL (FormatUserDefVisOpen)

PASS:		*ds:si - float controller instance
		cx:dx - OD of trigger

RETURN:		nothing

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	!!! GetEntryPos -> ILLEGAL_HANDLE
	!!! SUPPRESS_APPLY consistency

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FormatInvokeUserDefDB	method dynamic FloatFormatClass,
			MSG_FORMAT_USER_DEF_INVOKE

	call	GetChildBlock
	mov	di, offset FormatsList
	call	GetEntryPos			; cx <- entry pos, dest ax,di

	call	InitFormatInfoStruc		; bx <- han, es <- seg addr

	call	DerefDI
	mov	ds:[di].formatInfoStrucHan, bx
	mov	es:FIS_curSelection, cx

	;
	; save state - defining / editing
	;
	clr	al
	cmp	dx, offset UIFmtMainTriggerEdit
	jne	storeFlag
	dec	al	
storeFlag:
	mov	es:FIS_editFlag, al	; flag editting

	call	MemUnlock

	mov	cx, bx			; cx <- FormatInfoStruc mem han
	mov	ax, MSG_FLOAT_CTRL_USER_DEF_INVOKE
	call	SendToOutput

	ret
FormatInvokeUserDefDB	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatUserDefOK

DESCRIPTION:	User has hit the OK trigger. 

CALLED BY:	INTERNAL (MSG_FORMAT_USER_DEF_APPLY)

PASS:		*ds:si - float controller instance

RETURN:		nothing

DESTROYED:	ax,bx,cx,es,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	!!! adding to dynamic list

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FormatUserDefOK	method dynamic FloatFormatClass,
		MSG_FORMAT_USER_DEF_OK

	mov	ax, TEMP_FLOAT_CTRL_USER_DEFINE_ACTIVE
	call	ObjVarFindData
	jc	exit				; already active

	mov	bx, ds:[di].formatInfoStrucHan
	push	bx

	mov	ax, TEMP_FLOAT_CTRL_USER_DEFINE_ACTIVE
	clr	cx				; no extra data
	call	ObjVarAddData

	call	GetChildBlock			; bx <- child block
	mov	di, offset FormatsList
	call	GetEntryPos			; cx <- entry pos, dest ax,dx,di

	;
	; don't allocate a new block
	;
	pop	bx
	call	MemLock
	mov	es, ax
	mov	es:FIS_curSelection, cx
	call	MemUnlock
	mov	cx, bx
	mov	ax, MSG_FLOAT_CTRL_USER_DEF_OK
	call	SendToOutput
exit:
	ret
FormatUserDefOK	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatUserDefCancel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle user canceling out of Define Format dialog

CALLED BY:	MSG_FORMAT_USER_DEF_CANCEL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of FloatFormatClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatUserDefCancel		method dynamic FloatFormatClass,
						MSG_FORMAT_USER_DEF_CANCEL
	clr	bx
	xchg	bx, ds:[di].formatInfoStrucHan
	call	MemFree
	ret
FormatUserDefCancel		endm

FloatFormatCode	ends
