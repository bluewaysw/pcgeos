COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Misc		
FILE:		miscLettersDraw.asm

AUTHOR:		Ted H. Kim, March 9, 1992

ROUTINES:
	Name			Description
	----			-----------
 	LettersCompDraw		Draw method for composite gadget
	LettersColorDraw	Draws bitmaps for GeoDex in color display
	LettersBWDraw		Draws bitmaps for GeoDex in B&W display
	LettersCGADraw		Draws bitmaps for GeoDex in CGA display
	LettersDraw		Draw method for letter class gadget
	DrawRecycleTab		Draw the recycle tab
	DrawLetterTabs		Draws new letters onto letter tabs bitmap
	DrawLetters		Routine called by both DrawLetterTabs
	DrawMultChar		Draw letter tabs w/ multiple characters
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/92		Initial revision

DESCRIPTION:
	Contains message handlers for MSG_VIS_DRAW. 

	$Id: miscLettersDraw.asm,v 1.1 97/04/04 15:50:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LettersCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersCompDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw routine for composite gadget.	

CALLED BY:	UI (= MSG_VIS_DRAW)

PASS:		ds:si - instance data
		bp - gState handle
		cx - draw flags

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
	Set the attributes
	Get the bounds of gadget
	Draw the framed rectangle
	Draw its children

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	10/3/89		Initial version
	Ted	2/6/90		Uses bitmaps

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersCompDraw	method	LettersCompClass, MSG_VIS_DRAW
	push	cx, bp				
	mov	di, bp				; di - gstate handle

	; check to see if we are running under color mode

	cmp	es:[colorFlag], FALSE		; B&W?
	je	bw				; jump if B&W
	call	LettersColorDraw		; draw color bitmaps
	jmp	exit
bw:
	call	LettersBWDraw			; draw B&W bitmaps
exit:
	pop	cx, bp				

	; call its super class 

	mov	ax, MSG_VIS_DRAW			
	mov	di, offset LettersCompClass
	call	ObjCallSuperNoLock		
	ret
LettersCompDraw	endm

LettersCode 	ends

ColorCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersColorDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws all the bitmaps for color GeoDex except the letter tabs. 

CALLED BY:	LettersColorDraw	

PASS:		*ds:si - instance data of LettersCompClass		

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp 	

PSEUDO CODE/STRATEGY:
	Draw the rectangle for record entry area
	Fill this area with white color
	Draw the bitmap to the right of record entry area that shows
		the thickness of record entries
	Draw the bottom part of the bitmap
	Change the background color of phone related icons to light grey

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine is too big.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	10/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersColorDraw	proc	far

	class	LettersCompClass

	push	ds, si				; *ds:si - ptr to instance data
	call	VisGetBounds			; get the bounds of gadget

	; first draw the background for the card entry area.

	push	bx				; save top boundary
	push	ax				; save left boundary
	mov	al, SDM_100			; SOLID pattern
	call	GrSetLineMask			; set the line pattern to solid

	mov	ax, (CF_INDEX shl 8) or C_BLACK 
	call	GrSetLineColor			; set the line color to black

	pop	ax				; restore left position
	push	ax				; save left boundary
	inc	ax				; ax - adjust left position
ifdef GPC
	;
	; if no bottom/side, no adjust
	;
	push	si
	mov	si, ds:[si]
	add	si, ds:[si].LettersComp_offset
	tst	ds:[si].LCC_colBottom
	jz	checkAdjust
	tst	ds:[si].LCC_colMidsect
checkAdjust:
	pop	si
	jz	noAdjust
endif
	add	bx, COLOR_TOP_POS_ADJUST_BACKGRND_RECT	; bx - adjust top pos
	sub	cx, COLOR_RIGHT_POS_ADJUST_BACKGRND_RECT ; cx - adjust right pos
