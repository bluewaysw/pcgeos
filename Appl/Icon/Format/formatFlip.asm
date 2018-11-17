COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Icon Editor
FILE:		formatFlip.asm

AUTHOR:		Steve Yegge, Jan  7, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT DBViewerRotateFormat	Flip a format horizontally or vertically.

    INT FlipFormat		Flip format horizontally or vertically.

    INT DoHorizontalFlip	Takes the existing bitmap and flips it
				horizontally.

    INT DoVerticalFlip		Flip a bitmap vertically.

    INT Do90DegreeRotate	Rotate the format 90 degrees clockwise.

    INT Do180DegreeRotate	Rotate a format 180 degrees.

    INT Do270DegreeRotate	Rotate a format 270 degrees clockwise (90
				CCW).

    INT BitmapDrawFillCommon	Draw the source bitmap to the destination
				gstate, set the mask bits, and kill the
				gstate & window.

    INT Flop90Degrees		Rotate a huge bitmap 90 degrees clockwise.

    INT RotateScanLine		Rotates 1 scanline 90 degrees.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/ 7/94		Initial revision

DESCRIPTION:

	Routines for flipping a format horizontally or vertically.

	$Id: formatFlip.asm,v 1.1 97/04/04 16:06:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerRotateFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flip a format horizontally or vertically.

CALLED BY:	MSG_DB_VIEWER_ROTATE_FORMAT

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	1/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerRotateFormat	proc	far
		class	DBViewerClass
		uses	ax, cx, dx, bp
		.enter

		call	IconMarkBusy
	;
	;  If there's no current icon, bail.
	;
		cmp	ds:[di].DBVI_currentIcon, NO_CURRENT_ICON
		je	done
		
		call	CheckFormatDirtyAndDealWithIt
		jc	done			; user cancelled
	;
	;  See which type of flip the user wants to do.
	;
		push	si			; DBViewer object
		mov	bx, ds:[di].GDI_display
		mov	si, offset RotateItemGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage
		mov_tr	cx, ax			; cx = selection
	;
	;  Call a subroutine to do all the work.
	;
		pop	si			; *ds:si = DBViewer
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		call	FlipFormat
	;
	;  Switch editing to the new format (updates UI 'n' stuff).
	;  Yes, I know it's the same format.
	;
		mov	cx, ds:[di].DBVI_currentFormat
		mov	ax, MSG_DB_VIEWER_SWITCH_FORMAT
		call	ObjCallInstanceNoLock
	;
	;  Send a message to the format list to rescan.
	;
		mov	ax, MSG_FORMAT_CONTENT_RESCAN_LIST
		mov	si, offset FormatViewer
		call	ObjCallInstanceNoLock
done:
		call	IconMarkNotBusy

		.leave
		ret
DBViewerRotateFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlipFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flip format horizontally or vertically.

CALLED BY:	DBViewerRotateFormat

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance
		cx	= FormatRotateType

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	We want to avoid manipulating bitmap data within a scanline
	at all costs.  To this end, we can use the following facts:

		* A vertical flip involves just switching huge-array
		  scan lines.  Loop through them from first to last,
		  sticking them in the destination huge-array in
	  	  reverse order.  Not too hard.

		* A horizontal flip is accomplished by applying a (-1)
		  scale to the gstate and drawing the bitmap through
	  	  it.  Then we translate the origin along the bitmap so
	  	  that we can see it again.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	1/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlipFormat	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Get the format to flip.
	;
		push	cx				; fliptype
		mov	bp, ds:[di].GDI_fileHandle
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, ds:[di].DBVI_currentFormat
		call	IdGetFormat			; ^vcx:dx = bitmap
	;
	;  Call the appropriate handler routine to give us the
	;  new rotated (or flipped) bitmap.
	;
		pop	bx				; FormatRotateType
		mov	bx, cs:[flipTable][bx]		; bx = handler offset
		call	bx				; ^vcx:dx = new bitmap
	;
	;  Now take the new bitmap and store it away.  Also do all
	;  that VisMonikerListEntry stuff.  The new format has the
	;  exact same format parameters as the old one, so get them.
	;
		mov	bp, ds:[di].GDI_fileHandle
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, ds:[di].DBVI_currentFormat
		push	cx
		call	IdGetFormatParameters		; cx = VMLET record
		mov	si, cx
		pop	cx				; ^vcx:dx = bitmap
	;
	;  Set the new format & parameters into the database.
	;
		call	IdClearAndSetFormat		; frees old bitmap
		mov	dx, 1				; custom parameters
		mov	cx, si				; VMLET
		call	IdSetFormatParameters

		.leave
		ret

