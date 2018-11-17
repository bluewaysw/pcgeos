COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Admin
FILE:		objectAttr.asm

AUTHOR:		Steve Scholl, Nov 15, 1991

ROUTINES:
	Name
	----	
GrObjCanChangeAttributes?
GrObjCanDraw?

METHODS:
	Name
	----
GrObjSetAreaAttr
GrObjSetAreaColor
GrObjSetAreaMask
GrObjSetAreaDrawMode
GrObjSetAreaInfo
GrObjSetLineAttr
GrObjSetLineColor
GrObjSetLineMask
GrObjSetLineEnd
GrObjSetLineJoin
GrObjSetLineStyle
GrObjSetLineWidth
GrObjSetLineMiterLimit

GrObjGetGrObjAreaToken
GrObjGetGrObjLineToken
GrObjSetGrObjAreaToken
GrObjSetGrObjLineToken
GrObjInitToDefaultAttrs

GrObjApplyAttributesToGstate
GrObjInvertGrObjSprite
GrObjDraw		
GrObjDrawSpriteLine
GrObjDrawNormalSpriteLine
GrObjDerefAGrObjAreaToken
GrObjDerefAGrObjLineToken

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/91	Initial revision


DESCRIPTION:

	$Id: attr.asm,v 1.1 97/04/04 18:07:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrObjAttributesCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInitToDefaultAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize attributes of object to default
		attributes

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		GOI_areaAttrToken set
		GOI_lineAttrToken set
		GOI_grobjAttrFlags set

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInitToDefaultAttrs method extern dynamic GrObjClass, 
					MSG_GO_INIT_TO_DEFAULT_ATTRS
	uses	ax,cx,dx
	.enter

	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER
	jnz	done

	;    Creation of the object is undone in one sweeping gesture, 
	;    it is deleted.  This deletion will deref any necessary tokens
	;    so don't generate any undo for setting the initial tokens.
	;

	call	GrObjGlobalUndoIgnoreActions

	;    Get the current default area attr index from the manager
	;    And set it as the token for this object
	;

	mov	ax,MSG_GO_GET_GROBJ_AREA_TOKEN
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM
	mov	ax,MSG_GO_SET_GROBJ_AREA_TOKEN
	call	ObjCallInstanceNoLock

	;    Get the current default line attr index from the manager
	;    And set it as the token for this object
	;

	mov	ax,MSG_GO_GET_GROBJ_LINE_TOKEN
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM
	mov	ax,MSG_GO_SET_GROBJ_LINE_TOKEN
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GO_GET_GROBJ_ATTR_FLAGS
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM
	
	;    Reset all but the no default bits and don't set any of
	;    the no default bits
	;

	mov	dx,not NO_DEFAULT_GROBJ_ATTR_FLAGS
	andnf	cx,dx		
	mov	ax,MSG_GO_SET_GROBJ_ATTR_FLAGS
	call	ObjCallInstanceNoLock

	;    Set correct parent bounds again to account of non-standard
	;    default attrs
	;

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	call	GrObjGlobalUndoAcceptActions

done:

	.leave
	ret
GrObjInitToDefaultAttrs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMakeAttrsDefault
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set our attributes as the default in the attribute	
		manager

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMakeAttrsDefault method extern dynamic GrObjClass, 
					MSG_GO_MAKE_ATTRS_DEFAULT
	uses	ax,cx,dx
	.enter

	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER or \
					mask GOOF_ATTRIBUTE_MANAGER
	jnz	done

	;    It doesn't make sense to undo this
	;

	call	GrObjGlobalUndoIgnoreActions

	mov	ax,MSG_GO_GET_GROBJ_AREA_TOKEN
	call	ObjCallInstanceNoLock
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GO_SET_GROBJ_AREA_TOKEN
	call	GrObjMessageToGOAM

	mov	ax,MSG_GO_GET_GROBJ_LINE_TOKEN
	call	ObjCallInstanceNoLock
	mov	ax,MSG_GO_SET_GROBJ_LINE_TOKEN
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToGOAM

	mov	ax,MSG_GO_GET_GROBJ_ATTR_FLAGS
	call	ObjCallInstanceNoLock

	;    Reset all but the no default bits and don't set any of
	;    the no default bits
	;

	mov	dx,not NO_DEFAULT_GROBJ_ATTR_FLAGS
	andnf	cx,dx		
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_GO_SET_GROBJ_ATTR_FLAGS
	call	GrObjMessageToGOAM

	call	GrObjGlobalUndoAcceptActions

done:

	.leave
	ret
