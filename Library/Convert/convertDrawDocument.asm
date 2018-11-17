COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Convert
FILE:		convertDrawDocument.asm

AUTHOR:		Jon Witort, September 2, 1992

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jon		2 sept 1992	initial revision

DESCRIPTION:
	$Id: convertDrawDocument.asm,v 1.1 97/04/04 17:52:35 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include grobj.def

ConvertDrawDocumentCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertDrawDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Routine for converting a 1.X draw document -> 2.0 draw
		document. This procedure was adapted (copied) from the
		DrawDocumentClass handler for
		MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT

Pass:		*ds:si = DrawDocument object
		cx - GrObjBody chunk within 2.0 GeoDraw document

Return:		carry set on error

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	?user	?date 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertDrawDocument proc	far
	class	GenDocumentClass
	uses	ax, bx, cx, dx, di, si, bp, es, ds
	.enter

	;
	;  Fetch and preserve file handle
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].GenDocument_offset
	mov	bx, ds:[di].GDI_fileHandle
	push	bx					;save vm file

	xchg	bx, si
	call	ConvertGetVMBlockList			;ax = block list
	xchg	bx, si
	push	ax
	push	bx					;save vm file handle

	;
	;  Turn off undo actions
	;
	call	DrawUndoIgnoreActions

	;
	;  Suck out the old map block so we can locate the old body
	;
	call	VMGetMapBlock
	call	VMLock
	mov	es, ax					;es <- DrawDocMap1X

	mov	ax, es:[DDM_1X_documentData]
	push	es:[DDM_1X_bodyBlock]			;save body block
	push	cx					;save new body chunk
	mov	cx, bp					;^hcx <- DrawDocMap1X
	call	VMLock

	mov	es, ax					;es <- DrawDocData1X
	mov	al, es:[DDD_1X_orientation]
	push	ax					;save orientation
	push	es:[DDD_1X_size].XYS_1X_width		;save width
	push	es:[DDD_1X_size].XYS_1X_height		;save height

	call	VMUnlock				;unlock DrawDocData1X
	mov	bp, cx					;^hbp <- DrawDocMap1X
	call	VMUnlock				;unlock DrawDocMap1X
	
	;
	;  Create all our nifty new objects
	;
	mov	ax, MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE
	call	ObjCallInstanceNoLock

	call	VMGetMapBlock				;ax <- new map block
	call	VMLock
	mov	es, ax					;es <- DrawMapBlock
	clr	ax
	pop	es:[DMB_height].low
	mov	es:[DMB_height].high, ax
	pop	es:[DMB_width].low
	mov	es:[DMB_width].high, ax

	;
	;  We'll assume the PageLayout is a PageLayoutPaper
	;
	pop	ax					;ax <- orientation
	clr	ah

	rept	offset PLP_ORIENTATION
	shl	ax
	endm

	ornf	ax, PT_PAPER shl offset PLP_TYPE
	mov	es:[DMB_orientation], ax
	mov	ax, es:[DMB_bodyRulerGOAM]		;ax <- brg block handle
	call	VMUnlock

	call	VMLock
	mov	ds, ax
	pop	si					;*ds:si <- new body
	pop	ax					;ax <- old body block
	push	bp					;save handle for unlock
	call	VMLock
	mov	es, ax
	mov	di, OLD_BODY_CHUNK_HANDLE		;*es:di <- old body
	mov	di, es:[di]
	add	di, es:[di+OLD_VIS_MASTER_CLASS_OFFSET]
	mov	cx, es:[di+OLD_VCI_FIRST_CHILD_OFFSET].handle
	mov	di, es:[di+OLD_VCI_FIRST_CHILD_OFFSET].chunk
	call	VMUnlock

	pop	bx					;bx <- handle to unlock
	pop	ax					;ax <- vm file handle
	call	DrawDocumentConvert1XBodyTo20Body

	mov	bp, bx
	call	VMUnlock				;unlock new body

	call	DrawUndoAcceptActions

	;
	; Free old blocks
	;
	pop	cx					;cx = list
	pop	bx					;bx <- vm file handle
	xchg	bx, si
	call	ConvertDeleteViaBlockList
	xchg	bx, si

	;
	;  Turn relocation back on
	;
	mov	ax, VMA_OBJECT_ATTRS
	call	VMSetAttributes

	clc						;no error

	.leave
	ret
ConvertDrawDocument	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalUndoIgnoreActions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS to the 
		process

CALLED BY:	INTERNAL UTILITY

PASS:		nothing

