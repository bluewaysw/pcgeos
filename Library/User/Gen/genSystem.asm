COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genSystemClass.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenSystemClass		Class that implements the system object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

DESCRIPTION:
	This file contains routines to implement the GenSystem class.

	$Id: genSystem.asm,v 1.1 97/04/07 11:44:56 newdeal Exp $

------------------------------------------------------------------------------@

UserClassStructures	segment resource

	GenSystemClass

UserClassStructures	ends

Init segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenSystemInitialize

DESCRIPTION:	Initialize object

PASS:
	*ds:si - instance data
	es - segment of GenSystemClass
	ax - MSG_META_INITIALIZE

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	NOTE:  THIS ROUTINE ASSUME THAT THE OBJECT HAS JUST BEEN CREATED
	AND HAS INSTANCE DATA OF ALL 0'S FOR THE VIS PORTION

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/91		Initial version

------------------------------------------------------------------------------@

GenSystemInitialize	method static	GenSystemClass, MSG_META_INITIALIZE

	or	ds:[di].GI_attrs, mask GA_TARGETABLE

	mov	di, offset GenSystemClass
	GOTO	ObjCallSuperNoLock

GenSystemInitialize	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenSystemSetSpecificUI -- MSG_GEN_SYSTEM_SET_SPECIFIC_UI
						for GenSystemClass

DESCRIPTION:	Setup the UI system object

PASS:
	*ds:si - instance data (for object in GenSystem class)
	es - segment of GenSystemClass

	ax - MSG_GEN_SYSTEM_SET_SPECIFIC_UI

	cx - ?
	dx - handle of specific UI to use for system object
	     (Becomes initial default UI as well)
	bp - ?

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@

GenSystemSetSpecificUI	method	dynamic GenSystemClass,
				MSG_GEN_SYSTEM_SET_SPECIFIC_UI

	mov	ds:[di].GSYI_specificUI, dx	; store UI to use
	mov	ds:[di].GSYI_defaultUI, dx	; store as default, too

						; MARK AS USABLE.  This is
						; the only object which is
						; usable w/o upward linkage
						; Also mark as enabled. -cbh
	or	ds:[di].GI_states, mask GS_USABLE or \
				   mask GS_ENABLED
	ret

GenSystemSetSpecificUI	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenSystemBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenSystemClass

DESCRIPTION:	Build an object

PASS:
	*ds:si - instance data (for object in GenSystem class)
	es - segment of GenSystemClass

	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx - master offset of variant class to build

RETURN: cx:dx - class for specific UI part of object (cx = 0 for no build)

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

GenSystemBuild	method	GenSystemClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	mov	di, ds:[si]		; ds:di = instance data
	add	di, ds:[di].Gen_offset	;ds:di = GenInstance
					; get UI to use
					; (MUST be stored here!)
	mov	bx, ds:[di].GSYI_specificUI ; bx = handle of specific UI to use
	mov	ax, SPIR_BUILD_SYSTEM
	mov	di,MSG_META_RESOLVE_VARIANT_SUPERCLASS
	call	ProcGetLibraryEntry
	GOTO	ProcCallFixedOrMovable

GenSystemBuild	endm

Init ends

;----------

BuildUncommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenSystemSetDefaultScreen

DESCRIPTION:	Set the default screen to be used when new fields are
		created.

PASS:
	*ds:si - instance data
	es - segment of GenSystemClass

	ax - MSG_GEN_SYSTEM_SET_DEFAULT_SCREEN

	cx:dx - default object to be used for an field's vis parent

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


GenSystemSetDefaultScreen	method	GenSystemClass, \
					MSG_GEN_SYSTEM_SET_DEFAULT_SCREEN
EC<	call	ECCheckLMemODCXDX					>
				; store new default
	mov	ds:[di].GSYI_defaultScreen.handle, cx
	mov	ds:[di].GSYI_defaultScreen.chunk, dx
	ret
GenSystemSetDefaultScreen	endm

BuildUncommon	ends

;
;---------------
;
		
GetUncommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenSystemGetDefaultScreen

DESCRIPTION:	Get the default screen to be used when new fields are
		created.

PASS:
	*ds:si - instance data
	es - segment of GenSystemClass

	ax - MSG_GEN_SYSTEM_GET_DEFAULT_SCREEN


RETURN:	cx:dx - default object to be used for an field's vis parent

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


GenSystemGetDefaultScreen	method	GenSystemClass, \
					MSG_GEN_SYSTEM_GET_DEFAULT_SCREEN
	mov	cx, ds:[di].GSYI_defaultScreen.handle
	mov	dx, ds:[di].GSYI_defaultScreen.chunk
	ret