GrObjMakeAttrsDefault	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetGrObjAreaToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the GrObjBaseAreaAttrElement token

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		cx - area token
		must return carry set
	
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
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetGrObjAreaToken	method extern dynamic GrObjClass, 
					MSG_GO_GET_GROBJ_AREA_TOKEN
	.enter

	mov	cx,ds:[di].GOI_areaAttrToken
	stc

	.leave
	ret
GrObjGetGrObjAreaToken		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetGrObjLineToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the GrObjBaseLineAttrElement token

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		cx - line token
		must return carry set
	
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
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetGrObjLineToken	method extern dynamic GrObjClass, 
					MSG_GO_GET_GROBJ_LINE_TOKEN
	.enter

	mov	cx,ds:[di].GOI_lineAttrToken
	stc

	.leave
	ret
GrObjGetGrObjLineToken		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetGrObjAreaToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the area attribute token of the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cx - area token

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
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetGrObjAreaToken	method extern dynamic GrObjClass, 
					MSG_GO_SET_GROBJ_AREA_TOKEN
	uses	cx, dx, bp
	.enter

	cmp	cx, CA_NULL_ELEMENT
	je	returnToBaseStyle

	call	GrObjAttrGenerateUndoAreaAttrChangeChain

	call	ObjMarkDirty
	mov	ax,cx					;new token
	xchg	ax,ds:[di].GOI_areaAttrToken
	cmp	cx, ax					;check diff
	je	done
	call	GrObjAddRefGrObjAreaToken
	xchg	cx,ax					;cx <- old token
							;ax <- new
	call	GrObjDerefGrObjAreaToken

	call	GrObjAttrInvalidateAndSendAreaUINotification

done:
	.leave
	ret

returnToBaseStyle:
	;
	;	Retrieve our style token
	;
	mov	cx,ds:[di].GOI_areaAttrToken
	sub	sp, size GrObjFullAreaAttrElement
	mov	bp, sp
	mov	ax, MSG_GOAM_GET_FULL_AREA_ATTR_ELEMENT
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM
	mov	cx, ss:[bp].GOFAAE_base.GOBAAE_styleElement.SSEH_style
	add	sp, size GrObjFullAreaAttrElement

	;
	;	Get the base area attribute from the style token
	;
	mov	ax, MSG_GOAM_GET_AREA_AND_LINE_TOKENS_FROM_STYLE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM
	jc	done

	;
	;	Apply the base attr
	;
	mov_tr	cx, ax					;cx <- base area token
	mov	ax, MSG_GO_SET_GROBJ_AREA_TOKEN
	call	ObjCallInstanceNoLock
	jmp	done
GrObjSetGrObjAreaToken		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetGrObjLineToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the line attribute token of the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cx - line token

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
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetGrObjLineToken	method extern dynamic GrObjClass, 
					MSG_GO_SET_GROBJ_LINE_TOKEN
	uses	cx,dx,bp
	.enter

	cmp	cx, CA_NULL_ELEMENT
	je	returnToBaseStyle

	call	GrObjAttrGenerateUndoLineAttrChangeChain

	call	ObjMarkDirty
	mov	ax,cx					;new token
	xchg	ax,ds:[di].GOI_lineAttrToken
	cmp	cx, ax					;check diff
	je	done
	call	GrObjAddRefGrObjLineToken
	xchg	cx,ax					;ax <- new token
							;cx <- old token
	call	GrObjDerefGrObjLineToken

	call	GrObjAttrInvalidateAndSendLineUINotification

done:
	.leave
	ret

returnToBaseStyle:
	;
	;	Retrieve our style token
	;
	mov	cx,ds:[di].GOI_lineAttrToken
	sub	sp, size GrObjFullLineAttrElement
	mov	bp, sp
	mov	ax, MSG_GOAM_GET_FULL_LINE_ATTR_ELEMENT
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM
	mov	cx, ss:[bp].GOFLAE_base.GOBLAE_styleElement.SSEH_style
	add	sp, size GrObjFullLineAttrElement

	;
	;	Get the base area attribute from the style token
	;
	mov	ax, MSG_GOAM_GET_AREA_AND_LINE_TOKENS_FROM_STYLE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM
	jc	done

	;
	;	Apply the base attr
	;
	mov	cx, dx					;cx <- base line token
	mov	ax, MSG_GO_SET_GROBJ_LINE_TOKEN
	call	ObjCallInstanceNoLock
	jmp	done
GrObjSetGrObjLineToken		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDerefAGrObjAreaToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement the reference count for the passed area token


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		cx - area token

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDerefAGrObjAreaToken	method extern dynamic GrObjClass,
					 MSG_GO_DEREF_A_GROBJ_AREA_TOKEN
	.enter

	call	GrObjDerefGrObjAreaToken

	.leave
	ret