RETURN:		nothing

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
	srs	8/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawUndoIgnoreActions		proc	far
	uses	ax,bx,cx,dx,bp,di
	.enter

	clr	cx				;don't flush
	clr	di
	call	GeodeGetProcessHandle
	mov	ax,MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS
	call	ObjMessage

	.leave
	ret
DrawUndoIgnoreActions		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGlobalUndoAcceptActions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_GEN_PROCESS_UNDO_ACCEPT_ACTIONS to the 
		process. Don't flush undo chain.

CALLED BY:	INTERNAL UTILITY

PASS:		nothing

RETURN:		nothing

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
	srs	8/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawUndoAcceptActions		proc	far
	uses	ax,cx,dx,bx,bp,di
	.enter

	clr	di
	call	GeodeGetProcessHandle
	mov	ax,MSG_GEN_PROCESS_UNDO_ACCEPT_ACTIONS
	call	ObjMessage

	.leave
	ret
DrawUndoAcceptActions		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentConvert1XBodyTo20Body
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - new GrObjBody
		cx:di - unrelocated optr
		bx - handle containing the relocation
		ax - vm file handle

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  2, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentConvert1XBodyTo20Body	proc	near
	uses	bx, cx, di
	.enter
convertLoop:
	jcxz	done
	test	di, LP_IS_PARENT
	jnz	done
	call	DoConvert
	jmp	convertLoop
	
done:
	.leave
	ret
DrawDocumentConvert1XBodyTo20Body	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoConvert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - GrObjBody
		^lcx:di - unrelocated 1X grobj optr
		bx - handle containing relocation
		ax - vm file handle

Return:		cx:di - next (VI_link) unrelocated 1X grobj optr
		bx - handle containing relocation

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  2, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoConvert	proc	near
	uses	ax, dx, bp
	.enter

	push	ax				;save vm file handle

	;
	;  Relocate the handle so we can lock the block
	;
	mov	al, RELOC_HANDLE
	call	ObjDoRelocation			;cx <- old grobj block

	;
	;  Read the old class out of the object
	;
	mov	bx, cx				;bx <- old grobj block
	call	ObjLockObjBlock
	mov	es, ax				;*es:di <- old grobj
	pop	ax				;ax <- vm file handle
	push	bx				;save handle for unlock

	;
	;  Save the next unrelocated 1X grobj optr
	;
	mov	bx, es:[di]
	add	bx, es:[bx+OLD_VIS_MASTER_CLASS_OFFSET]
	push	es:[bx+OLD_VI_LINK_OFFSET].handle
	push	es:[bx+OLD_VI_LINK_OFFSET].chunk

	mov	bp, di					;*es:bp <- old grobj
	mov	di, es:[di]				;es:di <- old grobj
	mov	bx, es:[di].high			;class #
	sub	bx, FIRST_EXPORTED_POSSIBLE_GROBJ_CLASS	;bx <- index #
	shl	bx					;bx <- offset
	cmp	bx, offset grObjClassConversionRoutineTableEnd \
			 - offset grObjClassConversionRoutineTable
	jge	nextGrObj
	call	cs:[grObjClassConversionRoutineTable][bx]
	jnc	nextGrObj
	
	;    Notify object that it is complete and ready to go
	;

	push	si				;save body chunk
	movdw	bxsi, cxdx
	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Add the new grobject to the body and have it drawn.
	;    If you wish to add many grobjects and draw them all
	;    at once use MSG_GB_ADD_GROBJ instead.
	;

	pop	si					;body chunk
	mov	bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_ADD_GROBJ
	call	ObjCallInstanceNoLock

	;
	;  Point es:di at the old grobj's VI_link to prepare for
	;  the next grobj
	;
nextGrObj:
	popdw	cxdi				;es:di <- old grobj optr
	pop	bx
	call	MemUnlock

	.leave
	ret
DoConvert	endp

grObjClassConversionRoutineTable	label	word
	word	ConvertRectangle
	word	ConvertEllipse
	word	ConvertLine
	word	ConvertNothing		;arc
	word	ConvertBitmap		;bitmap
	word	ConvertPolyline		;polyline
	word	ConvertPolygon		;polygon
	word	ConvertBasicText	;basic text
	word	ConvertGStringObject	;gstring
grObjClassConversionRoutineTableEnd	label	word


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Creates a new grobj rectangle using info about
		the passed old one.

Pass:		nothing

Return:		carry clear

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertNothing	proc	near
	.enter

	clc

	.leave
	ret
ConvertNothing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertRectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Creates a new grobj rectangle using info about
		the passed old one.

