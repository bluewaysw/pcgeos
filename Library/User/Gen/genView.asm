COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genView.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenViewClass		View object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Chris	6/89		Changed to a view

DESCRIPTION:
	This file contains routines to implement the View class

	$Id: genView.asm,v 1.1 97/04/07 11:44:42 newdeal Exp $

-------------------------------------------------------------------------------@

; see documentation in /staff/pcgeos/Library/User/Doc/GenView.doc

UserClassStructures	segment resource

; Declare class table

	GenViewClass

UserClassStructures	ends

Build	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenViewInitialize

DESCRIPTION:	Initialize object

PASS:
	*ds:si - instance data
	es - segment of GenViewClass
	ax - MSG_META_INITIALIZE

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	NOTE:  THIS ROUTINE ASSUME THAT THE OBJECT HAS JUST BEEN CREATED
	AND HAS INSTANCE DATA OF ALL 0'S FOR THE VIS PORTION

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/91		Initial version

------------------------------------------------------------------------------@

GenViewInitialize	method static	GenViewClass, MSG_META_INITIALIZE

	mov	di, offset GenViewClass
	call	ObjCallSuperNoLock
	;
	; Initialize to match .cpp and .esp defaults
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	or	ds:[di].GI_attrs, mask GA_TARGETABLE

	or	ds:[di].GVI_attrs, mask GVA_FOCUSABLE
	mov	ds:[di].GVI_color.CQ_redOrIndex, C_WHITE

	mov	ax, 1
	mov	ds:[di].GVI_scaleFactor.PF_x.WWF_int, ax
	mov	ds:[di].GVI_scaleFactor.PF_y.WWF_int, ax

	mov	ds:[di].GVI_increment.PD_x.low, 20
	mov	ds:[di].GVI_increment.PD_y.low, 15
	ret

GenViewInitialize	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenViewBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenViewClass

DESCRIPTION:	Return the correct specific class for an object

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenViewClass

	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS

	cx - ?
	dx - ?
	bp - ?

RETURN:
	carry - ?
	ax - ?
	cx:dx - class for specific UI part of object (cx = 0 for no build)
	bp - ?

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@


GenViewBuild	method	GenViewClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	mov	ax, SPIR_BUILD_VIEW
	GOTO	GenQueryUICallSpecificUI

GenViewBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenViewSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	RESPONDER ONLY.  Prevents horizontal scrollbar.

CALLED BY:	MSG_SPEC_BUILD

PASS:		*ds:si	= GenViewClass object
		ds:di	= GenViewClass instance data
		ds:bx	= GenViewClass object (same as *ds:si)
		es 	= segment of GenViewClass
		ax	= message #
		bp	= SpecBuildFlags

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @----------------------------------------------------------------------

METHOD:		GenViewSetAttrs

DESCRIPTION:	Set view attributes
		NOTE:  Attributes may ONLY be changed while the object is
		not USABLE.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_GEN_VIEW_SET_ATTRS

	cx	- bits to set
	dx	- bits to clear
	bp	- update mode for changing GVA_NO_WIN_FRAME or GVA_VIEW_
			FOLLOWS_CONTENT_GEOMETRY (VUM_MANUAL allowed here...)

RETURN:
	Nothing
	ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

GenViewSetAttrs	method	GenViewClass, MSG_GEN_VIEW_SET_ATTRS

	; figure out what *really* needs to change

	mov	ax, ds:[di].GVI_attrs
	call	ComputeMinimalBitsToSetReset
	jc	done
	mov	ds:[di].GVI_attrs, ax

	call	ObjMarkDirty				;mark stuff as dirty
	test	bx, mask GVA_NO_WIN_FRAME or \
				mask GVA_VIEW_FOLLOWS_CONTENT_GEOMETRY
	jz	noGeometryChange
	call	FinishAttrChange			;invalidate things...
noGeometryChange:
	mov	ax, MSG_GEN_VIEW_SET_ATTRS
	call	GenViewOnlyCallIfSpecBuilt
done:
EC <	Destroy	ax, cx, dx, bp				;trash things	    >
	ret
GenViewSetAttrs	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	ComputeMinimalBitsToSetReset

DESCRIPTION:	...

CALLED BY:	INTERNAL

PASS:
	ax - current value
	cx - bits to set
	dx - bits to clear

RETURN:
	ax - new value
	bx - bits changed
	cx - minimal bits to set
	dx - minimal bits to clear
	carry - set if nothing to do

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/18/92		Initial version

------------------------------------------------------------------------------@
ComputeMinimalBitsToSetReset	proc	far

	mov	bx, ax					;bx = old
	not	dx
	and	ax, dx
	or	ax, cx
	cmp	ax, bx
	jz	nothingToDo				;no changes!

	; ax = new attributes

	xor	bx, ax					;bx = changed

	; set = changed & new

	mov	cx, bx
	and	cx, ax					;cx = bits to set

	; reset = changed & !new

	mov	dx, bx
	not	ax
	and	dx, ax					;dx = bits to reset
	not	ax
	clc
	ret

nothingToDo:
	clr	bx
	clr	cx
	clr	dx
	stc
	ret

ComputeMinimalBitsToSetReset	endp

COMMENT @----------------------------------------------------------------------

METHOD:		GenViewSetDimensionAttrs

DESCRIPTION:	Set view dimension attributes.  Use this method while the view
		is usable AT YOUR OWN RISK.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_GEN_VIEW_SET_ATTRS

	cl	- horizAttributes to set
	ch	- horizAttributes to reset
	dl	- vertAttributes to set
	dh	- vertAttributes to reset
	bp	- update mode  (VUM_MANUAL allowed here...)

RETURN:
	Nothing
	ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/90		Initial version

------------------------------------------------------------------------------@

GenViewSetDimensionAttrs	method	GenViewClass, \
				MSG_GEN_VIEW_SET_DIMENSION_ATTRS
EC <	test	cl, mask GVDA_SPLITTABLE		;too late now, buddy...>
EC <	ERROR_NZ  UI_CANT_MAKE_SPLITTABLE_VIA_MESSAGE			 >
EC <	test	dl, mask GVDA_SPLITTABLE		;too late now, buddy...>
EC <	ERROR_NZ  UI_CANT_MAKE_SPLITTABLE_VIA_MESSAGE			 >

	;
	; For Responder, we prevent the horzintal scrollbar from ever
	; appearing.  Thus, we turn on this attribute in MSG_SPEC_BUILD
	; (above) and we never allow it to be reset.
	;

	push	bp
	clr	bp					;flag
	push	dx					;save vertical bits
	clr	ax
	mov	al, ds:[di].GVI_horizAttrs		;ax = current value
	clr	dx
	mov	dl, ch					;dx = bits to clear
	clr	ch					;cx = bits to set

	call	ComputeMinimalBitsToSetReset
	jc	noChangeH
	mov	ds:[di].GVI_horizAttrs, al
	inc	bp					;set change flag
noChangeH:
	mov	ch, dl
	pop	dx

	push	cx
	clr	ax
	mov	al, ds:[di].GVI_vertAttrs		;ax = current value
	clr	cx
	mov	cl, dl					;cx = bits to set
	mov	dl, dh
	clr	dh					;dx = bits to clear
	call	ComputeMinimalBitsToSetReset
	jc	noChangeV
	mov	ds:[di].GVI_vertAttrs, al
	inc	bp					;set change flag