GrObjDerefAGrObjAreaToken		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDerefAGrObjLineToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement the reference count for the passed line token


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		cx - line token

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDerefAGrObjLineToken	method extern dynamic GrObjClass,
						 MSG_GO_DEREF_A_GROBJ_LINE_TOKEN
	.enter

	call	GrObjDerefGrObjLineToken

	.leave
	ret
GrObjDerefAGrObjLineToken		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjSubstAreaToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_SUBST_AREA_TOKEN

		If object's area token matches the passed "old" token,
		replace it with the new token, and update the reference
		counts if specified

Called by:	

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		cx - old token
		dx - new token
		bp - nonzero to update reference counts

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSubstAreaToken method extern dynamic GrObjClass, MSG_GO_SUBST_AREA_TOKEN
	.enter

	;
	;	Check for the old token
	;
	cmp	cx, ds:[di].GOI_areaAttrToken
	jne	done

	;
	;	Check if we're supposed to update ref counts
	;
	tst	bp
	jz	noRefs

	;
	;	Send ourselves a MSG_GO_SET_GROBJ_AREA_TOKEN,
	;	which will update the references...
	;
	xchg	cx, dx						;cx <- new
								;dx <- old
	mov	ax, MSG_GO_SET_GROBJ_AREA_TOKEN
	call	ObjCallInstanceNoLock
	xchg	cx, dx						;cx <- old
								;dx <- new
done:
	.leave
	ret

	;
	;	Update the tokens without updating the refs
	;
noRefs:
	mov	ds:[di].GOI_areaAttrToken, dx
	call	GrObjAttrInvalidateAndSendAreaUINotification
	call	ObjMarkDirty
	jmp	done
GrObjSubstAreaToken	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjSubstLineToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObj method for MSG_GO_SUBST_LINE_TOKEN

		If object's line token matches the passed "old" token,
		replace it with the new token, and update the reference
		counts if specified

Called by:	

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		cx - old token
		dx - new token
		bp - nonzero to update reference counts

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSubstLineToken method extern dynamic GrObjClass, MSG_GO_SUBST_LINE_TOKEN
	.enter

	;
	;	Check for the old token
	;
	cmp	cx, ds:[di].GOI_lineAttrToken
	jne	done

	;
	;	Check if we're supposed to update ref counts
	;
	tst	bp
	jz	noRefs

	;
	;	Send ourselves a MSG_GO_SET_GROBJ_LINE_TOKEN,
	;	which will update the references...
	;
	xchg	cx, dx						;cx <- new
								;dx <- old
	mov	ax, MSG_GO_SET_GROBJ_LINE_TOKEN
	call	ObjCallInstanceNoLock
	xchg	cx, dx						;cx <- old
								;dx <- new
done:
	.leave
	ret

	;
	;	Update the tokens without updating the refs
	;
noRefs:
	mov	ds:[di].GOI_lineAttrToken, dx
	call	GrObjAttrInvalidateAndSendLineUINotification
	call	ObjMarkDirty
	jmp	done
GrObjSubstLineToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCanChangeAttributes?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object can have its attributes changed

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - GrObj

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			object can have its attributes changed

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCanChangeAttributes?		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_locks, mask GOL_ATTRIBUTE
	jnz	done

	stc

done:
	.leave
	ret

GrObjCanChangeAttributes?		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetAreaColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the area color for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - r
		ch - g
		dl - b

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetAreaColor method extern dynamic GrObjClass, MSG_GO_SET_AREA_COLOR
	.enter

	mov_tr	ax,cx					;r,g
	mov	bx, offset GOBAAE_r
	mov	di,AREA_ATTR_COLOR_SIZE
	call	GrObjChangeAreaAttrCommon

	.leave
	ret
GrObjSetAreaColor		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetAreaMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the area mask for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - SystemDrawMask

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetAreaMask method extern dynamic GrObjClass, MSG_GO_SET_AREA_MASK
	.enter

	mov	al,cl					;SystemDrawMask

	; Check to see if we are attempting to set the area mask
	; for an object with text inside of it.  If so, override it
	; to unfilled (0%).  This is sort of a hack since it easier to
	; do this then to disallow the user to modify the setting in the
	; first place.  --JimG 8/31/99
	;
	mov	bx, ds:[di].GOI_attrFlags
	andnf	bx, mask GOAF_WRAP
	cmp	bx, GOWTT_WRAP_INSIDE shl offset GOAF_WRAP
	je	specialWrapInside

