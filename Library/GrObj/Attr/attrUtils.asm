COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Admin
FILE:		objectAttrUtils..asm

AUTHOR:		Steve Scholl, Nov 15, 1991

ROUTINES:
	Name			
	----			
GrObjAttrGenerateUndoAreaAttrChangeChain
GrObjAttrGenerateUndoLineAttrChangeChain
GrObjAttrInvalidateAndSendAreaUINotification
GrObjAttrInvalidateAndSendLineUINotification
GrObjAttrInvalidateAndSendUINotification
GrObjChangeGrObjBaseAreaAttrElementField	
GrObjChangeGrObjBaseAreaAttrElementByteRecord
GrObjChangeGrObjBaseLineAttrElementField	
GrObjGetAreaInfoAndMask	
GrObjGetAreaColor
GrObjGetLineColor
GrObjGetAreaInfoAndMask	
GrObjGetLineWidth		
GrObjApplyGrObjFullAreaAttrElement
GrObjApplyGrObjFullLineAttrElement
GrObjApplyBackgroundAttrs	
GrObjApplyGrObjLineToken
GrObjApplyGrObjAreaToken
GrObjAddGrObjFullAreaAttrElement
GrObjAddGrObjFullLineAttrElement
GrObjDerefGrObjLineToken
GrObjDerefGrObjAreaToken
GrObjAddRefGrObjLineToken
GrObjAddRefGrObjAreaToken
GrObjGetGrObjFullAreaAttrElement
GrObjGetGrObjFullLineAttrElement
GrObjDetermineAreaAttributeDataSize
GrObjDetermineLineAttributeDataSize

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/91	Initial revision


DESCRIPTION:

	$Id: attrUtils.asm,v 1.1 97/04/04 18:07:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrObjAttributesCode	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttrGenerateUndoAreaAttrChangeChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain to undo the impending area attribute
		change

CALLED BY:	INTERNAL  UTILITY

PASS:		
		*ds:si - object

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		Increment the reference count of the current area token
		so that it won't be thrown away.

		Create undo chain that will do
			on undo - set back to current token
			on free - deref the token

		Since we are guaranteed that the undo action will eventually be
		freed, even if the operation is undone, the increment
		of the reference count will be balanced by a decrement.

		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttrGenerateUndoAreaAttrChangeChain		proc	far
	class	GrObjClass
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>
	
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags,mask GOOF_ATTRIBUTE_MANAGER
	jnz	done

	;    If we don't exit when element is null we could get 
	;    an undo that caused us to send SET_GROB_AREA_TOKEN
	;    with FFFFH as the token to ourselves. This causes
	;    revert to base style. Bad news.
	;

	mov	cx,ds:[di].GOI_areaAttrToken
	cmp	cx,CA_NULL_ELEMENT
	je	done

	call	GenProcessUndoCheckIfIgnoring
	tst	ax
	jnz	done

	call	GrObjAddRefGrObjAreaToken

	mov_tr	ax,cx					;area token
	mov	cx,handle areaAttrString
	mov	dx,offset areaAttrString
	call	GrObjGlobalStartUndoChain
	mov_tr	cx,ax					;area token

	mov	ax,MSG_GO_SET_GROBJ_AREA_TOKEN		;undo message
	mov	di,MSG_GO_DEREF_A_GROBJ_AREA_TOKEN	;free message
	mov	bx,mask AUAF_NOTIFY_BEFORE_FREEING	;AddUndoActionFlags
	call	GrObjGlobalAddFlagsUndoAction

	call	GrObjGlobalEndUndoChain

done:
	.leave
	ret
GrObjAttrGenerateUndoAreaAttrChangeChain		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttrGenerateUndoLineAttrChangeChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain to undo the impending line attribute
		change

CALLED BY:	INTERNAL  UTILITY

PASS:		
		*ds:si - object

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		Increment the reference count of the current line token
		so that it won't be thrown away.

		Create undo chain that will do
			on undo - set back to current token
			on free - deref the token

		Since we are guaranteed that the undo action will eventually be
		freed, even if the operation is undone, the increment
		of the reference count will be balanced by a decrement.

		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttrGenerateUndoLineAttrChangeChain		proc	far
	class	GrObjClass
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>
	
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags,mask GOOF_ATTRIBUTE_MANAGER
	jnz	done

	;    If we don't exit when element is null we could get 
	;    an undo that caused us to send SET_GROB_LINE_TOKEN
	;    with FFFFH as the token to ourselves. This causes
	;    revert to base style. Bad news.
	;

	mov	cx,ds:[di].GOI_lineAttrToken
	cmp	cx,CA_NULL_ELEMENT
	je	done

	call	GenProcessUndoCheckIfIgnoring
	tst	ax
	jnz	done

	call	GrObjAddRefGrObjLineToken

	mov_tr	ax,cx					;line token
	mov	cx,handle lineAttrString
	mov	dx,offset lineAttrString
	call	GrObjGlobalStartUndoChain
	mov_tr	cx,ax					;line token

	mov	ax,MSG_GO_SET_GROBJ_LINE_TOKEN		;undo message
	mov	di,MSG_GO_DEREF_A_GROBJ_LINE_TOKEN	;free message
	mov	bx,mask AUAF_NOTIFY_BEFORE_FREEING	;AddUndoActionFlags
	call	GrObjGlobalAddFlagsUndoAction

	call	GrObjGlobalEndUndoChain

