                include stdapp.def
                include resource.def
		include system.def

;include malloc.asm

		UseLib mapheap.def

                SetGeosConvention               ; set calling convention

ASM_TEXT        segment public 'CODE'

                global _DispatchToClient:far
                global MULT3232TO64:far

		global _jsememextLockReadReally:far
		global _jsememextUnlockReadReally:far
		global _MappedPtrToJsememextHandle:far

COMMENT @----------------------------------------------------------------------

C FUNCTION:     DispatchToClient

C DECLARATION:  uword32 JSE_CFUNC FAR_CALL
                  DispatchToClient(uword16 ClientDataSegment,
                                   ClientFunction FClient,
                                   ...);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

                This is actually a wrapper around ProcCallFixedOrMovable
                that deals with the extra ClientDataSegment parameter.
		Parts of the code have been lifted from dlllib16.asm
		in the srccore component of ScriptEase.

		Stack layout:

    extern uword32 cdecl FAR_CALL DispatchToClient(uword16 DataSegment[bp+6],
	     ClientFunction FClient[bp+8],void _FAR_ *Parm1[bp+12],
	     			          void _FAR_ *Parm2[bp+16],
                                          void _FAR_ *Parm3[bp+20],
				          void _FAR_ *Parm4[bp+24]);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        mgroeb  8/00            Initial version

------------------------------------------------------------------------------@
_DispatchToClient       proc    far

	push  bp
	mov   bp, sp

	push  [bp+26]			; copy the parameters onto the stack
	push  [bp+24]
	push  [bp+22]
	push  [bp+20]
	push  [bp+18]
	push  [bp+16]
	push  [bp+14]
	push  [bp+12]

	mov   bx,[bp+10]		; get address of procedure...
	mov   ax,[bp+8]
	call  ProcCallFixedOrMovable	; ..and call it
	
	add   sp, 16
	
	pop   bp			; restore bp
	
	; can return; AX:DX already contains return value, if any
	ret

_DispatchToClient       endp

.386
MULT3232TO64   proc far  fp1:dword, fp2:dword, m64:fptr.sdword
	uses	eax, ebx, edx, es
        .enter
        mov     eax, fp1
        mov     ebx, fp2
	imul    ebx
        les     bx, m64
        mov     es:[bx], eax
	jo	overflow
        mov	{dword}es:[bx+4], 0
done:
        .leave
        ret
overflow:
	; signed result overflows 32-bit register.  Cue caller by setting
	; the high word to a non-zero value.
	mov	{dword}es:[bx+4], 1
	jmp	done
MULT3232TO64   endp

                SetDefaultConvention               ; set calling convention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_jsememextLockRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks a memext handle, handling both MemBlocks and fixed
		blocks.  The latter is indicated by the upper word of the
		handle being zero to (UTIL_WINDOW_MAX_NUM_WINDOWS - 1).

CALLED BY:	GLOBAL
PASS:		memHandle, type
RETURN:		dx:ax = pointer to chunk
DESTROYED:	nothing
SIDE EFFECTS:	none

C DECLARATION:	JSE_MEMEXT_R void *jsememextLockRead(
			jsememextHandle memHandle, enum jseMemExtType type)

PSEUDO CODE/STRATEGY:
		If handle < UTIL_WINDOW_MAX_NUM_WINDOWS
			return [winInfo][handle].UWI_addr:offset
		else
			MemLock(handle)
			return MemDeref(handle):offset

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/25/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_jsememextLockReadReally	proc	far	memHandle:optr, memType:word
	uses	bx
	ForceRef	memType
	.enter

	mov	bx, memHandle.handle		; bx = handle
	cmp	bx, UTIL_WINDOW_MAX_NUM_WINDOWS	; is chunk in mapped heap?
	jb	fixed				; branch if so
	call	MemLock				; ax = segment
	mov_tr	dx, ax
done:
	mov	ax, memHandle.offset		; dx:ax = chunk
	.leave
	ret
fixed:
	call	MapHeapWindowNumToPtr		; ax = segment
	mov_tr	dx, ax				; dx = segment
	jmp	done
	
_jsememextLockReadReally	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_jsememextUnlockReadReally
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlocks a memext handle, handling both MemBlocks and fixed
		blocks.

CALLED BY:	GLOBAL
PASS:		memHandle, data, type
RETURN:		nothing
DESTROYED:	dx, ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		If handle > UTIL_WINDOW_MAX_NUM_WINDOWS
			MemUnlock(handle)

C DECLARATION:	void jsememextUnlockRead(jsememextHandle memHandle,
			JSE_MEMEXT_R void * data,enum jseMemExtType type)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/25/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_jsememextUnlockReadReally	proc	far	memHandle:optr, data:fptr,
						memType:word
	uses	bx
	ForceRef	data
	ForceRef	memType
	.enter

	mov	bx, memHandle.handle		; bx = handle
	cmp	bx, UTIL_WINDOW_MAX_NUM_WINDOWS	; is chunk in mapped heap?
	jb	done				; branch if so
	call	MemUnlock			; unlock block
done:
	.leave
	ret
_jsememextUnlockReadReally	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_MappedPtrToJsememextHandleReally
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a pointer to a chunk in the mapped heap to a
		jsememextHandle.

CALLED BY:	Internal (jsememextAlloc, jsememextRealloc)
PASS:		pointer to chunk
RETURN:		dx:ax = handle
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Find the window number in which the chunk resides
		Return window:offset

C DECLARATION:	jsememextHandle MappedPtrToJsememextHandle(void *p);		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/25/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_MappedPtrToJsememextHandle	proc	far	memHandle:optr
	uses	bx
	.enter

	mov	ax, memHandle.handle		; ax = window segment
	call	MapHeapPtrToWindowNum		; bx = win #
EC <	ERROR_C -1							>
	mov_tr	dx, bx
	mov	ax, memHandle.offset		; dx:ax = handle
	.leave
	ret
_MappedPtrToJsememextHandle	endp

ASM_TEXT        ends
