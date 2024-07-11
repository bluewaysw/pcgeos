COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gdgwin.asm

AUTHOR:		Ronald Braunstein, Sep 29, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/29/94		Initial revision


DESCRIPTION:
	
		

	$Id: gdgwin.asm,v 1.1 98/03/11 04:30:16 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	;
	; property data
	;

CLIPPER_INITIAL_SIZE	equ	32

include Objects/winC.def

idata segment
	GadgetClipperClass
idata ends

GadgetClipperCode	segment	resource

makePropEntry clipper, bgColor, LT_TYPE_LONG,		\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CLIPPER_GET_BGCOLOR>,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CLIPPER_SET_BGCOLOR>

makeUndefinedPropEntry clipper, caption
makeUndefinedPropEntry clipper, enabled
makeUndefinedPropEntry clipper, look
makeUndefinedPropEntry clipper, graphic

compMkPropTable GadgetClipperProperty, clipper, bgColor, \
	caption, enabled, look, graphic

MakePropRoutines	Clipper, clipper


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipperSetCompBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the composites bounds to match the view's

CALLED BY:	
PASS:		*ds:si = the view
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipperSetCompBounds	proc	near
	;comp	local	optr
vwidth	local	word
vheight	local	word

		uses	si
		.enter
		push	bp
		mov	ax, MSG_GEN_GET_FIXED_SIZE
		call	ObjCallInstanceNoLock	; cx:dx = width:height
		pop	bp

		mov	vwidth, cx
		mov	vheight, dx
		
		push	si
		push	bp
		mov	ax, MSG_GEN_VIEW_GET_CONTENT
		call	ObjCallInstanceNoLock
		movdw	bxsi, cxdx
		pop	bp
		
		push	bp
		mov	ax, MSG_VIS_SET_SIZE
		mov	cx, vwidth
		mov	dx, vheight
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp
		pop	si
		.leave
		ret
GadgetClipperSetCompBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipperSetBGColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the BG color of a clipper

CALLED BY:	MSG_GADGET_WIN_SET_BG_COLOR
PASS:		*ds:si	= GadgetClipperClass object
		ds:di	= GadgetClipperClass instance data
		ds:bx	= GadgetClipperClass object (same as *ds:si)
		es	= segment of GadgetClipperClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 5/10/95	Initial version
	gene	9/28/97		Changed to take 24-bit color + opacity
	gene	9/28/97		Broke into two handlers for memory

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipperSetBGColor	method dynamic GadgetClipperClass, 
					MSG_GADGET_CLIPPER_SET_BGCOLOR
		uses	bp
		.enter

		les	di, ss:[bp].SPA_compDataPtr
	;
	; check the type is a long
	;
		cmp	es:[di].CD_type, LT_TYPE_LONG
		jne	wrongType
	;
	; set the color in the view
	;
		mov	ch, CF_RGB
		mov	cl, {byte}es:[di].CD_data.LD_long[2]	;red
		mov	dl, {byte}es:[di].CD_data.LD_long[1]	;green
		mov	dh, {byte}es:[di].CD_data.LD_long[0]	;blue
		mov	ax, MSG_GEN_VIEW_SET_COLOR
		call	ObjCallInstanceNoLock	
done:
		.leave
		Destroy	ax, cx, dx
		ret
wrongType:
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_PROPERTY_TYPE_MISMATCH
		jmp	done
GadgetClipperSetBGColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipperGetBGColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the BG color of a clipper

CALLED BY:	MSG_GADGET_CLIPPER_GET_BGCOLOR
PASS:		*ds:si	= GadgetClipper object
		ds:di	= GadgetClipper instance data
		ds:bx	= GadgetClipper object (same as *ds:si)
		es 	= segment of GadgetClipper
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/28/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipperGetBGColor	method dynamic GadgetClipperClass, 
					MSG_GADGET_CLIPPER_GET_BGCOLOR
		uses	bp
		.enter

		push	bp
		mov	ax, MSG_GEN_VIEW_GET_COLOR
		call	ObjCallInstanceNoLock
		pop	bp
		les	di, ss:[bp].SPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_LONG
		mov	{byte}es:[di].CD_data.LD_long[0], dh	;blue
		mov	{byte}es:[di].CD_data.LD_long[1], dl	;green
		mov	{byte}es:[di].CD_data.LD_long[2], cl	;red
		mov	{byte}es:[di].CD_data.LD_long[3], 0xff	;opacity

		.leave
		Destroy	ax, cx, dx
		ret