flipTable	nptr	\
		offset	DoHorizontalFlip,
		offset	DoVerticalFlip,
		offset	Do90DegreeRotate,
		offset	Do180DegreeRotate,
		offset	Do270DegreeRotate

FlipFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoHorizontalFlip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes the existing bitmap and flips it horizontally.

CALLED BY:	FlipFormat

PASS:		^vcx:dx = bitmap to flip

RETURN:		^vcx:dx = new rotated bitmap

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	1/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoHorizontalFlip	proc	near
		uses	ax, bx, si, di

		sourceBitmap	local	dword
		destBitmap	local	dword

		.enter

		movdw	sourceBitmap, cxdx		; save it
	;
	;  Create a new bitmap to draw into.
	;
		mov	bx, cx				; file for create
		call	HugeBitmapGetFormatAndDimensions
		push	cx				; width
		ornf	al, mask BMT_MASK
		clr	di, si				; exposure OD
		call	GrCreateBitmap
		movdw	destBitmap, bxax		; save new one
	;
	;  Set up the transformation matrix.
	;
		mov	dx, -1			; x-scale integer
		mov	bx, 1			; y-scale integer
		clr	cx, ax			; fractional parts
		call	GrApplyScale

		pop	dx			; width
		neg	dx			; x
		clr	cx, ax, bx		; fractional parts
		call	GrApplyTranslation
	;
	;  Draw the source bitmap through the GState.
	;
		movdw	dxcx, sourceBitmap
		call	BitmapDrawFillCommon
	;
	;  Return the destination bitmap.
	;
		movdw	cxdx, destBitmap
		
		.leave
		ret
DoHorizontalFlip	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoVerticalFlip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flip a bitmap vertically.

CALLED BY:	FlipFormat

PASS:		^vcx:dx = source huge array

RETURN:		^vcx:dx = dest huge array
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	For each element in source (going from first to last)
	deref element, point to data, replace in destination
	(going from last to first).

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	1/ 7/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoVerticalFlip	proc	near
		uses	ax,bx,si,di,bp,ds

		sourceArray	local	dword
		destArray	local	dword
		destCount	local	word

		.enter

		movdw	sourceArray, cxdx	; save source
		movdw	bxax, cxdx		; ^vbx:ax = bitmap
	;
	;  Create a destination huge array, same size as source.
	;
		push	bp
		clr	bp			; no DB items
		mov	dx, bx			; dest file = source file
		call	VMCopyVMChain		; ax = new handle
		pop	bp
		movdw	destArray, dxax		; dest is now identical
	;
	;  Set up the loop to copy source -> dest.
	;
		movdw	bxdi, sourceArray
		call	HugeArrayGetCount	; ax = #elements
		dec	ax			; 0-indexed arrays

		mov	destCount, ax		; start at the end
	;
	;  Since it's impossible to create a bitmap of height zero,
	;  we can assume that there's at least one element.
	;
		clr	dx, ax			; lock first element
		call	HugeArrayLock		; ds:si = first elem. in source
EC <		tst	ax						>
EC <		ERROR_Z CANT_FLIP_BITMAP_OF_HEIGHT_ZERO			>

		mov	cx, 1			; always replace 1 element
		movdw	bxdi, destArray		; invariant
