COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex/Main
FILE:		mainThread.asm

AUTHOR:		jimmy lefkowitz

DESCRIPTION:
	Code involving thread management. The thread management is
	straight forward, but the clean up is a bit involved. An
	overview of the lift of a thread is as follows:

		* An ImportExportClass object (a subclass, really)
		  asks to spawn a thread.

		* The thread is created, and an entry in the
		  thread list maintained by the Impex library is
		  created and initialized.

		* An IMPORT or EXPORT message is sent out, and the
		  import/export process ensues.

		* Now, either the app finishes & and sends a MSG_DETACH
		  to itself
				- or -
		  The application exits, and a DETACH is sent out before
		  import/export process is complete. An ObjIncDetach is
		  called on the owning object, to prevent it from leaving
		  before the thread has exited.

		* On receipt of MSG_META_ACK by the ImportExportClass
		  object, the ImpexThreadInfo block is destroyed, the
		  entry for the now-dead thread is removed from the
		  thread list, and a MSG_META_ACK will be sent on to
		  the superclass of the ImportExport object iff the
		  application is detaching.

	The code managing the thread lists is contained in this file.
	The code managing the detaches of the ImportExportClass is
	contained in UI/uiImportExport.asm

ROUTINES:
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/15/91		Initial version.
	don	6/ 3/92		Code & documentation changes

	$Id: mainThread.asm,v 1.1 97/04/04 23:29:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ProcessCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpawnThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Spawn an ImpexThreadProcessClass thread for either
		export or import

CALLED BY:	ImportControlImport, ExportControlExport

PASS:		AX	= Message to send to newly spawned thread
		BX	= ImpexThreadInfo block handle (locked)
		DS	= Object block owned by application

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS, ES

PSEUDOCODE/STRATEGY:	
		This routine uses MSG_PROCESS_CREATE_EVENT_THREAD which
		is call with an MF_CALL, thereby guaranteeing that the
		new thread will have been attached to its own event queue
		and be ready to receive messages
	
		all routines sent to a spawned thread will be handled by
		methods defined under ImpexThreadProcessClass

		once the thread is created, I insert an entry into the
		ImpexThreadList, this entry is how the Impex library
		can keep track of any threads that it spawns. Each entry
		contains the thread handle, the owning App's handle and
		an ImpexThreadInfo block handle, this ImpexThreadInfo block
		contains all information the thread needs to do its job.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	8/12/91		Initial version
		jenny	1/92		Cleaned up

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpawnThread	proc	far
	
		; Ignore input, if requested
		;
		push	ax, bx			; save message, ITI block handle
		mov	cx, ds:[LMBH_handle]	; block owned by app => CX
		call	MemDerefDS		; ImpexthreadInfo => DS
		call	InputIgnore
		call	MemUnlock		; unlock the Info first

		; Create an event thread by sending a message to the
		; application's thread.
		;
		mov	bx, cx
		call	MemOwner		; application's process => BX
		call	GeodeGetDGroupDS	; core block => DS
		mov	ax, segment ProcessClass
		mov	es, ax
		mov	di, offset ProcessClass
		mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD
		mov 	cx, segment ImpexThreadProcessClass
		mov	dx, offset ImpexThreadProcessClass
		mov	bp, IMPEX_THREAD_STACK_SIZE 
		call	ObjCallClassNoLock	; handle of new thread => AX
		pop	dx, cx			; message => DX
						; ImpexThreadInfo => CX
		jc	errorSpawning		; report error in spawning

		; Note that we've created a new thread
		;
		call	ImpexThreadCreated	; store data away

		; Now send off our initial message
		;
		mov_tr	bx, ax			; thread handle => BX
		mov_tr	ax, dx			; initial message => AX
		clr	di			; MessageFlags => DI
		GOTO	ObjMessage		; go for it!

		; We could not spawn the thread, so tell the user and abort
errorSpawning:
		mov	bx, cx			; ImpexThreadInfo => BX
		call	ImpexThreadInfoPLock
		mov	ax, IE_COULD_NOT_SPAWN_THREAD
		call	DisplayErrorAndBlock
		call	CleanUpImpexThreadInfo
		call	ImpexThreadInfoUnlockV
		GOTO	MemFree			; free the ThreadInfo
SpawnThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexThreadCreated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that an import/export thread has been created

CALLED BY:	GLOBAL

PASS:		AX	= Impex thread handle
		BX	= Application process handle
		CX	= ImpexThreadInfo

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexThreadCreated	proc	near
		uses	ds
		.enter
	
		; Some set-up work
		;
		call	ThreadListPLock		; lock & own the thread list

		; Add another entry, and initialize it
		;
		call	ThreadListAddEntry	; thread list => DS:SI
		mov	ds:[si].TLE_appProcess, bx
		mov	ds:[si].TLE_threadInfo, cx
		mov	ds:[si].TLE_threadHandle, ax

		; Clean up
		;
		call	ThreadListUnlockV	; unlock & release thread list

		.leave
		ret
