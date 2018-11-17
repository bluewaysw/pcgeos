COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	Text
FILE:		tssC.asm

AUTHOR:		Andrew Wilson, Oct  9, 1991

ROUTINES:
	Name			Description
	----			-----------
	TEXTSEARCHINSTRING	C Stub for TextSearchInString
	TEXTSEARCHINHUGEARRAY	C Stup for TextSearchInHugeArray
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 9/91		Initial revision

DESCRIPTION:
	Contains C stubs for TextSearchIn... routines

	$Id: tssC.asm,v 1.1 97/04/07 11:19:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

TextC	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEXTSEARCHINSTRING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just a CStub for TextSearchInString

C DECLARATION: char * _far 
    _pascal TextSearchInString(const char *str1, const char *startPtr,
			 	const char *endPtr, word str1Size,
				const char *str2, word str2Size,
				word searchOptions, word *matchLen);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	TEXTSEARCHINSTRING:far
TEXTSEARCHINSTRING	proc	far	str1:fptr.char, startPtr:fptr.char, \
					endPtr:fptr.char, str1Size:word, \
					str2:fptr.char, str2Size:word, \
					searchOptions:word, matchLen:fptr.word
	uses	ds, si, es, di, bp
	.enter
EC <	mov	ax, str1.segment					>
EC <	cmp	ax, startPtr.segment					>
EC <	ERROR_NZ START_PTR_MUST_BE_IN_SAME_SEGMENT_AS_END_PTR		>
EC <	cmp	ax, endPtr.segment					>
EC <	ERROR_NZ START_PTR_MUST_BE_IN_SAME_SEGMENT_AS_END_PTR		>
	les	di, startPtr
	mov	bx, endPtr.offset
	lds	si, str2
	mov	cx, str2Size
	mov	dx, str1Size
	mov	al, searchOptions.low
	push	bp
	mov	bp, str1.offset
	call	TextSearchInString
	pop	bp

	mov	dx, 0			;Don't change these to CLRs!
	mov	ax, 0
	jc	exit
	movdw	dxax, esdi
	les	di, matchLen
	mov	es:[di], cx
exit:
	.leave
	ret
TEXTSEARCHINSTRING	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEXTSEARCHINHUGEARRAY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just a CStub for TextSearchInHugeArray

C DECLARATION: dword _far _pascal
    _pascal TextSearchInHugeArray(char *str2, word str2Size,
				       dword str1Size, dword curOffset,
				       dword endOffset, 
				       FileHandle hugeArrayFile,
				       VMBlockHandle hugeArrayBlock,
				       SearchOptions searchOptions, dword *matchLen);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	TEXTSEARCHINHUGEARRAY:far
TEXTSEARCHINHUGEARRAY	proc	far str2:fptr.char,  str2Size:word, \
				    str1Size:dword, curOffset:dword, \
				    endOffset:dword, hugeArrayFileHan:hptr, \
				    hugeArrayBlock:hptr, searchOptions:word, \
				    matchLen:fptr.dword

		uses	ds, si, bp
		.enter
		sub	sp, size TextSearchInHugeArrayFrame
		mov	si, sp
		movdw	ss:[si].TSIHAF_str1Size, str1Size, ax
		movdw	ss:[si].TSIHAF_curOffset, curOffset, ax
		movdw	ss:[si].TSIHAF_endOffset, endOffset, ax
		mov	ax, hugeArrayFileHan
		mov	ss:[si].TSIHAF_hugeArrayVMFile, ax
		mov	ax, hugeArrayBlock
		mov	ss:[si].TSIHAF_hugeArrayVMBlock, ax
		mov	al, searchOptions.low
		mov	ss:[si].TSIHAF_searchFlags, al

		push	bp
		lds	si, str2
		mov	cx, str2Size
		call	TextSearchInHugeArray
		mov	ax, bp
		pop	bp
		lds	si, matchLen
		jc	notFound
		movdw	ds:[si], axcx
exit:
		add	sp, TextSearchInHugeArrayFrame
		.leave
		ret

notFound:
		clrdw	ds:[si]
		jmp	exit
		
TEXTSEARCHINHUGEARRAY	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEXTSETSPELLLIBRARY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just a CStub for TextSetSpellLibrary

C DECLARATION: extern void 	/* XXX */ 
     _pascal TextSetSpellLibrary(MemHandle libHandle);


PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	TEXTSETSPELLLIBRARY:far
TEXTSETSPELLLIBRARY	proc	far	libHandle:hptr.MemHandle
	uses	bx
	.enter

	mov	bx, ss:[libHandle]
	call	TextSetSpellLibrary
	
	.leave
	ret
TEXTSETSPELLLIBRARY		endp

	ForceRef	TEXTSETSPELLLIBRARY

TextC	ends

	SetDefaultConvention

