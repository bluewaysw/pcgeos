COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Gadget Library
FILE:		gadgetutil.asm

AUTHOR:		David Loftesness

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	8/31/94		Initial version.

DESCRIPTION:
	

	$Id: gdgutil.asm,v 1.1 98/03/11 04:28:41 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GadgetSetInheritor	proc	far	propName:fptr.char,
					compData:ComponentData
		ForceRef	propName
		ForceRef	compData
		.enter
		.leave
		ret
GadgetSetInheritor	endp

GadgetGetInheritor	proc	far	propName:fptr.char,
					compDataPtr:fptr.ComponentData
		ForceRef	propName
		ForceRef	compDataPtr
		.enter
		.leave
		ret
GadgetGetInheritor	endp

ForceRef	GadgetSetInheritor
ForceRef	GadgetGetInheritor


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilCheckHintAndSetInteger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine for returning a value based on the presence of
		a particular hint

CALLED BY:	INT (GadgetListGetProperty, GadgetGeomGetProperty)
PASS:		ax = hint to look for
	 	ss:bp = GetPropertyArgs
RETURN:		es:di = ptr to GetPropertyArgs
DESTROYED:	dx, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	 3/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilCheckHintAndSetInteger		proc	far
		clr	dx			;dx <- assume not present
		call	ObjVarFindData
		jnc	setVal			;branch if not present
		inc	dx			;dx <- hint present
setVal:
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, dx
		ret
GadgetUtilCheckHintAndSetInteger		endp
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilCheckIntegerAndSetHint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility for set property routines to either add or remove a
		hint based on the integer passed in.

CALLED BY:	INT (GadgetListSetProperty)
PASS:		es:di	= ComponentData
		ax	= hint
RETURN:		nothing
DESTROYED:	stuff
SIDE EFFECTS:	depend on what's passed in

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	 3/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilCheckIntegerAndSetHint	proc	far
		.enter

		clr	cx
		tst	es:[di].CD_data.LD_integer
		jnz	addHint

		call	ObjVarDeleteData
		jmp	done
addHint:
		call	ObjVarAddData
done:
		.leave
		ret
GadgetUtilCheckIntegerAndSetHint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilUpdateVarDataDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures the vardata is created for this object and that
		the current value is that which is passed in

CALLED BY:	GadgetSetProperty
PASS:		ax	= VarData to add
		cxdx	= dword to set vardata to
		ds:si	= object to add data to
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 3/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilUpdateVarDataDWord	proc	far
	uses	bx
	.enter
		call	ObjVarFindData
		jc	setVal
		push	cx
		mov	cx, size dword
		call	ObjVarAddData
		pop	cx
	; ds:bx points at space to write dword
		
setVal:
		Assert	fptr	dsbx
		movdw	ds:[bx], cxdx
	.leave
	ret
GadgetUtilUpdateVarDataDWord	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilGenSetFixedSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine for sending MSG_GEN_SET_FIXED_SIZE

CALLED BY:	EXTERNAL
PASS:		cx = SpecWidth
		dx = SpecHeight
		al = VisUpdateMode
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilGenSetFixedSize	proc	far
	uses	ax, cx, dx
		.enter

		.assert	SST_PIXELS eq 0
		
	; the largest size allowed is 1023 as the upper bits are the
	; size type, so nuke the bits and replace them with SST_PIXELS
	; which happend to be zero. Don't use AND, clip to 1023.
		cmp	cx, 1023
		jbe	checkDX
		mov	cx, 1023
checkDX:
		cmp	dx, 1023
		jbe	valuesCorrected
		mov	dx, 1023
valuesCorrected:
		
		push	bp
		sub	sp, SetSizeArgs
		mov	bp, sp
		mov	ss:[bp].SSA_width, cx
		mov	ss:[bp].SSA_height, dx
		clr	ss:[bp].SSA_count
		mov	ss:[bp].SSA_updateMode, al
		mov	ax, MSG_GEN_SET_FIXED_SIZE
		mov	dx, size SetSizeArgs
		call	ObjCallInstanceNoLock
		add	sp, SetSizeArgs
		pop	bp
		
		.leave
		ret
GadgetUtilGenSetFixedSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilVisRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for composites that don't want the ui to grow them
		based on their children.
CALLED BY:	MSG_VIS_COMP_RECALC_SIZE handlers
PASS:		*ds:si		- Some component that has a Vis part.
		cx, dx		- recommended sizes
RETURN:		cx, dx		- passed in
DESTROYED:	ax, bx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilVisRecalcSize	proc	far
	uses	ax, cx, dx
		.enter
		mov	bx, cs
		mov	di, offset ForceRecalcCallback
		call	GadgetUtilVisProcessChildren
	.leave
	ret
GadgetUtilVisRecalcSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilVisProcessChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine for calling a callback on all vis children.

CALLED BY:	INTERNAL
PASS:		*ds:si		- composite
		bx:di		- fptr.callback
		cx, dx		- data for callback
				(callback returns carry to stop)
RETURN:		cx, dx		- data from callback
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilVisProcessChildren	proc	far
		uses	bp, si
		.enter

	;
	;  Make sure we process the right children.
	;
		push	cx, dx, bx, di			; args
		call	GadgetUtilGetCorrectVisParent
		jcxz	noChildPop
		movdw	bxsi, cxdx
		call	ObjLockObjBlock
		mov	ds, ax
		mov	ax, bx
		pop	cx, dx, bx, di
		push	ax				; obj block
	

	;		Assert	objectPtr dssi, VisCompClass
	;	Assert	objectPtr dssi, EntClass
	; Make sure we have children, so ObjCompProcessChildren
	; doesn't barf.
		push	cx, dx				; args
		mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
		clr	cx
		call	ObjCallInstanceNoLock
		pop	ax, bp				; arg1, arg2
		jc	noChild
		jcxz	noChild				; sometimes carry \
							; isnt set.

	; FIXME: change to use VIS_SEND_TO_CHILDREN so we don't use
	; Vis instance data.
.warn -private
		pushdw	cxdx				; first child
		movdw	cxdx, axbp			; arg1, arg2
		mov	ax, offset VI_link
		push	ax				; link part
		pushdw	bxdi				; callback
		mov	bx, offset Vis_offset
		mov	di, offset VCI_comp
.warn @private		
		call	ObjCompProcessChildren		; fixes up stack
		jmp	noChild
noChildPop:
		add	sp, 8			; clean up stack
		jmp	done
noChild:
		pop	bx
		call	MemUnlock
done:
	.leave
	ret
GadgetUtilVisProcessChildren	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilSizeSelf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines what the size should be based on hints
		and children.

CALLED BY:	
PASS:		cx, dx		- size of parent / suggested size
		*ds:si		- VisComp object
RETURN:		cx, dx		- size to set self
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If its fixed size, return that.
		If expand-to-fit, return parents size
		Else, compute size needed to fit around children.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilSizeSelf	proc	far
		cdata	local	ComponentData
		spa	local	SetPropertyArgs
		wMargin	local	word
		hMargin	local	word
		uses	ax,bx,si,di, bp
		.enter
	;
	; Get margins so we can add them to size of children if
	; needed.
	;
		Assert	objectPtr, dssi, VisCompClass
		pushdw	cxdx				; args
		push	bp				; frame ptr
		mov	ax, MSG_VIS_COMP_GET_MARGINS
		call	ObjCallInstanceNoLock
		mov	bx, bp
		pop	bp				; frame ptr
		add	ax, cx
		add	bx, dx
		mov	ss:[wMargin], ax
		mov	ss:[hMargin], bx
		popdw	cxdx				;args

		push	bp				; frame ptr
		lea	bx, ss:[cdata]
		movdw	ss:[spa].SPA_compDataPtr, ssbx
		lea	bp, ss:[spa]

		push	cx, dx				; parent size
		mov	ax, MSG_GADGET_GET_SIZE_VCONTROL
		call	ObjCallInstanceNoLock
		pop	cx, dx				; parent size
		pop	bp				; frame ptr

		cmp	ss:[cdata].CD_data.LD_integer, GSCT_AS_SPECIFIED
		jne	checkMax
	;
	; If there is a temp vis inval region, then it is probably
	; because the window border was just size and we should
	; return that size.
	; Note it is not okay just to return, we have grab the size out
	; of the region or groups get messed up (too big).
if 0		; wait for other fix		
		mov	ax, TEMP_VIS_OLD_BOUNDS
		call	ObjVarFindData
		jc	done
endif		; wait for other fix.

fixed::
		mov	ax, HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT
		call	ObjVarFindData
		jnc	checkWinHeight
		tst	ds:[bx].SWSP_y
		je	checkMax
		mov	dx, ds:[bx].SWSP_y
		jmp	with
checkWinHeight:
		mov	ax, HINT_FIXED_SIZE
		call	ObjVarFindData
		jnc	smallOrNeeded
		tst	ds:[bx].SSA_height
		je	checkMax
		mov	dx, ds:[bx].SSA_height
		jmp	with
		
checkMax:
		cmp	ss:[cdata].CD_data.LD_integer, GSCT_AS_BIG_AS_POSSIBLE
		jne	smallOrNeeded
		push	cx				; save width
		call	GadgetUtilComputeParentInteriorSize
		pop	cx				; restore width
		jmp	with

smallOrNeeded::
		push	cx				; save width
		call	GadgetUtilComputeSizeOfChildren
		pop	cx				; width
		add	dx, ss:[hMargin]

