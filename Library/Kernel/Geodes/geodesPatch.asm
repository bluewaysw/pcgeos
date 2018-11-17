COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel
FILE:		geodesPatch.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

SYSTEM PATCHING INITIALIZATION (geodesPatchInit.asm)

On system startup (InitGeos), create a list of general patch files.  
Check for general patches referring to the same geode, deleting all
but the newest.  Apply the general patches, as well as any language
patches in the standard path to geodes that are already running.


INTRODUCING NEW PATCHES (geodesPatchInit.asm)

If a new general patch file needs to be introduced to the system
afterwards, add it to the list.


DETERMINE IF GEODE SHOULD BE PATCHED (geodesPatchFile.asm)

Check if there are any patch files associated with a particular geode,
loading in the patch data if it exists.

This occurs after the system patching initialization, once for each
geode that is already open.  It also occurs once for every geode
subsequently loaded.


INITIALIZE A GEODE PATCH (geodesPatchCoreBlock.asm, geodesPatchXIP.asm)

A geode's core block needs to be modified to allow patching to work
correctly.


APPLY A PATCH TO A RESOURCE (geodesPatchResource.asm)

When a resource is loaded in, check if there is patch data for
that resource.  If so, apply it.


CLEANING UP ON GEODE FREE

When a geode is freed, close the patch file and free the patch data.

	GeodePatchFree		Close the patch file and free the
				patch data.

GENERAL FILE ROUTINES (geodesPatchFile.asm)

GENERAL ROUTINES

	GeodeGetGeneralPatchBlock	Return the segment of the
				passed geode's locked general patch
				data.
	IsMultiLanguageModeOn	Return carry clear if multi-language
				mode is on.

ERROR-CHECKING ROUTINES

	ECCheckCoreBlockDS	Make sure ds:0 is a handle pointing to
				DS, and make sure ds:GM_geodeFileType
				is a valid GeodeType.  Can't check
				self-ownership, because it's not
				established until later.
	ECCheckDGroupDS		Check if ds points to our idata segment.
	ECCheckPatchDataHeaderES	Check if ES points to a valid
				PatchDataHeader.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chrisb	  1/14/94   	Initial version.
	canavese 10/19/94	Completely revamped, added multi-
				language capabilities, and broke the
				code into separate files. 

DESCRIPTION:
	
	Facilitate bug-fixing and language translation "patches" to
	modify old geodes as they are loaded into memory.

	$Id: geodesPatch.asm,v 1.1 97/04/05 01:12:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geodesPatchCoreBlock.asm
include geodesPatchFile.asm
include geodesPatchInit.asm
include geodesPatchResource.asm


GLoad	segment	resource

if USE_PATCHES

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodePatchFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the patch file and free the patch data.

CALLED BY:	FreeGeode
PASS:		es - core block of geode being freed.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	12/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodePatchFree	proc	far
		uses	ax,bx
		.enter

if USE_BUG_PATCHES

tryGeneralPatchList::

	; Are there any general patches?

		tst	es:[GH_generalPatchData]
		jz	tryLanguagePatchList

	; Close the general patch file.

		push	ds		; Core block.
		mov	bx, es:[GH_generalPatchData]
		call	MemLock
		mov	ds, ax

		mov	al, FILE_NO_ERRORS
		mov	bx, ds:[PDH_fileHandle]
		call	FileCloseFar

		mov	bx, es:[GH_generalPatchData]
		call	MemFree
		clr	es:[GH_generalPatchData]
		pop	ds
endif

tryLanguagePatchList::

if MULTI_LANGUAGE

	; Are there any language patches?

		tst	es:[GH_languagePatchData]
		jz	done

	; Close the language patch file.

		push	ds		; Core block.
		mov	bx, es:[GH_languagePatchData]
		call	MemLock
		mov	ds, ax

		mov	al, FILE_NO_ERRORS
		mov	bx, ds:[PDH_fileHandle]
		call	FileCloseFar

		mov	bx, es:[GH_languagePatchData]
		call	MemFree
		clr	es:[GH_languagePatchData]
		pop	ds

endif ; MULTI_LANGUAGE

