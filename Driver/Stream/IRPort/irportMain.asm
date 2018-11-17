COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Stream Drivers -- FileStream driver
FILE:		irportMain.asm

AUTHOR:		Jim DeFrisco, Jan 12, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/12/93		Initial revision


DESCRIPTION:
	Code to communicate with a file system via a stream interface.
		
NOTES:
		

	$Id: irportMain.asm,v 1.1 97/04/18 11:46:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	irport.def

;------------------------------------------------------------------------------
;	Driver info table
;------------------------------------------------------------------------------

Resident		segment

DriverTable	DriverInfoStruct	<
	IrportStrategy, mask DA_CHARACTER, DRIVER_TYPE_STREAM
>

public	DriverTable
Resident		ends

;------------------------------------------------------------------------------
;		       MISCELLANEOUS VARIABLES
;------------------------------------------------------------------------------
udata		segment

udata		ends

idata		segment

isdArray	IrportStrData NUM_ISD_ENTRIES dup (<>)


slotAllocSem	Semaphore <>			; protects allocation of unit

discoverySem	Semaphore <0>			; place to block waiting for
						;  discovery 
statusSem	Semaphore <0>			; place to block waiting for
						;  status

openAddr	dword			; address of printer to talk to
lptLSAP		byte			; LSAP in printer to talk to
iasIgnore	byte			; set true after first Ias response,
					;  so if get disconnect indication,
					;  while attempting to connect to
					;  IrLPT LSAP we ignore it and don't
					;  V the discoverySem
connStatus	ConnectionStatus	; IrLAP status 

idata		ends

Resident	segment	resource
DefFunction	macro	funcCode, routine
if ($-irportFunctions) ne funcCode
	ErrMessage <routine not in proper slot for funcCode>
endif
		nptr	routine
		endm

irportFunctions	label	nptr
DefFunction	DR_INIT,			IrportNull
DefFunction	DR_EXIT,			IrportNull
DefFunction	DR_SUSPEND,			IrportNull
DefFunction	DR_UNSUSPEND,			IrportNull
DefFunction	DR_STREAM_GET_DEVICE_MAP,	IrportCallStreamDriver
DefFunction	DR_STREAM_OPEN,			IrportOpen
DefFunction	DR_STREAM_CLOSE,		IrportClose
DefFunction	DR_STREAM_SET_NOTIFY,		IrportSetNotify
DefFunction	DR_STREAM_GET_ERROR,		IrportCallStreamDriver
DefFunction	DR_STREAM_SET_ERROR,		IrportCallStreamDriver
DefFunction	DR_STREAM_FLUSH,		IrportCallStreamDriver
DefFunction	DR_STREAM_SET_THRESHOLD,	IrportCallStreamDriver
DefFunction	DR_STREAM_READ,			IrportRead
DefFunction	DR_STREAM_READ_BYTE,		IrportReadByte
DefFunction	DR_STREAM_WRITE,		IrportWrite
DefFunction	DR_STREAM_WRITE_BYTE,		IrportWriteByte
DefFunction	DR_STREAM_QUERY,		IrportCallStreamDriver

IrportGetDgroupDS proc	near
		push	bx
		mov	bx, handle dgroup
		call	MemDerefDS		; (flags preserved)
		pop	bx
		ret
IrportGetDgroupDS endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for all irport-driver functions

CALLED BY:	GLOBAL
PASS:		di	= routine number
		bx	= open port number (usually)
RETURN:		depends on function, but an ever-present possibility is
		carry set with AX = STREAM_CLOSING or STREAM_CLOSED
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrportStrategy proc	far	
		uses es, ds
		.enter
		HandleFarEscape irport, exit
EC <		cmp	di, StreamFunction				>
EC <		ERROR_AE	INVALID_FUNCTION			>
		segmov	es, ds		; In case segment passed in DS

		call	IrportGetDgroupDS

		cmp	di, DR_STREAM_OPEN
		jbe	notYetOpen
		cmp	ds:[isdArray][bx].ISD_stream, -1
		je	portNotOpen
notYetOpen:
		call	cs:irportFunctions[di]
exit:
		.leave
		ret
portNotOpen:
		mov	ax, STREAM_CLOSED
		stc
		jmp	exit
IrportStrategy endp

global	IrportStrategy:far


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init function, does nothing for non-hardware

CALLED BY:	DR_INIT, DR_EXIT (IrportStrategy)
PASS:		ds	= dgroup
RETURN:		Carry clear if we're happy
DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrportNull	proc	near
		clc
		ret
IrportNull	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open one of the irport ports

CALLED BY:	DR_STREAM_OPEN (IrportStrategy)
PASS:		bx	= file handle of created/opened file
		dx	= total size of output buffer
		ds	= dgroup