with:
		push	bp				; frame ptr
		lea	bp, ss:[spa]
		push	cx, dx				; parent size
		mov	ax, MSG_GADGET_GET_SIZE_HCONTROL
		call	ObjCallInstanceNoLock
		pop	cx, dx				; parent size
		pop	bp				; frame ptr
		cmp	ss:[cdata].CD_data.LD_integer, GSCT_AS_SPECIFIED
		jne	checkMaxW
fixedW::
		mov	ax, HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT
		call	ObjVarFindData
		jnc	checkWinWidth
		tst	ds:[bx].SWSP_x
		je	checkMaxW
		mov	cx, ds:[bx].SWSP_x
		jmp	done
checkWinWidth:
		mov	ax, HINT_FIXED_SIZE
		call	ObjVarFindData
		jnc	smallOrNeededW
		tst	ds:[bx].SSA_width
		je	checkMaxW
		mov	cx, ds:[bx].SSA_width
		jmp	done
checkMaxW:
		cmp	ss:[cdata].CD_data.LD_integer, GSCT_AS_BIG_AS_POSSIBLE
		jne	smallOrNeededW
		push	dx				; height
		call	GadgetUtilComputeParentInteriorSize
		pop	dx				; height
		jmp	done
smallOrNeededW::
		push	dx				; save height
	; if we computed height this way, we could probably get
	; rid of this call.
	; (make one optimization at the top that sees if they are both set).
		
		call	GadgetUtilComputeSizeOfChildren
		pop	dx				; height
		add	cx, ss:[wMargin]

done:
	;
	; Make sure the size is at least the minimum allowed size.
	;	FIXME: should only call if VCGDA_HAS_MINIMUM_SIZE is set.
		push	bp			; frame ptr
		pushdw	cxdx		; computed size
		mov	ax, MSG_VIS_COMP_GET_MINIMUM_SIZE
		call	ObjCallInstanceNoLock
		popdw	axbx		; computed size
		pop	bp			; frame ptr

	; cxdx - min, axbx - real
		cmp	cx, ax
		jge	checkH
		xchg	cx, ax
checkH:
		cmp	dx, bx
		jge	bye
		xchg	dx, bx
bye:
		.leave
		ret
GadgetUtilSizeSelf	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilComputeParentInteriorSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the size of the interior of the parent.  If there is
		no parent, then returns size passed in (form, dialogs ...)

CALLED BY:	GadgetUtilSizeSelf
PASS:		*ds:si		- VisObject
RETURN:		cx		- width of parent
		dx		- height of parent
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	11/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilComputeParentInteriorSize	proc	near
	uses	ax,bx,bp
		.enter
	; if its a win group then return passed size, don't try to
	; expand.  (I guess we could ask for the size of the screen ....)
	;
		push	cx, dx			; width, height
		mov	ax, MSG_VIS_GET_TYPE_FLAGS
		call	ObjCallInstanceNoLock
		mov	al, cl			; VisTypeFlags
		pop	cx, dx			; width, height
		test	al, mask VTF_IS_WIN_GROUP
		jnz	done
	;
	; Get the size of the parent
	;
		mov	ax, MSG_VIS_GET_SIZE
		call	VisCallParent
		push	cx, dx			; parent size

		mov	ax, MSG_VIS_COMP_GET_MARGINS
		call	VisCallParent
		add	ax, cx			; border width
		mov	bx, bp
		add	bx, dx			; border height

		pop	cx, dx			; parent size
	; remove borders from parent so we know how big to make ourself
		
		sub	cx, ax
		sub	dx, bx
		
done:
		.leave
		ret
GadgetUtilComputeParentInteriorSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilComputeSizeOfChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		*ds:si		- VisComp
RETURN:		cx, dx		- largest space needed by child
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilComputeSizeOfChildren	proc	near
		uses	bx,di
		.enter
		mov	bx, cs
		mov	di, offset ComputeWidthCallback
		clr	cx, dx				; init size
		call	GadgetUtilVisProcessChildren
		.leave
		ret
GadgetUtilComputeSizeOfChildren	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeWidthCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells each child to figure what its size and set itself
		to that size.

CALLED BY:	GadgetGadgetVisRecaclSize
PASS:		*ds:si		- child
		*es:di		- parent composite
		cx, dx		- max size so far
RETURN:		cx, dx		- new max size
DESTROYED:	ax, bp, bx, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeWidthCallback	proc	far
		.enter
		push	cx, dx			; - max sizes
	;
	; Bummer, Vis Position not set yet, use HINTs.
		clrdw	cxdx
		mov	ax, ATTR_GEN_POSITION_X
		call	ObjVarFindData
		jnc	checkY
		mov	cx, ds:[bx]
checkY:
		mov	ax, ATTR_GEN_POSITION_Y
		call	ObjVarFindData
		jnc	getSize
		mov	dx, ds:[bx]
getSize:
		movdw	bpbx, cxdx
		mov	ax, MSG_VIS_GET_SIZE
		call	ObjCallInstanceNoLock
		add	bp, cx
		add	bx, dx
		pop	cx, dx			; - max size
		cmp	bp, cx
		jle	checkHeight
		xchg	bp, cx
checkHeight:
		cmp	bx, dx
		jle	done
		xchg	bx, dx
done:
		
		.leave
		Destroy	bx, si, di, bp
		clc
		ret
ComputeWidthCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceRecalcCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells each child to figure what its size and set itself
		to that size.

CALLED BY:	GadgetGadgetVisRecaclSize
PASS:		*ds:si		- child
		*es:di		- parent composite
		cx, dx		- desired sizes
RETURN:		cx, dx		- unchanged
DESTROYED:	ax, bp, bx, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceRecalcCallback	proc	far
		uses	cx, dx	
		.enter
		mov	ax, MSG_VIS_RECALC_SIZE
		call	ObjCallInstanceNoLock
		mov	ax, MSG_VIS_SET_SIZE
		call	ObjCallInstanceNoLock
.warn -private
		Assert	objectPtr dssi, VisClass		
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		and	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID or mask VOF_GEO_UPDATE_PATH)
.warn @private
		
		.leave
		Destroy	bx, si, di
		clc
		ret
ForceRecalcCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilPositionChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Positions all Ent children of the object.

CALLED BY:	GLOBAL
PASS:		*ds:si		- Gen Object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		For things like primaries, we need to position all the
		children of the OLGadgetArea, not of the GenPrimary.
		To find the children:
			1) Get the first Gen child.
			2) Get its vis parent.
			3) enumerate all the vis children.

		In step 1), we want the gen child, not the ent child.
		The ent child may not be a vis thing.  If the Gen child
		is not ent, we have some problems.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilPositionChildren	proc	far
		uses	cx,bp
		.enter
		mov	bx, cs
		mov	di, offset PositionChildCallback
		call	GadgetUtilVisProcessChildren
		.leave
		ret
GadgetUtilPositionChildren	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionChildCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Positions ent children where they should go.

CALLED BY:	
PASS:		ATTR_GEN_POSITION_X/Y vardata in object
		cx		- left margin to add in
		dx		- top margin to add in
RETURN:		Carry set if should stop processing
DESTROYED:	ax, bp
SIDE EFFECTS:	many wonderful things.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PositionChildCallback	proc	far
		uses	bp, es, di
		.enter
	;
	; If the child isn't ent, then it won't have the position hint.
	; (there probably are some VisCompGeometry flags we should check
	; for here too).
		mov	ax, segment EntClass
		mov	di, offset EntClass
		mov	es, ax
		call	ObjIsObjectInClass
		jnc	done
		clrdw	cxdx
		mov	ax, ATTR_GEN_POSITION_X
		call	ObjVarFindData
EC <		WARNING_NC	WARNING_GADGET_POSITION_VARDATA_EXPECTED >
		jnc	height
		mov	cx, ds:[bx]
height:
		mov	ax, ATTR_GEN_POSITION_Y
		call	ObjVarFindData
EC <		WARNING_NC	WARNING_GADGET_POSITION_VARDATA_EXPECTED >
		jnc	set
		mov	dx, ds:[bx]
set:
		mov	ax, MSG_VIS_POSITION_AND_INVAL_IF_NEEDED
		call	ObjCallInstanceNoLock
		clc
done:
		.leave
		ret
PositionChildCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilGetCorrectVisParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the Vis parent of the first Gen child.
		Usually self, unless you are a form with a gadget area.

CALLED BY:	INTERNAL
PASS:		*ds:si		- GadgetGeom object or
				- object where the vis parent of the gen child
				  is self.
RETURN:		cx:dx		- correct child's parent, maybe self
				- 0 for none
		Carry clear
DESTROYED:	ax, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	11/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilGetCorrectVisParent	proc	far
		class	GadgetGeomClass
		.enter
	;
	; If its not a GadgetGeomClass but still using this routine,
	; the vis parent of the child better be self.
	;
		push	es, di
		mov	ax, segment GadgetGeomClass
		mov	es, ax
		mov	di, offset GadgetGeomClass
		call	ObjIsObjectInClass
		pop	es, di
		jnc	isSelf
		
if 0
	;
	; Get the first Gen child
	;
		mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
		clr	cx					; first child
		call	ObjCallInstanceNoLock
		jc	done
		jcxz	done

	;
	; Now, the child's vis parent
		mov	ax, MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD
	;	mov	bp, mask SBF_WIN_GROUP
		
		mov	ax, MSG_VIS_FIND_PARENT
		movdw	bxsi, cxdx
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		clc
endif
		Assert	objectPtr, dssi, GadgetGeomClass
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGeom_offset
		movdw	cxdx, ds:[di].GGI_childParent
		clc

done:
		.leave
		ret
isSelf:
		mov	dx, si
		mov	cx, ds:[LMBH_handle]
		Assert	handle	cx
		clc
		jmp	done
