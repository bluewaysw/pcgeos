COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Format
FILE:		formatFormat.asm
AUTHOR:		Cheng, 1/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/90		Initial revision

DESCRIPTION:
		
	$Id: formatFormat.asm,v 1.1 97/04/05 01:18:19 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatTracks

DESCRIPTION:	Formats tracks from the given cylinder and head.

CALLED BY:	INTERNAL (FormatTrack)

PASS:		ds - dgroup
		es - seg addr of sector work area
		bp - number of tracks

RETURN:		carry set on error
		ax - error code

DESTROYED:	ax, bx, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@

FormatTracks	proc	near
	mov	cx, ds:[curCylinder]
	mov	dx, ds:[curHead]
FT_loop:
	call	FormatTrack
	jc	FT_exit

	inc	dx				;next head
	mov	ds:[curHead], dx
	cmp	dx, ds:[mediaVars.BPB_numHeads]	;valid head number?
	jb	FT_checkDone			;branch if so

	clr	dx
	mov	ds:[curHead], dx		;else reset head to 0
	inc	cx
	mov	ds:[curCylinder], cx		;next cylinder
FT_checkDone:
	dec	bp
	jne	FT_loop

	clr	ax
FT_exit:
	ret
FormatTracks	endp



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
noBootee	char	"This disk is not bootable.\r\nSystem HALTED\r\n", 0
NonSysBootstrap	endp

BOOTSTRAP_LENGTH equ $-NonSysBootstrap


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitReservedArea

DESCRIPTION:	Initialize the Reserved Area on the disk.

CALLED BY:	INTERNAL (LibDiskFormat)

PASS:		ds - dgroup
		es - seg addr of sector work area

RETURN:		carry set on error
		ax - 0 if successful, FMT_ERR_WRITING_BOOT if not

DESTROYED:	ax, cx, dx, di, si

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

-------------------------------------------------------------------------------@

oemName	char	'GEOWORKS'
	char	length BS_oemNameAndVersion - length oemName dup (' ')

InitReservedArea	proc	near
	call	ZeroSectorWorkArea

	;copy Bios Param Block
	mov	si, offset ds:[mediaVars]		;si <- start off to BPB
	mov	di, offset BS_bpbSectorSize		;= BS_biosParamBlock
	mov	cx, offset BS_totalSectorsInVolume - offset BS_bpbSectorSize
	rep	movsb

if 0
; certain execrable device drivers refuse to look at the geometry information we
; so kindly place in the boot sector unless there's a jump at the start (or
; an IMUL -- God only knows why).
	; Mark as non-bootable (we write no bootstrap code out)
	mov	{word}es:[BS_jumpInstr], 0
	mov	{byte}es:[BS_jumpInstr+2], 0
	mov	es:[BS_bootableSig], 0
else
	; install short jump to BS_bootstrap
	mov	{word}es:[BS_jumpInstr], ((BS_bootstrap - 2) shl 8) or 0xeb
	mov	es:[BS_jumpInstr+2], 0x90
	mov	es:[BS_bootableSig], 0xaa55

	; Copy in non-system-disk bootstrap code
	push	ds	
	segmov	ds, cs
	mov	si, offset NonSysBootstrap
	mov	di, offset BS_bootstrap
	mov	cx, BOOTSTRAP_LENGTH
	rep	movsb
	pop	ds
endif

	;***** init disk ID *****
	mov	dl, ds:[drive]
	mov	es:[BS_physicalDriveNumber], dl
	mov	es:[BS_extendedBootSig], EXTENDED_BOOT_SIGNATURE

	mov	di, offset BS_oemNameAndVersion
	mov	si, offset oemName
	rept	length BS_oemNameAndVersion / 2
	movsw	cs:
	endm

	;-----------------------------------------------------------------------
	;init volume id in the boot sector and the disk handle (if disk was
	;already formatted before)

	call	DiskGenerateSysId
	mov	es:[BS_volumeID.low], di
	mov	es:[BS_volumeID.high], dx

	mov	si, ds:[diskHandle]
	tst	si
	jz	initLabel
	
	push	ds
	andnf	dx, mask DIDH_ID_HIGH	; Clear out all but high part of ID
	ornf	dx, mask DIDH_WRITABLE	; Disk must be writable...
	mov	al, ds:[drive]		; Shift drive number into position
	mov	cl, offset DIDH_DRIVE
	shl	al, cl
	or	dl, al			;  and merge it into the ID

	LoadVarSeg	ds		; Now store the three bytes in the
	mov	ds:[si].HD_idLow, di	; handle
	mov	ds:[si].HD_idHigh, dl
	pop	ds
	

	;-----------------------------------------------------------------------
	;init volume label

