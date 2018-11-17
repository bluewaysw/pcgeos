COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Disk copy module
FILE:		diskcopyHigh.asm

AUTHOR:		Cheng, 10/89

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial revision

DESCRIPTION:
		
	$Id: diskcopyHigh.asm,v 1.1 97/04/05 01:18:14 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @-----------------------------------------------------------------------

Overview of strategy:
	Disk copies can only be done on compatible floppy disks.  The copy
	is done sector for sector (ie a sector on the source disk will
	be copied to the same sector on the destination disk). An
	alternative would be to reorganize the links in the FAT but that
	is considerably more work. The disk copy will fail if the destination
	disk has a bad sector in a location where the source disk has a good
	sector.

	Success if:
		(source sector is good) && (dest sector is good)
		(source sector is bad) && (dest sector is good)
		(source sector is bad) && (dest sector is bad)
	Failure if:
		(source sector is good) && (dest sector is bad)

Overview of implementation:
	Our primary goal is to have as few disk swaps as possible.  We
	therefore need as large a buffer space as we can get.  However, the
	heap limits buffer sizes to 64K so to get around this, we
	allocate several buffers for use.  This makes access a little
	cumbersome but that's the price we need to pay.

	Only a fixed number of buffers are used to put some bound on the code.
	An optimum starategy for minimizing disk swaps would have required
	an unbounded (almost) number of blocks but catering for this
	possibility seems unnecessarily complicated.

	A single cluster is read in at a time and we note the status of the
	'Read' in the Cluster Status Table.  When the buffers are full, we
	switch to Write mode.  Based on the status of the cluster, we
	either attempt a write or skip the write altogether, depending on
	whether or not the cluster was good.  No write is attemptedf if
	the cluster is bad. If the write fails, the disk copy operation
	is deemed a failure.

Main routines:
	Read cluster:
	Read a cluster from disk and store in in the buffer.
	Store status in the Cluster Status Table.


Glossary:
	buffer block table:
	The buffer block table is an array of buffer block table entries.
	The table holds the segment addresses and handles of the buffers
	used for the disk copy.

	buffer block table entry:
	A record that contains the segment address of the locked buffer block
	and the handle to the buffer.

	cluster status block:
	An array of bytes, 1 per cluster for each cluster in a buffer block,
	that tells if the corresponding cluster is GOOD (-1=good, 0=bad).

Special features:
	For copies on single disks, we compute the number of disk swaps
	that will be required and we inform the user.  He then has the
	option of continuing or aborting the operation if he feels intimidated.

Register usage:
	es - dgroup
	es:di - buffer block table entry
	ds:bx - buffer

ToDo ?
	Currently, the copy operation will abort if the destination disk
	is unformatted.  We cannot deal with this unless we resort to relying
	on DOS being v3.2 or greater (the IOCTL functions to get the media
	type are present then).
	
-------------------------------------------------------------------------------@


DiskcopyModule segment resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskCopy

DESCRIPTION:	Copies the contents of the source disk to the destination disk,
		prompting  for them as necessary.

CALLED BY:	GLOBAL

PASS:		dh - source drive (0 based drive number)
		dl - destination drive (0 based drive number)
		cx:bp - callback routine

RETURN:		ax - error code
		     0 if successful
		     ERR_DISKCOPY_INSUFFICIENT_MEM
		     ERR_CANT_COPY_FIXED_DISKS
		     ERR_CANT_READ_FROM_SOURCE
		     ERR_CANT_WRITE_TO_DEST
		     FMT_ERR_WRITE_PROTECTED
		     ERR_INCOMPATIBLE_FORMATS
		     ERR_OPERATION_CANCELLED

DESTROYED:	nothing

	Interface for callback function:

	CALLBACK_GET_SOURCE_DISK
		passed:
			ax - CALLBACK_GET_SOURCE_DISK
			dl - 0 based drive number
		callback routine to return:
			ax = 0 to continue, non-0 to abort


	CALLBACK_REPORT_NUM_SWAPS
		passed:
			ax - CALLBACK_REPORT_NUM_SWAPS
			dx - number of swaps required
		callback routine to return:
			ax = 0 to continue, non-0 to abort


	CALLBACK_GET_DEST_DISK
		passed:
			ax - CALLBACK_GET_DEST_DISK
			dl - 0 based drive number
		callback routine to return:
			ax = 0 to continue, non-0 to abort


	CALLBACK_VERIFY_DEST_DESTRUCTION
		passed:
			ax - CALLBACK_REPORT_NUM_SWAPS
			bx - disk handle of destination disk
			dl - 0 based drive number
			ds:si - name of destination disk
		callback routine to return:
			ax = 0 to continue, non-0 to abort


	CALLBACK_REPORT_FORMAT_PCT
		passed:
			ax - CALLBACK_REPORT_FORMAT_PCT
			dx - percentage of destination disk formatted
		callback routine to return:
			ax = 0 to continue, non-0 to abort

	CALLBACK_REPORT_COPY_PCT
		passed:
			ax - CALLBACK_REPORT_COPY_PCT
			dx - percentage of destination disk written
		callback routine to return:
			ax = 0 to continue, non-0 to abort

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if formats are compatible then
	    allocate buffer (some multiple of 1 sector)
	    for all blocks on disk
		read source (takes care of bringing disk in)
		write dest (takes care of bringing disk in)
	    end for
	endif

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version

