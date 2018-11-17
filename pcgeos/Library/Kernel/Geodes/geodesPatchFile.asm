COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel
FILE:		geodesPatchFile.asm

AUTHOR:		Paul Canavese, Jan 27, 1995

ROUTINES:
	Name			Description
	----			-----------

	(See geodesPatch.asm for an overview to the patching code.) 

DETERMINE IF GEODE SHOULD BE PATCHED

These routines check if there are any patch files associated with a
particular geode, loading in the patch data if it exists.

These routines are called after the system patching initialization,
once for each geode that is already open.  Then they are called once
for every geode subsequently loaded.  

	GeodeOpenGeneralPatchFile	Search the general patch file 
				list for the geode being loaded.  
				Load patch data from any matching 
				files. 
	GeodeOpenLanguagePatchFile	Search the language patch 
				path for the geode being loaded.  
				Load patch data from any matching 
				files. 
	-------------------------------------------------------------
	GeodeOpenPatchFileFromList	Opens a patch file (if one 
				exists)	from the passed patch file
				list and directory.
	-------------------------------------------------------------
	GeodeLoadPatchData	Read the proposed patch file's header,
				and check the permanent name, token,
				and protocol numbers.  If they match,
				return a locked block with the patched
				data.
	-------------------------------------------------------------
	SetOwnerToGeodeES	Set the owner of the handle (bx) to
				the geode whose core block is at ES.

GENERAL FILE ROUTINES

Routines dealing with the patch paths.

	GeodeSetGeneralPatchPath	Sets the current path to the
				directory for general (non-language)
				patch files.
	GeodeSetLanguagePatchPath	Sets the current path to the
				directory for language patch files.
	GeodeSetLanguageStandardPath	Change to the mirrored standard 
				path directory, inside 
				PRIVDATA/LANGUAGE/<Current Language>.
	CreateLanguagePatchDir	Creates the
				PRIVDATA/LANGUAGE/CurrentLanguageName 
				directory if it doesn't exist.
	BuildLanguagePatchPath	Returns a buffer containing the path
				of the current language's directory in
				the PRIVDATA standard path.

Routines to figure out the filename.

	GeodePatchCheckPermanentName	Open the proposed patch file 
				and make sure the permanent name and 
				GeodeAttrs match those of the geode 
				we're loading.
	GeodeConstructPatchFileName	Copy the geode's name base
				from the core block to es:di,
				converting it to all caps along the
				way.

Other random stuff

	CountCharactersBeforePeriod	Returns the number of
				characters preceding a period in the
				passed patch filename.
	GeodePatchFileGetHeader	Open the specified patch file and read
				in the header.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	1/27/95   	Initial revision


DESCRIPTION:
	Code for loading data in from patch files.
		

	$Id: geodesPatchFile.asm,v 1.1 97/04/05 01:12:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include initfile.def
include kernelGlobal.def

GLoad	segment	resource

if USE_PATCHES

if USE_BUG_PATCHES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeOpenGeneralPatchFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a patch file for the geode being loaded, and
		load in the patch file data if found.

CALLED BY:	LoadGeodeAfterFileOpen (for new non-XIP geodes), 
		PatchRunningGeodeCB (for already-loaded geodes),
		GeodePatchXIPGeode (for new XIP geodes)

PASS:		es - kdata
		ds - core block
		ss:di - pointer to ExecutableFileHeader's
		        EFH_udataSize field, if called by
			LoadGeodeAfterFileOpen (otherwise, pass di=0)

RETURN:		ds - fixed up if reallocated
		if patch file exists:
			ds:GH_generalPatchData
			contains handle of LOCKED PatchDataHeader block.

DESTROYED:	ax,bx,cx,dx,si

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/14/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeodeOpenGeneralPatchFile	proc	far

EC <		call	ECCheckCoreBlockDS				>
EC <		call	ECCheckDGroupES					>

	; Exit quickly if there are no patches.

		tst	es:[generalPatchFileList]
		jnz	continue
		ret
continue:

	; Some patch files exist, so check for our geode.

		uses	es, di
		
