COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrCOMM
FILE:		portemulatorOpen.asm

AUTHOR:		Greg Grisco, Dec  6, 1995

ROUTINES:
	Name					Description
	----					-----------
INT	PortEmulatorEstablishConnection		Discovery/IAS Query/Connect
INT	PortEmulatorSendLineSettings		Send the current line settings
INT	IrAddToIAS				Add IrCOMM object to IAS

EXT	PortEmulatorSendInitialLineSettings	Send initial line settings
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 6/95   	Initial revision


DESCRIPTION:
	Port Emulator routines called prior to opening a connection.
		

	$Id: portemulatorOpen.asm,v 1.1 97/04/18 11:46:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResidentCode		segment resource

ircommClass	IrlmpIasNameHeader <length ircommClassName>
ircommClassName	char	'IrDA:IrCOMM'

ircommAttr	IrlmpIasNameHeader <length ircommAttrName>
ircommAttrName	char	'IrDA:TinyTP:LsapSel'


ircommParameters	char	"Parameters"
paramOctetSeq		byte	ICIP_SERVICE_TYPE,1,
				(mask ICST_3_WIRE or mask ICST_9_WIRE),
				ICIP_PORT_TYPE,1,
				(mask ICPT_SERIAL or mask ICPT_PARALLEL),
				ICIP_FIXED_PORT_NAME,11,
				"GEOS IrCOMM"

ResidentCode		ends


PortEmulatorCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorDoDiscovery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the address of the device to talk to.

CALLED BY:	PortEmulatorEstablishConnection
PASS:		ds	= dgroup
RETURN:		carry set if couldn't find a device
			ax	= STREAM_NO_DEVICE
		carry clear if found it:
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	openAddr is changed

	

PSEUDO CODE/STRATEGY:

	Register the discovery callback
	Request discovery

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorDoDiscovery	proc	near
	uses	bx,cx,dx,si
attemptNum	local	word
	.enter
	;
	; Register the discovery callback
	;
	mov	cl, IRLMP_XID_DISCOVERY_SAP
	mov	dx, vseg IrCommDiscoveryCallback
	mov	ax, offset IrCommDiscoveryCallback
	call	IrlmpRegister			; si = client handle
	jc	errorNoUnregister

	clr	ss:[attemptNum]			; no retries yet
discReq:		
	mov	bl, IUTS_6_SLOT			; Discovers devices
	call	IrlmpDiscoverDevicesRequest	;   and calls the callback

	PSem	ds, discoverySem, TRASH_AX_BX

	cmp	ds:[openAddr].low, -1		; Did we not find a device?
	jne	okay				; (carry is set b/c
						;  everything's below
						;  65535)
	cmp	ds:[openAddr].high, -1		; Did we not find a device?
	jne	okay				; (carry is set)
	;
	;  The device may be busy or out of range.  We'll try again
	;  (up to 5 times before returning error)
	;
	inc	ss:[attemptNum]
	cmp	ss:[attemptNum], NUM_DISCOVERY_RETRIES
	jg	error

	call	TimerGetCount			; bx:ax = cur time in ticks
	and	ax, 0x3f			; ax = 0-63
	call	TimerSleep
	jmp	discReq

okay:
	call	IrlmpUnregister
	clc
exit:
	.leave
	ret
error:
	call	IrlmpUnregister
errorNoUnregister:
	mov	ax, STREAM_NO_DEVICE		; couldn't find a device
	stc					; signal error
	jmp	exit
PortEmulatorDoDiscovery	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommDiscoveryCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback which gets called by IrLMP when discovery is
		complete.  Searches through the device array for a
		device with the given nickname.  Sets openAddr to its
		address if found.