noAdjust::
ifndef GPC  ; GPC - draw at bottom
	mov	dx, bx
	add	dx, COLOR_BOTTOM_POS_ADJUST_BACKGRND_RECT ; dx - adjust bottom
endif
	call	GrDrawRect			; draw background rectangle 

	push	ax				; save left position
	mov	al, SDM_100			; SOLID pattern
	call	GrSetAreaMask			; set the area attributes

	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetAreaColor			; set the color to white
	pop	ax				; restore left position

	inc	ax				; ax - left
	;dec	cx				; cx - right
ifdef GPC
	push	bx
	inc	bx				; don't clobber top of outline
	call	GrFillRect			; fill the rectangle w/ white
	pop	bx
else
	call	GrFillRect			; fill the rectangle w/ white
endif

	; draw the right side of card view that shows the thickness of
	; record entries

ifdef GPC
	pop	si, si				; dump top left
	pop	ds, si				; *ds:si = object
	push	si
	mov	si, ds:[si]
	add	si, ds:[si].LettersComp_offset
	tst	ds:[si].LCC_colMidsect
	jz	noSideBot
	tst	ds:[si].LCC_colBottom
	jz	noSideBot
	push	cx, dx				; save lower right
	add	cx, 4
	mov	ax, cx
	sub	dx, 5
	call	GrDrawLine
	add	cx, 4
	mov	ax, cx
	sub	dx, 5
	call	GrDrawLine
	add	cx, 4
	mov	ax, cx
	sub	dx, 5
	call	GrDrawLine
	pop	ax, bx				; restore lower right
	call	GrDrawLine
noSideBot:
	pop	si
else  ; GPC
	mov	si, ds:[si]
	add	si, ds:[si].LettersComp_offset	; si - offset to instance data
	mov	bx, ds:[si].LCC_colMidsect	; bx - handle of bitmap
	mov	si, offset ColorMidsectResource: StartmidsecIcon ; si - offset
	pop	ax				; ax - left pos. of bitmap
	inc	ax				; adjust it for color version
	push	ax				; save it

	call	MemLock				; load in the bitmap
	mov	bp, bx				; bp - resource handle
	mov	ds, ax				; ds - seg addr of bitmap
	pop	ax				; restore left position
	pop	bx				; restore top position
	add	ax, COLOR_LEFT_POS_ADJUST_MIDDLE_BITMAP	; adjust left position
	add	bx, COLOR_TOP_POS_ADJUST_MIDDLE_BITMAP	; adjust top position
	clr	dx				; no call back routine 
	call	GrDrawBitmap			; draw the middle section

	pop	ds, si				; ds:si - ptr to instance data

	push	ds, si
	call	VisGetBounds			; get the bounds of gadget

	push	bx				; save top position
	push	ax				; save left position

	mov	bx, bp				; bx - resource handle
	call	MemUnlock			; unlock the bitmap resource

	; now draw the bottom part of card view

	mov	si, ds:[si]
	add	si, ds:[si].LettersComp_offset	; si - offset to instance data
	mov	bx, ds:[si].LCC_colBottom	; bx - handle of color bitmap
	mov	si, offset ColorBottomResource: StartbottomIcon ; si - offset

	call	MemLock				; load in the bitmap
	mov	bp, bx				; bp - resource handle
	mov	ds, ax				; ds - seg addr of bitmap
	pop	ax				; restore left position
	pop	bx				; restore top position
	inc	ax				; adjust left position
	add	bx, COLOR_TOP_POS_ADJUST_BOTTOM_BITMAP ; adjust top position
	clr	dx				; no call back routine
	call	GrDrawBitmap			; draw the bitmap

	mov	bx, bp				; bx - resource handle
	call	MemUnlock			; unlock the bitmap resource
	pop	ds, si				; ds:si - ptr to instance data
endif  ; GPC

