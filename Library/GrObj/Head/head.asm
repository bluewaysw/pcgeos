COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	GeoDraw
FILE:		graphicHead.asm

AUTHOR:		Steve Scholl, Jun 18, 1991

ROUTINES:
	Name			
	----			
INT	GrObjHeadCreateBlock		
INT	GrObjHeadCreateFloater	
INT	GrObjHeadDestroyFloater	
INT	GrObjHeadGetCurrentBody	
INT	GrObjHeadMessageToFloater	
INT	GrObjHeadAllLargePTRS

METHOD HANDLERS:
	Name			
	----			
	GrObjHeadSetCurrentTool		
	GrObjHeadSetCurrentToolWithDataBlock		
	GrObjHeadGetCurrentTool		
	GrObjHeadSetCurrentBody		
	GrObjHeadFloaterFinishedCreate	
	GrObjHeadClassedEventToFloater
	GrObjHeadClassedEventToFloaterIfCurrentBody
					


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	06/19/91	Initial revision


DESCRIPTION:
	$Id: head.asm,v 1.1 97/04/04 18:08:15 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

GrObjHeadClass

GrObjClassStructures	ends

GrObjInitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return desired super class

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjHeadClass

RETURN:		
		cx:dx - fptr to super class
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadBuild	method dynamic GrObjHeadClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	.enter

	mov	cx,segment VisEmptyClass
	mov	dx,offset VisEmptyClass

	.leave
	ret
GrObjHeadBuild		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjHeadSendNotifyCurrentTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sends UI notification to update anyone who cares about the
		current grobj tool.

Pass:		*ds:si = GrObjHead

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr  2, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadSendNotifyCurrentTool	method	GrObjHeadClass,
				MSG_GH_SEND_NOTIFY_CURRENT_TOOL
	uses	bx, cx, dx, bp
	.enter

	movdw	cxdx, ds:[di].GH_currentTool
	mov	bp, ds:[di].GH_initializeFloaterData

	mov	bx, size GrObjNotifyCurrentTool
	call	GrObjGlobalAllocNotifyBlock

	push	ds
	call	MemLock
	mov	ds, ax
	mov	ds:[GONCT_toolClass].segment, cx
	mov	ds:[GONCT_toolClass].offset, dx
	mov	ds:[GONCT_specInitData], bp
	call	MemUnlock
	pop	ds

	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_CURRENT_TOOL_CHANGE
	mov	dx, GWNT_GROBJ_CURRENT_TOOL_CHANGE
	call	GrObjGlobalUpdateControllerLow

	.leave
	ret
GrObjHeadSendNotifyCurrentTool	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadGetCurrentTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Gets the current tool class.
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjHeadClass

RETURN:		
		cx:dx - fptr to object class
		bp - MSG_GO_GROBJ_SPECIFIC_INITIALIZE data
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadGetCurrentTool	method dynamic GrObjHeadClass,
						MSG_GH_GET_CURRENT_TOOL
	.enter

	movdw	cxdx, ds:[di].GH_currentTool
	mov	bp, ds:[di].GH_initializeFloaterData

	.leave
	ret

GrObjHeadGetCurrentTool		endm

GrObjInitCode	ends

GrObjRequiredInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadCreateBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Allocate an object block 

CALLED BY:	INTERNAL
		GrObjHeadCreateFloater

PASS:		
		nothing

RETURN:		
		bx - handle of block

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadCreateBlock		proc	near

	.enter

	call	GeodeGetProcessHandle
	call	ProcInfo
	call	UserAllocObjBlock

	.leave
	ret
GrObjHeadCreateBlock		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadCallFloater
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send encapsulated message to floater and return params

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjHeadClass

		cx - message handle
RETURN:		
		ax,cx,dx,bp - from floater
	
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
	srs	10/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadCallFloater	method dynamic GrObjHeadClass, 
						MSG_GH_CALL_FLOATER
	.enter

	call	GrObjHeadGuaranteeFloater

	mov	bx,cx				;event handle
	movdw	cxsi,ds:[di].GH_floater
	call	MessageSetDestination

	mov	di,mask MF_CALL or mask MF_FIXUP_DS 
	call	MessageDispatch

	.leave
	ret
GrObjHeadCallFloater		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadMessageToFloater
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the floater

CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - graphic head
		ax - message
		cx,dx,bp - other message data
		di - MessageFlags

