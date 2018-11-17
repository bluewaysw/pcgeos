COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File System Drivers
FILE:		cvgfsDevSpec.asm

AUTHOR:		Adam de Boor, Apr 14, 1993

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/93		Initial revision
	cassie	6/29/93		adapted for Bullet
	todd	9/12/94		Modified to make generic
	Joon	1/19/96		Adapted for compressed GFS


DESCRIPTION:
	Device-specific support routines for the common code.
		

	$Id: cvgfsDevSpec.asm,v 1.1 97/04/18 11:46:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

.186			; enable use of V20 instructions

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the file whose absolute name is stored in the ini file.

CALLED BY:	GFSInit
PASS:		nothing
RETURN:		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version
	Joon	1/19/96		Compressed VGS version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
gfsKeyStr	char	'gfs', 0
driveKeyStr	char	'drive', 0

GFSDevInit 	proc	near
		uses	ds, bx, si, di, dx, cx, es
		.enter
	;
	; Just want to find the name we should use for the drive, if not the
	; default. Everything else we can handle.
	;
	; Our caller will check the filesystem for sanity.
	; 
		segmov	es, dgroup, di
		mov	di, offset gfsDriveName
		segmov	ds, cs, cx		; ds, cx <- cs
		mov	dx, offset driveKeyStr
		mov	si, offset gfsKeyStr
		push	bp
		mov	bp, (IFCC_INTACT shl offset IFRF_CHAR_CONVERT) or \
				DRIVE_NAME_MAX_LENGTH
		call	InitFileReadString
		pop	bp
ifidn	HARDWARE_TYPE, <PC>
	;
	; This is just so the non-Product version will make.
	;
else
	;
	; Locate the filesystem using the XIP header.
	; 
		LoadXIPSeg	ds, ax
if	FULL_EXECUTE_IN_PLACE
		movdw	es:[fsBase], ds:[FXIPH_romFSStart], ax
else
		movdw	es:[fsBase], ds:[XIPH_romFSStart], ax
endif
endif

	; Read compressed GFS header.

		clrdw	dxax
		call	VGFSMapOffset
		segmov	ds, es
		mov	si, di
		segmov	es, dgroup, di
		mov	di, offset cgfsHeader
		mov	cx, size cgfsHeader
		rep	movsb
		call	VGFSUnmapLastOffset

	; Make sure we have a real cgfs image.

		cmp	{word} es:[cgfsHeader].CGFSH_signature[0], 'cg'
EC <		ERROR_NE CGFS_IMAGE_IS_HOSED				>
		stc				; assume we have a problem
		jne	done
		cmp	{word} es:[cgfsHeader].CGFSH_signature[2], '00'
EC <		ERROR_NE CGFS_VERSION_NUMBER_MISMATCH			>
		stc				; assume we have a problem
		jne	done

	; It looks ok, so allocate a decompress buffer.

		mov	ax, es:[cgfsHeader].CGFSH_blocksize
		mov	bx, handle 0		; block owned by driver
		mov	cx, ALLOC_FIXED
		call	MemAllocSetOwner	; carry - set if error
		mov	es:[decompressSeg], ax
done:
		.leave
		ret
GFSDevInit	endp

Init		ends

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish with the filesystem

CALLED BY:	GFSExit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevExit	proc	far
		.enter
		.leave
		ret
GFSDevExit	endp

Resident	ends

Movable		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevMapDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring in the contents of the indicated directory

CALLED BY:	EXTERNAL
PASS:		dxax	= offset of directory
		cx	= # of entries in the directory
RETURN:		carry set on error:
			ax	= FileError
			es, di	= destroyed
		carry clear if ok:
			es:di	= first entry in the directory
			ax	= size of data read
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version
	Joon	1/19/96		Compressed GFS version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevMapDir	proc	near
		uses	bx, cx, ds
		.enter

		segmov	ds, dgroup, di

		push	ax, dx
		mov	ax, size GFSDirEntry
		mul	cx
		mov	di, ax
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
		mov	cx, di
		mov	es, ax
		clr	di
		pop	ax, dx

		call	SysLockBIOS
		mov	ds:[tempReadHandle], bx
		call	GFSDevRead

		.leave
		ret
GFSDevMapDir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevUnmapDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the directory at the head of the cache.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version
	Joon	1/19/96		Compressed GFS version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevUnmapDir	proc	near
		.enter

		pushf
		push	ds, bx
		segmov	ds, dgroup, bx
		mov	bx, ds:[tempReadHandle]
		call	SysUnlockBIOS
		call	MemFree
		pop	ds, bx
		popf

		.leave
		ret
