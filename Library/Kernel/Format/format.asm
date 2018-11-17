
COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Format
FILE:		

AUTHOR:		Cheng, 1/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial revision

DESCRIPTION:
		
	$Id: format.asm,v 1.1 97/04/05 01:18:23 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskFormat

DESCRIPTION:	Formats the disk in the specified drive.

CALLED BY:	GLOBAL

PASS:		ah - drive number (0 based)
		al - PC/GEOS media descriptor
			MEDIA_160K, or
			MEDIA_180K, or
			MEDIA_320K, or
			MEDIA_360K, or
			MEDIA_720K, or
			MEDIA_1M2, or
			MEDIA_1M44, or
			MEDIA_FIXED_DISK for default max capacity

		    not currently supported:
			MEDIA_DEFAULT_MAX for default max capacity

		cx:dx - callback routine
			dx = 0ffffh if none
		bp - callback specifier
			CALLBACK_WITH_PCT_DONE
			CALLBACK_WITH_CYL_HEAD

		es:di - ASCIIZ volume name

RETURN:		carry set on error
		error code in ax:
			FMT_DONE (= 0) if successful
			FMT_INVALID_DRIVE
			FMT_DRIVE_NOT_READY
			FMT_ERR_WRITING_BOOT
			FMT_ERR_WRITING_ROOT_DIR
			FMT_ERR_WRITING_FAT
			FMT_BAD_PARTITION_TABLE
			FMT_ERR_READING_PARTITION_TABLE
			FMT_ABORTED
			FMT_SET_VOLUME_NAME_ERR
			FMT_CANNOT_FORMAT_FIXED_DISKS_IN_CUR_RELEASE
			FMT_ERR_DISK_IS_IN_USE
			FMT_ERR_WRITE_PROTECTED
		if successful (else 0):
			si:di - bytes in good clusters
			dx:cx - bytes in bad clusters

DESTROYED:	ax,bx

	Callback:
	PASS:
		ax - percentage done
	RETURN:
		carry set to CANCEL
	DESTROYED:
		nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Formats for floppies are low-level, ie. all data will be lost.
	Formats for fixed disks proceed as track verifies. The FAT is rebuilt.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version

-------------------------------------------------------------------------------@

DiskFormat	proc	far	uses bx, bp, ds, es
	.enter

	;some preliminaries for this release

	mov	si, ax
	mov	al, ah
	call	DriveGetStatusFar
	test	ah, mask DS_MEDIA_REMOVABLE
	stc
	LONG jz	done

	LoadVarSeg	ds, ax

	PSem	ds, formatSem		; Gain exclusive access to our global
					;  variables.

	mov	ah, MSDOS_RESET_DISK
	call	FileInt21

	mov	ax, si

	; Fetch the disk handle for the thing, if any

	mov	al, ah
	call	DriveLockFar		; Lock down the drive for the duration
	push	ax			; save drive number for unlock

	call	DiskRegisterDiskWithoutInformingUserOfAssociation
	mov	ax, 0			; assume disk unformatted
	jc	pushDiskHandle
	;
	; check if disk is writable
	;
	push	ds
	LoadVarSeg	ds
	call	DiskCheckWritableFar	; C set if writable
	jc	checkWritable		; if so, continue
					
	call	DiskReRegister		; if not writable, and user is trying
	call	DiskCheckWritableFar	;	to set disk name, maybe s/he
					;	removed write-protect just
					;	before doing this operation,
					;	so reregister disk and check
					;	again
	mov	ax, FMT_ERR_WRITE_PROTECTED	; assume still write-protected
					; C set if writable
checkWritable:
	pop	ds
	cmc				; C clear if writable
	jc	LDF_errorNoCleanup	; if not writable, exit with error

	; See if the disk is in use anywhere here...
	xchg	ax, bx
