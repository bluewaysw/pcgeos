COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Translation Library
FILE:		exportHeader.asm

AUTHOR:		Jim DeFrisco, 5 March 1991

ROUTINES:
	Name			Description
	----			-----------
	EmitHeaderComments	write out postscript header comments

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/91		Initial revision


DESCRIPTION:
	This contains some support routines for TransExportHeader
		

	$Id: exportHeader.asm,v 1.1 97/04/07 11:25:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitHeaderComments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the header comment strings

CALLED BY:	INTERNAL
		TransExportHeader

PASS:		ds	- pointer to locked PSCode resource
		es	- pointer to locked options block
		di	- handle of EPSExportLowStreamStruct

RETURN:		carry	- set if some error from StreamWrite
			  (ax = error code in that case)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		copy comments from PSCode resource, insert arguments when
		necessary

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitHeaderComments	proc	near
		uses	bx, cx, dx, di
		.enter

		; the first thing to output is the !PS comment

		mov	bx, di				; bx = stream block
		clr	al				; handle errors
		mov	dx, offset printFileID		; %!PS-Adobe-3.0
		mov	cx, length printFileID
		test	es:[PSEO_flags], mask PSEF_EPS_FILE
		jz	writeLine1			;  no, print file
		mov	dx, offset epsFileID		;  yes, EPS file
		mov	cx, length epsFileID
writeLine1:
		call	SendToStream
		LONG jc	done				; handle errors

		; write out the %%BoundingBox line

		call	EmitBoundingBox
		LONG jc	done	

		; put the the %%Creator line

		EmitPS	creatorComment
		LONG jc	done	

		push	ds				; copy from option blk
		clr	al
		segmov	ds, es, dx
		mov	dx, offset GEO_appName		; copy creator
		call	CalcStringLength		; cx = length of string
		call	SendToStream
		pop	ds
		LONG jc	done	

		EmitPS	emitCRLF
		jc	done

		; put in the %%CreationDate line

		call	EmitCreationDate		; what is today ?
		jc	done	

		; put in the %%DocumentData line

		EmitPS	docData
		jc	done	
		call	EmitPageInfo			; emit #pages...
		jc	done	
;		EmitPS	emitCRLF  				; PageInfo already does it -> DSC error
;		jc	done	

		; put in the %%Extensions and %%LanguageLevel if needed

		mov	ax, es:[PSEO_level]		; get extensions/level
		cmp	ax, 1				; if level 1, done
		jne	checkLevel

		; put the the %%Title line
putTitle:
		EmitPS	titleComment
		jc	done	

		push	ds				; copy from option blk
		clr	al
		segmov	ds, es, dx
		mov	dx, offset GEO_docName		; copy creator
		call	CalcStringLength		; cx = length of string
		call	SendToStream
		pop	ds
		jc	done
		EmitPS	emitCRLF
		jc	done

		; put the %%EndComments line

		EmitPS	endComments
done:
		.leave
		ret

		; either we're level 2, or there are extensions.
checkLevel:
		cmp	al, 1				; check for level 2
		je	checkExtensions
		EmitPS	level2				; write out level 2
		jmp	putTitle

		; level 1, there must be extensions
checkExtensions:
		push	ax
		EmitPS	extensionKey			; write out keyword
		pop	ax
		test	ax, mask PSL_CMYK		; check for color
		jz	checkDPS			;  no, check Disp PS
		push	ax
		EmitPS	cmykSupport
		pop	ax
checkDPS:
		test	ax, mask PSL_DPS		; Display PostScript ?
		jz	checkComposite
		push	ax
		EmitPS	dpsSupport
		pop	ax
checkComposite:
		test	ax, mask PSL_COMPOSITE		; composite fonts ?
		jz	checkFile			;  nope, done
		push	ax
		EmitPS	compositeSupport
		pop	ax
checkFile:
		test	ax, mask PSL_FILE		; file system support ?
		jz	putExtCR			;  nope, done
		push	ax
		EmitPS	fileSupport
		pop	ax
putExtCR:
		EmitPS	emitCRLF
		jmp	putTitle
EmitHeaderComments	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitPageInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the #pages, page order, etc.

CALLED BY:	INTERNAL
		EmitHeaderComments

PASS:		ds	- points to locked PSCode resource
		es	- points to locked options block
		bx	- handle of EPSExportLowStreamStruct

RETURN:		carry	- set if problem in StreamWrite
		ax	- if carry set, ax = error code

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		write out the %%BoundingBox: comment

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitPageInfo	proc	near
		uses	cx, dx, di, si
