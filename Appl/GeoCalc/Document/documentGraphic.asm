COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		documentGraphic.asm

AUTHOR:		Chris Boyke

ROUTINES:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 8/91	Initial version.

DESCRIPTION:
	This file contains utility routines and new methods defined
	for use with the Graphic Layer.  Modifications of existing
	GenDocument methods are to be found in documentNew.asm and
	documentClass.asm
  
	

	$Id: documentGraphic.asm,v 1.2 97/04/15 15:49:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Document	segment resource

if _CHARTS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentCreateGrObjBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a graphic body object and add it to the file's 
		map block. The block duplicated also contains the
		attribute manager

CALLED BY:	
		
PASS:		bx - VM file handle
		
RETURN:		ax - VM block handle of graphic body block

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
		nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/28/90		Initial version
	cdb	11/8/91		Copied here from draw

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentCreateGrObjBody	proc	near
	uses	cx,si,di,es
	.enter

	push	bx				; VM file handle

	;
	; Duplicate body resource
	;

	GetResourceHandleNS GrObjBodyUI, bx
	clr	ax				; have current geode own block
	mov	cx, -1				; copy running thread from
						;	template block
	call	ObjDuplicateResource
	;
	; Attach body's block to vm file
	;
	mov	cx, bx				;body handle
	pop	bx				; VM file handle
	clr	ax				;create new vm block 
	call	VMAttach
	;
	; Preserve the body's block handle. This guarantees
	; that the mem handle created from the vm handle
	; will always be valid. Otherwise I couldn't send
	; messages to the body
	;

	call	VMPreserveBlocksHandle
	;
	; Save the VM handle of the graphic body block for later
	;
	push	ax				;save VM handle
	call	DBLockMap
	mov	di, es:[di]			;es:di <- ptr to map
	pop	ax				;ax <- VM handle of body
	mov	es:[di].CMB_grObjBody, ax	;save VM handle in map
	call	DBDirty
	call	DBUnlock

	.leave
	ret
GeoCalcDocumentCreateGrObjBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentInitGrObjBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize GrObjBody. Set bounds. Also have
		attribute manager create its arrays
		

CALLED BY:	INTERNAL
	
PASS:		bx - VM file handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 6/91		Initial version
	cdb	11/8/91		Modified for GeoCalc
	srs	2/9/92		Added OAM initialization

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentInitGrObjBody		proc	near
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	sub	sp, size RectDWord
	mov	bp,sp

	;
	;    Pass dimensions as rectangle 0,0,width,height
	;	NOTE: we really ought to get this information
	;	from the spreadsheet somehow, but it ain't worth
	;	it...
	;
	movdw	ss:[bp].RD_right, GEOCALC_NUM_COLUMNS*64
	movdw	ss:[bp].RD_bottom, GEOCALC_NUM_ROWS*15
	clr	ax
	clrdw	ss:[bp].RD_left, ax
	clrdw	ss:[bp].RD_top, ax
	;
	;    Send  message to the graphic body
	;
	mov	dx, size RectDWord
	mov 	di, mask MF_FIXUP_DS or mask MF_STACK
	mov	ax,MSG_GB_SET_BOUNDS
	call	SendToGrObjBody

	add	sp,size RectDWord

	;    Have attribute manager create attribute arrays it needs
	;

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GOAM_CREATE_ALL_ARRAYS
	call	SendToOAM

	.leave
	ret
GeoCalcDocumentInitGrObjBody		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToGrObjBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the graphic body

CALLED BY:	INTERNAL

PASS:		*ds:si - instance data of Document Object
		ax,cx,dx,bp,di - message data

RETURN:		ax,cx,dx,bp - modified by Graphic Body method

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 8/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToGrObjBody	proc near	
	uses bx,si
	.enter
	call	GetGrObjBodyOD
	mov	si, offset GrObjBodyObject
	call	ObjMessage
	.leave
	ret
SendToGrObjBody	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToOAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the object attribute manager

CALLED BY:	INTERNAL

PASS:		*ds:si - instance data of Document Object
		ax,cx,dx,bp,di - message data

RETURN:		ax,cx,dx,bp - modified by  OAM method

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 8/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToOAM	proc near	
	uses bx,si
	.enter
	call	GetGrObjBodyOD
	mov	si, offset OAMObject
	call	ObjMessage
	.leave
	ret
SendToOAM	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentAddBodyToDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Visually add body as child of Document object