ImpexThreadCreated	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexThreadDeleted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that an Impex thread list has been deleted

CALLED BY:	GLOBAL

PASS:		BX	= Impex thread handle

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexThreadDeleted	proc	near
		uses	di, si, ds
		.enter
	
		; Some set-up work
		;
		call	ThreadListPLock		; lock & own the thread list

		; Find the thread, and delete it
		;
		mov	di, offset EnumByThreadHandle
		call	ThreadListEnum		; search for entry by thread
		jc	done		
		call	ThreadListDeleteEntry	; remove the entry
done:
		call	ThreadListUnlockV	; unlock & release thread list

		.leave
		ret
ImpexThreadDeleted	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexThreadListAppExiting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell all import/export threads run by an application that
		they need to exit

CALLED BY:	ImportExportDetach

PASS:		*DS:SI	= ImportExportClass object

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		This routine goes through the thread list and for each
		active thread owned by the App that is detaching, sends
		a MSG_META_DETACH to it telling it to clean up and exit.
		If the thread is already exiting, another DETACH is
		*not* sent out, but the detach count for the 
		ImportExport object *is* incremented.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexThreadListAppExiting	proc	near
		uses	ax, bx, cx, dx, di, bp, ds
		.enter
	
		; Some set-up work
		;
		mov	dx, ds:[LMBH_handle]
		mov	bp, si			; Import/Export obj => ^lDX:BP
		mov	bx, dx
		call	MemOwner		; application thread => BX
		call	ThreadListPLock		; lock & own the thread list

		; Find all threads, and start the detaching
		;
		mov	di, offset EnumAppExiting
		call	ThreadListEnum		; enumerate though all entries

		; Clean up
		;
		call	ThreadListUnlockV	; unlock & release thread list
		mov	bx, dx
		call	MemDerefDS
		mov	si, bp			; Import/Export obj => *DS:SI

		.leave
		ret
ImpexThreadListAppExiting	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Lower-level routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadListPLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the ThreadList block down, creating one if it didn't
		exist before

CALLED BY:	INTERNAL

PASS:		Nothing

RETURN:		DS	= ThreadList segment

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ThreadListPLock	proc	near
		uses	ax, bx
		.enter

	; Get the handle, and see if we need to do anything
	;
NOFXIP <	segmov	ds, dgroup, ax					>
FXIP <		mov	bx, handle dgroup				>
FXIP <		call	MemDerefDS		; ds = dgroup		>
		mov	bx, ds:[threadList]	
EC <		tst	bx			; ensure handle exists	>
EC <		ERROR_Z IMPEX_THREAD_LIST_HANDLE_MUST_EXIST_TO_UNLOCK	>
		call	MemPLock
		mov	ds, ax

		.leave
		ret
ThreadListPLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadListUnlockV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the ThreadList block

CALLED BY:	INTERNAL

PASS:		DS:0	= ThreadList segment

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ThreadListUnlockV	proc	near
		uses	bx
		.enter
	
		mov	bx, ds:[TLH_handle]	; thread list handle => BX
EC <		tst	bx			; ensure handle exists	>
EC <		ERROR_Z IMPEX_THREAD_LIST_HANDLE_MUST_EXIST_TO_UNLOCK	>
		call	MemUnlockV

		.leave
		ret
ThreadListUnlockV	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadListAddEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an entry to the thread list

CALLED BY:	INTERNAL

PASS:		DS	= ThreadList segment

RETURN:		DS:SI	= ThreadListEntry to use

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ThreadListAddEntry	proc	near
		uses	bx, di
		.enter
	
		; See if we have an entry available. If not, create one
		;
		clr	bx
		mov	di, offset EnumByThreadHandle
		call	ThreadListEnum		; empty ThreadListEntry => DS:SI
		jc	appendEntry		; none, found, so append to end
done:
		.leave
		ret

		; Append a ThreadListEntry to the end of the list
appendEntry:		
		push	ax, cx
		mov	ax, ds:[TLH_size]
		mov	si, ax			; new ThreadListEntry => DS:SI
		add	ax, size ThreadListEntry
		mov	ds:[TLH_size], ax
		mov	bx, ds:[TLH_handle]	; ThreadList handle => BX
		mov	ch, mask HAF_NO_ERR	; can't deal with errors
		call	MemReAlloc		; reallocate block
		mov	ds, ax
		pop	ax, cx
		jmp	done			; we're done
ThreadListAddEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadListDeleteEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a ThreadListEntry

CALLED BY:	INTERNAL

PASS:		DS:SI	= ThreadListEntry

RETURN:		Nothing

DESTROYED:	DI

