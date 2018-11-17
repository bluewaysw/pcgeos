COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	icon editor	
MODULE:		Document
FILE:		documentUtils.asm

AUTHOR:		Steve Yegge, Oct 27, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT JohnCreateMonikerFromBitmap 
				Takes a huge bitmap and makes a vismoniker
				out of it.

    INT StuffVisMonikerHeader   Takes the header structure in idata and
				fills it correctly.

    INT JimStuffVisMonikerHeader 
				Takes the header structure in idata and
				fills it correctly.

    INT CopyBitmapToChunk       Copies the bitmap from the huge array into
				the chunk

    INT StuffBitmapHeader       sets the height,width,compaction and format
				in the bitmap header for the new moniker

    INT JimCreateMonikerFromIconData 
				Takes an icon in the database and makes a
				VisMoniker out of it.

    GLB SimpleBitmapToHugeBitmap 
				Converts a simple bitmap into a huge bitmap

    GLB HugeBitmapToSimpleBitmap 
				Converts a huge-bitmap (<64k) into a
				regular bitmap on an lmem heap.

    GLB HugeBitmapGetSizeInBytes 
				Returns the total number of bytes (data
				only) in the bitmap.

    GLB HugeBitmapGetFormatAndDimensions 
				Returns width & height of a huge bitmap,
				and the BMFormat

    GLB DiscardVMChain          Discards the blocks of a VM chain and frees
				up the handles.

    GLB DiscardVMBlock          Discard an individual vm block.

    EXT DisplayError            Display an error in a UserStandardDialog

    EXT DisplayNotification     Pops up a notification dialog box for the
				user to close :)

    EXT DisplayQuestion         Pops up a question dialog box for the user
				to reply YES or NO to.

    EXT DisplayQuestionMultipleResponse 
				Pops up a question dialog box for the user
				to reply YES, NO, or CANCEL.

    EXT LockStringResource      Locks a string resource and returns a
				pointer to the string

    EXT UnlockStringResource    Unlocks a string resource that was locked
				using LockStringResource

    GLB DisplaySaveChangesYesNo Put up a special multiple-response dialog.

    GLB IconMarkBusy            Marks the app as busy.

    GLB IconMarkNotBusy         Marks the app as not busy.

    GLB CheckHugeArrayBitmapCompaction 
				Check to see if the bitmap is compacted

    INT IVMInfoVMChain          returns the number of blocks in vm chain,
				and the total size of the chain in bytes

    INT VMInfoVMChainLow        recursivly gets size and block count for a
				vm chain

    GLB IDBInfo                 Fetch salient info about a DB item

    INT StripMaskDataFromBitmap Removes the mask bits from the bitmap.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/27/92   	Initial revision

DESCRIPTION:
	
	This file contains many utility routines used by other modules.

	$Id: documentUtils.asm,v 1.1 97/04/04 16:06:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata		segment

;-----------------------------------------------------------------------------
;
;  Here are the declarations necessary for creating a vismoniker
;  on the fly and stuffing bitmap data into it.
;
;-----------------------------------------------------------------------------

VMH	label 	VisMoniker
	VisMoniker < <0,1,DAR_NORMAL,DC_COLOR_4>, , >

VMGS	label	VisMonikerGString
	VisMonikerGString < >
	GSBeginString			; this is a macro -- takes no space
		
DBCP	label	OpDrawBitmapAtCP
	OpDrawBitmapAtCP	<>
		
VMH_SIZE	equ $ - VMH
		
VMT	label	byte
	GSEndString

VMT_SIZE	equ $ - VMT
		
;-----------------------------------------------------------------------------
		
idata		ends
		
DocumentCode	segment	resource
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JohnCreateMonikerFromBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes a huge bitmap and makes a vismoniker out of it.

CALLED BY:	INTERNAL

PASS:		es = dgroup	(for getting the huge array & vm file handles)
		bx = block handle of LMem Heap to use for moniker (0 for new)
		^vcx:dx = huge bitmap to convert

RETURN:		^lcx:dx = optr to new vismoniker
		carry set if error (bitmap too big or not enough mem)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	This is approach #1 to making a moniker from a bitmap.
	This approach allocates a chunk big enough for bitmap
	+ header + tail.  Then it fills the header, moves the
	bits of the bitmap into the chunk, and initializes the
	tail.  Invented by John Wedgwood.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JohnCreateMonikerFromBitmap	proc	far
		uses	ax,bx,si,di,bp,ds,es
		.enter
	;
	;  Don't even try to do this unless it's a safe size.
	;
		push	bx, cx, dx
		call	HugeBitmapGetSizeInBytes
		tst	dx
		jnz	errorPop3
		cmp	ax, MAX_SAFE_MONIKER_SIZE
		ja	errorPop3
		pop	bx, cx, dx
	;
	;  It's safe -- go for it.
	;
		push	cx			; save bitmap file handle
		tst	bx
		jnz	gotBlock
	;
	;  Allocate a block to hold the moniker chunk.
	;
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx			; header size
		call	MemAllocLMem		; returns bx = block handle
		jc	errorPop		; error
