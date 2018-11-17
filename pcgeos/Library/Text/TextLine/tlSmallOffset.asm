COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlSmallOffset.asm

AUTHOR:		John Wedgwood, Dec 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/26/91	Initial revision

DESCRIPTION:
	Offset related stuff

	$Id: tlSmallOffset.asm,v 1.1 97/04/07 11:20:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineGetCharCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of characters in a line.

CALLED BY:	TL_LineGetCount
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line
RETURN:		dx.ax	= Number of characters in the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineGetCharCount	proc	near
	uses	cx, di, es
	.enter
	mov	di, cx			; bx.di <- line

EC <	call	ECCheckSmallLineReference			>

	call	SmallGetLinePointer	; *ds:ax <- chunk array
					; es:di <- line pointer
					; cx <- size of line/field data
	CommonLineGetCharCount		; dx.ax <- Number of chars in line
	.leave
	ret
SmallLineGetCharCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineToOffsetStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the start of a line.

CALLED BY:	TL_LineToOffsetStart
PASS:		*ds:si	= Instance
		bx.cx	= Line
RETURN:		dx.ax	= Start
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineToOffsetStart	proc	near
	uses	cx, di
	.enter	inherit	TL_LineToOffsetStart
	
	call	SmallLineToOffsetStartSizeFlags
	;
	; ax	<- line start
	; cx	<- line flags
	; di	<- Number of characters on line
	;
	clr	dx		; dx.ax <- end of line
	.leave
	ret
SmallLineToOffsetStart	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineToOffsetVeryEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the end of a line.

CALLED BY:	TL_LineToOffsetVeryEnd
PASS:		*ds:si	= Instance
		bx.cx	= Line
RETURN:		dx.ax	= End
		cx	= LineFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineToOffsetVeryEnd	proc	near
	uses	di
	.enter	inherit	TL_LineToOffsetStart

	call	SmallLineToOffsetStartSizeFlags
	;
	; ax	<- line start
	; cx	<- line flags
	; di	<- Number of characters on line
	;
	add	ax, di		; ax <- end of line
	clr	dx		; dx.ax <- end of line
	.leave
	ret
SmallLineToOffsetVeryEnd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineToOffsetStartSizeFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about a line...

CALLED BY:	SmallLineToOffsetVeryEnd, SmallLineToOffsetStart
PASS:		*ds:si	= Instance
		ss:bp	= Inheritable stack frame
RETURN:		ax	= Start
		cx	= LineFlags
		di	= Number of chars on line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineToOffsetStartSizeFlags	proc	near
	uses	bx, dx, si
	.enter	inherit	TL_LineToOffsetStart

	;
	; Set the callback routine
	;
	mov	bx, cs			; bx:di <- callback routine
	mov	di, offset cs:CommonLineToOffsetEtcCallback

	clr	dx			; dx.cx <- line to stop at

	call	SmallGetLineArray	; *ds:ax <- line array
	mov	si, ax			; *ds:si <- line array

	call	ChunkArrayEnum		; cx <- LineFlags, dx.ax <- charCount

	;
	; Set up the return values
	;
	mov	di, ax			; di <- charCount
	mov	ax, lineStart.low	; ax <- start
	.leave
	ret
SmallLineToOffsetStartSizeFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineToOffsetEtcCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute lots of stuff

CALLED BY:	Large/SmallLineToOffsetStartSizeFlags via Huge/ChunkArrayEnum
PASS:		ds:di	= Current line
		ax	= Element size
		ss:bp	= Inheritable stack frame
		dx.cx	= Number of lines to go before stopping
RETURN:		carry set if we have found the line
		  cx	= LineFlags
		  dx.ax	= CharCount
		carry clear otherwise
		  dx.cx = Number to go before stopping
DESTROYED:	bx, di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineToOffsetEtcCallback	proc	far
	uses	bx, es
firstLine	local	dword
lineStart	local	dword
	.enter	inherit

	segmov	es, ds, bx		; es:di <- line ptr

	tstdw	dxcx			; Check for reached the line
	jz	foundLine
	
	;
	; We haven't reached the line we want
	;
	decdw	dxcx			; One less line to skip
	
	;
	; Update the line start
	;
	push	dx
	CommonLineGetCharCount		; dx.ax <- Number of chars in line
	adddw	lineStart, dxax		; Update the line start
	pop	dx
	
	clc				; Signal: continue

quit:
	.leave
	ret

