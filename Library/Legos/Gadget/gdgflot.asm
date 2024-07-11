COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gdgflot.asm

AUTHOR:		Jimmy Lefkowitz, Jul 18, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/18/95   	Initial revision


DESCRIPTION:
	floater window component
		

	$Id: gdgflot.asm,v 1.1 98/03/11 04:29:38 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


idata	segment
	GadgetFloaterClass
idata	ends

FLOATER_INITIAL_SIZE	equ 150
MAX_FLOATER_SIZE	equ 1023

GadgetFloaterCode	segment resource

makeActionEntry floater, RedoGeometry, MSG_GADGET_FLOATER_ACTION_REDO_GEOMETRY, LT_TYPE_UNKNOWN, 0

compMkActTable 	floater, RedoGeometry

makePropEntry floater, mask, LT_TYPE_UNKNOWN,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_FLOATER_GET_MASK>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_FLOATER_SET_MASK>

makeUndefinedPropEntry	floater, caption
makeUndefinedPropEntry	floater, enabled
makeUndefinedPropEntry	floater, look
makeUndefinedPropEntry	floater, graphic
compMkPropTable GadgetButtonProperty, floater, \
	mask, caption, enabled, look, graphic



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PropRoutines and ActionRoutines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	standard get/set/resolves method handlers
		defined by the macro MakePropRoutines and MakeActionRoutines

CALLED BY:	MSG_ENT_[GET|SET|RESOLVE]_PROPERTY, DO_ACTION
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakePropRoutines Floater, floater
MakeActionRoutines Floater, floater



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFloaterEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	arrange our guts the way we wants 'em

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetFloaterClass object
		ds:di	= GadgetFloaterClass instance data
		ds:bx	= GadgetFloaterClass object (same as *ds:si)
		es 	= segment of GadgetFloaterClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	6/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFloaterEntInitialize	method dynamic GadgetFloaterClass, 
					MSG_ENT_INITIALIZE
		.enter

	;
	; Tell superclass to do its thing.
	;
		mov	di, offset GadgetFloaterClass
		call	ObjCallSuperNoLock

	;
	; Set up attrs/hints.  Note that superclass has already set
	; up our window priority and ability to accept ink if not
	; focused.  FIXME: perhaps only on-tops should accept ink if
	; not focused.
	;
		mov	di, ds:[si]
		add	di, ds:[di].GadgetFloater_offset
		mov	ds:[di].GFI_width, FLOATER_INITIAL_SIZE
		mov	ds:[di].GFI_height, FLOATER_INITIAL_SIZE
		
		mov	ax, ATTR_GEN_WINDOW_CUSTOM_WINDOW
		clr	cx
		call	ObjVarAddData

		mov	ax, HINT_INTERACTION_FOCUSABLE
		call	ObjVarAddData
		
		mov	ax, HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT
		mov	cx, size SpecWinSizePair
		call	ObjVarAddData
		mov	ds:[bx].SWSP_x, FLOATER_INITIAL_SIZE
		mov	ds:[bx].SWSP_y, FLOATER_INITIAL_SIZE

		.leave
		ret
GadgetFloaterEntInitialize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFloaterMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform the system of our association to GenInteraction

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= GadgetFloaterClass object
		ds:di	= GadgetFloaterClass instance data
		ds:bx	= GadgetFloaterClass object (same as *ds:si)
		es 	= segment of GadgetFloaterClass
		ax	= message #
RETURN:		cx:dx	= superclass to use
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
 	----	----		-----------
	dloft	6/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFloaterMetaResolveVariantSuperclass	method dynamic GadgetFloaterClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

		compResolveSuperclass	GadgetFloater, GenInteraction

GadgetFloaterMetaResolveVariantSuperclass	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFloaterGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return "floater"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetFloaterClass object
		ds:di	= GadgetFloaterClass instance data
		ds:bx	= GadgetFloaterClass object (same as *ds:si)
		es 	= segment of GadgetFloaterClass
		ax	= message #
RETURN:		cx:dx	= "floater"
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFloaterGetClass	method dynamic GadgetFloaterClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetFloaterString
		mov	dx, offset GadgetFloaterString
		ret
