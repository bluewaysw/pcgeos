COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trLargeNextPrev.asm

AUTHOR:		John Wedgwood, Feb 12, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/12/92	Initial revision

DESCRIPTION:
	Code to move between regions in a large object.

	$Id: trLargeNextPrev.asm,v 1.1 97/04/07 11:21:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextRegion	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the next region in a large object.

CALLED BY:	TR_RegionNext via CallRegionHandler
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		carry flag set if there is no next region
		carry flag clear otherwise
			zero flag clear (nz) if the next region is empty
			zero flag set    (z) otherwise
			cx	= Next region number
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionNext	proc	far
	uses	ax
	.enter
	call	PointAtRegionElement		;ds:di = data, z set if last
						;ax = element size
	stc
	jz	done
	
	inc	cx				;cx <- next region number

	;
	; Clear the zero flag if the next region is empty
	;
	test	ds:[di].VLTRAE_flags, mask VLTRF_EMPTY

	clc					;indicates region exists
done:
	.leave
	ret
LargeRegionNext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionIsLastInSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a region is the last in its section

CALLED BY:	TR_RegionIsLastInSection
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		carry set if region is last in section
		    zero set if the region is the last
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionIsLastInSection	proc	near
	uses	ax, bx, cx, dx, di, si
firstRegion local	word
objChunk    local	word
	.enter
	mov	objChunk, si
	mov	firstRegion, cx
	call	PointAtRegionElement		;ds:di = data, z set if last
						;ax = element size
	stc					;Assume it's the very last
	jz	quit				;Branch if very last
	
	;
	; It's not the very last region
	;
	mov	ax, cx				;ax <- current region
	mov	si, objChunk
	call	SetupForRegionScan		;ds:si <- first region
						;dx <- element size
						;cx <- region count
	
	sub	cx, ax				;cx <- regions after ds:di
	mov	si, di				;ds:si <- region pointer

	; Point back at the original element
	mov	bx, firstRegion
	xchg	cx, bx
	mov	si, objChunk
	call	PointAtRegionElement
	mov	si, di
	mov	dx, ax
	xchg	cx, bx
		
	;
	; ds:si	= Region
	; cx	= Regions after ds:si
	; dx	= Size of elements
	;
	call	IsLastRegionInSection		;carry set if last in section

quit:
	.leave
	ProfilePoint 22
	ret
LargeRegionIsLastInSection	endp

TextRegion	ends

TextFixed	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsLastRegionInSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure if a region is the last in its section.

CALLED BY:	Figure if a region is the last
PASS:		ds:si	= Region
		cx	= Number of regions after ds:si
		dx	= Size of region data
RETURN:		carry set if this is the last region in its section
		    zero set if the region is the last non-empty region
		      in the object
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsLastRegionInSection	proc	far
	uses	ax
	.enter
	cmp	cx, 1
	je	isLastInLast

	mov	ax, ds:[si].VLTRAE_section	; ax <- current section

	call	ScanToNextRegion		; ds:si <- next region

	test	ds:[si].VLTRAE_flags, mask VLTRF_EMPTY
	jnz	isLastInSection			; Zero clear if we branch

	;
	; The next region is not empty. Either it is or is not in the same
	; section as the current one.
	;
	cmp	ax, ds:[si].VLTRAE_section	; Compare sections
	jne	isLastInSection			; carry clear if we don't branch
	call	ScanToPrevRegion		 ; leave us at the same region
	clc
	;
	; The two adjoining regions are in the same section.
	;
	; Carry is clear here (which is correct, since this isn't the last 
	;    region in the section).
	;
quit:
	.leave
	ret

isLastInLast:
	;
	; It's the last region in the last section
	;
	clr	ax				; Z=1, Last in object
	stc					; C=1, Last in section
	jmp	quit

isLastInSection:
	;
	; We need to find out if this is the last section.
	;
	call	ScanToPrevRegion		; ds:si <- region to check
						; cx holds # after ds:si
						; dx holds size of data
	call	LargeRegionIsLastRegionInLastSection
						; carry set if last in last
	jc	isLastInLast
	
	;
	; It's the last region but not in the last section
	;
	or	ax, 1				; Z=0, Not last in object
	stc					; C=1, Is last in section
	jmp	quit

IsLastRegionInSection	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LargeRegionIsLastRegionInLastSection

DESCRIPTION:	Determine if this region is the last region (with text) in the
		last section

CALLED BY:	INTERNAL

PASS:
	ds:si - region
	cx - Number of regions after ds:si (including ds:si)
	dx - Size of region data

RETURN:
	carry - set if this is the last region in the last section

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/27/92		Initial version

------------------------------------------------------------------------------@
LargeRegionIsLastRegionInLastSection	proc	far	uses ax, bx, cx
	.enter

	call	SaveCachedRegion			;bx = cached region

	mov	ax, ds:[si].VLTRAE_section
	jmp	nextSection

findLoop:
	cmp	ax, ds:[si].VLTRAE_section		;next section ?
	clc
	jnz	done
	test	ds:[si].VLTRAE_flags, mask VLTRF_EMPTY	;clears carry
	jz	done
nextSection:
	dec	cx
	jz	atEnd
	call	ScanToNextRegion
	jmp	findLoop
atEnd:

	; no regions with text following -- this is the last

	stc
done:
	call	RestoreCachedRegion
	.leave
	ret

LargeRegionIsLastRegionInLastSection	endp

TextFixed	ends
