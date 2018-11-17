COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Misc	
FILE:		miscLetterTabInvert.asm

AUTHOR:		Ted H. Kim, March 9, 1992

ROUTINES:
	Name			Description
	----			-----------
	LettersInvertTab	Inverts the letter tab for non-CGA mode
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial revision

DESCRIPTION:
	Contains routines used to invert the letter tab polygon.

	$Id: miscLetterTabInvert.asm,v 1.1 97/04/04 15:50:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LettersCode     segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersInvertTab 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates all vertices that comprise a tab and inverts it.

CALLED BY:	(INTERNAL)

PASS:		ax - letter number
		cx - left position of tab
		bx - top position of tab
		di - handle of gState
		ds - seg addr of instance data
		es - seg addr of core block

RETURN:		tab inverted
		ds:si - pointer to coordBuffer
		es:bx - instance data for LettersClass 
		cx - number of vertices

DESTROYED:	dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	2/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersInvertTab	proc	near	uses	ax
	.enter

	push	si

	clr	dx			; assume not 'A', nor 'K', nor 'U'
	tst	ax			; is it 'A'? 
	je	flag			; if so, skip to set a flag
	cmp	ax, LTI_K		; is it 'K'?
	je	flag			; if so, skip to set a flag
	cmp	ax, LTI_U		; is it 'U'?
	jne	common			; if not, skip
flag:
	mov	dx, -1			; set flag to indicate 'A', 'K', or 'U'

	; if dx = -1, then the letter tab to invert is A or K or U
	; if dx = 0, then the letter tab to invert is not A nor K nor U

common:
	cmp	ax, LTRN_ROW_2		; is the tab in the 1st row?
	jge	not1st			; if not, skip
	add	cx, RIGHT_BOUND_ADJUST	; if so, adjust x position
not1st:
	push	ds			; ds - seg address of instance data
	clr	si			; si - offset to coordBuffer
	segmov	ds, es			; ds - seg addr of coordBuffer

	; Each letter tab is a complex polygon.  In order to invert it,
	; we first have to figure out the coordnates of all the vertices
	; that comprise this polygon.

	; calculate vertex number 1

	mov	ds:coordBuffer[si], cx	; X1	
	add	ds:coordBuffer[si], VERTEX1_X1_ADJUST	; adjust X1

	tst	dx			; is this A, K, or U?
	js	firstTab		; if so, skip
	sub	ds:coordBuffer[si], VERTEX1_X1_ADJUST2	; if not, adjust X1
firstTab:
	mov	ds:coordBuffer[si+2], bx; Y1
	call	AdjustForTenthColumn
	add	si, COORDINATE_SIZE	; update the ptr into coordBuffer

	; calculate vertex number 2

	mov	ds:coordBuffer[si], cx	; X2
	add	ds:coordBuffer[si], VERTEX2_X2_ADJUST	; adjust X2

	cmp	ax, LTI_T		; is it 'T'?
	jne	notR			; if not, skip
	inc	ds:coordBuffer[si]	; if so, adjust X2
notR:
	mov	ds:coordBuffer[si+2], bx; Y2
	call	AdjustForNinthColumn
	call	AdjustForTenthColumn
	add	si, COORDINATE_SIZE	; update the ptr into coordBuffer

	; calculate vertex number 3

	mov	ds:coordBuffer[si], cx	; X3
	add	ds:coordBuffer[si], VERTEX3_X3_ADJUST	; adjust X3

	cmp	ax, LTI_T		; is it 'T'?
	jne	notR2			; if not, skip		
	inc	ds:coordBuffer[si]	; if so, adjust X3
notR2:
	mov	ds:coordBuffer[si+2], bx; Y3
	add	ds:coordBuffer[si+2], VERTEX3_Y3_ADJUST ; adjust Y3
	call	AdjustForNinthColumn
	call	AdjustForTenthColumn
	add	si, COORDINATE_SIZE	; update the ptr into coordBuffer

	; calculate vertex number 4
	
	cmp	ax, LTI_T		; is it 'T'?
	jne	notR3			; if not, skip

	mov	ds:coordBuffer[si], cx	; X4 for letter tab 'T'
	add	ds:coordBuffer[si], VERTEX4_X4_ADJUST	; adjust X4
	mov	ds:coordBuffer[si+2], bx; Y4
	add	ds:coordBuffer[si+2], VERTEX4_Y4_ADJUST	; adjust Y4
	tst	es:[colorFlag]		; EGA or VGA mode?
	js	vertex5			; if so, skip
	inc	ds:coordBuffer[si+2]	; adjust Y4
	jmp	short	vertex5		; update the ptr into coordBuffer
