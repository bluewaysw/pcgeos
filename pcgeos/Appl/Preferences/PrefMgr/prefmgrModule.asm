COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefmgrModule.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 9/92   	Initial version.

DESCRIPTION:
	

	$Id: prefmgrModule.asm,v 1.1 97/04/04 16:27:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef PREFMGR
	HAVE_BUILT_IN_MODULES	= TRUE
elseifdef MYOPT
	HAVE_BUILT_IN_MODULES	= TRUE
elseifdef SYSOPT
	HAVE_BUILT_IN_MODULES	= TRUE
elseifdef HARDOPT
	HAVE_BUILT_IN_MODULES	= TRUE
else
	HAVE_BUILT_IN_MODULES	= FALSE
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanForModulesLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan the pref directory for modules, build
		a buffer of filenames, etc.

CALLED BY:	PrefMgrOpenApplication

PASS:		es - dgroup

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,bp,ds

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScanForModulesLow	proc near

	uses	es

curElement	local	fptr.PrefModuleElement
appFeatures	local	PrefMgrFeatures
triggerBlock	local	hptr.ObjLMemBlockHeader
curModuleNum	local	word
updateParams	local	TocUpdateCategoryParams
categoryStruct	local	TocCategoryStruct
if	HAVE_BUILT_IN_MODULES
moduleNameArray	local	optr.ChunkArrayHeader
endif
	.enter

ForceRef	curElement
ForceRef	appFeatures
ForceRef	triggerBlock		
ForceRef	curModuleNum

	;
	; Update the category with what's "out there"
	;
		
		mov	{word} ss:[updateParams].TUCP_tokenChars,
						'P' or ('R' shl 8)
		mov	{word} ss:[updateParams].TUCP_tokenChars+2,
						'E' or ('F' shl 8)
		mov	ss:[updateParams].TUCP_flags, 
			mask TUCF_CUSTOM_FILES or mask TUCF_ADD_CALLBACK

		mov	ss:[updateParams].TUCP_fileArrayElementSize, 
			  size PrefModuleElement
		mov	ss:[updateParams].TUCP_addCallback.segment, cs
		mov	ss:[updateParams].TUCP_addCallback.offset, 
			  offset PrefMgrAddModuleCB
		push	bp
		lea	bp, ss:[updateParams]
		call	TocUpdateCategory
		pop	bp
		
		segmov	es, ss
		lea	di, ss:[categoryStruct]
		mov	{word} ss:[categoryStruct].TCS_tokenChars,
						'P' or ('R' shl 8)
		mov	{word} ss:[categoryStruct].TCS_tokenChars+2,
						'E' or ('F' shl 8)
		call	TocFindCategory

	;
	; Save the files array in dgroup
	;
		
		mov	di, {word} ss:[categoryStruct].TCS_files
		mov	ss:[moduleArray], di

ifdef USE_EXPRESS_MENU
	;
	; If we're using the express menu to show module triggers,
	; then create an object in the menu that will have the
	; triggers as its children.
	;
		call	PrefMgrCreateExpressMenuGroup
else

if	HAVE_BUILT_IN_MODULES
	;
	; Allocate a chunk array to hold the names of all of the modules,
	; so that we can ensure they appear in alphabetical order
	;
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx			; use default header size
		call	MemAllocLMem		; lmem block handle => BX
		mov	ss:[moduleNameArray].handle, bx
		call	MemLock
		mov	ds, ax
		clr	ax, bx, cx, si
		call	ChunkArrayCreate	; chunk array => SI
		mov	ss:[moduleNameArray].chunk, si

	;
	; Initialize the module name array with the names of all of the
	; built-in modules, while adding the built-in trigger in the correct
	; order into the generic tree.
	;
		call	InstallBuiltInModules
