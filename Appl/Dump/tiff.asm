COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Screen Dumps -- TIFF Form
FILE:		eps.asm

AUTHOR:		Adam de Boor, Dec  4, 1989

ROUTINES:
	Name			Description
	----			-----------
	TiffPrologue		Initialize file
	TiffSlice		Write a bitmap slice to the file
	TiffEpilogue		Cleanup

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1 /15/89	Initial revision


DESCRIPTION:
	Output-dependent routines for creating a TIFF file.
		
	A TIFF file is laid out as a series of Image File Directories,
	which contain fields to describe a single image. Each field in the
	directory contains a tag to identify the field, an indication of the
	type of data stored in the field (some fields can accept more than
	one type of data), a count of the number of data elements in the
	field's value and an offset from the header for the file (which need
	not be at the start of the physical file itself, note) to the field's
	value. If the field's value will fit in four bytes, it is stored in
	place of the offset.
	
	The data for the image itself is divided into strips containing
	a number of rows given in the IFD.
	
	NOTE: for StripOffsets and StripByteCounts: if image fits in a single
	strip, the offset and count must be placed in the IFD...

	$Id: tiff.asm,v 1.1 97/04/04 15:36:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	dump.def
include	file.def
include psc.def		; For PSCSlice
; NEW .def files for 2.0
include Internal/videoDr.def

TIFF_MAX_SLICES		equ	64	; a VGA screen (640x480) should fit in
					;  18 slices, so this should be plenty
;------------------------------------------------------------------------------
;
;			   TYPE DEFINITIONS
;
;------------------------------------------------------------------------------
;
; Tags indicating type of data stored for a field
;
TiffDTypes	etype	word, 1
    TDT_BYTE	enum	TiffDTypes	; 8-bit unsigned integer
    TDT_ASCII	enum	TiffDTypes	; 8-bit ASCII, null-terminated string
    TDT_SHORT	enum	TiffDTypes	; 16-bit unsigned integer
    TDT_LONG	enum	TiffDTypes	; 32-bit unsigned integer
    TDT_RATIONAL enum	TiffDTypes	; Two TDT_LONG's: first is the numerator
					;  of a fraction, the second is the
					;  denominator.

;
; Values for the PhotometricInterpretation field.
;
TiffPhotoInterp	etype	word, 0
    TPI_WB	enum	TiffPhotoInterp	; 0 is white, 1 is black
    TPI_BW	enum	TiffPhotoInterp	; 0 is black, 1 is white
    TPI_RGB	enum	TiffPhotoInterp	; Pixel is combo of R, G, and B
					;  values for it.
    TPI_PALETTE	enum	TiffPhotoInterp	; Pixel is index into ColorMap field
    TPI_MASK	enum	TiffPhotoInterp	; Image is a transparency mask for some
					;  other image in the file

;
; Types of compression possible in a TIFF file. For now, we only implement
; PACKBITS compression.
;
TiffCompressions etype	word
    TC_NONE	enum	TiffCompressions, 1	; no compression -- just simple
						;  pixel-packing
    TC_CCITT3	enum	TiffCompressions, 2	; modified Huffman run-length
						;  encoding
    TC_LZW	enum	TiffCompressions, 5	; LZW compression for greyscale,
						;  palette color and fullcolor
						;  images.
    TC_PACKBITS	enum	TiffCompressions, 32773	; Macintosh PackBits encoding

;
; Structure for a RATIONAL.
;
TiffRational	struct
    TR_numerator	dword
    TR_denominator	dword
TiffRational	ends

