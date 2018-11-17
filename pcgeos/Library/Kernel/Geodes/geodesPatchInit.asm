COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel
FILE:		geodesPatchInit.asm

AUTHOR:		Paul Canavese, Jan 27, 1995

ROUTINES:

	Name			Description
	----			-----------

	(See geodesPatch.asm for an overview to the patching code.) 

SYSTEM PATCHING INITIALIZATION

On system startup (InitGeos), create a list of general patch files and set
the "multi-language mode" kernel constant.  

	InitGeneralPatches	Initializes the general patching
				module of the kernel.
	-------------------------------------------------------------
	BuildPatchFileList	Enumerates patch files in the current
				directory and creates a list of them.

	InitLanguagePatches	Initialize kernel variable for
				multi-language mode.

Check for general patches referring to the same geode, deleting all
but the newest.

	GeodeKillObsoletePatches	Search the patch file list for
				patch files for the same geode.  When
				matches are found, delete the older 
				file and its entry from the list.
	-------------------------------------------------------------
	GeodeKillPatchIfObsolete	Compare passed patch file to
				all files above it in the list.  If
				there is another file in the list to
				patch the same geode, nuke the older
				one.
	-------------------------------------------------------------
	GeodeKillOlderPatchIfMatch	If the passed patch filenames
				refer to patches on the same geode,
				delete the older one and remove it
				from the list.

Apply the general patches, as well as any language patches in the 
standard path to geodes that are already running.  

	GeodePatchRunningGeodes	Apply any necessary patches to core blocks
				for geodes that have already been loaded.
	-------------------------------------------------------------
	PatchRunningGeodeCB	Callback routine to apply patches to
				any geodes that are already running.

The FixedStrings resource has to be patched specially, since it needs to
be fixed.  For XIP multi-language platforms, it is initially loaded in as a
non-fixed resource, and this routine moves it to a fixed block on the heap,
patching it if necessary. 

	GeodeProcessFixedStringsResource	Move the kernel's
				FixedStrings resource to a fixed block,
				patching it if necessary.

INTRODUCING NEW PATCHES

If a new general patch file needs to be introduced to the system
afterwards, add it to the list.

	GeodeInstallPatch	Install a new patch file (that was not
				present when the system was
				initialized).
	-------------------------------------------------------------
	InstallPatchRunningGeodeCB	Callback routine to check if
				the patch file to be installed affects
				a running geode.
	GeodeExpandPatchList	Reallocate the passed patch file list
				to hold an additional filename.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	1/27/95   	Initial revision


DESCRIPTION:
	Code for initializing the geode patching module of the kernel
	and introducing new patch files.	
		

	$Id: geodesPatchInit.asm,v 1.1 97/04/05 01:12:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; We need these so we can reference these in GeodePatchRunningGeodes.

StandardPathStrings segment lmem
StandardPathStrings ends

InitStrings segment  lmem
InitStrings ends

LocalStrings segment  lmem
LocalStrings ends

kinit	segment

if USE_BUG_PATCHES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitGeneralPatches
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the general patching module of the kernel.

CALLED BY:	InitGeos

PASS:		ds	- kdata

RETURN:		carry set on error
		ds:[generalPatchFileList] filled in with either the
		handle of a block containing patch files, or -1 if
		there are no patches. 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

returnAttrs	FileExtAttrDesc \
	<FEA_DOS_NAME, 0, DosDotFileName>,
	<FEA_END_OF_LIST>

InitGeneralPatches	proc near
		uses 	bx, dx
		.enter

EC <		call	AssertDSKdata					>

	; First, go to the patch file directory.

		call	GeodeSetGeneralPatchPath
		jc	done			; Error on setting path. 

	; Create a list of all patch files in current directory.

		mov	dx, offset generalPatchFileList
		call	BuildPatchFileList
		jc	done			; No list was created.
		call	GeodeKillObsoletePatches
		
done:
		call	FilePopDir
		.leave
		ret
InitGeneralPatches	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildPatchFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerates all patch files in the current directory and
		creates a list of them.

CALLED BY:	InitGeneralPatches

