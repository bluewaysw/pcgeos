COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlSmallUtils.asm

AUTHOR:		John Wedgwood, Dec 31, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/31/91	Initial revision

DESCRIPTION:
	Misc small-object utilities.

	$Id: tlSmallUtils.asm,v 1.1 97/04/07 11:20:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallGetLineArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the line-array for a small object.

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
RETURN:		*ds:ax	= Line array
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallGetLineArray	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	TextFixed_DerefVis_DI	; ds:di <- instance ptr
	mov	ax, ds:[di].VTI_lines	; *ds:ax <- chunk array
	.leave
	ret
SmallGetLineArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallGetLinePointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer to a line for a small object.

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
		di	= Line
RETURN:		*ds:ax	= Chunk array
		ds:di	= Pointer to the line
		cx	= Size of the line/field data
		es	= ds
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallGetLinePointer	proc	far
	class	VisTextClass
	uses	si
	.enter
	mov	ax, di			; ax <- element
	call	TextFixed_DerefVis_DI	; ds:di <- instance ptr
	mov	si, ds:[di].VTI_lines	; *ds:si <- chunk array
	call	ChunkArrayElementToPtr	; ds:di <- element
					; cx <- size
					; carry set if no such element
	segmov	es, ds, ax		; es <- ds
	mov	ax, si			; *ds:ax <- chunk array

EC <	ERROR_C	LINE_DOES_NOT_EXIST				>
	.leave
	ret
SmallGetLinePointer	endp


TextFixed	ends