doIt:
	mov	bx, offset GOBAAE_mask
	mov	di,AREA_ATTR_MASK_SIZE
	call	GrObjChangeAreaAttrCommon

	.leave
	ret

specialWrapInside:
	mov	al, SDM_0
	jmp	doIt
GrObjSetAreaMask		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetAreaDrawMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the area draw mode for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - MixMode

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetAreaDrawMode method extern dynamic GrObjClass,
						MSG_GO_SET_AREA_DRAW_MODE
	.enter

	mov	al,cl					;MixMode
	mov	bx, offset GOBAAE_drawMode
	mov	di,AREA_ATTR_DRAW_MODE_SIZE
	call	GrObjChangeAreaAttrCommon

	.leave
	ret
GrObjSetAreaDrawMode		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetAreaPattern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the area pattern for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cx - GraphicPattern

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetAreaPattern method extern dynamic GrObjClass, MSG_GO_SET_AREA_PATTERN
	.enter

	mov	ax,cx					;GraphicPattern
	mov	bx, offset GOBAAE_pattern
	mov	di,AREA_ATTR_PATTERN_SIZE
	call	GrObjChangeAreaAttrCommon

	.leave
	ret
GrObjSetAreaPattern		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetAreaAttrElementType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the area element type for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - GrObjAreaAttrElementType

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetAreaAttrElementType method extern dynamic GrObjClass, 
			MSG_GO_SET_AREA_ATTR_ELEMENT_TYPE

	uses	cx, dx
	.enter

	push	cx
	mov	cx, ds:[di].GOI_areaAttrToken
	sub	sp,size GrObjFullAreaAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullAreaAttrElement
	mov	al, ss:[bp].GOBAAE_aaeType
	mov	bl, ss:[bp].GOBAAE_backR
	mov	bh, ss:[bp].GOBAAE_backG
	mov	dl, ss:[bp].GOBAAE_backB
	add	sp, size GrObjFullAreaAttrElement
	pop	cx

	cmp	al, cl
	je	done

	push	bx				;save backR, backG
	mov	al,cl
	mov	bx, offset GOBAAE_aaeType
	mov	di,AREA_ATTR_TYPE_SIZE
	call	GrObjChangeAreaAttrCommon
	jnc	popCXDone			; => couldn't change, so
						;  don't do gradient stuff

	cmp	cl, GOAAET_GRADIENT
	pop	cx				;cl <- backR, ch <- backG
	jne	done

	mov	ax, MSG_GO_SET_ENDING_GRADIENT_COLOR
	call	ObjCallInstanceNoLock

	mov	cl, DEFAULT_GRADIENT_TYPE
	mov	ax, MSG_GO_SET_GRADIENT_TYPE
	call	ObjCallInstanceNoLock

	mov	cx, DEFAULT_NUMBER_OF_GRADIENT_INTERVALS
	mov	ax, MSG_GO_SET_NUMBER_OF_GRADIENT_INTERVALS
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

popCXDone:
	pop	cx
	jmp	done
GrObjSetAreaAttrElementType		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjChangeAreaAttrCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for changing most area attributes

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - object
		ax,dx - new data
		bx - offset to field to change
		di - size of data to change

RETURN:		
		carry set if attributes changed
		carry clear if attributes may not be changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 7/92   	Initial version
	ardeb	11/29/93	Changed to return carry to cope with gradient
				fill change on attribute-locked object (was
				recursing endlessly as GrObjSetAreaAttrElement-
				Type kept trying to call SET_ENDING_GRADIENT_-
				COLOR, which would again attempt to set the
				thing to GOAAET_GRADIENT and fail...)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjChangeAreaAttrCommon		proc	far
	class	GrObjClass
	uses	cx,bp
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	GrObjCanChangeAttributes?
	jnc	done

	call	GrObjAttrGenerateUndoAreaAttrChangeChain

	GrObjDeref	bp,ds,si
	mov	cx,ds:[bp].GOI_areaAttrToken
	call	GrObjChangeGrObjBaseAreaAttrElementField
	GrObjDeref	di,ds,si
	mov	ds:[di].GOI_areaAttrToken,cx

	;    Invalidate the object so that it will draw with its
	;    new attributes
	;

	call	GrObjAttrInvalidateAndSendAreaUINotification

	call	ObjMarkDirty
	stc
done:
	.leave
	ret