RETURN:		bx	= unit number, to use with subsequent calls
		carry set on error
			ax	= StreamError
DESTROYED:	ax, dx, di, bp

PSEUDO CODE/STRATEGY:
		P(slotAllocSem)
		look for slot
		set openAddr=-1
		request discovery
		P(discoverySem)
		<discovery callback:
			lock down passed block
			look for things with PRINTER bit set
			compare nickname
			if match, set openAddr to device addr
			unlock nickname block
			V(discoverySem)
		>
		if openAddr == -1, unregister client & return error
		else register IAS client and unregister discovery client
		fetch lsap for IrLPT object
		register ANY_LSAP client
		connect that to lsap
		P(discoverySem)
		<connect callback:
			if connect confirm:
				free connect data
				consult ICA_QoS to find negotiated packet size
				and record that
			if disconnect indication:
				note error
			V(discoverySem)
		>
		if error, unregister both clients and return error
		unregister IAS client
		create stream
		set reader notifier
		set reader threshold to packet size - IRLMP_HEADER_SIZE
		create HugeLMem & store handle

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrportOpen	proc	near
bufSize		local	word	push	dx
nickname	local	hptr	push	bx
unit		local	word
		uses	si, bp, cx
		.enter

		; first check to see if we can accomodate a new stream

		PSem	ds, slotAllocSem, TRASH_AX	; avoid collisions
		clr	si				; start at first one
tryNextSlot:
		cmp	ds:[isdArray][si].ISD_stream, -1 ; check for unalloc'd
		je	haveOne
		add	si, size IrportStrData
		cmp	si, size isdArray
		jb	tryNextSlot

		; amazing at it may seem, we've allocated four slots.  
		mov	ax, STREAM_CANNOT_ALLOC
		jmp	vSem

		; OK, there is room at the inn.  Store away the file handle
		; and allocate a new stream using the stream driver.
haveOne:
		; Zero-init the Irlmp client handle, so that we know if
		; connection was ever established.
		clr	ds:[isdArray][si].ISD_client

		clr	ds:[isdArray][si].ISD_flags

		movdw	ds:[openAddr], -1		; set to invalid addr
		mov	ss:[unit], si
		
		mov	bx, ss:[nickname]
		call	IrportDiscoverPrinter
		LONG jc	error

		call	IrportGetLsap
		LONG jc	error
		
		mov	bx, ss:[unit]
		call	IrportConnect			; sets ISD_packetSize
		LONG jc	error

		mov	ds:[isdArray][bx].ISD_client, si

		push	bx

		; If the negotiated data size is larger than the requested
		; buffer size, then adjust the buffer size so that it will
		; have enough room for all the data for a packet.
		mov	si, bx				; si <- unit
		mov	ax, ss:[bufSize]		
		cmp	ax, ds:[isdArray][si].ISD_packetSize
		jae	createStream	

		mov	ax, ds:[isdArray][si].ISD_packetSize
		mov	ss:[bufSize], ax
createStream:

		call	GeodeGetProcessHandle		; bx = process handle
		clr	cx				; no fixed buffer
		mov	di, DR_STREAM_CREATE
		call	StreamStrategy			; bx = stream token
		pop	si				; si <- unit
		jc	streamError			; if error, clear out

		; No error from stream driver on creation of new stream.  Cool.
		; store away the unit number and release the semaphore.

		mov	ds:[isdArray][si].ISD_stream, bx ; store stream handle
		VSem	ds, slotAllocSem

		; Now set up a notification so that we can write out the stream
		; buffer when it gets full.  We are the reader.

		mov	ax, StreamNotifyType <1,SNE_DATA,SNM_ROUTINE>
		mov	cx, cs
		mov	dx, offset IrportSendData
		push	bp
		mov	bp, si				; pass our unit number
		mov	di, DR_STREAM_SET_NOTIFY
		call	StreamStrategy
		pop	bp

		; now that we have setup getting notified, tell the stream 
		; how often to notify us.

		mov	ax, STREAM_READ

		mov	cx, ds:[isdArray][si].ISD_packetSize

; BufSize was already adjusted for the DR_STREAM_CREATE call, so now it
; is guaranteed that ISD_packetSize <= bufSize.
;		cmp	cx, ss:[bufSize]
;		jb	setThreshold
;		mov	cx, ss:[bufSize]
;setThreshold:
							; pass packet size as
		mov	di, DR_STREAM_SET_THRESHOLD	;  threshold
		call	StreamStrategy

		; we have no error handler.

		mov	ax, StreamNotifyType <1,SNE_ERROR,SNM_NONE>
		mov	di, DR_STREAM_SET_NOTIFY
		call	StreamStrategy
		
		mov	ax, 8				; limit amount
							;  of pending data.
		mov	bx, 512				; minimum size
		mov	cx, 2048			; max size
		call	HugeLMemCreate
		jc	nukeStream
		
		mov	ds:[isdArray][si].ISD_hugelmem, bx
		mov	bx, si				; return our unit #

		clc					; no error here
