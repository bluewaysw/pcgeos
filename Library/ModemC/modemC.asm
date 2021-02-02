COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PCGEOS
MODULE:		modemC
FILE:		modemC.asm

AUTHOR:		Chris Thomas, Aug 27, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/27/96   	Initial revision


DESCRIPTION:

	C stubs for the modem driver
		

	$Id: modemC.asm,v 1.1 97/04/05 01:23:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemLibraryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load/Unload the modem driver when library loads/unloads

CALLED BY:	At load time
PASS:		ds	= dgroup
		di	= LibraryCallType
RETURN:		carry set if error
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NEC <driverName	char	"modem.geo", 0					>
EC  <driverName	char	"modemec.geo", 0				>

global ModemLibraryEntry:far
ModemLibraryEntry	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter
		cmp	di, LCT_DETACH
		je	detach
		cmp	di, LCT_ATTACH
		jne	noProblem
	;
	; Load the modem driver
	; 
		segmov	es, ds			; es = dgroup
		segmov	ds, cs
		mov	si, offset driverName
		mov	ax, MODEM_PROTO_MAJOR	; need only be compatible with
		mov	bx, 0			;  original protocol
		call	GeodeUseDriver
		jc	done
	;
	; And store the driver handle & strategy
	;
		mov	es:[modemHandle], bx
		call	GeodeInfoDriver		; ds:si = info block
		movdw	cxdx, ds:[si].DIS_strategy
		movdw	es:[modemStrategy], cxdx
noProblem:
		clc
done:
	.leave
	ret

detach:
	;
	; Unload modem driver
	;
		mov	bx, ds:[modemHandle]
		call	GeodeFreeDriver		; destroys bx, carry
		jmp	noProblem

ModemLibraryEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemClientDataNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ASM stub for data notification routine.

CALLED BY:	data notification of modem driver
PASS:		ax	= word of extra data registered in bp by
			  DR_MODEM_SET_NOTIFY.  Passed on to client
			  in data parameter.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.warn	-unref
ModemClientDataNotify	proc	far
.warn	@unref
	uses	ax, bx, cx, dx, ds, es		; C routines may trash any
	.enter					;   of these (we trash ds)

	mov	bx, handle dgroup
	call	MemDerefDS
	push	ax				; push 'data' parameter
	pushdw	ds:[dataCallback].CCI_callback	; push callback address
	mov	bx, ds:[dataCallback].CCI_geode
	call	GeodeGetDGroupDS		; load client routine's dgroup

	call	PROCCALLFIXEDORMOVABLE_PASCAL

	.leave
	ret
ModemClientDataNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemClientResponseNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ASM stub for response notification routine.

CALLED BY:	response notification of modem driver
PASS:		ax	= word of extra data registered in bp by
			  DR_MODEM_SET_NOTIFY.  Passed on to client
			  in data parameter.
		cx	= response size
		dx:bp	= response buffer

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.warn -unref
ModemClientResponseNotify	proc	far
.warn @unref
	uses	ax, bx, cx, dx, ds, es		; C routines may trash any
	.enter					;   of these (we trash ds)

	mov	bx, handle dgroup
	call	MemDerefDS
	push	ax				; pass 'data' parameter
	push	cx				; pass 'responseSize'
	pushdw	dxbp				; pass 'response'
	pushdw	ds:[respCallback].CCI_callback	; push callback address
	mov	bx, ds:[respCallback].CCI_geode
	call	GeodeGetDGroupDS		; load client routine's dgroup

	call	PROCCALLFIXEDORMOVABLE_PASCAL

	.leave
	ret
ModemClientResponseNotify	endp

SetGeosConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MODEMSETROUTINEDATANOTIFY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	extern void
	_pascal ModemSetRoutineDataNotify(SerialPortNum port,
					  word data,
					  ModemDataNotifyRoutine *callback);

CALLED BY:	EXTERNAL

PSEUDO CODE/STRATEGY:
	Assume the notification routine is written in C, and uses
	the pascal calling convention.  We need to provide an ASM stub
	to register with the driver, which will properly call the
	client's C routine.

	We want to use FALL_THRU and GOTO's here, but that messes up
	the expected stack frames in EC

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global MODEMSETROUTINERESPONSENOTIFY:far
MODEMSETROUTINERESPONSENOTIFY	proc	far
	mov	bx, offset respCallback
	mov	cx, offset ModemClientResponseNotify
	mov	al, StreamNotifyType <1, SNE_RESPONSE, SNM_ROUTINE>
	jmp	ModemSetRoutineNotifyCommon