CALLED BY:	INTERNAL
		GeoCalcDocumentAttachUI

PASS:		
		*(ds:si) - document
		bx - handle of body

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
GeoCalcDocumentAddBodyToDocument		proc	near
	uses	ax,cx,dx,bp
	.enter
EC <	call	ECGeoCalcDocument			>

	mov	cx, bx				;body handle
	mov	dx, offset GrObjBodyObject	;body offset
	mov	bp, CCO_LAST shl offset CCF_REFERENCE
	mov	ax, MSG_VIS_ADD_NON_DISCARDABLE_VM_CHILD
	call	ObjCallInstanceNoLock

	;;call	GeoCalcDocumentSetBodyDocBounds

	.leave
	ret
GeoCalcDocumentAddBodyToDocument		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentRemoveBodyFromDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Visually remove body as child of Document object

CALLED BY:	INTERNAL
		GeoCalcDocumentDetachUI

PASS:		
		*(ds:si) - document
		bx - handle of body

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	Send GB_DETACH_UI message BEFORE removing body from parent.
	This is because GB_DETACH_UI needs to communicate to its
	parent re:  releasing target/focus.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 6/91		Initial version
	cdb	11/91		changed for GeoCalc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentRemoveBodyFromDocument		proc	near
	uses	ax,cx,dx,bp
	.enter
EC <	call	ECGeoCalcDocument			> 

	push	si					;document chunk
	mov	si, offset GrObjBodyObject
	mov	ax, MSG_GB_DETACH_UI
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si					;document chunk

	mov	ax, MSG_VIS_REMOVE_NON_DISCARDABLE
	mov	dl, VUM_MANUAL
	mov	di, mask MF_FIXUP_DS
	call	SendToGrObjBody
	
	.leave
	ret
GeoCalcDocumentRemoveBodyFromDocument		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetGrObjBodyOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the OD of the graphic body for this document

CALLED BY:

PASS:		*ds:si - GeoCalcDocument object

RETURN:		^lbx:si - Graphic Body object

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/26/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetGrObjBodyOD	proc far
	uses	ax,cx,di,es
	class	GeoCalcDocumentClass
	.enter
EC <	call	ECGeoCalcDocument			> 
	
	call	GetSpreadsheetFile		;bx <- spreadsheet file handle
	call	DBLockMap
	mov	di, es:[di]			;es:di <- ptr to map block
	mov	ax, es:[di].CMB_grObjBody	;ax <- VM handle of body
	tst	ax
	jz	noBody				;no branch in common case
haveBody:
	call	DBUnlock

	call	VMVMBlockToMemBlock
	mov	bx,ax					;body mem handle
	mov	si, offset GrObjBodyObject
	.leave
	ret
noBody:
	call	GeoCalcDocumentCreateGrObjBody
	jmp	haveBody

GetGrObjBodyOD	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECGeoCalcDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see that *ds:si points to a the correct object

CALLED BY:

PASS:		*ds:si - an object of GeoCalcDocumentClass (we hope!)

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/11/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK

ECGeoCalcDocument	proc far
	uses es,di
	.enter
	pushf
	mov	di, offset GeoCalcDocumentClass
	GetResourceSegmentNS GeoCalcDocumentClass, es
	call	ObjIsObjectInClass
	ERROR_NC DS_SI_NOT_POINTING_TO_GRAPHIC_DOCUMENT_OBJECT
	popf
	.leave
	ret
ECGeoCalcDocument	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentTrackScrolling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Send the TRACK_SCROLLING message to the spreadsheet,
		regardless of which layer is the target.

PASS:		*ds:si	= GeoCalcDocumentClassClass object
		ds:di	= GeoCalcDocumentClassClass instance data
		es	= Segment of GeoCalcDocumentClassClass.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/12/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocumentTrackScrolling	method	dynamic GeoCalcDocumentClass, 
					MSG_META_CONTENT_TRACK_SCROLLING
	mov	di, mask MF_CALL
	call	SendToDocSpreadsheet
	ret
