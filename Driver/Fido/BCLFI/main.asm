COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido Input driver
FILE:		vmfimain.asm

AUTHOR:		Paul L. DuBois, Nov 30, 1994

ROUTINES:
	Name			Description
	----			-----------
    EXT BCLFIOpen		Initialize state for future driver operations

    EXT BCLFIClose		Destroy state creted in BCLFIOpen

    EXT BCLFIGetHeader		Return a buffer with header info in it

    EXT BCLFIGetPage		Return a buffer with page in it

    EXT BCLFIGetComplexData	Extract a VMTree from module

    INT BCLFI_OpenFile		Opens the file corresponding to the passed
				URL

    INT LockHeapDS		Lock global lmem heap into ds

    INT UnlockHeapDS		Unlock LMem heap in DS

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/30/94   	Initial revision


DESCRIPTION:
	
	$Revision:   1.15  $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



MainCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BCLFIOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize state for future driver operations

CALLED BY:	EXTERNAL, BCLFIStrategy (DR_FIDOI_OPEN)
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
BCLFIOpen	proc	far
	uses	cx,dx, si, es,ds		; bx, di
	.enter
		movdw	esdi, dssi	; es:di/es:si <- module name
		call	LockHeapDS	; ds <- driver's state block


	; # chars to copy, not including NULL <- cx
	;

REMOVE_SUFFIX equ 0
;; dubois 9/19 -- remove code that strips off trailing .XXX suffix
;; since module names shouldn't have them any more
;;
if REMOVE_SUFFIX
		LocalStrLength	includeNull
		LocalPrevChar	esdi	; point to NULL

		std
		mov	dx, cx		; save size
		LocalLoadChar	ax, C_PERIOD
		LocalFindChar
		cld

		je	gotSize
		mov	cx, dx		; no period, so restore original size
		dec	cx		; don't want NULL
else		
		LocalStrLength
endif

gotSize:
	; es:si <- module name
	; cx <- # chars to copy
	;
		clr	al
		add	cx, 5		; for NULL and possible 4-char suffix
DBCS <		shl	cx		; cx <- size			>
		call	LMemAlloc
DBCS <		shr	cx		; cx <- length			>
		sub	cx, 5

		segxchg	ds, es		; ds:si <- src string

		mov	di, ax
		mov_tr	dx, ax		; save chunk in dx
		mov	di, es:[di]	; es:di <- chunk
		
		LocalCopyNString
		LocalLoadChar	ax, C_NULL
		LocalPutChar	esdi, ax

		mov	bx, es:[LMBH_handle]
		clc

		lahf
		call	MemUnlock
		sahf
		mov_tr	ax, dx		; ax <- state token
	.leave
	ret
BCLFIOpen	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BCLFIClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy state creted in BCLFIOpen

CALLED BY:	EXTERNAL, BCLFIStrategy (DR_FIDOI_CLOSE)
PASS:		cx	- token received from BCLFIOpen
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
BCLFIClose	proc	far
	.enter
		call	LockHeapDS
		mov	ax, cx
		call	LMemFree
		call	UnlockHeapDS
		Destroy	di, bx
	.leave
	ret
BCLFIClose	endp
		



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BCLFIReAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	little helper routine

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BCLFIReAllocAndRead	proc	near
		uses	cx
		.enter
		mov	ax, cx
		add	ax, dx
		clr	ch
		push	ax
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		pop	cx
		cmp	ax, cx
		jge	read

		shl	ax
		call	MemReAlloc
		call	MemDerefDS
read:
		pushdw	dsdx
		push	cx
		mov	ax, 1
		push	ax
		push	dxbx	; only bx matters here
		call	FREAD
		tst	ax
		jz	error
		clc
done:
		.leave
		ret
error:
		stc
		jmp	done
BCLFIReAllocAndRead	endp


		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BCLFIReadStringTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read in a string table

CALLED BY:	
PASS:		ds:dx = buffer to read info, bx = file handle
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BCLFIReadStringTable	proc	near
		uses	ax,bx,cx,si,di,bp,es
		.enter
		mov	cx, 2
		call	BCLFIReAllocAndRead
		jc	done
		cmp	{word}ds:[dx], PM_PAD_BYTE
		jne	afterPad
		add	dx, 2
		mov	cx, 2
		call	BCLFIReAllocAndRead
		jc	done
afterPad:
		mov	cx, 2
		call	BCLFIReAllocAndRead
		jc	done
		mov	cx, ds:[dx]
		add	dx, 2
		mov	di, dx
		segmov	es, ds
stringLoop:
		push	cx
		pushdw	dxbx
innerLoop:		
		call	FGETC
		stosb
		tst	al
		jnz	innerLoop
nextString:
		pop	cx
		loop	stringLoop
		clc
done:
		.leave
		ret
BCLFIReadStringTable	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BCLFIGetHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a buffer with header info in it

CALLED BY:	EXTERNAL, BCLFIStrategy (DR_FIDOI_GET_HEADER)
PASS:		cx	- token returned by DR_FIDOI_OPEN
RETURN:		bx	- buffer
		cf	- set on error
