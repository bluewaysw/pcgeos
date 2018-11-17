COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		exportDIB.asm

AUTHOR:		Maryann Simmons, Mar 12, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT ExportDIB		Exports a GString to the DIB format. The
				resulting bitmap is stored in the indicated
				file

    INT ETDDeleteTempFile	destroy Temp File and Bitmap in it

    INT ETDSetBitmapType	set the BMType according to the bitcount-
				will be complex with a palette, unless
				24bit

    INT ETDCreateTempVMFile	Creates a temp VM File- this will be used
				to play The Gstring into- Creating a bitmap
				which can then be converted out to DIB

    INT ETDCBitmapToDIB		Write out a slice of scanlines into the
				specified DIB File

    INT ETDSetUpDIBHeader	Sets up the DIB FIle Header and DIB info
				header in the specified file. These
				structures are as follows: FILEHEADER:
				DBFH_type	BitmapType
				DBFH_size	dword
				DBFH_reserved	dword
				DBFH_offBit	dword

    INT ETDWritePaletteToDIB	Writes the default Geos color table to the
				DIB file specified

    INT ETDCalculateStripSizeAndOffset calculates the number of scanlines
				that will fit in a 100K block, as well as
				the offset to translate the bitmap such
				that any remain. scanlines(remainder of
				scanlines/(scanlines/block)) will be
				handled first. The DIB format has the
				origin at the lower left, and the CBitmap's
				origin is the upper left, therefore, the
				last scanline in the DIB is the first one
				in the bitmap.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	3/12/92		Initial revision


DESCRIPTION:
	The routines in this file export a Gstring to a Device Independent
	Bitmap(DIB). The DIB will then be processed by one of the bitmap
	translation libraries which will take the DIB as input and output
	the appropriate format.	

	$Id: exportDIB.asm,v 1.1 97/04/07 11:29:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportCode	segment	resource		;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportHugeBitmapToDIB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exports a Huge Bitmap to a DIB metafile format	

CALLED BY:	ExportDIB	
PASS:		bx	-VMFile		hptr
		si	-VMBlock	hptr
		di	-DIBFile	(lower word of stream pointer)
		dl	-Bitcount	byte

RETURN:		ax	-will be zero if the export was successful
			 otherwise will contain TransError
		bx:	-if ax = TE_CUSTOM will contain handle of error text		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	3/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportHugeBitmapToDIB	proc	near
	uses	cx,dx,si,di,ds
	exportInfo	local	ExportInfo
	.enter 

	mov	exportInfo.ETDFrame.EDF_VMFile,bx	
	mov	exportInfo.ETDFrame.EDF_VMBlock,si	
	mov	exportInfo.ETDFrame.EDF_DIBFile,di				
	mov	exportInfo.ETDFrame.EDF_exportOptions,dl

	; first get the height, width, and bit count of the Bitmap
	mov	di,si			; di <= VM block
	call	HugeArrayLockDir	; bx.di = HugeBitmap
	mov	ds, ax
	mov	si, offset EB_bm
	mov	bx, ds:[si].B_height
	mov	ax, ds:[si].B_width
	mov	cl,dl
	clr	ch			; cx is the bit count

	call	HugeArrayUnlockDir	; ds is the segment

	; determine number of bytes/scanline and number bytes/normalized
	; scanline on long boundary
	call	ETDGetScanlineSize	
	mov	dx,exportInfo.EBInfo.EBI_scanlineSize
	add	dx,exportInfo.EBInfo.EBI_scanlineDiff
	mov	di,exportInfo.ETDFrame.EDF_DIBFile
	call	ETDSetUpDIBHeader
	jc	done			;error code will be in ax

	mov	exportInfo.EBInfo.EBI_initStripSize, 0
	mov	exportInfo.EBInfo.EBI_stripSize, bx	; handle in one strip 
	mov	cx, exportInfo.ETDFrame.EDF_DIBFile
	mov	bx, exportInfo.ETDFrame.EDF_VMFile	
	mov	ax, exportInfo.ETDFrame.EDF_VMBlock	;bx.ax = HugeArray	
	call	ETDCBitmapToDIB
	jc	done					; error code in ax

	mov	ax,TE_NO_ERROR
done:
	.leave
	ret

ExportHugeBitmapToDIB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportGStringToDIB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exports a GString to a DIB metafile format	

