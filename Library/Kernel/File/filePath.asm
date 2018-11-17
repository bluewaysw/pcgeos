COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File -- Path manipulation
FILE:		filePath.asm

AUTHOR:		Adam de Boor, Mar 19, 1990

ROUTINES:
	Name			Description
	----			-----------
    GLB FileGetCurrentPath	Get the current directory. If the directory
				is a standard path, the "disk handle"
				returned will be a StandardPath constant
				and the buffer will be a relative path.  If
				you need the full path, including drive
				specifier, call FileConstructFullPath,
				passing dx non-zero and bp = -1.

    GLB FileGetCurrentPathIDs	Return an array of FilePathID structures
				for the current path, for use in handling
				file-change notification messages.

    GLB FP_LoadVarSegDS		Load kdata into DS

    GLB Int_GetCurrentPath	Get the current directory.  Internal
				version of FileGetCurrentPath.

    GLB FileConstructFullPath	Construct a full path given a standard path
				constant and a path relative to it

    INT CopyNTStringCXMaxPointAtNull Copy a null-terminated string leaving
				the dest pointer pointing to the null.

    INT CopyNTStringCXMaxCompressPointAtNull Copy the null-terminated
				string from ds:si to es:di, compressing out
				. and .. components and dealing with an
				absolute source path, so long as the
				leading path components already in the
				buffer don't come from a StandardPath.

    INT CopyStandardPathComponents Copy a standard path into a buffer

    GLB FileSetCurrentPath	Set the current directory.

    INT CheckPathAbsolute	See if the passed path is absolute.

    INT FileParseStandardPathIfPathsEnabled Similar to
				FileParseStandardPath, but only returns a
				standard path if KLV_stdDirPaths is
				non-zero, so InitForPathEnum won't choke.

    GLB FileParseStandardPath	Construct the best combination of a
				StandardPath constant and a path. NOTE: if
				the filesystem on which our top level
				resides is case-insensitive, the passed
				path must be in all upper-case for it to be
				properly recognized. The best way to ensure
				this is to push to the directory in
				question and call FileGetCurrentPath,
				remembering to stick the drive specifier at
				the beginning of...to be continued..

    INT StdPathPointAtNthChild	Find the Nth child of a standard path

    GLB FILEPUSHDIR		Push the current directory onto the
				thread's directory stack. The current
				directory isn't changed, but this allows
				FileSetCurrentPath to be called with
				impunity, as the previous directory can be
				recovered by executing a FilePopDir

    GLB FILEPOPDIR		Pop a directory from the thread's directory
				stack

    GLB FileSetStandardPath	change to one of the standard system
				directories

    INT FileAllocPath		Allocate and initialize a new FilePath
				block

    INT FileSetInitialPath	Set the initial path block for the kernel
				scheduler thread.

    INT FileCopyPath		Make a copy of a path block

    INT SetCurPath		Ask the appropriate FSD to set the thread's
				current working directory.

    INT SetCurPathUsingStdPath	Set the thread's current directory to the
				passed standard path.

    INT InitForPathEnum		Initialize variables for enumerating paths

    INT SetDirOnPath		Set the physical current path to be the
				next directory on the path for the logical
				path. InitForPathEnum must have been called
				before this.

    INT FP_CurPathLockDS	Various locking routines, here to save
				bytes. The routines with "Path" in their
				names *must* be used for the locking of
				paths only

    INT FP_PathLockDS		Various locking routines, here to save
				bytes. The routines with "Path" in their
				names *must* be used for the locking of
				paths only

    INT FP_MemLockDS		Various locking routines, here to save
				bytes. The routines with "Path" in their
				names *must* be used for the locking of
				paths only

    INT FileLockPath		Lock down a path without causing ec-only
				deadlocks.

    INT FileUnlockPath		Unlock a path without causing ec-only
				deadlocks.

    INT Int_SetDirOnPath	Set the thread's current path to be the
				next directory on the path for the logical
				path

    INT FindNextPathEntry	Find the next path entry in the paths block

    INT BuildPathEntry		Construct the full path and set it

    INT FinishWithPathEnum	Called after completion of path enumeration

    INT FileEnsureLocalPath	Take the passed destination name as a file
				or directory that will be created and, if
				it's within a standard path (*not* a
				subdirectory of a standard path), make sure
				that the appropriate directories exist in
				the local tree under SP_TOP.

    INT FileCreateLocalStdPath	Create the local version of a standard
				path.

    INT FileChangeDirectory	Change to the given directory, changing the
				drive if necessary. This is allowed to use
				int 21h as it won't be used while a DOS
				executive might be running.

    INT FileDeletePath		Delete a path block, making sure pathHandle
				doesn't point to it.

    INT FileDeletePathStack	Delete all the saved paths for the current
				thread, along with the thread's current
				path.

    GLB FileForEachPath		Iterate over all active paths (the current
				directories and any directory stack entries
				for all existing threads).

    INT FFEP_callback		Callback function for FilePathProcess via
				ThreadProcess. Performs all the actual work
				of the traversal...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/19/90		Initial revision


DESCRIPTION:
	Functions for tracking and manipulating FilePaths structures in the
	kernel.

Handling of paths for standard directories:

The loader builds a structure...

	$Id: filePath.asm,v 1.4 98/05/02 22:26:32 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileChangeDirectory

DESCRIPTION:	Change to the given directory, changing the drive if necessary.
		This is allowed to use int 21h as it won't be used while
		a DOS executive might be running.

CALLED BY:	INTERNAL (InitPaths, RunDOSProg_OSExited)

PASS:		ds:bx - pathname (GEOS)

RETURN:		carry clear if successful
		else ax = error code

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/89		Initial version

-------------------------------------------------------------------------------@
FileChangeDirectory	proc	far
SBCS <	uses dx								>
DBCS <	uses dx, es, di, si						>
	.enter
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx,si						>
EC <	mov	si, bx						>
EC <	mov	bx, ds						>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx,si						>
endif

if DBCS_PCGEOS
PrintMessage <any way to keep this string in DOS at boot time?>
	;
	; The FSD has gone the way of the dodo by now, so convert the
	; string from GEOS to DOS as best we can.
	;
	segmov	es, ds
	mov	di, bx			;es:di <- ptr to dest
	mov	si, bx			;ds:si <- ptr to source
charLoop:
	lodsw
EC <	cmp	ax, 0x80						>
EC <	ERROR_AE	UNCONVERTABLE_DOS_CHARACTER_FOR_BOOT		>
	stosb
	tst	al			;reached NULL?
	jnz	charLoop
endif
	mov	dx, ds:[bx]		;dl <- drive letter
	cmp	dh, ':'			;drive present?
	jne	20$			;branch if not

	sub	dl, 'a'			; assume lower-case
	jge	10$
	add	dl, 'a' - 'A'		; whoops. Adjust b/c it was uppercase
10$:
	mov	ah, MSDOS_SET_DEFAULT_DRIVE
	int	21h
20$:
	mov	dx, bx
	mov	ah, MSDOS_SET_CURRENT_DIR
	int	21h
	.leave
	ret
FileChangeDirectory	endp

;---------------------------------------------------------------------

FileCommon	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	FileGetCurrentPath

DESCRIPTION:	Get the current directory. If the directory is a standard
		path, the "disk handle" returned will be a StandardPath
		constant and the buffer will be a relative path.
		
		If you need the full path, including drive specifier, call
		FileConstructFullPath, passing dx non-zero and bp = -1.

CALLED BY:	GLOBAL

PASS: 		ds:si - buffer for path
		cx - size of buffer (may be zero)

RETURN:		bx - disk handle

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

		Return the LOGICAL disk and path

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	2/90		Added disk handles
	CDB	8/19/92		Modified for new path block format
------------------------------------------------------------------------------@

FileGetCurrentPath	proc	far	

	uses ax, cx, si, di, ds, es, bp

	.enter

	segmov	es, ds				;es:di = dest
	mov	di, si

	call	FP_CurPathLockDS
	mov	bp, ds:[FP_logicalDisk]		; bp = disk handle

	jcxz	done

	mov	si, ds:[FP_path]
;	mov	al, '\\'	; return path as absolute w.r.t. to the S.P.
;	stosb
;	dec	cx
	call	CopyNTStringCXMaxPointAtNull

done:
	call	FileUnlockPath
	mov	bx, bp

	.leave
	ret

FileGetCurrentPath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FP_LoadVarSegDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Byte-saver to load dgroup into DS

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		ds	= dgroup
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FP_LoadVarSegDS	proc	near
	LoadVarSeg	ds
	ret
FP_LoadVarSegDS	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	Int_GetCurrentPath

DESCRIPTION:	Get the current directory.  Internal version of
		FileGetCurrentPath.

CALLED BY:	GLOBAL

PASS: 		dx - non-zero to add drive specifier
 		bx - path handle
		si - disk handle (StandardPath if current is standard path)
		es:di - buffer for path
		cx - size of buffer (may be zero)

RETURN:		es:di - pointing at null
		cx - buffer size left
		bx - real disk handle

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	2/90		Added disk handles
-------------------------------------------------------------------------------@
Int_GetCurrentPath	proc	near	uses si, bp, ds
	.enter
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx,si							>
EC<	movdw	bxsi, esdi						>
EC<	call	ECAssertValidTrueFarPointerXIP				>
EC<	pop	bx,si							>
endif
	;
	; Lock down the thread's current path
	;
	call	FP_PathLockDS

	push	bx
	mov	bx, si			; bx <- disk handle/std path
EC <	tst	bx							>
EC <	ERROR_Z	GASP_CHOKE_WHEEZE	; prevent endless loop		>
	mov	si, ds:[FP_path]
	call	FileConstructFullPath
	mov	si, bx			; save real disk handle
	pop	bx
	
	;
	; Unlock the path
	;
	call	FileUnlockPath

	mov	bx, si			; return real disk handle

	.leave
	ret
Int_GetCurrentPath	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileConstructFullPath

DESCRIPTION:	Construct a full path given a standard path constant and
		a path relative to it

CALLED BY:	GLOBAL

PASS: 		dx - non-zero to add <drive-name>:
		bx - disk handle:
		  0: 	   	passed path is either relative to the
			   	current working directory, or an absolute
			   	path with drive specifier

		  StandardPath	prepend logical path for the
				standard path, returning top-level
				disk handle

		  disk handle	ds:si is absolute; disk handle used
				only if dx is non-zero

		ds:si - tail of path being constructed (must be absolute if
			bx is non-zero and not a StandardPath constant)

 		es:di - buffer for path
		cx - size of buffer

RETURN:		carry set on error:
			- path too long to fit in buffer
			- invalid drive name given
		carry clear if OK:
			es:di - points at null
			bx - disk handle (if drive name not returned)

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/91		Initial version
------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileConstructFullPath		proc	far
	mov	ss:[TPD_dataBX], handle FileConstructFullPathReal
	mov	ss:[TPD_dataAX], offset FileConstructFullPathReal
	GOTO	SysCallMovableXIPWithDSSI
FileConstructFullPath		endp
CopyStackCodeXIP		ends

else
FileConstructFullPath		proc	far
	FALL_THRU	FileConstructFullPathReal
FileConstructFullPath		endp
endif

FileConstructFullPathReal	proc	far	

	uses 	ax, cx, dx, si

bufStart 	local	word 		push	di
stdPath		local	StandardPath 	push	bx
drive		local	nptr.DriveStatusEntry
pathTail	local	nptr.char
stdPathEnd	local	word
	.enter
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx,si							>
EC<	movdw	bxsi, esdi						>
EC<	call	ECAssertValidTrueFarPointerXIP				>
EC<	pop	bx,si							>
endif
	;
	; See if a drive was specified as part of the passed path.  If
	; so, save the path tail and DriveStatusEntry for later
	;
	push	es, si, dx
	call	FSDLockInfoShared
	mov	es, ax
	mov	dx, si
	call	DriveLocateByName
	jnc	storeDrive

	;
	; If carry set, then a drive WAS specified -- it just doesn't
	; match any existing drives.  Store a nonzero value here.
	;

	LocalNextChar	dssi
storeDrive:
	mov	drive, si
	mov	pathTail, dx
	call	FSDUnlockInfoShared
	pop	es, si, dx
	
	;
	; See if caller wants us to prepend the current path
	;

	tst	bx
	jnz	notCurrentPath
	
	;
	; Don't prepend the current path if the passed
	; path contains a drive specifier.
	;

	tst	ss:[drive]
	jnz	notCurrentPath

	;------------------------------------------------------------
	;
	; MODE 1: TOLD TO PREPEND CURRENT PATH.
	;
	; Recurse (effectively) by calling Int_GetCurrentPath to copy
	; the current path into the buffer.
	; 
	push	si, ds

	call	FP_CurPathLockDS	; fetch FP_stdPath from the block
	mov	si, ds:[FP_stdPath]	;  to deal with being in a std path
	mov	ss:[stdPath], si	;  if FP_stdPath is a standard path,
					;  we'll later ignore if tail is
					;  absolute...
	mov	si, ds:[FP_logicalDisk]
	call	MemUnlock

	mov	ax, di		; preserve buffer start so we can find how
				;  many bytes were consumed.
	call	Int_GetCurrentPath

	sub	ax, di
	add	cx, ax		; cx <- bytes left in the buffer, excluding null
DBCS <	shr	cx, 1		; cx <- # chars				>

	tst	dx		; any drive specifier we must skip over to
				;  find the actual buffer start?
	jz	cpBufStartOK	; no

	mov	si, ss:[bufStart]
cpFindDriveLoop:
SBCS <	lodsb	es:							>
DBCS <	lodsw	es:							>
	LocalCmpChar	ax, C_BACKSLASH
	jne	cpFindDriveLoop
	LocalPrevChar essi	; point to root
	mov	ss:[bufStart], si
cpBufStartOK:

	;
	; To cope with standard paths, set stdPathEnd to the backslash that
	; follows the standard path itself.
	; 
	test	ss:[stdPath], DISK_IS_STD_PATH_MASK
	jz	cpStdPathHandled

	;
	; Trim off as many chars from di as there are in the path tail in the
	; current path block.
	; 
	push	bx
	call	FP_CurPathLockDS
	mov	si, ds:[FP_path]
SBCS <	lea	dx, [di+1]						>
DBCS <	lea	dx, [di+2]						>
cpStdPathLoop:
	LocalPrevChar	dsdx
	LocalGetChar ax, dssi
	LocalIsNull ax
	jnz	cpStdPathLoop
	call	MemUnlock
	pop	bx
	;
	; two cases here: (1) no tail under the std path, in which case
	; es:dx is where the backslash is going to go; es:[dx] is then the
	; null byte copied in by Int_GetCurrentPath. (2) tail under the
	; std path, in which case es:[dx] is the first char of the first
	; component under the std path, but we need it to be the backslash
	; just before that, so we have to dec dx again.
	; 
	mov 	si, dx
SBCS <	cmp 	{char}es:[si], 0					>
DBCS <	cmp 	{wchar}es:[si], 0					>
	je	cpSetStdPathEnd
	LocalPrevChar	dsdx
cpSetStdPathEnd:
	mov	ss:[stdPathEnd], dx
	
cpStdPathHandled:
	pop	si, ds
	jmp	addSeparatorToLeadingPath

notCurrentPath:
	test	bx, DISK_IS_STD_PATH_MASK
	jz	noStdPath

	;------------------------------------------------------------
	;
	; MODE 2: PREPEND LOGICAL PATH OF PASSED STANDARD PATH
	; 
	; copy in top level path

	push	si, ds
	call	FP_LoadVarSegDS
		; XXX: this code assumes the top-level's drive is always a
		; single letter, which is true when running under DOS, but
		; may not always be true...

SBCS <	mov	si, offset loaderVars.KLV_topLevelPath+2	; assume no >
DBCS <	mov	si, offset loaderVars.KLV_topLevelPath+4	; assume no >
								;  drive spec
	tst	dx		; include drive specifier?
	jz	topLevelCopy	; no
SBCS <	dec	si			; no -- this is always two characters..>
SBCS <	dec	si							>
DBCS <	sub	si, (size wchar)*2	; no -- this is always two characters..>

topLevelCopy:
	call	CopyNTStringCXMaxPointAtNull
	pop	si, ds
	jcxz	fittethNot

	; copy in all components of the standard path

	push	bp, ds
	mov	bp, bx			; bp <- std path
	mov	bx, handle StandardPathStrings
	call	FP_MemLockDS
	push	si
	mov	ax, SP_TOP			;where to stop
	call	CopyStandardPathComponents	;recursively copy them...
	pop	si
	call	MemUnlock

	call	FP_LoadVarSegDS
	mov	bx, ds:[topLevelDiskHandle]	; return top-level disk
						;  handle to caller

	pop	bp, ds
	jcxz	fittethNot
	mov	ss:[stdPathEnd], di	; point to backslash that
					;  follows to deal with absolute.

addSeparatorToLeadingPath:
	;
	; Make sure there's a separator between the current path and the
	; tail, so CopyNTStringCXMaxCompressPointAtNull won't bitch.
	; 
	LocalPrevChar	esdi	; point before null
	LocalLoadChar	ax, C_BACKSLASH
SBCS <	scasb			; backslash there?			>
DBCS <	scasw			; backslash there?			>
	jz	copyTail
	LocalPutChar esdi, ax		; no -- add one
	loop	copyTail
	
	; trailing backslash has used up last char. If there is nothing to
	; add, this is ok. Just go to copyTail, which will trim the final
	; backslash.

	LocalCmpChar	ds:[si], C_NULL
	jz	copyTail
SBCS <	cmp	{word} ds:[si], C_BACKSLASH or (0 shl 8) ; ditto for root tail >
DBCS <	LocalCmpChar	ds:[si], C_BACKSLASH				>
DBCS <	jne	fittethNot						>
DBCS <	LocalCmpChar	ds:[si][2], C_NULL				>
	je	copyTail

fittethNot:
	stc			; flag path incomplete
	jmp	done


	;------------------------------------------------------------
	;
	; MODE 3: PREPEND ROOT OF PASSED DISK HANDLE
	; 

