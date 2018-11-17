COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GeoDex
MODULE:		Misc		
FILE:		miscLetters.asm

AUTHOR:		Ted H. Kim, 10/3/89

ROUTINES:
	Name			Description
	----			-----------
 	LettersCompSpecBuild	Vis. build method for composite gadget
 	LettersCompGetSpacing	Sets the spacing between objects in a gadget	
	LettersCompGetMargins	Gets margin of composite gadget	
 	LettersCompGetMinSize	Sets the minimum size of composite gadget
 	LettersCompRecalcSize	Sets the maximum size of composite gadget
 	LettersFindKbdAccelerator	Intercepts keyboard accelerators	
 	LettersSpecBuild	Vis. build method for letter class gadget
 	LettersStartSelect	Mouse press method handling routine
	LettersGetAppFeatures	Get the application feature bits
 	LettersButtonProcess	Processes mouse events
 	LettersButtonCalc	Calculates which button is pressed
	LettersDrawLetterTab	Invert a letter tab and display a record
	LettersDisplayRecord	Display 1st record under current letter tab
	LettersCheckForBlankTab	Check to see a blank tab is clicked upon
	LettersGetLetterTabChar	Get the string for letter tab
	LettersUninvertTab	Uninvert an already inverted tab
 	LettersLostExclusive	Releases the mouse grab
 	LettersButtonInvert	Inverts the new letter button
 	LettersButtonClear	Uninverts a letter tab before closing a file	
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/89		Initial revision
	ted	3/92		Complete restructuring for 2.0

DESCRIPTION:
	Contains letter button gadget related routines.

	$Id: miscLetters.asm,v 1.1 97/04/04 15:50:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LettersCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersCompSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Visually builds letters composite gadget.	

CALLED BY:	UI (= MSG_SPEC_BUILD)

PASS:		es - dgroup
		ds:si - instance data

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:
	Call the super class
	Get the instance data
	Set the flags

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	10/3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersCompSpecBuild	method	LettersCompClass, MSG_SPEC_BUILD
	mov	di, offset LettersCompClass
	call	ObjCallSuperNoLock	; call your super class
	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset	; di - offset to instance data

	; set size for letter gadget

ifndef GPC
	mov	ds:[di].VI_bounds.R_left, LEFT_BOUND
	mov	ds:[di].VI_bounds.R_top, TOP_BOUND
	mov	ds:[di].VI_bounds.R_right, RIGHT_BOUND
	mov	ds:[di].VI_bounds.R_bottom, BOTTOM_BOUND
endif
	mov	ds:[di].VCI_geoAttrs, mask VCGA_ORIENT_CHILDREN_VERTICALLY or\
		 			  mask VCGA_ONE_PASS_OPTIMIZATION or\
					  mask VCGA_HAS_MINIMUM_SIZE
	mov	ds:[di].VCI_geoDimensionAttrs, \
			mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT or \
			WJ_CENTER_CHILDREN_HORIZONTALLY shl offset \
			VCGDA_WIDTH_JUSTIFICATION

	; while we're here, adjust the font for the LastNameString
	; if we're running on a TV

ifdef	GPC
	tst	es:[tvFlag]
	jz	done				; not on TV, so nothing to do
	mov	di, ds:[si]
	add	di, ds:[di].LettersComp_offset	; di - offset to instance data
	mov	si, ds:[di].LCC_lastNameMkr	; chunk handle => SI
	mov	si, ds:[si]
	mov	{byte}ds:[si+ 8], 12		; switch to 12 point from 10
done:
endif
	ret
LettersCompSpecBuild	endm 


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersCompGetSpacing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the spacing for objects inside the composite gadget.

CALLED BY:	UI (= MSG_VIS_COMP_GET_CHILD_SPACING )

PASS:		nothing

RETURN:		cx -- spacing between children
		dx -- spacing between wrapped lines of children
		ax, bp destroyed

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	10/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersCompGetSpacing	method	LettersCompClass, MSG_VIS_COMP_GET_CHILD_SPACING
	mov	cx, 5			; child spacing
	clr	dx
	ret