CALLED BY:	ExportDIB	
PASS:		bx	-VMFile		hptr
		si	-VMBlock	hptr
		di	-DIBFile	(lower word of stream pointer)
		dl	-Bitcount	byte

RETURN:		ax	-will be zero if the export was successful
			 otherwise will contain TransError
		bx:	-if ax = TE_CUSTOM will contain handle of error text		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	3/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportGStringToDIB	proc	near
	uses	cx,dx,si,di,bp,es,ds
	exportInfo	local	ExportInfo
	.enter	

;save input parameters
	mov	exportInfo.ETDFrame.EDF_VMFile,bx	
	mov	exportInfo.ETDFrame.EDF_VMBlock,si	
	mov	exportInfo.ETDFrame.EDF_DIBFile,di				
	mov	exportInfo.ETDFrame.EDF_exportOptions,dl

	mov	cl,GST_VMEM		;cl is the type of handle in bx
	call	GrLoadGString		;returns si = GString Handle
;get the GString bounds so we know what size to make the bitmap
	clr	dx,di			;dx=Control flag,di = GState
	call	GrGetGStringBounds	;si = GString
	sub	cx,ax			;width in pixels
	
	mov	ax,GSSPT_BEGINNING	;set back to GString beginning
	call	GrSetGStringPos		;need to reset Gstring pos,as this is
					;affected by call to GrGetGStringBounds
	mov	ax,cx			;set width in pixels
	sub	dx,bx			;height in pixels
	mov	bx,dx
	clr	ch
	mov	cl,exportInfo.ETDFrame.EDF_exportOptions
	cmp	ax,0
	je	errorEmpty	
	cmp	bx,0
	jne	continue

;convenient places to put some error stubs, to avoid long jums
errorEmpty:
	mov	ax,TE_NOTHING_TO_EXPORT
	jmp	done
errorDIB:
	add	sp,2			;fixup stack pointer to leave
	jmp	done

continue:
	push	ax			;save the width of the Bitmap
	call	ETDCalculateStripSizeAndOffset

;set up the DIBBitmap FileHeader and Info structure in the specified DIBFile
	mov	dx,exportInfo.EBInfo.EBI_scanlineSize
	add	dx,exportInfo.EBInfo.EBI_scanlineDiff
	mov	di,exportInfo.ETDFrame.EDF_DIBFile
	call	ETDSetUpDIBHeader
	jc	errorDIB		;error code will be in ax
	
;Create and open a temp VM File		pass bp = IMPEX_TEMP_VM_FILE
	push	bp			;save to access locals
	segmov	es,ss,bx		;stack frame
	lea	di,exportInfo.tempVMFilename
	mov	ax,IMPEX_TEMP_VM_FILE
	call	ImpexCreateTempFile	;es:di  = temp filename buffer
	tst	ax			;ret bp = file handle
	mov	bx,bp
	pop	bp
	jnz	errorDIB		;error code in ax
	
;Create a Bitmap to play GString into
	push	bx			;save VM file handle
	mov	ax,TGIT_THREAD_HANDLE	;get thread handle
	clr	bx			;...for the current thread
	call	ThreadGetInfo		;ax = thread handle
	mov_tr	di,ax			;di = thread handle
	pop	bx			;restore VM file handle
	call	ETDSetBitmapType	;ax = bitmap type
	pop	cx			;cx = width,
	mov	dx,exportInfo.EBInfo.EBI_stripSize;dx = height
	push	bx			;TempVM,bx = VMFile Handle
	call	GrCreateBitmap		;ax=VM BLock- bx.ax = Huge Array Handle
	push	di			;GState
	push	bx,ax			;bx = temp VMB:H

;Set the default text color mapping to dither
	mov	al, ColorMapMode<0, CMT_DITHER>
	call	GrSetTextColorMap

;Play the GString into the Bitmap, and then convert it to a DIB
moreBitmap:				;Play the GString into a bitmap
	mov	bx,exportInfo.EBInfo.EBI_yTrans ;x,y = offset to start drawing at
	clr	ax,cx,dx		;dx.cx = x trans( WWF) bx.ax = ytrans
	call	GrApplyTranslation	;move window over bitmap
	call	GrSaveState		;Drawing GString may affect this
  	clr	ax,bx,dx		;xtrans
	call	GrDrawGString		;di = GState target,si = Gstring
	mov	ax,GSSPT_BEGINNING	;set back to GString beginning
	call	GrSetGStringPos		;need to reset Gstring pos
	call	GrRestoreState		;restore Gstate

