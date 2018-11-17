COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj/Body
FILE:		bodyImpex.asm

AUTHOR:		Steve Scholl

METHODS:
	Name		
	----	
	GrObjBodyImport
	GrObjBodyExport

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/22/92		Initial Revision

DESCRIPTION:
	Transfer item creation stuff

	$Id: bodyImpex.asm,v 1.1 97/04/04 18:07:57 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjImpexCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Import a gstring into a newly created gstring object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass
		
		ss:bp - ImpexTranslationParams

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
	srs	6/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyImport	method dynamic GrObjBodyClass, MSG_GB_IMPORT
	uses	cx
	.enter

	test	ss:[bp].ITP_dataClass, mask IDC_GRAPHICS	
	jz	done

	mov	cx,ss:[bp].ITP_clipboardFormat
	call	GrObjBodyRemoveAllGrObjsFromSelectionList

	call	GrObjBodyClearPasteCallBack

	;    Set override file to transfer file
	;

	mov	bx,ss:[bp].ITP_transferVMFile

	;    Import the gstring
	;

	mov	ax,ss:[bp].ITP_transferVMChain.high
	push	bp
	sub	sp, size PointDWFixed
	mov	bp, sp
	call	GrObjBodyGetWinCenter
	cmp	cx,CIF_BITMAP
	je	hugeBitmap
	call	GrObjBodyParseGString
clearFrame:
	add	sp,size PointDWFixed

	;    The objects were selected as they were imported but
	;    there handles haven't been drawn yet.
	;

	clr	dx					;no gstate
	mov	ax,MSG_GO_DRAW_HANDLES
	call	GrObjBodySendToSelectedGrObjs

	pop	bp					;impex stack frame
	call	GrObjImpexImportExportCompleted				

done:
	.leave
	ret

hugeBitmap:
	call	GrObjBodyImportHugeBitmap
	jmp	clearFrame

GrObjBodyImport		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Export gstring

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - ImpexTranslationParams

RETURN:		
		ss:[bp].ITP_transferVMChain.high <- gstring handle
	
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
	srs	5/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyExport	method dynamic GrObjBodyClass, MSG_GB_EXPORT
	uses	cx,dx,bp
	.enter

	;    Create gstring in passed vm file
	;

	mov_tr	ax,si					;body chunk
	mov	bx,ss:[bp].ITP_transferVMFile		
	mov	cl, GST_VMEM
	call	GrCreateGString
	mov	ss:[bp].ITP_transferVMChain.high,si
	clr	ss:[bp].ITP_transferVMChain.low
	mov	ss:[bp].ITP_clipboardFormat, CIF_GRAPHICS_STRING
	mov	ss:[bp].ITP_manufacturerID, MANUFACTURER_ID_GEOWORKS

	mov_tr	si,ax					;body chunk

	call	GrObjBodySetGStringBoundsToDocumentBounds

	;    Draw children into gstring and end gstring
	;    Pass DF_PRINT so that text objects won't show their
	;    selections.
	;
	
	push	bp					;stack frame
	call	GrObjBodySetGrObjDrawFlagsForDraw
	ornf	dx, mask GODF_DRAW_OBJECTS_ONLY or \
			mask GODF_DRAW_WITH_INCREASED_RESOLUTION
	mov	cl,mask DF_PRINT			;DrawFlags for vis objs
	mov	bp,di					;gstate
	mov	ax,MSG_GB_DRAW
	call	ObjCallInstanceNoLock
	call	GrEndGString
	pop	bp					;stack frame

	call	GrObjImpexImportExportCompleted				

	.leave
	ret
GrObjBodyExport		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetGStringBoundsToDocumentBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the gstring bounds of the passed gstring

		We want to preserve the location of the objects in
		relation to the upper left of the document but
		not include white space to the right of and below
		the objects.


CALLED BY:	INTERNAL
		GrObjBodyExport

PASS:		*ds:si - body
		di - gstring handle

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
	srs	6/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetGStringBoundsToDocumentBounds		proc	near
	class	GrObjBodyClass
	uses	ax,bx,cx,dx,si,bp
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	si,ds:[si]
	add	si,ds:[si].GrObjBody_offset
	mov	ax,ds:[si].GBI_bounds.RD_left.low
	mov	bx,ds:[si].GBI_bounds.RD_top.low
	mov	cx,ds:[si].GBI_bounds.RD_right.low
	mov	dx,ds:[si].GBI_bounds.RD_bottom.low
	call	GrSetGStringBounds

	.leave
	ret
GrObjBodySetGStringBoundsToDocumentBounds		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyExportSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Export gstring that contains the selected grobjects.
		Draw the objects so that the upper left of their
		bounding rect will be at 0,0

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - ImpexTranslationParams

RETURN:		
		ss:[bp].ITP_transferVMChain.high <- gstring handle
	
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
	srs	5/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyExportSelectedGrObjs	method dynamic GrObjBodyClass, 
						MSG_GB_EXPORT_SELECTED_GROBJS
	uses	cx,dx,bp
	.enter

	;    Create gstring in passed vm file
	;    Always create gstring even if we don't draw anything, to
	;    prevent the translation code from crashing.
	;

	mov_tr	ax,si					;body chunk
	mov	bx,ss:[bp].ITP_transferVMFile		
	mov	cl, GST_VMEM
	call	GrCreateGString
	mov	ss:[bp].ITP_transferVMChain.high,si
	clr	ss:[bp].ITP_transferVMChain.low
	mov	ss:[bp].ITP_clipboardFormat, CIF_GRAPHICS_STRING
	mov	ss:[bp].ITP_manufacturerID, MANUFACTURER_ID_GEOWORKS
	mov_tr	si,ax					;body chunk

	;    If no selected children then bail
	;

	push	bp					;stack frame
	call	GrObjBodyGetNumSelectedGrObjs	
	tst	bp
	pop	bp					;stack frame
	jz	endString

	;    If selected objects bounds violates coordinate system bounds
	;    then bail
	;

	mov	dx,MAX_COORD*2
	call	GrObjBodyCheckBoundsOfSelectedGrObjs
	jnc	error


	call	GrObjBodySetGStringBoundsToSelectedBounds

	call	GrObjBodyTranslateBackToZeroZero


	;    Draw children into gstring and end gstring
	;    Pass DF_PRINT so that text objects won't show their
	;    selections.
	;
	
	push	bp					;stack frame
	call	GrObjBodySetGrObjDrawFlagsForDraw
	ornf	dx, mask GODF_DRAW_SELECTED_OBJECTS_ONLY or \
			mask GODF_DRAW_OBJECTS_ONLY or \
			mask GODF_DRAW_WITH_INCREASED_RESOLUTION
	mov	cl,mask DF_PRINT			;DrawFlags for vis objs
	mov	bp,di					;gstate
	mov	ax,MSG_GB_DRAW
	call	ObjCallInstanceNoLock
	pop	bp					;stack frame

endString:
	call	GrEndGString
	call	GrObjImpexImportExportCompleted				

	.leave
	ret

error:	;ERROR NOT REPORTED
	jmp	endString

GrObjBodyExportSelectedGrObjs		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjImpexImportExportCompleted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the handle of the impex library, and calls 
		ImpexImportExportCompleted().

CALLED BY:	GLOBAL
PASS:		ss:bp - ImpexTranslationParams
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
impexName	char	"impex   ",0
GrObjImpexImportExportCompleted	proc	near
	uses	ax, bx, cx, dx, di, es
	.enter

	mov	ax, size impexName-1
	segmov	es, cs
	mov	di, offset impexName
	clr	cx, dx
FXIP <	call	SysCopyToStackESDI					>
	call	GeodeFind
FXIP <	call	SysRemoveFromStack					>
EC <	ERROR_NC	-1						>
NEC <	jnc	exit							>
   	mov	ax, enum ImpexImportExportCompleted
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
exit::						; Conditional label (NEC)
	.leave
	ret
GrObjImpexImportExportCompleted	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetGStringBoundsToSelectedBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the gstring bounds of the passed gstring to the
		bounds of the selected objects translated to have its
		upper left at 0,0

CALLED BY:	INTERNAL
		GrObjBodyExportSelectedGrObjs

PASS:		*ds:si - body
		di - gstring handle

RETURN:		
		ax,bx - upper left of selected bounds

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
	srs	6/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetGStringBoundsToSelectedBounds		proc	near
	class	GrObjBodyClass
	uses	cx,dx,bp
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	sub	sp,size RectDWord
	mov	bp,sp
	call	GrObjBodyGetBoundsOfSelectedGrObjs
	mov	ax,ss:[bp].RD_left.low
	mov	bx,ss:[bp].RD_top.low
	mov	cx,ss:[bp].RD_right.low
	mov	dx,ss:[bp].RD_bottom.low
	sub	cx,ax				;width
	sub	dx,bx				;height
	push	ax,bx				;orig left top
	clr	ax,bx
	call	GrSetGStringBounds
	pop	ax,bx				;orig left top
	add	sp,size RectDWord

	.leave
	ret
GrObjBodySetGStringBoundsToSelectedBounds		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyTranslateBackToZeroZero
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply a translation to the gstring so that the objects 
		will be drawn within a rectangle that has an upper left
		of 0,0 and the lower right is the width and height of the
		selection bounds.

CALLED BY:	INTERNAL
		GrObjBodyExportSelectedGrObjs

PASS:		*ds:si - body
		di - gstring handle
		ax,bx - upper left of selected object bounds

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
	srs	9/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyTranslateBackToZeroZero		proc	far
	class	GrObjBodyClass
	uses	ax,bx,cx,dx,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject		>

	cwd 					;sign extending width
	pushdw	dxax				;width
	mov_tr	ax,bx				;height
	cwd					;sign extending height
	mov	bx,dx				;height high int
	popdw	dxcx				;dword width

	mov	si,ds:[si]
	add	si,ds:[si].GrObjBody_offset
	adddw	dxcx,ds:[si].GBI_bounds.RD_left
	adddw	bxax,ds:[si].GBI_bounds.RD_top

	negdw	dxcx					;left
	negdw	bxax					;top
	call	GrApplyTranslationDWord

	.leave
	ret