GadgetFloaterGetClass	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFloaterGetDim
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_WIN_GET_TOP/LEFT/WIDTH/HEIGHT
PASS:		*ds:si	= GadgetWindowClass object
		ds:di	= GadgetWindowClass instance data
		ds:bx	= GadgetWindowClass object (same as *ds:si)
		es 	= segment of GadgetWindowClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 5/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFloaterGetDim	method dynamic GadgetFloaterClass,
					MSG_GADGET_GET_WIDTH,
					MSG_GADGET_GET_HEIGHT,
					MSG_GADGET_GET_TOP,
					MSG_GADGET_GET_LEFT

		.enter

		mov	bx, ds:[si]
		add	bx, ds:[bx].GadgetFloater_offset
		les	di, ss:[bp].SPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_INTEGER

	; if it's a get routine, fetch the value from instance data
		cmp	ax, MSG_GADGET_GET_WIDTH
		je	getWidth
		cmp	ax, MSG_GADGET_GET_HEIGHT
		je	getHeight
		cmp	ax, MSG_GADGET_GET_LEFT
		je	getLeft
		jmp	getTop
	
getWidth:
		mov	dx, ds:[bx].GFI_width
		jmp	stuffValue
getHeight:
		mov	dx, ds:[bx].GFI_height
		jmp	stuffValue
getLeft:
		mov	dx, ds:[bx].GFI_left
		jmp	stuffValue
getTop:
		mov	dx, ds:[bx].GFI_top
stuffValue:
		mov	es:[di].CD_data.LD_integer, dx
		.leave
		ret
GadgetFloaterGetDim	endm
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetFloaterSetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_WIN_GET/SET_HEIGHT/WIDTH
PASS:		*ds:si	= GadgetWindowClass object
		ds:di	= GadgetWindowClass instance data
		ds:bx	= GadgetWindowClass object (same as *ds:si)
		es 	= segment of GadgetWindowClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 5/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetFloaterSetSize	method dynamic GadgetFloaterClass,
					MSG_GADGET_SET_WIDTH,
					MSG_GADGET_SET_LEFT,
					MSG_GADGET_SET_HEIGHT,
					MSG_GADGET_SET_TOP
passedBP	local	word	push bp
msg		local	word		
window		local	word
self		local	word
off		local	word
val		local	word		
		uses	bx
		.enter

	; store away some useful values - registers just aren't enough
		mov	ss:[msg], ax
		mov	ss:[self], si
	; now fetch in the value to be set, if it is out of range, set to range
		push	bp 
		mov	bp, ss:[passedBP]
		call	CheckValue
		pop	bp
		jc	wrongType
		push	cx		; save value to be set on stack
		
		push	bp
		mov	bp, ss:[passedBP]
		mov	bx, segment GadgetFloaterClass
		mov	es, bx
		mov	di, offset  GadgetFloaterClass
		call	ObjCallSuperNoLock

	; see if we have a window around or not
		mov	ax, MSG_VIS_QUERY_WINDOW
		call	ObjCallInstanceNoLock
		pop	bp
		
	; save away the window handle
		mov	ss:[window], cx
		pop	cx		; value to be set


	; if we don't have a window around, just update the instance
	; data
		mov	ss:[val], cx
		mov	si, cx
		mov	di, ss:[window]
		tst	di
		jz	gotBounds
	; if there is a window around, we need to resize it
		call	WinGetWinScreenBounds
gotBounds:
		cmp	ss:[msg], MSG_GADGET_SET_TOP
		je	setTop
		cmp	ss:[msg], MSG_GADGET_SET_LEFT
		je	setLeft
		cmp	ss:[msg], MSG_GADGET_SET_WIDTH
		je	setWidth
;setHeight:
		mov	ss:[off], offset GFI_height
		mov	dx, bx
		add	dx, si
		jmp	setSize
setTop:
		mov	bx, si
		mov	ss:[off], offset GFI_top
		jmp	setPos
setLeft:
		mov	ss:[off], offset GFI_left
		mov	ax, si
setPos:
		tst	di
		jz	setInstance
		mov	si, mask WPF_ABS
		call	WinMove
		jmp	setInstance


setWidth:
		mov	ss:[off], offset GFI_width
		mov	cx, ax
		add	cx, si
		
setSize:
	; clear out bp, si as we are not using a region
	; and push WinPosFlags for absolute size being set
		tst	di
		jz	setInstance

	; do some checking for nonsense values
		cmp	cx, ax
		jge	checkVertical
		xchg	cx, ax
checkVertical:
		cmp	dx, bx
		jge	valuesOk
		xchg	bx, dx
valuesOk:
		push	bp
		mov	bp, mask WPF_ABS
		push	bp
		clr	bp
		mov	si, bp
		call	WinResize
		pop	bp

		sub	dx, bx
		sub	cx, ax