done:
	.leave
	ret
GrObjAttrGenerateUndoLineAttrChangeChain		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttrInvalidateAndSendAreaUINotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the grobject and initiate an update of
		the area ui controllers

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - grobject

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
	srs	3/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttrInvalidateAndSendAreaUINotification		proc	far
	uses	cx
	.enter

	call	GrObjOptInvalidateArea

	mov	cx, mask GOUINT_AREA
	call	GrObjAttrInvalidateAndSendUINotification

	.leave
	ret
GrObjAttrInvalidateAndSendAreaUINotification		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttrInvalidateAndSendLineUINotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the grobject and initiate an update of
		the line ui controllers

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - grobject

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttrInvalidateAndSendLineUINotification		proc	far
	uses	cx
	.enter

	call	GrObjOptInvalidateLine

	mov	cx, mask GOUINT_LINE
	call	GrObjAttrInvalidateAndSendUINotification

	.leave
	ret
GrObjAttrInvalidateAndSendLineUINotification		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttrInvalidateAndSendUINotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the grobject and initiate an update of
		the ui controllers

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - grobject
		ax - invalidate message
		cx - GrObjUINotificationTypes

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttrInvalidateAndSendUINotification		proc	near
	uses	ax,bp
	.enter

	call	GrObjOptSendUINotification

	mov	bp,GOANT_ATTRED
	call	GrObjOptNotifyAction

	.leave
	ret
GrObjAttrInvalidateAndSendUINotification		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOptInvalidateArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	InvalidateArea the object taking into account the
		GrObjMessageOptimizationFlags

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - grobject

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			opt bit not set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOptInvalidateArea		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_msgOptFlags, mask GOMOF_INVALIDATE_AREA
	jnz	send

	call	GrObjInvalidate

done:
	.leave
	ret

send:
	push	ax
	mov	ax,MSG_GO_INVALIDATE_AREA
	call	ObjCallInstanceNoLock
	pop	ax
	jmp	done

GrObjOptInvalidateArea		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOptInvalidateLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	InvalidateLine the object taking into account the
		GrObjMessageOptimizationFlags

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - grobject

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			opt bit not set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOptInvalidateLine		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_msgOptFlags, mask GOMOF_INVALIDATE_LINE
	jnz	send

	call	GrObjInvalidate

done:
	.leave
	ret

send:
	push	ax
	mov	ax,MSG_GO_INVALIDATE_LINE
	call	ObjCallInstanceNoLock
	pop	ax
	jmp	done

GrObjOptInvalidateLine		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjChangeGrObjBaseAreaAttrElementField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove reference to passed index and add new reference
		for same data with one field changed.


CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - object
		cx - index
		dx:ax - new field data
		bx - offset in GrObjBaseAreaAttrElement to field
		di - field size in bytes
			1 byte - al
			2 bytes - ax
			3 bytes - dl,ax
			4 bytes - dx,ax


RETURN:		
		cx - new element number

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		If unable to get the current attributes, just punt
		and return the original index.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjChangeGrObjBaseAreaAttrElementField		proc	far
	uses	ax,bp,di,es
	.enter

	;    Get the current attributes and then remove our
	;    reference to them
	;

	sub	sp,size GrObjFullAreaAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullAreaAttrElement
	jnc	clearFrame
	call	GrObjDerefGrObjAreaToken

	;    Copy the new data into the attribute structure
	;

	mov	cx,di					;number of bytes
	segmov	es,ss					;dest segment
	mov	di,bp					;frame offset
	add	di,bx					;field offset
	stosb
	dec	cx
	jcxz	addElement
	mov	al,ah
	stosb
	dec	cx
	jcxz	addElement
	mov	al,dl
	stosb
	dec	cx
	jcxz	addElement
	mov	al,dh
	stosb
	
addElement:
	;    Add the new element to the attribute arrays
	;

	call	GrObjAddGrObjFullAreaAttrElement
	mov	cx,ax					;new token

clearFrame:
	add	sp, size GrObjFullAreaAttrElement
	.leave
	ret
GrObjChangeGrObjBaseAreaAttrElementField		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjChangeGrObjBaseAreaAttrElementByteRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove reference to passed index and add new reference
		for same data with one field changed.


CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - object
		cx - index
		al - bits to set
		ah - bits to reset
		bx - offset in GrObjBaseAreaAttrElement to byte record


