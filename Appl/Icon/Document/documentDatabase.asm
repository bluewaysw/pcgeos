COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Icon Editor
FILE:		documentDatabase.asm

AUTHOR:		Steve Yegge, Nov  2, 1992

ROUTINES:
=============================================================================
Name				Description
=============================================================================
IdAddIcon			-- adds an icon to the database
IdDeleteIcon			-- deletes an icon from the database
IdGetIconCount			-- returns the number of icons in the database

IdCreateFormats			-- creates blank formats in an icon
IdClearFormat			-- frees a format's bitmap (no compaction)
IdClearAndSetFormat		-- sets new bitmap & frees old one (safely)
IdDeleteFormat			-- deletes a format and compacts list
IdFreeIconFormats		-- deletes all formats for an icon

IdGetIconHeader			-- returns entire header for an icon
IdSetIconHeader			-- sets most of the header for the icon

IdIncFormatCount		-- increments the format count for an icon
IdDecFormatCount		-- decrements the format count for an icon

IdGetFormat			-- returns a format from an icon
IdSetFormat			-- sets a format (caller must free the old one)
IdSetFormatNoCopy		-- sets a format in the format list (bitmap 
				   must already	be copied to the database, 
				   and format must be created).

IdGetIconFormat			-- Returns the entire IconFormat structure 
				   for an icon format
IdSetIconFormat			-- Set the entire IconFormat structure for 
				   an icon format. The format must already 
				   exist (use IdCreateFormats).

IdGetFormatParameters		-- returns a VisMonikerListEntry structure
IdSetFormatParameters		-- sets the VisMonikerListEntry for the format

IdGetFormatCount		-- returns number of valid formats for an icon
IdSetFormatCount		-- sets the number of valid formats for an icon

IdGetFormatDimensions		-- returns width & height of a format
IdGetFormatColorScheme		-- returns BMFormat for the format

IdGetFlags			-- gets IH_flags record
IdSetFlags			-- sets IH_flags record

IdGetIconName			-- returns the name field for an icon
IdSetIconName			-- sets the name field for an icon

IdGetPreviewObject		-- returns the preview object for an icon
IdSetPreviewObject		-- sets the preview object field for an icon
IdGetPreviewColors		-- returns the preview colors for an icon
IdSetPreviewColors		-- sets the preview colors for an icon

IdDiscardIcon			-- discards the mem handles for the icon

IdLockIcon			-- returns a pointer to the icon
IdUnlockIcon			-- unlocks the icon
IdGetHugeArray			-- returns bx:di = huge array
IdDirtyIcon			-- indicates the icon has been modified
IdLockFormatList		-- locks the IH_formatList
IdUnlockFormatList		-- unlocks IH_formatList
=============================================================================
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/2/92		Initial revision

DESCRIPTION:

	This file has the routines for accessing the database.  It
	could use the following changes:

		- some of the routines could be optimized by creating
		  routines that get passed ds:si = icon.  (So that the
		  huge array wouldn't keep getting locked & unlocked
		  by calls to other routines in this module).

	$Id: documentDatabase.asm,v 1.1 97/04/04 16:05:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
DatabaseCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdGetIconCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the number of icons in the database.

CALLED BY:	GLOBAL
PASS:		bp = vm file handle for icon database
RETURN:		ax = icon count
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- call HugeArrayGetCount, and return the low word.

	  We always assume the database has fewer than 64k icons in it,
	  so we always return the low word from HugeArrayGetCount.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdGetIconCount	proc	far
		uses	bx,dx,di
		.enter
		
		call	IdGetHugeArray			; bx:di = huge array
		call	HugeArrayGetCount
		
		.leave
		ret
IdGetIconCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdGetIconFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the entire IconFormat structure for an icon format

CALLED BY:	GLOBAL
PASS:		bp = vm file handle for icon database
		ax = icon number
		bx = format number
		cx:dx = buffer into which to copy IconFormat

RETURN:		cx:dx unchanged - buffer filled with header
		carry set if operation failed

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	- lock the huge array entry
	- copy the IconFormat into the buffer
	- unlock the huge array entry

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	10/15/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdGetIconFormat	proc	far
		uses	ax,bx,cx,es,di,si,ds,bp
		.enter
	;
	;  Bail if the format number exceeds the format count.
	;
EC <		push	dx			; save buffer offset	      >
EC <		mov	dx, bx			; dx = requested format       >
EC <		call	IdGetFormatCount	; bx = number of formats      >
EC <		cmp	dx, bx			; formats are zero-indexed... >
EC <		ERROR_GE	ILLEGAL_REQUESTED_FORMAT_NUMER		      >
EC <		mov	bx, dx			; dx is trashed               >
EC <		pop	dx			; restore buffer offset       >
	;
	;  Lock the format list.
	;
		call	IdLockFormatList	; returns *ds:si = chunkarray
						; bp = mem handle of block
		jc	done			; return error

		mov	ax, bx			; ax = format number
		call	ChunkArrayElementToPtr	; ds:di = IconFormat
		jc	done			; return error
	;
	; Copy the IconFormat
	;
		mov	si, di			; ds:si = IconFormat

		mov	es, cx			
		mov	di, dx			; es:di = destination buffer

		mov	cx, size IconFormat	
		rep	movsb
	;
	;  Unlock the format list.
	;
		call	IdUnlockFormatList