setInstance:
		mov	si, ss:[self]

	; stuff the new width/height into instance data
		mov	di, ds:[si]
		add	di, ds:[di].GadgetFloater_offset
		add	di, ss:[off]
		mov	ax, ss:[val]
		mov	{word}ds:[di], ax
done:
		.leave
		ret
wrongType:
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_PROPERTY_TYPE_MISMATCH
		jmp	done		
GadgetFloaterSetSize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Check if the passed value is on range, if it is out of range
		canstrain to range

CALLED BY:	MSG_GET_SET_*
PASS:		ss:bp	= SetPropertyArgs
		ax	= method number
RETURN:		cx	= valid value to set
		SPA_cpmData is also set to valid value
		carry   = set if wrong type of arg is passed
		es:di	= ComponentData pointed to b SPA_compDataPtr
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		- If it is negative
		    . Set to 0 if it is top or left
		    . Set to 1 if it is width or height
		- For positive value, only check if it is set width or height
		  check if it greater than MAX_FLOATER_SIZE,
		  set to MAX_FLOATER_SIZE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ATRAN	7/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckValue	proc	near		

		.enter
		
		call	GadgetGetPassedWordInCX
		jc	exit		; wrong type is passed
		
		cmp	cx, 0
		jg	havePositiveValue
		cmp	ax, MSG_GADGET_SET_LEFT
		je	set0
		cmp	ax, MSG_GADGET_SET_TOP
		je	set0
		mov	cx, 1
		jmp	done
set0:
		clr	cx
		jmp	done
havePositiveValue:
		cmp	ax, MSG_GADGET_SET_WIDTH
		je	checkMax
		cmp	ax, MSG_GADGET_SET_HEIGHT
		je	checkMax
		jmp	done
checkMax:
		cmp	cx, MAX_FLOATER_SIZE
		jle	done
		mov	cx, MAX_FLOATER_SIZE
done:
		mov	es:[di].CD_data.LD_integer, cx
		clc
exit:
		.leave
		ret
CheckValue	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFVisOpenWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_VIS_OPEN_WIN
PASS:		*ds:si	= GadgetFloaterClass object
		ds:di	= GadgetFloaterClass instance data
		ds:bx	= GadgetFloaterClass object (same as *ds:si)
		es 	= segment of GadgetFloaterClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFVisOpenWin	method dynamic GadgetFloaterClass, 
					MSG_VIS_OPEN_WIN
		uses	ax, cx, dx, bp
		.enter
	; create the default window first
		mov	di, offset GadgetFloaterClass
		call	ObjCallSuperNoLock

	; now fetch it
		mov	ax, MSG_VIS_QUERY_WINDOW
		call	ObjCallInstanceNoLock
		jcxz	done

		mov	di, ds:[si]
		add	di, ds:[di].GadgetFloater_offset

		push	si
		
		tst	ds:[di].GFI_region
		jnz	doRegion

		mov	si, cx
		mov	ax, ds:[di].GFI_left
		mov	bx, ds:[di].GFI_top
		mov	cx, ax
		add	cx, ds:[di].GFI_width
		mov	dx, bx
		add	dx, ds:[di].GFI_height
		mov	di, si
		mov	bp, mask WPF_ABS
		push	bp
		clr	si
		mov	bp, si
resize:
		call	WinResize
		pop	si
done:
		.leave
		ret
doRegion:
	; point bp:si = region
		mov	si, ds:[di].GFI_region
		mov	si, ds:[si]
		
		mov	bp, ds
		mov	ax, mask WPF_ABS
		mov	di, cx
		push	ax
		
	; FIXME - use region params
		clr	ax
		mov	bx, ax
		mov	cx, ax
		mov	dx, ax
		jmp	resize
GFVisOpenWin	endm


if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFMetaDragSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_DRAG_SELECT
PASS:		*ds:si	= GadgetFloaterClass object
		ds:di	= GadgetFloaterClass instance data
		ds:bx	= GadgetFloaterClass object (same as *ds:si)
		es 	= segment of GadgetFloaterClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFMetaDragSelect	method dynamic GadgetFloaterClass, 
					MSG_META_DRAG_SELECT
		uses	cx, dx, bp
		.enter

		mov	di, ds:[si]
		add	di, ds:[di].GadgetFloater_offset
		mov	ds:[di].GFI_drag, 1
		
		mov	ax, mask MRF_PROCESSED

		.leave
		ret
GFMetaDragSelect	endm