noChangeV:
	mov	dh, dl
	mov	dl, cl
	pop	cx

	tst	bp
	pop	bp
	jnz	10$
	ret

10$:

	call	ObjMarkDirty

	call	VisCheckIfSpecBuilt			;if not visually built
	jnc	FinishAttrChange			;then branch
	mov	ax, MSG_GEN_VIEW_SET_DIMENSION_ATTRS
	mov	di, offset GenViewClass			;else send to spec UI
	push	bp					;  to see if wants to
	call	ObjCallSuperNoLock			;  do anything special
	pop	bp

	FALL_THRU	FinishAttrChange

GenViewSetDimensionAttrs	endm

FinishAttrChange	proc	far	uses cx, dx
	.enter

	mov	dx, bp					;update mode
	cmp	dl, VUM_MANUAL				;if manual, get out
	je	exit

	call	VisCheckIfSpecBuilt			;if not visually built
	jnc	exit					;then no update needed

	;
	; Invalidate our geometry, so that DetermineSizes will get to us, and
	; the pane's parent's geometry, so the pane will have a chance to
	; expand.
	;
	push	dx					;save passed update mode
	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_MANUAL				;
	call	VisMarkInvalid				;do view first
	pop	dx

	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	ax, MSG_VIS_MARK_INVALID
	call	VisCallParent
exit:
	.leave
EC <	Destroy	ax, bp				;trash things	    >
	ret

FinishAttrChange	endp


Build	ends

;
;---------------
;

BuildUncommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenViewSetBGColor

DESCRIPTION:	Set View window bacground wash color.
		NOTE:  Attributes may ONLY be changed while the object is
		not USABLE.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_GEN_VIEW_SET_COLOR

	cl	- Red value
	ch	- ColorFlag
	dl	- Green color
	dh	- Blue color


RETURN:
	Nothing
	ax, cx, dx, bp -- Destroyed

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

GenViewSetBGColor	method	GenViewClass, MSG_GEN_VIEW_SET_COLOR
	clr	di				;no stack frame
	call	GenViewSendToLinksIfNeeded	;use linkage if there
	jc	exit				;we did, we're done now

	mov	bx, offset GVI_color.CQ_redOrIndex
	xchg	cx, dx				;make into cx:dx
	call	GenSetDWord
	xchg	cx, dx				;back to dx.cx
	jnc	exit
	call	GenCallSpecIfGrown		;call specific UI if grown
exit:
EC <	Destroy	ax, cx, dx, bp			;trash things	    >
	ret
GenViewSetBGColor	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenViewReplaceParams

DESCRIPTION:	Replaces any generic instance data paramaters that match
		BranchReplaceParamType

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_GEN_BRANCH_REPLACE_PARAMS

	dx	- size BranchReplaceParams structure
	ss:bp	- offset to BranchReplaceParams

RETURN:
	nothing
	ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@

GenViewReplaceParams	method	GenViewClass, \
					MSG_GEN_BRANCH_REPLACE_PARAMS
	cmp	ss:[bp].BRP_type, BRPT_OUTPUT_OPTR	; Replacing output optr?
	je	replaceOD		; 	branch if so
	jmp	short done

replaceOD:
					; Replace action OD if matches
					;	search OD
	mov	ax, MSG_GEN_VIEW_SET_CONTENT
	mov	bx, offset GVI_content
	call	GenReplaceMatchingDWord
done:
	mov	ax, MSG_GEN_BRANCH_REPLACE_PARAMS
	mov	di, offset GenViewClass
	GOTO	ObjCallSuperNoLock

GenViewReplaceParams	endm

BuildUncommon ends

;---------------------------------------------------

GetUncommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenViewGetAttrs --
		MSG_GEN_VIEW_GET_ATTRS for GenViewClass

DESCRIPTION:	Returns view attributes.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_GET_ATTRS

RETURN:		cx -- attributes
		ax, dx, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/19/91		Initial version

------------------------------------------------------------------------------@

GenViewGetAttrs	method	GenViewClass, MSG_GEN_VIEW_GET_ATTRS
EC <	Destroy	ax, dx, bp				;trash things	    >
	mov	cx, ds:[di].GVI_attrs
	ret
GenViewGetAttrs	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenViewGetDimensionAttrs --
		MSG_GEN_VIEW_GET_DIMENSION_ATTRS for GenViewClass

DESCRIPTION:	Returns dimension attrs.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_GET_DIMENSION_ATTRS

RETURN:		cl	- horiz attrs
		ch	- vert attrs
		ax, dx, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/19/91		Initial version

------------------------------------------------------------------------------@

GenViewGetDimensionAttrs method GenViewClass,\
				MSG_GEN_VIEW_GET_DIMENSION_ATTRS
EC <	Destroy	ax, dx, bp				;trash things	    >
	mov	cx, {word} ds:[di].GVI_horizAttrs
	ret
GenViewGetDimensionAttrs endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenViewGetBGColor --
		MSG_GEN_VIEW_GET_COLOR for GenViewClass

DESCRIPTION:	Returns background color.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_GET_COLOR

RETURN:		cl	- Red value
		ch	- ColorFlag
		dl	- Green color
		dh	- Blue color
		ax, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/19/91		Initial version

------------------------------------------------------------------------------@

GenViewGetBGColor	method	GenViewClass, MSG_GEN_VIEW_GET_COLOR
EC <	Destroy	ax, bp					;trash things	    >
	mov	bx, offset GVI_color.CQ_redOrIndex
	call	GenGetDWord
	xchg	cx, dx
	ret
GenViewGetBGColor	endm


GetUncommon	ends

;
;---------------
;

ViewCommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenViewGetDocBounds --
		MSG_GEN_VIEW_GET_DOC_BOUNDS for GenViewClass

DESCRIPTION:	Returns document bounds.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_GET_DOC_BOUNDS
		cx:dx	- buffer of size RectDWord

RETURN:		cx:dx   - RectDWord: document bounds
		ax, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/19/91		Initial version

------------------------------------------------------------------------------@

GenViewGetDocBounds	method	GenViewClass, MSG_GEN_VIEW_GET_DOC_BOUNDS
	mov	es, cx
	mov	bp, dx

	mov	ax, ds:[di].GVI_docBounds.RD_left.low
	mov	es:[bp].RD_left.low, ax
	mov	ax, ds:[di].GVI_docBounds.RD_left.high
	mov	es:[bp].RD_left.high, ax
	mov	ax, ds:[di].GVI_docBounds.RD_right.low
	mov	es:[bp].RD_right.low, ax
	mov	ax, ds:[di].GVI_docBounds.RD_right.high
	mov	es:[bp].RD_right.high, ax
	mov	ax, ds:[di].GVI_docBounds.RD_top.low
	mov	es:[bp].RD_top.low, ax
	mov	ax, ds:[di].GVI_docBounds.RD_top.high
	mov	es:[bp].RD_top.high, ax
	mov	ax, ds:[di].GVI_docBounds.RD_bottom.low
	mov	es:[bp].RD_bottom.low, ax
	mov	ax, ds:[di].GVI_docBounds.RD_bottom.high
	mov	es:[bp].RD_bottom.high, ax
EC <	Destroy	ax, bp					;trash things	    >
	ret
GenViewGetDocBounds	endm

ViewCommon	ends

;
;---------------
;

GetUncommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenViewGetIncrement --
		MSG_GEN_VIEW_GET_INCREMENT for GenViewClass

DESCRIPTION:	Returns increment.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_GET_INCREMENT
		cx:dx	- buffer of size PointDWord

RETURN:		cx:dx	- {PointDWord} increment amounts
		ax, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/19/91		Initial version

------------------------------------------------------------------------------@

GenViewGetIncrement	method GenViewClass, \
				MSG_GEN_VIEW_GET_INCREMENT
	mov	es, cx				;stack segment of passed buffer
	mov	bp, dx
	mov	ax, ds:[di].GVI_increment.PD_x.low
	mov	es:[bp].PD_x.low, ax
	mov	ax, ds:[di].GVI_increment.PD_x.high
	mov	es:[bp].PD_x.high, ax
	mov	ax, ds:[di].GVI_increment.PD_y.low
	mov	es:[bp].PD_y.low, ax
	mov	ax, ds:[di].GVI_increment.PD_y.high
	mov	es:[bp].PD_y.high, ax
EC <	Destroy	ax, bp					;trash things	    >
	ret
GenViewGetIncrement	endm


GetUncommon	ends
;
;-------------------
;
ViewCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenViewGetOrigin --
		MSG_GEN_VIEW_GET_ORIGIN for GenViewClass

DESCRIPTION:	Returns current origin.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_GET_ORIGIN
		cx:dx	- buffer of size PointDWord to put origin

RETURN:		cx:dx	- {PointDWord} current origin
		ax, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/19/91		Initial version
	Jim	7/29/91		Added support for fixed point GVI_origin

------------------------------------------------------------------------------@

GenViewGetOrigin	method GenViewClass, \
				MSG_GEN_VIEW_GET_ORIGIN
	push	cx
	mov	es, cx				;buffer in es:bp
	mov	bp, dx
	mov	cx, ds:[di].GVI_origin.PDF_x.DWF_int.low
	mov	al, ds:[di].GVI_origin.PDF_x.DWF_frac.high
	shl	al, 1					; round the result
	adc	cx, 0
	mov	es:[bp].PD_x.low, cx
	mov	cx, ds:[di].GVI_origin.PDF_x.DWF_int.high
	adc	cx, 0
	mov	es:[bp].PD_x.high, cx
	mov	cx, ds:[di].GVI_origin.PDF_y.DWF_int.low
	mov	al, ds:[di].GVI_origin.PDF_y.DWF_frac.high
	shl	al, 1					; round the result
	adc	cx, 0
	mov	es:[bp].PD_y.low, cx
	mov	cx, ds:[di].GVI_origin.PDF_y.DWF_int.high
	adc	cx, 0
	mov	es:[bp].PD_y.high, cx
	pop	cx
EC <	Destroy	ax, bp					;trash things	    >
	ret
GenViewGetOrigin	endm

ViewCommon	ends
;
;-------------------
;
GetUncommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenViewGetContent --
		MSG_GEN_VIEW_GET_CONTENT for GenViewClass

DESCRIPTION:	Returns current content object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_GET_CONTENT

RETURN:		^lcx:dx	- content
		ax, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/19/91		Initial version

------------------------------------------------------------------------------@

GenViewGetContent	method GenViewClass, \
				MSG_GEN_VIEW_GET_CONTENT
EC <	Destroy	ax, bp					;trash things	    >
	mov	bx,  offset GVI_content
	GOTO	GenGetDWord
GenViewGetContent	endm

GetUncommon	ends

;
;---------------
;

Build	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenViewSetContent

DESCRIPTION:	If specific UI grown, calls to handle.  Otherwise, stuffs
		outputOD & marks dirty.

PASS:
	*ds:si - instance data
	es - segment of MetaClass
	ax - MSG_GEN_VIEW_SET_CONTENT
	cx:dx	- new content OD

RETURN:
	nothing
	ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


GenViewSetContent	method	GenViewClass, MSG_GEN_VIEW_SET_CONTENT
	call	GenCallSpecIfGrown	; Call specific UI if grown
	jc	exit			; if called, done
	mov	bx,  offset GVI_content	; Otherwise, just stuff OD
	call	GenSetDWord
exit:
EC <	Destroy	ax, cx, dx, bp				;trash things	    >
	ret
GenViewSetContent	endm

Build	ends

;
;---------------
;

Ink	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenViewSetInkType

DESCRIPTION:	If specific UI grown, calls to handle.  Otherwise, stuffs
		inkType & marks dirty.

PASS:
	*ds:si - instance data
	es - segment of MetaClass
	ax - MSG_GEN_VIEW_SET_CONTENT
	cl - GenViewInkType

RETURN:
	nothing
	ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


GenViewSetInkType	method	GenViewClass, MSG_GEN_VIEW_SET_INK_TYPE
	clr	di				;no stack frame
	call	GenViewSendToLinksIfNeeded	;use linkage if there
	jc	exit				;we did, we're done now

	call	GenCallSpecIfGrown	; Call specific UI if grown
	jc	exit			; if called, done

	mov	bx, offset GVI_inkType
	call	GenSetByte
exit:
EC <	Destroy	ax, cx, dx, bp				;trash things	    >
	ret
GenViewSetInkType	endm


Ink	ends

;
;---------------
;

Common	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenViewSetDocBounds --
		MSG_GEN_VIEW_SET_DOC_BOUNDS for GenViewClass

DESCRIPTION:	Sets new document bounds.  Generic handler will set instance
		data, then pass on the specific UI for processing.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SET_DOC_BOUNDS
		ss:bp   - RectDWord: new scrollable bounds, or all zeroed if
				we don't want to constrain drag scrolling.

RETURN:		nothing
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/91		Initial version

------------------------------------------------------------------------------@

GenViewSetDocBounds	method GenViewClass, \
				MSG_GEN_VIEW_SET_DOC_BOUNDS
	mov	di, mask MF_STACK		;has stack frame
	call	GenViewSendToLinksIfNeeded	;use linkage if there
	jc	exit				;we did, we're done now

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

if	ERROR_CHECK
	push	cx
	mov	cx, ss:[bp].RD_left.high
	cmp	cx, ss:[bp].RD_right.high
	ERROR_G	UI_VIEW_BAD_DOC_BOUNDS
	jl	EC10
	mov	cx, ss:[bp].RD_left.low
	cmp	cx, ss:[bp].RD_right.low
	ERROR_A	UI_VIEW_BAD_DOC_BOUNDS
EC10:
	mov	cx, ss:[bp].RD_top.high
	cmp	cx, ss:[bp].RD_bottom.high
	ERROR_G	UI_VIEW_BAD_DOC_BOUNDS
	jl	EC20
	mov	cx, ss:[bp].RD_top.low
	cmp	cx, ss:[bp].RD_bottom.low
	ERROR_A	UI_VIEW_BAD_DOC_BOUNDS
EC20:
	pop	cx
endif


	push	ax, bp				;save bp
	clr	bx				;keep offset into instance data
	clr	cx				;init count of changes
10$:
	mov	ax, {word} ss:[bp]		;store if changed
	cmp	ax, {word} ds:[di].GVI_docBounds
	je	20$
	inc	cx				;bump change counter
	mov	{word} ds:[di].GVI_docBounds, ax
