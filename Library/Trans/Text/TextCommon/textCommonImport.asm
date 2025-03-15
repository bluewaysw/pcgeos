COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text translation libraries
FILE:		textCommonImport.asm

AUTHOR:		Jenny Greenwood, 9 July 1992

ROUTINES:
	Name				Description
	----				-----------
	TextCommonImport		Imports from source file to
					transfer format
	TextCommonGetFormat		Determines format of file to
					be imported

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/9/92		Initial version

DESCRIPTION:
	Common code to import text files from source file to transfer
	format using the MasterSoft metafile as an intermediate stage.

	$Id: textCommonImport.asm,v 1.1 97/04/07 11:29:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextCommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCommonImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Imports from source file to transfer format

CALLED BY:	GLOBAL

PASS:		ds:si	- ImportFrame on stack
		bx	- segment of translation library routine to call
		ax	- offset of translation library routine to call


RETURN:		ax	- TransError (0 = no error)
		bx	- memory handle of error text if ax = TE_CUSTOM
			- else clipboardFormat = CIF_TEXT
		dx:cx	- VM chain containing transfer format
		si	- ManufacturerID
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		Create a metafile.
		P the semaphore around the library.
			(The MasterSoft code uses global variables.)
		Import from the source file to the MasterSoft metafile.
		V the semaphore around the library.
		Import from the metafile to a transfer item.
		Delete the metafile.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

; TO DO: check for errors passed back from called routines.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jenny	7/09/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextCommonImport	proc	far
		uses	di, ds, es
metafileName	local	FILE_LONGNAME_BUFFER_SIZE dup(char)

		.enter

		push	bp			; save to access local buffer
		push	bx, ax			; save address of routine
						;  to call
	;
	; Create a metafile.
	;
		segmov	es, ss
		lea	di, metafileName
		mov	ax, IMPEX_TEMP_NATIVE_FILE
		call	ImpexCreateTempFile	; bp <- metafile handle
						; metafileName <- name
						; ax <- TransError or 0
						; bx <- handle of error msg
						; 	if ax = TE_CUSTOM
		mov_tr	di, ax
		tst	di
		jnz	error			; done if error
		pop	dx, ax			; dx:ax <- routine address
		push	bp			; save metafile handle
		push	ds:[si].IF_transferVMFile	; save VM file handle
							;  of transfer item
	;
	; P the semaphore around the library.
	;
		call	TransLibraryThreadPSem
	;
	; Import from the source file to the MasterSoft metafile.
	; Store address to jump to and stack pointer and TPD_stackBot
	; values to restore in case of error in the MasterSoft code's
	; execution.
	;
		mov	bx, dgroup
		mov	es, bx
		call	GeodeGetProcessHandle	; bx <- geode handle
		mov	cx, offset finish
		mov	es:[returnAddr], cx
		mov	es:[returnStackPtr], sp
		mov	cx, ss:[TPD_stackBot]
		mov	es:[returnTPD_stackBot], cx

		call	TextCommonImportLow	; ax <- TransError or 0
						; bx <- handle of error msg
						; 	if ax = TE_CUSTOM
finish:
	;
	; V the semaphore around the library.
	;
		call	TransLibraryThreadVSem

		pop	di			; di <- VM file handle
						; 	of transfer item
		pop	bp			; bp <- metafile handle
		push	bp			; save metafile handle
		tst	ax
		jnz	deleteMetafile		; done if error
	;
	; Import from the metafile to a transfer item.
	;
		mov	bx, bp			; bx <- metafile handle
		mov	bp, handle msmfile	; bp <- handle of msmfile
						;  translation library
		mov	ax, enum MetafileImport	; ax <- entry point #
		call	ImpexImportFromMetafile	; dx:cx <- VM chain containing
						; 	   transfer format 
						; ax <- TransError or 0
						; bx <- handle of error msg
						; 	if ax = TE_CUSTOM

deleteMetafile:
		mov_tr	ax, di			; di <- TransError or 0
		pop	si
		xchg	si, bx			; bx <- metafile handle
						; si <- save error msg, if any
		pop	bp			; bp <- original bp
		segmov	ds, ss
		push	dx			; save VM chain.high
		lea	dx, metafileName
		mov	ax, IMPEX_TEMP_NATIVE_FILE
		call	ImpexDeleteTempFile

		pop	dx			; dx:cx <- VM chain
		mov	bx, si			; bx <- error msg, if any
done:
		mov_tr	ax, di			; ax <- TransError or 0

		cmp	ax, TE_NO_ERROR		; was there an error
		jne	exit			; yes, exit
		mov	bx, CIF_TEXT		; no error, so set up formats
		mov	si, MANUFACTURER_ID_GEOWORKS
exit:
		.leave
		ret
error:
		add	sp, 4			; clear stack
		pop	bp			; restore bp
		jmp	done

TextCommonImport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCommonImportLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Imports from source file to MasterSoft metafile

CALLED BY:	GLOBAL

PASS:		ds:si	- ImportFrame on stack
		dx	- segment of translation library routine to call
		ax	- offset of translation library routine to call
		bx	- geode handle of translation library
		bp	- handle of metafile


RETURN:		ax	- TransError (0 = no error)
		bx	- memory handle of error text if ax = TE_CUSTOM
		dx:cx	- VM chain containing transfer format

DESTROYED:	di, si, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jenny	7/09/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextCommonImportLow	proc	near

		push	ds:[si].IF_sourceFile	; source file handle
		push	bp			; metafile handle
		push	ds:[si].IF_formatNumber	; format number
		push	bx			; geode handle for use
						;  by _Malloc
		mov	bx, si
		add	bx, offset IF_sourceFileName 
		pushdw	dsbx			; pointer to file name
		mov	bx, si
		add	bx, offset IF_sourcePathName 
		pushdw	dsbx			; pointer to path name
		push	ds:[si].IF_sourcePathDisk

		pushdw	dxax			; address of routine
						;  to call
		mov	bx, segment dgroup
		mov	ds, bx
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		ret

TextCommonImportLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCommonGetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines format of file to be imported

CALLED BY:	GLOBAL

PASS:		si	- file handle (open for read)	
		bx	- segment of translation library routine to call
		di	- offset of translation library routine to call

RETURN:		ax	- TransError (0 = no error)
		cx	- format number if valid format
			  or NO_IDEA_FORMAT if not

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:

		Use a buffer on the heap if more than 256 bytes of the
		file must be read in; otherwise use the stack.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jenny	9/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef TRANS_GET_FORMAT_BUFFER_SIZE

ErrMessage	<Error - Set TRANS_GET_FORMAT_BUFFER_SIZE before including this file.>

else

LARGE_THRESHOLD	equ	256

TextCommonGetFormat	proc	far 

		if	TRANS_GET_FORMAT_BUFFER_SIZE gt LARGE_THRESHOLD
			mov	ax, TRANS_GET_FORMAT_BUFFER_SIZE
			GetFormatHeap
		else
			GetFormatStack
		endif

TextCommonGetFormat	endp

endif

TextCommonCode	ends