RETURN:		
		cx - new element number

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		If unable to get the current attributes, just punt
		and return the original index.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjChangeGrObjBaseAreaAttrElementByteRecord		proc	far
	uses	ax,bp,di
	.enter

	;    Get the current attributes and then remove our
	;    reference to them
	;

	sub	sp,size GrObjFullAreaAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullAreaAttrElement
	jnc	clearFrame
	call	GrObjDerefGrObjAreaToken

	;    Copy the new data into the attribute structure
	;

	mov	di,bx
	mov	cl,ss:[bp][di]
	not	ah					;make bits to reset 0's
	andnf	cl,ah					;reset bits
	ornf	cl,al					;set bits
	mov	ss:[bp][di],cl

	;    Add the new element to the attribute arrays
	;

	call	GrObjAddGrObjFullAreaAttrElement
	mov	cx,ax					;new token

clearFrame:
	add	sp, size GrObjFullAreaAttrElement
	.leave
	ret
GrObjChangeGrObjBaseAreaAttrElementByteRecord		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjChangeGrObjBaseLineAttrElementField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove reference to passed index and add new reference
		for same data with one field changed.


CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - object
		cx - index
		dx:ax - new field data
		bx - offset in GrObjBaseLineAttrElement to field
		di - field size in bytes
			1 byte - al
			2 bytes - ax
			3 bytes - dl,ax
			4 bytes - dx,ax


RETURN:		
		cx - new element number

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		If unable to get the current attributes, just punt
		and return the original index.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjChangeGrObjBaseLineAttrElementField		proc	far
	uses	ax,bp,di,es
	.enter

	;    Invalidate the object before hand in case the line
	;    width shrinks.
	;

	push	ax					;new data
	mov	ax,MSG_GO_INVALIDATE_LINE
	call	ObjCallInstanceNoLock
	pop	ax					;new data

	;    Get the current attributes and then remove our
	;    reference to them
	;

	sub	sp,size GrObjFullLineAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullLineAttrElement
	jnc	clearFrame
	call	GrObjDerefGrObjLineToken

	;    Copy the new data into the attribute structure
	;

	mov	cx,di					;number of bytes
	segmov	es,ss					;dest segment
	mov	di,bp					;frame offset
	add	di,bx					;field offset
	stosb
	dec	cx
	jz	addElement
	mov	al,ah
	stosb
	dec	cx
	jz	addElement
	mov	al,dl
	stosb
	dec	cx
	jz	addElement
	mov	al,dh
	stosb
	
addElement:
	;    Add the new element to the attribute arrays
	;

	call	GrObjAddGrObjFullLineAttrElement
	mov	cx,ax					;new token

clearFrame:
	add	sp, size GrObjFullLineAttrElement
	.leave
	ret
GrObjChangeGrObjBaseLineAttrElementField		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjChangeGrObjBaseLineAttrElementByteRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove reference to passed index and add new reference
		for same data with one field changed.


CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - object
		cx - index
		al - bits to set
		ah - bits to reset
		bx - offset in GrObjBaseLineAttrElement to byte record


RETURN:		
		cx - new element number

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		If unable to get the current attributes, just punt
		and return the original index.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjChangeGrObjBaseLineAttrElementByteRecord		proc	far
	uses	ax,bp,di
	.enter

	;    Get the current attributes and then remove our
	;    reference to them
	;

	sub	sp,size GrObjFullLineAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullLineAttrElement
	jnc	clearFrame
	call	GrObjDerefGrObjLineToken

	;    Copy the new data into the attribute structure
	;

	mov	di,bx
	mov	cl,ss:[bp][di]
	not	ah					;make bits to reset 0's
	andnf	cl,ah					;reset bits
	ornf	cl,al					;set bits
	mov	ss:[bp][di],cl

	;    Add the new element to the attribute arrays
	;

	call	GrObjAddGrObjFullLineAttrElement
	mov	cx,ax					;new token

clearFrame:
	add	sp, size GrObjFullLineAttrElement
	.leave
	ret
GrObjChangeGrObjBaseLineAttrElementByteRecord		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAddGrObjFullAreaAttrElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Add an element (or a new reference to an existing element)
	in the area attr element array in body

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - object
		ss:bp - GrObjBaseAreaAttrElement

RETURN:		
		ax - element number
		stc - if this element newly added

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
	srs	1/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAddGrObjFullAreaAttrElement		proc	far
	uses	di,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>
EC <	push	ds						>
EC <	segmov	ds,ss						>
EC <	call	GrObjCheckGrObjBaseAreaAttrElement			>	
EC <	pop	ds						>

	call	GrObjDetermineAreaAttributeDataSize
	mov	dx,ax						;element size
	mov	ax,MSG_GOAM_ADD_AREA_ATTR_ELEMENT

	mov	di,mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	call	GrObjMessageToGOAM

	.leave
	ret

GrObjAddGrObjFullAreaAttrElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAddGrObjFullLineAttrElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Add an element (or a new reference to an existing element)
	in the line attr element array in body

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - segment of object block
		ss:bp - GrObjBaseLineAttrElement

RETURN:		
		ax - element number
		stc - if this element newly added

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
	srs	1/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAddGrObjFullLineAttrElement		proc	far
	uses	di,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>
