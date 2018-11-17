COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Admin	
FILE:		objectAttrMgr.asm

AUTHOR:		Steve Scholl, Jan 30, 1992

ROUTINES:
	Name	
	----	
GrObjAttributeManagerCreateGrObjArrays
GrObjAttributeManagerCreateTextArrays
GrObjAttributeManagerCreateTextObject		
GrObjAttributeManagerAttachAndCreateTextArrays	
GrObjAttributeManagerGetAttrElement
GrObjAttributeManagerAddAttrElement
GrObjAttributeManagerDerefAttrElementToken
GrObjAttributeManagerAddRefAttrElementToken
GrObjAttributeManagerAttachMemBlock
GrObjAttributeManagerMessageToText
GrObjAttributeManagerSearchBodyList
GrObjAttributeManagerSearchBodyListCB
GrObjAttributeManagerRelocBodyList
GrObjAttributeManagerRelocBodyListCB
GrObjAttributeManagerBodyListEnum

METHODS:
	Name	
	----	
GrObjAttributeManagerAttachBody
GrObjAttributeManagerDetachBody
GrObjAttributeManagerInitialize
GrObjAttributeManagerCreateAllArrays
GrObjAttributeManagerAttachAndCreateArrays
GrObjAttributeManagerGetGrObjFullAreaAttrElement
GrObjAttributeManagerGetGrObjFullLineAttrElement
GrObjAttributeManagerAddGrObjBaseAreaAttrElement
GrObjAttributeManagerAddGrObjBaseLineAttrElement
GrObjAttributeManagerDerefGrObjBaseAreaAttrElementToken
GrObjAttributeManagerDerefGrObjBaseLineAttrElementToken
GrObjAttributeManagerAddRefGrObjBaseAreaAttrElementToken
GrObjAttributeManagerAddRefGrObjBaseLineAttrElementToken
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	1/30/92		Initial revision


DESCRIPTION:
	
		

	$Id: attrMgr.asm,v 1.1 97/04/04 18:07:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

;
; Basicly a hack to avoid FIXUP_ES dying when es is the segment of the
; class structure.
;
classStructuresHandle	hptr	handle GrObjClassStructures
ForceRef classStructuresHandle

GrObjAttributeManagerClass		;Define the class record

GrObjClassStructures	ends


GrObjInitCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GOAMSendUINotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GOAM method for MSG_GO_SEND_UI_NOTIFICATION

Called by:	

Pass:		*ds:si = GOAM object
		ds:di = GOAM instance

		cx - GrObjUINotificationTypes

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GOAMSendUINotification		method dynamic	GrObjAttributeManagerClass,
				MSG_GO_SEND_UI_NOTIFICATION
	.enter

	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di

	mov	ax, MSG_GB_UPDATE_UI_CONTROLLERS
	mov	di, mask MF_FIXUP_DS
	call	GOAMMessageToBodyList

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret
GOAMSendUINotification	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GOAMCombineSelectionStateNotificationData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GOAM method MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA
		This message is subclassed because the GOAM should never
		be "selected", but we still want to know its locks.

Pass:		*ds:si = GOAM object
		ds:di = GOAM instance

		^hcx = GrObjNotifySelectionStateChange struct

Return:		carry clear

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr  1, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GOAMCombineSelectionStateNotificationData	method dynamic	GrObjAttributeManagerClass, MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA
	.enter

	mov	bx, cx
	call	MemLock
	jc	done
	GrObjDeref	di,ds,si
	mov	es, ax
	mov	ax, ds:[di].GOI_locks
	mov	es:[GONSSC_selectionState].GSS_locks, ax
	mov	ax, ds:[di].GOI_attrFlags
	mov	es:[GONSSC_selectionState].GSS_grObjFlags, ax
	clr	ax
	mov	es:[GONSSC_selectionStateDiffs], al
	mov	es:[GONSSC_grObjFlagsDiffs], ax
	mov	es:[GONSSC_locksDiffs], ax
	mov	es:[GONSSC_selectionState].GSS_numSelected, ax
	call	MemUnlock
done:
	.leave
	ret

GOAMCombineSelectionStateNotificationData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GOAMSubstTextAttrToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjAttributeManager method for MSG_GOAM_SUBST_TEXT_ATTR_TOKEN

		Sends a MSG_VIS_TEXT_SUBST_ATTR_TOKEN with the passed
		structure to each of the body's grobj texts.

Pass:		*ds:si = GOAM object
		ds:di = GOAM instance

		ss:[bp] - VisTextSubstAttrTokenParams

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GOAMSubstTextAttrToken	method dynamic	GrObjAttributeManagerClass,
				MSG_GOAM_SUBST_TEXT_ATTR_TOKEN
	.enter

	mov	ss:[bp].VTSATP_relayedToLikeTextObjects, ax	;non-zero
	mov	ax, MSG_GB_SUBST_TEXT_ATTR_TOKEN
	mov	di, mask MF_FIXUP_DS
	call	GOAMMessageToBodyList

	mov	ax, MSG_VIS_TEXT_SUBST_ATTR_TOKEN
	clr	di
	call	GrObjAttributeManagerMessageToText

	.leave
	ret
GOAMSubstTextAttrToken	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GOAMRecalcForTextAttrChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjAttributeManager method for MSG_GOAM_RECALC_FOR_TEXT_ATTR_CHANGE

		Sends a MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE
		to each of the body's grobj texts.

Pass:		*ds:si = GOAM object
		ds:di = GOAM instance

		cx - nonzero if relayed to all text objects

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GOAMRecalcForTextAttrChange	method dynamic	GrObjAttributeManagerClass,
				MSG_GOAM_RECALC_FOR_TEXT_ATTR_CHANGE
	uses	cx
	.enter

	mov_tr	cx, ax					;non-zero
	mov	ax, MSG_GB_RECALC_FOR_TEXT_ATTR_CHANGE
	mov	di, mask MF_FIXUP_DS
	call	GOAMMessageToBodyList

	.leave
	ret
GOAMRecalcForTextAttrChange	endm

GrObjInitCode	ends

GrObjStyleSheetCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjAttributeManagerInvalidateBodies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjAttributeManager method for MSG_GOAM_INVALIDATE_BODIES

Called by:	

Pass:		*ds:si = GrObjAttributeManager object
		ds:di = GrObjAttributeManager instance

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerInvalidateBodies	method dynamic	GrObjAttributeManagerClass, MSG_GOAM_INVALIDATE_BODIES
	uses	ax
	.enter

	mov	ax, MSG_GB_INVALIDATE
	mov	di, mask MF_FIXUP_DS		
	call	GOAMMessageToBodyList

	.leave
	ret
GrObjAttributeManagerInvalidateBodies	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerSubstAreaToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjAttributeManager method for MSG_GOAM_SUBST_AREA_TOKEN

		Inform all the GrObjBodys in the GOAM's list that any GrObjs
		with the passed "old" token should replace it with the new one,
		updating the reference count if specified.

Called by:	

Pass:		*ds:si = GrObjAttributeManager object
		ds:di = GrObjAttributeManager instance

		cx - old area token
		dx - new area token
		bp - nonzero if GrObjs should update reference counts
			to both the old and new tokens

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerSubstAreaToken  method dynamic GrObjAttributeManagerClass,
				     MSG_GOAM_SUBST_AREA_TOKEN

	mov	ax, MSG_GB_SUBST_AREA_TOKEN
	mov	di, mask MF_FIXUP_DS
	call	GOAMMessageToBodyList

	mov	ax, MSG_GO_SUBST_AREA_TOKEN
	mov	di, offset GrObjAttributeManagerClass
	GOTO	ObjCallSuperNoLock

GrObjAttributeManagerSubstAreaToken	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerSubstLineToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjAttributeManager method for MSG_GOAM_SUBST_LINE_TOKEN

		Inform all the GrObjBodys in the GOAM's list that any GrObjs
		with the passed "old" token should replace it with the new one,
		updating the reference count if specified.

Called by:	