initLabel:
	push	ds
	mov	di, BS_volumeLabel
	mov	cx, size BS_volumeLabel
	lds	si, ds:[volumeNameAddr]
copyVolumeLabel:
	lodsb
	tst	al
	jne	upcase?
	mov	al, ' '
	dec	si
	jmp	store
upcase?:
	cmp	al, 'a'
	jb	store
	cmp	al, 'z'
	ja	store
	sub	al, 'a' - 'A'
store:
	stosb
	loop	copyVolumeLabel
	pop	ds

	mov	cx, ds:[startBoot]			;specify sector 1
	call	WriteWorkArea
	mov	ax, FMT_ERR_WRITING_BOOT
	jc	IRA_error
	clr	ax
IRA_error:
	ret
InitReservedArea	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitFAT

DESCRIPTION:	

CALLED BY:	INTERNAL (LibDiskFormat)

PASS:		ds - dgroup
		es - seg addr of sector work area

RETURN:		carry set on error
		ax - 0 if successful, FMT_ERR_WRITING_ROOT_DIR if not

DESTROYED:	bx, bp, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version

-------------------------------------------------------------------------------@

InitFAT	proc	near
	mov	al, ds:[mediaVars.BPB_numFATs]
	clr	ah
	mov	bp, ds:[mediaVars.BPB_sectorsPerFAT]
	mul	bp
	mov	bp, ax
	mov	cx, ds:[startFAT]

	call	ZeroSectorWorkArea
initLoop:
	call	WriteWorkArea
	jc	error

	inc	cx				;next logical sector
	dec	bp				;dec count
	jnz	initLoop

	clr	ax
	ret
error:
	mov	ax, FMT_ERR_WRITING_FAT
	stc
	ret
InitFAT	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitRootDirectory

DESCRIPTION:	Initialize the Root Directory portion of the disk.

CALLED BY:	INTERNAL (LibDiskFormat)

PASS:		ds - dgroup
		es - seg addr of sector work area

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

-------------------------------------------------------------------------------@

InitRootDirectory	proc	near
;	mov	bx, ds:[mediaNumRootDirEntries]	;bx <- num entries
	mov	bp, ds:[rootDirSize]
	mov	cx, ds:[startRoot]

	call	ZeroSectorWorkArea
initLoop:
	call	WriteWorkArea
	jc	IRD_error
	inc	cx				;next logical sector
	dec	bp				;dec count
	jnz	initLoop

	clr	ax
	ret
IRD_error:
	mov	ax, FMT_ERR_WRITING_ROOT_DIR
	stc
	ret
InitRootDirectory	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitRootDirSector

DESCRIPTION:	Initialize the sector work area to serve as part of a
		root directory.

CALLED BY:	INTERNAL (currently unused)

PASS:		ds - dgroup
		es - seg addr of sector work area

RETURN:		sector work area initialized

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@

IF	0
InitRootDirSector	proc	near
	push	cx,di,es
	mov	cx, ROOT_DIR_ENTRIES_PER_SECTOR
	mov	es, ds:[workBufSegAddr]
	clr	di
IRDS_loop:
	mov	word ptr es:[di], ROOT_DIR_ENTRY_INIT_SIG
	add	di, ROOT_DIR_ENTRY_SIZE
	loop	IRDS_loop
	pop	cx,di,es
	ret
InitRootDirSector	endp
ENDIF


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatFilesArea

