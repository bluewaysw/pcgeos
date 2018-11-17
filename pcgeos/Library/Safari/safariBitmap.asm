COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1999 -- All Rights Reserved

PROJECT:	GeoSafari
FILE:		safariBitmap.asm

AUTHOR:		Gene Anderson

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/5/99		Initial revision

DESCRIPTION:
	Code for loading and drawing bitmaps

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include safariGeode.def
include safariConstant.def

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariImportBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Import a bitmap file

CALLED BY:	GLOBAL

PASS:		ds:si - ptr to FileLongName
		bx - handle of file to import into
RETURN:		ax - VM block handle
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/12/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SafariImportBitmap	proc	far
	.enter

	call	ImportBitmapFile

	.leave
	ret
SafariImportBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariFreeBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free an imported bitmap

CALLED BY:	GLOBAL

PASS:		ax - VM block handle
		bx - VM file handle
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/12/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SafariFreeBitmap	proc	far
	uses	bp
	.enter

	clr	bp				;ax:bp <- VM chain
	call	VMFreeVMChain

	.leave
	ret
SafariFreeBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBitmapFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a bitmap from a file

CALLED BY:	DrawLogo()

PASS:		(ax,bx) - (x,y) position
		di - gstate
		cx - VM block handle
		dx - VM file handle
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/12/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

DrawBitmapFile	proc	near
		uses	cx, dx
		.enter
	;
	; Use the VM chain to draw the bitmap
	;
		call	GrDrawHugeBitmap

		.leave
		ret
DrawBitmapFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadLogoBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Import the GeoSafari Logo

CALLED BY:	GameCardDraw()

PASS:		none
RETURN:		carry - set if error
		cx - bitmap VM handle
		dx - bitmap file handle
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/10/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

LocalDefNLString logoFile <"Logo", 0>
LocalDefNLString safDir <"GeoSafari", 0>

LoadLogoBitmap	proc	near
		uses	ds, si, di, ax, bx, bp
		.enter

	;
	; 16 color or 256 color logo?
	;
		segmov	ds, cs
		mov	si, offset SLMB_i16Color
		call	GetDisplayType			;16 color?
		je	is16Color			;branch if so
		mov	si, offset SLMB_i256color
is16Color:
	;
	; go to the correct directory and open the file
	;
		call	FilePushDir
		mov	bx, SP_USER_DATA		;bx <- StandardPath
		mov	dx, offset safDir
		segmov	ds, cs				;ds:dx <- path
		call	FileSetCurrentPath
		mov	ax, mask VMAF_FORCE_READ_ONLY or (VMO_OPEN shl 8)
		clr	cx				;cx <- compression
		mov	dx, offset logoFile		;ds:dx <- filename
		call	VMOpen
		jc	doneError			;branch if error
	;
	; get the map block and lock it
	;
		call	VMGetMapBlock			;ax <- map block
		call	VMLock
		mov	ds, ax				;ds <- seg addr
		mov	cx, ds:[si]			;cx <- VM blk handle
		mov	dx, bx				;dx <- VM file handle
	;
	; done with the map block
	;
		call	VMUnlock
doneError:
		call	FilePopDir

		.leave
		ret
LoadLogoBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportBitmapFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Import and draw a bitmap from a file

CALLED BY:	DrawLogo()

PASS:		ds:si - ptr to file name
		bx - VM file handle
		$CWD - set to directory with file
RETURN:		carry - set if error
		ax - bitmap VM handle (0 if error)
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/12/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ImportBitmapFile	proc	near
		uses	ds, dx, si, es, di, cx, bx
impFrame	local	ImportFrame
		.enter

		mov	ss:impFrame.IF_transferVMFile, bx
	;
	; Copy the filename
	;
		segmov	es, ss
		lea	di, ss:impFrame.IF_sourceFileName
		push	si
		LocalCopyString
		pop	dx				;ds:dx <- filename
	;
	; Open the file
	;
openFile::
		mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
		call	FileOpen
		mov	ss:impFrame.IF_sourceFile, ax
		mov	ss:impFrame.IF_sourcePathDisk, SP_DOCUMENT
		mov	{char}ss:impFrame.IF_sourcePathName, 0
		jc	noFile			;branch if error
	;
	; Setup and call the graphics import library directly
	;
		mov	ss:impFrame.IF_formatNumber, 0
		mov	ss:impFrame.IF_importOptions, 0
		segmov	ds, ss
		lea	si, ss:impFrame			;ds:si <- ImportFrame
		mov	ax, TR_IMPORT			;ax <- routine
		call	CallImportLib
		jc	noBitmap
	;
	; Returned required info
	;
		mov	ax, dx				;ax <- VM handle
		clc					;carry <- no error
doneFile:
		push	ax
		pushf
		mov	bx, ss:impFrame.IF_sourceFile
		call	FileClose
		popf
		pop	ax
done:
		.leave
		ret

noBitmap:
		clr	ax				;ax <- no VM handle
		stc					;carry <- error
		jmp	doneFile

