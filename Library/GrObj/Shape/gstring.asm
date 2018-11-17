COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GrObj
MODULE:		Shape
FILE:		gstring.asm

AUTHOR:		Steve Scholl, May 15, 1992

ROUTINES:
	Name		
	----		

	GStringSetNormalTransformForNewGString
	GStringGetVMFileHandle	
	GStringDestroyGString
	ECGStringCheckLMemObject

METHODS:
	Name		
	----		
	GStringMetaIntialize
	GStringDrawFG
	GStringSetGString	
	GStringGetBoundingRectDWFixed
	GStringNukeDataInOtherBlocks
				

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	5/15/92		Initial revision


DESCRIPTION:
	This file contains routines to implement the GString Class
		

	$Id: gstring.asm,v 1.1 97/04/04 18:08:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

GStringClass

GrObjClassStructures	ends

RectPlusCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GStringMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	GString does a multiplicative resize

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GStringClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringMetaInitialize	method dynamic GStringClass, 
						MSG_META_INITIALIZE
	.enter

	mov	di, offset GStringClass
	call	ObjCallSuperNoLock

	GrObjDeref	di,ds,si
	BitSet	ds:[di].GOI_attrFlags, GOAF_MULTIPLICATIVE_RESIZE

	.leave
	ret
GStringMetaInitialize		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GStringGetBoundingRectDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the RectDWFixed that bounds the object in
		the dest gstate coordinate system. Include the line
		width.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GStringClass

		ss:bp - BoundingGStringData
			destGState
			parentGState

RETURN:		
		ss:bp - BoundingGStringData
			rect
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		In most cases the line width that gstring elements draw
		with will be set in the gstring. However, if the
		gstring doesn't set the line width then the grobj line
		width will be used. Even though this case is rare we are
		going to expand our bounds to avoid any screen greebles
		on invalidates and such.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringGetBoundingRectDWFixed	method dynamic GStringClass, 
					MSG_GO_GET_BOUNDING_RECTDWFIXED
	.enter

	mov	di,offset GStringClass
	call	ObjCallSuperNoLock

	CallMod	GrObjAdjustRectDWFixedByLineWidth

	.leave
	ret
GStringGetBoundingRectDWFixed		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GStringSetGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the object's pointer to point to a passed gstring

PASS:		*ds:si	= GStringClass object
		ds:di	= GStringClass instance data
		es	= Segment of GStringClass.

		cx = VM file handle of gstring
		dx = VM block handle of gstring

RETURN:		
		nothing		

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:	
		Invalidate the area if an old string exists.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringSetGString	method	dynamic	GStringClass, MSG_GSO_SET_GSTRING
	uses	cx,dx
	.enter

	;    Invalidate the gstring object at its current size
	;

	tst	ds:[di].GSI_vmemBlockHandle
	jz	doneInvalidate
	call	GrObjOptInvalidate
doneInvalidate:
	push	si					;object chunk

	;    Nuke the existing string if it exists
	;

	call	GStringDestroyGString

	;    If the vmem file was passed as zero then we don't 
	;    need to copy it
	;

	jcxz	storeHandle

	;    Copy the new string
	;

	mov	bx, cx			; passed vm file
	mov	si, dx			; passed vm block handle
	mov	cl, GST_VMEM
	call	GrLoadGString
	push	si			; handle of source string

	;    Allocate a new block and create a new string
	;

	call	GStringGetVMFileHandle
	mov	cl,GST_VMEM
	call	GrCreateGString
	pop	dx				; source gstring
	push	si				; VM block of new string
	mov	si, dx				; restore source gstring

	;    Copy that puppy
	;

	clr	dx				; no position or flags
	call	GrCopyGString

	;    End copied string and destroy its handle
	;

	call	GrEndGString
	mov	dl,GSKT_LEAVE_DATA
	push	si
	mov	si, di				; si <- (dest) GString
	clr	di				; di <- no GState
	call	GrDestroyGString
	pop	si				; si <- (source) GString

	;    Free the transfer gstring we allocated with GrLoadGString
	;

	call	GrDestroyGString

	pop	dx				; VM block of new string