RETURN:		
		if no floater return
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
	srs	7/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadMessageToFloater		proc	far
	class	GrObjHeadClass
	uses	bx,si,di
	.enter

EC <	call	ECGrObjHeadCheckLMemObject			>

	call	GrObjHeadGuaranteeFloater

	mov	si,ds:[si]
	mov	bx,ds:[si].GH_floater.handle
	tst	bx
	jz	done

	mov	si,ds:[si].GH_floater.chunk
	ornf	di, mask MF_FIXUP_DS
	call	ObjMessage

	;    Clear zero flag to signify message being sent
	;

	ClearZeroFlagPreserveCarry	si

done:
	.leave
	ret

GrObjHeadMessageToFloater		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadClassedEventToFloater
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the encapuslated method to the floater object
		with a MSG_META_SEND_CLASSED_EVENT

PASS:		
		*(ds:si) - instance data of object

		cx - recorded message handle

RETURN:		
		nothing
	
DESTROYED:	
		nothing

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
	srs	7/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadClassedEventToFloater	method GrObjHeadClass, \
					MSG_GH_CLASSED_EVENT_TO_FLOATER
	uses	ax,bx,dx,di
	.enter

	mov	di,ds:[si]
	mov	bx,ds:[di].GH_floater.handle
	tst	bx
	jz	done
	mov	si,ds:[di].GH_floater.chunk
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_META_SEND_CLASSED_EVENT
	mov	dx, TO_SELF
	call	ObjMessage

done:
	.leave
	ret

GrObjHeadClassedEventToFloater		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadClassedEventToFloaterIfCurrentBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Send the encapuslated method to the floater object if the
	passed body od is the current body

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjHeadClass

		cx - recorded message handle
		dx:bp - od of body

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
	srs	7/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadClassedEventToFloaterIfCurrentBody \
			method dynamic GrObjHeadClass, \
			MSG_GH_CLASSED_EVENT_TO_FLOATER_IF_CURRENT_BODY
	uses	ax,cx
	.enter

	;    Get current body od and compare to passed one
	;

	call	GrObjHeadGetCurrentBody
	cmp	dx,ax				;body handles
	jne	done
	cmp	bp,bx				;body chunks
	jne	done

	call	GrObjHeadClassedEventToFloater

done:
	.leave
	ret

GrObjHeadClassedEventToFloaterIfCurrentBody		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadFloaterFinishedCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Notify head that the current floater has just
		completed creation of a new object. Reset the
		instance data of the current floater and
		notify the application that a tool has completed
		its job

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjHeadClass

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
	srs	7/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadFloaterFinishedCreate	method dynamic GrObjHeadClass, 
					MSG_GH_FLOATER_FINISHED_CREATE
	.enter

	mov	ax,MSG_GO_REACTIVATE_CREATE
	clr	di					;MessageFlags
	call	GrObjHeadMessageToFloater

	.leave
	ret
GrObjHeadFloaterFinishedCreate		endm







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadGetCurrentBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Return current body od

PASS:		
		*(ds:si) - instance data of head

RETURN:		
		ax:bx - OD of current body ( 0 if no current body )
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadGetCurrentBody	proc 	near
	class	GrObjHeadClass
	uses	di,si
	.enter

EC <	call	ECGrObjHeadCheckLMemObject		>

	mov	di,ds:[si]
	mov	ax,ds:[di].GH_currentBody.handle
	mov	bx,ds:[di].GH_currentBody.chunk

	.leave
	ret

GrObjHeadGetCurrentBody		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadSetCurrentTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Sets the current tool class and instantiates a tool of this
		class for the floater object and sends the new object
		MSG_GO_OBJECT_SPECIFIC_INIITIALIZE with the data passed in bp
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjHeadClass

		cx:dx - fptr to object class
		bp - MSG_GO_GROBJ_SPECIFIC_INITIALIZE data

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
	srs	6/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadSetCurrentTool	method dynamic GrObjHeadClass, 
						MSG_GH_SET_CURRENT_TOOL
	.enter

EC <	jcxz	noClass			>
EC <	push	es,di			>
EC <	mov	es,cx			>
EC <	mov	di,dx			>
EC <	call	ECCheckClass		>
EC <	pop	es,di			>
EC <noClass:				>

	cmp	ds:[di].GH_currentTool.offset,dx
	jne	newClass
	cmp	ds:[di].GH_currentTool.segment,cx
	jne	newClass
	cmp	ds:[di].GH_initializeFloaterData,bp
	jne	newClass