noFile:
		clr	ax				;ax <- no VM handle
		stc					;carry <- error
		jmp	done
ImportBitmapFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallImportLib
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the appropriate import library

CALLED BY:	DrawBitmapFile()

PASS:		ds:si - ImportFrame (on stack)
		ax - routine to call (TR_IMPORT)
RETURN:		carry - set if error
		TR_IMPORT:
		    dx - VM block handle of bitmap
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/2/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

CallImportLib	proc	near
libHandle	local	hptr
		.enter

	;
	; Change to the correct directory
	;
		push	ax, ds, si
		call	FilePushDir
		mov	ax, SP_IMPORT_EXPORT_DRIVERS
		call	FileSetStandardPath
	;
	; Load the library
	;
		call	GetImportLibraryName		;ds:si <- library name
		jc	noLib				;branch if not found
		mov	ax, XLATLIB_PROTO_MAJOR		;ax <- major protocol
		mov	bx, XLATLIB_PROTO_MINOR		;bx <- minor protocol
		call	GeodeUseLibrary
		mov	ss:libHandle, bx
noLib:
		call	FilePopDir			;restore directory
		pop	ax, ds, si
		jc	done				;branch if error
	;
	; Call the library
	;
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable		;ax <- TransError
	;
	; Free the library
	;
		push	bx
		mov	bx, ss:libHandle		;bx <- library handle
		call	GeodeFreeLibrary
		pop	bx
	;
	; Note any error
	;
		tst	ax				;clears carry
		jz	done				;branch if no error
importError::
		cmp	bx, TE_CUSTOM			;custom error?
		jne	doneImportError			;branch if not
		tst	bx				;any error string?
		jz	doneImportError			;branch if not
		call	MemFree				;free custom error
doneImportError:
		stc					;carry <- error
done:
		.leave
		ret
CallImportLib	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetImportLibraryName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the appropriate import library name

CALLED BY:	CallImportLib()

PASS:		ds:si - ImportFrame (on stack)
RETURN:		carry - set if error
		ds:si - library name
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This should probably query the libraries to figure out which
	will import which formats, but this is easier and a lot quicker
	than loading and unloading five libraries and the libraries they
	depend on (e.g., Impex and DIB)

	One thought is to load the common libraries once, then call each
	of the import libraries with TR_GET_FORMAT.

	It may not matter when things are changed to save the translated
	bitmap for redrawing rather than re-importing each time.

	Do a FileEnum() with TLGR in SYSTEM\IMPEX...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/2/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

formatExts nptr \
	GIFExt,
	JPEGExt,
	BMPExt,
	PCXExt,
	TIFFExt

LocalDefNLString GIFExt, <"GIF",0>
LocalDefNLString JPEGExt, <"JPG",0>
LocalDefNLString BMPExt, <"BMP",0>
LocalDefNLString PCXExt, <"PCX",0>
LocalDefNLString TIFFExt, <"TIF",0>

formatLibs	nptr \
	GIFLib,
	JPEGLib, 
	BMPLib,
	PCXLib,
	TIFFLib

if ERROR_CHECK
LocalDefNLString GIFLib, <"GIFEC.GEO",0>
LocalDefNLString JPEGLib, <"JPEGEC.GEO",0>
LocalDefNLString BMPLib, <"BMPEC.GEO",0>
LocalDefNLString PCXLib, <"PCXEC.GEO",0>
LocalDefNLString TIFFLib, <"TIFFEC.GEO",0>
else
LocalDefNLString GIFLib, <"GIF.GEO",0>
LocalDefNLString JPEGLib, <"JPEG.GEO",0>
LocalDefNLString BMPLib, <"BMP.GEO",0>
LocalDefNLString PCXLib, <"PCX.GEO",0>
LocalDefNLString TIFFLib, <"TIFF.GEO",0>
endif

CheckHack <length formatExts eq length formatLibs>

GetImportLibraryName	proc	near
		uses	bx, es, di
		.enter

	;
	; Find the extension
	;
		lea	si, ds:[si].IF_sourceFileName
		segmov	es, ds
		mov	di, si				;es:di <- string
		call	LocalStringLength		;cx <- length
		LocalLoadChar ax, '.'			;ax <- char to find
		LocalFindChar
		jnz	notFound			;branch if not found
	;
	; Find the extension in the table
	;
		mov	cx, length formatExts		;cx <- # of entries
		clr	bx				;bx <- table index
		segmov	ds, cs
extLoop:
		push	cx
		mov	si, cs:formatExts[bx]		;ds:si <- extension
		clr	cx				;cx <- NULL-terminated
		call	LocalCmpStringsNoCase
		pop	cx
		je	foundExt			;branch if match
		add	bx, (size nptr)			;bx <- next entry
		loop	extLoop				;loop for more
		jmp	notFound

	;
	; Found the extension -- return the library name
	;
foundExt:
		mov	si, cs:formatLibs[bx]		;ds:si <- library name
		clc					;carry <- no error
done:
		.leave
		ret

notFound:
		stc					;carry <- error
		jmp	done
GetImportLibraryName	endp

CommonCode	ends
