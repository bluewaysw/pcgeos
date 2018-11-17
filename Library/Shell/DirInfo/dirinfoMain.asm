COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Shell -- DirInfo
FILE:		dirinfoMain.asm

AUTHOR:		Martin Turon, November 9, 1992

METHODS:
	Name			Description
	----			-----------
	ShellCreateDirInfo	Creates a new dirinfo file
	ShellOpenDirInfoRW	Opens a dirinfo file read/write
	ShellOpenDirInfo	Opens a dirinfo file read only
	ShellOpenDirInfoLow	low-level code to open dirinfo file
	ShellCloseDirInfo	Closes a dirinfo file
	ShellSearchDirInfo	Searchs a dirinfo chunk array
	ShellSetPosition	Sets the position of the given file
	ShellGetPosition	Gets the position of the given file
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/9/92         Initial version

DESCRIPTION:
	Externally callable routines for this module.
	No routines outside this file should be called from outside this
	module.

	$Id: dirinfoMain.asm,v 1.1 97/04/07 10:45:48 newdeal Exp $

=============================================================================@



COMMENT @-------------------------------------------------------------------
			ShellCreateDirInfo
----------------------------------------------------------------------------

DESCRIPTION:	Creates a new DIRINFO file to be written to in the
		current directory.

CALLED BY:	GLOBAL - FolderSaveDirInfo

PASS:		ds:dx	= name of dirinfo file to create

RETURN:	IF ALL GOES WELL:
		carry clear

		*ds:si	= locked dirinfo chunk array 
		bx	= VM file handle
		bp	= memory handle of locked VM block

	ELSE ERROR OCCURED:
		carry set
		ax	= VMStatus

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/20/92	Initial version

---------------------------------------------------------------------------@
ShellCreateDirInfo	proc	far
		.enter

if ERROR_CHECK
	;
	; Validate that the filename is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, ds						>
FXIP<		mov	si, dx						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif

	;
	; Open the old @DIRINFO file if it exists.
	;
		mov	ax, (VMO_CREATE shl 8) +  \
			    (mask VMAF_FORCE_READ_WRITE) 
		clr	cx			; use default compression
		call	VMOpen
		jnc	opened

	;
	; If error on open, delete DIRINFO, and try to create again...
	;

		call	FileDelete
		mov	ax, (VMO_CREATE shl 8) +  \
			    (mask VMAF_FORCE_READ_WRITE) 
		call	VMOpen
		jc	error

opened:
		cmp	ax, VM_CREATE_OK
		push	bx			; save VM file handle
		je	createNewDirInfoFile

		call	VMGetMapBlock		; needs   bx = VM file handle
		tst	ax			; returns ax = VM block handle
		jz	createNewDirInfoFile
		call	VMLock			; needs bx:ax = 
						;	(VM file):(VM block) 
		mov	ds, ax
		cmp	ds:[DIFH_protocol],DIRINFO_PROTOCOL_NUM
		jne	createNewChunkArray	; rewrite old dirinfo.vm
		mov	si, ds:[DIFH_posArray]
		call	ChunkArrayZero
exit:
		pop	bx
error:
		.leave
		ret			; <--- EXIT HERE

createNewDirInfoFile:

	;
	; Mark the file as hidden -- internally to GEOS
	;
		push	bx
		mov	dx, bx		; file handle
		clr	bx
		mov	ds, bx
		mov	ax, mask GFHF_HIDDEN
		call	ShellSetFileHeaderFlags
		pop	bx

		mov	ax, LMEM_TYPE_GENERAL
		mov	cx, size DirInfoFileHeader
		call	VMAllocLMem		; ax = VM block handle
		call	VMSetMapBlock
		call	VMLock
		mov	ds, ax

createNewChunkArray:
		clr	ax, cx, si
		mov	bx, size DirInfoFileEntry 	; element size
		call	ChunkArrayCreate	; *ds:si = array
		mov	ds:[DIFH_posArray], si	; save handle to array
		mov	ds:[DIFH_protocol], DIRINFO_PROTOCOL_NUM
		movdw	ds:[DIFH_displayOptions], 0
		jmp	exit

ShellCreateDirInfo	endp



COMMENT @-------------------------------------------------------------------
			ShellOpenDirInfoRW
----------------------------------------------------------------------------

DESCRIPTION:	Opens the Directory Information file read only.

CALLED BY:	GLOBAL - FolderLoadDirInfo

PASS:		ds:dx	= name of dirinfo file to open

