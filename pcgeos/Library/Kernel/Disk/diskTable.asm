COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Disk tracking -- Table Management
FILE:		diskTable.asm

AUTHOR:		Adam de Boor, Feb 19, 1990

ROUTINES:
	Name			Description
	----			-----------
	DiskTblSearch		Look for a handle by disk id and do something
				to it when it's found, returning the handle
				itself
	DiskTblSearchByName	Look for a handle by volume name and return it
	DiskTblAddEntry		Add a handle to the disk table
	DiskTblEnum		Enumerate all known disk volumes
	DiskTblEntryToFront	Callback routine for DiskTblSearch if entry
				should be brought to the front when it's been
				found
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/19/90		Initial revision


DESCRIPTION:
	Functions for manipulating/maintaining the disk handle table

REGISTER USAGE:
	ds - idata segment
	es - seg addr of table
	di - offset to a disk handle entry

	$Id: diskTable.asm,v 1.1 97/04/05 01:11:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskTblEntryToFront

DESCRIPTION:	Makes the given disk handle entry the first in the table.
		This has the benefit of reducing search times for often-used
		handles.

CALLED BY:	INTERNAL (DiskRegister via DiskTblSearch, DiskTblAddEntry)

PASS:		es - seg addr of table
		di - offset of handle to move to the front

RETURN:		di - offset to first entry where target now resides

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/89		Initial version

-------------------------------------------------------------------------------@

DiskTblEntryToFront	proc	near	uses cx, ds, si
	.enter
EC<	call	CheckTblAddr						>
EC<	call	CheckTblOffset						>
EC<	call	CheckTblStruct						>

	;-----------------------------------------------------------------------
	;Shift handles that precede target handle down.
	;Handles that follow target handle remain in place.

	mov	cx, di			;init num bytes to move
	sub	cx, DT_entries
	je	done		;done if target already the first entry

EC<	ERROR_S	DISK_ASSERTION_FAILED					>

EC<	test	cx, 1							>
EC<	ERROR_NZ	DISK_ASSERTION_FAILED				>

	segmov	ds, es
	push	ds:[di]			;save target handle
	lea	si, ds:[di-2]		;set up source to overwrite target

	shr	cx, 1			;convert to num words
	std				;get rep instr to decrement
	rep	movsw
	cld				;reset direction flag
	pop	ds:[di]			;put target at first entry location
done:
EC<	call	CheckTblAddr						>
EC<	call	CheckTblStruct						>
	.leave
	ret
DiskTblEntryToFront	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskTblAddEntry

DESCRIPTION:	Add the given disk handle to the disk-handle table.
		The disk handle is made the first entry as part of LRU
		maintenance.

		If the table runs out of space, more memory is
		allocated.

CALLED BY:	INTERNAL (DiskRegister)

PASS:		bx - disk handle

RETURN:		di - table offset to handle entry

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/89		Initial version

-------------------------------------------------------------------------------@


DiskTblAddEntry	proc	near	uses si, ax, cx, ds, es
	.enter
EC<	call	AssertDiskHandle					>

	;
	; Lock down the handle table
	;
	LoadVarSeg	ds
	mov	si, ds:diskTblHan

	xchg	bx, si
	call	NearLockES
	xchg	bx, si

	;
	; Make sure there's enough room in the table to hold this new entry.
	;
	mov	ax, es:[TH_size]
	mov	di, es:[TH_nextAvail]
	cmp	di, ax
	jb	enoughSpace

EC<	ERROR_NZ	BAD_DISK_HAN_TBL				>

	;
	; Not enough room. Enlarge the table by the requisite amount.
	;
	add	ax, DISK_TBL_NUM_INC * size hptr
	mov	es:[TH_size], ax
	xchg	bx, si
	mov	ch, mask HAF_ZERO_INIT or mask HAF_NO_ERR	
	call	MemReAlloc		; returns ax = segment since block
					;  already locked.
	mov	es, ax
	xchg	bx, si
enoughSpace:
	;
	; Store the handle at the end (easiest)
	;
	xchg	ax, bx
	stosw
	mov	es:[TH_nextAvail], di
	xchg	ax, bx			; (1-byte inst)
	;
	; Point di back at the handle's entry and move it to the front of
	; the whole thing.
	;
	dec	di
	dec	di
	call	DiskTblEntryToFront
EC<	call	CheckTblStruct						>

	xchg	bx, si
	call	NearUnlock
	xchg	bx, si
	.leave
	ret
DiskTblAddEntry	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskTblSearch

DESCRIPTION:	Searches the disk handle table to see if any of the
		disk handles contain the given disk identifier,
		optionally calling a routine in this file once the entry
		is found (usually DiskTblEntryToFront).

CALLED BY:	INTERNAL (DiskRegister)

PASS:		ds - idata seg
		dx:di - disk id
		ax - offset of routine to call if entry found (0 if none)

RETURN:		carry clear if successful:
		    bx - disk handle
		    di - offset from table to disk handle entry
		else
		    dx:di = disk id

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/89		Initial version

-------------------------------------------------------------------------------@

DiskTblSearch	proc	near	uses dx, si, bp, es
	.enter
EC<	call	AssertDSKdata						>
	push	ax		; save routine to call
	mov	bx, ds:diskTblHan
	call	NearLockES
EC<	call	CheckTblStruct						>

	andnf	dx, mask DIDH_ID_HIGH or mask DIDH_DRIVE;isolate disk id an
							; drive bits
	push	bx			; save table handle
	mov	bp, es:[TH_nextAvail]	; bp <- address for search termination
	mov	si, offset DT_entries