endif

	;
	; Fetch the features from the app, so we can avoid creating
	; triggers for any modules that don't match this feature
	; level. 
	;
		
		push	bp
		mov	ax, MSG_GEN_APPLICATION_GET_APP_FEATURES
		LoadBXSI	PrefMgrApp
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp
		
		mov	ss:[appFeatures], ax
		
	;
	; create triggers for each external module, and add them to
	; the dialog group.  Start by allocating a block to stick the
	; triggers in.  Don't save the block, because we don't want to
	; save the triggers to state.
	;
		
		clr	bx
		call	UserAllocObjBlock
		mov	ss:[triggerBlock], bx
		
		
	;
	; Now, build a trigger for each element in the array.  Store
	; the module array in dgroup.  
	;
		
		clr	ss:[curModuleNum]
		call	TocGetFileHandle
		push	bx			; file handle
		push	ss:[moduleArray]

		push	cs
		mov	ax, offset BuildModuleTriggersCB
		push	ax
		
		clr	ax
		push	ax, ax
		dec	ax
		push	ax, ax			; -1
		call	HugeArrayEnum

if	HAVE_BUILT_IN_MODULES
	;
	; Free the module name array, as we don't need it anymore
	;
		mov	bx, ss:[moduleNameArray].handle
		call	MemFree
endif
endif
		
	;
	; Update the file here, just to get all of those dirty block
	; written out, so we can free up some memory. We don't deal
	; with the file not fitting on the disk, however.
	;
		call	TocGetFileHandle
		call	VMUpdate

		.leave
		ret
ScanForModulesLow	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrAddModuleCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the data for this pref module to the array

CALLED BY:	ConfigScanForPrefModules via TocUpdateCategory

PASS:		ds:si - filename
		di - VM handle of SortedNameArray

RETURN:		carry CLEAR if new element added
			ax - element number of newly added element

		carry SET otherwise (error loading geode, or whatever) 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 7/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMgrAddModuleCB	proc far
		uses	bx,cx,dx,es,di,ds,si

array		local	word	push	di		
libraryHandle	local	hptr
elementNumber	local	word		
fileID		local	FileID

		.enter

	;
	; Fetch the file ID for this module
	;

		mov	dx, si
		mov	ax, FEA_FILE_ID
		segmov	es, ss
		lea	di, ss:[fileID]
		mov	cx, size fileID
		call	FileGetPathExtAttributes
		
		LONG	jc	done
		
	;
	; Load the module.  If we can't load it, then bail
	;
		mov	ax, PREF_MODULE_PROTO_MAJOR
		mov	bx, PREF_MODULE_PROTO_MINOR
		call	GeodeUseLibrary
EC <		jnc	noLoadError			>
EC <		pushf					>
EC <		cmp	ax, GLE_LIBRARY_PROTOCOL_ERROR  >
EC <		WARNING_E PREFMGR_COULD_NOT_LOAD_MODULE	>
EC <		popf					>
noLoadError::
		LONG jc	done

		mov	ss:[libraryHandle], bx
		mov	di, ss:[array]		
		clr	bx, cx
		call	TocSortedNameArrayAdd
		mov	ss:[elementNumber], ax
		
		clr	dx
		call	TocGetFileHandle
		call	HugeArrayLock

EC <		tst	ax				>
EC <		ERROR_Z INVALID_ELEMENT_NUMBER		>
		
		mov	di, si			; ds:di - new element

		movdw	ds:[di].PME_fileID, ss:[fileID], ax
	;
	; Ask it everything about itself
	;
		
		mov	bx, ss:[libraryHandle]
		
		push	ds			
		lea	si, ds:[di].PME_info
		mov	ax, GGIT_ATTRIBUTES
		call	GeodeGetInfo
		test	ax, mask GA_ENTRY_POINTS_IN_C
		jz	getInfo
		
		push	ds, si			; pass fptr on the stack
		call	GeodeGetDGroupDS	;  and pass ds=dgroup
						;  for library, in
						;  case it needs it
		
getInfo:
		mov	ax, PMET_GET_MODULE_INFO
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable
		pop	ds

	;
	; Might as well add the moniker to the token DB while we've got
	; the library open, so that we won't have to open it again
	; later.  After that, free the library
	;
		
		lea	si, ds:[di].PME_info
		call	AddTokenToTokenDB

		mov	bx, ss:[libraryHandle]
		call	GeodeFreeLibrary

		
	;
	; Nuke the moniker list field, as it's only valid for this
	; instance of the library being open.  
	;
		