GadgetUtilGetCorrectVisParent	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilUpdateVisStuffOnAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used for various classes that custom manage geometry that
		need to update visually when objects are added to get
		the new children to draw.

CALLED BY:	various MSG_VIS_ADD_CHILD_HANDLERS
PASS:		^lcx:dx		- child
		*ds:si		- VisComp object

		Be sure to call superclass first.
RETURN:		
DESTROYED:	ax, cx, dx, bp, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		I don't know if this is the best way to do things, but it
		seems to work.

		Add button to non-tiled form.

		Fail cases to check if you change this routine:
		In builder, create a non-tiled group in a non-tiled group in
		a form.  Add a button to that, does it draw?


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	11/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilUpdateVisStuffOnAdd	proc	far
		.enter
		pushdw	cxdx				; child
		mov	ax, MSG_VIS_MARK_INVALID
		mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_WINDOW_INVALID or mask VOF_IMAGE_INVALID
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		push	ds:[LMBH_handle]
		push	si			; self

		mov	ax, MSG_VIS_FIND_PARENT
		call	ObjCallInstanceNoLock
		movdw	bxsi, cxdx		; parent
		mov	ax, MSG_VIS_MARK_INVALID
		mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_WINDOW_INVALID or mask VOF_IMAGE_INVALID
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

	;		mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
		mov	ax, MSG_VIS_UPDATE_GEOMETRY
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	;		popdw	bxsi			; self
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		popdw	bxsi			; self

		popdw	bxsi			; child
		mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		.leave
		ret
GadgetUtilUpdateVisStuffOnAdd	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilManageChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets all ent vis children to be  managed

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	11/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilManageChildren	proc	far
	uses	bx,cx,dx,di,bp
		.enter
		mov	cl, mask VA_MANAGED	; set this bit
		clr	ch			; clear nothing
		mov	bx, cs
		mov	di, offset SetAttrCallback
		call	GadgetUtilVisProcessChildren
		.leave
		ret
GadgetUtilManageChildren	endp

GadgetUtilUnManageChildren	proc	far
	uses	bx,cx,dx,di,bp
		.enter
		mov	ch, mask VA_MANAGED	; clear this bit
		clr	cl			; set nothing
		mov	bx, cs
		mov	di, offset SetAttrCallback
		call	GadgetUtilVisProcessChildren
		.leave
		ret
GadgetUtilUnManageChildren	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetAttrCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set VisAttrs on all ent children.

CALLED BY:	
PASS:		cl		; VisAttrs to set
		ch		; VisAttrs to clear
RETURN:		cx	- as passed
DESTROYED:	dx, bp, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	11/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetAttrCallback	proc	far
		uses	cx
		.enter
	;
	; If the child isn't ent, then it won't have the position hint.
	; (there probably are some VisCompGeometry flags we should check
	; for here too).
		mov	ax, segment EntClass
		mov	di, offset EntClass
		mov	es, ax
		call	ObjIsObjectInClass
		jnc	done
		mov	ax, MSG_VIS_SET_ATTRS
		mov	dl, VUM_MANUAL
		call	ObjCallInstanceNoLock
		clc
done:
		.leave
		ret
SetAttrCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSpecVisRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
RETURN:		cx, dx	= desired size
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If we have a fixed size, return that.
		If shrink-to-fit, return 0.
		If we have expand to fit, return (passed size - position)
			[passed size does not account for out offset]
		If none return 30. (passed size is kinda big)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilMsgVisRecalcSize	proc	far
		.enter
	;
	; If we have EXPAND_TO_FIT return passed size - position
	;
		mov	ax, HINT_EXPAND_WIDTH_TO_FIT_PARENT
		call	ObjVarFindData
		jnc	checkHeight
	; now look for ATTR_GEN_POS so we can subtract our offset.
	;
		mov	ax, ATTR_GEN_POSITION_X
		call	ObjVarFindData
		jnc	checkHeightHaveWidth
		sub	cx, {word} ds:[bx]
		jmp	checkHeightHaveWidth
checkHeight:
		mov	cx, RecalcSizeArgs <1,0>	; signal not set yet.
checkHeightHaveWidth:
		mov	ax, HINT_EXPAND_HEIGHT_TO_FIT_PARENT
		call	ObjVarFindData
		jnc	checkShrinkWidth

	;
	; If it doesn't know how big we can be, neither do we
		test	dx, RecalcSizeArgs <1,0>
		jnz	default
		
		mov	ax, ATTR_GEN_POSITION_Y
		call	ObjVarFindData
		jnc	checkShrinkWidthHaveHeight
		sub	dx, {word} ds:[bx]
		jmp	checkShrinkWidthHaveHeight

checkShrinkWidth:
		mov	dx, RecalcSizeArgs <1,0>	; no height found yet
checkShrinkWidthHaveHeight:
	;
	; If we have FIXED_SIZE, return its pixel value.
	; only use fixed size if not expand, otherwise it was just
	; a remnant.
	;
		mov	ax, cx
		and	ax, dx
		test	ax, RecalcSizeArgs <1,0>
		jz	default
		mov	ax, HINT_FIXED_SIZE
		call	ObjVarFindData
		jnc	default

		mov	ax, MSG_SPEC_CONVERT_DESIRED_SIZE_HINT
		mov	cx, ds:[bx].SSA_width
		mov	dx, ds:[bx].SSA_height
	;
	; hmm, MSG_SPEC_CONVERT_DESIRED_SIZE_HINT seems to not do the
	; right thing.	Just assume the SIZE is specified in pixels
		
		call	ObjCallInstanceNoLock
		jmp	done
default:
	;
	; If the specific ui does not know our size, make it 30.
		test	cx, RecalcSizeArgs <1,0>
		jz	checkDX
		mov	cx, 30
checkDX:
		test	dx, RecalcSizeArgs <1,0>
		jz	done
		mov	dx, 30
done:
		.leave	
		ret
GadgetUtilMsgVisRecalcSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilCheckIfDescendantOfWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the passed object is a legal .focus component
		for the passed window (form, dialog or floater).  By legal,
		I mean the passed object must be a descendant of the passed
		window.  GadgetUtilCheckIfVisClass checks that the passed
		component is focusable.

CALLED BY:	GadgetUtilSetFocusHelper
PASS:		*ds:si	- window object
		cx:dx	- possible .focus of the window
RETURN:		carry	- set if the object is a legal .focus
DESTROYED:	ax,bx,di
SIDE EFFECTS:	ds - fixed up
	This routine does not check that the passed .focus object is
	a focusable object -- that is, subclassed from VisClass.  Call
	GadgetUtilCheckIfVisClass before calling this routine.

PSEUDO CODE/STRATEGY:
	Check that the passed possible .focus is a descendant of
	the passed form, dialog or floater.  We loop calling
	MSG_GEN_FIND_PARENT until we find the form,
	or fall off the top.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilCheckIfDescendantOfWindow	proc	near
theWin	local	optr
		uses	cx,dx
		.enter
	;
	; Save the form/dialog/floater.
	;
		mov	ax, ds:LMBH_handle
		mov	ss:theWin.handle, ax
		mov	ss:theWin.chunk, si
	;
	; Is the desired focus ourself?
	;
		cmpdw	cxdx, axsi
		stc			; Assume we're our own focus.
		je	done
	;
	; Check that prospective .focus is a descendant of
	; the window.  Loop until we find the form or go off the top.
	;
		push	si
upLoop:
		push	bp
		movdw	bxsi, cxdx, ax
		mov	ax, MSG_GEN_FIND_PARENT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage	; ^lcx:dx = obj if any found
		pop	bp		; Restore bp
		clc			; Assume didn't find.
		jcxz	afterSearch	; Correct assumption.
		cmpdw	cxdx, ss:[theWin], ax
		stc			; Yeeha, found the window.
		je	afterSearch
		jmp	upLoop
afterSearch:
		pop	si
done:		
		.leave
		ret

GadgetUtilCheckIfDescendantOfWindow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilCheckIfVisClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the passed object is derived from VisClass.
		This routine is useful for checking if an object is
		not focusable.

CALLED BY:	Utility
PASS:		ds	- pointing to object block
		cx:dx	- object to check
RETURN:		carry	- set if object is derived from VisClass
DESTROYED:	nothing
SIDE EFFECTS:	ds fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilCheckIfVisClass	proc	far
	uses	ax,bp,di,bx,si
		.enter

		xchg	bx, cx
		xchg	si, dx
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	cx, segment VisClass
		mov	dx, offset VisClass
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		xchg	cx, bx
		xchg	dx, si
		
		.leave
		ret
GadgetUtilCheckIfVisClass	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilRememberFocusInEntVisHide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when a window is doing an ENT_HIDE so that
		it will remember its current focus.  The current
		focus will be used when the window becomes visible
		again (unless the focus is set to something else
		while the window is not visible).  Why do we do this?
		Because Geos doesn't remember the focus hierarchy for
		a non-visible object.

CALLED BY:	GFEntVisHide, GDEntVisHide
PASS:		*ds:si	- window object (Form, Dialog or Floater)
		bx	- GadgetForm_offset or GadgetDialog_offset
		di	- GFI_focus or GDI_focus
RETURN:		nothing
DESTROYED:	bx, cx, dx, di
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilRememberFocusInEntVisHide	proc	far
compData	local	ComponentData
getPropArgs	local	GetPropertyArgs
	uses	ax
		.enter
	;
	; Remember our .focus object for when we come back up.
	; (GadgetUtilGetFocusCommon will set our .focus inst data.)
	;
		mov_tr	ax, bx
		xchg	ax, di			; ax = class, di = inst data
		lea	bx, compData
		mov	ss:[getPropArgs].GPA_compDataPtr.segment, ss
		mov	ss:[getPropArgs].GPA_compDataPtr.offset, bx
		Assert	fptr, ss:[getPropArgs].GPA_compDataPtr
		push	bp
		lea	bp, getPropArgs
		push	si
		call	GadgetUtilGetFocusCommon
		pop	si
		pop	bp
		
		.leave
		ret
