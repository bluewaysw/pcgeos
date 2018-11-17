COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Dosappl
FILE:		dosapplLocate.asm

AUTHOR:		Adam de Boor, Apr  5, 1990

ROUTINES:
	Name			Description
	----			-----------
    GLB SysLocateFileInDosPath	Search for a file along our PATH envariable

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/ 5/90		Initial revision


DESCRIPTION:
	Functions for toying with (as opposed to accessing) files on disk.
		

	$Id: dosapplLocate.asm,v 1.1 97/04/05 01:11:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Filemisc	segment resource


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SysLocateFileInDosPath

DESCRIPTION:	Search for a file along the search path specified in the DOS
		PATH environment variable.

CALLED BY:	GLOBAL

PASS:		ds:si - addr of filename
			(in GEOS character set)
		es:di - place to store the result (DOS_PATH_BUFFER_SIZE
			bytes long, minimum)

RETURN:		carry clear if successful, full path copied out
			es:di = full path name (with drive letter)
					(in GEOS character set!)
			bx = disk handle of disk containing the found file
			cx = length of path (including null)
		else carry set, ax = ERROR_FILE_NOT_FOUND

DESTROYED:	none

REGISTER/STACK USAGE:
	es:di - environment block

NOTES:
	ds:si can be one of:
		1) full path with drive
		2) full path without drive
		3) relative path without drive
	
	We mimic DOS where possible:

	If a drive and absolute path are both specified then
		only the directory specified will be searched
	else if an absolute path is specified then
		only the directory on the current drive will be searched
	else (no drive, relative path)
		search current dir
		search path
	endif

	So, only if the path given does not contain a drive and it is relative
	does the code search the path.
	
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version
	ardeb	5/13/92		reworked for new filesystem
	Todd	04/28/94	XIP'ed

-------------------------------------------------------------------------------@
if	FULL_EXECUTE_IN_PLACE
CopyStackCodeXIP	segment	resource
SysLocateFileInDosPath		proc	far
	mov	ss:[TPD_dataBX], handle SysLocateFileInDosPathReal
	mov	ss:[TPD_dataAX], offset SysLocateFileInDosPathReal
	GOTO	SysCallMovableXIPWithDSSI
SysLocateFileInDosPath		endp
CopyStackCodeXIP	ends

else

SysLocateFileInDosPath		proc	far
	FALL_THRU	SysLocateFileInDosPathReal
SysLocateFileInDosPath		endp
endif

SysLocateFileInDosPathReal	proc	far
		uses si, ds, dx, di
filename	local	fptr.char	; Required file name \
		push	ds, si
destBuffer	local	fptr.char	; Place to store result	\
		push	es, di
path		local	fptr.char	; Storage for path address during
					;  call to FileGetAttributes
	.enter
EC <	call	FarCheckDS_ES						>

	;-----------------------------------------------------------------------
	;search specified directory first

	mov	dx, si			;DS:DX <- ptr to filename to search for
	call	FileGetAttributes	;destroys ax,cx
	jc	notFoundInSpecifiedDir	;Branch if not in specified dir

	mov	cx, -1			; null-terminated
	call	FileLocateBuildPath
found:
	;
	; fetch the disk handle for the file found using our normal
	; utility routine.
	;
	lds	dx, destBuffer		;ES:DI <- ptr to path name
	mov	bx, -1			;don't check for std path here...
	call	FileGetDestinationDisk
;FileGetDestinationDisk moves ds:dx past drive letter/colon, so restore it
	mov	dx, destBuffer.offset

	;
	; Now find the length of the found path.
	; 
	segmov	es, ds
	mov	di, dx

	mov	cx,-1
	LocalClrChar	ax
	LocalFindChar
	not	cx			;CX <- length (including null)
	mov	di, dx			; restore passed es:di

	; carry cleared by == scasb (w/null terminator) above.
done:
	.leave
	ret
	
notFoundInSpecifiedDir:
	;
	;file not in current directory, need to search path
	;only if there is no drive present and the path doesn't have any
	;leading path components.
	;
	call	FileLockInfoSharedToES
	mov	dx, si
	call	DriveLocateByName
	call	FSDUnlockInfoShared	; (preserves flags)
	jc	fileNotFound		;=> specified drive is bad
	tst	si
	jnz	fileNotFound		;=> drive specified, so file doesn't
					; exist
	mov	si, dx
checkForDirectoryComponentsLoop:
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, C_BACKSLASH
	je	fileNotFound
	LocalIsNull	ax
	jnz	checkForDirectoryComponentsLoop

	;ok, path has no drive + path is relative
	;first locate path string in environment block

	segmov	es, dgroup, di
	mov	es, es:[loaderVars].KLV_pspSegment
	mov	es, es:[PSP_envBlk]	;es:di <- env block
	clr	di
	mov	ax, di

