COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		Geode
FILE:		geodeLoad.asm

ROUTINES:
	Name			Description
	----			-----------
    GLB GeodeLoad               Load a Geode from the given file.  Execute
				the Geode based on its type.

    GLB GeodeLoad               Load a Geode from the given file.  Execute
				the Geode based on its type.

    GLB GeodeLoadReal           Load a Geode from the given file.  Execute
				the Geode based on its type.

    INT LoadGeodeLow            Load a Geode from the given file.  Execute
				the Geode based on its type.

    GLB LoadXIPGeode            Looks for a geode in the XIP image, and if
				it is there, loads it.

    GLB MapFileNameToCoreblockHandle 
				Given a filename, looks the file up in the
				FXIPH_geodeNames table.

    GLB LoadXIPGeodeWithHandle  Given the passed handle,

    INT LoadGeodeAfterFileOpen  Actual workhorse of loading a geode, called
				from a number of places with the .geo file
				already open.

    INT ReadGeodeHeader         Read in the header of an open Geode file
				and check to see if it is legal and if it
				matches the type and attributes asked for.

    INT GeodeEnsureEnoughHeapSpace 
				Make sure there's going to be sufficient
				space on the heap after launching this
				geode that it's worth doing so.
				TRANSPARENT_DETACH older apps if necessary,
				to try & accomodate this request.

    INT GeodeEnsureEnoughHeapSpaceCore 
				Make sure there's going to be sufficient
				space on the heap after the space is taken.
				TRAANSPARENT_DETACH older apps if
				necessary, to try & accomodate this request

    INT LookForHeapSpace        Look for additional heapspace by walking
				through the lists of detachable apps,
				adding up how much we'd get

    INT HEOS_check              Description

    INT GeodeTransparentDetach  Description

    INT GeodeThreadModify       Modifies process & UI thread priorities for
				a process geode

    INT GeodeGetRidOfTransparentlyDetachingAppsNow 
				We've been nice up to now, & let apps
				leisurely take their time detaching.  We're
				no longer going to be so nice.  In fact, we
				want them gone, NOW.  To do this, we'll go
				through the list of threads that we saved
				earlier, & up the priorities of the threads
				to very high levels, in hopes that they'll
				take over & nuke themselves, before we go
				looking for heap space.

    INT GGROFDAN_callback       Description

    EXT GeodeGetTotalHeapSpaceInUse 
				Get total of "heap space" amounts declared
				by all running applications.

    INT GGTHSIU_callBack        Callback for GeodeGetTotalHeapSpaceInUse.
				Add in "HeapSpace" amount in use for
				applications

    INT GeodeGetHeapSpaceUsedByGeode 
				Get "Heap space" requirement declared by
				application

    INT GeodeSetHeapSpaceUsedByGeode 
				Set "Heap space" requirement declared by
				application

    INT GetHeapVarsParamsCommon Set "Heap space" requirement declared by
				application

    INT TestProtocolNumbers     Compare two protocol numbers

    INT AllocateCoreBlock       Allocate the core block for a Geode and
				read core data information from the file

    INT LoadExportTable         Load the exported entry point table for a
				geode

    INT RelocateExportTable     Relocate the exported entry point table for
				a geode

    INT ProcessGeodeFile        Process a Geode file for GeodeLoad

    INT AddGeodeToList          Add a GEODE to the GEODE list

    INT ConvertIDToSegment      Convert a resource ID to a segment (or to a
				handle shifted right 4 times) in a geode's
				core block

    INT DoGeodeProcess          Do process initialization for GeodeLoad

    INT InitResources           Initialize resources for a Geode

    INT AllocateResource        Allocate a handle for a resource and read
				it in.

    INT PreLoadResources        Pre-load resources that are not shared and
				not discarded

    INT GLLoadResourcePrelude   Prepare to load a resource into memory,
				either into its own block or into another
				one.

    INT GLLoadResourceEpilude   Finish loading a resource, unlocking that
				which was locked in LoadResourcePrelude

    INT DoGeodeObjects          Do object initialization for GeodeLoad

    GLB GeodeAddReference       Artificially add another reference to the
				passed geode. Useful for geodes wanting to
				make sure they don't go away until *they*
				say so (e.g. non-process libraries loaded
				during initialization)

    GLB GeodeRequestSpace       Check if space is availible, and if so,
				submit reservation

    INT GeodeReturnSpace        Return heapspace reserved by
				HeapRequestSpace to general use

    INT GeodeAddSpace           Adds some space to the heapspace
				requirement of the geode.

    INT PheapVarBufSem          P's the heapVarBufSem semaphore - secures
				access to the heapVarBuffer (there's only
				one..) and grants single access to
				heapspace stuff (if you are totalling the
				heapspace in use, you should aquire it so
				nobody else does simulanteously).

    INT FarPheapVarBufSem       P's the heapVarBufSem semaphore - secures
				access to the heapVarBuffer (there's only
				one..) and grants single access to
				heapspace stuff (if you are totalling the
				heapspace in use, you should aquire it so
				nobody else does simulanteously).

    INT VheapVarBufSem          V's the heapVarBufSem semaphore - releases
				acces to the heapVarBuffer and general
				heapspace stuff

    INT FarVheapVarBufSem       V's the heapVarBufSem semaphore - releases
				acces to the heapVarBuffer and general
				heapspace stuff

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
	PJC	1/26/94		Added multi-language support.

DESCRIPTION:
	This file contains routines to load a Geode and execute it.

	$Id: geodesLoad.asm,v 1.1 97/04/05 01:12:17 newdeal Exp $

------------------------------------------------------------------------------@

GLoad	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeLoad

DESCRIPTION:	Load a Geode from the given file.  Execute the Geode based
		on its type.

CALLED BY:	GLOBAL

PASS:
	al - priority for new Geode (if an application)
	ah - flags:
		bits 7-0 - unused (pass 0)
	cx - attributes to match
	dx - attributes to NOT match
	di:bp - two words of information for new geode. For libraries and
		drivers, di:bp should be a far pointer to a null-terminated
		string of parameters. For processes, di is passed in cx and
		bp is passed in dx.
	ds:si - pointer to filename
		(file name *can* be in movable XIP code resource)

RETURN:
	carry - set if error
	ax - error code (GeodeLoadError)
			GLE_FILE_NOT_FOUND
			GLE_FILE_READ_ERROR
			GLE_NOT_GEOS_FILE
			GLE_NOT_GEOS_EXECUTABLE_FILE
			GLE_FILE_TYPE_MISMATCH
			GLE_ATTRIBUTE_MISMATCH
			GLE_MEMORY_ALLOCATION_ERROR
			GLE_PROTOCOL_ERROR_IMPORTER_TOO_RECENT
			GLE_PROTOCOL_ERROR_IMPORTER_TOO_OLD
			GLE_NOT_MULTI_LAUNCHABLE
			GLE_LIBRARY_PROTOCOL_ERROR
			GLE_LIBRARY_LOAD_ERROR
			GLE_DRIVER_INIT_ERROR
			GLE_LIBRARY_INIT_ERROR
	bx - handle to new Geode

DESTROYED:
	none

REGISTER/STACK USAGE:
	bp - used to reference local vars
	ds - core block for new Geode

PSEUDO CODE/STRATEGY:
	Call LoadGeodeLow to do the work

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

------------------------------------------------------------------------------@

GEODE_FILE_TABLE_SIZE	equ	GH_geoHandle
if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment

GeodeLoad	proc	far
	mov	ss:[TPD_dataBX], handle GeodeLoadReal
	mov	ss:[TPD_dataAX], offset GeodeLoadReal
	GOTO	SysCallMovableXIPWithDSSI
GeodeLoad	endp

CopyStackCodeXIP	ends

else
GeodeLoad	proc	far
	FALL_THRU	GeodeLoadReal
GeodeLoad	endp
endif


GeodeLoadReal	proc	far

if	FULL_EXECUTE_IN_PLACE

	; It isn't valid to pass far pointers in other XIP resources, so
	; complain if they are passed in.
EC <	push	cx, dx
EC <	mov	bx, ds							>
EC <	mov	dx, cs							>
EC <	cmp	bx, dx							>
EC <	je	thisResource						>
EC <	call	ECAssertValidTrueFarPointerXIP				>
EC <thisResource:							>
EC <	pop	cx, dx							>
endif

	test	cx, mask GA_APPLICATION
	jz	afterHeapClear

if	FULL_EXECUTE_IN_PLACE and LOAD_GEODES_FROM_XIP_IMAGE_UNTIL_FIRST_APP_LOADED

;	We are loading an app, so set the flag telling LoadGeodeLow to start
;	looking on the GFS now.

	push	ds
	LoadVarSeg	ds
	mov	ds:[lookForGeodesOnDisk], TRUE
	pop	ds
	
endif
if	not NEVER_ENFORCE_HEAPSPACE_LIMITS
	;
	; First, encourage everything we previously started to detach to
	; finish up their business & leave the system, by upping the
	; priorities of those threads to high levels (& lowering our own
	; briefly)
	;
	call	GeodeGetRidOfTransparentlyDetachingAppsNow
endif	; not NEVER_ENFORCE_HEAPSPACE_LIMITS
afterHeapClear:

	call	FarPGeode
	call	LoadGeodeLow
EC <	jc	done							>
EC <	push	ds, ax							>
EC <	call	MemLock							>
EC <	mov	ds, ax							>
EC <	tst	ds:[GH_geodeRefCount]					>
EC <	ERROR_Z	LOADED_GEODE_STILL_UNREFERENCED				>
EC <	call	MemUnlock						>
EC <	pop	ds, ax							>
EC <done:								>
	call	FarVGeode
	ret

GeodeLoadReal	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadGeodeLow

DESCRIPTION:	Load a Geode from the given file.  Execute the Geode based
		on its type.

CALLED BY:	INTERNAL
		GeodeLoad

PASS:
	al - priority for new Geode (if an application)
	ah - flags:
		bits 7-0 - unused (pass 0)
	cx - attributes to match
	dx - attributes to NOT match
	bp,di - information for new process
	ds:si - pointer to filename

RETURN:
	carry - set if error
	if error:
		ax - error code (GeodeLoadError)
			GLE_FILE_NOT_FOUND
			GLE_FILE_READ_ERROR
			GLE_NOT_GEOS_FILE
			GLE_NOT_GEOS_EXECUTABLE_FILE
			GLE_FILE_TYPE_MISMATCH
			GLE_ATTRIBUTE_MISMATCH
			GLE_MEMORY_ALLOCATION_ERROR
			GLE_PROTOCOL_ERROR_IMPORTER_TOO_RECENT
			GLE_PROTOCOL_ERROR_IMPORTER_TOO_OLD
			GLE_NOT_MULTI_LAUNCHABLE
			GLE_LIBRARY_PROTOCOL_ERROR
			GLE_LIBRARY_LOAD_ERROR
			GLE_DRIVER_INIT_ERROR
			GLE_LIBRARY_INIT_ERROR
	if no error:
		bx - handle to new Geode

DESTROYED:
	none

REGISTER/STACK USAGE:
	bp - used to reference local vars
	ds - core block for new Geode

PSEUDO CODE/STRATEGY:
	Allocate local scratch space, save parameters passed
	Open file name passed
	Read Geode header, check for errors
	Allocate core block for Geode and read in core data information
	Set up Geode fields: GH_geodeHandle, GH_geoHandle, GH_parentProcess
	if (Geode is a driver) -> call LoadDriverTable to load the table
	Process library table by calling LoadLibraryTable
	Load and initialize resource table (call to InitResources)
	Read in initialized data
	if (Geode is a driver) -> call InstallDriver to add the driver
	if (Geode is a library) -> initialize library
	if (Geode is a process) -> initialize process
	if (file is not to be kept open) -> close Geode file
	; add Geode to Geode list

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

------------------------------------------------------------------------------@
LoadGeodeLow	proc	near
if	FULL_EXECUTE_IN_PLACE
if 	LOAD_GEODES_FROM_XIP_IMAGE_FIRST or LOAD_GEODES_FROM_XIP_IMAGE_UNTIL_FIRST_APP_LOADED

if	LOAD_GEODES_FROM_XIP_IMAGE_FIRST
if	LOAD_GEODES_FROM_XIP_IMAGE_UNTIL_FIRST_APP_LOADED
	PrintError <Cannot set both LOAD_GEODES_FROM_XIP_IMAGE_UNTIL_FIRST_APP_LOADED and LOAD_GEODES_FROM_XIP_IMAGE_FIRST non-zero>
endif
%out Warning - cannot replace geodes in XIP image
endif

if	LOAD_GEODES_FROM_XIP_IMAGE_UNTIL_FIRST_APP_LOADED
	push	ds
	LoadVarSeg	ds
	tst	ds:[lookForGeodesOnDisk]
	pop	ds
	jnz	lookOnDiskFirst
endif

	push	ax, bx
	call	LoadXIPGeode
	jnc	inXIPImage
	cmp	ax, GLE_FILE_NOT_FOUND
	je	notInXIPImage
	stc
	mov	bx, ax		;BX <- error flag
inXIPImage:
	pop	ax, ax		;Restore stack w/o changing flags
	mov	ax, bx		;Restore AX with error (if any)
	jmp	LGL_done
notInXIPImage:
	pop	ax, bx
lookOnDiskFirst::

endif	;LOAD_GEODES_FROM_XIP_IMAGE_FIRST or
	; LOAD_GEODES_FROM_XIP_IMAGE_UNTIL_FIRST_APP_LOADED

