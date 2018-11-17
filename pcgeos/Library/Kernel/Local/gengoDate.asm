COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		gengoDate.asm

AUTHOR:		Brian Chin, Nov 22, 1993

ROUTINES:
	Name				Description
	----				-----------
	GengoDateInit			Init for Gengo date format
	LocalFormatLongGengo		Format numeric year into long form
						of Gengo name
	LocalFormatShortGengo		Format numeric year into short form
						of Gengo name
	LocalGetLongGengo		Return year for long Gengo name
	LocalGetShortGengo		Return year for short Gengo name
	LocalAddGengoName		Add new Gengo name/date
	LocalRemoveGengoName		Remove Gengo name/date

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/22/93	Initial revision

DESCRIPTION:
	Routines for handling Gengo names.

	$Id: gengoDate.asm,v 1.1 97/04/05 01:16:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObscureInitExit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GengoNameInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	init for Gengo date format

CALLED BY:	LocalInit

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/23/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GengoNameInit	proc	far
	uses	ax, bx, cx, dx, si, di, ds, es, bp
	.enter
	;
	; read new Gengo names from .ini and add to GengoNameStrings
	; resource
	;
	segmov	ds, cs, cx			; ds:si = category
	mov	si, offset gengoNameCategory
	mov	dx, offset gengoNameKey		; cx:dx = key
	clr	bp				; return buffer, please
	call	InitFileReadData		; bx = buffer, cx = size
	jc	done				; error
	clr	dx
	mov	ax, cx				; dx.ax = size
	mov	cx, size GengoNameData
	div	cx				; ax = number of entries
	mov	cx, ax				; cx = number of entries
	call	MemLock
	push	bx
	mov	ds, ax
	mov	es, ax
	clr	si
nameLoop:
	push	si
	mov	ax, ds:[si].GND_year
	mov	bl, ds:[si].GND_month
	mov	bh, ds:[si].GND_date
	lea	di, ds:[si].GND_shortName
	lea	si, ds:[si].GND_longName
	call	AddGengoName			; ignore error
	pop	si
	add	si, size GengoNameData
	loop	nameLoop
	pop	bx
	call	MemFree
done:
	.leave
	ret
GengoNameInit	endp

gengoNameCategory	char	"localization",0
gengoNameKey		char	"gengoNames",0

ObscureInitExit	ends



Format	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalFormatLongGengo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	format passed year into long Gengo name

CALLED BY:	EXTERNAL

PASS:		es:di - buffer
		ax - year
		bl - month (1-12)
		bh - day (1-31)

RETURN:		es:di - points after null-terminated name
		ax - number of years since start of emperor's accession

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/22/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalFormatLongGengo	proc	far
	uses	dx
	.enter
	mov	dx, offset GND_longName		; offset to desired
	call	FormatGengoCommon
	.leave
	ret
LocalFormatLongGengo	endp

FormatGengoCommon	proc	near
	uses	bx, cx, si, bp, ds
	.enter
	mov	cx, ax				; cx = year
	push	bx				; save month, date
	mov	bx, handle GengoNameStrings
	call	MemLock
	pop	bx				; bl = month, bh = date
	mov	ds, ax
	mov	ax, -1				; will inc to 1st element
	mov	si, offset gengoData		; *ds:si = gengo data array
	push	di				; save dest offset
formatLoop:
	inc	ax				; next element
	call	ChunkArrayElementToPtr		; ds:di = element
	jc	usePrev				; no more elements
	cmp	cx, ds:[di].GND_year		; compare year
	jb	usePrev
	ja	formatLoop
	cmp	bl, {byte} ds:[di].GND_month	; compare month
	jb	usePrev
	ja	formatLoop
	cmp	bh, {byte} ds:[di].GND_date	; compare date
	ja	formatLoop
	je	haveEntry
	;
	; found entry after passed date, use previous entry
	;
usePrev:
	dec	ax				; previous element
	cmp	ax, -1
	jne	haveEntry
	mov	ax, 0				; use first one
haveEntry:
	call	ChunkArrayElementToPtr		; ds:di = element
	sub	cx, {word} ds:[di]		; cx = year difference
	inc	cx
	mov	si, di
	add	si, dx				; ds:si = desired name
	pop	di				; es:di = dest
	LocalCopyString
	mov_tr	ax, cx				; ax = year difference

	mov	bx, handle GengoNameStrings
	call	MemUnlock
	.leave
	ret
FormatGengoCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalFormatShortGengo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	format passed year into short Gengo name

