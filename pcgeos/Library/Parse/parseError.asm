COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		parseError.asm

AUTHOR:		John Wedgwood, Jan 24, 1991

ROUTINES:
	Name			Description
	----			-----------
	ParserErrorMessage	Get an error message for a parser error.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/24/91	Initial revision

DESCRIPTION:
	

	$Id: parseError.asm,v 1.1 97/04/05 01:27:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ParserErrorCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParserErrorMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given that an error was generated, return a meaningful
		error message.

CALLED BY:	Global
PASS:		ds:si	= Pointer to the place to put the message
		al	= ParserScannerEvalError
RETURN:		cx	= length of the error message (not counting the null)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/24/91	Initial version
	witt	12/ 6/93	DBCS-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParserErrorMessage	proc	far
	uses	ax, bx, ds, es, di, si
	.enter	
EC <	cmp	al, ParserScannerEvaluatorError		>
EC <	ERROR_AE ILLEGAL_ERROR_CODE			>

;	mov	bx, resid ErrorMessages

	segmov	es, ds			; es:di <- destination
	mov	di, si
	
	clr	ah			; ax <- error code
	mov	si, ax			; si <- error code
	shl	si, 1			; si <- offset into chunks
	add	si, offset err_badNumber ; si <- chunk handle

;	mov	ax, bx			; ax <- resource ID
;	mov	bx, handle 0		; bx <- handle of the geode
;	call	GeodeGetGeodeResourceHandle ; bx <- handle of the resource

	mov	bx, handle ErrorMessages
	call	MemLock			; ax <- seg addr of resource
	mov	ds, ax			; ds <- segment of resource
	mov	si, ds:[si]		; ds:si <- ptr to source
	
	ChunkSizePtr	ds, si, cx	; cx <- size of string
	
	push	cx			; Save size
	rep	movsb			; Move the data
	pop	cx			; Restore size
DBCS<	shr	cx, 1			; cx <- string length		>
	dec	cx			; Don't count NULL
	
	call	MemUnlock		; Unlock the resource
	.leave
	ret
ParserErrorMessage	endp

;
; One ForceRef for every error message so that the assembler & linker don't
; complain that these symbols aren't accessed.
;
ForceRef	err_badNumber
ForceRef	err_badCellReference
ForceRef	err_noCloseQuote
ForceRef	err_columnTooLarge
ForceRef	err_rowTooLarge
ForceRef	err_general
ForceRef	err_tooManyTokens
ForceRef	err_expectedOpenParen
ForceRef	err_expectedCloseParen
ForceRef	err_badExpression
ForceRef	err_expectedEOE
ForceRef	err_missingCloseParen
ForceRef	err_outOfStackSpace
ForceRef	err_rowOutOfRange
ForceRef	err_columnOutOfRange
ForceRef	err_functionNoLongerExists
ForceRef	err_illegalToken
ForceRef	err_tooManyDependencies
ForceRef	err_unknownIdentifier
ForceRef	err_notEnoughNameSpace
ForceRef	err_tooMuchNesting
ForceRef	err_badArgCount
ForceRef	err_wrongType
ForceRef	err_divideByZero
ForceRef	err_undefinedName
ForceRef	err_circularRef
ForceRef	err_circularDep
ForceRef	err_circularNameRef
ForceRef	err_genErr
ForceRef	err_floatPosInfinity
ForceRef	err_floatNegInfinity
ForceRef	err_floatGenErr
ForceRef	err_numOutOfRange

ParserErrorCode	ends
