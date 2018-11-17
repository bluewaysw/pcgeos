COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PCGEOS
MODULE:		ResEdit
FILE:		documentPatch.asm

AUTHOR:		Paul Canavese, Jan 25, 1995

ROUTINES:
	Name			Description
	----			-----------
	GeneratePatchFile	Create a patch file in the current directory to 
				generate the second file from the first file. 
	PatchCreatePatchFile	Create the patch file in the current directory 
				using the permanent name of the passed geode. 
				The filename has the same permanent name as the 
				geode, and the extension is a "P", followed by 
				the last two digits of the revision number. 
	PatchGeodeReadHeaders	Position the geode file and read in its 
				ExecutableFileHeader and GeodeHeader. 
	PatchFileCreateHeader	Fill in the fields of the PatchFileHeader. 
	PatchCompareCoreBlocks	Generate and compare the core blocks for the 
				old and new geode files. 
	HackExportTables	The export tables contain word-sized resource 
				IDs that are relocated at run-time to segments. 
				Since the resource IDs will most likely differ 
				only in their low bytes, we'd be left with the 
				problem that patching an already-relocated 
				export table will munge the data (since the 
				high byte contains the high byte of the segment 
				address). To take care of this, make sure that 
				any values that differ in their low bytes also 
				differ in their high bytes (by storing "CC" in 
				the high byte of the "old" field. 
	PatchBuildCoreBlock	Build an image of the core block for this 
				geode. For patching, we're only interested in 
				GeodeHeader fields up to (and including) 
				GH_resHandleOff, and the exported entry point 
				table. 
	PatchCompareResources	Compares the resources and relocation tables of 
				the geode, creating patch elements if 
				necessary. 
	LoadResourceFromGeodeFile	Allocate a block and load a resource 
				(and its relocation table) into it. 
	GetResourceRelocationTableSize	Returns the size of the relocation 
				table for the given resource. 
	GetResourceAllocationFlags	Get the allocation flags for a given 
				resource. 
	CalcOffsetToRelocTableSizeTable	Calculate the offset of the Relocation 
				Table Size Table into the core block. 
	SnatchWordFromGeodeFile	Return the word at the offset in the specified 
				geode file. 
	CompareBytes		Create the most efficient list of patch 
				elements to describe the differences between 
				two strings of bytes. 
	OutOfBytes		Either the old or new resource is out of bytes. 
				Create a delete or insert patch element. 
	FindLargestMatchSimple	Find PATCH_GRANULARITY or more matching bytes 
				in the new and old resource. 
	FindLargestAlignedMatch	Find the largest matching string of bytes at 
				the same offsets between oldStart and oldEnd 
				and newStart and newEnd. 
	CalculateReplaceSize	Return the smaller of the sizes of the two 
				strings. 
	CreatePatchElement	Create a PatchElement for this resource. 
	CreatePatchedResourceEntry	Create a PatchedResourceEntry for this 
				resource. 
	WritePatchResourceList	Fill in the PRE_resourcePos fields, and write 
				out the PatchedResourceEntry structures. 
	WritePatchLists		Write the PatchElement structures for each 
				resource. 
	WritePatchElement	Write out the passed patch element and all 
				following it in the list. 
	ComputeMaxSize		Determine the maximum size of a resource or 
				relocation table of the passed size when the 
				passed patch elements are applied to it. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	1/25/95   	Initial revision


DESCRIPTION:
	Code for creating patch files.

	$Id: documentPatch.asm,v 1.1 97/04/04 17:14:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include Internal/patch.def

include object.def
include graphics.def
include Internal/fileStr.def
include Internal/geodeStr.def

include Objects/winC.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def
UseLib Objects/vTextC.def

PATCH_GRANULARITY	equ	8
MAX_PATCH_SIZE		equ	4095

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

GEODE_FILE_TABLE_SIZE	equ	GH_geoHandle

; Structures used when creating a patch file.

PatchedResourceCreateEntry struct
    PRCE_entry			PatchedResourceEntry
    PRCE_next			nptr
    PRCE_relocPatches		nptr
    PRCE_resourcePatches	nptr
PatchedResourceCreateEntry ends

PatchCreateElement	struct
    PCE_next			nptr
    PCE_entry			PatchElement
    PCE_data			label byte
PatchCreateElement	ends

GeodePatchInfo		struct
    GPI_coreBlock		word
    GPI_resourceHandle		word
    GPI_resourceSize		word
    GPI_relocationTableSize	word
    GPI_execHeader		ExecutableFileHeader
    GPI_geodeHeader		GeodeHeader
GeodePatchInfo		ends

GeneratePatchFileFrame	struct
    GPPF_resourceList		word
    GPPF_currentResourceEntry	word		; Handle.
    GPPF_fileType		GeosFileType
    GPPF_newGeode		GeodePatchInfo
    GPPF_oldGeode		GeodePatchInfo
    GPPF_patchFileHandle	word
    GPPF_patchFileHeader	PatchFileHeader
    GPPF_relocationPatching	word
GeneratePatchFileFrame	ends


DocumentBuildCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeneratePatchFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a patch file in the current directory to generate the
		second file from the first file.

CALLED BY:	CreatePatchFile
PASS:		ax = original geode file handle
		bx = translated geode file handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	2/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeneratePatchFile	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
frame		local	GeneratePatchFileFrame
		.enter

EC <		push	bx						>
EC <		call	ECCheckFileHandle				>
EC <		mov	bx, ax						>
EC <		call	ECCheckFileHandle				>
EC <		pop	bx						>

	; Initialize some local variables.

		clr	cx
		clr	ss:[frame].GPPF_relocationPatching
		mov	ss:[frame].GPPF_currentResourceEntry, cx
		mov	ss:[frame].GPPF_resourceList, cx

	; Read in new file's headers.

		lea	cx, ss:[frame].GPPF_newGeode.GPI_execHeader
		lea	dx, ss:[frame].GPPF_newGeode.GPI_geodeHeader
		call	PatchGeodeReadHeaders

	; Read in old file's headers.

		xchg	ax, bx
		lea	cx, ss:[frame].GPPF_oldGeode.GPI_execHeader
		lea	dx, ss:[frame].GPPF_oldGeode.GPI_geodeHeader
		call	PatchGeodeReadHeaders
		xchg	ax, bx

	; Create patch file header.

		call	PatchFileCreateHeader

	; Generate and compare the core blocks.
	
		call	PatchCompareCoreBlocks

	; Compare all the resources.

		call	PatchCompareResources

	; Check if there were any differences.

		tst	ss:[frame].GPPF_resourceList
		jz	done

	; Create the patch file.

		mov	bx, ss:[frame].GPPF_oldGeode.GPI_coreBlock
		call	MemDerefDS
		mov	bx, ss:[frame].GPPF_newGeode.GPI_coreBlock
		call	MemDerefES
		call	PatchCreatePatchFile
		mov	ss:[frame].GPPF_patchFileHandle, bx

writePatchFileHeader::					; Keep for Swat.

	; Write out the patch file header.

		clr	al
		mov	bx, ss:[frame].GPPF_patchFileHandle
		segmov	ds, ss, dx
		lea	dx, ss:[frame].GPPF_patchFileHeader
		mov	cx, size PatchFileHeader
		call	FileWrite

		call	WritePatchResourceList
		call	WritePatchLists

		clr	al
		call	FileClose

	; Free core blocks.

		mov	bx, ss:[frame].GPPF_oldGeode.GPI_coreBlock
		call	MemFree
		mov	bx, ss:[frame].GPPF_newGeode.GPI_coreBlock
		call	MemFree

done:
		.leave
		ret
GeneratePatchFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatchCreatePatchFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the patch file in the current directory using
		the permanent name of the passed geode.  The filename
		has the same permanent name as the geode, and the
		extension is a "P", followed by the last two digits of
		the revision number.

CALLED BY:	GeneratePatchFile

PASS:		ds = segment of old core block
		es = segment of new core block

RETURN:		bx = file handle

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PatchCreatePatchFile	proc	near
		uses	ax,cx,dx,si,di,ds,es
fileName		local	(GEODE_NAME_SIZE+GEODE_NAME_EXT_SIZE+1) dup (char)
		.enter

		segmov	es, ss, si
		lea	di, ss:[fileName]
		mov	si, offset GH_geodeName
		mov	cx, GEODE_NAME_SIZE

copyNameLoop:
		cmp	{byte} ds:[si], C_SPACE
		je	doExtension
		movsb
		loop	copyNameLoop

doExtension:

	; Copy the ".P"

		mov	{byte} es:[di], C_PERIOD
		inc	di
		mov	{byte} es:[di], 'P'

	; Copy the ending null.

		add	di, 3
		mov	{byte} es:[di], 0
		dec	di
		
	; Determine the second digit.

		mov	ax, ds:[GH_geodeRelease].RN_change		
		mov	bl, 10
		div	bl
		clr	dx
		mov	dl, ah
SBCS <		add	dx, C_ZERO					>
DBCS <		add	dx, C_DIGIT_ZERO				>
		mov	es:[di], dl

	; Determine the first digit.

		dec	di
		clr	ah
		div	bl
		clr	dx
		mov	dl, ah
SBCS <		add	dx, C_ZERO					>
DBCS <		add	dx, C_DIGIT_ZERO				>
		mov	es:[di], dl

	; Create the file.

		mov	ah, mask FCF_NATIVE
		mov	al, FA_WRITE_ONLY or (FE_NONE shl 4)
		clr	cx
		segmov	ds, ss, dx
		lea	dx, ss:[fileName]
		call	FileCreate
		mov	bx, ax

		.leave
		ret
PatchCreatePatchFile	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatchGeodeReadHeaders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the geode file and read in its
		ExecutableFileHeader and GeodeHeader.

CALLED BY:	GeneratePatchFile

PASS:		bx	= Geode's file handle.
		cx	= Offset of ExecutableFileHeader on the stack.
		dx	= Offset of GeodeHeader on the stack.

RETURN:		carry set on error

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	2/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PatchGeodeReadHeaders	proc	near
		uses	ax,cx,dx,si,di,ds
		.enter	inherit GeneratePatchFile

		push	dx,cx

EC <		call	ECCheckFileHandle				>

	; Check if this is a geode.

		push	es
		segmov	es, ss
		lea	di, ss:[frame].GPPF_fileType
		mov	cx, size GeosFileType
		mov	ax, FEA_FILE_TYPE
		call	FileGetHandleExtAttributes
		pop	es
		mov	ax, GLE_NOT_GEOS_EXECUTABLE_FILE
		jc	errorPopCXDX

	; Position the geode file.

		mov	al, FILE_POS_START
		clr	cx
		mov	dx, cx		
		call	FilePos

	; Read in the ExecutableFileHeader.

		clr	al
		mov	cx, size ExecutableFileHeader
		segmov	ds, ss, dx
		pop	dx
		call	FileRead
		mov	ax, GLE_FILE_READ_ERROR
		jc	errorPopDX
			; ax, cx killed

	; Read in GeodeHeader

		clr	ax
		mov	cx, GEODE_FILE_TABLE_SIZE
		pop	dx
		call	FileRead

	; Put file handle into GeodeHeader
	
		mov	si, dx
		mov	ds:[si].GH_geoHandle, bx
done:
		.leave
		ret

errorPopCXDX:
		pop	cx
errorPopDX:
		pop	dx
		stc
		jmp	done

PatchGeodeReadHeaders	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatchFileCreateHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the fields of the PatchFileHeader.

CALLED BY:	GeneratePatchFile
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	2/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PatchFileCreateHeader	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter	inherit	GeneratePatchFile

	; Compare the file names.

		mov	ax, ss
		mov	es, ax
		mov	ds, ax
		lea	di, ss:[frame].GPPF_oldGeode.GPI_geodeHeader.GH_geodeName
		lea	si, ss:[frame].GPPF_newGeode.GPI_geodeHeader.GH_geodeName
		mov	cx, GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE
		repe	cmpsb
		jne	geodeNamesDontMatch

	; Copy file name and GeodeToken to patch file header.
		
		lea	si, ss:[frame].GPPF_oldGeode.GPI_geodeHeader.GH_geodeName
		lea	di, ss:[frame].GPPF_patchFileHeader.PFH_geodeName
		mov	cx, GEODE_NAME_SIZE + GEODE_NAME_EXT_SIZE + size GeodeToken
		rep	movsb

	; Compare geode attributes.

		mov	ax, ss:[frame].GPPF_oldGeode.GPI_geodeHeader.GH_geodeAttr
		cmp	ax, ss:[frame].GPPF_newGeode.GPI_geodeHeader.GH_geodeAttr
		jne	geodeAttrsDontMatch

	; Copy old release number and protocol number.

		lea	si, ss:[frame].GPPF_oldGeode.GPI_geodeHeader.GH_geodeRelease
		lea	di, ss:[frame].GPPF_patchFileHeader.PFH_oldRelease
		mov	cx, size ReleaseNumber + size ProtocolNumber
		rep	movsb

	; Copy new release number and protocol number.

		lea	si, ss:[frame].GPPF_newGeode.GPI_geodeHeader.GH_geodeRelease
		lea	di, ss:[frame].GPPF_patchFileHeader.PFH_newRelease
		mov	cx, size ReleaseNumber + size ProtocolNumber
		rep	movsb

	; Copy new geode attributes.

;		lea	si, ss:[frame].GPPF_oldGeode.GPI_geodeHeader.GH_geodeAttr
;		lea	di, ss:[frame].GPPF_patchFileHeader.PFH_geodeAttr
;		mov	cx, size GeodeAttrs
;		rep	movsb
		clr	ss:[frame].GPPF_patchFileHeader.PFH_geodeAttr

	; Copy udata size, class pointer, and app obj.

		lea	si, ss:[frame].GPPF_oldGeode.GPI_execHeader.EFH_udataSize
		lea	di, ss:[frame].GPPF_patchFileHeader.PFH_udataSize
		mov	cx, size word + size dword + size optr
		rep	movsb

	; Start with no resources.

		clr	ss:[frame].GPPF_patchFileHeader.PFH_resourceCount
		clr	ss:[frame].GPPF_patchFileHeader.PFH_newResourceCount

	; Clear out the patch data flags.

		clr	ss:[frame].GPPF_patchFileHeader.PFH_flags

	; Fill in signature.

		mov	{word} ss:[frame].GPPF_patchFileHeader.PFH_signature, \
				'P' or ('A' shl 8)
		mov	{word} ss:[frame].GPPF_patchFileHeader.(PFH_signature+2), \
				'T' or ('C' shl 8)

geodeNamesDontMatch:
geodeAttrsDontMatch:

		.leave
		ret
PatchFileCreateHeader	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatchCompareCoreBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate and compare the core blocks for the old and
		new geode files.

CALLED BY:	GeneratePatchFile
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	2/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PatchCompareCoreBlocks	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter	inherit	GeneratePatchFile

	; Build the core blocks.

		mov	bx, ss:[frame].GPPF_oldGeode.GPI_geodeHeader.GH_geoHandle
		lea	si, ss:[frame].GPPF_oldGeode.GPI_geodeHeader
		call	PatchBuildCoreBlock
		mov	ss:[frame].GPPF_oldGeode.GPI_coreBlock, bx
		call	MemDerefES

		mov	bx, ss:[frame].GPPF_newGeode.GPI_geodeHeader.GH_geoHandle
		lea	si, ss:[frame].GPPF_newGeode.GPI_geodeHeader
		call	PatchBuildCoreBlock
		mov	ss:[frame].GPPF_newGeode.GPI_coreBlock, bx
		call	MemDerefDS

	; If core blocks are different size, we need to patch core
	; block.

		mov	ax, ds:[GH_resHandleOff]
		cmp	ax, es:[GH_resHandleOff]
		jne	patchCoreBlock

	; If GeodeHeaders differ between GH_driverTabOff and
	; GH_resPosOff, patch core block.

		mov	si, offset GH_driverTabOff
		mov	di, si
		mov	cx, offset GH_resPosOff
		sub	cx, si
		repe	cmpsw
		jne	patchCoreBlock

	; If the export tables differ, patch core block.
		
		mov	si, ds:[GH_exportLibTabOff]
		mov	di, es:[GH_exportLibTabOff]
		mov	cx, di
		sub	cx, es:[GH_resHandleOff]
		repe	cmpsw
		jne	patchCoreBlock

exit:
		.leave
		ret				; <---- EXIT HERE.

patchCoreBlock:

	; Patch the core block: increment the patched resources.

		inc	ss:[frame].GPPF_patchFileHeader.PFH_resourceCount

	; Create a PatchedResourceCreateEntry for the core block.

		call	CreatePatchedResourceEntry
			; ds = segment of PRE.

	; Record size difference.

		mov	cx, ds:[GH_resHandleOff]
		sub	cx, es:[GH_resHandleOff]
		mov	ds:[PRE_resourceSizeDiff], cx

	; Compare the bytes of some GeodeHeader entries.

		mov	ax, offset GH_driverTabOff
		mov	cx, ax
		mov	bx, offset GH_resPosOff
		mov	dx, ax
		call	CompareBytes

	; Suggestion: check that export tables are at the same offset here.

	; Hack the export tables.

		call	HackExportTables

	; Compare the bytes in the export tables.

		mov	ax, ds:[GH_exportLibTabOff]
		mov	cx, ax
		mov	bx, ds:[GH_resHandleOff]
		mov	dx, es:[GH_resHandleOff]
		call	CompareBytes

	; If there are new resources, insert some space in the
	; resource handle code.

		mov	ax, es:[GH_resCount]
		sub	ax, ds:[GH_resCount]
		jc	tooFewResources
		jz	exit

	; Insert space in the resource handle table for the new
	; resource(s).

		clr	cx
		mov	dx, ax
		shl	dx
		mov	ax, ds:[GH_resCount]
		shl	ax
		add	ax, ds:[GH_resHandleOff]
		mov	bx, PT_INSERT_ZERO
		call	CreatePatchElement
		jmp	exit

tooFewResources:

	; New version of the geode has fewer resources than the old
	; version.

		jmp	exit

PatchCompareCoreBlocks	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HackExportTables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The export tables contain word-sized resource IDs that
		are relocated at run-time to segments.  Since the
		resource IDs will most likely differ only in their low
		bytes, we'd be left with the problem that patching an
		already-relocated export table will munge the data
		(since the high byte contains the high byte of the
		segment address).  To take care of this, make sure
		that any values that differ in their low bytes also
		differ in their high bytes (by storing "CC" in the
		high byte of the "old" field.

CALLED BY:	PatchCompareCoreBlocks
PASS:		ds = segment of old resource
		es = segment of new resource
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HackExportTables	proc	near
		uses	ax,cx,dx,si,di
		.enter

	; Determine the start of the table.

		mov	si, ds:[GH_exportLibTabOff]
		add	si, 2
		mov	di, si

continueLoop:

	; Does entry need to be patched?

		mov	cx, 0FFFFh
		cmpsb
		je	advancePointersThree
		cmpsb
		jne	advancePointersTwo

	; Not the low byte of the entry.

		dec	si
		dec	di
		mov	ax, es:[di]
		not	ax
		mov	ds:[di], ax

advancePointersThree:
		inc	si
		inc	di

advancePointersTwo:
		add	si, 2
		add	di, 2
			
	; Are we done with the table?

		cmp	si, ds:[GH_resHandleOff]
		jb	continueLoop

		.leave
		ret
HackExportTables	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatchBuildCoreBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build an image of the core block for this geode.  For
		patching, we're only interested in GeodeHeader fields
		up to (and including) GH_resHandleOff, and the
		exported entry point table.

CALLED BY:	PatchCompareCoreBlocks

PASS:		bx	= file handle 
		si	= offset of GeodeHeader on the stack

RETURN:		bx	= handle of locked core block

DESTROYED:	ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	2/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PatchBuildCoreBlock	proc	near
		uses	ax,cx,dx,si,di
fileHandle		local	word	push bx
exportLibTabOff		local	word

		.enter

	; Determine core block size.

	; Use GeodeHeader or ProcessHeader.

		mov	ax, size GeodeHeader	; Assume not a process.
		test	ss:[si].GH_geodeAttr, mask GA_PROCESS
		jz	notProcess
		mov	ax, size ProcessHeader

notProcess:

	; Add in 2 * libraries used.

		mov	dx, ss:[si].GH_libCount
		sal	dx
		add	ax, dx
		mov	ss:[exportLibTabOff], ax

	; Add in 4 * exported entries.

		mov	dx, ss:[si].GH_exportEntryCount
		sal	dx
		sal	dx
		add	ax, dx		; Size to allocate.
		mov	dx, ax

	; Allocate the core block.

		mov	cl, mask HF_SWAPABLE
		mov	ch, mask HAF_ZERO_INIT or mask HAF_LOCK \
				or mask HAF_NO_ERR
		call	MemAlloc
		jc	error

	; Copy geode header to core block.

		mov	es, ax		; Core block segment.
		clr	di
		segmov	ds, ss, cx
		mov	cx, size GeodeHeader
		rep	movsb

	; Put offset values into core block.

		mov	cx, ss:[exportLibTabOff]
		mov	es:[GH_exportLibTabOff], cx
		mov	es:[GH_resHandleOff], dx

	; Position the file at the export table.

		push	bx		; GeodeHeader block handle.
		mov	ax, es:[GH_libCount]
		mov	bx, size ImportedLibraryEntry
		mul	bx
		jc	errorPopBX		; Overflow.
		mov	dx, ax

		mov	al, FILE_POS_START
		mov	bx, ss:[fileHandle]
		clr	cx
		add	dx, size ExecutableFileHeader
		add	dx, offset GH_endOfVariablesFromFile
		call	FilePos

	; Read in the export table.

		clr	ax
		mov	cx, es:[GH_exportEntryCount]
		sal	cx
		sal	cx
		segmov	ds, es, dx
		mov	dx, es:[GH_exportLibTabOff]
		call	FileRead

errorPopBX:
		pop	bx		; GeodeHeader block handle.
error:
		.leave
		ret
PatchBuildCoreBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PatchCompareResources
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares the resources and relocation tables of the
		geode, creating patch elements if necessary.

CALLED BY:	GeneratePatchFile

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	PatchedResourceEntry created if necessary.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	3/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PatchCompareResources	proc	near
		uses	ax,bx,cx,dx,si,di
		.enter inherit GeneratePatchFile

		mov	cx, 1		; Start at resource 1.
		mov	dx, ss:[frame].GPPF_newGeode.GPI_geodeHeader.GH_resCount

	; Load new resource.

loadNewResource:
		push	cx, dx
		lea	bx, ss:[frame].GPPF_newGeode.GPI_geodeHeader
		call	LoadResourceFromGeodeFile		
		mov	ss:[frame].GPPF_newGeode.GPI_resourceHandle, bx 
		mov	ss:[frame].GPPF_newGeode.GPI_resourceSize, cx
		mov	ss:[frame].GPPF_newGeode.GPI_relocationTableSize, dx
		pop	cx, dx

	; Check if this resource exists in the new geode, but not the
	; old one.

		cmp	cx, ss:[frame].GPPF_oldGeode.GPI_geodeHeader.GH_resCount
		LONG jae resourceOnlyInNewGeode

	; Load old resource.

		push	cx, dx
		lea	bx, ss:[frame].GPPF_oldGeode.GPI_geodeHeader
		call	LoadResourceFromGeodeFile		
		mov	ss:[frame].GPPF_oldGeode.GPI_resourceHandle, bx 
		mov	ss:[frame].GPPF_oldGeode.GPI_resourceSize, cx
		mov	ss:[frame].GPPF_oldGeode.GPI_relocationTableSize, dx
		pop	cx, dx

	; Check if resource sizes match.

		push	cx
		mov	si, ss:[frame].GPPF_oldGeode.GPI_resourceSize
		cmp	si, ss:[frame].GPPF_newGeode.GPI_resourceSize
		jne	doPop			; They don't match.
		mov	cx, si

	; Check if relocation table sizes match.

		mov	si, ss:[frame].GPPF_oldGeode.GPI_relocationTableSize
		mov	di, ss:[frame].GPPF_newGeode.GPI_relocationTableSize
		jne	doPop			; They don't match.
		add	cx, si

	; Get the segments of the resources.

		push	bx
		mov	bx, ss:[frame].GPPF_newGeode.GPI_resourceHandle
		call	MemDerefDS
		mov	bx, ss:[frame].GPPF_oldGeode.GPI_resourceHandle
		call	MemDerefES
		pop	bx

	; Check if the contents of the resource and relocation table
	; match.

		clr	si
		mov	di, si
		repe	cmpsb
doPop:
		pop	cx
		LONG je	nextResource		; Resource

createPatchElements:

	; Darn, the resources are different.

		inc	ss:[frame].GPPF_patchFileHeader.PFH_resourceCount
		
	; Create a PatchedResourceEntry.

		call	CreatePatchedResourceEntry	; ds = new entry

	; Fill in the allocation flags.

		push	cx, bx
		lea	bx, ss:[frame].GPPF_newGeode.GPI_geodeHeader
		call	GetResourceAllocationFlags		
		mov	{word} ds:[PRE_heapFlags], cx

	; Fill in the resource size diff.

		mov	ax, ss:[frame].GPPF_newGeode.GPI_resourceSize
;		add	ax, 15				; Paragraph...
;		and	ax, 0fff0h			; ...align.

		mov	bx, ss:[frame].GPPF_oldGeode.GPI_resourceSize
		mov	ds:[PRE_maxResourceSize], bx
;		add	bx, 15				; Paragraph...
;		and	bx, 0fff0h			; ...align.

		sub	ax, bx
		mov	ds:[PRE_resourceSizeDiff], ax

	; Initialize max size.  It will get updated on writing.

		mov	bx, ss:[frame].GPPF_oldGeode.GPI_relocationTableSize
		cmp	bx, ss:[frame].GPPF_newGeode.GPI_relocationTableSize
		ja	initRelocSize
		mov	bx, ss:[frame].GPPF_newGeode.GPI_relocationTableSize
initRelocSize:
		mov	ds:[PRE_maxRelocSize], bx		
		pop	bx

	; Make all necessary patch elements.

		mov	bx, ss:[frame].GPPF_oldGeode.GPI_resourceHandle
		call	MemDerefDS
		mov	bx, ss:[frame].GPPF_newGeode.GPI_resourceHandle
		call	MemDerefES
		clr	ax, cx
		mov	bx, ss:[frame].GPPF_oldGeode.GPI_resourceSize
		mov	dx, ss:[frame].GPPF_newGeode.GPI_resourceSize
		call	CompareBytes

patchRelocationTable::					; (Label is for swat.)

	; Relocation Table.

		mov	ss:[frame].GPPF_relocationPatching, 1
 		mov	ax, ss:[frame].GPPF_oldGeode.GPI_resourceSize
		add	ax, 15				; Paragraph...
		and	ax, 0fff0h			; ...align.
		mov	bx, ss:[frame].GPPF_oldGeode.GPI_relocationTableSize
		add	bx, ax
		dec	bx
		mov	cx, ss:[frame].GPPF_newGeode.GPI_resourceSize
		add	cx, 15				; Paragraph...
		and	cx, 0fff0h			; ...align.
		mov	dx, ss:[frame].GPPF_newGeode.GPI_relocationTableSize
		add	dx, cx
		dec	dx
		call	CompareBytes
		clr	ss:[frame].GPPF_relocationPatching

	; Unlock the PatchedResourceEntry.

		mov	bx, ss:[frame].GPPF_currentResourceEntry
		call	MemUnlock
		pop	cx

nextResource:

	; Free the old and new resource.

		push	bx
		mov	bx, ss:[frame].GPPF_oldGeode.GPI_resourceHandle
		call	MemFree
		mov	bx, ss:[frame].GPPF_newGeode.GPI_resourceHandle
		call	MemFree
		pop	bx

	; Advance to next resource.

		inc	cx
		cmp	cx, ss:[frame].GPPF_newGeode.GPI_geodeHeader.GH_resCount
		LONG jb	loadNewResource

		.leave
		ret

	; This resource only exists in the new geode.

resourceOnlyInNewGeode:

		clr	ax
		mov	ss:[frame].GPPF_oldGeode.GPI_resourceSize, ax
		mov	ss:[frame].GPPF_oldGeode.GPI_resourceHandle, ax
		mov	ss:[frame].GPPF_oldGeode.GPI_relocationTableSize, ax

		inc	ss:[frame].GPPF_patchFileHeader.PFH_newResourceCount
		jmp	createPatchElements		

PatchCompareResources	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadResourceFromGeodeFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a block and load a resource (and its
		relocation table) into it.

CALLED BY:	PatchCompareResources

PASS:		bx	= offset of GeodeHeader on the stack
		cx	= resource number

RETURN:		ax	= segment of resource block
		bx	= handle of resource block
		cx	= size of resource
		dx	= size of relocation table

DESTROYED:	ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	3/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadResourceFromGeodeFile	proc	near
		uses	si,di
		.enter

	; Determine size of relocation table following resource.

		push	cx			; Resource number
		call	GetResourceRelocationTableSize	; cx = size
		mov	si, cx			; Relocation table size.
		pop	cx			; Resource number.

	; Position the geode file at our resource.

		push	bx			; GeodeHeader.
		mov	bx, ss:[bx].GH_geoHandle
		clr	dx
		call	GeodeFindResource
		mov	di, ax			; Resource size.
		pop	bx			; GeodeHeader.
		jc	error

	; Allocate a block to hold resource.

		mov	dx, ss:[bx].GH_geoHandle	; dx = file handle
		add	ax, 15				; Paragraph...
		and	ax, 0fff0h			; ...align.
		add	ax, si			; Relocation table size.
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_NO_ERR shl 8)
		call	MemAlloc
			; ax = segment of new block
			; bx = handle of new block
		jc	error			; Memory allocation error.

	; Read the resource into the new block.

		push	bx			; Resource block handle.
		mov	cx, di			; Resource size.
		add	cx, 15				; Paragraph...
		and	cx, 0fff0h			; ...align.
		add	cx, si			; ...plus reloc table size.
		mov	bx, dx			; bx = file handle
		mov	ds, ax			; Segment of block.
		clr	dx
		clr	al
		call 	FileRead
		pop	bx			; Resource block handle.
		jc	error
		clc

error:
		mov	cx, di			; Resource size.
		mov	dx, si			; Relocation table size.
		.leave
		ret
LoadResourceFromGeodeFile	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetResourceRelocationTableSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the size of the relocation table for the given
		resource.

CALLED BY:	PatchCompareResources

PASS:		bx = offset of GeodeHeader on stack
  		cx = resource number

RETURN:		if error,
			carry set
		else
			carry clear
			cx = word to return
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	3/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetResourceRelocationTableSize	proc	near
		uses	ax,bx,dx
		.enter

	; Figure out where Relocation Table Size Table starts.

		push	cx				; Resource number.
		call	CalcOffsetToRelocTableSizeTable

	; Count offset into Relocation Table Size Table

		pop	dx				; Resource number.
		shl	dx
		add	dx, cx

	; Get the size.

		mov	bx, ss:[bx].GH_geoHandle
		call	SnatchWordFromGeodeFile

	; Return result in cx.

		mov	cx, ax
		clc

		.leave
		ret

GetResourceRelocationTableSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetResourceAllocationFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the allocation flags for a given resource. 

CALLED BY:	PatchCompareResources

PASS:	 	cx = resource number
		bx = offset of GeodeHeader on stack

RETURN:		cx = allocation flags

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	3/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetResourceAllocationFlags	proc	near
		uses	ax,bx,dx
		.enter

	; Figure out where Relocation Table Size Table starts.

		push	cx				; Resource number.
		call	CalcOffsetToRelocTableSizeTable

	; Count Relocation Table Size Table

		mov	dx, ss:[bx].GH_resCount
		shl	dx
		add	cx, dx

	; Count offset into Allocation Flags Table

		pop	dx				; Resource number.
		shl	dx
		add	dx, cx

	; Get the flags.

		mov	bx, ss:[bx].GH_geoHandle
		call	SnatchWordFromGeodeFile

	; Return result in cx.

		mov	cx, ax
		clc

		.leave
		ret
GetResourceAllocationFlags	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcOffsetToRelocTableSizeTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the offset of the Relocation Table Size
		Table into the core block.

CALLED BY:	GetResourceRelocationTableSize

PASS: 		bx = offset of GeodeHeader on stack

RETURN:		cx = offset of table

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	3/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcOffsetToRelocTableSizeTable	proc	near
		uses	ax,dx
		.enter

	; Count GeodeFileHeader.

		mov	cx, GEODE_FILE_TABLE_SIZE + size ExecutableFileHeader

	; Count Imported Library Table.

		mov	ax, ss:[bx].GH_libCount
		mov	dx, size ImportedLibraryEntry
		mul	dx
		jc	overFlow
		add	cx, ax

	; Count Exported Entry Point Table.

		mov	ax, ss:[bx].GH_exportEntryCount
		shl	ax
		shl	ax
		add	cx, ax

	; Count Resource Size and Position Tables 

		mov	ax, ss:[bx].GH_resCount
		shl	ax
		mov	dx, ax
		shl	ax
		add	ax, dx		; ax = 6*resources
		add	cx, ax

overFlow:
		.leave
		ret
CalcOffsetToRelocTableSizeTable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SnatchWordFromGeodeFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the word at the offset in the specified geode
		file.

CALLED BY:	PatchCompareResources
PASS:		bx	= geode file handle
		dx	= offset of word
RETURN:		ax	= word
DESTROYED:
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	3/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SnatchWordFromGeodeFile	proc	near
		uses	bx,cx,dx
wordBuffer	local	word
		.enter

		mov	al, FILE_POS_START
		clr	cx
		call	FilePos	

		push	ds
		clr	al
		mov	cx, 2
		segmov	ds, ss, dx
		lea	dx, ss:[wordBuffer]
		call	FileRead
		pop	ds

		mov	ax, ss:[wordBuffer]

		.leave
		ret
SnatchWordFromGeodeFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the most efficient list of patch elements to
		describe the differences between two strings of bytes.

CALLED BY:	PatchCompareResources

PASS:		ax	= old start
		bx	= old end
		cx	= new start
		dx	= new end
		ds	= old resource segment
		es	= new resource segment

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	We have two strings of bytes.  We want to create to most
	efficient list of patch elements that describes the difference
	between the strings.

	Old resource:	   ABCDEFGXXXXXXXJKLMNOPXXXXXXXXWXYZ   
		Old start--^                                ^---Old end.

	New resource:	   ABCDEFGYYYYYJKLMNOPYYYYYYYYWXYZ   
		New start--^                              ^---New end.

	1. Make sure bounds are valid.

	2. If either string is empty, create a patch element.

	3. Increment the start pointers while the old and new resource
	   bytes match.

	   Old resource:          XXXXXXXJKLMNOPXXXXXXXXWXYZ   
		       Old start--^                         ^---Old end.

	   New resource:          YYYYYJKLMNOPYYYYYYYYWXYZ   
		       New start--^                       ^---New end.

	4. Decrement the end pointers while the old and new resource
	   bytes match.

	   Old resource:          XXXXXXXJKLMNOPXXXXXXXX   
		       Old start--^                     ^---Old end.

	   New resource:          YYYYYJKLMNOPYYYYYYYY   
		       New start--^                   ^---New end.

	5. Find the largest section of matching bytes contained in both
	   strings.

	   If the match is smaller than PATCH_GRANULARITY bytes,
	   create a patch element to replace the whole string.

	   If the match is greater than PATCH_GRANULARITY bytes, call
	   CompareBytes twice, with the strings split at the match. 

	   -------------------CALL CompareBytes-------------------------

	   Old resource:          XXXXXXX
		       Old start--^      ^---Old end.

	   New resource:          YYYYY
		       New start--^    ^---New end.

	   -------------------CALL CompareBytes-------------------------

	   Old resource:                 JKLMNOPXXXXXXXX   
		              Old start--^              ^---Old end.

	   New resource:               JKLMNOPYYYYYYYY   
		            New start--^              ^---New end.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	2/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareBytes	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter inherit GeneratePatchFile

	; Make sure both resource's end >= position.

		cmp	ax, bx
		ja	errorInvalidOffset	; Error: start > end.
		cmp	cx, dx
		ja	errorInvalidOffset	; Error: start > end.

	; Increment the start offsets until we find a difference.

		mov	si, ax		; Old resource start offset.
		mov	di, cx		; New resource start offset.

incrementLoop:
		cmp	si, bx
		jae	incOutOfBytes	; No bytes left in old resource.
		cmp	di, dx
		jae	incOutOfBytes	; No bytes left in new resource.
		cmpsb
		je	incrementLoop	; Bytes matched.

	; Save the new start offsets.

		dec 	si		; Point to non-matching byte.
		dec	di		; Point to non-matching byte.
		mov	ax, si		; Old resource start offset.
		mov	cx, di		; New resource start offset.

	; Decrement the end offsets until we find a difference.

		mov	si, bx		; Old resource end offset.
		mov	di, dx		; New resource end offset.
		dec	si
		dec	di
		push	cx
		mov	cx, 0FFFFh
		std
		repe	cmpsb
		cld
		pop	cx
		add	si, 2
		add	di, 2

	; Save the new end offsets.

		mov	bx, si		; Old resource start offset.
		mov	dx, di		; New resource start offset.

	; Find the largest match between current offsets.

		call	FindLargestMatchSimple
		jc	replaceBytes

	; Split the range at the matching bytes, recurse.

		xchg	bx, si		; bx = Old resource match offset.
		xchg	dx, di		; dx = New resource match offset.
		call	CompareBytes

		xchg	bx, si		; bx = Old resource end offset.
		xchg	dx, di		; dx = New resource end offset.
		xchg	ax, si		; ax = Old resource match offset.
		xchg	cx, di		; cx = Old resource match offset.
		call	CompareBytes

done:
		.leave			; <---- EXIT HERE
		ret

errorInvalidOffset:
		jmp	done

incOutOfBytes:

	; Save the new start offsets.

		mov	ax, si		; Old resource start offset.
		mov	cx, di		; New resource start offset.

outOfBytes:
		call	OutOfBytes
		jmp	done

replaceBytes:

	; Determine the size of the replacement (we will replace as
	; much as is possible, then insert or delete the rest).

		call	CalculateReplaceSize

	; Replace only this many bytes.

		push	bx, dx		; End offsets.
		; ax = position in old resource to patch.
		mov	bx, PT_REPLACE
		; cx = position in new resource of replacement string.
;		mov	cx, di		; cx = offset of data in new resource		
;		mov	dx, si		; dx = size to replace
;		add	dx, cx
		call	CreatePatchElement
		pop	bx, dx		; End offsets.

	; Advance start offsets to account for replace.

		add	ax, si
		add	cx, si 

	; Deal with any left over bytes.

		jmp	outOfBytes

CompareBytes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutOfBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Either the old or new resource is out of bytes.
		Create a delete or insert patch element. 

CALLED BY:	CompareBytes

PASS:		ax	= old start
		bx	= old end
		cx	= new start
		dx	= new end
		ds	= old resource segment
		es	= new resource segment
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	2/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutOfBytes	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

	; Are there still bytes to check in the old resource?

		cmp	ax, bx
		jne	oldResourceHasBytes	; start <> end.

	; No bytes left in old resource.  How about new resource?

		cmp	cx, dx
		je	done			; No bytes in either resource.

	; We need to do an insertion.  But pass replace constant if
	; this is a new resource.

		mov	bx, PT_INSERT		; Assume insertion.
		tst	ax
		jnz	doInsertion
		mov	bx, PT_REPLACE		; Special case (new resource). 

doInsertion:

	; Do the insertion.

		call	CreatePatchElement
		jmp	done

oldResourceHasBytes:

	; No bytes left in old resource.  How about new resource?

		cmp	cx, dx
		jne	errorNotOutOfBytes	; No bytes in either resource.

	; No new resource bytes: do a delete.

		mov	cx, ax
		mov	dx, bx
		mov	bx, PT_DELETE
		call	CreatePatchElement

done:
		.leave
		ret

errorNotOutOfBytes:

	; This routine should only be called when one of the resources
	; is out of bytes.

		jmp	done

OutOfBytes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindLargestMatchSimple
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find PATCH_GRANULARITY or more matching bytes in the
		new and old resource.

CALLED BY:	CompareBytes

PASS:		ax	= old start
		bx	= old end
		cx	= new start
		dx	= new end
		ds	= old resource segment
		es	= new resource segment

RETURN:		if PATCH_GRANULARITY matching bytes couldn't be found,
			carry set
		else
			carry clear
			si	= offset of match in old resource
			di	= offset of match in new resource

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindLargestMatchSimple	proc	near
		uses	ax,bx,cx,dx
originalOldStart	local	word push ax
oldStart		local	word push ax
oldEnd			local	word push bx
newStart		local	word push cx
newEnd			local	word push dx
mostMatchingBytes	local	word
bestMatchOldPos		local	word
bestMatchNewPos		local	word
		.enter

		clr	ss:[mostMatchingBytes]

		mov	cx, ss:[oldEnd]
		sub	cx, ss:[oldStart]
		inc	cx

oldStartLoop:
		call	FindLargestAlignedMatch
		inc	ss:[oldStart]
		loop	oldStartLoop

		mov	cx, ss:[originalOldStart]
		mov	ss:[oldStart], cx
		mov	cx, ss:[newEnd]
		sub	cx, ss:[newStart]
		inc	cx

newStartLoop:
		call	FindLargestAlignedMatch
		inc	ss:[newStart]	
		loop	newStartLoop

	; We're done.  Have we found a match long enough?

		cmp	ss:[mostMatchingBytes], PATCH_GRANULARITY
		stc
		jl	exit

	; Return the result of the match.
		
		mov	si, ss:[bestMatchOldPos]
		mov	di, ss:[bestMatchNewPos]
		clc

exit:
		.leave
		ret

FindLargestMatchSimple	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindLargestAlignedMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the largest matching string of bytes at the same
		offsets between oldStart and oldEnd and newStart and
		newEnd.

CALLED BY:	FindLargestMatchSimple

PASS:		ds	= old resource segment
		es	= new resource segment

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	local variables will be updated if larger match is found.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	3/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindLargestAlignedMatch	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter	inherit FindLargestMatchSimple

	; Set initial offsets to compare.

		mov	si, ss:[oldStart]
		mov	di, ss:[newStart]

	; Set maximum loop.

		mov	cx, ss:[oldEnd]
		sub	cx, si
		mov	dx, ss:[newEnd]
		sub	dx, di
		cmp	cx, dx
		jb	continueCompare		; Use cx, since it's smaller.
		mov	cx, dx			; Use dx, since it's smaller.
		inc	cx

continueCompare:

	; Scan through non-matching bytes.

		repne	cmpsb
		jcxz	done
		dec	si
		dec	di
		inc	cx

	; Remember where match comparison started.

		mov	ax, si		; oldStart
		mov	bx, di		; newStart

	; Remember where we started the compare.

		mov	dx, cx

	; Scan through matching bytes.

		repe	cmpsb
		pushf
		sub	dx, cx
		popf
		je	proposeMatch
		dec	dx

proposeMatch:

	; We've found a non-matching byte.  Check if whatever matched
	; is significant.

		cmp	dx, ss:[mostMatchingBytes]
		ja	recordMatch

	; Are we past the end of the resource?

		inc	cx			; So loop and rep can use cx.
		loop	continueCompare

done:
		.leave
		ret

recordMatch:

	; Save information about this match.

		mov	ss:[bestMatchOldPos], ax
		mov	ss:[bestMatchNewPos], bx
		mov	ss:[mostMatchingBytes], dx
		inc	cx			; So loop and rep can use cx.
		loop	continueCompare
		jmp	done

FindLargestAlignedMatch	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateReplaceSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the smaller of the sizes of the two strings.

CALLED BY:	CompareBytes

PASS:		ax	= old start
		bx	= old end
		cx	= new start
		dx	= new end

RETURN:		si	= replace size

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	2/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalculateReplaceSize	proc	near
		uses	bx,dx
		.enter

	; Calculate sizes of two strings.

		sub	bx, ax
		sub	dx, cx

	; Return the smaller of sizes.

		cmp	bx, dx
		mov	si, dx
		ja	done
		mov	si, bx

done:
		.leave
		ret

CalculateReplaceSize	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreatePatchElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a PatchElement for this resource.

CALLED BY:	CompareBytes

PASS:		ax = 	offset of where patch should be applied to old resource
		bx =	PatchType

		if PT_INSERT or PT_REPLACE

			cx = 	offset (into new resource) of patch data
				to insert/replace
			dx = 	offset (into new resource) of end of
				patch data to insert/replace

		if PT_DELETE

			cx = 	offset (into old resource) of patch data
				to delete
			dx = 	offset (into old resource) of end of
				patch data to delete

RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	2/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreatePatchElement	proc	near
		uses	ax,bx,cx,dx,si,di
		.enter	inherit	GeneratePatchFile

		push	ds, es

	; Calculate size of replace or insert.

		mov	si, dx
		sub	si, cx

	; Calculate PE_flags field for below.

		push	cx
		mov	di, bx
		mov	cl, 14
		shl	di, cl
		or	di, si
		pop	cx

	; Determine if there is any patch data.

		cmp	bx, PT_INSERT
		je	afterClear
		cmp	bx, PT_REPLACE
		je	afterClear
		clr	si			; Assume data size is 0.

afterClear:

	; Calculate PatchEntry size.

		push	ax	; Where to apply patch to old resource.
		mov	ax, si
		add	ax, size PatchElement

		mov	bx, ss:[frame].GPPF_currentResourceEntry
		call	MemDerefDS

	; Record PatchEntry size 

		tst	ss:[frame].GPPF_relocationPatching
		jnz	incRelocSize		
		add	ds:[PRE_size], ax

		cmp	ax, MAX_PATCH_SIZE
		ERROR_Z	PATCH_FILE_CREATE_ERROR

		jmp	allocateElement
incRelocSize:
		add	ds:[PRE_relocSize], ax

allocateElement:

	; Allocate PatchElement

		push	cx
		mov	cl, mask HF_SWAPABLE
		mov	ch, mask HAF_ZERO_INIT or mask HAF_LOCK
		add	ax, size PatchCreateElement - size PatchElement
		call	MemAlloc
		mov	es, ax
		pop	cx
		pop	ax	; Where to apply patch to old resource.

	; Set PatchElement data fields.

		mov	es:[PCE_entry].PE_pos, ax
		mov	es:[PCE_entry].PE_flags, di

	; Put PatchElement into correct linked list.

		tst	ss:[frame].GPPF_relocationPatching
		jnz	calculateRelocPosition

	; Insert element in regular list.
		
		mov	ax, ds:[PRCE_resourcePatches]
		mov	es:[PCE_next], ax
		mov	ds:[PRCE_resourcePatches], bx
		jmp	copyDataToElement

calculateRelocPosition:

	; Subtract out the resource size from the position to patch.

		mov	ax, ss:[frame].GPPF_oldGeode.GPI_resourceSize
		add	ax, 15				; Paragraph...
		and	ax, 0fff0h			; ...align.
		sub	es:[PCE_entry].PE_pos, ax

insertInRelocList::
		
	; Insert element in relocation list.

		mov	ax, ds:[PRCE_relocPatches]
		mov	es:[PCE_next], ax
		mov	ds:[PRCE_relocPatches], bx

copyDataToElement:

	; Is there any patch data?

		tst	si
		jz	done

	; Copy patch data into element.

		push	bx
		xchg	cx, si			; Bytes of data, offset.
		mov	bx, ss:[frame].GPPF_newGeode.GPI_resourceHandle
		call	MemDerefDS
		mov	di, offset PCE_data
		rep	movsb
		pop	bx

done:

	; Unlock the new patch element.

		call	MemUnlock
		pop	ds, es

		.leave
		ret
CreatePatchElement	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreatePatchedResourceEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a PatchedResourceEntry for this resource.

CALLED BY:	PatchCompareResources
PASS:		cx	= resource number
RETURN:		ds	= segment of locked PatchedResourceEntry
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	3/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreatePatchedResourceEntry	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter	inherit GeneratePatchFile

	; Allocate a new PatchedResourceEntry.

		mov	dx, cx		; Resource number.

	; Allocate a block for PRE.

		mov	ax, size PatchedResourceCreateEntry
		mov	cl, mask HF_SWAPABLE
		mov	ch, mask HAF_ZERO_INIT or mask HAF_LOCK
		call	MemAlloc
		jc	error
		mov	ds, ax

	; Fill in the resource id.

		mov	ds:[PRE_id], dx 
		
	; Put new entry at the end of the list.

		tst	ss:[frame].GPPF_resourceList
		je	prependToList		; We are first entry.

	; We are not the first entry: make last entry's PRCE_next
	; point to the rest of the list.

		push	ds
		mov	cx, bx
		mov	bx, ss:[frame].GPPF_currentResourceEntry
		call	MemLock
		mov	ds, ax
		mov	ds:[PRCE_next], cx
		call	MemUnlock
		mov	bx, cx
		mov	ss:[frame].GPPF_currentResourceEntry, bx
		pop	ds

done:
error:
		.leave
		ret

prependToList:

	; Set as the current entry.

		mov	ss:[frame].GPPF_resourceList, bx
		mov	ss:[frame].GPPF_currentResourceEntry, bx
		jmp	done

CreatePatchedResourceEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WritePatchResourceList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the PRE_resourcePos fields, and write out the
		PatchedResourceEntry structures.

CALLED BY:	GeneratePatchFile
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WritePatchResourceList	proc	near
		uses	ax,bx,cx,dx,si,di
		.enter	inherit GeneratePatchFile

	; Set starting patch file position.

		clr	si
		mov	bl, size PatchedResourceEntry
		mov	ax, ss:[frame].GPPF_patchFileHeader.PFH_resourceCount
		mul	bl
		mov	di, ax
		add	di, size PatchFileHeader

	; Get first PatchedResourceEntry.

		mov	bx, ss:[frame].GPPF_resourceList

nextPatchedResourceEntry:

	; Are we done?

		tst	bx
		jz	done

	; Lock down the block with the entry.

		call	MemLock
		mov	ds, ax

	; Calculate PRE_maxResourceSize.

		push	bx
		mov	bx, ds:[PRCE_resourcePatches]
		mov	cx, ds:[PRE_maxResourceSize]
		call	ComputeMaxSize
		mov	ds:[PRE_maxResourceSize], cx

	; Calculate PRE_maxRelocSize.

		mov	bx, ds:[PRCE_relocPatches]
		mov	cx, ds:[PRE_maxRelocSize]
		call	ComputeMaxSize
		mov	ds:[PRE_maxRelocSize], cx

	; Assign PRE_pos

		movdw	ds:[PRE_pos], sidi

writePatchedResourceEntry::				; Keep for Swat.

	; Write out the PatchedResourceEntry.

		clr	al
		mov	bx, ss:[frame].GPPF_patchFileHandle
		clr	dx
		mov	cx, size PatchedResourceEntry
		call	FileWrite
		pop	bx		

	; Increment the position.

		push	cx, dx
		clr	cx
		mov	dx, ds:[PRE_size]
		adddw	sidi, cxdx
		clr	cx
		mov	dx, ds:[PRE_relocSize]
		adddw	sidi, cxdx 
		pop	cx, dx
	
	; Get the next entry, unlock this one

		mov	ax, ds:[PRCE_next]
		call	MemUnlock
		mov	bx, ax
		jmp	nextPatchedResourceEntry

done:
		.leave
		ret
WritePatchResourceList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WritePatchLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the PatchElement structures for each resource.

CALLED BY:	GeneratePatchFile
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WritePatchLists	proc	near
		uses	ax,bx,cx,dx,si,di
		.enter	inherit GeneratePatchFile

	; Get first PatchedResourceEntry.

		mov	bx, ss:[frame].GPPF_resourceList

nextPatchedResourceEntry:

	; Are we done?

		tst	bx
		jz	done

	; Lock down the block with the entry.

		call	MemLock
		mov	ds, ax
		push	bx

writePatchResourceElements::				; leave for Swat.

	; Write the patch elements for this geode.

		mov	bx, ds:[PRCE_resourcePatches]
		call	WritePatchElement

	; Are there any relocation table patches.

		tst	ds:[PRCE_relocPatches]
		jz	advanceEntry

writePatchRelocationElements::				; leave for Swat.

	; Write the relocation patch elements for this geode.

		mov	bx, ds:[PRCE_relocPatches]
		call	WritePatchElement		

advanceEntry:

	; Get the next entry, unlock this one

		pop	bx
		mov	ax, ds:[PRCE_next]
		call	MemFree
		mov	bx, ax
		jmp	nextPatchedResourceEntry

done:
		.leave
		ret
WritePatchLists	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WritePatchElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the passed patch element and all following
		it in the list.

CALLED BY:	WritePatchLists
PASS:		bx = handle of first patch element in the list.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WritePatchElement	proc	near
		uses	ax,bx,cx,dx,si,di,ds
		.enter	inherit	GeneratePatchFile

nextPatchElement:

	; Are we done?

		tst	bx
		jz	done

	; Lock down the block with the entry.

		call	MemLock
		mov	ds, ax

	; Determine the size of the element to write out.

		mov	ax, ds:[PCE_entry].PE_flags
		and	ax, mask PF_TYPE
		mov	cl, 14
		shr	ax, cl
		mov	cx, size PatchElement
		cmp	ax, PT_DELETE
		je	writeElement
		cmp	ax, PT_INSERT_ZERO
		je	writeElement

	; There is patch data, so add it to the size.

		mov	ax, ds:[PCE_entry].PE_flags
		and	ax, mask PF_SIZE
		add	cx, ax

writeElement:

	; Write out the element.

		push	bx
		clr	al
		mov	bx, ss:[frame].GPPF_patchFileHandle
		mov	dx, offset PCE_entry
		call	FileWrite
		pop	bx

	; Get the next entry, unlock this one

		mov	ax, ds:[PCE_next]
		call	MemFree
		mov	bx, ax
		jmp	nextPatchElement

done:
		.leave
		ret
WritePatchElement	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeMaxSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the maximum size of a resource or
		relocation table of the passed size when the passed
		patch elements are applied to it. 

CALLED BY:	WritePatchResourceList

PASS:		bx	= list of PatchElements
		cx	= starting size of the resource/relocation table

RETURN:		cx	= maximum size

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeMaxSize	proc	near
		uses	ax,bx,dx,si,di,ds
		.enter

	; Set the starting maximum.

		mov	ax, cx

entryLoop:

	; Are we at the end of the PatchElement list?

		tst	bx
		jz	returnMax

	; Lock down the PatchElement.

		push	ax
		call	MemLock
		mov	ds, ax
		pop	ax		

	; Get the patch type.

		mov	dx, ds:[PCE_entry].PE_flags
		and	dx, mask PF_TYPE

	; Is this a replace element?

		cmp	dx, PT_REPLACE shl offset PF_TYPE
		je	nextEntry

	; Is this a delete element?

		cmp	dx, PT_DELETE shl offset PF_TYPE
		jne	handleInsert

	; Handle delete entry.

		mov	dx, ds:[PCE_entry].PE_flags
		and	dx, mask PF_SIZE
		sub	cx, dx
		jmp	nextEntry

handleInsert:

	; Handle insert entry.

		mov	dx, ds:[PCE_entry].PE_flags
		and	dx, mask PF_SIZE
		add	cx, dx

	; Update the maximum size if necessary.

		cmp	cx, ax
		jbe	nextEntry
		mov	ax, cx		; Update max size.

nextEntry:
		mov	dx, ds:[PCE_next]
		call	MemUnlock
		mov	bx, dx
		jmp	entryLoop

returnMax:
		mov	cx, ax

		.leave
		ret
ComputeMaxSize	endp



DocumentBuildCode	ends	
