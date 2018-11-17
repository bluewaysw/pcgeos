COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Terminal
MODULE:		Main
FILE:		mainEci.asm

AUTHOR:		Eric Weber, Aug 24, 1995

ROUTINES:
	Name			Description
	----			-----------
    INT TermRegisterECI		Register for ECI messages

    INT TermUnregisterECI	Unregister ECI messages

    INT TermECICallback		Callback routine by registered ECI messages

    INT TermECIDataCallComing	Handle an incoming data call

    INT TermSerialInitForIncoming
				Initialize variables to prepare for an
				incoming call

    INT TermModemInitForIncoming
				send init strings to modem

    INT TermAnswerModemLow	Send a modem string to answer the modem

    INT TermComeToTop		Bring Terminal app to top, remembering
				previous state

    INT TermInitiateEmulator	Initiate the emulator window

    INT TermCleanupIncoming	Clean up after a failed incoming call

    INT TermECICallCreateStatus	A call has been created

    INT TermECICallReleaseStatus
				Handle data call ended by mobile user

    INT TermECICallTerminateStatus
				Handle data call to connection being
				terminatd from remote side.

    INT TermConnectionLost	Performs approriate cleanup when terminal
				connection lost (because of local or remote
				activity).  If the connection is already
				closed, assume that whatever close the
				connection took care of cleaning up.
				
				This routine is called exactly once for
				each terminal data call termination.

    INT TermEndCallChangeUI	Change UI when data call ends

    INT TermReplaceDisconnectMoniker
				Replace the disconnection moniker

    INT TermClearBlacklist	Send an ECI message to clear the blacklist

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/24/95   	Initial revision


DESCRIPTION:
	This file contains codes specific for responding to ECI messages. 

	$Id: mainEci.asm,v 1.1 97/04/04 16:55:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


if _VSER

EciCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermRegisterECI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register for ECI messages

CALLED BY:	OpenComPort
PASS:		ds	= dgroup
RETURN:		carry set if cannot register
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermRegisterECI	proc	far
		uses	ax, bp, es
		.enter
EC <		Assert_dgroup	ds					>
	;
	; Put the ECI id on the stack. We have three ECI messages to
	; register.
	;
		CheckHack <TERM_NUM_ECI_MSG eq 3>
		mov	ax, ECI_CALL_TERMINATE_STATUS
		push	ax
		mov	ax, ECI_CALL_RELEASE_STATUS
		push	ax
		mov	ax, ECI_CALL_CREATE_STATUS
		push	ax
		mov	ax, sp			; ss:ax = ECI ID array
	;
	; Fill in registration params.
	;
		sub	sp, size VpRegisterClientParams
		mov	bp, sp

		mov	ss:[bp].VRCP_eciReceive.segment, \
				vseg TermECICallback
		mov	ss:[bp].VRCP_eciReceive.offset, \
				offset TermECICallback

		mov	ss:[bp].VRCP_eciMessageIdArray.segment, ss
		mov	ss:[bp].VRCP_eciMessageIdArray.offset, ax
		mov	ss:[bp].VRCP_numberOfEciMessages, TERM_NUM_ECI_MSG

		mov	ss:[bp].VRCP_vpClientToken.segment, ds
		mov	ss:[bp].VRCP_vpClientToken.offset, offset vpClientToken
	;
	; Register.
	;		
		call	VpRegisterClient	; ax = VpRegisterClientResult
						; es can be destroyed
		add	sp, size VpRegisterClientParams
	;
	; Check register result
	;
		cmp	ax, VPRC_OK
		je	done			; carry clear
EC <		WARNING TERM_CANNOT_REGISTER_ECI			>
		stc				; can't register ECI msg

done:
		add	sp, TERM_NUM_ECI_MSG*2	; restore stack (ECI msg)

		.leave
		ret
TermRegisterECI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermUnregisterECI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister ECI messages

CALLED BY:	CloseComPort
PASS:		ds	= dgroup
RETURN:		carry set if cannot unregister
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermUnregisterECI	proc	far
		uses	ax, bp, es
		.enter
EC <		Assert_dgroup	ds					>
		CheckHack <size VpUnregisterClientParams eq size word>
		clr	ah
		mov	al, ds:[vpClientToken]
		push	ax			
		mov	bp, sp			; ss:bp <-
						; VpUnregisterClientParams 
		call	VpUnregisterClient	; ax = VpUnregisterClientResult
						; es can be destroyed
	;
	; Check result code
	;
		cmp	ax, VPUC_FAILED
		je	fail
		clc				; unregister ok
		jmp	done

fail:
EC <		WARNING TERM_CANNOT_UNREGISTER_ECI			>
		stc

done:
		pop	ax			; restore stack

		.leave
		ret
TermUnregisterECI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermECICallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine by registered ECI messages

CALLED BY:	VP library
PASS:		on stack:
			messageID	word
			msgStruct	hptr
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Queue message for TermClass process thread to handle

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermECICallback	proc	far	messageID:word,
				msgStruct:hptr
		.enter
	;
	; Deliver the message to Terminal receiver
	;
		mov	bx, handle dgroup
		call	MemDerefES
		mov	bx, es:[termProcHandle]
		mov	cx, ss:[msgStruct]
		mov	dx, ss:[messageID]
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_VP_CLIENT_ECI_RECEIVE
		call	ObjMessage

		.leave
		ret
TermECICallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermVpClientEciReceive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle ECI messages from IACP

