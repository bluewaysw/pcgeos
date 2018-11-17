COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		mainThread.asm

AUTHOR:		jimmy lefkowitz

ROUTINES:

	Name				Description
	----				-----------
	MathThreadListCompact		fill in hole in list with last element
	MathThreadListAppend		add an element
	MathThreadListFindThread	find an element
	MathThreadDelete		delete an element
	MathThreadListUpdateDepth	change dpeth value in an entry

	FloatHardwareEnter		check for context switches and overflow
	FloatHardwareLeave		check for underflow
	FloatGetStackDepth		returns the stack depth
	FloatGetSoftwareStackHandle	returns current software stack handle
	FloatHardwareInit		init a thread's float stack
	FloatHardwareExit		free a thread's float stack
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/27/92		Initial version.

DESCRIPTION:
	Code involving thread stuff

	$Id: mainThread.asm,v 1.1 97/04/05 01:22:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


MATH_THREAD_LIST_INIT_SIZE = 5

MathFixedCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatHardwareEnter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do a context switch on the coprocessor if neccesary
		also swap stuff out to the software stack if needed

CALLED BY:	GLOBAL

PASS:		ax = expected changed in stack depth
		     this argument tells up how much room on the hardware
		     stack we need to do the computations, it it turns out
		     that there is not enough space then we have to move 
		     some numbers down to the software stack extension so
		     there is sufficient room on the hardware stack to work
	
RETURN:		carry set if any problems encountered

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatHardwareEnter	proc	far
myThread	local	hptr
	
	uses	ax, bx, cx, dx, di, es
	.enter
	mov_tr	di, ax			; save away ax
NOFXIP< segmov	es, dgroup, ax						>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES			;es = dgroup		>
	mov	bx, es:[idataSem]
	call	ThreadPSem		; grab exclusive right to the chip
	cmp	ax, SE_NO_ERROR
LONG	jnz	error
	clr	bx			; get current thread handle
	mov	ax, TGIT_THREAD_HANDLE
	call	ThreadGetInfo			; ax <- thread handle
	mov	myThread, ax			; save it away for later

	; if we last thread (whose value is still in currentThread) is
	; not the actual current thread we must context switch the chip
	cmp	ax, es:[currentThread]
	jnz	contextSwitch

	; the following section of code checks for hardware stack overflows
	; and underflows and swaps to and from the software stack as needed
	; if the software stack over/underflows then we return the
	; carry set as that is a true error
	
	clr	cx		; do not yet have all the info we need
softwareSwap:

	; if di is zero the stack depth is not changing so don't worry
	mov	dx, es:[stackDepth]
	add	dx, di
	mov	es:[stackDepth], dx
	tst	di
LONG	jz	doneNoError
	jg	doOverFlow
	tst	es:[stackDepth]
LONG	jz	errorVSem
	jmp	doneNoError
doOverFlow:
	
	cmp	dx, es:[hardwareStackDepth]
	clc
LONG	jle	doneNoError

	; there is a special case, that is if the depth was less than
	; harwareStackSize to begin with, then we really need to skip the
	; previously empty spaces
	clr	cx
	mov	ax, es:[stackDepth]
	sub	ax, di
	sub	ax, es:[hardwareStackDepth]
	jge	contOverflow
	mov	cx, ax
contOverflow:
	mov	ax, MR_OVERFLOW
	mov	bx, es:[hardwareLibrary]
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable		; do any swaps necessary
	jc	errorVSem
	jmp	doneNoError
contextSwitch:
	; a context switch consists of the following:
	; first save away the entire current state of the chip for the
	; last guy who was using it (if there was a last guy)
	; then if its not our first time, get our old state back and
	; load it into the chip

	; I save si here so it only gets push and popped when there is
	; a context switch
	push	si		
	mov_tr	dx, ax		; dx <- the current thread
	mov	cx, -1		; don't update the depth

	; first we get and store away our data
	call	MathThreadListFindThread
		;CX = fp software stack Handle
		;DX = fp stack depth
		;SI = fp hardware stack handle	
	push	cx, dx
	push	si	
	; first get the old clients hardware stack handle
	; and save the hardware state
	mov	dx, es:[currentThread]
	mov	cx, es:[stackDepth]		; new depth to update
