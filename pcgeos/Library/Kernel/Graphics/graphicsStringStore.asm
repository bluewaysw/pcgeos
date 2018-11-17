COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Library
FILE:		graphicsStringStore.asm

AUTHOR:		Jim DeFrisco, 24 October 1989

ROUTINES:
		Name			Description
		----			-----------
	    GBL	BitmapToString		Store a bitmap to a graphics string
	    GBL	StoreTextField		Store a text field to a graphics string

	    INT	SliceToString		Support routine for BitmapToString
	    INT	CalcPackbitsBytes	Support routine for BitmapToString

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/24/89	Initial revision

DESCRIPTION:
		This file contains some of the support routines for the
		graphics string capability in the kernel.
		
	$Id: graphicsStringStore.asm,v 1.1 97/04/05 01:12:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsStringStore segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreTextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store a text field element to a graphics string

CALLED BY:	GLOBAL

PASS:		ss:bp	- pointer to GDF_vars structure (see text.def)

			  Of these, the GDF_saved structure should be written
			  to the GString:
				GDFS_nChars	word
				GDFS_drawPos 	PointWBFixed
				GDFS_baseline 	WBFixed
				GDFS_limie	word
		bx	- original GState handle

		di	- gstring handle

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si

PSEUDO CODE/STRATEGY:
		Write out a header of info, including the text string;
		Write out a series of style records;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		There will be some more info added to the text field record,
		but the basic structure of the element will be as follows:

			size			description
			----			-----------
			1			GR_DRAW_TEXT_FIELD
			(size GDF_saved)	GDF_saved structure:
			; now put out each style run

			2	#chars in run	TFStyleRun structure
			20	TextAttr structure

			n	chars for this run

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StoreTextFieldBuffer	struc
    STFB_gstring	hptr.GString		; need this to write stuff
    STFB_srun		TFStyleRun		; the bulk
    STFB_spacePad	WWFixed			; the previous space padding
StoreTextFieldBuffer	ends

StoreTextField	proc	far
		uses	es, ds
		.enter	

		; get the space padding that is in the GState, as we'll
		; need that later.  The GState is locked, so just dereference
		; it and grab the values straight away.

		call	MemDerefDS			; ds -> GState
		movwbf	dxah, ds:GS_textSpacePad	; get current padding
		clr	al				; bxax = spacePadding

		; first, write out the opcode and the GDF_saved structure

		pushwwf	dxax				; save space padding
		mov	al, GR_DRAW_TEXT_FIELD
		mov	cx, size GDF_saved
		segmov	ds, ss, si
		mov	si, bp				; ds:si -> GDF_saved
		mov	ah, GSSC_DONT_FLUSH		; not done yet
		call	GSStore				; store header bytes
		popwwf	dxax				; restore space padding

		; next, call back for each style run.  Allocate some room
		; on the stack to put the attributes

		sub	sp, size StoreTextFieldBuffer	; style run structure
		mov	bx, sp				; ss:bx -> structure
		mov	ss:[bx].STFB_gstring, di	; save GString handle
		movwwf	ss:[bx].STFB_spacePad, dxax	; save space padding 
		movdw	bxdi, sssp			
		add	di, offset STFB_srun.TFSR_attr	; bx:di -> attr buffer
		mov	cx, ss:[bp].GDFV_saved.GDFS_nChars
		clr	si				; start at beginning

		; loop through each style run, recording info.
		stc					; signal: 1st time
styleRunLoop:
		;
		; Carry must be set if this is the first time through the
		; loop.
		;
		push	si				; save string offset
		push	cx				; save total #chars 
		
		;
		; Set cx to zero if this is the first call.
		;
		mov	cx, 0				; Assume is first call
		jc	gotCXFlagForCallback		; Branch if is first
		dec	cx				; Set to non-zero if not
gotCXFlagForCallback:

		mov	ss:[TPD_dataBX], bx
		mov	ss:[TPD_dataAX], ax
		movdw	bxax, ss:[bp].GDFV_styleCallback
		call	ProcCallFixedOrMovable

		;
		;  The callback for the text object, sadly, does not update
		;  the textSpacePad value in this structure.  So just use the
		;  value that is already in the GState
		;
		push	ds, ax
		mov	ds, bx
		movwwf	dxax, ds:[di-STFB_srun.TFSR_attr].STFB_spacePad
		movwbf	ds:[di].TA_spacePad, dxah
		pop	ds, ax

		movdw	ss:[bp].GDFV_textPointer, dssi	; save text pointer
		sub	di, offset TFSR_attr		; backup to beginning
		mov	dx, cx				; dx = #chars
		pop	cx				; restore total #
		cmp	dx, cx				; use lesser of two
		jb	haveRunCount
		mov	dx, cx				; set run count = total