GrObjChangeAreaAttrCommon		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetTransparency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the transparenccy info for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - nonzero if true

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetTransparency	method extern dynamic GrObjClass, 
						MSG_GO_SET_TRANSPARENCY
	uses	ax,cx
	.enter

	call	GrObjCanChangeAttributes?
	jnc	done

	call	GrObjAttrGenerateUndoAreaAttrChangeChain

	mov	ah,mask GOAAIR_TRANSPARENT		;always reset
	mov	al,ah					;assume true
	tst	cl
	jnz	set
	clr	al					;set nothing
set:
	mov	cx,ds:[di].GOI_areaAttrToken
	mov	bx, offset GOBAAE_areaInfo
	call	GrObjChangeGrObjBaseAreaAttrElementByteRecord
	GrObjDeref	di,ds,si
	mov	ds:[di].GOI_areaAttrToken,cx

	;    Invalidate the object so that it will draw with its
	;    new attributes
	;

	call	GrObjAttrInvalidateAndSendAreaUINotification

	call	ObjMarkDirty
done:
	.leave
	ret
GrObjSetTransparency		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetAreaAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set rectangles area attributes

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - GrObjBaseAreaAttrElement

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetAreaAttr	method extern dynamic GrObjClass, 
							MSG_GO_SET_AREA_ATTR
	uses	ax,cx
	.enter

EC <	push	ds						>
EC <	segmov	ds,ss						>
EC <	call	GrObjCheckGrObjBaseAreaAttrElement			>	
EC <	pop	ds						>

	call	GrObjCanChangeAttributes?
	jnc	done

	call	GrObjAttrGenerateUndoAreaAttrChangeChain

	mov	cx,ds:[di].GOI_areaAttrToken
	call	GrObjDerefGrObjAreaToken
	call	GrObjAddGrObjFullAreaAttrElement
	mov	ds:[di].GOI_areaAttrToken,ax

	;    Invalidate the object so that it will draw with its
	;    new attributes
	;

	call	GrObjAttrInvalidateAndSendAreaUINotification

	call	ObjMarkDirty
done:
	.leave
	ret
GrObjSetAreaAttr		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetLineColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the line color for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - r
		ch - g
		dl - b

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetLineColor	method extern dynamic GrObjClass, 
							MSG_GO_SET_LINE_COLOR
	.enter

	mov_tr	ax,cx					;r,g
	mov	bx, offset GOBLAE_r
	mov	di,LINE_ATTR_COLOR_SIZE
	call	GrObjChangeLineAttrCommon

	.leave
	ret
GrObjSetLineColor		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetLineMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the line mask for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - SystemDrawMask

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetLineMask	method extern dynamic GrObjClass, 
							MSG_GO_SET_LINE_MASK
	.enter

	;   We calc the PARENT dimensions on changing the line mask
	;   because if the mask goes from zero to non zero then
	;   the line width actually gets used.
	;

	mov	al,cl					;SystemDrawMask
	mov	bx, offset GOBLAE_mask
	mov	di,LINE_ATTR_MASK_SIZE
	call	GrObjChangeLineAttrCommonAndCalcPARENT

	.leave
	ret
GrObjSetLineMask		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetLineJoin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the line join for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - LineJoin

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetLineJoin	method extern dynamic GrObjClass, 
							MSG_GO_SET_LINE_JOIN
	.enter

	mov	al,cl					;DrawJoins
	mov	bx, offset GOBLAE_join
	mov	di,LINE_ATTR_JOIN_SIZE
	call	GrObjChangeLineAttrCommon

	.leave
	ret
GrObjSetLineJoin		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetLineEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the line end for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - LineEnd

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetLineEnd	method extern dynamic GrObjClass, MSG_GO_SET_LINE_END
	.enter

	mov	al,cl					;DrawEnds
	mov	bx, offset GOBLAE_end
	mov	di,LINE_ATTR_END_SIZE
	call	GrObjChangeLineAttrCommon

	.leave
	ret
GrObjSetLineEnd		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetLineStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the line style for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - LineStyle

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetLineStyle	method extern dynamic GrObjClass, 
							MSG_GO_SET_LINE_STYLE
	.enter

	mov	al,cl					;DrawStyles
	mov	bx, offset GOBLAE_style
	mov	di,LINE_ATTR_STYLE_SIZE
	call	GrObjChangeLineAttrCommon

	.leave
	ret
GrObjSetLineStyle		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetLineWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the line width for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		dx:cx - WWFixed line width

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetLineWidth	method extern dynamic GrObjClass, 
							MSG_GO_SET_LINE_WIDTH
	.enter

