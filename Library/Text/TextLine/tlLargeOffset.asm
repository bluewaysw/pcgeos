COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlLargeOffset.asm

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

	$Id: tlLargeOffset.asm,v 1.1 97/04/07 11:20:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineGetCharCount
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
LargeLineGetCharCount	proc	near
	uses	cx, di, es
	.enter
	mov	di, cx			; bx.di <- line

	call	LargeGetLinePointer	; es:di <- line pointer
					; cx <- size of line/field data
	CommonLineGetCharCount		; dx.ax <- Number of characters
	call	LargeReleaseLineBlock	; Release the line block
	.leave
	ret
LargeLineGetCharCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineToOffsetStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the start offset of a line.

CALLED BY:	TL_LargeLineToOffsetStart
PASS:		*ds:si	= Instance
		bx.cx	= Line to find
		On stack:
			dword	- First line in current region
			dword	- Start offset of current region
RETURN:		dx.ax	= Line start
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineToOffsetStart	proc	near
	uses	bx, cx, di
firstLine	local	dword
lineStart	local	dword
	.enter	inherit
	
	call	LargeLineToOffsetStartSizeFlags
	;
	; cx	<- line flags
	;
	movdw	dxax, lineStart
	.leave
	ret	@ArgSize
LargeLineToOffsetStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineToOffsetVeryEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the end of the line.

CALLED BY:	TL_LineToOffsetVeryEnd
PASS:		*ds:si	= Instance
		bx.cx	= Line
		On stack:
			dword	- First line in current region
			dword	- Start offset of current region
RETURN:		dx.ax	= Line start
		cx	= Line flags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineToOffsetVeryEnd	proc	near
	uses	bx, di
firstLine	local	dword
lineStart	local	dword
	.enter	inherit

	call	LargeLineToOffsetStartSizeFlags
	;
	; cx	<- line flags
	;
	movdw	dxax, firstLine		; dx.ax <- Number of characters on line
	adddw	dxax, lineStart		; dx.ax <- end of line
	.leave
	ret	@ArgSize
LargeLineToOffsetVeryEnd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineToOffsetStartSizeFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about a line...

CALLED BY:	LargeLineToOffsetVeryEnd, LargeLineToOffsetStart
PASS:		*ds:si	= Instance
		bx.cx	= Line
		ss:bp	= Inheritable stack frame
RETURN:		cx	= LineFlags
		lineStart = Start of the line
		firstLine = Number of characters on line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineToOffsetStartSizeFlags	proc	near
	uses	bx, dx, di
firstLine	local	dword
startOffset	local	dword
	.enter	inherit

	subdw	bxcx, firstLine		; bx.cx <- # of lines to skip
	mov	dx, bx			; dx.cx <- # of lines to skip

	call	T_GetVMFile
	push	bx			; VM file
	call	LargeGetLineArray	; di <- line array
	push	di			; Pass array
	
	push	cs
	mov	di, offset cs:CommonLineToOffsetEtcCallback
	push	di			; Pass callback
	
	pushdw	firstLine		; Pass starting element
	
	mov	di, -1			; Pass number to do
	push	di, di

	call	HugeArrayEnum		; cx <- LineFlags, dx.ax <- charCount
	movdw	firstLine, dxax		; Save the count

	;
	; lineStart = Start of this line
	; firstLine = Number of characters on the line
	; cx	    = LineFlags for the line
	;
	.leave
	ret
LargeLineToOffsetStartSizeFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineFromOffsetGetStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure which line falls at a given offset and return the
		start of the line.

CALLED BY:	TL_LineFromOffsetGetStart
PASS:		*ds:si	= Instance
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
LargeLineFromOffsetGetStart	proc	near
offsetToFind	local	dword
lineStart	local	dword
firstLine	local	dword
wantFirstFlag	local	byte
	.enter	inherit
	call	T_GetVMFile
	push	bx			; VM file
	call	LargeGetLineArray	; di <- line array
	push	di			; Pass array
	
	push	cs
	mov	di, offset cs:CommonLineFromOffsetCallback
	push	di			; Pass callback

	pushdw	firstLine		; Pass starting element
	
	mov	di, -1			; Pass number to do
	push	di, di

	call	HugeArrayEnum		; cx <- LineFlags
					; dx.ax <- Previous line start
					; carry set if ran out of lines

	call	CommonLineFromOffsetGetStartFinish
	.leave
	ret
LargeLineFromOffsetGetStart	endp

TextFixed	ends
