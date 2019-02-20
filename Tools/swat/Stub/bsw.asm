COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Swat/Stub -- BSW Hardware Assist stuff
FILE:		bsw.asm

AUTHOR:		Adam de Boor, Jul 26, 1989

ROUTINES:
	Name			Description
	----			-----------
	BSW_Init		Initialize board and shift stub up
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	7/26/89		Initial revision


DESCRIPTION:
	Functions for the initialization and manipulation of the BSW
	Hardware Assist
		

	$Id: bsw.asm,v 2.2 92/04/13 00:13:11 adam Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_BSW		= 1
		
		include	stub.def

ifdef	BSW

stubInit	segment
		assume	cs:stubInit, ds:scode, es:scode, ss:sstack

BSW_ENABLE	=	00000b
BSW_BASE	=	0eh
BSW_ENABLE_PORT	=	31fh


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSW_Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the board and move the stub into it.

CALLED BY:	Main
PASS:		Nothing
RETURN:		CS	= board segment :)
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/26/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BSW_Init	proc	far
		;
		; Eventually, this should look for EMS cards and the like
		; and choose between d000 and e000 as the proper place to
		; go. For now, however, we just slap the thing to e000.
		;
		; This should also verify the board functions and decide
		; whether to move up there at all, or simply stay put.
		; XXX: Can that be done with the current macro stuff?
		; I don't think so. Perhaps a subroutine will be necessary.
		;
		mov	al, BSW_ENABLE or BSW_BASE
		mov	dx, BSW_ENABLE_PORT
		out	dx, al
		;
		; Copy all of ourselves up into stub RAM
		;
		mov	ax, BSW_BASE SHL 12
		mov	es, ax
		;
		; First reset the board
		;
		mov	es:stubRegisters.SR_control, SC_RESET
		jmp	short $+2
		;
		; Then disable everything, including write-protect.
		;
		mov	es:stubRegisters.SR_control, 0
		;
		; Now copy everything
		;
		mov	si, scode	; DS := scode as source segment
		mov	ds, si
		mov	cx, cs
		sub	cx, si		; CX = # paragraphs, want words
		shl	cx, 1		; * 2
		shl	cx, 1		; * 4
		shl	cx, 1		; * 8, CX now is # of words to copy
		clr	si		; All segment-aligned, so both
		mov	di, si		; SI and DI are 0
		rep	movsw

		;
		; Adjust SS, both now and in the variable used by SaveState,
		; to point into the RAM (AX still contains base). SP
		; stays the same (we copied the stack up too).
		;
		add	ax, sstack
		sub	ax, scode	; Just want offset from current base
					;  added to new base, thanks.
		mov	ss, ax
		mov	es:our_SS, ax

		;
		; Adjust return address to be up in the stub RAM
		;
		mov	bp, sp
		mov	[bp+2], es

		;
		; Adjust stubCode and kcodeSeg variables to reflect
		; reality, with the kernel actually getting loaded
		; over the old stub. Also change stubType to reflect that
		; stub is running in a working BSW Board
		;
		mov	es:stubCode, es
		mov	es:kcodeSeg, scode
		mov	es:stubType, STUB_BSW
		;
		; Return to Main in the stub RAM
		;
		ret
BSW_Init	endp

stubInit	ends

endif		; BSW

		end
