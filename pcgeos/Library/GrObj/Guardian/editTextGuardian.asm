COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj
FILE:		editTextGuardian.asm

AUTHOR:		Steve Scholl, Jan  9, 1992

ROUTINES:
	Name	
	----	

METHODS:
	Name
	----
EditTextGuardianLargeStartSelect
EditTextGuardianGetEditClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	1/ 9/92		Initial revision


DESCRIPTION:
	
		

	$Id: editTextGuardian.asm,v 1.1 97/04/04 18:08:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

EditTextGuardianClass		;Define the class record

GrObjClassStructures	ends

GrObjTextGuardianCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditTextGuardianMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the class of the vis ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of EditTextGuardianClass

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
	srs	12/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditTextGuardianMetaInitialize	method dynamic EditTextGuardianClass, 
							MSG_META_INITIALIZE
	.enter

	mov	di, offset EditTextGuardianClass
	CallSuper	MSG_META_INITIALIZE

	;   The edit text guardian cannot create new objects but
	;   it can edit existing ones
	;

	GrObjDeref	di,ds,si
	andnf	ds:[di].GOVGI_flags,not mask GOVGF_CREATE_MODE
	ornf	ds:[di].GOVGI_flags, GOVGCM_NO_CREATE \
					shl offset GOVGF_CREATE_MODE or \
					mask GOVGF_CAN_EDIT_EXISTING_OBJECTS

	.leave
	ret
EditTextGuardianMetaInitialize		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditTextGuardianGetSituationalPointerImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return default pointer images for situation

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of EditTextGuardianClass

		cl - GrObjPointerImageSituation

RETURN:		
		ah - high byte of MouseReturnFlags
			MRF_SET_POINTER_IMAGE or MRF_CLEAR_POINTER_IMAGE
		if MRF_SET_POINTER_IMAGE
		cx:dx - optr of mouse image
	
DESTROYED:	
		al

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditTextGuardianGetSituationalPointerImage	method dynamic \
	EditTextGuardianClass, MSG_GO_GET_SITUATIONAL_POINTER_IMAGE
	.enter

	mov	ax,mask MRF_SET_POINTER_IMAGE

	cmp	cl,GOPIS_CREATE
	je	edit

	cmp	cl,GOPIS_NORMAL
	je	edit

	cmp	cl,GOPIS_EDIT
	je	edit

	mov	ax,mask MRF_CLEAR_POINTER_IMAGE

done:
	.leave
	ret

edit:
	mov	cx,handle ptrTextEdit
	mov	dx,offset ptrTextEdit
	jmp	done

EditTextGuardianGetSituationalPointerImage	endm


GrObjTextGuardianCode	ends



if	ERROR_CHECK

GrObjErrorCode	segment resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECEditTextGuardianCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is an EditTextGuardianClass or one
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
ECEditTextGuardianCheckLMemObject		proc	near
ForceRef	ECEditTextGuardianCheckLMemObject
	uses	es,di
	.enter
	pushf	
	mov	di,segment EditTextGuardianClass
	mov	es,di
	mov	di,offset EditTextGuardianClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_OF_CORRECT_CLASS
	popf
	.leave
	ret
ECEditTextGuardianCheckLMemObject		endp

GrObjErrorCode	ends

endif