LettersCompGetSpacing	endm



COMMENT @----------------------------------------------------------------------

METHOD:		LettersCompGetMargins -- 
		MSG_VIS_COMP_GET_MARGINS for LettersCompClass

DESCRIPTION:	Gets margins.

PASS:		*ds:si 	- instance data
		es	- segment of MetaClass
		ax 	- MSG_VIS_COMP_GET_MARGINS

RETURN:		ax 	- left margin
		bp	- top margin
		cx	- right margin
		dx	- bottom margin

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/16/91		Initial version

------------------------------------------------------------------------------@

LettersCompGetMargins	method LettersCompClass, MSG_VIS_COMP_GET_MARGINS
ifdef GPC
	;
	; if no bottom/side use default
	;
	mov	di, ds:[si]
	add	di, ds:[di].LettersComp_offset
	tst	ds:[di].LCC_colBottom
	jz	useOurs
	tst	ds:[di].LCC_colMidsect
	jnz	useBitmapMargins
useOurs:
	mov	ax, 5
	mov	bp, ax
	mov	cx, ax
	mov	dx, ax
	ret

useBitmapMargins:
endif
	clr	ax				;top
	clr	bp				;left
	clr	cx				;right
	mov	dx, 5				;bottom
	ret
LettersCompGetMargins	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersCompGetMinSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the minimum size of the composite gadget.

CALLED BY:	UI (= MSG_VIS_COMP_GET_MINIMUM_SIZE )

PASS:		cga - flag for the video driver

RETURN: 	cx -- minimum width of composite
		dx -- minimum height of composite

DESTROYED:	cx, dx 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	10/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifndef GPC
LettersCompGetMinSize method LettersCompClass, MSG_VIS_COMP_GET_MINIMUM_SIZE
	mov	dx, MIN_HEIGHT		; minimum height of the gadget
	tst	es:[cga]
	jns	notCGA
	mov	dx, CGA_MIN_HEIGHT 	; minimum height of the gadget
notCGA:
	clr	cx
	ret
LettersCompGetMinSize	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Visually build letters class gadget. 

CALLED BY:	UI (= MSG_SPEC_BUILD)

PASS:		ds:si - instance data

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:
	Call your super class
	Dereference to instance data
	Initialize the size info
	Set various flags

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	10/3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersSpecBuild	method	LettersClass, MSG_SPEC_BUILD
	mov	di, offset LettersClass
	call	ObjCallSuperNoLock		; call its super class
	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset		; dereference to instance data
	mov	ds:[di].VI_bounds.R_left, LETTER_TAB_LEFT_BOUND
	mov	ds:[di].VI_bounds.R_top, LETTER_TAB_TOP_BOUND
	mov	ds:[di].VI_bounds.R_right, LETTER_TAB_RIGHT_BOUND
	mov	ds:[di].VI_bounds.R_bottom, LETTER_TAB_BOTTOM_BOUND
						; set size for letter gadget
	ornf	ds:[di].VI_geoAttrs, mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID \
				  or mask VGA_USE_VIS_SET_POSITION 
	ret
LettersSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles mouse presses over letter gadget.

CALLED BY:	UI (= MSG_META_START_SELECT)

PASS:		ds:si - instance data
		es - segment of LettersClass
		ax - The method
		cx - x position
		dx - y position
		bp low - ButtonInfo
		bp high - UIFunctionsActive

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:
	Are we in bounds?
	If not, exit
	Else do we have the mouse grab?
		if not get the mouse grab
	Are we selected?
	If not, exit
	Else process the even
	     release the mouse grab
	Exit

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	10/3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersStartSelect	method	LettersClass, MSG_META_START_SELECT
	test	bp, (mask UIFA_IN) shl 8	; is the event in our bounds?
	jz	replay				; jump if out of bounds

	mov	di, ds:[si]			; dereference the pointer
	add	di, ds:[di].Letters_offset	; access instance data
	test	ds:[di].LI_flag, mask LIF_GRAB	; do we have the mouse grab?
	jne	grabbed				; if so, skip

	ornf	ds:[di].LI_flag, mask LIF_GRAB	; set the grab mouse flag
	call	VisGrabMouse			; grab the mouse