noStdPath:

	; if the passed path contains a drive specifier, ignore the
	; disk handle, copying in the drive specifier, along with the
	; rest of the tail, if the caller requested it.

	tst	ss:[drive]
	jz	noDriveSpecified


	;
	; If the caller wants a drive specifier, then just return the
	; passed path, as it already contains one.  We WILL NOT return
	; the disk handle, since we're assuming the caller doesn't
	; need it.
	;

	tst	dx		; want drive spec?
	jnz	copyPassedPath

	;
	; Otherwise, return the disk handle from the passed drive
	; specifier, and copy the tail into the buffer (Will
	; return error if the drive isn't available, etc)
	;

	mov	dx, si
	mov	bx, TRUE		; don't check std path
	call	FileGetDestinationDisk
	jc	done			; disk handle could not be found.
	mov	si, dx			; path tail w/o drive spec

copyPassedPath:

	;
	; Copy it in, assuming it's already compressed
	;

	call	CopyNTStringCXMaxPointAtNull	
	jcxz	fittethNot
	jmp	done

noDriveSpecified:

	;
	; The passed path didn't contain a drive specifier.  If the
	; caller doesn't want a drive spec, then just copy the path
	;

	tst	dx
	jz	addTrailingBS

	;
	; Otherwise, get a drive name from the passed disk handle
	;

	call	DiskGetDrive
	call	DriveGetName
	jcxz	fittethNot
EC <	ERROR_C	BAD_DISK_HANDLE						>
	LocalLoadChar	ax, ':'
	LocalPutChar esdi, ax
	dec	cx
	jz	fittethNot
	
	mov	ss:[bufStart], di	; Record root backslash as start of buf
addTrailingBS:
	LocalLoadChar	ax, C_BACKSLASH
	LocalPutChar esdi, ax
	dec	cx
	jz	fittethNot

copyTail:
	; copy the path tail (or the entire path, in some cases) taking care
	; to eliminate . and .. components

	call	CopyNTStringCXMaxCompressPointAtNull
	jcxz	fittethNot
done:
	.leave
	ret

FileConstructFullPathReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyNTStringCXMaxPointAtNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a null-terminated string leaving the dest pointer
		pointing to the null.

CALLED BY:	FileConstructFullPath and others
PASS:		ds:si	= source null-terminated string
		es:di	= destination buffer
		cx	= # chars in the buffer
RETURN:		es:di	= pointing to null, if it all fit
		cx	= # chars remaining, including the null (if 0, then
			  source string didn't fit)
DESTROYED:	al, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	5/ ?/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyNTStringCXMaxPointAtNull	proc	near

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx						>
EC<	mov	bx, ds						>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx						>
endif

10$:
	LocalGetChar ax, dssi
	LocalPutChar esdi, ax
	LocalIsNull	ax
	loopne	10$

	jne	done
	LocalPrevChar esdi	; point at null
	inc	cx		; and flag another char avail
done:
	ret

CopyNTStringCXMaxPointAtNull	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyNTStringCXMaxCompressPointAtNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the null-terminated string from ds:si to es:di,
		compressing out . and .. components and dealing with an
		absolute source path, so long as the leading path components
		already in the buffer don't come from a StandardPath.

CALLED BY:	FileConstructFullPath
PASS:		ds:si	= source null-t string
		es:di	= dest buffer
		cx	= # chars avail
		ss:bp	= stack frame inherited from FileConstructFullPath
		 	(bufStart is beginning of the buffer into which es:di
			points so we know if .. component is excessive, and
			so we can deal with absolute tail)
RETURN:		es:di	= null terminator
		cx	= # chars left, including null (0 if buffer too small)
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		in a nutshell, we wish to copy the source string to the
		destination string keeping a lookout for "." and ".." components
		in the source string. Should we find a "." component, we
		delete it from the destination. Should we find a ".." component,
		we delete it and the previous component, even if it was in
		the buffer before we were called.
		
		simple state machine:
			base
			just copied backslash (dx holds position)
			saw . after backslash
			saw .. after backslash

		; assume char just before us is a backslash
	  	state = copied backslash (dx = (di==bufStart ? di : di-1))
		while ((al = ds:si++) != 0) {
		    if (al == '.') {
		    	if (state == saw .) {
			    ; remember ".." seen in case it's the whole thing
			    state = saw ..
			} else if (state == copied backslash) {
			    ; remember "." seen at start in case it's ".." or
			    ; just "." in this component
			    state = saw .
			}
			*es:di++ = al
		    } else if (al == '\\') {
			if (state == saw .) {
			    cx += (di - (dx+1))
			    di = dx+1
			} else if (state == saw ..) {
			    if (dx != bufStart) {
			        find \ before dx and set dx to it
			    }
			    cx += (di - (dx+1))
			    di = dx+1
			} else {
			    dx = di
			    *es:di++ = al
			}
		    } else {
		        state = base
			*es:di++ = al
		    }
		    if (--cx == 0) {
			break
		    }
		}
		if (cx != 0) {
		    if (state == saw .) {
			; drop final component if it's "."
			di = dx
		    } else if (state == saw ..) {
			; drop final component and the one before it if
			; last was ".."
			if (dx != bufStart) {
			    dx = \ before dx
			}
			di = dx
		    } else if (state == copied backslash) {
		        di = dx
		    }
		    if (di == buf start) {
			; preserve backslash if it's the only thing here
		        di++, cx--
		    }
		    *es:di = al
		}


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	It's possible to overflow the buffer, owing to ".." stuff, even
	though the end result, once ".."s have been taken into account, would
	fit into the buffer just fine.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CNTSCXMCPANStates	etype	byte
    CNTSCXMCPANS_BASE			enum	CNTSCXMCPANStates
    CNTSCXMCPANS_SAWDOT			enum	CNTSCXMCPANStates
    CNTSCXMCPANS_SAWDOTDOT		enum	CNTSCXMCPANStates
    CNTSCXMCPANS_LAST_WAS_BACKSLASH	enum	CNTSCXMCPANStates

CopyNTStringCXMaxCompressPointAtNull proc near
		uses	bx, dx
		.enter	inherit FileConstructFullPathReal
if FULL_EXECUTE_IN_PLACE
EC<	push	bx						>
EC<	mov	bx,ds						>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx						>
endif


	;
	; Deal with source string being absolute. If stdPath indicates the
	; thing was preceded by a standard path, the absolute path means
	; nothing. Otherwise, we shift our destination focus back to the
	; start of the buffer (this for FCFP with bx==0 on a non-std path).
	; 
		LocalCmpChar ds:[si], C_BACKSLASH
		jne	startCopy
		mov	di, ss:[stdPathEnd]
		test	ss:[stdPath], DISK_IS_STD_PATH_MASK
		jnz	skipLeadingSourceSlash
		mov	di, ss:[bufStart]
skipLeadingSourceSlash:
		LocalNextChar	esdi	; start after backslash
		LocalNextChar	dssi
startCopy:
	;
	; Set up for the loop, entering the "LAST_WAS_BACKSLASH" state to
	; begin with, as es:[di-1] must be a backslash.
	; 
SBCS <		mov	ah, CNTSCXMCPANS_LAST_WAS_BACKSLASH		>
DBCS <		mov	bl, CNTSCXMCPANS_LAST_WAS_BACKSLASH		>
SBCS <		lea	dx, [di-1]	; assume our storage point is preceded >
DBCS <		lea	dx, [di-2]	; assume our storage point is preceded >
					;  by a backslash...

EC < DBCS <		cmp	{wchar}es:[di-2], C_BACKSLASH		>>
EC < SBCS <		cmp	{char}es:[di-1], C_BACKSLASH		>>
EC <		ERROR_NE FILE_CONSTRUCTED_PATH_DOESNT_END_IN_BACKSLASH	>
	;
	; In no case do we go back before bufStart when compressing out ..,
	; however...
	; 
		cmp	dx, ss:[bufStart]
		jae	copyLoop
		mov	dx, ss:[bufStart]
copyLoop:
		LocalGetChar	ax, dssi
	;
	; Deal with '.' first...
	; 
		LocalCmpChar	ax, '.'
		jne	checkBackslash
DBCS <		cmp	bl, CNTSCXMCPANS_SAWDOT				>
SBCS <		cmp	ah, CNTSCXMCPANS_SAWDOT				>
		jne	checkCompStart
	    ;
	    ; this is the second . after a \. so switch to that state and
	    ; store the char.
	    ; 
DBCS <		mov	bl, CNTSCXMCPANS_SAWDOTDOT			>
SBCS <		mov	ah, CNTSCXMCPANS_SAWDOTDOT			>
		jmp	storeItBabe

checkCompStart:
	    ;
	    ; Have a dot not after "." but perhaps it's after a b.s.?
	    ; 
DBCS <		cmp	bl, CNTSCXMCPANS_LAST_WAS_BACKSLASH		>
SBCS <		cmp	ah, CNTSCXMCPANS_LAST_WAS_BACKSLASH		>
		jne	switchToBaseAndStoreItBabe
	    ;
	    ; Right. it is a dot after a b.s., so flag this for possible
	    ; compression and go store the dot.
	    ; 
DBCS <		mov	bl, CNTSCXMCPANS_SAWDOT				>
SBCS <		mov	ah, CNTSCXMCPANS_SAWDOT				>
		jmp	storeItBabe

checkBackslash:
	;
	; Char isn't a '.' but perhaps it's a backslash, which is equally
	; significant.
	; 
		LocalCmpChar	ax, C_BACKSLASH
		jne	checkNull
		
	    ;
	    ; End of a component. Need to do some things here:
	    ; 	- if component just ended was ".", then delete it; don't
	    ;	  store this backslash
	    ;	- if component just ended was "..", then delete it and the
	    ;	  component immediately before it. again we don't store the
	    ;	  b.s. as it should already be there.
	    ;	- if none of the above, we still need to record the position
	    ;	  at which we'll be storing the b.s. and switch into the
	    ;	  state telling us we just did so.
	    ;
DBCS <		cmp	bl, CNTSCXMCPANS_SAWDOT				>
SBCS <		cmp	ah, CNTSCXMCPANS_SAWDOT				>
		je	backToDX
DBCS <		cmp	bl, CNTSCXMCPANS_SAWDOTDOT			>
SBCS <		cmp	ah, CNTSCXMCPANS_SAWDOTDOT			>
		jne	storeBackslash

		call	findPrevCompStart
backToDX:
SBCS <		stc			; figure # chars we're regaining >
SBCS <		sbb	di, dx		;  (di - (dx + 1))		>
DBCS <		sub	di, dx		;  (di - (dx + 1))		>
DBCS <		shr	di, 1		;				>
DBCS <		dec	di						>
		add	cx, di		; add them back into the total avail
		mov	di, dx		; di <- char past backslash (dx+1)
		LocalNextChar	esdi	; di <- char past backslash (dx+1)
DBCS <		mov	bl, CNTSCXMCPANS_LAST_WAS_BACKSLASH		>
SBCS <		mov	ah, CNTSCXMCPANS_LAST_WAS_BACKSLASH		>
		jmp	copyLoop

storeBackslash:
DBCS <		mov	bl, CNTSCXMCPANS_LAST_WAS_BACKSLASH		>
SBCS <		mov	ah, CNTSCXMCPANS_LAST_WAS_BACKSLASH		>
		mov	dx, di
		jmp	storeItBabe

checkNull:
	;
	; Check for null terminator reached and bail if so.
	; 
		LocalIsNull ax
		je	copyDone

switchToBaseAndStoreItBabe:
	;
	; No special character, so switch to the base state to signal this.
	; 
DBCS <		mov	bl, CNTSCXMCPANS_BASE				>
SBCS <		mov	ah, CNTSCXMCPANS_BASE				>
storeItBabe:
	;
	; Store the char in al, advance di, and loop for more chars if we've
	; not used up the entire buffer.
	; 
		LocalPutChar	esdi, ax
		loop	copyLoop
	;
	; Buffer full, so return cx == 0
	; 
done:
		.leave
		ret

copyDone:
	;
	; Copied the entire source string, now deal with "." and ".." at the
	; end of the string.
	; 
DBCS <		cmp	bl, CNTSCXMCPANS_SAWDOT		; last was "."?	>
SBCS <		cmp	ah, CNTSCXMCPANS_SAWDOT		; last was "."?	>
		je	backToDXStoreNull		; yes -- nuke component
DBCS <		cmp	bl, CNTSCXMCPANS_LAST_WAS_BACKSLASH ; last was empty? >
SBCS <		cmp	ah, CNTSCXMCPANS_LAST_WAS_BACKSLASH ; last was empty? >
		je	nukeTrailingBackslash		; yes
DBCS <		cmp	bl, CNTSCXMCPANS_SAWDOTDOT	; last was ".."? >
SBCS <		cmp	ah, CNTSCXMCPANS_SAWDOTDOT	; last was ".."? >
		jne	storeNull			; no -- just go to store
							;  the null-terminator
		
		call	findPrevCompStart
backToDXStoreNull:
SBCS <		stc			; figure the # bytes we're regaining >
SBCS <		sbb	di, dx		;  di -= dx+1			>
DBCS <		sub	di, dx						>
DBCS <		shr	di, 1		; di <- # of chars		>
DBCS <		dec	di		;  di -= dx+1			>
		add	cx, di		; add them to the available

nukeTrailingBackslash:
		mov	di, dx		; di <- addr of final backslash
		inc	cx		; assume we're nuking it

		cmp	dx, ss:[bufStart]; is it the only char in the buffer?
		je	preserveLastBS	; yes -- preserve it
		
SBCS <		cmp	{char}es:[di-1], ':'; come after drive specifier? >
DBCS <		cmp	{wchar}es:[di-2], ':'; come after drive specifier? >
		jne	storeNull	; no -- nuke it

preserveLastBS:
		LocalNextChar	esdi	; if first BS in the buffer, preserve
		dec	cx		;  it
storeNull:
		LocalPutChar esdi, ax
		LocalPrevChar esdi	; leave pointing to null
		clc			; success!
		jmp	done

	;
	; Internal subroutine to find a backslash before the one whose position
	; is marked by es:dx.
	; Return:
	; 	es:dx	= backslash before last one. if es:dx is actually the
	; 		  start of the buffer, es:dx is returned unchanged (this
	;		  takes care of paths like \..)
	;
findPrevCompStart:
		push	cx
		mov	cx, dx
		sub	cx, ss:[bufStart]; cx <- distance from last
					;  b.s. to start of the buffer.
		je	fPCSDone
		
		push	ax, di
		mov	di, dx
		LocalPrevChar esdi	; es:di <- char before last backslash
		std			; scan backwards, of course
		LocalLoadChar ax, C_BACKSLASH
SBCS <		repne	scasb						>
DBCS <		repne	scasw						>
EC <		ERROR_NE	PATH_IN_BUFFER_NOT_ABSOLUTE		>
SBCS <		lea	dx, [di+1]	; dx <- address of found b.s.	>
DBCS <		lea	dx, [di+2]	; dx <- address of found b.s.	>
		cld			; must reset this or death will come...
		pop	ax, di
fPCSDone:
		pop	cx
		retn
CopyNTStringCXMaxCompressPointAtNull endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetStdPathParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the parent directory of a std path

CALLED BY:	CopyStandardPathComponents

PASS:		bx - std path

RETURN:		bx - parent

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetStdPathParent	proc far
	uses	ds, si
	.enter

EC <	cmp	bx, StandardPath	>
EC <	ERROR_AE INVALID_STANDARD_PATH	>

	call	FP_LoadVarSegDS
	mov	si, offset alteredStdPathUpwardTree
	tst	ds:[documentIsTop]
	jnz	gotTree
	mov	si, offset stdPathUpwardTree
gotTree:
	shr	bx
	mov	bl, cs:[si][bx]

EC <	cmp	bx, StandardPath	>
EC <	ERROR_AE INVALID_STANDARD_PATH	>

	.leave
	ret
FileGetStdPathParent	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyStandardPathComponents

DESCRIPTION:	Copy a standard path into a buffer

CALLED BY:	FileConstructFullPath, BuildPathEntry, 

PASS:		ax - StandardPath at which to stop
		bp - StandardPath
		es:di - buffer
		cx - buffer size
		ds - StandardPathStrings

RETURN:
	es:di - pointing at null terminator
	cx - updated (0 if ran out of buffer space)

DESTROYED:
	ds, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	If the docIsTop flag is set, then don't copy anything for
	SP_DOCUMENT

	Recursively call the parent, and then copy our own portion

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@


StdPathUpwardNode	struct
    SPUN_parent		byte		;SP_NOT_STANDARD_PATH if none
StdPathUpwardNode	ends

;Standard Case

stdPathUpwardTree	StdPathUpwardNode	\
	<SP_NOT_STANDARD_PATH>,	;top
	<SP_TOP>,		;world
	<SP_TOP>,		;document
	<SP_TOP>,		;system
	<SP_TOP>,		;privdata
	<SP_PRIVATE_DATA>,	;state
	<SP_USER_DATA>,		;font
	<SP_PRIVATE_DATA>,	;spool
	<SP_SYSTEM>,		;sysappl
	<SP_TOP>,		;userdata
	<SP_SYSTEM>,		;mouse
	<SP_SYSTEM>,		;printer
	<SP_SYSTEM>,		;fs
	<SP_SYSTEM>,		;video
	<SP_SYSTEM>,		;swap
	<SP_SYSTEM>,		;kbd
	<SP_SYSTEM>,		;fontDr
	<SP_SYSTEM>,		;impex
	<SP_SYSTEM>,		;task
	<SP_USER_DATA>,		;help
	<SP_USER_DATA>,		;template
	<SP_SYSTEM>,		;power
	<SP_TOP>,		;dosroom
	<SP_SYSTEM>,		;hwr
	<SP_PRIVATE_DATA>,	;wastebasket
	<SP_USER_DATA>,		;backup
	<SP_SYSTEM>,		;pager
	<SP_SYSTEM>		;component (NewBASIC)


alteredStdPathUpwardTree	StdPathUpwardNode	\
	<SP_NOT_STANDARD_PATH>,	;top
	<SP_TOP>,		;world
	<SP_NOT_STANDARD_PATH>,	;document
	<SP_TOP>,		;system
	<SP_TOP>,		;privdata
	<SP_PRIVATE_DATA>,	;state
	<SP_USER_DATA>,		;font
	<SP_PRIVATE_DATA>,	;spool
	<SP_SYSTEM>,		;sysappl
	<SP_TOP>,		;userdata
	<SP_SYSTEM>,		;mouse
	<SP_SYSTEM>,		;printer
	<SP_SYSTEM>,		;fs
	<SP_SYSTEM>,		;video
	<SP_SYSTEM>,		;swap
	<SP_SYSTEM>,		;kbd
	<SP_SYSTEM>,		;fontDr
	<SP_SYSTEM>,		;impex
	<SP_SYSTEM>,		;task
	<SP_USER_DATA>,		;help
	<SP_USER_DATA>,		;template
	<SP_SYSTEM>,		;power
	<SP_TOP>,		;dosroom
	<SP_SYSTEM>,		;hwr
	<SP_PRIVATE_DATA>,	;wastebasket
	<SP_USER_DATA>,		;backup
	<SP_SYSTEM>,		;pager
	<SP_COMPONENT>		;component (NewBASIC)

CheckHack <length stdPathUpwardTree eq (StandardPath/2)>
CheckHack <length alteredStdPathUpwardTree eq (StandardPath/2)>

CopyStandardPathComponents      proc    near

	uses 	ax, bx

        .enter

        cmp     bp, ax
        je      done

        push    bp		; current std path
	mov	bx, bp
	call	FileGetStdPathParent
	mov	bp, bx
	tst	bp
        jz      copyCurrent	| CheckHack <SP_NOT_STANDARD_PATH eq 0>

        ; parent exists, copy it first

        call    CopyStandardPathComponents
        jcxz    copyCurrent		; buffer full, but still need to pop bp
	LocalLoadChar ax, C_BACKSLASH
	LocalPutChar esdi, ax
        dec     cx

copyCurrent:
        pop     bp
        jcxz    done

	mov	si, bp
	call	FileGetStdPathName	; ds:si - name of std path
        call    CopyNTStringCXMaxPointAtNull
done:
        .leave
        ret

CopyStandardPathComponents      endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileSetCurrentPath, FileSetCurrentPathRaw

DESCRIPTION:	Set the current directory.  Both routines perform nearly the
		same function.  FileSetCurrentPath will additionally check the
		path to see if it matches a StandardPath, and if so, sets the
		current path disk handle to the nearest StandardPath.

CALLED BY:	GLOBAL

PASS:
	bx - disk handle OR StandardPath
		If BX is 0, then the passed path is either relative to
		the thread's current path, or is absolute (with a
		drive specifier).

	ds:dx - Path specification.  The path MAY contain a drive
		spec, in which case, BX should be passed in as zero.
		

