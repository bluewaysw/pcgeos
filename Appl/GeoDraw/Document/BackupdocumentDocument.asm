COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Document
FILE:		documentDocument.asm

AUTHOR:		Steve Scholl

ROUTINES:
	Name	
	----	
DrawDocumentDuplicateMainBlock
DrawDocumentInitMapBlockBoundsMargins
DrawDocumentInitGrObjBody
DrawDocumentInitGOAM
DrawDocumentAttachRulerUI
DrawDocumentDetachRulerUI

METHOD HANDLERS:
	Name	
	----	
DrawDocumentInitializeDocumentFile
DrawDocumentAttachUI
DrawDocumentDetachUI
DrawDocumentVisDraw
DrawDocumentInvalidate	
DrawDocumentSendClassedEvent
DrawDocumentGainedTargetExcl
DrawDocumentLostTargetExcl
DrawDocumentUpdateRulers

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/9/92		Initial revision

DESCRIPTION:

	$Id: BackupdocumentDocument.asm,v 1.1 97/04/04 15:51:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


idata	segment

	DrawDocumentClass

idata	ends

DocumentCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentInitializeDocumentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the document file (newly created).

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of DrawDocumentClass

RETURN:		
		carry - set if error
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
	This message is invoked when a new document has been created and
	the document file needs to be initialized.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentInitializeDocumentFile	method dynamic DrawDocumentClass, 
				MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE
	.enter

	;    Let superclass do its thang
	;

	mov	di,offset DrawDocumentClass
	call	ObjCallSuperNoLock


	call	DrawDocumentAllocMapBlock
	call	DrawDocumentInitMapBlockBoundsMargins
	call	DrawDocumentDuplicateMainBlock
	call	DrawDocumentInitGrObjBody
	call	DrawDocumentInitGOAM
	call	DrawDocumentUpdatePageSizeControl

	Destroy 	ax,cx,dx,bp

	clc			;no error
	.leave
	ret
DrawDocumentInitializeDocumentFile		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentInitMapBlockBoundsMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the bounds and the margins that are stored
		in the map block. 

CALLED BY:	INTERNAL
		DrawDocumentInitializeDocumentFile

PASS:		*ds:si - DrawDocument
		map block must have been allocated

RETURN:		
		In map block
			DMB_width
			DMB_height	
			DMB_orientation
			DMB_margins

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentInitMapBlockBoundsMargins		proc	near
	uses	ax,bx,cx,dx,bp,si,es,di
	.enter

EC <	call	ECCheckDocument					>

	;    Set document dimensions from default document size
	;

	sub	sp, size PageSizeReport
	mov	di, sp					;es:di <- PageSizeReport
	push	si, ds					;document
	mov	ax, ss
	mov	es,ax
	mov	ds,ax
	mov	si, di					;ds:si <- PageSizeReport
	call	SpoolGetDefaultPageSizeInfo
	pop	si, ds					;document
	movdw	dxcx, es:[di].PSR_width
	movdw	bxax, es:[di].PSR_height
	mov	bp, es:[di].PSR_layout
	call	DrawDocumentSetDocumentDimensions

	;    Set margins in document data block
	;

	mov	ax,es:[di].PSR_margins.PCMP_left
	mov	bx,es:[di].PSR_margins.PCMP_top
	mov	cx,es:[di].PSR_margins.PCMP_right
	mov	dx,es:[di].PSR_margins.PCMP_bottom
	call	DrawDocumentSetDocumentMargins

	add	sp, size PageSizeReport

	.leave
	ret
DrawDocumentInitMapBlockBoundsMargins		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentDuplicateMainBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate and attach to the vm file the block
		that contains the GrObjBody, ObjectAttributeManager
		and Rulers. Allocate map block and store the
		vm block handle in it.

CALLED BY:	INTERNAL
		DrawDocumentInitializeDocumentFile

PASS:		*ds:si - DrawDocument

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentDuplicateMainBlock		proc	near
	class	DrawDocumentClass
	uses	ax,bx,cx,bp,es
	.enter

