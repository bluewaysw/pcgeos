COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		ffile.ldf
FILE:		ffmanagerManager.asm

AUTHOR:		Jeremy Dashe, Jan 24, 1992

ROUTINES:
	Name				Description
	----				-----------
	FlatFileEntry			Entry point for the flat file database
					library
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	1/24/92		Initial revision

DESCRIPTION:
	This file holds entry point code for the flat file database library.


	$Id: ffmanagerManager.asm,v 1.1 97/04/04 18:03:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def

InitCode        segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                FlatFileEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Library entry called when the flat file database library
		is loaded.

CALLED BY:
PASS:
RETURN:         carry clear
DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jeremy	1/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlatFileEntry    proc    far
        clc
        ret
FlatFileEntry    endp

ForceRef        FlatFileEntry

InitCode        ends
if 0
HorribleHack	segment resource

PrintMessage <Get rid of the ridiculous _mwpush8ss routine when>
PrintMessage <possible.>



SetGeosConvention
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwpush8ss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	push a  64 bit number from the stack segment 
		(i.e. a local variable) onto the stack

CALLED BY:	INTERNAL

PASS:		ss:cx = 64 bit number

RETURN:		Void.

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/16/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_mwpush8ss	proc	far

;	CX <- addr of float #

	; this code writes directly onto the stack
	; so it leaves a 64 bit float on the stack

	; es contains destination segment of the movsw
	; so es <- stack segment
	
	mov	ax, es
	mov	bx, ds

	mov	dx, ss
	mov	es, dx	
	mov	ds, dx	

	; now we allocate 4 bytes on the stack, the other four bytes
	; come from the four bytes taken by the return address

	sub	sp, 4	
	push	si		; save di and si 
	push	di
	mov	si, cx		; ds:si = 64 bit number
	mov	di, sp
	add	di, 4		; es:di = destination for 64 bit number

	; here we added 4 to di to make up for the pushing of
	; si and di above

	; so now we fill up the first four bytes with data

	movsw
	movsw

	; now we save away the return address sitting on the stack
	; and then write over the return address the remaining four bytes
	; of the 64 bit word (2 bytes at a time)

	mov	dx, es:[di]	;Load return addr
	movsw
	mov	cx, es:[di]
	movsw
	pop	di		;Restore old vals of si, di, es
	pop	si
	mov	es, ax		
	mov	ds, bx		
	push	cx		;Push return addr
	push	dx
	ret
_mwpush8ss	endp
	public _mwpush8ss

SetDefaultConvention
HorribleHack	ends
endif
