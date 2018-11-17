COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Disk tracking
FILE:		diskInit.asm

AUTHOR:		Adam de Boor, Dec  7, 1989

ROUTINES:
	Name			Description
	----			-----------
	InitDisk		Initialize tables for tracking disks
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 7/89	Initial revision


DESCRIPTION:
	Initialization code for disk module.
		

	$Id: diskInit.asm,v 1.1 97/04/05 01:11:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		
COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitDisk

DESCRIPTION:	Initialize the vars that hold the handle table addresses
		and their block handles. Also creates the disk handles for
		all fixed disks.

CALLED BY:	EXTERNAL (InitFile)

PASS:		ds - idata seg

RETURN:		ds:[topLevelDiskHandle]

DESTROYED:	ax, bx, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	This routine can sit in the init code.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/89		Initial version
	Adam	2/18/90		Changed to single-table
	Adam	7/17/91		Nuked creation of all fixed-disk handles;
				Just registers boot disk.

-------------------------------------------------------------------------------@

InitDisk	proc	near
		uses	es
		.enter
	;
	; Register the top-level disk and save its handle away. Unfortunately,
	; the loader doesn't provide us with the drive number, so we have
	; to determine it ourselves.
	; 
		call	FSDLockInfoShared
		mov	es, ax
		mov	dx, offset loaderVars.KLV_topLevelPath
		call	DriveLocateByName
EC <		ERROR_C	DISK_TOP_LEVEL_DRIVE_NOT_CREATED		>
EC <		tst	si						>
EC <		ERROR_Z	DISK_TOP_LEVEL_DRIVE_NOT_CREATED		>
		mov	al, es:[si].DSE_number
		call	FSDUnlockInfoShared
	    ;
	    ; Drive number now in AL. Register the disk and bitch (ec & non-ec)
	    ; if we can't.
	    ; 
		call	DiskRegisterDiskSilently
		ERROR_C	UNABLE_TO_REGISTER_TOP_LEVEL_DISK

		mov	ds:[topLevelDiskHandle], bx
		.leave
		ret
InitDisk	endp



