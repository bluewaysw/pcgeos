COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	File Managers
MODULE:		Installable Tools -- Tool Manager object
FILE:		ctoolToolMgr.asm

AUTHOR:		Adam de Boor, Aug 25, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	8/25/92		Initial revision


DESCRIPTION:
	Implementation of ToolManager class
		

	$Id: ctoolToolMgr.asm,v 1.1 97/04/04 15:02:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ToolCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMMangleActiveList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add or remove ourselves from the active list, depending on
		what the caller tells us to do.

CALLED BY:	(INTERNAL) TMSpecBuild, TMDetach
PASS:		*ds:si	= ToolManager object
		ax	= MSG_META_GCN_LIST_ADD or MSG_META_GCN_LIST_REMOVE
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:	object added to or removed from the app's active list

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMMangleActiveList proc	near
		class	ToolManagerClass
		.enter
		mov	dx, size GCNListParams
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST
		mov	bx, ds:[LMBH_handle]
		mov	ss:[bp].GCNLP_optr.handle, bx
		mov	ss:[bp].GCNLP_optr.chunk, si
		push	si
		clr	bx		; current thread...
		call	GeodeGetAppObject
		mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
		call	ObjMessage
		pop	si
		add	sp, size GCNListParams
		.leave
		ret
TMMangleActiveList endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMProcessTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process an individual FMToolStruct, creating the ToolTrigger
		object for the beast, etc.

CALLED BY:	(INTERNAL) TMProcessLibrary
PASS:		*ds:si	= ToolManager
		es:di	= FMToolStruct
		dx	= index of library in ToolManager's array
		bp	= tool index within the library of this tool
RETURN:		nothing
DESTROYED:	ax, bx, bp
SIDE EFFECTS:	an ignoreDirty ToolTrigger will be created and initialized
			and added as the final child

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMProcessTool 	proc	near
		class	ToolManagerClass
		uses	dx, di, cx, es
setupArgs	local	ToolTriggerSetupArgs \
		push	bp,		; TTSA_number
			dx,		; TTSA_library
			es, di		; TTSA_toolStruct
		.enter
	;
	; Create the object.
	; 
		segmov	es, <segment ToolTriggerClass>, di
		mov	di, offset ToolTriggerClass
		mov	bx, ds:[LMBH_handle]
		push	bp, si
		call	GenInstantiateIgnoreDirty
	;
	; Initialize it.
	; 
		lea	bp, ss:[setupArgs]
		mov	dx, size setupArgs
		mov	ax, MSG_TT_SETUP
		call	ObjCallInstanceNoLock
	;
	; Add it as our last child.
	; 
		mov	dx, si
		mov	cx, ds:[LMBH_handle]	; ^lcx:dx <- ToolTrigger
		pop	si			; *ds:si <- ToolManager
		
		mov	ax, MSG_GEN_ADD_CHILD
		mov	bp, CCO_LAST
		call	ObjCallInstanceNoLock
	;
	; Tell the thing the most-recent selection state we received.
	; 
		push	si
		mov	si, ds:[si]
		add	si, ds:[si].ToolManager_offset
		mov	cx, ds:[si].TMI_selectState
		mov	si, dx			; *ds:si <- ToolTrigger
		mov	ax, MSG_TT_SET_FILE_SELECTION_STATE
		call	ObjCallInstanceNoLock
	;
	; Set the thing usable. Update mode is manual, as we're in the process
	; of building; the update will be done when that's complete.
	; 
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_MANUAL
		call	ObjCallInstanceNoLock
		pop	bp, si
		.leave
		ret
TMProcessTool 	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMProcessLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a single tool library we found

CALLED BY:	(INTERNAL) TMProcessLibraries
PASS:		*ds:si	= ToolManager object
		*ds:di	= array to which we're adding ToolLibrary structs
		es:dx	= FileLongName of next library to process
RETURN:		nothing
DESTROYED:	ax, bp
SIDE EFFECTS:	a new ToolLibrary structure is appended to the array

