COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994.	All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Icon editor
MODULE:		Source
FILE:		sourceSource.asm

AUTHOR:		Steve Yegge

ROUTINES:

	Name					Description
	----					-----------

    INT DBViewerWriteSource     Writes source code for the current icon.

    INT WriteSourceCode         Write out the icon.

    INT GetBitmapAndWriteSource Gets format from database & writes source
				for it.

    INT WriteBitmapSourceLow    Write the bitmap out in some form or other.

    INT StripMaskDataFromBitmap Removes the mask bits from the bitmap.

    INT OpenSourceFile          opens the text file for writing

    INT WriteMonikerHeader      Writes the moniker header to the file.

    INT WriteMonikerTrailer     Write the icon trailer string
				(language-dependent).

    INT WriteBitmap             Write the elements of the huge array.

    INT WriteElement            Write a huge-array element to the output
				file.

    INT WriteVisMoniker         just writes "visMoniker <name> = {" (1st
				string in file)

    INT WriteSize               writes the size for moniker-list selection

    INT WriteStyle              Writes the line "style = <blah>"

    INT WriteColor              Write the moniker's color scheme.

    INT WriteAspectRatio        Write the moniker's aspect ratio.

    INT WriteCachedSize         Write the moniker's cached size.

    INT WriteBitmapSize         Writes the size of the bitmap in decimal.

    INT ComputeCompactedBitmapSize 
				Returns the data size for the compacted
				bitmap.

    INT WriteBitmapHeader       writes Bitmap <xx,xx,BMC_PACKBITS,mask
				......> to file

    INT IconWriteSourceError    Display an error message

    INT NotifyUserWriteSourceSuccessful 
				Tells user we're done writing source code.

    INT InitStackFrame          Get options and save them in local
				variables.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/18/92		initial revision

DESCRIPTION:

	This module handles writing source code for icons.

	$Id: sourceSource.asm,v 1.1 97/04/04 16:06:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SourceCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerWriteSource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes source code for the current icon.

CALLED BY:	MSG_DB_VIEWER_WRITE_SOURCE

PASS:		*ds:si	= DBViewer object
		ds:[di] = DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- see if the icon is dirty first
	- figure out what kind of source code we're writing
	- call the source-code-writing routines
	- tell the user we're done.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerWriteSource	proc	far
		class	DBViewerClass

		WSFrame	local	WriteSourceFrame

		.enter
	;
	;  Mark application as busy.
	;
		call	IconMarkBusy
	;
	;  See if we have an icon...if not, bail.
	;
		cmp	ds:[di].DBVI_currentIcon, NO_CURRENT_ICON
		LONG	je	done			; quit with no error
	;
	;  Prompt for save; quit if they cancel.
	;
		call	CheckIconDirtyAndDealWithIt
		LONG	jc	done
	;
	;  Set up the options in the local variable frame.
	;
		call	InitStackFrame
	;
	;  Lock down the strings resource.
	;
		GetResourceHandleNS	SourceStrings, bx
		call	MemLock
		mov	ss:WSFrame.WSF_stringSeg, ax
		jc	error
	;
	;  Create a buffer into which to write the text.  Whenever
	;  the buffer fills up we'll flush it to disk.
	;
		mov	ax, SOURCE_CACHE_BUFFER_SIZE
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc			; bx = handle, ax = seg
		jc	unlockStrings

		mov	ss:WSFrame.WSF_outBufHan, bx
		mov	ss:WSFrame.WSF_outBufSeg, ax
		clr	ss:WSFrame.WSF_outBufPtr	; current position
	;
	;  Write the source code and free the cache.
	;
		call	WriteSourceCode			; actually writes it

		pushf
		mov	bx, ss:WSFrame.WSF_outBufHan
		call	MemFree
		popf
		jc	error
unlockStrings:
	;
	;  Unlock the strings resource.
	;
		pushf
		GetResourceHandleNS	SourceStrings, bx
		call	MemUnlock
		popf
		jc	error
success:
	;
	;  Tell the user we're done.
	;
		call	NotifyUserWriteSourceSuccessful
done:
	;
	;  Mark app as unbusy.
	;
		call	IconMarkNotBusy

		.leave
		ret
	;
	;  Put out of the way so that non-error situation will
	;  be a fall-through.
	;
error:
		tst	ax				; really an error?
		jz	success
		call	IconWriteSourceError
		jmp	done

DBViewerWriteSource	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteSourceCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the icon.

CALLED BY:	DBViewerWriteSource

PASS:		*ds:si	= DBViewer object
		ss:[bp]	= inherited WriteSourceFrame

RETURN:		carry set if error
		ax = WriteSourceErrors

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/ 4/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteSourceCode	proc	near
		class	DBViewerClass
		uses	bx, cx, dx
		.enter	inherit	DBViewerWriteSource
	;
	;  If we can't open the file, quit.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		call	OpenSourceFile			; sets WSF_fileHandle
		LONG	jc	done			; ax = WriteSourceError
	;
	;  If we're only writing the current format, set the counter 
	;  to 1 and put the current format number in ax.
	;
		cmp	ss:WSFrame.WSF_format, WSFT_CURRENT_FORMAT
		je	writingCurrent
	;
	;  Get number of formats into cx (counter).
	;
		push	bp				; locals
		mov	ax, ds:[di].DBVI_currentIcon	; dx.ax <- current icon
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormatCount		; returns in bx
		pop	bp				; locals

		mov	cx, bx				; cx = counter
		clr	ss:WSFrame.WSF_curFormat	; start on first one
		jmp	doLoop

writingCurrent:
	;
	;  Set counter (cx) to 1 and move current format into ax.
	;
		mov	ax, ds:[di].DBVI_currentFormat
		mov	ss:WSFrame.WSF_curFormat, ax
		mov	cx, 1				; write only 1 format
	;
	;  Any error encountered with this loop will be an
	;  error in writing the file, since we already have
	;  it open.
	;
		mov	ax, WSE_FILE_WRITE		; assume file write err