haveRunCount:
		sub	cx, dx				; fewer to go
		push	ds, si, dx, cx			; save char ptr & count
		movdw	dssi, bxdi			; ds:si -> TFStyleRun
		mov	ds:[si].TFSR_count, dx		; save count for run
		mov	cx, size TFStyleRun		; amount to save
		mov	al, GSE_INVALID			; no opcode to save
		mov	ah, GSSC_DONT_FLUSH		; not done yet
		mov	di, ds:[si-STFB_srun].STFB_gstring ; get GString handle
		call	GSStore				; save run attributes
		mov	di, si				; restore di -> TFSR
		add	di, TFSR_attr			; bx:di -> TextAttr
		pop	ds, si, cx, dx			; restore ptr and count
		tst	dx				; if this is the last
		jz	writeLastRun			;  then flush
		push	di				; save struc ptr
		mov	di, ss:[di-(STFB_srun.TFSR_attr)].STFB_gstring ; GS han
DBCS <		shl	cx, 1				; Char to byte count>
		call	GSStore				; write char string
		pop	di				; restore ptr to struc
		pop	si				; restore offset
DBCS <		shr	cx, 1				; byte count to char>
		add	si, cx				; bump offset
		mov	cx, dx				; cx = total char count
		
		clc					; signal: not 1st time
		jmp	styleRunLoop

		; everything is setup, just change to FLUSH mode
writeLastRun:		
		mov	di, ss:[di-(STFB_srun.TFSR_attr)].STFB_gstring ; GS han
		mov	ah, GSSC_FLUSH
DBCS <		shl	cx, 1				; Char to byte count>
		call	GSStore				; write out last string
		pop	si				; restore register

		add	sp, size StoreTextFieldBuffer	; restore stack

		.leave
		ret
StoreTextField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store stuff to a graphics string

CALLED BY:	GLOBAL

PASS:		di	- gstring handle
		cx	- #bytes to store
		ds:si	- pointer to buffer to store

		al	- graphics opcode	
		ah	- flag to control flushing of block (sometimes we 
			  don't want to flush data if we're in the middle of
			  an opcode...)
			  type is GStringStoreControl enum
			  GSSC_DONT_FLUSH	- yeah, what you'd think
			  GSSC_FLUSH		- flush if over threshold
			  GSSC_FORCE_FLUSH	- flush in any case

RETURN:		carry	- set if some disk error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		see GSStore in Kernel/Graphics/graphicsString.asm

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		
MAX_STORE_LENGTH	equ	0xf000

GSStore		proc	far
		uses	es, cx, dx, si, bp, bx, ax, di
		.enter

		; do some checking on the length of the beast we want to store

EC <		cmp	cx, MAX_STORE_LENGTH	; make sure we're not trying >
EC <		ERROR_A	GRAPHICS_STORING_WAY_TOO_MUCH_TO_A_GSTRING	>

		; lock the gstring structure	

		push	ax			; save opcode
		mov	bx, di
		call	MemLock			; ax -> gstring structure
		mov	es, ax			; es -> structure
		pop	ax			; get opcode in ax

		; if the error flag is set, indicating a full disk, then skip
		; this routine altogether.

		mov	bx, es:[GSS_flags]	; get type info
		test	bl, mask GSF_ERROR
		jnz	diskFullError		; error happened, don't write

		and	bl, mask GSF_HANDLE_TYPE ; isolate type info
		cmp	bl, GST_PTR		; this is definitely bad 
NEC <		je	done			; skip if read only	>
EC <		ERROR_Z GRAPHICS_WRITING_TO_READ_ONLY_GSTRING		>
		clr	bh
		shl	bx, 1
		call	cs:writeGSRoutines[bx]	; call specific routine
		jcxz	diskFullError		; oops, something went amiss
		clc				; no disk error
		
		; done.  carry will be preserved
