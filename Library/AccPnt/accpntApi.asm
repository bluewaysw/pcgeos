COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	socket
MODULE:		access point database
FILE:		accpntApi.asm

AUTHOR:		Eric Weber, Apr 24, 1995

ROUTINES:
	Name			Description
	----			-----------
    GLB AccessPointCreateEntry  Create an access point

    GLB AccessPointDestroyEntry Destroy an access point

    GLB AccessPointDestroyEntryNoNotify
    GLB AccessPointMultiDestroyDone

    GLB AccessPointGetType      Get the access point type

    GLB AccessPointSetStringProperty 
				Set a string property on an access point

    GLB AccessPointSetIntegerProperty 
				Set a integer property on an access point

    GLB AccessPointGetStringProperty 
				Get a string property on an access point

    GLB AccessPointGetIntegerProperty 
				Get a integer property on an access point

    GLB AccessPointDestroyProperty 
				Destroy one property of an access point

    GLB AccessPointGetEntries   Get a chunk array of entry IDs of a given
				type

    INT GetEntriesCallback      Possibly copy an access point from one
				array to another

    GLB AccessPointCompareStandardProperty
				Compare a string to a standard property name

    GLB	AccessPointCommit	Forces changes to disk

    GLB AccessPointIsEntryValid	Test whether an access point exists

    GLB AccessPointLock		Lock an access point to prevent changes

    GLB AccessPointUnlock	Unlock an access point

    INT AccessPointCheckLock	Check if an access point is locked


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/24/95   	Initial revision
	jwu	10/25/96	Added locking access points

DESCRIPTION:
	
		
	$Id: accpntApi.asm,v 1.17 97/10/22 13:19:16 brianc Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Strings	segment	lmem LMEM_TYPE_GENERAL
	accpntCategory	chunk.char "accpnt",0
			localize not
	activeKey	chunk.char "active0",0
			localize not
Strings	ends

ApiCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointCreateEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an access point

CALLED BY:	GLOBAL
PASS:		bx	- ID of entry before which to insert new entry
			 (0 to place at end)
		ax	- AccessPointType
RETURN:		ax	- new ID
		carry set if old entry not found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointCreateEntry	proc	far
		uses	bx,cx,dx,si,di,bp,ds
		.enter
		push	bx, ax
		EnterDatabase bx
		Assert	etype	ax, AccessPointType
	;
	; read the last assigned key value from the database
	;
		segmov	ds, cs
		mov	si, offset initCategory
		mov	cx, cs
		mov	dx, offset initIDKey
		call	InitFileReadInteger	; ax=value, carry on err
		jnc	nextValue
		clr	ax
	;
	; increment the value
	; if we reach 65536, wrap around, but skip over zero
	;
nextValue:
		inc	ax
		jnz	noZ
		inc	ax		; don't use zero
noZ:
		call	CheckIfEntryExists	; carry if does not exist
		jnc	nextValue
	;
	; this is the value we want to use
	;
valueOK::
		pop	bx, dx				; position, type
		call	AllocateEntry			; carry on err
		jc	done
		call	GenerateCreationNotice
	;
	; note that we've used this ID
	;
		mov	bp, ax
		mov	dx, offset initIDKey
		call	InitFileWriteInteger		; carry on err
EC <		ERROR_C UNABLE_TO_ALLOCATE_ENTRY_POINT			>
	;
	; commit the changes
	;
		AccpntCommit
		clc
done:
		ExitDatabase bx
		.leave
		ret
AccessPointCreateEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointDestroyEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy an access point

CALLED BY:	GLOBAL
PASS:		ax	- id of access point to destroy
RETURN:		carry	- set if access point does not exist or is locked
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointDestroyEntry		proc	far
		uses	ax,dx
		.enter
		call	GetTypeLow
		call	AccessPointGetActivePoint
		call	AccessPointDestroyEntryDirect
		.leave
		ret
AccessPointDestroyEntry	endp
		
AccessPointDestroyEntryDirect	proc	far
		uses	ax,bx,cx,dx,si,ds,es
		.enter

		EnterDatabase bx
	;
	; make sure changes are allowed
	;
		call	AccessPointCheckLock
		jc	done			; locked!
	;
	; remove access point from table of contents
	;
		call	FreeEntryFile		; remove from init file
		jc	done
		call	FreeEntryMem		; dx = entry type
		call	BuildEntryCategory	; get category name
	;
	; remove it's category, and hence all of its properties
	;
		call	InitFileDeleteCategory
		call	GenerateDeletionNotice
		AccpntCommit
		clc
done:
		ExitDatabase	bx

		.leave
		ret
AccessPointDestroyEntryDirect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointDestroyEntryNoNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy an access point, but don't send out notifications.

CALLED BY:	AccessPointSelectorDeleteMulti

PASS:		ax	= id of access point to destroy

RETURN:		carry set if access point does not exist or is locked
		dx	= entry type

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/ 1/97			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointDestroyEntryNoNotify	proc	far
		uses	ax, bx, cx, si, ds, es
		.enter

		EnterDatabase bx
	;
	; make sure changes are allowed
	;
		call	AccessPointCheckLock
		jc	done			; locked!
	;
	; remove access point from table of contents
	;
		call	FreeEntryFile		; remove from init file
		jc	done
		call	FreeEntryMem		; dx = entry type
		call	BuildEntryCategory	; get category name
	;
	; remove it's category, and hence all of its properties
	;
		call	InitFileDeleteCategory
		AccpntCommit
		clc
done:
		ExitDatabase	bx

		.leave
		ret
AccessPointDestroyEntryNoNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointMultiDestroyDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send batched notification for group of deleted access
		points.

CALLED BY:	AccessPointSelectorDeleteMulti

PASS:		bx	= block of IDs
		dx	= entry type

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/ 1/97		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointMultiDestroyDone	proc	far
		uses	ax
		.enter

		mov	ax, bx
		call	GenerateMultiDeletionNotice

		.leave
		ret
AccessPointMultiDestroyDone	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointGetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the access point type

CALLED BY:	GLOBAL
PASS:		ax	- access point ID
RETURN:		bx	- AccessPointType (0 if not found)
		carry set if not found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointGetType	proc	far
		uses	ax,cx,dx,si,di,bp,ds
		.enter
		EnterDatabase	bx
		call	GetTypeLow	; dx = AccessPointType
		ExitDatabase bx
		mov	bx, dx
	;
	; set carry if bx=0
	;
		tst	bx
		lahf
		rcl	ah
		rcl	ah
		.leave
		ret
AccessPointGetType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointGetActivePoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the active point

