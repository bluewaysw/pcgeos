COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Ruler Library
FILE:		RulerContent.def

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10 OCT 91	Initial version.

DESCRIPTION:
	This file contains the method handlers for RulerContentClass,
	a subclass off of GenView that handles a couple geometry related
	methods that need to update any rulers that are measuring this view.

	$Id: rulerContent.asm,v 1.1 97/04/07 10:42:56 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerBasicCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerContentVupCreateGState -- MSG_VIS_VUP_CREATE_GSTATE
							for RulerContentClass

DESCRIPTION:	Create a gstate

PASS:
	*ds:si - instance data
	es - segment of RulerContentClass

	ax - The message

RETURN:
	carry - set
	bp - gstate

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/26/92		Initial version

------------------------------------------------------------------------------@
RulerContentVupCreateGState	method dynamic	RulerContentClass,
						MSG_VIS_VUP_CREATE_GSTATE

	mov	di, offset RulerContentClass
	call	ObjCallSuperNoLock

	; Do some things to scale back to 1.0.

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset

	movdw	bxax, ds:[di].VCNI_scaleFactor.PF_y
	movdw	dxcx, 0x10000			;get 1/scale
	call	GrUDivWWFixed			;dxcx = y factor
	pushdw	dxcx

	movdw	bxax, ds:[di].VCNI_scaleFactor.PF_x
	movdw	dxcx, 0x10000			;get 1/scale
	call	GrUDivWWFixed			;dxcx = x factor
	popdw	bxax

	mov	di, bp
	call	GrApplyScale			;scales back to 1.0
	stc

	ret

RulerContentVupCreateGState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			RulerContentSetScaleFactor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	RulerContent method for MSG_META_CONTENT_VIEW_ORIGIN_CHANGED

Context:	

Source:		

Desitination:	

PASS:		*ds:si 	- RulerView instance
		ss:bp	- ScaleViewParams

Return:		nothing

Destroyed:	ax, di, es

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 10, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RulerContentScaleFactorChanged	method	dynamic	RulerContentClass, MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED
	.enter
	;
	;	Let the ruler know that we've changed our scale factor
	;
	mov	ax, MSG_VIS_RULER_VIEW_SCALE_FACTOR_CHANGED
	call	VisCallFirstChild

	;
	;	Call the super class
	;
	mov	di, segment RulerContentClass
	mov	es, di
	mov	di, offset RulerContentClass
	mov	ax, MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED
	call	ObjCallSuperNoLock

	.leave
	ret
RulerContentScaleFactorChanged	endm
RulerBasicCode	ends
