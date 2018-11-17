COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		importDib.asm

AUTHOR:		Maryann Simmons, Feb 24, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT ImportDIB		Imports a DIB File. Creates a GString
				containing a bitmap imported from the input
				DIB file . The Gstring is created in VM
				File:Block passed in bx

    INT ImportDIBCallBack	This is the call back routine passed to
				GrDrawBitmap. It checks to see if there is
				more data to be read in from the input DIB
				file, and if so,	 it reads in a
				scanline. If all scanlines have been read,
				it sets the carry.

    INT GetNextStrip		rewinds the file pointer back to the
				beginning of the next scanline, and reads
				in that scanline into the buffer

    INT ReadDIBBitmapHeaders	Reads in DIB header information into local
				structure

    INT CreateCBitmapFromDIB	Allocates and locks a memory block and
				initializes the header information for a
				complex bitmap according to the DIB
				information contained in stackframe

    INT SetFilePtrToStartofBitmap sets file pointer at end of bitmap in
				file. This corresponds to the beginning of
				the bitmap in our system, as he DIB origin
				is at the lower left, and our bitmap origin
				at the upper left

    INT GetColorTableSize	Determines the size, in bytes of the input
				Bitmaps color table, if any.

    INT BuildColorTable		reads in the DIB Color table to the
				corresponding color table for the Complex
				bitmap

    INT CheckForValidDIBFormat	Checks some of the header parameters to
				make sure it is a valid DIB bitmap format

    INT ConvertResolutionMeterToDPI converts the DIB resolution in X and Y
				from pixels/meter to DPI.

    INT GetBitmapType		Determines the Bitmap type of the input DIB
				format

    INT GetScanlineSize		Calculates the size in bytes of the
				scanlines

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/24/92		Initial revision


DESCRIPTION:
	This file contains the routines which translate a DIB( Microsoft Device
	Independent Bitmap) formatted bitmap file into a Geos Bitmap.
		

	$Id: importDIB.asm,v 1.1 97/04/07 11:29:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportCode	segment resource		;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportDIB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Imports a DIB File. Creates a GString containing a bitmap
		imported from the input DIB file . The Gstring is
		created in VM File:Block passed in bx
		
CALLED BY:	ImpexImportGraphicsConvertToTransferItem

PASS:	
		di:	IF_formatNumber		word
		ax:	IF_importOptions	word
	        (the above parameters are currently not utilized)

		dx:	VMFile to put Bitmap in	
		bx:	DIB source file( stream pointer-open for read )

RETURN:		ax:	 will be zero if the import was successful:
			   if the import was unsuccessful, will contain 
			   error flag of type TransError
		bx:	 memory handle for error text if ax = TE_CUSTOM
		dx:cx:	VMFile/VMBlock handle of HugeArray holding Bitmap

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		>Initialize ComplexBitmap struct from DIB info
				>Create Color Table( if not 24 bit cnt)
	
		>call GrDrawBitmap
		  *must seek to end of file; origin of DIB at lower left-
		   need it at upper left
		>callback routine called for each scanline
		
	
		   
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	* the DIB source file stream pointer is passed in bx. This is actually
	 the low word of the stream pointer, as the high word is always
	 zero. ALL OF THE FOLLOWING ROUTINES DEPEND UPON THIS!!!
	

	*****************
	24-BIT IS NOT SUPPORTED YET
	*****************************

	ASSUMPTIONS:
	 	Currently making the following assumptions about the 
		received DIB format:
		* The file is not compressed
		* unless it is 24 bit RGB- there must be a color table
	IDEAS:
		*possibly compress incoming information

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
ImportDIB	proc	near
	uses	di,si,ds

if COMPRESS_BITMAP
vmFile	local	word	push	dx
endif
		
locals 	local  	DIBBitmapHeaders 	;this local structure will hold the
					; DIB header info read in from the file
	.enter

;read in DIB Header information
	call	ReadDIBBitmapHeaders	;put info for Bitmap header on stack
	jc	done			;carry will be set on error

