COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentContent.asm

ROUTINES:
	Name			Description
	----			-----------
    INT CreateGStateCommon	Create a gstate

    INT IsTextTool		See whether the current tool from the GrObj
				is the text tool

    INT SetPositionCommon	Set the position of the document

    INT MessageToRuler		Send a message to the ruler

    INT SetStudioToolIfNotPageMode 
				If not in page mode then set the Studio
				tool

    INT SetStudioTool		If not in page mode then set the Studio
				tool

    INT SendDocumentNotifyIfModel 
				Send the NF_DOCUMENT notification if the
				document has the model exclusive

    INT MessageToMPRuler	Send a message to the ruler

METHODS:
	Name			Description
	----			-----------
    StudioDocumentFindObjectOfClass  
				Vups until finding an appropriate recipient
				of a classed event.

				MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
				StudioDocumentClass

    StudioDocumentVupCreateGState  
				Create a gstate

				MSG_VIS_VUP_CREATE_GSTATE
				StudioDocumentClass

    StudioMasterPageContentVupCreateGState  
				Create a gstate

				MSG_VIS_VUP_CREATE_GSTATE
				StudioMasterPageContentClass

    StudioDocumentLargeStartSelect  
				Pass messages off to the appropriate layer

				MSG_META_LARGE_START_SELECT,
				MSG_META_LARGE_START_MOVE_COPY
				StudioDocumentClass

    StudioDocumentViewOriginChanged  
				Handle the origin changing

				MSG_META_CONTENT_VIEW_ORIGIN_CHANGED
				StudioDocumentClass

    StudioDocumentSetPositionAbs  
				Set the position of the document given an
				absolute page position

				MSG_STUDIO_DOCUMENT_SET_POSITION_ABS
				StudioDocumentClass

    StudioDocumentSetPosition	Set the position of the document

				MSG_STUDIO_DOCUMENT_SET_POSITION
				StudioDocumentClass

    StudioDocumentSendClassedEvent  
				Pass a classed event to the right place

				MSG_META_SEND_CLASSED_EVENT
				StudioDocumentClass

    StudioDocumentSetTargetBasedOnTool  
				Set the target based on the (new) current
				tool

				MSG_STUDIO_DOCUMENT_SET_TARGET_BASED_ON_TOOL
				StudioDocumentClass

    StudioDocumentInvalidate	Handle invalidating a document by also
				invalidating all the master pages

				MSG_VIS_INVALIDATE
				StudioDocumentClass

    StudioDocumentGainedTargetExcl  
				Handle gaining the target

				MSG_META_GAINED_TARGET_EXCL
				StudioDocumentClass

    StudioDocumentLostTargetExcl  
				Handle losing the target

				MSG_META_LOST_TARGET_EXCL
				StudioDocumentClass

    StudioDocumentGainedModelExcl  
				Handle gaining the model exclusive

				MSG_META_GAINED_MODEL_EXCL
				StudioDocumentClass

    StudioDocumentLostModelExcl	Handle losing the target

				MSG_META_LOST_MODEL_EXCL
				StudioDocumentClass

    StudioMasterPageContentSetDocumentAndMP  
				Set the document that is associated with
				this master page

				MSG_STUDIO_MASTER_PAGE_CONTENT_SET_DOCUMENT_AND_MP
				StudioMasterPageContentClass

    StudioMasterPageContentGainedTargetExcl  
				Tell the document that we are the target

				MSG_META_GAINED_TARGET_EXCL
				StudioMasterPageContentClass

    StudioMasterPageContentLostTargetExcl  
				Handle losing the target

				MSG_META_LOST_TARGET_EXCL
				StudioMasterPageContentClass

    StudioMasterPageContentDraw	Draw the master page

				MSG_VIS_DRAW
				StudioMasterPageContentClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the VisContent related code for StudioDocumentClass

	$Id: documentContent.asm,v 1.1 97/04/04 14:39:19 newdeal Exp $

------------------------------------------------------------------------------@

idata segment
	StudioMasterPageContentClass

idata ends

;---

DocCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentVupCreateGState -- MSG_VIS_VUP_CREATE_GSTATE
						for StudioDocumentClass

DESCRIPTION:	Create a gstate

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

