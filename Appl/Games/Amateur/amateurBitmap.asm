COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		amateurBitmap.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/25/92   	Initial version.

DESCRIPTION:
	

	$Id: amateurBitmap.asm,v 1.1 97/04/04 15:12:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@





COMMENT @----------------------------------------------------------------------

FUNCTION:	HackApp_RelocOrUnReloc -- MSG_RELOCATE

DESCRIPTION:	We must intercept this method to relocate all of the
		handles to moniker lists that we have.

PASS:		*ds:si		= instance data

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

HackApp_RelocOrUnReloc	proc	near

	; Set BP non-zero if unrelocating.

	clr	bp		; Assume we're relocating
	cmp	ax, MSG_META_RELOCATE
	je	10$		; yup

	inc	bp		; wrong

10$:	;find our list of Moniker Lists

	mov	di, offset listOfMonikerLists
						;*ds:di = list of moniker lists
	mov	di, ds:[di]			;*ds:di = list of moniker lists

	ChunkSizePtr	ds, di, dx		;dx = size

20$:	;for each chunk handle in the list, relocate/unrelocate that
	;MonikerList.

	push	dx, di
	mov	bx, ds:[di]			;*ds:bx = VisualMoniker
						;or VisualMonikerList

	mov	cx, ds:[bx]			;ds:cx = Moniker List
	jcxz	clearEntryInList		;skip if so...

	cmp	cx, -1
	je	nextEntry

	mov	di, cx				;ds:di = Moniker List
	test	ds:[di].VM_type, mask VMT_MONIKER_LIST	;is it a list?
	jz	nextEntry			;skip to end if not...

	;walk through this VisualMonikerList, updating the OD's which point
	;to VisualMonikers.

	mov	bx, ds:[LMBH_handle]		;bx = handle of block
	ChunkSizePtr ds, di, cx			;cx -> size of list (in bytes)

relocEntry:
	push	cx
	mov	cx, ds:[di].VMLE_moniker.handle	;relocate the handle
	call	HackRelocOrUnRelocHandle	;uses bp flag to decide
						;whether to reloc or unreloc.
	mov	ds:[di].VMLE_moniker.handle,cx
	pop	cx
	jc	nextEntry

	add	di,size VisMonikerListEntry
	sub	cx,size VisMonikerListEntry
	jnz	relocEntry

nextEntry:
	pop	dx, di
	add	di, size word
	sub	dx, size word
	jnz	20$

	ret


clearEntryInList:
	mov	{word} ds:[di], 0		;Else, clear out the chunk
						;handle in the list.
	jmp	nextEntry
HackApp_RelocOrUnReloc	endp


HackRelocOrUnRelocHandle	proc	near
	mov	al, RELOC_HANDLE
	tst	bp
	jnz	un

	call	ObjDoRelocation
	jmp	exit

un:
	call	ObjDoUnRelocation
exit:
	ret
HackRelocOrUnRelocHandle	endp








COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawMonikerCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a moniker for the current vis object

CALLED BY:	DrawBlasterCommon, ClownDraw

PASS:		bx - chunk handle of moniker
		*ds:si - instance data of object to draw for
		ss:bp - DrawMonikerArgs (xInset and yInset filled in)
		
RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawMonikerCommon	proc near

		uses	es, di, cx, ax

locals	local	DrawMonikerArgs

		.enter	

		clr	locals.DMA_xInset
		clr	locals.DMA_yInset

		mov	ax, es:[gstate]
		mov	locals.DMA_gState, ax

		segmov	es, ds, di
		mov	cx, ( J_LEFT shl offset DMF_X_JUST) or \
			( J_LEFT shl offset  DMF_Y_JUST )

		; So that CGA icons show up:
		mov	di, locals.DMA_gState
		mov	ax, C_WHITE
		call	GrSetAreaColor

		mov	ss:[locals].DMA_xMaximum, MAX_COORD
		mov	ss:[locals].DMA_yMaximum, MAX_COORD
		clr	ss:[locals].DMA_textHeight
		
		push	bp
		lea	bp, ss:[locals]
		call	VisDrawMoniker
		pop	bp

		.leave
		ret
DrawMonikerCommon	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindMonikers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a VisFindMoniker on all the  monikers

CALLED BY:

PASS:		ds - GameObjects
		es - dgroup

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,ds,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindMonikers	proc near
	.enter

	mov	cx, ds:[LMBH_handle]
	mov	bh, es:[displayType]	; for VisFindMoniker

	;for each moniker list in our animation sequence, resolve that
	;moniker list to be just the one moniker which is correct for
	;this display type.

	mov	di, offset listOfMonikerLists
	ChunkSizeHandle ds, di, ax	;set ax = size of chunk
	clr	bp			;start with first item in list