EC <	tst	dx						>
EC <	ERROR_S GROBJ_BUMMER_YOUVE_GOT_A_NEGATIVE_LINE_WIDTH____GET_STEVE_NOW

	mov_tr	ax,cx					;width frac
	mov	bx, offset GOBLAE_width
	mov	di,LINE_ATTR_WIDTH_SIZE
	call	GrObjChangeLineAttrCommonAndCalcPARENT

	.leave
	ret
GrObjSetLineWidth		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetLineMiterLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the line miter limit for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		dx:cx - WWFixed line miter limit

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetLineMiterLimit	method extern dynamic GrObjClass, 
						MSG_GO_SET_LINE_MITER_LIMIT
	.enter

	mov_tr	ax,cx					;miter limit frac
	mov	bx, offset GOBLAE_miterLimit
	mov	di,LINE_ATTR_MITER_LIMIT_SIZE
	call	GrObjChangeLineAttrCommon

	.leave
	ret
GrObjSetLineMiterLimit		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetLineAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set rectangles line attributes

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - GrObjBaseLineAttrElement

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetLineAttr	method extern dynamic GrObjClass, 
							MSG_GO_SET_LINE_ATTR
	uses	ax,cx
	.enter

EC <	push	ds						>
EC <	segmov	ds,ss						>
EC <	call	GrObjCheckGrObjBaseLineAttrElement			>	
EC <	pop	ds						>

	call	GrObjCanChangeAttributes?
	jnc	done

	call	GrObjAttrGenerateUndoLineAttrChangeChain

	;    Invalidate at the original line width incase the line
	;    width gets smaller
	;

	mov	ax,MSG_GO_INVALIDATE_LINE
	call	ObjCallInstanceNoLock

	movnf	cx, CA_NULL_ELEMENT
	xchg	cx,ds:[di].GOI_lineAttrToken
	call	GrObjDerefGrObjLineToken
	call	GrObjAddGrObjFullLineAttrElement
	mov	ds:[di].GOI_lineAttrToken,ax

	;    Adjust for any change in line width
	;

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	;    Invalidate the object so that it will draw with its
	;    new attributes
	;

	call	GrObjAttrInvalidateAndSendLineUINotification

	call	ObjMarkDirty
done:
	.leave
	ret
GrObjSetLineAttr		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetLineAttrElementType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the line element type for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - GrObjLineAttrElementType

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetLineAttrElementType method extern dynamic GrObjClass, 
			MSG_GO_SET_LINE_ATTR_ELEMENT_TYPE
	.enter

	mov	al,cl					
	mov	bx, offset GOBLAE_laeType
	mov	di,LINE_ATTR_TYPE_SIZE
	call	GrObjChangeLineAttrCommon

	.leave
	ret
GrObjSetLineAttrElementType		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetArrowheadLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the length of the arrow head branches

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - arrowhead length

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetArrowheadLength method extern dynamic GrObjClass, 
			MSG_GO_SET_ARROWHEAD_LENGTH
	.enter

	mov	al,cl					;length
	mov	bx, offset GOBLAE_arrowheadLength
	mov	di,size GOBLAE_arrowheadLength
	call	GrObjChangeLineAttrCommonAndCalcPARENT

	.leave
	ret
GrObjSetArrowheadLength		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetArrowheadAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the arrowhead deflection angle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - arrowhead deflection angle

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetArrowheadAngle method extern dynamic GrObjClass, 
			MSG_GO_SET_ARROWHEAD_ANGLE
	.enter

	mov	al,cl					;angle
	mov	bx, offset GOBLAE_arrowheadAngle
	mov	di,size GOBLAE_arrowheadAngle
	call	GrObjChangeLineAttrCommonAndCalcPARENT

	.leave
	ret
GrObjSetArrowheadAngle		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjChangeLineAttrCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for changing most line attributes

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - object
		ax,dx - new data
		bx - offset to field to change
		di - size of data to change

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED
		
		This routine should probably return carry set/clear like
			GrObjChangeAreaAttrCommon, for consistency sake.
			The area attribute one was changed 11/29/93 by Adam
			to keep from endless recursion when gradient fill
			is enabled for an object with an attribute lock set.

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 7/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjChangeLineAttrCommon		proc	far
	class	GrObjClass
	uses	cx,bp
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	GrObjCanChangeAttributes?
	jnc	done

	call	GrObjAttrGenerateUndoLineAttrChangeChain

	GrObjDeref	bp,ds,si
	mov	cx,ds:[bp].GOI_lineAttrToken
	call	GrObjChangeGrObjBaseLineAttrElementField
	GrObjDeref	di,ds,si
	mov	ds:[di].GOI_lineAttrToken,cx

	;    Invalidate the object so that it will draw with its
	;    new attributes
	;

	call	GrObjAttrInvalidateAndSendLineUINotification

	call	ObjMarkDirty
