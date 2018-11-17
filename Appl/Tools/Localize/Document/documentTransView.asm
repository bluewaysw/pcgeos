COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ResEdit/Document
FILE:		documentTransView.asm

AUTHOR:		Cassie Hartzong, Oct 12, 1992

ROUTINES:
	Name			Description
	----			-----------
	DocumentViewSizeChanged
	DocumentVisDraw
	DocumentStartSelect	Handler for MSG_META_START_SELECT.
	DocumentStartSelectCommon
	DocumentEndSelect	Handler for MSG_META_END_SELECT.
	DocumentPtr		Handler for MSG_META_PTR.
INT	FindChunkInView		Finds the chunk located at the passed height.
INT	SendToTarget		Passes pointer event to current text target.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/12/92	Initial revision


DESCRIPTION:
	This module contains code for handling input events and
	UI messages sent to the right view, containing the Translation
	Document.

	$Id: documentTransView.asm,v 1.1 97/04/04 17:14:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransViewCode	segment	resource

DocTrans_ObjMessage_call		proc	near
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
DocTrans_ObjMessage_call		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentViewSizeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	View window's size has changed

CALLED BY:	UI
PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		es 	= segment of ResEditDocumentClass
		ax	= message #
		cx	= new view width
		dx	= new view height

RETURN:		dx	= new document height
DESTROYED:	ax,bx,si,di,ds,es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If width has not changed, no need to recalculate and change
	the document bounds.  This relies on both views having the
	same size.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentViewSizeChanged		method dynamic ResEditDocumentClass, 
					MSG_RESEDIT_DOCUMENT_VIEW_SIZE_CHANGED

	mov	ds:[di].REDI_viewHeight, dx

	DerefDoc
	cmp	cx, ds:[di].REDI_viewWidth
	je	done

	mov	ds:[di].REDI_viewWidth, cx
	call 	RecalcChunkPositions			;dx = new height
done:
	ret

DocumentViewSizeChanged		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A part of the document has been exposed and needs
		to be redrawn.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si - document object
		ds:di -  instance data
		es - seg addr of ResEditDocumentClass
		ax - the message
		^hbp 	= GState
		cl	= DrawFlags

RETURN:		^hbp	= GState

DESTROYED:	ax,dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentVisDraw		method dynamic ResEditDocumentClass,
						MSG_VIS_DRAW

	;
	; grab focus away from text so cursor stops flashing
	;
	test	ds:[di].REDI_chunkType, mask CT_TEXT
	jz	notText
	push	cx, bp
	movdw	cxdx, ds:[di].REDI_editText
	mov	bp, mask MAEF_FOCUS
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock
	pop	cx, bp

notText:
	mov	dl, ST_TRANSLATION
	mov	ax, MSG_RESEDIT_DOCUMENT_DRAW
	call	ObjCallInstanceNoLock	

	ret
DocumentVisDraw		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mouse button has been pressed.

CALLED BY:	MSG_META_START_SELECT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		cx = pointer x position
		dx = pointer y position
		bp low = ButtonInfo
		bp high = ShiftState

RETURN:		ax	- MouseReturnFlag

DESTROYED:	ax, bx, si, di, ds, es (method handler)
		cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/16/92	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentStartSelect		method dynamic ResEditDocumentClass,
						MSG_META_START_SELECT

	mov	ds:[di].REDI_newTarget, ST_TRANSLATION

	call	DocumentStartSelectCommon
	mov	ax, mask MRF_PROCESSED
	ret
DocumentStartSelect		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentStartSelectCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for META_START_SELECT method.

CALLED BY:	MSG_RESEDIT_DOCUMENT_START_SELECT
		DocumentStartSelect and ContentStartSelect

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		cx = pointer x position
		dx = pointer y position
		bp low = ButtonInfo
		bp high = ShiftState

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentStartSelectCommon		method  ResEditDocumentClass,
				MSG_RESEDIT_DOCUMENT_START_SELECT

	tst	ds:[di].REDI_numChunks
	jz	done

	push	cx,dx,bp

	; if editing, let the EditText handle this if the mouse
	; is within its bounds
	;
	call	FindChunkInView			;find chunk under mouse
	mov	cx, ax				;cx <- chunk number
	jc	select				;no visible chunk under mouse
	cmp	cx, ds:[di].REDI_curChunk	;is curChunk under the mouse 
	jne	select				;no, need to change chunk
	call	GrabTargetAndFocus		;return target, focus to text

	DerefDoc
	test	ds:[di].REDI_chunkType, CT_GRAPHICS
	jnz	graphics