RETURN:
	carry - set
	bp - gstate

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/24/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentVupCreateGState	method dynamic	StudioDocumentClass,
						MSG_VIS_VUP_CREATE_GSTATE

	mov	di, offset StudioDocumentClass

	FALL_THRU	CreateGStateCommon

StudioDocumentVupCreateGState	endm

;---

CreateGStateCommon	proc	far
	call	ObjCallSuperNoLock

	; we always want to dither colors

	mov	di, bp
	mov	al, ColorMapMode <0, CMT_DITHER>
	call	GrSetAreaColorMap
	call	GrSetLineColorMap
	call	GrSetTextColorMap

	;we want to show control characters sometimes

	test	es:[miscSettings], mask SMS_SHOW_INVISIBLES
	jz	afterInvisibles
	mov	ax, mask TM_DRAW_CONTROL_CHARS
	call	GrSetTextMode
afterInvisibles:

	stc
	ret

CreateGStateCommon	endp

;---

StudioMasterPageContentVupCreateGState	method dynamic	\
						StudioMasterPageContentClass,
						MSG_VIS_VUP_CREATE_GSTATE

	mov	di, offset StudioMasterPageContentClass
	GOTO	CreateGStateCommon

StudioMasterPageContentVupCreateGState	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentLargeStartSelect -- MSG_META_LARGE_START_SELECT
						for StudioDocumentClass

DESCRIPTION:	Pass messages off to the appropriate layer

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	dx - size LargeMouseData
	ss:bp - LargeMouseData

RETURN:
	ax - MouseReturnFlags

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/18/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentLargeStartSelect	method dynamic	StudioDocumentClass,
						MSG_META_LARGE_START_SELECT,
						MSG_META_LARGE_START_MOVE_COPY

	; if there are no children or if there is an active mouse grab then
	; let our superclass handle it

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	movdw	cxdx, ds:[di].VCI_comp.CP_firstChild
	tst	cx
	jnz	10$
	mov	di, offset StudioDocumentClass
	GOTO	ObjCallSuperNoLock
10$:

	; If the current tool is:
	; * geowrite text tool
	;	start at first object
	; * other
	;	send to grobj

	call	IsTextTool
	jnc	sendToGrObj
	jz	sendToGrObj

	; this is Studio's text tool -- we want to send to each child
	; until one claims it

	clr	bx				;bx = child number
	or	ds:[di].SDI_state, mask SDS_REPLAY
	mov_tr	di, ax				;di = message

childLoop:
	push	bx, di, bp
	clr	cx
	mov	dx, bx
	mov	ax, offset VI_link
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp
	call	ObjCompFindChild		;cx:dx = optr
	pop	bx, di, bp
	jc	notFound

	; cx:dx = object, send the sucker

	push	bx, si, di, bp
	movdw	bxsi, cxdx
	mov	dx, size LargeMouseData
	mov_tr	ax, di
	mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	call	DC_ObjMessage
	pop	bx, si, di, bp
	test	ax, mask MRF_REPLAY
	jz	done

	inc	bx			;move to next child
	jmp	childLoop

notFound:
	mov	ax, mask MRF_PROCESSED
done:
	ret

sendToGrObj:
	push	ax, bp
	clr	cx
	mov	dx, CCO_LAST
	mov	ax, offset VI_link
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp
	call	ObjCompFindChild	;bp = count
	clr	cx
	mov	dx, bp
	dec	dx
	call	ObjCompFindChild	;cxdx = grobj body
	pop	ax, bp

	push	ax, si, bp
	movdw	bxsi, cxdx
	mov	dx, size LargeMouseData
	mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	call	DC_ObjMessage
	pop	di, si, bp

	cmp	di, MSG_META_LARGE_START_SELECT
	jnz	done

	push	ax, cx, dx
	mov	cx, ss:[bp].LMD_location.PDF_x.DWF_int.low
	mov	dx, ss:[bp].LMD_location.PDF_y.DWF_int.high
	mov	bp, ss:[bp].LMD_location.PDF_y.DWF_int.low
	mov	ax, MSG_STUDIO_DOCUMENT_SET_POSITION
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx
	jmp	done

StudioDocumentLargeStartSelect	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	IsTextTool

DESCRIPTION:	See whether the current tool is the Studio text tool

CALLED BY:	INTERNAL

PASS:	nothing