20$:
	add	bx, 2				;bump counter
	add	bp, 2				;and stack buffer pointer
	add	di, 2				;and instance data pointer
	cmp	bx, size RectDWord		;done everything?
	jb	10$				;no, loop
	pop	ax, bp				;restore bp

	jcxz	exit				;exit if no changes made

	call	ObjMarkDirty			;mark as dirty
	call	GenCallSpecIfGrown		;Call specific UI if grown
exit:						;    to finish things up
EC <	Destroy	ax, cx, dx, bp				;trash things	    >
	ret
GenViewSetDocBounds	endm


Common	ends

;
;---------------
;

BuildUncommon	segment	resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenViewSetIncrement --
		MSG_GEN_VIEW_SET_INCREMENT for GenViewClass

DESCRIPTION:	Sets the increment amount.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SET_INCREMENT
		ss:bp   - {PointDWord} new increment amount
				      (zero in a given direction if no change
				       desired)

RETURN:		nothing
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/12/89		Initial version

------------------------------------------------------------------------------@

GenViewSetIncrement	method GenViewClass, MSG_GEN_VIEW_SET_INCREMENT
	mov	di, mask MF_STACK		;use stack frame
	call	GenViewSendToLinksIfNeeded	;use linkage if there
	jc	exit				;we did, we're done now

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

EC <	tst	ss:[bp].PD_x.high					>
EC <	ERROR_S	UI_VIEW_BAD_INCREMENT					>
EC <	tst	ss:[bp].PD_y.high					>
EC <	ERROR_S	UI_VIEW_BAD_INCREMENT					>

	mov	ax, ss:[bp].PD_x.low
	mov	bx, ss:[bp].PD_x.high
	mov	cx, ss:[bp].PD_y.low
	mov	dx, ss:[bp].PD_y.high

	tst	ax				;new value to use?
	jnz	10$				;no, branch
	tst	bx
	jz	tryVert
10$:
	mov	ds:[di].GVI_increment.PD_x.low, ax
	mov	ds:[di].GVI_increment.PD_x.high, bx

tryVert:
	tst	dx				;new value to use?
	jnz	20$
	jcxz	callSpecific			;no, branch
20$:
	mov	ds:[di].GVI_increment.PD_y.low, cx
	mov	ds:[di].GVI_increment.PD_y.high, dx

callSpecific:

	call	ObjMarkDirty
	mov	ax, MSG_GEN_VIEW_SET_INCREMENT
	call	GenCallSpecIfGrown		;Call specific UI if grown
exit:
EC <	Destroy	ax, cx, dx, bp				;trash things	    >
	ret
GenViewSetIncrement	endm


BuildUncommon	ends

;
;---------------
;

ViewCommon	segment	resource



COMMENT @----------------------------------------------------------------------

ROUTINE:	GenSetupTrackingArgs

SYNOPSIS:	Fills in extra data for trackings.

CALLED BY:	FAR library routine

PASS:		ss:bp -- TrackScrollingParams
		ds  - segment of LMem block or block in
			which ds:[LMBH_handle] = block handle

RETURN:		ss:bp -- updated TrackScrollingParams

DESTROYED:	nothing

WARNING:  	This routine MAY resize LMem and/or object blocks, moving
		them on the heap and invalidating stored segment pointers
		to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 1/90		Initial version

------------------------------------------------------------------------------@

GenSetupTrackingArgs	proc	far	uses	ax, di
	.enter
	mov	dx, bp			;pass cx:dx - TrackScrollingParams
	mov	cx, ss
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_VIEW_SETUP_TRACKING_ARGS
	call	ReturnToCaller
	.leave
	ret
GenSetupTrackingArgs	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	GenReturnTrackingArgs

SYNOPSIS:	Sends the tracking structure back to the caller.

CALLED BY:	FAR utility

PASS:		ss:bp -- TrackScrollingParams
		cx - caller's chunk handler
		ds  - segment of LMem block or block in
			which ds:[LMBH_handle] = block handle

RETURN:		ds - updated to point at segment of same block as on entry

DESTROYED:	nothing

	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 1/90		Initial version

------------------------------------------------------------------------------@

GenReturnTrackingArgs	proc	far		uses di, ax
	.enter
	;
	; If absolute, we'll set up newOrigin so the MSG_GEN_VIEW_TRACKING_-
	; COMPLETE handler can use the newOrigin for scrolling rather than
	; the change.  We run into problems with the content processing the
	; same absolute scroll twice before the view has received completion of
	; either, where the returned change doesn't reflect what the content
	; wanted.  -cbh 3/23/92
	;
	test	ss:[bp].TSP_flags, mask SF_ABSOLUTE
	jz	10$				; relative, new origin ignored
	mov	ax, ss:[bp].TSP_oldOrigin.PD_x.low	;get old origin
	mov	bx, ss:[bp].TSP_oldOrigin.PD_x.high
	mov	cx, ss:[bp].TSP_oldOrigin.PD_y.low
	mov	dx, ss:[bp].TSP_oldOrigin.PD_y.high
	add	cx, ss:[bp].TSP_change.PD_y.low		;add change,
	mov	ss:[bp].TSP_newOrigin.PD_y.low, cx	; store as new origin
	adc	dx, ss:[bp].TSP_change.PD_y.high
	mov	ss:[bp].TSP_newOrigin.PD_y.high, dx

	add	ax, ss:[bp].TSP_change.PD_x.low
	mov	ss:[bp].TSP_newOrigin.PD_x.low, ax
	adc	bx, ss:[bp].TSP_change.PD_x.high
	mov	ss:[bp].TSP_newOrigin.PD_x.high, bx
10$:
;	mov	di, mask MF_STACK or mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	mov	dx, size TrackScrollingParams	; set size if needed
	mov	ax, MSG_GEN_VIEW_TRACKING_COMPLETE
	call	ReturnToCaller
	.leave
	ret
GenReturnTrackingArgs	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	ReturnToCaller

SYNOPSIS:	Returns a call to the caller.

CALLED BY:	GenSetupTrackingArgs, GenReturnTrackingArgs

PASS:		ss:[bp] -- TrackScrollingParams
		dx -- other arguments to ObjMessage
		di -- flags to ObjMessage
		ax -- method to send

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/24/91		Initial version

------------------------------------------------------------------------------@

ReturnToCaller	proc	near	uses	bx, cx, dx, bp, si
	.enter
	mov	bx, ss:[bp].TSP_caller.handle
	mov	si, ss:[bp].TSP_caller.chunk
	call	ObjMessage			; Send it off
	.leave
	ret
ReturnToCaller	endp




COMMENT @----------------------------------------------------------------------

METHOD:		GenViewSetOrigin --
		MSG_GEN_VIEW_SET_ORIGIN for GenViewClass

DESCRIPTION:	Sets the subview origin.  Doesn't force building out of the
		view.  If the view hasn't been opened, any subsequent subviews
		opened will have this offset initially.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SET_ORIGIN
		ss:bp   - {PointDWord} - new origin

RETURN:
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/22/90		Initial version
	Jim	7/29/91		Added support for fixed point GVI_origin

------------------------------------------------------------------------------@

GenViewSetOrigin method GenViewClass,MSG_GEN_VIEW_SET_ORIGIN
	call	VisCheckIfSpecBuilt		;if not visually built
	jnc	setGenericDataOnly		;then just set instance data
	mov	di, offset GenViewClass		;else send to specific UI
	GOTO	ObjCallSuperNoLock