scanLoop:
	lodsw	es:			;fetch next handle and advance pointer
	cmp	bp, si			;hit the end?
	jb	notFound		;yes -- carry already set
	xchg	ax, bx			;bx <- handle (1-byte inst)
	cmp	di, ds:[bx].HD_idLow	; low bits match?
	jne	scanLoop
	mov	al, ds:[bx].HD_idHigh
	andnf	al, not mask DIDH_WRITABLE
	cmp	dl, al
	jne	scanLoop
	lea	di, [si-2]		;return entry in di. si has gone
					; beyond the one we want, however

notFound:
	pop	si			;recover table handle
	pop	ax			; and routine to call
	jc	unlock			;not found => don't call
	tst	ax
	jz	unlock			;0 => don't call
	call	ax			;call routine before unlocking
unlock:
	FastUnLock	ds, si, ax, NO_NULL_SEG
	.leave
	ret
DiskTblSearch	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskTblEnum

DESCRIPTION:	Enumerate all the entries for removable disks in the disk table
		into a single buffer of DiskEnumStrucs.

CALLED BY:	INTERNAL (DiskEnum)

PASS:		cx - number of entries available in DiskEnumStruct buffer
		es:di - addr of next available DiskEnumStruct entry
		ds - idata

RETURN:		bx - number of entries stored

DESTROYED:	ax, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@

DiskTblEnum	proc	near
	uses	ds, cx, si, ax, bp, di
	.enter
	;
	; Lock down the disk handle for our perusal
	;
	mov	bx, ds:diskTblHan
	call	NearLockDS

	push	bx				;save block handle

	;
	; Figure how many of the entries we've got will fit in the
	; caller's buffer.
	;
	mov	ax, ds:[TH_nextAvail]
	sub	ax, size TableHeader		;ax <- offset from nextAvail
	shr	ax
	sub	cx, ax
	jge	ok				;all will fit
	add	ax, cx				;reduce number to store to
						; match number that fit
ok:
	xchg	ax, cx				;(1-byte inst)
	clr	bp				; none processed yet
	jcxz	done				;weirdo

	mov	si, size TableHeader
processLoop:
	lodsw
	stosw					;DES_diskHandle
	xchg	ax, bx				;bx <- handle (1-byte inst)
	call	DiskGetDrive			;al <- drive number
	stosb					;DES_driveNum
	call	DriveGetStatus
	andnf	ah, mask DS_TYPE
	mov	al, ah
	stosb					;DES_driveType
	call	DiskHandleGetVolumeName
	add	di, size DES_volumeName
	clr	al
	stosb					;DES_flags
	inc	bp				;another one bites the dust
	loop	processLoop
done:
	pop	bx				;retrieve handle
	call	NearUnlock
	mov	bx, bp				;return number processed
	.leave
	ret
DiskTblEnum	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	DiskTblSearchByName

DESCRIPTION:	Tries to find a volume name match in a disk handle
		given a handle to a disk handle table.

CALLED BY:	INTERNAL (DiskVolumeNameGetDiskHandle)

PASS:		di - offset into table from which to start searching
		ds:si - null terminated volume name to match

RETURN:		carry clear if found
		    bx - handle found
		    di - offset into table beyond matching entry so another
		    	 call to this function to find the next match can
			 yield a resonable result

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@

DiskTblSearchByName	proc	near	uses ax,bp,es
	.enter
	push	ds
	LoadVarSeg	ds, bp			;bp <- idata
	mov	bx, ds:diskTblHan
	FastLock1	ds, bx, ax, DTSBN1, DTSBN2
	pop	ds

	mov	es, ax				;es <- seg addr of table
scanLoop:
	inc	di			; Advance past the entry
	inc	di
	cmp	es:[TH_nextAvail], di
	jb	done
	call	CheckVolumeNameMatch
	jc	scanLoop
done:
	push	es:[di-2]		; save the disk handle to return
	push	ds
	mov	ds, bp				;ds <- idata
	FastUnLock	ds, bx, ax, NO_NULL_SEG
	pop	ds
	pop	bx
	.leave
	ret

	FastLock2	ds, bx, ax, DTSBN1, DTSBN2
DiskTblSearchByName	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CheckVolumeNameMatch

DESCRIPTION:	Utility routine used by DiskTblSearchByName to compare the
		sought volume name against that for the handle, dealing with
		space-padding and so forth.

CALLED BY:	INTERNAL (DiskTblSearchByName)

PASS:		es:[di-2] - address containing disk handle
		ds:si - null-terminated string against which to compare it
		bp - idata seg

RETURN:		carry clear if match
		set if not

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@


CheckVolumeNameMatch	proc	near
	call	PushAll

	mov	di, es:[di-2]		;di <- disk handle
	mov	es, bp			;es <- idata
	add	di, HD_volumeLabel	;es:di <- volume name for this disk

	mov	cx, MSDOS_VOLUME_LABEL_LENGTH
	repe	cmpsb 
	je	done			; yup -- matched the whole way through
					;  (carry cleared by = comparison)
	tst	{byte}ds:[si-1]		; make sure source mismatched due to
					;  null-terminator
	jz	confirm			; yes -- go make sure rest is padding
noMatch:
	stc
done:
	call	PopAll
	ret
confirm:
	;
	; Make sure the rest of the chars in the disk handle's volumeLabel are
	; just padding spaces.
	;
	mov	al, ' '
	repe	scasb
	je	done			; made it to the end, so yes...
	jmp	noMatch
CheckVolumeNameMatch	endp