permNameBase	local	(GEODE_NAME_SIZE + 4) dup (char)
		
		.enter

	; Construct the patch filename.
		
		mov	si, di				; ss:si = udata size
		lea	di, ss:[permNameBase]		; ss:di = name buffer.
		call	GeodeConstructPatchFilename
			; dx = size of filename base

	; Try to load a general (non-language) patch file.

		LoadVarSeg	es, bx
		mov	bx, es:[generalPatchFileList]
		tst 	bx
		jz	done				; No general patch file.
		call	GeodeSetGeneralPatchPath
		lea	di, ss:[permNameBase]		; ss:di = name buffer.
		call	GeodeOpenPatchFileFromList
			; dx = handle to general patch data.
		jc	done
		mov	ds:[GH_generalPatchData], dx

done:
		call	FilePopDir
		.leave
		ret

GeodeOpenGeneralPatchFile	endp

endif ; USE_BUG_PATCHES

if MULTI_LANGUAGE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeOpenLanguagePatchFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a language patch file for the geode being
		loaded, and load in the patch file data if found.

CALLED BY:	LoadGeodeAfterFileOpen (for new non-XIP geodes), 
		PatchRunningGeodeCB (for already-loaded geodes),
		GeodePatchXIPGeode (for new XIP geodes)

PASS:		es - kdata
		ds - core block
		ss:di - pointer to ExecutableFileHeader's
		        EFH_udataSize field, if called by
			LoadGeodeAfterFileOpen (otherwise, pass di=0)

RETURN:		ds - fixed up if reallocated
		if patch file exists:
			ds:GH_languagePatchData 
			contains handle of LOCKED PatchDataHeader block.

DESTROYED:	ax,bx,cx,dx,si

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString wildCardString <".p*",0>
gLoadReturnAttrs	FileExtAttrDesc \
	<FEA_DOS_NAME, 0, DosDotFileName>,
	<FEA_END_OF_LIST>

GeodeOpenLanguagePatchFile	proc	far
		uses	ax,bx,cx,dx,si,di,es,bp

permNameBase	local	(GEODE_NAME_SIZE + 4) dup (char)

		.enter

EC <		call	ECCheckCoreBlockDS				>
EC <		call	ECCheckDGroupES					>

	; Check if the file system driver that we need has been
	; loaded in yet.

		tst	es:[fullFileSystemDriverLoaded]
		LONG jz	done

	; Change to the correct language patch directory.

		call	GeodeSetLanguagePatchPath

	; Construct the wildcard patch filename.

		push	di				; udata size.
		segmov	es, ss, si	; Stack segment for local buffer. 
		lea	di, ss:[permNameBase]		; ss:di = name buffer.
		mov	si, offset GH_geodeName
		mov	cx, size GH_geodeName
copyName:		
		lodsb
		cmp	al, ' '
		je	makeWildCard	; Done when we hit a space.
		stosb
		loop	copyName

makeWildCard:
		push	ds, bp		; Core block, locals.
		segmov	ds, cs, si	; Code segment for wild card string.
		mov	si, offset wildCardString
		LocalCopyString
		lea	di, ss:[permNameBase]
	
	; Enumerate all patch files, looking for this geode.

		segmov	ds, cs
		mov	si, offset gLoadReturnAttrs
FXIP	<	mov	cx, size gLoadReturnAttrs			>
FXIP 	<	call	SysCopyToStackDSSIFar				>

		sub	sp, size FileEnumParams
		mov	bp, sp

		clr	ax
		mov	ss:[bp].FEP_headerSize, size PatchFileListHeader
		movdw	ss:[bp].FEP_matchAttrs, axax
		mov	ss:[bp].FEP_searchFlags, mask FESF_NON_GEOS or \
					mask FESF_LEAVE_HEADER \
					or mask FESF_CALLBACK
		mov	ss:[bp].FEP_returnAttrs.segment, ds
		mov	ss:[bp].FEP_returnAttrs.offset, si
		mov	ss:[bp].FEP_returnSize, size DosDotFileName
		mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
		mov	ss:[bp].FEP_skipCount, ax

		mov	ss:[bp].FEP_callback.segment, ax
		mov	ss:[bp].FEP_callback.offset, FESC_WILDCARD
		mov	ss:[bp].FEP_cbData1.segment, ss
		mov	ss:[bp].FEP_cbData1.offset, di
		mov	ss:[bp].FEP_cbData2.low, TRUE
		
		call	FileEnum
			; bx = list of matching files.

