COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		clockRegion.asm

AUTHOR:		Adam de Boor, Feb  9, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/ 9/92		Initial revision


DESCRIPTION:
	Implementation of the ClockRegion functions.
		

	$Id: clockRegion.asm,v 1.1 97/04/04 14:50:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	clock.def

include Internal/grWinInt.def

ClockRegionCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CRCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin the creation of a ClockRegion.

CALLED BY:	EXTERNAL
PASS:		cx	= width of final region
		dx	= height of final region
RETURN:		di	= gstate through which to draw
		bx	= token to pass to CRDestroy
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CRCreate	proc	far
		uses	bp, cx, dx
		.enter
	;
	; Create a graphics state to no window and begin collecting a path
	; for it.
	; 
		clr	di
		call	GrCreateState
		mov	cx, PCT_REPLACE
		call	GrBeginPath
	;
	; Signal that path remains open.
	; 
		clr	ax
		call	GrSetPrivateData
	;
	; Set the null transformation as the default to allow the caller to
	; get back to this state "the right way"...
	; 
		call	GrInitDefaultTransform
		.leave
		ret
CRCreate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CREndPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the path for the gstate, if it's not closed already.

CALLED BY:	(INTERNAL) CRDestroy, CRConvert
PASS:		di	= gstate
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	path is closed. further drawing operations will go into space

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CREndPath	proc	near
		uses	bx, cx, dx
		.enter
	;
	; Close the path if not already closed.
	; 
		mov	ax, GIT_PRIVATE_DATA
		call	GrGetInfo		; ax <- non-zero if closed
		tst	ax
		jnz	done
		call	GrEndPath
	;
	; Flag path closed.
	; 
		mov	ax, TRUE
		call	GrSetPrivateData
done:
		.leave
		ret
CREndPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CRDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up a ClockRegion

CALLED BY:	EXTERNAL
PASS:		di	= gstate returned by CRCreate
		bx	= token returned by CRCreate
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CRDestroy	proc	far
		.enter
		call	CREndPath
		call	GrDestroyState
		.leave
		ret
CRDestroy	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CRParameterize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parameterize the passed coordinates, if appropriate. Also
		shift them so the upper-left of the region's bounding box
		is always (0,0) [(PARAM_0, PARAM_1) if parameterizing].

CALLED BY:	CRConvert
PASS:		ax	= X coord
		cx	= Y coord
		ds	= path's region, with Rectangle that is bounding
			  box at ds:0
		dx	= CRConvertMode
RETURN:		ax, cx	= parameterized if appropriate
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CRParameterize	proc	near
		.enter
	;
	; Shift so region is anchored at (0,0)
	; 
		sub	ax, ds:[R_left]
		sub	cx, ds:[R_top]

		test	dx, mask CRCM_PARAMETERIZE
		jz	done
		add	ax, PARAM_0
		add	cx, PARAM_1
done:
		.leave
		ret
CRParameterize	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CRConvert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a ClockRegion to a real region.

CALLED BY:	EXTERNAL
PASS:		ds	= lmem segment in which to allocate the region
		di	= gstate returned by CRCreate
		ax	= CRConvertMode
RETURN:		ax	= chunk handle of chunk that holds the region. The
			  region is always shifted so its bounding box is
			  anchored at (0,0) in its upper-left corner.
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CRConvert	proc	far
		uses	es, bx, di, si, cx, dx
		.enter
	;
	; Convert the path into a region.
	; 
		mov_trash	dx, ax	; save CRConvertMode
		call	CREndPath	; End the path, please
		mov	cl, RFR_ODD_EVEN
		call	GrGetPathRegion	; bx <- block
		LONG jc	createNullRegion
	;
	; Figure the number of bytes in the region definition
	; 
haveRegion:
		push	ds, dx, bx
		call	MemLock
		mov	ds, ax
		mov	si, size Rectangle	; skip bounding box
		call	GrGetPtrRegBounds	; si <- # bytes needed,
						;  plus bounding box
		pop	ds, dx, bx

		test	dx, mask CRCM_WITH_BOUNDING_BOX
		jnz	allocChunk
		sub	si, size Rectangle	; bounding box not needed, so
						;  remove from size
allocChunk:
	;
	; Allocate a chunk to hold the region.
	; 
		mov	cx, si			; cx <- size
		mov	ax, mask OCF_DIRTY
		call	LMemAlloc		; *ds:ax <- chunk
	;
	; Deref the locked region block again, after pointing es to the lmem
	; segment.
	; 
		segmov	es, ds
		call	MemDerefDS
		push	ax			; save for return
		mov_tr	di, ax
		mov	di, es:[di]		; es:di <- dest chunk

		test	dx, mask CRCM_WITH_BOUNDING_BOX
		jz	copyRegion
	;
	; Store a bounding box, parameterizing it, if necessary.
	; 
		mov	ax, ds:[R_left]
		mov	cx, ds:[R_top]
		call	CRParameterize
		mov	es:[di].R_left, ax
		mov	es:[di].R_top, cx
		
		mov	ax, ds:[R_right]
		mov	cx, ds:[R_bottom]
		call	CRParameterize
		mov	es:[di].R_right, ax
		mov	es:[di].R_bottom, cx
		add	di, size Rectangle
copyRegion:
	;
	; Now copy the coordinates of the region from the block to the chunk,
	; parameterizing and shifting them as we go.
	; 
		mov	si, size Rectangle
scanLoop:
		lodsw				; ax <- Y coord of scanline
		cmp	ax, EOREGREC		; end of definition?
		je	regionCopied
		mov_tr	cx, ax
		call	CRParameterize
		mov_tr	ax, cx
		stosw
pairLoop:
		lodsw				; ax <- first X coord
		cmp	ax, EOREGREC		; end of line?
		je	scanDone		; yes
		call	CRParameterize		; no -- parameterize/shift
		stosw				;  and store
		lodsw				; ax <- 2nd X coord
		call	CRParameterize		; parameterize/shift
		stosw				;  and store
		jmp	pairLoop
scanDone:
		stosw				; store EOREGREC...
		jmp	scanLoop		; ...and go to next line

regionCopied:
	;
	; Free the block we got back from GrGetPathRegion
	; 
		stosw				; store final EOREGREC
		call	MemFree

		segmov	ds, es			; return ds fixed up
		pop	ax			; *ds:ax <- chunk

		.leave
		ret

createNullRegion:
		mov	ax, size Rectangle + size word
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
		mov	es, ax
		clr	ax
		mov	es:[R_left], ax
		mov	es:[R_top], ax
		mov	es:[R_right], ax
		mov	es:[R_bottom], ax
		mov	{word}es:[size Rectangle], EOREGREC
		call	MemUnlock
		jmp	haveRegion
CRConvert	endp

ClockRegionCode	ends