ifndef GPC  ; the buttons draw their own backgrounds
	push	ds, si

	; for color version, change the background color of phone icon
	; and phone number scroll up & down icons to light grey

	mov	ax, (CF_INDEX shl 8) or C_LIGHT_GREY
	call	GrSetAreaColor			; set the color to light grey

	mov	si, offset ScrollUpTrigger	; ds:si - instance data of obj
	mov	ax, MSG_VIS_GET_BOUNDS		; ax - method number
	call	ObjCallInstanceNoLock		; get bounds of up arrow button 
	mov	bx, bp				; bx - left position
	call	GrFillRect			; fill this area with lt. grey

	mov	si, offset ScrollDownTrigger	; ds:si - instance data of obj
	mov	ax, MSG_VIS_GET_BOUNDS		; ax - method number
	call	ObjCallInstanceNoLock		; get bounds of down button 
	mov	bx, bp				; bx - left position
	call	GrFillRect			; fill this area with lt. grey
if _PHONE_ICON
	mov	si, offset AutoDialTrigger	; ds:si - instance data of obj
	mov	ax, MSG_VIS_GET_BOUNDS		; ax - method number
	call	ObjCallInstanceNoLock		; get bounds of phone button 
	mov	bx, bp				; bx - left position
	call	GrFillRect			; fill this area with lt. grey
endif
	pop	ds, si				; ds:si - ptr to instance data
endif ; GPC
	ret
LettersColorDraw	endp

ColorCode	ends

LettersCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersBWDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws all the bitmaps for B&W GeoDex except the letter tabs. 

CALLED BY:	LettersCompDraw

PASS:		cga - flag that tells you which video card is being used
		*ds:si - instance data of LettersCompDraw

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
	Draw a vertical line on the left edge of data entry area 
	Draw the bitmap to the right of record entry area that shows
		the thickness of record entries
	Draw the bottom part of the bitmap

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine is too big.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	10/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersBWDraw	proc	near

	class	LettersCompClass

if not PZ_PCGEOS
	tst	es:[cga]			; running under CGA card?
	LONG	js	doCGA			; if so, skip to handle it
endif

	push	ds, si				; *ds:si - instance data 
	call	VisGetBounds			; get the bounds of gadget

	push	bx				; save top boundary
	push	ax				; save left boundary
	mov	al, SDM_100			; SOLID pattern
	call	GrSetLineMask			; set the line pattern

	mov	ax, (CF_INDEX shl 8) or C_BLACK 
	call	GrSetLineColor			; set the line color to black

	pop	ax				; restore left position
	push	ax				; save left boundary
	inc	ax				; ax - left
	add	bx, BW_TOP_POS_ADJUST_BACKGRND_RECT 	; bx - adjust top
	mov	cx, ax				; cx - right
	mov	dx, bx
	add	dx, BW_BOTTOM_POS_ADJUST_BACKGRND_RECT	; dx - adjust bottom
	call	GrDrawLine			; draw a line

	; draw the bitmap that shows the thickness of rolodex cards

	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor

	mov	si, ds:[si]
	add	si, ds:[si].LettersComp_offset	; si - offset to instance data
	mov	bx, ds:[si].LCC_bwMidsect	; bx - handle of bitmap data
	mov	si, offset BWMidsectResource: StartbwmidsecIcon  ; si - offset
	call	MemLock				; load in the bitmap
	mov	bp, bx				; bp - resource handle
	mov	ds, ax				; ds - seg addr of bitmap
	pop	ax				; restore left position
	pop	bx				; restore top position
	add	ax, BW_LEFT_POS_ADJUST_MIDDLE_BITMAP	; adjust left position
	add	bx, BW_TOP_POS_ADJUST_MIDDLE_BITMAP	; adjust top position
	clr	dx				; no call back routine 
	call	GrFillBitmap			; draw the mid section

	pop	ds, si				; ds:si - ptr to instance data
	push	ds, si
	call	VisGetBounds			; get the bounds of gadget

	push	bx				; save top position
	push	ax				; save left position

	mov	bx, bp				; bx - resource handle
	call	MemUnlock			; unlock the bitmap resource

	; draw the bitmap that shows the punched holes at the bottom of a card

	mov	si, ds:[si]
	add	si, ds:[si].LettersComp_offset	; si - offset to instance data
	mov	bx, ds:[si].LCC_bwBottom	; bx - handle of B&W bitmap
	mov	si, offset BWBottomResource: StartbwbottomIcon ; si - offset
	call	MemLock				; load in the bitmap
	mov	bp, bx				; bp - resource handle
	mov	ds, ax				; ds - seg addr of bitmap
	pop	ax				; restore left position
	pop	bx				; restore top position
	inc	ax				; adjust left position

	add	bx, BW_TOP_POS_ADJUST_BOTTOM_BITMAP	; adjust top position
	clr	dx				; no call back routine
	call	GrFillBitmap			; draw the bitmap

	mov	bx, bp				; bx - resource handle
	call	MemUnlock			; unlock the bitmap resource
	pop	ds, si				; ds:si - ptr to instance data
	ret

