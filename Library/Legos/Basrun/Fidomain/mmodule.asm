COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido
FILE:		mmodule.asm

AUTHOR:		Paul L. DuBois, Oct  7, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB FIDOOPENMODULE		C stub for FidoOpenModule

    GLB FIDOCLOSEMODULE		C stub for FidoCloseModule

    GLB FIDOGETPAGE		C stub for FidoGetPage

    GLB FIDOGETHEADER		C stub for FidoGetHeader

    GLB FIDOGETCOMPLEXDATA	C stub for FidoGetComplexData

    GLB FidoOpenModule		Open up a module in preparation for getting
				pages from it

    GLB FidoCloseModule		Remove reference to module

    GLB FidoGetComplexData	Extract VM Tree of complex data from module

    GLB FidoGetPage		Return a page from a module

    GLB FidoGetHeader		Return a listing of symbols exported from
				this module

    INT ModuleCloseSaveCF	Call DR_FIDOI_CLOSE, preserving carry

    INT ModuleOpen		call DR_FIDOI_OPEN on a module

    INT ModuleAdd		Create and return a new module element
				given a URL

    INT Fido_MakeMLCanonical	Asm stub for C routine

    INT ModuleGetDriver		Return a driver handle that can deal with
				the module type.

    INT compareDriver		Check if first ss:[driver_len] chars of
				ss:[path] match string in ds:si

    INT ModuleRemove		Remove a reference to a module

    INT ModuleDestroy		Callback for ElementArrayRemoveReference

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/ 7/94   	Initial revision


DESCRIPTION:
	Handles the module name array and interface to fido input driver.

	Note that there is a difference between opening/closing a module
	in fido and calling the DR_FIDOI_OPEN and DR_FIDOI_CLOSE driver
	functions.  The former is used to inc/dec the refcount in a
	NameArray of MLs and the latter is used by the driver to physically
	perform an open/close (as in opening a file, a socket connection,
	etc)

	$Id: mmodule.asm,v 1.4 98/10/15 13:36:12 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MainCode	segment	resource

;; makeDriverStrings -- create strings for table
makeDriverEntry	macro mlName, geodeName
FI&geodeName&ML		TCHAR <mlName>, 0
if ERROR_CHECK
FI&geodeName&Geode	TCHAR <&geodeName&ec.geo>, 0
else
FI&geodeName&Geode	TCHAR <&geodeName&.geo>, 0
endif
endm

;; makeDriverTable -- create table itself
makeDriverTable	macro tableName, g1, g2, g3, g4
tableName	label	nptr.TCHAR
mdt_helper g1,g2,g3,g4
endm

mdt_helper	macro g1,g2,g3,g4
ifnb <g1>
	nptr.TCHAR	offset FI&g1&ML
	nptr.TCHAR	offset FI&g1&Geode
	mdt_helper g2, g3, g4
else
	word	-1
endif	
endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIDOOPENMODULE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for FidoOpenModule

CALLED BY:	GLOBAL

C DECLARATION:	extern ModuleToken _far _pascal
		    FidoOpenModule(MemHandle ftaskHan, char *url,
					ModuleToken module);

PSEUDO CODE/STRATEGY:
	Save esdi in regs that can be trashed		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 1/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
FIDOOPENMODULE	proc	far	ftask: hptr.FidoTask,
				url:fptr.TCHAR,
				module:word
	;uses	es, di
	.enter
		mov	cx, di
		mov	dx, es

		mov	ax, ss:[module]
		mov	bx, ss:[ftask]
		les	di, ss:[url]
		call	FidoOpenModule
		jnc	done
		mov	ax, NULL_MODULE	; signal failure
done:
		mov	di, cx
		mov	es, dx
	.leave
	ret
FIDOOPENMODULE	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIDOCLOSEMODULE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for FidoCloseModule

CALLED BY:	GLOBAL

C DECLARATION:	extern void _far _pascal
		    FidoCloseModule(MemHandle ftaskHan, ModuleToken module);

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 1/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
FIDOCLOSEMODULE	proc	far	ftask:hptr.FidoTask,
				module:word
	;uses	cs,ds,es,si,di
	.enter
		mov	ax, ss:[module]
		mov	bx, ss:[ftask]
		call	FidoCloseModule
	.leave
	ret
FIDOCLOSEMODULE	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIDOGETPAGE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for FidoGetPage

CALLED BY:	GLOBAL