GadgetClipperGetBGColor	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipperSetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_WIN_SET_SIZE
PASS:		*ds:si	= GadgetClipperClass object
		ds:di	= GadgetClipperClass instance data
		ds:bx	= GadgetClipperClass object (same as *ds:si)
		es	= segment of GadgetClipperClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 5/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipperSetSize	method dynamic GadgetClipperClass, 
					MSG_GADGET_SET_WIDTH,
					MSG_GADGET_SET_HEIGHT
	
		uses	ax, cx, dx, bp, si
		.enter
		mov	di, offset GadgetClipperClass
		call	ObjCallSuperNoLock
		call	GadgetClipperSetCompBounds
		.leave
		call	GCGeometryStuff
		ret

GadgetClipperSetSize	endm


	
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGetPassedWordInCXDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads in the passed long value and copies it to CX:DX

CALLED BY:	GadgetClipperSetProperty
PASS:		ss:bp	= SetPropertyArgs
RETURN:		cx	- high word
		dx	- low word
		CF set	- if wrong type
		es:di	= ComponentData passed in
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 4/12/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGetPassedWordInCX	proc	far
		.enter
		les	di, ss:[bp].SPA_compDataPtr
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		stc
		jne	done
		mov	cx, es:[di].CD_data.LD_integer
		clc
done:
		.leave
	ret
GadgetGetPassedWordInCX	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipperEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	arrange our guts the way we wants 'em

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetClipperClass object
		ds:di	= GadgetClipperClass instance data
		ds:bx	= GadgetClipperClass object (same as *ds:si)
		es	= segment of GadgetClipperClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		First tell superclass to Init itself.
		Then send messages to the superclass telling it what
		the init figs should really be.	 We don't have much
		to initialize in the object at our level.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipperEntInitialize	method dynamic GadgetClipperClass, 
					MSG_ENT_INITIALIZE
content	local	optr
interp	local	hptr
oself	local	optr		
		.enter

		mov	interp, dx
		mov	bx, ds:LMBH_handle
		movdw	oself, bxsi
	;
	; Tell superclass to do its thing
	;
		push	bp
		mov	di, offset GadgetClipperClass
		call	ObjCallSuperNoLock
		
		mov	cx, mask GVA_NO_WIN_FRAME or mask GVA_GENERIC_CONTENTS
		clr	dx
		mov	bp, VUM_NOW
		mov	ax, MSG_GEN_VIEW_SET_ATTRS
		call	ObjCallInstanceNoLock

		sub	sp, size RectDWord
		mov	bp, sp
		clr	dx
	; use highest non-negative value
		mov	ax, 400h
		movdw	ss:[bp].RD_left, dxdx
		movdw	ss:[bp].RD_top, dxdx
		movdw	ss:[bp].RD_right, dxax
		movdw	ss:[bp].RD_bottom, dxax
		mov	dx, size RectDWord
		mov	ax, MSG_GEN_VIEW_SET_DOC_BOUNDS
		call	ObjCallInstanceNoLock
		add	sp, size RectDWord

		mov	cx, SpecWidth <SST_PIXELS, CLIPPER_INITIAL_SIZE>
		mov	dx, SpecHeight <SST_PIXELS, CLIPPER_INITIAL_SIZE>
		mov	al, VUM_NOW
		call	GadgetUtilGenSetFixedSize
		
		pop	bp
		push	bp
		mov	ax, segment GenContentClass
		mov	es, ax
		mov	di, offset GenContentClass
		mov	bx, ds:LMBH_handle
		call	ObjInstantiate
		
		mov	cl, mask VTF_IS_COMPOSITE or mask VTF_IS_WINDOW or\
			    mask VTF_IS_CONTENT or mask	VTF_IS_WIN_GROUP
		clr	ch
		mov	ax, MSG_VIS_SET_TYPE_FLAGS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	
		mov	cl, (WJ_CENTER_CHILDREN_HORIZONTALLY shl offset \
	VCGDA_WIDTH_JUSTIFICATION) or (HJ_CENTER_CHILDREN_VERTICALLY shl \
	offset VCGDA_HEIGHT_JUSTIFICATION) or \
	(mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT) or \
	(mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT)
		clr	dx
		mov	ch, dh
		mov	ax, MSG_VIS_COMP_SET_GEO_ATTRS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp
		
		movdw	content, bxsi
		
		mov	dx, oself.chunk
