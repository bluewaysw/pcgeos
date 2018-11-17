COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Driver map -- implementation
FILE:		dmapCode.asm

AUTHOR:		Adam de Boor, Mar 30, 1994

ROUTINES:
	Name			Description
	----			-----------
    EXT DMapAlloc		Allocate & initialize a driver map

    EXT	DMapRegisterFileChange	Register a driver map for file-change
				notificaiton

    EXT DMapInit		Prepare a driver map for a new GEOS
				session.

    INT DMapMarkDirChanged	Cope with the driver directory having
				changed.

    INT DMapGetDriverDirIDs	Fetch the FilePathIDs for the directories
				that currently make up the driver
				directory, for use in handling file-change
				notification.

    INT DMapLock		Lock a DMap down and point DS to it.

    INT DMapPopDirAndUnlock	Pop the current directory stack & unlock
				the DMap

    INT DMapSearchCallback	Callback function for DMapSearchMap to find
				an entry with an appropriate token.

    INT DMapSearchMap		Search the map for a driver with the given
				token.

    INT DMapEnumFindByName	See if the current entry has the same name
				as the current file. If so, stop
				enumerating (which will cause the file to
				be rejected)

    INT DMapEnumCallback	Callback routine to make sure we're not
				finding a driver we've already seen before.

    INT DMapEnumPerformEnum	Perform the actual FileEnum to look for
				drivers we've not seen before.

    INT DMapEnumFetchToken	Open the given driver and fetch its 32-bit
				token from the dword after the
				DriverInfoStruct.

    INT DMapEnumAddDriver	Add the current DriverMapEntry to the end
				of the array

    INT DMapEnumForDriver	Look in the filesystem for a driver with a
				particular token

    INT DMapFindDriver		Locate or create an entry for the driver
				with the passed token.

    INT DMapFindDriverLow	Look for a driver entry now the map is
				locked down

    EXT DMapCheckExists		See if the system contains a driver with
				the given 32-bit token.

    EXT DMapLoad		Load the driver with the given 32-bit
				token.

    INT DMapLoadCallCallback	Call the passed callback, if it's for the
				driver just loaded

    EXT DMapGetAttributes	Retrieve the attributes word for the given
				driver. The attributes follow immediately
				the 32-bit token in the driver's
				DriverTable

    EXT DMapGetDriverHandle	Retrive the handle of a driver that is
				already loaded

    EXT DMapUnload		Unloads a driver

    EXT DMapGetAllTokens	Retrieve the tokens of all known drivers in
				the passed map. If DMF_DRIVER_DIR_CHANGED,
				then driver directory is	 rescanned
				for new transports.

    INT DMapGetAllTokensCallback 
				Callback function to fetch all the tokens
				stored in a driver map.

    EXT DMapRegisterLoadCallback 
				Register a callback routine for when the
				driver for the indicated token next gets
				loaded.

    EXT DMapFileChange		Take note of a change in the filesystem to
				see if we should update the
				DMF_DRIVER_DIR_CHANGED flag

    INT DMapMarkChangedIfIDMatches 
				Something's changed in the filesystem that
				could mean a new driver is available for
				the map. See if the disk & id in the
				notification corresponds to one of the
				FilePathIDs for the driver directory. If it
				does, then flag the directory as having
				changed.

    INT DMapStandardPathAdded	Note that another standard path has been
				added, which might (if the affected path is
				an ancestor of the driver directory) mean
				there are more drivers.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/30/94		Initial revision


DESCRIPTION:
	Implementation of the DMap abstraction
		

	$Id: dmapCode.asm,v 1.1 97/04/05 01:19:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate & initialize a driver map

CALLED BY:	(EXTERNAL)
PASS:		ds:si	= pointer to GeodeToken to match
		es:di	= subdirectory of SP_SYSTEM in which to look
		ax	= major protocol number expected from drivers
		bx	= minor protocol number expected
		cx	= entry number of routine to call when driver
			  added to the map
		dl	= DMapFlags
RETURN:		ax	= map handle for subsequent calls
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapAlloc	proc	near
tokenPtr	local	fptr.GeodeToken	push ds, si
subdir		local	fptr.char	push es, di
proto		local	ProtocolNumber	push bx, ax
initFunc	local	word		push cx
result		local	word
		uses	cx, si, di, ds, es
		.enter
	;
	; Error-check the parameters.
	; 
EC <		cmp	cx, DMAP_NO_INIT_ROUTINE			>
EC <		je	initRoutineOk					>
EC <		mov	ax, cx						>
EC <		mov	bx, handle 0					>
EC <		call	ProcGetLibraryEntry	; let this ec the thing	>
EC <initRoutineOk:							>
		Assert	fptr, dssi
		Assert	fptr, esdi
		Assert	record, dl, DMapFlags
	;
	; Allocate a block in the admin file for the beast.
	; 
		call	MailboxGetAdminFile		; bx <- file
	;
	; Compute the size (*not* the length) of the path below SP_SYSTEM, so
	; we know how big to make the map's header.
	; 
		LocalStrSize	includeNull	; cx <- # bytes in es:di
		add	cx, size DriverMapHeader; cx <- # bytes of header
						;  (includes LMemBlockHeader)
		mov	ax, LMEM_TYPE_GENERAL
		call	VMAllocLMem
		mov	ss:[result], ax
	;
	; Now gain exclusive access to the block.
	; 
		push	bp
		call	VMLock
		pop	bp
		mov	es, ax			; for upcoming movsbs
	;
	; Copy the path below SP_SYSTEM to the end of the header while we've got
	; the total header size in CX still.
	; 
	; XXX: Should we parse this down to a std path and store the SP + path?
	; It would be more general, and take care if we ever make these things
	; std paths in their own right...
	; 
		sub	cx, size DriverMapHeader; cx <- # bytes in path
		lds	si, ss:[subdir]
		mov	di, offset DMH_sysPath
		rep	movsb
	;
	; Shift the protocol number into the header.
	; 
		movdw	es:[DMH_protocol], ss:[proto], ax
	;
	; Copy the GeodeToken there as well.
	; 
		lds	si, ss:[tokenPtr]
		mov	di, offset DMH_token
		mov	cx, size GeodeToken
		rep	movsb
	;
	; Store the init routine in the header
	; 
		mov	ax, ss:[initFunc]
		mov	es:[DMH_init], ax
	;
	; Create an array for DriverMapEntry structures.
	; 
		segmov	ds, es