PSEUDO CODE/STRATEGY:
		Figure index of this library (it's the count of things in the
		    array currently)
		Append a ToolLibrary structure
		Copy the name in.
		Load the library.
		Ask it for its tool table
		Foreach tool:
			Instantiate a new ToolTrigger object (ignore dirty)
			set it up
			add it as last child
			set it usable, with manual update

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMProcessLibrary proc	near
		class	ToolManagerClass
		uses	bx, cx, dx, es, di
		.enter
	;
	; Figure index of the library
	; 
		push	si			; save tool manager
		mov	si, di
		call	ChunkArrayGetCount
	;
	; Append new descriptor to the array.
	; 
		push	cx			; save library index for setup
		call	ChunkArrayAppend
	;
	; Copy in the file name.
	; 
		segxchg	ds, es
		push	si
		mov	si, dx
		mov	cx, size FileLongName
		CheckHack <offset TL_name eq 0 and \
				size TL_name eq size FileLongName>
		rep	movsb
	;
	; Load in the library.
	; 
		mov	bx, FMTOOL_PROTO_MINOR
		mov	ax, FMTOOL_PROTO_MAJOR
		mov	si, dx
		call	GeodeUseLibrary
		pop	si
		segmov	ds, es
		jc	loadFailed
		
		CheckHack <offset TL_handle eq offset TL_name + size TL_name>
		mov	ds:[di], bx
	; sp -> index, tmchunk
	; ds = name block
	; es = object block
	;
	; Ask the library what tools it has to provide.
	; 
		mov	ax, GGIT_ATTRIBUTES
		call	GeodeGetInfo
		push	ax
		test	ax, mask GA_ENTRY_POINTS_IN_C
		jnz	fetchToolsFromCLibrary

		mov	ax, FMTF_FETCH_TOOLS
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable	; cx <- # tools, es:di <- array

haveToolTable:
EC <		tst	cx						>
EC <		ERROR_Z	IMPORTED_TOOL_LIBRARY_PROVIDES_NO_TOOLS		>
	;
	; Loop over all the tools, processing each in turn.
	; 
		pop	ax		; ax <- library GeodeAttrs
		pop	dx		; dx <- library index
		pop	si		; *ds:si <- tool manager
		push	ax		; save library GeodeAttrs
		push	bx		;  and possible original segment
					;  for unlock
		clr	bp
toolLoop:
		call	TMProcessTool
		add	di, size FMToolStruct
		inc	bp
		loop	toolLoop
	;
	; Unlock the table if we locked it.
	; 
		pop	bx
		pop	ax
		test	ax, mask GA_ENTRY_POINTS_IN_C
		jz	done
		call	MemUnlockFixedOrMovable
done:
		.leave
		ret
loadFailed:
	;
	; Couldn't load the library, so nuke the entry we created for it.
	; 
		sub	di, size FileLongName
		call	ChunkArrayDelete
		pop	cx
		pop	si
		jmp	done

fetchToolsFromCLibrary:
		sub	sp, 4			; make room for return of
						;  far pointer
		mov	ax, sp
		push	ss, ax			; pass address of room on stack
		mov	ax, FMTF_FETCH_TOOLS
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable

		mov_tr	cx, ax			; cx <- # tools
		pop	bx, di			; bx:di <- virtual fptr
		call	MemLockFixedOrMovable
		mov	es, ax			; es:di <- actual fptr to table
		jmp	haveToolTable
TMProcessLibrary endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMProcessLibraries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the buffer of tools FileEnumPtr returned to us.

CALLED BY:	(INTERNAL) TMSpecBuild
PASS:		*ds:si	= ToolManager object
		^hbx	= array of FileLongNames of found libraries
		cx	= number of libraries found
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	block is freed, ToolLibrary descriptors are added to the
     		array pointed to by the TMI_tools instance variable.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMProcessLibraries proc	near
		class	ToolManagerClass
		.enter
	;
	; Fetch the chunk of the array we'll build.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].ToolManager_offset
		mov	di, ds:[di].TMI_tools
	;
	; Lock down the block of names.
	; 
		call	MemLock
		mov	es, ax
		clr	dx
	;
	; Loop over all the names, processing each in turn.
	; 
toolLoop:
		call	TMProcessLibrary
		add	dx, size FileLongName
		loop	toolLoop
	;
	; Free the block o' names
	; 
		call	MemFree
		.leave
		ret
TMProcessLibraries endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build up the list of tools found in [SP_SYSTEM]\FILEMGR

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= ToolManager object
		ds:di	= ToolManagerInstance
		bp	= SpecBuildFlags
RETURN:		nothing
DESTROYED:	allowed: ax, cx, dx, bp
SIDE EFFECTS:	lots o' hooey