grabbed:
	test	bp, (mask UIFA_SELECT) shl 8	; are we selected?
	jne	checkDP				; if so, skip 
replay:
	mov	ax, mask MRF_REPLAY		; replay the event
	jmp	exit
checkDP:
	test	bp, mask BI_DOUBLE_PRESS	; double clicked?
	je	notDP				; if not, skip

	call	VisReleaseMouse			; release the mouse grab
	tst	es:[doublePress]		; triple or more clicked?
	js	quit				; if so, quit
	tst	es:[gmb.GMB_numMainTab]			; is database empty?
	je	quit				; if so, quit

	; check to see if view menu is enabled

	mov	ax, es:[appFeatures]		; ax - features bits
	test	ax, mask GF_VIEW_MENU		; is view menu enabled?
	je	quit				; if not, quit

	; set up registers before calling the subroutine

	mov	bx, ds:[di].LI_interface	; bx - handle of Interface
	mov	dx, ds:[di].LI_menu		; dx - handle of MenuResource
	mov	ax, ds:[di].LI_search		; ax - handle of Search
	segmov	ds, es
	call	BringUpBothView			; go to both view
	mov	es:[doublePress], -1		; set double press flag
	jmp	quit
notDP:
	tst	es:[ignoreInput]		; ignore mouse press?
	js	done				; if so, just exit

	call	LettersButtonProcess		; process the event
done:
	call	VisReleaseMouse			; release the mouse grab
quit:
	mov	ax, mask MRF_PROCESSED		; we processed the event
exit:
	ret
LettersStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersButtonProcess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Processes the mouse events.

CALLED BY:	LettersStartSelect

PASS:		ds:[di] - instance data
		bp - mouse flags

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
	Create a gState
	Set it in invert mode
	Invert the letter button
	Destroy the gState

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	9/20/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersButtonProcess	proc	near	uses	si, di, bp
	.enter

	; create a new gState

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock		

	; check to see if it has create a valid gState

	tst	bp				
	je	exit				; if not, exit

	; process the mouse press

	mov	di, bp				; di - gState handle
	call	LettersButtonCalc		
	jc	skip
	call	LettersDrawLetterTab
skip:
	; destroy the gState

	call	GrDestroyState	 		
exit:
	.leave
	ret
LettersButtonProcess	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersButtonCalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates which button was pressed and inverts it.

CALLED BY:	LettersButtonProcess

PASS:		di - handle of gState
		ds:si - instance data

RETURN:		di - handle of gState
		carry set if the mouse is clicked outside letter tabs

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
	Calculate the row over which the mouse was pressed
	Calculate the column over which the mouse was pressed
	Calculate the letter ID number
	Invert the old letter if there was one 
	Calculate the area to invert for the new letter
	Invert the new letter
	Display the 1st record that starts with this letter

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	9/20/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersButtonCalc	proc	near
	LBC_yPos	local	word			; y position
	LBC_xPos	local	word			; x position
	LBC_rowNum	local	word			; letter number

	class	LettersClass
	
	.enter

	mov	LBC_xPos, cx		; save mouse x position