Pass:		*ds:si = GrObjAttributeManager object
		ds:di = GrObjAttributeManager instance

		cx - old line token
		dx - new line token
		bp - nonzero if GrObjs should update reference counts
			to both the old and new tokens

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerSubstLineToken  method dynamic GrObjAttributeManagerClass,
				     MSG_GOAM_SUBST_LINE_TOKEN

	mov	ax, MSG_GB_SUBST_LINE_TOKEN
	mov	di, mask MF_FIXUP_DS
	call	GOAMMessageToBodyList

	mov	ax, MSG_GO_SUBST_LINE_TOKEN
	mov	di, offset GrObjAttributeManagerClass
	GOTO	ObjCallSuperNoLock

GrObjAttributeManagerSubstLineToken	endm

GrObjStyleSheetCode	ends

GrObjInitCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerAttachBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add passed body to body list

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass

		^lcx:dx - body to add to list
RETURN:		
		carry set if body not added to list
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	6 may 1992	Initial version
	steve	6/10/92		Won't add duplicates

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerAttachBody	  method dynamic GrObjAttributeManagerClass,
				  MSG_GOAM_ATTACH_BODY
	.enter

	tst	ds:[di].GOAMI_bodyList
	jz	createArray

addBody:
	call	GrObjAttributeManagerSearchBodyList
	jc	done

	;
	;	Append a new body
	;

	GOAMDeref	di,ds,si
	mov	si,ds:[di].GOAMI_bodyList
	call	ChunkArrayAppend
	mov	ds:[di].handle, cx
	mov	ds:[di].offset, dx

done:
	.leave
	ret

createArray:
	call	GOAMCreateBodyArray
	jmp	addBody

GrObjAttributeManagerAttachBody	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerBodyListEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do ChunkArrayEnum on BodyList

CALLED BY:	INTERNAL
		GrObjAttributeManagerBodySearchBodyList
		GrObjAttributeManagerBodyRelocBodyList

PASS:		*ds:si - GrObjAttributeManager
		bx:di - call back routine
		(For XIP'ed geode, the call back routine *must* be in the
		same segment of this routine; otherwise, we can't pass the
		callback to the ChunkArrayEnum() called by this routine.
		So it means you only need to pass the offset of the callback
		in di, and bx can be trash.)
		ax,cx,dx,bp - data to pass to call back routine

RETURN:		
		ax,cx,dx,bp,es, carry flags - set by call routine

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerBodyListEnum		proc	far
	class	GrObjAttributeManagerClass
	uses	si
	.enter

;	DON'T call ECGrObjAttributeManagerCheckLMemObject here because this 
;	routine can be called during unrelocation.
;
;	GOAMDeref	si,ds,si
;
	mov	si, ds:[si]
	add	si, ds:[si].GrObjAttributeManager_offset

	mov	si,ds:[si].GOAMI_bodyList
	tst	si
	jz	done
FXIP <	mov	bx, cs			;bx = callback segment	>
	call	ChunkArrayEnum
done:
	.leave
	ret
GrObjAttributeManagerBodyListEnum		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerSearchBodyList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search the body list for the passed body.

CALLED BY:	INTERNAL
		GrObjAttributeManagerAttachBody
		GrObjAttributeManagerDetachBody

PASS:		*ds:si - GrObjAttributeManager
		cx:dx - body od to search for

RETURN:		
		stc - found
			ds:di - element
		clc - not found
			di - destroyed

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			Adding new body so body won't be in list

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerSearchBodyList		proc	near	
	uses ax,bx
	.enter

EC <	call	ECGrObjAttributeManagerCheckLMemObject		>
	;
	; we don't pass vfptr (for XIP) because this callback will be passed
	; into ChunkArrayEnum() which takes fptr, *not* vfptr
	;
NOFXIP<	mov	bx, cs						>
	mov	di, offset GrObjAttributeManagerSearchBodyListCB
	call	GrObjAttributeManagerBodyListEnum
	mov_tr	di, ax

	.leave
	ret
GrObjAttributeManagerSearchBodyList		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerSearchBodyListCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ChunkArrayEnum call back routine. Compares current element
		with passed body OD

CALLED BY:	ChunkArrayEnum

PASS:		
		*ds:si - body list chunk array
		ds:di - element
		cx:dx - body to find od

RETURN:		
		stc - found
			ds:ax - element
		clc - not found
			ax - destroyed
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			fail

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerSearchBodyListCB		proc	far
	.enter

	cmp	cx,ds:[di].handle
	jne	fail
	cmp	dx,ds:[di].chunk
	je	found

fail:
	clc
done:
	.leave
	ret

found:
	mov_tr	ax, di			;return offset in ax
	stc
	jmp	done


GrObjAttributeManagerSearchBodyListCB		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerDetachBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove body from body list

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass

		^lcx:dx - body to detach

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
	srs	6/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerDetachBody	method dynamic GrObjAttributeManagerClass, 
						MSG_GOAM_DETACH_BODY
	.enter

EC <	tst	ds:[di].GOAMI_bodyList				>
EC <	ERROR_Z	GROBJ_GOAM_HAS_NO_BODY_LIST_TO_DETACH_BODY_FROM >

	call	GrObjAttributeManagerSearchBodyList
EC <	ERROR_NC GROBJ_GOAM_CANT_DETACH_BODY_NOT_IN_BODY_LIST 	>

	GOAMDeref	si,ds,si
	mov	si,ds:[si].GOAMI_bodyList
	call	ChunkArrayDelete

	.leave
	ret
GrObjAttributeManagerDetachBody		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GOAMCreateBodyArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Allocate memory for keeping track of multiple body ODs.

Pass:		*ds:si - GrObjAttributeManager

Return:		nothing

Destroyed:	nothing

Comments:	
		none

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 27, 1992 	Initial version.
	steve	6/10/92		Moved chunk array into goam's block
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GOAMCreateBodyArray		proc	near
	class	GrObjAttributeManagerClass
	uses	ax,bx,cx,dx,di
	.enter

EC<	call	ECGrObjAttributeManagerCheckLMemObject		>

	push	si				;goam chunk
	clr	al				;ObjChunkFlags
	mov	bx, size optr			;element size
	clr	cx				;default header size
	mov	si,cx				;alloc new chunk handle
	call	ChunkArrayCreate
	mov_tr	ax, si				;chunk array chunk
	pop	si				;goam chunk
	
	GOAMDeref	di,ds,si
	mov	ds:[di].GOAMI_bodyList,ax

	call	ObjMarkDirty

	.leave
	ret
GOAMCreateBodyArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initalize object to match default in grobj.uih

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass

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
	srs	1/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerInitialize	method dynamic	GrObjAttributeManagerClass,
				MSG_META_INITIALIZE
	.enter

	mov	di,offset GrObjAttributeManagerClass
	call	ObjCallSuperNoLock

	GrObjDeref	di,ds,si

	;  Indicate that we are the GOAM
	;

	ornf	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER

	ornf	ds:[di].GOI_attrFlags, mask GOAF_INSERT_DELETE_MOVE_ALLOWED or \
				mask GOAF_INSERT_DELETE_RESIZE_ALLOWED or \
				mask GOAF_INSERT_DELETE_DELETE_ALLOWED

	;  Set all locks *except* the attribute lock
	;

	ornf	ds:[di].GOI_locks, mask GrObjLocks or not mask GOL_ATTRIBUTE

if (GROBJ_DEFAULT_WRAP_TYPE ne 0)
	; Currently, GROBJ_DEFAULT_WRAP_TYPE = GOWTT_DONT_WRAP = 0.
	; Thus, this instruction serves no purpose and causes a compiler
	; warning.  So, only do it if it is useful. -JimG 7/1/94
	
	ornf	ds:[di].GOI_attrFlags, 
				GROBJ_DEFAULT_WRAP_TYPE shl offset GOAF_WRAP
endif

 	BitSet	ds:[di].GOI_msgOptFlags, GOMOF_SEND_UI_NOTIFICATION

	.leave
	ret
GrObjAttributeManagerInitialize		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerCreateAllArrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create all arrays necessary for managing attributes

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass

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
	srs	1/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerCreateAllArrays	method dynamic \
			GrObjAttributeManagerClass, MSG_GOAM_CREATE_ALL_ARRAYS
	uses	ax,cx,dx,bp
	.enter

	;    Pass all zeros to MSG_GOAM_ATTACH_AND_CREATE_ARRAYS
	;

	sub	sp, size GrObjAttributeManagerArrayDesc
	mov	bp,sp
	segmov	es,ss
	mov	di,bp
	clr	ax
	StoreConstantNumBytes	<size GrObjAttributeManagerArrayDesc>, cx
	mov	ax,MSG_GOAM_ATTACH_AND_CREATE_ARRAYS
	call	ObjCallInstanceNoLock
	add	sp,size GrObjAttributeManagerArrayDesc

	.leave
	ret