DESCRIPTION:	Formats the Files Area portion of the disk and builds
		the FAT at the same time. The FATs are written out when
		formatting is done.

CALLED BY:	INTERNAL (LibDiskFormat)

PASS:		ds - dgroup

RETURN:		carry set on error
		ax - 0 if successful, FMT_ERR_WRITING_FAT if not

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


FormatFilesArea	proc	near
	push	ds
	;-----------------------------------------------------------------------
	;make cl contain bios sector number for start of the Files Area
	;
	;bios sector number = (logical sector number MOD sectors per track) + 1

	mov	ax, ds:[startFilesArea]		;get logical sector number
	clr	dx
	mov	si, ds:[mediaVars.BPB_sectorsPerTrack]
	div	si				;dx <- ax mod sectors per track

	sub	si, dx				;calc num unprocessed sectors
	mov	ds:[unprocessedFilesAreaSectors], si

	inc	dl
	mov	cl, dl				;cl<- bios sector of Files Area

	;-----------------------------------------------------------------------
	;make ax contain num clusters
	;
	;num clusters = (num sectors - start files area) DIV cluster size

	mov	ax, ds:[mediaVars.BPB_numSectors]
	sub	ax, ds:[startFilesArea]		;ax <- num sectors in files area

	mov	bl, ds:[mediaVars.BPB_clusterSize]
	clr	bh
	clr	dx
	div	bx				;ax <- num clusters

	;-----------------------------------------------------------------------
	;make bp contain 12/16 bit FAT format indicator

	clr	bp				;assume 12 bit format
	cmp	ax, FAT_16_BIT_THRESHOLD	;16 bit format required?
	jb	FFA_calcFATSize			;branch if not
	inc	bp				;else modify value
FFA_calcFATSize:
	;-----------------------------------------------------------------------
	;allocate space for FAT in mem
	;ax = num clusters
	;for 12 bit FAT format = num clusters * 1.5
	;for 16 bit FAT format = num clusters * 2

	push	cx				;save cur sector
	mov	cx, ax
	shr	cx, 1				;cx <- num clusters / 2
	shl	ax, 1				;ax <- num clusters * 2
	tst	bp				;12 bit format?
	jne	FFA_allocSpace			;branch if not
	sub	ax, cx				;else ax <- num clusters * 1.5
FFA_allocSpace:
	add	ax, 4				;add space for first 2 entries
	push	ax				;save byte size of work area
	mov	bx, ds:[workBufHan]
	mov	ch, mask HAF_ZERO_INIT
	call	MemReAlloc			;ax <- func(ax,ch), destroys cx
	jnc	haveFATBuffer

	add	sp, 4				;nuke saved ax, cx
	mov	ax, FMT_ERR_WRITING_FAT
	stc
	jmp	exit

haveFATBuffer:
	mov	ds:[workBufSegAddr], ax
	mov	es, ax

	;-----------------------------------------------------------------------
	;zero init work area

	pop	cx				;cx <- byte size of work area
	clr	ax				;init value to stuff
	mov	di, ax
	cld
	rep	stosb
	pop	cx

	clr	di				;init FAT entry offset
	mov	byte ptr ds:[toggle], 0

	;-----------------------------------------------------------------------
	;reserve the first 2 FAT entries

	mov	al, ds:[mediaVars.BPB_mediaDescriptor]
	mov	ah, 0ffh
	mov	es:[di], ax			;init 1st word to media
						; descriptor
	add	di, 2

	mov	es:[di], ah			;init 3rd byte
	tst	bp
	je	FFA_10
	inc	di
	mov	es:[di], ah			;init 4th byte if 16 bit format
FFA_10:
	inc	di

	;-----------------------------------------------------------------------
	;ds = dgroup
	;bp = FAT format flag

EC<	mov	ax, ds:[mediaVars.BPB_sectorsPerTrack]			>
EC<	cmp	ax, ds:[unprocessedFilesAreaSectors] 			>
EC<	jae	FFA_20							>
EC<	ERROR	FORMAT_ASSERTION_FAILED					>
EC<FFA_20:								>

	call	ProcessClusters

	mov	si, ds:[numTracks]
	sub	si, ds:[lastRootDirTrack]	;si <- num tracks to process
