COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nwPrint.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

DESCRIPTION:
	NetWare printing functions	

	$Id: nwPrint.asm,v 1.1 97/04/18 11:48:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



NetWareResidentCode	segment	resource	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWarePrint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Printing function

CALLED BY:	NetWareStrategy

PASS:		al - NetWarePrintFunction to call

RETURN:		returned from called proc

DESTROYED:	es,di 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWarePrint	proc near
	call	NetWareRealPrint
	ret
NetWarePrint	endp

NetWareResidentCode	ends

NetWareCommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareRealPrint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle printing functions -- keeping them in this code
		segment. 

CALLED BY:	NetWarePrint

PASS:		al - NetWarePrintFunction to call

RETURN:		values returned from called procedure

DESTROYED:	es,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareRealPrint	proc far
	.enter
	clr	ah
	mov_tr	di, ax

EC <	cmp	di, NetPrintFunction	>
EC <	ERROR_AE NW_ERROR_INVALID_DRIVER_FUNCTION			>

	call	cs:[netWarePrintCalls][di]
	.leave
	ret
NetWareRealPrint	endp

netWarePrintCalls	nptr	\
	offset	NWPEnumPrintQueues,
	offset	NWPStartCapture,
	offset	NWPCancelCapture,
	offset	NWPEndCapture,
	offset	NWPFlushCapture,
	offset  NWPGetCaptureQueue,
	offset	NWPSetBanner,
	offset	NWPGetBanner,
	offset	NWPSetBannerStatus,
	offset	NWPGetBannerStatus,
	offset	NWPSetTimeout,
	offset	NWPGetTimeout

.assert (size netWarePrintCalls eq NetPrintFunction)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWPEnumPrintQueues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate all the print queues available on the
		network 

CALLED BY:

PASS:		ds - segment of NetEnumCallbackData

RETURN:		nothing 

DESTROYED:	es 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
wildcard	char	'*',0

NWPEnumPrintQueues	proc near
	.enter

	;
	; Allocate the request and reply buffers.  For the request
	; buffer, we need to allocate enough space to hold a name as
	; well.  The name we pass is just "*".
	;

	mov	bx, size NReqBuf_ScanBinderyObject + size wildcard
	mov	cx, size NRepBuf_ScanBinderyObject
	call	NetWareAllocRRBuffers		; es - segment of RR
						; buffers 
	;
	; Fill in the CallbackData fields
	;

	mov	ds:[NECD_curElement].segment, es
	lea	ax, es:[di].NREPBUF_SBO_objectName
	mov	ds:[NECD_curElement].offset, ax

	;
	; Fill in fields of request buffer (the name field fits in a word)
	;
	movdw	es:[si].NREQBUF_SBO_lastObjectID, -1
		CheckHack <size wildcard eq 2>		
	mov	ax, {word} cs:[wildcard]
	mov	{word} es:[si].NREQBUF_SBO_objectName, ax

	mov	es:[si].NREQBUF_SBO_objectType, NOT_PRINT_QUEUE
	mov	es:[si].NREQBUF_SBO_objectNameLen, size wildcard-1

startLoop:

	;
	; Make the call
	;

	mov	ax, NFC_SCAN_BINDERY_OBJECT
	call	NetWareCallFunctionRR

	;
	; If al nonzero, done (XXX: Figure out which errors are valid)
	;

	tst	al
	jnz	done

	;
	; Call the callback routine to add our data to the caller's
	; buffer. 
	;

	call	NetEnumCallback

	;
	; Copy the current object ID to the "last" object ID, so we
	; can get the next object
	;

	movdw	es:[si].NREQBUF_SBO_lastObjectID, \
			es:[di].NREPBUF_SBO_objectID, ax
	jmp	startLoop

done:
	;
	; Free the request / reply buffers
	;

	mov	bx, es:[NRR_handle]
	call	MemFree

	.leave
	ret
NWPEnumPrintQueues	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWPStartCapture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redirect a printer port to the specified queue

CALLED BY:	NPF_START_CAPTURE