EC <		segmov	es, cs			; so it's not pointing to map>
EC <						;  in case it moves during>
EC <						;  DMapMarkDirChanged	>
		push	bx
		mov	bx, size DriverMapEntry
		clr	si, cx			; allocate chunk, please and
						;  use default header
		call	ChunkArrayCreate
		
EC <		cmp	si, ds:[LMBH_offset]				>
EC <		ERROR_NE	DMAP_ALLOCATED_ARRAY_NOT_FIRST_CHUNK	>
	;
	; Create an array for DriverMapCallback structures.
	; 
		mov	bx, size DriverMapCallback
		clr	si, cx
		call	ChunkArrayCreate
		pop	bx
		mov	ds:[DMH_callbacks], si
	;
	; Initialize the flags.
	; 
		mov	ds:[DMH_flags], dl
	;
	; Initialize DMH_fcnIDs -- the actual ids will be gotten when
	; DMapInit is called, later.
	; 
		mov	ds:[DMH_fcnIDs], 0
	;
	; No error messages known for any driver yet.
	;
		mov	ds:[DMH_errMsgs], 0

	;
	; Set the user ID properly (primarily for EC).
	; 
		mov	ax, ss:[result]		; ax <- map handle
		mov	cx, MBVMID_DRIVER_MAP
		call	VMModifyUserID
	;
	; Perform initial scan, if necessary, else mark as scan needed.
	;
		call	DMapMarkDirChanged
	;
	; Array is now initialized.
	; 
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS

		.leave
		ret
DMapAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapRegisterFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a driver map for file-change notification.

CALLED BY:	(EXTERNAL) AdminInit
PASS:		ax	= map handle
RETURN:		nothing
DESTROYED:	cx, dx
SIDE EFFECTS:	map is registered for file-change notification

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	4/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapRegisterFileChange	proc	near

	;
	; Register a callback function for file-change notification
	; (callback isn't saved to state, so we have to register at the
	; start of each session, and we can use a vseg...)
	; 
	mov	cx, vseg DMapFileChange
	mov	dx, offset DMapFileChange
	call	UtilRegisterFileChangeCallback

	ret
DMapRegisterFileChange	endp

Init		ends

DMap		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare a driver map for a new GEOS session.

CALLED BY:	(EXTERNAL)
PASS:		ax	= map handle
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapInit 	proc	far
		uses	ds, si, cx, dx
		.enter
	;
	; Lock down the map so we can play.
	; 
		call	DMapLock
	;
	; Fix the chunk array of DriverMapEntry's and the chunk array of
	; DriverMapCallback.
	;
		call	UtilFixChunkArrayFar
		mov_tr	ax, si
		mov	si, ds:[DMH_callbacks]
		call	UtilFixChunkArrayFar
		mov_tr	si, ax
	;
	; Mark all existing drivers not loaded.
	;
		call	DMapMarkDriversNotLoaded
	;
	; Force a scan on next search for unknown token, as who knows what
	; happened to the directory while we were gone.
	; 
		call	DMapMarkDirChanged
	;
	; Fetch the FilePathIDs for the driver dir.
	; 
		call	DMapGetDriverDirIDs

	;
	; Release the map.
	;
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
		.leave
		ret
DMapInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapMarkDriversNotLoaded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark that no existing drivers are loaded.

CALLED BY:	(INTERNAL) DMapInit
PASS:		*ds:si	= driver map
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	block is NOT marked dirty even though things are changed.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapMarkDriversNotLoaded	proc	near
	uses	bx,di
	.enter

	mov	bx, cs
	mov	di, offset DMapMarkDriversNotLoadedCB
	call	ChunkArrayEnum

	.leave
	ret
DMapMarkDriversNotLoaded	endp

DMapMarkDriversNotLoadedCB	proc	far
	and	ds:[di].DME_handle, 0	; 4 bytes (shorter than clr), also
					;  clears CF
	ret
DMapMarkDriversNotLoadedCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapMarkDirChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cope with the driver directory having changed.

CALLED BY:	(INTERNAL) DMapInit, 
			   DMapMarkChangedIfIDMatches,
			   DMapStandardPathAdded
PASS:		ds	= dmap segment
RETURN:		ds	= fixed up (NOT marked dirty -- assume caller will
			  in a moment)
DESTROYED:	nothing
SIDE EFFECTS:	either DMF_DRIVER_DIR_CHANGED is set in DMH_flags or,
     			if DMF_AUTO_DETECT, driver directory will
			be scanned and drivers possibly added

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapMarkDirChanged proc	far
		uses	cx, dx, si, ax, bx
		.enter
		ornf	ds:[DMH_flags], mask DMF_DRIVER_DIR_CHANGED
		test	ds:[DMH_flags], mask DMF_AUTO_DETECT
		jnz	processDir
done:
		.leave
		ret

processDir:
	;
	; Search for an impossible token (Geoworks manufacturer ID + -1 for the
	; ID number)
	; 
		clr	cx
		mov	dx, -1
		mov	si, ds:[LMBH_offset]
		call	DMapFindDriverLow
		call	FilePopDir
		jmp	done
DMapMarkDirChanged endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapGetDriverDirIDs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the FilePathIDs for the directories that currently
		make up the driver directory, for use in handling
		file-change notification.

