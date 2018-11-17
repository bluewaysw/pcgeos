COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	DOS Common IFS Code
MODULE:		Disk Formatting
FILE:		dosFormat.asm

AUTHOR:		Adam de Boor, Oct 31, 1991

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/31/91	Initial revision


DESCRIPTION:
	Implementation of disk formatting.

	$Id: dosFormat.asm,v 1.1 97/04/10 11:55:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
DiskFormatCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format the disk currently in the passed drive to the passed
		format. NOTE: the FSInfoResource should *not* be locked for
		the duration of the format, as this will prevent disks in
		other drives from being registered. If the FSInfoResource must
		be consulted, lock it, get your data, and unlock it.

CALLED BY:	DR_FS_DISK_FORMAT
PASS:		ss:bx	= FSFormatArgs
RETURN:		carry set on failure:
			ax	= error code
		carry clear on success:
			ax:di	= bytes in good clusters
			dx:cx	= bytes in bad clusters
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskFormat	proc	far
		uses	ds, es, bx, si
		.enter
	;
	; Allocate and initialize our workspace
	;
		call	DOSFormatInit
		jc	done
	;
	; Perform initial callback.
	;
		call	DOSFormatCallCallback
		jc	cleanUp
	;
	; Try and perform a quick-format, if the caller and the media allow.
	; 
		call	DOSFormatCheckAndPerformQuick
		jnc	setName
	;
	; Format enough to initialize the FAT et al.
	;
		mov	bp, ds:[DFD_lastRootDirTrack]
		sub	bp, ds:[DFD_startTrack]
		inc	bp		; startTrack is 1-origin, but
					;  lastRootDirTrack is 0-origin

		call	DOSFormatTracks
		jc	cleanUp


		call	DOSFormatWriteAdminStuff
		jc	cleanUp
	;
	; Format the remainder of the tracks.
	;
		call	DOSFormatFilesArea
		jc	cleanUp
	;
	; Name the new disk properly.
	;
setName:
		call	DOSFormatSetName
		jc	cleanUp
	;
	; Return the amount of usable and unusable disk space.
	;
		call	DOSFormatReturnRegs
cleanUp:
	;
	; Clean up.
	;
		call	DOSFormatCleanUp
done:
		.leave
		ret
DOSDiskFormat	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatCallCallback

DESCRIPTION:	Calls the callback routine if one was supplied.

CALLED BY:	INTERNAL

PASS:		ds	= DiskFormatData

RETURN:		carry clear to proceed
		carry set to abort
			ax = FMT_ABORTED

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version
	ardeb	3/15/92		Brought into IFS driver

-------------------------------------------------------------------------------@

DOSFormatCallCallback	proc	near
		uses	cx, dx
		.enter
	;
	; If neither callback type requested, no callback required.
	;
		test	ds:[DFD_formatArgs].FSFA_flags,
				mask DFF_CALLBACK_PCT_DONE or \
				mask DFF_CALLBACK_CYL_HEAD
		jz	done
	;
	; Assume calling with cylinder and head...
	;
		mov	ax, ds:[DFD_curCylinder]
		mov	bx, ds:[DFD_curHead]

		test	ds:[DFD_formatArgs].FSFA_flags,
				mask DFF_CALLBACK_PCT_DONE
		jz	doCall
	;
	; Wrong. Figure how far along we are.
	;

		mul	ds:[DFD_bpb].BPB_numHeads	;dx:ax <- num tracks
							; into the disk
		mov	dx, 100
		mul	dx
		div	ds:[DFD_numTracks]		; ax <- percent
doCall:
	;
	; Pass ax & bx as they are now and call the callback routine,
	; which may be in either fixed or movable memory.
	;
		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx
		mov	ax, ds:[DFD_formatArgs].FSFA_callback.offset
		mov	bx, ds:[DFD_formatArgs].FSFA_callback.segment
		push	ds
		mov	ds, ds:[DFD_formatArgs].FSFA_ds
		call	ProcCallFixedOrMovable
		pop	ds
		mov	ax, FMT_ABORTED
		jc	done
		clr	ax
done:
		.leave
		ret
DOSFormatCallCallback	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatTracks

DESCRIPTION:	Formats tracks from the current cylinder and head.

CALLED BY:	INTERNAL (DOSDiskFormat)

PASS:		ds, es - DiskFormatData
		ds:[DFD_curCylinder] - starting cylinder
		ds:[DFD_curHead] - starting head
		bp - number of tracks

RETURN:		carry set on error
		ax - error code
		ds:[DFD_curCylinder], ds:[DFD_curHead] - updated

DESTROYED:	ax, bx, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version
	ardeb	3/15/92		Brought into IFS driver

-------------------------------------------------------------------------------@

DOSFormatTracks	proc	near
		mov	cx, ds:[DFD_curCylinder]
		mov	dx, ds:[DFD_curHead]
FT_loop:
		call	DOSFormatTrack
		jc	FT_exit

		inc	dx				;next head
		cmp	dx, ds:[DFD_bpb].BPB_numHeads	;valid head number?
		jb	FT_checkDone			;branch if so

		clr	dx				;else reset head to 0
		inc	cx
		mov	ds:[DFD_curCylinder], cx	;next cylinder
FT_checkDone:
		mov	ds:[DFD_curHead], dx
		dec	bp
		jne	FT_loop

		clr	ax
FT_exit:
		ret
DOSFormatTracks	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatWriteAdminStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the administrative information for the disk: the boot
		sector, the FAT(s), and the (empty) root directory.

CALLED BY:	(INTERNAL) DOSDiskFormat
PASS:		ds, es	= DiskFormatData
RETURN:		carry set on error
DESTROYED:	anything but ds & es

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatWriteAdminStuff proc	near
		uses	ds, es
		.enter
if PZ_PCGEOS
	;
	; save and set DisketteParams for Pizza's 1.232M 3.5"
	;
		cmp	ds:[DFD_formatArgs].FSFA_media, MEDIA_1M232
		jne	noSet1232M
		call	SysLockBIOS
		call	SaveAndSet1M232
		mov	ah, 0				;reset
		call	DOSFormatInt13
noSet1232M:
endif
		call	DOSFormatWriteBootAndReserved
		jc	done
if _REDMS4
	;
	; Force DOS to do all the wacky things it does when looking at
	; a disk for the first time. 
	;
		push	ax, bx, cx, dx, ds
		call	DOSPreventCriticalErr
		mov	ah, MSDOS_GET_DISK_GEOMETRY
		mov	dl, 2
		call	DOSUtilInt21
		call	DOSAllowCriticalErr
		pop	ax, bx, cx, dx, ds
endif
		
		call	DOSFormatZeroFAT
		jc	done
		call	DOSFormatWriteRootDirectory
		jc	done
		call	DOSFormatVerifyKeyTracks
done:
if PZ_PCGEOS
	;
	; restore DisketteParams for Pizza's 1.232M 3.5"
	;
		pushf
		cmp	ds:[DFD_formatArgs].FSFA_media, MEDIA_1M232
		jne	noUnset1232M
		call	Unset1M232
		mov	ah, 0
		call	DOSFormatInt13
		call	SysUnlockBIOS
noUnset1232M:
		popf
endif
		.leave
		ret
DOSFormatWriteAdminStuff		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveAndSet1M232
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set 1M232 mode.

CALLED BY:	format code.
PASS:		ds - DiskFormatData
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if PZ_PCGEOS
SaveAndSet1M232	proc	near
	uses	ds, si, es, di, cx
	.enter
	;
	; save and set DisketteParams for Pizza's 1.232M 3.5"
	;
	segmov	es, ds			; es:di = save DP
	mov	di, offset DFD_methodData.DFMD_bios.DFBD_saveParams
	clr	si
	mov	ds, si
					; ds:si = DisketteParams
	lds	si, ds:[BIOS_DISK_PARAMS_VECTOR * (size dword)]
	mov	cx, size DisketteParams
	push	si
	rep movsb			; save current DisketteParams
	pop	si
	mov	ds:[si].DP_bytesPerSector, BBPS_1024
	mov	ds:[si].DP_sectorsPerTrack, 8
	mov	ds:[si].DP_gapLength, 35h
	mov	ds:[si].DP_formatGapLength, 54h
	.leave
	ret
SaveAndSet1M232	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Unset1M232
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unset 1M232 mode.

CALLED BY:	format code.
PASS:		ds - DiskFormatData
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if PZ_PCGEOS
Unset1M232	proc	near
	uses	si, es, di, cx
	.enter
	;
	; restore DisketteParams for Pizza's 1.232M 3.5"
	;
					; ds:si = saved DP
	mov	si, offset DFD_methodData.DFMD_bios.DFBD_saveParams
	clr	di
	mov	es, di
					; es:di = DisketteParams
	les	di, es:[BIOS_DISK_PARAMS_VECTOR * (size dword)]
	mov	cx, size DisketteParams
	rep movsb			; restore saved DisketteParams
	.leave
	ret
Unset1M232	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NonSysBootstrap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bootstrap code copied into a new boot sector to tell the
		user s/he's tried to boot a non-system disk.

CALLED BY:	boot code.
PASS:		nothing
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NonSysBootstrap	proc	far
		call	10$
10$:
		pop	si
		add	si, noBootee-10$
ploop:
		lodsb
		tst	al
		jz	done
		mov	ah, 0xe
		int	0x10
		jmp	ploop
done:
		jmp	done
noBootee	label	char
NonSysBootstrap	endp

BOOTSTRAP_LENGTH equ $-NonSysBootstrap


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatWriteBootAndReserved

DESCRIPTION:	Initialize the Reserved Area on the disk.

CALLED BY:	(INTERNAL) DOSFormatWriteAdminStuff

PASS:		ds - DiskFormatData

RETURN:		carry set on error
		ax - 0 if successful, FMT_ERR_WRITING_BOOT if not

DESTROYED:	ax, cx, dx, di, si, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	copy bpb
	init other fields
	zero bootable signature
	write sector out

	for a map of the boot sector, see Duncan, pg 180

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version
	ardeb	3/15/92		Brought over to IFS driver

-------------------------------------------------------------------------------@

oemName	char	'GEOWORKS'
	char	length BS_oemNameAndVersion - length oemName dup (' ')