done:
	.leave
	ret

newClass:
	;    Store new class in instance data
	;

	movdw	ds:[di].GH_currentTool,cxdx
	mov	ds:[di].GH_initializeFloaterData,bp

	;    Create new floater of passed class
	;

	call	GrObjHeadCreateFloater

	mov	ax, MSG_GH_SEND_NOTIFY_CURRENT_TOOL
	call	ObjCallInstanceNoLock
	jmp	done

GrObjHeadSetCurrentTool		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadSetCurrentToolWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Sets the current tool class and instantiates a tool of this
		class for the floater object and sends the new object
		MSG_GO_OBJECT_SPECIFIC_INIITIALIZE_WITH_DATA_BLOCK with the
		data block passed in bp
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjHeadClass

		cx:dx - fptr to object class
		bp - data block

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
	srs	6/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadSetCurrentToolWithDataBlock	method dynamic GrObjHeadClass,
					MSG_GH_SET_CURRENT_TOOL_WITH_DATA_BLOCK
	.enter

EC <	push	es,di			>
EC <	mov	es,cx			>
EC <	mov	di,dx			>
EC <	call	ECCheckClass		>
EC <	pop	es,di			>


	;    Store new class in instance data
	;

	movdw	ds:[di].GH_currentTool,cxdx

	;    Create new floater of passed class
	;

	call	GrObjHeadCreateFloaterWithDataBlock

	.leave
	ret

GrObjHeadSetCurrentToolWithDataBlock	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadSetCurrentBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the passed body the current one. 

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjHeadClass

		cx:dx - body to be made the current one
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
	srs	6/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadSetCurrentBody	method dynamic GrObjHeadClass, 
						MSG_GH_SET_CURRENT_BODY
	uses	ax,cx,dx,bp
	.enter

	;   Don't do anything if this body is already the current one
	;

	cmp	ds:[di].GH_currentBody.handle,cx
	jne	setNew
	cmp	ds:[di].GH_currentBody.chunk,dx
	je	done

	;    Store the new body od
	;

setNew:
	mov	ds:[di].GH_currentBody.handle,cx
	mov	ds:[di].GH_currentBody.chunk,dx

	tst	ds:[di].GH_floater.handle
	jz	newFloater

	;
	;	Store the body in the floater's obj block output
	;
	call	GrObjHeadSetBodyInFloaterBlock

	;    Activate the new floater. This will cause it to notify
	;    any selected or edited objects in the new body.
	;

	call	GrObjHeadActivateCreateFloater

	mov	di, ds:[si]
	mov	cx,ds:[di].GH_currentTool.segment
	mov	dx,ds:[di].GH_currentTool.offset
	mov	bp,ds:[di].GH_initializeFloaterData

updateController:

	mov	ax, MSG_GH_SEND_NOTIFY_CURRENT_TOOL
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

newFloater:
	;    Create floater of current tool class, if
	;    class has been set
	;

	movdw	cxdx,ds:[di].GH_currentTool
	mov	bp,ds:[di].GH_initializeFloaterData
	jcxz	updateController
	call	GrObjHeadCreateFloater
	jmp	updateController
GrObjHeadSetCurrentBody		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjHeadSetBodyInFloaterBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sets the OLMBH_output field of the floater's block
		to the passed body

Pass:		*ds:si - GrObjHead
		^lcx:dx - GrObjBody

Return:		nothing

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 16, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadSetBodyInFloaterBlock	proc	near
	class	GrObjHeadClass
	uses	ax, bx, es
	.enter

	mov	bx, ds:[si]
	mov	bx, ds:[bx].GH_floater.handle
	tst	bx
	jz	done
	call	ObjLockObjBlock
	mov	es, ax
	movdw	es:[OLMBH_output], cxdx
	call	MemUnlock
done:
	.leave
	ret
GrObjHeadSetBodyInFloaterBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadClearCurrentBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the current body if it is the passed body.
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjHeadClass

		cx:dx - body to clear
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
	srs	6/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadClearCurrentBody	method dynamic GrObjHeadClass, 
						MSG_GH_CLEAR_CURRENT_BODY
	uses	cx, dx
	.enter

	;    Get current body and compare to passed body, if
	;    different then just exit, otherwise clear current body
	;

	call	GrObjHeadGetCurrentBody
	sub	cx,ax				;compare handles
	jnz	done
	sub	dx,bx				;compare chunks
	jnz	done

	call	GrObjHeadSetBodyInFloaterBlock

	mov	di,ds:[si]
	mov	ds:[di].GH_currentBody.handle,cx	;ax=0 from sub
	mov	ds:[di].GH_currentBody.chunk,cx

