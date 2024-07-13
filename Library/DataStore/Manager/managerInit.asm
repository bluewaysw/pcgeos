COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995.  U.S. Patent No. 5,327,529.
	All rights reserved.

PROJECT:	DataStore
MODULE:	        Manager
FILE:		managerInit.asm

AUTHOR:		Cassie Hartzog, Oct  5, 1995

ROUTINES:
	Name			Description
	----			-----------
GLB	DataStoreLibraryEntry	Library entry point
INT	ManagerInitialize	Allocates the Library Global Variables
INT	ManagerExit		Deallocates the Library Global Variables
INT	ManagerClientExit	Closes any sessions left open by the client
INT	MIDataStoreCloseIfHandlesMatchCallBack
				Call back which closes actually sessions.
INT	ManagerEmpty		Empty stub.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	10/ 5/95	Initial revision


DESCRIPTION:
	Routines for initializing the datastore manager.

	$Id: managerInit.asm,v 1.1 97/04/04 17:53:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ManagerInit	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataStoreLibraryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Library entry routine

CALLED BY:	
PASS:		di - LibraryCallType
		cx - handle of geode client, if
			LCT_NEW_CLIENT or LCT_CLIENT_EXIT
RETURN:		carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 5/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global DataStoreLibraryEntry:far
DataStoreLibraryEntry		proc	far
	uses	di
	.enter

	shl	di, 1		
	call 	cs:LibraryCallJumpTable[di]
		
	.leave
	ret
DataStoreLibraryEntry		endp

LibraryCallJumpTable	nptr	ManagerInitialize, ; LCT_ATTACH
				ManagerExit,       ; LCT_DETACH
				ManagerEmpty,  	   ; LCT_NEW_CLIENT
				ManagerEmpty,	   ; LCT_NEW_CLIENT_THREAD
				ManagerEmpty,	   ; LCT_CLIENT_THREAD_EXIT
				ManagerClientExit  ; LCT_CLIENT_EXIT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ManagerInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the DataStore Manager data strucutres. 

CALLED BY:	DataStoreLibraryEntry
PASS:		
		cx - handle of geode client, if
			LCT_NEW_CLIENT or LCT_CLIENT_EXIT
RETURN:		carry set on not enough error
DESTROYED:	ax,bx,cx,dx,ds,si

PSEUDO CODE/STRATEGY:
	10) Allocate a LMemblock 
	20) Initialize LMemBlock with a header that has room for
	    any global variables needed for this block 
	    as extra data in the LMemHeader.
	30) Initialize the name array needed for the DataStore
	    array. 
	40) Initialize the chunk array for the Session array.
	45) Initialize the dsToken counter.
	50) Stuff the DataStore and Session array handles
            in the LMemHeader as global variables for 
	    the data manager.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

*******	Note that we don't have to worry about getting an interrupt
	after the manager block is allocated but before the handle is
	stored in dsMLBHandle, because the Geode semaphore is held while
	this library is being loaded.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 5/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ManagerInitialize		proc	near
	.enter

	;Allocate the LMem heap 

        mov    	ax, LMEM_TYPE_GENERAL
        mov     cx, size ManagerLMemBlockHeader
        call    MemAllocLMem

	; make it sharable to avoid EC death on shutdown
	mov	al, mask HF_SHARABLE
	clr	ah
	call	MemModifyFlags

	LoadDGroup ds
	mov	ds:[dsMLBHandle], bx	
	call	MemLock
EC<	ERROR_C BAD_MANAGER_LMEM_BLOCK					>
	mov	ds, ax

	;Make the DataStore library the owner of the block and not
	;the GeoManager.
	
					;bx - handle of block 
	mov	ax, handle 0		;ax - block's new owner
        call    HandleModifyOwner

	;Create the DSElement name array 

        mov     bx, size DSElementData
        clr     cx, si			; cx - No extra data header
					; si - Allocate a new chunk
	mov	al, mask LMF_RETURN_ERRORS
        call    NameArrayCreate		; si - chunk handle of name array
	jc	memoryError
        mov     ds:[MLBH_dsElementArray], si  

	;Create the DSSession chunk array with fixed size elements
        
        mov     bx, size DSSessionElement 
				      ;fixed size elements
        clr     ax, cx, si            ; cx - No extra data in header
                       	      	      ; si - Allocate a new chunk
                       	              ; al - No flags
        call    ChunkArrayCreate      ; si - handle of element array
	jc	memoryError
        mov     ds:[MLBH_sessionArray], si
				      ; store the chunk array handle

	;Initialize the dsToken counter

	mov	ds:[MLBH_tokenCount], 0
	mov	bx, ds:[dsMLBHandle]
	call	MemUnlock
	clc

exit:
	.leave
	ret

memoryError:
	clr	bx
	xchg	bx, ds:[dsMLBHandle]
	call	MemFree			; preserves flags
	jmp	exit
ManagerInitialize		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ManagerExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleans up all the data structures for the data
		manager. This routine should only be called when no
		one is accessing the library. Therefore it is assumed
		that all entries in the DataStore array and Session array are
		gone and the only thing to do is to free the LMem
		block used to store the DataStore and Session ararys.
	

CALLED BY:	DataStoreLibraryEntry
PASS:		di - LibraryCallType
		cx - handle of geode client, if
			LCT_NEW_CLIENT or LCT_CLIENT_EXIT
RETURN:		carry set on error
DESTROYED:	
	