setGenericDataOnly:
	call	ObjMarkDirty
	mov	cx, ss:[bp].PD_x.low
	mov	ds:[di].GVI_origin.PDF_x.DWF_int.low, cx
	mov	cx, ss:[bp].PD_x.high
	mov	ds:[di].GVI_origin.PDF_x.DWF_int.high, cx
	mov	cx, ss:[bp].PD_y.low
	mov	ds:[di].GVI_origin.PDF_y.DWF_int.low, cx
	mov	cx, ss:[bp].PD_y.high
	mov	ds:[di].GVI_origin.PDF_y.DWF_int.high, cx
	clr	cx
	mov	ds:[di].GVI_origin.PDF_x.DWF_frac, cx
	mov	ds:[di].GVI_origin.PDF_y.DWF_frac, cx
EC <	Destroy	ax, cx, dx, bp				;trash things	    >
	ret
GenViewSetOrigin	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenViewScroll --
		MSG_GEN_VIEW_SCROLL for GenViewClass

DESCRIPTION:	Changes the subview origin.  Doesn't force building out of the
		view.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SCROLL
		ss:bp   - {PointDWord} amount to scroll

RETURN:		nothing
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/22/90		Initial version
	Jim	7/29/91		Added support for fixed point GVI_origin

------------------------------------------------------------------------------@

GenViewScroll method GenViewClass,MSG_GEN_VIEW_SCROLL
	call	VisCheckIfSpecBuilt		;if not visually built
	jnc	setGenericDataOnly		;then just set instance data
	mov	di, offset GenViewClass		;else send to specific UI
	GOTO	ObjCallSuperNoLock

setGenericDataOnly:
	mov	di, mask MF_STACK		;use stack frame
	call	GenViewSendToLinksIfNeeded	;use linkage if there
	jc	exit				;we did, we're done now
	call	ScrollView
exit:
EC <	Destroy	ax, cx, dx, bp				;trash things	    >
	ret
GenViewScroll	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenViewScrollLow --
		MSG_GEN_VIEW_SET_ORIGIN_LOW for GenViewClass

DESCRIPTION:	Changes the subview origin.  Doesn't force building out of the
		view.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SET_ORIGIN_LOW
		ss:bp   - {PointDWord} amount to scroll

RETURN:		nothing
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/22/90		Initial version
	Jim	7/29/91		Added support for fixed point GVI_origin

------------------------------------------------------------------------------@

GenViewScrollLow method GenViewClass,MSG_GEN_VIEW_SET_ORIGIN_LOW
	call	VisCheckIfSpecBuilt		;if not visually built
	jnc	setGenericDataOnly		;then just set instance data
	mov	di, offset GenViewClass		;else send to specific UI
	GOTO	ObjCallSuperNoLock

setGenericDataOnly:
	call	ScrollView
EC <	Destroy	ax, cx, dx, bp				;trash things	    >
	ret
GenViewScrollLow	endm


ScrollView	proc	near
	class	GenViewClass

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	call	ObjMarkDirty

	cmpdw	ss:[bp].PD_x, GVSOL_NO_CHANGE
	je	afterX
	mov	cx, ss:[bp].PD_x.low
	add	ds:[di].GVI_origin.PDF_x.DWF_int.low, cx
	mov	cx, ss:[bp].PD_x.high
	adc	ds:[di].GVI_origin.PDF_x.DWF_int.high, cx
afterX:

	cmpdw	ss:[bp].PD_y, GVSOL_NO_CHANGE
	je	afterY
	mov	cx, ss:[bp].PD_y.low
	add	ds:[di].GVI_origin.PDF_y.DWF_int.low, cx
	mov	cx, ss:[bp].PD_y.high
	adc	ds:[di].GVI_origin.PDF_y.DWF_int.high, cx
afterY:
	ret
ScrollView	endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenViewScrollOnWheel for GenViewClass

DESCRIPTION:	Scrolls the view on wheel up / down

PASS:
		cx = mouse x
		dx = mouse y
		bp = shiftState in the high byte

RETURN:		ax = wheel event processed
		ax, bx, di, -- trashed

ALLOWED TO DESTROY:	?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MeyerK	09/2021 	initial implementation

------------------------------------------------------------------------------@

GenViewScrollOnWheel	method dynamic GenViewClass, 	MSG_META_MOUSE_WHEEL_UP, \
							MSG_META_MOUSE_WHEEL_DOWN

	cmp	ax, MSG_META_MOUSE_WHEEL_DOWN
	je	scrollDown

scrollUp:
  	mov 	ax, MSG_GEN_VIEW_SCROLL_UP
	jmp 	finish

scrollDown:
  	mov 	ax, MSG_GEN_VIEW_SCROLL_DOWN

finish:
	mov 	bx, ds:[LMBH_handle]			;	oself
	mov 	di, mask MF_CAN_DISCARD_IF_DESPERATE
	call 	ObjMessage
  	mov 	ax, mask MRF_PROCESSED

	ret

GenViewScrollOnWheel	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenViewScale --
		MSG_GEN_VIEW_SET_SCALE_FACTOR for GenViewClass

DESCRIPTION:	Sets scale factor.  If not yet built, just changes the
		instance data, but will not change the document offset.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SET_SCALE_FACTOR
		ss:bp	- {ScaleViewParams} new scale factor

RETURN:		nothing
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/19/91		Initial version

------------------------------------------------------------------------------@

GenViewScale	method GenViewClass, MSG_GEN_VIEW_SET_SCALE_FACTOR

EC <	test	ds:[di].GVI_attrs, mask GVA_GENERIC_CONTENTS		>
EC <	WARNING_NZ  WARNING_VIEW_SHOULD_NOT_SCALE_UI_GADGETS		>

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	mov	dx, ss:[bp].SVP_scaleFactor.PF_x.WWF_int
	mov	cx, ss:[bp].SVP_scaleFactor.PF_x.WWF_frac
	mov	bx, ss:[bp].SVP_scaleFactor.PF_y.WWF_int
	mov	ax, ss:[bp].SVP_scaleFactor.PF_y.WWF_frac

	cmp	dx, ds:[di].GVI_scaleFactor.PF_x.WWF_int
	jne	10$
	cmp	cx, ds:[di].GVI_scaleFactor.PF_x.WWF_frac
	jne	10$
	cmp	bx, ds:[di].GVI_scaleFactor.PF_y.WWF_int
	jne	10$
	cmp	ax, ds:[di].GVI_scaleFactor.PF_y.WWF_frac
	je	exit				;no change, exit
10$:
	call	ObjMarkDirty			;mark dirty for all cases
	call	VisCheckIfSpecBuilt		;if not visually built
	jnc	setGenericDataOnly		;then just set instance data
	mov	ax, MSG_GEN_VIEW_SET_SCALE_FACTOR
	mov	di, offset GenViewClass		;else send to specific UI
	GOTO	ObjCallSuperNoLock

setGenericDataOnly:
	mov	ds:[di].GVI_scaleFactor.PF_x.WWF_int, dx
	mov	ds:[di].GVI_scaleFactor.PF_x.WWF_frac, cx
	mov	ds:[di].GVI_scaleFactor.PF_y.WWF_int, bx
	mov	ds:[di].GVI_scaleFactor.PF_y.WWF_frac, ax
exit:
EC <	Destroy	ax, cx, dx, bp				;trash things	    >
	ret
GenViewScale	endm


ViewCommon	ends

