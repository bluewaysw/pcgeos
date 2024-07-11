COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido Library
FILE:		emain.asm

AUTHOR:		Paul DuBois, Aug 17, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB FIDOREGLOADEDCOMPLIBS	C stub for FidoRegLoadedCompLibs

    GLB FidoRegLoadedCompLibs	Register loaded component libraries

    GLB FIDOFINDCOMPONENT	C stub for FidoFindComponent

    GLB FidoFindComponent	Find libraries that export a certain
				component

    INT FFC_Callback		Callback for FidoFindComponent

    INT FindLibraryDisk		Enumerate through component libraries on
				disk

    INT ProcessLibrary		Search component library for exported
				component type

    GLB FidoGetCompLibs		Returns a list of valid component libraries
				in the current directory.

    INT SetTokenChars		Set token chars in idata

    GLB FidoPushDir		Pushes the current directory on the stack,
				and changes to the standard directory for
				component libraries.

    INT TMP_WarningDialog	Temp: put up a warning dialog

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/17/94		Initial revision

DESCRIPTION:
	Bulk of code to enumerate through libraries
		

	$Revision: 1.2 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include	Internal/heapInt.def
include uDialog.def
MainCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIDOREGLOADEDCOMPLIBS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for FidoRegLoadedCompLibs

CALLED BY:	GLOBAL
C FUNCTION:	FidoRegLoadedCompLibs

C DECL:         extern void _far _pascal
	            FidoRegLoadedCompLibs(MemHandle fidoTask,
	                                  byte      compLibs);

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 6/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
FIDOREGLOADEDCOMPLIBS	proc	far    	ftask:hptr.FidoTask
	
	uses	cx,ds,es,di,si,bx
	.enter

		mov     bx, ss:[ftask]
		call 	FidoRegLoadedCompLibs

	.leave
	ret
FIDOREGLOADEDCOMPLIBS	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FidoRegLoadedCompLibs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register loaded component libraries

CALLED BY:	GLOBAL
PASS:		bx     	- hptr.FidoTask

RETURN:		nothing

DESTROYED:	
SIDE EFFECTS:	Fill the Fido task with handles to the component libraries
		already loaded by the app

PSEUDO CODE/STRATEGY:
		
		Have fido add any loaded component libraries
		(loaded by the current app) to its table of known 
		libraries.
	
		Go a minin' in the core block to extract the
		library info and tell fido it's already there.
		Also make sure Fido doesn't muck with it
		when Fido is destroyed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	6/26/95  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FidoRegLoadedCompLibs	proc	far
ftask		local	hptr.FidoTask	push bx
token		local	GeodeToken      ;space for EC retrieval of lib info
ForceRef token
	uses	ax,bx,cx,ds,si,es,di
	.enter

	; Lock down the core block

		mov	bx, ss:[TPD_processHandle]
		call	MemLock
		mov	ds, ax		; ds <- core block
		mov	si, ds:[GH_libOffset]	; ds:si <- array of libs
		mov	cx, ds:[GH_libCount]

	; Loop through libraries, adding component libraries
	; Token chars of component libraries are BoOL or CoOL
	;
checkLib:
		mov	bx, ds:[si]	; bx <- GeodeHandle
		segmov	es, ss
		lea	di, ss:[token]
		mov	ax, GGIT_TOKEN_ID
		call	GeodeGetInfo

		cmp 	es:[di].GT_chars[0], 'B'
		je	gotOne
		cmp 	es:[di].GT_chars[0], 'C'
		jne	nextLib

gotOne:
		cmp 	es:[di].GT_chars[1], 'o'
		jne	nextLib

		cmp 	es:[di].GT_chars[2], 'O'
		jne	nextLib

		cmp 	es:[di].GT_chars[3], 'L'
		jne	nextLib

	; It's a comp lib, so make it usable by all modules.
	; Create a library element for it, and put a reference
	; to the library in the global array
	;
		mov_tr	ax, bx		; save geode
		mov	bx, ss:[ftask]
		push	ds, cx
		call	TaskLockDS
		mov_tr	bx, ax		; restore geode
		mov	ax, mask LDF_STATIC
		call	Fido_AddLibrary	; ax <- index of new elt
		call	Fido_AddGlobalLibraryRef
		call	TaskUnlockDS
		pop	ds, cx
	