;create Bitmap: use info from DIB header to set up a CBitmap header and
; color table if appropriate., this bitmap will be drawn into the Huge Bitmap

	call	CreateCBitmapFromDIB	; ret: ds:si = bitmap
	jc	done			; if error from CreateCBitmapFromDIB

	mov	bx, dx			; VMFile
	push	ax			; save handle of block
					; containing bitmap
	push	si			; ds;si => pointer to the
					; bitmap to draw

	mov	al, ds:[si][BHD_CBM].CB_simple.B_type
	or	al, mask BMT_HUGE
	mov	cx, ds:[si][BHD_CBM].CB_simple.B_width
	mov	dx, ds:[si][BHD_CBM].CB_simple.B_height
	clr	di, si			; bx = VMfile
	call	GrCreateBitmap		; ax = vmBlock, di gstate handle
	pop	si			; restore pointer to bitmap
	push	ax			; save vmBlock handle of Bitmap

	mov	ax, ds:[si][BHD_CBM].CB_xres
	mov	bx, ds:[si][BHD_CBM].CB_yres
	call 	GrSetBitmapRes

	; Initialize invert field

	mov	ax, ss:[locals].DBH_invert
	mov	ds:[si].BHD_invert, ax

;draw Bitmap into vidmem
	clr	ax,bx			;where to draw, default to origin
	mov	dx,cs			;dx:cx callback routine
	mov	cx,offset ImportDIBCallBack 
	call	GrDrawBitmap		;ds:si = pointer to bitmap
					;di= handle of graphics state

if COMPRESS_BITMAP
	mov	bx, ss:[vmFile]
	mov	dx, bx
	pop	ax			; VMBlock holding Bitmap
	call	GrCompactBitmap
	mov	dx, cx

	push	bp
	clr	bp
	call	VMFreeVMChain
	pop	bp
else
	pop	dx			; VMBlock holding Bitmap
endif
	clr	cx
		
;free MemBlocks holding Bitmap and buffer

	pop	bx			;get handle for block holding bitmap
	call	MemFree			;unlock the block holding the bitmap


	mov	bx,locals.DBH_buffHandle;get buffer handle
	call	MemFree
	
;successful import, set up return values
	mov	ax,TE_NO_ERROR		;no errors
done:
	.leave
	ret

ImportDIB	endp

;---------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportDIBCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the call back routine passed to GrDrawBitmap.
		It checks to see if there is more data to be read in 
		from the input DIB file, and if so,  it reads in a
		scanline. If all scanlines have been read, it sets the
		carry.

CALLED BY:	GrDrawBitmap