;advance so next strip will be drawn
	pop	bx,ax			;get VMFile:Block
	cmp	dx,GSRT_FAULT		;if GrDrawGString unsuccessful
	je	errorExport
	push	bx,ax			;save Huge array handle

;convert to  DIB File
	mov	cx,exportInfo.ETDFrame.EDF_DIBFile
	call	ETDCBitmapToDIB
	jc	cleanup

;loop back up to moreBitmap
	call	GrClearBitmap		;pass di = GState
	dec	exportInfo.EBInfo.EBI_numStrips ;are there any more strips to draw?
	cmp	exportInfo.EBInfo.EBI_numStrips,0
	jne	moreBitmap

;destroy the temp bitmap, and the VMfile it is in
	mov	ax,TE_NO_ERROR		;successful export operation
cleanup:	
	add	sp,4			; pop bx,ax
delete:
	pop	di			;gstate handle
	pop	bx			;VMFileHandle
	call	ETDDeleteTempFile
	jc	errorDelete		
done:
	.leave
	ret
errorExport:
	mov	ax,TE_EXPORT_ERROR
	jmp	delete
errorDelete:
	mov	ax,TE_FILE_ERROR
	jmp	done
ExportGStringToDIB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportDIB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Exports a GString to the DIB format. The resulting
		bitmap is stored in the indicated file	

CALLED BY:	ImpexExportGraphicsConvertToDIBMetafile	
PASS:		
		bx	-VMFile		hptr
		si	-VMBlock	hptr
		di	-DIBFile	(lower word of stream pointer)
		cx	-ClipboardItemFormat( CIF_BITMAP or CIF_GRAPHICS_STRING)
		dx	-Bitcount	word
		ax	-maufacturer's ID

RETURN:		ax	-will be zero if the export was successful
			 otherwise will contain TransError
		bx:	-if ax = TE_CUSTOM will contain handle of error text

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	*Lock the block to access ExportFrame
	*Calculate StripSize and the number of strips:
		stripsize = num scanlines that fit in 100k block
		numStrips = num 100k blocks needed to hold bitmap
	  (the idea here is to repeatedly play the Gstring into a VM Bitmap,
	   which is of 100k block size or less,and translate it each time.In
	   this way only 100k of data is produced each time,keeping down the
	   memory allocation, and the window is just moved down the bitmap,
	   in order that the entire bitmap is produced, one chunk at a time.)
	*Setup the DIB header 
	*Create bitmap in a temp VMFile,setting type as specified in the
	   export options and vertical size stripsize
	*load the Gstring
	*For Num Strips:
		play Gstring into Bitmap
		write out scanlines to DIB
		Translate so next chunk of bitmap data will be generated
	*clean up- destroy VM and Bitmap
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	* the DIB source file stream pointer is passed to the DIB Library
	 in bx. This is actually  the low word of the stream pointer,
	 as the high word is always  zero.
	 ALL OF THE FOLLOWING DIB ROUTINES DEPEND UPON THIS!!!
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	3/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportDIB	proc	near
	.enter
	
	; first check to make sure this is not a 24-bit Export, 
	; as we do not support that yet
 	cmp	dx, 24
	je	unsupported24bit

	; do we recognize the Manufacturer's ID?
	cmp	ax, MANUFACTURER_ID_GEOWORKS
	jne	invalidManufacturerID

	; are we being passed a GSTRING or a HUGE BIIMAP ?
	cmp	cx, CIF_BITMAP
	jne	GString
	call	ExportHugeBitmapToDIB
	jmp	done
GString:
	mov	ax, TE_EXPORT_INVALID_CLIPBOARD_FORMAT	
	cmp	cx, CIF_GRAPHICS_STRING
	jne	done
	call	ExportGStringToDIB
done:
	.leave
	ret

invalidManufacturerID:
	mov	ax, TE_EXPORT_INVALID_CLIPBOARD_FORMAT	
	jmp	done

unsupported24bit:
	mov	ax, TE_EXPORT_NOT_SUPPORTED
	jmp	done