EC <	push	ds						>
EC <	segmov	ds,ss						>
EC <	call	GrObjCheckGrObjBaseLineAttrElement			>	
EC <	pop	ds						>

	call	GrObjDetermineLineAttributeDataSize
	mov	dx,ax						;element size
	mov	ax,MSG_GOAM_ADD_LINE_ATTR_ELEMENT

	mov	di,mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
	call	GrObjMessageToGOAM

	.leave
	ret

GrObjAddGrObjFullLineAttrElement		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDerefGrObjAreaToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Dereference element in area attr array (remove if
		reference count geos to zero)

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - object
		cx - token

RETURN:		
		stc - if element actually removed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDerefGrObjAreaToken		proc	far
	uses	ax,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;    Must check for null element here because floater will
	;    deref on final_obj_free, but the body will have
	;    already been destroyed.
	;

	cmp	cx, CA_NULL_ELEMENT
	je	null

	mov	ax,MSG_GOAM_DEREF_AREA_ATTR_ELEMENT_TOKEN
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM

done:
	.leave
	ret

null:
	clc
	jmp	done

GrObjDerefGrObjAreaToken		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDerefGrObjLineToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference element in line attr array (remove if
		reference count geos to zero)

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - object
		cx - line token

RETURN:		
		stc - if element actually removed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDerefGrObjLineToken		proc	far
	uses	ax,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;    Must check for null element here because floater will
	;    deref on final_obj_free, but the body will have
	;    already been destroyed.
	;

	cmp	cx, CA_NULL_ELEMENT
	je	null

	mov	ax,MSG_GOAM_DEREF_LINE_ATTR_ELEMENT_TOKEN
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM

done:
	.leave
	ret

null:
	clc
	jmp	done

GrObjDerefGrObjLineToken		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAddRefGrObjAreaToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add reference to element in area attr array

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - object
		cx - area token

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			element is valid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAddRefGrObjAreaToken		proc	far
	uses	ax,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_GOAM_ADD_REF_AREA_ATTR_ELEMENT_TOKEN
	call	GrObjMessageToGOAM

	.leave
	ret

GrObjAddRefGrObjAreaToken		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAddRefGrObjLineToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Add reference to element in line attr array

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - segment of object block
		cx - line token

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			element is valid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAddRefGrObjLineToken		proc	far
	uses	ax,di
	.enter

	mov	ax,MSG_GOAM_ADD_REF_LINE_ATTR_ELEMENT_TOKEN
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM

	.leave
	ret
GrObjAddRefGrObjLineToken		endp













COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDetermineAreaAttributeDataSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the size of the area attribute data in
		the passed stack frame. The structure begings
		with an GrObjBaseAreaAttrElement and size of the remaining
		data can be determined for the data in the 
		GrObjBaseAreaAttrElement.

		Currently, there can be no extra data below the
		GrObjBaseAreaAttrElement, so just return its size

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		ss:bp - area attributes structure

RETURN:		
		ax - size of data in structure

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDetermineAreaAttributeDataSize		proc	far
	.enter

	mov	ax, size GrObjBaseAreaAttrElement
	cmp	ss:[bp].GOBAAE_aaeType,GOAAET_BASE
	jne	other
done:
	.leave
	ret

other:
	cmp	ss:[bp].GOBAAE_aaeType,GOAAET_GRADIENT
EC < ERROR_NE GROBJ_BAD_AREA_ATTR_ELEMENT_TYPE		>
	mov	ax,size GrObjGradientAreaAttrElement
	jmp	done

GrObjDetermineAreaAttributeDataSize		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDetermineLineAttributeDataSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the size of the line attribute data in
		the passed stack frame. The structure begings
		with an GrObjBaseLineAttrElement and size of the remaining
		data can be determined for the data in the 
		GrObjBaseLineAttrElement.

		Currently, there can be no extra data below the
		GrObjBaseLineAttrElement, so just return its size

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		ss:bp - line attributes structure

RETURN:		
		ax - size of data in structure

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDetermineLineAttributeDataSize		proc	far
	.enter

	mov	ax, size GrObjBaseLineAttrElement
	cmp	ss:[bp].GOBLAE_laeType,GOLAET_BASE
EC <	ERROR_NE GROBJ_BAD_LINE_ATTR_ELEMENT_TYPE		>

	.leave
	ret

GrObjDetermineLineAttributeDataSize		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetAreaColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return area color of object . Will return 0,0,0 if
		area element is null.

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object

RETURN:		
		cl - r 
		ch - g
		dl - b

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE 
		because it is used during drawing.

		Common cases:
			Area element is valid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetAreaColor		proc	far
	class	GrObjClass
	uses	bp
	.enter

EC <	call	ECGrObjCheckLMemObject					>


	GrObjDeref	bp,ds,si
	mov	cx,ds:[bp].GOI_areaAttrToken
	sub	sp, size GrObjFullAreaAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullAreaAttrElement
	jnc	noElement
	mov	cl,ss:[bp].GOBAAE_r
	mov	ch,ss:[bp].GOBAAE_g
	mov	dl,ss:[bp].GOBAAE_b