Pass:		*ds:si - GrObjBody
		*es:bp - old 1X grobj
		es:di - old 1X grobj
		ax - vm file

Return:		carry set
		^lcx:dx - new Rectangle

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertRectangle	proc	near
	uses	ax
	.enter

	;
	;  Create the new grobj
	;
	mov	cx, segment RectClass
	mov	dx, offset RectClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	call	ConvertTransform
	call	InitializeAttributes
	call	ConvertAreaAttributes
	call	ConvertLineAttributes

	stc
	.leave
	ret
ConvertRectangle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertEllipse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Creates a new grobj ellipse using info about


		the passed old one.

Pass:		*ds:si - GrObjBody
		*es:bp - old 1X grobj
		es:di - old 1X grobj
		ax - vm file handle

Return:		carry set
		^lcx:dx - new Ellipse

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertEllipse	proc	near
	uses	ax
	.enter

	;
	;  Create the new grobj
	;
	mov	cx, segment EllipseClass
	mov	dx, offset EllipseClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	call	ConvertTransform
	call	InitializeAttributes
	call	ConvertAreaAttributes
	call	ConvertLineAttributes

	stc
	.leave
	ret
ConvertEllipse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Creates a new grobj line using info about
		the passed old one.

Pass:		*ds:si - GrObjBody
		*es:bp - old 1X grobj
		es:di - old 1X grobj

Return:		carry set
		^lcx:dx - new Line

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertLine	proc	near
	uses	ax
	.enter

	;
	;  Create the new grobj
	;
	mov	cx, segment LineClass
	mov	dx, offset LineClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	call	ConvertTransform
	call	InitializeAttributes
	call	ConvertLineAttributes

	stc
	.leave
	ret
ConvertLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertPolyline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Creates a new grobj polyline using info about
		the passed old one.

Pass:		*ds:si - GrObjBody
		*es:bp - old 1X grobj
		es:di - old 1X grobj
		ax - vm file

Return:		carry set
		^lcx:dx - new Polyline

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertPolyline	proc	near
	uses	ax, bx, bp, di, si
	.enter

	push	di					;save 1X polyline

	;
	;  Create the new grobj
	;
	mov	cx, segment SplineGuardianClass
	mov	dx, offset SplineGuardianClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	push	cx, dx					;save guardian OD

	;
	;  get the block to store the spline object in
	;
	mov	ax,MSG_GB_GET_BLOCK_FOR_ONE_GROBJ
	call	ObjCallInstanceNoLock

	pop	bx, si					;^lbx:si <- guardian
	mov	ax,MSG_GOVG_CREATE_VIS_WARD
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	movdw	cxdx, bxsi
	pop	di					;es:di <- 1X polyline

	call	ConvertTransformKeepingScale
	call	InitializeAttributes
	call	ConvertLineAttributes
	call	ConvertPolylinePoints

	;
	;  And now, once again to undo any unwanted repositioning
	;  from ConvertPolylinePoints...
	;
	call	ReconvertCenter

if 0
	;
	;  Push the points down through the transform
	;
	push	ds
	mov	bx, cx
	call	ObjLockObjBlock
	mov	ds, ax
	mov	si, dx
	call	SplineGuardianTransformSplinePoints
	call	MemUnlock
	pop	ds
endif
	stc
	.leave
	ret
ConvertPolyline	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertPolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Creates a new grobj polygon using info about
		the passed old one.

Pass:		*ds:si - GrObjBody
		*es:bp - old 1X grobj
		es:di - old 1X grobj
		ax - vm file

Return:		carry set
		^lcx:dx - new Polygon

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertPolygon	proc	near
	uses	ax, bx, bp, di, si
	.enter

	push	di					;save 1X polygon

	;
	;  Create the new grobj
	;
	mov	cx, segment SplineGuardianClass
	mov	dx, offset SplineGuardianClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	push	cx, dx					;save guardian OD

	;
	;  get the block to store the spline object in
	;
	mov	ax,MSG_GB_GET_BLOCK_FOR_ONE_GROBJ
	call	ObjCallInstanceNoLock

	pop	bx, si					;^lbx:si <- guardian
	mov	ax,MSG_GOVG_CREATE_VIS_WARD
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	movdw	cxdx, bxsi
	pop	di					;es:di <- 1X polygon

	call	ConvertTransformKeepingScale
	call	InitializeAttributes
	call	ConvertLineAttributes
	call	ConvertAreaAttributes
	call	ConvertPolygonPoints

	;
	;  And now, once again to undo any unwanted repositioning
	;  from ConvertPolylinePoints...
	;
	call	ReconvertCenter

	;
	;  Push the points down through the transform
	;