RETURN:	carry - set if error
	ax - FileError (if an error)
		ERROR_PATH_NOT_FOUND
	bx - disk handle if bx was passed as 0

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if (disk handle == 0) {
	    disk handle = current path's disk handle
	}
	if (disk handle is standard path) {
	    stdpath = disk handle
	    disk handle = topLevelDiskHandle
	    EC: path must be relative (?)
	} else {
	    stdpath = 0
	    if (same disk as current path) {
	        note if path is absolute or relative
	    } else {
	    	EC: path must be absolute (note same)
	    }
	}

	EC: if path has drive spec, ensure absolute & matches disk handle
	
	if (path isn't below s.p., or path is null & below s.p.) {
	    call FileConstructFullPath with various pieces
	    if FileSetCurrentPath called (not ...Raw)
	        call FileParseStandardPath to see if it's a s.p. in disguise
	}
	
	; buffer contains either absolute path & disk handle is disk handle,
	; or buffer contains tail & disk handle is s.p. constant
	
	if (disk handle is s.p.) {
	    foreach possible absolute path on s.p. search path {
	    	find FSD and ask it to set thread's cwd to this possibility
		if successful {
		    set stdpath and copy tail in, nuking FSD-private data
		    return success
		}
	    }
	    return error
	} else {
	    ask FSD to set thread's cwd to value in buffer & disk handle
	    return whatever FSD returns.
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Cheng	2/90		Added disk handle support
	dhunter	4/27/2000	Added FileSetCurrentPathRaw
-------------------------------------------------------------------------------@
FSCP_DONT_CHECK_STANDARD_PATHS	equ	1

if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileSetCurrentPathRaw		proc	far
	mov	al, FSCP_DONT_CHECK_STANDARD_PATHS
	mov	ss:[TPD_dataBX], handle FileSetCurrentPathReal
	mov	ss:[TPD_dataAX], offset FileSetCurrentPathReal
	GOTO	SysCallMovableXIPWithDSDX
FileSetCurrentPathRaw		endp
CopyStackCodeXIP		ends
else

FileSetCurrentPathRaw		proc	far
	mov	al, FSCP_DONT_CHECK_STANDARD_PATHS
	GOTO	FileSetCurrentPathReal
FileSetCurrentPathRaw		endp
endif

if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileSetCurrentPath		proc	far
	clr	al			; Check StandardPaths
	mov	ss:[TPD_dataBX], handle FileSetCurrentPathReal
	mov	ss:[TPD_dataAX], offset FileSetCurrentPathReal
	GOTO	SysCallMovableXIPWithDSDX
FileSetCurrentPath		endp
CopyStackCodeXIP		ends
else

FileSetCurrentPath		proc	far
	clr	al			; Check StandardPaths
	FALL_THRU	FileSetCurrentPathReal
FileSetCurrentPath		endp
endif

FileSetCurrentPathReal	proc	far
	uses	bp, si, ds, dx, es, di, cx
	.enter

	mov	di, 750
	call	ThreadBorrowStackDSDX
	push	di

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si							>
EC<	movdw	bxsi, dsdx						>
EC<	call	ECAssertValidTrueFarPointerXIP				>
EC<	pop	bx, si							>
endif

	push	bx				; save for return

if FLOPPY_BASED_DOCUMENTS
	call	HackDocumentToFloppy		; force to B:\		
endif

	segmov	es, ss
	sub	sp, size PathName
	mov	di, sp			;es:di = buffer

	mov	si, ss:[TPD_curPath]	; si <- thread's cwd handle
EC <	tst	si							>
EC <	ERROR_Z	THREAD_HAS_NO_CURRENT_PATH_BLOCK			>

	call	CheckPathAbsolute		; cx <- 0 if relative, !0 if
						;  absolute

	; See if the disk handle passed is actually a standard path. These
	; constants are all odd, while disk handles must be even, so...
	; 
EC <	test	bx, DISK_IS_STD_PATH_MASK				>
EC <	jz	ecDiskNotSP						>
EC <	cmp	bx, StandardPath-2					>
EC <	ERROR_A	INVALID_STANDARD_PATH					>
EC <	jmp	mergePieces						>
EC <ecDiskNotSP:							>
EC <	tst	bx							>
EC <	jz	mergePieces						>
EC <	tst	cx							>
EC <	ERROR_Z	PATH_WITH_DISK_HANDLE_MUST_BE_ABSOLUTE			>
EC <mergePieces:							>

	;
	; If path is being set relative but is actually absolute, get a disk
	; handle for it based on any drive specifier it might have.
	; 
	tst	bx
	jnz	haveDiskHandle
	jcxz	checkQuickSet

	;
	; To cope with getting an absolute path whilst in a standard path
	; on a system where standard path merging isn't enabled, we need to
	; skip over the leading \, if such there be, to make the path be
	; relative instead. Note that we do have to ensure the first
	; char is a backslash, as the thing might be absolute with a
	; drive specifier at its front.
	;
	push	ax			; save check s.p. flag
	push	ds
	call	FP_CurPathLockDS	; ds, ^hbx <- cur path
	mov	ax, ds:[FP_stdPath]
	call	MemUnlock
	pop	ds
	tst	ax
	jz	getDiskForPath		; => not under s.p.
	
	mov	bx, dx			; ds:bx <- path to set
SBCS <	cmp	{char}ds:[bx], C_BACKSLASH	; absolute?		>
DBCS <	cmp	{wchar}ds:[bx], C_BACKSLASH	; absolute?		>
	jne	getDiskForPath		; yes, but with drive spec

	clr	bx			; leave bx 0 so FCFP prepends current
					;  dir
	pop	ax			; restore check s.p. flag
	jmp	haveDiskHandle

getDiskForPath:

	mov	bx, TRUE		; don't check for std path, as we'll
					;  do that in a moment anyway
	call	FileGetDestinationDisk	; ds:dx <- path w/o drive specifier
	pop	ax			; restore check s.p. flag
	LONG	jc	done		; no disk, quit now (7/20/93 cbh)

haveDiskHandle:
	;
	; ds:dx	= path tail
	; bx	= disk handle
	; cx	= 0 if path is relative, !0 if path is absolute
	; si	= current path handle
	;
	; EC: if drive specifier given in path, ensure the drive matches
	; the disk handle
	; 

EC <	push	es, ax, dx, si						>
EC <	call	FileLockInfoSharedToES					>
EC <	call	DriveLocateByName					>
EC <	ERROR_C	PATH_DRIVE_MISMATCH	; => drive doesn't exist, so	>
EC <					;  can't match disk handle	>
EC <	tst	si							>
EC <	jz	driveSpecOK		; => no drive spec, so ok	>
EC <	cmp	es:[bx].DD_drive, si	; match drive in disk handle?	>
EC <	ERROR_NE PATH_DRIVE_MISMATCH	; no -- choke.			>
EC <	tst	cx			; make sure path is absolute	>
EC <	ERROR_Z PATH_WITH_DRIVE_MUST_BE_ABSOLUTE			>
EC <driveSpecOK:							>
EC <	call	FSDUnlockInfoShared					>
EC <	pop	es, ax, dx, si						>

checkQuickSet:
	push	si

	mov	si, dx			; ds:si <- new path

	test	bx, DISK_IS_STD_PATH_MASK; below std path?
	jz	completeThePath		; no -- go build the full path and
					;  see if it's actually std
if DBCS_PCGEOS
	mov	{wchar}es:[di], 0	; assume tail is empty
	tst	{wchar}ds:[si]		; correct?
	jz	justStdPath		; wrong.
	cmp	{wchar}ds:[si], '\\'
	jne	completeThePath		; tail is root?
	cmp	{wchar}ds:[si][2], C_NULL
	jne	completeThePath
else
	mov	{char}es:[di], 0	; assume tail is empty
	tst	{char}ds:[si]		; correct?
	jz	justStdPath		; wrong.
	cmp	{word}ds:[si], '\\' or (0 shl 8)	; tail is root?
	jne	completeThePath
endif

justStdPath:
	push	ds
	call	FP_LoadVarSegDS
	tst	ds:[loaderVars].KLV_stdDirPaths
	pop	ds
	jz	completeThePath		; => std path mechanism not in use,
					;  so we have to build a full path
					;  from the std path and the tail we
					;  were given.


	mov	dx, di			; es:dx <- full path to set (nothing,
					;  in this case, as std path is
					;  everything)
					; skip construction and
					;  parsing, as we've got what we
					;  need right now.
	mov	bp, bx
	jmp	havePath

completeThePath:
	;
	; First construct the full, absolute path from the components we've
	; got: bx = disk handle (maybe 0), ds:si = path tail
	; 
	push	di
	mov	cx, size PathName
	clr	dx			;no drive spec

	call	FileConstructFullPath
EC <	ERROR_C	PATH_BUFFER_OVERFLOW					>
	pop	di

	;
	; Now see if the thing's actually a standard directory. (bx is
	; real disk handle (topLevelDiskHandle if was in S.P.))
	;
	; If al was passed in containing FSCP_DONT_CHECK_STANDARD_PATHS,
	; then FileSetCurrentPath was called, and we should perform the
	; default functionality of checking for a StandardPath.  Otherwise,
	; skip this check.
	;
	clr	bp			; assume no StandardPath
	cmp	al, FSCP_DONT_CHECK_STANDARD_PATHS
	je	havePath
	mov_tr	bp, ax			; save ax
	mov	dx, di			; save start of buffer
	call	FileParseStandardPath	; get StandardPath (if any)
	xchg	ax, bp			; bp = std path, restore ax


havePath:
	pop	si			; restore block handle for current path

	; es:di = path to set, bx = disk handle, bp = StandardPath,
	; si = path block to change

	tst	bp
	jz	checkIfSamePath
	mov	bx, bp			; bx <- std path, not disk handle
checkIfSamePath:

	; before setting the path, see if we're setting a path that is
	; already set

if 0	; 4/19/93: this optimization is of questionable utility, I think, as
;	; things tend to push dir/set dir/pop dir, making it unlikely that one
;	; would be setting the same directory as is already set, and this
;	; optimization has the unfortunate side effect of making the
;	; megafile stuff not get searched when looking for the netware FS
;	; driver, owing to the FP_pathInfo having been set to <1, 2, SP_TOP>
;	; before the megafile driver was loaded -- ardeb
;
;	call	FP_LoadVarSegDS
;	cmp	bx, ds:[si].HM_otherInfo	; same disk?
;	jnz	noMatchNoUnlock			; nope, so not same
;
;	xchg	bx, si				;bx = path handle, si = disk
;	call	FP_PathLockDS			;ds = path block
;	push	si, di
;	mov	si, ds:[FP_path]
;cmpLoop:
;	lodsb
;	scasb
;	jnz	noMatch
;	tst	al
;	jnz	cmpLoop				; zero flag set -> match
;noMatch:
;	pop	si, di
;
;	call	FileUnlockPath
;	xchg	bx, si				;si = path handle, bx = disk
;noMatchNoUnlock:
;	jz	done
endif

	segmov	ds, es
	mov	dx, di

	; Keep track of link recursion so we'll know if we get into an
	; infinite loop.  We keep the recursion counter at the bottom
	; of the stack for convenience.
	;
	inc	ss:[TPD_stackBot]
	mov	bp, ss:[TPD_stackBot]
	mov	{byte} ss:[bp].CP_linkCount, 0

	call	SetCurPath

	dec	ss:[TPD_stackBot]

done::

	mov	di, sp				;don't trash the carry!
	lea	sp, [di+(size PathName)]

	;
	; Return current disk handle if no error and BX was passed as 0
	; 
	mov	dx, bx		; dx <- current disk (saved in .enter)
	pop	bx		; bx <- passed bx
	jc	exit		; error => do nothing
	tst	bx		; passed 0?
	jnz	exit		; no (tst clears carry)
	mov	bx, dx		; return current disk handle
exit:

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret

FileSetCurrentPathReal	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	HackDocumentToFloppy

SYNOPSIS:	Changes SP_DOCUMENT to be hardwired to B:\.

CALLED BY:	utility

PASS:		
	bx - disk handle OR StandardPath
		If BX is 0, then the passed path is either relative to
		the thread's current path, or is absolute (with a
		drive specifier).

	ds:dx - Path specification.  The path MAY contain a drive
		spec, in which case, BX should be passed in as zero.
RETURN:		
	bx, dx updated if needed

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/23/93       	Initial version

------------------------------------------------------------------------------@

if SINGLE_DRIVE_DOCUMENT_DIR

HackDocumentToFloppy	proc	near
	;
	; Hack to map SP_DOCUMENT to the floppy, always.  7/20/93 cbh
	;
	cmp	bx, SP_DOCUMENT			; force document to A:
	jne	10$
	clr	bx
FXIP<	LoadVarSeg	ds, dx						>
NOFXIP<	segmov	ds, cs							>
	mov	dx, offset bColon
10$:
	ret
HackDocumentToFloppy	endp

FXIP <	idata	segment							>
LocalDefNLString bColon, <DOCUMENT_DRIVE_CHAR, C_COLON, C_BACKSLASH, C_NULL>
FXIP <	idata	ends							>

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckPathAbsolute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed path is absolute.

CALLED BY:	INTERNAL
PASS:		ds:dx	= path to check
RETURN:		cx	= 0 if path relative, non-0 if path absolute
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckPathAbsolute proc	near
		uses	ax, si
		.enter
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	movdw	bxsi, dsdx					>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx, si						>
endif

		mov	cx, 1
		mov	si, dx
scanLoop:
		LocalGetChar ax, dssi
		LocalIsNull	ax
		jz	seenNullTerm
		LocalCmpChar	ax, ':'
		je	seenColon
		LocalCmpChar	ax, C_BACKSLASH
		je	seenBackslash
EC <		jcxz	malformed	; drive spec *must* be followed	>
EC <					;  by backslash (absolute) in	>
EC <					;  this system, no matter what	>
EC <					;  the path is for. If cx is 0,	>
EC <					;  we've seen the colon...	>
NEC <		jcxz	done		; malformed, but pretend it's	>
NEC <					;  relative so as to provoke	>
NEC <					;  an error from DOS when	>
NEC <					;  concatenated with cur path	>
		jmp	scanLoop
seenNullTerm:
		dec	cx		; cx <- 0 as neither drive spec nor
					;  backslash seen (or we would
					;  have been outta here long since)
EC <		ERROR_S	MALFORMED_PATH	; => ended with drive spec	>
NEC <		js	malformed	;  pretend path is relative	>
NEC <					;  so we provoke DOS		>

done:
		.leave
		ret
seenColon:
		dec	cx
		jz	scanLoop	; => first colon, so ok
		; can't have more than one colon in a path, bub
malformed:
EC <		ERROR	MALFORMED_PATH					>
NEC <		clr	cx	; pretend it's relative, in the hope	>
NEC <		jmp	done	;  that it's even less likely to be 	>
NEC <				;  found by DOS				>

seenBackslash:
		dec	cx	; if no colon before this, cx is 1 and path
				;  is relative...unless backslash is the first
				;  thing, of course :)
				; if colon before this, cx is 0 and decrement
				;  makes it non-zero, signalling absolute
		LocalPrevChar	dssi ; back up to actual backslash position
		cmp	si, dx	; backslash at start?
		jne	done	; no -- leave cx as-is
		dec	cx	; yes -- cx must be 0 now, so make it -1 to
				;  signal path absolute
		jmp	done
CheckPathAbsolute endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileParseStandardPathIfPathsEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Similar to FileParseStandardPath, but only returns a
		standard path if KLV_stdDirPaths is non-zero, so
		InitForPathEnum won't choke.
		
		It also is guaranteed to not return a null path tail, as
		we assume the caller is going to perform some operation on
		the passed path and thus need something non-null on which
		to work, unless, of course, a null path is passed in...

CALLED BY:	FileGetDestinationDisk
PASS:		es:di	= path to parse
		bx	= disk handle, or 0 to => that path includes
			  drive specifier.
RETURN:		ax	= standard path (SP_NOT_STANDARD_PATH [0] if none)
		es:di	= pointing at remaining part of path
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/91	Initial version
	chrisb  9/29/92		Added initial check for null

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileParseStandardPathIfPathsEnabled proc near

		uses	bx

		.enter

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	movdw	bxsi, esdi					>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx, si						>
endif

	;
	; If the caller passed us a null path, there's nothing to
	; parse... (9/29/92)
	;

		mov	ax, bx
SBCS <		tst	<{byte} es:[di]>				>
DBCS <		tst	<{wchar} es:[di]>				>
		jz	done

		clr	ax		; assume paths disabled
		push	ds
		call	FP_LoadVarSegDS
		tst	ds:[loaderVars].KLV_stdDirPaths
		pop	ds
		jz	done
		push	di
		call	FileParseStandardPath
		pop	bx
	;
	; Ensure final tail ain't null
	; 
SBCS <		tst	{char}es:[di]					>
DBCS <		tst	{wchar}es:[di]					>
		jnz	done
	;
	; It is null, so back up the std path tree one level.
	; 
		xchg	bx, ax		; bx <- std path, ax <- path start
		call	FileGetStdPathParent
		xchg	ax, bx		; ax <- parent, bx <- path start
		tst	ax
		jnz	skipBackAComponent
	;
	; Parsed path was SP_TOP, so use the path by itself, since there's
	; nothing above SP_TOP...
	; 
		mov	di, bx
done:
		.leave
		ret

skipBackAComponent:
		LocalPrevChar esdi
SBCS <		cmp	{char}es:[di], C_BACKSLASH			>
DBCS <		cmp	{wchar}es:[di], C_BACKSLASH			>
		je	atComponentStart
		cmp	di, bx		; at start of passed path?
		ja	skipBackAComponent
		jmp	done		; yes -- leave di there...
atComponentStart:
		LocalNextChar esdi	; point to first char of component, not
					;  backslash
		jmp	done
FileParseStandardPathIfPathsEnabled endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetStdPathFirstChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the first child of a std path

CALLED BY:	FileParseStdPath

PASS:		bx - StandardPath

RETURN:		bl - child , or SP_NOT_STANDARD_PATH if not found

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	We set SI as the offset of the field in the data structure, 
	plus the expected address of the table, -1 (since S.P.
	constants are all odd, and start at 1).


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetStdPathFirstChild	proc near

EC <	cmp	bx, StandardPath	>
EC <	ERROR_AE INVALID_STANDARD_PATH	>

	push	si
	mov	si, (offset alteredStdPathTree + offset SPN_firstChild-1)
	jmp	accessStdPathTreeCommon
FileGetStdPathFirstChild	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetStdPathName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a pointer to the string representing the
		directory name of the given StandardPath

CALLED BY:	INTERNAL

PASS:		si - StandardPath
		ds - StandardPathStrings

RETURN:		ds:si - standard path name

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetStdPathName	proc near
	uses	bx

	.enter


EC <	cmp	si, StandardPath	>
EC <	ERROR_AE INVALID_STANDARD_PATH	>

	;
	; See if the documentIsTop flag is set
	;

	push	ds
	call	FP_LoadVarSegDS
	tst	ds:[documentIsTop]
	pop	ds

	jz	useStrings
	cmp	si, SP_DOCUMENT
	je	nullString

useStrings:
	assume	ds:StandardPathStrings

	mov	si, ds:[firstStandardPath-SP_APPLICATION][si]

done:
	.leave
	ret

nullString:

	;
	; If SP_DOCUMENT flag set, return a null string
	;

	mov	si, ds:[firstStandardPath]
SBCS <	add	si, (size firstStandardPath - 1)			>
DBCS <	add	si, (size firstStandardPath - 2)			>
	jmp	done
	assume	ds:dgroup

FileGetStdPathName	endp

if MULTI_LANGUAGE
FileGetStdPathNameFar proc far
	call	FileGetStdPathName
	ret
FileGetStdPathNameFar endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetStdPathNextSibling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the next sibling in the std path tree, or 0 if
		not found

CALLED BY:	INTERNAL

PASS:		bx - StandardPath

RETURN:		bl - next sibling (StandardPath), or 0 if not found

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	hack.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetStdPathNextSibling	proc near

EC <	cmp	bx, StandardPath	>
EC <	ERROR_AE INVALID_STANDARD_PATH	>

	;
	; Assume we're using the "altered" tree.  Code is optimized
	; for this NOT being the case, as we jump later if so.
	;

	push	si
	mov	si, (offset alteredStdPathTree + offset SPN_nextSibling-1)
	
accessStdPathTreeCommon	label	near

	;
	; If special hack flag set in .INI file, then use our
	; "altered" tree. 
	;

	push	ds
	call	FP_LoadVarSegDS
	tst	ds:[documentIsTop]
	jnz	gotTree
	sub	si, (offset alteredStdPathTree- offset stdPathTree)
gotTree:
	mov	bl, cs:[si][bx]		; fetch sibling or child
	pop	ds
	pop	si

EC <	cmp	bx, StandardPath	>
EC <	ERROR_AE INVALID_STANDARD_PATH	>
	
	ret
FileGetStdPathNextSibling	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	FileParseStandardPath

DESCRIPTION:	Construct the best combination of a StandardPath constant
		and a path. NOTE: if the filesystem on which our top level
		resides is case-insensitive, the passed path must be in
		all upper-case for it to be properly recognized. The best
		way to ensure this is to push to the directory in question
		and call FileGetCurrentPath, remembering to stick the
		drive specifier at the beginning of...to be continued..

			Returns no leading slash.

CALLED BY:	GLOBAL

PASS:
	es:di 	- path to parse
	bx	- disk on which path resides. 0 means path contains drive
		  specifier

RETURN:
	ax - StandardPath (0 [aka SP_NOT_STANDARD_PATH] if none)
	es:di - pointing at remaining part of path

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@


StdPathNode	struct
    SPN_nextSibling	byte	
    SPN_firstChild	byte	
StdPathNode	ends


;
; SP_TOP -------+- SP_APPLICATION
; 		+- SP_DOCUMENT
; 		+- SP_SYSTEM
; 		|	+- SP_SYS_APPLICATION
;		|	+- SP_MOUSE_DRIVERS
;		|	+- SP_PRINTER_DRIVERS
;		|	+- SP_FILE_SYSTEM_DRIVERS
;		|	+- SP_VIDEO_DRIVERS
;		|	+- SP_SWAP_DRIVERS
;		|	+- SP_KEYBOARD_DRIVERS
;		|	+- SP_FONT_DRIVERS
;		|	+- SP_IMPORT_EXPORT_DRIVERS
;		|	+- SP_TASK_SWITCH_DRIVERS
;		|	+- SP_POWER_DRIVERS
;		|	+- SP_HWR
;		|	+- SP_PAGER_DRIVERS
;		|	+- SP_COMPONENT      (NewBASIC)
;		+- SP_PRIVATE_DATA
;		|	+- SP_STATE
;		|	+- SP_SPOOL
;		|	+- SP_WASTE_BASKET
;		+- SP_USER_DATA
;		|	+- SP_FONT
;		|	+- SP_HELP_FILES
; 		|	+- SP_TEMPLATE
; 		|	+- SP_BACKUP
;		+- SP_DOS_ROOM

stdPathTree	StdPathNode	\
	<0, SP_APPLICATION>,			;top
	<SP_DOCUMENT, 0>,			;world
	<SP_SYSTEM, 0>,				;document
	<SP_PRIVATE_DATA, SP_SYS_APPLICATION>,	;system
	<SP_USER_DATA, SP_STATE>,		;privdata
	<SP_SPOOL, 0>,				;state
	<SP_HELP_FILES, 0>,			;font
	<SP_WASTE_BASKET, 0>,			;spool
	<SP_MOUSE_DRIVERS, 0>,			;sysappl
	<SP_DOS_ROOM, SP_FONT>,			;userdata
	<SP_PRINTER_DRIVERS, 0>,		;mouse
	<SP_FILE_SYSTEM_DRIVERS, 0>,		;printer
	<SP_VIDEO_DRIVERS, 0>,			;fs
	<SP_SWAP_DRIVERS, 0>,			;video
	<SP_KEYBOARD_DRIVERS, 0>,		;swap
	<SP_FONT_DRIVERS, 0>,			;kbd
	<SP_IMPORT_EXPORT_DRIVERS, 0>,		;fontDr
	<SP_TASK_SWITCH_DRIVERS, 0>,		;impex
	<SP_POWER_DRIVERS, 0>,			;task
	<SP_TEMPLATE, 0>,			;help
	<SP_BACKUP, 0>,				;template
	<SP_HWR, 0>,				;power
	<0, 0>,					;dosroom
	<SP_PAGER_DRIVERS, 0>,			;hwr
	<0, 0>,					;wastebasket
	<0, 0>,					;backup
	<SP_COMPONENT, 0>,			;pager
	<0, 0>					;component (NewBASIC)