CALLED BY:	EXTERNAL

PASS:		es:di - buffer
		ax - year
		bl - month (1-12)
		bh - day (1-31)

RETURN:		buffer filled
		ax - number of years since start of emperor's accession

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/22/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalFormatShortGengo	proc	far
	uses	dx
	.enter
	mov	dx, offset GND_shortName	; offset to desired
	call	FormatGengoCommon
	.leave
	ret
LocalFormatShortGengo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGetLongGengo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return year for long Gengo name

CALLED BY:	EXTERNAL

PASS:		es:di - pointer to string to parse

RETURN:		carry set if the token was parsed correctly
			es:di - pointer past parsed text
			bp - year of emperor's accession
			bl - month (1-12)
			bh - day (1-31)
			ax - year of next emperor's accession, if any
				9999 if none
		carry clear otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/24/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalGetLongGengo	proc	far
	uses	dx
	.enter
	mov	dx, offset GND_longName		; offset to desired
	call	GetGengoCommon
	.leave
	ret
LocalGetLongGengo	endp

GetGengoCommon	proc	near
	uses	cx, si, ds
	.enter
	mov	bx, handle GengoNameStrings
	call	MemLock
	mov	ds, ax
	mov	ax, -1				; will inc to 1st element
getLoop:
	inc	ax				; next element
	push	di				; save string to parse
	mov	si, offset gengoData		; *ds:si = gengo data array
	call	ChunkArrayElementToPtr		; ds:di = element
	mov	si, di				; ds:si = element
	pop	di				; es:di = string to parse
	cmc					; carry clear if no more
	jnc	done				; no more, not found (C clr)
	add	si, dx				; ds:si = long or short name
	pushdw	esdi
	segmov	es, ds				; es:di = long or short name
	mov	di, si
	call	LocalStringLength		; cx = length w/o null
	popdw	esdi
	call	LocalCmpStrings
	jne	getLoop				; no match, check next
	;
	; found match, return info
	;	cx = length to matching entry
	;	ax = element # of matching entry
	;
	sub	si, dx
	mov	bp, ds:[si].GND_year		; return year
updateLoop:
	LocalNextChar	esdi			; update pointer past match
	loop	updateLoop
	mov	cl, ds:[si].GND_month		; return month and date
	mov	ch, ds:[si].GND_date
	;
	; get next emperor's accession year, if any
	;	ax = element # of matching entry
	;
	inc	ax				; next element
	push	di				; save updated offset
	mov	si, offset gengoData		; *ds:si = gengo data array
	call	ChunkArrayElementToPtr		; ds:di = next element
	mov	si, di				; ds:si = next element
	pop	di				; es:di = updated offset
	mov	ax, 9999			; assume none
	jc	done				; no more elements, C set
	mov	ax, ds:[si].GND_year		; next emperor's year
	stc					; indicate found
done:
	mov	bx, handle GengoNameStrings
	call	MemUnlock			; preserves flags
	mov	bx, cx				; return month/date in BX
	.leave
	ret
GetGengoCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGetShortGengo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return year for short Gengo name

CALLED BY:	EXTERNAL

PASS:		es:di - pointer to string to parse

RETURN:		carry set if the token was parsed correctly
			es:di - pointer past parsed text
			bp - year of emperor's accession
			bl - month (1-12)
			bh - day (1-31)
			ax - year of next emperor's accession, if any
				9999 if none
		carry clear otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/24/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalGetShortGengo	proc	far
	uses	dx
	.enter
	mov	dx, offset GND_shortName	; offset to desired
	call	GetGengoCommon
	.leave
	ret
LocalGetShortGengo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalAddGengoName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add new Gengo name/date

CALLED BY:	GLOBAL

PASS:		ds:si - long Gengo name string (null-terminated)
				max of GENGO_LONG_NAME_LENGTH chars w/o null
		es:di - short Gengo name string (null-terminated)
				max of GENGO_SHORT_NAME_LENGTH chars w/o null
		ax - year
		bl - month (1-12)
		bh - day (1-31)

RETURN:		carry clear if successful
		carry set if passed date comes before an existing Gengo year
			or is same as an existing Gengo year

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/22/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalAddGengoName	proc	far
	;
	; update the GengoNameStrings resource
	;
	call	AddGengoName
	jc	done				; skip .ini update on error
	;
	; update the .ini file
	;
	call	UpdateGengoNameIniFile
	clc					; indicate no error
done:
	ret