GeoCalcDocumentTrackScrolling	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcViewSizeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	View resize handler
CALLED BY:	MSG_META_CONTENT_VIEW_SIZE_CHANGED

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the method

		cx - width
		dx - height
		bp - handle of Window

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcViewSizeChanged	method dynamic GeoCalcDocumentClass, \
					MSG_META_CONTENT_VIEW_SIZE_CHANGED

	mov	di, offset GeoCalcDocumentClass
	call	ObjCallSuperNoLock

	;
	; Ask the spreadsheet to tell us its bounds
	;
	sub	sp, size RectDWord
	mov	cx, ss
	mov	dx, sp				;ss:bp <- ptr to 
	mov	ax, MSG_VIS_LAYER_GET_DOC_BOUNDS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	SendToDocSpreadsheet

	;
	; Now update them, in our instance data, in the grobj body,
	; and in the view
	;
	mov	bp, sp
	mov	ax, MSG_VIS_CONTENT_SET_DOC_BOUNDS
	call	ObjCallInstanceNoLock

	add	sp, (size RectDWord)

	ret	
GeoCalcViewSizeChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentSetDocBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the document bounds. Update the grobj and the view
		appropriately

PASS:		*ds:si	= GeoCalcDocumentClass object
		ds:di	= GeoCalcDocumentClass instance data
		es	= Segment of GeoCalcDocumentClass.
		ss:bp 	= RectDWord containing bounds

RETURN:		nothing 

DESTROYED:	bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/18/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocumentSetDocBounds	method	GeoCalcDocumentClass,
					MSG_VIS_CONTENT_SET_DOC_BOUNDS

 	add	di, offset GCDI_bounds		;ds:di <- ptr to dest
 	mov	cx, size RectDWord/2
 	call	CopyWordsFromStack
if _CHARTS
	;
	; Send the info to the grobj, but clear out the upper
	; left-hand corner
	;
	pushdw	ss:[bp].RD_left
	pushdw	ss:[bp].RD_top
	clrdw	ss:[bp].RD_left
	clrdw	ss:[bp].RD_top
		
	mov	ax, MSG_VIS_LAYER_SET_DOC_BOUNDS
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	mov	dx, size RectDWord
	call	SendToGrObjBody

	popdw	ss:[bp].RD_top
	popdw	ss:[bp].RD_left
endif
	;
	; Tell the view about the change
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisContent_offset
	mov	ax, ds:[di].VCNI_viewWidth	;ax <- view width
	mov	bx, ds:[di].VCNI_viewHeight	;bx <- view height
	call	SetViewDocSize

	
	.leave
	ret
GeoCalcDocumentSetDocBounds	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetViewDocSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the view's document size / scrollable area
CALLED BY:	GeoCalcDocumentSetDocBounds()

PASS:		*ds:si - GeoCalcDocument object
		ss:bp - size of spreadsheet (RectDWord)
		(ax,bx) - (width,height) of view
RETURN:		ss:bp - new view document size / scrollable area (RectDWord)
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/18/91	Initial version.
	eca	7/ 9/92		broke out from GeoCalcDocumentSetDocBounds()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetViewDocSize	proc	near
	class	GeoCalcDocumentClass
	.enter

	;
	; Add view width, height to passed rectangle
	;
	clr	cx				
	adddw	ss:[bp].RD_right, cxax
	adddw	ss:[bp].RD_bottom, cxbx
	;
	; Set this is as the scrollable document area
	;
	mov	dx, (size RectDWord)
	mov	di, ds:[si]
	add	di, ds:[di].VisContent_offset
	push	si, bp
	mov	ax, MSG_GEN_VIEW_SET_DOC_BOUNDS
	mov	bx, ds:[di].VCNI_view.handle
	mov	si, ds:[di].VCNI_view.chunk
	mov	di, mask MF_STACK or mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si, bp

	.leave
	ret
SetViewDocSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw the mystery gray areas and then both layers...

PASS:		*ds:si	= GeoCalcDocumentClass object
		ds:di	= GeoCalcDocumentClass instance data
		es	= Segment of GeoCalcDocumentClass.
		bp 	= gstate handle

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/19/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GeoCalcDocumentDraw	method	dynamic	GeoCalcDocumentClass, MSG_VIS_DRAW
	.enter

	; Draw mystery gray area

	push	ax,cx,dx
	call	DrawRightGrayArea
	call	DrawBottomGrayArea
	pop	ax,cx,dx

	; draw children
	call	VisSendToChildren

	; Send inversion message to the spreadsheet.
	mov	ax, MSG_SPREADSHEET_INVERT_RANGE_LAST
	call	VisCallFirstChild		; Spreadsheet is always
						; the first child
	.leave
	ret
GeoCalcDocumentDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentDrawRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw a range based on the passed gstate