doLoop:
	;
	;  Now cx is the number of formats to write, and ax is the
	;  format to start on.  Call the appropriate handler.
	;  This loop is a little funky; if we don't allow multiple
	;  formats for pointer images we could make it faster, but
	;  I guess people might want them...
	;
		cmp	ss:WSFrame.WSF_header, WSHT_PTR_IMAGE
		je	writePointer

		call	GetBitmapAndWriteSource		; write this format
		jc	done
		jmp	doCounter
writePointer:
		call	GetBitmapAndWritePointer
		jc	done
doCounter:
		inc	ss:WSFrame.WSF_curFormat	; next!
		loop	doLoop
	;
	;  Flush the cache, as we're done writing data.
	;
		call	FlushOutputBuffer
	;
	;  Close the output text file.
	;
		clr	al				; flags
		mov	bx, ss:WSFrame.WSF_fileHandle	; output file handle
		call	FileCommit
		call	FileClose
		mov	ax, WSE_FILE_CREATE
		jc	done				; choke

		mov	ax, WSE_NO_ERROR
done:
		.leave
		ret
WriteSourceCode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBitmapAndWriteSource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets format from database & writes source for it.

CALLED BY:	WriteSourceCode

PASS:		*ds:si	= DBViewerInstance
		ss:[bp]	= inherited WriteSourceFrame

RETURN:		carry set if error (ax = WriteSourceErrors)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBitmapAndWriteSource	proc	near
		class	DBViewerClass
		uses	bx,cx,dx,si,di
		.enter	inherit	WriteSourceCode
	;
	;  Update any locals for the new format to be written.
	;
		andnf	ss:WSFrame.WSF_flags, not \
			(mask WSF_COMPACTED_BITMAP or mask WSF_REMOVED_MASK)
		clr	ss:WSFrame.WSF_lineCount
	;
	;  Get the format for writing.
	;
		push	bp			; locals
		mov	bx, ss:WSFrame.WSF_curFormat
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormat		; ^vcx:dx = current format
		pop	bp 			; locals
	;
	;  Strip out the mask data if the user wants to do so.
	;
		test	ss:WSFrame.WSF_flags, mask WSF_WRITING_MASK
		jnz	noStrip
		call	StripMaskDataFromBitmap	; ax = flags
		jnc	noStrip
		ornf	ss:WSFrame.WSF_flags, mask WSF_REMOVED_MASK
noStrip:
		movdw	ss:WSFrame.WSF_bitmap, cxdx
	;
	;  Compact the bitmap if necessary.  However, if we just
	;  created a new bitmap without a mask (above), we need to
	;  free THAT bitmap after compacting.
	;
		mov	di, si			; *ds:di = object
		cmp	ss:WSFrame.WSF_compact, WSCT_COMPACTED
		jne	noCompact

		call	ClipboardGetClipboardFile	; bx = file to use
		mov	si, bx			; si = clipboard file handle
		movdw	bxax, cxdx
		mov	dx, si			; dx = clipboard file
		call	GrCompactBitmap		; ^vdx:cx = bitmap to write

		movdw	ss:WSFrame.WSF_bitmap, dxcx

		test	ss:WSFrame.WSF_flags, mask WSF_REMOVED_MASK
		jz	dontFree
	;
	;  Oh dear -- we need to free the uncompacted bitmap,
	;  since it's not the one from the database.  (We created
	;  it to remove the mask bits).  Conveniently the bitmap
	;  is already in bx:ax.
	;
		push	bp
		clr	bp			; no DB items
		call	VMFreeVMChain
		pop	bp
dontFree:
		BitSet	ss:WSFrame.WSF_flags, WSF_COMPACTED_BITMAP
noCompact:
	;
	;  Write the source code!
	;
		mov	si, di			; *ds:si = DBViewer
		call	WriteBitmapSourceLow
done::
	;
	;  Check if we compacted the bitmap.  If so, it means
	;  a new bitmap was created, and we have to nuke it.
	;
		lahf
		test	ss:WSFrame.WSF_flags, mask WSF_COMPACTED_BITMAP
		jz	quit
		sahf				; restore carry
	;
	;  Nuke the temp bitmap.  Preserve carry, just in case
	;  writing the data failed.
	;
		pushf
		push	bp			; locals
		movdw	bxax, ss:WSFrame.WSF_bitmap
		clr	bp			; no DB items
		call	VMFreeVMChain
		pop	bp			; locals
		popf				; restore carry
	;
	;  Was there an error?
	;
		mov	ax, WSE_FILE_WRITE
		jc	quit
success::
	;
	;  Return no error.
	;
		mov	ax, WSE_NO_ERROR
		clc
quit:
		.leave
		ret
GetBitmapAndWriteSource	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteBitmapSourceLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the bitmap out in some form or other.

CALLED BY:	GetBitmapAndWriteSource

PASS:		*ds:si = DBViewer object
		ss:bp  = inherited WriteSourceFrame

RETURN:		carry set on error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteBitmapSourceLow	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter	inherit	GetBitmapAndWriteSource
	;
	;  If we're writing a large bitmap, do it differently.
	;
		test	ss:WSFrame.WSF_flags, mask WSF_WRITING_LARGE
		jz	writeNormal
	;
	;  Writing a large bitmap.
	;
		call	WriteLargeBitmap
		jmp	done
writeNormal:
	;
	;  Write the header.
	;
		call	WriteMonikerHeader
		jc	done
	;
	;  Write the bits of the bitmap.
	;
		call	WriteBitmap
		jc	done
	;
	;  Write the tail, if necessary.
	;
		call	WriteMonikerTrailer
done:
		.leave
		ret
WriteBitmapSourceLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenSourceFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	opens the text file for writing

