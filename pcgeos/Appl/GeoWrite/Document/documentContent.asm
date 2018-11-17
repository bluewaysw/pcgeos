COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentContent.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the VisContent related code for WriteDocumentClass

	$Id: documentContent.asm,v 1.1 97/04/04 15:56:24 newdeal Exp $

------------------------------------------------------------------------------@

GeoWriteClassStructures	segment	resource
	WriteMasterPageContentClass
GeoWriteClassStructures	ends

;---

DocCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDocumentKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_KBD_CHAR
PASS:		*ds:si	= WriteDocumentClass object
		ds:di	= WriteDocumentClass instance data
		ds:bx	= WriteDocumentClass object (same as *ds:si)
		es 	= segment of WriteDocumentClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	7/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef _VS150

WriteDocumentKbdChar	method dynamic WriteDocumentClass, 
					MSG_META_KBD_CHAR
	.enter
	push	cx, dx
	mov	di, offset WriteDocumentClass
	call	ObjCallSuperNoLock
	pop	cx, dx

	test	dl, mask CF_RELEASE
	jz	done
	cmp	cx, (CS_CONTROL shl 8) or VC_PREVIOUS
	je	clickIt
	cmp	cx, (CS_CONTROL shl 8) or VC_NEXT
	jne	done
clickIt:
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_POSITION_CURSOR
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	.leave
	ret
WriteDocumentKbdChar	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDocumentPositionCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_POSITION_CURSOR
PASS:		*ds:si	= WriteDocumentClass object
		ds:di	= WriteDocumentClass instance data
		ds:bx	= WriteDocumentClass object (same as *ds:si)
		es 	= segment of WriteDocumentClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	
	This is all rather horrible.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	7/15/93   	Initial version
	cbh	3/94, 6/94	I'm just trying to hold it together...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef _VS150

WriteDocumentPositionCursor	method dynamic WriteDocumentClass, 
					MSG_POSITION_CURSOR
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	inc	ds:[di].WDI_selectCount

	;
	; Simulate mouse clicks to move the cursor position
	;
	mov	dx, 10
clickLoop:

	call	GetCursorLeftPos		;get left position to use

	mov	bp,	(mask BI_B0_DOWN or mask BI_PRESS) or \
			(mask UIFA_SELECT or mask UIFA_IN) shl 8
	push	dx

	mov	ax, MSG_META_START_SELECT
 	call	ObjCallInstanceNoLock
	mov	ax, MSG_META_END_SELECT
	call	ObjCallInstanceNoLock

	pop	dx
	cmp	dx, 340			; if dx=330...
	je	done
	
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].WDI_state, mask WDS_REPLAY
	jz	done			; then done
	add	dx, 10
	jmp	clickLoop
done:
if	1
	;
	; Since home changed functions in Redwood, Brian's gross hack no longer
	; works.   We'll use the vis text message directly.  Sigh.  6/ 1/94 cbh
	;
	mov	cx, VTKF_START_OF_TEXT
	mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
	call	ObjCallInstanceNoLock
else
	mov	cx, (CS_CONTROL shl 8) or VC_HOME
	mov	dx, mask CF_FIRST_PRESS
	clr	bp
	mov	ax, MSG_META_KBD_CHAR
	call	ObjCallInstanceNoLock
	mov	cx, (CS_CONTROL shl 8) or VC_HOME
	mov	dx, mask CF_RELEASE
	clr	bp
	mov	ax, MSG_META_KBD_CHAR
	call	ObjCallInstanceNoLock
endif
	.leave
	ret


WriteDocumentPositionCursor	endm

WriteDocumentPositionCursorDelayed	method dynamic WriteDocumentClass, 
					MSG_POSITION_CURSOR_DELAYED
	.enter
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_POSITION_CURSOR
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	.leave
	ret
WriteDocumentPositionCursorDelayed	endm

endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCursorLeftPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a left position to use for the mouse cursor.

CALLED BY:	WriteDocumentPositionCursor

PASS:		*ds:si -- WriteDocument object

RETURN:		cx -- left position to use

DESTROYED:	ax, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The rest of the cursor positioning code is highly questionable,
	but at least this routine should be working in a reasonable fashion.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/16/94       	Pulled out of WriteDocumentPositionCursor

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef _VS150