if not PZ_PCGEOS
doCGA:
	call	LettersCGADraw			; draw diff'rnt bitmap for CGA 
	ret
endif
LettersBWDraw	endp

LettersCode	ends

if not PZ_PCGEOS
CGACode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersCGADraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws all of the bitmaps for CGA GeoDex except letter tabs.

CALLED BY:	LettersBWDraw	

PASS:		*ds:si - instance data of LettersCompDraw

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
	Draw a vertical line on the left edge of data entry area 
	Draw the bitmap to the right of record entry area that shows
		the thickness of record entries
	Draw the bottom part of the bitmap

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine is too big.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	10/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersCGADraw		proc		far

	class	LettersCompClass

	push	ds, si				; *ds:si - instance data 
	call	VisGetBounds			; get the bounds of gadget

	push	bx				; save top boundary
	push	ax				; save left boundary
	mov	al, SDM_100			; SOLID pattern
	call	GrSetLineMask			; set the line pattern

	mov	ax, (CF_INDEX shl 8) or C_BLACK 
	call	GrSetLineColor			; set the line color to black

	pop	ax				; restore left position
	push	ax				; save left boundary
	inc	ax				; ax - left
	add	bx, CGA_TOP_POS_ADJUST_BACKGRND_RECT 	; bx - adjust top
	mov	cx, ax				; cx - right
	mov	dx, bx
	add	dx, CGA_BOTTOM_POS_ADJUST_BACKGRND_RECT	; dx - adjust bottom
	call	GrDrawLine			; vertical line on left edge

	; draw the bitmap that shows the thickness of the GeoDex cards

	mov	si, ds:[si]
	add	si, ds:[si].LettersComp_offset	; si - offset to instance data
	mov	bx, ds:[si].LCC_cgaMidsect	; bx - handle of bitmap data
	mov	si, offset CGABWMidsectResource: StartcgabwmidsecIcon 
	call	MemLock				; load in the bitmap
	mov	bp, bx				; bp - resource handle
	mov	ds, ax				; ds - seg addr of bitmap
	pop	ax				; restore left position
	pop	bx				; restore top position
	add	ax, CGA_LEFT_POS_ADJUST_MIDDLE_BITMAP	; adjust left position
	add	bx, CGA_TOP_POS_ADJUST_MIDDLE_BITMAP	; adjust top position
	clr	dx				; no call back routine 
	call	GrFillBitmap			; draw the mid section

	pop	ds, si				; ds:si - ptr to instance data
	push	ds, si
	call	VisGetBounds			; get the bounds of gadget

	push	bx				; save top position
	push	ax				; save left position

	mov	bx, bp				; bx - resource handle
	call	MemUnlock			; unlock the bitmap resource

	; draw the bitmap that shows the punched holes at the bottom of a card

	mov	si, ds:[si]
	add	si, ds:[si].LettersComp_offset	; si - offset to instance data
	mov	bx, ds:[si].LCC_bwBottom	; bx - handle of B&W bitmap
	mov	si, offset BWBottomResource: StartbwbottomIcon ; si - offset
	call	MemLock				; load in the bitmap
	mov	bp, bx				; bp - resource handle
	mov	ds, ax				; ds - seg addr of bitmap
	pop	ax				; restore left position
	pop	bx				; restore top position
	inc	ax				; adjust left position

	add	bx, CGA_TOP_POS_ADJUST_BOTTOM_BITMAP	; adjust top position
	clr	dx				; no call back routine
	call	GrFillBitmap			; draw the bitmap

	mov	bx, bp				; bx - resource handle
	call	MemUnlock			; unlock the bitmap resource
	pop	ds, si				; ds:si - ptr to instance data
	ret