PASS:		ds:si: pointer to the bitmap( what was passed to GrDrawBitmap
			initially.		
RETURN:		carry if no more bitmap
		ds:si	ptr to new bitmap slice( Note: this will always
			be what was passed in)
		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportDIBCallBack	proc	far
	uses	ax,bx,cx,dx,di,bp,es
	.enter
;check to see if this is the first scanline processed in  this bitmap
	mov	bp,si				;ds:[bp] points to the bitmap
	cmp	ds:[bp].BHD_CBM.CB_numScans,0	;is this the first scanline?
	je	firstStrip

	mov	dx,ds:[bp].BHD_rewind		;get amnt to seek back in file
	mov	bx,ds:[bp].BHD_stripSize	;num scanlines in strip
	mov	cx,ds:[bp].BHD_CBM.CB_numScans	;get num scans processed last
	add	ds:[bp].BHD_CBM.CB_startScan,cx ;call and update startScan
;see if we are finished with the bitmap
	mov	ax,ds:[bp].BHD_CBM.CB_simple.B_height
	cmp	ds:[bp].BHD_CBM.CB_startScan,ax
	LONG je	noMoreStrips
	mov	ds:[bp].BHD_CBM.CB_numScans,bx
rewindFile:
	;rewind the file pointer to the beginning of the next strip
	mov	al,FILE_POS_RELATIVE	
	mov	bx,ds:[bp].BHD_DIBFile		;file containing DIB
	mov	cx,-1				;cxdx is rewind amount
	push	cx
	push	dx
	call	FSeek				;rewind to beginning of strip

;unlock buffer block
	mov	bx,ds:[bp].BHD_buffHandle
	call	MemLock				;get the address of the block
	segmov	es,ds,cx			
	mov	ds,ax				;ds:dx will be the buffer to
						;read into
;now read in a strip
	clr	al				;reserved flags- should be 0
	pop	cx				;cx is the num bytes to read
	push	cx				;save to rewind
	neg	cx
	clr	dx				;ds:dx points to buffer
	mov	bx,es:[bp].BHD_DIBFile		;file containing DIB
	call	FRead				;read in a strip

; now copy the scanlines, in reverse order from the buffer into the
; bitmap. The outer loop will step from scanline to scanline in the 
; bitmap, while the inner loop moves words within a scanline

	push	es:[bp].BHD_CBM.CB_numScans     ;mov ds:si to es:di	
	mov	di,bp				;es:bp points to bitmap
	add	di,size BitmapHeaderAndData	;now es:di points to dest
	mov	si,cx				;cx = bytes in strip
	sub	si,es:[bp].BHD_scanlineSize	;ds:si is buffer to read from
copyLoop:

	mov	cx,es:[bp].BHD_scanlineSize
	sub	cx,es:[bp].BHD_scanlineDiff	;must account for CBitmap 
	tst	es:[bp].BHD_invert		;do we need to invert?
	jnz	invertMonochrome		;yes, so go to it!
copyScanline:
	cld					;so si and di incremented
	rep	movsb				;copy scanline to bitmap
	add	si,es:[bp].BHD_scanlineDiff	
	pop	bx				;get num scanlines
	dec	bx				;just copied one
	jz	finishedStrip			;are there more scanlines?
	push	bx				;save num left
	mov	ax,es:[bp].BHD_scanlineSize	;mov buffer pointer back two 
	shl	ax,1				;scanlines,one for one just
	sub	si,ax				;read, one to get next line
;	sub	di,es:[bp].BHD_scanlineDiff	;must account for CBitmap 
						;allignment on byte,DIB on long
	jmp	copyLoop			;copy next line
firstStrip:
	mov	dx,ds:[bp].BHD_initRewind	;get offset to seek to
	mov	ax,ds:[bp].BHD_initStripSize	;num initial scanlines
	mov	ds:[bp].BHD_CBM.CB_numScans,ax	;set num scans in strip
	mov	ds:[bp].BHD_CBM.CB_startScan,0	;first scan is 0
	mov	ds:[bp].BHD_CBM.CB_data,size BitmapHeaderAndData
	mov	ds:[bp].BHD_CBM.CB_palette,0	;turn off palette bit 
	and	ds:[bp].BHD_CBM.CB_simple.B_type, not (mask BMT_PALETTE)
	jmp	rewindFile			;position file pointer to 
						;read in strip
finishedStrip:
	segmov	ds,es,bx			;reset ds:si to point to bitmap
	mov	si,bp				;want es:bp-> ds:si

;rewind file so next call at right place
	mov	al,FILE_POS_RELATIVE	
	mov	bx,ds:[si].BHD_DIBFile		;file containing DIB
	pop	dx
	pop	cx
	call	FSeek				;rewind to beginning of strip

;unlock	buffer 
	mov	bx,ds:[si].BHD_buffHandle	; get handle to buffer
	call	MemUnlock			; unlock buffer
done:	
	.leave
	ret

invertMonochrome:

; the bitmap is monochrome, so flip all the bits so it will be consistent
; with the GString Monochrome bitmap color scheme
	push	es,cx,di,si
	segmov	es,ds,di			;reset ds:si to point to bitmap
	mov	di,si				; ds:si is the buffer
	mov	dl,0xff	
invertLoop:
	lodsb
	xor	al,dl
	stosb
	loop	invertLoop

	pop	es,cx,di,si
	jmp	copyScanline

noMoreStrips:
	stc					; setcarry so GrDrawBitmap
	jmp	done				; knows we are done

ImportDIBCallBack	endp

;-------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadDIBBitmapHeaders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads in DIB header information into local structure

CALLED BY:	ImportDIB	
PASS:		bx:  DIB File to Import(stream pointer)
		inherits stackframe from ImportDIB

RETURN:		carry set if error in reading DIB File
		ax = Error flag if unsuccessful read
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadDIBBitmapHeaders	proc	near
	uses	cx,dx,ds

	.enter inherit	ImportDIB

	mov	cx,size DIBFileHeader   ;cx = #bytes to read
	add	cx,size DIBBitmapInfo   ;number bytes in DIB header	
	segmov	ds,ss			;local variable is in stack segment
	lea	dx, locals		;get offset into stack segment
	clr	ax			;al =  flags,bx = file
	call	FRead		;ds:dx  = buffer to read into
	jc	errorRead
done:
	.leave
	ret

errorRead:
	mov	ax,TE_FILE_READ          ;error reading the file header
	jmp	done

ReadDIBBitmapHeaders 	 endp

;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateCBitmapFromDIB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates and locks a memory block and initializes
		the header information for a complex bitmap according
		to the DIB information contained in stackframe	

CALLED BY:	ImportDIB
PASS:		inherits stackframe from importDIB
		bx	-DIBFIle to Import(stream pointer)
		
RETURN:		ds:si	-pointer to bitmap
		ax	-handle of local memory block allocated and
			  containing initialized bitmap	
		carry set if error, ax = TransError code 
		if ax = TE_CSTOM, bx = handle of block containing the error
		string

DESTROYED:	bx if custom error not returned

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateCBitmapFromDIB	proc	near

	uses	cx,dx
	.enter	inherit	ImportDIB

;check the DIB header- make sure valid before proccessing any further
	call	CheckForValidDIBFormat
	LONG jc	done	

	call	GetScanlineSize		;returns scanline size in ax
	call	GetStripSize		;returns strip size in ax
	LONG jc	errorMem		;also allocates buff and stores handle
	
	mov	dx,bx			;DIB File handle
	call	GetColorTableSize 	;ret colorTable size in si

;Allocate block to hold bitmap( header + 1 scanline) + color table+ workspace
;Compares color table size and ax and allocate block of larger
	cmp	ax,si			;see if color table or scanline bigger
	jg	allocate		;scanline is bigger
	mov	ax,si			;color Table is larger
allocate:
	add	ax,size BitmapHeaderAndData
	mov	cl,mask HF_SWAPABLE
	mov	ch,mask HAF_LOCK	;lock block
	call	MemAlloc		;returns address ax
	LONG jc	errorMem		;return handle memblock bx
	push	bx			;save memhandle

;now set bitmap header according to info obtained in DIB header
	mov	ds,ax			;ds = address bitmap
	mov	cx,locals.DBH_info.DBI_width.low 
	mov	ds:[BHD_CBM].CB_simple.B_width,cx
	mov	cx,locals.DBH_info.DBI_height.low 
	mov	ds:[BHD_CBM].CB_simple.B_height,cx
	mov	ds:[BHD_CBM].CB_simple.B_compact,BMC_UNCOMPACTED	
	call	GetBitmapType		;returns bitmap type in al
	jc	error

	mov	ds:[BHD_CBM].CB_simple.B_type,al ;set bitmap type
	mov	ds:[BHD_CBM].CB_startScan,0
	mov	ds:[BHD_CBM].CB_numScans,0
	mov	ds:[BHD_CBM].CB_devInfo,0
	mov	ds:[BHD_CBM].CB_data,size BitmapHeaderAndData
	mov	ds:[BHD_CBM].CB_palette,0
	mov	ds:[BHD_DIBFile],dx
	mov	cx,locals.DBH_scanlineSize
	mov	ds:[BHD_scanlineSize],cx
	mov	cx,locals.DBH_scanlineDiff
	mov	ds:[BHD_scanlineDiff],cx
	mov	cx,locals.DBH_rewind
	mov	ds:[BHD_rewind],cx
	mov	cx,locals.DBH_initRewind
	mov	ds:[BHD_initRewind],cx
	mov	cx,locals.DBH_stripSize
	mov	ds:[BHD_stripSize],cx
	mov	cx,locals.DBH_initStripSize
	mov	ds:[BHD_initStripSize],cx
	mov	cx,locals.DBH_buffHandle
	mov	ds:[BHD_buffHandle],cx
	call	ConvertResolutionMeterToDPI ;returns xres in ax, yres in cx
	mov	ds:[BHD_CBM].CB_xres,ax
	mov	ds:[BHD_CBM].CB_yres,cx
	
;now must build color table
	mov	cx,si			;size of color table
	jcxz	cont			;nocolorTable
	mov	ax,offset BHD_paletteSize

CheckHack <((size BitmapHeaderAndData)-(size BHD_paletteSize)) eq \
	(offset BHD_paletteSize) >

	mov	ds:[BHD_CBM].CB_palette,ax
	add	ds:[BHD_CBM].CB_data,cx	;data follows immediately after color
	call 	BuildColorTable		;table	
	jc	error
cont:	clr	si

;position fp at end of file
	mov	bx,dx			;handle DIB
	call 	SetFilePtrToStartofBitmap
	pop	ax			;handle of mem block with bitmap in it
done:	
	.leave
	ret
error:
	add 	sp,2
errorMem:
	mov	ax,TE_IMPORT_ERROR
	stc
	jmp	done

CreateCBitmapFromDIB	endp

;---------------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetStripSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines what size buffer to allocate to be used
		by the callback routine for GrDrawBitmap. Also sets
		the number of scanlines per strip.	

CALLED BY:	CreateCBitmapFromDIB
PASS:		inherits stackframe from CreateCBitmapFromDIB
RETURN:		ax = buffer size
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		   We are shooting for a buffer size around 5K. Taking
		(( 5K/scanlinesSize) + 1) will give the number of scanlines
		that will fit in a buffer which is about 5K. By adding one,
		it is ensured that at least 1 scanline will fit in the buffer.
		   
		   When we have the number of scanlines per block, this is
		compared to the bitmap height, or total number of scanlines.
		If the entire bitmap will fit in 5K or less, the height of
	        the bitmap is taken as the number of scanlines per block.
		  
		   Once the number of scanlines is determined, this is
		multiplied by the passed in scanline size to get the 
		buffer size.

		   The number of scanlines per block is set.	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	6/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetStripSize	proc	near
	uses	bx,cx,dx

	.enter	inherit	ImportDIB

	mov	cx,locals.DBH_scanlineSize
	mov	ax,DIB_IMPORT_BUFF_SIZE
	clr	dx
	div	cx			;quotient ax, remainder, dx
	inc	ax			;increment to take care of any 
					;fractional part,which will ensure the
					;buffer can hold at least one scanline
	cmp	ax,locals.DBH_info.DBI_height.low	
	jg	smallBitmap
	mov	locals.DBH_stripSize,ax	;ax is the num scanlines per strip
	mov	locals.DBH_initStripSize,ax ;default init scanlines
	mul	cx
	mov	bx,ax			;bytes/buffer
	neg	ax
	mov	locals.DBH_rewind,ax
	mov	locals.DBH_initRewind,ax

	mov	cx,locals.DBH_stripSize	;num scans per strip
	mov	ax,locals.DBH_info.DBI_height.low
	clr	dx	
	div	cx			;result in ax remainder dx
	tst	dx
	jz	allocBuf
	mov	locals.DBH_initStripSize,dx
	mov	ax,locals.DBH_scanlineSize
	mul	dx			;num scanlines over
	neg	ax
	mov	locals.DBH_initRewind,ax
allocBuf:
	mov	ax,bx			;size of buffer
	push	bx			;save size in bytes of buffer
;now allocate buffer and store away handle
	mov	cx,ALLOC_DYNAMIC	;allocate block
	call	MemAlloc		;returns address ax
					;handle returned in bx
	mov	locals.DBH_buffHandle,bx;save handle
	pop     ax			;return size of buffer in ax

	.leave
	ret

smallBitmap:	
;if the entire bitmap fits into less than 5K, allocate just enough 
;to hold the entire thing in one pass
	mov	ax,locals.DBH_info.DBI_height.low
	mov	locals.DBH_initStripSize,ax
	mov	dx,locals.DBH_scanlineSize
	mul	dx			;size of image
	mov	bx,ax			;save buffer size
	neg	ax			;initial rewind amount
	mov	locals.DBH_initRewind,ax
	jmp	allocBuf

GetStripSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFilePtrToStartofBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets file pointer at end of bitmap in file. This corresponds
		to the beginning of the bitmap in our system, as he DIB origin
		is at the lower left, and our bitmap origin at the upper left	
CALLED BY:	CreateCBitmapFromDIB	
PASS:		bx:	DIB File(stream pointer) 
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	3/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFilePtrToStartofBitmap	proc	near
	uses	ax,bx,cx,dx

	.enter inherit	ImportDIB

;moveto size of fileheader plus size of bitmap
	push	bx			;save DIB File Handle

	mov	ax,locals.DBH_scanlineSize
	mov	cx,locals.DBH_info.DBI_height.low
	mul	cx			;num bytes in image in dx:ax
	mov	cx, locals.DBH_fileHeader.DBFH_offBit.low
	clr	bx
	adddw	dxax,bxcx		;offset from header to data
	mov	cx,dx							
	mov	dx,ax			;offset into file
	pop	bx			;get DIB File Handle
	mov	al,FILE_POS_START
	call	FSeek
	.leave
	ret
SetFilePtrToStartofBitmap	endp
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetColorTableSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines the size, in bytes of the input Bitmaps color
		table, if any.	

CALLED BY:	CreateCBitmapFromDIB
PASS:		inherits stackframe from importDIB
RETURN:		si:	sizeColorTable		
DESTROYED:      	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetColorTableSize	proc	near
	uses	ax,cx,dx

	.enter inherit	ImportDIB

	clr	si			;initialize, if 24 bit no color table
	mov	cx, locals.DBH_info.DBI_bitCnt
	cmp	cx,24
	je	done			;24bit stored as explicit RGBs,no table
	mov	ax,1			;ax = num entries in color table
	shl	ax,cl			;2^num bits per pixel

;test if num colors used set, if so may be less than full default size	
	tst	locals.DBH_info.DBI_colorUsed.low
	jz	colorTableSizeSet
	cmp	ax,locals.DBH_info.DBI_colorUsed.low
	jg	colorTableSizeSet
	mov	ax,locals.DBH_info.DBI_colorUsed.low

colorTableSizeSet:
	mov	locals.DBH_numColors,ax
	mov	cx,3			;number bytes for RB triple
	mul	cx			;num entries*3bytes(rgb) per entry
	mov	si,ax			;bx = num bytes in color table
	add	si,1			;make sure have extra byte( will be
					;reading in RGB quads, not triples
                                        ;need 1 extra at end)
done:
	.leave
	ret
GetColorTableSize	endp
;----------------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildColorTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	reads in the DIB Color table to the corresponding
		color table for the Complex bitmap 

CALLED BY:	CreateCBitmapFromDIB
PASS:		dx:	DIB FIle(stream pointer)
		ds pointing to block with bitmap in it
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/28/92		Initial version
	Don	8/04/94		Map monochrome bitmaps to GEOS color scheme

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildColorTable	proc	near
	uses	ax,bx,cx,dx,si,di,es,ds

	.enter	inherit	ImportDIB

	mov	ax, locals.DBH_numColors;set num colors in palette
	mov	ds:[BHD_paletteSize].P_entries,ax
	segmov	es,ds			;es:di points to dest
	shl	ax,1			;size of buffer to read in table
	shl	ax,1			;4 bytes/entry
	push	ax			;save size of table
	mov	cx,ALLOC_DYNAMIC_LOCK	;flags- swapable and return locked
	call	MemAlloc		;bx = handle, ax = seg
	jc	error	
	segmov	ds,ax			;ds:si = source
;readRGB:
	pop	cx			;cx = num bytes to read
	push	bx			;mem block alloctated
	mov	bx,dx			;bx = DIB file handle
	clr	dx,ax			;ds:dx = buffer to read into
					;ax=flags-must be 0
	call	FRead			;ax = error, cx = num bytes read
	jc	errorRead
	mov	di,size BitmapHeaderAndData 
	mov	cx,locals.DBH_numColors ;es:di = buffer to read to	
	clr	si			;ds:si = source

moreColors: ; must do some juggling here, DIB is BGRR(Reserved=0)
	lodsw
	mov	bx,ax			;bx = GB
	lodsw				;ax = 0R
	mov	ah,bh			;ax = RG
	stosw				
	mov	al,bl			;al = B	
	stosb
	loop	moreColors
	pop	bx			;block handle
	call	MemFree			;free block

	; If we are working with a Monochrome bitmap, we know that
	; GEOS ignores the palette. So, we're going to check the
 	; color table information that has been provided to us,
	; compare it against the default table, and then see if
	; we should change the polarity of the bitmap. If we are
	; not monochrome, clearly we never need to invert the data.

	mov	ss:[locals].DBH_invert,FALSE
	cmp	ss:[locals].DBH_numColors,2 ; see if it is a Mono Bitmap
	je	monoBitmap		; yep, so do some work
	clc
done:
	.leave
	ret

errorRead:
	pop	bx
	call	MemFree
	stc
	jmp	done
error:
	add	sp,2			;fixup the stack pointer
	stc
	jmp	done

	; We're going to do two things:
	; 1) Map the current entries in the color table to
	;    the BLACK & WHITE colors, so that the bitmap will
	;    have the proper polarity.
	; 2) Set the default color table to something GEOS likes
	;    (this should be unnecessary)