GetCursorLeftPos	proc	near		uses	dx, bx
	class	WriteDocumentClass
	.enter
	;
	; Pick a halfway-decent left margin to position cursor at.  3/ 6/94 cbh
	;
	; This was done incorrectly.  X cursor position should be in terms
	; of an offset into the window, and is thus:
	;	SAE_leftMargin - VCNI_docOrigin.PF_x * VCNI_scaleFactor.PF_x
	; And also, to guarantee the cursor stays onscreen, we'll also not
	; let this go negative.    -cbh 6/16/94
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].WDI_currentSection
	call	LockMapBlockES
	call	SectionArrayEToP_ES		;es:di = section element
	mov	cx, es:[di].SAE_leftMargin
	add	cx, 4
	shr	cx
	shr	cx
	shr	cx
	call	VMUnlockES			;cx <- pixel left margin

	mov	di, ds:[si]			;ignores high word for width,
	add	di, ds:[di].Vis_offset		;  only a problem if > 455" :)
	sub	cx, ds:[di].VCNI_docOrigin.PD_x.low	
	jns	mulByScale
;useZero:
	clr	cx				;use zero if negative
	jmp	short exit

mulByScale:
	mov	bx, cx
	clr	ax				;bx.ax = left margin
	movdw	dxcx, ds:[di].VCNI_scaleFactor.PF_x
	call	GrMulWWFixed			;result in dx.ax
	mov	cx, dx				;result in cx
exit:
	.leave
	ret
GetCursorLeftPos	endp

endif



COMMENT @----------------------------------------------------------------------

METHOD:		WriteDocumentCallObjectOfClass -- 
		MSG_VIS_VUP_CALL_OBJECT_OF_CLASS for WriteDocumentClass

DESCRIPTION:	Vups until finding an appropriate recipient of a classed
		event.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
		cx	- ClassedEvent

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	1/22/94         Initial Version

------------------------------------------------------------------------------@

ifdef _VS150

WriteDocumentCallObjectOfClass	method dynamic	WriteDocumentClass, \
				MSG_VIS_VUP_CALL_OBJECT_OF_CLASS

	mov	bx, cx
	push 	ax, cx, si
	call	ObjGetMessageInfo
	cmp	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
	pop	ax, cx, si
	jne	callSuper
	;
	; If in a certain mode, we'll intercept the make rect visible and
	; skip it.   (Fixed to work 3/ 6/94 cbh)
	;
	tst	ds:[di].WDI_selectCount
	jz	callSuper
	dec	ds:[di].WDI_selectCount
	jmp	short exit

callSuper:
	mov	di, offset WriteDocumentClass
	call	ObjCallSuperNoLock
exit:
	ret
WriteDocumentCallObjectOfClass	endm

endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentVupCreateGState -- MSG_VIS_VUP_CREATE_GSTATE
						for WriteDocumentClass

DESCRIPTION:	Create a gstate

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentVupCreateGState	method dynamic	WriteDocumentClass,
						MSG_VIS_VUP_CREATE_GSTATE

	mov	di, offset WriteDocumentClass

	FALL_THRU	CreateGStateCommon

WriteDocumentVupCreateGState	endm

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
	push	es
	GetResourceSegmentNS dgroup, es			;es = dgroup
	test	es:[miscSettings], mask WMS_SHOW_INVISIBLES
	pop	es
	jz	afterInvisibles
	mov	ax, mask TM_DRAW_CONTROL_CHARS
	call	GrSetTextMode
afterInvisibles:

	stc
	ret

CreateGStateCommon	endp

;---

WriteMasterPageContentVupCreateGState	method dynamic	\
						WriteMasterPageContentClass,
						MSG_VIS_VUP_CREATE_GSTATE

	mov	di, offset WriteMasterPageContentClass
	GOTO	CreateGStateCommon

WriteMasterPageContentVupCreateGState	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentLargeStartSelect -- MSG_META_LARGE_START_SELECT
						for WriteDocumentClass

DESCRIPTION:	Pass messages off to the appropriate layer

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentLargeStartSelect	method dynamic	WriteDocumentClass,
						MSG_META_LARGE_START_SELECT,
						MSG_META_LARGE_START_MOVE_COPY

	; if there are no children or if there is an active mouse grab then
	; let our superclass handle it

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	movdw	cxdx, ds:[di].VCI_comp.CP_firstChild
	tst	cx
	jnz	10$
	mov	di, offset WriteDocumentClass
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

	; this is GeoWrite's text tool -- we want to send to each child
	; until one claims it

	clr	bx				;bx = child number
ifdef _VS150
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	and	ds:[di].WDI_state, 0ffffh - mask WDS_REPLAY
else
	or	ds:[di].WDI_state, mask WDS_REPLAY