PASS:		*ds:si	- GeoCalcDocumentClass object
		ds:di	- GeoCalcDocumentClass instance data
		es	- segment of GeoCalcDocumentClass
		bp	- gstate through which to draw

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/30/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocumentDrawRange	method	dynamic	GeoCalcDocumentClass, 
					MSG_GEOCALC_DOCUMENT_DRAW_RANGE

gstate		local	hptr	push	bp
drawFlags	local	word	push	cx
ssDrawParams	local	SpreadsheetDrawParams
rangeBounds	local	RectDWord
ife _CHARTS
		ForceRef	drawFlags				
endif		
		.enter

	; Draw mystery gray area

		push	bp
		mov	bp, ss:[gstate]
		call	DrawRightGrayArea
		call	DrawBottomGrayArea
		pop	bp
		
	;	
	; Draw spreadsheet, but only the range specified
	;
		mov	di, ss:[gstate]
		mov	ss:[ssDrawParams].SDP_gstate, di

		push	ds, si
		segmov	ds, ss
		lea	si, ss:[ssDrawParams].SDP_drawArea
		call	GrGetWinBoundsDWord
		pop	ds, si


	;
	; Ask the spreadsheet what the upper left-hand cell is based on
	; the passed window bounds
	;
		mov	ax, MSG_SPREADSHEET_GET_ROW_AT_POSITION
		movdw	dxcx, ss:[ssDrawParams].SDP_drawArea.RD_top
		incdw	dxcx		; last-minute hack
		call	callSpreadsheet

		mov	ss:[ssDrawParams].SDP_topLeft.CR_row, ax
		mov	ss:[ssDrawParams].SDP_limit.CR_start.CR_row, ax

		mov	ax, MSG_SPREADSHEET_GET_COLUMN_AT_POSITION
		movdw	dxcx, ss:[ssDrawParams].SDP_drawArea.RD_left
		incdw	dxcx		; last-minute hack
		call	callSpreadsheet

		mov	ss:[ssDrawParams].SDP_topLeft.CR_column, ax
		mov	ss:[ssDrawParams].SDP_limit.CR_start.CR_column, ax


	;
	; Now, we also need the bottom-right cell, since we'll
	; need the draw area to be INCLUSIVE
	;
		mov	ax, MSG_SPREADSHEET_GET_ROW_AT_POSITION
		movdw	dxcx, ss:[ssDrawParams].SDP_drawArea.RD_bottom
		call	callSpreadsheet

		mov	ss:[ssDrawParams].SDP_limit.CR_end.CR_row, ax

		mov	ax, MSG_SPREADSHEET_GET_COLUMN_AT_POSITION
		movdw	dxcx, ss:[ssDrawParams].SDP_drawArea.RD_right
		call	callSpreadsheet

		mov	ss:[ssDrawParams].SDP_limit.CR_end.CR_column, ax

		mov	ax, MSG_SPREADSHEET_GET_RANGE_BOUNDS
		push	bp
		mov	dx, ss
		lea	cx, ss:[rangeBounds]
		lea	bp, ss:[ssDrawParams].SDP_limit
		call	callSpreadsheet
		pop	bp


		movdw	bxax, ss:[rangeBounds].RD_right
		movdw	ss:[ssDrawParams].SDP_drawArea.RD_right, bxax

		movdw	bxax, ss:[rangeBounds].RD_bottom
		movdw	ss:[ssDrawParams].SDP_drawArea.RD_bottom, bxax

		push	bp
		mov	ax, MSG_SPREADSHEET_GET_DRAW_FLAGS
		call	callSpreadsheet
		andnf	dx, mask SPF_PRINT_GRID 
		ornf	dx, mask SPF_PRINT_TO_SCREEN
		pop	bp
		mov	ss:[ssDrawParams].SDP_printFlags, dx 

		clr	ss:[ssDrawParams].SDP_margins.P_x
		clr	ss:[ssDrawParams].SDP_margins.P_y
	;
	; Decrement the top left range, since we don't want the border
	; drawn up there
	;

		decdw	ss:[ssDrawParams].SDP_drawArea.RD_top
		decdw	ss:[ssDrawParams].SDP_drawArea.RD_left

		push	bp
		lea	bp, ss:[ssDrawParams]
		mov	ax, MSG_SPREADSHEET_DRAW_RANGE
		call	callSpreadsheet
		pop	bp

if _CHARTS
		push	bp
		mov	ax, MSG_VIS_DRAW
		mov	cx, ss:[drawFlags]
		mov	bp, ss:[gstate]
		mov	di, mask MF_FIXUP_DS
		call	SendToGrObjBody
		pop	bp