monoBitmap:
	mov	di,size BitmapHeaderAndData
	clr	ax,bx			; BL = 0 && BX = FALSE
	mov	al,{byte} es:[di+0]
	add	al,{byte} es:[di+1]
	adc	ah,bl
	add	al,{byte} es:[di+2]
	adc	ah,bl
	mov_tr	cx,ax			; distance color0 from BLACK => CX
	clr	ax
	mov	al,{byte} es:[di+3]
	add	al,{byte} es:[di+4]
	adc	ah,bl
	add	al,{byte} es:[di+5]
	adc	ah,bl			; distance color1 from BLACK => CX
	cmp	ax,cx
	jle	havePolarity
	dec	bx			; else reverse polarity (BX = TRUE)
havePolarity:
	mov	ss:[locals].DBH_invert, bx

	; set to index0 = WHITE(ff ff ff) and index1 = BLACK(00 00 00)

	movdw	dxax,0x00ffffff
	movdw	es:[di],dxax		; set index0 to white
	add	di,4
	clr	ax
	mov	es:[di],ax		; set index1 to black
	jmp	done
BuildColorTable	endp
;----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCustomErrorBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a block and copy in custom error string

CALLED BY:	
PASS:		
RETURN:		ax	- TE_CUSTOM 
			  or if allocation unsuccessful,
			  	TE_FORMAT_UNSUPPORTED
		bx	- Block with error String		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	3/ 6/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCustomErrorBlock	proc	near
	uses	ds,es,cx,si,di
	.enter


	mov	bx, handle DIBCustomErrorStrings
	call	MemLock
	jc	noBlock	
	mov	ds,ax				; ds:si = source error string
	mov	si, offset DIBError1
	mov	si, ds:[si]			; deref chunk
	ChunkSizePtr	ds, si, ax		; cx <- # of bytes in string

	mov	cl, mask HF_SWAPABLE
	mov	ch, HAF_STANDARD_LOCK		; cl = HeapFlags, ch = HeapAllocFlags
	call	MemAlloc			; bx = handle, ax address
	jc	unlockBlock
	push	bx				; save handle to block
	mov	es,ax				; es:di = destination
	clr	di
	ChunkSizePtr	ds,si,cx		; cx <- # of bytes in string
	rep	movsb				; copy string
	call	MemUnlock			; unlock block

	mov	bx, handle DIBCustomErrorStrings
	call	MemUnlock			; unlock string resource block
	mov	ax, TE_CUSTOM
	pop	bx				; restore handle to custom error