notR3:
	cmp	ax, LTI_RECYCLE		; is it recycle tab?
	jne	notStar			; if not, skip

	mov	ds:coordBuffer[si], cx	; X4 for recycle tab
	add	ds:coordBuffer[si], VERTEX4_X4_ADJUST2	; adjust X4
	mov	ds:coordBuffer[si+2], bx; Y4
	add	ds:coordBuffer[si+2], VERTEX4_Y4_ADJUST2; adjust Y4
	tst	es:[colorFlag]		; EGA or VGA mode?
	js	vertex5			; if so, skip		
	inc	ds:coordBuffer[si+2]	; adjust Y4
	jmp	short	vertex5		
notStar:
	mov	ds:coordBuffer[si], cx	; X4
	add	ds:coordBuffer[si], VERTEX4_X4_ADJUST3
	mov	ds:coordBuffer[si+2], bx ; Y4
	add	ds:coordBuffer[si+2], VERTEX4_Y4_ADJUST3
vertex5:
	call	AdjustForNinthColumn
	call	AdjustForTenthColumn
	add	si, COORDINATE_SIZE	; update the ptr into coordBuffer

	; calculate vertex number 5 for recycle or 'T'

	cmp	ax, LTI_RECYCLE		; is it recycle tab?
	jne	notStar2		; if not, skip

	mov	ds:coordBuffer[si], cx	; X5 for recycle tab
	add	ds:coordBuffer[si], VERTEX5_X5_ADJUST	; adjust X5

	;tst	ds:[colorFlag]		; is this a color monitor?
	;jns	bw			; if not, skip
	dec	ds:coordBuffer[si]	; if so, adjust x position
;bw:
	mov	ds:coordBuffer[si+2], bx; Y5
	add	ds:coordBuffer[si+2], VERTEX5_Y5_ADJUST	; adjust Y5
	add	si, COORDINATE_SIZE	; update the ptr into coordBuffer
	jmp	short	vertex6

notStar2:
	cmp	ax, LTI_T		; is it 'T'?
	jne	notR4			; if not, skip
	mov	ds:coordBuffer[si], cx	; X5
	add	ds:coordBuffer[si], VERTEX5_X5_ADJUST2	; adjust X5

	;tst	ds:[colorFlag]		; is this a color monitor?
	;jns	bw2			; if not, skip
	dec	ds:coordBuffer[si]	; if so, adjust x position
;bw2:
	mov	ds:coordBuffer[si+2], bx; Y5
	add	ds:coordBuffer[si+2], VERTEX5_Y5_ADJUST	; adjust Y5
	;call	AdjustForTenthColumn
	add	si, COORDINATE_SIZE	; update the ptr into coordBuffer
	jmp	short	vertex6
notR4:
	cmp	ax, LTRN_ROW_2		; is this row one?
	jl	vertex6			; if so, skip

	; calculate vertex number 5 for any letter in the second or 
	; the third row except recycle tab and 'T'

	mov	ds:coordBuffer[si], cx	; X5
	add	ds:coordBuffer[si], VERTEX5_X5_ADJUST+1	; adjust X5
	mov	ds:coordBuffer[si+2], bx; Y5
	add	ds:coordBuffer[si+2], VERTEX5_Y5_ADJUST	; adjust Y5
	add	si, COORDINATE_SIZE	; update the ptr into coordBuffer

	; calculate vertex number 6 for any letter in the second or
	; the third row except recycle tab and 'T'

	mov	ds:coordBuffer[si], cx	; X6
	add	ds:coordBuffer[si], VERTEX6_X6_ADJUST	; adjust X6
	mov	ds:coordBuffer[si+2], bx; Y6
	add	ds:coordBuffer[si+2], VERTEX6_Y6_ADJUST	; adjust Y6
	call	AdjustForNinthColumn
	add	si, COORDINATE_SIZE	; update the ptr into coordBuffer

	; calculate vertex number 7 for any letter in the second or
	; the third row except recycle tab and 'T'

	mov	ds:coordBuffer[si], cx	; X7
	add	ds:coordBuffer[si], VERTEX7_X7_ADJUST	; adjust X7
	mov	ds:coordBuffer[si+2], bx; Y7
	add	ds:coordBuffer[si+2], VERTEX7_Y7_ADJUST	; adjust Y7
	call	AdjustForNinthColumn
	add	si, COORDINATE_SIZE	; update the ptr into coordBuffer

