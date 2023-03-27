COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved
	Geoworks Confidential

PROJECT:	GEOS
MODULE:		IR Object Database
FILE:		irdbApi.asm

AUTHOR:		Andy Chiu, Jan 10, 1996

ROUTINES:
	Name			Description
	----			-----------
	IrdbOpenDatabase	GLOBAL
	IrdbCloseDatabase	GLOBAL
	IrdbCreateEntry		GLOBAL
	IrdbAddAttribute	GLOBAL
	IrdbGetValueByClass	GLOBAL
	IrdbDeleteEntry		GLOBAL

	IrdbDeleteUsingClientHandle			INTERNAL

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/10/96   	Initial revision


DESCRIPTION:
	Routines to access the object database.	

	$Id: irdbApi.asm,v 1.1 97/04/05 01:08:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

	irdbLibrarySem	Semaphore	<1,>	; library semaphore
	irdbClientCount	word		0	; number

idata	ends

udata	segment

	irdbFileHandle	hptr			; database file handle
		
udata	ends

IrdbCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrdbOpenDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the database so we can read/write information to it.
		Multiple clients can read/write to the database,
		This routine will block the thread if another is doing
		an access. 

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry set if error
		ax = IrdbErrorType
		else ax = 0
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IRDBOPENDATABASE	proc	far
		uses	bx,cx,dx,si,di,bp,ds
		.enter

	;
	; Grab the semaphore for exclusive access to the library
	;
		call	IUGrabLibrarySem
	;
	; Check to see if we already have the file open.
	; If so, then lets go ahead and use it.
	;
		call	UtilsLoadDGroupDS
		tst	ds:[irdbFileHandle]
		jnz	exitClean
		
	;
	; Open the database file.  Create one if it's not there.
	;
		call	IIOpenDatabaseFile
		jc	openError
	;
	; If the file was newly created, then we'll have to initialize it.
	;
		cmp	ax, VM_CREATE_OK
		jz	initFile

	;
	; Check the protocol number of the file. 
	;
		call	IICheckDatabaseFileProtocol
		jnc	saveHandle
	;
	; We got to create a new file.  Delete the old one.
	; It's no good anymore.
	;
		call	IIDeleteDatabaseFile
		call	IIOpenDatabaseFile
		jc	openError
		jmp	initFile
	;
	; We did a succesful open.  Increment the client count
	; Save the file handle
	;
saveHandle:
		mov	ds:[irdbFileHandle], bx		

	;
	; Clean up any objects that shouldn't be in the database anymore
	;
		call	IICleanUpDatabaseFile
		
exitClean:
		clr	ax			; return value
		inc	ds:[irdbClientCount]
		clc

exit:
		call	IUReleaseLibrarySem
		.leave
		ret
	;
	; Couldn't open nor create the file.
	;
openError:
		mov	ax, IET_OPEN_ERROR
		stc
		jmp	exit

	;
	; Need to initialize the file.  We also have to set the file
	; handle here because the initialize routine calls API functions
	; that assume the file handle is there.
	;
initFile:
		mov	ds:[irdbFileHandle], bx
		call	IIInitializeDatabaseFile	; carry set if error
		jnc	exitClean
		jmp	exit

		
IRDBOPENDATABASE	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrdbCloseDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the database

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		ax	= IrdbErrorType 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IRDBCLOSEDATABASE	proc	far
		uses	bx,cx,dx,si,di,bp,ds
		.enter

	;
	; Grab the library semaphore
	;
		call	IUGrabLibrarySem
	;
	; Decrement the client count.
	; If we're not the last one, then
	; lets just exit cleanly.
	;
		call	UtilsLoadDGroupDS
		dec	ds:[irdbClientCount]
		jnz	exitClean

	;
	; We're done with the file.  So let's close it and go home
	;
		clr	ax,bx
		xchg	bx, ds:[irdbFileHandle]

		call	VMClose
		jc	error

	;
	; The operation was successful
	;
exitClean:
		clr	ax		; return value
		clc

exit:
		call	IUReleaseLibrarySem
		
		.leave
		ret

error:
		mov	ax, IET_DISK_FULL	; !* not really
		stc
		jmp	exit
IRDBCLOSEDATABASE	endp

FXIP	<	IrdbCode	ends			>
FXIP	<	ResidentXIP	segment	resource	>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrdbCreateEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an entry to the database.  The information needed
		to establish an entry is a class name. 

CALLED BY:	GLOBAL
PASS:		ds:si	= class name
		cx	= string length	(0 for null)
		dx	= client handle