DOSFormatWriteBootAndReserved	proc	near
		call	DOSFormatZeroSectorWorkArea	; es <- sector area
	;
	; copy partial Bios Param Block into work area.
	;
		mov	si, offset DFD_bpb		;si <- start off to BPB
		mov	di, offset BS_bpbSectorSize	; = BS_bpbSectorSize
		mov	cx, offset BS_physicalDriveNumber - \
				offset BS_bpbSectorSize
		rep	movsb
	;
	; Certain execrable device drivers refuse to look at the geometry
	; information we so kindly place in the boot sector unless there's
	; a jump at the start (or an IMUL -- God only knows why), so we can't
	; 0-initialize the jumpInstr and must, therefore, have real bootstrap
	; code there, even if it does nothing.
	;
		mov	{word}es:[BS_jumpInstr],
				((BS_bootstrap - 2) shl 8) or 0xeb
		mov	es:[BS_jumpInstr+2], 0x90
		mov	es:[BS_bootableSig], 0xaa55

	;
	; Copy in non-system-disk bootstrap code & non-bootable string.
	;
		push	ds
		segmov	ds, cs
		mov	si, offset NonSysBootstrap
		mov	di, offset BS_bootstrap
		mov	cx, BOOTSTRAP_LENGTH
		rep	movsb
		segmov	ds, Strings, si
		mov	si, ds:[noBooteeString]
		ChunkSizePtr ds, si, cx		; cx <- length w/null
		rep	movsb
		pop	ds

	;
	;***** init disk ID *****
	;
		mov	dl, ds:[DFD_formatArgs].FSFA_drive
		mov	es:[BS_physicalDriveNumber], dl
		mov	es:[BS_extendedBootSig], EXTENDED_BOOT_SIGNATURE

		mov	di, offset BS_oemNameAndVersion
		mov	si, offset oemName
		rept	length BS_oemNameAndVersion / 2
		movsw	cs:
		endm

	;
	; Init volume id in the boot sector. disk handle will be taken care
	; of when disk name is set.
	;

		call	DOSGetTimeStamp
		mov	es:[BS_volumeID].high, cx
		mov	ds:[DFD_diskID].high, cx
		mov	es:[BS_volumeID].low, dx
		mov	ds:[DFD_diskID].low, dx

	;
	; Init volume label
	;
		push	ds
		mov	di, BS_volumeLabel
		CheckHack <size BS_volumeLabel ge size FCB_name>
		lds	si, ds:[DFD_formatArgs].FSFA_volumeName
		call	DOSDiskCopyAndMapVolumeName
		pop	ds
	;
	; Set BS_fsType appropriately (FAT16 or FAT12).
	; 
		mov	{word}es:[BS_fsType][0], 'F' or ('A' shl 8)
		mov	{word}es:[BS_fsType][2], 'T' or ('1' shl 8)
		push	bx		; just in case...
		call	DOSFormatGetNumClusters
		pop	bx
		cmp	ax, FAT_16_BIT_THRESHOLD
		mov	ax, '6' or (' ' shl 8)
		jae	finishFSType
		mov	al, '2'
finishFSType:
		mov	{word}es:[BS_fsType][4], ax
		mov	{word}es:[BS_fsType][6], ' ' or (' ' shl 8)
	;
	; Write the whole boot sector out now.
	;
		mov	cx, ds:[DFD_startBoot]		;specify sector 1
		call	DOSFormatWriteWorkArea
		mov	ax, FMT_ERR_WRITING_BOOT
		jc	done
		clr	ax
done:
		.leave
		ret
DOSFormatWriteBootAndReserved	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatZeroFAT

DESCRIPTION:	Writes the initial version of the FAT. The FAT will be modified
		by DOSFormatFilesArea if it encounters bad sectors.

CALLED BY:	INTERNAL (DOSFormatWriteAdminStuff)

PASS:		ds - DiskFormatData

RETURN:		carry set on error
		ax - 0 if successful, FMT_ERR_WRITING_FAT if not

DESTROYED:	bx, bp, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version
	ardeb	4/92		Brought to IFS driver

-------------------------------------------------------------------------------@

DOSFormatZeroFAT	proc	near
	mov	al, ds:[DFD_bpb].BPB_numFATs
	clr	ah
	mul	ds:[DFD_bpb].BPB_sectorsPerFAT
	mov_tr	bp, ax
	mov	cx, ds:[DFD_startFAT]

	call	DOSFormatZeroSectorWorkArea
initLoop:
	call	DOSFormatWriteWorkArea
	mov	ax, FMT_ERR_WRITING_FAT
	jc	done

	inc	cx				;next logical sector
	dec	bp				;dec count
	jnz	initLoop

	clr	ax
done:
	ret
DOSFormatZeroFAT	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatWriteRootDirectory

DESCRIPTION:	Initialize the Root Directory portion of the disk.

CALLED BY:	INTERNAL (DOSFormatWriteAdminStuff)

PASS:		ds - DiskFormatData

RETURN:		carry set on error
		ax - 0 if successful, FMT_ERR_WRITING_ROOT_DIR if not

DESTROYED:	bx, bp, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	for number of sectors in root dir do
		write zeroed sector out to next sector
	end for

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version
	ardeb	4.9.92		IFS version

-------------------------------------------------------------------------------@

DOSFormatWriteRootDirectory	proc	near
	mov	bp, ds:[DFD_rootDirSize]
	mov	cx, ds:[DFD_startRoot]

	call	DOSFormatZeroSectorWorkArea
initLoop:
	call	DOSFormatWriteWorkArea
	mov	ax, FMT_ERR_WRITING_ROOT_DIR
	jc	done
	inc	cx				;next logical sector
	dec	bp				;dec count
	jnz	initLoop

	clr	ax
done:
	ret
DOSFormatWriteRootDirectory	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatVerifyKeyTracks

DESCRIPTION:	Verify the integrity of the important tracks on the disk.

CALLED BY:	(INTERNAL) DOSFormatWriteAdminStuff

PASS:		ds - DiskFormatData

RETURN:		carry set on error
		ax - 0 if successful,
		     else one of:
			FMT_ERR_WRITING_BOOT
			FMT_ERR_WRITING_ROOT_DIR
			FMT_ERR_WRITING_FAT

DESTROYED:	bx,cx,dx,bp,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version

-------------------------------------------------------------------------------@

DOSFormatVerifyKeyTracks proc	near
	uses	ds, es
	.enter

	;
	; Point DS to the sector buffer for the duration.
	; 
	mov	ax, ds:[DFD_sectorBuffer]
	mov	bx, ds
	mov	es, bx
	mov	ds, ax

	call	SysLockBIOS
	
	;
	; Flush any sectors out of the cache, so we can be reasonably
	; certain the thing's going to the disk.
	; 
	mov	ah, MSDOS_RESET_DISK
	call	DOSUtilInt21

	;
	; Now read all the sectors that make up the administrative part of
	; the disk, i.e. up to the first data sector.
	; 
	clr	dx				;logical sector 0
if PZ_PCGEOS
;seems like this would be the right thing for a DOS call
	mov	al, es:[DFD_formatArgs].FSFA_drive
else
	mov	al, es:[DFD_biosDrive]
endif
	mov	cx, 1				;specify 1 sector

verifyLoop:
	;
	; Read this sector.
	; 
	clr	bx				;ds:bx <- buffer for read
	push	ax,cx,dx
	int	25h
	inc	sp				; throw away flags from int
	inc	sp
	mov_tr	bx, ax
	pop	ax,cx,dx
	jc	error
	;
	; Advance to next sector.
	; 
	inc	dx
	cmp	dx, es:[DFD_startFiles]		;done all sectors?
	jne	verifyLoop			; no
	clr	ax				;ax <- 0, clear C
	jmp	done

error:
	;
	; Cope with attempting 16-bit read on 32-bit device when drive
	; managed by some driver other than us. We should get back
	; ERROR_UNKNOWN_MEDIA, suitably massaged, according to Drew @
	; Datalight, in which case we'll try a 32-bit read.
	; 
	cmp	bl, CE_UNKNOWN_MEDIA
	je	verify32Bit		; go do entire verification with 32-bit
					;  stuff
	
returnError:
	;
	; Figure in what part of the administrative data the error lies and
	; return the appropriate error code.
	; 
	mov	ax, FMT_ERR_WRITING_BOOT
	cmp	dx, es:[DFD_startFAT]
	jb	doneError

	mov	ax, FMT_ERR_WRITING_FAT
	cmp	dx, es:[DFD_startRoot]
	jb	doneError

	mov	ax, FMT_ERR_WRITING_ROOT_DIR

doneError:
	stc
done:
	call	SysUnlockBIOS

	.leave
	ret

verify32Bit:
	;
	; Read this sector.
	; 
	clr	bx
	pushdw	dsbx			; address of buffer
	inc	bx			; (1-byte inst)
	push	bx			; # sectors
	dec	bx			; (1-byte inst)
	pushdw	bxdx			; starting sector
	segmov	ds, ss			; ds:bx <- parameter block
	mov	bx, sp
	mov	di, es:[DFD_startFiles]
verify32BitLoop:
	push	ax			; save drive # across call
	mov	cx, -1			; Indicate read on huge
	int	25h
	inc	sp				; throw away flags from int
	inc	sp
	pop	ax
	mov	bx, sp			; re-establish BX for loop and
					;  sector increment
	jc	return32BitError

	inc	{word}ds:[bx]		; advance to next sector
	cmp	di, ds:[bx]		; done?
	jne	verify32BitLoop		; no...

	lea	sp, [bx+8]		; yes, clear all but saved DS off
					;  the stack
	pop	ds
	clr	ax			; ax <- 0, clear carry
	jmp	done

return32BitError:
	pop	dx			; dx <- erroneous sector
	lea	sp, [bx+8]
	pop	ds
	jmp	returnError
DOSFormatVerifyKeyTracks	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatGetNumClusters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the number of clusters on the disk.

CALLED BY:	(INTERNAL) DOSFormatAllocFATBuffer,
			   DOSFormatQFreeAllGoodClusters