;	call	MathThreadListUpdateDepth
;	jc	cont				; first one so no other thread
	call	MathThreadListFindThread
	jc	cont				; first one so no other thread
	mov	es:[softwareStackHandle], cx
	mov	es:[stackDepth], dx
	mov	ax, MR_SAVE_STATE
	mov	bx, es:[hardwareLibrary]
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
cont:	
	; now get the state of this new client
	pop	si			; used in MR_RESTORE_STATE
	mov	ax, MR_RESTORE_STATE
	mov	bx, es:[hardwareLibrary]
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
	
	mov	bx, myThread	
	mov	es:[currentThread], bx
	pop	cx, dx
	mov	es:[stackDepth], dx
	mov	es:[softwareStackHandle], cx
	pop	si
	jmp	softwareSwap
doneNoError:
	clc
done:
	.leave
	ret
errorVSem:
	mov	bx, es:[idataSem]
	call	ThreadVSem
error:
	stc
	jmp	done
FloatHardwareEnter	endp
	public	FloatHardwareEnter


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatHardwareLeave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update the stack depth, bring any stuff over from
		software to hardware if there is room
		and VSem the math library

CALLED BY:	GLOBAL

PASS:		ax = change in stack depth
			this argument is used so update the stack depth 
			to its correct value after an operation.  Often it
			will be a negative number to indicate that the stack
			has shrunk in size, in which case we need to see if 
			spots in the hardware stack have been opened up, if so
			and we have any values in the software stack extension
			we move them up to fill the blank spaces in the
			harware stack so that it always has as many values as
			possible in the hardware stack.  If there are any
			spaces left open in the hardware stack after this
			routine is called it means that the software stack
			must be empty...

RETURN:		carry - clear (no error)

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatHardwareLeave	proc	far
	uses	es, bx, cx
	.enter
NOFXIP<	segmov	es, dgroup, bx						>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES			;ds = dgroup		>
	mov	cx, es:[stackDepth]
	add	es:[stackDepth], ax
	clr	bx
	tst	ax
	clc
	jge	doneNoError			; if we shrank, do underflow
	cmp	cx, es:[hardwareStackDepth]
	clc
	jle	doneNoError
	push	di, ax
	mov	di, ax			; gets passed to MR_UNDERFLOW
	mov	cx, es:[hardwareStackDepth]
	sub	cx, es:[stackDepth]	
	jg	cont
	clr	cx
cont:
	mov	bx, es:[hardwareLibrary]
	mov	ax, MR_UNDERFLOW
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
	pop	di, ax
doneNoError:
	clc
	mov	bx, es:[idataSem]
	call	ThreadVSem	
	.leave
	ret

FloatHardwareLeave	endp
	public	FloatHardwareLeave


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatGetStackDepth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the stack depth

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		ax = stack depth

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatGetStackDepth	proc	far
	uses	es
	.enter
NOFXIP<	segmov	es, dgroup, ax						>
FXIP <	mov_tr	ax, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES			;es = dgroup		>
FXIP <	mov_tr	bx, ax				;restore bx		>
	mov	ax, es:[stackDepth]
	.leave
	ret
FloatGetStackDepth	endp
	public	FloatGetStackDepth

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatSetStackDepth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the stack depth

CALLED BY:	GLOBAL

PASS:		ax = stack depth

RETURN:		nothing

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatSetStackDepth	proc	far
	uses	es, bx
	.enter
NOFXIP<	segmov	es, dgroup, bx						>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES			;ds = dgroup		>
	mov	es:[stackDepth], ax
	.leave
	ret
FloatSetStackDepth	endp
	public	FloatSetStackDepth

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatGetSoftwareStackHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	gets the handle of the software stack

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		bx = software stack handle of current active client

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatGetSoftwareStackHandle	proc	far
	uses	es
	.enter
NOFXIP<	segmov	es, dgroup, bx						>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES			;es = dgroup		>
	mov	bx, es:[softwareStackHandle]
EC <	call	ECCheckMemHandle				>
	.leave
	ret
FloatGetSoftwareStackHandle	endp
	public	FloatGetSoftwareStackHandle

MathFixedCode	ends

	
ThreadListCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatHardwareInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	allocate state block and add client to thread list

CALLED BY:	GLOBAL

PASS:		bx = handle of software stack block

RETURN:		carry set on error