RETURN:		carry clear if sucessful
		ax = Object ID assigned to entry
		carry set if error
		ax = IrdbErrorType
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

There used to be a parameter like this:
		al	= IrdbCreateEntryFlags
But we're disallowing persistent objects now, so we're nuking
it.  -- &y 5/2/96
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrdbCreateEntry		proc	far
FXIP <		uses	es, di, cx					>
FXIP <		.enter							>
		call	IUGrabLibrarySem
	; 
	; If the class name is null terminated, we need to find the
	; true size.
	;
if _FXIP
		tst	cx
		jnz	copyToStack

		movdw	esdi, dssi
		SBStringLength			; cx <- string length
copyToStack:
		call	SysCopyToStackDSSI
endif
		
		call	IrdbCreateEntryLow
FXIP <		call	SysRemoveFromStack				>
		call	IUReleaseLibrarySem

FXIP <		.leave							>
		ret
		
IrdbCreateEntry	endp

FXIP	<	ResidentXIP	ends			>
FXIP	<	IrdbCode	segment	resource	>

FXIP	<	IrdbCreateEntryLow	proc	far	>
NOFXIP	<	IrdbCreateEntryLow	proc	near	>
classname		local	fptr	push	ds, si
classnameLength		local	word	push	cx
clientHandle		local	word	push	dx
createFlags		local	word	push	ax
newObjectID		local	word		
		uses	cx,dx,si,di,bp,ds,es
		.enter


		Assert	fptr, dssi

	;
	; We're taking out the ability to add persistent objects.
	; I'm leaving the code in there to add persistent objects,
	; in case we want them back again.  In the meantime,
	; I'm just going to clear out al, so that it seems
	; the caller did not want the object to be persistent
	; no matter what was passed -- &y 5/2/96
	;
		clr	al
	;
	; Find out how big the string is without the null.
	; If the user supplied a string, then don't bother finding the size
	;
		tst	cx
		jnz	getMapBlock
	;
	; It's a null terminated string, so compute the size
	;
		movdw	esdi, dssi
		SBStringLength			; cx <- string size
		mov	ss:classnameLength, cx		
	;
	; Create a first get the object chunk array to write the
	; new name in of the object.
	;
getMapBlock::
		call	IIGetObjArrayFileBlockAndChunkHandles
	; 	bx	= File handle
	;	ax	= VMBlock handle of object array
	;	si	= Chunk array handle of object array

	;
	; Lock down the chunk array
	;
		push	bp			; save for locals
		call	VMLock			; ax <- segment
						; bp <- mem handle
		pop	bp			; bp <- for locals
		mov_tr	ds, ax			; *ds:si <- chunk array
	;
	; Get a new object id to use for this element
	;
		call	IIGetNewObjectID		; ax <- new object id
		mov_tr	ss:newObjectID, ax		; save object id
	;
	; Calculate how big the chunk array entry should be.
	; That size is an IrdbObjArray struct plus the size of the string.
	;
		mov	ax, size IrdbObjArrayEntry
		add	ax, cx			; ax <- element size
	;
	; Add an element to our object array. 
	;
		Assert	ChunkArray	dssi
		call	ChunkArrayAppend	; ds:di <- new element
		jc	appendError
	;
	; Add the information into the chunk array.
	; We're going to use the chunk array element as the object id.
	; The last element is always going to have the highest number.
	;
		clr	ds:[di].IOAE_attrsBlockHandle	; no attrs yet
		mov	ax, ss:newObjectID
		mov	ds:[di].IOAE_objectID, ax	; write into chunkarray
		mov	ds:[di].IOAE_classNameSize, cl	; string size

	;
	; Put in the IrdbEntryFlags and the client handle
	;
		mov	ax, ss:clientHandle
		mov	ds:[di].IOAE_clientHandle, ax
		mov	ax, ss:createFlags
		mov	ds:[di].IOAE_flags, al
	;
	; Copy the class name.
	;
		Assert	ChunkArray	dssi
		lea	di, ds:[di].IOAE_className
		segmov	es, ds			; es:di <- destination

		movdw	dssi, ss:classname
		mov	cx, ss:classnameLength
		rep	movsb
	;
	; Done with the chunk array.  Unlock the block.
	;
		push	bp
		mov	bp, es:[LMBH_handle]
		call	IUUnlockBlockAndUpdateFile
		pop	bp			; bp <- local vars
	;
	; Need to supply object id here.
	;
		mov	bx, ss:newObjectID
		clc				; exit clean
		lahf				; save flags for exit
exit:
		.leave
		sahf				; restore flags for exit
		mov_tr	ax, bx			; return value
		ret
	;
	; Error in adding a new entry.  Assumes that carry has been set.
	;