done:
		.leave
		ret
IdGetIconFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdSetIconFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the entire IconFormat structure for an icon format.
		The format must already exist (use IdCreateFormats).

CALLED BY:	GLOBAL
PASS:		bp = vm file handle for icon database
		ax = icon number
		bx = format number
		cx:dx = buffer from which to copy IconFormat

RETURN:		cs:dx unchanged
		carry set if operation failed

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	- lock the huge array entry
	- copy the IconFormat from the buffer
	- unlock the huge array entry

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	10/15/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdSetIconFormat	proc	far
		uses	ax,bx,cx,di,si,ds,bp,es
		.enter
	;
	;  Bail if the format number exceeds the format count.
	;
EC <		push	dx			; save buffer offset	      >
EC <		mov	dx, bx			; dx = requested format       >
EC <		call	IdGetFormatCount	; bx = number of formats      >
EC <		cmp	dx, bx			; formats are zero-indexed... >
EC <		ERROR_GE	ILLEGAL_REQUESTED_FORMAT_NUMER                >
EC <		mov	bx, dx			; dx is trashed		      >
EC <		pop	dx			; restore buffer offset       >
	;
	;  Lock the format list.
	;
		call	IdLockFormatList	; returns *ds:si = chunkarray
						; bp = mem handle of block
		jc	done			; return error

		mov	ax, bx			; ax = format number
		call	ChunkArrayElementToPtr	; ds:di = IconFormat
		jc	done			; return error
	;
	; Copy the IconFormat
	;
		segmov	es, ds, ax		; es:di = destination

		mov	ds, cx
		mov	si, dx			; ds:si = source buffer
		
		mov	cx, size IconFormat	
		rep	movsb
	;
	;  Unlock the format list.
	;
		call	IdUnlockFormatList
done:
	.leave
	ret
IdSetIconFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdGetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a format from an icon.

CALLED BY:	GLOBAL

PASS:		bp = vm file handle for icon database
		ax = icon number
		bx = format number

RETURN:		cx = vm file handle of bitmap   (undefined if no bitmap)
		dx = vm block handle of bitmap	(0 for no bitmap)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
	- lock the huge array entry
	- get the bitmap
	- unlock the huge array entry
	- get the file handle (stored in idata)
	- return the bitmap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdGetFormat	proc	far
		uses	ax,bx,di,si,ds,bp
		.enter
	;
	;  Bail if the format number exceeds the format count.
	;  We just want to return dx=0
	;
EC <		mov	dx, bx			; dx = requested format       >
EC <		call	IdGetFormatCount	; bx = number of formats      >
EC <		cmp	dx, bx			; formats are zero-indexed... >
EC <		jge	noBitmap		; ...so jge instead of jg     >
EC <		mov	bx, dx			; dx is trashed		      >

	;
	;  Lock the format list.
	;
		mov	dx, bp			; save vm file handle
		call	IdLockFormatList	; returns *ds:si = chunkarray
		jc	noBitmap

		mov	ax, bx			; ax = format number
		call	ChunkArrayElementToPtr	; ds:di = IconFormat
		jc	noBitmap

		mov	cx, dx			; cx = vm file handle
		mov	dx, ds:[di].IF_bitmap

		call	IdUnlockFormatList
		jmp	short	done
noBitmap:
		clr	dx
done:
		.leave
		ret
IdGetFormat	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdSetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets a format in an icon from a given bitmap.  The
		format must already exist (use IdCreateFormats).

CALLED BY:	GLOBAL

PASS:		bp = vm file handle of icon database
		ax = icon number
		bx = format number
		cx = vm file handle of new bitmap (0 to clear)
		dx = vm block handle (0 for simply clearing the format)

RETURN:		carry set if operation failed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- copy the passed vm chain to the database
	- saves the chain handle in the passed icon + format

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	This procedure will not free the old bitmap; you have to do
	this yourself with IdClearFormat before calling this routine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdSetFormat	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
		
		call	IdLockIcon		; ds:si = icon
		jc	done			; invalid icon if carry set
		
		tst	dx			; passed bitmap block handle
		jz	doneCopy		; no bitmap; skip copying chain
	;
	;  Copy the VM chain into the database.  (This operation preserves
	;  the icon pointer in ds:si).
	;
		push	bx, bp, ax		; save format, file, icon
		mov	bx, cx			; bx <- source file
		mov	ax, dx			; ax <- source VM chain
		mov	dx, bp			; dx = vm file handle
		clr	bp			; no DB items
		call	VMCopyVMChain		; returns new chain in ax
		mov_tr	dx, ax			; dx <- vm block handle
		pop	bx, bp, ax		; format, file & icon
	;
	;  Unlock the huge array entry
	;
		call	IdDirtyIcon
		call	IdUnlockIcon