-------------------------------------------------------------------------------@

DiskCopy	proc	far	uses bx, cx, dx, si, di, es, ds
	.enter
	call	FilePushDir
	mov	di, dgroup
	mov	es, di			;es <- dgroup
	PSem	es, copySem

	mov	es:[sourceDrive], dh	;save source drive
	mov	es:[destDrive], dl	;save destination drive
	mov	es:[statusCallback].segment, cx
	mov	es:[statusCallback].offset, bp
	clr	es:[srcCurSector]	;initialize tracking var
	clr	es:[destCurSector]	;initialize tracking var

	clr	es:[oneDriveCopy]	;1 drive copy flag <- FALSE
	cmp	dh, dl
	jne	10$
	dec	es:[oneDriveCopy]	;1 drive copy flag <- TRUE
10$:

	call	AllocBufBlks		;es:di <- bufBlkTbl
	jc	error			;error if error

	call	CheckFormats		;are formats compatible?
	jc	error			;branch if not

copyLoop:
	call	ReadSource
	jc	error

	push	ax			;save completion flag
	call	WriteDest
	jc	writeError

	pop	ax			;retrieve completion flag
	tst	ax			;completed?
	je	copyLoop		;loop if not

	;change volume name
	LoadVarSeg	ds
	mov	bx, es:[destDiskHan]
	mov	si, bx
	add	si, offset HD_volumeLabel
	mov	dl, es:[destDrive]
	call	DiskFileSetVolumeName
	jmp	short done

writeError:
	inc	sp			;clear stack of completion flag
	inc	sp
error:
done:
	call	FreeBufBlks

	VSem	es, copySem
	call	FilePopDir
	.leave
	ret
DiskCopy	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CheckFormats

DESCRIPTION:	Checks to see that the source and destination disk formats
		are the compatible. Verifies destruction of destination
		disk if it is formatted. Formats destination disk if necessary
		(either the destination is unformatted or the media
		is compatible but different).

CALLED BY:	INTERNAL (DiskCopy)

PASS:		es - dgroup
		es:[sourceDrive]
		es:[destDrive]

RETURN:		carry clear if successful
			ax = 0
			es:[numSectors]
		else carry set,
			ax = ERR_CANT_READ_FROM_SOURCE
			     ERR_CANT_COPY_FIXED_DISKS
			     ERR_INCOMPATIBLE_FORMATS
			     ERR_OPERATION_CANCELLED
			     ERR_CANT_FORMAT_DEST

DESTROYED:	bx,cx,bp,di,si,ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version

-------------------------------------------------------------------------------@

CheckFormats	proc	near
EC<	call	DCCheckESDGroup						>

	clr	es:[destFormatRequired]		;assume no format required
	mov	es:[destFormatted], -1		;assume formatted

	mov	al, es:[sourceDrive]
	clr	dh				;specify source disk
	call	GetMediaCharacteristics
	jc	exitJMP				;ax = error code

	mov	es:[sourceMedia], ah
	mov	es:[sourceClusterSize], al
	mov	es:[sourceDiskHan], bx
	mov	es:[sourceNumSectors], cx
	mov	es:[numSectors], cx
	mov	es:[sourceFATSize], cx
	mov	es:[sourceSectorSize], cx

	call	NotifyNumSwaps
	jc	exitJMP

	mov	al, es:[destDrive]
	mov	dh, -1				;specify destination disk
	call	GetMediaCharacteristics

	mov	es:[destMedia], ah
	mov	es:[destDiskHan], bx
	jnc	checkMedia

	cmp	ax, ERR_OPERATION_CANCELLED
	stc
	jne	destUnformatted
exitJMP:
	jmp	exit

destUnformatted:
	;-----------------------------------------------------------------------
	;destination disk is unformatted

	mov	es:[destFormatRequired], -1
	clr	es:[destFormatted]
	jmp	short doFormat