appendError:
		call	VMUnlock		; unlock the block
		mov	bp, dx			; for locals
		mov	ax, IET_MEM_ERROR
		stc
		lahf				; restore flags for exit
		jmp	exit	
		
IrdbCreateEntryLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrdbDeleteEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete an entry in the database.  Give only
		the object id that was returned in the
		IrdbCreateEntry function.

CALLED BY:	GLOBAL
PASS:		bx	= Object ID
RETURN:		carry set if error
		ax = IrdbErrorType
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrdbDeleteEntry	proc	far
		uses	bx,cx,si,di,bp,ds
		.enter

	;
	; Grab the library semaphore
	;
		call	IUGrabLibrarySem
	;
	; Get the object array.
	;
		mov	cx, bx			; bp <- object id
		call	IIGetObjArrayFileBlockAndChunkHandles
			; bx <- file handle
			; ax = VMBlock handle
			; si = Chunk array handle
	;
	; Lock down the chunk array
	;
		call	VMLock			; bp <- mem handle
						; ax <-segment
		mov_tr	ds, ax
		Assert	ChunkArray	dssi
	;
	; Get the element in the object array
	;
		xchg	cx, bx			; cx <- object ID
		call	IUGetObjectFromObjectID	; ds:di <- Chunk array element
		jc	error
	;
	; Delete the element from our object array
	;
		mov	bx, cx			; bx <- fil handle
		call	IUDeleteObjectFromObjectArray
	;
	; Update the file.
	;
		call	IUUnlockBlockAndUpdateFile
		clr	ax			; return value
		
exit:
		call	IUReleaseLibrarySem
		
		.leave
		ret
error:
		stc
		jmp	exit
IrdbDeleteEntry	endp

FXIP	<	IrdbCode	ends			>
FXIP	<	ResidentXIP	segment	resource	>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrdbAddAttribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an attribute and the value for an object.

CALLED BY:	GLOBAL
PASS:		bx	= Object ID
		ds:si	= fptr to attribute name 
		bp	= length of attribute
		di	= attribute type
		cxdxax	= data
RETURN:		carry clear if sucessful
			ax = Current number of attributes in the object
 		carry set if error
			ax = IrdbErrorType
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrdbAddAttribute	proc	far
FXIP <		uses	es, ds, si, bx, bp, cx				>
FXIP <		.enter							>

		call	IUGrabLibrarySem