endif		
		.leave
		ret

callSpreadsheet:
		push	bp
		call	VisCallFirstChild
		pop	bp
		retn
GeoCalcDocumentDrawRange	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyWordsFromStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy some words of memory off of a stack frame

CALLED BY:	GeoCalcDocumentDraw

PASS:		ds:di - destination
		ss:bp - source
		cx - number of words to copy

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	
	rep movsw is 25 cycles per word, vs. at least 50, 60 cycles
	using any other method.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/19/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyWordsFromStack	proc near	
	uses	es, si
	.enter
	segmov	es, ds, ax		; store (old DS) in AX
	segmov	ds, ss, si
	mov	si, bp
	rep	movsw
	mov	ds, ax
	.leave
	ret
CopyWordsFromStack	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the document grid, if appropriate

CALLED BY:	GeoCalcDocumentDraw

PASS:		*ds:si - GeoCalcDocument object
		bp - gstate handle

RETURN:		nothing

DESTROYED:	This routine sets the line color of the passed GState,
		which goes unchanged through the cell drawing. If re-instated,
		this routine should fix up the line color.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	4 aug 1992	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
DrawGrid	proc	near
	class	GeoCalcDocumentClass
	uses	di, si, bx, es
	.enter	

	mov	di, bp
	mov	ax, C_LIGHT_BLUE
	call	GrSetLineColor

	mov	ax, MSG_VIS_RULER_DRAW_GRID
	call	MessageToRuler

	mov	ax, C_LIGHT_RED
	call	GrSetLineColor

	mov	ax, MSG_VIS_RULER_DRAW_GUIDES
	call	MessageToRuler

	.leave
	ret
DrawGrid	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRightGrayArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw gray area to right of spreadsheet, if appropriate

CALLED BY:	GeoCalcDocumentDraw

PASS:		*ds:si - GeoCalcDocument object
		bp - gstate handle

RETURN:		di - gstate handle

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
	Translate the gstate to the right edge of the document and
	draw height and width of window

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/21/91		Initial version
	cdb	11/19/91	Moved here from spreadsheet


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawRightGrayArea	proc	near
	class	GeoCalcDocumentClass
	uses	ds, si
	.enter	


	; Get right edge of document	 x-coord
	mov	di, ds:[si]
	add	di, ds:[di].GeoCalcDocument_offset
	movdw	dxcx, ds:[di].GCDI_bounds.RD_right


	; Fetch the window's offset onto the document
	;

	sub	sp, size RectDWord
	mov	si, sp
	segmov	ds, ss, ax
	mov	di, bp
	call	GrGetWinBoundsDWord

	; Trivial reject if right edge of doc > right edge of window

	jgdw	dxcx,	ds:[si].RD_right, done

	; y-offset is window's top bound:

	movdw	bxax, ds:[si].RD_top
	call	FillGrayRect
done:
	add	sp, size RectDWord
	.leave
	ret

DrawRightGrayArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBottomGrayArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw gray area on bottom of spreadsheet, if appropriate
CALLED BY:	RangeDraw()

PASS:		*ds:si - GeoCalcDocument object

RETURN:		di - gstate handle

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
	Only draw area UNDERNEATH spreadsheet

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/21/91		Initial version
	cdb	11/91		Moved here from spreadsheet lib.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawBottomGrayArea	proc	near
	class	GeoCalcDocumentClass
	uses	ds,si
	.enter	
	
	; y-translation is bottom of doc
	mov	di, ds:[si]
	add	di, ds:[di].GeoCalcDocument_offset
	movdw	bxax, ds:[di].GCDI_bounds.RD_bottom

	; Fetch the window's offset onto the document
	;
	sub	sp, size RectDWord
	mov	si, sp
	segmov	ds, ss, cx
	mov	di, bp
	call	GrGetWinBoundsDWord

	; Trivial reject if bottom edge of doc > bottom edge of window
	jgdw	bxax, ds:[si].RD_bottom, done

	; x-offset is window's left bound:

	movdw	dxcx, ds:[si].RD_left
	call	FillGrayRect
done:
	add	sp, size RectDWord
	.leave
	ret
DrawBottomGrayArea	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillGrayRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a gray rectangle

CALLED BY:	DrawRightGrayArea, DrawBottomGrayArea