doneCopy:
	;
	;  Save the vm chain returned by VMCopyVMChain (stored in dx)
	;  into the chunk array format list.  And dirty the block!  Oh,
	;  what a debugging session that was!
	;
		call	IdLockFormatList	; *ds:si = format list
		mov_tr	ax, bx			; ax = format number
		call	ChunkArrayElementToPtr	; ds:di = IconFormat
		mov	ds:[di].IF_bitmap, dx	; save the bitmap
		call	VMDirty
		call	IdUnlockFormatList
done:
		.leave
		ret
IdSetFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdSetFormatNoCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets a format in the format list (bitmap must already
		be copied to the database, and format must be created).

CALLED BY:	GLOBAL

PASS:		bp	= vm file handle
		ax	= icon number
		bx	= format number
		dx	= block handle of bitmap already in database

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/15/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdSetFormatNoCopy	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter

		call	IdLockFormatList	; *ds:si = chunkarray
		mov	ax, bx			; ax = format number
		call	ChunkArrayElementToPtr	; ds:di = IconFormat
		mov	ds:[di].IF_bitmap, dx
		call	VMDirty
		call	IdUnlockFormatList

		.leave
		ret
IdSetFormatNoCopy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdSetFormatParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the fields in IF_type (a VisMonikerListEntryType)

CALLED BY:	GLOBAL

PASS:		bp	= file handle
		ax	= icon
		bx	= format
		cx	= FormatParameters etype if dx is zero, else
		cx	= VisMonikerListEntryType

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/26/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdSetFormatParameters	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter

		tst	dx
		jnz	custom

		mov	si, cx
		mov	dx, cs:[standardFormatTable][si]
		jmp	short	gotVMLE
custom:
		mov	dx, cx
gotVMLE:
		call	IdLockFormatList	; *ds:si = chunkarray
		mov	ax, bx			; ax = format
		call	ChunkArrayElementToPtr	; ds:di = IconFormat

		mov	ds:[di].IF_type, dx
		call	VMDirty
		call	IdUnlockFormatList

		.leave
		ret
IdSetFormatParameters	endp

standardFormatTable VisMonikerListEntryType	\
	<DS_STANDARD,VMS_ICON,,TRUE,DAR_NORMAL,DC_COLOR_4>,	  ; VGA file
	<DS_STANDARD,VMS_ICON,,TRUE,DAR_SQUISHED,DC_COLOR_4>,	  ; EGA file
	<DS_STANDARD,VMS_ICON,,TRUE,DAR_VERY_SQUISHED,DC_GRAY_1>, ; CGA file
	<DS_STANDARD,VMS_ICON,,TRUE,DAR_NORMAL,DC_GRAY_1>,	  ; MCGA file
	<DS_TINY,VMS_ICON,,TRUE,DAR_NORMAL,DC_COLOR_4>,		  ; TC file
	<DS_TINY,VMS_ICON,,TRUE,DAR_NORMAL,DC_GRAY_1>,		  ; TM file
	<DS_STANDARD,VMS_TOOL,,TRUE,DAR_NORMAL,DC_COLOR_4>,	  ; VGA tool
	<DS_STANDARD,VMS_TOOL,,TRUE,DAR_SQUISHED,DC_COLOR_4>,	  ; EGA tool
	<DS_STANDARD,VMS_TOOL,,TRUE,DAR_VERY_SQUISHED,DC_GRAY_1>, ; CGA tool
	<DS_STANDARD,VMS_TOOL,,TRUE,DAR_NORMAL,DC_GRAY_1>,	  ; MCGA tool
	<DS_TINY,VMS_TOOL,,TRUE,DAR_NORMAL,DC_COLOR_4>,		  ; TC tool
	<DS_TINY,VMS_TOOL,,TRUE,DAR_NORMAL,DC_GRAY_1>,		  ; TM tool
	<>							  ; PtrDef

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdGetFormatParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns IF_type for the format.

CALLED BY:	GLOBAL

PASS:		bp	= file handle
		ax	= icon number
		bx	= format number

RETURN:		cx	= VisMonkerListEntryType

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/31/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdGetFormatParameters	proc	far
		uses	ax,bx,si,di,bp,ds
		.enter

		call	IdLockFormatList	; *ds:si = chunk array
		mov_tr	ax, bx			; ax = format
		call	ChunkArrayElementToPtr	; ds:di = format
		mov	cx, ds:[di].IF_type
		call	IdUnlockFormatList

		.leave
		ret
IdGetFormatParameters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdCreateFormats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a new blank IconFormat to the chunk array.

CALLED BY:	GLOBAL

PASS:		bp	= vm file handle
		ax	= icon number
		cx	= number of formats to create

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/23/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdCreateFormats	proc	far
		uses	cx,si,di,bp,ds
		.enter

		call	IdLockFormatList		; *ds:si = array