EC <		clrdw	ds:[di].PME_info.PMI_monikerList	>

	;
	; Unlock the array element, and return the element number to
	; the caller.
	;
		
		mov	di, ss:[array]
		call	TocGetFileHandle
		call	HugeArrayUnlock
		mov	ax, ss:[elementNumber]
		clc				; Oll Korrect
done:
		.leave
		ret
		
PrefMgrAddModuleCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildModuleTriggersCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to build a trigger for this module

CALLED BY:	ScanForModulesLow via HugeArrayEnum

PASS:		ds:di - PrefModuleElement

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 7/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PREFMGR_TRIGGER_BLOCK_MAX_SIZE	equ	4096

ifndef	USE_EXPRESS_MENU

BuildModuleTriggersCB	proc far

	.enter	inherit	ScanForModulesLow

	movdw	ss:[curElement], dsdi

	;
	; Make sure ALL of the required flags are set

	mov	ax, ss:[appFeatures]
	andnf	ax, ds:[di].PME_info.PMI_requiredFeatures
	cmp	ax, ds:[di].PME_info.PMI_requiredFeatures
	je	requiredOK
doneJMP:
	jmp	done

requiredOK:
	;
	;  Also check whether the module should appear in the
	;  the current User level.
	;
	call	UserGetDefaultUILevel	; ax - user level
	cmp	ax, ds:[di].PME_info.PMI_minLevel
	jl	doneJMP
	;
	; Make sure NONE of the prohibited flags are set
	;

	mov	ax, ss:[appFeatures]
	test	ax, ds:[di].PME_info.PMI_prohibitedFeatures
	jnz	doneJMP

	;
	; If this block is getting full, then allocate a new one.
	;

	mov	bx, ss:[triggerBlock]
	mov	ax, MGIT_SIZE
	call	MemGetInfo
	cmp	ax, PREFMGR_TRIGGER_BLOCK_MAX_SIZE
	jb	instantiate

	clr	bx
	call	UserAllocObjBlock
	mov	ss:[triggerBlock], bx

instantiate:	

	;
	; Instantiate a trigger (bx = block)
	;

	segmov	es, <segment PrefTriggerClass>, di
	mov	di, offset PrefTriggerClass
	call	ObjInstantiate		; ^lbx:si - new trigger


	call	ObjLockObjBlock
	mov	ds, ax

	push	bp			; stack frame

	mov	ax, MSG_META_SET_FLAGS
	mov	cx, si
	mov	dx, mask OCF_IGNORE_DIRTY
	call	ObjCallInstanceNoLock

	;
	; Set the destination of the trigger.  Since we're sending the
	; message to the process, we can use the low word of the optr
	; as data, so we'll store the module number there.
	;
	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	mov	cx, handle 0
	mov	dx, ss:[curModuleNum]
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
	mov	cx, MSG_PREF_MGR_ITEM_SELECTED
	call	ObjCallInstanceNoLock
	pop	bp			; stack frame

	;
	; Get the moniker for this module.  If it's not in the token
	; database, then try to install it from the library.  
	;

	call	buildMonikerFromToken
	jnc	monikerOK

	;
	; Well, we weren't able to look up this moniker in the token
	; DB, so try to install it from the library
	;

	mov	cx, ss:[curModuleNum]
	call	PrefMgrUseLibraryToGetMoniker
	jc	errorNukeTrigger

	;
	; That worked, so try to build it again!
	;

	call	buildMonikerFromToken
	jc	errorNukeTrigger

monikerOK:

	;
	; Determine where to add the moniker
	;

if	HAVE_BUILT_IN_MODULES
	call	FindModulePosition
else
	mov	ax, CCO_LAST
