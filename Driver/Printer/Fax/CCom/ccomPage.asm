COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer/Fax/CCom
FILE:		ccomPage.asm

AUTHOR:		Don Reeves, April 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	PrintStartPage		Initializes a new page
	PrintEndPage		Ends the current page
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/26/91		Initial revision

DESCRIPTION:
	Code to implement the page routines for the fax driver		

	$Id: ccomPage.asm,v 1.1 97/04/18 11:52:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the page

CALLED BY:	GLOBAL

PASS:		BP	= PState segment address.

RETURN:		carry	= Set if error

DESTROYED:	BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintStartPage	proc	far
		mov	bx, bp
cff		local	CFFrame
		uses	ax, cx, dx, ds
		.enter
		
	;
	; Some set-up work
	;
		mov	ds, bx
		push	ds
		call	ConvertCFFrameToStack
		mov	ss:[cff.CFF_pageStart].low, ax
		mov	ss:[cff.CFF_pageStart].high, dx
	;
	; Create the file using the current name (stored in convertFileEntry).
	;
		segmov	ds, ss
		lea	dx, ss:[cff.CFF_convertFileEntry].CFE_fileName
		mov	ax, (FILE_CREATE_TRUNCATE or mask FCF_NATIVE) shl 8 or \
				FileAccessFlags <FE_EXCLUSIVE, FA_WRITE_ONLY>
		mov	cx, FILE_ATTR_NORMAL
		call	FileCreate
		jc 	done
	;
	; Write the proper header to the file using the current page number.
	;
		xchg	bx, ax
		mov	ss:[cff.CFF_curPageFile], bx
		mov	ax, ss:[cff.CFF_curPage]
		mov	ss:[cff.CFF_faxFileHeader].FFH_pageNumber, ax
		lea	dx, ss:[cff.CFF_faxFileHeader]
		mov	cx, (size FaxFileHeader) + 1
		clr	al
		call	FileWrite
EC <		WARNING_C ERROR_WRITING_TO_DATA_FILE		>
		jc	fileError
		call	ConvertTopMargin
done:
		pop	ds				; PState => DS
		call	ConvertStackToCFFrame

		.leave
		ret
	;
	; Error setting up the page. Close the file down again and return
	; carry set.
	;
fileError:
		mov	bx, ss:[cff.CFF_curPageFile]
		clr	al
		call	FileClose
		stc
		jmp	done
PrintStartPage	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEndPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the page

CALLED BY:	GLOBAL

PASS:		BP	= PState segment address.

RETURN:		Carrry	= Set if error

DESTROYED:	BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 4/91		Initial version
	don	5/ 2/91		Made into a print driver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintEndPage	proc	far
		mov	bx, bp
cff		local	CFFrame
		uses	ax, cx, dx, si, ds
		.enter
	;
	; Write the terminating 5 (or more) EOL tokens to the file.
	;
		mov	ds, bx
		call	ConvertCFFrameToStack
		push	ds

		mov	ds, ss:[cff.CFF_outBufSeg]
		mov	ax, EOL_TOKEN or (EOL_TOKEN shl 8)
		mov	{word}ds:[0], ax
		mov	{word}ds:[2], ax
		mov	{word}ds:[4], ax
		clr	dx
		mov	cx, 6
		mov	bx, ss:[cff.CFF_curPageFile]
		clr	al
		call	FileWrite		; don't ignore errors
EC <		WARNING_C ERROR_WRITING_TO_DATA_FILE		>
		jnc	finishPage
		clr	al
		call	FileClose
		stc
		jmp	done
	;
	; Adjust the cumulative size of pages in faxFileHeader by the size of
	; this file.
	;
finishPage:
		call	FileSize
		adddw	ss:[cff.CFF_faxFileHeader].FFH_size, dxax
		clr	al
		call	FileClose
		jc	done
	;
	; Adjust the page number in the FaxJob and in convertFileEntry
	;
		inc	ss:[cff.CFF_curPage]
		mov	si, 11
incLoop:
		mov	al, ss:[cff.CFF_convertFileEntry].CFE_fileName[si]
		inc	al
		mov	ss:[cff.CFF_convertFileEntry].CFE_fileName[si], al
		cmp	al, '9'+1	; did we wrap?
		jne	doneOK		; no -- all done

		mov	al, '0'		; wrap correctly
		mov	ss:[cff.CFF_convertFileEntry].CFE_fileName[si], al
		dec	si		; and carry to the next higher digit
		cmp	si, 8		; back to 000?
		jne	incLoop		; nope -- keep going
doneOK:
		clc
done:
		pop	ds
		call	ConvertStackToCFFrame

		.leave
		ret
PrintEndPage	endp








