COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Nimbus Font Converter
FILE:		ninfntFile.asm

AUTHOR:		Gene Anderson, Apr 24, 1991

ROUTINES:
	Name			Description
	----			-----------
EXT	ConvertNimbusFont	Convert all Nimbus fonts w/given ID

	ConvertOneNimbusFont	Convert one style of one Nimbus font
	CreateDestFile		Create destination DOS 8.3 font file
	WriteGEOSFontHeader	Write PC/GEOS font file header

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/24/91		Initial revision
	JDM	91.05.09	Fixed error returning.
	JDM	91.05.10	Added user file overwrite confirmation. 
	JDM	91.05.13	Added conversion status updating.

DESCRIPTION:
	File-related routines for Nimbus font converter

	A PC/GEOS font file has the a special font file header
	which contains an array of entries specifying the outline
	styles contained in the file, their position and their size.

	The actual outline data itself for a font/style combination
	is broken up into three lumps: the header/metric information,
	the characters from 0x20-0x7f, and the characters from 0x80-0xff.

	The header lump has font metrics and a table of character widths.
	Each lump of character data has a table at the start of lump-
	relative offsets to the character data in that lump.

	$Id: ninfntFile.asm,v 1.1 97/04/04 16:16:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertNimbusFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Conver a Nimbus font to PC/GEOS format.
CALLED BY:	EXTERNAL

PASS:		ds:si - ptr to FontConvertEntry
RETURN:		carry - set if error
			ax - NimbusError
DESTROYED:	bx, cx, dx, es, ax (if no error)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/26/91		Initial version
	JDM	91.05.09	Fixed error returning.
	JDM	91.05.10	Added user abort handling.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertNimbusFont	proc	far
	uses	si, di, ds

destFileHandle	local	hptr

	.enter

	call	AssignFontID
	jc	reportError			;branch if error
	call	CreateDestFile
	jc	reportError			;branch if error
	mov	ss:destFileHandle, bx		;save file handle
	;
	; Inform the application that we're working.
	;
	call	ConvertStatusInit

	call	WriteGEOSFontHeader
	mov	dx, bx				;dx <- destination file handle
	jc	reportErrorDelete		;branch if error

	mov	cx, ds:[si].FCE_activeEntries	;cx <- # of fonts
	clr	di				;di <- entry #
	add	si, offset FCE_font		;ds:si <- ptr to FontStyleEntry
	clr	bx				;bx <- file number.
fontLoop:
	;
	; Inform the application that we're working on another font file.
	;
	mov	ax, bx				;ax <- file number
	call	ConvertStatusSetFile
	inc	bx				;bx <- next file
	;
	; Go convert this font file.
	;
	call	ConvertOneNimbusFont
	jc	reportErrorDelete		;branch if error
	;
	; Go to next file, if any.
	;
	add	si, (size FontStyleEntry)	;ds:si <- ptr to next entry
	inc	di				;di <- next entry #
	loop	fontLoop			;loop while more fonts

	mov	bx, dx				;bx <- file handle
	call	FileClose			;close me jesus
	clc					;carry <- no error
done:
	.leave
	ret

	;
	; An error occurred in the middle of conversion.
	; Delete the destination file so as to not wreak havoc the
	; next time the system starts up.
	;
reportErrorDelete:
	push	ax				;save error #
	mov	bx, dx				;bx <- file handle
	call	FileClose			;close the destination file
	jc	closeError			;branch if error
	call	FilePushDir
	mov	ax, SP_FONT			;ax <- StandardPath
	call	FileSetStandardPath
	segmov	ds, idata, ax
	mov	dx, offset destFilename		;ds:dx <- ptr to DOS filename
	call	FileDelete			;delete the destination file
	call	FilePopDir
closeError:
	pop	ax				;ax <- error #
	;
	; Put up an error message if not aborting.
	;
reportError:
	;
	; Did the user want to abort?
	;
	cmp	ax, NE_FILE_ABORT
	stc					;carry <- error
	jz	done				;branch if aborting
	;
	; Otherwise notify the user of the error.
	;
	call	ReportError
	jmp	done
ConvertNimbusFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertOneNimbusFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert one Nimbus font/style into PC/GEOS font
CALLED BY:	ConvertNimbusFont()