FFA_loop:
	push	cx, dx
	mov	cx, ds:[curCylinder]		;init param table
	mov	dx, ds:[curHead]
	call	FormatTrack
	pop	cx, dx				;ch <- cylinder, dh <- head
	jnc	FFA_trackOK

	cmp	ax, FMT_ABORTED
	stc
	je	exit

	;format/verify track failed, verify clusters individually
	call	ProcessBadTrack
	jmp	short FFA_nextTrack
FFA_trackOK:
	mov	ax, ds:[mediaVars.BPB_sectorsPerTrack]
	add	ds:[unprocessedFilesAreaSectors], ax
	call	ProcessClusters			;func(ds,bp), destroys ax
FFA_nextTrack:
	mov	ax, ds:[curHead]
	inc	ax				;next head
	mov	ds:[curHead], ax
	cmp	ax, ds:[mediaVars.BPB_numHeads]	;valid head number?
	jb	FFA_checkDone			;branch if so

	clr	ds:[curHead]			;else reset head to 0
	inc	ds:[curCylinder]		;next cylinder
FFA_checkDone:
	dec	si
	jne	FFA_loop
	call	ProcessClusters			;process remaining sectors

	call	WriteFATs
exit:
	pop	ds
	ret
FormatFilesArea	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ProcessClusters

DESCRIPTION:	Track was formatted and verified successfully. Update the
		appropriate number of FAT entries.

CALLED BY:	INTERNAL (FormatFilesArea)

PASS:		ds - dgroup
		bp - FAT format flag

RETURN:		di - offset to next cluster entry

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@


ProcessClusters	proc	near
EC<	tst	bp							>
EC<	je	bpOK							>
EC<	cmp	bp, 1							>
EC<	ERROR_NZ FORMAT_ASSERTION_FAILED				>
EC< bpOK:								>

	push	cx, dx, si
	mov	ax, ds:[unprocessedFilesAreaSectors]
	tst	ax
	je	PC_done

	clr	ch
	mov	cl, ds:[mediaVars.BPB_clusterSize]
	cmp	cx, 1				;cluster size = 1?
	je	PC_trivial			;branch if so

	clr	dx
	div	cx				;ax <- complete clusters present
	mov	ds:[unprocessedFilesAreaSectors], dx	;save for next track
	jmp	short PC_clustersComputed
PC_trivial:
	mov	ds:[unprocessedFilesAreaSectors], 0
PC_clustersComputed:
	add	ds:[goodClusters], ax
	mov	cx, ax				;cx <- num clusters
	mov	si, ax

	;-----------------------------------------------------------------------
	;exploit fact that work area was 0 initialized

	tst	bp				;12 bit?
	je	PC_12bit			;branch if so
	shl	cx, 1				;else cx <- cx * 2
	jmp	short PC_update			;carry is clear
PC_12bit:
	;-----------------------------------------------------------------------
	;this portion will probably be difficult to decipher

	;first some definitions
	;a number of clusters is 'even' if the number of bytes required for
	;    their FAT entries is whole. The clusters are 'odd' otherwise.
	;a FAT entry is 'aligned' if the ls 8 bits fit entirely in es:[di].
	;    The entry is 'unaligned' if the ms 8 bits fit in es:[di+1])

	;if the current FAT entry is aligned, the correct di offset will always
	;    be obtained if we add INT(num clusters * 1.5)
	;if the current FAT entry is unaligned, in addition to adding
	;    INT(num clusters * 1.5), we need to inc di if the number
	;    of entries to be updated is 'odd'

	shr	ax, 1				;ax <- num clusters / 2
	pushf
	add	cx, ax				;cx <- cx * 1.5
	popf
	jnc	PC_12BitUpdateToggle		;branch if clusters are even

	test	ds:[toggle], 1			;aligned?
	je	PC_12BitUpdateToggle		;branch if so
	inc	di
PC_12BitUpdateToggle:
	test	si, 1				;adding even number of clusters?
	je	PC_update			;branch if so, no toggle change
	xor	ds:[toggle], 1			;else flip bit
