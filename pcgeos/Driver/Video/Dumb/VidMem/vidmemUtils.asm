COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem video driver	
FILE:		vidmemUtils.asm

AUTHOR:		Jim DeFrisco, Feb 13, 1992

ROUTINES:
	Name			Description
	----			-----------
	LockHugeBlock		Lock a HugeArray data block
	LockHugeBlockSrc	Lock a HugeArray data block
	NextHugeBlock		at the end of the current block, lock the
				next one
	NextHugeBlockSrc	at the end of the current block, lock the
				next one
	PrevHugeBlock		go to previous HugeArray block
	PrevHugeBlockSrc	go to previous HugeArray block
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/13/92		Initial revision


DESCRIPTION:
	various HugeArray related utilities that are common to all vidmem
	modules
		

	$Id: vidmemUtils.asm,v 1.1 97/04/18 11:42:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockHugeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a HugeArray data block

CALLED BY:	CalcScanLine macro
PASS:		ax	- scan line number
RETURN:		ds:si	- pointer to scan line
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		call HugeArrayLock, then add in offset stored at 
		cs:bm_byteOffset

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockHugeBlock	proc	far
		uses	dx, cx, bx, di
		.enter
EC <		call	ECCheckWriteLock				>
		clr	dx
		mov	bx, cs:[bm_handle].segment 
		mov	di, cs:[bm_handle].offset
		call	HugeArrayLock
		add	si, cs:[bm_dataOffset]	; accounts for mask
		mov	cs:[bm_scansNext], ax
		tst	ax			; if zero, elem # out of bounds
		jz	badScan
		mov	cs:[bm_scansPrev], cx
		mov	cs:[bm_lastSeg], ds
EC <		mov	cs:[bm_ec_lastOffset], si			>
EC <		mov	cs:[bm_ec_lastLineSize], dx			>
EC <		push	ax, cx, dx					>
EC <		mov	cx, dx						>
EC <		mul	cx			; bytes of data buffer	>
EC <		mov	cs:[bm_ec_lastSliceSize], ax			>
EC <		pop	ax, cx, dx					>
		add	si, cs:[bm_byteOffset] 
done:
		.leave
		ret

		; scan line number that was passed is out of bounds
badScan:
		mov	cs:[bm_lastSeg], ax	; clear this -- nothing locked
		jmp	done
LockHugeBlock	endp

LockHugeBlockSrc proc	far
		uses	dx, cx, bx, di
		.enter
EC <		call	ECCheckReadLock					>
		clr	dx
		mov	bx, cs:[bm_handle].segment 
		mov	di, cs:[bm_handle].offset
		call	HugeArrayLock
		add	si, cs:[bm_dataOffset]	; accounts for mask
		mov	cs:[bm_scansNextSrc], ax
		tst	ax			; if zero, elem # out of bounds
		jz	badScan
		mov	cs:[bm_scansPrevSrc], cx
		mov	cs:[bm_lastSegSrc], ds
		add	si, cs:[bm_byteOffsetSrc] 
done:
		.leave
		ret

		; scan  line number that was passed is out of bounds
badScan:
		mov	cs:[bm_lastSegSrc], ax	; clear this -- nothing locked
		jmp	done
LockHugeBlockSrc endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NextHugeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	at the end of the current block, lock the next one

CALLED BY:	NextScan macro
PASS:		es:di	- pointer into scan line
RETURN:		es:di	- pointer to scan line, next block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		use HugeArrayNext

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		NOTE: these routines will return bm_scansNext{,Src} =-1
		      if the call to HugeArrayNext was unsuccessful

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NextHugeBlock		proc	far
		uses	ax, dx, ds
		.enter
		segmov	ds, es, ax
EC <		cmp	ax, cs:[bm_lastSeg]	; if these not ==, it's bad >
EC <		ERROR_NE VIDMEM_HUGE_ARRAY_PROBLEM ; 			>
		xchg	si, di
		sub	si, cs:[bm_byteOffset]	; back to beginning of scan
		sub	si, cs:[bm_dataOffset]
		call	HugeArrayDirty
		call	HugeArrayNext
		add	si, cs:[bm_dataOffset]	; accounts for mask
		tst	ax			; if zero, store bogus value
		jnz	storeNext
		dec	ax			
storeNext:
		mov	cs:[bm_scansNext], ax	; store #scans in this block
		mov	cs:[bm_lastSeg], ds	; save new data segment