PASS:		ds:dx	= pointer to set to handle of enumerated list
RETURN:		if a list was created
			carry clear
			bx = handle of new (LOCKED) patch file list
		else
			carry set

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
	Fetch the DOS name, because these are DOS files, and because 
	it's easier in DBCS to compare permanent names against	DOS 
	names than GEOS names.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	10/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildPatchFileList	proc	near
		uses	ax,cx,dx,si,di,bp,es
		.enter

	; Prepare for returned attributes.

		push	dx			; Offset of pointer to list. 
		segmov	ds, cs
		mov	si, offset returnAttrs
FXIP <		mov	cx, size returnAttrs				>
FXIP <		call	SysCopyToStackDSSIFar				>
		
	; Enumerate all patch files in current directory.

		sub	sp, size FileEnumParams
		mov	bp, sp
		
		clr	ax
		mov	ss:[bp].FEP_headerSize, size PatchFileListHeader
		movdw	ss:[bp].FEP_matchAttrs, axax
		mov	ss:[bp].FEP_searchFlags, mask FESF_NON_GEOS or \
					mask FESF_LEAVE_HEADER
		mov	ss:[bp].FEP_returnAttrs.segment, ds
		mov	ss:[bp].FEP_returnAttrs.offset, si
		mov	ss:[bp].FEP_returnSize, size DosDotFileName
		mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
		mov	ss:[bp].FEP_skipCount, ax
		
		call	FileEnum
FXIP <		call	SysRemoveFromStackFar				>

		pop	bp			; Offset of pointer to list. 
		pushf
		LoadVarSeg	ds, ax
		popf
		jc	done
		jcxz	error

	; Save the list of patch files.

		mov	ds:[bp], bx
		call	MemLock
		mov	es, ax
		mov	es:[PFLH_count], cx
		clc		

done:
		.leave
		ret

error:
		stc
		jmp	done

BuildPatchFileList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeKillObsoletePatches
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search the patch file list for patch files for the
		same geode.  When matches are found, delete the older
		file and its entry from the list.

CALLED BY:	InitGeneralPatches, GeodeInstallPatch
PASS:		bx 	= handle of patch file list
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	11/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeKillObsoletePatches	proc	far
		uses	ax,cx,di,es
		.enter

	; Find the start of the patch file list.

		call	MemLock
		mov	es, ax
		mov	di, offset PFLH_files

	; Find the size of list.

		mov	ax, size DosDotFileName
		mul	{byte} es:[PFLH_count]
		add	ax, size PatchFileListHeader
			; ax = size of list block.
		mov	cx, ax		; Size of patch file list.

patchFileLoop:

	; Check all patch files below this one.  If a match is found,
	; delete the older file and its entry in the list.

		call	GeodeKillPatchIfObsolete

	; A patch file was deleted... recheck from the current offset.
	; (The entry that was at this offset may have just been deleted.)

		jc	patchFileLoop	

	; Look at the next entry.

		add	di, size DosDotFileName

	; Are there more entries to check?

		cmp	di, cx
		jb	patchFileLoop

	; Clean up.

		call	MemUnlock

		.leave
		ret
GeodeKillObsoletePatches	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeKillPatchIfObsolete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare passed patch file to all files above it in the
		list.  If there is another file in the list to patch
		the same geode, nuke the older one.

CALLED BY:	GeodeKillObsoletePatches

PASS:		bx	= handle of patch file list
		cx	= size of patch file list
		es:di	= patch filename to compare with all later entries

RETURN:		es 	= segment of patch file list
		if entry deleted
			carry set
			cx = size of patch file list
		else
			carry clear

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	12/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeKillPatchIfObsolete	proc	near
		uses	ax,bx,dx,si,di,bp,ds
		.enter

	; Find the filename at the cx position.

		segmov	ds, es, si
		mov	si, di		; Offset of first entry.

	; Determine how many filename characters to compare.

		call	CountCharactersBeforePeriodFar
			; dx = characters to compare
		mov	ax, dx

patchFileLoop:

	; Check next entry.

		add	si, size DosDotFileName
		cmp	si, cx
		jae	noMatch

	; Compare passed filename prefix with loop filename prefix.

		xchg	cx, dx
			; cx = characters to compare.
			; dx = size of patch file list.
		push	si, di		; String offsets.
		repe	cmpsb
		pop	si, di		; String offsets.
		mov	cx, dx	; Size of patch file list.	
		mov	dx, ax	; Characters to compare.
		jne	patchFileLoop

	; Compare the geode permanent names.

		call	GeodeKillOlderPatchIfMatch
		jc	done		; A patch file was deleted.
		jmp	patchFileLoop

