
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
		
	$Id: spreadsheetFormat.asm,v 1.1 97/04/07 11:14:44 newdeal Exp $

-------------------------------------------------------------------------------@


SpreadsheetFormatCode	segment	resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSFormatRequestMoniker

DESCRIPTION:	See documentation in math.def.

CALLED BY:	EXTERNAL ()

PASS:		ds:di - SpreadsheetInstance
		cx - handle of FormatInfoStruc
		     with FIS_chooseFmtListChunk = list to provide moniker for
			& FIS_curSelection = entry number to work on

RETURN:		FormatInfoStruc freed

DESTROYED:	everything (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	get user def format array
	call controller to get name
	set the moniker

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

SSFormatRequestMoniker	method	dynamic SpreadsheetClass,
				MSG_FLOAT_CTRL_REQUEST_MONIKER
	.enter

	mov	bx, cx
	push	bx
	call	SSFPrepFormatInfoStruc
	call	FloatFormatGetFormatParamsWithListEntry
	jc	done

	mov	cx, es
	mov	dx, offset FIS_curParams + offset FP_formatName

	push	bp
	mov	bx, es:FIS_childBlk
	mov	si, es:FIS_chooseFmtListChunk
	mov	bp, es:FIS_curSelection
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

done:
	pop	bx
	call	MemFree
	.leave
	ret
SSFormatRequestMoniker	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSFormatUpdateUI

DESCRIPTION:	See documentation in math.def.

CALLED BY:	EXTERNAL ()

PASS:		ds:di - spreadsheet instance
		cx - mem handle of FormatInfoStruc

RETURN:		FormatInfoStruc freed

DESTROYED:	everything (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

SSFormatUpdateUI	method	dynamic SpreadsheetClass,
				MSG_FLOAT_CTRL_UPDATE_UI
	mov	bx, cx
	push	bx

	call	SSFPrepFormatInfoStruc
	call	FloatFormatInitFormatList

	pop	bx
	call	MemFree
	ret
SSFormatUpdateUI	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSFormatSelected

DESCRIPTION:	See documentation in math.def.

CALLED BY:	EXTERNAL ()

PASS:		ds:di - spreadsheet instance
		cx - mem handle of FormatInfoStruc

RETURN:		FormatInfoStruc freed

DESTROYED:	everything (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

SSFormatSelected	method	dynamic SpreadsheetClass,
			MSG_FLOAT_CTRL_FORMAT_SELECTED
	mov	bx, cx
	push	bx

	call	SSFPrepFormatInfoStruc
	call	FloatFormatProcessFormatSelected

	pop	bx
	call	MemFree
	ret
SSFormatSelected	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSFormatUserDefInvoke

DESCRIPTION:	See documentation in math.def.

CALLED BY:	EXTERNAL ()

PASS:		ds:di - spreadsheet instance
		cx - mem handle of FormatInfoStruc

RETURN:		nothing

DESTROYED:	everything (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	message handler of MSG_FLOAT_CTRL_USER_DEF_INVOKE should not free
	FormatInfoStruc

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

SSFormatUserDefInvoke	method	dynamic SpreadsheetClass,
			MSG_FLOAT_CTRL_USER_DEF_INVOKE
	mov	bx, cx
	push	bx

	call	SSFPrepFormatInfoStruc
	call	FloatFormatGetFormatParamsWithListEntry
	jc	done

	call	FloatFormatInvokeUserDefDB

done:
	pop	bx
	call	MemUnlock
	ret
SSFormatUserDefInvoke	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSFormatUserDefOK

DESCRIPTION:	See documentation in math.def.

CALLED BY:	EXTERNAL ()

PASS:		ds:di - spreadsheet instance
		cx - mem handle of FormatInfoStruc

RETURN:		FormatInfoStruc freed unless an error occurred

DESTROYED:	everything (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

SSFormatUserDefOK	method	dynamic SpreadsheetClass,
			MSG_FLOAT_CTRL_USER_DEF_OK
	mov	bx, cx
	push	bx

	call	SSFPrepFormatInfoStruc	; es:0 <- FormatInfoStruc

	push	ds:[LMBH_handle]
	call	FloatFormatUserDefOK	
	pop	bx
	tst	cx
	jne	exitError

	call	MemDerefDS
	mov	si, di			; ds:si <- spreadsheet
	cmp	es:FIS_editFlag, 0	; defining a new format?
	je	defining		;  yes, don't need redraw
	
	mov	si, ds:[si].SSI_chunk
	mov	ax, MSG_SPREADSHEET_COMPLETE_REDRAW
	call	ObjCallInstanceNoLock
	mov	si, ds:[si]
	add	si, ds:[si].Spreadsheet_offset

defining:
	; 
	; increment formatCount to force FormatChange notification
	;
	push	ds
NOFXIP<	segmov	ds, <segment idata>, ax					>
FXIP<	mov_tr	ax, bx			; save bx value			>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefDS		;ds = dgroup			>
FXIP<	mov_tr	bx, ax			; restore bx value		>
	inc	ds:formatCount
	pop	ds
	
	mov	ax, SNFLAGS_FORMAT_LIST_CHANGE	
	call	SS_SendNotification

	pop	bx
	call	MemFree			; no error => clean up

	ret

	;
	; In the event of an error, don't free the FormatInfoStruc
	;
exitError:
	pop	bx
	call	MemUnlock
	ret
SSFormatUserDefOK	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSFormatDelete

DESCRIPTION:	See documentation in math.def.

CALLED BY:	EXTERNAL ()

PASS:		ds:di - spreadsheet instance
		cx - mem handle of FormatInfoStruc

RETURN:		FormatInfoStruc freed

DESTROYED:	everything (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

SSFormatDelete	method	dynamic SpreadsheetClass,
		MSG_FLOAT_CTRL_FORMAT_DELETE

	mov	bx, cx
	push	bx

	mov	ax, ds:LMBH_handle
	push	ax,si

	call	SSFPrepFormatInfoStruc
	call	FloatFormatGetFormatParamsWithListEntry
	jc	done

	call	FloatFormatDelete		; cx <- deleted format token
	pop	bx,si
	jc	done				; bail if no delete

	;
	; Remove all references to this format by replacing them with
	; the general format
	;
	push	bx,si
	call	MemDerefDS
	mov	si, ds:[si]
	add	si, ds:[si].Spreadsheet_offset

	mov	ax, cx
	mov	dx, FORMAT_ID_FIXED
NOFXIP<	mov	bx, cs							>
FXIP<	mov	bx, vseg ReplaceNumFormat				>
	mov	di, offset ReplaceNumFormat	;bx:di <- callback routine
	call	StyleTokenChangeAttr

	;
	; increment formatCount to force FormatChange notification
	;
NOFXIP<	segmov	ds, <segment idata>, ax					>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefDS			;ds = dgroup		>
	inc	ds:formatCount

	;
	; redraw the spreadsheet, reinit the format list
	;
	pop	bx,si
	call	MemDerefDS
	mov	si, ds:[si]
	add	si, ds:[si].Spreadsheet_offset
	mov	ax, SNFLAGS_FORMAT_LIST_CHANGE	
	call	UpdateUIRedrawAll

done:
	pop	bx
	call	MemFree
	ret
SSFormatDelete	endm



if FULL_EXECUTE_IN_PLACE
AttrCode	segment	resource
endif
COMMENT @-----------------------------------------------------------------------

FUNCTION:	ReplaceNumFormat

DESCRIPTION:	Replace CA_format for a style token array entry

CALLED BY:	INTERNAL (StyleReplaceNumFormat)

PASS:		*ds:si - array
		ds:di - ptr to CellAttrs entry
		ax - format to replace
		dx - format to replace with

RETURN:		carry - set to end enumeration

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

ReplaceNumFormat	proc	far
	.enter

EC <	cmp	ds:[di].CA_refCount.REH_refCount.WAAH_high, EA_FREE_ELEMENT >
EC <	je	done				;skip empty entries >

EC <	push	es				;>
EC <	segmov	es, ds				;>
EC <	call	ECCheckCellAttrRefCount		;>
EC <	pop	es				;>

	cmp	ds:[di].CA_format, ax		;format match?
	jne	done				;branch if mismatch
	mov	ds:[di].CA_format, dx		;replac format
done:
	clc					;carry <- don't abort
	.leave
	ret
ReplaceNumFormat	endp

if FULL_EXECUTE_IN_PLACE
AttrCode	ends
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSFormatApply

DESCRIPTION:	See documentation in math.def.

CALLED BY:	EXTERNAL ()

PASS:		ds:di - spreadsheet instance
		cx - mem handle of FormatInfoStruc

RETURN:		FormatInfoStruc freed

DESTROYED:	everything (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

SSFormatApply	method	dynamic SpreadsheetClass,
		MSG_FLOAT_CTRL_FORMAT_APPLY
	mov	bx, cx
	push	bx

	call	SSFPrepFormatInfoStruc
	call	FloatFormatGetFormatParamsWithListEntry
	jc	done

	;
	; use info in FormatInfoStruc
	;
EC<	call	ECCheckObject >
	mov	di, ds:[si]
	add	di, ds:[di].Spreadsheet_offset
	mov	cx, es:FIS_curToken
	call	SpreadsheetSetNumFormat

done:
	pop	bx
	call	MemFree
	ret
SSFormatApply	endm


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SSFPrepFormatInfoStruc

DESCRIPTION:	Stuff the FIS_userDefFmtArrayFileHan and
		FIS_userDefFmtArrayBlkHan fields.

CALLED BY:	INTERNAL ()

PASS:		bx - handle of FormatInfoStruc
		ds:di - spreadsheet instance

RETURN:		es:0 - FormatInfoStruc
		    with FIS_userDefFmtArrayFileHan
		    and FIS_userDefFmtArrayBlkHan initialized

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/92		Initial version

-------------------------------------------------------------------------------@

SSFPrepFormatInfoStruc	proc	near
	class	SpreadsheetClass
	.enter
	call	MemLock
	mov	es, ax

	mov	ax, ds:[di].SSI_cellParams.CFP_file
	mov	es:FIS_userDefFmtArrayFileHan, ax
	mov	ax, ds:[di].SSI_formatArray
	mov	es:FIS_userDefFmtArrayBlkHan, ax
	.leave
	ret
SSFPrepFormatInfoStruc	endp

SpreadsheetFormatCode	ends