CALLED BY:	GLOBAL
PASS:		ax	- access point ID
		dx	- type
RETURN:		ax	- the active accesspoint for the same type
		carry set if not found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mzhu	2/ 2/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointGetActivePoint	proc	far
		uses	bx,cx,dx,si,di,bp,ds,es
		.enter

		add	dx, 48	; '0' = 48

		push	ax
		segmov	es, ds, bx
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	cx, ax
		assume	ds:Strings
		mov	bp, ds:[activeKey]
		mov	ds:[bp+6], dx
		mov	dx, ds:[activeKey]		; cx:dx = key
		mov	si, ds:[accpntCategory]		; ds:si = category
		assume	ds:nothing
		pop	ax
		call	InitFileReadInteger		; ax = accpnt
		pushf

		mov	bx, handle Strings
		call	MemUnlock

		popf
		.leave
		ret
AccessPointGetActivePoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointSetActivePoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the active point for the type

CALLED BY:	GLOBAL
PASS:		ax	- access point
		dx	- type
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mzhu	2/ 2/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointSetActivePoint	proc	far
		uses	ax, bx,cx,dx,si,di,bp,ds,es
		.enter

		add	dx, 48	; '0' = 48

		push	ax
		segmov	es, ds, bx
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	cx, ax
		assume	ds:Strings
		mov	bp, ds:[activeKey]
		mov	ds:[bp+6], dx
		mov	dx, ds:[activeKey]		; cx:dx = key
		mov	si, ds:[accpntCategory]		; ds:si = category
		assume	ds:nothing
		pop	bp
		call	InitFileWriteInteger
		pushf

		mov	bx, handle Strings
		call	MemUnlock
		popf
		
		.leave
		ret
AccessPointSetActivePoint	endp


ifdef SCRAMBLED_INI_STRINGS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APCheckScrambledProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if this property is to be scrambled

CALLED BY:	INTERNAL
PASS:		cx:dx	- pointer to property name
				if cx = 0, dx = APSP_
RETURN:		carry set if scrambled
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/30/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APCheckScrambledProperty	proc	near
		jcxz	checkScrambled
notScrambled:
		clc				; only APSPs supported
		ret
		
checkScrambled:
		cmp	dx, APSP_SECRET
		jne	notScrambled		; not scrambled
		stc				; APSP_SECRET, scramble
		ret
APCheckScrambledProperty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APScramble, APUnscramble
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scramble and unscramble .ini string

CALLED BY:	INTERNAL
PASS:		es:di - ASCIIZ string
		cx - num chars, 0 for null-terminated
RETURN:		cx - length if 0 passed in, otherwise unchanged
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/30/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APScramble	proc	near
		uses	ax, ds, si, di
		.enter
		tst	cx
		jnz	haveLength
		call	LocalStringLength	; cx = length
haveLength:
		jcxz	done
		push	cx
		segmov	ds, es, si
		mov	si, di
scrambleLoop:
		LocalGetChar	ax, dssi
SBCS <		xor	al, 0xbc					>
DBCS <		xor	ax, 0xbcbc					>
		LocalPutChar	esdi, ax
		loop	scrambleLoop
		pop	cx
done:
		.leave
		ret
APScramble	endp

APUnscramble	equ	APScramble


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APScrambleAndInitFileWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scramble and write .ini string

CALLED BY:	INTERNAL
PASS:		ds:si - category ASCIIZ string
		cx:dx - key ASCIIZ string
		es:di - body ASCIIZ string
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/30/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APScrambleAndInitFileWrite	proc	near
		uses	bp
		.enter
	;
	; scramble data
	;
		push	cx
		clr	cx			; null-terminated
		call	APScramble
		mov	bp, cx			; bp = size for write data
DBCS <		shl	bp, 1						>
		pop	cx
	;
	; write scrambled string to .ini file
	;
		call	InitFileWriteData
	;
	; unscramble so user buffer is not altered
	;
		push	cx
		clr	cx			; null-terminated
		call	APScramble
		pop	cx
		.leave
		ret
APScrambleAndInitFileWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		APInitFileReadAndUnscramble
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read .ini string and unscramble

CALLED BY:	INTERNAL
PASS:		ds:si	- category ASCIIZ string
		cx:dx	- key ASCIIZ string
		bp	- size
				If size = 0	
					Buffer will be allocated for string
				Else
			    		es:di - buffer to fill

RETURN:		carry	- clear if successful 
		cx 	- number of chars retrieved (excluding null terminator)
			  cx = 0 if category / key not found

		bx	- mem handle to block containing entry (IFRF_SIZE = 0)
				- or -
		es:di	- buffer filled (IFRF_SIZE != 0)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/30/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
APInitFileReadAndUnscramble	proc	near
	;
	; read scrambled string from .ini file
	;
		call	InitFileReadData
	;
	; unscramble
	;
		jc	done			; error, return it
		tst	bp			; have buffer?
		jnz	haveBuffer
		push	ax, es, di
		call	MemLock
		mov	es, ax
		clr	di
haveBuffer:
DBCS <		shr	cx, 1			; bytes to chars	>
		call	APUnscramble		; pass cx = num chars
		tst	bp
		jnz	done
		call	MemUnlock
		pop	ax, es, di
		clc				; indicate success
done:
		ret
APInitFileReadAndUnscramble	endp

endif	; SCRAMBLED_INI_STRINGS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointSetStringProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a string property on an access point

CALLED BY:	GLOBAL
PASS:		ax	- access point id
		cx:dx	- null terminated property name
		es:di	- null terminated property value
RETURN:		carry set if access point does not exist or is locked
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointSetStringProperty	proc	far
		uses	ax,dx
		.enter
		mov	bx, dx
		call	GetTypeLow
		call	AccessPointGetActivePoint
		mov	dx, bx
		call	AccessPointSetStringPropertyDirect
		.leave
		ret
AccessPointSetStringProperty	endp
		
AccessPointSetStringPropertyDirect	proc	far
		uses	bx,cx,dx,ds,si
		.enter
		Assert	fptrXIP, esdi
		EnterDatabase	bx
		call	ValidateEntry
		jc	done
	;
	; Only allow change if accpnt not locked or if property is
	; automatic.
	;
		test	dx, APSP_AUTOMATIC
		jz	checkLock

		jcxz	continue
checkLock:
		call	AccessPointCheckLock	
		jc	done
continue:
	;
	; Set string property.
	;
ifdef SCRAMBLED_INI_STRINGS
		call	APCheckScrambledProperty
		pushf					; save result