endif

	;
	; Send the moniker off to get copied
	; *ds:dx - new VisMoniker
	; 

	push	bp			; stack frame
	push	ax			; save trigger position
	mov	cx, ds:[LMBH_handle]
	mov	bx, cx
	mov	bp, VUM_MANUAL
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	call	ObjCallInstanceNoLock

	;
	; Add the trigger to the interaction
	;

	pop	bp			; trigger position -> bp
	push	bx, si			; trigger OD
	mov	ax, MSG_GEN_ADD_CHILD
	mov	cx, bx
	mov	dx, si
	mov	bx, handle PrefMgrDialogGroup
	mov	si, offset PrefMgrDialogGroup
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx, si			; trigger OD


	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
	pop	bp

unlock:
	call	MemUnlock


done:

	;
	; Increment the module number in EVERY CASE, even when we
	; don't build a trigger for this module (so that the module
	; number always matches the position in the array).
	;
		
	inc	ss:[curModuleNum]

	;
	; restore DS to the segment of the array (SHOULD NOT HAVE
	; MOVED!!!) 
	;

	mov	ds, ss:[curElement].segment
	clc
	.leave				; <----- EXIT HERE
	ret



buildMonikerFromToken:
	push	si
	les	di, ss:[curElement]
	movtok	axbxsi, es:[di].PME_info.PMI_monikerToken
	call	ConfigBuildTitledMonikerUsingToken
	pop	si
	retn


errorNukeTrigger:

	;
	; Just free the thing, since we haven't added it to any tree
	;

	push	bp
	mov	ax, MSG_META_OBJ_FREE
	call	ObjCallInstanceNoLock
	pop	bp
	mov	bx, ds:[LMBH_handle]
	jmp	unlock
	
	

BuildModuleTriggersCB	endp
endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InstallBuiltInModules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine where we should add the trigger

CALLED BY:	BuildModuleTriggersCB

PASS:		SS:BP	= Inherited stack frame

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, DS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		ES, if pointing at an object block, will likely no longer
		be valid.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	HAVE_BUILT_IN_MODULES
InstallBuiltInModules	proc	near
		uses	es
		.enter	inherit	ScanForModulesLow
	
	;
	; Loop through each of the built-in modules, adding its name
	; to the module name array, and moving it in the generic tree
	; if it is in the wrong location
	;
		mov	bx, handle MainUI
		call	ObjLockObjBlock
		mov	ds, ax
		mov	bx, offset builtInModuleNames
		mov	di, offset builtInModuleTriggers
		clr	cx			; initialize expected position
moduleLoop:
		push	bx
		mov	bx, cs:[bx]		; module name => *DS:BX
		call	AddNameToModuleArray
		cmp	ax, cx
		jne	moveTrigger
nextTrigger:
		pop	bx
		inc	cx
		add	bx, 2			; go to next module name
		add	di, 2			; go to next trigger 
		cmp	bx, offset builtInModuleNames + \
			    size builtInModuleNames
		jl	moduleLoop
		mov	bx, handle MainUI
		call	MemUnlock

		.leave
		ret
	;
	; Well, somehow the trigger is in the wrong location. So move it.
	;
moveTrigger:
		push	cx, bp, di
		push	ax			; save correct location
	;
	; First set trigger not usable
	;
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	bx, handle MainUI
		mov	si, cs:[di]
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		
	;
	; Move it to the correct location
	;
		mov	ax, MSG_GEN_MOVE_CHILD
		movdw	cxdx, bxsi
		mov	si, offset MainUI:PrefMgrDialogGroup
		pop	bp			; location to mvoe trigger
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Set the trigger usable again
	;
		mov	ax, MSG_GEN_SET_USABLE
		mov	si, dx
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Clean up & go on to the next trigger
	;
		pop	cx, bp, di
		jmp	nextTrigger
InstallBuiltInModules	endp
endif

ifdef PREFMGR
builtInModuleTriggers	nptr \
			ModemTrigger, PrinterTrigger, TextTrigger
builtInModuleNames	nptr \
			ModemTextMoniker, PrinterTextMoniker, TextTextMoniker
endif

ifdef MYOPT
builtInModuleTriggers	nptr \
			ModemTrigger, PrinterTrigger, TextTrigger
