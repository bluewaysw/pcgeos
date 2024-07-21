COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido Input driver
FILE:		main.asm

AUTHOR:		Paul L. DuBois, Nov 30, 1994

ROUTINES:
	Name			Description
	----			-----------
    EXT FFIOpen			Initialize state for future driver
				operations

    EXT FFIClose		Destroy state creted in FFIOpen

    EXT FFIGetHeader		Return a buffer with header info in it

    EXT FFIGetPage		Return a buffer with page in it

    EXT FFIGetComplexData	Extract a VMTree from module

    INT FFI_OpenFile		Opens the file corresponding to the passed
				ML

    INT LockHeapDS		Lock global lmem heap into ds

    INT UnlockHeapDS		Unlock LMem heap in DS

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/30/94   	Initial revision
	dubois	4/29/96  	Modify for .bcl files

DESCRIPTION:
	
	$Revision:   1.1  $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


MainCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FFIOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize state for future driver operations

CALLED BY:	EXTERNAL, FFIStrategy (DR_FIDOI_OPEN)
PASS:		ds:si	- asciiz string
RETURN:		ax	- token to pass to other driver functions
		cf	- set on error
DESTROYED:	bx, di
SIDE EFFECTS:
	Allocate a chunk to hold state until DR_FIDOI_CLOSE.
	State right now is just a string: the module name without
	a trailing .BC suffix (but with space for a 3-char suffix)

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FFIOpen	proc	far
	uses	cx,dx, si, es,ds		; bx, di
	.enter
		LocalNextChar	dssi	; don't chare about leading //
		LocalNextChar	dssi
		movdw	esdi, dssi	; es:di/es:si <- module name
		call	LockHeapDS	; ds <- driver's state block

		LocalStrLength includeNull	; cx <- length

	; We do one of these conversions:
	;  ~T/world/foo		~T\world\foo		copy cx chars
	;  c/foo/bar/baz	c:\foo\bar\baz		copy cx+1 chars
	;
	; es:si <- module name
	; cx <- # chars to copy
	;
		LocalCmpChar	es:[si], C_ASCII_TILDE
		je	gotLength
		inc	cx		; add space for :
gotLength:

		clr	al
		add	cx, 4		; for possible 4-char suffix
DBCS <		shl	cx		; cx <- size			>
		call	LMemAlloc
DBCS <		shr	cx		; cx <- length			>
		sub	cx, 4

		segxchg	ds, es		; ds:si <- src string

		mov	di, ax
		mov_tr	dx, ax		; save chunk in dx
		mov	di, es:[di]	; es:di <- chunk
		
		LocalCmpChar	ds:[si], C_ASCII_TILDE
		je	copy

	; dssi is of form <drive>/... put the colon in by hand
		LocalGetChar	ax, dssi
		LocalPutChar	esdi, ax
		LocalLoadChar	ax, C_COLON
		LocalPutChar	esdi, ax
		sub		cx, 2
copy:
		LocalGetChar	ax, dssi
		LocalCmpChar	ax, C_SLASH
		jne		putChar
		LocalLoadChar	ax, C_BACKSLASH
putChar:
		LocalPutChar	esdi, ax
		loop		copy

		mov	bx, es:[LMBH_handle]
		clc

		lahf
		call	MemUnlock
		sahf
		mov_tr	ax, dx		; ax <- state token
	.leave
	ret
FFIOpen	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FFIClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy state creted in FFIOpen

CALLED BY:	EXTERNAL, FFIStrategy (DR_FIDOI_CLOSE)
PASS:		cx	- token received from FFIOpen
RETURN:		carry	- set on error
DESTROYED:	ax, (allowed to destroy bx, di)
SIDE EFFECTS:	
	Deletes state chunk

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FFIClose	proc	far
	.enter
		call	LockHeapDS
		mov	ax, cx
		call	LMemFree
		call	UnlockHeapDS
		Destroy	di, bx
	.leave
	ret
FFIClose	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FFIGetHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a buffer with header info in it

CALLED BY:	EXTERNAL, FFIStrategy (DR_FIDOI_GET_HEADER)
PASS:		cx	- token returned by DR_FIDOI_OPEN
RETURN:		bx	- buffer
		cf	- set on error