vertex6:
	; calculate vertex number 5 for 'B' through 'J'
	; number 6 for recycle and 'T', and number 7 for the rest

	mov	ds:coordBuffer[si], cx	; X7

	tst	dx			; is this A, K, or U?
	js	firstTab2		; if so, skip

	add	ds:coordBuffer[si], VERTEX7_X7_ADJUST2	; if not, adjust X7
firstTab2:
	mov	ds:coordBuffer[si+2], bx; Y7
	add	ds:coordBuffer[si+2], VERTEX7_Y7_ADJUST	; adjust Y7
	add	si, COORDINATE_SIZE	; update the ptr into coordBuffer

	; calculate vertex number 6 for 'B' through 'J'
	; number 7 for recycle tab and 'T', and number 8 for the rest

	mov	ds:coordBuffer[si], cx	; X8

	tst	dx			; is this A, K, or U?
	js	firstTab3		; if so, skip

	add	ds:coordBuffer[si], VERTEX8_X8_ADJUST	; if not, adjust X8
firstTab3:
	mov	ds:coordBuffer[si+2], bx; Y8
	add	ds:coordBuffer[si+2], VERTEX8_Y8_ADJUST	; adjust Y8
	add	si, COORDINATE_SIZE	; update the ptr into coordBuffer

	mov	si, offset coordBuffer	; ds:si - ptr to coord buffer

	cmp	ax, LTI_T		; is it 'T'?
	je	isAnR			; if so, skip

	cmp	ax, LTI_RECYCLE		; is it recycle tab?
	jne	notStar3		; if not, skip
isAnR:
	; for letter tabs 'T' and recycle tab, total # of vertices is 7

	mov	cx, NUMBER_OF_COORDINATES1	; cx - # of pts in polygon
	jmp	draw			; jump to invert the polygon
notStar3:

	; for letters in the 2nd and the 3rd row, total # of vertices is 9

	mov	cx, NUMBER_OF_COORDINATES2	; cx - # of pts in polygon
	cmp	ax, LTRN_ROW_2		; is the tab in the 1st row?
	jge	draw			; if not, skip

	; for letters in the 1st row, total # of vertices is 6

	mov	cx, NUMBER_OF_COORDINATES3	; cx - # of pts in polygon
draw:
	mov	al, MM_INVERT
	call	GrSetMixMode		; set to invert mode

	mov	al, RFR_ODD_EVEN	; use the odd even rule
	call	GrFillPolygon		; invert the tab

	mov	al, MM_COPY
	call	GrSetMixMode		; set to normal mode
	pop	es			; es - seg address of instance data
	pop	bx			; es:di - ptr to instance data

	.leave
	ret
LettersInvertTab	endp

AdjustForNinthColumn	proc	near
	tst	es:[colorFlag]
	jns	exit
	cmp	ax, LTI_I		; is it 'I'?
	je	adjust			; if so, skip

	cmp	ax, LTI_S		; is it 'S'?
	je	adjust			; if so, skip

	cmp	ax, LTI_SPACE2		; is it second blank tab?
	jne	exit
adjust:
	inc	ds:coordBuffer[si]	; adjust X8
exit:
	ret
AdjustForNinthColumn	endp

AdjustForTenthColumn	proc	near
	tst	es:[colorFlag]
	jns	exit
	cmp	ax, LTI_J		; is it 'J'?
	je	adjust			; if so, skip

	cmp	ax, LTI_T		; is it 'T'?
	je	adjust			; if so, skip

	cmp	ax, LTI_RECYCLE		; is it recycle tab?
	jne	exit
adjust:
	inc	ds:coordBuffer[si]	; adjust X8
exit:
	ret
AdjustForTenthColumn	endp

LettersCode     ends
