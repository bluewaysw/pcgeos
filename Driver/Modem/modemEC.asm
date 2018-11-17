COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
			
			GEOWORKS CONFIDENTIAL

PROJECT:	Socket
MODULE:		Modem Driver
FILE:		modemEC.asm

AUTHOR:		Jennifer Wu, Mar 15, 1995

ROUTINES:
	Name			Description
	----			-----------
	ECCheckCallerThread
	ECCheckMode	
	ECCheckClientStatus
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	3/15/95		Initial revision

DESCRIPTION:
	EC routines for modem driver.

	$Id: modemEC.asm,v 1.1 97/04/18 11:47:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckCallerThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the client is not calling the modem driver 
		with the modem driver's thread.

CALLED BY:	ModemSetNotify
		ModemDoCommand

PASS:		es	= dgroup

RETURN:		only if current thread is not the modem driver's thread

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/15/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckCallerThread	proc	near
		push	ax
		mov	ax, ss:[TPD_threadHandle]
		cmp	ax, es:[modemThread]
		ERROR_E	MODEM_DRIVER_CALLED_WITH_OWN_THREAD		
		pop	ax
		ret
ECCheckCallerThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the current mode is not data mode.

CALLED BY:	ModemDoDial
		ModemDoAnswerCall
		ModemDoReset
		ModemDoInitModem
		ModemDoAutoAnswer

PASS:		es	= dgroup

RETURN:		only if command is valid for current mode

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckMode	proc	near
		test	es:[modemStatus], mask MS_COMMAND_MODE
		ERROR_Z CANNOT_SEND_COMMAND_IN_DATA_MODE
		ret
ECCheckMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckClientStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure that we are not busy processing a prior command.
		Ensure that the client is registered.
		Ensure the port is the one used by the registered client.

CALLED BY:	ModemDoCommand
		ModemClose
		ModemSetNotify

PASS:		es	= dgroup
		bx	= port number

RETURN:		only if no errors

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/16/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckClientStatus	proc	near

		test	es:[modemStatus], mask MS_HAVE_CLIENT
		ERROR_E	MODEM_CLIENT_NOT_REGISTERED

		test	es:[modemStatus], mask MS_CLIENT_BLOCKED
		ERROR_NZ CANNOT_PROCESS_MULTIPLE_MODEM_COMMANDS

		cmp	bx, es:[portNum]
		ERROR_NE MODEM_CLIENT_USING_INVALID_PORT

		ret
ECCheckClientStatus	endp

CommonCode	ends







