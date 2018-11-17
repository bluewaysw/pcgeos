COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		outboxTransportMenu.asm

AUTHOR:		Adam de Boor, Sep 22, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/22/94		Initial revision


DESCRIPTION:
	Implementation of the OutboxTransportMenu class, an interaction
	that gives itself one GenTrigger for each available transport
		
	Need some way to get updates...and then need OTMDestroyKids routine

	$Id: outboxTransportMenu.asm,v 1.1 97/04/05 01:21:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxClassStructures	segment	resource
	OutboxTransportMenuClass
MailboxClassStructures	ends

OutboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the children necessary to represent ourselves, based
		on the monikers found by the moniker source

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= OutboxTransportMenu object
		ds:di	= OutboxTransportMenuInstance
		bp	= SpecBuildFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	children are created

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMSpecBuild	method dynamic OutboxTransportMenuClass, MSG_SPEC_BUILD
		clr	cx
		mov	ax, MSG_SPEC_GET_ATTRS
		push	bp
		call	ObjCallInstanceNoLock
		pop	bp
		test	cl, mask SA_USES_DUAL_BUILD
		jz	buildKids
		test	bp, mask SBF_WIN_GROUP
		jz	toSuper

buildKids:
		push	bp		; save SpecBuildFlags
		call	OTMDestroyKids
		pop	bp
		call	OTMCreateKids
		mov	ax, MGCNLT_NEW_TRANSPORT
		call	UtilAddToMailboxGCNList

toSuper:
		mov	di, offset OutboxTransportMenuClass
		mov	ax, MSG_SPEC_BUILD
		GOTO	ObjCallSuperNoLock
OTMSpecBuild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMMbNotifyNewTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rebuild our list to take into account a new transport.

CALLED BY:	MSG_MB_NOTIFY_NEW_TRANSPORT
PASS:		*ds:si	= OutboxTransportMenu object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/26/94		Initial version
	AY	10/14/94	Moved most of the code to OTMDestroyKids

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMMbNotifyNewTransport method dynamic OutboxTransportMenuClass, 
			MSG_MB_NOTIFY_NEW_TRANSPORT,
			MSG_OTM_REBUILD_LIST
		.enter
		call	OTMDestroyKids
		call	OTMCreateKids
		.leave
		ret
OTMMbNotifyNewTransport endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMDestroyKids
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys all the GenTrigger children of the passed object

CALLED BY:	(INTERNAL) OTMbNotifyNewTransport, OPMbNotifyNewTransport
PASS:		*ds:si	= GenClass or subclass object
RETURN:		bp	= VUM_DELAYED_VIA_APP_QUEUE
		ds fixed up
DESTROYED:	ax, bx, cx, dl, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMDestroyKids	proc	near

	push	si
	clr	bx, si			; any class
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	clr	bp
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	pop	si
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	call	ObjCallInstanceNoLock

	mov	bp, VUM_DELAYED_VIA_APP_QUEUE

	ret
OTMDestroyKids	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMCreateKids
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create one child for each possible transport, as determined
		by our moniker source partner-object

CALLED BY:	
PASS:		*ds:si	= OutboxTransportMenu object
		bp	= SpecBuildFlags with only SBF_UPDATE_MODE used
RETURN:		nothing
DESTROYED:	ax, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMCreateKids	proc	near
		uses	cx, dx, bp, si
		class	OutboxTransportMenuClass
		.enter
	;
	; Tell the moniker source to rebuild its list. We don't have anything
	; that needs to be mapped through the rebuild...
	; 
		mov	di, ds:[si]
		add	di, ds:[di].OutboxTransportMenu_offset
		push	si, bp
		mov	si, ds:[di].OTMI_monikerSource
		Assert	objectPtr, dssi, OutboxTransportMonikerSourceClass

		mov	cx, -1			; cx <- nothing to track
		mov	ax, MSG_OTMS_REBUILD
		call	ObjCallInstanceNoLock
		mov	bx, si			; *ds:bx <- moniker source
		pop	si, bp			; *ds:si <- menu,
						; bp <- build flags/update mode
		mov_tr	cx, ax			; cx <- # kids to create
		clr	ax			; ax <- start with 1st kid
		jcxz	done
childLoop:
		call	OTMCreateChild
		inc	ax
		loop	childLoop
done:
		.leave
		ret
OTMCreateKids	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMCreateChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a single child trigger and initialize it properly

