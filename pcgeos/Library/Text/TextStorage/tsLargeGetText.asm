COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsLargeGetText.asm

AUTHOR:		John Wedgwood, Nov 25, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/25/91	Initial revision

DESCRIPTION:
	Support for getting text from a large text object.

	$Id: tsLargeGetText.asm,v 1.1 97/04/07 11:22:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextStorageCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeGetTextRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy text from a large text object.

CALLED BY:	TS_GetTextRange via CallStorageHandler
PASS:		*ds:si	= instance ptr
		ss:bx	= VisTextRange filled in
		ss:bp	= TextReference filled in
RETURN:		dx.ax	= Number of chars copied
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeGetTextRange	proc	far
	class	VisTextClass
textReference	local	word		push	bp
vmfile		local	word
charsLeft	local	dword
	uses	bx, cx, di, si, bp, ds
	.enter
	;
	; Get the huge-array block
	;
	push	bx
	call	T_GetVMFile			;bx = file
	mov	vmfile, bx
	pop	bx
	call	TextStorage_DerefVis_DI		; ds:di <- instance ptr
	mov	di, ds:[di].VTI_text		; di <- huge-array block
	
	movdw	dxax, ss:[bx].VTR_start		; dx.ax <- start
	mov	cx, ss:[bx].VTR_end.high	; cx.bx <- count
	mov	bx, ss:[bx].VTR_end.low

	subdw	cxbx, dxax			; cx.bx <- Number to copy
	movdw	charsLeft, cxbx			; Save count
	pushdw	cxbx	
;-----------------------------------------------------------------------------
	clrdw	cxbx				; Start at the start
appendLoop:
	tstdw	charsLeft			; Check for nothing left
	jz	endLoop				; Branch if nothing left

	;
	; cx.bx	= Place to append text in output (char offset)
	; charsLeft = Number of bytes left to append
	;
	; di	= Huge-array
	; dx.ax	= Position in the text object to get text from
	;
	push	ax, dx, bp			; Save pos, frame
	push	cx				; Save destPos.high
	push	bx
	mov	bx, vmfile
	call	HugeArrayLock			; ds:si <- ptr to text
EC <	tst	ax							>
EC <	ERROR_Z	PASSED_OFFSET_DOES_NOT_EXIST_IN_HUGE_ARRAY		>
	pop	bx				; ax <- # after position
						; cx <- # before position
						; dx <- element size (1)
	;
	; We want to use the minimum of "charsLeft" and ax as the number
	; of bytes to append.
	;
	tst	charsLeft.high			; Check for >64K
	jnz	gotAppendSize			; Branch if it is
	cmp	ax, charsLeft.low		; Check for got less than we want
	jbe	gotAppendSize			; Branch if we do
	mov	ax, charsLeft.low		; ax <- # to copy
gotAppendSize:
	pop	cx				; Restore destPos.high
	
	mov	bp, textReference		; ss:bp <- text reference
	;
	; ds:si	= Pointer to text to copy
	; ax	= Number of chars to copy after ds:si
	; cx.bx	= Offset to write to in output TextReference (char offset)
	; ss:bp	= TextReference to write to
	;
	call	AppendFromPointerToTextReference
	mov	si, ax				; si <- # of chars copied

	call	HugeArrayUnlock			; Release the text
	pop	ax, dx, bp			; Restore pos, frame

	;
	; Update the position in the source and dest.
	;
	add	ax, si				; Update source (in chars)
	adc	dx, 0
	
	add	bx, si				; Update destination (in chars)
	adc	cx, 0
	
	;
	; Update the number of bytes left
	;
	sub	charsLeft.low, si
	sbb	charsLeft.high, 0
	
	jmp	appendLoop
;-----------------------------------------------------------------------------
endLoop:
	popdw	dxax			;Restore # bytes copied
	.leave
	ret
LargeGetTextRange	endp


TextStorageCode	ends
