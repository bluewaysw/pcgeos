COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Hierarchy
FILE:		graphicBodySelectionList

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name			Description
	----			-----------
GrObjBodyCreateSelectionArray
GrObjBodyDestroySelectionArray
GrObjBodyIsLMemGrObjSelected?
GrObjBodyCheckBoundsOfSelectedGrObjs

METHOD HANDLERS
	Name				Description
	----				-----------
GrObjBodyRemoveGrObjFromSelectionList	Remove child from selection list
GrObjBodyAddGrObjToSelectionList	Add child to selection list
GrObjBodyIsGrObjSelected?		Determine if child in in selection list
GrObjBodyGetNumSelectedGrObjs Count children in selection list
GrObjBodyGetSingleSelectionOD		Get od of sole child in selection list

GrObjBodyProcessSelectedGrObjsCommon
GrObjBodyProcessSelectedGrObjsCommonRV
GrObjBodySendToSelectedGrObjs	
GrObjBodySendToSelectedGrObjsAndEditGrab
GrObjBodyGetBoundsOfSelectedGrObjs
GrObjBodyGetBoundsOfSelectedGrObjsCB
GrObjBodyGetDWFBoundsOfSelectedGrObjs
GrObjBodyGetDWFBoundsOfSelectedGrObjsCB
GrObjBodyRemoveAllGrObjsFromSelectionList
GrObjBodyRemoveLMemChildFromSelectionList
GrahpicBodyDeleteSelectedGrObjs
GrObjBodyPullSelectedGrObjsToFront
GrObjBodyPullSelectedGrObjsToFrontCB
GrObjBodyPushSelectedGrObjsToBack
GrObjBodyPushSelectedGrObjsToBackCB

GrObjBodySendClassedEventToSelectedGrObjs
GrObjBodySendClassedEventToSelectedGrObjsCB

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:

	$Id: bodySelectionList.asm,v 1.1 97/04/04 18:08:06 newdeal Exp $
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
GrObjRequiredInteractiveCode	segment resource


GrObjBodySendToSelectedGrObjsTestAbort		proc	far
	uses	bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	clr	bx
	mov	di,OCCT_SAVE_PARAMS_TEST_ABORT
	call	GrObjBodyProcessSelectedGrObjsCommon

	.leave
	ret
GrObjBodySendToSelectedGrObjsTestAbort		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendToSelectedGrObjSplines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a classed event to all grobjs that are in the
		selected list

CALLED BY:	INTERNAL 

PASS:		
		*ds:si - instance data of graphic body
		ax - the message
		cx, dx, bp - data

RETURN:		nothing
		
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendToSelectedGrObjSplines 	proc	far
	uses	ax,bx,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	push	ds:[LMBH_handle]			;body handle

	clr	bx
	push	bx, bx					;initial OD

FXIP<	mov	bx, SEGMENT_CS						>
FXIP<	push	bx							>
	mov	bx,offset GrObjBodySendToSelectedGrObjSplinesCB
FXIP<	push	bx							>
NOFXIP<	push	cs,bx					;callback 	>
	push	ds:[LMBH_handle], si			;composite

	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	call	GrObjBodySelectionArrayLock
	jc	clearStackDone
	call	ObjArrayProcessChildren
	call	MemUnlock

	pop	bx					;body handle
	call	MemDerefDS

done:
	.leave
	ret

clearStackDone:
	add	sp,14
	jmp	done
GrObjBodySendToSelectedGrObjSplines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendToSelectedGrObjSplinesCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tests whether the passed object is some subclass of
		SplineGuardian, and if so, sends the message along to
		its ward.

CALLED BY:	ObjArrayProcessChildren

PASS:		*ds:si - child optr
		*es:di - composite optr
		ax - spline message
		cx, dx, bp - data

RETURN:		clc - to keep processing

DESTROYED:	bx, si, di, ds, es

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8 jun 1992	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendToSelectedGrObjSplinesCB	proc	far
	.enter

	push	ax, cx, dx, bp				;save message, regs
	mov	cx, segment SplineGuardianClass
	mov	dx, offset SplineGuardianClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp				;restore message, regs
	jnc	done

	;
	;  We're a spline guardian, so send the message to the ward
	;
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	clc
done:
	.leave
	ret
GrObjBodySendToSelectedGrObjSplinesCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendToFirstSelectedGrObjSpline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a classed event to all grobjs that are in the
		selected list

CALLED BY:	INTERNAL 

PASS:		
		*ds:si - instance data of graphic body
		ax - the message
		cx, dx, bp - data

RETURN:		nothing
		
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendToFirstSelectedGrObjSpline	proc	far
	uses	ax,bx,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	push	ds:[LMBH_handle]			;body handle

	clr	bx
	push	bx, bx					;initial OD
FXIP<	mov	bx, SEGMENT_CS						>
FXIP<	push	bx							>
	mov	bx,offset GrObjBodySendToFirstSelectedGrObjSplineCB
FXIP<	push	bx							>
NOFXIP<	push	cs,bx					;callback 	>
	push	ds:[LMBH_handle], si			;composite

	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	call	GrObjBodySelectionArrayLock
	jc	clearStackDone
	call	ObjArrayProcessChildren
	call	MemUnlock

	pop	bx					;body handle
	call	MemDerefDS

done:
	.leave
	ret

clearStackDone:
	add	sp,14
	jmp	done
GrObjBodySendToFirstSelectedGrObjSpline	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendToFirstSelectedGrObjSplineCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tests whether the passed object is some subclass of
		SplineGuardian, and if so, sends the message along to
		its ward.

CALLED BY:	ObjArrayProcessChildren

PASS:		*ds:si - child optr
		*es:di - composite optr
		ax - spline message
		cx, dx, bp - data

RETURN:		stc - if obj is spline guardian (to halt processing)

DESTROYED:	bx, si, di, ds, es

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8 jun 1992	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendToFirstSelectedGrObjSplineCB	proc	far
	.enter

	push	ax, cx, dx, bp				;save message, regs
	mov	cx, segment SplineGuardianClass
	mov	dx, offset SplineGuardianClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp				;restore message, regs
	jnc	done

	;
	;  We're a spline guardian, so send the message to the ward
	;
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	stc
done:
	.leave
	ret
GrObjBodySendToFirstSelectedGrObjSplineCB	endp

GrObjRequiredInteractiveCode	ends

GrObjRequiredExtInteractive2Code	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyRemoveGrObjFromSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove child from selection list

PASS:		
		*(ds:si) - instance data of body
		cx:dx - OD of object to remove

RETURN:		
		nothing

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on.And it must be careful about the
		registers is destroys.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyRemoveGrObjFromSelectionList	method 	GrObjBodyClass, 
				MSG_GB_REMOVE_GROBJ_FROM_SELECTION_LIST
	uses	bx,di,bp, si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	push	ds:[LMBH_handle]			;body handle

	;    Lock the selection list
	;

	call	GrObjBodySelectionArrayLock
	jc	done


	;    Locate the passed OD in the array
	;

	call	SelectionArrayFindOD

	;    If it's there, delete it
	;

	jnc	unlock
	mov_tr	di, ax				;ds:di = element
	call	ChunkArrayDelete

unlock:
	call	MemUnlock

	;
	;    Send lost selection message to child
	;
	;	NOTE: do not pass MF_FIXUP_DS -- at this point
	;	it does not point to the body's object block,
	;	but instead to where the selection array was.
	;	In the EC with ECF_SEGMENT, this means ds will
	;	be 0xa000, which is bogus to try to fix up
	;	and will cause ILLEGAL_HANDLE death.
	;

	mov	ax,MSG_GO_LOST_SELECTION_LIST
	mov	bx,cx				;od of child
	mov	si,dx
	clr	di
	call	ObjMessage

done:
	pop	bx					;body handle
	call	MemDerefDS

	.leave
	ret