EC <	call	ECCheckDocument					>

	;    Duplicate block with GrObjBody and ObjectAttributeManager
	;    in it and have its burden thread be our process thread.
	;    The attach block to the vm file.The handles must be preserved,
	;    otherwise the block may get discarded and loaded back in
	;    with a different memory handle causing random obscure death 
	;    when we attempt to send messages to that object.
	;

	GetResourceHandleNS	DrawBodyRulerGOAMResTemp, bx
	clr	ax				; have current geode own block
	clr	cx				; have current thread run block
	call	ObjDuplicateResource

	mov	cx,bx				;mem handle of new block
	mov	bx,ds:[si]
	add	bx,ds:[bx].DrawDocument_offset
	mov	bx,ds:[bx].GDI_fileHandle
	clr	ax				;create new vm block
	call	VMAttach
	call	VMPreserveBlocksHandle

	call	DrawDocumentSetBodyGOAMRulerVMBlock

	.leave
	ret
DrawDocumentDuplicateMainBlock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentInitGrObjBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send necessary initialization messages to GrObjBody

CALLED BY:	INTERNAL
		DrawDocumentInitializeDocumentFile

PASS:		*ds:si - DrawDocument

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentInitGrObjBody		proc	near
	uses	ax,di
	.enter

EC <	call	ECCheckDocument				>

	;    Set the bounds in the body from the data stored in the
	;    map block

	call	DrawDocumentSetGrObjBodyBounds

	.leave
	ret
DrawDocumentInitGrObjBody		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentInitGOAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send necessary initialization message to 
		ObjectAttributeManager

CALLED BY:	INTERNAL
		DrawDocumentInitializeDocumentFile

PASS:		*ds:si - DrawDocument

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentInitGOAM		proc	near
	uses	di,ax
	.enter

	;    Have attribute manager create all the attribute and style arrays
	;    that it needs to use.
	;

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GOAM_CREATE_ALL_ARRAYS
	call	DrawDocumentMessageToGOAM

	.leave
	ret
DrawDocumentInitGOAM		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentAttachUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Document has been opened. Need to add body as child
		of document and notify it of opening

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of DrawDocumentClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentAttachUI	method dynamic DrawDocumentClass, \
				MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
	.enter

	;    Set bits for large document model
	;    clear bits for unmanaged geometry
	;

	mov	bx, Vis_offset
	call	ObjInitializePart
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].VCNI_attrs, mask VCNA_LARGE_DOCUMENT_MODEL \
				 or mask VCNA_WINDOW_COORDINATE_MOUSE_EVENTS
	andnf	ds:[di].VI_attrs, not (mask VA_MANAGED)
	andnf	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID \
				       or mask VOF_GEO_UPDATE_PATH)
	ornf	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN

	;    Have superclass do its thang
	;

	mov	di, offset DrawDocumentClass	
	call	ObjCallSuperNoLock

	call	DrawDocumentSendDocumentSizeToView

	;    Attach ruler contents to ruler view
	;    and rulers to ruler contents
	;

	call	DrawDocumentAttachRulerUI

	;    Get output descriptor of GrObjBody from map block
	;

	call	DrawDocumentGetBodyGOAMRulerMemHandle
	mov	cx,bx
	mov	dx,offset DrawGrObjBodyObjTemp

	;    Add the graphic body as the first child of the
	;    Document/Content. Don't mark dirty because we don't
	;    want the document dirtied as soon as it is open, nor
	;    do we save the Document/Content or the parent pointer
	;    in the GrObjBody.
	;

	mov	bp,CCO_FIRST
	mov	ax,MSG_VIS_ADD_NON_DISCARDABLE_VM_CHILD
	call	ObjCallInstanceNoLock

	;    Notify the GrObjBody that it has been added to
	;    the Document/Content. And pass GrObjHead to it.
	;

	GetResourceHandleNS	DrawGrObjHeadObj,cx
	mov	dx, offset DrawGrObjHeadObj
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GB_ATTACH_UI
	call	DrawDocumentMessageToGrObjBody

	Destroy	ax,cx,dx,bp

	.leave
	ret
DrawDocumentAttachUI		endm


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
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/20/92		Initial version

------------------------------------------------------------------------------@
MessageToRuler	proc	near

	uses	bx, si, di, es
	.enter

	call	DrawDocumentGetBodyGOAMRulerMemHandle
	mov	si, offset DrawColumnRulerObjTemp
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
MessageToRuler	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentAttachRulerUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach the ruler contents to the ruler views and
		the rulers to the ruler contents