GFSDevUnmapDir	endp

Movable		ends

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevMapEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring in the extended attributes for a file.

CALLED BY:	EXTERNAL
PASS:		dxax	= offset of extended attributes
RETURN:		carry set on error:
			ax	= FileError for caller to return
		carry clear if ok:
			es:di	= GFSExtAttrs
			ax	= size of data read
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version
	Joon	1/19/96		Compressed GFS version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevMapEA	proc	far
		uses	bx, cx, ds
		.enter

		segmov	ds, dgroup, di

		push	ax
		mov	ax, size GFSExtAttrs
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
		mov	cx, size GFSExtAttrs
		mov	es, ax
		clr	di
		pop	ax

		call	SysLockBIOS
		mov	ds:[tempReadHandle], bx
		call	GFSDevRead

		.leave
		ret
GFSDevMapEA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevUnmapEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the extended attributes we read in last.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version
	Joon	1/19/96		Compressed GFS version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevUnmapEA	proc	far
		.enter

		pushf
		push	ds, bx
		segmov	ds, dgroup, bx
		mov	bx, ds:[tempReadHandle]
		call	SysUnlockBIOS
		call	MemFree
		pop	ds, bx
		popf

		.leave
		ret
GFSDevUnmapEA	endp

Resident	ends

Movable		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevFirstEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the offset of the first extended attribute
		structure for this directory.

CALLED BY:	EXTERNAL
PASS:		dxax	= base of directory
		cx	= # directory entries in there
RETURN:		dxax	= offset of first extended attribute structure
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevFirstEA	proc	far
		uses	bx, si
		.enter
		movdw	bxsi, dxax
		mov	ax, size GFSDirEntry
		mul	cx
		adddw	dxax, bxsi
	;
	; Round the thing to a 256-byte boundary.
	; 
		adddw	dxax, <size GFSExtAttrs-1>
		andnf	ax, not (size GFSExtAttrs-1)
		.leave
		ret
GFSDevFirstEA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevNextEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the start of the next GFSExtAttrs structure in
		a directory, given the offset of the current one

CALLED BY:	EXTERNAL
PASS:		dxax	= base of current ea structure
RETURN:		dxax	= base of next
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevNextEA	proc	near
		.enter
		add	ax, size GFSExtAttrs
		adc	dx, 0
		.leave
		ret
GFSDevNextEA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevLocateEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the extended attrs for a file given the base of
		the directory that contains it, the number of entries
		in the directory, and the entry # of the file in the directory

CALLED BY:	EXTERNAL
PASS:		dxax	= base of directory
		cx	= # of entries in the directory
		bx	= entry # within the directory
RETURN:		dxax	= base of extended attrs
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevLocateEA	proc	near
		uses	cx, si
		.enter
		call	GFSDevFirstEA
		movdw	cxsi, dxax
		mov	ax, size GFSExtAttrs
		mul	bx
		adddw	dxax, cxsi
		.leave
		ret
GFSDevLocateEA	endp

Movable	ends

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gain exclusive access to the filesystem

CALLED BY:	EXTERNAL
PASS:		al - GFSDevLockFlags
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevLock	proc	far
		uses	ds
		.enter
		call	LoadVarSegDS
		PSem	ds, fileSem
		.leave
		ret
GFSDevLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release exclusive access to the filesystem.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevUnlock	proc	far
		uses	ds, bx, ax
EC <		uses	si					>
		.enter
		pushf
		call	LoadVarSegDS
EC <		tst	ds:[fsMapped]				>
EC <		ERROR_NZ	SOMETHING_NOT_UNMAPPED		>
   		VSem	ds, fileSem, TRASH_AX_BX
		popf
		.leave
		ret
GFSDevUnlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read bytes from the filesystem

CALLED BY:	EXTERNAL
PASS:		dxax	= offset from which to read them
		cx	= number of bytes to read
		es:di	= place to which to read them
RETURN:		ax	= number of bytes read
		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version
	Joon	1/19/96		Compressed GFS version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevRead	proc	far
fpos	local	dword				push	dx, ax
dest	local	fptr				push	es, di
	uses	bx,cx,dx,si,di,bp,ds,es
	.enter

	push	cx			; save number of bytes to read
	mov	bx, cx			; bx = number of bytes to read
