
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Translation Library
FILE:		exportEmbeddedGraphic.asm

AUTHOR:		Jim DeFrisco, 2 May 1991

ROUTINES:
	Name			Description
	----			-----------
	EmitEmbeddedGraphic	fucked routine that will soon be nuked

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/2/91		Initial revision


DESCRIPTION:
	Useless routines in a matter of weeks.
		

	$Id: exportEmbeddedGraphic.asm,v 1.1 97/04/07 11:25:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmbeddedGraphic	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtractFirstStyleGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the first style group of a GrDrawTextField element

CALLED BY:	EmitTextField

PASS:		si	- gstring

RETURN:		ds:si	- pointer to OpDrawTextField structure

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Keep reading as long as we don't hit a graphics string or
		the end of the element.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Note:  This routine will go away when we don't have embedded
		graphics anymore.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtractFirstStyleGroup	proc	far
		uses	ax, bx, cx, dx, di
tgs		local	TGSLocals
		.enter	inherit

		; first extract the file handle from the gstring structure

		mov	bx, tgs.TGS_gstring		; get gstring handle
		call	MemLock
		mov	ds, ax				; ds -> GState struct
		mov	ax, ds:[GS_gstring]		; get GString han
		call	MemUnlock
		mov	bx, ax
		call	MemLock
		mov	ds, ax				; ds -> GString struct
		mov	ax, ds:[GSS_hString]		; ax = file handle
		call	MemUnlock			; release block
		mov	tgs.TGS_gsfile, ax		; save handle
		mov	bx, ax				; need to back up one
		mov	al, FILE_POS_RELATIVE
		mov	cx, -1				; move -1 bytes
		mov	dx, -1
		call	FilePos

		; lock down the scratch block, clear the chunk.
		; then read the fixed part of a DrawTextField element into
		; the chunk.

		mov	bx, tgs.TGS_chunk.handle	; lock the block
		call	MemLock
		mov	ds, ax				; ds -> block
		mov	ax, tgs.TGS_chunk.chunk		; get chunk handle
		mov	cx, size OpDrawTextField	; get first part
		call	LMemReAlloc			; 
		mov	di, ax				; deref chunk handle
		mov	dx, ds:[di]			; ds:dx -> chunk
		mov	bx, tgs.TGS_gsfile		; get file handle
		clr	al
		call	FileRead			; read element to chunk
EC <		ERROR_C PS_BAD_FILE_READ				>
		mov	si, dx				; ds:si -> data
		add	dx, size OpDrawTextField	; point dx after
		mov	cx, ds:[si].ODTF_fcount		; get fixed size
		add	cx, 3				; add size of opcode..
		mov	ax, tgs.TGS_chunk.chunk		; get chunk handle
		call	LMemReAlloc			; have fixed part
		sub	cx, size OpDrawTextField	; cx = fixed part left
							;   to read
							; this = size of string
		mov	di, ax				; deref chunk again
		mov	dx, ds:[di]			; ds:dx -> chunk
		mov	si, dx				; ds:si -> chunk
		add	dx, size OpDrawTextField	; ds:dx -> where we read
		clr	al
		call	FileRead			; have fixed part
EC <		ERROR_C PS_BAD_FILE_READ				>

		; now we need to see if there are other style runs we should
		; get.  We keep reading additional style run structures until
		; we either account for all the characters in the string or 
		; until we hit a style run structure that is for an embedded
		; graphic.
		; cx = length of string

		; get bx to be offset to style run structure.

		mov	bx, ds:[si].ODTF_fcount		; 
		sub	bx, (size TFStyleRun - 3)	; ds:si.bx -> style run
styleRunLoop:
		cmp	ds:[si][bx].TFSR_count, 0	; embedded graphic ?
		je	graphicEnd			;  yes, end of group
		sub	cx, ds:[si][bx].TFSR_count	; fewer to go
		jcxz	haveWhatWeNeed			; have all style runs

		push	cx				; save character count
		ChunkSizePtr	ds, si, cx
		add	cx, size TFStyleRun		; expand to read 1 more
		mov	ax, tgs.TGS_chunk.chunk		; get chunk handle
		call	LMemReAlloc			; resize chunk
		mov	si, ax				; deref again
		mov	si, ds:[si]			; ds:si -> chunk
		mov	dx, si				; ds:dx -> chunk
		sub	cx, size TFStyleRun		; cx = old size
		add	dx, cx				; ds:dx -> where to read
		mov	cx, size TFStyleRun		; amount to read
		push	bx				; save offset
		mov	bx, tgs.TGS_gsfile		; get file handle
		clr	al
		call	FileRead			; read next sr struct
EC <		ERROR_C PS_BAD_FILE_READ				>
		pop	bx				; restore offset
		add	bx, size TFStyleRun		; on to next one
		pop	cx				; restore char count
		jmp	styleRunLoop			; check for next run
		
		; have all we need for now.  We hit an embedded graphic, 
graphicEnd:
		dec	cx				; one less
haveWhatWeNeed:
		mov	tgs.TGS_embeddedHack2, cx	; save char count
		.leave
		ret
ExtractFirstStyleGroup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtractNextStyleGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the next style group of a GrDrawTextField element

CALLED BY:	EmitTextField

PASS:		ds:bx	 - pointer to chunk
		ds:bx.si - pointer to style run structure for embedded graphic

