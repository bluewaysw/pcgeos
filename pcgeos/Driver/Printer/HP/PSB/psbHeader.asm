COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript (bitmap) printer driver
FILE:		psbHeader.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/91		Initial revision


DESCRIPTION:
	This file contains the code to create the proper header for the 
	stream of PostScript that we're sending to the printer.  This is 
	mostly taken from the PostScript translation library, with a few
	modifications.
		

	$Id: psbHeader.asm,v 1.1 97/04/18 11:52:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WritePSHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	output any header info

CALLED BY:	INTERNAL
		PrintStartJob

PASS:		ds:si	- pointer to JobParameters block
		es	- pointer to PState

RETURN:		carry	- set if some transmission error to printer

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		export the file header and prolog

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WritePSHeader	proc	near
		uses	ax, bx, cx, dx, ds, si
jobParams	local	fptr	
scratchBuffer	local	40 dup(char)
		.enter
		ForceRef	scratchBuffer

		; store away the JobParameters pointer that we have

		mov	jobParams.segment, ds
		mov	jobParams.offset, si
		
		; first write out the header comments.  For a few of them,
		; we need to insert arguments.  Check to make sure writing
		; comments is OK...
		; lock down the PSCode resource to emit the comments

		mov	bx, handle PSCode
		call	GeodeLockResource
		mov	dx, ax
		call	EmitHeaderComments
		mov	bx, handle PSCode
		call	MemUnlock		; release PSCode resource
		jc	done

		; next, output the PostScript code for the prolog.

		mov	bx, handle PSProlog	; get resource handle
		call	GeodeLockResource	; lock it down
		mov	ds, ax			; ds -> PSCode resource
		mov	cx, offset endPSProlog - offset beginPSProlog
		mov	si, offset beginPSProlog
		call	PrintStreamWrite	; write out prolog
		mov	bx, handle PSProlog	; get resource handle
		call	MemUnlock
		jc	done

		mov	bx, handle PSCode
		call	GeodeLockResource
		mov	ds, ax
		call	EmitDocSetup		; write out doc setup stuff
		mov	bx, handle PSCode
		call	MemUnlock		; release PSCode resource
done:
		.leave
		ret
WritePSHeader endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitHeaderComments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the header comment strings

CALLED BY:	INTERNAL
		WritePSHeader

PASS:		dx	- pointer to locked PSCode resource
		es	- pointer to locked options block
		ds:si	- pointer to JobParameters block

RETURN:		carry	- set if some error from PrintStreamWrite

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		copy comments from PSCode resource, insert arguments when
		necessary

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitHeaderComments	proc	near
		uses	bx, cx, dx, di, si, ds
jobParams	local	fptr	
scratchBuffer	local	40 dup(char)
		.enter  inherit

		ForceRef scratchBuffer			; needed by lower rout

		; the first thing to output is the !PS comment

		mov	ds, dx				; ds -> PSCode rsrc
		mov	si, offset printFileID		; %!PS-Adobe-3.0
		mov	cx, length printFileID
		call	PrintStreamWrite
		LONG jc	done				; handle errors

		; write out the %%BoundingBox line

		call	EmitBoundingBox
		LONG jc	done	

		; put the the %%Creator line

		EmitPS	creatorComment
		LONG jc	done	

		push	ds				; copy from option blk
		lds	si, ss:jobParams
		add	si, offset JP_parent		; ds:si -> appName
		mov	dx, si
		call	CalcStringLength		; cx = length of string
		call	PrintStreamWrite
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
		EmitPS	emitCRLF
		jc	done	

		; put the the %%Title line
putTitle:
		EmitPS	titleComment
		jc	done	

		push	ds				; copy from option blk
		lds	si, ss:jobParams
		add	si, offset JP_documentName	; ds:si -> doc name
		mov	dx, si
		call	CalcStringLength		; cx = length of string
		call	PrintStreamWrite
		pop	ds
		jc	done
		EmitPS	emitCRLF
		jc	done

		; put the %%EndComments line

		EmitPS	endComments
