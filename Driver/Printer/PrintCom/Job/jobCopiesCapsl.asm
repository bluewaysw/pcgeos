
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Canon LBP CaPSL printer driver
FILE:		jobCopiesCapsl.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	12/92	initial version

DESCRIPTION:

	$Id: jobCopiesCapsl.asm,v 1.1 97/04/18 11:51:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEscSetCopies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the number of copies in the printer.

CALLED BY:	PrintEscSetCopies-GLOBAL
		PrintSetCopies-INTERNAL

PASS:		bp	- PSTATE segment address for PrintEscSetCopies.
		es	- PSTATE segment address for PrintSetCopies
		ax	- # of copies desired

RETURN:		ax	- # of copies set in printer.
		carry set if error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintEscSetCopies	proc	far
	push	es
	mov	es,bp		;es-->PState
	call	PrintSetCopies
	pop	es
	ret
PrintEscSetCopies	endp

PrintSetCopies	proc	near
	uses	ax, si
	cmp	ax,99		;see if ax is a legal value.
	jna	smallEnough
	mov	ax,99		;if not, set to closest legal value.
smallEnough:
	test	ax,ax		;see if 0
	jnz	bigEnough
	inc	ax		;if 0, then set to 1.
bigEnough:
	.enter
	mov     si,offset pr_codes_CSIcode
        call    SendCodeOut
        jc      exit
        call    HexToAsciiStreamWrite   ;send it.
        jc      exit
        mov     cl,'v'
        call    PrintStreamWriteByte
exit:
	.leave
	ret
PrintSetCopies	endp