CALLED BY:	GLOBAL
PASS:		si	= client handle
		di	= IrlmpIndicationOrConfirmation
		^hbx	= nickname to search for
		*ds:ax	= array of found devices
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		openAddr is set to address if device is found

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommDiscoveryCallback	proc	far
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter
	;
	;  Will we ever get called with any other type of indication
	;  or confirmation?
	;
	cmp	di, IIC_DISCOVER_DEVICES_CONFIRMATION
	jne	done
		
	mov	si, ax				; *ds:si = chunk array
	mov	bx, cs
	mov	di, offset checkDevice		; bx:di = callback
	call	ChunkArrayEnum			; search the list of devices
	call	IrCommGetDGroupDS		; ds = dgroup; carry preserved
	jnc	notFound
		
	movdw	ds:[openAddr], cxdx		; save the device address
notFound:
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
if 0
;
; Why do we care if it's a computer?  This would prohibit two GEOS
; PDA's from connecting.
;
	;
	; Make sure the thing's a computer.
	;
	test	{IrlmpDiscoveryServiceA}ds:[di].DL_info, mask IDSA_COMPUTER
	jz	noMatch
endif
	;
	; Get the size of the discovery info, please.
	;
	mov	bx, ds:[di].DL_flags
	andnf	bx, mask DLF_INFO_SIZE
	mov	cl, offset DLF_INFO_SIZE
	shr	bx, cl				; bx = info size
	;
	; Skip over the service hints to get to the nickname
	;
	lea	si, ds:[di].DL_info
;skipHints:
	dec	bx
	inc	si
if 1
	;
	; The first byte of the device info should have the EXTENDED
	; bit set which signifies that we should check the second byte
	; for more information.
	;
	test	{IrlmpDiscoveryServiceA}ds:[si-1], mask IDSA_EXTENDED
	jz	noMatch
	;
	;  The second byte of the discovery info should have the
	;  IRCOMM bit set.  If it doesn't, then it's not the device we
	;  are looking for.  Move along...
	;
	test	{IrlmpDiscoveryServiceB}ds:[si], mask IDSB_IRCOMM
	jz	noMatch
endif
	movdw	cxdx, ds:[di].DL_devAddr	; we'll connect to this
	stc					; signal success
callbackDone:
	retf
noMatch:
	clc					; signal error
	jmp	callbackDone
IrCommDiscoveryCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorGetLSAP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Talk to the device and get the LSAP we need to connect
		to.

CALLED BY:	PortEmulatorEstablishConnection
PASS:		ds		= dgroup
		ds:[openAddr]	= device address
RETURN:		carry set on error
			cx, si = destroyed
			ax = STREAM_NO_DEVICE
		carry clear if ok
			cl = LSAP
			si = IAS client to disconnect and unregister 
				after connect
			ax = destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PortEmulatorGetLSAP	proc	near
	uses	bx,dx,bp,di
	.enter
		
	mov	cl, IRLMP_ANY_LSAP_SEL		; Any LSAP will do
	mov	dx, vseg PortEmulatorIASCallback
	mov	ax, offset PortEmulatorIASCallback ; ds:ax = our callback
	mov	bx, ds				; callback extra data
	call	IrlmpRegister			; si = IAS client
	mov	ax, STREAM_NO_DEVICE		; error code
	jc	done				; jump if error
		
	clr	di				; loop counter
iasQuery:
	sub	sp, size IrlmpGetValueByClassRequestArgs
	mov	bp, sp

	movdw	ss:[bp].IGVBCRA_irlapAddr, ds:[openAddr], ax
	mov	ax, segment ResidentCode
 	segmov	ss:[bp].IGVBCRA_className.segment, ax
	mov	ss:[bp].IGVBCRA_className.offset, offset ircommClass
	segmov	ss:[bp].IGVBCRA_attributeName.segment, ax
	mov	ss:[bp].IGVBCRA_attributeName.offset, offset ircommAttr

	mov	cx, ss
	mov	dx, bp				; cxdx = IGVBCR args
	mov	ds:[iasIgnore], 0
	call	IrlmpGetValueByClassRequest
	add	sp, size IrlmpGetValueByClassRequestArgs
	jc	unregister

	PSem	ds, discoverySem, TRASH_AX_BX	; block til callback done
		
	mov	cl, ds:[ircommLSAP]		; save LSAP value
	cmp	cl, -1				; LSAP found?
	jne	finishOk

	inc	di				; di = num attempts
	cmp	di, NUM_IAS_QUERY_RETRIES
	jg	iasFailed

	call	TimerGetCount			; bx:ax = time in ticks
	and	ax, 0x3f			; ax = 0-63
	call	TimerSleep
	jmp	iasQuery
