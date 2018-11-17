COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Compress Library
FILE:		compressIO.asm

AUTHOR:		David Loftesness, Jan  6, 1993

ROUTINES:
	Name				Description
	----				-----------

	
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	dloft	1/ 6/93			Initial revision


DESCRIPTION:
	
		

	$Id: compressIO.asm,v 1.1 97/04/04 17:49:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Reads data from the input file or from memory

CALLED BY:	Implode, Explode

	unsigned (far pascal * read_buff) (char far *buffer, 
					   unsigned short far *size)
PASS:		On Stack:  pointer to number of bytes to read, pointer to buffer
		to read into.
RETURN:		ax = # of bytes read
DESTROYED:	ax, bx, cx, dx, di, si (nasty, huh?)

		NOTE: Implode requires that we preserve bp, sp, cs,
		ds, and ss only.
PSEUDO CODE/STRATEGY:
		See if we're using a file or a buffer
		Set up for a rep movsw if a buffer
		Set up for a FileRead if a file

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	* Could be broken up into routines specific for reading from
	memory and for reading from a file.  I've opted to go for a
	small code size instead.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	1/14/91		Initial Version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		.model	large, pascal
ReadData	proc	far	Buf:fptr, byteCount:fptr.word 
		uses 	bp, ds, es, si, di

		.enter
		segmov	es, dgroup, cx
	;
	; Grab the number of bytes off the stack and store away
	; 
		lds	si, ss:[byteCount]
		mov	cx, ds:[si]
		mov	es:[BytesToTransfer], cx
	;
	; Are we reading from memory?
	;
		test	es:[CurFlags], mask CLF_SOURCE_IS_BUFFER
		jz	prepForFileRead		; jump if from file
	;
	; Check if BytesTotal = 0 and boogie
	;
		clr	ax			; in case we're done
		tst	es:[BytesTotal]
		jz 	RD_done
	;
	; Check if we're about to read too much
	;
		cmp	es:[BytesTotal], cx
		jg	plentyLeft
		mov	cx, es:[BytesTotal]
plentyLeft:
		sub	es:[BytesTotal], cx
		push	cx
		lds	si, es:[SourceBuffer]	; ds:si -> source
		les	di, Buf			; es:di -> Buf


		cld
		shr	cx, 1	; divide by 2, copying the odd-byte
				; status to the carry flag
		jnc	CopyWordLowToHigh	; no odd byte
		movsb		; copy the odd byte
CopyWordLowToHigh:
		rep	movsw	; Whammo!

		segmov	es, dgroup, ax		; save the new offset
		mov	es:[SourceBuffer].offset, si
		pop	ax			; # of bytes read
		jmp	RD_done
prepForFileRead:
	;
	; Set up args to FileRead
	;
		mov	bx, es:[SourceFile]

		clr	al			; return errors
		lds	dx, ss:[Buf]		; ds:dx -> buffer

		call	FileRead
		jnc	noError

		cmp	ax, ERROR_SHORT_READ_WRITE
		je	noError			; cx has the right number in it.

		clr	cx			; some other error -- tell PKZip
						; that we're done
noError:
		mov_tr	ax, cx			; return number of
						; bytes read
RD_done:
	;
	; ax should be the # of bytes read!
	;
		.leave
		ret	@ArgSize

ReadData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write data from a buffer to a file

CALLED BY:	Implode, Explode
PASS:		ON STACK: pointer to number of bytes to write, buffer containing
		data to write
RETURN:		
DESTROYED:	ax, bx, cx, dx

		NOTE: Implode requires that we preserve bp, sp, cs,
		ds, and ss only
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	* See ReadData

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	DL	1/14/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		.model	large, pascal
WriteData	proc	far	Buf:fptr, byteCount:fptr
		uses 	bp, ds, es, di, si
		.enter

		segmov	es, dgroup, cx
	;
	; Grab the number of bytes from memory
	;
		lds	si, ss:[byteCount]
		mov	cx, ds:[si]
		add	es:[BytesWritten], cx
	;
	; Test flags
	;
		test	es:[CurFlags], mask CLF_DEST_IS_BUFFER
		jz	writeToFile		; jump if from file
		
writeToMem::
		lds	si, ss:[Buf]		; ds:si -> Buf
		les	di, es:[DestBuffer]	; es:di -> dest

		cld		; copy from low addresses to high
		shr 	cx, 1	; divide by 2, copying the odd-byte
				; status to the carry flag
		jnc	CopyWordLowToHigh	; no odd byte
		movsb		; copy the odd byte
CopyWordLowToHigh:
		rep	movsw	; Whammo!
		segmov	es, dgroup, ax		; save the new offset
		mov	es:[DestBuffer].offset, di
		jmp	WD_done

	;
	; Set up args to FileWrite
	;
writeToFile:
		mov	bx, es:[DestFile]

		lds	dx, ss:[Buf]		; Point to buffer
		clr	al			; return errors
		call	FileWrite
		mov_tr	ax, cx			;AX <- # bytes written
		jnc	WD_done
		clr	ax
WD_done:
		.leave
		ret	@ArgSize
WriteData		endp
