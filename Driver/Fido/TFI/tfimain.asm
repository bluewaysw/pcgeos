COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido Input driver
FILE:		tfimain.asm

AUTHOR:		Paul L. DuBois, Nov 30, 1994

ROUTINES:
	Name			Description
	----			-----------
    EXT TFIGetSymbols		Return a buffer with symbol info in it

    EXT TFIOpen			Open a file

    EXT TFIClose		Close a file

    EXT TFIGetPage		Return a buffer with page in it

    INT TFI_ExtractRegion	Extract a region from a buffer, properly
				null-terminating it.

    INT TFI_NextLine		Move to beginning of next line, or EOB

    INT TFI_NextPage		Move to after next <pag> marker, or end of
				buffer

    INT TFI_CmpToEOL		Are we looking at <str>\n?

    INT TFI_ReadFile		Read file into a buffer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/30/94   	Initial revision


DESCRIPTION:
	
	$Revision:   1.2  $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TFIGetSymbols
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a buffer with symbol info in it

CALLED BY:	EXTERNAL, TFIStrategy (DR_FIDOI_GET_SYMBOLS)
PASS:		cx	- token returned by DR_FIDOI_OPEN
RETURN:		bx	- buffer
DESTROYED:	(allowed to destroy ax, di)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	12/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TFIGetSymbols	proc	far
	;uses	cx,dx,si,bp
	.enter
		stc
	.leave
	ret
TFIGetSymbols	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TFIOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a file

CALLED BY:	EXTERNAL, TFIStrategy (DR_FIDOI_OPEN)
PASS:		ds:si	- asciiz string
RETURN:		ax	- token to pass to other routines.
DESTROYED:	nothing (allowed to destroy bx, di)
SIDE EFFECTS:
	Opens a file

PSEUDO CODE/STRATEGY:
	Return a file handle

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TFIOpen	proc	far
	uses	dx
	.enter
		mov	dx, si
		mov	ax, FILE_DENY_W or FILE_ACCESS_R
		call	FileOpen
		Destroy	bx, di
	.leave
	ret
TFIOpen	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TFIClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a file

CALLED BY:	EXTERNAL, TFIStrategy (DR_FIDOI_CLOSE)
PASS:		cx	- token received from TFIOpen
RETURN:		carry	- set on error
DESTROYED:	ax, bx (allowed to destroy di)
SIDE EFFECTS:	
	Closes the file handle

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TFIClose	proc	far
	.enter
		mov	bx, cx
		clr	ax
		call	FileClose
		Destroy	di
	.leave
	ret
TFIClose	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TFIGetPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a buffer with page in it

CALLED BY:	EXTERNAL, TFIStrategy (DR_FIDOI_GET_PAGE)
PASS:		cx	- token received from TFIOpen
		ds:si	- page name
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
TFIGetPage	proc	far
	uses	cx, ds, es
	.enter
		mov	ax, cx
		call	TFI_ReadFile
		jc	done
		
	; search for <pag> markers, then compare page name
	; to ds:si.  When/if found, search for </pag> marker.
	;
		call	MemDerefES
		clr	di		;es:di <- text buffer
					;ds:si <- page name
findPage:
		call	TFI_NextPage
		jc	errorFree
		call	TFI_CmpToEOL	;found the right page?
		jc	findPage

	; Found the beginning ... save position at the beginning of
	; the next line, then find the end of the page.
	;
		call	TFI_NextLine
		push	di		;save position

		call	TFI_NextPage
		jc	noBackup	; hit EOB
		sub	di, 5		;size of "<pag>"
		add	cx, 5
noBackup:
		pop	ax		;ax <- beginning of page
		mov	cx, di
		sub	cx, ax		;cx <- # chars in page

		call	TFI_ExtractRegion
		call	MemUnlock
		clc
done:
	.leave
	ret
errorFree:
		call	MemFree
		stc
		jmp	done
TFIGetPage	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TFI_ExtractRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract a region from a buffer, properly null-terminating it.

CALLED BY:	INTERNAL, TFIGetPage
PASS:		ax	- offset into buffer of region start
		bx	- MemHandle of buffer
		cx	- # characters to take
RETURN:		
DESTROYED:	ax, cx
SIDE EFFECTS:	bx resized to cx+1 bytes (+1 for the null)

PSEUDO CODE/STRATEGY:
	Slow... doesn't utilize movsw.
	zeros out the end of the block

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TFI_ExtractRegion	proc	near
	uses	ds,es,si,di
	.enter
		push	cx		;save size...
		jcxz	resize

		mov	si, ax
		call	MemLock
		mov	es, ax
		clr	di
		mov	ds, ax

	; Ensure that the movsw copies from a word boundary
	;
		test	si, 1
		jz	wordAligned
		movsb
		dec	cx
		