RETURN:
	carry - set if text tool
	(zero - set if grobj's text tool - not used in Condo)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/31/92		Initial version

------------------------------------------------------------------------------@
IsTextTool	proc	far	uses ax, bx, cx, dx, si, di, bp
	.enter

	GetResourceHandleNS StudioHead, bx
	mov	si, offset StudioHead
	mov	ax, MSG_GH_GET_CURRENT_TOOL
	mov	di, mask MF_CALL
	call	DC_ObjMessage			;cx:dx = tool

if 0
	cmp	cx, segment MultTextGuardianClass
	jnz	10$
	cmp	dx, offset MultTextGuardianClass
	jz	doneGood
10$:
endif
	cmp	cx, segment EditTextGuardianClass
	clc
	jnz	done
	cmp	dx, offset EditTextGuardianClass
	clc
	jnz	done
	cmp	dx, offset MultTextGuardianClass	;will be NZ
;;doneGood:
	stc

done:
	.leave
	ret

IsTextTool	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentViewOriginChanged --
		MSG_META_CONTENT_VIEW_ORIGIN_CHANGED for StudioDocumentClass

DESCRIPTION:	Handle the origin changing

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	ss:bp - OriginChangedParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/17/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentViewOriginChanged	method dynamic	StudioDocumentClass,
					MSG_META_CONTENT_VIEW_ORIGIN_CHANGED

	push	bp
	mov	di, offset StudioDocumentClass
	call	ObjCallSuperNoLock
	pop	bp

	call	LockMapBlockES
	mov	bx, bp

	; We can get into trouble when we try to reset the page number
	; based on an intermediate state of the content.  We can get around
	; this by bailing out unless the content's VCNI_docOrigin is the
	; same as the view's GVI_origin

	sub	sp, size PointDWord
	movdw	cxdx, sssp
	mov	ax, MSG_GEN_VIEW_GET_ORIGIN
	call	VisCallParent			;call the view
	mov	bp, sp				; ss:bp = PointDWord origin
	cmpdw	ss:[bx].OCP_origin.PD_x, ss:[bp].PD_x, ax
	jnz	10$
	cmpdw	ss:[bx].OCP_origin.PD_y, ss:[bp].PD_y, ax
10$:
	lahf
	add	sp, size PointDWord
	sahf
	jnz	done


	; If the user has scrolled to a different page we want to change the
	; page number.  If any part of the window is in the same page, however,
	; we don't want to change the page number
	;
	; 3/29/94: if either the top or the bottom falls in no section, we base
	; our decision on the page number of the other part, rather than
	; assuming there's no page change.

	; Is the top of the window on the same page ?

	call	loadOrigin
	call	isSamePage			; cmp topPage, oldPage
	jc	checkBottom
	jz	done

checkBottom:
	; when we get here, the page for the top is not the same as the page
	; we had before.
	
	call	loadOrigin
	tst	ax				; 3/29/94: if view height is
	jz	notInRange			;  currently 0 and top doesn't
						;  match old page, then switch
						;  (easier than doing double-
						;  precision decrement & add to
						;  get a coord < current origin)
						;  	-- ardeb

	dec	ax				;check bottom-1 (fixes a bug
						;in scale to fit mode)
	add	bp, ax
	adc	dx, 0
	call	isSamePage			; cmp bottomPage, newPage
	jc	notInRange			; top wasn't the same, and
						;  bottom falls beyond the pale,
						;  so change page #
	je	done				; => bottom is same as before,
						;  so don't change page #

	; Find the page for the middle of the window and make it the current
	; page

notInRange:
	call	loadOrigin
	shr	ax
	add	bp, ax
	adc	dx, 0

	mov	ax, MSG_STUDIO_DOCUMENT_SET_POSITION
	call	ObjCallInstanceNoLock
done:
	call	VMUnlockES
	ret

;---

loadOrigin:
	mov	cx, ss:[bx].OCP_origin.PD_x.low
	movdw	dxbp, ss:[bx].OCP_origin.PD_y
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di].VCNI_viewHeight
	retn

;---

	; cx = x pos, dx:bp = y pos

isSamePage:
	call	FindPageAndSection		;cx = section, dx = abs page #
	jc	returnEqual

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	cx, ds:[di].SDI_currentSection
	jnz	compareDone
	cmp	dx, ds:[di].SDI_currentPage
compareDone:
	retn
returnEqual:
	cmp	ax, ax
	retn