LettersCGADraw	endp

CGACode	ends
endif

LettersCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw routine for letters class.

CALLED BY:	UI (= MSG_VIS_DRAW)

PASS:		ds:si - instance data
		es - segment of LettersClass
		ax - The method
		cx - DrawFlag (with DF_EXPOSED)
		bp - gstate to use

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di, ds, es

PSEUDO CODE/STRATEGY:
	Draw the bounding boxes for letter buttons
	Display characters for letter buttons

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	10/3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersDraw	method	LettersClass, MSG_VIS_DRAW
	call	VisGetBounds		; get bounds of letter boxes
	mov	di, bp			; di - handle graphics state

	push	ds, si			; ds:si - instance data			

	push	ax			; save left boundary
	push	bx			; save top boundary

	tst	es:[colorFlag]		; is color flag set?
	js	colorBitmap		; if so, skip

	; draw the black and white letter tab bitmap

	mov	si, ds:[si]
	add	si, ds:[si].Letters_offset ; access the instance data
	mov	bx, ds:[si].LI_bwLetters   ; bx - handle of bitmap resource
	mov	si, offset BWLettersResource: StartstarbwIcon ; si - offset
	jmp	short	draw		; skip to draw it
colorBitmap:
	; draw the color bitmap for letter tabs

	mov	si, ds:[si]
	add	si, ds:[si].Letters_offset ; access the instance data
	mov	bx, ds:[si].LI_colLetters  ; bx - handle of color bitmap
	mov	si, offset ColorLettersResource: StartstarcolIcon ; si - offset
draw:
	call	MemLock			; load in the bitmap resource
	mov	bp, bx			; save resource handle
	mov	ds, ax			; ds - seg address of bitmap resource
	pop	bx			; restore top boundary
	pop	ax			; restore left boundary
	inc	ax			; adjust left boundary
	clr	dx			; no call back routine
	call	GrDrawBitmap		; draw the damn thing
	mov	bx, bp			; bx - resource handle
	call	MemUnlock		; unlock the resource block
	pop	ds, si			; ds:si - instance data

	; write the letters into the letter tabs

	push	si
	mov	cx, 1			; gstate handle is passed
	mov	dl, es:[curCharSet]	; dl - current character set index
	mov	dh, C_RED		; dl - ColorIndex
	call	DrawLetterTabs		; draw letters into tabs

	mov	si, ds:[si]
	add	si, ds:[si].Letters_offset	; access instance data
	test	ds:[si].LI_flag, mask LIF_INVERTED ; is there an inverted char?
	mov	dx, ds:[si].LI_letter	; dx - letter tab ID
	pop	si
	je	exit			; if not, exit

	; invert the letter tab

	mov	cx, es:[gmb.GMB_numMainTab]
	push	es
	mov	bp, di			; bp - gState handle
	call	LettersButtonInvert
	pop	es
exit:
	cmp	es:[numCharSet], 1	; one set of characters?
	je	done			; if so, exit
	call	DrawRecycleTab		; otherwise, draw recycle tab 
done:
	ret
LettersDraw	endm


if	0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the VisBounds of this object to see if it is being
		exposed.

