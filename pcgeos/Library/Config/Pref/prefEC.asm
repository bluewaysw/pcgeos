COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefEC.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/19/92   	Initial version.

DESCRIPTION:
	

	$Id: prefEC.asm,v 1.1 97/04/04 17:50:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckGenOptionsParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that ss:bp.GOP_key and ss:bp.GOP_category
		are valid ascii strings

CALLED BY:

PASS:		ss:bp - GenOptionsParams

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckGenOptionsParams	proc near
	uses	ds,si
	.enter
	pushf
	segmov	ds, ss, si
	lea	si, ss:[bp].GOP_key
SBCS <	call	ECCheckAsciiString					>
DBCS <	call	ECCheckAsciiStringSBCS					>
	lea	si, ss:[bp].GOP_category
SBCS <	call	ECCheckAsciiString					>
DBCS <	call	ECCheckAsciiStringSBCS					>
	popf
	.leave
	ret
ECCheckGenOptionsParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckAsciiString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that ds:si is a valid ascii string

CALLED BY:	utility

PASS:		ds:si - string to check

RETURN:		nothing 

DESTROYED:	nothing - flags preserved 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckAsciiString	proc near
	uses	ax,bx,cx,dx,si
	.enter

	pushf

	;
	; hack to determine if SBCS or DBCS string
	;
if DBCS_PCGEOS
	cmp	({word} ds:[si]).high, 0
	je	double
	;
	; SBCS string
	;
	mov	cx, PREF_ITEM_GROUP_STRING_BUFFER_SIZE
	clr	ah
10$:
	lodsb
	tst	al
	jz	done
	clr	bx, dx
	call	LocalIsDosChar
	ERROR_Z	ILLEGAL_ASCII_STRING
	loop	10$

	ERROR	ILLEGAL_ASCII_STRING
	.unreached
endif

DBCS <double:								>
	mov	cx, PREF_ITEM_GROUP_STRING_BUFFER_SIZE
SBCS <	clr	ah							>
startLoop:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	done
	clr	bx, dx
	call	LocalIsDosChar
	ERROR_Z	ILLEGAL_ASCII_STRING
	loop	startLoop

	ERROR	ILLEGAL_ASCII_STRING
done:
	popf
	.leave
	ret
ECCheckAsciiString	endp

if DBCS_PCGEOS
ECCheckAsciiStringSBCS	proc near
	uses	ax,bx,cx,dx,si
	.enter

	pushf

	;
	; SBCS string
	;
	mov	cx, PREF_ITEM_GROUP_STRING_BUFFER_SIZE
	clr	ah
10$:
	lodsb
	tst	al
	jz	done
	clr	bx, dx
	call	LocalIsDosChar
	ERROR_Z	ILLEGAL_ASCII_STRING
	loop	10$

	ERROR	ILLEGAL_ASCII_STRING
	.unreached

done:
	popf
	.leave
	ret
ECCheckAsciiStringSBCS	endp
endif

ECCheckAsciiStringDSBX	proc	near
	xchg	bx, si
	call	ECCheckAsciiString
	xchg	bx, si
	ret
ECCheckAsciiStringDSBX	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckBoundsESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the memory location ES:DI is writable and in
		bounds. 

CALLED BY:	

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckBoundsESDI	proc far
	uses	ds, si
	.enter

	segmov	ds, es
	mov	si, di
	call	ECCheckBounds


	.leave
	ret
ECCheckBoundsESDI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckPrefObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 2/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckPrefObject	proc near
		uses	es,di
		.enter

		pushf
		segmov	es, <segment PrefClass>, di
		mov	di, offset PrefClass
		call	ObjIsObjectInClass
		ERROR_NC	DS_SI_NOT_A_PREF_OBJECT
		popf


		.leave
		ret
ECCheckPrefObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckSrcDestMoveBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ECCheck that we ain't scribbling

CALLED BY:	?

PASS:		ds:si - source
		es:di - dest
		cx - # bytes to move

RETURN:		nothing 

DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	0
ECCheckSrcDestMoveBounds	proc far
		uses	si, di
		.enter
		
		pushf
		call	ECCheckBounds
		add	si, cx
		dec	si
		call	ECCheckBounds

		call	ECCheckBoundsESDI
		add	di, cx
		dec	di
		call	ECCheckBoundsESDI
		popf
		
		.leave
		ret
ECCheckSrcDestMoveBounds	endp
endif