CALLED BY:	INTERNAL
		DrawDocumentAttachUI

PASS:		*ds:si - DrawDocument


RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		The Ruler Contents are in the same block as this 
		document object.

		The Ruler Views are in the same block as the main view, 
		which is in the same block as the display.

		The Rulers are in the same block as the graphic body.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentAttachRulerUI		proc	near
	class	DrawDocumentClass
	uses	ax,bx,cx,dx,bp,di,si
	.enter

EC <	call	ECCheckDocument					>

	;    Attach the contents to the views
	;

	push	si					;document chunk
	mov	di,ds:[si]
	add	di,ds:[di].DrawDocument_offset
	mov	bx,ds:[di].GDI_display
	mov	cx,ds:[LMBH_handle]
	mov	dx,offset DrawColumnContentObjTemp
	mov	si,offset DrawColumnViewObjTemp
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GEN_VIEW_SET_CONTENT
	call	ObjMessage
	mov	dx,offset DrawRowContentObjTemp
	mov	si,offset DrawRowViewObjTemp
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
	pop	si					;document chunk

	;    Attach the rulers to the contents
	;

	call	DrawDocumentGetBodyGOAMRulerMemHandle
	mov	cx,bx					;ruler handle
	mov	si,dx					;RowContent chunk
	mov	dx,offset DrawRowRulerObjTemp
	mov	bp, CCO_FIRST
	mov	ax,MSG_VIS_ADD_CHILD
	call	ObjCallInstanceNoLock
	mov	si,offset DrawColumnContentObjTemp
	mov	dx, offset DrawColumnRulerObjTemp
	mov	bp, CCO_FIRST
	mov	ax,MSG_VIS_ADD_CHILD
	call	ObjCallInstanceNoLock

	.leave
	ret
DrawDocumentAttachRulerUI		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentDetachUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Document is being closed. Need to remove body
		from document.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of DrawDocumentClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Handling MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT should
		undo all of the things done by ATTACH_UI. When the document
		is saved and restored to and from state, both these
		messages are called, so the need to mirror each other
		so that the file will be connected correctly.


		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentDetachUI	method dynamic DrawDocumentClass, \
				MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	.enter

	;    Get output descriptor of GrObjBody from map block
	;

	call	DrawDocumentGetBodyGOAMRulerMemHandle
	mov	cx,bx
	mov	dx,offset DrawGrObjBodyObjTemp

	;    Notify the GrObjBody that it is about to be
	;    removed from the Document/Content and closed
	;

	push	si					;document chunk
	mov	bx,cx					;body vm memory handle
	mov	si,dx					;body chunk
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GB_DETACH_UI
	call	ObjMessage

	;    Remove the GrObjBody from the Document/Content.
	;
	;

	mov	dl, VUM_MANUAL
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_VIS_REMOVE_NON_DISCARDABLE
	call	ObjMessage
	pop	si					;document chunk

	;    Detach ruler contents from ruler view
	;    and rulers from ruler contents
	;

	call	DrawDocumentDetachRulerUI
	
	;    Have superclass do its thang
	;

	mov	ax,MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	mov	di, offset DrawDocumentClass	
	call	ObjCallSuperNoLock


	Destroy	ax,cx,dx,bp

	.leave
	ret
DrawDocumentDetachUI		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentDetachRulerUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detach the ruler contents from the ruler views and
		the rulers from the ruler contents

CALLED BY:	INTERNAL
		DrawDocumentDetachUI

PASS:		*ds:si - DrawDocument


RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		The Ruler Contents are in the same block as this 
		document object.

		The Ruler Views are in the same block as the main view, 
		which is in the same block as the display.

		The Rulers are in the same block as the graphic body.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentDetachRulerUI		proc	near
	class	DrawDocumentClass
	uses	ax,bx,cx,dx,bp,di,si
	.enter

