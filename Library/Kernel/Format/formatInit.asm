COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		KLib/Format
FILE:		formatInit.asm

AUTHOR:		Cheng, 1/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial revision

DESCRIPTION:
	Initializes variables prior to formatting.
		
	$Id: formatInit.asm,v 1.1 97/04/05 01:18:24 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatDoInit

DESCRIPTION:	Initialize variables.

CALLED BY:	INTERNAL (LibDiskFormat)

PASS:		ds - dgroup
		ah - drive number (0 based)
		al - PC/GEOS media descriptor
		cx:dx - fptr to callback routine
			dx = 0ffffh if none
		bp - callback specifier
			CALLBACK_WITH_PCT_DONE
			CALLBACK_WITH_CYL_HEAD
		es:di - ASCIIZ volume name

RETURN:		carry set on error
		ax - error code

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

FormatDoInit	proc	far
	push	es

	;-----------------------------------------------------------------------
	;initialize callback interaction vars

	mov	ds:[callbackRoutine.offset], dx
	mov	ds:[callbackRoutine.segment], cx
	mov	ds:[callbackInfoFlag], bp
	mov	ds:[volumeNameAddr.offset], di
	mov	ds:[volumeNameAddr.segment], es
	mov	ds:[abortFlag], 0

	;-----------------------------------------------------------------------
	;initialize medium vars

	call	SetDrive			;change to drive, init var

	;-----------------------------------------------------------------------
	;allocate work buffer

	push	ax				;save PC/GEOS media descriptor
	mov	ax, MSDOS_STD_SECTOR_SIZE
	mov	cx, HAF_STANDARD_LOCK shl 8
	call	MemAllocFar
	jnc	haveBuffer
	pop	ax
	mov	ax, FMT_ERR_CANNOT_ALLOC_SECTOR_BUFFER
	jmp	FDI_error

haveBuffer:
	mov	ds:[workBufHan], bx
	mov	ds:[workBufSegAddr], ax
	pop	ax

	call	FormatInitMediaVars

	;-----------------------------------------------------------------------
	;modify BPB if necessary

	call	IsIoctlPresent
	jc	noIoctl

	call	GetBPB				;destroys ax,bx,cx,dx
	call	SaveBPB				;destroys ax,cx,di,si,es
	call	SetBPB				;destroys ax,cx,dx,di,si,es

noIoctl:
	;-----------------------------------------------------------------------

	mov	ax, ds:[mediaVars.BPB_sectorSize]
	mov	bx, ROOT_DIR_ENTRY_SIZE
	clr	dx
	div	bx
	mov	ds:[rootDirsPerSector], ax

	;-----------------------------------------------------------------------
	;get logical sector number of start

	mov	ax, ds:[mediaVars.BPB_sectorsPerTrack]
	push	ax
	mul	ds:[mediaVars.BPB_numHeads]	;dx:ax <- sectors per cylinder
	mov	ds:[sectorsPerCylinder], ax

	mul	ds:[curCylinder]
	mov	bx, ax			;bx <- sector offset to start cylinder
	pop	ax			;ax <- sectors per track
	mul	ds:[curHead]		;ax <- offset to start track
	add	ax, bx			;ax <- offset to start sector
	add	ax, ds:[curSector]
	dec	ax
	mov	ds:[startBoot], ax

	;-----------------------------------------------------------------------
	;init positions for disk areas

	push	ax			;save logical sector of boot
	add	ax, ds:[mediaVars.BPB_numReservedSectors]
	mov	ds:[startFAT], ax
	mov	bx, ax			;bx <- logical sector of FAT

	pop	ax			;ax <- logical sector of boot
	clr	dx
	div	ds:[mediaVars.BPB_sectorsPerTrack]
	inc	ax
	mov	ds:[startTrack], ax

	mov	ax, ds:[mediaVars.BPB_sectorsPerFAT]
	mul	ds:[mediaVars.BPB_numFATs]
	add	ax, bx			;ax <- start FAT + FAT size
	mov	ds:[startRoot], ax
	mov	bx, ax

	mov	ax, ds:[mediaVars.BPB_numRootDirEntries]
	clr	dx
	div	ds:[rootDirsPerSector]
	mov	ds:[rootDirSize], ax
	add	ax, bx
	mov	ds:[startFilesArea], ax

	;-----------------------------------------------------------------------
	;init other disk vars

	clr	dx
	div	ds:[mediaVars.BPB_sectorsPerTrack]
	inc	ax
	mov	ds:[lastRootDirTrack], ax

	mov	ax, ds:[mediaVars.BPB_sectorsPerTrack]
	sub	ax, dx
	mov	ds:[unprocessedFilesAreaSectors], ax

	mov	ax, ds:[mediaVars.BPB_numSectors]
	clr	dx
	div	ds:[mediaVars.BPB_sectorsPerTrack]
	mov	ds:[numTracks], ax

	;-----------------------------------------------------------------------
	;if Ioctl is absent, allocate buffers for track verification

	call	IsIoctlPresent
	jnc	FDI_20

	mov	ax, MSDOS_STD_SECTOR_SIZE
	mul	ds:[mediaVars.BPB_sectorsPerTrack]
	mov	ds:[mediaBytesPerTrack], ax
	mov	cx, HAF_STANDARD_LOCK shl 8
	call	MemAllocFar
	jnc	haveVerifyBuffer

	mov	bx, ds:[workBufHan]	; Free working buffer
	call	MemFree
	call	RestoreBPB
	mov	ax, FMT_ERR_CANNOT_ALLOC_SECTOR_BUFFER
	stc
	jmp	FDI_error