finishOk:
	clc
done:
	.leave
	ret

iasFailed:					; No LSAP found
	call	IrlmpDisconnectIas		; Disconnect from peer IAS
unregister:
	call	IrlmpUnregister
	mov	ax, STREAM_NO_DEVICE
	stc
	jmp	done

PortEmulatorGetLSAP	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorIASCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to process Irlmp's answer to our IAS query

CALLED BY:	GLOBAL (Irlmp)
PASS:		bx	= dgroup
		si	= IAS client
		di	= IrlmpIndicationOrConfirmation

		if IIC_GET_VALUE_BY_CLASS_CONFIRMATION :
			dl	= IrlmpGetValueByClassReturnCode
			if IGVBCRC_SUCCESS :
				*ds:ax = chunk array of IAS entries
			else
				ax = IrlmpError

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorIASCallback	proc	far
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter
	;
	;  Is this a response to our IAS query?  I'm not sure what
	;  else it could be!
	;
	cmp	di, IIC_GET_VALUE_BY_CLASS_CONFIRMATION
	jne	done

	push	ds
	mov	ds, bx					; our dgroup
	mov	cl, -1					; we've been called
	xchg	ds:[iasIgnore], cl
	pop	ds					; *ds:ax = array
	tst	cl
	jnz	done					; already called?

	mov	cl, -1					; assume error
	cmp	dl, IGVBCRC_SUCCESS
	jne	setLsap

	clr	si
	xchg	si, ax					; *ds:si = array
	call	ChunkArrayElementToPtr			; ds:di = element
	mov	cx, -1					; assume error
	jc	setLsap					; => no value
	cmp	ds:[di].IIIAV_value.IIAV_type, IIVT_INTEGER
	jne	setLsap
	;
	; Fetch the LSAP. It's only a single byte...
	;
	mov	cl, ds:[di].IIIAV_value.IIAV_value.IIVU_integer.low.low
setLsap:
	mov	ds, bx					; ds = dgroup
	mov	ds:[ircommLSAP], cl
	VSem	ds, discoverySem, TRASH_AX_BX
done:
	.leave
	ret
PortEmulatorIASCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the IrCOMM module to initiate the connection.
		This routine is called in response to a read or write 
		command.  The connection must be established before
		any writing can occur.

CALLED BY:	PortEmulatorEstablishConnection
PASS:		cl	= LSAP to connect to
		si	= Irlmp IAS client handle to disconnect and unregister
		di	= unit index
RETURN:		carry set on error
			ax = STREAM_NO_DEVICE
		carry clear if ok
			ax = destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	The ISPD_mode is used to decide to request a 3-wire or 9-wire
	service.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorConnect	proc	near
	uses	bx,cx,dx,si,di,bp
	.enter

	call	IrCommGetDGroupDS		; ds = dgroup
	movdw	axdx, ds:[openAddr]		; axdx = device address
	;
	; Pass the service type and LSAP id in the IrlmpConnectArgs
	;
	sub	sp, size IrlmpConnectArgs
	mov	bp, sp

	movdw	ss:[bp].ICA_lsapID.ILI_irlapAddr, axdx
	mov	ax, ds:[vmFile]
	mov	ss:[bp].ICA_data.high, ax
	mov	cl, ds:[ircommLSAP]
	mov	ss:[bp].ICA_lsapID.ILI_lsapSel, cl
	mov	ss:[bp].ICA_QoS.QOS_flags, mask QOSF_DEFAULT_PARAMS

	movdw	cxdx, ssbp			; cxdx = IrlmpConnectArgs
	call	IrCommConnectRequest
	mov	cx, ax
	lahf
	add	sp, size IrlmpConnectArgs
	sahf
	mov	ax, cx

	.leave
	ret