GenSystemGetDefaultScreen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenSystemForeachField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a callback function for each attached field

CALLED BY:	MSG_GEN_SYSTEM_FOREACH_FIELD
PASS:		*ds:si	= GenSystem object
		cx:dx	= callback function to call:
		(For XIP, cx:dx is vfptr callback.)
			Pass:	^lbx:si	= optr of field
				ax	= bp passed to method
			Return:	carry set to stop enumerating
		bp	= data to pass to callback in ax
RETURN:		carry set if callback returned carry set:
			^lcx:dx	= last field it received.
		carry clear if callback never returned carry set:
			cx:dx	= 0:0
DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenSystemForeachField method dynamic GenSystemClass, 
					MSG_GEN_SYSTEM_FOREACH_FIELD
		.enter
if 	ERROR_CHECK and FULL_EXECUTE_IN_PLACE
		cmp	cx, MAX_SEGMENT
		jae	10$
		xchgdw	cxdx, bxsi
		call	ECAssertValidFarPointerXIP
		xchgdw	cxdx, bxsi
10$:
endif
		clr	ax
		push	ax, ax		; start with first child
		mov	ax, offset GI_link
		push	ax
NOFXIP <	push	cs			>	;push call-back routine
FXIP <		mov	ax, SEGMENT_CS					>
FXIP <		push	ax						>
		mov	ax, offset GSFF_callback
		push	ax
		mov	bx, offset Gen_offset
		mov	di, offset GI_comp
		call	ObjCompProcessChildren
		jc	done
		clr	cx, dx
done:
		.leave
		ret
GenSystemForeachField endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSFF_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for MSG_GEN_SYSTEM_FOREACH_FIELD to call
		the caller's callback function with the current child, if
		the child is a field.

CALLED BY:	GenSystemForeachField via ObjCompProcessChildren
PASS:		*ds:si	= child
		*es:di	= composite
		cx:dx	= callback routine
		(For XIP, cx:dx is the vfptr callback)
RETURN:		carry set to end processing:
			^lcx:dx	= current child
		carry clear to continue processing:
			cx:dx	= preserved
DESTROYED:	ax, bp, bx, si, di, ds, es all allowed

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GSFF_callback	proc	far
dataAX		local	word		push bp
NOFXIP <callback	local	fptr.far	push cx, dx		>
		.enter
	;
	; First see if this child is a field.
	; 
		segmov	es, <segment GenFieldClass>, di
		mov	di, offset GenFieldClass
		call	ObjIsObjectInClass
		jnc	done		; => not field, so don't call
	;
	; It is a field, so pass its optr in ^lbx:si to the callback routine.
	;
		mov	bx, ds:[LMBH_handle]
		mov	ax, ss:[dataAX]
NOFXIP	<	call	ss:[callback] >
FXIP	<	mov	ss:[TPD_dataBX], bx 	>
FXIP	<	mov	ss:[TPD_dataAX], ax	>
FXIP	<	movdw	bxax, cxdx					>
FXIP	<	call	ProcCallFixedOrMovable				   >
		jnc	done		; => continue processing.
	;
	; Callback returned carry set, so return the field in ^lcx:dx and leave
	; the carry set.
	; 
		mov	dx, si
		mov	cx, bx
done:
		.leave
		ret
GSFF_callback	endp


GetUncommon	ends

;
;---------------
;
		
BuildUncommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenSystemSetDefaultField

DESCRIPTION:	Set the default field to be used when new applications are
		created.

PASS:
	*ds:si - instance data
	es - segment of GenSystemClass

	ax - MSG_GEN_SYSTEM_SET_DEFAULT_FIELD

	cx:dx - default object to be used for an application's vis parent

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


GenSystemSetDefaultField	method	GenSystemClass, \
					MSG_GEN_SYSTEM_SET_DEFAULT_FIELD
EC<	call	ECCheckLMemODCXDX					>
				; store new default
	mov	ds:[di].GSYI_defaultField.handle, cx
	mov	ds:[di].GSYI_defaultField.chunk, dx
	ret
GenSystemSetDefaultField	endm


BuildUncommon	ends

;
;---------------
;
		
GetUncommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenSystemGetDefaultField

DESCRIPTION:	Get the default field to be used when new applications are
		created.

PASS:
	*ds:si - instance data
	es - segment of GenSystemClass

	ax - MSG_GEN_SYSTEM_GET_DEFAULT_FIELD

RETURN:	cx:dx - default object to be used for an application's vis parent

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


GenSystemGetDefaultField	method	GenSystemClass, \
					MSG_GEN_SYSTEM_GET_DEFAULT_FIELD
	mov	cx, ds:[di].GSYI_defaultField.handle
	mov	dx, ds:[di].GSYI_defaultField.chunk
	ret