;Special Case for some networks: SP_DOCUMENT = PC/GEOS root directory.
; SP_DOCUMENT is not part of the tree in this case -- we never want to
; parse it, and we never want to construct it (its string is NULL)
;
;    ---+- SP_TOP ------+- SP_APPLICATION
;	 		+- SP_SYSTEM
;			|	+- SP_SYS_APPLICATION
;			|	+- SP_MOUSE_DRIVERS
;			|	+- SP_PRINTER_DRIVERS
;			|	+- SP_FILE_SYSTEM_DRIVERS
;			|	+- SP_VIDEO_DRIVERS
;			|	+- SP_SWAP_DRIVERS
;			|	+- SP_KEYBOARD_DRIVERS
;			|	+- SP_FONT_DRIVERS
;			|	+- SP_IMPORT_EXPORT_DRIVERS
;			|	+- SP_TASK_SWITCH_DRIVERS
;			|	+- SP_POWER_DRIVERS
;			|	+- SP_HWR
;			|	+- SP_PAGER_DRIVERS
;			|	+- SP_COMPONENT (NewBASIC)
;			+- SP_PRIVATE_DATA
;			|	+- SP_STATE
;			|	+- SP_SPOOL
;			|	+- SP_WASTE_BASKET
;			+- SP_USER_DATA
;			|	+- SP_FONT
;			|	+- SP_HELP_FILES
;			|	+- SP_TEMPLATE
;			|	+- SP_BACKUP
;			+- SP_DOS_ROOM
;	
;    ---+- SP_DOCUMENT
;

alteredStdPathTree	StdPathNode	\
	<0, SP_APPLICATION>,			;top
	<SP_SYSTEM, 0>,				;world
	<0, 0>,					;document
	<SP_PRIVATE_DATA, SP_SYS_APPLICATION>,	;system
	<SP_USER_DATA, SP_STATE>,		;privdata
	<SP_SPOOL, 0>,				;state
	<SP_HELP_FILES, 0>,			;font
	<SP_WASTE_BASKET, 0>,			;spool
	<SP_MOUSE_DRIVERS, 0>,			;sysappl
	<SP_DOS_ROOM, SP_FONT>,			;userdata
	<SP_PRINTER_DRIVERS, 0>,		;mouse
	<SP_FILE_SYSTEM_DRIVERS, 0>,		;printer
	<SP_VIDEO_DRIVERS, 0>,			;fs
	<SP_SWAP_DRIVERS, 0>,			;video
	<SP_KEYBOARD_DRIVERS, 0>,		;swap
	<SP_FONT_DRIVERS, 0>,			;kbd
	<SP_IMPORT_EXPORT_DRIVERS, 0>,		;fontDr
	<SP_TASK_SWITCH_DRIVERS, 0>,		;impex
	<SP_POWER_DRIVERS, 0>,			;task
	<SP_TEMPLATE, 0>,			;help
	<SP_BACKUP, 0>,				;template
	<SP_HWR, 0>,				;power
	<0, 0>,					;dosroom
	<SP_PAGER_DRIVERS, 0>,			;hwr
	<0, 0>,					;wastebasket
	<0, 0>,					;backup
	<SP_COMPONENT, 0>,			;pager
	<0, 0>					;component (NewBASIC)


.assert (length stdPathTree eq (StandardPath/2))
.assert (length alteredStdPathTree eq (StandardPath/2))
CheckHack <SP_NOT_STANDARD_PATH eq 0>

if FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileParseStandardPath		proc	far
	uses	cx, es
	.enter
	;
	;  Because this routine is supposed to return a pointer into
	;  the passed string, we need to save the original offsets
	;  of the passed in string and the copied string, determine
	;  how much the pointer changes in the returned value, and
	;  add that change to the passed in pointer.
	push	di				; save original offset
	clr	cx				; null terminated...
	call	SysCopyToStackESDI	; es:di <- copy string

	push	di				; save copied offset
	call	FileParseStandardPathReal ; di <- new new offset
	tst	ax
	jnz	found
	call	FileParseMergedStandardPathReal
found:
	pop	cx				; cx <- copied offset

	sub	di, cx				; di <- change in copied offsets
	pop	cx				; cx <- original offset

	add	di, cx				; di <- correct offset for
						;	original string
	call	SysRemoveFromStack
	.leave
	ret
FileParseStandardPath		endp
CopyStackCodeXIP		ends

else
FileParseStandardPath		proc	far
	call	FileParseStandardPathReal
	tst	ax
	jnz	found
	call	FileParseMergedStandardPathReal
found:
	ret
FileParseStandardPath		endp
endif

FileParseStandardPathReal	proc	far
	uses bx, cx, dx, si, ds, bp
	.enter

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	movdw	bxsi, esdi					>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx, si						>
endif


	push	bx			; passed disk handle

	mov	bx, handle StandardPathStrings
	call	FP_MemLockDS		; lock it once at the very beginning
					;  so we needn't keep locking and
					;  unlocking it.
	pop	bx

	;
	; See if we're passed a standard path
	;
	test	bx, DISK_IS_STD_PATH_MASK
	jnz	givenStdPath

	;
	; Set up registers for loop
	;

	mov	bp, SP_NOT_STANDARD_PATH	; final verdict

	; compare to KLV_topLevelPath.  If BX was passed in as zero,
	; then assume es:di is an absolute path, and start at the top.

	call	FP_LoadVarSegDS
	mov	si, offset loaderVars.KLV_topLevelPath
	tst	bx
	jz	startAtTop

	;
	; If BX is the disk handle on which the top-level directory
	; resides, then start at SP_TOP as well.  Otherwise, 
	;

	LocalNextChar	dssi
	LocalNextChar	dssi		; skip drive specifier in topLevelPath
	cmp	bx, ds:[topLevelDiskHandle]
	jne	searchComplete

startAtTop:
	;
	; Start parsing at SP_TOP.  DS:SI is the top-level directory name.
	;

	mov	bx, SP_TOP
	jmp	enterNodeLoopWithString

givenStdPath:
	; passed disk handle is a std path, so start the quest from its
	; first child.

	mov	bp, bx			; bp <- current verdict
	LocalLoadChar ax, C_BACKSLASH
SBCS <	scasb				; passed path "absolute"?	>
DBCS <	scasw				; passed path "absolute"?	>
	je	nodeLoop		; yes -- ignore leading backslash
	LocalPrevChar 	esdi		; no -- back up to start again


nodeLoop:
	; get first child

	mov	bx, bp			; std path
	call	FileGetStdPathFirstChild
	tst	bx
	jz	searchComplete		;no children -- done

siblingLoop:
	push	bx
	mov	bx, handle StandardPathStrings
	call	MemDerefDS
	pop	bx

	;
	; For each of the current child and its siblings, see if its
	; name matches the current component of the target pathname
	;
	mov	si, bx			; si <- child's SP constant
	call	FileGetStdPathName	; ds:si - std path name

enterNodeLoopWithString:
	mov	dx, di			; dx = start of string
cmpLoop:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	endOfString
SBCS <	scasb								>
DBCS <	scasw								>
	je	cmpLoop
	jmp	noMatch

endOfString:

	LocalGetChar	ax, esdi, NO_ADVANCE
	LocalIsNull	ax
	jz	matchFoundAtEnd
	LocalCmpChar	ax, C_BACKSLASH
	jne	noMatch

	; match found -- move down the tree

	LocalNextChar	esdi		;es:di must point after \  .
	mov	bp, bx		; last s.p. matched <- s.p. just matched 
	jmp	nodeLoop

	; match found and we're at the end of the string
matchFoundAtEnd:

	mov	bp, bx
	jmp	searchComplete

	; no string match, try next sibling

noMatch:
	mov	di, dx			; restore target string
	call	FileGetStdPathNextSibling
	tst	bx
	jnz	siblingLoop

searchComplete:
	mov	bx, handle StandardPathStrings
	call	MemUnlock

	mov_tr	ax, bp			; StandardPath

	.leave
	ret

FileParseStandardPathReal	endp

FileParseMergedStandardPathReal	proc	far
	uses bx, cx, dx, si, ds, bp
	.enter

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	movdw	bxsi, esdi					>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx, si						>
endif


	push	bx			; passed disk handle

	mov	bx, handle StandardPathStrings
	call	FP_MemLockDS		; lock it once at the very beginning
					;  so we needn't keep locking and
					;  unlocking it.
	pop	bx

	;
	; See if we're passed a standard path
	;
	test	bx, DISK_IS_STD_PATH_MASK
	jnz	givenStdPath

	;
	; Set up registers for loop
	;

	mov	bp, SP_NOT_STANDARD_PATH	; final verdict

	; compare to KLV_topLevelPath.  If BX was passed in as zero,
	; then assume es:di is an absolute path, and start at the top.

	call	FP_LoadVarSegDS
	tst	ds:[loaderVars].KLV_stdDirPaths
	jz	searchComplete
	push	bx
	mov	bx, ds:[loaderVars].KLV_stdDirPaths
	call	MemLockShared
	pop	bx
	mov	ds, ax
	clr	si
	lodsw
	cmp	ax, ds:[si]
	je	searchComplete
	mov	si, ax
	tst	bx
	jz	startAtTop

	;
	; If BX is the disk handle on which the top-level directory
	; resides, then start at SP_TOP as well.  Otherwise, 
	;

	LocalNextChar	dssi
	LocalNextChar	dssi		; skip drive specifier in topLevelPath
	push	ds
	call	FP_LoadVarSegDS
	cmp	bx, ds:[topLevelDiskHandle]
	pop	ds
	jne	searchComplete

startAtTop:
	;
	; Start parsing at SP_TOP.  DS:SI is the top-level directory name.
	;

	mov	bx, SP_TOP
	jmp	enterNodeLoopWithString

givenStdPath:
	; passed disk handle is a std path, so start the quest from its
	; first child.

	mov	bp, bx			; bp <- current verdict
	LocalLoadChar ax, C_BACKSLASH
SBCS <	scasb				; passed path "absolute"?	>
DBCS <	scasw				; passed path "absolute"?	>
	je	nodeLoop		; yes -- ignore leading backslash
	LocalPrevChar 	esdi		; no -- back up to start again


nodeLoop:
	; get first child

	mov	bx, bp			; std path
	call	FileGetStdPathFirstChild
	tst	bx
	jz	searchComplete		;no children -- done

siblingLoop:
	push	bx
	mov	bx, handle StandardPathStrings
	call	MemDerefDS
	pop	bx

	;
	; For each of the current child and its siblings, see if its
	; name matches the current component of the target pathname
	;
	mov	si, bx			; si <- child's SP constant
	call	FileGetStdPathName	; ds:si - std path name

enterNodeLoopWithString:
	mov	dx, di			; dx = start of string
cmpLoop:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	endOfString
SBCS <	scasb								>
DBCS <	scasw								>
	je	cmpLoop
	jmp	noMatch

endOfString:

	LocalGetChar	ax, esdi, NO_ADVANCE
	LocalIsNull	ax
	jz	matchFoundAtEnd
	LocalCmpChar	ax, C_BACKSLASH
	jne	noMatch

	; match found -- move down the tree

	LocalNextChar	esdi		;es:di must point after \  .
	mov	bp, bx		; last s.p. matched <- s.p. just matched 
	jmp	nodeLoop

	; match found and we're at the end of the string
matchFoundAtEnd:

	mov	bp, bx
	jmp	searchComplete

	; no string match, try next sibling

noMatch:
	mov	di, dx			; restore target string
	call	FileGetStdPathNextSibling
	tst	bx
	jnz	siblingLoop

searchComplete:
	call	FP_LoadVarSegDS
	mov	bx, ds:[loaderVars].KLV_stdDirPaths
	tst	bx
	jz	noPaths
	call	MemUnlockShared
noPaths:
	mov	bx, handle StandardPathStrings
	call	MemUnlock

	mov_tr	ax, bp			; StandardPath

	.leave
	ret

FileParseMergedStandardPathReal	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FileStdPathCheckIfSubDir

DESCRIPTION:	Checks if a StandardPath constant (bx)is a subdirectory of
			another StandardPath constant (bp).

CALLED BY:	GLOBAL

PASS:		bp = potential parent directory (StandardPath)
		bx = potential subdirectory (StandardPath)
	
RETURN:		ax = 0 if bx is a subdir of bp
		ax = non-zero is bx is not a subdir of bp

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/21/92		Initial version

------------------------------------------------------------------------------@
FileStdPathCheckIfSubDir	proc	far
	uses	bx
	.enter

	clr	ax

	cmp	bp, SP_NOT_STANDARD_PATH
	je	failedSubDirTest
	cmp	bx, SP_NOT_STANDARD_PATH
	je	failedSubDirTest

EC <	test	bp, DISK_IS_STD_PATH_MASK		>
EC <	ERROR_Z	STANDARD_PATH_EXPECTED			>
EC <	test	bx, DISK_IS_STD_PATH_MASK		>
EC <	ERROR_Z	STANDARD_PATH_EXPECTED			>

	; start from bx and look upward for bp
subDirLoop:
	call	FileGetStdPathParent
	tst	bx
	jz	failedSubDirTest
	cmp	bx, bp
	jne	subDirLoop

		; passed if get to here
	jmp	done

failedSubDirTest:
	dec	ax		; ax is nonzero

done:
	.leave
	ret
FileStdPathCheckIfSubDir	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	StdPathPointAtNthChild

DESCRIPTION:	Find the Nth child of a standard path

CALLED BY:	FEEnumSpecials

PASS:
	StandardPathStrings resource locked
	si - StandardPath
	cx - child # to find

RETURN:
	carry - set if child does not exist
	ds:si - pointing at Nth child

DESTROYED:
	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version
	CDB	9/11/92		changed to use stdpath access routines
------------------------------------------------------------------------------@

StdPathPointAtNthChild	proc	far
	uses	bx
	.enter

	mov	bx, si
	call	FileGetStdPathFirstChild

	inc	cx			; ensure 1-origin
	jmp	endLoop

childLoop:
	call	FileGetStdPathNextSibling	; bl <- stdPath

endLoop:
	tst	bl
	loopne	childLoop
	jz	noChild

gotChild::
	mov	si, bx				; si <- std path
	call	FileGetStdPathName		; ds:si - name of std path
	clc
done:
	.leave
	ret

noChild:
	stc
	jmp	done
StdPathPointAtNthChild	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FilePushDir

DESCRIPTION:	Push the current directory onto the thread's directory stack.
		The current directory isn't changed, but this allows
		FileSetCurrentPath to be called with impunity, as the previous
		directory can be recovered by executing a FilePopDir

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Duplicate the current path block and link the new one into the
	stack *after* the current one so FSD's can continue to optimize any
	directory stuff based on the thread's path handle.


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Cheng	2/90		Added disk handle support

------------------------------------------------------------------------------@
FILEPUSHDIR	proc	far	uses bx, si, ds, ax
	.enter

	mov	bx, ss:[TPD_curPath]	; Fetch current path
	mov	si, bx			; preserve original
	call	FileCopyPath		; Forcibly duplicate it

	xchg	bx, si			; bx <- current path, si <- new block
	call	FP_PathLockDS		; Lock current path down
	mov	ax, si
	xchg	ds:[FP_prev], ax	; Link the new block behind it
	call	FileUnlockPath

	mov	bx, si			; bx <- new block
	call	FP_PathLockDS
	mov	ds:[FP_prev], ax	; link new block to block previously
					;  behind current block
	call	FileUnlockPath


	.leave
	ret
FILEPUSHDIR	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FilePopDir

DESCRIPTION:	Pop a directory from the thread's directory stack

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	none

DESTROYED:
	none (flags preserved)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Cheng	2/90		Added disk handle support

------------------------------------------------------------------------------@
FILEPOPDIR	proc	far	uses	bx, si, ds
	.enter
	pushf

	call	FP_CurPathLockDS
	mov	si, ds:[FP_prev]
EC <	tst	si							>
EC <	ERROR_Z	DIRECTORY_STACK_EMPTY					>
	call	FileDeletePath		; Nuke the current path

	mov	ss:[TPD_curPath], si	; Set the previous path as the thread's
					;  new path

	popf
	.leave
	ret
FILEPOPDIR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSetStandardPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	change to one of the standard system directories

CALLED BY:	GLOBAL

PASS:		ax - directory to change to, StandardPath enum or disk handle

RETURN:		if FLOPPY_BASED_DOCUMENTS
			if error:
				carry set
				ax - FileError
			else
				carry clear
		else
			nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/04/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileSetStandardPath	proc	far
		uses bx, dx, ds
		.enter

		push	ax		; don't destroy AX if no error
		
		segmov	ds, cs
		mov	dx, offset rootString
		mov_tr	bx, ax
		call	FileSetCurrentPath

if FLOPPY_BASED_DOCUMENTS
		pop	bx
		jc	done
		mov_tr	ax, bx
done:
else
		pop	ax
		
EC <		ERROR_C	SET_PATH_ERROR					>
endif
		
		.leave
		ret

FileSetStandardPath	endp

LocalDefNLString rootString <C_BACKSLASH, 0>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileAllocPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and initialize a new FilePath block

CALLED BY:	FileCopyPath
PASS:		nothing
RETURN:		bx	= handle of uninitialized new path
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileAllocPath	proc	near	uses ax, cx
		.enter
	;
	; Allocate the new block swapable, and non-discardable.
	;
		mov	ax, size FilePath+1
		mov	cx, (HAF_STANDARD_NO_ERR shl 8) \
				or mask HF_SHARABLE or mask HF_SWAPABLE
		mov	bx, handle 0	; path blocks are all owned by the
					;  kernel
		call	MemAllocSetOwnerFar
		.leave
		ret
FileAllocPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCopyPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a copy of a path block

CALLED BY:	FilePushDir, CreateThreadCommon
PASS:		bx	= path to duplicate
RETURN:		bx	= new path block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCopyPath 	proc	far	uses ds, es, ax, di, cx, si
		.enter
	;
	; Allocate a new path block
	;
		mov	si, bx
		call	FileAllocPath
	;
	; Copy the disk handle from the old to the new block
	;
		call	FP_LoadVarSegDS
		mov	ax, ds:[si].HM_otherInfo
		mov	ds:[bx].HM_otherInfo, ax
		push	ax		; save disk handle for possible
					;  notification
	;
	; Enlarge the new thing to be the same size as the old.
	; 
		mov	ax, MGIT_SIZE
		xchg	bx, si		; bx <- old path, si <- new path
		call	MemGetInfo	; ax <- # bytes
		xchg	bx, si		; bx <- new path, si <- old path
		push	ax
		mov	cx, mask HAF_LOCK shl 8
		call	MemReAlloc	; ax <- segment of block
		pop	cx		; cx <- # of bytes to copy
	;
	; Lock down both and copy the whole block.
	;
		mov	es, ax
		push	bx
		mov	bx, si
		call	FP_PathLockDS

		clr	si
		mov	di, si
		rep	movsb
	;
	; Don't have the new path point into the path stack...even though
	; it would be useful for FilePushDir for us to leave this,
	; ThreadCreate would get unhappy (and it's not supposed to look inside
	; a path block...)
	;
		mov	es:[FP_prev], 0
	;
	; Unlock both the blocks, leaving bx being the new path
	;
		call	FileUnlockPath
		mov	cx, bx		; cx <- old block
		pop	bx
		call	FileUnlockPath
	;
	; If path is on a real disk, we need to notify the driver that the
	; thing's been duplicated.
	;
		pop	si
		test	si, DISK_IS_STD_PATH_MASK
		jnz	done
		
EC <		mov	ax, NULL_SEGMENT; avoid ec +segment		>
EC <		mov	es, ax		;  death from use of 		>
EC <		mov	ds, ax		;  FileUnlockPath		>

		mov	di, DR_FS_CUR_PATH_COPY
		push	bp
		call	DiskCallFSD
		pop	bp
done:
		.leave
		ret
FileCopyPath 	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetCurPathUsingStdPath

DESCRIPTION:	Set the thread's current directory to the passed standard
		path.

CALLED BY:	SetCurPath

PASS:
	ds:dx	= path tail under standard path

	bx	= standard path below which to find the tail

RETURN:
	carry - set if error
		ax	= ERROR_PATH_NOT_FOUND
			= ERROR_DISK_UNAVAILABLE
			= ERROR_DISK_STALE
	carry clear if path set successfully:
		ax	= destroyed
		bx	= actual standard path that was set

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	PATH TAIL is all that's stored in the logical path in the path
	block. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	ardeb	8/6/91		Changed for 2.0
-------------------------------------------------------------------------------@
SetCurPathUsingStdPath	proc	near

	uses	cx, si, di, es, bx

stdPath		local	StandardPath	push	bx
tailLength	local	word
dirPathInfo	local	word

	.enter

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	movdw	bxsi, dsdx					>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx, si						>
endif

	;
	; Use the internal Int_SetDirOnPath routine to first switch the thread
	; to the initial existing directory for the standard path.
	;
	; CX <- the standard path being set, while AX <- DirPathInfo sufficient
	; to start enumerating things from the first path for the std path
	; being set. DS:DX <- tail below std path
	; 
	
	mov	cx, bx		; cx <- std path
		CheckHack <offset DPI_STD_PATH eq 0 AND width DPI_STD_PATH eq 8>
	mov	al, cl		; set DPI_STD_PATH
	mov	ah, high DirPathInfo <1,0,0>
	call	Int_SetDirOnPath
	jc	noExistee	; => none exists, so std path doesn't exist

