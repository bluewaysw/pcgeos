COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Document
FILE:		documentUtils.asm

AUTHOR:		Steve Scholl

ROUTINES:
	Name	
	----	
INT DrawDocumentSetDocumentDimensions 
INT DrawDocumentGetDocumentDimensions 
INT DrawDocumentSetDocumentMargins	
INT DrawDocumentGetDocumentMargins 
INT DrawDocumentLockMapBlock		
INT DrawDocumentAllocMapBlock		

INT DrawDocumentSetBodyGOAMRulerVMBlock
INT DrawDocumentGetBodyGOAMRulerMemBlock
INT DrawDocumentSendDocumentSizeToView
INT DrawDocumentSetGrObjBodyBounds
INT DrawDocumentMessageToGrObjBody
INT DrawDocumentMessageToGOAM
INT DrawDocumentUpdatePageSizeControl		
INT DrawDocumentMessageToPageSizeControl

METHOD HANDLERS:
	Name	
	----	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/9/92		Initial revision

DESCRIPTION:

	$Id: documentUtils.asm,v 1.1 97/04/04 15:51:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DocumentCode segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentLockMapBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the documents map block

CALLED BY:	INTERNAL

PASS:		*ds:si - DrawDocument

RETURN:		
		clc - successfully locked map block
			ax - segment of map block
			bp - memory handle of map block
		stc - error
			ax,bp destroyed			

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentLockMapBlock		proc	near
	class	DrawDocumentClass
	uses	bx
	.enter

EC <	call	ECCheckDocument					>


	mov	bx,ds:[si]
	add	bx,ds:[bx].DrawDocument_offset
	mov	bx,ds:[bx].GDI_fileHandle
	call	VMGetMapBlock			

	tst	ax				;map block vm block handle
	jz	error

	call	VMLock				; lock the map block
	clc
done:
	.leave
	ret

error:
	stc
	jmp	short done
DrawDocumentLockMapBlock		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentAllocMapBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate the map block in the document vm file

CALLED BY:	INTERNAL

PASS:		*ds:si - DrawDocument object

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentAllocMapBlock		proc	near
	class	DrawDocumentClass
	uses	ax,bx,cx
	.enter

EC <	call	ECCheckDocument					>

	mov	bx,ds:[si]
	add	bx,ds:[bx].DrawDocument_offset
	mov	bx,ds:[bx].GDI_fileHandle
	mov	cx, size DrawMapBlock
	clr	ax					;VM id
	call	VMAlloc
	call	VMSetMapBlock

	.leave
	ret
DrawDocumentAllocMapBlock		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentSetDocumentDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the dimensions of the document in the map block
		Note: The width and height stored here should be 
		adjusted for the orientation. For example if the
		size is 8.5x11 but the orientation is landscape
		then you should pass 11x8.5


CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - DrawDocument

		dx:cx - 32 bit integer width
		bx:ax - 32 bit integer height
		bp - PageLayout

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentSetDocumentDimensions		proc	near
	uses	bp,es
	.enter

EC <	call	ECCheckDocument				>

	;    Lock down the map block
	;

	push	ax,bx				;height
	push	bp				;layout
	call	DrawDocumentLockMapBlock
	mov	es,ax

	;    Store width and orientation
	;

	mov	es:[DMB_width].high,dx
	mov	es:[DMB_width].low,cx
	pop	es:[DMB_orientation]

	;    Pop height into registers instead of memory to prevent
	;    passed registers from being destroyed
	;

	pop	ax,bx					;height
	mov	es:[DMB_height].high,bx
	mov	es:[DMB_height].low,ax

	;    Dirty the map block and unlock it
	;

	call	VMDirty
	call	VMUnlock

	.leave
	ret
DrawDocumentSetDocumentDimensions		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentGetDocumentDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the dimensions of the document in the document
		data block.
		Note: The width and height stored here is
		adjusted for the orientation. 
		See DrawDocumentSetDocumentDimensions


CALLED BY:	INTERNAL

PASS:		
		*ds:si - DrawDocument

RETURN:		
		dx:cx - 32 bit integer width
		bx:ax - 32 bit integer height
		bp - PageLayout

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentGetDocumentDimensions		proc	near
	uses	es
	.enter

EC <	call	ECCheckDocument				>

	call	DrawDocumentLockMapBlock
	mov	es,ax
	mov	dx,es:[DMB_width].high
	mov	cx,es:[DMB_width].low
	mov	bx,es:[DMB_height].high
	mov	ax,es:[DMB_height].low
	push	es:[DMB_orientation]
	call	VMUnlock				
	pop	bp					;orientation

	.leave
	ret