locatePATH:
	cmp	{byte}es:[di], 0	;end of env block?
	je	fileNotFound		;loop if so

	cmp	{word}es:[di], 'A' shl 8 or 'P'	;'PA' ?
	jne	nextVariable			;next if not

	add	di, 2
	cmp	{word}es:[di], 'H' shl 8 or 'T'	;'TH' ?
	jne	nextVariable			;next if not

	add	di, 2
	cmp	{byte}es:[di], '='	;'=' ?
	jne	nextVariable		;next if not

	inc	di			;es:di <- first entry
	jmp	foundPATH

nextVariable:
	mov	cx, -1			;scan as far as necessary
	repne	scasb			;locate variable terminator
	jmp	locatePATH

fileNotFound:
	mov	ax, ERROR_FILE_NOT_FOUND	; return error code
	stc
	les	di, destBuffer		;restore passed es:di
	jmp	done			;nothing to copy out...

foundPATH:
	;-----------------------------------------------------------------------
	;'PATH=' located
	;generate full path names from entries and conduct searches
	;es:di = path entry

	segmov	ds, es				;ds:si <- path entry
	mov	si, di

dirLoop:
	mov	di, si
	mov	cx, PATH_BUFFER_SIZE

transferLoop:
	lodsb
	tst	al
	je	nullFound			;branch if so
	cmp	al, ';'				;entry separator?
	loopne	transferLoop
	je	nullFound

	; ran out of possible buffer. this be hosed. just skip until the null
	; or a separator is found and ignore the path entry.
ignoreLoop:
	lodsb
	tst	al
	je	fileNotFound
	cmp	al, ';'
	jne	ignoreLoop
	jmp	dirLoop

nullFound:
	dec	si				; point at terminator and
	mov	cx, si				; figure path length for
	sub	cx, di				; FileLocateBuildPath

	mov	path.segment, ds		; save current position in path
	mov	path.offset, si			;  (terminator)
	mov	si, di				; go back to start of path
						;  component

	;-----------------------------------------------------------------------
	;format path entry

if DBCS_PCGEOS
	;
	; convert path from environment to DBCS
	;	ds:si = path in enviroment block
	;	cx = path length
	;
	push	cx				; save path length
	mov	ax, PATH_BUFFER_SIZE*((size wchar)+(size char))
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAllocFar
	pop	cx				; restore path length
	jc	fileNotFound			; mem problem
	push	cx				; save path length
	mov	es, ax
	clr	di
	rep	movsb				; copy path to working buf
	pop	cx				; cx = path length
	mov	ds, ax				; ds:si = SBCS path to convert
	clr	si
	mov	di, PATH_BUFFER_SIZE		; es:di = convert-to-DBCS dest
	push	bx				; save mem handle
	mov	ax, '_'				; default char
	clr	bx, dx				; default code page, IFS
	call	LocalDosToGeos			; cx = length
	pop	bx				; bx = mem handle
	les	di, destBuffer			; es:di = dest to build path
	jnc	convOK
	call	MemFree				; free work buffer
	jmp	fileNotFound

convOK:
	mov	si, PATH_BUFFER_SIZE		; ds:si = DBCS path in work buf
	call	FileLocateBuildPath
	call	MemFree				; free work buffer
else
	les	di, destBuffer
	call	FileLocateBuildPath
endif

	;-----------------------------------------------------------------------
	;tack on path to file

	LocalPrevChar	esdi			;position di over null

	LocalLoadChar	ax, C_BACKSLASH
SBCS <	cmp	{char} es:[di-1], al		;is separator already present?>
DBCS <	cmp	{wchar} es:[di-2], ax		;is separator already present?>
	je	10$				; don't store another if so
	LocalPutChar	esdi, ax
10$:
	;path must be relative, other cases have been weeded out

	lds	si, filename

tackOnFilename:
	; copy filename until null terminator
	LocalGetChar	ax, dssi
	LocalPutChar	esdi, ax
	LocalIsNull	ax
	jne	tackOnFilename

	;-----------------------------------------------------------------------
	;perform a search

	lds	dx, destBuffer
	call	FileGetAttributes		;see if file there
	LONG jnc found				;no error => happiness

	;-----------------------------------------------------------------------
	;search failed for current path entry, try next entry

	lds	si, path		; (in DOS char set)
	lodsb
	tst	al
	LONG jz	fileNotFound		; => end of path, so file not found
	jmp	dirLoop
SysLocateFileInDosPathReal	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FileLocateBuildPath