CALLED BY:	MSG_VP_CLIENT_ECI_RECEIVE
		IACP from DataRec

PASS:		ds	= dgroup
		^hcx	= mesage structure
		dx	= message id
RETURN:		nothing
DESTROYED:	all (including ds/es)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	8/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermVpClientEciReceive	method dynamic TermClass, 
					MSG_VP_CLIENT_ECI_RECEIVE
		.enter
	;
	; check the message type and direct to appropriate handler. Supported
	; ECI messages:
	; 	ECI_CALL_DATA_CALL_COMING
	;	ECI_CALL_CREATE_STATUS
	;	ECI_CALL_TERMINATE_STATUS
	;	ECI_CALL_RELEASE_STATUS
	;
		cmp	dx, ECI_CALL_DATA_CALL_COMING
		je	callComing
		cmp	dx, ECI_CALL_CREATE_STATUS
		je	callCreated
		cmp	dx, ECI_CALL_TERMINATE_STATUS
		je	callTerminated
EC <		cmp	dx, ECI_CALL_RELEASE_STATUS			>
EC <		ERROR_NE UNEXPECTED_ECI_MESSAGE				>
callEnd::
		call	TermECICallReleaseStatus	; ax,bx,es destroyed
		jmp	done
	
callComing:
		mov	ds:[incomingRetries], INCOMING_CALL_MAX_TRIES
		mov	ds:[incomingCallData], cx
		call	TermECIDataCallComing		; bx destroyed
		jmp	done

callCreated:
		call	TermECICallCreateStatus
		jmp	done

callTerminated:
		call	TermECICallTerminateStatus	; bx destroyed
done:
		.leave
		ret
TermVpClientEciReceive	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermRetryAnsweringDataCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Try to answer an incoming call after already having
		tried to do so unsuccessfuly.  We need to distinguish
		because a new call might have come in after we first
		started trying to answer this one, in which case
		the new one takes precedence.

CALLED BY:	MSG_TERM_RETRY_ANSWERING_DATA_CALL
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		ds:bx	= TermClass object (same as *ds:si)
		es 	= segment of TermClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	7/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermRetryAnsweringDataCall	method dynamic TermClass, 
					MSG_TERM_RETRY_ANSWERING_DATA_CALL
	.enter
		cmp	ds:[incomingCallData], cx
		jne	stopTrying
		call	TermECIDataCallComing
done:
	.leave
	ret

stopTrying:
	;
	; The data block in incomingCallData is always the more recent
	; one, so discard the older block in cx, and stop trying to answer
	; its call.
	;
		mov	bx, cx
		call	MemFree
		jmp	done

TermRetryAnsweringDataCall	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermECIDataCallComing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an incoming data call

CALLED BY:	TermVpClientEciReceive
PASS:		ds	= dgroup
		dx	= message id
		^hcx	= mesage structure
RETURN:		nothing
DESTROYED:	all (including ds/es)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	If a data call is incoming, but we can't open the serial port,
	there are 2 cases:

		1) Fax modem (or other software that leaves the serial port
		   open) is active, and will always have the
		   serial port open.
		2) Another data call has just ended, but the software hasn't
		   yet closed the port.

	How do we distinguish 1 from 2?  We will continually try to open
	the serial port for as long as we think the phone is still ringing.
	If we haven't opened it by then, we'll assume case 1, and ignore the
	incoming call and assume that fax-modem (or whatever) is dealing
	with it.  Else, it's case 2.  Continue the process of answering
	the call.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermECIDataCallComing	proc	near
if _TELNET
		ERROR	TELNET_DOES_NOT_SUPPORT_ECI_DATA_CALL_COMING
else
		.enter
EC <		Assert_dgroup	ds					>
EC <		cmp	ds:[incomingCallData], cx			>
EC <		ERROR_NE TERM_ERROR					>
	;
	; Make sure that we have permission to call the serial thread.
	; Otherwise, the serial thread might be blocking for us,
	; and cause deadlock.  Requeue this message, but
	; take a trip through the serial thread first,
	; so we don't loop ourselves to death.
	;
	; DO NOT PUT ANY CODE BEFORE THIS THAT YOU DON'T WANT
	; EXECUTED MORE THAN ONCE PER CONNECTION.
	; 

	BitTest	ds:[statusFlags], TSF_PROCESS_MAY_BLOCK
	jnz	okToConnect

	mov	ax, MSG_VP_CLIENT_ECI_RECEIVE
	mov	bx, handle 0
	mov	di, mask MF_RECORD
	call	ObjMessage		; di = event

	mov	cx, di			; cx = event
	mov	dx, mask MF_FORCE_QUEUE
	mov	ax, MSG_META_DISPATCH_EVENT
	SendSerialThreadDS

	jmp	done
okToConnect:
	;
	; Don't allow the user to initiate a connection when we're trying
	; to answer the phone.  Don't do it by disabling/re-enabling
	; the trigger, 'cause we don't have enough knowledge to know
	; what state it should be in when we're done.
	;
		push	cx
		mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
		mov	cx, MSG_META_DUMMY
		mov	bx, handle ConnectionsGroupConnectTrigger
		mov	si, offset ConnectionsGroupConnectTrigger
		clr	di
		call	ObjMessage
		pop	cx
	;
	; initialize serial settings
	;
		call	TermSerialInitForIncoming
						; carry set if error
		jnc	continueAnswering
	;
	; Try opening the port again, after a delay
	;
		dec	ds:[incomingRetries]
		js	error		; run out of retries?
