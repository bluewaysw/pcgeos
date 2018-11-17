COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlLargeUtils.asm

AUTHOR:		John Wedgwood, Feb  3, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/ 3/92	Initial revision

DESCRIPTION:
	Misc utilities for large objects.

	$Id: tlLargeUtils.asm,v 1.1 97/04/07 11:20:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeGetLineArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the huge-array of lines.

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
RETURN:		di	= Line array
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeGetLineArray	proc	far
	class	VisTextClass

	call	TextFixed_DerefVis_DI	; ds:di <- vis instance
	mov	di, ds:[di].VTI_lines	; di <- line-array
	ret
LargeGetLineArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeGetLinePointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pointer to a line for a large object.

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
		bx.di	= Line
RETURN:		es:di	= Pointer to the line
		cx	= Size of the line/field data
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeGetLinePointer	proc	far
	uses	ax, bx, dx, si, ds
	.enter

	movdw	dxax, bxdi		; dx.ax <- line
	call	LargeGetLineArray	; di <- line-array

	call	T_GetVMFile		; bx = VM file handle

	call	HugeArrayLock		; ds:si <- ptr to element
EC <	tst	ax							>
EC <	ERROR_Z	PASSED_OFFSET_DOES_NOT_EXIST_IN_HUGE_ARRAY		>
					; dx <- size of element
					; ax <- # after
					; cx <- # before
	mov	cx, dx			; cx <- size of element
	segmov	es, ds, di		; es:di <- ptr to element
	mov	di, si
	.leave
	ret
LargeGetLinePointer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeReleaseLineBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the block containing a given line.

CALLED BY:	Utility
PASS:		es	= Segment address of block to release
RETURN:		nothing
DESTROYED:	nothing (not even flags)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeReleaseLineBlock	proc	far
	uses	ds
	.enter
	segmov	ds, es
	call	HugeArrayUnlock			;preserves the flags
	.leave
	ret
LargeReleaseLineBlock	endp


TextFixed	ends