endif	;FULL_EXECUTE_IN_PLACE
	push	ax, dx		; save priority & attrs to not match
	mov	dx, si		; ds:dx <- file name
	mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
	call	FileOpen	; ax <- file handle
	mov_tr	bx, ax
if	FULL_EXECUTE_IN_PLACE and not LOAD_GEODES_FROM_XIP_IMAGE_FIRST

;	On XIP systems, we want to make sure we aren't trying to open one
;	of those little stubs that the elyom tool produces.

	jc	noCheckSize
	call	FileSize	;DX:AX <- file size
	tst_clc	dx
	jnz	noCheckSize	;If we have a >64K file, branch

;	If the file is too small, close the file and act as if the file
;	couldn't be opened...

	cmp	ax, size GeosFileHeader+1	;Sets carry if file only
						; contains GeosFileHeader
	jnc	noCheckSize
	mov	al, FILE_NO_ERRORS
	call	FileCloseFar
	stc
noCheckSize:
endif
	pop	ax, dx
	jc	LGL_openError

	call	LoadGeodeAfterFileOpen

LGL_done label near	;*** REQUIRED BY SHOWCALL -L COMMAND IN SWAT ***
	ret

LGL_openError label near ;*** REQUIRED BY SHOWCALL -L COMMAND IN SWAT ***
if	FULL_EXECUTE_IN_PLACE and not LOAD_GEODES_FROM_XIP_IMAGE_FIRST
	call	LoadXIPGeode
else
	mov	ax, GLE_FILE_NOT_FOUND
endif

	jmp	LGL_done

LoadGeodeLow	endp

GeodeLoadFlagsAndPriority	struct
    GLFAP_priority	ThreadPriority
    GLFAP_flags		byte		; must be zero, for now
GeodeLoadFlagsAndPriority	ends

if	FULL_EXECUTE_IN_PLACE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadXIPGeode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks for a geode in the XIP image, and if it is there, 
		loads it.

CALLED BY:	GLOBAL
PASS:	al - priority for new Geode (if an application)
	ah - flags:
		bits 7-0 - unused (pass 0)
	cx - attributes to match
	dx - attributes to NOT match
	bp,di - information for new process
	ds:si - pointer to filename
RETURN:		carry set if not loaded
		ax - error code (GeodeLoadError)
			GLE_FILE_NOT_FOUND
			GLE_MEMORY_ALLOCATION_ERROR
			GLE_PROTOCOL_ERROR_IMPORTER_TOO_RECENT
			GLE_PROTOCOL_ERROR_IMPORTER_TOO_OLD
			GLE_NOT_MULTI_LAUNCHABLE
			GLE_LIBRARY_PROTOCOL_ERROR
			GLE_LIBRARY_LOAD_ERROR
			GLE_DRIVER_INIT_ERROR
			GLE_LIBRARY_INIT_ERROR
		otherwise
		bx - handle of coreblock of newly loaded geode	

DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 6/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadXIPGeode	proc	near	uses	es, di
	.enter
	call	MapFileNameToCoreblockHandle
	jc	exit
	call	LoadXIPGeodeWithHandle
exit:
	.leave
	ret
LoadXIPGeode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapFileNameToCoreblockHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a filename, looks the file up in the FXIPH_geodeNames
		table.

CALLED BY:	GLOBAL
PASS:		ds:si - ptr to filename
RETURN:		carry set if not found (ax = GLE_FILE_NOT_FOUND)
		else 	bx - handle of coreblock
			ax preserved
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapFileNameToCoreblockHandle	proc	near	uses	cx, di, es, si
DBCS <	dbcsDosNameBuffer	local	DOS_DOT_FILE_NAME_LENGTH_ZT dup(TCHAR)>
	.enter

;	Strip off the opening path

	push	ax
	mov	di, si		;DI <- ptr to character after last slash
next:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	endOfString
	LocalCmpChar	ax, C_BACKSLASH
	jne	next
	mov	di, si
	jmp	next
endOfString:
	mov	si, di		;DS:SI <- ptr to filename portion of string
	LoadVarSeg	es, bx
	mov	es, es:[loaderVars].KLV_xipHeader
	mov	bx, es:[FXIPH_numGeodeNames]	;BX <- # items in GeodeNames
						; table
	mov	di, es:[FXIPH_geodeNames]	;ES:DI <- ptr to GeodeNames
						; table

loopTop:
	; Scan through the array of GeodeNameTableEntry structures, trying
	; to match the filename passed in in DS:SI

if	DBCS_PCGEOS
	; Need to convert the SBCS GNTE_fname to DBCS for string comparison.
	pushdw	esdi

	pushdw	dssi				; save filename portion
	movdw	dssi, esdi			; ds:si <- GNTE_fname
	segmov	es, ss
	lea	di, ss:[dbcsDosNameBuffer]
	clr	ah
	charLoop:
	lodsb
	stosw
	tst	al
	jnz	charLoop
	popdw	dssi				; ds:si <- filename portion
	lea	di, ss:[dbcsDosNameBuffer]
endif	; DBCS_PCGEOS

	clr	cx	;Strings are null terminated
	call	LocalCmpStringsNoCase

if	DBCS_PCGEOS
	popdw	esdi
endif	; DBCS_PCGEOS

	jz	match

	push	di
	add	di, offset GNTE_longname
	call	LocalCmpStrings
	pop	di
	jz	match

	add	di, size GeodeNameTableEntry
	dec	bx
	jnz	loopTop

;	The geode was not in the XIP image, so whine that we couldn't find it

	add	sp, size word		;Nuke saved AX from stack
	mov	ax, GLE_FILE_NOT_FOUND
	stc
	jmp	exit
match:
	mov	bx, es:[di].GNTE_coreblock
	clc
	pop	ax
exit:
	.leave
	ret
MapFileNameToCoreblockHandle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadXIPGeodeWithHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the passed handle, 

CALLED BY:	GLOBAL
PASS:	al - priority for new Geode (if an application)
	ah - flags:
		bits 7-0 - unused (pass 0)
	bx - coreblock handle for geode
	cx - attributes to match
	dx - attributes to NOT match
	bp,di - information for new process
RETURN:		carry set if error:
			ax	= GeodeLoadError
		carry clear if ok:
			bx	= handle of new Geode

DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 6/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoadXIPGeodeWithHandle	proc	near

	;Local vars are the same as LoadGeodeAfterFileOpen
valueToPass2	local word push bp		;value passed in bp
valueToPass1	local word push di		;value passed in di
notAttributes	local word push dx		;value passed in dx
attributes	local word push cx		;value passed in cx
flagsAndPrio	local GeodeLoadFlagsAndPriority \
		push	ax
otherInstance	local hptr
temporary	local word
execHeader	local ExecutableFileHeader
fileType	local GeosFileType		;buffer for ensuring file is
						; an executable
heapSpace	local word			;Temp variable for HeapSpace
currentGeode	local hptr

	uses	cx, dx, si, di, es, ds

	ForceRef valueToPass2
	ForceRef valueToPass1
	ForceRef notAttributes
	ForceRef attributes
	ForceRef flagsAndPrio
	ForceRef otherInstance
	ForceRef temporary
	ForceRef execHeader
	ForceRef fileType
	ForceRef heapSpace			;Temp variable fo HeapSpace
	ForceRef currentGeode

	.enter

;	Allocate a block of data, read the coreblock information into it,
;	and swap the handles so the coreblock handle points to the data.

	LoadVarSeg	ds

;
; 	If the coreblock is already in memory, then the geode must be loaded,
;	so exit with a GLE_NOT_MULTI_LAUNCHABLE error (XIP geodes can't be
;	multi-launched, as there may be non-sharable blocks with hardcoded
;	handle references to the coreblock).
;
	mov	ax, GLE_NOT_MULTI_LAUNCHABLE
	tst	ds:[bx].HM_addr
	LONG jnz toErrorExit

	mov	ax, ds:[bx].HM_size		;
	mov	cl, 4
	shl	ax, cl				;AX <- byte size of coreblock

;	Allocate the coreblock handle

	push	ax
	mov	ch, mask HAF_LOCK
	call	MemReAlloc
	pop	cx				;CX <- # bytes to copy
	jc	cannotAllocCoreblock

;	Copy the data out of the XIP image

	mov	es, ax				;ES:DI <- dest for data
	mov	ds, ax				;DS <- coreblock handle
	clr	di
	call	CopyDataFromXIPImageFar

;	Ensure that the geode has the desired attributes

	mov	ax, GLE_ATTRIBUTE_MISMATCH
	mov	cx, ds:[GH_geodeAttr]
	test	cx, ss:[notAttributes]
	jnz	error
	not	cx
	test	cx, ss:[attributes]
	jnz	error

if	NEVER_ENFORCE_HEAPSPACE_LIMITS
	LoadVarSeg	es, ax
	jmp	10$
else
;	On XIP systems, the heapspace value is stored in the PH_stdFileHandles
;	area, since there is no ExecutableFileHeader available.
;
;	If this XIP geode is an application, make sure there is enough
;	heapspace available for it, and store the heapspace required in the
;	private data area.
;
	
	LoadVarSeg	es, ax
	mov	ax, ds:[GH_geodeAttr]
	test	ax, mask GA_APPLICATION
	jz	10$
	mov	cx, ds:[PH_stdFileHandles]
	push	ds			; save coreblock
	call	GeodeEnsureEnoughHeapSpace
	pop	ds			; ds <- coreblock
	jnc	setHeapspace		;Exit if not enough heapspace for this
					; app
endif	; NEVER_ENFORCE_HEAPSPACE_LIMITS

error:

	;We encountered an error, so unlock and discard the coreblock.

	mov	bx, ds:[GH_privData]
	tst	bx
	jz	noPrivData
	call	MemUnlock
noPrivData:
	mov	bx, ds:[GH_geodeHandle]
	call	MemUnlock
EC <	call	NullDS							>
	call	MemDiscard
EC <	ERROR_C	COULD_NOT_DISCARD_COREBLOCK				>
toErrorExit:
	jmp	errorExit

cannotAllocCoreblock:
	mov	ax, GLE_MEMORY_ALLOCATION_ERROR
	jmp	errorExit

memError:
	mov	ax, GLE_MEMORY_ALLOCATION_ERROR
	jmp	error

if	not NEVER_ENFORCE_HEAPSPACE_LIMITS
setHeapspace:
	tst	ax
	jz	10$
	mov	bx, ds:[GH_geodeHandle]
	call	GeodeSetHeapSpaceUsedByGeode
endif	; not NEVER_ENFORCE_HEAPSPACE_LIMITS
	
10$:

;	Now, scan through the GH_libOffset table (the table of coreblocks
;	of libraries this geode uses). Libraries that have not been loaded
; 	need to be loaded - libraries that are already loaded just have
;	references added to them (via UseLibraryLow).

	call	ProcessXIPLibraryTable
	jc	error


;
;	Initialize all the resource sizes and flags, in case they were mucked
;	with the last time the geode was loaded.
;
	call	InitGeodeHandles

if USE_PATCHES
	call	GeodePatchXIPGeode
endif		

;	If the geode has a discardable dgroup (the dgroup resource gets
;	allocated when the geode is loaded) then the dgroup resource should
;	be marked discarded

	mov	bx, ds:[GH_resHandleOff]
	mov	bx, ds:[bx][size hptr]		;si <- dgroup handle
	test	es:[bx].HM_flags, mask HF_DISCARDED
	jz	dgroupNotDiscardable

;	The dgroup resource is discarded, so we need to allocate memory for
;	it.

	ornf	es:[bx].HM_flags, mask HF_FIXED
	mov	ax, es:[bx].HM_size
	mov	cl, 4			
	shl	ax, cl			;AX <- byte size of dgroup resource

	mov	ch, mask HAF_ZERO_INIT
	call	MemReAlloc
	jc	memError		;BX <- dgroup resource handle

dgroupNotDiscardable:

;	Load the writable fixed resources into memory, and init the udata
;	area to 0

	call	PreLoadResources

	call	ProcessGeodeFile

	mov	bx, ds:[GH_geodeHandle]
	call	MemUnlock
EC <	call	NullDS							>
	jnc	exit
	
;	ProcessGeodeFile returned an error (most likely because the LCT_INIT/
;	DR_INIT call returned carry set), so free the geode.

	push	ax
	LoadVarSeg	ds
	call	FreeGeodeLow
	pop	ax
errorExit:
	stc
exit:
	.leave
	ret


LoadXIPGeodeWithHandle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitGeodeHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the handles for a geode, using the size and flags
		stored in the coreblock

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResourceHandleInformation	struct
	RHI_size	word
	RHI_flags	HeapFlags
ResourceHandleInformation	ends

InitGeodeHandles	proc	near
	uses    ax, bx, cx, di, si, es
	.enter

;	On XIP systems, the GH_resPosOff field points to an array of
;	ResourceHandleInformation structures, one for each resource.

	LoadVarSeg	es
	mov	cx, ds:[GH_resCount]
	mov	si, ds:[GH_resHandleOff]
	mov	di, ds:[GH_resPosOff]

;	If no handle information stored (probably an XIP image created without
;	the -H flag) whine, then skip the handle initialization.

	tst	di
	WARNING_Z	XIP_IMAGE_CREATED_WITHOUT_H_FLAG
	jz	exit
	dec	cx	;Decrement the resource count, as we are skipping
			; the coreblock (it is already resident, so we do
			; not want to mess with the flags).
EC <	ERROR_S		ILLEGAL_RESOURCE_COUNT				>
	jcxz	exit

loopTop:
	add	si, size word		;Go to next array entry (skips first
					; array entry, which is the coreblock)
	add	di, size ResourceHandleInformation
	mov	bx, ds:[si]		;ES:BX <- HandleGen structure
