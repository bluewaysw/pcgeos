COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		DOS IFS Drivers
FILE:		dosFormatInit.asm

AUTHOR:		Cheng, 1/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial revision
	ardeb	3/12/92		Brought over to IFS drivers

DESCRIPTION:
	Initializes variables prior to formatting.
		
	$Id: dosFormatInit.asm,v 1.1 97/04/10 11:55:09 newdeal Exp $

-------------------------------------------------------------------------------@

DiskFormatCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatInitGetNumSectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the number of sectors from the format data, coping
		with the potential for 32-bit sector numbers

CALLED BY:	(EXTERNAL)
PASS:		ds	= DiskFormatData
RETURN:		dxax	= # of sectors
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatInitGetNumSectors proc	near
		.enter
		mov	ax, ds:[DFD_bpb].BPB_numSectors
		clr	dx
		tst	ax
		jnz	done
		movdw	dxax, ds:[DFD_bpb].BPB_largeNumSectors
done:
		.leave
		ret
DOSFormatInitGetNumSectors endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatAllocWorkspace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate our working variables for the format.

CALLED BY:	(INTERNAL) DOSFormatInit
PASS:		ss:bx	= FSFormatArgs
RETURN:		ds, es	= DiskFormatData
		ds:[DFD_method] initialized.
		ds:[DFD_sectorBuffer], ds:[DFD_sectorBufferHandle] set
		ds:[DFD_blockHandle] set
		ds:[DFD_formatArgs] set
		everything else zero
DESTROYED:	si, di, bx, ax, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatAllocWorkspace proc	near
		.enter
	;
	; Allocate regular work area structure.
	; 
		mov	si, bx
		mov	ax, size DiskFormatData
		mov	cx, ALLOC_FIXED or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		jnc	dataAreaAllocated
		mov	ax, FMT_ERR_CANNOT_ALLOC_SECTOR_BUFFER
		jmp	exit

dataAreaAllocated:
	;
	; Copy in the FSFormatArgs for later use.
	; 
		mov	es, ax
		mov	di, offset DFD_formatArgs
		mov	cx, size DFD_formatArgs
		segmov	ds, ss
		rep	movsb
	;
	; Store work area's handle for later freeing.
	; 
		mov	ds, ax
		mov	ds:[DFD_blockHandle], bx
	;
	; See if disk will be unnamed and zero out FSFA_volumeName segment
	; if so.
	; 
		les	di, ds:[DFD_formatArgs].FSFA_volumeName
		tst	{char}es:[di]
		jnz	setFormatMethod
		mov	ds:[DFD_formatArgs].FSFA_volumeName.segment, 0
setFormatMethod:
		mov	es, ax
	;
	; Record data about drive and reset it.
	; 
		call	DOSFormatInitSetDrive	;change to drive, init var

if (_MS4 or _MS5 or _DRI or _OS2) and not _REDMS4
	;
	; generic IOCTL for formatting always present in these versions but
	; we want to make sure the driver supports it, so get the BPB now.
	; If that returns an error, use BIOS instead.
	; 
if PZ_PCGEOS
	;
	; use BIOS for Pizza's 1.232M 3.5"
	;
		cmp	ds:[DFD_formatArgs].FSFA_media, MEDIA_1M232
		je	forceBIOS
endif
		mov	ds:[DFD_method], DFM_IOCTL
		call	DOSFormatInitGetBPB	;destroys ax,bx,cx,dx
		jnc	allocSector
if PZ_PCGEOS
forceBIOS:
endif
		mov	ds:[DFD_method], DFM_BIOS
