COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	socket
MODULE:		network utilities library
FILE:		address.asm

AUTHOR:		Eric Weber, Oct 31, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/31/94   	Initial revision


DESCRIPTION:
	Code for SocketAddressControlClass
		

	$Id: address.asm,v 1.1 97/04/05 01:25:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CANNOT_CHANGE_TO_NON_ANCESTOR_CLASS			enum FatalErrors
; UtilChangeClass was called asking to change an object to some class that
; is not a superclass of the base class of the object.

CANNOT_REMOVE_MASTER_LEVELS_WHEN_CHANGING_CLASS		enum FatalErrors
; You are attempting to change the class of an object using UtilChangeClass
; and the class to which you wish to change it is in a different master group
; than the class to which the object currently belongs. UtilChangeClass doesn't
; have code in it to support this.

UtilClasses	segment resource

SocketAddressControlClass

UtilClasses	ends

AddressCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAddressControlSetAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the destination and message to be outputted when
		address becomes valid or invalid

CALLED BY:	MSG_SOCKET_ADDRESS_CONTROL_SET_ACTION
PASS:		ds:di	= SocketAddressControlClass instance data
		^lcx:dx	= destination
			(or cx=0, dx=travel option)
		bp	= message id
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/31/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAddressControlSetAction	method dynamic SocketAddressControlClass, 
					MSG_SOCKET_ADDRESS_CONTROL_SET_ACTION
		mov	ds:[di].SACI_actionMsg, bp
		CheckHack <GenControl_offset eq SocketAddressControl_offset>
		movdw	ds:[di].GCI_output, cxdx
		ret
SocketAddressControlSetAction	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAddressControlSetValidState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a valid notification

CALLED BY:	MSG_SOCKET_ADDRESS_CONTROL_SET_VALID_STATE
PASS:		*ds:si	= SocketAddressControlClass object
		ds:di	= SocketAddressControlClass instance data
		cx	= FALSE if address not valid
			= TRUE if address is valid
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	10/31/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAddressControlSetValidState	method dynamic SocketAddressControlClass, 
					MSG_SOCKET_ADDRESS_CONTROL_SET_VALID_STATE
	;
	; record an event
	;
		mov	dx, ds:[LMBH_handle]		
		mov	bp, si				; ^ldx:bp= this object
		mov	ax, ds:[di].SACI_actionMsg
		clrdw	bxsi				; no class
		mov	di, mask MF_RECORD
		call	ObjMessage			; di = classed event
	;
	; dispatch it
	;
		mov	si, bp
		mov	bp, di				; bp = event
		mov	di, ds:[si]
		add	di, ds:[di].GenControl_offset
		mov	ax, MSG_GEN_OUTPUT_ACTION
		movdw	cxdx, ds:[di].GCI_output
		call	ObjCallInstanceNoLock
		
		ret
SocketAddressControlSetValidState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SocketAddressControlFinalObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the geode reference

CALLED BY:	MSG_META_FINAL_OBJ_FREE
PASS:		*ds:si	= SocketAddressControlClass object
		ds:di	= SocketAddressControlClass instance data
		es 	= segment of SocketAddressControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	changes the class of this object to SocketAddressControlClass

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	1/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SocketAddressControlFinalObjFree	method dynamic SocketAddressControlClass, 
					MSG_META_FINAL_OBJ_FREE
		push	ax
	;
	; get the address of GeodeRemoveReference
	;
		mov	ax, enum GeodeRemoveReference
		mov	bx, handle geos
		call	ProcGetLibraryEntry	; bx:ax = vfptr to routine
	;
	; set up parameters for GeodeRemoveReference
	;
		sub	sp, size ProcessCallRoutineParams
		mov	bp,sp
		movdw	ss:[bp].PCRP_address, bxax
		segmov	ss:[bp].PCRP_dataBX, ds:[di].SACI_geode, ax
	;
	; get our thread
	;
		mov	bx, ds:[LMBH_handle]
		mov	ax, MGIT_EXEC_THREAD
		call	MemGetInfo
	;
	; Ask our own thread's process to call GeodeRemoveReference
	; on the driver.  It can't do this until this message completes,
	; so it is safe even if this library exits as a result.
	;
		mov	bx,ax
		mov	ax, MSG_PROCESS_CALL_ROUTINE
		mov	dx, size ProcessCallRoutineParams
		mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
		call	ObjMessage
		add	sp, size ProcessCallRoutineParams
	;
	; call the superclass
	;
		pop	ax
		mov	di, offset SocketAddressControlClass
		GOTO 	ObjCallSuperNoLock
SocketAddressControlFinalObjFree	endm

AddressCode	ends