CALLED BY:	IconWriteCurrentFormat, IconWriteIconAsMonikerList

PASS:		*ds:si 	= DBViewer object
		ds:di	= DBViewerInstance
		ss:[bp]	= inherited WriteSourceFrame

RETURN:		ss:WSFrame.WSF_fileHandle initialized
		carry set on error (ax = error code)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- get the requested filename from the write-source dialog
	- change it to upper-case
	- try to create the file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenSourceFile	proc	near
		class	DBViewerClass
		uses	bx,cx,dx,si,di,ds
		.enter	inherit	DBViewerWriteSource
	;
	;  Get the filename from the WriteSourceDialog box.
	;
		push	bp			; locals
		mov	dx, ss
		lea	bp, ss:WSFrame.WSF_fileName
		mov	bx, ds:[di].GDI_display
		mov	si, offset WriteSourceFileName
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjMessage		; cx = string length (w/o NULL)
		pop	bp

		mov	ax, WSE_BAD_FILENAME	; assume it failed
		stc
		jcxz	done
	;
	;  Switch to the document directory.
	;
		call	FilePushDir
		mov	bx, SP_DOCUMENT		; use document directory
		call	ThreadGetDGroupDS	; ds = dgroup
		mov	dx, offset nullString	; ds:dx = null string
		call	FileSetCurrentPath
		mov	ax, WSE_FILE_CREATE	; assume failure
		jc	done
	;
	;  Open the file for writing.
	;
		segmov	ds, ss, dx
		lea	dx, ss:WSFrame.WSF_fileName
		mov	ax, (mask FCF_NATIVE or FILE_CREATE_TRUNCATE) shl 8 or\
				FileAccessFlags <FE_NONE, FA_WRITE_ONLY>
		clr	cx			; FileAttrs
		call	FileCreate		; ax = file handle
		mov	ss:WSFrame.WSF_fileHandle, ax
		mov	ax, WSE_FILE_CREATE	; assume failure
		jc	done

		mov	ax, WSE_NO_ERROR	; success!
		call	FilePopDir		; preserves flags
done:
		.leave
		ret
OpenSourceFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteMonikerHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the moniker header to the file.

CALLED BY:	GetBitmapAndWriteSource

PASS:		*ds:si	= DBViewer object
		ss:[bp]	= inherited WriteSourceFrame

RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- create a buffer to hold the header
	- write the strings to the buffer
	- write the whole buffer to the file		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteMonikerHeader	proc	near
 		class	DBViewerClass
 		uses	ax,bx,cx,dx,si,di,ds
 		.enter	inherit	GetBitmapAndWriteSource
 	;
 	;  If we're not writing the icon as a vis-moniker, just skip
 	;  to the part where we write the bitmap header.
 	;
		cmp	ss:WSFrame.WSF_header, WSHT_BITMAP
		LONG	je	writeBitmapHeader
	;
	;  Get the VisMonikerListEntry for this format.
	;
		push	bp			; locals
		mov	bx, ss:WSFrame.WSF_curFormat
		mov	di, ds:[di]
		add	di, ds:[di].DBViewer_offset
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormatParameters	; cx = IF_type
		pop	bp			; locals

		mov	ss:WSFrame.WSF_type, cx	; save VisMonikerListEntryType
	;
	;  Lock down the bitmap.
	;
		movdw	bxdi, ss:WSFrame.WSF_bitmap
		call	HugeArrayLockDir
		mov	si, size HugeArrayDirectory
		movdw	ss:WSFrame.WSF_element, axsi
	;	
	;  Write various pieces of header information.
	;
		mov	ds, ss:WSFrame.WSF_stringSeg	; everyone needs this
		call	WriteVisMoniker
		call	WriteSize
		call	WriteStyle
		call	WriteColor
		call	WriteAspectRatio
		call	WriteCachedSize
	;
	;  Grab the BMFormat from the bitmap before unlocking it,
	;  since we'll be needing it shortly.
	;
		lds	si, ss:WSFrame.WSF_element
		mov	al, ds:[si].CB_simple.B_type
		andnf	al, mask BMT_FORMAT
		call	HugeArrayUnlockDir
		mov	ds, ss:WSFrame.WSF_stringSeg
	;
	;  Write the gstring setup stuff -- setup strings are slightly
	;  different for UIC and GOC, and for mono vs. color.
	;
		cmp	ss:WSFrame.WSF_language, WSLT_GOC
		jne	writeUICSetup
	;
	;  We're writing GOC -- get either the color or mono setup string.
	;
		mov	si, offset GOCGStringSetupMono
		cmp	al, BMF_MONO shl offset BMT_FORMAT
		je	writeString
		mov	si, offset GOCGStringSetupColor
		jmp	writeString
writeUICSetup:
	;
	;  We're writing UIC -- get the color or mono setup string.
	;
		mov	si, offset UICGStringSetupMono
		cmp	al, BMF_MONO shl offset BMT_FORMAT
		je	writeString
		mov	si, offset UICGStringSetupColor
writeString:
		call	GetChunkStringSize
		call	IconWriteString

		cmp	ss:WSFrame.WSF_language, WSLT_GOC
		je	writeParens
	;
	;  Write out the UIC thing (<size>).
	;
		WriteString	OpenAngleBracket
		call	WriteBitmapSize
		WriteString	CloseAngleBracket
		jmp	writeBitmapHeader
writeParens:
	;
	;  Write out the GOC thing ( (size), )
	;
		WriteString	OpenParen
		call	WriteBitmapSize
		WriteString	CloseParen
		WriteString	Comma
		jc	done

writeBitmapHeader:
	;
	;  Re-lock the block and write the bitmap header.
	;
		mov	ds, ss:WSFrame.WSF_stringSeg	; for if we jumped here
		movdw	bxdi, ss:WSFrame.WSF_bitmap
		call	HugeArrayLockDir	; ax = segment
		mov	si, size HugeArrayDirectory	
		movdw	ss:WSFrame.WSF_element, axsi

		call	WriteBitmapHeader
		pushf
		mov	ds, ax
		call	HugeArrayUnlockDir
		popf