noMatch:
		clc

done:
		.leave
		ret
GeodeKillPatchIfObsolete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeKillOlderPatchIfMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the passed patch filenames refer to patches on the
		same geode, delete the older one and remove it from
		the list.

CALLED BY:	GeodeKillPatchIfObsolete

PASS:		bx	= handle of patch file list
		cx	= size of patch file list
		ds	= segment of patch file list
		si	= offset of first filename to compare
		di	= offset of second filename to compare

RETURN:		ds, es	= segment of patch file list
		if entry deleted
			carry set
			cx = size of patch file list
		else
			carry clear

DESTROYED:	ds

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	12/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeKillOlderPatchIfMatch	proc	near
		uses	ax,bx,dx,si,di,bp

patchFileHandle		local	word	push	bx
patchFileListSize	local	word	push	cx
patchFileName1Offset	local	word	push	si
patchFileName2Offset	local	word	push	di
patchFileHeader1	local	PatchFileHeader
patchFileHeader2	local	PatchFileHeader

		.enter

	; Load in first file header.

		segmov	es, ss, ax	; es:di = file header buffer
		lea	di, ss:[patchFileHeader1]
		call	GeodePatchFileGetHeaderFar
		jc	noMatch
		call	FileCloseFar

	; Load in second file header.

		lea	di, ss:[patchFileHeader2]
		mov	si, ss:[patchFileName2Offset]
		call	GeodePatchFileGetHeaderFar
		jc	noMatch
		call	FileCloseFar

	; Check if the geode name matches.

		push	ds
		segmov	ds, ss, si	
		lea	si, ss:[patchFileHeader1].PFH_geodeName
		lea	di, ss:[patchFileHeader2].PFH_geodeName
		mov	cx, (GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE)/2
		repe	cmpsw
		pop	ds
		jne	noMatch

	; Names match.  Is one release major number older?

		mov	cx, ss:[patchFileHeader1].PFH_newRelease.RN_major
		cmp	cx, ss:[patchFileHeader2].PFH_newRelease.RN_major
		ja	killSecondFile		
		jb	killFirstFile

	; Which release minor number is older?

		mov	cx, ss:[patchFileHeader1].PFH_newRelease.RN_minor
		cmp	cx, ss:[patchFileHeader2].PFH_newRelease.RN_minor
		ja	killSecondFile

killFirstFile:

		mov	dx, ss:[patchFileName1Offset]
		jmp	doFileKill

killSecondFile:

		mov	dx, ss:[patchFileName2Offset]

doFileKill:

	; Remove actual file.

		call	FileDelete

	; Remove entry in the patch file list.

	; Move all later entries up.

		segmov	es, ds, di	; Patch file list segment.
		mov	di, dx		; Offset of entry to delete.
		mov	si, dx		; Offset of entry to delete.
		add	si, size DosDotFileName
		mov	cx, ss:[patchFileListSize]
		sub	cx, si		; Size of block to move up.
		LocalCopyNString

	; Reallocate the patch file list.

		mov	ax, ss:[patchFileListSize]
		sub	ax, size DosDotFileName
		push	ax		; New patch list size.
		clr	ch
		mov	bx, ss:[patchFileHandle]
		call	MemReAlloc
		mov	es, ax
		mov	ds, ax

	; Decrement patch file entry count.

		dec	es:[PFLH_count]
		pop	cx		; New patch list size.
		stc
		jmp	done

noMatch:
		segmov	es, ds, dx
		clc
done:
		.leave
		ret
GeodeKillOlderPatchIfMatch	endp

endif ; USE_BUG_PATCHES

if USE_PATCHES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchRunningGeodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply any necessary patches to core blocks for geodes that
		have already been loaded.

CALLED BY:	InitGeos
PASS:		ds - kdata
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	1. Walk through each geode already loaded and patch its core
	   block if necessary.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	11/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchRunningGeodes	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

	; For each geode that's already running, check if there
	; is a patch file.  If so, apply changes to the core block.

		clr	bx
		mov	di, SEGMENT_CS
		mov	si, offset PatchRunningGeodeCB
		call	GeodeForEach