StudioDocumentViewOriginChanged	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentSetPositionAbs --
		MSG_STUDIO_DOCUMENT_SET_POSITION_ABS for StudioDocumentClass

DESCRIPTION:	Set the position of the document given an absolute page
		position

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	cx - x position
	dx.bp - y position

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/31/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentSetPositionAbs	method dynamic StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_SET_POSITION_ABS

	; calculate page number and store it

	call	LockMapBlockES

	call	FindPageAndSectionAbs

	GOTO	SetPositionCommon

StudioDocumentSetPositionAbs	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentSetPosition -- MSG_STUDIO_DOCUMENT_SET_POSITION
						for StudioDocumentClass

DESCRIPTION:	Set the position of the document

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	cx - x position
	dx.bp - y position

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/31/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentSetPosition	method dynamic StudioDocumentClass,
						MSG_STUDIO_DOCUMENT_SET_POSITION


	; calculate page number and store it

	call	LockMapBlockES

	call	FindPageAndSection
EC <	ERROR_C	FIND_PAGE_RETURNED_ERROR				>

	FALL_THRU	SetPositionCommon

StudioDocumentSetPosition	endm

;---

SetPositionCommon	proc	far
	class	StudioDocumentClass

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	clr	ax
	cmp	cx, ds:[di].SDI_currentSection
	jz	10$
	mov	ax, mask NF_SECTION
10$:
	cmp	dx, ds:[di].SDI_currentPage
	jz	20$
	ornf	ax, mask NF_PAGE
if 0
	push	ax, si, di, es
	mov	ax, MSG_STUDIO_ARTICLE_PAGE_CHANGED
	call	GetFirstArticle
	clr	di
	call	ObjMessage
	pop	ax, si, di, es
endif		
20$:
	tst	ax
	jz	done
	mov	ds:[di].SDI_currentSection, cx
	mov	ds:[di].SDI_currentPage, dx

	call	SendNotification

done:

	call	VMUnlockES
	ret

SetPositionCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentFindObjectOfClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find and return an object of the passed class.

CALLED BY:	MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of StudioDocumentClassClass
		ax - the message
		cx:dx	- class of object we're looking for

RETURN:		^lcx:dx	- object, if found, else returns null
		carry	- set if found, clear if no object of class found.

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentFindObjectOfClass		method dynamic StudioDocumentClass,
					MSG_VIS_VUP_FIND_OBJECT_OF_CLASS

		movdw	bxdi, cxdx
		mov	ax, segment HotSpotManagerClass
		mov	bp, offset HotSpotManagerClass
		call	StudioCheckClass
		jnc	notManager

	; this message is destined for the body -- find it

		call	StudioGetBody	; cx:dx = grobj body
		jmp	foundIt
		
notManager:
		mov	ax, segment HotSpotTextClass
		mov	bp, offset HotSpotTextClass
		call	StudioCheckClass
		jnc	callSuper

		call	GetFirstArticle
		movdw	cxdx, bxsi
foundIt:		
		stc
		ret
callSuper:
		mov	ax, MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
		call	ObjCallSuperNoLock
		ret

StudioDocumentFindObjectOfClass		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioCheckClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if one class is the descendant of another

CALLED BY:	
PASS:		ax:bp - class to check
		bx:di - class to check against	
RETURN:		carry - set if bx:di is a subclass of ax:bp
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioCheckClass		proc	near
		uses	si, ds, es
		.enter

		movdw	dssi, axbp
		mov	es, bx
		call	ObjIsClassADescendant
	
		.leave
		ret
StudioCheckClass		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioGetBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the optr of the GrObjBody

CALLED BY:	
PASS:		nothing
RETURN:		bp - if 0, no grobj body
		   - else cx:dx - grobj body
DESTROYED:	ax,bx,bp,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioGetBody		proc	near
	class	VisCompClass		
		
	clr	cx
	mov	dx, CCO_LAST
	mov	ax, offset VI_link
	mov	bx, offset Vis_offset
	mov	di, offset VCI_comp
	call	ObjCompFindChild	;bp = count
	tst	bp
	jz	done
		
	clr	cx
	mov	dx, bp
	dec	dx
	call	ObjCompFindChild	;cxdx = grobj body
			
done:
	ret
StudioGetBody		endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentSendClassedEvent -- MSG_META_SEND_CLASSED_EVENT
							for StudioDocumentClass