done:
		.leave
		ret
WriteMonikerHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteMonikerTrailer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the icon trailer string (language-dependent).

CALLED BY:	GetBitmapAndWriteSource

PASS:		ss:[bp] = inherited WriteSourceFrame

RETURN:		carry set on error (ax = WriteSourceErrors)
		carry clear on success (ax = destroyed)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/10/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteMonikerTrailer	proc	near
		uses	cx, si, ds
		.enter	inherit	GetBitmapAndWriteSource
	;
	;  Set up strings segment for WriteString macro.
	;
		mov	ds, ss:WSFrame.WSF_stringSeg
	;
	;  Now for the actual trailer.  If we're simply writing a
	;  bitmap header, no trailer is necessary.
	;
		cmp	ss:WSFrame.WSF_header, WSHT_BITMAP
		je	done			; carry clear if equal
	;
	;  Write the appropriate trailer depending on the language.
	;
		cmp	ss:WSFrame.WSF_language, WSLT_GOC
		jne	writeUICTailString

		mov	si, offset GOCTailString
		jmp	writeTailString

writeUICTailString:

		mov	si, offset UICTailString

writeTailString:
	;
	;  Write the tail string.  If an error occurs, the
	;  carry will be set and ax = WriteSourceErrors.  Otherwise
	;  ax is destroyed.
	;
		call	GetChunkStringSize
		call	IconWriteString		; really write the tail
		mov	ax, WSE_FILE_WRITE
done:
		.leave
		ret
WriteMonikerTrailer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the elements of the huge array.

CALLED BY:	GetBitmapAndWriteSource

PASS:		ss:[bp]	= inherited WriteSourceFrame

RETURN:		carry set on error 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Dereference the first huge array element, and begin
	looping through the elements (which contain the bytes
	of the bitmap), converting them to ascii and writing
	them to the source file.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteBitmap	proc	near
		uses	ax,bx,cx,dx,si,di,ds
		.enter	inherit	GetBitmapAndWriteSource
	;
	;  Clear the last-element flag.
	;
		BitClr	ss:WSFrame.WSF_flags, WSF_LAST_ELEMENT
	;
	;  Get the first huge array element, and save the size.
	;
		movdw	bxdi, ss:WSFrame.WSF_bitmap
		clrdw	dxax			; dereference 1st element
		call	HugeArrayLock		; dx = element size
		mov	ss:WSFrame.WSF_elemSize, dx
		movdw	ss:WSFrame.WSF_element, dssi
elementLoop:
	;
	;  Write the bytes of this element to the output file.
	;
		tst	ax			; see if no more elements
		jz	done			; we're outta here
	;
	; The code commented out below does not work (in fact, I have
	; no idea how it could ever work). Instead, I simply check to
	; see if there is another block after the current one in the
	; HugeArray, and if not, then we clearly must be working on the
	; last element. This solves problems with mis-formatted source
	; code (missing CR/LF and/or 'db' directives) -Don 4/12/95
	;
	; Actually he's sort of right -- both tests are needed to
	; determine whether it's really the last element of the array.
	; I'm putting my test back in.  -stevey 5/8/95
	;
		cmp	ax, 1			; writing last element?
		jne	writeIt

		tst	ds:[HAB_next]		; last block?
		jnz	writeIt
	;
	;  If it's the last element in the last block, then it's really,
	;  really the last element.
	;
		BitSet	ss:WSFrame.WSF_flags, WSF_LAST_ELEMENT
writeIt:
		call	WriteElement		; carry set if write failed
		jc	done			
	;
	;  HugeArrayNext returns dx = size for variable-sized bitmaps
	;  (in our case, compacted bitmaps).  Otherwise dx is undefined.
	;  If we're writing a compacted bitmap, update the size field
	;  of our local variable frame.  If not, don't mess with it.
	;
		lds	si, ss:WSFrame.WSF_element
		call	HugeArrayNext		; ds:si = next element
		movdw	ss:WSFrame.WSF_element, dssi

		cmp	ss:WSFrame.WSF_compact, WSCT_COMPACTED
		jne	elementLoop

		mov	ss:WSFrame.WSF_elemSize, dx
		jmp	elementLoop
done:
	;
	;  Unlock the last element.
	;
		call	HugeArrayUnlock		; pass ds = sptr to last element

		.leave
		ret
WriteBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a huge-array element to the output file.

CALLED BY:	WriteBitmap

PASS:		ss:[bp]	= inherited WriteSourceFrame
		si	= element ptr (from ds:si returned by 
				HugeArrayLock or HugeArrayNext)

RETURN:		carry set if write failed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

SIDE EFFECTS:

	WSF_lineCount persists across calls to this routine,
	because where we are on a line (and where we break)
	is dependent only on what we've written to the line
	so far -- NOT on whether we've hit an element boundary.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/10/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteElement	proc	far
		uses	ax,bx,cx,dx,si,di,ds,es
		.enter	inherit	WriteBitmap
	;
	;  Set up the loop invariants.
	;
		mov	ds, ss:WSFrame.WSF_stringSeg
		clr	dx, bx				; high word & data size
		clr	ah				; high byte of low word
byteLoop:
	;
	;  If we've written all the data for the element, quit.
	;
		cmp	bx, ss:WSFrame.WSF_elemSize
		LONG	je	done			; clears carry
	;
	;  If we're at the beginning of the line (linecount = 0)
	;  and we're writing UIC, we need a "db" prefix in front of
	;  the line.
	;
		tst	ss:WSFrame.WSF_lineCount
		jnz	noDB

		cmp	ss:WSFrame.WSF_language, WSLT_GOC
		je	noDB

		WriteString	DBString		; UIC + starting line
