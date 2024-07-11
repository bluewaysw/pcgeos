COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Gadget Library
FILE:		gadgetgeom.asm

AUTHOR:		David Loftesness, Nov  4, 1994

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_ENT_INITIALIZE	Set up default instance data, etc.

    MTD MSG_GADGET_GEOM_GET_TILE_LAYOUT
				Deal with our layout property

    MTD MSG_GADGET_GEOM_GET_TILED
				Return our tiled state

    MTD MSG_GADGET_GEOM_SET_TILED
				Set our tiled state

    MTD MSG_GADGET_GEOM_SET_TILE_HALIGN,
	MSG_GADGET_GEOM_SET_TILE_VALIGN
				Set our alignment properties

    MTD MSG_GADGET_GEOM_GET_TILE_HALIGN,
	MSG_GADGET_GEOM_GET_TILE_VALIGN
				Get our alignment properties

    MTD MSG_GADGET_GEOM_GET_TILE_SPACING
				Methods to deal with tile spacing property

 ?? INT GadgetGeomSetCustomTileSpacing
				helper routine to add some var data

    MTD MSG_GADGET_GEOM_SET_TILE_SPACING
				helper routine to add some var data

    INT GadgetGeomUpdateChildManagement
				Sends out notification to all children
				within this geometry composite of the
				change in the tiled property.  The children
				then either add or remove their
				ATTR_GEN_POSITION hint according to the new
				value of its parent's tiled property.

    MTD MSG_GADGET_GEOM_SET_TILE_LAYOUT
				Deal with our layout property

    MTD MSG_GADGET_GEOM_GET_TILE_VINSET,
	MSG_GADGET_GEOM_GET_TILE_HINSET
				

    MTD MSG_GADGET_GEOM_SET_TILE_HINSET,
	MSG_GADGET_GEOM_SET_TILE_VINSET
				set the tileInset properties

    MTD MSG_VIS_COMP_GET_MARGINS
				Return the size of our margins

    MTD MSG_SPEC_BUILD_BRANCH	Store self in GGI_childParent so we can
				access it later if needed.  No extra object
				creation is done here.

    MTD MSG_VIS_RECALC_SIZE	Tell whoever cares what our size should
				be. If not tiled, let the geometry manager
				figure it out, otherwise compute it based
				on our size controls.

    MTD MSG_GADGET_GEOM_GET_FLAGS
				Returns the current flags

    MTD MSG_GADGET_GEOM_GET_VIS_CHILD_PARENT
				Used to get Vis object that is holding our
				children. Really only useful on forms,
				clippers, dialogs where it is different
				than self.

    MTD MSG_META_INITIALIZE	Store childParent so it is something valid
				before MSG_SPEC_BUILD_BRANCH is sent.

    MTD MSG_GADGET_GEOM_GET_NUM_CHILDREN
				Return the number of children we've got.

    MTD MSG_GADGET_GEOM_SET_NUM_CHILDREN,
	MSG_GADGET_GEOM_ACTION_SET_CHILDREN
				Return the number of children we've got.

    MTD MSG_GADGET_GEOM_ACTION_GET_CHILDREN
				Get the gadget's children.

    MTD MSG_GADGET_SET_GRAPHIC	Only allow groups, not windowed things to
				have graphic monikers

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	11/ 4/94	Initial revision


DESCRIPTION:
	This class provides geometry-related properties to its
	subclasses.  It provides the properties for tiling and turns
	the geometry manager on and off as needed.

	One weird property is "tile." Ideally, the tile property would
	be a function of other tile properties.  If any of them is
	set, tile is set.  Turning tile off should remove all of the
	tiling properties (and appropiate hints) but currently
	doesn't.

	The current class heirarchy for GadgetGeom looks like:

	Gadget*+
		GadgetGeom*
			GadgetForm*
			GadgetClipper*
			GadgetGroup
				GadgetPopup
			GadgetDialog*
				GadgetFloater*+
	GadgetGadget (and GadgetTable) also has a tile property, but
	they don't support any tiling behavior.

	PCV doesn't support any sort of tiling.  We left it in as
	other projects in the future might want it and so the build
	time components could make use of it.


	$Id: gdggeom.asm,v 1.1 98/03/11 04:30:20 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	GadgetGeomClass
idata	ends

include Objects/visC.def	; for SpecSizeSpec
include	Objects/vCompC.def	; for geo msgs