CALLED BY:	(INTERNAL) DMapInit
PASS:		ds	= locked driver map
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	existing ds:[DMH_fcnIDs] is freed and replaced by a new one,
     			if possible (set to 0 if driver dir doesn't exist)
		block is *not* marked dirty

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapGetDriverDirIDs proc	near
		uses	bx, dx
		.enter
	;
	; Nuke old array, if present, leaving header field 0.
	; 
		clr	ax
		xchg	ds:[DMH_fcnIDs], ax
		tst	ax
		jz	getIDs
		call	LMemFree
getIDs:
	;
	; Change to driver directory.
	; 
		call	FilePushDir
		mov	bx, SP_SYSTEM
		mov	dx, offset DMH_sysPath
		call	FileSetCurrentPath
		jc	popDirDone
	;
	; Go fetch all the id's for the directory.
	; 
		call	FileGetCurrentPathIDs
		jc	popDirDone
		mov	ds:[DMH_fcnIDs], ax
popDirDone:
		call	FilePopDir
		.leave
		ret
DMapGetDriverDirIDs endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a DMap down and point DS to it.

CALLED BY:	(INTERNAL)
PASS:		ax	= driver map handle
RETURN:		*ds:si	= locked map
DESTROYED:	nothing
SIDE EFFECTS:	map is locked for exclusive access

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapLock	proc	near
		uses	bp, ax, bx
		.enter
		call	MailboxGetAdminFile

EC <		call	ECVMCheckVMFile					>
EC <		push	ax, cx, di					>
EC <		call	VMInfo						>
EC <		ERROR_C	INVALID_DMAP_HANDLE				>
EC <		cmp	di, MBVMID_DRIVER_MAP				>
EC <		ERROR_NE INVALID_DMAP_HANDLE				>
EC <		pop	ax, cx, di					>

		call	VMLock
		mov	ds, ax
		mov	si, ds:[LMBH_offset]
EC <		call	ECLMemValidateHeap				>
EC <		call	ECLMemValidateHandle				>
		.leave
		ret
DMapLock	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapPopDirAndUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pop the current directory stack & unlock the DMap

CALLED BY:	(INTERNAL) DMapCheckExists, DMapLoad, DMapGetAttributes
PASS:		ds	= locked DMap
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapPopDirAndUnlock proc	near
		call	FilePopDir
		call	UtilVMUnlockDS
		ret
DMapPopDirAndUnlock endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapSearchCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for DMapSearchMap to find an entry
		with an appropriate token.

CALLED BY:	(INTERNAL) DMapSearchMap via ChunkArrayEnum
PASS:		ds:di	= DriverMapEntry
		ax	= index of current element
		cxdx	= token being sought
RETURN:		carry set if element found (stop enum):
			ax	= index of current element
		carry clear if element not found (keep going):
			ax	= index of next element
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapSearchCallback proc	far
		.enter
	;
	; See if the token sought matches the entry.
	; 
		cmpdw	ds:[di].DME_token, cxdx
		stc			; assume yes, so stop enum & leave
					;  elt counter alone
		je	done

		inc	ax		; not it, so advance elt counter for
		clc			;  next callback and keep enumerating
done:
		.leave
		ret
DMapSearchCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapSearchMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search the map for a driver with the given token.

CALLED BY:	(INTERNAL) DMapFindDriver
PASS:		*ds:si	= map ChunkArray
		cxdx	= token for which we seek
RETURN:		carry set if no entry for the token
			ax	= destroyed
		carry clear if found entry:
			ds:si	= DriverMapEntry
			ax	= element #
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapSearchMap	proc	near
		uses	bx, di
		.enter
		clr	ax		; start elt counter at 0
		mov	bx, cs
		mov	di, offset cs:DMapSearchCallback
		call	ChunkArrayEnum
		cmc			; get CF set if found, but want t'other
		jc	done
	;
	; Deref the element, since we found it.
	; 
		call	ChunkArrayElementToPtr
		mov	si, di
done:
		.leave
		ret
DMapSearchMap	endp

DMapEnumParams	struct
    DMEP_common		FileEnumParams
    DMEP_matchAttrs	FileExtAttrDesc	2 dup(<>)
    DMEP_returnAttrs	FileExtAttrDesc	2 dup(<>)
DMapEnumParams	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapEnumFindByName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the current entry has the same name as the current
		file. If so, stop enumerating (which will cause the file
		to be rejected)

CALLED BY:	(INTERNAL) DMapEnumCallback via ChunkArrayEnum
PASS:		ds:di	= DriverMapEntry
		es:dx	= name of current file
RETURN:		carry set on match (stop enumerating)
DESTROYED:	si, di, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapEnumFindByName proc	far
		.enter
		lea	si, ds:[di].DME_name
		mov	di, dx
compareLoop:
DBCS <		lodsw							>
DBCS <		scasw							>
SBCS <		lodsb							>
SBCS <		scasb							>
		clc			; assume no match
		jne	done
DBCS <		tst	ax						>
SBCS <		tst	al						>
		jnz	compareLoop
		stc
done:
		.leave
		ret
DMapEnumFindByName endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to make sure we're not finding a driver
		we've already seen before.

CALLED BY:	(INTERNAL) DMapEnumPerformEnum via FileEnum
PASS:		ds	= FileEnumCallbackData
		bp	= inherited stack frame
RETURN:		carry set to reject the file
		carry clear to accept the file
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapEnumCallback proc	far	params:DMapEnumParams
		uses	ax, ds, bx, di, es, cx
		.enter	inherit far
		
		mov	ax, FEA_NAME
		mov	si, offset FECD_attrs
		call	FileEnumLocateAttr
EC <		ERROR_C	NAME_ATTRIBUTE_NOT_GIVEN_TO_ENUM_CALLBACK	>
EC <		tst	es:[di].FEAD_value.segment			>
EC <		ERROR_Z	FILE_HAS_NO_NAME_ATTRIBUTE			>

		les	dx, es:[di].FEAD_value
		
		mov	bx, cs
		mov	di, offset cs:DMapEnumFindByName
		lds	si, ss:[params].DMEP_common.FEP_cbData1
		call	ChunkArrayEnum		; carry <- set on match
						;	   => reject
		.leave
		ret
DMapEnumCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapEnumPerformEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the actual FileEnum to look for drivers we've not
		seen before.

CALLED BY:	(INTERNAL) DMapEnumForDriver
PASS:		*ds:si	= map
RETURN:		carry set if error or no new drivers found:
			bx, ax	= destroyed
		carry clear if found at least one new driver:
			bx	= handle of block holding DriverMapEntry
				  structures
			ax	= # drivers found
DESTROYED:	nothing
SIDE EFFECTS:	Current thread left pushed to the directory holding the
     			drivers.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapEnumPerformEnum proc	near
		uses	cx, dx, bp
		.enter
	;
	; If the directory hasn't changed since the last complete enum,
	; don't bother.
	; 
		test	ds:[DMH_flags], mask DMF_DRIVER_DIR_CHANGED
		jz	noneFound
	;
	; Make room for the massive numbers of parameters for FileEnum, plus
	; our own additions.
	; 
		sub	sp, size DMapEnumParams
		mov	bp, sp
	;
	; Looking for GEOS executables only, and we're using a callback routine.
	; 
		mov	ss:[bp].DMEP_common.FEP_searchFlags, 
				mask FESF_GEOS_EXECS or mask FESF_CALLBACK
	;
	; Special return attributes, to place the FEA_NAME in the right place
	; in the DriverMapEntry.
	; 
		lea	ax, ss:[bp].DMEP_returnAttrs
		mov	ss:[bp].DMEP_common.FEP_returnAttrs.offset, ax
		mov	ss:[bp].DMEP_common.FEP_returnAttrs.segment, ss

		mov	ss:[bp].DMEP_returnAttrs[0].FEAD_attr, FEA_NAME
		mov	ss:[bp].DMEP_returnAttrs[0].FEAD_value.offset, \
				offset DME_name
		mov	ss:[bp].DMEP_returnAttrs[0].FEAD_size, size DME_name
		mov	ss:[bp].DMEP_returnAttrs[1*FileExtAttrDesc].FEAD_attr,\
				FEA_END_OF_LIST
	;
	; Each returned structure is a DriverMapEntry, please.
	; 
		mov	ss:[bp].DMEP_common.FEP_returnSize,
				size DriverMapEntry
	;
	; Make sure the thing's got the right token (as stored in the map's
	; header). First point to the attribute array, then initialize said
	; array.
	; 
		lea	ax, ss:[bp].DMEP_matchAttrs
		mov	ss:[bp].DMEP_common.FEP_matchAttrs.offset, ax
		mov	ss:[bp].DMEP_common.FEP_matchAttrs.segment, ss
		
		mov	ss:[bp].DMEP_matchAttrs[0].FEAD_attr, FEA_TOKEN
		mov	ss:[bp].DMEP_matchAttrs[0].FEAD_value.offset, 
				offset DMH_token
		mov	ss:[bp].DMEP_matchAttrs[0].FEAD_value.segment, ds
		mov	ss:[bp].DMEP_matchAttrs[0].FEAD_size, size GeodeToken

		mov	ss:[bp].DMEP_matchAttrs[1*FileExtAttrDesc].FEAD_attr,
				FEA_END_OF_LIST
	;
	; Give us everything you can, please (never know where the driver might
	; be, you know...)
	; 
		mov	ss:[bp].DMEP_common.FEP_bufSize, FE_BUFSIZE_UNLIMITED
	;
	; Don't skip nuthin'
	; 
		mov	ss:[bp].DMEP_common.FEP_skipCount, 0
	;
	; Set up the callback, but we need no extra attributes. Pass the map's
	; location in cbData1
	; 
		mov	ss:[bp].DMEP_common.FEP_callback.offset,
				offset cs:DMapEnumCallback
		mov	ss:[bp].DMEP_common.FEP_callback.segment, SEGMENT_CS
		mov	ss:[bp].DMEP_common.FEP_callbackAttrs.segment, 0
		movdw	ss:[bp].DMEP_common.FEP_cbData1, dssi
	;
	; Endlich! Call the silly routine.
	; 
		call	FileEnum
	;
	; Clear off our additional stuff w/o messing with the carry.
	; 
		lea	sp, ss:[bp+size DMapEnumParams]
	;
	; Return carry set on error or no drivers found.
	; 
		jc	done
		mov_tr	ax, cx		; return # drivers in ax
		tst_clc	ax
		jnz	done