endif
		call	ParseStandardProperty		; cx:dx=key, bx=APSP
		call	BuildEntryCategory		; ds:si = category
ifdef SCRAMBLED_INI_STRINGS
		popf					; C set if scrambled
		jnc	notScrambled
		call	APScrambleAndInitFileWrite
		jmp	afterWrite
notScrambled:
		call	InitFileWriteString
afterWrite:
else
		call	InitFileWriteString
endif
		AccpntCommit
		call	GenerateChangeNotice
		clc					; indicate success
done:
		ExitDatabase	bx
		.leave
		ret
AccessPointSetStringPropertyDirect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointSetIntegerProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a integer property on an access point

CALLED BY:	GLOBAL
PASS:		ax	- access point id
		cx:dx	- null terminated property name
		bp	- value to store
RETURN:		carry set if access point does not exist or is locked
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointSetIntegerProperty	proc	far
		uses	ax,dx
		.enter
		mov	bx, dx
		call	GetTypeLow
		call	AccessPointGetActivePoint
		mov	dx, bx
		call	AccessPointSetIntegerPropertyDirect
		.leave
		ret
AccessPointSetIntegerProperty	endp

AccessPointSetIntegerPropertyDirect	proc	far
		uses	bx,cx,dx,ds,si
		.enter
		EnterDatabase	bx
		call	ValidateEntry
		jc	done
	;
	; Only allow change if accpnt not locked or if property is 
	; automatic.
	;
		test	dx, APSP_AUTOMATIC
		jz	checkLock

		jcxz	continue
checkLock:
		call	AccessPointCheckLock
		jc	done
continue:
	;
	; Set integer property.
	;
		call	ParseStandardProperty		; cx:dx = key,
							; bx = APSP
		call	BuildEntryCategory		; ds:si = category
		call	InitFileWriteInteger
		AccpntCommit
		call	GenerateChangeNotice
		clc					; indicate success
done:
		ExitDatabase	bx
		.leave
		ret
AccessPointSetIntegerPropertyDirect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointGetStringProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a string property on an access point

CALLED BY:	GLOBAL
PASS:		ax	- access point id
		cx:dx	- null terminated property name
		bp	- size of buffer (0 to allocate block)
		es:di	- buffer for property value (if bp != 0)
RETURN:		carry set on error
		cx 	- number of chars retrieved (excluding null terminator)
			  cx = 0 if property not found

		bx	- mem handle to block containing entry
				- or -
		es:di	- buffer filled

DESTROYED:	bx (if not returned)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointGetStringProperty	proc	far
		uses	ax,dx
		.enter
		mov	bx, dx
		call	GetTypeLow
		call	AccessPointGetActivePoint
		mov	dx, bx
		call	AccessPointGetStringPropertyDirect
		.leave
		ret
AccessPointGetStringProperty	endp

AccessPointGetStringPropertyDirect	proc	far
		uses	dx,bp,si,ds
		.enter
		EnterDatabase	bx
EC <		call	ValidateEntry					>
EC <		jc	done						>
ifdef SCRAMBLED_INI_STRINGS
		call	APCheckScrambledProperty
		pushf					; save result
endif
		call	ParseStandardProperty		; cx:dx = key

		and	bp, mask IFRF_SIZE		; get low 12 bits
EC <		jz	ptrOK						>
EC <		Assert	fptrXIP, esdi					>
ptrOK::
		call	BuildEntryCategory		; ds:si = category
ifdef SCRAMBLED_INI_STRINGS
		popf					; C set if scrambled
		jnc	notScrambled
		call	APInitFileReadAndUnscramble
		jmp	afterRead
notScrambled:
		call	InitFileReadString
afterRead:
else
		call	InitFileReadString
endif
done::
		ExitDatabase
		.leave
		ret
AccessPointGetStringPropertyDirect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointGetIntegerProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a integer property on an access point

CALLED BY:	GLOBAL
PASS:		ax	- access point id
		cx:dx	- null terminated property name
RETURN:		carry set if error
		ax	- value of property (unchanged if error)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointGetIntegerProperty	proc	far
		uses	bx, dx
		.enter
		mov	bx, dx
		call	GetTypeLow
		call	AccessPointGetActivePoint
		mov	dx, bx
		call	AccessPointGetIntegerPropertyDirect
		.leave
		ret
AccessPointGetIntegerProperty	endp

AccessPointGetIntegerPropertyDirect	proc	far
		uses	bx,cx,dx,ds,si
		.enter
		EnterDatabase	bx
EC <		call	ValidateEntry					>
EC <		jc	done						>
		call	ParseStandardProperty		; cx:dx = key
		call	BuildEntryCategory		; ds:si = category
		call	InitFileReadInteger
done::
		ExitDatabase	bx
		.leave
		ret
AccessPointGetIntegerPropertyDirect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointDestroyProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy one property of an access point

CALLED BY:	GLOBAL
PASS:		ax	- access point id
		cx:dx	- null terminated property name
RETURN:		carry set if error (accpnt locked)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointDestroyProperty	proc	far
		uses	ax,dx
		.enter
		mov	bx, dx
		call	GetTypeLow
		call	AccessPointGetActivePoint
		mov	dx, bx
		call	AccessPointDestroyPropertyDirect
		.leave
		ret
AccessPointDestroyProperty	endp

AccessPointDestroyPropertyDirect	proc	far
		uses	bx,cx,dx,si,ds
		.enter
		EnterDatabase bx
EC <		call	ValidateEntry					>
EC <		jc	done						>

	;
	; Only allow change if accpnt not locked or if property is
	; automatic.  
	;
		test	dx, APSP_AUTOMATIC
		jz	checkLock		

		jcxz	change				
checkLock:
		call	AccessPointCheckLock
		jc	done
change:
	;
	; Delete the property.
	;
		call	ParseStandardProperty		; cx:dx = key
		call	BuildEntryCategory		; ds:si = category
		call	InitFileDeleteEntry
		AccpntCommit
		call	GenerateChangeNotice
		clc					; indicate success
done::
		ExitDatabase	bx
		.leave
		ret

AccessPointDestroyPropertyDirect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointGetEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a chunk array of entry IDs of a given type

CALLED BY:	GLOBAL
PASS:		ds	- segment in which to return data
		si	- chunk in which to return data (0 to create one)
		ax	- type of entries to list (APT_ALL for all types)
RETURN:		ds:si	- chunk array of entry ID words
			(ds may have moved)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	4/25/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointGetEntries	proc	far
		uses	ax,bx,cx,dx,di,bp,es
		.enter
		EnterDatabase	bx, SAVE_DS