wordAligned:
		shr	cx
		rep	movsw
		jnc	resize
extraByte::
		movsb

	; now resize the block and add a trailing null
	; add after resizing so we don't accidentally trash a byte
	; of random memory in the case that the block isn't getting
	; smaller
resize:
		pop	ax
		inc	ax		; add one more for the null
		mov	ch, mask HAF_NO_ERR
		call	MemReAlloc
		mov	es, ax
		mov	{byte}es:[di], 0
		
		call	MemUnlock
	.leave
	ret
TFI_ExtractRegion	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TFI_NextLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to beginning of next line, or EOB

CALLED BY:	INTERNAL
PASS:		es:di	- buffer
		cx	- # chars in es:di
RETURN:		di, cx	- updated
		carry	- set if hit end of buffer
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Assume CRLF termination for now...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TFI_NextLine	proc	near
	uses	ax
	.enter
		mov	al, C_CR
		repne	scasb		;now pointing at '\n'
		jne	hitEnd
EC <		cmp	{byte} es:[di], C_LF				>
EC <		ERROR_NZ	NOT_CRLF_TERMINATED		>
		inc	di		;point at next char
		dec	cx
		clc
done:
	.leave
	ret
hitEnd:
		stc
		jmp	done
		
TFI_NextLine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TFI_NextPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to after next <pag> marker, or end of buffer

CALLED BY:	INTERNAL, TFIGetPage
PASS:		es:di	- text buffer
		cx	- size of buffer

RETURN:		carry clear
		es:di	- pointing after <pag>
		cx	- updated
	failure:
		carry set
		es:di	- 1 past end of buffer

DESTROYED:
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Assumes the '<' is preceded by a newline.
	Therefore, first line can't be a <> tag.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TFI_NextPage	proc	near
	uses	ax
	.enter		
		tst	cx
		jz	notFound
lookAgain:
		mov	al, '<'
		repne	scasb
		jne	notFound

		cmp	{byte} es:[di-2], C_LF	;is it at beginning of line?
		jne	lookAgain

		cmp	cx, 4		; 4 is length of "pag>"
		jb	notFound

		mov	ax, ('a' shl 8) or 'p'	;little-endian... gr
		scasw
		lahf
		sub	cx, 2
		sahf
		jne	lookAgain
		mov	ax, ('>' shl 8) or 'g'
		scasw
		lahf
		sub	cx, 2
		sahf
		jne	lookAgain

		clc
done:
	.leave
	ret

notFound:
		add	di, cx		; point es:di to end of buffer
		clr	cx		; and update size
		stc
		jmp	done
TFI_NextPage	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TFI_CmpToEOL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Are we looking at <str>\n?

CALLED BY:	INTERNAL, TFIGetPage

PASS:		es:di	- text buffer
		ds:si	- ASCIIZ string to look for
		cx	- size of buffer

RETURN:		carry	- set if they don't match

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Assumes that there are no nulls in the text buffer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TFI_CmpToEOL	proc	near
	uses	cx, si, di
	.enter
		mov	cx, -1
		repe	cmpsb
EC <		ERROR_E	-1						>

	; success if we just compared end of string to end of line
		tst	< {byte} ds:[si-1] >	;null?
		jnz	noMatch
		cmp	{byte} es:[di-1], C_CR	;end of line?
		jne	noMatch
match::
		clc
done:
	.leave
	ret

noMatch:
		stc
		jmp	done

TFI_CmpToEOL	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TFI_ReadFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read file into a buffer

CALLED BY:	INTERNAL, TFIGetPage
PASS:		ax	- file handle
RETURN:		bx	- locked buffer with file in it
		cx	- size of buffer
		carry	- set on error (& bx,cx garbage)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TFI_ReadFile	proc	near
file	local	hptr	push	ax
	uses dx, ds
	.enter
		mov_tr	bx, ax
		call	FileSize
		tst	dx		; > 64K?
		jnz	errorDone
		
		mov	dx, ax		; save size
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc	; bx <- handle, ax <- addr
		
		push	bx		; save block
		mov	cx, dx		; cx <- # bytes to read
		mov	ds, ax
		clr	ax, dx		; ds:dx <- buffer
		mov	bx, ss:[file]
		call	FileRead
		pop	bx
		jc	errorFreeDone

done:
		mov	ax, ss:[file]
	.leave
	ret
errorFreeDone:
		call	MemFree
errorDone:
		stc
		jmp	done
TFI_ReadFile	endp

MainCode	ends