EC <	call	ECCheckMemHandleNSFar					>

	mov	al, ds:[di].RHI_flags
EC <	test	al, mask HF_DEBUG or mask HF_SWAPPED			>
EC <	ERROR_NZ	INVALID_HANDLE_FLAGS_STORED_IN_XIP_IMAGE	>
	mov	es:[bx].HM_flags, al
EC <	test	al, mask HF_DISCARDED					>
EC <	jz	notDiscarded						>
EC <	tst	es:[bx].HM_addr						>
EC <	ERROR_NZ	RESIDENT_RESOURCE_BEING_CHANGED_TO_BE_DISCARDED	>
EC <notDiscarded:							>

	mov	ax, ds:[di].RHI_size
EC <	cmp	ax, 65535 / 16						>
EC <	ERROR_AE	INVALID_HANDLE_SIZE_STORED_IN_XIP_IMAGE		>

EC <	tst	es:[bx].HM_addr						>
EC <	jz	notResident						>
EC <	cmp	ax, es:[bx].HM_size					>
EC <	ERROR_NZ	CHANGING_SIZE_OF_RESIDENT_RESOURCE		>
EC <notResident:							>
	mov	es:[bx].HM_size, ax
	loop	loopTop
exit:
	.leave
	ret
InitGeodeHandles	endp


endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadGeodeAfterFileOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Actual workhorse of loading a geode, called from a number
		of places with the .geo file already open.

CALLED BY:	LoadGeodeLow, UseLibraryLow
PASS:		al	= priority for process thread, if process
		ah	= flags (must be zero)
		cx	= GeodeAttrs to match
		dx	= GeodeAttrs to NOT match
		bp, di	= information for new process
		bx	= open file handle (need not be positioned at
			  offset 0 in the file, but should be opened
			  FE_DENY_WRITE, FA_READ_ONLY)
RETURN:		carry set if error:
			ax	= GeodeLoadError
		carry clear if ok:
			bx	= handle of new Geode
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoadGeodeAfterFileOpen proc near
valueToPass2	local word push bp		;value passed in bp
valueToPass1	local word push di		;value passed in di
notAttributes	local word push dx		;value passed in dx
attributes	local word push cx		;value passed in cx
flagsAndPrio	local GeodeLoadFlagsAndPriority \
		push	ax
otherInstance	local hptr
temporary	local word
execHeader	local ExecutableFileHeader
fileType	local GeosFileType		;buffer for ensuring file is
						; an executable
if	not NEVER_ENFORCE_HEAPSPACE_LIMITS
heapSpace	local word			;Temp variable for HeapSpace
endif	; not NEVER_ENFORCE_HEAPSPACE_LIMITS
currentGeode	local hptr
	uses	cx, dx, si, di, es, ds

	ForceRef valueToPass2
	ForceRef valueToPass1
	ForceRef notAttributes
	ForceRef attributes
	ForceRef flagsAndPrio
	ForceRef otherInstance
	ForceRef temporary
	ForceRef execHeader
	ForceRef fileType
if	not NEVER_ENFORCE_HEAPSPACE_LIMITS
	ForceRef heapSpace			;Temp variable fo HeapSpace
endif	; not NEVER_ENFORCE_HEAPSPACE_LIMITS
	ForceRef currentGeode

	.enter

	LoadVarSeg	es

EC <	or	ah,ah							>
EC <	ERROR_NZ LGL_BAD_FLAGS						>

	;Allocate local scratch space, save parameters passed

	; setup ThreadLock here..  stored in HF_semaphore
	; We used to use a semaphore to allow only one thread at a time
	; to load a resource, but now we are using a threadlock so
	; that we can recursively load resources.  This is required
	; since we allow the async biffing of VM based Object blocks.
	; An example:  we are trying to load in a resource, so we need
	; to find room.  One of the blocks we toss out is an Object
	; block requiring relocation.  This locks down the owner and
	; any imported libraries which may include our initial
	; resource.

	mov	si, bx				; preserve the file handle in si
	call	ThreadAllocThreadLock
	mov	es:[si].HF_semaphore, bx	; store the semaphore Handle
	mov	bx, si				; restore file handle

	; ensure enough free space on the heap. We assume the geode will require
	; half its file size on start-up...

	call	FileSize
	mov	cl, 5			; convert to paragraphs and divide by
	ror	dx, cl			;  two
	shr	ax, cl
	andnf	dx, 0xf800
	or	ax, dx
	LoadVarSeg	ds
	call	HeapEnsureFreeSpace

	;Read in Geode header

	call	ReadGeodeHeader
	LONG jc	errorRemoveFile

if	not NEVER_ENFORCE_HEAPSPACE_LIMITS
	mov	ax, ss:[execHeader].EFH_attributes
	mov	cx, ss:[execHeader].EFH_heapSpace
	call	GeodeEnsureEnoughHeapSpace
	LONG jc	errorRemoveFile
					; ax = "heap space" required, if any
endif	; not NEVER_ENFORCE_HEAPSPACE_LIMITS

	;Allocate core block for Geode and read in core data information

	push	ax
	call	AllocateCoreBlock	;ds = core block (locked), ax =
					; GeodeLoadError (if carry set)
	pop	cx			; cx = "heap space" required, if any
	LONG jc	errorRemoveFile

	; set the Geodes semaphore ownership
	mov	bx, ds:[GH_geodeHandle]
	mov	es:[bx].HM_owner, bx
	mov	si, ds:[GH_geoHandle]
	mov	si, es:[si].HF_semaphore
	mov	es:[si].HS_owner, bx

if	not NEVER_ENFORCE_HEAPSPACE_LIMITS
	jcxz	10$			; if no "heap space" requirement, skip
	mov_tr	ax, cx			; ax = "heap space" required

	call	GeodeSetHeapSpaceUsedByGeode
10$:
endif	; not NEVER_ENFORCE_HEAPSPACE_LIMITS

if USE_PATCHES

	; Look for a patch file.  If found, read it in.

	lea	di, ss:[execHeader].EFH_udataSize

endif

if USE_BUG_PATCHES

	call	GeodeOpenGeneralPatchFile

endif

if MULTI_LANGUAGE

	call	IsMultiLanguageModeOn
	jc	afterLanguage
	call	GeodeOpenLanguagePatchFile

afterLanguage:

endif

if USE_BUG_PATCHES

	; Check for general patch data.

	LoadVarSeg	es, ax
	tst	ds:[GH_generalPatchData]
	jz	afterRealloc		; Core block should not be changed.

	; Resize the core block if the patch adds any resources or
	; entry points.

	call	GeodePatchReAllocCoreBlock

afterRealloc:

endif
	;Process library table

	call	ProcessLibraryTable	;process library table
	jc	errorRemoveFileMem

	; Load exported entry point table
	call	LoadExportTable
	jc	errorRemoveFileMem

	;Load and initialize resource table (call to InitResources)
	call	InitResources
	jc	errorFreeLibMem

	; Relocate the exported entry point table
	call	RelocateExportTable

	; Set up library and driver stuff -- ProcessGeodeFile makes the
	; geode own itself.
	call	ProcessGeodeFile
	jc	errorFreeGeode

ife FAULT_IN_EXECUTABLES_ON_FLOPPIES
	; if (file is not to be kept open) -> close Geode file
	; and zero geoHandle field
FXIP <	test	ds:[GH_geodeAttr], mask GA_XIP				>
FXIP <	jnz	retOK							>
	test	ds:[GH_geodeAttr], mask GA_KEEP_FILE_OPEN
	jnz	noCloseFile
	clr	bx			; clear out geoHandle and close file
	xchg	bx,ds:[GH_geoHandle]
	mov	al,FILE_NO_ERRORS
	call	FileCloseFar
retOK:
endif

	mov	ax,ds
	mov	bx,ds:[GH_geodeHandle]	;return handle to process created
	call	MemUnlock
EC <	call	NullDS							>
	clc
LGAFO_done label near
	.leave
	ret

ife FAULT_IN_EXECUTABLES_ON_FLOPPIES
noCloseFile:
	; Change the ownership of the file handle to the geode so it doesn't
	; get closed if the loading geode goes away.
	mov	bx, ds:[GH_geoHandle]
	mov	ax, ds:[GH_geodeHandle]
	mov	es:[bx].HG_owner, ax
	jmp	retOK
endif

	; error -- free geode

errorFreeGeode:
	push	ax
ife FAULT_IN_EXECUTABLES_ON_FLOPPIES
	; mark geode as keep-file-open so FreeGeodeLow actually closes
	; the .geo file. 
	ornf	ds:[GH_geodeAttr], mask GA_KEEP_FILE_OPEN
endif
	mov	bx, ds:[GH_geodeHandle]
	LoadVarSeg	ds
	call	FreeGeodeLow
	pop	ax
	stc
	jmp	LGAFO_done

	; error -- free libraries

errorFreeLibMem:
	push	ax
	segxchg	ds, es
	call	FrGL_FreeLibraryUsages
	segxchg	ds, es
	pop	ax

errorRemoveFileMem:
	push	ax
	mov	bx, ds:[GH_geoHandle]	; Make sure the file handle is
	mov	ax, ss:[TPD_processHandle];owned by the loading geode (not
	cmp	es:[bx].HG_owner, ax	;  another instance of the failed
					;  geode) before pushing it for
					;  errorRemoveFile
	je	closeOK
	clr	bx			; Not ours => don't close
closeOK:
	push	bx
	mov	bx, ds:[GH_privData]
	tst	bx
	jz	noPrivData
	call	MemFree
noPrivData:
	mov	bx, ds:[GH_geodeHandle]	; bx <- core block handle
	call	MemFree
	pop	bx
	pop	ax

errorRemoveFile:
	tst	bx
	jz	noClose
	push	ax			;save error code

	mov	si, bx			; remove the file's semaphore
	mov	bx, es:[si].HF_semaphore
	call	ThreadFreeSem
	mov	bx, si

	mov	al,FILE_NO_ERRORS
	call	FileCloseFar
	pop	ax
noClose:
	stc
	jmp	LGAFO_done

LoadGeodeAfterFileOpen	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ReadGeodeHeader

DESCRIPTION:	Read in the header of an open Geode file and check to see if it
		is legal and if it matches the type and attributes asked for.

CALLED BY:	INTERNAL
		LoadGeodeAfterFileOpen

PASS:
	bx - file handle
	ss:bp - stack frame inherited from LoadGeodeAfterFileOpen
	es - kernel variables

RETURN:
	bx - file handle
	carry - set if error
	ax - error code (GeodeLoadError):
		GLE_FILE_READ_ERROR
		GLE_NOT_GEOS_FILE
		GLE_NOT_GEOS_EXECUTABLE_FILE
		GLE_FILE_TYPE_MISMATCH
		GLE_ATTRIBUTE_MISMATCH
		GLE_PROTOCOL_ERROR_IMPORTER_TOO_RECENT
		GLE_PROTOCOL_ERROR_IMPORTER_TOO_OLD

DESTROYED:
	ax, cx, dx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	fetch FEA_FILE_TYPE and make sure it's GFT_EXECUTABLE

	Read Geode header
	if (version too high) -> return error
	if (file type does not match) -> return error
	if (attributes do not match) -> return error

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

ReadGeodeHeader	proc	near
	.enter	inherit	LoadGeodeAfterFileOpen

	; fetch the FEA_FILE_TYPE extended attribute from the file to confirm
	; it is indeed a geos executable.

	push	es
	segmov	es, ss
	lea	di, ss:[fileType]
	mov	cx, size fileType
	mov	ax, FEA_FILE_TYPE
	call	FileGetHandleExtAttributes
	pop	es
	mov	ax,GLE_NOT_GEOS_EXECUTABLE_FILE
	jc	error

	;if (not executable file) -> return error

	cmp	ss:[fileType],GFT_EXECUTABLE
	jnz	error

	; read in executable file header

	mov	al,FILE_POS_START		;position correctly
	clr	cx
	mov	dx,cx
	call	FilePosFar

	mov	cx,size ExecutableFileHeader	;read first header info
	segmov	ds, ss
	lea	dx,ss:[execHeader]
	clr	al
	call	FileReadFar
	mov	ax,GLE_FILE_READ_ERROR
	jnc	10$
error:
	stc
	jmp	done

10$:

	;if (attributes do not match) -> return error

	mov	ax,GLE_ATTRIBUTE_MISMATCH
	mov	cx,ss:[execHeader].EFH_attributes
	test	cx,ss:[notAttributes]
	jnz	error
	not	cx
	test	cx,ss:[attributes]
	jnz	error

	clc
done:
	.leave
	ret

ReadGeodeHeader	endp

if	not NEVER_ENFORCE_HEAPSPACE_LIMITS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeEnsureEnoughHeapSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure there's going to be sufficient space on the heap
		after launching this geode that it's worth doing so.  
		TRANSPARENT_DETACH older apps if necessary, to try & accomodate
		this request.

CALLED BY:	INTERNAL
PASS:		
		ax - GeodeAttrs for application
		cx - heapspace value 
		bx - file handle
		ss:bp - stack frame inherited from LoadGeodeAfterFileOpen
	 		valueToPass2	- ^hAppLaunchBlock, if application
			heapSpace	- variable space for us to use
		es - kernel variables
RETURN:		bx - file handle
		carry - set if error
		ax - error code (GeodeLoadError), or heap space required if
		     no error (in K) (else 0 if no requirement)
DESTROYED:	cx, dx, si, di, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeodeEnsureEnoughHeapSpace	proc	near	uses	bx
	.enter	inherit	LoadGeodeAfterFileOpen