PASS:		bx - ParallelPortNum
		cx:dx - name of print queue (asciiZ)

RETURN:		carry set if error 

DESTROYED:	ax,es,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWPStartCapture	proc near
		uses	bx,cx,dx,si,ds
		.enter

	;
	; Get object ID from name
	;
		mov	ds, cx
		mov	si, dx
		mov	ax, NOT_PRINT_QUEUE
		call	NetWareGetBinderyObjectID	; cx:dx - id
		jc	done

	;
	; Now, redirect the parallel port to this ID.  Our
	; ParallelPortNum etype goes from 0 in steps of 2, Novell's
	; goes from zero in steps of one, so just shift right
	;
		mov	al, bl
		shr	al			; novell's parallel port #

		mov	bx, cx
		mov	cx, dx			; bx:cx - queue id
		mov	dh, al			; dh - parallel port #

		mov	ax, NFC_SET_CAPTURE_PRINT_QUEUE
		call	NetWareCallFunctionAX
		jc	done


	;
	; Fetch the default capture flags, so that we can copy the
	; banner settings for this port.  I hope this works -- nothing
	; else has!
	;
		call	SetBannerFlags
		

		mov	ax, NFC_START_SPECIFIC_LPT_CAPTURE
		call	NetWareCallFunctionAX

	;
	; Set the banner user name.  We shouldn't need to do this, but
	; the name of the last logged-in user seems to stick around,
	; so better to be safe...
	;

		sub	sp, size NetWareBinderyObjectNameZ
		mov	si, sp
		segmov	ds, ss
		call	NetWareUserGetLoginName
		segmov	es, ss
		mov	bx, si
		mov	ax, NFC_SET_BANNER_USER_NAME
		call	NetWareCallFunctionAX

		add	sp, size NetWareBinderyObjectNameZ
	
	
done:
		.leave
		ret
NWPStartCapture	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBannerFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy the banner flags and banner text from the default
		set of flags to the specific ones for this port.


CALLED BY:	NWPStartCapture

PASS:		dh  - LPT port of specific capture

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/ 4/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBannerFlags	proc near
		uses	ax,bx,cx,dx,di,si,ds,es
		.enter

	;
	; First, fetch the DEFAULT flags
	;
		
		call	GetDefaultCaptureFlags
		push	es, bx

	;
	; Now, get the ones for this queue
	;
		
		mov	bx, size NRepBuf_GetCaptureFlags
		clr	cx
		call	NetWareAllocRRBuffers	; es:si - buffer
		mov	bx, si
		mov	cx, size NRepBuf_GetCaptureFlags
		mov	ax, NFC_GET_SPECIFIC_CAPTURE_FLAGS
		call	NetWareCallFunctionAX

	;
	; Copy the default flags
	;
		pop	ds, si
		mov	al, ds:[si].NREPBUF_GCF_flags
		mov	es:[bx].NREPBUF_GCF_flags, al


	;
	; Copy the timeout value
	;
		mov	ax, ds:[si].NREPBUF_GCF_flushTimeoutCount
		mov	es:[bx].NREPBUF_GCF_flushTimeoutCount, ax
		
	;
	; Copy the banner text
	;
		
		lea	si, ds:[si].NREPBUF_GCF_bannerText
		lea	di, es:[bx].NREPBUF_GCF_bannerText
		mov	cx, size NREPBUF_GCF_bannerText
		rep	movsb


	;
	; Set the flags
	;
		mov	cx, size NRepBuf_GetCaptureFlags
		mov	ax, NFC_SET_SPECIFIC_CAPTURE_FLAGS
		call	NetWareCallFunctionAX

	;
	; Free both buffers
	;
		
		call	NetWareFreeRRBuffers
		segmov	es, ds
		call	NetWareFreeRRBuffers
		
		


		.leave
		ret
SetBannerFlags	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWPCancelCapture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWPCancelCapture	proc near
		uses	ax,bx,cx,dx,di,si,bp
		.enter

		.leave
		ret
