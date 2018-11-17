COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj
FILE:		multTextGuardian.asm

AUTHOR:		Steve Scholl, Jan  9, 1992

ROUTINES:
	Name	
	----	
MultTextGuardianGetDefaultParaToken
MultTextGuardianGetDefaultCharToken

METHODS:
	Name
	----
MultTextGuardianGetEditClass
MultTextGuardianCreateVisWard

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	1/ 9/92		Initial revision


DESCRIPTION:
	
		

	$Id: multTextGuardian.asm,v 1.1 97/04/04 18:08:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

MultTextGuardianClass		;Define the class record

GrObjClassStructures	ends

GrObjTextGuardianCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MultTextGuardianCreateVisWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create storage for the text object.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of MultTextGuardianClass

RETURN:		
		^lcx:dx - new ward
	
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
	srs	5/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MultTextGuardianCreateVisWard	method dynamic MultTextGuardianClass, 
						MSG_GOVG_CREATE_VIS_WARD
	uses	bp
	.enter

	;    Call our superclass so that the we have a ward
	;    that we can create storage in
	;

	mov	di,offset MultTextGuardianClass
	call	ObjCallSuperNoLock

	push	cx, dx					;save ward optr

	mov	cl, mask VTSF_MULTIPLE_CHAR_ATTRS or \
			mask VTSF_MULTIPLE_PARA_ATTRS or mask VTSF_TYPES or \
			mask VTSF_GRAPHICS or mask VTSF_STYLES
	clr	ch
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_VIS_TEXT_CREATE_STORAGE
	call	GrObjVisGuardianMessageToVisWard

	sub	sp, size GrObjTextArrays
	mov	bp, sp
	mov	ax,MSG_GOAM_GET_TEXT_ARRAYS
	mov	di,mask MF_FIXUP_DS
	call	GrObjMessageToGOAM

	; Do the name and style arrays first because to change the
	; element array the text object must free the old element array.
	; To do this is must know how this array is stored (with chunk
	; or VM block). It does this by looking at the character
	; attributes and assuming that the styles/names are stored in
	; the same way.  Thus we must change the styles/names while
	; the character attributes are still stored in a chunk so that
	; the old style/name array will be freed correctly.

	mov	ax,MSG_VIS_TEXT_CHANGE_ELEMENT_ARRAY	;same message throughout

	mov	dx, ss:[bp].GOTA_nameArray
	mov	cl, VTSF_NAMES
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	mov	dx, ss:[bp].GOTA_textStyleArray
	mov	cl, mask VTSF_STYLES
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	push	bp
	mov	dx, ss:[bp].GOTA_charAttrArray
	call	MultTextGuardianGetDefaultCharToken
	mov	cl, mask VTSF_MULTIPLE_CHAR_ATTRS
	mov	ch,1					;dx is a vm block han
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	pop	bp

	push	bp
	mov	dx, ss:[bp].GOTA_paraAttrArray
	call	MultTextGuardianGetDefaultParaToken
	mov	cl, mask VTSF_MULTIPLE_PARA_ATTRS
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	pop	bp

	push	bp
	mov	dx, ss:[bp].GOTA_typeArray
	call	MultTextGuardianGetDefaultTypeToken
	mov	cl, mask VTSF_TYPES
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	pop	bp

	mov	dx, ss:[bp].GOTA_graphicArray
	mov	cl, mask VTSF_GRAPHICS
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	add	sp, size GrObjTextArrays

	pop	cx, dx					;^lcx:dx <- ward

	.leave
	ret
MultTextGuardianCreateVisWard		endm







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MultTextGuardianGetDefaultTypeToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the token of the default text type stored
		in the attribute manager

CALLED BY:	INTERNAL
		MultTextGuardianInitToDefaultAttrs

PASS:		*ds:si - MultTextGuardian

RETURN:		
		bp - token

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
	srs	5/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MultTextGuardianGetDefaultTypeToken		proc	near
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECMultTextGuardianCheckLMemObject			>

	;    Create frames to hold data areas that must be passed
	;    with para messages
	;

	sub	sp,size VisTextType
	mov	ax,sp
	sub	sp,size VisTextTypeDiffs
	mov	bx,sp

	;    Set up params to VIS_TEXT_GET_TYPE, pointing
	;    its stack frame at the stack frames just created.	
	;

	mov	dx,size VisTextGetAttrParams
	sub	sp,dx
	mov	bp,sp
	movdw	ss:[bp].VTGAP_attr, ssax
	movdw	ss:[bp].VTGAP_return, ssbx
	mov	ss:[bp].VTGAP_range.VTR_start.high,VIS_TEXT_RANGE_SELECTION
	mov	ss:[bp].VTGAP_flags, 0

	;    Get those attributes and the token
	;

	mov	di,mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	mov	ax,MSG_VIS_TEXT_GET_TYPE
	call	GrObjMessageToGOAMText

	;    Clear the stack of all those stack frames. 
	;    We just need the token.
	;

	add	sp, (size VisTextGetAttrParams + \
			size VisTextType + \
			size VisTextTypeDiffs)


	mov	bp,ax				;token

	.leave
	ret