FXIP	<	call	SysRemoveFromStackFar				>
		pop	ds, bp				; Core block, locals.

		pop	si				; udata size.
		jcxz	doneWithPop			; No patch files found.

	; Record the size of the list.

		call	MemLock
		mov	es, ax
		mov	es:[PFLH_count], cx
		call	MemUnlock

	; Try to open a patch file from the list.

		clr	dx				; Don't check filenames.
		call	GeodeOpenPatchFileFromList
			; dx = handle to language patch data.
		jc	doneWithFreeAndPop		; No matching patch file.

	; Save the patch data.

		mov	ds:[GH_languagePatchData], dx

doneWithFreeAndPop:
		call	MemFree		; Free list of files from FileEnum.

doneWithPop:
		call	FilePopDir

done:
		.leave
		ret

GeodeOpenLanguagePatchFile	endp

endif ; MULTI_LANGUAGE



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeOpenPatchFileFromList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens a patch file (if one exists) from the passed
		patch file list and directory.

CALLED BY:	GeodeOpenGeneralPatchFile, GeodeOpenLanguagePatchFile

PASS:		ds	= core block address
		bx	= block of patch file list to check
		dx	= size of patch file name base (zero if name
				base does not need to be checked).
		ss:di	= name buffer (if dx > 0)
		ss:si - pointer to ExecutableFileHeader's
		        EFH_udataSize field, if called by
			LoadGeodeAfterFileOpen (otherwise, pass di=0)

RETURN:		ds	= core block address (fixed up if necessary).
		if error,
			carry set
		else
			carry clear
			dx = handle of LOCKED patch data

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	When language patch files are being passed in, we already know
	that each entry in the file list matches the permanent name.
	This is why dx will be passed in as zero, and this step is
	skipped in the matching loop.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	10/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeOpenPatchFileFromList	proc	far

		uses	ax,bx,cx,si,di,bp,es

udataPtr	local	word	push	si
coreBlock	local	sptr	push	ds
fileHeader	local	PatchFileHeader
patchFile	local	hptr

		.enter	

EC <		call	ECCheckCoreBlockDS			>
EC <		call 	ECCheckMemHandleFar	; bx		>

	; Lock the list of patch files and look for this filename
	
		call	MemLock
		mov	ds, ax
		mov	si, offset PFLH_files
		mov	ax, ds:[PFLH_count]

	; Do we already know the filename matches?

		tst	dx
		jz	fileNameMatches		; Filename matches.

	; Prepare for comparing with name base. 

		segmov	es, ss
		mov	cx, dx			; String size.

compareLoop:
	
	; Try to match the permanent name base against the filename.
	
		push	si, di
		repe	cmpsb
		pop	si, di
		jne	next			; No match.
	
fileNameMatches:	

	; A possible match is found.  Open the patch file and check
	; the full permanent name.

		mov	es, ss:[coreBlock]
		lea	di, ss:[fileHeader]
		call	GeodePatchCheckPermanentName
			; If found, 
			; 	ss:[fileHeader] = patch file header.
			; 	si = patch file handle.
		jnc	found

next:
	; Did not match.  Are there more entries?

		add	si, size DosDotFileName
		dec	ax
		jz	noMatches

	; Try next entry.

		tst	dx
		jz	fileNameMatches	; We know filename matches.
		mov	cx, dx		; String size.
		jmp	compareLoop	; Check for filename match.

noMatches:

	; No matches in the list.  Unlock list and exit.

		call	MemUnlock
		stc			; No match found: error.
		jmp	done

found:
	; This patch file matches our geode.

		mov	ss:[patchFile], si 	; Patch file handle.
		call	MemUnlock