GrObjAttributeManagerCreateAllArrays		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerAttachAndCreateArrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use the passed arrays for storing attributes and
		create the ones not passed.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass
		
		ss:bp - GrObjAttributeManagerArrayDesc
		For the three grobj arrays you must either pass all
		three arrays or all three as 0
		For the three text arrays you must either pass all
		three arrays or all three as 0
		

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
	srs	1/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerAttachAndCreateArrays	method dynamic \
		GrObjAttributeManagerClass, MSG_GOAM_ATTACH_AND_CREATE_ARRAYS
	uses	ax,cx
	.enter

if	ERROR_CHECK
	tst	ss:[bp].GOAMAD_areaAttrArrayHandle		
	jz	checkAllGrObjZero
	tst	ss:[bp].GOAMAD_lineAttrArrayHandle		
	ERROR_Z	GROBJ_ATTRIBITE_MANAGER_REQUIRES_THREE_ATTRIBUTE_ARRAYS
	tst	ss:[bp].GOAMAD_grObjStyleArrayHandle		
	ERROR_Z	GROBJ_ATTRIBITE_MANAGER_REQUIRES_THREE_ATTRIBUTE_ARRAYS
	jmp	checkTextArrays
checkAllGrObjZero:
	tst	ss:[bp].GOAMAD_lineAttrArrayHandle		
	ERROR_NZ	GROBJ_ATTRIBITE_MANAGER_REQUIRES_THREE_ATTRIBUTE_ARRAYS
	tst	ss:[bp].GOAMAD_grObjStyleArrayHandle		
	ERROR_NZ	GROBJ_ATTRIBITE_MANAGER_REQUIRES_THREE_ATTRIBUTE_ARRAYS
checkTextArrays:
	tst	ss:[bp].GOAMAD_charAttrArrayHandle		
	jz	checkAllTextZero
	tst	ss:[bp].GOAMAD_paraAttrArrayHandle
	ERROR_Z	GROBJ_ATTRIBITE_MANAGER_REQUIRES_THREE_ATTRIBUTE_ARRAYS
	tst	ss:[bp].GOAMAD_typeArrayHandle
	ERROR_Z	GROBJ_ATTRIBITE_MANAGER_REQUIRES_THREE_ATTRIBUTE_ARRAYS
	tst	ss:[bp].GOAMAD_graphicArrayHandle
	ERROR_Z	GROBJ_ATTRIBITE_MANAGER_REQUIRES_THREE_ATTRIBUTE_ARRAYS
	tst	ss:[bp].GOAMAD_nameArrayHandle
	ERROR_Z	GROBJ_ATTRIBITE_MANAGER_REQUIRES_THREE_ATTRIBUTE_ARRAYS
	tst	ss:[bp].GOAMAD_textStyleArrayHandle
	ERROR_Z	GROBJ_ATTRIBITE_MANAGER_REQUIRES_THREE_ATTRIBUTE_ARRAYS
	jmp	doneError
checkAllTextZero:
	tst	ss:[bp].GOAMAD_paraAttrArrayHandle
	ERROR_NZ	GROBJ_ATTRIBITE_MANAGER_REQUIRES_THREE_ATTRIBUTE_ARRAYS
	tst	ss:[bp].GOAMAD_typeArrayHandle
	ERROR_NZ	GROBJ_ATTRIBITE_MANAGER_REQUIRES_THREE_ATTRIBUTE_ARRAYS
	tst	ss:[bp].GOAMAD_graphicArrayHandle
	ERROR_NZ	GROBJ_ATTRIBITE_MANAGER_REQUIRES_THREE_ATTRIBUTE_ARRAYS
	tst	ss:[bp].GOAMAD_nameArrayHandle
	ERROR_NZ	GROBJ_ATTRIBITE_MANAGER_REQUIRES_THREE_ATTRIBUTE_ARRAYS
	tst	ss:[bp].GOAMAD_textStyleArrayHandle
	ERROR_NZ	GROBJ_ATTRIBITE_MANAGER_REQUIRES_THREE_ATTRIBUTE_ARRAYS
doneError:
endif

	;    Be lazy and assume that the caller passed in
	;    the grobj arrays to use.
	;

	mov	ax,ss:[bp].GOAMAD_areaAttrArrayHandle
	mov	ds:[di].GOAMI_areaAttrArrayHandle,ax
	mov	ax,ss:[bp].GOAMAD_lineAttrArrayHandle
	mov	ds:[di].GOAMI_lineAttrArrayHandle,ax
	mov	ax,ss:[bp].GOAMAD_grObjStyleArrayHandle
	mov	ds:[di].GOAMI_grObjStyleArrayHandle,ax

	;    Also assume that the passed default grobj tokens 
	;    are valid.
	;

	mov	ax,ss:[bp].GOAMAD_areaDefaultElement
	mov	bx,ss:[bp].GOAMAD_lineDefaultElement
	
	;    Create the array if the area array handle is zero. Remember
	;    the caller must pass all or none of the arrays.
	;

	tst	ss:[bp].GOAMAD_areaAttrArrayHandle
	jnz	setDefaultGrObjTokens
	call	GrObjAttributeManagerCreateGrObjArrays

setDefaultGrObjTokens:
	;    Set the default tokens (either passed in or 
	;    returned from create arrays routine).
	;

	mov	cx,ax				;area token
	mov	ax,MSG_GO_SET_GROBJ_AREA_TOKEN
	call	ObjCallInstanceNoLock
	mov	cx,bx				;line token
	mov	ax,MSG_GO_SET_GROBJ_LINE_TOKEN
	call	ObjCallInstanceNoLock

	call	GrObjAttributeManagerAttachAndCreateTextArrays

	.leave
	ret
GrObjAttributeManagerAttachAndCreateArrays		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerAttachAndCreateTextArrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create text object is necessary.
		Use the passed arrays for storing attributes and
		create the ones not passed.

CALLED BY:	INTERNAL
		GrObjAttributeManagerAttachAndCreateArrays

PASS:		*ds:si - AttributeManager

		ss:bp - GrObjAttributeManagerArrayDesc
		For the three text arrays you must either pass all
		three arrays or all three as 0

RETURN:		
		GOAMI_charAttrArrayHandle - set
		GOAMI_paraAttrArrayHandle - set
		GOAMI_typeArrayHandle - set
		GOAMI_graphicArrayHandle - set
		GOAMI_nameArrayHandle - set
		GOAMI_textStyleArrayHandle - set

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
GrObjAttributeManagerAttachAndCreateTextArrays		proc	near
	class	GrObjAttributeManagerClass
	uses	ax,bx,cx,dx,bp
	.enter

EC <	call	ECGrObjAttributeManagerCheckLMemObject			>

	call	GrObjAttributeManagerCreateTextObject

	;    Be lazy and assume that the caller passed in
	;    the text arrays to use.
	;

	GOAMDeref	di,ds,si
	mov	ax,ss:[bp].GOAMAD_paraAttrArrayHandle
	mov	ds:[di].GOAMI_paraAttrArrayHandle,ax
	mov	ax,ss:[bp].GOAMAD_typeArrayHandle
	mov	ds:[di].GOAMI_typeArrayHandle,ax
	mov	ax,ss:[bp].GOAMAD_graphicArrayHandle
	mov	ds:[di].GOAMI_graphicArrayHandle,ax
	mov	ax,ss:[bp].GOAMAD_nameArrayHandle
	mov	ds:[di].GOAMI_nameArrayHandle,ax
	mov	ax,ss:[bp].GOAMAD_charAttrArrayHandle
	mov	ds:[di].GOAMI_charAttrArrayHandle,ax
	mov	ax,ss:[bp].GOAMAD_textStyleArrayHandle
	mov	ds:[di].GOAMI_textStyleArrayHandle,ax

	;    Also assume that the passed default text tokens 
	;    are valid.
	;

	mov	ax,ss:[bp].GOAMAD_charDefaultElement
	mov	bx,ss:[bp].GOAMAD_paraDefaultElement
	mov	cx,ss:[bp].GOAMAD_typeDefaultElement

	;    Create the array if the area array handle is zero. Remember
	;    the caller must pass all or none of the arrays.
	;

	tst	ss:[bp].GOAMAD_charAttrArrayHandle
	jnz	setDefaults
	call	GrObjAttributeManagerCreateTextArrays