if 	FULL_EXECUTE_IN_PLACE
PrintMessage <Do we want to muck with the heapspace stuff on XIP geodes?>
endif

	; We only check operating space for whole applications.  Return without
	; error if anything else.
	;

	test	ax, mask GA_APPLICATION		; clears carry
	mov	ax,0				; no heap space requirement yet
	jz	exitNoError

	tst	cx
	jnz	haveHeapSpaceReq

	mov	cx, HEAP_DEFAULT_SPACE_REQUIRED_FOR_GEODE
haveHeapSpaceReq:
	; now we need to boost up the required heapspace if we are
	; running EC.  This boost should match the one in
	; GeodeGetHeapSpaceUsedByGeode.
EC<	push	dx					>
EC<	mov	dx, cx					>
EC<	shr	cx					>
EC<	shr	cx					>
EC<	shr	cx					>
EC<	add	cx, dx					>
EC<	pop	dx					>

	;
	; Convert value in paragraphs to be in terms of K
	; (the value used internally is in K, but the value in
	; the ExecutableFileHeader is in paragraphs, because that's how
	; it was in Zoomer, and we cannot change it now).
	;

	shr	cx, 1		;Convert from paragraphs to K (1024/16 = 64)
	shr	cx, 1
	shr	cx, 1
	shr	cx, 1
	shr	cx, 1
	shr	cx, 1
	adc	cx, 0		;Round to nearest K (carry will be set here
				; if we need to round up)

	clr	currentGeode	; we are attempting to launch and app,
				; not find space for a reservation..
	call	GeodeEnsureEnoughHeapSpaceCore

exitNoError:
	.leave
	ret
GeodeEnsureEnoughHeapSpace	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeEnsureEnoughHeapSpaceCore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure there's going to be sufficient space on the
		heap after the space is taken.  TRAANSPARENT_DETACH
		older apps if necessary, to try & accomodate this request

CALLED BY:	INTERNAL - GeodeEnsureEnoughHeapSpace & GeodeRequestSpace
PASS:		cx - heapspace required, in K
		ss:bp - stack frame inherited from LoadGeodeAfterFileOpen
		es - kernel variables
RETURN:			carry - set if error
		ax - error code (GeodeLoadError), or heapspace
			required iff no error (in K)
DESTROYED:	bunches.. bx, cx, dx, si, di, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	2/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeEnsureEnoughHeapSpaceCore	proc	near
	.enter	inherit LoadGeodeAfterFileOpen

	push	cx		; save heapspace use for this app

	; If heapSpaceLimitEnforced = NULL, then this scheme is not in use -- OK
	; everything.  Note: MaxTotalHeapSpace has been phased out by heapSize!
	;
	tst	es:[heapSpaceLimitsEnforced]
	jz	popExitNoError

	call	FarPheapVarBufSem

	; Figure out how much space we'll need
	;
	call	GeodeGetTotalHeapSpaceInUse

GEEHSC_showHeapSpace::			; showcalls -H
	
	add	cx, ax				; cx = total space needed
EC <	ERROR_C	TOTAL_HEAP_SPACE_IN_USE_EXCEEDED_64_MEGS		>
	mov	dx, es:[heapSize] ; used to be geodeMaxHeapSpaceTotal

	cmp	cx, dx
	ja	needMoreSpace

popExitNoError:
	pop	ax		; return heap space requirement in ax

	clc			; no errors
	jmp	short exit

popExitWithError:
	pop	cx		; fix stack, preserve error # in ax

;exitWithError:
	stc
exit:
	call	FarVheapVarBufSem	; careful!  don't tweak flags!
	.leave
	ret


needMoreSpace:
						; cx = total space needed
						; dx = maxTotalHeapSpace

	mov     bx, handle GCNListBlock
        call    MemPLock
	mov	ds, ax

	; Try it -- look through lists & see if it's possible
	;
	clr	heapSpace	; clear flag - means don't detach, just calc
	push	cx, dx		; preserve desire, have amounts for 2nd pass
	call	LookForHeapSpace
	pop	cx, dx
	jc	unsuccessful

	; OK, it's doable.  No need to return error.  This time, go ahead
	; & do it.  Since we have the GCNListBlock locked down, the only
	; way we could get an error here is if someone changed their heapspace
	; value on us, in fact, lowering it, which would be highly unusual.
	; In any case, there'd be no damage done, just some apps detached, 
	; & we have to return with an error anyway.  The worst that could
	; happen is that we detach the top full screen app & find we can't
	; actually load a new full screen app, meaning the user will end
	; up looking at the wrong app.  Oh well... like I said, this would
	; be extremely unusual.
	;
	inc	heapSpace	; set flag - do detach this time
	call	LookForHeapSpace
	jc	unsuccessful

GEEHSC_heapSpaceAcquired::		; showcalls -H

	;
	; unlock *after* enum'ing, deadlock in HEOS_transparentDetach when
	; detaching app that is doing the launching avoided by using
	; MF_FORCE_QUEUE in HEOS_transparentDetach (could use MemThreadGrab
	; here, instead, but it seems better to force queue the detach anyway)
	; - brianc 3/24/93
	;
	mov     bx, handle GCNListBlock
	call    MemUnlockV
	jmp	short popExitNoError

unsuccessful:
	mov     bx, handle GCNListBlock
        call    MemUnlockV
	mov	ax, GLE_INSUFFICIENT_HEAP_SPACE
	jmp	short popExitWithError
GeodeEnsureEnoughHeapSpaceCore	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LookForHeapSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for additional heapspace by walking through the lists
		of detachable apps, adding up how much we'd get

CALLED BY:	INTERNAL
		GeodeEnsureEnoughHeapSpace

PASS:		ds	- locked GCNListBlock
		cx 	-  total space needed
		dx 	-  maxTotalHeapSpace
		ss:bp - stack frame inherited from LoadGeodeAfterFileOpen
			valueToPass2	- ^hAppLaunchBlock, if application
			heapSpace	- flag -- set to do detach
			currentGeode	- either 0 or geode not to detach

RETURN:		carry	- set if can't get enough space, else
		cx 	-  updated space needed after detach(es)
		dx 	-  uchanged (maxTotalHeapSpace)
DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/93		Split out from GeodeEnsureEnoughHeapSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LookForHeapSpace	proc	near
	.enter	inherit	LoadGeodeAfterFileOpen
;
; 1.  	Go through full-screen apps still running, & figure out which we could
; 	get rid of.
;
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TRANSPARENT_DETACH
	clc	
	call	FindGCNList
	jnc	afterFullScreen

	mov	bx, cs
	mov	di, offset HEOS_check
	call	ChunkArrayEnum
				; Returns:
				; cx 	-  updated space needed after detach(es)
				; dx 	-  uchanged (maxTotalHeapSpace)

	; See if enough room made
	;
	cmp	cx, dx
	jbe	successful	; If found enough, done
afterFullScreen:

;
; 2.	Need still more space.  If launching a full-screen app, try detaching
; 	the top full-screen app.
;
	tst	currentGeode			; if non-zero, we're
						; not launching an
						; app..
	jnz	afterFullScreenExcl

EC <	tst	valueToPass2						>
EC <	ERROR_Z	NOT_ENOUGH_HEAPSPACE_TO_LOAD_UI				>

	push	bx
	mov	bx, valueToPass2		; MUST be AppLaunchBlock
	call	MemLock				; or death is appropriate.
	push	ds
	mov	ds, ax
	test	ds:[ALB_launchFlags], mask ALF_DESK_ACCESSORY
	pop	ds
	call	MemUnlock
	pop	bx
	jnz	afterFullScreenExcl
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TRANSPARENT_DETACH_FULL_SCREEN_EXCL
	clc	
	call	FindGCNList
	jnc	afterFullScreenExcl
	
	mov	bx, cs
	mov	di, offset HEOS_check
	call	ChunkArrayEnum
				; Returns:
				; cx 	-  updated space needed after detach(es)
				; dx 	-  uchanged (maxTotalHeapSpace)

	; See if enough room made
	;
	cmp	cx, dx
	jbe	successful	; If found enough, done
afterFullScreenExcl:

;
; 3.	Need still more space.  Run through the DA list
;
; What to do here...
;
; If we nuke desk accesories that are on screen, we risk disrupting the user's
; perception of the world, i.e. that things are stable and in their control.
; If we don't nuke the D/A's at this point, they get an error dialog, & have
; to then close down something & try again.  Or a couple of something's --
; there's no indication just how much needs shutting down.  The idea of
; allowing exactly one D/A breaks down when you consider that we are likely
; to want to deal with things like AOL by having it put up a floating, non-
; modal command window indicating the connection still being in pogress, with
; options to goto AOL, logoff, etc. to give the user continued indication
; that they're doing something there.  For lack of a definitive answer...
;
if	(1)			; True.  We nuke D/As if we need the room.
				; Same behavior as before.  Another thought --
				; perhaps detachable D/As should come down when
				; anything else comes up?
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TRANSPARENT_DETACH_DA
	clc	
	call	FindGCNList
	jnc	afterDA
	
	mov	bx, cs
	mov	di, offset HEOS_check
	call	ChunkArrayEnum
				; Returns:
				; cx 	-  updated space needed after detach(es)
				; dx 	-  uchanged (maxTotalHeapSpace)

	; See if enough room made
	;
	cmp	cx, dx
	jbe	successful	; If found enough, done
afterDA:
endif

	; Otherwise, just can't do it -- bail.
	;
	stc
	jmp	short done

successful:
				; cx 	-  updated space needed after detach(es)
				; dx 	-  uchanged (maxTotalHeapSpace)
	clc			; no error
done:
	.leave
	ret
LookForHeapSpace	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HEOS_check
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	INTERNAL
		callback for GeodeEnsureEnoughHeapSpace
PASS:		*ds:si - gcn list
		ds:di - gcn list element
		cx 	-  updated space needed after detach(es)
		dx 	-  uchanged (maxTotalHeapSpace)
		ax = # of apps wer're detaching so far
		ss:bp - stack frame inherited from LoadGeodeAfterFileOpen
			heapSpace	- flag -- set to do detach
			currentGeode	- 0 or geode not to detach

RETURN:		cx 	-  updated space needed after detach(es)
		dx 	-  uchanged (maxTotalHeapSpace)
		ax = # of apps we're detaching so far
		carry - set to end enumeration
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/3/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HEOS_check	proc	far	uses	bx
	.enter	inherit	LoadGeodeAfterFileOpen
	inc	ax		; One more...
	push	ax
	mov	bx, ds:[di].GCNLE_item.handle
	call	MemOwnerFar

	cmp	currentGeode, bx	; this is the geode asking for space!
	je	notEnough		; don't detach!

	; Check to see if we're already transparently detaching this
	; geode.  It could still have a MSG_META_TRANSPARENT_DETACH or
	; MSG_META_DETACH in the queue & not have gotten to taking itself
	; off this list yet, so this is a good thing to check.
	;
	push	bx, cx, dx, si, di
	mov	cx, bx
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TRANSPARENT_DETACH_IN_PROGRESS
	call	FindGCNList
	jnc	notFound
	call	GCNListFindItemInList
notFound:
	pop	bx, cx, dx, si, di
	jc	notEnough

	call	GeodeGetHeapSpaceUsedByGeode
	sub	cx, ax
	tst	heapSpace	; Test flag -- do detach?
	jz	afterDetach
	push	cx, dx
	call	GeodeTransparentDetach		; Do it -- start detach
	pop	cx, dx
afterDetach:
	cmp	cx, dx
	ja	notEnough
	stc			; have enough - end enum
	jmp	short done

notEnough:
	clc
done:
	pop	ax
	.leave
	ret
HEOS_check	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeTransparentDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	INTERNAL
		callback for GeodeEnsureEnoughHeapSpace
PASS:		*ds:si - gcn list
		ds:di - gcn list element

RETURN:		nothing
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/3/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeTransparentDetach	proc	far	uses	bx, si, di
	.enter
	mov	bx, ds:[di].GCNLE_item.handle	; handle of app obj
	push	bx				; save item while ptr valid
	push	ds:[di].GCNLE_item.chunk	; chunk of app obj

	call	MemOwnerFar			; get owning geode
	mov	al, PRIORITY_LOWEST
	mov	ah, mask TMF_BASE_PRIO
	call	GeodeThreadModify		; modify thread prios for geode

	; Add geode to GCN list of those things we're in the process of
	; transparently detaching.
	;
	mov	cx, bx
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TRANSPARENT_DETACH_IN_PROGRESS
	stc	
	call	FindGCNList
	call	GCNListAddToList

	pop	si				; get app obj optr off stack
	pop	bx

	mov	ax, MSG_META_TRANSPARENT_DETACH
	;
	; use MF_FORCE_QUEUE here to avoid deadlock on GCNListBlock when
	; transparent detaching app that is doing the launching (see
	; GeodeEnsureEnoughHeapSpace above) - brianc 3/24/93
	;
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	.leave
	ret
GeodeTransparentDetach	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeThreadModify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modifies process & UI thread priorities for a process geode

CALLED BY:	INTERNAL
PASS:		bx	- geode
		al - new base priority (if the bit is set to change it)
		ah - ThreadModifyFlags (flags for what to modify)
			TMF_BASE_PRIO - set to modify base priority
			TMF_ZERO_USAGE - set to zero recent CPU usage