patchFileOpen::

	; Attempt to load in the patch data.

		mov	bx, ss:[patchFile]
		mov	es, ss:[coreBlock]
		segmov	ds, ss
		lea	dx, ss:[fileHeader]	; ds:dx = PatchFileHeader
		call	GeodeLoadPatchData
			; If no error, bx = handle of locked patch data.
		jc	errorCloseFile

	; The patch data was read in.  

	; Copy various bits of data into the execHeader field stored
	; in the calling procedure's local variables.

		mov	di, ss:[udataPtr]
		tst	di
		jz	doneNoError
		
		mov	ax, ss
		mov	ds, ax
		mov	es, ax
		lea	si, ss:[fileHeader].PFH_udataSize

CheckHack <offset PFH_classPtr eq offset PFH_udataSize + 2	>
CheckHack <offset PFH_appObj eq offset PFH_classPtr + 4		>

CheckHack <offset EFH_classPtr eq offset EFH_udataSize + 2	>
CheckHack <offset EFH_appObj eq offset EFH_classPtr + 4		>

		mov	cx, (size PFH_udataSize + \
				size PFH_classPtr + \
				size PFH_appObj) / 2
		rep	movsw

doneNoError:
		mov	dx, bx		; Patch data.
		clc
done:
	; Return the core block's address to the caller, in case it moved.
		
		mov	ds, ss:[coreBlock]	
		.leave
		ret
errorCloseFile:
		mov	bx, ss:[patchFile]
		call	FileCloseFar
		stc
		jmp	done

GeodeOpenPatchFileFromList	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeLoadPatchData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the proposed patch file's header, and check the
		permanent name, token, and protocol numbers.  If they
		match, return a locked block with the patch data.

CALLED BY:	GeodeOpenPatchFileFromList

PASS:		ds:dx - PatchFileHeader read in from patch file
		es - core block of geode being patched
		bx - patch file handle

RETURN:		if error
			carry set
		else
			carry clear
			bx = handle of LOCKED patch data

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/18/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeLoadPatchData	proc near
		uses	cx, si
		.enter

EC <		call	ECCheckCoreBlockES				>
EC <		call 	ECCheckFileHandle	; bx			>
		
		call	SetOwnerToGeodeES

		mov	si, dx
		cmp	{word} ds:[si].PFH_signature, PFH_SIG_1_2
		jne	error

		cmp	{word} ds:[si].PFH_signature[2], PFH_SIG_3_4
		jne	error

		
		lea	si, ds:[si].PFH_oldRelease
		mov	di, offset GH_geodeRelease
		mov	cx, (size ReleaseNumber + size ProtocolNumber )/2

		CheckHack <offset GH_geodeRelease + size GH_geodeRelease \
			   eq offset GH_geodeProtocol>

		CheckHack <offset PFH_oldRelease + size PFH_oldRelease \
			   eq offset PFH_oldProtocol>

		repe	cmpsw
		jne	error

		mov	si, dx		; ds:si - PatchFileHeader

		mov	di, bx		; patch file handle
		mov	ax, ds:[si].PFH_resourceCount

EC <		tst	ax						>
EC <		ERROR_Z PATCH_FILE_ERROR				>
		
	; Allocate space for the patch resource data.

		mov	dx, ax				; Resource count.
		mov	cl, size PatchedResourceEntry
		mul	cl				; Multiply by size.
		add	ax, size PatchDataHeader	; Add header.
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAllocFar
		jc	done				; Error on alloc.


	; Fill in the PatchDataHeader.

		mov	cx, ds:[si].PFH_newResourceCount

		mov	ds, ax
		mov	ds:[PDH_fileHandle], di
		mov	ds:[PDH_count], dx

		mov	ds:[PDH_newResCount], cx
		mov	ax, es:[GH_resCount]
		mov	ds:[PDH_origResCount], ax

	; Set this block as owned by the geode.
	
		call	SetOwnerToGeodeES

	; Read the list of PatchedResourceEntries.

		push	bx		; Patch data block handle.
		mov	bx, di		; File handle.
		mov_tr	ax, dx		; Resource count.
		mov	cl, size PatchedResourceEntry
		mul	cl
		mov_tr	cx, ax
		mov	dx, offset PDH_resources
		mov	al, FILE_NO_ERRORS
		call	FileReadFar
		pop	bx		; Patch data block handle.		