GrObjBodyTranslateBackToZeroZero		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyConvertSelectedGrObjsToBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Converts the selected grobjs into a single bitmap object

Pass:		*ds:si = GrObjBody

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 12, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; This constant is used to prevent the user from creating a bitmap which is
; too big to store.  There is an EC check on the size of a chunk array
; element and this should prevent the user from making that too big.  In
; non-EC, the user may run out of memory if the bitmap is too big.  The
; units for this constant are points, and this gives the user a 12-inch
; wide bitmap.  Since the default bitmap is 4-bit 72dpi, this will not
; violate the EC check.  Also, if the user were to change the resolution of
; a 12-inch bitmap to 600dpi, the EC check will not fail because the chunk
; array element size will still be small enough.  --JimG 6/14/94

; Actually, this is 12 1/12 (12.08333) inches.  This gives the user a little
; extra slop because the snap to grid may not exactly create an object that
; is 12.000 inches. --JimG 6/14/94
CONVERT_TO_BITMAP_MAX_WIDTH_LOW	=	870

GrObjBodyConvertSelectedGrObjsToBitmap	method dynamic	GrObjBodyClass,
				MSG_GB_CONVERT_SELECTED_GROBJS_TO_BITMAP
	uses	cx, dx, bp
	.enter

	; Check width of selected objects.  If they are too wide, then warn
	; the user with an error dialog.  --JimG 6/14/94
	
	sub	sp, size RectDWord
	mov	bp, sp
	
	mov	ax, MSG_GB_GET_BOUNDS_OF_SELECTED_GROBJS
	call	ObjCallInstanceNoLock			;Destroys: ax
	movdw	axbx, ss:[bp].RD_right
	subdw	axbx, ss:[bp].RD_left			;axbx = width
	add	sp, size RectDWord
	tst	ax					;High byte should be 0
	jnz	tooWide
	cmp	bx, CONVERT_TO_BITMAP_MAX_WIDTH_LOW	;Low byte <= limit
	jle	beginConversion

tooWide:
	mov	bx, handle convertToBitmapTooBigErrorString
	mov	ax, offset convertToBitmapTooBigErrorString
	call	GrObjBodyStandardError
	jmp	done
	
beginConversion:
	call	GBMarkBusy

	push	si					;save body chunk

	;
	;  Put some bogus value out there
	;
	clr	bp
	rept 	size PointDWFixed / 2
		push	bp
	endm
	mov	bp, sp

	;
	;	Generate the gstring represented by the selected grobjs
	;
	call	GrObjGlobalGetVMFile
	mov	cx, bx					;cx <- vm file
	mov	ax, MSG_GB_CREATE_GSTRING_TRANSFER_FORMAT
	call	ObjCallInstanceNoLock

	mov_tr	di,ax					;di <- vm block handle

	;    Specify the position and size of the new grobject and
	;    have initialize itself to the default attributes
	;
CheckHack <(size RectDWFixed) ge (size GrObjInitializeData)>
	sub	sp, size RectDWFixed - size PointDWFixed
	mov	bp,sp
	mov	ax, MSG_GB_GET_DWF_BOUNDS_OF_SELECTED_GROBJS
	call	ObjCallInstanceNoLock

if 1

	mov	ax, ss:[bp].RDWF_right.DWF_frac
	sub	ax, ss:[bp].RDWF_left.DWF_frac
	mov	cx, ss:[bp].RDWF_right.DWF_int.low
	sbb	cx, ss:[bp].RDWF_left.DWF_int.low
	rndwwf	cxax
	inc	cx

	mov	ax, ss:[bp].RDWF_bottom.DWF_frac
	sub	ax, ss:[bp].RDWF_top.DWF_frac
	mov	dx, ss:[bp].RDWF_bottom.DWF_int.low
	sbb	dx, ss:[bp].RDWF_top.DWF_int.low
	rndwwf	dxax
	inc	dx
endif

	clr	ax
	movwwf	ss:[bp].GOID_width, cxax
	movwwf	ss:[bp].GOID_height, dxax

	push	cx,dx					;save width,height

	;
	;	Delete the selected grobjs now that we're done with `em
	;
	mov	ax, MSG_META_DELETE
	call	ObjCallInstanceNoLock

	;
	;  ^lcx:dx <- new bitmap object
	;
	mov	cx, segment BitmapGuardianClass
	mov	dx, offset BitmapGuardianClass
	mov	ax, MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	mov	si,di					;si <- vm block handle
	push	cx,dx					;save new bitmap
	mov	cl, GST_VMEM
	call	GrLoadGString				;si <- GString
	mov	cx, si					;cx <- gstring
	pop	bx, si					;^lbx:si <- bitmap
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_INITIALIZE
	call	ObjMessage

	mov	bp, cx					;bp <- gstring
	pop	cx,dx					;cx,dx <- width,height
	add	sp,size RectDWFixed			;free stack frame

	mov	ax, MSG_BG_CREATE_VIS_BITMAP
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	mov_tr	ax, si					;ax <- grobj chunk
	mov	si, bp					;GString
	clr	di					;no gstate
	mov	dl,GSKT_KILL_DATA
	call	GrDestroyGString

	;    Notify object that it is complete and ready to go
	;
	mov_tr	si, ax					;^lbx:si <- grobj
	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Add the new grobject to the body and have it drawn.
	;    If you wish to add many grobjects and draw them all
	;    at once use MSG_GB_ADD_GROBJ instead.
	;

	mov	cx,bx					;new handle
	mov	dx,si					;new chunk
	pop	si					;body chunk
	mov	bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_ADD_GROBJ_THEN_DRAW
	call	ObjCallInstanceNoLock

	mov	al,HUM_NOW
	call	GrObjBodySendBecomeSelectedToChild

	call	GBMarkNotBusy

done:
	.leave
	ret
GrObjBodyConvertSelectedGrObjsToBitmap	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyConvertSelectedGrObjsToGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Converts the selected grobjs into a single gstring object

Pass:		*ds:si = GrObjBody

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 12, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyConvertSelectedGrObjsToGraphic	method dynamic	GrObjBodyClass,
				MSG_GB_CONVERT_SELECTED_GROBJS_TO_GRAPHIC
	uses	bp
	.enter

	call	GBMarkBusy

	;
	;  Put some bogus value out there
	;
	clr	bp
	rept 	size PointDWFixed / 2
		push	bp
	endm
	mov	bp, sp

	;
	;	Generate the gstring represented by the selected grobjs
	;
	call	GrObjGlobalGetVMFile
	mov	cx, bx					;cx <- vm file
	mov	ax, MSG_GB_CREATE_GSTRING_TRANSFER_FORMAT
	call	ObjCallInstanceNoLock

	add	sp, size PointDWFixed

	push	ax					;save block handle
	;
	;	Delete the selected grobjs now that we're done with `em
	;
	mov	ax, MSG_META_DELETE
	call	ObjCallInstanceNoLock

	pop	ax					;ax <- block handle
	call	GrObjBodyParseGString

	call	GBMarkNotBusy	

	.leave
	ret
GrObjBodyConvertSelectedGrObjsToGraphic	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCreatePolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Create a polygon

Pass:		*ds:si = GrObjBody

		bp - number of sides in created polygon
		cx,dx - height, width of polygon

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 12, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreatePolygon	method dynamic	GrObjBodyClass,	MSG_GB_CREATE_POLYGON
	uses	cx,dx,bp
	.enter

	call	GrObjBodyStartCreateCommon

	push	si					;save body chunk
	push	cx,dx,bp				;save dimensions,points

	mov	ax, MSG_GB_REMOVE_ALL_GROBJS_FROM_SELECTION_LIST
	call	ObjCallInstanceNoLock

	;
	;  Set up the initialize data
	;
	sub	sp, size GrObjInitializeData
	mov	bp, sp

CheckHack	<offset GOID_position eq 0>
	call	GrObjBodyGetWinCenter

	mov	ss:[bp].GOID_width.WWF_int, cx
	mov	ss:[bp].GOID_height.WWF_int, dx
	clr	cx
	mov	ss:[bp].GOID_width.WWF_frac, cx
	mov	ss:[bp].GOID_height.WWF_frac, cx

	;
	;  Create the new grobj
	;
	mov	cx, segment SplineGuardianClass
	mov	dx, offset SplineGuardianClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	;
	;  Have the guardian create its ward and initialize to the
	;  passed size
	;
	movdw	bxsi, cxdx				;^lbx:si <- guardian
	mov	ax, MSG_GO_INITIALIZE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GrObjInitializeData

	;    Notify object that it is complete and ready to go
	;

	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage


	;
	;  Tell the ward to generate polygon points
	;
	mov	ax, MSG_GOVG_GET_VIS_WARD_OD
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	pop	ax,di,bp				;ax <- width
							;di <- height
							;bp <- # points
	;
	; We have to do an IGNORE here, because otherwise, when we
	; UNDO the create, and then flush the actions, the
	; FINAL_OBJ_FREE will arrive at the spline before the freeing
	; action for the CLOSE_CURVE, and things will crash.
	;

	call	GrObjGlobalUndoIgnoreActions

	push	bx, si					;save guardian optr
	movdw	bxsi, cxdx				;^lbx:si <- VisSpline
	mov_tr	cx, ax					;cx <- width
	mov	dx, di					;dx <- height
	shr	cx					;cx <- 1/2 width
	shr	dx					;dx <- half height
	mov	ax, MSG_SPLINE_MAKE_POLYGON
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	call	GrObjGlobalUndoAcceptActions

	;    Add the new grobject to the body and have it drawn.
	;    If you wish to add many grobjects and draw them all
	;    at once use MSG_GB_ADD_GROBJ instead.
	;
	pop	cx, dx					;^lcx:dx <- guardian
	pop	si					;*ds:si <- GrObjBody
	mov	bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_ADD_GROBJ_THEN_DRAW
	call	ObjCallInstanceNoLock

	mov	al,HUM_NOW
	call	GrObjBodySendBecomeSelectedToChild

	call	GrObjBodyEndCreateCommon	

	.leave
	ret