GadgetUtilRememberFocusInEntVisHide	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilBuildFocusPathInEntVisShow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A window is being ENT_VIS_SHOWed, so set up its
		focus according to the window's .focus.

CALLED BY:	GFEntVisShow, GDEntVisShow
PASS:		*ds:si	- a window object (Form, Dialog or Floater)
		bx	- offset to ptr to class inst data
			  (GadgetDialog_offset or GadgetForm_offset)
		di	- offset to GFI_focus or GDI_focus
RETURN:		nothing
DESTROYED:	bx,si,di,es
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilBuildFocusPathInEntVisShow	proc	far
		uses	ax,cx,dx
		.enter
	;
	; Need to make our focus the object specified in our
	; instance data.
	;
		mov_tr	ax, di
		mov	di, ds:[si]
		add	di, ds:[di + bx]	; Point to object.
		add	di, ax			; Point to G?I_focus
		mov	cx, ds:[di].handle
		mov	dx, ds:[di].chunk
		jcxz	done
		Assert	optr, cxdx
		call	GadgetUtilBuildFocusPath
done:		
		.leave
		ret
GadgetUtilBuildFocusPathInEntVisShow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilBuildFocusPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a focus path from the passed component to the
		passed window (form, dialog or floater).

CALLED BY:	GadgetUtilSetFocusHelper
PASS:		*ds:si	- window object 
		cx:dx	- possible .focus of the form
RETURN:		carry	- set if the object is a legal .focus
DESTROYED:	ax,bx,cx,dx,si,di,es
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:
	The focus path is built by the .focus component grabbing
	the focus exclusive from its *parent*, its parent grabbing
	the focus exclusive from its parent, on up to the window
	(form, dialog or floater).  Note that the focus hierarchy
	consists only of valid focus nodes and leaf objects that
	grab the focus from a valid focus node.

	FIXME:
	This routine also checks for unfocusable gadgets as it builds
	the hierarchy, returning carry=0 if some unfocusable gadget is
	encountered.  We could speed things up by taking out the check,
	letting the setting of .focus fail silently.

	NOTE:
	This routine does *not* check that the passed .focus object is
	a legal focus.  Use GadgetUtilCheckIfVisClass and GadgetUtilCheckIf
	DescendantOfWindow if necessary.  See GadgetUtilSetFocusHelper.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilBuildFocusPath	proc	near
theWin	local	optr
count	local	word
		.enter
		Assert	optr, cxdx
	;
	; If we're our own .focus, bail now.
	;
		mov	bx, ds:LMBH_handle
		cmpdw	bxsi, cxdx, ax
		je	ourOwnFocus
		movdw	ss:theWin, bxsi, ax
	;
	; Make sure there aren't any nonfocusable gadgets in path
	; from the prospective .focus to the window. If we don't hit
	; the window on the way up, then don't build the path.  Although
	; GadgetUtilCheckLegalPath was already called to make sure the 
	; prospective .focus is a descendant of the window.
	;
	; NOTE: Each object examined is assumed to have already been
	; grown.  ENT_INITIALIZE will have taken care of this.
	;
		clr	ss:count
		jmp	checkObjectClass
checkParentObj:
		mov	ax, MSG_GEN_FIND_PARENT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		push	bp
		call	ObjMessage		; ^lcx:dx = parent
		pop	bp
		jcxz	abortFocusPathBuild	; Off the top.
		cmpdw	cxdx, ss:theWin, ax	; At the window?
		je	grabFocusFromParent
checkObjectClass:
		movdw	bxsi, cxdx, ax		; ^lbx:si= obj to check
		pushdw	bxsi			; Save object
		inc	ss:count		; Save for path creation.

		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	cx, segment GadgetClipboardableClass
		mov	dx, offset GadgetClipboardableClass
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		push	bp
		call	ObjMessage		; Carry set if subclass.
		pop	bp
		jnc	checkParentObj		; Not a subclass, go up.

		mov	ax, MSG_GADGET_CLIPBOARDABLE_GET_FOCUSABLE_INTERNAL
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		push	bp
		call	ObjMessage
		pop	bp
		jz	abortFocusPathBuild	; Not focusable.
		jmp	checkParentObj
		
	;
	; Loop up until we reach the form.
	;   - Grab focus exclusive for our level from parent.
	;   - Get our parent, and do the same for them.
	;   - Except skip any VisContent subclasses
	;
grabFocusFromParent:
		popdw	bxsi			; Grab obj in focus path.
		push	bp
		call	GadgetUtilCheckIfShouldSkipNodeInFocusPathBuild
		jc	afterGrab
		mov	ax, MSG_META_GRAB_FOCUS_EXCL
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
afterGrab:
		pop	bp
		dec	ss:count
		jz	success
		jmp	grabFocusFromParent
success:
		stc
done:
		.leave
		ret

abortFocusPathBuild:
		mov	cx, ss:count
		Assert	g, cx, 0
		shl	cl, 1			; Word size is 2.
		add	sp, cx			; Clear stack.
		clc
		jmp	done
	;
	; We're our own focus.  Break off hierarchy below us.
	;
ourOwnFocus:
		call	GadgetUtilBreakFocusHierarchy
		stc
		jmp	done

GadgetUtilBuildFocusPath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilCheckIfShouldSkipNodeInFocusPathBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When building a focus path, we should skip objects
		of type VisContentClass (or we'll die with UI_VIS_
		CONTENT_CAN_NOT_GRAB_OR_RELEASE_THIS_EXCL).  However
		LViewAppClass, subclassed (dynamically) from Vis-
		ContentClass, is an exception. (bug 57240)

CALLED BY:	SKSetFocus, GadgetUtilBuildFocusPath
PASS:		^lbx:si	- object to check
		ds	- pointing to object block
RETURN:		carry	- set if object should be skipped
DESTROYED:	ax, cx, dx, bp, di
SIDE EFFECTS:	ds	- fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 6/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilCheckIfShouldSkipNodeInFocusPathBuild	proc	far
		.enter

		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	cx, segment VisContentClass
		mov	dx, offset VisContentClass
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		jc	checkIfApp
done:
		.leave
		ret
checkIfApp:
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	cx, segment GenApplicationClass
		mov	dx, offset GenApplicationClass
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		cmc
		jmp	done
GadgetUtilCheckIfShouldSkipNodeInFocusPathBuild	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilSetFocusHelper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for setting a window's .focus.

CALLED BY:	utility for forms, dialogs and floaters
PASS:		*ds:si	= window object
		ss:bp	= SetPropertyArgs
RETURN:		carry	- set if object is a legal focus
			  cx:dx is focus object if success
			- clear if object is not a legal focus
		zf	- meaningless if carry is set
			- if carry is clear:
			    zf=1: don't generate a runtime error
			    zf=0: generate a runtime error

DESTROYED:	nothing
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilSetFocusHelper	proc	far
		uses	ax,bx,si,di,es,bp
		.enter
	;
	; Make sure the passed component is a legal .focus.
	; It must be a focusable descendant of us.....
	;
		les	bx, ss:[bp].SPA_compDataPtr
		Assert	fptr, esbx
		movdw	cxdx, es:[bx].CD_data.LD_comp, ax
		jcxz	getDefaultFocus		; Null -> use default.
		Assert	optr, cxdx
		call	GadgetUtilCheckIfVisClass
		jnc	doneNoError
		call	GadgetUtilCheckIfDescendantOfWindow
		jnc	doneError		; Not a descendant.
	;
	; .....and it must not be a popup.
	;
		call	GadgetUtilCheckIfObjectIsPopup
		cmc
		jnc	doneNoError		; It's a popup.
	;
	; If we're not visible, don't build the focus
	; hierarchy yet, but still return success so that the
	; focus object will be recorded to instance data.
	; (Actually, EF_VISIBLE=0 just means the net sum of
	; ENT_HIDE/SHOWs is 0.)
	;
.warn -private
		push	si
		mov	si, ds:[si]
		add	si, ds:[si].Ent_offset
		test	{byte}ds:[si].EI_flags, mask EF_VISIBLE
		pop	si
.warn @private
		stc				; Assume not visible
		jz	done			; cf=1, zf=1
	;
	; Make the .focus object grab the focus.
	;
		pushdw	cxdx
		call	GadgetUtilBuildFocusPath
		popdw	cxdx

doneNoError:
		lahf
		or	ah, mask CPU_ZERO	; Set zf, preserve cf.
		sahf
done:
		.leave
		ret
	;
	; Null .focus, so figure out default focus.
	;
getDefaultFocus:
		call	GadgetUtilFindDefaultFocus
		stc
		jmp	done

doneError:
		xor	al, 1			; Runtime error
		clc				; cf=0, zf=0
		jmp	done
		
GadgetUtilSetFocusHelper	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilFindDefaultFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the default focus under the passed window.  If
		the passed window is visible, build the focus path.
		If not, don't build the path: it'll be done later.