done:
		.leave
		ret
		
error:
		stc
		jmp	done
GeodeLoadPatchData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetOwnerToGeodeES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the owner of the handle (bx) to the geode whose
		core block is at ES
CALLED BY:	GeodeLoadPatchData

PASS:		es - core block
		bx - handle to modify

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/29/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetOwnerToGeodeES	proc near
		uses	ds
		.enter

EC <		call	ECCheckCoreBlockES				>

		LoadVarSeg	ds, ax
		mov	ax, es:[GH_geodeHandle]
		mov	ds:[bx].HM_owner, ax

		.leave
		ret
SetOwnerToGeodeES	endp

endif ; USE_PATCHES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeSetGeneralPatchPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current path to the directory for general 
		(non-language) patch files.  If that directory does not
		exist, it is created.

CALLED BY:	InitGeneralPatches
PASS:		nothing
RETURN:		carry	= set on error
DESTROYED:	nothing
SIDE EFFECTS:	Current path is changed, old path is pushed.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	10/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if USE_BUG_PATCHES
LocalDefNLString kinitPatchDir <"PATCH",0>
endif

GeodeSetGeneralPatchPath	proc	far
if USE_BUG_PATCHES
		uses	ax,bx,dx
		.enter

		call	FilePushDir

	; Set path to patch file location (PRIVDATA/PATCH).

		push	ds			; kdata
		mov	bx, SP_PRIVATE_DATA
		segmov	ds, cs
		mov	dx, offset kinitPatchDir
		call	FileSetCurrentPath
		jnc	done			; Success.

	; Move to PRIVDATA.
	
		mov	ax, SP_PRIVATE_DATA
		call	FileSetStandardPath
		jc	done

	; Create a patch directory.

		call	FileCreateDir
		jc	done
		call	FileSetCurrentPath		

done:
		pop	ds			; kdata
		.leave
endif
		ret
GeodeSetGeneralPatchPath	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeSetLanguagePatchPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current path to the directory for language 
		patch files.

CALLED BY:	InitLanguagePatches
PASS:		nothing
RETURN:		carry	= set on error
DESTROYED:	nothing
SIDE EFFECTS:	Current path is changed, old path is pushed.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	10/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeSetLanguagePatchPath	proc	far
if MULTI_LANGUAGE
		uses	ax,bx,dx,ds
		.enter

		call	FilePushDir

	; Create a buffer with the path to create.

		call	BuildLanguagePatchPath
		jc	done		; Error.
			; ds:dx = path buffer

	; Change to language sub-directory.

		push	bx		; Buffer handle.
		mov	bx, SP_PRIVATE_DATA
		call	FileSetCurrentPath
		pop	bx		; Buffer handle.

	; Free the buffer.

		pushf
		call	MemFree		; Free buffer.
		popf

done:
		.leave
endif
		ret
GeodeSetLanguagePatchPath	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeSetLanguageStandardPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change to the mirrored standard path directory, inside
		PRIVDATA/LANGUAGE/<Current Language>.

CALLED BY:	GLOBAL
PASS:		ax = directory to change to, standardPath enum
RETURN:		if error,
			carry set
		else
			carry clear
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	5/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeSetLanguageStandardPath	proc	far
if MULTI_LANGUAGE
		uses	ax,bx,dx,si,ds
		.enter

	; First, change to PRIVDATA/LANGUAGE/<Current Language>

		call 	GeodeSetLanguagePatchPath
		jc	done				; Error.

	; Get the standard path string.

		mov	si, ax		; Standard Path enum.
		mov	bx, handle StandardPathStrings
		call	MemLock
		mov	ds, ax
		call	FileGetStdPathNameFar		
		call	MemUnlock
			; ds:si = standard path name

	; Change to the standard path subdirectory.

		clr	bx
		mov	dx, si
		call	FileSetCurrentPath