endif
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
ifdef _VS150
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	or	ds:[di].WDI_state, mask WDS_REPLAY
	pop	di
endif
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
	mov	ax, MSG_WRITE_DOCUMENT_SET_POSITION
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx
	jmp	done

WriteDocumentLargeStartSelect	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	IsTextTool

DESCRIPTION:	See whether the current tool from the GrObj is the text tool

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object

RETURN:
	carry - set if text tool
	zero - set if grobj's text tool

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
EC <	call	AssertIsWriteDocument					>

	GetResourceHandleNS WriteHead, bx
	mov	si, offset WriteHead
	mov	ax, MSG_GH_GET_CURRENT_TOOL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	DC_ObjMessage			;cx:dx = tool

	cmp	cx, segment MultTextGuardianClass
	jnz	10$
	cmp	dx, offset MultTextGuardianClass
	jz	doneGood
10$:

	cmp	cx, segment EditTextGuardianClass
	clc
	jnz	done
	cmp	dx, offset EditTextGuardianClass
	clc
	jnz	done
	cmp	dx, offset MultTextGuardianClass	;will be NZ
doneGood:
	stc

done:
	.leave
	ret

IsTextTool	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentViewOriginChanged --
		MSG_META_CONTENT_VIEW_ORIGIN_CHANGED for WriteDocumentClass

DESCRIPTION:	Handle the origin changing

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentViewOriginChanged	method dynamic	WriteDocumentClass,
					MSG_META_CONTENT_VIEW_ORIGIN_CHANGED

	push	bp
	mov	di, offset WriteDocumentClass
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

	; Is the bottom of the window on the same page ?

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

	mov	ax, MSG_WRITE_DOCUMENT_SET_POSITION
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
	jc	outOfBounds

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	cx, ds:[di].WDI_currentSection
	jnz	compareDone
	cmp	dx, ds:[di].WDI_currentPage
compareDone:
	clc
	retn

outOfBounds:
	retn

WriteDocumentViewOriginChanged	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentSetPositionAbs --
		MSG_WRITE_DOCUMENT_SET_POSITION_ABS for WriteDocumentClass

DESCRIPTION:	Set the position of the document given an absolute page
		position

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentSetPositionAbs	method dynamic WriteDocumentClass,
					MSG_WRITE_DOCUMENT_SET_POSITION_ABS

	; calculate page number and store it

	call	LockMapBlockES

	call	FindPageAndSectionAbs

	GOTO	SetPositionCommon

WriteDocumentSetPositionAbs	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentSetPosition -- MSG_WRITE_DOCUMENT_SET_POSITION
						for WriteDocumentClass

DESCRIPTION:	Set the position of the document

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentSetPosition	method dynamic WriteDocumentClass,
						MSG_WRITE_DOCUMENT_SET_POSITION


	; calculate page number and store it

	call	LockMapBlockES

	call	FindPageAndSection
EC <	ERROR_C	FIND_PAGE_RETURNED_ERROR				>

	FALL_THRU	SetPositionCommon

WriteDocumentSetPosition	endm

;---

SetPositionCommon	proc	far
	class	WriteDocumentClass

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	clr	ax
	cmp	cx, ds:[di].WDI_currentSection
	jz	10$
	mov	ax, mask NF_SECTION
10$:
	cmp	dx, ds:[di].WDI_currentPage
	jz	20$
	ornf	ax, mask NF_PAGE
20$:
	tst	ax
	jz	done
	mov	ds:[di].WDI_currentSection, cx
	mov	ds:[di].WDI_currentPage, dx

	call	SendNotification

done:

	call	VMUnlockES
	ret

SetPositionCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentSendClassedEvent -- MSG_META_SEND_CLASSED_EVENT
							for WriteDocumentClass

DESCRIPTION:	Pass a classed event to the right place

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentSendClassedEvent	method dynamic	WriteDocumentClass,
					MSG_META_SEND_CLASSED_EVENT

	push	cx, si
	mov	bx, cx
	call	ObjGetMessageInfo		;cxsi = class, ax = message
	movdw	bxdi, cxsi			;bxdi = class
	mov_tr	bp, ax				;bp = message
	pop	cx, si

	; check specially for PASTE

	cmp	bp, MSG_META_CLIPBOARD_PASTE
	LONG jz	paste

	; if there is no class then pass to the superclass

	tst	bx
	LONG jz	toSuper

	mov	ax, segment GrObjHeadClass
	mov	bp, offset GrObjHeadClass
	call	checkclassAXBP
	jnc	notHead

	; this message is destined for the GrObjHead

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	GetResourceHandleNS	WriteHead, bx
	mov	si, offset WriteHead
	call	DC_ObjMessageNoFlags
	ret