haveVerifyBuffer:
	mov	ds:[trackVerifyBufSegAddr], ax
	mov	ds:[trackVerifyBufHan], bx

	call	SetDiskType

	;-----------------------------------------------------------------------
	;stuff disk base table entry with correct number of sectors
	;some way around this?

	mov	ax, 351eh		;get addr of disk base table
	call	FileInt21		;es:bx <- addr of base table
	mov	al, {byte}ds:[mediaVars.BPB_sectorsPerTrack]
	mov	es:[bx+4], al		; XXX

FDI_20:
	clr	ax			;return no errors
	mov	ds:[ioctlFmtTrkParamBlk.FTPB_specialFunctions], al
	mov	ds:[ioctlFmtTrkParamBlk.FTPB_head], ax
	mov	ds:[ioctlFmtTrkParamBlk.FTPB_cylinder], ax

	mov	ds:[clusterStat], ax
	mov	ds:[goodClusters], ax
	mov	ds:[badClusters], ax
FDI_error:
	pop	es
	ret
FormatDoInit	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetDrive

DESCRIPTION:	Select and reset the specified drive.

CALLED BY:	INTERNAL (LibGetMediaAndOptions, LibDiskFormat)

PASS:		ds - dgroup
		ah - 0 based drive code

RETURN:		ds:[drive]
		ds:[biosDrive]

DESTROYED:	carry clear if successful
		carry set otherwise, error in ds:[errCode]

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@

SetDrive	proc	near
	push	ax, dx
	mov	al, ah

	mov	ds:[drive], al

	call	DriveGetStatusFar
	test	ah, mask DS_MEDIA_REMOVABLE
	jne	floppy
	sub	al, 2				;convert to fixed drive num
	or	al, 80h
floppy:
	mov	ds:[biosDrive], al

; I can see no use in this, since we're not doing real file OPs on the disk...
;	- ardeb 4/28/90
;	mov	ah, MSDOS_SET_DEFAULT_DRIVE	;select drive
;	mov	dl, ds:[drive]
;	call	FileInt21			;destroys al

	clr	ah				;reset disk
	mov	dl, ds:[biosDrive]
	call	FormatInt13
	mov	al, ah
	clr	ah
	mov	ds:[errCode], ax

	pop	ax, dx
	ret
SetDrive	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatInitMediaVars

DESCRIPTION:	Initialize variables relating to the medium that we're going
		to work on.

CALLED BY:	INTERNAL (FormatDoInit)

PASS:		ds - dgroup
		al - PC/GEOS media descriptor

RETURN:		media vars

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial version

-------------------------------------------------------------------------------@


FormatInitMediaVars	proc	near
	push	ax,cx,di,si
EC<	call	ECCheckDS						>


	push	ax
	mov	al, ds:[drive]
	call	DriveGetStatusFar
	mov	ds:[mediaStatus], ah
	test	ah, mask DS_MEDIA_REMOVABLE
	pop	ax
	jnz	floppy

	;-----------------------------------------------------------------------
	;dealing with fixed disk...
	;
	;if IOCTL is present then
	;    get params
	;    copy BPB over to media vars
	;else
	;    get boot sector
	;    copy BPB over to media vars
	;
	;get partition entry

	mov	ds:[ioctlFuncCode], 62h		;verify track
	jmp	short done