DESTROYED:	ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	First word is # pages in file (N)
	Next N dwords are offsets to the pages
	The header is everything between this array and page 0

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	12/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FFIGetHeader	proc	far

FileHeader	struct
    FH_numPages		word
    FH_page0Offset	dword
FileHeader	ends

	read_buf	local	FileHeader
	file_han	local	hptr
	block_han	local	hptr
	uses	cx, dx, ds
	.enter
		clr	ax		; open <file>.BCL
		call	FFI_OpenFile	; cx <- file handle
		mov	bx, cx
		mov	ss:[file_han], bx
		jc	done

		mov	cx, size FileHeader
		lea	dx, ss:[read_buf]
		segmov	ds, ss, ax	; ds:dx <- buffer
		clr	al
		call	FileRead
		jc	close

	; Seek to just after the array
	;
		mov	ax, ss:[read_buf].FH_numPages
		shl	ax		; # words in array
		inc	ax		; account for first word
		shl	ax		; # bytes in array

		mov_tr	dx, ax
		clr	cx		; cx:dx <- desired pos
		mov	al, FILE_POS_START
		call	FilePos		; dx:ax <- new pos

	; Alloc a block to read into
	; size = -(header offset - page 1 offset)
	;
		subdw	dxax, ss:[read_buf].FH_page0Offset, cx
		negdw	dxax
EC <		tst	dx						>
EC <		ERROR_NZ FFI_TOO_LARGE					>
		mov	dx, ax		; save size
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	close
		mov	ss:[block_han], bx

		mov	cx, dx		; cx <- size
		mov	ds, ax
		clr	dx		; ds:dx <- buffer
		mov	bx, ss:[file_han]
		call	FileRead
		jc	freeClose
		
		mov	bx, ss:[block_han]
		call	MemUnlock
		clc
close:
		pushf
		mov	al, FILE_NO_ERRORS
		mov	bx, ss:[file_han]
		call	FileClose
		mov	bx, ss:[block_han]
		popf
done:
	.leave
	ret
freeClose:
		mov	bx, ss:[block_han]
		call	MemFree
		stc
		jmp	close
FFIGetHeader	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FFIGetPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a buffer with page in it

CALLED BY:	EXTERNAL, FFIStrategy (DR_FIDOI_GET_PAGE)
PASS:		cx	- token received from FFIOpen
		dx	- page number
RETURN:		bx	- MemHandle
		carry	- set on error
DESTROYED:	ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	First word is # pages in file (N)
	Next N dwords are offsets to the pages
	The header is everything between this array and page 0

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FFIGetPage	proc	far
	page_num	local	word	push	dx
	num_pages	local	word
	offsets		local	2 dup(dword)
	file_han	local	hptr
	block_han	local	hptr
	uses	cx, dx, ds
	.enter
		clr	ax		; open <file>.BCL
		call	FFI_OpenFile	; cx <- file handle
		mov	bx, cx
		mov	ss:[file_han], bx
	LONG	jc	done

	; Snag # pages
	;
		mov	bx, cx		; bx <- handle
		mov	cx, 2
		lea	dx, ss:[num_pages]
		segmov	ds, ss, ax	; ds:dx <- buffer
		clr	al
		call	FileRead
		jc	jc_close

	; skip page_num dwords forward to get at offsets

		mov	al, FILE_POS_RELATIVE
		clr	cx
		mov	dx, ss:[page_num]
		shl	dx
		shl	dx		; cx:dx <- seek amount
		call	FilePos

		clr	al
		mov	cx, 8
		lea	dx, ss:[offsets]
		call	FileRead
jc_close:	jc	close

		mov	dx, ss:[page_num]
		inc	dx		; page # is 0-based
		cmp	dx, ss:[num_pages]
		ja	errorClose
		jne	seek

	; If reading the last page, must snag the file size
	;
		call	FileSize
		movdw	ss:[offsets][4], dxax

seek:
		mov	al, FILE_POS_START
		movdw	cxdx, ss:[offsets]
		call	FilePos		; dxax <- current pos

	; Alloc a block to read into
	;
		subdw	dxax, ss:[offsets][4]
		negdw	dxax