ExportDIB	endp
;-----------------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ETDDeleteTempFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	destroy Temp File and Bitmap in it	

CALLED BY:	ExportDIB
PASS:		di	-handle of GState holding Bitmap
		bx	-VM File 
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ETDDeleteTempFile	proc	near
	uses	ax,ds,dx

	exportInfo	local	ExportInfo
	.enter	inherit

	mov	al,BMD_LEAVE_DATA
	call	GrDestroyBitmap
	mov	ax,IMPEX_TEMP_VM_FILE
	segmov	ds,ss,dx
	lea	dx,exportInfo.tempVMFilename
	call	ImpexDeleteTempFile
	tst	ax
	jz	done
	stc			;an error has occurred in File Delete
done:
	.leave
	ret
ETDDeleteTempFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ETDSetBitmapType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the BMType according to the bitcount- will be
		complex with a palette, unless 24bit

CALLED BY:	ExportDIB
PASS:		cx=  bitcount
RETURN:		ax = bitmapType
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	3/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ETDSetBitmapType	proc	near
	.enter
	
	cmp	cx,1
	jne	fourBit
	mov	ax,BMF_MONO or mask BMT_COMPLEX or mask BMT_PALETTE
	jmp	done
fourBit:
	cmp	cx,4
	jne	eightBit
	mov	ax,BMF_4BIT or mask BMT_COMPLEX or mask BMT_PALETTE
	jmp	done
eightBit:
	cmp	cx,8
	jne	twentyFourBit
	mov	ax,BMF_8BIT or mask BMT_COMPLEX or mask BMT_PALETTE
	jmp	done
twentyFourBit:
	mov	ax,BMF_24BIT or mask BMT_COMPLEX 
done:	
	.leave
	ret
ETDSetBitmapType	endp
;------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ETDCBitmapToDIB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a slice of scanlines into the specified
		DIB File	

CALLED BY:	ExportDIB	
PASS:		cx:	DIB File( lower word of stream pointer)
		bx.ax	-HugeArray Handle
	
RETURN:		carry set if error		
		ax = error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	3/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ETDCBitmapToDIB	proc	near
	uses	es,bx,cx,dx,si,di,bp
	exportInfo	local	ExportInfo

	.enter	inherit

EC <	push	bx,ax			
EC < 	mov	di,ax
EC <    call	ECCheckHugeArray

;for num scanlines,write to file
	mov	di,ax			;VM Block Handle of HugeArray
	mov	ax,exportInfo.EBInfo.EBI_stripSize
	mov	exportInfo.EBInfo.EBI_yTrans,ax
EC <	tst	ax
EC < 	ERROR_Z	EXPORT_DIB_INVALID	;this should NEVER be zero
	tst	exportInfo.EBInfo.EBI_initStripSize
	jz	notFirstStrip
	mov	ax,exportInfo.EBInfo.EBI_initStripSize
	clr	exportInfo.EBInfo.EBI_initStripSize   
notFirstStrip:
	dec	ax			;process scanline x-1 -> 0
	push	ax			;save num scanlines in the strip
	push	cx			;save DIB File Handle
	clr	dx			;dx.ax holds scanline desired
	call	HugeArrayLock		;ds:si  pointer to scanline
					;ax = num after,cx = num before

	pop	bx			;bx is the DIB File,dx = size
;EC <	cmp	dx,exportInfo.EBInfo.EBI_scanlineSize
;EC <	ERROR_NE EXPORT_DIB_INVALID
	mov	di,cx			;di= numb of scanlines before next blk
writeScanlineLoop:	

	; check to see if it is a monochrome bitmap, if so,then we must invert
	; it to be consistent with the 0= white, 1= black paradigm
	cmp	exportInfo.ETDFrame.EDF_exportOptions,1
	je	invertMonochrome
writeScanline:
	mov	dx,si			;ds:dx is buffer to read from
  	clr	al			;flags=0
	mov	cx,exportInfo.EBInfo.EBI_scanlineSize
	call	FWrite			;ax = error,cx = numbytes written
	jc	cont			;error in file write
	mov	cx,exportInfo.EBInfo.EBI_scanlineDiff
	jcxz	cont
	push	ds
	segmov	ds,ss			;ds:dx = buffer to read from
	lea	dx,exportInfo.scanBuff
	clr	al			;flags
	call	FWrite			;write out extra bytes
	pop	ds			;restore ds