gotBlock:
	;
	;  Allocate a chunk for the vismoniker
	;  note that bitmapSize must include the bitmap header
	;
		call	MemLock			; lock the block for alloc
		mov	ds, ax
		clr	al			; object flags
		mov	cx, (VMH_SIZE + VMT_SIZE) 	; initial space to alloc
		call	LMemAlloc		; returns handle in ax
		call	MemUnlock
	;
	;  stuff the idata header structure with the appropriate values
	;
		pop	cx			; restore bitmap file handle
		call	StuffVisMonikerHeader	; stuffs the struct in idata
		mov	di, ax			; di <- chunk handle
	;
	;  now move header and tail into the chunk
	;
		call	MemLock			; lock the block
		mov	ds, ax
		
		push	di, cx			; save chunk and vm file handles
		segxchg	ds, es			; ds <- dgroup, es <- chunk seg.
		mov	di, es:[di]		; dereference chunk 
		mov	cx, (VMH_SIZE + VMT_SIZE)	; #bytes to move
		mov	si, offset VMH		; ds:si <- idata header
		rep	movsb
		pop	ax, cx			; restore chunk and vm handles
	;
	;  Copy the bitmap data into the chunk
	;
		call	CopyBitmapToChunk
	;
	;  Unlock the block and set up return values (bx hasn't changed)
	;
		call	MemUnlock
		
		mov	cx, bx			; ^lcx:dx = optr to moniker
		mov	dx, ax
		clc				; return no error
		jmp	short	done
errorPop3:
		pop	cx, dx
errorPop:
		add	sp, 2			; restore sp
error::
		stc
done:
		.leave
		ret
JohnCreateMonikerFromBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffVisMonikerHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes the header structure in idata and fills it correctly.

CALLED BY:	JohnCreateMonikerFromBitmap

PASS:		es = dgroup
		cx = vm file handle
		dx = vm block handle

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
	Lock the vm block and find all the necessary parameters from
	the CBitmap that comes just after the HugeArrayDirectory.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StuffVisMonikerHeader	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
	;
	;  Lock the block and point ds:si to the CBitmap structure
	;
		mov	bx, cx			; vm file handle
		mov	ax, dx			; vm block handle
		call	VMLock
		mov	ds, ax
	;
	;  Get the width and height, and put in idata header
	;
		mov	ax, ds:[(size HugeArrayDirectory)].CB_simple.B_width
		mov	{word} es:VMH.VM_width, ax
		mov	ax, ds:[(size HugeArrayDirectory)].CB_simple.B_height
		mov	{word} es:VMGS.VMGS_height, ax
	;
	;  Get the color scheme
	;
		mov	ah, ds:[(size HugeArrayDirectory)].CB_simple.B_type
		and	ah, mask BM_FORMAT
		cmp	ah, BMF_MONO
		je	mono
		cmp	ah, BMF_4BIT
		je	bit4
		mov	es:VMH.VM_type, (mask VMT_GSTRING) or DC_COLOR_8
		jmp	short	doneColor
bit4:
		mov	es:VMH.VM_type, (mask VMT_GSTRING) or DC_COLOR_4
		jmp	short	doneColor
mono:
		mov	es:VMH.VM_type, (mask VMT_GSTRING) or DC_GRAY_1
doneColor:
	;
	;  Unlock the block and re-lock using HugeArrayLock
	;
		call	VMUnlock
		mov	di, dx			; huge array handle
		clrdw	dxax			; dereference 1st element
		call	HugeArrayLock		; returns size in dx
	;
	;  Get the number of bytes in the huge array, and store into idata
	;
		mov	cx, dx			; cx <- element size
		call	HugeArrayUnlock
		call	HugeArrayGetCount	; ax <- # elements
		
		mul	cx			; dx.ax <- # bytes (< 64k)
		add	ax, size Bitmap		; size includes bitmap header
		mov	es:DBCP.ODBCP_size, ax
		
		.leave
		ret
StuffVisMonikerHeader	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JimStuffVisMonikerHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes the header structure in idata and fills it correctly.

CALLED BY:	JimCreateMonikerFromIconData
PASS:		cx = vm file handle
		dx = vm block handle
		ax = chunk for moniker
		ds = segment for moniker
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		
	This is approach #2 to creating a moniker from a bitmap.
	It creates a GString, calls GrDrawHugeBitmapAtCP, and
	GrEndGString.  It then destroys the gstate, leaving the
	data in the chunk, and pre-pends a vismoniker header at
	the front of the chunk.  It doesn't work.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	This procedure is commented out until further notice.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
JimStuffVisMonikerHeader	proc	near
	uses	ax,bx,cx,dx,si,di,ds,es
	.enter

	;
	;  Lock the vm block and point ds:si to the CBitmap structure
	;

	segmov	es, ds				; es <- moniker segment	
	mov	di, ax				; di <- chunk handle for later
	mov	bx, cx				; vm file handle
	mov	ax, dx				; vm block handle
	call	VMLock
	mov	ds, ax
	
	;
	;  Get the width and height, and store in VisMoniker header
	;

	mov	di, es:[di]			; dereference chunk
	mov	ax, di				; ax saves chunk handle
	mov	bx, ds:[(size HugeArrayDirectory)].CB_simple.B_width
	mov	es:[di].VM_width, bx
	mov	bx, ds:[(size HugeArrayDirectory)].CB_simple.B_height
	lea	di, es:[di].VM_data
	mov	es:[di].VMGS_height, bx

	;
	;  Get the color scheme
	;

	mov	di, ax				; di <- chunk handle
	mov	di, es:[di]			; dereference chunk
	mov	ah, ds:[(size HugeArrayDirectory)].CB_simple.B_type
	and	ah, mask BM_FORMAT
	cmp	ah, BMF_MONO
	je	mono
	mov	es:[di].VM_type, (mask VMT_GSTRING) or DC_COLOR_4
	jmp	short	doneColor
mono:
	mov	es:[di].VM_type, (mask VMT_GSTRING) or DC_GRAY_1

doneColor:
	;
	;  Unlock the block and re-lock using HugeArrayLock
	;

	call	VMUnlock
;	mov	di, dx				; huge array handle
;	clrdw	dxax				; dereference 1st element
;	call	HugeArrayLock			; returns size in dx
	
	;
	;  Get the number of bytes in the huge array, and store into idata
	;

;	mov	cx, dx				; cx <- element size
;	call	HugeArrayUnlock
;	call	HugeArrayGetCount		; ax <- # elements
	
;	mul	cx				; dx.ax <- # bytes (< 64k)
;	mov	es:DBCP.ODBCP_size, ax

	.leave
	ret
JimStuffVisMonikerHeader	endp@
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyBitmapToChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies the bitmap from the huge array into the chunk

CALLED BY:	JohnCreateMonikerFromBitmap

PASS:		es = segment of lmem heap
		ax = chunk
		cx = vm file handle
		dx = vm block handle

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	es will almost certainly change from the insert

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyBitmapToChunk	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
	;
	;  First find out how big the bitmap is and insert that many bytes
	;  (get the information from the idata header structure--it's fast)
	;
		push	cx			; save vm file handle
		mov	cx, ds:DBCP.ODBCP_size	; # bytes to insert
		mov	bx, VMH_SIZE		; offset into chunk
		segmov	ds, es			; ds <- segment of lmem heap
		call	LMemInsertAt		; ds = es after call
		pop	bx			; bx <- vm file handle
		push	ax			; save chunk handle
		
		call	StuffBitmapHeader
	;
	;  Lock the huge array and loop using HugeArrayNext
	;
		mov	di, dx			; vm block handle
		clrdw	dxax			; dereference 1st element
		call	HugeArrayLock		; returns ds:si = element,
		mov	bp, dx			; bp keeps the size
	;	
	;  dereference the chunk and move di to starting position
	;
		pop	di			; di <- chunk handle
		mov	di, es:[di]		; dereference chunk	
		add	di, VMH_SIZE + size Bitmap	; start after header
more:
	;
	;  move the element bitmap data into the chunk
	;
		mov	bx, si			; save si for HugeArrayNext
		mov	cx, bp			; size of element
		rep	movsb			; changes cx, si, di
	;	
	;  call HugeArrayNext and loop if necessary
	;
		mov	si, bx			; restore element pointer
		call	HugeArrayNext		; nukes ax, dx
		tst	ax
		jg	more				
		
		call	HugeArrayUnlock
		
		.leave
		ret
CopyBitmapToChunk	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffBitmapHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the height,width,compaction and format in the bitmap
		header for the new moniker

CALLED BY:	CopyBitmapToChunk

PASS:		ax = chunk handle
		es = segment of lmem heap

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StuffBitmapHeader	proc	near
		uses	ax,bx,cx,dx,si,di,ds
		.enter
	;
	;  point ds:si to the (pre-initialized) idata VisMoniker stuff
	;
		GetResourceSegmentNS	dgroup, ds
		mov	si, offset	VMH	; ds:si <- idata vismoniker
		
		mov	di, ax			; di <- chunk handle
		mov	di, es:[di]		; dereference chunk
		add	di, VMH_SIZE		; es:di <- bitmap header
	;
	;  Fill in the bitmap header height and width
	;
		mov	ax, ds:[si].VM_width
		mov	es:[di].B_width, ax	; set bitmap width
		mov	si, offset VMGS
		mov	ax, ds:[si].VMGS_height
		mov	es:[di].B_height, ax	; set bitmap height
	;
	;  Determine the color scheme and set it in the bitmap header
	;
		mov	si, offset VMH
		mov	ah, ds:[si].VM_type
		and	ah, mask VMT_GS_COLOR
		cmp	ah, DC_GRAY_1
		je	mono
		mov	es:[di].B_type, mask BMT_MASK or BMF_4BIT
		jmp	short	doneColor
mono:
		mov	es:[di].B_type, mask BMT_MASK or BMF_MONO
doneColor:
	;
	;  Indicate that the bitmap is uncompacted
	;
		mov	es:[di].B_compact, BMC_UNCOMPACTED
		
		.leave
		ret
StuffBitmapHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JimCreateMonikerFromIconData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes an icon in the database and makes a VisMoniker out of it.

CALLED BY:	internal
PASS:		es = dgroup	(for getting the huge array & vm file handles)
RETURN:		^lcx:dx = optr to new vismoniker
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Takes the bitmap data from the first format in the format
	list, and makes a vismoniker out of it.  This will be
	different later, of course.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	This routine is commented out until further notice.

	This routine will likely be called from lots of places.
	WARNING:  if you change this routine, make sure that es:di
		  is still pointing to the right place for copying
		  the tail from idata to the chunk.

	This routine doesn't work, since I changed the call from 
	CreateLMemBlock to MemAllocLMem.  You're going to have to
	fix it if you want to use it.  (CreateLMemBlock was a routine
	I wrote that did the same as MemAllocLMem but returned the
	block locked).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
JimCreateMonikerFromIconData	proc	near
	uses	ax,bx,si,di,bp,ds,es
	.enter

	;
	;  Query the bitmap object for its bitmap data.
	;

	GetResourceHandleNS	BMO, bx
	mov	si, offset	BMO
	mov	di, mask MF_CALL
	mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
	call	ObjMessage			; returns cx & dx
	xchg	cx, dx			; get them correct for graphics system

	;
	;  create the block and a gstring in it
	;

	mov_tr	ax, cx			; save vm block handle
	call	MemAllocLMem		; returns bx = block handle
	jc	done			; error
	mov	cl, GST_CHUNK		; create an LMem type gstring
	call	GrCreateGString		; si = chunk handle
					; di = GState handle
	mov_tr	cx, ax			; restore vm block
	push	cx, dx			; save the file & block handles

	;
	;  put the bitmap in the gstring and destroy the gstate
	;
	
	mov	bp, si			; free register -> save chunk handle
	call	GrDrawHugeBitmapAtCP	; copy bitmap into chunk
	call	GrEndGString		; put endstring in
	mov	si, di			; put GString handle in si
	clr	di			; (this step will go away soon)
	mov	dl, GSKT_LEAVE_DATA	; don't biff the chunk
	call	GrDestroyGString	; kill the GState, etc.

	;
	;  insert a VisMoniker header structure into the chunk
	;

	push	bx			; save block handle
	call	MemLock			; returns segment in ax
	mov	ds, ax			; ds <- segment
	mov	ax, bp			; ax <- chunk handle
	clr	bx			; insert at beginning
	mov	cx, size VisMoniker + size VisMonikerGString
	call	LMemInsertAt		; ds -> still points at block

	;
	;  Fill in the VisMoniker structures
	;

	pop	bx			; get memory block handle for memunlock
	pop	dx, cx			; restore vm file & block handles
	call	JimStuffVisMonikerHeader

	call	MemUnlock	

	mov	cx, bx				; cx <- block
	mov_tr	dx, ax				; dx <- chunk

done:
	.leave
	ret
JimCreateMonikerFromIconData	endp@
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SimpleBitmapToHugeBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a simple bitmap into a huge bitmap

CALLED BY:	GLOBAL

PASS:		cx = vm file handle for huge bitmap
		ds:si = simple bitmap

RETURN:		^vcx:dx = huge bitmap

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	This routine is untested.  Test me, test me.

PSEUDO CODE/STRATEGY:

	- create a huge array in the passed vm file
	- append an element to the huge array for each scan line
	- move the data from each scan line into the element

	
	For a 4-bit-per-pixel bitmap, the total size per scan line
	in bytes is (size mask + size data).
	
		size mask = (width+7)/8		(really)
		size data = width / 2

	For a monochrome bitmap the size is simply twice the mask
	size.  Oog.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SimpleBitmapToHugeBitmap	proc	far
		uses	ax,bx,cx,si,di,ds,es	; keep "uses cx" in there
		
		bitmapVMFile	local	word	; file handle
		bitmapVMBlock	local	word	; huge-array handle
		
		.enter
		
		mov	bitmapVMFile, cx	; file handle
	;
	;  Figure out how big a scan line is.  First get mask size.
	;
		mov	cx, ds:[si].B_width
		mov	dx, cx			; save width
		
		add	cx, 7			; pad to nearest byte
		shr	cx, 1
		shr	cx, 1
		shr	cx, 1
		
		mov	al, ds:[si].B_type
		and	al, mask BM_FORMAT	; isolate color scheme
		cmp	al, BMF_MONO
		je	monoBitmap
		
		shr	dx			; data size = width/2
		add	cx, dx			; cx = total size
		jmp	short	gotSize
monoBitmap:
		shl	cx			; mask size * 2
gotSize:
		mov	bx, bitmapVMFile
		clr	di			; default header size
		call	HugeArrayCreate
		mov	bitmapVMBlock, di	; huge-array handle
	;
	;  Append (B_height) elements to the huge array.
	;
		push	bp			; save locals
		mov	cx, ds:[si].B_height	; number of elements to append
		clr	bp			; don't initialize elements
		call	HugeArrayAppend
		pop	bp			; restore locals
		
		segmov	es, ds
		mov	di, si			; es:di = bitmap
	;
	;  Lock the first element and set up the loop
	;
		clrdw	dxax			; first element
		mov	bx, bitmapVMFile
		mov	di, bitmapVMBlock
		call	HugeArrayLock		; ds:si = element
elementLoop:		
	;
	;  Now, for each scan line, move the bytes into the element.
	;
		segxchg	es, ds			; es:di = huge array element
		xchg	si, di			; ds:si = simple bitmap
		
		mov	cx, dx			; size of the element
		rep	movsb
		
		segxchg	es, ds			; es:si = huge array element
		xchg	si, di			; ds:si = simple bitmap
		
		add	di, dx			; increment scan-line
		
		call	HugeArrayNext
		tst	ax
		jnz	elementLoop
	;
	;  Unlock last element and return huge array handle
	;
		call	HugeArrayUnlock
		mov	dx, bitmapVMBlock
		
		.leave
		ret
SimpleBitmapToHugeBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeBitmapToSimpleBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a huge-bitmap (<64k) into a regular bitmap on
		an lmem heap.

CALLED BY:	GLOBAL

PASS:		^vcx:dx = huge bitmap

RETURN:		^lcx:dx = optr to simple bitmap
		carry set on error (too big or no memory)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- find out how big the bitmap is
	- allocate a chunk in an lmem heap big enough to hold the bitmap
	- copy the data from the huge-bitmap into the chunk

SIDE EFFECTS:

	WARNING:  This routine will move stuff around on the heap,
		  invalidating your pointers.  Period.

	Don't even think about passing a huge array that's larger
	than 64k.  It'll just return garbage.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/27/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeBitmapToSimpleBitmap	proc	far
		uses	ax,bx,si,di,ds,es
		
		hugeBitmap	local	dword
		bitmapOptr	local	optr
		elemSize	local	word
		
		.enter
	;
	;  Find out how big the huge bitmap is.
	;
		movdw	hugeBitmap, cxdx	; save bitmap
		call	HugeBitmapGetSizeInBytes; returns in dx:ax, and cx
		mov	elemSize, cx		; save element size
		tst	dx			; larger than 64k?
		LONG	jnz	error		; yup
		push	ax			; save total bitmap size
	;
	;  Allocate an lmem heap to hold the simple bitmap
	;
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx			; header size
		call	MemAllocLMem		; returns handle in bx
		mov	bitmapOptr.handle, bx
	;
	;  Allocate a chunk for the simple bitmap.
	;
		call	MemLock
		mov	ds, ax			; ds = simple bitmap block
		pop	cx			; restore total bitmap size
		add	cx, size Bitmap		; make room for header
		clr	al			; object flags
		call	LMemAlloc		; returns handle in ax
		LONG	jc	couldNotAlloc

		mov	bitmapOptr.chunk, ax
		call	MemUnlock
	;
	;  Set up the loop.
	;	
		movdw	bxdi, hugeBitmap
		clrdw	dxax			; lock first element
		call	HugeArrayLock		; ds:si = element
		
		mov	bx, bitmapOptr.handle
		call	MemLock
		mov	es, ax
		mov	di, bitmapOptr.chunk
		mov	di, es:[di]		; es:di = chunk
		add	di, size Bitmap		; skip the header
elemLoop:		
	;
	;  Loop through the elements of the huge bitmap, copying the
	;  data to the chunk.
	;
		mov	bx, si			; save element sptr
		mov	cx, elemSize
		rep	movsb
		mov	si, bx			; restore element sptr
		call	HugeArrayNext		; ds:si = next element
		tst	ax
		jnz	elemLoop
		
		call	HugeArrayUnlock		; unlock last element
	;
	;  Initialize the header for the simple bitmap by directly
	;  copying the header from the huge bitmap (the CB_simple part)
	;  into the header for the simple bitmap.
	;
		movdw	bxdi, hugeBitmap
		call	HugeArrayLockDir
		mov	ds, ax
		lea	si, ds:[(size HugeArrayDirectory)].CB_simple
		mov	cx, size Bitmap
		mov	di, bitmapOptr.chunk
		mov	di, es:[di]		; dereference chunk
		rep	movsb
		call	HugeArrayUnlockDir
	;
	;  Two of the fields set in a huge bitmap are inappropriate for
	;  the simple bitmap, so we clear them here.
	;
		mov	di, bitmapOptr.chunk
		mov	di, es:[di]		; dereference the chunk
		andnf	es:[di].B_type, not mask BMT_HUGE
		andnf	es:[di].B_type, not mask BMT_COMPLEX
	;
	;  unlock the lmem heap and set up return values
	;
		mov	bx, bitmapOptr.handle
		call	MemUnlock
		
		movdw	cxdx, bitmapOptr	; return ^lcx:dx = bitmap
		clc
done:
		.leave
		ret
couldNotAlloc:
 	;
 	;  Oh dear -- there wasn't enough heap space.  Put up a dialog
 	;  saying the operation couldn't complete
 	;
 		mov	si, offset CouldNotAllocateMemoryText
 		call	DisplayError
error:
 		stc
 		jmp	done
HugeBitmapToSimpleBitmap	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeBitmapGetSizeInBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the total number of bytes (data only) in the bitmap.

CALLED BY:	GLOBAL

PASS:		^vcx:dx = bitmap

RETURN:		dx:ax = size of bitmap, in bytes
		cx    = size per element, in bytes

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Get the number of scanlines and the size of each scanline,
	and multiply.

SIDE EFFECTS/IDEAS:

	Should probably have a different routine for compacted
	bitmaps that calls VMInfoVMChain().

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/27/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeBitmapGetSizeInBytes	proc	far
		uses	bx,si,di,ds
		.enter
	;
	;  If it's compacted, don't even think about it.
	;
EC <		movdw	bxax, cxdx					>
EC <		call	CheckHugeArrayBitmapCompaction			>
EC <		ERROR_NZ GRAPHICS_BITMAP_ALREADY_COMPACTED		>
	;
	;  Get the size.
	;
		movdw	bxdi, cxdx
		clrdw	dxax
		call	HugeArrayLock		; returns elem. size in dx
		push	dx
		
		call	HugeArrayUnlock
		call	HugeArrayGetCount	; dx.ax = #elements
		
		pop	dx			; dx <- size per element
		mov	cx, dx			; cx <- size per element
		mul	dx			; dx:ax = #bytes

		.leave
		ret
HugeBitmapGetSizeInBytes	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeBitmapGetFormatAndDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns width & height of a huge bitmap, and the BMFormat

CALLED BY:	GLOBAL

PASS:		^vcx:dx = huge bitmap

RETURN:		cx = width
		dx = height
		al = BMFormat

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/27/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeBitmapGetFormatAndDimensions	proc	far
		uses	bx, di, ds
		.enter
		
		movdw	bxdi, cxdx
		call	HugeArrayLockDir
		mov	ds, ax
		mov	cx, ds:[(size HugeArrayDirectory)].CB_simple.B_width
		mov	dx, ds:[(size HugeArrayDirectory)].CB_simple.B_height
		mov	al, ds:[(size HugeArrayDirectory)].CB_simple.B_type
		call	HugeArrayUnlockDir
		
		clr	ah
		andnf	al, mask BMT_FORMAT
		
		.leave
		ret
HugeBitmapGetFormatAndDimensions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiscardVMChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discards the blocks of a VM chain and frees up the handles.

CALLED BY:	GLOBAL

PASS:		bx	= vm file handle of vm chain to discard
		ax	= vm block handle

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- Walk the VM chain, freeing the memory handle for each block.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	8/24/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiscardVMChain	proc	far
		uses	ax,bx,cx,dx,di,bp,ds
		.enter
freeLoop:
	;
	;  Lock the block & get the handle of the NEXT block.
	;
		mov	cx, ax			; cx = current vm block handle
		call	VMLock			; ax = segment
		mov	ds, ax
		mov	dx, ds:[VMCL_next]	; dx = handle of next block
		call	VMUnlock
	;
	;  Detach the memory block from the VM block.
	;
		mov_tr	ax, cx			; ax = current vm block handle
		clr	cx			; our geode owns it
		call	VMDetach		; di = memory handle
	;
	;  Free the memory block.
	;
		xchg	bx, di			; bx = mem handle
		call	MemFree
		xchg	bx, di			; bx = vm file handle

		mov	ax, dx			; ax = next VM block
		tst	ax
		jnz	freeLoop
doneLoop::
		.leave
		ret
DiscardVMChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiscardVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discard an individual vm block.

CALLED BY:	GLOBAL

PASS:		bx	= vm file handle
		ax	= vm block handle

RETURN:		nothing
DESTROYED:	nothing (mem handle for the vm block is nuked)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	8/27/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiscardVMBlock	proc	far
		uses	ax,bx,cx,di
		.enter

		clr	cx
		call	VMDetach	; nukes ax.  di = memory handle

		mov	bx, di
		call	MemFree

		.leave
		ret
DiscardVMBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display an error in a UserStandardDialog

CALLED BY:	EXTERNAL
PASS:		si	- chunk handle of the error string to display
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayError	proc	far
		uses	ax, bx, si, bp, ds
		.enter
		
		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDP_customFlags, 
		CustomDialogBoxFlags <0, CDT_ERROR, GIT_NOTIFICATION,0>
		
		call	LockStringResource	; ds:si <- string pointer
		
		mov	ss:[bp].SDOP_customString.segment, ds 
		mov	ss:[bp].SDOP_customString.offset, si
		
		clrdw	ss:[bp].SDOP_stringArg1
		clrdw	ss:[bp].SDOP_stringArg2
		clr	ss:[bp].SDP_helpContext.segment
		
		call	UserStandardDialog
		call	UnlockStringResource
		
		.leave
		ret
DisplayError	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pops up a notification dialog box for the user to close :)

CALLED BY:	EXTERNAL
PASS:		si = offset to string resource (notification
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayNotification	proc	far
		uses	ax,si,bp,ds
		.enter
		
		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDP_customFlags, 
		CustomDialogBoxFlags <0, CDT_NOTIFICATION, GIT_NOTIFICATION,0>
		
		call	LockStringResource	; ds:si <- string pointer
		
		mov	ss:[bp].SDOP_customString.segment, ds 
		mov	ss:[bp].SDOP_customString.offset, si
		
		clrdw	ss:[bp].SDOP_stringArg1
		clrdw	ss:[bp].SDOP_stringArg2
		clr	ss:[bp].SDP_helpContext.segment
		
		call	UserStandardDialog
		call	UnlockStringResource
		
		.leave
		ret
DisplayNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayQuestion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pops up a question dialog box for the user to reply YES or
		NO to.

CALLED BY:	EXTERNAL
PASS:		si	- offset to string resource (question)
RETURN:		ax	- IC_YES or IC_NO
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	8/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayQuestion	proc	far
		uses	si,bp,ds
		.enter
		
		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDOP_customFlags, 
		CustomDialogBoxFlags <0, CDT_QUESTION, GIT_AFFIRMATION,0>
		
		call	LockStringResource	; ds:si <- pointer to string
		
		mov	ss:[bp].SDOP_customString.segment, ds
		mov	ss:[bp].SDOP_customString.offset, si
		clrdw	ss:[bp].SDOP_stringArg1
		clrdw	ss:[bp].SDOP_stringArg2
		clr	ss:[bp].SDP_helpContext.segment
		
		call	UserStandardDialog
		call	UnlockStringResource
		
		.leave
		ret
DisplayQuestion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayQuestionMultipleResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pops up a question dialog box for the user to reply YES,
		NO, or CANCEL.

CALLED BY:	EXTERNAL

PASS:		ds	- segment of StandardDialogResponseTriggerTable
		si	- offset to string resource (question)
		di	- offset to StandardDialogResponseTriggerTable

RETURN:		ax	- IC_YES, IC_NO or IC_CANCEL

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	8/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayQuestionMultipleResponse	proc	far
		uses	si, di, ds, bp
		.enter
	;
	;  Make room on stack for StandardDialogParams.
	;
		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDOP_customFlags, 
		CustomDialogBoxFlags <0, CDT_QUESTION, GIT_MULTIPLE_RESPONSE,0>
	;
	;  Initialize the custom triggers.
	;
		mov	ss:[bp].SDOP_customTriggers.segment, ds
		mov	ss:[bp].SDOP_customTriggers.offset, di
	;
	;  Initialize the custom-string.
	;
		call	LockStringResource	; ds:si <- pointer to string
		
		mov	ss:[bp].SDOP_customString.segment, ds
		mov	ss:[bp].SDOP_customString.offset, si
		clrdw	ss:[bp].SDOP_stringArg1
		clrdw	ss:[bp].SDOP_stringArg2
		clr	ss:[bp].SDP_helpContext.segment
	;
	;  Do it.
	;
		call	UserStandardDialog
		call	UnlockStringResource
		
		.leave
		ret
DisplayQuestionMultipleResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockStringResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks a string resource and returns a pointer to the string

CALLED BY:	EXTERNAL

PASS:		si	- Chunk handle of the string
RETURN:		ds:si	- Pointer to string
		ds:LMBH	- Handle of resource
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockStringResource	proc	far
		uses	ax, bx
		.enter
		
		GetResourceHandleNS	IconStrings, bx
		
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]
		
		.leave
		ret
LockStringResource	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockStringResource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlocks a string resource that was locked using
		LockStringResource

CALLED BY:	EXTERNAL
PASS:		ds	- Segment of block containing string
RETURN:		Nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockStringResource	proc	far
		uses	bx
		.enter
		
		mov	bx, ds:LMBH_handle
		call	MemUnlock
		
		.leave
		ret
UnlockStringResource	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplaySaveChangesYesNo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a special multiple-response dialog.

CALLED BY:	GLOBAL

PASS:		si = string to display

RETURN:		ax = response (IC_YES, IC_NO, IC_DIMISS)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/16/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplaySaveChangesYesNo	proc	far
		uses	di, ds
		.enter
	;
	;  Set up the StandardDialogResponseTriggerTable.
	;
		segmov	ds, cs, di
		mov	di, offset SDRT_somethingChangedSaveChanges
		call	DisplayQuestionMultipleResponse	; ax = response

		.leave
		ret

SDRT_somethingChangedSaveChanges label	StandardDialogResponseTriggerTable
	word	3			; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SFD_saveChangesYes,		; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SFD_saveChangesNo,
		IC_NO
	>
	StandardDialogResponseTriggerEntry <
		SFD_cancel,
		IC_DISMISS
	>

DisplaySaveChangesYesNo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconMarkBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Marks the app as busy.

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing (ds fixed up)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/13/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconMarkBusy	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		GetResourceHandleNS	IconApp, bx
		mov	si, offset	IconApp
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
		call	ObjMessage
		
		.leave
		ret
IconMarkBusy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconMarkNotBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Marks the app as not busy.

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing (ds fixed up)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/13/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconMarkNotBusy	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		GetResourceHandleNS	IconApp, bx
		mov	si, offset	IconApp
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
		call	ObjMessage
		
		.leave
		ret
IconMarkNotBusy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckHugeArrayBitmapCompaction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the bitmap is compacted

CALLED BY:	GLOBAL

PASS:		BX:AX	= Bitmap VM file:block handles

RETURN:		ZF	= Set if uncompacted

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/20/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckHugeArrayBitmapCompaction	proc	far
	uses	ax, bp, es
	.enter
	
	call	VMLock
	mov	es, ax
	cmp	es:[(size HugeArrayDirectory)].CB_simple.B_compact, \
								BMC_UNCOMPACTED
	call	VMUnlock

	.leave
	ret
CheckHugeArrayBitmapCompaction	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMInfoVMChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the number of blocks in vm chain, and the total size
		of the chain in bytes

CALLED BY:	
PASS:		bx	= vm file handle
		ax:bp	= vm chain
RETURN:		
		cxdx <- sum of sizes of VM blocks and DB items (in bytes)
		si   <- number of VM blocks in chain
		di   <- number of DB items in chain

		carry set if error (bad block in chain)

DESTROYED:	nothing

	(copied from trunk kernel so it can be used in the 20X
	  icon editor)

SIDE EFFECTS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SK	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IVMInfoVMChain	proc	far
	vmChainLowWord		local	word	push bp
	byteSizeBlocks		local	dword
	byteSizeItems		local	dword
	numBlocks		local	word
	numItems		local	word

	ForceRef VMInfoVMChain
	ForceRef byteSizeBlocks
	ForceRef byteSizeItems
	ForceRef numBlocks		
	ForceRef numItems

	uses	ax
	.enter
EC <		Assert	fileHandle, bx					>
	;
	; init the counts to 0
	;
		clrdw	byteSizeBlocks
		clrdw	byteSizeItems
		clr	numBlocks
		clr	numItems
	;
	; start the recursion
	;
		mov	cx, vmChainLowWord		; ax:cx is vm chain
		;bx is vm file
		;axcx is vm chain
		;bp is locals
		call	VMInfoVMChainLow		; size & blocks filled
							; carry set if error
done::
	;
	; move return values into registers
	;
		pushf					; save error flag
		movdw	cxdx, byteSizeBlocks
		adddw	cxdx, byteSizeItems
		mov	si, numBlocks
		mov	di, numItems
		popf					; restore error flag
	.leave
	ret
IVMInfoVMChain	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMInfoVMChainLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	recursivly gets size and block count for a vm chain

CALLED BY:	VMInfoVMChain
PASS:		;bx is vm file
		;axcx is vm chain
		;bp is locals
RETURN:		update counts
		carry set if an invalid block was found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SK	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMInfoVMChainLow	proc	near
	uses	ds
	.enter inherit IVMInfoVMChain
EC <		Assert	fileHandle, bx					>
	;
	; is it a chain or a DBItem?
	;
		tst	cx
		jz	doChainsAndTrees
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;    	     a db item		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doDBItem::
	;
	; make sure that the group/item block is valid, if it is valid
	; count it
	;
		;bx is vm file handle
		;ax is block handle
		mov	di, cx				; ax:di is group:item
		call	IDBInfo				; cx <- size
		LONG jc	done				; an error occured
		inc	numItems
ifdef USE_DBLOCK
	;
	; lock down the item
	;
		push	es				; save es
		;ax is group
		;di is item
		;bx is vm file
		call	DBLock				; es:*di ptr to item
	;
	; get the size
	;
		ChunkSizeHandle	es, di, cx
		clr	ax
		adddw	byteSizeItems, axcx
	;
	; unlock it
	;
		;es is segment of locked block
		call	DBUnlock
		pop	es				; restore es
		clc					; no error
else
	;
	; add the size of the item...
	;
		clr	ax
		adddw	byteSizeItems, axcx
endif

		jmp	done
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;     chains and trees	;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doChainsAndTrees:
	;
	; is there anything to do?
	;
		tst	ax
		clc					; no error
		jz	done				; is null chain
	;
	; count this block
	;
		mov	dx, ax				; copy block hdl
		;bx is vm file handle
		;ax is block handle
		call	VMInfo				; cx <- size
							; ax <- mem hdl (or 0)
							; di <- user id
		LONG jc	done				; error occured
		inc	numBlocks
		clr	ax				; high word of dword
		adddw	byteSizeBlocks, axcx
	;
	; lock down this block
	;
		push	bp				; save locals
		mov_tr	ax, dx				; block handle
		;bx is vm file
		call	VMLock				; bp <- mem handle
							; ax <- segment
		mov	ds, ax
	;
	; see if it is a tree or a chain
	;
		mov	ax, ds:[VMCL_next]
		cmp	ax, VM_CHAIN_TREE
		je	doTree
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;     just a chain		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;
	; its not a tree, just a chain.  unlock this block and go on.
	; the bp for locals is on the stack
	;
		;bp is mem handle
		call	VMUnlock			; flags preserved
		pop	bp				; restore locals

		tst	ax				; clears carry
		jz	done				; chain ends here
	;
	; go do the next block, sorta like tail recursion, only we are
	; not at the end, since the tree stuff is below us...  oh well.  ;)
	;
		;bx is vm file
		;bp is locals
		;ax:cx is chain
		;clr	cx				; ax:cx is chain
		;call	VMInfoVMChainLow		; carry set on error
		jmp	doChainsAndTrees
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;    	   just a tree		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doTree:
	; 
	; bp is mem handle of the block, the bp for locals is on the stack
	;
		mov_tr	ax, bp
		pop	bp				; restore locals
		push	ax				; save mem handle
	;
	; loop through the branches
	;
		mov	si, ds:[VMCT_offset]		; first chain
		mov	di, ds:[VMCT_count]		; chains to do
		tst	di				; any children?
		jz	exitTreeLoop			; nope!