tryAgain:
	;
	; Would like to use an event timer here, but it won't let
	; us pass any extra data.
	;
		mov	bx, segment EnqueueRetryMessage
		mov	si, offset  EnqueueRetryMessage
		mov	dx, cx			; pass ECI block as data
		mov	cx, INCOMING_CALL_RETRY_DELAY
		mov	al, TIMER_ROUTINE_ONE_SHOT
		call	TimerStart		; ax,bx = ID, handle
		jmp	done

continueAnswering:
	;
	; Send special modem init strings
	;
		call	TermModemInitForIncoming; carry set if error
		mov	ax, offset cleanup
		mov	bp, mask DEF_SYS_MODAL or ERR_INCOMING_MODEM_INIT
		jc	displayError
	;
	; answer the modem
	;
		call	TermAnswerModemLow	; carry set if error
		jc	cleanup			; (indicator will handle note)
	;
	; remember the call id
	;
		mov	bx, cx
		call	MemLock
		mov	es, ax
		mov	al, es:[call_id_2105]
		mov	ds:[dataCallID], al
		mov	ds:[eciStatus], TECIS_CALL_CREATED
		call	MemFree
		clr	ds:[incomingCallData]
	;
	; bring Terminal app to the top
	;
		call	TermComeToTop
	;
	; bring up the emulator
	;
		call	TermInitiateEmulator
	;
	; Let the serial thread block as it needs to
	;
		call	TermAllowSerialToBlock

doneRestoreConnect:
	;
	; And restore normal workings of Connect trigger
	;
		mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
		mov	cx, MSG_TERM_MAKE_CONNECTION
		mov	bx, handle ConnectionsGroupConnectTrigger
		mov	si, offset ConnectionsGroupConnectTrigger
		clr	di
		call	ObjMessage
done:
		.leave
		ret
cleanup:
		call	TermCleanupIncoming
error:
	;
	; Must free ECI message
	;
		mov	bx, cx
		call	MemFree
		clr	ds:[incomingCallData]

		jmp	doneRestoreConnect

displayError:
;;;
;;;  Throw up an error dialog before continuing
;;;  PASS: ds = dgroup
;;;	   bp = DisplayErrorFlags
;;;	   ax = place to continue execution after putting up dialog

		push	ax, bx, cx, dx, si
		call	DisplayErrorMessage
		pop	ax, bx, cx, dx, si
		jmp	ax

endif ; NOT _TELNET
TermECIDataCallComing	endp

if not _TELNET

Main	segment	resource
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSerialInitForIncoming
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize variables to prepare for an incoming call

CALLED BY:	TermECIDataCallComing
PASS:		^hcx	= STR_ECI_CALL_DATA_CALL_COMING message structure
RETURN:		carry set if error initializing serial port
DESTROYED:	nothing
SIDE EFFECTS:	serial port open if carry clear
		serial port not open if carry set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	9/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermSerialInitForIncoming	proc	far
	msgStructHandle	local	hptr.STR_ECI_CALL_DATA_CALL_COMING \
							push	cx
		uses	ax,bx,cx,dx,si,di,ds,es
		.enter
	;
	; Get datarec access point
	;
		push	bp
		call	TermGetDatarecAccPnt		; bx,cx,dx,ds,si,
							; bp destroyed 
							; ax <- accpnt ID
							; carry set if err
		pop	bp
	;
	; we ASSUME that the data we need from the incoming access point
	; is all the item groups and nothing but the item groups
	;
	; we further ASSUME that all of the item groups APSP values
	; are contiguous starting at ITEM_APSP_TABLE_BASE and extending
	; to the end of ConnectionAPSPTable
	;
gotPoint:
		GetResourceSegmentNS	dgroup, ds
	;
	; Open up serial port, without dropping carrier, as AT emulator
	; on responder will nuke the incoming call.
	;
		cmp	ds:[serialPort], NO_PORT
		stc			; error if we have already opened port
		jne	done
	
		push	ax, bp		; save accpnt

		mov	cl, ds:[statusFlags]
		andnf	cl, mask TSF_DONT_DROP_CARRIER
		push	cx			; save drop-carrier flag
		ornf	ds:[statusFlags], mask TSF_DONT_DROP_CARRIER

		mov	cx, SERIAL_COM1	; Responder default com port
		call	OpenPort	; cx = 0 if com port no opened
					; ax,bx,dx,si,di destroyed
		pop	ax			; get drop-carrier flag
		andnf	ds:[statusFlags], not mask TSF_DONT_DROP_CARRIER
		ornf	ds:[statusFlags], al

EC <		tst	cx						>
EC <		WARNING_Z TERM_CANNOT_OPEN_COM_PORT			>
		stc
		pop	ax, bp		; restore accpnt
		jcxz	done
	;
	; Set up misc things
	;
		push	ax, bp		; save accpnt
		call	RestoreState
		pop	ax, bp		; restore accpnt
	;
	; Set the serial format from the incoming call parameters passed in.
	;
		mov	cx, ss:[msgStructHandle]
		call	TermSerialInitForIncomingSetFormat
	;
	; try to read the next setting from the init file. Note that we don't
	; start SI from zero because we have to skip the serial settings that
	; have been set by TermSerialInitForIncomingSetFormat.
	;					-Simon 11/20/96
	;
		mov	si, NUM_ITEM_SETTINGS_TO_SKIP_FOR_INCOMING_CALL * \
			size AccessPointStandardProperty