startLoop:	;for each moniker list in the list, get its OD

	push	ax, bp
	mov	di, offset listOfMonikerLists
	mov	di, ds:[di]		;ds:di = listOfMonikerLists list
					;(may have moved since last time
					;through this loop)

	mov	di, ds:[di][bp]		;*ds:di = Moniker List(N)

	mov	bp, mask VMSF_GSTRING or \
		    mask VMSF_REPLACE_LIST
					;(GString: standard size and color,
					;unless DisplayType dictates otherwise.)
	call	VisFindMoniker		;does not trash ax, bx, bp
	pop	ax, bp

	add	bp, size word
	sub	ax, size word
	jnz	startLoop			;loop if not done...

	.leave
	ret
FindMonikers	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapSetPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= BitmapClass object
		ds:di	= BitmapClass instance data
		es	= Segment of BitmapClass.

		ss:bp - BitmapPositionParams

RETURN:		nothing 

DESTROYED:	cx,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapSetPosition		method	dynamic	BitmapClass, 
					MSG_VIS_SET_POSITION
	uses	ax
	.enter

	call	VisGetSize		; cx, dx = size

	; Set left 

	mov	ax, ss:[bp].BPP_curPos
	mov	ds:[di].VI_bounds.R_left, ax
	add	ax, cx
	mov	ds:[di].VI_bounds.R_right, ax
	
	; Set top and bottom

	mov	ax, ss:[bp].BPP_viewHeight
	mov	ds:[di].VI_bounds.R_bottom, ax
	sub	ax, dx
	mov	ds:[di].VI_bounds.R_top, ax

	; curPos = curPos + objWidth + distBetween

	add	cx, [bp].BPP_distBetween
	add	ss:[bp].BPP_curPos, cx
	clc	
	.leave
	ret
BitmapSetPosition	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapResizeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the size of the bitmap object

CALLED BY:

PASS:		cx, dx - width/height to set
		ds:di - bitmap object

RETURN:		width added to BP

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapResizeCommon	proc near
	uses	ax,bx
	class	BitmapClass
	.enter


	add	bp, cx			; sum of all widths

	mov	ax, ds:[di].VI_bounds.R_left
	mov	bx, ds:[di].VI_bounds.R_top
	add	ax, cx
	add	bx, dx
	mov	ds:[di].VI_bounds.R_right, ax
	mov	ds:[di].VI_bounds.R_bottom, bx
	clc
	.leave
	ret
BitmapResizeCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapCheckCloud
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= BitmapClass object
		ds:di	= BitmapClass instance data
		es	= Segment of BitmapClass.
		cx, dx  = center of cloud

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	set 

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapCheckCloud	method	dynamic	BitmapClass, 
					MSG_BITMAP_CHECK_CLOUD
	uses	cx,dx
	.enter

	; check Y-coordinates

	add	dx, MAX_CLOUD_SIZE/2
	cmp	dx, ds:[di].VI_bounds.R_top
	jl	done

	add	cx, MAX_CLOUD_SIZE/2
	cmp	cx, ds:[di].VI_bounds.R_left
	jl	done

	sub	cx, MAX_CLOUD_SIZE
	cmp	cx, ds:[di].VI_bounds.R_right
	jg	done


	ornf	ds:[di].BI_state, mask BS_INVALID
done:
	.leave
	ret
BitmapCheckCloud	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= BitmapClass object
		ds:di	= BitmapClass instance data
		es	= Segment of BitmapClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapDraw	method	dynamic	BitmapClass, 
					MSG_VIS_DRAW

	.enter	 
	andnf	ds:[di].BI_state, not mask BS_INVALID
	mov	bx, ds:[di].BI_moniker
	call	DrawMonikerCommon
	clc
	.leave
	ret
BitmapDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapDrawAlt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= BitmapClass object
		ds:di	= BitmapClass instance data
		es	= Segment of BitmapClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapDrawAlt	method	dynamic	BitmapClass, 
					MSG_BITMAP_DRAW_ALT

	.enter	inherit 
	mov	bx, ds:[di].BI_altMoniker
	call	DrawMonikerCommon
	.leave
	ret
BitmapDrawAlt	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapDrawIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= BitmapClass object
		ds:di	= BitmapClass instance data
		es	= Segment of BitmapClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapDrawIfNeeded	method	dynamic	BitmapClass, 
					MSG_BITMAP_DRAW_IF_NEEDED
	.enter
	test	ds:[di].BI_state, mask BS_INVALID
	jz	done
	mov	ax, MSG_VIS_DRAW
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
BitmapDrawIfNeeded	endm