GFMetaStartSelect	method dynamic GadgetFloaterClass, 
					MSG_META_START_SELECT
		uses	cx, dx, bp
		.enter

		mov	ax, MSG_VIS_GRAB_MOUSE
		call	ObjCallInstanceNoLock

		mov	ax, mask MRF_PROCESSED

		.leave
		ret
GFMetaStartSelect	endm

GFMetaEndSelect	method dynamic GadgetFloaterClass, 
					MSG_META_END_SELECT
		uses	cx, dx, bp
		.enter

		mov	ax, MSG_VIS_RELEASE_MOUSE
		call	ObjCallInstanceNoLock

		mov	di, ds:[si]
		add	di, ds:[di].GadgetFloater_offset
		mov	ds:[di].GFI_drag, 0
		
		mov	ax, mask MRF_PROCESSED

		.leave
		ret
GFMetaEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFMetaMousePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_MOUSE_PTR
PASS:		*ds:si	= GadgetFloaterClass object
		ds:di	= GadgetFloaterClass instance data
		ds:bx	= GadgetFloaterClass object (same as *ds:si)
		es 	= segment of GadgetFloaterClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFMetaMousePtr	method dynamic GadgetFloaterClass, 
					MSG_META_MOUSE_PTR
		uses	cx, dx, bp
		.enter

		mov	di, ds:[si]
		add	di, ds:[di].GadgetFloater_offset
		tst	ds:[di].GFI_drag
		jz	done

		mov	bx, ds:LMBH_handle
		mov	ax, MSG_GADGET_FLOATER_WIN_MOVE
		mov	di, mask MF_FORCE_QUEUE or mask MF_REPLACE or \
			    mask MF_CHECK_DUPLICATE
		call	ObjMessage
done:
		mov	ax, mask MRF_PROCESSED
		
		.leave
		ret
GFMetaMousePtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFGadgetFloaterWinMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_FLOATER_WIN_MOVE
PASS:		*ds:si	= GadgetFloaterClass object
		ds:di	= GadgetFloaterClass instance data
		ds:bx	= GadgetFloaterClass object (same as *ds:si)
		es 	= segment of GadgetFloaterClass
		ax	= message #
		cx:dx 	= x, y of where to move
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFGadgetFloaterWinMove	method dynamic GadgetFloaterClass, 
					MSG_GADGET_FLOATER_WIN_MOVE
		uses	ax, cx, dx, bp
		.enter
		push	cx, dx
		mov	ax, MSG_VIS_QUERY_WINDOW
		call	ObjCallInstanceNoLock
		pop	ax, bx
		jcxz	done
		mov	di, cx
	;
	;		push	ax, bx
	;		call	WinGetWinScreenBounds
	;		sub	cx, ax
	;		sub	dx, bx
	;		pop	ax, bx
	;		
	;		shr	cx
	;		shr	dx
	;		sub	ax, cx
	;		sub	bx, dx
		mov	si, 0
		call	WinMove
done:
		.leave
		ret
GFGadgetFloaterWinMove	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= GadgetFloaterClass object
		ds:di	= GadgetFloaterClass instance data
		ds:bx	= GadgetFloaterClass object (same as *ds:si)
		es 	= segment of GadgetFloaterClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSpecBuild	method dynamic GadgetFloaterClass, 
					MSG_SPEC_BUILD
		uses	ax, cx, dx, bp
		.enter
	; this is a primitive component, so lets manage our own
	; children
if 0
		mov	ax, MSG_VIS_COMP_SET_GEO_ATTRS
		mov	cl, mask VCGA_CUSTOM_MANAGE_CHILDREN
		clr	ch
		mov	dx, cx
		not	dl
		call	ObjCallInstanceNoLock
endif
		mov	ax, MSG_SPEC_BUILD

		mov	di, offset GadgetFloaterClass
		call	ObjCallSuperNoLock
		.leave
		ret
GFSpecBuild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValidateRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check to see if a region look reasonable or not

CALLED BY:	
PASS:		es:di = passed array data
		cx = size
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ValidateRegion	proc	far
		uses	es, ds, di, si, ax, bx, cx, dx
		.enter
		segmov	ds, es
		mov	si, di

	; the first word is the size of the region in word
	;		lodsw
	;		mov	cx, ax

		cmp	cx, 2
		jb	error
	; the first scan line is a special case handling -infinity to
	; y1
		lodsw	; ax = y1
		dec	cx
		mov	dx, ax	; dx = last y through the loop
		lodsw
		dec	cx
		cmp	ax, EOREGREC
		jne	error