done:
		.leave
		ret

streamError:
		push	ax				; save StreamError
		clr	ax
		xchg	ax, ds:[isdArray][si].ISD_client
		mov_tr	si, ax
		call	IrlmpUnregister
		pop	ax				; ax = StreamError
error:
		mov	si, ss:[unit]			; make sure si = unit,
							;  because si was
							;  trashed in places
							;  that jump to here.
		mov	ds:[isdArray][si].ISD_stream, -1; flag as free
vSem:
		VSem	ds, slotAllocSem		; release the semaphore
		stc
		jmp	done

nukeStream:
	;
	; Couldn't create the HugeLMem heap, so destroy the stream.
	;
		mov	bx, ds:[isdArray][si].ISD_stream
		mov	ax, STREAM_DISCARD
		mov	di, DR_STREAM_DESTROY
		call	StreamStrategy
	;
	; Unregister the client.
	;
		push	si
		clr	si
		xchg	si, ds:[isdArray][si].ISD_client
		call	IrlmpUnregister
		pop	si
		mov	ds:[isdArray][si].ISD_stream, -1
	;
	; And return an error.
	;
		mov	ax, STREAM_CANNOT_ALLOC
		stc
		jmp	done

IrportOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportDiscoverPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the address of the printer we're supposed to talk to.

CALLED BY:	(INTERNAL) IrportOpen
PASS:		^hbx	= nickname to search for
		ds	= dgroup
RETURN:		carry set if couldn't find the printer:
			si	= destroyed
			ax	= STREAM_NO_DEVICE
		carry clear if found it:
			si	= discovery client to be unregistered once
				  IAS client is registered
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	openAddr is changed
		discoverSem is P'd and V'd

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrportDiscoverPrinter		proc	far
		uses	cx, dx, bx
		.enter
		mov	cl, IRLMP_XID_DISCOVERY_SAP
		mov	dx, vseg IrportDiscoveryCallback
		mov	ax, offset IrportDiscoveryCallback
		call	IrlmpRegister
		jc	error
		
		mov	bl, IUTS_6_SLOT
		call	IrlmpDiscoverDevicesRequest
		
		PSem	ds, discoverySem, TRASH_AX_BX
		
		cmp	ds:[openAddr].low, -1
		jne	done				; (carry is set b/c
							;  everything's below
							;  65535)
		cmp	ds:[openAddr].high, -1
		jne	done				; (carry is set)
		
		call	IrlmpUnregister
error:
		mov	ax, STREAM_NO_DEVICE
		clc

done:
		cmc
		.leave
		ret
IrportDiscoverPrinter endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportDiscoveryCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLMP callback routine to handle discovery being complete.
		Looks for the printer's nickname in the list of found
		devices and sets openAddr to the address, if it's found.

CALLED BY:	(GLOBAL)
PASS:		si	= client handle
		^hbx	= nickname desired
		*ds:ax	= array of found devices
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	discoverySem is V'd
     		openAddr is set to the address if the device is found

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrportDiscoveryCallback proc	far
		uses	ax, es, di, cx, bx, si, ds
		.enter
		cmp	di, IIC_DISCOVER_DEVICES_CONFIRMATION
		jne	done
		
		mov_tr	si, ax
		call	MemLock
		mov	es, ax
		
		push	bx
		mov	bx, cs
		mov	di, offset checkDevice
		call	ChunkArrayEnum
		pop	bx
		call	MemUnlock
		call	IrportGetDgroupDS
		jnc	wakeup
		
		movdw	ds:[openAddr], cxdx
wakeup:
		VSem	ds, discoverySem, TRASH_AX_BX
done:
		.leave
		ret

	;--------------------
	; See if the device is the one we want
	; 
	; Pass:
	; 	ds:di	= DiscoveryLog to check
	;	es:0	= nickname (char set + chars + 0s)
	; Return:
	; 	carry set if this is the one:
	; 		cxdx	= address
	; 	carry clear if it's not:
	; 		cx,dx	= destroyed
checkDevice:
	;
	; Make sure the thing's a printer.
	;
		test	{IrlmpDiscoveryServiceA}ds:[di].DL_info, 
				mask IDSA_PRINTER
		jz	noMatch
	;
	; Get the size of the discovery info, please.
	;
		mov	bx, ds:[di].DL_flags
		andnf	bx, mask DLF_INFO_SIZE
		mov	cl, offset DLF_INFO_SIZE
		shr	bx, cl
	;
	; Skip over the service hints to get to the nickname
	;
		lea	si, ds:[di].DL_info