PZ <	add	dx, HEIGHT_OF_LETTER_TAB ; add one row for pizza	>
	mov	LBC_yPos, dx		; save mouse y position

	; cx - x mouse position, dx - y mouse position

	call	VisGetBounds			; get bounds of letter boxes

	; from the x, y position of the mouse press, we have to figure out
	; over which letter the mouse has been pressed and x, y coordinate
	; of top left corner of the letter tab polygon.

	add	bx, HEIGHT_OF_LETTER_TAB	; bx - boundary to compare with
	cmp	LBC_yPos, bx			; is it in the 1st row?
	jl	row1				; if so, skip
	add	bx, HEIGHT_OF_LETTER_TAB	; bx - boundary to compare with
	cmp	LBC_yPos, bx			; is it in the 2nd row?
	jl	row2				; if so, skip

	; the tab is in the third row

	add	ax, THIRD_ROW_LEFT_BOUND_ADJUST	; adjust left boundary
	sub	cx, THIRD_ROW_RIGHT_BOUND_ADJUST; adjust right boundary
	cmp	LBC_xPos, cx			; mouse click past right bounds?
	jg	exit				; if so, exit
	mov	cx, LBC_xPos			; cx - mouse x position
	sub	cx, ax				; cx - relative x pos inside box
	mov	ax, LTRN_ROW_1			; ax - row number
NPZ <	dec	bx				; adjust top position >
	mov	LBC_yPos, bx			; save y position
	jmp	calcCol				; jump to calculate coloumn #
row1:
	; the tab is in the first row

	add	ax, FIRST_ROW_LEFT_BOUND_ADJUST	; adjust left boundary
	sub	cx, FIRST_ROW_RIGHT_BOUND_ADJUST; adjust right boundary
	cmp	LBC_xPos, ax			; mouse click past left bounds?
	jl	exit				; if so, exit
	cmp	LBC_xPos, cx			; mouse click past right bounds?
	jg	exit				; if so, exit
	mov	cx, LBC_xPos			; cx - mouse x position
	sub	cx, ax				; cx - relative x pos inside box
	mov	ax, LTRN_ROW_3			; ax - row number

	sub	bx, HEIGHT_OF_LETTER_TAB - 1	; adjust top position
	mov	LBC_yPos, bx			; save y position
	jmp	short	calcCol			; jump to calculate column #
row2:
	; the tab is in the second row

	add	ax, SECOND_ROW_LEFT_BOUND_ADJUST	; adjust left boundary
	sub	cx, SECOND_ROW_RIGHT_BOUND_ADJUST	; adjust right boundary
	cmp	LBC_xPos, ax			; mouse click past left bounds?
	jl	exit				; if so, exit
	cmp	LBC_xPos, cx			; mouse clock past right bounds?
	jg	exit				; if so, exit
	mov	cx, LBC_xPos			; cx - mouse x position
	sub	cx, ax				; cx - relative x pos inside box
	mov	ax, LTRN_ROW_2			; ax - row number

	sub	bx, HEIGHT_OF_LETTER_TAB	; adjust top position
PZ <	inc	bx				; adjust top position	>
	mov	LBC_yPos, bx			; save y position
calcCol:
	mov	LBC_rowNum, ax 			; ax - row number

	; now calculate which column the tab is in

	cmp	cx, WIDTH_OF_LETTER_TAB+3	; is it the 1st tab in each row?
	jl	leadTab				; if so, skip
	mov	ax, cx				; ax - x position
	clr	dx				; dx:ax - dividend

	mov	bx, WIDTH_OF_LETTER_TAB		; bx - width of a tab
	div	bx				; divide x pos by width of tab
	jmp	getXPos
leadTab:
	clr	ax				; ax - column number is zero
	mov	dx, cx				; dx - remainder 
getXPos:
	add	LBC_rowNum, ax			; update the letter number
	mov	cx, LBC_xPos			; cx - mouse x position
	sub	cx, dx				; cx - left pos. of tab
	mov	bx, LBC_yPos			; bx - top pos. of tab
	mov	ax, LBC_rowNum			; ax - letter number
PZ <	sub	bx, HEIGHT_OF_LETTER_TAB	; bx - top pos. of tab 	>
	clc	
	jmp	quit
exit:
	stc					; carry set if out of bounds
quit:
	.leave
	ret
LettersButtonCalc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersDrawLetterTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert the letter tab that was clicked upon.

CALLED BY:	(INTERNAL) LettersButtonProcess