NWPCancelCapture	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWPEndCapture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End capture of the specified LPT port

CALLED BY:

PASS:		bx - ParallelPortNum

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWPEndCapture	proc near
		uses	dx
		.enter
		mov	dh, bl
		shr	dh			; convert to netw
		mov	ax, NFC_END_SPECIFIC_LPT_CAPTURE
		call	NetWareCallFunctionAX
		.leave
		ret
NWPEndCapture	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWPFlushCapture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWPFlushCapture	proc near
	.enter

	.leave
	ret
NWPFlushCapture	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWPGetCaptureQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the name of the queue to which the specified
		port is being captured

CALLED BY:	NPF_GET_CAPTURE_QUEUE

PASS:		bx - ParallelPortNum
		ds:si - buffer to hold queue name

RETURN:		if error
			carry set
		else
			carry clear
			ds:si - filled in

DESTROYED:	es,di 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWPGetCaptureQueue	proc near
	uses	bx, cx, dx, si, bp

	.enter

	;
	; Initialize the return buffer to a null string
	;

	mov	{byte} ds:[si], 0

	mov	bp, si			; ds:bp - dest buffer

	mov	dh, bl
	shr	dh			; 0-2 

	;
	; Allocate a reply buffer.  There's no request buffer, but
	; NetWareAllocRRBuffers doesn't know that...
	;

	mov	bx, size NRepBuf_GetCaptureFlags
	clr	cx
	call	NetWareAllocRRBuffers		; es:si - REPLY buffer	

	;
	; Get the capture flags, and load the print queue ID into
	; dx:ax (high word, Novell-style, in DX)
	;
	mov	bx, si
	mov	cx, size NRepBuf_GetCaptureFlags
	mov	ax, NFC_GET_SPECIFIC_CAPTURE_FLAGS
	call	NetWareCallFunctionAX

	;
	; See if capturing is turned ON, and if so, get the queue ID
	;

	mov	cl, es:[bx].NREPBUF_GCF_lptCaptureFlag
	movdw	axdx, es:[bx].NREPBUF_GCF_printQueueID
	call	NetWareFreeRRBuffers

	;
	; Carry flag is still valid from function call, so check it now
	;

	jc	done

	; Hack for ICLAS -- ICLAS sets the capture queue without
	; actually turning capture ON, and they expect us to work with
	; that!  Bozo-rama!
		
;;	tst	cl				; clears carry
;;	jz	done

	mov	si, bp				; ds:si - dest buffer
						; for name
	call	NetWareGetBinderyObjectName
done:
	.leave
	ret
NWPGetCaptureQueue	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWPGetBanner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the banner text

CALLED BY:	NetWareRealPrint

PASS:		ds:si - buffer to fill

RETURN:		nothing 

DESTROYED:	es,di 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWPGetBanner	proc near
	uses	ds, si, bx
	.enter

	push	ds, si			; caller's buffer

	call	GetDefaultCaptureFlags	; es:bx - NRepBuf_GetCaptureFlags

	lea	si, es:[bx].NREPBUF_GCF_bannerText
	segmov	ds, es

	pop	es, di

	
	call	NetWareCopyNTString

	segmov	es, ds
	call	NetWareFreeRRBuffers
	

	.leave
	ret
NWPGetBanner	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWPSetBanner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the banner text

CALLED BY:	NetWareRealPrint

PASS:		ds:si - banner

RETURN:		nothing 

DESTROYED:	es 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWPSetBanner	proc near

	uses	bx

	.enter

	call	GetDefaultCaptureFlags	; es:bx - NRepBuf_GetCaptureFlags

	lea	di, es:[bx].NREPBUF_GCF_bannerText
	call	NetWareCopyNTString

	call	SetDefaultCaptureFlags

	.leave
	ret
NWPSetBanner	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWPSetBannerStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the default banner status

CALLED BY:	NetWareRealPrint

PASS:		bx - TRUE/FALSE

RETURN:		nothing 