GrObjBodyRemoveGrObjFromSelectionList		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SelectionArrayFindOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns a ptr to the array element containing the
		specified OD, if it exists.

Context:	

Source:		

Destination:	

Pass:		*ds:si = OD chunk array
		cx:dx = OD to search for

Return:		if found:
			carry set
			ds:ax = element
		else:
			carry clear

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 18, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectionArrayFindOD	proc	near
	uses	bx, di
	.enter
	mov	bx, cs
	mov	di, offset SelectionArrayFindODCB
	call	ChunkArrayEnum
	.leave
	ret
SelectionArrayFindOD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SelectionArrayFindODCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Callback routine for SelectionArrayFindOD

Context:	

Source:		

Destination:	

Pass:		ds:di = OD array element
		cx:dx = OD to search for

Return:		if passed OD matches element OD:
			carry set
			ds:ax = array element
		else:
			carry clear

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 18, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectionArrayFindODCB	proc	far

	;    See if the chunks match
	;

	cmp	dx, ds:[di].chunk
	je	checkHandle

	;    The OD does not match, so clear the carry and return
	;

noMatch:
	clc
done:
	ret

	;    See if the handles match
	;

checkHandle:
	cmp	cx, ds:[di].handle
	jne	noMatch

	;    This element contains the OD we're looking for, so set
	;    the carry and return our address
	;

	mov_tr	ax, di					;ds:ax = element
	stc
	jmp	done
SelectionArrayFindODCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAddGrObjToSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add child to selection list

PASS:		
		*(ds:si) - instance data of body
		cx:dx - OD of object to remove
		bp low - HandleUpdateMode
RETURN:		
		nothing

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on. And it must be careful about the
		regsiters is destroys.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 5/90		Initial version
	jon	12 Nov 1991	Updated to work with selection array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAddGrObjToSelectionList	method dynamic	GrObjBodyClass, 
					MSG_GB_ADD_GROBJ_TO_SELECTION_LIST
	uses	dx,bp
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>
EC <	cmp	bp,HandleUpdateMode				>
EC <	ERROR_AE	BAD_HANDLE_UPDATE_MODE			>

	;    The selection list is another form of the target so	
	;    make sure we don't have both selected and editable objects.
	;    This helps with some problems with spell checking and search
	;    and replace giving the target to text objects when I
	;    least expect it.
	;

	push	cx					;child handle
	mov	di,mask MF_FIXUP_DS
	mov	cl,DONT_SELECT_AFTER_EDIT
	mov	ax,MSG_GO_BECOME_UNEDITABLE
	call	GrObjBodyMessageToEdit
	pop	cx					;child handle

	;    If child is in selection list then exit
	;

	call	GrObjBodyIsGrObjSelected
	jc	done				;jmp if already in list

	;    If no selection array just punt
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	tst	ds:[di].GBI_selectionArray.handle
	jz	done

	;    Add that baby to the list
	;

	call	GrObjBodyAddGrObjToSelectionListLow

	;    Get status of system target in body
	;    so we can update the newly selected object with it
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	mov	al,TRUE
	test	ds:[di].GBI_fileStatus, mask GOFS_SYS_TARGETED
	jz	notSys


sendGained:
	;    Send sys target status before gained selection so that
	;    the HandleUpdateMode can be handled correctly.
	;	

	mov	bx,cx				;od of child
	mov	si,dx
	mov	cx,ax				;sys target status
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_SET_SYS_TARGET
	call	ObjMessage

	mov	dx,bp				;HandleUpdateMode
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_GAINED_SELECTION_LIST
	call	ObjMessage

done:
	.leave
	ret

notSys:
	mov	al,FALSE
	jmp	sendGained

GrObjBodyAddGrObjToSelectionList		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAddGrObjToSelectionListLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a grobject to the selection list. Does
		no error checking. Just adds the child

CALLED BY:	INTERNAL
		GrObjBodyAddGrObjToSelectionList

PASS:		
		*ds:si - GrObjBody
		^lcx:dx - od of child

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
	srs	9/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAddGrObjToSelectionListLow		proc	near
	uses	ds,si,di,bp,cx,dx,ax,bx
	.enter

EC <	call	ECGrObjBodyCheckLMemObject		>

	;    Lock the selection array, bailing if selection array not
	;    available.
	;

	push	ds, si				;save body ptr
	call	GrObjBodySelectionArrayLock	;*ds:si = array
	pop	di, bp				;*di:bp = body
EC <	ERROR_C GROBJ_BODY_SELECTION_ARRAY_NOT_FOUND	>

	;    If selection array is empty jmp to append child
	;    to chunk array.
	;

	mov_tr	ax, cx				;child handle 
	call	ChunkArrayGetCount
	jcxz	append

	;    Find the OD of the next selected object in the draw list,
	;    so that we can add this child just before it in the
	;    selection list. The selection list is maintained in draw
	;    order
	;

	mov_tr	cx, ax				;child handle
	push	cx, dx				;save OD to be added

	push	ds, si				;save chunk array ptr

	mov	ds, di				;*ds:si <= body
	mov	si, bp

	call	GrObjBodyFindNextSelectedChildInDrawOrder
	pop	ds, si				;*ds:si = chunk array

	jnc	popAppend	

	call	SelectionArrayFindOD
EC<	ERROR_NC   OBJECT_HAS_SELECTED_BIT_SET_BUT_IS_NOT_IN_SELECTED_ARRAY  >
NEC<	jnc	popAppend			>
	mov_tr	di, ax
	pop	ax, dx
	call	ChunkArrayInsertAt

	;    Fill in the data for our new selected entry
	;

new:
	mov	ds:[di].handle, ax
	mov	ds:[di].offset, dx

	call	MemUnlock

	.leave
	ret

popAppend:
	pop	ax, dx					;child od
append:
	call	ChunkArrayAppend
	jmp	new

GrObjBodyAddGrObjToSelectionListLow		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyIsGrObjSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if object is selected

PASS:		
		*(ds:si) - instance data of body
		cx:dx - OD of object to check
		
RETURN:		
		carry set if object is in selection list

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyIsGrObjSelected proc far
	uses	bx,di,si,ds
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	bx,cx
	call	ObjLockObjBlock
	mov	ds,ax
	mov	si,dx
	GrObjDeref	si,ds,si
	test	ds:[si].GOI_tempState, mask GOTM_SELECTED
	jz	notSelected

	stc

unlock:
	;    Unlock the grobjects block
	;

	call	MemUnlock				

	.leave
	ret

notSelected:
	clc
	jmp	unlock

GrObjBodyIsGrObjSelected		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyRemoveAllGrObjsFromSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove all children from selected list

PASS:		
		*(ds:si) - instance data of body
		
RETURN:		
		nothing

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on. And it must be careful about the
		regsiters is destroys.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyRemoveAllGrObjsFromSelectionList	method GrObjBodyClass, \
				MSG_GB_REMOVE_ALL_GROBJS_FROM_SELECTION_LIST
	uses	bx,cx,dx,bp,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	ax, MSG_META_SUSPEND
	call	ObjCallInstanceNoLock

	mov	bx, SEGMENT_CS				;call back segment
	mov	di, offset GrObjBodyRemoveLMemChildFromSelectionListCB
	call	GrObjBodyProcessSelectedGrObjsCommon

	mov	ax, MSG_META_UNSUSPEND
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBodyRemoveAllGrObjsFromSelectionList		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyRemoveLMemChildFromSelectionListCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes child from selection list

CALLED BY:	INTERNAL
		ObjCompProcessChildren

PASS:		
		*(ds:si) - child
		*(es:di) - composite object
		
RETURN:		
		clc - so that ObjCompProcessChildren

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	must be far because it is call back routine		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyRemoveLMemChildFromSelectionListCB		proc	far
	class	GrObjBodyClass
	uses	ax,bx,cx,dx,ds,si
	.enter