DESTROYED:	ax, bx, cx, dx

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/29/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatHardwareInit	proc	far
	uses	ds,si,di,bp,es
	.enter	
NOFXIP<	segmov	es, dgroup, ax						>
FXIP <	mov_tr	ax, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES			;es = dgroup		>
FXIP <	mov_tr	bx, ax				;restore bx		>
	mov	cx, bx			; save the handle for later

	; do the semaphore first!
	mov	bx, es:[idataSem]
	call	ThreadPSem	
	cmp	ax, SE_NO_ERROR
LONG	jnz	error

	; now that we have done the semaphore we can use the
	; libraries global variables
	mov	es:[softwareStackHandle], cx	; save away the passed handle
	mov	dx, es:[currentThread]
	mov	cx, es:[stackDepth]		; new depth to update
;	call	MathThreadListUpdateDepth
;	jc	cont				; first one so no other thread
	call	MathThreadListFindThread
	jc	cont
	mov	ax, MR_SAVE_STATE
	mov	bx, es:[hardwareLibrary]
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
cont:
	; now allocate a new block for saving state for the new client
	mov	ax, MR_GET_ENV_SIZE
	mov	bx, es:[hardwareLibrary]
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable		; cx <- size in bytes
	mov	ax, cx
	; must be made sharable as different geodes will actually do the
	; saving of state when this block needs to be written out
	mov	cx,(HAF_STANDARD shl 8) or mask HF_SWAPABLE or mask HF_SHARABLE
	call	MemAlloc
	jc	vsem
	; now get all the information we need and stuff it into the
	; thread list so that we can retrieve it on future context
	; switches to this thread
	mov	si, bx
	clr	bx				; 0 = current thread
	mov	ax, TGIT_THREAD_HANDLE
	call	ThreadGetInfo			; ax <- thread handle
	mov	bp, ax	
	mov	es:[currentThread], ax
	clr	es:[stackDepth]
	clr	dx			; initial depth = 0
	mov	cx, es:[softwareStackHandle]
	call	MathThreadListAppend
	jc	vsem
	; now init the hardware chip and save the state for the new client
	; we can do this after we append because the handle has been 
	; saved away in the list and now we just write to that handles
	; block	
	mov	ax, MR_DO_HARDWARE_INIT	
	mov	bx, es:[hardwareLibrary]
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
vsem:
	mov	bx, es:[idataSem]
	call	ThreadVSem		; flags perserved
	jc	done			; MemAlloc error propagated
	cmp	ax, SE_NO_ERROR
	jne	error
	clc
done:		
	.leave
	ret
error:
	stc
	jmp	done
FloatHardwareInit	endp
	public	FloatHardwareInit

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatHardwareExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	free up memory and thread list entry for stack state

CALLED BY:	hardware exit routine

PASS:		nothing

RETURN:		carry set if the thread list is now empty

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/29/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatHardwareExit	proc	far
	uses	ds, es, si, di, ax, bx, cx, dx
	.enter
NOFXIP<	segmov	es, dgroup, ax						>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES			;es = dgroup		>
	mov	bx, es:[idataSem]
	call	ThreadPSem	
	mov	ax, TGIT_THREAD_HANDLE
	clr	bx
	call	ThreadGetInfo
	mov_tr	dx, ax	
	call	MathThreadListDelete	
	mov	bx, es:[idataSem]
	call	ThreadVSem	
	.leave
	ret
FloatHardwareExit	endp
	public	FloatHardwareExit

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MathThreadListDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Delete an entry from the Math Thread List

PASS:		*ds:si	= MathClass instance data.
		ds:di	= *ds:si.
		es	= Segment of MathClass.
		ax	= Method.
		dx 	= thread handle

RETURN:		carry set if nothing removed else carry clear
		zero flag = 1 if the thread list handle was freed

DESTROYED:	bx, ds, di, si, cx

REGISTER/STACK USAGE:
		Standard dynamic register file.

PSEUDOCODE/STRATEGY:
		search through to find this thread's element and delete
		it, moving the last element into its position

KNOWN BUGS/SIDEFFECTS/CAVEATS/IDEAS:	???

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/25/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MathThreadListDelete	proc	far
	uses	ax

	.enter

	; Now see if the list handle has been allocated;
	; if so, continue, else there has been an error
	;
	push	es