RETURN:	IF ALL GOES WELL:
		zero flag clear
		carry clear

		*ds:si	= locked dirinfo chunk array 
		bx	= VM file handle
		bp	= memory handle of locked VM block

	IF DIRINFO FILE OLD, OR DOESN'T EXIST:
		zero flag set
		carry set

	ELSE ERROR OCCURED:
		zero flag clear
		carry set
		ax	= VMStatus

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	To deal with the return values of this routine:
		call	ShellOpenDirInfoLow
		jz	noDirInfo
	`	jc	error

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/22/92	Initial version

---------------------------------------------------------------------------@
ShellOpenDirInfoRW	proc	far

		mov	ax, (VMO_OPEN shl 8) + (mask VMAF_FORCE_READ_WRITE)
		GOTO	ShellOpenDirInfoLow

ShellOpenDirInfoRW	endp



COMMENT @-------------------------------------------------------------------
			ShellOpenDirInfo
----------------------------------------------------------------------------

DESCRIPTION:	Opens the Directory Information file read only.

CALLED BY:	GLOBAL - FolderLoadDirInfo

PASS:		ds:dx	= name of dirinfo file to open

RETURN:		if error
			carry set
			ax = VMStatus
		else
			carry clear
			*ds:si	= locked dirinfo chunk array 
			bx	= VM file handle
			bp	= memory handle of locked VM block

DESTROYED:	ax


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/22/92	Initial version

---------------------------------------------------------------------------@
ShellOpenDirInfo	proc	far

		mov	ax, (VMO_OPEN shl 8) + (mask VMAF_FORCE_READ_ONLY) \
				+ (mask VMAF_FORCE_DENY_WRITE)
		FALL_THRU	ShellOpenDirInfoLow

ShellOpenDirInfo	endp



COMMENT @-------------------------------------------------------------------
			ShellOpenDirInfoLow
----------------------------------------------------------------------------

DESCRIPTION:	Opens the Directory Information file, and handles errors.

CALLED BY:	GLOBAL - FolderLoadDirInfo

PASS:		ds:dx	= name of dirinfo file to open
		al 	= VMAccessFlags
		ah	= VMOpenType

RETURN:	IF ALL GOES WELL:
		zero flag clear
		carry clear

		*ds:si	= locked dirinfo chunk array 
		bx	= VM file handle
		bp	= memory handle of locked VM block

	IF DIRINFO FILE OLD, OR DOESN'T EXIST:
		zero flag set
		carry set

	ELSE ERROR OCCURED:
		zero flag clear
		carry set
		ax	= VMStatus

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	To deal with the return values of this routine:
		call	ShellOpenDirInfoLow
		jz	noDirInfo
	`	jc	error


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/9/92		Initial version

---------------------------------------------------------------------------@
ShellOpenDirInfoLow	proc	far
		uses	cx
		.enter

if ERROR_CHECK
	;
	; Validate that the filename is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, ds						>
FXIP<		mov	si, dx						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif
	;
	; open the dirinfo file!
	;
		clr	cx			; use default compression
		call	VMOpen
		jc	error
	;
	; lock down the block of information
	;
		call	VMGetMapBlock		; pass bx = VM file handle
		call	VMLock
		mov	ds, ax			; ds = locked
						; dirinfo.vm block
	;
	; Check that this isn't some old or corrupt dirinfo file.
	; Set zero flag if dirinfo protocol numbers don't match.
	;
		cmp	ds:[DIFH_protocol], DIRINFO_PROTOCOL_NUM
		jne	oldDirInfo

		mov	si, ds:[DIFH_posArray]	; *ds:si = chunk array
EC <		call	ECCheckDirInfo				>

done:
		.leave
		ret

oldDirInfo:
		call	ShellCloseDirInfo
		jc	done
error:
		cmp	ax, VM_FILE_NOT_FOUND	; ZF = set if not found
		stc
		jmp 	done

ShellOpenDirInfoLow	endp




COMMENT @-------------------------------------------------------------------
			ShellCloseDirInfo
----------------------------------------------------------------------------

DESCRIPTION:	Closes dirinfo file, and handles errors

CALLED BY:	GLOBAL - FolderLoadDirInfo,
			 FolderSaveDirInfo

PASS:		bx	= VM file handle
		bp	= memory handle of locked VM block

RETURN:		carry - set if error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/9/92		Initial version

---------------------------------------------------------------------------@
ShellCloseDirInfo	proc	far	uses ax
	.enter
	call	VMUnlock
	mov	al, FILE_NO_ERRORS
	call	VMClose
	.leave
	ret
