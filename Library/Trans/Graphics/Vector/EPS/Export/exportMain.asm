COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Translation Library
FILE:		exportMain.asm

AUTHOR:		Jim DeFrisco, 12 Feb 1991

ROUTINES:
	Name			Description
	----			-----------
    GLB EPSExportHeader         output any header info

    GLB TransExport             Externally callable export routine.

    GLB EPSExportLow            perform export of a graphics file

    GLB EPSExportRaw            output some data as is to the stream (no
				conversion)

    GLB EPSExportBitmap         perform export of a bitmap

    GLB EPSExportTrailer        output any trailer info

    GLB EPSExportBeginPage      do any page-starting calculations

    GLB EPSExportEndPage        do any page-ending calculations

    GLB EPSNormalizeFilename    Check the filename set in the options block
				and change it if it is non-conforming.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/91		Initial revision


DESCRIPTION:
	This file contains the main interface to the export side of the 
	library
		

	$Id: exportMain.asm,v 1.1 97/04/07 11:25:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPSExportHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	output any header info

CALLED BY:	GLOBAL

PASS:		dx	- handle of option block, zero to use default
		di	- handle of EPSExportLowStreamStruct

RETURN:		ax	- TransError error code

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		export the file header and prolog

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPSExportHeader proc	far
		uses	bx, cx, ds, es, si, dx, di
		.enter
		
		; check for bogus stream block handle and bail if we get one...

		tst	di
		LONG jz	errorFileWrite

		; lock down the options block.  We'll need info from there...

		mov	bx, dx			; bx = options block handle
		call	MemLock			; lock it down
		mov	es, ax			; es -> options block

		; first write out the header comments.  For a few of them,
		; we need to insert arguments.  Check to make sure writing
		; comments is OK...

		or	es:[PSEB_status], mask PSES_OPEN_PROLOG ; set flag

		test	es:[GEO_flags], mask GEF_NO_COMMENTS
		jnz	outputProlog

		; lock down the PSCode resource to emit the comments

		mov	bx, handle PSCode
		call	MemLock
		mov	ds, ax
		call	EmitHeaderComments
		call	MemUnlock		; release PSCode resource
		jc	unlockOptBlk

		; next, output the PostScript code for the prolog.
outputProlog:
		mov	bx, handle PSProlog	; get resource handle
		call	MemLock	; lock it down
		mov	ds, ax			; ds -> PSCode resource
		test	es:[GEO_flags], mask GEF_NO_HEADER
		clc				; assume no errors
		jnz	doneNoError

		push	dx			; save options block handle
		mov	bx, di
		clr	al			; handle errors
		mov	cx, offset endPSProlog - offset beginPSProlog
		mov	dx, offset beginPSProlog
		call	SendToStream		; write out prolog
		pop	dx			;restore options block handle
doneNoError:
		mov	bx, handle PSProlog	; unlock resource block
		call	MemUnlock
unlockOptBlk:
		mov	bx, dx			; unlock options block
		call	MemUnlock
		jc	errorFileWrite		; flags preserved by MemUnlock

		; finally, check for a patch file, and include it here

		call	FilePushDir		; save current dir
		mov	ax, SP_SYSTEM		; probably should be changed
;		mov	ax, SP_IMPORT_EXPORT_DRIVERS  ; for 2.0
		call	FileSetStandardPath
		segmov	ds, cs, dx
		mov	dx, offset cs:patchfile
		mov	al, FILE_ACCESS_R or FILE_DENY_NONE
		call	FileOpen		; if open fails, no patch file
		cmc
		jnc	noPatchFile
		mov	si, ax			; si =  source file handle
		mov	bx, ax
		call	FileSize		; ax = size of source file
		push	ax			; save size
		mov	cx, ALLOC_DYNAMIC_LOCK	; alloc a block for file
		call	MemAlloc
		pop	cx
		jc	errorCloseFile		; return error
		push	bx			; save block handle
		mov	ds, ax			; ds -> block
		clr	dx
		mov	bx, si			; source file handle
		mov	al, FILE_NO_ERRORS
		call	FileRead
		mov	bx, di			; dest file handle
		clr	al
		call	SendToStream		; copy file contents
		pop	bx
		pushf
		call	MemFree			; free the temp block