elementLoop:
	;
	;  Replace an element in the destination array with the data
	;  pointed to by ds:si.
	;
		mov	ax, destCount		; element to replace
		push	bp			; locals
		mov	bp, ds			; bp.si = data
		clr	dx			; high word of element number
		call	HugeArrayReplace
		pop	bp
	;
	;  Get to the next element in the source array.
	;
		call	HugeArrayNext		; ds:si = next element
		tst	ax			; any more elements?
		jz	done
	;
	;  Get to the previous element in the destination array.
	;
		dec	destCount		; previous element in dest
		jmp	elementLoop
done:
	;
	;  Unlock the last HugeArray element and return the new bitmap.
	;
		call	HugeArrayUnlock
		movdw	cxdx, destArray
		
		.leave
		ret
DoVerticalFlip	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Do90DegreeRotate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rotate the format 90 degrees clockwise.

CALLED BY:	FlipFormat

PASS:		^vcx:dx	= bitmap to rotate

RETURN:		^vcx:dx	= (new) rotated bitmap

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Before:

		+---------------+
		|		|
		|		|
		+---------------+

	After:

		+-----+
		|     |
		|     |
		|     |
		|     |
		|     |
		|     |
		+-----+

	We need to translate the origin to the left by the width
	of the new bitmap (height of the old one) to make it work.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/ 6/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Do90DegreeRotate	proc	near
		uses	ax, bx, si, di
if 0
		sourceBitmap	local	dword
		destBitmap	local	dword
endif
		.enter
if 0
	;
	;  Create a new bitmap to draw into.  Swap width & height
	;  because we're rotating 90 degrees.
	;
		movdw	sourceBitmap, cxdx		; save it
		mov	bx, cx				; file for create
		call	HugeBitmapGetFormatAndDimensions; cx=width,dx=height
		xchg	cx, dx				; cx=height,dx=width
		push	cx				; save old height
		ornf	al, mask BMT_MASK
		clr	di, si				; exposure OD
		call	GrCreateBitmap
		movdw	destBitmap, bxax		; save new one
	;
	;  Set up the transformation matrix.
	;
		mov	dx, -90			; angle (ccw)
		clr	cx			; angle fraction
		call	GrApplyRotation

		pop	dx			; new width (old height)
		neg	dx			; xlat origin left that much
		clr	cx, ax, bx		; fractional parts
		call	GrApplyTranslation
	;
	;  Draw the source bitmap through the GState.
	;
		movdw	dxcx, sourceBitmap
		call	BitmapDrawFillCommon
	;
	;  Return the destination bitmap.
	;
		movdw	cxdx, destBitmap
		jmp	done
endif
	;
	;  Call our temporary routine to hack around the graphics
	;  system's problems.
	;
		call	Flop90Degrees		; ^vcx:dx = new bitmap
done::
		.leave
		ret
Do90DegreeRotate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Do180DegreeRotate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rotate a format 180 degrees.

CALLED BY:	FlipFormat

PASS:		^vcx:dx = source bitmap

RETURN:		^vcx:dx = dest bitmap (creates a new one)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	We need to translate the origin left by the width and
	up by the height to make the bitmap visible.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/ 6/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Do180DegreeRotate	proc	near
		uses	ax, bx, si, di
if 0
		sourceBitmap	local	dword
		destBitmap	local	dword
endif
		.enter
