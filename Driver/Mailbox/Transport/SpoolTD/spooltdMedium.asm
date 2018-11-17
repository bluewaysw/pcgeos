COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		spooltdMedium.asm

AUTHOR:		Adam de Boor, Oct 27, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/27/94	Initial revision


DESCRIPTION:
	Stuff related to media
		

	$Id: spooltdMedium.asm,v 1.1 97/04/18 11:40:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MediaCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTDCheckMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the transport driver uses the passed medium
		to transmit messages.

CALLED BY:	(GLOBAL) DR_MBTD_CHECK_MEDIUM
PASS:		cxdx	= MediumType
		ax	= MailboxTransportOption
RETURN:		carry set if the transport option of this driver employs
			the passed medium
		carry clear if the transport option does *not* support
			the passed medium
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolTDCheckMedium proc	far
		.enter
		cmp	cx, MANUFACTURER_ID_GEOWORKS
		jne	nope
		cmp	dx, GMID_PRINTER
		jne	nope
		stc
done:
		.leave
		ret
nope:
		clc
		jmp	done
SpoolTDCheckMedium endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTDGetMaxAddressSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the number of bytes in the largest address used by
		the transport driver for the given medium

CALLED BY:	(GLOBAL) DR_MBTD_GET_MAX_ADDRESS_SIZE
PASS:		cxdx	= MediumType
		ax	= MailboxTransportOption
RETURN:		ax	= # bytes
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolTDGetMaxAddressSize proc	far
		.enter
		Assert	e, cx, MANUFACTURER_ID_GEOWORKS
		Assert	e, dx, GMID_PRINTER
		Assert	e, ax, 0
		
		mov	ax, MAXIMUM_PRINTER_NAME_LENGTH + size JobParameters
		.leave
		ret
SpoolTDGetMaxAddressSize endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTDCheckMediumConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if a connection over a particular medium can
		be used by the transport driver, and if so, what the address
		of the connected machine is.

CALLED BY:	(GLOBAL) DR_MBTD_CHECK_MEDIUM_CONNECTION
PASS:		cx:dx	= pointer to MBTDMediumMapArgs
			  MBTDMMA_medium, MBTDMMA_unit, MBTDMMA_unitType
			  	set for the medium
			  MBTDMMA_transAddr pointing to as many bytes as
				were indicated as necessary by previous call
				to DR_MBTD_GET_MAX_ADDRESS_SIZE
				(MBTDMMA_transAddrLen set to this value)
RETURN:		carry set if the transport driver can use the connection:
			*cx:dx.MBTDMMA_transAddr filled in
			cx:dx.MBTDMMA_transAddrLen set to actual address length
		carry clear if transport driver can *not* use the connection.
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		if medium is GMID_PRINTER, copy printer name from unit to
		transAddr buffer and set transAddrLen to MAXIMUM_PRINTER_NAME

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolTDCheckMediumConnection proc	far
		.enter
		.leave
		ret
SpoolTDCheckMediumConnection endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTDGetAddressMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the medium and unit encoded in a particular address

CALLED BY:	(GLOBAL) DR_MBTD_GET_ADDRESS_MEDIUM
PASS:		cx:dx	= pointer to MBTDMediumMapArgs
			  MBTDMMA_transAddr points to address from a message
			  MBTDMMA_transAddrLen holds the size of the address
RETURN:		carry set if the address is invalid
		carry clear if address is valid:
			cx:dx.MBTDMMA_medium, MBTDMMA_unit, and
			MBTDMMA_unitType filled in. unitType may be MMUT_ANY
			to indicate any unit of the medium can be used to
			transmit the message
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolTDGetAddressMedium proc	far
		uses	cx, ds, si, bx, di, ax, es
		.enter
		movdw	dssi, cxdx
		Assert	ge, ds:[si].MBTDMMA_transAddrLen,  \
				MAXIMUM_PRINTER_NAME_LENGTH
		mov	ds:[si].MBTDMMA_medium.MET_manuf,
				MANUFACTURER_ID_GEOWORKS
		mov	ds:[si].MBTDMMA_medium.MET_id,
				GMID_PRINTER
		mov	ds:[si].MBTDMMA_unitType, MUT_MEM_BLOCK
		mov	ax, MAXIMUM_PRINTER_NAME_LENGTH
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or \
				(mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		mov	ds:[si].MBTDMMA_unit, bx
		mov	es, ax
		clr	di
		lds	si, ds:[si].MBTDMMA_transAddr
		mov	cx, MAXIMUM_PRINTER_NAME_LENGTH/2
		rep	movsw
if  MAXIMUM_PRINTER_NAME_LENGTH and 1
		movsb
endif
		call	MemUnlock
		clc
		.leave
		ret
SpoolTDGetAddressMedium endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTDGetMediumParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetche the monikers and verb for how a message is transmitted
		to a particular medium through this transport driver

CALLED BY:	(GLOBAL) DR_MBTD_GET_MEDIUM_PARAMS
PASS:		cx:dx	= MBTDGetMediumParamsArgs
		ax	= MailboxTransportOption
RETURN:		carry set on error
		carry clear if ok:
			MBTDGMPA_monikers, MBTDGMPA_verb, and
			MBTDGMPA_significantAddrBytes filled in
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolTDGetMediumParams proc	far
		uses	ds, si
		.enter
		Assert	e, ax, 0
		movdw	dssi, cxdx
		Assert	e, ds:[si].MBTDGMPA_medium.MET_manuf, \
				MANUFACTURER_ID_GEOWORKS
		Assert	e, ds:[si].MBTDGMPA_medium.MET_id, GMID_PRINTER
		
		mov	ds:[si].MBTDGMPA_monikers.handle, handle SpoolTDMonikers
		mov	ds:[si].MBTDGMPA_monikers.chunk, offset SpoolTDMonikers

		mov	ds:[si].MBTDGMPA_verb.handle, handle SpoolTDVerb
		mov	ds:[si].MBTDGMPA_verb.chunk, offset SpoolTDVerb
		
		mov	ds:[si].MBTDGMPA_abbrev.handle, handle SpoolTDAbbrev
		mov	ds:[si].MBTDGMPA_abbrev.chunk, offset SpoolTDAbbrev
		
		mov	ds:[si].MBTDGMPA_significantAddrBytes,
				MAXIMUM_PRINTER_NAME_LENGTH

		clc
		.leave
		ret
SpoolTDGetMediumParams endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTDGetTransportOptionsInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the number of transport options available from this 
		driver

CALLED BY:	(GLOBAL) DR_MBTD_GET_TRANSPORT_OPTIONS_INFO
PASS:		nothing
RETURN:		cx	= number of options available
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolTDGetTransportOptionsInfo proc	far
		.enter
		mov	cx, 1		; just one option, here
		.leave
		ret
SpoolTDGetTransportOptionsInfo endp
MediaCode	ends
