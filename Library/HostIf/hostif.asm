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

COORDINATE_OVERFLOW				enum FatalErrors
; Some internal error in TransformInkBlock

udata	segment
udata	ends

idata	segment
idata	ends

Code	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine what the protocol # of the pen library is, so we
		know if we need to add our workarounds.

CALLED BY:	GLOBAL
PASS:		di - LibraryCallType
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HostIfEntry	proc	far
	.enter
	clc
	.leave
	ret
HostIfEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfDetect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine what the protocol # of the pen library is, so we
		know if we need to add our workarounds.

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

HOSTIFDETECT	proc	far
		GOTO	HostIfDetect
HOSTIFDETECT	endp

Code	ends