MODEMSETROUTINERESPONSENOTIFY	endp

global MODEMSETROUTINEDATANOTIFY:far
MODEMSETROUTINEDATANOTIFY	proc	far
	mov	bx, offset dataCallback
	mov	cx, offset ModemClientDataNotify
	mov	al, StreamNotifyType <1, SNE_DATA, SNM_ROUTINE>
	REAL_FALL_THRU	ModemSetRoutineNotifyCommon
MODEMSETROUTINEDATANOTIFY	endp

RoutineNotifyFrame	struct
	RNF_savedBP	word
	RNF_retAddr	fptr.far
	RNF_destination	fptr.far		; this is all we care about
RoutineNotifyFrame	ends

; Common routine for routine notifications that figures out the owning
; geode of the notification routine, and stores it, so that we can load
; up the routine's geode's dgroup when we call it.
;
; bx = offset to CCallbackInfo
; cx = offset of callback stub
; ax = StreamNotifyType to ModemSetNotifyCommon
;
ModemSetRoutineNotifyCommon	proc	far
	push	bx
	mov	bx, handle dgroup
	call	MemDerefES
	pop	bx				; bx = CCallbackInfo
	mov_tr	dx, bp				; dx = old bp
	push	bp

	mov	bp, sp
	xchg	cx, ss:[bp].RNF_destination.low	; replace callback arg /w
	mov	es:[bx].CCI_callback.low, cx	;   our stub
	mov	cx, vseg CommonCode
	xchg	cx, ss:[bp].RNF_destination.high ; and stash the passed
	mov	es:[bx].CCI_callback.high, cx	;  callback routine.

	call	MemSegmentToHandle
	push	ax
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	push	bx
	mov	bx, cx
	call	MemGetInfo
	pop	bx
	mov	es:[bx].CCI_geode, ax
	pop	ax
	pop	bp

	jmp	ModemSetNotifyCommonJmp
ModemSetRoutineNotifyCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MODEMSETMESSAGEDATANOTIFY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	extern void
		_pascal ModemSetMessageDataNotify(SerialPortNum port,
						  Message msg,
						  optr destination);

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global MODEMSETMESSAGERESPONSENOTIFY:far
MODEMSETMESSAGERESPONSENOTIFY	proc	far
	mov	al, StreamNotifyType <1, SNE_RESPONSE, SNM_MESSAGE>
	jmp	ModemSetNotifyCommonJmp
MODEMSETMESSAGERESPONSENOTIFY	endp

global MODEMSETMESSAGEDATANOTIFY:far
MODEMSETMESSAGEDATANOTIFY	proc	far
	mov	al, StreamNotifyType <1, SNE_DATA, SNM_MESSAGE>
	REAL_FALL_THRU	ModemSetNotifyCommon
MODEMSETMESSAGEDATANOTIFY	endp

ModemSetNotifyCommon	proc	far	port:SerialPortNum,
					msg:word,
					destination:dword
ModemSetNotifyCommonJmp	label	far

	uses	di
	.enter

	push	bp
	mov	bx, ss:port
	movdw	cxdx, ss:destination
	mov	bp, ss:msg
	mov	di, DR_MODEM_SET_NOTIFY
	call	CallModem
	pop	bp

	.leave
	ret
ModemSetNotifyCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MODEMSETMESSAGEENDCALLNOTIFY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up a message to be sent when the data call ends.

CALLED BY:	EXTERNAL
	extern Boolean
	_pascal ModemSetMessageEndCallNotify(SerialPortNum port,
					     Message msg,
					     optr destination);

RETURN:		ax=TRUE if not supported
DESTROYED:	bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global MODEMSETMESSAGEENDCALLNOTIFY:far
MODEMSETMESSAGEENDCALLNOTIFY	proc	far	port:SerialPortNum,
						msg:word,
						dest:optr