PASS:		ds	= DiskFormatData
RETURN:		ax	= # clusters
DESTROYED:	bx, dx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 8/92 	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatGetNumClusters proc	near
		.enter
		call	DOSFormatInitGetNumSectors ; dxax <- #
		sub	ax, ds:[DFD_startFiles]	;ax <- num sectors in
						; files area
		sbb	ax, 0

		mov	bl, ds:[DFD_bpb].BPB_clusterSize
		clr	bh
		div	bx				;ax <- num clusters

		inc	ax		; must include the 2 reserved
		inc	ax		;  clusters, else FAT will be the
					;  wrong size...
		.leave
		ret
DOSFormatGetNumClusters endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatAllocFATBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a buffer to hold an entire copy of the FAT as a
		bitmap.

CALLED BY:	(INTERNAL) DOSFormatFilesArea, DOSFormatCheckAndPerformQuick
PASS:		ds	= DiskFormatData
RETURN:		carry set if couldn't allocate buffer:
			ax	= FMT_ERR_WRITING_FAT
			bx	= destroyed
		carry clear if buffer allocated:
			ax, es	= segment of locked buffer
			bx	= handle of buffer
			ds:[DFD_fat] = handle of buffer
			bp	= 0 if 12-bit FAT, non-zero if 16-bit
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatAllocFATBuffer proc	near
		.enter
	;-----------------------------------------------------------------------
	;make ax contain num clusters
	;
	;num clusters = (num sectors - start files area) DIV cluster size
		call	DOSFormatGetNumClusters

	;-----------------------------------------------------------------------
	;make bp contain 12/16 bit FAT format indicator

		clr	bp				;assume 12 bit format
		cmp	ax, FAT_16_BIT_THRESHOLD	;16 bit format required?
		jb	calcFATSize			;branch if not
		dec	bp				;else modify value
calcFATSize:
	;-----------------------------------------------------------------------
	;allocate space for FAT in mem
	;ax = num clusters
		add	ax, 7
		rcr	ax			; can only carry out one bit
		shr	ax			;  so only have to shift one
		shr	ax			;  into the low word

	;allocate the block
		mov	cx, (mask HAF_ZERO_INIT shl 8) or ALLOC_DYNAMIC_LOCK
		call	MemAlloc			;ax <- func(ax,ch),
							; destroys cx
		jnc	haveFATBuffer
		mov	ax, FMT_ERR_WRITING_FAT
		jmp	exit

haveFATBuffer:
		mov	ds:[DFD_fat], bx
		mov	es, ax
exit:
		.leave
		ret
DOSFormatAllocFATBuffer endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatFilesArea

DESCRIPTION:	Formats the Files Area portion of the disk and builds
		the FAT at the same time. The FATs are written out when
		formatting is done.

CALLED BY:	INTERNAL (DOSDiskFormat)

PASS:		ds - DiskFormatData

RETURN:		carry set on error
		ax - 0 if successful, FMT_ERR_? if not

DESTROYED:	bx, cx, dx, bp, es, di, si

REGISTER/STACK USAGE:
	ax - general purpose
	bx - current FAT sector
	cl - current sector
	dl - drive
	bp - 12/16 bit increment value (0 or 1)
	di - offset into sector work area to current FAT entry
	si - track count

PSEUDO CODE/STRATEGY:
	process Files Area sectors in last root dir track
	for all subsequent tracks
		format and verify track
		if ok then
			zero out FAT entries
		else
			verify clusters in track individually
		endif
		make note of unprocessed sectors


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@