EC <		tst	dx						>
EC <		ERROR_NZ FFI_TOO_LARGE					>
		mov	dx, ax		; save size
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	close
		mov	ss:[block_han], bx

		mov	cx, dx		; cx <- size
		mov	ds, ax
		clr	dx		; ds:dx <- buffer
		mov	bx, ss:[file_han]
		call	FileRead
		jc	freeClose
		
		mov	bx, ss:[block_han]
		call	MemUnlock
		clc

close:
		pushf
		mov	al, FILE_NO_ERRORS
		mov	bx, ss:[file_han]
		call	FileClose
		mov	bx, ss:[block_han]
		popf
done:
	.leave
	ret
freeClose:
		mov	bx, ss:[block_han]
		call	MemFree
errorClose:
		stc
		jmp	close
FFIGetPage	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FFIGetComplexData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract a VMTree from module

CALLED BY:	EXTERNAL, FFIStrategy (DR_FIDOI_GET_COMPLEX_DATA)
PASS:		bx	- destination vm file
		cx	- token
		dx	- data element
RETURN:		carry	- set on failure
		^vbx:ax:si	- VMTree (bx unchanged)
		cx:dx	- format
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 2/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FFIGetComplexData	proc	far
	uses	bx,ds,bp
	.enter
		mov	ax, 1		; open <file>.RSC
		call	FFI_OpenFile
		jc	done

		push	bx		; save dest vm file
		mov	bx, cx		; bx <- source vm file

		call	VMGetMapBlock	; ax <- map
		tst	ax
		jz	errorPopBX
		call	VMLock
		mov	ds, ax
		mov	si, ds:[RFH_complexDataArray]
		mov_tr	ax, dx
		call	ChunkArrayElementToPtr
		pop	dx		; dx <- dest vm file
		jc	errorUnlock

	; *ds:si - chunkarray
	; ds:di	- element
	; bx,dx	- source,dest vm file
	; bp	- handle of map block
	;
		xchg	bp, si		; save bp
		movdw	axbp, ds:[di].CDE_chain
		call	VMCopyVMChain
		xchg	bp, si		; ax:si <- dest chain, bp restored

		movdw	cxdx, ds:[di].CDE_format

		clc

doneUnlock:
		push	ax		; save block
		pushf
		call	VMUnlock
		mov	al, FILE_NO_ERRORS
		call	VMClose
		popf
		pop	ax
done:
	.leave
	ret
errorPopBX:
		pop	bx
		stc
		jmp	done
errorUnlock:
		stc
		jmp	doneUnlock
FFIGetComplexData	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FFI_OpenFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens the file corresponding to the passed ML

CALLED BY:	INTERNAL, FFIGet*
PASS:		ax	- zero to open .BCL file, non-zero to open .RSC file
		cx	- state token (ChunkHandle)

RETURN:		cx	- VMFileHandle or FileHandle
		cf	- set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	path should look like:
	~D\basic\foo.bc		(document dir)
	F:\20x.ec\basic\foo.bc

	Temporarily replace char after final backslash with a null to
	split string into a path and filename

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 7/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FFI_OpenFile	proc	near
	bcOrRsc	local	word	push	ax
	nullPtr	local	word		;saved pointer to end of string
	uses	ax,bx,dx, es,ds, si
	.enter

	; Convert state token into the module name
	;
		call	LockHeapDS

		mov	si, cx
		mov	si, ds:[si]	; ds:si <- module name

		mov	bx, 0		; assume relative to cwd
		
		LocalGetChar	ax, dssi, noAdvance
		LocalCmpChar	ax, C_ASCII_TILDE
		jne	gotDisk

	; Starts with ~ -- grab and advance past ~ identifier
	; and set disk appropriately.  Just do it the obvious
	; and slow way for now
	;
		LocalNextChar	dssi
		LocalGetChar	ax, dssi

		mov	bx, SP_APPLICATION
		LocalCmpChar	ax, C_CAP_A
		je	gotDisk

		mov	bx, SP_DOCUMENT
		LocalCmpChar	ax, C_CAP_D
		je	gotDisk

		mov	bx, SP_SYSTEM
		LocalCmpChar	ax, C_CAP_S
		je	gotDisk

		mov	bx, SP_TOP
		LocalCmpChar	ax, C_CAP_T
		je	gotDisk
		
		mov	bx, SP_TOP	; just default to SP_TOP for now
		