foundLine:
	;
	; lineStart already holds the start of this line. We do need to copy
	; over the number of characters in the line.
	;
	CommonLineGetCharCount		; dx.ax <- character count
	mov	cx, ds:[di].LI_flags	; cx <- flags

	stc				; Signal: all done
	jmp	quit

CommonLineToOffsetEtcCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineFromOffsetGetStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure which line falls at a given offset and return the
		start of the line.

CALLED BY:	TL_LineFromOffsetGetStart
PASS:		*ds:si	= Instance
		ss:bp	= Inheritable stack frame
RETURN:		bx.di	= Line containing offset
		dx.ax	= Start of that line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallLineFromOffsetGetStart	proc	near
	uses	si
offsetToFind	local	dword
lineStart	local	dword
firstLine	local	dword
wantFirstFlag	local	byte
	.enter	inherit
	mov	bx, cs			; bx:di <- callback routine
	mov	di, offset cs:CommonLineFromOffsetCallback

	push	ax			; Save offset.low
	call	SmallGetLineArray	; *ds:ax <- line array
	mov	si, ax			; *ds:si <- line array
	pop	ax			; Restore offset.low

	call	ChunkArrayEnum		; cx <- LineFlags
					; dx.ax <- Previous line start
					; carry set if ran out of lines

	call	CommonLineFromOffsetGetStartFinish
	.leave
	ret
SmallLineFromOffsetGetStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineFromOffsetGetStartFinish
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish up getting a line and line-start from an offset.

CALLED BY:	SmallLineFromOffsetGetStart, LargeLineFromOffsetGetStart
PASS:		cx	= LineFlags for current line
		dx.ax	= Previous line start
		carry set if we ran out of lines
		ss:bp	= Inheritable stack frame
		bx	= Flags passed to *LineFromOffsetGetStart
RETURN:		bx.di	= Line containing offset
		dx.ax	= Start of that line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineFromOffsetGetStartFinish	proc	near
	.enter	inherit	SmallLineFromOffsetGetStart
	jnc	usePrevLine		; Branch if ran out of lines
quit:
	;
	; Return values from the stack
	;
	movdw	dxax, lineStart		; dx.ax <- current line start
	movdw	bxdi, firstLine		; bx.di <- line to use
	.leave
	ret

usePrevLine:
	;
	; Use the previous line
	;
	tstdw	firstLine		; Check for on first line
	jz	quit			; Branch if we are

	decdw	firstLine		; Use previous line
	movdw	lineStart, dxax		; Use previous line start
	jmp	quit
CommonLineFromOffsetGetStartFinish	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonLineFromOffsetCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure if a line contains a given offset

CALLED BY:	Chunk/HugeArrayEnum
PASS:		ds:di	= Line
		ss:bp	= Inheritable stack frame
RETURN:		firstLine = Current line
		lineStart = Start of current line
		cx	= LineFlags
		dx.ax	= Previous line start if needed
		carry set to stop processing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

nKNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonLineFromOffsetCallback	proc	far
	uses	es
	.enter	inherit	SmallLineFromOffsetGetStart

	segmov	es, ds, ax		; es:di <- line ptr

	CommonLineGetCharCount		; dx.ax <- Number of chars in line
	adddw	dxax, lineStart		; dx.ax <- Next line start

	cmpdw	offsetToFind, dxax
	jb	usePrevLine		; Branch if before this line
	je	checkWhichLine		; Branch if at the offset

advanceLine:
	xchgdw	dxax, lineStart		; Set next line start
					; dx.ax <- previous line start

	incdw	firstLine		; Advance the line

	clc				; Signal: Keep processing

quit:
	pushf				; Save flags
	mov	cx, ax			; cx <- prevLine.start.low
	call	CommonLineGetFlags	; ax <- flags
	xchg	ax, cx			; dx.ax <- prevLine.start
					; cx <- flags
	popf				; Restore flags
	.leave
	ret

checkWhichLine:
	;
	; We are at the offset. If the caller wants the first line at this
	; offset, we return this one.
	;
	tst	wantFirstFlag
	jz	advanceLine
	
;;;	xchgdw	dxax, lineStart		; Set next line start
					; dx.ax <- previous line start

;;;	incdw	firstLine		; Advance the line

usePrevLine:
	;
	; We are on the line to use...
	;
	stc				; Signal: quit
	jmp	quit
CommonLineFromOffsetCallback	endp


TextFixed	ends