;
;---------------
;

ViewCommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenViewGetScaleFactor --
		MSG_GEN_VIEW_GET_SCALE_FACTOR for GenViewClass

DESCRIPTION:	Returns scale factors for this pane.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GET_PANE_SCALE_FACTOR

RETURN:		dx.cx   - x scale factor (WWFixed)
		bp.ax   - y scale factor (WWFixed)

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/26/90		Initial version

------------------------------------------------------------------------------@

GenViewGetScaleFactor	method GenViewClass, MSG_GEN_VIEW_GET_SCALE_FACTOR
	mov	dx, ds:[di].GVI_scaleFactor.PF_x.WWF_int
	mov	cx, ds:[di].GVI_scaleFactor.PF_x.WWF_frac
	mov	bp, ds:[di].GVI_scaleFactor.PF_y.WWF_int
	mov	ax, ds:[di].GVI_scaleFactor.PF_y.WWF_frac
	ret
GenViewGetScaleFactor	endm

ViewCommon	ends
;
;-------------------
;
GetUncommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenViewGetWindow --
		MSG_GEN_VIEW_GET_WINDOW for GenViewClass

DESCRIPTION:	Returns window handle, of null if none.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_GET_WINDOW

RETURN:		cx	- window handle, or null if none
		ax, dx, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/91		Initial version

------------------------------------------------------------------------------@

GenViewGetWindow	method GenViewClass, MSG_GEN_VIEW_GET_WINDOW
	clr	cx				;assume none
	call	GenViewOnlyCallIfSpecBuilt
EC <	Destroy	ax, dx, bp				;trash things	    >
	ret

GenViewGetWindow	endm

GetUncommon	ends

;
;---------------
;

ViewCommon	segment	resource





COMMENT @----------------------------------------------------------------------

METHOD:		GenViewSetupTrackingArgs --
		MSG_GEN_VIEW_SETUP_TRACKING_ARGS for GenViewClass

DESCRIPTION:	Sets up tracking arguments.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SETUP_TRACKING_ARGS
		cx:dx	- TrackScrollingParams

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/18/93         	Initial Version

------------------------------------------------------------------------------@

GenViewSetupTrackingArgs	method dynamic	GenViewClass, \
				MSG_GEN_VIEW_SETUP_TRACKING_ARGS
	push	es
	movdw	esbp, cxdx
	or	es:[bp].TSP_flags, mask SF_EC_SETUP_CALLED
	pop	es
	FALL_THRU	GenViewOnlyCallIfSpecBuilt

GenViewSetupTrackingArgs	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenViewOnlyCallIfSpecBuilt --
		MSG_GEN_VIEW_MAKE_RECT_VISIBLE for GenViewClass
		MSG_GEN_VIEW_TRACKING_COMPLETE for GenViewClass

DESCRIPTION:	Only calls specific UI object if specifically built already.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax	- method
		cx,dx,bp- args

RETURN:		nothing

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/25/90		Initial version

------------------------------------------------------------------------------@

GenViewOnlyCallIfSpecBuilt method GenViewClass, \
					MSG_GEN_VIEW_MAKE_RECT_VISIBLE,    \
			  		MSG_GEN_VIEW_TRACKING_COMPLETE,    \
					MSG_GEN_VIEW_INITIATE_DRAG_SCROLL, \
					MSG_GEN_VIEW_SCROLL_TOP,	   \
					MSG_GEN_VIEW_SCROLL_PAGE_UP,	      \
					MSG_GEN_VIEW_SCROLL_UP,	      \
					MSG_GEN_VIEW_SCROLL_SET_Y_ORIGIN,   \
					MSG_GEN_VIEW_SCROLL_DOWN,	      \
					MSG_GEN_VIEW_SCROLL_BOTTOM,	      \
					MSG_GEN_VIEW_SCROLL_LEFT_EDGE,      \
					MSG_GEN_VIEW_SCROLL_PAGE_LEFT,      \
					MSG_GEN_VIEW_SCROLL_LEFT,	      \
					MSG_GEN_VIEW_SCROLL_SET_X_ORIGIN,   \
					MSG_GEN_VIEW_SCROLL_RIGHT,	     \
					MSG_GEN_VIEW_SCROLL_PAGE_RIGHT,     \
					MSG_GEN_VIEW_SCROLL_RIGHT_EDGE,     \
					MSG_GEN_VIEW_SUSPEND_UPDATE,	     \
					MSG_GEN_VIEW_UNSUSPEND_UPDATE
	call	VisCheckIfSpecBuilt		;if not visually built
	jnc	exit				;then exit
	mov	di, offset GenViewClass		;else send to specific UI
	GOTO	ObjCallSuperNoLock
exit:
	ret
GenViewOnlyCallIfSpecBuilt	endm







COMMENT @----------------------------------------------------------------------

ROUTINE:	GenViewSetSimpleBounds

SYNOPSIS:	Sets simple bounds.

CALLED BY:	global

PASS:		^lbx:si -- view handle
		cx	-- 16 bit right bound to set (width of your doc)
		dx	-- 16 bit bottom bound to set (height of your doc)
		di	-- MessageFlags:
				MF_FIXUP_DS to fixup DS around call to view
				MF_FIXUP_ES to fixup ES around call to view

RETURN:		nothing
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/91		Initial version

------------------------------------------------------------------------------@

GenViewSetSimpleBounds	proc	far		uses	ax, cx, dx, bp, di
	.enter
EC <	tst	cx					;small only!	>
EC <	ERROR_S	UI_VIEW_NEG_WIDTH_PASSED_TO_SET_SIMPLE_BOUNDS		>
EC <	tst	dx							>
EC <	ERROR_S	UI_VIEW_NEG_HEIGHT_PASSED_TO_SET_SIMPLE_BOUNDS		>
EC <	test	di, not (mask MF_FIXUP_DS or mask MF_FIXUP_ES)		>
EC <	ERROR_NZ  UI_VIEW_BAD_MESSAGE_FLAGS_PASSED_TO_SET_SIMPLE_BOUNDS >

	sub	sp, size RectDWord			;set up parameters
	mov	bp, sp
	clr	ax
	mov	ss:[bp].RD_left.low, ax			;origin 0, 0
	mov	ss:[bp].RD_left.high, ax
	mov	ss:[bp].RD_top.low, ax
	mov	ss:[bp].RD_top.high, ax
	mov	ss:[bp].RD_right.high, ax		;clear other high words
	mov	ss:[bp].RD_bottom.high, ax
	mov	ss:[bp].RD_right.low, cx		;right edge <- width
	mov	ss:[bp].RD_bottom.low, dx		;bottom edge <- height
	mov	dx, size RectDWord
	or	di, mask MF_STACK or mask MF_CALL
	mov	ax, MSG_GEN_VIEW_SET_DOC_BOUNDS	;set new document size
	call	ObjMessage
	add	sp, size RectDWord
	.leave
	ret
GenViewSetSimpleBounds	endp




COMMENT @----------------------------------------------------------------------

METHOD:		GenViewGetVisibleRect --
		MSG_GEN_VIEW_GET_VISIBLE_RECT for GenViewClass

DESCRIPTION:	Returns the visible rectangle.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_GET_VISIBLE_RECT
		cx:dx	- buffer of size RectDWord

RETURN:		cx:dx   - {RectDWord} visible area, or null if not yet built
		ax, bp -- trashed

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 2/91		Initial version

