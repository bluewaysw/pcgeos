COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlSmallStorage.asm

AUTHOR:		John Wedgwood, Dec 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/26/91	Initial revision

DESCRIPTION:
	Routines for creating/destroying line and field storage in small
	text objects.

	$Id: tlSmallStorage.asm,v 1.1 97/04/07 11:21:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextInstance	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallStorageCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create line and field storage for a small text object.

CALLED BY:	TL_StorageCreate via CallLineHandler
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Allocate a single line and initialize it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallStorageCreate	proc	near
	class	VisTextClass
	uses	ax, bx, cx, di, es
	.enter
	;
	; Allocate a chunk-array.
	;
	push	si				; Save instance ptr
	mov_tr	ax, si
	call	ObjGetFlags			; al <- text-object flags.
	and	al, mask OCF_IGNORE_DIRTY
	clr	bx				; Variable sized elements
	clr	cx				; No extra header space
	mov	si, cx
	call	ChunkArrayCreate		; si <- chunk-array handle
	
	;
	; Allocate a single item that is the correct size
	;
	mov	ax, size LineInfo		; ax <- size to allocate
	call	ChunkArrayAppend		; ds:di <- ptr to element

	mov	ax, si				; ax <- chunk-array handle
	pop	si				; Restore instance ptr

	;
	; *ds:si= Instance ptr
	; ds:di	= Pointer to new element
	; ax	= Chunk handle of the line/field array
	;
	push	di				; Save element pointer
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; ds:di <- instance ptr
	mov	ds:[di].VTI_lines, ax		; Save the chunk array
	pop	di				; Restore element pointer
	
	;
	; Initialize the line and field.
	; *ds:si= Instance ptr
	; ds:di	= New element
	;
	segmov	es, ds, ax			; es:di <- line ptr
	call	CommonInitLineAndField		; Do the initialization
	.leave
	ret
SmallStorageCreate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallStorageDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy line and field storage for a small text object.

CALLED BY:	TL_StorageDestroy via CallLineHandler
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallStorageDestroy	proc	near
	class	VisTextClass
	uses	ax, di
	.enter
	call	TextLine_DerefVis_DI		; ds:di <- instance ptr
	mov	ax, ds:[di].VTI_lines		; ax <- chunk handle
	tst	ax				; Check for no storage
	jz	quit				; Branch if none

	call	ObjFreeChunk			; Remove the chunk-array
quit:
	.leave
	ret
SmallStorageDestroy	endp

TextInstance	ends

TextLineCalc	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert some number of lines into a small text object.

CALLED BY:	TL_LineInsert via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line to insert in front of
		dx.ax	= Number of lines to insert
RETURN:		bx.di	= First new line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineInsert	proc	far
	class	VisTextClass
	uses	ax, cx, si, bp, es
	.enter
	mov	di, cx				; bx.di <- line

	;
	; The number of lines to insert can't result in more than 64K of
	; lines.
	;
EC <	push	ax, bx, cx, dx
EC <	movdw	cxbx, dxax			; cx.bx <- # to insert	       >
EC <	call	SmallLineGetCount		; dx.ax <- # already existing  >
EC <	adddw	dxax, cxbx			; dx.ax <- final number	       >
EC <	tst	dx				; Check for >64K	       >
EC <	ERROR_NZ INSERT_COUNT_TOO_LARGE_FOR_SMALL_OBJECT		       >
EC <	pop	ax, bx, cx, dx						       >
	
	;
	; We are pretty sure we can insert the requested lines.
	;
	mov	bp, di				; Save first element

	push	ax				; Save number to insert

	call	SmallGetLineArray		; *ds:ax <- line array
	mov	si, ax				; *ds:si <- chunk array

	mov	ax, di				; ax <- element number
	call	ChunkArrayElementToPtr		; ds:di <- element pointer
						; cx <- size of element
						; carry set if no such element
	pop	cx				; Restore number to insert

	mov	ax, size LineInfo		; Initialize this one
	
	jc	appendLoop			; Branch if we want to append

insertLoop:
	;
	; *ds:bx= Instance pointer
	; *ds:si= Chunk array
	; ds:di	= Element or end of array (if line-number == -1)
	; cx	= Number of elements to insert
	; ax	= Size of each element
	;
	call	ChunkArrayInsertAt		; ds:di <- pointer to new line
	
	;
	; Initialize the line
	;
	xchg	si, bx				; *ds:si <- instance ptr
						; *ds:bx <- chunk array
	segmov	es, ds				; es:di <- ptr to new line
	call	CommonInitLineAndField		; Initialize the new line/field
	xchg	si, bx				; *ds:si <- chunk array
						; *ds:bx <- instance ptr

	loop	insertLoop			; Loop to insert them all

quit:
	clr	bx				; bx.di <- first one added
	mov	di, bp
	.leave
	ret


appendLoop:
	;
	; *ds:bx= Instance pointer
	; *ds:si= Chunk array
	; cx	= Number of elements to insert
	; ax	= Size of each element
	;
	call	ChunkArrayAppend		; ds:di <- pointer to new line
	
	;
	; Initialize the line
	;
	xchg	si, bx				; *ds:si <- instance ptr
						; *ds:bx <- chunk array
	segmov	es, ds				; es:di <- ptr to new line
	call	CommonInitLineAndField		; Initialize the new line/field
	xchg	si, bx				; *ds:si <- chunk array
						; *ds:bx <- instance ptr

	loop	appendLoop			; Loop to append them all
	
	jmp	quit
SmallLineInsert	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete some number of lines from a small text object.

CALLED BY:	TL_LineDelete via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line to start deleting at
		dx.ax	= Number of lines to delete
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineDelete	proc	far
	uses	ax, cx, si
	.enter
	push	ax
	call	SmallGetLineArray		; *ds:ax <- line array
	mov	si, ax				; *ds:si <- chunk array
	pop	ax

	xchg	ax, cx				; ax <- first line to nuke
						; cx <- # to nuke
	;
	; Delete the lines
	; *ds:si= Chunk array
	; ax	= First element to nuke
	; cx	= Number to nuke
	;
	call	ChunkArrayDeleteRange		; Nuke the lines
	.leave
	ret
SmallLineDelete	endp

TextLineCalc	ends