;
; Header for the file. Must start on a word boundary (TiffPrologue assumes
; it's already at a word boundary -- it is up to the caller to ensure this).
;
TiffHeader	struct
    TH_order	char	'II'		; byte-order signature. Were we on a
					;  big-endian machine, this would be
					;  'MM'
    TH_version	word	42		; Magic version number
    TH_ifd	dword	0		; Offset to the first IFD in the file
TiffHeader	ends

;
; Defined field tags. NOTE: Naming convention breakdown to follow the names
; given in TIFF spec. For each tag, the acceptable type(s) and the expected
; TF_count field (N) is given. Most of these we don't use, but....
;
TiffTags	etype	word
    TT_NewSubfileType	enum	TiffTags, 254	; TDT_LONG, N = 1
    TT_SubfileType	enum	TiffTags, 255	; TDT_SHORT, N = 1
    TT_ImageWidth	enum	TiffTags, 256	; TDT_LONG/TDT_SHORT, N = 1
    TT_ImageLength	enum	TiffTags, 257	; TDT_LONG/TDT_SHORT, N = 1
    TT_BitsPerSample	enum	TiffTags, 258	; TDT_SHORT,
						;  N = TT_SamplesPerPixel
    TT_Compression	enum	TiffTags, 259	; TDT_SHORT (see
						;  TiffCompressionTypes),
						;  N = 1
    TT_PhotometricInterpretation enum TiffTags, 262; TDT_SHORT, N = 1
    TT_Thresholding	enum	TiffTags, 263	; TDT_SHORT, N = 1
    TT_CellWidth	enum	TiffTags, 264	; TDT_SHORT, N = 1
    TT_CellLength	enum	TiffTags, 265	; TDT_SHORT, N = 1
    TT_FillOrder	enum	TiffTags, 266	; TDT_SHORT, N = 1
    TT_DocumentName	enum	TiffTags, 269	; TDT_ASCII
    TT_ImageDescription enum	TiffTags, 270	; TDT_ASCII
    TT_Make		enum	TiffTags, 271	; TDT_ASCII
    TT_Model		enum	TiffTags, 272	; TDT_ASCII
    TT_StripOffsets	enum	TiffTags, 273	; TDT_SHORT/TDT_LONG,
						;  N = StripsPerImage for us
    TT_Orientation	enum	TiffTags, 274	; TDT_SHORT, N = 1
    TT_SamplesPerPixel	enum	TiffTags, 277	; TDT_SHORT, N = 1
    TT_RowsPerStrip	enum	TiffTags, 278	; TDT_SHORT/TDT_LONG, N = 1
    TT_StripByteCounts	enum	TiffTags, 279	; TDT_SHORT/TDT_LONG,
						;  N = StripsPerImage for us
    TT_MinSampleValue	enum	TiffTags, 280	; TDT_SHORT, N = SamplesPerPixel
    TT_MaxSampleValue	enum	TiffTags, 281	; TDT_SHORT, N = SamplesPerPixel
    TT_XResolution	enum	TiffTags, 282	; TDT_RATIONAL, N = 1
    TT_YResolution	enum	TiffTags, 283	; TDT_RATIONAL, N = 1
    TT_PlanarConfiguration enum	TiffTags, 284	; TDT_SHORT, N = 1
    TT_PageName		enum	TiffTags, 285	; TDT_ASCII
    TT_XPosition	enum	TiffTags, 286	; TDT_RATIONAL, N = 1
    TT_YPosition	enum	TiffTags, 287	; TDT_RATIONAL, N = 1
    TT_FreeOffsets	enum	TiffTags, 288	; TDT_LONG
    TT_FreeByteCounts	enum	TiffTags, 289	; TDT_LONG
    TT_GrayResponseUnit	enum	TiffTags, 290	; TDT_SHORT, N = 1
    TT_GrayResponseCurve enum	TiffTags, 291	; TDT_SHORT,
						;  N = 2**BitsPerSample
    TT_Group3Options	enum	TiffTags, 292	; TDT_LONG, N = 1
    TT_Group4Options	enum	TiffTags, 293	; TDT_LONG, N = 1
    TT_ResolutionUnit	enum	TiffTags, 296	; TDT_SHORT, N = 1
    TT_PageNumber	enum	TiffTags, 297	; TDT_SHORT, N = 2
    TT_ColorResponseCurve enum	TiffTags, 301	; TDT_SHORT,
						;  N = 3 * (2**BitsPerSample)
    TT_Software		enum	TiffTags, 305	; TDT_ASCII
    TT_DateTime		enum	TiffTags, 306	; TDT_ASCII
    TT_Artist		enum	TiffTags, 315	; TDT_ASCII
    TT_HostComputer	enum	TiffTags, 316	; TDT_ASCII
    TT_Predictor	enum	TiffTags, 317	; TDT_SHORT, N = 1
    TT_WhitePoint	enum	TiffTags, 318	; TDT_RATIONAL, N = 2
    TT_PrimaryChromaticities enum TiffTags, 319	; TDT_RATIONAL, N = 6
    TT_ColorMap		enum	TiffTags, 320	; TDT_SHORT,
						;  N = 3 * (2**BitsPerSample)

;
; An individual field in an IFD. These must be sorted in order of increasing
; tag number.
;
TiffField	struct
    TF_tag	TiffTags		; Type of field
    TF_type	TiffDTypes		; Type of data stored as the field value
    TF_count	dword			; Number of aforementioned data elements
    					;  stored in the field.
    TF_offset	dword			; Location in the file at which the
    					;  field's value is stored. If the total
					;  size of the value is <= 4 bytes,
					;  the value is stored in this field,
					;  rather than elsewhere in the file.
TiffField	ends

;
; The file is organized into a series of IFD (Image File Directory) structures
; placed anywhere in the file. If we wrote more than one, we'd have more than
; one :), but we don't, so don't worry about it.
;
TiffIFD		struct
    TIFD_length	word			; Number of fields in the IFD
    TIFD_fields	label	TiffField	; Start of field table. After the table
    					;  comes the four-byte offset of the
					;  next IFD in the file. We always write
					;  that as 0.