EC <	call	ECCheckDocument					>

	;    Detach the contents from the views
	;

	push	si					;document chunk
	mov	di,ds:[si]
	add	di,ds:[di].DrawDocument_offset
	mov	bx,ds:[di].GDI_display
	clr	cx
	mov	dx,cx
	mov	si,offset DrawColumnViewObjTemp
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GEN_VIEW_SET_CONTENT
	call	ObjMessage
	mov	si,offset DrawRowViewObjTemp
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
	pop	si					;document chunk

	;    Detach the rulers from the contents
	;

	call	DrawDocumentGetBodyGOAMRulerMemHandle
	mov	cx,bx					;rulers handle
	mov	si,offset DrawRowContentObjTemp
	mov	dx,offset DrawRowRulerObjTemp
	clr	bp
	mov	ax,MSG_VIS_REMOVE_CHILD
	call	ObjCallInstanceNoLock
	mov	si,offset DrawColumnContentObjTemp
	mov	dx, offset DrawColumnRulerObjTemp
	clr	bp
	mov	ax,MSG_VIS_REMOVE_CHILD
	call	ObjCallInstanceNoLock

	.leave
	ret
DrawDocumentDetachRulerUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DrawDocumentVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	DrawDocument method for MSG_VIS_DRAW
		Subclassed to draw the grid before anything else

Called by:	

Pass:		*ds:si = DrawDocument object
		ds:di = DrawDocument instance
		bp - gstate
		cl - DrawFlags

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug  4, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentVisDraw	method dynamic	DrawDocumentClass, MSG_VIS_DRAW
	.enter

	test	cl, mask DF_PRINT
	jnz	callSuper

	mov	di, bp					;gstate

	clr	ax,dx
	call	GrSetLineWidth

	mov	ax, C_LIGHT_BLUE
	call	GrSetLineColor

	mov	al, SDM_50 or mask SDM_INVERSE
	call	GrSetLineMask

	mov	ax, MSG_VIS_RULER_DRAW_GRID
	call	MessageToRuler

	mov	ax, C_LIGHT_RED
	call	GrSetLineColor

	mov	ax, MSG_VIS_RULER_DRAW_GUIDES
	call	MessageToRuler

	call	DrawDocumentDrawMargins

callSuper:
	mov	ax, MSG_VIS_DRAW
	mov	di, offset DrawDocumentClass
	call	ObjCallSuperNoLock

	.leave
	
	Destroy	ax,cx,dx,bp

	ret
DrawDocumentVisDraw	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentDrawMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw document margins

CALLED BY:	INTERNAL
		DrawDocumentVisDraw

PASS:		*ds:si - Document
		di - gstate

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentDrawMargins		proc	near
	uses	ax,bx,cx,dx,ds,bp
	.enter

EC <	call	ECCheckDocument			>

	;    Set attributes for drawing margins
	;

	clr	ax,dx
	call	GrSetLineWidth

	mov	al,SDM_50 or mask SDM_INVERSE
	call	GrSetLineMask

	mov	ax, C_BLACK
	call	GrSetLineColor

	;    Get Document dimensions
	;

	call	DrawDocumentGetDocumentDimensions
	sub	sp, size RectDWord
	mov	bp, sp
	mov	ss:[bp].RD_right.low,cx
	mov	ss:[bp].RD_bottom.low,ax
	mov	ss:[bp].RD_right.high,dx
	mov	ss:[bp].RD_bottom.high,bx
	clr	ax
	mov	ss:[bp].RD_left.low,ax
	mov	ss:[bp].RD_left.high,ax
	mov	ss:[bp].RD_top.low,ax
	mov	ss:[bp].RD_top.high,ax

	;    Inset document dimensions by margins
	;

	call	DrawDocumentGetDocumentMargins
	add	ss:[bp].RD_left.low,ax
	mov	ax,0					;preserve carry
	adc	ss:[bp].RD_left.high,ax	
	adddw	ss:[bp].RD_top,axbx
	subdw	ss:[bp].RD_right,axcx
	subdw	ss:[bp].RD_bottom,axdx

	;    Draw that baby
	;

	segmov	ds,ss
	mov	bx,bp
	call	GrObjDraw32BitRect
	add	sp,size RectDWord

	.leave
	ret
DrawDocumentDrawMargins		endp



COMMENT @----------------------------------------------------------------------

MESSAGE:	DrawDocumentGainedTargetExcl -- MSG_META_GAINED_TARGET_EXCL
						for DrawDocumentClass

DESCRIPTION:	Handle gaining the target