CALLED BY:	(INTERNAL) LettersDraw

PASS:		ax - left
		bx - top
		cx - right
		dx - bottom

RETURN:		carry set if not exposed
		carry clear if it is being exposed

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	11/19/92	Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckBounds	proc	near	uses	ax, bx, cx, dx

	left	local	word
	top	local	word
	right	local	word
	bottom	local	word
	
	.enter

	; set up the local stack frame

	mov	left, ax
	mov	top, bx
	mov	right, cx
	mov	bottom, dx

	; now get the bounds of clipped region

	call	GrGetMaskBounds

	cmp	ax, right		; too far right?
	jg	notExposed		; if so, not exposed

	cmp	bx, bottom		; too far above?
	jg	notExposed		; if so, not exposed

	cmp	cx, left		; too far left?
	jl	notExposed		; if so, not exposed

	cmp	dx, top			; too far below?
	jl	notExposed		; if so, not exposed
	clc				; exposed flag set
	jmp	exit
notExposed:
	stc				; not exposed flag set
exit:
	.leave
	ret
CheckBounds	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRecycleTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the recycle tab

CALLED BY:	(INTERNAL) LettersDraw

PASS:		es - seg addr of core block
		ds:si - instance data

RETURN:		nothing

DESTROYED:	ax, bx, si, bp 

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawRecycleTab	proc	near

	class	LettersClass

	left		local	word
	top		local	word
	right		local	word
	bottom		local	word
	memHandle	local	hptr
	
	.enter

	; check to see if color mode

	call	VisGetBounds		; get the bounds of gadget

	mov	left, ax		; save the bounds
	mov	top, bx
	mov	right, cx
	mov	bottom, dx

	tst	es:[colorFlag]		
	js	colorBitmap		; if so, skip

	; locate bitmap for B&W arrow

	mov	si, ds:[si]
	add	si, ds:[si].Letters_offset 
	mov	bx, ds:[si].LI_bwLetters   ; bx - handle of BW bitmap block
	mov	si, offset BWLettersResource: StartBWArrow 
	jmp	common
colorBitmap:
	; locate bitmap for color arrow

	mov	si, ds:[si]
	add	si, ds:[si].Letters_offset 
	mov	bx, ds:[si].LI_colLetters  ; bx - handle of color bitmap block
	mov	si, offset ColorLettersResource: StartColorArrow 
common:
	call	MemLock			; lock the bitmap resource block
	mov	memHandle, bx	
	mov	ds, ax				; ds:si - bitmap 
	mov	ax, left
	add	ax, LEFT_POS_RECYCLE_TAB	; ax - x position 
	mov	bx, top
	add	bx, TOP_POS_RECYCLE_TAB		; bx - y position
	call	GrDrawBitmap
	mov	bx, memHandle			
	call	MemUnlock		; unlock the resource block

	.leave
	ret
DrawRecycleTab	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawLetterTabs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw new set of characters onto the letter tab bitmap.

CALLED BY:	UI(=MSG_DRAW_LETTER_TABS), LettersButtonCalc

PASS:		dl - curCharSet		
		dh - ColorIndex
		cx - flag for GState
			if cx = 0, create a new GState
			if cx = 1, di is the handle of GState
		di - handle of GState if cx is not zero
		es - dgroup

RETURN:		nothing

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawLetterTabs		method	LettersClass, MSG_DRAW_LETTER_TABS 
	uses	ax, bx, cx, dx, ds, es, si, di, bp

	gState		local	hptr		; gstate handle
	colorIndex	local	word		; current ColorIndex

	.enter

	mov	ax, es:[numCharSet]		; ax - number of char set
	cmp	dl, al				; is this char set exant?
	jl	ok				; if so, skip
	clr	dl				; if not, draw the 1st set
ok:
	mov	es:[curCharSet], dl		; update curCharSet
	push	cx				; save gstate flag 
	tst	cx				; gstate handle passed?
	jne	skip				; if so, skip

	; if not, we need to create a new gstate 

	push	bp, dx
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock		; create gState
	mov	di, bp				; di - gState handle
	pop	bp, dx