scratchBuffer	local	40 dup(char)
		.enter

		; put in %%Pages

		EmitPS	numPages
		LONG jc	done

		mov	si, bx				; save stream block
		mov	bx, es:[GEO_pages]		; get num pages
		push	ds, es
		segmov	es, ss, di
		lea	di, scratchBuffer		; es:di -> scratch space
		call	UWordToAscii			; convert #pages
		mov	al, C_CR			; finish off the line
		mov	ah, C_LF			; output CRLF
		stosw
		clr	al
		mov	cx, di				; cx = current pos
		lea	dx, scratchBuffer		; compute length
		sub	cx, dx				; cx = length
		segmov	ds, ss, di			; ds -> stack
		mov	bx, si
		call	SendToStream			; write out the coords
		pop	ds, es
		jc	done

		; put in %%PageOrder, but only if there is more than one page

		cmp	es:[GEO_pages], 1		; more than 1 page ?
		jbe	setCopies			;  no, check copies
		mov	dx, offset ascendOrder		; assume ascending
		mov	cx, length ascendOrder
		test	es:[GEO_flags], mask GEF_PAGES_DESCENDING
		jz	setPageDirection
		mov	dx, offset descendOrder		; assume ascending
		mov	cx, length descendOrder
setPageDirection:
		clr	al
		call	SendToStream
		jc	done

		; put in %%Requirements comment for #copies, collate...
setCopies:
		cmp	es:[GEO_copies], 1		; only need this if
		jbe	doneOK				;  more than 1 copy
		EmitPS	requirements
		jc	done
		mov	bx, es:[GEO_copies]		; get #copies
		push	es, ds
		segmov	es, ss, di
		lea	di, scratchBuffer		; es:di -> buffer
		call	UWordToAscii			; create string
		mov	al, ')'				; closing paren
		stosb
		clr	al
		mov	cx, di				; cx = current pos
		lea	dx, scratchBuffer		; compute length
		sub	cx, dx				; cx = length
		segmov	ds, ss, di			; ds -> stack
		mov	bx, si				; restore stream block
		call	SendToStream			; write out the coords
		pop	es, ds
		jc	done
		test	es:[GEO_flags], mask GEF_COLLATE ; check for collate
		jz	writeFinalCR
		EmitPS	reqCollate
done:
		.leave
		ret

		; no collate flag, so end line with a carriage return
writeFinalCR:
		push	es
		segmov	es, ss, dx
		lea	dx, scratchBuffer
		mov	es:[scratchBuffer], C_CR
		mov	es:[scratchBuffer+1], C_LF
		mov	cx, 2
		clr	al
		call	SendToStream
		pop	es
		jmp	done
doneOK:
		clc					; no error
		jmp	done
EmitPageInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitBoundingBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the bounding box comment line

CALLED BY:	INTERNAL
		EmitHeaderComments

PASS:		ds	- points to locked PSCode resource
		es	- points to locked options block
		bx	- handle of EPSExportLowStreamStruct

RETURN:		carry	- set if problem in StreamWrite
		ax	- if carry set, ax = error code

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		write out the %%BoundingBox: comment

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitBoundingBox	proc	near
		uses	bx, cx, dx
scratchBuffer	local	40 dup(char)
		.enter

		; write out the bounding box.  Use (0,0) for the lower left
		; and (width,height) for the upper right.

		EmitPS	boundBox
		jc	done

		; convert the bounding box coords to ascii to output

		push	ds, es, bx
		push	bx				; save stream block
		pushdw	es:[GEO_docH]
		movdw	cxbx, es:[GEO_docW]		; grab width
		segmov	es, ss, di
		lea	di, scratchBuffer		; es:di -> buffer
		mov	al, '0'				; setup to write 0
		mov	ah, ' '
		stosw
		stosw					; "0 0 " written
		call	SDWordToAscii			; convert width
		mov	al, ' '				; space separated
		stosb
		popdw	cxbx				; now do height
		call	SDWordToAscii
		mov	al, C_CR			; finish off the line
		mov	ah, C_LF			; output CRLF
		stosw
		clr	al
		mov	cx, di				; cx = current pos
		lea	dx, scratchBuffer		; compute length
		sub	cx, dx				; cx = length
		segmov	ds, ss, di			; ds -> stack
		pop	bx				; restore stream block
		call	SendToStream			; write out the coords
		pop	ds, es, bx
done:
		.leave
		ret
EmitBoundingBox	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitCreationDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the creation date comment line

CALLED BY:	INTERNAL
		EmitHeaderComments

PASS:		ds	- points to locked PSCode resource
		es	- points to locked options block
		bx	- handle of EPSExportLowStreamStruct

RETURN:		carry	- set if problem in StreamWrite
		ax	- if carry set, ax = error code

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		write out the %%CreationDate: comment

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitCreationDate proc	near
		uses	cx, dx
scratchBuffer	local	40 dup(char)
		.enter

		EmitPS	creationDate
		jc	done

		push	ds, es
		push	bx				; save stream block
		call	TimerGetDateAndTime		; get the date
		mov	cl, bh				; save day
		clr	bh
		clr	ch
		mov	dx, ax				; save year
		segmov	es, ss, di
		lea	di, scratchBuffer
		call	UWordToAscii			; write month
		mov	al, '/'
		stosb
		mov	bx, cx				; prepare day
		call	UWordToAscii
		stosb
		sub	dx, 1900			; assume 1900-1999
		cmp	dx, 100				; see if OK
		jb	doYear
		sub	dx, 100				; surely before 2099
							;  anyway, I'll be long
