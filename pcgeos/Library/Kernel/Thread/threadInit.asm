COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Thread
FILE:		threadInit.asm

ROUTINES:
	Name		Description
	----		-----------
   EXT	InitThread	Initialize the thread module

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

DESCRIPTION:
	This module initializes the thread module.  See manager.asm for
documentation.

	$Id: threadInit.asm,v 1.1 97/04/05 01:15:13 newdeal Exp $

-------------------------------------------------------------------------------@



COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitThread

DESCRIPTION:	Initialize the thread module

CALLED BY:	INTERNAL
		StartGEOS

PASS:
	ds - kernel variable segment

RETURN:
	none

DESTROYED:
	ax, es, cx, dx, di, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

InitThread	proc	near

	test	ds:[sysConfig], mask SCF_UNDER_SWAT
	jnz	done
	
	;
	; Not running under swat, so catch all the exceptions listed in the
	; exceptions list.
	;
	LoadVarSeg	es, si
	mov	si, offset exceptions
	mov	cx, length exceptions

ifdef	CATCH_STACK_EXCEPTION
	cmp	ds:[sysProcessorType], SPT_80386
	jae	catchExceptions
	dec	cx		; don't catch stack exception for processors
				;  that don't produce it in real or V86 mode.
endif

	cmp	ds:[sysProcessorType], SPT_80286
	jae	catchExceptions
ifdef CATCH_PROTECTION_FAULT
	sub	cx, 2		; don't catch illegal instruction or protection
				;  violation for processors that don't produce
				;  them...
else
	dec	cx
endif

catchExceptions:
	mov	ds:[numExceptionsCaught], cx
exceptLoop:
	push	cx
	lodsw
	xchg	cx, ax		; cx <- offset of handler (1-byte inst)
	lodsw
	xchg	di, ax		; di <- offset of save vector (1-byte inst)
	lodsw
	mov	bx, kcode	; bx <- segment of handler
	call	SysCatchInterrupt
	pop	cx
	loop	exceptLoop

done:
	ret
InitThread	endp
	public	InitThread