setDefaults:
	;    Set the default tokens (either passed in or 
	;    returned from create arrays routine).

	push	cx					;save type token
	push	ax					;save char attr token

	; Do names and text styles first (trust me)

	mov	ax,MSG_VIS_TEXT_CHANGE_ELEMENT_ARRAY	;same message throughout

	GOAMDeref	di,ds,si
	mov	dx, ds:[di].GOAMI_nameArrayHandle
	mov	cl, VTSF_NAMES
	mov	di,mask MF_FIXUP_DS
	call	GrObjAttributeManagerMessageToText

	GOAMDeref	di,ds,si
	mov	dx, ds:[di].GOAMI_textStyleArrayHandle
	mov	cl, mask VTSF_STYLES
	mov	di,mask MF_FIXUP_DS
	call	GrObjAttributeManagerMessageToText

	GOAMDeref	di,ds,si
	mov	dx, ds:[di].GOAMI_charAttrArrayHandle
	mov	cl, mask VTSF_MULTIPLE_CHAR_ATTRS
	mov	ch,1					;dx is a vm block han
	pop	bp					;char token
	mov	di,mask MF_FIXUP_DS
	call	GrObjAttributeManagerMessageToText

	GOAMDeref	di,ds,si
	mov	dx,ds:[di].GOAMI_paraAttrArrayHandle
	mov	cl, mask VTSF_MULTIPLE_PARA_ATTRS
	mov	bp, bx					;para token
	mov	di,mask MF_FIXUP_DS
	call	GrObjAttributeManagerMessageToText

	GOAMDeref	di,ds,si
	mov	dx,ds:[di].GOAMI_typeArrayHandle
	mov	cl, mask VTSF_TYPES
	pop	bp					;type token
	mov	di,mask MF_FIXUP_DS
	call	GrObjAttributeManagerMessageToText

	GOAMDeref	di,ds,si
	mov	dx,ds:[di].GOAMI_graphicArrayHandle
	mov	cl, mask VTSF_GRAPHICS
	mov	di,mask MF_FIXUP_DS
	call	GrObjAttributeManagerMessageToText

	.leave
	ret
GrObjAttributeManagerAttachAndCreateTextArrays		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerCreateTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a text object to hold default text attributes
		if one hasn't already been created.

CALLED BY:	INTERNAL
		GrObjAttributeManagerAttachAndCreateTextArrays

PASS:		*ds:si - GrObjAttributeManager

RETURN:		GOAMI_text - set

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
GrObjAttributeManagerCreateTextObject		proc	near
	class	GrObjAttributeManagerClass
	uses	bx,di,si,es
	.enter

EC <	call	ECGrObjAttributeManagerCheckLMemObject		>

	GOAMDeref	di,ds,si
	tst	ds:[di].GOAMI_text.handle
	jnz	done

	;    Create text object in same block as attribute manager
	;

	push	si					;attr mgr chunk
	mov	bx,ds:[LMBH_handle]
	mov	di,segment VisTextClass
	mov	es,di
	mov	di,offset VisTextClass
	call	ObjInstantiate

	; Don't muck with the search controller!
	push	bx				; Save trashed registers.
	mov	ax, ATTR_VIS_TEXT_DO_NOT_INTERACT_WITH_SEARCH_CONTROL
	clr	cx				; No data.
	call	ObjVarAddData
	pop	bx				; Restore trashed regs.

	mov	cl, mask VTSF_MULTIPLE_CHAR_ATTRS or \
			mask VTSF_MULTIPLE_PARA_ATTRS or mask VTSF_TYPES or \
			mask VTSF_GRAPHICS
	clr	ch
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_VIS_TEXT_CREATE_STORAGE
	call	ObjMessage

	;    Save od in instance data
	;

	pop	di					;attr mgr chunk
	GOAMDeref	di,ds,di
	mov	ds:[di].GOAMI_text.handle,bx
	mov	ds:[di].GOAMI_text.chunk,si

done:
	.leave
	ret
GrObjAttributeManagerCreateTextObject		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerMessageToText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the text object associated with
		this attribute manager

CALLED BY:	INTERNAL UTILITY
		

PASS:		*ds:si - GrObjAttributeManager
		ax - message
		cx,dx,bp - message data
		di - MessageFlags

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
GrObjAttributeManagerMessageToText		proc	far
	class	GrObjAttributeManagerClass
	uses	bx,si,di
	.enter

EC <	call	ECGrObjAttributeManagerCheckLMemObject			>

	GOAMDeref	si,ds,si
	mov	bx,ds:[si].GOAMI_text.handle
EC <	tst	bx							>
EC <	ERROR_Z	GROBJ_ATTRIBUTE_MANAGER_HAS_NO_TEXT_OBJECT		>
	mov	si,ds:[si].GOAMI_text.chunk
	ornf	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
GrObjAttributeManagerMessageToText		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerCreateGrObjArrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create arrays necessary for holding area and line attributes
		and styles

CALLED BY:	INTERNAL
		GrObjAttributeManagerAttachAndCreateArrays

PASS:		*ds:si - GrObjAttributeManager

RETURN:		
		GOAMI_areaAttrArrayHandle 
		GOAMI_lineAttrArrayHandle 
		GOAMI_grObjStyleArrayHandle 
		ax - area default element index
		bx - line default element index

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
	srs	1/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerCreateGrObjArrays		proc	near
	class	GrObjAttributeManagerClass
	uses	si,di,bp
	.enter

	push	ds:[LMBH_handle], es:[LMBH_handle]

EC <	call	ECGrObjAttributeManagerCheckLMemObject			>

	GOAMDeref	di,ds,si

	;    Duplicate GrObjBaseAreaAttrElement array, attach the new
	;    block to the vm file and store the vm block handle
	;    in the GrObjAttributeManager's instance data
	;

	mov	bx, handle GrObjAreaAttr
	call	GeodeDuplicateResource
	call	GrObjAttributeManagerAttachMemBlock
	mov	ds:[di].GOAMI_areaAttrArrayHandle,ax

	;    Duplicate GrObjBaseLineAttrElement array, attach the new
	;    block to the vm file and store the vm block handle
	;    in the GrObjAttributeManager's instance data
	;

	mov	bx, handle GrObjLineAttr
	call	GeodeDuplicateResource
	call	GrObjAttributeManagerAttachMemBlock
	mov	ds:[di].GOAMI_lineAttrArrayHandle,ax

	;    Duplicate GrObjStyleElementHeader array, attach the new
	;    block to the vm file and store the vm block handle
	;    in the GrObjAttributeManager's instance data
	;

	mov	bx, handle GrObjStyle
	call	GeodeDuplicateResource
	call	GrObjAttributeManagerAttachMemBlock
	mov	ds:[di].GOAMI_grObjStyleArrayHandle,ax

	;    Localize GOStyles

	call	GrObjGlobalGetVMFile
	call	VMLock
	mov	ds, ax
	mov	si, offset GOStyles

	mov	ax, 0;  handle GOStyles		; Chunk array
	call	LocalizeNameArrayElement
	call	VMUnlock

	pop	bx
	call	MemDerefES
	pop	bx
	call	MemDerefDS

	mov	ax,GOA_NORMAL_AREA_ATTR
	mov	bx,GOL_NORMAL_LINE_ATTR

	.leave
	ret
GrObjAttributeManagerCreateGrObjArrays		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalizeNameArrayElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Localizes a name array element.

CALLED BY:	GLOBAL
PASS:		ds:si - NameArray
		ax - element number
RETURN:		nada
DESTROYED:	si,di
 