if 0
	push	ds
	mov	bx, cx
	call	ObjLockObjBlock
	mov	ds, ax
	mov	si, dx
	call	SplineGuardianTransformSplinePoints
	call	MemUnlock
	pop	ds
endif

	stc
	.leave
	ret
ConvertPolygon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertPolylinePoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sets the points os the new grobj based on the old
		grobj's points.

Pass:		es:di - 1X grobj
		^lcx:dx - new grobj

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  8, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertPolylinePoints	proc	near
	uses	ax, bx, cx, dx, bp, di, si

	.enter

	;
	;	Point es:di at the 1X ObjectClass instance data
	;
	add	di, es:[di+OLD_GROBJ_MASTER_CLASS_OFFSET]
	mov	ax, es:[di+OLD_PI_numPtsInBase]
	mov	di, es:[di+OLD_PI_baseLMem]
	mov	di, es:[di]				;es:di <- Points array

	call	SetPointsCommon

	mov	ax, MSG_SPLINE_OPEN_CURVE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
ConvertPolylinePoints	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPointsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the points of the spline to the passed points

CALLED BY:	ConvertPolylinePoints, ConvertPolygonPoints

PASS:		^lcx:dx - grobj od
		ax	- # of points
		es:di - points address

RETURN:		^lbx:si - OD of ward

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/21/92   	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPointsCommon	proc near

params	local	SplineSetPointParams

	uses	ax, cx, dx, di
	.enter

	movdw	ss:[params].SSPP_points, esdi
	mov	ss:[params].SSPP_numPoints, ax

	movdw	bxsi, cxdx
	mov	ax, MSG_GOVG_GET_VIS_WARD_OD
	mov	di, mask MF_CALL
	call	ObjMessage
	movdw	bxsi, cxdx			; ^lbx:si - ward

	mov	ss:[params].SSPP_flags, SSPT_POINT shl offset SSPF_TYPE

	push	bp
	lea	bp, ss:[params]
	mov	dx, size params
	mov	ax, MSG_SPLINE_SET_POINTS
	mov	di, mask MF_STACK
	call	ObjMessage
	pop	bp

	.leave
	ret
SetPointsCommon	endp


	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertPolygonPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sets the points os the new grobj based on the old
		grobj's points.

Pass:		es:di - 1X grobj
		^lcx:dx - new grobj

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  8, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertPolygonPoints	proc	near
	uses	ax, bx, cx, dx, bp, di, si
	.enter

	;
	;	Point es:di at the 1X ObjectClass instance data
	;
	add	di, es:[di+OLD_GROBJ_MASTER_CLASS_OFFSET]
	mov	ax, es:[di+OLD_PGI_numPtsInBase]
	mov	di, es:[di+OLD_PGI_baseLMem]
	mov	di, es:[di]				;es:di <- Points array

	call	SetPointsCommon

	mov	ax, MSG_SPLINE_CLOSE_CURVE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
ConvertPolygonPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertBasicText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Creates a new grobj BasicText using info about
		the passed old one.

Pass:		*ds:si - GrObjBody
		*es:bp - old 1X grobj
		es:di - old 1X grobj
		ax - the VM file

Return:		carry set
		^lcx:dx - new text guardian

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertBasicText	proc	near
	uses	ax, bx, bp, si, di, ds
	.enter

	push	bp					;save old obj chunk
	push	ax					;save VM file
	push	di					;save 1X BasicText

	;
	;  Create the new grobj
	;
	mov	cx, segment MultTextGuardianClass
	mov	dx, offset MultTextGuardianClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	push	cx, dx					;save guardian OD

	;
	;  get the block to store the spline object in
	;
	mov	ax,MSG_GB_GET_BLOCK_FOR_ONE_GROBJ
	call	ObjCallInstanceNoLock

	pop	bx, si					;^lbx:si <- guardian
	mov	ax,MSG_GOVG_CREATE_VIS_WARD
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	pop	di					;es:di <- 1X BasicText

	pushdw	cxdx					;save ward
	movdw	cxdx, bxsi				;^lcx:dx <- guardian
	call	ConvertTransform
	call	InitializeAttributes

	popdw	cxdx					;^lcx:dx <- ward
	clr	di					;null style?
	pop	bp					;bp <- vm file
	segmov	ds, es					;*ds:si <- 1.X text
	mov_tr	ax, si					;^lbx:ax <- guardian
	pop	si
	call	ConvertOldTextObject

	mov	cx, bx
	mov_tr	dx, ax

	stc
	.leave
	ret