EC <		cmp	ax, APT_ALL					>
EC <		je	aptOK						>
EC <		Assert	etype	ax, AccessPointType			>
aptOK::
EC <		Assert  segment, ds					>
EC <		tst	si						>
EC <		jz	chunkOK						>
EC <		Assert	chunk si,ds					>
chunkOK::
		mov	bp, ax			; remember type
	;		
	; create a chunk array in target block
	;
		mov	bx, size word		; element size
		clr	cx			; default header size
		clr	al			; no obj flags
		call	ChunkArrayCreate	; si = chunk
		push	si			; save chunk handle
		mov	cx, ds
		mov	dx, si			; *cx:dx = target array
	;
	; lock down the source block
	;
		mov	bx, handle AccessTypeArray
		call	MemLock
		mov	ds, ax
		mov	si, offset AccessTypeArray
	;
	; copy the chunk array
	;
		mov	bx, cs
		mov	di, offset GetEntriesCallback
		call	ChunkArrayEnum
	;
	; clean up and exit
	;
		mov	bx, handle AccessTypeArray
		call	MemUnlock		; release source block
		ExitDatabase	bx
		mov	ds, cx
		pop	si			; *ds:si = target array
		.leave
		ret
AccessPointGetEntries	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetEntriesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Possibly copy an access point from one array to another

CALLED BY:	AccessPointGetEntries (via ChunkArrayEnum)
PASS:		*ds:si	- AccessTypeArray
		ds:di	- current entry in AccessTypeArray
		*cx:dx	- target array
		bp	- desired type
RETURN:		*cx:dx	- target array (possibly moved)
		carry clear
DESTROYED:	ax, bx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetEntriesCallback	proc	far
		uses	ds
		.enter
	;
	; if type matches, copy it
	;
		cmp	bp, ds:[di]
		je	typeOK
	;
	; if bp is APT_ALL, copy it
	;
		cmp	bp, APT_ALL
		jne	done
	;
	; switch to AccessPointArray and read ID from same offset
	; we are at in AccessTypeArray
	;
typeOK:
		sub	di, ds:[si]
		mov	si, offset AccessPointArray
		add	di, ds:[si]
		mov	ax, ds:[di]
	;
	; store it in target array
	;
		mov	ds, cx
		mov	si, dx
		call	ChunkArrayAppend	; ds:di = new slot
		mov	ds:[di], ax
		mov	cx, ds			; save new segment value
done:
		clc
		.leave
		ret
GetEntriesCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointCompareStandardProperty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare a string to a standard property name

CALLED BY:	GLOBAL
PASS:		es:di		- null terminated string to match
		dx		- AccessPointStandardProperty
RETURN:		zero flag	- set if equal
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointCompareStandardProperty	proc	far
		uses	bx,cx,dx,si,di,ds
		.enter
		EnterDatabase	bx
		Assert	fptrXIP, esdi
	;
	; get the standard property name
	;
		clr	cx
		call	ParseStandardProperty	; cx:dx = property
		movdw	dssi, cxdx
	;
	; compare it to the passed value
	;
		clr	cx			; null terminated
		call	LocalCmpStringsNoCase	; z flag if equal

		ExitDatabase	bx
		.leave
		ret
AccessPointCompareStandardProperty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointCommit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force changes to disk

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	5/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointCommit	proc	far
		call	InitFileCommit
		ret
AccessPointCommit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointIsEntryValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test whether an access point exists

CALLED BY:	GLOBAL
PASS:		ax	- access point ID
RETURN:		carry set if invalid
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointIsEntryValid	proc	far
		uses	ax,dx
		.enter
		call	GetTypeLow
		call	AccessPointGetActivePoint
		call	AccessPointIsEntryValidDirect
		.leave
		ret
AccessPointIsEntryValid	endp

AccessPointIsEntryValidDirect	proc	far
		uses	bx, ds
		.enter
		EnterDatabase	bx
		call	ValidateEntry
		ExitDatabase
		.leave
		ret
AccessPointIsEntryValidDirect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock an access point.  Once an access point is locked,
		only the automatic settings for it may be modified.

CALLED BY:	GLOBAL

PASS:		ax	= access point ID

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Writes lock entry to ini for this accpnt.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/25/96		Initial version
	jwu	01/18/97		lock stored in memory

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointLock	proc	far
		uses	ax,dx
		.enter
		call	GetTypeLow
		call	AccessPointGetActivePoint
		call	AccessPointLockDirect
		.leave
		ret
AccessPointLock	endp

AccessPointLockDirect	proc	far
		uses	bx, cx, dx, di, si, ds, es
		.enter
	;
	; If access point is already locked, don't lock it again.
	;
		EnterDatabase	bx
EC <		call	ValidateEntry					>
EC <		jc	exit						>

		mov_tr	cx, ax				; cx = accpnt id
		mov	bx, handle AccessPointLockArray
		call	MemLock
		mov	ds, ax
		mov	es, ax
		mov	si, offset AccessPointLockArray	; *ds:si = array
		mov	di, ds:[si]
		mov	ax, es:[di].CAH_count
		add	di, es:[di].CAH_offset
		xchg	cx, ax				; ax = id, cx = count
		repne	scasw
		je	done				; already locked
	;
	; Add new lock to array and send a notification for it
	;
		call	ChunkArrayAppend
		mov	ds:[di], ax

		mov	dx, APT_INTERNET
		call	GenerateLockNotice
done:
		call	MemUnlock
exit:
		ExitDatabase	bx

		.leave
		ret
AccessPointLockDirect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock an access point.

CALLED BY:	GLOBAL

PASS:		ax	= access point ID

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Removes lock entry for this accpnt.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/25/96		Initial version
	jwu	01/18/97		lock stored in memory

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointUnlock	proc	far
		uses	ax,dx
		.enter
		call	GetTypeLow
		call	AccessPointGetActivePoint
		call	AccessPointUnlockDirect
		.leave
		ret
AccessPointUnlock	endp

AccessPointUnlockDirect	proc	far
		uses	bx, cx, dx, di, si, ds, es
		.enter
	;
	; Find access point in lock array.
	;
		EnterDatabase	bx
EC <		call	ValidateEntry					>
EC <		jc	exit						>

		mov_tr	cx, ax				; cx = accpnt id
		mov	bx, handle AccessPointLockArray
		call	MemLock
		mov	ds, ax
		mov	es, ax
		mov	si, offset AccessPointLockArray	; *ds:si = array
		mov	di, ds:[si]
		mov	ax, es:[di].CAH_count
		add	di, es:[di].CAH_offset
		xchg	cx, ax				; ax = id, cx = count
		repne	scasw
		jne	done
	;
	; Delete entry from lock array and send a notification for it
	;
		dec	di
		dec	di
		call	ChunkArrayDelete

		mov	dx, APT_INTERNET
		call	GenerateLockNotice