builtInModuleNames	nptr \
			ModemTextMoniker, PrinterTextMoniker, TextTextMoniker
endif

ifdef SYSOPT
builtInModuleTriggers	nptr \
			TextTrigger
builtInModuleNames	nptr \
			TextTextMoniker
endif

ifdef HARDOPT
builtInModuleTriggers	nptr \
			ModemTrigger, PrinterTrigger
builtInModuleName	nptr \
			ModemTextMoniker, PrinterTextMoniker
endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindModulePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine where we should add the trigger

CALLED BY:	BuildModuleTriggersCB

PASS:		SS:BP	= Inherited stack frame

RETURN:		AX	= New position for this module

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	HAVE_BUILT_IN_MODULES
FindModulePosition	proc	near
		uses	bx, cx, dx, di, si, ds, es
		.enter	inherit	ScanForModulesLow
	;
	; First, grab the text moniker for the current module. If
	; we cannot find one, then add trigger to end of list
	;
		push	bp
		les	di, ss:[curElement]
		movtok	axbxsi, es:[di].PME_info.PMI_monikerToken
		mov	dh, DC_TEXT
		mov	bp, VMS_TEXT shl offset VMSF_STYLE
		call	TokenLookupMoniker
		pop	bp
		jc	notFound
	;
	; Determine where this moniker belongs, by comparing it against
	; the array of built-in monikers.
	;
		call	TokenLockTokenMoniker	; text moniker => *DS:BX
		call	AddNameToModuleArray
		call	TokenUnlockTokenMoniker
done:
		.leave
		ret
	;
	; We could not find a text moniker, so add moniker to end of list
	;
notFound:
EC <		WARNING	PREF_MODULE_HAS_NO_TEXT_MONIKER			>
		mov	ax, CCO_LAST
		jmp	done
FindModulePosition	endp
endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddNameToModuleArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a name to the module name array

CALLED BY:	InstallBuiltInModules(), FindModulePosition()

PASS:		SS:BP	= Inherited stack frame
		*DS:BX	= Name to add to module name array

RETURN: 	AX	= Position of new name

DESTROYED:	BX, DX, SI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	HAVE_BUILT_IN_MODULES
AddNameToModuleArray	proc	near
		uses	cx, di
		.enter	inherit	ScanForModulesLow
	
		segmov	es, ds, ax
		mov	dx, es:[bx]		; text moniker => ES:DX
		add	dx, (size VisMoniker) + (size VisMonikerText)
		movdw	bxsi, ss:[moduleNameArray]
		call	MemDerefDS		; name chunk array => *DS:SI
		clr	cx			; initial position => CX
		mov	bx, cs
		mov	di, offset NameCompareCallback
		call	ChunkArrayEnum
	;
	; Insert the moniker into the correct location
	;
		pushf
		mov	ax, cx			; element # => AX
		call	ChunkArrayElementToPtr
		mov	cx, ax
		mov	bx, dx
		sub	bx, (size VisMoniker) + (size VisMonikerText)
		ChunkSizePtr	es, bx, ax
		sub	ax, (size VisMoniker) + (size VisMonikerText)
		popf
		jnc	append
		call	ChunkArrayInsertAt	; new element => DS:DI
copyModuleName:
		segxchg	ds, es			; destination => ES:DI
		mov	si, dx			; source => DS:SI
		xchg	ax, cx			; length => CX, position => AX
		rep	movsb

		.leave
		ret
	;
	; Insert the new module name to the end of the chunk array
	;
append:
		call	ChunkArrayAppend
		jmp	copyModuleName
AddNameToModuleArray	endp
endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NameCompareCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine where in the chunk array the module name belongs

CALLED BY:	FindModulePosition, via ChunkArrayEnum

PASS:		*DS:SI	= Module name chunkarray
		DS:DI	= Array element (existing module name)
		AX	= Module name's size
		CX	= Module's position
		ES:DX	= New module's name

RETURN:		Carry	= Set to end enumeration
		CX	= Position to add module name
			- or -
		Carry	= Clear to continue search
		CX	= Position for next module

