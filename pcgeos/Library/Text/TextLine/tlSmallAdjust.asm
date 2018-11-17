COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlSmallAdjust.asm

AUTHOR:		John Wedgwood, Jan  2, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/ 2/92	Initial revision

DESCRIPTION:
	Code for adjusting line and field offsets for a small text object.

	$Id: tlSmallAdjust.asm,v 1.1 97/04/07 11:20:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Text	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineAdjustForReplacement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust a range of lines after a change has been made.

CALLED BY:	TL_LineAdjustForReplacement via CallLineHandler
PASS:		*ds:si	= Instance ptr
		ss:bp	= VisTextReplaceParameters
RETURN:		bx.di	= First affected line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Since small objects have all their lines in one region we can just
	update all the lines after the one passed.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineAdjustForReplacement	proc	far
	uses	ax, si, bp
;-----------------------------------------------------------------------------
; Added 'object'  3/27/93 -jw
;	Needed by CommonLineAdjustForReplacementCallback so that it can
;	figure out if it is a large or small object so that it can dirty
;	the line-block appropriately.
;
object		local	dword
;-----------------------------------------------------------------------------
currentLine	local	dword
lineStart	local	dword
	.enter
	clrdw	lineStart		; Start at the start
	clrdw	currentLine
	movdw	object, dssi

	;
	; We Need:
	; bx:di	= Callback routine
	; *ds:si= Line array
	; ss:bp	= Stack frame
	;
	call	SmallGetLineArray	; *ds:ax <- line array
	mov	si, ax			; *ds:si <- line array

	mov	bx, cs
	mov	di, offset cs:CommonLineAdjustForReplacementCallback
	
	call	ChunkArrayEnum		; Do the update

	;
	; Set up the return value
	;
	movdw	bxdi, currentLine	; bx.di <- first changed line
	.leave
	ret
SmallLineAdjustForReplacement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineAdjustForReplacementCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust a line after replacement

CALLED BY:	Small/LargeLineAdjustForReplacement via ChunkArrayEnum
PASS:		*ds:si	= Line array
		ds:di	= Current line/field data
		ax	= Size of the line/field data
		ss:bp	= Inheritable stack frame
RETURN:		Carry set to abort
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineAdjustForReplacementCallback	proc	far
	class	VisTextClass
	uses	ax, cx, dx, es, ds, di, si
	.enter	inherit	SmallLineAdjustForReplacement

	segmov	es, ds, cx		; es:di <- line pointer
	mov	cx, ax			; cx <- size of data

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Added 3/27/93, -jw
	;
	; This routine modifies the line start and the line flags, nothing
	; else. We save the old line-start and flags so we can compare
	; them later.
	;
	mov	dl, es:[di].LI_count.WAAH_high
	mov	ax, es:[di].LI_count.WAAH_low
	push	dx, ax			; Save the count
	push	es:[di].LI_flags	; Save the flags
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

	movdw	dxax, lineStart		; dx.ax <- line start

	push	bp			; Save frame ptr
	mov	bp, ss:[bp]		; ss:bp <- VisTextReplaceParameters
	
	call	CommonLineAdjustForReplacement
					; dx.ax <- start of next line
					; Carry set if we can stop now
	pop	bp			; Restore frame ptr

	movdw	lineStart, dxax		; Save the next line start
	jc	quit			; Branch if all done
	;
	; We aren't all done. Check to see if the line falls in the affected
	; range.
	;
	jz	quit			; Branch if in affected area
	incdw	currentLine		; Update the current line
quit:
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; Added 3/27/93, -jw
;	This wasn't done before and the result was that changes to the start
;	or lines could occur, and then the block would be discarded because
;	it was clean.
;
	;
	; Check for any change in the count or the flags.
	;
	pop	cx			; cx <- old flags
	pop	dx, ax			; dl.ax <- old count
	
	pushf				; Save "abort enum" flag (carry)
	
	cmp	dl, es:[di].LI_count.WAAH_high
	jne	markDirty
	cmp	ax, es:[di].LI_count.WAAH_low
	jne	markDirty
	cmp	cx, es:[di].LI_flags
	je	notDirty

markDirty:
	;
	; Mark the block containing the line as dirty, but only for large
	; objects. For small objects, the only reason for calling this
	; routine is because text was inserted. This implies that the
	; block is dirty and that the lines, etc will be written out when
	; the thing shuts down to state.
	;
	movdw	dssi, object		; *ds:si <- instance
	call	Text_DerefVis_DI	; ds:di <- instance
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jz	notDirty

	;
	; It's a large object...
	; We use HugeArrayDirty to mark the block dirty.
	;
	call	MarkLineBlockDirty
	
notDirty:

	popf				; Restore "abort enum" flag (carry)
;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	.leave
	ret
CommonLineAdjustForReplacementCallback	endp

;-----------------------------------------------------------------------------
; Routines below added  3/27/93 -jw
;

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkLineBlockDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the block containing the line as dirty

CALLED BY:	CommonLineAdjustForReplacementCallback
PASS:		ds:di	= Instance ptr
		es	= Segment of the block to mark dirty
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/27/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkLineBlockDirty	proc	near
	uses	ds
	.enter
	segmov	ds, es			; ds <- segment address
	call	HugeArrayDirty		; Dirty the block
	.leave
	ret
MarkLineBlockDirty	endp



Text	ends
