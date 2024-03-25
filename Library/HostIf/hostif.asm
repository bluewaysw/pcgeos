COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2023 -- All Rights Reserved

PROJECT:	Host Interface Library
FILE:		hostif.asm

AUTHOR:		Falk Rehwagen, Dec 21, 2023

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	fr	12/21/23	Initial revision

DESCRIPTION:
	

	$Id: hostif.asm,v 1.1 97/04/05 01:06:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include ec.def
include heap.def
include geode.def
include resource.def
include library.def
include ec.def
include vm.def
include dbase.def

include object.def
include graphics.def
include thread.def
include gstring.def
include Objects/inputC.def

include Objects/winC.def

DefLib hostif.def

HOST_API_INTERRUPT 	equ 	0xA0


Code	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfDetect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if host side API is available and in case it is
		what version is supported.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		ax - interface version, 0 mean no host interface found
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	12/21/23   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

.ioenable

	SetGeosConvention

baseboxID	byte 	"XOBESAB1"

HostIfDetect	proc	far

	;	
	; Check host call if SSL interface is available
	;
		uses	cx, dx, si

		.enter

		mov	si, 0
		mov	cx, 9
		mov	ah, cs:baseboxID[si]
next:
		mov	dx, 38FFh
		in	al, dx
		dec	cx

		cmp	al, ah
		je	start
		cmp	cx, 0
		jne	next
		je	error
start:
		mov	cx, 7
nextCompare:
		inc	si
		mov	ah, cs:baseboxID[si]
		mov	dx, 38FFh
		in	al, dx
		cmp	al, ah
		jne	error
		dec	cx
		cmp	cx, 0
		jne	nextCompare

		; matched 8 chars
		mov	dx, 38FFh
		in	al, dx
		clr	ah		
done:
		.leave
		ret
		
error:
		mov	ax, 0
		jmp    done

HostIfDetect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfDetect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if host side API is available and in case it is
		what version is supported.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		ax - interface version, 0 mean no host interface found
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	12/21/23   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HOSTIFDETECT	proc	far
		GOTO	HostIfDetect
HOSTIFDETECT	endp

HostIfCall	proc	far
		int	HOST_API_INTERRUPT
		ret
HostIfCall	endp

HOSTIFCALL		proc	far	func:word, 
					data1:dword, 
					data2:dword, 
					data3:word	
		uses	di, si, cx, bx

		.enter
		
		mov	di, data3
		mov	dx, data2.high
		mov	cx, data2.low
		mov	bx, data1.high
		mov	si, data1.low

		mov	ax, func
		
		int	HOST_API_INTERRUPT

		.leave
		
		ret

HOSTIFCALL		endp

	SetDefaultConvention

Code	ends