done::	
		.leave
		ret
GeodePatchFree	endp

endif ; USE_PATCHES


if USE_BUG_PATCHES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeodeGetGeneralPatchBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the segment of the passed geode's locked
		general patch data. 

CALLED BY:	Various patch routines.
		GeodePatchReAllocCoreBlock,GeodePatchCoreBlock,
		GeodePatchPreLoadNewResources, GeodePatchInitNewResources,
		GeodePatchRelocateNewExportEntries,
		GeodePatchReadAllocationFlags
		GeodeGetPatchedResourceSize

PASS:		ds - segment of core block

RETURN:		es - segment of patch data

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/30/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeodeGetGeneralPatchBlock	proc near
		uses	bx
		.enter
EC <		call	ECCheckCoreBlockDS			>

		mov	bx, ds:[GH_generalPatchData]
		call	MemDerefES

EC <		call	ECCheckPatchDataHeaderES ; es		>

		.leave
		ret
GeodeGetGeneralPatchBlock	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsMultiLanguageModeOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry clear if multi-language mode is on.

CALLED BY:	GLOBAL
PASS:		nothin'
RETURN:		if multi-language mode is on,
			carry clear
		else
			carry set
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	12/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsMultiLanguageModeOn	proc	far
if MULTI_LANGUAGE
		uses	ax,cx,ds
		.enter

	; Get global .

		LoadVarSeg	ds, ax
		mov	cx, ds:[multiLanguageMode]
		stc			; Assume multi-language off.
		jcxz	done
		clc
done:
		.leave
else
		stc
endif
		ret
IsMultiLanguageModeOn	endp



if ERROR_CHECK and USE_PATCHES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckCoreBlockDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure ds:0 is a handle pointing to DS, and make
		sure ds:GH_geodeFileType is a valid GeodeType.
		Can't check self-ownership, because that's not
		established till later.

CALLED BY:	internal

PASS:		ds - core block

RETURN:		nothing 

DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/24/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckCoreBlockDS	proc far
		uses	ax, bx, si, es
		.enter

		pushf
		LoadVarSeg	es, ax
		mov	ax, ds
		mov	bx, ds:[GH_geodeHandle]
		cmp	es:[bx].HM_addr, ax
		ERROR_NE BAD_DS
	

	; This check doesn't work for geodes compiled using the PC SDK
	; for some reason
		
;;		cmp	ds:[GH_geodeFileType], GeodeType
;;		ERROR_A	BAD_DS

	; For some reason, the extra library table for the kernel's
	; core block points beyond the end of the block (in XIP), so
	; don't bother checking this
	;
;;		mov	si, ds:[GH_extraLibOffset]
;;		EC_BOUNDS	ds, si

		popf
		.leave
		ret
ECCheckCoreBlockDS	endp

ECCheckCoreBlockES	proc	far
		uses	ds
		.enter
		segmov	ds, es
		call	ECCheckCoreBlockDS
		.leave
		ret
ECCheckCoreBlockES	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckDGroupDS/ES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if ds points to our idata segment.

CALLED BY:

PASS:		ds	= segment to compare.

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/24/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckDGroupDS	proc	far
		uses	ax,bx
		.enter
		pushf
		mov	ax, ds
		mov	bx, segment idata
		cmp	ax, bx
		ERROR_NE BAD_DS
		popf
		.leave
		ret
ECCheckDGroupDS	endp

ECCheckDGroupES	proc	far
		uses	ds
		.enter
		segmov	ds, es
		call	ECCheckDGroupDS
		.leave
		ret
ECCheckDGroupES	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckPatchDataHeaderES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if ES points to a valid PatchDataHeader.

CALLED BY:	INTERNAL
PASS:		es	= segment to check
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	1/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckPatchDataHeaderES	proc	far
		uses	ax,bx
		.enter

		mov	ax, es 
		call	ECCheckSegment

		mov	bx, es:[PDH_fileHandle]
		call	ECCheckFileHandle

		.leave
		ret
ECCheckPatchDataHeaderES	endp

endif ; ERROR_CHECK and USE_PATCHES

GLoad	ends