if 0
		movdw	sourceBitmap, cxdx
	;
	;  Create a new bitmap to draw into.
	;
		mov	bx, cx				; file for create
		call	HugeBitmapGetFormatAndDimensions
		push	cx, dx				; width
		ornf	al, mask BMT_MASK
		clr	di, si				; exposure OD
		call	GrCreateBitmap
		movdw	destBitmap, bxax		; save new one
	;
	;  Set up the transformation matrix.
	;
		mov	dx, -1			; x-scale integer
		mov	bx, -1			; y-scale integer
		clr	cx, ax			; fractional parts
		call	GrApplyScale

		pop	dx, bx			; width, height
		neg	dx			; x
		neg	bx			; y
		clr	cx, ax			; fractional parts
		call	GrApplyTranslation
	;
	;  Draw the source bitmap through the GState.
	;
		movdw	dxcx, sourceBitmap
		call	BitmapDrawFillCommon
	;
	;  Return the destination bitmap.
	;
		movdw	cxdx, destBitmap
endif
	;
	;  Hacks, hacks.
	;
		call	DoHorizontalFlip
		movdw	bxax, cxdx
		call	DoVerticalFlip
		push	bp
		clr	bp
		call	VMFreeVMChain
		pop	bp
		
		.leave
		ret
Do180DegreeRotate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Do270DegreeRotate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rotate a format 270 degrees clockwise (90 CCW).

CALLED BY:	FlipFormat

PASS:		^vcx:dx = source format

RETURN:		^vcx:dx = newly-created rotated format

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	We need to translate the origin up by the new height
	for this to work.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/ 6/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Do270DegreeRotate	proc	near
		uses	ax, bx, bp
		.enter
	;
	;  First call our hack routine to hand-rotate it 90 degrees.
	;  Since we have a 2-step process we have to free the
	;  intermediate bitmap returned by Flop90Degrees after we're
	;  done with it.
	;
		call	Flop90Degrees
	;
	;  Now add another 180 degrees and we're all set.
	;
		movdw	bxax, cxdx
		call	Do180DegreeRotate
	;
	;  Free the intermediate bitmap.
	;
		clr	bp
		call	VMFreeVMChain

		.leave
		ret
Do270DegreeRotate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapDrawFillCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the source bitmap to the destination gstate,
		set the mask bits, and kill the gstate & window.

CALLED BY:	INTERNAL

PASS:		^vdx:cx = source bitmap
		di	= gstate

RETURN:		nothing (draws to passed gstate)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/ 6/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapDrawFillCommon	proc	near
		uses	ax, bx, cx, dx, si, di
		.enter
	;
	;  Draw source -> dest.
	;
		clr	ax, bx
		call	GrDrawHugeBitmap
	;
	;  Set bitmap mode for editing mask bits in destination.
	;
		push	dx
		clr	dx			; no color transfer info
		mov	ax, mask BM_EDIT_MASK
		call	GrSetBitmapMode
		pop	dx			; ^vcx:dx = bitmap
	;
	;  Set the mask bits in the destination.
	;
		clr	ax, bx
		call	GrFillHugeBitmap
	;
	;  Kill temp window & gstate without destroying dest. bitmap.
	;
		mov	al, BMD_LEAVE_DATA
		call	GrDestroyBitmap		; scratch gstate & window

		.leave
		ret
BitmapDrawFillCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Flop90Degrees
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rotate a huge bitmap 90 degrees clockwise.

CALLED BY:	Do90DegreeRotate, Do270DegreeRotate

PASS:		^vcx:dx = bitmap

RETURN:		^vcx:dx = new bitmap

DESTROYED:	nothing


KNOWN BUGS/SIDE EFFECTS/IDEAS:

	Do this ONLY for 16-color bitmaps, and ONLY because there's
	a bug in the graphics system somewhere that causes huge
	bitmaps to acquire a black area-mask pattern after being
	rotated.