RETURN:		bx	- unchanged
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/20/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeThreadModify	proc	near
	push	bx		; process handle
	call	ProcInfo	; get first thread
	push	ax
	call	ThreadModify
	pop	ax
	pop	bx		; process handle

	; & its second (UI) thread, if it has it, too
	;
	push	ds
	push	ax
	call	MemLock
	mov	ds, ax
	pop	ax
	push	bx
	mov	bx, ds:[PH_uiThread]
	tst	bx
	jz	afterSecondThread
	call	ThreadModify
afterSecondThread:
	pop	bx		; process handle
	call	MemUnlock
	pop	ds
	ret
GeodeThreadModify	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeGetRidOfTransparentlyDetachingAppsNow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We've been nice up to now, & let apps leisurely take their
		time detaching.   We're no longer going to be so nice.  In
		fact, we want them gone, NOW.  To do this, we'll go through
		the list of threads that we saved earlier, & up the priorities
		of the threads to very high levels, in hopes that they'll
		take over & nuke themselves, before we go looking for heap
		space.

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/20/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeGetRidOfTransparentlyDetachingAppsNow	proc	near
	call	PushAllFar
	mov     bx, handle GCNListBlock
        call    MemPLock
	mov	ds, ax

	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TRANSPARENT_DETACH_IN_PROGRESS
	clc
	call	FindGCNList
	jnc	afterAppsStillDetachingTossed

	clr	ax			; none being detached yet
	mov	bx, cs
	mov	di, offset GGROFDAN_callback
	call	ChunkArrayEnum
	tst	ax
	jz	afterAppsStillDetachingTossed

	mov     bx, handle GCNListBlock
        call    MemUnlockV

	; Now, drop our own thread priority to let these apps go as far
	; as they can...
	;
	clr	bx			; get current thread priority
	mov	ax, TGIT_PRIORITY_AND_USAGE
	call	ThreadGetInfo
	push	ax			; save it
	mov	al, PRIORITY_IDLE	; drop it to give apps a chance
	mov	ah, mask TMF_BASE_PRIO
	clr	bx
	call	ThreadModify
	pop	ax			; then restore our own priority
	mov	ah, mask TMF_BASE_PRIO
	clr	bx
	call	ThreadModify
	jmp	short done

afterAppsStillDetachingTossed:
	mov     bx, handle GCNListBlock
        call    MemUnlockV
done:
	call	PopAllFar
	ret
GeodeGetRidOfTransparentlyDetachingAppsNow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GGROFDAN_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	INTERNAL
		callback for GeodeGetRidOfTransparentlyDetachingAppsNow
PASS:		*ds:si - gcn list
		ds:di - gcn list element
		ax - # being detached so far

RETURN:		carry - set to end enumeration
		ax - # being detached so far
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/3/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGROFDAN_callback	proc	far
	push	ax
	mov	bx, ds:[di].GCNLE_item.handle	; Fetch geode busy detaching
	mov	al, PRIORITY_UI			; Push WAY up there. 
						; Get lost! Shoo!
	mov	ah, mask TMF_BASE_PRIO
	call	GeodeThreadModify		; Both threads
	pop	ax
	inc	ax
	clc					; all of 'em
	ret
GGROFDAN_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeGetTotalHeapSpaceInUse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get total of "heap space" amounts declared by all running
		applications.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		ax - total "heap space" in use, in K

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/10/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeGetTotalHeapSpaceInUse	proc	far
	uses	bx, si, di, dx
	.enter
	clr	bx		; entire geode list
	clr	ax		; no heap space recorded yet
	mov	di, SEGMENT_CS
	mov	si, offset GGTHSIU_callBack
	call	GeodeForEach
	.leave
	ret
GeodeGetTotalHeapSpaceInUse	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GGTHSIU_callBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for GeodeGetTotalHeapSpaceInUse.  Add in
		"HeapSpace" amount in use for applications

CALLED BY:	INTERNAL
PASS:		bx	- handle of geode
		es	- segment of core block
		ax	- total "heap space" so far (in K)
RETURN:		ax	- new total "heap space" (in K)
DESTROYED:	dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/10/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGTHSIU_callBack	proc	far
	mov	dx, ax
	mov	ax, GGIT_ATTRIBUTES
	call	GeodeGetInfo
	test	ax, mask GA_APPLICATION
	jz	done
	call	GeodeGetHeapSpaceUsedByGeode
	add	dx, ax
done:
	mov	ax, dx
	ret
GGTHSIU_callBack	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeGetHeapSpaceUsedByGeode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get "Heap space" requirement declared by application 

CALLED BY:	INTERNAL
PASS:		bx	- geode handle
RETURN:		ax	- "heap space" requirement (in K)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/10/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeGetHeapSpaceUsedByGeode	proc	far
	uses	cx, si, di, ds
	.enter
	call	GetHeapVarsParamsCommon
	call	GeodePrivRead
	lodsw				; get GHV_heapSpace


if FULL_EXECUTE_IN_PLACE
;
; We don't want to pad the heap values for XIP'd geodes.
;
EC <	mov	cx, ax 						>
EC <	mov	ax, GGIT_ATTRIBUTES				>
EC <	call	GeodeGetInfo 					>
EC <	test	ax, mask GA_XIP 				>
EC <	mov	ax, cx		 				>
EC <	jnz	noHeapBoost					>

endif

;
; Now we will boost the required space while running EC.
EC<	mov	cx, ax					>
EC<	shr	ax					>
EC<	shr	ax					>
EC<	shr	ax					>
EC <	add	ax, cx					>

if FULL_EXECUTE_IN_PLACE
EC < noHeapBoost:							>
endif
	.leave
	ret
GeodeGetHeapSpaceUsedByGeode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeSetHeapSpaceUsedByGeode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set "Heap space" requirement declared by application 

CALLED BY:	INTERNAL
PASS:		bx	- geode handle
		ax	- "heap space" requirement
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/10/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeSetHeapSpaceUsedByGeode	proc	far
	uses	cx, si, di, ds
	.enter
	call	GetHeapVarsParamsCommon
	mov	{word} ds:[si], ax	; store GHV_heapSpace
	call	GeodePrivWrite
	.leave
	ret
GeodeSetHeapSpaceUsedByGeode	endp

;
;---
;

GetHeapVarsParamsCommon	proc	near
	LoadVarSeg	ds
	mov	di, ds:[geodeHeapVarsOffset]
	mov	si, offset geodeHeapVarsBuffer
	mov	cx, (size GeodeHeapVars)/2
	ret
GetHeapVarsParamsCommon	endp

endif	; not NEVER_ENFORCE_HEAPSPACE_LIMITS


COMMENT @----------------------------------------------------------------------

FUNCTION:	TestProtocolNumbers

DESCRIPTION:	Compare two protocol numbers

CALLED BY:	INTERNAL

PASS:
	ax - importer's expected protocol number, major
	bx - importer's expected protocol number, minor
	cx - exporter's protocol number, major
	dx - exporter's protocol number, minor

RETURN:
	carry - set if error
	ax - error type:
		GLE_PROTOCOL_ERROR_IMPORTER_TOO_RECENT
		GLE_PROTOCOL_ERROR_IMPORTER_TOO_OLD

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

TestProtocolNumbers	proc	near

	; compare major numbers first

	cmp	ax,cx
	ja	tooRecent
	jb	tooOld

	; major numbers equal -- compare minor numbers

	cmp	bx,dx
	ja	tooRecent

	; no error

	clc
	ret

tooRecent:
	mov	ax, GLE_PROTOCOL_IMPORTER_TOO_RECENT
	stc
	ret

tooOld:
	mov	ax, GLE_PROTOCOL_IMPORTER_TOO_OLD
	stc
	ret

TestProtocolNumbers	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AllocateCoreBlock

DESCRIPTION:	Allocate the core block for a Geode and read core data
		information from the file

CALLED BY:	LoadGeodeAfterFileOpen

PASS:
	bx - file handle positioned after ExecutableFileHeader
	ss:bp - stack frame inherited from LoadGeodeAfterFileOpen
	es - kernel variables

RETURN:
	carry - set if error
	if error:
		ax - error code (GeodeLoadError):
			GLE_FILE_READ_ERROR
			GLE_MEMORY_ALLOCATION_ERROR
		bx - file handle
	if no error:
		ds - core block for new Geode with core data information
		     loaded in and these fields set:
			GH_geodeHandle, GH_geoHandle, GH_parentProcess

DESTROYED:
	ax, bx, cd, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

AllocateCoreBlock	proc	near
	.enter	inherit	LoadGeodeAfterFileOpen
	push	bx			;save file handle

	mov	ax, ss:[execHeader].EFH_importLibraryCount
	CheckHack <size ImportedLibraryEntry eq 14>
	shl	ax		; *2
	mov	dx, ax		; dx <- count*2
	shl	ax		; *4
	add	dx, ax		; dx <- count*6
	shl	ax		; *8
	add	dx, ax		; dx <- count*14

	; calculate size to allocate
	;	= size GeodeHeader (or) ProcessHeader
	;	+ (number resources) * 8
	;	+ (number imported libraries) * 2
	;	+ (number exported entry points) * 4

	mov	ax,ss:[execHeader].EFH_resourceCount
	shl	ax,1
	add	ax,ss:[execHeader].EFH_exportEntryCount
	shl	ax,1
	add	ax,ss:[execHeader].EFH_importLibraryCount
	shl	ax,1
	add	ax,size GeodeHeader		;assume not a process
	test	ss:[execHeader].EFH_attributes, mask GA_PROCESS
	jz	notProcess
	add	ax,size ProcessHeader - size GeodeHeader
notProcess:


	push	ax			; save size for GH_extraLibOffset
	add	ax, dx			; add room for imported library entry
					;  table
if 	FULL_EXECUTE_IN_PLACE

	; The kernel's coreblock is stored in the ROM image. If the primary
	; file-system driver (the first geode the kernel loads) is *not*
	; in the XIP image, then we will have pre-allocated a coreblock
	; handle for the first geode to be loaded

	LoadVarSeg	ds, cx
	tst	ds:[geodeCount]
	jnz	allocNormally	;Exit if this is not the first geode loaded

;	Lock down the kernel's coreblock, and grab the handle we have
;	pre-allocated for this geode's coreblock.

	push	ax
	mov	bx, handle 0
	call	MemLock
	mov	ds, ax
	mov	ax, ds:[GH_nextGeode]
if	ERROR_CHECK
	cmp	ax, LAST_XIP_RESOURCE_HANDLE
	ERROR_NA	ILLEGAL_PREALLOCATED_COREBLOCK_HANDLE
endif
	call	MemUnlock
EC <	call	NullDS							>
	mov_tr	bx, ax			;BX <- handle for this coreblock
	pop	ax			;Size for this coreblock
	mov	ch, mask HAF_ZERO_INIT or mask HAF_LOCK
	call	MemReAlloc		;AX <- addr of locked mem for coreblock
	jmp	afterAlloc

allocNormally:
endif

	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE \
						or (mask HAF_ZERO_INIT shl 8)
	call	MemAllocFar
afterAlloc::
	mov	si,bx			;si = core block handle
	pop	dx			;recover size for GH_extraLibOffset
	pop	bx			;recover file handle
	jc	allocError

	; If we are executing the kernel in place, then we have
	; pre-allocated a handle for the next geode's core block (as the core
	; blocks are chained together, and the Kernel's core block is in 
	; read-only memory), so swap the memory over to the pre-allocated
	; handle

if	KERNEL_EXECUTE_IN_PLACE
	LoadVarSeg	ds, cx
	tst	ds:[geodeCount]
	jnz	doneXIP
	push	bx
	mov	bx, si			;bx = source, si = destination
	mov	si, ds:[xipFirstCoreBlock]
	call	XIPUsePreAllocatedHandle
	call	MemLock
	pop	bx
doneXIP:
endif



	mov	ds,ax			;ds = core block

	mov	ds:[GH_extraLibOffset], dx	; set offset at which to
						;  read imported library
						;  table

	; Read in partial GeodeHeader from file.

	mov	cx,GEODE_FILE_TABLE_SIZE 	; GeodeHeader in file includes
					 	; up to (but not including) 
						; GH_geoHandle field.
	clr	dx			; Read in at top of core block.
	clr	al
	call	FileReadFar		; bx already has file handle
	jc	readError

	;Set up Geode fields: GH_geodeHandle, GH_geoHandle, GH_parentProcess
	;	(preserve carry)

	mov	ds:[GH_geodeHandle],si		; Save memory handle
	mov	ds:[GH_geoHandle],bx		; Save file handle
	mov	ax,ss:[TPD_processHandle]	; Make current process be parent
	mov	ds:[GH_parentProcess],ax

	clc
done:
	.leave
	ret

readError:
	xchg	bx,si
	call	MemFree
	mov	bx,si			;return bx = file handle
	mov	ax, GLE_FILE_READ_ERROR
	stc
	jmp	done

allocError:
	mov	ax, GLE_MEMORY_ALLOCATION_ERROR
	jmp	done

AllocateCoreBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadExportTable

DESCRIPTION:	Load the exported entry point table for a geode

CALLED BY:	INTERNAL
		LoadGeodeLow

PASS:
	file pointing at exported entry table
	ss:bp - stack frame inherited from LoadGeodeAfterFileOpen
	ds - core block for new Geode (locked)
	es - kernel variables

RETURN:
	carry - set if error
	if error:
		ax - error code (GeodeLoadError):
			GLE_FILE_READ_ERROR

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