noneFound:
		stc
done:
		.leave
		ret
DMapEnumPerformEnum endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapEnumFetchToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the given driver and fetch its 32-bit token from the
		dword after the DriverInfoStruct.

CALLED BY:	(INTERNAL) DMapEnumForDriver
PASS:		es:di	= DriverMapEntry
		ds:0 - DriverMapHeader
		current dir = driver dir
RETURN:		carry set if couldn't get token
		carry clear if got token:
			es:di.DME_token	= set
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapEnumFetchToken proc	near
		uses	ax, bx, ds, dx, cx
		.enter
	;
	; First we need to open the driver file. Open it read-only and
	; deny-write, just in case...
	;
		push	ds
		segmov	ds, es
		lea	dx, ds:[di].DME_name
		mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
		call	FileOpen
		pop	ds
		jc	done

	;
	; On XIP systems, there will be a little stub file in the GFS so the
	; transport drivers show up via FileEnum, but the actual geode lives
	; in the XIP image. If we only find a stub file, then load and
	; unload the geode from the XIP image.
	;

		mov_tr	bx, ax		; bx <- file handle
		call	FileSize
		tst	dx
		jnz	notStub
		cmp	ax, size GeosFileHeader
		jbe	loadFromXIP
		
notStub:
	;
	; Seek to the part of the header where the resource id & offset of
	; the driver's DriverTable is stored.
	; 
		movdw	cxdx, <(offset GFH_coreBlock.GH_driverTab)>
		mov	al, FILE_POS_START
		call	FilePos
	;
	; Now read in that dword.
	; 
		call	readCXDX	; cx <- resid, dx <- offset
		jc	closeDone	; => bogus
	;
	; Seek the file to the dword following the DriverInfoStruct, which is
	; where the 32-bit token for the driver is stored.
	; 
		add	dx, size DriverInfoStruct
		call	GeodeFindResource
	;
	; Read in the token & the "attributes" for the driver.
	; 
		segmov	ds, es
		lea	dx, ds:[di].DME_token
		mov	cx, size DME_token + size DME_attrs
		clr	al
		call	FileRead
closeDone:
		pushf			; save error flag
		clr	al		; allow errs on close...(as if...)
		call	FileClose
		popf
done:
		.leave
		ret
loadFromXIP:

	;
	; Load the driver from the XIP image, copy the data from after the
	; DriverInfoStruct record, then unload the geode...
	;

		push	bx, si, ds, di
		mov	ax, ds:[DMH_protocol].PN_major
		mov	bx, ds:[DMH_protocol].PN_minor
		segmov	ds, es
		lea	si, ds:[di].DME_name
		call	GeodeUseDriver
		WARNING_C COULD_NOT_LOAD_DRIVER_FROM_XIP_IMAGE		
		jc	couldNotLoad
		
		call	GeodeInfoDriver	;DS:SI <- ptr to DriverInfoStruct
		add	si, size DriverInfoStruct
		mov	cx, size DME_token + size DME_attrs
.assert offset DME_token eq 0
		rep	movsb
		call	GeodeFreeDriver
		clc
couldNotLoad:
		pop	bx, si, ds, di
		jmp	closeDone

	;--------------------
	; Read the four bytes at the current seek position into CXDX (high
	; word into CX, low word into DX)
	;
	; Pass:		bx	= file handle
	; Return:	ds	= ss
	; 		carry set on error:
	; 			ax	= FileError
	; 		carry clear if ok:
	; 			cxdx	= dword read
	; 			ax	= destroyed
readCXDX:
		mov	cx, size fptr	; cx <- # bytes to read
		sub	sp, cx
		segmov	ds, ss
		mov	dx, sp		; ds:dx <- buffer
		clr	al		; return errs, please
		call	FileRead
		popdw	cxdx		; cx <- resid, dx <- offset
		retn
DMapEnumFetchToken endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapEnumAddDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the current DriverMapEntry to the end of the array