TiffIFD		ends

idata	segment

TiffProcs	DumpProcs	<
	0,
	TiffPrologue,
	TiffSlice,
	TiffEpilogue,
	<'tif'>,
	mask DUI_TIFFBOX or mask DUI_ANNOTATION or \
	mask DUI_DESTDIR or mask DUI_BASENAME or mask DUI_DUMPNUMBER
>

tiffHeader	TiffHeader	<>

;============================================================
;
;	IFD for file
;
tiffIFD		TiffIFD	<(tiffIFDEnd-tiffIFDStart)/size TiffField>
tiffIFDStart	label	TiffField
		;
		; Indicate subfile type: full-resolution, not multi-page,
		; not transparency mask.
		;
		TiffField	<TT_NewSubfileType, TDT_LONG, 1, 0>
		;
		; Following are filled in by Prologue function
		;
tiffImageWidth	TiffField	<TT_ImageWidth, TDT_SHORT, 1, 0>
tiffImageLength	TiffField	<TT_ImageLength, TDT_SHORT, 1, 0>
tiffBitsPerSample TiffField	<TT_BitsPerSample, TDT_SHORT, 1, 0>
tiffCompression	TiffField	<TT_Compression, TDT_SHORT, 1, TC_NONE>
	ForceRef tiffCompression
tiffPhotoInterp	TiffField	<TT_PhotometricInterpretation,
				 TDT_SHORT, 1, TPI_BW>
		;
		; StripOffsets filled in by Prologue (TF_count) and Epilogue
		; (TF_offset); table for same filled by Slice.
		;
tiffStripOffsets TiffField	<TT_StripOffsets, TDT_LONG, 0, 0>
		;
		; Until we get 24-bit color, this is always 1...
		;
tiffSamplesPerPixel TiffField	<TT_SamplesPerPixel, TDT_SHORT, 1, 1>
		ForceRef	tiffSamplesPerPixel
		;
		; Filled in by Prologue.
		;
tiffRowsPerStrip TiffField	<TT_RowsPerStrip, TDT_SHORT, 1, 0>
		;
		; StripByteCounts filled in by Prologue (TF_count) and Epilogue
		; (TF_offset); table for same filled by Slice.
		;
tiffStripCounts	TiffField	<TT_StripByteCounts, TDT_LONG, 0, 0>
		;
		; More fields to be filled by Prologue
		;
tiffXResolution	TiffField	<TT_XResolution, TDT_RATIONAL, 1, 0>
tiffYResolution	TiffField	<TT_YResolution, TDT_RATIONAL, 1, 0>
		;
		; Another "Until we get 24-bit color" field. 1 => one plane
		; with all samples for a pixel consecutive.
		;
tiffPlanarConfig TiffField	<TT_PlanarConfiguration, TDT_SHORT, 1, 1>
		ForceRef	tiffPlanarConfig
		;
		; Resolution is w.r.t. an inch
		;
		TiffField	<TT_ResolutionUnit, TDT_SHORT, 1, 2>
		;
		; Color map. For now it's just 16 colors. The TF_offset is
		; set when the map is written out.
		;