gotDisk:
	; Find last '\' char in string and replace with null.
	; di is left pointing at the filename
	;
		segmov	es, ds, ax
		mov	di, si
		mov	cx, -1
		clr	ax
		LocalFindChar		; repne scas[bw]
		not	cx

	; si	- points to beginning of path
	; di	- points after final null
	; bx	- disk handle for FileSetCurrentPath
	; cx	- # chars including null
	; set	ds:dx -	path
	;	ds:di -	filename
	;
	; 1. append ".RSC" or ".BC"
	; 2. replace char after last  '\' with a null,
	;    to split into path and file
	; 3. Set current path and restore '\'
	;

	; [1] - append extension
		LocalPrevChar	esdi	; point at trailing NULL
		mov	ss:[nullPtr], di
		LocalLoadChar	ax, C_PERIOD
		LocalPutChar	esdi, ax

		tst	ss:[bcOrRsc]
		jz	appendBC
		LocalLoadChar	ax, C_CAP_R
		LocalPutChar	esdi, ax
		LocalLoadChar	ax, C_CAP_S
		LocalPutChar	esdi, ax
		LocalLoadChar	ax, C_CAP_C
		LocalPutChar	esdi, ax
		LocalLoadChar	ax, C_NULL
		LocalPutChar	esdi, ax
		jmp	afterAppend
appendBC:
		LocalLoadChar	ax, C_CAP_B
		LocalPutChar	esdi, ax
		LocalLoadChar	ax, C_CAP_C
		LocalPutChar	esdi, ax
		LocalLoadChar	ax, C_CAP_F
		LocalPutChar	esdi, ax
		LocalLoadChar	ax, C_NULL
		LocalPutChar	esdi, ax
afterAppend:

	; [2] - break string after '\'
		mov	di, ss:[nullPtr]
		LocalLoadChar	ax, C_BACKSLASH
		std
		LocalFindChar
		cld
		jnz	errorDone

		LocalNextChar	esdi
		LocalNextChar	esdi	; point after '\'
		clr	cx		; set es:di to null and save
SBCS <		xchg	cl, es:[di]	;   nuked char in cx		>
DBCS <		xchg	cx, es:[di]					>

	; [3] - set path, restore char after '\'
		mov	dx, si		; ds:dx <- path
		call	FilePushDir
		call	FileSetCurrentPath
SBCS <		mov	es:[di], cl	; restore the char		>
DBCS <		mov	es:[di], cx					>

	; Open .RSC file (VM) or .BCL file (DOS)

		tst	ss:[bcOrRsc]
		jz	dosFile


		jc	afterVMOpen	; easier to handle error this way
		mov	dx, di
		clr	cx		
		mov	ax, (VMO_OPEN shl 8) or mask VMAF_FORCE_READ_ONLY \
				or mask VMAF_FORCE_DENY_WRITE \
				or mask VMAF_FORCE_SHARED_MULTIPLE
			
		call	VMOpen
		mov	bx, cx
		jmp	afterVMOpen

dosFile:
		mov	dx, di
		mov	ax, FILE_ACCESS_R or FILE_DENY_W
		call	FileOpen
		mov_tr	cx, ax
		
afterVMOpen:

	; Remove trailing .BC or .RSC by restoring NULL
	;
		mov	di, ss:[nullPtr]
SBCS <		mov	{byte} es:[di], C_NULL				>
DBCS <		mov	{word} es:[di], C_NULL				>

		jc	errorPopDone
		call	FilePopDir
		clc
done:
		call	UnlockHeapDS
	.leave
	ret

errorPopDone:
		call	FilePopDir
errorDone:
		stc
		jmp	done
FFI_OpenFile	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockHeapDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock global lmem heap into ds

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		ds	- global lmem heap
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 7/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockHeapDS	proc	near
		push	ax, bx
		segmov	ds, dgroup, ax
		mov	bx, ds:[stateHeap]
		call	MemLock
		mov	ds, ax
		pop	ax, bx
	ret
LockHeapDS	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockHeapDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock LMem heap in DS

CALLED BY:	INTERNAL
PASS:		ds	- lmem heap
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 7/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockHeapDS	proc	near
		push	bx
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
		pop	bx
	ret
UnlockHeapDS	endp

MainCode	ends