clearFrame:
	add	sp, size GrObjFullAreaAttrElement

	.leave
	ret

noElement:
	clr	cx
	clr	dl
	jmp	clearFrame

GrObjGetAreaColor		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetLineColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return line color of object . Will return 0,0,0 if
		line element is null.

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object

RETURN:		
		cl - r 
		ch - g
		dl - b

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE 
		because it is used during drawing.

		Common cases:
			Line element is valid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetLineColor		proc	far
	class	GrObjClass
	uses	bp
	.enter

EC <	call	ECGrObjCheckLMemObject					>


	GrObjDeref	bp,ds,si
	mov	cx,ds:[bp].GOI_lineAttrToken
	sub	sp, size GrObjFullLineAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullLineAttrElement
	jnc	noElement
	mov	cl,ss:[bp].GOBLAE_r
	mov	ch,ss:[bp].GOBLAE_g
	mov	dl,ss:[bp].GOBLAE_b

clearFrame:
	add	sp, size GrObjFullLineAttrElement

	.leave
	ret

noElement:
	clr	cx
	clr	dl
	jmp	clearFrame

GrObjGetLineColor		endp


GrObjAttributesCode	ends


GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetGrObjFullAreaAttrElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the GrObjAttributeManager to
		get the GrObjFullAreaAttrElement for the passed index

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object
		cx - element number
		ss:bp - GrObjFullAreaAttrElement - empty

RETURN:		
		stc - element exists
			ss:bp - GrObjFullAreaAttrElement - filled
		clc - element
			ss:bp - garbage

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE
		because it is used during drawing

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetGrObjFullAreaAttrElement		proc	far
	uses	ax,dx,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>


	mov	di,mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	mov	dx,size GrObjFullAreaAttrElement
	mov	ax,MSG_GOAM_GET_FULL_AREA_ATTR_ELEMENT
	call	GrObjMessageToGOAM

	;    Error check the the area attributes if data was
	;    actually returned

EC <	jnc	errorDone					>
EC <	pushf							>
EC <	push	ds						>
EC <	segmov	ds,ss						>
EC <	call	GrObjCheckGrObjBaseAreaAttrElement			>	
EC <	pop	ds						>
EC <	popf							>
EC <errorDone:							>

	.leave
	ret
	
GrObjGetGrObjFullAreaAttrElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetGrObjFullLineAttrElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return GrObjBaseLineAttrElement for object

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object
		cx - element number
		ss:bp - GrObjFullLineAttrElement - empty

RETURN:		
		stc - element exists
			ss:bp - GrObjFullLineAttrElement - filled
		clc - element
			ss:bp - garbage

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE
		because it is used during drawing

		Common cases:
			none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetGrObjFullLineAttrElement		proc	far
	uses	ax,dx,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	di,mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	mov	dx,size GrObjFullLineAttrElement
	mov	ax,MSG_GOAM_GET_FULL_LINE_ATTR_ELEMENT
	call	GrObjMessageToGOAM

	;    Error check the the line attributes if data was
	;    actually returned
	;

EC <	jnc	errorDone					>
EC <	pushf							>
EC <	push	ds						>
EC <	segmov	ds,ss						>
EC <	call	GrObjCheckGrObjBaseLineAttrElement			>	
EC <	pop	ds						>
EC <	popf							>
EC <errorDone:							>

	.leave
	ret

	
GrObjGetGrObjFullLineAttrElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyGrObjAreaToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply the area attributes found in the body area attribute
		array at the passed index to the gstate

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - segment of object block	
		cx - token
		di - gstate

RETURN:		
		di - gstate with attributes applied

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
GrObjApplyGrObjAreaToken		proc	far
	uses	bp
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	sub	sp,size GrObjFullAreaAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullAreaAttrElement
	jnc	clearFrame
	call	GrObjApplyGrObjFullAreaAttrElement

clearFrame:
	add	sp, size GrObjFullAreaAttrElement

	.leave
	ret
GrObjApplyGrObjAreaToken		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyGrObjLineToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply the line attributes found in the body line attribute
		array at the passed index to the gstate

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - object
		cx - token
		di - gstate

RETURN:		
		di - gstate with attributes applied

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
GrObjApplyGrObjLineToken		proc	far
	uses	bp
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	sub	sp,size GrObjFullLineAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullLineAttrElement
	jnc	clearFrame
	call	GrObjApplyGrObjFullLineAttrElement
clearFrame:
	add	sp, size GrObjFullLineAttrElement

	.leave
	ret
GrObjApplyGrObjLineToken		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyGrObjFullAreaAttrElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply area attibutes passed in stack frame to gstate

PASS:		
		ss:bp - GrObjFullAreaAttrElement
		di - gstate

RETURN:		
		GState altered

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjApplyGrObjFullAreaAttrElement 	proc 	far
	uses	ax,dx,ds,si
	push	bx
	mov	bx, bp			; ss:bx -> GrObjBaseAreaAttrElement