PSEUDO CODE/STRATEGY:
	Each element in a localizable NameArray has an lptr to a string as
	the last word in the element.

	We copy the data out of that chunk into the end of the element.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/93   	Initial version
	pjc	1/3/96		Stole from GeoWrite and rewrote.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalizeNameArrayElement	proc	far
	uses ax,bx,cx,dx,bp
	.enter

	; Get the offset to the localized string.

	mov	dx, ax			; element number
	call	ChunkArrayElementToPtr	; ds:di = element, cx = size

	mov	ax, cx			; ax = size
	sub	cx, size lptr		; offset of string chunk handle
					; within element
	mov	bp, cx			; Save it
	add	di, cx			; di = offset to end of element
	mov	bx, ds:[di]		; bx = chunk handle of string
	mov	bx, ds:[bx]		; ds:bx = ptr to string

	; Get the size of the localized string.

	ChunkSizePtr	ds, bx, cx	; cx = size of localized string
	dec	cx			; cx = size of string w/o null	
DBCS <  dec	cx							>
	push	cx

	; Resize element to fit the data.

     	add	cx, ax			; cx = current element size +
					; localized string.
	sub	cx, size lptr		; cx = new size of element
	mov	ax, dx			; ax = element number	
	call	ChunkArrayElementResize	; Resize the element

	; Get a ptr into the element, and copy the data over

	call	ChunkArrayElementToPtr	; ds:di = element
	pop	cx			; cx = string size (w/o null)
	push	si
	segmov	es, ds
	add	di, bp			; es:di = destination 
	mov	si, ds:[di]		; *ds:si <- localized string
	mov	si, ds:[si]		; ds:si <- localized string
	rep	movsb			; Copy the data over.
	pop	si	

	.leave
	ret
LocalizeNameArrayElement	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerCreateTextArrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create arrays necessary for holding char and para attributes
		and styles

CALLED BY:	INTERNAL
		GrObjAttributeManagerAttachAndCreateTextArrays

PASS:		*ds:si - GrObjAttributeManager

RETURN:		
		GOAMI_charAttrArrayHandle 
		GOAMI_paraAttrArrayHandle 
		GOAMI_typeArrayHandle 
		GOAMI_graphicArrayHandle 
		GOAMI_nameArrayHandle 
		GOAMI_textStyleArrayHandle 
		ax - char default element index
		bx - para default element index
		cx - type element index

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
	srs	1/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerCreateTextArrays		proc	near
	class	GrObjAttributeManagerClass
	uses	di
	.enter

	push	ds:[LMBH_handle], es:[LMBH_handle]

EC <	call	ECGrObjAttributeManagerCheckLMemObject			>

	GOAMDeref	di,ds,si

	;    Duplicate char array, attach the new
	;    block to the vm file and store the vm block handle
	;    in the GrObjAttributeManager's instance data
	;

	mov	bx, handle GrObjCharAttr
	call	UserGetDisplayType
	andnf	ah, mask DT_DISP_ASPECT_RATIO
	cmp	ah, DAR_TV shl offset DT_DISP_ASPECT_RATIO
	jne	duplicate
	mov	bx, handle GrObjTVCharAttr
duplicate:
	call	GeodeDuplicateResource
	call	GrObjAttributeManagerAttachMemBlock
	mov	ds:[di].GOAMI_charAttrArrayHandle,ax

	;    Duplicate para array, attach the new
	;    block to the vm file and store the vm block handle
	;    in the GrObjAttributeManager's instance data
	;

	mov	bx, handle GrObjParaAttr
	call	GeodeDuplicateResource
	call	GrObjAttributeManagerAttachMemBlock
	mov	ds:[di].GOAMI_paraAttrArrayHandle,ax

	;    Duplicate type array, attach the new
	;    block to the vm file and store the vm block handle
	;    in the GrObjAttributeManager's instance data
	;

	mov	bx, handle GrObjTypeElements
	call	GeodeDuplicateResource
	call	GrObjAttributeManagerAttachMemBlock
	mov	ds:[di].GOAMI_typeArrayHandle,ax

	;    Duplicate para array, attach the new
	;    block to the vm file and store the vm block handle
	;    in the GrObjAttributeManager's instance data
	;

	mov	bx, handle GrObjGraphicElements
	call	GeodeDuplicateResource
	call	GrObjAttributeManagerAttachMemBlock
	mov	ds:[di].GOAMI_graphicArrayHandle,ax

	mov	bx, handle GrObjNameElements
	call	GeodeDuplicateResource
	call	GrObjAttributeManagerAttachMemBlock
	mov	ds:[di].GOAMI_nameArrayHandle,ax

	;    Duplicate TextStyleElementHeader array, attach the new
	;    block to the vm file and store the vm block handle
	;    in the GrObjAttributeManager's instance data
	;

	mov	bx, handle GrObjTextStyle
	call	GeodeDuplicateResource
	call	GrObjAttributeManagerAttachMemBlock
	mov	ds:[di].GOAMI_textStyleArrayHandle,ax

	;    Localize GOTextStyles

	push	si
	call	GrObjGlobalGetVMFile
	call	VMLock
	mov	ds, ax
	mov	si, offset GOTextStyles
	mov	ax, 0;  handle GOStyles		; Chunk array
	call	LocalizeNameArrayElement
	call	VMUnlock
	pop	si

	pop	bx
	call	MemDerefES
	pop	bx
	call	MemDerefDS

	mov	ax,GOC_NORMAL_CHAR_ATTR
	mov	bx,GOP_NORMAL_PARA_ATTR
	mov	cx,GOT_NORMAL_TYPE

	.leave
	ret
GrObjAttributeManagerCreateTextArrays		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerAttachMemBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach the memory block to vm file the 
		GrObjAttributeManager is in and return the
		vm block handle
		

CALLED BY:	INTERNAL
		GrObjAttributeManagerCreateGrObjArrays

PASS:		
		ds - segment GrObjAttributeManager is in
		bx - memory handle 

RETURN:		
		ax - vm block handle

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
	srs	2/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerAttachMemBlock		proc	near
	uses	bx,cx
	.enter

	mov	cx,bx					;memory handle
	call	GrObjGlobalGetVMFile
	clr	ax					;alloc new vm block
	call	VMAttach

	.leave
	ret
GrObjAttributeManagerAttachMemBlock		endp

GrObjInitCode	ends

GrObjAttributesCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerGetTextOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return od of text object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass

RETURN:		
		cx:dx - od
	
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
	srs	5/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerGetTextOD	method dynamic GrObjAttributeManagerClass, 
						MSG_GOAM_GET_TEXT_OD
	.enter

	mov	cx,ds:[di].GOAMI_text.handle
	mov	dx,ds:[di].GOAMI_text.chunk

	.leave
	ret
GrObjAttributeManagerGetTextOD		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerGetTextArrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Return the vm block handles of the char, para and style arrays.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerGetTextArrays

		ss:bp - GrObjTextArrays structure to fill in

RETURN:
		ss:bp - structure filled in
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerGetTextArrays method dynamic GrObjAttributeManagerClass, 
						MSG_GOAM_GET_TEXT_ARRAYS
	.enter

	mov	ax, ds:[di].GOAMI_charAttrArrayHandle
	mov	ss:[bp].GOTA_charAttrArray, ax
	mov	ax, ds:[di].GOAMI_paraAttrArrayHandle
	mov	ss:[bp].GOTA_paraAttrArray, ax
	mov	ax, ds:[di].GOAMI_typeArrayHandle
	mov	ss:[bp].GOTA_typeArray, ax
	mov	ax, ds:[di].GOAMI_graphicArrayHandle
	mov	ss:[bp].GOTA_graphicArray, ax
	mov	ax, ds:[di].GOAMI_nameArrayHandle
	mov	ss:[bp].GOTA_nameArray, ax
	mov	ax, ds:[di].GOAMI_textStyleArrayHandle
	mov	ss:[bp].GOTA_textStyleArray, ax

	.leave
	ret
GrObjAttributeManagerGetTextArrays		endm








COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerAddGrObjBaseAreaAttrElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an element (or a new reference to an existing element)
		in the area attr element array

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass
		
		ss:bp - GrObjBaseAreaAttrElement

RETURN:		
		ax - area token
		stc - if this element newly added
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerAddGrObjBaseAreaAttrElement	method dynamic \
		GrObjAttributeManagerClass, MSG_GOAM_ADD_AREA_ATTR_ELEMENT
	.enter

	call	GrObjDetermineAreaAttributeDataSize

	mov	bx,ds:[di].GOAMI_areaAttrArrayHandle
	call	GrObjAttributeManagerAddAttrElement

	.leave
	ret