pushDiskHandle:	
	mov	ds:diskHandle, ax	; save where InitReservedArea
					;  can get at it to set its ID

	xchg	ax, bx			; bx <- disk handle
	call	DiskCheckInUse		;  (don't worry if no handle to disk)
	mov	ax, FMT_ERR_DISK_IS_IN_USE
	jc	LDF_errorNoCleanup

	mov	ax, si
	call	FormatDoInit		;destroys ax,bx,cx,dx,di,si
	jc	LDF_errorNoCleanup

	mov	bp, ds:[lastRootDirTrack]	;specify count
	sub	bp, ds:[startTrack]
	inc	bp

	clr	ax			;clear ax and carry for callback
	call	CallStatusCallback	;initial call
	jc	LDF_error

	call	FormatTracks		;destroys ax,bx,cx,dx,bp
	jc	LDF_error

	mov	es, ds:[workBufSegAddr]

	call	InitReservedArea	;destroys ax,cx,dx,bp,di,si
	jc	LDF_error

	call	InitFAT			;destroys ax,cx,dx,bp
	jc	LDF_error

	call	InitRootDirectory	;destroys bx,cx,bp
	jc	LDF_error

	call	VerifyKeyTracks
	jc	LDF_error

	call	FormatFilesArea		;ax<-err, dest bx,cx,dx,bp,es,di,si

LDF_error:
	call	FormatDoCleanup		;destroys bx

LDF_errorNoCleanup:
	call	FormatDoReturnRegs	;destroys bx,bp

	xchg	ax, bx			; preserve ax...
	pop	ax			;recover drive number and unlock
	call	DriveUnlockFar		; the thing
	xchg	ax, bx

	VSem	ds, formatSem
done:
	.leave
	ret
DiskFormat	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatGrabDOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Snag the DOS/BIOS lock for a time

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	flags

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatGrabDOS	proc	near	uses bx
		.enter
		mov	bx, FML_DOS
		call	FileGrabSystem
		.leave
		ret
FormatGrabDOS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatReleaseDOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the DOS/BIOS lock again

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatReleaseDOS proc	near	uses bx
		.enter
		mov	bx, FML_DOS
		call	FileReleaseSystem
		.leave
		ret
FormatReleaseDOS endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatInt13
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Execute BIOS interrupt 13h with proper protection

CALLED BY:	INTERNAL
PASS:		registers set up for int 13h
RETURN:		result of call
DESTROYED:	nothing by this function, just by BIOS

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FormatInt13	proc	near
		.enter
		call	FormatGrabDOS
		int	13h
		call	FormatReleaseDOS
		.leave
		ret
FormatInt13	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatDoCleanup

DESCRIPTION:	Restores the BPB if necessary and frees the work buffer.

CALLED BY:	INTERNAL (DiskFormat)

PASS:		nothing

RETURN:		nothing

DESTROYED:	bx, flags preserved

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version

-------------------------------------------------------------------------------@

FormatDoCleanup	proc	near
	pushf

	;-----------------------------------------------------------------------
	;if Ioctl was used, restore BPB

	call	IsIoctlPresent
	jc	noIoctl

	call	RestoreBPB		;destroys cx,dx
	jmp	short freeWorkBuf

noIoctl:
	mov	bx, ds:[trackVerifyBufHan]
	call	MemFree

freeWorkBuf:
	;-----------------------------------------------------------------------
	;free buffer

	mov	bx, ds:[workBufHan]
	call	MemFree
	popf
	ret
FormatDoCleanup	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatDoReturnRegs

DESCRIPTION:	Sets up the return registers.

CALLED BY:	INTERNAL (DiskFormat)

PASS:		ds - dgroup
		carry from Format operation
		ds:[mediaClusterSize]
		ds:[mediaSectorSize]

RETURN:		si:di - bytes in good clusters
		dx:cx - bytes in bad clusters

DESTROYED:	bx, bp, carry flag preserved

REGISTER/STACK USAGE:
	bx - sectors per cluster
	bp - bytes per sector

	bytes in cluster = num clusters * sectors per cluster * bytes per sector

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version

-------------------------------------------------------------------------------@

FormatDoReturnRegs	proc	near
	mov	si, 0			; preserve carry
	mov	di,si
	mov	dx,si
	mov	cx,si
	jc	exit

	;-----------------------------------------------------------------------
	;set volume name

	push	dx,ds
	mov	dl, ds:[drive]
	inc	dl
	mov	bx, ds:[diskHandle]
	lds	si, ds:[volumeNameAddr]
	cmp	byte ptr ds:[si], 0
	je	setUnnamed
	call	DiskFileSetVolumeName
doneSet:
	pop	dx,ds

	mov	ax, FMT_SET_VOLUME_NAME_ERR
	jc	exit

	mov	bl, ds:[mediaVars.BPB_clusterSize]
	clr	bh
	mov	bp, ds:[mediaVars.BPB_sectorSize]

	mov	ax, ds:[goodClusters]
	mul	bx			;ax <- sectors in good clusters
	mul	bp			;ax <- bytes in good sectors
	mov	si, dx			;si:di <- bytes in good sectors
	mov	di, ax

	mov	ax, ds:[badClusters]
	mul	bx
	mul	bp
	mov	cx, ax			;dx:cx <- bytes in bad sectors
	clr	ax
exit:
	ret

setUnnamed:
	tst	bx			; any disk handle?
	jz	doneSet			; nope, it is already unnamed
	; User desires no name be given to the newly-formatted disk, so
	; make sure the disk handle reflects this
	call	DiskCheckUnnamed
	cmc				; carry clear if unnamed
	jnc	doneSet			;leave alone if disk was previously
					; unnamed. (carry clear)
	; else re-register the thing. This will also notify the user of
	; the disk's new identity as well as giving it the proper name.
	call	DiskReRegister
	jmp	doneSet
FormatDoReturnRegs	endp
