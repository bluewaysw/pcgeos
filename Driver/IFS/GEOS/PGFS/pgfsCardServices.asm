COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		pgfsCardServices.asm

AUTHOR:		Adam de Boor, Sep 29, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/29/93		Initial revision


DESCRIPTION:
	Interface to Card Services
		

	$Id: pgfsCardServices.asm,v 1.1 97/04/18 11:46:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSCardServicesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for Card Services events

CALLED BY:	Card Services

PASS:		al	-> function
		cx	-> socket
		dx	-> info
		di	-> 1st word in RegisterClient
		ds	-> dgroup (2nd word in RegisterClient)
		si	-> 3rd word in RegisterClient
		ss:bp	-> MTDRequest
		es:bx	-> buffer
		bx	-> Misc (when no buffer returned)

RETURN:		ax	<- status to return
		carry set on error,
		carry clear on success.

DESTROYED:	nothing

SIDE EFFECTS:
		None

PSEUDO CODE/STRATEGY:
		Notify registered client.

		See if a thread is spawned.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	7/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSCardServicesCallback	proc	far
	uses	cx, dx
	.enter

	cmp	al, CSEC_CARD_INSERTION
	je	doInsertion
	
	cmp	al, CSEC_REGISTRATION_COMPLETE
	jne	handleEvent
	
	mov	ds:[amRegistered], TRUE
	jmp	success

handleEvent:	
	mov	di, ax
	andnf	di, 0xff
	shl	di
	cmp	di, endEventRoutineTable - eventRoutineTable
	ja	unsupported
	jmp	cs:[eventRoutineTable][di-2]

	;--------------------
doExclusiveReq:
	;
	; only allow exclusive if filesystem(s) not in-use
	; 
	push	bx
	call	PGFSUCheckInUse
	pop	bx
	jnc	success
	mov	ax, CSRC_IN_USE
	jmp	done
	;--------------------
doInsertion:
	call	PGFSIHandleInsertion
	jmp	success

	;--------------------
doRemoval:
	call	PGFSRHandleRemoval
	jmp	success
	
	;--------------------
doInfo:
	test	es:[bx].CSGCIA_attributes, mask CSGCIAA_INFO_SUBFUNCTION
	jnz	unsupported	; only handle function 0
	
	mov	cx, cs:[clientInfo].CSGCIA_infoLen
	cmp	cx, es:[bx].CSGCIA_maxLen
	jbe	copyInfo
	mov	cx, es:[bx].CSGCIA_maxLen
copyInfo:
	segmov	ds, cs
	mov	si, offset clientInfo.CSGCIA_infoLen
	lea	di, es:[bx].CSGCIA_infoLen
	sub	cx, offset CSGCIA_infoLen	; not copying stuff up to here
	rep	movsb
	jmp	success

	;--------------------
unsupported:
	mov	ax, CSRC_UNSUPPORTED_FUNCTION
	stc
	jmp	done

	;--------------------
doIgnore:
success:
	mov	ax, CSRC_SUCCESS
	clc
done:
	.leave
	ret

clientInfo	CSGetClientInfoArgs <
	0,			; CSGCIA_maxLen
	size clientInfo,
	mask CSGCIAA_EXCLUSIVE_CARDS or \
		mask CSGCIAA_SHARABLE_CARDS or \
		mask CSGCIAA_MEMORY_CLIENT_DEVICE_DRIVER,
	<			; CSGCIA_clientInfo
		0100h,				; CSCI_revision
		0201h,				; CSCI_csLevel
		<
			29,				; CSDI_YEAR
			9,				; CSDI_MONTH
			22				; CSDI_DAY
		>,				; CSCI_revDate
		clientInfoName - clientInfo,	; CSCI_nameOffset
		length clientInfoName,		; CSCI_nameLength
		vendorString - clientInfo,	; CSCI_vStringOffset
		length vendorString		; CSCI_vStringLength
	>
>
	org	clientInfo.CSGCIA_clientInfo.CSCI_data
clientInfoName	char	"GEOS File System Driver", 0
vendorString	char	"Geoworks", 0

DefCSEvent	macro	event, handler
	.assert ($-eventRoutineTable)/2 eq (event-1)
	nptr.near	handler
		endm
eventRoutineTable	label	nptr
DefCSEvent	CSEC_PM_BATTERY_DEAD,	doIgnore	; Battery Dead
DefCSEvent	CSEC_PM_BATTERY_LOW,	doIgnore	; Battery Low
DefCSEvent	CSEC_CARD_LOCK,		doIgnore	; Card Locked
DefCSEvent	CSEC_CARD_READY,	doIgnore	; Card Ready
DefCSEvent	CSEC_CARD_REMOVAL,	doRemoval	; Card Removal
DefCSEvent	CSEC_CARD_UNLOCK,	doIgnore	; Card Unlocked
DefCSEvent	CSEC_EJECTION_COMPLETE,	doIgnore	; Ejection Complete
DefCSEvent	CSEC_EJECTION_REQUEST,	doIgnore	; Ejection Request
DefCSEvent	CSEC_INSERTION_COMPLETE,doIgnore	; Insertion Complete
DefCSEvent	CSEC_INSERTION_REQUEST,	doIgnore	; Insertion Request
DefCSEvent	CSEC_PM_RESUME,		doIgnore	; Power Manager Resume
DefCSEvent	CSEC_PM_SUSPEND,	doIgnore	; Power Manager Suspend
DefCSEvent	CSEC_EXCLUSIVE_COMPLETE,doIgnore	; Exclusive Complete
DefCSEvent	CSEC_EXCLUSIVE_REQUEST,	doExclusiveReq	; Exclusive Request
DefCSEvent	CSEC_RESET_PHYSICAL,	doIgnore	; Reset Physical
DefCSEvent	CSEC_RESET_REQUEST,	doIgnore	; Reset Request
DefCSEvent	CSEC_CARD_RESET,	doIgnore	; Card Reset
DefCSEvent	CSEC_MTD_REQUEST,	unsupported	; MTD Request
DefCSEvent	CSEC_RESERVED_1,	unsupported	; UNDEFINED
DefCSEvent	CSEC_CLIENT_INFO,	doInfo		; Get Client Info
DefCSEvent	CSEC_TIMER_EXPIRED,	doIgnore	; Timer Expired
DefCSEvent	CSEC_SS_UPDATED,	doIgnore	; SS Updated
endEventRoutineTable	label	nptr

PGFSCardServicesCallback	endp

Resident	ends