yLoop:
	; now, for each scan line, we get a y value, followd by one or
	; more x1-x2 pairs, and the an EOREGREC
	; so we are going to make sure that an EOREGREC doesnt fall in
	; an invalid spot, that an EOREGREC is where it should be and
	; that for each x1-x2 pair, x1 < x2
	; and make sure the y values increment the whole time
		jcxz	error
		
		lodsw	; load y
		dec	cx
	; check for end record
		cmp	ax, EOREGREC
		je	doneOK

	; make sure the y value increases each time
		cmp	ax, dx
		jle	error

		mov	dx, ax	; store new y value as the last y

xLoop:
		jcxz	error
		
		lodsw
		dec	cx
	; check for end of x1-x2 pairs
		cmp	ax, EOREGREC
		je	yLoop

		jcxz	error
		mov	bx, ax
		lodsw	; read x2 - cannot be EOREGREC
		dec	cx
		cmp	ax, EOREGREC
		je	error

		cmp	ax, bx	; make sure x1 < x2
		jge	xLoop
error:
		stc
		jmp	done
doneOK:
	; see if the number passed for the size was too large
	; this isn't the end of the world, but it does mean the user
	; is not doing something right
		tst	cx
		jnz	error
		clc
done:		
		.leave
		ret
ValidateRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFGadgetFloaterActionUishape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_FLOATER_SET_MASK
PASS:		*ds:si	= GadgetFloaterClass object
		ds:di	= GadgetFloaterClass instance data
		ds:bx	= GadgetFloaterClass object (same as *ds:si)
		es 	= segment of GadgetFloaterClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFGadgetFloaterActionUishape	method dynamic GadgetFloaterClass, 
					MSG_GADGET_FLOATER_SET_MASK

		.enter
		les	di, ss:[bp].SPA_compDataPtr
		cmp	es:[di].CD_type, LT_TYPE_ARRAY
		jne	wrongType

		mov	bx, es:[di].CD_data.LD_gen_word
	
		call	MemLock
		mov	es, ax
		mov	di, size ArrayHeader

		mov	ax, es:[di]
		mov	cx, ax
		add	di, size word ; advance past size
		call	ValidateRegion
		jc	badRegion
		
	; now calculate the actual number of bytes being used so
	; so we can allocate a chunk to hold the data
		mov	cx, ax
		shl	cx
		clr	al
		call	LMemAlloc

		mov	di, ds:[si]
		add	di, ds:[di].GadgetFloater_offset
		mov	ds:[di].GFI_region, ax

	; now copy in the array data to the chunk we just allocated
		mov	di, ax
		mov	di, ds:[di]
		segmov	es, ds
		call	MemDerefDS
		mov	si, size ArrayHeader + 2
		shr	cx
		rep	movsw
		call	MemUnlock
done:
		.leave
		ret
badRegion:
		call	MemUnlock
		les	di, ss:[bp].SPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error,	CPE_SPECIFIC_PROPERTY_ERROR
		jmp	done
wrongType:
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_PROPERTY_TYPE_MISMATCH
		jmp	done
		
GFGadgetFloaterActionUishape	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFGadgetFloaterActionRedoGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_FLOATER_ACTION_REDO_GEOMETRY
PASS:		*ds:si	= GadgetFloaterClass object
		ds:di	= GadgetFloaterClass instance data
		ds:bx	= GadgetFloaterClass object (same as *ds:si)
		es 	= segment of GadgetFloaterClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/26/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFGadgetFloaterActionRedoGeometry	method dynamic GadgetFloaterClass, 
					MSG_GADGET_FLOATER_ACTION_REDO_GEOMETRY
		uses	ax, cx, dx, bp
		.enter
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjCallInstanceNoLock
		
		.leave
		ret
GFGadgetFloaterActionRedoGeometry	endm


	; try returning 0,0 so MSG_VIS_GET_HEIGHT for children works
	; and catch GAINED_FOCUS here as well since it does nothing real
GFVisGetPosition	method dynamic	GadgetFloaterClass,
					MSG_VIS_GET_POSITION
		.enter
		clrdw	cxdx
		.leave
		ret
GFVisGetPosition	endm
;					MSG_META_GAINED_FOCUS_EXCL,
;					MSG_META_GRAB_FOCUS_EXCL,
;					MSG_META_RELEASE_FOCUS_EXCL


GadgetFloaterCode	ends