makePropEntry geom, numChildren, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_GET_NUM_CHILDREN>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_SET_NUM_CHILDREN>
makePropEntry geom, tileLayout, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_GET_TILE_LAYOUT>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_SET_TILE_LAYOUT>
makePropEntry geom, tileSpacing, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_GET_TILE_SPACING>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_SET_TILE_SPACING>
makePropEntry geom, tile, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_GET_TILED>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_SET_TILED>
makePropEntry geom, tileHAlign, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_GET_TILE_HALIGN>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_SET_TILE_HALIGN>
makePropEntry geom, tileVAlign, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_GET_TILE_VALIGN>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_SET_TILE_VALIGN>
makePropEntry geom, tileHInset, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_GET_TILE_HINSET>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_SET_TILE_HINSET>
makePropEntry geom, tileVInset, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_GET_TILE_VINSET>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GEOM_SET_TILE_VINSET>

makeUndefinedPropEntry geom, readOnly

compMkPropTable	 GadgetGeomProperty, geom, numChildren, tileLayout,\
	tileSpacing, tile, tileHAlign, tileVAlign, tileHInset, tileVInset,\
	readOnly


makeActionEntry geom, Setchildren, \
	MSG_GADGET_GEOM_ACTION_SET_CHILDREN, LT_TYPE_VOID, 1
makeActionEntry geom, Getchildren, \
	MSG_GADGET_GEOM_ACTION_GET_CHILDREN, LT_TYPE_COMPONENT, 1

compMkActTable geom, Getchildren, Setchildren


hAlignHintTable		word	\
HINT_CENTER_CHILDREN_HORIZONTALLY,
HINT_FULL_JUSTIFY_CHILDREN_HORIZONTALLY,
HINT_LEFT_JUSTIFY_CHILDREN,
HINT_RIGHT_JUSTIFY_CHILDREN

vAlignHintTable		word	\
HINT_CENTER_CHILDREN_VERTICALLY,
HINT_FULL_JUSTIFY_CHILDREN_VERTICALLY,
HINT_TOP_JUSTIFY_CHILDREN,
HINT_BOTTOM_JUSTIFY_CHILDREN

;
; justifyHintTable in low-to-high order from the justifychildren bitfield so
; we can increment a pointer through it.
;
;justifyHintTable	word	\
;HINT_BOTTOM_JUSTIFY_CHILDREN,
;HINT_LEFT_JUSTIFY_CHILDREN,
;HINT_RIGHT_JUSTIFY_CHILDREN,
;HINT_TOP_JUSTIFY_CHILDREN,
;HINT_FULL_JUSTIFY_CHILDREN_VERTICALLY,
;HINT_FULL_JUSTIFY_CHILDREN_HORIZONTALLY,
;HINT_CENTER_CHILDREN_VERTICALLY,
;HINT_CENTER_CHILDREN_HORIZONTALLY,
;0

;JC_HIGH_BIT	equ	10000000b	; highest hint in bitfield

GadgetInitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeomEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up default instance data, etc.

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	 3/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeomEntInitialize	method dynamic GadgetGeomClass, 
					MSG_ENT_INITIALIZE
		.enter
	;
	; Set up some instance data
	;
		or	ds:[di].EI_flags, mask EF_ALLOWS_CHILDREN
	;
	; Call superclass
	;
		mov	di, offset GadgetGeomClass
		call	ObjCallSuperNoLock

if 0	; wait for it to get set to tiled to do this
		
	; add hints to match default values for tileHAlign and
	; tileVAlign
		mov	ax, MSG_META_DUMMY
		call	ObjCallInstanceNoLock

		
		clr	cx
		mov	ax, HINT_CENTER_CHILDREN_HORIZONTALLY
		call	ObjVarAddData		
		clr	cx
		mov	ax, HINT_CENTER_CHILDREN_VERTICALLY
		call	ObjVarAddData
endif	; don't set tile align unless tiled
		
		.leave
		ret
GeomEntInitialize	endm

GadgetInitCode	ends

MakePropRoutines Geom, geom
MakeActionRoutines Geom, geom


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomGetLayout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Synopsis:	Deal with our layout property

CALLED BY:	MSG_GADGET_GEOM_GET_LAYOUT
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Assume that if HINT...HORIZONTALLY is not set, then we're
		vertical.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	 8/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetGeomGetTileLayout	method dynamic GadgetGeomClass, \
						MSG_GADGET_GEOM_GET_TILE_LAYOUT
		.enter

		mov	ax, HINT_ORIENT_CHILDREN_HORIZONTALLY
		call	GadgetUtilCheckHintAndSetInteger

		.leave
		ret