DOSFormatFilesArea	proc	near
		uses	ds
		.enter
	;
	; Figure the number of data sectors that lie at the end of the final
	; root-directory track, storing that value in DFD_unprocessedDataSectors
	; so we take care of their clusters properly (they're all good or we
	; wouldn't be here).
	; 
		mov	ax, ds:[DFD_startFiles] ;get logical sector number
		clr	dx
		mov	si, ds:[DFD_bpb].BPB_sectorsPerTrack
		div	si			;dx <- ax mod sectors per track

		sub	si, dx			;calc num unprocessed sectors
		mov	ds:[DFD_unprocessedDataSectors], si

	;
	; Now allocate a buffer for the FAT.
	; 
		call	DOSFormatAllocFATBuffer
		jc	exit

	;-----------------------------------------------------------------------
	;reserve the first 2 FAT entries, as expected
	;mark them BAD, though. FAT write-out code will take care
	;of setting them properly.
	;
		mov	ds:[DFD_fatMask], 1 shl 2
		clr	di				;init FAT entry offset
		mov	ds:[DFD_fatOffset], di
		mov	{byte}es:[0], 00000011b

		call	MemUnlock		;release the FAT

	;-----------------------------------------------------------------------
	;ds = DiskFormatData
	;bp = FAT format flag (TRUE if 16-bit)

EC<		mov	ax, ds:[DFD_bpb].BPB_sectorsPerTrack		>
EC<		cmp	ax, ds:[DFD_unprocessedDataSectors] 		>
EC<		ERROR_B	FORMAT_ASSERTION_FAILED	; more unprocessed sectors>
EC <						; than fit on a track	>

	;
	; Process clusters left over from the root directory track.
	; 
		call	DOSFormatProcessClusters

		mov	si, ds:[DFD_numTracks]
		sub	si, ds:[DFD_lastRootDirTrack]	;si <- num tracks to
							; process
formatLoop:
	;
	; Format the next track on the disk.
	; 
		push	cx, dx
		mov	cx, ds:[DFD_curCylinder]	;init param table
		mov	dx, ds:[DFD_curHead]
		call	DOSFormatTrack
		pop	cx, dx				;ch <- cylinder,
							; dh <- head
		jnc	trackOK
	;
	; Error formatting the track. If format aborted by user, then stop
	; in our tracks.
	; 
		cmp	ax, FMT_ABORTED
		stc
		je	exit

	;
	; format/verify track failed, verify clusters individually
	;
		call	DOSFormatProcessBadTrack
		jmp	nextTrack
trackOK:
	;
	; Mark this track's sectors as unprocessed for DOSFormatProcessClusters
	; 
		mov	ax, ds:[DFD_bpb].BPB_sectorsPerTrack
		add	ds:[DFD_unprocessedDataSectors], ax
		call	DOSFormatProcessClusters	;func(ds,bp), destroys
							; ax
nextTrack:
		mov	ax, ds:[DFD_curHead]
		inc	ax				;next head
		cmp	ax, ds:[DFD_bpb].BPB_numHeads	;valid head number?
		jb	storeHead			;branch if so

		clr	ax				;else reset head to 0
		inc	ds:[DFD_curCylinder]		;next cylinder
storeHead:
		mov	ds:[DFD_curHead], ax
		dec	si				; another track down
		jne	formatLoop

		call	DOSFormatProcessClusters	;process remaining
							; sectors
	;
	; Write however many copies of the FAT are required by the format.
	; 
		call	DOSFormatWriteFATs
exit:
		.leave
		ret
DOSFormatFilesArea	endp

if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DFAssertBPNotTrashed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure bp hasn't been munged, but is still either 0
		(12-bit FAT) or -1 (16-bit FAT)

CALLED BY:	INTERNAL
PASS:		bp
RETURN:		only if BP ok
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DFAssertBPNotTrashed proc near
		.enter
		tst	bp
		je	done
		cmp	bp, -1
		ERROR_NZ FORMAT_ASSERTION_FAILED
done:
		.leave
		ret
DFAssertBPNotTrashed endp
endif ; ERROR_CHECK


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatProcessClusters

DESCRIPTION:	Track was formatted and verified successfully. Update the
		appropriate number of FAT entries.

CALLED BY:	INTERNAL (DOSFormatFilesArea)

PASS:		ds - DiskFormatData
		bp - FAT format flag (TRUE if 16-bit)
		di - offset to first cluster entry for the just-formatted
		     track

RETURN:		di - offset to next cluster entry
		ds:[DFD_unprocessedDataSectors] = number of sectors from
		   this track that weren't marked as part of a good cluster,
		   owing to the cluster size and the number of sectors per
		   track.

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
		Since all the sectors were good and the FAT buffer was
		allocated zero-initialized, we have only to count the
		number of clusters the sectors were, adding that to
		DFD_goodClusters, and advance the cluster pointer (di)
		appropriately, along with setting the DFD_fatToggle correctly,
		if the FAT is using 12-bit entries.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version
	ardeb	4.9.92		IFS version

-------------------------------------------------------------------------------@


DOSFormatProcessClusters	proc	near
		uses	cx, dx
		.enter
EC <		call	DFAssertBPNotTrashed

	;
	; Compute the number of clusters in the track just successfully
	; formatted.
	;
		mov	ax, ds:[DFD_unprocessedDataSectors]
		tst	ax
		jz	done			; => no sectors were actually
						;  formatted...?

		mov	cl, ds:[DFD_bpb].BPB_clusterSize
		cmp	cl, 1			;cluster size = 1?
		je	trivial			;branch if so

		clr	dx			; zero-extend both # sectors
		mov	ch, dh			;  and cluster size
		div	cx			;ax <- complete clusters present
		mov	ds:[DFD_unprocessedDataSectors], dx	;save remainder
								; for next track
		jmp	clustersComputed
trivial:
	;
	; Trivial case of above computation: no sectors will be left b/c each
	; sector is a cluster.
	;
		mov	ds:[DFD_unprocessedDataSectors], 0

clustersComputed:
	;
	; Add all the clusters from this track into the number of good clusters
	; on the disk so far.
	;
		add	ds:[DFD_goodClusters], ax
		mov	cx, ax				;cx <- num clusters

	;
	; First skip over the clusters in the current byte that haven't
	; been processed.
	; 
		mov	al, ds:[DFD_fatMask]
skipBeginLoop:					; could be done with
						;  binary search, but...
		shl	al
		loopnz	skipBeginLoop
		jnz	clustersSkipped		; ran out of clusters in the
						;  loop -- leave al set to the
						;  mask for next time, and
						;  DFD_fatOffset remains as
						;  it was

		inc	di
	;
	; Now skip the whole bytes that represent clusters that are in this
	; range.
	; 
		mov	ax, cx
		andnf	ax, 0x7			; al <- left-over clusters
		shr	cx			; convert middle clusters to
		shr	cx			;  # of bytes to skip
		shr	cx
		add	di, cx			; skip that many
	;
	; Finally, set DFD_fatMask to the mask for the first cluster yet
	; unprocessed in the now-current byte.
	; 
		mov_tr	cx, ax
		mov	al, 1
		shl	al, cl
clustersSkipped:
		mov	ds:[DFD_fatMask], al
done:
		.leave
		ret
DOSFormatProcessClusters	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatProcessBadTrack

DESCRIPTION:	When FormatTrack fails, the clusters corresponding to
		the sectors on the track are marked as bad.

		The original approach was to go through and verify each sector
		to recover as much space as possible but int 13h function 4
		turned out to be very unreliable since it often returns OK
		with sectors that turn out to be bad. (This must be because
		all it does is verify the sector address mark).

		This 'verification' approach can be pursued and an actual
		write, read, verify can be done for each sector but for
		simplicity, it is not.  The original code has been commented
		out rather than deleted for any future endeavors in this regard.

		DOS seems to take the approach we do, which is to mark all
		corresponding clusters as bad. This conclusion is drawn
		from status comparisons at the end of our format and DOS's
		format on the same disk.

CALLED BY:	(INTERNAL) DOSFormatFilesArea

PASS:		bp - FAT format flag (TRUE if 16-bit)
		ds - DiskFormatData
		di - offset to current cluster entry
		ds:[DFD_fatToggle] (for 12-bit FAT)
		ds:[DFD_curCylinder]
		ds:[DFD_curHead]
		ds:[DFD_unprocessedDataSectors] = sectors from previous track
			that go into the first bad cluster of this track. if
			negative, it's the number of sectors in this track
			that have already been included as the last bad cluster
			of the previous track.

RETURN:		di - offset to next cluster entry
		ds:[DFD_fatToggle] = 1 or 0 (for 12-bit FAT)
		ds:[DFD_unprocessedDataSectors] = -(number of sectors used from
		   next track as part of the last bad cluster on this track)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	format/verify track failed for some reason
	if (unprocessedSectors != 0) {
		add to sectors/track and use sum to figure # clusters
		this also takes care of unprocessedSectors < 0
	}
	divide # sectors by cluster size.
	if any remainder {
		unprocessSectors = remainder - cluster size
		#clusters += 1
	} else {
		unprocessedSectors = 0
	}

	add # bad clusters to DFD_badClusters
	lock FAT buffer
	foreach bad cluster
		set FAT entry to FAT_CLUSTER_BAD

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	if bios verify track is used, take care of upper 2 bits of 10-bit
	cylinder number in cl

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version
	ardeb	4.9.92		IFS version

-------------------------------------------------------------------------------@

DOSFormatProcessBadTrack	proc	near
		uses	ax, cx, dx
		.enter
EC <		call	DFAssertBPNotTrashed				>

		mov	ax, ds:[DFD_bpb].BPB_sectorsPerTrack
		mov	cx, ds:[DFD_unprocessedDataSectors]
		jcxz	computeNumberOfClusters
		add	ax, cx			; ax <- # sectors involved.
						;  increases if sectors from
						;  previous track involved;
						;  decreases if some of this
						;  track's sectors were stolen
						;  by previous bad track
computeNumberOfClusters:
	; ax = # sectors to mark bad
		mov	cl, ds:[DFD_bpb].BPB_clusterSize
		clr	dx			; zero-extend # sectors
		mov	ch, dl			;  and cluster size

		div	cx			; ax <- # clusters,
						;  dx <- remainder

		tst	dx
		jz	storeNumberUnprocessed
		sub	dx, cx			; dx <- -(number stolen from
						;  next track). we steal enough
						;  to make up a complete
						;  final cluster, of course.
		inc	ax			; 1 more cluster to mark bad
storeNumberUnprocessed:
		mov	ds:[DFD_unprocessedDataSectors], dx
	
		add	ds:[DFD_badClusters], ax
		mov_tr	cx, ax			; cx <- # clusters to mark bad

	;
	; Lock down the FAT buffer so we can actually mark things.
	; 
		mov	bx, ds:[DFD_fat]
		call	MemLock
		mov	es, ax
	;
	; Now mark them. (could be done "more efficiently" perhaps by computing
	; beginning and ending masks and storing 0xff in the intermediate bytes,
	; but this is a rare occurrence and it's not that bad to or in the bytes
	; so that's what we do, for the sake of simplicity)
	; 
		mov	al, ds:[DFD_fatMask]
markLoop:
		ornf	es:[di], al
		shl	al
		loopnz	markLoop
		jnz	markDone		; => ran out of clusters, so
						;  don't advance DI or reset AL

		inc	di			; ran out of byte, so advance
		mov	al, 1			;  to next and reset mask
		tst	cx
		jnz	markLoop
markDone:
		mov	ds:[DFD_fatMask], al
	;
	; Marking is complete. DI and ds:[DFD_fatMask] point properly to
	; indicate the next cluster to mark one way or the other, so unlock the
	; FAT buffer until we need it again.
	; 
		call	MemUnlock
		.leave
		ret
DOSFormatProcessBadTrack	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatWriteFATs

DESCRIPTION:	Write out however many copies of the FAT are required.

CALLED BY:	(INTERNAL) DOSFormatFilesArea

PASS:		ds - DiskFormatData
		ds:[DFD_fat] = handle of unlocked buffer holding FAT
			       to write.
		bp - FAT format flag (TRUE if 16-bit)

RETURN:		carry set on error
		ax - 0 if successful, FMT_ERR_WRITING_FAT if not

DESTROYED:	bx, cx, dx, bp, di, si, es

PSEUDO CODE/STRATEGY:
	You would think we could do something reasonable like find the
	number of sectors in a FAT, point to the FAT buffer we've allocated
	and call DOSWriteSectors to write them all out. You'd be wrong.
	
	The problem lies in the DMA system of the PC, which can't DMA things
	across a 64K linear boundary, which our buffer, in all its glory,
	could well cross.
	
	So we copy the FAT into our sector-buffer work area sector by sector
	and write each one out.
	
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	One possible optimization is to use each filled-in sector buffer to
	write the appropriate sector in each copy of the FAT before moving
	on to the next sector in the FAT. I don't know what an impact that
	would have on the process, as far as seek time etc. are concerned

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version
	ardeb	10/8/92		Ported to IFS driver

-------------------------------------------------------------------------------@

DOSFormatWriteFATs	proc	near
	mov	al, ds:[DFD_bpb].BPB_numFATs
	clr	ah
	mov	di, ax

	;
	; Loop through building each sector in our work area and writing it out
	; to each FAT.
	; 

	mov	dx, ds:[DFD_startFAT]
	mov	cx, ds:[DFD_bpb].BPB_sectorsPerFAT
	clr	si
	mov	ax, 1			; al <- cluster mask bit,
					; ah <- byte left over from previous
					;  sector (nothing)
	mov	ds:[DFD_fatToggle], 0	; doing even cluster, if 12-bit
	clr	di			; start storing at beginning of sector
sectorLoop:
	call	DOSFormatCreateFATSector
	call	DOSFormatWriteFATSector	; write to all FATs
	jc	fatWriteError
	inc	dx			; advance to next sector
	loop	sectorLoop
done:
	ret

fatWriteError:
	mov	ax, FMT_ERR_WRITING_FAT
	jmp	done

DOSFormatWriteFATs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatCreateFATSector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create one sector of the FAT in the work area based on the
		bitmask for the current range of clusters

CALLED BY:	(INTERNAL) DOSFormatWriteFATs
PASS:		ds	= DiskFormatData
		si	= byte offset within FAT bitmap
		al	= bit mask of first cluster to store in sector
		di	= offset within sector at which to start storing
			  (0 or 1)
		ah	= byte to store as the first of the sector (carry-
			  over from previous sector)
		bp	= non-zero if 16-bit FAT
RETURN:		di, ah, si, al	= updated
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatCreateFATSector proc	near
fatSize		local	word			\
		push	bp
workArea	local	sptr.DiskFormatData	\
		push	ds
fatToggle	local	byte
		uses	bx, cx, dx, ds, es
		.enter
	;
	; Initialize the sector buffer to all 0's so we just have to OR
	; things in if the cluster is bad...
	; 
		call	DOSFormatZeroSectorWorkArea	; es <- work area
	;
	; Fetch various things out of our DiskFormatData before we lock down
	; the FAT bitmask.
	; 
		mov	bx, ds:[DFD_fat]
		mov	cx, ds:[DFD_bpb].BPB_sectorSize
		sub	cx, di			; adjust by # bytes being
						;  used by carry-over from
						;  previous sector
		push	ax
		mov	al, ds:[DFD_fatToggle]
		mov	ss:[fatToggle], al
		call	MemLock
		mov	ds, ax
		pop	ax
		
		mov	es:[0], ah		; store carry-over byte

		mov	ah, al			; ah <- bit to check
	;
	; New stuff: in case byte offset is 0 (AH==1), we don't need to care
	; about bits for clusters left over from last byte of previous sector
	; 				-simon (11/10/94)
	;
		cmp	ah, 1
		je	haveBitsForFirstCluster	; nothing left from previous
						; byte 

		mov	al, ds:[si-1]		; al <- bits for clusters
						;  left over from last byte
						;  of previous sector
haveBitsForFirstCluster:
		tst	ss:[fatSize]
		jnz	create16Bit
	;
	; Create a 12-bit sector. Much more fun.
	; 
		call	DOSFormatCreate12BitFATSector
markDone:
		mov	ds, ss:[workArea]
		mov	bx, ds:[DFD_fat]
		call	MemUnlock
		mov	bl, ss:[fatToggle]
		mov	ds:[DFD_fatToggle], bl
		.leave
		ret

create16Bit:
		call	DOSFormatCreate16BitFATSector
		jmp	markDone
DOSFormatCreateFATSector endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatCreate12BitFATSector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a FAT sector for a 12-bit FAT

CALLED BY:	(INTERNAL) DOSFormatCreateFATSector
PASS:		ds:si	= next byte within the FAT bitmap to process
		ah	= mask of current bit to check
		al	= byte within which to look for it
		es:di	= place within sector work area into which to
			  merge the bad cluster mark for the next cluster
		cx	= number of bytes left in the sector work area
RETURN:		ah	= carry-over byte for the next sector
		di	= offset at which to start storing in the next
			  sector
		al	= mask for first cluster in next sector
		ds:si	= thing to pass for next sector (points to next
			  byte in bitmask to process)
DESTROYED:	bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		During the loop, bx holds the value to OR in if this cluster
		is bad, while dx holds the value to OR in if the next cluster
		is bad. They hold the "bad cluster" mark either left-justified
		or shifted left 4 bits, depending on whether the current
		cluster is "even" (starts on a byte boundary in the FAT)
		or "odd" (starts with the high nibble of the current byte)

        ;Pretty Diagrams:
        ;       0   1   2   3   4   5
        ;       +---+---+---+---+---+---+
        ;       | c1  |  c2 | c3  |  c4 |
        ;       +---+---+---+---+---+---+
        ;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatCreate12BitFATSector proc	near
		.enter	inherit	DOSFormatCreateFATSector
	;
	; Set bx/dx appropriately, depending on whether the first cluster
	; of this sector is even or odd.
	; 
		mov	bx, FAT_CLUSTER_BAD and 0xfff
		mov	dx, (FAT_CLUSTER_BAD and 0xfff) shl 4
		tst	ss:[fatToggle]
		jz	markLoop
		xchg	bx, dx
markLoop:
	;
	; If we're back to the first bit of the next byte, load the next
	; byte into AL, advancing SI
	; 
		cmp	ah, 1
		jne	checkCluster
		lodsb
checkCluster:
	;
	; If we're only going to get 8 or 4 bits (even or odd cluster, resp.)
	; of this cluster into this sector, handle it specially
	; 
		cmp	cx, 1
		je	handlePartialCluster
	;
	; Entire cluster will fit within this sector. If the cluster isn't
	; bad, we need do nothing, as the thing is already 0 (free).
	; 
		test	al, ah
		jz	nextCluster
	;
	; If the cluster is in the first byte, it may be one of the two
	; reserved ones that require special treatment.
	; 
		cmp	si, 1
		je	maybeStoreMedia
markBad:
		ornf	es:[di], bx
nextCluster:
	;
	; Advance to the next cluster.
	; 
		xchg	bx, dx			; swap bad-cluster values
		rol	ah			; rotate the cluster bit
						;  mask to the next bit. If
						;  it comes back to 1, we'll
						;  reload AL at the top of
						;  the loop.
		inc	di			; always need to advance by 1
						;  at least
		dec	cx			; which consumes a byte...can't
						;  be 0 as we checked for cx==1
						;  earlier
		xor	ss:[fatToggle], 1
		jnz	markLoop		; now odd, so advance only
						;  one byte
		inc	di			; now even, so skip high
		dec	cx			;  byte of odd cluster
		jnz	markLoop		; loop if more bytes in the
						;  sector
	;
	; Sector is complete.
	; 
		clr	dx, di			; don't alter first byte of
						;  next sector, but start
						;  storing things there...
done:
		mov	al, ah
		mov	ah, dh			; first byte of next sector
						;  should be set to high byte
						;  of bad cluster for prev
						;  cluster type, since we
						;  always swap them and prev
						;  cluster type is the one
						;  that's incomplete
		.leave
		ret

handlePartialCluster:
	;
	; There's only one byte left in this sector, so we need to set it
	; as we think appropriate and set things up so the first byte/nibble
	; of the next sector is also set properly.
	; 
		test	al, ah			; cluster bad?
		jnz	markPartialBad		; => yes
		clr	bx			; no -- make sure first byte of
						;  next sector is left 0
partialDone:
		xchg	bx, dx			; swap bad-cluster values
		clr	di			; assume now even, so want to
						;  start in 0th byte
		xor	ss:[fatToggle], 1
		jnz	done			; was odd, so DI is right

		inc	di			; start w/byte 1 (high byte
						;  of odd cluster takes up
						;  entire byte 0)
		jmp	done

markPartialBad:
		ornf	es:[di], bl
		jmp	partialDone

	;--------------------
maybeStoreMedia:
	;
	; Cluster in first byte of bitmask is bad, so we may have to store
	; the media descriptor or 0xfff for the cluster.
	; 
		cmp	ah, 1 shl 2
		jae	markBad			; => not reserved

		push	bx, ds
		mov	ds, ss:[workArea]
		mov	bl, ds:[DFD_bpb].BPB_mediaDescriptor
		mov	bh, 0x0f
		cmp	ah, 1 shl 0
		je	setReservedCluster
		mov	bx, 0xfff shl 4
setReservedCluster:
		ornf	es:[di], bx
		pop	bx, ds
		jmp	nextCluster

DOSFormatCreate12BitFATSector endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatCreate16BitFATSector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a FAT sector for a 16-bit FAT

CALLED BY:	(INTERNAL) DOSFormatCreateFATSector
PASS:		ds:si	= next byte within the FAT bitmap to process
		ah	= mask of current bit to check
		al	= byte within which to look for it
		es:di	= place within sector work area into which to
			  merge the bad cluster mark for the next cluster
		cx	= number of bytes left in the sector work area
RETURN:		ah	= carry-over byte for the next sector
		di	= offset at which to start storing in the next
			  sector
		al	= mask for first cluster in next sector
		ds:si	= thing to pass for next sector (points to next
			  byte in bitmask to process)
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		This is pretty straight-forward, since we're dealing with
		words, which won't cross sector boundaries.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatCreate16BitFATSector proc	near
		.enter	inherit	DOSFormatCreateFATSector
markLoop:
	;
	; If we're back to the first bit of the next byte, load the next
	; byte into AL, advancing SI
	; 
		cmp	ah, 1
		jne	checkCluster
		lodsb
checkCluster:
	;
	; If the cluster isn't bad, we need do nothing, as the thing is already
	; 0 (free).
	; 
		test	al, ah
		jz	nextCluster
	;
	; If the cluster is in the first byte, it may be one of the two
	; reserved ones that require special treatment.
	; 
		cmp	si, 1
		je	maybeStoreMedia
markBad:
		mov	es:[di], FAT_CLUSTER_BAD
nextCluster:
	;
	; Advance to the next cluster.
	; 
		rol	ah			; rotate the cluster bit
						;  mask to the next bit. If
						;  it comes back to 1, we'll
						;  reload AL at the top of
						;  the loop.
		inc	di
		inc	di
		dec	cx
		loop	markLoop
	;
	; Sector is complete.
	; 
		clr	di			; start storing at first
						;  byte of next sector
		mov	al, ah			; al <- mask for first cluster
						;  in next sector
		clr	ah			; first byte of next sector
						;  should be left alone
		.leave
		ret

maybeStoreMedia:
	;
	; Cluster in first byte of bitmask is bad, so we may have to store
	; the media descriptor or 0xfff for the cluster.
	; 
		cmp	ah, 1 shl 2
		jae	markBad			; => not reserved

		push	bx, ds
		mov	ds, ss:[workArea]
		mov	bl, ds:[DFD_bpb].BPB_mediaDescriptor
		mov	bh, 0xff
		cmp	ah, 1 shl 0
		je	setReservedCluster
		mov	bx, 0xffff
setReservedCluster:
		mov	es:[di], bx
		pop	bx, ds
		jmp	nextCluster

DOSFormatCreate16BitFATSector endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatWriteFATSector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the sector generated in the sector work area out to
		all the FATs for the disk.

CALLED BY:	(INTERNAL) DOSFormatWriteFATs
PASS:		dx	= sector within first FAT
		ds	= DiskFormatData
RETURN:		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatWriteFATSector	proc near
		uses	ax, bx, cx, dx, si, di, ds, es
		.enter

	;
	; Fast case: use DOSWriteSectors to write the entire FAT at one fell
	; swoop.
	; 
		mov	si, ds:[DFD_formatArgs].FSFA_dse
		mov	cl, ds:[DFD_bpb].BPB_numFATs
		clr	ch
		mov	bx, ds:[DFD_bpb].BPB_sectorsPerFAT
		call	FSDLockInfoShared
		mov	es, ax		; es:si <- DriveStatusEntry
if PZ_PCGEOS
		mov	al, ds:[DFD_formatArgs].FSFA_media
endif
		mov	ds, ds:[DFD_sectorBuffer]
		clr	di		; ds:di <- buffer to write
fatLoop:
		push	bx, cx
		clr	bx		; bxdx = sector to write
		mov	cx, 1		; 1 sector at a time, please
if PZ_PCGEOS
	;
	; for Pizza's 1.232M 3.5", we use 1024 byte sectors
	;
		cmp	al, MEDIA_1M232
		jne	not1M232
		shl	cx, 1		; #sectors*2
		shldw	bxdx		; start sector*2
not1M232:
endif
		call	DOSWriteSectors
		pop	bx, cx
		jc	done

		add	dx, bx			; advance to next FAT
EC <		ERROR_C	GASP_CHOKE_WHEEZE				>

		loop	fatLoop
		clc
done:
		call	FSDUnlockInfoShared
		.leave
		ret
DOSFormatWriteFATSector	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatZeroSectorWorkArea

DESCRIPTION:	Zero out the sector work area.

CALLED BY:	INTERNAL

PASS:		ds - DiskFormatData

RETURN:		es = sector buffer, initialized to 0

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version
	ardeb	4.9.92		IFS version

-------------------------------------------------------------------------------@

DOSFormatZeroSectorWorkArea	proc	near
		uses	ax, cx, di
		.enter
		mov	es, ds:[DFD_sectorBuffer]
		clr	ax
		mov	di, ax
if PZ_PCGEOS
		mov	cx, ds:[DFD_bpb].BPB_sectorSize
		shr	cx, 1
else
		mov	cx, MSDOS_STD_SECTOR_SIZE / 2
endif
		cld
		rep	stosw
		.leave
		ret
DOSFormatZeroSectorWorkArea	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatWriteWorkArea

DESCRIPTION:	Writes the sector work area out to disk.

CALLED BY:	INTERNAL

PASS:		es - seg addr of sector work area
		cx - logical sector number
		ds - DiskFormatData

RETURN:		ax - error code
		carry set on error

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@

DOSFormatWriteWorkArea	proc	near
	uses	bx, cx, dx, si, ds, es
	.enter

	call	FSDLockInfoShared
	push	es
	mov	es, ax
	mov	si, ds:[DFD_formatArgs].FSFA_dse		;specify drive
if PZ_PCGEOS
	mov	al, ds:[DFD_formatArgs].FSFA_media
	mov	ah, ds:[DFD_biosDrive]
endif
	pop	ds
	clr	di				;ds:di <- buffer
	clr	bx
	mov	dx, cx				;bx:dx <- sector number
	mov	cx, 1				;specify num sectors
if PZ_PCGEOS
	;
	; force BIOS usage for track 0
	;
	push	{word} es:[si].DSE_number
	cmp	al, MEDIA_1M232
	jne	10$
	shl	cx, 1				;number of sectors*2
	shldw	bxdx				;start sector*2
	cmp	es:[si].DSE_number, 2
	jb	10$
	cmp	dx, MAX_NON_CACHE
	jae	10$
	mov	es:[si].DSE_number, ah
10$:
endif
	call	DOSWriteSectors
if PZ_PCGEOS
	;
	; undo hack
	;
	pop	cx
	mov	es:[si].DSE_number, cl
	pushf
	push	ax
	mov	ah, 0				; reset
	mov	dl, ds:[DFD_biosDrive]
	call	DOSFormatInt13
	pop	ax
	popf
endif

	call	FSDUnlockInfoShared
	.leave
	ret
DOSFormatWriteWorkArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatSetName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the volume name for the disk.

CALLED BY:	(INTERNAL) DOSDiskFormat
PASS:		ds	= DiskFormatData
RETURN:		carry set on error:
			ax	= error code
		carry clear if successful
DESTROYED:	ax, bx, es, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatSetName proc	near
volFCB		local	FCB		; FCB to create new volume label (there
					;  is no other, since we biffed the
					;  root directory)
dta		local	RenameFCB	; DTA for DOS to use during volume
					;  location (needs an unopened
					;  extended FCB).
		.enter
		tst	ds:[DFD_formatArgs].FSFA_volumeName.segment
		jz	noVolumeName
		
	;
	; Perform bullshit call to locate a volume label, as appears to be
	; required by DR DOS 6.0
	; 
		mov	dl, ds:[DFD_formatArgs].FSFA_drive
		lea	di, ss:[volFCB]
		lea	bx, ss:[dta]
		push	ds
		call	DOSDiskLocateVolumeLow
		pop	ds
EC <		tst	al						>
EC <		ERROR_Z	HOW_IN_THE_HELL_DID_THIS_DISK_GET_A_VOLUME_LABEL?>

	;
	; Store the new name in the FCB.
	; 
		segmov	es, ss
		lea	di, ss:[volFCB].FCB_name
		push	ds
		lds	si, ds:[DFD_formatArgs].FSFA_volumeName
		call	DOSDiskCopyAndMapVolumeName
		pop	ds
	;
	; Tell DOS to create the thing.
	; 
		mov	ah, MSDOS_FCB_CREATE
		push	ds
		segmov	ds, ss
		lea	dx, ss:[volFCB]
		call	DOSUtilInt21
		pop	ds
		tst	al
		jnz	createFailed
	;
	; Now see if there's a DiskDesc whose name we need to change.
	; 
		mov	si, ds:[DFD_formatArgs].FSFA_disk
		tst	si
		jz	done
		
	;
	; Indeed there is. Lock down the FSIR shared (XXX: perhaps excl so
	; someone getting info about this disk doesn't get nailed?)
	; 
		call	FSDLockInfoShared
		mov	es, ax
	;
	; Copy the mapped name from the FCB using our standard routine.
	; 
		push	ds
		segmov	ds, ss
		add	dx, offset FCB_name
		call	DOSDiskCopyVolumeNameToDiskDesc
		pop	ds
	;
	; Make sure it's not marked nameless.
	; 
		andnf	es:[si].DD_flags, not mask DF_NAMELESS
setDiskID:
	;
	; Now copy the new ID from our data into the disk descriptor.
	; 
		mov	ax, ds:[DFD_diskID].low
		mov	es:[si].DD_id.low, ax
		mov	ax, ds:[DFD_diskID].high
		mov	es:[si].DD_id.high, ax
	;
	; Unlock the FSIR and signal our happiness
	; 
		call	FSDUnlockInfoShared
		clc
done:
		.leave
		ret

noVolumeName:
	;
	; No volume name, so see if there's a DiskDesc we need to update.
	; 
		mov	si, ds:[DFD_formatArgs].FSFA_disk
		tst	si
		jz	done
	;
	; There is. First generate a nameless name for the thing.
	; 
		call	FSDLockInfoShared
		mov	es, ax
		test	es:[si].DD_flags, mask DF_NAMELESS
		jnz	setDiskID		; keep old name if was nameless

		mov	ah, FNA_ANNOUNCE	; let user know new identifier
		call	FSDGenNameless		;  when we created it
		jmp	setDiskID

createFailed:
		mov	ax, FMT_SET_VOLUME_NAME_ERR
		stc
		jmp	done
DOSFormatSetName endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatReturnRegs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up registers for return of appropriate info to caller.

CALLED BY:	(INTERNAL) DOSDiskFormat
PASS:		ds	= DiskFormatData
RETURN:		ax:di	= bytes in good clusters
		dx:cx	= bytes in bad clusters
DESTROYED:	bx, si
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatReturnRegs proc near
		.enter
		mov	al, ds:[DFD_bpb].BPB_clusterSize
		clr	ah
		mul	ds:[DFD_bpb].BPB_sectorSize	; ax <- bytes in a
							;  cluster (must be
							;  < 64K...)
	;
	; Figure bytes in good clusters first, since we return something else
	; in DX
	; 
		push	ax
		mul	ds:[DFD_goodClusters]	; dx:ax <- bytes in good
						;  clusters
		movdw	cxdi, dxax
	;
	; Now figure bytes in bad clusters.
	; 
		pop	ax
		mul	ds:[DFD_badClusters]	; dx:ax <- bytes in bad clusters
		; cxdi = good bytes
		; dxax = bad bytes
		;
		; need axdi = good, dxcx = bad, so ax <-> cx

		xchg	ax, cx		; axdi <- good bytes
					; dxcx <- bad bytes
		clc
		.leave
		ret
DOSFormatReturnRegs endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatCleanUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after ourselves, freeing whatever buffers we
		allocated, etc.

CALLED BY:	(INTERNAL) DOSDiskFormat
PASS:		ds	= DiskFormatData
RETURN:		nothing
DESTROYED:	ds (flags preserved)
SIDE EFFECTS:	all memory allocated during the course of the format is
		    freed, including the DiskFormatData block.
		if formatting via IOCTL, previous BPB is restored.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatCleanUp proc	near
		uses	ax, bx
		.enter
		pushf
		
if DOS_FORMAT_RESTORE_BPB
		cmp	ds:[DFD_method], DFM_IOCTL
		jne	freeCommon
		
		call	DOSFormatInitRestoreBPB
freeCommon:
endif
		mov	bx, ds:[DFD_fat]
		call	freeMe

		mov	bx, ds:[DFD_sectorBufferHandle]
		call	freeMe
		
		mov	bx, ds:[DFD_blockHandle]
		call	MemFree

		popf
		.leave
		ret


	;--------------------
	;internal routine to free a block of memory if it was allocated
	;Pass:
	;	bx	= handle (possibly zero)
	;Return:
	;	nothing
	;Destroyed:
	;	bx
freeMe:
		tst	bx
		jz	freeDone
		call	MemFree
freeDone:
		retn
DOSFormatCleanUp endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatIoctl

DESCRIPTION:	Performs call to the generic I/O control interrupt for block
		devices in DOS.

CALLED BY:	INTERNAL

PASS:		cl - DosGenBlockDevFunc to call
		ds - DiskFormatData
		ds:dx - addr of parameter block

RETURN:		carry set on error:
			ax	= error code
		carry clear on success
			ax	= preserved		

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version
	ardeb	10/6/92		Initial IFS version.

-------------------------------------------------------------------------------@

DOSFormatIoctl	proc	near
	push	bx, cx, ax

	mov	ax, MSDOS_IOCTL_GEN_BLOCK_DEV
	mov	bl, ds:[DFD_biosDrive]
	inc	bl			;specify drive code (1-origin)
	mov	ch, 08h			;specify category (disk drive)
	call	DOSUtilInt21

	jnc	done
	pop	bx
	push	ax
done:
	pop	bx, cx, ax
	ret
DOSFormatIoctl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatInt13
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call int 13h services within BIOS, obeying all rules of
		the road.

CALLED BY:	(INTERNAL)
PASS:		ah	= BiosInt13Func
RETURN:		whatever is appropriate
DESTROYED:	whatever is nuked by the function
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatInt13	proc	near
		.enter
		call	SysLockBIOS
		int	13h
		call	SysUnlockBIOS
		.leave
		ret
DOSFormatInt13	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatTrack

DESCRIPTION:	Formats a disk track regardless of DOS version.

CALLED BY:	(INTERNAL) DOSFormatTracks, DOSFormatFilesArea

PASS:		ds - DiskFormatData
		cx - cylinder
		dx - head

		ds:[DFD_biosDrive]
		ds:[DFD_bpb] (BPB_sectorsPerTrack, BPB_sectorSize)

RETURN:		carry clear if successful
		carry set on error
			ax	= error code

DESTROYED:	nothing

REGISTER/STACK USAGE:
	ds - idata seg

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version

-------------------------------------------------------------------------------@

DOSFormatTrack	proc	near
	uses	cx, dx
	.enter


	cmp	ds:[DFD_method], DFM_IOCTL
	jne	useBIOS

	;-----------------------------------------------------------------------
	;Ioctl present
	;stuff Ioctl Format Track Param Block

	mov	ds:[DFD_methodData].DFMD_ioctl.DFID_fmtTrackParams.FVP_cylinder, cx
	mov	ds:[DFD_methodData].DFMD_ioctl.DFID_fmtTrackParams.FVP_head, dx

	mov	cl, DGBDF_FORMAT_AND_VERIFY_TRACK
	mov	dx, offset ds:[DFD_methodData].DFMD_ioctl.DFID_fmtTrackParams
	call	DOSFormatIoctl
	jnc	done
	;
	; Translate DOS error to FormatError.
	; 
	mov	cx, FMT_ERR_WRITE_PROTECTED
	cmp	ax, ERROR_WRITE_PROTECTED
	je	setError
	mov	cx, FMT_DRIVE_NOT_READY
	cmp	ax, ERROR_DRIVE_NOT_READY
	je	setError
	mov	cx, FMT_ERR_CANNOT_FORMAT_TRACK
setError:
	mov_tr	ax, cx		; ax <- code to return
	stc
	jmp	done

useBIOS:
	;-----------------------------------------------------------------------
	;Ioctl absent

	call	DOSFormatTrackBIOS

done:
	pushf
	push	ax
	call	DOSFormatCallCallback
	jc      aborted		; aborted, C=1, ax=FMT_ABORTED
	pop	ax
	popf
exit:
	.leave
	ret

aborted:
	pop	cx
	pop	cx
	jmp	exit
DOSFormatTrack	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatTrackBIOS

DESCRIPTION:	Formats a track on a floppy disk with no recourse to
		the IOCTL functions.

CALLED BY:	(INTERNAL) DOSFormatTrack

PASS:		ds - DiskFormatData
		cx - cylinder number
		dx - head number

RETURN:		carry clear if successful
		carry set otherwise:
			ax	= error code

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	for num sectors do
	    create address field list
	call int 13h, function 5 (format track)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version
	ardeb	10/6/92		Initial IFS version

-------------------------------------------------------------------------------@

DOSFormatTrackBIOS	proc	near
if PZ_PCGEOS
	uses	bx,cx,bp,es, di, si
else
	uses	bx,cx,bp,es, di
endif
	.enter

	;This is overhead and the price the user pays for running on DOS < 3.2.
	;Want:
	;	ch - cylinder number
	;	cl, bits 7,6 - ms 2 bits of cylinder number
	;	dh - head
	;	dl - drive
	clr	ah
	mov	al, ch		;ah <- ms 2 bits in bits 1,0
	mov	ch, cl		;ch <- cylinder number
	mov	cl, 6
	shl	ax, cl
	mov	cl, al
	or	cx, 1
	mov	dh, dl		;dh <- head
	mov	dl, ds:[DFD_biosDrive]

	segmov	es, ds			;es:bx <- buffer
	mov	bx, offset [DFD_methodData].DFMD_bios.DFBD_fmtTrackParams

	;-----------------------------------------------------------------------
	;al <- sector size code

	mov	ax, ds:[DFD_bpb].BPB_sectorSize
	mov	al, ah				;ax <- sector size / 256
	test	al, 4
	je	codeOK
	dec	al				;al <- 3 if sector size = 1024

codeOK:
	;-----------------------------------------------------------------------
	;loop to initialize address field list

	mov	bp, ds:[DFD_bpb].BPB_sectorsPerTrack
	mov	ah, 1

	push	bx
createLoop:
	;-----------------------------------------------------------------------
	;init address field list entry

	mov	es:[bx][AFE_cylinderNum], ch
	mov	es:[bx][AFE_headNum], dh
	mov	es:[bx][AFE_sectorNum], ah
	mov	es:[bx][AFE_sectorSize], al	;store sector size code
	add	bx, size AddrFieldEntry

	inc	ah				;next sector number
	dec	bp				;dec count
	jne	createLoop			;loop while not done
	pop	bx				;make bx point back to buf start

	;
	; Store the parameters we were given in vector 1eh so BIOS knows what
	; to do.
	; 
	
	push	bx, cx
	call	SysLockBIOS
	movdw	bxcx, ds:[DFD_methodData].DFMD_bios.DFBD_params
	mov	di, offset DFD_methodData.DFMD_bios.DFBD_oldParams
	mov	ax, BIOS_DISK_PARAMS_VECTOR
	call	SysCatchInterrupt
if PZ_PCGEOS
	;
	; save and set DisketteParams for Pizza's 1.232M 3.5"
	;
	cmp	ds:[DFD_formatArgs].FSFA_media, MEDIA_1M232
	jne	noSet1232M
	call	SaveAndSet1M232
;not needed
;	mov	ah, 0				;reset
;	call	DOSFormatInt13
noSet1232M:
endif
	pop	bx, cx

	;-----------------------------------------------------------------------
	;ch - cylinder
	;dh - head
	;dl - drive number
	;es:bx - buffer addr

	mov	ds:[DFD_methodData].DFMD_bios.DFBD_tryCount, B13F_FORMAT_RETRIES
	clr	di				; no error yet.
doFormat:
	;-----------------------------------------------------------------------
	;stuff disk base table entry with correct number of sectors
	;some way around this?

	mov	ah, B13F_FORMAT_TRACK			;BIOS format track
	mov	al, ds:[DFD_bpb].BPB_sectorsPerTrack.low
if PZ_PCGEOS
	;
	; for some reason, this is what they do
	;
	cmp	ds:[DFD_formatArgs].FSFA_media, MEDIA_1M232
	jne	noFakeCount
	mov	al, 1
noFakeCount:
endif
	call	DOSFormatInt13
	jc	tryAgain

	mov	ah, B13F_VERIFY_SECTORS
	mov	al, ds:[DFD_bpb].BPB_sectorsPerTrack.low
	mov	cl, 1				; starting sector
	call	DOSFormatInt13
	jc	tryAgain

	jmp	short done

tryAgain:
	mov	al, ah
	clr	ah
	mov	di, ax				; save error code

		CheckHack <B13F_RESET_DISK_SYSTEM eq 0>
	call	DOSFormatInt13

	dec	ds:[DFD_methodData].DFMD_bios.DFBD_tryCount
	jne	doFormat
	;
	; Map BIOS error to FormatError.
	; 
	mov	ax, FMT_DRIVE_NOT_READY
	cmp	di, B13E_DRIVE_NOT_READY
	je	setError
	mov	ax, FMT_ERR_WRITE_PROTECTED
	cmp	di, B13E_WRITE_PROTECTED
	je	setError
	mov	ax, FMT_ERR_CANNOT_FORMAT_TRACK
setError:
	stc
done:
	;
	; Restore the old diskette parameters.
	; 
	
	pushf
	push	ax
if PZ_PCGEOS
	;
	; restore DisketteParams for Pizza's 1.232M 3.5"
	;
	cmp	ds:[DFD_formatArgs].FSFA_media, MEDIA_1M232
	jne	noUnset1232M
	call	Unset1M232
noUnset1232M:
endif
	mov	di, offset DFD_methodData.DFMD_bios.DFBD_oldParams
	mov	ax, BIOS_DISK_PARAMS_VECTOR
	call	SysResetInterrupt
if PZ_PCGEOS
;not needed
;	mov	ah, 0
;	call	DOSFormatInt13
endif
	call	SysUnlockBIOS
	pop	ax
	popf

	.leave
	ret
DOSFormatTrackBIOS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatQReadFAT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the current FAT into the allocated buffer.

CALLED BY:	DOSFormatCheckAndPerformQuick
PASS:		ds	= DiskFormatData
		es	= segment of buffer of FAT bitmask
		bp	= non-zero if 16-bit FAT
RETURN:		carry set if couldn't read FAT
		carry clear if FAT read ok.
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	ds:[DFD_badClusters], ds:[DFD_goodClusters] set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatQReadFAT proc	near
fatSize		local	word 	push bp
badClusters	local	word
numClusters	local	word
goodClusters	local	word
processRoutine	local	nptr.near
		uses	ds
		.enter
		clr	ss:[badClusters]
		call	DOSFormatGetNumClusters
		mov	ss:[numClusters], ax
		mov	ss:[goodClusters], ax
	;
	; Fill in the vector for processing a single sector.
	; 
		mov	ax, offset DOSFormatQCondense16BitFATSector
		tst	ss:[fatSize]
		jnz	haveCondenseRoutine
		mov	ax, offset DOSFormatQCondense12BitFATSector
haveCondenseRoutine:
		mov	ss:[processRoutine], ax
	;
	; Mark first two clusters "bad" as they're reserved for the media
	; descriptor and whatnot.
	; 
		mov	{byte}es:[0], 00000011b
	;
	; Must condense the FAT into a bitmask, so read it a sector at a time
	; into our aligned buffer and condense it.
	;
	; For the main loop:
	; 	dx	= sector number being processed
	; 	cx	= number of FAT sectors left to process
	; 	bx	= size of a sector
	; 	es:di	= byte in FAT buffer that holds bit for current
	;		  cluster
	;	al	= bit for current cluster
	;
		mov	dx, ds:[DFD_startFAT]
		mov	cx, ds:[DFD_bpb].BPB_sectorsPerFAT
		mov	bx, ds:[DFD_bpb].BPB_sectorSize
		clr	di, si
		mov	al, 1		; clusters 0 & 1 won't be marked "bad",
					;  so no need to skip them and thereby
					;  mangle this already twisted logic
		mov	ds:[DFD_fatToggle], 0
readLoop:
	;
	; Have:	dx	= sector number
	;	ds	= DiskFormatData
	; need: es:si = drive
	; 	bx:dx = sector #
	; 	cx = # sectors to read (1)
	; 	ds:di = buffer to which to read things
	; 
		push	ds, bx, cx, di, si, ax, es
		clr	bx
		mov	cx, 1
if PZ_PCGEOS
	;
	; handle for Pizza's 1.232M 3.5"
	;
		cmp	ds:[DFD_formatArgs].FSFA_media, MEDIA_1M232
		jne	not1M232
		shl	cx, 1				; #sectors*2
		shldw	bxdx				; start sector*2
not1M232:
endif
		mov	si, ds:[DFD_formatArgs].FSFA_dse
		call	FSDLockInfoShared
		mov	es, ax
		mov	ds, ds:[DFD_sectorBuffer]
		clr	di
		call	DOSReadSectors
		call	FSDUnlockInfoShared
		pop	ds, bx, cx, di, si, ax, es
		jc	error
	;
	; Mangle that sector with the proper routine.
	;
		call	ss:[processRoutine]

		inc	dx		; advance to next sector
		loop	readLoop
	;
	; Set the number of clusters in the DiskFormatData.
	; XXX: reduce by # of reserved clusters?
	; 
		mov	ax, ss:[goodClusters]
		mov	bx, ss:[badClusters]
		sub	ax, bx
		mov	ds:[DFD_goodClusters], ax
		mov	ds:[DFD_badClusters], bx

		clc
error:
		.leave
		ret
		
DOSFormatQReadFAT endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatQCondense16BitFATSector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Condense a 16-bit FAT sector into a bitmask in the FAT
		buffer for the disk.

CALLED BY:	(INTERNAL) DOSFormatQReadFAT
PASS:		ds	= DiskFormatData
		dx	= sector number being processed
		cx	= number of FAT sectors left to process
		bx	= size of a sector
		es:di	= byte in FAT buffer that holds bit for current cluster
		al	= bit for current cluster
RETURN:		es:di	= byte to use at start of next sector
		al	= bit to use for first cluster in next sector
DESTROYED:	si, ah
SIDE EFFECTS:	ss:[numClusters] is reduced
     		ss:[badClusters] may increase

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatQCondense16BitFATSector proc	near
		uses	cx, ds, dx
		.enter	inherit	DOSFormatQReadFAT
		clr	si
		mov	ds, ds:[DFD_sectorBuffer]
		mov	dh, es:[di]	; dh <- current bitmask byte
		mov	dl, al		; dl <- bit to manipulate for first
					;  cluster in FAT sector
		mov	cx, bx		; cx <- sector size
		shr	cx		; convert to clusters
		sub	ss:[numClusters], cx
		jae	processLoop
		add	cx, ss:[numClusters]
processLoop:
		lodsw
		cmp	ax, FAT_CLUSTER_BAD
		jne	maybeStore
		ornf	dh, dl
		inc	ss:[badClusters]
maybeStore:
		rol	dl
		cmp	dl, 1		; used up a byte?
		jne	nextCluster	; no

		mov	es:[di], dh	; store it in the bitmask
		clr	dh		;  and set up for the next
		inc	di		;  byte in the mask
nextCluster:
		loop	processLoop
		
		cmp	dl, 1		; any partial byte to store?
		je	done		; => no
		mov	es:[di], dh
done:
		mov	al, dl
		.leave
		ret
DOSFormatQCondense16BitFATSector endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatQCondense12BitFATSector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Condense a 12-bit FAT sector into a bitmask in the FAT
		buffer for the disk.

CALLED BY:	(INTERNAL) DOSFormatQReadFAT
PASS:		ds	= DiskFormatData
		dx	= sector number being processed
		cx	= number of FAT sectors left to process
		bx	= size of a sector
		es:di	= byte in FAT buffer that holds bit for current cluster
		al	= bit for current cluster
		si	= offset within sector at which to start processing
			  (0 or -1)
		ah	= last byte of previous sector, if si is -1
		ds:[DFD_fatToggle] = set for first cluster in the sector
RETURN:		es:di	= byte to use at start of next sector
		al	= bit to use for first cluster in next sector
		si	= 0 or -1
		ah	= last byte of sector, if si is -1
DESTROYED:	nothing
SIDE EFFECTS:	ss:[numClusters] is reduced
     		ss:[badClusters] may increase
		ds:[DFD_fatToggle] updated

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatQCondense12BitFATSector proc	near
		uses	bx, cx, dx
		.enter	inherit	DOSFormatQReadFAT
		push	ds
		mov	dh, es:[di]	; dh <- current byte
		mov	dl, al		; dl <- mask for current cluster
		mov	cx, bx		; cx <- # bytes left

		mov	bl, ds:[DFD_fatToggle]
		mov	ds, ds:[DFD_sectorBuffer]
		cmp	si, -1
		jne	processLoop
	;
	; Last cluster in previous sector wasn't completely described. Form
	; the word we would have gotten had the two sectors been concatenated.
	; 
		inc	cx
		mov	al, ah
		mov	ah, ds:[0]
		jmp	haveWord
	
processLoop:
		mov	ax, ds:[si]
	
haveWord:
		tst	bl			; is cluster even?
		jz	checkEven		; yes -- go handle it
	;
	; Cluster is odd, so it resides in high 12 bits of the word.
	; 
		andnf	ax, 0xfff0
		cmp	ax, (FAT_CLUSTER_BAD and 0xfff) shl 4
		jne	maybeStore
markBad:
		ornf	dh, dl
		inc	ss:[badClusters]
maybeStore:
		rol	dl
		cmp	dl, 1		; used up a byte?
		jne	nextCluster	; no

		mov	es:[di], dh	; store it in the bitmask
		clr	dh		;  and set up for the next
		inc	di		;  byte in the mask
nextCluster:
		inc	si		; always skip at least one byte
		dec	cx		;  which consumes it, of course
		xor	bl, 1		; toggle even/odd flag
		jnz	checkLastByte	; => now odd, so just needed single inc

		inc	si		; skip high byte of previous odd
		dec	cx		;  cluster

checkLastByte:
		dec	ss:[numClusters]
		jz	finish		; if out of clusters, stop now so we
					;  don't compute bad clusters from
					;  garbage

	;
	; If there's only one byte left in the sector, we have to save the byte
	; for the next sector.
	; 
		cmp	cx, 1
		ja	processLoop
		
		je	handlePartialCluster
	;
	; Consumed all bytes in the sector, so set SI = 0 for next time.
	; 
		clr	si
finish:
		cmp	dl, 1		; partial byte to store?
		je	done		; => no
		mov	es:[di], dh
done:
		mov	al, dl		; al <- mask for first cluster of next
					;  sector
	;
	; Store the even/odd flag for next time.
	; 
		pop	ds
		mov	ds:[DFD_fatToggle], bl
		.leave
		ret

handlePartialCluster:
	;
	; Only one byte left in the sector. Return it in AH and set SI to -1
	; to indicate this for the next call.
	; 
		mov	ah, ds:[si]
		mov	si, -1
		jmp	finish

checkEven:
		andnf	ax, 0xfff
		cmp	ax, FAT_CLUSTER_BAD and 0xfff
		je	markBad
		jmp	maybeStore
DOSFormatQCondense12BitFATSector endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatCheckAndPerformQuick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Try and perform a quick format if the caller and the media
		allow it.

CALLED BY:	(INTERNAL) DOSDiskFormat
PASS:		ds	= DiskFormatData
RETURN:		carry clear if format complete
		carry set if quick format not possible.
DESTROYED:	ax, bx, cx, dx, si, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		See if DFF_FORCE_ERASE, if set then no go
		See if disk handle given, if not, current disk is unformatted,
			so no go
		Try and read the last sector of the disk, if can't, then
			disk not completely formatted, so no go.
		Allocate a buffer for the FAT and read the current one in.
		Run through the FAT zeroing out every cluster not marked as
			bad, counting the bad ones as we go along
		Set # good clusters = total - # bad
		Write new FAT out
		Zero root directory
		return happiness

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatCheckAndPerformQuick proc	near		uses	es
		.enter
	;
	; Caller wants to forcibly erase the disk?
	; 
		test	ds:[DFD_formatArgs].FSFA_flags, mask DFF_FORCE_ERASE
		jnz	fail		; yes
	;
	; Disk in drive registered (i.e. at least formatted enough to have
	; a boot sector)?
	; 
		mov	si, ds:[DFD_formatArgs].FSFA_disk
		tst	si
		jz	fail
	;
	; See if MediaType matches the one we're formatting to
	; 
		call	FSDLockInfoShared
		mov	es, ax
		mov	al, es:[si].DD_media
		cmp	al, ds:[DFD_formatArgs].FSFA_media
		jne	failUnlockFSIR
	;
	; Use #sectors in DFD_bpb to get number of last sector to read and
	; try and read it.
	; 
		mov	si, ds:[DFD_formatArgs].FSFA_dse; es:si <- DSE
		push	ax
		call	DOSFormatInitGetNumSectors	; dxax <- #sectors
		subdw	dxax, 1				;  sector (0-origin)
		mov	bx, dx
		mov_tr	dx, ax
		pop	ax

		push	ds
	    ;
	    ; Increment the dosPreventCritical flag so any critical error
	    ; generated by this call is immediately failed w/o user
	    ; intervention.
	    ; 
		push	ds:[DFD_sectorBuffer]

		call	DOSPreventCriticalErr

		clr	di				; ds:di <- buffer
		mov	cx, 1				; cx <- # to read
if PZ_PCGEOS
	;
	; handle for Pizza's 1.232M 3.5"
	;
		cmp	ds:[DFD_formatArgs].FSFA_media, MEDIA_1M232
		jne	not1M232
		shl	cx, 1				; #sectors*2
		shldw	bxdx				; start sector*2
not1M232:
endif
		pop	ds
		call	DOSReadSectors
	    ;
	    ; Reset the dosPreventCritical
	    ; 
		call	DOSAllowCriticalErr

		pop	ds
		jnc	quickFormatMeBaby		; => formatted all the
							;  way through
failUnlockFSIR:
		call	FSDUnlockInfoShared
fail:
		stc
		jmp	done
quickFormatMeBaby:
		call	FSDUnlockInfoShared
	;
	; Allocate a buffer into which we can read the FAT
	; 
		call	DOSFormatAllocFATBuffer
		jc	done
	;
	; Now read it, silly.
	; 
		call	DOSFormatQReadFAT
		jc	failFreeFAT
	;
	; Write out the FAT again.
	; 
		call	DOSFormatWriteFATs
		jc	failFreeFAT
	;
	; Zero the root directory.
	; 
		call	DOSFormatWriteRootDirectory
		jc	failFreeFAT
	;
	; Fetch the ID for the disk from the DiskDesc and store it in our
	; data so DOSFormatSetName doesn't mangle it.
	; 
		call	FSDLockInfoShared
		mov	es, ax
		mov	si, ds:[DFD_formatArgs].FSFA_disk
		mov	ax, es:[si].DD_id.low
		mov	ds:[DFD_diskID].low, ax
		mov	ax, es:[si].DD_id.high
		mov	ds:[DFD_diskID].high, ax
		call	FSDUnlockInfoShared
	;
	; Perform gratuitous callback so user sees 100% display before the
	; feedback box vanishes.
	; 
		mov	ax, ds:[DFD_numTracks]
		clr	dx
		mov	cx, ds:[DFD_bpb].BPB_numHeads
		div	cx			; ax <- # cylinders
		dec	ax
		dec	cx
		mov	ds:[DFD_curCylinder], ax
		mov	ds:[DFD_curHead], cx
		call	DOSFormatCallCallback
		clc			; don't care if format aborted:
					;  this puppy is done.
	;
	; No need to free the FAT on success, as DOSFormatCleanUp will do it
	; for us...
	; 
done:
		.leave
		ret

failFreeFAT:
		clr	bx
		xchg	bx, ds:[DFD_fat]
		call	MemFree
		stc
		jmp	done
DOSFormatCheckAndPerformQuick endp

DiskFormatCode	ends