if MULTI_LANGUAGE and FULL_EXECUTE_IN_PLACE

	; If in multi-language mode, discard patchable kernel resources that
	; may have been loaded in already.

		tst 	ds:[multiLanguageMode]
		jz	done
	
	; Check if the resource has been loaded in.
		
		mov	si, offset DiscardResourceTable
nextResource:
		mov	bx, cs:[si]
		test	ds:[bx].HM_flags, mask HF_DISCARDED
		jnz	afterDiscard		; Already discarded.

	; It has been loaded in.  Discard it so it has to be loaded in
	; again, this time through the patching facility.

		call 	MemDiscard

afterDiscard:
		add	si, 2
		cmp	si, offset DiscardResourceTable + \
				size DiscardResourceTable
		jb	nextResource

done:
endif
		.leave
		ret
GeodePatchRunningGeodes	endp


if MULTI_LANGUAGE and not FULL_EXECUTE_IN_PLACE
	PrintMessage <WARNING: Some kernel resources will not be language-patched correctly in non-XIP.>
endif

if MULTI_LANGUAGE and FULL_EXECUTE_IN_PLACE

DiscardResourceTable	hptr \
	handle MovableStrings, 
	handle LocalStrings,
	handle StandardPathStrings,
	handle InitStrings

endif

if FULL_EXECUTE_IN_PLACE and MULTI_LANGUAGE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeProcessFixedStringsResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the kernel's FixedStrings resource to a fixed block,
		patching it if necessary. 

CALLED BY:	InitGeos
PASS:		ds = kdata
		es = kdata
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	canavese	5/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeProcessFixedStringsResource	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

	; Attempt to language-patch the kernel's FixedStrings resource.

		mov	bx, handle FixedStrings
		push	bx			; Handle of original block.
		call	GetByteSizeFar		; ax, cx = size of original block.

	; Change the heap allocation flags of the old block.

		mov	cl, mask HF_FIXED or mask HF_LMEM
		mov	ch, mask HAF_NO_ERR or mask HAF_READ_ONLY
		mov	{word} ds:[bx].HM_flags, cx
		push	ax			; Size of fixed strings.
		mov	al,DEBUG_MODIFY		; Notify debugger of block modification.
		call	FarDebugMemory
		pop	ax			; Size of FixedStrings.

	; Allocate a new fixed block.

		push	bx, ax			; Old handle, size.
		call	MemAllocFar
		mov	es, ax			; Destination block segment.
		mov	dx, bx			; Destination block handle.
		mov	bp, bx			; Destination block handle.
		pop	bx, cx			; Old handle, size.
		push	dx, ds			; Destination block handle, kdata

	; Get the resource number.

		call	HandleToID
		mov	si, bx			; Resource id.
		shl	si, 1			; Resource id * 2
		mov	ds, ax			; Core block of owner (kernel).
		
	; Decrement the lock count on the kernel's GeodeHeader (which was
	; incremented by HandleToID).

		mov	bx, ds:[GH_geodeHandle]
		call	MemUnlock

	; Is multi-language mode on?

		call	IsMultiLanguageModeOn
		jc	noPatchDataFound	; Nope.  So don't patch, eh?

	; Check if patch data exists for this resource.

		mov	bx, ds:[GH_languagePatchData]
		tst	bx
		jz	noPatchDataFound
		push	es			; Destination block segment.
		mov	ax, es			; Destination block segment.
		call	SearchPatchResourceList	; es:di	= PatchedResourceEntry.
		jc	noPatchDataFoundPopES

		push	bx			; Patch data handle.
		mov	bx, bp
		call	GeodeLoadPatchedResourceFar
		pop	bx			; Patch data handle.
		pop	es			; Destination block segment.

	; Unlock patch data block.

		call	MemUnlock
		pop	ds			; kdata

cleanUp:

	; Record in kdata the permanent location of FixedStrings.

		mov	ds:[fixedStringsSegment], es

	; Swap the handles.

		pop	bx			; Handle of old block.
		pop	si			; Handle of new block.
		call	MemSwap

	; Free the old block, restore kdata.

		call	MemFree
		segmov	es, ds, bx		; kdata

		.leave
		ret