cont:
	pop	cx			;num of scanlines
	jc	errorWrite
	jcxz	done			;any more left?
	dec	cx			;we just read one
	push	cx			;save away num scanlines

EC <	tst	di			;this should NEVER be zero
EC <	ERROR_Z	EXPORT_DIB_INVALID

	dec 	di
	cmp	di,0
	je	nextBlock		;now move to next block
	sub	si,exportInfo.EBInfo.EBI_scanlineSize
	jmp	writeScanlineLoop
nextBlock:
;pass ds:si = pointer to element, get pointer to prev	
	call	HugeArrayPrev		;ds:di = first element,
	mov	di,ax			;ax = num prev(0 if first),dx = size
	jmp	writeScanlineLoop

done:
EC <	pop	bx,di
EC <	call	ECCheckHugeArray
	call	HugeArrayUnlock 	;ds = pointer to element block	

	.leave
	ret

invertMonochrome:
; the bitmap is monochrome, so flip all the bits so it will be consistent
; with the 0=white, 1 = black Monochrome bitmap color scheme
	push	si,di,cx
	segmov	es,ds,dx
	mov	di,si
	mov	cx,exportInfo.EBInfo.EBI_scanlineSize
	mov	dl,0xff
invertLoop:
	lodsb
	xor	al,dl
	stosb
	loop	invertLoop

	pop	si,di,cx
	jmp	writeScanline
	
errorWrite:
	mov	ax,TE_FILE_WRITE
	jmp	done
ETDCBitmapToDIB	endp

;-----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ETDSetUpDIBHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the DIB FIle Header and DIB info header
		in the specified file. These structures are as follows:
			FILEHEADER:
				DBFH_type	BitmapType
				DBFH_size	dword
				DBFH_reserved	dword
				DBFH_offBit	dword

			INFOHEADER:
				DBI_size	dword
				DBI_width	dword
				DBI_height	dword
				DBI_planes	word
				DBI_bitCount	word
				DBI_compress	dword
				DBI_isize	dword
				DBI_xRes	dword
				DBI_yRes	dword
				DBI_colorUsed	dword
				DBI_colorImp	dword
		*for more info see dib.def				

CALLED BY:	ExportDIB
PASS:		
		di	DIB File (lower word of stream pointer)	
		ax	-bitmap	width
		bx	-bitmap	height
		cx	-BitCount	
		dx	-ScanlineSize

RETURN:		ax is error if carry set
DESTROYED:	ax
PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	3/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ETDSetUpDIBHeader	proc	near
	uses	bx,cx,dx,si,di,bp,ds
	locals	local	DIBBitmapHeader
	.enter

	mov	locals.DB_fileHeader.DBFH_type,BITMAP

	mov	locals.DB_info.DBI_width.high,0			
	mov	locals.DB_info.DBI_width.low,ax			
	mov	locals.DB_info.DBI_height.high,0			
	mov	locals.DB_info.DBI_height.low,bx

	mov	locals.DB_info.DBI_bitCnt,cx
	clr	ax
	cmp	cx,24
	je	twFourBit
	mov	ax,1			;num colors = 2^Bitcount
	shl	ax,cl
twFourBit:
	push	ax			;num entries in color table
	clr	cx
	movdw	locals.DB_info.DBI_colorUsed,cxax
	movdw	locals.DB_info.DBI_colorImp,cxax ;num colors important=numUsed
	shl	ax,1			;ax = size of color table
	shl	ax,1			;4bytes/entry
	push	ax			;size color table
;add color table size header and info 		
	add	ax,size DIBBitmapHeader ;data right after hdr & color table 
	movdw	locals.DB_fileHeader.DBFH_offBit,cxax
	mov	cx,ax
	mov	ax,dx			;add size of image
	mul	bx	
	movdw	locals.DB_info.DBI_iSize,dxax			

	clr	bx
	adddw	dxax,bxcx
	movdw	locals.DB_fileHeader.DBFH_size,dxax
	clr	cx	
	movdw	locals.DB_fileHeader.DBFH_reserved,bxcx
	mov	locals.DB_info.DBI_size.high,0
	mov	locals.DB_info.DBI_size.low,size DIBBitmapInfo
	mov	locals.DB_info.DBI_planes,1		
	movdw	locals.DB_info.DBI_compress,bxcx			
	movdw	locals.DB_info.DBI_xRes,bxcx			
	movdw	locals.DB_info.DBI_yRes,bxcx			