PSEUDO CODE/STRATEGY:
		push to [SP_SYSTEM]\FILEMGR
		call FileEnum to locate all geodes with FMTL as token chars
		foreach geode:
			load the library
			ask it for its table of tools.
			foreach tool:
				create a ToolTrigger object
				set it up
				add as child
				set usable with manual update
			unload library?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString systemSubdir <C_BACKSLASH, "FILEMGR", 0>
		 		; Subdirectory of SP_SYSTEM to find tools

tmsbEnumParams	FileEnumParams <
	mask FESF_GEOS_EXECS,				; FEP_searchFlags
	FESRT_NAME,					; FEP_returnAttrs
	size FileLongName,				; FEP_returnSize
	tmsbMatchAttrs,					; FEP_matchAttrs
	FE_BUFSIZE_UNLIMITED				; FEP_bufSize
>

tmsbMatchAttrs	FileExtAttrDesc \
	<FEA_TOKEN, toolToken, size GT_chars>,	; match GT_chars, only
	<FEA_END_OF_LIST>


if FULL_EXECUTE_IN_PLACE
FixedCode	segment	resource
else
idata	segment
endif

toolToken	GeodeToken <<'FMTL'>, 0>

if FULL_EXECUTE_IN_PLACE
FixedCode	ends
else
idata	ends
endif

TMSpecBuild	method dynamic ToolManagerClass, MSG_SPEC_BUILD
		uses	bp, es
		.enter
	;
	; Push to directory in which we'll find the tools.
	; 
		call	FilePushDir
		mov	bx, SP_SYSTEM
		push	ds
		segmov	ds, cs
		mov	dx, offset systemSubdir
		call	FileSetCurrentPath
		jnc	doEnum
enumFailed:
		pop	ds
		jmp	callSuper
doEnum:
		push	si
		mov	si, offset tmsbEnumParams
		call	FileEnumPtr
		pop	si
		jc	enumFailed
		jcxz	enumFailed
		pop	ds
	;
	; Now process all those files we found.
	; 
		call	TMProcessLibraries
callSuper:
	;
	; Return to previous directory.
	; 
		call	FilePopDir
	;
	; Add ourselves to the active list so we can be sure to unload all
	; the libraries we've loaded before the app goes away.
	; 
		mov	ax, MSG_META_GCN_LIST_ADD
		call	TMMangleActiveList
		.leave
	;
	; Let our superclass actually do all the building that needs to take
	; place, now we've created all the kids we need to create.
	; 
		mov	ax, MSG_SPEC_BUILD
		mov	di, offset ToolManagerClass
		GOTO	ObjCallSuperNoLock
TMSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMSetFileSelectionState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell our children whether there are any files or directories
		selected.

CALLED BY:	MSG_TM_SET_FILE_SELECTION_STATE
PASS:		*ds:si	= ToolManager object
		cx	= non-zero if anything is selected
RETURN:		nothing
DESTROYED:	allowed: ax, cx, dx, bp
SIDE EFFECTS:	things might be enabled or disabled

PSEUDO CODE/STRATEGY:
		Just call our generic children, passing the info along

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMSetFileSelectionState method dynamic ToolManagerClass, MSG_TM_SET_FILE_SELECTION_STATE
		.enter
		mov	ds:[di].TMI_selectState, cx
		mov	ax, MSG_TT_SET_FILE_SELECTION_STATE
		call	GenSendToChildren
		.leave
		ret
TMSetFileSelectionState endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMActivateToolOnProcessThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the appropriate routine in the tool library on the
		process thread, rather than here on the UI thread.

CALLED BY:	MSG_TM_ACTIVATE_TOOL_ON_PROCESS_THREAD
PASS:		*ds:si	= ToolManager object
		cx	= library number
		bp	= routine number to call
		dx	= tool number (within library) that was activated
RETURN:		nothing
DESTROYED:	allowed: ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMActivateToolOnProcessThread method dynamic ToolManagerClass, MSG_TM_ACTIVATE_TOOL_ON_PROCESS_THREAD
		.enter
	;
	; Point to the ToolLibrary structure for the beast.
	; 
		mov_tr	ax, cx
		mov	si, ds:[di].TMI_tools
		call	ChunkArrayElementToPtr
	;
	; Fetch out the library handle and queue a message to our process
	; asking it to contact the library in question.
	; 
		mov	cx, ds:[di].TL_handle
		mov	si, bp
		mov	ax, MSG_DESKTOP_CALL_TOOL_LIBRARY
		call	GeodeGetProcessHandle
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		.leave
		ret