DESCRIPTION:	Pass a classed event to the right place

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	cx - event
	dx - travel option

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 8/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentSendClassedEvent	method dynamic	StudioDocumentClass,
					MSG_META_SEND_CLASSED_EVENT

	push	cx, si
	mov	bx, cx
	call	ObjGetMessageInfo		;cxsi = class, ax = message
	movdw	bxdi, cxsi			;bxdi = class
	pop	cx, si

	; if there is no class then pass to the superclass

	tst	bx
	LONG jz	toSuper

	mov	ax, segment GrObjHeadClass
	mov	bp, offset GrObjHeadClass
	call	StudioCheckClass
	jnc	notHead

	; this message is destined for the GrObjHead

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	GetResourceHandleNS	StudioHead, bx
	mov	si, offset StudioHead
	call	DC_ObjMessageNoFlags
	ret
notHead:

	; check for the ruler

	mov	ax, segment VisRulerClass
	mov	bp, offset VisRulerClass
	call	StudioCheckClass
	jnc	notRuler

	; this message is destined for the ruler

	call	LockMapBlockES
	mov	ax, es:MBH_grobjBlock
	call	StudioVMBlockToMemBlock			;ax = handle
	call	VMUnlockES

	mov_tr	bx,ax
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	si, offset MainHorizontalRuler
	call	DC_ObjMessageNoFlags
	ret
notRuler:

	; check for the attribute manager

	mov	ax, segment GrObjAttributeManagerClass
	mov	bp, offset GrObjAttributeManagerClass
	call	StudioCheckClass
	jnc	notAttrMgr

	; this message is destined for the attribute manager

	call	LockMapBlockES
	mov	ax, es:MBH_grobjBlock
	call	StudioVMBlockToMemBlock			;ax = handle
	call	VMUnlockES

	mov_tr	bx,ax
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	si, offset AttributeManager
	call	DC_ObjMessageNoFlags
	ret
notAttrMgr:

	; check for grobj class. let the body handle 'em if so
	;

	mov	ax, segment GrObjClass
	mov	bp, offset GrObjClass
	call	StudioCheckClass
	jc	toBody

	; check for the body

	mov	ax, segment GrObjBodyClass
	mov	bp, offset GrObjBodyClass
	call	StudioCheckClass
	jnc	notBody

	; this message is destined for the body -- find it

toBody:
	push	cx, dx
	call	StudioGetBody				; cx:dx <- grobj body
	movdw	bxsi, cxdx
	pop	cx, dx
	tst	bp
	jz	noBody
		
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	call	DC_ObjMessageNoFlags
noBody:
	ret
notBody:

	; check for an article

	GetResourceSegmentNS	StudioArticleClass, es
	mov	ax, es
	mov	bp, offset StudioArticleClass
	call	StudioCheckClass
	jnc	notArticle

	; this message is destined for an article

	call	LockMapBlockES
	mov	di, cx
	call	SendToFirstArticle
	call	VMUnlockES
	ret
notArticle:

toSuper:
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	di, offset StudioDocumentClass
	GOTO	ObjCallSuperNoLock

StudioDocumentSendClassedEvent	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentSetTargetBasedOnTool --
		MSG_STUDIO_DOCUMENT_SET_TARGET_BASED_ON_TOOL
						for StudioDocumentClass

DESCRIPTION:	Set the target based on the (new) current tool

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 8/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentSetTargetBasedOnTool	method dynamic	StudioDocumentClass,
				MSG_STUDIO_DOCUMENT_SET_TARGET_BASED_ON_TOOL

	; If the current tool is:
	; * geowrite text tool
	;	don't change target (unless there is no target)
	; * other
	;	target = grobj

	clr	cx				;assume text is target,
						; use the first child
	call	IsTextTool
	jc	common				;is text tool
	;
	; The tool is not the text tool, so the target will be the
	; grobj body, which is the last of the document's children.
	;
	mov	ax, MSG_VIS_COUNT_CHILDREN
	call	ObjCallInstanceNoLock		;dx = count
	mov	cx, dx
	dec	cx

common:
	mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock		;cx:dx = child
	movdw	bxsi, cxdx
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	DC_ObjMessageNoFlags
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	DC_ObjMessageNoFlags
	ret

StudioDocumentSetTargetBasedOnTool	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	MessageToRuler