closeFile:
		mov	bx, si
		mov	al, FILE_NO_ERRORS
		call	FileClose		; close source file
		popf				; restore error flag
noPatchFile:
		call	FilePopDir
		mov	ax, TE_NO_ERROR		; assume no errors
		jc	errorFileWrite
done:
		.leave
		ret

		; some error occured.  need to close the file.
errorCloseFile:
		pushf				; save carry flag
		jmp	closeFile
		
		; some error in StreamWrite, handle it
errorFileWrite:
		mov	ax, TE_EXPORT_ERROR
		jmp	done
EPSExportHeader endp

patchfile	char	"patch.ps", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Externally callable export routine.

CALLED BY:	GLOBAL
PASS:		ds:si	- ExportFrame
RETURN:		ax	- TE_NO_ERROR

			-or-

		ax	- TransError and
		bx	- handle of custom error string if AX = TE_CUSTOM
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EC  < fileStreamDr	char	"filestre.geo",0 >
NEC < fileStreamDr	char	"filestr.geo",0  >

TransExport	proc	far
fileStrDr	local	hptr
fileStrToken	local	word
fileStrStrategy	local	fptr
epsStreamBlock	local	hptr
		.enter

		; do some checking of parameters for EC

		mov	ax, TE_INVALID_FORMAT		; in case error...
		cmp 	ds:[si].EF_formatNumber, EpsFormat
		LONG jae done

		; load filestr driver

		push	ds, si
		call	FilePushDir
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath
 		segmov	ds, cs
		mov	si, offset fileStreamDr		; ds:si -> port driver
		mov	ax, FILESTR_PROTO_MAJOR
		mov	bx, FILESTR_PROTO_MINOR
		call	GeodeUseDriver
 		call	FilePopDir
		pop	ds, si
		LONG jc	exportError

		mov	ss:[fileStrDr], bx

		; get driver info

		push	ds, si
		call	GeodeInfoDriver
		movdw	ss:[fileStrStrategy], ds:[si].DIS_strategy, ax
		pop	ds, si

		; open stream on file

		mov	di, DR_STREAM_OPEN
		mov	ax, mask SOF_NOBLOCK
		mov	bx, ds:[si].EF_outputFile
		mov	dx, 1024			; fileStr buffer size
		call	ss:[fileStrStrategy]
		mov	ax, TE_EXPORT_ERROR		; in case error...
		LONG jc	freeDriver

		mov	ss:[fileStrToken], bx

		; create EPSExportLowStreamStruct block

		mov	ax, size EPSExportLowStreamStruct
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
		mov_tr	cx, ax				; cx <- alloc'd segment
		mov	ax, TE_EXPORT_ERROR		; in case error...
		jc	closeStream

		push	ds
		mov	ss:[epsStreamBlock], bx
		mov	ds, cx
		mov	ax, ss:[fileStrToken]
		mov	ds:[ESPELSS_token], ax
		movdw	ds:[ESPELSS_strategy], ss:[fileStrStrategy], ax
		call	MemUnlock
		pop	ds

		; export

		mov	di, bx				; di = stream block
		mov	dx, ds:[si].EF_exportOptions	; load handle to opts

		call	EPSExportHeader			; write postscript
		cmp	ax, TE_NO_ERROR			;  header
		jne	freeStreamBlock

		call	EPSExportBeginPage		; write begin page
		cmp	ax, TE_NO_ERROR
		jne	freeStreamBlock

		push	di, dx
		mov	bx, ds:[si].EF_transferVMFile	; get file handle
		mov	si, ds:[si].EF_transferVMChain.high ; get HA handle
		mov	cl, GST_VMEM			; it's a VM chain
		call	GrLoadGString			; si = GString handle
		clr	cx				; stop at end 
		call	EPSExportLow			; ax = TransError
		clr	di
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString		; kill GString struct
		pop	di, dx

		cmp	ax, TE_NO_ERROR
		jne	freeStreamBlock

		call	EPSExportEndPage		; write end page
		cmp	ax, TE_NO_ERROR
		jne	freeStreamBlock

		call	EPSExportTrailer		; write postscript
							;  trailer
freeStreamBlock:
		mov	bx, ss:[epsStreamBlock]
		call	MemFree				; free epsStreamBlock