NOFXIP<	segmov	es, dgroup, bx						>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES			;es = dgroup		>
	mov	bx, es:[threadListHan]
	pop	es
EC <	call	ECCheckMemHandle					>
	call	MemLock			; lock the ThreadList block

	; Get the number of elements in the list and make sure it's
	; non-zero
	;
	mov	ds, ax		; ds <- pointer to ThreadList header
	tst	ds:[MTLH_numberOfElements]
	jz	errorNotFound

	; ds:di <- pointer to last element, just beyond the header
	;
	; we must look from the back to the front so that
	; if a single thread has done multiple FloatInits
	; it will have several entries that got put in front
	; to back.  SO we always want to get the latest one
	; put in by any givien thread, thus we search from back to front

	mov	ax, size MathThreadList
	mov	cx, ds:[MTLH_numberOfElements]
EC <	cmp	cx, 0xff					>
EC <	ERROR_A	TOO_MANY_CLIENT_THREADS				>
	dec	cx
	mul	cl
	add	ax, size MathThreadListHeader
	mov_tr	di, ax
	inc	cx
searchLoop:

	; Go through the list, looking for the thread entry passed in.
	; There can be only one entry per thread.
	;
	cmp	dx, ds:[di].MTL_threadHandle
	jz	foundElement		; continue if we find the match
	sub	di, size MathThreadList
	loop	searchLoop

	; If we get through the list and the element is not found,
	; set the carry flag and return
	;
	jmp	errorNotFound
foundElement:

	; If we found the element, move the last element into the deleted
	; element's place and clear the carry
	; we also free up the hardware stack handle we were using
	push	bx
	mov	bx, ds:[di].MTL_hardwareStackHandle
	call	MemFree
	pop	bx	
	call	MathThreadListCompact
	clc

	; Unlock the ThreadList block
	;
	tst	bx
	jz	done
doneUnlock:
	call	MemUnlock
done:
	.leave
	ret
errorNotFound:

	; Do some error notification
	;
	stc
	jmp	doneUnlock
MathThreadListDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MathThreadListCompact
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move last item in list into vacated spot

CALLED BY:	MathThreadListCompact

PASS:		di = offset address of element that is being deleted
		ds = thread list block
		bx = thread list handle

RETURN:		Void.
		if the handle is freed, bx is set to zero

DESTROYED:	si, ax, cx

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/25/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MathThreadListCompact	proc	near
	.enter

	; Since we are deleting an item, decrement the item count
	;
	dec	ds:[MTLH_numberOfElements]

	; If this is the only element then we are done
	;
	mov	ax, ds:[MTLH_numberOfElements]
	tst	ax
	jnz	cont
	; if it was the last element, then free up the
	; list handle
	call	MemFree	
	push	es
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES			;es = dgroup		>
	clr	bx			; return bx = 0
	mov	es:[threadListHan], bx
	pop	es
	jmp	done
cont:
	; Otherwise calculate the address of the last element
	;
	push	es, bx
	mov	bl, size MathThreadList
	mul	bl
	add	ax, size MathThreadListHeader
	mov	si, ax		; ds:si <- address of last element 

	; Move the last element into new empty slot
	;	
	segmov	es, ds		; es:di = address of element to delete
	mov	cx, size MathThreadList	; cx = # bytes to copy
	rep	movsb				; copy last element over
						; element to delete
	pop	es, bx
done:
	.leave
	ret
MathThreadListCompact	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MathThreadListAppend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a thread to the Math Thread List.


PASS:		
		BP = thread handle
		CX = fp software stack handle
		DX = fp stack depth
		SI = fp hardware stack handle
		
RETURN:		carry set on error

DESTROYED:	bx, ax

PSEUDOCODE/STRATEGY:	
		since there will usually not be a lot of threads at once,
		I initially allocate space for MATH_THREAD_LIST_INIT_SIZE
		(which is about 5) structures and then just realloc more
		space if thats not enough, the semaphore is used so that
		we don't ever get two handles allocated

KNOWN BUGS/SIDEFFECTS/IDES:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		----------
	jimmy	6/25/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MathThreadListAppend	proc	far
	uses	es
	.enter

	push	cx, dx			; save input for the end