done:		
		call	MemUnlock
exit:
		ExitDatabase	bx

		.leave
		ret
AccessPointUnlockDirect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointCheckLock/AccessPointInUse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if an access point is locked.  If an access point
		is locked, only the automatic settings may be modified.

		Applications use AccessPointInUse which hides the concept
		of locked access points.

CALLED BY:	EXTERNAL		(AccessPointInUse)

		INTERNAL		(AccessPointCheckLock)
		AccessPointDestroyEntry
		AccessPointSetStringProperty
		AccessPointSetIntegerProperty
		AccessPointDestroyProperty

PASS:		ax	= access point ID

RETURN:		carry set if locked or in use

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOTE:  Do not call EnterDatabase here.  Caller already
			got exclusive access and calling it here will
			cause deadlock.


REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/25/96		Initial version
	jwu	01/18/97		locks stored in memory

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointInUse	proc	far
		uses	ax,dx
		.enter
		call	GetTypeLow
		call	AccessPointGetActivePoint
		call	AccessPointInUseDirect
		.leave
		ret
AccessPointInUse	endp

AccessPointInUseDirect	proc	far
		uses	bx
		.enter
		EnterDatabase	bx, SAVE_DS
EC <		call	ValidateEntry					>
EC <		jc	exit						>
		call	AccessPointCheckLock
exit:
		ExitDatabase	bx, SAVE_DS
		.leave
		ret
AccessPointInUseDirect	endp

AccessPointCheckLock	proc	near
		uses	bx, cx, di, si, es
		.enter
	;
	; Check if access point is in lock array.
	;
		mov_tr	cx, ax
		mov	bx, handle AccessPointLockArray
		call	MemLock
		mov	es, ax
		mov	di, offset AccessPointLockArray
		mov	di, es:[di]
		mov	ax, es:[di].CAH_count
		add	di, es:[di].CAH_offset
		xchg	cx, ax				; ax = id, cx = count
		repne	scasw				
		call	MemUnlock

		clc					; assume not locked 
		jne	exit				
		stc					; it's locked
exit:
		.leave
		ret
AccessPointCheckLock	endp

dialingAreaCodeKey	char	"areaCode",0
dialingCallWaitingKey	char	"callWaiting",0
dialingOutsideLineKey	char	"outsideLine",0
dialingDialMethodKey	char	"dialMethod",0
dialTenDigitKey		char	"tenDigit",0
dialtoneKey		char	"dialtone",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointGetDialingOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns dialing options from INI file.  If a key is not
		present in the INI file, NULL or a default value will
		be used.

CALLED BY:	EXTERNAL/GLOBAL
PASS:		cx:dx = fptr to AccessPointDialingOptions structure
			to be filled
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/03/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointGetDialingOptions	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter

	; Use es:[di] to point to current member of structure.
	; di will be moved from element to element at each step.
	;
		mov	es, cx
		mov	di, dx
		add	di, offset APDO_areaCode
		
	; Set up ds:si to point to category key.  Should stay the whole
	; routine.
	;
		segmov	ds, cs, cx
		mov	si, offset initCategory

	; Read the area code key.
	;
		mov	dx, offset dialingAreaCodeKey
		mov	{byte}es:[di], 0		; default value
		mov	bp, (size APDO_areaCode) and mask IFRF_SIZE
		call	InitFileReadString
		jc	checkCallWaiting		; unsuccessful
		cmp	cx, APDO_AREA_CODE_LEN		; must be 3 digits!
		je	checkCallWaiting
		mov	{TCHAR}es:[di], 0		; if not, null it!

checkCallWaiting:
	; Read the call waiting key.
	;
		add	di, offset APDO_callWaiting - offset APDO_areaCode
		mov	cx, cs
		mov	dx, offset dialingCallWaitingKey
		mov	bp, (size APDO_callWaiting) and mask IFRF_SIZE
		mov	{TCHAR}es:[di], 0		; default value
		call	InitFileReadString

	; Read the outside line key.
	;
		add	di, offset APDO_outsideLine - offset APDO_callWaiting
		mov	cx, cs
		mov	dx, offset dialingOutsideLineKey
		mov	bp, (size APDO_outsideLine) and mask IFRF_SIZE
		mov	{TCHAR}es:[di], 0		; default value
		call	InitFileReadString

	; Read the dialing method key.  Here we read the string key
	; onto the stack since the value in the struct is only a one
	; byte enumeration.  Happily, the value of the enum is either
	; 'T' or 'P', the value stored in the ini file.
	; 
		pushdw	esdi
		sub	sp, 2*(size TCHAR)
		mov	di, sp
		segmov	es, ss, cx
		mov	cx, cs
		mov	dx, offset dialingDialMethodKey
		mov	bp, 2
		mov	al, APDM_TONE			; default value
		call	InitFileReadString
		jc	useDefaultMethod		; not in INI file
		mov	ah, es:[di]
		cmp	ah, APDM_PULSE
		je	gotMethod
		cmp	ah, APDM_TONE
		jne	useDefaultMethod		; if not valid, use al
		
gotMethod:
		mov	al, ah
useDefaultMethod:
		add	sp, 2*(size TCHAR)
		popdw	esdi
		add	di, offset APDO_dialMethod - offset APDO_outsideLine
		mov	es:[di], al

	; Read boolean ten digit key.
	;
		add	di, offset APDO_tenDigit - offset APDO_dialMethod
		mov	cx, cs
		mov	dx, offset dialTenDigitKey
		mov	{byte}es:[di], FALSE		; default value
		call	InitFileReadBoolean
		jc	gotTenDigit			; no value, use def.
		mov	es:[di], al

gotTenDigit:

	; Read boolean dialtone key.
	;
		add	di, offset APDO_waitForDialtone - offset APDO_tenDigit
		mov	cx, cs
		mov	dx, offset dialtoneKey
		mov	{byte}es:[di], TRUE		; default value
		call	InitFileReadBoolean
		jc	gotDialtone			; no value, use def.
		mov	es:[di], al

gotDialtone:
	; Whew!
		.leave
		ret
AccessPointGetDialingOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointSetDialingOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets dialing options in INI file.

