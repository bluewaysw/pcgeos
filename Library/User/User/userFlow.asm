COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/User
FILE:		userFlow.asm

ROUTINES:
	Name			Description
	----			-----------
	FlowInitialize		Initialize the flow object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

DESCRIPTION:
	This set of files (userFlow*.asm) contains routines to handle input
	processing for the User Interface.
	
	$Id: userFlow.asm,v 1.1 97/04/07 11:46:12 newdeal Exp $

------------------------------------------------------------------------------@

UserClassStructures	segment resource

	FlowClass	mask CLASSF_NEVER_SAVED

UserClassStructures	ends

;---------------------------------------------------

Init segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		FlowInitialize -- MSG_META_INITIALIZE for FlowClass

DESCRIPTION:	Handles init of a flow object

PASS:
	*ds:si - instance data
	es - segment of FlowClass

	ax - MSG_PROCESS_INSTANTIATE

	cx, dx, bp - Nothing

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@

FlowInitialize	method	FlowClass, MSG_META_INITIALIZE

	; Do NOT bother sending to parent - we're the end of the master class.

	; Init Button variables

    	mov	ds:[di].FI_activeMouseButton, -1	; set to NONE

	; Init flow object stuff

	mov	di, ds:[si]	; get ptr to object

	;
	; Zero out the strategy routine. It will be set up by a 
	; MSG_FLOW_SET_SCREEN dispatched from UserSetCurScreen once the
	; screen layout has been determined.
	; 
	clr	ax
	mov	ds:[di].FI_curVideoStrategy.segment, ax
	mov	ds:[di].FI_curVideoStrategy.offset, ax


        ; Allocate queues used to control input flow
	;
        call    GeodeAllocQueue
        mov     ds:[di].FI_holdUpInputQueue, bx

	ret
FlowInitialize	endp

Init ends