done:
		mov	bx, es:[LMBH_handle]	; bx <- gstring block
		call	MemUnlock		; unlock gstring block
		.leave
		ret

		; disk is full.  Alert the media.
diskFullError:
		or	es:[GSS_flags], mask GSF_ERROR
		stc				; signal disk error
		jmp	done
GSStore		endp

writeGSRoutines	label	nptr
		nptr	offset WriteMemGString
		nptr	offset WriteStreamGString
		nptr	offset WriteVMemGString

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteMemGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write some data to a chunk-based gstring

CALLED BY:	INTERNAL
		GSStore
PASS:		es	- GString block
		ds:si	- pointer to data to save
		cx	- #bytes to write
		al	- opcode to write
RETURN:		cx	- 0xffff (to indicate no problems with disk filling)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteMemGString	proc	near
		uses	dx, bx
		.enter
		mov	dx, es:[GSS_firstBlock]	; get chunk/vmem block handle
		mov	bx, es:[GSS_hString]	; set up handle to string block
		call	WriteToChunk		; store element to chunk
		mov	cx, 0xffff		; signal no error
		.leave
		ret
WriteMemGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteStreamGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write data to a stream-based GString

CALLED BY:	INTERNAL
		GSStore
PASS:		es	- GString block
		ds:si	- pointer to data to save
		cx	- #bytes to write
		al	- opcode to write
		ah	- flush control
RETURN:		cx	- 0 if disk full, else 0xffff
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteStreamGString proc	near
		uses	dx, bx			; save gstring handle
		.enter
		mov	bx, es:[LMBH_handle]	; file buffer chunk in GS struc
		mov	dx, es:[GSS_fileBuffer]
		call	WriteToChunk		; store element to chunk
		cmp	ah, GSSC_DONT_FLUSH	; if this set, just continue
		jne	flushChunk
		mov	cx, 0xffff		; signal no error
		jmp	done

		; OK, we can flush the buffer.  See if there is enough, and
		; whether or not there have been any file writing errors lately
flushChunk:
		cmp	ah, GSSC_FORCE_FLUSH	; if forcing, go for it
		je	flushIt
		cmp	cx, GS_WRITE_THRESHOLD	; big enough to write out ?
		jb	done			;  all done, leave
flushIt:
		test	es:[GSS_flags], mask GSF_ERROR ; check for err
		jnz	done			;  some error, don't flush
		call	FlushChunk		;  over, flush
done:
		.leave
		ret
WriteStreamGString endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteVMemGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write data to a hugearray gstring

CALLED BY:	INTERNAL
		GSStore
PASS:		es	- GString block
		ds:si	- pointer to data to save
		cx	- #bytes to write
		al	- opcode to write
		ah	- flush control
RETURN:		cx	- 0xffff (no disk error)
DESTROYED:	

PSEUDO CODE/STRATEGY:
		append to filebuffer chunk;
		if OK to flush,
		    insert element into HugeArray at current position
		    bump current position

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteVMemGString proc	near
		uses	dx, bx
		.enter
		mov	bx, es:[LMBH_handle]	; file buffer chunk in GS struc
		mov	dx, es:[GSS_fileBuffer]
		call	WriteToChunk		; store element to chunk
		cmp	ah, GSSC_DONT_FLUSH
		je	done
		
		; time to write out the element.  Get the current position
		; and insert the element there.

		push	ds, bp, di, si, ax
		segmov	ds, es, bp		; ds, bp -> GString block
		mov	si, ds:[GSS_fileBuffer]
		ChunkSizeHandle es, si, cx	; cx = size of data
		mov	si, ds:[si]		; bp:si -> data
		mov	bx, ds:[GSS_hString]	; get VM file handle
		mov	di, ds:[GSS_firstBlock]	; get HugeArray Dir handle
		movdw	dxax, ds:[GSS_curPos]	; dxax = element number
		call	HugeArrayInsert		; insert the element
		incdw	ds:[GSS_curPos]		; bump current position

		; now we need to nuke the chunk so we don't write it out
		; again.

		mov	ax, ds:[GSS_fileBuffer]	; chunk handle
		clr	cx			; resize to zero
		call	LMemReAlloc
		pop	ds, bp, di, si, ax	; restore all sorts of things
done:
		mov	cx, 0xffff
		.leave
		ret
WriteVMemGString endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteToChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a string 