PASS:		ax - letter tab ID
		es - segment address of core block
		ds:si - instance data of LettersClass
		di - handle of gState

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersDrawLetterTab	proc	near

	class	LettersClass

	; check to see if this is a blank tab

	call	LettersCheckForBlankTab	
	jc	exit				; if blank, exit

	; uninvert a tab that has been inverted

	call	LettersUninvertTab		

	; now invert the new tab

	call	LettersInvertTab		; calculate all vertices

	; display the 1st record under this letter tab

	call	LettersDisplayRecord
exit:
	.leave
	ret
LettersDrawLetterTab	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersDisplayRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the 1st record under the letter tab that was
		clicked upon.

CALLED BY:	(INTERNAL) LettersDrawLetterTab

PASS:		es:bx - instance data
		di - handle of gState

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersDisplayRecord	proc	near	uses	di

	ptrIData	local		word	; offset to instance data 

	class	LettersClass

	.enter

	; save the coordinates of polygon within the instance data

	mov	ptrIData, bx
	push	di
	mov	di, ptrIData
	mov	di, es:[di]
	add	di, es:[di].Letters_offset	; access instance data
	mov	es:[di].LI_numPts, cx		; save # of pts in polygon
	add	di, offset LI_coordBuf		; es:di - beg. of coord buffer
	shl	cx, 1				; cx - # of words to copy
	rep	movsw				; copy buffer into instance data

	; send a message to GeoDex to display 1st record under this tab

	mov	ds:[ignoreInput], -1		; do not accept any more input
	mov	bx, ds:[processID] 		; bx - process ID
	mov	si, ptrIData
	push	ds
	segmov	ds, es				; ds - seg addr of instance data
	push	ds, si
	mov	si, ds:[si]
	add	si, ds:[si].Letters_offset	; access instance data
	ornf	ds:[si].LI_flag, mask LIF_INVERTED ; set the flag 
	mov	dx, ax				; dx - letter number
	mov	ds:[si].LI_letter, dx		; save letter number
	cmp	dx, MAX_NUM_OF_LETTER_TABS	; recycle tab?
	je	recycle				; if so, skip
	mov	ax, MSG_ROLODEX_FIND_LETTER	; ax - method number
	mov	di, mask MF_FIXUP_DS		; di - set flags
	call	ObjMessage			; call application thread
	pop	ds, si
	pop	es
	pop	di
	jmp	exit

	; "Recycle" tab is clicked upon.  Draw the next set of chars
recycle:
	mov	ax, MSG_ROLODEX_NEW		; ax - method number
	mov	di, mask MF_FIXUP_DS		
	call	ObjMessage			; clear the record fields
	pop	ds, si				; ds:si - instance data
	pop	es				; es - dgroup
	pop	di
	clr	es:[ignoreInput]
	mov	cx, 1				; no need to create gstate
	mov	dl, es:[curCharSet]		; dl - current char set index
	mov	dh, C_WHITE			; dh - ColorIndex
	call	DrawLetterTabs			; erase current letters
	inc	es:[curCharSet]			
	mov	cx, 1				; no need to create gstate
	mov	dl, es:[curCharSet]		; dl - current char set index
	mov	dh, C_RED			; dh - ColorIndex
	call	DrawLetterTabs			; draw the next set of chars
exit:
	.leave
	ret
LettersDisplayRecord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersCheckForBlankTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a blank tab has been clicked upon.

CALLED BY:	(INTERNAL) LettersDrawLetterTab	

PASS:		es - segment address of core block
			dgroup:numCharSet

RETURN:		carry set if blank tab 
		carry clear otherwise

DESTROYED:	nothing

SIDE EFFECTS:	ds:sortBuffer changed

PSEUDO CODE/STRATEGY:
		return (sortBuffer[0] == C_SPACE || == C_NULL)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision
	witt	2/94		NULL string same as blank

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersCheckForBlankTab		proc	near	uses	ax, bx, cx, dx,	si, di

	.enter