NOFXIP<	segmov	es, dgroup, bx			; es = dgroup		>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES			;es = dgroup		>
	mov	bx, es:[threadListHan]		; get the list handle
	tst	bx				; if zero, allocate some memory
	jnz	cont				; else cont
	mov	al, size MathThreadList	; set size of element
	mov	cl, MATH_THREAD_LIST_INIT_SIZE ; multiply by initial amount
	mul	cl
	add	ax, size MathThreadListHeader  ; add header size
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	mov	bx, handle 0			; make math library the owner
	call	MemAllocSetOwner		; allocate memory
	jc	errorAlloc
	mov	es:[threadListHan], bx		; save away handle
	mov	ds, ax 
	
	; Now initialize the header
	;
	mov	{word}ds:[MTLH_numberOfElements], 0
	mov	cx, MATH_THREAD_LIST_INIT_SIZE
	mov	{word}ds:[MTLH_numberAllocated], cx 
	jmp	contNoLock
cont:
	; Lock the block
	;
	call	MemLock
	mov	ds, ax				; ds = locked segment	
contNoLock:
	inc	ds:[MTLH_numberOfElements]	; increment the number of elmts
	mov	ax, ds:[MTLH_numberOfElements]  ; if too overflow, realloc
	cmp	ax, ds:[MTLH_numberAllocated]
	jle	doAppend			; else go ahead and insert data
	add	ax, MATH_THREAD_LIST_INIT_SIZE
	mov	ds:[MTLH_numberAllocated], ax	

	; If need to realloc, allocate another MATH_THREAD_LIST_INIT_SIZE
	; more, so that we don't realloc to often
	;
	mov	cl, size MathThreadList
	mul	cl
	add	ax, size MathThreadListHeader
	mov	cx, mask HAF_LOCK
	call	MemReAlloc			
	jc	errorAlloc
	mov	ds, ax				; ds <- new locked segment
	mov	ax, ds:[MTLH_numberOfElements]		
doAppend:
	; Now calculate memory address to new element
	; position  = [(element number - 1) * (element size)] + header size
	;
	dec	al
	mov	cl, size MathThreadList
	mul	cl
	add	ax, size MathThreadListHeader

	; Retrieve data for new element and put it in element
	;
	mov	di, ax
	pop	cx, dx
	mov	ds:[di].MTL_stackDepth, dx
	mov	ds:[di].MTL_threadHandle, bp
	mov	ds:[di].MTL_softwareStackHandle, cx
	mov	ds:[di].MTL_hardwareStackHandle, si

	call	MemUnlock			; unlock our block
done:
	.leave
	ret

errorAlloc:
	pop	cx, dx
	jmp	done
MathThreadListAppend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MathThreadListFindThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	search through thread list to see if the thread entry is
		still around, if not then we must be careful about sending
		messages to Apps that have already exited

PASS: 		
		dx 	= Thread Handle to search for
		cx	= -1 means no update of depth otherwise
			  cx = the new depth
RETURN:		carry set if not element found, otherwise:

		carry clear
		CX = fp software stack Handle
		DX = fp stack depth
		SI = fp hardware stack handle	

DESTROYED:	AX

REGISTER/STACK USAGE:
	Standard dynamic register file

PSEUDOCODE/STRATEGY:	search though the ThredList looking for a specific 
			thread entry, return carry set if not found

KNOWN BUGS/SIDEFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/17/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MathThreadListFindThread	proc	far
	uses	di, ds

	.enter

	; If there is no thread handle then return carry set
	;
	push	es
NOFXIP< segmov	es, dgroup, bx				;es = dgroup	>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES			;es = dgroup		>
	mov	bx, es:[threadListHan]
	pop	es
	tst	bx
	jz	doneError

	; Lock the ThreadList block
	;
	call	MemLock
	mov	ds, ax

	; If there are no elements return carry set
	;
	tst	ds:[MTLH_numberOfElements]
	jz	noElement

	; Now es:di <- last element and cx <- # of elements
	;
	; we must look from the back to the front so that
	; if a single thread has done multiple FloatInits
	; it will have several entries that got put in front
	; to back.  SO we always want to get the latest one
	; put in by any givien thread, thus we search from back to front
	mov	di, cx			; save new depth in di
	mov	ax, size MathThreadList
	mov	cx, ds:[MTLH_numberOfElements]
