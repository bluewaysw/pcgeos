COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CMain
FILE:		cmainCharTable.asm

AUTHOR:		Andrew Wilson, Oct 12, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/12/92	Initial revision
	dlitwin	4/12/94		Moved to SPUI from UI, renamed from
				uiCharTable.asm to cmainCharTable.asm
	dlitwin	4/29/94		Changed the way the initfile keyboard
				conditionals work such that there is 
				now the concept of initfile keyboard or
				non-initfile keyboard, which relys on the
				generic KEYBOARD_... constants to be set
				correcly instead of having conditionals
				for each keyboard available.

DESCRIPTION:
	Contains code to implement the char table object (VisCharTableClass)

	$Id: cmainCharTable.asm,v 1.11 95/11/15 17:46:38 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonUIClassStructures segment resource

	VisCharTableClass

CommonUIClassStructures ends


CharTableCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the GState for drawing.

CALLED BY:	GLOBAL
PASS:		*ds:si	= VisCharTableClass object
		^hdi	= GState

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/12/92	Initial version
	dlitwin	4/29/94		Generalized IKBD/SKBD/ZKBD to allow other KBDs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupGState	proc	near
	.enter

	mov	bx, ds:[si]
	add	bx, ds:[bx].VisCharTable_offset	; deref VisCharTable into bx
	mov	cx, ds:[bx].VCTI_fontType
	mov	dx, ds:[bx].VCTI_fontSize
	clr	ax				;dx.ah <- pointsize (WBFixed)
	call	GrSetFont

	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetAreaColor			;clear out key

	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetLineColor

	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetTextColor

	.leave
	ret
SetupGState	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisCharTableVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the GState before drawing

CALLED BY:	GLOBAL
PASS:		*ds:si	= VisCharTableClass object
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisCharTableVisOpen	method	VisCharTableClass, MSG_VIS_OPEN
	.enter
	mov	di, offset VisCharTableClass
	call	ObjCallSuperNoLock

	;
	; Setup params in the cached gstate.
	;
	call	VisCharTableGetGState
	call	SetupGState

	.leave
	ret
VisCharTableVisOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisCharTableDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the data for this object.

CALLED BY:	GLOBAL
PASS:		es - segment of VisCharTableClass 
		bp - ^hGState
		cl - DrawFlags
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, si, di, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/13/92		Initial version
	JT	7/27/92		Modified to draw Character Table
	dlitwin	4/29/94		Generalized IKBD/SKBD/ZKBD to allow other KBDs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisCharTableDraw	method	VisCharTableClass, MSG_VIS_DRAW
top		local	word
noOptimize	local	word

	mov	di, bp				; di gets passed in GState
	.enter

	segmov	es, dgroup, ax
	call	SetupGState

;	Check to see if the view is fully enabled. If not, draw this object
;	in a 50% pattern.

	push	si, di
	mov	ax, MSG_VIS_GET_ATTRS
	mov	bx, segment GenViewClass
	mov	si, offset GenViewClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			;CX <- classed event
	pop	si, di

	push	bp
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	VisCallParent
	pop	bp
	test	cl, mask VA_FULLY_ENABLED
	jnz	isFullyEnabled

	mov	al, SDM_50
	call	GrSetLineMask
	call	GrSetAreaMask
	call	GrSetTextMask
isFullyEnabled:

	call	CharTableCountNumberColumns	;CX <- # columns
if _NIKE
	; we need to draw the last vertical bar for characters that does
	; not fill up the whole character table
	mov	ss:[noOptimize], 1
else
	mov	ss:[noOptimize], ax		;If there are no space filler
						; chars in the data, we can
						; do an optimized draw	
endif
	push	bp
	call	GetCharTableInfo		;ax <- top of the rectangle
						;bx <- left of the rectangle
						;cx <- width of the rectangle
						;dx <- rows of the CharTable
	pop	bp
	mov	ss:[top], ax
EC <	tst	dx							>
EC <	ERROR_Z	CHAR_TABLE_MUST_HAVE_AT_LEAST_ONE_LINE			>

	tst	ss:[noOptimize]
	jnz	noOptimization

;	Draw the lines in between

	push	dx				;Save # rows
	xchg	ax, bx				;AX <- left, BX <- right
IKBD <	push	es			>
IKBD <	segmov	es, dgroup, cx		>
IKBD <	mov	cx, es:[charTableWidth]	>
IKBD <	pop	es			>
IKBD <	dec	cx			>
NOTIKBD<mov	cx, KEYBOARD_CHAR_TABLE_WIDTH-1 >
						;We know the char table is 
						; centered, so we can get the
						; right edge of the rectangle
						; by subtracting the left edge
						; from the max width
	sub	cx, ax				;CX <- right edge of CharTable
drawInnerLine:
IKBD <	push	es, ax							>
IKBD <	segmov	es, dgroup, ax						>
IKBD <	add	bx, es:[charTableRectHeight]				>
IKBD <	pop	es, ax							>
NOTIKBD<add	bx, KEYBOARD_CHAR_TABLE_RECT_HEIGHT			>
	dec	dx
	jz	drawOuterRectangle
	call	GrDrawHLine
	jmp	drawInnerLine

drawOuterRectangle:
	mov	dx, bx
	mov	bx, ss:[top]
	call	GrDrawRect
	pop	dx				;Restore # rows
	mov_tr	bx, ax				;AX <- left edge of char table

noOptimization:
	mov	cx, dx 				;CX <- # rows of char table
	mov	dx, bx				;DX <- left edge of char table
	mov	si, ds:[si]
	add	si, ds:[si].VisCharTable_offset
	add	si, offset VCTI_line1
	segmov	es, ds

drawLoop:

;	Draw each row, until there are no more
;
;	ES:SI <- ptr to optr containing line data
;	DX <- left edge of char table

	push	si
	movdw	bxsi, es:[si]
	
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]			;DS:SI <- string to draw

	push	bx
	mov	ax, ss:[noOptimize]
	mov	bx, ss:[top]
	call	CharTableDrawOneRow		;
	pop	bx
	call	MemUnlock
	pop	si
	add	si, size optr
IKBD <	LoadVarSeg	ds, ax						>
IKBD <	mov	ax, ds:[charTableRectHeight]				>
IKBD <	add	ss:[top], ax						>
NOTIKBD<add	ss:[top], KEYBOARD_CHAR_TABLE_RECT_HEIGHT		>
	loop	drawLoop

	.leave
	ret
VisCharTableDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCharTableInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Find out the top, left and width of a rectangle in the
		Character Table and the rows and columns of the CharTable
CALLED BY:	VisCharTableDraw
PASS:		*ds:si - VisCharTable object
		di - ^hGState
		es - dgroup
RETURN:		ax - top of the rectangle
		bx - left of the rectangle
		cx - width of the rectangle
		dx - rows of the CharTable
		bp - columns of the CharTable
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	8/12/92		Initial version
	dlitwin	4/29/94		Generalized IKBD/SKBD/ZKBD to allow other KBDs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCharTableInfo	proc	near
	.enter

EC <	call	ECLMemValidateHeap					>
	call	CharTableCountNumberRows	;dx <- # of rows

EC <	call	ECLMemValidateHeap					>
	call	CharTableCountNumberColumns	;cx <- # of columns
	mov	bp, cx				;bp <- # of columns

IKBD_EC<call	ECCheckESDGroup						>
IKBD <	mov	cx, es:[charTableRectWidth]				>
NOTIKBD<mov	cx, KEYBOARD_CHAR_TABLE_RECT_WIDTH			>

	call	GetCenteredTableTopLeftCoord	;ax <- top of the rectangle
						;bx <- left of the rectangle
	.leave
	ret
GetCharTableInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCenteredTableTopLeftCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Get the left and top coordinates of the centered CharTable
CALLED BY:	GetCharTableInfo
PASS:		es - dgroup
		dx - number rows
		bp - number columns
		cx - width of the rectangle