DESTROYED:	BX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	HAVE_BUILT_IN_MODULES
NameCompareCallback	proc	far
		.enter
	;
	; Determine if we are less than or equal to the current module's name
	;
		mov	si, di
		mov	di, dx
		call	LocalCmpStrings
		jle	continue
		stc
		jmp	done
continue:
		inc	cx			; go to next position
		clc				; continue search
done:		
		.leave
		ret
NameCompareCallback	endp
endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrUseLibraryToGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do a UseLibrary to try and get the moniker for this
		library. 

CALLED BY:	BuildModuleTriggersCB,
		BuildExpressMenuTriggersCB

PASS:		cx - module number

RETURN:		carry CLEAR if moniker fetched OK, carry set otherwise

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMgrUseLibraryToGetMoniker	proc near
	uses	bx,cx,dx,bp,di,si,ds,es
	.enter
	;
	; do a GeodeUseLibrary on the module
	;

	call	UseModule
	jc	done

	;
	; Fetch the relevant info
	;

	sub	sp, size PrefModuleInfo
	segmov	ds, ss				; ds:si = buffer for module info
	mov	si, sp
	push	ds
	mov	ax, GGIT_ATTRIBUTES
	call	GeodeGetInfo
	test	ax, mask GA_ENTRY_POINTS_IN_C
	jz	getInfo
	push	ds, si				; pass fptr on the stack for C
	call	GeodeGetDGroupDS	;  pass ds=dgroup for library,
					;  in case it needs it
getInfo:
	mov	ax, PMET_GET_MODULE_INFO
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable
	pop	ds

	call	AddTokenToTokenDB

	clr	dx
	call	FreeModule
	add	sp, size PrefModuleInfo		; assume this clears carry!

done:
	.leave
	ret
PrefMgrUseLibraryToGetMoniker	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddTokenToTokenDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the moniker for this module to the token database

CALLED BY:	PrefMgrAddModuleCB, PrefMgrUseLibraryToGetMoniker

PASS:		ds:si - pointer to PrefModuleInfo structure

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/12/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddTokenToTokenDB	proc near
		uses	bp, di

		.enter
		mov	di, si
	;
	; First, see if there's a token already defined.  If there is,
	; and it's in the global token database, then don't add it.
	;

		call	UserGetDisplayType
		mov	dh, ah
		
		movtok	axbxsi, ds:[di].PMI_monikerToken
		mov	bp, (VMS_ICON shl offset VMSF_STYLE) or \
				mask VMSF_GSTRING
		call	TokenLookupMoniker
		
		jc	addIt		; not there -- add it

		tst	ax
		jz	done
addIt:
	;
	; Fetch AX again
	;
		
		mov	ax, {word} ds:[di].PMI_monikerToken		
		movdw	cxdx, ds:[di].PMI_monikerList
		clr	bp
		call	TokenDefineToken
done:
		.leave
		ret
AddTokenToTokenDB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UseModule
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do a "UseLibrary" on the passed module #

CALLED BY:	BringUpModuleUI

PASS:		cx - module number

RETURN:		IF LIBRARY AVAILABLE:
			bx - library handle
			carry clear
		ELSE
			bx - destroyed
			carry set.

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UseModule	proc near
		uses	ax,cx,dx,ds,si, ds, es

libraryName	local	FileLongName


		.enter
		segmov	es, dgroup, bx
		
	;
	; Store the current module number -- if it's the current one
	; in use, then done, otherwise, free the current one.
	;
		
		cmp	cx, es:[moduleNum]
		je	sameAsCurrent
		
		clr	dx			; no META_ACK needed
		call	FreeModule
		
		call	PrefMgrSetPath
		
	;
	; Lock the module array in the TOC file, and search for this
	; element. 
	;
		
		call	TocGetFileHandle
		mov	di, es:[moduleArray]
		
		push	cx
		mov_tr	ax, cx
		clr	dx
		
		call	HugeArrayLock			; ds:si - element
							; dx - length