DESCRIPTION:	Send a message to the ruler

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	ax, cx, dx, bp - message data

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/20/92		Initial version

------------------------------------------------------------------------------@
MessageToRuler	proc	far	uses si, di
	.enter

	push	ax, es
	call	LockMapBlockES
	mov	ax, es:MBH_grobjBlock
	call	StudioVMBlockToMemBlock			;ax = handle
	call	VMUnlockES
	mov_tr	bx, ax
	pop	ax, es

	mov	si, offset MainHorizontalRuler
	mov	di, mask MF_FIXUP_DS
	call	DC_ObjMessage

	.leave
	ret

MessageToRuler	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentInvalidate -- MSG_VIS_INVALIDATE
						for StudioDocumentClass

DESCRIPTION:	Handle invalidating a document by also invalidating all
		the master pages

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/29/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentInvalidate	method dynamic	StudioDocumentClass, MSG_VIS_INVALIDATE

	; invalidate ourself

	push	ax
	mov	di, offset StudioDocumentClass
	call	ObjCallSuperNoLock
	pop	ax

	; invalidate all master pages

	mov	di, ds:[OpenMasterPageArray]
	mov	cx, ds:[di].CAH_count
	jcxz	noMasterPages
	add	di, ds:[di].CAH_offset
invalidateMPLoop:
	mov	bx, ds:[di].OMP_content
	mov	si, offset MasterPageContent
	call	DC_ObjMessageNoFlags
	add	di, size OpenMasterPage
	loop	invalidateMPLoop
noMasterPages:

	ret

StudioDocumentInvalidate	endm

DocCommon ends

DocNotify segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentGainedTargetExcl -- MSG_META_GAINED_TARGET_EXCL
						for StudioDocumentClass

DESCRIPTION:	Handle gaining the target

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/31/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentGainedTargetExcl	method dynamic	StudioDocumentClass,
						MSG_META_GAINED_TARGET_EXCL

	ornf	ds:[di].SDI_state, mask SDS_TARGET

	mov	di, offset StudioDocumentClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_VIS_RULER_GAINED_SELECTION
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	MessageToRuler

	; if we have the model exclusive then update stuff (in case we are
	; switching between the document and the master page)

	call	SendDocumentNotifyIfModel

	call	SetStudioToolIfNotPageMode

	ret

StudioDocumentGainedTargetExcl	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetStudioToolIfNotPageMode

DESCRIPTION:	If not in page mode then set the Studio tool

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/23/92		Initial version

------------------------------------------------------------------------------@
SetStudioToolIfNotPageMode	proc	far	uses es
	.enter

	call	LockMapBlockES
	cmp	es:MBH_displayMode, VLTDM_PAGE
	jz	done
	call	SetStudioTool
done:
	call	VMUnlockES

	.leave
	ret

SetStudioToolIfNotPageMode	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetStudioTool

DESCRIPTION:	If not in page mode then set the Studio tool

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/23/92		Initial version

------------------------------------------------------------------------------@
SetStudioTool	proc	far	uses ax, bx, cx, dx, si, bp
	.enter

	GetResourceHandleNS	StudioHead, bx
	mov	si, offset StudioHead
	mov	ax, MSG_GH_SET_CURRENT_TOOL
	mov	cx, segment EditTextGuardianClass
	mov	dx, offset EditTextGuardianClass
	clr	bp
	call	DN_ObjMessageNoFlags

	.leave
	ret

SetStudioTool	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendDocumentNotifyIfModel

DESCRIPTION:	Send the NF_DOCUMENT notification if the document has the
		model exclusive

CALLED BY:	INTERNAL

PASS:
	*ds:si - document

RETURN:
	none

DESTROYED:
	ax, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/23/92		Initial version

------------------------------------------------------------------------------@
SendDocumentNotifyIfModel	proc	near
	class	StudioDocumentClass
EC <	call	AssertIsStudioDocument					>

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].SDI_state, mask SDS_MODEL
	jz	done
	mov	ax, mask NF_DOCUMENT
	call	LockAndSendNotification
done:
	ret

SendDocumentNotifyIfModel	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentLostTargetExcl -- MSG_META_LOST_TARGET_EXCL
						for StudioDocumentClass