PASS:		ds:si - ptr to FontStyleEntry
		di - entry # of FontStyleEntry (0-based)
		dx - destination file handle (FilePos'd at end)
RETURN:		carry - set if error
			ax - NimbusError
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack	<(offset ODE_weight - offset ODE_style) eq 1>
CheckHack	<(offset FSE_weight - offset FSE_style) eq 1>

ConvertOneNimbusFont	proc	near
	uses	bx, cx, dx, ds

styleEntry	local	OutlineDataEntry
lastChar	local	Chars			;NOTE: order important
firstChar	local	Chars			;NOTE: order important

CheckHack	<(offset lastChar - offset firstChar) eq 1>

	.enter

	;
	; Get the current file position to stuff into the header.
	;
	call	GetFilePos			;cx:ax <- file position
	mov	ss:styleEntry.ODE_header.OE_offset.low, ax
	mov	ss:styleEntry.ODE_header.OE_offset.high, cx
	;
	; Open Nimbus font file.
	;
	push	dx
	lea	dx, ds:[si].FSE_filename	;ds:dx <- ptr to filename
	mov	al, FILE_ACCESS_R or FILE_DENY_W
	call	FileOpen			;ax <- file handle
	pop	dx
	LONG jc	openError			;branch if error
	mov	bx, ax				;bx <- source file handle
	;
	; Convert the DTCFontHeader to PC/GEOS format
	;
	clr	cx				;cx <- Nimbus header unknown
	push	di
	call	ConvertFontHeader
	mov	{word}ss:firstChar, di
	pop	di				;di <- FontStyleEntry
	LONG jc	done				;branch if error
	mov	ss:styleEntry.ODE_header.OE_size, ax
	;
	; Write the first half data
	;
	push	cx
	call	GetFilePos
	mov	ss:styleEntry.ODE_first.OE_offset.low, ax
	mov	ss:styleEntry.ODE_first.OE_offset.high, cx
	pop	cx
	mov	al, ss:firstChar		;al <- start char
	mov	ah, 0x7f			;ah <- end char
	call	WriteHalfData
	jc	done				;branch if error
	mov	ss:styleEntry.ODE_first.OE_size, ax
	;
	; Write the second half data
	;
	push	cx
	call	GetFilePos
	mov	ss:styleEntry.ODE_second.OE_offset.low, ax
	mov	ss:styleEntry.ODE_second.OE_offset.high, cx
	pop	cx
	mov	al, 0x80			;al <- first char
	mov	ah, ss:lastChar			;ah <- last char
	call	WriteHalfData
	jc	done				;branch if error
	mov	ss:styleEntry.ODE_second.OE_size, ax
	;
	; Close Nimbus font file.
	;
	clr	al				;al <- file flags
	call	FileClose
	jc	closeError			;branch if error
	;
	; Free the DTCFontHeader block
	;
	mov	bx, cx				;bx <- handle of header
	call	MemFree
	;
	; Write the block sizes and offsets into the file header,
	; as well as the style and weight, while we're here.
	;	di = (0-based) entry #
	;
	clr	ax
	mov	ss:styleEntry.ODE_header.OE_handle, ax
	mov	ss:styleEntry.ODE_first.OE_handle, ax
	mov	ss:styleEntry.ODE_second.OE_handle, ax
	push	dx
	mov	ax, (size OutlineDataEntry)	;ax <- size of each entry
	mul	di
	pop	dx				;dx <- dest file handle
	add	ax, (size FontFileInfo) + (FontInfo) - 2
	clr	cx
	call	SetFilePos			;set position in file
	mov	ax, {word}ds:[si].FSE_style
	mov	{word}ss:styleEntry.ODE_style, ax
	clr	al				;al <- file flags
	mov	bx, dx				;bx <- dest file handle
	mov	cx, (size OutlineDataEntry)	;cx <- # of bytes
	segmov	ds, ss
	lea	dx, styleEntry			;ds:dx <- ptr to buffer
	call	FileWrite
	jc	writeError			;branch if error
	;
	; Put the file pointer (back) at the new end of file
	;
	mov	al, FILE_SEEK_END		;al <- FileSeekModes
	clr	cx
	clr	dx				;cx:dx <- offset from end
	call	FilePos
done:
	.leave
	ret

writeError:
	mov	ax, NE_FILE_WRITE		;ax <- NimbusError
	jmp	done				;carry set
openError:
	mov	ax, NE_FILE_OPEN		;ax <- NimbusError
	jmp	done				;carry set

closeError:
	mov	ax, NE_FILE_CLOSE		;ax <- NimbusError
	jmp	done				;carry set
ConvertOneNimbusFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateDestFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create destination font file of form "name####.fnt"
CALLED BY:	ConvertNimbusFont()

PASS:		ds:si - ptr to FontConvertEntry
RETURN:		bx - dest file handle
		carry - set if error
			ax - NimbusError
DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	What a bunch of hacks.  Assumes the following:
	(1) the file name is a 8.3 DOS name
	(2) the generated name will be broken into 4 characters from
		the font name and 4 hex digits of the FontIDs value
	(3) '.' and ' ' are bad DOS filename characters (other than ".fnt")
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/24/91		Initial version
	JDM	91.05.10	Added user overwrite confirmation.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateDestFile	proc	near
	uses	si, di, ds, es, cx, dx
	.enter

	segmov	es, idata, ax			;es <- seg addr of idata
	mov	dx, ds:[si].FCE_fontID		;dx <- font ID
	mov	si, ds:[si].FCE_name		;si <- chunk handle of name
	mov	si, ds:[si]			;ds:si <- dereferenced chunk
	mov	di, offset destFilename		;es:di <- ptr to DOS filename
	;
	; Make the first four bytes the start of the font name
	;
	mov	cx, 4
charLoop:
	tst	{byte}ds:[si]			;end of string?
	jz	replaceChar			;branch if end
	lodsb					;al <- byte of name
	cmp	al, ' '
	je	replaceChar
	cmp	al, '.'
	je	replaceChar
	cmp	al, '*'
	je	replaceChar
	cmp	al, '?'
	je	replaceChar
	push	di
	mov	di, DR_LOCAL_IS_DOS_CHAR	;di <- localization function
	call	SysLocalInfo
	pop	di
	jnz	charOK
replaceChar:
	mov	al, '_'				;al <- replacement character
charOK:
	stosb					;store byte of name
	loop	charLoop			;loop while more characters
	;
	; Make the last four bytes the FontIDs value (in hex)
	;
	mov	cx, 4				;cx <- 4 digits
digitLoop:
	rol	dx, 1
	rol	dx, 1
	rol	dx, 1
	rol	dx, 1				;rotate high nibble to low
	mov	al, dl				;al <- 2 digits
	andnf	al, 0x0f			;keep low nibble only
	add	al, '0'				;convert to a digit
	cmp	al, 10+'0'			;alphabetic digit? (A-F)?
	jb	storeDigit			;branch if (0-9)
	add	al, 'A'-'0'-10			;convert from 0-9 to A-F
storeDigit:
	stosb
	loop	digitLoop			;loop while more digits
	;
	; Now actually create the file
	;
	call	FilePushDir			;save $cwd

	mov	ax, SP_FONT			;ax <- StandardPath
	call	FileSetStandardPath

	; Attempt to open the file.
	; The first time through check for previous file existence.
	mov	ax, FileAccessFlags <FE_NONE, FA_WRITE_ONLY> \
		    or (FILE_CREATE_ONLY shl 8)

attemptFileCreation:
	clr	cx				;cx <- FileAttrs
	segmov	ds, idata, dx
	mov	dx, offset destFilename		;ds:dx <- ptr to file name
	call	FileCreate
	jnc	done				;branch if no error

	; Does the file already exist.
	cmp	ax, ERROR_FILE_EXISTS
	jz	confirmOverwrite		; Attempt failed.

	; Otherwise, exit with an file creation error.
	mov	ax, NE_FILE_CREATE
	stc
	jmp	done

confirmOverwrite:
	; Ask the user if they want to overwrite the file.
	mov	ax, offset NimbusFontInstallConfirmFileOverwriteString
	call	DoConfirmation

	; What did they decide?
	cmp	ax, SDBR_AFFIRMATIVE		; Overwrite?
	jnz	abortFile			; Nope.

	; Otherwise, try overwriting the file.
	mov	ax, FileAccessFlags <FE_NONE, FA_WRITE_ONLY> \
		    or (FILE_CREATE_TRUNCATE shl 8)
	jmp	attemptFileCreation

abortFile:
	; Otherwise they didn't want to overwrite the file so abort
	; the conversion process.
	mov	ax, NE_FILE_ABORT
	stc

done:
	pushf
	call	FilePopDir			;restore $cwd
	popf

	mov	bx, ax				;bx <- file handle

	.leave
	ret
CreateDestFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteGEOSFontHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write PC/GEOS font file header
CALLED BY:	

PASS:		ds:si - ptr to FontConvertEntry
		bx - destination file handle
RETURN:		carry - set for error
			ax - NimbusError
		ax - size of PC/GEOS font file header
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Assumes: (size FI_fileHandle) == 2
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack	<(size FI_fileHandle) eq 2>

WriteGEOSFontHeader	proc	near
	uses	bx, cx, si, di, ds, es

destFileHandle		local	hptr
infoSize		local	word		;size of OutlineDataEntry's
outlineSize		local	word		;+ FontInfo
headerSize		local	word		;+ FontFileInfo

	.enter

	mov	ss:destFileHandle, bx		;save file handle

	mov	di, bx				;di <- file handle
	;
	; Allocate enough space for file header, font header,
	; and OutlineDataEntry for each outline set in the font.
	;
	mov	ax, ds:[si].FCE_activeEntries	;ax <- # of font entries
	mov	cx, size (OutlineDataEntry)	;cx <- size of entry / font
	mul	cx
EC <	ERROR_C	TOO_MANY_FONTS			;>
	mov	ss:outlineSize, ax
	add	ax, (size FontInfo) - 2
	mov	ss:infoSize, ax
	add	ax, (size FontFileInfo)
	mov	ss:headerSize, ax
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	LONG jc	memError			;branch if error
	mov	es, ax				;es <- seg addr of block
	;
	; Initialize the header
	;
	mov	{word}es:FFI_signature, FONT_SIG_LOW
	mov	{word}es:FFI_signature[2], FONT_SIG_HIGH
	mov	{word}es:FFI_minorVer, (MAJOR_VER_NUMBER shl 8)
	mov	ax, ss:headerSize
	mov	es:FFI_headerSize, ax		;store header size
	mov	ax, ds:[si].FCE_fontID
	mov	es:[FontFileInfo][-2].FI_fontID, ax
	mov	es:[FontFileInfo][-2].FI_maker, MAKER_NIMBUSQ
	andnf	ah, 0x0f
	shr	ah, 1				;ah <- FontFamily
	mov	es:[FontFileInfo][-2].FI_family, ah
	;
	; Copy the font name in
	;
	push	di
	mov	si, ds:[si].FCE_name		;si <- chunk handle of name
	mov	si, ds:[si]			;ds:si <- ptr to name
	ChunkSizePtr	ds, si, cx		;cx <- length of name
	mov	cx, FONT_NAME_LEN

EC <	cmp	cx, FONT_NAME_LEN		;>
EC <	ERROR_A	FONT_NAME_TOO_LONG		;>
	mov	di, (offset [FontFileInfo][-2].FI_faceName)
	rep	movsb				;copy me jesus
	pop	di
	;
	; Set the pointers to the various info tables
	;
	mov	es:[FontFileInfo][-2].FI_pointSizeTab, 0
	mov	es:[FontFileInfo][-2].FI_pointSizeEnd, 0
	mov	ax, (FontInfo)			;NOTE! no -2
	mov	es:[FontFileInfo][-2].FI_outlineTab, ax
	add	ax, ss:outlineSize
	mov	es:[FontFileInfo][-2].FI_outlineEnd, ax
	;
	; Leave the OutlineDataEntry's for now -- we'll fill
	; them in later.  Flush everything else to disk.
	;
	segmov	ds, es
	clr	dx				;ds:dx <- buffer to write
	xchg	bx, di				;bx <- file handle
	clr	al				;al <- file flags
	mov	cx, ss:headerSize		;cx <- # of bytes to write
	call	FileWrite
	jc	writeError			;branch if error
	;
	; Done with the memory block
	;
	xchg	bx, di				;bx <- header block handle
	call	MemFree
	mov	ax, cx				;ax <- # of bytes written
	clc					;carry <- no error
done:
	.leave
	ret

memError:
	mov	ax, NE_MEM_ALLOC		;ax <- NimbusError
	jmp	done				;carry set

writeError:
	mov	ax, NE_FILE_WRITE		;ax <- NimbusError
	jmp	done				;carry set
WriteGEOSFontHeader	endp

ConvertCode	ends
