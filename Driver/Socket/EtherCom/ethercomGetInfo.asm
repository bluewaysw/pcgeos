COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Tedious Endeavors 1998 -- All Rights Reserved

PROJECT:	Native ethernet support
MODULE:		Ethernet link driver
FILE:		ethercomGetInfo.asm

AUTHOR:		Todd Stumpf, July 8th, 1998

ROUTINES:

    INT EtherGetInfo         Get information about the driver

DESCRIPTION:

	Routines to retreive informatio about link driver which are
	common to all ethernet link drivers

	$Id:$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MovableCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about the driver

CALLED BY:	EtherStrategy

PASS:		ax	= SocketGetInfoType
RETURN:		carry set if info not available
DESTROYED:	ax

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherGetInfo	proc	far
		.enter
		cmp	ax, offset getInfoTableEnd - offset getInfoTable
		cmc
		jb	done				; jb=jc
		push	di
		mov	di, ax
		mov	ax, cs:[getInfoTable][di]
		pop	di
		call	{nptr}ax
done:
		.leave
		ret
EtherGetInfo	endp
	
DefInfoFunction   macro   routine, cnst
.assert ($-getInfoTable) eq cnst, <function table is corrupted>
.assert (type routine eq near)
                nptr        routine
                endm

getInfoTable	label	nptr
DefInfoFunction	EtherGetMediaList, 		SGIT_MEDIA_LIST
DefInfoFunction	EtherGetMediumAndUnit,		SGIT_MEDIUM_AND_UNIT
DefInfoFunction	EtherGetAddrCtrl,		SGIT_ADDR_CTRL
DefInfoFunction	EtherInfoNotAvailable,		SGIT_ADDR_SIZE
DefInfoFunction	EtherGetAddress,		SGIT_LOCAL_ADDR
DefInfoFunction	EtherInfoNotAvailable,		SGIT_REMOTE_ADDR
DefInfoFunction	EtherGetMTU,			SGIT_MTU
DefInfoFunction EtherGetPrefCtrl,		SGIT_PREF_CTRL
DefInfoFunction EtherGetMediumConnection,	SGIT_MEDIUM_CONNECTION
DefInfoFunction	EtherGetMediumConnection,	SGIT_MEDIUM_LOCAL_ADDR
getInfoTableEnd	label	byte
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherInfoNotAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		
RETURN:		
DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherInfoNotAvailable	proc	near
		stc
		ret
EtherInfoNotAvailable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetMediaList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	List of media supported by ether

CALLED BY:	EtherGetInfo

PASS:		*ds:si	- chunk array
RETURN:		*ds:si	- chunk array of MediumType
		carry set if ChunkArrayAppend failed
		clear otherwise
DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherGetMediaList	proc	near
		uses	di
		.enter
		call	ChunkArrayAppend		; ds:di = MediumType
		jc	done
		mov	ds:[di].MET_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ds:[di].MET_id, GMID_NETWORK
done:
		.leave
		ret
EtherGetMediaList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetMediumAndUnit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the medium and unit of a link

CALLED BY:	EtherGetInfo

PASS:		nothing
RETURN:		cx	- MANUFACTURER_ID_GEOWORKS
		dx	- GMIT_ETHER
		bl	- MUT_NONE
		bp	- 0
		carry clear
DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherGetMediumAndUnit	proc	near
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GMID_NETWORK
		mov	bl, MUT_NONE
		clr	bp
		ret
EtherGetMediumAndUnit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetAddressSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return number of significant bytes in an addres

CALLED BY:	EtherGetInfo

PASS:		nothing
RETURN:		ax = 0
		carry clear
DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
EtherGetAddressSize	proc	near
		clr	ax
		ret
EtherGetAddressSize	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the local address

CALLED BY:	EtherGetInfo

PASS:		ds:bx	- buffer
		dx	- buffer size
RETURN:		carry clear if info available
			ds:bx	- buffer filled with address if buffer is
				  big enough
			ax	- address size
		carry set if not available
DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherGetAddress	proc	near
		uses	cx, dx, es
		.enter

		mov_tr	ax, dx		; ax = buffer size
		GetDGroup	es, dx
		movdw	dxcx, es:[localIpAddr]	; dxcx = IP addr, network order
		tstdw	dxcx
		stc
		jz	exit		; => no info

		cmp	ax, IP_ADDR_SIZE
		mov	ax, IP_ADDR_SIZE
		jb	done		; => buffer too small

	;	commented out, ip address now stored in network order
	;		xchg	dh, cl
	;		xchg	dl, ch		; dxcx = IP addr, network order
		movdw	ds:[bx], dxcx

done:
		clc			; info available

exit:
		.leave
		ret
EtherGetAddress	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetAddrCtrl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns address controller

CALLED BY:	SGIT_ADDR_CTRL

PASS:		dx = media
RETURN:		cx:dx = class pointer
DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherGetAddrCtrl	proc	near
		uses	bx
		.enter
		stc
if 0
		mov	bx, handle 0
		call	GeodeAddReference
		mov	cx, segment EtherAddressControlClass
		mov	dx, offset EtherAddressControlClass
endif
		.leave
		ret
EtherGetAddrCtrl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetMTU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return MTU

CALLED BY:	SGIT_MTU
PASS:		nothing
RETURN:		ax	= MTU
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	12/05/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherGetMTU	proc	near
	.enter

	mov	ax, ETHER_MTU
	clc

	.leave
	ret
EtherGetMTU	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetPrefCtrl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns pref control class

CALLED BY:	SGIT_PREF_CTRL

PASS:		nothing
RETURN:		cx:dx = class
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherGetPrefCtrl	proc	near
		.enter
		clr	cx, dx
		.leave
		ret
EtherGetPrefCtrl	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetMediumConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if driver is connected over medium and unit, and
		return address if connected.

CALLED BY:	SGIT_MEDIUM_CONNECTION

PASS:		dx:bx	= MediumAndUnit
		ds:si	= address buffer
		cx	= buffer size in bytes
RETURN: 	carry set if no connection is established over the
			unit of the medium.
		else
		ds:si	= filled in with address, up to value passed
			  in as buffer size.
		cx	= actual size of address in ds:si.  If cx
			  is greater than the buffer size that was
			  passed in, then address in ds:si is 
			  incomplete.
DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherGetMediumConnection	proc	near
	uses	ds, si, ax, bx
	.enter
	;
	; The only medium acceptable for this driver is GMID_ETHER/
	; MANUFACTURER_ID_GEOWORKS.
	;
	movdw	dssi, dxbx			;ds:si = MediumAndUnit
	cmp	ds:[si].MU_medium.MET_id, GMID_NETWORK
	jne	notConnected
	cmp	ds:[si].MU_medium.MET_manuf, MANUFACTURER_ID_GEOWORKS
	jne	notConnected

	;
	; Check that we've connected with an ethernet card.
	;
	GetDGroup	ds, ax
	tst	ds:[linkEstablished]
	jz	notConnected

	;
	; We are connected.  Since the ether driver can connect to
	; anyone anytime, return a null address.
	; 
	clr	cx
	clc
exit:
	.leave
	ret

notConnected:
	stc
	jmp	exit
EtherGetMediumConnection	endp
	
MovableCode	ends