tiffColorMap	TiffField	<TT_ColorMap, TDT_SHORT, 16*3, 0>
tiffIFDEnd	label	TiffField
		dword		0	; Offset of next IFD (none!)
tiffIFDRealEnd	label	byte

;============================================================
;
;	Data values for the fields before writing
;
resolutionBuffer TiffRational	<0, 1>	; resolutions are known in dots/inch,
					;  giving a denominator of 1. The units
					;  gotten from the driver's DevInfo
					;  struct is just stuck in the low word
					;  of the numerator here before the
					;  whole thing is written out.

; Color map written to the file for a 16-color dump.  Refer to pcx.asm for
; the different indices.
colorMap4Red	word	0x0000, 0x0000, 0x0000, 0x0000,
			0xaa00, 0xaa00, 0xaa00, 0xaa00,
			0x5500, 0x5500, 0x5500, 0x5500,
			0xff00, 0xff00, 0xff00, 0xff00
colorMap4Green	word	0x0000, 0x0000, 0xaa00, 0xaa00,
			0x0000, 0x0000, 0x5500, 0xaa00,
			0x5500, 0x5500, 0xff00, 0xff00,
			0x5500, 0x5500, 0xff00, 0xff00
colorMap4Blue	word	0x0000, 0xaa00, 0x0000, 0xaa00,
			0x0000, 0xaa00, 0x0000, 0xaa00,
			0x5500, 0xff00, 0x5500, 0xff00,
			0x5500, 0xff00, 0x5500, 0xff00
	ForceRef colorMap4Green	; written out based on colorMap4Red
	ForceRef colorMap4Blue	; written out based on colorMap4Red
	

;;; We no longer appear to write out a color map in the 1-bit case...
;;; 				 -- ardeb 9/15/94
;;;colorMap1Red	word	0x0000, 0xffff
;;;colorMap1Green	word	0x0000, 0xffff
;;;colorMap1Blue	word	0x0000, 0xffff
;;;	ForceRef colorMap1Green	; written out based on colorMap1Red
;;;	ForceRef colorMap1Blue	; written out based on colorMap1Red

COLOR_MAP_4_LENGTH	equ	length colorMap4Red + \
				length colorMap4Green + \
				length colorMap4Blue
;;;COLOR_MAP_1_LENGTH	equ	length colorMap1Red + \
;;;				length colorMap1Green + \
;;;				length colorMap1Blue

idata	ends

udata	segment

sliceOffsets	dword	TIFF_MAX_SLICES dup(?)
sliceCounts	dword	TIFF_MAX_SLICES dup(?)

udata	ends

;------------------------------------------------------------------------------
;
;			   OTHER VARIABLES
;
;------------------------------------------------------------------------------
udata	segment
curOff		dword			; Current file offset
curSlice	word			; index of next slice (initialized to
					;  0 by TiffPrologue)
headerOff	dword			; Absolute offset in the file of the
					;  header
udata	ends

Tiff	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TiffPrologue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a TIFF file

CALLED BY:	DumpScreen
PASS:		si	= BMFormat
		bp	= file handle
		cx	= dump width
		dx	= dump height
		sliceHeight set to maximum height of a slice.
RETURN:		Carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TiffPrologue	proc	far
		.enter
		cmp	si, BMF_MONO
		je	weCanHandleThis
		cmp	si, BMF_4BIT
		je	weCanHandleThis
		stc
		jmp	done
weCanHandleThis:
	;
	; Initialize counters for the file.
	;
		mov	ds:curOff.low, size TiffHeader
		mov	ds:curOff.high, 0
		mov	ds:curSlice, 0
	;
	; Record the width, height, and rows per strip for the image.
	;
		mov	ds:tiffImageLength.TF_offset.low, dx
		mov	ds:tiffImageWidth.TF_offset.low, cx
		mov	ax, ds:sliceHeight
		mov	ds:tiffRowsPerStrip.TF_offset.low, ax
	;
	; Set the bits per sample and the length of the color map based on the
	; bitmap format. We also set the PhotometricInterpretation to
	; TPI_PALETTE if we're working with a 4-bit image.
	;
		mov	ax, 1