PSEUDO CODE/STRATEGY:

	create new bitmap of mxn (original is nxm) dimensions

	for i = 0 to sourceHeight {
	  for j = 0 to sourceWidth {
	    GetPixel(i, j, source)
	    SetPixel(j, i, destination)
	  }
	}

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/16/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Flop90Degrees	proc	near
		uses	ax,bx,si,di,bp,ds

		sourceWidth		local	word
		destWidth		local	word
		sourceHeight		local	word
		sourceMaskWidth		local	word
		destMaskWidth		local	word
		flipArgs		local	FormatRotateArgs
		
		.enter
	;
	;  Create the destination bitmap.
	;
		movdw	ss:flipArgs.FRA_source, cxdx
		mov	bx, cx				; file handle
		call	HugeBitmapGetFormatAndDimensions
		push	ax				; save BMFormat
		mov	sourceWidth, cx
		mov	sourceHeight, dx
		mov	destWidth, dx
		xchg	cx, dx				; swap height & width
		clr	di, si
		ornf	al, mask BMT_MASK
		call	GrCreateBitmap			; ^vbx:ax = bitmap
		movdw	ss:flipArgs.FRA_dest, bxax
	;
	;  Kill temp window & gstate without destroying the
	;  destination bitmap data.
	;
		mov	al, BMD_LEAVE_DATA
		call	GrDestroyBitmap		; scratch gstate & window
	;
	;  Calculate the mask sizes of the source & destination
	;  (in bytes).
	;
		mov	ax, sourceWidth
		add	ax, 7
		shr	ax, 1
		shr	ax, 1
		shr	ax, 1
		mov	sourceMaskWidth, ax

		mov	ax, destWidth
		add	ax, 7
		shr	ax, 1
		shr	ax, 1
		shr	ax, 1
		mov	destMaskWidth, ax
	;
	;  Do either mono or color.
	;
		pop	ax				; al = BMFormat
		cmp	al, BMF_4BIT
		je	color4

		call	Flop90Mono
		jmp	done
color4:
	;
	;  Rotate the mask.
	;
		call	FlopMask
	;
	;  Rotate the data.
	;
		clr	ss:flipArgs.FRA_row		
		clr	ss:flipArgs.FRA_column
outerLoop:
	;
	;  The outermost loop is to go through the scanlines
	;  of the source, one by one, and do something with
	;  them.  If we're at the height of the source bitmap,
	;  exit.
	;
		mov	ax, ss:sourceHeight
		cmp	ss:flipArgs.FRA_row, ax
		je	doneLoop
innerLoop:
	;
	;  The inner loop is to go through the pixels of the
	;  source and place them in the destination.
	;
		call	GetPixel
		mov	ss:flipArgs.FRA_color, al
		call	SetPixel
	;
	;  Increment the column count.  If we're at the width
	;  of the source, jmp to outerLoop (meaning we finished
	;  this scanline), else jump to innerLoop to process
	;  more pixels.
	;
		inc	ss:flipArgs.FRA_column
		mov	ax, ss:sourceWidth
		cmp	ss:flipArgs.FRA_column, ax
		jb	innerLoop

		clr	ss:flipArgs.FRA_column		; finished line
		inc	ss:flipArgs.FRA_row		; do next line
		jmp	outerLoop
doneLoop:
done:
	;
	;  We've set all the pixels in the destination.  Return it.
	;
		movdw	cxdx, ss:flipArgs.FRA_dest
		
		.leave
		ret
Flop90Degrees	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPixel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a pixel from a 16-color huge array.

CALLED BY:	Flop90Degrees

PASS:		ss:[bp]	= inherited stack frame from Flop90Degrees

RETURN:		al = pixel (color)

DESTROYED:	bx, cx, dx, si, di, ds

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/16/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPixel	proc	near
		.enter	inherit	Flop90Degrees
	;
	;  Lock the requested element and skip the mask data.
	;
		clr	dx
		mov	ax, ss:flipArgs.FRA_row		; row = scanline
		movdw	bxdi, ss:flipArgs.FRA_source
		call	HugeArrayLock			; ds:si = element
		add	si, ss:sourceMaskWidth		; ds:si = data
	;
	;  Pixel (i) in the row is found in byte (i/2). (This
	;  is using 0-indexed pixels).
	;
		mov	dx, ss:flipArgs.FRA_column	; pixel (i)
		shr	dx				; byte (i/2)
		lahf
		add	si, dx				; ds:si = byte to get
		sahf
	;
	;  Grab the byte.  If the carry flag is set (meaning we
	;  lost precision when we shifted), it means we need the
	;  low nibble of the byte.
	;
		lodsb					; al = byte
		jc	lowNibble
		shr	al
		shr	al
		shr	al
		shr	al				; al = high nibble
		jmp	gotNibble
