COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS (Network Extensions)
MODULE:		TELNET Library
FILE:		telnetCommand.asm

AUTHOR:		Simon Auyeung, Jul 19, 1995

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------
    INT TelnetExecIncomingCommand
				Execute a TelnetCommand initiated by remote
				connection

    INT TelnetSendCommandSocket	Send a TelnetCommand to a socket

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon		7/19/95   	Initial revision


DESCRIPTION:
	This file contains routines regarding Telnet commands.
		

	$Id: telnetCommand.asm,v 1.1 97/04/07 11:16:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetExecIncomingCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Execute a TelnetCommand initiated by remote connection

CALLED BY:	(INTERNAL) TelnetControlReadyStateHandler
PASS:		al	= TelnetCommand
		ds:dx	= TelnetInfo
RETURN:		bx	= TelnetStateType
		carry set if data should be returned to TelnetRecv
			immediately
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetExecIncomingCommand	proc	near
		uses	si
		.enter
EC <		Assert_fptr	dsdx					>
	;
	; If we are not in urgent data Scan mode, we just ignore any command.
	; When we need to handle incoming commands in the future, we should
	; handle them here.
	;
		BitTest	ds:[si].TI_status, TS_SYNCH_MODE
		jz	normal			; not in urgent mode
	;
	; It reaches urgent mode, we ignore any unsignificant commands:
	; If this is a DM command, we always clear discard-data flag.
	; In urgent mode, we should scan and handle all TelnetCommands except
	; EC and EL. Since we don't them any incoming command anyway, we just
	; ignore them.
	;
		cmp	al, TC_DM
		jne	contUrgent
		mov	si, dx			; dssi<-TelnetInfo
		BitClr	ds:[si].TI_status, TS_SYNCH_MODE
		jmp	normal			; back to normal

contUrgent:
		mov	bx, TST_CONTROL_READY
		jmp	done		
normal:
		mov	bx, TST_GROUND		; back to ground state
	
done:	
		clc
		
		.leave
		ret
TelnetExecIncomingCommand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TelnetSendCommandSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a TelnetCommand to a socket

CALLED BY:	(EXTERNAL) TelnetSendCommand
PASS:		bx	= Socket
		al	= TelnetCommand
RETURN:		carry set if error
			ax = TelnetError
		carry clear if no error
			ax = TE_NORMAL
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	switch (command) {
	case 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	8/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TelnetSendCommandSocket	proc	far
	bufToSend	local	TELNET_COMMAND_PACKET_SIZE dup (byte)
	command		local	TelnetCommand	
		uses	cx, ds, si
		.enter
EC <		Assert_socket	bx					>
%out	~~~~ TelnetSendCommandSocket: All TelnetCommands sent without interpretation and screening. ~~~~
	
		mov	ss:[command], al
	;
	; Just package and send the command
	;
sendCmd::
		segmov	ds, ss, cx
		lea	si, ss:[bufToSend]	; dssi <- bufToSend
		mov	{byte}ds:[si], TC_IAC	; Escape byte
		mov	ds:[si+1], al		; assign TelnetCommand
		clr	ax			; no SocketSendFlags
		mov	cx, size bufToSend
		call	TelnetSendSocket	; ax <- TelnetError
						; carry set if error
		jc	done		
	;
	; If the command requires Synch signal, send it.
	;
		pushf	
		TelnetIsCommandAssocSynch	ss:[command]
		jne	dontSendSynch

		popf				; restore stack
		call	TelnetSendSynch		; ax <- TelnetError
						; carry set if error
	;
	; If we are sending IP command, we need to send AO also to make sure
	; server returns a Synch signal to resume normal processing
	;
		cmp	ss:[command], TC_IP
		jne	done
		mov	al, TC_AO
		call	TelnetSendCommandSocket	; ax <- TelnetError
						; carry set if error
		jmp	done			; pass flags to caller
	
dontSendSynch:
		popf
	
done:
		.leave
EC <		Assert_TelnetErrorAndFlags	ax			>
		ret
TelnetSendCommandSocket	endp

CommonCode	ends