------------------------------------------------------------------------------@

GenViewGetVisibleRect	method GenViewClass, MSG_GEN_VIEW_GET_VISIBLE_RECT
	push	es
	mov	es, cx
	mov	di, dx
	clr	es:[di].RD_left.low		;assume not built
	clr	es:[di].RD_left.high
	clr	es:[di].RD_top.low
	clr	es:[di].RD_top.high
	clr	es:[di].RD_right.low
	clr	es:[di].RD_right.high
	clr	es:[di].RD_bottom.low
	clr	es:[di].RD_bottom.high
	pop	es
	GOTO	GenViewOnlyCallIfSpecBuilt

GenViewGetVisibleRect	endm


ViewCommon	ends

;
;---------------
;

Build	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenViewAddGenChild --
		MSG_GEN_ADD_CHILD for GenViewClass
		MSG_GEN_REMOVE_CHILD for GenViewClass

DESCRIPTION:	Sends the method first to the specific UI, then to superclass.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- method
		cx, dx, bp - args

RETURN:		ax, cx, dx, bp - any return values

ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/10/91		Initial version

------------------------------------------------------------------------------@

GenViewAddGenChild	method GenViewClass, MSG_GEN_ADD_CHILD, \
					     MSG_GEN_REMOVE_CHILD
	push	ax, cx, dx, bp
	mov	di, offset GenClass
	call	ObjCallSuperNoLock		;first, call specific UI
	pop	ax, cx, dx, bp

	mov	di, offset GenViewClass		;then do normal GenClass add
	GOTO	ObjCallSuperNoLock

GenViewAddGenChild	endm


Build	ends

;
;---------------
;

ViewCommon	segment	resource



COMMENT @----------------------------------------------------------------------

ROUTINE:	GenViewSendToLinksIfNeeded

SYNOPSIS:	Takes the current message, encapsulates it, and sends it off
		to the linked views, if there are any.

CALLED BY:	GLOBAL, called at the start of handlers for
       			all scroll messages (called after tracking complete)
			MSG_GEN_VIEW_SET_SCALE_FACTOR
			MSG_GEN_VIEW_SET_DOC_BOUNDS
			MSG_GEN_VIEW_SET_CONTENT
			MSG_GEN_VIEW_SET_INCREMENT
			MSG_GEN_VIEW_SUSPEND_UPDATE
			MSG_GEN_VIEW_UNSUSPEND_UPDATE
			MSG_GEN_VIEW_SET_COLOR

PASS:		*ds:si	       -- view
		ax	       -- message
		cx, dx, bp     -- arguments to message
		di	       -- MF_STACK if a stack message, 0 if not

RETURN:		carry set if message sent to MSG_GEN_VIEW_SEND_TO_LINKS
			with ax, cx, dx, bp destroyed
		clear if message not sent (and should be handled normally),
			with ax, cx, dx, bp preserved

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/16/91	Initial version

------------------------------------------------------------------------------@

GenViewSendToLinksIfNeeded	proc	far
	uses	bx
	.enter
	clr	bx
	call	GenViewSendToLinksIfNeededDirection
	.leave
	ret
GenViewSendToLinksIfNeeded	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenViewSendToLinksIfNeededDirection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ROUTINE:	GenViewSendToLinksIfNeededDirection

SYNOPSIS:	Takes the current message, encapsulates it, and sends it off
		to the linked views, if there are any.  Changed to
		only send to the links specified in bx

CALLED BY:	Internal, called at the start of handlers for
       			all scroll messages (called after tracking complete)
			MSG_GEN_VIEW_SET_SCALE_FACTOR
			MSG_GEN_VIEW_SET_DOC_BOUNDS
			MSG_GEN_VIEW_SET_CONTENT
			MSG_GEN_VIEW_SET_INCREMENT
			MSG_GEN_VIEW_SUSPEND_UPDATE
			MSG_GEN_VIEW_UNSUSPEND_UPDATE
			MSG_GEN_VIEW_SET_COLOR

PASS:		*ds:si	       -- view
		ax	       -- message
		cx, dx, bp     -- arguments to message
		di	       -- MF_STACK if a stack message, 0 if not
		bx	       -- bx = < 0 if horizontal only scroll
                                     = > 0 if vertical only scroll
				     =   0 if scroll in both dircestions

RETURN:		carry set if message sent to MSG_GEN_VIEW_SEND_TO_LINKS
			with ax, cx, dx, bp destroyed
		clear if message not sent (and should be handled normally),
			with ax, cx, dx, bp preserved

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/16/91	Initial version
	IP	1/ 9/95    	changed to only send to specified link

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenViewSendToLinksIfNeededDirection	proc	far
	uses 	si, bx
	class	GenViewClass
	.enter
	push	bx
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	tst	ds:[bx].GVI_vertLink.handle	;a vertical link, encapsulate
	jnz	encapsulate
	tst_clc	ds:[bx].GVI_horizLink.handle	;no vert or horiz link, exit,
						;   not handled
	jz	popExit

encapsulate:
	pop	bx
	cmp	ax, MSG_GEN_VIEW_SET_ORIGIN_LOW	;is this our scroll guy?
	je	handleScroll			;yes, handle it specially

	mov	bx, MSG_GEN_VIEW_SEND_TO_LINKS	;send to all links
	call	SendInLinkMessage
	jmp	short exitHandled

handleScroll:
	tst 	bx
	jg	noHoriz

	push	ss:[bp].PD_y.low		;nuke the vertical portion
	push	ss:[bp].PD_y.high
	movdw	ss:[bp].PD_y, GVSOL_NO_CHANGE

	push	bx
	mov	bx, MSG_GEN_VIEW_SEND_TO_VLINK
	call	SendInLinkMessage
	pop	bx

	pop	ss:[bp].PD_y.high
	pop	ss:[bp].PD_y.low

	tst	bx
noHoriz:
	jl	noVert
	movdw	ss:[bp].PD_x, GVSOL_NO_CHANGE

	mov	bx, MSG_GEN_VIEW_SEND_TO_HLINK
	call	SendInLinkMessage		;send to horizontal link
noVert:
exitHandled:
	stc					;say handled through links
exit:
	.leave
	ret

popExit:
	pop	bx
	jmp	exit
GenViewSendToLinksIfNeededDirection	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	SendInLinkMessage

SYNOPSIS:	Encapsulates a GenView message and sends it in a link message.
		Frees the event after sent off.

CALLED BY:	GenViewSendToLinksIfNeeded

PASS:		*ds:si     -- GenView
		di	   -- MF_STACK or zero, depending on message
		ax         -- message to encapsulate
		cx, dx, bp -- arguments
		bx         -- link message to send out, either:
				MSG_GEN_VIEW_SEND_TO_HLINK
				MSG_GEN_VIEW_SEND_TO_VLINK
				MSG_GEN_VIEW_SEND_TO_LINKS

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/17/91		Initial version

------------------------------------------------------------------------------@

SendInLinkMessage	proc	near		uses ax, cx, dx, bp, di
	class	GenViewClass
	.enter
	push	bx
	mov	bx, ds:[LMBH_handle]		;pass destination in ^lbx:si
	push	si
	or	di, mask MF_RECORD		;encapsulate the message
	call	ObjMessage
	pop	si
	mov	bp, di				;event handle in bp

	mov	cx, ds:[LMBH_handle]		;pass originator in ^lcx:dx
	mov	dx, si
	pop	ax				;restore event message
	call	ObjCallInstanceNoLock

	mov	bx, di
	call	ObjFreeMessage			;get rid of the event
	.leave
	ret
