COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File
FILE:		fileInit.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name		Description
	----		-----------
   EXT	InitFile	Initialize the file module

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

DESCRIPTION:
	This module initializes the file module.  See fileManager.asm for
documentation.

	$Id: fileInit.asm,v 1.1 97/04/05 01:11:38 newdeal Exp $

-------------------------------------------------------------------------------@





;---

COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFile

DESCRIPTION:	Initialize the File module

CALLED BY:	EXTERNAL
		InitGeos

PASS:
	ds - kernel variable segment

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

InitFile	proc	near
	mov	ds:[fileList], 0		;Initialize file list
	ret

InitFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSetInitialPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the initial path block for the kernel scheduler thread.
		This initial path is inherited by every other thread in
		the system...

CALLED BY:	InitGeos
PASS:		nothing
RETURN:		nothing
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileSetInitialPath proc	near
		uses	ax, ds, cx, di
		.enter
	;
	; We assume the loader left us in loaderVars.KLV_topLevelPath.
	; We know the skeleton driver relies on the DOS working directory
	; and stores no private data in the FilePath block.
	; We know the logical path (pointed to by FP_logicalDisk & FP_path)
	; needs to be SP_TOP and a null tail.
	;
	; What this means is we can initialize the block the same for both
	; network and standalone mode (where standard path merging isn't
	; enabled) and only change the value of the actual disk handle
	; we store in the path block's HM_otherInfo field.
	;
	; Allocate the new block swapable, and non-discardable, and lock it
	; for easy initialization.
	;
		mov	ax, size FilePath+size StdPathPrivateData+1+1
		mov	cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) \
				or mask HF_SHARABLE or mask HF_SWAPABLE
		mov	bx, handle 0	; path blocks are all owned by the
					;  kernel
		call	MemAllocSetOwnerFar
		mov	ds, ax

	;
	; Initialize the thing appropriately.
	;
		clr	ax
		mov	ds:[FP_prev], ax
		mov	{word}({StdPathPrivateData}ds:[FP_private]).SPPD_flags,
				ax		; set flags and tail at the
						;  same time

		mov	di,  offset FP_private + size StdPathPrivateData + 1
		mov	ds:[FP_path], di
		mov	ds:[FP_stdPath], SP_TOP
		mov	ds:[FP_logicalDisk], SP_TOP
		mov	ds:[FP_pathInfo], DirPathInfo <1, 0, SP_TOP>
SBCS <		mov	{char}ds:[di], al		; null logical tail,too>
DBCS <		mov	{wchar}ds:[di], ax		; null logical tail,too>
	;
	; Figure the actual disk handle to use.
	; 
		LoadVarSeg ds, ax
		mov	ax, ds:[topLevelDiskHandle]	;assume standalone
		tst	ds:[loaderVars].KLV_stdDirPaths
		jz	setActualDisk
		mov	ax, SP_TOP
setActualDisk:
		mov	ds:[bx].HM_otherInfo, ax

		call	MemUnlock
	;
	; Set it as the current path.
	; 
		mov	ss:[TPD_curPath], bx
		.leave
		ret
FileSetInitialPath endp