CheckHack < MAX_LETTER_TAB_SETS eq 2 >

	; if there is only one character set and upper right tab
	; has been clicked, then it must be a blank tab

	cmp	es:[numCharSet], 1
	jne	notOne

	cmp	ax, MAX_NUM_OF_LETTER_TABS
	je	blank
notOne:
	; if there are two character sets and upper right tab
	; has been clicked, then it must be "recycle" tab

	cmp	ax, MAX_NUM_OF_LETTER_TABS
	je	notBlank

	; get tab letter string

	mov	dl, al				; dl - letter tab ID
	call	LettersGetLetterTabChar		; sortBuffer - tab letter 

	; check to see if this is a blank tab

	LocalLoadChar	ax, es:[sortBuffer]
	LocalCmpChar	ax, C_SPACE
	je	blank				; if so, exit with carry set
	LocalIsNull	ax
	je	blank
notBlank:
	clc
	jmp	exit
blank:
	stc
exit:
	.leave
	ret
LettersCheckForBlankTab		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersGetLetterTabChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the letter tab ID, figures out what string is 
		embedded in the tab. 

CALLED BY:	(GLOBAL) MSG_LETTERS_GET_TAB_LETTER

PASS:		dl - letter tab ID
		es - segment address of dgroup

RETURN:		dgroup:sortBuffer - current letter string
		dgroup:curLetterLen - length of sortBuffer (w/out C_NULL)

DESTROYED:	ax, cx, dx

SIDE EFFECTS:	Instead of returning values, this routine changes
		global variables.  BASIC is your friend.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	8/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersGetLetter   method  LettersClass, MSG_LETTERS_GET_LETTER
	mov	cx, ds:[di].LI_letter
	ret
LettersGetLetter	endm

LettersGetLetterTabChar   method  LettersClass, MSG_LETTERS_GET_TAB_LETTER
	uses	bx, si, di, ds
	.enter

	; lock the resource block with character sets

	GetResourceHandleNS	TextResource, bx
	call	MemLock				
	mov	ds, ax				
	mov	si, offset LetterTabCharSetTable
	mov	si, ds:[si]			; dereference the handle

	; locate the current character set

	clr	ch
	mov	cl, es:[curCharSet]
EC <	cmp	cl, MAX_LETTER_TAB_SETS				>
EC <	ERROR_GE  CHAR_SET_INDEX_TOO_BIG			>

	shl	cx, 1				; array of 'nptr's
	add	si, cx				
	mov	si, ds:[si]			
	mov	si, ds:[si]			; dereference the handle

	; now locate the current character string withing the char set

	clr	dh
	shl	dx, 1				; array of 'nptr's
	add	si, dx				; go to the correct string
	mov	si, ds:[si]			; dereference the handle
	mov	si, ds:[si]			; ds:si - string on letter tab

	; copy the character string into 'sortBuffer' buffer,
	;  counting chars as we go.

	mov	cx, -1				; counter
	mov	di, offset sortBuffer		; return letter tab to caller
strCpy:
	inc	cx
	LocalGetChar	ax, dssi
	LocalPutChar	esdi, ax		; copy a character
	LocalIsNull	ax			; done copying?

	jne	strCpy				; if not, continue

	mov	es:[curLetterLen], cx		; save length of tab string 
EC <	cmp	cx, MAX_TAB_LETTER_LENGTH	; copied to many?	>
EC <	ERROR_G  LETTER_TAB_STRING_TOO_LONG	; ouch!			>

	call	MemUnlock			; unlock text block

	.leave
	ret
LettersGetLetterTabChar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersUninvertTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Uninvert a letter tab that is already inverted

CALLED BY:	(INTERNAL) LettersDrawLetterTab