PASS:		di - gstate handle
		dx:cx, bx:ax - upper left-hand corner of rectangle
			(dwords)
		ds:si - RectDWord of window's bounds in document
		coordinates. 

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	
	Draw a rectangle as big as the view window.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/19/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillGrayRect	proc near	
	.enter

	call	GrSaveState
	call	GrApplyTranslationDWord


	movdw	axcx, ds:[si].RD_right
	subdw	axcx, ds:[si].RD_left
	js	done
	ECMakeSureZero	ax			; cx = width

	movdw	bxdx, ds:[si].RD_bottom
	subdw	bxdx, ds:[si].RD_top		; dx = height
	js	done
	ECMakeSureZero	bx

	; Draw the rectangle
	;
	mov	al, MM_COPY
	call	GrSetMixMode
	mov	al, SDM_50			;al <- SysDrawMask
	call	GrSetAreaMask
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor

	clr	ax

	; Make the rectangle just a liiitttllleee bigger

	inc	cx
	inc	cx
	inc	dx
	inc	dx
	call	GrFillRect
done:
	call	GrRestoreState

	.leave
	ret
FillGrayRect	endp


if _CHARTS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentSetTargetBasedOnTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the target based on the tool, if possible
CALLED BY:	MSG_GEOCALC_DOCUMENT_SET_TARGET_BASED_ON_TOOL

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
	eca	6/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentSetTargetBasedOnTool	method dynamic GeoCalcDocumentClass, \
				MSG_GEOCALC_DOCUMENT_SET_TARGET_BASED_ON_TOOL
	call	IsPtrTool
	;
	; set the target based on the current tool
	; Our children are:
	;	#0 - spreadsheet
	;	#1 - graphics layer
	;
	jcxz	quit				;branch if spreadsheet/ptr
	push	cx
	mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock
	movdw	bxsi, cxdx			;^lbx:si <- cx-th child
	pop	cx				;cl <- GeoCalcTargetLayer
	;
	; Tell the cx-th child to grab the focus and target
	;
CheckHack <GCTL_SPREADSHEET eq 0>
CheckHack <GCTL_GROBJ eq 1>
	call	SetTargetLayerOpt
quit:
	ret
GeoCalcDocumentSetTargetBasedOnTool	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsPtrTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the current tool is the pointer

CALLED BY:	GeoCalcDocumentSetTargetBasedOnTool()
PASS:		none
RETURN:		z flag - set (jz) if pointer tool
		cx - 0 if spreadsheet/pointer tool
		   - 1 if graphics tool
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsPtrTool		proc	near
	uses	ax, bx, dx, si, di, bp
	.enter

	GetResourceHandleNS GCGrObjHead, bx
	mov	si, offset GCGrObjHead
	mov	ax, MSG_GH_GET_CURRENT_TOOL
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	cmp	cx, segment PointerClass
	mov	cx, 0				;cx <- assme spreadsheet (#0)
	jne	notPtr
	cmp	dx, offset PointerClass
	je	isPtr
notPtr:
	inc	cx				;cx <- graphics layer (#1)
isPtr:
	tst	cx				;set Z flag for spreadsheet/ptr

	.leave
	ret
IsPtrTool		endp

endif

if _CHARTS and FALSE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeocalcDocumentInvalidateLockedAreas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A grobj has been modified. If the document has split views
		the grobj may lie partially in a locked area, and we must
		invalidate all locked areas so that it will be completely
		redrawn.

CALLED BY:	MSG_GEOCALC_DOCUMENT_INVALIDATE_LOCKED_AREAS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/17/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentInvalidateLockedAreas	method dynamic GeoCalcDocumentClass,
				MSG_GEOCALC_DOCUMENT_INVALIDATE_LOCKED_AREAS,
				MSG_GROBJ_ACTION_NOTIFICATION

		test	ds:[di].GCDI_flags, mask GCDF_SPLIT
		jnz	invalidate
		ret

invalidate:
		mov	bx, ds:[di].GCDI_spreadsheet	
		mov	si, offset MidLeftContent
		call	sendInvalMsg

		mov	si, offset MidRightContent
		call	sendInvalMsg

		mov	si, offset BottomLeftContent
		call	sendInvalMsg
		ret
;;-----
		
sendInvalMsg:
		mov	ax, MSG_VIS_INVALIDATE
		clr	di
		call	ObjMessage
		retn
		
GeoCalcDocumentInvalidateLockedAreas		endm

endif

Document	ends

