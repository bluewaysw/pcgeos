COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Irlmp
FILE:		irdbUtils.asm

AUTHOR:		Andy Chiu, Feb  6, 1996

ROUTINES:
	Name			Description
	----			-----------
	IUGrabLibrarySem
	IUReleaseLibrarySem

	IUGetObjArray
	IUGetObjectFromObjectID
	IUGetAttributeArray
	IUUnlockBlockAndUpdateFile
	IUFindObjectUsingClientHandleCallback
	IUDeleteObjectFromObjectArray


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/ 6/96   	Initial revision


DESCRIPTION:
	Utility functions to grab info from the database
		

	$Id: irdbUtils.asm,v 1.1 97/04/05 01:08:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrdbCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUGrab/ReleaseLibrarySem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab/Release the library semaphore so no one else can much with
		the database while we're working.

CALLED BY:	(INTERNAL) IrdbAddAttribute, IrdbCloseDatabase,
		IrdbCreateEntry, IrdbDeleteEntry,
		IrdbDeleteUsingClientHandle, IrdbOpenDatabase

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NOFXIP<	IUGrabLibrarySem	proc	near		>
FXIP<	IUGrabLibrarySem	proc	far		>


		push	ds
		pushf
		call	UtilsLoadDGroupDS
		PSem	ds, irdbLibrarySem
		popf

		pop	ds
		ret
IUGrabLibrarySem	endp

NOFXIP<	IUReleaseLibrarySem	proc	near		>
FXIP<	IUReleaseLibrarySem	proc	far		>

		push	ds
		pushf
		call	UtilsLoadDGroupDS
		VSem	ds, irdbLibrarySem
		popf
		pop	ds		
		ret
IUReleaseLibrarySem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUGetObjArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the VMBlock handle and the chunk handle for the
		ObjArray in our database file.

CALLED BY:	(INTERNAL) IrdbDeleteUsingClientHandle, IrdbGetValueByClass
PASS:		bx	= file handle
RETURN:		ax	= VMBlock handle
		si	= Chunk handle
		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUGetObjArray	proc	near
		uses	ds, bp
		.enter
	;
	; Get the map block for the file.
	;
		call	VMGetMapBlock		; ax <- Map Block handle
		tst	ax
		stc
		jz	exit
		
	;
	; Load in the map block and find out what the
	; VMBlock handle and chunk handle is for the object array
	;
		call	VMLock			; ax <- segment
						; bp <- mem handle
	;
	; Get the data we need to pass back
	;
		mov_tr	ds, ax
		mov	ax, ds:[IFMB_objArrayVMBlockHandle]
		mov	si, ds:[IFMB_objArrayChunkHandle]
	;
	; Unlock the map block.
	;
		call	VMUnlock
		clc
exit:
		.leave
		ret
IUGetObjArray	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUGetObjectFromObjectID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the element in our object array that matches the object
		id that was passed in.

CALLED BY:	(INTERNAL) IrdbAddAttributeLow, IrdbDeleteEntry
PASS:		*ds:si	= Chunk Array
		bx	= object id
RETURN:		carry set if item not found
		ds:di	= Chunk array item
		ax	= element number
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUGetObjectFromObjectID	proc	near
		uses	ax,bx,cx,dx,si,bp
		.enter

		Assert ChunkArray	dssi
	;
	; Search through the chunk array until we find it or
	; there is no more items.
	;
		mov	di, ds:[si]
		mov	ax, ds:[di].CAH_count	; ax <- number of elements
		dec	ax			; ax <- element to access
		js	notFound
	;
	; Enumerate through the chunk array looking for a match with object
	; ID's
	;
enumChunkArray:
		call	ChunkArrayElementToPtr	; ds:di <- element

		cmp	ds:[di].IOAE_objectID, bx
		jz	done			; carry is clear if equal

		dec	ax
		jns	enumChunkArray

notFound:
		stc

done:
		.leave
		ret
IUGetObjectFromObjectID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUGetAttributeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the VM Block handle and chunk handle for the
		attribute array.  If it doesn't exist, we create it
		and add it to the object info

