COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CSV/Expot		
FILE:		exportFile.asm

AUTHOR:		Ted H. Kim, 3/30/92

ROUTINES:
	Name			Description
	----			-----------
	TransExport		Library routine called by Impex
	FileExportComma		Export a file into CSV format
	WriteExportRecord	Writes out a record to output file 
	WriteTextField		Writes out one text field to output file
	CheckForQuoteAndComma	Scans the given string for comma and quote
	WriteOutCRAndLF, WriteOutComma, WriteOutQuote
				Writes out various strings
	WriteOutOneChar		Writes out one character
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial revision

DESCRIPTION:
	Contains all of file export routines.

	$Id: exportFile.asm,v 1.1 97/04/07 11:42:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Export	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Library routine called by Impex

CALLED BY:	Impex

PASS:		ds:si - ExportFrame

RETURN:		ax - TransError 

DESTROYED:	bx, cx, dx, si, di, bp, es, ds

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransExport	proc	far
	TE_Local	local	ImpexStackFrame
	TE_SSMeta	local	SSMetaStruc

	.enter

	; check to see if there was an error
	mov	ax, TE_EXPORT_INVALID_CLIPBOARD_FORMAT	; just in case...
	cmp	ds:[si].EF_clipboardFormat, CIF_SPREADSHEET
	jne	quit
	cmp	ds:[si].EF_manufacturerID, MANUFACTURER_ID_GEOWORKS
	jne	quit

	mov	ax, ds:[si].EF_transferVMChain.low	
	or	ax, ds:[si].EF_transferVMChain.high
	jne	noError				; skip if no error

	mov	ax, TE_EXPORT_FILE_EMPTY	; ax - TransError
	jmp	quit
noError:
	; set up the output file for writing

	mov	bx, ds:[si].EF_outputFile	; bx - handle of output file
	call	OutputCacheAttach		; create output cache block
	mov	ax, TE_OUT_OF_MEMORY		; ax - TransError
	jc	quit				; exit if error
	mov	TE_Local.ISF_cacheBlock, bx	; save handle of cache block 

	; get the handle of map entry block from the stack frame

	mov	bx, ds:[si].EF_exportOptions	; bx - map list block
	mov	TE_Local.ISF_mapBlock, bx	; save it

	; initialize the stack frame for file exporting

	mov	bx, ds:[si].EF_transferVMFile	; bx - VM file handle
	mov	ax, ds:[si].EF_transferVMChain.high	; ax - VM block handle 
	push	bp
	mov	dx, ss
	lea	bp, TE_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaInitForRetrieval	
	pop	bp

	; now grab the number of records and fields from the transfer file

	mov	ax, TE_SSMeta.SSMDAS_scrapRows	
	mov	TE_Local.ISF_numRecords, ax	; ax - number of records
	mov	ax, TE_SSMeta.SSMDAS_scrapCols	
	mov	TE_Local.ISF_numSourceFields, ax; ax - number of fields

	; convert to CSV

	call	FileExportComma
	jnc	skip				; skip if no error

	; destroy the cache block before exiting

	mov	bx, TE_Local.ISF_cacheBlock	; bx - handle of cache block 
	call	OutputCacheFlush		; flush out the buffer
	call	OutputCacheDestroy		; destroy cache block
	jmp	error
skip:
	; clean up the cached block

	mov	bx, TE_Local.ISF_cacheBlock	; bx - handle of cache block 
	call	OutputCacheFlush		; flush out the buffer
	jc	error				; exit if error
	call	OutputCacheDestroy		; destroy cache block
	mov	ax, TE_NO_ERROR			; return with no error
	jmp	quit
error:
	mov	ax, TE_FILE_ERROR		; return with error
quit:
	.leave
	ret
TransExport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileExportComma
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exports transfer VM file into CSV (Comma Separated Value)
		format.

CALLED BY:	TransExport

PASS:		nothing

RETURN:		carry set if there was a file error

DESTROYED:	ax, bx, cx, dx, di, es

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
	crAndLF		word	CR, LF, 0
	endOF		word	26, 0
else
	crAndLF		byte	CR, LF, 0
	endOF		byte	26, 0
endif
FileExportComma	proc	near		uses	ds, si, bp
	FEC_Local	local	ImpexStackFrame
	FEC_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	tst	FEC_Local.ISF_mapBlock		; is there a map block?	
	jne	mapBlk				; if there is, skip

	call	WriteExportFile			; export the meta file
	jc	error				; exit if error
	jmp	quit
mapBlk:
	clr	cx				; cx - record number counter