PASS:		ds:si - instance data 
		di - handle of gState

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	10/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersUninvertTab	proc	near	uses	ax, bx, cx, dx, si

	class	LettersClass

	.enter

	; check to see if there is a tab that has been inverted

	mov	si, ds:[si]
	add	si, ds:[si].Letters_offset	
	test	ds:[si].LI_flag, mask LIF_INVERTED 
	je	exit				; if not, exit

	; set to invert mode

	mov	al, MM_INVERT
	call	GrSetMixMode			

	; invert back a tab that has already been inverted

	mov	cx, ds:[si].LI_numPts		; cx - # of pts in polygon
	add	si, offset LI_coordBuf 		; ds:si - ptr to coord. buffer
	mov	al, RFR_ODD_EVEN		; al - use odd-even rule
	call	GrFillPolygon			; invert the old letter button
	sub	si, offset LI_coordBuf		; ds:si - beg of instance data
	andnf	ds:[si].LI_flag, not mask LIF_INVERTED ; clear the flag

	; set to normal mode

	mov	al, MM_COPY
	call	GrSetMixMode
exit:
	.leave
	ret
LettersUninvertTab	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersLostExclusive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when losing the grab of mouse.

CALLED BY:	UI (= MSG_VIS_LOST_GADGET_EXCL)

PASS:		ds:si	= Instance data

RETURN:		nothing

DESTROYED:	di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	10/3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersLostExclusive	method	LettersClass, MSG_VIS_LOST_GADGET_EXCL
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Letters_offset		; access instance data
	andnf	ds:[di].LI_flag, not mask LIF_GRAB	
						; clear the mouse grab flag
	ret
LettersLostExclusive	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersButtonInvert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inverts the letter that corresponds to the current record.

CALLED BY:	Resident Module (= MSG_INVERT_LETTER)

PASS:		cx - number of records in database
		dl - letter to invert
		if bp = 0, then create a new gstate
		else, bp contains a gstate handle 

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Create a new gState
	Invert the old letter button
	Calculate the top and bottom of new letter button
	Calculate the left and right of new letter button
	Invert the new letter button
	Destroy the gState

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	10/3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LBI_StackFrame	struct
	LBI_numRecords		word		; number of records
	LBI_instData		word		; ptr to instance data
	LBI_remainder		word		; remainder of letter ID/9
	LBI_rowNum		word		; letter tab ID
	LBI_gState		word		; handle of gState
	LBI_gStatePassed	byte		; flag
LBI_StackFrame	ends
	
LettersButtonInvert	method	LettersClass, MSG_LETTERS_INVERT
	uses	ax, bx, cx, dx, si, di, bp

	mov	di, bp				; save gState handle in DI

	LBI_Local	local 	LBI_StackFrame
	.enter

	mov	LBI_Local.LBI_gStatePassed, TRUE; assume gState is passed
	tst	di				; gState handle passed?
	jne 	passed				; if so, skip
	mov	LBI_Local.LBI_gStatePassed, FALSE ; if not, set the flag

	; otherwise, create a new gState 

	push	bp
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock		; create gState
	mov	di, bp
	pop	bp
	tst	di				; valid gState?
	LONG	je	exit			; if not, exit
passed:
	mov	LBI_Local.LBI_gState, di
	mov	LBI_Local.LBI_numRecords, cx	; save number of records
	clr	dh
	mov	LBI_Local.LBI_rowNum, dx	; save current letter
	mov	LBI_Local.LBI_instData, si	; save ptr to instance data
	
	call	VisGetBounds			; get the bounds of gadget
	push	ax, bx				; save left and top

	tst	LBI_Local.LBI_numRecords	; is database empty?
	jne	notEmtpy			; if not, skip

	mov	si, ds:[si]
	add	si, ds:[si].Letters_offset	; access instance data
	mov	ds:[si].LI_letter, -1		; set a flag to indicate no data
