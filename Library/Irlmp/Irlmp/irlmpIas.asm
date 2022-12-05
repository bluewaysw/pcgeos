COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IAS
FILE:		irlmpIas.asm

AUTHOR:		Chung Liu, May  9, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 9/95   	Initial revision


DESCRIPTION:
	API for IAS queries.
		

	$Id: irlmpIas.asm,v 1.1 97/04/05 01:07:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


NOFXIP<	IasCode		segment resource>
FXIP<	ResidentXIP	segment	resource>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpGetValueByClassRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get all the values of a named attribute in objects of a
		given class name.

CALLED BY:	GLOBAL
PASS:		si	= client handle
		cx:dx	= IrlmpGetValueByClassRequestArgs
RETURN:		carry clear if okay:
			ax	= IE_SUCCESS
		carry set if error:
			ax	= IrlmpError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpGetValueByClassRequest	proc	far

;
; clientHandle and connectArgs must be consecutive because it corresponds
; to ICFCallRequestArgs.
;

clientHandle	local	word			push si
connectArgs	local	IrlmpConnectArgs
dataSize	local	word

	uses	bx,cx,dx,si,di,ds,es
	.enter

	;
	; Setup what we can in connectArgs.
	;
	movdw	dssi, cxdx			;ds:si = args
	movdw	ss:[connectArgs].ICA_lsapID.ILI_irlapAddr, \
			ds:[si].IGVBCRA_irlapAddr, ax
	mov	ss:[connectArgs].ICA_lsapID.ILI_lsapSel, \
			IRLMP_IAS_LSAP_SEL
	mov	ss:[connectArgs].ICA_QoS.QOS_flags, \
			mask QOSF_DEFAULT_PARAMS	

	;
	; Figure out parameter size.
	;
	movdw	esdi, ds:[si].IGVBCRA_attributeName 	;es:di = 
							;  IrlmpIasNameHeader
							;  of attribute name
	push	es, di		
	clr	cx
	mov	cl, es:[di].IINH_size			;cx = name size
	add	cx, offset IINH_name

	movdw	esdi, ds:[si].IGVBCRA_className		;es:di = 
							;  IrlmpIasNameHeader
							;  of class name
	push	es, di		
	clr	ax
	mov	al, es:[di].IINH_size
	add	cx, ax
	add	cx, offset IINH_name			
	add	cx, size IrlmpIasFrame
	mov	ss:[dataSize], cx

	call	UtilsAllocHugeLMemDataLocked		;^ldx:ax = buffer
							;  ds:di = buffer
	segmov	es, ds					;es:di = buffer
	mov	es:[di].IIF_iasControlByte, IIOC_GET_VALUE_BY_CLASS
	pop	ds, si				;ds:si = class name
	clr	cx
	mov	cl, ds:[si].IINH_size
	add	cx, offset IINH_name			
	add	di, size IrlmpIasFrame
	rep	movsb

	pop	ds, si				;ds:si = attribute name 
	clr	cx
	mov	cl, ds:[si].IINH_size
	add	cx, offset IINH_name			
	rep	movsb

	mov	bx, dx
	call	HugeLMemUnlock

	mov	cx, ss:[dataSize]
	sub	cx, size IrlmpFrameHeader
	mov	ss:[connectArgs].ICA_dataSize, cx	
	mov	ss:[connectArgs].ICA_dataOffset, size IrlmpFrameHeader
	movdw	ss:[connectArgs].ICA_data, dxax

	push	bp

	lea	bp, ss:[connectArgs]
	mov	dx, size ICFCallRequestArgs		

	mov	ax, MSG_ICF_CALL_REQUEST
	mov	di, mask MF_CALL or mask MF_STACK
	mov	bx, handle IrlmpIasClientFsm
	mov	si, offset IrlmpIasClientFsm
	call	ObjMessage

	pop	bp

	.leave
	ret
IrlmpGetValueByClassRequest	endp

FXIP<	ResidentXIP	ends			>
FXIP<	IasCode		segment resource	>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpGetValueByClassConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LM_GetValueByClass.confirm

CALLED BY:	(EXTERNAL) 	ICGetValueByClassConfirm
PASS:		si	= client handle
		dl	= IrlmpGetValueByClassReturnCode
		If dl = IGVBCRC_SUCCESS:
			*ds:ax	= chunk array of IrlmpIasIdAndValue
				Array is not valid after callback 
				returns, so callback routine should 
				copy all the information it wants 
				to keep.
		If dl = IGVBCRC_IRLMP_ERROR:
			ax	= IrlmpError

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpGetValueByClassConfirm	proc	far
	uses	di
	.enter
	mov	di, IIC_GET_VALUE_BY_CLASS_CONFIRMATION
	call	IUCallEndpoint
	.leave
	ret
IrlmpGetValueByClassConfirm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpDisconnectIas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disconnect IrLMP connection to peer's IAS LSAP.

CALLED BY:	(EXTERNAL)
PASS:		si	= client handle
RETURN:		carry clear if okay:
			ax	= IE_SUCCESS
		carry set if error:
			ax	= IrlmpError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpDisconnectIas	proc	far
	uses	bp, bx, si, di
	.enter
	mov	bp, si				;bp = requesting client

	mov	ax, MSG_ICF_DISCONNECT_IAS
	mov	di, mask MF_FORCE_QUEUE
	mov	bx, handle IrlmpIasClientFsm
	mov	si, offset IrlmpIasClientFsm
	call	ObjMessage

	clc	
	mov	ax, IE_SUCCESS
	.leave
	ret
IrlmpDisconnectIas	endp


IasCode		ends









