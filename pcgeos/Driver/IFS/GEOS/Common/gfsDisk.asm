COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gfsDisk.asm

AUTHOR:		Adam de Boor, Apr 14, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/93		Initial revision


DESCRIPTION:
	Implementation of the various DR_FS_DISK calls that we handle
		

	$Id: gfsDisk.asm,v 1.1 97/04/18 11:46:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDiskGetVolumeName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the name for the volume as a space-padded array.

CALLED BY:	(INTERNAL) GFSDiskInit, GFSDiskInfo
PASS:		es:di	= VOLUME_NAME_LENGTH-sized buffer to fill
		(PCMCIA only:) bx - offset to PCGFSSocketInfo

RETURN:		buffer filled
DESTROYED:	(PCMCIA only:) bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The volume label for the beast is stored in the longname
		of the special structure that tells us where the root
		directory is.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDiskGetVolumeName proc	near
		uses	ds, si, ax, dx, di, cx
		.enter
		segmov	ds, dgroup, si
if _PCMCIA
		clr	al
		call	GFSDevLock
		mov	ds:[curSocketPtr], bx
		push	es, di
		mov	ax, size GFSFileHeader	; point to root directory
		cwd
		mov	cx, size GFSDirEntry
		call	PGFSMapOffsetFar
		segmov	ds, es
		lea	si, ds:[di].GDE_longName
		pop	es, di
else
		mov	si, offset gfsRootDir.GDE_longName
endif
		mov	cx, VOLUME_NAME_LENGTH

copyLoop:
		LocalGetChar	ax, dssi
		LocalIsNull	ax
		jnz	storeIt
		LocalPrevChar	dssi
		LocalLoadChar	ax, C_SPACE
storeIt:
		LocalPutChar	esdi, ax
		loop	copyLoop
if _PCMCIA
		call	PGFSUnmapLastOffset
		call	GFSDevUnlock
endif
		.leave
		ret
GFSDiskGetVolumeName endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDiskID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the 32-bit ID for the disk currently in the passed drive

CALLED BY:	DR_FS_DISK_ID
PASS:		es:si	= DriveStatusEntry
RETURN:		carry set if ID couldn't be determined
		carry clear if it could:
			cx:dx	= 32-bit ID
			al	= DiskFlags for the disk
			ah	= MediaType for the disk
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDiskID	proc	far
		.enter
if _PCMCIA
		call	PGFSDiskID
else
		clrdw	cxdx		; (clears carry)
		mov	ax, mask DF_ALWAYS_VALID or (MEDIA_FIXED_DISK shl 8)
endif
		.leave
		ret
GFSDiskID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDiskInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a new disk handle with the remaining pertinent
		information. The FSInfoResource is locked for shared access
		and its segment is passed in ES for use by the driver.

		NOTE: The offset received by this routine is not the offset
		that will be returned to the application performing the
		disk registration; do not under any circumstances record the
		offset of either the descriptor or its private data.

CALLED BY:	DR_FS_DISK_INIT
PASS:		es:si	= DiskDesc for the disk, with all fields but
			  DD_volumeLabel filled in. DD_private points to a
			  chunk large enough to hold the private data for
			  all registered filesystem drivers.
		ah	= FSDNamelessAction to be passed to FSDGenNameless if
			  the disk has no volume label.
RETURN:		carry set on failure
		carry clear on success
			es	= fixed up if a chunk was allocated by the FSD
			DD_volumeLabel filled in (space-padded, not
				null-terminated).
			DD_private chunk filled in if driver told the kernel
				it keeps private data for disks.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDiskInit	proc	far
		.enter
		lea	di, es:[si].DD_volumeLabel
if _PCMCIA
	;
	; Fetch the offset to the socket information for this disk
	;
		push	bx
		mov	bx, es:[si].DD_drive
		mov	bx, es:[bx].DSE_private
		mov	bx, es:[bx].PGFSPD_socketPtr
endif
		call	GFSDiskGetVolumeName
PCMCIA <	pop	bx						>
		.leave
		ret
GFSDiskInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDiskFindFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the number of bytes of free space available on
		the passed disk.

CALLED BY:	DR_FS_DISK_FIND_FREE
PASS:		es:si	= DiskDesc of disk whose free space is desired (disk
			  is locked into drive)
RETURN:		carry set on  error:
			ax	= error code
		carry clear if ok:
			dx:ax	= # bytes free on the disk.
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDiskFindFree	proc	far
		.enter
		clrdw	dxax	; guess what? we have no free space.
		.leave
		ret
GFSDiskFindFree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDiskInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return useful information about a disk all in one fell swoop

CALLED BY:	DR_FS_DISK_INFO
PASS:		bx:cx	= fptr.DiskInfoStruct
		es:si	= DiskDesc of disk whose info is desired (disk is
			  locked shared in the drive)
RETURN:		carry set on error
			ax	= error code
		carry clear if successful
			buffer filled in.
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDiskInfo	proc	far
		uses	es, di
		.enter
if _PCMCIA
		push	bx, si
		mov	si, es:[si].DD_drive
		mov	si, es:[si].DSE_private
		mov	si, es:[si].PGFSPD_socketPtr
endif
		movdw	esdi, bxcx
		mov	es:[di].DIS_blockSize, 512	; what the hell
		clr	ax
		clrdw	es:[di].DIS_freeSpace, ax
		push	ds
		segmov	ds, dgroup, ax
if _PCMCIA
		movdw	es:[di].DIS_totalSpace, ds:[si].PGFSSI_size, ax
else
		movdw	es:[di].DIS_totalSpace, \
			ds:[gfsFileHeader].GFSFH_totalSize, \
			ax
endif
		pop	ds
		add	di, offset DIS_name
PCMCIA <	mov	bx, si						>
		call	GFSDiskGetVolumeName
PCMCIA <	pop	bx, si						>
		clc
		.leave
		ret
GFSDiskInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDiskSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append whatever private data the driver will require to
		restore the passed disk descriptor. The system portion
		(FSSavedDisk) will already have been filled in, with
		FSSD_private set to the offset at which the driver should
		store its information.

		NOTE: The registers passed to this function are non-standard
		(the FSIR is in DS, not ES).

CALLED BY:	DR_FS_DISK_SAVE
PASS:		ds:bx	= DiskDesc being saved (not locked; FSIR locked shared)
		es:dx	= place to store FSD's private data
		cx	= # bytes FSD may use
RETURN:		carry clear if disk saved:
			cx	= # bytes actually taken by FSD-private data
		carry set if disk not saved:
			cx	= # bytes needed by FSD-private data (0 =>
				  other error)
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Currently we do nothing, but perhaps we ought to save the
		path to the mega file, for the File driver, so we can confirm
		a restored disk handle is coming back to the same filesystem?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDiskSave	proc	far
		.enter
		clr	cx		; no bytes taken, clears carry
		.leave
		ret
GFSDiskSave	endp

Resident	ends
