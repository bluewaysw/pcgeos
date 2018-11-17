COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ResEdit/Document
FILE:		documentSourceView.asm

AUTHOR:		Cassie Hartzog, Oct 12, 1992

ROUTINES:
	Name			Description
	----			-----------
	ContentViewSizeChanged	View window's size has changed 
	ContentVisDraw		A part of the Content has been exposed and 
				needs to be redrawn. 
	ContentSetDocument	A document is being attached, store its optr in 
				my instance data 
	ContentPtrEvent		Handler for mouse pointer events. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cassie	10/12/92	Initial revision


DESCRIPTION:
	This module contains the code for drawing the SourceView 
	content.

	$Id: documentSourceView.asm,v 1.1 97/04/04 17:14:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SourceViewCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentViewSizeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	View window's size has changed

CALLED BY:	UI
PASS:		*ds:si	= ResEditContentClass object
		ds:di	= ResEditContentClass instance data
		es 	= segment of ResEditContentClass
		ax	= message #
		bp	= window handle
		cx	= new width
		dx	= new height
RETURN:		nothing
DESTROYED:	bx,dx,si,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If width has not changed, no need to recalculate and change
	the Content bounds.  This relies on both views having the
	same size.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentViewSizeChanged		method dynamic ResEditContentClass, 
					MSG_META_CONTENT_VIEW_SIZE_CHANGED

	; let the superclass handle the geomtry updating and stuff
	;
	push	cx, dx
	mov	di, offset ResEditContentClass
	call	ObjCallSuperNoLock
	mov	di, ds:[si]
	add	di, ds:[di].ResEditContent_offset
	pop	cx, dx

	; pass the message to the document, where the recalculating
	; of the document height at the new width is done
	;
	movdw	bxsi, ds:[di].RECI_document
	mov	di, mask MF_CALL or mask MF_FIXUP_DS 
	mov	ax, MSG_RESEDIT_DOCUMENT_VIEW_SIZE_CHANGED
	call	ObjMessage	

	ret
ContentViewSizeChanged		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A part of the Content has been exposed and needs
		to be redrawn.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si - content object
		ds:di -  instance data
		es - seg addr of ResEditContentClass
		ax - the message
		^hbp 	- GState
		cl	- DrawFlags

RETURN:		^hbp	- GState

DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
	Let the document handle the redraw.

	For redraws caused by changing the resource:
	Since this method calls VisDrawCommon via ObjMessage, 
	the SourceView will always be drawn after the TransView,
	which calls it directly, and gets MSG_VIS_DRAW first, too.
	So this method clears the changing resource flag, which is
	set to prevent VisDrawCommon from calling DocumentSaveChunk
	before the mnemonic information has been set correctly by the
	call to InitializeEdit at the end VisDrawCommon.  The old chunk
	will have already been saved by the FinishEdit call in 
	DocumentChangeResource, and the new current chunk will not have
	been edited yet, so there is no need to save it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentVisDraw		method dynamic ResEditContentClass,
						MSG_VIS_DRAW

	; If we're in batch mode, we don't want to redraw anything.

	call	IsBatchMode
	jc	done

	; grab focus away from text so cursor stops flashing
	;
	push	cx, bp
	mov	cx, ds:[LMBH_handle]
	mov	dx, offset OrigText
	mov	bp, mask MAEF_FOCUS
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	ObjCallInstanceNoLock
	pop	cx, bp

	; call VisDrawCommon to do the drawing
	;
	movdw	bxsi, ds:[di].RECI_document
	mov	dl, ST_ORIGINAL
	mov	ax, MSG_RESEDIT_DOCUMENT_DRAW
	mov	di, mask MF_CALL
	call	ObjMessage

	;clear the changing resource flag, in case it was set
	;
	mov	cl, mask DS_CHANGING_RESOURCE
	clr	ch
	mov	ax, MSG_RESEDIT_DOCUMENT_SET_STATE
	clr	di
	call	ObjMessage
done:
	ret

ContentVisDraw		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentSetDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A document is being attached, store its optr in my
		instance data

CALLED BY:	MSG_RESEDIT_CONTENT_SET_DOCUMENT
PASS:		*ds:si  = instance data
		ds:di 	= *ds:si
		es 	= seg addr of ResEditContentClass
		ax 	= the message
		^lcx:dx	= the document
RETURN:		nothing
DESTROYED:	bx,si,di,ds destroyed by ObjMessage

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentSetDocument		method dynamic ResEditContentClass,
					MSG_RESEDIT_CONTENT_SET_DOCUMENT

	call	ObjMarkDirty
	movdw	ds:[di].RECI_document, cxdx
	ret
ContentSetDocument		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentPtrEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for mouse pointer events.

CALLED BY:	UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditContentClass
		ax - the message
		cx - x position
		dx - y position
		bp - flags

RETURN:		ax - MouseReturnFlag

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/22/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentPtrEvent		method dynamic ResEditContentClass,
						MSG_META_START_SELECT, 
						MSG_META_END_SELECT, 
						MSG_META_PTR

	; save the original message number and passed parameters
	;
	push	cx, dx, bp

	; Only change the target on start select. 
	;
	cmp	ax, MSG_META_START_SELECT
	jne	sendEvent

	; set the new target in the document instance data
	;
	movdw	bxsi, ds:[di].RECI_document
	mov	dl, ST_ORIGINAL
	mov	ax, MSG_RESEDIT_DOCUMENT_SET_NEW_TARGET
	call	DocSV_ObjMessage_call		

	; Let the document process the start select
	;
	mov	ax, MSG_RESEDIT_DOCUMENT_START_SELECT

sendEvent:
	movdw	bxsi, ds:[di].RECI_document
	pop	cx, dx, bp			;restore passed registers
	clr	di
	call	ObjMessage			;send this event to document

	mov	ax, mask MRF_PROCESSED
	ret
ContentPtrEvent		endm


;----

DocSV_ObjMessage_call		proc	near
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
DocSV_ObjMessage_call		endp

SourceViewCode		ends