skipHints:
		dec	bx
		inc	si
		test	{IrlmpDiscoveryServiceA}ds:[si-1], mask IDSA_EXTENDED
		jnz	skipHints
	;
	; Compare the nicknames
	;
		mov_tr	cx, bx
		push	di
		clr	di
		repe	cmpsb
		pop	si
		jne	noMatch
		cmp	{char}es:[di], 0
		jne	noMatch		; => desired name is longer
		
		movdw	cxdx, ds:[si].DL_devAddr
		stc
		retf
noMatch:
		clc
		retf
IrportDiscoveryCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportGetLsap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Talk to the printer to get the LSAP to which we need to connect

CALLED BY:	(INTERNAL) IrportOpen
PASS:		si	= discovery client to unregister
		ds	= dgroup
		ds:[openAddr] = address of printer
RETURN:		carry set on error
			cx, si	= destroyed
		carry clear if happy:
			cl	= LSAP
			si	= client to unregister after connect
DESTROYED:	ax, bx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
irlptClass	IrlmpIasNameHeader <length irlptClassName>
irlptClassName	char	'IrLPT'

irlptAttr	IrlmpIasNameHeader <length irlptAttrName>
irlptAttrName	char	'IrDA:IrLMP:LsapSel'

jeteyeAttr	IrlmpIasNameHeader <length jeteyeAttrName>
jeteyeAttrName	char	'IrDA:IrLMP:LSAPSel'

ircommClass	IrlmpIasNameHeader <length ircommClassName>
ircommClassName	char	'IrDA:IrCOMM'

IrportGetLsap	proc	near
		uses	bp
		.enter
		
		push	si
		mov	cl, IRLMP_ANY_LSAP_SEL
		mov	dx, vseg IrportIasCallback
		mov	ax, offset IrportIasCallback
		mov	bx, ds
		call	IrlmpRegister
	;
	; Unregister the discovery client now, before checking error.
	;
		pop	bx
		pushf
		xchg	bx, si
		call	IrlmpUnregister
		mov_tr	si, bx
		popf

		mov	ax, STREAM_NO_DEVICE
		LONG jc	done
		
		mov	ds:[iasIgnore], 0

		sub	sp, size IrlmpGetValueByClassRequestArgs
		mov	bp, sp
		
		movdw	ss:[bp].IGVBCRA_irlapAddr, ds:[openAddr], ax
 		mov	ss:[bp].IGVBCRA_className.segment, cs
		mov	ss:[bp].IGVBCRA_className.offset, offset irlptClass
		mov	ss:[bp].IGVBCRA_attributeName.segment, cs
		mov	ss:[bp].IGVBCRA_attributeName.offset, offset irlptAttr
		
		mov	cx, ss
		mov	dx, bp

		call	IrlmpGetValueByClassRequest
		PSem	ds, discoverySem, TRASH_AX_BX
		
		mov	cl, ds:[lptLSAP]
		cmp	cl, -1
		jne	gotLsap

	;
	; The JetEye 9580 has a misspelled attribute
	;
		mov	ds:[iasIgnore], 0
		mov	cx, ss
		mov	ss:[bp].IGVBCRA_attributeName.offset, offset jeteyeAttr
		call	IrlmpGetValueByClassRequest
		PSem	ds, discoverySem, TRASH_AX_BX
gotJetEye::
		mov	cl, ds:[lptLSAP]
		cmp	cl, -1
		jne	gotLsap

	;
	; Also check IrDA:IrCOMM class
	;
		mov	ds:[iasIgnore], 0
		mov	cx, ss
		mov	ss:[bp].IGVBCRA_className.offset, offset ircommClass
		mov	ss:[bp].IGVBCRA_attributeName.offset, offset irlptAttr
		call	IrlmpGetValueByClassRequest
		PSem	ds, discoverySem, TRASH_AX_BX

		mov	cl, ds:[lptLSAP]
		cmp	cl, -1
		jne	gotLsap

		jmp	iasFailed
gotLsap:
		add	sp, size IrlmpGetValueByClassRequestArgs
		clc
done:
		.leave
		ret

	;
	; Disconnect from IAS.  If there's an error, then
	; manually remove the client handle from irlmp
	;
iasFailed:
		add	sp, size IrlmpGetValueByClassRequestArgs
		call	IrlmpDisconnectIas
		call	IrlmpUnregister
		mov	ax, STREAM_NO_DEVICE
		stc
		jmp	done
