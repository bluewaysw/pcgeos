COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		utilsPDU.asm

AUTHOR:		Chung Liu, Mar 21, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/21/95   	Initial revision


DESCRIPTION:
	Routines to manage PDUs.

	$Id: utilsPDU.asm,v 1.1 97/04/05 01:08:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a HugeLMem block for PDU data.

CALLED BY:	(INTERNAL) UtilsInit
PASS:		nothing
RETURN:		if error (insufficient memory):
			carry set 
		else:
			carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPInit	proc	near
	uses	ax,cx
	.enter
	call	UtilsLoadDGroupES
	
	clr	ax			;default maximum
	mov	bx, 20
	mov	cx, 2000
	call	HugeLMemCreate		;bx = HugeLMem handle
	jc	exit
	mov	es:[utilsHugeLMemBlock], bx
exit:
	.leave
	ret
UPInit	endp

InitCode	ends

UtilsCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsAllocPDUData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate enough data for a LM-PDU with no use data.

CALLED BY:	(EXTERNAL) LFConnectConfirmSetupPend
PASS:		nothing
RETURN:		^ldx:ax	= HugeLMem data block
		cx	= 0 (reflects no user data)
		si	= offset of IPDU_data 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsAllocPDUData	proc	far
	uses	es,ds,di,bx
	.enter
	call	UtilsLoadDGroupES
	mov	bx, es:[utilsHugeLMemBlock]
	mov	ax, size IrlmpPDU
	mov	cx, FOREVER_WAIT
	call	HugeLMemAllocLock		;^lax:cx = buffer
						;ds:di = buffer
	mov	bx, ax
	call	HugeLMemUnlock
	mov	dx, ax
	mov	ax, cx				;^ldx:ax = buffer
	clr	cx				;no data space
	mov	si, offset IPDU_data
	.leave
	ret
UtilsAllocPDUData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsMakeConnectPDU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a Connect PDU out of the data provided.

CALLED BY:	(EXTERNAL)
PASS:		^ldx:ax	= HugeLMem data block
		si	= offset of data
		cx	= number of bytes to send
		bh	= destination IrlmpLsapSel
		bl	= source IrlmpLsapSel

RETURN:		si	= new offset into data
		cx	= new byte count
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsMakeConnectPDU	proc	far
	uses	di
	.enter
	push	cx			;save data size
	mov	di, 0
	mov	cx, IOC_CONNECT
	call	UPMakePDU		;si = new offset
	pop	cx			;cx = data size
	add	cx, size IrlmpPDU	;cx = new data size
	.leave
	ret
UtilsMakeConnectPDU	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsMakeDisconnectPDU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a Disconnect PDU out of the data provided

CALLED BY:	(EXTERNAL) LFDisconnectRequest
PASS:		^ldx:ax	= HugeLMem data block
		si	= offset of data
		cx	= number of bytes to send
		bh	= destination IrlmpLsapSel
		bl	= source IrlmpLsapSel
		bp.low 	= IrlmpDisconnectReason

RETURN:		si	= new offset into data
		cx	= new byte count
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsMakeDisconnectPDU	proc	far
	uses	di
	.enter
	push	cx			;save data size
	mov	di, bp
	mov	cl, IOC_DISCONNECT
	call	UPMakePDU		;si = new offset
	pop	cx			;cx = data size
	add	cx, size IrlmpPDU	;cx = new data size
	.leave
	ret
UtilsMakeDisconnectPDU	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsMakeConnectConfirmPDU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a Connect Confirm PDU out of the data provided.

CALLED BY:	(EXTERNAL)
PASS:		^ldx:ax	= HugeLMem data block
		si	= offset of data
		cx	= number of bytes to send
		bh	= destination IrlmpLsapSel
		bl	= source IrlmpLsapSel

RETURN:		si	= new offset into data
		cx	= new byte count
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsMakeConnectConfirmPDU	proc	far
	uses	di
	.enter
	push	cx			;save data size
	mov	di, 0
	mov	cl, IOC_CONNECT_CONFIRM
	call	UPMakePDU		;si = new offset
	pop	cx			;cx = data size
	add	cx, size IrlmpPDU	;cx = new data size
	.leave
	ret
UtilsMakeConnectConfirmPDU	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsMakeDataPDU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform the data provided into a Data LM-PDU

CALLED BY:	(EXTERNAL) LFDataRequest
PASS:		^ldx:ax	= HugeLMem data block
		si	= offset of data
		cx	= number of bytes to send
		bh	= destination IrlmpLsapSel
		bl	= source IrlmpLsapSel

RETURN:		cx	= new size
		si	= new offset
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsMakeDataPDU	proc	far
lsaps		local	word			push bx
	uses	ax,bx,dx,ds,di
	.enter
EC <	cmp	si, size IrlmpFrameHeader		>
EC <	ERROR_B	IRLMP_NOT_ENOUGH_HEADER_SPACE		>

	push	cx			;save data size
	;
	; Lock down the data
	;
	movdw	bxdi, dxax			;^lbx:di = HugeLMem data block
	push	bx
	call	HugeLMemLock			;ax = segment of block
	mov	ds, ax
	mov	di, ds:[di]			
	;
	; Subtract size IrlmpFrameHeader from offset, to get to the start 
	; of the header.
	;
	sub	si, size IrlmpFrameHeader	;si = new offset to return
	add	di, si				;ds:di = HugeLMem data
	;
	; Fill in the frame header
	;
	mov	bx, ss:[lsaps]
	xchg	bl, bh
	mov	ds:[di], bx
	;
	; unlock the data block
	;
	pop	bx
	call	HugeLMemUnlock

	pop	cx				;cx = data size
	add	cx, size IrlmpFrameHeader	;cx = new data size
	.leave
	ret