PortEmulatorConnect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorStreamSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the input and output streams, sets the
		thresholds, and sets the notification routines.

CALLED BY:	PortEmulatorEstablishConnection
PASS:		bx	= unit number
		cx	= input buffer size
		dx	= output buffer size
		ds	= dgroup
RETURN:		carry set on error
			cx = destroyed
		carry clear if ok
			cx = initial credits
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorStreamSetup	proc	far
	uses	ax,bx,dx,si,di,bp
	.enter

EC <	call	ECValidateUnitNumber					>

	mov	si, bx				; si = unit number
	call	GeodeGetProcessHandle		; bx = processHandle

	call	SetupInputStream
	jc	error

	call	SetupOutputStream
error:
	.leave
	ret
PortEmulatorStreamSetup	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupInputStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the input stream and set the high & low-water
		thresholds.

CALLED BY:	PortEmulatorStreamSetup
PASS:		bx	= geode handle
		cx	= input stream size
		si	= unit number
		ds	= dgroup
RETURN:		carry set if couldn't create stream
			cx = destroyed
		carry clear if ok
			cx = initial credits
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupInputStream	proc	far
	uses	ax,bx,dx,si,di,bp
	.enter

	sti					; why were they off?
	;
	; Ignore the input passed to us.
	;
	mov	cx, INPUT_STREAM_SIZE
	mov	ax, cx				; ax = stream size
	shr	cx				; divide by 4
	shr	cx
	mov	ds:[si].ISPD_lowWater, cx	; 1/4 of buffer low thresh
	mov	ds:[si].ISPD_highWater, ax	; set to top of buffer
	neg	cx
	add	cx, ax
	jle	keepAtTop
	mov	ds:[si].ISPD_highWater, cx	; 3/4 of buffer high thresh
keepAtTop:
	;
	; Create the input stream
	;
	mov	dx, ax
	mov	cx, mask HF_FIXED		; cx = fixed buffer
	mov	di, DR_STREAM_CREATE
	call	StreamStrategy			; bx = stream token
	jc	error
	mov	ds:[si].ISPD_inStream, bx
	;
	; Tell TinyTP how many credits it can advance to the other
	; side.
	;
	mov	ax, dx				; ax = buffer size
	clr	dx				; dx:ax = stream size
	mov	cx, ds:[si].ISPD_packetDataSizeIn
	div	cx				; ax = #packets per buffer
	mov_tr	cx, ax				; cx = # of credits

	clr	ds:[si].ISPD_bytesDealtWith
	;
	; Set the low-water threshold so that we can receive
	; notification when the stream drains and we can act on the
	; data indication which TinyTP sends us.
	;
	push	cx				; cx = initial credits
	mov	cx, ds:[si].ISPD_highWater
	mov	ax, STREAM_WRITE
	mov	di, DR_STREAM_SET_THRESHOLD
	call	StreamStrategy
	;
	; Set the notifier for the writing side of the input stream so
	; that we can mark the input state as not busy when the stream
	; drains.  We won't actually turn the notifier on until the
	; stream raises above the highwater mark and we go to a busy
	; state.
	;
	mov	ax, StreamNotifyType <0,SNE_DATA,SNM_NONE>
	mov	bp, si				; Pass unit number to us
	mov	dx, offset PortEmulatorRestart
	mov	cx, segment PortEmulatorRestart
	mov	di, DR_STREAM_SET_NOTIFY
	call	StreamStrategy
	clc
	;
	; Set any stream notifiers for the user which may have existed
	; during a previous connection (or which couldn't be set due
	; to no existing connection).
	;
	call	SetStreamNotifiers
	pop	cx				; cx = initial credits