done:
		.leave
endif
		ret
GeodeSetLanguageStandardPath	endp


if USE_PATCHES

if MULTI_LANGUAGE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateLanguagePatchDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the PRIVDATA/LANGUAGE/CurrentLanguageName
		directory if it doesn't exist.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry = set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	1/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateLanguagePatchDir	proc	far
		uses	ax,bx,dx
		.enter

	; Change to PRIVDATA.

		call	FilePushDir
		mov	ax, SP_PRIVATE_DATA
		call	FileSetStandardPath
		jc	done		; Error on setting path.

	; Create a buffer with the path to create.

		call	BuildLanguagePatchPath
		jc	done		; Error.
			; ds:dx = path buffer

	; Create the path.

		call	FileCreateDir

	; Free the buffer.

		pushf
		call	MemFree
		popf
done:

	; Restore the original path.

		call	FilePopDir

		.leave
		ret
CreateLanguagePatchDir	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildLanguagePatchPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a buffer containing the path of the current
		language's directory in the PRIVDATA standard path.

CALLED BY:	CreateLanguagePatchDir, GeodeSetLanguagePatchPath

PASS:		nothing

RETURN: 	if error
			carry set
		else
			carry clear
			bx	= handle of buffer
			ds:dx	= buffer containing path

DESTROYED:	bx, dx, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	1/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString kinitLanguageDir <"LANGUAGE", C_BACKSLASH, 0>
LocalDefNLString kinitLanguageCategory <"system", 0>
LocalDefNLString kinitLanguageKey <"systemLanguage",0>

BuildLanguagePatchPath	proc	near
		uses	ax,cx,di,si,bp,es
		.enter

	; Allocate buffer for subdirectory.

		mov	ax, FILE_LONGNAME_BUFFER_SIZE
		add	ax, size kinitLanguageDir
		inc	ax
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAllocFar
		jc	done		; Error: not enough memory.
		mov	es, ax
		clr	di		; es:di = buffer

	; Copy language directory string into buffer.

		segmov	ds, cs, ax
		mov	si, offset kinitLanguageDir
		LocalCopyString
			; di points to after the null in the buffer
		dec	di

	; Append language subdirectory to buffer.

		mov	ax, bx		; Buffer handle
		mov	si, offset kinitLanguageCategory
		mov	cx, cs
		mov	dx, offset kinitLanguageKey
		mov	bp, mask IFRF_SIZE
		call	InitFileReadString		
		mov	bx, ax		; Buffer handle
		jc	doneWithFree	; Error on .ini read.

	; Set ds:dx to path buffer.

		segmov	ds, es, dx
		clr	dx
		clc			; No errors.

done:
		.leave
		ret

doneWithFree:
		call	MemFree
		jmp	done

BuildLanguagePatchPath	endp

endif ; MULTI_LANGUAGE



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchCheckPermanentName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the proposed patch file and make sure the
		permanent name and GeodeAttrs match those of the geode
		we're loading

CALLED BY:	GeodeOpenPatchFileFromList,
		InstallPatchRunningGeodeCB

PASS:		ds:si	- filename to check		
		es	- geode core block to check
		di	- offset of file header buffer on stack

		current path - location of patch files

RETURN:		if error
			carry set
		else
			carry clear
			si = file handle
			ss:[di] contains file header

DESTROYED:	es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/ 1/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchCheckPermanentName	proc near
		uses	ax,bx,cx,di
		
		.enter	inherit GeodeOpenPatchFileFromList

EC <		call	ECCheckBounds		; ds:si			>
EC <		call	ECCheckCoreBlockES	; es			>

		push	es			; Core block.
		segmov	es, ss, ax	; es:di = file header buffer
		call	GeodePatchFileGetHeader
		pop	ds			; Core block.
		jc	done
		push	bx			; File handle.

	; Check if the geode name matches.

		lea	di, ss:[di].PFH_geodeName
		mov	si, offset GH_geodeName
		mov	cx, (GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE)/2
		repe	cmpsw
		pop	si			; File handle.
		je	done			; Name matches.

	; Name did not match.  Indicate error and close file.

		call	FileCloseFar
		stc