ConvertBasicText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertGStringObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Creates a new grobj GString using info about
		the passed old one.

Pass:		*ds:si - GrObjBody
		*es:bp - old 1X grobj
		es:di - old 1X grobj
		ax - the VM file

Return:		carry set 
			^lcx:dx - new grobj
		carry clear
			cx,dx - destroyed

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertGStringObject	proc	near
	uses	bx
	.enter

	mov	bx, OLD_GSI_vmemBlockHandle
	call	ConvertGStringCommon

	.leave
	ret
ConvertGStringObject	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertGStringCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Creates a new grobj GString using info about
		the passed old one.

Pass:		*ds:si - GrObjBody
		*es:bp - old 1X grobj
		es:di - old 1X grobj
		bx - offset to gstring block handle within 1.X grobj
		ax - the VM file

Return:		carry set 
			^lcx:dx - new grobj
		carry clear
			cx,dx - destroyed

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertGStringCommon	proc	near
	uses	ax, bx, bp, di, si
	.enter

	push	ax					;vm file

	;
	;  Create the new grobj
	;
	mov	cx, segment GStringClass
	mov	dx, offset GStringClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	call	ConvertTransformKeepingScale
	call	InitializeAttributes

	;
	; Convert the gstring to 2.0 format
	;


	pop	ax					;vm file
	pushdw	cxdx					;new grobj od
	mov	cx,ax					;vm file
	mov	dx,ax					;vm file
	add	di, es:[di+OLD_GROBJ_MASTER_CLASS_OFFSET]
	mov	di, es:[di][bx]				;gstring block
	clr	si					;don't free old?
	call	ConvertGString
	popdw	bxsi					;new grobj od

	;
	; Exit with carry clear if there is an error. clear carry
	; means no object to add to the body.
	;

	cmc
	jnc	done

	; 
	; Set converted gstring in object
	;

	clr	cx					;the gstring is
							;already in the vm
							;file
	mov	dx,di					;new gstring vm block 
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GSO_SET_GSTRING_FOR_1X_CONVERT
	call	ObjMessage
	movdw	cxdx,bxsi				;return new grobj od

	stc
done:
	.leave
	ret

ConvertGStringCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Creates a new grobj GString using info about
		the passed old one.

Pass:		*ds:si - GrObjBody
		*es:bp - old 1X grobj
		es:di - old 1X grobj
		ax - the VM file