EC <		tst	ax				>
EC <		ERROR_Z	ILLEGAL_MODULE			>
		
		mov	cx, dx
		sub	cx, offset PME_name
		lea	si, ds:[si].PME_name		; ds:si -
							; module filename
		
	;
	; Copy the filename onto the stack, since the @&!^%# thing
	; isn't stored null-terminated in the array
	;
		
		push	es			; dgroup
		segmov	es, ss
		lea	di, ss:[libraryName]
		rep	movsb			; cx = byte size
SBCS <		clr	al						>
SBCS <		stosb							>
DBCS <		clr	ax						>
DBCS <		stosw							>
		pop	es			; dgroup
		
		call	HugeArrayUnlock
		
	;
	; Now, try to load the thing
	;
		
		segmov	ds, ss
		lea	si, ss:[libraryName]
		mov	ax, PREF_MODULE_PROTO_MAJOR
		mov	bx, PREF_MODULE_PROTO_MINOR
		call	GeodeUseLibrary
		pop	cx
		jc	done
		
		
		mov	es:[moduleNum], cx	; save current module #
		mov	es:[moduleHandle], bx	; and library handle
		
done:
		.leave
		ret
		
sameAsCurrent:
		mov	bx, es:[moduleHandle]
		jmp	done
		
UseModule	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrItemSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Run one of the pref modules

PASS:		ds, es = dgroup
		si 	- item number selected

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMgrItemSelected	method	dynamic	PrefMgrClass, 
					MSG_PREF_MGR_ITEM_SELECTED
		.enter
ifdef USE_EXPRESS_MENU
		mov	ax, MSG_GEN_SYSTEM_MARK_BUSY
		call	UserCallSystem

		mov	ax, MSG_GEN_BRING_TO_TOP
		call	UserCallApplication

endif
		
		mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
		call	UserCallApplication

		mov	cx, si			; item number

		call	BringUpModuleUI		; bx:si - OD of module
						; interaction 
		jc	done
	;
	; Set the GA_NOTIFY_VISIBILITY flag for this object so that it
	; sends notification when it goes off-screen
	;
if ERROR_CHECK
	;
	; Make sure it doesn't already have this...
	;
		mov	ax, MSG_GEN_GET_ATTRIBUTES
		mov	di, mask MF_CALL
		call	ObjMessage
		test	cl, mask GA_NOTIFY_VISIBILITY
		ERROR_NZ PREF_DIALOG_HAS_VISIBILITY_NOTIFICATION
endif
		
		mov	ax, MSG_GEN_SET_ATTRS
		mov	cx, mask GA_NOTIFY_VISIBILITY
		call	ObjMessageNone

	;
	; Set the dialog usable
	;
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_MANUAL
		call	ObjMessageNone

	;
	; send the Pref-level initialization message -- sending down
	; the features and interface level, so that objects can decide
	; whether to be on-screen or not.
	;

		mov	ax, MSG_GEN_APPLICATION_GET_APP_FEATURES
		call	UserCallApplication
		mov_tr	cx, ax			; features (dx is level)

		mov	ax, MSG_PREF_INIT
		call	ObjMessageNone

	;
	; Load the options
	;
		mov	ax, MSG_META_LOAD_OPTIONS
		call	ObjMessageNone
	;
	; Bring it on up.
	;
		
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessageNone


done:
		
ifdef USE_EXPRESS_MENU
		mov	ax, MSG_GEN_SYSTEM_MARK_NOT_BUSY
		call	UserCallSystem
endif

		mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
		call	UserCallApplication

		.leave
		ret

PrefMgrItemSelected	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BringUpModuleUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the UI for one of the dynamic library
		modules

CALLED BY:	PrefMgrItemSelected

PASS:		cx - module number
		ds, es - dgroup

RETURN:		^lbx:si - OD of root of pref tree
		carry set if error, or if UI already up.

