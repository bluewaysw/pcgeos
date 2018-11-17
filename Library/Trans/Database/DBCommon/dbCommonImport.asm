COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Database	
MODULE:		DBCommon
FILE:		dbCommonImport.asm

AUTHOR:		Ted H. Kim, 10/22/92

ROUTINES:
	Name			Description
	----			-----------
	ImportCreateNotMappedColumnList
				Create a list of not-mapped columns
	ImportGetActualColumnNumber
				Get actual column number
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	10/92		Initial revision

DESCRIPTION:
	This file contains common import routines for database libraries. 

	$Id: dbCommonImport.asm,v 1.1 97/04/07 11:43:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Import	segment	resource

if	0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportCreateNotMappedColumnList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a list of columns that are not mapped.

CALLED BY:	(INTERNAL)

PASS:		bx - handle of map block

RETURN:		bx - handle of not-mapped column list block

DESTROYED:	ax, bx, cx, dx, es, di 

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportCreateNotMappedColumnList	proc	near
	mapBlock	local	hptr
	numFields	local	word
	notMappedBlk	local	hptr
	.enter

	; initialize the stack frame

	clr	dx
	clr	notMappedBlk
	mov	mapBlock, bx
	tst	bx				; no map block?
	je	exit				; if not, just exit

	; grab the number of output fields from map list block

	call    MemLock                         ; lock map block
	mov     es, ax
	clr     di                              ; es:di - header
	mov     cx, es:[di].MLBH_numDestFields  ; cx - # of fields
	mov	numFields, cx
	call	MemUnlock

	; get the mapped column number
nextField:
	mov	ax, dx				; ax - column number
	mov	bx, mapBlock	
	mov     cl, mask IF_IMPORT		; do import
	call	GetMappedRowAndColNumber
	jnc	notMapped			; skip if not mapped   

	; add this column number to the column list

	push	ax				; save mappped column number
	mov	bx, notMappedBlk		; bx - handle
	tst	bx			; has column list block been created?
	jne	skip

	; create a data block that will hold not mapped column list

	mov	ax, MAX_NUM_FIELDS+1		; ax - size of block  
	mov     cx, ((mask HAF_ZERO_INIT or mask HAF_NO_ERR) shl 8) or 0
	call	MemAlloc
	mov	notMappedBlk, bx		; save the handle
skip:
	call	MemLock				; lock the data block
	mov	es, ax
	pop	di				; di - mapped column number

	mov	byte ptr es:[di], -1		; mark this field as mapped 
	call	MemUnlock			; unlock the data block

	; check the next field
notMapped:
	inc     dx
	cmp     dx, numFields			; are we done?
	jne     nextField			; if not, continue...
	mov	bx, notMappedBlk		; return handle of data block
exit:
	.leave
	ret
ImportCreateNotMappedColumnList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportGetActualColumnNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a column number returns true column number taking
		unmapped columns into consideration. 

CALLED BY:	(INTERNAL)

PASS:		ax - column number
		bx - handle of not-mapped column list data block

RETURN:		ax - true column number

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportGetActualColumnNumber	proc	near	uses	bx, cx, dx, es, di
	.enter

	clr	dx		; dx - actual column number
	tst	bx		; has column list block been created?
	je	exit		; exit if no not-mapped column list

	; lock this data block

	push	ax
	call	MemLock
	mov	es, ax
	pop	ax
	clr	di		; es:di - ptr to mapped column list
mainLoop:
	cmp	ax, di		; are we end of the list?
	je	found		; if so, exit the loop

	tst	es:[di]		
	je	next
	inc	dx		; if so, up the counter
next:
	inc	di
	jmp	mainLoop	; check the next entry
found:
	call	MemUnlock	; unlock this block
	mov	ax, dx		; ax - actual column number
exit:
	.leave
	ret
ImportGetActualColumnNumber	endp

endif

Import	ends