error:
	.leave
	ret
SetupInputStream	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetStreamNotifiers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if any stream notifiers were requested by the
		client.  The notifiers could have been set but lost
		during a disconnect, or were set by the user before
		the connection was made.

CALLED BY:	SetInputStream
PASS:		bx	= input stream token
		si	= unit number
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	2/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetStreamNotifiers	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	tst	ds:[si].ISPD_dataEvent.SN_type
	jz	checkError
	;
	; There is a Data event.  Let the stream driver know what it is.
	;
	clr	ax
	mov	al, ds:[si].ISPD_dataEvent.SN_type
	or	al, SNE_DATA shl offset SNT_EVENT
	or	al, mask SNT_READER
	movdw	cxdx, ds:[si].ISPD_dataEvent.SN_dest.SND_routine
	mov	bp, ds:[si].ISPD_dataEvent.SN_data
	mov	di, DR_STREAM_SET_NOTIFY
	call	StreamStrategy	

checkError:
	tst	ds:[si].ISPD_errorEvent.SN_type
	jz	done
	;
	; There is an Error event.  Let the stream driver know about it.
	;
	clr	ax
	mov	al, ds:[si].ISPD_errorEvent.SN_type
	or	al, SNE_ERROR shl offset SNT_EVENT
	or	al, mask SNT_READER
	movdw	cxdx, ds:[si].ISPD_errorEvent.SN_dest.SND_routine
	mov	bp, ds:[si].ISPD_errorEvent.SN_data
	mov	di, DR_STREAM_SET_NOTIFY
	call	StreamStrategy
	clc
done:
	.leave
	ret
SetStreamNotifiers	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupOutputStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the output stream and set the notifier & threshold

CALLED BY:	PortEmulatorStreamSetup
PASS:		bx	= geode handle
		dx	= output stream size
		si	= unit number
		ds	= dgroup
RETURN:		carry set if couldn't create stream
		carry clear if no error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupOutputStream	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

EC <	cmp	dx, 4096						>
EC <	ERROR_G	IRCOMM_STREAM_TOO_BIG					>
	;
	; Create the output buffer
	;
	mov	ax, dx				; ax = buffer size
	mov	cx, mask HF_FIXED
	mov	di, DR_STREAM_CREATE
	call	StreamStrategy			; bx = stream token
	jc	done
	mov	ds:[si].ISPD_outStream, bx
	;
	; The output flush time is the amount of time to wait before
	; forcing data in the stream to be sent.
	;
	call	ReadIniOutputFlushTime
	;
	; Create the event queue which will handle timer requests.
	;
	push	bx
	mov	ax, TGIT_THREAD_HANDLE
	clr	bx				; get current thread handle
	call	ThreadGetInfo
	call	IrCommInitThread		; create event thread
	pop	bx				; bx = unit number
	jc	destroy
	;
	; Set a notifier so that we will be called when the first byte
	; of data gets written to the stream.  The notifier will set a
	; timer and adjust the threshold so that data is not stranded
	; in the stream
	;
	mov	ax, StreamNotifyType <1,SNE_DATA,SNM_ROUTINE>
	mov	bp, si		; Pass SerialPortData offset to us
	mov	dx, offset PortEmulatorNotify
	mov	cx, segment PortEmulatorNotify
	mov	di, DR_STREAM_SET_NOTIFY
	call	StreamStrategy
	;
	; Set the threshold to 0 so we get called on the first byte.
	; We will initially be called with 0 bytes, but we'll ignore
	; the first call
	;
	mov	ax, STREAM_READ
	mov	cx, 0
	mov	di, DR_STREAM_SET_THRESHOLD
	call	StreamStrategy
done:
	.leave
	ret
destroy:
	;
	; An error occured after we created the stream.  Make sure we
	; destroy the stream before exiting.
	;
	mov	ax, STREAM_DISCARD
	mov	di, DR_STREAM_DESTROY
	call	StreamStrategy
	stc
	jmp	done