if _SUPPORTS_END_CALL_NOTIFICATION

	uses	ds
	.enter

	;
	; Store the notification destination and message for later
	;
	mov	bx, handle dgroup
	call	MemDerefDS
		
	movdw	ds:[endCallDest], ss:[dest], ax
	mov	ax, ss:[msg]
	mov	ds:[endCallMsg], ax

	;
	; And return supported
	;
	clr	ax

	.leave

else ; not _SUPPORTS_END_CALL_NOTIFICATION
	.enter
	;
	; Return "not supported"
	;
	mov	ax, TRUE
	.leave
endif
	ret
MODEMSETMESSAGEENDCALLNOTIFY	endp

if _SUPPORTS_END_CALL_NOTIFICATION

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModemSendEndCallNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If an end-call notification has been registered,
		send it.

CALLED BY:	ModemECICallback
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModemSendEndCallNotification	proc	near
	uses	ax, bx, si, di, ds
	.enter

	mov	bx, handle dgroup
	call	MemDerefDS
	;
	; If notification registered, send it.
	;
	mov	bx, ds:[endCallDest].handle
	tst	bx
	jz	done
	mov	si, ds:[endCallDest].segment
	mov	ax, ds:[endCallMsg]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	.leave
	ret
ModemSendEndCallNotification	endp

endif ; _SUPPORTS_END_CALL_NOTIFICATION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MODEMOPEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
	extern  Boolean 
	       	_pascal ModemOpen(Handle driver,
				  SerialPortNum port,
				  StreamOpenFlags flags,
				  word inBuffSize,
				  word outBuffSize,
				  word timeout);

CALLED BY:	GLOBAL

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global MODEMOPEN:far
MODEMOPEN	proc	far	driver:hptr, port:SerialPortNum,
				flags:word, inBufSize:word,
				outBufSize:word, timeout:word
	uses	si,di
	.enter

	push	bp
	mov	ax, ss:flags			; al = StreamOpenFlags
	mov	bx, ss:port
	mov	cx, ss:inBufSize
	mov	dx, ss:outBufSize
	mov	si, ss:driver
	mov	bp, ss:timeout
	mov	di, DR_MODEM_OPEN
	call	CallModem		; returns carry
	pop	bp

	mov	ax, 0
	sbb	ax, ax			; -1 if carry set

	.leave
	ret
MODEMOPEN	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MODEMCLOSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	extern void
		_pascal ModemClose(SerialPortNum port,
				   StreamLingerMode linger);

CALLED BY:	EXTERNAL

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global MODEMCLOSE:far
MODEMCLOSE	proc	far
	C_GetTwoWordArgs	bx, ax, cx, dx	; bx <- port, ax <- linger

	push	di
	mov	di, DR_MODEM_CLOSE
	call	CallModem
	pop	di

	ret
MODEMCLOSE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MODEMDIAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	extern Boolean
		_pascal ModemDial(SerialPortNum port, word strLen,
				  const char *dialStr,
				  ModemResultCode *result);

CALLED BY:	EXTERNAL

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global MODEMDIAL:far
MODEMDIAL	proc	far	port:SerialPortNum, strLen:word,
				dialStr:fptr.char, result:fptr.ModemResultCode
	uses	di
	.enter


	mov	bx, ss:port
	movdw	cxdx, ss:dialStr
	mov	ax, ss:strLen
	mov	di, DR_MODEM_DIAL
	call	CallModem		; ax = result

	;
	; Work around a bug in the original modem driver that returns
	; carry clear (success) on MRC_BLACKLISTED and MRC_DELAYED
	;
	pushf
	cmp	ax, MRC_BLACKLISTED
	je	returnFail
	cmp	ax, MRC_DELAYED
	je	returnFail
	popf
return:


	les	di, ss:result
	call	ReturnErrorAndCode

	.leave
	ret

returnFail:
	popf					; throw away old
	stc					; set failure
	jmp	return

MODEMDIAL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MODEMINITMODEM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	extern Boolean
		_pascal ModemInitModem(SerialPortNum port, word strLen,
					const char *initStr,
					ModemResultCode *result);

CALLED BY:	EXTERNAL

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global MODEMINITMODEM:far
MODEMINITMODEM	proc	far	port:SerialPortNum, strLen:word,
				initStr:fptr.char,
				result:fptr.ModemResultCode
	uses	di
	.enter

	mov	bx, ss:port
	movdw	cxdx, ss:initStr
	mov	ax, ss:strLen

	mov	di, DR_MODEM_INIT_MODEM
	call	CallModem		; ax = result

	les	di, ss:result
	call	ReturnErrorAndCode

	.leave
	ret
