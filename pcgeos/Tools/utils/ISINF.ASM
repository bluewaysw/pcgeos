COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		isinf.asm

AUTHOR:		Adam de Boor, April 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	isinf			See if the passed double is infinity,
				according to IEEE754 standards.
	isnan			See if the passed double is not-a-number,
				according to IEEE754 standards.
	caller			Return the caller's caller. Used by malloc()

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/26/91		Initial revision


DESCRIPTION:
	This file contains various functions that must be written in
	assembly when running under the DOS-Extender.
		

	$Id: ISINF.ASM,v 3.1 1996/08/07 05:00:42 ron Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_TEXT	segment	word public use32 'CODE'
CGROUP	group	_TEXT
assume cs:CGROUP

isinf	proc	near
	public	isinf
	push	ebp
	mov	ebp, esp
	xor	eax, eax
	cmp	dword ptr ss:[ebp+12], 0; low mantissa all zero?
	jne	isinf_done		; nope. not infinity
	cmp	dword ptr ss:[ebp+8], 07ff00000h	; positive infinity?
	je	isinf_yes
	cmp	dword ptr ss:[ebp+8], 0fff00000h	; negative infinity?
	jne	isinf_done		; no
isinf_yes:
	inc	eax
isinf_done:
	pop	ebp
	ret
isinf	endp

isnan	proc	near
	public	isnan
	push	ebp
	mov	ebp, esp
	xor	eax, eax		; assume no

	mov	edx, ss:[ebp+8]
	mov	ebx, edx
	and	edx, 7ff00000h
	cmp	edx, 7ff00000h
	jne	isnan_done		; exponent not 7ff => not NaN

	and	ebx, 0fffffh
	jne	isnan_yes		; mantissa of 0 is reserved for inf

	cmp	dword ptr ss:[ebp+12], 0; low mantissa m.b.non z. to be NaN
	je	isnan_done
isnan_yes:
	inc	eax
isnan_done:
	pop	ebp
	ret
isnan	endp

caller	proc	near	; return the caller's caller. This assumes the caller
			;  is near and has a frame pointer...
	public	caller
	mov	eax, ss:[ebp+4]
	ret
caller	endp

_TEXT	ends

end