DrawDocumentGetDocumentDimensions		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentSetDocumentMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the margins in the map block

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - DrawDocument

		ax - left margin
		bx - top margin
		cx - right margin
		dx - bottom margin

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentSetDocumentMargins		proc	near
	uses	bp,es
	.enter

	push	ax,bx					;left,top
	call	DrawDocumentLockMapBlock
	mov	es,ax
	mov	es:[DMB_margins].R_right,cx
	mov	es:[DMB_margins].R_bottom,dx
	
	;    Pop left,top margin into registers instead of memory 
	;    to prevent passed registers from being destroyed
	;

	pop	ax,bx					;left, top
	mov	es:[DMB_margins].R_left,ax
	mov	es:[DMB_margins].R_top,bx

	;    Dirty and unlock map block
	;

	call	VMDirty
	call	VMUnlock


	.leave
	ret
DrawDocumentSetDocumentMargins		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentGetDocumentMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the margins in the document data block

CALLED BY:	INTERNAL

PASS:		
		*ds:si - DrawDocument

RETURN:		
		ax - left margin
		bx - top margin
		cx - right margin
		dx - bottom margin

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentGetDocumentMargins		proc	near
	uses	bp,es
	.enter

EC <	call	ECCheckDocument				>

	call	DrawDocumentLockMapBlock
	mov	es,ax
	mov	cx,es:[DMB_margins].R_right
	mov	dx,es:[DMB_margins].R_bottom
	mov	ax,es:[DMB_margins].R_left
	mov	bx,es:[DMB_margins].R_top
	call	VMUnlock				

	.leave
	ret
DrawDocumentGetDocumentMargins		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentSetBodyGOAMRulerVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set vm block handle of of the block that holds
		the GrObjBody, ObjectAttributeManager and the Rulers
		into the map block

CALLED BY:	INTERNAL

PASS:		
		*ds:si - DrawDocument
		ax - vm block handle

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	    Store the vm block handle in the map block, so we can
	    get to the objects each time the document is opened.
	    Store the vm block handle, instead of the mem handle, 
	    because the vm block handle
	    doesn't have to be relocated and urelocated.
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentSetBodyGOAMRulerVMBlock		proc	near
	uses	ax,es,bp
	.enter

EC <	call	ECCheckDocument					>

	push	ax
	call	DrawDocumentLockMapBlock
	mov	es,ax					;seg map block
	pop	es:[DMB_bodyRulerGOAM]
	call	VMUnlock				;unlock map block

	.leave
	ret
DrawDocumentSetBodyGOAMRulerVMBlock	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentGetBodyGOAMRulerMemHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the vm memory handle of the block which
		contains the GrObjBody, ObjectAttributeManager and
		Rulers from the map block

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - DrawDocument

RETURN:		
		bx - vm mem block handle

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentGetBodyGOAMRulerMemHandle		proc	near

	class	DrawDocumentClass
	uses	ax,es,bp
	.enter

EC <	call	ECCheckDocument					>

	call	DrawDocumentLockMapBlock
	mov	es,ax					;seg map block
	mov	ax,es:[DMB_bodyRulerGOAM]
	call	VMUnlock				;unlock map block

	mov	bx,ds:[si]
	add	bx,ds:[bx].DrawDocument_offset
	mov	bx,ds:[bx].GDI_fileHandle
	call	VMVMBlockToMemBlock
	mov	bx,ax					;body mem handle

	.leave
	ret
DrawDocumentGetBodyGOAMRulerMemHandle		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentSetGrObjBodyBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the bounds of the GrObjBody from the data
		stored in the map block

CALLED BY:	INTERNAL (UTILITY)

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
DrawDocumentSetGrObjBodyBounds		proc	far
	uses	ax,bx,cx,dx,di,bp
	.enter

EC <	call	ECCheckDocument					>

	call	DrawDocumentGetDocumentDimensions

	;    Create stack frame for setting of document bounds
	;

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
	mov	dx,size RectDWord
	mov	di,mask MF_FIXUP_DS or mask MF_STACK
	mov	ax,MSG_GB_SET_BOUNDS
	call	DrawDocumentMessageToGrObjBody
	add	sp,size RectDWord

	.leave
	ret
DrawDocumentSetGrObjBodyBounds		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentMessageToGrObjBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the GrObjBody

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - DrawDocument
		ax - message
		cx,dx,bp - message data
		di - MessageFlags

RETURN:		
		if MF_CALL
			ax,cx,dx,bp

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentMessageToGrObjBody		proc	near
	uses	bx,di,si
	.enter

	call	DrawDocumentGetBodyGOAMRulerMemHandle		
	mov	si,offset DrawGrObjBodyObjTemp
	ornf	di,mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
DrawDocumentMessageToGrObjBody		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentMessageToGOAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the GOAM

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - DrawDocument
		ax - message
		cx,dx,bp - message data
		di - MessageFlags

RETURN:		
		if MF_CALL
			ax,cx,dx,bp

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentMessageToGOAM		proc	near
	uses	bx,di,si
	.enter

	call	DrawDocumentGetBodyGOAMRulerMemHandle		
	mov	si,offset DrawGOAMObjTemp
	ornf	di,mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
DrawDocumentMessageToGOAM		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentSendDocumentSizeToView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the document size stored in the map block
		to the view