top:
		push	ax				; save accpnt ID
		clr	cx
		mov	dx, cs:[ITEM_APSP_TABLE_BASE][si]
		call	AccessPointGetIntegerProperty	; ax = value
		jnc	gotVal
	;
	; if we couldn't read it, use the default
	;
		mov	ax, cs:[ConnectionItemDefaultSelectionTable][si]
	;
	; pass it to the appropriate routine
	;
gotVal:
		mov_tr	cx,ax
		CheckHack <segment TermSerialInitForIncoming eq \
			segment ConnectionUpdateRoutineTable>
		call	cs:[ConnectionUpdateRoutineTable][si]
		pop	ax				; restore accpnt ID
	;
	; go to next value
	;
pastCall::
		inc	si
		inc	si
		cmp	si, ITEM_APSP_TABLE_END - ITEM_APSP_TABLE_BASE
		jb	top				; carry clear
done:		
		.leave
		ret
TermSerialInitForIncoming	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSerialInitForIncomingSetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the serial format for incoming call

CALLED BY:	(INTERNAL) TermSerialInitForIncoming
PASS:		^hcx	= STR_ECI_CALL_DATA_CALL_COMING message structure
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Lock message block;
	if (call_data_bits == 8) {
		Set data bits to 8;
	} else {
		Set data bits to 7;
	}
	if (call_stop_bits == 2) {
		Set stop bits to SBO_TWO;
	} else {
		Set stop bits to SBO_ONE;
	}
	switch (call_parity) {
	case 0:
		Set parity to None;
		break;
	case 1:
		Set parity to Odd;
		break;
	case 2:
		Set parity to Even;
		break;
	default:
		ERROR;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	11/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermSerialInitForIncomingSetFormat	proc	near
		uses	ax, bx, cx, dx, es, di
		.enter
EC <		Assert	handle	cx					>
EC <		Assert	dgroup	ds					>
		push	cx
		mov	bx, cx
		call	MemLock			; ax = sptr to msg struct
		mov	es, ax
		clr	di			; es:di = msg struct
	;
	; Set the data bits. Either 8 data bits or 7
	;
		mov	cx, (SL_8BITS shl offset SF_LENGTH) or \
			(mask SF_LENGTH shl 8)	; default is 7 data bist
		cmp	es:[di].call_data_bits_2105, 8
		je	setDataBits
EC <		cmp	es:[di].call_data_bits_2105, 7			>
EC <		ERROR_NE TERM_INVALID_ECI_CALL_DATA_CALL_COMING_DATA_BITS>
		mov	cx, (SL_7BITS shl offset SF_LENGTH) or \
			(mask SF_LENGTH shl 8) 

setDataBits:
		call	TermAdjustFormat1
	;
	; Set the stop bits
	;
		mov	cx, SBO_TWO
		cmp	es:[di].call_stop_bits_2105, 2
		je	setStopBits
EC <		cmp	es:[di].call_stop_bits_2105, 1			>
EC <		ERROR_NE TERM_INVALID_ECI_CALL_DATA_CALL_COMING_STOP_BITS>
		mov	cx, SBO_ONE

setStopBits:
		call	TermAdjustFormat2
	;
	; Set the parity
	;
		clr	bh
		mov	bl, es:[di].call_parity_2105
EC <		Assert	inList	bx, <ECI_CALL_DATA_PARITY_NONE, ECI_CALL_DATA_PARITY_ODD, ECI_CALL_DATA_PARITY_EVEN>>
		shl	bx			; chnaged to word index
		mov	cx, cs:[ParityValueTable][bx]

setParity::
		call	TermAdjustFormat3

unlockMsgStruct::
		pop	bx
		call	MemUnlock		; bx destroyed
		.leave
		ret
TermSerialInitForIncomingSetFormat	endp

;
; Set the parity value to the parity table
;
SetParityTableEntry	macro	eciParity, parityValue
.assert ((eciParity eq ECI_CALL_DATA_PARITY_NONE) or \
	 (eciParity eq ECI_CALL_DATA_PARITY_ODD) or \
	 (eciParity eq ECI_CALL_DATA_PARITY_EVEN)),
	<SetParityTableEntry: Invalid parity>
.assert (($-ParityValueTable) eq (eciParity * (size word))), \
	<SetParityTableEntry: Parity value not in right sequence>
.assert (PARITY_TABLE_ENTRY eq eciParity), \
	<SetParityTableEntry: definitions not in correct order>
		word	parityValue	

PARITY_TABLE_ENTRY=PARITY_TABLE_ENTRY+1
endm

PARITY_TABLE_ENTRY=0

ParityValueTable	label	word
SetParityTableEntry	ECI_CALL_DATA_PARITY_NONE, <(SP_NONE shl offset SF_PARITY) or (mask SF_PARITY shl 8)>
SetParityTableEntry	ECI_CALL_DATA_PARITY_ODD,  <(SP_ODD shl offset SF_PARITY) or (mask SF_PARITY shl 8)>
SetParityTableEntry	ECI_CALL_DATA_PARITY_EVEN, <(SP_EVEN shl offset SF_PARITY) or (mask SF_PARITY shl 8)>

CheckHack <ECI_CALL_DATA_PARITY_NONE eq 0>
CheckHack <ECI_CALL_DATA_PARITY_ODD gt ECI_CALL_DATA_PARITY_NONE>
CheckHack <ECI_CALL_DATA_PARITY_EVEN gt ECI_CALL_DATA_PARITY_ODD>
.assert (PARITY_TABLE_ENTRY eq ECI_CALL_DATA_PARITY_EVEN+1), \
	<Too many or too few entries in ParityValueTable>

Main	ends
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermModemInitForIncoming
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send init strings to modem

CALLED BY:	TermECIDataCallComing
PASS:		nothing
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	9/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermModemInitForIncoming	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es,ds
		.enter
if	_MODEM_STATUS
	;
	; Tell serial line to start keep track of modem response
	;
		mov	ax, MSG_SERIAL_CHECK_MODEM_STATUS_START
		GetResourceSegmentNS	dgroup, es
		SendSerialThread	; ax,cx destroyed
	;
	; Send whatever init string we need to send before users'
	;
		mov	es:[modemInitStart], TRUE
		mov	dl, TIMIS_FACTORY
		mov	ax, MSG_SERIAL_SEND_INTERNAL_MODEM_COMMAND
		call	TermWaitForModemResponse
					; carry set if error
		mov	es:[modemInitStart], FALSE
		jc	clean
		cmp	es:[responseType], TMRT_OK
		jne	clean
endif	; if _MODEM_STATUS
	;
	; send the user's modem initialization code, if any
	;
		call	TermSendDatarecModemInit	; carry if error
							; ax,bx,cx,dx,bp
							; ds,si destroyed
		jc	clean
	;
	; wait for the OK prompt
	;
if	_MODEM_STATUS
		cmp	es:[responseType], TMRT_OK
		jne	clean
	;
	; Send whatever init string we need to send before users'
	;
		mov	es:[modemInitStart], TRUE
		mov	dl, TIMIS_INTERNAL
		mov	ax, MSG_SERIAL_SEND_INTERNAL_MODEM_COMMAND
		call	TermWaitForModemResponse	; carry set if error
		mov	es:[modemInitStart], FALSE
		jc	clean
		cmp	es:[responseType], TMRT_OK
		je	done

clean:
		mov	ax, MSG_SERIAL_CHECK_MODEM_STATUS_END
		SendSerialThread
		stc					; clean when error

endif	; if _MODEM_STATUS
done:
		.leave
		ret
TermModemInitForIncoming	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermAnswerModemLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a modem string to answer the modem

CALLED BY:	TermECIDataCallComing
PASS:		ds	- dgroup
RETURN:		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	9/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
answerString	char	"ATA"
TermAnswerModemLow	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; send answerString
	;
		segmov	dx, cs, ax
		mov	ax, MSG_SERIAL_SEND_CUSTOM_MODEM_COMMAND
		mov	bp, offset answerString
		mov	cl, size answerString
		clr	ch			; long timeout 
		call	TermWaitForModemResponse; carry set if error	
if	_MODEM_STATUS
		jc	clean
else
		jc	done
endif
	;
	; wait for response
	;
if _MODEM_STATUS
		Assert	dgroup, es
		cmp	es:[responseType], TMRT_CONNECT
		je	clean
		stc

clean:
		pushf
		GetResourceSegmentNS	dgroup, es
		mov	ax, MSG_SERIAL_CHECK_MODEM_STATUS_END
		SendSerialThread
		popf
endif
done:
		.leave
		ret
TermAnswerModemLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermCleanupIncoming
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after a failed incoming call

CALLED BY:	TermECIDataCallComing
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermCleanupIncoming	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Shut down the com port
	;
		Assert	dgroup, ds
		call	CloseComPort
	;
	; Clear screen to reduce memory usage
	;
if _CLEAR_SCR_BUF
		mov	ax, MSG_SCR_CLEAR_SCREEN_AND_SCROLL_BUF
		mov	bx, ds:[termuiHandle]
		SendScreenObj
endif
		.leave
		ret
TermCleanupIncoming	endp

endif	;  not _TELNET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermECICallCreateStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A call has been created

CALLED BY:	TermVpClientEciReceive
PASS:		ds	= dgroup
		^hcx	= message struct
RETURN:		nothing
DESTROYED:	ax, bx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	3/24/96    	Initial version
	jwu	11/27/96	Log data call with Contact Log

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermECICallCreateStatus	proc	near
		.enter
	;
	; lock down the STR_ECI_CALL_CREATE_STATUS
	;
		mov	bx, cx
		call	MemLock
		mov	es, ax
	;
	; only pay attention to OK data calls
	;
		cmp	es:[call_mode_2004], ECI_CALL_MODE_DATA
		jne	done

		cmp	es:[status_2004], ECI_OK
		jne	done
	;
	; this is an OK data call, so grab the ID
	;
		mov	al, es:[call_id_2004]
		mov	ds:[dataCallID], al
		mov	ds:[eciStatus], TECIS_CALL_CREATED
	;
	; Log start of data call.
	;
		call	TermLogCallStart
done:
		call	MemFree
		.leave
		ret
TermECICallCreateStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermECICallReleaseStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle data call ended by mobile user

CALLED BY:	TermVpClientEciReceive
PASS:		ds	= dgroup
		^hcx	= message struct 
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di, si, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if our call was released, close the port

	This message may be received in two situations:
		1) User ends the call by pressing Hang up, in which
			case the disconnection UI will already
			have been put up

		2) an outside source on the PDA ends the call (like
			phone app), and we need to initiate the UI
			changes here.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/ 9/95    	Initial version
	jwu	11/27/96	Log end of data call with Contact Log

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermECICallReleaseStatus	proc	near
	;
	; Lock the message struct to check the id. If it is caused by
	; wrong ID, ignore message.
	;
		mov	bx, cx
		call	MemLock			; ax <- sptr of msg block
		mov	es, ax
		mov	al, es:[call_id_2015]
		call	MemFree			; free message block
		cmp	al, ds:[dataCallID]
		jne	done
	;
	; Log end of data call.
	;
		call	TermLogCallEnd

		clr	ds:[dataCallID]
		mov	ds:[eciStatus], TECIS_CALL_RELEASED
		GOTO	TermConnectionLost