treeLoop:
		movdw	axcx, ds:[si]
		;bx is vm file
		;bp is locals
		push	si, di
		call	VMInfoVMChainLow		; carry set on error
		pop	si, di
		jc	exitTreeLoop
		add	si, size dword			; move to next chain
		dec	di				; one less child chain
		clc					; no error
		jnz	treeLoop
exitTreeLoop:
;end treeLoop
	;
	; done with tree block, unlock it
	;
		mov_tr	ax, bp				; save locals
		pop	bp				; mem handle
		call	VMUnlock			; flags preserved
		mov_tr	bp, ax				; restore locals
done:
	.leave
	ret
VMInfoVMChainLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch salient info about a DB item

CALLED BY:	(GLOBAL)
PASS:		bx	= VM file
		ax	= DB group
		di	= DB item
RETURN:		carry set if group or item is invalid
		carry clear if ok:
			cx	= size of the item
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDBInfo		proc	far
		uses	ax, ds, si, bp, di
		.enter
EC <		call	ECVMCheckVMFile					>
	;
	; See if the group block is actually a group block.
	;
		push	di, ax
		call	VMInfo
		mov	si, di
		pop	di, ax
		jc	done			; => not a VM block
		cmp	si, DB_GROUP_ID		; is it a DB group?
		jne	invalid			; no -- invalid

		cmp	di, cx			; item info beyond bounds of the
						;  group block?
		jae	invalid			; yes -- invalid
	;
	; Lock down the group and fetch the item info.
	;
		call	DBGroupLock		; ds <- group
		
		mov	ax, ds:[di].DBII_block
		mov	si, ds:[di].DBII_chunk
	;
	; Make sure the item block info offset points to a valid, in-use item
	; block info record by looking down the group's item block info chain
	; for that offset.
	;
		mov	di, offset DBGH_itemBlocks - offset DBIBI_next
