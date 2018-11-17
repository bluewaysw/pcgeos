COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj	
FILE:		grobjText.asm

AUTHOR:		Steve Scholl, May  3, 1992

ROUTINES:
	Name		
	----		

METHODS:
	Name		
	----		
GrObjTextMetaInitialize
GrObjTextBuild
GrObjTextHeightNotify
GrObjTextAdjustMarginsForLineWidth

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	5/ 3/92		Initial revision


DESCRIPTION:
	
		

	$Id: grobjText.asm,v 1.1 97/04/04 18:08:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

GrObjTextClass		;Define the class record

GrObjClassStructures	ends

GrObjTextGuardianCode	segment resource





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjTextMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjTextClass

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTextMetaInitialize	method dynamic GrObjTextClass, MSG_META_INITIALIZE
	.enter

	mov	di, offset GrObjTextClass
	CallSuper	MSG_META_INITIALIZE

	;    Initialize some text instance data.
	;

	mov	bx, Vis_offset
	call	ObjInitializePart
	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset

	;    Pad the edges to keep the text object from clearing
	;    over the edit indicator
	;
	mov	ds:[di].VTI_lrMargin,1
	mov	ds:[di].VTI_tbMargin,1
	ornf	ds:[di].VTI_state, mask VTS_TARGETABLE
	mov	ds:[di].VTI_maxLength, MAX_TEXT_OBJECT_CHARS
	ornf	ds:[di].VTI_features, mask VTF_ALLOW_UNDO or mask VTF_ALLOW_SMART_QUOTES

	mov	ax, ATTR_VIS_TEXT_DOES_NOT_ACCEPT_INK
	clr	cx
	call	ObjVarAddData
	.leave
	ret
GrObjTextMetaInitialize		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjTextBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The variant parent of the GrObjTextClass is VisTextClass

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjTextClass

RETURN:		
		cx:dx - fptr to VisTextClass
	

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTextBuild	method dynamic GrObjTextClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	.enter

	mov	cx,segment VisTextClass
	mov	dx, offset VisTextClass

	.leave
	ret
GrObjTextBuild		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjTextHeightNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Relay message to quardian

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClassText

		dx - desired height

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
	srs	5/ 7/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTextHeightNotify	method dynamic GrObjTextClass, 
						MSG_VIS_TEXT_HEIGHT_NOTIFY
	.enter

	mov	ax,MSG_TG_HEIGHT_NOTIFY
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisMessageToGuardian

	;   In some situations the VisText object attempts to send out
	;   a notification while handling MSG_META_FINAL_OBJ_FREE.
	;   So don't put error checking code here that checks
	;   the returned zero flag from GrObjVisMessageToGuardian
	;


	.leave
	ret
GrObjTextHeightNotify		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjTextAdjustMarginsForLineWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the margins of the text object so that they
		don't collide with the lines around the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjTextClass


		dx:cx - WWFixed line with

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
	srs	5/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTextAdjustMarginsForLineWidth	method dynamic GrObjTextClass, 
					MSG_GT_ADJUST_MARGINS_FOR_LINE_WIDTH
	uses	cx,dx
	.enter

	add	bx,ds:[bx].VisText_offset

	;   Account for 1/2 the line width on each side
	;	

	shrwwf	dxcx
	rndwwf	dxcx

	;    If the margins haven't changed then do nothing
	;    We operate under the assumption that the 
	;    left right and top bottom margins are the same
	;

	cmp	ds:[bx].VTI_lrMargin,dl
	je	done
	mov	ds:[bx].VTI_lrMargin,dl
	mov	ds:[bx].VTI_tbMargin,dl

done:
	.leave
	ret
GrObjTextAdjustMarginsForLineWidth		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjTextGenerateNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjText method for MSG_VIS_TEXT_GENERATE_NOTIFY

		This routine calls the GrObjBody so that it can coalesce
		each GrObjText's attrs into a single update.

Called by:	

