                include stdapp.def
		include hugearr.def

                SetGeosConvention               ; set calling convention

ASM_TEXT        segment public 'CODE'

        if ERROR_CHECK
        global F_CHKSTK@:far
; Called with AX containing the number of bytes to be allocated on the stack.
; Must return with the stackpointer lowered by AX bytes.
F_CHKSTK@       proc far
        pop     cx                      ; save return address
        pop     dx
        sub     sp,ax                   ; allocated space on stack
        push    dx                      ; restore return address
        push    cx
        call    ECCHECKSTACK            ; still enough room on stack?
        ret                             ; return to calling routine
F_CHKSTK@       endp
        endif

global CHUNKARRAYELEMENTTOPTRFIXED:far
global CHUNKARRAYGETCOUNTFIXED:far
global HUGEARRAYLOCKFIXED:far
global HUGEARRAYUNLOCKFIXED:far
global HUGEARRAYDIRTYFIXED:far
global HUGEARRAYNEXTFIXED:far
global HUGEARRAYPREVFIXED:far

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayElementToPtr

C DECLARATION:	extern void _far *
			_far _pascal ChunkArrayElementToPtr(MemHandle mh,
					ChunkHandle chunk, word elementNumber,
					word _far *elementSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
CHUNKARRAYELEMENTTOPTRFIXED	proc	far	mhan:hptr, chan:word, ele:word,
					eleSize:fptr
			uses	si, di, ds
	.enter

	mov	bx, mhan
	call	MemDerefDS
	mov	si, chan
	mov	ax, ele
	call	ChunkArrayElementToPtr
	mov	dx, ds
	mov_trash	ax, di
	tst	eleSize.segment
	jz	10$
	lds	si, eleSize
	mov	ds:[si], cx
10$:

	.leave
	ret

CHUNKARRAYELEMENTTOPTRFIXED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayGetCount

C DECLARATION:	extern word
			_far _pascal ChunkArrayGetCount(MemHandle mh,
							ChunkHandle chunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
CHUNKARRAYGETCOUNTFIXED	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = han, ax = chunk

	push	ds
	call	MemDerefDS
	xchg	si, ax
	call	ChunkArrayGetCount
	mov_trash	si, ax
	mov_trash	ax, cx
	pop	ds

	ret

CHUNKARRAYGETCOUNTFIXED	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayLock

C DECLARATION:	extern dword 
			_far _pascal HugeArrayLock(VMFileHandle vmFile, 
						   VMBlockHandle vmBlock,
						   dword elemNum,
						   void _far *_far *elemPtr,
						   word *size);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYLOCKFIXED	proc	far  vmFile:hptr, vmBlock:hptr, elemNum:dword, 
			     elemPtr:fptr.far, elemSize:fptr.word
	uses	ds, si, di
	.enter
	mov	bx, vmFile		; load up routine parameters
	mov	di, vmBlock
	mov	ax, elemNum.low
	mov	dx, elemNum.high
	call	HugeArrayLock		; dx <- size of element
	push	dx			; Save size of element
	push	cx			; save # elements before this one
		
	mov	cx, ds			; save returned pointer
	mov	bx, si
	lds	si, elemPtr
	mov	ds:[si].offset, bx
	mov	ds:[si].segment, cx

	pop	dx			; dx <- # elements before this one
					; ax <- # elements after this one
	pop	cx			; cx <- element size
	lds	si, elemSize		; ds:si <- ptr to word
	mov	{word} ds:[si], cx	; Save element size
	.leave
	ret
HUGEARRAYLOCKFIXED	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayUnlock

C DECLARATION:	extern void 
			_far _pascal HugeArrayUnlock(const void _far *elemPtr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYUNLOCKFIXED	proc	far  
	C_GetOneDWordArg	dx,ax, bx,cx
	push	ds
	mov	ds, dx
	call	HugeArrayUnlock
	pop	ds
	ret
HUGEARRAYUNLOCKFIXED	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayDirty

C DECLARATION:	extern void 
			_far _pascal HugeArrayDirty(const void _far *elemPtr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYDIRTYFIXED	proc	far  
	C_GetOneDWordArg	dx,ax, bx,cx
	push	ds
	mov	ds, dx
	call	HugeArrayDirty
	pop	ds
	ret
HUGEARRAYDIRTYFIXED endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayNext

C DECLARATION:	extern word 
			_far _pascal HugeArrayNext(void _far *_far *elemPtr,
						   word *size);
						    
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYNEXTFIXED	proc	far	elemPtr:fptr.fptr, elemSize:fptr.word
	uses	ds, si
	.enter
	lds	bx, elemPtr			; ds:bx -> pointer
	mov	si, ds:[bx].offset
	mov	ds, ds:[bx].segment
	call	HugeArrayNext			; return value in dx.ax
	push	dx				; save element size

	mov	cx, si
	mov	dx, ds
	lds	si, elemPtr
	mov	ds:[si].offset, cx		; store new pointer
	mov	ds:[si].segment, dx

	pop	dx				; dx <- element size
	lds	si, elemSize			; ds:si <- ptr to word
	mov	{word} ds:[si], dx		; Save element size
	.leave
	ret
HUGEARRAYNEXTFIXED	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	HugeArrayPrev

C DECLARATION:	extern word 
			_far _pascal HugeArrayPrev(void _far *_far *elemPtr1,
						   void _far *_far *elemPtr2,
						   word *size);
						    
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HUGEARRAYPREVFIXED	proc	far	elemPtr1:fptr.fptr, elemPtr2:fptr.fptr,
				elemSize:fptr.word
	uses	ds, si, di
	.enter
	lds	bx, elemPtr1			; ds:bx -> pointer
	mov	si, ds:[bx].offset
	mov	ds, ds:[bx].segment
	call	HugeArrayPrev			; return value in dx.ax
	push	dx				; save size

	mov	cx, si
	mov	dx, ds
	mov	bx, di
	lds	si, elemPtr1
	mov	ds:[si].offset, cx		; store new pointer
	mov	ds:[si].segment, dx
	lds	si, elemPtr2
	mov	ds:[si].offset, bx		; store new pointer
	mov	ds:[si].segment, dx

	pop	dx				; dx <- element size
	lds	si, elemSize			; ds:si <- ptr to word
	mov	{word} ds:[si], dx		; Save element size
	.leave
	ret
HUGEARRAYPREVFIXED	endp

ASM_TEXT        ends