closeStream:
		; close the stream (commits final writes) & free stream driver

		push	ax
		mov	di, DR_STREAM_CLOSE
		mov	ax, STREAM_LINGER
		mov	bx, ss:[fileStrToken]
		call	ss:[fileStrStrategy]		; close the stream
		pop	ax
freeDriver:
		mov	bx, ss:[fileStrDr]
		call	GeodeFreeDriver			; free filestr driver

		cmp	ax, TE_NO_ERROR
		je	done
exportError:
		mov	ax, TE_EXPORT_ERROR		; error during export
done:
		.leave
		ret
TransExport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPSExportLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform export of a graphics file

CALLED BY:	GLOBAL

PASS:		dx	- block containing options, zero to use default
		si	- gstring handle to source for export
		di	- handle of EPSExportLowStreamStruct
		cx	- GSControl flags (argument passed to GrDrawGString)

RETURN:		ax	- TransError error code
		cx	- return code from GrDrawGString

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		perform the exportation

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPSExportLow	proc	far
		uses	bx, dx, si, di, ds, es
		.enter

		; just quit if the stream block handle is bogus

		tst	di
		jz	errorFileWrite

		; if the Prolog or Setup or PageSetup sections are still open,
		; then close them.

		; first lock down the things we'll need

		push	dx			; save block handle
		push	cx, dx
		mov	bx, dx			; bx = block handle
		call	MemLock			; 
		mov	es, ax			; es -> options block

		mov	bx, handle PSCode	; get ps code resource
		call	MemLock	; lock it down
		mov	ds, ax			; ds -> ps code

		; check to see if Prolog is terminated yet - if not, do it.

		mov	bx, di			; setup stream block handle
		test	es:[PSEB_status], mask PSES_OPEN_PROLOG
		jz	checkPageSetup		;  no, just write trailer

		and	es:[PSEB_status], not mask PSES_OPEN_PROLOG ; clear bit

		; prolog is open -- must be an EPS file.  Just close the prolog
		; and go onto the translation.  There mustn't be multiple pages
		; in this document, since EPSExportBeginPage would have been
		; called (and wasn't since the prolog is still open).

		EmitPS	endProlog		; close the section
		jc	writeError
		jmp	translateString		; go straight to translation

		; prolog wasn't open, but page setup might be.  Check it and
		; close it if it is.  Also, set the default page transform.
checkPageSetup:
		test	es:[PSEB_status], mask PSES_OPEN_PAGE_SETUP
		jz	translateString		;  nope, just translate.
		and	es:[PSEB_status], not mask PSES_OPEN_PAGE_SETUP
		call	EmitEndPageSetup
		jc	writeError

translateString:
		pop	cx, dx			; restore flags, block handle
		call	TranslateGString	; translate it
		mov	cx, ax
		mov	ax, TE_NO_ERROR		; return no error
		cmp	cx, GSRT_FAULT		; see if there was a problem
		jne	unlockResource
		mov	ax, TE_EXPORT_ERROR
unlockResource:
		mov	bx, handle PSCode
		call	MemUnlock		; doesn't affect carry
		pop	bx			; restore option block handle
		call	MemUnlock
done:
		.leave
		ret

		; bogus stream block handle
errorFileWrite:
		mov	ax, TE_EXPORT_ERROR
		jmp	done
		
		; some unfortunate error has occurred..
writeError:
		pop	cx, dx			; restore stack
		mov	ax, TE_EXPORT_ERROR
		mov	cx, GSRT_FAULT
		jmp	unlockResource
EPSExportLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPSExportRaw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	output some data as is to the stream (no conversion)

CALLED BY:	GLOBAL

PASS:		dx	- block containing options, zero to use default
		ds:si	- pointer to buffer containing data to export
		cx	- #bytes to write
		di	- handle of EPSExportLowStreamStruct

RETURN:		ax	- TransError error code
			  (will return either TE_NO_ERROR or TE_EXPORT_ERROR
			   if there was an error from StreamWrite)
		cx	- #bytes written

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just write out the data

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPSExportRaw	proc	far
		uses	bx, dx
		.enter

		; check for bogus stream block handle

		tst	di
		jz	errorFileWrite

		; nothing yet in the options block makes a difference for 
		; this function, so just write it out.

		clr	al			; get errors back
		mov	bx, di
		mov	dx, si			; ds:Dx -> data to write
		call	SendToStream
		mov	ax, TE_NO_ERROR		; assume no errors
		jnc	done
errorFileWrite:
		mov	ax, TE_EXPORT_ERROR
done:
		.leave
		ret
EPSExportRaw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPSExportBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform export of a bitmap

CALLED BY:	GLOBAL

PASS:		dx	- block containing options, zero to use default
		si	- gstate to use to export bitmap
		di	- handle of EPSExportLowStreamStruct
		bx.ax	- Huge bitmap (VMFile.VMBlock)

RETURN:		ax	- TransError error code

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPSExportBitmap	proc	far
		uses	bx, dx, si, di, ds, es
		.enter

		; just quit if the stream block handle is bogus

		tst	di
		jz	errorFileWrite

		; if the Prolog or Setup or PageSetup sections are still open,
		; then close them.

		; first lock down the things we'll need

		push	dx			; save options block handle
		push	ax, bx, dx		; save bitmap, options
		mov	bx, dx			; bx = options block handle
		call	MemLock			; 
		mov	es, ax			; es -> options block

		mov	bx, handle PSCode	; get ps code resource
		call	MemLock			; lock it down
		mov	ds, ax			; ds -> ps code

		; check to see if Prolog is terminated yet - if not, do it.

		mov	bx, di			; setup stream block handle
		test	es:[PSEB_status], mask PSES_OPEN_PROLOG
		jz	checkPageSetup		;  no, just write trailer

		and	es:[PSEB_status], not mask PSES_OPEN_PROLOG ; clear bit

		; prolog is open -- must be an EPS file.  Just close the prolog
		; and go onto the translation.  There mustn't be multiple pages
		; in this document, since EPSExportBeginPage would have been
		; called (and wasn't since the prolog is still open).

		EmitPS	endProlog		; close the section
		jc	writeError
		jmp	translateString		; go straight to translation

		; prolog wasn't open, but page setup might be.  Check it and
		; close it if it is.  Also, set the default page transform.
checkPageSetup:
		test	es:[PSEB_status], mask PSES_OPEN_PAGE_SETUP
		jz	translateString		;  nope, just translate.
		and	es:[PSEB_status], not mask PSES_OPEN_PAGE_SETUP
		call	EmitEndPageSetup
		jc	writeError

translateString:
		pop	ax, bx, dx		; restore bitmap, options

		ornf	es:[PSEB_status], mask PSES_EXPORTING_BITMAP
		call	TranslateBitmap		; translate it
		andnf	es:[PSEB_status], not mask PSES_EXPORTING_BITMAP
unlockResource:
		mov	bx, handle PSCode
		call	MemUnlock		; doesn't affect carry
		pop	bx			; restore option block handle
		call	MemUnlock
done:
		.leave
		ret

		; bogus stream block handle
errorFileWrite:
		mov	ax, TE_EXPORT_ERROR
		jmp	done
		
		; some unfortunate error has occurred..
writeError:
		pop	ax, bx, dx		; restore stack
		mov	ax, TE_EXPORT_ERROR
		jmp	unlockResource
EPSExportBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPSExportTrailer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	output any trailer info

CALLED BY:	GLOBAL

PASS:		dx	- handle of option block, zero to use default
		di	- handle of EPSExportLowStreamStruct

RETURN:		ax	- TransError error code

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		perform the exportation

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPSExportTrailer proc	far
		uses	bx, cx, dx, ds, es
		.enter

		; check for bad stream block handle

		tst	di
		jz	errorFileWrite

		push	dx			; save option block handle
		mov	bx, dx			; lock down options block
		call	MemLock			; lock it 
		mov	es, ax			; es -> options block
		mov	bx, handle PSCode	; lock down resource
		call	MemLock
		mov	ds, ax			; ds -> PSCode

		; first check to see if the prolog is still open -- like
		; we didn't export anything

		mov	bx, di			; setup stream block handle
		test	es:[PSEB_status], mask PSES_OPEN_PROLOG
		jz	writeTrailer		;  no, just write trailer

		; close Prolog section

		EmitPS	endProlog
		jc	unlockResource

		; write a different trailer for EPS vs printer files
writeTrailer:
		test	es:[PSEO_flags], mask PSEF_EPS_FILE
		jnz	writeEPSTrailer		; endit with a ^D
		EmitPS	printTrailer
unlockResource:
		mov	bx, handle PSCode
		call	MemUnlock		; doesn't affect carry
		pop	bx			; restore option block handle
		call	MemUnlock
		
		mov	ax, TE_NO_ERROR		; assume everything OK
		jnc	done
errorFileWrite:
		mov	ax, TE_EXPORT_ERROR
done:
		.leave
		ret

writeEPSTrailer:
		EmitPS	epsTrailer		; put %%EOF instead of ^D
		jmp	unlockResource
EPSExportTrailer endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPSExportBeginPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do any page-starting calculations

CALLED BY:	GLOBAL

PASS:		dx	- handle of option block, zero to use default
		di	- handle of EPSExportLowStreamStruct

RETURN:		ax	- TransError error code
			  TE_NO_MULITPLE_PAGE_DOCS if format does not 
			  support multiple pages

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		perform any page-boundary calculations/exports.

		this function leaves the PageSetup section open.  It is closed
		by the TransExport function or the EPSExportEndPage function,
		This allows the caller to insert other code in the page setup
		portion of the file (such as default page transforms)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPSExportBeginPage proc	far
		uses	dx, bx, cx, dx, si, di, es, ds
		.enter

		; check for bogus stream block handle

		tst	di
		jz	fileError

		; first lock down the things we'll need

		push	dx			; save block handle
		mov	bx, dx			; bx = block handle
		call	MemLock			; 
		mov	es, ax			; es -> options block

		mov	bx, handle PSCode	; get ps code resource
		call	MemLock	; lock it down
		mov	ds, ax			; ds -> ps code

		; check to see if Prolog is terminated yet - if not, do it.

		mov	bx, di			; setup stream block handle
		test	es:[PSEB_status], mask PSES_OPEN_PROLOG
		jz	writeBeginPage		;  no, just write trailer

		and	es:[PSEB_status], not mask PSES_OPEN_PROLOG ; clear bit
		call	EmitDocSetup		; write out document setup stuff
		jc	unlockResource

		; done with preliminaries, start off the page
writeBeginPage:
		call	EmitPageSetup		; carry set from this routine
		or	es:[PSEB_status], mask PSES_OPEN_PAGE_SETUP

unlockResource:
		mov	bx, handle PSCode	; release resource
		call	MemUnlock
		pop	bx			; restore options block handle
		call	MemUnlock		; release options block
		mov	ax, TE_NO_ERROR
done:
		.leave
		ret

fileError:
		mov	ax, TE_EXPORT_ERROR
		jmp	done
EPSExportBeginPage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPSExportEndPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do any page-ending calculations

CALLED BY:	GLOBAL

PASS:		dx	- handle of option block, zero to use default
		di	- handle of EPSExportLowStreamStruct

RETURN:		ax	- TransError error code
			  TE_NO_MULITPLE_PAGE_DOCS if format does not 
			  support multiple pages

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		perform any page-boundary calculations/exports.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPSExportEndPage proc	far
		uses	dx, bx, cx, dx, si, di, es, ds
		.enter

		; check for bogus stream block handle

		tst	di
		LONG jz	fileError

		; first lock down the things we'll need

		push	dx			; save block handle
		mov	bx, dx			; bx = block handle
		call	MemLock			; 
		mov	es, ax			; es -> options block

		mov	bx, handle PSCode	; get ps code resource
		call	MemLock			; lock it down
		mov	ds, ax			; ds -> ps code

		; do some bookeeping

		mov	bx, di			; bx = stream block handle
		inc	es:[PSEB_curPage]	; bump the page number
		test	es:[PSEB_status], mask PSES_OPEN_PAGE_SETUP
		jz	writeEndPage		; if not open, just finish page
		and	es:[PSEB_status], not mask PSES_OPEN_PAGE_SETUP
		EmitPS	endPageSetup
		jc	unlockResource
writeEndPage:
		EmitPS	emitEP			; write out EndPage
		jc	unlockResource
		EmitPS	emitEndDict		; write out EndPage
		jc	unlockResource
		EmitPS	emitRestore		; write out EndPage
		jc	unlockResource
		EmitPS	pageTrailer		; write out %%PageTrailer
unlockResource:
		mov	bx, handle PSCode	; release resource
		call	MemUnlock
		pop	bx			; restore options block handle
		call	MemUnlock		; release options block
		mov	ax, TE_NO_ERROR
done:
		.leave
		ret

fileError:
		mov	ax, TE_EXPORT_ERROR
		jmp	done
EPSExportEndPage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPSNormalizeFilename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the filename set in the options block and change it
		if it is non-conforming.

CALLED BY:	GLOBAL

PASS:		dx	- handle of option block, zero to use default

RETURN:		ax	- TransError error code

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		check to make sure the file is a ".ps" file for non-EPS
		file and a ".eps" file for real EPS files.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This function does not check for a valid DOS-compatible name.
		It merely checks the last few characters of the string.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPSNormalizeFilename proc	far
		uses	bx, es, di
		.enter

		; lock down the block

		mov	bx, dx
		call	MemLock			; lock the block
		mov	es, ax			; es -> options block

		; scan for a terminating zero, then back up to the "."
		; if we have to back up more than three chars, assume
		; that there is no extension yet (and add one).

		clr	al
		mov	di, offset GEO_fileName ; es:di -> name
		mov	cx, length GEO_fileName	; cx = length of field
		repne	scasb			; es:di -> after zero
		dec	di			; es:di -> zero
		dec	di			; check last non-zero char
		cmp	{byte} es:[di], '.'	; found dot yet ?
		je	foundDot		;  yes, continue
		dec	di			; backup pointer
		cmp	{byte} es:[di], '.'	; found dot yet ?
		je	foundDot		;  yes, continue
		dec	di			; backup pointer
		cmp	{byte} es:[di], '.'	; found dot yet ?
		je	foundDot		;  yes, continue
		dec	di			; backup pointer
		cmp	{byte} es:[di], '.'	; found dot yet ?
		je	foundDot		;  yes, continue
		mov	{byte} es:[di+4], '.'	; add a dot
		add	di, 4			; es:di -> dot

		; OK, we found the dot.  es:di -> dot.  Check for an eps file
foundDot:
		test	es:[PSEO_flags], mask PSEF_EPS_FILE ; is it eps ?
		jnz	checkValidEPS		;  yes, do it

		; don't have an EPS file.  Just check for es:di -> "ps" and
		; add it if it doesn't.

		cmp	{byte} es:[di+1], 'p'	; check for valid extension
		jne	forcePS
		cmp	{byte} es:[di+2], 's'	; keep checking
		je	haveFilename
forcePS:
		mov	{byte} es:[di+1], 'P'	; force extension to .PS
		mov	{byte} es:[di+2], 'S'
		mov	{byte} es:[di+3], 0	; terminate string
		
		; It's an EPS file.  if it has a preview, we want to name
		; it EPI
checkValidEPS:
		test	es:[PSEO_flags], mask PSEF_INCLUDE_PREVIEW ; preview ?
		jnz	check_epi
		cmp	{byte} es:[di+1], 'e'	; check for valid extension
		jne	forceEPS
		cmp	{byte} es:[di+1], 'p'	; check for valid extension
		jne	forceEPS
		cmp	{byte} es:[di+1], 's'	; check for valid extension
		je	haveFilename
forceEPS:
		mov	{byte} es:[di+1], 'E'	; set it to EPS
		mov	{byte} es:[di+2], 'P'
		mov	{byte} es:[di+3], 'S'
		mov	{byte} es:[di+4], 0
		jmp	haveFilename

		; check for EPI
check_epi:
		cmp	{byte} es:[di+3], 'e'	; check for valid extension
		jne	forceEPI
		cmp	{byte} es:[di+2], 'p'	; check for valid extension
		jne	forceEPI
		cmp	{byte} es:[di+2], 'i'
		je	haveFilename		; shortstop -- fix it now
forceEPI:
		mov	{byte} es:[di+1], 'E'
		mov	{byte} es:[di+2], 'P'
		mov	{byte} es:[di+3], 'I'
		mov	{byte} es:[di+4], 0
haveFilename:
		mov	bx, dx
		call	MemUnlock		; release options block
		.leave
		ret
EPSNormalizeFilename endp

ExportCode	ends