done:
		.leave
		ret

EmitHeaderComments	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitPageInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the #pages, page order, etc.

CALLED BY:	INTERNAL
		WritePSHeader

PASS:		ds	- points to locked PSCode resource
		es	- points to PState
		jobParams - inherited stack frame variable

RETURN:		carry	- set if problem in PrintStreamWrite

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		write out the %%Pages: comment

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitPageInfo	proc	near
		uses	ax, bx, cx, dx, di, si
jobParams	local	fptr	
scratchBuffer	local	40 dup(char)
		.enter	inherit

		; put in %%Pages

		EmitPS	numPages
		LONG jc	done

		push	ds
		push	es
		lds	si, ss:jobParams		; ds:si -> JobParams
		mov	bx, ds:[si].JP_numPages		; get num pages
		mov	dl, ds:[si].JP_numCopies	; while we're here...
		clr	dh
		segmov	es, ss, di
		lea	di, scratchBuffer		; es:di -> scratch space
		call	UWordToAscii			; convert #pages
		mov	al, C_CR			; finish off the line
		mov	ah, C_LF			; output CRLF
		stosw
		mov	cx, di				; cx = current pos
		lea	si, scratchBuffer		; compute length
		sub	cx, si				; cx = length
		segmov	ds, ss, di			; ds:si -> scratchbuf
		pop	es
		call	PrintStreamWrite		; write out the coords
		pop	ds
		jc	done

		; put in %%Requirements comment for #copies, collate...
setCopies:
		cmp	dx, 1				; only need this if
		jbe	doneOK				;  more than 1 copy
		EmitPS	requirements
		jc	done
		mov	bx, dx				; get #copies
		push	ds
		push	es
		segmov	es, ss, di
		lea	di, scratchBuffer		; es:di -> buffer
		call	UWordToAscii			; create string
		mov	al, ')'				; closing paren
		stosb
		mov	cx, di				; cx = current pos
		lea	si, scratchBuffer		; compute length
		sub	cx, si				; cx = length
		segmov	ds, ss, di			; ds:si -> scratchBuf
		pop	es
		call	PrintStreamWrite		; write out the coords
		pop	ds
done:
		.leave
		ret

doneOK:
		clc					; no error
		jmp	done
EmitPageInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitBoundingBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the bounding box comment line

CALLED BY:	INTERNAL
		WritePSHeader

PASS:		ds	- points to locked PSCode resource
		es	- points to locked PState
		jobParams - passed on stack

RETURN:		carry	- set if problem in PrintStreamWrite

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
		uses	bx, cx, dx, ax, si, di
jobParams	local	fptr
scratchBuffer	local	40 dup(char)
		.enter	inherit

		; write out the bounding box.  Use (0,0) for the lower left
		; and (width,height) for the upper right.

		EmitPS	boundBox
		jc	done

		; convert the bounding box coords to ascii to output

		mov	cx, es:[PS_customWidth]		; get width and height
		mov	dx, es:[PS_customHeight]
		push	ds
		push	es
		segmov	es, ss, di
		lea	di, scratchBuffer		; es:di -> buffer
		mov	al, '0'				; setup to write 0
		mov	ah, ' '
		stosw
		stosw					; "0 0 " written
		mov	bx, cx				; convert this one
		call	UWordToAscii			; convert width
		mov	al, ' '				; space separated
		stosb
		mov	bx, dx				; now do height
		call	UWordToAscii
		mov	al, C_CR			; finish off the line
		mov	ah, C_LF			; output CRLF
		stosw
		mov	cx, di				; cx = current pos
		lea	si, scratchBuffer		; compute length
		sub	cx, si				; cx = length
		segmov	ds, ss, di			; ds -> stack
		pop	es				; restore file handle
		call	PrintStreamWrite		; write out the coords
		pop	ds