DESCRIPTION:	Build up a full path to a file based on the filename given
		and the thread's current directory.

CALLED BY:	INTERNAL (SysLocateFileInDosPath)

PASS:		ds:si - path to filename. Path may be:
			1) full with drive
			2) full without drive (cur drive will be used)
			3) relative without drive (cur directory will be used)
		(in GEOS character set)
		es:di - buffer where full path should be placed
		cx - length of source path (-1 => null terminated & already
		     in PC/GEOS character set)

RETURN:		di points after null terminator

DESTROYED:	ax,cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if drive is present then
	    path must be full. If not, we pretend it is.
	    copy path as is into buffer
	else (drive absent)
	    put cur drive in buffer
	    if path is full then
		copy path into buffer+2
	    else
		get cur dir into buffer+2
		add relative path to end of cur dir
	    endif
	endif

	implementation betters this algorithm cos several actions are similar
		

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial version

-------------------------------------------------------------------------------@

FileLocateBuildPath	proc	near	uses	si, dx
	.enter
	;
	; See if the path has a drive specifier.
	; 
	mov	dx, si			; save source name start
checkForDriveLoop:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	driveAbsent
	LocalCmpChar	ax, ':'
	jne	checkForDriveLoop

	;-----------------------------------------------------------------------
	;drive present, so path must be absolute. We make it so if it wasn't

	xchg	si, dx
copyDriveLoop:
	LocalGetChar	ax, dssi
	LocalPutChar	esdi, ax
	dec	cx
	cmp	si, dx
	jne	copyDriveLoop

SBCS <	cmp	{char}ds:[si], C_BACKSLASH	; path is full?		>
DBCS <	cmp	{wchar}ds:[si], C_BACKSLASH	; path is full?		>
	je	copyPath		; yes -- copy rest into the buffer
	LocalLoadChar	ax, C_BACKSLASH	; no -- make it so
	LocalPutChar	esdi, ax
	jmp	copyPath		; and copy the rest into the buffer

driveAbsent:
	;-----------------------------------------------------------------------
	;drive absent

	mov	si, dx			;ds:si <- file name again
	push	cx
	clr	cx			;want only disk handle
	call	FileGetCurrentPath	;bx <- disk handle
	call	DiskGetDrive		;al <- 0 based drive number
	mov	cx, -1			;as big as you wanna be
	call	DriveGetName
	LocalLoadChar	ax, ':'
	LocalPutChar	esdi, ax
	pop	cx

	;-----------------------------------------------------------------------
	;drive already stuffed in buffer
	;ds:si - path without drive
	;es:di - buffer in which to place path

SBCS <	cmp	{char} ds:[si], C_BACKSLASH	;is path full?		>
DBCS <	cmp	{wchar} ds:[si], C_BACKSLASH	;is path full?		>
	je	copyPath

	;-----------------------------------------------------------------------
	;path relative

	push	cx
	push	ds,si			;save path to filename
	segmov	ds,es,si
	mov	si, di			;ds:si <- buffer
	mov	cx, PATH_BUFFER_SIZE-2	;specify length of buffer
	call	FileGetCurrentPath
	pop	ds,si			;recover path to filename

	LocalClrChar	ax
	mov	cx, -1
	LocalFindChar			;locate null terminator
	LocalPrevChar	esdi		;position di over null
	pop	cx

	LocalLoadChar	ax, C_BACKSLASH	;we know that path is relative
	LocalPutChar	esdi, ax
copyPath:
	push	di			;save start for possible conversion
					; to virtual name

copyPathLoop:
	LocalGetChar	ax, dssi
	LocalPutChar	esdi, ax
	LocalIsNull	ax			;done?
	loopne	copyPathLoop

	je	mapToVirtual		; be sure to null-terminate it
	LocalClrChar	ax
	LocalPutChar	esdi, ax

mapToVirtual:
	pop	si
	tst	cx
	jl	done			; => was -1 on entry, so already
					;  in PC/GEOS character set

if not DBCS_PCGEOS
;
; don't need this for DBCS_PCGEOS as incoming path is in GEOS char set
;
	; XXX: Should probably be using the ifs driver for the drive, but
	; I don't feel like finding the darn thing, and I'd need another
	; buffer anyway. bleah -- ardeb

	push	ds, di
	stc
	sbb	di, si			; di <- # chars w/o null

	segmov	ds, es			; ds:si <- string to convert
	mov	cx, di			; cx <- # chars
	mov	ax, '_'			; ax <- default char
	call	LocalDosToGeos
	pop	ds, di
endif
done:
	.leave
	ret
FileLocateBuildPath	endp

Filemisc	ends