CALLED BY:	GLOBAL

PASS:		al	- 0-fe = prefix byte to write
			  GSE_INVALID   = don't write any prefix
		bx	- block handle
		dx	- chunk handle
		cx	- # bytes in buffer
		ds:si	- far pointer to buffer
		es	- pointer to GString structure

RETURN:		cx	- new size of chunk

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (al != GSE_INVALID)
		    realloc chunk to (current size + cx + 1)
		    write out al;
		else
		    realloc chunk to (current size + cx)
		copy cx bytes from ds:si to chunk;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteToChunk	proc	near
		uses	ax
dataPtr		local	fptr
dataSize	local	word
prefix		local	word
chunkSize	local	word
		.enter

		; save some stuff for later

		mov	ss:[dataPtr].offset, si
		mov	ss:[dataPtr].segment, ds
		mov	ss:[dataSize], cx
		mov	ss:[prefix], ax

		; first lock block that chunk resides in

		call	ObjLockObjBlock		; ax = segment address
		mov	ds, ax			; setup pointer to block

		; determine size of chunk we're storing to

		mov	si, dx			; si = chunk handle
		ChunkSizeHandle ds,si,si	; si = size of chunk

		; calc size of new chunk and realloc chunk

		add	cx, si			; cx = total size
		cmp	{byte} ss:[prefix].low, GSE_INVALID ; store prefix ?
		je	haveNewSize		;  no, size ok
		inc	cx			; cx = size of new chunk
haveNewSize:
		mov	ss:[chunkSize], cx	; save it
		mov	ax, dx			; ax = chunk handle
		call	LMemReAlloc		; realloc chunk

		; calc new offset into chunk and copy bytes over

		push	es			; save GString block ptr
		mov	di, dx			; *ds:di -> target chunk
		mov	di, ds:[di]		; ds:di -> target chunk
		add	di, si			; ds:di -> target data space
		segmov	es, ds, si		; es:di -> target data space
		lds	si, ss:[dataPtr]	; ds:si -> data pointer
		mov	cx, ss:[dataSize]

		; check to see if prefix byte should be written

		mov	al, {byte} ss:[prefix].low ; get prefix byte
		cmp	al, GSE_INVALID		; need to store prefix ?
		je	moveData		;  no, just do the block move
		stosb				; write it out
moveData:
		jcxz	doneCopy
		rep	movsb			; do last move if odd #bytes
doneCopy:
		call	MemUnlock		; unlock the chunk block
		pop	es			; restore pointer to GString 
		mov	cx, ss:[chunkSize]	; return size of chunk
		mov	si, ss:[dataPtr].offset
		mov	ax, ss:[prefix]
		.leave
		ret
WriteToChunk	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlushChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flush chunk out to disk

CALLED BY:	INTERNAL

PASS:		es	- GString block (has fileBuffer chunk)

RETURN:		cx	- non-zero if no error, else zero if disk was full...

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Write out chunk to open file;
		Resize chunk to NULL;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version
		jim	1/91		Added handling of disk full error

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlushChunk	proc	near
		uses	ds, di, si
		.enter

		; make ds -> buffer chunk

		segmov	ds, es, ax		; es -> file buffer

		; write out the bytes

		mov	si, es:[GSS_fileBuffer]	; set up chunk in si
		mov	dx, ds:[si]		; ds:dx -> data
		clr	al			; set filewrite to ret errs
		mov	bx, es:[GSS_hString]	; bx = file handle
		ChunkSizeHandle ds,si,cx	; cx = amount to write
		call	FileWriteFar		; write out the chunk
		pushf				; save carry flag state
						;  (carry set == error)
		; resize the chunk to NULL

		clr	cx			; size in cx
		mov	ax, si			; chunk in ax
		call	LMemReAlloc		; resize chunk

		; restore disk error status

		popf				; restore result of FileWrite
		jc	handleDiskFull		; error, do something !
		mov	cx, 0xffff		; indicate no error
done:
		.leave
		ret

		; the disk is full.  truncate the file and return the error
handleDiskFull:
		clr	cx			; truncate to zero length
		clr	dx
		clr	al			; no errors
		call	FileTruncate
		clr	cx			; set to zero for error
		jmp	done
FlushChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSStoreBytes 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a graphics opcode, plus up to 6 bytes of data

CALLED BY:	EXTERNAL