notEmtpy:
	mov	ax, LBI_Local.LBI_rowNum	; save letter ID
	clr	dx				; dx:ax - dividend
	mov	bx, NUMBER_OF_TABS_IN_ONE_ROW	; bx - divisor
	div	bx				
	mov	LBI_Local.LBI_remainder, dx	; save the remainder

	; Now calculate the top left coordinate of the letter tab polygon
	; because the routine 'InvertTab' expect this coordinate to be 
	; passed.  And it uses this coordinate to figure out the rest of
	; the coordinates in letter tab polygon.

	clr	dx
	mov	ax, WIDTH_OF_LETTER_TAB		; dx:ax - multiplicand
	mov	cx, LBI_Local.LBI_remainder	; cx - multiplier
	mul	cx				; multiply remainder by width
	mov	cx, ax				; cx - x position

	mov	ax, LBI_Local.LBI_rowNum	; ax - letter ID
	sub	ax, LBI_Local.LBI_remainder	; ax - row ID

	pop	dx, bx				; restore top and left
	add	cx, dx				; cx - x position

	cmp	ax, LTRN_ROW_3			; is it in row 3?
	jne	row2				; if not, skip

	add	cx, X_POS_ADJUST_ROW_ONE	; if so, adjust x position
	inc	bx				; adjust y position
	jmp	short	calcCol
row2:
	cmp	ax, LTRN_ROW_2			; is it in row 2?
	jne	row3				; if not, skip
	add	cx, X_POS_ADJUST_ROW_TWO	; if so, adjust x position
	add	bx, Y_POS_ADJUST_ROW_TWO	; adjust y position
	jmp	short	calcCol
row3:						; must be in row one
	add	cx, X_POS_ADJUST_ROW_THREE	; adjust x position
	add	bx, Y_POS_ADJUST_ROW_THREE	; adjust y position
calcCol:
	mov	ax, LBI_Local.LBI_rowNum	; ax - letter ID
	call	LettersInvertTab		; inver the tab
	mov	di, LBI_Local.LBI_instData	; di - ptr to instance data
	mov	di, es:[di]
	add	di, es:[di].Letters_offset	; access instance data
	mov	es:[di].LI_letter, ax
	mov	es:[di].LI_numPts, cx		; save # of pts in polygon
	add	di, offset LI_coordBuf		; di - ptr to coord buffer
	shl	cx, 1				; cx - # of pts to copy
	rep	movsw				; copy the coord buffer

	segmov	ds, es
	mov	si, LBI_Local.LBI_instData	; save ptr to instance data
	mov	si, ds:[si]
	add	si, ds:[si].Letters_offset	; access instance data
	ornf	ds:[si].LI_flag, mask LIF_INVERTED ; set flag 

	cmp	LBI_Local.LBI_gStatePassed, TRUE; was gState handle passed?
	je	exit				; if so, just exit

	; if a new gState was created in this routine, destroy it

	mov	di, LBI_Local.LBI_gState
	call	GrDestroyState 			; destroy the gState
exit:
	.leave
	ret
LettersButtonInvert		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LettersButtonClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Uninverts a letter tab before closing a data file.

CALLED BY:	Application thread

PASS:		*ds:si - instance data of LettersClass

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	10/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LettersButtonClear	method	LettersClass, MSG_LETTERS_CLEAR
	uses	ax, bx, cx, dx, si, di, bp
	.enter
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock		; create gState
	tst	bp				; valid gState?
	je	exit				; if so, skip

	mov	di, bp				; di - handle of gState
	mov	al, MM_INVERT
	call	GrSetMixMode			; set to invert mode

	mov	si, ds:[si]			; dereference handle
	add	si, ds:[si].Letters_offset	; access instance data

	test	ds:[si].LI_flag, mask LIF_INVERTED  ; is there a tab inverted?
	je	quit				; if not, skip

	mov	cx, ds:[si].LI_numPts		; cx - # of pts in polygon
	add	si, offset LI_coordBuf		; ds:si - ptr to coord buffer
	mov	al, RFR_ODD_EVEN		; use the odd even rule
	call	GrFillPolygon			; invert old letter button 
	sub	si, offset LI_coordBuf		; ds:si - beg of instance data
	andnf	ds:[si].LI_flag, not mask LIF_INVERTED	; clear invert flag
quit:
	mov	al, MM_COPY	
	call	GrSetMixMode			; set to normal mode
	call	GrDestroyState 			; destroy the gState
exit:
	.leave
	ret
LettersButtonClear	endm


LettersCode ends