checkMedia:
	;-----------------------------------------------------------------------
	;can't copy if either disk is fixed

	cmp	al, MEDIA_FIXED_DISK		;is dest a fixed disk?
	je	usingFixed

	cmp	bl, MEDIA_FIXED_DISK		;is source a fixed disk?
	jne	notFixed

usingFixed:
	mov	ax, ERR_CANT_COPY_FIXED_DISKS
	jmp	short error

notFixed:
	;-----------------------------------------------------------------------
	;see if they are compatible

	mov	ah, es:[destMedia]		;ah <- destination media
	mov	al, es:[sourceDrive]		;al <- source drive
	call	DriveTestMediaSupport		;compatible?
	jnc	ok

	mov	ax, ERR_INCOMPATIBLE_FORMATS
	jmp	short error

ok:
	cmp	ah, es:[sourceMedia]		;source and dest same media?
	je	noFormat			;no format required

	mov	es:[destFormatRequired], -1

noFormat:
	;-----------------------------------------------------------------------
	;if destination is formatted, then verify destruction

	cmp	es:[destFormatted], 0
	je	noVerification

	mov	bx, es:[destDiskHan]
	mov	di, offset destName
	call	DiskHandleGetVolumeName		;es:di <- volume name
	segmov	ds,es
	mov	si, di

	mov	dl, es:[destDrive]		; (also pass bx = disk handle)
	mov	ax, CALLBACK_VERIFY_DEST_DESTRUCTION
	call	DC_CallStatusCallback

	tst	ax				;proceed?
	mov	ax, ERR_OPERATION_CANCELLED
	jne	error				;branch if not


noVerification:
	;-----------------------------------------------------------------------
	;if format required, then format destination

	cmp	es:[destFormatRequired], 0
	je	done

doFormat:
	mov	al, es:[sourceMedia]
	call	FormatDestination
	jc	exit

	mov	al, es:[destDrive]
;	call	DiskRegisterDiskWithoutInformingUserOfAssociation
;	mov	es:[destDiskHan], bx
	jmp	short exit
done:
	clr	ax
	jmp	short exit
error:
	stc
exit:
	ret
CheckFormats	endp

DC_CallStatusCallback	proc	near
	mov	ss:[TPD_dataAX], ax
	mov	ss:[TPD_dataBX], bx
	mov	ax, es:[statusCallback].offset
	mov	bx, es:[statusCallback].segment
	call	ProcCallFixedOrMovable
	ret
DC_CallStatusCallback	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetMediaCharacteristics

DESCRIPTION:	

CALLED BY:	INTERNAL (CheckFormats)

PASS:		es - dgroup
		al - 0 based drive number
		dh - 0 for source disk, non-zero for destination

RETURN:		carry clear if successful
			ah - GEOS media descriptor
			al - cluster size
			bx - disk handle
			cx - number of sectors on disk
			dx - number of sectors per FAT
			di - number of bytes per sector
			si - first FAT sector (logical)
		else, carry set
			ax = error code
			     ERR_OPERATION_CANCELLED
			     ERR_CANT_READ_FROM_SOURCE

DESTROYED:	ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version

-------------------------------------------------------------------------------@

GetMediaCharacteristics	proc	near	uses	dx
	.enter
EC<	call	DCCheckESDGroup						>
EC<	push	dx							>
EC<	mov	dl, al							>
EC<	call	DCCheckValidDrive					>
EC<	pop	dx							>

	push	ax
	mov	dl, al
	call	PromptForDisk			;ax <- error, destroys di,si,ds
	pop	bx				;clear stack in case we need to
						; exit, ax = error code
	jc	quit

	mov	ax, bx
	call	DiskRegisterDiskWithoutInformingUserOfAssociation
	push	bx				;save disk handle

	push	ax				;restore drive to stack
	mov	ax, MSDOS_STD_SECTOR_SIZE
	mov	cx, HAF_STANDARD_LOCK shl 8
	call	MemAllocFar
	mov	ds, ax
	pop	ax				;retrieve drive number
	jc	exit

	push	bx				;save mem handle
	push	ax				;save drive number

	clr	si				;ds:si <- buffer
	mov	cx, 1				;specify read 1 sector
	clr	bx
	mov	dx, bx				;specify boot sector
	call	MyReadSectors
	jc	error

	;-----------------------------------------------------------------------
	;assert valid disk

	;
	; Check the jump instruction at the start of the sector. It must
	; contain one of three things:
	;	- a near jump (three bytes) [XXX: check target of jump?]
	;	- a short jump (two bytes) followed by a NOP
	;	- all zeroes
	;
	clr	bx
	mov	ax, {word}ds:[bx].BS_jumpInstr
	cmp	al, JMP_INTRA_SEG
	je	diskValid

	mov	cl, 90h			; check for NOP as third...
	cmp	al, JMP_SHORT
	je	checkThirdByte

	clr	cl			; third byte must be zero
	tst	ax			; first two be zero?
	jnz	error			; no => it be an error