CALLED BY:	EXTERNAL/GLOBAL
PASS:		cx:dx = fptr to AccessPointDialingOptions structure
			to be written to INI file.  All string values
			must be null terminated.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/03/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccessPointSetDialingOptions	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
		
	; Use es:[di] to point to current member of structure.
	; di will be moved from element to element at each step.
	;
		mov	es, cx
		mov	di, dx
		add	di, offset APDO_areaCode

	; Set up ds:si to point to category key.  Should stay the whole
	; routine.
	;
		segmov	ds, cs, cx
		mov	si, offset initCategory

	; Write the area code key.
	;
		mov	dx, offset dialingAreaCodeKey
		call	InitFileWriteString

	; Write the call waiting key.
	;
		add	di, offset APDO_callWaiting - offset APDO_areaCode
		mov	cx, cs
		mov	dx, offset dialingCallWaitingKey
		call	InitFileWriteString

	; Write the outside line key.
	;
		add	di, offset APDO_outsideLine - offset APDO_callWaiting
		mov	cx, cs
		mov	dx, offset dialingOutsideLineKey
		call	InitFileWriteString

	; Write the dialing method key.  We just write out a string to
	; the file whose value is the enumeration value.  Those values should
	; be printable ascii characters.  To do this, we need to make a string
	; on the stack so that we have a zero byte.
	;
		add	di, offset APDO_dialMethod - offset APDO_outsideLine
		sub	sp, 2*(size TCHAR)
		mov	bp, sp
		mov	cl, es:[di]
		mov	ss:[bp], cl
		mov	{byte}ss:[bp+1], 0
DBCS <		mov	{word}ss:[bp+2], 0				>
		pushdw	esdi
		mov	di, bp
		segmov	es, ss, cx
		mov	cx, cs
		mov	dx, offset dialingDialMethodKey
		call	InitFileWriteString
		popdw	esdi
		add	sp, 2*(size TCHAR)

	; Write ten digit boolean key.
	;
		add	di, offset APDO_tenDigit - offset APDO_dialMethod
		clr	ax
		mov	al, es:[di]			; ax != 0 ==> TRUE
		mov	cx, cs
		mov	dx, offset dialTenDigitKey
		call	InitFileWriteBoolean

	; Write dialtone boolean key.
	;
		add	di, offset APDO_waitForDialtone - offset APDO_tenDigit
		clr	ax
		mov	al, es:[di]			; ax != 0 ==> TRUE
		mov	cx, cs
		mov	dx, offset dialtoneKey
		call	InitFileWriteBoolean

	; Write these suckers to the disk.
	;
		call	InitFileCommit

		.leave
		ret
AccessPointSetDialingOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccessPointGetPhoneStringWithOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the phone string (stored in APSP_PHONE) with
		dialing options applied for the currently set
		access point.  Options will only be applied
		if (1) they are set (may be in INI file) and (2) if
		APSP_USE_DIALING_OPTIONS is set non-zero for access point.
		If APSP_USE_DIALING_OPTIONS is not present, the routine
		will behave normally but no options will be applied
		(i.e., output will be equal to APSP_PHONE string).

CALLED BY:	EXTERNAL/GLOBAL
PASS:		ax = access point id
		bx = handle to block to receive string or
		     0 to have block allocated.
RETURN:		carry: set if APSP_PHONE is defined
		       clear if no PHONE is specified for access point.
		cx = length of phone string (excluding zero-byte)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Oh, string parsing and concatenation in ASM is SO MUCH
		FUN!  This was much shorter in C, really.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/03/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PREAMBLE_LEN equ 32

AccessPointGetPhoneStringWithOptions	proc	far
		uses	ax,dx,si,di,ds,es
accPntID		local	word		push ax
returnHan		local	hptr		push bx
origCX			local	word		push cx
phonePropHan		local	hptr
preamble		local	PREAMBLE_LEN dup (TCHAR)
areaCode		local	3 dup (TCHAR)
DBCS < areaCodeLen	local	byte			>
prefix			local	3 dup (TCHAR)
extension		local	4 dup (TCHAR)
dialOptions		local	AccessPointDialingOptions
localDialOptions	local	AccessPointLocalDialingOptions
		.enter
	
	; Get the phone number from the access point.  (AX was passed in
	; to be the access point ID.)
	;
		push	bp				; save locals
		clr	cx, bp
		mov	dx, APSP_PHONE
		call	AccessPointGetStringProperty	; bx = block, cx = len
		pop	bp				; restore locals
		cmc					; carry set = failure
	   LONG	jnc	done				; no phone, E.T., clc

		mov	ss:[phonePropHan], bx
		tst	ss:[returnHan]
		jnz	returnBlockAlloc

		mov	ax, 112*(size TCHAR)		; big enuf!
		mov	cx, ALLOC_DYNAMIC
		call	MemAlloc
	   LONG	jc	errorFreePropHan
		mov	ss:[returnHan], bx
		
returnBlockAlloc:
		mov	bx, ss:[phonePropHan]
		call	MemLock
	   LONG	jc	errorFreePropHan		; may leak memory
		mov	ds, ax
		clr	si

		mov	bx, ss:[returnHan]
		call	MemLock
	   LONG	jc	errorUnlockPropHan		; may leak memory
		mov	es, ax
		clr	di

	; ds:si = original phone number
	; es:di = return phone number
	;
	; At this point, check is APSP_USE_DIALING_OPTIONS is present for
	; this access point.
	;
		mov	ax, ss:[accPntID]		; can trash ax,cx,dx
		clr	cx
		mov	dx, APSP_USE_DIALING_OPTIONS
		call	AccessPointGetIntegerProperty
		jc	skipOptions
		tst	ax
		jnz	useOptions

skipOptions:
	; OK.. we are bailing but we need to copy the phone number to the
	; output string an proceed like a normal call.  To do that, we simply
	; need to advance ds:si to the end of the source string and pretend
	; we have "garbage".
	;
		LocalGetChar	ax, dssi		; rep scasb uses es:di.
		LocalIsNull	ax			; use lodsb loop instead
		jnz	skipOptions
		jmp	stuffIt

useOptions:
	; bl = numDigits
	; bh = garbageInString
	; cl = firstDigitIs1
	; ch = preambleLen
		clr	bx, cx

	; First time through, figure out how many actual digits we have
	; and some things about it.  Store a preamble, valid dial chars
	; before the first digits, just in case.
