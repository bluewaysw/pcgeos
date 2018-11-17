COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Admin
FILE:		objectAccessBody.asm

AUTHOR:		Steve Scholl, Nov 15, 1991

ROUTINES:
	Name			
	----			
INT	GrObjGetDWordFromBody
INT	GrObjMessageToBody	
INT	GrObjMessageToHead	
INT	GrObjMessageToRuler	
INT	GrObjMessageToEdit	
INT	GrObjMessageToMouseGrab
INT	GrObjMessageToGroup	
INT	GrObjMessageToGOAM
INT	GrObjMessageToGOAMText
INT	GrObjCreateGState	
INT	GrObjGetBodyGStateStart	
INT	GrObjGetParentGStateStart	
INT	GrObjGetGStateEnd		
INT	GrObjGetHeadOD			
INT	GrObjGetGOAMOD			
INT     GrObjGetMouseOD
INT	GrObjGetRulerOD		
INT	GrObjGetEditOD		
INT	GrObjGetCurrentHandleSize
INT	GrObjGetDesiredHandleSize
	GrObjSendActionNotificationViaBody
	GrObjGetCurrentNudgeUnits
	GrObjActionNotificationSuspendedInBody?
	GrObjCreateBodyGState

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/91	Initial revision


DESCRIPTION:

	$Id: grobjAccessBody.asm,v 1.1 97/04/04 18:07:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetDWordFromBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return two consecutive words from the bodies instance
		data. Treats data as if it is stored low word, high
		word. Conveniently returns vm file handle for 
		callers who are getting a vm block handle

CALLED BY:	INTERNAL (UTILITY)
	
PASS:		
		ds - segment of grobject block
		bx - offset to instance words to get

RETURN:		
		carry clear - body existed
			ax - high word (word after word at offset)
			si - low word (word at offset)
			bx - vm file handle of body and friends
		carry set - no body
			ax,si,bx - DESTORYED

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetDWordFromBody		proc	far
	class	GrObjBodyClass
	uses	cx,ds
	.enter

	mov	cx,bx					;offset to words

	movdw	bxsi, ds:[OLMBH_output]
	tst	bx
	jz	noBody
EC <	call	ECGrObjBodyCheckLMemOD		>

	;    Lock the body and snag the words, then unlock the body
	;

	call	ObjLockObjBlock
	mov	ds,ax					;body segment
	mov	si,ds:[si]				;deref body
	add	si,ds:[si].GrObjBody_offset
	add	si,cx					;offset to words
	mov	ax,ds:[si+2]
	mov	si,ds:[si]
	call	MemUnlock

	;    Get vm file handle of body
	;	

	mov_tr	cx, ax					;high word from body
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo
	mov_tr	bx, ax					;vm file handle
	mov_tr	ax, cx					;high word from body

	clc
done:
	.leave
	ret


noBody:
	stc	
	jmp	done

GrObjGetDWordFromBody		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMessageToGOAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message via ObjMessage or ObjCallInstanceNoLock
		if this object is the AttributeManager to the 
		GrObjAttributeManager

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object
		ax - message
		di - MessageFlags
		cx,dx,bp - other data for message

RETURN:		
		if this object is not the GrObjAttributeManager
			if MF_CALL
				ax,cx,dx,bp - from message handler
		if this object is the GrObjManaager
			ax,cx,dx,bp - returned from message handler

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMessageToGOAM		proc	far
	class	GrObjClass
	uses	bx,si,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	GrObjDeref	bx,ds,si
	test	ds:[bx].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER
	jnz	manager

	call	GrObjGetGOAMOD
	ornf	di, mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret

manager:
	call	ObjCallInstanceNoLock
	jmp	done

GrObjMessageToGOAM		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetGOAMOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the OD of the oam from the body

CALLED BY:	INTERNAL

PASS:		
		ds - segment of object block

RETURN:		
		^lbx:si - oam od

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
GrObjGetGOAMOD		proc	far
	uses	ax
	.enter

	mov	bx,offset GBI_goam
	call	GrObjGetDWordFromBody
	mov_tr	bx,ax					;oam handle

	.leave
	ret
