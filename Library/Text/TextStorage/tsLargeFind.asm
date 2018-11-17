COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsLargeFind.asm

AUTHOR:		John Wedgwood, Nov 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/26/91	Initial revision

DESCRIPTION:
	Code for finding strings in large text objects.

	$Id: tsLargeFind.asm,v 1.1 97/04/07 11:22:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextStorageCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeFindStringInText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a string in a large text object.

CALLED BY:	TS_FindStringInText via CallStorageHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Offset to char in text object to begin search
		dx.ax	= Offset into text object of last char to include
			  in search
		es	= Segment address of SearchReplaceStruct
RETURN:		carry set if string not found
		dx.ax   = # chars in match
		bp.cx 	= offset to string found
DESTROYED:	bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeFindStringInText	proc	far	uses	si, es, ds
	class	VisTextClass

	stackFrame	local	TextSearchInHugeArrayFrame
	.enter

	;
	; Set up stack frame for TextSearchInHugeArray
	;
	movdw	stackFrame.TSIHAF_curOffset, bxcx
	movdw	stackFrame.TSIHAF_endOffset, dxax
	call	TS_GetTextSize
	movdw	stackFrame.TSIHAF_str1Size, dxax

	;
	; Set up HugeArrayHandle
	;
	call	T_GetVMFile			;bx = file
	mov	stackFrame.TSIHAF_hugeArrayVMFile, bx
	call	TextStorage_DerefVis_DI
	mov	ax, ds:[di].VTI_text
	mov	stackFrame.TSIHAF_hugeArrayVMBlock, ax
	
	segxchg	ds, es
	mov	al, ds:[SRS_params]
	mov	stackFrame.TSIHAF_searchFlags, al

	mov	bx, bp				; bx <- save frame ptr in bx
	lea	bp, stackFrame			; ss:bp <- stack frame
	mov	si, offset SRS_searchString	; ds:si <- ptr to string to find
	clr	cx				; null terminated search string
	call	TextSearchInHugeArray		; Do the search!
	;
	; carry set if string was not found
	; bp.cx	= # chars matched
	; dx.ax	= offset to match
	;
	xchg	bx, bp				; Restore frame ptr
						; bx <- nMatched.high
	.leave

	mov	bp, bx				; bp.cx <- # that matched
	xchgdw	bpcx, dxax			; dx.ax <- # chars matched
						; bp.cx <- offset to match
	ret		
LargeFindStringInText	endp


TextStorageCode	ends
