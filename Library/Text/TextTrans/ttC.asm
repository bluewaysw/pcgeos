COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	Text
FILE:		ttC.asm

AUTHOR:		Andrew Wilson, Oct  9, 1991

ROUTINES:
	Name				Description
	----				-----------
	TEXTALLOCCLIPBOARDOBJECT	C Stub for TextAllocClipboardObject
	TEXTFINISHWITHCLIPBOARDOBJECT	C Stup for TextFinishWithClipboardObject
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/8/92		Initial revision

DESCRIPTION:
	Contains C stubs for Text*Clipboard* routines

	$Id: ttC.asm,v 1.1 97/04/07 11:19:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

TextC	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEXTALLOCCLIPBOARDOBJECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just a CStub for TextAllocClipboardObject

C DECLARATION:	extern VMBlockHandle
			_far _pascal TextAllocClipboardObject(
					VMFileHandle file,
					word storageFlags,
					word regionFlag);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	TEXTALLOCCLIPBOARDOBJECT:far
TEXTALLOCCLIPBOARDOBJECT	proc	far	vmfile:word,
						storageFlags:word,
						regionFlag:word
	uses	si
	.enter
	mov	al, storageFlags.low
	mov	ah, regionFlag.low
	mov	bx, vmfile
	call	TextAllocClipboardObject	; ^lbx:si = text object
	mov	dx, bx				; ^ldx:ax = text object
	mov	ax, si
	.leave
	ret
TEXTALLOCCLIPBOARDOBJECT	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEXTFINISHWITHCLIPBOARDOBJECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just a CStub for TextFinishWithClipboardObject

C DECLARATION:	extern VMBlockHandle
			_far _pascal TextFinishWithClipboardObject(
						optr obj,
						TextClipboardOption opt,
						optr owner,
						char *name);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	TEXTFINISHWITHCLIPBOARDOBJECT:far
TEXTFINISHWITHCLIPBOARDOBJECT	proc	far	textObj:optr,
						opt:TextClipboardOption,
						owner:optr,
						scrapname:fptr.char
	uses	si, es, di
	.enter
	mov	bx, textObj.handle
	mov	si, textObj.chunk
	movdw	cxdx, owner
	les	di, scrapname
	mov	ax, opt
	call	TextFinishWithClipboardObject	; ax = VM block
	.leave
	ret
TEXTFINISHWITHCLIPBOARDOBJECT	endp

TextC	ends

	SetDefaultConvention