noDB:
	;
	;  Write the next 0xae or 0xffff or whatever.
	;
		call	WriteDataWord
	;
	;  Write something based on the language and line count:
	;
	;	if (UIC) then
	;	  if (bx = dataSize AND it's the last element) then
	;	    do nothing
	;	  else if (line count = max) then
	;	    write CRLF
	;	  else /* regular old number */
	;	    write comma & space
	;	  endif
	;	else /* GOC -- easy */
	;	  write comma & space
	;	  if (line count = max) then write CRLF
	;	endif
	;
		cmp	ss:WSFrame.WSF_language, WSLT_GOC
		je	doGOC
doUIC::
	;
	;  We're doing UIC code.  If we're on the last byte of
	;  the bitmap, don't write anything.
	;
		mov	cx, bx				; cx = data size (DS)
		inc	cx				; cx = DS for next loop
		test	ss:WSFrame.WSF_flags, mask WSF_WRITING_LARGE
		jz	testLast
		inc	cx				; cx = DS for next loop
testLast:
		cmp	cx, ss:WSFrame.WSF_elemSize
		jb	notLast
	;
	;  We're on the last byte of the element.  Is it the
	;  last element of the huge array?  If so, we're done.
	;
		test	ss:WSFrame.WSF_flags, mask WSF_LAST_ELEMENT
		jnz	doneTail			; do nothing
notLast:
	;
	;  We're not on the last byte of the element.  Are we on
	;  the last byte of this line in the output file?
	;
		mov	cl, LARGE_LINE_ENTRIES
		test	ss:WSFrame.WSF_flags, mask WSF_WRITING_LARGE
		jnz	doTest
		mov	cl, LINE_ENTRIES
doTest:		
		cmp	ss:WSFrame.WSF_lineCount, cl
		je	writeCRLF			; yep, write CRLF
plainByte::
	;
	;  We're not at the end of the last element, so just
	;  write the old comma string as usual.
	;
		WriteString	Comma
		WriteString	Space
		jmp	doneTail
doGOC:
	;
	;  If we're writing a large bitmap, and we're on the last
	;  byte of the last element, don't write the comma/space.
	;
if 0
		how?
endif
	;
	;  Write comma & space no matter what.
	;
		WriteString	Comma
		WriteString	Space
	;
	;  If (line-count != max) skip writing CRLF.
	;
		mov	cl, LARGE_LINE_ENTRIES
		test	ss:WSFrame.WSF_flags, mask WSF_WRITING_LARGE
		jnz	doTest2
		mov	cl, LINE_ENTRIES
doTest2:		
		cmp	ss:WSFrame.WSF_lineCount, cl
		jne	doneTail
writeCRLF:
		test	ss:WSFrame.WSF_flags, mask WSF_WRITING_LARGE
		jnz	writeRaw
		WriteString	CRLF
		jc	done
		jmp	doneCRLF
writeRaw:	
		WriteString	RawCRLF
		jc	done
doneCRLF:
	;
	;  OK, a bit of a hack.  And I was trying so hard not
	;  to have any.  Since at the end we always increment
	;  the line count, and here we really want to end the
	;  loop with line count = 0, we set it to -1 and let
	;  the inc put it to the proper value.
	;
		mov	ss:WSFrame.WSF_lineCount, -1
doneTail:
	;
	;  Increment our counters (bx = data size) and loop.
	;
		inc	bx
		inc	ss:WSFrame.WSF_lineCount
		jmp	byteLoop
done:
		.leave
		ret
WriteElement	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDataWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write one byte or one word of data.

CALLED BY:	WriteElement()

PASS:		ss:bp = inherited WSFrame
		dx, ah    = clear

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/16/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteDataWord	proc	near
		.enter inherit WriteElement
	;
	;  Write common stuff.
	;
		WriteString	HexPrefixString		; "0x"
		mov	ds, ss:WSFrame.WSF_element.segment
	;
	;  If we're writing a large bitmap it's done differently.
	;
		test	ss:WSFrame.WSF_flags, mask WSF_WRITING_LARGE
		jnz	writeLarge
	;
	;  Get next byte & write it.
	;
		lodsb					; dx.ax = number
		mov	ds, ss:WSFrame.WSF_stringSeg
		call	WriteHexNumber			; "e9" or whatever
		jmp	done
writeLarge:
	;
	;  Get the first & second bytes, swap them and write them.
	;
		lodsb					; dx.ax = number
		push	ax
		lodsb					; dx.ax = 2nd number
		mov	ds, ss:WSFrame.WSF_stringSeg
		call	WriteHexNumber			; write 2nd first
		pop	ax				; write 1st second
		call	WriteHexNumber
done:
		.leave
		ret
WriteDataWord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteVisMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	just writes "visMoniker <name> = {"  (1st string in file)

CALLED BY:	WriteMonikerHeader

PASS:		ss:[bp] = inherited WriteSourceFrame
		ds	= ss:WSFrame.WSF_stringSeg

RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- if (we're writing GOC source) write an AtSymbolString.
	- write "vismoniker <name> = {"

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteVisMoniker	proc	near
		uses	ax, cx, dx
		.enter	inherit	WriteMonikerHeader
	;
	;  If we're writing GOC code, write an '@' symbol first.
	;	
		cmp	ss:WSFrame.WSF_language, WSLT_GOC
		jne	continue			; nope, skip atSymbol

		WriteString	AtSymbol
		jc	done
continue:
	;  
	;  Write "visMoniker Moniker" (the 2nd "Moniker" should
	;  really be customizable, which is why it's separated here).
	;
		WriteString VisMonikerString
		WriteString MonikerString
	;
	;  Write out the number of this format.
	;
		mov	ax, ss:WSFrame.WSF_curFormat
		clr	dx			; dx.ax = dword to convert
		call	IconWriteNumber
		jc	done
	;
	;  Write " = {"
	;
		WriteString VisMonikerTailString
done:
		.leave
		ret
WriteVisMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	writes the size for moniker-list selection

CALLED BY:	WriteMonikerHeader

PASS:		ss:[bp]	= inherited WriteSourceFrame
		ds	= ss:WSFrame.WSF_stringSeg

RETURN:		carry set if error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteSize	proc	near
		uses	ax, bx, cx, si
		.enter	inherit	WriteMonikerHeader
	;
	;  Write "size = ".
	;
		WriteString SizeString
		jc	done
	;
	;  Get the correct size string...
	;
		mov	bx, ss:WSFrame.WSF_type		; VMLET
		andnf	bx, mask VMLET_GS_SIZE		; isolate display size
		mov	cl, offset VMLET_GS_SIZE
		shr	bx, cl
		shl	bx				; word table
		mov	si, cs:[sizeTable][bx]		; *ds:si = string
	;
	;  ...and write it.
	;
		call	GetChunkStringSize
		call	IconWriteString
		jc	done
	;
	;  Write a semicolon.
	;	
		WriteString Semicolon
done:
		.leave
		ret

sizeTable	word	\
		offset	TinyString,
		offset StandardString,
		offset LargeString,
		offset HugeString

WriteSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the line "style = <blah>"

CALLED BY:	WriteMonikerHeader

PASS:		ss:[bp] = inherited WriteSourceFrame
		ds	= ss:WSFrame.WSF_stringSeg

RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	9/21/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteStyle	proc	near
		uses	ax, bx, cx, si
		.enter	inherit	WriteMonikerHeader
	;
	;  Write "style = ".
	;
		WriteString	StyleString
		jc	done
	;
	;  Figure out the style of the icon...
	;
		mov	bx, ss:WSFrame.WSF_type
		andnf	bx, mask VMLET_STYLE		; isolate style
		mov	cl, offset VMLET_STYLE
		shr	bx, cl
		shl	bx				; word table
		mov	si, cs:[styleTable][bx]		; *ds:si = string
	;
	;  ...and write it.
	;
		call	GetChunkStringSize		; ds:si = string
		call	IconWriteString
		jc	done
	;
	;  Write a semicolon.
	;	
		WriteString Semicolon
done:
		.leave
		ret
;
;  Make it an icon for all entries other than "tool".
;
styleTable	word	\
	offset	IconString,				; text
	offset	IconString,				; abbrev text
	offset	IconString,				; graphic
	offset	IconString,				; icon
	offset	ToolString				; tool

WriteStyle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the moniker's color scheme.

CALLED BY:	WriteMonikerHeader

PASS:		ss:[bp] = inherited WriteSourceFrame
		ds	= ss:WSFrame.WSF_stringSeg
		ss:WSFrame.WSF_element temporarily set to CBitmap struct

RETURN:		carry set if error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteColor	proc	near
		uses	ax, bx, cx, si
		.enter	inherit	WriteMonikerHeader
	;
	;  Write "color = ".
	;
		WriteString	ColorString
		jc	done
	;
	;  Figure out display type...
	;
		lds	si, ss:WSFrame.WSF_element	; ds:si = CBitmap
		mov	bl, ds:[si].CB_simple.B_type
		andnf	bl, mask BMT_FORMAT		; isolate BMFormat
		clr	bh
		shl	bx				; word table
		mov	si, cs:[formatTable][bx]	; si = string offset
	;
	;  ...and write it.
	;
		mov	ds, ss:WSFrame.WSF_stringSeg
		call	GetChunkStringSize		; ds:si = string
		call	IconWriteString
		jc	done
	;
	;  Write a semicolon.
	;
		WriteString Semicolon
done:	
		.leave
		ret

formatTable	word	\
		offset	Gray1String,
		offset	Color4String,
		offset	Color8String

WriteColor	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteAspectRatio
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the moniker's aspect ratio.

CALLED BY:	WriteMonikerHeader

PASS:		ss:[bp]	= inherited WriteSourceFrame
		ds	= ss:WSFrame.WSF_stringSeg

RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteAspectRatio	proc	near
		uses	ax, cx, si
		.enter	inherit WriteMonikerHeader
	;
	;  Write "aspectRatio = ".
	;
		WriteString AspectRatioString
		jc	done
	;
	;  Write the correct aspect ratio.
	;
		mov	ax, ss:WSFrame.WSF_type
		andnf	ax, mask VMLET_GS_ASPECT_RATIO
		shr	al
		shr	al
		shr	al
		shr	al
		cmp	al, DAR_VERY_SQUISHED
		je	verySquished
		cmp	al, DAR_SQUISHED
		je	squished

		mov	si, offset NormalString
		jmp	writeRatio
squished:
		mov	si, offset SquishedString
		jmp	writeRatio
verySquished:
		mov	si, offset VerySquishedString
writeRatio:		
		call	GetChunkStringSize		; ds:si = string
		call	IconWriteString
		jc	done
	;
	;  Write the trailing semicolon.
	;
		WriteString Semicolon
done:
		.leave
		ret
WriteAspectRatio	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteCachedSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the moniker's cached size.

CALLED BY:	WriteMonikerHeader

PASS:		ss:[bp]	= inherited WriteSourceFrame
		ds	= ss:WSFrame.WSF_stringSeg
		ss:WSFrame.WSF_element temporarily set to CBitmap struct

RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteCachedSize	proc	near
		uses	ax,bx,cx,dx,di,si
		.enter	inherit WriteMonikerHeader
	;
	;  Write "cachedSize = "
	;
		WriteString CachedSizeString
		jc	done
	;
	;  Determine the cached size for the moniker.  Convert width
	;  and height to ascii, using sizeBuffer
	;
		lds	si, ss:WSFrame.WSF_element	; ds:si = CBitmap
		mov	ax, ds:[si].CB_simple.B_width	; get the width
		clr	dx
		call	IconWriteNumber
		jc	done
	;
	;  Write a comma and a space.
	; 
		mov	bx, ds:[si].CB_simple.B_height	; save the height
		mov	ds, ss:WSFrame.WSF_stringSeg
		WriteString Comma
		WriteString Space
		jc	done
	;
	;  Write the height.
	;
		mov_tr	ax, bx
		clr	dx			; dx.ax = dword to convert
		call	IconWriteNumber
		jc	done
	;
	;  Write the trailing semicolon.
	;
		WriteString	Semicolon
done:
		.leave
		ret
WriteCachedSize	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteBitmapSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the size of the bitmap in decimal.

CALLED BY:	WriteMonikerHeader

PASS:		ss:[bp]	= inherited WriteSourceFrame

RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteBitmapSize	proc	near
		uses	ax,bx,cx,dx,si,di,ds
		.enter	inherit WriteMonikerHeader
	;
	;  First calculate the bitmap size.  If it's compacted we
	;  have to do a different calculation.
	;
		cmp	ss:WSFrame.WSF_compact, WSCT_COMPACTED
		je	compacted

		movdw	bxdi, ss:WSFrame.WSF_bitmap
		clrdw	dxax			; dereference 1st element
		call	HugeArrayLock		; returns size in dx
	;
	;  Get the total number of bytes in the huge array.
	;
		mov	cx, dx			; cx <- element size
		call	HugeArrayUnlock
		call	HugeArrayGetCount	; ax <- # elements
	
		mul	cx			; dx.ax <- # bytes (< 64k)
		add	ax, size Bitmap		; size includes bitmap header
		jmp	gotSize
compacted:
	;
	;  Ye bitmap is compacted.  Call a routine to loop through
	;  the elements and add up all the individual sizes.
	;
		movdw	cxdx, ss:WSFrame.WSF_bitmap
		call	ComputeCompactedBitmapSize	; dx.ax = size
gotSize:
		call	IconWriteNumber

		.leave
		ret
WriteBitmapSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeCompactedBitmapSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the data size for the compacted bitmap.

CALLED BY:	WriteBitmapSize

PASS:		^vcx:dx = compacted bitmap

RETURN:		dx:ax = size

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	We know we can use a word to store the total size, because
	there's never going to be a bitmap that's got > 64k of data.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	9/20/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeCompactedBitmapSize	proc	near
		uses	bx,cx,si,di,bp,ds
		.enter
	;
	;  Lock the first element.
	;
		clr	bp			; total size thus far
		movdw	bxdi, cxdx

if 0
EC <		mov	ax, di						>
EC <		call	IVMInfoVMChain					>
EC <		tst	cx						>
EC <		ERROR_NZ BITMAP_TOO_BIG_TO_WRITE_SOURCE_CODE		>
EC <		mov	di, ax			; ^vbx:di = bitmap	>
endif
		clrdw	dxax 			; element to lock
		call	HugeArrayLock		; dx = size, ds:si = element
	;
	;  Loop through the rest of the elements, adding their
	;  sizes to bp.
	;
elemLoop:
		tst	ax			; any more elements?
		jz	doneLoop		; nope, we're gone

		add	bp, dx

		call	HugeArrayNext		; dx = new size
		jmp	elemLoop
doneLoop:
	;
	;  Unlock the last element.
	;
		call	HugeArrayUnlock
	;
	;  Return the size in dx:ax.
	;
		clr	dx
		mov_tr	ax, bp
		add	ax, size Bitmap		; don't forget!

		.leave
		ret
ComputeCompactedBitmapSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteBitmapHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	writes Bitmap <xx,xx,BMC_PACKBITS,mask ......> to file

CALLED BY:	WriteMonikerHeader

PASS:		ss:[bp]	= inherited WriteSourceFrame
		ds	= ss:WSFrame.WSF_stringSeg
		ss:WSFrame.WSF_element temporarily set to CBitmap structure

RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	This is a long grunt routine that converts the appropriate
	values to hex and writes them, with commas and such.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteBitmapHeader	proc	near
		uses	ax,bx,cx,dx,si
		.enter	inherit WriteMonikerHeader
	;
	;  Write the "Bitmap " part.  If we're doing UIC, do an
	;  open angle bracket; otherwise do an open paren.
	;
		WriteString	BitmapString
		LONG	jc 	done

		mov	si, offset OpenParen
		cmp	ss:WSFrame.WSF_language, WSLT_GOC
		je	writeOpen
		mov	si, offset OpenAngleBracket
writeOpen:
		call	GetChunkStringSize
		call	IconWriteString		; ...then write a bracket
		LONG	jc 	done
	;
	;  Convert width to ascii and write it, followed by
	;  a comma.
	;
		lds	si, ss:WSFrame.WSF_element
		mov	ax, ds:[si].CB_simple.B_width	
		mov	bx, ds:[si].CB_simple.B_height
		clr	dx			; dx.ax = dword to convert
		call	IconWriteNumber
		LONG	jc	done

		mov	ds, ss:WSFrame.WSF_stringSeg
		WriteString	Comma
	;
	;  Convert height to ascii and write it, followed by
	;  a comma.
	;
		mov_tr	ax, bx			; ax = height
		clr	dx			; dx.ax = dword to convert
		call	IconWriteNumber
		WriteString	Comma
		LONG	jc	done
	;
	;  Write the BMC_UNCOMPACTED string, or BMC_PACKBITS,
	;  followed by a comma.
	;
		mov	si, offset PackString
		cmp	ss:WSFrame.WSF_compact, WSCT_COMPACTED
		je	writeCompact
		mov	si, offset UnPackString
writeCompact:
	;
	;  Write the appropriate string.
	;
		call	GetChunkStringSize
		call	IconWriteString
		WriteString	Comma
	;
	;  At this point, in GOC, we write an open-paren no
	;  matter what.
	;
		cmp	ss:WSFrame.WSF_language, WSLT_GOC
		jne	noOpen
		WriteString	OpenParen
noOpen:
	;
	;  If the user's writing a mask, write the BMT_MASK part.
	;
		test	ss:WSFrame.WSF_flags, mask WSF_WRITING_MASK
		jz	noMask
	;
	;  We're writing BM_MASK, with "mask" in front for UIC/ESP.
	;
		cmp	ss:WSFrame.WSF_language, WSLT_GOC
		je	writeBMMask

		WriteString	MaskString		; ESP needs this
writeBMMask:
		WriteString	BMMaskString
	;
	;  Write "or" (UIC) or "|" (GOC).
	;
		mov	si, offset OrSymbol
		cmp	ss:WSFrame.WSF_language, WSLT_GOC
		je	writeOr
		mov	si, offset OrString
writeOr:
		call	GetChunkStringSize
		call	IconWriteString
noMask:
	;
	;  Find out the color scheme.
	;
		lds	si, ss:WSFrame.WSF_element	; ds:si = CBitmap
		mov	ah, ds:[si].CB_simple.B_type
		mov	ds, ss:WSFrame.WSF_stringSeg	; restore ds
		andnf	ah, mask BMT_FORMAT	; see if 16-color bitmap
	;
	;  Choose the appropriate color string.
	;
		mov	si, offset Bit4String
		cmp	ah, BMF_4BIT shl offset BMT_FORMAT
		je	writeColor
		mov	si, offset MonoString
writeColor:
		call	GetChunkStringSize
		call	IconWriteString
	;
	;  Write the closing angle bracket/close paren.
	;
		mov	si, offset CloseParen
		cmp	ss:WSFrame.WSF_language, WSLT_GOC
		je	writeClose
		mov	si, offset CloseAngleBracket
writeClose:
		call	GetChunkStringSize
		call	IconWriteString
	;
	;  If we're writing GOC we actually do 1 more close paren
	;  and a comma.
	;
		cmp	ss:WSFrame.WSF_language, WSLT_GOC
		jne	done

		WriteString	CloseParen
		WriteString	Comma
done:
	;
	;  Write a CRLF in any case.
	;
		WriteString	CRLF
		
		.leave
		ret
WriteBitmapHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconWriteSourceError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display an error message

CALLED BY:	DBViewerWriteSource

PASS:		ax = error code (WriteSourceErrors)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconWriteSourceError	proc	near
		uses	bx, si
		.enter
	;
	;  If there was really no error, return.
	;
		tst	ax				; WSF_NO_ERROR
		jz	done

		mov	bx, ax				; bx <- error code
		mov	si, cs:[errorTable][bx]
		call	DisplayError
done:
		.leave
		ret

errorTable	word	\
		0,					; WSE_NO_ERROR
		offset	BadFileNameText,		; WSE_BAD_FILENAME
		offset	FileCreateErrorText,		; WSE_FILE_CREATE
		offset	FileWriteErrorText,		; WSE_FILE_WRITE
		offset	InvalidImageText		; WSE_INVALID_IMAGE

IconWriteSourceError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyUserWriteSourceSuccessful
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells user we're done writing source code.

CALLED BY:	DBViewerWriteSource
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- tell 'em everything's cool

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotifyUserWriteSourceSuccessful	proc	near
		uses	si
		.enter

		mov	si, offset	WriteSourceSuccessfulText
		call	DisplayNotification

		.leave
		ret
NotifyUserWriteSourceSuccessful	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitStackFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get options and save them in local variables.

CALLED BY:	DBViewerWriteSource

PASS:		ss:bp	= inherited WriteSourceFrame
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/10/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitStackFrame	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di
		.enter	inherit	DBViewerWriteSource
	;
	;  Zero out anything that needs to be zeroed.
	;
		clr	ss:WSFrame.WSF_flags
	;
	;  See whether we're writing a VisMoniker or a PointerDef struct.
	;
		push	bp			; locals
		mov	bx, ds:[di].GDI_display
		mov	si, offset WriteSourceHeaderList
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage		; ax = selection
		pop	bp			; locals
		jc	noHeader

		mov	ss:WSFrame.WSF_header, al
		jmp	doneHeader
noHeader:
		mov	ss:WSFrame.WSF_header, WSHT_BITMAP
doneHeader:
	;
	;  Find out whether we're writing GOC or ESP source code.
	;
		push	bp			; locals
		mov	si, offset WriteSourceLanguageList
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage
		pop	bp			; locals

		mov	ss:WSFrame.WSF_language, al
	;
	;  See if we're compacting the bitmap.
	;
		push	bp			; locals
		mov	si, offset WriteSourceCompactionList
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage
		pop	bp			; locals

		mov	ss:WSFrame.WSF_compact, al
	;
	;  Find out whether user wants to write whole icon or
	;  just 1 format.
	;
		push	bp
		mov	si, offset WriteSourceFormatList
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	; returns in al
		call	ObjMessage
		pop	bp

		mov	ss:WSFrame.WSF_format, al
	;
	;  Figure out whether they're writing a large bitmap.
	;
		push	bp
		mov	si, offset WriteSourceLargeBoolean
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage
		pop	bp

		jc	noSelection

		ornf	ss:WSFrame.WSF_flags, mask WSF_WRITING_LARGE
noSelection:
	;
	;  Figure out whether they're writing the mask data.
	;
		push	bp
		mov	si, offset OtherOptionsBooleanGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	ObjMessage			; ax = booleans
		pop	bp
		jc	noBooleans

		test	ax, mask WSOO_WRITE_MASK
		jz	noBooleans

		ornf	ss:WSFrame.WSF_flags, mask WSF_WRITING_MASK
noBooleans:
		.leave
		ret
InitStackFrame	endp


SourceCode	ends