passItOn:
	DerefDoc
	pop	cx,dx,bp
	mov	ax, MSG_META_START_SELECT
	call	SendToTarget
done:
	ret
	
graphics:
	call	InitializeEditGraphics		;select the graphics
	pop	cx,dx,bp
	jmp	done

select:
	; select this chunk in the chunk list if it is not already selected
	;
	cmp	cx, ds:[di].REDI_curChunk
	je	donePop
	push	si
	mov	bx, ds:[di].GDI_display
	mov	si, offset ChunkList
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	push	cx
	clr	di
	call	ObjMessage
	pop	cx
	pop	si

	; now update internal state, redraw the highlight
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_RESEDIT_DOCUMENT_CHANGE_CHUNK
	mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE or \
		 mask MF_REPLACE
	call	ObjMessage
	jmp	passItOn

donePop:
	add	sp, 6				;restore stack
	jmp	done

DocumentStartSelectCommon		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrabTargetAndFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A start select event has occurred, and the target and focus
		have been taken away from the text object.  The text object
		(possibly different, if the start select occurred in the
		other view) needs to get the target and focus back.

CALLED BY:	DocumentStartSelectCommon

PASS:		ds:di	- document
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/30/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrabTargetAndFocus		proc	near

	mov	al, ds:[di].REDI_newTarget
	cmp	al, ds:[di].REDI_curTarget	; does newTarget = curTarget?
	je	done				; yes, no change 

	test	ds:[di].REDI_chunkType, CT_GRAPHICS
	jnz	graphics
	test	ds:[di].REDI_chunkType, mask CT_OBJECT or mask CT_TEXT
	jz	done
	push	ax
	call	FinishEditText
	pop	ax
done:
	DerefDoc
	mov	ds:[di].REDI_curTarget, al
	call	ObjMarkDirty
	ret

graphics:
	call	FinishEditGraphics
	jmp	done
GrabTargetAndFocus		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mouse button has been released.

CALLED BY:	MSG_META_END_SELECT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		cx = pointer x position
		dx = pointer y position
		bp low = ButtonInfo
		bp high = ShiftState

RETURN:		ax	- MouseReturnFlags

DESTROYED:	bx, si, di, ds, es (method handler)
		cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentEndSelect		method dynamic ResEditDocumentClass,
						MSG_META_END_SELECT

	tst	ds:[di].REDI_numChunks
	jz	done
	;
	; if the text object is doing a selection, let it have this event
	;
	mov	ax, MSG_META_END_SELECT
	call	SendToTarget
	;
	; update the edit menu, mnemonic and shortcut displays
	;
	call	SetEditMenuState

done:	
	mov	ax, mask MRF_PROCESSED
	ret
DocumentEndSelect		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The mouse has moved within the document's view.

CALLED BY:	MSG_META_PTR

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		cx = pointer x position
		dx = pointer y position
		bp low = ButtonInfo
		bp high = ShiftState

RETURN:		ax - MouseReturnFlag

DESTROYED:	ax, bx, si, di, ds, es (method handler)
		cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/16/92	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentPtr		method dynamic ResEditDocumentClass,
						MSG_META_PTR

	call	SendToTarget
	mov	ax, mask MRF_PROCESSED	
	ret
DocumentPtr		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindChunkInView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the chunk located in the view at the passed height

CALLED BY:	
PASS:		*ds:si	= document instance data
		dx	= mouse y pos

RETURN:		carry clear if a chunk was found under the mouse
			ax	= chunk number
		carry set if mouse outside of view
			ax 	= next closest chunk just outside of view

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindChunkInView		proc	near
	uses	bx,cx,dx,si,es,bp
	.enter

	mov	bp, si
	DerefDoc

	; if this is an empty resouce, return null
	mov	ax, PA_NULL_ELEMENT
	mov	bx, ds:[di].REDI_posArray
	tst	bx
	stc
	LONG	jz	noChunks

	push	bx
	call	MemLock
	mov	es, ax
	clr	si
	mov	cx, ds:[di].REDI_numChunks
	mov	ax, es:[si].PE_top
	cmp	dx, 0
	jl	outOfView

