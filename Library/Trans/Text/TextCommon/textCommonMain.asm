COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Translation Libraries
FILE:		textCommonMain.asm

AUTHOR:		Jenny Greenwood, 9 July 1992

ROUTINES:
	Name				Description
	----				-----------
	TextCommonScram			Jumps out of MasterSoft code
					back to TextCommonImport or
					TextCommonExport	
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/9/92		Initial version

DESCRIPTION:

	$Id: textCommonMain.asm,v 1.1 97/04/07 11:29:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Uninitialized data
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

; Our thread's semaphore, as we are not re-entrant, plus the
; address to jump back to and the stack pointer and TPD_stackBot
; value to restore in case of error while executing the MasterSoft
; code.

udata		segment
		threadSem		hptr
		returnAddr		nptr
		returnTPD_stackBot	nptr
		returnStackPtr		nptr
udata		ends


TextCommonCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCommonScram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C DECLARATION:	extern _void _pascal TextCommonScram(word transError);

SYNOPSIS:	Jumps out of MasterSoft code back to TextCommonImport
		or TextCommonExport

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jenny	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextCommonScram	proc	far
	pop	ax, bx			; throw out return address
	pop	ax			; ax <- TransError
	mov	bx, ds:[returnTPD_stackBot]
	mov	ss:[TPD_stackBot], bx
	mov	sp, ds:[returnStackPtr]
	jmp	ds:[returnAddr]
TextCommonScram	endp

TextCommonCode	ends