skip:
	; change the text color

	mov	gState, di			; save gState handle
	call	GrGetTextColor			; get current color index 
	mov	colorIndex, ax			; save it
	mov	ah, CF_INDEX
	mov	al, dh				; al - ColorIndex
	call	GrSetTextColor			; change text color to red

	call	DrawLetters			; draw new set of characters

	mov	di, gState			; di - handle of gState
	mov	ax, colorIndex
	mov	ah, CF_INDEX			
	call	GrSetTextColor			; restore the text color

	pop	cx				; save gstate flag
	tst	cx				; did we create a new gstate?
	jne	exit				; if not, exit
	call	GrDestroyState	 		; if so, destroy it
exit:
	.leave
	ret
DrawLetterTabs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawLetters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw all the characters in the given character set. 

CALLED BY:	DrawLetterTabs, ClearLetterTabs

PASS:		di - gstate handle
		dl - curCharSet
		es - dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, ds, si 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawLetters	proc	near

	xColumnOne	local	word		; left boundary of letter tabs
	xPosition	local	word		; x position for GrDrawChar
	yPosition	local	word		; y position for GrDrawChar
	gState		local	hptr		; gstate handle
	charSet		local	byte		; current character set index
	leftSpace	local	word		; space b/w left edge and char

	.enter

	mov	leftSpace, LEFT_SPACE_IN_TAB
	mov	charSet, dl			; save cur char set number
	mov	gState, di			; save gState handle
	call	VisGetBounds			; get bounds of letter tabs
	sub	dx, FIRST_ROW_Y_POSITION_ADJUST	; adjust y position
	mov	yPosition, dx			; bx - y position

PZ <	sub	yPosition, 1						>

	mov	xColumnOne, ax			; save left pos. of boundary 
	add	ax, FIRST_ROW_X_POSITION_ADJUST	; adjust x position
	mov	xPosition, ax			; ax - x position

PZ <	sub	xPosition, 3						>

	; now change the font and point size

ifdef GPC
	call	GrSaveState
endif

	mov	dx, LETTER_TAB_FONT_SIZE	; dx - integer part of WBFixed
	mov	cx, GEODEX_DISPLAY_FONT

	clr	ah				; dx.ah - point size
	call	GrSetFont			; change the font

	GetResourceHandleNS	TextResource, bx
	call	MemLock				; lock the block with char set 
	mov	ds, ax				; set up the segment
;; (why?) mov	es, ax				; set up the segment
;; (why?) mov	di, offset LetterTabCharSetTable; handle of error messages 

	mov	si, offset LetterTabCharSetTable 
	mov	si, ds:[si]			; dereference the handle
	clr	dh
	mov	dl, charSet			; dx - current char set index
	shl	dx, 1				; multiply it by two
	add	si, dx				; go to the correct char set
	mov	si, ds:[si]			; text handle => si
	mov	si, ds:[si]			; dereference the handle
	clr	cx				; index into character set
charLoop:
	push	si, cx
	shl	cx, 1				; array of 'nptr's
	add	si, cx				; go to the correct character
	mov	si, ds:[si]			; text handle => si
	mov	si, ds:[si]			; character is in DS:SI

	ChunkSizePtr	ds, si, cx
DBCS <	shr	cx, 1				; cx - string length	>
	dec	cx				; cx - length w/out NULL
	cmp	cx, 1				; just one character in string?
	jg	notOne				; if not, skip to handle it
SBCS <	clr	dh							>
	LocalGetChar	dx, dssi, noAdvance	; dx - char to draw

	mov	ax, xPosition			; ax - x position
	mov	bx, yPosition			; bx - y position
	mov	di, gState			; di - gState handle
	call	GrDrawChar			; draw the character
	jmp	common2
notOne:
	call	DrawMultChar			; draw multiple character