done:
	.leave
	ret
GrObjChangeLineAttrCommon		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjChangeLineAttrCommonAndCalcPARENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for changing most line attributes
		the require a recalc of the parent bounds

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - object
		ax,dx - new data
		bx - offset to field to change
		di - size of data to change

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 7/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjChangeLineAttrCommonAndCalcPARENT		proc	far
	class	GrObjClass
	uses	cx,bp
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	GrObjCanChangeAttributes?
	jnc	done

	call	GrObjAttrGenerateUndoLineAttrChangeChain

	GrObjDeref	bp,ds,si
	mov	cx,ds:[bp].GOI_lineAttrToken
	call	GrObjChangeGrObjBaseLineAttrElementField
	GrObjDeref	di,ds,si
	mov	ds:[di].GOI_lineAttrToken,cx

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	;    Invalidate the object so that it will draw with its
	;    new attributes
	;

	call	GrObjAttrInvalidateAndSendLineUINotification

	call	ObjMarkDirty
done:
	.leave
	ret
GrObjChangeLineAttrCommonAndCalcPARENT		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetArrowheadOnStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the arrowhead on start for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - nonzero if true

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetArrowheadOnStart	method extern dynamic GrObjClass, 
					MSG_GO_SET_ARROWHEAD_ON_START
	uses	ax,cx
	.enter

	call	GrObjCanChangeAttributes?
	jnc	done

	call	GrObjAttrGenerateUndoLineAttrChangeChain

	mov	ah,mask GOLAIR_ARROWHEAD_ON_START	;always reset
	mov	al,ah					;assume true
	tst	cl
	jnz	set
	clr	al					;set nothing
set:
	mov	cx,ds:[di].GOI_lineAttrToken
	mov	bx, offset GOBLAE_lineInfo
	call	GrObjChangeGrObjBaseLineAttrElementByteRecord
	GrObjDeref	di,ds,si
	mov	ds:[di].GOI_lineAttrToken,cx

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	;    Invalidate the object so that it will draw with its
	;    new attributes
	;

	call	GrObjAttrInvalidateAndSendLineUINotification
done:
	.leave
	ret
GrObjSetArrowheadOnStart		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetArrowheadOnEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the arrowhead on start for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - nonzero if true

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetArrowheadOnEnd	method extern dynamic GrObjClass, 
					MSG_GO_SET_ARROWHEAD_ON_END
	uses	ax,cx
	.enter

	call	GrObjCanChangeAttributes?
	jnc	done

	call	GrObjAttrGenerateUndoLineAttrChangeChain

	mov	ah,mask GOLAIR_ARROWHEAD_ON_END	;always reset
	mov	al,ah					;assume true
	tst	cl
	jnz	set
	clr	al					;set nothing
set:
	mov	cx,ds:[di].GOI_lineAttrToken
	mov	bx, offset GOBLAE_lineInfo
	call	GrObjChangeGrObjBaseLineAttrElementByteRecord
	GrObjDeref	di,ds,si
	mov	ds:[di].GOI_lineAttrToken,cx


	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	;    Invalidate the object so that it will draw with its
	;    new attributes
	;

	call	GrObjAttrInvalidateAndSendLineUINotification

	call	ObjMarkDirty
done:
	.leave
	ret
GrObjSetArrowheadOnEnd		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetArrowheadFilled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the arrowhead on start for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - nonzero if true
		ch - nonzero to fill with area attributes,
		     zero to fill with line attributes

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetArrowheadFilled	method extern dynamic GrObjClass, 
					MSG_GO_SET_ARROWHEAD_FILLED
	uses	ax,cx
	.enter

	call	GrObjCanChangeAttributes?
	jnc	done

	call	GrObjAttrGenerateUndoLineAttrChangeChain

	mov	ax, (mask GOLAIR_ARROWHEAD_FILLED or \
		    mask GOLAIR_ARROWHEAD_FILL_WITH_AREA_ATTRIBUTES) shl 8 or \
		    (mask GOLAIR_ARROWHEAD_FILLED or \
		    mask GOLAIR_ARROWHEAD_FILL_WITH_AREA_ATTRIBUTES)
	tst	cl
	jnz	checkAreaFill
	BitClr	al, GOLAIR_ARROWHEAD_FILLED

checkAreaFill:
	tst	ch
	jnz	set
	BitClr	al, GOLAIR_ARROWHEAD_FILL_WITH_AREA_ATTRIBUTES