CALLED BY:	GadgetUtilSetFocusHelper only
PASS:		*ds:si	- some window (form, dialog, floater)
RETURN:		^lcx:dx	- window's default focus
DESTROYED:	nothing
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilFindDefaultFocus	proc	near
		uses	bx
		.enter

		push	ds:[LMBH_handle]
	;
	; If we're not visible, return null.  Default focus
	; will be done automatically when we become visible.
	; Note that NAVIGATE won't work well unless we're
	; visually built so we don't check EF_VISIBLE to
	; determine visibility.
	;
		clrdw	cxdx
		call	GadgetUtilCheckIfReallyVisible
		jc	done
	;
	; We're visible.  Make the default focus the focus now.
	; Break hierarchy below us; then navigate to next
	; focusable object (making a new hierarchy); then find
	; out who the new focus object is.
	;
		push	ax,bx,di,bp,bx
		call	GadgetUtilBreakFocusHierarchy

		mov	ax, MSG_GEN_NAVIGATE_TO_NEXT_FIELD
		call	ObjCallInstanceNoLock

		mov	cx, ds:LMBH_handle
		mov	dx, si
		call	GadgetUtilGetFocusCommonLow
		pop	ax,bx,di,bp,bx
done:
		pop	bx
		call	MemDerefDS
		
		.leave
		ret

GadgetUtilFindDefaultFocus	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilCheckParentIsApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure parent of the passed object is "app".

CALLED BY:	intercepted MSG_ENT_SET_PARENT handlers
PASS:		*ds:si	= object whose parent is being set
		di	= offset of object's superclass
		^lcx:dx	= potential parent
RETURN:		ax	= nonzero if parent is not legal
			= 0 if parent is "app"
DESTROYED:	bx
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilCheckParentIsApp	proc	far
		.enter

		push	ds:[LMBH_handle]
	;
	; Make sure "app" is requested parent.
	;
		push	si
		clr	bx			; Appobj for current process.
		call	GeodeGetAppObject
		cmpdw	cxdx, bxsi
		pop	si
		jne	fail
	;
	; We're okay.  Call superclass.
	;
		call	ObjCallSuperNoLock

done:
		pop	bx
		call	MemDerefDS
		
		.leave
		ret

fail:
		mov	ax, 1
		jmp	done
GadgetUtilCheckParentIsApp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilReturnSetPropError
		GadgetUtilReturnGetPropError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to return a set-property error.

CALLED BY:	Utility
PASS:		ss:bp	= SetPropertyArgs (for SetPropError)
			= GetPropertyArgs (for GetPropError)
		ax	= error to return
RETURN:		nothing
DESTROYED:	es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilReturnSetPropError	proc	far
		.enter

		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr, esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax

		.leave
		ret
GadgetUtilReturnSetPropError	endp

GadgetUtilReturnGetPropError	proc	far
		.enter

		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr, esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax

		.leave
		ret
GadgetUtilReturnGetPropError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilGetFocusCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for getting a window's .focus
		property.

CALLED BY:	
PASS:		*ds:si	- window object (form, dialog or floater)
		di	- GadgetDialog_offset or GadgetForm_offset
		ax	- offset of GFI_focus or GDI_focus
		ss:bp	- GetPropertyArgs
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di
SIDE EFFECTS:	ds is fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilGetFocusCommon	proc	far
		uses	es
		.enter
	;
	; If we've been set not visible, then there's no focus hierarchy
	; below us.  So just return whatever is in our .focus instance
	; data.  This data will have been set correctly when we became
	; not visible (or the programmer could've set our .focus to
	; what we *should* have as the focus when we become visible).
	;
		call	GadgetUtilCheckIfReallyVisible
		jc	derefInstData
	;
	; So, who has the focus?
	;
		mov	cx, ds:LMBH_handle
		mov	dx, si
		push	bp,si
		push	di,ax
		push	cx
		call	GadgetUtilGetFocusCommonLow	; ^lcx:dx = focus
		clc					; (if skip check)
		jcxz	afterPopupCheck
		call	GadgetUtilCheckIfObjectIsPopup
afterPopupCheck:
		pop	bx
		call	MemDerefDS
		pop	di,ax
		pop	bp,si
derefInstData:
		mov_tr	bx, di				; bx = ??_offset
		mov_tr	di, ax				; di = inst data off.
		lahf
		mov	si, ds:[si]			; Deref object.
		add	si, ds:[si+bx]			; class inst. data
		add	si, di				; Pnt to inst. data
		sahf
		jc	returnFocus			; retn prev focus
	;
	; Save the focus in our G?I_focus field.  Note that we
	; could have a null focus if GetFocusCommonLow couldn't find
	; an Ent-subclassed ancestor of the focus.
	;
		movdw	ds:[si], cxdx, bx
	;
	; Now return focus
	;
returnFocus:
		les	bx, ss:[bp].GPA_compDataPtr
		Assert	fptr, esbx
		movdw	es:[bx].CD_data.LD_comp, ds:[si], ax
		mov	es:[bx].CD_type, LT_TYPE_COMPONENT

		.leave
		ret
GadgetUtilGetFocusCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilGetFocusCommonLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the leaf focus object that is below the
		passed object.  ....Ah, but since the leaf
		object might not be an Ent subclass, walk up
		the parent links until an Ent-subclass parent
		is found.

CALLED BY:	GadgetForm/DialogMetaMupAlterFtvmcExcl (via
		GadgetUtilGetFocusCommon),
		GadgetUtilFindDefaultFocus
PASS:		^lcx:dx	- object under which to start search
		ds	- segment of an object block
RETURN:		^lcx:dx	- focus object
DESTROYED:	ax,bp,di,bx
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilGetFocusCommonLow	proc	far
origObj	local	optr
		uses	si
		.enter
	;
	; Our callers happen to have ds pointing to an object block.
	; Even though none of the msgs called in this routine will
	; cause a block to move, EC code pretends that blocks do move.
	; So to avoid EC crashes, we save the block handle here and
	; dereference it at the end.
	;
		push	ds:[LMBH_handle]
	;
	; Save original object.  We won't search above this object
	; for an Ent-subclassed object.
	;
		movdw	ss:[origObj], cxdx, ax
	;
	;  ^lcx:dx contains the optr of the top level focus; we'll
	;  recursively send the GET_FOCUS message until we get no
	;  response.
	;
		;Assert	optr, cxdx		; Note that we will get a
						; HANDLE_SHARING_ERROR if
						; we do this on an obj that
						; we don't own.  So rely on
						; ObjMessage to check the
						; optr.  -jmagasin 10/18/96
		push	bp
focusLoop:
		movdw	bxsi, cxdx
		mov	ax, MSG_META_GET_FOCUS_EXCL
		mov	di, mask MF_CALL
		call	ObjMessage
		jnc	findEntComponent	; No response.
		jcxz	findEntComponent	; Noone below w/ focus.

		jmp	focusLoop
	;
	; Now we walk up the parent links looking for an EntClass
	; subclass, since Legos code only speaks to EntClass components.
	;
findEntComponent:
		mov	cx, segment EntClass
		mov	dx, offset EntClass
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	di, mask MF_CALL
		call	ObjMessage
		jc	resultInCXDX

		pop	bp
		cmpdw	bxsi, ss:[origObj], ax
		push	bp
		je	noFocus
		
		mov	ax, MSG_VIS_FIND_PARENT
		mov	di, mask MF_CALL
		call	ObjMessage		; ^lcx:dx = parent
		movdw	bxsi, cxdx
		Assert	optr, bxsi
		jmp	findEntComponent

resultInCXDX:
		movdw	cxdx, bxsi		; last object

done:
		pop	bp

		pop	bx
		call	MemDerefDS		; make ds point to obj block
		
		.leave
		ret

noFocus:
		clrdw	cxdx
		jmp	done
		
GadgetUtilGetFocusCommonLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilCheckIfReallyVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the passed window is really visible.
		EF_VISIBLE really just reflects whether the
		number of ENT_VIS_SHOW and ENT_HIDE calls balance.

CALLED BY:	GadgetUtilGetFocusCommon only
PASS:		*ds:si	- window component (form, dialog, or floater)
RETURN:		carry	- set if NOT visible
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.warn -private
GadgetUtilCheckIfReallyVisible	proc	near
	uses	di
		.enter
	;
	; Do we have Vis data?
	;
		mov	di, ds:[si]
		mov	bx, ds:[di].Vis_offset
		tst	bx
		jz	notVisible
	;
	; Are we VA_REALIZED?
	;
		add	di, bx
		test	ds:[di].VI_attrs, mask VA_REALIZED
		jz	notVisible
	;
	; We made it!  We're visible!
	;
		clc
done:
		.leave
		ret

notVisible:
		stc
		jmp	done
GadgetUtilCheckIfReallyVisible	endp
.warn @private



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilCheckIfObjectIsPopup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the passed object is a popup component.

CALLED BY:	GadgetUtilSetFocusHelper
		GadgetUtilGetFocusCommon

PASS:		^lcx:dx
		ds	- pointing to object block
RETURN:		carry	- set if object *is* a popup
DESTROYED:	nothing
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilCheckIfObjectIsPopup	proc	near
	uses	ax,cx,dx,bp,si,di
		.enter
	;
	; Is it a popup component.
	;
		Assert	optr, cxdx
		movdw	bxsi, cxdx, ax
		mov	cx, segment GadgetPopupClass
		mov	dx, offset GadgetPopupClass
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
GadgetUtilCheckIfObjectIsPopup	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilRaiseCloseEventIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise an "aboutToClose" event if we haven't already done
		so*, and if we're VA_REALIZED.

		* We prevent recursive ENT_HIDE's, which the user could
		  cause by setting a window not visible from within
		  an aboutToClose handler.

CALLED BY:	utility called my MSG_ENT_HIDE handlers
PASS:		*ds:si	= GadgetDialog/Floater/FormClass object
RETURN:		zf	= set if did *not* generate event
			= clear if did generate event
