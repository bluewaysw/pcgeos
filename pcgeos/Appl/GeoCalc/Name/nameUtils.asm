COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		namesUtils.asm

AUTHOR:		John Wedgwood, Feb 11, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/11/91	Initial revision

DESCRIPTION:
	Utilities used by the name routines.

	$Id: nameUtils.asm,v 1.1 97/04/04 15:49:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UICode	segment resource
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrabParserError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get an error message

CALLED BY:	GeoCalcSpreadsheetError

PASS:		al	= ParserScannerEvaluatorError
		cx:dx	= Pointer to the place to put the message
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	If the error is a parse library error
	    Get the error string
	else (is our own error)
	    Get the error from our own buffer
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrabParserError	proc	far
	uses	bx, cx, ds, si
	.enter
	mov	ds, cx			; ds:si <- ptr to the buffer
	mov	si, dx

	cmp	al, PSEE_FIRST_APPLICATION_ERROR
	jb	parserError
	call	GrabInternalParserError
gotError:
	.leave
	ret

parserError:
	call	ParserErrorMessage
	jmp	gotError
GrabParserError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrabInternalParserError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get an internal error message

CALLED BY:	GrabParserError
PASS:		ds:si	= Place to put the message
		al	= Error code
RETURN:		cx	= Length of the message (not including the NULL)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrabInternalParserError	proc	near
	uses	ax, ds, si, es, di
	.enter
	segmov	es, ds			; es:di <- ptr to the destination
	mov	di, si

	clr	cx
	mov	cl, al			; cx <- error message #
	;
	; The only errors we handle are:
	;	PSEE_REALLOC_FAILED
	;	PSEE_RESULT_SHOULD_BE_CELL_OR_RANGE
	; Everything else is handled in the spreadsheet.
	;
	; There's a new error in town:
	;	PSEE_CELL_OR_RANGE_IS_LOCKED
	; This is returned if the user tries to 'Goto' a cell in the
	; locked area. For Nike, we have a special error message. For
	; all other products, the "invalid range" message is used.
	;
	mov	si, offset reallocFailedMessage
	cmp	cx, PSEE_REALLOC_FAILED
	je	gotMessage
	mov	si, offset notCellOrRangeMessage
gotMessage:

	GetResourceHandleNS	StringsUI, bx
	call	MemLock	; ax <- seg addr of the resource
	mov	ds, ax			; *ds:si <- ptr to first message
	mov	si, ds:[si]		; ds:si <- ptr to the message
	
	ChunkSizePtr	ds, si, cx	; cx <- size of the chunk (with null)
	push	cx			; Save the size
	rep	movsb			; Copy the string
	pop	cx			; Restore the size
DBCS<	shl	cx, 1			; cx <- string length		>
	dec	cx			; Don't count the NULL
	
	call	MemUnlock		; Unlock the resource
	.leave
	ret
GrabInternalParserError	endp

UICode	ends