GadgetGeomGetTileLayout	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomGetTiled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return our tiled state

CALLED BY:	MSG_GADGET_GEOM_GET_TILED
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
RETURN:		
DESTROYED:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	 8/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomGetTiled	method dynamic GadgetGeomClass, 
					MSG_GADGET_GEOM_GET_TILED
		.enter
	; 
	; Pull the current value of the tiled property from a
	; bitfield in the instance data of this component.  The tiled
	; property specifies whether or not a given GoolGeomClass component
	; is managing its childrens' positions. -martin 4/24/95	
	;
		test	ds:[di].GGI_flags, mask GGF_TILED
		pushf
		les	di, ss:[bp].GPA_compDataPtr	; buffer to be filled
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, 1
		popf
		jnz	done
		mov	es:[di].CD_data.LD_integer, 0		
done:	
		.leave
		ret
GadgetGeomGetTiled	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomSetTiled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set our tiled state

CALLED BY:	MSG_GADGET_GEOM_SET_TILED
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	 8/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomSetTiled	method dynamic GadgetGeomClass, 
					MSG_GADGET_GEOM_SET_TILED
		.enter
	; 
	; The tiled property specifies whether or not a given
	; GoolGeomClass component is managing its childrens' positions.
	; First, store the value of the property in the dynamic property
	; table.  Then inform all children that geometry has been updated so
	; they can either add or remove their ATTR_GEN_POSITION hint.  
	; -martin 4/24/95	 
	;

		mov	cl, ds:[di].GGI_flags	; save old flags
		push	cx			 	; old flags
		les	bx, ss:[bp].SPA_compDataPtr
		mov	dx, es:[bx].CD_data.LD_integer
		BitClr	ds:[di].GGI_flags, GGF_TILED
		tst	dx
		jz	updateGeom

setTiled::
		BitSet	ds:[di].GGI_flags, GGF_TILED
	;
	; If we were previously untiled, then set the alignment
	; to be CENTER, 0
		pop	cx				; old flags
		test	cl, mask GGF_TILED
		jnz	updateGeom
		clr	cx
		mov	ax, HINT_CENTER_CHILDREN_HORIZONTALLY
		call	ObjVarAddData		
		clr	cx
		mov	ax, HINT_CENTER_CHILDREN_VERTICALLY
		call	ObjVarAddData
		push	dx
		clr	dx
		mov	ax, dx	; don't force value if already got one
		call	GadgetGeomSetCustomTileSpacing
		pop	dx
		
updateGeom:
		call	GadgetGeomUpdateChildManagement
		tst	dx
		jnz	done

	;
	; If not tiled, ensure that it has no alignment hints,
	; as this messes up / crashes the spui.
	; If we previously weren't tiled, then don't bother
		pop	cx				; old flags
	;		test	cl, mask GGF_TILED
	;	jnz	done
		mov	di, offset hAlignHintTable
		mov	cx, length hAlignHintTable
hTable:
		mov	ax, {word} cs:[di]
		call	ObjVarDeleteData
		inc	di
		inc	di
		loop	hTable
		
		mov	di, offset vAlignHintTable
		mov	cx, length vAlignHintTable
vTable:
		mov	ax, {word} cs:[di]
		call	ObjVarDeleteData
		inc	di
		inc	di
		loop	vTable
done:

		.leave
		ret
GadgetGeomSetTiled	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomSetTileAlign
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set our alignment properties