lowNibble:
		andnf	al, 00001111b			; isolate low nibble
gotNibble:
	;
	;  Unlock the requested element.
	;
		call	HugeArrayUnlock
		
		.leave
		ret
GetPixel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPixel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the specified pixel in a huge bitmap.

CALLED BY:	Flop90Degrees

PASS:		ss:[bp]	= inherited stack frame from Flop90Degrees

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, ds

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/16/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPixel	proc	near
		.enter	inherit Flop90Degrees
	;
	;  Lock the requested scanline (row) and skip the mask bits.
	;
		clr	dx
		mov	ax, ss:flipArgs.FRA_column	; row = scanline
		movdw	bxdi, ss:flipArgs.FRA_dest
		call	HugeArrayLock			; ds:si = element
		add	si, ss:destMaskWidth		; ds:si = data
	;
	;  Pixel (i) in the row is found in byte (i/2). (This
	;  is using 0-indexed pixels).
	;
		mov	dx, ss:destWidth
		dec	dx				; 0-indexed
		sub	dx, ss:flipArgs.FRA_row		; pixel (i)
		shr	dx				; byte (i/2)
		lahf
		add	si, dx				; ds:si = byte to get
		sahf
	;
	;  Grab the byte to modify.  If the carry is set we
	;  need to change the low nibble, otherwise the high
	;  nibble.  Note that mov, lodsb and dec do not change
	;  the state of the carry flag.
	;
		mov	dl, ss:flipArgs.FRA_color
		lodsb					; al = byte
		dec	si				; back up!
		jc	lowNibble
	;
	;  Set the color in the high nibble.
	;
		andnf	al, 00001111b			; clear prev. color
		shl	dl
		shl	dl
		shl	dl
		shl	dl				; dl.high = color
		ornf	al, dl
		jmp	setColor
lowNibble:
		andnf	al, 11110000b			; clear prev. color
		ornf	al, dl
setColor:
		mov	{byte} ds:[si], al
	;
	;  Unlock the element.
	;
		call	HugeArrayUnlock

		.leave
		ret
SetPixel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlopMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rotate a mono bitmap (or mask) 90 degrees clockwise.

CALLED BY:	Flop90Degrees, Flop90Mono

PASS:		ss:[bp]	= inherited stack frame from Flop90Degrees

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	for i = 0 to sourceHeight-1 do
	  for j = 0 to sourceWidth-1 do
	    get mask bit (i, j, source)
	    set mask bit (j, sourceHeight-1-i, destination)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/16/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FlopMask	proc	near
		uses	ax
		.enter	inherit	Flop90Degrees
	;
	;  Set the flags so that GetMaskBit and SetMaskBit operate
	;  on the mask instead of the data.
	;
		BitSet	ss:flipArgs.FRA_flags, FRF_DOING_MASK
		clr	ss:flipArgs.FRA_row
		clr	ss:flipArgs.FRA_column
outerLoop:
	;
	;  The outermost loop is to go through the scanlines
	;  of the source, one by one, and do something with
	;  them.  If we're at the height of the source bitmap,
	;  exit.
	;
		mov	ax, ss:sourceHeight
		cmp	ss:flipArgs.FRA_row, ax
		je	doneLoop