DESTROYED:	nothing
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/29/95   	Initial version
	dloft	9/25/95		changed to prevent nested visual updates
	jmagasin 3/18/96	Call common routine.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
aboutToCloseString TCHAR	"aboutToClose", C_NULL

GadgetUtilRaiseCloseEventIfNecessary	proc	far
	uses	ax,dx
		.enter

		mov	ax, HINT_GADGET_GEOM_SKIP_CLOSE_EVENT
		mov	dx, offset aboutToCloseString
		call	GadgetUtilRaiseOpenCloseIfNecessaryCommon

		.leave
		ret
GadgetUtilRaiseCloseEventIfNecessary	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilRaiseOpenEventIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise an "aboutToOpen" event if we haven't already
		done so*, and if we're not VA_REALIZED.

		* We prevent recursive ENT_VIS_SHOW's, which the user could
		  cause by setting a window visible from within an
		  aboutToOpen handler.

CALLED BY:	utility called by MSG_ENT_VIS_SHOW handlers
PASS:		*ds:si	= GadgetDialog/Floater/FormClass object
RETURN:		zf	= set if did *not* generate event
			= clear if did generate event
DESTROYED:	nothing
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
aboutToOpenString TCHAR		"aboutToOpen", C_NULL
GadgetUtilRaiseOpenEventIfNecessary	proc	far
	uses	ax,dx
		.enter

		mov	ax, HINT_GADGET_GEOM_SKIP_OPEN_EVENT
		mov	dx, offset aboutToOpenString
		call	GadgetUtilRaiseOpenCloseIfNecessaryCommon

		.leave
		ret
GadgetUtilRaiseOpenEventIfNecessary	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilRaiseOpenCloseIfNecessaryCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for raising an aboutToOpen or aboutToClose
		event.
		  aboutToOpen:  not raised if HINT_GADGET_GEOM_SKIP_OPEN_EVENT
				is present, or window is already VA_REALIZED

		  aboutToClose: not raised if HINT_GADGET_GEOM_SKIP_CLOSE_EVENT
				is present, or window is not VA_REALIZED

CALLED BY:	GadgetUtilRaiseOpenEventIfNecessary,
		GadgetUtilRaiseCloseEventIfNecessary
PASS:		*ds:si	- GadgetDialog/Floater/Form object
		ax	- HINT_GADGET_GEOM_SKIP_CLOSE_EVENT or
			  HINT_GADGET_GEOM_SKIP_OPEN_EVENT
		dx	- offset aboutToCloseString or
			  offset aboutToOpenString
RETURN:		zf	- set if event was not raised
DESTROYED:	ax, dx
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilRaiseOpenCloseIfNecessaryCommon	proc	near
params	local	EntHandleEventStruct
		uses	di,cx,bp,bx
		.enter

		push	ds:[LMBH_handle]
	;
	; Is there a hint preventing us from raising an event?
	;
		call	GadgetUtilCheckForOpenCloseEventSkip
		jz	done
	;
	; Check visibility.  
	;
		push	bp
		push	dx
		mov	ax, MSG_VIS_GET_ATTRS
		call	ObjCallInstanceNoLock		; cl <- attrs
		pop	ax				; offset of string
		pop	bp
		cmp	ax, offset aboutToOpenString
		je	checkNotRealized
		test	cl, mask VA_REALIZED
		jz	done				; not realized
		jmp	raiseEvent
checkNotRealized:
		test	cl, mask VA_REALIZED
		jnz	setZF				; already realized

	;
	; Okay, okay...Raise an event.
	;
raiseEvent:
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 0
		
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	di, mask MF_CALL
		lea	dx, params
		mov	cx, ss
		call	ObjCallInstanceNoLock
		inc	al				; Clear zf.
done:
		pop	bx
		call	MemDerefDS
		
		.leave
		ret
setZF:
		sub	bl, bl
		jmp	done
GadgetUtilRaiseOpenCloseIfNecessaryCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilCheckForOpenCloseEventSkip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If an aboutToOpen or aboutToClose handler causes
		another aboutToOpen/aboutToClose event to be
		generated, don't generate the event.

		For example, if aboutToClose for a dialog sets
		the dialog's .visible=0, we won't generate
		another aboutToClose.

CALLED BY:	GadgetUtilRaiseOpenCloseEventIfNecessaryCommon only
PASS:		*ds:si	= GadgetDialogClass object
		ax	= HINT_GADGET_GEOM_SKIP_OPEN_EVENT or
			  HINT_GADGET_GEOM_SKIP_CLOSE_EVENT
RETURN:		zf	= 1 if should skip the event
			= 0 if we should handle this event
			  and vardata was added to skip future
			  events

DESTROYED:	bx, cx, ax
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilCheckForOpenCloseEventSkip	proc	near
		.enter

		push	ds:[LMBH_handle]
	;
	; If we've been asked to raise an aboutToOpen,
	; then remove any HINT_GADGET_GEOM_SKIP_CLOSE_EVENT.
	;
	; If we've been asked to raise an aboutToClose,
	; then remove any HINT_GADGET_GEOM_SKIP_OPEN_EVENT.
	;
		mov_tr	bx, ax
		mov	ax, HINT_GADGET_GEOM_SKIP_OPEN_EVENT
		cmp	bx, HINT_GADGET_GEOM_SKIP_CLOSE_EVENT
		je	deleteOtherHint
		mov	ax, HINT_GADGET_GEOM_SKIP_CLOSE_EVENT
deleteOtherHint:
		call	ObjVarDeleteData
		mov_tr	ax, bx
		
	;
	; See if we've got a hint to skip the event we've been asked
	; to raise.
	;
		call	ObjVarFindData
		jc	setZF
		clr	cx
		call	ObjVarAddData			; maybe next time
		Assert	ne al, 0
		inc	al				; clr ZF
done:
		pop	bx
		call	MemDerefDS
		
		.leave
		ret
setZF:
		sub	bl, bl				; set ZF
		jmp	done
GadgetUtilCheckForOpenCloseEventSkip	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilReturnReadOnlyError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the interpreter that this property is readOnly

CALLED BY:	EXTERNAL
PASS:		ss:bp = SetPropertyArgs
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	1/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilReturnReadOnlyError	proc	far
		.enter

		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_READONLY_PROPERTY

		.leave
		ret
GadgetUtilReturnReadOnlyError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilRaiseFocusOnWindowDisable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When a focused window (form, dialog, or floater)
		becomes	disabled, it should make break off the
		focus hierarchy below it.

CALLED BY:	MSG_GADGET_SET_ENABLED for forms/dialogs if the window
		is being disabled.
PASS:		*ds:si	- window object
RETURN:		carry	- set if window had the focus and therefore
			  broke the hierarchy below itself
DESTROYED:	ax,bx,cx,dx
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilRaiseFocusOnWindowDisable	proc	far
		uses	bp
		.enter
	;
	; Do we have the focus under the application object?
	; (GenSystem->GenField->GenApplication->*us?*)
	;
		mov	ax, MSG_META_GET_FOCUS_EXCL
		call	UserCallApplication		; ^lcx:dx is focus
		jnc	notFocused			; No response.
		cmp	dx, si
		jne	notFocused
		mov	bx, ds:LMBH_handle
		cmp	cx, bx
		jne	notFocused
	;
	; Yup, we're in the focus path.  Make the object with the
	; focus exclusive below us drop the focus.  (On return,
	; the caller will set itself to be its own focus.)
	;
		call	GadgetUtilBreakFocusHierarchy
		stc
done:
		.leave
		ret

notFocused:
		clc					; We're not focused.
		jmp	done
		
GadgetUtilRaiseFocusOnWindowDisable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilBreakFocusHierarchy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Breaks the focus hierarchy off at the passed object.

CALLED BY:	GadgetUtilRaiseFocusOnWindowDisable,
		GadgetUtilFindDefaultFocus,
		GadgetUtilBuildFocusPath ONLY!
PASS:		*ds:si	- window object (form, dialog, floater)
RETURN:		nothing
DESTROYED:	ax,cx,dx,bx
SIDE EFFECTS:	ds fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 1/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilBreakFocusHierarchy	proc	near
		uses	bp
		.enter

		push	ds:[LMBH_handle]		; for deref at end
	;
	; Get the focus below us.
	;
		mov	ax, MSG_META_GET_FOCUS_EXCL
		call	ObjCallInstanceNoLock		; ^lcx:dx our focus
		jcxz	done				; Hmm... no focus.
	;
	; Have the focus object release the focus exclusive.
	;
		push	si,di
		movdw	bxsi, cxdx
		mov	ax, MSG_META_RELEASE_FOCUS_EXCL
		clr	di
		call	ObjMessage
		pop	si,di
done:
		pop	bx
		call	MemDerefDS
		
		.leave
		ret
GadgetUtilBreakFocusHierarchy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilSetSysFocusTargetCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to make the passed object the
		system focus or target

CALLED BY:	
PASS:		ax	- MSG_META_GRAB_FOCUS_EXCL or
			  MSG_META_GRAB_TARGET_EXCL
		bx:si	- optr of component to make focus or target
		ds	- object block (will be fixed up)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilSetSysFocusTargetCommon	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		message	local	word	push	ax
		count	local	word
		.enter

		clr	ss:[count]
upLoop:
	;
	; If the thing has got a parent, then we need to grab the
	; focus or target for the thing.
	;
		push	bp			; frame ptr
		mov	ax, MSG_GEN_FIND_PARENT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp			; frame ptr
		jcxz	atTop

	;
	; Don't include the content object (below a GadgetClipper)
	; or we'll die with UI_VIS_CONTENTCAN_NOT_GRABOR_RELEASE_THIS_EXCL
	; on the downloop.
	;
		push	cx,dx,bp		; parent optr / frame
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	cx, segment VisContentClass
		mov	dx, offset VisContentClass
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	cx,dx,bp		; parent optr / frame
		jc	afterPush
		pushdw	bxsi			; Save this node.
		inc	ss:[count]		; Inc node count.
