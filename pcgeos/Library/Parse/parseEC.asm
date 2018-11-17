COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		parseEC.asm

AUTHOR:		John Wedgwood, Jan 16, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 1/16/91	Initial revision

DESCRIPTION:
	Error checking code for the parser library.
	None of the routines in here destroy any registers or flags

	$Id: parseEC.asm,v 1.1 97/04/05 01:27:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckPointer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a pointer to make sure it's valid

CALLED BY:	Utility
PASS:		ds:si	= Pointer to check
RETURN:		nothing
DESTROYED:	nothing (not even flags)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckPointer	proc	far
	uses	ax, bx, cx, dx, di
	.enter
	pushf

	mov	ax, ds			; ax <- segment to check
	call	ECCheckSegment		; Check the segment...
	
	mov	cx, ds			; cx <- segment
	call	MemSegmentToHandle	; cx <- handle
	ERROR_NC PARSE_SEGMENT_HAS_NO_HANDLE
	
	mov	bx, cx			; bx <- handle to check
	mov	ax, MGIT_FLAGS_AND_LOCK_COUNT
	call	MemGetInfo
	mov	cx, ax			; cl <- flags, ch <- lock count
	mov	ax, MGIT_SIZE		; ax <- MemGetInfoType
	call	MemGetInfo		; ax <- size in bytes
	
	test	cl, mask HF_FIXED	; Check for fixed block
	jnz	skipLockCheck
	tst	ch			; Check for unlocked block
	ERROR_Z	PARSE_SEGMENT_IN_UNLOCKED_BLOCK
skipLockCheck:
	cmp	si, ax			; Check offset vs. block size
	ERROR_A	PARSE_PASSED_OFFSET_PAST_END_OF_BLOCK
	
	popf
	.leave
	ret
ECCheckPointer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckPointerESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a pointer in es:di

CALLED BY:	Utility
PASS:		es:di	= Pointer to check
RETURN:		nothing
DESTROYED:	nothing (not even flags)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckPointerESDI	proc	far
	uses	ds, si
	.enter
	pushf

	segmov	ds, es
	mov	si, di
	call	ECCheckPointer
	
	popf
	.leave
	ret
ECCheckPointerESDI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckPointerESBX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a pointer in es:bx

CALLED BY:	Utility
PASS:		es:bx	= Pointer to check
RETURN:		nothing
DESTROYED:	nothing (not even flags)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckPointerESBX	proc	far
	uses	ds, si
	.enter
	pushf

	segmov	ds, es
	mov	si, bx
	call	ECCheckPointer
	
	popf
	.leave
	ret
ECCheckPointerESBX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckParserParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the ParserParameters structure passed to ParserParseString

CALLED BY:	ParserParseString
PASS:		es:di	= Pointer to buffer to put parsed tokens in.
		ds:si	= Pointer to text to parse.
		ss:bp	= ParserParameters
RETURN:		nothing
DESTROYED:	nothing (not even flags)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckParserParameters	proc	far
	uses	ax, es, di, si
	.enter
	pushf
	;
	; Check for legal current row.
	;
	mov	ax, ss:[bp].CP_row
	cmp	ax, ss:[bp].CP_maxRow
	ERROR_A	PARSER_CURRENT_ROW_BEYOND_MAX_ROW
	;
	; Check for legal current column.
	;
	mov	ax, ss:[bp].CP_column
	cmp	ax, ss:[bp].CP_maxColumn
	ERROR_A	PARSER_CURRENT_COLUMN_BEYOND_MAX_COLUMN
	;
	; Check to see if passed buffer size is correct.
	;
	add	di, ss:[bp].PP_parserBufferSize
	dec	di			; es:di <- ptr to last byte of buffer
	call	ECCheckPointerESDI	; Die if size is wrong
	;
	; Make sure that the callback routines are OK.
	;
ife FULL_EXECUTE_IN_PLACE
	mov	es, ss:[bp].CP_callback.segment
	mov	di, ss:[bp].CP_callback.offset
	call	ECCheckPointerESDI	; Die if callback is bad
endif
	;
	; Run through the text looking for control characters which
	; aren't whitespace characters.
	;
stringLoop:
	LocalGetChar	ax, dssi	; al <- next byte
	LocalIsNull	ax		; Check for NULL
	jz	stringOK		; Branch if NULL
	LocalCmpChar	ax, C_SPACE
	jae	stringLoop		; Branch if legal char or whitespace.
	LocalCmpChar	ax, C_CR		
	je	stringLoop		; Branch if whitespace
	LocalCmpChar	ax, C_TAB		
	je	stringLoop		; Branch if whitespace
	ERROR	PARSER_TEXT_CONTAINS_ILLEGAL_CONTROL_CHARACTERS
stringOK:

	popf
	.leave
	ret
ECCheckParserParameters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckEvalParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the parameters passed to ParserEvalExpression.

CALLED BY:	ParserEvalExpression
PASS:		ss:bp	= Pointer to EvalParameters on stack
RETURN:		nothing
DESTROYED:	nothing (not even flags)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckEvalParameters	proc	far
	uses	ax, es, di
	.enter
	pushf
	;
	; Make sure that the callback routine is OK.
	;
	mov	es, ss:[bp].CP_callback.segment
	mov	di, ss:[bp].CP_callback.offset
	call	ECCheckPointerESDI	; Die if callback is bad
	popf
	.leave
	ret
ECCheckEvalParameters	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckBXFileHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if bx contains a file handle

CALLED BY:	Utility
PASS:		bx	= Register to check
RETURN:		nothing
DESTROYED:	nothing (not even flags)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	0
ECCheckBXFileHandle	proc	far
	uses	bx
	.enter
	pushf
	call	ECVMHandleVMFileOverride	; bx <- file to use
	call	ECVMCheckFileHandle		; Check the handle
	popf
	.leave
	ret
ECCheckBXFileHandle	endp
endif

ECCode	ends