Pass:		*ds:si = GrObjText object
		ds:di = GrObjText instance

		ss:[bp] - VisTextGenerateNotifyParams

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTextGenerateNotify		method dynamic	GrObjTextClass,
				MSG_VIS_TEXT_GENERATE_NOTIFY

	mov	ax, MSG_GO_GET_TEMP_STATE_AND_OPT_FLAGS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjVisMessageToGuardian

	;   In some situations the VisText object attempts to send out
	;   a notification while handling MSG_META_FINAL_OBJ_FREE.
	;   Lets not die.
	;

	jz	done				;bail if no guardian

	;
	;  We don't want to send a select state notification unless
	;  we being edited (otherwise may conflict with grobj select
	;  state notifications
	;
	test	al, mask GOTM_EDITED
	jnz	checkRelay
	BitClr	ss:[bp].VTGNP_notificationTypes, VTNF_SELECT_STATE

checkRelay:
	test	ss:[bp].VTGNP_sendFlags, mask VTNSF_RELAYED_TO_LIKE_TEXT_OBJECTS
	jz	checkEditedOrSelected

	;
	;  The message has been relayed, so just call our superclass
	;
	mov	ax, MSG_VIS_TEXT_GENERATE_NOTIFY
	mov	di, offset GrObjTextClass
	GOTO	ObjGotoSuperTailRecurse

checkEditedOrSelected:
	test	al, mask GOTM_EDITED or mask GOTM_SELECTED
	jnz	sendToBody

	;    So that text objects selected groups can update the ui.
	;

	test	ah, mask GOOF_IN_GROUP
	jz	done

sendToBody:
	mov	ax, MSG_GB_GENERATE_TEXT_NOTIFY
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToBody
done:
	ret
GrObjTextGenerateNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjTextGetPotentialWardSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The text object can grow to the max.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjTextClass

RETURN:		
		cx - size in bytes
	
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
	srs	3/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTextGetPotentialWardSize	method dynamic GrObjTextClass, 
					MSG_GV_GET_POTENTIAL_WARD_SIZE
	.enter

	mov	cx,MAX_ALLOWED_POTENTIAL_GROBJ_SIZE

	.leave
	ret
GrObjTextGetPotentialWardSize		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjTextSubstAttrToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjText method for MSG_VIS_TEXT_SUBST_ATTR_TOKEN

		This routine calls the GrObjBody so that it can coalesce
		each GrObjText's attrs into a single update.

Called by:	

Pass:		*ds:si = GrObjText object
		ds:di = GrObjText instance

		ss:[bp] - VisTextSubstAttrTokenParams

Return:		none

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTextSubstAttrToken		method dynamic	GrObjTextClass,
				MSG_VIS_TEXT_SUBST_ATTR_TOKEN

	.enter

	tst	ss:[bp].VTSATP_relayedToLikeTextObjects
	jz	relay

	;
	;  The message has been relayed, so just call our superclass
	;
	mov	ax, MSG_VIS_TEXT_SUBST_ATTR_TOKEN
	mov	di, offset GrObjTextClass
	GOTO	ObjGotoSuperTailRecurse

relay:
	mov	ax, MSG_GOAM_SUBST_TEXT_ATTR_TOKEN
	call	GrObjGetGOAMOD
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
GrObjTextSubstAttrToken	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjTextRecalcForAttrChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjText method for MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE

		This routine calls the GrObjBody so that it can coalesce
		each GrObjText's attrs into a single update.

Called by:	

Pass:		*ds:si = GrObjText object
		ds:di = GrObjText instance

		ss:[bp] - VisTextRecalcForAttrChangeParams

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTextRecalcForAttrChange		method dynamic	GrObjTextClass,
				MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE

	.enter

	jcxz	relay

	;
	;  The message has been relayed, so just call our superclass
	;
	mov	ax, MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE
	mov	di, offset GrObjTextClass
	GOTO	ObjGotoSuperTailRecurse

relay:
	mov	ax, MSG_GOAM_RECALC_FOR_TEXT_ATTR_CHANGE
	call	GrObjGetGOAMOD
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
GrObjTextRecalcForAttrChange	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjTextAttributeChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send action notification to guardian

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjTextClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTextAttributeChange	method dynamic GrObjTextClass, 
						MSG_VIS_TEXT_ATTRIBUTE_CHANGE
	.enter

	mov	bp,GOANT_ATTRED
	mov	ax,MSG_GO_NOTIFY_ACTION
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisMessageToGuardian
EC <	ERROR_Z VIS_WARD_HAS_NO_GUARDIAN				>

	.leave

	Destroy	ax,cx,dx,bp

	ret
GrObjTextAttributeChange		endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjTextShowSelection -- MSG_VIS_TEXT_SHOW_SELECTION
							for GrObjTextClass

DESCRIPTION:	Show the selection

PASS:
	*ds:si - instance data
	es - segment of GrObjTextClass

	ax - The message

	ss:bp - VisTextShowSelectionArgs

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/28/92		Initial version

------------------------------------------------------------------------------@
GrObjTextShowSelection	method dynamic	GrObjTextClass,
						MSG_VIS_TEXT_SHOW_SELECTION

	tst	ds:[di].GVI_guardian.handle
	jz	callSuper

	; we must translate these coordinates properly

	mov	bx, bp				;save params
	sub	sp, size PointDWFixed
	mov	bp, sp

	push	bx, si
	movdw	bxsi, ds:[di].GVI_guardian
	mov	dx,size PointDWFixed
	mov	di,mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	mov	ax, MSG_GO_GET_POSITION
	call	ObjMessage
	pop	bx, si

	movdw	dxax, ss:[bp].PDF_x.DWF_int
	movdw	cxdi, ss:[bp].PDF_y.DWF_int

	add	sp, size PointDWFixed
	mov	bp, bx				;ss:bp = params

	adddw	ss:[bp].VTSSA_params.MRVP_bounds.RD_left, dxax
	adddw	ss:[bp].VTSSA_params.MRVP_bounds.RD_right, dxax
	adddw	ss:[bp].VTSSA_params.MRVP_bounds.RD_top, cxdi
	adddw	ss:[bp].VTSSA_params.MRVP_bounds.RD_bottom, cxdi

callSuper:
	mov	ax, MSG_VIS_TEXT_SHOW_SELECTION
	mov	di, offset GrObjTextClass
	GOTO	ObjCallSuperNoLock

GrObjTextShowSelection	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjTextScreenUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The text object has a habit of drawing without invalidating
		things. This is okay if it is being edited, but if it
		is selected or in a group this may cause the handles
		to get trounced. So if we are in a group or we are selected
		force and invalidate.

		We can't just check the edited bit though because this
		dorks GeoFile. When GeoFile is in multi-record mode it
		stamping the body down the page, replacing the text in
		the fields at each stamp location. When they replace
		the text the object can't invalidate because that would
		cause infinite redraws.


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjTextClass

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
	srs	12/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTextScreenUpdate	method dynamic GrObjTextClass, 
						MSG_VIS_TEXT_SCREEN_UPDATE
	.enter

	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_GO_GET_TEMP_STATE_AND_OPT_FLAGS
	call	GrObjVisMessageToGuardian
EC <	ERROR_Z VIS_WARD_HAS_NO_GUARDIAN				>
NEC <	jz	callSuper						>

	test	al,mask GOTM_SELECTED
	jnz	invalidate

	test	ah, mask GOOF_IN_GROUP
	jz	callSuper

invalidate:
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GO_INVALIDATE
	call	GrObjVisMessageToGuardian
EC <	ERROR_Z VIS_WARD_HAS_NO_GUARDIAN				>

callSuper:
	mov	di,offset GrObjTextClass
	mov	ax,MSG_VIS_TEXT_SCREEN_UPDATE
	call	ObjCallSuperNoLock

	.leave
	ret
GrObjTextScreenUpdate		endm




GrObjTextGuardianCode	ends

GrObjTransferCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjTextGetGrObjVisClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjText method for MSG_GV_GET_GROBJ_VIS_CLASS

Called by:	MSG_GV_GET_GROBJ_VIS_CLASS

Pass:		nothing

Return:		cx:dx - pointer to GrObjTextClass

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug  6, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTextGetGrObjVisClass	method dynamic	GrObjTextClass,
				MSG_GV_GET_GROBJ_VIS_CLASS
	.enter

	mov	cx, segment GrObjTextClass
	mov	dx, offset GrObjTextClass

	.leave
	ret
GrObjTextGetGrObjVisClass	endm

GrObjTransferCode	ends



GrObjStyleSheetCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjTextRecallStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjText method for MSG_VIS_TEXT_GENERATE_NOTIFY

		Increments the block's ref count to counter the superclass's
		dec, since we want the net result = 0

Called by:	

Pass:		*ds:si = GrObjText object
		ds:di = GrObjText instance

		ss:[bp] - SSCRecallStyleParams


Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTextRecallStyle		method dynamic	GrObjTextClass,
				MSG_META_STYLED_OBJECT_RECALL_STYLE

	;
	;  Inc the ref count so that other text objects will have
	;  a chance to see it, too
	;
	mov	cx, ss:[bp].SSCRSP_blockHandle
	mov	bx, cx
	call	MemIncRefCount

	mov	di, offset GrObjTextClass
	GOTO	ObjCallSuperNoLock
	
GrObjTextRecallStyle	endm

GrObjStyleSheetCode	ends


GrObjMiscUtilsCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjTextGetObjectForSearchSpell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Relay this puppy to the body so that it can
		figure out what to do.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjTextClass

		cx:dx - GrObjText currently being searched/spelled
		bp - GetSearchSpellObjectOption

RETURN:		
		cx:dx - new GrObjText or 0:0
	
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
	srs	9/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTextGetObjectForSearchSpell	method dynamic GrObjTextClass, 
					MSG_META_GET_OBJECT_FOR_SEARCH_SPELL,
					MSG_META_DISPLAY_OBJECT_FOR_SEARCH_SPELL
	.enter

	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToBody

	.leave
	ret
GrObjTextGetObjectForSearchSpell		endm


GrObjMiscUtilsCode	ends