afterPush:
		movdw	bxsi, cxdx
		jmp	upLoop
atTop:
		mov	cx, ss:[count]
		jcxz	done
downLoop:
		popdw	bxsi
		mov	ax, ss:[message]
		push	cx, bp			; count / frame ptr
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	cx, bp			; count / frame ptr
		loop	downLoop
done:
		.leave
		ret
GadgetUtilSetSysFocusTargetCommon	endp


COMMENT @- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

The following code is useful for SystemKeyboardClass and SystemBusyClass.
Objects of these classes need to notify any other instances of their class
of certain actions.  To that end they maintain global chunk arrays whose
elements are optrs to instances of their class.  The following routines
are used for working with these arrays.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - @


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilAddSelfToArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add ourself to the passed array of components.
		This message is only provided because we don't
		want BSystem<Busy,Keyboard> messing with the array.

CALLED BY:	Util for SystemBusy/KeyboardClass
PASS:		di	- offset into idata of chunk array's optr
		*ds:si	- object
RETURN:		di	- # objects in array after the add
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilAddSelfToArray	proc	far
		uses	ax, cx, dx, bp, ds, es, si, bx
		.enter
	;
	; Save our optr.
	;
		push	ds:[LMBH_handle]
		push	si
	;
	; Allocate the chunk array of components if
	; it doesn't yet exist.
	;
		mov	ax, seg dgroup
		mov	es, ax
		tstdw	es:[di]
		jnz	addSelfToArray			; null->no exist

		mov	ax, LMEM_TYPE_GENERAL
		clr	cx				; default size
		call	MemAllocLMem			; bx <- block han

	; make it sharable
		mov	al, mask HF_SHARABLE
		clr	ah
		call	MemModifyFlags

	; make sure it stays around as long as we are
		mov	ax, handle 0
		call	HandleModifyOwner

		push	bx
		call	MemLock				; ax= seg of block
		Assert	carryClear
		mov	ds, ax
		mov	bx, size optr			; array of optrs
		;clr	cx				; default header
		clr	si				; alloc chnk han
		clr	al				; no flags
		call	ChunkArrayCreate		; *ds:si is array
		Assert	carryClear
		pop	bx

		movdw	es:[di], bxsi
		jmp	appendNow
	;
	; Add ourself to the array.
	;
addSelfToArray:
		movdw	bxsi, es:[di]
		call	MemLock
		mov	ds, ax				; *ds:si = array
appendNow:
		call	ChunkArrayAppend		; ds:di = new elt
		Assert	carryClear
		pop	dx
		pop	cx				; Get component optr.
		movdw	ds:[di], cxdx

	; get count into di
		mov	di, ds:[si]
		mov	di, ds:[di].CAH_count
		call	MemUnlock
		
		.leave
		ret
GadgetUtilAddSelfToArray	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilRemoveSelfFromArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove self from the array of components.
		This message is only provided because we don't
		want BSystemBusy/Keyboard messing with the array.

CALLED BY:	Util for SystemBusy/KeyboardClass
PASS:		di	- offset into idata of chunk array's optr
		*ds:si	- object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/29/96   	Initial version
	jmagasin 9/24/96	Silently fail if component not in array.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilRemoveSelfFromArray	proc	far
		uses	ax, cx, dx, bp, ds, es, di, si, bx
		.enter
	;
	; Fetch the array, and bail if it is null.
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si				; ^lcx:dx = self
		mov	ax, seg dgroup
		mov	es, ax
		movdw	bxsi, es:[di] 			; bx = block han
		tstdw	bxsi
		jz	done
	;
	; Find ourself in the array.
	;
		call	MemLock
		mov	ds, ax				; *ds:si = array
		push	bx, di
		mov	bx, cs
		mov	di, offset GadgetUtilFindCompInArrayCallback
		call	ChunkArrayEnum			; ax = our index
		pop	bx, di
		jnc	unlockArray
	;
	; Take ourself out of the array, or just nuke the array
	; if we're the only component in it.
	;
		call	ChunkArrayGetCount		; cx <- # elts
		cmp	cx, 1
		je	nukeArray

		mov	cx, 1				; delete just self
		call	ChunkArrayDeleteRange
unlockArray:
		call	MemUnlock
		jmp	done
nukeArray:
		call	MemFree
		clrdw	es:[di]
done:
		.leave
		ret
GadgetUtilRemoveSelfFromArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilFindCompInArrayCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the element number of the passed
		component.

CALLED BY:	GadgetUtilRemoveSelfFromArray
PASS:		cx:dx	- optr of component we want
		ds:di	- array element
		*ds:si	- array