GenSystemGetDefaultField	endm

GetUncommon	ends

;
;---------------
;
		
Init	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenSysAddScreenChild -- MSG_GEN_SYSTEM_ADD_SCREEN_CHILD for GenClass

DESCRIPTION:	Add a GenScreen object as a child of the system through
		its screen linkage (CompPart is GSYI_screenComp; linkage
		through child is standard generic linkage).

WHO CAN USE:	Anyone

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_ADD_SCREEN_CHILD

	cx:dx - chunk handle to add
	bp low - CompChildFlags

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@


GenSysAddScreenChild	method	GenSystemClass, MSG_GEN_SYSTEM_ADD_SCREEN_CHILD
EC <	call	CheckForCXDXNotUsable					>

	mov	ax, offset GI_link
	mov	bx, offset Gen_offset
	mov	di, offset GSYI_screenComp
	GOTO	ObjCompAddChild

GenSysAddScreenChild	endm


Init	ends

;
;---------------
;
		
Exit	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenSysRemoveScreenChild
			-- MSG_GEN_SYSTEM_REMOVE_SCREEN_CHILD for GenClass

DESCRIPTION:	Remove a child object from a composite

WHO CAN USE:	Anyone

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_REMOVE_SCREEN_CHILD

	cx:dx - object to remove

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@


GenSysRemoveScreenChild	method	GenSystemClass, MSG_GEN_SYSTEM_REMOVE_SCREEN_CHILD
EC <	call	CheckForCXDXNotUsable					>

	mov	ax, offset GI_link
	mov	bx, offset Gen_offset
	mov	di, offset GSYI_screenComp
	clr	bp
	GOTO	ObjCompRemoveChild

GenSysRemoveScreenChild	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenSysDetach

DESCRIPTION:	This method may be sent to the system object to cause the
		entire system to be shutdown.  This starts out by sending
		MSG_META_DETACH to all of the field objects under the system
		object, which in turn detach all applications running
		within them.

PASS:
	*ds:si - instance data
	es - segment of GenSystemClass

	ax - MSG_META_DETACH

	cx - caller's ID (value to be returned in MSG_META_DETACH_COMPLETE to
			 this object, & in MSG_META_ACK to caller)
	dx:bp	- OD to send MSG_META_ACK to when all done.

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version
	Doug	12/89		Re-wrote to support ACK notification

------------------------------------------------------------------------------@
GenSysDetach	method	GenSystemClass, MSG_META_DETACH

	call	ObjInitDetach		; Start up chunk to handle detach
					; count

	;
	; Notify all our children, upping the detach count once for each child.
	; 
	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx,offset GI_link	; pass offset to LinkPart
	push	bx

	;push call-back routine
NOFXIP <	push	cs						>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	
	mov	bx,offset GSD_callBack
	push	bx
	mov	di,offset GI_comp
	mov	bx,offset Gen_offset
	call	ObjCompProcessChildren

	call	ObjEnableDetach		; Allow detaching any time...
	ret

GenSysDetach	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenSysDetachComplete

DESCRIPTION:	

PASS:
	*ds:si - instance data
	es - segment of GenSystemClass

	ax - MSG_META_DETACH_COMPLETE

	cx	- ID of object that sent MSG_META_DETACH to us in the first
		  place
	dx:bp	- OD to send MSG_META_ACK back to
	nothing

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	6/8/92		Initial version

------------------------------------------------------------------------------@
GenSysDetachComplete	method	GenSystemClass, MSG_META_DETACH_COMPLETE

	; If flag exists, then the fields were previously detached, & now
	; the UI app is as well.  Just call superclass for default ACK 
	; behavior.
	;
	push	ax
	mov	ax, TEMP_GEN_SYSTEM_FIELDS_DETACHED
	call	ObjVarFindData
	pop	ax
	jnc	fieldsJustFinishedDetaching

	mov	di, offset GenSystemClass
	GOTO	ObjCallSuperNoLock