checkThirdByte:
	cmp	ds:[bx].BS_jumpInstr[2], cl
	jne	error

diskValid:
	;-----------------------------------------------------------------------
	;retrieve params from BPB

	pop	ax
	push	bx
	mov	cx, ds:[bx].BS_bpbSectorsPerTrack
	mov	bl, ds:[bx].BS_bpbMediaDescriptor
	call	MapDosMediaToGEOSMedia
	mov	ah, cl
	pop	bx

	mov	al, ds:[bx].BS_bpbClusterSize	;al <- sectors per cluster
	mov	cx, ds:[bx].BS_bpbNumSectors	;cx <- number of sectors
	mov	dx, ds:[bx].BS_bpbFATSize	;dx <- sectors per FAT
	mov	di, ds:[bx].BS_bpbSectorSize	;di <- bytes per sector
	mov	si, ds:[bx].BS_bpbNumReserved	;si <- first FAT sector
	clc
	jmp	short done

error:
	pop	ax
	stc
done:
	pop	bx				;retrieve mem handle
	pushf
	call	MemFree
	popf
	jnc	exit
	mov	ax, ERR_CANT_READ_FROM_SOURCE
exit:
	pop	bx				;retrieve disk handle
quit:
	.leave
	ret
GetMediaCharacteristics	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MapDosMediaToGEOSMedia

DESCRIPTION:	Returns the GEOS media descriptor that corresponds to
		the given DOS media descriptor.

CALLED BY:	INTERNAL (DriveBuildBPB, DriveFetchDeviceParams)

PASS:		cx - sectors per track
		bl - DOS media descriptor (bh zero)

RETURN:		cl - GEOS media descriptor

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

MapDosMediaToGEOSMedia	proc	near
	push	bx

	;-----------------------------------------------------------------------
	;handle exception to near-consecutiveness

	cmp	bl, DOS_MEDIA_1M44
	jne	notF0

	;-----------------------------------------------------------------------
	;3.5" 1.44Mb

	mov	bl, MEDIA_1M44
	jmp	done

notF0:
	and	bl, 07h

	;-----------------------------------------------------------------------
	;valid values in bl are now 0 (fixed), 1 (720K/1.2M), 4 (180K),
	;5 (360K), 6 (160K) and 7 (320K)

	mov	bl, cs:[bx][mediaConvTable]

	cmp	bl, MEDIA_1M2	;handle non-unique exception
	jne	done

	;-----------------------------------------------------------------------
	;DOS media byte 0f9h is shared by the 5.25" 1.2Mb media and
	;the 3.5" 720Kb. We use the number of sectors per track in
	;the BPB to distinguish between the two.

	cmp	cx, 15		; 1.2 Mb format?
	je	done
	mov	bl, MEDIA_720K
done:
	mov	cl, bl		; return in CL
	pop	bx
	ret
MapDosMediaToGEOSMedia	endp

mediaConvTable	label	byte
	db	MEDIA_FIXED_DISK
	db	MEDIA_1M2	;this offset is also valid for 720Kb
	db	0
	db	0
	db	MEDIA_180K
	db	MEDIA_360K
	db	MEDIA_160K
	db	MEDIA_320K



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatDestination

DESCRIPTION:	

CALLED BY:	INTERNAL (CheckFormats)

PASS:		al - media to format disk to

RETURN:		carry clear if successful
		    ax = 0
		else carry set,
		    ax = ERR_CANT_FORMAT_DEST

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial version

-------------------------------------------------------------------------------@

FormatDestination	proc	near	uses	dx
	.enter
	mov	ah, es:[destDrive]
	mov	cx, cs
	mov	dx, offset FormatDoCallback
	mov	bp, CALLBACK_WITH_PCT_DONE
	mov	di, offset nullTerm	;no volume name
	call	DiskFormat

;	mov	ax, ERR_CANT_FORMAT_DEST	;return format error
	jc	exit

	; get a disk handle for the sucker now that it's formatted.
	mov	al, es:[destDrive]
	call	DiskRegisterDiskWithoutInformingUserOfAssociation
	mov	es:[destDiskHan], bx

	clr	ax
exit:
	.leave
	ret
FormatDestination	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FormatDoCallback

DESCRIPTION:	

CALLED BY:	INTERNAL (DiskFormat::DC_CallStatusCallback)