GrObjAttributeManagerAddGrObjBaseAreaAttrElement		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerAddGrObjBaseLineAttrElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an element (or a new reference to an existing element)
		in the area attr element array

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass
		
		ss:bp - GrObjBaseLineAttrElement

RETURN:		
		ax - line token
		stc - if this element newly added
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerAddGrObjBaseLineAttrElement	method dynamic \
		GrObjAttributeManagerClass, MSG_GOAM_ADD_LINE_ATTR_ELEMENT
	.enter

	call	GrObjDetermineLineAttributeDataSize

	mov	bx,ds:[di].GOAMI_lineAttrArrayHandle
	call	GrObjAttributeManagerAddAttrElement
				   
	.leave
	ret
GrObjAttributeManagerAddGrObjBaseLineAttrElement		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerAddAttrElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an element (or a new reference to an existing element)
		in an attr element array

CALLED BY:	INTERNAL
		GrObjAttributeManagerAddGrObjBaseAreaAttrElement
		GrObjAttributeManagerAddGrObjBaseLineAttrElement

PASS:		
		bx - array vm block
			(array chunk must be GROBJ_VM_ELEMENT_ARRAY_CHUNK )
		ss:bp - element to add
		ax - element size
		ds - segment of body

RETURN:		
		ax - token
		stc - if this element newly added

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
	srs	8/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerAddAttrElement		proc	near
	uses	bx,cx,dx,bp,si,di,ds
	.enter

	mov_tr	di,ax					;element size
	mov_tr	ax,bx					;array vm block handle
	mov	cx,ss					;seg element
	mov	dx,bp					;offset element
	call	GrObjGlobalGetVMFile
	call	VMLock					;lock array
	mov	ds,ax					;segment array
	clr	bx					;no call back
	mov	si,GROBJ_VM_ELEMENT_ARRAY_CHUNK
	mov	ax,di					;element size
	call	ElementArrayAddElement
	call	VMDirty
	call	VMUnlock				;array block

	.leave
	ret
GrObjAttributeManagerAddAttrElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerDerefGrObjBaseAreaAttrElementToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference element in area attr array (remove if
		reference count geos to zero)

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass

		cx - area token

RETURN:		
		stc - if element actually removed
	
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
	srs	8/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerDerefGrObjBaseAreaAttrElementToken	method dynamic \
	GrObjAttributeManagerClass, MSG_GOAM_DEREF_AREA_ATTR_ELEMENT_TOKEN
	.enter

	mov	bx,ds:[di].GOAMI_areaAttrArrayHandle
	call	GrObjAttributeManagerDerefAttrElementToken

	.leave
	ret
GrObjAttributeManagerDerefGrObjBaseAreaAttrElementToken		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerDerefGrObjBaseLineAttrElementToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference element in line attr array (remove if
		reference count geos to zero)

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass

		cx - token

RETURN:		
		stc - if element actually removed
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerDerefGrObjBaseLineAttrElementToken	method dynamic \
	GrObjAttributeManagerClass, MSG_GOAM_DEREF_LINE_ATTR_ELEMENT_TOKEN
	.enter

	mov	bx,ds:[di].GOAMI_lineAttrArrayHandle
	call	GrObjAttributeManagerDerefAttrElementToken

	.leave
	ret
GrObjAttributeManagerDerefGrObjBaseLineAttrElementToken		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerDerefAttrElementToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference element in attr array (remove if
		reference count geos to zero)

CALLED BY:	INTERNAL
		GrObjAttributeManagerDerefGrObjBaseAreaAttrElementToken
		GrObjAttributeManagerDerefGrObjBaseLineAttrElementToken

PASS:		
		bx - array vm block
			(array chunk must be GROBJ_VM_ELEMENT_ARRAY_CHUNK )
		cx - token
		ds - segment of GrObjAttributeManager

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
	srs	8/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerDerefAttrElementToken		proc	near
	uses	ax,bx,bp,si,ds
	.enter

	cmp	cx,CA_NULL_ELEMENT
	je	done

	mov_tr	ax,bx					;vm block handle
	call	GrObjGlobalGetVMFile
	call	VMLock					;lock array
	mov	ds,ax					;segment array
	clr	bx					;no call back
	mov	ax,cx					;token
	mov	si,GROBJ_VM_ELEMENT_ARRAY_CHUNK
	call	ElementArrayRemoveReference
	call	VMDirty
	call	VMUnlock

done:
	.leave
	ret
GrObjAttributeManagerDerefAttrElementToken		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerAddRefGrObjBaseAreaAttrElementToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add reference to element in area attr array 

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass

		cx - token

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
	srs	8/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerAddRefGrObjBaseAreaAttrElementToken	method dynamic \
	GrObjAttributeManagerClass, MSG_GOAM_ADD_REF_AREA_ATTR_ELEMENT_TOKEN
	.enter

	mov	bx,ds:[di].GOAMI_areaAttrArrayHandle
	call	GrObjAttributeManagerAddRefAttrElementToken

	.leave
	ret
GrObjAttributeManagerAddRefGrObjBaseAreaAttrElementToken		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerAddRefGrObjBaseLineAttrElementToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add reference to element in line attr array 

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass

		cx - line token

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
	srs	8/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerAddRefGrObjBaseLineAttrElementToken	method dynamic \
	GrObjAttributeManagerClass, MSG_GOAM_ADD_REF_LINE_ATTR_ELEMENT_TOKEN
	.enter

	mov	bx,ds:[di].GOAMI_lineAttrArrayHandle
	call	GrObjAttributeManagerAddRefAttrElementToken

	.leave
	ret
GrObjAttributeManagerAddRefGrObjBaseLineAttrElementToken		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerAddRefAttrElementToken
o%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add reference to element in attr array 

CALLED BY:	INTERNAL
		GrObjAttributeManagerAddRefGrObjBaseAreaAttrElementToken
		GrObjAttributeManagerAddRefGrObjBaseLineAttrElementToken

PASS:		
		bx - array vm block
		cx - token
		ds - segment of GrObjAttributeManager
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
	srs	8/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerAddRefAttrElementToken		proc	near
	uses	ax,bx,bp,si,ds
	.enter

	cmp	cx, CA_NULL_ELEMENT
	je	done

	mov_tr	ax,bx					;vm block handle
	call	GrObjGlobalGetVMFile
	call	VMLock					;lock array
	mov	ds,ax					;segment array
	mov	ax,cx					;token
	mov	si,GROBJ_VM_ELEMENT_ARRAY_CHUNK
	call	ElementArrayAddReference
	call	VMDirty
	call	VMUnlock

done:
	.leave
	ret
GrObjAttributeManagerAddRefAttrElementToken		endp


GrObjAttributesCode	ends


GrObjRequiredExtInteractive2Code	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjAttributeManagerGetStyleArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjAttributeManager method for MSG_GOAM_GET_STYLE_ARRAY

Called by:	

Pass:		*ds:si = GrObjAttributeManager object
		ds:di = GrObjAttributeManager instance

Return:		cx = style array vm block handle
		carry set to indicate success

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 20, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerGetStyleArray	method dynamic	GrObjAttributeManagerClass, MSG_GOAM_GET_STYLE_ARRAY
	.enter

	mov	cx, ds:[di].GOAMI_grObjStyleArrayHandle
	stc

	.leave
	ret
GrObjAttributeManagerGetStyleArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	GrObjAttributeManagerGetAreaAndLineTokensFromStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjAttributeManager method for
		MSG_GOAM_GET_AREA_AND_LINE_TOKENS_FROM_STYLE


Called by:	

Pass:		*ds:si = GrObjAttributeManager object
		ds:di = GrObjAttributeManager instance

		cx - style token

Return:		carry set if style not found, else:

		ax - area attr token
		dx - line attr token

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 20, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerGetAreaAndLineTokensFromStyle	method dynamic	GrObjAttributeManagerClass, MSG_GOAM_GET_AREA_AND_LINE_TOKENS_FROM_STYLE

	uses	cx, bp
	.enter

	call	GrObjGlobalGetVMFile
	mov	ax, ds:[di].GOAMI_grObjStyleArrayHandle
	call	VMLock
	mov	ds, ax
	mov	si, VM_ELEMENT_ARRAY_CHUNK
	mov_tr	ax, cx
	call	ChunkArrayElementToPtr
	jc	unlock
	mov	ax, ds:[di].GSE_areaAttrToken
	mov	dx, ds:[di].GSE_lineAttrToken