common2:
	pop	si, cx				; cx - # of chars drawn so far
	inc	cx				; increment it
	cmp	cx, MAX_NUM_OF_LETTER_TABS	; are we done?
	je	done				; if so, exit

	cmp	cx, DLTI_ROW_TWO		; if not, at the beg. of row 2?
	jne	three				; if not, skip

	; this is the 1st character of row two, adjust x, y position values

	mov	leftSpace, LEFT_SPACE_IN_TAB
	mov	ax, xColumnOne
	add	ax, SECOND_ROW_X_POSITION_ADJUST
	mov	xPosition, ax			; ax - new X position for row 2
	sub	yPosition, SECOND_ROW_Y_POSITION_ADJUST	; y position
	jmp	charLoop			; draw the next character
three:
	cmp	cx, DLTI_ROW_THREE		; is this 1st char of row 3?
	jne	updateX				; if not, skip

	; this is the 1st character of row three, adjust x, y position values

	mov	leftSpace, LEFT_SPACE_IN_TAB
	mov	ax, xColumnOne
	add	ax, THIRD_ROW_X_POSITION_ADJUST
	mov	xPosition, ax			; ax - new x position of row 3
	sub	yPosition, THIRD_ROW_Y_POSITION_ADJUST	; y position
	jmp	charLoop			; draw the next character
updateX:
	mov	leftSpace, LEFT_SPACE_IN_TAB-3
	add	xPosition, NEXT_COLUMN_INCREMENT; update x position
	jmp	charLoop

done:
ifdef GPC
	mov	di, gState
	call	GrRestoreState
endif
	GetResourceHandleNS	TextResource, bx
	call	MemUnlock			; unlock the block

	.leave
	ret
DrawLetters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawMultChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw letter tabs with multiple characters

CALLED BY:	(INTERNAL) DrawLetters	

PASS:		ds:si - character string to draw		
		cx - length of string (w//out C_NULL)

RETURN:		none

DESTROYED:	ax, bx, cx, dx, si, di

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Calculate string width in points.
		If more than 2 chars, move left margin to left edge
			of letter tab.
		Print the string.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawMultChar	proc	near

	xColumnOne	local	word		; left boundary of letter tabs
	xPosition	local	word		; x position for GrDrawChar
	yPosition	local	word		; y position for GrDrawChar
	gState		local	hptr		; gstate handle
	charSet		local	byte		; current character set index
	leftSpace	local	word		; space b/w left edge and char

	.enter	inherit near

	push	cx				; save char length
	clr	cx				; cx - point width of string
	clr	ah
	push	si
mainLoop:
	LocalGetChar	ax, dssi		; ax - char to draw
	LocalIsNull	ax			; end of string?

	je	done				; exit if so
	mov	di, gState			; di - gState handle
	call	GrCharWidth			; dx - width of this character
	add	cx, dx				; cx - width of string
	jmp	mainLoop			; check the next character

done:
	pop	si				; retrive string ptr
;;(why??)	cmp	cx, NEXT_COLUMN_INCREMENT	; is string too wide?
;;(why??)	jle	draw				; if so, exit
;;(why??) draw:
	mov	ax, xPosition
	pop	bx				; retrieve char length
	cmp	bx, 2				; more that 2 chars?
	je	charLoop
	sub	ax, leftSpace			; ax - "moved left" x position
charLoop:
	LocalGetChar	dx, dssi		; dx - char to draw
	LocalIsNull	dx			; end of string?

	je	exit				; exit if so
	mov	bx, yPosition			; bx - y position
	mov	di, gState			; di - gState handle
	push	ax
	call	GrDrawChar			; draw the character
	mov	ax, dx				; ax - char to draw
	call	GrCharWidth			; dx - width of this character

	pop	ax 
	add	ax, dx				; ax - x position
	jmp	charLoop
exit:
	.leave
	ret
DrawMultChar	endp

LettersCode ends
