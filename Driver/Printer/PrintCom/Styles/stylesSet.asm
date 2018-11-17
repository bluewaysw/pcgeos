COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		stylesSet.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintSetStyles		Set printer text style word

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/1/90		Initial revision
	Dave	3/92		Moved in a bunch of common test routines
	Dave	5/92		Parsed from printcomText.asm


DESCRIPTION:

	$Id: stylesSet.asm,v 1.1 97/04/18 11:51:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetStyles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set new current style

CALLED BY: 	GLOBAL

PASS:		bp	- Segment of PSTATE
		dx	- style word

		(PrintClearStyles)
		es	- Segment of PState
	
RETURN: 	carry	- set if some type of cummunications error

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	02/90		Initial version
		Jim	3/90		Added check for NLQ mode and split
					into two routines

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetStyles	proc	far

	call	PrintTestStyles
	push	es
        mov     es, bp          ; set ds -> PState
	call	PrintSetStylesInt
	pop	es

	ret
PrintSetStyles	endp

PrintClearStyles	proc	near
	uses	dx
	.enter
	clr	dx		; init the styles word.
	call	PrintSetStylesInt
	.leave
	ret
PrintClearStyles	endp

PrintSetStylesInt	proc	near
	uses	ax,bx,cx,dx,si
	.enter

	mov	ax, dx		; get a copy of the flags
	xchg	dx,es:[PS_asciiStyle] ; get the curr styles, set new.
	xor	dx,ax		; see which are different.
	mov	cx,16		; load the loop counter.

bitloop:
	rcl	dx,1		; shift off a style bit.
	jnc	nextbit		; skip call if the bits are the same.
	push	ax		; save new style.
	push	cx		; save loop counter.
	call	SetStyle	; set or reset this style.
	pop	cx		; recover loop counter.
	pop	ax
	jc	exit		; done if any communications errors

nextbit:
	loop	bitloop
	clc

exit:
	.leave
	ret
PrintSetStylesInt	endp

SetStyle	proc	near

	mov	bx,cx
	sal	bx,1		; for word index.
	rcr	ax,cl		; get style bit into carry.
	jnc	resetStyle	; if carry not set, we reset the style.
	call	{word} cs:setStyleTab[bx-2] ; set the style.
	ret

resetStyle:
	call	{word} cs:resetStyleTab[bx-2] ; reset the style.
	ret
SetStyle	endp


;-----------------------------------------------------------------------
;		Jump Tables for setting/resetting text styles
;-----------------------------------------------------------------------

setStyleTab	label	word
	nptr	SetFuture
	nptr	SetOverline
	nptr	SetQuadHeight
	nptr	SetDblHeight
	nptr	SetDblWidth
	nptr	SetReverse
	nptr	SetOutline
	nptr	SetShadow
	nptr	SetStrikeThru
	nptr	SetUnderline
	nptr	SetItalic
	nptr	SetBold
	nptr	SetNLQ
	nptr	SetSuperscript
	nptr	SetSubscript
	nptr	SetCondensed

resetStyleTab	label	word
	nptr	ResetFuture
	nptr	ResetOverline
	nptr	ResetQuadHeight
	nptr	ResetDblHeight
	nptr	ResetDblWidth
	nptr	ResetReverse
	nptr	ResetOutline
	nptr	ResetShadow
	nptr	ResetStrikeThru
	nptr	ResetUnderline
	nptr	ResetItalic
	nptr	ResetBold
	nptr	ResetNLQ
	nptr	ResetSuperscript
	nptr	ResetSubscript
	nptr	ResetCondensed