CALLED BY:	(INTERNAL) DMapEnumForDriver
PASS:		*ds:si	= map array
		es:di	= entry to add
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapEnumAddDriver proc	near
		uses	ax, cx, si, di, es
		.enter
	;
	; Add an entry to the array. Might cause the block to move, of course.
	; 
		push	es, di
		call	ChunkArrayAppend	; ds:di <- new entry
	;
	; Move dem bytes...
	; 
		segmov	es, ds			; es:di <- dest for move
		pop	ds, si			; ds:si <- src for move
		mov	cx, size DriverMapEntry	; cx <- # bytes
		rep	movsb

		segmov	ds, es			; ds <- DMap block again
	;
	; Call init routine, if one exists.
	; 
		mov	ax, ds:[DMH_init]
	CheckHack <DMAP_NO_INIT_ROUTINE eq -1>
		inc	ax
		je	done
	;
	; Load registers:
	; 	ds:si <- driver name (in current dir)
	; 	cxdx <- driver token.
	; 
		dec	ax
		push	ds:[LMBH_handle]
		push	dx, bx
		lea	si, ds:[di-size DriverMapEntry].DME_name
		movdw	cxdx, <ds:[di-size DriverMapEntry].DME_token>
		mov	bx, handle 0
		call	ProcGetLibraryEntry	; bx:ax <- vfptr of routine
		pushdw	bxax			; put routine on stack for call
		mov	bx, ds:[LMBH_handle]
		call	VMMemBlockToVMBlock	; ax <- VM block of map
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		pop	dx, bx
		call	MemDerefStackDS
done:
		.leave
		ret
DMapEnumAddDriver endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapEnumForDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look in the filesystem for a driver with a particular token

CALLED BY:	(INTERNAL) DMapFindDriver
PASS:		*ds:si	= map array
		cxdx	= token being sought
		current dir = driver dir
RETURN:		carry set if driver not found
			ax	= destroyed
		carry clear if driver found:
			ds:si	= DriverMapEntry
			ax	= element #
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		enumerate all drivers, using a callback to screen the ones
			we've seen. results are DriverMapEntry structs
		for each new driver:
			open it
			find its DriverTable
			read its token
			close it
			store the token in the entry
			if token matches, break out
		store new entries we opened on the way to finding the one
			we want at the end of the array. the rest get discarded
			(we're assuming here that the stuff to read the token
			is more expensive than the enumeration, so it's best
			to stop once we find the driver, discarding the enum
			results, rather than spending the time to get the
			tokens for the remaining drivers)
		if new one found, return ds:si pointing to it

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapEnumForDriver proc	near
		uses	bp, di, bx, es
		.enter
	;
	; Find all the driver's we've not seen yet.
	; 
		call	DMapEnumPerformEnum
		jc	done		; => nothing new, so token not
					;  viable
		
	;
	; Now loop through the drivers found.
	; 
		push	ax
		call	MemLock
		mov	es, ax
		pop	ax
		clr	di		; es:di <- current DriverMapEntry
		xchg	ax, cx		; cx <- # drivers, ax <- token.high