PASS:		di	- gstring handle
		al	- opcode to write (if no opcode, pass GSE_INVALID)
		cl	- # bytes to write (excludes opcode)
		ch	- flag to control flushing of block (sometimes we 
			  don't want to flush data if we're in the middle of
			  an opcode...)
			  type is GStringStoreControl enum
			  GSSC_DONT_FLUSH	- yeah, what you'd think
			  GSSC_FLUSH		- flush if over threshold
			  GSSC_FORCE_FLUSH	- flush always

		if (cl == 1)
		    ah	- data byte 1
		if (cl == 2)
		    bx	- data word 1
		if (cl == 3)
		    ah	- data byte 1
		    bx	- data bytes 2 & 3
		if (cl == 4)
		    bx	- data word 1
		    dx	- data word 2
		if (cl == 5)
		    ah  - data byte 1
		    bx	- data bytes 2 & 3
		    dx	- data bytes 4 & 5
		if (cl == 6)
		    bx	- data word 1
		    dx	- data word 2
		    si	- data word 3
		if (cl == 7)
		    ah  - data byte 1
		    bx	- data bytes 2 & 3
		    dx	- data bytes 4 & 5
		    si  - data bytes 6 & 7

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This is an optimization for GSStore, to avoid unnec pushing;

		Just lock the block, and write to the chunk, don't bother
		flushing the file buffer.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The non-flushing of the buffer is actually an important part
		of the code -- since this is called as the first part of a
		two part write for many opcodes (first part includes fixed
		header part of element, second part (usually GSStore is called
		for 2nd part) contains the variable part of the element), it
		ensures  that no element will be spread across two VM blocks,
		should that be the target of the write...

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version
		jim	4/3/92		Rewritten for 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GSStoreBytes	proc	far
		uses	ds,cx,si,ax
saveBuffer	local	4 dup(word)
		.enter

		; save the bytes in our local buffer
		
		push	di
		segmov	ds, ss, di
		lea	di, ss:saveBuffer	; es:di -> save buffer
		test	cl, 1			; if odd number, ah has data
		jz	storeWords
		mov	ds:[di], ah		; put in al,ah
		inc	di			; keep at least one
storeWords:
		mov	ds:[di], bx		; storem all, even if we don't
		mov	ds:[di+2], dx		;  need them all.  It's prob
		mov	ds:[di+4], si		;  faster than figuring out
		pop	di			;  which ones to really store
		
		; all setup.  Just use the existing GSStore routine

		mov	ah, ch			; move flush control into ah
		clr	ch			; make count a word
		lea	si, ss:saveBuffer	; ds:si -> bytes to write
		call	GSStore			; store the bytes

		.leave
		ret
GSStoreBytes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrEndGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish the definition of a string

CALLED BY:	GLOBAL

PASS:		di	- handle of graphics string

RETURN:		ax	- enum of type GStringErrorType
			     GSET_NO_ERROR	- no error creating gstring
			     GSET_DISK_FULL	- disk became full, file was
						  truncated
			 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		    if (graphics string in a file)
			flush file buffer;
		    clr	ax

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrEndGString	proc	far
		uses	ds,cx,bx		; save some regs
		.enter

		; make sure we have a gstring, then write out the opcode

		mov	bx, di			; lock the gstate block
		call	MemLock
		mov	ds, ax			; ds -> gstate block
		test	ds:[GS_pathFlags], mask PF_DEFINING_PATH
		jnz	doneNoError		; if defining path, ignore it
		mov	di, ds:[GS_gstring]	; get gstring handle
		tst	di			; if zero, exit
		jz	doneNoError		; not a gstring, exit

		; write out the string terminator, use GSStore so we can
		; flush the chunk.

		mov	al, GR_END_GSTRING	; write out terminator
		clr	cx			; writing one byte
		mov	ah, GSSC_FORCE_FLUSH
		call	GSStore			;
		jc	errorFlagSet
doneNoError:
		mov	ax, GSET_NO_ERROR
done:
		mov	di, bx			; restore gstate handle
		call	MemUnlock		; unlock gstate
		.leave
		ret

		; disk full error handling
errorFlagSet: 					;  disk full error, set flag
		mov	ax, GSET_DISK_FULL	; set error flag
		jmp	done
GrEndGString	endp

GraphicsStringStore	ends