EC <		call	VisCheckVisAssumption				>
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
	;	movdw	ds:[di].VI_link, bxdx

		mov	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID or\
					     mask VOF_GEO_UPDATE_PATH or\
					     mask VOF_IMAGE_INVALID or\
					     mask VOF_WINDOW_INVALID or\
					     mask VOF_WINDOW_UPDATE_PATH or\
					     mask VOF_IMAGE_UPDATE_PATH

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset

		movdw	cxdx, bxsi
		mov	si, oself.chunk
		movdw	ds:[di].GCI_genView, bxsi
	; it seems that the link pointer of the GenContent should
	; point back to the GenView so that it actually resides in the
	; Generic Tree
	;		movdw	ds:[di].GI_link, bxsi
		

		push	bp
		push	cx, dx
		mov	ax, MSG_GEN_VIEW_SET_CONTENT
		call	ObjCallInstanceNoLock
		pop	cx, dx

		push	es
		mov	bp, CCO_FIRST
		mov	ax, segment GadgetClipperClass
		mov	es, ax
		mov	di, offset GadgetClipperClass
		mov	ax, MSG_GEN_ADD_CHILD
		call	ObjCallSuperNoLock
		pop	es
		
		
	; this is an attempt to get some reasonble bounds into the
	; comp, based on the bounds of the view
		call	GadgetClipperSetCompBounds

		pop	bp
		push	bp
		movdw	cxdx, content
		mov	ax, segment GadgetGroupClass
		mov	es, ax
		mov	di, offset GadgetGroupClass
		mov	bx, ds:LMBH_handle
		call	ObjInstantiate
		pop	bp

		
		push	bp
		mov	ax, MSG_ENT_INITIALIZE
		mov	dx, interp
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp

		push	bp
		movdw	cxdx, content
		xchgdw	bxsi, cxdx
		mov	ax, MSG_GEN_ADD_CHILD
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	bp, CCO_LAST
		call	ObjMessage

		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp

		push	bp
		movdw	bxsi, content
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp

		mov	si, oself.chunk
		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		mov	ax, content.chunk
		mov	ds:[di].GCI_window, ax
		.leave
		ret
GadgetClipperEntInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipperMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform the system of our association Vis

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= GadgetClipperClass object
		ds:di	= GadgetClipperClass instance data
		ds:bx	= GadgetClipperClass object (same as *ds:si)
		es	= segment of GadgetClipperClass
		ax	= message #
RETURN:		cx:dx	= superclass to use
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	6/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeResolveSuperClassRoutine Clipper, GenView
				

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipperGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return "win"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetClipperClass object
		ds:di	= GadgetClipperClass instance data
		ds:bx	= GadgetClipperClass object (same as *ds:si)
		es	= segment of GadgetClipperClass
		ax	= message #
RETURN:		cx:dx	= fptr.char

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/28/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetClipperGetClass	method dynamic GadgetClipperClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetClipperString
		mov	dx, offset GadgetClipperString	
		ret
