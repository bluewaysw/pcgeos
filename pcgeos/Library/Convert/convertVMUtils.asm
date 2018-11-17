COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Convert
FILE:		convertVMUtils.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains utility stuff for converting from 1.X to 2.0

	$Id: convertVMUtils.asm,v 1.1 97/04/04 17:52:41 newdeal Exp $

------------------------------------------------------------------------------@

VMUtils segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertGetVMBlockList

DESCRIPTION:	Get a list of used blocks in a VM file and save it in a block
		of memory

CALLED BY:	INTERNAL

PASS:
	si - VM file handle

RETURN:
	ax - memory handle

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/18/92		Initial version

------------------------------------------------------------------------------@
ConvertGetVMBlockList	proc	far	uses bx, cx, dx, si, di, ds, es
	.enter

	mov	bx, si
	clr	ax
	call	VMSetAttributes	; aka VMMarkHeaderDirtySoItWontGoAwayOnMe

	mov	ax, SGIT_HANDLE_TABLE_SEGMENT
	call	SysGetInfo			;ax = kdata
	mov	ds, ax

	mov	bx, ds:[si].HF_otherInfo	;bx = HandleVM
	call	HandleP				; obey the rules of the road
	push	bx				;  and P the HandleVM

	mov	bx, ds:[bx].HVM_headerHandle
	call	MemThreadGrab
	mov	ds, ax
	push	bx
	
	mov	ax, ds:[VMH_numUsed]		; ax <- max blocks (count
						;  includes header block,
						;  which we never store, so
						;  this leaves room for
						;  required null-terminator)
	shl	ax				; storing words...

	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc			;bx = block to return
	mov	es, ax
	clr	di

	mov	si, offset VMH_blockTable
blockLoop:
	add	si, size VMBlockHandle
	cmp	si, ds:[VMH_lastHandle]
	je	blockLoopDone

	mov	al, ds:[si].VMBH_sig
	cmp	al, VMBT_USED
	jz	saveBlock
	cmp	al, VMBT_DUP
	jnz	blockLoop
saveBlock:
	mov	ax, si
	stosw
	jmp	blockLoop

blockLoopDone:

	clr	ax
	stosw

	call	MemUnlock
	mov_tr	ax, bx				;ax = block to return

	pop	bx			; bx <- header
	call	MemThreadRelease
	
	pop	bx			; bx <- HandleVM
	call	HandleV
	.leave
	ret

ConvertGetVMBlockList	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertDeleteViaBlockList

DESCRIPTION:	Delete blocks in a VM file

CALLED BY:	INTERNAL

PASS:
	si - VM file handle
	cx - memory handle

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/18/92		Initial version

------------------------------------------------------------------------------@
ConvertDeleteViaBlockList	proc	far	uses ax, bx, si, ds
	.enter

	mov	bx, cx
	push	bx
	call	MemLock
	mov	ds, ax
	mov	bx, si				;bx = file
	clr	si				;ds:si = list

blockLoop:
	lodsw
	tst	ax
	jz	done
	call	VMFree
	jmp	blockLoop
done:
	pop	bx
	call	MemFree

	.leave
	ret

ConvertDeleteViaBlockList	endp

VMUtils ends