PC_update:
	add	di, cx
PC_done:
	pop	cx,dx, si
	ret
ProcessClusters	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ProcessBadTrack

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

CALLED BY:	INTERNAL (FormatFilesArea)

PASS:		bp - FAT format flag
		es - work buffer seg addr
		di - offset to current cluster entry
		ds:[curCylinder]
		ds:[curHead]

RETURN:		di - offset to next cluster entry

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	format/verify track failed for some reason
	find corresponding cluster, store status

	ax <- offset from start of files area
	dx <- ax MOD cluster size
	if (dx <> 0) then
	    mark prev cluster bad
	    processed sectors <- cluster size - dx
	else
	    processed clusters <- 0
	endif
	unprocessed sectors <- sectors per track - processed sectors
	unprocessed clusters <- CEILING(unprocessed sectors / cluster size)
	    (dx <- remainder)
	for unprocessed clusters
	    stuff bad cluster flag in FAT work area

	;compute number of full clusters for updating di

	if (dx <> 0)
	    unprocessed clusters--
	di <- di + (unprocessed clusters * FAT entry size)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	if bios verify track is used, take care of upper 2 bits of 10-bit
	cylinder number in cl

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@

TRUE	=	-1

if	TRUE	;***************************************************************

ProcessBadTrack	proc	near
EC<	tst	bp							>
EC<	je	bpOK							>
EC<	cmp	bp, 1							>
EC<	ERROR_NZ FORMAT_ASSERTION_FAILED				>
EC< bpOK:								>

	push	ax, cx, dx, si

	;-----------------------------------------------------------------------
	;get offset of sector from start of the Files Area

	mov	ax, ds:[curHead]
	mul	ds:[mediaVars.BPB_sectorsPerTrack];ax <- head * sectors per trk
	mov	cx, ax				;save result in cx

	mov	ax, ds:[curCylinder]
	mul	ds:[sectorsPerCylinder]		;ax <- cyl * sectors per cyl
	add	ax, cx

	sub	ax, ds:[startFilesArea]		;ax <- offset from Files Area

	mov	cl, ds:[mediaVars.BPB_clusterSize]
	clr	ch
	clr	dx
	div	cx				;dx <- ax MOD cluster size
	tst	dx
	mov	ax, ds:[mediaVars.BPB_sectorsPerTrack];ax <- num unprocessed
						      ; sectors
	je	findUnprocClusters

	;-----------------------------------------------------------------------
	;previous cluster bad

EC<	cmp	di, 3							>
EC<	ERROR_Z	FORMAT_ASSERTION_FAILED					>

	mov	ax, FAT_CLUSTER_BAD
	tst	bp				;12/16 bit FAT?
	je	prevBad12

	or	es:[di-2], ax
	jmp	short prevClusterDone

prevBad12:
	test	byte ptr ds:[toggle], 1		;current cluster even or odd?
	je	prevOdd
	;prev even
	and	ah, 0fh
	or	es:[di-1], ax
	jmp	short prevClusterDone
prevOdd:
	mov	cl, 4
	shl	ax, cl

	or	es:[di-2], al			;mask ls 4 bits into high nibble
	mov	es:[di-1], ah			;store ms 8 bits

prevClusterDone:
	;-----------------------------------------------------------------------
	;ax <- num unprocessed sectors

	mov	ax, ds:[mediaVars.BPB_sectorsPerTrack]
	sub	al, ds:[mediaVars.BPB_clusterSize]
	sbb	ah, 0
	add	ax, dx

findUnprocClusters:
	;-----------------------------------------------------------------------
	;ax <- CEILING(unprocessed sectors / cluster size)
	;dx <- remainder

	mov	cl, ds:[mediaVars.BPB_clusterSize]
	clr	ch
	clr	dx
	div	cx
	tst	dx				;any remainder?
	je	unprocClustersDone		;branch if not
	inc	ax

unprocClustersDone:
	;-----------------------------------------------------------------------
	;for unprocessed clusters
	;    stuff bad cluster flag in FAT work area

	add	ds:[badClusters], ax
	mov	cx, ax

