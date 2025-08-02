COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2023 -- All Rights Reserved

PROJECT:	Host Interface Library
FILE:		hostif.asm

AUTHOR:		Falk Rehwagen, Dec 21, 2023

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	fr	12/21/23	Initial revision

DESCRIPTION:
	

	$Id: hostif.asm,v 1.1 97/04/05 01:06:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include ec.def
include heap.def
include geode.def
include resource.def
include library.def
include ec.def
include vm.def
include dbase.def
include file.def
include gcnlist.def

include object.def
include graphics.def
include thread.def
include gstring.def
include Objects/inputC.def

include Objects/winC.def

include Internal/interrup.def
include Internal/im.def


DefLib hostif.def

HOST_API_INTERRUPT 	equ 	0xA0


HostIfProcessClass	class	ProcessClass

MSG_HOSTIF_DETECT		message

MSG_HOSTIF_PROCESS_EVENTS	message

HostIfProcessClass	endc

Resident	segment	resource

HostIfProcessClass	mask CLASSF_NEVER_SAVED


COMMENT @----------------------------------------------------------------------

FUNCTION:	HostIfInterrupt

DESCRIPTION:	Host interface callback service routine.

CALLED BY:	INT A0h (HOST_API_INTERRUPT)

PASS:
	none

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	4/6/25		Initial version

------------------------------------------------------------------------------@
HostIfInterrupt	proc	far

	pushf

	push	ax, bx, cx, dx, si, di, bp, ds, es
	call	SysEnterInterrupt		; disable context switching
	cld					;clear direction flag
	INT_ON

EC <	call	ECCheckStack						>

	segmov	cx, cs
	call	MemSegmentToHandle	;cx = handle

	mov	bx, cx
	call	MemOwner
	;mov_trash	ax, bx
	mov	ax, MSG_HOSTIF_PROCESS_EVENTS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	call	SysExitInterrupt
	pop	ax, bx, cx, dx, si, di, bp, ds, es
	popf
	iret

HostIfInterrupt	endp


Resident	ends

Code	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfProcDetect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signs up for the DHCP GCN list.

CALLED BY:	MSG_META_ATTACH

PASS:		*ds:si	= EtherProcessClass object
		ds:di	= EtherProcessClass instance data
		ds:bx	= EtherProcessClass object (same as *ds:si)
		es 	= segment of EtherProcessClass
		ax	= message #
RETURN:		ax - interface version, 0 mean no host interface found
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/03/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostIfProcDetect	method dynamic HostIfProcessClass, 
					MSG_HOSTIF_DETECT
	.enter

	mov	ax, HIF_API_CHECK
	call	HostIfCall

	cmp	ax, HIF_OK
	jne	failed
	cmp	si, {word} cs:baseboxID
	jne	failed
	cmp	bx, {word} cs:baseboxID[2]
	jne	failed
	cmp	cx, {word} cs:baseboxID[4]
	jne	failed
	cmp	dx, {word} cs:baseboxID[6]
	jne	failed

	mov	ax, di
done:
	.leave
	ret

failed:
	mov	ax, 0
	jmp	done

HostIfProcDetect	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfProcEventProcess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signs up for the DHCP GCN list.

CALLED BY:	MSG_META_ATTACH

PASS:		*ds:si	= EtherProcessClass object
		ds:di	= EtherProcessClass instance data
		ds:bx	= EtherProcessClass object (same as *ds:si)
		es 	= segment of EtherProcessClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/03/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostIfProcEventProcess	method dynamic HostIfProcessClass, 
					MSG_HOSTIF_PROCESS_EVENTS
	.enter

	;
	; process all host event
	;
eventLoop:
	mov	ax, HIF_GET_EVENT
	call	HostIfCall

	cmp	ax, HIF_NOT_FOUND
	je	done

	; Record the message
	mov	ax, MSG_META_NOTIFY
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_HOST_DISPLAY_SIZE_CHANGE
	mov	di, mask MF_RECORD
	call	ObjMessage

	; Send it to the GCN list
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_HOST_NOTIFICATIONS
	mov	cx, di		; event handle
	clr	dx, bp		; no additional block sent
				; not set status flag
	call	GCNListSend

	jmp	eventLoop
done:

	.leave
	ret
HostIfProcEventProcess	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signs up for the DHCP GCN list.

CALLED BY:	MSG_META_ATTACH

PASS:		*ds:si	= EtherProcessClass object
		ds:di	= EtherProcessClass instance data
		ds:bx	= EtherProcessClass object (same as *ds:si)
		es 	= segment of EtherProcessClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/03/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostIfAttach	method dynamic HostIfProcessClass, 
					MSG_META_ATTACH
	.enter

	; Commenting this out cuz it causes a crash. There is no default
	; handler for this message, so we won't worry about it.
		mov	di, offset HostIfProcessClass
		call	ObjCallSuperNoLock

	; 
	; Setup interrupt handle
	;
		mov	ax, HOST_API_INTERRUPT
		mov	bx, segment HostIfInterrupt		
		mov	cx, offset HostIfInterrupt	; bx:cx <- fptr of my handler
		call	SysCatchInterrupt

	;
	; Register event interrupt
	;
		mov	ax, HIF_SET_EVENT_INTERRUPT
		call	HostIfCall

	.leave
	ret
HostIfAttach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove self from GCN list

CALLED BY:	MSG_META_DETACH

