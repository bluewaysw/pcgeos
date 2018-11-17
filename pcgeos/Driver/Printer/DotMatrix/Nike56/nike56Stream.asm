COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:        PC GEOS
MODULE:         Brother NIKE 56-jet print driver
FILE:           nike56Stream.asm

AUTHOR:         Dave Durran

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    10/94          Initial revision


DESCRIPTION:


        $Id: nike56Stream.asm,v 1.1 97/04/18 11:55:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterBIOSNoDMA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       call a printer BIOS routine

CALLED BY:      PRINT ROUTINES

PASS:		ah      - Function number of BIOS routine to execute
		others	- specific to routine

RETURN:		ax	=	Printer status flags
		carry set if error

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    10/94           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrinterBIOSNoDMA	proc	near
	int	17h		;actual printer BIOS call
	test	ax,mask PER_ACK	;see if we were successful in our command
	clc			;assume OK	
	jnz	exit
	stc
exit:
	ret
PrinterBIOSNoDMA	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterBIOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a printer BIOS routine and check trying if DMA is busy

CALLED BY:	PRINT ROUTINES
PASS:		ah      = Function number of BIOS routine to execute
		others	= specific to routine
RETURN:		ax	= Printer status flags
		carry set if error
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DMA_BUSY_FLAG	equ	02h

PrinterBIOS	proc	near
passedBP	local	word	push	bp
function	local	word	push	ax
dmaRetryCount	local	word
		.enter

		mov	ss:[dmaRetryCount], 120	;120 * 1/4 sec = 30 sec
callBIOS:
		push	bp
		mov	bp, ss:[passedBP]
		int	17h			;actual printer BIOS call
		pop	bp

		test	ax,DMA_BUSY_FLAG
		jz	dmaOK			;exit if DMA was not busy

		dec	ss:[dmaRetryCount]
		stc				;assume not OK
		jz	exit

		mov	ax, 15
		call	TimerSleep		;wait 1/4 second and try again

		mov	ax, ss:[function]
		jmp	callBIOS

dmaOK:
		test	ax,mask PER_ACK		;see if we were successful
		jnz	exit
		stc				;not OK
exit:
		.leave
		ret
PrinterBIOS	endp
