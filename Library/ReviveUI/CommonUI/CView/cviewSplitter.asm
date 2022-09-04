COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CView (common code for several specific ui's)
FILE:		cviewSplitter.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLSplitterClass		splitter class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/92		Initial version

DESCRIPTION:

	$Id: cviewSplitter.asm,v 1.4 94/10/14 17:13:10 dlitwin Exp $

-------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLSplitterClass		mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED

CommonUIClassStructures ends



if	0		;NO SPLITTER YET

Build			segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLSplitterSetFlags -- 
		MSG_SPEC_SPLITTER_SET_FLAGS for OLSplitterClass

DESCRIPTION:	Sets flags.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPLITTER_SET_FLAGS
		cl	- flags to set
		ch	- flags to clear

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
	chris	8/20/92		Initial Version

------------------------------------------------------------------------------@

OLSplitterSetFlags	method dynamic	OLSplitterClass, \
				MSG_SPEC_SPLITTER_SET_FLAGS
	or	ds:[di].OLSI_flags, cl
	not	ch
	and	ds:[di].OLSI_flags, ch
	ret
OLSplitterSetFlags	endm




COMMENT @----------------------------------------------------------------------

METHOD:		OLSplitterSetOtherView -- 
		MSG_SPEC_SPLITTER_SET_OTHER_VIEW for OLSplitterClass

DESCRIPTION:	Sets the other view instance data.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SPLITTER_SET_OTHER_VIEW
		^lcx:dx	- other view

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
	chris	8/21/92		Initial Version

------------------------------------------------------------------------------@

OLSplitterSetOtherView	method dynamic	OLSplitterClass, \
				MSG_SPEC_SPLITTER_SET_OTHER_VIEW

	movdw	ds:[di].OLSI_otherView, cxdx
	ret
OLSplitterSetOtherView	endm

Build			ends

CommonFunctional	segment	resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLSplitterDraw -- 
		MSG_VIS_DRAW for OLSplitterClass

DESCRIPTION:	Draws the splitter.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_DRAW

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
	chris	8/20/92		Initial Version

------------------------------------------------------------------------------@

OLSplitterDraw	method dynamic	OLSplitterClass, MSG_VIS_DRAW
	mov	ax, C_BLACK
	call	GrSetAreaColor
	call	VisGetBounds
	call	GrFillRect
	ret
OLSplitterDraw	endm

CommonFunctional	ends


Geometry	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLSplitterRecalcSize -- 
		MSG_VIS_RECALC_SIZE for OLSplitterClass

DESCRIPTION:	Chooses a size for the splitter.  For the moment, this is fixed.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_RECALC_SIZE
		cx, dx  - suggested size values

RETURN:		cx, dx  - size
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	8/20/92		Initial Version

------------------------------------------------------------------------------@

OLSplitterRecalcSize	method dynamic	OLSplitterClass, MSG_VIS_RECALC_SIZE
	movdw	bxsi, ds:[di].OLSI_otherView	;get other view

EC <	tst	bx							>
EC <	ERROR_Z	OL_ERROR			;shouldn't happen	>

	mov	ax, MSG_GEN_GET_USABLE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;get its usable status

	mov	dx, SPLITTER_HEIGHT		;assume other view not there
	jc	haveHeight
	shr	dx, 1				;is there, divide height by 2
						;(a matching part exists in the
						; other view as well)
haveHeight:
OLS <	mov	cx, SCROLLBAR_WIDTH		;for the moment this is fixed  >
CUAS<	mov	cx, MO_SCROLLBAR_WIDTH					       >
	test	ds:[di].OLSI_flags, mask OLSF_VERTICAL
	jnz	10$				
	xchg	cx, dx				;swap if horizontal
10$:
	ret
OLSplitterRecalcSize	endm

Geometry	ends


endif	;NO SPLITTER YET