PASS:		ax - percentage

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial version

-------------------------------------------------------------------------------@

FormatDoCallback	proc	far
	uses	ax, dx, ds
	.enter
	mov	dx, ax
	mov	ax, dgroup
	mov	ds, ax
	mov	ax, CALLBACK_REPORT_FORMAT_PCT
	call	DC_CallStatusCallback

	tst	ax
	clc
	je	done
	stc
done:
	.leave
	ret
FormatDoCallback	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	AllocBufBlks

DESCRIPTION:	Initializes the buffer block table.

CALLED BY:	INTERNAL (DiskCopy)

PASS:		es - dgroup

RETURN:		carry clear if successful
		ax = error code
			0 if successful
			ERR_DISKCOPY_INSUFFICIENT_MEM

DESTROYED:	nothing

REGISTER/STACK USAGE:
	cx - count
	es:di - ptr to current BufBlkTblEntry

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version

-------------------------------------------------------------------------------@

AllocBufBlks	proc	near
EC<	call	DCCheckESDGroup						>

	;-----------------------------------------------------------------------
	;loop to fill in entries

	mov	cx, NUM_BUF_BLKS
	mov	es:numBufBlks, cx
	mov	di, offset dgroup:[bufBlkTbl]
allocLoop:
	push	cx			;save count
	mov	ax, 2*1024		;fixed at 32K till MemInfoHeap works

	;-----------------------------------------------------------------------
	;leave some mem for rest of PC/GEOS

	cmp	ax, MIN_MEM_THRESHOLD
	jbe	done

	test	ax, 0f000h		;any bits in ms nibble?
	jne	justAlloc64K

	;-----------------------------------------------------------------------
	;allocate byte size

	mov	cl, 5			;bits to shift right to get num sectors
	shr	ax, cl
	jne	doAlloc
popAndFinish:
	pop	cx			;recover count
	jmp	done			; and get out of loop

justAlloc64K:
	;-----------------------------------------------------------------------
	;allocate as much mem as MemAlloc will allow (currently fff0h)

	mov	ax, (64*2) - 1			;(num sectors in 64K) - 1

doAlloc:
	;-----------------------------------------------------------------------
	;ax = sectors to allocate

	mov	es:[di][BBTE_sizeInSectors], ax
	mov	ah, al				;= shl ax, 9
	shl	ax, 1

	mov	cx, HAF_STANDARD shl 8
	call	MemAllocFar
	jc	popAndFinish

	mov	es:[di][BBTE_memHan], bx	;save mem handle
	add	di, size BufBlkTblEntry		;on to next entry
	pop	cx				;retrieve count
	loop	allocLoop
done:
	;-----------------------------------------------------------------------
	;check that everything was allocated (cx should be zero if so)

	clr	ax			; Assume no error
	sub	es:numBufBlks, cx
	jne	exit			; Allocated at least 1 block, so copy
					;  can proceed.

	mov	ax, ERR_DISKCOPY_INSUFFICIENT_MEM
	stc
exit:
	ret
AllocBufBlks	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	NotifyNumSwaps

DESCRIPTION:	Inform the user as to the number of disk swaps required
		and allow him to continue or quit.

CALLED BY:	INTERNAL (DiskCopy)

PASS:		es - dgroup
		es:[numSectors]
		es:[bufBlkTbl]

RETURN:		carry set if copy should abort

DESTROYED:	ax,bx,cx,dx,di,si,bp,ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	extend to allow the user to abort the diskcopy operation

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version

-------------------------------------------------------------------------------@

NotifyNumSwaps	proc	near
EC<	call	DCCheckESDGroup						>

	mov	cl, es:[sourceDrive]		; don't report num swaps if
	cmp	cl, es:[destDrive]		;	different drives
	clc					; (in case diff. drives)
	jne	done				; yes, different drives
						;	(carry clear)

	mov	cx, es:numBufBlks
	mov	di, offset dgroup:[bufBlkTbl]
	clr	bx				;use ax to count num sectors
notifyLoop:
	add	bx, es:[di][BBTE_sizeInSectors]
	add	di, size BufBlkTblEntry
	loop	notifyLoop

	clr	dx
	mov	ax, es:[numSectors]
	div	bx

	tst	dx				;any remainder?
	je	noRem				;branch if not
	inc	ax				;else 1 more swap required
noRem:
	mov	dx, ax
	inc	dx				;account for source and
						; destination prep

	mov	ax, CALLBACK_REPORT_NUM_SWAPS
	call	DC_CallStatusCallback

	tst	ax
	clc
	je	done

	mov	ax, ERR_OPERATION_CANCELLED
	stc
done:
	ret