SendInLinkMessage	endp





COMMENT @----------------------------------------------------------------------

METHOD:		GenViewSendToLinks --
		MSG_GEN_VIEW_SEND_TO_LINKS for GenViewClass

DESCRIPTION:	Sends the event to all the links, by moving horizontally
		and sending out MSG_GEN_VIEW_SEND_TO_VLINK at each node.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SEND_TO_LINKS

		bp	- event
		^lcx:dx	- originator

RETURN:
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	10/17/91		Initial Version

------------------------------------------------------------------------------@

GenViewSendToLinks	method dynamic	GenViewClass, \
				MSG_GEN_VIEW_SEND_TO_LINKS

	push	ax, cx, dx, bp			;save original originator
	;
	; Send a MSG_GEN_VIEW_SEND_TO_VLINK to ourselves, to call ourselves
	; with the encapsulated message and anyone we're linked to vertically.
	;
	mov	cx, ds:[LMBH_handle]		;pass ourselves
	mov	dx, si
	mov	ax, MSG_GEN_VIEW_SEND_TO_VLINK
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp

	;
	; Now, pass this message along to the horizontal link, if it doesn't
	; match the originator.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GVI_horizLink.handle
	mov	di, ds:[di].GVI_horizLink.chunk
	GOTO	SendToLink

GenViewSendToLinks	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenViewSendToVLink --
		MSG_GEN_VIEW_SEND_TO_VLINK for GenViewClass

DESCRIPTION:	Sends encapsulated message to all nodes in the vertical link.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SEND_TO_VLINK

		bp	- event
		^lcx:dx	- originator

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	10/16/91		Initial Version

------------------------------------------------------------------------------@

GenViewSendToVLink	method dynamic GenViewClass, MSG_GEN_VIEW_SEND_TO_VLINK
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GVI_vertLink.handle
	mov	di, ds:[di].GVI_vertLink.chunk

CallOurselvesAndSendToLink	label	far
	;
	; Send to ourselves, ignoring any links.
	;
	push	ax, cx, dx, bp
	mov	cx, mask MF_RECORD or mask MF_CALL	;preserve message
	mov	ax, MSG_GEN_VIEW_CALL_WITHOUT_LINKS
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp

SendToLink			label far
	;
	; If no vertical link, or the link matches the originator, nothing
	; to send, exit.  (^lbx:di is the link)
	;
	mov	si, di
	tst	bx

EC <	pushf								     >
EC <	jnz	EC10					;is linkage, branch  >
EC <	cmp	si, dx					;no linkage, better  >
EC <	jne	EC10					;  be originator!    >
EC <	cmp	bx, cx							     >
EC <	ERROR_E	UI_VIEW_LINKAGE_MUST_BE_CIRCULAR			     >
EC <EC10:								     >
EC <	popf								     >

	jz	exit
	cmp	si, dx
	jne	sendToLink
	cmp	bx, cx
	je	exit

sendToLink:
	mov	di, mask MF_CALL			;send to link
	call	ObjMessage
exit:
	ret
GenViewSendToVLink	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenViewSendToHLink --
		MSG_GEN_VIEW_SEND_TO_HLINK for GenViewClass

DESCRIPTION:	Propagates a message through the horizontal links.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SEND_TO_HLINK

		bp	- event
		^lcx:dx	- originator of the message

RETURN:
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	10/16/91		Initial Version

------------------------------------------------------------------------------@

GenViewSendToHLink	method dynamic	GenViewClass, MSG_GEN_VIEW_SEND_TO_HLINK
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GVI_horizLink.handle
	mov	di, ds:[di].GVI_horizLink.chunk
	GOTO	CallOurselvesAndSendToLink

GenViewSendToHLink	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenViewCallWithoutLinks --
		MSG_GEN_VIEW_CALL_WITHOUT_LINKS for GenViewClass

DESCRIPTION:	Dispatches a GenView message that will ignore horizontal
		and vertical links.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_CALL_WITHOUT_LINKS

		bp	- ClassedEvent
		cx	- ObjMessageFlags to pass to MessageDispatch

RETURN:		ax, cx, dx, bp - any return arguments

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	10/16/91		Initial Version

------------------------------------------------------------------------------@

GenViewCallWithoutLinks	method dynamic	GenViewClass, \
				MSG_GEN_VIEW_CALL_WITHOUT_LINKS

	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	push	ds:[di].GVI_vertLink.handle,
		ds:[di].GVI_vertLink.chunk,
		ds:[di].GVI_horizLink.handle,
		ds:[di].GVI_horizLink.chunk

	clr	ax
	mov	ds:[di].GVI_vertLink.handle, ax
	mov	ds:[di].GVI_vertLink.chunk, ax
	mov	ds:[di].GVI_horizLink.handle, ax
	mov	ds:[di].GVI_horizLink.chunk, ax

	mov	di, cx			;flags
	mov	bx, bp			;event

	test	di, mask MF_RECORD
	jz	dispatch

	push	si
	call	ObjGetMessageInfo	;save event destination data
	mov	dx, si
	pop	si
	push	cx, dx

dispatch:
	mov	cx, ds:[LMBH_handle]	;send to ourselves
	call	MessageSetDestination
	ornf	di, mask MF_FIXUP_DS	; make sure this is set...
	call	MessageDispatch

	test	di, mask MF_RECORD
	jz	done			; => message was destroyed, so no need
					;  to restore the destination
	pop	cx, dx

	push	si
	mov	si, dx
	call	MessageSetDestination	;restore event destination data
	pop	si
done:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	pop	ds:[di].GVI_vertLink.handle,
		ds:[di].GVI_vertLink.chunk,
		ds:[di].GVI_horizLink.handle,
		ds:[di].GVI_horizLink.chunk

	pop	di
	call	ThreadReturnStackSpace

	ret
GenViewCallWithoutLinks	endm

ViewCommon	ends

;
;---------------
;

Ink	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenViewResetExtendedInkType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes any "extended" ink info from the object.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenViewResetExtendedInkType	method	GenViewClass,
				MSG_GEN_VIEW_RESET_EXTENDED_INK_TYPE
	.enter
	mov	ax, ATTR_GEN_VIEW_INK_DESTINATION_INFO
	call	ObjVarDeleteData
	Destroy	ax, cx, dx, bp
	.leave
	ret
GenViewResetExtendedInkType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenViewSetExtendedInkType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes any "extended" ink info from the object.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenViewSetExtendedInkType	method	GenViewClass,
				MSG_GEN_VIEW_SET_EXTENDED_INK_TYPE
	.enter
	clr	bh
	mov	bl, mask OCF_VARDATA_RELOC
	mov	ax, si
	call	ObjSetFlags

	mov	ax, ATTR_GEN_VIEW_INK_DESTINATION_INFO
	mov	cx, size InkDestinationInfoParams
	call	ObjVarAddData
	mov	cx, size InkDestinationInfoParams/2
	segmov	es, ds
	mov	di, bx
	segmov	ds, ss
	mov	si, bp
	rep	movsw
	Destroy	ax, cx, dx, bp
	.leave
	ret
GenViewSetExtendedInkType	endp

Ink	ends