CALLED BY:	INTERNAL
		DrawDocumentChangeDocSize

PASS:		
		*ds:si - DrawDocument

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentSendDocumentSizeToView		proc	near
	uses	ax,bx,cx,dx,bp,di,si
	class	DrawDocumentClass
	.enter

EC <	call	ECCheckDocument				>

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

	;    The view od in the content may not have been set
	;    yet, so we can't use it. However, the
	;    view is in the same block as the display, and
	;    we know the view offset since it was created
	;    by duplicating a template
	;

	mov	di,ds:[si]
	add	di,ds:[di].DrawDocument_offset
	mov	bx,ds:[di].GDI_display
	mov	si,offset DrawMainViewObjTemp
	mov	dx, size RectDWord
	mov	ax, MSG_GEN_VIEW_SET_DOC_BOUNDS
	mov	di, mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
	call	ObjMessage

	add	sp, size RectDWord

	.leave
	ret
DrawDocumentSendDocumentSizeToView		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentUpdatePageSizeControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the PageSizeControl with information about
		this document

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - document

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
	srs	8/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentUpdatePageSizeControl		proc	far
	uses	ax,bx,cx,dx,bp,di
	.enter

EC <	call	ECCheckDocument				>

	call	DrawDocumentGetDocumentDimensions
	mov	di,bp					;PageLayout

	sub	sp,size PageSizeReport
	mov	bp,sp
	movdw	ss:[bp].PSR_width,dxcx
	movdw	ss:[bp].PSR_height,bxax
	mov	ss:[bp].PSR_layout,di
	call	DrawDocumentGetDocumentMargins
	mov	ss:[bp].PSR_margins.PCMP_left,ax
	mov	ss:[bp].PSR_margins.PCMP_top,bx
	mov	ss:[bp].PSR_margins.PCMP_right,cx
	mov	ss:[bp].PSR_margins.PCMP_bottom,dx
	mov	di,mask MF_FIXUP_DS or mask MF_CALL	;its across threads
							;and we have stuff
							;on stack so use MF_CALL
	mov	dx,ss
	mov	ax,MSG_PZC_SET_PAGE_SIZE
	call	DrawDocumentMessageToPageSizeControl
	add	sp,size PageSizeReport

	.leave
	ret
DrawDocumentUpdatePageSizeControl		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentMessageToPageSizeControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the DrawPageSizeControl

CALLED BY:	INTERNAL UTILITY

PASS:		
		ax - message
		cx,dx,bp - other data
		di - MessageFlags

RETURN:		
		if MF_CALL
			ax,cx,dx,bp - from message

DESTROYED:	
		ax,cx,dx,bp - if not returned

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentMessageToPageSizeControl		proc	near
	uses	bx,si
	.enter

	GetResourceHandleNS	DrawPageSizeControl,bx
	mov	si,offset DrawPageSizeControl
	call	ObjMessage

	.leave
	ret
DrawDocumentMessageToPageSizeControl		endp








DocumentCode ends






if	0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawAdjustDocumentDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Older draw documents had a document data block that was
		too small. So increase the size of the document data
		block if this is the case and set the orientation
		fields correctly.

CALLED BY:	DrawDocumentOpen

PASS:		
		*ds:si - document instance data
		vm override file set

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	In old draw documents the document data block will have been
	alloced to a page boundary and zeroed. So if orientationValid
	(which lies outside the original data structure, but within the
	zero area after the data structure and before the page boundary)
	is zero then it is an old document. 

	When the old documents were created, all of the document size
	options were taller than they were wide. So setting the page
	orientation field in the new data structure can be done based
	on a comparison of the document width and height.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawAdjustDocumentDataBlock		proc	near
	uses	ax,bx,cx,dx,bp,es
	.enter

	; Determine if the document data block is in need of adjustment

	call	DrawLoadMapBlock		;dx - vm block of doc data
EC <	ERROR_C	ERROR_MISSING_MAP_BLOCK	>	
	mov	ax,dx
	call	VMLock
	mov	es,ax
	tst	es:[DMB_orientationValid]
	jnz	unlock				;jmp if doc data block ok

	call	VMDirty				;dirty doc data block

	; Adjust size of document data block

	mov	bx,bp				;mem handle of doc data
	mov	ax, size DrawDocData
	mov	ch, mask HAF_NO_ERR
	call	MemReAlloc
	mov	es,ax				;in case block moved

	; Set orientation and orientationValid field 

	call	DrawGetDocDimensionsAndBody
EC <	ERROR_C	ERROR_MISSING_MAP_BLOCK	>	
	mov	al,PO_PORTRAIT			;assume
	cmp	bp,dx				;width to height
	jle	10$				;jmp if portrait
	mov	al,PO_LANDSCAPE
10$:
	mov	es:[DMB_orientation],al
	mov	es:[DMB_orientationValid],1
	mov	bp,bx				;doc data handle
unlock:
	call	VMUnlock			;doc data block

	.leave
	ret
DrawAdjustDocumentDataBlock		endp

endif