loop1:
		LocalGetChar	ax, dssi
		LocalIsNull	ax
		jz	doneLoop1

		inc	bh			; assume garbage, but digit
		LocalCmpChar	ax, '#'		; (which means # or *)
		je	haveDigit1
		LocalCmpChar	ax, '*'
		je	haveDigit1
		dec	bh			; unassume garbage
		LocalCmpChar	ax, '0'
		jb	noDigit1
		LocalCmpChar	ax, '9'
		ja	noDigit1

haveDigit1:
		tst	bl			; numDigits == 0
		jnz	alreadyHaveOneDigit1
		LocalCmpChar	ax, '1'		; first digit == 1
		jne	alreadyHaveOneDigit1
		inc	cl			; first digit is a 1.. note it

alreadyHaveOneDigit1:
		inc	bl			; inc count of digits
		jmp	loop1

noDigit1:
		LocalCmpChar	ax, '-'		; check for useless (,),- chars
		je	loop1			; they aren't garbage, fluff
		LocalCmpChar	ax, '('
		je	loop1
		LocalCmpChar	ax, ')'
		je	loop1
		tst	bl			; numDigits ==0 ?
		jnz	garbageLoop1		; nope - no preamble, garbage
		cmp	ch, PREAMBLE_LEN	; preambleLen < PREAMBLE_LEN
		jae	garbageLoop1		; nope - garbage
		push	bx			; stuff in preamble
		lea	bx, ss:[preamble]
		add	bl, ch
DBCS <		adc	bh, 0						>
DBCS <		add	bl, ch			; size TCHAR		>
		adc	bh, 0
		LocalPutChar	ssbx, ax, noAdvance
		pop	bx
		inc	ch			; preambleLen++
		jmp	loop1			; no garbage

garbageLoop1:
		inc	bh			; yup, garbage
		jmp	loop1

doneLoop1:
	; Get the dialing options (in local variable).. we need to, no matter
	; what, stuff the 'T' or 'P' in the output string.   (We may bail below
	; by stuffing the input string to the output string; however, we still
	; would like the T or P present.)
	;
		push	cx
		mov	cx, ss
		lea	dx, ss:[dialOptions]	; dx unused so far
		call	AccessPointGetDialingOptions
		pop	cx

	; Also get the local dialing options for this access point.
	;
		push	ax, cx, dx
		clr	ss:[localDialOptions]	; by default, options are off
		mov	ax, ss:[accPntID]		; can trash ax,cx,dx
		clr	cx
		mov	dx, APSP_LOCAL_DIALING_OPTIONS
		call	AccessPointGetIntegerProperty
		jc	skipLocalOptions
		mov	ss:[localDialOptions], ax
skipLocalOptions:
		pop	ax, cx, dx

	; Write dial method ('T' or 'P') out first.
	;
		mov	al, ss:[dialOptions].APDO_dialMethod
DBCS <		clr	ah						>
		LocalPutChar	esdi, ax

	; At this point, we can figure out if we are going to just stuff the
	; string out as it came in because we have garbage or unparse-able
	; stuff.
		tst	bh			; garbageInString
		jnz	stuffIt
		tst	cl			; first digit is 1 ?
		jnz	stuffItFDI1
		cmp	bl, 7			; first dig not 1.. 7 or 10 digs
		je	pressOn			; get to pass GO.
		cmp	bl, 10
		je	pressOn
stuffIt:
		mov	cx, si			; cx=si = num chars in string
		clr	si			; since ds:0 is byte 0
		LocalCopyNString		; includes null terminator>
		jmp	doneSuccess

stuffItFDI1:
		cmp	bl, 11			; first dig is 1.. do we have
		jne	stuffIt			; 11 digits? If not, garbage!

pressOn:
	; ds:si = original phone number
	; es:di = return phone number
	; bl = numDigits
	; bh = numDigits2 (for second loop)  (was garbage counter.. must be 0)
	; cl = firstDigitIs1
	; ch = preambleLen
	; ah = areaCodeLen
	; dl = prefixLen
	; dh = extLen
EC <		tst	bh						>
EC <		ERROR_NZ -1						>
		clr	dx, si
SBCS <		clr	ah						>
DBCS <		clr	ss:[areaCodeLen]				>

	; This time through, we parse out area code, prefix, and extension.
	; Oh, this is fun in ASM!
loop2:
		LocalGetChar	ax, dssi
		LocalIsNull	ax
		jz	doneLoop2

		LocalCmpChar	ax, '0'			; isdigit?
		jb	loop2
		LocalCmpChar	ax, '9'
		ja	loop2

		tst	bh			; first digit this loop?
		jnz	notFirst2
		tst	cl			; first digit should be 1?
		jz	notFirst2
EC <		LocalCmpChar	ax, '1'						>
EC <		ERROR_NE -1						>
		clr	cl			; clear firstDigit and
						; don't count this digit
		jmp	loop2

notFirst2:
		cmp	bl, 10			; do we have 10 digits?
		jb	tryPrefix2
SBCS <		cmp	ah, 2			; are seeing the first 3 still?>
DBCS <		cmp	ss:[areaCodeLen], 2	; are seeing the first 3 still?>
		ja	tryPrefix2
		push	bx			; yes.. write area code.
		lea	bx, ss:[areaCode]
SBCS <		add	bl, ah						>
DBCS <		add	bl, ss:[areaCodeLen]				>
DBCS <		adc	bh, 0						>
DBCS <		add	bl, ss:[areaCodeLen]	; TCHAR size		>
		adc	bh, 0
		LocalPutChar	ssbx, ax, noAdvance
		pop	bx
SBCS <		inc	ah			; ++areaCodeLen		>
DBCS <		inc	ss:[areaCodeLen]	; ++areaCodeLen		>
incloop2:
		inc	bh			; ++numDigits2
		jmp	loop2

tryPrefix2:
		cmp	dl, 2			; do we have 3 prefix yet?
		ja	tryExt2
		push	bx			; no.. write in prefix.
		lea	bx, ss:[prefix]
		add	bl, dl
DBCS <		adc	bh, 0						>
DBCS <		add	bl, dl			; TCHAR size		>
		adc	bh, 0
		LocalPutChar	ssbx, ax, noAdvance
		pop	bx
		inc	dl			; ++prefixLen
		jmp	incloop2

tryExt2:
		cmp	dh, 3			; have we filled ext yet?
EC <		ERROR_A -1			; BAD BAD		>
NEC <		ja	doneLoop2		; don't count anymore!	>
		push	bx			; no.. write in extension.
		lea	bx, ss:[extension]
		add	bl, dh
DBCS <		adc	bh, 0						>
DBCS <		add	bl, dh			; TCHAR size		>
		adc	bh, 0
		LocalPutChar	ssbx, ax, noAdvance
		pop	bx
		inc	dh			; ++extensionLen
		jmp	incloop2

doneLoop2:
if	ERROR_CHECK
		cmp	di, 1*(size TCHAR)	; di should be 1 ('T' or 'P')
		ERROR_NZ -1
		cmp	dl, 3			; prefixLen == 3
		ERROR_NE	-1
		cmp	dh, 4			; && extensionLen == 4
		ERROR_NE	-1
		cmp	bh, 7			; numDigits2 == 7
		je	ecOK			; cool
		cmp	bh, 10			; numDigits == 10
		ERROR_NE -1			; MUST BE!
SBCS <		cmp	ah, 3			; areaCodeLen == 3	>
DBCS <		cmp	ss:[areaCodeLen], 3	; areaCodeLen == 3	>
		ERROR_NE	-1		
ecOK:
endif
	; Let's build the return value now!
	;
	; es:di = return phone number
	; bl = <DONT CARE>
	; bh = numDigits2 (for second loop)  (was garbage counter.. must be 0)
	; cl = <DONT CARE>
	; ch = preambleLen
	; ah = areaCodeLen
	; dl = prefixLen
	;

	; All our source data comes from the stack now, daddy-o.
	;
		segmov	ds, ss

	; Copy out the preamble, if any.
	;
		tst	ch			; preamble?
		jz	noPreamble
		lea	si, ss:[preamble]
		push	ax
		clr	cl
		xchg	ch, cl
		LocalCopyNString
		pop	ax

	; cx = <DONT CARE>

	; Check the outside line action.
	;
noPreamble:
		tst	ss:[dialOptions].APDO_outsideLine
		jz	noOutsideLine
		lea	si, ss:[dialOptions].APDO_outsideLine
		clr	bl			; pause counter
olCopy:
		LocalGetChar	ax, dssi	; 0-terminated
		LocalIsNull	ax
		jz	olCopyDone
		LocalPutChar	esdi, ax
		LocalCmpChar	ax, ','
		jne	olCopy
		inc	bl
		jmp	olCopy

olCopyDone:	; Append pause ',' if none already.
		LocalLoadChar	ax, ','
		tst	bl
		jnz	noOutsideLine
		LocalPutChar	esdi, ax

	; Check the call waiting action.
	;
noOutsideLine:
		tst	ss:[dialOptions].APDO_callWaiting
		jz	noCallWaiting
		lea	si, ss:[dialOptions].APDO_callWaiting
		clr	bl			; pause counter
cwCopy:
		LocalGetChar	ax, dssi	; 0-terminated
		LocalIsNull	ax
		jz	cwCopyDone
		LocalPutChar	esdi, ax
		LocalCmpChar	ax, ','
		jne	cwCopy
		inc	bl
		jmp	cwCopy

cwCopyDone:	; Append pause ',' if none already.
		LocalLoadChar	ax, ','
		tst	bl
		jnz	noCallWaiting
		LocalPutChar	esdi, ax

	; Do we stick out an area code?
	;   cx = offset to which area code to use
noCallWaiting:
		clr	cx			; no area code at first
		test	ss:[localDialOptions], mask APLDO_ALWAYS_ADD_AREA_CODE
		jnz	forced
		tst	ss:[dialOptions].APDO_tenDigit
		jz	notForced
forced:
		cmp	bh, 10			; numDigits2
		jne	forcedNot10
useSupplied:
		lea	cx, ss:[areaCode]
		jmp	haveArea
forcedNot10:
	; Need 10 digits, don't have 10.. use default area code
		tst	ss:[dialOptions].APDO_areaCode
		jz	noAreaCode		; no default.. oh well
		lea	cx, ss:[dialOptions].APDO_areaCode
		jmp	haveArea
				   
notForced:
	; Not forced to.  Do we have 10 digits? If not, no need for
	; an area code.
		cmp	bh, 10			; numDigits2
		jne	noAreaCode		; nope! done.
		tst	ss:[dialOptions].APDO_areaCode	; no default to cmp?
		jz	useSupplied		; use one supplied
	; We have 10 digits and we have a default area code.  We need
	; to compare them to see if we have to dial it.
		push	es,ds,si,di,cx
		segmov	ds, ss, si
		mov	es, si
		lea	si, ss:[dialOptions].APDO_areaCode
		lea	di, ss:[areaCode]
		mov	cx, 3
SBCS <		repe cmpsb						>
DBCS <		repe cmpsw						>
		pop	es,ds,si,di,cx
		je	noAreaCode		; EQUAL.. no area code needed
		jmp	useSupplied		; otherwise, use supplied code

haveArea:
	; Area code required.. Write out a "1-<area code>-"
	; If APLDO_OMIT_ONE_FOR_LONG_DISTANCE, skip the "1-".
		test	ss:[localDialOptions], mask APLDO_OMIT_ONE_FOR_LONG_DISTANCE
		jnz	skipOne
		LocalLoadChar	ax, '1'
		LocalPutChar	esdi, ax
		LocalLoadChar	ax, '-'
		LocalPutChar	esdi, ax
skipOne:
		mov	si, cx			; copy 3 byte area code.
		mov	cx, 3
		LocalCopyNString
		LocalLoadChar	ax, '-'
		LocalPutChar	esdi, ax

noAreaCode:
	; Finally, the rest of the damn thing.
		lea	si, ss:[prefix]
		mov	cx, 3
		LocalCopyNString
		LocalLoadChar	ax, '-'
		LocalPutChar	esdi, ax

		lea	si, ss:[extension]
		mov	cx, 4
		LocalCopyNString
		LocalClrChar	ax
		LocalPutChar	esdi, ax	; 0 terminate it

doneSuccess:
SBCS <		stc				; success		>
		mov	cx, di			; return length in cx
DBCS <		shr	cx, 1			; size to length	>
		dec	cx			; don't count zero byte
DBCS <		stc				; success		>

		mov	bx, ss:[returnHan]
		call	MemUnlock		; flags preserved

unlockPropHan:
		mov	bx, ss:[phonePropHan]
		call	MemUnlock		; flags preserved

freePropHan:
		mov	bx, ss:[phonePropHan]	; may jump here
		pushf
		call	MemFree
		popf

	; Return the return handle in BX.  If there was a failure, this should
	; still be 0 if the handle was to be allocated.
	;
		mov	bx, ss:[returnHan]

done:	; If unsuccessful, restore CX to passed CX.
		jc	reallyDone
		mov	cx, ss:[origCX]
reallyDone:
		.leave
		ret

errorUnlockPropHan:
		clc
		jmp	unlockPropHan

errorFreePropHan:
		clc
		jmp	freePropHan

AccessPointGetPhoneStringWithOptions	endp


ApiCode		ends