done:
		ret
TermECICallReleaseStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermECICallTerminateStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle data call to connection being terminatd from remote
		side. 

CALLED BY:	TermVpClientEciReceive
PASS:		ds	= dgroup
		^hcx	= mesage struct
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di, si, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Check call ID;
	Log connection time;
	Change UI;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/ 5/95    	Initial version
	jwu	11/27/96	Log end of data call with Contact Log

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermECICallTerminateStatus	proc	near
	;
	; make sure this is our call
	;
		mov	bx, cx
		call	MemLock
		mov	es, ax
		mov	al, es:[call_id_2016]
		call	MemFree
		cmp	al, ds:[dataCallID]
		jne	done
	;
	; Log end of data call.
	;
		call	TermLogCallEnd

		clr	ds:[dataCallID]
		mov	ds:[eciStatus], TECIS_CALL_TERMINATED
		GOTO	TermConnectionLost
done:
		ret

TermECICallTerminateStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermConnectionLost
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs approriate cleanup when terminal connection
		lost (because of local or remote activity).  If the
		connection is already closed, assume that whatever
		close the connection took care of cleaning up.

		This routine is called exactly once for each
		terminal data call termination.

CALLED BY:	INTERNAL
			TermECICallReleaseStatus
			TermECICallTerminateStatus

PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermConnectionLost	proc	near
	;
	; If the com port is already closed, don't disconnect anything or put
	; up any UI as the connection is already gone.
	;
		cmp	ds:[serialPort], NO_PORT
		je	done
	;
	; If user is canceling connection, don't do anything
	;
		cmp	ds:[responseType], TMRT_USER_CANCEL
		je	done
	;
	; Display disconection dialog box
	;
		GetResourceHandleNS	DisconnectionIndicatorDialog, bx
		mov	si, offset DisconnectionIndicatorDialog
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Close com port
	;
		call	CloseComPort

doneClosingPort::
	;
	; Tell the serial thread to give the right to block back to the
	; process.
	;
		call	TermSerialStopBlocking
	;
	; Change UI
	;
		call	TermEndCallChangeUI		; nothing destroyed
	;
	; Make sure text send/capture files are closed.
	;
		call	GeodeGetProcessHandle
		mov	ax, MSG_FILE_SEND_STOP
		mov	di, mask MF_CALL
		call	ObjMessage

		mov	ax, MSG_FILE_RECV_STOP_CHECK_DISKSPACE
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Dismiss disconnection dialog box
	;
		GetResourceHandleNS	DisconnectionIndicatorDialog, bx
		mov	si, offset DisconnectionIndicatorDialog
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		mov	di, mask MF_CALL
		call	ObjMessage
	
done:
		.leave
		ret
TermConnectionLost	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermEndCallChangeUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change UI when data call ends

CALLED BY:	TermECICallTerminateStatus
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermEndCallChangeUI	proc	near
		uses	ax, cx, dx
		.enter
	;
	; Change disconnect trigger to "Close"
	;
		mov	dx, CMST_LPTR
		clr	ax
		mov	cx, offset CloseScreenText
		CheckHack <segment CloseScreenText eq \
			segment	DisconnectPrimaryTrigger>
		call	TermReplaceDisconnectMoniker
		
		.leave
		ret
TermEndCallChangeUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermReplaceDisconnectMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the disconnection moniker

CALLED BY:	TermMakeConnection, TermEndCallChangeUI
PASS:		dx	= ComplexMonikerSourceType		
		axcx	= source of text depending on
			ComplexMonikerSourceType passed in (see foam.def)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermReplaceDisconnectMoniker	proc	far
		uses	ax, bx, cx, dx, si, di, bp
		.enter
	;
	; Set up the parameters to replace disconnect moniker
	;
                sub     sp, size ReplaceComplexMoniker
                mov     bp, sp			;ss:bp=ComplexMonikerParameters

                movdw   ss:[bp].RCM_topTextSource, axcx
                mov	ss:[bp].RCM_topTextSourceType, dx
                clr     ax
                movdw   ss:[bp].RCM_iconBitmapSource, axax
                mov     ss:[bp].RCM_iconBitmapSourceType, ax
		mov     ss:[bp].RCM_textStyleSet, mask TS_BOLD
                mov     ss:[bp].RCM_textStyleClear, al
                mov     ss:[bp].RCM_fontSize, ax
                mov     ss:[bp].RCM_overwrite, ax
						; don't free anything
                mov     dx, ss			;dx:bp=ComplexMonikerParameters

		GetResourceHandleNS	DisconnectPrimaryTrigger, bx
                mov     si, offset DisconnectPrimaryTrigger
                mov     di, mask MF_CALL
                mov     ax, MSG_COMPLEX_MONIKER_REPLACE_MONIKER
                call    ObjMessage

                add     sp, size ReplaceComplexMoniker
		
		.leave
		ret
TermReplaceDisconnectMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermMetaQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform process quitting procedures

CALLED BY:	MSG_META_QUIT
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		es 	= segment of TermClass
		ax	= message #
		dx - QuitLevel (if sent to a process)
			if QuitLevel = QL_AFTER_DETACH
				SI:CX - Ack OD to be passed on to
				MSG_META_QUIT_ACK 
				(Can use CX, since it is illegal to abort here)
			else (QuitLevel != QL_AFTER_DETACH
				cx - clear (can just send MSG_META_QUIT_ACK
				without clearing)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Close IACP connection with VP.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermMetaQuit	method dynamic TermClass,
					MSG_META_QUIT
		uses	ax, bx, cx, es, si
		.enter
        ;--------------------------------------------------
        ; unregister our callback routine from the VP lib
        ; (code copied from faxrecApplication's FAMetaQuit)
	;--------------------------------------------------
        ;
        ; close that pesky IACP connection that they have to us or we will
        ; never be able to quit
        ;
                sub     sp, size GeodeToken
                mov     bp, sp
                CheckHack < size TokenChars eq 4 >
                mov     {word}ss:[bp].GT_chars, 'TE'
                mov     {word}ss:[bp+2].GT_chars, 'RM'
                mov     {word}ss:[bp].GT_manufID, MANUFACTURER_ID_GEOWORKS
closeIACP::
                call    VpCloseIacp			; can destroy ES
                add     sp, size GeodeToken
        ;
        ; call superclass to do normal stuff
        ;
	        .leave
	        mov     di, offset TermClass
	        GOTO    ObjCallSuperNoLock	
TermMetaQuit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermClearBlacklist
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send an ECI message to clear the blacklist

CALLED BY:	(INTERNAL) TermMakeConnectionInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Codes copied from PPPClearBlacklist		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermClearBlacklist	proc	far
		uses	ax, bx, cx, dx, bp, es
		.enter

		sub	sp, size VpSendEciMessageParams
		mov	bp, sp
		clr	ax
		mov	ss:[bp].VSEMP_eciMessageID, ECI_CALL_CLEAR_BLACKLIST
		movdw	ss:[bp].VSEMP_eciStruct, axax
		call	VpSendEciMessage
		add	sp, size VpSendEciMessageParams
	
		.leave
		ret
TermClearBlacklist	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermSendEciCallReleaseAfterCancel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send ECI_CALL_RELEASE after user cancels connection

CALLED BY:	MSG_TERM_SEND_ECI_CALL_RELEASE_AFTER_CANCEL
PASS:		*ds:si	= TermClass object
		ds:di	= TermClass instance data
		es 	= segment of TermClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	
	if (dataCallID != NULL) {
		send out release call eci message;
		Close com port;
		Clean up what TermMakeConnection should have cleaned up;
	} else if (eciStatus != NO_CONNECTION) {
		Close com port;
		Clean up what TermMakeConnection should have cleaned up;
	}	
	if (eciStatus == TECIS_NO_CONNECTION) {
		// wait for create message
		Re-queue this message;
	}

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	6/16/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermSendEciCallReleaseAfterCancel	method dynamic TermClass, 
			MSG_TERM_SEND_ECI_CALL_RELEASE_AFTER_CANCEL
	eciStruct	local	STR_ECI_CALL_RELEASE
		.enter
	;
	; If call ID is not valid, check if we have created any call at
	; all. If so, we queue up a message to wait until call create message
	; is established so that we can release the call.
	;
		GetResourceSegmentNS	dgroup, ds, TRASH_BX
		tst	ds:[dataCallID]
		jnz	releaseCall
	;
	; No data call ID. Either ECI_CALL_CREATE_STATUS has not been received
	; or the call has been released/terminated. So, we need to check if
	; it is the former.
	; 
		cmp	ds:[eciStatus], TECIS_NO_CONNECTION
		je	resend		; releasing a call not yet created,
					; need to wait till call created
		Assert inList	ds:[eciStatus], <TECIS_CALL_TERMINATED, TECIS_CALL_RELEASED>
EC <		WARNING TERM_IGNORE_ECI_CALL_RELEASE			>
		jmp	cleanup		; otherwise, call should be ended
	
releaseCall:
EC <		WARNING TERM_SEND_ECI_CALL_RELEASE			>
		segmov	ss:[eciStruct].call_id_2014, ds:[dataCallID], al
		push	bp
		sub	sp, size VpSendEciMessageParams
		lea	ax, ss:[eciStruct]
		mov	bp, sp
		mov	ss:[bp].VSEMP_eciMessageID, ECI_CALL_RELEASE
		movdw	ss:[bp].VSEMP_eciStruct, ssax
		call	VpSendEciMessage
		add	sp, size VpSendEciMessageParams
		pop	bp
cleanup:
	;
	; Done sending release
	;
EC <		Assert_dgroup	ds					>
		BitClr	ds:[statusFlags], TSF_WAIT_FOR_DIAL_RESPONSE
	;
	; Clean up whatever left for TermMakeConnection
	;
		call	CloseComPort
	;
	; End parsing modem status and dismiss connection cancelling dialog
	;
		stc				; a kind of error exiting
		call	TermMakeConnectionExit	; all destroyed
		call 	TermDismissCancelConnectionDialog

done:		
		.leave
		ret

resend:
EC <		WARNING	TERM_RESEND_ECI_CALL_RELEASE			>
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	bx, ds:[termProcHandle]
		mov	cx, ONE_SECOND/2
		mov	dx, MSG_TERM_SEND_ECI_CALL_RELEASE_AFTER_CANCEL
		call	TimerStart
		jmp	done
TermSendEciCallReleaseAfterCancel	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermLogCallStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Log start of data call with Contact Log. 

CALLED BY:	TermECICallCreateStatus

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Log call, providing access point name if available, 
		else use phone number.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/27/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermLogCallStart	proc	near
		uses	ax, bx, cx, dx, bp, di, si, es
		.enter

		Assert_dgroup	ds
	;
	; Get access point name.  If none, get phone number.
	;
		mov	ax, ds:[settingsConnection]	; ax = accpnt ID
EC <		call	AccessPointIsEntryValid				>

		clr	cx
		mov	dx, APSP_NAME
getInfo:
		segmov	es, ds, di
		lea	di, es:[termLogEntry].LE_number
		mov	bp, size NameOrNumber
		call	AccessPointGetStringProperty
		
		jnc	getTime
		tst	cx
		jnz	getTime

EC <		cmp	dx, APSP_PHONE					>
EC <		ERROR_E	TERM_NO_ACCPNT_NAME_NOR_NUMBER			>

		clr	cx
		mov	dx, APSP_PHONE
		jmp	getInfo		

getTime:
	;
	; Fill in start time and date.
	;
		call	TimerGetDateAndTime
		mov	si, offset ds:[termLogEntry]
		mov	ds:[si].LE_datetime.DAT_year, ax
		mov	ds:[si].LE_datetime.DAT_month, bl
		mov	ds:[si].LE_datetime.DAT_day, bh
		mov	ds:[si].LE_datetime.DAT_hour, ch
		mov	ds:[si].LE_datetime.DAT_minute, dl
	;
	; Get count so we can figure out duration at end of call.
	;
		call	TimerGetCount			; bxax = count
		pushdw	bxax

		call	LogAddEntry
EC <		WARNING_C TERM_CANNOT_LOG_CALL_START		>

		popdw	ds:[si].LE_duration

		.leave
		ret
TermLogCallStart	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermLogCallEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Log end of data call with Contact Log, if start of call was
		logged.  Reset LogEntry values for next call.

CALLED BY:	TermECICallReleaseStatus
		TermECICallTerminateStatus

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/27/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermLogCallEnd	proc	near
		uses	ax, bx, si
		.enter

		Assert_dgroup	ds
	;
	; Only log end if start of call was logged.
	;
		mov	si, offset ds:[termLogEntry]
		tst	ds:[si].LE_flags
		jz	reset				; not logged
	;
	; Calculate duration in seconds.
	;
		call	TimerGetCount			; bxax = count
		mov	dx, bx			
		subdw	dxax, ds:[si].LE_duration

		mov	cx, ONE_SECOND
		div	cx				

		tst	dx
		jz	store

		clr	dx
		add	ax, 1				; round up to next second
		adc	dx, 0
store:
		movdw	ds:[si].LE_duration, dxax
		call	LogAddEntry
EC <		WARNING_C TERM_CANNOT_LOG_CALL_END			>

reset:
	;
	; Reset LogEntry settings for next call.
	;
		clr	ax
		movdw	ds:[si].LE_duration, axax
		mov	ds:[si].LE_flags, al
		movdw	ds:[si].LE_contactID, LECI_INVALID_CONTACT_ID


		.leave
		ret
TermLogCallEnd	endp


EciCode		ends

endif	; _VSER

if _VSER

Fixed		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnqueueRetryMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enqueues an ECI data-call-coming message.
		Part of the wait-n-retry mechanism of answering
		an incoming data call.

CALLED BY:	TermECIDataCallComing (via TimerStart & interrupt code)
PASS:		^hax	= ECI data block
RETURN:		
DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es (allowed by timer code)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	7/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnqueueRetryMessage	proc	far
	.enter
	;
	; Deliver the message to Terminal receiver
	;
		mov	bx, handle 0
		mov	cx, ax
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_TERM_RETRY_ANSWERING_DATA_CALL
		call	ObjMessage
	.leave
	Destroy	ax, bx, cx, dx, si, di, bp
	ret
EnqueueRetryMessage	endp

Fixed		ends

endif ; _VSER


if _VSER or _LOGIN_SERVER


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermInitiateEmulator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate the emulator window

CALLED BY:	TermECIDataCallComing
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	9/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermInitiateEmulator	proc	far
		ret
TermInitiateEmulator	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermComeToTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring Terminal app to top, remembering previous state

CALLED BY:	TermECIDataCallComing
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TermComeToTop	proc	far
		uses	ax,bx,si,di,ds
		.enter
if _VSER
		CheckHack <BB_TRUE eq (BB_FALSE xor 255)>
	;
	; if we have the full-screen exclusive, we're already on the top
	;
		GetResourceSegmentNS dgroup, ds, TRASH_BX
		mov	al, ds:[haveExclusive]
		xor	al, 255				; invert true/false
		mov	ds:[buryOnDisconnect], al
		jz	done
endif ; _VSER
	;
	; beam us up, Scotty
	;
		mov	ax, MSG_GEN_BRING_TO_TOP
		GetResourceHandleNS MyApp, bx
		mov	si, offset MyApp
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
		.leave
		ret
TermComeToTop	endp


endif ; _VSER or _LOGIN_SERVER