mainLoop:
	call	WriteExportRecord		; write out a record
	jc	error
	call	WriteOutCRAndLF			; write out CR and LF
	jc	error				; exit if error
	inc	cx
	cmp	cx, FEC_Local.ISF_numRecords	; are we done?
	jne	mainLoop			; continue if not done
quit:
	call	WriteOutEndOfFile		; write out EOF character
	clc					; exit with no error
error:
	.leave
	ret
FileExportComma	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteExportFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Export the meta file.

CALLED BY:	(INTERNAL) FileExportComma

PASS:		nothing		

RETURN:		carry set if there was an error

DESTROYED:	ax, bx, cx, dx, si	

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	2/1/93		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteExportFile		proc	near
	WEF_Local	local	ImpexStackFrame
	WEF_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	clr	WEF_Local.ISF_colNumber		; initialize column number
	clr	WEF_Local.ISF_rowNumber		; and row number
	mov	WEF_Local.ISF_endOfFile, FALSE

	; make it point to the beginning of DAS_CELL array

	mov	WEF_SSMeta.SSMDAS_dataArraySpecifier, DAS_CELL
	push	bp
	mov	dx, ss
	lea	bp, WEF_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaDataArrayResetEntryPointer
	pop	bp
fieldLoop:
	; now get an element from the CELL huge array

	push	bp
	mov	dx, ss
	lea	bp, WEF_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaDataArrayGetNextEntry	
	pop	bp
	jnc	locked				; skip if end of data chain

	; end of data chain, set end of file flag and jump

	mov	WEF_Local.ISF_endOfFile, TRUE
	jmp	checkRec
locked:
	; check to see if this field data belongs to the next record

	mov	bx, WEF_Local.ISF_rowNumber	; bx - row number
	cmp	bx, ds:[si].SSME_coordRow
	je	skip				; if not, skip
	ja	fieldLoop			; bogus cell data - get next

checkRec:
	mov	bx, WEF_Local.ISF_colNumber
	cmp	bx, WEF_Local.ISF_numSourceFields
	je	endOfRec

	tst	WEF_Local.ISF_colNumber
	je	cellOne				; don't add a comma if 1st cell
	call	WriteOutComma			; create an empty field 	
	jc	error				; exit if error
cellOne:
	inc	WEF_Local.ISF_colNumber		; update column number
	jmp	checkRec

	; we are at the end of the record, write out CR and LF
endOfRec:
	call	WriteOutCRAndLF			
	jc	error				; exit if error

	tst	WEF_Local.ISF_endOfFile		; end of data chain? 
	jne	done				; if so, exit

	inc	WEF_Local.ISF_rowNumber		; update row number
	clr     WEF_Local.ISF_colNumber
	jmp	locked
skip:
	mov	bx, WEF_Local.ISF_colNumber	; bx - current column number
	cmp	bx, ds:[si].SSME_coordCol	; dx - column number
	je	formatCell
	ja	fieldLoop			; bogus cell data - get next

	; write out commas to indicate blank cells between non-empty fields

	tst	WEF_Local.ISF_colNumber
	je	firstCell			; don't add a comma if 1st cell
	call	WriteOutComma			; create an empty field 	
	jc	error				; exit if error
firstCell:
	inc	WEF_Local.ISF_colNumber		; update column number
	jmp	skip

formatCell:
	; there is data, we need to format this data.

	push	bp
	mov	dx, ss 				; dx:bp - SSMetaStruc
	lea	bp, WEF_SSMeta
	call	SSMetaFormatCellText		; ds:si <- ptr to text
	pop	bp				; ax <- size of text
	jnc	notEmpty 			; bx <- block (if any)

	; empty (or error) field, handle it

	tst	WEF_Local.ISF_colNumber
	je	emptyField
	call	WriteOutComma			; create an empty field 	
	jc	error				; exit if error
	jmp	emptyField

	; write out a CSV field to the output file
notEmpty:
	tst	WEF_Local.ISF_colNumber
	je	firstField
	call	WriteOutComma			; create an empty field 	
	jc	error				; exit if error
firstField:
	call	WriteTextField			; write out a text field
	jc	error

	; free the data block created by SSMetaFormatCellText if exists
emptyField:
	inc     WEF_Local.ISF_colNumber		; update the column number
	tst	bx
	LONG	je	fieldLoop
	call	MemFree
	jmp	fieldLoop
done:
	push	bp
	mov	dx, ss
	lea	bp, WEF_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaDataArrayUnlock		; unlock the data chain
	pop	bp
	clc
error:
	.leave
	ret
WriteExportFile		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteExportRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out one record to output file.

CALLED BY:	FileExportComma

PASS:		ds:si - pointer to the field data 
		es - segment address of dgroup
		cx - current row number

RETURN:		carry set if there was a file error