CALLED BY:	(INTERNAL) IIAddAttributeToAttributeArray
PASS:		es:di	= Element in object array (IrdbObjArrayEntry)
RETURN:		carry clear if successful
		ax	= vm block handle for attribute chunk array
		si 	= chunk handle for attribute chunk array
		*ds:si	= Chunk array
		bp	= Mem handle for locked VM Block
		(ds may have changed
DESTROYED:	nothing
SIDE EFFECTS:	Must unlock block when done.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUGetAttributeArray	proc	near
		uses	bx,dx
		.enter

		Assert	fptr	esdi
	;
	; Get the file handle so we can lock down the block
	;
		call	UtilsLoadDGroupDS
		mov	bx, ds:[irdbFileHandle]
	;
	; See if there already is an attribute array for this object
	;
		tst	es:[di].IOAE_attrsBlockHandle
		jnz	getArray	
	;
	; Create the attribute array in a separate lmem block.
	;
		mov	dx, size IrdbAttrArrayEntry
		call	IICreateVMChunkArray	; *ds:si <- chunk array
						; ax <- VMBlock Handle
						; bp < mem handle
		jc	error
	;
	; Save the handles for the attribute array in the object array
	;
		mov	es:[di].IOAE_attrsBlockHandle, ax
		mov	es:[di].IOAE_attrsChunkHandle, si
		jmp	short	doneClean

	;
	; Get the handles for the for the attribute array.
	;
getArray:
		mov	ax, es:[di].IOAE_attrsBlockHandle
		mov	si, es:[di].IOAE_attrsChunkHandle
	;
	; Lock the attribute array block down.
	;
		push	ax
		call	VMLock			; ax <- segment
		mov_tr	ds, ax			; *ds:si <- attribute array
		pop	ax
		
doneClean:
		Assert	vmMemHandle	bp
		Assert	ChunkArray	dssi
		Assert	vmBlock		ax, bx
		clc
done:
		.leave
		ret
error:
		stc
		jmp	done
		
IUGetAttributeArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUUnlockBlockAndUpdateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine will unlock our dirty our VMBlock, unlock
		it, and then update our VM file.

CALLED BY:	(INTERNAL) IIAddAttributeToAttributeArray,
		IIInitializeDatabaseFile, IrdbAddAttributeLow,
		IrdbCreateEntryLow, IrdbDeleteEntry,
		IrdbDeleteUsingClientHandle
PASS:		bp	= mem handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUUnlockBlockAndUpdateFile	proc	near
		uses	ds,bx,ax
		.enter

		call	VMDirty
		call	VMUnlock

		call	UtilsLoadDGroupDS
		mov	bx, ds:[irdbFileHandle]
		call	VMUpdate
		
		.leave
		ret
IUUnlockBlockAndUpdateFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUFindObjectUsingClientHandleCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goes throught the object array and find the
		element with the matching client handle

CALLED BY:	ChunkArrayEnum (IrdbDeleteUsingClientHandle)
PASS:		*ds:si	= chunk array
		ds:di	= element
		cx	= client handle to find
RETURN:		carry set when handle found
		ds:ax	= chunk array element
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUFindObjectUsingClientHandleCallback	proc	far
		.enter

	;
	; See if the client handle actually matches.
	;
		cmp	cx, ds:[di].IOAE_clientHandle
		clc	
		jnz	exit
				
		mov_tr	ax, di		; offset of element
		stc
exit:
		.leave
		ret
IUFindObjectUsingClientHandleCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUDeleteObjectFromObjectArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete an object from the object array. Also deletes
		any associated attributes with it.

CALLED BY:	(INTERNAL) IrdbDeleteEntry, IrdbDeleteUsingClientHandle
PASS:		*ds:si	= Chunk array
		ds:di	= Chunk array element to delete
		bx	= File handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUDeleteObjectFromObjectArray	proc	near
		uses	ax
		.enter

	;
	; Find out where the attributes are kept.  Erase the block
	;
		mov	ax, ds:[di].IOAE_attrsBlockHandle
		tst	ax
		jz	deleteObj
		call	VMFree
	;
	; Erase the object from the chunk array
	;
deleteObj:
		call	ChunkArrayDelete

		.leave
		ret
IUDeleteObjectFromObjectArray	endp


IrdbCode	ends