done:
		.leave
		ret
GeodePatchCheckPermanentName	endp

if USE_BUG_PATCHES
GeodePatchCheckPermanentNameFar	proc	far
		call	GeodePatchCheckPermanentName
		ret
GeodePatchCheckPermanentNameFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeConstructPatchFilename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the geode's name base from the core block to
		es:di, converting it to all caps along the way.

CALLED BY:	GeodeOpenGeneralPatchFile, 
		GeodeOpenLanguagePatchFile,
		InstallPatchRunningGeodeCB

PASS:		ds 	= core block
		ss:di	= buffer for name wildcard

RETURN:		dx	= size of name base
		ss:di	= end of converted name base

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeConstructPatchFilename	proc	far
		uses	ax,cx,si,es
		.enter

EC <		call	ECCheckCoreBlockDS				>

	; Point to geode's permanent name and determine size.

		segmov	es, ss, si
		mov	si, offset GH_geodeName
		mov	cx, size GH_geodeName
		clr	ax, dx
copyName:
		lodsb
		cmp	al, ' '
		je	done

	; The permanent name is lower-case, single-byte (ASCII),
	; so convert it to uppercase along the way.

		call	LocalUpcaseChar
		stosb
		inc	dx
		loop	copyName

done:
		.leave
		ret
GeodeConstructPatchFilename	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CountCharactersBeforePeriod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the number of characters preceding a period in
		the passed patch filename.

CALLED BY:	GeodeInstallPatch, GeodeKillPatchIfObsolete
PASS:		ds:si	= patch filename
RETURN:		dx	= characters preceding a period
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	11/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CountCharactersBeforePeriod	proc	near
		uses	si
		.enter

EC <		call	ECCheckBounds		; ds:si			>

		clr	dx	; Count for characters before period.
findPeriodLoop:
		cmp	{byte} ds:[si], C_PERIOD
		je	done

		inc	dx			; Character count.
EC <		cmp	dx, size DosDotFileName				>
EC <		ERROR_A PATCH_FILE_NAME_ERROR				>

		inc	si			; Next char to check.
		jmp	findPeriodLoop

done:
		.leave
		ret
CountCharactersBeforePeriod	endp

CountCharactersBeforePeriodFar	proc	far
		call	CountCharactersBeforePeriod
		ret
CountCharactersBeforePeriodFar	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchFileGetHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the specified patch file and read in the header.

CALLED BY:	GeodePatchCheckPermanentName, GeodeKillOlderPatchIfMatch

PASS:		ds:si	= filename
		es:di	= buffer for PatchFileHeader
		current directory = directory of patch file

RETURN:		If error,
			carry set
		else
			carry clear
			bx	= file handle

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	11/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchFileGetHeader	proc	near
		uses	ax,cx,dx
		.enter

EC <		push	ds, si						>
EC <		call	ECCheckBounds		; ds:si			>
EC <		segmov	ds, es						>
EC <		mov	si, di						>
EC <		call	ECCheckBounds		; es:di			>
EC <		pop	ds, si						>

	; Open the patch file.

		mov	dx, si
		mov	al, FILE_DENY_W or FILE_ACCESS_R
		call	FileOpen
		jc	done			; Error on open.

	; Read in the file header.

		segxchg	ds, es, dx
		mov	dx, di			; Header buffer.
		mov_tr	bx, ax			; Patch file handle.
		mov	cx, size PatchFileHeader
		call	FileReadFar
		segxchg	ds, es, dx
		jc	closeFileDone		; Error on read.

done:
		.leave
		ret
closeFileDone:

	; Error on read.  Close file.

		call	FileCloseFar
		stc		
		jmp	done

GeodePatchFileGetHeader	endp

if USE_BUG_PATCHES
GeodePatchFileGetHeaderFar	proc	far
		call	GeodePatchFileGetHeader
		ret
GeodePatchFileGetHeaderFar	endp
endif

endif ; USE_PATCHES

GLoad	ends