ShellCloseDirInfo	endp



COMMENT @-------------------------------------------------------------------
			ShellSearchDirInfo
----------------------------------------------------------------------------

DESCRIPTION:	Search the given dirinfo file for the given file.

CALLED BY:	GLOBAL

PASS:		*ds:si	= dirinfo chunk array
		cx:dx  - FileID to find

RETURN:		IF FOUND:
			carry clear
			(cx, dx) - position
			al - DirInfoFileEntryFlags
		ELSE:
			carry set

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/9/92		Initial version
	chrisb	3/93		rewrote

---------------------------------------------------------------------------@
ShellSearchDirInfo	proc	far
	uses	di, bx
	.enter

	mov	bx, cs
	mov	di, offset ShellSearchDirInfoCB
	call	ChunkArrayEnum
	cmc				; return carry CLEAR if found

	.leave
	ret
ShellSearchDirInfo	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellSearchDirInfoCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to find the file

CALLED BY:	ShellSearchDirInfo via ChunkArrayEnum

PASS:		cx:dx - FileID to find
		ds:di - DirInfoFileEntry to compare against

RETURN:		if found:
			carry SET
			(cx, dx) - position
			al - DirInfoFileEntryFlags
		else:
			carry CLEAR

DESTROYED:	bx,cx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/10/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShellSearchDirInfoCB	proc far

		.enter

		cmpdw	cxdx, ds:[di].DIFE_fileID
		je	found
		clc
done:
		.leave
		ret

found:
	;
	; It matches!  return the position
	;
		mov	cx, ds:[di].DIFE_position.P_x
		mov	dx, ds:[di].DIFE_position.P_y
		mov	al, ds:[di].DIFE_flags
		stc
		jmp	done

ShellSearchDirInfoCB	endp





COMMENT @-------------------------------------------------------------------
			ShellSetPosition
----------------------------------------------------------------------------

DESCRIPTION:	Sets the position of the given file.

CALLED BY:	GLOBAL

PASS:		ds:dx	= name of dirinfo file
		es:di	= FileLongName of file to set position of
		(cx,dx) = position

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
*** NOT TESTED ***

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/9/92		Initial version

---------------------------------------------------------------------------@
ShellSetPosition	proc	far
	;
	; Don't use this procedure, it doesn't work.
	;
		ERROR -1
if 0
		uses	ax, bx, dx, di, si, bp, ds
		.enter

	;
	; Open @dirinfo file.
	;
		call	ShellOpenDirInfoRW
		jc	done
		push	ds
	;
	; Search for given filename
	;
		mov	dx, di
		clr	ax
		call	ShellSearchDirInfo
		jc	fillEntry
	;
	; If not found, create new element in proper place, and copy
	; over the filename.
	;
		xchg	dx, di
		call	LocalStringSize
		mov	ax, size DirInfoFileEntry
		add	ax, cx
		xchg	dx, di
		call	ChunkArrayInsertAt
		push	di, si
		lea	si, ds:[di].DIFE_fileID
		mov	di, dx
		LocalCopyString
		pop	di, si
fillEntry:
	;
	; Now fill the element with the proper information
	;
		movdw	ds:[di], cxdx
		call	ShellCloseDirInfo
done:
		.leave
		ret
endif
		
ShellSetPosition	endp



COMMENT @-------------------------------------------------------------------
			ShellGetPosition
----------------------------------------------------------------------------

DESCRIPTION:	Returns the position of the given file.

CALLED BY:	GLOBAL

PASS:		ds:dx	= name of dirinfo file
		es:di	= FileLongName of file to set position of

RETURN:		IF FOUND:
			carry clear
			(cx,dx) = position
		ELSE:
			carry set

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
*** NOT TESTED ***

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/9/92		Initial version

---------------------------------------------------------------------------@
ShellGetPosition	proc	far
		

	;
	; Don't use this procedure, it doesn't work.
	;
		ERROR -1

if 0
		.enter
	;
	; Open @dirinfo file.
	;
		call	ShellOpenDirInfo
		jc	done
		push	ds
	;
	; Search for given filename
	;
		mov	dx, di
		clr	ax
		call	ShellSearchDirInfo
		jc	notFound
	;
	; Get position.
	;
		movdw	cxdx, ds:[di].DIFE_position
notFound:
		pushf
		call	ShellCloseDirInfo
		popf
done:
		.leave	
		ret
endif
ShellGetPosition	endp