done:
	.leave
	ret

unlockBlock:
	mov	bx, handle DIBCustomErrorStrings
	call	MemUnlock			; unlock string resource block
noBlock:
	; unable to get error string
	mov	ax, TE_IMPORT_NOT_SUPPORTED
	jmp	done

GetCustomErrorBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForValidDIBFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks some of the header parameters to make sure
		it is a valid DIB bitmap format

CALLED BY:	CreateCBitmapFromDIB	
PASS:		inherit stackframe fron ImportDIB

RETURN:		carryset if error
		ax = TransError Code
		bx = block if ax= TE_CUSTOM
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/27/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForValidDIBFormat	proc	near
	
	.enter	inherit	ImportDIB
	
	mov	ax, TE_IMPORT_ERROR

	cmp	locals.DBH_fileHeader.DBFH_type,BITMAP 
	jne	notValidBitmap			;type must be BM	

	tst	locals.DBH_info.DBI_width.high	;cant be this big
	jnz	notValidBitmap

	tst	locals.DBH_info.DBI_height.high
	jnz	notValidBitmap			;cant be this big

	cmp	locals.DBH_info.DBI_planes,1	;according to DIB, must be one
	jne	notValidBitmap
				
	cmp	locals.DBH_info.DBI_compress.low, NO_COMPRESS
	jne	notValidBitmap			;dont support compression

	mov	ax,TE_CUSTOM	
	cmp	locals.DBH_info.DBI_bitCnt, 24	; do not currently support 24-bit
	je	RGBUnsupported				; images
	clc