unlock:
	call	VMUnlock
	.leave
	ret
GrObjAttributeManagerGetAreaAndLineTokensFromStyle	endm	

GrObjRequiredExtInteractive2Code	ends

GrObjStyleSheetCode	segment resource

GrObjAttributeManagerGetAreaAttrArray	method dynamic	GrObjAttributeManagerClass, MSG_GOAM_GET_AREA_ATTR_ARRAY
	.enter

	mov	cx, ds:[di].GOAMI_areaAttrArrayHandle
	stc

	.leave
	ret
GrObjAttributeManagerGetAreaAttrArray	endm

GrObjAttributeManagerGetLineAttrArray	method dynamic	GrObjAttributeManagerClass, MSG_GOAM_GET_LINE_ATTR_ARRAY
	.enter

	mov	cx, ds:[di].GOAMI_lineAttrArrayHandle
	stc

	.leave
	ret
GrObjAttributeManagerGetLineAttrArray	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GOAMLoadStyleSheetParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjAttributeManager method for
		MSG_GOAM_LOAD_STYLE_SHEET_PARAMS

Called by:	

Pass:		*ds:si = GrObjAttributeManager object
		ds:di = GrObjAttributeManager instance

		ss:bp - StyleSheetParams
		cx - nonzero to preserve xfer stuff
		
Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GOAMLoadStyleSheetParams	method dynamic	GrObjAttributeManagerClass,
				MSG_GOAM_LOAD_STYLE_SHEET_PARAMS

	uses	cx

	.enter

	;
	;	Test to preserve xfer
	;
	push	si, ds
	tst	cx
	mov	cx, offset SSP_xferStyleArray / 2
	jnz	copyParams
	mov	cx, size StyleSheetParams / 2
copyParams:
	;
	;	Copy callbacks
	;
	segmov	es, ss, di
	segmov	ds, cs, di
	lea	di, ss:[bp]
	mov	si, offset ssParams
	rep movsw

	pop	si, ds
	GOAMDeref	di, ds, si

	; copy in arrays

	call	GrObjGlobalGetVMFile
	mov	ss:[bp].SSP_styleArray.SCD_vmFile, bx
	mov	ss:[bp].SSP_attrArrays[0].SCD_vmFile, bx
	mov	ss:[bp].SSP_attrArrays[(size StyleChunkDesc)].SCD_vmFile, bx

	mov	bx, ds:[di].GOAMI_grObjStyleArrayHandle
	mov	ss:[bp].SSP_styleArray.SCD_vmBlockOrMemHandle, bx

	mov	bx, ds:[di].GOAMI_areaAttrArrayHandle
	mov	ss:[bp].SSP_attrArrays[0].SCD_vmBlockOrMemHandle, bx

	mov	bx, ds:[di].GOAMI_lineAttrArrayHandle
	mov	ss:[bp].SSP_attrArrays[(size StyleChunkDesc)].SCD_vmBlockOrMemHandle, bx

	mov	bx, VM_ELEMENT_ARRAY_CHUNK
	mov	ss:[bp].SSP_styleArray.SCD_chunk, bx
	mov	ss:[bp].SSP_attrArrays[0].SCD_chunk, bx
	mov	ss:[bp].SSP_attrArrays[(size StyleChunkDesc)].SCD_chunk, bx

	.leave
	ret
GOAMLoadStyleSheetParams	endm

ssParams	StyleSheetParams	<
    <DescribeAreaAttr, DescribeLineAttr, 0, 0>,	;SSP_descriptionCallbacks
    DescribeGrObjStyle,				;SSP_specialDescriptionCallback
    <MergeGrObjAreaAttr, MergeGrObjLineAttr, 0, 0>,	;SSP_mergeCallbacks
    <SubstGrObjAreaAttr, SubstGrObjLineAttr, 0, 0>,	;SSP_substitutionCallbacks
    <>,						;SSP_styleArray
    <>,						;SSP_attrArrays
    <>,						;SSP_attrTokens
    <0, 0, VM_ELEMENT_ARRAY_CHUNK>,		;SSP_xferStyleArray
    <						;SSP_xferAttrArrays
	<0, 0, VM_ELEMENT_ARRAY_CHUNK>,
	<0, 0, VM_ELEMENT_ARRAY_CHUNK>,
	<>, <>
    >
>


GrObjStyleSheetCode	ends


GrObjDrawCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerGetGrObjFullAreaAttrElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return GrObjFullAreaAttrElement structure from area array

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass

		cx - area token
		ss:bp - GrObjFullAreaAttrElement - empty

RETURN:		
		carry set if passed token valid
			ss:bp - GrObjFullAreaAttrElement - filled
			ax - element size

		carry clear if no information retured
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE 
		because it will be used during drawing

		Common cases:
			none
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerGetGrObjFullAreaAttrElement	method dynamic \
		GrObjAttributeManagerClass, MSG_GOAM_GET_FULL_AREA_ATTR_ELEMENT
	.enter

	mov	bx,ds:[di].GOAMI_areaAttrArrayHandle
	call	GrObjAttributeManagerGetAttrElement

	.leave
	ret
GrObjAttributeManagerGetGrObjFullAreaAttrElement		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerGetGrObjFullLineAttrElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return GrObjFullLineAttrElement structure from line array

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass

		cx - line token
		ss:bp - GrObjFullLineAttrElement - empty

RETURN:		
		carry set if passed token valid
			ss:bp - GrObjFullLineAttrElement - filled
			ax - element size

		carry clear if no information retured
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE 
		because it will be used during drawing

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerGetGrObjFullLineAttrElement	method dynamic \
	GrObjAttributeManagerClass, MSG_GOAM_GET_FULL_LINE_ATTR_ELEMENT
	.enter

	mov	bx,ds:[di].GOAMI_lineAttrArrayHandle
	call	GrObjAttributeManagerGetAttrElement

	.leave
	ret
GrObjAttributeManagerGetGrObjFullLineAttrElement		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerGetAttrElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return attr element structure from area array

CALLED BY:	INTERNAL
		GrObjAttributeManagerGetGrObjFullLineAttrElement
		GrObjAttributeManagerGetGrObjFullAreaAttrElement
		

PASS:		
		bx - vm block handle of array
			(array chunk must be GROBJ_VM_ELEMENT_ARRAY_CHUNK )
		cx - token
		ss:bp - element structure - empty
		ds - segment of GrObjAttributeManager

RETURN:		
		carry set if token valid
			ax - element size
			ss:bp - element structure - filled

		carry clear if no information returned

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE 
		because it will be used during drawing

		Common cases:
			token is valid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerGetAttrElement		proc	near
	uses	bx,cx,dx,bp,si,ds
	.enter

	cmp	cx, CA_NULL_ELEMENT
	je	done					;carry clear if =

	mov	ax,bx					;array vm block handle
	mov	dx,bp					;offset buffer
	call	GrObjGlobalGetVMFile
	call	VMLock					;lock array block
	mov	ds,ax					;segment array 
	mov_tr	ax,cx					;token
	mov	cx,ss					;seg buffer
	mov	si,GROBJ_VM_ELEMENT_ARRAY_CHUNK
	call	ChunkArrayGetElement
	call	VMUnlock

	stc
done:
	.leave
	ret
GrObjAttributeManagerGetAttrElement		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle relocation and unrelocation of object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass

 		ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE
 		cx - handle of block containing relocation
 		dx - VMRelocType:
 			VMRT_UNRELOCATE_BEFORE_WRITE
 			VMRT_RELOCATE_AFTER_READ
 			VMRT_RELOCATE_AFTER_WRITE
 		bp - data to pass to ObjRelocOrUnRelocSuper
		ax - method
		dx - VMRelocType

RETURN:		
		carry - set if error
		bp - unchanged

DESTROYED:	
		ax,cx,dx

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerReloc	method dynamic GrObjAttributeManagerClass, reloc
	.enter


	cmp	ax,MSG_META_RELOCATE
	jne	handleBodyList
	cmp	dx,VMRT_RELOCATE_AFTER_READ
	jne	handleBodyList

	;    If the GOAM is being relocated after being read from the
	;    file then we must clean up its instance data.
	;    Clear any suspension. Otherwise if we crashed and it 
	;    was set it would never get cleared again.
	;

	mov_tr	cx,ax					;reloc message
	mov	ax,ATTR_GO_ACTION_NOTIFICATION
	call	ObjVarFindData
	jnc	recoverMessage
	clr	ds:[bx].GOANS_suspendCount
