COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1999 -- All Rights Reserved

PROJECT:	Mail
FILE:		stylesStack.asm

AUTHOR:		Gene Anderson

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/24/99		Initial revision

DESCRIPTION:
	A small stack for saving state about style information when
	parsing HTML/rich-text documents

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata segment
	styleStack hptr
udata ends

AsmCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StyleStackInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize the style stack

CALLED BY:	FilterMailStyles (C)

PASS:		none
RETURN:		none
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/6/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

STYLE_STACK_CHUNK	equ (size LMemBlockHeader)

STYLESTACKINIT	proc	far
		uses	ds
		.enter

		segmov	ds, udata, bx
EC <		tst	ds:styleStack			;>
EC <		ERROR_NZ -1				;>

		mov	ax, LMEM_TYPE_GENERAL		;ax <- LMemType
		clr	cx				;cx <- extra header
		call	MemAllocLMem
		mov	ds:styleStack, bx
		call	MemLock
		mov	ds, ax
		clr	cx				;cx <- size
		call	LMemAlloc
EC <		cmp	ax, STYLE_STACK_CHUNK		;>
EC <		ERROR_NE -1				;>
		call	MemUnlock

		.leave
		ret
STYLESTACKINIT	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StyleStackFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	free the style stack

CALLED BY:	FilterMailStyles (C)

PASS:		none
RETURN:		none
DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/6/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

STYLESTACKFREE	proc	far
		uses	ds
		.enter

		segmov	ds, udata, bx
		clr	bx				;clear old
		xchg	bx, ds:styleStack		;bx <- stack handle
EC <		tst	bx				;>
EC <		ERROR_Z -1				;>
		call	MemFree

		.leave
		ret
STYLESTACKFREE	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StyleStackLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	lock the style stack

CALLED BY:	UTILITY

PASS:		none
RETURN:		ds - seg addr of style stack
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/6/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

StyleStackLock	proc	near
		uses	ax, bx
		.enter

		segmov	ds, udata, bx
		mov	bx, ds:styleStack
		call	MemLock
		mov	ds, ax				;ds <- seg of stack

		.leave
		ret
StyleStackLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StyleStackUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	unlock the style stack

CALLED BY:	UTILITY

PASS:		none
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/6/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

StyleStackUnlock	proc	near
		uses	bx, ds
		.enter

		segmov	ds, udata, bx
		mov	bx, ds:styleStack
		call	MemUnlock

		.leave
		ret
StyleStackUnlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StyleStackPush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push data on the style stack

CALLED BY:	UTILITY

PASS:		al - StyleStackTag
		ah - size (0-6)
		bx, cx, dx - data as needed
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/6/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

StyleStackPush	proc	near
		uses	ax, ds, es, si, di
		.enter

		call	StyleStackLock
	;
	; insert space at the end start of the chunk
	;
		push	ax, bx, cx
		mov	cl, ah
		add	cl, (size StyleStackElement)
		clr	ch				;cx <- size to add
		mov	ax, STYLE_STACK_CHUNK		;*ds:ax <- chunk
		clr	bx				;bx <- offset
		call	LMemInsertAt
		pop	ax, bx, cx
	;
	; copy the data as needed
	;
		mov	si, ds:[STYLE_STACK_CHUNK]	;ds:si <- ptr to chunk
		mov	ds:[si], ax			;store tag, size
		segmov	es, ds
		lea	di, ds:[si].SSE_data		;es:di <- ptr to data
		tst	ah
		jz	done				;branch if done
		mov	al, bl
		stosb					;store bl
		dec	ah				;ah <- 1 less byte
		jz	done				;branch if done
		mov	al, bh
		stosb					;store bh
		dec	ah				;ah <- 1 less byte
		jz	done				;branch if done
		mov	al, cl
		stosb					;store cl
		dec	ah				;ah <- 1 less byte
		jz	done				;branch if done
		mov	al, ch
		stosb					;store ch
		dec	ah				;ah <- 1 less byte
		jz	done				;branch if done
		mov	al, dl
		stosb					;store dl
		dec	ah				;ah <- 1 less byte
		jz	done				;branch if done
		mov	al, dh
		stosb					;store dh
EC <		dec	ah				;>
EC <		ERROR_NZ -1				;>
done:
		call	StyleStackUnlock

		.leave
		ret
StyleStackPush	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StyleStackPop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pop data from the style stack

CALLED BY:	UTILITY

PASS:		al - StyleStackTag
RETURN:		bx, cx, dx - data as needed
		carry - set if tag not found
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/6/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

StyleStackPop	proc	near
		uses	ds, si, di
		.enter

		call	StyleStackLock
		mov	si, STYLE_STACK_CHUNK		;*ds:si <- chunk
		push	bx, cx
		ChunkSizeHandle ds, si, cx		;cx <- size of chunk
		LONG jcxz	notFoundPop		;branch if no data
		mov	si, ds:[si]			;ds:si <- chunk
		clr	di				;di <- offset
	;
	; find the first matching tag
	;
findLoop:
		cmp	ds:[si].SSE_type, al		;right tag?
		je	foundTag			;branch if found tag
		mov	bl, ds:[si].SSE_size
		add	bl, (size StyleStackElement)
		clr	bh				;bx <- element size
		add	si, bx				;ds:si <- ptr to next
		add	di, bx				;di <- next offset
		sub	cx, bx				;cx <- # bytes left
		jz	notFoundPop			;branch if none left
EC <		ERROR_C -1				;die if underflow >
		jmp	findLoop


foundTag:
		pop	bx, cx
	;
	; found the tag, get the data
	;
		mov	ah, ds:[si].SSE_size		;ah <- size
		push	ax
		add	si, (size StyleStackElement)	;ds:si <- data
		tst	ah
		jz	doneData			;branch if done
		lodsb
		mov	bl, al				;bl <- byte #1
		dec	ah				;ah <- one less byte
		jz	doneData			;branch if done
		lodsb
		mov	bh, al				;bh <- byte #2
		dec	ah				;ah <- one less byte
		jz	doneData			;branch if done
		lodsb
		mov	cl, al				;cl <- byte #3
		dec	ah				;ah <- one less byte
		jz	doneData			;branch if done
		lodsb
		mov	ch, al				;ch <- byte #4
		dec	ah				;ah <- one less byte
		jz	doneData			;branch if done
		lodsb
		mov	dl, al				;dl <- byte #5
		dec	ah				;ah <- one less byte
		jz	doneData			;branch if done
		lodsb
		mov	dh, al				;dh  <- byte #6
EC <		dec	ah				;>
EC <		ERROR_NZ -1				;>

doneData:
		pop	ax				;ah <- size
	;
	; delete the space
	;
		push	bx, cx, dx
		mov	cl, ah
		clr	ch				;cx <- # bytes data
		add	cx, (size StyleStackElement)	;cx <- # bytes total
		mov	ax, STYLE_STACK_CHUNK		;ax <- chunk
		mov	bx, di				;bx <- offset
		call	LMemDeleteAt
		pop	bx, cx, dx
		clc					;carry <- found

done:
		call	StyleStackUnlock

		.leave
		ret

notFoundPop:
		pop	bx, cx
		stc					;carry <- not found
		jmp	done
StyleStackPop	endp

AsmCode	ends