done:
	.leave
	ret
RGBUnsupported:
	call	GetCustomErrorBlock
notValidBitmap:
	stc
	jmp	done
CheckForValidDIBFormat	endp

;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertResolutionMeterToDPI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	converts the DIB resolution in X and Y from pixels/meter to
		DPI.

CALLED BY:	CreateCBitmapFromDIB
PASS:		inherits stackframe from CreateCBitmapFromDIB
RETURN:		ax:	Xresolution in dpi	
		cx:	Yresolution in dpi	
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/26/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertResolutionMeterToDPI	proc	near
	uses	bx,dx

	.enter inherit	ImportDIB

	cmp	locals.DBH_info.DBI_xRes.low,0 
	jne	convert
	mov	ax,72	;default
	mov	cx,72	;default
	jmp	done
convert:
	clr	dx			;.00254-conversion factor ppm->dpi
	mov	cx,1665			;fractional part
	push	dx,cx			;save conversion factor
	clr	ax
	mov	bx,locals.DBH_info.DBI_xRes.low  ;bx.ax is res. x in ppm
	call	GrMulWWFixed		;dx.cx = product dpi
	pop	bx,ax			;get conversion factor back
	push	dx			;save new x res
	mov	dx,locals.DBH_info.DBI_yRes.low	;dx.cx is y res ppm
	clr	cx
	call	GrMulWWFixed		;apply conversion factor
	pop	ax			;ax =  xres in dpi
	mov	cx,dx			;cx =  yres in dpi