read:
	segmov	ds, dgroup, cx
	mov	cx, ds:[cgfsHeader].CGFSH_blocksize	; cx = blocksize
	div	cx			; ax = block table index
	shl	ax, 2			; ax = convert to dword offset
	add	ax, size CompressedGFSHeader
	clr	dx			; dx:ax = offset to block entry
	call	VGFSMapOffset		; *es:di = compressed block offset
	movdw	dxax, es:[di]		; dx:ax = compressed block offset
	call	VGFSUnmapLastOffset

	mov	si, dx			; save high word of offset
	andnf	dx, 0x7fff		; clear UNCOMPRESSED bit
	call	VGFSMapOffset		; es:di = compressed data block

	mov	ax, cx			; ax = blocksize
	test	si, 0x8000		; check if block was not compressed
	jnz	copy			; then just copy it

	mov	si, es
	mov	es, ds:[decompressSeg]
	mov	ds, si	
	mov	si, di			; ds:si = input buffer
	clr	di			; es:di = output buffer (decompressSeg)
	call	CVGFSUncompress		; ax = uncompressed data size
EC <	cmp	ax, cx			; compare with blocksize	>
EC <	ERROR_A	CGFS_IMAGE_IS_HOSED					>

copy:
	mov	si, cx			; si = blocksize
	dec	si			; si = blocksize - 1
	and	si, ss:[fpos].low	; si = offset of data
	sub	ax, si			; ax = size of data in block
	segmov	ds, es
	add	si, di			; ds:si = source
	les	di, ss:[dest]		; es:di = destination
	cmp	ax, bx			; size of data vs. size of dest
	jb	move
	mov	ax, bx			; ax = size of dest
move:	mov	cx, ax			; cx = size of data to copy
	shr	cx, 1
	rep	movsw
	jnc	unmap
	movsb
unmap:	call	VGFSUnmapLastOffset

	sub	bx, ax
EC <	ERROR_C	CGFS_IMAGE_IS_HOSED	; not really, logic error???	>
	jz	done

	cwd				; dx:ax = ax
	adddw	ss:[fpos], dxax		; update file pointer
	adddw	ss:[dest], dxax		; update destination buffer pointer
	movdw	dxax, ss:[fpos]		; dx:ax = new fpos
	jmp	read
done:
	pop	ax			; ax = number of bytes read

	.leave
	ret
GFSDevRead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VGFSMapOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map in data at a given offset in the filesystem.

CALLED BY:	INTERNAL
PASS:		dxax	= data to map
RETURN:		es:di	= first byte of that data.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VGFSMapOffset	proc	far
		uses	ds, dx, ax
		.enter
		call	LoadVarSegDS
	;
	; Get the linear address of the memory.
	; 
		adddw	dxax, ds:[fsBase]
	;
	; Return the in-bank offset in DI.
	; 
		mov	di, ax
		andnf	di, BANK_SIZE-1
	;
	; Now convert the 32-bit offset in dxax to a 16-bit (11-bit, actually)
	; bank address in ax by appropriate shifts.
	; 
		shr	ax, BANK_SIZE_SHIFT
		shl	dx, 16 - BANK_SIZE_SHIFT
		or	ax, dx
	;
	; Make sure the thing is write-protected while it's mapped.
	; 
;		ornf	ax, mask EW_WRITE_PROTECT
	;
	; Grab the BIOS lock, as we use the same bank as the RAM/ROM drives
	; do in DOS.
	; 
		call	SysLockBIOS

EC <		tst	ds:[fsMapped]					>
EC <		ERROR_NZ	SOMETHING_ALREADY_MAPPED		>
EC <		mov	ds:[fsMapped], TRUE				>

		push	ax
		mov	al, BANK_SEG_LOW
		out	BANK_ADDR_REG, al
		pop	ax
		ornf	ax, 0xb000				;Enable ROM #1
		out	BANK_DATA_REG, ax
	;
	; Always the same segment returned in ES.
	; 
		segmov	es, BANK_SEG, ax
		.leave
		ret
VGFSMapOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VGFSUnmapLastOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unmap the thing we mapped before

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Don't actually have to do anything here except release the
		BIOS lock.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VGFSUnmapLastOffset proc	far
EC <		uses	ds						>
		.enter
