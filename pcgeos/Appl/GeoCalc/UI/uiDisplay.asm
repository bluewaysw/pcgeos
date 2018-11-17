COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		uiDisplay.asm

AUTHOR:		Gene Anderson, Mar  5, 1991

ROUTINES:
	Name				Description
	----				-----------
	MSG_DISPLAY_ATTACH_UI		Attach UI within display

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/ 5/91		Initial revision

DESCRIPTION:
	Routines to implement GeoCalcDisplayClass.

	$Id: uiDisplay.asm,v 1.1 97/04/04 15:48:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcClassStructures	segment	resource
	GeoCalcDisplayClass		;declare the class record
GeoCalcClassStructures	ends

DisplayCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDisplayAttachUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the document OD and info
CALLED BY:	MSG_DISPLAY_ATTACH_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDisplayClass
		ax - the method
		cx - handle of spreadsheet block
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDisplayAttachUI	method dynamic GeoCalcDisplayClass, \
						MSG_DISPLAY_ATTACH_UI
	;
	; connect the row & column contents and their views.
	; Stuff is arranged here left to right, top to bottom
	;
if _SPLIT_VIEWS
	mov	dx, offset LeftColumnContent
	mov	si, offset LeftColumnView
	call	callSetContent
endif

	mov	dx, offset RightColumnContent
	mov	si, offset RightColumnView
	call	callSetContent

if _SPLIT_VIEWS
	mov	dx, offset MidRowContent
	mov	si, offset MidRowView
	call	callSetContent

	mov	dx, offset MidLeftContent
	mov	si, offset MidLeftView
	call	callSetContent

	mov	dx, offset MidRightContent
	mov	si, offset MidRightView
	call	callSetContent
endif
	mov	dx, offset BottomRowContent
	mov	si, offset BottomRowView
	call	callSetContent

if _SPLIT_VIEWS
	mov	dx, offset BottomLeftContent
	mov	si, offset BottomLeftView
	call	callSetContent

endif
	ret


callSetContent:
	push	cx
	mov	ax, MSG_GEN_VIEW_SET_CONTENT
	call	ObjCallInstanceNoLock
	pop	cx
	retn
GeoCalcDisplayAttachUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDisplayUpdateRulers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update rulers
CALLED BY:	MSG_GEOCALC_DISPLAY_UPDATE_RULERS

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDisplayClass
		ax - the message

		cx - RulerShowControlAttributes
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDisplayUpdateRulers	method dynamic GeoCalcDisplayClass, \
					MSG_GEOCALC_DISPLAY_UPDATE_RULERS
	mov	ax, mask RSCA_SHOW_VERTICAL
	mov	si, offset MidRowView
	call	UpdateRuler

	mov	ax, mask RSCA_SHOW_VERTICAL
	mov	si, offset BottomRowView
	call	UpdateRuler

	mov	ax, mask RSCA_SHOW_HORIZONTAL
	mov	si, offset TopViewGroup
	call	UpdateRuler

	ret
GeoCalcDisplayUpdateRulers	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateRuler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update usable/not usable status of rulers
CALLED BY:	GeoCalcDisplayUpdateRulers()

PASS:		*ds:si - GeoCalcDisplay object
		ax - bits to check (RulerShowControlAttributes)
		cx - RulerShowControlAttributes from controller
RETURN:		none
DESTROYED:	ax, bx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateRuler	proc	near
	uses cx
	.enter

	mov	bx, ax				;bx <- bits to check
	andnf	bx, cx
	cmp	ax, bx				;right bits set to enable?
	mov	ax, MSG_GEN_SET_USABLE
	jz	20$
	mov	ax, MSG_GEN_SET_NOT_USABLE
20$:
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	.leave
	ret

UpdateRuler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDisplayBuildBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
CALLED BY:	MSG_SPEC_BUILD_BRANCH

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDisplayClass
		ax - the message

		bp - SpecBuildFlags

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/22/92		copied from GeoWrite

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDisplayBuildBranch	method dynamic GeoCalcDisplayClass, \
						MSG_SPEC_BUILD_BRANCH,
						MSG_VIS_OPEN
	;
	; add ourself to the display GCN list now so that we can immediately
	; set our rulers not usable if needed
	;
	mov	di, MSG_META_GCN_LIST_ADD
	call	GCNCommon

	mov	di, offset GeoCalcDisplayClass
	GOTO	ObjCallSuperNoLock
GeoCalcDisplayBuildBranch	endm

;---

GeoCalcDisplayUnbuildBranch	method dynamic	GeoCalcDisplayClass,
						MSG_SPEC_UNBUILD_BRANCH,
						MSG_VIS_CLOSE

	mov	di, offset GeoCalcDisplayClass
	call	ObjCallSuperNoLock
	;
	; remove ourself to the display GCN list we added ourselves to before
	;
	mov	di, MSG_META_GCN_LIST_REMOVE
	call	GCNCommon
	ret
GeoCalcDisplayUnbuildBranch	endm

;---

GCNCommon	proc	near
	push	ax, si, bp
	sub	sp, size GCNListParams		; create stack frame
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type,
				GAGCNLT_DISPLAY_OBJECTS_WITH_RULERS
	mov	bx, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, bx
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	dx, size GCNListParams		; create stack frame
	clr	bx
	call	GeodeGetAppObject
	mov_tr	ax, di
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GCNListParams		; fix stack
	pop	ax, si, bp

	ret
GCNCommon	endp

DisplayCode ends