DESTROYED:	ax,bx,cx,dx,si,di,bp,es,ds

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BringUpModuleUI	proc near

		.enter

	; Load up the library.

		call	UseModule
		jc	done

	; If there's already an OD in the moduleUI field, then the
	; user is probably clicking on the same module s/he just
	; clicked on before -- so do nothing.

		tst	ds:[moduleUI].handle
		jnz	reuse
	

		mov	ax, PMET_FETCH_UI
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable	; ^ldx:ax - OD of root of tree
	;
	; Make sure obj block is discarded before duplicating
	;
		push	ax			; chunk handle of root
		mov	bx, dx
		call	MemDiscard

	;
	; Duplicate the UI block -- the owner is our process handle,
	; and the burden thread is the current thread, now that we're
	; single-threaded. 
	;

		mov	bx, dx
		mov	ax, handle 0
		clr	cx
		call	ObjDuplicateResource
		pop	dx			; chunk handle of root

		movdw	ds:[moduleUI], bxdx


	;
	; Add the new dialog box to the application
	;

		mov	cx, bx			; handle of duplicated block
		mov	bp, CCO_LAST
		LoadBXSI PrefMgrApp
		mov	ax, MSG_GEN_ADD_CHILD
		clr	di
		call	ObjMessage

		mov	bx, cx			; dialog box
		mov	si, dx
		clc
done:
		.leave
		ret
reuse:
		movdw	bxsi, ds:[moduleUI]
		stc
		jmp	done

BringUpModuleUI	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMgrSetPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the path to the SYSTEM\PREF directory

CALLED BY:	UseModule

PASS:		es - dgroup

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS <prefPathName	char	"PREF",0				>
DBCS <prefPathName	wchar	"PREF",0				>

PrefMgrSetPath	proc near
		uses	ds
		.enter
		segmov	ds, cs
		mov	bx, SP_SYSTEM
		mov	dx, offset prefPathName
		call	FileSetCurrentPath
EC <		ERROR_C	NO_PREF_MODULE_DIRECTORY			>
		.leave
		ret
PrefMgrSetPath	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeModule
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the currently in-use module

CALLED BY:	UseModule

PASS:		^ldx:bp	= OD to which to send MSG_META_ACK when
			  module is unloaded -- dx = 0 for no ack.

RETURN:		es	= dgroup

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeModule	proc near
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	;
	; First, remove and free the UI block
	;

	push	dx, bp
	segmov	es, dgroup, bx
	call	FreeModuleUI
	pop	dx, bp

	clr	cx
	xchg	cx, es:moduleHandle
	jcxz	maybeSendAck

	;
	; There could be messages in various queues sent by objects in
	; the duplicated block as part of their response to having the
	; duplicated block freed. To cope with this, we route the
	; message to free the library through various queues, thereby
	; ensuring that all messages destined for an object whose
	; class may be in this library have been handled.
	;
		
	call	GeodeGetProcessHandle
	mov	ax, MSG_PREF_MGR_FREE_LIBRARY
	mov	di, mask MF_RECORD
	call	ObjMessage

	mov	cx, di
	mov	dx, bx
	clr	bp
	mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
	mov	di, mask MF_CALL
	call	ObjMessage

afterFree:

	.leave
	ret

maybeSendAck:
	tst	dx
	jz	afterFree

	;
	; Didn't have a module loaded, but we still need to generate the
	; MSG_META_ACK...
	; 
	call	GeodeGetProcessHandle
	clr	si			; ^lbx:si <- us

	xchg	bx, dx			; ^lbx:si <- destination of ACK
	xchg	si, bp			; ^ldx:bp <- we who are sending it
	mov	ax, MSG_META_ACK
	call	ObjMessageNone
	jmp	afterFree
FreeModule	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeModuleUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove and free the block of UI for the current module

CALLED BY:	FreeModule, PrefMgrCloseApplication

PASS:		es - dgroup

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/24/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeModuleUI	proc near
		.enter

		mov	es:[moduleNum], -1
	
		clrdw	bxsi
		xchgdw	bxsi, es:[moduleUI]
		tst	bx
		jz	done

		mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
		call	ObjMessageNone

done:
		.leave
		ret
FreeModuleUI	endp

ObjMessageNone	proc	near
		clr	di
		call	ObjMessage
		ret
ObjMessageNone	endp