DESTROYED:	ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	12/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BCLFIGetHeader	proc	far
numFunctions	local	word
		uses	cx, ds, bp, es
		.enter
		
		clr	ax		; open <file>.BC
		call	BCLFI_OpenFile
		jc	done

		push	cx
		mov	ax, 32
		mov	cl, mask HF_SHARABLE or mask HF_SWAPABLE
		mov	ch, mask HAF_LOCK
		call	MemAlloc
		mov	ds, ax		; destination buffer
		pop	cx
		jc	done
		push	bx
		mov	bx, cx		; bx <- file handle
		clr	dx
		clr	al
		mov	cx, size BCLFileHeader
		clr	dx
		call	BCLFIReAllocAndRead
		jc	doneFree
		add	dx, cx
		mov	cx, ds:BCLFH_numModuleVars
		mov	ax, cx
		shl	ax
		add	cx, ax	; read in 3 * numModuleVars bytes
		add	cx, 2	; and numFunctions too
		call	BCLFIReAllocAndRead
		jc	doneFree
		add	dx, cx
		mov	cx, ds:[dx-2]	; get number of functions
		mov	numFunctions, cx
		shl	cx		; read in two * numFunctions
		add	cx, 2		; add number of structures
		call	BCLFIReAllocAndRead
		jc	doneFree
		add	dx, cx
		mov	cx, ds:[dx-2]
		jcxz	getFuncs
structLoop:
		push	cx
		mov	cx, 2
		call	BCLFIReAllocAndRead
		jc	doneFree
		mov	cx, ds:[dx]
		add	dx, 2
		mov	ax, cx
		shl	ax
		add	cx, ax
		call	BCLFIReAllocAndRead
		jc	doneFree
		add	dx, cx
		pop	cx
		loop	structLoop

		call	BCLFIReadStringTable
		jc	doneFree
		call	BCLFIReadStringTable
		jc	doneFree
		call	BCLFIReadStringTable
		jc	doneFree

		mov	cx, 2
		call	BCLFIReAllocAndRead
		
		pushdw	dxbx
		call	FCLOSE
		pop	bx
		clc
done:
		.leave
		ret
error:
		stc
		jmp	done
doneFree:
		call	MemFree
		pop	bx
		jmp	error
		
BCLFIGetHeader	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BCLFIGetPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a buffer with page in it

CALLED BY:	EXTERNAL, BCLFIStrategy (DR_FIDOI_GET_PAGE)
PASS:		cx	- token received from BCLFIOpen
		dx	- page number
RETURN:		bx	- MemHandle
		carry	- set on error
DESTROYED:	ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BCLFIGetPage	proc	far
	uses	cx, dx, ds, si, bp
	.enter
		clr	ax		; open <file>.BC
		call	BCLFI_OpenFile
		jc	done
		push	cx
		mov	ax, 32
		mov	cl, mask HF_SHARABLE or mask HF_SWAPABLE
		mov	ch, mask HAF_LOCK
		call	MemAlloc
		mov	ds, ax		; destination buffer
		pop	cx
		jc	done
		push	bx

		clr	dx
funcLoop:
		mov	cx, 2
		call	BCLFIReAllocAndRead
		cmp	{word}ds:[dx], PM_FUNC
		jne	doneOK
		push	cx
		mov	cx, 7
		call	BCLFIReAllocAndRead
		jc	doneFree
		add	dx, 7
		mov	cx, ds:[dx-9]
		call	BCLFIReAllocAndRead
		jc	doneFree
		add	dx, cx
		pop	cx
		loop	funcLoop

		pushdw	dxbx
		call	FCLOSE
		pop	bx
doneOK:
		clc
done:
	.leave
	ret
error:
		stc
		jmp	done
errorUnlock:
		call	VMUnlock
		stc
		jmp	done
BCLFIGetPage	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BCLFIGetComplexData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract a VMTree from module

CALLED BY:	EXTERNAL, BCLFIStrategy (DR_FIDOI_GET_COMPLEX_DATA)
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
BCLFIGetComplexData	proc	far
	uses	bx,ds,bp
	.enter
	.leave
	ret
BCLFIGetComplexData	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BCLFI_OpenFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens the file corresponding to the passed URL

CALLED BY:	INTERNAL, BCLFIGet*
PASS:		ax	- zero to open .BC file, non-zero to open .RSC file
		cx	- state token (ChunkHandle)

RETURN:		cx = low word of FILE *fp
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
formatStr char "r", 0
BCLFI_OpenFile	proc	near
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

		jc	afterVMOpen	; easier to handle error this way

	;		mov	dx, di
	;	mov	al, FILE_ACCESS_R or FILE_DENY_NONE
	;	call	FileOpen
		pushdw	dsdi
		lds	di, formatStr
		pushdw	dssi
		call	FOPEN
afterVMOpen:

	; Remove trailing .BC or .RSC by restoring NULL
	;
		mov	di, ss:[nullPtr]
SBCS <		mov	{byte} es:[di], C_NULL				>
DBCS <		mov	{word} es:[di], C_NULL				>

		jc	errorPopDone
		mov	cx, ax
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
BCLFI_OpenFile	endp


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