DESTROYED:	ax, cx, dx, si

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
	comma		wchar	',', 0
	quote		wchar	'"', 0
else
	comma		char	',', 0
	quote		char	'"', 0
endif
WriteExportRecord	proc	near	uses	cx
	WER_Local	local	ImpexStackFrame
	WER_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	mov	WER_Local.ISF_curField, 0	; initialize column number
	mov	WER_SSMeta.SSMDAS_row, cx	; cx - row number
mainLoop:
	; get true column number after the field has been mapped

        mov     ax, WER_Local.ISF_curField	; ax - column number
	mov	bx, WER_Local.ISF_mapBlock	; bx - handle of map block
	mov	cl, mask IF_EXPORT		; do export
	call	GetMappedRowAndColNumber	; returns - ax = map col num
	jnc	notMapped			; skip if not mapped

	; now get an element from the CELL huge array

	mov	WER_SSMeta.SSMDAS_dataArraySpecifier, DAS_CELL
	mov	WER_SSMeta.SSMDAS_col, ax	; ax - column number
	push	bp
	mov	dx, ss
	lea	bp, WER_SSMeta			; dx:bp - SSMetaStruc
	clr     bx                              ; Assume no data
	call	SSMetaDataArrayGetEntryByCoord  ; ds:si <- ptr to data
						; cx <- size
	pop	bp
	jc	empty 				; branch if there is no data

	; There is data, we need to either reset our pointer, 
	; or else format the data to a block which we allocate.

	push	bp, dx, es, di
	mov	dx, ss
	lea	bp, WER_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaFormatCellText		; ds:si <- ptr to text
	pop	bp, dx, es, di			; ax <- size of text
						; bx <- block (if any)
	jnc	writeField			; skip if no error
	clc
	jmp	unlock				; skip if empty

	; write out a CSV field to the output file
writeField:
	call	WriteTextField			; write out a text field

	; unlock the huge array block
unlock:
	pushf					; save the flags
	push	bp
	mov	dx, ss
	lea	bp, WER_SSMeta			; dx:bp - SSMetaStruc
	call	SSMetaDataRecordFieldUnlock
	pop	bp
	popf					; restore the flags
	jc	error				; exit if error

	; check to see if this is the last field of this record
empty:
	inc	WER_Local.ISF_curField
	mov	dx, WER_Local.ISF_curField 
	cmp	dx, WER_Local.ISF_numSourceFields ; are we done?
	je	exit				; if so, exit

	; the following check is done to avoid the case where the last field
	; of the record is not mapped and you end up with an extraneous comma
next:
        mov     ax, dx				; ax - column number
	mov	bx, WER_Local.ISF_mapBlock	; bx - handle of map block
	mov     cl, mask IF_EXPORT 		; do export
	call	GetMappedRowAndColNumber	; returns - ax = map col num
	jc	writeComma			; skip, if mapped 

	; if not mapped, continue checking until there is a mapped field

	inc	dx
	cmp	dx, WER_Local.ISF_numSourceFields ; are we done?
	jne	next				; if not, continue
	jmp	exit

	; write out comma as a field delimiter
writeComma:
	call	WriteOutComma			; create an empty field 	
	jc	error				; exit if error
	jmp	mainLoop			; continue ...

	; don't do anything if the field has not been mapped
notMapped:
	inc	WER_Local.ISF_curField
	mov	dx, WER_Local.ISF_curField 
	cmp	dx, WER_Local.ISF_numSourceFields ; are we done?
	LONG	jne	mainLoop		; if not, continue
exit:
	clc					; exit with no error
error:
	.leave
	ret
WriteExportRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteTextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a text field data to output file.

CALLED BY:	WriteExportRecord

PASS:		ds:si - fptr to the text of field data
		es - segment address of dgroup

RETURN:		carry set if there was a file error	

DESTROYED:	ax, dx, si 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version
	mevissen 3/99		Handle leading single quotes in field

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteTextField	proc	near		uses	bx, cx, bp
	WTE_Local	local	ImpexStackFrame
	WTE_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	; if a leading ', quote the rest of the (text) field automatically
	;				mevissen, 3/99

	LocalGetChar	ax, dssi	; read in first character
	LocalCmpChar	ax, '\''	; is it a single quote?
	je		doQuotedString	; yes, quote rest of string

	LocalPrevChar	dssi		; restore ptr to string start
	call	CheckForQuoteAndComma	; check for comma or quote
	tst	WTE_Local.ISF_quoteFlag	; was there one?
	je	copy			; copy the string if there was none

doQuotedString:
	call	WriteOutQuote		; add open quote
	jc	exit			; exit if error
