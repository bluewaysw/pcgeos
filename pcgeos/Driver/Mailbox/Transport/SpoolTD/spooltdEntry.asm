COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		spooltdEntry.asm

AUTHOR:		Adam de Boor, Oct 25, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/25/94	Initial revision


DESCRIPTION:
	foo
		

	$Id: spooltdEntry.asm,v 1.1 97/04/18 11:40:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

DefTDFunction	macro	const, routine
.assert ($-spooltdFunctions)/2 eq (const), <Routine for const in the wrong slot>
.assert (type (routine) eq far)
		fptr	routine
		endm

spooltdFunctions label	fptr.far
DefTDFunction	DR_INIT,			SpoolTDDoNothing
DefTDFunction	DR_EXIT,			SpoolTDDoNothing
DefTDFunction	DR_SUSPEND,			SpoolTDDoNothing
DefTDFunction	DR_UNSUSPEND,			SpoolTDDoNothing
DefTDFunction	DR_MBTD_GET_ADDRESS_CONTROLLER,	SpoolTDGetAddressController
DefTDFunction	DR_MBTD_PREPARE_FOR_TRANSPORT,	SpoolTDPrepareForTransport
DefTDFunction	DR_MBTD_DONE_WITH_TRANSPORT,	SpoolTDDoNothing
DefTDFunction	DR_MBTD_CONNECT,		SpoolTDConnect
DefTDFunction	DR_MBTD_TRANSMIT_MESSAGE, 	SpoolTDTransmitMessage
DefTDFunction	DR_MBTD_END_CONNECT,		SpoolTDEndConnect
DefTDFunction	DR_MBTD_CHOOSE_FORMAT,		SpoolTDChooseFormat
DefTDFunction	DR_MBTD_CHECK_MEDIUM,		SpoolTDCheckMedium
DefTDFunction	DR_MBTD_GET_MAX_ADDRESS_SIZE,	SpoolTDGetMaxAddressSize
DefTDFunction	DR_MBTD_CHECK_MEDIUM_CONNECTION, SpoolTDCheckMediumConnection
DefTDFunction	DR_MBTD_GET_ADDRESS_MEDIUM,	SpoolTDGetAddressMedium
DefTDFunction	DR_MBTD_GET_MEDIUM_PARAMS,	SpoolTDGetMediumParams
DefTDFunction	DR_MBTD_DELETE,			SpoolTDDoNothing
DefTDFunction	DR_MBTD_RETRIEVE_MESSAGES,	SpoolTDDoNothing
DefTDFunction	DR_MBTD_GET_TRANSPORT_OPTIONS_INFO, SpoolTDGetTransportOptionsInfo
	.assert ($-spooltdFunctions)/2 eq MailboxTransportDriverFunction

MBTDBeginEscapeTable	spooltd
MBTDDefEscape		spooltd, DR_MBTD_ESC_GET_FORMATS, SpoolTDGetFormats
MBTDEndEscapeTable	spooltd


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTDStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routine to dispatch calls to their appropriate routines

CALLED BY:	(GLOBAL)
PASS:		di	= MailboxTransportDriverFunction/DriverFunction
		all else is subject to change without notice
RETURN:		depends on function called
DESTROYED:	ditto
SIDE EFFECTS:	ditto

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/26/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolTDStrategy	proc	far
		.enter
		MBTDHandleEscape	spooltd, done
EC <		cmp	di, MailboxTransportDriverFunction		>
EC <		ERROR_AE INVALID_TRANSPORT_DRIVER_FUNCTION		>
EC <		test	di, 1						>
EC <		ERROR_NZ INVALID_TRANSPORT_DRIVER_FUNCTION		>
		shl	di
		pushdw	cs:[spooltdFunctions][di]
		call	PROCCALLFIXEDORMOVABLE_PASCAL
done:		
		.leave
		ret
SpoolTDStrategy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTDDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return happiness

CALLED BY:	DR_INIT
		DR_EXIT
		DR_SUSPEND
		DR_UNSUSPEND
PASS:		nothing interesting
RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/26/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolTDDoNothing proc	far
		.enter
		clc
		.leave
		ret
SpoolTDDoNothing endp

Resident	ends