IrportGetLsap	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportIasCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for Irlmp to give us an answer to our Ias query

CALLED BY:	(GLOBAL)
PASS:		bx	= dgroup
		si	= client
		di	= IIC_GET_VALUE_BY_CLASS_CONFIRMATION (maybe):
			dl	= IrlmpGetValueByClassReturnCode
			if success:
				*ds:ax = chunk arry of IrlmpIasIdAndValue
			if irlmp_error:
				ax 	= IrlmpError
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	discoverSem V'd
    		lptLSAP set to lsap value returned, or -1 on error

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrportIasCallback proc	far
		uses	si, di, cx, ax, bx, ds
		.enter
		cmp	di, IIC_GET_VALUE_BY_CLASS_CONFIRMATION
		jne	done
		
		push	ds
		mov	ds, bx
		mov	cl, -1
		xchg	ds:[iasIgnore], cl
		pop	ds
		tst	cl
		jnz	done

		mov	cl, -1			; assume error
		cmp	dl, IGVBCRC_SUCCESS
		jne	setLsap
		
		mov_tr	si, ax
		clr	ax
		push	cx
		call	ChunkArrayElementToPtr
		pop	cx
		jc	setLsap			; => no value
		cmp	ds:[di].IIIAV_value.IIAV_type, IIVT_INTEGER
		jne	setLsap
	;
	; Fetch the LSAP. It's only a single byte...
	;
		mov	cl, ds:[di].IIIAV_value.IIAV_value.IIVU_integer.low.low
setLsap:
		mov	ds, bx
		mov	ds:[lptLSAP], cl
		VSem	ds, discoverySem, TRASH_AX_BX
done:
		.leave
		ret
IrportIasCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to connect to the printer at the given LSAP

CALLED BY:	(INTERNAL) IrportOpen
PASS:		si	= IAS client to unregister
		cl	= LSAP to connect to
		bx	= unit number being used
RETURN:		carry set on error:
			ax	= STREAM_NO_DEVICE
			si	= destroyed
		carry clear if happy:
			ax	= destroyed
			si	= client
DESTROYED:	nothing
SIDE EFFECTS:	ISD_packetSize set for unit

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrportConnect	proc	near
		uses	bx, cx, dx, di, bp
		.enter
		push	si			; save for final disconnect

		push	cx
		
		mov	cl, IRLMP_ANY_LSAP_SEL
		mov	dx, vseg IrportCallback
		mov	ax, offset IrportCallback
		call	IrlmpRegister
		pop	cx
		mov	ax, STREAM_CANNOT_ALLOC
		jc	disconnectIas
		
		mov	ds:[isdArray][bx].ISD_stream, 0

		sub	sp, size IrlmpConnectArgs
		mov	bp, sp
		mov	ss:[bp].ICA_dataSize, 0	; no extra data, thanks
		movdw	ss:[bp].ICA_lsapID.ILI_irlapAddr, ds:[openAddr], ax
		mov	ss:[bp].ICA_lsapID.ILI_lsapSel, cl
		mov	ss:[bp].ICA_QoS.QOS_flags, mask QOSF_DEFAULT_PARAMS
		mov	cx, ss
		mov	dx, bp
		call	IrlmpConnectRequest
		add	sp, size IrlmpConnectArgs
		
		PSem	ds, discoverySem, TRASH_AX
		
		cmp	ds:[isdArray][bx].ISD_stream, 0
		clc
		jne	disconnectIas
		
		call	IrlmpUnregister
		mov	ax, STREAM_NO_DEVICE
		stc
disconnectIas:
		mov	bx, si
		pop	si
		pushf
		call	IrlmpDisconnectIas
		call	IrlmpUnregister
		popf
		mov	si, bx
		.leave
		ret
IrportConnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for the actual connection to the printer.

CALLED BY:	(GLOBAL)
PASS:		si	= client
		bx	= unit number (offset into isdArray)
		di	= indication/confirmation
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		if IIC_CONNECT_CONFIRMATION:
			if data, free it
			set ISD_stream to 1 to signal success
			set ISD_packetSize to ICA_QoS.QOS_param.ICD_dataSize -
				IRLMP_HEADER_SIZE
			V(discoverySem)
		if IIC_DISCONNECT_INDICATION:
			if data, free it
			if ISD_stream is 0
				V(discoverySem)
			else
				STREAM_SET_ERROR(PERROR_FATAL)
		if IIC_DATA_INDICATION:
			if data, free it
		if IIC_UDATA_INDICATION:
			if data, free it
		if IIC_STATUS_CONFIRMATION:
			V(statusSem)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrportCallback	proc	far
		uses	ds, si, di, es, ax, bx
		.enter
		cmp	di, IIC_STATUS_CONFIRMATION
		jne	checkConnect

		call	IrportGetDgroupDS
		mov	ds:[connStatus], cx
		VSem	ds, statusSem, TRASH_AX_BX
		jmp	done

