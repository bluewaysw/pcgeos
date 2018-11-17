COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc/Document
FILE:		documentMouse.asm

AUTHOR:		Gene Anderson, Oct 12, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/12/92		Initial revision


DESCRIPTION:
	Mouse messages for the GeoCalc document

	$Id: documentMouse.asm,v 1.1 97/04/04 15:48:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Document segment resource

if _CHARTS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckGrObjMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a mouse event is destined for the grobj

CALLED BY:	GeoCalcDocumentPtr
PASS:		*ds:si - GeoCalc document object
		ss:bp - ptr to LargeMouseData
RETURN:		z flag - clear (jnz) if destined for grobj
		    ^lcx:dx - new pointer image
		    ax - MouseReturnFlags
		^lbx:si - OD of grobj
DESTROYED:	ax - if not destined for grobj

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckGrObjMouse		proc	near
	uses	di
	.enter

	call	GetGrObjBodyOD			;^lbx:si <- OD of grobj
CheckHack <(offset LMD_location) eq 0>
	mov	ax, MSG_GB_EVALUATE_MOUSE_POSITION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	cmp	al, GOMRF_NOTHING		;set Z flag for not grobj
	mov	al, 0				;ax <- MouseReturnFlags

	.leave
	ret
CheckGrObjMouse		endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle pointer events for GeoCalc document

CALLED BY:	MSG_META_LARGE_PTR
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the message

		ss:bp - ptr to LargeMouseData

RETURN:		ax - MouseReturnFlags
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentPtr		method dynamic GeoCalcDocumentClass,
						MSG_META_LARGE_PTR
	;
	; See if the edit bar has the focus.  If we're doing cell references
	; in the edit bar, just pass the ptr event off so it goes to the
	; spreadsheet.
	;
	call	CheckEditBarFocus
	jc	notPtrTool			;branch if edit bar has focus
	;
	; Get the current tool -- if it isn't the pointer, just pass it on
	;
CHART<	call	IsPtrTool						>
CHART<	jnz	notPtrTool			;branch if not pointer tool >
	;
	; Ask the GrObj if it can deal with the pointer
	;
if _CHARTS
	push	si
	call	CheckGrObjMouse
	pop	si				;*ds:si <- document object
	jnz	isGrObj				;branch if for grobj
endif
	;
	; If not, send to the spreadsheet
	;
	call	GetDocSpreadsheet		;^
	mov	ax, MSG_META_LARGE_PTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
isGrObj::
	ornf	ax, mask MRF_PROCESSED		;ax <- MouseReturnFlags
	ret

notPtrTool:
	mov	di, offset GeoCalcDocumentClass
	GOTO	ObjCallSuperNoLock
GeoCalcDocumentPtr		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle start select events for GeoCalc document

CALLED BY:	MSG_META_LARGE_START_SELECT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the message

		ss:bp - ptr to LargeMouseData

RETURN:		ax - MouseReturnFlags
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentStartSelect	method dynamic GeoCalcDocumentClass,
						MSG_META_LARGE_START_SELECT
	mov	di, si				;*ds:di <- document object
	;
	; See if the edit bar has the focus.  If we're doing cell references
	; in the edit bar, just pass the ptr event off so it goes to the
	; spreadsheet.
	;
	call	CheckEditBarFocus
	jc	notPtrTool			;branch if edit bar has focus
	;
	; Get the current tool -- if it isn't the pointer, just pass it on
	;
if _CHARTS
	call	IsPtrTool
	jnz	notPtrTool			;branch if not pointer tool
	;
	; Ask the GrObj if it can deal with the pointer
	;
	call	CheckGrObjMouse
	mov	cl, GCTL_GROBJ
	jnz	changeTarget			;branch if for grobj
endif
	;
	; If not, send to the spreadsheet
	;
	mov	si, di				;*ds:si <- document object
	call	GetDocSpreadsheet		;^lbx:si <- OD of spreadsheet
	mov	cl, GCTL_SPREADSHEET
	;
	; Tell either the spreadsheet or the grobj to grab the focus and
	; target...
	;
changeTarget::
	call	SetTargetLayerOpt
	;
	; ...and then pass it the start select.
	;
	mov	ax, MSG_META_LARGE_START_SELECT
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	ret

notPtrTool:
	mov	di, offset GeoCalcDocumentClass
	GOTO	ObjCallSuperNoLock
GeoCalcDocumentStartSelect		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTargetLayer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the target layer

CALLED BY:	GeoCalcDocumentStartSelect()
PASS:		^lbx:si - OD of grobj or spreadsheet
		cl - GeoCalcTargetLayer
		ds - fixupable segment owned by GeoCalc
		carry - clear to check if target layer changing
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTargetLayerOpt	proc	near
	clc					;carry <- optimization OK
	FALL_THRU	SetTargetLayer