innerLoop:
	;
	;  The inner loop is to go through the mask bits of the
	;  source and place them in the destination.
	;
		call	GetMaskBit
		mov	ss:flipArgs.FRA_color, al
		call	SetMaskBit
	;
	;  Increment the column count.  If we're at the width
	;  of the source, jmp to outerLoop (meaning we finished
	;  this scanline), else jump to innerLoop to process
	;  more pixels.
	;
		inc	ss:flipArgs.FRA_column
		mov	ax, ss:sourceWidth
		cmp	ss:flipArgs.FRA_column, ax
		jb	innerLoop

		clr	ss:flipArgs.FRA_column		; finished line
		inc	ss:flipArgs.FRA_row		; do next line
		jmp	outerLoop
doneLoop:
		.leave
		ret
FlopMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMaskBit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return mask bit from position (row, column) in source.

CALLED BY:	FlopMask

PASS:		ss:[bp]	= inherited stack frame from Flop90Degrees

RETURN:		al = 1 (mask bit set) or 0 (mask bit clear)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/16/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMaskBit	proc	near
		uses	bx,cx,dx,si,di,ds
		.enter	inherit FlopMask
	;
	;  Lock the requested element.
	;
		clr	dx
		mov	ax, ss:flipArgs.FRA_row		; row = scanline
		movdw	bxdi, ss:flipArgs.FRA_source
		call	HugeArrayLock			; ds:si = element
	;
	;  If the FRF_DOING_MASK bit is clear, skip over the
	;  mask data.
	;
		test	ss:flipArgs.FRA_flags, mask FRF_DOING_MASK
		jnz	doneSkip
		add	si, ss:sourceMaskWidth
doneSkip:
	;
	;  Find out which byte of the mask in which to look.  This
	;  is accomplished by dividing the column by 8 (integer
	;  division).  Columns 0-7 are in byte 0, 8-15 in 1, etc.
	;
		mov	dx, ss:flipArgs.FRA_column
		shr	dx
		shr	dx
		shr	dx				; ax = mask byte
	;
	;  Get the mask byte from the mask.
	;
		add	si, dx
		lodsb					; al = byte
	;
	;  Now rotate the bit we want into the least
	;  significant position.  We rotate left to make
	;  things easy:  rotate once for column 0, twice for
	;  column 1, etc.  We get the column by subtracting
	;  8*(number of mask bytes that preceded this one)
	;  from the column number.  So column 18, for example,
	;  is in mask byte 2, and 2 mask bytes preceded 2 (0 & 1),
	;  so we have mask bit = 18 - 8*2 = 2.  It's right;
	;  trust me.  Also dx happens to be the number of
	;  mask bytes that preceded the target mask byte.
	;
		mov	cx, ss:flipArgs.FRA_column
		shl	dx				; mask byte * 2
		shl	dx				; mask byte * 4
		shl	dx				; mask byte * 8
		sub	cx, dx				; cl = which mask bit
		inc	cl				; rotate 1-8 bits
		rol	al, cl				; LSB = mask bit value
		andnf	al, 00000001b			; isolate mask bit
		call	HugeArrayUnlock

		.leave
		ret
GetMaskBit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMaskBit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a mask bit in the destination bitmap.

CALLED BY:	FlopMask

PASS:		ss:[bp]	= inherited stack frame from FlopMask

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/16/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMaskBit	proc	near
		uses	ax,bx,cx,dx,si,di,ds
		.enter	inherit FlopMask
	;
	;  Lock the requested element.  Whatever column we're
	;  on in the source is the row we're on in the destination.
	;
		clr	dx
		mov	ax, ss:flipArgs.FRA_column	; row = scanline
		movdw	bxdi, ss:flipArgs.FRA_dest
		call	HugeArrayLock			; ds:si = element
	;
	;  If the FRF_DOING_MASK bit is clear, skip over the
	;  mask data.
	;
		test	ss:flipArgs.FRA_flags, mask FRF_DOING_MASK
		jnz	doneSkip
		add	si, ss:destMaskWidth