if	0	;code prior to callback stuff
	clr	ax
	clr	cx				;no leading 0s, don't null term
	mov	di, offset dgroup:[notifyStr2]	; 
	cmp	ax, 9999
	ja	many
	mov	es:[di], " " shl 8 or " "
	mov	es:[di+2], " " shl 8 or " "
	call	UtilHex32ToAscii

notify:
	segmov	ds, es, ax
	mov	ax, mask SNF_CONTINUE or mask SNF_ABORT
	mov	si, offset dgroup:[notifyStr1]
	mov	di, offset dgroup:[notifyStr2]
	call	SysNotify
	test	ax, mask SNF_CONTINUE
	jnz	ok
	stc					;signal abort requested
	mov	ax, ERR_OPERATION_CANCELLED
ok:
	ret
many:
	mov	es:[di], 'a' shl 8 or 'm'
	mov	es:[di+2], 'y' shl 8 or 'n'
	jmp	notify
endif
NotifyNumSwaps	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ReadSource

DESCRIPTION:	Prompts for the source disk if we're doing a 1 drive copy
		and reads as much as we can into the buffers.

CALLED BY:	INTERNAL (DiskCopy)

PASS:		es - dgroup

RETURN:		carry clear if successful
			ax - completion flag, TRUE if last sector has been read
		else carrry set
			ax - ERR_CANT_READ_FROM_SOURCE

DESTROYED:	bx,cx,dx,di,si,bp,ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	switch to source disk
	if 1 drive copy then
		prompt for source disk
	endif
	read sectors into buffer blocks

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version

-------------------------------------------------------------------------------@

ReadSource	proc	near
EC<	call	DCCheckESDGroup						>

;	mov	bx, FML_DOS
;	call	FileGrabSystem
;	mov	ah, MSDOS_SET_DEFAULT_DRIVE
	mov	dl, es:[sourceDrive]
;	call	FileInt21

	tst	es:[oneDriveCopy]
	je	noPrompt

	clr	dh			;specify source disk
	call	PromptForDisk		;destroys ax,di,si,ds
	jc	exitNoUnlock

noPrompt:
	;
	; Lock down the drive and make sure the right disk is really there
	;
	mov	bx, es:[sourceDiskHan]
	call	DiskValidateFar

	;-----------------------------------------------------------------------
	;loop to fill all buffers

	mov	cx, es:numBufBlks
	mov	bx, offset dgroup:[bufBlkTbl]
readLoop:
	push	bx, cx
	mov	al, es:[sourceDrive]

	;-----------------------------------------------------------------------
	;figure out num sectors to read

	mov	cx, es:[bx][BBTE_sizeInSectors]
	cmp	cx, es:[numSectors]
	jbe	sizeOK
	mov	cx, es:[numSectors]
sizeOK:
	push	cx			;save num sectors that will be read

	mov	dx, es:[srcCurSector]
	mov	bx, es:[bx][BBTE_memHan]
	push	ax			; save drive
	call	MemLock
	mov	ds, ax
	pop	ax			; retreive drive
	push	bx			; save handle
	clr	bx
	mov	si, bx
	call	MyReadSectors
	pop	bx			; retrieve handle
	call	MemUnlock		; (preserves flags)
	jc	readError

	pop	dx			;get sectors read
	pop	bx, cx
	;-----------------------------------------------------------------------
	;update tracking vars

	mov	es:[bx][BBTE_sectorsUsed], dx
	add	bx, size BufBlkTblEntry	;point at next entry
	add	es:[srcCurSector], dx

	sub	es:[numSectors], dx	;num sectors left
	je	done
EC<	ERROR_B	DISKCOPY_ASSERTION_FAILED				>
	loop	readLoop

	;-----------------------------------------------------------------------
	;done reading - buffer has run out of space
	clr	ax			;flag <- F, sectors remain
exit:
;	mov	bx, FML_DOS		;release DOS/BIOS
;	call	FileReleaseSystem

	mov	bx, es:[sourceDiskHan]
	call	DiskUnlockFar
exitNoUnlock:
	ret

done:
	dec	cx			; skip the buffer we just filled
	;-----------------------------------------------------------------------
	;done reading - last sector has been read
	;clear remaining buffers

	jcxz	afterClear		; no extra buffers to clear
clrBufs:
	clr	ax
	mov	es:[bx][BBTE_sectorsUsed], ax
	add	bx, size BufBlkTblEntry	;point at next entry
	loop	clrBufs
afterClear:

	mov	ax, TRUE
	clc
	jmp	exit

	;-----------------------------------------------------------------------
	;read failed
readError:
	add	sp, 6			;clear stack
	mov	ax, ERR_CANT_READ_FROM_SOURCE
	stc
	jmp	exit