PSEUDO CODE/STRATEGY:
		Mark the entry as unused, rather than coalescing the block,
		as the block will only grow as large as the largest number
		of import/exports that occur simultaneously

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ThreadListDeleteEntry	proc	near
		clr	di
		mov	ds:[si].TLE_appProcess, di
		mov	ds:[si].TLE_threadHandle, di
		mov	ds:[si].TLE_threadInfo, di
		ret
ThreadListDeleteEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Enumeration-related routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadListEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate all of the entries in a ThreadList

CALLED BY:	INTERNAL

PASS:		DS	= ThreadList segment
		DI	= Callback routine to call (near)
			  Pass:		DS:SI	= ThreadListEntry
					AX, BX, CX, DX, BP = Data
			  Returns:	Carry = Set to stop enumeration
					AX, BX, CX, DX, BP = Data
			  Destroys:	Nothing

RETURN:		AX, BX, CX, DX, BP = Data returned by callback
		DS:SI	= ThreadListEntry
		Carry	= Clear
			- or -
		Carry	= Set (no entries accepted)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		May not delete or add entries inside of callback routines

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ThreadListEnum	proc	near
		.enter
	
		; Loop through the list of entries
		;
		mov	si, size ThreadListHeader
		jmp	midLoop
loopAgain:
		call	di
		jc	done			; if carry = set, accept
		add	si, size ThreadListHeader
midLoop:
		cmp	si, ds:[TLH_size]
		jl	loopAgain
		clc
done:
		cmc				; invert that carry!		

		.leave
		ret
ThreadListEnum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumByThreadHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for ThreadListEnum, searching for a
		thread handle

CALLED BY:	INTERNAL

PASS:		DS:SI	= ThreadListEntry
		BX	= Thread handle we're searching for

RETURN:		Carry	= Set if found

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EnumByThreadHandle	proc	near
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif
		cmp	ds:[si].TLE_threadHandle, bx
		stc
		jz	done
		clc
done:
		ret
EnumByThreadHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumAppExiting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An application is exiting, so we need to tell all of 
		threads run by the application to exit

CALLED BY:	ThreadListEnum

PASS:		DS:SI	= ThreadListEntry
		BX	= Application thread handle
		DX:BP	= Object that is detaching

RETURN:		Carry	= Clear (continue enumeration)

DESTROYED:	AX, CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EnumAppExiting	proc	near
		uses	bx, bp, ds, si
		.enter
	
		; See if we have the right thread
		;
		cmp	bx, ds:[si].TLE_appProcess
		jne	exit
		mov	ax, ds:[si].TLE_threadHandle
		mov	bx, ds:[si].TLE_threadInfo
		call	ImpexThreadInfoPLock	; ImpexThreadInfo => DS:0
		or	ds:[ITI_state], mask ITS_APP_DETACHING
		test	ds:[ITI_state], mask ITS_THREAD_DETACHING
		jnz	incDetachCount		; don't sent two DETACH's

		; Tell the thread that it better exit soon
		;
		mov	cx, bx			; ImpexThreadInfo handle => CX
		mov_tr	bx, ax			; thread handle => BX
		mov	ax, MSG_META_DETACH
		mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
		call	ObjMessage
				
		; Increment the detach count on the ImportExport object
incDetachCount:
		push	ds			; save ImpexThreadInfo
		mov	bx, dx
		call	MemDerefDS
		mov	si, bp			; ImpexObject => *DS:SI
		call	ObjIncDetach		; increment detach count
		pop	ds			; retreive ImpexThreadInfo
		call	ImpexThreadInfoUnlockV	; unlock & release Info block
exit:
		.leave
		ret
EnumAppExiting	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** ImpexProcessThread methods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ITPDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free all data structures as we're being destroyed

CALLED BY:	GLOBAL (MSG_META_DETACH)

PASS:		DS	= ImpexThreadProcess segment
		ES	= ImpexThreadProcessClass segment
		CX	= ImpexThreadInfo handle
		DX:BP	= Caller's OD		

RETURN:		Nothing

DESTROYED:	BX, DI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ITPDetach	method dynamic	ImpexThreadProcessClass, MSG_META_DETACH

		; Clean up the ImpexThreadInfo resources
		;
		push	ds
		call	GetCurrentThreadHandle	; thread handle => BX
		call	ImpexThreadDeleted	; remove from the thread list
		mov	bx, cx
		call	ImpexThreadInfoPLock
		call	CleanUpImpexThreadInfo
		mov	cl, ds:[ITI_state]	; ImpexThreadState => CL
		call	ImpexThreadInfoUnlockV
		call	MemFree			; free the ImpexThreadInfo block
		pop	ds

		; Pass message onto superclass
		;
		mov	ax, MSG_META_DETACH
		mov	di, offset ImpexThreadProcessClass
		GOTO 	ObjCallSuperNoLock

ITPDetach	endm

ProcessCode	ends