fieldsJustFinishedDetaching:
	; Otherwise, only the fields have finished detaching.  Set flag,
	; then start DETACH of UI app itself.
	;
	push	cx
	mov	ax, TEMP_GEN_SYSTEM_FIELDS_DETACHED
	clr	cx			; no data
	call	ObjVarAddData		; set flag
	pop	cx

	; Start over w/new DETACH cycle but this time, send MSG_META_DETACH to
	; UI process
	;
	mov	ax, MSG_META_DETACH
	call	ObjInitDetach

	clr	cx			; no particular ID

	; NOTE! We're about to ask the UI process itself to detach. By the
	; time its process thread is being nuked, this object will be dead.
	; Attempting to ACK here would actually cause the system to blow up.
	; Yet, we still pass ourselves as the ACK OD here.  Are we crazy?
	; No.  The UI process needs this information in order to be able to
	; distinguish this case from that of SysShutdown calling it.  The 
	; UI process itself saves the day by clearing out these registers
	; before continuing its own detach, so that no ACK will later die
	; trying to make its way back to this object.
	;
	; 10/19/92: this is not true. The GenSystem object is run by the
	; UI thread, which avoids killing itself (special code in
	; GenProcess::GEN_PROCESS_FINAL_DETACH) until it sends an ACK back
	; to us. We don't go away until we send an ACK back to the ui
	; process, which takes the system the rest of the way down -- ardeb
	;	
	mov	dx, ds:[LMBH_handle]	; Pass ourselves as source of DETACH
	mov	bp, si

	mov	bx, handle 0		; Detach UI process itself
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	call	ObjIncDetach		; inc count once for above DETACH

	call	ObjEnableDetach
	ret

GenSysDetachComplete	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	GSD_callBack

DESCRIPTION:	Call back routine supplied by GenSysDetach when
		calling ObjCompProcessChildren

CALLED BY:	ObjCompProcessChildren (as call-back)

PASS:
	*ds:si - child
	*es:di - composite
	ax - method

RETURN:
	carry clear to continue enumeration

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

GSD_callBack	proc	far
	;
	; Force-queue the MSG_META_DETACH to the child.
	; 
	clr	cx			; no particular ack ID
	mov	dx, es:[LMBH_handle]
	mov	bp, di
	mov	ax, MSG_META_DETACH
	mov	bx, ds:[LMBH_handle]
	push	di
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	;
	; And up our detach count
	; 
	segmov	ds, es			; *ds:si <- system obj
	pop	si
	call	ObjIncDetach		; One more acknowledge that we need to
					; receive.
	clc
	ret
GSD_callBack	endp


Exit ends

;----------------------

UtilityUncommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenSystemSetPtrImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Used to change the mouse ptr image.  The mouse ptr defined
		at the highest PtrImageLevel will actually be used.  This
		function is also accessible via the Input Manager library
		routine ImSetPtrImage, but this method is provided for cases
		where an interrupt routine needs to change the ptr image --
		it may send this method to the IM to effect the change.

	Allows UI components to change the ptr image at a number of
	different priority levels.

	The image that the mouse takes on is governed by several things,
	in the priority of:

	1) System state.  Should the system ever be globally blocked
	   then we would want a mouse image which could represent this
	   state.  One use of this would be the Yin/Yang symbol.

	2) Application state.  If the application owning the current implied
	   window is busy as a whole, or if it is in a modal state such that
	   the current window that the mouse is in is not accessible.
	   Should be set on MSG_META_UNIV_ENTER, removed on MSG_META_UNIV_LEAVE,
	   by any UI windows used by the application which sit on
	   a field window, or on any state change by the application,
	   if it is still the current application.

	3) Gadget.  May be set by the holder of the active or the implied grab
		    at any time.  Must also be cleared.

	4) Window.  The image that the object owning the implied
	window would like to put up.  Should be set on any MSG_META_VIS_ENTER,
	& may be modified by holder of implied grab at any time.  If implied
	grab is null (ptr over null window space during a window grab),
	then anyone may set the ptr, though generally this would
	be done by the last window the ptr was in.   NOTE:   ALL windows must
	set this ptr image to SOMETHING, or the pointer may just end up
	continuing to be the previous value  (Since entire screen is divided
	into visible portion of windows, then if EVERY window sets the ptr
	on VIS_ENTER, all will be happy.)

	5) Default (ptr)


PASS:	*ds:si	- instance data
	es	- segment of GenSystemClass
	ax 	- MSG_GEN_SYSTEM_SET_PTR_IMAGE

	cx:dx	- handle:offset to PointerDef to use
	bp	- PtrImageLevel to change mouse image for.  Currently one of:
		  	PIL_SYSTEM
		  	PIL_FLOW		- only set by flow (UI thread)
		  	PIL_MODAL_WINDOW	- only set if ptr is in UNIV of
		  			  	  a modal window
		  	PIL_APPLICATION	- only set if ptr is in UNIV of
		  			  	  an application
		  	PIL_GADGET		- only set by active/implied
		  			  	  gadget
		  	PIL_WINDOW		- only set if ptr is in UNIV of
		  			  	  the window
		  	PIL_DEFAULT		- the basic ptr image

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	3/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenSystemSetPtrImage	method	GenSystemClass, MSG_GEN_SYSTEM_SET_PTR_IMAGE
	call	ImSetPtrImage
	ret

GenSystemSetPtrImage	endm

UtilityUncommon ends
