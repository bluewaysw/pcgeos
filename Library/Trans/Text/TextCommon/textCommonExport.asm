COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Translation Libraries
FILE:		textCommonExport.asm

AUTHOR:		Jenny Greenwood, 9 July 1992

ROUTINES:
	Name				Description
	----				-----------
	TextCommonExport		Exports from transfer format
					to output file
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	7/9/92		Initial version


DESCRIPTION:
		

	$Id: textCommonExport.asm,v 1.1 97/04/07 11:29:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextCommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCommonExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exports from transfer format to output file

CALLED BY:	GLOBAL

PASS:		ds:si	- ExportFrame on stack
		bx	- segment of translation library routine to call
		ax	- offset of translation library routine to call


RETURN:		ax	- TransError (0 = no error)
		bx	- memory handle of error text if ax = TE_CUSTOM

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Create a metafile.
	Export from the transfer format to the MasterSoft metafile format.
	P the semaphore around the library.
		(The MasterSoft code uses global variables.)
	Export from the metafile to the output file.
	V the semaphore around the library.
	Delete the metafile.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jenny	7/09/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextCommonExport		proc	far
		uses	si, di, ds, es
metafileName	local	DOS_DOT_FILE_NAME_LENGTH_ZT  dup(char)

		.enter

		push	bp			; save original bp
		push	bx, ax			; save address of
						;  routine to call	
		cmp	ds:[si].EF_clipboardFormat, CIF_TEXT
		jne	formatError
		cmp	ds:[si].EF_manufacturerID, MANUFACTURER_ID_GEOWORKS
		jne	formatError

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
		tst	ax
		jnz	error			; done if no metafile created
	;
	; Export from the transfer format to the MasterSoft metafile format.
	;
		mov	bx, handle msmfile	; bx <- handle of MSMetafile
						; translation library
		mov	ax, enum MetafileExport		; ax <- entry point #
		mov	dx, ds:[si].EF_transferVMChain.high
		mov	cx, ds:[si].EF_transferVMChain.low
		mov	di, ds:[si].EF_transferVMFile
		call	ImpexExportToMetafile	; ax <- TransError or 0
						; bx <- handle of error msg
						; 	if ax = TE_CUSTOM
		tst	ax
		jnz	deleteMetafile		; done if error
	;
	; P the semaphore around the library.
	;
		call	TransLibraryThreadPSem
	;
	; Export from the MasterSoft metafile to the output file.
	; Store address to jump to and stack pointer and TPD_stackBot
	; values to restore in case of error in the MasterSoft code's
	; execution.
	;
		mov	bx, dgroup
		mov	es, bx
		call	GeodeGetProcessHandle	; bx <- geode handle
		pop	dx, ax			; dx:ax <- routine address
		push	bp			; save metafile handle
		mov	cx, offset finish
		mov	es:[returnAddr], cx
		mov	es:[returnStackPtr], sp
		mov	cx, ss:[TPD_stackBot]
		mov	es:[returnTPD_stackBot], cx

		call	TextCommonExportLow	; ax <- TransError or 0
						; bx <- handle of error msg
						; 	if ax = TE_CUSTOM
finish:
		pop	bp			; bp <- metafile handle
	;
	; V the semaphore around the library.
	;
		call	TransLibraryThreadVSem

deleteMetafile:
		mov_tr	di, ax			; di <- save TransError or 0
		mov	cx, bx			; cx <- save error msg, if any
		mov	bx, bp			; bx <- metafile handle
		pop	bp			; bp <- original bp
		push	bp			; save original bp again
		segmov	ds, ss
		lea	dx, metafileName
		mov	ax, IMPEX_TEMP_NATIVE_FILE
		call	ImpexDeleteTempFile

		mov_tr	ax, di			; restore ax and bx
		mov	bx, cx			;  in case they hold
						;  error info
done:
		pop	bp			; bp <- original bp
		.leave
		ret
formatError:
		mov	ax, TE_EXPORT_INVALID_CLIPBOARD_FORMAT
error:
		add	sp,4			; clear stack
		jmp	done

TextCommonExport		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCommonExportLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls MasterSoft code to export from metafile to output file

CALLED BY:	TextCommonExport

PASS:		ds:si	- ExportFrame on stack
		dx	- segment of translation library routine to call
		ax	- offset of translation library routine to call
		bx	- geode handle of translation library
		bp	- handle of metafile

RETURN:		ax	- TransError (0 = no error)
		bx	- memory handle of error text if ax = TE_CUSTOM

DESTROYED:	di, si, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jenny	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextCommonExportLow	proc	near

		push	bp			; metafile handle
		push	ds:[si].EF_outputFile	; output file handle
		push	ds:[si].EF_formatNumber	; format number
		push	bx			; geode handle for use
						;  by _Malloc
		mov	bx, si
		add	bx, offset EF_outputFileName 
		pushdw	dsbx			; pointer to file name
		mov	bx, si
		add	bx, offset EF_outputPathName 
		pushdw	dsbx			; pointer to path name
		push	ds:[si].EF_outputPathDisk

		pushdw	dxax			; address of routine
						;  to call
		mov	bx, dgroup
		mov	ds, bx
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		ret

TextCommonExportLow	endp

TextCommonCode	ends