driverLoop:
	;
	; Fetch the token from the current driver.
	; 
		call	DMapEnumFetchToken
		jc	nextDriver	; => couldn't get token, so ignore
					;  the driver (wouldn't be able to
					;  load it anyway, if we can't open
					;  the darn thing...)
	;
	; DriverMapEntry now complete -- append it to the array.
	; 
		clr	es:[di].DME_handle	; driver not loaded yet
		call	DMapEnumAddDriver
	;
	; See if the token matches the one for which we seek.
	; 
		cmpdw	axdx, es:[di].DME_token
		jne	nextDriver
	;
	; It does. Point ds:si to the last entry in the array (which we just
	; added). (es:di, you'll recall, points to the entry returned by
	; FileEnum, which isn't useful to our caller.)
	; 
		call	ChunkArrayGetCount
		dec	cx		; cx <- index of last elt
		xchg	ax, cx		; ax <- elt #, cx <- token.high
		call	ChunkArrayElementToPtr	; ds:di <- elt
		mov	si, di		; return it in ds:si, please
		xchg	ax, cx		; ax <- token.high, cx <- elt #
		clc			; return success
		jmp	doneLoop	; go free the enum block

nextDriver:
	;
	; That wasn't the trick. Advance to the next driver we found.
	; 
		add	di, size DriverMapEntry
		loop	driverLoop
	;
	; No driver matched, so return an error after indicating we've
	; gone through the entire directory.
	; 
		andnf	ds:[DMH_flags], not mask DMF_DRIVER_DIR_CHANGED
		stc
doneLoop:
	;
	; Free the FileEnum result block.
	; 
		pushf
		call	MemFree
		call	UtilVMDirtyDS
		popf

		xchg	cx, ax		; restore token.high, and possibly
					;  return elt # (only if added)
done:		
		.leave
		ret
DMapEnumForDriver endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapFindDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate or create an entry for the driver with the passed
		token.

CALLED BY:	(INTERNAL) DMapCheckExists, DMapLoad
PASS:		cxdx	= token for driver
		ax	= map handle
RETURN:		ds	= DMap block
		current directory pushed to that containing the drivers
		carry set if couldn't find entry
			ax	= destroyed
		carry clear if found it:
			ds:si	= DriverMapEntry
			ax	= entry #
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapFindDriver	proc	near
		.enter
	;
	; Lock the data block for shared access, on the assumption we've
	; already seen the token.
	; 
		call	DMapLock		; *ds:si <- map
		
		call	DMapFindDriverLow
		.leave
		ret
DMapFindDriver	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapFindDriverLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a driver entry now the map is locked down

CALLED BY:	(INTERNAL) DMapFindDriver, DMapMarkDirChanged
PASS:		*ds:si	= map array
		cxdx	= token to look for
RETURN:		current directory pushed to that containing the drivers
		carry set if couldn't find entry
			ax	= destroyed
		carry clear if found it:
			ds:si	= DriverMapEntry
			ax	= entry #
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		This function always pushes to the directory because it is
		most often used when loading a driver, or when looking for
		new drivers that have just been added to the system by adding
		a standard path. In both cases we'll need to be in the
		directory shortly after the call (when loading) or during
		the course of the call (when enumerating), so work isn't wasted
		most of the time.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapFindDriverLow proc	near
		.enter
	;
	; Push to the driver directory.
	;
		push	dx 
		call	FilePushDir
		mov	dx, offset DMH_sysPath
		mov	bx, SP_SYSTEM
		call	FileSetCurrentPath
		pop	dx			; token
		jc	done

		call	DMapSearchMap
		jnc	done
	;
	; Still not there. Go look for the driver & add an entry for it.
	; 
		call	DMapEnumForDriver
done:
		.leave
		ret
DMapFindDriverLow endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapCheckExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the system contains a driver with the given 32-bit
		token.

CALLED BY:	(EXTERNAL)
PASS:		cxdx	= 32-bit token for which to search
		ax	= handle of driver map
RETURN:		carry set if driver exists
		carry clear if driver does not exist
DESTROYED:	ax
SIDE EFFECTS:	DMap block may move if the driver has to be searched for
     			and added to the map.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapCheckExists	proc	far
		uses	ds, si, bx
		.enter
	;
	; Just use the common utility routine to locate the entry in the
	; array or find the driver itself...
	; 
		call	DMapFindDriver		; carry, ds:si <- result
		cmc				; want carry set if driver
						;  found
	;
	; Release the exclusive lock on the data block.
	; 
		call	DMapPopDirAndUnlock
		.leave
		ret
DMapCheckExists	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapLoad
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the driver with the given 32-bit token.

CALLED BY:	(EXTERNAL) MailboxLoadTransportDriver, 
			MailboxLoadDataDriver
PASS:		cxdx	= 32-bit token for driver
		ax	= handle of driver map
RETURN:		carry set if couldn't load:
			ax	= GeodeLoadError
			bx	= destroyed
		carry clear if driver loaded:
			bx	= driver handle
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	DMap block may move if the driver has to be searched for
     			and added to the map.


PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapLoad	proc	far
		uses	ds, si, dx, di
		.enter
	;
	; Find or create the entry for the driver in the map.
	; 
		call	DMapFindDriver
		jnc	haveDriver
		mov	ax, GLE_FILE_NOT_FOUND	; assume not there & couldn't
						;  be found
		jmp	done
haveDriver:
	;
	; Have an entry, and we're in the driver directory, so try and load the
	; thing.
	; 
		add	si, offset DME_name	; ds:si <- filename
		mov_tr	dx, ax
tryAgain:
		push	dx
		mov	ax, ds:[DMH_protocol].PN_major
		mov	bx, ds:[DMH_protocol].PN_minor
		call	GeodeUseDriver
		pop	dx			; dx <- entry #
		jc	checkErrMsg
	;
	; See if we need to store the handle.  (We don't need to if the drive
	; has been load earlier.)  If not, we avoid marking the block dirty.
	;
		cmp	ds:[si - offset DME_name].DME_handle, bx
		je	stored
		mov	ds:[si - offset DME_name].DME_handle, bx
		call	UtilVMDirtyDS
stored:
	;
	; Driver loaded. Call any load-callbacks registered for the driver.
	; 
		test	ds:[DMH_flags], mask DMF_HAVE_CALLBACK
		jz	done
		push	bx, cx
		lea	dx, ds:[si-offset DME_name]
		mov	cx, bx
		mov	bx, cs
		mov	di, offset DMapLoadCallCallback
		mov	si, ds:[DMH_callbacks]
		call	ChunkArrayEnum	; block marked dirty if some cb deleted
	;
	; Clear the DMF_HAVE_CALLBACK flag if no more callbacks.
	; 
		call	ChunkArrayGetCount
		tst	cx
		jnz	callbacksLeft
		andnf	ds:[DMH_flags], not mask DMF_HAVE_CALLBACK
					; no need to mark block dirty because
					;  DMapLoadCallCallback has done so.
callbacksLeft:
		pop	bx, cx
done:
		call	DMapPopDirAndUnlock
		.leave
		ret

checkErrMsg:
		cmp	ax, GLE_FILE_NOT_FOUND
		stc
		jne	done

		call	DMapUseCustomError
		jc	done
		jmp	tryAgain
		
DMapLoad	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapUseCustomError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a dialog with the custom error string for the driver,
		if there is one.

CALLED BY:	(INTERNAL) DMapLoad
PASS:		dx	= entry # of driver that we attempted to load
		ds	= dmap block
RETURN:		carry set if no custom error message or user doesn't want
			us to try again.
		carry clear if should try to load the driver again
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 7/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapUseCustomError proc	near
		uses	ax, bx, cx, dx, si, di, bp
		.enter
	;
	; Look for a custom error message for this driver.
	; dx = entry #
	;
		mov	bx, offset DMH_errMsgs - offset DMEM_next
findErrMsgLoop:
		mov	bx, ds:[bx].DMEM_next
		tst	bx
		jz	noErrMsg
		mov	bx, ds:[bx]
		cmp	ds:[bx].DMEM_entry, dx
		jne	findErrMsgLoop
	;
	; Found it. Put up an affirmation error box with our amusing triggers
	; and the custom string.
	; 
		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDP_customFlags, CustomDialogBoxFlags <
			1,			; CDBF_SYSTEM_MODAL
			CDT_ERROR,		; CDBF_DIALOG_TYPE
			GIT_AFFIRMATION,	; CDBF_INTERACTION_TYPE
			0			; CDBF_DESTRUCTIVE_ACTION
		>
		lea	ax, ds:[bx].DMEM_msg
		movdw	ss:[bp].SDP_customString, dsax
		clr	ax			; no argument strings
		mov	ss:[bp].SDP_stringArg1.segment, ax
		mov	ss:[bp].SDP_stringArg2.segment, ax
		
		mov	ss:[bp].SDP_customTriggers.segment, cs
		mov	ss:[bp].SDP_customTriggers.offset, 
				offset dmapDriverLoadErrorTriggerTable

		mov	ss:[bp].SDP_helpContext.segment, cs
		mov	ss:[bp].SDP_helpContext.offset,
				offset dmapDriverLoadErrorHelpContext
		push	ds:[LMBH_handle]	; save for deref
		call	UserStandardDialog
		pop	bx
		call	MemDerefDS
	;
	; If user answered yes (Done That), tell caller to retry the load.
	; 
		cmp	ax, IC_YES
		je	done
noErrMsg:
	;
	; Anything else means don't retry -- just return the error.
	;
		stc
done:
		.leave
		ret
DMapUseCustomError endp

dmapDriverLoadErrorTriggerTable	StandardDialogResponseTriggerTable <
	length dmapDriverLoadErrorTriggers
>
dmapDriverLoadErrorTriggers	StandardDialogResponseTriggerEntry <
	uiDoneThatMoniker, IC_YES
>, <
   	uiGiveItUpMoniker, IC_NO
>

dmapDriverLoadErrorHelpContext	char	'dbDriverLoadErr', 0



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapLoadCallCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the passed callback, if it's for the driver just loaded

CALLED BY:	(INTERNAL) DMapLoad via ChunkArrayEnum
PASS:		ds:di	= DriverMapCallback
		ds:dx	= DriverMapEntry of just-loaded driver
		cx	= handle of just-loaded driver
RETURN:		carry set to stop enumerating (always returned clear)
DESTROYED:	bx, si, di all allowed
		ax
SIDE EFFECTS:	block marked dirty if some callback is deleted.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapLoadCallCallback proc	far
		.enter
	;
	; See if the callback is for this driver.
	; 
		mov	bx, dx
		mov	ax, ds:[bx].DME_token.low
		mov	bx, ds:[bx].DME_token.high
		cmpdw	bxax, ds:[di].DMC_token
		jne	done		; no
	;
	; Fetch the vfptr for the routine to call and push it on the stack,
	; as we need to pass something in BX.
	; 
		push	si, cx, dx
		mov	bx, handle 0
		mov	ax, ds:[di].DMC_routine
		call	ProcGetLibraryEntry
		pushdw	bxax
	;
	; Load the registers and issue the callback:
	; 	bx	<- driver handle
	; 	cx	<- CX passed to DMapRegisterLoadCallback
	; 	dx	<- DX passed to DMapRegisterLoadCallback
	; 
		mov	bx, cx
		mov	cx, ds:[di].DMC_cx
		mov	dx, ds:[di].DMC_dx
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		pop	si, cx, dx
	;
	; If carry clear, delete the callback from the array.
	; 
		Assert	segment, ds	; make sure hasn't moved

		jc	done
		call	ChunkArrayDelete
		call	UtilVMDirtyDS
done:
		clc
		.leave
		ret
DMapLoadCallCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapGetAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the attributes word for the given driver. The
		attributes follow immediately the 32-bit token in the
		driver's DriverTable

CALLED BY:	(EXTERNAL)
PASS:		cxdx	= 32-bit token
		ax	= map handle
RETURN:		carry set if no such driver:
			ax	= destroyed
		carry clear if driver found:
			ax	= attributes
DESTROYED:	nothing
SIDE EFFECTS:	DMapData block may move if the driver has to be searched for
     			and added to the map.


PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 4/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapGetAttributes proc	far
		uses	ds, si, bx
		.enter
	;
	; Locate the driver, one way or another.
	; 
		call	DMapFindDriver
		jc	done
	;
	; Found it -- load up the attributes.
	; 
		mov	ax, ds:[si].DME_attrs
done:
	;
	; Release the DMapData block.
	; 
		call	DMapPopDirAndUnlock
		.leave
		ret
DMapGetAttributes endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapGetDriverHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrive the handle of a driver that is already loaded

CALLED BY:	(EXTERNAL)
PASS:		cxdx	= 32-bit token of desired driver
		ax	= map handle
RETURN:		carry set if no such driver, or driver not loaded
		carry clear if driver is loaded:
			bx	= driver handle
DESTROYED:	nothing
SIDE EFFECTS:	none.  This routine does NOT add new drivers found in the
		file system.  It only searches whatever is already in the
		driver map.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapGetDriverHandle	proc	far
	uses	ax,si,ds
	.enter

	;
	; Search the map for DriverMapEntry
	;
	call	DMapLock		; *ds:si = driver map
	call	DMapSearchMap		; ds:si = DriverMapEntry, CF
	jc	unlock
	mov	bx, ds:[si].DME_handle
	sub	bx, 1			; sets CF if bx = null	(2 bytes)
	inc	bx			; preserves CF		(1 byte)
unlock:
	call	UtilVMUnlockDS		; flags preserved

	.leave
	ret
DMapGetDriverHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapUnload
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unloads a driver

CALLED BY:	(EXTERNAL)
PASS:		cxdx	= 32-bit token of desired driver
		ax	= map handle
RETURN:		carry set if driver exited
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapUnload	proc	far
	uses	bx,si,ds,ax
	.enter

	;
	; Search the map for DriverMapEntry
	;
	call	DMapLock		; *ds:si = driver map
	call	DMapSearchMap		; ds:si = DriverMapEntry, CF
	mov	bx, ds:[si].DME_handle
EC <	call	ECCheckGeodeHandle					>
	call	GeodeFreeDriver
	jnc	done
	mov	ds:[si].DME_handle, 0	; driver was exited, so clear the
					;  field out
	call	UtilVMDirtyDS
done:
	call	UtilVMUnlockDS		; flags preserved

	.leave
	ret
DMapUnload	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapGetAllTokens
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the tokens of all known drivers in the passed map.
		If DMF_DRIVER_DIR_CHANGED, then driver directory is 
		rescanned for new transports.

CALLED BY:	(EXTERNAL)  MTAddMedium
PASS:		ds	= lmem block in which to allocate array
		ax	= map handle
RETURN:		*ds:ax	= ChunkArray of 32-bit tokens for all known drivers
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapGetAllTokens proc	far
		uses	cx, bx, di, es, si
		.enter
	;
	; Create an array for the results.
	; 
		push	ax
		mov	bx, size dword
		clr	cx, si, ax
		call	ChunkArrayCreate
		segmov	es, ds
		mov	cx, si
		pop	ax
	;
	; Lock down and enumerate the map.
	; 
		call	DMapLock	; *ds:si <- map
		mov	bx, cs
		mov	di, offset DMapGetAllTokensCallback
		call	ChunkArrayEnum
		call	UtilVMUnlockDS
	;
	; Restore DS to the (possibly moved) segment containing the array and
	; return the array chunk in AX, as promised.
	; 
		segmov	ds, es
		mov_tr	ax, cx
		.leave
		ret
DMapGetAllTokens endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapGetAllTokensCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to fetch all the tokens stored in a driver
		map.

CALLED BY:	(INTERNAL) DMapGetAllTokens via ChunkArrayEnum
PASS:		ds:di	= DriverMapEntry
		*es:cx	= result array
RETURN:		carry set to stop enumerating (carry always clear)
DESTROYED:	bx, si, di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapGetAllTokensCallback proc	far
		.enter
		mov	bx, di
		segxchg	ds, es		; es:bx <- DriverMapEntry
		mov	si, cx		; *ds:si <- result array
		call	ChunkArrayAppend; ds:di <- new element
		movdw	({dword}ds:[di]), es:[bx].DME_token, ax
		segxchg	ds, es
		clc
		.leave
		ret
DMapGetAllTokensCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapRegisterLoadCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a callback routine for when the driver for the
		indicated token next gets loaded.

CALLED BY:	(EXTERNAL)
PASS:		ax	= map handle
		bx	= entry # of routine to call
				Pass:	cx, dx	= as passed
					bx	= driver handle
				Return:	carry clear if callback may be deleted
					carry set if callback should be
						made again on next load
				Destroy:cx, dx
		cx, dx	= data for callback
		sidi	= 32-bit token of driver whose loading should trigger
			  the callback
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapRegisterLoadCallback proc	far
driver		local	dword	push si, di
		uses	ds, si, di
		.enter
	;
	; Validate the routine #
	; 
EC <		push	ax, bx						>
EC <		mov_tr	ax, bx						>
EC <		mov	bx, handle 0					>
EC <		call	ProcGetLibraryEntry				>
EC <		pop	ax, bx						>

   		call	DMapLock
	;
	; Append an entry to the callback array for the map.
	; 
		mov	si, ds:[DMH_callbacks]
		call	ChunkArrayAppend	; ds:di <- new entry
	;
	; Copy the parameters into the new entry.
	; 
		movdw	ds:[di].DMC_token, ss:[driver], ax
		mov	ds:[di].DMC_routine, bx
		mov	ds:[di].DMC_cx, cx
		mov	ds:[di].DMC_dx, dx
	;
	; Set the flag so DMapLoad knows it needs to look through the array.
	; 
		ornf	ds:[DMH_flags], mask DMF_HAVE_CALLBACK
	;
	; Release the map.
	; 
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
		.leave
		ret
DMapRegisterLoadCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of a change in the filesystem to see if we should
		update the DMF_DRIVER_DIR_CHANGED flag

CALLED BY:	(EXTERNAL)
PASS:		es:di	= FileChangeNotificationData
		dx	= FileChangeNotificationType
		ax	= map handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapFileChange	proc	far
		.enter
		cmp	dx, FCNT_CREATE
		je	checkID
		cmp	dx, FCNT_ADD_SP_DIRECTORY
		jne	done
		call	DMapStandardPathAdded
done:
		.leave
		ret
checkID:
		call	DMapMarkChangedIfIDMatches
		jmp	done
DMapFileChange 	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapMarkChangedIfIDMatches
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Something's changed in the filesystem that could mean a new
		driver is available for the map. See if the disk & id in
		the notification corresponds to one of the FilePathIDs for
		the driver directory. If it does, then flag the directory
		as having changed.

CALLED BY:	(INTERNAL) DMapFileChange
PASS:		es:di	= FileChangeNotificationData
		ax	= map handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapMarkChangedIfIDMatches proc	near
		uses	ds, si, cx, dx, ax, bx
		.enter
	;
	; Point to the array of FilePathIDs.
	; 
		call	DMapLock
		mov	si, ds:[DMH_fcnIDs]
		tst	si
		jz	done
		ChunkSizeHandle	ds, si, cx
		jcxz	done
	;
	; Set up registers for the loop:
	; ds:si <- current FilePathID to check
	; ax <- disk from notification data
	; bxdx <- ID from notification data
	; cx = # bytes in the id array
	; 
		mov	si, ds:[si]
		mov	ax, es:[di].FCND_disk
		movdw	bxdx, es:[di].FCND_id
checkLoop:
	;
	; Check the components of the FilePathID against the notification data.
	; 
		cmp	ax, ds:[si].FPID_disk
		jne	nextID
		cmpdw	bxdx, ds:[si].FPID_id
		je	found
nextID:
	;
	; Advance to the next ID, please.
	; 
		add	si, size FilePathID
		sub	cx, size FilePathID
		jnz	checkLoop
done:
		call	UtilVMUnlockDS
		.leave
		ret

found:
	;
	; The affected directory is the driver directory, so mark the thing
	; as changed.
	; 
		call	DMapMarkDirChanged
		call	UtilVMDirtyDS
		jmp	done
DMapMarkChangedIfIDMatches endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapStandardPathAdded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that another standard path has been added, which
		might (if the affected path is an ancestor of the driver
		directory) mean there are more drivers.

CALLED BY:	(INTERNAL) DMapFileChange
PASS:		es:di	= FileChangeNotificationData
		ax	= map handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapStandardPathAdded proc	near
		uses	bp, bx
		.enter
		mov	bp, es:[di].FCND_disk	; bp <- path for which component
						;  was added
	;
	; If SP_SYSTEM got a new component, the driver directory could
	; definitely have been affected.
	; 
		cmp	bp, SP_SYSTEM
		je	isAffected
	;
	; If SP_SYSTEM is a subdirectory of the affected directory, the
	; directory could have been affected.
	; 
		mov	bx, SP_SYSTEM
		push	ax
		call	FileStdPathCheckIfSubDir
		tst	ax
		pop	ax
		jz	isAffected
done:
		.leave
		ret

isAffected:
		push	ds, si
		call	DMapLock
		call	DMapMarkDirChanged
		call	DMapGetDriverDirIDs
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
		pop	ds, si
		jmp	done
DMapStandardPathAdded endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DMapStoreErrorMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store a custom error message for a driver.

CALLED BY:	(EXTERNAL)
PASS:		ax	= map block handle
		cxdx	= 32-bit token for the driver
		^lbx:si	= null-terminated error string to store
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	in the future, if the driver is loaded and cannot be found,
     			the user will be prompted with this error string

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 7/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DMapStoreErrorMsg proc	far
errMsg		local	optr.char	push bx, si
		uses	ds, si, di, ax
		.enter
		call	DMapLock
		call	DMapSearchMap	; ax <- element #
EC <		ERROR_C	CANNOT_REGISTER_ERROR_FOR_UNKNOWN_DRIVER	>
	;
	; Nuke any existing message for the driver.
	;
		mov	si, offset DMH_errMsgs - offset DMEM_next
findExistingLoop:
		mov	bx, si
		mov	si, ds:[bx].DMEM_next
		tst	si
		jz	createNew
		mov	si, ds:[si]
		cmp	ds:[si].DMEM_entry, ax
		jne	findExistingLoop
		
		push	ax
		mov	ax, ds:[si].DMEM_next
		xchg	ds:[bx].DMEM_next, ax
		call	LMemFree
		pop	ax
createNew:
	;
	; Copy the string chunk in, leaving room for our beloved header
	;
		movdw	bxsi, ss:[errMsg]
		mov	cx, size DriverMapErrMsg
		call	UtilCopyChunkWithHeader
	;
	; Store the driver's entry number
	;
		mov	di, ds:[si]
		mov	ds:[di].DMEM_entry, ax
	;
	; Link this error message as the head of the list.
	;
		mov_tr	ax, si
		xchg	ds:[DMH_errMsgs], ax
		mov	ds:[di].DMEM_next, ax
		.leave
		ret
DMapStoreErrorMsg endp


DMap		ends