Return:		carry clear (since there's no grobj to represent the object)

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertBitmap	proc	near
	uses	bx
	.enter

	mov	bx, OLD_BI_vmemBlockHandle
	call	ConvertGStringCommon

	.leave
	ret
ConvertBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertBitmapGStringCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Creates a new grobj GString using info about
		the passed old one.

Pass:		*ds:si - GrObjBody
		*es:bp - old 1X grobj
		es:di - old 1X grobj
		bx - offset to gstring block handle within 1.X grobj
		ax - the VM file

Return:		carry clear (since there's no grobj to represent the object)

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertBitmapGStringCommon	proc	near
	uses	ax, bx, cx, dx, bp, di
	.enter

	mov_tr	dx, ax					;dx <- vm file
	add	di, es:[di+OLD_GROBJ_MASTER_CLASS_OFFSET]
	push	di					;save 1.X Object inst.
	mov	di, es:[di][bx]				;di <- gstring block
	mov	cx, dx
	push	si
	clr	si					;don't free old?

	;
	; Convert the gstring to 2.0 format
	;

	call	ConvertGString
	pop	si
	mov_tr	ax, di					;ax <- vm handle
	pop	di					;es:di <- 1.X Object
	jc	exit

	;
	;  Calculate the center of the object
	;
	sub	sp, size PointDWFixed
	mov	bp, sp
	call	ConvertObjectCenter

	;
	; Parse that puppy
	;
	mov	bx, dx					;bx <- vm file
	call	GrObjBodyParseGString
	add	sp, size PointDWFixed

exit:
	clc
	.leave
	ret
ConvertBitmapGStringCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sets the transform os the new grobj based on the old
		grobj's transform.

Pass:		es:di - 1X grobj
		^lcx:dx - new grobj
		*ds:si - GrObjBody

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertTransform	proc	near
	uses	ax, bx, cx, dx, bp, di, si
	.enter

	;
	;	Point es:di at the 1X ObjectClass instance data
	;
	add	di, es:[di+OLD_GROBJ_MASTER_CLASS_OFFSET]


	;    Specify the position and size of the new grobject and
	;    have initialize itself to the default attributes
	;
	sub	sp,size BasicInit
	mov	bp,sp

	push	cx, dx					;save grobj optr

	clr	bx

	;
	;  center = OI_drawPt + OI_rotatePtOffset
	;

CheckHack <offset BI_center eq 0>

	call	ConvertObjectCenter

	;
	;  width = OI_baseBounds width * OI_scaleX
	;
	mov_tr	ax, bx						;ax <- 0
	mov	bx, es:[di + OLD_OI_baseBounds].R_right
	sub	bx, es:[di + OLD_OI_baseBounds].R_left
	mov	dx, es:[di + OLD_OI_scaleX].WWF_int
	mov	cx, es:[di + OLD_OI_scaleX].WWF_frac
	cmp	bx, 1
	je	haveWidth
	call	GrMulWWFixed
haveWidth:
	movwwf	ss:[bp].BI_width, dxcx

	;
	;  height = OI_baseBounds height * OI_scaleY
	;
	mov	bx, es:[di + OLD_OI_baseBounds].R_bottom
	sub	bx, es:[di + OLD_OI_baseBounds].R_top
	mov	dx, es:[di + OLD_OI_scaleY].WWF_int
	mov	cx, es:[di + OLD_OI_scaleY].WWF_frac
	cmp	bx, 1
	je	haveHeight
	call	GrMulWWFixed
haveHeight:
	movwwf	ss:[bp].BI_height, dxcx

	;
	; 		[cos w	-sin w]
	;  transform = 	[sin w	 cos w]		w = OI_rotateDegrees
	;

	mov	dx, es:[di + OLD_OI_rotateDegrees]
	tst	dx
	jnz	rotated

	inc	dx
	movwwf	ss:[bp].BI_transform.GTM_e11, dxax
	movwwf	ss:[bp].BI_transform.GTM_e22, dxax
	movwwf	ss:[bp].BI_transform.GTM_e12, axax
	movwwf	ss:[bp].BI_transform.GTM_e21, axax
	
afterRotation:
	pop	bx, si
	mov	dx,size BasicInit
	mov	di,mask MF_FIXUP_DS or mask MF_STACK
	mov	ax,MSG_GO_INIT_BASIC_DATA
	call	ObjMessage
	add	sp,size BasicInit
	
	.leave
	ret

rotated:
	push	dx
	call	GrQuickCosine
	movwwf	ss:[bp].BI_transform.GTM_e11, dxax
	movwwf	ss:[bp].BI_transform.GTM_e22, dxax

	pop	dx
	clr	ax
	call	GrQuickSine

	movwwf	ss:[bp].BI_transform.GTM_e21, dxax
	negwwf	dxax
	movwwf	ss:[bp].BI_transform.GTM_e12, dxax
	jmp	afterRotation

ConvertTransform	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReconvertCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sets the center of the transform of the new grobj based 
		on the old grobj's transform.

Pass:		es:di - 1X grobj
		^lcx:dx - new grobj
		*ds:si - GrObjBody

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReconvertCenter	proc	near
	uses	ax, bx, cx, dx, bp, di, si
	.enter

	;
	;	Point es:di at the 1X ObjectClass instance data
	;
	add	di, es:[di+OLD_GROBJ_MASTER_CLASS_OFFSET]


	;    Specify the position and size of the new grobject and
	;    have initialize itself to the default attributes
	;
	sub	sp,size PointDWFixed
	mov	bp,sp
	;
	;  center = OI_drawPt + OI_rotatePtOffset
	;

	call	ConvertObjectCenter

	movdw	bxsi,cxdx				;guardian optr
	mov	dx,size PointDWFixed
	mov	di,mask MF_FIXUP_DS or mask MF_STACK
	mov	ax,MSG_GO_MOVE_CENTER_ABS
	call	ObjMessage
	add	sp,size PointDWFixed
	
	.leave
	ret

ReconvertCenter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertTransformKeepingScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sets the transform os the new grobj based on the old
		grobj's transform, but doesn't convert the scale
		into the width and height of the object. See ConvertTransform
		for comparison

Pass:		es:di - 1X grobj
		^lcx:dx - new grobj
		*ds:si - GrObjBody

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	srs	1/8/93		Inital Revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertTransformKeepingScale	proc	near
	uses	ax, bx, cx, dx, bp, di, si
	.enter

	;
	;	Point es:di at the 1X ObjectClass instance data
	;
	add	di, es:[di+OLD_GROBJ_MASTER_CLASS_OFFSET]


	;    Specify the position and size of the new grobject and
	;    have initialize itself to the default attributes
	;
	sub	sp,size BasicInit
	mov	bp,sp

	push	cx, dx					;save grobj optr

	clr	bx

	;
	;  center = OI_drawPt + OI_rotatePtOffset
	;

CheckHack <offset BI_center eq 0>

	call	ConvertObjectCenter

	;
	;  width = OI_baseBounds width 
	;
	mov_tr	ax, bx						;ax <- 0
	mov	bx, es:[di + OLD_OI_baseBounds].R_right
	sub	bx, es:[di + OLD_OI_baseBounds].R_left
	movwwf	ss:[bp].BI_width, bxax

	;
	;  height = OI_basBounds height 
	;
	mov	bx, es:[di + OLD_OI_baseBounds].R_bottom
	sub	bx, es:[di + OLD_OI_baseBounds].R_top
	movwwf	ss:[bp].BI_height, bxax

	; 
	; build out transform in a windowless gstate
	;

	mov	bx,di				;old instance data offset
	clr	di
	call	GrCreateState

	mov	dx, es:[bx + OLD_OI_rotateDegrees]
	clr	cx
	call	GrApplyRotation

	mov	dx, es:[bx + OLD_OI_scaleX].WWF_int
	mov	cx, es:[bx + OLD_OI_scaleX].WWF_frac
	mov	ax,es:[bx + OLD_OI_scaleY].WWF_frac
	mov	bx,es:[bx + OLD_OI_scaleY].WWF_int
	call	GrApplyScale

	; 
	; copy the transform from the gstate into the basic init structure
	;

	push	es,di,ds,si
	sub	sp,size TransMatrix
	mov	si,sp
	segmov	ds,ss
	call	GrGetTransform
	segmov	es,ss
	mov	di,bp
	add	di,offset BI_transform
	mov	cx,(size GrObjTransMatrix)/2
	rep	movsw
	add	sp,size TransMatrix
	pop	es,di,ds,si

	call	GrDestroyState

	pop	bx, si
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_INIT_BASIC_DATA
	call	ObjMessage
	add	sp,size BasicInit
	
	.leave
	ret

ConvertTransformKeepingScale	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertObjectCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Converts the old object center to the new

Pass:		ss:[bp] - PointDWFixed
		esL[di] - 1.X grobj

Return:		ss:[bp] = center of grobj

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 26, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertObjectCenter	proc	near
	uses	ax, bx, dx
	.enter

	movwwf	axbx,es:[(di+OLD_OI_drawPt)].PF_x
	addwwf	axbx, es:[(di+OLD_OI_rotatePtOffset)].PF_x
	cwd
	movdwf	ss:[bp].BI_center.PDF_x,dxaxbx

	movwwf	axbx, es:[(di+OLD_OI_drawPt)].PF_y
	addwwf	axbx, es:[(di+OLD_OI_rotatePtOffset)].PF_y
	cwd
	movdwf	ss:[bp].BI_center.PDF_y,dxaxbx

	.leave
	ret
ConvertObjectCenter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Resets the area and line attribute tokens in the grobj
		from CA_NULL_ELEMENT to 0

Pass:		^lcx:dx - grobj

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  6, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeAttributes	proc	near
	uses	ax, bx, di, si
	.enter

	movdw	bxsi, cxdx
	mov	ax, MSG_GO_INIT_TO_DEFAULT_ATTRS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
InitializeAttributes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertAreaAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sets the area attributes os the new grobj based on the old
		grobj's attributes.

Pass:		es:di - 1X grobj
		^lcx:dx - new grobj

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertAreaAttributes	proc	near
	uses	ax, bx, cx, dx, bp, di, si
	.enter

	movdw	bxsi, cxdx
	mov	bp, di
	add	bp, es:[bp+OLD_GROBJ_MASTER_CLASS_OFFSET]

	mov	cl, es:[bp+OLD_AA_foreAttr].AAS_1X_r
	mov	ch, es:[bp+OLD_AA_foreAttr].AAS_1X_g
	mov	dl, es:[bp+OLD_AA_foreAttr].AAS_1X_b
	mov	ax, MSG_GO_SET_AREA_COLOR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;    Set us some usable defaults
	;

	mov	cl,SDM_100
	mov	ax, MSG_GO_SET_AREA_MASK
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	cl,PT_SOLID
	mov	ax, MSG_GO_SET_AREA_PATTERN
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;    Of old DrawMasks the first 24 were actually patterns.
	;

	mov	cl, es:[bp+OLD_AA_foreAttr].AAS_1X_mask
	cmp	cl,25
	jl	itsAPattern
	mov	ax, MSG_GO_SET_AREA_MASK
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

drawMode:
	mov	cl, es:[bp+OLD_AA_foreAttr].AAS_1X_drawMode
	mov	ax, MSG_GO_SET_AREA_DRAW_MODE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	test 	es:[bp+OLD_AA_foreAttr].AAS_1X_areaInfo,mask AAIR1X_filled
	jz	unfilled

	mov	cl,TRUE					;assume
	test 	es:[bp+OLD_AA_foreAttr].AAS_1X_areaInfo,mask AAIR1X_transparent
	jnz	send
	mov	cl,FALSE

send:
	mov	ax, MSG_GO_SET_TRANSPARENCY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret

itsAPattern:
	;    The mask is actually a pattern, because the low 25 masks
	;    in 1.2 were actually patterns. (ie slanted brick).
	;    Warning, this is a hack, don't look with out your
	;    peril sensitive glasses.
	;
	
	;   special horizontal ->SH_HORIZONTAL
	;

	cmp	cl,23
	mov	ch,SH_HORIZONTAL	
	je	setPattern

	;    special verticalL ->SH_VERTICAL
	;

	cmp	cl,24
	mov	ch,SH_VERTICAL
	je	setPattern

	;    MASK_DIAG_NE ->SH_45_DEGREE
	;

	cmp	cl,4
	mov	ch,SH_45_DEGREE
	je	setPattern

	;    MASK_DIAG_NW->SH_135_DEGREE
	;

	cmp	cl,5
	mov	ch,SH_135_DEGREE
	je	setPattern

	;    MASK_BRICK->SH_BRICK
	;

	cmp	cl,8
	mov	ch,SH_BRICK
	je	setPattern

	;    MASK_SLANT_BRICK->SH_SLANTED_BRICK
	;

	cmp	cl,9
	mov	ch,SH_SLANTED_BRICK
	jne	drawMode

setPattern:
	mov	cl,PT_SYSTEM_HATCH
	mov	ax, MSG_GO_SET_AREA_PATTERN
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	jmp	drawMode


unfilled:
	;    1.X objects that weren't filled still may have had area masks
	;    that weren't zero. So we must zero the area mask explicitly.
	;    Also these object must me marked as transparent so that
	;    the background won't draw either. 
	;

	mov	di,mask MF_FIXUP_DS
	mov	cl,SDM_0
	mov	ax,MSG_GO_SET_AREA_MASK
	call	ObjMessage
	mov	cl,TRUE
	jmp	send

ConvertAreaAttributes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertLineAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sets the line attributes os the new grobj based on the old
		grobj's attributes.

Pass:		es:di - 1X grobj
		^lcx:dx - new grobj

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Sep  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertLineAttributes	proc	near
	uses	ax, bx, cx, dx, bp, di, si
	.enter

	movdw	bxsi, cxdx
	mov	bp, di
	add	bp, es:[bp+OLD_GROBJ_MASTER_CLASS_OFFSET]

	mov	cl, es:[bp+OLD_LA_foreAttr].LAS_1X_r
	mov	ch, es:[bp+OLD_LA_foreAttr].LAS_1X_g
	mov	dl, es:[bp+OLD_LA_foreAttr].LAS_1X_b
	mov	ax, MSG_GO_SET_LINE_COLOR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;    Of old DrawMasks the first 24 were actually patterns.
	;    But there are no line patterns in 2.0 so just use
	;    100 mask.
	;

	mov	cl, es:[bp+OLD_LA_foreAttr].LAS_1X_mask
	cmp	cl,25
	jge	doMask
	mov	cl,SDM_100
doMask:
	mov	ax, MSG_GO_SET_LINE_MASK
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	cl, es:[bp+OLD_LA_foreAttr].LAS_1X_end
	mov	ax, MSG_GO_SET_LINE_END
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	cl, es:[bp+OLD_LA_foreAttr].LAS_1X_join
	mov	ax, MSG_GO_SET_LINE_END
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	cl, es:[bp+OLD_LA_foreAttr].LAS_1X_style
	mov	ax, MSG_GO_SET_LINE_STYLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	dx, es:[bp+OLD_LA_foreAttr].LAS_1X_width
	clr	cx
	mov	ax, MSG_GO_SET_LINE_WIDTH
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret

ConvertLineAttributes	endp

ConvertDrawDocumentCode	ends
