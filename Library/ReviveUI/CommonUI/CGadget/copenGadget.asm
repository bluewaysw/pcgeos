COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/Open (gadgets)
FILE:		copenGadget.asm (common portion of button code)

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLGadgetClass		Open look button

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

DESCRIPTION:

	$Id: copenGadget.asm,v 2.9 94/10/14 16:24:44 dlitwin Exp $
------------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLGadgetClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
					;flags for class

CommonUIClassStructures ends

;---------------------------------------------------

CommonFunctional segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLGadgetVupQuery -- MSG_VIS_VUP_QUERY for OLGadgetClass

DESCRIPTION:	Respond to a query traveling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of OLGadgetCompClass

	ax - MSG_VIS_VUP_QUERY
	cx - Query type (VupQueryType)
	dx - ?
	bp - ?
RETURN:
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/89		Initial version

------------------------------------------------------------------------------@


OLGadgetVupQuery	method	OLGadgetClass, MSG_VIS_VUP_QUERY
	cmp	cx, VUQ_DISPLAY_SCHEME		;can we answer this query?
	je	OLGCVQ_10			;skip if so...

	;we can't answer this query: call super class to handle
	mov	di, offset OLGadgetCompClass
	GOTO	ObjCallSuperNoLock

OLGCVQ_10:
	call	SpecGetDisplayScheme
	mov	bp,dx			;return in ax, cx, dx, bp
	mov	dx,cx
	mov	cx,bx
	stc
	ret

OLGadgetVupQuery	endp

CommonFunctional ends