CALLED BY:	MSG_GADGET_GEOM_SET_TILE_HALIGN
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:
		Setting an alignment will ensure that the tile property
		is set too (so the spui doesn't crash)

PSEUDO CODE/STRATEGY:
		We'll do things the slow way to save space.  Instead of
		storing our state in instance data, just go through and
		remove all the HINTs we're not setting.  We don't expect
		this property to change often at runtime, if at all, so
		slowness shouldn't be a problem.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	 8/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomSetTileAlign	method dynamic GadgetGeomClass, 
					MSG_GADGET_GEOM_SET_TILE_HALIGN,
					MSG_GADGET_GEOM_SET_TILE_VALIGN
		.enter
	;
	; Ensure that we are set to tiled.

		test	ds:[di].GGI_flags, mask GGF_TILED
		jnz	tiled
		BitSet	ds:[di].GGI_flags, GGF_TILED
		mov	ax, MSG_ENT_SET_PROPERTY
		mov	dx, 1
		call	GadgetGeomUpdateChildManagement
tiled:
		
		mov	di, offset hAlignHintTable
		cmp	ax, MSG_GADGET_GEOM_SET_TILE_HALIGN
		je	gotTable
		mov	di, offset vAlignHintTable
gotTable:
		les	bx, ss:[bp].SPA_compDataPtr
		Assert	fptr	esbx
		mov	dx, es:[bx].CD_data.LD_integer

		inc	dx
		mov	cx, 4			; number of hints to look at
		add	di, 3 * size word	; point to end of table
loopTop:
		mov	ax, {word} cs:[di]	; get current hint
		cmp	cx, dx			; is this our hint to add?
		je	addHint
		call	ObjVarDeleteData
checkLoop:
		dec	di
		dec	di			; next hint
		loop	loopTop

		.leave
		ret
addHint:
		clr	cx			; dx has value of cx
		call	ObjVarAddData
		mov	cx, dx			; restore cx (counter)
		jmp	checkLoop
		
GadgetGeomSetTileAlign	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomGetTileAlign
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get our alignment properties

CALLED BY:	MSG_GADGET_GEOM_GET_TILE_HALIGN
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Assume we've only got one hint set (see
		GadgetGeomSetTileAlign, above).  Loop through to see which
		one we hit.  If we don't find one, return the default (0).

		One might argue that the default should be 1 if there is hints,
		as the spui uses a default of HINT_LEFT_JUSTIFY_CHILDREN,
		not HINT_CENTER_CHILDREN, but now we always assume a hint is
		explicityly set.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	 8/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomGetTileAlign	method dynamic GadgetGeomClass, 
					MSG_GADGET_GEOM_GET_TILE_HALIGN,
					MSG_GADGET_GEOM_GET_TILE_VALIGN
		.enter
		mov	di, offset hAlignHintTable
		cmp	ax, MSG_GADGET_GEOM_GET_TILE_HALIGN
		je	gotTable
		mov	di, offset vAlignHintTable
gotTable:
		mov	cx, 5			; 1 + number of hints
		add	di, 3 * size word	; point to end of table
loopTop:
		Assert	fptr	csdi
		dec	cx
		jcxz	found
		mov	ax, {word} cs:[di]	; get current hint
		call	ObjVarFindData
		jc	foundDec
		dec	di
		dec	di			; point to next hint
		jmp	loopTop
foundDec:
		dec	cx			; convert to property value
found:
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx

		.leave
		ret
		
GadgetGeomGetTileAlign	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomGet/SetTileSpacing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Methods to deal with tile spacing property

CALLED BY:	MSG_GADGET_GEOM_GET/SET_TILE_SPACING
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	 8/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomGetTileSpacing	method dynamic GadgetGeomClass, 
					MSG_GADGET_GEOM_GET_TILE_SPACING
		.enter

		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	ax, HINT_CUSTOM_CHILD_SPACING
		call	ObjVarFindData
		jnc	nada
		mov	ax, ds:[bx]
		andnf	ax, mask SSS_DATA
done:
		mov	es:[di].CD_data.LD_integer, ax
		
		.leave
		ret
nada:
		clr	ax
		jmp	done
GadgetGeomGetTileSpacing	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomGetCustomTileSpacing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	helper routine to add some var data

CALLED BY:	
PASS:		dx = spacing, *ds:si = object
		ax = force
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomSetCustomTileSpacing	proc	near
		uses	ax, cx, bx
		.enter

		push	ax
		mov	ax, HINT_CUSTOM_CHILD_SPACING
		call	ObjVarFindData
		pop	cx
		jnc	addData

	; if we have data, check the force flag
		jcxz	done
addData:
		mov	cx, size SpecSizeSpec
		call	ObjVarAddData

		and	dx, mask SSS_DATA	; zero out high bits
		CheckHack <SST_PIXELS eq 0>
	;		ornf	ax, SST_PIXELS shl offset SSS_TYPE
		mov	{word} ds:[bx], dx
done:		
		.leave
		ret
GadgetGeomSetCustomTileSpacing	endp
		
GadgetGeomSetTileSpacing	method dynamic GadgetGeomClass, 
					MSG_GADGET_GEOM_SET_TILE_SPACING
		.enter
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	dx, es:[di].CD_data.LD_integer
		mov	ax, 1	; force new value
		call	GadgetGeomSetCustomTileSpacing
		.leave
		ret