SetTargetLayerOpt	endp
SetTargetLayer		proc	near
	uses	ax, bx, cx, dx, bp, di, si
	.enter

	;
	; See if we're allowed to optimize and check our current
	; notion of the target.
	;
	jc	doChange			;branch if no optimization
	;
	; See if the layer has actually changed -- if not, quit
	;
	push	cx
	mov	ax, MSG_GEOCALC_APPLICATION_GET_TARGET_LAYER
	call	UserCallApplication
	mov	dl, cl				;dl <- current layer
	pop	cx
	cmp	cl, dl				;layer changed?
	je	quit				;branch if not changed
	;
	; Notify the app obj of the target change
	;
doChange:
	push	cx
	mov	ax, MSG_GEOCALC_APPLICATION_SET_TARGET_LAYER
	call	UserCallApplication
	pop	cx
if _CHARTS
	;
	; If the new layer is the spreadsheet layer, unselect all grobjs
	;
	cmp	cl, GCTL_SPREADSHEET
	jne	noDeselect
	push	bx, si				; save spreadsheet obj
	mov	ax, MSG_VIS_FIND_PARENT
	call	callObjMessage			; ^lcx:dx = document obj
	jcxz	oops
	movdw	bxsi, cxdx			; ^lbx:si = document obj
	mov	cx, 1				; first child is grobj body
	mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
	call	callObjMessage			; ^lcx:dx = grobj body
	jcxz	oops
	movdw	bxsi, cxdx
	mov	ax, MSG_GB_REMOVE_ALL_GROBJS_FROM_SELECTION_LIST
	call	callObjMessage
oops:
	pop	bx, si				; restore ss obj
noDeselect:
endif
	;
	; Set the focus and target to the specified OD
	;
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	callObjMessage
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	callObjMessage
quit:
	.leave
	ret

callObjMessage:
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	retn
SetTargetLayer		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentSetTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the target layer

CALLED BY:	MSG_GEOCALC_DOCUMENT_SET_TARGET
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the message

		cl - GeoCalcTargetLayer

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentSetTarget		method dynamic GeoCalcDocumentClass,
						MSG_GEOCALC_DOCUMENT_SET_TARGET
	cmp	cl, GCTL_SPREADSHEET
	je	isSpreadsheet

if _CHARTS
	call	GetGrObjBodyOD			;^lbx:si <- OD of GrObj
	jmp	setLayer
else

EC<	ERROR	-1							>
endif

isSpreadsheet:
	call	GetDocSpreadsheet		;^lbx:si <- OD of spreadsheet
setLayer::
	call	SetTargetLayerOpt
	ret
GeoCalcDocumentSetTarget		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentGainedFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle gaining the focus

CALLED BY:	MSG_META_GAINED_FOCUS_EXCL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentGainedFocus		method dynamic GeoCalcDocumentClass,
						MSG_META_GAINED_FOCUS_EXCL
	ornf	ds:[di].GCDI_flags, mask GCDF_IS_FOCUS
	mov	di, offset GeoCalcDocumentClass
	GOTO	ObjCallSuperNoLock
GeoCalcDocumentGainedFocus		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentLostFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle losing the focus

CALLED BY:	MSG_META_LOST_FOCUS_EXCL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentLostFocus		method dynamic GeoCalcDocumentClass,
						MSG_META_LOST_FOCUS_EXCL
	andnf	ds:[di].GCDI_flags, not (mask GCDF_IS_FOCUS)
	mov	di, offset GeoCalcDocumentClass
	GOTO	ObjCallSuperNoLock
GeoCalcDocumentLostFocus		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckEditBarFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the edit bar has the focus

CALLED BY:	UTILITY
PASS:		*ds:si - geocalc document object
RETURN:		carry - clear if edit bar doesn't have focus
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckEditBarFocus		proc	near
	uses	si
	class	GeoCalcDocumentClass
	.enter

EC <	call	ECGeoCalcDocument		;>
	;
	; Do the quick check to see if we have the focus
	; (ie. that the edit bar doesn't).  This is the common case.
	;
	mov	si, ds:[si]
	add	si, ds:[si].GeoCalcDocument_offset
	test	ds:[si].GCDI_flags, mask GCDF_IS_FOCUS
	jnz	noEditBarFocus			;branch (carry clear)
	;
	; We don't have the focus -- see if the edit bar does
	;
	push	ax, cx, di
	mov	ax, MSG_SSEBC_GET_FLAGS
	GetResourceHandleNS GCEditBarControl, bx
	mov	si, offset GCEditBarControl	;^lbx:si <- OD of display ctrl
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	test	cl, mask SSEBCF_IS_FOCUS	;is edit bar focus?
	pop	ax, cx, di
	jz	noEditBarFocus			;exit if not
	stc					;carry <- edit bar has focus
noEditBarFocus:

	.leave
	ret
CheckEditBarFocus		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get flags for a GeoCalc document

CALLED BY:	MSG_GEOCALC_DOCUMENT_GET_FLAGS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the message

RETURN:		cl - GeoCalcDocumentFlags
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentGetFlags		method dynamic GeoCalcDocumentClass,
						MSG_GEOCALC_DOCUMENT_GET_FLAGS
	mov	cl, ds:[di].GCDI_flags		;cl <- GeoCalcDocumentFlags
	ret
GeoCalcDocumentGetFlags		endm

Document ends