checkConnect:
		cmp	di, IIC_CONNECT_CONFIRMATION
		jne	checkDisconnect
		
		movdw	dssi, cxdx
		call	maybeFreeData

		mov	al, ds:[si].ICA_QoS.QOS_param.ICP_dataSize
		call	IrportGetDgroupDS
		mov	ds:[isdArray][bx].ISD_stream, 1
		mov	si, 8192
convertPacketSizeLoop:
		shr	si
		shl	al
		jns	convertPacketSizeLoop
		sub	si, IRLMP_HEADER_SIZE
		mov	ds:[isdArray][bx].ISD_packetSize, si
		VSem	ds, discoverySem, TRASH_AX_BX
		jmp	done

checkDisconnect:
		cmp	di, IIC_DISCONNECT_INDICATION
		jne	checkData
		movdw	dssi, cxdx
		call	maybeFreeData
		call	IrportGetDgroupDS
		cmp	ds:[isdArray][bx].ISD_stream, 0
		jne	disconnectAfterConnected
		VSem	ds, discoverySem, TRASH_AX_BX
		jmp	done

disconnectAfterConnected:
		mov	di, bx			; di = unit number
		mov	bx, ds:[isdArray][bx].ISD_stream

		; Check first if already closed.
		cmp	bx, -1
		je	done

					; indicate error
		BitSet	ds:[isdArray][di].ISD_flags, ISDF_ERROR
		mov	cx, PERROR_FATAL
		mov	ax, STREAM_READ
		mov	di, DR_STREAM_SET_ERROR
		call	StreamStrategy
		jmp	done

checkData:
		cmp	di, IIC_DATA_INDICATION
		je	isData
		cmp	di, IIC_UDATA_INDICATION
		jne	done
isData:
		movdw	dssi, cxdx
		call	maybeFreeData
done:
		.leave
		ret

	;--------------------
	; Free the data chunk if one passed
	;
	; Pass:
	; 	ds:si	= IrlmpDataArgs/IrlmpConnectArgs
	; Return:
	; 	nothing
	; Destroyed:
	; 	ax, cx
maybeFreeData:
		
			CheckHack <IDA_dataSize eq ICA_dataSize>
			CheckHack <IDA_data eq ICA_data>

		tst	ds:[si].IDA_dataSize
		jz	doneFreeingData
		
		movdw	axcx, ds:[si].IDA_data
		call	HugeLMemFree
doneFreeingData:
		retn
IrportCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close an open irport port.

CALLED BY:	DR_STREAM_CLOSE (IrportStrategy)
PASS:		ds	- dgroup
		bx	- unit number
		ax	- STREAM_LINGER or STREAM_DISCARD
RETURN:		nothing
DESTROYED:	ax, bx
		ds, es (preserved by IrportStrategy)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrportClose	proc	near	
		uses di, si, ax, bx, cx, dx
		.enter
		
		push	ax			; save close flags
		push	bx			; save unit number
	;
	; Wait for data to transmit
	;
		cmp	ax, STREAM_DISCARD
		je	unregister		; but not if we want to discard
	;
	; Send out any remaining partial packet before waiting for data to
	; transmit.  We need to set ISDF_FLUSHING so IrportSendData will
	; send partial packet.
	;
		push	ax			; save close flags
		mov	si, bx			; si = unit number
		BitSet	ds:[isdArray][si].ISD_flags, ISDF_FLUSHING
		mov	dx, ds:[isdArray][si].ISD_stream	; dx = token
		mov	ax, si			; ax = unit number
		call	IrportSendData
		BitClr	ds:[isdArray][si].ISD_flags, ISDF_FLUSHING
		pop	ax			; ax = close flags

waitForUnacked:
		pop	si			; get unit number from stack
		push	si
		mov	si, ds:[isdArray][si].ISD_client
		tst	si
		jz	unregister		; someone else closed while
						;	we were waiting
		call	IrlmpStatusRequest
		jc	reportError		; connection is already hosed.
		PSem	ds, statusSem, TRASH_AX_BX

		test	ds:[connStatus], mask CS_UNACKED_DATA
		jz	unregister		; no more unacked data

		mov	ax, 120			; 2 secs.		
		call	TimerSleep
		jmp	waitForUnacked

reportError:
		pop	si			; si = unit number
		push	si
					; skip if error reported before
		test	ds:[isdArray][si].ISD_flags, mask ISDF_ERROR
		jnz	unregister
		mov	bx, ds:[isdArray][si].ISD_stream
		mov	cx, PERROR_FATAL
		mov	ax, STREAM_READ
		mov	di, DR_STREAM_SET_ERROR
		call	StreamStrategy