SetupOutputStream	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorSendLineSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends either DTE or DCE line settings, depending on
		the client's role.

CALLED BY:	INTERNAL
PASS:		bx	= unit number
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorSendLineSettingsFar	proc	far
	call	PortEmulatorSendLineSettings
	ret
PortEmulatorSendLineSettingsFar	endp

PortEmulatorSendLineSettings	proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

	sub	sp, 4				; make room on stack
	mov	si, sp

	cmp	ds:[bx].ISPD_clientRole, SR_DCE	; are we DCE or DTE?
	je	sendDCE
	;
	; Send the current DTE settings.  First convert from
	; SerialModem to IrCommDTESetting
	;
	mov	al, ds:[bx].ISPD_dteSetting

	mov	{byte} ss:[si], 3		; clen
	mov	{byte} ss:[si+1], ICCP_DTE	; PI
	mov	{byte} ss:[si+2], 1		; PL
	mov	{byte} ss:[si+3], al		; PV
done:
	segmov	ds, ss
	call	PortEmulatorWriteControlData
	add	sp, 4				; restore stack

	.leave
	ret
sendDCE:
	mov	al, ds:[bx].ISPD_dceSetting

	mov	{byte} ss:[si], 3		; clen
	mov	{byte} ss:[si+1], ICCP_DCE	; PI
	mov	{byte} ss:[si+2], 1		; PL
	mov	{byte} ss:[si+3], al		; PV
	jmp	done

PortEmulatorSendLineSettings	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorEstablishConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does the discovery, IAS query, and Connect Request.
		This routine is called when we initially open the
		port. 

CALLED BY:	CheckConnection
PASS:		bx	= unit number
		ds	= dgroup
RETURN:		carry set if couldn't establish the connection
			ax = STREAM_CLOSED
		else
			ax = destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorEstablishConnection	proc	far
	uses	bx,cx,dx,si,di,bp
	.enter

EC <	call	ECValidateUnitNumber					>
	movdw	ds:[openAddr], -1		; invalid address

	call	PortEmulatorDoDiscovery	
	jc	error

	call	PortEmulatorGetLSAP		; cl = LSAP to connect to
						;   pass in IrlmpConnectArgs
						; si = client to unregister
						;   after connect.
	jc	error				

	mov	di, bx				; pass unit number
	call	PortEmulatorConnect		; cx = packet data size
	jc	error

EC <	call	ECValidateUnitNumber					>

	mov	cx, ds:[bx].ISPD_inStreamSize
	mov	dx, ds:[bx].ISPD_outStreamSize
	call	PortEmulatorStreamSetup		; cx = initial credits to send
	jc	error

	mov	si, ds:[bx].ISPD_client		; si = client handle
	call	TTPAdvanceCredit
	;
	; Send the initial line settings
	;
	call	PortEmulatorSendInitialLineSettings
done:
	.leave
	ret
error:
	mov	ax, STREAM_CLOSED
	mov	ds:[bx].ISPD_inStream, 0
	jmp	done
PortEmulatorEstablishConnection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorSendInitialLineSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the initial line settings to let the other side
		know whether we are DCE or DTE and also to enable the
		flow. 

CALLED BY:	EXTERNAL
PASS:		bx	= unit number
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

NOTES:
	I've commented out the functionality of this routine and just
	made it call PortEmulatorSendLineSettings.  This way, if we
	are PASSIVE, the remote can disconnect from us and when it
	reconnects, the settings will not have changed.  The initial
	settings are now set in IrSerialPortData in ircomm.def.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	2/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorSendInitialLineSettingsFar	proc	far
	call	PortEmulatorSendInitialLineSettings
	ret
PortEmulatorSendInitialLineSettingsFar	endp

PortEmulatorSendInitialLineSettings	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

EC <	call	ECValidateUnitNumber					>
	Assert	dgroup ds