nextLib:	add	si, 2

		loop 	checkLib

	; Unlock the core block
	;
		mov	bx, ss:[TPD_processHandle]
		call	MemUnlock

	.leave
	ret
FidoRegLoadedCompLibs	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIDOFINDCOMPONENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for FidoFindComponent

CALLED BY:	GLOBAL
C FUNCTION:	FidoFindComponent

C DECLARATION:	extern void _far _pascal
		    FidoFindComponent(MemHandle	fidoTask,
				      ModuleToken mod,
				      char _far* componentName,
				      FidoSearchFlags searchFlags,
				      LibraryClassPointer* retval);

PSEUDO CODE/STRATEGY:
	We could make this return a boolean word since ax is zero
	if not found anyway...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/23/94		Initial version
	martin	9/14/94 	Added FidoSearchFlags argument

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
FIDOFINDCOMPONENT	proc	far	ftask:hptr.FidoTask,
					module:word,
					compName:fptr,
					searchFlags:FidoSearchFlags,
					libPtr:fptr.LibraryClassPointerAsm
	uses	es,di,cx
	.enter

		mov	ax, ss:[searchFlags]
		mov	bx, ss:[ftask]
		mov	dx, ss:[module]
		les	di, ss:[compName]
		call	FidoFindComponent
		les	di, libPtr
	;
	; Return LibraryClassPointer correctly.
	; What follows is an optimized version of this code:
	; 	mov	es:[di].LCP_handle, ax
	; 	movdw	es:[di].LCP_classPointer, cxdx
	;
		CheckHack <offset LCP_library eq 0>
		CheckHack <offset LCP_class eq 2>
		stosw
		movdw	es:[di], cxdx
	.leave
	ret
FIDOFINDCOMPONENT	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FidoFindComponent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find libraries that export a certain component

CALLED BY:	GLOBAL
PASS:		es:di	- null-terminated component name
		ax	- FidoSearchFlags
		bx	- hptr.FidoTask
		dx	- module token

RETURN:		ax	- library handle, zero on error, 0xffff if agg
		cx:dx	- fptr to ClassStruct, or garbage on error
			- module:function if agg
DESTROYED:	nothing
SIDE EFFECTS:	Does a GeodeUseLibrary.