C DECLARATION:	extern MemHandle _far _pascal
		    FidoGetPage(MemHandle ftaskHan,
				aModuleToken module, word pageNuM);

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 1/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
FIDOGETPAGE	proc	far	ftask:hptr.FidoTask,
				module:word,
				pageNum:word
	;uses	cs,ds,es,si,di
	.enter
		mov	ax, ss:[module]
		mov	bx, ss:[ftask]
		mov	dx, ss:[pageNum]
		call	FidoGetPage
		mov_tr	ax, bx		; assume success
		jnc	done
		clr	ax		; signal failure
done:
	.leave
	ret
FIDOGETPAGE	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIDOGETHEADER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for FidoGetHeader

CALLED BY:	GLOBAL

C DECLARATION:	extern MemHandle _far _pascal
		    FidoGetHeader(MemHandle ftaskHan, ModuleToken module);

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 1/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
FIDOGETHEADER	proc	far	ftask:hptr.FidoTask,
				module:word
	;uses	cs,ds,es,si,di
	.enter
		mov	ax, ss:[module]
		mov	bx, ss:[ftask]
		call	FidoGetHeader
		mov_tr	ax, bx		; assume success
		jnc	done
		clr	ax		; signal failure
done:
	.leave
	ret
FIDOGETHEADER	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FIDOGETCOMPLEXDATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for FidoGetComplexData
CALLED BY:	GLOBAL
C DECLARATION:
extern Boolean _far _pascal
    FidoGetComplexData(FTaskHan ftaskHan, ModuleToken module, word element,
		       VMFileHandle dest,
		       VMChain* chainP, ClipboardItemFormatID* idP);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 1/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
FIDOGETCOMPLEXDATA	proc	far	\
	ftask:hptr.FidoTask, module:word, elt:word,
 	dest:hptr,
	chainP: fptr.dword, idP: fptr.dword
	;uses	cs,ds,si,di
	uses	di, si
	.enter
		mov	ax, ss:[module]
		mov	bx, ss:[ftask]
		mov	cx, ss:[dest]
		mov	dx, ss:[elt]
		call	FidoGetComplexData
		jc	errorDone

		les	di, ss:[chainP]
		movdw	es:[di], axsi
		les	di, ss:[idP]
		movdw	es:[di], cxdx

		mov	ax, 1		; signal success
done:
	.leave
	ret
errorDone:
		clr	ax		; signal failure
		jmp	done
FIDOGETCOMPLEXDATA	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FidoOpenModule
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open up a module in preparation for getting pages from it

CALLED BY:	GLOBAL
PASS:		es:di	- ML
		ax	- Module token, or NULL_MODULE if not relative
		bx	- hptr.FidoTask
RETURN:		carry clear
		ax	- Module token of new module
	on error:
		carry set
		ax	- destroyed

DESTROYED:	nothing

SIDE EFFECTS/NOTES:
	if successful, element added to module array, and module token
	added to task's list of open modules.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FidoOpenModule	proc	far
	uses	ds,si
	.enter
		call	TaskLockDS
		call	ModuleAdd
		pushf
		call	TaskUnlockDS
		popf
	.leave
	ret

FidoOpenModule	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FidoCloseModule
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove reference to module

CALLED BY:	GLOBAL
PASS:		ax	- Module token
		bx	- hptr.FidoTask
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Remove a reference to the module.
	Remove the module token from fido data.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FidoCloseModule	proc	far
	uses	ds
	.enter
		call	TaskLockDS
		call	ModuleRemove
		call	TaskUnlockDS
	.leave
	ret
FidoCloseModule	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FidoGetComplexData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract VM Tree of complex data from module

CALLED BY:	GLOBAL
PASS:		ax	- Module token
		bx	- hptr.FidoTask
		cx	- destination VM file
		dx	- complex data element #

RETURN:		bx:ax:si - VM Tree
		cxdx	- ClipboardItemFormatID
		carry	- set on error

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 2/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FidoGetComplexData	proc	far
	ftask		local	hptr.FidoTask	push bx
	strategy	local	fptr.far
	destFile	local	word
ForceRef ftask
	uses	di
	.enter

		mov	ss:[destFile], cx

		call	ModuleOpen	; cx <- token, ss:strategy filled in
		jc	done

		mov	ax, ss:[destFile]
		mov	ss:[TPD_dataBX], ax
		mov	di, DR_FIDOI_GET_COMPLEX_DATA
		movdw	bxax, ss:[strategy]

		push	cx
		call	ProcCallFixedOrMovable ;bxaxsi-chain. cxdx-FormatID
		pop	di
		xchg	di, cx		; cx <- token, di <- saved
		call	ModuleCloseSaveCF
		mov	cx, di		; restore cx
