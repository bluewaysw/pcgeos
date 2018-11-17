COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tsSmallFind.asm

AUTHOR:		John Wedgwood, Nov 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/26/91	Initial revision

DESCRIPTION:
	Code for finding strings in small text objects.

	$Id: tsSmallFind.asm,v 1.1 97/04/07 11:22:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextStorageCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallFindStringInText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a string in a small text object.

CALLED BY:	TS_FindStringInText via CallStorageHandler
PASS:		*ds:si	= Instance ptr
		cx	= Offset to char in text object to begin search
		ax	= Offset into text object of last char to include
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
	atw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SmallFindStringInText	proc	far	uses	ds, es, si
	.enter
	class	VisTextClass
	call	TextStorage_DerefVis_DI
	mov	di, ds:[di].VTI_text	;
	mov	di, ds:[di]		;DS:DI <- ptr to start of text chunk
	mov	bx, di			;
	mov	bp, di			;DS:BP <- ptr to start of text chunk
DBCS <	shl	cx, 1			;char offset -> byte offset	>
	add	di, cx			;DS:DI <- ptr to first char to include
					; in search
DBCS <	shl	ax, 1			;char offset -> byte offset	>
	add	bx, ax			;DS:BX <- ptr to last char to include
					; in search
	call	TS_GetTextSize		;AX <- # chars in this object
	mov_tr	dx, ax			;DX <- # chars to search in in text
					; object

	segxchg	es, ds			;ES <- segment of text object
					;DS <- segment of SearchReplaceStruct

	clr	cx			;Null terminated string
	mov	si, offset SRS_searchString	;DS:SI <- ptr to string to
						; search for
	mov	al, ds:[SRS_params]
	call	TextSearchInString
	pushf				;Save return code
	clr	dx			;DX.AX <- # chars in match
	mov	ax, cx			;
	sub	di, bp			;DI <- offset from start of text
					; that match was found
	clr	bp			;
	mov	cx, di			;BP:CX <- offset to string if found
DBCS <	shr	cx, 1			;cx: byte offset -> char offset	>
	popf
	.leave
	ret
SmallFindStringInText	endp

TextStorageCode	ends