set:
	mov	cx,ds:[di].GOI_lineAttrToken
	mov	bx, offset GOBLAE_lineInfo
	call	GrObjChangeGrObjBaseLineAttrElementByteRecord
	GrObjDeref	di,ds,si
	mov	ds:[di].GOI_lineAttrToken,cx

	;    Invalidate the object so that it will draw with its
	;    new attributes
	;

	call	GrObjAttrInvalidateAndSendLineUINotification

	call	ObjMarkDirty
done:
	.leave
	ret
GrObjSetArrowheadFilled		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetBGColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the background color for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - r
		ch - g
		dl - b

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetBGColor	method extern dynamic GrObjClass, MSG_GO_SET_BG_COLOR
	.enter

	mov_tr	ax,cx					;r,g
	mov	bx, offset GOBAAE_backR
	mov	di,AREA_ATTR_COLOR_SIZE
	call	GrObjChangeAreaAttrCommon

	.leave
	ret
GrObjSetBGColor		endp


GrObjAttributesCode	ends



GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyAttributesToGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply the area and line attributes to
		the passed gstate

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		bp - gstate
RETURN:		

		bp - gstate with attributes applied
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjApplyAttributesToGState	method extern dynamic GrObjClass,
					 MSG_GO_APPLY_ATTRIBUTES_TO_GSTATE
	.enter

	xchg	di,bp				;gstate, instance offset
	mov	cx,ds:[bp].GOI_areaAttrToken
	call	GrObjApplyGrObjAreaToken
	mov	cx,ds:[bp].GOI_lineAttrToken
	call	GrObjApplyGrObjLineToken
	mov	bp,di				;gstate	

	.leave
	ret
GrObjApplyAttributesToGState		endp

GrObjDrawCode	ends


GrObjSpecialGraphicsCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetStartingGradientColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the staring gradient area color for the object
		which is stored in the normal area color location

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - r
		ch - g
		dl - b

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetStartingGradientColor method extern dynamic GrObjClass, 
				MSG_GO_SET_STARTING_GRADIENT_COLOR
	.enter

	push	cx
	mov	cl, GOAAET_GRADIENT
	mov	ax, MSG_GO_SET_AREA_ATTR_ELEMENT_TYPE
	call	ObjCallInstanceNoLock

	pop	ax					;r,g
	mov	bx, offset GOBAAE_r
	mov	di,AREA_ATTR_COLOR_SIZE
	call	GrObjChangeAreaAttrCommon

	.leave
	ret
GrObjSetStartingGradientColor		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetEndingGradientColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the ending gradient area color for the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - r
		ch - g
		dl - b

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetEndingGradientColor method extern dynamic GrObjClass, 
				MSG_GO_SET_ENDING_GRADIENT_COLOR
	.enter

	push	cx
	mov	cl, GOAAET_GRADIENT
	mov	ax, MSG_GO_SET_AREA_ATTR_ELEMENT_TYPE
	call	ObjCallInstanceNoLock

	pop	ax					;r,g
	mov	bx, offset GOGAAE_endR
	mov	di,AREA_ATTR_COLOR_SIZE
	call	GrObjChangeAreaAttrCommon

	.leave
	ret
GrObjSetEndingGradientColor		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetNumberOfGradientIntervals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the number of gradient intervals

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cx - number of intervals

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetNumberOfGradientIntervals method extern dynamic GrObjClass, 
				MSG_GO_SET_NUMBER_OF_GRADIENT_INTERVALS
	.enter

	push	cx
	mov	cl, GOAAET_GRADIENT
	mov	ax, MSG_GO_SET_AREA_ATTR_ELEMENT_TYPE
	call	ObjCallInstanceNoLock

	pop	ax					;num intervals
	mov	bx, offset GOGAAE_numIntervals
	mov	di,size GOGAAE_numIntervals
	call	GrObjChangeAreaAttrCommon

	.leave
	ret
GrObjSetNumberOfGradientIntervals		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetGradientType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the  gradient type

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
				
		cl - GrObjGradientType

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetGradientType method extern dynamic GrObjClass, 
				MSG_GO_SET_GRADIENT_TYPE
	.enter

	push	cx
	mov	cl, GOAAET_GRADIENT
	mov	ax, MSG_GO_SET_AREA_ATTR_ELEMENT_TYPE
	call	ObjCallInstanceNoLock

	pop	ax					;gradient type
	mov	bx, offset GOGAAE_type
	mov	di,size GOGAAE_type
	call	GrObjChangeAreaAttrCommon

	.leave
	ret
GrObjSetGradientType		endp


GrObjSpecialGraphicsCode	ends