done:
	.leave
	ret
FidoGetComplexData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FidoGetPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a page from a module

CALLED BY:	GLOBAL
PASS:		ax	- Module token
		bx	- hptr.FidoTask (FidoTask)
		dx	- page number
RETURN:		bx	- hptr.byte
		carry	- set on error (and bx trashed)
DESTROYED:	nothing
SIDE EFFECTS:	Allocates some memory on the heap

PSEUDO CODE/STRATEGY:
	ModuleOpen, ModuleCloseSaveCF, FidoGetHeader, FidoGetPage
	all share the same stack frame.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FidoGetPage	proc	far
	ftask		local	hptr.FidoTask	push bx
	strategy	local	fptr.far
ForceRef ftask
	uses	ax,cx, si, di
	.enter
		
	; Tell driver to open the url, extracting strategy routine
	; and token needed for further driver calls.
	;
		call	ModuleOpen	; cx <- token, ss:strategy filled in
		jc	done

	; Extract page and close url
	;
		mov	di, DR_FIDOI_GET_PAGE
		movdw	bxax, ss:[strategy]
		call	ProcCallFixedOrMovable	; bx <- page

		call	ModuleCloseSaveCF
done:
	.leave
	ret
FidoGetPage	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FidoGetHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a listing of symbols exported from this module

CALLED BY:	GLOBAL
PASS:		ax	- Module token
		bx	- hptr.FidoTask
RETURN:		bx	- MemHandle to symbol data
		carry	- set on error (and bx trashed)
DESTROYED:	nothing
SIDE EFFECTS:	Allocates some memory on the heap

PSEUDO CODE/STRATEGY:
	FIXME update docs with structure of returned block

	ModuleOpen, ModuleCloseSaveCF, FidoGetHeader, FidoGetPage
	all share the same stack frame.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	12/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FidoGetHeader	proc	far
	ftask		local	hptr.FidoTask	push bx
	strategy	local	fptr.far
ForceRef ftask
	uses	ax, cx, di
	.enter

	; Tell driver to open the url, extracting strategy routine
	; and token needed for further driver calls.
	;
		call	ModuleOpen	; cx <- token, strategy filled in
		jc	done

	; Extract page and close url
	;
		mov	di, DR_FIDOI_GET_HEADER
		movdw	bxax, ss:[strategy]
		call	ProcCallFixedOrMovable

		call	ModuleCloseSaveCF
done:
	.leave
	ret
FidoGetHeader	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModuleCloseSaveCF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call DR_FIDOI_CLOSE, preserving carry