aa	local	AreaAttr
	.enter

EC <	call	ECCheckGStateHandle				>

	mov	ss:aa.AA_colorFlag, CF_RGB 
	mov	al,ss:[bx].GOBAAE_r		
	mov	ss:aa.AA_color.RGB_red, al
	mov	ax, {word} ss:[bx].GOBAAE_g		;also GOBAAE_b
	mov	{word} ss:aa.AA_color.RGB_green, ax
	mov	ss:aa.AA_mapMode, (CMT_DITHER shl offset CMM_MAP_TYPE )
	mov	al, ss:[bx].GOBAAE_mask
	mov	ss:aa.AA_mask, al
	segmov	ds, ss, si
	lea	si, ss:aa
	call	GrSetAreaAttr
	mov	al, ss:[bx].GOBAAE_drawMode
	call	GrSetMixMode
	mov	al,ss:[bx].GOBAAE_pattern.GP_type
	mov	ah,ss:[bx].GOBAAE_pattern.GP_data
	call	GrSetAreaPattern

	.leave
	pop	bx
	ret
GrObjApplyGrObjFullAreaAttrElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyGrObjFullLineAttrElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets gstate to line attrs in passed structure

PASS:		
		ss:bp - fptr to GrObjFullLineAttrElement
		di - gstate

RETURN:		
		GState altered

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
GrObjApplyGrObjFullLineAttrElement 	proc 	far
	uses	ax,cx,dx,si,ds
	push	bx
	mov	bx, bp					; ss:bx -> LAE...
la	local	LineAttr
	.enter

EC <	call	ECCheckGStateHandle				>

	mov	ss:la.LA_colorFlag, CF_RGB
	mov	al,ss:[bx].GOBLAE_r
	mov	ss:la.LA_color.RGB_red, al
	mov	ax,{word} ss:[bx].GOBLAE_g			;also b
	mov	{word} ss:la.LA_color.RGB_green, ax
	mov	ax,{word} ss:[bx].GOBLAE_end		;also line join
	mov	{word} ss:la.LA_end, ax
	mov	ax,ss:[bx].GOBLAE_width.WWF_int

	;     We've got a bug I can't find that sets the line width to
	;     -1. Until we find it lets at least prevent bad things
	;     from happening.
	;

	tst	ax
	js	bummer

lineWidthOKNow:
	mov	ss:la.LA_width.WWF_int, ax
	mov	ax, ss:[bx].GOBLAE_width.WWF_frac
	mov	ss:la.LA_width.WWF_frac, ax
	mov	ss:la.LA_mapMode, (CMT_DITHER shl offset CMM_MAP_TYPE )
	mov	al, ss:[bx].GOBLAE_mask
	mov	ss:la.LA_mask, al
	mov	al, ss:[bx].GOBLAE_style
	mov	ss:la.LA_style, al
	segmov	ds, ss, si
	lea	si, ss:la
	call	GrSetLineAttr
	mov	ax,ss:[bx].GOBLAE_miterLimit.WWF_frac
	mov	bx,ss:[bx].GOBLAE_miterLimit.WWF_int
	call	GrSetMiterLimit				;degrees

	.leave
	pop	bx

	ret

bummer:
	mov	ax,1
	jmp	lineWidthOKNow	

GrObjApplyGrObjFullLineAttrElement		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetAreaInfoAndMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return areaInfo of object . Will return zero if 
		area element is null.

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object

RETURN:		
		al - AreaAttrInfoRecord
		ah - SystemDrawMask

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE 
		because it is used during drawing.

		Common cases:
			Area element is valid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetAreaInfoAndMask		proc	far
	class	GrObjClass
	uses	bp,cx
	.enter

EC <	call	ECGrObjCheckLMemObject					>


	GrObjDeref	bp,ds,si
	mov	cx,ds:[bp].GOI_areaAttrToken
	sub	sp, size GrObjFullAreaAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullAreaAttrElement
	jnc	noElement
	mov	al,ss:[bp].GOBAAE_areaInfo
	mov	ah,ss:[bp].GOBAAE_mask

clearFrame:
	add	sp, size GrObjFullAreaAttrElement

	.leave
	ret

noElement:
	clr	al					;AreaAttrInfoRecord
	mov	ah,SDM_100
	jmp	clearFrame

GrObjGetAreaInfoAndMask		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyBackgroundAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply attributes to draw background of object.

		Color = white
		Mask = 100
		DrawMode = COPY
		MapColorToMono = Dither

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object
		di - gstate

RETURN:		
		di - gstate with altered attributes

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjApplyBackgroundAttrs		proc	far
	class	GrObjClass
	uses	ax,cx,bx
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;    Apply line attributes because we need the line width,
	;    end, join, and miter limit for background lines
	;

	GrObjDeref	bx,ds,si
	mov	cx,ds:[bx].GOI_lineAttrToken
	call	GrObjApplyGrObjLineToken

	;    The background color is stored in the area structure
	;
	
	GrObjDeref	bx,ds,si
	mov	cx,ds:[bx].GOI_areaAttrToken
	sub	sp,size GrObjFullAreaAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullAreaAttrElement
	jnc	clearFrame
	mov	al,ss:[bp].GOBAAE_backR
	mov	bl,ss:[bp].GOBAAE_backG
	mov	bh,ss:[bp].GOBAAE_backB
	mov	ah,CF_RGB