GrObjGetGOAMOD		endp

GrObjDrawCode	ends


GrObjAlmostRequiredCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetDrawFlagsFromBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the draw flags from the GrObjBody object.

CALLED BY:	INTERNAL UTILITTY

PASS:		ds	= segment of block with grobjects in it

RETURN:		ax	= GrObjDrawFlags

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetDrawFlagsFromBody	proc	far
	class	GrObjBodyClass
	uses	bx,si
	.enter
	
	mov	bx, offset GBI_drawFlags
	call	GrObjGetDWordFromBody
	mov_tr	ax, si
	
	.leave
	ret
GrObjGetDrawFlagsFromBody	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetSuspendCountFromBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the suspend count from the body

CALLED BY:	INTERNAL UTILITTY

PASS:		ds- segment of block with grobjects in it

RETURN:		
		cx - suspend count of body

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
	srs	3/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetSuspendCountFromBody		proc	far
	class	GrObjBodyClass
	uses	ax,bx,si
	.enter

	mov	bx,offset GBI_suspendCount
	call	GrObjGetDWordFromBody
	mov	cx,si					;suspend count

	.leave
	ret
GrObjGetSuspendCountFromBody		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMessageToBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to the body from a grobject
		(won't work if object is the body)

CALLED BY:	INTERNAL

PASS:		ds - block with graphic objects in it
		ax - message
		di - MessageFlags
		cx,dx,bp - other data for message

RETURN:		
		if no body return
			zero flag set
		else
			zero flag cleared
			if MF_CALL
				ax,cx,dx,bp
				no flags except carry
			otherwise 
				nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMessageToBody		proc	far
	uses	bx,si,di
	.enter

	mov	bx, ds:[OLMBH_output].handle
	tst	bx
	jz	done
	mov	si, ds:[OLMBH_output].chunk
EC <	call	ECGrObjBodyCheckLMemOD			>
	ornf	di, mask MF_FIXUP_DS
	call	ObjMessage

	ClearZeroFlagPreserveCarry	si

done:
	.leave
	ret
GrObjMessageToBody		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMessageToHead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to the graphic head

CALLED BY:	INTERNAL

PASS:		ds - block with graphic objects in it
		ax - message
		di - MessageFlags
		cx,dx,bp - other data for message

RETURN:		
		if MF_CALL
			ax,cx,dx,bp - from message handler

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMessageToHead		proc	far
	uses	bx,si,di
	.enter

	call	GrObjGetHeadOD
	ornf	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
GrObjMessageToHead		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMessageToGOAMText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to the text object associated with
		the attribute manager

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - object
		ax - message
		di - MessageFlags
		cx,dx,bp - other data for message

RETURN:		
		if MF_CALL
			ax,cx,dx,bp - from message handler

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
	srs	5/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMessageToGOAMText		proc	far
	uses	bx,si,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;    Get OD of text object from attribute manager
	;

	push	ax,cx,dx,di				;message, params
	mov	ax,MSG_GOAM_GET_TEXT_OD
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGOAM
	mov	bx,cx
	mov	si,dx
	pop	ax,cx,dx,di				;message, params

	;    Send original message to text object
	;

	ornf	di,mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
GrObjMessageToGOAMText		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMessageToRuler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to the ruler

CALLED BY:	INTERNAL

PASS:		ds - block with graphic objects in it
		ax - message
		di - MessageFlags
		cx,dx,bp - other data for message

RETURN:		
		if no ruler return
			zero flag set
		else
			zero flag cleared
			if MF_CALL
				ax,cx,dx,bp
				no flags except carry
			else
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
	srs	8/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMessageToRuler		proc	far
	uses	bx,si,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>


	call	GrObjGetRulerOD
	tst	bx
	jz	done
	ornf	di, mask MF_FIXUP_DS
	call	ObjMessage
done:
	.leave
	ret
GrObjMessageToRuler		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMessageToEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to object being edited

CALLED BY:	INTERNAL

PASS:		ds - block with graphic objects in it
		ax - message
		di - MessageFlags
		cx,dx,bp - other data for message

RETURN:		
		if no edit return
			zero flag set
		else
			zero flag cleared
			if MF_CALL
				ax,cx,dx,bp
				no flags except carry
			otherwise 
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
	srs	8/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMessageToEdit		proc	far
	uses	bx,si,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	GrObjGetEditOD
	tst	bx
	jz	done
	ornf	di, mask MF_FIXUP_DS
	call	ObjMessage

	;    Clear zero flag to signify message being sent
	;

	ClearZeroFlagPreserveCarry	si

done:
	.leave
	ret
GrObjMessageToEdit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMessageToMouseGrab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to object with mouse grab

CALLED BY:	INTERNAL

PASS:		ds - block with graphic objects in it
		ax - message
		di - MessageFlags
		cx,dx,bp - other data for message

RETURN:		
		if no mouse grab return
			zero flag set
		else
			zero flag cleared
			if MF_CALL
				ax,cx,dx,bp
				no flags except carry
			otherwise 
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
	srs	8/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMessageToMouseGrab		proc	far
	uses	bx,si,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	GrObjGetMouseGrabOD
	tst	bx
	jz	done
	ornf	di, mask MF_FIXUP_DS
	call	ObjMessage

	;    Clear zero flag to signify message being sent
	;

	ClearZeroFlagPreserveCarry	si

done:
	.leave
	ret
GrObjMessageToMouseGrab		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMessageToGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to the group

CALLED BY:	INTERNAL

PASS:		ds:si - object
		ax - message
		di - MessageFlags
		cx,dx,bp - other data for message

RETURN:		
		if MF_CALL
			ax,cx,dx,bp - from message handler

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		GrObjs within a group store the OD of  the group
		in their reverseLink


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMessageToGroup		proc	far
	class	GrObjClass
	uses	bx,si,di
	.enter

EC <	call	ECGrObjCheckLMemObject		>

	GrObjDeref	bx,ds,si

EC <	test	ds:[bx].GOI_optFlags, mask GOOF_IN_GROUP		>
EC <	ERROR_Z	OBJECT_NOT_IN_A_GROUP				>

	mov	si,ds:[bx].GOI_reverseLink.LP_next.chunk
	mov	bx,ds:[bx].GOI_reverseLink.LP_next.handle
	ornf	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
GrObjMessageToGroup		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetHeadOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the OD of the graphic head from the body

CALLED BY:	INTERNAL

PASS:		
		ds - segment of object block

RETURN:		
		^lbx:si - head od

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
GrObjGetHeadOD		proc	near
	uses	ax
	.enter

	mov	bx,offset GBI_head
	call	GrObjGetDWordFromBody
	mov_tr	bx,ax					;head handle

	.leave
	ret
GrObjGetHeadOD		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetMouseGrabOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the OD of the object with the mouse grab from the body

CALLED BY:	INTERNAL

PASS:		
		ds - segment of object block

RETURN:		
		^lbx:si - mouse grab

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
GrObjGetMouseGrabOD		proc	near
	uses	ax
	.enter

	mov	bx,offset GBI_mouseGrab
	call	GrObjGetDWordFromBody
	jc	noBody
	mov	bx,ax					;edit handle

done:
	.leave
	ret
noBody:
	clr 	bx
	jmp	done	

GrObjGetMouseGrabOD		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetRulerOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the OD of the ruler from the body

CALLED BY:	INTERNAL

PASS:		
		ds - segment of object block

RETURN:		
		^lbx:si - ruler od

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
	jon	8 jan 92	copied from GrObjGetHeadOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetRulerOD	proc	near
	uses	ax
	.enter

	mov	bx,offset GBI_ruler
	call	GrObjGetDWordFromBody
	mov_tr	bx,ax					;head handle

	.leave
	ret
GrObjGetRulerOD		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetEditOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the OD of the editable object from the body

CALLED BY:	INTERNAL

PASS:		
		ds - segment of object block

RETURN:		
		^lbx:si - edit od or bx = 0 and si destroyed

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetEditOD		proc	far
	uses	ax
	.enter

	;    If the body does not have both targets then
	;    we really don't have an edit grab
	;

	mov	bx,offset GBI_targetExcl.HG_flags
	call	GrObjGetDWordFromBody
	test 	si,mask HGF_SYS_EXCL or mask HGF_APP_EXCL
	jz	noEdit
	jpo  	noEdit

	mov	bx,offset GBI_targetExcl.HG_OD
	call	GrObjGetDWordFromBody
	jc	noEdit					;jmp if no body
	mov	bx,ax					;edit handle

done:
	.leave
	ret
noEdit:
	clr 	bx
	jmp	done	

GrObjGetEditOD		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetParentGStateStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	GrObj needs a gstate with the PARENT transformation in it.
		This means the body translation plus the transformations from
		all the groups above it. 
		The object has been passed a value that must either be
		zero or a gstate. If the value is zero, create a PARENT_GSTATE.
		If the value is non-zero, assume it is a gstate and push
		its transform. 

		This routine manipulates the stack and places two values
		above the return address. At the offset of the return 
		segment + 2 is either 0 or the pushed gstate handle. At the
		offset of the return segment +4 is either 0 or the 
		created gstate handle.

		The routine GrObjGetGStateEnd reads in both these values
		and either pops the transform or destroys the created
		gstate.

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object
		di - gstate or 0
	
RETURN:		
		di - gstate

DESTROYED:	
		none

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This routine must be used in conjunction with
		GrObjGetGStateEnd because it dorks with the stack.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModifiedStackData	struct
	MSD_bp			word
	MSD_bx			word
	MSD_offset		word
	MSD_segment		word
	MSD_pushedGState	hptr
	MSD_createdGState	hptr
ModifiedStackData	ends

ExtraSpaceOnStack = size ModifiedStackData - (offset MSD_segment + size MSD_segment)

GrObjGetParentGStateStart		proc	far call
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;    Make room above the return address in the stack to store
	;    the soon to be created gstate
	;

	sub	sp,ExtraSpaceOnStack
	push	ax,bp						;into MSD
	mov	bp,sp						;base of MSD
	mov	ax,ss:[bp].[MSD_offset + ExtraSpaceOnStack]	;return offset
	mov	ss:[bp].MSD_offset,ax				;return offset
	mov	ax,ss:[bp].[MSD_segment + ExtraSpaceOnStack]	;return segment
	mov	ss:[bp].MSD_segment,ax				;return segment
	tst	di						;passed gstate
	je	create

EC <	call	ECCheckGStateHandle				>
	call	GrSaveTransform
	clr	ax					;no created gstate

store:
	;    Put pushed gstate or 0 and created gstate or 0 on stack
	;

	mov	ss:[bp].MSD_pushedGState,di
	mov	ss:[bp].MSD_createdGState,ax

	;    Make sure that the one, true gstate ends up in di
	;

	tst	ax
	jz	done
	mov_tr	di,ax
done:
	pop	ax,bp

	.leave
	retf

create:
	;    Create a parent gstate for object
	;

	mov	di, PARENT_GSTATE
	call	GrObjCreateGState
	mov_tr	ax,di				;created gstate
	clr	di				;no pushed gstate
	jmp	store

GrObjGetParentGStateStart		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetBodyGStateStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	GrObj needs a BODY_GSTATE gstate. 
		This means the body translation but not any of the 
		transformations from all the groups above it. 
		The object has been passed a value that must either be
		zero or a gstate. If the value is zero, create a BODY_GSTATE.
		If the value is non-zero, assume it is a gstate and push
		its transform. 

		This routine manipulates the stack and places two values
		above the return address. At the offset of the return 
		segment + 2 is either 0 or the pushed gstate handle. At the
		offset of the return segment +4 is either 0 or the 
		created gstate handle.

		The routine GrObjGetGStateEnd reads in both these values
		and either pops the transform or destroys the created
		gstate.

		
CALLED BY:	INTERNAL

PASS:		
		*ds:si - object
		di - gstate or 0
	
RETURN:		
		di - gstate

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This routine must be used in conjunction with
		GrObjGetGStateEnd because it dorks with the stack.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetBodyGStateStart		proc	far call
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;    Make room above the return address in the stack to store
	;    the soon to be created gstate
	;

	sub	sp,ExtraSpaceOnStack
	push	ax,bp						;into MSD
	mov	bp,sp						;base of MSD
	mov	ax,ss:[bp].[MSD_offset + ExtraSpaceOnStack]	;return offset
	mov	ss:[bp].MSD_offset,ax				;return offset
	mov	ax,ss:[bp].[MSD_segment + ExtraSpaceOnStack]	;return segment
	mov	ss:[bp].MSD_segment,ax				;return segment
	tst	di						;passed gstate
	jz	create

EC <	call	ECCheckGStateHandle				>
	call	GrSaveTransform
	clr	ax					;no created gstate

store:
	;    Put pushed gstate or 0 and created gstate or 0 on stack
	;

	mov	ss:[bp].MSD_pushedGState,di
	mov	ss:[bp].MSD_createdGState,ax

	;    Make sure that the one, true gstate ends up in di
	;

	tst	ax
	jz	done
	mov_tr	di,ax
done:
	pop	ax,bp

	.leave
	retf

create:
	;    Create a body gstate for object
	;

	mov	di, BODY_GSTATE
	call	GrObjCreateGState
	mov_tr	ax,di				;created gstate
	clr	di				;no pushed gstate
	jmp	store

GrObjGetBodyGStateStart		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetGStateEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up the gstate info that has been placed on the
		stack by either GrObjGetBodyGStateStart or 
		GrObjGetParentGStateStart.

		Two values have been placed on the stack, only one
		of them is actually a gstate, the other is zero.
		
		Depending on which is gstate either pop transform or
		destroy gstate.


CALLED BY:	INTERNAL	

PASS:		
		gstate arguments

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		WARNING: This routine must be used in conjunction with
		GrObjGetBodyGStateStart or GrObjGetParentGStateStart
		because it dorks with the stack.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetGStateEnd		proc	far	call \
	pushedGState:hptr,
	createdGState:hptr
	uses	di
	.enter

	mov	di,pushedGState
	tst	di
	jz	destroy

EC <	tst	createdGState					>
EC <	ERROR_NZ	STACK_HAS_BEEN_HOSED_BY_OBJECT_GET_GSTATE >
	call	GrRestoreTransform

done:
	.leave
	ret	@ArgSize

destroy:
	mov	di,createdGState
	call	GrDestroyState
	jmp	short done

GrObjGetGStateEnd		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetCurrentHandleSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current width and height of handle size

CALLED BY:	INTERNAL

PASS:		
		ds - segment of object block

RETURN:		
		ax - max line width
		bl - current handle width
		bh - current handle height

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
GrObjGetCurrentHandleSize		proc	far
	uses	si
	.enter

	mov	bx,offset GBI_curHandleWidth
	call	GrObjGetDWordFromBody
	mov	bx,si					;handle size

	.leave
	ret
GrObjGetCurrentHandleSize		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetDesiredHandleSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the desired width and height of handle size

CALLED BY:	INTERNAL

PASS:		
		ds - segment of object block

RETURN:		
		bl - desired handle size

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
GrObjGetDesiredHandleSize		proc	far
	uses	si
	.enter

	mov	bx,offset GBI_desiredHandleSize
	call	GrObjGetDWordFromBody
	mov	bx,si					;handle size

	.leave
	ret
GrObjGetDesiredHandleSize		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetCurrentNudgeUnits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current nudge values. These represent the
		number of points that currently equal one screen pixel
		in x and y

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		ds - segment of object block

RETURN:		
		ax - curNudgeX in BBFixed
		bx - curNudgeY in BBFixed

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
GrObjGetCurrentNudgeUnits		proc	far
	uses	si
	.enter

CheckHack < (offset GBI_curNudgeY - offset GBI_curNudgeX) eq 2>
	mov	bx,offset GBI_curNudgeX
	call	GrObjGetDWordFromBody
	mov	bx,si					;handle size

	.leave
	ret
GrObjGetCurrentNudgeUnits		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetCurrentNudgeUnitsWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current nudge values. These represent the
		number of points that currently equal one screen pixel
		in x and y

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		ds - segment of object block

RETURN:		
		dx:cx - curNudgeX in WWFixed
		bx:ax - curNudgeY in WWFixed

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
GrObjGetCurrentNudgeUnitsWWFixed		proc	far
	.enter

	call	GrObjGetCurrentNudgeUnits
	clr	cl					;x frac low byte
	mov	ch,al					;x frac high byte
	mov	al,ah					;x int low byte
	cbw						;sign extend x int low 
	mov	dx,ax					;x int
	mov	al,bh					;y int low byte
	cbw						;sign extend y int low
	xchg	bx,ax					;y int, y frac high byte
	mov	ah,al					;y frac high byte
	clr	al					;y frac low byte

	.leave
	ret
GrObjGetCurrentNudgeUnitsWWFixed		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSendActionNotificationViaBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to send the action notification using the
		GrObjActionNoticificationStruct in the body's vardata.
		If no such vardata exists then do nothing

CALLED BY:	INTERNAL 
		GrObjSendActionNotification

PASS:		
		*ds:si - GrObject
		bp - GrObjActionNotificationType

RETURN:		
		bp - based on GrObjActionNotificationType
		     GOANT_PRE_DELETE - zero to abort the deletion
		
		ds - Fixed up so that it is pointing at the same block
		     as was passed in. 
		     
		     You should not save segment registers around calls to
		     this routine unless you are certain that the block
		     containing the object won't move as part of the
		     notification (not always a safe assumption).

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
	srs	2/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSendActionNotificationViaBody		proc	far
	class	GrObjClass
	uses	ax,bx,cx,dx,si
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	;    The attribute manager is not permitted to send
	;    notifications via the body, because it is not
	;    guaranteed to be in a block with a BodyKeeper.
	;

	test	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER
	jnz	done

	;    OD of object sending notification
	;

	mov	cx,ds:[LMBH_handle]
	mov	dx,si

	;    Get body od
	;

	GrObjGetBodyOD

	;    Lock the body and look for the var data
	;

	push	cx					;object block
	push	bx					;body block
	call	ObjLockObjBlock
	mov	ds,ax					;body segment
	.warn	-private
	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	test	ds:[di].GBI_flags,mask GBF_HAS_ACTION_NOTIFICATION
	.warn	+private
	jz	unlock

	mov	ax,ATTR_GB_ACTION_NOTIFICATION
	call	ObjVarFindData
EC <	ERROR_NC GROBJ_BODY_HAS_NO_ACTION_NOTIFICATION_BUT_BIT_IS_SET >

	tst	ds:[bx].GOANS_suspendCount
	jnz	unlock

	;    Send the notification
	;

	mov	ax,MSG_GROBJ_ACTION_NOTIFICATION
	mov	si,ds:[bx].GOANS_optr.chunk
	mov	bx,ds:[bx].GOANS_optr.handle
	mov	di,mask MF_FIXUP_DS or mask MF_CALL	;so we can get BP
	call	ObjMessage
	
unlock:
	pop	bx					;body block
	call	MemUnlock				;body
	pop	bx					;object block
	call	MemDerefDS				;fixup object segment
done:
	.leave
	ret
GrObjSendActionNotificationViaBody		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjActionNotificationSuspendedInBody?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the action notification has been
		suspended in the body

CALLED BY:	INTERNAL
		GrObjSendActionNotification

PASS:		
		*ds:si - GrObject

RETURN:		
		stc - suspended
		clc - not suspend

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
	srs	3/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjActionNotificationSuspendedInBody?		proc	far
	class	GrObjClass
	uses	ax,bx,cx,dx,ds,si,di
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	;    The attribute manager is not permitted to send
	;    notifications via the body, because it is not
	;    guaranteed to be in a block with a BodyKeeper.
	;

	test	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER
	jnz	suspended

	;    OD of object sending notification
	;

	mov	cx,ds:[LMBH_handle]
	mov	dx,si

	;    Get body od
	;

	GrObjGetBodyOD

	;    Lock the body and look for the var data
	;

	push	bx					;body block
	call	ObjLockObjBlock
	mov	ds,ax					;body segment
	.warn	-private
	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	test	ds:[di].GBI_flags,mask GBF_HAS_ACTION_NOTIFICATION
	.warn	+private
	jz	notSuspended
	
	mov	ax,ATTR_GB_ACTION_NOTIFICATION
	call	ObjVarFindData
EC <	ERROR_NC GROBJ_BODY_HAS_NO_ACTION_NOTIFICATION_BUT_BIT_IS_SET >

	tst	ds:[bx].GOANS_suspendCount
	jnz	suspended

notSuspended:
	clc
unlock:
	pop	bx					;body block
	call	MemUnlock				;body

	.leave
	ret

suspended:
	stc
	jmp	unlock

GrObjActionNotificationSuspendedInBody?		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCreateGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a gstate with all the appropriate body and group
		transformations in it.

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object that wants gstate
		di - GrObjCreateGStateType

RETURN:		
		di - gstate

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCreateGState		proc	far
	class	GrObjClass
	uses	ax,bp, cx
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	cx, di				;cx <- GrObjCreateGStateTypes

	;    If caller just wants body translation, the skip to
	;    calling body
	;

CheckHack< BODY_GSTATE eq 0>
	jcxz	body

	;    Check for object in group, if so jump to gup for gstate
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags,mask GOOF_IN_GROUP
	jnz	gupForGState

body:
	call	GrObjCreateBodyGState

checkGrObj:
	mov	di,bp				;gstate
	cmp	cx, OBJECT_GSTATE
	jne	done


	;    If the NORMAL transform doesn't exist (it should, but hey...)
	;    then return the "best" GState we can.
	;

	GrObjDeref	bp,ds,si
	mov	bp, ds:[bp].GOI_normalTransform
	tst	bp
	jz	done

	call	GrObjApplyNormalTransform
	
done:

	.leave
	ret

gupForGState:
	mov	ax,MSG_GROUP_CREATE_GSTATE
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToGroup
	jmp	checkGrObj
GrObjCreateGState		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCreateBodyGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the body and call its gstate create routine.
		Yes, this is hack for speed purposes

CALLED BY:	INTERNAL
		GrObjCreateGState

PASS:		ds - grobject block

RETURN:		
		bp - gstate

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
	srs	8/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCreateBodyGState		proc	near
	uses	ax,bx,si,ds
	.enter

	GrObjGetBodyOD

	push	bx					;body block
	call	ObjLockObjBlock
	mov	ds,ax

	call	GrObjBodyCreateGState

	pop	bx					;body block
	call	MemUnlock

	.leave
	ret
GrObjCreateBodyGState		endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GrObjFreeObjectAppropriately

DESCRIPTION:	I believe that the floater can still have messages in the
		queue at this point, but no other grobjects can.
	
		

CALLED BY:	INTERNAL

PASS:
	*ds:si - object

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/21/92		Initial version

------------------------------------------------------------------------------@
GrObjFreeObjectAppropriately	proc	far	
	uses	ax,cx,dx,bp,di
	class	GrObjClass
	.enter

	mov	ax,MSG_META_OBJ_FREE			;assume
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER
	jnz	common
	mov	ax, MSG_GO_OBJ_FREE
common:
	call	ObjCallInstanceNoLock

	.leave
	ret

GrObjFreeObjectAppropriately	endp


GrObjAlmostRequiredCode	ends