CALLED BY:	INTERNAL, FidoGetPage, FidoGetHeader
PASS:		ss:[strategy]	- driver strategy routine
RETURN:		nothing
DESTROYED:	nothing, cf preserved
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	ModuleOpen, ModuleCloseSaveCF, FidoGetHeader, FidoGetPage
	all share the same stack frame.

	caveat: saving cf causes us to ignore possible errors from
	DR_FIDOI_CLOSE (but if that's what the caller wants...)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	12/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModuleCloseSaveCF	proc	near
	ftask		local	hptr.FidoTask
	strategy	local	fptr.far
	uses	ax, bx, di
	.enter	inherit far
		movdw	bxax, ss:[strategy]
		mov	di, DR_FIDOI_CLOSE
		pushf
		call	ProcCallFixedOrMovable
		popf
	.leave
	ret
ModuleCloseSaveCF	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModuleOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call DR_FIDOI_OPEN on a module

CALLED BY:	INTERNAL, FidoGetPage, FidoGetHeader
PASS:		ax	- module NameArray element #
RETURN:		ss:[strategy]	- strategy routine
		cx	- ax returned by driver routine (handle)
		carry	- as set in driver routine
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	ModuleOpen, ModuleCloseSaveCF, FidoGetHeader, FidoGetPage
	all share the same stack frame.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	12/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModuleOpen	proc	near
	ftask		local	hptr.FidoTask
	strategy	local	fptr.far
	uses	ax,bx, es,ds,si,di
	.enter inherit	far
		mov	bx, ss:[ftask]
		call	TaskLockDS
		mov	si, ds:[FT_modules]
EC <		cmp	ax, NULL_MODULE					>
EC <		ERROR_E	FIDO_NULL_MODULE_TOKEN				>
		call	ChunkArrayElementToPtr
EC <		ERROR_C	FIDO_INVALID_MODULE_TOKEN			>

		movdw	bxax, ds:[di].MD_strategy

	; Don't pass the leading <driver>:
	;
		push	ax
		mov	di, ds:[di].MD_ml
		mov	di, ds:[di]
		segmov	es, ds, ax
		LocalLoadChar	ax, C_COLON
		mov	cx, -1
		LocalFindChar
EC <		ERROR_NZ	-1					>
		mov	si, di
		pop	ax

		mov	di, DR_FIDOI_OPEN
		movdw	ss:[strategy], bxax
		call	ProcCallFixedOrMovable

		mov_tr	cx, ax
		lahf
		call	TaskUnlockDS
		sahf
	.leave
	ret
ModuleOpen	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModuleAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and return a new module element given a URL

CALLED BY:	INTERNAL
		FidoOpenModule
PASS:		ds	- Locked FidoTask
		ax	- Module token that ML is relative to
		es:di	- ML
RETURN:		ax	- Module token
		ds	- points to same block (but possibly moved)
		carry	- set on error (and ax trashed)
DESTROYED:	nothing
SIDE EFFECTS:
	Adds element to module name array

PSEUDO CODE/STRATEGY:
	Various called fuctions inherit our frame

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModuleAdd	proc	near
	module		local ModuleData
	path		local URLBuffer
	driver_len	local word
	module_len	local word
ForceRef driver_len
	uses	bx,cx,dx,si,di,es
	.enter

	; fill in [path], [driver_len], [module_len]
		call	_Fido_MakeMLCanonical
		jc	done

	; fill in [module] with driver data
		call	ModuleGetDriver
		jc	done

	; fill in [module].MD_ml -- copy ML in es:di to chunk
		clr	ax
		mov	cx, ss:[module_len]
DBCS <		shl	cx						>
		call	LMemAlloc
DBCS <		shr	cx						>
		mov	module.MD_ml, ax

		segmov	es, ds, di
		mov	di, ax
		mov	di, es:[di]	; es:di <- new chunk

		segmov	ds, ss, ax
		lea	si, ss:[path]	; ds:si <- path buffer

		LocalCopyNString	; rep movs[bw]
		segmov	ds, es, ax	; restore ds <- locked FidoTask

	; fill in other fields -- MD_myLibrary,MD_localLibs
		mov	ax, CA_NULL_ELEMENT
		mov	ss:[module].MD_myLibrary, ax

		clr	ax, si, cx
		mov	bx, size lptr
		call	ChunkArrayCreate
	; prevent EC segment death
EC <		segmov	es, ss						>
		mov	ss:[module].MD_localLibs, si

	; Now add [module] to the array
	; ds	- locked FidoTask
	;
		mov	si, ds:[FT_modules]	;*ds:si <- NameArray
		mov	cx, ss
		lea	dx, module	; cx:dx <- module
		mov	bx, cs
		mov	di, offset EltAddCB
		call	ElementArrayAddElement	;ax <- token
		clc

done:
	.leave
	ret
ModuleAdd	endp

;; NO-FFH
EltAddCB	proc	far
	; just say elements are always not equal
	clc
	ret				
EltAddCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Fido_MakeMLCanonical
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Asm stub for C routine

CALLED BY:	INTERNAL, ModuleAdd
PASS:		ds	- Locked FidoTask
		es:di	- ML to canonicalize
		[path]	- Inherited
		ax	- Loading module or NULL_MODULE

RETURN:		[path]	- filled in
		[driver_len] - filled in
		[module_len] - filled in
		carry	- set on error, stack not filled in
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Inherits frame from ModuleAdd

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	4/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_Fido_MakeMLCanonical	proc	near
	uses	ax,bx,cx,dx,si,di, es,ds
	.enter inherit ModuleAdd

		push	ds:[LMBH_handle]
		push	ax
		pushdw	esdi		; ML to canonicalize
		lea	bx, ss:[path]
		pushdw	ssbx		; buffer
		mov	ax, URL_LENGTH_ZT
		push	ax
ifdef __BORLANDC__
 		call	FIDO_MAKEMLCANONICAL
else
		call	Fido_MakeMLCanonical
endif
		tst_clc	ax
		stc			; assume error
		jz	done

	; find the length of the entire ML, and the length
	; of the initial driver portion
	;
		lea	di, ss:[path]
		segmov	es, ss, ax

		mov	bx, di		; save
		LocalStrLength includeNull
		mov	di, bx		; restore
		mov	ss:[module_len], cx
		mov	bx, cx		; bx <- string length

		LocalLoadChar	ax, C_COLON
DBCS <		repne	scasw						>
SBCS <		repne	scasb						>
EC <		ERROR_NZ BARK_YELP_YELP					>
NEC <		stc			; assume failure		>
NEC <		jnz	done						>
		sub	bx, cx		; bx <- # chars checked, including `:'
		dec	bx		; bx <- # chars before `:'
		mov	ss:[driver_len], bx

		clc
done:
	.leave
	ret
_Fido_MakeMLCanonical	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModuleGetDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a driver handle that can deal with the module type.

CALLED BY:	INTERNAL, ModuleAdd
PASS:		ds	- Locked FidoTask
		stack	- Inherited

RETURN:		carry	- set on error, else fill in:
			MD_driver, MD_strategy, MD_driverData
DESTROYED:	nothing
SIDE EFFECTS:	
	GeodeUseDriver may be called.  If a new driver is used, handle
	will be added to task's list of used drivers.

PSEUDO CODE/STRATEGY:
	First look in our table of already-loaded drivers.  They should
	have the ML type that they support in their DriverInfoStruct.
	Use this to determine whether we should use that driver with the
	passed ML.

	If that fails, look in table we define below, which maps
	ML types (eg. DOS, BCL) into geode names of drivers (vmfi, bclfi).

	If that fails, punt.  If we want more dynamicism, we could add
	a FileEnum to search for drivers.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

makeDriverEntry DOS, vmfi
makeDriverEntry BCL, bclfi
makeDriverEntry FLAT, flatfi
makeDriverTable	InputDriverTable, vmfi, bclfi, flatfi

ModuleGetDriver	proc	near
	uses	ax,cx,si,di,ds,es
	.enter inherit ModuleAdd

	; save FidoTask in es
	;
		segmov	es, ds, cx

	; First look through the drivers this task has already
	; loaded, because doing a GeodeUseDriver is slooow (and
	; there's no point to using a driver more than once).
	;
		mov	di, es:[FT_drivers]
		mov	di, es:[di]
		mov	cx, es:[di].CDR_count
		add	di, offset CDR_data

		jcxz	loadFromTable
driverLoop:
		mov	bx, es:[di]
		call	GeodeInfoDriver

		push	si
		mov	si, ds:[si].FDIS_name
		call	compareDriver
		pop	si
		je	done		; carry will be clear if equal
		add	di, 2
		loop	driverLoop


	; Try and load a driver.  If successful, add it to this
	; task's list of used drivers so we know to GeodeFreeDriver
	; it later.
	; 
loadFromTable:
		segmov	ds, cs, ax
		mov	si, offset InputDriverTable
		jmp	tableLoop2

tableLoop:
		add	si, 4
tableLoop2:
		mov	ax, ds:[si]	; ax <- lptr or -1
		cmp	ax, -1		; end of table?
		stc			; assume failure
		je	done

		xchg	si, ax		; ds:si <- string, ax <- saved si
		call	compareDriver
		xchg	si, ax
		jne	tableLoop
		
gotDriver:
		add	si, 2		; lptr to geode name follows
		mov	si, ds:[si]
		cmp	si, -1		; no driver defined?
		stc			; assume failure
		jz	done
		
		call	FilePushDir
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath
		clr	ax, bx		; don't care about protocol #s
		call	GeodeUseDriver
		jc	donePopDir

		mov_tr	ax, bx		; ax <- driver
		mov	bx, es:[LMBH_handle]	; bx <- FidoTask
		call	Fido_AddDriver
		mov_tr	bx, ax		; bx <- driver

		call	GeodeInfoDriver
		clc

donePopDir:
		lahf
		call	FilePopDir
		sahf

done:
	; if carry not set, then
	;  ds:si- DriverInfoStruct
	;  bx	- ModuleType
		jc	afterFill	; don't fill in on error
if ERROR_CHECK
	; sanity check to see if driver _really_ matches
		push	si
		mov	si, ds:[si].FDIS_name
		call	compareDriver
		pop	si
		ERROR_NZ BARK_YELP_YELP
endif
		mov	module.MD_driver, bx
		clr	module.MD_driverData
		movdw	module.MD_strategy, ds:[si].DIS_strategy, ax
afterFill:
	.leave
	ret

ModuleGetDriver	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		compareDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if first ss:[driver_len] chars of ss:[path]
		match string in ds:si
CALLED BY:	INTERNAL
PASS:		stack	- inherited
		ds:si	- ZT string to check

RETURN:		if equal, zf set and cf clear (as with cmp)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	To expand on the synopsis...
	if ss:[path] looks like "DOS://foo/bar/..."
	then ss:[driver_len] is 3.

	We want to check if ds:si is "DOS",0

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	4/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
compareDriver	proc	near
	uses	ax,cx,es,di,si
	.enter inherit ModuleAdd

		mov	cx, ss:[driver_len]
		segmov	es, ss, ax
		lea	di, ss:[path]
	; es:di	- current ML
	; ds:si	- driver's ML name
	; cx - length of ds:si driver portion
DBCS <		repe	cmpsw						>
SBCS <		repe	cmpsb						>
		jnz	done

	; Check if we matched the whole string
	; ML should have ended at colon (always)
	; Driver's ML name should end at NULL
	;
EC <		LocalGetChar	ax, esdi, noAdvance			>
EC <		LocalCmpChar	ax, C_COLON				>
EC <		ERROR_NE	BARK_YELP_YELP				>
		LocalGetChar	ax, dssi
		LocalCmpChar	ax, C_NULL
done:
	.leave
	ret
compareDriver	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModuleRemove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a reference to a module

CALLED BY:	INTERNAL, FidoCloseModule
PASS:		ds	- Locked FidoTask
		ax	- Module token to remove
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModuleRemove	proc	near
	uses	bx,cx,si,di
	.enter
		mov	si, ds:[FT_modules]	; ds:si <- ElementArray
		mov	bx, cs
		mov	di, offset ModuleDestroy
		clr	cx		;no callback data
		call	ElementArrayRemoveReference
	.leave
	ret
ModuleRemove	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModuleDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for ElementArrayRemoveReference

CALLED BY:	INTERNAL
		ModuleRemove (through ElementArrayRemoveReference)
PASS:		ax	- callback data (none at present)
		ds:di	- ModuleData
RETURN:		none
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Go through all libraries and dec their ref count.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ModuleDestroy	proc	far
	uses	si, di
	.enter

	; Nuke MD_ml
	;
		mov	ax, ds:[di].MD_ml
EC <		mov	ds:[di].MD_ml, 0xdead				>
		call	LMemFree

	; If this was an aggregate module, mark its FT_libraries entry
	; so Fido knows it's gone away (and therefore can't create more
	; components)
	;
		mov	ax, ds:[di].MD_myLibrary
		cmp	ax, CA_NULL_ELEMENT
		je	nukeLibs
		push	di
		mov	si, ds:[FT_libraries]
		mov	bx, cs
		mov	di, offset Fido_DestroyLibrary
		call	ElementArrayRemoveReference
		pop	di
		jc	nukeLibs	; stc if element removed

	; lib elt is being used by others, so mark it as unusable
		push	di
		call	ChunkArrayElementToPtr
		mov	ds:[di].LD_library, 0xdead
		mov	ds:[di].LD_myModule, CA_NULL_ELEMENT
		mov	si, ds:[di].LD_components
		call	ChunkArrayZero
		pop	di		
nukeLibs:

	; Nuke MD_localLibs after decrefing all libraries
	;
		push	di
		mov	si, ds:[di].MD_localLibs
EC <		mov	ds:[di].MD_localLibs, 0xdead			>
		mov	bx, cs
		mov	di, offset DecRefLibraryCB
		call	ChunkArrayEnum
		pop	di
		mov	ax, si
		call	LMemFree
		
	.leave
	ret
ModuleDestroy	endp

;; *ds:si - array
;; ds:di - array elt
;; ax cx dx bp es -- passed data
;; can destroy bx, si, di
;; NO-FFH
DecRefLibraryCB	proc	far
	uses	ax
	.enter
		mov	ax, ds:[di]
		mov	si, ds:[FT_libraries]
		mov	bx, cs
		mov	di, offset Fido_DestroyLibrary
		call	ElementArrayRemoveReference
	.leave
	ret
DecRefLibraryCB	endp
MainCode	ends