done:
		.leave
		ret
EmitBoundingBox	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitCreationDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the creation date comment line

CALLED BY:	INTERNAL
		WritePSHeader

PASS:		ds	- points to locked PSCode resource
		es	- points to locked options block
		bx	- file handle

RETURN:		carry	- set if problem in PrintStreamWrite
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
		uses	ax, bx, cx, dx, si, di
jobParams	local	fptr
scratchBuffer	local	40 dup(char)
		.enter	inherit

		EmitPS	creationDate
		jc	done

		push	ds
		push	es
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
		mov	cx, di				; cx = current pos
		lea	si, scratchBuffer		; compute length
		sub	cx, si				; cx = length
		segmov	ds, ss, di			; ds -> stack
		pop	es
		call	PrintStreamWrite		; write out the coords
		pop	ds
done:
		.leave
		ret
EmitCreationDate endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitDocSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write document setup section

CALLED BY:	INTERNAL
		WritePSBeginPage

PASS:		ds	- points to locked PSCode resource
		es	- points to locked PState
		jobParams - passed in inherited stack frame

RETURN:		carry	- set if some error from PrintStreamWrite

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		write out document setup stuff

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitDocSetup	proc	near
		uses	ax, bx, cx, dx, si, di
jobParams	local	fptr
scratchBuffer	local	40 dup(char)
		.enter	inherit

		; close Prolog section, start page setup section

		mov	si, offset endProlog
		mov	cx, length endProlog + length beginSetup
		call	PrintStreamWrite		; write out prolog
		jc	done

		; write out #copies...

		EmitPS	emitNC				; write out "/#copies "
		jc	done
		push	ds
		push	es
		lds	si, jobParams
		mov	bl, ds:[si].JP_numCopies	; get #copies
		clr	bh
		segmov	es, ss, di
		lea	di, scratchBuffer		; es:di -> buffer
		call	UWordToAscii			; create string
		mov	cx, di				; cx = current pos
		lea	si, scratchBuffer		; compute length
		sub	cx, si				; cx = length
		segmov	ds, ss, di			; ds -> stack
		pop	es
		call	PrintStreamWrite		; write out the coords
		pop	ds
		jc	done
		EmitPS	emitDef
		jc	done

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
		WritePSBeginPage

PASS:		ds	- points to locked PSCode resource
		es	- points to locked PState
		jobParams - passed in inherited stack frame

RETURN:		carry	- set if some error from PrintStreamWrite

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		write out page setup stuff

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitPageSetup	proc	near
		uses	ax, bx, cx, dx, si, di
scratchBuffer	local	40 dup(char)
		.enter

		; first write out %%Page comment

		EmitPS	pageNumber
		jc	done			; handle errors

		; next convert the current page number...

		mov	bx, es:[PS_asciiStyle]	; reuse variable for page#
		push	ds
		push	es
		segmov	es, ss, di
		lea	di, scratchBuffer	; es:di -> buffer
		call	UWordToAscii		; create string
		mov	al, ' '
		stosb
		call	UWordToAscii		; just do it again, even though
		mov	al, C_CR		; it's the same value
		mov	ah, C_LF
		stosw
		mov	cx, di			; cx = current pos
		lea	si, scratchBuffer	; compute length
		sub	cx, si			; cx = length
		segmov	ds, ss, di		; ds -> stack
		pop	es
		call	PrintStreamWrite	; write out the coords
		pop	ds
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
		EmitPS	emitPageMatrix		; special transform
		jc	done
		call	EmitPaperSize
		jc	done
		EmitPS	emitSDT			; set the default transform
		jc	done
		EmitPS	endPageSetup		; end the page setup portion
		jc	done
		EmitPS	emitSO
		jc	done
		EmitPS	emitObjMatrix
		jc	done
		call	EmitBitmapParams	; output size, scale, etc.
done:
		.leave
		ret
EmitPageSetup	endp