storeHandle:	
	pop	si				; gstring object chunk
	GrObjDeref	di,ds,si
	mov	ds:[di].GSI_vmemBlockHandle, dx

	call	GStringSetNormalTransformForNewGString

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GO_INVALIDATE
	call	ObjCallInstanceNoLock

	.leave
	ret
GStringSetGString	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GStringSetNormalTransformForNewGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the
		width and height to the bounds of the gstring.
		Calculate the gstringCenterTrans

CALLED BY:	INTERNAL
		GStringSetGString

PASS:		*ds:si - gstring object

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
	srs	5/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringSetNormalTransformForNewGString		proc	near
	class	GStringClass
	uses	ax,bx,cx,dx,bp,di,si
	.enter

	push	si					;gsrtring object chunk

	;    Get us a gstring handle
	;

	GrObjDeref	di,ds,si
	mov	si, ds:[di].GSI_vmemBlockHandle
	mov	cl, GST_VMEM
	call	GStringGetVMFileHandle
	call	GrLoadGString		

	;    Get the bounds of that puppy and then destroy it
	;

	clr	dx				;no controls
	mov	di,dx				;no gstate
	call	GrGetGStringBounds
	push	dx				;bottom
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString
	pop	dx				;bottom


	pop	si				;gstring object chunk

	;   Set the normal transform. In the process keep track of
	;   the upper left of the object so that we can keep it from
	;   moving.
	;

	push	bx				; top
	push	ax				; left
	sub	sp,size SrcDestPointDWFixeds
	mov	bp,sp
	push	cx				;right
	mov	cx,HANDLE_LEFT_TOP
	addnf	bp, <offset SDPDWF_source>
	call	GrObjGetNormalPARENTHandleCoords
	subnf	bp, <offset SDPDWF_source>
	pop	cx				;right

	sub	cx,ax				;right - left
	sub	dx,bx				;bottom - top
	mov	bx,dx				;height int
	mov	dx,cx				;width int
	clr	ax,cx				;fracs	
	call	GrObjSetNormalOBJECTDimensions

	addnf	bp, <offset SDPDWF_dest>
	mov	cx,HANDLE_LEFT_TOP
	call	GrObjGetNormalPARENTHandleCoords
	subnf	bp, <offset SDPDWF_dest>

	call	GrObjMoveNormalBackToAnchor
	add	sp,size SrcDestPointDWFixeds

	;   Set the gstringCenterTrans
	;   - x/2 of center, - y/2 of center
	;

	GrObjDeref	di, ds, si		; deref grobj

	clr	cx
	pop	ax				; axcx - left (WWF)
	shr	dx
	jnc	gotFracX
	mov	cx, 8000h
gotFracX:
	add	ax, dx
	negwwf	axcx
	movwwf	ds:[di].GSI_gstringCenterTrans.PF_x, axcx


	clr	cx
	pop	ax				; axcx - top (WWF)
	shr	bx
	jnc	gotFracY
	mov	cx, 8000h
gotFracY:
	add	ax, bx
	negwwf	axcx
	movwwf	ds:[di].GSI_gstringCenterTrans.PF_y, axcx
	
	.leave
	ret
GStringSetNormalTransformForNewGString		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GStringSetGStringFor1XConvert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the object's pointer to point to a passed gstring

PASS:		*ds:si	= GStringClass object
		ds:di	= GStringClass instance data
		es	= Segment of GStringClass.

		cx = VM file handle of gstring
		dx = VM block handle of gstring

RETURN:		
		nothing		

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:	
		Invalidate the area if an old string exists.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringSetGStringFor1XConvert	method	dynamic	GStringClass, 
				MSG_GSO_SET_GSTRING_FOR_1X_CONVERT
	uses	cx,dx
	.enter

	;    Invalidate the gstring object at its current size
	;

	tst	ds:[di].GSI_vmemBlockHandle
	jz	doneInvalidate
	call	GrObjOptInvalidate