initLoop:
	tst	bp
	je	do12Bit

	or	es:[di], FAT_CLUSTER_BAD	;mask in status
	mov	si, 2
	jmp	short initNext
do12Bit:
	test	byte ptr ds:[toggle], 1		;even or odd?
	jnz	do12BitOdd			;branch if odd

	;12 bit format - even
	or	es:[di], FAT_CLUSTER_BAD and 0fffh
	mov	si, 1
	jmp	short initNext
do12BitOdd:
	;12 bit format - odd
	mov	ax, 0ff70h			;FAT_CLUSTER_BAD shl 4

	or	es:[di], al			;mask ls 4 bits into high nibble
	mov	es:[di+1], ah			;store ms 8 bits
	mov	si, 2
initNext:
	cmp	cx, 1				;last cluster?
	jne	doUpdateDI			;go inc di if not
	tst	dx				;else does this cluster sit
						; on the next track as well?
	jne	doNext				;don't inc di if so
doUpdateDI:
	xor	ds:[toggle], 1			;flip odd/even bit
	add	di, si
doNext:
	loop	initLoop

	pop	ax, cx, dx, si
	ret
ProcessBadTrack	endp

else	;***********************************************************************

ProcessBadTrack	proc	near
	push	ax, bx, cx, dx, si
	mov	bx, ds:[mediaVars.BPB_sectorsPerTrack]
;	mov	cl, 1				;cl <- sector 1
PBT_loop:
;	mov	ax, 0401h			;verify 1 sector
;	int	13h
;	pushf					;save result of verify
	;-----------------------------------------------------------------------
	;get offset of sector from start of the Files Area

	push	cx
	push	dx

	mov	al, dh
	clr	ah
	mul	bx				;ax <- head * sectors per trk
	mov	si, ax				;save result in si

	mov	al, ch
	clr	ah
	mul	ds:[sectorsPerCylinder]		;ax <- cyl * sectors per cyl
	add	ax, si

	pop	dx
	pop	cx
	add	al, cl				;ax <- logical sector + 1
	jnc	PBT_10
	inc	ah
PBT_10:
	dec	ax

	sub	ax, ds:[startFilesArea]		;ax <- offset from Files Area

	;-----------------------------------------------------------------------
	;modify di if we are processing a new cluster

	cmp	ds:[mediaVars.BPB_clusterSize], 1
	je	PBT_trivial			;always new cluster if size=1

	push	cx, dx
	clr	ch
	mov	cl, ds:[mediaVars.BPB_clusterSize]
	clr	dx
	div	cx
	tst	dx				;are we on to a new cluster?
	pop	cx, dx

	jne	PBT_20				;branch if not
PBT_trivial:
	;on to a new cluster

	tst	bp				;12/16 bit FAT format?
	je	PBT_15				;branch if 12
	add	di, 2
	jmp	short PBT_20
PBT_15:
	;add 2 to di if unaligned
	;add 1 to di if aligned

	inc	di
	xor	byte ptr ds:[toggle], 1		;toggle aligned/unaligned bit
	jne	PBT_20				;branch if formerly aligned
	inc	di
PBT_20:
	;-----------------------------------------------------------------------
	;since we're on to a new cluster, we inspect the status of the
	; previous cluster and update the appropriate cluster count
	; accordingly.

	tst	ds:[clusterStat]
	jne	PBT_badClus
	inc	ds:[goodClusters]
	jmp	short PBT_resetStat
PBT_badClus:
	inc	ds:[badClusters]
PBT_resetStat:
	clr	ds:[clusterStat]
	
;	popf					;restore result of verify
	;-----------------------------------------------------------------------
	;store status

;	mov	ax, FAT_CLUSTER_UNUSED		;assume sector is ok
;	jnc	PBT_storeStatus			;branch if assumption correct
	mov	ax, FAT_CLUSTER_BAD
PBT_storeStatus:

	or	ds:[clusterStat], ax

	;1 bad sector in a cluster will result in all FAT bits for that cluster
	;being set. Subsequent good sectors in the cluster will not affect
	;the FAT entry