RETURN:		ax - top of the rectangle
		bx - left of the rectangle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		left = [CHAR_TABLE_WIDTH - rectWidth * current col #] /2
		top  = [CHAR_TABLE_HEIGHT - rectHeight * current row #] /2

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	8/12/92		Initial version
	dlitwin	4/29/94		Generalized IKBD/SKBD/ZKBD to allow other KBDs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCenteredTableTopLeftCoord	proc	near	uses	cx, dx
	.enter

	push	dx
	mov	ax, bp				;AX <- # columns
	clr	dx				;
	mul	cx				;DX.AX <- width of area
IKBD_EC<call	ECCheckESDGroup						>
IKBD <	mov	bx, es:[charTableWidth]					>
NOTIKBD<mov	bx, KEYBOARD_CHAR_TABLE_WIDTH				>
	sub	bx, ax
	shr	bx, 1				;bx <- left
	pop	dx

	mov	ax, dx
	clr	dx
IKBD <	mov	cx, es:[charTableRectHeight]				>
NOTIKBD<mov	cx, KEYBOARD_CHAR_TABLE_RECT_HEIGHT			>
	mul	cx
IKBD <	mov	cx, es:[charTableHeight]				>
NOTIKBD<mov	cx, KEYBOARD_CHAR_TABLE_HEIGHT				>
	sub	cx, ax
	shr	cx, 1				;cx <- top
	mov_tr	ax, cx				;ax <- top

	.leave
	ret
GetCenteredTableTopLeftCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharTableCountNumberColumns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Count number of columns in the Character Table assuming each
		row has the same number of columns except for the one with
		special attribute
CALLED BY:	VisCharTableDraw
PASS:		*ds:si - VisCharTable object
		es - dgroup
RETURN:		cx - number of columns
		ax - non-zero if data had CHAR_TABLE_SPACE_FILLER_CHARs
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

; ChunkSizePtr( segment, ptr, result );

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	8/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharTableCountNumberColumns	proc	near
	class	VisCharTableClass
	uses	ds, si, bx, di, es
	.enter

EC <	call	ECLMemValidateHeap					>
	call	VisCharTableDeref_DSDI
	movdw	bxsi, ds:[di].VCTI_line1

	push	bx
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]			;DS:SI <- string to display
	ChunkSizePtr	ds, si, cx
	pop	bx
	call	MemUnlock

	dec	cx

;	See if the data had CHAR_TABLE_SPACE_FILLER_CHARs

	push	cx
	mov	di, si
	segmov	es, ds
	mov	al, CHAR_TABLE_SPACE_FILLER_CHAR
	repne	scasb
	pop	cx
	jz	exit
	clr	ax
exit:	
	.leave
	ret
CharTableCountNumberColumns	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharTableCountNumberRows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count number of rows in the Character Table assuming each
		row has the same number of columns except for the one with
		special attribute

CALLED BY:	VisCharTableDraw

PASS:		*ds:si - VisCharTable object
RETURN:		dx - number of rows
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	8/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharTableCountNumberRows	proc	near	uses	cx, di
	class	VisCharTableClass
	.enter

	clr	dx
	call	VisCharTableDeref_DSDI
	add	di, offset VCTI_line1
loopTop:
	tstdw	ds:[di]
	jz	exit
	inc	dx
	add	di, size optr
	cmp	dx, 5
	jne	loopTop
exit:
	.leave
	ret
CharTableCountNumberRows	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfSpecialLastLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if it is a table with special last line

CALLED BY:	INTERNAL

PASS:		*ds:si - VisCharTable object
RETURN:		carry set if it is the table with special last line
			ax = 0 if Tab/Space/Enter/BS
			ax = 1 if Enter/BS
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	8/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfSpecialLastLine	proc	near	uses	bx, ds
	.enter
	mov	ax, ATTR_CHAR_TABLE_SPECIAL_LAST_LINE
	call	ObjVarFindData
	mov	ax, ds:[bx]
	.leave
	ret
CheckIfSpecialLastLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfSpecialChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the passed char is a special char

CALLED BY:	GLOBAL

PASS:		al - char to look for
RETURN:		carry set if is special char, ax = chunk handle of text
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfSpecialChar	proc	near	uses	es, cx, di
	.enter

	segmov	es, cs
	mov	di, offset specChars
	mov	cx, length specChars
	repne	scasb
	clc
	jne	exit
	sub	di, offset specChars+1
	shl	di
	mov	ax, cs:[specCharTab][di]
	stc
exit:
	.leave
	ret
CheckIfSpecialChar	endp

if DBCS_PCGEOS
specChars	wchar	C_SYS_BACKSPACE, C_SYS_TAB, C_SYS_ENTER, C_SPACE
else
specChars	char	VC_BACKSPACE, VC_TAB, VC_ENTER, C_SPACE
endif

specCharTab	lptr	\
		String_BS,
		String_TAB,
		String_ENTER,
		String_SPACE

.assert (length specChars) eq (length specCharTab)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharTableDrawOneRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one row of the Character Table

CALLED BY:	VisCharTableDraw

PASS: 		DI - GState handle
		DS:SI - string to display
		bx - top of the rectangle
		ax - zero if we can optimize the drawing (only draw 
		     	the right edge of the box)		
		dx - left of the rectangle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	7/28/92		Initial version
	dlitwin	4/29/94		Generalized IKBD/SKBD/ZKBD to allow other KBDs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharTableDrawOneRow	proc	near
noOptimize	local	word	push	ax	; non-zero if we cannot do
						;  the optimization
rectWidth	local	word			; Width of each standard-sized
						;  rectangle
yCharOffset	local	word			; Offset from top of rectangle
						;  to draw char label
	uses	ax, bx, dx, cx, es
	.enter

	mov_tr	cx, dx					;CX <- left of rect

IKBD <	LoadVarSeg	es, ax						>
IKBD_EC<call	ECCheckESDGroup						>
IKBD <	mov	ax, es:[charTableRectWidth]				>
IKBD <	mov	ss:[rectWidth], ax					>
NOTIKBD<mov	ss:[rectWidth], KEYBOARD_CHAR_TABLE_RECT_WIDTH		>

EC <	call	ECCheckGStateHandle					>

	push	si
	mov	si, GFMI_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics
	neg	dx
IKBD <	add	dx, es:[charTableRectHeight]				>
IKBD <	inc	dx							>
NOTIKBD<add	dx, KEYBOARD_CHAR_TABLE_RECT_HEIGHT+1			>
EC <	ERROR_S	-1							>

	shr	dx
	mov	ss:[yCharOffset], dx
	pop	si

	mov	dx, bx
IKBD <	add	dx, es:[charTableRectHeight]				>
NOTIKBD<add	dx, KEYBOARD_CHAR_TABLE_RECT_HEIGHT			>

	clr	ah

	; ds:si	= string to draw
	; bx	= y coord of top of row
	; dx	= y coord of bottom of row
	; cx	= left edge of current char
drawLoop:
	lodsb
	tst	al
	jz	done
	call	CheckIfSpecialChar		;If this is a special char,
	jc	isSpecialChar			; AX = chunk handle of 
						; corresponding text string
	cmp	ax, CHAR_TABLE_SPACE_FILLER_CHAR
	je	skipChar

	push	ax, cx

	mov	ax, cx
	add	cx, ss:[rectWidth]		;ax,bx,cx,dx - coord of rect

	call	OptimizedDrawRect
	pop	ax, cx


;	Center the character within the rectangle


	push	bx, dx
	clr	ah
	call	GrCharWidth			;DX <- width of character
						; actually dx.ah
	neg	dx
	add	dx, ss:[rectWidth]
	shr	dx
	add	dx, cx				;DX <- X pos for char

	xchg	ax, dx				;AX <- x pos, DX <- char value

if _NIKE
	; It was assume that the character width is only integer and
	; ah is clear after the GrCharWidth, but for font like Ping
	; Pong the character width might have fractions, thus, we need
	; to clear the dh again for our single byte character set.
	clr	dh		; 
endif

	add	bx, ss:[yCharOffset]
	call	GrDrawChar
	pop	bx, dx
skipChar:

	add	cx, ss:[rectWidth]
	jmp	drawLoop

done:
	.leave
	ret
isSpecialChar:
;
; This is a special char, so we do things a little differently. The box around
; the character is a little bigger, and we draw a string instead of a single
; char.
;
;	Pass: AX <- chunk handle of text string
;	      BX,DX <- top,bottom of row
;	      CX <- left edge of text
;

	push	ds, si

	mov_tr	si, ax		;SI <- chunk handle of string

if _NIKE_EUROPE
	; Use kbd accelerator bitmaps for Enter and Backspace

	mov	ax, offset enterBitmap
	cmp	si, offset String_ENTER
	je	drawBitmap
	mov	ax, offset backspaceBitmap
	cmp	si, offset String_BS
	jne	drawText

drawBitmap:
	mov_tr	si, ax			;si = offset of bitmap

	push	bx
	mov	bx, handle enterBitmap
	call	MemLock
	mov	ds, ax			;ds:si = bitmap
	pop	bx

	mov	ax, C_BLACK
	call	GrSetAreaColor

	push	bx, dx			;save top and bottom of row
	mov	ax, ss:[rectWidth]	;ax = rectWidth
	sub	ax, ds:[si].XYS_width	;ax = rectWidth - bitmapWidth
	shr	ax, 1			;ax = (rectWidth - bitmapWidth) / 2
	add	ax, 3			;minor adjustment
	add	ax, cx			;
	add	bx, 6			;(x,y) = bitmap position
	clr	dx			;no callback
	call	GrFillBitmap		;draw the bitmap
	pop	bx, dx			;restore top and bottom of row

	push	bx
	mov	bx, handle enterBitmap
	call	MemUnlock
	pop	bx

	mov	ax, cx			;ax = left edge
	add	cx, ss:[rectWidth]	;cx = right edge
	call	OptimizedDrawRect
	jmp	doneChar
drawText:
endif	; _NIKE_EUROPE

	push	bx
	mov	bx, handle GenPenInputControlToolboxUI
	call	MemLock
	pop	bx

NKE <	push	si			;save chunk handle of string	>
	mov	ds, ax
	mov	si, ds:[si]		;DS:SI <- string to draw
	mov	ax, cx				;AX <- left edge of rect drawn
	call	CharTableDrawVirtualChar	;CX <- right edge of rect drawn
NKE <	pop	si			;restore chunk handle of string	>
NKE <	cmp	si, offset String_BS					>
NKE <	jne	noHack							>
NKE <	inc	cx			;hack '<-' for NIKE.  Gross!!!	> 
NKE <noHack:								>
	call	OptimizedDrawRect

	push	bx
	mov	bx, handle GenPenInputControlToolboxUI
	call	MemUnlock
	pop	bx
doneChar::
	pop	ds, si
	jmp	drawLoop

OptimizedDrawRect:
	tst	ss:[noOptimize]
	jz	10$
	call	GrDrawRect
	retn
10$:
	call	GrDrawVLine
	retn

CharTableDrawOneRow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharTableDrawVirtualChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Calculate the width of the virtual character,
		draw a rectangle around it and draw the text inside the rect.
CALLED BY:	CharTableDrawLine5()
PASS:		cx - left coord of the rectangle going to be drawn
		bx - top coord of the rectangle going to be drawn
		dx - bottom coord of the rectangle going to be drawn
		ds:si - string to draw
RETURN:		cx - right coord of the rectangle just drawn
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	7/28/92		Initial version
	dlitwin	4/29/94		Generalized IKBD/SKBD/ZKBD to allow other KBDs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharTableDrawVirtualChar	proc	near	uses	ax,bx,dx,si,ds
charRect	local	Rectangle	
	.enter


	mov	ss:[charRect].R_left, cx
	mov	ss:[charRect].R_top, bx
	mov	ss:[charRect].R_bottom, dx

	clr	cx
	call	GrTextWidth			;dx - text width
	mov	ax, ss:[charRect].R_left
	mov	cx, ax
	add	cx, dx
	add	cx, (CHAR_TABLE_VIRTUAL_CHAR_LEFT_RIGHT_MARGIN * 2) - 1

;	HACK HACK HACK HACK HACK!
;	The widths of the special characters don't equal the width of the
;	char table, so we massage them here. Wheee!

IKBD_EC<call	ECCheckESDGroup						>
IKBD <	mov	ax, es:[charTableWidth]					>
IKBD <	sub	ax, 3							>
IKBD <	cmp	cx, ax							>
NOTIKBD<cmp	cx, KEYBOARD_CHAR_TABLE_WIDTH-3				>
	jb	afterHack

IKBD <	mov	cx, es:[charTableWidth]					>
IKBD <	dec	cx							>
NOTIKBD<mov	cx, KEYBOARD_CHAR_TABLE_WIDTH-1				>

afterHack:
	mov	bx, ss:[charRect].R_top
	mov	ax, ss:[charRect].R_left
	add	ax, CHAR_TABLE_VIRTUAL_CHAR_LEFT_RIGHT_MARGIN
	mov	bx, ss:[charRect].R_top
	inc	bx		;Put one pixel of space between top of
				; char rectangle and the text.
	call	GrDrawText

	.leave
	ret
CharTableDrawVirtualChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharTableMouseStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dealing with mouse press, converting to the character
		table press

CALLED BY:	GLOBAL

PASS:		*ds:si	= VisCharTableClass object
		ds:di	= VisCharTableClass instance data
		ds:bx	= VisCharTableClass object (same as *ds:si)
		es 	= segment of VisCharTableClass
		ax	= message #
		cx	= X position of mouse, in document coordinates of
			  receiving object
		dx	= X position of mouse, in document coordinates of
			  receiving object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

;MSG_META_KBD_CHAR
;This is the message sent out on any keyboard press or release.
; Pass:
;	cx = character value
;	dl = CharFlags
;	dh = ShiftState
;	bp low = ToggleState
;	bp high = scan code
; Return:
;	nothing
;	ax, cx, dx, bp - destroyed

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	7/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharTableMouseStartSelect	method dynamic VisCharTableClass, 
							MSG_META_START_SELECT
	.enter

	segmov	es, dgroup, ax

	call	VisCharTableGetGState
	call	CharTableFindSelectedRowCol
	jc	done				;ignore the mouse click
						;if click outside of the
						;character table
	call	CharTableFindCharValue		;cx <- character value
	cmp	cl, CHAR_TABLE_SPACE_FILLER_CHAR
	je	done

	;
	;  Generate Key-click sound
if	KEY_CLICK_SOUNDS
	push	ax				; save trashed register
	mov	ax, SST_KEY_CLICK		; play a key-click if sound-on
	call	UserStandardSound
	pop	ax				; restore trashed register
endif

	call	CharTableInvertChar

	push	ax, bx, si, di
	clr	bx				; current process
	call	GeodeGetAppObject		; ^lbx:si = app object
	clr	dh
	clr	bp

	mov	dl, mask CF_FIRST_PRESS
	mov	ax, MSG_META_KBD_CHAR
	call	CT_ObjMessageFixupDS 	

	; check if there is any pending MSG_META_START_SELECT (for any object)
	;   in the event queue.  If so, don't sleep.
	clr	es:[foundStartSelectMsg]	; reset flag
	mov	ax, MSG_META_START_SELECT
	mov	di, offset CT_CheckDuplicateCB
	pushdw	csdi
	mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE \
			or mask MF_CUSTOM or mask MF_DISCARD_IF_NO_MATCH \
			or mask MF_MATCH_ALL or mask MF_FIXUP_DS
	call	ObjMessage
	tst	es:[foundStartSelectMsg]
	jnz	noSleep

	mov	ax, 10				;Pause for 1/6 second
	call	TimerSleep 	

noSleep:
	clr	dh
	clr	bp
	ornf	dl, mask CF_RELEASE 	
	andnf	dl, not mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
						;Added 4/12/93 cbh

	mov	ax, MSG_META_KBD_CHAR 	
	call	CT_ObjMessageFixupDS 	

	pop	ax, bx, si, di
	call	CharTableInvertChar

done: 	
	mov	ax, mask MRF_PROCESSED 	
	.leave
	ret
CharTableMouseStartSelect	endm

CT_ObjMessageFixupDS	proc	near
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret
CT_ObjMessageFixupDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CT_CheckDuplicateCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to check for MSG_META_START_SELECT in queue.

CALLED BY:	INTERNAL, CharTableMouseStartSelect (via ObjMessage)

	It looks like callback routines for MF_CUSTOM have the following
	parameters: (AY 5/24/94)

	PASS:	ds:bx	= HandleEvent of an event already on queue
		ax	= message of the new event
		cx,dx,bp = data in the new event
		si	= lptr of destination of new event
	RETURN:	bp	= new value to be passed in bp in new event
		di	= one of the PROC_SE_* values
	CAN DESTROY:	si

SIDE EFFECTS:	foundStartSelectMsg modified

PSEUDO CODE/STRATEGY:
	Speed is more important than code size.  Optimize the not-match case.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CT_CheckDuplicateCB	proc	far
	cmp	ds:[bx].HE_method, ax	; see if MSG_META_START_SELECT
	je	found
CheckHack <PROC_SE_CONTINUE eq 0>
	clr	di			; di = PROC_SE_CONTINUE
	ret
found:
	mov	si, es			; preserve es (faster than "uses es")
	segmov	es, dgroup, di
	mov	es:[foundStartSelectMsg], BB_TRUE
	mov	es, si			; restore es
	mov	di, PROC_SE_EXIT
	ret
CT_CheckDuplicateCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharTableFindSelectedRowCol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the mouse click position to row and column in the
		Character Table

CALLED BY:	CharTableMouseStartSelect

PASS:		(cx, dx) - mouse position
		di - ^hGState
		*ds:si - VisCharTable object
		es - dgroup
RETURN:		(ax, bx) - corresponding row and column - 1-based
		carry - mouse press does not happen within the character table
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		col = (x clicked position - x start coord)/rect width
		row = (y clicked position - y start coord)/rect height
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	7/30/92		Initial version
	dlitwin	4/29/94		Generalized IKBD/SKBD/ZKBD to allow other KBDs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharTableFindSelectedRowCol	proc	near
	class	VisCharTableClass
mouseX		local	word
mouseY		local	word
left		local	word
column		local	word
row		local	word
totalRows	local	word
totalCols	local	word
rectWidth	local	word
rectLeft	local	word
	uses	cx,dx,si
	.enter

EC <	call	ECCheckGStateHandle			;>
	mov	ss:[mouseX], cx
	mov	ss:[mouseY], dx

	push	si
	push	bp
	call	GetCharTableInfo		;ax <- top of the rectangle
						;bx <- left of the rectangle
						;cx <- width of the rectangle
						;dx <- rows of the CharTable
						;bp <- columns of the CharTable
	mov	si, bp
	pop	bp
	mov	ss:[rectLeft], bx
	mov	ss:[rectWidth], cx
	mov	ss:[totalRows], dx
	mov	ss:[totalCols], si
	pop	si

;	row = (y clicked position - y start coord)/rect height
	mov	dx, ss:[mouseY]
	sub	dx, ax
	mov_tr	ax, dx
	clr	dx

IKBD_EC<call	ECCheckESDGroup						>
IKBD <	mov	bx, es:[charTableRectHeight]	;ax <- row number	>
NOTIKBD<mov	bx, KEYBOARD_CHAR_TABLE_RECT_HEIGHT			>

	div	bx
	inc	ax				;make row number as 1-based
	mov	ss:[row], ax			;bx <- row number
	
	cmp	ax, 1
	jl	outOfBound
	
	mov	dx, ss:[totalRows]
	cmp	ss:[row], dx
	jg	outOfBound

	call	CheckIfSpecialLastLine		;ax = 0 if Tab/Space/Enter/BS
						;ax = 1 if Enter/BS
	jnc	normal

;	code for the table with special last line
	cmp	ss:[row], dx
	jl	normal

;	Calculate column number for line 5
;	If it is one of the first 8 characters, do normal calculation
	;right coord of the 8th rectangle = 8*rectWidth + x start coord

	mov	dx, ss:[rectWidth]
	shl	dx, 1
	shl	dx, 1
	shl	dx, 1				;dx - right coord of the
						;     8th rectangle
	add	dx, ss:[rectLeft]

	cmp	dx, ss:[mouseX]
	jg	normal
	cmp	dx, ss:[mouseX]
	je	outOfBound

	mov	ss:[left], dx

	cmp	ax, 1
	je	specialEnterBS

	call	GetTabWidth			;cx - TAB rect width
	add	dx, cx
	mov	ss:[column], 9
	cmp	dx, ss:[mouseX]
	jg	done
	cmp	dx, ss:[mouseX]
	je	outOfBound
	
	call	GetSpaceWidth			;cx - SPACE rect width
	add	dx, cx
	mov	ss:[column], 10
	cmp	dx, ss:[mouseX]
	jg	done
	cmp	dx, ss:[mouseX]
	je	outOfBound

	call	GetEnterWidth			;cx - ENTER rect width
	add	dx, cx
	mov	ss:[column], 11
	cmp	dx, ss:[mouseX]
	jg	done
	cmp	dx, ss:[mouseX]
	je	outOfBound

	call	GetBackspaceWidth		;cx - BS rect width
	add	dx, cx
	mov	ss:[column], 12
	cmp	dx, ss:[mouseX]
	jg	done

outOfBound:
	;mouse click is out of bound or click on the border of the rectangle
	stc
	jmp	exit

normal:
;	column = (x clicked position - x start coord)/rect width
	mov	bx, ss:[rectWidth]		;bx <- rect width
	mov	ax, ss:[mouseX]
	sub	ax, ss:[rectLeft]
	clr	dx
	div	bx				;ax <- column number
	tst	dx
	jz	outOfBound			;click on the border of rect
	inc	ax				;make column number as 1-based
	mov	ss:[column], ax

	cmp	ss:[column], 1
	jl	outOfBound

	mov	dx, ss:[totalCols]
	cmp	ss:[column], dx
	jg	outOfBound

done:
	mov	ax, ss:[row]			;ax <- row number
	mov	bx, ss:[column]			;bx <- column number
	clc
exit:
	.leave
	ret

specialEnterBS:
	call	GetEnterWidth			;cx - ENTER rect width
	add	dx, cx
	mov	ss:[column], 9
	cmp	dx, ss:[mouseX]
	jg	done
	cmp	dx, ss:[mouseX]
	je	outOfBound

	call	GetBackspaceWidth		;cx - BS rect width
	add	dx, cx
	mov	ss:[column], 10
	cmp	dx, ss:[mouseX]
	jg	done
	jmp	outOfBound

CharTableFindSelectedRowCol	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTabWidth, GetSpaceWidth
		GetEnterWidth, GetBackspaceWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Get the width of the virtual character rectangle
CALLED BY:	CharTableFindSelectedRowCol
PASS:		nothing
RETURN:		cx - rect width
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	7/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTabWidth	proc	near
	.enter
	mov	si, offset String_TAB
	call	CharTableVirtualCharRectWidthSI
	.leave
	ret
GetTabWidth	endp

GetSpaceWidth	proc	near
	.enter
	mov	si, offset String_SPACE
	call	CharTableVirtualCharRectWidthSI
	.leave
	ret
GetSpaceWidth	endp

GetEnterWidth	proc	near	
	.enter
	mov	si, offset String_ENTER
	call	CharTableVirtualCharRectWidthSI
	.leave
	ret
GetEnterWidth	endp

GetBackspaceWidth	proc	near	
	.enter
	mov	si, offset String_BS
	call	CharTableVirtualCharRectWidthSI
NKE <	inc	cx	; one HACK deserves another (CharTableDrawOneRow) >
	.leave
	ret
GetBackspaceWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharTableVirtualCharRectWidthSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Passed in the offset to the virtual character string and
		get the width of the desired rectangle
CALLED BY:	INTERNAL
PASS:		si - offset to the string
RETURN:		cx - width of the desired rectangle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	7/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharTableVirtualCharRectWidthSI	proc	near	uses	ax,bx,dx,si,ds
	.enter

	mov	bx, handle GenPenInputControlToolboxUI

	push	bx
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]			;DS:SI <- string to display

	clr	cx
	call	GrTextWidth			;dx - text width
	mov	cx, dx
	add	cx, (CHAR_TABLE_VIRTUAL_CHAR_LEFT_RIGHT_MARGIN * 2) - 1

	pop	bx
	call	MemUnlock

	.leave
	ret