noPatchDataFoundPopES:
		pop	es				; Destination block.

noPatchDataFound:

	; Copy old block into new fixed block.

		pop	ds				; kdata
		push	ds				; kdata.
		mov	ds, ds:[fixedStringsSegment]
		clr	si, di
		shr	cx, 1
		rep	movsw
		pop	ds				; kdata
		jmp	cleanUp

GeodeProcessFixedStringsResource	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatchRunningGeodeCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to apply patches to any geodes that
		are already running

CALLED BY:	GeodePatchRunningGeodes via GeodeForEach

PASS:		ax - segment of list of patch filenames
		ds - kdata
		es - segment of geode's core block

RETURN:		nothing 

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		NOTE:  This routine will only lead to updating the
		core block of a geode that is already running, and
		will not affect resources that are already loaded in.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/ 1/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PatchRunningGeodeCB	proc far
		uses	bx
		.enter

EC <		call	ECCheckCoreBlockES				>	
		segxchg	ds, es		; ds = core block seg, es = kdata

	; Search the patch file lists for this geode.  Apply if found.	

		clr	di			; Not loading geode

if USE_BUG_PATCHES
		call	GeodeOpenGeneralPatchFile
endif

if MULTI_LANGUAGE

	; Try to open a language patch file if we're in mode.

		tst	es:[multiLanguageMode]
		jz	afterLanguageStuff		; Is false.
		call	GeodeOpenLanguagePatchFile

afterLanguageStuff:
endif

if USE_BUG_PATCHES

	; If any general patch data was found, update the core block.
	;
	; Language patches do not need to change the core block, since
	; they will not change the number of resources in the geode.

		tst	ds:[GH_generalPatchData]
		jz	done

	; Grab some kind of lock to keep other threads from possibly
	; using this core block while we're in the process of
	; modifying it.  I'll grab the FSD lock exclusive, since
	; LoadResourcePrelude grabs it shared.  Let's hope this works.

		call	FSDLockInfoExcl

	; Reallocate the core block, patch it, initialize and load in
	; any appropriate new resources, and relocate the export table.

		call	GeodePatchModifyCoreBlock

	; Release the lock.

		call	FSDUnlockInfoExcl		

	; Unlock the patch data block.

		mov	bx, ds:[GH_generalPatchData]
		call	MemUnlock
endif	
	
done::
		segmov ds, es, ax		; ds = kdata
		clc
		.leave
		ret
PatchRunningGeodeCB	endp

endif ; USE_PATCHES


if MULTI_LANGUAGE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitLanguagePatches
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize kernel variable for multi-language mode.

CALLED BY:	InitGeos
PASS:		ds = kdata
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	canavese	5/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString kmultiLanguageCategory <"system", 0>
LocalDefNLString kmultiLanguageKey <"multiLanguage",0>

InitLanguagePatches	proc	near
		uses	ax,cx,dx,si
		.enter

	; Get ini file value.

		push	ds
		clr	ax	; So ax will indicate correct
				; multiLanguage mode status, even if
				; the category is not found.
		mov	si, offset kmultiLanguageCategory
		mov	cx, cs
		mov	ds, cx
		mov	dx, offset kmultiLanguageKey
		call	InitFileReadBoolean
		pop	ds

	; Save result in kdata.

		mov	ds:[multiLanguageMode], ax

		.leave
		ret
InitLanguagePatches	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeInstallPatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install a new (general) patch file (that was not
		present when the system was initialized).

CALLED BY:	GLOBAL

PASS:		ds:si - filename of patch file

RETURN:		cx	= PatchInstallResult
		if error
			carry set
		else
			carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/ 1/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeInstallPatch	proc far
if USE_BUG_PATCHES
		uses	ax,bx,dx,si,di
		.enter

		push	ds, si			; New patch filename.

	; For each geode that's already running, check if it is ours.

		clr	bx
		movdw	cxdx, dssi	; Filename.
		mov	di, SEGMENT_CS
		mov	si, offset InstallPatchRunningGeodeCB
		call	GeodeForEach
		jc	geodeRunning

	; Check if this is the first patch file.

		LoadVarSeg	es, bx
		mov	bx, es:[generalPatchFileList]
		tst	bx		; Are we the first patch file?
		jne	reAllocOldList