RETURN:		ds:bx.si - pointer to next style run structure

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Keep reading as long as we don't hit a graphics string or
		the end of the element.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Note:  This routine will go away when we don't have embedded
		graphics anymore.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtractNextStyleGroup	proc	far
		uses	ax, cx, di
tgs		local	TGSLocals
		.enter	inherit

		; resize scrath block, read in some more style run structs

		sub	dx, bx				; get offset from chunk
		push	dx				;  start and save
		xchg	bx, si				; si -> chunk, bx=offset
		mov	cx, bx				; size chunk - TFStyleR
		add	cx, (size TFStyleRun) * 2	; cx = new size 
		mov	ax, tgs.TGS_chunk.chunk		; get chunk handle
		call	LMemReAlloc			; make room for next
		mov	si, ax				; deref chunk handle
		mov	si, ds:[si]
		mov	dx, si
		add	dx, bx				; ds:dx -> last struct
		mov	cx, size TFStyleRun
		add	dx, cx				; where to read
		mov	bx, tgs.TGS_gsfile		; get file handle
		call	FileRead			; read next TFStyleRun
		mov	bx, dx				; get pointer to new
		sub	bx, si				; make it an offset
		mov	cx, tgs.TGS_embeddedHack2	; get #chars left
		push	bx				; save off to nxt run

		; now we need to see if there are other style runs we should
		; get.  We keep reading additional style run structures until
		; we either account for all the characters in the string or 
		; until we hit a style run structure that is for an embedded
		; graphic.
styleRunLoop:
		cmp	ds:[si][bx].TFSR_count, 0	; embedded graphic ?
		je	graphicEnd			;  yes, end of group
		sub	cx, ds:[si][bx].TFSR_count	; fewer to go
		jcxz	haveWhatWeNeed			; have all style runs

		push	cx				; save character count
		ChunkSizePtr	ds, si, cx
		add	cx, size TFStyleRun		; expand to read 1 more
		mov	ax, tgs.TGS_chunk.chunk		; get chunk handle
		call	LMemReAlloc			; resize chunk
		mov	si, ax				; deref again
		mov	si, ds:[si]			; ds:si -> chunk
		mov	dx, si				; ds:dx -> chunk
		sub	cx, size TFStyleRun		; cx = old size
		add	dx, cx				; ds:dx -> where to read
		mov	cx, size TFStyleRun		; amount to read
		push	bx				; save offset
		mov	bx, tgs.TGS_gsfile		; get file handle
		clr	al
		call	FileRead			; read next sr struct
EC <		ERROR_C PS_BAD_FILE_READ				>
		pop	bx				; restore offset
		add	bx, size TFStyleRun		; on to next one
		pop	cx				; restore char count
		jmp	styleRunLoop			; check for next run
		
		; have all we need for now.  We hit an embedded graphic, 
graphicEnd:
		dec	cx				; one less
haveWhatWeNeed:
		pop	bx				; restore off to next
		xchg	bx, si				; get em back again
		mov	tgs.TGS_embeddedHack2, cx	; save char count
		pop	dx				; restore chunk offset
		add	dx, bx				;  to text, make nptr
		.leave
		ret
ExtractNextStyleGroup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtractEGFonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab font list for embedded graphic

CALLED BY:	GLOBAL

PASS:		tgs	- passed on stack
		bx	- offset to start of chunk
		ds	- points to locked buffer

RETURN:		bx	- updated appropriately
		ds	- points to locked buffer, may have changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		we don't want to allocate a whole new stack frame, since 
		we need the font into to stay local.  What we do need, 
		however is a few new chunks in the current block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtractEGFonts	proc	far
		uses	ax, cx, dx
tgs		local	TGSLocals
		.enter	inherit

		; first lock the block and allocate the new chunks.  Save away
		; the old chunk handles frist

		push	tgs.TGS_chunk.chunk	; we just need these two
		push	tgs.TGS_xtrachunk
		push	tgs.TGS_embeddedHack2	; yes, you guessed it

		; allocate new chunks and put the handles where we expect them

		clr	cx			; no space initially
		call	LMemAlloc
		mov	tgs.TGS_chunk.chunk, ax	; save new chunk handle
		call	LMemAlloc
		mov	tgs.TGS_xtrachunk, ax	; save new chunk handle
		mov	bx, tgs.TGS_chunk.handle ; unlock the block
		call	MemUnlock		; release the block

		; recurse to get the font info

		clr	ax
		call	GetPageFonts		; read fonts for this page

		; OK, we're done with getting the fonts from this embedded
		; graphic. We're pointing at the final escape code, so skip
		; over it.

		mov	bx, tgs.TGS_gsfile	; get file handle
		mov	dx, size OpEscape	; it's just this size
		clr	cx
		mov	al, FILE_POS_RELATIVE	; bump over it
		call	FilePos

		; we're done with these bogus chunks, so free them

		mov	bx, tgs.TGS_chunk.handle ; lock the block
		call	MemLock
		mov	ds, ax
		mov	ax, tgs.TGS_chunk.chunk	; get handles to free
		call	LMemFree
		mov	ax, tgs.TGS_xtrachunk
		call	LMemFree

		; restore the old chunk handles

		pop	tgs.TGS_embeddedHack2
		pop	tgs.TGS_xtrachunk
		pop	tgs.TGS_chunk.chunk
		mov	bx, tgs.TGS_chunk.chunk
		mov	bx, ds:[bx]		; dereference again

		.leave
		ret
ExtractEGFonts	endp

EmbeddedGraphic	ends