UtilsMakeDataPDU	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPMakePDU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a PDU out of the data.

CALLED BY:	(INTERNAL)
PASS:		^ldx:ax	= HugeLMem data block
		si	= offset of data
		bh	= destination IrlmpLsapSel
		bl	= source IrlmpLsapSel
		cl	= IrlmpOpCode
		di.low	= IrlmpParameter
RETURN:		si	= new offset of data, including header
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPMakePDU	proc	near
lsaps		local	word			push bx
param		local	word			push di
	uses	ds,di,ax,bx
	.enter
EC <	cmp	si, size IrlmpPDU			>
EC <	ERROR_B	IRLMP_NOT_ENOUGH_HEADER_SPACE		>
	
	;
	; Lock down the data
	;
	movdw	bxdi, dxax			;^lbx:di = HugeLMem data block
	push	bx
	call	HugeLMemLock			;ax = segment of block
	mov	ds, ax
	mov	di, ds:[di]			
	;
	; Subtract size IrlmpPDU from offset, to get to the start of the 
	; header.
	;
	sub	si, size IrlmpPDU		;ds:di = IrlmpPDU
	add	di, si				;ds:di = HugeLMem data
	;
	; Set IFH_CONTROL and clear IFH_RESERVED.  Low byte of word is
	; transmitted first, so exchange bl and bh.
	;
	mov	bx, ss:[lsaps]
	xchg	bl, bh				;bl = dest lsap
						;bh = source lsap
	ornf	bx, mask IFH_CONTROL
	andnf	bx, not mask IFH_RESERVED
	
	mov	ds:[di].IPDU_header, bx
	mov	ds:[di].IPDU_opCode, cl
	mov	ax, ss:[param]
	mov	ds:[di].IPDU_parameter, al
	;
	; unlock the data block
	;
	pop	bx
	call	HugeLMemUnlock
	.leave
	ret
UPMakePDU	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsGetLsapsFromPDU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Obtain the destionation LSAP-Sel from the PDU.

CALLED BY:	(EXTERNAL) IsapDataIndication
PASS:		^ldx:ax	= HugeLMem buffer
		si	= offset of data in buffer
RETURN:		ch	= destination IrlmpLsapSel
		cl	= source IrlmpLsapSel
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsGetLsapsFromPDU	proc	far
	uses	ax,bx,ds,di
	.enter
	;
	; Peek into IFH_DLSAP_SEL to select the proper LsapFsm to which
	; we should forward this data indication.
	;
	movdw 	bxdi, dxax
	call	HugeLMemLock			;ax = segment of block
	mov	ds, ax
	mov	di, ds:[di]			;ds:di = data buffer
	add	di, si				;ds:di = data 
	mov	cx, ds:[di]			;ax = IrlmpFrameHeader
	andnf	cx, mask IFH_DLSAP_SEL or mask IFH_SLSAP_SEL
	xchg	cl, ch
						;ch = dest LSAP
						;cl = source LSAP
	call	HugeLMemUnlock
	.leave
	ret
UtilsGetLsapsFromPDU	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsGetOpCodeFromPDU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract the Op-Code from the data indication.

CALLED BY:	(EXTERNAL) LFIrlapDataIndication
PASS:		ss:bp	= IrlmpDataArgs
RETURN:		dl	= IrlmpOpCode
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsGetOpCodeFromPDU	proc	far
	uses	ax,bx,ds,di,si
	.enter
	movdw	bxdi, ss:[bp].IDA_data
	mov	si, ss:[bp].IDA_dataOffset
	call	HugeLMemLock			;ax = segment of block
	mov	ds, ax
	mov	di, ds:[di]
	add	di, si				;ds:di = IrlmpPDU
	mov	ax, ds:[di]			;ax = IrlmpFrameHeader
	;
	; Determine if this is a data PDU.  The IFH_CONTROL bit is
	; 0 for data, or 1 for command frames.
	;
	test	ax, mask IFH_CONTROL
	jnz	notData
	mov	dx, IOC_DATA
	jmp	exit

notData:
	mov	dl, ds:[di].IPDU_opCode
exit:
	call	HugeLMemUnlock
	.leave
	ret
UtilsGetOpCodeFromPDU	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsGetParameterFromPDU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract the parameter byte from the LM-PDU.

CALLED BY:	(EXTERNAL) LFDisconnectPDU
PASS:		ss:bp	= IrlmpDataArgs for LM-PDU
RETURN:		bl	= parameter byte
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsGetParameterFromPDU	proc	far
	uses	ax,ds,di,si
	.enter
	movdw	bxdi, ss:[bp].IDA_data
	mov	si, ss:[bp].IDA_dataOffset
	call	HugeLMemLock			;ax = segment of block
	mov	ds, ax
	mov	di, ds:[di]
	add	di, si				;ds:di = IrlmpPDU

	mov	al, ds:[di].IPDU_parameter	
	call	HugeLMemUnlock
	mov	bl, al
	.leave
	ret
UtilsGetParameterFromPDU	endp

UtilsCode	ends