unregister:
	;
	; Destroy stream and hugelmem (destroy hugelmem first to unblock
	; anyone blocked waiting on HugeLMemAllocLock)
	;
		pop	si			; si = unit number
		clr	bx
		xchg	bx, ds:[isdArray][si].ISD_hugelmem
		tst	bx
		jz	noLMem
		call	HugeLMemDestroy
noLMem:
		mov	bx, -1			; mark stream free
		xchg	bx, ds:[isdArray][si].ISD_stream
		pop	ax			; ax = close flags
		cmp	bx, -1
		je	noStream
		mov	di, DR_STREAM_DESTROY
		call	StreamStrategy
noStream:
		clr	bx
		xchg	bx, ds:[isdArray][si].ISD_client
		tst	bx
		jz	done
		mov	si, bx
	;
	; Only unregister with Irlmp if not done already.
	;
		clr	cx
		pushdw	cxcx			; IDA_data
		push	cx			; IDA_dataOffset
		push	cx			; IDA_dataSize
		mov	cx, ss
		mov	dx, sp
		mov	bl, IDR_USER_REQUEST
		call	IrlmpDisconnectRequest
		add	sp, size IrlmpDataArgs

		call	IrlmpUnregister
done:
		.leave
		ret
IrportClose	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportSetNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a notifier for the caller. Caller may only set the
		notifier for the writing side of the stream.

CALLED BY:	DR_STREAM_SET_NOTIFY
PASS:		ax	= StreamNotifyType
		bx	= unit number (transformed to IrportPortData offset by
			  IrportStrategy).
		cx:dx	= address of handling routine, if SNM_ROUTINE;
			  destination of output if SNM_MESSAGE
		bp	= AX to pass if SNM_ROUTINE (except for SNE_DATA with
			  threshold of 1, in which case value is passed in CX);
			  method to send if SNM_MESSAGE.