PASS:
	*ds:si - instance data
	es - segment of DrawDocumentClass

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
DrawDocumentGainedTargetExcl	method dynamic	DrawDocumentClass,
						MSG_META_GAINED_TARGET_EXCL
	.enter

	mov	di, offset DrawDocumentClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_VIS_RULER_GAINED_SELECTION
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	MessageToRuler

	call	DrawDocumentUpdatePageSizeControl

	.leave
	ret
DrawDocumentGainedTargetExcl	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DrawDocumentLostTargetExcl -- MSG_META_LOST_TARGET_EXCL
						for DrawDocumentClass

DESCRIPTION:	Handle losing the target

PASS:
	*ds:si - instance data
	es - segment of DrawDocumentClass

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
DrawDocumentLostTargetExcl	method dynamic	DrawDocumentClass,
						MSG_META_LOST_TARGET_EXCL
	mov	ax, MSG_VIS_RULER_LOST_SELECTION
	call	MessageToRuler

	mov	ax, MSG_META_LOST_TARGET_EXCL
	mov	di, offset DrawDocumentClass
	GOTO	ObjCallSuperNoLock

DrawDocumentLostTargetExcl	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DrawDocumentSendClassedEvent -- MSG_META_SEND_CLASSED_EVENT
							for DrawDocumentClass

DESCRIPTION:	Pass a classed event to the right place

PASS:
	*ds:si - instance data
	es - segment of DrawDocumentClass

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
DrawDocumentSendClassedEvent	method dynamic	DrawDocumentClass,
					MSG_META_SEND_CLASSED_EVENT
	.enter

	push	ax, cx, si
	mov	bx, cx
	call	ObjGetMessageInfo		;cxsi = class
	movdw	bxdi, cxsi			;bxdi = class
	pop	ax, cx, si

	cmp	bx, segment GrObjHeadClass
	jnz	notHead
	cmp	di, offset GrObjHeadClass
	jnz	notHead

	; this message is destined for the GrObjHead

	GetResourceHandleNS	DrawGrObjHeadObj, bx
	mov	si, offset DrawGrObjHeadObj
	clr	di
	call	ObjMessage

done:
	.leave
	ret
notHead:
	;
	;	Must fix for subclasses of VisRuler
	;
	cmp	bx, segment VisRulerClass
	jnz	notRuler
	cmp	di, offset VisRulerClass
	jnz	notRuler

	; this message is destined for the ruler

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	call	MessageToRuler
	jmp	done

notRuler:

	mov	di, offset DrawDocumentClass
	call	ObjCallSuperNoLock
	jmp	done
DrawDocumentSendClassedEvent	endm
COMMENT @----------------------------------------------------------------------

MESSAGE:	DrawDocumentLoadStyleSheet --
		MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET for DrawDocumentClass

DESCRIPTION:	Load a style sheet

PASS:
	*ds:si - instance data
	es - segment of DrawDocumentClass

	ax - The message

	bp - SSCLoadStyleSheetParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/25/92		Initial version

------------------------------------------------------------------------------@
DrawDocumentLoadStyleSheet	method dynamic	DrawDocumentClass,
				MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET

	call	StyleSheetOpenFileForImport
	LONG_EC jc	done

	; bx = file handle

	; We need to get a StyleSheetParams structure from the file.

	call	VMGetMapBlock
	call	VMLock
	mov	es, ax			;es = map block
	mov	ax, es:[DMB_bodyRulerGOAM]
	call	VMUnlock

	call	VMLock
	mov	es, ax
	mov	di, offset DrawGOAMObjTemp
	mov	di, es:[di]
	add	di, es:[di].GrObjAttributeManager_offset
	mov	ax, es:[di].GOAMI_grObjStyleArrayHandle
	mov	cx, es:[di].GOAMI_areaAttrArrayHandle
	mov	dx, es:[di].GOAMI_lineAttrArrayHandle
	call	VMUnlock

	sub	sp, size StyleSheetParams
	mov	bp, sp

	mov	ss:[bp].SSP_xferStyleArray.SCD_vmFile, bx
	mov	ss:[bp].SSP_xferAttrArrays[0].SCD_vmFile, bx
	mov	ss:[bp].SSP_xferAttrArrays[(size StyleChunkDesc)].SCD_vmFile, bx

	mov	ss:[bp].SSP_xferStyleArray.SCD_chunk, VM_ELEMENT_ARRAY_CHUNK
	mov	ss:[bp].SSP_xferAttrArrays[0].SCD_chunk, VM_ELEMENT_ARRAY_CHUNK
	mov	ss:[bp].SSP_xferAttrArrays[(size StyleChunkDesc)].SCD_chunk,
							VM_ELEMENT_ARRAY_CHUNK

	mov	ss:[bp].SSP_xferStyleArray.SCD_vmBlockOrMemHandle, ax
	mov	ss:[bp].SSP_xferAttrArrays[0].SCD_vmBlockOrMemHandle, cx
	mov	ss:[bp].SSP_xferAttrArrays[(size StyleChunkDesc)].\
					SCD_vmBlockOrMemHandle, dx

	mov	ax, MSG_GOAM_LOAD_STYLE_SHEET
	mov	dx, size StyleSheetParams
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	DrawDocumentMessageToGOAM

	add	sp, size StyleSheetParams