done:
	.leave
	ret

GrObjHeadClearCurrentBody		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadGuaranteeFloater
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we don't have a floater then create one. Unless
		we have no tool class. Then do nothing

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - GrObjHead

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			Floater exists

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadGuaranteeFloater		proc	near
	class	GrObjHeadClass
	uses	cx,dx,bp,di
	.enter

EC <	call	ECGrObjHeadCheckLMemObject			>

	mov	di,ds:[si]
	tst	ds:[di].GH_floater.handle
	jz	create

done:
	.leave
	ret

create:
	movdw	cxdx,ds:[di].GH_currentTool
	mov	bp,ds:[di].GH_initializeFloaterData
	jcxz	done
	call	GrObjHeadCreateFloater
	jmp	done

GrObjHeadGuaranteeFloater		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadCreateFloater
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new floater and destroy any existing floater 
		in the process. Stores od of new floater in graphicHead
		instance data.

CALLED BY:	INTERNAL
		GrObjHeadSetCurrentTool

PASS:		
		*ds:si - GrObjHead object
		cx:dx - fptr to class of floater
		bp - Word of data to be sent with
			MSG_GO_OBJECT_SPECIFIC_INIITIALIZE to
			the floater when it is instantiated
		
RETURN:		
		floater od in GH_floater

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadCreateFloater		proc	near
	class	GrObjHeadClass
	uses	ax,bx,cx,dx,di,es
	.enter

EC <	jcxz	noClass			>
EC <	call	ECGrObjHeadCheckLMemObject >
EC <	push	es,di			>
EC <	mov	es,cx			>
EC <	mov	di,dx			>
EC <	call	ECCheckClass		>
EC <	pop	es,di			>
EC <noClass:				>

	call	GrObjHeadDestroyFloater
	;
	; If we're passed a null class ptr, don't create a floater...
	;
	jcxz	done

	;    Create new floater

	push	si					;head lmem
	mov	es,cx					;floater class segment
	mov	di,dx					;floater class offset
	call	GrObjHeadCreateBlock
	call	ObjInstantiate

	;    Store od of new floater in instance data
	;

	mov_tr	ax,si				;floater lmem
	pop	si				;head lmem
	mov	di,ds:[si]
	mov	ds:[di].GH_floater.handle,bx
	mov	ds:[di].GH_floater.chunk,ax

	call	GrObjHeadGetCurrentBody
	mov	cx,ax					;body handle
	mov	dx,bx					;body chunk
	call	GrObjHeadSetBodyInFloaterBlock

	;    Do object specific initialization
	;

	mov	ax,MSG_GO_GROBJ_SPECIFIC_INITIALIZE
	mov	di,mask MF_FIXUP_DS
	call	GrObjHeadMessageToFloater
	
	;    Activate the new floater
	;

	call	GrObjHeadActivateCreateFloater
done:
	.leave
	ret
GrObjHeadCreateFloater		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadCreateFloaterWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new floater and destroy any existing floater 
		in the process. Stores od of new floater in graphicHead
		instance data.

CALLED BY:	INTERNAL
		GrObjHeadSetCurrentTool

PASS:		
		*ds:si - GrObjHead object
		cx:dx - fptr to class of floater
		bp - Data block
		
RETURN:		
		floater od in GH_floater

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadCreateFloaterWithDataBlock		proc	near
	class	GrObjHeadClass
	uses	ax,bx,cx,dx,di,es
	.enter

EC <	call	ECGrObjHeadCheckLMemObject >
EC <	push	es,di			>
EC <	mov	es,cx			>
EC <	mov	di,dx			>
EC <	call	ECCheckClass		>
EC <	pop	es,di			>

	call	GrObjHeadDestroyFloater
	;
	; If we're passed a null class ptr, don't create a floater...
	;
	jcxz	done

	;    Create new floater

	push	si					;head lmem
	mov	es,cx					;floater class segment
	mov	di,dx					;floater class offset
	call	GrObjHeadCreateBlock
	call	ObjInstantiate

	;    Store od of new floater in instance data
	;

	mov	ax,si				;floater lmem
	pop	si				;head lmem
	mov	di,ds:[si]
	mov	ds:[di].GH_floater.handle,bx
	mov	ds:[di].GH_floater.chunk,ax

	call	GrObjHeadGetCurrentBody
	mov	cx,ax					;body handle
	mov	dx,bx					;body chunk
	call	GrObjHeadSetBodyInFloaterBlock

	;    Do object specific initialization
	;

	mov	ax,MSG_GO_GROBJ_SPECIFIC_INITIALIZE_WITH_DATA_BLOCK
	mov	di,mask MF_FIXUP_DS
	call	GrObjHeadMessageToFloater
	
	;    Activate the new floater
	;

	call	GrObjHeadActivateCreateFloater
