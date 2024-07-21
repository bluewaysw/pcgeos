COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido Input driver
FILE:		vmfimain.asm

AUTHOR:		Paul L. DuBois, Nov 30, 1994

ROUTINES:
	Name			Description
	----			-----------
    EXT VMFIOpen		Initialize state for future driver operations

    EXT VMFIClose		Destroy state creted in VMFIOpen

    EXT VMFIGetHeader		Return a buffer with header info in it

    EXT VMFIGetPage		Return a buffer with page in it

    EXT VMFIGetComplexData	Extract a VMTree from module

    INT VMFI_OpenVMFile		Opens the file corresponding to the passed
				URL

    INT VMFI_VMDetach		Wrapper around VMDetach to work around bug

    INT LockHeapDS		Lock global lmem heap into ds

    INT UnlockHeapDS		Unlock LMem heap in DS

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/30/94   	Initial revision


DESCRIPTION:

	$Id: vmfimain.asm,v 1.1 97/12/02 11:37:29 gene Exp $	
	$Revision: 1.1 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


MainCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMFIOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize state for future driver operations

CALLED BY:	EXTERNAL, VMFIStrategy (DR_FIDOI_OPEN)
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
VMFIOpen	proc	far
	uses	cx,dx, si, es,ds		; bx, di
	.enter
		LocalGetChar	ax, dssi	; don't chare about leading //
		LocalCmpChar	ax, C_SLASH
		jne	error		
		LocalGetChar	ax, dssi
		LocalCmpChar	ax, C_SLASH
		jne	error
		
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
SBCS <		clr	ah		; don't pass DBCS char		>
		LocalGetChar	ax, dssi
		call	LocalIsAlpha
		jz	errorFree
		
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
done:
		.leave
		ret
errorFree:
	; dx = allocated chunk
		mov	ax, dx
		segxchg	ds, es
		call	LMemFree
		call	UnlockHeapDS
error:
		stc
		jmp	done
VMFIOpen	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMFIClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy state creted in VMFIOpen

CALLED BY:	EXTERNAL, VMFIStrategy (DR_FIDOI_CLOSE)
PASS:		cx	- token received from VMFIOpen
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
VMFIClose	proc	far
	.enter
		call	LockHeapDS
		mov	ax, cx
		call	LMemFree
		call	UnlockHeapDS
		Destroy	di, bx
	.leave
	ret
VMFIClose	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMFIGetHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a buffer with header info in it

CALLED BY:	EXTERNAL, VMFIStrategy (DR_FIDOI_GET_HEADER)
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
VMFIGetHeader	proc	far
	uses	cx, ds, bp
	.enter
		clr	ax		; open <file>.BC
		call	VMFI_OpenVMFile
		jc	done

		mov	bx, cx		; bx <- vm file
		call	VMGetMapBlock	; ax <- map
		tst	ax
		jz	error
		call	VMLock
		mov	ds, ax
		mov	ax, ds:[CFH_header]
		call	VMUnlock	; unlock map
		clr	cx
		call	VMFI_VMDetach

	; di <- block to return
	;
		mov	al, FILE_NO_ERRORS
		call	VMClose
		mov	bx, di		; bx <- header
done:
	.leave
	ret
error:
		stc
		jmp	done
VMFIGetHeader	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMFIGetPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a buffer with page in it

CALLED BY:	EXTERNAL, VMFIStrategy (DR_FIDOI_GET_PAGE)
PASS:		cx	- token received from VMFIOpen
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
VMFIGetPage	proc	far
	uses	cx, dx, ds, si, bp
	.enter
		clr	ax		; open <file>.BC
		call	VMFI_OpenVMFile
		jc	done

		mov	bx, cx		; bx <- vm file
		call	VMGetMapBlock	; map <- ax
		tst	ax
		jz	error
		call	VMLock
		mov	ds, ax
		mov	si, ds:[CFH_pageArray]
		mov_tr	ax, dx
		call	ChunkArrayElementToPtr
		jc	errorUnlock

		mov	ax, ds:[di]	; ax <- vm block of page
		call	VMUnlock

		clr	cx
		call	VMFI_VMDetach	; di <- mem block of page
		mov	al, FILE_NO_ERRORS
		call	VMClose
		mov	bx, di
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
VMFIGetPage	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMFIGetComplexData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract a VMTree from module

CALLED BY:	EXTERNAL, VMFIStrategy (DR_FIDOI_GET_COMPLEX_DATA)
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
VMFIGetComplexData	proc	far
	uses	bx,ds,bp
	.enter
		mov	ax, 1		; open <file>.RSC
		call	VMFI_OpenVMFile
		jc	done

		push	bx		; save dest vm file
		mov	bx, cx		; bx <- source vm file

		call	VMGetMapBlock	; ax <- map
		tst	ax
		jz	errorPopBX
		call	VMLock
		mov	ds, ax
		mov	si, ds:[CFH_complexDataArray]
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
VMFIGetComplexData	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMFI_OpenVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens the file corresponding to the passed URL

CALLED BY:	INTERNAL, VMFIGet*
PASS:		ax	- zero to open .BC file, non-zero to open .RSC file
		cx	- state token (ChunkHandle)

RETURN:		cx	- VMFileHandle
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
VMFI_OpenVMFile	proc	near
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

		mov	bx, SP_USER_DATA
		LocalCmpChar	ax, C_CAP_U
		je	gotDisk

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
		mov	dx, di
		clr	cx		
		mov	ax, (VMO_OPEN shl 8) or mask VMAF_FORCE_READ_ONLY \
				or mask VMAF_FORCE_DENY_WRITE \
				or mask VMAF_FORCE_SHARED_MULTIPLE
			
		call	VMOpen
afterVMOpen:

	; Remove trailing .BC or .RSC by restoring NULL
	;
		mov	di, ss:[nullPtr]
SBCS <		mov	{byte} es:[di], C_NULL				>
DBCS <		mov	{word} es:[di], C_NULL				>

		jc	errorPopDone
		mov	cx, bx
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
VMFI_OpenVMFile	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMFI_VMDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wrapper around VMDetach to work around bug

CALLED BY:	INTERNAL, VMFIGetPage VMFIGetHeader
PASS:		As for VMDetach
RETURN:			"
DESTROYED:		"
SIDE EFFECTS:	
	Returned block is guaranteed to be unlocked.
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 2/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMFI_VMDetach	proc	near
		call	VMDetach	; di <- handle, possibly locked once

		push	dx, ds
		mov	ax, SGIT_HANDLE_TABLE_SEGMENT
		call	SysGetInfo
		mov	ds, ax
		tst	ds:[di].HM_lockCount
		jz	popDone

		xchg	bx, di
		call	MemUnlock
		xchg	bx, di
popDone:
		pop	dx, ds
		ret
VMFI_VMDetach	endp

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