DESTROYED:	es 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWPSetBannerStatus	proc near
		uses	bx, cx
		.enter

		mov	cx, bx		; TRUE/FALSE

		call	GetDefaultCaptureFlags

		jcxz	resetFlag
		ornf	es:[bx].NREPBUF_GCF_flags, mask NWPF_BANNER
		jmp	set

resetFlag:
		andnf	es:[bx].NREPBUF_GCF_flags, not mask NWPF_BANNER

set:

		call	SetDefaultCaptureFlags

		.leave
		ret
NWPSetBannerStatus	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWPGetBannerStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the default banner status

CALLED BY:	NetWareRealPrint

PASS:		nothing 

RETURN:		bx - TRUE/FALSE 

DESTROYED:	es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWPGetBannerStatus	proc near
		.enter

		call	GetDefaultCaptureFlags

		test	es:[bx].NREPBUF_GCF_flags, mask NWPF_BANNER
		mov	bx, 0
		jz	done
		dec	bx
done:
		call	NetWareFreeRRBuffers

		.leave
		ret
NWPGetBannerStatus	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDefaultCaptureFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate the request buffer, and fetch the flags

CALLED BY:	NWPSetBannerStatus, NWPSetBanner, NWPGetBanner

PASS:		nothing 

RETURN:		es:bx - NRepBuf_GetCaptureFlags

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 2/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDefaultCaptureFlags	proc near
		uses	ax,cx,dx,si
		.enter

		mov	bx, size NRepBuf_GetCaptureFlags
		clr	cx
		call	NetWareAllocRRBuffers	; es:si - buffer
		mov	bx, si
		mov	cx, size NRepBuf_GetCaptureFlags
		mov	ax, NFC_GET_DEFAULT_CAPTURE_FLAGS
		call	NetWareCallFunctionAX

		.leave
		ret
GetDefaultCaptureFlags	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDefaultCaptureFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the flags, the first 20 bytes or so, and then free
		the buffer

CALLED BY:	NWPSetBanner, NWPSetBannerStatus

PASS:		es:bx - NRepBuf_GetCaptureFlags

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		Only stores the first few fields of the capture flags!
		(up to NREPBUF_GCF_flushTimeoutCount).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 2/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDefaultCaptureFlags	proc near
		uses	ax

		.enter

	;
	; Only store up to NREPBUF_GCF_flushTimeoutCount (use the
	; offset of the following field as the size to store).
	;
		
		mov	cx, offset NREPBUF_GCF_flushOnDeviceClose
		mov	ax, NFC_SET_DEFAULT_CAPTURE_FLAGS
		call	NetWareCallFunctionAX

		call	NetWareFreeRRBuffers

		.leave
		ret
SetDefaultCaptureFlags	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWPSetTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the capture timeout value

CALLED BY:	NetWareRealPrint

PASS:		bx - timeout count, in seconds

RETURN:		nothing 

DESTROYED:	es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/27/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWPSetTimeout	proc near
		uses	bx,cx
		.enter

	;
	; Timeout value is in 18ths of a second
	;
		
		mov_tr	ax, bx
		mov	bx, 18
		mul	bx

	;
	; Even though it's documented as a hi-low word, it's not.
	;
		
;;		xchg	al, ah		; hi-low word
		
		call	GetDefaultCaptureFlags
		
		mov	es:[bx].NREPBUF_GCF_flushTimeoutCount, ax

		call	SetDefaultCaptureFlags

		.leave
		ret
NWPSetTimeout	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWPGetTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the timeout value

CALLED BY:	NetWareRealPrint

PASS:		nothing 

RETURN:		bx - timeout value

DESTROYED:	es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/27/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWPGetTimeout	proc near
		uses	ax,dx

		.enter

		call	GetDefaultCaptureFlags

		mov	ax, es:[bx].NREPBUF_GCF_flushTimeoutCount
		clr	dx
		mov	bx, 18
		div	bx
		mov_tr	bx, ax

;;		xchg	bl, bh

		call	NetWareFreeRRBuffers

		.leave
		ret

NWPGetTimeout	endp



NetWareCommonCode	ends