MultTextGuardianGetDefaultTypeToken		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MultTextGuardianGetDefaultParaToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the token of the default text paragraph stored
		in the attribute manager

CALLED BY:	INTERNAL
		MultTextGuardianInitToDefaultAttrs

PASS:		*ds:si - MultTextGuardian

RETURN:		
		bp - token

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
	srs	5/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MultTextGuardianGetDefaultParaToken		proc	near
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECMultTextGuardianCheckLMemObject			>

	;    Create frames to hold data areas that must be passed
	;    with para messages
	;

	sub	sp,size VisTextMaxParaAttr
	mov	ax,sp
	sub	sp,size VisTextParaAttrDiffs
	mov	bx,sp

	;    Set up params to VIS_TEXT_GET_PARA_ATTR, pointing
	;    its stack frame at the stack frames just created.	
	;

	mov	dx,size VisTextGetAttrParams
	sub	sp,dx
	mov	bp,sp
	movdw	ss:[bp].VTGAP_attr, ssax
	movdw	ss:[bp].VTGAP_return, ssbx
	mov	ss:[bp].VTGAP_range.VTR_start.high,VIS_TEXT_RANGE_SELECTION
	mov	ss:[bp].VTGAP_flags, 0

	;    Get those attributes and the token
	;

	mov	di,mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	mov	ax,MSG_VIS_TEXT_GET_PARA_ATTR
	call	GrObjMessageToGOAMText

	;    Clear the stack of all those stack frames. 
	;    We just need the token.
	;

	add	sp, (size VisTextGetAttrParams + \
			size VisTextMaxParaAttr + \
			size VisTextParaAttrDiffs)


	mov	bp,ax				;token

	.leave
	ret
MultTextGuardianGetDefaultParaToken		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MultTextGuardianGetDefaultCharToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the token of the default text chargraph stored
		in the attribute manager

CALLED BY:	INTERNAL
		MultTextGuardianInitToDefaultAttrs

PASS:		*ds:si - MultTextGuardian

RETURN:		
		bp - token

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
	srs	5/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MultTextGuardianGetDefaultCharToken		proc	near
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECMultTextGuardianCheckLMemObject			>

	;    Create frames to hold data areas that must be passed
	;    with char messages
	;

	sub	sp,size VisTextCharAttr
	mov	ax,sp
	sub	sp,size VisTextCharAttrDiffs
	mov	bx,sp

	;    Set up charms to VIS_TEXT_GET_CHAR_ATTR, pointing
	;    its stack frame at the stack frames just created.	
	;

	mov	dx,size VisTextGetAttrParams
	sub	sp,dx
	mov	bp,sp
	movdw	ss:[bp].VTGAP_attr, ssax
	movdw	ss:[bp].VTGAP_return, ssbx
	mov	ss:[bp].VTGAP_range.VTR_start.high,VIS_TEXT_RANGE_SELECTION
	mov	ss:[bp].VTGAP_flags, 0

	;    Get those attributes and the token
	;

	mov	di,mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	mov	ax,MSG_VIS_TEXT_GET_CHAR_ATTR
	call	GrObjMessageToGOAMText

	;    Clear the stack of all those stack frames. 
	;    We just need the token.
	;

	add	sp, (size VisTextGetAttrParams + \
			size VisTextCharAttr + \
			size VisTextCharAttrDiffs)


	mov	bp,ax				;token

	.leave
	ret
MultTextGuardianGetDefaultCharToken		endp


GrObjTextGuardianCode	ends



if	ERROR_CHECK
GrObjErrorCode	segment resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECMultTextGuardianCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is an MultTextGuardianClass or one
		of its subclasses
		
CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - object chunk to check
RETURN:		
		none
DESTROYED:	
		nothing - not even flags

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECMultTextGuardianCheckLMemObject		proc	far
ForceRef	ECMultTextGuardianCheckLMemObject
	uses	es,di
	.enter
	pushf	
	mov	di,segment MultTextGuardianClass
	mov	es,di
	mov	di,offset MultTextGuardianClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_OF_CORRECT_CLASS
	popf
	.leave
	ret
ECMultTextGuardianCheckLMemObject		endp

GrObjErrorCode	ends

endif



