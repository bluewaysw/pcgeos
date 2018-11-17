COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Heap
FILE:		heapC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the heap routines

	$Id: heapC.asm,v 1.1 97/04/05 01:13:51 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Common	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemAllocLMem

C DECLARATION:	

	extern MemHandle
    		MemAllocLMem(LMemType type, word headerSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
MEMALLOCLMEM	proc	far	; byteSize:word, flags:word
	C_GetTwoWordArgs	ax, cx,  bx, dx	;ax = type, cx = size

	call	MemAllocLMem
	mov_tr	ax, bx
	ret

MEMALLOCLMEM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemAlloc

C DECLARATION:	

	extern MemHandle
    		MemAlloc(word byteSize, word heapFlags, word heapAllocFlags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
MEMALLOC	proc	far	; byteSize:word, flags:word
	C_GetThreeWordArgs	ax, cx, bx,  dx	;ax = byteSize, cx = ty, bx=al

	mov	ch, bl			;ch = alloc flags
	call	MemAllocFar

retBXError	label	far
	mov_trash	ax, bx
	jnc	noError
	clr	ax
noError:
	ret

MEMALLOC	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemAllocSetOwner

C DECLARATION:	extern MemHandle
			 MemAllocSetOwner(GeodeHandle owner,
			word byteSize, word typeFlags, word allocFlags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
MEMALLOCSETOWNER	proc	far	owner:word, byteSize:word,
					typeFlags:word, allocFlags:word
	.enter

	mov	bx, owner
	mov	ax, byteSize
	mov	cl, {byte} typeFlags
	mov	ch, {byte} allocFlags
	call	MemAllocSetOwnerFar

;	DON'T CHANGE THE FOLLOWING TO A "jmp  retBXError", AS THIS ROUTINE
;	NEEDS TO POP THE ARGS ON THE STACK...

	mov_trash	ax, bx		
	jnc	noError
	clr	ax
noError:
	.leave
	ret
MEMALLOCSETOWNER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemReAlloc

C DECLARATION:	extern MemHandle
		    MemReAlloc(MemHandle mh, word byteSize,
						word allocFlags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Returns TRUE (non-zero) if error

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
MEMREALLOC	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx
	mov	ch, cl
	call	MemReAlloc
	jmp	retBXError

MEMREALLOC	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemGetInfo

C DECLARATION:	extern word
			 MemGetInfo(MemHandle mh,
							MemGetInfoType info);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
MEMGETINFO	proc	far	; mh:hptr, info:MemGetInfoType
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = handle, ax = type

	GOTO	MemGetInfo

MEMGETINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemModifyFlags

C DECLARATION:	extern void
			 MemModifyFlags(MemHandle mh,
					word bitsToSet, word bitsToClear);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
MEMMODIFYFLAGS	proc	far	; mh:hptr, bitsToSet:word, bitsToClear:word
	PopReturnAddr	cx, dx
	pop	bx			;bx = third arg
	mov	ah, bl			;ah = bits to clear
	pop	bx			;bx = second arg
	mov	al, bl			;bl = bits to clear
	pop	bx			;bx = first arg
	PushReturnAddr	cx, dx

	GOTO	MemModifyFlags

MEMMODIFYFLAGS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	HandleModifyOwner

C DECLARATION:	extern void
			 HandleModifyOwner(Handle mh, GeodeHandle owner);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
HANDLEMODIFYOWNER	proc	far	; mh:hptr, owner:hptr
	C_GetTwoWordArgs	bx, ax,   cx,dx

	GOTO	HandleModifyOwner

HANDLEMODIFYOWNER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemModifyOtherInfo

C DECLARATION:	extern void
			 MemModifyOtherInfo(MemHandle mh,
							word otherInfo);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
MEMMODIFYOTHERINFO	proc	far	; mh:hptr, otherInfo:word
	C_GetTwoWordArgs	bx, ax,   cx,dx

	GOTO	MemModifyOtherInfo

MEMMODIFYOTHERINFO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemInitRefCount

C DECLARATION:	extern void
			 MemInitRefCount(MemHandle mh, word count);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/92		Initial version

------------------------------------------------------------------------------@
MEMINITREFCOUNT	proc	far
	C_GetTwoWordArgs	bx, ax,  cx,dx
	GOTO	MemInitRefCount
MEMINITREFCOUNT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemIncRefCount

C DECLARATION:	extern void
			 MemIncRefCount(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/92		Initial version

------------------------------------------------------------------------------@
MEMINCREFCOUNT	proc	far
	C_GetOneWordArg	bx,  ax,cx
	GOTO	MemIncRefCount
MEMINCREFCOUNT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemDecRefCount

C DECLARATION:	extern void
			 MemDecRefCount(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/92		Initial version

------------------------------------------------------------------------------@
MEMDECREFCOUNT	proc	far
	C_GetOneWordArg	bx,  ax,cx
	GOTO	MemDecRefCount
MEMDECREFCOUNT	endp

C_Common	ends

;---

C_System	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MemPtrToHandle

C DECLARATION:	extern MemHandle
			 MemPtrToHandle(void *ptr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Returns NULL (0) if not found

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
MEMPTRTOHANDLE	proc	far
	C_GetOneDWordArg	cx, dx,   ax,bx		;cx = segment

	; check for a virtual segment

	cmp	cx, 0xf000
	jb	notVirtual
	mov_tr	ax, cx
	mov	cl, 4
	shl	ax, cl
	ret

notVirtual:
	call	MemSegmentToHandle
	mov_tr	ax, cx
	ret

MEMPTRTOHANDLE	endp

;=====================================================
;		EC Routines
;=====================================================

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckMemHandle

C DECLARATION:	extern void
			 ECCheckMemHandle(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKMEMHANDLE	proc	far
EC <	C_GetOneWordArg	bx,   ax,cx	;bx = handle			>
EC <	GOTO	ECCheckMemHandleFar					>
NEC <	ret	2							>

ECCHECKMEMHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckMemHandleNS

C DECLARATION:	extern void
			 ECCheckMemHandleNS(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKMEMHANDLENS	proc	far
EC <	C_GetOneWordArg	bx,   ax,cx	;bx = handle			>
EC <	GOTO	ECCheckMemHandleNSFar					>
NEC <	ret	2							>

ECCHECKMEMHANDLENS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckThreadHandle

C DECLARATION:	extern void
			 ECCheckThreadHandle(ThreadHandle th);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKTHREADHANDLE	proc	far
EC <	C_GetOneWordArg	bx,   ax,cx	;bx = handle			>
EC <	GOTO	ECCheckThreadHandleFar					>
NEC <	ret	2							>

ECCHECKTHREADHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckProcessHandle

C DECLARATION:	extern void
			 ECCheckProcessHandle(GeodeHandle gh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKPROCESSHANDLE	proc	far
EC <	C_GetOneWordArg	bx,   ax,cx	;bx = handle			>
EC <	GOTO	ECCheckProcessHandle					>
NEC <	ret	2							>

ECCHECKPROCESSHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckResourceHandle

C DECLARATION:	extern void
			 ECCheckResourceHandle(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKRESOURCEHANDLE	proc	far
EC <	C_GetOneWordArg	bx,   ax,cx	;bx = handle			>
EC <	GOTO	ECCheckResourceHandle					>
NEC <	ret	2							>

ECCHECKRESOURCEHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckGeodeHandle

C DECLARATION:	extern void
			 ECCheckGeodeHandle(GeodeHandle gh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKGEODEHANDLE	proc	far
EC <	C_GetOneWordArg	bx,   ax,cx	;bx = handle			>
EC <	GOTO	ECCheckGeodeHandle					>
NEC <	ret	2							>

ECCHECKGEODEHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckDriverHandle

C DECLARATION:	extern void
			 ECCheckDriverHandle(GeodeHandle gh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKDRIVERHANDLE	proc	far
EC <	C_GetOneWordArg	bx,   ax,cx	;bx = handle			>
EC <	GOTO	ECCheckDriverHandle					>
NEC <	ret	2							>

ECCHECKDRIVERHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckLibraryHandle

C DECLARATION:	extern void
			 ECCheckLibraryHandle(GeodeHandle gh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKLIBRARYHANDLE	proc	far
EC <	C_GetOneWordArg	bx,   ax,cx	;bx = handle			>
EC <	GOTO	ECCheckLibraryHandle					>
NEC <	ret	2							>

ECCHECKLIBRARYHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckGStateHandle

C DECLARATION:	extern void
			 ECCheckGStateHandle(GStateHandle gsh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKGSTATEHANDLE	proc	far
EC <	mov_tr	ax, di			;save passed di			>
EC <	C_GetOneWordArg	di,   bx,cx	;di = handle			>
EC <	call	ECCheckGStateHandle					>
EC <	mov_tr	di, ax			;restore passed di		>
EC <	ret								>
NEC <	ret	2							>

ECCHECKGSTATEHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckWindowHandle

C DECLARATION:	extern void
			 ECCheckWindowHandle(WindowHandle wh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKWINDOWHANDLE	proc	far
EC <	C_GetOneWordArg	bx,   ax,cx	;bx = handle			>
EC <	GOTO	ECCheckWindowHandle					>
NEC <	ret	2							>

ECCHECKWINDOWHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckQueueHandle

C DECLARATION:	extern void
			 ECCheckQueueHandle(QueueHandle qh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKQUEUEHANDLE	proc	far
EC <	C_GetOneWordArg	bx,   ax,cx	;bx = handle			>
EC <	GOTO	ECCheckQueueHandle					>
NEC <	ret	2							>

ECCHECKQUEUEHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckLMemHandle

C DECLARATION:	extern void
			 ECCheckLMemHandle(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKLMEMHANDLE	proc	far
EC <	C_GetOneWordArg	bx,   ax,cx	;bx = handle			>
EC <	GOTO	ECCheckLMemHandle					>
NEC <	ret	2							>

ECCHECKLMEMHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckLMemHandleNS

C DECLARATION:	extern void
			 ECCheckLMemHandleNS(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKLMEMHANDLENS	proc	far
EC <	C_GetOneWordArg	bx,   ax,cx	;bx = handle			>
EC <	GOTO	ECCheckLMemHandleNS					>
NEC <	ret	2							>

ECCHECKLMEMHANDLENS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECECLMemValidateHeap

C DECLARATION:	extern void
			 ECECLMemValidateHeap(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECLMEMVALIDATEHEAP	proc	far
EC <	C_GetOneWordArg	bx,   ax,cx	;bx = handle			>
EC <	push	ds							>
EC <	call	MemDerefDS						>
EC <	call	ECLMemValidateHeapFar					>
EC <	pop	ds							>
EC <	ret								>
NEC <	ret	2							>

ECLMEMVALIDATEHEAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECECLMemValidateHandle

C DECLARATION:	extern void _pascal ECLMemValidateHandle(optr o);
		extern void _pascal ECLMemValidateHandleHandles(MemHandle mh,
							ChunkHandle ch);
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECLMEMVALIDATEHANDLE	proc	far
EC <	C_GetTwoWordArgs	bx, ax,   dx,cx	;bx = handle, ax = chunk >
EC <	push	si, ds							>
EC <	call	MemDerefDS						>
EC <	mov_trash	si, ax						>
EC <	call	ECLMemValidateHandle					>
EC <	pop	si, ds							>
EC <	ret								>
NEC <	ret	4							>

ECLMEMVALIDATEHANDLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckLMemChunk

C DECLARATION:	extern void _pascal ECCheckLMemChunk(void *chunkPtr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKLMEMCHUNK	proc	far
EC <	C_GetTwoWordArgs	bx, ax,   dx,cx	;bx = handle, ax = chunk >
EC <	push	si, ds							>
EC <	mov_trash	si, ax						>
EC <	mov	ds, bx							>
EC <	call	ECCheckLMemChunk					>
EC <	pop	si, ds							>
EC <	ret								>
NEC <	ret	4							>

ECCHECKLMEMCHUNK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECECLMemExists

C DECLARATION:	extern void ECLMemExists(optr o);
		extern void ECLMemExistsHandles(MemHandle mh,
						ChunkHandle ch);
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECLMEMEXISTS	proc	far
EC <	C_GetTwoWordArgs	bx, ax,   dx,cx	;bx = handle, ax = chunk >
EC <	push	ds							>
EC <	call	MemDerefDS						>
EC <	call	ECLMemExists						>
EC <	pop	ds							>
EC <	ret								>
NEC <	ret	4							>

ECLMEMEXISTS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckChunkArray

C DECLARATION:	extern void ECCheckChunkArray(optr o);
		extern void ECCheckChunkArrayHandles(MemHandle mh, 
						     ChunkHandle ch);
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKCHUNKARRAY	proc	far
EC <	C_GetTwoWordArgs	bx, ax,   dx,cx	;bx = handle, ax = chunk >
EC <	push	si, ds							>
EC <	call	MemDerefDS						>
EC <	mov_trash	si, ax						>
EC <	call	ECCheckChunkArray					>
EC <	pop	si, ds							>
EC <	ret								>
NEC <	ret	4							>

ECCHECKCHUNKARRAY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckClass

C DECLARATION:	extern void
			 ECCheckClass(ClassStruct *class);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKCLASS	proc	far
EC <	C_GetTwoWordArgs	bx, ax,   dx,cx	;bx = handle, ax = chunk >
EC <	push	di, es							>
EC <	mov	es, bx							>
EC <	mov_trash	di, ax						>
EC <	call	ECCheckClass						>
EC <	pop	di, es							>
EC <	ret								>
NEC <	ret	4							>

ECCHECKCLASS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckObject

C DECLARATION:	extern void ECCheckObject(optr o);
		extern void ECCheckObjectHandles(MemHandle mh,
					         ChunkHandle chunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKOBJECT	proc	far
EC <	C_GetTwoWordArgs	bx, ax,   dx,cx	;bx = handle, ax = chunk >
EC <	push	si, ds							>
EC <	call	MemDerefDS						>
EC <	mov_trash	si, ax						>
EC <	call	ECCheckObject						>
EC <	pop	si, ds							>
EC <	ret								>
NEC <	ret	4							>

ECCHECKOBJECT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckLMemObject

C DECLARATION:	extern void ECCheckLMemObject(optr o);
		extern void ECCheckLMemObjectHandles(MemHandle mh,
						     ChunkHandle chunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKLMEMOBJECT	proc	far
EC <	C_GetTwoWordArgs	bx, ax,   dx,cx	;bx = handle, ax = chunk >
EC <	push	si, ds							>
EC <	call	MemDerefDS						>
EC <	mov_trash	si, ax						>
EC <	call	ECCheckLMemObject					>
EC <	pop	si, ds							>
EC <	ret								>
NEC <	ret	4							>

ECCHECKLMEMOBJECT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckOD

C DECLARATION:	extern void ECCheckOD(optr o);
		extern void ECCheckODHandles(MemHandle objHan,
					     ChunkHandle objCh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKOD	proc	far
EC <	C_GetTwoWordArgs	bx, ax,   dx,cx	;bx = handle, ax = chunk >
EC <	push	si							>
EC <	mov_trash	si, ax						>
EC <	call	ECCheckOD						>
EC <	pop	si							>
EC <	ret								>
NEC <	ret	4							>

ECCHECKOD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckLMemOD

C DECLARATION:	extern void
			 ECCheckLMemOD(MemHandle objHan,
							ChunkHandle objCh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKLMEMOD	proc	far
EC <	C_GetTwoWordArgs	bx, ax,   dx,cx	;bx = handle, ax = chunk >
EC <	push	si							>
EC <	mov_trash	si, ax						>
EC <	call	ECCheckLMemOD						>
EC <	pop	si							>
EC <	ret								>
NEC <	ret	4							>

ECCHECKLMEMOD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ECCheckBounds

C DECLARATION:	extern void
			 ECCheckBounds(void *address);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ECCHECKBOUNDS	proc	far
EC <	C_GetTwoWordArgs	bx, ax,   dx,cx	;bx = segment, ax = offset >
EC <	push	si, ds							>
EC <	mov	ds, bx							>
EC <	mov_trash	si, ax						>
EC <	call	ECCheckBounds						>
EC <	pop	si, ds							>
EC <	ret								>
NEC <	ret	4							>

ECCHECKBOUNDS	endp

C_System	ends

	 SetDefaultConvention
