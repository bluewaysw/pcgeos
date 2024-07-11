COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		GadgetGroup.asm

AUTHOR:		David Loftesness, Jun 28, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	6/28/94   	Initial revision


DESCRIPTION:
	
		
	$Id: gdggroup.asm,v 1.1 98/03/11 04:30:34 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	GadgetGroupClass
idata	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGroupEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	arrange our guts the way we wants 'em

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetGroupClass object
		ds:di	= GadgetGroupClass instance data
		ds:bx	= GadgetGroupClass object (same as *ds:si)
		es 	= segment of GadgetGroupClass
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
GadgetGroupEntInitialize	method dynamic GadgetGroupClass, 
					MSG_ENT_INITIALIZE
	.enter

	;
	; Tell superclass to do its thing
	;
		mov	di, offset GadgetGroupClass
		call	ObjCallSuperNoLock

	;
	; deref back from chunk handle
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset

	;;
	;; Setup instance data for the interaction
	;;


		mov	ds:[di].GII_type, GIT_ORGANIZATIONAL
		mov	ds:[di].GII_visibility, GIV_SUB_GROUP
		mov	ds:[di].GII_attrs, 0

	;
	; Setup hints for Normal Look
	;


	.leave
	ret
GadgetGroupEntInitialize	endm

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGroupVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the background color of the group on open.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= GadgetGroupClass object
		ds:di	= GadgetGroupClass instance data
		ds:bx	= GadgetGroupClass object (same as *ds:si)
		es 	= segment of GadgetGroupClass
		ax	= message #
		cl	= DrawFlags
		bp	= gstate
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		GrFillRect(VisGetBounds)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGroupVisDraw	method dynamic GadgetGroupClass, 
					MSG_VIS_DRAW

	.enter
	
ifdef COLOR_WACKINESS
		test	cl, mask DF_EXPOSED
		jz	setClip
		
		push	cx
		mov	di, bp			; gstate

		mov	ax, C_LIGHT_GREEN
		call	GrSetAreaColor
		call	VisGetBounds
		call	GrFillRect
		pop	cx
setClip:

endif
		
	;
	; Set a clip region so children can't draw outside the group.
	;

	; commented out because Doug says no clipping
ifdef	GROUP_CLIPPING
		mov	di, bp			; gstate
		push	bp			; gstate
		call	GrSaveState
		push	cx			; DrawFlags

		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjCallInstanceNoLock
		push	si			; self

		Assert	gstate, di
		mov	si, PCT_INTERSECTION	; adding the region
		call	GrSetClipRect
		pop	si			; self

		mov	bp, di			; gstate
		pop	cx			; DrawFlags
endif 
		mov	ax, MSG_VIS_DRAW
		mov	di, offset GadgetGroupClass
		call	ObjCallSuperNoLock

ifdef GROUP_CLIPPING
		pop	di			; gstate
		call	GrRestoreState
endif		

	.leave
	ret
GadgetGroupVisDraw	endm

endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGroupMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform the system of our association to GenText

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= GadgetGroupClass object
		ds:di	= GadgetGroupClass instance data
		ds:bx	= GadgetGroupClass object (same as *ds:si)
		es 	= segment of GadgetGroupClass
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
GadgetGroupMetaResolveVariantSuperclass	method dynamic GadgetGroupClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

		compResolveSuperclass	GadgetGroup, GenInteraction

GadgetGroupMetaResolveVariantSuperclass	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGroupGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return "group"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetGroupClass object
		ds:di	= GadgetGroupClass instance data
		ds:bx	= GadgetGroupClass object (same as *ds:si)
		es 	= segment of GadgetGroupClass
		ax	= message #
RETURN:		cx:dx	= "group"
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGroupGetClass	method dynamic GadgetGroupClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetGroupString
		mov	dx, offset GadgetGroupString
		ret
GadgetGroupGetClass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGroupSetLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the look for the group.  Removes old looks if needed.

CALLED BY:	MSG_GADGET_SET_LOOK
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/22/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGroupSetLook	method dynamic GadgetGroupClass, 
					MSG_GADGET_SET_LOOK
		uses	bp
		.enter

	;
	; call our superclass to set the look
	;
		mov	di, offset GadgetScrollbarClass
		call	ObjCallSuperNoLock
	;
	; call utility to add and remove hints as necessary
	;
		mov	ax, GadgetGroupLook		;ax <- maximum look
		mov	cx, length groupHints		;cx <- length of hints
		segmov	es, cs
		mov	dx, offset groupHints		;es:dx <- ptr ot hints
		call	GadgetUtilSetLookHints

		.leave
		Destroy	ax, cx, dx
		ret

