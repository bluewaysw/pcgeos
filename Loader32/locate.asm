COMMENT @----------------------------------------------------------------------

	Copyright (c) MyTurn.com 2000 -- All Rights Reserved

PROJECT:	GEOS32
MODULE:		Loader
FILE:		locate.asm

ROUTINES:
	Name			Description
	----			-----------
   	LocateGeosDir		Locate the kernel

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Lysle   8/2000          Initial version

DESCRIPTION:

	$Id: locate.asm,v 1.1 97/04/04 17:26:42 newdeal Exp $

------------------------------------------------------------------------------@


COMMENT @----------------------------------------------------------------------

FUNCTION:	LocateGeosDir

DESCRIPTION:	Initialize the kernel's path to the current path

CALLED BY:	LoadGeos

PASS:
	none

RETURN:
	KLV_bootupPath - set
	KLV_topLevelPath - set

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

The location of the GEOS directory is based on the location of the geos.ini
file.  The following strategy is used:

    1. Current directory
	Look for geos.ini in the current directory.  If it exists then
	the current directory is the GEOS directory.

    2. GEOSDIR environment variable
	Look for an environment variable GEOSDIR.  If it exists, cd to
	that directory and look for a geos.ini file.  If it exists then
	this directory is the GEOS directory.

    3. End of environment block (in DOS 3.X or above)
	If running DOS 3.X or above, look at the end of the environment block.
	The path used to run the program is stored here.

    4. Path
	Look in all directories on the path for a geos.ini file.  If a
	geos.ini file is found, the first directory in which it was found
	is the GEOS directory.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/91		Initial version
        Lysle   8/2000          Setup for GEOS32

------------------------------------------------------------------------------@
LocateGeosDir	proc	near
	uses es
	.enter

	; save start-up path so that we can pass it to the kernel
	mov	ah, MSDOS_GET_DEFAULT_DRIVE	;store the drive letter
	int	21h				;does NOT return the carry flag

	mov	ds:[loaderVars.KLV_bootDrive], al
	add	al, 'A'
	mov	ds:[loaderVars.KLV_bootupPath],al

	mov	si, offset loaderVars.KLV_bootupPath+3
	clr	dl
	mov	ah, MSDOS_GET_CURRENT_DIR
	int	21h				;store current directory
	ERROR_C	LS_CANNOT_LOCATE_KERNEL

	; look in current directory
	call	LocateInCurrentDir
	jnc	done

	; look for the GEOSDIR environment variable
	call	LocateInGEOSDIR
	jnc	done

	; look at the end of the env block in DOS 3.X or above
	call	LocateAtEndOfEnv
	jnc	done

	; look at the path
	call	LocateOnPath
	jnc	done

	; no place left to look
	ERROR	LS_CANNOT_LOCATE_KERNEL

done:
	; set working directory to be topLevelPath
	call	SetTopLevelPath

        ; Re-read the path and see where DOS really put us.
	mov	ah, MSDOS_GET_DEFAULT_DRIVE	;set drive
	int	21h

        ; Get the drive letter
	add	al, 'A'
	mov	{byte}ds:[loaderVars.KLV_topLevelPath], al

        ; Now for the directory path
	mov	si, offset loaderVars.KLV_topLevelPath+3
	clr	dl
	mov	ah, MSDOS_GET_CURRENT_DIR
	int	21h
	ERROR_C	LS_CANNOT_LOCATE_KERNEL

	.leave
	ret

LocateGeosDir	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	TackOnFilename

DESCRIPTION:	Completes the full path name for the GEOS.INI file given the
		full path to the directory in which the file sits.

CALLED BY:	LocateOnPath

PASS:
	es:di - addr of path terminator where a \filename will be placed
	cx - room left in the buffer (must be 2 bytes or more)

RETURN:
	carry set if couldn't fit in the buffer

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/91		Initial version
        Lysle   8/2000          Setup for GEOS32

-------------------------------------------------------------------------------@

NEC <loaderName	char	"geos.ini", 0				>
EC <loaderName	char	"geosec.ini", 0				>

TackOnFilename	proc	near	uses	ax, si, di, ds
	.enter

	LoaderDS
	mov	si, offset loaderName

	mov	al, '\\'
	cmp	es:[di-1], al
	je	TAF_loop

	stosb
	dec	cx
	stc
	jz	done				;skip to end (with error)
						;if ran out of room already...

TAF_loop:
	lodsb
	stosb					;copy up to and incl null
	tst	al
	loopne	TAF_loop

	jz	done
	stc					;ran out of room!

done:
	.leave
	ret
TackOnFilename	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LookForIniOnPathESDI

DESCRIPTION:	Look for a geos.ini file in the path at es:di

CALLED BY:	LocateInCurrentDir, LocateInGEOSDIR, LocateOnPath