done:
	ret
DrawDocumentLoadStyleSheet	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RedwoodPrintNotifyPrintDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_PRINT_NOTIFY_PRINT_DB
PASS:		*ds:si	= DrawDocumentClass object
		ds:di	= DrawDocumentClass instance data
		ds:bx	= DrawDocumentClass object (same as *ds:si)
		es 	= segment of DrawDocumentClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	1/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RedwoodPrintNotifyPrintDB	method dynamic DrawDocumentClass, 
					MSG_PRINT_NOTIFY_PRINT_DB
	.enter

	cmp	bp, PCS_PRINT_BOX_VISIBLE
	jne	callSuper

	;
	; save the regs for the call to the super class
	;
	push	ax, cx, dx, bp, si, es

	;
	; set up dx:bp to hold the PageSizeReport
	;
	sub	sp, size PageSizeReport
	mov	bp, sp
	mov	dx, ss

	;
	; being here means that the PrintControlbox is just about to be
	; put onto the screen.  Now we want to get the data from the
	; PageSizeControlObject.
;	GetResourceHandleNS DrawPageSizeControl, bx
;	mov	si, offset DrawPageSizeControl
;	mov	di, mask MF_CALL or mask MF_FIXUP_DS
;	mov	ax, MSG_PZC_GET_PAGE_SIZE
;	call	ObjMessage 

	push	bx

	mov	di, ds:[si]
	add	di, ds:[di].GenDocument_offset
	mov	bx, ds:[di].GDI_fileHandle

	;
	; save bp, since it points to the PageSizeReport
	;
	mov	si, bp

	call	VMGetMapBlock
	call	VMLock

	mov	es, ax
	clr	bx

	movdw	cxdx, es:[bx].DMB_width
	movdw	ss:[si].PSR_width, cxdx

	movdw	cxdx, es:[bx].DMB_height
	movdw	ss:[si].PSR_height, cxdx

	mov	cx, es:[bx].DMB_orientation.PL_label
	mov	ss:[si].PSR_layout, cx

	and	cx, not mask PLL_TYPE
	cmp	cx, PT_LABEL shl PLL_TYPE
	mov	cx, -1
	jne	notLabel

	clr	cx

notLabel:
	call	VMUnlock

	pop	bx

	;
	; check whether the page size is for label
	;
	; do it later - The info is in the DrawMapBlock
	;
;	mov	es, dx
;	mov	ax, es:[bp].PSR_layout.PL_label
;	and	ax, not mask PLL_TYPE
;	cmp	ax, PT_LABEL shl offset PLL_TYPE
;	je	isLabel

	jcxz	isLabel

	;
	; We want to reset the pagesize of the print control, to be
	; the same as the one stroed in the document
	;
	GetResourceHandleNS DrawPrintControl, bx
	mov	bp, si
	segmov	dx, ss
	mov	si, offset DrawPrintControl
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_PRINT_SET_PRINT_CONTROL_PAGE_SIZE
	call	ObjMessage 

isLabel:
	add	sp, size PageSizeReport

	;
	; restore the data from the initial call
	;
	pop	ax, cx, dx, bp, si, es

callSuper:
	mov	di, offset DrawDocumentClass
	call	ObjCallSuperNoLock	

	.leave
	ret
RedwoodPrintNotifyPrintDB	endm

DocumentCode ends