notHead:

	; check for the ruler

	mov	ax, segment VisRulerClass
	mov	bp, offset VisRulerClass
	call	checkclassAXBP
	jnc	notRuler

	; this message is destined for the ruler

	call	LockMapBlockES
	mov	ax, es:MBH_grobjBlock
	call	WriteVMBlockToMemBlock			;ax = handle
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
	call	checkclassAXBP
	jnc	notAttrMgr

	; this message is destined for the attribute manager

	call	LockMapBlockES
	mov	ax, es:MBH_grobjBlock
	call	WriteVMBlockToMemBlock			;ax = handle
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
	call	checkclassAXBP
	jc	toBody

	; check for the body

	mov	ax, segment GrObjBodyClass
	mov	bp, offset GrObjBodyClass
	call	checkclassAXBP
	jnc	notBody

	; this message is destined for the body -- find it

toBody:
	push	cx, dx
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
	movdw	bxsi, cxdx
	pop	cx, dx

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	call	DC_ObjMessageNoFlags
	ret
notBody:

	; check for an article

	GetResourceSegmentNS	WriteArticleClass, es
	mov	ax, es
	mov	bp, offset WriteArticleClass
	call	checkclassAXBP
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
	mov	di, offset WriteDocumentClass
	GOTO	ObjCallSuperNoLock

paste:
	push	es
	GetResourceSegmentNS dgroup, es
	test	es:[miscSettings], mask WMS_PASTE_GRAPHICS_TO_CURRENT_LAYER
	pop	es
	jnz	toSuper

	; if (no graphics layer) -> paste into text (which is the target)

	call	GetAppFeatures			;ax = features
	test	ax, mask WF_SIMPLE_GRAPHICS_LAYER or mask WF_GRAPHICS_LAYER
	jz	toSuper

	; if the target is the grobj then go there

	push	cx, dx
	mov	cx, TL_TARGET
	mov	ax, MSG_META_GET_TARGET_AT_TARGET_LEVEL
	call	ObjCallInstanceNoLock		;cxdx = object
						;axbp = class
	mov	cx, es
	cmp	ax, cx
	jnz	50$
	cmp	bp, offset WriteGrObjBodyClass
50$:
	pop	cx, dx
	jz	toSuper

	; if a text format exists then always go to the target

	push	cx, dx
	clr	bp
	call	ClipboardQueryItem		;bp = # formats
						;cxdx = owner, bxax = header
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_TEXT
	call	ClipboardTestItemFormat
	pushf
	call	ClipboardDoneWithItem
	popf
	pop	cx, dx
	jnc	toSuper

	; ask the user what they want

	push	cx, dx
	mov	ax, offset PasteToWhereString
	mov	cx, offset PasteToWhereTable
	mov	dx, CustomDialogBoxFlags \
			<0, CDT_QUESTION, GIT_MULTIPLE_RESPONSE,0>
	call	ComplexQuery			;ax = InteractionCommand
	pop	cx, dx
	cmp	ax, IC_NULL
	jz	abort
	cmp	ax, IC_DISMISS			;cancel
	jz	abort
	cmp	ax, IC_YES			;graphic
	LONG jnz toSuper

	; redirect this to the graphic body, but first force the graphics
	; tools visibile and force the pointer tool

	push	cx, dx, si
	GetResourceHandleNS	WriteHead, bx
	mov	si, offset WriteHead
	mov	ax, MSG_GH_SET_CURRENT_TOOL
	mov	cx, segment PointerClass
	mov	dx, offset PointerClass
	clr	bp
	call	DC_ObjMessageNoFlags
	mov	ax, MSG_WRITE_APPLICATION_FORCE_DRAWING_TOOLS_VISIBLE
	call	GenCallApplication
	pop	cx, dx, si

	jmp	toBody

abort:
	mov	bx, cx
	call	ObjFreeMessage
	ret

;---

	; is axbp a subclass of bxdi ? (carry set if so)

checkclassAXBP:
	push	si, ds, es
	movdw	dssi, axbp
	mov	es, bx
	call	ObjIsClassADescendant
	pop	si, ds, es
	retn

WriteDocumentSendClassedEvent	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentSetTargetBasedOnTool --
		MSG_WRITE_DOCUMENT_SET_TARGET_BASED_ON_TOOL
						for WriteDocumentClass