floppy:
	;-----------------------------------------------------------------------
	;dealing with floppy disk...

	push	ds,es
	clr	ah
	dec	ax				;make ax 0 based
	mov	cx, size BiosParamBlock		;cx <- block size
	mul	cx				;ax <- 0 based offset
	add	ax, offset cs:[BPB_160K]	;ax <- offset to BPB for media
	mov	si, ax
	mov	di, offset dgroup:[mediaVars]
	push	cs
	push	ds
	pop	es			; es <- ds
	pop	ds			; ds <- cs
	rep	movsb
	pop	ds,es

	clr	ax
	mov	ds:[curCylinder], ax
	mov	ds:[curHead], ax
	mov	ds:[curSector], 1

	mov	ds:[ioctlFuncCode], 42h		;format and verify track

done:
	pop	ax,cx,di,si
	ret
FormatInitMediaVars	endp


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
IF	0
	CheckHack <MEDIA_FIXED_DISK eq 8>
BPB_fixed	BiosParamBlock <
	512,		;sectorSize
	0,		;clusterSize, 4 or 8
	1,		;numReservedSectors
	2,		;numFATs
	0,		;numRootDirEntries, 200 or 512
	0,		;numSectors
	DOS_MEDIA_FIXED_DISK,	;mediaDescriptor
	0,		;sectorsPerFAT
	17,		;sectorsPerTrack
	0,		;numHeads, 4, 5 or 7
	0		;numHiddenSectors
>
ENDIF

	ForceRef	BPB_180K
	ForceRef	BPB_320K
	ForceRef	BPB_360K
	ForceRef	BPB_720K
	ForceRef	BPB_1M2
	ForceRef	BPB_1M44


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetDiskType

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		No ioctl present.
		ds - dgroup

		what user desires:
		    ds:[mediaDescriptor] - valid values are:
			DOS_MEDIA_360K
			DOS_MEDIA_1M2
		
		what drive user has:
		    ds:[drive]

RETURN:		

DESTROYED:	

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

-------------------------------------------------------------------------------@

SetDiskType	proc	near
	push	ax,cx,dx

	;reset disk driver
	clr	ah
	call	FormatInt13

	call	SysGetConfig		;dh <- machine type, alters ax

	mov	dl, ds:[drive]

	cmp	dh, SMT_PC_XT
	je	doSetMedia

	cmp	dh, SMT_PC_AT
	jne	doSetDASD

doSetMedia:
	call	SetMediaType

doSetDASD:
	cmp	ch, SMT_PC_AT
	jb	exit

	mov	al, dl
	call	DriveGetDefaultMedia	;ah <- PC/GEOS media descriptor

	cmp	ah, MEDIA_360K
	mov	al, 1			;floppy disk type code <- 1
	je	doSet

	cmp	ah, MEDIA_1M2
	mov	al, 4			;al <- 4
	jne	doSet

	mov	cl, ds:[mediaVars.BPB_mediaDescriptor]

	dec	al			;al <- 3
	cmp	cl, DOS_MEDIA_1M2
	je	doSet

	dec	al			;al <- 2
	cmp	cl, DOS_MEDIA_360K
	je	doSet

	cmp	cl, DOS_MEDIA_320K
	je	doSet

	cmp	cl, DOS_MEDIA_180K
	je	doSet

	cmp	cl, DOS_MEDIA_160K
	je	doSet

	mov	al, 4
doSet:
	mov	ah, 17h			;BIOS set disk type
	call	FormatInt13
exit:
	pop	ax,cx,dx
	ret
SetDiskType	endp


SetMediaType	proc	near
	push	es,di
	mov	cx, ds:[numTracks]
	mov	al, ch			;bits 0,1 of al <- ms cylinder bits
	mov	ch, cl
	mov	cl, 6
	shl	ax, cl
	mov	cl, al
	or	cl, {byte}ds:[mediaVars.BPB_sectorsPerTrack]
	mov	ah, 18h
	call	FormatInt13
	pop	es,di
	ret
SetMediaType	endp