DESCRIPTION:	Handle losing the target

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/31/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentLostTargetExcl	method dynamic	StudioDocumentClass,
						MSG_META_LOST_TARGET_EXCL

	andnf	ds:[di].SDI_state, not mask SDS_TARGET

	mov	ax, MSG_VIS_RULER_LOST_SELECTION
	call	MessageToRuler

	; if we have the model exclusive then update stuff (in case we are
	; switching between the document and the master page)

	call	SendDocumentNotifyIfModel

	mov	ax, MSG_META_LOST_TARGET_EXCL
	mov	di, offset StudioDocumentClass
	GOTO	ObjCallSuperNoLock

StudioDocumentLostTargetExcl	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentGainedModelExcl -- MSG_META_GAINED_MODEL_EXCL
						for StudioDocumentClass

DESCRIPTION:	Handle gaining the model exclusive

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/31/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentGainedModelExcl	method dynamic	StudioDocumentClass,
						MSG_META_GAINED_MODEL_EXCL

	test	ds:[di].GDI_attrs, mask GDA_CLOSING
	jz	notClosing
	ret

notClosing:
	ornf	ds:[di].SDI_state, mask SDS_MODEL
	push	ds:[di].SDI_currentPage

	mov	di, offset StudioDocumentClass
	call	ObjCallSuperNoLock

	mov	ax, mask NotifyFlags		;send all
	call	LockAndSendNotification

	; Send a hyperlink status notification
	
	call	SendHyperlinkStatusChangeNotification

	; Change the filename in ContentFileNameText, if it is visible

	push	si
	mov	si, offset ContentFileNameText
	GetResourceHandleNS	BookNameText, bx
	mov	ax, MSG_VIS_GET_ATTRS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	test	cl, mask VA_REALIZED
	jz	notVisible

	mov	ax, MSG_STUDIO_DOCUMENT_SET_CONTENT_FILE_NAME
	call	ObjCallInstanceNoLock

notVisible:	
	;
	; Force the article to send a GWNT_PAGE_NAME_CHANGE notification
	;
	pop	dx
	mov	ax, MSG_STUDIO_ARTICLE_PAGE_CHANGED
	call	GetFirstArticle
	clr	di
	GOTO	ObjMessage

StudioDocumentGainedModelExcl	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentLostModelExcl -- MSG_META_LOST_MODEL_EXCL
						for StudioDocumentClass

DESCRIPTION:	Handle losing the target

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/31/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentLostModelExcl	method dynamic	StudioDocumentClass,
						MSG_META_LOST_MODEL_EXCL

	andnf	ds:[di].SDI_state, not mask SDS_MODEL

	tst	ds:[di].GDI_fileHandle
	jz	skipNotify
	push	ax
	clr	ax
	call	LockAndSendNotification
	pop	ax
skipNotify:

	mov	di, offset StudioDocumentClass
	GOTO	ObjCallSuperNoLock

StudioDocumentLostModelExcl	endm

DocNotify ends

;============================================================================
;============================================================================

DocEditMP segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioMasterPageContentSetDocumentAndMP --
		MSG_STUDIO_MASTER_PAGE_CONTENT_SET_DOCUMENT_AND_MP
					for StudioMasterPageContentClass

DESCRIPTION:	Set the document that is associated with this master page

PASS:
	*ds:si - instance data
	es - segment of StudioMasterPageContentClass

	ax - The message

	cx:dx - document

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 5/92		Initial version

------------------------------------------------------------------------------@
StudioMasterPageContentSetDocumentAndMP	method dynamic	\
					StudioMasterPageContentClass,
				MSG_STUDIO_MASTER_PAGE_CONTENT_SET_DOCUMENT_AND_MP

	movdw	ds:[di].SMPCI_document, cxdx
	mov	ds:[di].SMPCI_mpBodyVMBlock, bp
	ret

StudioMasterPageContentSetDocumentAndMP	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	MessageToMPRuler

DESCRIPTION:	Send a message to the ruler

CALLED BY:	INTERNAL

PASS:
	*ds:si - master page content object
	ax, cx, dx, bp - message data

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/20/92		Initial version