RETURN:		nothing
DESTROYED:	bx (saved by IrportStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrportSetNotify proc	near
		uses	bx
		.enter

		test	ax, mask SNT_READER
		jnz	done

		; we don't do no stinkin' reads

		and	ax, not mask SNT_READER
		mov	bx, ds:[isdArray][bx].ISD_stream
		call	StreamStrategy
done:
		.leave
		ret
IrportSetNotify endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportCallStreamDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass a call on to the stream driver as the writer of the
		stream.

CALLED BY:	DR_STREAM_GET_ERROR, DR_STREAM_SET_ERROR, DR_STREAM_FLUSH,
       		DR_STREAM_SET_THRESHOLD, DR_STREAM_QUERY
PASS:		bx	= unit number (transformed to IrportPortData by 
			  IrportStrategy)
		di	= function code
RETURN:		?
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrportCallStreamDriver proc	near
		uses	bx
		.enter

		mov	ax, STREAM_WRITE
		mov	bx, ds:[isdArray][bx].ISD_stream
		call	StreamStrategy

		.leave
		ret
IrportCallStreamDriver endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read data from a port (ILLEGAL)

CALLED BY:	DR_STREAM_READ
PASS:		bx	= unit number (transformed to IrportPortData by 
			  IrportStrategy)
		ax	= STREAM_BLOCK/STREAM_NOBLOCK
		cx	= number of bytes to read
		ds:si	= buffer to which to read
RETURN:		cx	= number of bytes read
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrportRead	proc	near
EC <		ERROR	CANNOT_READ_FROM_FILESTR_STREAM			>
NEC <		stc							>
NEC <		clr	cx						>
NEC <		ret							>
IrportRead	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportReadByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a single byte from a port (ILLEGAL)

CALLED BY:	DR_STREAM_READ_BYTE
PASS:		ax	= STREAM_BLOCK/STREAM_NOBLOCK
		bx	= unit number (transformed to IrportPortData by 
			  IrportStrategy)
RETURN:		al	= byte read
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrportReadByte proc	near
EC <		ERROR	CANNOT_READ_FROM_FILESTR_STREAM			>
NEC <		stc							>
NEC <		ret							>
IrportReadByte endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a buffer to the irport port.

CALLED BY:	DR_STREAM_WRITE
PASS:		ax	= STREAM_BLOCK/STREAM_NOBLOCK
		bx	= unit number 
		cx	= number of bytes to write
		ds:si	= buffer from which to write (ds moved to es by
			  IrportStrategy)
		di	= DR_STREAM_WRITE
RETURN:		cx	= number of bytes written
DESTROYED:	bx (preserved by IrportStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrportWrite	proc	near
		uses	bx
		.enter
		mov	bx, ds:[isdArray][bx].ISD_stream
		segmov	ds, es		; ds <- buff segment for stream driver
		call	StreamStrategy

		.leave
		ret
IrportWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportWriteByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a byte to the irport port.

CALLED BY:	DR_STREAM_WRITE_BYTE
PASS:		ax	= STREAM_BLOCK/STREAM_NOBLOCK
		bx	= unit number
		cl	= byte to write
		di	= DR_STREAM_WRITE_BYTE
RETURN:		carry set if byte could not be written and STREAM_NOBLOCK
		was specified
DESTROYED:	bx (preserved by IrportStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrportWriteByte proc	near
		uses	bx
		.enter
		mov	bx, ds:[isdArray][bx].ISD_stream
		call	StreamStrategy
		.leave
		ret
IrportWriteByte endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrportSendData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The stream driver is calling to empty the buffer

CALLED BY:	EXTERNAL
		StreamDriver via a write operation
PASS:		ax	- our unit number
		dx	- virtual segment of moveable StreamData
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		while # bytes > packet size || (SS_LINGERING && # bytes > 0):
			allocate packet buffer
			read data from stream into buffer
		(if SS_LINGERING, stream driver will do the necessary wakeup 
			on the final read, so we don't have to worry)
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrportSendData		proc	far
		uses	ds, es, si, di, ax, bx, cx, dx, bp
		.enter
		call	IrportGetDgroupDS
		mov_tr	si, ax
		mov_tr	bx, dx				; bx <- stream
		mov	dx, ds:[isdArray][si].ISD_packetSize
		mov	bp, ds:[isdArray][si].ISD_hugelmem
		push	ds:[isdArray][si].ISD_flags	; ISD_flags on stack
		mov	si, ds:[isdArray][si].ISD_client
		
		call	MemLockFixedOrMovable
		mov	es, ax				; es <- stream
		
	;
	; If a block larger than twice the size of the output buffer, there
	; is a problem in receiving the notification for the second time.
	; Force the issue here by pretending we weren't notified.
	;
		andnf	es:[SD_state], not mask SS_RDATA	

	;
	; Loop reading packets, please.
	;
packetLoop:
		mov	ax, STREAM_READ
		mov	di, DR_STREAM_QUERY
		call	StreamStrategy			; ax <- bytes available
		cmp	ax, dx
		jae	readPacket

		push	bx
		mov	bx, sp
		test	ss:[bx+2], mask ISDF_FLUSHING	; ISD_flags on stack
		pop	bx
		jnz	checkPacketSize
		
		test	es:[SD_state], mask SS_LINGERING
		jz	done

checkPacketSize:		
		tst	ax
		jz	done
		
		mov_tr	dx, ax
		
readPacket:
	;
	; dx = # bytes to put in the packet
	;
		xchg	bx, bp			; bx <- hugelmem
						; bp <- stream
		mov	ax, dx			; ax <- size to alloc
		add	ax, IRLMP_HEADER_SIZE	; include room for header
		mov	cx, FOREVER_WAIT
		call	HugeLMemAllocLock	; ^lax:cx <- buffer
						; ds:di <- buffer
		xchg	bx, bp
		jc	dataSendError

		pushdw	axcx			; IDA_data
		push	dx, si
		lea	si, ds:[di+IRLMP_HEADER_SIZE]
		mov	ax, STREAM_BLOCK
		mov	cx, dx			; cx <- # bytes to read
		mov	di, DR_STREAM_READ
		call	StreamStrategy
		pop	dx, si
		
		push	bx
		mov	bx, sp
		mov	bx, ss:[bx+4]		; bx <- handle part of
						;  buffer optr
		call	HugeLMemUnlock
		pop	bx

		mov	ax, IRLMP_HEADER_SIZE
		push	ax			; IDA_dataOffset
		push	cx			; IDA_dataSize
		mov	cx, sp
		push	dx
		mov	dx, cx			; cx:dx = IrlmpDataArgs
		mov	cx, ss
		call	IrlmpDataRequest
		pop	dx
		jc	dataRequestError
		add	sp, size IrlmpDataArgs
		jmp	packetLoop
done:
		pop	ax			; remove ISD_flags
		call	MemUnlockFixedOrMovable

		.leave
		ret

dataRequestError:
		mov	bp, sp
		movdw	axcx, ss:[bp].IDA_data
		call	HugeLMemFree
		add	sp, size IrlmpDataArgs
dataSendError:
		mov	ax, STREAM_READ
		mov	di, DR_STREAM_FLUSH
		call	StreamStrategy
		jmp	done

IrportSendData		endp

Resident	ends