doneInvalidate:
	push	si					;object chunk

	;    Nuke the existing string if it exists
	;

	call	GStringDestroyGString

	;    If the vmem file was passed as zero then we don't 
	;    need to copy it
	;

	jcxz	storeHandle

	;    Copy the new string
	;

	mov	bx, cx			; passed vm file
	mov	si, dx			; passed vm block handle
	mov	cl, GST_VMEM
	call	GrLoadGString
	push	si			; handle of source string

	;    Allocate a new block and create a new string
	;

	call	GStringGetVMFileHandle
	mov	cl,GST_VMEM
	call	GrCreateGString
	pop	dx				; source gstring
	push	si				; VM block of new string
	mov	si, dx				; restore source gstring

	;    Copy that puppy
	;

	clr	dx				; no position or flags
	call	GrCopyGString

	;    End copied string and destroy its handle
	;

	call	GrEndGString
	mov	dl,GSKT_LEAVE_DATA
	push	si
	mov	si, di				; si <- (dest) GString
	clr	di				; di <- no GState
	call	GrDestroyGString
	pop	si				; si <- (source) GString

	;    Free the transfer gstring we allocated with GrLoadGString
	;

	call	GrDestroyGString

	pop	dx				; VM block of new string

storeHandle:	
	pop	si				; gstring object chunk
	GrObjDeref	di,ds,si
	mov	ds:[di].GSI_vmemBlockHandle, dx

	call	GrObjGetNormalOBJECTDimensions
	shrwwf	dxcx
	shrwwf	bxax
	negwwf	dxcx
	negwwf	bxax
	GrObjDeref	di,ds,si
	movwwf	ds:[di].GSI_gstringCenterTrans.PF_x,dxcx
	movwwf	ds:[di].GSI_gstringCenterTrans.PF_y,bxax

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GO_INVALIDATE
	call	ObjCallInstanceNoLock

	.leave
	ret
GStringSetGStringFor1XConvert	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GStringNukeDataInOtherBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke the gstring.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GStringClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringNukeDataInOtherBlocks	method dynamic GStringClass, 
						MSG_GO_NUKE_DATA_IN_OTHER_BLOCKS
	.enter

	call	GStringDestroyGString

	.leave
	ret
GStringNukeDataInOtherBlocks		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GStringDestroyGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the gstring and data

CALLED BY:	INTERNAL 
		GStringNukeDataInOtherBlocks
		GStringSetGString

PASS:		*ds:si - GString object

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
	srs	5/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringDestroyGString		proc	near
	class	GStringClass
	uses	cx,dx,di,si
	.enter

EC <	call	ECGStringCheckLMemObject		>

	GrObjDeref	di,ds,si
	mov	si,ds:[di].GSI_vmemBlockHandle
	tst	si
	jz	done

	mov	cl, GST_VMEM
	call	GStringGetVMFileHandle
	call	GrLoadGString
	mov	di, si				;gstring handle
	mov	dl, GSKT_KILL_DATA
	call	GrDestroyGString

done:
	.leave
	ret
GStringDestroyGString		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GStringGetVMFileHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the VM FIle handle of the file containing the
		current block

CALLED BY:	INTERNAL
		GStringDrawFG
		GStringSetGString

PASS:		ds - a segment in the file

RETURN:		bx - VM file handle

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringGetVMFileHandle	proc far
	uses	ax
	.enter
	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo
	mov	bx, ax
	.leave
	ret
GStringGetVMFileHandle	endp



RectPlusCode	ends

GrObjDrawCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GStringDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The gstring cannot be drawn in two phase, area and line, like
		most objects. So we must subclass MSG_GO_DRAW instead of
		the normal MSG_GO_DRAW_FG_AREA, ...

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GStringClass

		bp - gstate
		cl - DrawFlags
		dx - GrObjDrawFlags

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
	srs	11/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringDraw	method dynamic GStringClass, MSG_GO_DRAW
	uses	bp,dx
	.enter

	call	GrObjCanDraw?
	jnc	done

	;    Call the super class on these modes will result in
	;    MSG_GO_DRAW_QUICK_VIEW, MSG_GO_DRAW_PARENT_RECT or
	;    MSG_GO_DRAW_CLIP_AREA. No of these require separate
	;    area and line drawing.
	;

	test	dx,mask GODF_DRAW_QUICK_VIEW or \
		mask GODF_DRAW_WRAP_TEXT_INSIDE_ONLY or \
		mask GODF_DRAW_WRAP_TEXT_AROUND_ONLY
	jnz	callSuper

	mov	di,bp				;gstate
	call	GrSaveTransform
	call	GrObjApplyNormalTransform

	xchg	dx,bp				;gstate, GrObjDrawFlags
	call	GStringDrawGString

 	call	GrRestoreTransform