allocSector:
elif _MS2 or _REDMS4
     	;
	; generic IOCTL for formatting never present in this version...
	; (We've also had problems formatting in Redwood. 5/ 9/94 cbh)
	;
		mov	ds:[DFD_method], DFM_BIOS
else
	;
	; MS 3. ioctl became available in 3.20
	; 
		push	ds
		segmov	ds, dgroup, bx
		mov	bl, DFM_BIOS
		cmp	ds:[dosVersionMinor], 20
		pop	ds
		jb	haveFormatMethod
	;
	; DOS supports it. Does the driver?
	; 
		call	DOSFormatInitGetBPB	;destroys ax,bx,cx,dx
		mov	bl, DFM_IOCTL		; assume yes
		jnc	haveFormatMethod
		mov	bl, DFM_BIOS		; no -- use BIOS
haveFormatMethod:
		mov	ds:[DFD_method], bl
endif
	;
	; Allocate a sector buffer; we always need one of these.
	; 
if PZ_PCGEOS
		mov	ax, 1024
else
		mov	ax, MSDOS_STD_SECTOR_SIZE
endif
		call	DOSAllocateSectorBuffer
		mov	ds:[DFD_sectorBuffer], ax
		mov	ds:[DFD_sectorBufferHandle], bx
	;
	; If there's a disk handle, let the world know it's going away.
	; 
		mov	si, ds:[DFD_formatArgs].FSFA_disk
		tst	si
		jz	exit
		
		mov	ax, FCNT_DISK_FORMAT
		call	FSDGenerateNotify
		clc
exit:
		.leave
		ret
DOSFormatAllocWorkspace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatInitSetGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the geometry of the disk to be formatted.

CALLED BY:	(INTERNAL) DOSFormatInit
PASS:		ds, es	= DiskFormatData
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatInitSetGeometry proc	near
		.enter
	;
	; First divide the sector size by the size of a directory entry to
	; get the number of entries per sector.
	; 
		mov	ax, ds:[DFD_bpb].BPB_sectorSize
		mov	bx, size RootDirEntry
		clr	dx
		div	bx
		mov	ds:[DFD_dirEntsPerSector], ax

	;
	; Get logical sector number of start
	;
		mov	ax, ds:[DFD_bpb].BPB_sectorsPerTrack
		push	ax
		mul	ds:[DFD_bpb].BPB_numHeads ;dx:ax <- sectors per cylinder
		mov	ds:[DFD_sectorsPerCylinder], ax

		mul	ds:[DFD_curCylinder]
		mov	bx, ax		;bx <- sector offset to start cylinder
		pop	ax		;ax <- sectors per track
		mul	ds:[DFD_curHead];ax <- offset to start track
		add	ax, bx		;ax <- offset to start sector
		add	ax, ds:[DFD_curSector]
		dec	ax
		mov	ds:[DFD_startBoot], ax

	;
	; Figure positions for disk areas
	;
		push	ax		;save logical sector of boot
		add	ax, ds:[DFD_bpb].BPB_numReservedSectors
		mov	ds:[DFD_startFAT], ax
		mov	bx, ax		;bx <- logical sector of FAT

		pop	ax		;ax <- logical sector of boot
		clr	dx
		div	ds:[DFD_bpb].BPB_sectorsPerTrack
		inc	ax
		mov	ds:[DFD_startTrack], ax

		mov	ax, ds:[DFD_bpb].BPB_sectorsPerFAT
		mul	ds:[DFD_bpb].BPB_numFATs
		add	ax, bx		;ax <- start FAT + FAT size
		mov	ds:[DFD_startRoot], ax
		mov	bx, ax

		mov	ax, ds:[DFD_bpb].BPB_numRootDirEntries
		clr	dx
		div	ds:[DFD_dirEntsPerSector]
		mov	ds:[DFD_rootDirSize], ax
		add	ax, bx
		mov	ds:[DFD_startFiles], ax

	;
	; Initialize other disk vars
	;
		clr	dx
		div	ds:[DFD_bpb].BPB_sectorsPerTrack
		inc	ax
		mov	ds:[DFD_lastRootDirTrack], ax

	    ;
	    ; Start DFD_unprocessedDataSectors out with the number that reside
	    ; on the track with the root directory, since that track is
	    ; formatted by code other than DOSFormatFilesArea.
	    ; 
		mov	ax, ds:[DFD_bpb].BPB_sectorsPerTrack
		sub	ax, dx
		mov	ds:[DFD_unprocessedDataSectors], ax

		call	DOSFormatInitGetNumSectors
		div	ds:[DFD_bpb].BPB_sectorsPerTrack
		mov	ds:[DFD_numTracks], ax
		.leave
		ret
DOSFormatInitSetGeometry endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatInit

DESCRIPTION:	Initialize variables.

CALLED BY:	INTERNAL (DOSDiskFormat)

PASS:		ss:bx	= FSFormatArgs

RETURN:		carry set on error
			ax - error code
		carry clear if ok to proceed
			ds, es = DiskFormatData

DESTROYED:	ax,bx,cx,dx,di,si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	see notes on pg 536-537 of Duncan

	set drive
	allocate buffer
	init vars
	if Ioctl will be used, save BPB and set BPB

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version

-------------------------------------------------------------------------------@

DOSFormatInit	proc	far

	;
	; Allocate workspace and copy all arguments into it.
	; 
		call	DOSFormatAllocWorkspace
		jc	exit

	;
	; Initialize medium vars
	;
		call	DOSFormatInitMediaVars
		jc	error

	;
	; Modify BPB in the driver if necessary
	;
		cmp	ds:[DFD_method], DFM_IOCTL
		jne	setGeometry

if DOS_FORMAT_RESTORE_BPB
		call	DOSFormatInitSaveBPB	;destroys ax,cx,di,si,es
endif
		call	DOSFormatInitSetBPB	;destroys ax,cx,dx,di,si,es
		jnc	setGeometry
		
	;
	; If unable to set the BPB, the driver probably just supported the
	; GET_DEVICE_PARAMS ioctl to be nice (e.g. Datalight DOS 3.31 does
	; this), so attempt to revert to BIOS for formatting the disk.
	; 				-- ardeb 10/22/93
	; 
		mov	ds:[DFD_method], DFM_BIOS

setGeometry:
	;
	; Set the various disk-geometry variables in the workspace.
	;
		call	DOSFormatInitSetGeometry
	;
	; If using BIOS, allocate buffers for track verification
	; 11/24/92: we don't actually read all the sectors, so we don't need
	; a buffer for verification. Just set the disk type and be done -- ardeb
	;
		cmp	ds:[DFD_method], DFM_BIOS
		jne	finish

		call	DOSFormatInitSetDiskType
if _REDMS4
		jc	error
	;
	; In RedMS4, hack the data transfer rate -- seems to fix formatting
	; problems.  5/ 9/94 cbh
	;
		call	DOSHackTransferRateForRedwood
		jmp	finish
else
		jnc	finish
endif

error:
		mov	bx, ds:[DFD_blockHandle]
		call	MemFree
		stc
		jmp	exit

finish:
		clr	ax			;return no errors

exit:
		ret
DOSFormatInit	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSHackTransferRateForRedwood
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the data transfer rate in BIOS.

CALLED BY:	DOSFormatInit

PASS:		ds - DiskFormatData

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 9/94       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_REDMS4

DOSHackTransferRateForRedwood	proc	near
		uses	ax, es
		.enter

		segmov	es, BIOS_DATA_SEG, ax
	
	;
	; Set data transfer rate, based on media being formatted.
	;
		mov	al, es:[91h]
		and	al, 03fh
		cmp	ds:[DFD_formatArgs].FSFA_media, MEDIA_1M44
		je	afterHiBitSet
		or	al, 080h
afterHiBitSet:
		mov	es:[91h], al

		mov	al, es:[8bh]
		and	al, 033h		;assume 144M, 00xx00xx - 500 kbs
		cmp	ds:[DFD_formatArgs].FSFA_media, MEDIA_1M44
		je	storeTransferRate
		or	al, 088h		;720k, 10xx10xx - 250 kbs
storeTransferRate:
		mov	es:[8bh], al		;store

		.leave
		ret
DOSHackTransferRateForRedwood	endp

endif




COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatInitSetDrive

DESCRIPTION:	Select and reset the specified drive.

CALLED BY:	INTERNAL (DOSFormatInit)

PASS:		ds - DiskFormatData

RETURN:		carry clear if successful
			ds:[DFD_biosDrive]	= set
			ds:[DFD_mediaStatus]	= set
			ax	= destroyed
		carry set otherwise:
			al	= BiosInt13Error

DESTROYED:	dx
	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version
	ardeb	3/15/92		Imported to IFS driver

-------------------------------------------------------------------------------@

DOSFormatInitSetDrive	proc	near
		mov	al, ds:[DFD_formatArgs].FSFA_drive
		call	DriveGetStatus
		mov	ds:[DFD_mediaStatus], ah

if PZ_PCGEOS
	;
	; look in BDS for drive num in Pizza's 1.232M 3.5"
	;
		cmp	ds:[DFD_formatArgs].FSFA_media, MEDIA_1M232
		jne	not1M232
		push	ds, di
		mov	dl, al				; dl = logical drive
		mov	ax, 0803h
		call	SysLockBIOS
		int	2fh				; ds:di = BDS
		call	SysUnlockBIOS
findLoop:
		cmp	di, -1
		je	notFound
		cmp	ds:[di+5], dl			; compare logical drive
		je	found
		lds	di, {dword} ds:[di]		; get next BDS
		jmp	short findLoop

notFound:
		pop	ds, di
		mov	al, B13E_DRIVE_NOT_READY	; fake error code
		stc					; indicate error
		jmp	done

found:
		mov	al, ds:[di+4]			; al = physical drive
		pop	ds, di
not1M232:
endif
		mov	ds:[DFD_biosDrive], al

		clr	ah				;reset disk
		mov	dl, al
		call	DOSFormatInt13
		mov	al, ah
if PZ_PCGEOS
done:
endif
		ret
DOSFormatInitSetDrive	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatInitMediaVars

DESCRIPTION:	Initialize variables relating to the medium that we're going
		to work on.

CALLED BY:	INTERNAL (DOSFormatInit)

PASS:		ds, es - DiskFormatData

RETURN:		ds:[DFD_bpb]	= set

DESTROYED:	ax, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version

-------------------------------------------------------------------------------@


DOSFormatInitMediaVars	proc	near
		uses	ds
		.enter
	;
	; Figure which BiosParamBlock to use from the array below.
	; 
		mov	al, ds:[DFD_formatArgs].FSFA_media
		cmp	al, MEDIA_FIXED_DISK
		je	isFixed
		cmp	al, MEDIA_CUSTOM
		je	isCustom
		cmp	al,MEDIA_SRAM
		je	isCustom
		cmp	al,MEDIA_ATA
		je	isCustom
		cmp	al,MEDIA_FLASH
		je	isCustom
if PZ_PCGEOS
		mov	cx, size BiosParamBlock		;cx <- block size
		mov	si, offset BPB_640K
		cmp	al,MEDIA_640K
		je	haveBPB
		mov	si, offset BPB_1M232
		cmp	al,MEDIA_1M232
		je	haveBPB
endif

		clr	ah
		dec	ax				;make ax 0 based
		mov	cx, size BiosParamBlock		;cx <- block size
		mul	cx				;ax <- 0 based offset
		add	ax, offset cs:[BPB_160K]	;ax <- offset to BPB
							; for media
	;
	; Copy it into the DiskFormatData.
	; 
		mov_tr	si, ax
if PZ_PCGEOS
haveBPB:
endif
		mov	di, offset [DFD_bpb]
		segmov	ds, cs
		rep	movsb
	;
	; Clear loop variables.
	; 
done:
		clr	ax
		mov	es:[DFD_curCylinder], ax
		mov	es:[DFD_curHead], ax
		mov	es:[DFD_curSector], 1
exit:
		.leave
		ret

isCustom:
isFixed:
	;
	; Fixed disks aren't generally marked formattable, but the things we
	; get from the SUNDISK driver on the Zoomer appear to be removable
	; fixed disks (go figure). We can't, however, determine the disk's
	; geometry without IOCTL, so...
	; 
		mov	ax, FMT_CANNOT_FORMAT_FIXED_DISKS_IN_CUR_RELEASE
		cmp	ds:[DFD_method], DFM_IOCTL
		stc
		jne	exit
	;
	; Copy the BPB we fetched from the device driver when determining if
	; IOCTL was supported by the drive.
	; 
		mov	si, offset DFD_methodData.DFMD_ioctl.DFID_newBPB.SDP_common.GDP_bpb
		mov	di, offset DFD_bpb
		mov	cx, size DFD_bpb
		rep	movsb
		jmp	done
DOSFormatInitMediaVars	endp


	CheckHack <MEDIA_160K eq 1>
BPB_160K	BiosParamBlock <
	512,		;sectorSize
	1,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	64,		;numRootDirEntries
	320,		;numSectors
	DOS_MEDIA_160K,	;mediaDescriptor

	1,		;sectorsPerFAT
	8,		;sectorsPerTrack
	1,		;numHeads
	0		;numHiddenSectors
>
	CheckHack <MEDIA_180K eq 2>
BPB_180K	BiosParamBlock <
	512,		;sectorSize
	2,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	64,		;numRootDirEntries, 4 sectors
	360,		;numSectors
	DOS_MEDIA_180K,	;mediaDescriptor
	1,		;sectorsPerFAT
	9,		;sectorsPerTrack
	1,		;numHeads
	0		;numHiddenSectors
>
	CheckHack <MEDIA_320K eq 3>
BPB_320K	BiosParamBlock <
	512,		;sectorSize
	2,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	112,		;numRootDirEntries
	640,		;numSectors
	DOS_MEDIA_320K,	;mediaDescriptor
	1,		;sectorsPerFAT
	8,		;sectorsPerTrack
	2,		;numHeads
	0		;numHiddenSectors
>
	CheckHack <MEDIA_360K eq 4>
BPB_360K	BiosParamBlock <
	512,		;sectorSize
	2,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	112,		;numRootDirEntries, 7 sectors
	720,		;numSectors
	DOS_MEDIA_360K,	;mediaDescriptor
	2,		;sectorsPerFAT
	9,		;sectorsPerTrack
	2,		;numHeads
	0		;numHiddenSectors
>
	CheckHack <MEDIA_720K eq 5>
BPB_720K	BiosParamBlock <
	512,		;sectorSize
	2,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	112,		;numRootDirEntries, 7 sectors
	1440,		;numSectors
	DOS_MEDIA_720K,	;mediaDescriptor
	3,		;sectorsPerFAT
	9,		;sectorsPerTrack
	2,		;numHeads
	0		;numHiddenSectors
>
	CheckHack <MEDIA_1M2 eq 6>
BPB_1M2		BiosParamBlock <
	512,		;sectorSize
	1,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	224,		;numRootDirEntries, 14 sectors
	2400,		;numSectors
	DOS_MEDIA_1M2,	;mediaDescriptor
	7,		;sectorsPerFAT
	15,		;sectorsPerTrack
	2,		;numHeads
	0		;numHiddenSectors
>
	CheckHack <MEDIA_1M44 eq 7>
BPB_1M44	BiosParamBlock <
	512,		;sectorSize
	1,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	224,		;numRootDirEntries, 14 sectors
	2880,		;numSectors
	DOS_MEDIA_1M44,	;mediaDescriptor
	9,		;sectorsPerFAT
	18,		;sectorsPerTrack
	2,		;numHeads
	0		;numHiddenSectors
>
	CheckHack <MEDIA_2M88 eq 8>
BPB_2M88	BiosParamBlock <
	512,		;sectorSize
	1,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	224,		;numRootDirEntries, 14 sectors
	5760,		;numSectors
	DOS_MEDIA_1M44,	;mediaDescriptor
	9,		;sectorsPerFAT
	36,		;sectorsPerTrack
	2,		;numHeads
	0		;numHiddenSectors
>
if PZ_PCGEOS
BPB_640K	BiosParamBlock <
	512,		;sectorSize
	2,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	112,		;numRootDirEntries, 14 sectors
	1280,		;numSectors
	DOS_MEDIA_640K,	;mediaDescriptor
	2,		;sectorsPerFAT
	8,		;sectorsPerTrack
	2,		;numHeads
	0		;numHiddenSectors
>
BPB_1M232	BiosParamBlock <
	1024,		;sectorSize
	1,		;clusterSize
	1,		;numReservedSectors
	2,		;numFATs
	192,		;numRootDirEntries, 14 sectors
	1232,		;numSectors
	DOS_MEDIA_1M232, ;mediaDescriptor
	2,		;sectorsPerFAT
	8,		;sectorsPerTrack
	2,		;numHeads
	0		;numHiddenSectors
>
	ForceRef	BPB_640K
	ForceRef	BPB_1M232
endif

	ForceRef	BPB_180K
	ForceRef	BPB_320K
	ForceRef	BPB_360K
	ForceRef	BPB_720K
	ForceRef	BPB_1M2
	ForceRef	BPB_1M44
	ForceRef	BPB_2M88


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DOSFormatInitSetDiskType

DESCRIPTION:	Prepare BIOS for the formatting we're about to perform by
		informing it of the geometry of the density to which we
		will be formatting the disk.

CALLED BY:	INTERNAL (DOSFormatInit)

PASS:		No ioctl present.
		ds - DiskFormatData

		what user desires:
		    ds:[DFD_formatArgs].FSFA_media
		    ds:[DFD_biosDrive]	= set
		    ds:[DFD_formatArgs].FSFA_drive
		

RETURN:		carry set on error
			ax	= error code
		carry clear if ok

DESTROYED:	ax, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if drive is 360Kb then
	    code = 1
	else if drive is 1.2Mb then
	    if what user wants is 320Kb/360Kb then
		code = 2
	    else
		code = 3
	    endif
	else
	    code = 4
	endif

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version
	ardeb	3/15/92		Brought into IFS driver

-------------------------------------------------------------------------------@

DOSFormatInitSetDiskType	proc	near
		uses	es
		.enter
	;
	; Reset disk driver
	;
			CheckHack <B13F_RESET_DISK_SYSTEM eq 0>
		clr	ah
		call	DOSFormatInt13
	;
	; And do it through DOS, too, to make sure the cache is flushed.
	; 
		mov	ah, MSDOS_RESET_DISK
		call	FileInt21

	;
	; XXX: the B13F_SET_DISK_TYPE and B13F_SET_MEDIA_TYPE calls aren't
	; supported by the XT BIOS before 1/10/86, but we hope that issuing
	; the calls won't cause the thing to freak out. -- ardeb 3/15/92
	;
		mov	ax, ds:[DFD_numTracks]
		clr	dx
		div	ds:[DFD_bpb].BPB_numHeads	; ax <- cylinders
		dec	ax				; want 0-origin
		mov	ch, al			; ch <- low 8 bits of #cyls
		mov	cl, ah
		ror	cl			; shift high 2 bits of 10-bit
		ror	cl			;  #cyls into high 2 bits of
						;  ah
		or	cl, ds:[DFD_bpb].BPB_sectorsPerTrack.low
						; low 6 bits get #sectors

EC <		test	ds:[DFD_numTracks], 0xfc00			>
EC <		ERROR_NZ	DOS_FORMAT_TOO_MANY_TRACKS		>
EC <		tst	ds:[DFD_bpb].BPB_sectorsPerTrack.high		>
EC <		ERROR_NZ	DOS_FORMAT_TOO_MANY_SECTORS		>
		mov	dl, ds:[DFD_biosDrive]
		mov	ah, B13F_SET_MEDIA_TYPE
		call	DOSFormatInt13	; es:di <- DisketteParams
		jnc	setDiskType
	
		cmp	ah, B13E_DISK_CHANGED
		je	diskChanged
	;
	; See if function just isn't supported.
	; 
		cmp	ah, B13E_INVALID_PARAMETER
		LONG jne	error
	;
	; Right. Fetch the current diskette parameters so we don't nail
	; things. Then exit stage left, saying everything's all right.
	; 
		clr	ax		; (clears carry)
		mov	es, ax
		les	di, es:[BIOS_DISK_PARAMS_VECTOR*fptr]
		movdw	ds:[DFD_methodData].DFMD_bios.DFBD_params, esdi
		jmp	exit
diskChanged:
	;
	; Change-line active, so try a second time.
	; 
		mov	ah, B13F_SET_MEDIA_TYPE
		call	DOSFormatInt13
		LONG jc	error

setDiskType:

if PZ_PCGEOS
	;
	; set drive type for Pizza's 1.232M 3.5"
	;
		cmp	ds:[DFD_formatArgs].FSFA_media, MEDIA_1M232
		jne	not1M232
		push	ds, bx
		mov	dl, ds:[DFD_biosDrive]
		mov	cl, 10			; 10 retries
retry:
		mov	ah, 070h		; FD12.SYS stuff
		mov	al, 0			; set 1M232 mode
		clr	bx
		call	DOSFormatInt13		; C, ah = error code
		pushf
		tst	bx			; no function?
		jz	noFunction
		popf
		jnc	done1M232		; (carry clear)
		cmp	ah, 1			; bad command?
		stc				; indicate error
		je	set1M232error
		dec	cl			; dec retries
		jz	set1M232error		; no more retries, error
		cmp	ah, 80h			; drive busy?
		je	retry			; yes, retry
set1M232error:
		stc				; else, error
		jmp	done1M232
noFunction:
		popf
done1M232:
		pop	ds, bx
		jc	error
not1M232:
endif

	;
	; Record the address of the parameter table to use for the format.
	; 
		mov	ds:[DFD_methodData].DFMD_bios.DFBD_params.segment, es
		mov	ds:[DFD_methodData].DFMD_bios.DFBD_params.offset, di
	;
	; Figure the BiosDiskType for the drive based on the default media
	; and the medium we're formatting.
	; 
		mov	al, ds:[DFD_formatArgs].FSFA_drive
		call	DriveGetDefaultMedia	;ah <- PC/GEOS media descriptor

if PZ_PCGEOS
	;
	; use BDT_1M2_IN_1M2 for Pizza's 1.232M 3.5"
	;
		mov	al, BDT_1M2_IN_1M2
		cmp	ah, MEDIA_1M232
		je	doSet
endif

		mov	al, BDT_360_IN_360	; assume 360 in 360
		cmp	ah, MEDIA_360K
		je	doSet

		cmp	ah, MEDIA_1M2
		jne	check720
		
	    ;
	    ; In a 1.2M drive, so figure whether formatting 360 or 1.2 in the
	    ; drive.
	    ; 
		mov	al, BDT_1M2_IN_1M2	; assume 1.2M
		cmp	ds:[DFD_formatArgs].FSFA_media, MEDIA_1M2
		je	doSet
		mov	al, BDT_360_IN_1M2	; use 360K data rate for 360
						;  or below...
		jmp	doSet

check720:
	;
	; Not 360K or 1.2M drive. If also not 720K drive, BIOS doesn't support
	; us, so we can't support this function.
	; 
		cmp	ah, MEDIA_720K
		jne	check144
		
		mov	al, BDT_720_IN_720
doSet:
		mov	ah, B13F_SET_DISK_TYPE
		mov	dl, ds:[DFD_biosDrive]
		call	DOSFormatInt13

if PZ_PCGEOS
		jc	exit
	;
	; this triggers FD12.SYS to do something?
	;
		cmp	ds:[DFD_formatArgs].FSFA_media, MEDIA_1M232
		clc				; indicate error
		jne	exit
		push	bx
		mov	ax, 440fh		; IOCTL get drives
		mov	bl, ds:[DFD_formatArgs].FSFA_drive
		inc	bl			; 1-based
		call	DOSUtilInt21
		pop	bx
endif

exit:
		.leave
		ret
check144:
	;
	; 1.44Mb drives don't seem to need the SET_DISK_TYPE call, but we
	; don't want to fail, so just skip the call.
	; 
		cmp	ah, MEDIA_1M44
		je	exit
unsupported::
		mov	ax, FMT_ERR_DRIVE_CANNOT_BE_FORMATTED
		stc
		jmp	exit
error:
		mov	ax, FMT_DRIVE_NOT_READY
		stc
		jmp	exit
DOSFormatInitSetDiskType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatInitGetBPB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the current BiosParamBlock stored in the driver

CALLED BY:	(INTERNAL) DOSFormatInit
PASS:		ds	= DiskFormatData
RETURN:		ds:[DFD_methodData].DFMD_ioctl.DFID_newBPB set
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatInitGetBPB proc near
		.enter

	;-----------------------------------------------------------------------
	;specify:
	;  return default BPB (bit 0 of specialFunctions)

		mov	ds:[DFD_methodData].DFMD_ioctl.DFID_newBPB.SDP_common.GDP_specialFuncs, 
			SpecialFuncs <
			1,	; All sectors same size
			0,	; Set all aspects of the device
			0	; Get the DEFAULT BPB, NOT THE CURRENT ONE.
		>
		mov	dx, offset DFD_methodData.DFMD_ioctl.DFID_newBPB
		mov	cl, DGBDF_GET_DEVICE_PARAMS
		call	DOSFormatIoctl

		.leave
		ret
DOSFormatInitGetBPB endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatInitSaveBPB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Preserves the parameter block fetched by DOSFormatInitGetBPB
		so it can be reset at the end.

CALLED BY:	(INTERNAL) DOSFormatInit
PASS:		ds	= DiskFormatData
		ds:[DFD_methodData].DFMD_ioctl.DFID_newBPB
RETURN:		ds:[DFD_methodData].DFMD_ioctl.DFID_savedBPB set
DESTROYED:	si, di, cx, es
SIDE EFFECTS:	the entire DFID_savedBPB is overwritten

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DOS_FORMAT_RESTORE_BPB
DOSFormatInitSaveBPB proc near
		.enter
		segmov	es, ds
		mov	si, offset ds:[DFD_methodData].DFMD_ioctl.DFID_newBPB
		mov	di, offset ds:[DFD_methodData].DFMD_ioctl.DFID_saveBPB
		mov	cx, size DFID_newBPB
		rep	movsb
		.leave
		ret
DOSFormatInitSaveBPB endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatInitSetBPB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the driver's BiosParamBlock according to how we're
		formatting the disk.

CALLED BY:	(INTERNAL) DOSFormatInit
PASS:		ds	= DiskFormatData
		ds:[DFD_bpb] set
RETURN:		carry - set on error
DESTROYED:	ax, cx, dx, di, si, es
SIDE EFFECTS:	driver's current BPB set to ours

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatInitSetBPB proc near
		.enter
	;-----------------------------------------------------------------------
	;copy BPB over to BPB portion of newBPB

		segmov	es, ds

		mov	si, offset DFD_bpb
		mov	di, offset DFD_methodData.DFMD_ioctl.DFID_newBPB.SDP_common.GDP_bpb
			CheckHack <size DFD_bpb eq size GDP_bpb>
		mov	cx, size DFD_bpb
		rep	movsb

	;-----------------------------------------------------------------------
	;initialize track layout field

		mov	si, offset DFD_methodData.DFMD_ioctl.DFID_newBPB
		call	DOSFormatInitSetTrackLayout

	;-----------------------------------------------------------------------
	;figure the number of cylinders in the thing. This is the total
	;number of sectors, divided by the number of sectors per track (to
	;get the number of tracks), divided by the number of heads.

		call	DOSFormatInitGetNumSectors

	; 10/12/93: add in the number of "hidden sectors", too, so we get the
	; total number of sectors in the disk. I have no idea what a "hidden
	; sector" is, and no one seems to be able to tell me, but without this
	; addition, Sundisk cards end up with a remainder when we divide the
	; number of sectors by the sectors per track, and that's bad.
	; Note that under MS 3, only the low word is valid. As of today, all
	; versions of DR/NW DOS that require the DRI driver are 3.31-compatible
	; 		-- ardeb
if _MS3 or _DRI
   		add	ax, ds:[DFD_methodData].DFMD_ioctl.DFID_newBPB.SDP_common.GDP_bpb.BPB_numHiddenSectors.low
		adc	dx, 0
elif _MS4 or _MS5 or _OS2
		adddw	dxax, ds:[DFD_methodData].DFMD_ioctl.DFID_newBPB.SDP_common.GDP_bpb.BPB_numHiddenSectors
endif

		div	ds:[DFD_methodData].DFMD_ioctl.DFID_newBPB.SDP_common.GDP_bpb.BPB_sectorsPerTrack
		tst	dx			; s/b no remainder.
EC <		ERROR_NZ	FORMAT_BOGUS_BPB			>
NEC <		jnz	error						>
		div	ds:[DFD_methodData].DFMD_ioctl.DFID_newBPB.SDP_common.GDP_bpb.BPB_numHeads
		mov	ds:[DFD_methodData].DFMD_ioctl.DFID_newBPB.SDP_common.GDP_cylinders, ax

	;-----------------------------------------------------------------------
	;set BPB 

		mov	ds:[DFD_methodData].DFMD_ioctl.DFID_newBPB.SDP_common.GDP_specialFuncs, SpecialFuncs <
			1,	; All sectors same size
			0,	; Set all aspects of the device
			1	; Set the CURRENT BPB.
		>

		mov	cl, DGBDF_SET_DEVICE_PARAMS
		mov	dx, offset ds:[DFD_methodData].DFMD_ioctl.DFID_newBPB
		call	DOSFormatIoctl
NEC <done:								>
		.leave
		ret
NEC <error:								>
NEC <		stc							>
NEC <		jmp	done						>
DOSFormatInitSetBPB endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatInitRestoreBPB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the driver's BPB to what it was before we started.

CALLED BY:	(INTERNAL) DOSFormatCleanUp
PASS:		ds	= DiskFormatData
		ds:[DFD_methodData].DFMD_ioctl.DFID_savedBPB set
RETURN:		nothing
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DOS_FORMAT_RESTORE_BPB
DOSFormatInitRestoreBPB proc	near
		uses	si, cx, dx
		.enter

	;-----------------------------------------------------------------------
	;specify:
	;  specify new default BPB (bit 0 of specialFunctions)
	;  normal track layout (bit 2 of specialFunctions)

		mov	si, offset DFD_methodData.DFMD_ioctl.DFID_saveBPB
		call	DOSFormatInitSetTrackLayout

;		mov	ds:[DFD_methodData].DFMD_ioctl.DFID_saveBPB.SDP_common.GDP_specialFuncs, SpecialFuncs <
;			1,	; All sectors same size
;			0,	; Set all aspects of the device
;			1	; Set the CURRENT BPB first.
;		>

		mov	cl, DGBDF_SET_DEVICE_PARAMS 
		mov	dx, offset ds:[DFD_methodData].DFMD_ioctl.DFID_saveBPB
;		call	DOSFormatIoctl	; destroys nothing
	;
	; Set the default BPB as well, so DOS 4.X knows to go back to looking at
	; the boot sector to determine the disk geometry.
	; 
		mov	ds:[DFD_methodData].DFMD_ioctl.DFID_saveBPB.SDP_common.GDP_specialFuncs, SpecialFuncs <
			1,	; All sectors same size
			0,	; Set all aspects of the device
			0	; Set the DEFAULT BPB, NOT THE CURRENT ONE.
		>
		call	DOSFormatIoctl

EC<	        jnc	done						>
EC<	        mov	ah, MSDOS_GET_EXT_ERROR_INFO			>
EC<	        clr	bx						>
EC<	        call	DOSUtilInt21					>
EC<	        mov	dx, ax						>
EC<	        ERROR	FORMAT_IOCTL_FAILED				>
EC<done:								>
		mov	ah, MSDOS_RESET_DISK
		call	DOSUtilInt21

		.leave
		ret
DOSFormatInitRestoreBPB endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSFormatInitSetTrackLayout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the SDP_trackLayout field of a SetDeviceParams
		structure.

CALLED BY:	(INTERNAL) DOSFormatInitSetBPB, DOSFormatInitRestoreBPB
PASS:		ds:si	= SetDeviceParams structure with SDP_common.GDP_bpb
			  properly initialized.
RETURN:		nothing
DESTROYED:	ax, cx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSFormatInitSetTrackLayout	proc	near
		.enter
		mov	cx, ds:[si].SDP_common.GDP_bpb.BPB_sectorsPerTrack
		mov	ds:[si].SDP_numSectors, cx
		add	si, offset SDP_trackLayout
		mov	ax, 1
sectorLoop:
		mov	ds:[si].TLE_sectorNum, ax
		mov	ds:[si].TLE_sectorSize, MSDOS_STD_SECTOR_SIZE
		add	si, size TrackLayoutEntry
		inc	ax
		loop	sectorLoop
		.leave
		ret
DOSFormatInitSetTrackLayout	endp

DiskFormatCode	ends
