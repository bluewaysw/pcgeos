COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Disk
FILE:		diskInit.asm

AUTHOR:		Cheng, 12/89

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial revision

DESCRIPTION:	Initialize the drive status table and the drive parameter
		table.

GENERAL STRATEGY:
	Call InitDriveMap to build the initial drive map.
		
	$Id: driveInit.asm,v 1.1 97/04/05 01:11:32 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitDrive

DESCRIPTION:	Create drives bound to the skeleton FSD for all drives mentioned
		in the stdDirPaths block.

CALLED BY:	EXTERNAL (InitGeos)

PASS:		ds - idata

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version
	Cheng	12/89		Moved routine here from fileInit.asm
	ardeb	7/24/91		Changed for 2.0

-------------------------------------------------------------------------------@

InitDrive	proc	near
	uses	di, si
	.enter
	
	;
	; Locate all drives referenced in the standard paths and create
	; drives for them bound to the skeleton FSD.
	; 
	mov	bx, ds:[loaderVars].KLV_stdDirPaths
	tst	bx
	jz	stdPathsDone

	call	MemLock
	push	ds
	mov	ds, ax
	mov	es, ax
	
	mov	cx, length SDP_pathOffsets
	mov	si, offset SDP_pathOffsets
stdDirLoop:
	lodsw			; fetch base of path for std dir
	cmp	ax, ds:[si]	; anything there?
	je	nextStdDir	; nope -- go to next std dir

	push	si, cx		; save loop vars
	mov_trash si, ax	; ds:si <- first path in list

pathLoop:
	call	InitDriveFromPath

	mov	si, di		; si <- start of the next component
	scasb			; so long as extra null not here
	jne	pathLoop

	pop	si, cx

nextStdDir:
	loop	stdDirLoop

	;
	; All done -- release the stdDirPaths block
	; 
	pop	ds
	mov	bx, ds:[loaderVars].KLV_stdDirPaths
	call	MemUnlock

stdPathsDone:
	;
	; Create a drive from the top-level path.
	; 
	segmov	es, ds
	mov	si, offset loaderVars.KLV_topLevelPath
	call	InitDriveFromPath

	mov	si, offset loaderVars.KLV_bootupPath
	call	InitDriveFromPath
	.leave
	ret
InitDrive	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitDriveFromPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a drive descriptor for the drive mentioned in the
		passed path.

CALLED BY:	InitDrive
PASS:		ds:si	= path with drive specifier from which to create
			  a DriveStatusEntry
		es	= ds
RETURN:		es:di	= after null byte at end of path
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitDriveFromPath proc	near
		.enter
	;
	; Locate the colon that separates the drive name from everything else.
	; the loader has made sure that the separator exists...
	;
DBCS <		mov	ax, ':'						>
SBCS <		mov	al, ':'						>
		mov	di, si
		mov	cx, -1
		LocalFindChar			;scasb/scasw
	
	;
	; Null-terminate the drive name and upcase the thing, then define a
	; drive with that name.
	; XXX: if a drive name is ever in the high ascii set, this will
	; get hosed...not particularly likely, though :)
	;
SBCS <		mov	{char}ds:[di-1], 0				>
DBCS <		mov	{wchar}ds:[di-2], 0				>
		clr	cx
		call	LocalUpcaseString

		mov	al, -1		; figure drive number out yourself,
					;  please.
		mov	ah, MEDIA_FIXED_DISK
		mov	cx, DriveExtendedStatus <
				0,		; drive may be available over
						;  net
				0,		; drive not read-only
				0,		; drive cannot be formatted
				0,		; drive not an alias
				0,		; drive not busy
				<
				    1,		; drive is present
				    0,		; assume not removable
				    0,		; assume not network
				    DRIVE_FIXED	; assume fixed
				>
			>
		clr	bx			; no private data
		mov	dx, offset fileSkeletonDriver
		call	FSDInitDrive
	;
	; Restore the drive-name separator and find the end of the path
	;
SBCS <		mov	{char}ds:[di-1], ':'				>
SBCS <		clr	al						>
DBCS <		mov	{word}ds:[di-2], ':'				>
DBCS <		clr	ax						>
		mov	cx, -1
		LocalFindChar			;repne scasb/scasw
		.leave
		ret
InitDriveFromPath endp