recordPath:
	mov	ss:[dirPathInfo], ax

	mov	bx, ss:[TPD_curPath]
	call	FSDInformOldFSDOfPathNukage

	;
	; Reallocate the path block large enough to hold the private
	; data (flags & path tail)
	;

	segmov	es, ds
	mov	di, dx
SBCS <	clr	al							>
DBCS <	clr	ax							>
	mov	cx, -1
	LocalFindChar		;repne scasb/scasw
	not	cx		; length of tail

	mov	ss:[tailLength], cx
	mov_tr	ax, cx
DBCS <	shl	ax		; ax <- size				>
	add	ax, size FilePath + size StdPathPrivateData
	clr	ch
	call	MemReAlloc
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	jc	done

	call	FileLockPath
	mov	es, ax

	;
	; Store the std path constant and the dirPathInfo, setting the
	; DPI_EXISTS_LOCALLY flag so that the first path won't be
	; skipped by the next enumeration.
	;

	mov	ax, ss:[stdPath]
	mov	es:[FP_stdPath], ax
	mov	ax, ss:[dirPathInfo]
	ornf	ax, mask DPI_EXISTS_LOCALLY
	mov	es:[FP_pathInfo], ax
	mov	ax, ss:[tailLength]
DBCS <	shl	ax		; ax <- size				>
	add	ax, size StdPathPrivateData + size FilePath
	mov	es:[FP_path], ax

	;
	; Store the fixed-size portion
	;

	mov	di, offset FP_private
	mov	cx, size StdPathPrivateData
	clr	al
	rep	stosb

	;
	; Store the path tail
	;

	mov	si, dx
	mov	cx, ss:[tailLength]
	LocalCopyNString	;rep movsb/movsw
	
	call	FileUnlockPath

done:
	.leave
	ret

noExistee:
	mov	bx, ss:[stdPath]
	call	StdPathDoesntExist
	jc	done
	jmp	recordPath
SetCurPathUsingStdPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCurPathUsingStdPathWhenStdPathsNotEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The current path is within a standard paths, but no
		directory-merging has been specified in the ini file. We
		still have to do a couple special things, however,
		for consistency's sake: create the thing if it doesn't
		exist, and make sure FileGetCurrentPath will return
		a StandardPath constant.

CALLED BY:	SetCurPath

PASS:
	bx	= StandardPath 
	ds:dx	= path tail under standard path

RETURN:
	carry set if path doesn't exist on the disk
		ax	= ERROR_PATH_NOT_FOUND
			= ERROR_DISK_UNAVAILABLE
			= ERROR_DISK_STALE
	carry clear if path set successfully
		ax	= destroyed
		bx	= actual disk handle that was finally set

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	The buffer for the pathname is allocated on the global heap,
	rather than the stack, so that we can avoid stack overflow when
	recursively traversing links.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/92		Initial version
	CDB	8/18/92		Modified to work with links

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCurPathUsingStdPathWhenStdPathsNotEnabled	proc	near

		uses	ds, es, si, di, cx, dx

stdPath		local	StandardPath	push	bx
pathTail	local	fptr		push	ds, dx
bufferHandle	local	hptr

		.enter
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	movdw	bxsi, dsdx					>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx, si						>
endif

tryAgain:

	;
	; Construct the full path, and set it as the current path.
	;

		push	bx
		call	FileAllocPathNameBuffer	; es:di - buffer
		mov	ss:[bufferHandle], bx
		pop	bx
		jc	done

		push	di
		mov	si, dx			; ds:si <- tail
		clr	dx			; no drive spec, please
		call	FileConstructFullPath
		pop	dx
		segmov	ds, es			; ds:dx - buffer

		call	SetCurPath		; bx <- actual disk handle

	;
	; Free the buffer, w/o munging flags or trashing the disk
	; handle in BX
	;

		push	bx
		pushf
		mov	bx, ss:[bufferHandle]
		call	MemFree
		popf
		pop	bx			; std path

	;
	; If there was an error setting the path, try to create it...
	;

		jc	maybeCreate

	;
	; Now lock down the path block and set its FP_stdPath
	; and FP_pathInfo variables to indicate the standard path that we
	; know the thread is in.
	; 
		mov	si, ss:[TPD_curPath]
		xchg	bx, si			; bx <- path block,
						;  si <- disk handle
		call	FP_PathLockDS
		mov	ax, ss:[stdPath]
		mov	ds:[FP_stdPath], ax	; save std path

		ornf	ax, DirPathInfo <1,0,0>	; set FP_pathInfo to hold the
						;  path with DPI_EXISTS_LOCALLY
						;  set
		mov	ds:[FP_pathInfo], ax
		call	MemUnlock
		mov	bx, si			; return std path to
						; caller. 
done:
		.leave
		ret
maybeCreate:
		lds	dx, ss:[pathTail]
		mov	bx, ss:[stdPath]
		call	StdPathDoesntExist
		jc	done
		jmp	tryAgain
SetCurPathUsingStdPathWhenStdPathsNotEnabled endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	InitForPathEnum

DESCRIPTION:	Initialize variables for enumerating paths

CALLED BY:	FileOpen, FileEnum

PASS:
	bx	= std path for operation, if any
	cx	= non-zero if ds:dx is path on which caller will be operating
	ds:dx	= path on which caller will be operating, if cx non-zero

RETURN:
	carry - set if error (don't call FinishWithPathEnum)
	ds:dx   = possibly modified to point to a different point in the path

DESTROYED:
	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP	segment	resource
InitForPathEnum		proc	far
	.enter
	jcxz	noCopy
	mov	ss:[TPD_dataBX], handle InitForPathEnumReal
	mov	ss:[TPD_dataAX], offset InitForPathEnumReal
	call	SysCallMovableXIPWithDSDX
done:
	.leave
	ret

noCopy:
	call	InitForPathEnumReal
	jmp	short	done
InitForPathEnum		endp
CopyStackCodeXIP	ends

else

InitForPathEnum		proc	far
	FALL_THRU	InitForPathEnumReal
InitForPathEnum		endp
endif

InitForPathEnumReal	proc	far
	uses ax, bx, ds
	.enter

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	movdw	bxsi, dsdx					>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx, si						>
endif

	;
	; If the caller has given us a path under the standard path, see if
	; it has any leading components. If it does, we need to be sure to be
	; actually *in* the passed standard path, not just under it, else
	; the caller won't be able to get to the file.
	;
	; The end result of this is cx is non-zero if the current directory
	; must have an empty tail.
	;
	; 10/26/92: just see if the tail is absolute, rather than looking
	; through the whole tail for a backslash, as that hoses things like
	; FileGetAttributes("abc\def") while within SP_DOCUMENT:\foo
	; -- ardeb
	; 
	jcxz	checkedTail
	
	push	di
	mov	di, dx
	clr	cx
SBCS <	cmp	{char}ds:[di], C_BACKSLASH				>
DBCS <	cmp	{wchar}ds:[di], C_BACKSLASH				>
	pop	di
	jne	checkedTail
	dec	cx			; empty tail needed
	LocalNextChar dsdx		; need to have this be relative for
					;  when passed to the IFS driver for
					;  each directory in the standard path,
					;  or it thinks the thing is absolute
checkedTail:

	; if no path block then bail

	call	FP_LoadVarSegDS
	mov	ax, ERROR_PATH_NOT_FOUND
	tst	ds:[loaderVars].KLV_stdDirPaths
	stc
	jz	done

EC <	test	bx, DISK_IS_STD_PATH_MASK	; standard path?	>
EC <	ERROR_Z	INIT_FOR_PATH_ENUM_CALLED_FOR_NON_STANDARD_PATH		>

	;
	; Always push at least once, as we'll need to play games with the
	; whole beast.
	; 
	call	FilePushDir

	;
	; See if the destination is the same as the current std path. If so,
	; then one push is enough.
	;

	mov_tr	ax, bx		; save passed std path

	;
	; We need to check both the Actual disk handle (stored in the
	; path's HM_otherInfo field), and make sure that the current
	; directory has no path tail.
	;

	mov	bx, ss:[TPD_curPath]
	cmp	ds:[bx].HM_otherInfo, ax
	jne	switch

	;
	; If we must, make sure there's a null path tail in the current
	; directory (check for a null character)
	;

	jcxz	done			; => don't have to be *in* std path,
					;  just under it

	call	FP_PathLockDS
	push	di
	mov	di, ds:[FP_path]
SBCS <	tst	{byte}ds:[di]						>
DBCS <	tst	{wchar}ds:[di]						>
	pop	di
	call	MemUnlock
	jz	done

switch:
	;
	; Not the same, so switch to the passed one...
	; 
	call	FileSetStandardPath
	
	;
	; Mark the path as needing to be biffed when popped to
	; 
	call	FP_PathLockDS
	mov	({StdPathPrivateData} ds:[FP_private]).SPPD_flags, \
				mask SPF_NUKE_ME
	call	MemUnlock

	;
	; And push again, so we can play with this thing instead.
	; 
	call	FilePushDir

	clc

done:
	.leave
	ret

InitForPathEnumReal	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SetDirOnPath

DESCRIPTION:	Set the physical current path to be the next directory on the
		path for the logical path. InitForPathEnum must have been
		called before this.

CALLED BY:	FileOpen, FileEnum

PASS:
	In curPath:
		FP_pathInfo.DPI_STD_PATH - current std path we're enuming
							(moves up tree)
		FP_pathInfo.DPI_ENTRY_NUMBER_IN_PATH - entry on DPI_STD_PATH
						that we last looked at

RETURN:
	ax - DirPathInfo
	bx - disk handle
	carry - set if error (no more paths)
	FP_pathInfo - updated
	thread's current path - set

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Use Int_SetDirOnPath to find the next physical directory for
	this std path.

	If Int_SetDirOnPath returned a standard path constant, then
	we've hit a link, and need to enumerate further.  To do this,
	create 2 new path blocks -- using the path tail stored in the
	private data after the link directory is set -- and set the
	"nested" flag in the first of these blocks, so
	FinishWithPathEnum will nuke the proper number of blocks.


	For example:
		the link "link1" in SP_DOCUMENT is  a link to
		the directory (SP_SYSTEM, foo).

		Int_SetDirOnPath will find the first directory called
		(SP_SYSTEM, foo), change to that directory, and return
		SP_SYSTEM to us.  The path block at this point has
		"foo" as the path tail in the private data.

		We create a new path block -- this will be our new
		"master" path block, and we set the current path to
		(SP_SYSTEM, foo), using the private data described
		above. 

		We set the NESTED flag in this block, so
		FinishWithPathEnum will know to nuke it.

		We then create a new path block via FilePushDir, so
		that we now have a new "working" block.

	When the nested enumeration is done, then we also have some
	code to go and nuke the nested path blocks, if they exist.


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version
	ardeb	8/8/91		changed for 2.0 FSDs
	CDB	8/17/92		changed for links

------------------------------------------------------------------------------@

SetDirOnPath	proc	far
	uses bx, cx, dx, si, ds, di
	.enter

	; Initialize the link recursion counter, since SetCurPath
	; expects it to be set up that way.
	;

	inc	ss:[TPD_stackBot]
	mov	di, ss:[TPD_stackBot]
	mov	{byte} ss:[di].CP_linkCount, 0
			

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di

	;
	; Fetch the current state of the enumeration from the current path,
	; along with the handle of the path block that holds the initial
	; path tail for us to use.
	; 
	call	FP_CurPathLockDS
	mov	ax, ds:[FP_pathInfo]
	mov	dx, ds:[FP_prev]
EC <	tst	dx							>
EC <	ERROR_Z	INIT_FOR_PATH_ENUM_NOT_CALLED_YET			>
	call	FileUnlockPath		; done with current, for now...
	;
	; Lock down the original path block from which we pushed in
	; InitForPathEnum so we can get the actual path tail. We also need
	; to load the FP_stdPath from the previous block, as it will have been
	; overwritten in the current path with SP_NOT_STANDARD_PATH by the
	; FSD.
	; 
	mov	bx, dx			; bx <- original std path block
	call	FP_PathLockDS
	lea	dx, ({StdPathPrivateData} ds:[FP_private]).SPPD_stdPathTail
	mov	cx, ds:[FP_stdPath]
	
	;
	; Use that and the state from the current path to set the next
	; current directory for this here thread.
	; 
   	push	bx			; save path block handle
	call	Int_SetDirOnPath		;bx = disk handle (if success)
	mov	dx, bx				; save disk handle
	pop	bx
	call	FileUnlockPath
	jc	error			; if error, don't alter current path

	;
	; New directory successfully set, so update the enumeration information
	; in the current path
	; 
	call	FP_CurPathLockDS
	mov	ds:[FP_pathInfo], ax
	call	FileUnlockPath
	
	;
	; If Int_SetDirOnPath returned us a standard path, then go into
	; a nested path enumeration.
	;

	test	dx, DISK_IS_STD_PATH_MASK
	jnz	stdPath

	;
	; Otherwise store the disk handle
	;

	call	FP_LoadVarSegDS
	mov	ds:[bx].HM_otherInfo, dx	;save disk handle

done:
	dec	ss:[TPD_stackBot]

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret

stdPath:

	;
	; Int_SetDirOnPath returned us a link to a standard path, so
	; we have to start another enumeration.  Take the current std
	; path, and tail (stored in the private data of the current
	; path), and create 2 new paths:
	;
	;	dx - standard path

	;
	; Call FilePushDir BEFORE accessing the standard path tail of
	; the previous path, since FilePushDir actually
	; places the CURRENT path block at the top of the stack
	;

	call	FilePushDir


	call	FP_PrevPathLockDS
	push	bx, dx
	mov	bx, dx		; standard path
	mov	dx, offset ({StdPathPrivateData}ds:[FP_private]).SPPD_stdPathTail

	;
	; Allow for bizarre path tails, such as those containing ".."
	; as their first component.  Since BX is a standard path, we
	; call SetCurPath rather than FileSetCurrentPath.  This avoids
	; calling FileConstructFullPath, which would give us a path
	; that didn't have a StandardPath as its disk handle.
	; What a nightmare...
	;

	call	SetCurPath
	pop	bx, dx
	call	FileUnlockPath
	jc	unableToSetPath

	;
	; Set the "Nested" flag, so we'll nuke it when we're done:
	;
	

	call	FP_CurPathLockDS
	ornf	({StdPathPrivateData} ds:[FP_private]).SPPD_flags, \
					mask SPF_NESTED
	call	FileUnlockPath

	;
	; Now, create another path block, that will be our working
	; version: 
	;

	call	FilePushDir
	;
	; Set the enumeration constant to the new standard
	; path that the link returned to us, and set the
	; DPI_EXISTS_LOCALLY flag, so we'll start enumeration at the
	; beginning. 
	;

	call	FP_CurPathLockDS
	ornf	dx, mask DPI_EXISTS_LOCALLY
	mov	ds:[FP_pathInfo], dx
	call	FileUnlockPath
	;
	; Now, get a REAL physical path
	;

	call	SetDirOnPath
	jmp	done


error:
	;
	; No more directories.  See if we're in a nested enumeration,
	; and if so, go up a level
	;

	call	FP_PrevPathLockDS
	test	({StdPathPrivateData} ds:[FP_private]).SPPD_flags, \
					mask SPF_NESTED
	call	FileUnlockPath
	stc
	jz	done
	
	;
	; We were in a nested enumeration.  Pop the top 2 paths, and
	; continue at the previous level.
	;

	call	FilePopDir
	call	FilePopDir

	call	SetDirOnPath
	jmp	done

unableToSetPath:

	;
	; We were unable to CD to the path returned to us by the link.
	; Remove any path blocks we created up to this point, and
	; propagate the error upwards.
	;

	call	FilePopDir
	jmp	done

SetDirOnPath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	FP_CurPathLockDS, FP_PrevPathLockDS, FP_PathLockDS, FP_MemLockDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Various locking routines, here to save bytes. The routines
		with "Path" in their names *must* be used for the locking
		of paths only

CALLED BY:	Internal
	
PASS:		BX	= Handle (path or memory)
			- or -
			for FP_CurPathLockDS, ss:[TPD_curPath] is used

RETURN:		DS	= Points to path of memory segment
		BX	= Handle of whatever was locked

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FP_PrevPathLockDS	proc	near
	uses	ax
	.enter
	call	FP_CurPathLockDS
	mov	ax, ds:[FP_prev]
	call	FileUnlockPath
	mov_tr	bx, ax
	call	FP_PathLockDS
	.leave
	ret
FP_PrevPathLockDS	endp


FP_CurPathLockDS	proc	near
	mov	bx, ss:[TPD_curPath]
	FALL_THRU	FP_PathLockDS
FP_CurPathLockDS	endp

FP_PathLockDS	proc	near
	push	ax
	call	FileLockPath
	mov	ds, ax
	pop	ax
	ret
FP_PathLockDS	endp

FP_MemLockDS	proc	near
	push	ax
	call	MemLock
	mov	ds, ax
	pop	ax
	ret
FP_MemLockDS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileLockPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down a path without causing ec-only deadlocks.

CALLED BY:	INTERNAL
PASS:		bx	= handle to lock down
RETURN:		ax	= segment of block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLD_ERROR_CHECK = ERROR_CHECK
ERROR_CHECK = FALSE

FileLockPath	proc near
		uses	ds
		.enter
		LoadVarSeg 	ds, ax
		FastLock1	ds, bx, ax, FLP1, FLP2
		.leave
		ret
		FastLock2	ds, bx, ax, FLP1, FLP2
FileLockPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileUnlockPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a path without causing ec-only deadlocks.

CALLED BY:	INTERNAL
PASS:		bx	= handle to unlock
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileUnlockPath	proc near
		uses	ds, ax
		.enter
		pushf
		LoadVarSeg	ds, ax
		FastUnLock	ds, bx, ax
		popf
		.leave
		ret
FileUnlockPath	endp

ERROR_CHECK = OLD_ERROR_CHECK
		


COMMENT @----------------------------------------------------------------------

FUNCTION:	Int_SetDirOnPath

DESCRIPTION:	Set the thread's current path to be the next directory on the
		path for the logical path

CALLED BY:	SetDirOnPath

PASS:
	cx - StandardPath
	ds:dx - path tail to set
	ax - DirPathInfo

RETURN:
	carry - set if error (no more paths)
	carry clear if successful:
		bx - disk handle (or standard path, if a link pointing
				to a standard path was encountered)
		ax - updated
		thread's path - set

DESTROYED:
	none

REGISTER/STACK USAGE:
	ds - paths block
	cx - DirPathInfo
	ax, bx, si, di - scratch

PSEUDO CODE/STRATEGY:
	Allocate a path buffer on the global heap, rather than the
	stack, to avoid stack overflow.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

Int_SetDirOnPath	proc	near	
		uses cx, di, si, ds

pathTail	local	fptr.char	push	ds, dx
logicalStdPath	local	StandardPath	push	cx
bufferHandle	local	hptr.PathName
stdPathHandle	local	hptr

	ForceRef	pathTail
	ForceRef	logicalStdPath
	ForceRef	bufferHandle

	.enter

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	movdw	bxsi, dsdx					>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx, si						>
endif

	mov_tr	cx, ax				; DirPathInfo

	; lock the kernel's std paths block

	call	FP_LoadVarSegDS
	mov	bx, ds:[loaderVars].KLV_stdDirPaths
	call	MemLockShared
	mov	ss:[stdPathHandle], bx
	mov	ds, ax				;ds = paths

	; look for this path

lookForEntry:
	call	FindNextPathEntry
	jc	notFound

	; found an entry, construct the full path and try to set it

	call	BuildPathEntry			;build entry in ss:bp
	jc	lookForEntry		; path doesn't exist, so keep
					;  traversing list

	; we've set the path, save our variables and leave (bx = disk handle)

	mov_tr	ax, cx
	jmp	done

	; we've run out of entries on this path, try moving up

notFound:
	mov	bx, cx
	and	bx, mask DPI_STD_PATH
	clr	ch			; do not set DPI_EXISTS_LOCALLY,
					; as the local version was dealt
					; with at the bottom level...

	call	FileGetStdPathParent
	mov	cx, bx			; cx - parent
	tst	cl
	jnz	lookForEntry
	stc

done:
	push	bx
	mov	bx, ss:[stdPathHandle]
	call	MemUnlockShared			;unlock paths
	pop	bx
	.leave
	ret

Int_SetDirOnPath	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindNextPathEntry

DESCRIPTION:	Find the next path entry in the paths block

CALLED BY:	Int_SetDirOnPath

PASS:
	ds - std path block
	cx - DirPathInfo. DPI_EXISTS_LOCALLY set (hack) if the first directory
	     on the path for the std path in DPI_STD_PATH is wanted. This 
	     could have been done by setting DPI_ENTRY_NUMBER_IN_PATH to -1,
	     but...

RETURN:
	cx, - updated
	carry - set if error (does not exist)
	if called with DPI_EXISTS_LOCALLY set and DPI_ENTRY_NUMBER_IN_PATH = 0
		si preserved
	else
		ds:si - std path string

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

FindNextPathEntry	proc	near	uses ax
	.enter

	test	cx, mask DPI_EXISTS_LOCALLY	; first time?
	jnz	10$
	inc	ch	; advance to next entry
10$:
	and	ch, not mask DPI_EXISTS_LOCALLY shr 8
		CheckHack <(offset DPI_ENTRY_NUMBER_IN_PATH eq 8) and \
			   (width DPI_ENTRY_NUMBER_IN_PATH eq 7) and \
			   (offset DPI_EXISTS_LOCALLY eq 15)>

	jz	exit	; => need to try local dir under top level, so
			;  ds:si doesn't matter worth beans. (carry cleared
			;  by AND)

	push	cx

	; get pointer to path. path block holds array of offsets to
	; individual path lists. We know if a logical path has no path
	; list if its offset is the same as that of the next logical path
	; in the array...

	mov	si, cx
	andnf	si, mask DPI_STD_PATH
	dec	si		; convert to word index (constants are odd
				;  and start with 1...)
	CheckHack <offset SDP_pathOffsets eq 0>
	lodsw						;ds:ax = path
	cmp	ax, ds:[si]				; any path there?
	jz	flipCarry		; same as next logical => no path list
					;  (carry clear)
	; skip any other paths

	mov_tr	si, ax
	mov	cl, ch
	clr	ch				;cx = entry # (clears carry)
	dec	cx
	jz	done			; => looking for first entry

skipLoop:
	LocalGetChar ax, dssi
	LocalIsNull ax
	jnz	skipLoop			;al = 0
SBCS <	cmp	al, ds:[si]		; double-null => that was the last >
DBCS <	cmp	ax, ds:[si]		; double-null => that was the last >
					;  path in the list?
	loopne	skipLoop
flipCarry:
	cmc		; set carry if out of list entries. if there were
			;  no entries in the path list, carry is clear when
			;  we get here (via a jz), so we'll set the carry to
			;  say we didn't find a path. If we fell through the
			;  loopne b/c ds:[si] wasn't 0 (i.e. cx decremented
			;  to 0), carry will be set when we get here (0 is
			;  below everything) so we'll clear the carry to signal
			;  we found a path. If we fell through the loopne
			;  b/c ds:[si] is 0, carry will be clear (b/c of
			;  == comparison), so we'll set the carry to signal
			;  no path found.
