COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1995.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Icon Editor
MODULE:		format
FILE:		formatVMFile.asm

AUTHOR:		Steve Yegge, May 24, 1995

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	5/24/95		Initial revision

DESCRIPTION:

	This file contains routines for writing the current format
	out to a VM file, where the first block of the huge array
	(the EditableBitmap header block) is the map block of the
	VM file.  This allows the app writer to do:

		VMOpen
		VMGetMapBlock
		GrDrawHugeArray (file, map block)
		VMClose

	The output VM file is created in the document directory.

	$Id: formatVMFile.asm,v 1.1 97/04/04 16:06:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteToFileCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerWriteToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the current format to a VM file.

CALLED BY:	GLOBAL (MSG_DB_VIEWER_WRITE_TO_FILE)

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- get the filename & open file
	- get the user options
	- if they're stripping the mask, do it
	- if they're compacting the bitmap, do it
	- save in file
	- close file

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerWriteToFile	proc	far
		class	DBViewerClass

		WTFFrame	local	WriteToFileFrame

		.enter

		call	IconMarkBusy
	;
	;  Get the filename & open the file for writing.
	;
		call	WTFCreateVMFile			; bx = handle
		jc	error
	;
	;  Get bitmap for writing.
	;
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, ds:[di].DBVI_currentFormat
		cmp	bx, NO_CURRENT_FORMAT
		je	error

		push	bp
		mov	bp, ds:[di].GDI_fileHandle
		call	IdGetFormat		; ^vcx:dx = current format
		pop	bp
	;
	;  Maybe strip out mask
	;
		call	WTFMaybeStripMask	; al = options, ah = flag
		test	ss:WTFFrame.WTFF_flags, mask WTFF_REMOVED_MASK
		jz	doCompact
	;
	;  We stripped the mask; save temp bitmap in locals.
	;
		movdw	ss:WTFFrame.WTFF_bitmap, cxdx	; save for later
doCompact:		
	;
	;  Compact the bitmap if necessary.
	;
		movdw	bxax, cxdx
		mov	dx, ss:WTFFrame.WTFF_destFile
		test	ss:WTFFrame.WTFF_options, mask WTFO_COMPACT_BITMAP
		jz	copyBitmap
	;
	;  If we're compacting the bitmap, use the output VM file
	;  as the destination, so we don't have to do the copy.
	;
		call	GrCompactBitmap		; ^vdx:cx = new bitmap
		movdw	bxax, dxcx
		jmp	setMapBlock
copyBitmap:		
	;
	;  Copy bitmap to VM file.
	;
		push	bp
		clr	bp
		call	VMCopyVMChain		; ^vax:bp = new bitmap
		movdw	bxax, axbp
		pop	bp
setMapBlock:
	;
	;  ^vbx:ax = new bitmap in destination file.  Set first
	;  block as the map block.  Then close the file.
	;
		call	VMSetMapBlock		; easy as that
		clr	al
		call	VMClose
		mov	ax, WSE_FILE_WRITE
		jc	error
done::
	;
	;  Free temp bitmap, if any.
	;
		test	ss:WTFFrame.WTFF_flags, mask WTFF_REMOVED_MASK
		jz	exit

		movdw	bxdi, ss:WTFFrame.WTFF_bitmap
		call	HugeArrayDestroy
exit:
	;
	;  Notify success.
	;
		mov	si, offset WriteToFileSuccessText
		call	DisplayNotification		

		call	IconMarkNotBusy

		.leave
		ret
error:
		call	WriteToFileError
		jmp	exit
DBViewerWriteToFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WTFCreateVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get filename & create file.

CALLED BY:	DBViewerWriteToFile

PASS:		ss:bp	= inherited WriteToFileFrame

RETURN:		carry set on error, set on success
		ss:WTFF_destFile = file handle
		ax = WriteSourcErrors

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WTFCreateVMFile	proc	near
		class	DBViewerClass
		uses	bx,cx,dx,si,di,ds
		.enter	inherit DBViewerWriteToFile
	;
	;  Get the filename from the WriteSourceDialog box.
	;
		push	bp			; locals
		mov	dx, ss
		lea	bp, ss:WTFFrame.WTFF_filename
		mov	bx, ds:[di].GDI_display
		mov	si, offset WriteToFileText
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
		lea	dx, ss:WTFFrame.WTFF_filename
		mov	ax, (VMO_CREATE) shl 8 or \
				mask VMAF_FORCE_READ_WRITE
		clr	cx			; default compression
		call	VMOpen			; bx = file handle
		mov	ss:WTFFrame.WTFF_destFile, bx
		mov	ax, WSE_FILE_CREATE	; assume failure
		jc	done

		mov	ax, WSE_NO_ERROR	; success!
		call	FilePopDir		; preserves flags
		clc
done:
		.leave
		ret
WTFCreateVMFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WTFMaybeStripMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strip out mask data if user wants to do so.

CALLED BY:	DBViewerWriteToFile

PASS:		^vcx:dx = bitmap
		ds:di	= DBViewerInstance
		ss:bp	= inherited WriteToFileFrame

RETURN:		ss:bp.WTFF_flags = WTFF_REMOVED_MASK if removed mask
		^vcx:dx = new bitmap, if any

DESTROYED:	nothing (ds may be fixed up)

PSEUDO CODE/STRATEGY:

SIDE EFFECTS:	retrieving the user options is a side effect of
		this routine

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	5/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WTFMaybeStripMask	proc	near
		class	DBViewerClass
		uses	bx,si,bp
		.enter	inherit	DBViewerWriteToFile
	;
	;  Get the options.
	;
		clr	ss:WTFFrame.WTFF_flags
		clr	ss:WTFFrame.WTFF_options
		mov	bx, ds:[di].GDI_display
		mov	si, offset WTFOptionsGroup

		Assert	optr	bxsi

		push	cx, dx, bp
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; ax = WriteToFileOptions
		pop	cx, dx, bp
		jc	done
	;
	;  If user wants to strip mask, do so.
	;
		mov	ss:WTFFrame.WTFF_options, al
		test	al, mask WTFO_WRITE_MASK
		jnz	done

		call	StripMaskDataFromBitmap
		jnc	done
		ornf	ss:WTFFrame.WTFF_flags, mask WTFF_REMOVED_MASK
done:
		.leave
		ret
WTFMaybeStripMask	endp


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
WriteToFileError	proc	near
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

WriteToFileError	endp

WriteToFileCode	ends