;now write the header to the specified DIB File
	mov	bx,di			;file to write to
	mov	cx,size	DIBBitmapHeader ;number of bytes to write
	segmov	ds,ss			;write from the local structure
	lea	dx,locals
	clr     al			;so returns errors
	call	FWrite			
	pop	dx			;size color table (bytes)
	pop	cx			;num colors in table
	jc	errorWrite		;error will be in ax
	jcxz	done			;24bit,no colortable
;write the palette default palette to the DIBFile
	call	ETDWritePaletteToDIB

done:
	.leave
	ret
errorWrite:
	mov	ax,TE_FILE_WRITE
	jmp	done
ETDSetUpDIBHeader	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ETDWritePaletteToDIB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the default Geos color table to the DIB file
		specified	

CALLED BY:	SetUpDIBHeader		
PASS:		bx   -DIBFile (lower word of stream pointer)
		dx   -size color table
		cx   -numEntries		
RETURN:		carry set if error
		error in ax-

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		-calls GrGetPalette, which will return all 256 RGB
		 triples
		-Writes out the appropriate number to a DIB File, first 
		 converting the triples into DIB RGBQuad format:		 			i.e. RGBQuad{
					BYTE	rgbBlue;
					BYTE	rgbGreen;
					BYTE	rgbRed;
					BYTE	rgbReserved;
					}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	3/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ETDWritePaletteToDIB	proc	near
	uses 	bx,cx,dx,si,di,bp,ds,es
	.enter

	mov	bp,bx			;save DIBFileHandle	
	mov	ax,dx			;ax is size to allocate
	mov	si,cx			;cx = numEntries,save in si
	mov	cx,ALLOC_DYNAMIC_LOCK	;cx = HeapFlags and heapAllocFlags
	call	MemAlloc		
	jc	errorMem		;ret:bx = handle ax = seg
	push	bx			;ColorTable buffer
	segmov	es,ax			;es:di will be dest
	clr	di			;di =assoc window

	; set up assuming will be monochrome
	;
	movdw	es:[di],   0x00000000	; 0 entry is white
	movdw	es:[di+4], 0x00ffffff	; 1 entry is black
	cmp	si,2			; if monochrome, set by hand
	je	writeTable

	; it is not monochrome, so get default palette
	;	
	mov	al,GPT_DEFAULT
	call	GrGetPalette		;bx = handle to 
	call	MemLock			;bx = block to lock,return ax = segment
	jc	errorLock
	clr	di			;es:di is the destination
	mov	cx,si			;num entries
	segmov	ds,ax			;ds points to palette
	mov	si,2			;ds:si = palette
	push	bx			;save handle to palette
	clr	bh			;for reserved byte
writeColorTable: 
	; moves ds:si->es:di- because these are RGB bytes, and a word is
	;  loaded and stored, the order will be reversed.
	;
	lodsw				;ax<-GR
	mov	bl,al			;bh = R, ah =G
	lodsb				;al = B
	stosw				;stores BG to es:di	
	mov	ax,bx			;ax = 0R	
	stosw				;store R0
	loop	writeColorTable

	pop	bx			;get handle to palette
	call	MemFree			;pass memBlock to unlock in bx
writeTable:
	mov	bx,bp			;bx = fileHandle
	clr	al			;al = flags -0
	mov	cx,dx			;cx= size of colorTable
	segmov	ds,es			;ds:dx = file from which to write
	clr	dx		
	call	FWrite			;ax= error,cx = numbytes
	jc	errorWrite

	pop	bx			;get handle to the color table buffer
	call	MemFree			;free this also
	clc
done:
	.leave
	ret
errorLock:
	mov	ax,TE_EXPORT_ERROR
	jmp	error
errorWrite:
	mov	ax,TE_FILE_WRITE
error:
	pop	bx			;get handle to the color table buffer
	call	MemFree			;free this also
	jmp	done
errorMem:
	mov	ax,TE_EXPORT_ERROR
	jmp	done

ETDWritePaletteToDIB	endp
;-------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ETDGetScanlineSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: Determine the number of bytes per scanline, as well as the number
	  of bytes if the scanline is aligned on a long boundary.
	  This information is stored in the inherited exportInfo	