ReadSource	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	WriteDest

DESCRIPTION:	Prompts for the destination disk if we're doing a 1 drive copy
		and writes out as much as was read in.

CALLED BY:	INTERNAL (DiskCopy)

PASS:		es - dgroup

RETURN:		carry clear if successful
			ax = 0
		else carry set
			ax = ERR_CANT_WRITE_TO_DEST
			     FMT_ERR_WRITE_PROTECTED

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	switch to dest disk
	if 1 drive copy then
		prompt for destination disk
	endif
	write sectors out from buffer blocks

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version

-------------------------------------------------------------------------------@

WriteDest	proc	near
EC<	call	DCCheckESDGroup						>

;	mov	bx, FML_DOS
;	call	FileGrabSystem
;	mov	ah, MSDOS_SET_DEFAULT_DRIVE
	mov	dl, es:[destDrive]
;	call	FileInt21

	tst	es:[oneDriveCopy]
	je	noPrompt

	mov	dh, 1
	call	PromptForDisk
	jc	exitNoUnlock

noPrompt:
	mov	bx, es:[destDiskHan]
	call	DiskValidateFar

	;-----------------------------------------------------------------------
	;loop to empty all buffers

	mov	cx, es:numBufBlks
	mov	bx, offset dgroup:[bufBlkTbl]
writeLoop:
	push	bx, cx
	mov	al, es:[destDrive]
	mov	cx, es:[bx][BBTE_sectorsUsed]

	push	cx
	jcxz	noSectors			; no sectors in this buffer

	mov	dx, es:[destCurSector]
	mov	bx, es:[bx][BBTE_memHan]
	push	ax				; save drive
	call	MemLock
	mov	ds, ax
	pop	ax				; restore drive
	push	bx				; save handle
	clr	bx
	mov	si, bx
	call	MyWriteSectors
	pop	bx				; retrieve handle
	call	MemUnlock			; (preserves flags)
	jc	writeError

	call	WriteReportStatus	;ax <- error code, carry flag
	jc	writeError

noSectors:
	pop	dx
	pop	bx, cx

	;-----------------------------------------------------------------------
	;update tracking vars

	add	bx, size BufBlkTblEntry	;point at next entry
	add	es:[destCurSector], dx
	loop	writeLoop

	;-----------------------------------------------------------------------
	;if boot sector was written out, reregister disk

exit:
;	pushf
;	mov	bx, FML_DOS
;	call	FileReleaseSystem
;	popf
	mov	bx, es:[destDiskHan]
	call	DiskUnlockFar
exitNoUnlock:
	ret
	;*** exit ***

writeError:
	add	sp, 6
	cmp	ax, ERR_OPERATION_CANCELLED	; allow this to pass through
	je	20$
	cmp	ax, ERROR_WRITE_PROTECTED
	jne	10$
	mov	ax, FMT_ERR_WRITE_PROTECTED
	jmp	short 20$
10$:
	mov	ax, ERR_CANT_WRITE_TO_DEST
20$:
	stc
	jmp	short exit
WriteDest	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	WriteReportStatus

DESCRIPTION:	

CALLED BY:	INTERNAL (WriteDest)

PASS:		es - dgroup

RETURN:		ax - status code
		    0 if OK, carry on (carry flag clear)
		    ERR_OPERATION_CANCELLED if CANCEL, abort (carry flag set)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial version

-------------------------------------------------------------------------------@

WriteReportStatus	proc	near	uses	bx,dx
	.enter
	mov	bx, es:[destCurSector]
	mov	ax, 100
	mul	bx			;dx:ax <- destCurSector * 100
	mov	bx, es:[sourceNumSectors]
	div	bx			;ax <- percentage of disk copied

	mov	dx, ax
	mov	ax, CALLBACK_REPORT_COPY_PCT
	call	DC_CallStatusCallback

	tst	ax
	clc
	je	exit

	mov     ax, ERR_OPERATION_CANCELLED
	stc
exit:
	.leave
	ret
WriteReportStatus	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	PromptForDisk

DESCRIPTION:	Ask the user for the specified disk.

CALLED BY:	INTERNAL (ReadSource, WriteDest)

PASS:		es - dgroup
		dh - 0 for source disk, non-zero for destination
		dl - 0 based drive number

RETURN:		carry set if abort requested

DESTROYED:	ax,di,si,ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version

-------------------------------------------------------------------------------@

PromptForDisk	proc	near
EC<	call	DCCheckESDGroup						>

	mov	ax, CALLBACK_GET_SOURCE_DISK	;assume source disk
	tst	dh
	je	doCallback
	mov	ax, CALLBACK_GET_DEST_DISK	;modify if assumption wrong
