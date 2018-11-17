COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trLargeGet.asm

AUTHOR:		John Wedgwood, Feb 12, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/12/92	Initial revision

DESCRIPTION:
	Code for getting information about regions in large objects.

	$Id: trLargeGet.asm,v 1.1 97/04/07 11:21:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextRegion	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionGetTopLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the top line of a region in a large object.

CALLED BY:	TR_GetTopLine via CallRegionHandlers
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		bx.di	= Top line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionGetTopLine	proc	near
	ProfilePoint 40
	.enter
	call	FindLineByRegion
	.leave
	ProfilePoint 38
	ret

LargeRegionGetTopLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FetchCachedRegionIfLower
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the cached line position and region pair if that
		region is lower or equal than the passed region.  If not
		valid, return line 0 and region 0.

CALLED BY:	FindLineByRegion
PASS:		*ds:si	= Instance
		cx	= Region to compare if higher.
RETURN:		bp.di	= Top line of cached region
		cx	= Cached region index
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	  Date		Description
	----	  ----		-----------
	lshields  4/19/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FetchCachedRegionIfLower proc near
	uses ax, bx, si
        .enter

	mov	ax, ATTR_VIS_LARGE_TEXT_LOCAL_LINE_AND_CHAR_COUNT
	call	ObjVarFindData
	jnc	notFound2

	mov	ax, ds:[bx].VLTCLACC_lineRegionIndex
	cmp	cx, ax
	jb	notFound1
	mov_tr	cx, ax
	movdw	bpdi, ds:[bx].VLTCLACC_lineSum
	jmp	done
notFound1:
	mov	ax, ds:[bx].VLTCLACC_prevLineRegionIndex
	cmp	cx, ax
	jb	notFound2
	mov_tr	cx, ax
	movdw	bpdi, ds:[bx].VLTCLACC_prevLineSum
	jmp	done
notFound2:
	clrdw	bpdi
	clr	cx
done:
	.leave
        ret
FetchCachedRegionIfLower endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreCachedRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Records the region index and first line pair for future
		calls to FetchCachedRegionIfLower

CALLED BY:	FindLineByRegion
PASS:		*ds:si	= Instance
		cx	= Region index to store
		bp.di	= Top line to pair with region
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	  Date		Description
	----	  ----		-----------
	lshields  4/19/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreCachedRegion proc near
	uses ax, bx, cx
	.enter
	pushf

	mov	ax, ATTR_VIS_LARGE_TEXT_LOCAL_LINE_AND_CHAR_COUNT
	call	ObjVarFindData
	jnc	notFound

	cmp	cx, ds:[bx].VLTCLACC_lineRegionIndex
	je	justStore

	; Copy over the current line to the previous line (if it is something)
	mov	ax, ds:[bx].VLTCLACC_lineRegionIndex
	cmp	ax, -1
	je	justStore
	mov	ds:[bx].VLTCLACC_prevLineRegionIndex, ax
	movdw   ds:[bx].VLTCLACC_prevLineSum, ds:[bx].VLTCLACC_lineSum, ax

justStore:
        ; Store the new values
	mov	ds:[bx].VLTCLACC_lineRegionIndex, cx
	movdw	ds:[bx].VLTCLACC_lineSum, bpdi
notFound:
	popf
	.leave
	ret
StoreCachedRegion endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FetchCachedLineToRegionIfLower
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the cached line position and region pair if the 
		cached line position is lower or equal than the passed line.  
		If not, return line 0 and region 0.

CALLED BY:	LargeRegionFromLine
PASS:		*ds:si	= Instance
		bx.di	= Top line to compare against cached value
RETURN:		bx.di	= Cached top line, or 0
		cx	= Cached region index, or 0
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	  Date		Description
	----	  ----		-----------
	lshields  4/19/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FetchCachedLineToRegionIfLower proc far
	uses ax, bx, si
        .enter

	mov	ax, ATTR_VIS_LARGE_TEXT_LOCAL_LINE_AND_CHAR_COUNT
	call	ObjVarFindData
	jnc	notFound

	mov	ax, ds:[bx].VLTCLACC_lineToRegionRegionIndex
	cmp	ax, -1
	je	notFound

	cmpdw	bxdi, ds:[bx].VLTCLACC_lineToRegionSum
	jb	notFound

	mov_tr	cx, ax
	movdw	bxdi, ds:[bx].VLTCLACC_lineToRegionSum
	jmp	done
notFound:
	clrdw	bxdi
	clr	cx
done:
	.leave
        ret
FetchCachedLineToRegionIfLower endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreCachedRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Records the region index and first line pair for future
		calls to FetchCachedLineToRegionIfLower