PSEUDO CODE/STRATEGY:
	10) Load the Manager LMem Block handle
	20) EC check to make sure the DataStore  name array is empty
	30) EC check to make sure the Session chunk array is empty
	40) MemFree the Manager LMem Block handle

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 5/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ManagerExit		proc	near
	.enter

	;Free the DataStore Manager Memory Block

	LoadDGroup ds, ax
	clr	bx
	xchg 	bx, ds:[dsMLBHandle]	
		
EC <	call	MemLock							>
EC<	ERROR_C	BAD_MANAGER_LMEM_BLOCK					>
EC<	mov  	ds, ax 		        ; Manager LMem segment  	>
							
	;Check to make sure the Session array is empty

EC<	mov	si, ds:[MLBH_sessionArray]				>
EC<	call	ChunkArrayGetCount      ;cx now has count		>
EC<     tst	cx							>
EC<	ERROR_NZ MANAGER_EXIT_WITHOUT_EMPTY_SESSION_ARRAY		>

	;Check to make sure the DataStore array is empty

EC<	push	bx							>
EC<	mov	si, ds:[MLBH_dsElementArray]				>
EC<	clr	bx			; no callback			>
EC<	call	ElementArrayGetUsedCount				>
EC<     tst	ax							>
EC<	ERROR_NZ MANAGER_EXIT_WITHOUT_EMPTY_DATASTORE_ARRAY		>
EC<	pop	bx							>
	
	;Everything is okay, exit stage left

EC<	call 	MemUnlock						>
	call 	MemFree

	clc				; return no error

	.leave
	ret
ManagerExit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ManagerClientExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:  Checks the passed geode handle against ones stored in the
	   Session array to see if the geode has any outstanding open
	   datastores. If so, calls the appropriate close DataStore
	   routines to clean up the table.

CALLED BY:	(INTERNAL) DataStoreLibraryEntry
PASS:		di - LibraryCallType
		cx - handle of geode client, if
			LCT_NEW_CLIENT or LCT_CLIENT_EXIT
RETURN:		carry set on error
DESTROYED:	bx,si,di,ds

PSEUDO CODE/STRATEGY:
	10) Lock down Manager Memory Block
	20) Use ChunkArrayEnum for each entry in the DataStore array, 
	    check if the passed geode handle matches a table entry 
            geode handle.
        30) For each matching entry, call the DataStoreClose routine
            on the dsToken to delete the entry and possibly close
	    a DataStore file.
	40) Cause an EC error for any DataStore which fails closing.
	50) Unlock Manager Memory Block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/ 5/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ManagerClientExit		proc	near
	uses 	cx
	.enter

	call	MSLockMngrBlockP
        mov	si, ds:[MLBH_sessionArray]	;si - ChunkArray ChunkHandle
EC<	call	ECCheckChunkArray					>

	;Call ChunkArrayEnum to check if handles match and if so to
	;close any sessions the geode has opened

	call	GeodeGetProcessHandle
	mov	cx, bx
	mov	bx, cs
	mov	di, offset MIDataStoreCloseIfHandlesMatchCallback
	call	ChunkArrayEnum			
	call	MSUnlockMngrBlockV

	.leave
	ret
ManagerClientExit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MIDataStoreCloseIfHandlesMatchCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ChunkArrayEnum for the Session array which closes
	        the session if the passed geode matches a geode
		handle in session.
	
CALLED BY:	(INTERNAL) ManagerClientExit
PASS:
		cx - handle of geode client
		ds:di  = Chunk Array element

RETURN:		carry clear

DESTROYED:	bx
SIDE EFFECTS:	May delete an element in the ChunkArray.

PSEUDO CODE/STRATEGY:
	10) Verify the DSSE_client GeodeHandle
	20) Compare the passed in handle with DSSE_client
	30) If they are not equal, exit,
	40) else call DataStoreClose on the dsToken in the DSSessionElement


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	10/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MIDataStoreCloseIfHandlesMatchCallback	proc	far
	uses	ax, cx
	.enter

EC<	Assert 	handle, ds:[di].DSSE_client				>
	cmp	cx, ds:[di].DSSE_client	;Geode handles equal?
	jne	done

	;The handles are equal, close the DataStore which should also
	;delete this Session Array element from the ChunkArray. If not, 
        ;there is something wrong with DataStoreClose.

	pushdw	ds:[di].DSSE_notifObj
	mov	ax, ds:[di].DSSE_session       
					;DataStoreClose parameter
	mov	bx, mask DSCF_DISCARD_LOCKED_RECORDS
	call 	MDDataStoreCloseWithFlags
					;removes entry from the table
EC<	cmp	ax, DSE_NO_ERROR					> 
EC<	ERROR_NZ MANAGER_CLIENT_EXIT_CANT_CLOSE_DATASTORE		>

	popdw	cxdx
	jcxz	done
EC <	push	si						>
EC <	movdw	bxsi, cxdx					>
EC <	call	ECCheckOD					>
EC <	pop	si						>
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GAGCNLT_NOTIFY_DATASTORE_CHANGE
	call	GCNListRemove

done:
	clc				;look through all the elements	

	.leave
	ret 
MIDataStoreCloseIfHandlesMatchCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ManagerEmpty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Empty routine.

CALLED BY:	DataStoreLibraryEntry
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		none
PSEUDO CODE/STRATEGY:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	9/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ManagerEmpty	proc	near
	.enter

	clc			     ;return no error

	.leave
	ret
ManagerEmpty	endp


ManagerInit	ends