LoadExportTable	proc	near

	; Compute location for the exported entry point table
	;	libOffset + (2 * #libraries)

	mov	dx,ds:[GH_libCount]	;#libs * 2
	shl	dx,1
	add	dx,ds:[GH_libOffset]	;resources go after import table
	mov	ds:[GH_exportLibTabOff],dx

	; Read in table

	mov	cx,ds:[GH_exportEntryCount]
	clc
	jcxz	LET_ret
	shl	cx,1			;*2
	shl	cx,1			;*4
	mov	bx,ds:[GH_geoHandle]	;file handle to read from
	clr	al			;no flags
	call	FileReadFar
	mov	ax,GLE_FILE_READ_ERROR

LET_ret:
	ret

LoadExportTable	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RelocateExportTable

DESCRIPTION:	Relocate the exported entry point table for a geode

CALLED BY:	INTERNAL
		LoadGeodeLow

PASS:		ds - core block for new Geode

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

RelocateExportTable	proc	near

	mov	cx,ds:[GH_exportEntryCount]
	jcxz	RET_ret

	mov	di,ds:[GH_exportLibTabOff]
	add	di,2			;ds:di = segment of first entry point
RET_loop:
	call	ConvertIDToSegment
	add	di,4
	loop	RET_loop

RET_ret:
	ret

RelocateExportTable	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ProcessGeodeFile

DESCRIPTION:	Process a Geode file for GeodeLoad

CALLED BY:	LoadGeodeAfterFileOpen, LoadXIPGeodeWithHandle

PASS:
	file pointing at imported library table
	ss:bp - stack frame inherited from LoadGeodeAfterFileOpen
	ds - core block for new Geode (locked)
	es - kernel variables

RETURN:
	carry - set if error
	if error:
		ax - error code (GeodeLoadError):
			GLE_LIBRARY_PROTOCOL_ERROR
			GLE_LIBRARY_LOAD_ERROR
			GLE_DRIVER_INIT_ERROR
			GLE_LIBRARY_INIT_ERROR

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if (Geode is a driver) -> call LoadDriverTable to load the table
	Process library table by calling LoadLibraryTable
	Load and initialize resource table (call to InitResources)
	Read in initialized data
	if (Geode is a driver) -> up system driver count and initialize it
	if (Geode is a library) -> initialize library

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

ProcessGeodeFile	proc	near
	.enter	inherit	LoadGeodeAfterFileOpen

	; Make the Geode own itself so Swat reads in symbols

	mov	bx,ds:[GH_geodeHandle]
	mov	es:[bx][HM_owner],bx	;a Geode owns itsself

	; add Geode to Geode list -- we must do this before calling the
	; library entry point because the entry point might load something
	; that uses this library (which would not be known to exist yet)
	; ...also need to do it if the thing's a driver, Tony -- ardeb

	call	AddGeodeToList
	ornf	ds:[GH_geodeAttr],mask GA_GEODE_INITIALIZED

	; add one to the reference count here so if the LCT_ATTACH or
	; DR_INIT handler loads something that depends on this geode,
	; and that load fails, this geode doesn't vanish before our
	; eyes. we will decrement the count before we're through -- ardeb

	inc	ds:[GH_geodeRefCount]

if FAULT_IN_EXECUTABLES_ON_FLOPPIES

	; if (file is not to be kept open) -> close Geode file
	; and zero geoHandle field

FXIP <	test	ds:[GH_geodeAttr], mask GA_XIP				>
FXIP <	jnz	afterPossibleCloseFile					>
	test	ds:[GH_geodeAttr], mask GA_KEEP_FILE_OPEN
	jnz	noCloseFile
	clr	bx			; clear out geoHandle and close file
	xchg	bx,ds:[GH_geoHandle]
	mov	al,FILE_NO_ERRORS
	call	FileCloseFar
	jmp	afterPossibleCloseFile
noCloseFile:
	; Change the ownership of the file handle to the geode so it doesn't
	; get closed if the loading geode goes away.
	mov	bx, ds:[GH_geoHandle]
	mov	ax, ds:[GH_geodeHandle]
	mov	es:[bx].HG_owner, ax
afterPossibleCloseFile:
endif

	;if (Geode is a driver) -> up system driver count and initialize it

	test	ds:[GH_geodeAttr], mask GA_DRIVER
	jz	notDriver2

;	For XIP geodes, the driver table is already relocated.

FXIP <	test	ds:[GH_geodeAttr], mask GA_XIP				>
FXIP <	jnz	noRelocDriverTab					>
	mov	di,offset GH_driverTabSegment
	call	ConvertIDToSegment
FXIP <noRelocDriverTab:							>

	inc	es:[geodeDriverCount]
	mov	al,DEBUG_LOAD_DRIVER	; notify debugger of driver load
	call	FarDebugProcess
	push	bp, ds, es
	mov	di,DR_INIT
	mov	si, ds:[GH_driverTabOff]
	mov	bx, ds:[GH_geodeHandle]
	mov	ds, ds:[GH_driverTabSegment]
	mov	cx, ss:[valueToPass1]
	mov	dx, ss:[valueToPass2]
CallDInit label	near
	ForceRef	CallDInit	; Make life easier for Swat
	call	ds:[si][DIS_strategy]		;call driver's init routine
	pop	bp, ds, es
	mov	ax,GLE_DRIVER_INIT_ERROR
	LONG jc	PGF_ret
	ornf	ds:[GH_geodeAttr],mask GA_DRIVER_INITIALIZED

	; if this is a system driver then add its strategy routine to the
	; list of system strategy routines

	test	ds:[GH_geodeAttr], mask GA_SYSTEM
	jz	notDriver2
	mov	di, es:[nextSystemDriver]
	cmp	di, offset systemDriverList + (size systemDriverList)
EC <	ERROR_Z	TOO_MANY_SYSTEM_DRIVERS					>
NEC <	jz	notDriver2						>
	mov	si, offset GH_driverTabOff
	movsw
	movsw
	mov	es:[nextSystemDriver], di

notDriver2:

	;if (Geode is a library) -> initialize library

	test	ds:[GH_geodeAttr],(mask GA_LIBRARY)
	jz	notLibrary

;	For XIP geodes, the library entry point is already relocated

FXIP <	test	ds:[GH_geodeAttr], mask GA_XIP				>
FXIP <	jnz	nullLibraryEntry					>

	cmp	ds:[GH_libEntrySegment],0	;check for null entry
	jz	nullLibraryEntry
	mov	di,offset GH_libEntrySegment
	call	ConvertIDToSegment
nullLibraryEntry:
	inc	es:[geodeLibraryCount]

	mov	al,DEBUG_LOAD_LIBRARY	; notify debugger of library load
	call	FarDebugProcess
	mov	di,LCT_ATTACH			;init the library
	mov	cx, ss:[valueToPass1]
	mov	dx, ss:[valueToPass2]
	call	CallLibraryEntry
	mov	ax,GLE_LIBRARY_INIT_ERROR
	jc	PGF_ret
	ornf	ds:[GH_geodeAttr],mask GA_LIBRARY_INITIALIZED


notLibrary:

if FAULT_IN_EXECUTABLES_ON_FLOPPIES
	; The swat stub always sets GA_KEEP_FILE_OPEN so that it can
	; get to the file to step through discarded resources.

	tst	ds:[GH_geoHandle]
	jnz	noStubFixup
	andnf	ds:[GH_geodeAttr], not mask GA_KEEP_FILE_OPEN
noStubFixup:
endif

	; Set up process stuff

	call	DoGeodeProcess

	clc				;return no error
PGF_ret:
	; remove hacked reference from the start of this here
	; function. Doesn't affect the carry, of course. -- ardeb
	dec	ds:[GH_geodeRefCount]

	.leave
	ret

ProcessGeodeFile	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	AddGeodeToList

DESCRIPTION:	Add a GEODE to the GEODE list

CALLED BY:	ProcessGeodeFile

PASS:
	exclusive access to GEODE list
	ds - core block of GEODE to add (locked)
	es - kernel variables

RETURN:

DESTROYED:
	ax, bx, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

AddGeodeToList	proc	near	uses ds
	.enter

	mov	cx, ds:[GH_geodeHandle]
	mov	ds:[GH_nextGeode], 0
	segmov	ds, es				;ds = idata

	inc	ds:[geodeCount]
	mov	bx, ds:[geodeListPtr]	;get pointer to first process

ACTL_loop:
	call	MemLock
	mov	ds, ax
	mov	ax, ds:[GH_nextGeode]
AXIP <	cmp	ax, cx			; if XIP, geode after kernel	>
AXIP <	je	done			; ...is already linked in	>
	tst	ax
	jz	foundEnd
	call	MemUnlock
EC <	call	NullDS							>
	mov_trash	bx, ax
	jmp	ACTL_loop

foundEnd:
	mov	ds:[GH_nextGeode], cx
	call	MemUnlock
AXIP <done:								>
	.leave
	ret
AddGeodeToList	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertIDToSegment

DESCRIPTION:	Convert a resource ID to a segment (or to a handle shifted
		right 4 times) in a geode's core block

CALLED BY:	ProcessGeodeFile, RelocateExportTable

PASS:
	di - offset of field to convert
	ds - core block (locked)

RETURN:
	field - converted

DESTROYED:
	si, ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Tell DoRelocation we've got a geode segment relocation at the
	indicated address. This ensures consistency in the system (in
	contrast to when this would figure out its own self what to store
	and I forgot to change it when MAX_SEGMENT came into vogue...)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

ConvertIDToSegment	proc	near 	uses bx, dx, bp, es
	.enter

	clr	bp		;pass zero are block relocation is relative to
				;so that it never matches

	segmov	es, ds
	mov	bx, di
	mov	al,(GRS_RESOURCE shl offset GRI_SOURCE) or GRT_SEGMENT
	call	DoRelocation
	mov	di, bx
	.leave
	ret
ConvertIDToSegment	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DoGeodeProcess

DESCRIPTION:	Do process initialization for GeodeLoad

CALLED BY:	INTERNAL
		LoadGeodeAfterFileOpen

PASS:
	ss:bp - stack frame inherited from LoadGeodeAfterFileOpen
	ds - core block for new Geode (locked)
	es - kernel variables

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if (Geode is a process) -> initialize process

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

DoGeodeProcess	proc	near
	.enter	inherit	LoadGeodeAfterFileOpen

	;if (Geode is a process) -> initialize process

	test	ds:[GH_geodeAttr], mask GA_PROCESS
	jz	notProcess

	; initialize class table pointer

	;On XIP systems, the TPD_classPointer fields are already initialized
	; unless the geode is patched

if USE_BUG_PATCHES
FXIP <	tst	ds:[GH_generalPatchData]				>
FXIP <	jnz	10$							>
endif
FXIP <	test	ds:[GH_geodeAttr], mask GA_XIP				>
FXIP <	jnz	copyFileHandles						>
FXIP <	10$:								>

	mov	dx, ss:[execHeader].EFH_classPtr.offset
	mov	si, ss:[execHeader].EFH_classPtr.segment
	shl	si,1			;index into handle table
	add	si,ds:[GH_resHandleOff]
	mov	si,ds:[si]
	mov	cx,es:[si].HM_addr		;cx = segment

	push	ds
	mov	bx,ds:[GH_resHandleOff]		;get first resource (dgroup)
	mov	bx,ds:[bx][2]
	mov	ds,es:[bx].HM_addr		;ds = dgroup for new process
	mov	ds:[TPD_classPointer].segment,cx
	mov	ds:[TPD_classPointer].offset,dx
	pop	ds

	;initialize UI stuff

	call	DoGeodeObjects

FXIP <copyFileHandles:						>
	;
	; initialize standard file handles.  If the current thread is
	; the kernel's thread, then initialize the std file handles to zero.
	;

	cmp	es:[currentThread], 0

	push	es				; kdata
	segmov	es, ds				; core block
	mov	di,offset PH_stdFileHandles
	mov	cx,NUMBER_OF_STANDARD_FILES
	je	fromKernel

	mov	bx, ss:[TPD_processHandle]
	call	MemLock
	mov	ds, ax
	mov	si, di
	rep	movsw		
	call	MemUnlock
	jmp	afterFiles
fromKernel:
	clr	ax
	rep	stosw
afterFiles:
	segmov	ds, es				; core block
	pop	es				; kdata
	

	; pass parameters, including words to send with MSG_META_ATTACH

	push	bp
	mov	ax,word ptr ss:[flagsAndPrio]
	mov	cx,ss:[valueToPass1]	 ;value to pass in init
	mov	dx,ss:[valueToPass2]
	call	ProcCreate
	pop	bp

notProcess:
	.leave
	ret

DoGeodeProcess	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	InitResources

DESCRIPTION:	Initialize resources for a Geode

CALLED BY:	LoadGeodeAfterFileOpen

PASS:
	file pointing at resource table
	ss:bp - stack frame inherited from LoadGeodeAfterFileOpen
	ds - core block for new Geode (locked)
	es - kernel variables

RETURN:
	carry - set if error
	if error:
		ax - error code (GeodeLoadError):
			GLE_FILE_READ_ERROR
			GLE_NOT_MULTI_LAUNCHABLE

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	NOTE: The resource handle table is initially all 0
	Read in resource table
	Read in allocation flags table
	Call FindMatchingGeode to determine if another instance of this Geode
		is loaded
	if (another instance exists)
		copy its resource handles
	allocate handles for each resource
	load in each resource

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

------------------------------------------------------------------------------@


InitResources	proc	near
	.enter	inherit LoadGeodeAfterFileOpen

if FAULT_IN_EXECUTABLES_ON_FLOPPIES

	; If the executable is on removable media then we want to load
	; in all resources of the executable and close the executable
	; file, so that we don't get stuck in horrible disk swapping
	; situations.
	;
	; To do this we check if the file is on removable media and if it
	; is we clear the GA_KEEP_FILE_OPEN flag.  This causes the file
	; to be closed at the end of LoadGeodeLow.
	;
	; To ensure the resources are loaded in we do a check further down
	; in the routine.

	mov	bx, ds:[GH_geoHandle]
	call	FileGetDiskHandle		;bx = disk handle
	call	DiskGetDrive			;al = 0 based drive number
	call	DriveGetStatusFar		;ah = DriveStatus
	test	ah, mask DS_MEDIA_REMOVABLE
	jz	notRemovable


	andnf	ds:[GH_geodeAttr], not mask GA_KEEP_FILE_OPEN
notRemovable:
endif

	; Set the offset to the resource handle table.
	; 	(Export entry table offset + 4 * number of entries.)

	; Read in resource table and set offsets
	;	resource table at (exportEntryOffset + 4*#exported)

	mov	ax,ds:[GH_exportEntryCount]
	shl	ax,1			;*2
	shl	ax,1			;*4
	add	ax,ds:[GH_exportLibTabOff]
	mov	ds:[GH_resHandleOff],ax
	mov	dx,ax			; For FileRead, below.

	; Set the offset to the resource position table.

	mov	cx,ds:[GH_resCount]
	shl	cx,1			;cx = #resources * 2
	add	ax,cx
	mov	ds:[GH_resPosOff],ax

	; Set the offset to the resource relocation size table.

	shl	cx,1			;cx = #resources * 4
	add	ax,cx
	mov	ds:[GH_resRelocOff],ax

	; Read in the resource table from the geode file.

	shl	cx,1			;cx = #resources * 8
	mov	bx,ds:[GH_geoHandle]
	clr	al
	call	FileReadFar
	mov	ax, GLE_FILE_READ_ERROR
	LONG jc exit

if USE_BUG_PATCHES
	tst	ds:[GH_generalPatchData]
	jz	afterPatchCoreBlock
	call	GeodePatchCoreBlock
afterPatchCoreBlock:
endif

	; Read allocation flags into local variable space

	mov	cx,ds:[GH_resCount]	;calculate table size
	mov	ss:[temporary],cx	;allocation loop counter
	shl	cx,1
	mov	dx,sp
	sub	sp,cx
	mov	di,sp			;allocate local variables, di = BOTTOM
	push	dx			;save stack ptr before locals

	push	ds			;read into stack
	segmov	ds,ss
	mov	dx,di
	clr	al
if USE_BUG_PATCHES
	mov	cx, ss:[execHeader].EFH_resourceCount
	shl	cx
endif
	call	FileReadFar
	pop	ds
	mov	ax, GLE_FILE_READ_ERROR
	LONG	jc	done
if USE_BUG_PATCHES
	tst	ds:[GH_generalPatchData]
	jz	afterPatchAllocationFlags

	; Copy allocation flags for any new resources onto the stack.

	call	GeodePatchReadAllocationFlags	
afterPatchAllocationFlags:
endif

	; Check if another instance of the geode has been loaded.

	call	FindMatchingGeode
	mov	ss:[otherInstance],ax	; Store result.
	jnc	noMatch			; No other instances.

	; Another instance exists.  Make sure the Geode is multi-launchable.

	test 	ds:[GH_geodeAttr], mask GA_MULTI_LAUNCHABLE
	stc
	LONG jz	mlError

	; Launch another instance of the geode...

	; Do we need to keep a file handle around for this geode?

	test	ds:[GH_geodeAttr], mask GA_KEEP_FILE_OPEN
	jz	noCloseFile		; We will be closing the file,
					; so no need to share.

	; Close the geode file we opened.

	mov	es,ax			; es = matching geode handle.
	clr	bx
	xchg	bx,ds:[GH_geoHandle]
	mov	al,FILE_NO_ERRORS
	call	FileCloseFar

	; Use the same handle the other instance is using.

	mov	ax,es:[GH_geoHandle]
	mov	ds:[GH_geoHandle],ax

noCloseFile:
	LoadVarSeg	es

noMatch:
	; This is the only instance of this geode.

	; Prepare to initialize each resource.

	clr	si		; Start at 0, fall through to increment so that
				; first resource (core block) is skipped.

	mov	ax,ds:[GH_geodeHandle]
	mov	bx,ds:[GH_resHandleOff]		; But set the handle for the
	mov	ds:[bx],ax			; core block to be correct.

	; For each resource:
	;	Allocate handle for it using flags from table.

allocLoop:
	inc	si
	inc	si	; Offset into resource handle table.
	inc	di
	inc	di	; Offset of current allocation flag on the stack.

	dec	ss:[temporary]		; Resources left to process.
	jz	doneAlloc		; EXIT LOOP.

	mov	bx,ds:[GH_resHandleOff]
	mov	ax,ds:[bx][si]		; Load size of module.
	mov	cx,ss:[di]		; Load allocation flags.

	; If the resource can be modified, we need to read in our own
	; copy of it.

	test	ch, mask HAF_READ_ONLY
	jz	noShare			; Can be modified.

	; This is a read-only resource.  If another instance of the
	; geode exists, we can use its copy of this resource.

	cmp	ss:[otherInstance],0
	jz	noShare			; No other instances.

	; Another instance of this geode already exists, so share
	; this resource with it.

	push	ds			; Get handle from other instance.
	mov	ds,ss:[otherInstance]
	mov	ax,ds:[bx][si]
	pop	ds
	mov	ds:[bx][si],ax
	jmp	allocLoop

noShare:
	; Allocate a handle for the resource.  If it should be
	; pre-loaded, allocate space for it.

	call	AllocateResource
	jnc	allocLoop		; Success!  Process next resource.

errorLoop:

	; Allocation error -- go in reverse order to free resources.

	dec	si
	dec	si
	jz	30$
	mov	bx, ds:[GH_resHandleOff]
	mov	bx, ds:[bx][si]		;get handle
EC <	ornf	es:[bx].HM_flags, mask HF_SHARABLE; defeat EC code	>
	call	MemFree
	jmp	errorLoop
30$:
	stc
	mov	ax, GLE_MEMORY_ALLOCATION_ERROR
	jmp	doneUnlockMatchingGeode

doneAlloc:

	; pre-load resources that need to be pre-loaded

	call	PreLoadResources

doneUnlockMatchingGeode:
	pushf
	mov	cx, ss:[otherInstance]
	jcxz	noOtherInstanceToUnlock
	push	ds
	mov	ds, cx
	mov	bx, ds:[GH_geodeHandle]
	call	MemUnlock
	pop	ds
noOtherInstanceToUnlock:
	; be sure to return client geode's handle else matching geode's
	; core block may be freed...
	mov	bx, ds:[GH_geodeHandle]
	popf
done:
	pop	cx
	mov	sp,cx			;recover local space
exit:
	.leave
	ret

mlError:
	mov	ax,GLE_NOT_MULTI_LAUNCHABLE
	jmp	doneUnlockMatchingGeode

InitResources	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AllocateResource

yDESCRIPTION:	Allocate a handle for a resource and, if it should be
		pre-loaded, allocate space for it.

CALLED BY:	INTERNAL
		InitResources, GeodePatchXIPInitResources

PASS:
	si - resource number * 2
	ss:bp - stack frame inherited from LoadGeodeAfterFileOpen
		(only needed if si = 2)

	ax - size of resource
	bx - GH_resHandleOff
	cx - allocation flags
	ds - core block for new Geode
	es - kernel variables

RETURN:
	carry - set if error
	if no error:
		ax - block allocated
		ds:[si][bx],ax - slot in GeodeHeader for handle

DESTROYED:
	cx, dx

REGISTER/STACK USAGE:
	di - points at local variables

PSEUDO CODE/STRATEGY:
	Allocate handle for it using flags from table

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

------------------------------------------------------------------------------@

AllocateResource	proc	near
	.enter	inherit LoadGeodeAfterFileOpen

if USE_PATCHES
	call	GeodeGetPatchedResourceSize
endif
		
	; if allocating the first resource then add the uninitialized data size

	cmp	si,2
	jnz	notIdata
	add	ax,ss:[execHeader].EFH_udataSize
	or	ch, mask HAF_ZERO_INIT
notIdata:

	push	cx
	tst	ax
	jnz	10$
	inc	ax				;allocate at least 1 byte
10$:
	; Allocate space for the resource if it should be preloaded.
	; Otherwise (if HF_DISCARDED is passed), only a handle will 
	; allocated.

	call	MemAllocFar
	pop	cx
	jc	done

	; if an object block then set the burden thread.  The burden thread
	; is either the first thread of the process or the second, its
	; UI thread.  Since neither threads have been created yet, we store
	; -1 in the otherInfo field to indicate that the first thread, and -2
	; to indicate the second.

	test	ch,mask HAF_OBJECT_RESOURCE
	jz	notObjectResource

	mov	ax, -1				;assume first thread of process
	test	ch,mask HAF_UI
	jz	setBurden
	dec	ax				;otherwise, use 2nd (UI) thread
setBurden:
	mov	es:[bx].HM_otherInfo,ax	;store thread to execute
notObjectResource:

	mov	dx,ds:[GH_geodeHandle]		;set owner to new geode
	mov	es:[bx][HM_owner],dx

	mov	ax,bx				;save handle of new block
	mov	bx,ds:[GH_resHandleOff]
	mov	ds:[si][bx],ax			;save resource handle
	clc
done:
	.leave
	ret

AllocateResource	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	PreLoadResources

DESCRIPTION:	Pre-load resources that are not shared and not discarded

CALLED BY:	INTERNAL
		InitResources

PASS:
	ss:bp - stack frame inherited from LoadGeodeAfterFileOpen
	ds - core block for new geode
	es - kernel variables

RETURN:
	carry - set if error

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
------------------------------------------------------------------------------@

PreLoadResources	proc	near
	.enter	inherit	LoadGeodeAfterFileOpen
	; load dgroup specially

	;
	; Gain exclusive access to the file handle for the duration, as
	; another instance of the geode could be using it, and we need
	; to be sure the read/write position is ours to mess with.
	;
	call	GLLoadResourcePrelude

	mov	bx,ds:[GH_resHandleOff]		;get address of size table
	mov	bx,ds:[bx][2]			;get handle
	mov	ax,es:[bx].HM_addr		;address

	mov	cx,es:[bx].HM_size
	shl	cx,1
	shl	cx,1
	shl	cx,1
	shl	cx,1


if 	FULL_EXECUTE_IN_PLACE
	test	ds:[GH_geodeAttr], mask GA_XIP
	jz	haveDgroupSize

;	Init the udata portion to zero (we have to do this manually on XIP
; 	systems

	mov	di, es:[bx].HM_otherInfo	;DI <- size of idata/ptr to
						; first byte of udata
	sub	cx, di				;CX <- # bytes to init to zero

	push	es
	mov	es, ax				;ES:DI <- udata resource
	clr	al
	rep	stosb
	mov	ax, es
	pop	es
	mov	cx, es:[bx].HM_otherInfo
	jmp	loadDgroup
haveDgroupSize:

else
EC <	test	ds:[GH_geodeAttr], mask GA_XIP				>
EC <	ERROR_NZ	CANNOT_LOAD_XIP_GEODE_ON_NON_XIP_SYSTEM		>
endif
	; correct for the fact that unitialized data is in the block but
	; not stored in the file

	sub	cx,ss:[execHeader].EFH_udataSize
	and	cx,not 15
FXIP <loadDgroup:							>
	mov	si,2				;resource #1
	mov	dx, bx
	push	bp
	mov	bp, dx
	call	DoLoadResource
	pop	bp

	mov	cx,ds:[GH_resCount]
	dec	cx			; don't count core block
	dec	cx			;  and dgroup already loaded
	LONG jz	PLR_ret
	mov	ss:[temporary],cx	;counter
	mov	si,4			;skip core block and dgroup

	;For each resource:
	;	Load resource if not discarded

loadLoop:
	mov	bx,ds:[GH_resHandleOff]
	mov	ax,ds:[bx][si]
	mov	dx,ss:[otherInstance]  ;another instance ?
	tst	dx
	jz	mightLoad			;if not then try loading

	push	ds				; else see if resource shared
	mov	ds,dx				;  between instances
	cmp	ax,ds:[bx][si]
	pop	ds
	LONG jz	loaded				; yes => don't touch it

mightLoad:
	;
	; Lock the thing down if we might need to load it in and it's not
	; fixed.
	; 
	call	swapESDS		;ds = kdata, es = core block
	mov_tr	bx, ax
	mov	ax, ds:[bx].HM_addr
	test	ds:[bx].HM_flags, mask HF_FIXED
	LONG jnz loadIt				;branch with carry clear
	cmp	ds:[bx].HM_lockCount, LOCK_COUNT_MOVABLE_PERMANENTLY_FIXED
	LONG jz	loadIt				;branch with carry clear

	call	FarFullLockNoReload
	cmc
if	FULL_EXECUTE_IN_PLACE
EC <	jnc	10$							>
EC <	pushf								>
EC <	test	es:[GH_geodeAttr], mask GA_XIP				>
EC <	ERROR_NZ	PRE_LOADING_NON_FIXED_RESOURCE_IN_XIP_GEODE	>
EC <	popf								>
EC <10$:								>
endif
	LONG jc	loadIt				; => not discarded, so load,
						;  noting block needs unlocking

if FAULT_IN_EXECUTABLES_ON_FLOPPIES

	; If the executable is on removable media then we must load the data
	; and the relocations to be loaded into a special block so that we
	; can use them later.
	;
	; We store this data in a block and store the handle in HM_usageValue.
	;
	; Both GeodeDuplicateResource and LockDiscardedResource then check for
	; this case and use the data in this handle instead of loading it

	test	es:[GH_geodeAttr], mask GA_KEEP_FILE_OPEN or mask GA_XIP
	jnz	notSpecialCase

faultIn::
	push	bx, si, ds, es
	call	swapESDS		;ds = kdata, es = core block

	push	es:[bx].HM_size		;save block size (in paragraphs)

	;Get file position from table, move to file position

	push	si
	shl	si			;resource number * 4
	add	si, ds:[GH_resPosOff]
	movdw	cxdx, ds:[si]		;put position in cx:dx
	pop	si

	mov	bx, ds:[GH_geoHandle]
	mov	al, FILE_POS_START
	call	FilePosFar		;call MS-DOS to move file pointer

	pop	ax			;ax = paragraph size
	shl	ax
	shl	ax
	shl	ax
	shl	ax			;ax <- # bytes in block

	add	si, ds:[GH_resRelocOff]
	add	ax, ds:[si]		;size of relocation table
	push	ax			;save size
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAllocFar		;bx = new handle
	pop	cx			;cx = block size
	mov	dx, ds:[GH_geodeHandle]	;set the owner of the new block
	mov	es:[bx].HM_owner, dx	;to be the new geode

	push	bx			;save new handle
	mov	bx, ds:[GH_geoHandle]	;bx = file handle
	mov	ds, ax			;ds = segment address to load into
	mov	al, FILE_NO_ERRORS
	clr	dx
	call	FileReadFar		;read in data and relocations
	pop	bx			;bx = special block handle
	call	MemUnlock
	mov_tr	ax, bx

	pop	bx, si, ds, es
	mov	ds:[bx].HM_usageValue, ax ;save special handle
notSpecialCase:

endif

	call	swapESDS			;ds = core block, es = kdata
	jmp	loaded
loadIt:
	call	swapESDS			;ds = core block, es = kdata

	;
	; Now load the resource in.
	; 
	pushf					;carry set if block locked
	mov	cx, bx				;resource we're loading into

;	If a resource lies on the heap, then load it. If it lies outside the
;	heap, then it lies in the fixed-read-only XIP resources, so don't
;	bother loading it.

FXIP <	cmp	ax, es:[loaderVars].KLV_heapEnd				>
FXIP <	jae	noLoad							>

if USE_PATCHES
	push	si
	; The patch code expects the handle of this block in SI so
	; that it can reallocate the block if necessary
	mov	si, cx
endif
	call	LoadResourceLow
if USE_PATCHES
	pop	si
endif


if FAULT_IN_EXECUTABLES_ON_FLOPPIES

	; If the executable is on removable media then we must make sure
	; the block never gets discarded

	test	ds:[GH_geodeAttr], mask GA_KEEP_FILE_OPEN or mask GA_XIP
	jnz	noClearDiscardable
	andnf	es:[bx].HM_flags, not mask HF_DISCARDABLE
noClearDiscardable:
endif

noLoad::
	popf
	;
	; Unlock the resource if we locked it before.
	; 
	jnc	loaded
	call	MemUnlock

loaded:
	inc	si
	inc	si
	dec	ss:[temporary]
	LONG jnz loadLoop

PLR_ret:
	;
	; Release exclusive access to the executable file.
	;
	call	GLLoadResourceEpilude

	clc
	.leave
	ret

swapESDS:
	segxchg	ds, es
	retn
PreLoadResources	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GLLoadResourcePrelude
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare to load a resource into memory, either into its
		own block or into another one.

CALLED BY:	(INTERNAL) PreLoadResources
PASS:		ds	= locked owner's core block
		es	= dgroup
RETURN:		library core blocks locked down
DESTROYED:	ax, bx, cx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GLLoadResourcePrelude proc	near
	.enter
if	MOVABLE_CORE_BLOCKS
	mov	si, ds:[GH_libOffset]
	mov	cx, ds:[GH_libCount]
	jcxz	grabFile
libLoop:
	lodsw
	mov_tr	bx, ax
	call	MemLock
	loop	libLoop
grabFile:
endif
	;
	; Gain the exclusive right to load a resource for this geode
	; by grabbing the threadlock whose handle is stored in the
	; executable's file handle. 
	; 
	mov	bx, ds:[GH_geoHandle]	; es:bx <- HandleFile
FXIP <	tst	bx							>
FXIP <	jz	exit							>

	; see LoadGeodeAfterFileOpen for comment on the semaphore to
	; threadlock change 
	mov	bx, es:[bx].HF_semaphore
	call	ThreadGrabThreadLock

exit::
	.leave
	ret
GLLoadResourcePrelude endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GLLoadResourceEpilude
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish loading a resource, unlocking that which was locked
		in LoadResourcePrelude

CALLED BY:	(INTERNAL) PreLoadResources
PASS:		ds	= locked owner's core block
		es	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GLLoadResourceEpilude proc	near
	.enter
	mov	bx, ds:[GH_geoHandle]
FXIP <	tst	bx							>
FXIP <	jz	noV							>

	; see LoadGeodeAfterFileOpen for comment on the semaphore to
	; threadlock change
	mov	bx, es:[bx].HF_semaphore
	call	ThreadReleaseThreadLock

noV::

if	MOVABLE_CORE_BLOCKS
	mov	si, ds:[GH_libOffset]
	mov	cx, ds:[GH_libCount]
	jcxz	done
libLoop:
	lodsw
	mov_tr	bx, ax
	call	MemUnlock
	loop	libLoop
done:
endif

	.leave
	ret

GLLoadResourceEpilude endp
	

COMMENT @----------------------------------------------------------------------

FUNCTION:	DoGeodeObjects

DESCRIPTION:	Do object initialization for GeodeLoad

CALLED BY:	INTERNAL
		DoGeodeProcess

PASS:
	ss:bp - stack frame inherited from LoadGeodeAfterFileOpen
	ds - core block for new Geode
	es - kernel variables

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
------------------------------------------------------------------------------@

DoGeodeObjects	proc	near
	.enter	inherit LoadGeodeAfterFileOpen

	mov	ax,ss:[execHeader].EFH_appObj.chunk
	tst	ax				;using objects ?
	jz	DGO_ret				;if no then return
	mov	ds:[PH_appObject].chunk,ax
	mov	bx,ss:[execHeader].EFH_appObj.handle
	shl	bx,1				;convert from ID to resource
	add	bx,ds:[GH_resHandleOff]
	mov	ax,ds:[bx]
	mov	ds:[PH_appObject].handle,ax

DGO_ret:
	.leave
	ret

DoGeodeObjects	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeAddReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Artificially add another reference to the passed geode.
		Useful for geodes wanting to make sure they don't go
		away until *they* say so (e.g. non-process libraries
		loaded during initialization)

CALLED BY:	GLOBAL
PASS:		bx	= handle of geode to which to add a reference
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeAddReference proc	far
		uses	ds, ax
		.enter
EC <		call	ECCheckGeodeHandle				>
		call	FarPGeode
		call	MemLock
		mov	ds, ax
		inc	ds:[GH_geodeRefCount]
		call	MemUnlock
EC <		call	NullDS						>
		call	FarVGeode
		.leave
		ret
GeodeAddReference endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeRequestSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if space is availible, and if so, submit reservation

CALLED BY:	GLOBAL
PASS:		cx - heap Space requested in k
		bx - geode handle for geode requesting space.  It must
			be an application.
RETURN:		carry cleared if request accepted
			bx - Reservation Token
		carry set if request denied
			bx - destroyed
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	2/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	NEVER_ENFORCE_HEAPSPACE_LIMITS

GeodeRequestSpace	proc	far
	clc				; always accept
	ret
GeodeRequestSpace	endp

else

GeodeRequestSpace	proc	far
valueToPass2	local word push bp  ; just to get frame set up properly
valueToPass1	local word
notAttribute	local word
attributes	local word
flagsAndPrio	local GeodeLoadFlagsAndPriority
otherInstance	local hptr
temporary	local word
execHeader	local ExecutableFileHeader
fileType	local GeosFileType
heapSpace	local word
currentGeode	local hptr
	uses	ax, di, si, cx, ds, es, dx
	.enter

	ForceRef valueToPass2
	ForceRef valueToPass1
	ForceRef notAttribute
	ForceRef attributes
	ForceRef flagsAndPrio
	ForceRef otherInstance
	ForceRef temporary
	ForceRef execHeader
	ForceRef fileType
	ForceRef heapSpace			;Temp variable fo HeapSpace

EC<	call	ECCheckGeodeHandle					>
	LoadVarSeg	es

	mov	ax, GGIT_ATTRIBUTES	; if the request does not come
	call	GeodeGetInfo		; from an app it is pointless
	test	ax, mask GA_APPLICATION	; to continue because its
	stc				; heapspace doesn't count anyway.
EC<	ERROR_Z ILLEGAL_RESERVATION			>
	jz	done

	mov	currentGeode, bx
retry:
	call	GeodeEnsureEnoughHeapSpaceCore
	jc	fail

	mov	bx, currentGeode
	LoadVarSeg	ds

	call	GeodeAddSpace

	call	MemIntAllocHandle
	mov	ds:[bx].HR_type, SIG_RESERVATION
	mov	ds:[bx].HR_size, ax
	clc
done:
	.leave
	ret

fail:
;
; OK.  We've tried to grab some heapspace and failed.  This could be
; because a bunch of apps are starting to detach, but haven't
; finished, and therefore seem to be taking up space but are
; undetachable.  What we'll do is look to see if anybody is in the
; process of detaching and if so, sleep for a bit.
;
	push	ax, bx, cx
	mov	bx, handle GCNListBlock
	call	MemPLock
	mov	ds, ax

	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TRANSPARENT_DETACH_IN_PROGRESS
	clc				; tell it not to make a list
					; if not found..
	call	FindGCNList		; carry clear if doesn't find it
	jnc	failPop

	call	ChunkArrayGetCount	; count in cx..

	clc
	jcxz	failPop
	stc

failPop:				; carry clear on error (none found)
	mov	bx, handle GCNListBlock
	call	MemUnlockV		; doesn't trash registers
	pop	ax, bx, cx
	cmc
	jc	done			; none found

;
; there were things detaching..  lets wait a while so they can finish.
;
	push	ax
	mov	ax, GEODE_REQUEST_SPACE_RETRY_WAIT_TIME
	call	TimerSleep
	pop	ax
	jmp	retry

GeodeRequestSpace	endp

endif	; NEVER_ENFORCE_HEAPSPACE_LIMITS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeReturnSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return heapspace reserved by HeapRequestSpace to
		general use

CALLED BY:	Global
PASS:		bx - Token returned by HeapRequestSpace
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	2/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	NEVER_ENFORCE_HEAPSPACE_LIMITS

GeodeReturnSpace	proc	far
	ret
GeodeReturnSpace	endp

else

GeodeReturnSpace	proc	far
	uses	ax, cx, bp, di, si, ds
	.enter
	LoadVarSeg	ds
EC<	call	ECCheckReservationHandle				>
	mov	bp, ds:[bx].HR_owner
	mov	ax, ds:[bx].HR_size
	call	FarFreeHandle

	mov	bx, bp
	neg	ax
	call	GeodeAddSpace
	
	.leave
	ret
GeodeReturnSpace	endp

endif	; NEVER_ENFORCE_HEAPSPACE_LIMITS

if	not NEVER_ENFORCE_HEAPSPACE_LIMITS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeAddSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds some space to the heapspace requirement of the geode.

CALLED BY:	Internal - GeodeRequestSpace & GeodeReturnSpace
PASS:		ax - space to add (or negate it to subtract..)
		bx - geode handle
		ds - kdata
RETURN:		nothing
DESTROYED:	di, si, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	2/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeAddSpace	proc	near
	.enter
	mov	di, ds:[geodeHeapVarsOffset]
	mov	si, offset geodeHeapVarsBuffer
	mov	cx, (size GeodeHeapVars)/2
	call	FarPheapVarBufSem
	call	GeodePrivRead
	add	ds:[si], ax
	call	GeodePrivWrite
	call	FarVheapVarBufSem
	.leave
	ret
GeodeAddSpace	endp

kcode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PheapVarBufSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	P's the heapVarBufSem semaphore - secures access to
		the heapVarBuffer (there's only one..) and grants
		single access to heapspace stuff (if you are totalling
		the heapspace in use, you should aquire it so nobody
		else does simulanteously).

CALLED BY:	heapspace stuff (GeodeRequestSpace, GeodeConsignSpace,
		GeodeEnsureEnoughHeapSpace, etc)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	2/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PheapVarBufSem	proc	near
	push	bx
	mov	bx, offset heapVarBufSem
	jmp	SysPSemCommon
PheapVarBufSem	endp

FarPheapVarBufSem	proc	far
	call	PheapVarBufSem
	ret
FarPheapVarBufSem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VheapVarBufSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	V's the heapVarBufSem semaphore - releases acces to
		the heapVarBuffer and general heapspace stuff

CALLED BY:	heapspace stuff (GeodeRequestSpace, GeodeConsignSpace,
		GeodeEnsureEnoughHeapSpace).
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (not even flags)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	2/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VheapVarBufSem	proc	near
	push	bx
	mov	bx, offset heapVarBufSem
	jmp	SysVSemCommon
VheapVarBufSem	endp

FarVheapVarBufSem	proc	far
	call	VheapVarBufSem
	ret
FarVheapVarBufSem	endp
kcode	ends

endif	; not NEVER_ENFORCE_HEAPSPACE_LIMITS

GLoad	ends