recoverMessage:
	mov_tr	ax,cx					;reloc message

handleBodyList:
	call	GrObjAttributeManagerRelocBodyList


	.leave

	Destroy	ax,cx,dx

	mov	di,offset GrObjAttributeManagerClass
	call	ObjRelocOrUnRelocSuper
	ret

GrObjAttributeManagerReloc		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerRelocBodyList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Relocate or unrelocate the body list

CALLED BY:	INTERNAL
		GrObjAttributeManagerReloc

PASS:		*ds:si - GrObjAttributeManager
		ax - MSG_META_RELOCATE or MSG_META_UNRELOCATE

RETURN:		
		carry - set if error

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
	srs	6/10/92   	Initial version
	sh	4/29/94		XIP'ed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerRelocBodyList		proc	near
	uses	di,bx
	.enter
	;
	; we don't pass vfptr because the callback will be passed
	; into ChunkArrayEnum() which takes fptr, *not* vfptr
	;
NOFXIP <mov	bx, cs						>
	mov	di, offset GrObjAttributeManagerRelocBodyListCB
	call	GrObjAttributeManagerBodyListEnum

	.leave
	ret
GrObjAttributeManagerRelocBodyList		endp

if FULL_EXECUTE_IN_PLACE
GrObjDrawCode	ends
GrObjInitCode	segment	resource
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerRelocBodyListCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ChunkArrayEnum call back routine. Relocates or unrelocates
		handle of body od

CALLED BY:	ChunkArrayEnum

PASS:		
		*ds:si - body list chunk array
		ds:di - element
		ax - relocation message

RETURN:		
		carry - set if error

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
	srs	6/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerRelocBodyListCB		proc	far
	uses	ax,bx,cx
	.enter

	mov	cx,ds:[di].handle
	mov	bx,ds:[LMBH_handle]
	cmp	ax,MSG_META_RELOCATE
	mov	al,RELOC_HANDLE
	jne	unreloc

	call	ObjDoRelocation

store:
	mov	ds:[di].handle,cx

	.leave
	ret

unreloc:
	call	ObjDoUnRelocation
	jmp	store


GrObjAttributeManagerRelocBodyListCB		endp

if FULL_EXECUTE_IN_PLACE
GrObjInitCode	ends
else
GrObjDrawCode	ends
endif

GrObjAlmostRequiredCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GOAMMessageToBodyList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Send a message to every body in the body list

Pass:		*ds:si = GOAM
		ax = message
		cx,dx,bp = other data
		di = message flags

Return:		nothing

Destroyed:	nothing

Comments:	
		WARNING: May cause blocks to move on heap. ds will
		be fixed up but es will not.

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 27, 1992 	Initial version.
	steve	6/10/92		Moved body list into goam's block
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GOAMMessageToBodyList		proc	far
	class	GrObjAttributeManagerClass
	uses	si,bx,di
	.enter

EC<	call	ECGrObjAttributeManagerCheckLMemObject		>

	GOAMDeref	di, ds, si
	tst	ds:[di].GOAMI_bodyList
	jz	done

	clr	bx
	push	bx,bx				;start with first OD
	mov	di,OCCT_SAVE_PARAMS_DONT_TEST_ABORT
	push	bx,di				;0, ObjCompCallType
	push	ds:[LMBH_handle], si		;GOAM OD

	GOAMDeref	si,ds,si
	mov	si,ds:[si].GOAMI_bodyList
	call	ObjArrayProcessChildren

done:
	.leave
	ret

GOAMMessageToBodyList		endp

GrObjAlmostRequiredCode	ends

GrObjRequiredCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAttributeManagerSendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send VisTextMessages and MetaTextMessage on the 
		text object. 

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjAttributeManagerClass

		cx - handle of ClassedEvent
		dx - TravelOptions

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
	srs	5/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttributeManagerSendClassedEvent 	method dynamic \
			GrObjAttributeManagerClass, MSG_META_SEND_CLASSED_EVENT
	.enter

	push	ax,cx,dx				;message #, event, TO
	mov	bx,cx					;event handle
	mov	dx,si					;guardian chunk
	call	ObjGetMessageInfo
	xchg	dx,si					;event class offset,
							;guard chunk
	jcxz	checkMetaTextMessages			;class segment
	cmp	cx, segment MetaClass
	jne	checkTextClass
	cmp	dx, offset MetaClass
	je	checkMetaTextMessages

checkTextClass:
	mov	ax,MSG_META_IS_OBJECT_IN_CLASS
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjAttributeManagerMessageToText
	jc	popCallText

popCallSuper:
	pop	ax,cx,dx				;message #, event, TO
	mov	di, offset GrObjAttributeManagerClass
	CallSuper	MSG_META_SEND_CLASSED_EVENT

done:
	.leave
	ret

checkMetaTextMessages:
	call	GrObjGlobalCheckForMetaTextMessages
	jnc	popCallSuper

popCallText:
	pop	ax,cx,dx				;message #, event, TO
	mov	di,mask MF_FIXUP_DS
	call	GrObjAttributeManagerMessageToText
	jmp	done


GrObjAttributeManagerSendClassedEvent		endm

GrObjRequiredCode	ends


if	ERROR_CHECK
GrObjErrorCode	segment resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECGrObjAttributeManagerCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is an 
		GrObjAttributeManagerClass or one of its subclasses
		
CALLED BY:	INTERNAL (UTILITY)

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
ECGrObjAttributeManagerCheckLMemObject		proc	far
	uses	es,di
	.enter
	pushf	
	mov	di,segment GrObjAttributeManagerClass
	mov	es,di
	mov	di,offset GrObjAttributeManagerClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_OF_CORRECT_CLASS
	popf
	.leave
	ret
ECGrObjAttributeManagerCheckLMemObject		endp

GrObjErrorCode	ends

endif

GrObjSpecialGraphicsCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GOAMSetGradientType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the  gradient type

		This message is subclassed here so that the attribute manager
		can shrink the default attribute structure back to
		base size if the passed GrObjGradientType is GOGT_NONE.

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
GOAMSetGradientType method extern dynamic GrObjAttributeManagerClass, 
				MSG_GO_SET_GRADIENT_TYPE
	.enter

	cmp	cl, GOGT_NONE
	je	backToBase

	push	cx
	mov	cl, GOAAET_GRADIENT
	mov	ax, MSG_GO_SET_AREA_ATTR_ELEMENT_TYPE
	call	ObjCallInstanceNoLock

	pop	ax					;gradient type
	mov	bx, offset GOGAAE_type
	mov	di,size GOGAAE_type
	call	GrObjChangeAreaAttrCommon

done:
	.leave
	ret

backToBase:
	mov	cl, GOAAET_BASE
	mov	ax, MSG_GO_SET_AREA_ATTR_ELEMENT_TYPE
	call	ObjCallInstanceNoLock
	jmp	done

GOAMSetGradientType		endp

GrObjSpecialGraphicsCode	ends


GrObjMiscUtilsCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GOAMSetGrObjDrawFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set GrObjDrawFlags in the GOAM's bodies

PASS:		cx - bits to set
		dx - bits to reset

RETURN:		nothing
DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	14 mar 1993	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GOAMSetGrObjDrawFlags	method dynamic GrObjAttributeManagerClass, 
			MSG_GOAM_SET_GROBJ_DRAW_FLAGS
	.enter

EC <	test	cx, not mask GrObjDrawFlags			>
EC <	ERROR_NZ GROBJ_BAD_GROBJ_DRAW_FLAGS			>
EC <	test	dx, not mask GrObjDrawFlags			>
EC <	ERROR_NZ GROBJ_BAD_GROBJ_DRAW_FLAGS			>

	mov	ax, MSG_GB_SET_GROBJ_DRAW_FLAGS_NO_BROADCAST
	clr	di
	call	GOAMMessageToBodyList

	.leave
	ret
GOAMSetGrObjDrawFlags		endm

GrObjMiscUtilsCode	ends