allocNewList::

	; This is the first patch file.  Allocate a new list.

		mov	ax, size PatchFileListHeader
		mov	di, ax			; Offset for filename.
		add	ax, size DosDotFileName
		clr	cl
		mov	ch, mask HAF_LOCK
		call	MemAllocFar
		jc	done			; Error.

	; Initialize the new list.

		mov	es:[generalPatchFileList], bx
		mov	es, ax			; New block.
		mov	es:[PFLH_count], 1	; We are only patch.
		jmp	addToList

reAllocOldList:

	; Add an entry to the list.

		call	GeodeExpandPatchList	; es:di = new entry.

addToList:

	; Copy new filename into list.

		pop	ds, si			; Patch filename.
		mov	cx, size DosDotFileName
		rep	movsb

		call	MemUnlock
		call	GeodeKillObsoletePatches
		mov	cx, PIR_SUCCESSFUL_INSTALL
done:
		.leave
endif
		ret

if USE_BUG_PATCHES

geodeRunning:		
		pop	ds, si			; New patch filename.
		mov	cx, PIR_GEODE_IN_USE
		stc
		jmp	done
endif

GeodeInstallPatch	endp


if USE_BUG_PATCHES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InstallPatchRunningGeodeCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to check if the patch file to be
		installed affects a running geode.

CALLED BY:	GeodeInstallPatch via GeodeForEach

PASS:		bx	- handle of geode to process
		es 	- segment of geode's core block
		cx:dx	- patch filename

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	11/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InstallPatchRunningGeodeCB	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds

geodeNameBase	local	(GEODE_NAME_SIZE) dup (char)
patchFileHeader	local	PatchFileHeader

		.enter

EC <		call	ECCheckCoreBlockES				>	

	; Load this geode's name base into our buffer.

		mov	si, dx			; Patch filename offset.
		segmov	ds, es, di		; Core block.
		lea	di, ss:[geodeNameBase]	; ss:di = name buffer.
		call	GeodeConstructPatchFilename
			; dx = size of filename base

	; Compare with patch file name.

		mov	bx, ds			; Core block.
		mov	ds, cx			; ds:si = patch filename.
		segmov	es, ss, di
		lea	di, ss:[geodeNameBase]	; ss:di = name buffer.
		mov	cx, dx			; Characters to check.
		mov	ax, si			; Patch filename offset.
		repe	cmpsb
		jne	doneClearCarry		; No match.

	; Check the permanent name.

		mov	es, bx			; Core block.
		mov	si, ax			; Patch filename offset.
		lea	di, ss:[patchFileHeader]; ss:di = header buffer.
		call	GeodePatchCheckPermanentNameFar
		jnc	match		; Geode for patch is running.

doneClearCarry:

		clc
done:
		.leave
		ret

match:
		mov	bx, si			; Patch file handle.
		call	FileCloseFar
		stc
		jmp	done

InstallPatchRunningGeodeCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeExpandPatchList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reallocate the passed patch file list to hold an
		additional filename.

CALLED BY:	GeodeInstallPatch

PASS:		bx	= handle of locked patch file list

RETURN:		es	= segment address of locked patch file list 
		di	= offset of new entry

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	11/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeExpandPatchList	proc	near
		uses	ax,cx
		.enter

EC <		call	ECCheckMemHandleFar				>

	; Lock down the patch file list.

		call	MemLock
		mov	ds, ax

	; Calculate new size of the list.

		mov	ax, ds:[PFLH_count]
		inc	ax			; We're adding one.
		mov	cx, size DosDotFileName
		mul	cx			; ax = new size of block.
		add	ax, size PatchFileListHeader

	; Calculate offset for new filename.

		mov 	di, ax			; New size of block.
		sub	di, size DosDotFileName	; ds:di = destination
						; for new patch filename.
	; Perform reallocation.

		clr	ch			; HeapAllocationFlags.
		call	MemReAlloc
		; should I handle error?
		mov	es, ax		; es:di = destination (in list).
		inc	es:[PFLH_count]	; Increment patch file count.

		.leave
		ret
GeodeExpandPatchList	endp



endif ; USE_BUG_PATCHES


kinit	ends