if 0
	;
	; Send DTE line settings if we are DTE
	;
	cmp	ds:[bx].ISPD_clientRole, SR_DTE
	jne	doDCE

	mov	ds:[bx].ISPD_dteSetting, mask ICDTE_RTS_STATE or mask ICDTE_DTR_STATE
	mov	ds:[bx].ISPD_curState.SPS_modem, mask SMC_RTS or mask SMC_DTR

send:
endif
	call	PortEmulatorSendLineSettings

	.leave
	ret
if 0
	;
	; Send DCE line settings if we are DCE
	;
doDCE:

	mov	ds:[bx].ISPD_dceSetting, mask ICDCE_CTS_STATE or mask ICDCE_DSR_STATE or mask ICDCE_RI_STATE or mask ICDCE_CD_STATE or mask ICDCE_CTS_DELTA or mask ICDCE_DSR_DELTA or mask ICDCE_RI_DELTA or mask ICDCE_CD_DELTA

	mov	ds:[bx].ISPD_curState.SPS_modem, mask SMC_CTS or mask SMC_DSR or mask SMC_RI or mask SMC_DCD

	jmp	send
endif
PortEmulatorSendInitialLineSettings	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrAddToIas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates an IrCOMM entry in the IAS database and adds
		the TinyTP LSAP attribute.

CALLED BY:	(INTERNAL) IrCommPassiveOpen
PASS:		cx	= LSAP to be used by IrCOMM
		si	= client handle
RETURN:		carry set on error
			ax = IrdbErrorType
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	2/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrAddToIas	proc	far
	uses	bx,cx,dx,si,di,bp,ds
	.enter

	call	IrdbOpenDatabase
	jc	error
	;
	; Create the IrCOMM class
	;
	push	cx
	mov	ax, segment ResidentCode
	segmov	ds, ax
	mov	dx, offset ircommClassName
	xchg	dx, si				; ds:si = class name
	mov	cx, size ircommClassName
	clr	ax				; not permanent
	call	IrdbCreateEntry			; ax = Object ID
	pop	dx				; dx = LSAP
	jc	close
	;
	; Add the TinyTP LSAP Sel attribute to the IrCOMM object
	;
	mov	si, offset ircommAttrName
	mov	bp, size ircommAttrName		; not null terminated
	mov	di, IIVT_INTEGER
	mov_tr	bx, ax				; bx = Object ID
	clr	ax
	xchg	ax, dx				; dxax = LSAP sel
	call	IrdbAddAttribute		; add LSAP attribute
	jc	error
	;
	; Add the IrCOMM Parameters attribute
	;
	mov	si, offset ircommParameters	; Port Type attribute
	mov	bp, size ircommParameters
	mov	di, IIVT_OCTET_SEQUENCE
	mov	dx, segment ResidentCode
	mov	ax, offset paramOctetSeq
	mov	cx, size paramOctetSeq	
	call	IrdbAddAttribute
	jc	error
close:
	pushf
	call	IrdbCloseDatabase
	jc	errorClose
	popf
error:
	.leave
	ret
errorClose:
	pop	ax				; pop the flags
	stc
	jmp	error
IrAddToIas	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadIniOutputFlushTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads the output flush time (in ticks) from the ini
		file.
CALLED BY:	SetupOutputStream
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	4/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ircommCategory	char	"IrCOMM",0
flushTimeKey	char	"flushTime",0

ReadIniOutputFlushTime	proc	near
	uses	ax,cx,dx,si,di,ds
	.enter

	mov	ds:[flushTime], OUTPUT_FLUSH_TIME

	push	ds
	segmov	ds, cs, ax
	mov	si, offset ircommCategory		;ds:si = category
	mov	cx, cs
	mov	dx, offset flushTimeKey			;cx:dx = key
	call	InitFileReadInteger			;ax = value
	pop	ds

	jc	useDefault				;not found?

	mov	ds:[flushTime], ax

useDefault:

	.leave
	ret
ReadIniOutputFlushTime	endp


PortEmulatorCode	ends