formatLoop:		
		call	ChunkArrayAppend		; ds:di = new element
		loop	formatLoop

		call	VMDirty
		call	IdUnlockFormatList

		.leave
		ret
IdCreateFormats	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdSetIconName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Changes the name of a specified icon in the database.

CALLED BY:	GLOBAL

PASS:		bp = vm file handle for icon database
		ax = icon number
		bx:dx = fptr to string
		cx = length of string (including NULL)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- lock the icon
	- refuse to change the name if the icon's invalid
	- get pointers to source & destination
	- clear the name buffer in destination
	- move the name
	- dirty the database
	- unlock the icon

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdSetIconName	proc	far
		uses	ax,cx,dx,si,di,ds,es
		.enter
	;
	;  Lock the icon and set es:di to it.
	;
		call	IdLockIcon		; ds:si = icon
		jc	done
		
		segmov	es, ds, ax		; es = icon segment
		mov	di, si			; es:di = icon
	;
	;  set up the move, and do it.
	;
		mov	ds, bx			; ds = string segment
		mov	si, dx			; ds:si = string
		rep	movsb			; nukes cx, of course
		
		segmov	ds, es, ax		; ds = icon segment
		call	IdDirtyIcon
		call	IdUnlockIcon
done:
		.leave
		ret
IdSetIconName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdGetIconName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the name of the icon

CALLED BY:	GLOBAL

PASS:		bp = vm file handle for icon database
		ax = icon number
		bx:dx = fptr to buffer into which to put the name

RETURN:		bx:dx = preserved, filled with name of icon
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- lock the icon
	- copy the name into the destination buffer
	- unlock the icon

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdGetIconName	proc	far
		uses	cx,si,di,es,ds
		.enter
		
		call	IdLockIcon		; ds:si = icon
		jc	done			; bad icon number
		
		lea	si, ds:[si].IH_name	; ds:si = icon name
		
		mov	es, bx
		mov	di, dx			; es:di = buffer for name
		mov	cx, FILE_LONGNAME_BUFFER_SIZE
		rep	movsb
		
		call	IdUnlockIcon
done:
		.leave
		ret
IdGetIconName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdGetIconHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the entire header for an icon.

CALLED BY:	EXTERNAL

PASS:		bp	= file handle for database
		ax	= icon number
		cx:dx	= buffer into which to copy header

RETURN:		cx:dx unchanged - buffer filled with header

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/15/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdGetIconHeader	proc	far
		uses	cx,si,di,ds,es
		.enter

		call	IdLockIcon		; ds:si = header
		mov	es, cx
		mov	di, dx
		mov	cx, size IconHeader
		rep	movsb
		call	IdUnlockIcon

		.leave
		ret
IdGetIconHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdSetIconHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the header from a buffer, EXCEPT for the format
		list, which is unchanged.

CALLED BY:	EXTERNAL

PASS:		bp	= file handle for database
		ax	= icon number
		cx:dx	= buffer with header info (only the information
			  up to and not including the format list will
			  be copied).

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/19/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdSetIconHeader	proc	far
		uses	ax,cx,si,di,ds,es
		.enter

		call	IdLockIcon		; ds:si = IconHeader
		segmov	es, ds, di
		mov	di, si			; es:di = dest header

		mov	ds, cx
		mov	si, dx			; ds:si = source header
		mov	cx, size IconHeader
		sub	cx, size IH_formatList
		rep	movsb

		segmov	ds, es, di
		call	IdUnlockIcon

		.leave
		ret
IdSetIconHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdFreeIconFormats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees all VM blocks associated with an icon.

CALLED BY:	GLOBAL

PASS:		bp = vm file handle for icon database
		ax = icon number

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- for each format entry:  if the format is nonzero, free it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdFreeIconFormats	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter

		mov	cx, bp			; cx = database file
		call	IdLockFormatList	; *ds:si = chunk array
		jc	done

		mov	bx, cs
		mov	di, offset FreeFormatCallBack
		call	ChunkArrayEnum

		call	VMDirty
		call	IdUnlockFormatList
done:
		.leave
		ret
IdFreeIconFormats	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeFormatCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for IdFreeIconFormats.

CALLED BY:	ChunkArrayEnum

PASS:		ds:di	= IconFormat
		cx	= file handle

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/22/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeFormatCallBack	proc	far
		uses	ax, bx, bp
		.enter
		
		mov	bx, cx
		mov	ax, ds:[di].IF_bitmap
		clr	bp			; no DB items in chain
		call	VMFreeVMChain

		.leave
		ret
FreeFormatCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdAddIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a blank icon in the database.

CALLED BY:	GLOBAL
	
PASS:		bp	= vm file handle of icon database
		cx	= number of (blank) formats to initially create