groupHints word \
	HINT_DRAW_IN_BOX,
	HINT_DO_NOT_USE_MONIKER
normalGroupHints nptr \
	GadgetRemoveHint,	;no: draw in box
	GadgetRemoveHint	;no: do not use moniker
boxHints nptr \
	GadgetAddHint,		;draw in box
	GadgetRemoveHint	;no: do not use moniker
noMonikerHints nptr \
	GadgetRemoveHint,	;no: draw in box
	GadgetAddHint		;do not use moniker

ForceRef normalGroupHints
ForceRef boxHints
ForceRef noMonikerHints

CheckHack <length normalGroupHints eq length groupHints>
CheckHack <length boxHints eq length groupHints>
CheckHack <length noMonikerHints eq length groupHints>
CheckHack <offset normalGroupHints eq offset groupHints+size groupHints>
CheckHack <offset boxHints eq offset normalGroupHints+size normalGroupHints>
CheckHack <offset noMonikerHints eq offset boxHints+size boxHints>

CheckHack <LOOK_GROUP_NORMAL eq 0>
CheckHack <LOOK_GROUP_DRAW_IN_BOX eq 1>
CheckHack <LOOK_GROUP_NO_MONIKER eq 2>

GadgetGroupSetLook	endm

if 0		; moved to GadgetGeom


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGroupVisRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= GadgetGroupClass object
		ds:di	= GadgetGroupClass instance data
		ds:bx	= GadgetGroupClass object (same as *ds:si)
		es 	= segment of GadgetGroupClass
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
GadgetGroupVisRecalcSize	method dynamic GadgetGroupClass, 
					MSG_VIS_RECALC_SIZE

		.enter
		test	ds:[di].GGI_flags, mask GGF_TILED
		jnz	callSuper
	;
	; If we are not tiled, size our children and ourself
	;
		call	GadgetUtilVisRecalcSize
		call	GadgetUtilSizeSelf
		mov	ax, MSG_VIS_SET_SIZE
		call	ObjCallInstanceNoLock
		jmp	done
		

callSuper:
		mov	di, offset GadgetGroupClass
		mov	ax, MSG_VIS_RECALC_SIZE
		call	ObjCallSuperNoLock
done:
		.leave
		ret
GadgetGroupVisRecalcSize	endm

endif		; moved to gadget geom

ifdef	GROUP_CLIPPING

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGroupVisVupCreateGstate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_VIS_VUP_CREATE_GSTATE
PASS:		*ds:si	= GadgetGroupClass object
		ds:di	= GadgetGroupClass instance data
		ds:bx	= GadgetGroupClass object (same as *ds:si)
		es 	= segment of GadgetGroupClass
		ax	= message #
RETURN:		^hbp	= gstate
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGroupVisVupCreateGstate	method dynamic GadgetGroupClass, 
					MSG_VIS_VUP_CREATE_GSTATE

		.enter
		mov	di, offset GadgetGroupClass
		call	ObjCallSuperNoLock

	;
	; Set a clip rect on the group
	;
		mov	di, bp
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjCallInstanceNoLock

		mov	si, PCT_INTERSECTION	; add to path
		call	GrSetClipRect
		stc
		mov	bp, di
		.leave
		ret
GadgetGroupVisVupCreateGstate	endm

endif

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGroupVisAddChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When a child is added to us, tell our parent, its grandparent
		to redo geometry and redraw.

CALLED BY:	MSG_VIS_ADD_CHILD
PASS:		*ds:si	= GadgetGroupClass object
		ds:di	= GadgetGroupClass instance data
		ds:bx	= GadgetGroupClass object (same as *ds:si)
		es 	= segment of GadgetGroupClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Why the grandparent, you ask. 'cause it works.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGroupVisAddChild	method dynamic GadgetGroupClass, 
					MSG_VIS_ADD_CHILD
		uses	cx, dx
		.enter
		mov	bl, ds:[di].GGI_flags
		push	bx
		mov	di, offset GadgetGroupClass
		CallSuper	MSG_VIS_ADD_CHILD
		pop	ax
		test	al, mask GGF_TILED
		jnz	done
	;
	; if tiled, we don't need this hack.

		call	GadgetUtilUpdateVisStuffOnAdd
done:		
		.leave
		ret
GadgetGroupVisAddChild	endm

endif