CharTableVirtualCharRectWidthSI	endp

;------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharTableFindCharValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Pass in the row and column number, find the corresponding
		character value		
CALLED BY:	CharTableMouseStartSelect
PASS:		(ax, bx) - (row, column) in the Character Table
		*ds:si - VisCharTable object
RETURN:		cx - character value
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	7/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharTableFindCharValue	proc	near	uses	ax, bx, dx,di
	class	VisCharTableClass
	.enter

EC <	cmp	ax, 1					;>
EC <	ERROR_B	ILLEGAL_CHAR_TABLE_ROW_NUMBER		;>

EC <	cmp	ax, 5					;>
EC <	ERROR_A	ILLEGAL_CHAR_TABLE_ROW_NUMBER		;>


	call	VisCharTableDeref_DSDI
	add	di, offset VCTI_line1 - size optr
	shl	ax
	shl	ax
	add	di, ax
	mov_tr	ax, bx			;AX <- column value
	dec	ax
	movdw	bxdx, ds:[di]
	call	CharTableGetCharValue_BXDX

;	Make it a control character if necessary.

SBCS <	mov	ch, CS_BSW			;assume it is BSW	>
SBCS <	cmp	cl, C_SPACE						>
SBCS <	jae	exit							>
SBCS <	mov	ch, CS_CONTROL						>
SBCS <exit:								>
	.leave
	ret
CharTableFindCharValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharTableGetCharValue_BXDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Get character value
CALLED BY:	CharTableFindCharValue()
PASS:		bxdx - optr to the line (instance data of VisCharTableClass)
		ax - column number (0-based)
RETURN:		SBCS:
			cl - character value
		DBCS:
			cx - character value
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	8/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharTableGetCharValue_BXDX	proc	near	uses	ax, ds, si
	.enter

	push	bx
	push	ax				;ax <- column number
	call	MemLock
	mov	ds, ax
	mov	si, dx
	mov	si, ds:[si]			;DS:SI <- string to display
	pop	ax				;ax <- column number
	add	si, ax
SBCS <	mov	cl, {char} ds:[si]					>
DBCS <	mov	cx, {wchar} ds:[si]					>
	pop	bx
	call	MemUnlock

	.leave
	ret
CharTableGetCharValue_BXDX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharTableInvertChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert or white out one key.

CALLED BY:	CharTableMouseStartSelect
PASS:		di - handle of gstate
		(ax, bx) - (row, col) of the character
		*ds:si - VisCharTable object
		es - dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	8/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharTableInvertChar	proc	near	uses	ax, bx, cx, dx
	.enter
EC <	call	ECCheckGStateHandle			;>
	call	GrSaveState
	push	ax
	mov	al, MM_INVERT			;al <- drawing mode
	call	GrSetMixMode
	pop	ax
	call	CharTableGetRectBounds
	inc	ax
	inc	bx
	call	GrFillRect
	call	GrRestoreState
	.leave
	ret
CharTableInvertChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharTableGetRectBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Get the rectangle bounds in the character table
CALLED BY:	CharTableInvertChar()
PASS:		(ax, bx) - (row, col) of rectangle
		*ds:si - VisCharTable object
		di - handle of gstate
		es - dgroup
RETURN:		(ax, bx, cx, dx) - (left, top, right, bottom)
		       		 - rectangle bounds
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
;	left = start x position + (col-1)*rectWidth 
;	     = (col-1)*rectWidth 

;	top  = start y position + (row-1)*rectHeight
;	     = CHAR_TABLE_TOP_BOTTOM_MARGIN + (row-1)* CHAR_TABLE_RECT_HEIGHT

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	8/ 6/92		Initial version
	dlitwin	4/29/94		Generalized IKBD/SKBD/ZKBD to allow other KBDs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharTableGetRectBounds	proc	near	uses	si
	class	VisCharTableClass
totalRows	local	word
totalCols	local	word
rectWidth	local	word
rectLeft	local	word
rectTop		local	word
enterBSFlag	local	word
	.enter


	push	si, ax, bx
	push	bp
	call	GetCharTableInfo		;ax <- top of the rectangle
						;bx <- left of the rectangle
						;cx <- width of the rectangle
						;dx <- rows of the CharTable
						;bp <- columns of the CharTable
	mov	si, bp
	pop	bp
	mov	ss:[rectTop], ax
	mov	ss:[rectLeft], bx
	mov	ss:[rectWidth], cx
	mov	ss:[totalRows], dx
	mov	ss:[totalCols], si
	pop	si, ax, bx