RETURN:		ax	= new icon's number in the database

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- create a zeroed-out IconHeader and append it.
	- create cx blank formats in the format list

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdAddIcon	proc	far
		uses	bx,cx,dx,si,di,ds

		vmFile		local	hptr	push	bp
		formats		local	word	push	cx
		icon		local	word
		formatBlock	local	word
		
		.enter

		push	bp			; locals
		mov	bp, vmFile
		call	IdGetHugeArray		; bx:di = huge array
		mov	dx, bx			; dx:di = huge array
		pop	bp
	;
	;  Create a block for the IconHeader
	;
		mov	ax, size IconHeader
		clr	cl			; HeapFlags
		mov	ch, mask HAF_ZERO_INIT or mask HAF_LOCK
		call	MemAlloc		; bx = handle; ax = segment
		jc	done
		
		push	bp			; save locals
		mov	bp, ax			; bp = segment
		clr	si			; bp:si = IconHeader
		push	bx			; save handle for freeing
		
		mov	bx, dx			; bx:di = huge array
		mov	cx, 1
		call	HugeArrayAppend		; ax <- new icon number

		pop	bx			; temp block handle
		call	MemFree
		pop	bp			; restore locals
	;
	;  Create a chunk array for the format list.
	;
		mov	icon, ax
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx
		call	MemAllocLMem
		call	MemLock
		mov	ds, ax			; ds = segment
		mov	formatBlock, bx
		
		mov	bx, size IconFormat
		clr	cx, si, ax
		call	ChunkArrayCreate	; *ds:si = chunk array

		mov	bx, formatBlock
		call	MemUnlock
	;
	;  Attach the chunk array to the vm file.
	;
		mov	cx, bx			; cx = mem block handle
		mov	bx, vmFile
		clr	ax			; allocate new vm block
		call	VMAttach		; ax <- new vm block
	;
	;  Save the chunk array in IH_formatList.
	;
		push	bp			; save locals
		mov_tr	cx, ax			; cx = new vm block
		mov	ax, icon
		mov	bp, bx			; bx = vm file handle
		mov	di, si			; di = chunk array handle
		call	IdLockIcon		; ds:si = icon
		mov	ds:[si].IH_formatList.handle, cx
		mov	ds:[si].IH_formatList.chunk, di
		call	IdUnlockIcon
		pop	bp			; restore locals
	;
	;  Create some blank formats if necessary.
	;
		mov	ax, icon
		mov	cx, formats		; how many to create
		jcxz	done
		
		push	bp			; locals
		mov	bp, vmFile
		call	IdCreateFormats
		pop	bp			; locals
done:		
		.leave
		ret
IdAddIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdDeleteIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes an icon from the database.  Doesn't delete the
		formats (call IdFreeIconFormats first).

CALLED BY:	GLOBAL

PASS:		bp = vm file handle for icon database
		ax = icon number

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdDeleteIcon	proc	far
		uses	ax,bx,cx,dx,di,si,ds
		.enter
	;
	;  Delete the format list vm block.
	;
		push	ax			; save icon number
		call	IdLockIcon		; ds:si = icon
		mov	ax, ds:[si].IH_formatList.handle
		mov	bx, bp			; file handle
		call	VMFree
		call	IdUnlockIcon
		pop	ax			; restore icon number
	;
	;  Delete the icon vm block.
	;
		call	IdGetHugeArray		; bx:di = huge array
		mov	cx, 1			; delete 1 element
		clr	dx			; dx.ax = element to delete
		call	HugeArrayDelete
		
		.leave
		ret
IdDeleteIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdGetFormatCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the number of valid formats for the icon.

CALLED BY:	GLOBAL

PASS:		bp = vm file handle for icon database
		ax = icon number

RETURN:		bx = format count
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdGetFormatCount	proc	far
		uses	ds,si
		.enter
		
		call	IdLockIcon			; ds:si = icon
		jc	done
		
		mov	bx, ds:[si].IH_formatCount
		call	IdUnlockIcon
done:
		.leave
		ret
IdGetFormatCount	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdSetFormatCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the count of valid formats for the icon.

CALLED BY:	GLOBAL

PASS:		bp = vm file handle for icon database
		ax = icon number
		bx = new count

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdSetFormatCount	proc	far
		uses	ds,si
		.enter
		
		call	IdLockIcon			; ds:si = icon
		jc	done
		
		mov	ds:[si].IH_formatCount, bx
		
		call	IdDirtyIcon
		call	IdUnlockIcon
done:
		.leave
		ret
IdSetFormatCount	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdIncFormatCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increments IH_formatCount for the icon.

CALLED BY:	GLOBAL

PASS:		bp = vm file handle for icon database
		ax = icon number

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdIncFormatCount	proc	far
		uses	ds,si
		.enter
		
		call	IdLockIcon			; ds:si = icon
		jc	done
		
		inc	ds:[si].IH_formatCount
		
		call	IdDirtyIcon
		call	IdUnlockIcon
done:
		.leave
		ret
IdIncFormatCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdDecFormatCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrements IH_formatCount for the icon.

CALLED BY:	GLOBAL
	
PASS:		bp = vm file handle for icon database
		ax = icon number

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdDecFormatCount	proc	far
		uses	ds,si
		.enter
		
		call	IdLockIcon			; ds:si = icon
		jc	done
		
		dec	ds:[si].IH_formatCount
		
		call	IdDirtyIcon
		call	IdUnlockIcon