PASS:		*ds:si	= EtherProcessClass object
		ds:di	= EtherProcessClass instance data
		ds:bx	= EtherProcessClass object (same as *ds:si)
		es 	= segment of EtherProcessClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/03/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostIfDetach	method dynamic HostIfProcessClass, 
					MSG_META_DETACH
	uses	ax, bx, cx, dx
	.enter

	;mov	cx, ss:[0].TPD_threadHandle
	;clr	dx
	;mov	bx, MANUFACTURER_ID_GEOWORKS
	;mov	cx, GCNSLT_TCPIP_STATUS_NOTIFICATIONS
	;call	GCNListRemove

	.leave
	mov	di, offset HostIfProcessClass
	call	ObjCallSuperNoLock

	ret
HostIfDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for the kernel's benefit

CALLED BY:	kernel
PASS:		di	= LibraryCallTypes
		cx	= handle of client, if LCT_NEW_CLIENT or LCT_CLIENT_EXIT
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostIfEntry	proc	far
		uses	ds, si, cx, dx, ax, bp, es, bx
		.enter
		cmp	di, LCT_ATTACH
		jne	checkDetach

		segmov	es, dgroup, cx	; es, cx <- dgroup
	;
	; Detect host interface
	;
		call	HostIfDetect
		tst	ax
		jz	done	; 0 if not host API

	; 
	; Setup interrupt handle
	;
		mov	ax, HOST_API_INTERRUPT
		mov	bx, segment HostIfInterrupt		
		mov	cx, offset HostIfInterrupt	; bx:cx <- fptr of my handler
		call	SysCatchInterrupt

	;
	; Register event interrupt
	;
		mov	ax, HIF_SET_EVENT_INTERRUPT
		call	HostIfCall

done:
		.leave
		clc		; no errors
		ret
checkDetach:
		cmp	di, LCT_DETACH
		jne	done
	;
	; Unregister event interrupt
	;

	; 
	; Unset interrupt handler
	;
		call	SysResetInterrupt

		jmp	done

HostIfEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfDetect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if host side API is available and in case it is
		what version is supported.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		ax - interface version, 0 mean no host interface found
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	12/21/23   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

.ioenable

	SetGeosConvention

baseboxID	byte 	"XOBESAB2"

HostIfDetect	proc	far

	;	
	; Check host call if SSL interface is available
	;
		uses	bx, cx, dx, si, di

		.enter
		segmov	cx, cs
		call	MemSegmentToHandle	;cx = handle

		mov	bx, cx
		call	MemOwner
		;mov_trash	ax, bx
		mov	ax, MSG_HOSTIF_DETECT
		mov	di, mask MF_CALL
		call	ObjMessage

		.leave
		ret

HostIfDetect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfDetect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if host side API is available and in case it is
		what version is supported.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		ax - interface version, 0 mean no host interface found
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	12/21/23   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HOSTIFDETECT	proc	far
		GOTO	HostIfDetect
HOSTIFDETECT	endp

HostIfCall	proc	far

		push	bp
		mov	bp, dx

		mov	dx, 38FFh

		; interrupts off
		INT_OFF

		; ping/pong request/response record exchange
		push	ax
		in	ax, dx
		pop	ax

		; send request data
		out	dx, ax
		mov	ax, si
		out	dx, ax
		mov	ax, bx
		out	dx, ax
		mov	ax, cx
		out	dx, ax
		mov	ax, bp
		out	dx, ax
		mov	ax, di
		out	dx, ax

		; receive response data
		in	ax, dx		; di
		mov	di, ax 
		in	ax, dx		; dx
		mov	bp, ax
		in	ax, dx		; cx
		mov	cx, ax
		in	ax, dx		; bx
		mov	bx, ax
		in	ax, dx		; si
		mov	si, ax
		in	ax, dx

		; interrupts on
		INT_ON

		mov	dx, bp
		pop	bp

		.leave
		ret
HostIfCall	endp

HOSTIFCALL		proc	far	func:word, 
					data1:dword, 
					data2:dword, 
					data3:word	
		uses	di, si, cx, bx

		.enter
		
		mov	di, data3
		mov	dx, data2.high
		mov	cx, data2.low
		mov	bx, data1.high
		mov	si, data1.low

		mov	ax, func
		
		int	HOST_API_INTERRUPT

		.leave
		
		ret

HOSTIFCALL		endp


HostIfAsyncCallbackData	struct
	; input
	HIACD_callback		fptr
	HIACD_semaphore		word
	
	; output
	HIACD_result		word
HostIfAsyncCallbackData	ends

HostIfCallbackHandler	proc	far

EC <		call	ECCheckStack						>

		mov	ds:[si].HIACD_result, ax
		inc	ds:[si].HIACD_semaphore
			
		ret
			
HostIfCallbackHandler	endp


HostIfCallAsync	proc	far

callbackData	local	HostIfAsyncCallbackData

		.enter
		
		; init  callback structure
		mov	callbackData.HIACD_callback.segment, cs
		mov	callbackData.HIACD_callback.offset, offset cs:HostIfCallbackHandler
		mov	callbackData.HIACD_semaphore, 0
		
		; ss:bp beeing passed as point to callback results structure
		push	bp
		lea	bp, callbackData
		
		int	HOST_API_INTERRUPT
		pop	bp

		; for doe semaphore to get a trigger
waitHere:
                cmp     callbackData.HIACD_semaphore, 0
                je      waitHere

		mov	ax, callbackData.HIACD_result

		; wait for result available
		.leave
		ret

HostIfCallAsync	endp

HOSTIFCALLASYNC		proc	far	func:word, 
					data1:dword, 
					data2:dword, 
					data3:word	
		uses	di, si, cx, bx

		.enter
		
		mov	di, data3
		mov	dx, data2.high
		mov	cx, data2.low
		mov	bx, data1.high
		mov	si, data1.low

		mov	ax, func
		
		int	HOST_API_INTERRUPT

		; wait for result available

		.leave
		
		ret

HOSTIFCALLASYNC		endp

	SetDefaultConvention

Code	ends


