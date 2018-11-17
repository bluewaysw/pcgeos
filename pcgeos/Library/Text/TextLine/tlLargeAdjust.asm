COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlLargeAdjust.asm

AUTHOR:		John Wedgwood, Jan  2, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/ 2/92	Initial revision

DESCRIPTION:
	Code for adjusting line and field offsets for a large text object.

	$Id: tlLargeAdjust.asm,v 1.1 97/04/07 11:21:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Text	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineAdjustForReplacement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust a range of lines after a change has been made.

CALLED BY:	TL_LineAdjustForReplacement via CallLineHandler
PASS:		*ds:si	= Instance ptr
		ss:bp	= VisTextReplaceParameters
RETURN:		bx.di	= First line that changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineAdjustForReplacement	proc	far
	uses	ax, dx, bp
;-----------------------------------------------------------------------------
; Added 'object'  3/27/93 -jw
;	Needed by CommonLineAdjustForReplacementCallback so that it can
;	figure out if it is a large or small object so that it can dirty
;	the line-block appropriately.
;
object		local	dword
;-----------------------------------------------------------------------------
currentLine	local	dword
lineStart	local	dword
	.enter
	movdw	object, dssi

	;
	; First get the starting line/offset for the region associated with
	; the start of the range.
	;
	push	bp			; Save frame ptr
	mov	bp, ss:[bp]		; ss:bp <- VisTextReplaceParameters
	movdw	dxax, ss:[bp].VTRP_range.VTR_start
	call	TR_RegionFromOffsetGetStartLineAndOffset
					; dx.ax <- region start offset
					; bx.di <- region start line
	pop	bp			; Restore frame ptr

	movdw	currentLine, bxdi	; Save these values
	movdw	lineStart, dxax

	call	T_GetVMFile
	push	bx			; File
	call	LargeGetLineArray	; di <- line array
	push	di			; Push line array
	
	push	cs			; Push callback
	mov	di, offset cs:CommonLineAdjustForReplacementCallback
	push	di

	pushdw	currentLine		; Start at region start
	
	mov	bx, -1			; Process until we say stop
	push	bx, bx

	call	HugeArrayEnum		; Do the update
	
	;
	; Set up the return value
	;
	movdw	bxdi, currentLine	; bx.di <- first changed line
	.leave
	ret
LargeLineAdjustForReplacement	endp

Text	ends