done:
		.leave
		ret
IdDecFormatCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdClearFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees the format's bitmap without actually deleting the
	 	entry in the chunk array.

CALLED BY:	GLOBAL

PASS:		bp = vm file handle for icon database
		ax = icon
		bx = format to clear

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdClearFormat	proc	far
		uses	ax,bx,cx,dx,bp,di
		.enter
		
		call	IdGetFormat		; get the old format
		tst	dx			; null format?
		jz	done

	;
	; set up parameters for VMInfo and VMFreeVMChain	
	;
		movdw	bxax, cxdx

EC <		push	ax						>
EC <		call	VMInfo			; nukes ax, cx & di	>
EC <		ERROR_C	CORRUPTED_ICON_DATABASE				>
EC <		pop	ax						>

		clr	bp			; no DB items
		call	VMFreeVMChain
done:
		.leave
		ret
IdClearFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdClearAndSetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes old bitmap and sets new one without race condition.

CALLED BY:	GLOBAL

PASS:		bp	= vm file handle for database
		ax	= icon number
		bx	= format number
		cx	= vm file handle of new bitmap
		dx	= vm block handle of new bitmap

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- get & save the old bitmap's block handle
	- set the new bitmap into the database
	- free the old bitmap

	This prevents the format list from ever containing
	handles to freed blocks (this actually caused deaths,
	believe it or not).

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	9/ 1/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdClearAndSetFormat	proc	far
		uses	ax,bx,cx,dx,si,di,bp

		database	local	hptr	push	bp
		oldBitmap	local	dword
		newBitmap	local	dword
		
		.enter
	;
	;  Save the new bitmap; grab the old one and save it too.
	;
		movdw	newBitmap, cxdx
		
		push	bp			; locals
		mov	bp, database
		call	IdGetFormat		; ^vcx:dx = old format
		pop	bp
	;
	;  Stick the new bitmap into the database.
	;
		movdw	oldBitmap, cxdx
		movdw	cxdx, newBitmap

		push	bp			; locals
		mov	bp, database
		call	IdSetFormat
		pop	bp			; locals
	;
	;  Free the old bitmap.
	;
		movdw	bxax, oldBitmap

EC <		push	ax						>
EC <		call	VMInfo			; nukes ax & not bx	>
EC <		ERROR_C	CORRUPTED_ICON_DATABASE				>
EC <		pop	ax						>

		push	bp
		clr	bp			; no DB items in chain
		call	VMFreeVMChain
		pop	bp

		.leave
		ret
IdClearAndSetFormat	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdDeleteFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the passed format & updates the count

CALLED BY:	IconIdDeleteFormat

PASS:		bp = vm file handle
		ax = icon number
		bx = format number

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- get the format and free it
	- compact the format list to get rid of the hole
	- decrements the format count for the icon

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdDeleteFormat	proc	far
		uses	ax,bx,bp,si,di,ds
		.enter
	;
	;  Free the old format, and set it to NULL (unless it is already)
	;
		push	ax, bp			; save icon
		call	IdClearFormat
		call	IdLockFormatList	; *ds:si = chunk array
		jc	errorPop2

		mov_tr	ax, bx			; ax = format number
		call	ChunkArrayElementToPtr	; ds:di = element
		call	ChunkArrayDelete	; delete that baby
		call	VMDirty
		call	IdUnlockFormatList

		pop	ax, bp			; ax = icon number
		call	IdDecFormatCount
		jmp	short	done
errorPop2:
		pop	ax, bx			; restore sp
done:
		.leave
		ret
IdDeleteFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the IH_flags record from the icon header.

CALLED BY:	GLOBAL

PASS:		bp	= vm file handle for database
		ax	= icon number

RETURN:		bx	= flags

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	2/ 9/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdGetFlags	proc	far
		uses	ds, si
		.enter
		
		call	IdLockIcon			; ds:si = icon
		jc	done
		
		mov	bx, ds:[si].IH_flags
		call	IdUnlockIcon
done:
		.leave
		ret
IdGetFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdSetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the IH_flags record in the icon header.

CALLED BY:	GLOBAL

PASS:		bp 	= vm file handle for database
		ax	= icon number
		bx	= bits to set
		cx	= bits to clear

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	2/ 9/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdSetFlags	proc	far
		uses	ds, si
		.enter
		
		call	IdLockIcon			; ds:si = icon
		jc	done
		
		ornf	ds:[si].IH_flags, bx		; set these bits
		not	cx
		andnf	ds:[si].IH_flags, cx		; clear these bits
		
		call	IdDirtyIcon
		call	IdUnlockIcon
done:
		.leave
		ret
IdSetFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdGetFormatDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the width & height of passed format.

CALLED BY:	GLOBAL

PASS:		bp = vm file handle for the icon database
		ax = icon number
		bx = format number