RETURN:		carry	- set if found component
			  ax - element #
			- clear if passed element is not cx:dx
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilFindCompInArrayCallback	proc	far
		.enter

		cmpdw	ds:[di], cxdx
		je	gotcha
		clc				; assumed incorrectly:(
done:
		.leave
		ret
gotcha:
		call	ChunkArrayPtrToElement	; ax - element number
		stc
		jmp	done
GadgetUtilFindCompInArrayCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilNotifyCompsOfChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify busy or keyboard components that
		some change has occurred.

CALLED BY:	Utility for busy/keyboard components.
PASS:		di	- offset into idata of optr of component array
		ax	- message to send to all components
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilNotifyCompsOfChange	proc	far
		.enter
	;
	; If there's no array of components, bail
	;
		mov	cx, ax				; save msg
		mov	ax, seg dgroup
		mov	es, ax
		tstdw	es:[di]
		jz	done
	;
	; Fetch that array!  Tell the world about the change!
	;
		movdw	bxsi, es:[di] 			; bx = block han
		call	MemLock
		mov	ds, ax				; *ds:si = array
		push	bx
		mov	bx, cs
		mov	ax, cx				; msg to send
		mov	di, offset GadgetUtilNotifyCompsOfChangeCallback
		call	ChunkArrayEnum			; ax = our index
		pop	bx
		call	MemUnlock
done:		
		.leave
		Destroy	ax, bx, cx, dx, di
		ret
GadgetUtilNotifyCompsOfChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilNotifyCompsOfChangeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for notifying busy/keyboard components
		of a change.

CALLED BY:	GadgetUtilNoitifyCompsOfChange
PASS:		ds:di	- component array element
		ax	- message to send to object specified by
			  array element in ds:di
RETURN:		carry	- clear
DESTROYED:	bx, cx, dx, si, di
SIDE EFFECTS:	ds - fixed up (because EC can set ds=A000)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilNotifyCompsOfChangeCallback	proc	far
		uses	ax, bp
		.enter

		movdw	bxsi, ds:[di]
		;Assert	optr, bxsi		; Note that we will get a
						; HANDLE_SHARING_ERROR if
						; we do this on an obj that
						; we don't own.  So rely on
						; ObjMessage to check the
						; optr.  -jmagasin 10/18/96
		clr	di
		call	ObjMessage
		clc					; Notify all components
		
		.leave
		Destroy	bx, cx, dx, si, di
		ret
GadgetUtilNotifyCompsOfChangeCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilClipMkrBasedOnSizeControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for adding hints to cause a gadget to
		clip its moniker.  Written for labels and buttons,
		which should clip their monikers if they are
		GSCT_AS_SPECIFIED or GSCT_AS_BIG_AS_POSSIBLE.
		* * * This routine should only be called from
		      MSG_GADGET_SET_SIZE_H/VCONTROL.

CALLED BY:	
PASS:		*ds:si	- object
		ss:bp	- SetPropertyArgs
		ax	- MSG_GADGET_SET_SIZE_V/HCONTROL
RETURN:		nothing
DESTROYED:	di, bx, dx, cx, es
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilClipMkrBasedOnSizeControl	proc	far
		.enter
		Assert	objectPtr, dssi, GadgetClass

		push	ds:[LMBH_handle]
	;
	; Get argument.
	;
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		mov	bx, es:[di].CD_data.LD_integer
		cmp	bx, GSCT_AS_NEEDED
		je	noClipping
		cmp	bx, GSCT_AS_SMALL_AS_POSSIBLE
		je	noClipping

	;
	; We're AS_SPECIFIED or AS_BIG..., so we want to clip.
	;
		mov	dx, HINT_CAN_CLIP_MONIKER_HEIGHT
		cmp	ax, MSG_GADGET_SET_SIZE_VCONTROL
		je	setClippable
		Assert	e ax, MSG_GADGET_SET_SIZE_HCONTROL
		mov	dx, HINT_CAN_CLIP_MONIKER_WIDTH
setClippable:
		clr	cx
		xchg	ax, dx
		call	ObjVarAddData
		xchg	ax, dx

	;
	; We're out of here.  Caller will now call superclass.
	;
done:
		pop	bx
		call	MemDerefDS
		
		.leave
		ret

	;
	; Clipping not allowed.
	;
noClipping:
		mov	dx, HINT_CAN_CLIP_MONIKER_HEIGHT
		cmp	ax, MSG_GADGET_SET_SIZE_VCONTROL
		je	setNotClippable
		Assert	e ax, MSG_GADGET_SET_SIZE_HCONTROL
		mov	dx, HINT_CAN_CLIP_MONIKER_WIDTH
setNotClippable:
		xchg	ax, dx
		call	ObjVarDeleteData
		xchg	ax, dx
		jmp	done
GadgetUtilClipMkrBasedOnSizeControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilClipMkrForFixedSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for adding hints to cause a gadget to
		clip its moniker.  Written for labels and buttons,
		which should clip their moniker if they are
		GSCT_AS_SPECIFIED or GSCT_AS_BIG_AS_POSSIBLE.
		* * * This routine should only be called from
		      MSG_GADGET_SET_WIDTH/HEIGHT

CALLED BY:	
PASS:		*ds:si	- object
		ss:bp	- SetPropertyArgs
		ax	- MSG_GADGET_SET_WIDTH/HEIGHT
RETURN:		nothing
DESTROYED:	dx, cx, bx
SIDE EFFECTS:	ds - fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 5/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilClipMkrForFixedSize	proc	far
		.enter
		Assert	objectPtr, dssi, GadgetClass

		push	ds:[LMBH_handle]
	;
	; Figure out if we should set H or V control.
	;
		mov	dx, HINT_CAN_CLIP_MONIKER_WIDTH
		cmp	ax, MSG_GADGET_SET_WIDTH
		je	addHint
		mov	dx, HINT_CAN_CLIP_MONIKER_HEIGHT
		Assert	e ax, MSG_GADGET_SET_HEIGHT

addHint:
		clr	cx
		xchg	ax, dx
		call	ObjVarAddData
		xchg	ax, dx

		pop	bx
		call	MemDerefDS
		
		.leave
		ret
GadgetUtilClipMkrForFixedSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUtilSetLookHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add and remove hints to implement look (after verify look)

CALLED BY:	
PASS:		*ds:si - instance data of object
		ax - maximum look
		es:dx - ptr to hint table
		cx - length of hint and look tables
		ss:bp - ptr to SetPropertyArgs
RETURN:		none
DESTROYED:	di, ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	NOTE: the look tables must be the same length as the hint table,
	and must be sequentially in memory immediately after it

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/23/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUtilSetLookHints	proc	far
		uses	bx
		.enter
	;
	; Get the look to set
	;
		Assert	fptr	ssbp
		push	es
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		mov	di, es:[di].CD_data.LD_integer	;di <- look to set
		pop	es
	;
	; Check the look.  If illegal, set to zero
	;
		cmp	di, ax				;legal look?
		jb	lookOK				;branch if legal
		clr	di				;di <- set to zero
lookOK:
	;
	; get the pointer to the appropriate looks table
	;
		push	dx				;save table offset
		mov	ax, cx				;ax <- table length
		mov	bx, dx				;bx <- table offset
		inc	di				;skip hints table
		mul	di				;ax <- index to +/-
		shl	ax, 1				;ax <- offset to +/-
		add	bx, ax				;cs:bx <- ptr to +/-
		pop	di				;cs:di <- ptr to hints
	;
	; loop through hint table and add or remove
	;
hintLoop:
		push	cx
		mov	ax, es:[di]			;ax <- hint to +/-
		call	es:[bx]
		add	di, (size word)			;cs:di <- next hint
		add	bx, (size word)			;cs:bx <- next +/-
		pop	cx
		loop	hintLoop			;loop if more

		.leave
		ret
GadgetUtilSetLookHints	endp

GadgetAddHint	proc	near
		push	bx
		clr	cx				;cx <- no extra data
		call	ObjVarAddData
		pop	bx
		ret
GadgetAddHint	endp

GadgetRemoveHint	proc	near
		call	ObjVarDeleteData
		ret
GadgetRemoveHint	endp

GadgetAddGeometry	proc	near
		mov	ax, MSG_GEN_ADD_GEOMETRY_HINT
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
		ret
GadgetAddGeometry	endp

GadgetRemoveGeometry	proc	near
		mov	ax, MSG_GEN_REMOVE_GEOMETRY_HINT
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
		ret
GadgetRemoveGeometry	endp

GadgetMastCode	segment	Resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetStringVardataProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a string vardata tag as a property

CALLED BY:	UTILITY
PASS:		ax - ATTR_GEN_HELP_CONTEXT or other string vardata tag
		ss:bp - SetPropertyArgs
		*ds:si - object
RETURN:		none
DESTROYED:	ax, bx, cx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/31/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetStringVardataProperty	proc	near
		.enter

	;
	; Lock down the property string
	;
		call	GadgetLockPropertyString
		jc	doneTypeError			;branch if error
		jcxz	removeHelp			;branch if NULL
	;
	; Set the help context / string
	;
		call	ObjVarAddData
		push	ds, si
		mov	si, di
		segxchg	ds, es				;ds:si <- ptr to string
		mov	di, bx				;es:di <- ptr to vardat
		rep	movsb				;copy the bytes
		pop	ds, si
	;
	; Unlock the string
	;
done:
		call	GadgetUnlockPropertyString
doneTypeError:

		.leave
		ret

	;
	; remove the help context / string
	;
removeHelp:
		call	ObjVarDeleteData
		jmp	done
SetStringVardataProperty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetStringVardataProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a string vardata tag from a property

CALLED BY:	UTILITY
PASS:		ax - ATTR_GEN_HELP_CONTEXT or other string based vardata
		ss:bp - ptr to GetPropertyArgs
		*ds:si - object
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/31/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetStringVardataProperty	proc	near
		uses	si
		.enter

	;
	; Get the the help context / string, if any
	;
		call	ObjVarFindData
		mov	ax, 0				;ax <- 0 (carry OK)
		jnc	storeStringToken
		mov	si, bx				;ds:si <- ptr to str
		segmov	es, ds
		mov	di, si				;es:di <- ptr to str
		call	LocalStringSize
		mov	ax, cx				;ax <- size of string
		inc	ax				;ax <- +1 for NULL
DBCS <		inc	ax				;+2 for NULL >
storeStringToken:
	;
	; Create the string for the property
	;
		call	GadgetCreatePropertyString

		.leave
		ret
GetStringVardataProperty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetLockPropertyString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the property string in the run heap

CALLED BY:	UTILITY
PASS:		ss:bp - SetPropertyArgs
RETURN:		carry - set if type mismatch error
		carry - clear
			es:di - ptr to string
			cx - size of string including NULL (not length)
DESTROYED:	bx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/31/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetLockPropertyString	proc	near
		uses	ax
		.enter

	;
	; check the type is a string
	;
		les	di, ss:[bp].SPA_compDataPtr
		cmp	es:[di].CD_type, LT_TYPE_STRING
		jne	typeError
	;
	; lock the string
	;
		sub	sp, size RunHeapLockStruct
		mov	bx, sp				;ss:bx <- RHLS
		lea	dx, ss:[bx].RHLS_eptr
		movdw	ss:[bx].RHLS_dataPtr, ssdx
		mov	ax, es:[di].CD_data.LD_string
		mov	ss:[bx].RHLS_token, ax 
		movdw	cxdx, ss:[bp].SPA_runHeapInfoPtr
		movdw	ss:[bx].RHLS_rhi, cxdx
		call	RunHeapLock
		mov	bx, sp
		movdw	esdi, ss:[bx].RHLS_eptr		;es:di <- ptr to string
		Assert	fptr	esdi
		add	sp, size RunHeapLockStruct
	;
	; Get size
	;
		Assert	nullTerminatedAscii esdi
		call	LocalStringSize
		jcxz	emptyString			;branch if 0 size
		inc	cx				;cx <- +1 for NULL
DBCS <		inc	cx				;+2 bytes for NULL>
emptyString:
		clc					;carry <- no error
exit:

		.leave
		ret

typeError:
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_PROPERTY_TYPE_MISMATCH
		stc					;carry <- error
		jmp	exit
GadgetLockPropertyString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetUnlockPropertyString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the property string locked by GadgetLockPropertyString

CALLED BY:	UTILITY
PASS:		ss:bp - ptr to SetPropertyArgs
RETURN:		none
DESTROYED:	ax, bx, cx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/31/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetUnlockPropertyString	proc	near
		.enter

		les	di, ss:[bp].SPA_compDataPtr
		sub	sp, size RunHeapLockStruct
		mov	bx, sp				;ss:bx <- RHLS
		mov	ax, es:[di].CD_data.LD_string
		mov	ss:[bx].RHLS_token, ax 
		movdw	cxdx, ss:[bp].SPA_runHeapInfoPtr
		movdw	ss:[bx].RHLS_rhi, cxdx
		call	RunHeapUnlock
		add	sp, size RunHeapLockStruct

		.leave
		ret
GadgetUnlockPropertyString	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetCreatePropertyString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the passed property string on the run heap

CALLED BY:	UTILITY
PASS:		ss:bp - GetPropertyArgs struct
		ds:si - ptr to string
		ax - size of string (including NULL); 0 for NULL string
RETURN:		ax - token of created string
DESTROYED:	bx, cx, dx, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/31/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetCreatePropertyString	proc	near
		.enter

	;
	; check for NULL string
	;
		tst	ax				;NULL string?
		jz	storeStringToken		;branch if so
	;
	; create a string on the heap to hold the string
	;
		sub	sp, size RunHeapAllocStruct
		mov	bx, sp
		movdw	cxdx, ss:[bp].GPA_runHeapInfoPtr

		movdw	ss:[bx].RHAS_data, dssi
		mov	ss:[bx].RHAS_size, ax
		clr	ss:[bx].RHAS_refCount
		mov	ss:[bx].RHAS_type, RHT_STRING
		movdw	ss:[bx].RHAS_rhi, cxdx
		
		call	RunHeapAlloc
		add	sp, size RunHeapAllocStruct
	;
	; store the string token created
	;
storeStringToken:
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_STRING
		mov	es:[di].CD_data.LD_string, ax

		.leave
		ret
GadgetCreatePropertyString	endp

GadgetMastCode	ends