CALLED BY:	OTMCreateKids
PASS:		*ds:si	= OutboxTransportMenu
		*ds:bx	= OutboxTransportMonikerSource
		ax	= child # to create
		bp	= SpecBuildFlags
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	trigger created, added, initialized, and set usable

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMCreateChild	proc	near
		uses	ax, cx, dx, bp, es, di, si, bx
		class	OutboxTransportMenuClass
		.enter
	;
	; Instantiate a GenTrigger in our block, please.
	; 
		segmov	es, <segment GenTriggerClass>, di
		mov	di, offset GenTriggerClass
		mov	dx, si
		push	bx
		mov	bx, ds:[LMBH_handle]
		call	ObjInstantiate		; *ds:si <- GT
		mov	cx, bx
		pop	bx
		xchg	dx, si			; ^lcx:dx <- trigger
						; *ds:si <- OTM
	;
	; Add the new trigger in its proper position
	; 
		push	bp
		push	ax
		mov	bp, ax			; bp <- CompChildFlags
		mov	ax, MSG_GEN_ADD_CHILD
		call	ObjCallInstanceNoLock
		pop	cx			; cx <- child #
	;
	; Talk to the moniker source to get a moniker for this object.
	; 
		push	dx
		xchg	bx, si			; *ds:bx <- OTM
						; *ds:si <- OTMS
		mov	ax, MSG_OTMS_GET_MONIKER
		call	ObjCallInstanceNoLock
		pop	si			; *ds:si <- GT
		pop	bp			; bp <- SBF
	;
	; Set the moniker for the object. If the moniker we got back is in
	; our block, we have the rights to the object, so we can just use
	; GEN_USE_VIS_MONIKER. If it's someplace else, we have to use the
	; more-involved REPLACE_VIS_MONIKER_OPTR instead.
	; 
		andnf	bp, mask SBF_UPDATE_MODE; bp <- update mode
		push	bp			; save update mode
		push	ax			; remember if should be enabled
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
		cmp	cx, ds:[LMBH_handle]
		jne	setMoniker

		mov	cx, dx			; *ds:cx <- moniker
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		mov	dx, bp			; dx <- update mode
setMoniker:
		call	ObjCallInstanceNoLock
	;
	; Tell the trigger to send us a message when the user hits the trigger
	; 
		mov	cx, ds:[LMBH_handle]
		mov	dx, bx
		mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
		call	ObjCallInstanceNoLock
		
		mov	cx, MSG_OTM_TRANSPORT_SELECTED
		mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
		call	ObjCallInstanceNoLock
	;
	; If we're marked as bringing up a window, mark the trigger likewise.
	; 
		xchg	bx, si
		DerefDI	OutboxTransportMenu
		xchg	bx, si
		test	ds:[di].OTMI_attrs, mask OTMA_BRINGS_UP_WINDOW
		jz	expandWidth
		
		mov	ax, HINT_TRIGGER_BRINGS_UP_WINDOW
		clr	cx
		call	ObjVarAddData

expandWidth:

	;
	; Adjust the thing's enabled status based on what the moniker source
	; said.
	;
		pop	cx
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		jcxz	haveEnabledMsg		; => shouldn't be selectable
		mov	ax, MSG_GEN_SET_ENABLED
haveEnabledMsg:
		pop	dx			; dx <- update mode
		push	dx
		call	ObjCallInstanceNoLock
	;
	; Set the trigger usable (finally!)
	; 
		pop	dx
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjCallInstanceNoLock

		.leave
		ret
OTMCreateChild 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMTransportSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate our action based on the trigger the user clicked

CALLED BY:	MSG_OTM_TRANSPORT_SELECTED
PASS:		*ds:si	= OutboxTransportMenu object
		ds:di	= OutboxTransportMenuInstance
		^lcx:dx	= selected trigger
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMTransportSelected method dynamic OutboxTransportMenuClass, 
				MSG_OTM_TRANSPORT_SELECTED
		.enter
		mov	ax, MSG_GEN_FIND_CHILD
		call	ObjCallInstanceNoLock
EC <		ERROR_C	WHERE_OH_WHERE_COULD_MY_LITTLE_CHILD_BE?	>
	;
	; Now use GenProcessAction to send the action out. We allow the thing
	; to be handled during the call to GenProcessAction if the destination
	; is on the same thread, but we don't insist on it...
	; 
		mov	di, ds:[si]
		add	di, ds:[di].OutboxTransportMenu_offset
		mov	cx, bp			; cx <- transport #
		pushdw	ds:[di].OTMI_destination
		mov	ax, ds:[di].OTMI_actionMsg
		mov	di, mask MF_FIXUP_DS
		call	GenProcessAction
		.leave
		ret
OTMTransportSelected endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMGetTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the actual transport+medium that corresponds to a
		selection in the menu, please

CALLED BY:	MSG_OTM_GET_TRANSPORT
PASS:		*ds:si	= OutboxTransportMenu object
		ds:di	= OutboxTransportMenuInstance
		cx	= list index
		dx:bp	= MailboxMediaTransport buffer to fill in
RETURN:		dx:bp	= filled in (MT_transport is GEOWORKS::GMTID_LOCAL to
			  display all messages => MT_medium is
			  GEOWORKS::GMMID_INVALID)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMGetTransport	method dynamic OutboxTransportMenuClass, MSG_OTM_GET_TRANSPORT
		mov	si, ds:[di].OTMI_monikerSource
		mov	ax, MSG_OTMS_GET_TRANSPORT
		GOTO	ObjCallInstanceNoLock
OTMGetTransport	endm

OutboxUICode	ends