done:
	.leave
	ret


callSuper:
	mov	di,offset GStringClass
	call	ObjCallSuperNoLock
	jmp	done

GStringDraw		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GStringDrawGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the gstring.

PASS:		
		*(ds:si) - instance data of object
		dx - GState - objects normal transform has been applied
		cl - DrawFlags
		bp - GrObjDrawFlags

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringDrawGString proc	near
	class	GStringClass
	uses	si,di,ax,bx,cx,dx,bp
	.enter

EC <	call	ECGStringCheckLMemObject		>
	mov	di,dx					;gstate
EC <	call	ECCheckGStateHandle				>

	;    Apply attributes because it is allowed for the gstring to
	;    depend on the grobj attributes instead of having attributes in
	;    the gstring.
	;

	GrObjDeref	bx,ds,si
	mov	cx,ds:[bx].GOI_areaAttrToken
	call	GrObjApplyGrObjAreaToken
	mov	cx,ds:[bx].GOI_lineAttrToken
	call	GrObjApplyGrObjLineToken

	call	GrSaveTransform
	
	;    Get position to draw gstring at
	;

	movwwf	axcx, ds:[bx].GSI_gstringCenterTrans.PF_x
	rndwwf	axcx
	movwwf	dxcx, ds:[bx].GSI_gstringCenterTrans.PF_y
	rndwwf	dxcx

	;    Load us a gstring handle
	;

	mov	si, ds:[bx].GSI_vmemBlockHandle
	mov	cl, GST_VMEM
	call	GStringGetVMFileHandle
	call	GrLoadGString		

	;    Draw GString to GState
	;

	mov	bx,dx					;y to draw at
	clr	dx					;no control flags
	call	GrDrawGString

	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString

	call	GrRestoreTransform

	.leave
	ret
GStringDrawGString		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GStringDrawBG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Override the default handler and draw nothing
		for the background

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GStringClass

		dx - GState 
		cl - DrawFlags
		bp - GrObjDrawFlags

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringDrawBG method	dynamic GStringClass, MSG_GO_DRAW_BG_AREA,
					MSG_GO_DRAW_BG_AREA_HI_RES,
					MSG_GO_DRAW_FG_AREA,		
					MSG_GO_DRAW_FG_AREA_HI_RES,		
					MSG_GO_DRAW_FG_LINE,
					MSG_GO_DRAW_FG_LINE_HI_RES

	.enter


	.leave
	ret
GStringDrawBG		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GStringDrawClipArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the gstring for clipping

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GStringClass

		dx - GState 
		cl - DrawFlags
		bp - GrObjDrawFlags

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringDrawClipArea method	dynamic GStringClass, MSG_GO_DRAW_CLIP_AREA,
						MSG_GO_DRAW_CLIP_AREA_HI_RES

	.enter

	call	GStringDrawGString

	.leave
	ret
GStringDrawClipArea		endm


GrObjDrawCode	ends


GrObjTransferCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GStringCreateTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GString method for MSG_GO_CREATE_TRANSFER

Called by:	

Pass:		*ds:si = GString object
		ds:di = GString instance

		ss:bp - GrObjTransferParams