GrObjBodyCreatePolygon	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCreateStar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Converts the selected grobjs into a single gstring object

Pass:		*ds:si = GrObjBody
		ss:[bp] - SplineMakeStarParams

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 12, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateStar	method dynamic	GrObjBodyClass,	MSG_GB_CREATE_STAR
	uses	cx,dx,bp
	.enter

	call	GrObjBodyStartCreateCommon

	push	si					;save body chunk
	push	bp					;save params

	mov	ax, MSG_GB_REMOVE_ALL_GROBJS_FROM_SELECTION_LIST
	call	ObjCallInstanceNoLock

	mov	cx, ss:[bp].SMSP_outerRadius.P_x	
	mov	dx, ss:[bp].SMSP_outerRadius.P_y

	shl	cx
	shl	dx

	;
	;  Set up the initialize data
	;
	sub	sp, size GrObjInitializeData
	mov	bp, sp

CheckHack	<offset GOID_position eq 0>
	call	GrObjBodyGetWinCenter

	mov	ss:[bp].GOID_width.WWF_int, cx
	mov	ss:[bp].GOID_height.WWF_int, dx
	clr	cx
	mov	ss:[bp].GOID_width.WWF_frac, cx
	mov	ss:[bp].GOID_height.WWF_frac, cx

	;
	;  Create the new grobj
	;
	mov	cx, segment SplineGuardianClass
	mov	dx, offset SplineGuardianClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	;
	;  Have the guardian create its ward and initialize to the
	;  passed size
	;
	movdw	bxsi, cxdx				;^lbx:si <- guardian
	mov	ax, MSG_GO_INITIALIZE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GrObjInitializeData

	;    Notify object that it is complete and ready to go
	;

	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	;
	;  Tell the ward to generate star points
	;
	mov	ax, MSG_GOVG_GET_VIS_WARD_OD
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bp					;ss:[bp] <- params

	call	GrObjGlobalUndoIgnoreActions

	pushdw	bxsi					;save guardian optr
	movdw	bxsi, cxdx				;^lbx:si <- VisSpline
	mov	ax, MSG_SPLINE_MAKE_STAR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	call	GrObjGlobalUndoAcceptActions


	;    Add the new grobject to the body and have it drawn.
	;    If you wish to add many grobjects and draw them all
	;    at once use MSG_GB_ADD_GROBJ instead.
	;
	popdw	cxdx					;^lcx:dx <- guardian
	pop	si					;*ds:si <- GrObjBody
	mov	bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_ADD_GROBJ_THEN_DRAW
	call	ObjCallInstanceNoLock

	mov	al, HUM_NOW
	call	GrObjBodySendBecomeSelectedToChild

	call	GrObjBodyEndCreateCommon	

	.leave
	ret
GrObjBodyCreateStar	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCreateGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Converts the selected grobjs into a single gstring object

Pass:		*ds:si = GrObjBody
		ss:[bp] - GrObjBodyCreateGrObjParams

Return:		^lcx:dx - new grobj

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 12, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateGrObj	method dynamic	GrObjBodyClass,	MSG_GB_CREATE_GROBJ

	uses	bp

	.enter

	call	GrObjBodyStartCreateCommon

	push	si					;save body chunk

	mov	ax, MSG_GB_REMOVE_ALL_GROBJS_FROM_SELECTION_LIST
	call	ObjCallInstanceNoLock

	pushdw	ss:[bp].GBCGP_class

CheckHack	<offset GOID_position eq 0>
CheckHack	<offset GOID_width eq GBCGP_width>
CheckHack	<offset GOID_height eq GBCGP_height>

	;
	; Gets the center of the body's window in PARENT coords
	;
	call	GrObjBodyGetWinCenter
	
	;
	; Do a simple transform so that the PointDWFixed at ss:bp points
	; to the upper-left-hand corner of the new object to be created
	; (since that is what MSG_GO_INITIALIZE requires).
	;
	
	movwwf	axcx, ss:[bp].GBCGP_width
	sarwwf	axcx					;half width
	cwd
	subdwf	ss:[bp].PDF_x, dxaxcx			;PDF_x = left edge
	
	movwwf	axcx, ss:[bp].GBCGP_height
	sarwwf	axcx					;half height
	cwd
	subdwf	ss:[bp].PDF_y, dxaxcx			;PDF_y = top edge

	;
	;  Create the new grobj
	;
	popdw	cxdx
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	movdw	bxsi, cxdx				;^lbx:si <- guardian
	mov	ax, MSG_GO_INITIALIZE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;    Notify object that it is complete and ready to go
	;
	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	;
	;    Add the new grobject to the body and have it drawn.
	;    If you wish to add many grobjects and draw them all
	;    at once use MSG_GB_ADD_GROBJ instead.
	;
	movdw	cxdx, bxsi				;^lcx:dx <- guardian
	pop	si					;*ds:si <- GrObjBody
	mov	bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_ADD_GROBJ_THEN_DRAW
	call	ObjCallInstanceNoLock

	mov	bp, HUM_NOW
	mov	ax, MSG_GB_ADD_GROBJ_TO_SELECTION_LIST
	call	ObjCallInstanceNoLock

	call	GrObjBodyEndCreateCommon	

	.leave
	ret
GrObjBodyCreateGrObj	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyStartCreateCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to begin a "create" operation:  start the
		undo chain, and mark the grobj busy

CALLED BY:	GrObjBodyCreatePolygon, GrObjBodyCreateStar,
		GrObjBodyCreateGrObj

PASS:		*ds:si - GrObjBodyClass object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 3/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyStartCreateCommon	proc near
		uses	cx, dx
		.enter
		mov	cx, handle createString
		mov	dx, offset createString
		call	GrObjGlobalStartUndoChain
		call	GBMarkBusy
		.leave
		ret
GrObjBodyStartCreateCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyEndCreateCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to end a "create" operation.  Mark the
		grobj not busy, and end the undo chain

CALLED BY:	GrObjBodyCreatePolygon, GrObjBodyCreateStar,
		GrObjBodyCreateGrObj

PASS:		*ds:si - GrObjBodyClass object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 3/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyEndCreateCommon	proc near
		call	GBMarkNotBusy
		call	GrObjGlobalEndUndoChain
		ret
GrObjBodyEndCreateCommon	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyImportHugeBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a vis bitmap object from the HugeBitmap

		NOTE:******
		The caller must
		have explicity set or cleared ATTR_GB_PASTE_CALL_BACK 
		before calling this routine.

CALLED BY:	INTERNAL
		GrObjBodyImport