GadgetClipperGetClass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GWVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= GadgetClipperClass object
		ds:di	= GadgetClipperClass instance data
		ds:bx	= GadgetClipperClass object (same as *ds:si)
		es	= segment of GadgetClipperClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/24/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GWVisOpen	method dynamic GadgetClipperClass, 
					MSG_VIS_OPEN
		.enter
		
	; stuff in a size so don't get coord in win open when
	; under a floater (what's the hell is up with this crap ???)
		push	bp
		mov	ax, MSG_GEN_GET_FIXED_SIZE
		call	ObjCallInstanceNoLock
		mov	ax, MSG_VIS_SET_SIZE
		call	ObjCallInstanceNoLock
		pop	bp
		
		mov	di, offset GadgetClipperClass
		mov	ax, MSG_VIS_OPEN
		call	ObjCallSuperNoLock	
		.leave
		ret
GWVisOpen	endm



		
GCGeometryStuff	method  GadgetClipperClass,
					MSG_GEN_ADD_CHILD,
					MSG_GADGET_SET_SIZE_HCONTROL,
					MSG_GADGET_SET_SIZE_VCONTROL,
					MSG_GADGET_GEOM_SET_TILE_LAYOUT,
					MSG_GADGET_GEOM_SET_TILE_SPACING,
					MSG_GADGET_GEOM_SET_TILED,
					MSG_GADGET_GEOM_SET_TILE_HALIGN,
					MSG_GADGET_GEOM_SET_TILE_VALIGN,
					MSG_GADGET_GEOM_SET_TILE_HINSET,
					MSG_GADGET_GEOM_SET_TILE_VINSET,
					MSG_GADGET_GET_SIZE_HCONTROL,
					MSG_GADGET_GET_SIZE_VCONTROL,
					MSG_GADGET_GEOM_GET_TILE_LAYOUT,
					MSG_GADGET_GEOM_GET_TILE_SPACING,
					MSG_GADGET_GEOM_GET_TILED,
					MSG_GADGET_GEOM_GET_TILE_HALIGN,
					MSG_GADGET_GEOM_GET_TILE_VALIGN,
					MSG_GADGET_GEOM_GET_TILE_HINSET,
					MSG_GADGET_GEOM_GET_TILE_VINSET,
					MSG_META_QUERY_IF_PRESS_IS_INK
		
		.enter
		push	cx, dx, bp, ax
		mov	ax, MSG_GEN_VIEW_GET_CONTENT
		call	ObjCallInstanceNoLock
		movdw	bxsi, cxdx

		mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		clr	cx
		call	ObjMessage
		mov	di, si
		movdw	bxsi, cxdx
		pop	cx, dx, bp, ax
		
		push	di
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si

		.leave
		ret
GCGeometryStuff	endm
		

method	ClipperVisPositionBranch, GadgetClipperClass, MSG_VIS_POSITION_BRANCH
;
; Note, Dialogs and forms have a similar routine in gdgwin.asm
; 
ClipperVisPositionBranch	proc	far
		class	GadgetGeomClass
	;
	; Are we tiled?
		Assert	objectPtr, dssi, GadgetGeomClass
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGeom_offset
		test	ds:[di].GGI_flags, mask GGF_TILED
		jnz	callSuper

	;
	; I think the GeometryValid bits should be clear now.
	; lets ensure they are.
	; Only do it if not tiled or there may be no specific
	; vis parent.
		
	;	call	ClearGeomBitsOnForm

	;
	; For PCV, we want the OLGadgetArea to appear at 0,0 so we don't
	; ask the superclass to place it.
	; If PCV had title bars / system menus / menu bars / scrollbars
	; as part of any object we would need to call the superclass to get
	; those in the right place.
		mov	ax, MSG_VIS_POSITION_BRANCH
		mov	di, offset GadgetGeomClass
		call	ObjCallSuperNoLock
		call	GadgetUtilPositionChildren
		jmp	done
	;
	; Use GadgetGeomClass because this proc is used for both forms
	; and dialog and their first common superclass is GadgetGeomClass.
	;
callSuper:
		mov	di, offset GadgetGeomClass
		call	ObjCallSuperNoLock

done:
		.leave
		ret
ClipperVisPositionBranch	endp

method	GadgetOLSpecBuildBranch, GadgetClipperClass, MSG_SPEC_BUILD_BRANCH

method ClipperVisRecalcSize, GadgetClipperClass, MSG_VIS_RECALC_SIZE

;
; Note: Clippers have a similar routine in gdgwin.asm
; 

ClipperVisRecalcSize	proc	far
		class	GadgetGeomClass
		.enter
		Assert	objectPtr, dssi, GadgetGeomClass
		test	ds:[di].GGI_flags, mask GGF_TILED
		pushf

callSuper::
	; the superclass needs to be called when not tiling,
	; to place all of its OL stuff itself.  Mark everything else as
	; not managed so it doesn't mess with it.
	;
		jnz	afterChildManagement
		call	GadgetUtilUnManageChildren
afterChildManagement:

	; call superclass of Geom, not form so we don't do everything
	; twice
		mov	di, offset GadgetGeomClass
		mov	ax, MSG_VIS_RECALC_SIZE
		call	ObjCallSuperNoLock
		popf
		jnz	reallyDone

custom::
	;
	; future notes:
	; 	cx:dx is the sized passed in and what we pass to our children.
	;	It is not necessarily our size, but that is okay.
	;	I don't think we want to call SizeSelf because if we are
	; 	as small as possible then our children will not have been sized
	;	yet, which we need.
	;
	;	Also, we probably should remove our margins here.
	; 	(ask self, not superclass for margins so we can add in
	;	tile offsets as defined in legos to the vis comp margins.)
	;
		
	;
	; If we are not tiled, size our gadget area and our
	; children and ourself
	;
	; moved to UpdateGeometry code
		call	GadgetUtilVisRecalcSize		; size children
	;
		
	; If we have any children, then set the gadget area to the size
	; it needs to be instead of setting the size on the primary.
	;
		pushdw	cxdx		; size
		call	GadgetUtilGetCorrectVisParent
		mov	bp, si		; form
		mov	si, dx
		mov	ax, cx						
		popdw	cxdx		; size
		jc	sizeSelf
		cmp	ax, 0
		je	sizeSelf
	; assume gadget area in same block
		Assert	e, ds:[LMBH_handle], ax
	; *ds:si	= gadget area.
	; cx:dx		= correct size

		push	si		; gadget area
		mov	ax, si
		mov	si, bp		; form
		call	GadgetUtilSizeSelf
		cmp	si, ax
		je	afterGadgetArea
		pushdw	cxdx		; real width /height
		
	; don't add in gadget insets on the actual vis size.
		mov	ax, MSG_VIS_COMP_GET_MARGINS
		mov	di, offset GadgetGeomClass
		call	ObjCallClassNoLock
		add	ax, cx
		add	bp, dx
		popdw	cxdx		; real width height
		mov	di, si		; form
		pop	si		; gadget area

		push	di		; form
		pushdw	cxdx		; total width,height
		sub	cx, ax		; - width
		sub	dx, bp		; - height
		call	VisSetSize
		popdw	cxdx		; total width, height of self
		
afterGadgetArea:
		pop	si		; form
done:

		call	GadgetUtilManageChildren
reallyDone:
		.leave
		ret
sizeSelf:
		mov	si, bp
		call	GadgetUtilSizeSelf
		jmp	done

ClipperVisRecalcSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipperShow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the object usable in the Gen or Vis world.
		This will also update the "visible" property of the component.

CALLED BY:	MSG_ENT_VIS_SHOW, MSG_ENT_VIS_HIDE
PASS:		*ds:si	= EntClass object
		ds:di	= EntClass instance data
		ds:bx	= EntClass object (same as *ds:si)
		es	= segment of EntClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipperShow method dynamic GadgetClipperClass, 
					MSG_ENT_VIS_SHOW, MSG_ENT_VIS_HIDE
	uses	ax, cx, dx, bp
		.enter
		.assert MSG_ENT_VIS_HIDE eq MSG_ENT_VIS_SHOW +1

		sub	ax, MSG_ENT_VIS_SHOW		;0 = show, 1 = hide
		tst	ax
		jz	setVisible
		BitClr	ds:[di].EI_flags, EF_VISIBLE
		jmp	callMaster
setVisible:
		BitSet	ds:[di].EI_flags, EF_VISIBLE
callMaster:
	;
	; Determine if this is a vis or gen object
	;
		add	ax, MSG_GEN_SET_USABLE
		mov	cl, ds:[di].EI_state
		test	cl, mask ES_IS_GEN
		jnz	genSetUsable

		test	cl, mask ES_IS_VIS
		jz	done
	;
	; Send it a vis message to make it viewable
	;
		mov	cx, ( mask VA_MANAGED or mask VA_DRAWABLE or mask VA_DETECTABLE or mask VA_FULLY_ENABLED)
		cmp	ax, MSG_GEN_SET_USABLE
		je	changeVisState
setNotVisible::
		mov	ch, cl
		clr	cl
changeVisState:
		mov	ax, MSG_VIS_SET_ATTRS
		
	;
	; Send it a gen message to make it viewable
	;
genSetUsable:
		mov	di, segment EntClass
		mov	es, di
		mov	dl, VUM_NOW
		mov	di, offset EntClass
		call	ObjCallSuperNoLock
done:		
	.leave
	ret
ClipperShow endm


GadgetClipperCode	ends