EC <		mov	cs:[bm_ec_lastOffset], si			>
EC <		push	ax, cx, dx					>
EC <		mov	cx, cs:[bm_ec_lastLineSize]			>
EC <		mul	cx			; bytes of data buffer	>
EC <		mov	cs:[bm_ec_lastSliceSize], ax			>
EC <		mov	ax, cs:[bm_dataOffset]	; subtract mask room	>
EC <		sub	cs:[bm_ec_lastSliceSize], ax			>
EC <		pop	ax, cx, dx					>
		add	si, cs:[bm_byteOffset]	; index into scan line
		segmov	es, ds, ax
		xchg	di, si

		.leave
		ret
NextHugeBlock		endp

NextHugeBlockSrc	proc	far
		uses	ax, dx, ds
		.enter
		segmov	ds, es, ax
EC <		cmp	ax, cs:[bm_lastSegSrc]	; if these not ==, it's bad >
EC <		ERROR_NE VIDMEM_HUGE_ARRAY_PROBLEM ; 			>
		xchg	si, di
		sub	si, cs:[bm_byteOffsetSrc] ; back to beginning of scan
		sub	si, cs:[bm_dataOffset]
		call	HugeArrayDirty
		call	HugeArrayNext
		add	si, cs:[bm_dataOffset]	  ; accounts for mask
		mov	cs:[bm_lastSegSrc], ds	  ; save new data segment
		tst	ax			; if zero, store bogus value
		jnz	storeNext
		dec	ax			
storeNext:
		mov	cs:[bm_scansNextSrc], ax  ; store #scans in this block
		add	si, cs:[bm_byteOffsetSrc] ; index into scan line
		segmov	es, ds, ax
		xchg	di, si
		.leave
		ret
NextHugeBlockSrc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrevHugeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	go to previous HugeArray block

CALLED BY:	PrevScan macro
PASS:		es:di 	- pointer into scan line
RETURN:		es:di	- pointer into previous scan line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just use HugeArrayPrev

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		NOTE: these routines will return bm_scansPrev{,Src} =-1
		      if the call to HugeArrayPrev was unsuccessful
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrevHugeBlock		proc	far
		uses	ax,dx,ds,si
		.enter
		segmov	ds, es, ax
EC <		cmp	ax, cs:[bm_lastSeg]	; if these not ==, it's bad >
EC <		ERROR_NE VIDMEM_HUGE_ARRAY_PROBLEM ; 			>
		mov	si, di
		sub	si, cs:[bm_byteOffset]
		sub	si, cs:[bm_dataOffset]
		call	HugeArrayDirty
		call	HugeArrayPrev
		add	si, cs:[bm_dataOffset]	; accounts for mask
		mov	cs:[bm_lastSeg], ds
		tst	ax			; if zero, store bogus value
		jnz	storeNext
		dec	ax			
storeNext:
		mov	cs:[bm_scansPrev], ax
		add	si, cs:[bm_byteOffset]
		segmov	es, ds, ax
		mov	di, si
		.leave
		ret
PrevHugeBlock		endp

PrevHugeBlockSrc	proc	far
		uses	ax,dx,ds,si
		.enter
		segmov	ds, es, ax
EC <		cmp	ax, cs:[bm_lastSegSrc]	; if these not ==, it's bad >
EC <		ERROR_NE VIDMEM_HUGE_ARRAY_PROBLEM ; 			>
		mov	si, di
		sub	si, cs:[bm_byteOffsetSrc]
		sub	si, cs:[bm_dataOffset]
		call	HugeArrayDirty
		call	HugeArrayPrev
		add	si, cs:[bm_dataOffset]	; accounts for mask
		mov	cs:[bm_lastSegSrc], ds
		tst	ax			; if zero, store bogus value
		jnz	storeNext
		dec	ax			
storeNext:
		mov	cs:[bm_scansPrevSrc], ax
		add	si, cs:[bm_byteOffsetSrc]
		segmov	es, ds, ax
		mov	di, si
		.leave
		ret
PrevHugeBlockSrc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckBitmapLocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Error checking code to catch bad lock/unlock nesting

CALLED BY:	INTERNAL
		SetBuffer macro
PASS:		nothing
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
ECCheckBitmapLocks	proc	far
		cmp	dgseg:[bm_lastSeg], 0
		ERROR_NZ VIDMEM_HUGE_ARRAY_PROBLEM
		cmp	dgseg:[bm_lastSegSrc], 0
		ERROR_NZ VIDMEM_HUGE_ARRAY_PROBLEM
		ret
ECCheckBitmapLocks	endp

ECCheckReadLock	proc	near
		cmp	dgseg:[bm_lastSegSrc], 0
		ERROR_NZ VIDMEM_HUGE_ARRAY_PROBLEM
		ret
ECCheckReadLock	endp

ECCheckWriteLock proc	near
		cmp	dgseg:[bm_lastSeg], 0
		ERROR_NZ VIDMEM_HUGE_ARRAY_PROBLEM
		ret
ECCheckWriteLock endp
endif