doCallback:
	call	DC_CallStatusCallback

	tst	ax				;check return status
	je	done

	mov     ax, ERR_OPERATION_CANCELLED
	stc
done:
	ret

if	0	;code prior to callback stuff **********************************
	mov	si, offset dgroup:[promptSourceStr]	;assume source disk
	tst	dh					;test assumption
	je	str1ok				;branch if right
	mov	si, offset dgroup:[promptDestStr]	;else modify

str1ok:
EC<	call	DCCheckValidDrive					>
	add	dl, 'A'
	mov	es:[promptDrive], dl

	mov	di, offset dgroup:[promptDriveStr]

	segmov	ds, es, ax
	mov	ax, mask SNF_CONTINUE or mask SNF_ABORT
	call	SysNotify
	test	ax, mask SNF_CONTINUE	; Continue?
	jnz	ok
	stc				; Abort requested -- get out with error
	mov	ax, ERR_OPERATION_CANCELLED	; code set right
ok:
	ret
endif		;***************************************************************
PromptForDisk	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FreeBufBlks

DESCRIPTION:	Frees all buffers taken up.

CALLED BY:	INTERNAL (DiskCopy)

PASS:		es - dgroup

RETURN:		

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	for all buffer block table entry handles
		call MemFree
	end for

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/89		Initial version

-------------------------------------------------------------------------------@

FreeBufBlks	proc	near
	pushf				;save flags
	push	ax			;save error code

EC<	call	DCCheckESDGroup						>

	mov	cx, es:numBufBlks
	mov	di, offset dgroup:[bufBlkTbl]
	clr	ax			;used to zero-init tbl
freeLoop:
	mov	bx, es:[di][BBTE_memHan]
	call	MemFree

	push	cx
	mov	cx, size BufBlkTblEntry / 2
	rep	stosw
	pop	cx

	loop	freeLoop
	pop	ax
	popf
	ret
FreeBufBlks	endp



MyReadSectors	proc	near
	call	ResetDiskSystem
	call	DriveReadSectors
	ret
MyReadSectors	endp


MyWriteSectors	proc	near
	call	ResetDiskSystem

	tst	dx
	jne	doWrite

	;
	; Writing the boot sector of the destination, so change it to contain
	; the ID already assigned to the disk. Also alter the volume name of
	; the destination disk handle to match the volume name of the source
	; with a twiddle added to the end, to differentiate it from the source.
	;

	;ds:si = buffer

	push	ax,bx,cx,es,di

	mov	di, es:[destDiskHan]
	push	es:[sourceDiskHan]
	LoadVarSeg	es
	
	; Figure where in the buffer to store the proper ID number. If boot
	; sector is extended, ID goes in BS_volumeID, else we put it in the
	; oemNameAndVersion field
	mov	bx, offset BS_oemNameAndVersion
	cmp     ds:[si].BS_extendedBootSig, EXTENDED_BOOT_SIGNATURE
	jne     copyID
	mov	bx, offset BS_volumeID
copyID:

	; Copy the ID to the proper location.
	mov	ax, es:[di].HD_idLow
	mov	ds:[si+bx], ax
	mov	al, es:[di].HD_idHigh
	mov	ds:[si+bx+2], ax

	; Copy the volume name from the source handle to the destination
	XchgTopStack	si		; si <- source handle, save buffer
	
	add	si, offset HD_volumeLabel
	add	di, offset HD_volumeLabel
	mov	cx, size HD_volumeLabel

	.ioenable
	cli			; Avoid death on < 80186 due to double-prefix
	rep	movsb	es:
	sti

	pop	si		; si <- buffer offset

	; Find the last space in the volume name and replace it with a twiddle.
	; If no space in the name, just replace the last character. To make
	; certain the name's unique, skip over any trailing twiddles as well.

	dec	di
	std
	mov	cx, size HD_volumeLabel
	mov	al, ' '
	repe	scasb

	inc	di
	inc	cx
	mov	al, '~'
	repe	scasb
	mov	es:[di+1], al	; XXX: what if name is all twiddles?
	cld

	pop	ax, bx, cx, es, di

doWrite:
	call	DriveWriteSectors

	ret
MyWriteSectors	endp



ResetDiskSystem	proc	near
	ret
if	0
	push	ax,bx
	mov	bx, FML_DOS
	call	FileGrabSystem
	mov	ah, 0dh
	int	21h
	mov	bx, FML_DOS
	call	FileReleaseSystem
	pop	ax,bx
	ret
endif
ResetDiskSystem	endp

DiskcopyModule ends