GadgetGeomSetTileSpacing	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomUpdateChildManagement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends out notification to all children within this geometry
		composite of the change in the tiled property.  The
		children then either add or remove their ATTR_GEN_POSITION
		hint according to the new value of its parent's tiled
		property.  

CALLED BY:	INTERNAL - GadgetGeomSetProperty

PASS:		*ds:si	= EntClass object (Component)
		; ds:di	= EntClass instance data
		dx	= new value of tiled property

RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	*** May resize chunks and move lmem blocks ***
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	4/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomUpdateChildManagement	proc	near
		uses	ax, cx, dx, bp, bx
		.enter
	;
	; Figure out whether to add or remove the positioning hint.
	;
		mov	ax, MSG_GEN_REMOVE_GEOMETRY_HINT
		tst	dx
		jnz	enforceGeometry
		dec	ax
	;
	; Ask all children to add ATTR_GEN_POSITION with the proper value 
	; (the x,y positions imposed by their geometry managing parent) 
	; to themselves. 
	;
		jmp	done

enforceGeometry:
	;
	; Remove ATTR_GEN_POSITION from all children to enforce geometry
	; within this group.
	;
	; Actually, we need to remove both ATTR_GEN_POSITION_X and
	; ATTR_GEN_POSITION_Y, since those are the attributes used.
	; dl 7/18/95
	;