check:
	cmp	dx, ax
	jl	next
	add	ax, es:[si].PE_height
	add	ax, (SELECT_LINE_WIDTH*2)
	cmp	dx, ax
	jle	found

next:
	add	si, size PosElement
	loop	check
	jmp	notFound

found:
	mov	ax, si
	mov	cl, size PosElement
	div	cl
	clc
	jmp	done

notFound:
	; check if the mouse is below the document, by comparing
	; the mouse yPos to the document's bottom coordinate
	push	dx, bp				;save yPos, doc chunk
	sub	sp, size RectDWord
	mov	dx, sp
	mov	cx, ss				;cx:dx <- RectDWord buffer
	mov	bx, ds:[di].GDI_display
	mov	si, offset RightView
	mov	ax, MSG_GEN_VIEW_GET_DOC_BOUNDS
	call	DocTrans_ObjMessage_call
	mov	bp, dx
	mov	cx, ss:[bp].RD_bottom.low	;cx <- document bottom
	add	sp, size RectDWord
	pop	dx, bp
	cmp	dx, cx				;is yPos within doc bounds?
	jb	outOfView			;no, it must be out of view
	mov	ax, ds:[di].REDI_numChunks	;mouse is below the doc,
	dec	ax				;so return the last chunk 
	stc
	jmp	done
		
outOfView:
	; the mouse is outside the view bounds, find out if it is
	; above or below the view by comparing it to the view origin.
	push	dx, bp					;dx = mouse yPos
	mov	bx, ds:[di].GDI_display
	mov	si, offset RightView
	mov	ax, MSG_VIS_GET_BOUNDS
	call	DocTrans_ObjMessage_call		;bp <- top, dx<- bottom
	pop	cx, si					;cx <- mouse y position
	cmp	cx, bp					
	jle	below					;mouse is before view
	dec	dx					;move bottom up
	call	FindChunkInView				;ax<-last visible chunk
	inc	ax					;ax<-first non vis.
	cmp	ax, ds:[di].REDI_numChunks		;check if last chunk
	jne	notLast					;nope! return ax
	dec	ax					;back up to last
notLast:
	stc						;ax <- next chunk
	jmp	done

below:
	inc	cx					;move mouse down
	mov	dx, cx					;find first visible
	call	FindChunkInView				; chunk in the view
	tst	ax					;if it is first chunk
	jz	isFirst					;return it in ax
	dec	ax					;else return previous
isFirst:		
	stc

done:
	pop	bx
	call	MemUnlock
noChunks:
	.leave
	ret

FindChunkInView		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to either the translation or original
		text object's content's superclass, depending on who 
		has the target.

CALLED BY:	INTERNAL 

PASS:		*ds:si	- document instance data
		ax	- message to send
		cx,dx,bp	- data to pass

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToTarget		proc	near
	uses	bx,si,di,ds,es
	.enter

	; If it is not text, don't send it anywhere for now.
	; Gstrings and bitmaps are not objects, so don't really
	; care about pointer events	
	;
	DerefDoc
	test	ds:[di].REDI_chunkType, mask CT_TEXT
	jz	done

	cmp	ds:[di].REDI_curTarget, ST_TRANSLATION
	je	sendToDoc

	push	ax
	mov	bx, ds:[di].REDI_editText.handle
	call	ObjLockObjBlock
	mov	ds, ax
	mov	si, offset OrigContent			;*ds:si <- OrigContent
	GetResourceSegmentNS	ResEditContentClass, es
	mov	di, offset ResEditContentClass
	pop	ax

callSuper:
	call	ObjCallSuperNoLock
	cmp	si, offset OrigContent
	jne	done
	call	MemUnlock
done:
	.leave
	ret

sendToDoc:
	GetResourceSegmentNS	ResEditDocumentClass, es
	mov	di, offset ResEditDocumentClass
	jmp	callSuper

SendToTarget		endp

TransViewCode		ends