;;; Don't write color map out in non-4-bit case, so value doesn't matter
;;;		mov	di, COLOR_MAP_1_LENGTH
		clr	di
		cmp	si, BMF_4BIT
		jne	10$
		mov	ax, 4
		mov	di, COLOR_MAP_4_LENGTH
		cmp	ds:[procVars].DI_tiffColorScheme, TCS_PALETTE
		jne	10$
		mov	ds:tiffPhotoInterp.TF_offset.low, TPI_PALETTE
10$:
		mov	ds:tiffBitsPerSample.TF_offset.low, ax
		mov	ds:tiffColorMap.TF_count.low, di
	;
	; Make room for the header by seeking forward its size. This
	; also tells us where to seek back to when we need to
	; write out the header itself.
	;
		mov	al, FILE_POS_RELATIVE
		mov	dx, size TiffHeader
		clr	cx
		mov	bx, bp
		call	FilePos
	;
	; Back the new position up by the size of the header and
	; save the result.
	;
		sub	ax, size TiffHeader
		sbb	dx, 0
		mov	ds:headerOff.low, ax
		mov	ds:headerOff.high, dx
		clc
done:
		.leave
		ret
TiffPrologue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TiffSlice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a single bitmap slice out to the file

CALLED BY:	DumpScreen
PASS:		bp	= file handle
		si	= bitmap block handle
		cx	= size of bitmap (bytes)