MODEMINITMODEM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MODEMAUTOANSWER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	extern Boolean
		_pascal ModemAutoAnswer(SerialPortNum port, word numRings,
					ModemResultCode *result);

CALLED BY:	EXTERNAL

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global MODEMAUTOANSWER:far
MODEMAUTOANSWER	proc	far	port:SerialPortNum, numRings:word,
				result:fptr.ModemResultCode
	uses	di
	.enter

	mov	bx, ss:port
	mov	ax, ss:numRings

	mov	di, DR_MODEM_AUTO_ANSWER
	call	CallModem		; ax = result


	les	di, ss:result
	call	ReturnErrorAndCode

	.leave
	ret
MODEMAUTOANSWER	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	MODEMANSERCALL, MODEMHANGUP, MODEMRESET, MODEMFACTORYRESET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

extern Boolean
	_pascal XXX(SerialPortNum port, ModemResultCode *result);

CALLED BY:	GLOBAL

PSEUDO CODE/STRATEGY:
		Set up a which driver function to call, then jump to
		common routine that loads args, calls, & returns.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global MODEMANSWERCALL:far

MODEMANSWERCALL		proc	far
	mov	cx, DR_MODEM_ANSWER_CALL
	jmp	CallWithPortReturnStatus


MODEMANSWERCALL		endp

global MODEMHANGUP:far
MODEMHANGUP		proc	far
	mov	cx, DR_MODEM_HANGUP
	jmp	CallWithPortReturnStatus
MODEMHANGUP		endp

global MODEMRESET:far
MODEMRESET		proc	far
	mov	cx, DR_MODEM_RESET
	jmp	CallWithPortReturnStatus
MODEMRESET		endp

global MODEMFACTORYRESET:far
MODEMFACTORYRESET		proc	far
	mov	cx, DR_MODEM_FACTORY_RESET
	REAL_FALL_THRU	CallWithPortReturnStatus
MODEMFACTORYRESET		endp

SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallWithPortReturnStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common fall-thru routine that takes a port number and driver
		routine, calls driver, returns success/fail and result
		code.

CALLED BY:	
PASS:		cx	= ModemDriverFunction
		on stack:
			port
			return code address
			return address

RETURN:		ax	= Boolean TRUE if carry set (means error),
		return code supplied
DESTROYED:	es, bx, cx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CallWithPortReturnStatusFrame	struct
	CWPRSF_savedBP		word
	CWPRSF_savedDI		word
	CWPRSF_retAddr		fptr.far
	CWPRSF_argStart		label	word
	CWPRSF_returnCode	fptr.ModemResultCode
	CWPRSF_port		SerialPortNum
	CWPRSF_argEnd		label	word
CallWithPortReturnStatusFrame	ends

CallWithPortReturnStatus	proc	far

	push	di
	push	bp

	mov	bp, sp
	mov	bx, ss:[bp].CWPRSF_port		; bx = port #

	mov	di, cx				; di = ModemFunction

	call	CallModem			; carry, ax returned

	les	di, ss:[bp].CWPRSF_returnCode

	call	ReturnErrorAndCode

	pop	bp
	pop	di

	retf	(offset CWPRSF_argEnd - offset CWPRSF_argStart)
CallWithPortReturnStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnErrorAndCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up to return  success/failure & a ModemResultCode
		to a C caller.

CALLED BY:	INTERNAL
PASS:		carry	= set to return TRUE
		ax	= ModemResultCode
		es:di	= location to store ModemResultCode

RETURN:		ax	= TRUE if carry set, FALSE if not.
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReturnErrorAndCode	proc	near
	mov	es:[di], ax			; fill in ModemResultCode
	mov	ax, 0
	sbb	ax, ax				; AX = -1 if carry set
	ret
ReturnErrorAndCode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallModem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the modem driver's strategy routine

CALLED BY:	INTERNAL  every stub
PASS:		di	= ModemFunction
RETURN:		whatever driver returns
DESTROYED:	es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallModem	proc	near
	push	bx
	mov	bx, handle dgroup
	call	MemDerefES
	pop	bx
	call	es:[modemStrategy]
	ret
CallModem	endp