doYear:							;  dead before this is
		mov	bx, dx				;  a bug :)
		call	UWordToAscii
		mov	al, C_CR			; finish off the line
		mov	ah, C_LF			; output CRLF
		stosw
		clr	al
		mov	cx, di				; cx = current pos
		lea	dx, scratchBuffer		; compute length
		sub	cx, dx				; cx = length
		segmov	ds, ss, di			; ds -> stack
		pop	bx
		call	SendToStream			; write out the coords
		pop	ds, es
done:
		.leave
		ret
EmitCreationDate endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitDocSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write document setup section

CALLED BY:	INTERNAL
		TransExportBeginPage

PASS:		ds	- points to locked PSCode resource
		es	- points to locked options block
		bx	- handle of EPSExportLowStreamStruct

RETURN:		carry	- set if some error from StreamWrite
				(ax holds error code)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		write out #copies...

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitDocSetup	proc	near
		uses	bx, cx, dx
scratchBuffer	local	20 dup(char)
		.enter

		; close Prolog section, start page setup section

		clr	al				; handle errors
		mov	dx, offset endProlog
		mov	cx, length endProlog + length beginSetup
		call	SendToStream			; write out prolog
		jc	done

		; write out #copies...

		EmitPS	emitNC				; write out "/#copies "
		mov	si, bx				; save stream block
		mov	bx, es:[GEO_copies]		; get #copies
		push	es, ds
		segmov	es, ss, di
		lea	di, scratchBuffer		; es:di -> buffer
		call	UWordToAscii			; create string
		clr	al
		mov	cx, di				; cx = current pos
		lea	dx, scratchBuffer		; compute length
		sub	cx, dx				; cx = length
		segmov	ds, ss, di			; ds -> stack
		mov	bx, si				; restore stream block
		call	SendToStream			; write out the coords
		pop	es, ds
		jc	done
		EmitPS	emitDef
		jc	done

		; Write out paper size setting, if needed.  We only check
		; the paper height since not everything seems to use the
		; right width for A4.  Note that GEO_docH is the document
		; height, not the paper height of the print job, so this'll
		; only work in cases where the app sets the document size
		; to A4 (i.e. GeoWrite, Responder NoteEdit, etc.)
		; -- brianc 4/1/96

		test	es:[PSEO_flags], mask PSEF_EPS_FILE
		jnz	notA4				; not for print file
		cmpdw	es:[GEO_docH], 842		; A4 height?
		jne	notA4
		EmitPS	emitA4
		jc	done
notA4:

		; write our EndSetup section

		EmitPS	endSetup
done:
		.leave
		ret
EmitDocSetup	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitPageSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write page setup section

CALLED BY:	INTERNAL
		TransExportBeginPage

PASS:		ds	- points to locked PSCode resource
		es	- points to locked options block
		bx	- handle of EPSExportLowStreamStruct

RETURN:		carry	- set if some error from StreamWrite
				(ax holds error code)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		write out #copies...

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitPageSetup	proc	near
		uses	bx, cx, dx
scratchBuffer	local	20 dup(char)
		.enter

		; first write out %%Page comment

		EmitPS	pageNumber
		jc	done			; handle errors

		; next convert the current page number...

		mov	si, bx			; save stream block handle
		mov	bx, es:[PSEB_curPage]	; get #copies
		push	es, ds
		segmov	es, ss, di
		lea	di, scratchBuffer	; es:di -> buffer
		call	UWordToAscii		; create string
		mov	{byte} es:[di], ' '
		inc	di
		call	UWordToAscii		; just do it again, even though
		mov	al, C_CR		; it's the same value
		mov	ah, C_LF
		stosw
		clr	al
		mov	cx, di			; cx = current pos
		lea	dx, scratchBuffer	; compute length
		sub	cx, dx			; cx = length
		segmov	ds, ss, di		; ds -> stack
		mov	bx, si			; restore stream block handle
		call	SendToStream		; write out the coords
		pop	es, ds
		jc	done

		; next emit the %%PageSetup section.

		EmitPS	beginPageSetup
		jc	done
		EmitPS	emitSave		; exec a save
		jc	done
		EmitPS	emitStartDict		; begin the GeoWorks dictionary
		jc	done
		EmitPS	emitBP			; start the page 
		jc	done

done:
		.leave
		ret
EmitPageSetup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitEndPageSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish the PageSetup section of the EPS file

CALLED BY:	INTERNAL
		TransExport

PASS:		ds	- points to locked PSCode resource
		es	- points to locked options block
		bx	- handle of EPSExportLowStreamStruct

RETURN:		carry	- set if some error from StreamWrite
				(ax = error code)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		write out the code to effect the setting of the default 
		transformation matrix, and the EndPageSetup comments

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitEndPageSetup proc	far
		uses	cx, dx
		.enter

		; compute the default transformation 

		EmitPS	emitSDT			; set the default...
		jc	done

		EmitPS	endPageSetup
done:
		.leave
		ret
EmitEndPageSetup endp

ExportCode	ends