PSEUDO CODE/STRATEGY:
	Steal ardeb's code from ctoolToolMgr.asm.  Thanks, adam!

	Hack for basco:
	If NULL_MODULE is passed, just search in the "global" library
	list, (and don't put up the error box if a FileEnum is needed?)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FidoFindComponent	proc	far
searchFlags	local	word		push	ax
ftask		local	hptr.FidoTask	push	bx
componentName	local	fptr.TCHAR	push	es,di
module		local	word		push	dx
str_length	local	word		;length of componentName
classPtr	local	fptr		;set in ProcessLibrary
token		local	GeodeToken	;used as scratch space in ProcessLib
					;but only in GENERAL_FIDO
ForceRef ftask
ForceRef token
ForceRef componentName
ForceRef searchFlags
	uses	bx,ds,si,es,di
	.enter
		call	LocalStringLength
		inc	cx
		mov	ss:[str_length], cx

		call	TaskLockDS
		mov	si, ds:[FT_modules]
		mov	ax, dx

		cmp	ax, NULL_MODULE
		je	globalList

	; Check in module-local list of libraries
	;
		call	ChunkArrayElementToPtr
EC <		ERROR_C	FIDO_INVALID_MODULE_TOKEN			>
		mov	si, ds:[di].MD_localLibs
		mov	bx, cs
		mov	di, offset FFC_Callback
		call	ChunkArrayEnum	; stc, ax, classPtr set if success
		jc	done

globalList:
	; Check in the global list of libraries -- these don't have
	; to be explicitly requested by the module
	;
		mov	bx, cs
		mov	di, offset FFC_Callback
		mov	si, ds:[FT_globalLibs]
		call	ChunkArrayEnum
		jc	done

	; Temporarily, search on disk if called from Legos code
	; later, return error if comp not found in library list
	;
PrintMessage <Temporary backwards-compatibility code>
if 0
	; If being called by basic code, only search libraries that
	; have been loaded -- don't go out looking for libraries.
	; If the compiler is calling us, do more work
	;
		clr	ax		; assume fail
		cmp	ss:[module], NULL_MODULE
		jne	done		; not being called by compiler
endif
		call	FindLibraryDisk	; clc, ax=0 if failure
		jnc	done
		WARNING	FIDO_WARNING_COMP_NOT_IN_LOADED_LIBS

	; Found it -- add to global array so compiler won't have
	; to search on disk next time

	; Add new element to library array
		mov_tr	bx, ax		; bx <- library
		clr	ax		; no flags
		call	Fido_AddLibrary	; ax <- index of added elt
ifdef EXTERNAL_COMPONENT_WARNING
		cmp	ss:[module], NULL_MODULE
		jne	tmp_addToLocal
endif
		call	Fido_AddGlobalLibraryRef
		mov_tr	ax, bx		; ax <- library

done:
		call	TaskUnlockDS
		movdw	cxdx, ss:[classPtr]
	.leave
	ret
ifdef EXTERNAL_COMPONENT_WARNING
tmp_addToLocal:
		les	di, ss:[componentName]
		call	TMP_WarningDialog
		mov_tr	cx, bx		; save lib handle
		mov_tr	bx, ax		; bx <- index of added elt
		mov	ax, ss:[module]
		call	Fido_AddLocalLibraryRef
		mov_tr	ax, cx		; restore ax <- library
		jmp	done
endif
FidoFindComponent	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FFC_Callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for FidoFindComponent
CALLED BY:	INTERNAL
PASS:		*ds:si	- array
		ds:di	- array element for enum (ptr to index)
		stack	- inherited

RETURN:		carry set and ss:[classPtr] filled in if successful
		ax	- library (0xffff if agg)
DESTROYED:	(bx, si, di allowed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Library element can either refer to a geode or an aggregate module.

	If the former, look through its table of exported components.

	If the latter, look through the chunkarray of name/constructor
	function mappings.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	4/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FFC_Callback	proc	far
	uses	cx,dx, es, ds
	.enter inherit FidoFindComponent
		mov	ax, ds:[di]	; element # in FT_libraries
		mov	si, ds:[FT_libraries]
		call	ChunkArrayElementToPtr
EC <		ERROR_C	BARK_YELP_YELP					>

		test	ds:[di].LD_flags, mask LDF_AGGREGATE
		jnz	doAgg

		mov	bx, ds:[di].LD_library
		call	ProcessLibrary	; kill dxax, dssi, esdi
		mov_tr	ax, bx		; ax <- library
done:
	.leave
	ret
doAgg:
	; ds:di - LibraryData
	; If agg module was unloaded, LD_myModule will be NULL
	; fill in ss:[classPtr] with rtaskHan:constructor dword
	;
		cmp	ds:[di].LD_myModule, CA_NULL_ELEMENT
		je	done		; carry clear if equal

		mov	ax, ds:[di].LD_library
		mov	ss:[classPtr].low, ax
		mov	si, ds:[di].LD_components
		mov	bx, cs
		mov	di, offset AggComp_Callback	;kill ax-dx, es
		call	ChunkArrayEnum	; return stc if found
		mov	ax, 0xffff
		jmp	done
FFC_Callback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AggComp_Callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for an exported aggregate in an aggregate module

CALLED BY:	INTERNAL, ChunkArrayEnum callback from FFC_Callback
PASS:		*ds:si	- array (LD_components)
		ds:di	- element (AggCompDecl)
		ax	- elt size
RETURN:		stc	- quit processing
		ss:[classPtr] filled in if successful
DESTROYED:	can destroy bx, si, di
		also ax,cx, es
		
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	4/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AggComp_Callback	proc	far
	;uses
	.enter inherit FidoFindComponent

		mov	cx, ax
		sub	cx, size AggCompDecl
DBCS <		shr	cx		; convert to length		>

		mov	ax, di

		lea	si, ds:[di].ACD_name
		les	di, ss:[componentName]
DBCS <		repe	cmpsw						>
SBCS <		repe	cmpsb						>

		mov	di, ax
		jne	notEqual

	; equal, so fill in ss:[classPtr]
		mov	ax, ds:[di].ACD_constructor
		mov	ss:[classPtr].high, ax
		stc
done:
	.leave
	ret
notEqual:
		clc
		jmp	done
AggComp_Callback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindLibraryDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate through component libraries on disk

CALLED BY:	INTERNAL
		FidoFindComponent
PASS:		stack	- inherited stack frame
RETURN:		carry	- set if successful
		stack	- ss:[classPtr] filled in if successful
		ax	- lib handle if successful, else 0

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindLibraryDisk	proc	near
	uses	bx,cx,dx, ds,si, es,di
	.enter inherit FidoFindComponent
	; Oh well; do it the slow way.
	;
		call	FidoPushDir

		mov	ax, SP_COMPONENT
		call	FileSetStandardPath

		mov	ax, ss:[searchFlags]
		call	FidoGetCompLibs
		jc	errorDone
		jcxz	errorDone

		call	MemLock
		mov	ds, ax
		clr	si

	; Loop through the found libraries, looking for one which
	; exports the component we're looking for
	;
	; ds:si - array of FileLongName
	; cx	- number of libraries left
	;
		push	bx		; mem handle

compLoop:
		clr	ax		; don't care about protocol #
		call	GeodeUseLibrary
		jc	cl_next
		push	ds,si
		call	ProcessLibrary	; kill ax, dx
		pop	ds,si
		jc	found
		call	GeodeFreeLibrary
cl_next:
		add	si, size FileLongName
		loop	compLoop
cl_fallThru::
		jmp	notFound

	; stack	- memhandle
	; bx	- last library processed
found:
		mov_tr	ax, bx		; ax <- library
		pop	bx		; bx <- MemHandle
		call	MemFree
		call	FilePopDir
		stc
done:
	.leave
	ret

notFound:
		pop	bx
		call	MemFree
errorDone:
		WARNING	FIDO_WARNING_NO_COMPONENT_LIBRARIES_FOUND
		call	FilePopDir
		clr	ax
		clc
		jmp	done

FindLibraryDisk	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search component library for exported component type

CALLED BY:	INTERNAL, FidoFindComponent
PASS:		bx	- library handle
		stack	- inherited from FidoFindComponent
			  But make sure the frame is filled in!

RETURN:		carry set and ss:[classPtr] filled in, if successful
		otherwise carry clear

DESTROYED:	ax, dx, ds,si,es,di
SIDE EFFECTS:	GeodeUseLibrary on bx if successful

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/18/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessLibrary	proc	near
	uses	bx,cx
	.enter	inherit FidoFindComponent

	; Token chars:  buildtime-'BoOL', runtime-'CoOL'
	;
		segmov	es, ss, ax
		lea	di, ss:[token]
		mov	ax, GGIT_TOKEN_ID
		call	GeodeGetInfo
		test	{word}ss:[searchFlags], mask FSF_BUILD_TIME
		jnz	checkBool
checkCool::
		cmp	es:[di].GT_chars[0], 'C'	; for CoOL
		je	rightType
wrongType:
		clc
		jmp	done
		
checkBool:
		cmp	es:[di].GT_chars[0], 'B'	; for BoOL
		jne	wrongType
rightType:

	; Lock block containing table of exported components down,
	; put fptr into ds:bx.	Save the vseg off so we can unlock
	; it later...
	;
		mov	ax, ENT_TABLE_ENTRY_NUMBER
		call	ProcGetLibraryEntry	; bx:ax - vfptr to table
		push	bx		; save that vseg

		push	ax		; save offset
		call	MemLockFixedOrMovable
EC <		ERROR_C BARK_YELP_YELP				>
		mov	ds, ax
		pop	bx		; ds:bx - classPtrTable

	; Set things up like so before the loop:
	;
	; stack - vseg of table
	; ds:bx - fptr to table of nptrs to EOLClassPtrStruct
	; es:dx - component name to look for
	; ax	- length of component name (including null)
	; 
		les	dx, ss:[componentName]
		mov	ax, ss:[str_length]

	; comprare all exported class names to es:dx
tableLoop:
		mov	si, ds:[bx]
		cmp	si, -1		; end of table?
		je	notFound
		mov	si, ds:[si].ECPS_className
		mov	di, dx		; es:di <- name
		mov	cx, ax		; cx <- length
EC <		Assert	okForRepCmpsb					>
SBCS	<	repe	cmpsb						>
DBCS	<	repe	cmpsw						>
		jz	found
		add	bx, size nptr
		jmp	tableLoop
		
notFound:
		clc
donePop:
		lahf
		pop	bx		; restore vseg
		call	MemUnlockFixedOrMovable
		sahf
done:
	.leave
	ret

found:
		mov	bx, ds:[bx]	; ds:bx <- EntClassPointerStruct
		movdw	ss:[classPtr], ds:[bx].ECPS_classPtr, ax
		stc			; signal success
		jmp	donePop

ProcessLibrary	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FidoGetCompLibs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a list of valid component libraries in the current
		directory.

CALLED BY:	GLOBAL

PASS:		ax	- FidoSearchFlags

RETURN:		if carry set:
			ax	- FileError
		otherwise:
			ax	- destroyed
			bx	- handle of block containing list of libraries
			cx	- number of matches

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/9/94    	Pulled out of FidoFindComponent

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ffcEnumParams	FileEnumParams <
	mask FESF_GEOS_EXECS,		; FEP_searchFlags
	FESRT_NAME,			; FEP_returnAttrs
	size FileLongName,		; FEP_returnSize
	ffcMatchAttrs,			; FEP_matchAttrs
	FE_BUFSIZE_UNLIMITED		; FEP_bufSize
>

ffcMatchAttrs	FileExtAttrDesc \
	<FEA_TOKEN, compToken, size GT_chars>,	; match GT_chars, only
	<FEA_END_OF_LIST>

FidoGetCompLibs	proc	far
	uses	ds, si
	.enter

		call	SetTokenChars
		segmov	ds, cs, si
		mov	si, offset ffcEnumParams
		call	FileEnumPtr	; bx <- buffer of matches
					; cx <- number of matches
	.leave
	ret

FidoGetCompLibs	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTokenChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set token chars in idata

CALLED BY:	INTERNAL
		FidoGetCompLibs, FLL_callback
PASS:		ax	- search flags
RETURN:		ds	- dgroup
DESTROYED:	si
SIDE EFFECTS:
	messes with dgroup:[compToken]

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTokenChars	proc	near
		segmov	ds, dgroup, si
		mov	ds:[compToken].GT_chars[0], 'C' ; CoOL
		test	ax, mask FSF_BUILD_TIME
		jz	done
		mov	ds:[compToken].GT_chars[0], 'B'	; BoOl
done:
	ret
SetTokenChars	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FidoPushDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pushes the current directory on the stack, and changes to
		the standard directory for component libraries.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/14/94    	Pulled out of FidoFindComponent
	dloft	9/26/94		Changed to use a subdir of system
	dubois	 2/ 6/95  	Changed back as an anti-optimization

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;compLibPath	char	'comp',C_NULL
compLibPath	TCHAR	C_NULL

FidoPushDir	proc	far
		uses	ax, bx, ds, dx
		.enter

		call	FilePushDir
		mov	bx, SP_SYSTEM
		segmov	ds, cs
		mov	dx, offset compLibPath
		call	FileSetCurrentPath
EC <		ERROR_C -1						>

		.leave
		ret
FidoPushDir	endp

theWarning	TCHAR	'The component class "\001" was not found in any libraries requested by the current module.  It was found in a component library on disk, but this searching behavior will be removed soon.', C_NULL
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMP_WarningDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Temp: put up a warning dialog

CALLED BY:	INTERNAL
PASS:		es:di	- component name
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	4/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMP_WarningDialog	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDP_customFlags,		\
	(CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE) OR	\
	(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
		mov	ss:[bp].SDP_customString.high, cs
		mov	ss:[bp].SDP_customString.low, offset theWarning
		movdw	ss:[bp].SDP_stringArg1, esdi
		clrdw	ss:[bp].SDP_customTriggers
		clrdw	ss:[bp].SDP_helpContext	
		call	UserStandardDialog
	.leave
	ret
TMP_WarningDialog	endp

MainCode	ends