done:
	pop	cx
exit:
	.leave
	ret

FindNextPathEntry	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	BuildPathEntry

DESCRIPTION:	Construct the full path and set it

CALLED BY:	Int_SetDirOnPath

PASS:
	ss:bp - inherited variables
	cx - DirPathInfo
	if DPI_ENTRY_NUMBER_IN_PATH !=0
		ds:si - path (from paths block)

RETURN:
	carry - set if error (cannot set path)
	bx - disk handle

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

BuildPathEntry	proc	near	

	uses 	ax, cx, dx, si, di, ds

pathTail	local	fptr.char
logicalStdPath	local	StandardPath
bufferHandle	local	hptr.PathName
stdPathHandle	local	hptr

	.enter	inherit near

	;
	; If entry number is 0, then we need to build the local version of
	; the thing: use top-level path and pretend DirPathInfo is actually
	; for SP_TOP (doesn't affect our caller) so we add the proper
	; intervening components.
	; 
	push	cx		; save for optimization bit

	test	cx, mask DPI_ENTRY_NUMBER_IN_PATH
	jnz	useString
	LoadVarSeg	ds, si
	mov	si, cx
	andnf	si, mask DPI_STD_PATH		; si <- StandardPath
		CheckHack <type pathAttrs eq 1>
	shr	si				; convert to byte index
	test	ds:[pathAttrs][si], mask SPA_DOES_NOT_EXIST_LOCALLY
	LONG jnz	fail

	mov	si, offset loaderVars.KLV_topLevelPath
	mov	cx, DirPathInfo <1,0,SP_TOP>
useString:

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx						>
EC<	mov	bx, ds						>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx						>
endif

	clr	dh
	mov	dl, cl				;dx = std path
		CheckHack <width DPI_STD_PATH eq 8 and \
			   offset DPI_STD_PATH eq 0>

	; Example: Logical path: "c:/geoworks/document/tech_doc"
	;	   entry in .ini file: top = "g:/netgeos"
	;	ds:si = "g:/netgeos"
	;	dx = SP_TOP
	;	logicalStdPath = SP_DOCUMENT
	;	pathTail = "tech_doc"
	;
	;	Result: "g:/netgeos/document/tech_doc"

	call	FileAllocPathNameBuffer
	jc	done

	mov	ss:[bufferHandle], bx

	mov	cx, size PathName
	call	CopyNTStringCXMaxPointAtNull	;copy path entry

	; copy difference between std path that entry is for and std of
	; logical path

	push	bp
	mov	bp, ss:[logicalStdPath]
	cmp	dx, bp
	je	afterCopyDiff

	mov	bx, handle StandardPathStrings
	call	FP_MemLockDS
	mov_tr	ax, dx				;ax = place to stop

	; if already ends in backslash, back up, as CSPC will put one in, too
SBCS <	cmp	{char}es:[di-1], C_BACKSLASH				>
DBCS <	cmp	{wchar}es:[di-2], C_BACKSLASH				>
	jne	copyDiff
	inc	cx
	LocalPrevChar esdi
copyDiff:
	call	CopyStandardPathComponents
	call	MemUnlock

afterCopyDiff:
	pop	bp

	;copy tail of path

	lds	si, ss:[pathTail]
SBCS <	cmp	{char} ds:[si], 0					>
DBCS <	cmp	{wchar} ds:[si], 0					>
	jz	noTail
	LocalLoadChar ax, C_BACKSLASH
SBCS <	cmp	es:[di-1], al						>
DBCS <	cmp	es:[di-2], ax						>
	je	copyTail
	LocalPutChar esdi, ax
copyTail:
	call	CopyNTStringCXMaxPointAtNull
noTail:

	; try to set path. first get the disk handle for the disk on which
	; the path resides, then ask the FSD responsible for that disk to
	; set the thread's current path.

	mov	bx, 1				;don't look for standard path
	segmov	ds, es			; ds:dx - pathname
	clr	dx
	call	FileGetDestinationDisk
	pop	cx
	jc	setOptimizationBit

	;
	; Call the FSD to set the current path, and then free the
	; pathname buffer.
	;

	call	SetCurPath
	jc	setOptimizationBit

freeBuffer:
	pushf
	push	bx
	mov	bx, ss:[bufferHandle]
	call	MemFree
	pop	bx
	popf

done:
	.leave
	ret

setOptimizationBit:
	;
	; Couldn't set the path that was built; if the built path was
	; the local version, then set the SPA_DOES_NOT_EXIST_LOCALLY
	; optimization flag for this directory and all its children.
	; so we don't try this again.
	; 
	test	cx, mask DPI_ENTRY_NUMBER_IN_PATH
	stc
	jnz	freeBuffer		; => not local, so no opt bit.
	lds	si, ss:[pathTail]	; empty path tail?
SBCS <	cmp	{char}ds:[si], 0					>
DBCS <	cmp	{wchar}ds:[si], 0					>
	jne	errorFreeBuffer		; no => don't set opt bit, as we don't
					;  know for sure that std path itself
					;  doesn't exist locally

	push	bx
	call	FP_LoadVarSegDS
		CheckHack <width DPI_STD_PATH eq 8 and offset DPI_STD_PATH eq 0>
	mov	bx, cx			; bl <- root of tree of standard
					;  paths that don't exist
	call	setOptimizationBitForTree
	pop	bx

errorFreeBuffer:
	stc
	jmp	freeBuffer

fail:
	;
	; Attempting to set local dir and local is marked as not existing,
	; so just fail now.
	; 
	pop	cx
	stc
	jmp	done

	;--------------------
	; Pass:		bl	= StandardPath
	; 		ds	= kdata
	; Return:	nothing
	; Destroyed:	si, bx
setOptimizationBitForTree:
	;
	; First set the bit for this path.
	; 
	clr	bh
	mov	si, bx
		CheckHack <type pathAttrs eq 1>
	shr	si			; convert to byte index
	ornf	ds:[pathAttrs][si], mask SPA_DOES_NOT_EXIST_LOCALLY

	;
	; Now recurse on all the children.
	; 
	call	FileGetStdPathFirstChild; bl <- first child, or 0
sOBLoop:
	tst	bl			; done?
	jz	sOBDone

	push	bx
	call	setOptimizationBitForTree
	pop	bx
	call	FileGetStdPathNextSibling; bl <- next child or 0
	jmp	sOBLoop

sOBDone:
	retn
BuildPathEntry	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileAllocPathNameBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a buffer large enough to hold a PathName
		structure.  Return a pointer to it in es:di

CALLED BY:	BuildPathEntry, SetCurPathUsingStdPathWhenStdPathsNotEnabled

PASS:		nothing 

RETURN:		if allocated:
			carry clear
			bx - handle
			es:di - address (es = segment addr, di = 0)

		else
			carry set
			ax - FileError (ERROR_INSUFFICIENT_MEMORY)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileAllocPathNameBuffer	proc near
	uses	cx
	.enter

	mov	ax, size PathName
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAllocFar
	jc	error
	mov	es, ax
	clr	di
done:

	.leave
	ret
error:
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	jmp	done
FileAllocPathNameBuffer	endp





COMMENT @----------------------------------------------------------------------

FUNCTION:	FinishWithPathEnum

DESCRIPTION:	Called after completion of path enumeration

CALLED BY:	FileOpen, FileEnum

PASS:
	none

RETURN:
	none

DESTROYED:
	none (flags preserved)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	If we got ourselves into a nested enumeration because of
	links, then we need to make sure to get rid of all the extra
	paths. 

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

FinishWithPathEnum	proc	far
	uses	ds, bx, ax
	.enter
	pushf

startLoop:
	call	FilePopDir


	;
	; If the nested flag is set, remove the top path, and
	; then "recurse"
	;

	call	FP_CurPathLockDS
	mov	al, ({StdPathPrivateData} ds:[FP_private]).SPPD_flags
	call	MemUnlock

	test	al, mask SPF_NESTED
	jz	notNested

	call	FilePopDir
	jmp	startLoop

notNested:

	;
	; If the NUKE ME flag is set, then do so.
	;
	test	al, mask SPF_NUKE_ME
	jz	done
	call	FilePopDir

done:
	popf
	.leave
	ret
FinishWithPathEnum	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDeletePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a path block, letting the managing FSD know of its
		demise.

CALLED BY:	FileDeletePathStack and others
PASS:		bx	= handle to nuke
RETURN:		nothing
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDeletePath	proc	far
		.enter
	;
	; Let the FSD on which the path resides know the path is going away.
	;
		call	FSDInformOldFSDOfPathNukage
	;
	; Free up the path block.
	; 
		call	MemFree
		.leave
		ret
FileDeletePath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDeletePathStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete all the saved paths for the current thread, along
		with the thread's current path.

CALLED BY:	ThreadDestroy
PASS:		ss	= thread stack
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDeletePathStack proc far
		call	PushAllFar

		mov	bx, ss:[TPD_curPath]
nukeLoop:
		tst	bx
		jz	done
		call	FP_PathLockDS
		mov	si, ds:[FP_prev]
		call	MemUnlock
		call	FileDeletePath
		mov	bx, si
		jmp	nukeLoop
done:
		mov	ss:[TPD_curPath], 0

		call	PopAllFar
		ret
FileDeletePathStack endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCurPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to set the current path. If a link is
		encountered, then traverse it.

CALLED BY:	BuildPathEntry, FileSetCurrentPath,
		SetCurPathUsingStdPathWhenStdPathsNotEnabled,
		SetDirOnPath, SetCurPath

PASS:		bx - disk handle, or standard path
		ds:dx - path to set

RETURN:		if path was set:
			carry clear
			ax = destroyed
			bx = disk handle, or Std Path
		else
			carry set
			ax = error code

DESTROYED:	si,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This procedure assumes that the byte just below TPD_stackBot
is being used as a link recursion counter. As such, it can only be
called (directly or indirectly) by routines that set this up
(FileSetCurrentPath and SetDirOnPath).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetCurPath	proc near
		uses	bp, es

		.enter
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	movdw	bxsi, dsdx					>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx, si						>
endif

	;
	; Increment the link (recursion) counter so we'll know if
	; we're getting into trouble
	;
		mov	bp, ss:[TPD_stackBot]
		inc	{byte} ss:[bp].CP_linkCount
		cmp	{byte} ss:[bp].CP_linkCount, MAX_LINK_COUNT
		
		jne	linkCountOK
		mov	ax, ERROR_TOO_MANY_LINKS
		stc
		jmp	done

linkCountOK:

		mov	bp, bx		; passed disk handle / std
					; path

	;
	; See if (bx) is a standard path or a disk handle
	;

		test	bx, DISK_IS_STD_PATH_MASK
		jz	diskHandle
	
	;
	; It's a std path, so call one of the std path routines.
	;

		push	ds
		call	FP_LoadVarSegDS
		tst	ds:[loaderVars].KLV_stdDirPaths
		pop	ds

		jz	pathsNotEnabled

		call	SetCurPathUsingStdPath
		jmp	afterCall

pathsNotEnabled:
		call	SetCurPathUsingStdPathWhenStdPathsNotEnabled
		jmp	afterCall

	;
	; Load disk handle into si for DiskLockCallFSD and go make the
	; change, ensuring the disk is in its drive before contacting the
	; FSD.
	; 

diskHandle:


	;
	; Lock the FSIR for DiskLockCallFSD to use.
	; 
		call	FileLockInfoSharedToES

		push	bp
		mov	si, bx			; disk handle
		mov	di, DR_FS_CUR_PATH_SET
		clr	al			; allow lock aborts
		call	DiskLockCallFSD
		pop	bp

		call	FSDUnlockInfoShared

		jnc	storeActual

		cmp	ax, ERROR_LINK_ENCOUNTERED
		stc
LONG		jne	done

	;
	; A link was encountered, so follow it, and try again.
	; bx = mem handle of link data
	;
link::

		push	ds, dx, cx
		push	bx

	;
	; Fetch the link data and then set the new returned path,
	; unless we can't
	;

		call	FileGetLinkData
		jc	afterSet

		call	SetCurPath
		mov	cx, bx		; returned disk handle
afterSet:
		pop	bx
		pushf
		call	MemFree
		popf

		mov	bx, cx		; returned disk handle
		pop	ds, dx, cx
		
afterCall:

	;
	; bx - disk handle returned from called routine
	;

		jc	done

storeActual:
	;
	; We know that we've finally set a REAL directory.  Store the
	; ACTUAL disk in the otherInfo field, to be used when calling
	; the FS driver.  The logical disk is whatever the caller
	; wants it to be...
	;
	;	bx = actual disk handle

		push	ds
		call	FP_LoadVarSegDS
		mov_tr	ax, bx			; actual disk handle
		mov	bx, ss:[TPD_curPath]
		mov	ds:[bx].HM_otherInfo, ax
		mov_tr	bx, ax			; returned disk handle
		pop	ds			; ds:dx - path tail
		segmov	es, ds, di
	;
	; Figure out the length of the path tail
	;
		push	bx, cx
		mov	di, dx		;es:di <- ptr to string
if DBCS_PCGEOS
		call	LocalStringSize	;cx <- size of user-specified path
		LocalNextChar	escx	;cx <- size with NULL
else
		clr	al
		mov	cx, -1
		repne	scasb
		not	cx		; size of user-specified path
endif

	;
	; Reallocate the path block to fit.
	;
		
		mov	bx, ss:[TPD_curPath]
		call	FileLockPath
		mov	es, ax

		push	cx		; size of path
		add	cx, es:[FP_path]
		mov_tr	ax, cx
		clr	ch
		call	MemReAlloc
		pop	cx
		jnc	copyIt
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	unlock
	;
	; copy the path data in
	;
copyIt:
		mov	es, ax
		mov	si, dx
		mov	di, es:[FP_path]
DBCS <		shr	cx, 1			;cx <- # of chars	>
		LocalCopyNString		;rep movsb/movsw

	;
	; Set the logical disk handle as well
	;
		mov	es:[FP_logicalDisk], bp

	;
	; Decrement the link (recursion) counter
	;
		
		mov	bp, ss:[TPD_stackBot]
		dec	{byte} ss:[bp].CP_linkCount		
EC <		ERROR_S GASP_CHOKE_WHEEZE			>

unlock:
		call	MemUnlock
		pop	bx, cx
		
done:
		.leave
		ret
SetCurPath	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FilePushTopLevelPath

DESCRIPTION:	Replaces KLV_topLevelPath with the passed 

CALLED BY:	RESTRICTED GLOBAL

PASS: 		ds:si - Null-terminated string to copy into KLV_topLevelPath

RETURN:		carry set if error (ax = error code)

DESTROYED:	ax, ds

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	14 april 1993	initial revision

------------------------------------------------------------------------------@
if FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment
FilePushTopLevelPath	proc	far
	mov	ss:[TPD_dataBX], handle FilePushTopLevelPathReal
	mov	ss:[TPD_dataAX], offset FilePushTopLevelPathReal
	GOTO	SysCallMovableXIPWithDSSI
FilePushTopLevelPath	endp
CopyStackCodeXIP		ends
else

FilePushTopLevelPath	proc	far
	FALL_THRU	FilePushTopLevelPathReal
FilePushTopLevelPath	endp
endif

FilePushTopLevelPathReal	proc	far	
		uses	cx, di, si, es
		.enter

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx						>
EC<	mov	bx, ds						>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx						>
endif

	;
	; set both topLevelDiskHandle and loaderVars.KLV_topLevelPath
	;

		call	FilePushPopTopLevelPathCommon
						;sets es = kdata
		jc	done			;skip if error (ax = error)...

	;
	;  Clear the SPA_DOES_NOT_EXIST_LOCALLY bit in each of the paths by
	;  shifting them into the backup positions
	;

		mov	si, StandardPath/2 - 1
		segmov	ds, es

clearLoop:
		shl	ds:[pathAttrs][si]
		dec	si
		jns	clearLoop

		clc				;no error

done:
		.leave
		ret
FilePushTopLevelPathReal	endp


FilePushPopTopLevelPathCommon	proc	near
		uses	bx
		.enter
	;
	; Determine the handle of the top-level path from the passed string
	;

		push	dx

		mov	dx, si			;ds:dx = path
		mov	bx, TRUE		;don't check to see if is
						;subdir of a std path.
		call	FileGetDestinationDisk	;bx = disk handle
						;sets carry and AX if error

		pop	dx
		jc	done			;skip to end if error...

		LoadVarSeg	es
		mov	es:[topLevelDiskHandle], bx

	;
	;  Write the passed string into KLV_topLevelPath
	;

		mov	di, offset loaderVars.KLV_topLevelPath
		mov	cx, size loaderVars.KLV_topLevelPath
		call	CopyNTStringCXMaxPointAtNull

		clc				;no error

done:
	;
	;return with carry set if error
	;return es = kdata
	;
		.leave
		ret
FilePushPopTopLevelPathCommon	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FilePopTopLevelPath

DESCRIPTION:	Replaces KLV_topLevelPath with the passed 

CALLED BY:	INTERNAL

PASS: 		ds:si - Null-terminated string to copy into KLV_topLevelPath

RETURN:		carry set if error (ax = error code)

DESTROYED:	ax, ds

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	14 april 1993	initial revision

------------------------------------------------------------------------------@
if FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment
FilePopTopLevelPath	proc	far
	mov	ss:[TPD_dataBX], handle FilePopTopLevelPathReal
	mov	ss:[TPD_dataAX], offset FilePopTopLevelPathReal
	GOTO	SysCallMovableXIPWithDSSI
FilePopTopLevelPath	endp
CopyStackCodeXIP		ends

else

FilePopTopLevelPath	proc	far
	FALL_THRU	FilePopTopLevelPathReal
FilePopTopLevelPath	endp
endif

FilePopTopLevelPathReal	proc	far	
		uses	cx, di, si, es
		.enter

	;
	; set both topLevelDiskHandle and loaderVars.KLV_topLevelPath
	;

		call	FilePushPopTopLevelPathCommon
						;sets es = kdata
		jc	done			;skip if error (ax = error)...

	;
	;  Restore the SPA_DOES_NOT_EXIST_LOCALLY bit by shifting right
	;

		mov	si, StandardPath/2 - 1
		segmov	ds, es

clearLoop:
		shr	ds:[pathAttrs][si]
		dec	si
		jns	clearLoop

		clc				;no error

done:
	;
	;return with carry set if error
	;

		.leave
		ret
FilePopTopLevelPathReal	endp

FileCommon	ends

;------------------------------------------------------

FileSemiCommon segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileEnsureLocalPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take the passed destination name as a file or directory
		that will be created and, if it's within a standard
		path (*not* a subdirectory of a standard path), make sure
		that the appropriate directories exist in the local
		tree under SP_TOP.

CALLED BY:	FileCreate, FileCreateDir, FileCopy, FileMove,
		FileCreateLink 

PASS:		ds:dx	= destination path, relative to current dir
RETURN:		carry set if paths couldn't be created (!)
			ax	= error code
		carry clear if all is good
			ax	= destroyed
DESTROYED:	nothing (except ax, of course)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment
FileEnsureLocalPath	proc	far
	mov	ss:[TPD_dataBX], handle FileEnsureLocalPathReal
	mov	ss:[TPD_dataAX], offset FileEnsureLocalPathReal
	GOTO	SysCallMovableXIPWithDSDX
FileEnsureLocalPath	endp
CopyStackCodeXIP		ends
else

FileEnsureLocalPath	proc	far
	FALL_THRU	FileEnsureLocalPathReal
FileEnsureLocalPath	endp
endif

FileEnsureLocalPathReal proc far
createBuf	local	PathName
		uses	bx, cx, es, di, si, dx, ds
		.enter

	;
	; Build the full path for the destination, skipping the drive
	; specifier, as we'll get back a disk handle, thanks.
	; 
		mov	si, dx			; ds:si <- tail
		segmov	es, ss
		lea	di, ss:[createBuf]	; es:di <- buffer
		mov	cx, size createBuf	; cx <- buffer size
		clr	bx			; prepend current dir
		clr	dx			; no drive spec, thanks
		call	FileConstructFullPath	; es:di <- null
	;
	; Trim off the final component.
	; 
		lea	cx, ss:[createBuf]
		sub	cx, di
		neg	cx		; cx <- path len w/o null
		std
		LocalPrevChar esdi	; don't check null
SBCS <		mov	al, C_BACKSLASH					>
DBCS <		mov	ax, C_BACKSLASH					>
SBCS <		repne	scasb						>
DBCS <		repne	scasw						>
		cld
		jcxz	doneOK		; => dest is in root, which means we've
					;  nothing to create, even if \ is
					;  SP_TOP
SBCS <		mov	{char}es:[di+1], 0				>
DBCS <		mov	{wchar}es:[di+2], 0				>
	;
	; Armed with that, try and parse the whole thing down to a standard
	; path.
	; 
		lea	di, ss:[createBuf]
		call	FileParseStandardPath
		cmp	ax, SP_TOP
			CheckHack <SP_TOP eq 1>
		jbe	doneOK		; not S.P., or SP_TOP (which must
					;  exist), so nothing to do
		
SBCS <		tst	{char}es:[di]	; any tail?			>
DBCS <		tst	{wchar}es:[di]	; any tail?			>
		jnz	doneOK		; => should be in some directory of
					;  the S.P., so nothing to do

		lea	dx, ss:[createBuf]
		call	FileCreateLocalStdPath
		jc	doneOK
	;
	; Now adjust the FP_pathInfo for the current path so we try the local
	; path again...
	;
	 	mov	bx, ss:[TPD_curPath]
		call	MemLock
		mov	ds, ax
			CheckHack <width DPI_STD_PATH eq 8 and \
				   offset DPI_STD_PATH eq 0>
		mov	al, ds:[FP_stdPath].low
		mov	ah, DirPathInfo <1,0,0> shr 8
		mov	ds:[FP_pathInfo], ax
		call	MemUnlock
		clc
doneOK:
	;
	; Little whatsits to clear the carry and finish; stuck here to make
	; sure it's not out of reach of the branches to it...
	; 
		clc
		.leave
		ret
FileEnsureLocalPathReal endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCreateLocalStdPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the local version of a standard path.

CALLED BY:	FileEnsureLocalPath, StdPathDoesntExist
PASS:		ax	= StandardPath that's the last thing to create
		es:di	= null char after final component. Chars leading up
			  to this must be the full path to AX
		es:dx	= start of full path
		bx	= topLevelDiskHandle
RETURN:		carry set if directories couldn't be created.
			ds	= destroyed
			ax	= error code
		carry clear if everything's ok:
			ds	= es on entry
DESTROYED:	di, dx, si, cx, es
		null-terminator in passed path is replaced by a backslash...

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCreateLocalStdPath proc far
topLevelDisk	local	word	push bx
notifyPath	local	StandardPath
		uses	bp, bx, ax
		.enter
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	movdw	bxsi, esdi					>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	mov	si, dx						>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx, si						>
endif
	;
	; We need to clear the SPA_DOES_NOT_EXIST_LOCALLY bit in pathAttrs
	; for each component we create, so we first work our way back
	; through the path, using stdPathUpwardTree to find the S.P. at
	; each level, pushing the S.P. and the component end address
	; on the stack. When we get to SP_TOP, we pop things and do
	; the creation and adjustment until we're back where we started.
	;
	; To make life simpler, we assume we'll be successful in creating the
	; components, so we clear the SPA_DOES_NOT_EXIST_LOCALLY as we're
	; working our way up the tree. It doesn't hurt anything if we end up
	; being wrong...
	; 
	; 	
		mov_tr	bx, ax		; bx <- current S.P.

		clr	ax
		mov	ss:[notifyPath], ax
		
		push	ax		; push sentinel
		push	ax		; ditto
		LocalPrevChar esdi	; point to last char of component, as
					;  it'll be for everything else
		LoadVarSeg	ds, ax	; for clearing SPA_D_N_E_L
SBCS <		mov	al, C_BACKSLASH	; load these once		>
DBCS <		mov	ax, C_BACKSLASH					>
		mov	cx, -1
findComponentLoop:
		mov	si, bx
			CheckHack <type pathAttrs eq 1>
	;
	; Convert the S.P. to a byte index for the pathAttrs 
	; array and clear the SPA_DOES_NOT_EXIST_LOCALLY flag.
	; 
		push	si		; save component SP constant for
					;  possibly setting notifyPath
		push	di		; save component end
		shr	si
		andnf	ds:[pathAttrs][si], not mask SPA_DOES_NOT_EXIST_LOCALLY
	;
	; Now fetch the parent path and stop if we've reached SP_TOP, as we've
	; no need to create *that*
	; 
		call	FileGetStdPathParent
		cmp	bx, SP_TOP
		je	processComponents
	;
	; Scan backward for the next backslash, leaving DI pointing to the
	; last char of the component before it. CX started at -1 and continues
	; to decrement...
	; 
		std
SBCS <		repne	scasb						>
DBCS <		repne	scasw						>
		cld
		jmp	findComponentLoop

processComponents:
	;
	; All components have been found. It's now time to process them.
	; On the stack we have all the successive offsets to the last
	; char of each component, in the proper downward-travelling order, and
	; a sentinel value of 0 to tell us when to stop.
	;
	; Point ds:dx to the start of the buffer holding the full path for
	; the duration of the loop.
	; 
		mov	bx, ss:[topLevelDisk]

		segmov	ds, es			; ds:dx <- dir to create next
	;
	; Lock the FSIR shared for calling the FSD
	; 
		call	FileLockInfoSharedToES	; for calling the FSD...

processComponentLoop:
	;
	; Fetch the end of the next component. If 0, we've hit the sentinel
	; and are finished.
	; 
		pop	cx			; cx <- path end
		pop	si			; si <- std path constant for
						;  this thing
		jcxz	maybeNotify
		mov	di, cx
		
SBCS <		mov	{char}ds:[di+1], 0	; terminate the path after the>
DBCS <		mov	{wchar}ds:[di+2], 0	; terminate the path after the>
						;  final char of the component
	;
	; Now call the FSD to create that directory, using the absolute path
	; we've got in createBuf, pointed to by ds:dx
	; 
		xchg	si, bx			; es:si <- DiskDesc
						; bx <- standard path being
						;  created
		mov	ax, FSPOF_CREATE_DIR shl 8	; al is 0 to allow
							;  disk lock to be
							;  aborted
		mov	di, DR_FS_PATH_OP
		push	bp
		call	DiskLockCallFSD
		pop	bp
		xchg	bx, si			; es:bx <- DiskDesc
						; si <- std path constant
	;
	; Restore the backslash we biffed after this component, in case there's
	; another one coming.
	; 
		mov	di, cx
SBCS <		mov	{char}ds:[di+1], C_BACKSLASH			>
DBCS <		mov	{wchar}ds:[di+2], C_BACKSLASH			>
		jnc	recordTopCreated	; => happy, so remember this
						;  as highest path created,
						;  if nothing above us was
						;  happy...
	;
	; Error occurred during the call. If it's ERROR_FILE_EXISTS, we're
	; happy. Anything else and we have to bail.
	; 
		cmp	ax, ERROR_FILE_EXISTS
		je	processComponentLoop
clearStackLoop:
		pop	cx			; nuke path end
		pop	si			; nuke std path const
		tst	cx
		jnz	clearStackLoop
		stc

maybeNotify:
		mov	ax, ss:[notifyPath]	;AX <- highest standard path
						; created
		jc	unlockFSIR
		tst	ax
		jz	unlockFSIR

;	If we created the directory, then send out a notification

		push	si, cx, dx
		mov	si, FCNT_ADD_SP_DIRECTORY
		call	FSP_GenerateNotify
		pop	si, cx, dx

unlockFSIR:
	;
	; Creation is complete, either successfully or not, so release the
	; FSIR and return.
	; 
		call	FSDUnlockInfoShared
		.leave
		ret

recordTopCreated:
		cmp	ss:[notifyPath], SP_NOT_STANDARD_PATH
		jne	processComponentLoop
		mov	ss:[notifyPath], si
		jmp	processComponentLoop
FileCreateLocalStdPath endp

FileSemiCommon ends

;-------------------------------------------------------

Filemisc segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileResolveStandardPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the actual path to a file, resolving links and
		standard paths, etc.  NOTE:  If one of the components
		of the CWD is a link, will NOT resolve that component.

CALLED BY:	GLOBAL
PASS:		ds:dx	= path to find
		es:di	= buffer in which to place the result. 
		cx	= size of that buffer
		ax	= FRSPFlags
RETURN:		carry set if file not found:
			bx	= destroyed
		carry clear if found:
			es:di	= points to null-terminator at end of absolute
				  path.
			bx	= disk handle
			al	= FileAttrs of found file/dir
DESTROYED:	ah, cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/27/92		Initial version
	chrisb  10/19/92	Modified to also work on standalone systems

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileResolveStandardPath		proc	far
	mov	ss:[TPD_dataBX], handle FileResolveStandardPathReal
	mov	ss:[TPD_dataAX], offset FileResolveStandardPathReal
	GOTO	SysCallMovableXIPWithDSDX
FileResolveStandardPath		endp
CopyStackCodeXIP		ends

else

FileResolveStandardPath		proc	far
	FALL_THRU	FileResolveStandardPathReal
FileResolveStandardPath		endp

endif


FileResolveStandardPathReal proc	far
flags		local	FRSPFlags	push ax
resultBuf	local	fptr.char	push es, di
resultBufSize	local	word		push cx
resultDisk	local	word
resultAttrs	local	FileAttrs
originalDisk	local	word

	ForceRef	flags		; FRSP_callback
	ForceRef	resultBufSize	; FRSP_callback

		uses	si, dx, es
		.enter

		clr	ss:[originalDisk]
		call	FileLockInfoSharedToES

	;
	; If the passed path contains a drive specifier, then push to
	; the root of that drive
	;
		push	dx
		call	DriveLocateByName
		pop	dx
		call	FSDUnlockInfoShared
		jc	done		; no drive known of that name
		tst	si
		jz	opOnPath

	;
	; A drive was passed, so get its disk handle, and push to the root
	;
		clr	bx
		call	FileGetDestinationDisk
		jc	done

		mov	ss:[originalDisk], bx
		mov	cx, bx
		jcxz	opOnPath		; we won't pop, so don't push
		call	PushToRoot
		jc	done
opOnPath:

		mov	bx, bp
		mov	si, SEGMENT_CS
		mov	di, offset FRSP_callback
		call	FileOpOnPathFar

	;
	; Restore the cwd, if we changed it
	;

		pushf
		tst	ss:[originalDisk]
		jz	afterPop
;this is not needed, as non-zero originalDisk means we've pushed, fixes
;dir stack leak
;		test	ss:[originalDisk], DISK_IS_STD_PATH_MASK
;		jnz	afterPop

		call	FilePopDir
afterPop:
		popf
		jc	done
		mov	di, ss:[resultBuf].offset
		mov	bx, ss:[resultDisk]
		mov	al, ss:[resultAttrs]
done:
		.leave
		ret
FileResolveStandardPathReal endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FRSP_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to see if the destination path exists in
		the current directory and build an absolute representation of
		it into the given buffer, getting its disk handle, etc.

CALLED BY:	FileResolveStandardPath via FileOpOnPath
PASS:		ds:dx	= file being sought
		es	= FSIR locked shared
		si	= disk handle 
		ss:bx	= frame inherited from FileResolveStandardPath
RETURN:		carry set if file not found:
			ax	= error code
DESTROYED:	bp, cx, di, si

PSEUDO CODE/STRATEGY:
	If we're in a standard path enumeration, then prepend the CWD
	in our call to FileConstructFullPath, otherwise, just use the
	passed disk handle.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/28/92		Initial version
	chrisb  10/92		changed to return logical, not actual
				disk handle

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FRSP_callback	proc	far
		uses	es
		.enter	inherit	FileResolveStandardPathReal
if FULL_EXECUTE_IN_PLACE
EC<	push	bx, si						>
EC<	movdw	bxsi, dsdx					>
EC<	call	ECAssertValidTrueFarPointerXIP			>
EC<	pop	bx, si						>
endif
		mov	bp, bx		; ss:bp <- frame
	;
	; If asked to, then always build in first directory.
	; 
		clr	cl		; no attribute set (assume file)
		test	ss:[flags], mask FRSPF_RETURN_FIRST_DIR
		jnz	buildResult
	;
	; If passed null path or ".", then resolve to current dir.
	; 
		mov	cl, mask FA_SUBDIR
		mov	di, dx
SBCS <		cmp	{char}ds:[di], 0				>
DBCS <		cmp	{wchar}ds:[di], 0				>
		je	buildResult
SBCS <		cmp	{word}ds:[di], '.' or (0 shl 8)			>
DBCS <		cmp	{wchar}ds:[di], '.'				>
DBCS <		jne	notCurrentDir					>
DBCS <		cmp	{wchar}ds:[di][2], 0				>
		je	buildResult
DBCS <notCurrentDir:							>
	;
	; Call the FSD to see if the thing exists.
	; 
		mov	di, DR_FS_PATH_OP
		mov	ax, FSPOF_GET_ATTRIBUTES shl 8	; al is clear so
							;  disk lock may be
							;  aborted
		push	bp
		call	DiskLockCallFSD
		pop	bp
		jc	done

buildResult:
	;
	; Store the disk & file attributes into the result buffer first.
	; 
		les	di, ss:[resultBuf]
		mov	ss:[resultAttrs], cl
		mov	ss:[resultDisk], si
	
	;
	; Now build the full path into the buffer, using the current directory,
	; if appropriate.
	; 
		mov	si, dx
		push	dx
		mov	dx, ss:[flags]
		andnf	dx, mask FRSPF_ADD_DRIVE_NAME	; non-zero if want
							;  drive spec.
		clr	bx		; prepend current dir
		mov	cx, ss:[resultBufSize]
		call	FileConstructFullPath
		mov	ss:[resultDisk], bx
		mov	ss:[resultBuf].offset, di
		pop	dx
		clc
done:		
		.leave
		ret
FRSP_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetCurrentPathIDs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return an array of FilePathID structures for the current path,
		for use in handling file-change notification messages.

CALLED BY:	GLOBAL
PASS:		ds	= segment of LMem block in which to allocate the array
RETURN:		carry set on error:
			ax	= FileError
		carry clear if ok:
			ax	= chunk handle of array
		ds	= fixed up
DESTROYED:	nothing
	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetCurrentPathIDs proc	far
		uses	si, di, bp, dx, bx, cx
		.enter
		
	;
	; Allocate an empty chunk in the block initially, so we've got a
	; chunk handle we can use.
	; 
		mov	al, mask OCF_DIRTY
		clr	cx
		call	LMemAlloc
		
	;
	; Pass ss:bx -> chunk, segment to our getID callback routine.
	; 
			CheckHack <@CurSeg eq Filemisc>
		push	ds, ax
		mov	bx, sp

SBCS <		mov	dx, C_PERIOD or C_NULL shl 8	; '.', null	>
SBCS <		push	dx						>
DBCS <		LocalClrChar	dx			; null		>
DBCS <		push	dx						>
DBCS <		mov	dx, C_PERIOD			; '.'		>
DBCS <		push	dx						>
		segmov	ds, ss		;DS:DX - ptr to '.',0
		mov	dx, sp
		mov	si, SEGMENT_CS
		mov	di, offset getID
		call	FileOpOnPathFar
		pop	dx		;Get '.',0 off stack
DBCS	<	pop	dx						>
		pop	ds, dx		; ds <- fixed-up segment,
					;  dx <- chunk handle

		xchg	ax, dx		; ax <- chunk handle, in case ok
					; dx <- error code, in case not ok
		jnc	exit
	;
	; ERROR_FILE_NOT_FOUND is a normal side-effect of how we have to do
	; things, unless the resulting array is zero-sized.
	; 
		cmp	dx, ERROR_FILE_NOT_FOUND
		jne	freeChunk
		
		mov	si, ax
		cmp	{word}ds:[si], -1	; any memory?
		clc
		jne	exit		; yes, thus happiness
freeChunk:		
	;
	; Free the chunk on error and return the error code in AX
	; 
		call	LMemFree
		mov_tr	ax, dx
		stc
exit:
		.leave
		ret

	;--------------------
	; Fetch the ID for the current path.
	;
	; Pass:		si	= disk handle
	;		es	= FSIR
	;		ss:bx	-> array chunk
	;			   data block segment
	; Return:	carry set on error:
	; 			ax	= ERROR_INSUFFICIENT_MEMORY
	; 		carry clear if ok:
	; 			ax	= destroyed
	; Destroyed:	si, di, dx
getID:
		push	ds
	;
	; First fetch the ID from the IFS driver.
	; 
		mov	di, DR_FS_CUR_PATH_GET_ID
		call	DiskLockCallFSD
	;
	; Figure how big the array currently is and enlarge it to hold another
	; FilePathID structure.
	; 
		push	si
		movdw	dssi, ({fptr}ss:[bx])
		mov	di, cx		; save high word
		ChunkSizeHandle	ds, si, cx
		add	cx, size FilePathID
		mov	ax, si
		call	LMemReAlloc
		pop	ax			; ax <- disk handle
		jc	allocErr
	;
	; Store the disk handle and ID in the new entry.
	; 
		mov	si, ds:[si]
		add	si, cx
		mov	ds:[si-size FilePathID].FPID_disk, ax
		movdw	<ds:[si-size FilePathID].FPID_id>, didx
	;
	; Return ERROR_FILE_NOT_FOUND so FileOpOnPath keeps going through the
	; remaining components of this here path.
	; 
		mov	ax, ERROR_FILE_NOT_FOUND
getIDDone:
		stc
		mov	ss:[bx].segment, ds	; store fixed up DS for next
						;  pass
		pop	ds
		retf
allocErr:
	;
	; If block has LMF_RETURN_ERRORS set, we can get an error back, so
	; return an appropriate error ourselves.
	; 
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		stc
		jmp	getIDDone
FileGetCurrentPathIDs endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileForEachPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Iterate over all active paths (the current directories and
		any directory stack entries for all existing threads).

CALLED BY:	GLOBAL
PASS:		di:si	= virtual far pointer to callback routine
		cx, dx, bp = initial data to pass to callback
RETURN:		cx, dx, bp = as returned from last call
		carry - set if callback forced early termination of processing.
			ax = value returned by callback if early termination
DESTROYED:	ax, di, si

PSEUDO CODE/STRATEGY:
		CALLBACK ROUTINE:
			Pass:	di	= disk handle of path to process
				bx	= memory handle of path to process
				ds	= idata
				cx, dx, bp = data as passed to ThreadProcess
					  or returned from previous callback
			Return:	carry - set to end processing
				cx, dx, bp = data to send on or return.
				ax = data to return if carry set
			Can Destroy: di, si, es

		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileForEachPath	proc	far	uses ds, bx
callback	local	fptr.far
		.enter
if	FULL_EXECUTE_IN_PLACE
EC<	xchg	bx, di							>
EC<	call	ECAssertValidFarPointerXIP				>
EC<	xchg	bx, di							>
endif
	;
	; Lock the FSIR exclusively (any shared lock(s) held by this thread
	; are automatically upgraded...) so nothing can change its path
	; stack while we're traversing things.
	;
	; We need this, rather than a separate ThreadLock as we used to
	; have, to prevent deadlock, as there are cases where the FSIR
	; is locked shared and we must go for the pathLock, and other
	; places where we've got the pathLock and need to get the FSIR
	; exclusive. Using the FSIR only to control this, while a bit
	; heavy-handed (it stops *all* file activity cold) does solve this
	; rather nasty problem gracefully, and traversing the path stacks
	; shouldn't take long.
	; 
		call	FSDLockInfoExcl

		mov	ss:callback.offset, si
		mov	ss:callback.segment, di

		mov	di, cs
		mov	si, offset FFEP_callback
		call	ThreadProcess
		
	;
	; Traversal complete, so release exclusive access to the FSIR. This
	; will automatically downgrade to a shared lock if was locked shared
	; before.
	; 
		call	FSDUnlockInfoExcl
		.leave
		ret
FileForEachPath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FFEP_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for FilePathProcess via ThreadProcess.
		Performs all the actual work of the traversal...

CALLED BY:	ThreadProcess
PASS:		bx	= handle of thread whose directory stack is to
			  be processed
		ds	= idata
		ss:bp	= above frame containing routine to call
RETURN:		carry set if callback function tells us to stop
DESTROYED:	si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FFEP_callback	proc	far	uses es, bx
callback	local	fptr.far	; callback vector for SysCallCallbackBP
		.enter	inherit
	;
	; Locate the stack segment for the thread so we can get at its
	; TPD_curPath.
	;
		push	ax
		call	ThreadFindStack
		mov	es, ax
		pop	ax
		mov	bx, es:[TPD_curPath]
pathLoop:
		tst	bx
		jz	done
		mov	di, ds:[bx].HM_otherInfo
		call	SysCallCallbackBPFar
		jc	done
		push	ax
		call	MemLock
		mov	es, ax
		mov	di, es:[FP_prev]
		call	MemUnlock
		pop	ax
		mov	bx, di
		jmp	pathLoop
done:
		.leave
		ret
FFEP_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StdPathDoesntExist
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with a standard directory not existing, creating it
		locally if the standard directory itself, not one of its
		subdirectories, is what was being changed to.

CALLED BY:	SetCurPathUsingStdPath, 
       		SetCurPathUsingStdPathWhenStdPathsNotEnabled

PASS:		ds:dx	= path tail
		bx	= StandardPath

RETURN:		carry set if path tail non-empty or local couldn't be created:
			ax	= ERROR_PATH_NOT_FOUND
		carry clear if local version successfully created:
			ax	= DirPathInfo

DESTROYED:	ax, es, di, si, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		If local copy is created, pathAttrs for the std path will
		have its SPA_DOES_NOT_EXIST_LOCALLY bit cleared.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
StdPathDoesntExist		proc	far
	mov	ss:[TPD_dataBX], handle StdPathDoesntExistReal
	mov	ss:[TPD_dataAX], offset StdPathDoesntExistReal
	GOTO	SysCallMovableXIPWithDSDX
StdPathDoesntExist		endp
CopyStackCodeXIP		ends

else

StdPathDoesntExist	proc	far
	FALL_THRU	StdPathDoesntExistReal
StdPathDoesntExist	endp

endif

StdPathDoesntExistReal	proc	far
		uses	ds, es, dx, bx, cx

pathBuffer	local	PathName

		.enter
	;
	; If a standard path doesn't exist in any form, we must create it
	; locally, unless there's a tail to this particular dog...
	;
		mov	si, dx
SBCS <		cmp	{byte} ds:[si], 0				>
DBCS <		cmp	{wchar}ds:[si], 0				>
		jnz	noExisteeNoCreatee

	;
	; Build the full path
	;

		mov	ax, bx			; standard path
		segmov	es, ss
		lea	di, ss:[pathBuffer]

		mov	cx, size pathBuffer	; cx <- buffer size
		clr	dx			; no drive name, please
		call	FileConstructFullPath
		jc	noExisteeNoCreatee
		lea	dx, ss:[pathBuffer]
	;
	; es:dx - full path
	; es:di - points after end of path
	; ax - StandardPath
	; bx - top level disk handle
	;

		call	FileCreateLocalStdPath
		jc	done
		
		mov	ah, DirPathInfo <1,0,0> shr 8; set DirPathInfo for the
						;  thing, which we now know
						;  exists locally...
		jmp	done			; (carry must be clear or we'd
						;  have branched above...)

noExisteeNoCreatee:
	;
	; Setting to a directory under a std path. If that doesn't exist,
	; it's not our fault or responsibility, so return a reasonable error.
	;
		mov	ax, ERROR_PATH_NOT_FOUND
		stc
done:
		.leave
		ret
StdPathDoesntExistReal endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileAddStandardPathDirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the specified directory to the standard path table

CALLED BY:	GLOBAL
PASS:		ds:dx - ptr to NULL-terminated path
		ax - StandardPath to add as
		bx - FileAddStandardPathFlags
RETURN:		carry - set if error
		ax - FileError (if an error)
			ERROR_PATH_NOT_FOUND
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileAddStandardPathDirectory	proc	far
	mov	ss:[TPD_dataBX], handle FileAddStandardPathDirectoryReal
	mov	ss:[TPD_dataAX], offset FileAddStandardPathDirectoryReal
	GOTO	SysCallMovableXIPWithDSDX
FileAddStandardPathDirectory	endp
CopyStackCodeXIP		ends

else

FileAddStandardPathDirectory	proc	far
	FALL_THRU	FileAddStandardPathDirectoryReal
FileAddStandardPathDirectory	endp

endif

FileAddStandardPathDirectoryReal	proc	far
		uses	bx, dx, es, si, di
spath		local	StandardPath	push	ax
newSize		local	word
		.enter

EC <		call	ECCheckAddDeleteStandardPathParams		>

		mov	si, dx			;ds:si <- ptr to string
	;
	; Lock the standard paths block for exclusive access, since
	; we'll be resizing it and writing to it.
	;
		call	FSP_LockStandardPaths
	;
	; Find the entries (if any) for the StandardPath we're adding
	;
		call	FSP_FindStandardPathEntry
		jnc	doneNoNotify		;branch if exists, no error
	;
	; Resize the block larger to make room for our string.
	; If there are no entries in this section currently, we need to
	; also add a second NULL to indicate the end of the section.
	;
		mov	dl, 0			;dl <- XXX: preserve flags
		mov	ax, es:SDP_blockSize	;ax <- current size
		jnz	haveEntries		;branch if entries exist
		LocalNextChar esax		;ax <- +space for 2nd NULL
		inc	dl			;dl <- flag: 2nd NULL needed
haveEntries:
		inc	cx			;cx <- 1 char for NULL
DBCS <		shl	cx, 1			;cx <- size for DBCS>
		push	cx
		add	ax, cx			;ax <- new size
		mov	ss:newSize, ax
		clr	ch			;ch <- HeapAllocFlags
		call	MemReAlloc
		pop	cx			;cx <- size w/NULL
		jc	doneNoNotify		;branch if error
		mov	es, ax			;es <- (new) seg addr of string
	;
	; Shift existing data up to make room for our string.
	;
	; bytes	 = old_end - insertion_point
	; source = old_end-1
	; dest	 = new_end-1
	;
		push	ds, si, di, cx
		segmov	ds, es
		mov	si, ds:SDP_blockSize
		mov	cx, si			;cx <- old size
		sub	cx, di			;cx <- # of bytes to move
		mov	di, ss:newSize
		dec	di			;es:di <- ptr to end-1
		dec	si			;ds:si <- ptr to end of data
		std				;set for shift upwards
		rep	movsb			;shift me jesus
		cld				;clear for normal behavior
		pop	ds, si, di, cx
	;
	; Copy our string in -- we use movsb because we have the size
	; in bytes, not the length.
	;
		push	cx
		rep	movsb			;copy me jesus
		pop	cx
	;
	; If the section didn't exist before, add in a 2nd NULL to indicate
	; the end of the section we've just created, and adjust the amount
	; we use for adjusting the pointers to account for it.
	;
		tst	dl			;need 2nd NULL?
		jz	no2ndNull		;branch if not
		clr	ax
		LocalPutChar esdi, ax		;NULL-terminate me jesus
		LocalNextChar escx		;cx <- +space for 2nd NULL
no2ndNull:
	;
	; Adjust the pointers for any strings after ours
	;
		mov	ax, ss:spath		;ax <- StandardPath
		call	FSP_AdjustStandardPathPtrs
	;
	; Release the standard path block *now* to prevent deadlock when
	; FileForEachPath attempts to grab the FSIR for exclusive access.
	; 
	; XXX: This still leaves a window where-in another thread can use
	; an incorrect cached DirPathInfo, but... Perhaps this invalidation
	; should happen at the very start? Then there'd be a window for
	; another thread to store a cached DirPathInfo. There's nothing
	; to be done, given the need to have the FSIR shared when grabbing
	; the stdDirPaths block shared...
	; 
		push	ax
		call	MemDowngradeExclLock
		pop	ax
	;
	; Invalidate all the paths changed by this
	;
		call	FSP_InvalidatePaths
		call	MemUnlockShared
		jc	done			;branch if error
	;
	; Send a notification indicating the change
	;
		mov	si, FCNT_ADD_SP_DIRECTORY
		call	FSP_GenerateNotify
		clc				;carry <- no error
done:

		.leave
		ret

doneNoNotify:
		call	MemUnlockExcl
		jmp	done
FileAddStandardPathDirectoryReal		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDeleteStandardPathDirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the specified directory from the standard path table

CALLED BY:	GLOBAL
PASS:		ds:dx - ptr to NULL-terminated path
		ax - StandardPath it was added as
RETURN:		carry - set if error
		ax - FileError (if an error)
			ERROR_PATH_NOT_FOUND
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP		segment	resource
FileDeleteStandardPathDirectory	proc	far
	mov	ss:[TPD_dataBX], handle FileDeleteStandardPathDirectoryReal
	mov	ss:[TPD_dataAX], offset FileDeleteStandardPathDirectoryReal
	GOTO	SysCallMovableXIPWithDSDX
FileDeleteStandardPathDirectory	endp
CopyStackCodeXIP		ends

else

FileDeleteStandardPathDirectory	proc	far
	FALL_THRU	FileDeleteStandardPathDirectoryReal
FileDeleteStandardPathDirectory	endp

endif
FileDeleteStandardPathDirectoryReal		proc	far
		uses	bx, si, ds, es, di
spath		local	StandardPath	push	ax
		.enter

EC <		call	ECCheckAddDeleteStandardPathParams		>

		mov	si, dx			;ds:si <- ptr to string
	;
	; Lock the standard paths block for exclusive access, since
	; we'll be resizing it and writing to it.
	;
		call	FSP_LockStandardPaths
	;
	; Find the entries (if any) for the StandardPath we're adding
	;
		call	FSP_FindStandardPathEntry
		mov	ax, ERROR_PATH_NOT_FOUND
		jc	doneNoNotify		;branch if not found
	;
	; Shift the strings after ours down.
	;
	; source = ptr past our string
	; dest	 = ptr to our string
	; bytes	 = (old end) - (source)
	;
		inc	cx			;cx <- +1 char for NULL
		segmov	ds, es
	;
	; If ours is the only string in the section, we want to
	; delete the additional NULL as well.
	;
		mov	si, ss:spath		;si <- StandardPath
		dec	si			;si <- offset to offset
CheckHack <SP_TOP eq 1>
		mov	ax, ds:SDP_pathOffsets[si][2]
		sub	ax, ds:SDP_pathOffsets[si]
DBCS <		shr	ax, 1			;ax <- # of chars>
		dec	ax			;ax <- -1 char for 2nd NULL>
		cmp	cx, ax			;only string in section?
EC <		ERROR_A	GASP_CHOKE_WHEEZE			>
		jb	no2ndNULL		;branch if not only string
		inc	cx			;cx <- +space for 2nd NULL
no2ndNULL:
	;
	; Shift the data down
	;
DBCS <		shl	cx, 1			;cx <- # bytes (DBCS)>
		mov	si, di			;ds:si <- ptr to our string
		add	si, cx			;ds:si <- ptr past our string
		push	cx
		mov	cx, ds:SDP_blockSize
		sub	cx, si			;cx <- # of bytes to move
		rep	movsb			;shift me jesus
		pop	cx
	;
	; Resize the block smaller (should never error)
	;
		push	cx
		mov	ax, ds:SDP_blockSize	;ax <- current size
		sub	ax, cx			;ax <- new size
		clr	ch			;ch <- HeapAllocFlags
		call	MemReAlloc
EC <		ERROR_C GASP_CHOKE_WHEEZE	;>
		pop	cx
		mov	es, ax			;es <- (new) seg addr
	;
	; Adjust the pointers after ours accordingly
	;
		mov	ax, ss:spath		;ax <- StandardPath
		neg	cx			;cx <- adjust pointers down
		call	FSP_AdjustStandardPathPtrs
	;
	; Invalidate all the paths changed by this
	;
		push	ax
		call	MemDowngradeExclLock	;release exclusive access,
						; but keep anyone else from
						; dicking with the block
		pop	ax
		call	FSP_InvalidatePaths
		call	MemUnlockShared
		jc	done			;branch if error
	;
	; Send a notification indicating the change
	;
		mov	si, FCNT_DELETE_SP_DIRECTORY
		call	FSP_GenerateNotify
		clc				;carry <- no error
done:

		.leave
		ret

	;
	; Unlock the standard paths block
	;
doneNoNotify:
		call	MemUnlockExcl
		jmp	done
FileDeleteStandardPathDirectoryReal	endp

if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckAddDeleteStandardPathParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the params we're passed are reasonable

CALLED BY:	FileAddStandardPathDirectory()

PASS:		ds:dx - ptr to NULL-terminated path
		ax - StandardPath it was added as
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckAddDeleteStandardPathParams		proc	near
		uses	es, di, cx
		.enter

		pushf
	;
	; To be a StandardPath, it must be odd, and in the legal range
	;
		test	ax, 0x1
		ERROR_Z FILE_STANDARD_PATH_DIRECTORY_INVALID_STANDARD_PATH
		cmp	ax, SP_NOT_STANDARD_PATH
		ERROR_E FILE_STANDARD_PATH_DIRECTORY_INVALID_STANDARD_PATH
		cmp	ax, StandardPath
		ERROR_A FILE_STANDARD_PATH_DIRECTORY_INVALID_STANDARD_PATH
	;
	; Make sure the path we're passed is a reasonable length
	;
		segmov	es, ds
		mov	di, dx			;es:di <- ptr to string
		call	LocalStringLength	;cx <- string length
		cmp	cx, 1024
		ERROR_A FILE_STANDARD_PATH_DIRECTORY_INVALID_PATH_STRING

		popf

		.leave
		ret
ECCheckAddDeleteStandardPathParams		endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSP_LockStandardPaths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the standard paths block

CALLED BY:	FileAddStandardPathDirectoryReal()
		FileDeleteStandardPathDirectoryReal()

PASS:		none
RETURN:		es - seg addr of standard paths block
		bx - handle of standard paths block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Lock using MemLockExcl() because we'll be resizing the block and
	writing to it, so we don't want someone else doing the same thing.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Will allocate and initialize a StandardPath block if none exists
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/13/93		Initial version
	ardeb	5/11/93		Added grabbing of FSIR, too, to prevent
				deadlock when invalidating current dirs.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSP_LockStandardPaths		proc	near
		uses	ax
		.enter
		LoadVarSeg	es, ax
		mov	bx, es:[loaderVars].KLV_stdDirPaths
		tst	bx
		jz	allocate
lockBlock:
		call	MemLockExcl
		mov	es, ax

		.leave
		ret

		; Allocate & initialize a StandardPath block. Look in
		; kLoader.def for the structure of the block
allocate:
		push	cx, di, es
		mov	ax, (size StdDirPaths)
		mov	cx, ((mask HF_SHARABLE or mask HF_SWAPABLE) or \
			    ((mask HAF_LOCK or mask HAF_NO_ERR) shl 8))
		mov	bx, handle 0		; to be owned by Kernel
		call	MemAllocSetOwnerFar
		mov	es, ax
		clr	di
		mov	ax, (size StdDirPaths)	; value to write
		mov	cx, ax
		shr	cx, 1			; write this many words
		rep	stosw
		call	MemUnlock
		pop	cx, di, es
		mov	es:[loaderVars].KLV_stdDirPaths, bx
		jmp	lockBlock
FSP_LockStandardPaths		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSP_FindStandardPathEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the entries (if any) for the specified StandardPath

CALLED BY:	FileAddStandardPathDirectory()
PASS:		es - seg addr of standard paths block
		ax - StandardPath to find entries for
		ds:si - ptr to path to add
RETURN:		carry - set if not found or no entries
		z flag - set (jz) if no entries for StandardPath
		if entry exists:
			es:di - ptr to entry
		else:
			es:di - ptr to start of entries for StandardPath
		cx - length of path string w/o NULL
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSP_FindStandardPathEntry		proc	near
		uses	bx
		.enter

	;
	; Figure out how big the string we're adding is.
	;
		push	es
		segmov	es, ds
		mov	di, si			;es:di <- ptr to path string
		call	LocalStringLength	;cx <- string size w/o NULL
		mov	dx, cx
		pop	es
	;
	; Calculate the pointer to the start of the entries
	;
		mov	di, ax
		dec	di			;di <- offset to offset
CheckHack <SP_TOP eq 1>
		mov	ax, es:[SDP_pathOffsets][di]
		cmp	ax, es:[SDP_pathOffsets][di][2]
		mov	di, ax
		stc				;carry <- not found / no entries
		je	done			;branch if no entries
	;
	; Entries exist -- see if one is ours
	;
		mov	bx, di			;es:bx <- ptr to section
cmpLoop:
	;
	; See if we've reached a zero-length string, which signals
	; the end of our section.
	;
		call	LocalStringLength
		jcxz	notFound		;branch if reached end
	;
	; See if the string is ours.  We have the lengths of both the
	; string we're looking at and our string, so we do a quick check
	; to see if they're even the same size first.
	;
		cmp	cx, dx			;same length?
		jne	nextString		;not equal if different lengths
		call	LocalCmpStringsNoCase
		clc				;carry <- found match
		je	doneHaveEntries		;branch if match
	;
	; Mismatch -- advance to the next string.  cx is the length.
	;
nextString:
		add	di, cx			;es:di <- ptr to NULL
		inc	di			;es:di <- ptr beyond NULL
DBCS <		add	di, cx			;>
DBCS <		inc	di			;>
		jmp	cmpLoop

	;
	; The string was not found -- return the pointer to the start
	; of the section for purposes of inserting
	;
notFound:
		mov	di, bx			;es:di <- ptr to section
		stc				;carry <- not found
doneHaveEntries:
		inc	cx			;clear z flag
EC <		ERROR_Z	GASP_CHOKE_WHEEZE				>
done:
	;
	; Return the length of our string
	;
		mov	cx, dx			;cx <- length of our string

		.leave
		ret
FSP_FindStandardPathEntry		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSP_AdjustStandardPathPtrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust pointers in the standard paths block after insert/delete

CALLED BY:	FileAddStandardPathDirectory()
PASS:		es - seg addr of standard paths block
		cx - amount to adjust by (signed)
		ax - StandardPath added to / deleted from
RETURN:		none
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSP_AdjustStandardPathPtrs		proc	near
		.enter

	;
	; Calculate the pointer to the first offset to adjust.
	; We don't want to adjust our pointer, but any after it.
	;
		mov	di, ax
		inc	di			;es:di <- ptr to offset
CheckHack <SP_TOP eq 1>
	;
	; Loop throught the offsets and adjust them
	;
adjustLoop:
		add	es:[SDP_pathOffsets][di], cx
		add	di, (size nptr)		;es:di <- next offset
		cmp	di, offset SDP_blockSize
		jbe	adjustLoop
		
		.leave
		ret
FSP_AdjustStandardPathPtrs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSP_GenerateNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a notification for adding/deleting a StandardPath

CALLED BY:	FileAddStandardPathDirectory(), FileCreateLocalStdPath()
PASS:		ax - StandardPath added/deleted
		si - FileChangeNotificationType
RETURN:		none
DESTROYED:	bx, cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSP_GenerateNotify		proc	far
		uses	ax
		.enter

		xchg	si, ax		;si <- StandardPath
					;ax <- FileChangeNotificationType
		clr	cx, dx		;cx, dx <- no ID
		call	FSDGenerateNotify

		.leave
		ret
FSP_GenerateNotify		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSP_InvalidatePaths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate all the paths that have changed

CALLED BY:	FileAddStandardPathDirectory()
PASS:		ax - StandardPath that has been added/deleted
RETURN:		carry - set if callback ended early
			ax - FileError
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSP_InvalidatePaths		proc	near
		uses	ax, bp, si
		.enter

		mov	bp, ax				;bp <- StandardPath
		mov	di, SEGMENT_CS
		mov	si, offset FSP_InvalidatePathCallback
		call	FileForEachPath

		.leave
		ret
FSP_InvalidatePaths		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSP_InvalidatePathCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate one path

CALLED BY:	FSP_InvalidatePaths() via FileForEachPath()
PASS:		di - disk handle of path
		bx - memory handle of path
		ds - idata
		bp - StandardPath added/deleted
RETURN:		carry - set to end processing
			ax - FileError
DESTROYED:	es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSP_InvalidatePathCallback		proc	far
		uses	ax, bx, di
		.enter

		test	di, DISK_IS_STD_PATH_MASK
		jz	done			;branch if not standard path
	;
	; See if the StandardPath in the path is affected by the change
	;
		cmp	bp, di			;same directory?
		je	invalPath		;branch if same directory
		push	bx
		mov	bx, di			;bx <- path's StandardPath
		call	FileStdPathCheckIfSubDir
		pop	bx
		tst	ax			;subdirectory?
		jnz	done			;branch if not subdirectory
	;
	; Invalidate the path by setting the DPI_EXIST_LOCALLY flag
	; and clearing the DPI_ENTRY_NUMBER_IN_PATH field.
	;
invalPath:
		call	MemLock
		mov	es, ax			;es <- seg addr of FilePath
EC <		test	di, not (mask DPI_STD_PATH)		>
EC <		ERROR_NZ GASP_CHOKE_WHEEZE			>
		ornf	di, mask DPI_EXISTS_LOCALLY
		mov	es:FP_pathInfo, di
		call	MemUnlock
done:
		clc				;carry <- don't abort

		.leave
		ret
FSP_InvalidatePathCallback		endp

Filemisc ends