RETURN:		cx = width	(0 for no bitmap)
		dx = height	(0 for no bitmap)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdGetFormatDimensions	proc	far
		uses	ax,bx,di,ds
		.enter
		
		call	IdGetFormat		; returns ^vcx:dx = bitmap
		tst	dx
		jz	noBitmap
		
		movdw	bxdi, cxdx
		call	GrGetHugeBitmapSize
		movdw	cxdx, axbx		; cx = width, dx = height

		jmp	short	done
noBitmap:
		clrdw	cxdx			; return 0`s
done:
		.leave
		ret
IdGetFormatDimensions	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdGetFormatColorScheme
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the BMFormat for the format's bitmap.

CALLED BY:	GLOBAL

PASS:		bp = vm file handle for icon database
		ax = icon number
		bx = format number

RETURN:		al = BMFormat (invalid if no bitmap in the format)
DESTROYED:	ah

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdGetFormatColorScheme	proc	far
		uses	bx,cx,dx,di,ds
		.enter
		
		call	IdGetFormat		; returns in cx & dx
		tst	dx
		jz	done

		movdw	bxdi, cxdx
		call	HugeArrayLockDir	; nukes bp
		mov	ds, ax
		
		mov	al, ds:[(size HugeArrayDirectory)].CB_simple.B_type
		and	al, mask BM_FORMAT	; mask out all but the format
		
		call	HugeArrayUnlockDir
done:		
		.leave
		ret
IdGetFormatColorScheme	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdGetPreviewObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the current preview-object for the icon.

CALLED BY:	GLOBAL

PASS:		bp = vm file handle for icon database
		ax = icon number

RETURN:		cx = preview object
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdGetPreviewObject	proc	far
		uses	ds,si
		.enter
		
		call	IdLockIcon		; ds:si = icon
		jc	done
		
		mov	cx, ds:[si].IH_preview.PST_object
		
		call	IdUnlockIcon
done:
		.leave
		ret
IdGetPreviewObject	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdSetPreviewObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the preview object for an icon.

CALLED BY:	GLOBAL

PASS:		bp = vm file handle for icon database
		ax = icon
		bx = preview object  (PreviewGroupInteractionObject)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdSetPreviewObject	proc	far
		uses	ds,si
		.enter
		
		call	IdLockIcon		; ds:si = icon
		jc	done
		
		mov	ds:[si].IH_preview.PST_object, bx
		
		call	IdDirtyIcon
		call	IdUnlockIcon
done:
		.leave
		ret
IdSetPreviewObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdGetPreviewColors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the preview-object colors for the icon.

CALLED BY:	GLOBAL

PASS:		bp = vm file handle for icon database
		ax = icon number

RETURN:		ch = selected ("on") color 1
		cl = selected ("on") color 2
		dh = unselected ("off") color 1
		dl = unselected ("off") color 2

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdGetPreviewColors	proc	far
		uses	ds,si
		.enter
		
		call	IdLockIcon			; ds:si = icon
		jc	done
		
		mov	ch, ds:[si].IH_preview.PST_onColor.CP_firstColor
		mov	cl, ds:[si].IH_preview.PST_onColor.CP_secondColor
		mov	dh, ds:[si].IH_preview.PST_offColor.CP_firstColor
		mov	dl, ds:[si].IH_preview.PST_offColor.CP_secondColor
		
		call	IdUnlockIcon
done:
		.leave
		ret
IdGetPreviewColors	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdSetPreviewColors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the preview colors for the icon.

CALLED BY:	GLOBAL

PASS:		bp = vm file handle for icon database
		ax = icon
		ch = selected ("on") color 1
		cl = selected ("on") color 2
		dh = unselected ("off") color 1
		dl = unselected ("off") color 2

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdSetPreviewColors	proc	far
		uses	ds,si
		.enter
		
		call	IdLockIcon			; ds:si = icon
		jc	done
		
		mov	ds:[si].IH_preview.PST_onColor.CP_firstColor, ch
		mov	ds:[si].IH_preview.PST_onColor.CP_secondColor, cl 
		mov	ds:[si].IH_preview.PST_offColor.CP_firstColor, dh
		mov	ds:[si].IH_preview.PST_offColor.CP_secondColor, dl
		
		call	IdDirtyIcon
		call	IdUnlockIcon
done:
		.leave
		ret
IdSetPreviewColors	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiscardIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees all memory blocks associated with the icon.

CALLED BY:	GLOBAL

PASS:		bp = database file handle
		ax = icon number

RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	We free all memory blocks associated with each vm chain in
	the icon.  Why?  Because the vm manager would rather
	swap them into EMS or XMS, and the handle table fills up.
	Note that we have to call VMUpdate to flush the dirty
	blocks to disk or the discard-vm-chain won't work.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	8/27/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdDiscardIcon	proc	far
		uses	ax,bx,cx,dx,si,ds
		.enter
	;
	;  First write all the blocks to the file, so that the
	;  calls to VMDetach will function correctly.
	;
		mov_tr	cx, ax			; save icon number
		mov	bx, bp
		call	VMUpdate
		jc	done
		mov_tr	ax, cx			; restore icon number
	;
	;  Loop through the formats, detaching the blocks in the
	;  vm chain.
	;
		call	IdGetFormatCount	; bx = count
		mov	cx, bx
		dec	cx			; zero-indexed format numbers	
formatLoop:
		push	cx, ax			; format number & icon number
		mov	bx, cx
		call	IdGetFormat		; ^vcx:dx = format

		tst	dx
		jz	errorPop2	

		movdw	bxax, cxdx
		call	DiscardVMChain
		pop	cx, ax			; restore format & icon number
		loop	formatLoop
doneLoop::
	;
	;  Discard the format-list block as well.  Don't bother
	;  discarding the icon-header block, since it'll likely
	;  get loaded right back in.
	;
		call	IdLockIcon
		mov	ax, ds:[si].IH_formatList.handle
		call	IdUnlockIcon

		mov	bx, bp
		call	DiscardVMBlock
		clc
done:
		.leave
		ret
errorPop2:
		add	sp, 2*(size word)	; restore stack pointer
		stc
		jmp	done
IdDiscardIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdDiscardIconList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees memory handles associated with the huge array of
		IconHeader structs (whose handle is in the map block).

CALLED BY:	GLOBAL

PASS:		bp = vm file handle

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	8/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdDiscardIconList	proc	far
		uses	ax,bx,di
		.enter

		mov	bx, bp
		call	VMUpdate

		call	IdGetHugeArray			; bx:di = vm chain
		mov	ax, di				; bx:ax = chain
		call	DiscardVMChain

		.leave
		ret
IdDiscardIconList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdLockIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the icon is valid and locks it.

CALLED BY:	INTERNAL

PASS:		ax = icon number
		bp = vm file handle for icon database

RETURN:		ds:si = icon, or
		carry set if invalid icon number or other error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- get the icon count in the database.  since the database is
	  zero-indexed, the count will be 1 higher than the highest
	  icon number.  If the passed icon number is >= the count,
	  then it's an invalid icon.

	- lock the icon using HugeArrayLock

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdLockIcon	proc	near
		uses	ax,bx,cx,dx,di
		.enter
	;
	;  Get the huge array handle, and count the icons.
	;
		call	IdGetHugeArray		; bx:di = huge array
		tst	di
		jz	error
		
		mov_tr	cx, ax			; cx = icon number
		call	HugeArrayGetCount	; ax = icon count
		
		cmp	cx, ax			; passed icon # invalid?
		jae	error
		
		mov_tr	ax, cx			; ax = icon number
		clr	dx			; dx:ax = element number
		call	HugeArrayLock		; ds:si = iconHeader
		clc				; return no error
		jmp	short	done
error:
		stc				; return error
done:
		.leave
		ret
IdLockIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdUnlockIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlocks the icon

CALLED BY:	INTERNAL
PASS:		ds = sptr to icon
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdUnlockIcon	proc	near
		
		call	HugeArrayUnlock
		
		ret
IdUnlockIcon	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdGetHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the huge array in bx:di from the vm file handle

CALLED BY:	INTERNAL
PASS:		bp = vm file handle for icon database

RETURN: 	bx:di = huge array

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	11/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdGetHugeArray	proc	near
		uses	ax, bp, ds
		.enter
		
		mov	bx, bp
		call	VMGetMapBlock		; returns handle in ax
		tst	ax
		jz	error
		
		call	VMLock			; nukes bp
		mov	ds, ax
		
		mov	di, ds:[IMBS_iconList]	; huge-array handle
		call	VMUnlock
		
		jmp	short	done
error:
		clr	di
done:
		.leave
		ret
IdGetHugeArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdDirtyIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dirties the entry for the icon.	

CALLED BY:	INTERNAL
PASS: 		ds = locked icon segment
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdDirtyIcon	proc	near
		
		call	HugeArrayDirty
		
		ret
IdDirtyIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdLockFormatList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns *ds:si = IH_formatList for the icon.

CALLED BY:	INTERNAL

PASS:		bp	= vm file handle
		ax	= icon

RETURN:		*ds:si	= format list (chunk array)
		bp	= memory handle of locked vm block
		carry	- set if operation failed for some reason

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/22/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdLockFormatList	proc	near
		uses	ax, bx
		.enter

		call	IdLockIcon		; ds:si = icon
		jc	done
		
		mov	ax, ds:[si].IH_formatList.handle
		mov	si, ds:[si].IH_formatList.chunk
		mov	bx, bp
		call	VMLock			; ax = segment
		call	IdUnlockIcon

		mov	ds, ax			; *ds:si = ChunkArray
done:		
		.leave
		ret
IdLockFormatList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IdUnlockFormatList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlocks a previously locked format list block.

CALLED BY:	INTERNAL

PASS:		bp	= mem handle returned by IdLockFormatList

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/22/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IdUnlockFormatList	proc	near

		call	VMUnlock
		
		ret
IdUnlockFormatList	endp


DatabaseCode	ends