RETURN:		Carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
				

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This thing should do packbits compression for mono data at least
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TiffSlice	proc	far	uses dx, ds, es
		.enter
		mov	bx, ds:curSlice		; bx <- index into dword tables
		shl	bx
		shl	bx
	;
	; Fetch and store the current file offset in the sliceOffsets
	; array.
	;
		mov	ax, ds:curOff.low
		mov	ds:sliceOffsets[bx].low, ax
		mov	dx, ds:curOff.high
		mov	ds:sliceOffsets[bx].high, dx
	;
	; Round the slice size up to a word (TIFF likes things on word
	; boundaries).
	;
		sub	cx, size Bitmap-1
		andnf	cx, not 1
	;
	; Store it in the sliceCounts array (we never write anything
	; larger than 64K, so no need to worry about it.
	;
		mov	ds:sliceCounts[bx].low, cx
		mov	ds:sliceCounts[bx].high, 0
	;
	; Adjust the file offset by the number of bytes we're going to
	; write, storing the new offset back into curOff.
	;
		add	ax, cx
		adc	dx, 0
		mov	ds:curOff.low, ax
		mov	ds:curOff.high, dx
		inc	ds:curSlice
	;
	; Lock the memory block down and write the whole thing out
	; at once.
	;
		segmov	es, ds		; es <- dgroup
		mov	bx, si
		call	MemLock
		mov	ds, ax
		;
		; If the bitmap isn't monochrome, see if we have to convert it
		; to grayscale first.
		; 
		mov	al, ds:[B_type]
		andnf	al, mask BMT_FORMAT
		cmp	al, BMF_MONO
		je	invert
		cmp	es:[procVars].DI_tiffColorScheme, TCS_GRAY
		jne	writeBitmap
		
		call	TiffConvertToGray
writeBitmap:
		mov	bx, bp		; bx <- file handle
		clr	al		; Give Me Errors
		mov	dx, size Bitmap	; data start after the header...
		call	FileWrite	; cx still holds size
	;
	; Free the memory block, making sure to preserve any
	; error from the FileWrite.
	;
		pushf
		mov	bx, si
		call	MemFree
		popf
		.leave
		ret
invert:
	;
	; In theory, we could just set the photometric interpretation, but
	; our TIFF import library doesn't deal with that correctly, so
	; rather than look stupid when we can't import our own TIFF dumps,
	; we invert the data now.
	;
		call	TiffInvertBitmap
		jmp	writeBitmap
TiffSlice	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TiffConvertToGray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the bitmap to grayscale from 4-bit color.

CALLED BY:	TiffSlice
PASS:		ds	= bitmap segment
		cx	= number of bytes in the bitmap (excluding header)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
; mapping of EGA/VGA pixels to linear grayscales, from psc.asm
tiffPixelToGray	byte	0, 1, 5, 7, 2, 3, 9, 11, 4, 6, 12, 13, 8, 10, 14, 15

TiffConvertToGray proc	near	uses es, di, si, cx, ax, bx
		.enter
		mov	si, size Bitmap
		mov	di, si
		segmov	es, ds
		mov	bx, offset tiffPixelToGray
convertLoop:
		lodsb
		mov	ah, al
		andnf	al, 0x0f
		xlat	cs:[tiffPixelToGray]
		
		xchg	al, ah
		shr	al
		shr	al
		shr	al
		shr	al
		xlat	cs:[tiffPixelToGray]
		shl	al
		shl	al
		shl	al
		shl	al
		or	al, ah
		stosb
		loop	convertLoop
		.leave
		ret
TiffConvertToGray endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TiffInvertBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert the monochrome bitmap so we don't look silly when
		another part of the system imports the thing inverted, owing
		to its ignoring the photometric interpretation of the file.

CALLED BY:	TiffSlice
PASS:		ds	= bitmap segment
		cx	= number of bytes in the bitmap (excluding header)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/31/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TiffInvertBitmap proc	near	uses es, di, si, cx, ax
		.enter
		mov	si, size Bitmap
		mov	di, si
		segmov	es, ds
convertLoop:
		lodsb
		not	al
		stosb
		loop	convertLoop
		.leave
		ret
TiffInvertBitmap endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TiffSetResolution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the X and Y resolution for the image based on the
		information provided by the video driver that was running
		the bits we just finished writing.

CALLED BY:	TiffEpilogue
PASS:		ds	= dgroup
		bp	= file handle
RETURN:		carry set if couldn't write
		curOff updated to account for the two TiffRational structures
			written out.
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TiffSetResolution proc	near	uses es, di
		.enter
		les	di, ds:vidDriver
		mov	ax, es:[di].VDI_vRes
		mov	ds:resolutionBuffer.TR_numerator.low, ax
		mov	cx, size resolutionBuffer
		mov	dx, offset resolutionBuffer
		mov	bx, bp
		clr	al		; return errors
		call	FileWrite
		jc	done
	;
	; Set the file offsets for both the Y and the X resolution
	; fields at once.
	;
		mov	ax, ds:curOff.low
		mov	dx, ds:curOff.high
		mov	ds:tiffYResolution.TF_offset.low, ax
		mov	ds:tiffYResolution.TF_offset.high, dx
		add	ax, size resolutionBuffer
		adc	dx, 0
		mov	ds:tiffXResolution.TF_offset.low, ax
		mov	ds:tiffXResolution.TF_offset.high, dx
		add	ax, size resolutionBuffer
		adc	dx, 0
		mov	ds:curOff.low, ax
		mov	ds:curOff.high, dx

	;
	; Write out the horizontal resolution as a rational.
	;
		mov	ax, es:[di].VDI_hRes
		mov	ds:resolutionBuffer.TR_numerator.low, ax
		mov	cx, size resolutionBuffer
		mov	dx, offset resolutionBuffer
		mov	bx, bp
		clr	al		; return errors
		call	FileWrite
done:
		.leave
		ret
TiffSetResolution endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TiffWriteSliceTables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the values for the StripByteCounts and StripOffsets
		fields in the IFD.

CALLED BY:	TiffEpilogue
PASS:		bp	= file handle
		ds	= dgroup
RETURN:		carry set on error
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TiffWriteSliceTables proc near
		.enter
	;
	; Set the count fields for both StripByteCounts and the
	; StripOffsets fields to the number of slices written.
	;
		mov	ax, ds:curSlice
		mov	ds:tiffStripCounts.TF_count.low, ax
		mov	ds:tiffStripOffsets.TF_count.low, ax
		cmp	ax, 1
		jbe	singleSlice
	;
	; Figure and store the file positions for both tables.
	;
		mov_tr	cx, ax
		mov	ax, ds:curOff.high
		mov	ds:tiffStripOffsets.TF_offset.high, ax
		mov_tr	dx, ax
		mov	ax, ds:curOff.low
		mov	ds:tiffStripOffsets.TF_offset.low, ax
		shl	cx			; Each element is a dword...
		shl	cx
		add	ax, cx
		adc	dx, 0
		mov	ds:tiffStripCounts.TF_offset.low, ax
		mov	ds:tiffStripCounts.TF_offset.high, dx
		add	ax, cx
		adc	dx, 0
		mov	ds:curOff.low, ax
		mov	ds:curOff.high, dx
	;
	; Write the StripOffsets table first
	;
		mov	dx, offset sliceOffsets
		clr	al		; return errors
		mov	bx, bp
		call	FileWrite
		jc	done
	;
	; Then the StripByteCounts table
	;
		mov	dx, offset sliceCounts
		clr	al		; return us errors
		call	FileWrite
done:
		.leave
		ret
singleSlice:
	;
	; Only one slice written, so just store the offset and length
	; of it in the IFD itself.
	;
		mov	ax, ds:sliceOffsets.low
		mov	ds:tiffStripOffsets.TF_offset.low, ax
		mov	ax, ds:sliceOffsets.high
		mov	ds:tiffStripOffsets.TF_offset.high, ax
		mov	ax, ds:sliceCounts.low
		mov	ds:tiffStripCounts.TF_offset.low, ax
		mov	ax, ds:sliceCounts.high
		mov	ds:tiffStripCounts.TF_offset.high, ax
		clc		; signal no error.
		jmp	done
TiffWriteSliceTables endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TiffEpilogue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish off a TIFF file

CALLED BY:	DumpScreen
PASS:		bp	= file handle
RETURN:		Carry set on error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TiffEpilogue	proc	far	uses es, di
		.enter
	;
	; Write out the X and Y resolutions based on what's in the
	; device info table.
	;
		call	TiffSetResolution
		LONG	jc	done
	;
	; Write out the StripOffsets and StripByteCounts arrays. Note
	; that if there was only one strip, we need to store the
	; values in the IFD, not in the file (yet).
	;
		call	TiffWriteSliceTables
		LONG	jc	done
	;
	; Write the colormap out that's appropriate to the mode. If it's not
	; a palette image, don't stick a color map in, as it confuses some
	; (stupid) TIFF readers...
	;
		cmp	ds:tiffPhotoInterp.TF_offset.low, TPI_PALETTE
		je	writeColorMap
		;
		; Truncate the IFD at the ColorMap tag...
		;
		mov	({dword}ds:tiffColorMap).low, 0	; no more IFDs
		mov	({dword}ds:tiffColorMap).high, 0
		mov	cx, (tiffColorMap-tiffIFD) + size dword
		mov	{word}ds:[tiffIFD], 
			(tiffColorMap-tiffIFDStart)/size TiffField
		jmp	writeIFD

writeColorMap:
		mov	cx, ds:tiffColorMap.TF_count.low
		mov	dx, offset colorMap4Red
		shl	cx		; words -> bytes
		; store the current file offset in the IFD entry and
		; adjust curOff to account for the colormap written.
		mov	ax, ds:curOff.low
		mov	ds:tiffColorMap.TF_offset.low, ax
		add	ax, cx
		mov	ds:curOff.low, ax
		mov	ax, ds:curOff.high
		mov	ds:tiffColorMap.TF_offset.high, ax
		adc	ax, 0
		mov	ds:curOff.high, ax
		clr	al
		call	FileWrite
		jc	done
		
	;
	; Write out the IFD and the header for the file. Leaves the
	; file position after the header. Always reset the field count
	; in case the previous image had no colormap...
	;
		mov	cx, tiffIFDRealEnd-tiffIFD
		mov	{word}ds:[tiffIFD], 
			(tiffIFDEnd-tiffIFDStart)/size TiffField
writeIFD:
		mov	ax, ds:curOff.low
		mov	ds:tiffHeader.TH_ifd.low, ax
		mov	ax, ds:curOff.high
		mov	ds:tiffHeader.TH_ifd.high, ax
		mov	dx, offset tiffIFD
		clr	al		; return errors
		mov	bx, bp
		call	FileWrite
		jc	done
		mov	cx, ds:headerOff.high
		mov	dx, ds:headerOff.low
		mov	al, FILE_POS_START
		call	FilePos
		mov	cx, size tiffHeader
		mov	dx, offset tiffHeader
		clr	al		; return errors
		call	FileWrite
done:
		.leave
		ret
TiffEpilogue	endp

Tiff		ends