PASS:		*ds:si - GrObjBody`
		bx - vm file handle of huge bitmap
		ax - vm block handle of huge bitmap
		ss:[bp] - PDF center of paste

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
	srs	3/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyImportHugeBitmap		proc	far
	uses	ax,bx,cx,dx,di,bp
	.enter

	call	GBMarkBusy

	push	ax					;vm blockhandle
	mov	cx, segment BitmapGuardianClass
	mov	dx, offset BitmapGuardianClass
	mov	ax, MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock
	pop	ax					;vm block handle

	call	GrObjBodyInitBitmapGuardianGeometryFromHugeBitmap

	call	GrObjBodyInitVisBitmapFromHugeBitmap

	;    Notify object that it is complete and ready to go
	;

	push	si					;body chunk
	movdw	bxsi,cxdx				;guardian
	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Add the new grobject to the body and have it drawn.
	;

	movdw	cxdx, bxsi				;^lcx:dx <- guardian
	pop	si					;*ds:si <- GrObjBody
	call	GrObjBodyCallPasteCallBack

	call	GBMarkNotBusy

	.leave
	ret
GrObjBodyImportHugeBitmap		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyInitBitmapGuardianGeometryFromHugeBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the position and size of bitmap guardian from
		a huge bitmap

CALLED BY:	INTERNAL
		GrObjBodyImportHugeBitmap

PASS:		*ds:si - GrObjBody
 		^lcx:dx - bitmap guardian
		bx - vm file handle of huge bitmap
		ax - vm block handle of huge bitmap
		ss:bp - PointDWFixed center of object
RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		Position the bitmap centered on passed PointDWFixed
		Calculate bounds of page minus margins (assumed to be 18 pts)
		If bottom bound is exceeded, move up
		If right bound is exceed, move left
		If top bound is exceeded, move down
		If left bound is exceeded, move right
		==> Results in too-large bitmap being positioned
		    at the page margin

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 9/93   	Initial version
	Don	5/2/00		Attempt to keep bitmap fully within the
				  bounds of the document, if possible
	jfh   9/15/03		Undo Don's centering & resizing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyInitBitmapGuardianGeometryFromHugeBitmap		proc	near
	class	GrObjBodyClass
	uses	ax,bx,cx,dx,ds,es,di,si
	.enter

	;    Some set-up work
	;

	sub	sp,size GrObjInitializeData
	mov	di,bp					;center stack frame
	mov	bp,sp

	pushdw	cxdx					;guardian od

	;    Initialize GOID_position to passed center
	;

;	push	ds,si
	mov	cx,ss
	mov	ds,cx
	mov	es,cx
	mov	si,di					;center stack frame
	mov	di,bp
	add	di,offset GOID_position
	MoveConstantNumBytes <size PointDWFixed>,cx
;	pop	ds,si
if 0
	;    Tempoarily adjust our bounds to account for margins
	;

	mov	di,ax					;vm block handle
	mov	si,ds:[si]
	add	si,ds:[si].GrObjBody_offset
	mov	ax,18
	cwd
	adddw	ds:[si].GBI_bounds.RD_left,dxax
	adddw	ds:[si].GBI_bounds.RD_top,dxax
	subdw	ds:[si].GBI_bounds.RD_right,dxax
	subdw	ds:[si].GBI_bounds.RD_bottom,dxax
endif
	;    Calculate the width and height of the bitmap so we
	;    can set it in the object and use it to calculate the
	;    upper left from the center.
	;

	mov	di,ax					;vm block handle

	call	GrGetHugeBitmapSize			;width->ax, height->bx
	clr	cx					;width frac
	movwwf	ss:[bp].GOID_width,axcx
	sarwwf	axcx
	cwd	
	subdwf	ss:[bp].GOID_position.PDF_x,dxaxcx
	mov	ax,bx					;height
	clr	cx					;height frac
	movdw	ss:[bp].GOID_height,axcx
	sardw	axcx
	cwd	
	subdwf	ss:[bp].GOID_position.PDF_y,dxaxcx
if 0
	;    Now see if the bitmap is position too far afield, and
	;    then adjust its position accordingly. Check, in sequence,
	;    bottom, right, top, left.
	;

	movdw	axcx,ss:[bp].GOID_height
	cwd
	adddwf	dxaxcx,ss:[bp].GOID_position.PDF_y
	subdw	dxax,ds:[si].GBI_bounds.RD_bottom
	tst	dx				;negative?
	js	checkRight			;yes - bottom bounds OK
	subdwf	ss:[bp].GOID_position.PDF_y,dxaxcx
checkRight:
	movdw	axcx,ss:[bp].GOID_width
	cwd
	adddwf	dxaxcx,ss:[bp].GOID_position.PDF_x
	subdw	dxax,ds:[si].GBI_bounds.RD_right
	tst	dx				;negative?
	js	checkTop			;yes - right bounds OK
	subdwf	ss:[bp].GOID_position.PDF_x,dxaxcx
checkTop:
	movdw	dxax,ds:[si].GBI_bounds.RD_top
	clr	cx
	subdwf	dxaxcx,ss:[bp].GOID_position.PDF_y
	tst	dx				;negative?
	js	checkLeft			;yes - top bounds OK
	adddwf	ss:[bp].GOID_position.PDF_y,dxaxcx
checkLeft:
	movdw	dxax,ds:[si].GBI_bounds.RD_left
	clr	cx
	subdwf	dxaxcx,ss:[bp].GOID_position.PDF_x
	tst	dx				;negative?
	js	doneBounds			;yes - left bounds OK
	adddwf	ss:[bp].GOID_position.PDF_x,dxaxcx
doneBounds:		

	;    If the bitmap is too large to fit on the screen, the upper-left
	;    of the bitmap is now on the upper-left of the margin. So, we
	;    calculate the scale factor to make the bitmap fully visible.
	;

	mov	di, 0xffff			;initialize to 100% (almost)
	movdw	axdx,ds:[si].GBI_bounds.RD_right
	subdw	axdx,ds:[si].GBI_bounds.RD_left	;parent's width -> ax:dx
	tst	ax				;if upper word non-zero
	jnz	checkHeight			;...it will fit
	cmp	dx, ss:[bp].GOID_width.WWF_int	;if parent is wider than bitmap
	jae	checkHeight			;...it will fit
	clr	cx
	movwwf	bxax, ss:[bp].GOID_width
	call	GrUDivWWFixed			;scale factor -> dx.cx
EC <	tst	dx							>
EC <	ERROR_NZ BUG_IN_DIMENSIONS_CALC					>
	mov	di, cx				;scale factor -> di
checkHeight:
	movdw	axdx,ds:[si].GBI_bounds.RD_bottom
	subdw	axdx,ds:[si].GBI_bounds.RD_top	;parent's height -> ax:dx
	tst	ax				;if upper word non-zero
	jnz	doneScaleCheck			;...it will fit
	cmp	dx, ss:[bp].GOID_height.WWF_int	;if parent is talled than bitmap
	jae	doneScaleCheck			;...it will fit
	clr	cx
	movwwf	bxax, ss:[bp].GOID_height
	call	GrUDivWWFixed			;scale factor -> dx.cx
EC <	tst	dx							>
EC <	ERROR_NZ BUG_IN_DIMENSIONS_CALC					>
	cmp	cx, di				;if new scale fraction is larger
	ja	doneScaleCheck			;...then use the other one
	mov	di, cx				;...else use new one
doneScaleCheck:

	;    Undo bounds damage done ealier
	;

	mov	ax,18
	cwd
	subdw	ds:[si].GBI_bounds.RD_left,dxax
	subdw	ds:[si].GBI_bounds.RD_top,dxax
	adddw	ds:[si].GBI_bounds.RD_right,dxax
	adddw	ds:[si].GBI_bounds.RD_bottom,dxax
endif
	;    Inialize that object - first its size
	;

	popdw	bxsi				;restore guardian OD
;	push	di				;save scale factor
	mov	di,mask MF_STACK
	mov	dx,size GrObjInitializeData
	mov	ax,MSG_GO_INITIALIZE
	call	ObjMessage
;	pop	di				;restore scale factor
	add	sp,size GrObjInitializeData
if 0
	;    ...then its scale factor
	;
	
	cmp	di, 0xfff
	je	doneScale
	push	ds
	call	ObjLockObjBlock
	push	bx, si
	mov	ds, ax
	sub	sp, size GrObjScaleData
	mov	bp, sp
	mov	ss:[bp].GOSD_xScale.WWF_int, 0
	mov	ss:[bp].GOSD_xScale.WWF_frac, di
	mov	ss:[bp].GOSD_yScale.WWF_int, 0
	mov	ss:[bp].GOSD_yScale.WWF_frac, di
	mov	cl, HANDLE_LEFT_TOP
	call	GrObjScaleNormalRelativeOBJECT
	add	sp, size GrObjScaleData
	pop	bx, si
	call	MemUnlock
	pop	ds
doneScale:
endif
	;    ...finally, its attributes
	;

	clr	di
	mov	ax,MSG_GO_INIT_TO_DEFAULT_ATTRS
	call	ObjMessage

	;    Calculate parent dimensions now that we have
	;    geometry and attributes
	;
	
	clr	di
	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjMessage

	clr	di
	mov	ax,MSG_GOVG_VIS_BOUNDS_SETUP
	call	ObjMessage

	.leave
	ret
GrObjBodyInitBitmapGuardianGeometryFromHugeBitmap		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyInitVisBitmapFromHugeBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	INTERNAL 
		GrObjBodyImportHugeBitmap

PASS: 
		^lcx:dx - bitmap guardian
		bx - vm file handle of huge bitmap
		ax - vm block handle of huge bitmap

RETURN:		

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
	srs	3/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyInitVisBitmapFromHugeBitmap		proc	near
	uses	ax,bx,cx,dx,si,di
	.enter

	pushdw	bxax					;vm file/block
	movdw	bxsi,cxdx				;guardian od
	mov	di,mask MF_CALL				
	mov	ax,MSG_GOVG_GET_VIS_WARD_OD
	call	ObjMessage

	clr	di					;MessgaeFlags
	movdw	bxsi,cxdx				;ward
	popdw	cxdx					;vm file /block
	mov	ax,MSG_VIS_BITMAP_REPLACE_WITH_TRANSFER_FORMAT
	call	ObjMessage

	.leave
	ret
GrObjBodyInitVisBitmapFromHugeBitmap		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyParseGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just take the whole gstring and cram it into one gstring object

		NOTE:******
		The caller must
		have explicity set or cleared ATTR_GB_PASTE_CALL_BACK 
		before calling this routine.

CALLED BY:	INTERNAL
		GrObjBodyImport
		GrObjBodyPasteCommon
		
PASS:		
		*ds:si = GrObjBody
		bx - VM file handle of gstring
		ax - vm block handle of gstring
		ss:[bp] - PointDFixed position to center the gstring on.

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
	srs	9/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyParseGString		proc	far
	uses	ax, bx, cx, dx, bp, di, si
	.enter

	push	si					;body chunk
	call	GBMarkBusy

	mov	di,bp					;center stack frame
	sub	sp,size GrObjInitializeData
	mov	bp,sp
	call	GrObjBodyParseGStringSetGOID
	jc	tooBig

	;    Create our gstring object and initialize it.
	;

	pushdw	bxax					;vm file,block handle
	mov	cx,segment GStringClass
	mov	dx,offset GStringClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	movdw	bxsi,cxdx				;new gstring obj od
	mov	di,mask MF_FIXUP_DS or mask MF_STACK
	mov	dx,size GrObjInitializeData
	mov	ax,MSG_GO_INITIALIZE
	call	ObjMessage
	popdw	cxdx					;vm file,block handle
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GSO_SET_GSTRING
	call	ObjMessage
	add	sp,size GrObjInitializeData

	;    Notify object that it is complete and ready to go
	;

	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Add the new grobject to the body and have it drawn.
	;

	movdw	cxdx,bxsi				;obj od
	pop	si					;body chunk
	call	GrObjBodyCallPasteCallBack

	call	GBMarkNotBusy

done:
	.leave
	ret

tooBig:
	;ERROR IGNORED ???
	add	sp,size GrObjInitializeData
	pop	si					;body chunk
	call	GBMarkNotBusy
	jmp	done

GrObjBodyParseGString		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyParseGStringSetGOID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set position, width and height in GrObjInitializeData
		structure

CALLED BY:	INTERNAL
		GrObjBodyParseGString

PASS:		ss:bp - GrObjInitializeData
		ax - vm block handle of gstring
		bx - vm file handle of gstring
		ss:di - PointDWFixed - center of object

RETURN:		
		clc - GrObjInitializeData initalized
		stc - gstring bounds to big

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
	srs	3/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyParseGStringSetGOID		proc	near
	uses	ax,bx,cx,dx,si,ds,es,di
	.enter

	;    Initialize GOID_position to passed center
	;

	mov	cx,ss
	mov	ds,cx
	mov	es,cx
	mov	si,di					;center stack frame
	mov	di,bp
	add	di,offset GOID_position
	MoveConstantNumBytes <size PointDWFixed>,cx

	;   Load the gstring to parse
	;

	mov	si,ax					;vm block handle
	mov	cl, GST_VMEM
	call	GrLoadGString

	;    Calculate the width and height of the gstring so we
	;    can set it in the object and use it to calculate the
	;    upper left from the center.
	;

	clr	dx,di					;no flags, no gstate
	call	GrGetGStringBounds
	jc	destroyGString
	push	dx					;bottom
	xchg	ax,cx					;right, left
	sub	ax,cx					;right-left
	clr	cx					;width frac
	movwwf	ss:[bp].GOID_width,axcx
	sarwwf	axcx
	cwd	
	subdwf	ss:[bp].GOID_position.PDF_x,dxaxcx
	pop	ax					;bottom
	sub	ax,bx					;bottom-top
	clr	cx					;height frac
	movdw	ss:[bp].GOID_height,axcx
	sardw	axcx
	cwd	
	subdwf	ss:[bp].GOID_position.PDF_y,dxaxcx
	clc						;no error

destroyGString:
	;    Don't need gstring handle anymore
	;

	pushf						;gstring bounds error
	clr	di					;no gstate
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString
	popf						;gstring bounds error

	.leave
	ret
GrObjBodyParseGStringSetGOID		endp



ifdef	DONT_DELETE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyParseGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert output elements of gstring into grobjs

CALLED BY:	INTERNAL
		GrObjBodyImport
		GrObjBodyPasteCommon
		GrObjBodyConvertSelectedGrObjsToGraphic
		
PASS:		
		*ds:si = GrObjBody
		bx - VM file
		ax - block handle
		ss:[bp] - PointDFixed position to center the gstring on.

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
	srs	9/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjBodyParseGStringStruc	struct
	GOBPGS_body	optr
GrObjBodyParseGStringStruc	ends

GrObjBodyParseGString		proc	far
	uses	ax, bx, cx, dx, bp, di,es
	.enter

	call	GBMarkBusy

	push	si					;body chunk

	;  Clear the selection list
	;

	push	ax					; transfer block
	mov	ax, MSG_GB_REMOVE_ALL_GROBJS_FROM_SELECTION_LIST
	call	ObjCallInstanceNoLock

	;   Load the gstring to parse
	;

	pop	si					;vm block handle
	mov	cl, GST_VMEM
	call	GrLoadGString

	clr	di					;no window
	call	GrCreateState

	;    Apply translation of negative of the gstring bounds center
	;    so that we can position the gstring where we want it.
	;

	push	ds					;body segment
	sub	sp,size RectDWord
	segmov	ds,ss
	mov	bx,sp
	clr	dx
	call	GrGetGStringBoundsDWord
	movdw	dxcx,ds:[bx].RD_right
	adddw	dxcx,ds:[bx].RD_left
	sardw	dxcx
	pushdw	dxcx					;x of gstring center
	movdw	dxcx,ds:[bx].RD_bottom
	adddw	dxcx,ds:[bx].RD_top
	sardw	dxcx
	movdw	bxax,dxcx				;y of gstring center
	popdw	dxcx					;x of gstring center
	negdw	dxcx
	negdw	bxax
	call	GrApplyTranslationDWord
	add	sp,size RectDWord
	pop	ds					;body segment

	;    Translation to the center that was passed in.
	;

	mov	cx,ss:[bp].PDF_x.DWF_int.low
	mov	dx,ss:[bp].PDF_x.DWF_int.high
	mov	ax,ss:[bp].PDF_y.DWF_int.low
	mov	bx,ss:[bp].PDF_y.DWF_int.high
	call	GrApplyTranslationDWord
	mov	cx,ss:[bp].PDF_x.DWF_frac
	clr	dx
	mov	ax,ss:[bp].PDF_y.DWF_frac
	clr	bx
	call	GrApplyTranslation

	;    Old geodraw gstrings are full of GrSetDefaultTransforms, so
	;    I must initialize the default transform to my translation
	;    otherwise it would get lost.
	;

	call	GrInitDefaultTransform

	;    Parse gstring stopping at each output element
	;

	pop	dx					;body chunk
	push	dx					;body chunk 
	sub	sp,size GrObjBodyParseGStringStruc
	mov	bp,sp
	mov	bx,ds:[LMBH_handle]
	mov	ss:[bp].GOBPGS_body.handle,bx
	mov	ss:[bp].GOBPGS_body.chunk,dx
	mov	dx,mask GSC_OUTPUT
	mov	bx,SEGMENT_CS				; bx <- vseg if XIP'ed
	mov	cx,offset GrObjBodyParseGStringCB
	push	ds:[LMBH_handle]			;body handle
	call	GrParseGString
	pop	bx					;body handle
	call	MemDerefDS	
	add	sp,size GrObjBodyParseGStringStruc

	;    Clean up gstring and gstate
	;

	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString
	call	GrDestroyState

	pop	si					;body chunk
	call	GBMarkNotBusy

	.leave
	ret
GrObjBodyParseGString		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyParseGStringCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an grobj for the output element that was stopped on

CALLED BY:	GrParseGString

PASS:		
		ds:si - pointer to element
		ss:bx - GrObjBodyParseGStringStruc

RETURN:		
		ax - FALSE to continue parsing
		ds - element segment

DESTROYED:	
		ax,cx,dx,bp,es,di - ok because call back

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyParseGStringCB		proc	far
	.enter

	;    Call instantiate routine based on gstring output element
	;

	push	di					;gstate
	mov	bp,bx				;GrObjBodyParseGStringStruc
	segmov	es,cs
	mov	di,offset GStringOpTable
	mov	al,ds:[si]				;GString Op
	mov	cx,length GStringOpTable
	repne	scasb
	mov	bx,di					;offset past op
	pop	di					;gstate
	jnz	exit
	sub	bx,offset GStringOpTable+1		;Offset from begining
							; of GStringOpTable
	shl	bx					;Offset into
							; ObjectRoutineTable
							; which is a word table
	add	bx,offset ObjectRoutineTable 
	call	es:[bx]					; near call (XIP OK)

	;    Add the new grobject to the body and have it drawn.
	;

	push	ds					;element segment
	mov	bx,ss:[bp].GOBPGS_body.handle
	mov	si,ss:[bp].GOBPGS_body.chunk
	clr 	di
	mov	bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_ADD_GROBJ_THEN_DRAW
	call	ObjMessage

	movdw	bxsi,cxdx				;guardian od
	mov	dl, HUM_MANUAL
	clr	di
	mov	ax,MSG_GO_BECOME_SELECTED
	call	ObjMessage
	pop	ds					;element segment

exit:
	mov	ax,FALSE

	.leave
	ret

GrObjBodyParseGStringCB		endp

GStringOpTable	byte	\
	GR_DRAW_RECT,
	GR_DRAW_ELLIPSE,
	GR_DRAW_LINE,
	GR_DRAW_ROUND_RECT,
	GR_FILL_RECT,
	GR_FILL_ELLIPSE,
	GR_FILL_ROUND_RECT,
	GR_DRAW_BITMAP,
	GR_FILL_BITMAP

ObjectRoutineTable	word \
	offset GrObjBodyCreateGrObjFromGrDrawRect,	
	offset GrObjBodyCreateGrObjFromGrDrawEllipse,	
	offset GrObjBodyCreateGrObjFromGrDrawLine,	
	offset GrObjBodyCreateGrObjFromGrDrawRoundRect,
	offset GrObjBodyCreateGrObjFromGrFillRect,	
	offset GrObjBodyCreateGrObjFromGrFillEllipse,	
	offset GrObjBodyCreateGrObjFromGrFillRoundRect,
	offset GrObjBodyCreateGrObjFromGrDrawBitmap,
	offset GrObjBodyCreateGrObjFromGrDrawBitmap

.assert (length GStringOpTable eq length ObjectRoutineTable)





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCreateGrObjFromGrDrawRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a RectClass object from the gstring element

CALLED BY:	INTERNAL
		GrObjBodyParseGStringCB

PASS:		
		ds:si - GString element pointer
		di - gstate
		ss:bp - GrObjBodyParseGStringStruc

RETURN:		
		^lcx:dx - new object

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

		MUST BE NEAR as it is called with "call es:[bx]"

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateGrObjFromGrDrawRect		proc	near
	.enter

	mov	cx,segment RectClass
	mov	dx,offset RectClass
	add	si,offset ODR_x1
	call	GrObjBodyCreateRectBasedGrObjectFromGStringElement
	sub	si,offset ODR_x1

	;    If was just a draw rect so blot out the area
	;

	call	GrObjBodyMaskOutAreaAttributes

	.leave
	ret
GrObjBodyCreateGrObjFromGrDrawRect		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCreateGrObjFromGrDrawEllipse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a EllipseClass object from the gstring element

CALLED BY:	INTERNAL
		GrObjBodyParseGStringCB

PASS:		
		ds:si - GString element pointer
		di - gstate
		ss:bp - GrObjBodyParseGStringStruc

RETURN:		
		^lcx:dx - new object

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

		MUST BE NEAR as it is called with "call es:[bx]"

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateGrObjFromGrDrawEllipse		proc	near
	.enter

	mov	cx,segment EllipseClass
	mov	dx,offset EllipseClass
	add	si,offset ODE_x1
	call	GrObjBodyCreateRectBasedGrObjectFromGStringElement
	sub	si,offset ODE_x1

	;    If was just a draw ellipse so blot out the area
	;

	call	GrObjBodyMaskOutAreaAttributes

	.leave
	ret
GrObjBodyCreateGrObjFromGrDrawEllipse		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCreateGrObjFromGrDrawRoundRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a RoundedRectClass object from the gstring element

CALLED BY:	INTERNAL
		GrObjBodyParseGStringCB

PASS:		
		ds:si - GString element pointer
		di - gstate
		ss:bp - GrObjBodyParseGStringStruc

RETURN:		
		^lcx:dx - new object

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

		MUST BE NEAR as it is called with "call es:[bx]"

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateGrObjFromGrDrawRoundRect		proc	near
	uses	ax,bx,si,di
	.enter

	mov	cx,segment RoundedRectClass
	mov	dx,offset RoundedRectClass
	add	si,offset ODRR_x1
	call	GrObjBodyCreateRectBasedGrObjectFromGStringElement
	sub	si,offset ODRR_x1

	mov	bx,cx					;new obj handle
	mov	cx,ds:[si].ODRR_radius
	mov	si,dx					;new obj chunk
	clr	di
	mov	ax,MSG_RR_SET_RADIUS
	call	ObjMessage
	mov	cx,bx					;new obj handle

	;    If was just a draw rounded rect so blot out the area
	;

	call	GrObjBodyMaskOutAreaAttributes

	.leave
	ret
GrObjBodyCreateGrObjFromGrDrawRoundRect		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCreateGrObjFromGrDrawLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a LineClass object from the gstring element

CALLED BY:	INTERNAL
		GrObjBodyParseGStringCB

PASS:		
		ds:si - GString element pointer
		di - gstate
		ss:bp - GrObjBodyParseGStringStruc

RETURN:		
		^lcx:dx - new object

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

		MUST BE NEAR as it is called with "call es:[bx]"

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateGrObjFromGrDrawLine		proc	near
	.enter

	mov	cx,segment LineClass
	mov	dx,offset LineClass
	add	si,offset ODL_x1
	call	GrObjBodyCreateRectBasedGrObjectFromGStringElement
	sub	si,offset ODL_x1

	.leave
	ret
GrObjBodyCreateGrObjFromGrDrawLine		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMaskOutAreaAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the area mask of the object to SDM_0.
		Used for DRAW gstring elements.

CALLED BY:	INTERNAL
		GrObjBodyCreateGrObjFromGrDrawRect
		GrObjBodyCreateGrObjFromGrDrawEllipse
		GrObjBodyCreateGrObjFromGrDrawArc
		GrObjBodyCreateGrObjFromGrDrawLine
		GrObjBodyCreateGrObjFromGrDrawRoundRect
	
PASS:		
		^lcx:dx - object
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
	srs	9/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMaskOutAreaAttributes		proc	near
	uses	ax,bx,cx,di,si
	.enter

	movdw	bxsi,cxdx				;object od
	clr	di
	mov	cl,SDM_0
	mov	ax,MSG_GO_SET_AREA_MASK
	call	ObjMessage

	.leave
	ret
GrObjBodyMaskOutAreaAttributes		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCreateGrObjFromGrFillRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a RectClass object from the gstring element

CALLED BY:	INTERNAL
		GrObjBodyParseGStringCB

PASS:		
		ds:si - GString element pointer
		di - gstate
		ss:bp - GrObjBodyParseGStringStruc

RETURN:		
		^lcx:dx - new object

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

		MUST BE NEAR as it is called with "call es:[bx]"

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateGrObjFromGrFillRect		proc	near
	.enter

	mov	cx,segment RectClass
	mov	dx,offset RectClass
	add	si,offset ODR_x1
	call	GrObjBodyCreateRectBasedGrObjectFromGStringElement
	sub	si,offset ODR_x1

	;    If was just a fill rect so blot out the line
	;

	call	GrObjBodyMaskOutLineAttributes

	.leave
	ret
GrObjBodyCreateGrObjFromGrFillRect		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCreateGrObjFromGrFillEllipse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a EllipseClass object from the gstring element

CALLED BY:	INTERNAL
		GrObjBodyParseGStringCB

PASS:		
		ds:si - GString element pointer
		di - gstate
		ss:bp - GrObjBodyParseGStringStruc

RETURN:		
		^lcx:dx - new object

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

		MUST BE NEAR as it is called with "call es:[bx]"

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateGrObjFromGrFillEllipse		proc	near
	.enter

	mov	cx,segment EllipseClass
	mov	dx,offset EllipseClass
	add	si,offset ODE_x1
	call	GrObjBodyCreateRectBasedGrObjectFromGStringElement
	sub	si,offset ODE_x1

	;    If was just a fill ellipse so blot out the line
	;

	call	GrObjBodyMaskOutLineAttributes

	.leave
	ret
GrObjBodyCreateGrObjFromGrFillEllipse		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCreateGrObjFromGrFillRoundRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a RoundedRectClass object from the gstring element

CALLED BY:	INTERNAL
		GrObjBodyParseGStringCB

PASS:		
		ds:si - GString element pointer
		di - gstate
		ss:bp - GrObjBodyParseGStringStruc

RETURN:		
		^lcx:dx - new object

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

		MUST BE NEAR as it is called with "call es:[bx]"

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateGrObjFromGrFillRoundRect		proc	near
	uses	ax,bx,si,di
	.enter

	mov	cx,segment RoundedRectClass
	mov	dx,offset RoundedRectClass
	add	si,offset ODRR_x1
	call	GrObjBodyCreateRectBasedGrObjectFromGStringElement
	sub	si,offset ODRR_x1

	mov	bx,cx					;new obj handle
	mov	cx,ds:[si].ODRR_radius
	mov	si,dx					;new obj chunk
	clr	di
	mov	ax,MSG_RR_SET_RADIUS
	call	ObjMessage
	mov	cx,bx					;new obj handle

	;    If was just a fill rounded rect so blot out the line
	;

	call	GrObjBodyMaskOutLineAttributes

	.leave
	ret
GrObjBodyCreateGrObjFromGrFillRoundRect		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMaskOutLineAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the line mask of the object to SDM_0.
		Used for FILL gstring elements.

CALLED BY:	INTERNAL
		GrObjBodyCreateGrObjFromGrFillRect
		GrObjBodyCreateGrObjFromGrFillEllipse
		GrObjBodyCreateGrObjFromGrFillArc
		GrObjBodyCreateGrObjFromGrFillLine
		GrObjBodyCreateGrObjFromGrFillRoundRect
	
PASS:		
		^lcx:dx - object
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
	srs	9/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMaskOutLineAttributes		proc	near
	uses	ax,bx,cx,di,si
	.enter

	movdw	bxsi,cxdx				;object od
	clr	di
	mov	cl,SDM_0
	mov	ax,MSG_GO_SET_LINE_MASK
	call	ObjMessage

	.leave
	ret
GrObjBodyMaskOutLineAttributes		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCreateRectBasedGrObjectFromGStringElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a grobj of the passed class from the data
		in the gstring element.

CALLED BY:	INTERNAL
		GrObjBodyCreateGrObjFromGrDrawRect
		GrObjBodyCreateEllipseFromGStringElement
		GrObjBodyCreateLineFromGStringElement

PASS:		
		ds:si - pointer to x1 field of rect in gstring element
		cx:dx - class of object to create
		di - gstate with attributes
		ss:bp - GrObjBodyParseGStringStruc

RETURN:		
		cx:dx - optr of new object

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
	srs	9/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateRectBasedGrObjectFromGStringElement		proc	near
	uses	ax,bx,di,si
	.enter

	push	si,di				;GStringElement offset,gstate
	mov	bx,ss:[bp].GOBPGS_body.handle
	mov	si,ss:[bp].GOBPGS_body.chunk
	mov	di,mask MF_CALL
	mov	ax, MSG_GB_INSTANTIATE_GROBJ
	call	ObjMessage
	pop	si,di				;GStringElement offset,gstate

	;    Initialize the geometry of the object
	;

	call	GrObjBodyInitRectBasedGrObjFromGStringElement

	;    Get attributes from gstate and set them in object
	;

	call	GrObjBodySetAreaAttributesFromGState
	call	GrObjBodySetLineAttributesFromGState

	;    Calculate parent dimensions now that we have
	;    geometry and attributes
	;
	
	movdw	bxsi,cxdx				;new od
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjMessage

	;    Notify object that it is complete and ready to go
	;


	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	movdw	cxdx,bxsi				;new od

	.leave
	ret
GrObjBodyCreateRectBasedGrObjectFromGStringElement		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyInitRectBasedGrObjFromGStringElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the geometry of a grobject from a pointer
		to a gstring element.

CALLED BY:	INTERNAL
		GrObjBodyCreateRectBasedGrObjectFromGStringElement

PASS:	
		ds:si - pointer to x1 field of rect in gstring element
		di - gstate handle
		cx:dx - optr of object
		ss:bp - GrObjBodyParseGStringStruc

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
	srs	9/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpGrObjBodyRect	struct
	OGOBR_x1	word	
	OGOBR_y1	word	
	OGOBR_x2	word	
	OGOBR_y2	word	
OpGrObjBodyRect	ends

GrObjBodyInitRectBasedGrObjFromGStringElement		proc	near
	uses	ax,bx,cx,dx,si,bp,di,ds,es
	.enter

	;    Create stack frame for initializing object
	;

	sub	sp,size BasicInit
	mov	bp,sp
	push	cx,dx					;new od

	;    Calc the width and height of the new object
	;

	clr	ax
	mov	ss:[bp].BI_width.WWF_frac,ax
	mov	ss:[bp].BI_height.WWF_frac,ax
	mov	ax,ds:[si].OGOBR_x2
	sub	ax,ds:[si].OGOBR_x1
	mov	ss:[bp].BI_width.WWF_int,ax
	mov	ax,ds:[si].OGOBR_y2
	sub	ax,ds:[si].OGOBR_y1
	mov	ss:[bp].BI_height.WWF_int,ax

	;    Calculate the center of the object in the gstate's 
	;    coordinate system
	;

	mov	ax,ss:[bp].BI_width.WWF_int
	clr	bx
	shrwwf	axbx
	add	ax,ds:[si].OGOBR_x1
	cwd
	movdwf	ss:[bp].BI_center.PDF_x,dxaxbx
	mov	ax,ss:[bp].BI_height.WWF_int
	clr	bx
	shrwwf	axbx
	add	ax,ds:[si].OGOBR_y1
	cwd
	movdwf	ss:[bp].BI_center.PDF_y,dxaxbx
	segmov	es,ss
	mov	dx,bp
	addnf	dx,<offset BI_center>
	call	GrTransformDWFixed

	;    Get transform from gstate into BI_transform
	;

	sub	sp,size TransMatrix
	segmov	ds,ss				;TransMatrix segment
	mov	si,sp				;TransMatrix offset
	call	GrGetTransform
	mov	di,bp				;BasicInit frame
	add	di,offset BI_transform
	MoveConstantNumBytes <size GrObjTransMatrix>, cx
	add	sp,size TransMatrix

PrintMessage <STEVE: handle zero scale factor case here>

	;    Initialize object
	;

	pop	bx,si					;new od
	clr	di
	mov	ax,MSG_GO_INIT_BASIC_DATA
	call	ObjMessage
	add	sp,size BasicInit

	.leave
	ret
GrObjBodyInitRectBasedGrObjFromGStringElement		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetAreaAttributesFromGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get area attributes from the gstate and set them in 
		the object	

CALLED BY:	INTERNAL
		GrObjBodyCreateRectBasedGrObjectFromGStringElement

PASS:		
		di - gstate
		bx:si - object

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
	srs	9/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetAreaAttributesFromGState		proc	near
	uses	ax,bx,dx,bp,di,si
	.enter

	sub	sp,size GrObjBaseAreaAttrElement
	mov	bp,sp
	call	GrGetAreaColor
	mov	ss:[bp].GOBAAE_r,al
	mov	ss:[bp].GOBAAE_g,bl
	mov	ss:[bp].GOBAAE_b,bh
	mov	al,GMT_ENUM
	call	GrGetAreaMask
	mov	ss:[bp].GOBAAE_mask,al
	call	GrGetMixMode
	mov	ss:[bp].GOBAAE_drawMode,al
	call	GrGetAreaPattern
	mov	{word}ss:[bp].GOBAAE_pattern,ax

	mov	ss:[bp].GOBAAE_aaeType, GOAAET_BASE
	mov	ss:[bp].GOBAAE_areaInfo, mask GOAAIR_TRANSPARENT

	clr	ax
	mov	ss:[bp].GOBAAE_reservedByte,al
	mov	ss:[bp].GOBAAE_reserved,ax

	mov	al,0xff
	mov	ss:[bp].GOBAAE_backR,al
	mov	ss:[bp].GOBAAE_backG,al
	mov	ss:[bp].GOBAAE_backB,al

	movdw	bxsi,cxdx				;new od
	mov	di,mask MF_STACK			;MessageFlags
	mov	dx,size GrObjBaseAreaAttrElement
	mov	ax,MSG_GO_SET_AREA_ATTR
	call	ObjMessage

	add	sp,size GrObjBaseAreaAttrElement
	.leave
	ret
GrObjBodySetAreaAttributesFromGState		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetLineAttributesFromGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get line attributes from the gstate and set them in 
		the object	

CALLED BY:	INTERNAL
		GrObjBodyCreateRectBasedGrObjectFromGStringElement

PASS:		
		di - gstate
		bx:si - object

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
	srs	9/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetLineAttributesFromGState		proc	near
	uses	ax,bx,dx,bp,si,di
	.enter

	mov	si,dx					;object chunk

	sub	sp,size GrObjBaseLineAttrElement
	mov	bp,sp
	call	GrGetLineColor
	mov	ss:[bp].GOBLAE_r,al
	mov	ss:[bp].GOBLAE_g,bl
	mov	ss:[bp].GOBLAE_b,bh
	mov	al,GMT_ENUM
	call	GrGetLineMask
	mov	ss:[bp].GOBLAE_mask,al
	call	GrGetLineEnd
	mov	ss:[bp].GOBLAE_end,al
	call	GrGetLineJoin
	mov	ss:[bp].GOBLAE_join,al
	call	GrGetLineStyle
	mov	ss:[bp].GOBLAE_style,al
	call	GrGetLineWidth
	mov	ss:[bp].GOBLAE_width.WWF_int,dx
	mov	ss:[bp].GOBLAE_width.WWF_frac,ax
	call	GrGetMiterLimit
	mov	ss:[bp].GOBLAE_miterLimit.WWF_int,bx
	mov	ss:[bp].GOBLAE_miterLimit.WWF_frac,ax
	mov	ss:[bp].GOBLAE_laeType, GOLAET_BASE

	clr	ax
	mov	ss:[bp].GOBLAE_reserved,ax
	mov	ss:[bp].GOBLAE_lineInfo,al
	mov	ss:[bp].GOBLAE_arrowheadAngle,al
	mov	ss:[bp].GOBLAE_arrowheadLength,al

	mov	bx,cx					;object handle
	mov	di,mask MF_STACK			;MessageFlags
	mov	dx,size GrObjBaseLineAttrElement
	mov	ax,MSG_GO_SET_LINE_ATTR
	call	ObjMessage

	add	sp,size GrObjBaseLineAttrElement

	.leave
	ret
GrObjBodySetLineAttributesFromGState		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCreateGrObjFromGrDrawBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a BitmapGuardianClass object from the gstring element

CALLED BY:	INTERNAL
		GrObjBodyParseGStringCB

PASS:		
		ds:si - GString element pointer
		di - gstate
		ss:bp - GrObjBodyParseGStringStruc

RETURN:		
		^lcx:dx - new object
		ds - segment of last slice of bitmap

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

		MUST BE NEAR as it is called with "call es:[bx]"

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateGrObjFromGrDrawBitmap		proc	near
	uses	ax,bx,es,bp,di
	.enter

	push	si					;element offset
	push	di					;gstate
	mov	cx,segment BitmapGuardianClass
	mov	dx,offset BitmapGuardianClass
	mov	bx,ss:[bp].GOBPGS_body.handle
	mov	si,ss:[bp].GOBPGS_body.chunk
	mov	di,mask MF_CALL
	mov	ax, MSG_GB_INSTANTIATE_GROBJ
	call	ObjMessage
	pop	di					;gstate
	pop	si					;element offset
	pushdw	cxdx					;guardian od

	call	GrObjBodyInitBitmapGuardianFromGStringElement

	call	GrObjBodyGetVisBitmapGState

	;    Fill in the mask so that our bitmap will show up
	;
	
	mov	ax,mask BM_EDIT_MASK
	clr	dx					;no ColorTransfer
	call	GrSetBitmapMode
	test	ax, mask BM_EDIT_MASK
	jz	afterMask
	
	mov	ax,C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor
	mov	ax,MIN_COORD
	mov	bx,ax
	mov	cx,MAX_COORD
	mov	dx,cx
	call	GrFillRect
	clr	ax					;back to normal mode
	clr	dx					;no ColorTransfer
	call	GrSetBitmapMode

afterMask:
	add	si, size OpDrawBitmap
	mov	dx, SEGMENT_CS
	mov	cx, offset GrObjBodyDrawBitmapFromGStringCB
	clr	ax, bx					;position
	call	GrDrawBitmap

	popdw	cxdx					;guardian od

	.leave
	ret
GrObjBodyCreateGrObjFromGrDrawBitmap		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetVisBitmapGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get main bitmap gstate from vis ward of guardian being
		created from gstring element

CALLED BY:	INTERNAL
		GrObjbodyCreateGrObjFromGrDrawBitmap

PASS:		^lcx:dx - guardian

RETURN:		
		di - gstate

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
	srs	12/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetVisBitmapGState		proc	near
	uses	ax,bx,cx,dx,bp,si
	.enter

	movdw	bxsi,cxdx				;guardian od
	mov	di,mask MF_CALL
	mov	ax,MSG_GOVG_GET_VIS_WARD_OD
	call	ObjMessage
	movdw	bxsi,cxdx				;ward od
	mov	di,mask MF_CALL
	mov	ax,MSG_VIS_BITMAP_GET_MAIN_GSTATE
	call	ObjMessage
	mov	di,bp					;bitmap gstate

	.leave
	ret
GrObjBodyGetVisBitmapGState		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyDrawBitmapFromGStringCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	HugeArrayNext bitmap to next slice

CALLED BY:	INTERNAL
		GrObjBodyCreateGrObjFromGrDrawBitmap 

PASS:		ds:si - pointing at CBitmap structure in
		a GR_DRAW_BITMAP or GSE_BITMAP_SLICE gstring element

RETURN:		
		if next gstring element is a GSE_BITMAP_SLICE
			ds:si - pointing at CBitmap structure in next
			gstring element		
			carry clear

		if next gstring element is not a GSE_BITMAP_SLICE
			ds:si - pointing a op code of next gstring element
			carry set
		
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

		MUST BE FAR - it is used as a call back routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDrawBitmapFromGStringCB		proc	far
	uses	ax,dx
	.enter

	;    Need to point si back to begin of gstring element so
	;    that HugeArrayNext will work. We don't know whether
	;    we are at the GR_DRAW_BITMAP element or one of the
	;    GSE_BITMAP_SLICE elements. If this is really an
	;    OpBitmapSlice but we check for the GSE_BTIMAP_SLICE,
	;    we will be looking at the high byte of the y position
	;    of the OpDrawBitmap. That high byte can never be
	;    GSE_BITMAP_SLICE (84h), so we are safe.
	;

CheckHack < (size OpDrawBitmap - size OpBitmapSlice) eq (offset ODB_y + 1) >
CheckHack < GSE_BITMAP_SLICE gt 40h >

	mov	ax,size OpBitmapSlice			;assume slice
	cmp	{byte}ds:[si-(size OpBitmapSlice)],GSE_BITMAP_SLICE
	je	gotElementStructSize

	mov	ax, size OpDrawBitmap			;probably this then

gotElementStructSize:
	;    back up to begining of gstring element
	;

	sub	si,ax					

	call	HugeArrayNext

	;   Move si past the OpBitmapSlice data to point at the CBitmap
	;   structure, unless the element we are pointing at is
	;   not a GSE_BITMAP_SLICE
	;

	cmp	ds:[si].OBS_opcode,GSE_BITMAP_SLICE
	jne	notExpected
	add	si,size OpBitmapSlice

	clc
done:
	.leave
	ret

notExpected:
	;    We did not expect to be called back with the pointer pointing
	;    into the last slice of the bitmap. We have now passed onto
	;    the gstring element that lies beyond the bitmap. However the
	;    code after the call to GrDrawBitmap expects ds:si pointing
	;    into the last slice of the bitmap at the CBitmap structure.
	;    So make things happy and stop processing.
	;

	call	HugeArrayPrev
	add	si,size OpBitmapSlice
	stc
	jmp	done	

GrObjBodyDrawBitmapFromGStringCB		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyInitBitmapGuardianFromGStringElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the bitmaps normal transform, create and
		initialize the ward

CALLED BY:	INTERNAL
		GrObjBodyCreateGrObjFromGrDrawBitmap

PASS:		ds:si - gstring element
		^lcx:dx - od of object
		ss:bp - GrObjBodyParseGStringStruc

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
	srs	12/ 1/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyInitBitmapGuardianFromGStringElement		proc near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	call	GrObjBodyInitBitmapGuardianGeometry

	push	si					;element offset

	movdw	bxsi,cxdx				;guardian od
	clr	di
	mov	ax,MSG_GO_INIT_TO_DEFAULT_ATTRS
	call	ObjMessage

	;    Calculate parent dimensions now that we have
	;    geometry and attributes
	;
	
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjMessage

	;    Create and initialized the vis bitmap
	;

	pushdw	bxsi					;guardian od
	mov	bx,ss:[bp].GOBPGS_body.handle
	mov	si,ss:[bp].GOBPGS_body.chunk
	mov	di,mask MF_CALL
	mov	ax,MSG_GB_GET_BLOCK_FOR_ONE_GROBJ
	call	ObjMessage
	popdw	bxsi					;guardian od
	mov	di,mask MF_CALL
	mov	ax,MSG_GOVG_CREATE_VIS_WARD
	call	ObjMessage
	clr	di
	mov	ax,MSG_GOVG_VIS_BOUNDS_SETUP
	call	ObjMessage

	pop	di					;element offset
	pushdw	bxsi					;guardian od
	movdw	bxsi,cxdx				;ward od
	call	GrObjBodyGetResolutionFromOpDrawBitmap	
	mov	dx,ax					;x res
	mov	bp,cx					;y res
	mov	cl,ds:[di].CB_simple.B_type+size OpDrawBitmap
	andnf	cl,mask BMT_FORMAT
	clr	di
	mov	ax,MSG_VIS_BITMAP_SET_FORMAT_AND_RESOLUTION
	call	ObjMessage

	;    Notify object that it is complete and ready to go.
	;    This will also cause the VisBitmap to create
	;    its bitmap.
	;

	popdw	bxsi					;guardian
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	call	ObjMessage

	.leave
	ret
GrObjBodyInitBitmapGuardianFromGStringElement		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetResolutionFromOpDrawBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	return resolution of bitmap from OpDrawBitmap in 
		gstring

Pass:		ds:di - OpDrawBitmap gstring element

Return:		
		ax - x res
		cx - y res

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 17, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetResolutionFromOpDrawBitmap	proc	near
	.enter

	mov	ax,72					;assumed x res
	mov	cx,ax					;assumed y res
	test	ds:[di].B_type+size OpDrawBitmap, mask BMT_COMPLEX
	jz	done
	mov	ax,ds:[di].CB_xres+size OpDrawBitmap
	mov	cx,ds:[di].CB_yres+size OpDrawBitmap
done:

	.leave
	ret
GrObjBodyGetResolutionFromOpDrawBitmap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyInitBitmapGuardianGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the position, size of the bitmap guardian

CALLED BY:	INTERNAL
		GrObjBodyInitBitmapGuardianGeometry

PASS:		ds:si - gstring element
		^lcx:dx - guardian od

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
	srs	12/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyInitBitmapGuardianGeometry		proc	near
	uses	ax,bx,cx,dx,bp,si,di,ds
	.enter

	sub	sp,size BasicInit
	mov	bp,sp
	push	cx,dx					;guardian od

	;    The dimension in DOCUMENT coordinates = (pixel width / dpi) * 72
	;

	clr	ax
	mov	ss:[bp].BI_width.WWF_frac,ax
	mov	ss:[bp].BI_height.WWF_frac,ax

	;    By doing the multiply before the divide we avoid
	;    losing accuracy
	;

	push	di					;gstate
	mov	di,si					;gstring element
	call	GrObjBodyGetResolutionFromOpDrawBitmap
	mov_tr	di,ax					;x res

	mov	ax,ds:[si].CB_simple.B_width+size OpDrawBitmap
	mov	bx,72
	mul	bx
	div	di
	mov	ss:[bp].BI_width.WWF_int,ax

	mov	ax,ds:[si].CB_simple.B_height+size OpDrawBitmap
	mov	bx,72
	mul	bx
	div	cx
	mov	ss:[bp].BI_height.WWF_int,ax
	pop	di						;gstate

	;    Calculate the center of the object in the gstate's 
	;    coordinate system
	;

	mov	ax,ss:[bp].BI_width.WWF_int
	clr	bx
	sarwwf	axbx
	add	ax,ds:[si].ODB_x
	cwd
	movdwf	ss:[bp].BI_center.PDF_x,dxaxbx
	mov	ax,ss:[bp].BI_height.WWF_int
	clr	bx
	sarwwf	axbx
	add	ax,ds:[si].ODB_y
	cwd
	movdwf	ss:[bp].BI_center.PDF_y,dxaxbx
	segmov	es,ss
	mov	dx,bp
	addnf	dx,<offset BI_center>
	call	GrTransformDWFixed

	;    Get transform from gstate into BI_transform
	;

	sub	sp,size TransMatrix
	segmov	ds,ss				;TransMatrix segment
	mov	si,sp				;TransMatrix offset
	call	GrGetTransform
	mov	di,bp				;BasicInit frame
	add	di,offset BI_transform
	MoveConstantNumBytes <size GrObjTransMatrix>, cx
	add	sp,size TransMatrix

	pop	bx,si				;guardian od
	clr	di
	mov	ax,MSG_GO_INIT_BASIC_DATA
	call	ObjMessage
	add	sp,size BasicInit

	.leave
	ret
GrObjBodyInitBitmapGuardianGeometry		endp
endif

if 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyImportGStringToBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Does the "real" work of pasting a CIF_GRAPHICS_STRING format
		transfer, reading the item and creating a gstring object with
		the passed gstring, then adding the object to the body.

Pass:		*ds:si = GrObjBody
		bx - VM file
		ax - block handle

		cx, dx - extra data (presumably width, height)

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 12, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyImportGStringToBitmap	proc	far
	uses	ax, bx, cx, dx, bp, di
	.enter

	push	si					;save body chunk
	push	ax					;save transfer block

	;
	;  ^lcx:dx <- new gstring object
	;
	mov	cx, segment BitmapGuardianClass
	mov	dx, offset BitmapGuardianClass
	mov	ax, MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	pop	si					;si <- vm block handle
	push	cx,dx					;save guardian
	mov	cl, GST_VMEM
	call	GrLoadGString				;si <- gstring
	clr	di, dx
	call	GrGetGStringBounds
	sub	cx, ax					;cx <- width
	sub	dx, bx					;dx <- height
	mov_tr	ax, si					;ax <- gstring


	;    Specify the position and size of the new grobject and
	;    have initialize itself to the default attributes
	;

	pop	bx, si
	push	ax					;save gstring
	sub	sp,size GrObjInitializeData
	mov	bp,sp
	clr	ax
	clrdwf	ss:[bp].GOID_position.PDF_x, ax
	clrdwf	ss:[bp].GOID_position.PDF_y, ax
	mov	ss:[bp].GOID_width.WWF_frac, ax
	mov	ss:[bp].GOID_height.WWF_frac, ax
	mov	ss:[bp].GOID_width.WWF_frac, ax
	mov	ss:[bp].GOID_height.WWF_int, dx
	mov	ss:[bp].GOID_width.WWF_int, cx
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_INITIALIZE
	call	ObjMessage
	add	sp,size GrObjInitializeData

	pop	bp					;bp <- gstring
	mov	ax, MSG_BG_CREATE_VIS_BITMAP
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	mov_tr	ax, si					;ax <- grobj chunk
	mov	si, bp					;gstring
	clr	di					;no gstate
	mov	dl,GSKT_LEAVE_DATA
	call	GrDestroyGString

	;
	;  Move the gstring to be centered on the interesting point
	;

	pop	si					;*ds:si <- body
	push	si					;save body chunk
	sub	sp, size PointDWFixed
	mov	bp, sp
	call	GrObjBodyGetWinCenter
	mov_tr	si, ax					;^lbx:si <- grobj

	mov	ax,MSG_GO_MOVE_CENTER_ABS
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size PointDWFixed

	;    Notify object that it is complete and ready to go
	;

	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Add the new grobject to the body and have it drawn.
	;    If you wish to add many grobjects and draw them all
	;    at once use MSG_GB_ADD_GROBJ instead.
	;

	mov	cx,bx					;new handle
	mov	dx,si					;new chunk
	pop	si					;body chunk
	mov	bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_ADD_GROBJ_THEN_DRAW
	call	ObjCallInstanceNoLock

	mov	al, HUM_NOW
	call	GrObjBodySendBecomeSelectedToChild

	.leave
	ret
GrObjBodyImportGStringToBitmap	endp

endif

GrObjImpexCode	ends