Return:		ss:[bp].GTP_curSlot - updated to the next slot in the header

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringCreateTransfer	method dynamic	GStringClass, MSG_GO_CREATE_TRANSFER
	uses	cx, dx, bp
	.enter

	;
	;  Allocate a VMBlock item big enough for our GString
	;
	add	cx, size VMChainTree + size GrObjEntryPointRelocation + size dword
	mov	ss:[bp].GTP_curSize, cx
	mov	bx, ss:[bp].GTP_vmFile
	clr	ax				;user ID
	call	VMAlloc				;ax <- block handle
	clr	di

	movdw	ss:[bp].GTP_id, axdi

	mov_tr	cx, ax				;cx <- GString tree block handle

	;
	;  Indicate that we're going to write the tree stuff and the class
	;
	mov	ss:[bp].GTP_curPos, size VMChainTree + size GrObjEntryPointRelocation

	;
	;  Write the rest of our instance data out
	;	
	mov	ax, MSG_GO_WRITE_INSTANCE_TO_TRANSFER
	call	ObjCallInstanceNoLock

	;
	; Lock down the damn block and copy the gstring into it
	;
	mov	ax, cx					;ax <- block handle
	mov	di, ss:[bp].GTP_curPos			;di <- after inst. data
	mov	dx, ss:[bp].GTP_vmFile
	push	bp					;save GTP

	call	VMLock
	call	VMDirty
	mov	es, ax

	;
	;  Indicate that this is a tree, not a leaf
	;
	mov	es:[VMCT_meta].VMCL_next, VM_CHAIN_TREE

	;
	;  We only have one branch off this node, which is the copied gstring,
	;  who's 32-bit id will be located right after the gstring obj's data
	;
	mov	es:[VMCT_count], 1
	mov	es:[VMCT_offset], di

	;
	;  Copy the gstring and put the copy here
	;

	GrObjDeref	bx,ds,si
	mov	ax, ds:[bx].GSI_vmemBlockHandle
	call	GStringGetVMFileHandle
	push	bp
	clr	bp
	call	VMCopyVMChain
	movdw	es:[di], axbp
	pop	bp

	mov	di, size VMChainTree
	mov	ax, MSG_META_GET_CLASS
	call	ObjCallInstanceNoLock
	mov	di, size VMChainTree
	mov	ax, MSG_GO_GET_GROBJ_CLASS
	call	GrObjWriteEntryPointRelocation

	call	VMUnlock
	pop	bp

	;
	;  Store our identifier in the header
	;
	mov	bx, ss:[bp].GTP_vmFile
	mov	ax, ss:[bp].GTP_textSSP.VTSSSP_treeBlock
	mov	di, ss:[bp].GTP_curSlot
	mov	cx, ss:[bp].GTP_id.high

	push	bp
	call	VMLock
	mov	es, ax
	mov	es:[di].high, cx
	clr	es:[di].low
	call	VMDirty
	call	VMUnlock
	pop	bp

	add	di, size dword				;point to the next slot
	mov	ss:[bp].GTP_curSlot, di

	.leave
	ret
GStringCreateTransfer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GStringReplaceWithTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GString method for MSG_GO_REPLACE_WITH_TRANSFER

Called by:	

Pass:		*ds:si = GString object
		ds:di = GString instance

		ss:[bp] - GrObjTransferParams

Return:		ss:[bp].GTP_curPos - updated to after read data

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GStringReplaceWithTransfer	method dynamic	GStringClass,
				MSG_GO_REPLACE_WITH_TRANSFER
	uses	cx,dx,bp
	.enter

	;
	;  call superclass, updating ss:[bp].GTP_curPos
	;
	mov	di, offset GStringClass
	call	ObjCallSuperNoLock

	;
	;  Read our gstring out of the vm file
	;
	mov	bx, ss:[bp].GTP_vmFile
	mov	ax, ss:[bp].GTP_id.high
	call	VMLock
	mov	es, ax
	mov	di, es:[VMCT_offset]
	mov	cx, bx				;cx <- vm file
	mov	dx, es:[di].high		;dx <- vm block handle
	call	VMUnlock

	;
	;  Copy that pup
	;
	mov	ax, MSG_GSO_SET_GSTRING
	call	ObjCallInstanceNoLock

	.leave
	ret
GStringReplaceWithTransfer	endm

GrObjTransferCode	ends



if	ERROR_CHECK

GrObjErrorCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECGStringCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si is a pointer to an object stored
		in an object block and that it is an GStringClass or one
		of its subclasses
		
CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - object chunk to check
RETURN:		
		none
DESTROYED:	
		nothing - not even flags

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECGStringCheckLMemObject		proc	far
ForceRef	ECGStringCheckLMemObject		
	uses	es,di
	.enter
	pushf	
	mov	di,segment GStringClass
	mov	es,di
	mov	di,offset GStringClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_A_DRAW_OBJECT	
	popf
	.leave
	ret
ECGStringCheckLMemObject		endp

GrObjErrorCode	ends

endif