mainLoop:
	LocalGetChar	ax, dssi	; read in a character
	LocalIsNull	ax		; end of data?
	je	closeQuote		; if so, add right quote

	LocalCmpChar	ax, '"'		; is quote part of field data?
	jne	notQuote		; if not, skip

	call	WriteOutOneChar		; if so, add " as an escape char
	jc	exit			; exit if error
notQuote:
	call	WriteOutOneChar		; store the quote as part of data
	jc	exit			; exit if error
	jmp	mainLoop		; check the next character
closeQuote:
	call	WriteOutQuote		; add close quote
	jmp	exit
copy:
	mov	dx, si			; ds:dx - fptr to string
        mov	bx, WTE_Local.ISF_cacheBlock	; bx - handle of cache block
	call	OutputCacheWrite	; write out the empty field
exit:
	.leave
	ret
WriteTextField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForQuoteAndComma
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scans the string for a double-quote, a comma, or a
		carriage return.  

CALLED BY:	WriteTextField

PASS:		es - segment address of dgroup
		ds:si - ptr to string to scan

RETURN:		quoteFlag
		cx - number of chars in the string 
		(invalid if quoteFlag is set TRUE) 
			
DESTROYED:	ax

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForQuoteAndComma	proc	near
	uses	si

CFQAC_Local	local	ImpexStackFrame
CFQAC_SSMeta	local	SSMetaStruc

	.enter	inherit	near

	clr	cx			; cx - # of chars in string
	mov	CFQAC_Local.ISF_quoteFlag, FALSE ; assume no quote or comma

mainLoop:
	LocalGetChar	ax, dssi
	LocalIsNull	ax		; end of string?
	jz	exit			; exit if so
SBCS <	LocalCmpChar	ax, C_QUOTE				>
DBCS <	LocalCmpChar	ax, C_QUOTATION_MARK			>
	je	found
	LocalCmpChar	ax, C_COMMA
	je	found
	LocalCmpChar	ax, C_ENTER
	je	found

	inc	cx			; up the counter
	jmp	mainLoop		; check the next character
found:
	mov	CFQAC_Local.ISF_quoteFlag, TRUE	; set the flag	
exit:
	.leave
	ret
CheckForQuoteAndComma	endp

WriteOutCRAndLF	proc	near	uses	ds, cx, bp
	WOCRALF_Local	local	ImpexStackFrame
	WOCRALF_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	segmov	ds, cs
	mov	dx, offset crAndLF		; ds:dx - fptr to string
	mov	cx, 2				; cx - # of chars to write out
        mov	bx, WOCRALF_Local.ISF_cacheBlock; bx - handle of cache block
	call	OutputCacheWrite		; write out these two chars

	.leave
	ret
WriteOutCRAndLF	endp

WriteOutEndOfFile	proc	near	uses	ds, cx, bp
	WOEOF_Local	local	ImpexStackFrame
	WOEOF_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	segmov	ds, cs
	mov	dx, offset endOF		; ds:dx - fptr to string
	mov	cx, 1				; cx - # of chars to write out
        mov	bx, WOEOF_Local.ISF_cacheBlock	; bx - handle of cache block
	call	OutputCacheWrite		; write out these two chars

	.leave
	ret
WriteOutEndOfFile	endp

WriteOutOneChar	proc	near	
	WOOC_Local	local	ImpexStackFrame
	WOOC_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	mov	dx, si			; ds:dx - fptr to string

	; go back one space since ds:si is already pointing to the next char

	dec	dx
DBCS <	dec	dx				; go back full word	>
	mov	cx, 1				; cx - # of chars to write out
        mov	bx, WOOC_Local.ISF_cacheBlock	; bx - handle of cache block
	call	OutputCacheWrite		; write out '"'

	.leave
	ret
WriteOutOneChar	endp
	
WriteOutQuote	proc	near	uses	ds
	WOO_Local	local	ImpexStackFrame
	WOO_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	segmov	ds, cs
	mov	dx, offset quote	; ds:dx - fptr to string
	mov	cx, 1			; cx - # of chars to write out
        mov	bx, WOO_Local.ISF_cacheBlock	; bx - handle of cache block
	call	OutputCacheWrite	; write out '"'

	.leave
	ret
WriteOutQuote	endp

WriteOutComma	proc	near	uses	bx, dx, ds, bp
	WOC_Local	local	ImpexStackFrame
	WOC_SSMeta	local	SSMetaStruc
	.enter	inherit	near

	segmov	ds, cs
	mov	dx, offset comma	; ds:dx - fptr to string
	mov	cx, 1			; cx - # of chars to write out
        mov	bx, WOC_Local.ISF_cacheBlock	; bx - handle of cache block
	call	OutputCacheWrite	; write out comma

	.leave
	ret
WriteOutComma	endp

Export	ends