if _FXIP
	;
	; Copy the attribute name to the stack.
	; If type of data is also an octet sequence or a user string,
	; then we have to copy that data too.	
	; If the string is supposed to be null terminated,
	; we`ll have to find the length of the string
	;
		xchg	cx, bp			; cx <- attr name length
		tst	cx
		jnz	copyAttrNameToStack

		push	di			; save attribute type
		movdw	esdi, dssi
		SBStringLength			; cx <- attr name length
		pop	di			; restore attribute name
		
copyAttrNameToStack:
		call	SysCopyToStackDSSI		
		xchg	cx, bp			; bp <- attr name length
	;
	; If it's an octet sequence or a user string, we'll have to
	; copy it to the stack.
	;
		cmp	di, IIVT_OCTET_SEQUENCE
		jnz	checkUserString

		xchgdw	bxsi, dxax
		call	SysCopyToStackBXSI
		xchgdw	bxsi, dxax

	;
	; If it's a string, check to see if it's null terminated.
	; If it is, then find it's length before copying it to the stack.
	;
checkUserString:	
		cmp	di, IIVT_USER_STRING
		jnz	makeCall

		movdw	esdi, dxax
		mov	ax, cx			; ax <- cx original 
		tst	cl
		jnz	copyString

		SBStringLength			; cx <- string length
NEC <		clr	ch						>
EC <		tst	ch						>
EC <		ERROR_NZ -1						>
copyString:
		call	SysCopyToStackESDI
		mov	ch, ah			; ch <- char set
		movdw	dxax, esdi
		mov	di, IIVT_USER_STRING

makeCall:
endif
		call	IrdbAddAttributeLow
	;
	; We have to restore the stack and remember to return the carry flag
	;
if _FXIP
		mov_tr	bx, ax
		lahf	
		call	SysRemoveFromStack
		cmp	di, IIVT_USER_STRING
		jz	restore
		cmp	di, IIVT_OCTET_SEQUENCE
		jnz	releaseSem
restore:
		call	SysRemoveFromStack
		
releaseSem:
		sahf
		mov_tr	ax, bx
endif
		call	IUReleaseLibrarySem

FXIP <		.leave							>
		ret
IrdbAddAttribute	endp

FXIP	<	ResidentXIP	ends			>
FXIP	<	IrdbCode	segment	resource	>

NOFXIP<	IrdbAddAttributeLow	proc	near		>
FXIP<	IrdbAddAttributeLow	proc	far		>
		uses	bx,es
		.enter

		Assert	fptr	dssi
		Assert	etype	di, IrlmpIasValueType
	;
	; Save the parameters for the call later.
	;
		push	ds, si, bp, cx, dx, ax, di
	;
	; Add an attribute to the database.
	;
		mov	cx, bx			; cx <- object id
		call	IIGetObjArrayFileBlockAndChunkHandles
			; bx = file handle
			; ax = VMBlock handle of object array
			; si = Chunk handle of object array
	;
	; Grab the chunk array and see if there's an attribute array
	;
		call	VMLock		; ax <- segment
		mov_tr	ds, ax		; ds:si <- object chunk array
	;
	; Get the element with the right object id.
	;
		Assert	ChunkArray	dssi
		mov_tr	bx, cx		; bx <- object id
		call	IUGetObjectFromObjectID	; ds:di <- element
		jc	findError
	;
	; Add the attribute to the attribute array.  Pass ds:di as
	; the element to the chunk array.  Also the routine inherits
	; our local variables, so make sure bp has the right value.
	;
		call	IIAddAttributeToAttributeArray	; cx <- number of attrs
	;
	; Unlock the VMBlock that contained our object array
	;
		pushf
		mov	bp, ds:[LMBH_handle]
		call	IUUnlockBlockAndUpdateFile
		popf
exit:
	;
	; Restore stack and restore registers.  BX replaces
	; ax because ax is the return value and we can return trash bx
	;
		mov_tr	ax, cx			; return value
		pop	ds, si, bp, cx, dx, bx, di

		.leave
		ret
	;
	; Unable to find the object from the database.
	; Unlock the block and exit.  Return the error.
	;
findError:
		call	VMUnlock
		stc
		jmp	exit

IrdbAddAttributeLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrdbGetValueByClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the GetValueByClass call.
		This function will search through the database
		To find the requested data about a class.
		It will then send the data back to the
		IasServerFsm that called this routine.

CALLED BY:	ISAGetValueByClass
PASS:		*ds:si	= ServerFsm to write too.
		es:di	= data to search for.	
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrdbGetValueByClass	proc	far
serverFsm		local	dword	push	ds, si
foundCount		local	word	; how many objects we found
classMatchCount		local	word	; number of objects with matching classname		
attrString		local	fptr	; attr string that was recv.
attrSize		local	byte	; attr size that was recv.
fileHandle		local	word	; db file handle
objArrayElement		local	fptr	; fptr to an object array element
		uses	bx,di,bp,es,ds
		.enter

		ForceRef	objArrayElement
		
		Assert	objectPtr	dssi, IasServerFsmClass
		Assert	fptr	 	esdi

	;
	; Set the data size so we can start writing beyond
	; the return value and argument count.
	; This is IRH_data, which is past the return value
	; plus the size of the argument count.
	;
		mov	ax, MSG_ISF_SET_DATA_SIZE
		mov	cx, IRH_data + size (word)
		call	ObjCallInstanceNoLock
	;
	; Load dgroup into ES so we can get the file handle
	;
		call	UtilsLoadDGroupDS
		mov	bx, ds:[irdbFileHandle]
		mov	ss:fileHandle, bx
		clr	ss:foundCount, ss:classMatchCount
	;
	; Get ptrs to inside the datablock so we can access it
	; easily later.
	;
	; Find out where the class data is kept in this thing
	;
		clr	cx
		mov	cl, {byte} es:[di]	; bx <- size of class name
		inc	di			; ds:di <- class name
	;
	; find out where the attribute data is kept in this thing.
	;
		mov	si, di
		add	si, cx		 ; ds:di <- begining of attr data

		mov	dl, {byte} es:[si]
		mov	ss:attrSize, dl
		inc	si			; ds:di <- attr string
		movdw	ss:attrString, essi
	;
	; Get the map object block of the file.
	;
		call	IUGetObjArray		; ax <- VMBlock handle
						; si <- chunk handle
	;
	; Lock down the block and get the Object array
	;
		push	bp			; #1 for locals
		call	VMLock			; ax <- segment
		pop	bp			; #1 bp <- locals

		mov_tr	ds, ax			; *ds:si <- object array
		Assert	ChunkArray	dssi

	;
	; Go through the object array looking for the class
	; es:di <- should still be pointing to the class name
	; cx should be the class size
	;
		mov	bx, SEGMENT_CS
		mov	dx, di			; es:dx <- class name
		mov	di, offset IIGVBCLookForClassCallback
		call	ChunkArrayEnum
	;
	; Unlock the object array.  The block handle is in the
	; local variable vmMemHandle
	;
		push	bp			; save for locals
		mov	bp, ds:[LMBH_handle]	; mem handle
		call	VMUnlock
		pop	bp			; restore for locals

	;
	; Write that this is the last frame and that this is a
	; GetValueByRequest in the control byte
	;
		push	bp

		mov	dx, mask IICB_LAST or IIOC_GET_VALUE_BY_CLASS
		mov	cx, IIF_iasControlByte		
		lds	si, ss:serverFsm
		mov	ax, MSG_ISF_INSERT_DATA
		mov	bp, TRUE		; writing word
		call	ObjCallInstanceNoLock

		pop	bp
	;
	; Write the number of objects that we are returning.  Also let
	; si be the value of the data offset to Irlmp knows where
	; it can put the IrlmpIasFrame
	;
		push	bp
		
		mov	dx, ss:foundCount
		xchg	dl, dh			; net protocol
		mov	cx, IRH_data
		mov	bp, TRUE
		call	ObjCallInstanceNoLock

		pop	bp
		
	;
	; Figure out the return code in the buffer.
	; If the found count is zero, then the class wasn't found.
	;
		mov	cx, IRH_returnValue
		tst	dx
		mov	dx, IGVBCRC_SUCCESS
		jnz	writeReturn
	;
	; There is an error, so don't return any data.
	; If we found the class but not the attribute we return
	; NO_SUCH_ATTRIBUTE.  If we just didn't find the class,
	; we'll return NO_SUCH_CLASS
	;
		mov	dx, IGVBCRC_NO_SUCH_CLASS

		tst	ss:classMatchCount
		jz	writeReturn
		
		mov	dx, IGVBCRC_NO_SUCH_ATTRIBUTE

writeReturn:
		push	bp
		
		mov	bp, FALSE
		call	ObjCallInstanceNoLock
		
		pop	bp

		.leave
		ret
IrdbGetValueByClass	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrdbDeleteUsingClientHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete an entry in the database from the client handle
		it uses. 

CALLED BY:	IrlmpUnregister
PASS:		si	= client handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrdbDeleteUsingClientHandle	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter

		call	IUGrabLibrarySem
	;
	; Get the object array so, we check all the client handles
	;
		call	UtilsLoadDGroupDS
		mov	bx, ds:[irdbFileHandle]
		tst	bx
		jz	done
		
		mov	cx, si			; cx <- client handle
		call	IUGetObjArray		; ax <- block handl
						; si <- chunk handle
	;
	; Lock down the chunk array.
	;
		call	VMLock			; ax <- segment
		mov_tr	ds, ax			; *ds:si <- object array


		push	bx			; save file handle

		Assert	ChunkArray	dssi
		mov	bx, SEGMENT_CS
		mov	di, offset IUFindObjectUsingClientHandleCallback
		call	ChunkArrayEnum

		pop	bx			; bx <- file handle
		
		jnc	unlockBlock			; element not found
	;
	; If we got the here, then there's an element to delete.
	; Check to make sure it's not a permanent element
	;
		mov_tr	di, ax			; ds:di <- element to delete

		test	ds:[di].IOAE_flags, mask ICEF_PERMANENT
		jnz	unlockBlock

	;
	; Delete the element from our object array
	;
		call	IUDeleteObjectFromObjectArray
		
unlockBlock:
		call	IUUnlockBlockAndUpdateFile

done:
		call	IUReleaseLibrarySem
		
		.leave
		ret
IrdbDeleteUsingClientHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrdbDestroyDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the database so we can recreate it.

CALLED BY:	
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Even if there's an error in the file delete, we'll just
	go on since we can still probably use it.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	5/ 2/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrdbDestroyDatabase	proc	far
		uses	ax,dx,ds
		.enter
	;
	; Go to the directory of the file.
	;
		call	FilePushDir
		mov	ax, SP_USER_DATA
		call	FileSetStandardPath
	;
	; Try to delete the file.
	;
		segmov	ds, cs
		mov	dx, offset irdbDatabaseFileName
		call	FileDelete

EC <		WARNING_C IRLMP_IRDB_CANNOT_DELETE_DATABASE_FILE	>

		call	FilePopDir
		
		.leave
		ret
IrdbDestroyDatabase	endp

IrdbCode	ends