DESCRIPTION:	Set the target based on the (new) current tool

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentSetTargetBasedOnTool	method dynamic	WriteDocumentClass,
				MSG_WRITE_DOCUMENT_SET_TARGET_BASED_ON_TOOL

	; If the current tool is:
	; * geowrite text tool
	;	don't change target (unless there is no target)
	; * other
	;	target = grobj

	call	IsTextTool
	jnc	setGrObj
	jz	setGrObj

if 0
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	tst	ds:[di].VCNI_targetExcl.FTVMC_OD.handle
	jnz	done
endif

	; set the first article as the target

	clr	cx
	jmp	common

setGrObj:
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
;;;done:
	ret

WriteDocumentSetTargetBasedOnTool	endm

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
	call	WriteVMBlockToMemBlock			;ax = handle
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

MESSAGE:	WriteDocumentInvalidate -- MSG_VIS_INVALIDATE
						for WriteDocumentClass

DESCRIPTION:	Handle invalidating a document by also invalidating all
		the master pages

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentInvalidate	method dynamic	WriteDocumentClass, MSG_VIS_INVALIDATE

	; invalidate ourself

	push	ax
	mov	di, offset WriteDocumentClass
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

WriteDocumentInvalidate	endm

DocCommon ends

DocNotify segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentGainedTargetExcl -- MSG_META_GAINED_TARGET_EXCL
						for WriteDocumentClass

DESCRIPTION:	Handle gaining the target

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentGainedTargetExcl	method dynamic	WriteDocumentClass,
						MSG_META_GAINED_TARGET_EXCL

	ornf	ds:[di].WDI_state, mask WDS_TARGET

	mov	di, offset WriteDocumentClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_VIS_RULER_GAINED_SELECTION
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	MessageToRuler

	; if we have the model exclusive then update stuff (in case we are
	; switching between the document and the master page)

	call	SendDocumentNotifyIfModel

	call	SetGeoWriteToolIfNotPageMode

	ret

WriteDocumentGainedTargetExcl	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetGeoWriteToolIfNotPageMode

DESCRIPTION:	If not in page mode then set the GeoWrite tool

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
SetGeoWriteToolIfNotPageMode	proc	far	uses es
	.enter

	call	LockMapBlockES
	cmp	es:MBH_displayMode, VLTDM_PAGE
	jz	done
	call	SetGeoWriteTool
done:
	call	VMUnlockES

	.leave
	ret

SetGeoWriteToolIfNotPageMode	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetGeoWriteTool

DESCRIPTION:	If not in page mode then set the GeoWrite tool

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
SetGeoWriteTool	proc	far	uses ax, bx, cx, dx, si, bp
	.enter

	GetResourceHandleNS	WriteHead, bx
	mov	si, offset WriteHead
	mov	ax, MSG_GH_SET_CURRENT_TOOL
	mov	cx, segment EditTextGuardianClass
	mov	dx, offset EditTextGuardianClass
	clr	bp
	call	DN_ObjMessageNoFlags

	.leave
	ret

SetGeoWriteTool	endp

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
	class	WriteDocumentClass
EC <	call	AssertIsWriteDocument					>

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].WDI_state, mask WDS_MODEL
	jz	done
	mov	ax, mask NF_DOCUMENT
	call	LockAndSendNotification
done:
	ret

SendDocumentNotifyIfModel	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentLostTargetExcl -- MSG_META_LOST_TARGET_EXCL
						for WriteDocumentClass

DESCRIPTION:	Handle losing the target

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentLostTargetExcl	method dynamic	WriteDocumentClass,
						MSG_META_LOST_TARGET_EXCL

	andnf	ds:[di].WDI_state, not mask WDS_TARGET

	mov	ax, MSG_VIS_RULER_LOST_SELECTION
	call	MessageToRuler

	; if we have the model exclusive then update stuff (in case we are
	; switching between the document and the master page)

	call	SendDocumentNotifyIfModel

	mov	ax, MSG_META_LOST_TARGET_EXCL
	mov	di, offset WriteDocumentClass
	GOTO	ObjCallSuperNoLock

WriteDocumentLostTargetExcl	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentGainedModelExcl -- MSG_META_GAINED_MODEL_EXCL
						for WriteDocumentClass

