COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		spooltdAddress.asm

AUTHOR:		Adam de Boor, Oct 26, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/26/94	Initial revision


DESCRIPTION:
	Address controller fun
		

	$Id: spooltdAddress.asm,v 1.1 97/04/18 11:40:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



AddressCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTDGetAddressController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the class pointer for the address controller to use

CALLED BY:	DR_MBTD_GET_ADDRESS_CONTROLLER
PASS:		cxdx	= MediumType
		ax	= MailboxTransportOption
RETURN:		cx:dx	= class pointer
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/26/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolTDGetAddressController proc	far
		.enter
		mov	cx, segment MailboxSpoolAddressControlClass
		mov	dx, offset MailboxSpoolAddressControlClass
		.leave
		ret
SpoolTDGetAddressController endp



AddressCode	ends