validateItemBlock:
		mov	di, ds:[di].DBIBI_next
		tst	di
		jz	unlockInvalid		; => hit end of list
		cmp	ax, di
		jne	validateItemBlock
	;
	; Make sure the item block is a valid VM block
	;
		mov	ax, ds:[di].DBIBI_block
		push	ax
		call	VMInfo
		pop	ax
		jc	unlockInvalid
		cmp	di, DB_ITEM_BLOCK_ID
		jne	unlockInvalid		; => valid VM, but not an item
						;  block

		cmp	si, cx			; is chunk beyond the end of the
						;  block?
		jae	unlockInvalid		; yes
	;
	; Release the group and lock the item block instead.
	;
		call	DBGroupUnlock
		call	VMLock
		mov	ds, ax
	;
	; Make sure the chunk handle is a valid chunk.
	;
		cmp	si, ds:[LMBH_offset]
		jb	unlockInvalid		; => before handle table
		mov	cx, ds:[LMBH_nHandles]
		shl	cx
		add	cx, ds:[LMBH_offset]
		cmp	si, cx
		jae	unlockInvalid		; => after handle table
		tst	{word}ds:[si]
		jz	unlockInvalid		; => free handle
	;
	; Endlich, get the size of the chunk and release the block.
	;
		mov	si, ds:[si]
		ChunkSizePtr	ds, si, cx
		call	VMUnlock
		clc