EC <	cmp	cx, 0xff					>
EC <	ERROR_A	TOO_MANY_CLIENT_THREADS				>
	dec	cx
	mul	cl
	add	ax, size MathThreadListHeader
	xchg	di, ax	; di <- offset of first element, ax <- new depth
	inc	cx
searchLoop:
	; Now look at each element to see if the thread handle
	; passed in matches any of the elements
	;
	cmp	dx, ds:[di].MTL_threadHandle

	; If we find an match, return carry clear
	;
	jz	foundElement
	sub	di, size MathThreadList
	loop	searchLoop

	; If we get through the list with no match found, 
	; set the carry and return
	;
	jmp	noElement

foundElement:
	; Clear carry, unlock block and return
	;
	mov	cx, ds:[di].MTL_softwareStackHandle
	mov	si, ds:[di].MTL_hardwareStackHandle
	cmp	ax, -1
	jne	updateDepth
	mov	dx, ds:[di].MTL_stackDepth
gotDepth:
	clc
	jmp	doneUnlock
updateDepth:
	mov	ds:[di].MTL_stackDepth, ax
	mov_tr	dx, ax
	jmp	gotDepth
noElement:
	; Set the carry and unlock the block and return
	;
	stc

doneUnlock:
	; Unlock the ThreadList block
	;
	call	MemUnlock

done:
	; All done, it's Miller time !!!
	;
	.leave
	ret

doneError:
	stc
	jmp	done

MathThreadListFindThread endp


if 0 ; merged in with MainThreadListFindThread

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MathThreadListUpdatDepth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	search through thread list to see if the thread entry is
		still around, if not then we must be careful about sending
		messages to Apps that have already exited

PASS:		*ds:si	= MathClass instance data.
		ds:di	= *ds:si.
		es	= Segment of MathClass.
		dx 	= Thread Handle to search for
		cx	= new depth value		
RETURN:		carry set if not element found, otherwise:
		carry clear

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Standard dynamic register file

PSEUDOCODE/STRATEGY:	search though the ThredList looking for a specific 
			thread entry, return carry set if not found

KNOWN BUGS/SIDEFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/17/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MathThreadListUpdateDepth	proc	far
	uses	cx, ds, ax, di, bx

	.enter

	; If there is no thread handle then return carry set
	;
	push	es
NOFXIP<	segmov	es, dgroup, bx						>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES			;es = dgroup		>
	mov	bx, es:[threadListHan]
	pop	es
	tst	bx
	jz	doneError

	; Lock the ThreadList block
	;
	call	MemLock
	mov	ds, ax

	; If there are no elements return carry set
	;
	tst	ds:[MTLH_numberOfElements]
	jz	noElement

	; Now es:di <- last element and cx <- # of elements
	;
	; we must look from the back to the front so that
	; if a single thread has done multiple FloatInits
	; it will have several entries that got put in front
	; to back.  SO we always want to get the latest one
	; put in by any givien thread, thus we search from back to front
;	mov_tr	ax, cx
	push	cx				; new depth
	mov	di, size MathThreadListHeader
	mov	cx, ds:[MTLH_numberOfElements]
	mov	ax, size MathThreadList
EC <	cmp	cx, 0xff					>
EC <	ERROR_A	TOO_MANY_CLIENT_THREADS				>
	dec	cx
	mul	cl
	add	di, ax
	inc	cx
	pop	ax		; get new depth back
searchLoop:
	; Now look at each element to see if the thread handle
	; passed in matches any of the elements
	;
	cmp	dx, ds:[di].MTL_threadHandle

	; If we find an match, return carry clear
	;
	jz	foundElement
	sub	di, size MathThreadList
	loop	searchLoop

	; If we get through the list with no match found, 
	; set the carry and return
	;
	jmp	noElement

foundElement:
	; Clear carry, unlock block and return
	;
	mov	ds:[di].MTL_stackDepth, ax
	jmp	doneUnlock

noElement:
	; Set the carry and unlock the block and return
	;
	stc

doneUnlock:
	; Unlock the ThreadList block
	;
	call	MemUnlock

done:
	; All done, it's Miller time !!!
	;
	.leave
	ret

doneError:
	stc
	jmp	done

MathThreadListUpdateDepth	endp
endif

ThreadListCode	ends