CALLED BY:	ETDCalculateStripSizeAndOffset	

PASS:		cx	-BitCount
		bx	-bitmap height
		ax	-bitmap	width		
RETURN:		update exportInfo struct		

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	3/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ETDGetScanlineSize	proc	near
	uses	ax,bx,cx,dx
	exportInfo	local	ExportInfo
	.enter	inherit

	mul	cx			;(pixels/scanline)*(bits/pixel)
	mov	dx,ax			;save bytes/scanline
	add	ax,7			;(bits/scanline)+7
	mov	cl,3			;div by 8
	shr	ax,cl			;bytes/scanline
	mov	exportInfo.EBInfo.EBI_scanlineSize,ax	
	add	dx,31			;want to align on long boundary
	mov	cl,5			;div by 32
	shr	dx,cl			;bits+31/32
	shl	dx,1
	shl	dx,1			;mult by 4
	sub	dx,ax			;get difference and set
	mov	exportInfo.EBInfo.EBI_scanlineDiff,dx	
	movdw	exportInfo.scanBuff,0	;make sure buff that you will write
					;any additional bytes out from is
	.leave
	ret
ETDGetScanlineSize	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ETDCalculateStripSizeAndOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	calculates the number of scanlines that will fit into our
		temporary bitmap (of size DIB_EXPORT_BUFF_SIZE), as well as
		the offset to translate the bitmap such that any remaining
		scanlines(remainder of scanlines/(scanlines/block)) will be
		handled first. The DIB format has the origin at the lower
		left, and the CBitmap's origin is the upper left, therefore,
		the last scanline in the DIB is the first one in the bitmap.	

CALLED BY:	ExportDIB	
PASS:		cx	-BitCount
		bx	-bitmap height
		ax	-bitmap	width
RETURN:		nothing	
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	3/13/92		Initial version
	Don	8/04/94		Fixed comparison error & reduced buffer size
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ETDCalculateStripSizeAndOffset	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	exportInfo local ExportInfo
	.enter inherit

;calulate bytes/scanline = ((pixels/scanline)*(bits/pixel)+7)*(byte/8bits)
	call	ETDGetScanlineSize
	mov	cx, exportInfo.EBInfo.EBI_scanlineSize
	CheckHack <DIB_EXPORT_BUFF_SIZE lt 65536>
	mov	ax, DIB_EXPORT_BUFF_SIZE;rough size of temporary bitmap
	clr	dx
	div	cx			;ax = num scanlines in temporary bitmap
	cmp	ax,bx			;num scans/temp > num/bitmap?
	jb	moreThanOneStrip		
	mov	exportInfo.EBInfo.EBI_stripSize,bx
	mov	exportInfo.EBInfo.EBI_numStrips,1
	mov	exportInfo.EBInfo.EBI_initStripSize,bx
	mov	exportInfo.EBInfo.EBI_yTrans,0
	jmp	done
moreThanOneStrip:
	mov	exportInfo.EBInfo.EBI_stripSize,ax	;set strip size

;now need #blocks/bitmap = (#scanline/bitmap)/( scanlines/block)
	mov	cx,ax	;num scanlines/block			
	mov	ax,bx	;(num scanline/bitmap)
	clr	dx	;dxax/cx result in ax, remainder in dx
	div	cx
	inc	ax	;there is at least one
	mov	exportInfo.EBInfo.EBI_numStrips,ax	;set number of strips/bitmap
;numscanlines-remainder = where to translate to
	tst	dx			;is there a remainder?
	jnz	remainder		;yes, set init trans and  strip size
	mov	dx,exportInfo.EBInfo.EBI_stripSize 	
					;initial strip and ytrans = strip size

	mov	exportInfo.EBInfo.EBI_initStripSize,dx ;set initial stripSize
	sub	bx,dx			;num scanlines from the end
	jmp	setTrans
remainder: ;if dx not zero,initial size is rem
	mov	exportInfo.EBInfo.EBI_initStripSize,dx
	sub	bx,dx			;dx = remainder,
setTrans:
	neg	bx			;set the translation
	mov	exportInfo.EBInfo.EBI_yTrans,bx
done:
	.leave
	ret
ETDCalculateStripSizeAndOffset	endp
;---------------------------------------------------------------------------

ExportCode	ends