done:
		.leave
		ret
unlockInvalid:
		mov	bp, ds:[LMBH_handle]
		call	VMUnlock
invalid:
		stc
		jmp	done
IDBInfo		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StripMaskDataFromBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the mask bits from the bitmap.

CALLED BY:	GetBitmapAndWriteSource

PASS:		^vcx:dx = bitmap

RETURN:		^vcx:dx = new bitmap to use, if any
		carry set if we removed the mask

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- if bitmap doesn't need to be stripped, quit
	- create a destination bitmap (unmasked)
	- create a temp bitmap that's a copy of the source
	- set all the mask bits in the temp bitmap
	- draw the temp bitmap into the destination

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	9/21/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StripMaskDataFromBitmap	proc	far
		uses	bx,si,di,bp,ds

		oldBitmap	local	HBitmap
		tempBitmap	local	HBitmap
		tempGState	local	hptr.GState 
		newBitmap	local	HBitmap
		newGState	local	hptr.GState

		.enter
	;
	;  If the bitmap already has no mask, just return.
	;
		movdw	oldBitmap, cxdx
		movdw	bxdi, cxdx
		call	HugeArrayLockDir
		mov	ds, ax
		mov	al, ds:[(size HugeArrayDirectory)].CB_simple.B_type
		mov	cx, ds:[(size HugeArrayDirectory)].CB_simple.B_width
		mov	dx, ds:[(size HugeArrayDirectory)].CB_simple.B_height
		call	HugeArrayUnlockDir

		test	al, mask BMT_MASK
		LONG	jz	notNew
	;
	;  Create new bitmap with same dimensions as the old one,
	;  using the clipboard VM file (that way we don't dirty the
	;  database when we perform this operation.
	;
		andnf	al, not mask BMT_MASK
		clr	di, si			; OD for exposures
		call	ClipboardGetClipboardFile

		call	GrCreateBitmap		; bx:ax = new bitmap
		movdw	newBitmap, bxax
		mov	newGState, di		; save it.
	;
	;  Create a temporary bitmap (for this routine only)
	;  that's a copy of the OLD bitmap, but set all the
	;  mask bits in it.
	;
		mov	dx, bx			; dx = clipboard file
		movdw	bxax, oldBitmap

		push	bp			; locals
		clr	bp			; no DB items
		call	VMCopyVMChain		; ^vdx:ax = temp bitmap
		pop	bp			; locals

		movdw	tempBitmap, dxax
	;
	;  Edit the temp bitmap and set its mask bits.
	;
		clr	di, si			; exposure OD
		mov	bx, dx			; ^vbx:ax = temp bitmap
		call	GrEditBitmap		; di = gstate
		mov	tempGState, di

		mov	ax, (CF_INDEX shl 8 or C_BLACK)
		call	GrSetAreaColor

		push	dx			; save height
		clr	dx			; no color transfer info
		mov	ax, mask BM_EDIT_MASK
		call	GrSetBitmapMode
		pop	dx			; restore height
		
		clrdw	bxax			; position to draw at
		call	GrFillRect		; cx & dx are still dimensions
	;
	;  Now draw the temp bitmap into the new one.
	;
		mov	di, newGState		; gstate to new bitmap
		movdw	dxcx, tempBitmap
		clr	ax, bx			; (x, y) to position draw at
		call	GrDrawHugeBitmap	; draw old to temp
	;
	;  Destroy the window & gstate for the new bitmap.
	;
		mov	ax, BMD_LEAVE_DATA
		call	GrDestroyBitmap		; leaves new bitmap's data
		movdw	cxdx, newBitmap		; return this bitmap
	;
	;  Destroy the temp bitmap (window, gstate, data & all).
	;
		mov	ax, BMD_KILL_DATA
		mov	di, tempGState
		call	GrDestroyBitmap
	;
	;  Return ax as nonzero, indicating we created a new bitmap.
	;
		stc
		jmp	done
notNew:
		movdw	cxdx, oldBitmap		; bitmap that was passed in.
		clc
done:
		.leave
		ret
StripMaskDataFromBitmap	endp


DocumentCode	ends