EC <		pushf							>
EC <		call	LoadVarSegDS					>
EC <		tst	ds:[fsMapped]					>
EC <		ERROR_Z	NOTHING_MAPPED					>
EC <		mov	ds:[fsMapped], FALSE				>
EC <		popf							>
		call	SysUnlockBIOS
		.leave
		ret
VGFSUnmapLastOffset endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CVGFSUncompress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Uncompress

CALLED BY:	GLOBAL
PASS:		ds:si	= compressed data
		es:di	= output buffer
RETURN:		ax	= size of uncompressed data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

    for (;;) {
	if ((data = *in++) & 0x80) {
	    pos = out - (data & 0x7f);
	    *out++ = *pos++;
	    *out++ = *pos++;
	    *out++ = *pos++;
	} else {
	    if (data & 0x40) {
		if ((len = data & 0x1f) == 0)
		    break;
		if (data & 0x20)
		    for (; len; len--) *out++ = 0;
		else
		    for (; len; len--) *out++ = *in++;
	    } else {
		len = ((data & 0x3f) >> 2) + MIN_MATCH_LENGTH;
		pos = out - ((data & 0x03) << 8 | *in++);
		for (; len; len--) *out++ = *pos++;
	    }
	}

    }

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LZ77_PAIR_POSITION_BITS	equ	10
LZ77_PAIR_LENGTH_BITS	equ	(14-LZ77_PAIR_POSITION_BITS)
LZ77_MIN_MATCH_LENGTH	equ	3
LZ77_SMALL_PAIR_FLAG	equ	80h
LZ77_LITERALS_FLAG	equ	40h
LZ77_RUN_LENGTH_FLAG	equ	20h

CVGFSUncompress	proc	near
	uses	bx,cx,si
	.enter

	push	di			; save output offset
	clr	ax, cx			; start out with ah = 0, ch = 0

uncompress:
	lodsb				; load flag byte
	test	al, LZ77_SMALL_PAIR_FLAG
	jnz	smallPair

	test	al, LZ77_LITERALS_FLAG	; test for literals
	jz	pair			; else do pair

	test	al, LZ77_RUN_LENGTH_FLAG
	jnz	runLength

literals::
	and	al, not LZ77_LITERALS_FLAG
	jz	done			; done if no literals

	mov	cl, al			; cx = size of literals
	shr	cx, 1			; # of bytes -> # of words
	rep	movsw			; copy literal
	jnc	uncompress		; loop back for next pair
	movsb				; copy leftover byte
	jmp	uncompress		; loop back for next pair

runLength:
	and	al, not (LZ77_LITERALS_FLAG or LZ77_RUN_LENGTH_FLAG)
	clr	cx
	xchg	ax, cx			; ax = NULL, cx = run length
	shr	cx, 1			; # of bytes -> # of words
	rep	stosw			; write NULL's
	jnc	uncompress		; loop back for more
	stosb				; write NULL
	jmp	uncompress		; loop back for more

pair:
	mov	cl, al			; cx=cl = 4 length bits, 2 offset bits
	lodsb				; load low 8 bits of dictionary offset
	mov	bl, al			; bl = low 8 bits of dictionary offset
	mov	bh, cl			; bh has high bits of offset
	and	bh, (1 shl (LZ77_PAIR_POSITION_BITS-8)) - 1
					; bx = dictionary offset
	neg	bx
	add	bx, di			; bx = position in output buffer
	xchg	si, bx			; ds:si = source string
	CheckHack <(LZ77_PAIR_POSITION_BITS-8) eq 2>
	shr	cl, 1			; shift out offset bits
	shr	cl, 1
	add	cl, LZ77_MIN_MATCH_LENGTH	; cx = cl = size of string
	rep	movsb es:		; copy string from dictionary (warning)
	mov	si, bx			; restore compressed data offset
	jmp	uncompress		; loop back for more

smallPair:
	andnf	al, not LZ77_SMALL_PAIR_FLAG
	mov	bx, di
	sub	bx, ax			; bx = position in output buffer
	xchg	si, bx			; ds:si = source string
	movsb	es:			; copy a byte (not a word)
	movsb	es:			; copy a byte (not a word)
	movsb	es:			; copy a byte (not a word)
	mov	si, bx			; restore compressed data offset
	jmp	uncompress		; loop back for more
done:
	mov	ax, di			; ax = end of output
	pop	di			; di = start of output
	sub	ax, di			; ax = size of uncompressed data

	.leave
	ret
CVGFSUncompress	endp

Resident	ends