clearFrame:
	add	sp, size GrObjFullAreaAttrElement
	call	GrSetAreaColor
	call	GrSetLineColor


	mov	al,SDM_100
	call	GrSetAreaMask
	call	GrSetLineMask
	mov	al,(CMT_DITHER shl offset CMM_MAP_TYPE )
	call	GrSetAreaColorMap
	call	GrSetLineColorMap
	mov	al, MM_COPY
	call	GrSetMixMode
	mov	al,PT_SOLID
	call	GrSetAreaPattern

	.leave
	ret
GrObjApplyBackgroundAttrs		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetAreaAttrElementType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return GrObjAreaAttrElementType of object

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object

RETURN:		
		al - GrObjAreaAttrElementType

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED
	

		Common cases:
			Area element is valid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetAreaAttrElementType		proc	far
	class	GrObjClass
	uses	bp,cx
	.enter

EC <	call	ECGrObjCheckLMemObject					>


	GrObjDeref	bp,ds,si
	mov	cx,ds:[bp].GOI_areaAttrToken
	sub	sp, size GrObjFullAreaAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullAreaAttrElement
	jnc	noElement
	mov	al,ss:[bp].GOBAAE_aaeType

clearFrame:
	add	sp, size GrObjFullAreaAttrElement

	.leave
	ret

noElement:
	clr	al		
	jmp	clearFrame

GrObjGetAreaAttrElementType		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetLineAttrElementType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return GrObjLineAttrElementType of object

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object

RETURN:		
		al - GrObjLineAttrElementType

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED
	

		Common cases:
			Line element is valid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetLineAttrElementType		proc	far
	class	GrObjClass
	uses	bp,cx
	.enter

EC <	call	ECGrObjCheckLMemObject					>


	GrObjDeref	bp,ds,si
	mov	cx,ds:[bp].GOI_lineAttrToken
	sub	sp, size GrObjFullLineAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullLineAttrElement
	jnc	noElement
	mov	al,ss:[bp].GOBAAE_aaeType

clearFrame:
	add	sp, size GrObjFullLineAttrElement

	.leave
	ret

noElement:
	clr	al				
	jmp	clearFrame

GrObjGetLineAttrElementType		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetLineInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return lineInfo of object . Will return zero if 
		line element is null.

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object

RETURN:		
		al - LineAttrInfoRecord

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE 
		because it is used during drawing.

		Common cases:
			Line element is valid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetLineInfo		proc	far
	class	GrObjClass
	uses	bp,cx
	.enter

EC <	call	ECGrObjCheckLMemObject					>


	GrObjDeref	bp,ds,si
	mov	cx,ds:[bp].GOI_lineAttrToken
	sub	sp, size GrObjFullLineAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullLineAttrElement
	jnc	noElement
	mov	al,ss:[bp].GOBLAE_lineInfo

clearFrame:
	add	sp, size GrObjFullLineAttrElement

	.leave
	ret

noElement:
	clr	al		
	jmp	clearFrame

GrObjGetLineInfo		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetArrowheadInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return information about arrowheads. Will return zeros if 
		line element is null.

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object

RETURN:		
		al - LineAttrInfoRecord
		bl - arrowhead length
		bh - arrowhead angle

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE 
		because it is used during drawing.

		Common cases:
			Line element is valid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetArrowheadInfo		proc	far
	class	GrObjClass
	uses	bp,cx
	.enter

EC <	call	ECGrObjCheckLMemObject					>


	GrObjDeref	bp,ds,si
	mov	cx,ds:[bp].GOI_lineAttrToken
	sub	sp, size GrObjFullLineAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullLineAttrElement
	jnc	noElement
	mov	al,ss:[bp].GOBLAE_lineInfo
	mov	bl,ss:[bp].GOBLAE_arrowheadLength
	mov	bh,ss:[bp].GOBLAE_arrowheadAngle

clearFrame:
	add	sp, size GrObjFullLineAttrElement

	.leave
	ret

noElement:
	clr	al		
	clr	bx
	jmp	clearFrame

GrObjGetArrowheadInfo		endp

GrObjDrawCode	ends








GrObjAlmostRequiredCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetLineWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return line width of object. Will return zero if line
		element number is null or the line mask is zero.
		

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object

RETURN:		
		di:bp - WWFixed width

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE 
		because it is used during drawing.

		Common cases:
			Line element is valid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetLineWidth		proc	far
	class	GrObjClass
	uses	cx
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	GrObjDeref	di,ds,si
	mov	cx,ds:[di].GOI_lineAttrToken
	sub	sp, size GrObjFullLineAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullLineAttrElement
	jnc	returnZeroThickness
	cmp	ss:[bp].GOBLAE_mask, SDM_0
	je	returnZeroThickness
	mov	di, ss:[bp].GOBLAE_width.WWF_int
	mov	bp, ss:[bp].GOBLAE_width.WWF_frac