;
; Can't do it the quick way and just call GenSendToChildren directly...  
; Alas, we need to send a message so that BentWindowClass's hacked
; childGroup can forward the event correctly. :( 	- martin 5/9/95 
;	 	mov	cx, ATTR_GEN_POSITION
;		mov	dl, VUM_NOW
;		call	GenSendToChildren

recordMessage::
		push	si
		mov	bx, segment GenClass
		mov	cx, ATTR_GEN_POSITION_X
		mov	si, offset GenClass
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	di, mask MF_RECORD
		call	ObjMessage

		push	di
		mov	cx, ATTR_GEN_POSITION_Y
		mov	di, mask MF_RECORD
		call	ObjMessage
		pop	cx				; first event
		pop	si

		mov	ax, MSG_GEN_SEND_TO_CHILDREN
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_SEND_TO_CHILDREN
		mov	cx, di				; second event
		call	ObjCallInstanceNoLock

done:
		.leave
		ret
GadgetGeomUpdateChildManagement	endp
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomSetLayout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with our layout property

CALLED BY:	interpreter, MSG_GADGET_GEOM_SET_PROPERTY
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	8/8/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetGeomSetTileLayout	method dynamic GadgetGeomClass, \
					MSG_GADGET_GEOM_SET_TILE_LAYOUT
		.enter
	;
	; Added code to mark not usable -- we'll mark usable at the end to
	; ensure that geometry changes are displayed.  dl 2/22/95
	;
ifdef FORCE_GEOMETRY_UPDATES
		push	cx, ax
		push	bp
		mov	ax, MSG_GEN_GET_USABLE
		call	ObjCallInstanceNoLock
		pop	bp
		pushf				; save usable state
		jnc	notUsable

		push	bp
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock
		pop	bp
		pop	cx, ax
endif

	; <--FIXME when get
	; property implemented
	; NOTE that the layout defaults are different for different
	; components.  For example, primaries tend to lay out their children
	; vertically, while lists tend toward the horizontal.  Think about
	; this before implementing the get_layout handler -- we may need to
	; alter the default behavior of some components, or intercept
	; get_layout somewhere lower in the class hierarchy...	dl 11/4/94
		geomSet_layout label near
		ForceRef geomSet_layout
		
		mov	dx, HINT_ORIENT_CHILDREN_HORIZONTALLY
		mov	ax, HINT_ORIENT_CHILDREN_VERTICALLY
		les	di, ss:[bp].SPA_compDataPtr
		tst	es:[di].CD_data.LD_integer
		jnz	setLayout

		mov	dx, HINT_ORIENT_CHILDREN_VERTICALLY
		mov	ax, HINT_ORIENT_CHILDREN_HORIZONTALLY
setLayout:
		call	ObjVarDeleteData
		
		mov_tr	ax, dx			; hint to be added
		clr	cx
		call	ObjVarAddData
		jmp	done

if 0
geomSet_justifychildren label near
	;
	; Justify bitfield:
	;	7 - center horizontal
	;	6 - center vertical
	;	5 - full horizontal
	;	4 - full vertical
	;	3 - top
	;	2 - right
	;	1 - left
	;	0 - bottom
	;
	; NOTE:	 This implementation is pretty simpleminded -- we always send
	; a message, no matter how few hints are changing.  Could easily be
	; optimized by saving these flags in instance data and comparing the
	; next time they get set.  Then, we'd have to worry about the flags
	; getting out of sync with the actual hints, say if someone sent
	; MSG_GEN_ADD_GEOMETRY_HINT directly to the component...
	;
	; One optimization we do take advantage of is updating the geometry
	; manually at the end of the loop.

	; dl 3/15/95:  Changed to use ObjVar routines to prevent stupid
	; OLScrollList from crashing while not usable... grumble... it's
	; probably a good optimization anyway.
	;
		les	bx, ss:[bp].SPA_compDataPtr
		mov	dx, es:[bx].CD_data.LD_integer
		mov	di, offset justifyHintTable
		mov	ax, cs:[di]	; get the hint we're dealing with
		clr	cx		; zero size for hint data
justifyLoop:
	;
	; dx = hints remaining
	; ax = hint we're currently dealing with
	; ds:si = instance
	; cs:di = table of hints remaining
	;
		shr	dx
		jnc	removeHint
		call	ObjVarAddData
		jmp	contLoop
removeHint:
		call	ObjVarDeleteData
contLoop:
		
		add	di, size word	; point to next hint
		mov	ax, {word} cs:[di]
		tst	ax
		LONG jz	done
		jmp	justifyLoop
endif
if 0
geomSet_tiled label near
	; 
	; The tiled property specifies whether or not a given
	; GoolGeomClass component is managing its childrens' positions.
	; First, store the value of the property in the dynamic property
	; table.  Then inform all children that geometry has been updated so
	; they can either add or remove their ATTR_GEN_POSITION hint.  
	; -martin 4/24/95	 
	;
		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		les	bx, ss:[bp].SPA_compDataPtr
		mov	dx, es:[bx].CD_data.LD_integer
		BitClr	ds:[di].GGI_flags, GGF_TILED
		tst	dx
		jz	updateGeom
		BitSet	ds:[di].GGI_flags, GGF_TILED
updateGeom:
		call	GadgetGeomUpdateChildManagement
		jmp	done

geomSet_tileSpacing label near

endif

	;
	; XXX SAVE THIS CODE FOR HFIT, VFIT PROPERTIES!!!
	;
if 0
	;
	; The logic here is a bit hard to follow -- we want to add two hints
	; and remove two hints based on the value passed in.
	; 

		les	di, ss:[bp].SPA_compDataPtr
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	typeError
		mov	ax, HINT_NO_WIDER_THAN_CHILDREN_REQUIRE
		push	ax
		mov	ax, HINT_EXPAND_WIDTH_TO_FIT_PARENT
		push	ax
		mov	ax, HINT_EXPAND_HEIGHT_TO_FIT_PARENT
		mov	dx, HINT_NO_TALLER_THAN_CHILDREN_REQUIRE
		clr	cx
		tst	es:[di].CD_data.LD_integer
		pushf
		jz	untilespace
		xchg	ax, dx		; ax = no taller, dx = expand height 
untilespace:
		call	ObjVarAddData
		mov_tr	ax, dx
		call	ObjVarDeleteData

		popf
		pop	ax		; ax = expand witdh
		pop	dx		; cx = no wider
		jz	untilespace2
		xchg	ax, dx		; ax = no wider, dx = expand width
untilespace2:
		call	ObjVarAddData
		mov_tr	ax, dx		; ax = hint to remove
		call	ObjVarDeleteData
		jmp	done
endif

done:
ifdef FORCE_GEOMETRY_UPDATES

		popf
		jnc	reallydone
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock
reallydone:
endif
		
		.leave
		ret
GadgetGeomSetTileLayout	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomGetTileInset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_GEOM_GET_TILE_VINSET
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	8/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomGetTileInset	method dynamic GadgetGeomClass, 
					MSG_GADGET_GEOM_GET_TILE_VINSET,
					MSG_GADGET_GEOM_GET_TILE_HINSET
		.enter

		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER

		mov_tr	cx, ax
		mov	ax, ATTR_GADGET_GEOM_INSET_DATA
		call	ObjVarFindData
		mov	ax, 0			;no flags modified!
		jnc	setVal

		mov	ax, ds:[bx].GGID_vertical
		cmp	cx, MSG_GADGET_GEOM_GET_TILE_VINSET
		je	setVal
		mov	ax, ds:[bx].GGID_horizontal
setVal:
		mov	es:[di].CD_data.LD_integer, ax
		
		.leave
		ret
GadgetGeomGetTileInset	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomSetTileInset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the tileInset properties

CALLED BY:	MSG_GADGET_GEOM_SET_TILE_INSET
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	8/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomSetTileInset	method dynamic GadgetGeomClass, 
					MSG_GADGET_GEOM_SET_TILE_HINSET,
					MSG_GADGET_GEOM_SET_TILE_VINSET
		.enter

		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		mov	dx, es:[di].CD_data.LD_integer

		mov_tr	cx, ax			; save msg
		mov	ax, ATTR_GADGET_GEOM_INSET_DATA
		call	ObjVarFindData
		jnc	createData
haveData:
		cmp	cx, MSG_GADGET_GEOM_SET_TILE_VINSET
		je	havePtr
		add	bx, offset GGID_horizontal
havePtr:
	CheckHack <offset GGID_vertical eq 0>
		mov	{word} ds:[bx], dx

		.leave
		ret
createData:
		push	cx
		mov	cx, size GadgetGeomInsetData
		call	ObjVarAddData
		pop	cx
		jmp	haveData
GadgetGeomSetTileInset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomVisCompGetMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the size of our margins

CALLED BY:	MSG_VIS_COMP_GET_MARGINS
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	8/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomVisCompGetMargins	method dynamic GadgetGeomClass, 
					MSG_VIS_COMP_GET_MARGINS
		.enter

		mov	di, offset GadgetGeomClass
		call	ObjCallSuperNoLock

		push	ax
		mov	ax, ATTR_GADGET_GEOM_INSET_DATA
		call	ObjVarFindData
		pop	ax
		jnc	done

		add	ax, ds:[bx].GGID_horizontal
		add	bp, ds:[bx].GGID_vertical
		add	cx, ds:[bx].GGID_horizontal
		add	dx, ds:[bx].GGID_vertical
done:
		.leave
		ret
GadgetGeomVisCompGetMargins	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomSpecBuildBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store self in GGI_childParent so we can access it later
		if needed.  No extra object creation is done here.

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We need to set GGI_childParent even if we are not tiled
		so GetParentPosition won't crash.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomSpecBuildBranch	method dynamic GadgetGeomClass, 
					MSG_SPEC_BUILD_BRANCH
		.enter
		test	ds:[di].GGI_flags, mask GGF_TILED
		pushf

		mov	di, offset GadgetGeomClass
		call	ObjCallSuperNoLock

	;
	; Tell ourself that we are the direct VisParent of our children.
	; (this isn't true for subclasses of us)
	;
		Assert	objectPtr, dssi, GadgetGeomClass
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGeom_offset
		mov	bx, ds:[LMBH_handle]
		movdw	ds:[di].GGI_childParent, bxsi
		popf
		jnz	done

	;
	; FIXME: I don't know if this next part is still needed or not.
	; Programming by trial and error sucks.
		
		mov	ax, MSG_VIS_SET_GEO_ATTRS
		mov 	cl, mask VGA_ALWAYS_RECALC_SIZE ;or mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID
		clr	ch

		mov	dl, VUM_MANUAL
		call	ObjCallInstanceNoLock

		call	VisMarkFullyInvalid
		

done:
		.leave
		ret
GadgetGeomSpecBuildBranch	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomVisRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell whoever cares what our size should be.
		If not tiled, let the geometry manager figure it out,
		otherwise compute it based on our size controls.

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
		ax	= message #
		cx	= RecalcSizeArgs -- suggest width for object
		dx	= RecalcSizeArgs -- suggest height for object
RETURN:		cx	= widt to use
		dx	= height to use
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomVisRecalcSize	method dynamic GadgetGeomClass, 
					MSG_VIS_RECALC_SIZE

		.enter
		test	ds:[di].GGI_flags, mask GGF_TILED
		jz	custom

callSuper::
	; the superclass needs to be called when not tiling, otherwise, buttons
	; dropped at build time don't show up for some weird reason.
	;
	
		mov	di, offset GadgetGeomClass
		call	ObjCallSuperNoLock
		jmp	done

custom::
	;		call	GadgetUtilUnManageChildren
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
		call	GadgetUtilSizeSelf
	;	call	GadgetUtilManageChildren
	
		
done:

		.leave
		ret
GadgetGeomVisRecalcSize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the current flags

CALLED BY:	MSG_GADGET_GEOM_GET_FLAGS
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	11/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomGetFlags	method dynamic GadgetGeomClass, 
					MSG_GADGET_GEOM_GET_FLAGS
		.enter
		clr	ch
		mov	cl, ds:[di].GGI_flags
		.leave
		ret
GadgetGeomGetFlags	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomGetVisChildParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used to get Vis object that is holding our children.
		Really only useful on forms, clippers, dialogs where
		it is different than self.

CALLED BY:	MSG_GADGET_GEOM_GET_VIS_CHILD_PARENT
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
RETURN:		cx:dx	= Vis object that holds children or 0 if not
			  special or if tiling.
DESTROYED:	bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	12/ 1/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomGetVisChildParent	method dynamic GadgetGeomClass, 
					MSG_GADGET_GEOM_GET_VIS_CHILD_PARENT
		.enter
		movdw	cxdx, ds:[di].GGI_childParent
		.leave
		ret
GadgetGeomGetVisChildParent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store childParent so it is something valid before
		MSG_SPEC_BUILD_BRANCH is sent.

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	12/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomMetaInitialize	method dynamic GadgetGeomClass, 
					MSG_META_INITIALIZE
		.enter
		mov	di, offset GadgetGeomClass
		call	ObjCallSuperNoLock
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGeom_offset
		
		mov	bx, ds:[LMBH_handle]
		movdw	ds:[di].GGI_childParent, bxsi		; self
		.leave
		ret
GadgetGeomMetaInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomGetNumChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of children we've got.

CALLED BY:	MSG_GADGET_GEOM_GET_NUM_CHILDREN
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		GetPropertyArgs filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 6/ 6/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomGetNumChildren	method dynamic GadgetGeomClass, 
					MSG_GADGET_GEOM_GET_NUM_CHILDREN
		.enter
	;
	; EntClass does child-support:)
	;
		mov	ax, MSG_ENT_GET_NUM_CHILDREN
		call	ObjCallInstanceNoLock
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetGeomGetNumChildren	endm

GadgetGeomSetNumChildren	method dynamic GadgetGeomClass,
					MSG_GADGET_GEOM_SET_NUM_CHILDREN,
					MSG_GADGET_GEOM_ACTION_SET_CHILDREN
		.enter

		mov	ax, CPE_READONLY_PROPERTY
		call	GadgetUtilReturnSetPropError
		
		.leave
		ret
GadgetGeomSetNumChildren	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomActionGetChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the gadget's children.

CALLED BY:	MSG_GADGET_GEOM_ACTION_GET_CHILDREN
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
		ss:bp	= EntDoActionArgs
RETURN:		ComponentData filled in (_retVal)
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 6/ 6/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGeomActionGetChildren	method dynamic GadgetGeomClass, 
					MSG_GADGET_GEOM_ACTION_GET_CHILDREN
		.enter
	;
	; Have EntClass take care of this for us.
	;
		mov	ax, MSG_ENT_GET_CHILDREN
		call	ObjCallInstanceNoLock
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetGeomActionGetChildren	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGeomGadgetAllowGraphicMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Only allow groups, not windowed things to have graphic
		monikers

CALLED BY:	MSG_GADGET_SET_GRAPHIC
PASS:		*ds:si	= GadgetGeomClass object
		ds:di	= GadgetGeomClass instance data
		ds:bx	= GadgetGeomClass object (same as *ds:si)
		es 	= segment of GadgetGeomClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/ 4/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
REMOVED 4/22/96 dl
Only button, choice, toggle, picture have a graphic these days...

GadgetGeomGadgetAllowGraphicMoniker	method dynamic GadgetGeomClass, 
					MSG_GADGET_SET_GRAPHIC
		uses	es, di
		.enter
		mov	ax, segment GadgetGroupClass
		mov	es, ax
		mov	di, offset GadgetGroupClass
		call	ObjIsObjectInClass
		mov	ax, 0
		jnc	notAllowed
		mov	ax, segment GadgetGeomClass
		mov	es, ax
		mov	di, offset GadgetGeomClass
		mov	ax, MSG_GADGET_SET_GRAPHIC
		call	ObjCallSuperNoLock
		jmp	done
notAllowed:

		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_SPECIFIC_PROPERTY_ERROR
		
done:
		.leave
		ret
GadgetGeomGadgetAllowGraphicMoniker	endm
endif