EC <	cmp	ax, 1					;>
EC <	ERROR_B	ILLEGAL_CHAR_TABLE_ROW_NUMBER		;>
EC <	cmp	ax, totalRows				;>
EC <	ERROR_A	ILLEGAL_CHAR_TABLE_ROW_NUMBER		;>
EC <	cmp	bx, 1					;>
EC <	ERROR_B	ILLEGAL_CHAR_TABLE_COLUMN_NUMBER	;>
EC <	cmp	bx, totalCols				;>
EC <	ERROR_A	ILLEGAL_CHAR_TABLE_COLUMN_NUMBER	;>

	push	ax
	call	CheckIfSpecialLastLine		;ax = 0 if Tab/Space/Enter/BS
						;ax = 1 if Enter/BS
	mov	enterBSFlag, ax
	pop	ax
	jnc	normal

	cmp	ax, ss:[totalRows]		; is it the last line?
	jl	normal				; if not, branch
	cmp	bx, FIRST_SPECIAL_CHAR_IN_LAST_ROW			;
	jl	normal

	;now, deal with special rectangles, those with virtual characters
	push	ax				;ax - row number
	mov	dx, ss:[rectWidth]
	shl	dx, 1
	shl	dx, 1
	shl	dx, 1				;dx - right coord of the
						;     8th rectangle
	add	dx, ss:[rectLeft]

	cmp	ss:[enterBSFlag], 1
LONG	je	specialEnterBS

	mov	ax, dx				;ax - left of TAB rect
	call	GetTabWidth			;cx - TAB rect width
	mov	dx, cx				;dx - TAB rect width
	mov	cx, ax				;cx - left of TAB
	add	cx, dx				;cx - right of TAB 
	
	cmp	bx, FIRST_SPECIAL_CHAR_IN_LAST_ROW
	je	doPopTopBottom	

	mov	ax, cx				;ax - left of SPACE rect
	call	GetSpaceWidth			;cx - SPACE rect width
	mov	dx, cx				;dx - SPACE rect width
	mov	cx, ax				;cx - left of rect
	add	cx, dx				;cx - right of SPACE

	cmp	bx, FIRST_SPECIAL_CHAR_IN_LAST_ROW + 1
	je	doPopTopBottom	

	mov	ax, cx				;ax - left of ENTER rect
	call	GetEnterWidth			;cx - ENTER rect width
	mov	dx, cx				;dx - ENTER rect width
	mov	cx, ax				;cx - left of rect
	add	cx, dx				;cx - right of ENTER

	cmp	bx, FIRST_SPECIAL_CHAR_IN_LAST_ROW+2
	je	doPopTopBottom	

EC <	cmp	bx, FIRST_SPECIAL_CHAR_IN_LAST_ROW+3			;>
EC <	ERROR_NE	ILLEGAL_CHAR_TABLE_COLUMN_NUMBER	;>

	mov	ax, cx				;ax - left of BACKSPACE rect
	call	GetBackspaceWidth		;cx - BACKSPACE rect width
	mov	dx, cx				;dx - BACKSPACE rect width
	mov	cx, ax				;cx - left of rect
	add	cx, dx				;cx - right of BACKSPACE

doPopTopBottom:
	pop	dx				;dx <- row number
	jmp	doTopBottom

normal:
;	left = start x position + (col-1)*rectWidth 
;	     = (col-1)*rectWidth 

	push	ax				;ax <- row number
	dec	bx
	mov_tr	ax, bx
	clr	dx
	mov	bx, ss:[rectWidth]
	mul	bx				;ax - left
	add	ax, ss:[rectLeft]		;ax - left
	mov	cx, ax
	add	cx, ss:[rectWidth]		;cx - right
	pop	dx				;dx <- row number