TMActivateToolOnProcessThread endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unload any libraries we loaded before acknowledging the
		detach.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= ToolManager object
		ds:di	= ToolManagerInstance
		cx	= caller's ID
		dx:bp	= callers OD
RETURN:		nothing
DESTROYED:	allowed: ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMDetach	method dynamic ToolManagerClass, MSG_META_DETACH
		uses	cx, dx, bp, si, ax
		.enter
		push	si
		mov	si, ds:[di].TMI_tools
		mov	bx, cs
		mov	di, offset TMD_callback
		call	ChunkArrayEnum
	;
	; Remove ourselves from the app's active list so we don't get brought
	; in on start-up.
	; 
		pop	si
		mov	ax, MSG_META_GCN_LIST_REMOVE
		call	TMMangleActiveList

		.leave
		mov	di, offset ToolManagerClass
		GOTO	ObjCallSuperNoLock
TMDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMD_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to unload all tool libraries we loaded,
		before the app goes away

CALLED BY:	TMDetach via ChunkArrayEnum
PASS:		*ds:si	= chunk array
		ds:di	= ToolLibrary
RETURN:		carry set to stop enumerating
DESTROYED:	allowed: ax, bx, cx, dx, bp, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMD_callback	proc	far
		.enter
		clr	bx
		xchg	bx, ds:[di].TL_handle
		tst	bx
		jz	done
		call	GeodeFreeLibrary
done:
		clc			; keep iterating
		.leave
		ret
TMD_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolManagerRebuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	rebuild tool library list

CALLED BY:	MSG_TM_REBUILD

PASS:		*ds:si	= ToolManagerClass object
		ds:di	= ToolManagerClass instance data
		es 	= segment of ToolManagerClass
		ax	= MSG_TM_REBUILD

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/22/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolManagerRebuild	method	dynamic	ToolManagerClass, MSG_TM_REBUILD
	;
	; nuke current library references
	;
	push	si
	mov	si, ds:[di].TMI_tools
	mov	bx, cs
	mov	di, offset TMD_callback
	call	ChunkArrayEnum
	pop	si
	;
	; nuke tool triggers
	;
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	bp, 0
	call	GenSendToChildren
	;
	; set not usable then usable, causing SPEC_BUILD when necessary
	;
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	ret
ToolManagerRebuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToolManagerRebuildIfOnDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	rebuild tool library list if a library is on passed disk

CALLED BY:	MSG_TM_REBUILD_IF_ON_DISK

PASS:		*ds:si	= ToolManagerClass object
		ds:di	= ToolManagerClass instance data
		es 	= segment of ToolManagerClass
		ax	= MSG_TM_REBUILD

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/22/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToolManagerRebuildIfOnDisk	method	dynamic	ToolManagerClass,
						MSG_TM_REBUILD_IF_ON_DISK
	;
	; nuke current library references
	;
	push	si
	mov	si, ds:[di].TMI_tools
	mov	bx, cs
	mov	di, offset TMRIOD_callback
	call	ChunkArrayEnum
	pop	si
	jnc	done				; no match found
	mov	ax, MSG_TM_REBUILD		; else, match -> rebuild
	call	ObjCallInstanceNoLock
done:
	ret
ToolManagerRebuildIfOnDisk	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMRIOD_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to check if library is on disk being
		removed

CALLED BY:	ToolManagerRebuildIfOnDisk via ChunkArrayEnum
PASS:		*ds:si	= chunk array
		ds:di	= ToolLibrary
		cx = disk being removed
RETURN:		carry set to stop enumerating (match, need to rebuild)
DESTROYED:	allowed: ax, bx, cx, dx, bp, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/22/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMRIOD_callback	proc	far
	uses	es
	.enter
	mov	bx, ds:[di].TL_handle
	tst	bx
	jz	done				; (carry clear)
	call	MemLock				; lock GeodeHeader
	mov	es, ax
	clr	ax				; assume not open
	test	es:[GH_geodeAttr], mask GA_KEEP_FILE_OPEN
	jz	checkHandle
	mov	ax, es:[GH_geoHandle]
checkHandle:
	call	MemUnlock
	mov_tr	bx, ax				; bx = library file handle
	tst	bx
	jz	done				; (carry clear)
	call	FileGetDiskHandle		; bx = disk handle
	cmp	bx, cx				; same as removed disk?
	clc					; assume not
	jne	done				; not, keep iterating
	stc					; else, stop, need to rebuild
done:
	.leave
	ret
TMRIOD_callback	endp

ToolCode	ends