EC<	tst	bp							>
EC<	je	bpOK							>
EC<	cmp	bp, 1							>
EC<	ERROR_NZ FORMAT_ASSERTION_FAILED				>
EC< bpOK:								>

	tst	bp
	je	PBT_12Bit
	or	es:[di], ax			;mask in status
	jmp	short PBT_next
PBT_12Bit:
	test	byte ptr ds:[toggle], 1		;even or odd?
	jnz	PBT_do12BitOdd			;branch if odd

	;12 bit format - even
	and	ah, 0fh
	or	es:[di], ax
	jmp	short PBT_next
PBT_do12BitOdd:
	;12 bit format - odd
	push	cx
	mov	cl, 4
	shl	ax, cl
	pop	cx

	or	es:[di], al			;mask ls 4 bits into high nibble
	mov	es:[di+1], ah			;store ms 8 bits
PBT_next:
;	inc	cl				;next sector
	dec	bx				;done?
	je	PBT_done			;loop if not
	jmp	PBT_loop
PBT_done:
	pop	ax, bx, cx, dx, si
	ret
ProcessBadTrack	endp

endif	;***********************************************************************


COMMENT @-----------------------------------------------------------------------

FUNCTION:	WriteFATs

DESCRIPTION:	

CALLED BY:	INTERNAL (ProcessClusters)

PASS:		es - FAT work area

RETURN:		carry set on error
		ax - 0 if successful, FMT_ERR_WRITING_FAT if not

DESTROYED:	bx, cx, dx, bp, di, si, es

REGISTER/STACK USAGE:
	di - FAT count
	al - drive number
	cx - number of sectors to write
	dx - starting sector number
	ds:bx - addr of FAT work area

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@

WriteFATs	proc	near
	;init regs
	mov	al, ds:[mediaVars.BPB_numFATs]
	clr	ah
	mov	di, ax

	mov	al, ds:[drive]
	mov	cx, ds:[mediaVars.BPB_sectorsPerFAT]	;num sectors
	clr	bx
	mov	dx, ds:[startFAT]		;bx:dx = start sector
	segmov	ds, es, si			;ds:si <- FAT work area
	clr	si
WFAT_loop:
	call	DriveWriteSectors
	jc	WFAT_error

	add	dx, cx			;on to next FAT
	adc	bx, 0			; just in case...
	dec	di			;more FATs to write?
	jne	WFAT_loop		;branch if so
	clr	ax
	ret
WFAT_error:
	mov	ax, FMT_ERR_WRITING_FAT
	ret
WriteFATs	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ZeroSectorWorkArea

DESCRIPTION:	Zero out the sector work area.

CALLED BY:	INTERNAL (InitReservedArea, InitRootDirectory)

PASS:		es - seg addr of work area

RETURN:		work area initialized to 0

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@

ZeroSectorWorkArea	proc	near
	push	ax, cx, di
	clr	ax
	mov	di, ax
	mov	cx, MSDOS_STD_SECTOR_SIZE / 2
	cld
	rep	stosw
	pop	ax, cx, di
	ret
ZeroSectorWorkArea	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	WriteWorkArea

DESCRIPTION:	Writes the sector work area out to disk.

CALLED BY:	INTERNAL

PASS:		es - seg addr of sector work area
		cx - logical sector number
		ds - dgroup

RETURN:		ax - error code
		carry set on error

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	int 26h may destroy all registers save seg regs
	cpu flags remain on the stack so they must be popped off

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	7/89		Initial version

-------------------------------------------------------------------------------@

WriteWorkArea	proc	near
	uses	bx, cx, dx, si, ds
	.enter

	mov	al, ds:[drive]			;specify drive
	segmov	ds, es, si			;ds:si <- buffer
	clr	si
	clr	bx
	mov	dx, cx				;bx:dx = sector number
	mov	cx, 1				;specify num sectors
	call	DriveWriteSectors

	.leave
	mov	ds:[errCode], ax
	ret
WriteWorkArea	endp