doneSkip:
	;
	;  Figure out in which mask byte we're setting a bit.
	;  This is accomplished by taking the column in the
	;  destination (destWidth-1-FRA_row) and integer-dividing
	;  it by 8.
	;
		mov	dx, ss:destWidth
		dec	dx				; 0-indexed
		sub	dx, ss:flipArgs.FRA_row		; dx = column
		shr	dx
		shr	dx
		shr	dx				; dx = mask byte
	;
	;  Get the mask byte from the destination.
	;
		add	si, dx
		lodsb					; al = mask byte
		dec	si				; back up!
	;
	;  Figure out which bit we're setting.  This means taking
	;  the destination column (destWidth-1-FRA_row) and subtracting
	;  from it 8 * number of mask bytes preceding this one (that
	;  number conveniently in dx right now).
	;
		mov	cx, ss:destWidth
		dec	cx				; cx = 0 to destWidth-1
		sub	cx, ss:flipArgs.FRA_row
		shl	dx				; mask byte * 2
		shl	dx				; mask byte * 4
		shl	dx				; mask byte * 8
		sub	cx, dx				; cl = which mask bit
	;
	;  Make dl the "mask register" by setting it to 80h and then
	;  shifting it right by cl (0-7).  So if we want the 7th bit
	;  in the mask byte, dl gets shifted right 7 times, etc.
	;
		mov	dl, 10000000b
		shr	dl, cl				; dl = "mask register"
	;
	;  Clear the bit in the mask byte (al) we're about to
	;  set/clear.
	;
		not	dl
		andnf	al, dl				; clear mask bit
	;
	;  If ss:flipArgs.FRA_color is zero, we're done, since
	;  we wanted the bit to be clear.  If FRA_color is 1,
	;  then we set the bit.
	;
		tst	ss:flipArgs.FRA_color
		jz	done

		not	dl
		ornf	al, dl
done:
	;
	;  We now have the new mask byte in al -- store it in
	;  the destination (pointed to by ds:si).
	;
		mov	{byte} ds:[si], al
		call	HugeArrayUnlock
		
		.leave
		ret
SetMaskBit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Flop90Mono
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rotate a monochrome bitmap 90 degrees clockwise.

CALLED BY:	Do90DegreeRotate

PASS:		^vcx:dx = bitmap

RETURN:		^vcx:dx = new bitmap

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/17/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Flop90Mono	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter	inherit	Flop90Degrees
	;
	;  First translate the mask data.
	;
		call	FlopMask
	;
	;  Now loop through the bits, rotating them.
	;
		BitClr	ss:flipArgs.FRA_flags, FRF_DOING_MASK
		clr	ss:flipArgs.FRA_row
		clr	ss:flipArgs.FRA_column
outerLoop:
	;
	;  The outermost loop is to go through the scanlines
	;  of the source, one by one, and do something with
	;  them.  If we're at the height of the source bitmap,
	;  exit.
	;
		mov	ax, ss:sourceHeight
		cmp	ss:flipArgs.FRA_row, ax
		je	doneLoop
innerLoop:
	;
	;  The inner loop is to go through the mask bits of the
	;  source and place them in the destination.
	;
		call	GetMaskBit
		mov	ss:flipArgs.FRA_color, al
		call	SetMaskBit
	;
	;  Increment the column count.  If we're at the width
	;  of the source, jmp to outerLoop (meaning we finished
	;  this scanline), else jump to innerLoop to process
	;  more pixels.
	;
		inc	ss:flipArgs.FRA_column
		mov	ax, ss:sourceWidth
		cmp	ss:flipArgs.FRA_column, ax
		jb	innerLoop

		clr	ss:flipArgs.FRA_column		; finished line
		inc	ss:flipArgs.FRA_row		; do next line
		jmp	outerLoop
doneLoop:
		.leave
		ret
Flop90Mono	endp


FormatCode	ends