done:
	.leave
	ret
ConvertResolutionMeterToDPI	endp
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBitmapType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines the Bitmap type of the input DIB format

CALLED BY:	CreateCBitmapFromDIB
PASS:		inherits stackframe from CreateCBitmapFromDIB

RETURN:		al has info for bitmaptype record
		or: if carry set, ax has TE_INVALID_FORMAT

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBitmapType	proc	near

	.enter inherit	ImportDIB

	cmp	locals.DBH_info.DBI_bitCnt,DIB_MONO
	jne	fourbit

;this is a monochrome bm, assumed with palette
	mov	al, mask BMT_COMPLEX or mask BMT_PALETTE or \
		BMF_MONO shl offset BMT_FORMAT
  	jmp	done
fourbit:
	cmp	locals.DBH_info.DBI_bitCnt,DIB_4BIT
	jne	eightbit		;this bitmap has 4bit pixels
	mov	al, mask BMT_COMPLEX or mask BMT_PALETTE or \
		BMF_4BIT shl offset BMT_FORMAT
	jmp	done
eightbit:
	cmp	locals.DBH_info.DBI_bitCnt,DIB_8BIT
	jne	twentyfour			;bitmap w/byte size pixels,
	mov	al, mask BMT_COMPLEX or mask BMT_PALETTE or \
		BMF_8BIT shl offset BMT_FORMAT
	jmp	done		;max 256 colors