CALLED BY:	LargeRegionFromLine
PASS:		*ds:si	= Instance
		cx	= Region index to store
		bx.di	= Top line to pair with region
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	  Date		Description
	----	  ----		-----------
	lshields  4/19/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreCachedLineToRegion proc far
	uses ax, bx, cx
	.enter
	pushf
	mov	ax, ATTR_VIS_LARGE_TEXT_LOCAL_LINE_AND_CHAR_COUNT
	call	ObjVarFindData
	jnc	notFound

	mov	ds:[bx].VLTCLACC_lineToRegionRegionIndex, cx
	movdw	ds:[bx].VLTCLACC_lineToRegionSum, bxdi
notFound:
	popf
	.leave
	ret
StoreCachedLineToRegion endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FetchCachedLineToRegionIfLower
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the cached line position, character position, and
		region if the cached line position is lower or equal than 
		the passed line.  

		If not, return all zeros.

CALLED BY:	LargeRegionFromLineGetStartLineAndOffset
PASS:		*ds:si	= Instance
		bx.dx	= Top line to compare against cached value
RETURN:		ax.di	= Cached top line, or 0
		bx.cx	= Cached character position, or 0
		dx	= Cached region index, or 0
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	  Date		Description
	----	  ----		-----------
	lshields  4/19/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FetchCachedRegionFromLine proc far
	uses si
	.enter

	push	bx
	mov	ax, ATTR_VIS_LARGE_TEXT_LOCAL_LINE_AND_CHAR_COUNT
	call	ObjVarFindData
	mov	si, bx
	pop	bx
	jnc	notFound

	mov	ax, ds:[si].VLTCLACC_regionFromLineRegionIndex
	cmp	ax, -1
	je	notFound

	cmpdw	bxdx, ds:[si].VLTCLACC_regionFromLineLineSum
	jb	notFound

	; Pull out the cached values
	movdw	axdi, ds:[si].VLTCLACC_regionFromLineLineSum
	movdw	bxcx, ds:[si].VLTCLACC_regionFromLineCharSum
	mov	dx, ds:[si].VLTCLACC_regionFromLineRegionIndex
	jmp	done

notFound:
	clrdw	bxcx
	clrdw	axdi
	clr	dx
done:
	.leave
	ret
FetchCachedRegionFromLine endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreCachedRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Records the region index, character offset, and first line 
		pair for future calls to FetchCachedRegionFromLine

CALLED BY:	LargeRegionFromLineGetStartLineAndOffset
PASS:		*ds:si	= Instance
		cx	= Region index to store
		bx.di	= Top line to pair with region
		dx.ax	= Character offset to pair with region
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	  Date		Description
	----	  ----		-----------
	lshields  4/19/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreCachedRegionFromLine proc far
	uses ax, si, cx
	.enter
	pushf
	push	bx, ax

	mov	ax, ATTR_VIS_LARGE_TEXT_LOCAL_LINE_AND_CHAR_COUNT
	call	ObjVarFindData
	jnc	notFound
	mov	si, bx
	pop	bx, ax

	; Store the cached values
	mov	ds:[si].VLTCLACC_regionFromLineRegionIndex, cx
	movdw	ds:[si].VLTCLACC_regionFromLineLineSum, bxdi
	movdw	ds:[si].VLTCLACC_regionFromLineCharSum, dxax
	jmp	done
notFound:
	pop	bx, ax
done:
	popf
	.leave
	ret
StoreCachedRegionFromLine endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FetchCachedRegionFromOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the cached line position, character position, and
		region if the cached character position is lower or equal
		than the passed character position.

		If not, return all zeros.

CALLED BY:	LargeRegionFromOffsetGetStartLineAndOffset
PASS:		*ds:si	= Instance
		dx.ax	= character position to compare against cached value
RETURN:		ax.di	= Cached top line, or 0
		bx.cx	= Cached character position, or 0
		dx	= Cached region index, or 0
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	  Date		Description
	----	  ----		-----------
	lshields  4/19/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FetchCachedRegionFromOffset proc far
	uses si
	.enter

	; locate our cached information
	push	ax, bx
	mov	ax, ATTR_VIS_LARGE_TEXT_LOCAL_LINE_AND_CHAR_COUNT
	call	ObjVarFindData
	mov	si, bx
	pop	ax, bx
	jnc	notFound

	; If nothing is cached, early out
	mov	dx, ds:[si].VLTCLACC_regionFromOffsetRegionIndex
	cmp	dx, -1
	je	notFound

	; If the offset is less than what we have, early out
	cmpdw	dxax, ds:[si].VLTCLACC_regionFromOffsetCharSum
	jb	notFound

	; Ok, good cached item.  Pull out the data
	movdw	bxcx, ds:[si].VLTCLACC_regionFromOffsetLineSum
	movdw	axdi, ds:[si].VLTCLACC_regionFromOffsetCharSum
	mov	dx, ds:[si].VLTCLACC_regionFromOffsetRegionIndex
	jmp	done