clearFrame:
	add	sp, size GrObjFullLineAttrElement

	.leave
	ret

returnZeroThickness:
	clr	di
	mov	bp,di
	jmp	clearFrame

GrObjGetLineWidth		endp

GrObjAlmostRequiredCode	ends


GrObjSpecialGraphicsCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetStartingGradientColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return starting gradient color of object. Which
		happens to be stored in the normal fg area color.
		Will return 0,0,0 if area element is null or
		isn't of type GOAAET_GRADIENT

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object

RETURN:		
		cl - r 
		ch - g
		dl - b

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED 

		Common cases:
			Area element is valid
			Area element is gradient type

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetStartingGradientColor		proc	far
	class	GrObjClass
	uses	bp
	.enter

EC <	call	ECGrObjCheckLMemObject					>


	GrObjDeref	bp,ds,si
	mov	cx,ds:[bp].GOI_areaAttrToken
	sub	sp, size GrObjFullAreaAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullAreaAttrElement
	jnc	noElement
	cmp	ss:[bp].GOBAAE_aaeType,GOAAET_GRADIENT
	jne	noElement
	mov	cl,ss:[bp].GOBAAE_r
	mov	ch,ss:[bp].GOBAAE_g
	mov	dl,ss:[bp].GOBAAE_b

clearFrame:
	add	sp, size GrObjFullAreaAttrElement

	.leave
	ret

noElement:
	clr	cx
	clr	dl
	jmp	clearFrame

GrObjGetStartingGradientColor		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetEndingGradientColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return ending gradient color of object. 
		Will return 0,0,0 if area element is null or
		isn't of type GOAAET_GRADIENT

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object

RETURN:		
		cl - r 
		ch - g
		dl - b

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED 

		Common cases:
			Area element is valid
			Area element is gradient type

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetEndingGradientColor		proc	far
	class	GrObjClass
	uses	bp
	.enter

EC <	call	ECGrObjCheckLMemObject					>


	GrObjDeref	bp,ds,si
	mov	cx,ds:[bp].GOI_areaAttrToken
	sub	sp, size GrObjFullAreaAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullAreaAttrElement
	jnc	noElement
	cmp	ss:[bp].GOBAAE_aaeType,GOAAET_GRADIENT
	jne	noElement
	mov	cl,ss:[bp].GOGAAE_endR
	mov	ch,ss:[bp].GOGAAE_endG
	mov	dl,ss:[bp].GOGAAE_endB

clearFrame:
	add	sp, size GrObjFullAreaAttrElement

	.leave
	ret

noElement:
	clr	cx
	clr	dl
	jmp	clearFrame

GrObjGetEndingGradientColor		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetNumberOfGradientIntervals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return number of gradient intervals
		Will return 0 if area element is null or
		isn't of type GOAAET_GRADIENT

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object

RETURN:		
		cx - number of intervals

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED 

		Common cases:
			Area element is valid
			Area element is gradient type

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetNumberOfGradientIntervals		proc	far
	class	GrObjClass
	uses	bp
	.enter

EC <	call	ECGrObjCheckLMemObject					>


	GrObjDeref	bp,ds,si
	mov	cx,ds:[bp].GOI_areaAttrToken
	sub	sp, size GrObjFullAreaAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullAreaAttrElement
	jnc	noElement
	cmp	ss:[bp].GOBAAE_aaeType,GOAAET_GRADIENT
	jne	noElement
	mov	cx,ss:[bp].GOGAAE_numIntervals

clearFrame:
	add	sp, size GrObjFullAreaAttrElement

	.leave
	ret

noElement:
	clr	cx
	jmp	clearFrame

GrObjGetNumberOfGradientIntervals		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetGradientType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return number of gradient intervals
		Will return GOGT_LEFT_TO_RIGHT if area element is null or
		isn't of type GOAAET_GRADIENT

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object

RETURN:		
		al - GrObjGradientType

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED 

		Common cases:
			Area element is valid
			Area element is gradient type

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetGradientType		proc	far
	class	GrObjClass
	uses	bp
	.enter

EC <	call	ECGrObjCheckLMemObject					>


	GrObjDeref	bp,ds,si
	mov	cx,ds:[bp].GOI_areaAttrToken
	sub	sp, size GrObjFullAreaAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullAreaAttrElement
	jnc	noElement
	cmp	ss:[bp].GOBAAE_aaeType,GOAAET_GRADIENT
	jne	noElement
	mov	al,ss:[bp].GOGAAE_type

clearFrame:
	add	sp, size GrObjFullAreaAttrElement

	.leave
	ret

noElement:
	mov	al,GOGT_LEFT_TO_RIGHT
	jmp	clearFrame

GrObjGetGradientType		endp

GrObjSpecialGraphicsCode	ends