------------------------------------------------------------------------------@
MessageToMPRuler	proc	far	uses ax, bx, cx, dx, si, di, bp
	class	StudioMasterPageContentClass
	.enter

	push	ax
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	push	ds:[di].SMPCI_mpBodyVMBlock
	movdw	bxsi, ds:[di].SMPCI_document
	mov	ax, MSG_GEN_DOCUMENT_GET_FILE_HANDLE
	mov	di, mask MF_CALL
	call	ObjMessage				;ax = file handle
	mov_tr	bx, ax
	pop	ax
	call	VMVMBlockToMemBlock			;ax = handle
	mov_tr	bx, ax
	pop	ax

	mov	si, offset MPHorizontalRuler
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret

MessageToMPRuler	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioMasterPageContentGainedTargetExcl --
		MSG_META_GAINED_TARGET_EXCL for StudioMasterPageContentClass

DESCRIPTION:	Tell the document that we are the target

PASS:
	*ds:si - instance data
	es - segment of StudioMasterPageContentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 5/92		Initial version

------------------------------------------------------------------------------@
StudioMasterPageContentGainedTargetExcl	method dynamic	\
					StudioMasterPageContentClass,
					MSG_META_GAINED_TARGET_EXCL

	mov	di, offset StudioMasterPageContentClass
	call	ObjCallSuperNoLock

	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	movdw	bxsi, ds:[di].SMPCI_document
	mov	ax, MSG_META_GRAB_MODEL_EXCL
	call	DEMP_ObjMessageNoFlags
	pop	si

	mov	ax, MSG_VIS_RULER_GAINED_SELECTION
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	MessageToMPRuler

	ret

StudioMasterPageContentGainedTargetExcl	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioMasterPageContentLostTargetExcl --
		MSG_META_LOST_TARGET_EXCL for StudioMasterPageContentClass

DESCRIPTION:	Handle losing the target

PASS:
	*ds:si - instance data
	es - segment of StudioMasterPageContentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 5/92		Initial version

------------------------------------------------------------------------------@
StudioMasterPageContentLostTargetExcl	method dynamic	\
					StudioMasterPageContentClass,
					MSG_META_LOST_TARGET_EXCL
	push	ax
	mov	ax, MSG_VIS_RULER_LOST_SELECTION
	call	MessageToMPRuler
	pop	ax

	mov	di, offset StudioMasterPageContentClass
	GOTO	ObjCallSuperNoLock

StudioMasterPageContentLostTargetExcl	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioMasterPageContentDraw -- MSG_VIS_DRAW
					for StudioMasterPageContentClass

DESCRIPTION:	Draw the master page

PASS:
	*ds:si - instance data
	es - segment of StudioMasterPageContentClass

	ax - The message

	cl - DrawFlags
	bp - gstate

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 5/92		Initial version

------------------------------------------------------------------------------@
StudioMasterPageContentDraw	method dynamic	StudioMasterPageContentClass,
								MSG_VIS_DRAW

	push	cx
	mov	di, bp

	; *** Draw the page border ***

	mov	ax, C_BLACK
	call	GrSetAreaColor
	mov	ax, C_BLACK
	call	GrSetLineColor
	mov	ax, SDM_50
	call	GrSetAreaMask

	; draw left

	call	getBoundsExpanded
	clr	cx				;right = 0
	call	GrFillRect

	; draw top

	call	getBoundsExpanded
	clr	dx				;bottom = 0
	call	GrFillRect

	; draw right

	call	getBoundsExpanded
	mov	ax, cx
	sub	ax, PAGE_BORDER_SIZE		;left = right-PAGE_BORDER_SIZE
	call	GrFillRect

	; draw bottom

	call	getBoundsExpanded
	mov	bx, dx
	sub	bx, PAGE_BORDER_SIZE		;top = bottom-PAGE_BORDER_SIZE
	call	GrFillRect

	; draw the frame

	mov	ax, SDM_100
	call	GrSetAreaMask
	clrdw	dxax				;use zero line width for speed
	call	GrSetLineWidth

	call	VisGetBounds
	call	GrDrawRect

	pop	cx

	mov	ax, MSG_VIS_DRAW
	mov	di, offset StudioMasterPageContentClass
	GOTO	ObjCallSuperNoLock

getBoundsExpanded:
	call	VisGetBounds
	sub	ax, PAGE_BORDER_SIZE
	sub	bx, PAGE_BORDER_SIZE
	add	cx, PAGE_BORDER_SIZE
	add	dx, PAGE_BORDER_SIZE
	retn

StudioMasterPageContentDraw	endm

DocEditMP ends