notFound:
	; If never found, clear out and start at the beginning
	clrdw	bxcx
	clrdw	axdi
	clr	dx
done:
	.leave
	ret
FetchCachedRegionFromOffset endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreCachedRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Records the region index, character offset, and first line 
		pair for future calls to FetchCachedRegionFromOffset
		in the text object.

CALLED BY:	LargeRegionFromOffsetGetStartLineAndOffset
PASS:		*ds:si	= Instance
		cx	= Region index to store
		bx.di	= Top line to pair with region
		dx.ax	= Character offset to pair with region
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	  Date		Description
	----	  ----		-----------
	lshields  4/19/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreCachedRegionFromOffset proc far
	uses ax, si, cx
	.enter
	pushf
	push	bx, ax
   jmp notFound  ; Turn off this optimization for now -- it's messing up a bunch of stuff.

	mov	ax, ATTR_VIS_LARGE_TEXT_LOCAL_LINE_AND_CHAR_COUNT
	call	ObjVarFindData
	jnc	notFound
	mov	si, bx
	pop	bx, ax

	; Store the cached values
	mov	ds:[si].VLTCLACC_regionFromOffsetRegionIndex, cx
	movdw	ds:[si].VLTCLACC_regionFromOffsetLineSum, bxdi
	movdw	ds:[si].VLTCLACC_regionFromOffsetCharSum, dxax
	jmp	done
notFound:
	pop	bx, ax
done:
	popf
	.leave
	ret
StoreCachedRegionFromOffset endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	FindLineByRegion

DESCRIPTION:	Given a region find its starting offset

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	cx - region number

RETURN:
	bxdi - line

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/19/92		Initial version

------------------------------------------------------------------------------@
FindLineByRegion    proc near
	tst cx
	je notZero
	dec cx
	call FindLineByRegionSub
	inc cx
notZero:
	call FindLineByRegionSub
	ProfilePoint 9
	ret
FindLineByRegion    endp

FindLineByRegionSub	proc	near
	.enter

	clrdw	bxdi
	jcxz	exit

	push	bp
	push	ax, cx, dx, si
	clr	bp				; bpdi = running count
	mov	ax, cx

	call	FetchCachedRegionIfLower
	; bp.di = line
	; cx = region

	sub	ax, cx
	push	ax
	call	NewSetupForRegionScan
	pop	ax				; ax = count to region Index position

	; ds:si = first region
	; dx = element size
	; ax = # regions until we hit the last one
	; bpdi = line counts up to this point

	tst	ax
	jz	done
countloop:
	adddw	bpdi, ds:[si].VLTRAE_lineCount
	dec	ax
	jz	done
	add	si, dx
	loop	countloop
	sub	si, dx
	call	NewScanToNextRegion
EC <	ERROR_Z	-1							>
	jmp	countloop
done:
	call	NewFinishRegionScan

	pop	ax, cx, dx, si
	call	StoreCachedRegion
	mov	bx, bp				; bxdi = count
	pop	bp
exit:

	.leave
	ret

FindLineByRegionSub	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeRegionGetStartOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the starting offset of a region in a large object.

CALLED BY:	TR_GetStartOffset via CallRegionHandlers
PASS:		*ds:si	= Instance
		cx	= Region
RETURN:		dx.ax	= Starting offset
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeRegionGetStartOffset	proc	near
	.enter
	call	FindOffsetByRegion
	.leave
	ret

LargeRegionGetStartOffset	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindOffsetByRegion

DESCRIPTION:	Given a region find its starting offset

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	cx - region number

RETURN:
	dxax - text offset

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/19/92		Initial version

------------------------------------------------------------------------------@
FindOffsetByRegion	proc	near
	.enter

	clrdw	dxax
	jcxz	exit

	push	bx, cx, si, di, bp
	push	cx
	clr	cx
	call	NewSetupForRegionScan
	pop	di				;di = count
	mov	bp, dx				;bp = size
	clr	dx				;dxax = 0

	; ds:si = first region
	; bp = element size

countloop:
	adddw	dxax, ds:[si].VLTRAE_charCount
	dec	di
	jz	done
	add	si, bp
	loop	countloop
	sub	si, bp
	call	NewScanToNextRegion
EC <	ERROR_Z	-1							>
	jmp	countloop
done:
	call	NewFinishRegionScan
	pop	bx, cx, si, di, bp
exit:

	.leave
	ProfilePoint 10
	ret

if 0 ; OLD

	push	cx
	call	SetupForRegionScan
	pop	cx
	mov	bx, dx

	; ds:si = first region
	; bx = element size

	clrdw	dxax
	jcxz	done

countloop:
	adddw	dxax, ds:[si].VLTRAE_charCount
	xchg	bx, dx
	call	ScanToNextRegion		; ds:si <- ptr to next region
	xchg	bx, dx
	loop	countloop

done:

endif

FindOffsetByRegion	endp


TextRegion	ends