LocalAddGengoName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddGengoName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add new Gengo name/date

CALLED BY:	GLOBAL

PASS:		ds:si - long Gengo name string (null-terminated)
				max of GENGO_LONG_NAME_LENGTH chars w/o null
		es:di - short Gengo name string (null-terminated)
				max of GENGO_SHORT_NAME_LENGTH chars w/o null
		ax - year
		bl - month (1-12)
		bh - day (1-31)

RETURN:		carry clear if successful
		carry set if passed date comes before an existing Gengo year
			or is same as an existing Gengo year

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/22/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddGengoName	proc	far
	uses	ax, bx, cx, dx, di, si, ds, es
longNameSeg	local	word	push	ds
longNameOff	local	word	push	si
shortNameSeg	local	word	push	es
shortNameOff	local	word	push	di
	.enter
	push	ax, bx				; save year, month/date
	mov	bx, handle GengoNameStrings
	call	MemLock
	mov	ds, ax
	mov	si, offset gengoData		; *ds:si = gengo data array
	call	ChunkArrayGetCount		; cx = number of elements
	dec	cx				; cx = last element #
	call	ChunkArrayElementToPtr		; ds:di = last element
	pop	dx, bx				; dx = year, bx = month/date
	cmp	dx, ds:[di].GND_year
	jb	done				; (carry set)
	ja	addEntry
	cmp	bl, ds:[di].GND_month
	jb	done				; (carry set)
	ja	addEntry
	cmp	bh, ds:[di].GND_date
	jb	done				; (carry set)
	stc					; assume error
	je	done				; same as existing date, error
addEntry:
	call	ChunkArrayAppend		; ds:di = new element
	mov	ds:[di].GND_year, dx
	mov	ds:[di].GND_month, bl
	mov	ds:[di].GND_date, bh
	segmov	es, ds				; es:di = GND_longName
	lea	di, ds:[di].GND_longName
	mov	ds, longNameSeg
	mov	si, longNameOff
	mov	cx, length GND_longName
	LocalCopyNString
	LocalPrevChar	esdi			; ensure null-terminated
	clr	ax
	LocalPutChar	esdi, ax
.assert (offset GND_shortName) eq ((offset GND_longName)+(size GND_longName))
	mov	ds, shortNameSeg
	mov	si, shortNameOff
	mov	cx, length GND_shortName
	LocalCopyNString
	LocalPrevChar	esdi			; ensure null-terminated
	clr	ax
	LocalPutChar	esdi, ax
done:
	mov	bx, handle GengoNameStrings
	call	MemUnlock			; (preserves flags)
	.leave
	ret
AddGengoName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateGengoNameIniFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update Gengo name info in .ini file

CALLED BY:	LocalAddGengoName

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/23/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateGengoNameIniFile	proc	near
	uses	ax, bx, cx, dx, bp, di, si, ds, es
	.enter
	;
	; allocate buffer to hold entries
	;
	mov	ax, size GengoNameData
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAllocFar
	mov	es, ax
	clr	di
	;
	; then loop through user-defined entries and copy them to buffer
	;
	push	bx				; save buffer handle
	mov	bx, handle GengoNameStrings
	call	MemLock
	pop	bx				; bx = buffer handle
	mov	ds, ax
	mov	ax, FIRST_USER_ELEMENT
updateLoop:
	push	di				; save dest offset
	mov	si, offset gengoData		; *ds:si = gengo data array
	call	ChunkArrayElementToPtr		; ds:di = element
	mov	si, di				; ds:si = element
	pop	di				; es:di = dest
	jc	updateDone
	push	ax				; save element #
	mov	cx, size GengoNameData
	rep movsb				; copy over
	mov	ax, di				; ax = current size
	add	ax, size GengoNameData		; make room for next one
	mov	ch, mask HAF_NO_ERR
	call	MemReAlloc
	mov	es, ax				; update segment
	pop	ax				; element #
	inc	ax				; next element
	jmp	updateLoop			; copy next one

updateDone:
	push	bx				; save buffer handle
	mov	bx, handle GengoNameStrings
	call	MemUnlock
	pop	bx				; bx = buffer handle
	;
	; write buffer to .ini file
	;	es:0 = buffer
	;	di = buffer size
	;	bx = buffer handle
	;
	mov	bp, di				; bp = buffer size
	clr	di				; es:di = buffer
	segmov	ds, cs, cx			; ds:si = category
	mov	si, offset updateGengoNameCategory
	mov	dx, offset updateGengoNameKey	; cx:dx = key
	call	InitFileWriteData
	call	MemFree				; free buffer
	.leave
	ret