EC <	call	ECGrObjCheckLMemObject			>
EC <	push	ds,si					>
EC <	segmov	ds,es					>
EC <	mov	si,di					>
EC <	call	ECGrObjBodyCheckLMemObject		>
EC <	pop	ds,si					>

	mov	cx,ds:[LMBH_handle]		;od of child
	mov	dx,si
	segmov	ds,es				;od of composite
	mov	si,di
	CallMod	GrObjBodyRemoveGrObjFromSelectionList
	clc

	clc					;keep goin'!

	.leave
	ret
GrObjBodyRemoveLMemChildFromSelectionListCB		endp

 


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyProcessSelectedGrObjsCommonRV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process  all children of body that are in the
		selected list, procssing the selection list
		in reverse order

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - instance data of graphic body

		bx:di - call back routine
			(must be vfptr if XIP'ed)
		ax, cx, dx, bp - parameters to call back

		or
			bx = 0
			ax - message to send to children
			cx,dx,bp - parameters to message

			** IMPORTANT **

			unlike ObjCompProcessChildren, you don't get to
			pass nice OCCT flags in di to this routine. you get the
			equivalent of di = OCCT_SAVE_PARAMS_DONT_TEST_ABORT.

RETURN:		
		ax,cx,dx,bp - may be returned depending on message,
		call back or ObjCompCallType

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	WARNING: call back routine must be in the same segment
	as this routine or must have been locked explicitly
		
	In the call back routine 

	You CANNOT delete the current element or any elements before
	it.	

	You CANNOT insert at the current element or before it.

	Before means elements with lower element numbers, it is
	not meant to be relative to the direction we are enuming in.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyProcessSelectedGrObjsCommonRV	proc	far
	class	GrObjBodyClass
	uses	bx,di,es,si
	.enter

	push	ds:[LMBH_handle]			;body handle

	push	bx
	clr	bx
	mov	es, bx
	pop	bx
	push	es, es					;initial OD
	push	bx, di					;callback
	push	ds:[LMBH_handle], si			;composite

	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	call	GrObjBodySelectionArrayLock
	jc	clearStackDone
	call	ObjArrayProcessChildrenRV

	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
done:
	pop	bx					;body handle
	call	MemDerefDS

	.leave
	ret
clearStackDone:
	add	sp, 12
	jmp	done
GrObjBodyProcessSelectedGrObjsCommonRV	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyIsLMemGrObjSelected?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if object is selected

PASS:		
		*(ds:si) - instance data object
		*es:di - GraphicBody
		
RETURN:		
		stc - selected
		clc - not selected

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyIsLMemGrObjSelected? 	proc 	far
	class	GrObjClass
	uses	cx,dx,si,ds
	.enter				

EC <	call	ECGrObjCheckLMemObject					>
	mov	cx,ds:[LMBH_handle]			;object handle
	mov	dx,si					;object chunk
	segmov	ds,es					;body segment		
	mov	si,di					;body chunk
EC <	call	ECGrObjBodyCheckLMemObject				

	call	GrObjBodyIsGrObjSelected

	.leave
	ret

GrObjBodyIsLMemGrObjSelected?		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetBoundsOfSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the bounds encompassing all the selected objects
		
PASS:		
		*(ds:si) - instance data
		ss:bp - RectDWord

RETURN:		
		ss:bp - RectDWord

DESTROYED:	
		ax
		
PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on. And it must be careful about the
		regsiters is destroys.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetBoundsOfSelectedGrObjs method GrObjBodyClass, 
					MSG_GB_GET_BOUNDS_OF_SELECTED_GROBJS
	uses	bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	;    Initalize rect so that left is all the way to right, right
	;    is all the way to the left and so on.
	;	

	mov	ax, 0x8000
	clr	bx
	mov	ss:[bp].RD_right.low,bx
	mov	ss:[bp].RD_bottom.low,bx
	mov	ss:[bp].RD_right.high,ax
	mov	ss:[bp].RD_bottom.high,ax

	dec	ax					;= 7fffh
	dec	bx					;= ffffh

	mov	ss:[bp].RD_left.low,bx
	mov	ss:[bp].RD_top.low,bx
	mov	ss:[bp].RD_left.high,ax
	mov	ss:[bp].RD_top.high,ax


	mov	bx, SEGMENT_CS				;call back segment
	mov	di, offset GrObjBodyGetBoundsOfSelectedGrObjsCB
	call	GrObjBodyProcessSelectedGrObjsCommon

	.leave
	ret
GrObjBodyGetBoundsOfSelectedGrObjs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetBoundsOfGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the bounds encompassing all the objects
		
PASS:		
		*(ds:si) - instance data
		ss:bp - RectDWord

RETURN:		
		ss:bp - RectDWord

DESTROYED:	
		ax
		
PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on. And it must be careful about the
		regsiters is destroys.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetBoundsOfGrObjs method GrObjBodyClass, 
					MSG_GB_GET_BOUNDS_OF_GROBJS
	uses	bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	;    Initalize rect so that left is all the way to right, right
	;    is all the way to the left and so on.
	;	

	mov	ax, 0x8000
	clr	bx
	mov	ss:[bp].RD_right.low,bx
	mov	ss:[bp].RD_bottom.low,bx
	mov	ss:[bp].RD_right.high,ax
	mov	ss:[bp].RD_bottom.high,ax

	dec	ax					;= 7fffh
	dec	bx					;= ffffh

	mov	ss:[bp].RD_left.low,bx
	mov	ss:[bp].RD_top.low,bx
	mov	ss:[bp].RD_left.high,ax
	mov	ss:[bp].RD_top.high,ax


	mov	bx, SEGMENT_CS				;call back segment
	mov	di, offset GrObjBodyGetBoundsOfSelectedGrObjsCB
	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon

	.leave
	ret
GrObjBodyGetBoundsOfGrObjs		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetDWFBoundsOfSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the bounds encompassing all the selected objects
		
PASS:		
		*(ds:si) - instance data
		ss:bp - RectDWFixed

RETURN:		
		ss:bp - RectDWFixed

DESTROYED:	
		ax
		
PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11 Nov 1991	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetDWFBoundsOfSelectedGrObjs method GrObjBodyClass,
				MSG_GB_GET_DWF_BOUNDS_OF_SELECTED_GROBJS
	uses	bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	;    Initalize rect so that left is all the way to right, right
	;    is all the way to the left and so on.
	;	

	mov	bx, 0x8000
	clr	ax
	mov	ss:[bp].RDWF_right.DWF_frac, ax
	mov	ss:[bp].RDWF_bottom.DWF_frac, ax
	mov	ss:[bp].RDWF_right.DWF_int.low, ax
	mov	ss:[bp].RDWF_bottom.DWF_int.low, ax
	mov	ss:[bp].RDWF_right.DWF_int.high, bx 
	mov	ss:[bp].RDWF_bottom.DWF_int.high, bx

	dec	bx					;= 7fffh
	dec	ax					;= ffffh

	mov	ss:[bp].RDWF_left.DWF_frac, ax
	mov	ss:[bp].RDWF_top.DWF_frac, ax
	mov	ss:[bp].RDWF_left.DWF_int.low, ax
	mov	ss:[bp].RDWF_top.DWF_int.low, ax
	mov	ss:[bp].RDWF_left.DWF_int.high, bx 
	mov	ss:[bp].RDWF_top.DWF_int.high, bx

	mov	bx, SEGMENT_CS				;call back segment
	mov	di, offset GrObjBodyGetDWFBoundsOfSelectedGrObjsCB
	call	GrObjBodyProcessSelectedGrObjsCommon

	.leave
	ret
GrObjBodyGetDWFBoundsOfSelectedGrObjs		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetBoundsOfSelectedGrObjsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Combine bounds in stack frame with bounds of object
		
CALLED BY:	INTERNAL
		ObjCompProcessChildren

PASS:		*ds:si -- child handle
		*es:di -- composite handle
		ss:bp - RectDWord
ETURN:		
		clc - to keep search going


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetBoundsOfSelectedGrObjsCB		proc	far
	class	GrObjBodyClass
	uses	ax,bx,es,ds,si,di
	.enter

	mov	bx,bp				;primary RectDWord offset

	;    Get bounds of object in Bodies coordinate system
	;    in RectDWord
	;

	sub	sp, size RectDWord
	mov	bp,sp
	call	GrObjGetDWPARENTBounds

	;    Combine the passed bounds (primary) with the objects
	;    bounds (secondary). Storing results in primary bounds.
	;

	mov	ax,ss
	mov	ds,ax				;primary RectDWord seg
	mov	es,ax				;secondary RectDWord seg
	mov	si,bx				;primary RectDWord offset
	mov	di,bp				;secondary RectDWord offset
	mov	bp,bx				;primary RectDWord offset
	CallMod	GrObjCombineRectDWords

	add	sp,size RectDWord

	clc					;keep going

	.leave
	ret

GrObjBodyGetBoundsOfSelectedGrObjsCB		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetDWFBoundsOfSelectedGrObjsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Combine bounds in stack frame with bounds of object
		
CALLED BY:	INTERNAL
		ObjCompProcessChildren

PASS:		*ds:si -- child handle
		*es:di -- composite handle
		ss:bp - RectDWFixed
ETURN:		
		clc - to keep search going

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11 Nov 1991	Initial Revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetDWFBoundsOfSelectedGrObjsCB		proc	far
	class	GrObjBodyClass
	uses	ax,bx,es,ds,si,di
	.enter

	mov	bx,bp				;primary RectDWord offset

	;    Get bounds of object in Bodies coordinate system
	;    in RectDWFixed
	;

	sub	sp, size RectDWFixed
	mov	bp,sp
	call	GrObjGetDWFPARENTBounds

	;    Combine the passed bounds (primary) with the objects
	;    bounds (secondary). Storing results in primary bounds.
	;

	mov	ax,ss
	mov	ds,ax				;primary RectDWord seg
	mov	es,ax				;secondary RectDWord seg
	mov	si,bx				;primary RectDWord offset
	mov	di,bp				;secondary RectDWord offset
	mov	bp,bx				;primary RectDWord offset
	CallMod	GrObjGlobalCombineRectDWFixeds

	add	sp,size RectDWFixed
	clc					;keep going

	.leave
	ret

GrObjBodyGetDWFBoundsOfSelectedGrObjsCB		endp

GrObjRequiredExtInteractive2Code	ends

GrObjAlmostRequiredCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySelectionArrayLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the block containing the selection array

CALLED BY:	

PASS:		*ds:si - GrObjBody object

RETURN:		bx - handle of selection array
		IF SELECTION ARRAY IS AVAILBLE:
			*ds:si - Selection array,
			carry clear
		ELSE
			carry set
			si - trashed

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon/cdb	18 Nov 1991	Initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySelectionArrayLock	proc far
	class	GrObjBodyClass
	uses	ax
	.enter

EC <	call	ECGrObjBodyCheckLMemObject		>

	mov	bx, ds:[si]
	add	bx, ds:[bx].GrObjBody_offset
	mov	si, ds:[bx].GBI_selectionArray.chunk
	mov	bx, ds:[bx].GBI_selectionArray.handle
	tst	bx
	jz	necError					
	call	MemLock
	jc	done
	mov	ds, ax
done:
	.leave
	ret

necError:			
	stc			
	jmp	done		

GrObjBodySelectionArrayLock	endp

GrObjAlmostRequiredCode	ends

GrObjInitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCreateSelectionArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate chunk array to hold ods of selected objects.

CALLED BY:	INTERNAL
		GrObjBodyAttachUI

PASS:		
		*ds:si - GrObjBody

RETURN:		
		GBI_selectionArray

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
	srs	1/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateSelectionArray		proc	far
	class	GrObjBodyClass
	uses	ax,cx,dx,di
	.enter

EC <	call 	ECGrObjBodyCheckLMemObject				>

	;    Allocate a chunk array to keep track of selected objects
	;

	mov	ax, size ChunkArrayHeader
	mov	cx, ALLOC_DYNAMIC_NO_ERR or (mask HAF_LOCK shl 8)
	call	MemAlloc

	push	bx				;save allocated mem handle

	push	ds, si				;save body ptr

	mov	ds, ax
	mov	cx, 4				;4 initial handles?
	mov	ax, LMEM_TYPE_GENERAL
	mov	dx, size LMemBlockHeader
	mov	si, size ChunkArrayHeader	;make room for header
	clr	di				;no lmem flags
	call	LMemInitHeap

	mov	al, mask OCF_IGNORE_DIRTY	;is this right?
	mov	bx, size optr			;element size
	clr	cx				;default header size
	mov	si,cx
	call	ChunkArrayCreate
	mov_trash	ax, si			;ax <- header chunk
	pop	ds, si				;*ds:si <- body
	
	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset

	pop	bx

	mov	ds:[di].GBI_selectionArray.handle, bx
	mov	ds:[di].GBI_selectionArray.chunk, ax

	call	MemUnlock

	.leave
	ret
GrObjBodyCreateSelectionArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyDestroySelectionArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the graphic body's selection array

CALLED BY:	INTERNAL
		GrObjBodyDetachUI

PASS:		*ds:si - GrObjBody

RETURN:		
		GBI_selectionArray.handle - zeroed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			selection array exists

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDestroySelectionArray		proc	far
	class	GrObjBodyClass
	uses	bx
	.enter

EC <	call	ECGrObjBodyCheckLMemObject		>

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	clr	bx
	xchg	bx, ds:[di].GBI_selectionArray.handle
	tst	bx
	jz	done
	call	MemFree
done:

	.leave
	ret
GrObjBodyDestroySelectionArray		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendGenerateNotifyToSelectedGrObjTexts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_VIS_TEXT_GENERATE_NOTIFY to all the selected
		text objects and all the text objects in groups
		that are selected.

CALLED BY:	INTERNAL 

PASS:		
		*ds:si - instance data of graphic body
		ss:bp - VisTextGenerateNotifyParams

RETURN:		nothing
		
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendGenerateNotifyToSelectedGrObjTexts 	proc	far
	uses	ax,bx,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	push	ds:[LMBH_handle]			;body handle

	clr	bx
	push	bx, bx					;initial OD
FXIP<	mov	bx, SEGMENT_CS						>
FXIP<	push	bx							>
	mov	bx, offset GrObjBodySendGenerateNotifyToSelectedGrObjTextsCB
FXIP<	push	bx							>
NOFXIP<	push	cs, bx					;callback 	>
	push	ds:[LMBH_handle], si			;composite

	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	call	GrObjBodySelectionArrayLock
	jc	clearStackDone
	mov	cx,ss
	mov	dx,size VisTextGenerateNotifyParams
	call	ObjArrayProcessChildren
	call	MemUnlock

	pop	bx					;body handle
	call	MemDerefDS

done:
	.leave
	ret

clearStackDone:
	add	sp,14
	jmp	done
GrObjBodySendGenerateNotifyToSelectedGrObjTexts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendGenerateNotifyToSelectedGrObjTextsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_VIS_TEXT_GENERATE_NOTIFY to the object if
		it is a text object. Send MSG_GROUP_VIS_TEXT_GENERATE_NOTIFY
		to object if it is a group.

CALLED BY:	ObjArrayProcessChildren

PASS:		*ds:si - child optr
		*es:di - composite optr
		ss:bp - VisTextGenerateNotifyParams
		dx - size VisTextGenerateNotifyParams
		cx = ss


RETURN:		clc - to keep processing

DESTROYED:	bx, si, di, ds, es

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8 jun 1992	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendGenerateNotifyToSelectedGrObjTextsCB	proc	far
	uses	cx,dx,bp
	.enter

	push	cx, dx, bp				;message params
	mov	cx, segment TextGuardianClass
	mov	dx, offset TextGuardianClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLockES
	pop	cx, dx, bp				; message params
	jnc	checkGroup

	;
	;  We're a text guardian, so send the message to the ward
	;
	mov	ax,MSG_VIS_TEXT_GENERATE_NOTIFY
	mov	di, mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
	call	GrObjVisGuardianMessageToVisWard

done:
	clc				;keep processing
	.leave
	ret


checkGroup:
	push	cx, dx, bp				;message params
	mov	cx, segment GroupClass
	mov	dx, offset GroupClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLockES
	pop	cx, dx, bp				; message params
	jnc	done

	mov	ax,MSG_GROUP_VIS_TEXT_GENERATE_NOTIFY
	call	ObjCallInstanceNoLockES
	jmp	done


GrObjBodySendGenerateNotifyToSelectedGrObjTextsCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCheckForSelectedGrObjTexts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if any of the selected objects is a text object.
		Or any of the selected groups contains a text object.

CALLED BY:	INTERNAL 

PASS:		
		*ds:si - instance data of graphic body

RETURN:		stc - there is at least one selected text object
		clc - there are no selected grobj texts
		
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCheckForSelectedGrObjTexts 	proc	far
	uses	ax,bx,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	push	ds:[LMBH_handle]			;body handle

	clr	bx
	push	bx, bx					;initial OD
FXIP<	mov	bx, SEGMENT_CS						>
FXIP<	push	bx							>
	mov	bx,offset GrObjBodyCheckForSelectedGrObjTextsCB
FXIP<	push	bx							>
NOFXIP<	push	cs,bx					;callback 	>
	push	ds:[LMBH_handle], si			;composite

	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	call	GrObjBodySelectionArrayLock
	jc	clearStackDone
	call	ObjArrayProcessChildren
	call	MemUnlock

	pop	bx					;body handle
	call	MemDerefDS

done:
	.leave
	ret

clearStackDone:
	add	sp,14
	jmp	done
GrObjBodyCheckForSelectedGrObjTexts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCheckForSelectedGrObjTextsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If object is text object or a group with a text object
		in it then stop processing

CALLED BY:	ObjArrayProcesChildren

PASS:		*ds:si - child optr
		*es:di - composite optr


RETURN:		stc - a selected text object was found
		clc - to keep processing

DESTROYED:	bx, si, di, ds, es

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8 jun 1992	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCheckForSelectedGrObjTextsCB	proc	far
	uses	cx,dx,bp
	.enter

	push	cx, dx, bp				;message params
	mov	cx, segment TextGuardianClass
	mov	dx, offset TextGuardianClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLockES
	pop	cx, dx, bp				; message params
	jnc	checkGroup

done:
	.leave
	ret


checkGroup:
	push	cx, dx, bp				;message params
	mov	cx, segment GroupClass
	mov	dx, offset GroupClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLockES
	pop	cx, dx, bp				; message params
	jnc	done

	mov	ax,MSG_GROUP_CHECK_FOR_GROBJ_TEXTS
	call	ObjCallInstanceNoLockES
	jmp	done


GrObjBodyCheckForSelectedGrObjTextsCB	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendToSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to all children of body that are in
		the selected list.  The message will be sent to all
		selected children regardless of message return values.

CALLED BY:	INTERNAL
		

PASS:		
		*ds:si - instance data of graphic body
		ax - message to send to selected children
		cx,dx,bp - parameters to message

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
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendToSelectedGrObjs		proc	far
	uses	bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	clr	bx
	mov	di,OCCT_SAVE_PARAMS_DONT_TEST_ABORT
	call	GrObjBodyProcessSelectedGrObjsCommon

	.leave
	ret
GrObjBodySendToSelectedGrObjs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendToFirstSelectedGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the body's first selected grobj

CALLED BY:	INTERNAL

PASS:		
		*ds:si - instance data of graphic body
		ax - message to send to selected children
		cx,dx,bp - parameters to message

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
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendToFirstSelectedGrObj		proc	far
	uses	bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	clr	bx
	mov	di,OCCT_ABORT_AFTER_FIRST
	call	GrObjBodyProcessSelectedGrObjsCommon

	.leave
	ret
GrObjBodySendToFirstSelectedGrObj		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendToSelectedGrObjsShareData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to all children of body that are in
		the selected list.  The message will be sent to all
		selected children regardless of message return values.

CALLED BY:	INTERNAL
		

PASS:		
		*ds:si - instance data of graphic body
		ax - message to send to selected children
		cx,dx,bp - parameters to message

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
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendToSelectedGrObjsShareData	method dynamic	GrObjBodyClass,
				MSG_GB_SEND_TO_SELECTED_GROBJS_SHARE_DATA
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov_tr	ax, cx
	clr	bx
	mov	di,OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	call	GrObjBodyProcessSelectedGrObjsCommon

	.leave
	ret
GrObjBodySendToSelectedGrObjsShareData		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendToSelectedGrObjsAndEditGrab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Send method to all objects on the selection list
		and the object with the edit grab

CALLED BY:	INTERNAL

PASS:		
		*ds:si - GrObjBody
		ax - Message #
		cx,dx,bp - data to pass with method

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
	srs	6/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendToSelectedGrObjsAndEditGrab		proc	far
	uses	di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	call	GrObjBodySendToSelectedGrObjs
	mov	di,mask MF_FIXUP_DS
	call	GrObjBodyMessageToEdit

	.leave
	ret
GrObjBodySendToSelectedGrObjsAndEditGrab		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyProcessSelectedGrObjsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process to all children of body that are in the
		selected list

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - instance data of graphic body

		bx:di - call back routine
		(must be vfptr if XIP'ed)
		ax, cx, dx, bp - parameters to call back

		or
			bx = 0
			di - ObjCompCallType
			ax - message to send to children
			cx,dx,bp - parameters to message

RETURN:		
		ax,cx,dx,bp - may be returned depending on message,
		call back or ObjCompCallType

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyProcessSelectedGrObjsCommon	proc	far
	class	GrObjBodyClass
	uses	bx,di,es,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	push	ds:[LMBH_handle]			;body handle

	tst	bx
	jnz	bxNonZero
	push	bx, bx					;initial OD
afterPushOD:
	push	bx, di					;callback
	push	ds:[LMBH_handle], si			;composite

	;
	;  Lock the selection array (in-line for speed)
	;
	push	ax
	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	movdw	bxsi, ds:[di].GBI_selectionArray
	tst	bx
	jz	popAXClearStackDone				
	call	MemLock
	jc	popAXClearStackDone
	mov	ds, ax
	pop	ax

	jc	clearStackDone
	call	ObjArrayProcessChildren

	mov	bx, ds:[LMBH_handle]			;selection array handle
	call	MemUnlock
done:
	pop	bx					;body handle
	call	MemDerefDS

	.leave
	ret
bxNonZero:
	;
	; I'm pretty sure this is illegal in protected mode, but what the hey?
	;
	push	bx
	clr	bx
	mov	es, bx
	pop	bx
	push	es, es
	jmp	afterPushOD

popAXClearStackDone:
	pop	ax
clearStackDone:
	add	sp, 12
	jmp	done
GrObjBodyProcessSelectedGrObjsCommon	endp

GrObjInitCode	ends


GrObjObscureExtNonInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetSummedDWFDimensionsOfSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the summed heights and widths of the selected objects
		
PASS:		
		*(ds:si) - instance data
		ss:bp - PointDWFixed
		
RETURN:		
		ss:bp - PointDWFixed

DESTROYED:	
		ax
		
PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11 Nov 1991	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetSummedDWFDimensionsOfSelectedGrObjs method GrObjBodyClass,
			MSG_GB_GET_SUMMED_DWF_DIMENSIONS_OF_SELECTED_GROBJS
	uses	bx,cx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	;    Initalize width and height to 0
	;	
	segmov	es, ss, ax
	mov	di, bp
	mov	cx, size PointDWFixed / 2
	clr	ax
	rep	stosw

	mov	bx, SEGMENT_CS				;call back segment
	mov	di, offset GrObjBodyGetSummedDWFDimensionsOfSelectedGrObjsCB
	call	GrObjBodyProcessSelectedGrObjsCommon

	.leave
	ret
GrObjBodyGetSummedDWFDimensionsOfSelectedGrObjs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetSummedDWFDimensionsOfSelectedGrObjsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Adds objects height and width to the passed buffer.
		
CALLED BY:	INTERNAL
		ObjCompProcessChildren

PASS:		*ds:si -- child handle
		*es:di -- composite handle
		ss:bp - PointDWFixed

RETURN:		
		clc - to keep going

DESTROYED:	
		ax, bx, cx, dx, di, si		which is "OK", since this
						is a callback routine where
						ax, cx, dx are unimportant

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	11 Nov 1991	Initial Revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetSummedDWFDimensionsOfSelectedGrObjsCB		proc	far
	class	GrObjBodyClass
passedPtr	local	word	;push	bp		;here's the passed ptr
localRect	local	RectDWFixed

	mov	ax, bp

	.enter

	mov	passedPtr, ax
	;    Get the object's bounds
	;

	push	bp
	lea	bp, ss:localRect
	mov	ax, MSG_GO_GET_DWF_PARENT_BOUNDS
	call	ObjCallInstanceNoLock
	pop	bp					;bx <- passed ptr

	MovDWF	dx, cx, ax, localRect.RDWF_right
	SubDWF	dx, cx, ax, localRect.RDWF_left
	MovDWF	bx, si, di, localRect.RDWF_bottom
	SubDWF	bx, si, di, localRect.RDWF_top

	push	bp
	mov	bp, passedPtr

	AddDWF	ss:[bp].PDF_x, dx, cx, ax
EC<	ERROR_C	OBJECT_DIMENSION_SUM_OVERFLOW		>

	AddDWF	ss:[bp].PDF_y, bx, si, di
EC<	ERROR_C	OBJECT_DIMENSION_SUM_OVERFLOW		>
	pop	bp
	.leave
	ret
GrObjBodyGetSummedDWFDimensionsOfSelectedGrObjsCB		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyGetDwfBoundsOfLastSelectedGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_GET_DWF_BOUNDS_OF_LAST_SELECTED_GROBJ

Called by:	INTERNAL

Pass:		*ds:si = graphic body
		ss:bp = RectDWFixed
		dx >= size RectDWFixed

Return:		ss:bp = RectDWFixed bounds of last selected object

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 24, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetDWFBoundsOfLastSelectedGrObj	method	GrObjBodyClass, 
			MSG_GB_GET_DWF_BOUNDS_OF_LAST_SELECTED_GROBJ
	uses	ax, bx, cx, di, si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject		>

	push	ds:[LMBH_handle]			;body handle

	;    Find the last element in the array
	;

	call	GrObjBodySelectionArrayLock
EC <	ERROR_C	GROBJ_BODY_SELECTION_ARRAY_NOT_FOUND		>
	call	ChunkArrayGetCount
	dec	cx
	mov_tr	ax, cx
	call	ChunkArrayElementToPtr

	;    Get the object's parent bounds
	;

	mov	bx, ds:[di].handle
	mov	si, ds:[di].chunk
	mov	ax, MSG_GO_GET_DWF_PARENT_BOUNDS	
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage

	pop	bx					;body handle
	call	MemDerefDS

	.leave
	ret
GrObjBodyGetDWFBoundsOfLastSelectedGrObj	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetDwfBoundsOfFirstSelectedGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_GET_DWF_BOUNDS_OF_FIRST_SELECTED_GROBJ

Called by:	INTERNAL

Pass:		*ds:si = graphic body
		ss:bp = RectDWFixed
		dx >= size RectDWFixed

Return:		ss:bp = RectDWFixed bounds of first selected object

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 24, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetDWFBoundsOfFirstSelectedGrObj	method	GrObjBodyClass, 
				MSG_GB_GET_DWF_BOUNDS_OF_FIRST_SELECTED_GROBJ
	uses	ax, bx, di, si
	.enter

	push	ds:[LMBH_handle]			;body handle

	;    Find the first element in the array
	;

	call	GrObjBodySelectionArrayLock
EC <	ERROR_C	GROBJ_BODY_SELECTION_ARRAY_NOT_FOUND		>
	clr	ax
	call	ChunkArrayElementToPtr

	;    Get the object's parent bounds
	;
	mov	bx, ds:[di].handle
	mov	si, ds:[di].chunk
	mov	ax, MSG_GO_GET_DWF_PARENT_BOUNDS	
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage

	pop	bx					;body handle
	call	MemDerefDS

	.leave
	ret
GrObjBodyGetDWFBoundsOfFirstSelectedGrObj	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyGetCenterOfLastSelectedGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_GET_CENTER_OF_LAST_SELECTED_GROBJ

Called by:	INTERNAL

Pass:		*ds:si = graphic body
		ss:bp = PointDWFixed
		dx >= size PointDWFixed

Return:		ss:bp = PointDWFixed center of last selected object

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 24, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetCenterOfLastSelectedGrObj	method	GrObjBodyClass, 
				MSG_GB_GET_CENTER_OF_LAST_SELECTED_GROBJ
	uses	ax, bx, cx, di, si
	.enter

	push	ds:[LMBH_handle]			;body handle

	;    Find the last element in the array
	;

	call	GrObjBodySelectionArrayLock
EC <	ERROR_C	GROBJ_BODY_SELECTION_ARRAY_NOT_FOUND		>
	call	ChunkArrayGetCount
	dec	cx
	mov_tr	ax, cx
	call	ChunkArrayElementToPtr

	;    Get the object's parent bounds
	;

	mov	bx, ds:[di].handle
	mov	si, ds:[di].chunk
	mov	ax, MSG_GO_GET_CENTER
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage

	pop	bx					;body handle
	call	MemDerefDS

	.leave
	ret
GrObjBodyGetCenterOfLastSelectedGrObj	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetCenterOfFirstSelectedGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_GET_CENTER_OF_FIRST_SELECTED_GROBJ

Called by:	INTERNAL

Pass:		*ds:si = graphic body
		ss:bp = PointDWFixed
		dx >= size PointDWFixed

Return:		ss:bp = PointDWFixed center of first selected object

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 24, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetCenterOfFirstSelectedGrObj	method	GrObjBodyClass, MSG_GB_GET_CENTER_OF_FIRST_SELECTED_GROBJ
	uses	ax, bx, di, si
	.enter

	push	ds:[LMBH_handle]			;body handle

	;    Find the last element in the array
	;

	call	GrObjBodySelectionArrayLock
EC <	ERROR_C	GROBJ_BODY_SELECTION_ARRAY_NOT_FOUND		>
	clr	ax
	call	ChunkArrayElementToPtr

	;    Get the object's parent bounds
	;

	mov	bx, ds:[di].handle
	mov	si, ds:[di].chunk
	mov	ax, MSG_GO_GET_CENTER
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage

	pop	bx					;body handle
	call	MemDerefDS

	.leave
	ret
GrObjBodyGetCenterOfFirstSelectedGrObj	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetCenterOfSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_GET_CENTER_OF_SELECTED_GROBJS

Called by:	INTERNAL

Pass:		*ds:si = graphic body
		ss:bp = PointDWFixed
		dx >= size PointDWFixed

Return:		ss:bp = PointDWFixed center of first selected object

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 24, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetCenterOfSelectedGrObjs	method	GrObjBodyClass,
					MSG_GB_GET_CENTER_OF_SELECTED_GROBJS
	uses	bx
	.enter

	mov	bx, bp					;ss:bx <- PointDWF
	sub	sp, size RectDWFixed
	mov	bp, sp
	mov	ax, MSG_GB_GET_DWF_BOUNDS_OF_SELECTED_GROBJS
	call	ObjCallInstanceNoLock

	movdwf	ss:[bx].PDF_x, ss:[bp].RDWF_right, ax
	adddwf	ss:[bx].PDF_x, ss:[bp].RDWF_left, ax
	movdwf	ss:[bx].PDF_y, ss:[bp].RDWF_bottom, ax
	adddwf	ss:[bx].PDF_y, ss:[bp].RDWF_top, ax

	mov	bp, bx
	sardwf	ss:[bp].PDF_x
	sardwf	ss:[bp].PDF_y

	add	sp, size RectDWFixed

	.leave
	ret
GrObjBodyGetCenterOfSelectedGrObjs	endm





GrObjObscureExtNonInteractiveCode	ends





GrObjExtNonInteractiveCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyDeleteSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Delete all of the children on the selected list
		
PASS:		
		*(ds:si) - instance data

RETURN:		
		nothing

DESTROYED:	
		ax
		
PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDeleteSelectedGrObjs method dynamic GrObjBodyClass, 
					MSG_GB_DELETE_SELECTED_GROBJS
	uses	cx,dx
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	call	GrObjGlobalStartUndoChainNoText
	clr	bx
	mov	di,OCCT_SAVE_PARAMS_DONT_TEST_ABORT
	mov	ax,MSG_GO_CLEAR
	call	GrObjBodyProcessSelectedGrObjsCommon
	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjBodyDeleteSelectedGrObjs		endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPullSelectedGrObjsToFront
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring the selected grobjs to the front of the document.
		(i.e. move them to the end of the drawing list)


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

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
	srs	5/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyPullSelectedGrObjsToFront	method dynamic GrObjBodyClass, 
					MSG_GB_PULL_SELECTED_GROBJS_TO_FRONT
	.enter

	mov	cx,handle bringToFrontString
	mov	dx,offset bringToFrontString
	call	GrObjGlobalStartUndoChain

	mov	bx, SEGMENT_CS
	mov	di, offset GrObjBodyPullSelectedGrObjsToFrontCB
	call	GrObjBodyProcessSelectedGrObjsCommon

	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjBodyPullSelectedGrObjsToFront		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPullSelectedGrObjsToFrontCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move child to front of draw list


CALLED BY:	INTERNAL
		ObjCompProcessChildren
		GrObjBodyPullSelectedGrObjsToFront

PASS:		
		*ds:si - child
		*es:di - group

RETURN:		
		clc - to keep processing

DESTROYED:	
		ax,cx,dx,di,si,es,ds 

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyPullSelectedGrObjsToFrontCB		proc	far
	.enter

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	segmov	ds,es
	mov	si,di
	mov	bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_CHANGE_GROBJ_DEPTH
	call	ObjCallInstanceNoLock
	clc

	.leave
	ret
GrObjBodyPullSelectedGrObjsToFrontCB		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPushSelectedGrObjsToBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push the selected grobjs to the back of the document.
		(i.e. move them to the begining of the drawing list)


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

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
	srs	5/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyPushSelectedGrObjsToBack	method dynamic GrObjBodyClass, 
					MSG_GB_PUSH_SELECTED_GROBJS_TO_BACK
	.enter

	mov	cx,handle sendToBackString
	mov	dx,offset sendToBackString
	call	GrObjGlobalStartUndoChain

	mov	bx, SEGMENT_CS
	mov	di, offset GrObjBodyPushSelectedGrObjsToBackCB
	call	GrObjBodyProcessSelectedGrObjsCommonRV

	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjBodyPushSelectedGrObjsToBack		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPushSelectedGrObjsToBackCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move child to begining of draw list


CALLED BY:	INTERNAL
		ObjCompProcessChildren
		GrObjBodyPushSelectedGrObjsToBack

PASS:		
		*ds:si - child
		*es:di - group

RETURN:		
		clc - to keep processing

DESTROYED:	
		ax,cx,dx,di,si,es,ds 

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyPushSelectedGrObjsToBackCB		proc	far
	.enter

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	segmov	ds,es
	mov	si,di
	mov	bp,GOBAGOR_FIRST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_CHANGE_GROBJ_DEPTH
	call	ObjCallInstanceNoLock
	clc

	.leave
	ret
GrObjBodyPushSelectedGrObjsToBackCB		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyShuffleSelectedGrObjsUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move each selected grobj on top of the first object
		above it that overlaps it, unless then overlapping
		object is selected.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

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
	srs	5/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyShuffleSelectedGrObjsUp	method dynamic GrObjBodyClass, 
					MSG_GB_SHUFFLE_SELECTED_GROBJS_UP
	uses	cx,dx
	.enter

	mov	cx,handle shuffleUpString
	mov	dx,offset shuffleUpString
	call	GrObjGlobalStartUndoChain

	;   Need reorder before and after shuffle so that undo, and
	;   undoing undo will not dork the selection array.
	;

	mov	ax,MSG_GB_REORDER_SELECTION_ARRAY
	call	ObjCallInstanceNoLock

	mov	bx, SEGMENT_CS
	mov	di, offset GrObjBodyShuffleSelectedGrObjsUpCB
	call	GrObjBodyProcessSelectedGrObjsCommonRV

	mov	ax,MSG_GB_REORDER_SELECTION_ARRAY
	call	ObjCallInstanceNoLock

	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjBodyShuffleSelectedGrObjsUp		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyShuffleSelectedGrObjsUpCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move child to front of object that overlaps it.


CALLED BY:	INTERNAL
		ObjCompProcessChildren
		GrObjBodyShuffleSelectedGrObjsUp

PASS:		
		*ds:si - child
		*es:di - group

RETURN:		
		clc - to keep processing

DESTROYED:	
		ax,cx,dx,di,si,es,ds 

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyShuffleSelectedGrObjsUpCB		proc	far
	uses	cx,dx,ds,si,es,di,ax,bp
	.enter

	;    Find object that overlaps this grobject
	;

	mov	cx,ds:[LMBH_handle]			;object handle
	mov	dx,si					;object chunk
	segxchg	ds,es					;body seg, obj seg
	xchg	si,di					;body chunk, obj chunk
	mov	ax,MSG_GB_FIND_NEXT_GROBJ_THAT_OVERLAPS
	call	ObjCallInstanceNoLockES
	jcxz	done

	;    If the overlapping object is selected don't move in front of it.
	;

	call	GrObjBodyIsGrObjSelected
	jc	done

	;    Get position of grobject to move in front of
	;

	mov	ax,MSG_GB_FIND_GROBJ
	call	ObjCallInstanceNoLockES

	;    Move child to before the overlapping child in the
	;    reverse list.
	;

	mov	bp,dx					;reverse position
	mov	cx,es:[LMBH_handle]			;obj to move handle
	mov	dx,di					;obj to move chunk
	mov	ax,MSG_GB_CHANGE_GROBJ_DEPTH
	call	ObjCallInstanceNoLockES

done:
	clc
	.leave
	ret
GrObjBodyShuffleSelectedGrObjsUpCB		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyShuffleSelectedGrObjsDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move each selected grobj on below of the first object
		below it that overlaps it, unless then overlapping
		object is selected.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

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
	srs	5/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyShuffleSelectedGrObjsDown	method dynamic GrObjBodyClass, 
					MSG_GB_SHUFFLE_SELECTED_GROBJS_DOWN
	uses	cx,dx
	.enter

	mov	cx,handle shuffleDownString
	mov	dx,offset shuffleDownString
	call	GrObjGlobalStartUndoChain

	;   Need reorder before and after shuffle so that undo, and
	;   undoing undo will not dork the selection array.
	;

	mov	ax,MSG_GB_REORDER_SELECTION_ARRAY
	call	ObjCallInstanceNoLock

	mov	bx, SEGMENT_CS
	mov	di, offset GrObjBodyShuffleSelectedGrObjsDownCB
	call	GrObjBodyProcessSelectedGrObjsCommon

	mov	ax,MSG_GB_REORDER_SELECTION_ARRAY
	call	ObjCallInstanceNoLock

	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjBodyShuffleSelectedGrObjsDown		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyShuffleSelectedGrObjsDownCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move child to behind object below it that overlaps it


CALLED BY:	INTERNAL
		ObjCompProcessChildren
		GrObjBodyShuffleSelectedGrObjsDown

PASS:		
		*ds:si - child
		*es:di - group

RETURN:		
		clc - to keep processing

DESTROYED:	
		ax,cx,dx,di,si,es,ds 

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyShuffleSelectedGrObjsDownCB		proc	far
	uses	cx,dx,ds,si,es,di,ax,bp
	.enter

	;    Find object that overlaps this grobject
	;

	mov	cx,ds:[LMBH_handle]			;object handle
	mov	dx,si					;object chunk
	segxchg	ds,es					;body seg, obj seg
	xchg	si,di					;body chunk, obj chunk
	mov	ax,MSG_GB_FIND_PREV_GROBJ_THAT_OVERLAPS
	call	ObjCallInstanceNoLockES
	jcxz	done

	;    If the overlapping object is selected don't move in behind it.
	;

	call	GrObjBodyIsGrObjSelected
	jc	done

	;    Get position of grobject to move behind
	;

	mov	ax,MSG_GB_FIND_GROBJ
	call	ObjCallInstanceNoLockES

	;    Move child to before the overlapping child in the
	;    draw list.
	;

	mov	bp,cx					;draw position
	ornf	bp,mask GOBAGOF_DRAW_LIST_POSITION
	mov	cx,es:[LMBH_handle]			;obj to move handle
	mov	dx,di					;obj to move chunk
	mov	ax,MSG_GB_CHANGE_GROBJ_DEPTH
	call	ObjCallInstanceNoLockES

done:
	clc
	.leave
	ret
GrObjBodyShuffleSelectedGrObjsDownCB		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyReorderSelectionArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke and rebuild the selection array so that it is in 
		draw order. The array is rebuilt from objects that
		have their GOTM_SELECTED bit set.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

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
	srs	11/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyReorderSelectionArray	method dynamic GrObjBodyClass, 
						MSG_GB_REORDER_SELECTION_ARRAY
	.enter

	call	GrObjGlobalStartUndoChainNoText

	mov	ax,MSG_GB_REORDER_SELECTION_ARRAY	;undo message
	clr	bx					;AddUndoActionFlags
	call	GrObjGlobalAddFlagsUndoAction

	push	ds,si					;body
	call	GrObjBodySelectionArrayLock
EC <	ERROR_C	GROBJ_BODY_SELECTION_ARRAY_NOT_FOUND		>
	call	ChunkArrayZero
	call	MemUnlock				;selection array
	pop	ds,si					;body

	mov	bx, SEGMENT_CS
	mov	di, offset GrObjBodyAppendSelectedGrObjsToSelectionArrayCB
	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon

	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjBodyReorderSelectionArray		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAppendSelectedGrObjsToSelectionArrayCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the grobject has its GOTM_SELECTED bit set then
		append it to the selection array

CALLED BY:	INTERNAL
		GrObjBodyReorderSelectionArray as call back

PASS:		
		*ds:si - grobject
		*es:di - body

RETURN:		
		clc - to keep processing

DESTROYED:	
		ds,si,di - ok because call back

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAppendSelectedGrObjsToSelectionArrayCB		proc	far
	uses	cx,dx
	.enter

	push	di					;body chunk
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_tempState, mask GOTM_SELECTED
	pop	di					;body chunk		
	jz	done

	mov	cx,ds:[LMBH_handle]			;object handle
	mov	dx,si					;object chunk
	segmov	ds,es					;body segment
	mov	si,di					;body chunk

	call	GrObjBodySelectionArrayLock
EC <	ERROR_C	GROBJ_BODY_SELECTION_ARRAY_NOT_FOUND		>

	call	ChunkArrayAppend
	mov	ds:[di].handle, cx
	mov	ds:[di].offset, dx

	call	MemUnlock				;selection array

done:
	clc
	.leave
	ret
GrObjBodyAppendSelectedGrObjsToSelectionArrayCB		endp



GrObjExtNonInteractiveCode	ends


GrObjRequiredInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetNumSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return number of children in in selection list

PASS:		
		*(ds:si) - instance data of body
RETURN:		
		bp - number of children
		
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on.And it must be careful about the
		regsiters is destroys.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetNumSelectedGrObjs	method GrObjBodyClass, 
				MSG_GB_GET_NUM_SELECTED_GROBJS

	uses	bx,cx,di, si,ds
	.enter				

EC <	call	ECGrObjBodyCheckLMemObject			>

	;    Use ObjCompFindChild with non-existent child to
	;    count number of selected children
	;

	call	GrObjBodySelectionArrayLock
	jc	none

	call	ChunkArrayGetCount
	mov	bp, cx

	call	MemUnlock	
done:
	.leave
	ret

none:
	clr	bp
	jmp	done

GrObjBodyGetNumSelectedGrObjs		endp

GrObjRequiredInteractiveCode	ends

GrObjRequiredCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendClassedEventToSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a classed event to all grobjs that are in the
		selected list

CALLED BY:	INTERNAL 
		ObjCallMethodTable
		GrObjBodySendClassedEvent
PASS:		
		*ds:si - instance data of graphic body

		cx - event handle
		dx - TravelOption

RETURN:		
		ds - updated if moved
		event destroyed
		
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on. And it must be careful about the
		regsiters is destroys.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendClassedEventToSelectedGrObjs method GrObjBodyClass,
				MSG_GB_SEND_CLASSED_EVENT_TO_SELECTED_GROBJS
	uses	cx,bx,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	push	ds:[LMBH_handle]			;body handle

	clr	bx
	push	bx, bx					;initial O
FXIP<	mov	bx, SEGMENT_CS						>
FXIP<	push	bx							>
	mov	bx, offset GrObjBodySendClassedEventToSelectedGrObjsCB
FXIP<	push	bx							>
NOFXIP<	push	cs, bx					;callback 	>
	push	ds:[LMBH_handle], si			;composite

	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	call	GrObjBodySelectionArrayLock
	jc	clearStackDone
	call	ObjArrayProcessChildren

	mov	bx,cx					;bx <- event handle
	call	ObjFreeMessage

	mov	bx, ds:[LMBH_handle]			;bx <- array handle
	call	MemUnlock

	pop	bx					;body handle
	call	MemDerefDS

done:
	.leave
	ret

clearStackDone:
	add	sp,14
	mov	bx,cx
	call	ObjFreeMessage
	jmp	done


GrObjBodySendClassedEventToSelectedGrObjs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendClassedEventToSelectedGrObjsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate the classed event and send it to the child
-
CALLED BY:	INTERNAL
		GrObjBodySendClassedEventToSelectedGrObjs

PASS:		
		*ds:si - child optr
		*es:di - composite optr
		cx - event handle
		dx - TravelOption

RETURN:		
		clc - to keep processing

DESTROYED:	
		bx - ok because call back routine

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendClassedEventToSelectedGrObjsCB		proc	far
	uses	ax,cx,dx,bp
	.enter

	mov	bx,cx					;event handle
	call	ObjDuplicateMessage
	mov	cx,ax					;new event handle	
	mov	ax,MSG_META_SEND_CLASSED_EVENT
	call	ObjCallInstanceNoLockES

	.leave
	ret
GrObjBodySendClassedEventToSelectedGrObjsCB		endp

GrObjRequiredCode	ends