;	top  = start y position + (row-1)*rectHeight
;	     = CHAR_TABLE_TOP_BOTTOM_MARGIN + (row-1)* CHAR_TABLE_RECT_HEIGHT

doTopBottom:
	push	ax, cx
	dec	dx
	mov_tr	ax, dx
IKBD_EC<call	ECCheckESDGroup						>
IKBD <	mov	bx, es:[charTableRectHeight]				>
NOTIKBD<mov	bx, KEYBOARD_CHAR_TABLE_RECT_HEIGHT			>
	clr	dx
	mul	bx				;ax - top
	add	ax, ss:[rectTop]		;ax - top
	mov_tr	bx, ax				;bx - top
	mov	dx, bx
IKBD <	add	dx, es:[charTableRectHeight]	;dx - bottom		>
NOTIKBD<add	dx, KEYBOARD_CHAR_TABLE_RECT_HEIGHT			>
	pop	ax, cx

	.leave
	ret

specialEnterBS:
	mov	ax, dx				;ax - left of ENTER rect
	call	GetEnterWidth			;cx - ENTER rect width
	mov	dx, cx				;dx - ENTER rect width
	mov	cx, ax				;cx - left of ENTER
	add	cx, dx				;cx - right of ENTER
	
	cmp	bx, FIRST_SPECIAL_CHAR_IN_LAST_ROW
	je	doPopTopBottom

EC <	cmp	bx, FIRST_SPECIAL_CHAR_IN_LAST_ROW+1			;>
EC <	ERROR_NE	ILLEGAL_CHAR_TABLE_COLUMN_NUMBER	;>

	mov	ax, cx				;ax - left of BACKSPACE rect
	call	GetBackspaceWidth		;cx - BACKSPACE rect width
	mov	dx, cx				;dx - BACKSPACE rect width
	mov	cx, ax				;cx - left of rect
	add	cx, dx				;cx - right of BACKSPACE
	jmp	short doPopTopBottom

CharTableGetRectBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			Utilities 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisCharTableDeref_DSDI	proc	near
	.enter
EC <	call	ECCheckVisCharTableObj			;>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	.leave
	ret
VisCharTableDeref_DSDI	endp


VisCharTableGetGState	proc	near
	class	VisCharTableClass
	.enter
	call	VisCharTableDeref_DSDI
	mov	di, ds:[di].VCGSI_gstate
	.leave
	ret
VisCharTableGetGState	endp

;------------------


if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckVisCharTableObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify *ds:si is pointing to VisCharTable object

CALLED BY:	INTERNAL
PASS:		*ds:si - ptr to check
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	7/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckVisCharTableObj	proc	near	uses	es, di
	.enter

	mov	di, segment VisCharTableClass				
	mov	es, di							
	mov	di, offset VisCharTableClass				
	call	ObjIsObjectInClass					
	ERROR_NC	ILLEGAL_OBJECT_PASSED_TO_VIS_CHAR_TABLE_ROUTINE	

	.leave
	ret
ECCheckVisCharTableObj	endp

endif		; if ERROR_CHECK

CharTableCode ends

GenPenInputControlCode segment	resource

;	Put this in the GenPenInputControlCode resource, so CharTableCode
;	won't be loaded when we start up (it is sent from the GENERATE_UI
;	handler)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharTableGetCustomCharTableData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Copies the data in the CharTableData sturcture in the 
		PenInputControl to the instance data of the CustomCharTable
		object
CALLED BY:	GenPenInputControlSetDisplay
PASS:		
		*ds:si	= VisCharTableClass object
		ds:di	= VisCharTableClass instance data
		ds:bx	= VisCharTableClass object (same as *ds:si)
		es 	= segment of VisCharTableClass
		ax	= message #
		dx:bp - pointer to the CharTableData structure
RETURN:		nothing
DESTROYED:	bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	8/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharTableGetCustomCharTableData	method dynamic VisCharTableClass, 
				MSG_CHAR_TABLE_GET_CUSTOM_CHAR_TABLE_DATA
	uses	es
	.enter

	mov	es, dx			; es:[bp] - ptr to the structure

	movdw	cxdx, es:[bp].CTD_line1
	movdw	ds:[di].VCTI_line1, cxdx

	movdw	cxdx, es:[bp].CTD_line2
	movdw	ds:[di].VCTI_line2, cxdx

	movdw	cxdx, es:[bp].CTD_line3
	movdw	ds:[di].VCTI_line3, cxdx

	movdw	cxdx, es:[bp].CTD_line4
	movdw	ds:[di].VCTI_line4, cxdx

	movdw	cxdx, es:[bp].CTD_line5
	movdw	ds:[di].VCTI_line5, cxdx

	.leave
	ret
CharTableGetCustomCharTableData	endm


if INITFILE_KEYBOARD

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisCharTableSetToZoomerSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Configure our instance data for Zoomer keyboard size.

CALLED BY:	MSG_VIS_CHAR_TABLE_SET_TO_ZOOMER_SIZE
PASS:		*ds:si	= VisCharTableClass object
		ds:di	= VisCharTableClass instance data
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisCharTableSetToZoomerSize	method dynamic VisCharTableClass, 
					MSG_VIS_CHAR_TABLE_SET_TO_ZOOMER_SIZE
	.enter

	mov	ds:[di].VI_bounds.R_right, ZOOMER_CHAR_TABLE_WIDTH
	mov	ds:[di].VI_bounds.R_bottom, ZOOMER_CHAR_TABLE_HEIGHT+1

	mov	ds:[di].VCTI_fontType, ZOOMER_FONT_TYPE
	mov	ds:[di].VCTI_fontSize, ZOOMER_FONT_SIZE

	.leave
	ret
VisCharTableSetToZoomerSize	endm
endif		; if INITFILE_KEYBOARD

GenPenInputControlCode ends