DESCRIPTION:	Handle gaining the model exclusive

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentGainedModelExcl	method dynamic	WriteDocumentClass,
						MSG_META_GAINED_MODEL_EXCL

	test	ds:[di].GDI_attrs, mask GDA_CLOSING
	jnz	done

	ornf	ds:[di].WDI_state, mask WDS_MODEL

	mov	di, offset WriteDocumentClass
	call	ObjCallSuperNoLock

	mov	ax, mask NotifyFlags		;send all
	call	LockAndSendNotification
done:
	ret

WriteDocumentGainedModelExcl	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentLostModelExcl -- MSG_META_LOST_MODEL_EXCL
						for WriteDocumentClass

DESCRIPTION:	Handle losing the target

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentLostModelExcl	method dynamic	WriteDocumentClass,
						MSG_META_LOST_MODEL_EXCL

	andnf	ds:[di].WDI_state, not mask WDS_MODEL

	tst	ds:[di].GDI_fileHandle
	jz	skipNotify
	push	ax
	clr	ax
	call	LockAndSendNotification
	pop	ax
skipNotify:

	mov	di, offset WriteDocumentClass
	GOTO	ObjCallSuperNoLock

WriteDocumentLostModelExcl	endm

DocNotify ends

;============================================================================
;============================================================================

DocEditMP segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteMasterPageContentSetDocumentAndMP --
		MSG_WRITE_MASTER_PAGE_CONTENT_SET_DOCUMENT_AND_MP
					for WriteMasterPageContentClass

DESCRIPTION:	Set the document that is associated with this master page

PASS:
	*ds:si - instance data
	es - segment of WriteMasterPageContentClass

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
WriteMasterPageContentSetDocumentAndMP	method dynamic	\
					WriteMasterPageContentClass,
				MSG_WRITE_MASTER_PAGE_CONTENT_SET_DOCUMENT_AND_MP

	movdw	ds:[di].WMPCI_document, cxdx
	mov	ds:[di].WMPCI_mpBodyVMBlock, bp
	ret

WriteMasterPageContentSetDocumentAndMP	endm

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
	class	WriteMasterPageContentClass
	.enter

	push	ax
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	push	ds:[di].WMPCI_mpBodyVMBlock
	movdw	bxsi, ds:[di].WMPCI_document
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

MESSAGE:	WriteMasterPageContentGainedTargetExcl --
		MSG_META_GAINED_TARGET_EXCL for WriteMasterPageContentClass

DESCRIPTION:	Tell the document that we are the target

PASS:
	*ds:si - instance data
	es - segment of WriteMasterPageContentClass

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
WriteMasterPageContentGainedTargetExcl	method dynamic	\
					WriteMasterPageContentClass,
					MSG_META_GAINED_TARGET_EXCL

	mov	di, offset WriteMasterPageContentClass
	call	ObjCallSuperNoLock

	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	movdw	bxsi, ds:[di].WMPCI_document
	mov	ax, MSG_META_GRAB_MODEL_EXCL
	call	DEMP_ObjMessageNoFlags
	pop	si

	mov	ax, MSG_VIS_RULER_GAINED_SELECTION
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	MessageToMPRuler

	ret

WriteMasterPageContentGainedTargetExcl	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteMasterPageContentLostTargetExcl --
		MSG_META_LOST_TARGET_EXCL for WriteMasterPageContentClass

DESCRIPTION:	Handle losing the target

PASS:
	*ds:si - instance data
	es - segment of WriteMasterPageContentClass

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
WriteMasterPageContentLostTargetExcl	method dynamic	\
					WriteMasterPageContentClass,
					MSG_META_LOST_TARGET_EXCL
	push	ax
	mov	ax, MSG_VIS_RULER_LOST_SELECTION
	call	MessageToMPRuler
	pop	ax

	mov	di, offset WriteMasterPageContentClass
	GOTO	ObjCallSuperNoLock

WriteMasterPageContentLostTargetExcl	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteMasterPageContentDraw -- MSG_VIS_DRAW
					for WriteMasterPageContentClass

DESCRIPTION:	Draw the master page

PASS:
	*ds:si - instance data
	es - segment of WriteMasterPageContentClass

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
WriteMasterPageContentDraw	method dynamic	WriteMasterPageContentClass,
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
	mov	di, offset WriteMasterPageContentClass
	GOTO	ObjCallSuperNoLock

getBoundsExpanded:
	call	VisGetBounds
	sub	ax, PAGE_BORDER_SIZE
	sub	bx, PAGE_BORDER_SIZE
	add	cx, PAGE_BORDER_SIZE
	add	dx, PAGE_BORDER_SIZE
	retn

WriteMasterPageContentDraw	endm

DocEditMP ends