PASS:
	carry - set to copy path (clear if already in topLevelPath)
	es:di - path to look at (must be in loader segment)

RETURN:
	es:di - pointing after path
	carry - set if error
	KLV_topLevelPath - set

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version
        Lysle   8/2000          Setup for GEOS32

------------------------------------------------------------------------------@
LookForIniOnPathESDI	proc	near	uses ax, cx, dx, si, bp, ds, es
	.enter

	jnc	afterCopy

	segmov	ds, es				;ds:si <- path entry
	mov	si, di
	LoaderES
	mov	di, offset loaderVars.KLV_topLevelPath	;es:di <- buffer

if DBCS_PCGEOS
	mov	cx, length loaderVars.KLV_topLevelPath
else
	mov	cx, size loaderVars.KLV_topLevelPath
endif

	; add drive letter if not there (use the boot path's drive letter)
	cmp	{char} ds:[si], '\\'
	jne	transferLoop
	mov	ax, {word}ds:[loaderVars.KLV_bootupPath]
	stosw

transferLoop:
	; copy all chars in path entry except seperator
	lodsb
	stosb
	tst	al
	je	sepFound			;branch if so
	cmp	al, ';'				;entry seperator?
	loopne	transferLoop

sepFound:
	dec	di
	dec	si				;point ds:si at separator
	stc
	jcxz	done				;bail if no more room

	;-----------------------------------------------------------------------
	;tack on the name "GEOS.INI" to path entry

afterCopy:
	mov	bp, di				;save end of path
	call	TackOnFilename
	jc	done

	LoaderDS				;ds <- loader segment
	mov	dx, offset loaderVars.KLV_topLevelPath
	mov	ax, MSDOS_GET_SET_ATTRIBUTES shl 8
	int	21h
	mov	{char} es:[bp], 0

done:
	mov	di, si
	.leave
	ret
LookForIniOnPathESDI	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LocateInCurrentDir

DESCRIPTION:	Try to locate the geos.ini file in the current directory.

CALLED BY:	LocateGeosDir

PASS:
	ds - loader segment

RETURN:
	carry - set if error (not found)
	KLV_topLevelPath - set

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/91		Initial version

------------------------------------------------------------------------------@
LocateInCurrentDir	proc	near
	LoaderES
	mov	di, offset loaderVars.KLV_bootupPath

	stc                                     ; request copy var into buffer
	call	LookForIniOnPathESDI
	ret
LocateInCurrentDir	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	FindEnvironmentVariable

DESCRIPTION:	Find an environment variable

CALLED BY:	LocateOnPath

PASS:
	cs:si - environment variable to find

RETURN:
	carry - set if error (not found)
	es:di - pointing at environment variable

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
FindEnvironmentVariable	proc	near	uses ax, cx, dx, si, ds
	.enter

	LoaderDS
	mov	dx, si				;ds:dx = var to find (stored)
	mov	es, ds:[loaderVars].KLV_envSegment	;es:di <- env block
	clr	di

locateLoop:
	mov	si, dx				;ds:si = reset var to find
cmpLoop:
	lodsb
	scasb
	jz	cmpLoop
	tst	al
	jnz	nextCategory
	cmp	{char} es:[di-1], '='
	clc
	jz	done

nextCategory:
	dec	di
	clr	al
	mov	cx, 0ffffh
	repne	scasb				;locate category terminator

	cmp	{char} es:[di], 0		;end of environment block?
	jnz	locateLoop

        ; Not found
	stc
done:
	.leave
	ret
FindEnvironmentVariable	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LocateInGEOSDIR

DESCRIPTION:	Try to locate the geos.ini file in the the path given by
		the environment variable GEOSDIR

CALLED BY:	LocateGeosDir

PASS:
	ds - loader segment

RETURN:
	carry - set if error (not found)
	KLV_topLevelPath - set

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/91		Initial version

-------------------------------------------------------------------------------@
geosDirString	char	"GEOSDIR", 0

LocateInGEOSDIR	proc	near
	; first locate the environment variable
	mov	si, offset geosDirString
	call	FindEnvironmentVariable
	jc	done

	stc                                     ; request copy var into buffer
	call	LookForIniOnPathESDI
done:
	ret
LocateInGEOSDIR	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LocateAtEndOfEnv

DESCRIPTION:	Try to locate the geos.ini file using the path stored at
		the end of the environment

CALLED BY:	LocateGeosDir

PASS:
	ds - loader segment

RETURN:
	carry - set if error (not found)
	KLV_topLevelPath - set

DESTROYED:
	ax, bx, cx, dx, si, di, bp, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/91		Initial version

-------------------------------------------------------------------------------@

strncpy proc    near
        ; do a strncpy
	lodsb
	stosb
	tst	al
	loopne	strncpy
        ret
strncpy endp

LocateAtEndOfEnv	proc	near
	; check DOS version
	mov	ax, MSDOS_GET_VERSION shl 8
	int	21h
	cmp	al, 3
	jae	dosOK
	stc
	ret
dosOK:
	; skip past all the strings in the environment block
	mov	es, ds:[loaderVars].KLV_envSegment	;es = enviroment block
	clr	di
	clr	al
	mov	cx, -1
findEndLoop:
	repne	scasb
	scasb
	loopne	findEndLoop

	; ds:si = path to kernel/stub
	mov	si, di
	segmov	ds, es			;ds = env
	LoaderES			;es = loader
	lodsw			; skip over count (might do something with
				;  it at some point...)

	mov	di, offset loaderVars.KLV_topLevelPath
	mov	dx, di
	mov	cx, PATH_BUFFER_SIZE

	cmp	{char}ds:[si+1], ':'	; Full path there?
	je	copyFromEnv

	; full path not recorded in environment, so must be relative to the
	; boot directory...Copy in the boot path first

	push	si, ds
	LoaderDS			;ds = loader
	mov	si, offset loaderVars.KLV_bootupPath
	call	strncpy
	pop	si, ds

	mov	{char}es:[di-1], '\\'		; Overwrite the terminator
	cmp	{char}ds:[si], '\\'		; absolute?
	jne	copyFromEnv

	LoaderDS
	mov	di, offset loaderVars.KLV_topLevelPath+2
						; yes -- just use drive letter
						; from bootupPath
copyFromEnv:
        call strncpy

	; remove filename from full pathname now stored in topLevelPath
	LoaderDS
	LoaderES
	mov	di, dx				; es:di <- full path name
	clr	al
	mov	cx, -1				; find null-terminator
	repne   scasb
	not	cx				; cx = full path length

	dec	di			;place di over null terminator
	mov	al, '\\'
	std
	repne	scasb
	cld
	cmp	{char} ds:[di], ':'	;leave backslash if in root
	jne	dontLeaveBackslash
	inc	di
	inc	cx
dontLeaveBackslash:
	inc	di
	mov	{char}ds:[di], 0

	;-----------------------------------------------------------------------
	;go to PC/GEOS top level directory

	segmov	es, ds				;es:di = end of path

	clc					; no copy
	call	LookForIniOnPathESDI
	ret
LocateAtEndOfEnv	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LocateOnPath

DESCRIPTION:	Try to locate the geos.ini file on the paths that are
		specified in the "PATH" environment variable.

CALLED BY:	LocateGeosDir

PASS:
	ds, es - loader segment

RETURN:
	carry - set if error (not found)
	es:di - path to use

DESTROYED:
	ax, bx, cx, dx, si, bp

REGISTER/STACK USAGE:
	es:di - environment block

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/91		Initial version

-------------------------------------------------------------------------------@

pathString	char	"PATH", 0

LocateOnPath	proc	near
	mov	si, offset pathString		;use the "PATH" environment
						;variable.
	call	FindEnvironmentVariable
	jc	done

locateLoop:
	stc
	call	LookForIniOnPathESDI
	jnc	done

	;is there another path in this PATH string?
	mov	al, ';'
	scasb
	jz	locateLoop		;loop to check it if so...

	;no: return error code
	stc
done:
	ret
LocateOnPath	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SetTopLevelPath

DESCRIPTION:	Set the top level path

CALLED BY:	LocateGeosDir, FindAndOpenKernel

PASS:
	none

RETURN:
	none
        flags are preserved.

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
SetTopLevelPath	proc	near	uses	dx, ds
	.enter
	pushf

	LoaderDS
	mov	dx, offset loaderVars.KLV_topLevelPath	; ds:dx <- topLevelPath
	call	SetCurrentDirAndDisk

	ERROR_C	LS_CANNOT_LOCATE_KERNEL

	popf
	.leave
	ret
SetTopLevelPath	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SetCurrentDirAndDisk

DESCRIPTION:	Set the current directory and disk

CALLED BY:	SetTopLevelPath, BuildPathEntry

PASS:
	ds:dx - path  (Assumed to be a full path of type "X:\path")

RETURN:
	carry - set if error

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

SetCurrentDirAndDisk	proc	near	uses	ax, dx, si
	.enter

	push	dx
	mov	si, dx
	mov	dl, ds:[si]
	sub	dl, 'a'			; assume lower-case
	jge	yesLowerCase
	add	dl, 'a' - 'A'		; whoops. Adjust b/c it was uppercase
yesLowerCase:
	; set the drive
	mov	ah, MSDOS_SET_DEFAULT_DRIVE
	int	21h
	pop	dx

	add	dx, 2			; skip drive letter and colon
	mov	ah, MSDOS_SET_CURRENT_DIR
	int	21h			; set current directory

	.leave
	ret
SetCurrentDirAndDisk	endp