UpdateGengoNameIniFile	endp

updateGengoNameCategory	char	"localization",0
updateGengoNameKey	char	"gengoNames",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalRemoveGengoName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	remove new Gengo name/date

CALLED BY:	GLOBAL

PASS:		ax - year
		bl - month (1-12)
		bh - day (1-31)

RETURN:		carry clear if successful
		carry set if Gengo name/date is pre-defined or not found
			ax = 0 if not found
			ax = -1 if trying to delete pre-defined

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalRemoveGengoName	proc	far
	uses	bx, cx, dx, si, ds
	.enter
	mov	cx, ax				; cx = year
	mov	dx, bx				; dx = month/day
	mov	bx, handle GengoNameStrings
	call	MemLock
	mov	ds, ax
	mov	ax, -1				; will inc to 1st element
	mov	si, offset gengoData		; *ds:si = gengo data array
removeLoop:
	inc	ax				; next element
	call	ChunkArrayElementToPtr		; ds:di = element
	jc	noMore				; not found, done (C set)
	cmp	cx, ds:[di].GND_year		; check year
	jne	removeLoop			; no match, check next
	cmp	dl, ds:[di].GND_month		; check month
	jne	removeLoop			; no match, check next
	cmp	dh, ds:[di].GND_date		; check day
	jne	removeLoop			; no match, check next
	;
	; found match, check if predefined
	;	ax = element number
	;
	cmp	ax, FIRST_USER_ELEMENT
	mov	ax, -1				; indicate predefined
	jb	done				; predefined, error (C set)
	;
	; not predefined, delete element
	;	*ds:si = chunk array
	;	ds:di = element
	;
	call	ChunkArrayDelete
	clc					; indicate no error
noMore:
	mov	ax, 0				; if error, indicate not found
done:
	mov	bx, handle GengoNameStrings
	call	MemUnlock			; preserves flags
	;
	; update .ini file
	;
	jc	exit				; error, nothing to update
	call	UpdateGengoNameIniFile
	clc					; indicate success
exit:
	.leave
	ret
LocalRemoveGengoName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalGetGengoInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get information about Gengo name/date entries

CALLED BY:	GLOBAL

PASS:		ax - gengo name entry #
		es:di - GengoNameData structure to return info

RETURN:		carry clear if successful
			es:di - GengoNameDate structure filled in
		carry set if no more Gengo name/date entries

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		To examine each Gengo name/date entry, call LocalGetGengoInfo
		in a loop, starting with ax=0 and incrementing ax by 1 each
		time until LocalGetGengoInfo returns carry set.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/18/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalGetGengoInfo	proc	far
	uses	ax, bx, cx, ds, si, di
	.enter
	push	ax				; save entry #
	mov	bx, handle GengoNameStrings
	call	MemLock
	mov	ds, ax
	pop	ax				; ax = entry #
	push	di				; save buffer offset
	mov	si, offset gengoData		; *ds:si = gengo data array
	call	ChunkArrayElementToPtr		; ds:di = element
	mov	si, di				; ds:si = element
	pop	di				; es:di = buffer
	jc	done				; not found, done (C set)
	mov	cx, size GengoNameData
	rep movsb
	clc					; indicate success
done:
	mov	bx, handle GengoNameStrings
	call	MemUnlock			; preserves flags
	.leave
	ret
LocalGetGengoInfo	endp

Format	ends

;--------------------------------------------------------------------------

GengoNameStrings	segment lmem	LMEM_TYPE_GENERAL

DefaultGengoData	struct
	DGD_header	ChunkArrayHeader
	DGD_meiji	GengoNameData
	DGD_taisyo	GengoNameData
	DGD_showa	GengoNameData
	DGD_heisei	GengoNameData
DefaultGengoData	ends

gengoData chunk.DefaultGengoData <
		<4, (size GengoNameData), 0, (size ChunkArrayHeader)>,
		<1868, 1, 1, <0x660e, 0x6cbb, 0>, <'M', 0>>,
		<1912, 7, 30, <0x5927, 0x6b63, 0>, <'T', 0>>,
		<1926, 12, 25, <0x662d, 0x548c, 0>, <'S', 0>>,
		<1989, 1, 8, <0x5e73, 0x6210, 0>, <'H', 0>>>
FIRST_USER_ELEMENT equ 4

GengoNameStrings	ends