twentyfour:
	jmp	error
;	cmp	locals.DBH_info.DBI_bitCnt,DIB_24BIT
;	jne	error
;	mov	al,mask BMT_COMPLEX or BMF_24BIT shl offset BMT_FORMAT	
;bitmap w/@pixel triple of RGB bytes
done:
	.leave
	ret
error:
	stc
	mov	ax,TE_IMPORT_ERROR
	jmp	done
GetBitmapType endp
;-----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetScanlineSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the size in bytes of the scanlines

CALLED BY:	CreateCBitmapFromDIB	
PASS:		inherits stackframe from CreateCBitmapFromDIB
RETURN:		ax: scanline size
DESTROYED:	nothiing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetScanlineSize	proc	near
	uses bx,cx,dx

	.enter	inherit	ImportDIB

;scanline Size = trunc( (#pixels* #bits/pixel)+31) /(32)*8) 
	mov	ax,locals.DBH_info.DBI_width.low;number of pixels wide
	mov	cx,locals.DBH_info.DBI_bitCnt	;# bits/pixel
	mul	cx				;get number bits/scanline
	push	ax				;save bits/scanline
	add	ax,31				;must be on LONG boundary
	mov	cl,5				; div by 32
	shr	ax,cl				;mul by 4 to get bytes
	mov	cl,2
	shl	ax,cl
	mov	locals.DBH_scanlineSize,ax	;set scanline size
	
;CBitmap scanline size = trunc( (#bits/scanline)+7/8) 
	pop	bx				;get num bits/scanline
	add	bx,7				;CBitmap on byte boundary
	mov	cl,3				;div by 8
	shr	bx,cl
	mov	cx,ax				;scanline size
	sub	cx,bx				;diff between long and byte 
	mov	locals.DBH_scanlineDiff,cx	; boundaries
	.leave
	ret
GetScanlineSize	endp

;---------------------------------------------------------------------------


ImportCode	ends				;end CommonCode Resource

