done:
	.leave
	ret
GrObjHeadCreateFloaterWithDataBlock		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadActivateCreateFloater
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_GO_ACTIVATE_CREATE to the floater

CALLED BY:	INTERNAL
		GrObjHeadCreateFloater
		GrObjHeadSetCurrentBody
		GrObjSetCurrentTool

PASS:		
		*ds:si - GrObjHead

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
	srs	2/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadActivateCreateFloater		proc	near
	uses	ax,cx,di
	.enter

EC <	call	ECGrObjHeadCheckLMemObject			>

	mov	cl,mask ACF_NOTIFY
	mov	ax,MSG_GO_ACTIVATE_CREATE
	mov	di,mask MF_FIXUP_DS
	call	GrObjHeadMessageToFloater

	.leave
	ret
GrObjHeadActivateCreateFloater		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadDestroyFloater
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the current floater

CALLED BY:	INTERNAL
		GrObjHeadCreateFloater

PASS:		
		*ds:si - graphicHead
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
	srs	6/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadDestroyFloater		proc	near
	class	GrObjHeadClass
	uses	ax,bx,cx,dx,di,si
	.enter

EC <	call	ECGrObjHeadCheckLMemObject	>

	;    Get OD of floater in bx:si and clear od in instance data
	;

	mov	di,ds:[si]
	clr	bx
	xchg	bx,ds:[di].GH_floater.handle
	clr	si
	xchg	si,ds:[di].GH_floater.chunk

	;    Exit if current od handle is zero
	;

	tst	bx				;floater handle
	jz	done

	;    Vaporize floater
	;
	
	mov	ax,MSG_GO_CLEAR_SANS_UNDO
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
GrObjHeadDestroyFloater		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadAllLargePTRs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass ptr events onto the floater so we can
		get the pointer image set correctly. A ptr event
		should only arrive here from a body with no
		mouse grab. It is probably a body that is
		not the current target

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjHeadClass

		ss:bp - LargeMouseData

RETURN:		
		ax - MouseReturnFlags
		if MRF_SET_POINTER_IMAGE then
			cx:dx: - optr of image
		else
			cx,dx - destroyed
	
DESTROYED:	
		bp, see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadAllLargePTRs	method dynamic GrObjHeadClass, MSG_META_LARGE_PTR
	.enter


	mov	di,mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	mov	dx,size LargeMouseData
	call	GrObjHeadMessageToFloater
	jz	noFloater

done:
	.leave
	ret

noFloater:
	;    Yow, there is no floater.
	;

	clr	ax
	jmp	done

GrObjHeadAllLargePTRs		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHeadSetTextToolForSearchSpell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current tool to the MultTextGuardianClass

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjHeadClass

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
	srs	12/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHeadSetTextToolForSearchSpell	method dynamic GrObjHeadClass, 
					MSG_GH_SET_TEXT_TOOL_FOR_SEARCH_SPELL
	uses	cx,dx,bp
	.enter

	mov	cx, segment MultTextGuardianClass
	mov	dx, offset MultTextGuardianClass
	clr	bp
	mov	ax,MSG_GH_SET_CURRENT_TOOL
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjHeadSetTextToolForSearchSpell		endm




GrObjRequiredInteractiveCode	ends




if	ERROR_CHECK
GrObjErrorCode	segment  resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECGrObjHeadCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is an GrObjHeadClass or one
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
ECGrObjHeadCheckLMemObject		proc	far
	uses	es,di
	.enter
	pushf	
	call	ECCheckLMemObject
	mov	di,segment GrObjHeadClass
	mov	es,di
	mov	di,offset GrObjHeadClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_OF_CORRECT_CLASS
	popf
	.leave
	ret
ECGrObjHeadCheckLMemObject		endp

GrObjErrorCode	ends
endif

