COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Screen
FILE:		screenLocal.asm

AUTHOR:		Dennis Chow, September 8, 1989

METHODS:
	Name			Description
	----			-----------

ROUTINES:
	Name			Description
	----			-----------
    INT DrawDocument            Draw the screen object (or the lines that
				are currently visible)

    INT BufStoreData            Store screen data in screen buffer

    INT StoreCharAttr           Store character attributes

    INT AddCharAttr             Store character attributes

    INT ClearCharAttr           Store character attributes

    INT BufGetPutCurChar        Get/Put the character at the current cursor

    INT BufGetPutCurCharLow     Get/Put screen data from/to screen buffer

    INT CheckForScroll          Check if the document should scroll

    INT CalcCursorPos           calculate document coordinates to draw to,
				from cursor position and winTopLine

    INT GetCurCharFromCurPos    calculate document coordinates to draw to,
				from cursor position and winTopLine

    INT GetCurPosFromCurChar    calculate document coordinates to draw to,
				from cursor position and winTopLine

    INT EraseRemLine            Erase from the current position to end of
				line

    INT EraseBegLine            Erases from beginning of line to cursor

    INT DrawTextLine            Draw from current cursor position to end of
				line

    INT ScreenSetFont           Set the screen font and font info

    INT DrawCursor              draw cursor by inverting bits

    INT DrawSelectCursor        draw cursor by inverting bits

    INT EraseCursor             erase the cursor

    INT ToggleCursor            xor the cursor (either clears or sets it)

    INT BufScrollUp             Scroll our copy of the screen image

    INT BufScrollDown           Add a blank line to screen by scrolling
				lines down

    INT BufDelLine              Delete current line from screen buffer

    INT BufClearLine            Clear from the cursor to the end of current
				line

    INT BufClearToEndLine       Clear from the cursor to the end of current
				line

    INT BufClearToBegLine       Clear from the cursor to the beginning of
				current line, inclusive

    INT BufClear                Clear the screen buffer from cursor
				position down.

    INT BufClearUpward          Clear the screen buffer from top of screen
				to line containing cursor (inclusive)

    INT WinClearToEnd           Clear window from cursor on

    INT WinClearToBeg           Clear window from beginning to cursor

    INT WinClear                Whiteout the visible window region

    INT BufShiftLineRight       Shift the characters in the current line to
				the right

    INT BufShiftLineLeft        Shift the characters in the current line to
				the left

    INT WinScrollDown           Insert a line in the window

    INT WinScrollUp             Shifts all lines up to the current line, up
				one line

    INT WinDelLine              Deletes current line on window

    INT WinClearLine            Clears the current line on the window

    INT ScrollDrawLines         Draw lines from scroll buffer that are
				invalid

    INT ScrollSaveLine          Add the line at the top of screen to the
				scroll buffer

    INT ScreenClearScreenAndScrollBufResetParams 
				Reset some paramters of screen object when
				clearing screen and scroll buffer

    INT ScreenClearScrollBuf    Clear the screen scroll bufffer

    INT ScrollLinesToDisk       Write line from scroll buffer to disk

    INT LinesToDisk             Write buffer lines to disk

    INT GetDrawLines            Calculate which lines in document need
				redrawing

    INT ScrollResetView         Scroll the view to make the cursor visible

    INT BufDrawLines            Redraw lines in screen buffer

    INT SetGraphicsMode         Sets the TextColor and the AreaColor for
				current GState

    INT SetFontNewScreen        adjust the current screen to the new
				document size

    INT FontNewScreenSetOrigin  Set the GenView document origin when
				changing font

    INT FontNewScreenSetInc     Set the increment amount for GenView object

    INT GetViewTopLineNum       Get the line number of top line of window

    INT WinInvalScreen          Invalidate current screen

    INT EraseDrawLine           Erase the line in preparation for a
				DrawRemLine call

    INT DrawRemLine             Draw current line paying attention to any
				graphic attributes in the line.

    INT CmpEvenOdd              Compares odd and even nibbles

    INT CmpOddEven              Compares odd and even nibbles

    INT SetLineAttribute        Process line attribute

    INT SetNormalAttribute      Set normal attributes

    INT SetTextStyleNormalAttr  Set normal attributes

    INT SetNormalAttribute      Set normal attributes

    INT SetReverseAttribute     Set normal attributes

    INT SetBoldAttribute        Set normal attributes

    INT SetUnderlineAttribute   Set normal attributes

    INT SetCharacterSet         Set the character set

    INT ScreenSetUSASCIICommon  Set the current character set to USASCII

    INT ScreenSetGraphicsCommon Set the current character set to graphics

    INT DoVisualBell            make screen flash

    INT DoCursorDown            handle actions involved with a cursor down
				motion

    INT DoNewLine               Move the cursor to start of a new line

    INT DrawBoxCursor           draw an outline cursor

    INT EraseBoxCursor          draw an outline cursor

    INT GetBoxCoord             calculate cursor dimensions

    INT DoArrowKey              Send arrow key sequence depending on
				terminal

    INT ConvertToTextCoords     Covert mouse coordinate to character
				coordinates

    INT SelectWord              Select the word at the mouse position

    INT SelectLine              Select the line at the mouse position

    INT GetWordBounds           Find start and end of word at mouse
				position

    INT HighlightText           Hightlight text

    INT UnHighlightText         unhighlight text

    INT DoTextAttribute         store attributes into character data

    INT AdjustSelection         expand or contract the selected area.

    INT SelectRight             Mouse moved right

    INT SelectLeft              Mouse moved left

    INT LineSelectUp            adjust selected area for a mouse movement
				up

    INT LineSelectDown          adjust selected area for a mouse movement
				down

    INT GetScreenLine           get screen line the mouse is on

    INT GetScrollLine           get Scroll line the mouse is on

    INT UnSelectArea            unselect text

    INT UnHighlightArea         unselect text

    INT DrawScrollLine          print line of text interpreting graphic
				attributes

    INT EraseScrollLine         erase text in the scroll buffer

    INT DrawScrollText          erase text in the scroll buffer

    INT GetSelectLine           return ptr to text of the line selected

    INT FreeSelectLine          check if scroll segment should be unlocked

    INT PasteText               Handle when text object scrap is dropped on
				us

    INT PasteTransferItem       Send the text portion of the transfer item
				out the port

    INT MakeTransferItem        Make the selected text into a transfer item

    INT CreateTransferItem      create a transfer item

    INT CopySelectText          copy the selected text into a buffer

    INT CopyText                copy text into vm segment

    INT CheckSelectTopBottom    ensures that selectStartLine is above
				selectEndLine

    INT GetSelectSize           Get number chars in selected area

    INT ScrollSelectRegion      adjust selected region when have to scroll
				the document

    INT CheckSelectRegion       adjust selected region when have to scroll
				the document

    INT ResetWindow             adjust selected region when have to scroll
				the document

    INT CheckWinWidth           Check that the view width is a multiple of
				the character width

    INT CheckWinHeight          Check that the view height is a multiple of
				the character height

    INT UpdateWinDisplay        Set text in window range objects to reflect
				window size

    INT GetLineLength           Get line length

    INT CheckViewSize           Get line length

    INT CalcTextLines           check how many lines of text can be
				displayed on the screen

    INT RestoreScreenState      check state of screen UI objects

    INT ResetView               check state of screen UI objects

    INT RestoreFontSize         check state of screen UI objects

    INT RestoreAutoWrap         check state of screen UI objects

    INT RestoreAutoLinefeed     check state of screen UI objects

    INT CheckCursorInSelect     check if cursor in selected region

    INT CheckCoordInSelect      check if passed coordinates are in the
				selected region

    INT CheckCursorErased       check if cursor erased when selecting
				region

    INT IsCursorInDragSelect    check if cursor in drag select region

    INT StartCapture            Start capturing stuff

    INT ScreenLinesToDisk       Write screen buffer to disk

    INT CaptureDone             Screen or Scroll capture done

    INT RecalcSize              Calc new size for window based on new font

    INT GetScreenHeight         Calc new size for window based on new font

    INT GetScreenWidth          Calc new size for window based on new font

    INT GetDefaultScreenHeight  Calc default height for window based on new
				font.

    INT GetDefaultScreenWidth   Calc default width for window.

    INT EnableEditMenu          Enable the edit menu caus focus back in
				screen object

    INT DisableEditMenu         Enable the edit menu caus focus back in
				screen object

    INT DorkEditMenu            send each entry in the edit menu a method

    INT DisableCopy             enable the Copy entry of the Edit Menu

    INT EnableCopy              enable the Copy entry of the Edit Menu

    INT DorkCopy                enable the Copy entry of the Edit Menu

    INT CheckScreenBuf          enable the Copy entry of the Edit Menu

    INT NullScreenBuf           enable the Copy entry of the Edit Menu

    INT CheckHalfWidth          enable the Copy entry of the Edit Menu

    INT ScreenSendNumKeypadKey  Send out the keypad keys as typed in
				keyboard

    INT ScreenSendAppKeypadKey  Send out keypad key codes in Application
				mode

    INT ScreenHandleIntlChar    Handle international characters

    INT ScreenIsCursorVisible	Check to see if the cursor is visible in
				current zooming mode 

    INT ScreenIsCursorInLowerScreen
				Is the cursor in lower half of screen when we
				are to zoom in? Assuming the cursor is
				already visible  
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc       9/ 8/89        Initial revision.

DESCRIPTION:
	Internally callable routines for this module.

	$Id: screenLocal.asm,v 1.1 97/04/04 16:55:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the screen object (or the lines that are currently visible)

CALLED BY:	ScreenDraw
PASS:		ds:si	- instance data	
		di	- gState handle
		es	- dgroup
		SI_screenBuf	- unlocked segment

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		Get lines to draw from scroll buffer
		Get lines to draw from screen buffer

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 8/24/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocument	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	noDraw
	mov	bx, ds:[si][SI_screenHandle]
	call	MemLock
	mov	ds:[si][SI_screenBuf], ax
	mov	al, ds:[si][SI_fontColor]
	mov	ah, CF_INDEX 		;set color to black
	call	GrSetTextColor			;
	call	GetDrawLines			;get lines to redraw
	jc	exit				;exit if document dorked
	mov	ah, {byte}ds:[si][SI_winTopLine];get line at top of screen
	mov	al, ah 				;
	add	al, MAX_LINES			;get line at bot of screen
	;
	; AH = window's top line#
	; AL = window's bottom line#
	; BH = 1st line to draw
	; BL = last line to draw
	;
	cmp	bh, ah				;is first line in scroll buf? 
	jae	inScreen			;nope
	push	ax, bx
	cmp	bl, ah				;is last line in scroll buf?
	jb	doScroll			;yes
	mov	bl, ah				;nope, so draw only lines
;	dec	bl				;	in scroll buffer
doScroll:
	call	ScrollDrawLines
	pop	ax, bx
inScreen:
	cmp	bl, al				;is last line above screenBot
	jbe	doScreen			;yes
	cmp	bh, al				;is first line in screen
	jae	notInScreen			;nope, exit
	mov	bl, al				;first, but not last line
	
NRSP <	jmp	screenDraw			;in screen		>
RSP <	jmp checkScroll							>
notInScreen:
	mov	ds:[si][SI_inScroll], TRUE	;no, scroll past screen, exit
	jmp	exit
doScreen:
	cmp	bl, ah				;is last line below screenTop
	jb	exit				;yes, exit
	cmp	bh, ah				;is first line in screen
NRSP <	jae	screenDraw						>
RSP <	jae	checkScroll						>
	mov	bh, ah				;bx = draw from winTopLine
checkScroll::
	

screenDraw:
	call	BufDrawLines
exit:
	mov	bx, ds:[si][SI_screenHandle]
	call	MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>
noDraw:
	ret					
DrawDocument	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufStoreData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store screen data in screen buffer

CALLED BY:	(INTERNAL) ScreenData
PASS:		ds:si	- screen object instance data	
		di	- GState
		dl	- char to save	
		es	- dgroup
		bp	- ptr into character buffer

RETURN:		nothing

DESTROYED:	ax	

PSEUDO CODE/STRATEGY:
	Store the character in the screen buffer at the cursor position.
	If graphical attributes set, store those too

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 10/04/89	Initial version
	dennis	 10/20/89	Revised to use screen not scroll buffer
	dennis	 01/12/90	Revised to save graphic attributes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufStoreData	proc	near
class	ScreenClass				;we're friends with ScreenClass
	push 	es, bp, bx, cx 			;save dgroup 
EC <	call	CheckScreenBuf						>
	mov	es, ds:[si][SI_screenBuf]	;access screenBuffer
	mov 	ah, {byte} ds:[si][SI_curLine]		;
	clr	al				;shift 7 bits to get
SBCS <	shr	ax, 1				;   ptr to line in screenBuf>
	mov	bx, ax				;   (save ptr to start of line)	
	mov	cx, ds:[si][SI_curChar]		;   go to position in line
	add	ax, cx
DBCS <	add	ax, cx				;char offset -> byte offset>
	mov	bp, ax				;put ptr in index register
if ERROR_CHECK
	push	ds, si
	segmov	ds, es
	mov	si, bp
	call	ECCheckBounds
	pop	ds, si
endif
SBCS <	mov	es:[bp], dl			;  stuff char into screen buf>
DBCS <	mov	es:[bp], dx			;  stuff char into screen buf>
	mov	al, ds:[si][SI_attributes]	;pass attributes to store
	call	StoreCharAttr			;  and store attribute info
	pop	es, bp, bx, cx
	ret
BufStoreData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreCharAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store character attributes

CALLED BY:	BufStoreData, HighlightText 

PASS:		ds:si	- screen object instance data	
		es:bx	- ptr to start of line in screen buffer
		cx	- col # of char
		al	- char attributes to store

RETURN:		nothing

DESTROYED:	ax, bx, cx		

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	02/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StoreCharAttr	proc	near
if DBCS_PCGEOS
	add	bx, LINE_GRAFX_START
	add	bx, cx				;offset to col attribute
	mov	es:[bx], al			;store new attributes
else
	mov	ah, al				;copy the attribute settings
	add	bx, LINE_GRAFX_START
	shr	cx, 1				;convert col# to attribute byte
	jc	doOdd
doEven:
	add	bx, cx				;offset to col attribute
	mov	cl, 4				;shift the bit masked over
	shl	al, cl				;  so high nibble used for
	mov	ch, es:[bx]			;get attriubte byte
	and	ch, ODD_COL_MASK		;nuke even col attributes 
	or	ch, al				;set current attributes
	mov	es:[bx], ch			;and store it back in
	jmp	short exit
doOdd:
	add	bx, cx				;offset to col attribute
	mov	al, es:[bx]			;get char attributes
	and	al, EVEN_COL_MASK		;isolate col attributes
	or	al, ah				;set new attributes
	mov	es:[bx], al
exit:
endif
	ret
StoreCharAttr	endp

AddCharAttr	proc	near
if DBCS_PCGEOS
	add	bx, LINE_GRAFX_START
	add	bx, cx				;offset to col attribute
	or	es:[bx], al
else
	mov	ah, al				;copy the attribute settings
	add	bx, LINE_GRAFX_START
	shr	cx, 1				;convert col# to attribute byte
	jc	doOdd
doEven:
	add	bx, cx				;offset to col attribute
	mov	cl, 4				;shift the bit masked over
	shl	al, cl				;  so high nibble used for
	mov	ch, es:[bx]			;get attriubte byte
;;	and	ch, ODD_COL_MASK		;nuke even col attributes 
	or	ch, al				;set current attributes
	mov	es:[bx], ch			;and store it back in
	jmp	short exit
doOdd:
	add	bx, cx				;offset to col attribute
	mov	al, es:[bx]			;get char attributes
;;	and	al, EVEN_COL_MASK		;isolate col attributes
	or	al, ah				;set new attributes
	mov	es:[bx], al
exit:
endif
	ret
AddCharAttr	endp

ClearCharAttr	proc	near
if DBCS_PCGEOS
	add	bx, LINE_GRAFX_START
	add	bx, cx				;offset to col attribute
	not	al				; create mask of bits to keep
	and	es:[bx], al
else
	mov	ah, al				;copy the attribute settings
	add	bx, LINE_GRAFX_START
	shr	cx, 1				;convert col# to attribute byte
	jc	doOdd
doEven:
	add	bx, cx				;offset to col attribute
	mov	cl, 4				;shift the bit masked over
	shl	al, cl				;  so high nibble used for
	mov	ch, es:[bx]			;get attriubte byte
;;	and	ch, ODD_COL_MASK		;nuke even col attributes 
	not	al				; create mask of bits to keep
	and	ch, al				; clear unwanted attributes
	mov	es:[bx], ch			;and store it back in
	jmp	short exit
doOdd:
	add	bx, cx				;offset to col attribute
	mov	al, es:[bx]			;get char attributes
;;	and	al, EVEN_COL_MASK		;isolate col attributes
	not	ah				; create mask of bits to keep
	and	al, ah				; clear unwanted attributes
	mov	es:[bx], al
exit:
endif
	ret
ClearCharAttr	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForScroll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the document should scroll

CALLED BY:	(INTERNAL) DoCursorDown
PASS:		ds:si		- instance data	
		di		- GState
		[SI_screenBuf]	- unlocked segment

RETURN:		C		- clear if scroll done
				- set   if scroll not done
		SI_winTopLine	- set to line at top of window

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The 'jz scroll' is a hack, sometimes deleteing
		lines is implemented through scroll regions.  To delete
		line 6 they set the scroll reg top to line 5 then they
		go to the bottom of screen and have you scroll up to
		delete line 6 (lines 0-5 remain untouched).  
		In this case I want to handle my own scrolling and not
		adjust winTopLine or any of the other dorky variables.

		bugs? too many to mention.
		Well there may or may not be an off by 1 error at
		the bottom of the window when trying to use BISON 9.
		See if hacking results from GrGetWinBounds helps.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 8/30/89	Initial version
	dennis	01/11/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckForScroll	proc	near
class	ScreenClass				;we're friends with ScreenClass
	mov	bx, ds:[si][SI_screenHandle]
	call	MemLock
	mov	ds:[si][SI_screenBuf], ax
	tst	ds:[si][SI_scrollRegTop]
	jnz	10$			;do we scroll
	clr	ah
	mov	al, ds:[si][SI_maxLines]	;get line for bottom of screen
	dec	ax				;
	cmp	ds:[si][SI_scrollRegBot], ax	;
	je	scroll				;check if ui/or we scroll
10$:
	mov	ax, ds:[si][SI_curLine]
	cmp	ds:[si][SI_scrollRegBot], ax
	je	scrollOneLine	
	stc
	jmp	exit
scrollOneLine:
	call	BufScrollUp			;Hack for dorked VI scroll
	call	BufClearLine
	call	WinScrollUp
	clc					; indicate scroll done
	jmp	exit	
scroll:
	call	CalcCursorPos			;get top of cursor 
						;  USE LAST SAVED POS?
	cmp	ds:[si][SI_gState], BOGUS_VAL	;if no gState then check
	jne	20$				; stored window bounds if we
	cmp	bx, ds:[si][SI_winBottom]	; should scroll	screen
	ja	yesScroll
	jmp	noScroll
20$:
	cmp	di, BOGUS_VAL			; no gstate?
	LONG je	noScroll			; yep
	push	bx				;  and save it 
	call	GrGetWinBounds			;get height of window 

;
; okay there was a bug where if they shrank the view so the cursor
; was below the view then the window wouldn't update properly.  Because
; I assumed that the area to scroll would be entirely within the window
;
	mov	di, ds:[si][SI_lastCursorY]	
	add	di, ds:[si][SI_lineHeight]
	cmp	dx, di
	ja	30$
	mov	dx, di	
30$:
	sub	cx, ax				;

	mov	di, dx				;save bottom of window
	sub	dx, ds:[si][SI_lineHeight]	;offset win bot by line height
	mov	bp, dx 				;  (save window height - 1 line)
	;
	; The above SUB instruction has already subtracted window
	; height. This instruction is not really necessary.  
	; 				-simon 1/14/96
	;
NRSP <	sub	dx, ds:[si][SI_lineHeight]	;offset window by cursor height>
	pop	ax				; restore top of cursor 
	cmp	ss:[forceScroll], TRUE		;if forceing scroll
	je	yesScroll			;then do it
	cmp	ax, dx				; is cursor beneath window
	LONG jbe	noScroll		; nope, no need to scroll 
yesScroll:					; yes, we have to scroll
	cmp	ds:[si][SI_wrap], TRUE		;check if we're scrolling
	je	weScroll			; yes,
	cmp	ds:[si][SI_winTopLine], SCROLL_LINES
	jb	uiScroll			;ui scroll if not at last screen
;checkDoc:
;	mov	dx, ds:[si][SI_docHeight]	;
;	sub	dx, ds:[si][SI_lineHeight]	;
;	cmp	di, dx				;is cursor at end of document?
;	jbe	uiScroll			;nope ui scroll
weScroll:
	mov	ds:[si][SI_wrap], TRUE		;  flag that we scroll 
	mov	ax, bp				; height of region to scroll is	
	sub	ax, bx				; 	bottom - top
	push	ax				;pass height of scroll area
	mov	ax, BLTM_CLEAR		;pass scroll flags	
	push	ax
	mov	dx, bx				;dest (Y) is top of window
	add	bx, ds:[si][SI_lineHeight]	;src  (Y) is one line below top
	mov	di, ds:[si][SI_gState]
	cmp	di, BOGUS_VAL			;calling HACKMASTER!	
	je	screwBlt			;exit if no GState 
	mov	bp, si				;  (save ptr to instance)
	mov	si, cx				;pass width of the window
	clr	ax				;set source X pos
	mov	cx, ax				;set dest   X pos	
	call	GrBitBlt
	mov	si, bp				;  (restore ptr to instance)
	jmp	scrollRet
screwBlt:
	pop	ax				;pop BitBlt parameters off
	pop	ax				;	stack
	jmp	scrollRet
uiScroll:	
	inc	ds:[si][SI_winTopLine]		; 
	mov	di, ds:[si][SI_gState]
	push	di, si				;
	mov	dx, size PointDWord		; allocate room for stack params
	sub	sp, dx
	mov	bp, sp
	clr	ax 				;don't scroll horizontally
	mov	ss:[bp].PD_x.low, ax		;don't scroll horizontally
	mov	ss:[bp].PD_x.high, ax
	mov	ss:[bp].PD_y.high, ax
	mov	ax, ds:[si][SI_lineHeight]	;just one line vertically
	mov	ss:[bp].PD_y.low, ax		;use line height vertically
	GetResourceHandleNS	TermView, bx
	mov	si, offset TermView
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	mov	ax, MSG_GEN_VIEW_SCROLL
	call	ObjMessage
	add	sp, size PointDWord
	pop	di, si
scrollRet:
	call	BufScrollUp
	call	BufClearLine
	clc					;signal scrolling done
	jmp	short exit
noScroll:
	mov	di, ds:[si][SI_gState]		;restore gState
	stc
exit:
	pushf					;don't trash flag to tell  
	mov	bx, ds:[si][SI_screenHandle]	;  if we scrolled or not
	call	MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>
	popf
	ret
CheckForScroll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcCursorPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calculate document coordinates to draw to, from cursor 
			position and winTopLine

CALLED BY:	DrawCursor, DrawRemLine, EraseRemLine, CheckForScroll

PASS:		ds:si	- screen object instance data	

RETURN:		ax, bx 	- top of cursor (in document coordinates)

DESTROYED:	ax, bx, cx, dx	

PSEUDO CODE/STRATEGY:
		cursor position (lines, cols) relative to window and
		window relative to scroll buffer.
		So get line at top of window calculate its absolute
		document coordinate and then offset from there to current
		position

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 8/23/89	Initial version
	dennis	10/11/89	Using new screen circular data structures

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcCursorPos	proc	near
class	ScreenClass				;we're friends with ScreenClass
	mov	ax, ds:[si][SI_winTopLine]	;get line# at top of window
	add	ax, ds:[si][SI_curLine]		;offset to current line
	cmp	ax, DOC_LINES			;if printing outside document
	jl	getYPos				;then adjust to print to
	mov	ax, DOC_LINES-1			;bottom of screen.
getYPos:
if HALF_AND_FULL_WIDTH and not CURSOR
	push	ax
endif
	mov	cx, ds:[si][SI_lineHeight]	;get the line height	
	mul	cl				;calculate document Y coord
	mov	bx, ax				;  and save it

if HALF_AND_FULL_WIDTH	;-----------------------------------------------------
if CURSOR
	clr	ax
	mov	dx, ds:[si][SI_charWidth]	;get the line height	
	mov	cx, ds:[si][SI_curPos]
	jcxz	CPP_exit			;if cursor at 0, skip loop
CCP_X:
	add	ax, dx				;add the character width
	loop	CCP_X				; to figure x position
CPP_exit:
else ; not CURSOR
	pop	ax				; ax = line
	push	di
	clr	di				; trivial case: curChar = 0
	tst	ds:[si].SI_curChar
	jz	done
	push	bx, ds, si
	mov	cx, ds:[si].SI_curChar
	mov	dx, ds:[si].SI_charWidth	; dx = half-width char width
	cmp	ax, ds:[si].SI_winTopLine
	jae	inScreen
	mov	bx, ds:[si].SI_scrollHandle
	jmp	short haveLineOffset

inScreen:
	mov	bx, ds:[si].SI_screenHandle
	sub	ax, ds:[si].SI_winTopLine	; ax = line in screen buffer
haveLineOffset:
	mov	ah, al
	clr	al
SBCS <	shr	ax							>
	mov	si, ax				; si = offset within buffer
	call	MemLock
	mov	ds, ax				; ds:si = this line
checkChar:
	add	di, dx				; add in half-width char
	lodsw					; ax = char
	call	CheckHalfWidth
	jc	halfWidth
	add	di, dx				; else, full-width char
halfWidth:
	loop	checkChar
	call	MemUnlock
	pop	bx, ds, si
done:
	mov	ax, di
	pop	di
endif
else	; not HALF_AND_FULL_WIDTH --------------------------------------------
	clr	ax
	mov	dx, ds:[si][SI_charWidth]	;get the line height	
	mov	cx, ds:[si][SI_curChar]
	jcxz	CPP_exit			;if cursor at 0, skip loop
CCP_X:
	add	ax, dx				;add the character width
	loop	CCP_X				; to figure x position
CPP_exit:
endif	; not HALF_AND_FULL_WIDTH --------------------------------------------
	ret
CalcCursorPos	endp

if CURSOR
GetCurCharFromCurPos	proc	near
class	ScreenClass				;we're friends with ScreenClass
	uses	ax, bx, cx, dx
	.enter
	push	ds, si
	mov	ax, ds:[si][SI_winTopLine]	;get line# at top of window
	add	ax, ds:[si][SI_curLine]		;offset to current line
	cmp	ax, DOC_LINES			;if printing outside document
	jl	getYPos				;then adjust to print to
	mov	ax, DOC_LINES-1			;bottom of screen.
getYPos:
	clr	dx				; init curChar counter
	mov	cx, ds:[si].SI_curPos
	jcxz	done				; trivial case: curPos = 0
	cmp	ax, ds:[si].SI_winTopLine
	jae	inScreen
	mov	bx, ds:[si].SI_scrollHandle
	jmp	short haveLineOffset

inScreen:
	mov	bx, ds:[si].SI_screenHandle
	sub	ax, ds:[si].SI_winTopLine	; ax = line in screen buffer
haveLineOffset:
	mov	ah, al
	clr	al
SBCS <	shr	ax, 1							>
	mov	si, ax				; si = offset within buffer
	call	MemLock
	mov	ds, ax				; ds:si = this line
checkChar:
	lodsw					; ax = char
	call	CheckHalfWidth
	jc	halfWidth
	dec	cx				; adjust curPos for full-width
	jz	unlockDone			; in middle of full-width char!
halfWidth:
	inc	dx				; bump curChar counter
	dec	cx				; adjust for half-width
	jnz	checkChar
unlockDone:
	call	MemUnlock
done:
	pop	ds, si
	mov	ds:[si][SI_curChar], dx
	.leave
	ret
GetCurCharFromCurPos	endp
	
GetCurPosFromCurChar	proc	near
class	ScreenClass				;we're friends with ScreenClass
	uses	ax, bx, cx, dx
	.enter
	push	ds, si
	mov	ax, ds:[si][SI_winTopLine]	;get line# at top of window
	add	ax, ds:[si][SI_curLine]		;offset to current line
	cmp	ax, DOC_LINES			;if printing outside document
	jl	getYPos				;then adjust to print to
	mov	ax, DOC_LINES-1			;bottom of screen.
getYPos:
	clr	dx				; init curPos counter
	mov	cx, ds:[si].SI_curChar
	jcxz	done				; trivial case: curChar = 0
	cmp	ax, ds:[si].SI_winTopLine
	jae	inScreen
	mov	bx, ds:[si].SI_scrollHandle
	jmp	short haveLineOffset

inScreen:
	mov	bx, ds:[si].SI_screenHandle
	sub	ax, ds:[si].SI_winTopLine	; ax = line in screen buffer
haveLineOffset:
	mov	ah, al
	clr	al
SBCS <	shr	ax, 1							>
	mov	si, ax				; si = offset within buffer
	call	MemLock
	mov	ds, ax				; ds:si = this line
checkChar:
	inc	dx				; bump curPos for half-width
	lodsw					; ax = char
	call	CheckHalfWidth
	jc	halfWidth
	inc	dx				; bump curPos for full-width
halfWidth:
	loop	checkChar
unlockDone:
	call	MemUnlock
done:
	pop	ds, si
	mov	ds:[si][SI_curPos], dx
	.leave
	ret
GetCurPosFromCurChar	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseRemLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase from the current position to end of line

CALLED BY:	(INTERNAL) ScreenClearToEndLine, ScreenDelChar, WinClearLine
PASS:		ds:si		- instance data	
		di		- gState handle
		[SI_screenBuf]  - locked segment

RETURN:		nothing

DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraseRemLine	proc	near
class	ScreenClass				;we're friends with ScreenClass
	push	ax				;save #chars to erase
	cmp	di, BOGUS_VAL
	je	exit
	mov	al, ds:[si][SI_backColor]	; get back color
	mov	ah, CF_INDEX
	call	GrSetAreaColor			
	call	CalcCursorPos			; ax = left side, bx = top
	mov	cx, 880-1			; cx = max width of view
	mov	dx, bx
	add	dx, ds:[si][SI_lineHeight]	; dx = bottom of line to erase
;	dec 	dx				; adjust for 1-bit wide border
	call	GrFillRect			;and white out screen
exit:
	pop	ax
	ret
EraseRemLine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseBegLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erases from beginning of line to cursor

CALLED BY:	INTERNAL ScreenClearToBegLine
PASS:		ds:si		- instance data	
		di		- gState handle
		[SI_screenBuf]  - locked segment
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraseBegLine	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit

	uses	ax, bx, cx, dx
	.enter

	mov	al, ds:[si][SI_backColor]	; get back color
	mov	ah, CF_INDEX
	call	GrSetAreaColor
	call	CalcCursorPos			; ax = left side, bx = top
	clr	cx
	xchg	cx, ax				; ax = left
	mov	dx, bx				; dx = top
	add	cx, ds:[si][SI_charWidth]	; cx = cursor right
	add	dx, ds:[si][SI_lineHeight]	; dx = cursor bottom
	call	GrFillRect			;and white out screen
	.leave
exit:
	ret
EraseBegLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTextLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw from current cursor position to end of line

CALLED BY:	DrawDocument, ScreenData

PASS:		ds:si	- screen instance data
		di	- GState
		ax	- #of chars to draw
		dx	- ptr to start of string to print

RETURN:		nothing

DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		Get cursor position	
		Get pointer to current line data	
		Draw line at cursor

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 8/24/89	Initial version
	dennis	10/11/89	Revised screen data structures

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawTextLine	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit
	push	ds, si, dx		 	;save ptr to instance
	push	dx				;save ptr to start of line
	push	ax				;save #chars to draw	
	call	CalcCursorPos			;get position to print at
	add	bx, ds:[si].SI_leading		; adjust Y pos
EC <	call	CheckScreenBuf						>
	mov	ds, ds:[si][SI_screenBuf]	
	pop	cx 				;# of chars to print 
	pop	si				;ds:si->text to draw
	call	GrDrawText
	pop	ds, si, dx			;restore pointer to instance
exit:
	ret
DrawTextLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSetFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the screen font and font info

CALLED BY:	(INTERNAL) ScreenBison12, ScreenBison9Or12
PASS:		ds:si	- screen instance data
		es	- dgroup
		cx	- font to set
		dx:ah	- point size to set

RETURN:		ds:si	- instance data
		di	- gState to draw to

DESTROYED:	al, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	mov     si, GFI_AVERAGE
	call	GrFontInfo

	GrFontInfo is dorked, don't use till fixed
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 8/29/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenSetFont	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit
	call	GrSetFont			; test out routine to set font
	mov	al, mask TM_DRAW_ACCENT		; set this
	clr	ah				; clear none
	call	GrSetTextMode
	mov	bx, si				;save si
	cmp	dx, 9				; 9 point?
	je	ninePoint
	mov	ds:[bx][SI_lineHeight], BISON_12_HEIGHT
	mov	ds:[bx][SI_leading], BISON_12_LEADING-1	; one pixel is below
	jmp	short 20$
ninePoint:
	mov	ds:[bx][SI_lineHeight], BISON_9_HEIGHT
	mov	ds:[bx][SI_leading], BISON_9_LEADING
20$:
SBCS <	mov	al, 'A'							>
DBCS <	mov	ax, 'A'							>
	call	GrCharWidth
	clr	dh
	
	mov     ds:[bx][SI_charWidth], dx       ;and store it
	mov	si, bx

	push	si
	mov	dx, size PointDWord		; allocate room for stack params
	sub	sp, dx
	mov	bp, sp
	clr	ax
	mov	ss:[bp].PD_x.high, ax
	mov	ss:[bp].PD_y.high, ax
	mov     ax, ds:[si][SI_charWidth]      	;font width
	mov	ss:[bp].PD_x.low, ax		;don't scroll horizontally
	mov     ax, ds:[si][SI_lineHeight]      ;font height
	mov	ss:[bp].PD_y.low, ax		;use line height vertically
	GetResourceHandleNS	TermView, bx
	mov	si, offset TermView
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	mov	ax, MSG_GEN_VIEW_SET_INCREMENT
	call	ObjMessage
	add	sp, size PointDWord
	pop	si
exit:
	ret
ScreenSetFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw cursor by inverting bits

CALLED BY:	ScreenData, ScreenCursorDown, ScreenCursorLeft, ScreenCR

PASS:		ds:si		- screen object instance data	
		di		- GState
		[SI_screenBuf]	- unlocked segment
		
RETURN:		SI_CursorDrawn	- TRUE	
		SI_lastCursorX	- positon of cursor drawn
		SI_lastCursorY	- 

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 9/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawCursor	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit
if	not _CHAR_SET
	call	CheckSelectRegion		;check if cursor dorking 
						;  selected text
endif
	call	DrawSelectCursor
EC <	call	ScreenCheckCursorPos					>
exit:
	ret
DrawCursor	endp

DrawSelectCursor	proc	near
	class	ScreenClass

	cmp	ds:[si][SI_cursorDrawn], TRUE	;is cursor already drawn
	je	exit				;yes, 
	cmp	di, BOGUS_VAL 			;if not GState to draw to 
	je	exit				;	bail city
	call 	CalcCursorPos			;get cursor positon
	mov	ds:[si][SI_cursorDrawn], TRUE	;flag cursor drawn
	mov	ds:[si][SI_lastCursorX], ax	;store last position
	mov	ds:[si][SI_lastCursorY], bx
	tst	ds:[si][SI_gotFocus]
	jz	50$
	call	ToggleCursor			;and draw it
	jmp	short exit
50$:
	call	DrawBoxCursor
exit:
	ret
DrawSelectCursor	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	erase the cursor

CALLED BY:	(INTERNAL) GetDrawLines, ScreenBackTab, ScreenBison12,
		ScreenBison9Or12, ScreenCR, ScreenClearToEndDisplay,
		ScreenClearToEndLine, ScreenCursorDown, ScreenCursorDownN,
		ScreenCursorLeft, ScreenCursorLeftN, ScreenCursorRight,
		ScreenCursorRightN, ScreenCursorUp, ScreenCursorUpN,
		ScreenData, ScreenDelChar, ScreenDelLine,
		ScreenGainFocusExcl, ScreenHomeCursor, ScreenInsLine,
		ScreenLostFocusExcl, ScreenRelCursorMove,
		ScreenRestoreCurChar, ScreenRestoreCursor,
		ScreenScrollBufEmpty, ScreenScrollTextUp, ScreenSetCol,
		ScreenSetRow, ScreenTab
PASS:		ds:si	- screen object instance data	
		di	- GState
		
RETURN:		nothing

DESTROYED:	ax, bx, cx, dx	

PSEUDO CODE/STRATEGY:
			

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 9/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EraseCursor	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	ds:[si][SI_cursorDrawn], FALSE	;is there a cursor to erase?
	je	EC_ret				;no, exit	
	cmp	di, BOGUS_VAL 			;if not GState to draw to 
	je	EC_ret				;	bail city
	mov	ax, ds:[si][SI_lastCursorX]	;yes, erase it
	mov	bx, ds:[si][SI_lastCursorY]
	mov	ds:[si][SI_cursorDrawn], FALSE	;flag cursor erased
	tst	ds:[si][SI_gotFocus]
	jz	50$
	call	ToggleCursor
	jmp	short EC_ret
50$:
	call	EraseBoxCursor
EC_ret:
	ret
EraseCursor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToggleCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	xor the cursor  (either clears or sets it)

CALLED BY:	ScreenData

PASS:		ds:si	- screen object instance data	
		di	- GState
		ax, bx	- (left, top) position to dork with cursor
		
RETURN:		nothing

DESTROYED:	ax, cx, dx	

PSEUDO CODE/STRATEGY:
		XOR the cursor into place		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 9/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ToggleCursor	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit
	mov	cx, ax				;save left bounds
	mov	al, MM_INVERT			;draw cursor by inverting
	call	GrSetMixMode
	call	GetBoxCoord
	call	GrFillRect			;if got focus draw a solid
	mov	al, MM_COPY			;restore regular gstate mode
	call	GrSetMixMode
exit:
	ret
ToggleCursor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufScrollUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scroll our copy of the screen image

CALLED BY:	(INTERNAL) CheckForScroll, ScreenScrollTextUp, SetFontNewScreen
PASS:		ds:si	- screen object instance data	
		di	- GState
		es	- dgroup
		[SI_screenBuf]	- locked segment
		
RETURN:		nothing

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
		Shift all lines upto and including the current 
		line up one line

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		I kind of cheat perhaps I should check scrollRegBot
		here, but I just scroll from where the cursor is.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 9/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufScrollUp	proc	near
class	ScreenClass				;we're friends with ScreenClass
	push	ds, es, si, di
	mov	ch, {byte} ds:[si][SI_scrollRegTop]
	tst	ch				;if not scrolling off top
	jnz	noSave				;  of screen then don't	
	call	ScrollSaveLine			;  save line to scroll buf
noSave:
	clr	cl				;dest of scroll is top
SBCS <	shr	cx, 1				;of scroll region	>
	mov	di, cx				;es:di-> dest of scroll 
	mov	ch, {byte} ds:[si][SI_curLine]
	clr	cl
SBCS <	shr	cx, 1				;cx->bottom of scroll region>
	sub	cx, di				;calc #bytes to move
EC <	call	CheckScreenBuf						>
	mov	ds, ds:[si][SI_screenBuf]	;ds   -> screen buffer	
	mov	si, di
if ERROR_CHECK
	call	ECCheckBounds
endif
	add	si, LINE_LENGTH			;ds:si-> src of scroll
	segmov	es, ds, dx		
	shr	cx, 1				;calc #words to move
	jnc	666$
	movsb
666$:
	rep	movsw
	pop	ds, es, si, di
	ret
BufScrollUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufScrollDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a blank line to screen by scrolling lines down

CALLED BY:	ScreenInsLine, ScreenScrollTextDown

PASS:		ds:si	- screen object instance data	
		di	- GState
		es	- dgroup
		[SI_screenBuf]	- locked segment
		
RETURN:		nothing

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
		Move all lines not below the current line down one line

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/30/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufScrollDown	proc	near
class	ScreenClass				;we're friends with ScreenClass
EC <	Assert_fptr	dssi						>
	push	ds, es, si, di
	mov	ch, {byte} ds:[si][SI_scrollRegBot]	;calc #lines to moves
	sub	ch, {byte} ds:[si][SI_curLine];
	clr	cl				;conv #lines to #bytes
SBCS <	shr	cx, 1				;  (bytes = #lines * 128)>
	shr	cx, 1				;conv #bytes to #words
	mov	ah, {byte} ds:[si][SI_scrollRegBot]
	inc	ah				;point to end of bottom line	
	clr	al				;	
SBCS <	shr	ax, 1				;			>
	sub	ax, 2
EC <	call	CheckScreenBuf						>
	mov	es, ds:[si][SI_screenBuf]	;
	segmov	ds, es, di			;
	mov	di, ax				;es:di->last byte in last line 
	mov	si, di				;ds:si->last byte in 2nd last
if ERROR_CHECK
	call	ECCheckBounds
endif
	sub	si, LINE_LENGTH
	std					;copy from bottom up
	rep	movsw				;
	cld					;reset direction flag
	pop	ds, es, si, di			;	
	ret
BufScrollDown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufDelLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete current line from screen buffer

CALLED BY:	(INTERNAL) ScreenDelLine
PASS:		ds:si	- screen object instance data	
		di	- GState
		es	- dgroup
		[SI_screenBuf]	- unlocked segment
		
RETURN:		nothing

DESTROYED:	cx, dx	

PSEUDO CODE/STRATEGY:
		Delete the current line from scren buffer by
		scrolling all those lines below it up one line.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/30/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufDelLine	proc	near
	class	ScreenClass

	push  ds, es, di, si

	mov	bx, ds:[si][SI_screenHandle]
EC <	push	ds, si				; save instance 	>
	push	bx				; save buffer handle
	call	MemLock
	mov	ds:[si][SI_screenBuf], ax

	mov     ch, {byte} ds:[si][SI_curLine]
	clr     cl
SBCS <	shr     cx, 1                           ;get ptr to current line>
	mov     di, cx                          ;es:di->dest of scroll
EC <	call	CheckScreenBuf						>
	mov     es, ds:[si][SI_screenBuf]       ;delete line from buffer
	segmov  ds, es, cx
	mov     si, di                          ;ds:si->src of scroll
	add     si, LINE_LENGTH
	mov     cx, SCREEN_SIZE
	sub     cx, si                          ;get  #byte to copy
	shr     cx, 1                           ;conv #bytes to #words
	jnc	666$
	movsb
666$:
	rep     movsw

	pop	bx				; retrieve buffer handle
	call	MemUnlock
EC <	pop	ds, si				; retrieve instance	>
EC <	call	NullScreenBuf			; stuff bogus segment	>

	pop ds, es, di, si
	ret
BufDelLine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufClearLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear from the cursor to the end of current line 

CALLED BY:	BufScrollUp, ScreenClearToEndLine

PASS:		ds:si	- screen object instance data	
		di	- GState
		[SI_screenBuf]  - locked segment

		
RETURN:		nothing

DESTROYED:	ax, cx	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BufClearLine	proc	near
class	ScreenClass				;we're friends with ScreenClass
	push	ds:[si][SI_curChar]
CUR <	push	ds:[si][SI_curPos]					>
	clr	ds:[si][SI_curChar]
CUR <	clr	ds:[si][SI_curPos]					>
	call	BufClearToEndLine
CUR <	pop	ds:[si][SI_curPos]					>
	pop	ds:[si][SI_curChar]
	ret
BufClearLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufClearToEndLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear from the cursor to the end of current line 

CALLED BY:	(INTERNAL) BufClearLine, ScreenClearToEndLine
PASS:		ds:si	- screen object instance data	
		di	- GState
		[SI_screenBuf]  - locked segment
		
RETURN:		nothing

DESTROYED:	ax, cx	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufClearToEndLine	proc	near
class	ScreenClass				;we're friends with ScreenClass
	push	es, di	
	mov	ah, {byte} ds:[si][SI_curLine]
	clr	al
SBCS <	shr	ax, 1				;get ptr to line in screenbuf>
	push	ax				; save line offset
	mov	di, ds:[si][SI_curChar]		;get cursor pos

	mov	cx, MAX_LINE_CHARS		;#bytes to replace = line
	sub	cx, di			 	;  length - cursor

DBCS <	shl	di, 1				;char offset -> byte offset>
	add	di, ax				;es:di ->string to replace
EC <	call	CheckScreenBuf						>
	mov	es, ds:[si][SI_screenBuf]	;
if DBCS_PCGEOS
	mov	ax, CHAR_SPACE
	rep	stosw
else
	mov	al, CHAR_SPACE			;replaces chars with spaces
	mov	ah, al
	shr	cl, 1				;convert to #bytes to #words
	jnc	SBClear				;even #of bytes
	stosb
SBClear:
	rep	stosw				;store ax at es:di
endif
	;
	; Clear the char attrs too
	;
	pop	di				; restore line offset
	add	di, LINE_GRAFX_START

	mov	cx, MAX_GRAFX_CHARS
	mov	ax, ds:[si][SI_curChar]
	sub	cx, ax				; cx = # chars to clear
	shr	ax, 1				; start nibble -> start byte
	pushf
	add	di, ax
	popf	
	jnc	getOnWithIt
	;
	; We're starting in an odd column, clear out the odd nibble
	; byte containing the beginning attr nibble.
	;
	andnf	{byte}es:[di], not ODD_COL_MASK
	inc	di				; go to next byte
	dec	cx				; 1 char down

getOnWithIt:
	shr	cx, 1				; cx = # bytes to clear
	shr	cx, 1				; cx = # words to clear
	mov	ax, NO_GRAFX or NO_GRAFX shl 8	;erase grafx attributes
	jnc	movWords
	stosb
movWords:
	rep	stosw				;for this line

	pop	es, di
	ret
BufClearToEndLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufClearToBegLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear from the cursor to the beginning of current line,
		inclusive

CALLED BY:	(INTERNAL) ScreenClearToBegDisp, ScreenClearToBegLine
PASS:		ds:si	- screen object instance data	
		di	- GState
		[SI_screenBuf]  - locked segment
		
RETURN:		nothing

DESTROYED:	ax, cx	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cthomas	2/20/96		Copied from BufClearToEndLine, for what it's
				worth.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufClearToBegLine	proc	near
class	ScreenClass				;we're friends with ScreenClass
	push	es, di	
	mov	ah, {byte} ds:[si][SI_curLine]
	clr	al
SBCS <	shr	ax, 1				;get ptr to line in screenbuf>
	mov	cx, ds:[si][SI_curChar]		;get cursor pos
	inc	cx				; cx = # chars to clear
	mov	di, ax				;es:di ->string to replace
	push	di
EC <	call	CheckScreenBuf						>
	mov	es, ds:[si][SI_screenBuf]	;
	;
	; Clear the characters
	;
if DBCS_PCGEOS
	mov	ax, CHAR_SPACE
	rep	stosw
else
	push	cx
	mov	al, CHAR_SPACE			;replaces chars with spaces
	mov	ah, al
	shr	cl, 1				;convert to #bytes to #words
	jnc	SBClear				;even #of bytes
	stosb
SBClear:
	rep	stosw				;store ax at es:di
	pop	cx
endif
	;
	; Clear the graphics attributes
	;
	pop	di				; get line bufer base
	add	di, LINE_GRAFX_START		; di = attr buffer
	shr	cx, 1				; # of bytes to clear
	mov	ax, NO_GRAFX			;erase grafx attributes
	rep	stosb				;for this line
	jnc	done
	CheckHack <NO_GRAFX eq 0>
	andnf	{byte}es:[di], not EVEN_COL_MASK ; 1 leftover nibble to clear
done:
	pop	es, di
	ret
BufClearToBegLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the screen buffer from cursor position down.

CALLED BY:	CheckForScroll

PASS:		ds:si	- 	screen object instance data	
		SI_screenBuf	- unlocked segment
		
RETURN:		nothing

DESTROYED:	es, ax, cx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 9/27/89	Initial version
	dennis	10/20/89	New screen buf data structure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufClear	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	ds:[si][SI_curLine], MAX_LINES
	jae	exit

     	mov     bx, ds:[si][SI_screenHandle]    ;store handle to segment
	call    MemLock
	mov     ds:[si][SI_screenBuf], ax

	clr	dl				;reset line counter	
	mov	dh, MAX_LINES 			;
	mov	bh, {byte} ds:[si][SI_curLine]	;
	sub	dh, bh				;max - current = #lines to clear
	clr	bl				;
SBCS <	shr	bx, 1				;calc index into buffer	>
	mov	di, bx				; (line# * 128)
initLine:
SBCS <	mov	al, CHAR_SPACE						>
SBCS <	mov	ah, al							>
DBCS <	mov	ax, CHAR_SPACE						>
EC <	call	CheckScreenBuf						>
	mov	es, ds:[si][SI_screenBuf]
SBCS <	mov	cx, MAX_LINE_CHARS/2					>
DBCS <	mov	cx, MAX_LINE_CHARS					>
	rep	stosw				;store AX into es:di
	
	mov	cx, LINE_DATA/2
	mov	ax, NO_GRAFX			;init graphic attributes
	rep	stosw				;store AX into es:di
	inc	dl	
	cmp	dl, dh
	jl	initLine

	mov     bx, ds:[si][SI_screenHandle]    ;unlock stinking block
	call    MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>
exit:
	ret
BufClear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufClearUpward
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the screen buffer from top of screen to line
		containing cursor (inclusive)

CALLED BY:	ScreenClearToBegDisp

PASS:		ds:si	- 	screen object instance data	
		SI_screenBuf	- unlocked segment
		
RETURN:		nothing

DESTROYED:	es, ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cthomas	2/20/96		Copied from BufClear, such as it is

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufClearUpward	proc	near
class	ScreenClass				;we're friends with ScreenClass

	mov	dh, {byte} ds:[si][SI_curLine]	;
	tst	dh
	js	exit

     	mov     bx, ds:[si][SI_screenHandle]    ;store handle to segment
	call    MemLock
	mov     ds:[si][SI_screenBuf], ax
	mov	es, ax
	mov	bh, dh
	inc	dh				; dh = # lines to clear
	clr	dl				;reset line counter	
	clr	di				; start at beginning of buf

	cmp	dh, MAX_LINES			; don't clear too many lines
	jbe	initLine
	mov	dh, MAX_LINES

initLine:
SBCS <	mov	al, CHAR_SPACE						>
SBCS <	mov	ah, al							>
DBCS <	mov	ax, CHAR_SPACE						>
SBCS <	mov	cx, MAX_LINE_CHARS/2					>
DBCS <	mov	cx, MAX_LINE_CHARS					>
	rep	stosw				;store AX into es:di
	
	mov	cx, LINE_DATA/2
	mov	ax, NO_GRAFX			;init graphic attributes
	rep	stosw				;store AX into es:di
	inc	dl	
	cmp	dl, dh
	jl	initLine

	mov     bx, ds:[si][SI_screenHandle]    ;unlock stinking block
	call    MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>
exit:
	ret
BufClearUpward	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinClearToEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear window from cursor on

CALLED BY:	(INTERNAL) ScreenClearToEndDisplay
PASS:		ds:si	- screen object instance data	
		di	- GState
		
		
RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/08/89	New screen buf data structure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinClearToEnd	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit
	mov	al, ds:[si][SI_backColor]
	mov     ah, CF_INDEX
	call    GrSetAreaColor                  ;set erase color
	;
	; Erase rect from cursor UL to Window BR
	;
	call    CalcCursorPos                   ;get region to erase
	push  ax, bx                          ;from cursor top
	call    GrGetWinBounds                 ;  window bottom and right
	xchg	bp, ax				; bp -> Win.left
	pop ax, bx                          ;
	call    GrFillRect                      ;clear the screen display
	;
	; Erase rect to Right & Below cursor
	;
	add	bx, ds:[si][SI_lineHeight]
	xchg	ax, bp				; ax -> Win.left
	call	GrFillRect
exit:
	ret
WinClearToEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinClearToBeg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear window from beginning to cursor

CALLED BY:	(INTERNAL) ScreenClearToBegDisplay
PASS:		ds:si	- screen object instance data	
		di	- GState
		
		
RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/08/89	New screen buf data structure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinClearToBeg	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit
	mov	al, ds:[si][SI_backColor]
	mov     ah, CF_INDEX
	call    GrSetAreaColor                  ;set erase color
	;
	; Erase rect from (Left, Top) - (Right, Cursor.top)
	;
	call    CalcCursorPos                   ;get region to erase
	push	ax				; +1 : cursor.left
	push	bx				; +2 : cursor.top
	call    GrGetWinBounds			;  window bottom and right
	pop	dx				; -2 : cursor.top
	cmp	bx, dx
	jae	eraseLine
	call	GrFillRect
eraseLine:
	;
	; Erase (Left, Cursor.top) - (cursor.right, cursor.bottom)
	;
	pop	cx				; -1 : cursor.left
	mov	bx, dx				; (ax,bx) = (left, c.top)
	add	cx, ds:[si][SI_charWidth]
	add	dx, ds:[si][SI_lineHeight]	; (cx,dx) = (c.left, c.bot)
	call    GrFillRect                      ;clear the line
exit:
	ret
WinClearToBeg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Whiteout the visible window region

CALLED BY:	ScreenDelLine

PASS:		ds:si	- screen object instance data	
		di	- GState
		
		
RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Doesn't take into account scroll bottom
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/29/89	New screen buf data structure
	dennis	01/22/90	White out area defined by scroll region	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinClear	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit
	mov	al, ds:[si][SI_backColor]	;set erase color
	mov	ah, CF_INDEX
	call	GrSetAreaColor			
	call	GrGetWinBounds			;get window coordinates
	call	GrFillRect			;and white out screen
exit:
	ret
WinClear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufShiftLineRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shift the characters in the current line to the right 

CALLED BY:	(INTERNAL) ScreenData
PASS:		ds:si	- screen object instance data	
		di	- GState
		dl	- current character	
		
RETURN:		

DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/29/89	New screen buf data structure
	dennis	01/10/90	Handle graphic attributes properly

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufShiftLineRight	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	ds:[si][SI_curChar], MAX_LINE_CHARS
	jae	reallyExit

	push	es, di, dx, bp
	push	ds, si	
EC <	call	CheckScreenBuf						>
	mov	es, ds:[si][SI_screenBuf]	;es->screen buf segment
	mov 	cx, MAX_LINE_CHARS
	sub	cl, {byte} ds:[si][SI_curChar]	;get #chars to move
	mov	bh, {byte} ds:[si][SI_curLine]	;
	clr	bl				;
SBCS <	shr	bx, 1				;bx->to current line	>
	mov	di, bx
SBCS <	add	di, MAX_LINE_CHARS - 1		;ds:di->dest of copy	>
DBCS <	add	di, MAX_LINE_CHARS - 2		;ds:di->dest of copy	>
	mov	si, di	
	dec	si				;ds:si->src of copy
DBCS <	dec	si							>
	segmov	ds, es, ax
	std					;copy from bottom up	
SBCS <	shr	cx, 1				;conv bytes to words	>
SBCS <	jnc	666$							>
SBCS <	movsb					;			>
SBCS <666$:								>
	rep	movsw				;copies ds:si to es:di
	cld					;restore direction flag	

	pop	ds, si				;restore ptr to instance data
						;now shift attriubte bits
	add	bx, LINE_GRAFX_END		;es:bx->end of line attributes
if DBCS_PCGEOS	;-------------------------------------------------------------
	push	ds, si
	mov	cx, MAX_LINE_CHARS
	sub	cl, {byte} ds:[si].SI_curChar
	mov	di, bx
	add	di, MAX_LINE_CHARS - 1
	mov	si, di
	dec	si
	segmov	ds, es, ax
	std
	shr	cx, 1
	jnc	777$
	movsb
777$:
	rep	movsw
	cld
	pop	di, si
else	;---------------------------------------------------------------------
	mov	bp, MAX_LINE_CHARS
	sub	bp, ds:[si][SI_curChar]		;calc #nibbles to shift
	shr	bp, 1				;calc #bytes to shift
	jc	oddNibble
	mov	ss:[oddCol], FALSE
	jmp	short initShift
oddNibble:
	inc	bp
	mov	ss:[oddCol], TRUE
initShift:
	sub	bx, bp				;es:bx->attributes to shift
	mov	dh, es:[bx]			;store start attribute nibbles
	mov	ax, bx				;save start of nibble shift
	mov	cx, NIBBLE_SIZE	
	clc					;reset carry bit first
nibbleShift:
	push	cx				;is nibble shifted over yet
	mov	bx, ax				;set start of shift
	mov	cx, bp				;#bytes to shift
bitShift:
	rcr	{byte} es:[bx], 1
	inc	bx
	loop	bitShift
	pop	cx
	loop	nibbleShift
	mov	bx, ax				;es:bx->start of nibble shifts
	cmp	ss:[oddCol], TRUE
	je	odd	
	and	{byte} es:[bx], ODD_COL_MASK	;if inserting at even column
	jmp	short exit			;then nuke odd nibble
odd:
	and	dh, EVEN_COL_MASK		;if insert at odd nibble 
	mov	{byte}es:[bx], dh		;then even nibble restored
exit:
endif	;---------------------------------------------------------------------
	pop	es, di, dx, bp
reallyExit:
	ret
BufShiftLineRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufShiftLineLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shift the characters in the current line to the left 

CALLED BY:	ScreenDelChar

PASS:		ds:si	- screen object instance data	
		di	- GState
		SI_screenBuf	- locked segment

		
RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		Shift nibbles left by shifting with carry.  Start at the
		end of the sequence to shift left one bit. Go to the
		second to last word and shift left one bit with the carry bit. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/29/89	New screen buf data structure
	dennis	01/11/90	Handle line graphic attributes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufShiftLineLeft	proc	near
class	ScreenClass				;we're friends with ScreenClass
	push	es, di	
	push	ds, si
	mov	ch, {byte} ds:[si][SI_curLine]
	clr	cl
SBCS <	shr	cx, 1				;get ptr to cur line	>
	mov	ax, cx				;save ptr to cur line
	mov	dx, ds:[si][SI_curChar]		
DBCS <	shl	dx, 1				;char offset -> byte offset>
	add	cx, dx				;offset to cursor
	mov	di, cx				;es:di->dst string
SBCS <	mov 	cx, MAX_LINE_CHARS - 1					>
DBCS <	mov 	cx, MAX_LINE_CHARS - 2					>
	sub	cl, dl				;calc #chars to move
EC <	call	CheckScreenBuf						>
	mov	es, ds:[si][SI_screenBuf]
	segmov	ds, es, si
	mov	si, di				;ds:si->src string
	inc	si			
DBCS <	inc	si							>
SBCS <	shr	cl, 1				;conv #bytes to words	>
SBCS <	jnc	666$							>
SBCS <	movsb								>
SBCS <666$:								>
	rep	movsw				
SBCS <	mov	{byte} ds:[di], CHAR_SPACE	;blank out last char	>
DBCS <	mov	{wchar} ds:[di], CHAR_SPACE	;blank out last char	>

	pop	ds, si
	add	ax, LINE_GRAFX_START 		;get to start of line attribute
if DBCS_PCGEOS	;-------------------------------------------------------------
	push	ds, si
	mov	cx, MAX_LINE_CHARS - 1
	sub	cl, {byte} ds:[si].SI_curChar
	mov	di, ax
	add	di, ds:[si].SI_curChar
	mov	si, di
	inc	si
	segmov	ds, es, ax
	shr	cx, 1
	jnc	777$
	movsb
777$:
	rep	movsw
	pop	ds, si
else	;---------------------------------------------------------------------
	mov	cx, ds:[si][SI_curChar]		;
	shr	cx, 1				;get #of nibbles to shift to 
	jc	odd
	mov	ss:[oddCol], FALSE
	jmp	short initShift
odd:
	mov	ss:[oddCol], TRUE
initShift:
	add	ax, cx				;get start of nibbles to shift
	inc	cx				;adjust #bytes to shift
	mov	bp, cx				;save #bytes to shift	
	mov	bx, ax
	mov	dh, es:[bx]			;save orig nibbles
	mov	cx, NIBBLE_SIZE	
	clc					;reset carry bit first
nibbleShift:
	push	cx
	mov	bx, ax				;set ptr to start of shift
	mov	cx, bp				;restore #bytes to shift
bitShift:
	rcl	{byte}es:[bx], 1
	dec	bx
	loop	bitShift
	pop	cx
	loop	nibbleShift

	mov	bx, ax	
	mov 	{byte} es:[bx], dh		;restore original attr		
	tst	ss:[oddCol]
	jne	evenCol
	and	{byte} es:[bx], ODD_COL_MASK
	jmp	short exit
evenCol:
	and	{byte} es:[bx], EVEN_COL_MASK
exit:
endif	;---------------------------------------------------------------------
	pop	es, di 
	ret
BufShiftLineLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinScrollDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a line in the window

CALLED BY:	(INTERNAL) ScreenInsLine
PASS:		ds:si	- screen object instance data	
		SI_screenBuf	- locked segment
		
RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
		
NOTES:
	The Responder specific version of WinScrollDown is 
	simplified because the window has a fixed size.  The
	algorithm computes the equivalent value as the regular version
	of WinScrollDown.  The difference is that the responder version
	will work in zoomed in mode.  The current zoom mode does not
	affect the calculations.

	Algorithm for calculating height of block to blt is:
		|(scrollRegBot - curLine)(lineHeight)|.

	Absolute value is used in case the cursor is ever below
	the scroll region.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


WinScrollDown	proc	near
class	ScreenClass				;we're friends with ScreenClass
	mov	di, ds:[si][SI_gState]		;get gstate	
	cmp	di, BOGUS_VAL
	je	exit
	push	si
	call	CalcCursorPos			;get doc coord for cur line
;	inc	bx				;(screen hack off by one)
	push	bx				;save src Y pos 
	add	bx, ds:[si][SI_lineHeight]	;dest of copy is next line
	push	bx				;save dest Y pos
	clr	ah
	mov	al, ds:[si][SI_maxLines]
	dec	al
	sub	ax, ds:[si][SI_scrollRegBot]
	mov	bp, ax
	jz	10$	
	jg	9$
	clr	bp
	jmp	short 10$

9$:
	mov	cx, ds:[si][SI_lineHeight]
	mul	cl
	mov	bp, ax
;	dec	bp				;HACK, HACK, HACK
10$:
	call	GrGetWinBounds			;get window bounds
;	inc	dx
	sub	dx, bp
	sub	cx, ax				;pass width of window
	inc	cx
	mov	si, cx				;get width of block to copy
	pop	cx				;get dest Y coord
	pop	bx				;set src  Y coord
	sub	dx, cx				;pass # lines to copy 
	tst	dx	
	jz	oneLine
	push	dx				; (win bot - dest)
	mov	dx, cx				;set dest Y coord 
	mov	cx, BLTM_CLEAR
	push	cx				;pass copy ctrl flags
	clr	ax				;set src  X coord
	mov	cx, ax				;set dest X coord 
	call	GrBitBlt
	pop	si
	jmp	short exit

oneLine:					;for single line don't scroll
	pop	si
	call	WinClearLine			;	just clear it
exit:
	ret
WinScrollDown	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinScrollUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shifts all lines up to the current line, up one line

CALLED BY:	ScreenScrollTextUp	

PASS:		ds:si	- screen object instance data	
		[SI_screenBuf]  - locked segment
		
RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		I kind of cheat perhaps I should check scrollRegBot
		here, but I just scroll from where the cursor is.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/17/89	Initial version
	dennis	01/15/90	Modified to take into account scroll regions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinScrollUp	proc	near
class	ScreenClass				;we're friends with ScreenClass
	mov	di, ds:[si][SI_gState]
	cmp	di, BOGUS_VAL
	je	exit
	push	si
	call	CalcCursorPos			;get doc coord for cur line
	push	bx				;and save Y pos of cursor
	call	GrGetWinBounds			;get top of window 
	sub	cx, ax				;get width of window
	inc	cx
	mov	bp, cx				;save width of copy
	mov	ax, ds:[si][SI_scrollRegTop]	;
	mov	cx, ds:[si][SI_lineHeight]	;
	mul	cl				;offset to top of scroll buf
	add	bx, ax				
	mov	dx, bx				;dest Y copy is top of win
	add	bx, ds:[si][SI_lineHeight]	;src Y copy is line under top
	mov	si, bp				;width of copy is win right 
	pop	cx				;get Y pos for cur line 
	sub	cx, dx				;height of copy =
EC <	ERROR_S	-1	; if we're scrolling up, the cursor should be below >
EC <			; the scroll region so the height should not be zero!> 
	jcxz	oneLine				;special case : if height is 0
	push	cx				;top of win to cur line
	mov	cx, BLTM_CLEAR
	push	cx				;pass copy ctrl flags
	clr	ax				;set src  X coord
	mov	cx, ax				;set dest X coord 
	call	GrBitBlt
	pop	si				;restore obj ptr
	jmp	short exit
oneLine:					;for single line don't scroll
	pop	si				;restore screen obj
	call	WinClearLine			;just clear the line
exit:
	ret
WinScrollUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinDelLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes current line on window 

CALLED BY:	(INTERNAL) ScreenDelLine
PASS:		ds:si	- screen object instance data	
		di	- GState
		
RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinDelLine	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit
	push	si
	call	CalcCursorPos			;get cursor coordinates
	push	bx				;dest Y pos is top of cursor
;	inc	bx				;(screen hack: off by 1?)
	add	bx, ds:[si][SI_lineHeight]	;src  Y pos is one line down
	push	bx				;save src Y pos
	call	GrGetWinBounds			;get bottom of window
	inc	dx				; adjust for our usage
						; (need height not coords.)
	sub	cx, ax				;calc width of window
	inc	cx
	mov	si, cx				;win right is width of copy
	pop	bx				;get src Y pos
	sub	dx, bx				;height of copy =
	mov	cx, dx				;save copy height
	pop	dx				;get dest Y pos
	jcxz	lastLine			; no region to blt...
						; ...must be last line in view
	push	cx				;pass height of copy block
	mov	cx, BLTM_CLEAR
	push	cx				;pass copy ctrl flags
	clr	ax				;set src  X coord
	mov	cx, ax				;set dest X coord 
	call	GrBitBlt
	pop	si
	jmp	short exit

lastLine:
	pop	si
	call	WinClearLine
exit:
	ret
WinDelLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinClearLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears the current line on the window

CALLED BY:	ScreenInsLine

PASS:		ds:si	- screen object instance data	
		di	- GState
		[SI_screenBuf]  - locked segment
		
RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinClearLine	proc	near
class	ScreenClass				;we're friends with ScreenClass
	push	ds:[si][SI_curChar]
CUR <	push	ds:[si][SI_curPos]					>
	mov	ds:[si][SI_curChar], 0		; 1st char to clear whole line
CUR <	mov	ds:[si][SI_curPos], 0					>
	call	EraseRemLine
CUR <	pop	ds:[si][SI_curPos]					>
	pop	ds:[si][SI_curChar]
	ret
WinClearLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrollDrawLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw lines from scroll buffer that are invalid

CALLED BY:	(INTERNAL) DrawDocument
PASS:		ds:si		- screen object instance data	
		di		- GState
		bh		- first line to draw
		bl		- last line to draw
		
RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScrollDrawLines	proc	near
class	ScreenClass				;we're friends with ScreenClass
	push	ds, si
	mov	ds:[si][SI_inScroll], TRUE	;user scrolled away from win
	mov	al, bh				;get first line to draw
	clr	ah
	mov	cx, ds:[si][SI_lineHeight]	;calculate doc coordinates
	mul	cl				;to print line at
	mov	bp, ax				;save Y coordinates	
	mov	al, bl
	clr	ah
	mul	cl
	mov	dx, ax				;save last coord to draw at

	mov	al, bh				;get first line to draw
	clr	ah
	add	ax, ds:[si][SI_scrollTop]	;offset to line in
	cmp	ax, SCROLL_LINES		;  scroll buffer
	jl	getLine
	sub	ax, SCROLL_LINES
getLine:
	mov	ah, al				;calc ptr to line in 
	clr	al				;	scroll buffer
SBCS <	shr	ax, 1				;			>
	push	ax				;save line to draw
	mov	bx, ds:[si][SI_scrollHandle]	;lock scroll segment
	call	MemLock
	mov	es, ax				;es->scroll segment
	mov	bx, bp				;pass coordinates to print at
	pop	bp				;es:bp-> line to draw
SDL_loop:					;
	mov	ch, MAX_LINE_CHARS		;max # of chars to print 
	mov	cl, 0				;set starting column
	clr	ax
	call	DrawScrollLine			;print string
	add	bp, LINE_LENGTH			;point to next string
	cmp	bp, SCROLL_BUF_SIZE		;do we need to wrap around buf
	jl	noWrap				;nope
	clr	bp				;yes
noWrap:
	add	bx, ds:[si][SI_lineHeight]	;update position to print
	cmp	bx, dx				;continue if line to print in
	jb	SDL_loop			;  invalid region 
exit:
	pop	ds, si
	mov	bx, ds:[si][SI_scrollHandle]	;unlock scroll segment
	call	MemUnlock
	ret
ScrollDrawLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrollSaveLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the line at the top of screen to the scroll buffer

CALLED BY:	BufScrollUp

PASS:		ds:si		- screen object instance data	
		di		- GState
		
RETURN:		nothing

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/21/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScrollSaveLine	proc	near
class	ScreenClass				;we're friends with ScreenClass
	push	ds, es, di, si
	mov	ax, ds:[si][SI_scrollLines]	;get num of lines in scroll
	cmp	ax, SCROLL_LINES		;if buffer full	
	jl	incLineCount			;  
if	not _CHAR_SET
	mov	ax, 1				;scroll select region one line
	call	ScrollSelectRegion		;adjust selected region
endif
	mov	ax, ds:[si][SI_scrollTop]	;then wrap to the top
	inc	ds:[si][SI_scrollTop]		;advance head pointer
	cmp	ds:[si][SI_scrollTop], SCROLL_LINES
	jne	storeLine			;check if head ptr needs to 
	clr	ds:[si][SI_scrollTop]		;  wrap around
	jmp	storeLine
incLineCount:
	tst	ds:[si][SI_scrollLines]		;if have text in scroll buffer
	jnz	10$				;enable the save scroll options
	push	ax
	CallMod	EnableSaveScroll
	pop	ax
10$:
	inc	ds:[si][SI_scrollLines]
storeLine:
	mov	ah, al				;calc place to store
	clr	al				;  in buffer.
SBCS <	shr	ax, 1				;			>
	mov	di, ax				;es:di->dest line in scroll
	mov	bx, ds:[si][SI_scrollHandle]	;lock scroll segment 
	call	MemLock
	mov	es, ax				;
EC <	call	CheckScreenBuf						>
	mov	ds, ds:[si][SI_screenBuf]	;ds:si->top line in screen
	clr	si				;  buffer
	mov	cx, LINE_LENGTH/2		;get # of words to copy
	rep	movsw				;copy ds:si to es:di
	pop	ds, es, di, si
	mov	bx, ds:[si][SI_scrollHandle]	;unlock scroll segment
	call	MemUnlock
	ret
ScrollSaveLine	endp

if	_CLEAR_SCR_BUF

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenClearScreenAndScrollBufResetParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset some paramters of screen object when clearing screen
		and scroll buffer

CALLED BY:	(INTERNAL) ScreenClearScreenAndScrollBuf
PASS:		ds:si	= fptr to screen object's instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenClearScreenAndScrollBufResetParams	proc	near
	class	ScreenClass
	uses	ax
	.enter
EC <	Assert_fptr	dssi						>
	;
	; Reset screen object paramters
	;
	mov	ds:[si][SI_inScroll], FALSE	; not scrolling when at top
	mov	ds:[si][SI_wrap], FALSE		; indicate we are not at
						; bottom of buffer to enable
						; scroll up
	mov	ax, ds:[si][SI_winHeight]
	mov	ds:[si][SI_winBottom], ax	; bottom of win = win height
	
	clr	ax
	mov	ds:[si][SI_scrollTop], ax	; top scroll line is 1st line
	mov	ds:[si][SI_scrollLines], ax	; no saved scroll lines
	mov	ds:[si][SI_lastCursorX], ax
	mov	ds:[si][SI_lastCursorY], ax	; no last cursor
	mov	ds:[si][SI_saveCursorX], ax
	mov	ds:[si][SI_saveCursorY], ax	; no saved cursor
	mov	ds:[si][SI_curLine], ax		; current line is top line
	mov	ds:[si][SI_winTopLine], ax	; 1st line is win top line
	
	.leave
	ret
ScreenClearScreenAndScrollBufResetParams	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenClearScrollBuf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the screen scroll bufffer

CALLED BY:	(INTERNAL) ScreenClearScreenAndScrollBuf
PASS:		ds:si	= fptr to screen object instance data
RETURN:		carry set if error reallocating memory scroll buffer
DESTROYED:	ax, bx, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Free the original scroll buffer;
	Re-allocate a new scroll buffer;
	Return error if any;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenClearScrollBuf	proc	near
	class	ScreenClass
	.enter
EC <	Assert_fptr	dssi						>

	clr	bx
	xchg	bx, ds:[si][SI_scrollHandle]
	tst	bx
	jz	allocNew
	call	MemFree				; bx destroyed
allocNew:
	mov	ax, SCROLL_BUF_SIZE
	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc			; ^hbx <- block handle
	jc	done
	mov	ds:[si][SI_scrollHandle], bx
	
done:
	.leave
	ret
ScreenClearScrollBuf	endp

endif	; _CLEAR__SCR_BUF
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrollLinesToDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write line from scroll buffer to disk

CALLED BY:	(INTERNAL)
PASS:		ds:si		- screen object instance data	
		bx		- file handle	
		ah		- first line number to write out
		al		- #lines to write out

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx	

PSEUDO CODE/STRATEGY:
		when writing scrollbuffer to disk we don't write out
		trailing spaces or nulls.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	could make saveScroll a local variable, but I'm lame.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/05/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrollLinesToDisk	proc 	near
class	ScreenClass				;we're friends with ScreenClass
	push	ds, si				;save instance data
	push	ax, bx				;save file handle
	mov	ss:[saveScroll], TRUE
	mov	bx, ds:[si][SI_scrollHandle]	;lock scroll segment
	call	MemLock
	mov	ds, ax				;ds->scroll segment
	pop	ax, bx				;restore file handle

	mov	dh, ah				;calc offset in scroll buffer
	clr	dl				;for the line to copy
SBCS <	shr	dx, 1 				;ds:dx->line to copy	>
	call	LinesToDisk
	pop	ds, si				;get screen instance	
	mov	bx, ds:[si][SI_scrollHandle]	;unlock scroll segment
	call	MemUnlock
	ret
ScrollLinesToDisk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinesToDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write buffer lines to disk

CALLED BY:	ScreenScrollBufSave

PASS:		ds:dx		- ptr to first line to write out
		bx		- file handle	
		al		- # lines to write out
		ss:[saveScroll]	- flag if scroll buffer is being saved out
		es		- dgroup

RETURN:		bx		- file handle open

DESTROYED:	ax, cx, dx, di, bp

PSEUDO CODE/STRATEGY:
		when writing scrollbuffer to disk we don't write out
		trailing spaces or nulls.
		when writing out scrollbuffer have to check if scroll
		buffer is being wrapped.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/05/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LinesToDisk	proc	near

EC <	call	ECCheckES_dgroup					>

	clr	ah				;clear line counter
nextLine:
	inc	ah				;update num lines written out
	mov	di, ax				;save line numbers
	mov	bp, dx				;ds:dx->start of line
	call	GetLineLength
	jcxz	writeCRLF			;if no chars to write, skip line
	mov	bp, bx				;pass file handle
	;
	; copy line to stack and convert from GEOS char set to DOS code page
	;
	push	ds, dx, di, si			; save buffer pointer & stuff
if DBCS_PCGEOS	;-------------------------------------------------------------
	;	cx = # chars
	mov	si, dx				; ds:si = line
	sub	sp, MAX_LINE_CHARS*3		; JIS: 2 to 5 expansion
	mov	di, sp
	push	es				; save dgroup
	segmov	es, ss, ax			; es:di = converted line buffer
	mov	ax, MAPPING_DEFAULT_CHAR
	clr	bx, dx
	call	LocalGeosToDos			; cx = new size (# bytes)
	pop	es				; es = dgroup
	jc	err
EC <	cmp	cx, MAX_LINE_CHARS*3					>
EC <	ERROR_A	-1							>
	segmov	ds, ss, ax			; ds:dx = converted line
	mov	dx, di
	CallMod	WriteBufToDisk
err:
	lahf
	add	sp, MAX_LINE_CHARS*3
	sahf
else	;---------------------------------------------------------------------
	sub	sp, MAX_LINE_CHARS		; 80 bytes
	mov	di, sp
	mov	si, sp
	push	es				; save es=dgroup
	segmov	es, ss, ax			; es:di = stack buffer
	xchg	si, dx				; ds:si = line, dx = stack buf
	push	cx				; save char count
	rep movsb				; copy line to stack buffer
	pop	cx				; retrieve char count
	pop	es				; retreive es=dgroup
	mov	ds, ax				; ds:dx = stack buffer
	mov	si, dx				; ds:si = stack buffer
	mov	ax, MAPPING_DEFAULT_CHAR
	call	LocalGeosToDos			; convert to DOS code page
	CallMod	WriteBufToDisk			;write out scroll buf line
	lahf					; save result
	add	sp, MAX_LINE_CHARS
	sahf					; restore result
endif	;---------------------------------------------------------------------
	pop	ds, dx, di, si			; retrieve buffer pointer
	mov	bx, bp				;restore file handle	
	jc	exit				;exit if errors
writeCRLF:
	push	dx				;write out CR/LF
SBCS <	add	dx, MAX_LINE_CHARS		;jump to end of scroll line>
DBCS <	add	dx, MAX_LINE_CHARS*(size wchar)	;jump to end of scroll line>
	mov	bp, dx				;and insert a CR/LF
	;SBCS CR/LF even for DBCS
	mov	{byte} ds:[bp], CHAR_CR		;
	inc	bp
	mov	{byte} ds:[bp], CHAR_LF		;
	mov	cx, 2				;set #chars to write
	clr	al				;flag to report disk errors
	call	FileWrite			;write this out
	pop	dx
	mov	ax, di				;get count of lines printed
	cmp	ah, al				;done copying lines?
	jae	exit				;yes exit 	
	add	dx, LINE_LENGTH			;ds:dx->next line
	tst	ss:[saveScroll]			;if saving screen buffer don't
	LONG jz	nextLine			;	worry about wrapping
	cmp	dx, SCROLL_LAST_LINE		;are we at end of scroll buffer?
	jb	jmpNextLine			;nope
	clr	dx				;yes, so wrap to the top
jmpNextLine:
	jmp	nextLine
exit:
	ret
LinesToDisk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDrawLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate which lines in document need redrawing

CALLED BY:	(INTERNAL) DrawDocument
PASS:		ds:si		- screen object instance data	
		di		- GState
		
RETURN:		C		- set if shouldn't draw any lines	

		C		- clear if things okay
		bh		- first line to draw	
		bl		- last  line to draw

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If try to resize the window when the masked bounds are 
	undefined (for instance when the first EXPOSED event has
	not been finished processing) then will get div error 
	error because the div operation results in some huge
	quotient. 

	Is there a problem here if the document is bigger than
	24 lines, so I return some line numbers that aren't valid? 
	ERROR : PUT A CHECK IN HERE TO SEE IF THE MASKED REGION IS
	VALID!!!!

	If somehow I get an EXPOSED event when my instance data is dorked,
	then is it okay to just ignore the draw (like I currently do?)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/21/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetDrawLines	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit
	tst	ds:[si][SI_lineHeight]		;if line height is 0 
	jz	noDraw				;	don't attempt to draw
	call	GrGetMaskBounds			;get invalid region 
	jc	noDraw	
	cmp	bx, UNDEF_MASK_BOUND
	jae	noDraw
	cmp	dx, UNDEF_MASK_BOUND
	jae	noDraw
	mov	bp, ds:[si][SI_lastCursorX]
	add	bp, ds:[si][SI_charWidth]	;get right bound of cursor
	cmp	ax, bp				;check if cursor erased
	ja	cursorOK			
	cmp	cx, ds:[si][SI_lastCursorX]
	jb	cursorOK
	mov	bp, ds:[si][SI_lastCursorY]
	add	bp, ds:[si][SI_lineHeight]
	cmp	bx, bp
	ja	cursorOK
	cmp	dx, ds:[si][SI_lastCursorY]
	jb	cursorOK
	push	bx, dx
	call	EraseCursor			;cursor invalidated
	pop	bx, dx
cursorOK:
	mov	ax, bx				;get top of inval region
	mov	cx, ds:[si][SI_lineHeight]	;figure out corresponging line
	div	cl				;
	mov	bh, al				;store first line to draw
	mov	ax, dx
	div	cl
;	tst	ah				;check if part of line needs 
;	jz	noFrac				; to be redrawn
	inc	al
noFrac:
	mov	bl, al 
	clc					;clear error flag
	jmp	short exit
noDraw:
	stc					;set error flag
exit:
	ret
GetDrawLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrollResetView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scroll the view to make the cursor visible

CALLED BY:	ScreenData

PASS:		ds:si		- screen object instance data	
		di		- GState
		bp		- pointer to charcter buffer
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		should I allow the scroll reset to abort if cursor 
		visible in the current screen ?
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/21/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScrollResetView	proc	near
class	ScreenClass				;we're friends with ScreenClass
	push	bp
	cmp	di, BOGUS_VAL
	je	exit
	mov	ds:[si][SI_inScroll], FALSE
	mov	ax, ds:[si][SI_winTopLine]	;calculate doc coordinates
	mov	cx, ds:[si][SI_lineHeight]	;of top of window
EC <	tst	ch		>
EC <	ERROR_NZ	0	>
	mul	cl	
	mov	bp, ax				;save desired window pos
	call	GrGetWinBounds			;get current window position
	sub	bp, bx				;get offset to window pos
	mov	bx, bp				;scroll amount in bx
	push	di, si				;dorked in (CallScreen macro)
	mov	dx, size PointDWord
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].PD_y.low, bx		;use line height vertically
	clr	ax
	mov	ss:[bp].PD_y.high, ax
	tst	bx
	jns	notSign
	mov	ss:[bp].PD_y.high, 0xffff	; sign extend sword to dword
notSign:
	mov	ss:[bp].PD_x.low, ax		;don't scroll horizontally
	mov	ss:[bp].PD_x.high, ax
	GetResourceHandleNS	TermView, bx
	mov	si, offset TermView
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	mov	ax, MSG_GEN_VIEW_SCROLL
	call	ObjMessage
	add	sp, size PointDWord
	pop	di, si
exit:
	pop	bp
	ret
ScrollResetView	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BufDrawLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraw lines in screen buffer

CALLED BY:	(INTERNAL) DrawDocument
PASS:		ds:si		- screen object instance data	
		di		- GState
		bh		- first line to draw
		bl		- last line to draw
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/04/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BufDrawLines	proc	near
class	ScreenClass				;we're friends with ScreenClass
	push	bx				;save lines to redraw
	push	ds:[si][SI_curLine]		;else, redraw specified lines
	push	ds:[si][SI_curChar]		;save cursor X position
CUR <	push	ds:[si][SI_curPos]					>

cursorDrawn:
	clr	ds:[si][SI_curChar]
CUR <	clr	ds:[si][SI_curPos]					>
	mov	al, bh				;get first line to print
	clr	ah
	sub	ax, ds:[si][SI_winTopLine]	;calc offset from top of screen
	jnc	haveTopLine
	WARNING	TERM_INVALID_TOP_LINE_NUMBER
	clr	ax
haveTopLine:
	mov	ds:[si][SI_curLine], ax
	clr	bh				;set last line to print
	sub	bx, ds:[si][SI_winTopLine]	;calc offset from top of screen
	mov	bp, bx
topLoop:
	mov     ax, MAX_LINE_CHARS
	call	DrawRemLine			;Redraw the current line
	inc	ds:[si][SI_curLine]		;	current window
	cmp	ds:[si][SI_curLine], bp		;Check if done with window
	jl	topLoop
CUR <	pop	ds:[si][SI_curPos]					>
	pop	ds:[si][SI_curChar]		;restore cursor X position
	pop	ds:[si][SI_curLine]		;restore cursor X position
	call	CheckCursorInSelect		;else don't draw cursor if in 
	pop	bx				;	get lines to redraw
	jc	exit				;	select region
cursor:
	mov	ax, ds:[si][SI_winTopLine]	;calc line cursor on
	add	ax, ds:[si][SI_curLine]		;if cursor not in area	
	cmp	al, bh 				; that is being redrawn
	jb	exit				; don't attempt to
	cmp	al, bl				; redraw the cursor
	ja	exit				;
	call	DrawSelectCursor		;
exit:
	ret					
BufDrawLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetGraphicsModes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the TextColor and the AreaColor for current GState

CALLED BY:	ScreenReverseOn, ScreenNormalMode

PASS:		ds:si		- screen object instance data	
		di		- GState
		
RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/06/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetGraphicsMode proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit
	mov	al, ds:[si][SI_fontColor]       ;
	mov     ah, CF_INDEX                 ;set text, line and background
	call    GrSetTextColor                  ;       colors
	mov     al, ds:[si][SI_backColor]
	call    GrSetAreaColor
exit:
	ret
SetGraphicsMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFontNewScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	adjust the current screen to the new document size

CALLED BY:	(INTERNAL) ScreenBison12, ScreenBison9Or12
PASS:		ds:si		- screen object instance data	
		[SI_screenBuf]	- pointing to unlocked segemnt
		
RETURN:		nothing
		di		- ptr to gState

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		When changing font sizes we can't always maintain the same 
		screen contents.  For example, if in BISON_9, we
		display 24 lines our view will take up the whole screen.
		When we jump up to BISON_12 there is no way we can
		display 24 lines with the increased font size.  So
		we could do some window checking and figure out
		exactly how many lines we can display, but I propose
		that I just display the seven lines before the cursor.
		I'm assuming that there is no valid data in lines below
		the cursor  (you can't be in VI when changing fonts or
		and screen addressing program, cause can't guarantee
		that able to display a full screen.)
		
		So if the cursor is on the 24th line of the current screen 
		then after the routine, the last NUM_SHOW_LINES lines
		will be at the top of the screen.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/07/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetFontNewScreen proc	near
class	ScreenClass				;we're friends with ScreenClass
	mov	bx, ds:[si][SI_screenHandle]	;lock the screen buffer	
	call	MemLock
	mov	ds:[si][SI_screenBuf], ax
	call    CalcTextLines			;figure how many lines of text
						;	can be displayed
	mov	di, ds:[si][SI_gState]		;get gstate
						;if window can accomadate both
	cmp	cl, MAX_LINES			;big and small fonts then
	je	scrollUp			;  don't need to shrink window	
	mov	cx, ds:[si][SI_curLine]
	sub	cx, NUM_SHOW_LINES
	jle	gotTopLine	
	push	cx				;save window adjust amount
saveScreen:
	push	cx				;save our counter
	call	BufScrollUp			;save these lines to scroll 
	call	BufClearLine
	pop	cx
	loop	saveScreen
	mov	ds:[si][SI_curLine], NUM_SHOW_LINES
	pop	cx				;offset the window by this
	mov	ax, ds:[si][SI_winTopLine]	;many lines
	add	cx, ax
	cmp	cx, SCROLL_LINES		;make sure don't set the top
	jb	10$				; of the screen past the
	mov	cx, SCROLL_LINES		; abs bottom of scroll buf	
10$:
	mov	ds:[si][SI_winTopLine], cx
	jmp	short gotTopLine
scrollUp:
	call	WinClear			;don't want UI to bitblit screen
gotTopLine:
	push	di, si
	call	RecalcSize
;	call	CheckViewSize
	push	bx
	call	ResetWindow
	pop	dx				;get #cols,#lines we display
	mov	cl, dh				;pass #cols in cx
	clr	ch				;pass #lines in dx
	clr	dh				;
	call	UpdateWinDisplay

	pop	di, si

	mov	bp, ds:[si][SI_curLine] 	;save line position	
	clr     ds:[si][SI_curLine]          	;get position for top of win
	call    CalcCursorPos                   ;reset current line
						; (bx = y-origin)
	mov	ds:[si][SI_curLine], bp 	;restore line position	
	push	si
	mov	dx, size PointDWord
	sub	sp, dx
	mov	bp, sp
	clr     ax                              ;use for x-origin
	mov	ss:[bp].PD_x.low, ax		;zero x origin
	mov	ss:[bp].PD_x.high, ax
	mov	ss:[bp].PD_y.low, bx		;y origin in bx
	mov	ss:[bp].PD_y.high, ax
	tst	bx
	jns	notSign
	mov	ss:[bp].PD_y.high, 0xffff	; sign extend sword to dword
notSign:
	GetResourceHandleNS	TermView, bx
	mov	si, offset TermView
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	mov	ax, MSG_GEN_VIEW_SET_ORIGIN
	call	ObjMessage
	add	sp, size PointDWord
	pop	si
	mov	di, ds:[si][SI_gState]		;restore gstate ptr
	mov	bx, ds:[si][SI_screenHandle]	;unlock the screen buffer	
	call	MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>
	ret
SetFontNewScreen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WinInvalScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate current screen

CALLED BY:	(INTERNAL) ScreenScrollBufEmpty
PASS:		di		- GState
		
RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/11/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WinInvalScreen proc	near
	cmp	di, BOGUS_VAL
	je	exit
	call	GrGetWinBounds			;get current window position
	sub	dx, bx				;convert document coords
	sub	cx, ax				;  to window coords
	clr	ax
	mov	bx, ax
	mov	bp, ax
	mov	si, ax
	call	WinInvalReg
exit:
	ret
WinInvalScreen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseDrawLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase the line in preparation for a DrawRemLine call

CALLED BY:	DrawRemLine

PASS:		ds:si			- instance data	
		di			- gState handle
		ax			- number of characters to erase
		SI_screenBuf
		SI_curLine
		SI_curChar		- text to draw

RETURN:		nothing

DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The check for '0 chars to erase is a hack a result of 
	NULLs coming through the stream and not being stored so cursor
	hasn't moved. 
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/11/89	Initial version
	dennis  01/12/89        hacked up coordinates for dorked fonts
	brianc	4/23/91		fix for border width = 0 change

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EraseDrawLine	proc	near
class	ScreenClass				;we're friends with ScreenClass
	tst	ax				;if no text to erase
	jz	exit
	cmp	di, BOGUS_VAL 			;if no GState then exit
	je	exit
	push	ax
if HALF_AND_FULL_WIDTH	;------------------------------------------------------
	push	ds, si, di
	clr	di
	mov	ch, {byte} ds:[si].SI_curLine	; cx = buffer offset for curLine
	clr	cl
SBCS <	shr	cx, 1							>
	add	cx, ds:[si].SI_curChar		; offset to start char
	add	cx, ds:[si].SI_curChar
	push	cx
	mov	cx, ax				; cx = # chars
	mov	dx, ds:[si].SI_charWidth	; dx = half-width char width
EC <	call	CheckScreenBuf						>
	mov	ds, ds:[si][SI_screenBuf]	; ds:si = this line
	pop	si
checkChar:
	add	di, dx				; add in half-width char
	lodsw					; ax = char
	call	CheckHalfWidth
	jc	halfWidth
	add	di, dx				; else, full-width char
halfWidth:
	loop	checkChar
	mov	ax, di
	pop	ds, si, di
else	;----------------------------------------------------------------------
	mov	cx, ds:[si][SI_charWidth]	;multiply #chars to erase by
	mul	cl				;  width of chars
endif	;----------------------------------------------------------------------
;border width = 0 fix
;	dec     ax                              ;QUICK:FIX for "off by 1" bug?
	push	ax				;save width of area to erase
	mov	al, ds:[si][SI_backColor]	; get back color
	mov	ah, CF_INDEX
	call	GrSetAreaColor			
	call	CalcCursorPos
;	inc	bx				;dork with eraseing
	pop	cx				;get width of area to erase
	add	cx, ax				;get end of rectangle 
	mov	dx, bx
	add	dx, ds:[si][SI_lineHeight]
;border width = 0 fix
;	dec 	dx				;line parameters
	call	GrFillRect			;and white out screen
	pop	ax
exit:
	ret
EraseDrawLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRemLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw current line paying attention to any graphic attributes
		in the line.

CALLED BY:	(INTERNAL) BufDrawLines, DoNewLine, DoTextAttribute,
		ScreenClearToEndLine, ScreenData, ScreenDelChar,
		ScreenRestoreCurChar
PASS:		ds:si		- instance data	
		di		- gState handle
		ax		- number of characters to draw
		ss		- dgroup
		bp		- saved data not to be trashed
		[SI_screenBuf]	- locked segment

RETURN:		nothing

DESTROYED:	es	

PSEUDO CODE/STRATEGY:
		While #chars to print != 0
			check attribute of characters until		
			all chars procesed or two styles differ
			If chars not done
				print chars up to style change
				Set style change
				continue	
			if all chars processed
				DrawTextLine

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	1/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawRemLine	proc	near
class	ScreenClass				;we're friends with ScreenClass
	push	es, bp
	push	ds:[si][SI_curChar]		;can't dork with cursor position
CUR <	push	ds:[si][SI_curPos]					>
	cmp	di, BOGUS_VAL 			;if valid GState then continue
	jne	10$				;	
	jmp	exit				;	else  exit
10$:
EC <	call	CheckScreenBuf						>
	mov	es, ds:[si][SI_screenBuf]
	mov	dh, {byte} ds:[si][SI_curLine]	;get line # to print
	clr	dl				;find the line in the buffer
SBCS <	shr	dx, 1				;dx -> start of line to print>
	mov	bp, dx				;copy ptr to start of line
	mov	bx, ds:[si][SI_curChar]
	add	dx, bx				;dx->start of string to print
DBCS <	add	dx, bx				;char offset -> byte offset>
	mov	ss:[headPtr], dx
	add	bp, LINE_GRAFX_START		;es:bp->start of line attributes
if DBCS_PCGEOS	;-------------------------------------------------------------
	add	bp, bx				;es:bp = start of string attr
	clr	dl				;reset char counter
	mov	dh, al				;dh = # chars to process
attrLoop:
	inc	dl
	mov	bl, es:[bp]
	mov	bh, es:[bp]+1
	mov	ss:[newAttr], bh
	cmp	bl, bh
	je	next
else	;---------------------------------------------------------------------
	shr	bx, 1				;find attribute byte for col #
	jc	odd
	mov	ss:[oddCol], FALSE
	jmp	short topLoop
odd:
	mov	ss:[oddCol], TRUE
topLoop:	
	add	bp, bx				;es:bp->start of string attr
	clr	dl				;reset char counter
	mov	dh, al				;set #chars to process
checkNibble:
	inc	dl
	cmp	ss:[oddCol], TRUE
	jne	evenNibble
	call	CmpOddEven
	je	next
	jmp	short drawText
evenNibble:
	call	CmpEvenOdd
	je	next
	and	bl, ODD_COL_MASK		;pass attribute in low nibble
drawText:
endif	;---------------------------------------------------------------------
	call	SetLineAttribute		;set new attributes
	clr	ah
	mov	al, dl				;pass #chars to draw
	push	dx				;save nibble counters
	call	EraseDrawLine			;erase in new attributes
	mov	dx, ss:[headPtr]
	call	DrawTextLine			;drew in old attribute
	mov	bl, ss:[newAttr]		;now draw in new attribute
	call	SetLineAttribute
	pop	dx
	sub	dh, dl				;reduce #chars left to draw
	tst	dh				;if done exit
	jz	exit				;
	add	{byte} ds:[si][SI_curChar], dl
CUR <	call	GetCurPosFromCurChar					>
	add	{byte} ss:[headPtr], dl
DBCS <	add	{byte} ss:[headPtr], dl		; char offset -> byte offset>
	clr	dl				;reduce #chars processed
next:
if DBCS_PCGEOS	;-------------------------------------------------------------
	inc	bp
	cmp	dl, dh
	jb	attrLoop
else	;---------------------------------------------------------------------
	not	ss:[oddCol]			;flip odd/even flag
	cmp	dl, dh
	jb	checkNibble
endif	;---------------------------------------------------------------------
	clr	ah
	mov	al, dh				;get length of string
	tst	dh				;if empty string, forget it
	jz	exit
	mov	dx, ax
	call	SetLineAttribute
	mov	ax, dx
	call	EraseDrawLine
	mov	dx, ss:[headPtr]
	call	DrawTextLine
exit:
CUR <	pop	ds:[si][SI_curPos]					>
	pop	ds:[si][SI_curChar]		;can't dork with cursor position
	pop	es, bp
	ret
DrawRemLine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CmpEvenOdd, CmpOddEven
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares odd and even nibbles 

CALLED BY:	DrawRemLine

PASS:		es:[bp]	- byte to play with

RETURN:		es:[bp]	- next byte to process

DESTROYED:	bx, cx

PSEUDO CODE/STRATEGY:

	 compares odd byte to an even byte
	 increments bp, so next even odd byte will behave properly

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	1/08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not DBCS_PCGEOS
CmpEvenOdd 	proc	near
	mov	bl, es:[bp]
	mov	bh, bl			
	and	bh, ODD_COL_MASK		;isolate odd/low nibble
	mov	cl, 4
	shr	bl, cl				;isolate even/high nibble	
	mov	ss:[newAttr], bh		;save possible new attributes
	cmp	bl, bh
exit:
	ret
CmpEvenOdd	endp

CmpOddEven 	proc	near
	mov	bl, es:[bp]
	and	bl, ODD_COL_MASK		;isolate odd nibble
	inc	bp
	mov	bh, es:[bp]
	mov	cl, 4
	shr	bh, cl
	mov	ss:[newAttr], bh		;save possible new attributes	
	cmp	bl, bh
exit:
	ret
CmpOddEven	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetLineAttribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process line attribute

CALLED BY:	(INTERNAL) DrawRemLine, DrawScrollLine
PASS:		ds:si			- instance data	
		di			- gState handle
		bl			- line attribute to set
					  (0) if normal mode
RETURN:		nothing

DESTROYED:	ax, bx	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Doesn't check if individual attributes should be
		turned off.

		*** Doesn't test for bold.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	1/05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetLineAttribute 	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit

	call	SetNormalAttribute		; always start with normal

	tst	bl				;check if in normal mode
	je	exit

if	_CHAR_SET
	;
	; Test if character set bit is set
	;
	test	bl, mask CA_GRAPH_CHAR_LO
	jz	reverse				; default is already G0, so
						; check next flag
	mov	al, TCS_GRAPHICS		; set graphics characters
	call	SetCharacterSet
else
;;handle special selected attribute - 8/21/90 brianc
	push	bx
	andnf	bl, mask CA_SELECTED_LO or mask CA_REV_LO
	cmp	bl, mask CA_SELECTED_LO or mask CA_REV_LO
	pop	bx
	je	underscore			; if both set, normal mode...
						; ...then check underline
	test	bl, mask CA_SELECTED_LO
	jz	reverse
	call	SetReverseAttribute		; (can be countered with CA_REV)
endif	; if _CHAR_SET
reverse:
	test	bl, mask CA_REV_LO
	je	underscore
	call	SetReverseAttribute
underscore:
	test	bl, mask CA_UNDER_LO
	je	exit				
	call	SetUnderlineAttribute		
exit:
	ret
SetLineAttribute	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNormalAttribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set normal attributes 

CALLED BY:	(INTERNAL) ScreenNormalMode, ScreenResetVT, SetLineAttribute
PASS:		ds:si			- instance data	
		di			- gState handle

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	1/05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CHAR_SET

SetNormalAttribute	proc	near
	call	SetTextStyleNormalAttr
	;
	; Also set character set
	;
	mov	al, DEFAULT_CHARACTER_SET
	call	SetCharacterSet
	ret
SetNormalAttribute	endp

SetTextStyleNormalAttr	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit
	cmp	ds:[si][SI_reverseVideo], TRUE
	je	doReverse
	mov     ds:[si][SI_backColor], C_WHITE
	mov     ds:[si][SI_fontColor], C_BLACK
	jmp	short setGraphics
doReverse:
	mov     ds:[si][SI_backColor], C_BLACK
	mov     ds:[si][SI_fontColor], C_WHITE
setGraphics:
	call    SetGraphicsMode
	clr     al                              ;nuke bits to set
	mov     ah, mask TS_UNDERLINE or mask TS_BOLD
	call    GrSetTextStyle
exit:
	ret
SetTextStyleNormalAttr	endp

else
	
SetNormalAttribute 	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit
	cmp	ds:[si][SI_reverseVideo], TRUE
	je	doReverse
	mov     ds:[si][SI_backColor], C_WHITE
	mov     ds:[si][SI_fontColor], C_BLACK
	jmp	short setGraphics
doReverse:
	mov     ds:[si][SI_backColor], C_BLACK
	mov     ds:[si][SI_fontColor], C_WHITE
setGraphics:
	call    SetGraphicsMode
	clr     al                              ;nuke bits to set
	mov     ah, mask TS_UNDERLINE or mask TS_BOLD
	call    GrSetTextStyle
exit:
	ret
SetNormalAttribute	endp
	
endif	; _CHAR_SET

SetReverseAttribute 	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit
	cmp	ds:[si][SI_reverseVideo], TRUE
	je	doNormal
	mov     ds:[si][SI_backColor], C_BLACK    ;set background to black
	mov     ds:[si][SI_fontColor], C_WHITE    ;  and foreground to white
	jmp	short setGraphics
doNormal:
	mov     ds:[si][SI_backColor], C_WHITE    ;set background to black
	mov     ds:[si][SI_fontColor], C_BLACK    ;  and foreground to white
setGraphics:
	call    SetGraphicsMode
exit:
	ret
SetReverseAttribute	endp


SetBoldAttribute 	proc	near
class	ScreenClass				;we're friends with ScreenClass
	mov     al, mask TS_BOLD                ;
	clr     ah                              ;nuke bits to reset
	call    GrSetTextStyle
exit:
	ret
SetBoldAttribute	endp


SetUnderlineAttribute 	proc	near
class	ScreenClass				;we're friends with ScreenClass
	mov     al, mask TS_UNDERLINE           ;
	clr     ah                              ;nuke bits to reset
	call    GrSetTextStyle
exit:
	ret
SetUnderlineAttribute	endp

if	_CHAR_SET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCharacterSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the character set

CALLED BY:	(INTERNAL) ScreenSetGraphicsCommon, ScreenSetUSASCIICommon,
		SetLineAttribute, SetNormalAttribute
PASS:		al	= TermCharacterSet
		di	= gstate
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	4/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCharacterSet	proc	near
		uses	ax, cx, dx
		.enter
EC <		Assert_gstate	di					>
	;
	; Test the character set for USASCII 
	;
		cmp	al, TCS_USASCII
		je	setUSASCII
		cmp	al, TCS_GRAPHICS
EC <		ERROR_NE TERM_INVALID_CHARACTER_SET			>
		jne	exit			; none of it is supported,
						; ignore 
		mov	cx, TERM_GRAPHICS_FONT
		jmp	setFont
setUSASCII:
		mov	cx, TERM_USASCII_FONT
setFont:
		clr	dx, ax			; not set point size
		call	GrSetFont
exit:
		.leave
		ret
SetCharacterSet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSetUSASCIICommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current character set to USASCII 

CALLED BY:	(INTERNAL) ScreenG0SelectUSASCII, ScreenG1SelectUSASCII,
		ScreenSelectG0, ScreenSelectG1
PASS:		ds:di	= ScreenClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Set the graphics char set flag;
	Use the USASCII font;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	1/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenSetUSASCIICommon	proc	near
		class	ScreenClass
		uses	ax, di
		.enter
EC <		Assert_fptr	dsdi					>
	
		BitClr	ds:[di][SI_attributes], CA_GRAPH_CHAR_LO
		mov	al, TCS_USASCII
		mov	di, ds:[di][SI_gState]
		call	SetCharacterSet
	
		.leave
		ret
ScreenSetUSASCIICommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSetGraphicsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current character set to graphics 

CALLED BY:	(INTERNAL) ScreenG0SelectGraphics, ScreenG1SelectGraphics,
		ScreenSelectG0, ScreenSelectG1
PASS:		ds:di	= ScreenClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Set the graphics char set flag;
	Use the graphics font;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	1/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenSetGraphicsCommon	proc	near
		class	ScreenClass
		uses	ax, di
		.enter
EC <		Assert_fptr	dsdi					>
	
		BitSet	ds:[di][SI_attributes], CA_GRAPH_CHAR_LO
		mov	al, TCS_GRAPHICS
		mov	di, ds:[di][SI_gState]
		call	SetCharacterSet

		.leave
		ret
ScreenSetGraphicsCommon	endp

endif	; if _CHAR_SET
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoVisualBell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	make screen flash

CALLED BY:	

PASS:		ds:si			- instance data	
		di			- gState handle

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	1/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoVisualBell 	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL		; any gstate?
	jz	exit			; nope
	mov	al, MM_INVERT		; prepare to invert
	call	GrSetMixMode
	call	GrGetWinBounds		; ax->cx, bx->dx
	call	GrFillRect		; invert it
	call	GrFillRect		; invert again
	mov	al, MM_COPY
	call	GrSetMixMode
exit:
	ret
DoVisualBell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoCursorDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle actions involved with a cursor down motion

CALLED BY:	(INTERNAL) DoNewLine, ScreenCR, ScreenCursorDown, ScreenCursorDownN
PASS:		ds:si			- instance data	
		di			- gState handle
		ss			- dgroup
RETURN:		C		- set if scrolled and DRAW pending so
				don't draw cursor

DESTROYED:	

PSEUDO CODE/STRATEGY:

	BUG ?? :: THERE MAY BE PROBLEMS IF WE WRAP AROUND AT BOTTOM OF SCREEN
	AND FORCE A SCROLL,  SCROLL MAY CAUSE A CURSOR TO DRAW AND
	CALLING ROUTINE MAY DRAW CURSOR.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	1/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoCursorDown 	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp     ds:[si][SI_curLine], MAX_LINES-1;if hit end of screen buffer
	jl      noForce
	mov     ss:[forceScroll], TRUE          ;force a scroll
	jmp     short checkScroll
noForce:
	mov     ss:[forceScroll], FALSE
checkScroll:
NCUR <	cmp	ds:[si][SI_curChar], MAX_LINE_CHARS			>
CUR <	cmp	ds:[si][SI_curPos], MAX_LINE_CHARS			>
	jne	10$
	clr	ds:[si][SI_curChar]		;autowrap
CUR <	clr	ds:[si][SI_curPos]					>
10$:
	call    CheckForScroll                  ;scroll if necessary
	jnc     exit                         	;if scrolled exit
	inc     ds:[si][SI_curLine]             ;else increment cursor line #
	cmp	ds:[si].SI_curLine, MAX_LINES
	jb	okay
EC <	WARNING	CUR_LINE_ADJUSTED					>
	mov	ds:[si].SI_curLine, MAX_LINES-1	;else force last line
okay:
	stc					;draw cursor
exit:
	ret
DoCursorDown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoNewLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the cursor to start of a new line

CALLED BY:	ScreenData

PASS:		ds:si		- instance data	
		di		- gState handle
		es:bp		- buffer of chars
		cx, dx		- chars data

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	1/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoNewLine 	proc	near
class	ScreenClass				;we're friends with ScreenClass
	push  cx, dx, es, bp
	mov	ss:[wrapped], TRUE		;flag that we're wrapping
	clr	ds:[si][SI_curChar]		;Carriage Return
CUR <	clr	ds:[si][SI_curPos]					>
	mov	ax, MAX_LINE_CHARS		;print the current line
	call	EraseDrawLine			;	before advancing
	call	DrawRemLine			;	cursor
	call    DoCursorDown			;LineFeed
	pop cx, dx, es, bp
	ret
DoNewLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBoxCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw an outline cursor

CALLED BY:	(INTERNAL) DrawSelectCursor
PASS:		ds:si	- screen object instance data	
		ax, bx	- (left, top) position to dork with cursor
		di	- GState
		
RETURN:		nothing

DESTROYED:	ax, bx, cx, dx	

PSEUDO CODE/STRATEGY:
			

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 2/20/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawBoxCursor	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit
	mov	cx, ax				;save left bounds
	mov	al, MM_INVERT			; invert box outline
	call	GrSetMixMode
	call	GetBoxCoord			;get rectangle coords
	push	ax, bx, cx, dx			;  and save em
	call	GrFillRect
	pop	ax, bx, cx, dx			;get rectangle coords
	inc	ax				;adjust left bounds
	inc	bx				;adjust top
	dec	cx				;adjust right 
	dec	dx				;adjust bottom
	call	GrFillRect			;re-invert inner rectangle
	mov	al, MM_COPY			;restore draw mode
	call	GrSetMixMode			;
exit:
	ret
DrawBoxCursor	endp


EraseBoxCursor	proc	near
class	ScreenClass				;we're friends with ScreenClass
	cmp	di, BOGUS_VAL
	je	exit
	mov	cx, ax
	mov	al, MM_INVERT			; invert box outline
	call	GrSetMixMode
	call	GetBoxCoord
	push	ax, bx, cx, dx			;  and save em
	inc	ax				;adjust left bounds
	inc	bx				;adjust top
	dec	cx				;adjust right 
	dec	dx				;adjust bottom
	call	GrFillRect			;erase the box outline
	pop	ax, bx, cx, dx			;get rectangle coords
	call	GrFillRect			;erase the cursor
	mov	al, MM_COPY			;restore draw mode
	call	GrSetMixMode			;
exit:
	ret
EraseBoxCursor	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBoxCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calculate cursor dimensions

CALLED BY:	DrawCursor

PASS:		ds:si	- screen object instance data	
		cx, bx	- (left, top) position to dork with cursor
		di	- GState
		
RETURN:		nothing

DESTROYED:	ax, bx, cx, dx	

PSEUDO CODE/STRATEGY:
			

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 2/20/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetBoxCoord	proc	near
	class	ScreenClass

	mov	ax, cx				;(restore left value)
	add	cx, ds:[si][SI_charWidth]	;and set the right bounds
;;border width = 0 fix
;;	dec	cx				;to width of character data
;makes cursor too short - brianc 8/15/90
;	inc	bx				;adjust top bounds 
	mov	dx, bx				;get top bounds 
	add	dx, ds:[si][SI_lineHeight]	;and set the bottom bounds 
;;border width = 0 fix
;;;	sub	dx,2				;  one less than line height	
;;;makes cursor too short - brianc 8/15/90
;;	dec	dx				;  one less than line height	

	ret
GetBoxCoord	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoArrowKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send arrow key sequence depending on terminal

CALLED BY:	(INTERNAL) ScreenKbdCharReal
PASS:		ds:si	- screen object instance data	
		cl	- VC_UP, VC_LEFT, VC_RIGHT, VC_DOWN
		di	- GState
		ss	- dgroup
		
RETURN:		nothing

DESTROYED:	ds, es, cx, bx

PSEUDO CODE/STRATEGY:
			

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine is lame, I should really try to check the termcap file
	on disk and then search for the method number to determine what
	characters to put out, but don't have time for that now.  So i'll
	do a quick and dirty approach.  This approach is lame cause it 
	doesn't support user defined termcaps and if the termcap sequences
	for ARROW keys are ever changed the internal arrow tables will have
	to be modified too.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/04/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
if C_SYS_UP+1 ne C_SYS_DOWN
	ErrMessage <Somebody changed the Cursor key values>
endif
if C_SYS_DOWN+1 ne C_SYS_RIGHT
	ErrMessage <Somebody changed the Cursor key values>
endif
if C_SYS_RIGHT+1 ne C_SYS_LEFT
	ErrMessage <Somebody changed the Cursor key values>
endif
else
if VC_UP+1 ne VC_DOWN
	ErrMessage <Somebody changed the Cursor key values>
endif
if VC_DOWN+1 ne VC_RIGHT
	ErrMessage <Somebody changed the Cursor key values>
endif
if VC_RIGHT+1 ne VC_LEFT
	ErrMessage <Somebody changed the Cursor key values>
endif
endif

if DBCS_PCGEOS
vt52Up		wchar	2, CHAR_ESC,"A"
vt52Down	wchar	2, CHAR_ESC,"B"
vt52Right	wchar	2, CHAR_ESC,"C"
vt52Left 	wchar	2, CHAR_ESC,"D"
vt52Home 	wchar	2, CHAR_ESC,"H"

vt100Up		wchar	3, CHAR_ESC,"OA"
vt100Down	wchar	3, CHAR_ESC,"OB"
vt100Right	wchar	3, CHAR_ESC,"OC"
vt100Left 	wchar	3, CHAR_ESC,"OD"
vt100Home 	wchar	3, CHAR_ESC,"[H"

;
; Arrow codes to send out when we are in ANSI mode and Cursor Reset
;
vt100ResetUp	wchar	3, CHAR_ESC,"[A"
vt100ResetDown	wchar	3, CHAR_ESC,"[B"
vt100ResetRight	wchar	3, CHAR_ESC,"[C"
vt100ResetLeft 	wchar	3, CHAR_ESC,"[D"

wy50Up		wchar	1, CHAR_VT 
wy50Down	wchar	1, CHAR_NL 
wy50Left	wchar	1, CHAR_BS
wy50Right	wchar	1, CHAR_FF
wy50Home	wchar	2, CHAR_CTRL, CHAR_CTRL 

ansiUp		wchar	3, CHAR_ESC,"[A"
ansiDown	wchar	3, CHAR_ESC,"[B"
ansiLeft	wchar	3, CHAR_ESC,"[D"
ansiRight	wchar	3, CHAR_ESC,"[C"
ansiHome	wchar	3, CHAR_ESC,"[H"

ibm3101Up	wchar	2, CHAR_ESC,'A'
ibm3101Down	wchar	2, CHAR_ESC,'B'
ibm3101Left	wchar	2, CHAR_ESC,'D'
ibm3101Right	wchar	2, CHAR_ESC,'C'
ibm3101Home	wchar	2, CHAR_ESC,'H'

tvi950Up	wchar	1, CHAR_VT
tvi950Down	wchar	1, 016h
tvi950Left	wchar	1, CHAR_BS
tvi950Right	wchar	1, CHAR_FF
tvi950Home	wchar	2, CHAR_CTRL, CHAR_CTRL
else
vt52Up		db	2, CHAR_ESC,"A"
vt52Down	db	2, CHAR_ESC,"B"
vt52Right	db	2, CHAR_ESC,"C"
vt52Left 	db	2, CHAR_ESC,"D"
vt52Home 	db	2, CHAR_ESC,"H"

vt100Up		db	3, CHAR_ESC,"OA"
vt100Down	db	3, CHAR_ESC,"OB"
vt100Right	db	3, CHAR_ESC,"OC"
vt100Left 	db	3, CHAR_ESC,"OD"
vt100Home 	db	3, CHAR_ESC,"[H"

;
; Arrow codes to send out when we are in ANSI mode and Cursor Reset
;
vt100ResetUp	db	3, CHAR_ESC,"[A"
vt100ResetDown	db	3, CHAR_ESC,"[B"
vt100ResetRight	db	3, CHAR_ESC,"[C"
vt100ResetLeft 	db	3, CHAR_ESC,"[D"

wy50Up		db	1, CHAR_VT 
wy50Down	db	1, CHAR_NL 
wy50Left	db	1, CHAR_BS
wy50Right	db	1, CHAR_FF
wy50Home	db	2, CHAR_CTRL, CHAR_CTRL 

ansiUp		db	3, CHAR_ESC,"[A"
ansiDown	db	3, CHAR_ESC,"[B"
ansiLeft	db	3, CHAR_ESC,"[D"
ansiRight	db	3, CHAR_ESC,"[C"
ansiHome	db	3, CHAR_ESC,"[H"

ibm3101Up	db	2, CHAR_ESC,'A'
ibm3101Down	db	2, CHAR_ESC,'B'
ibm3101Left	db	2, CHAR_ESC,'D'
ibm3101Right	db	2, CHAR_ESC,'C'
ibm3101Home	db	2, CHAR_ESC,'H'

tvi950Up	db	1, CHAR_VT
tvi950Down	db	1, 016h
tvi950Left	db	1, CHAR_BS
tvi950Right	db	1, CHAR_FF
tvi950Home	db	2, CHAR_CTRL, CHAR_CTRL
endif

vt52ArrowTable	label	word
	word	offset	vt52Up			;VC_UP
	word	offset	vt52Down		;VC_DOWN
	word	offset	vt52Right		;VC_RIGHT
	word	offset	vt52Left		;VC_LEFT
	word	offset	vt52Home		;VC_HOME
	
vt100ArrowTable	label	word
	word	offset	vt100Up			;VC_UP
	word	offset	vt100Down		;VC_DOWN
	word	offset	vt100Right		;VC_RIGHT
	word	offset	vt100Left		;VC_LEFT
	word	offset	vt100Home		;VC_HOME

;
; Arrow codes to send out when we are in ANSI mode and Cursor Reset
;
vt100ResetArrowTable	label	word
	word	offset	vt100ResetUp		;VC_UP
	word	offset	vt100ResetDown		;VC_DOWN
	word	offset	vt100ResetRight		;VC_RIGHT
	word	offset	vt100ResetLeft		;VC_LEFT
	word	offset	vt100Home		;VC_HOME
						; use same Home cursor code
wyse50ArrowTable	label	word	
	word	offset	wy50Up			;VC_UP
	word	offset	wy50Down		;VC_DOWN
	word	offset	wy50Right		;VC_RIGHT
	word	offset	wy50Left		;VC_LEFT
	word	offset	wy50Home		;VC_HOME

ansiArrowTable	label	word	
	word	offset	ansiUp			;VC_UP
	word	offset	ansiDown		;VC_DOWN
	word	offset	ansiRight		;VC_RIGHT
	word	offset	ansiLeft		;VC_LEFT
	word	offset	ansiHome		;VC_HOME

ibm3101ArrowTable	label	word	
	word	offset	ibm3101Up		;VC_UP
	word	offset	ibm3101Down		;VC_DOWN
	word	offset	ibm3101Right		;VC_RIGHT
	word	offset	ibm3101Left		;VC_LEFT
	word	offset	ibm3101Home		;VC_HOME

tvi950ArrowTable	label	word	
	word	offset	tvi950Up		;VC_UP
	word	offset	tvi950Down		;VC_DOWN
	word	offset	tvi950Right		;VC_RIGHT
	word	offset	tvi950Left		;VC_LEFT
	word	offset	tvi950Home		;VC_HOME

TermArrowTable	label	word
	word	0				;TTY has no arrow support
	word	offset vt52ArrowTable	
	word	offset vt100ArrowTable	
	word	offset wyse50ArrowTable	
	word	offset ansiArrowTable	
	word	offset ibm3101ArrowTable	
	word	offset tvi950ArrowTable	

; Tables are used to define sequence of characters to be sent out when
; arrow keys are pressed. Format of tables is 
; <length of sequence>,character sequence>
;
DoArrowKey	proc	near
	mov	bl, ss:[termType] 		;if term type is TTY 
	tst	bl
	jz	exit				;	bail out
	clr	bh				;
	call	DoArrowKeyCheckVT100		;carry set if not VT100
						;  bx <- nptr to cursor table
	jnc	getPointerToTable
	shl	bx, 1				;else point to table of
	add	bx, offset TermArrowTable	;	arrow sequences
	mov	bx, cs:[bx]			;get pointer to table

getPointerToTable:
SBCS <	clr	ch							>
SBCS <	sub	cl, VC_UP			;calc index into arrow table>
DBCS <	sub	cx, C_SYS_UP			;calc index into arrow table>
SBCS <	shl	cl, 1				;			>
DBCS <	shl	cx, 1				;			>
	add	bx, cx				;		
	mov	bx, cs:[bx]			;dereference ptr
SBCS <	mov	cl, cs:[bx]			;get number of chars to write>
DBCS <	mov	cx, cs:[bx]			;get number of chars to write>
	jcxz	exit				;if no chars zip out of here	
	inc	bx				;else point to sequence
DBCS <	inc	bx							>
	segmov	ds, ss, si			;make ds point to dgroup
	segmov	es, cs, si			;
	mov	si, bx				;es:si->buffer to write out
;	CallMod	SendBuffer
;echo locally for half-duplex - brianc 1/3/91
	call	BufferedSendBuffer
exit:
	ret
DoArrowKey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoArrowKeyCheckVT100
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check and set cursor code table if we are doing vt100. 

CALLED BY:	(INTERNAL) DoArrowKey
PASS:		bl	= Terminals
		*ds:si	= ScreenClass object instance data
RETURN:		carry clear if current term type is not VT100
		carry set if current term type *is* VT100
			bx	= nptr to appropriate VT100 cursor table
DESTROYED:	bx if carry clear
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	2/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoArrowKeyCheckVT100	proc	near
		class	ScreenClass
		uses	si
		.enter
EC <		Assert_objectPtr	dssi, ScreenClass		>
	;
	; Check if we are using VT100 and cursor key mode reset. If so, use
	; VT100 Reset Arrow table
	;
NRSP <		cmp	bl, VT100					>
NRSP <		stc				; default is not VT100	>
NRSP <		jne	done						>

		mov	bx, offset vt100ArrowTable
		mov	si, ds:[si]		; ds:si <- instance data
	;
	; Cursor keys mode is effect only in keypad application mode and
	; ANSI/VT52 mode is set. However, most terminal server implementation
	; out there disregard keypad mode, so we just don't check keypad
	; mode. 
	;
		BitTest	ds:[si][SI_modeFlags], SVTMF_ANSI_VT52 
		jz	vt100Done
		BitTest	ds:[si][SI_modeFlags], SVTMF_CURSOR_KEY
		jnz	vt100Done
		mov	bx, offset vt100ResetArrowTable
						; use reset vt100 arrow codes
vt100Done:
		clc
done:
		.leave
		ret
DoArrowKeyCheckVT100	endp
		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertToTextCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Covert mouse coordinate to character coordinates

CALLED BY:	ScreenStartSelect

PASS:		ds:si	- screen object instance data	
		cx	- x position (document coord)
		dx	- y position (document coord)
		ss	- dgroup
		
RETURN:		cx	- text column of mouse
		dx	- text line of mouse
		
DESTROYED:	

PSEUDO CODE/STRATEGY:
	Takes ptr location and calculates what line and column that should be 
	basedon the font height and width.  Need to check that the coordinates
	are valid for that screen.  Meaning that if our screen is a 
	maximum of 24 lines high.  So if ptr goes below the window
	then don't want to return that ptr on line 25. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 2/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertToTextCoords	proc	near
	class	ScreenClass

if HALF_AND_FULL_WIDTH	;-----------------------------------------------------
	uses	bx, di, si, ds
	.enter
	push	cx				; save X coordinate
else	;---------------------------------------------------------------------
	cmp	ch, NEG_VALUE			;if left bound off the screen
	jne	10$				;
	clr	ch
	clr	al				;then just make it the 0 col
	jmp	short colOK
10$:
	mov	ax, cx				;pass x coordinate
	mov	cx, ds:[si][SI_charWidth]	;
	div	cl				;calculate the col #	
	cmp	al, MAX_LINE_CHARS		;
	jbe	colOK				;
	mov	al, MAX_LINE_CHARS		;make sure col# is valid
colOK:						;	
	mov	cl, al				;save col#
endif	;---------------------------------------------------------------------
	cmp	dh, NEG_VALUE
	jne	20$
	clr	dh
	clr	al
	jmp	short lineOK
20$:
	mov	ax, dx				;pass y coordinate
	mov	dx, ds:[si][SI_lineHeight]	;
	div	dl				;calculate the line #
	mov	dx, ds:[si][SI_winTopLine]	;if line # past bottom
	add	dl, MAX_LINES-1			;of screen
	cmp	al, dl				;then pass the screen bottom
	ja	exit				;line
lineOK:
	mov	dl, al				;  and save it
exit:
if HALF_AND_FULL_WIDTH	;-----------------------------------------------------
	;
	; compute column number (uses line number)
	;
	pop	di				; di = X coordinate
	tst	di
	jns	computeCol
	clr	cx
	jmp	haveCol

computeCol:
	push	dx				; save computed line
	cmp	dx, ds:[si].SI_winTopLine
	jae	inScreen
	mov	bx, ds:[si].SI_scrollHandle
	jmp	short haveLineOffset

inScreen:
	mov	bx, ds:[si].SI_screenHandle
	sub	dx, ds:[si].SI_winTopLine	; dx = line in screen buffer
haveLineOffset:
	clr	ax				; ax = offset within buffer
	mov	ah, dl
	mov	dx, ds:[si].SI_charWidth	; dx = half-width char width
	mov	si, ax
	call	MemLock
	mov	ds, ax				; ds:si = cur line
	mov	cx, MAX_LINE_CHARS
checkChar:
	sub	di, dx
	js	foundCol
	lodsw					; ax = char
	cmp	ax, C_DELETE
	jbe	halfWidth
	sub	di, dx
	js	foundCol
halfWidth:
	loop	checkChar
foundCol:
	call	MemUnlock
	mov	ax, MAX_LINE_CHARS
	xchg	ax, cx				; ax = found col, cx = MAX
	sub	cx, ax				; cx = selected col
	pop	dx
haveCol:
	.leave
endif	;---------------------------------------------------------------------
	ret
ConvertToTextCoords	endp

if	not _CHAR_SET
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the word at the mouse position

CALLED BY:	(INTERNAL)
PASS:		ds:si	- screen object instance data	
		cx	- column mouse is on (text coord)
		dx	- line mouse is on (text coord)
		ss	- dgroup
		[SI_screenBuf]	- pointing to unlocked segemnt
		
RETURN:		es	- segement of selected text	
		
DESTROYED:	

PSEUDO CODE/STRATEGY:
			

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 2/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SelectWord	proc	near
	class	ScreenClass

	mov	bx, ds:[si][SI_screenHandle]	;lock the screen buffer	
	call	MemLock
	mov	ds:[si][SI_screenBuf], ax

	mov	ss:[selStartLine], dx		;store line selected text on
	mov	ss:[selEndLine], dx
	call	GetSelectLine
	add	bx, cx				;offset to column position
DBCS <	add	bx, cx				;char offset -> byte offset>
if DBCS_PCGEOS
	mov	ax, {wchar} es:[bx]
	call	LocalGetWordPartType
	cmp	ax, WPT_SPACE
	je	exit
else
	cmp	{byte} es:[bx], CHAR_SPACE	;check if text under mouse
	je	exit
	cmp	{byte} es:[bx], CHAR_TAB
	je	exit
	cmp	{byte} es:[bx], CHAR_CR
	je	exit
endif
	call	GetWordBounds			;find the bounds of the word
	call	HighlightText
exit:
	call 	FreeSelectLine
	mov	bx, ds:[si][SI_screenHandle]	;unlock the screen buffer	
	call	MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>
	ret
SelectWord	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the line at the mouse position

CALLED BY:	ScreenStartSelect

PASS:		ds:si	- screen object instance data	
		cx	- column mouse is on (text coord)
		dx	- line mouse is on (text coord)
		ss	- dgroup
		[SI_screenBuf]	- pointing to unlocked segemnt
		
RETURN:		es	- segement of selected text	
		
DESTROYED:	

PSEUDO CODE/STRATEGY:
			

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SelectLine	proc	near
	class	ScreenClass

	mov     bx, ds:[si][SI_screenHandle]
	call    MemLock
	mov	ds:[si][SI_screenBuf], ax

	mov	ss:[selStartLine], dx
	mov	ss:[selEndLine], dx
	call	GetSelectLine
	clr	dx				;start at col 0
	mov	bx, MAX_LINE_CHARS		; and select whole line
	mov	ss:[selStartCol], dx
	mov	ss:[selEndCol], MAX_LINE_CHARS
	call	HighlightText
exit:
	call	FreeSelectLine

	mov     bx, ds:[si][SI_screenHandle]
	call    MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>
	ret
SelectLine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetWordBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find start and end of word at mouse position

CALLED BY:	(INTERNAL)
PASS:		ds:si	- screen object instance data	
		cx	- column mouse is on (text coord)
		dx	- line mouse is on (text coord)
		es:[bx]	- mouse position in screen buffer
		ss	- dgroup
		
RETURN:		dx	- start column of selected word
		bx	- end column + 1 of selected word
		
DESTROYED:	
	
PSEUDO CODE/STRATEGY:
		any problems assuming this line only called by double click
		so then selStartLine and selEndLine are same?

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 2/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetWordBounds	proc	near
DBCS <	push	si							>
	inc	cx				;adjust #cols to search
if DBCS_PCGEOS
	mov	si, -1				;no current WPT yet
getStart:
	push	ax
	mov	ax, {wchar} es:[bx]
	call	LocalGetWordPartType
	cmp	si, -1
	jne	compareWPT
	mov	si, ax				;store current WPT
compareWPT:
	cmp	ax, si				;different WPT?
	pop	ax
	jne	gotStart			;yes, found start
else
getStart:
	cmp	{byte} es:[bx], CHAR_SPACE
	je	gotStart
	cmp	{byte} es:[bx], CHAR_TAB
	je	gotStart
	cmp	{byte} es:[bx], CHAR_CR
	je	gotStart
endif
notStart:
	dec	bx
DBCS <	dec	bx							>
	loop	getStart
	inc	bx				;start at 0 col
DBCS <	inc	bx							>
	jmp	short startZero			;start at 0 col
gotStart:
	inc	bx				;move ptr to start of word
DBCS <	inc	bx							>
startZero:
	mov	ss:[selStartCol], cx		;store start of word selected
	mov	ss:[selEndCol], cx		;store end of word selected
	mov	cx, MAX_LINE_CHARS 
	sub	cx, ss:[selStartCol]		;set #chars to search for
	mov	ss:[selTextPtr], bx		;save pointer to selected text
	mov	dx, bx				;
getEnd:
if DBCS_PCGEOS
	push	ax
	mov	ax, {wchar} es:[bx]
	call	LocalGetWordPartType
	cmp	ax, si				;different WPT?
	pop	ax
	jne	gotEnd				;yes, found end
else
	cmp	{byte} es:[bx], CHAR_SPACE
	je	gotEnd
	cmp	{byte} es:[bx], CHAR_TAB
	je	gotEnd
	cmp	{byte} es:[bx], CHAR_CR
	je	gotEnd
endif
	inc	bx
DBCS <	inc	bx							>
	loop	getEnd
gotEnd:
	sub	bx, dx
DBCS <	shr	bx, 1				;byte offset -> char offset>
	add	ss:[selEndCol], bx		;get end of word
	mov	dx, ss:[selStartCol]		;pass start of selected word
exit:
DBCS <	pop	si							>
	ret
GetWordBounds	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighlightText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hightlight text

CALLED BY:	ScreenStartSelect

PASS:		ds:si	- screen object instance data	
		dx	- start column of selected word
		bx	- #chars to dork with
		es	- segment of selected text
		ss	- dgroup
		selLinePtr	- ptr to line data
		di	- gState
		
RETURN:		
		
DESTROYED:	
	
PSEUDO CODE/STRATEGY:
	To highlight the word, set the reverse video bit in the word
	and then redraw those characters.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 2/26/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HighlightText	proc	near
	tst	bx				;exit if no chars to dork
	jz	exit
;;	mov	al, ds:[si][SI_attributes]	;pass current attributes	
;;	xor	al, mask CA_REV_LO		;  plus the reverse flag
;;use special selection attribute - brianc 8/21/90
	mov	al, mask CA_SELECTED_LO
	mov	cx, 0
	call	DoTextAttribute			;  as attributes to store
	tst	ss:[textSelected]
	jnz	exit
	mov	ss:[textSelected], TRUE		;flag text selected
	call	EnableCopy
exit:
	ret
HighlightText	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnHighlightText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	unhighlight text

CALLED BY:	(INTERNAL)
PASS:		ds:si	- screen object instance data	
		dx	- start column of selected word
		bx	- #chars to dork with
		ss	- dgroup
		es	- segment containing selected text
		selLinePtr - ptr to line data
		di	- gState
		
RETURN:		
		
DESTROYED:	
	
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 2/26/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UnHighlightText	proc	near
	tst	bx
	jz	exit
;;	mov	al, ds:[si][SI_attributes]	;pass char attribute
;;	and	al, not mask CA_REV_LO		; minus the reverse flag
;;use special selection attribute - brianc 8/21/90
	mov	al, mask CA_SELECTED_LO
	mov	cx, -1				; remove text attributes
	call	DoTextAttribute
exit:
	ret
UnHighlightText	endp
endif	; if !_CHAR_SET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoTextAttribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	store attributes into character data

CALLED BY:	ScreenStartSelect

PASS:		ds:si	- screen object instance data	
		dx	- start column of selected word
		bx	- #chars to dork with
		ss	- dgroup
		al	- char attributes to store or remove
		selLinePtr	- ptr to line data
		es	- segement of selected text
		di	- gState
		cx	= 0 to add in attribute bits
			<> 0 to remove attribute bits
		
RETURN:		
		
DESTROYED:	
	
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 3/03/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoTextAttribute	proc	near
	class	ScreenClass

	mov	bp, dx
	add	bp, bx				;get last col to dork
	push	dx, bx, di			;save cursor position
						;	save #chars to dork
						;	save GState value
	mov	di, ax				;pass attriubutes to set
selectChar:
	push	cx				; save set/clear flag
	mov	ax, di				;pass attributes to store (AL)
	mov	ah, ch				; ah = set/clear flag
	mov	cx, dx				;pass col# of selected char
	mov	bx, ss:[selLinePtr]
;	call	StoreCharAttr
;correct behavior for highlighting - brianc 8/21/90
	tst	ah
	jnz	clearAttr
	call	AddCharAttr
	jmp	short afterAttr
clearAttr:
	call	ClearCharAttr
afterAttr:
;
	pop	cx				; retrieve set/clear flag
	inc	dx
	cmp	dx, bp				;are we done selecting?
	jb	selectChar
	pop	dx, ax, di			;restore GState,#chars, col pos
	mov	bx, ss:[selEndLine]
	cmp	bx, ds:[si][SI_winTopLine]	;  make line screen relative
	jl	inScroll
	push	ds:[si][SI_curLine]		;save original cursor position
	push	ds:[si][SI_curChar]		;
CUR <	push	ds:[si][SI_curPos]					>
	mov	ds:[si][SI_curChar], dx		;set cursor position
	sub	bx, ds:[si][SI_winTopLine]	;  make line screen relative
	mov	ds:[si][SI_curLine], bx		;  
CUR <	call	GetCurPosFromCurChar					>
	call	DrawRemLine			;
CUR <	pop	ds:[si][SI_curPos]					>
	pop	ds:[si][SI_curChar]		;	
	pop	ds:[si][SI_curLine]		;
	jmp	short exit
inScroll:
	mov	bp, ss:[selLinePtr]		;get start of selected line
	mov	cl, dl	 			;  offset to selected text
	mov	ch, al				;get #chars to print

	mov	ax, ss:[selEndLine]
	mov	bx, ds:[si][SI_lineHeight]	;calc Y pos to print
	mul	bl
	mov	dx, ax				;save it

if HALF_AND_FULL_WIDTH	;-----------------------------------------------------
	;
	; es:bp = text
	; cl = # chars
	; ds:si = Screen object instance
	;
	push	ds, si, di, cx, dx
	clr	di
	clr	ch				; cx = # chars
	mov	dx, ds:[si].SI_charWidth	; dx = half-width char width
	segmov	ds, es
	mov	si, bp
checkChar:
	add	di, dx				; add in half-width char
	lodsw					; ax = char
	call	CheckHalfWidth
	jc	halfWidth
	add	di, dx				; else, full-width char
halfWidth:
	loop	checkChar
	mov	ax, di
	pop	ds, si, di, cx, dx
else	;---------------------------------------------------------------------
	mov	ax, ds:[si][SI_charWidth]	;calc X printing pos
	mul	cl				;
endif	;---------------------------------------------------------------------
	mov	bx, dx				;get y position

	call	DrawScrollLine			;print the line
exit:
	ret
DoTextAttribute	endp

if	not _CHAR_SET
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	expand or contract the selected area.

CALLED BY:	(INTERNAL)
PASS:		ds:si	- screen object instance data	
		cx, dx	- range to add or remove from the selection.
		ss	- dgroup
		[SI_screenBuf]	- pointing to unlocked segemnt
		
RETURN:		
		
DESTROYED:	
	
PSEUDO CODE/STRATEGY:
	if line change 
		do right thing
	else
		extend right or left

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	bug fix:  if the cursor is in the selected range and the range
		changes so that the cursor is no longer selected then
		the cursor should be redrawn, because it'll have been
		erased when the selected range shrunk.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 3/08/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AdjustSelection	proc	near
	class	ScreenClass

	mov     bx, ds:[si][SI_screenHandle]
	call    MemLock
	mov     ds:[si][SI_screenBuf], ax

	cmp	dx, ss:[selEndLine]		;did mouse change lines?
	jne	adjustLine			;yep
	cmp	cx, ss:[selEndCol]		;exit if mouse hasn't moved
	jne	adjustCol
	jmp	exit
adjustCol:					;
	push	cx	
	jb	adjustLeft
	call	SelectRight
	jmp	short colDone
adjustLeft:
	call	SelectLeft
colDone:
	pop	cx
	mov	ss:[selEndCol], cx
	jmp	exit
adjustLine:
	mov	ss:[mouseCol], cx		;save mouse position
	mov	ss:[mouseLine], dx		;
	push	cx, dx 	
	ja	selectDown			
	call	LineSelectUp			;mouse moved up
	jmp	short lineDone
selectDown:					;mouse moved down
	call	LineSelectDown
lineDone:
	pop	cx, dx				;
	mov	ss:[selEndCol], cx		;update the selected area
	mov	ss:[selEndLine],dx 		;
exit:
	;
	; ensure cursor is drawn, if not in selection
	;
	cmp	ds:[si].SI_cursorDrawn, TRUE	; is cursor already drawn?
	je	afterCursor
	call	CheckCursorInSelect
	jc	afterCursor			; cursor in selected area,
						;	don't mess with it
	call	DrawSelectCursor		; else, force it to be drawn
afterCursor:

	mov     bx, ds:[si][SI_screenHandle]
	call    MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>
	ret
AdjustSelection	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mouse moved right

CALLED BY:	AdjustSelection

PASS:		ds:si	- screen object instance data	
		ss	- dgroup
		cx	- document col mouse is on
		dx	- document line mouse is on
		
RETURN:		
		
DESTROYED:	
	
PSEUDO CODE/STRATEGY:
if (mouseLine < selStartLine)
	if (mouseCol > selEndCol) 
	; decrease selected area
	DeSelect from (selEndCol, mouseCol)
	
if (mouseLine > selStartLine)
	if (mouseCol > selEndCol)
	; increase selected area
	Select from (selEndCol, mouseCol)

If (mouseLine == selStartLine)
	if (mouseCol > selEndCol) && (mouseCol > selStartCol)
	  if (selStartCol > selEndCol)
		;unselect old area
		UnSelectArea
	; select new area
		Select from (selEndCol, mouseCol)

	if (mouseCol > selEndCol) && (mouseCol < selStartCol)
	; decrease selected area
		DeSelect from (selEndCol, mouseCol)

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	-------		---------------
	dennis	 3/10/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectRight	proc	near
	call	GetSelectLine
	cmp	dx, ss:[selStartLine]		;if mouse above selstartLine
	jb	deselect			;then deselect this area
	ja	select				;if mouse above then select
	cmp	cx, ss:[selStartCol]		;else check the start Column
	jb	deselect	
select:
	mov	ss:[selectRout], offset HighlightText
	mov	dx, ss:[selStartLine]		;if single line and increasing	
	cmp	dx, ss:[selEndLine]		;  selected area then, check
	jne	doAdjust			;  if text to unselect
	mov	dx, ss:[selStartCol]
	cmp	dx, ss:[selEndCol]
	jbe	doAdjust
	call	UnSelectArea
	jmp	short doAdjust
deselect:
	mov	ss:[selectRout], offset UnHighlightText
doAdjust:
	mov	dx, ss:[selEndCol]
	sub	cx, dx 				; #chars to adjust = 
	mov	bx, cx				; mouseCol - selEndCol =
	call	ss:[selectRout]			;(De)Select (selEndCol,mouseCol)
	call	FreeSelectLine
	ret
SelectRight	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mouse moved left

CALLED BY:	(INTERNAL)
PASS:		ds:si	- screen object instance data	
		ss	- dgroup
		cx	- document col mouse is on
		dx	- document line mouse is on
		
RETURN:		
		
DESTROYED:	
	
PSEUDO CODE/STRATEGY:

if (mouseLine < selStartLine)
	if (mouseCol < selEndCol)
	; increase selected area
	Select from (selEndCol, mouseCol)

if (mouseLine > selStartLine)
	if (mouseCol < selEndCol)
	; decrease selected area 
		DeSelect from (mouseCol, selEndCol)
		
if (mouseLine == selStartLine)
	if (mouseCol < selEndCol) && (mouseCol < selStartCol)
		if (selEndCol > selStartCol) 
			UnSelectArea
	; increase selected area
		Select from (mouseCol, selEndCol)

	if (mouseCol < selEndCol) && (mouseCol > selStartCol)
	; decrease selected area

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	-------		---------------
	dennis	 3/10/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectLeft	proc	near
	call	GetSelectLine
	cmp	dx, ss:[selStartLine]		;if start of selected area
	ja	deselect			;  above mouse
	jb	select
	cmp	cx, ss:[selStartCol]
	jae	deselect	
select:
	mov	ss:[selectRout], offset HighlightText
	mov	dx, ss:[selStartLine]
	cmp	dx, ss:[selEndLine]
	jne	doAdjust
	mov	dx, ss:[selStartCol]		;if (selEndCol > selStartCol) 
	cmp	dx, ss:[selEndCol]		;
	jae	doAdjust			;
	call	UnSelectArea			;	UnSelectArea
	jmp	short doAdjust
deselect:
	mov	ss:[selectRout], offset UnHighlightText
doAdjust:
	mov	dx, cx
	mov	bx, ss:[selEndCol]		;#chars to adjust = 
	sub	bx, dx 				;selEndCol - mouseCol =
	call	ss:[selectRout]			;(De)Select (mouseCol,selEndCol)
	call	FreeSelectLine
	ret
SelectLeft	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineSelectUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	adjust selected area for a mouse movement up

CALLED BY:	AdjustSelection

PASS:		ds:si	- screen object instance data	
		ss	- dgroup
		dx	- document line mouse is on
RETURN:		
		
DESTROYED:	
	
PSEUDO CODE/STRATEGY:
if (mouseLine < selEndLine) && (mouseLine < selStartLine)
; check if old area has to be unselected
if (selEndLine > selStartLine) || 
   (mouseCol > selStartCol) ||
   (mouseLine < startLine && selEndLine > selStartLine)
	UnselectArea	

; increase selected area
	Select from (0, selEndCol)
	Select lines between selEndLine and mouseLine
	Select from (mouseCol, 80)

if (mouseLine < selEndLine) && (mouseLine > selStartLine)
; decrease selected area
	DeSelect from (0, selEndCol)
	DeSelect lines between selEndLine and mouseLine
	if (startCol > selEndCol) && (mouseCol < selStartCol)
		DeSelect (selStartCol, 80)
		Select (mouseCol, selStartCol)
	else
		DeSelect (mouseCol, 80)

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 3/08/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LineSelectUp	proc	near
	mov	cx, ss:[selEndCol]		;pass left bound
	cmp	dx, ss:[selStartLine]
	jb	incSelArea			;increase selected area
decSelArea:					;  
	mov	ss:[selectRout], offset UnHighlightText
	jmp	short doAdjust	
incSelArea:
	mov	bx, ss:[selEndLine]		;if (selEndLine > selStartLine)	
	cmp	bx, ss:[selStartLine]		;	UnselectArea	
	ja	unselect
	jb	10$
	cmp	cx, ss:[selStartCol]		;if select text to right of
	jb	10$				;  select start and get a
unselect:
	call	UnSelectArea			;  mouse up then unselect text
	mov	cx, ss:[selEndCol]		;pass revised left bounds
10$:
	mov	ss:[selectRout], offset HighlightText
doAdjust:
	mov	dx, ss:[selEndLine]		;
	call	GetSelectLine			;
	clr	dx				;		
	mov	bx, cx				;Select from (0, selEndCol)
	call	ss:[selectRout]			;
	call 	FreeSelectLine
	dec	ss:[selEndLine]
	mov	dx, ss:[selEndLine]		;
	cmp	dx, ss:[mouseLine]
	je	lastLine
	mov	cx, MAX_LINE_CHARS		;Select whole lines between 
	jmp	short doAdjust			;mouse and select Line end
lastLine:
	call	GetSelectLine			;Select from (mouseCol, 80)
	cmp	ss:[selectRout], offset	HighlightText
	je	50$				;if selecting text don't need
						;  to check special case	
	mov	bx, ss:[selStartLine]		;special case only when single 
	cmp	bx, ss:[selEndLine]		;  line being selected
	jne	50$
	mov	bx, ss:[selStartCol]		;
	cmp	bx, ss:[selEndCol]		;if (startCol > selEndCol) && 
	jb	50$				;
	cmp	bx, ss:[mouseCol]		;	(mouseCol < startCol)
	jb	50$
	mov	bx, MAX_LINE_CHARS		;
	mov	dx, ss:[selStartCol]		;	
	sub	bx, dx				;
	call	UnHighlightText			; DeSelect (selStartCol, 80)
	mov	dx, ss:[mouseCol]
	mov	bx, ss:[selStartCol]
	sub	bx, dx
	call	HighlightText			; Select (mouseCol, selStartCol)
	jmp	short done
50$:
	mov	bx, MAX_LINE_CHARS		;
	mov	dx, ss:[mouseCol]		;
	sub	bx, dx				;calc #chars to select
	call	ss:[selectRout]			;
done:
	call 	FreeSelectLine
	ret
LineSelectUp	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineSelectDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	adjust selected area for a mouse movement down

CALLED BY:	(INTERNAL)
PASS:		ds:si	- screen object instance data	
		ss	- dgroup
		dx	- document line mouse is on
		cx	- document col mouse is on
		
RETURN:		
		
DESTROYED:	
	
PSEUDO CODE/STRATEGY:
if (mouseLine > selEndLine) && (mouseLine > selStartLine)
; check if old area has to be unselected
  if (selEndLine < selStartLine) ||
     (selStartLine == selEndLine && mouseCol < selStartCol) ||
     (mouseLine > startLine && selEndline < startLine )
	UnselectArea	
; increase selected area
	Select from (selEndCol, 80)
	While (selEndLine != mouseLine)
		Highlight ++selEndLine (0,80)
	Select selEndLine (0, mouseCol)

if (mouseLine > selEndLine) && (mouseLine < selStartLine)
; decrease selected area
	DeSelect selEndLine (selEndCol, 80)
	While (selEndLine != mouseLine)
		UnHighlight ++selEndLine (0,80)
	if (startCol < selEndCol) && (mouseCol > startCol)
		DeSelect (0, selStartCol)
		Select (selStartCol, mouseCol)
	else	
		DeSelect (0, mouseCol)

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 3/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LineSelectDown	proc	near
	mov	cx, ss:[selEndCol]		;pass left bound
	mov	bx, ss:[selEndLine]		;check if cursor moved 
	cmp	bx, ss:[selStartLine]		;completely below the
	ja	10$				;  (upward) selected region
	cmp	dx, ss:[selStartLine]		;  if so unselect it
	ja	unselect
10$:
	cmp	dx, ss:[selStartLine]
	jbe	decSelArea			;decrease selected area
	mov	bx, ss:[selStartLine]		;if startLine == endLine
	cmp	bx, ss:[selEndLine]
	jb	incSelArea
	mov	bx, ss:[mouseCol]
	cmp	bx, ss:[selStartCol]		;  && mouseCol < startCol
	ja	incSelArea			;then unselect
unselect:
	call	UnSelectArea
	mov	cx, ss:[selEndCol]		;pass revised left bounds
incSelArea:
	mov	ss:[selectRout], offset HighlightText
	jmp	short doAdjust	
decSelArea:					;  
	mov	ss:[selectRout], offset UnHighlightText
doAdjust:
	mov	dx, ss:[selEndLine]		;
	call	GetSelectLine			;
	mov	dx, cx				;pass left bound
	mov	bx, MAX_LINE_CHARS		;	
	sub	bx, dx				;
	call	ss:[selectRout]			;(De)Select (selEndCol, 80)
	call 	FreeSelectLine
	inc	ss:[selEndLine]			;
	mov	dx, ss:[selEndLine]		;
	cmp	dx, ss:[mouseLine]
	je	lastLine
	clr	cx				;Select whole lines between 	
	jmp	short doAdjust			;mouseLine and selLineEnd
lastLine:
	call	GetSelectLine			;(De)Select from (0,mouseCol)
	clr	dx				;
	cmp	ss:[selectRout], offset	UnHighlightText
	jne	70$				;increasing selected region?
	mov	bx, ss:[selStartLine]		;check special case on 
	cmp	bx, ss:[selEndLine]		;  when only one line selected
	jne	70$
	mov	bx, ss:[selStartCol]		;if (startCol < selEndCol) && 
	cmp	bx, ss:[selEndCol]		;
	ja	70$				;
	cmp	bx, ss:[mouseCol]		;	(mouseCol > startCol)
	ja	70$				;
	mov	bx, ss:[selStartCol]		;
	call	UnHighlightText			;unselect (0, seStartCol)line
	mov	dx, ss:[selStartCol]		;
	mov	bx, ss:[mouseCol]		;
	sub	bx, dx				;
	call	HighlightText			;select (selStartCol, mouseCol)
	jmp	short done
70$:						;increasing selected region
	mov	bx, ss:[mouseCol]		;get #chars to select
	call	ss:[selectRout]			;
done:
	call 	FreeSelectLine
	ret
LineSelectDown	endp
endif	; if !_CHAR_SET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetScreenLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get screen line the mouse is on

CALLED BY:	ScreenDragSelect, ScreenPtr, SelectWord

PASS:		ds:si	- screen object instance data	
		ss	- dgroup
		dx	- document line mouse is on
		
RETURN:		es:[bx]	- ptr to line data	
		
DESTROYED:	
	
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 3/06/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetScreenLine	proc	near
	class	ScreenClass

	mov	bx, dx				;pass mouse line#
	sub	bx, ds:[si][SI_winTopLine]
	mov	bh, bl				;convert line # to index into
	clr	bl				;buffer
SBCS <	shr	bx, 1				;			>
EC <	call	CheckScreenBuf						>
	mov	es, ds:[si][SI_screenBuf]	;get screen buffer
	ret
GetScreenLine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetScrollLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get Scroll line the mouse is on

CALLED BY:	(INTERNAL) GetSelectLine
PASS:		ds:si	- screen object instance data	
		ss	- dgroup
		dx	- document line mouse is on
		
RETURN:		es:[bx]	- ptr to line data	
		
DESTROYED:	
	
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Any routine that calls this routine should call FreeSelectLine
	to free up the scroll block after its used.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 3/06/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetScrollLine	proc	near
	class	ScreenClass

	uses	dx
	.enter
	tst	ss:[scrollLocked]		;flag that locking 
	jz	10$
	mov	es, ss:[scrollSeg]
	jmp	short getScrollLine
10$:
	mov	ss:[scrollLocked], TRUE		;
	mov	bx, ds:[si][SI_scrollHandle]	;	scroll segment
	call	MemLock
	mov	es, ax				;es->scroll segment
	mov	ss:[scrollSeg], ax
getScrollLine:
	add	dx, ds:[si][SI_scrollTop]	;offset to line in
	cmp	dx, SCROLL_LINES		;  scroll buffer
	jl	getLine
	sub	dx, SCROLL_LINES
getLine:	
	mov	bh, dl				;pass mouse line#
	clr	bl				;calculate index into scroll buf
SBCS<	shr	bx, 1							>
	.leave
	ret
GetScrollLine	endp

if	not _CHAR_SET
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnSelectArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	unselect text

CALLED BY:	ScreenStartSelect, AdjustSelection

PASS:		ds:si		- screen object instance data	
		[SI_screenBuf]	- pointing to unlocked segment
		ss		- dgroup
		bp, cx, dx	- button info
RETURN:		
		
DESTROYED:	es	
	
PSEUDO CODE/STRATEGY:
		unhighlight the selected text
		reset the select values
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 3/06/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UnSelectArea	proc	near
	class	ScreenClass

	uses	cx
	.enter
	tst	ss:[textSelected]
	je	exit
	call	CheckCursorInSelect
	jnc	10$
	mov	ds:[si][SI_cursorDrawn], FALSE	;cursor's been erased	
	mov	ss:[curInSelect], FALSE		;cursor no longer in select
10$:
	call	UnHighlightArea
	call	DrawSelectCursor		;do we need to redraw cursor?
	mov	bx, ss:[selStartLine]		;reset selected values 
	mov	ss:[selEndLine], bx
	mov	bx, ss:[selStartCol]
	mov	ss:[selEndCol], bx
	mov	ss:[textSelected], FALSE	;flag no text selected
	call	DisableCopy			;disable 'Edit/Copy' entry
exit:
	.leave
	ret
UnSelectArea	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnHighlightArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	unselect text

CALLED BY:	(INTERNAL)
PASS:		ds:si		- screen object instance data	
		ss		- dgroup
		bp, cx, dx	- button info
		[SI_screenBuf]	- unlocked segment
RETURN:		
		
DESTROYED:	es	
	
PSEUDO CODE/STRATEGY:
	if selEndLine < selStartLine	(selected area growing up)
		DeSelect (selEndCol, 80)
		While ( --selEndLine != selStartLine)
			DeSelect selEndLine (0,80)
		DeSelect selEndLine (0, selStartCol)

	if selEndLine > selStartLine	(selected area growing down)
		DeSelect (0, selEndCol)
		While ( --selEndLine != selStartLine)
			DeSelect selEndLine (0,80)
		DeSelect selEndLine (selStartCol, 80)

Could make these both a common routine if when deselecting an area that
is growing down manipulate the selStart(Line/Col) variable instead
of the selEnd(Line/Col) variable.  But the AddTextAttribute uses 
'selEndLine' to determine which line to print, so if manipulated the
selStartLine variable instead then the wrong line would be redrawn.
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 3/06/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnHighlightArea	proc	near
	class	ScreenClass

	push	bp, cx, dx
	mov	bx, ds:[si][SI_screenHandle]
	call	MemLock
	mov	ds:[si][SI_screenBuf], ax
	mov	dx, ss:[selEndLine]		;check if multi-lines are
	cmp	dx, ss:[selStartLine]		;	selected
	ja	growDown			;is selected area growing down ?
	jb	growUp				;is selected area growing up ?
	jmp	singleLine			;selected area is a single line 
growDown:
	mov	ss:[selectUp], FALSE		;selected area growing down
	jmp	short deSelectArea
growUp:
	mov	ss:[selectUp], TRUE		;selected area growing down
deSelectArea:
	mov	dx, ss:[selEndLine]		;
	call	GetSelectLine			;
	tst	ss:[selectUp]			;is selected area up
	je	10$				;nope
	mov	dx, ss:[selEndCol]		;
	mov	bx, MAX_LINE_CHARS		;
	sub	bx, dx				;
	jmp	short deSelectLast		;DeSelect (selEndCol, 80)
10$:
	clr	dx				;DeSelect (0, selEndCol)
	mov	bx, ss:[selEndCol]		;
deSelectLast:
	call	UnHighlightText			;
	call 	FreeSelectLine			;
checkLine:
	tst	ss:[selectUp]
	jnz	15$
	dec	ss:[selEndLine]	
	jmp	short 20$
15$:
	inc	ss:[selEndLine]	
20$:
	mov	dx, ss:[selEndLine]		;
	cmp	dx, ss:[selStartLine]		;While(selEndLine!=selStartLine)
	je	lastLine			;
	call	GetSelectLine			;
	clr	dx				;
	mov	bx, MAX_LINE_CHARS		;
	call	UnHighlightText			;DeSelect --selEndLine (0,80)
	call	FreeSelectLine			;
	jmp	short checkLine			;
lastLine:	
	call	GetSelectLine			;
	tst	ss:[selectUp]			;is selected area up
	je	30$	
	clr	dx				;
	mov	bx, ss:[selStartCol]		;
	jmp	short deselectFirst		;DeSelect (0, selStartCol)
30$:
	mov	dx, ss:[selStartCol]		;
	mov	bx, MAX_LINE_CHARS
	sub	bx, dx				;DeSelect (selStartCol, 80)
deselectFirst:
	call	UnHighlightText			;
	call 	FreeSelectLine 			;
	jmp	short done
singleLine:
	mov	dx, ss:[selEndLine]		;
	call	GetSelectLine
	mov	dx, ss:[selStartCol]		;
	mov	bx, ss:[selEndCol]
	cmp	dx, bx				;check if start before end
	jb	50$				;
	xchg	dx, bx				;	
50$:
	sub	bx, dx				;pass length of text
	call	UnHighlightText
	call 	FreeSelectLine
done:
	pop	bp, cx, dx
	mov	bx, ds:[si][SI_screenHandle]
	call	MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>
	ret
UnHighlightArea	endp
endif	; if !_CHAR_SET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawScrollLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	print line of text interpreting graphic attributes

CALLED BY:	ScrollDrawLines

PASS:		ds:si	- ptr to instance data
		ch	- # chars to print
		cl	- col # to start printing at
		ax, bx	- (x,y) coordinates to print at
		es:bp	- pointer to start of selected line
		di	- handle of gState

RETURN:		
		
DESTROYED:	
	
PSEUDO CODE/STRATEGY:
	DrawRemLine is the routine that prints lines in the screen buffer.
	This routine interprets the character attributes.  Would be nice
	if common routine called to handle both printing from scroll
	and from the screen buffers, but not going to try to do that yet.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	--------	-----------
	dennis	03/07/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawScrollLine	proc	near
	cmp	di, BOGUS_VAL
	jne	10$
	jmp	bogus
10$:
	push	si, dx, bp			;save printing info
	push	ax, bx				;save printing position
	mov	bx, bp
	add	bp, LINE_GRAFX_START		;es:bp->start of line attributes
	mov	ss:[scrollCol], cl		;get start col
	mov	dh, ch				;set #chars to process
	clr	dl				;clear char counter
	clr	ch				;
	add	bx, cx				;offset to column to print
DBCS <	add	bx, cx				;char offset -> byte offset>
	mov	ss:[headPtr], bx		;save start of string
if DBCS_PCGEOS	;-------------------------------------------------------------
	add	bp, cx
attrLoop:
	inc	dl
	mov	bl, es:[bp]
	mov	bh, es:[bp]+1
	mov	ss:[newAttr], bh
	cmp	bl, bh
	je	next
else	;---------------------------------------------------------------------
	shr	cx, 1				;find attribute byte for col #	
	jc	odd
	mov	ss:[oddCol], FALSE
	jmp 	short topLoop
odd:
	mov	ss:[oddCol], TRUE
topLoop:
	add	bp, cx 				;es:bp->start of string attr
checkNibble:
	inc	dl
	cmp	ss:[oddCol], TRUE
	jne	evenNibble
	call	CmpOddEven
	je	next
	jmp	short drawText
evenNibble:
	call	CmpEvenOdd
	je	next
	and	bl, ODD_COL_MASK		;get attribute to set
drawText:
endif	;---------------------------------------------------------------------
	call	SetLineAttribute		;and set gState
	mov	cl, dl				;pass #chars to draw
	clr 	ch
	mov	ss:[charCounter], dx		;save nibble counters
	pop	ax, bx				;get print position
	call	EraseScrollLine
	mov	dx, ss:[headPtr]
	call	DrawScrollText
	push	ax, bx				;push coordinates back on stack
	mov	bl, ss:[newAttr]
	call	SetLineAttribute
	mov	dx, ss:[charCounter]		;restore counter
	sub	dh, dl				;reduce #chars left to draw
	tst	dh				;if not done continue
	jnz	cont				;
	pop	ax, bx				;else pop coordinates off the
	jmp	short exit			;	stack and bug out
cont:
	add	ss:[scrollCol], dl
	clr	dl				;clear char counter
next:
if DBCS_PCGEOS	;-------------------------------------------------------------
	inc	bp
	cmp	dl, dh
	jb	attrLoop
else	;---------------------------------------------------------------------
	not	ss:[oddCol]			;flip odd/even flag
	cmp	dl, dh
	jb	checkNibble
endif	;---------------------------------------------------------------------
	mov	cl, dh				;get length of string
	clr	ch				;if string empty forget it
	tst	cx				;
	jz	exit
	call	SetLineAttribute
	pop	ax, bx
	call	EraseScrollLine
	mov	dx, ss:[headPtr]
	call	DrawScrollText
exit:
	pop	si, dx, bp
bogus:
	ret
DrawScrollLine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseScrollLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	erase text in the scroll buffer

CALLED BY:	(INTERNAL) DrawScrollLine
PASS:		ds:si	- ptr to instance data
		cx	- # chars to erase
		ax, bx	- position to start erasing 
		di	- handle of gState
		es:(ss:[headPtr]) - text we'll be drawing in erased area

RETURN:		
		
DESTROYED:	cx 	
	
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	--------	-----------
	dennis	03/07/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EraseScrollLine	proc	near
	class	ScreenClass

	cmp	di, BOGUS_VAL
	je	exit
	push	ax, bx, cx
	push	ax				;save x position
	mov	ax, cx				;area to erase = 
if HALF_AND_FULL_WIDTH	;------------------------------------------------------
	push	ds, si, di
	clr	di
	mov	dx, ds:[si].SI_charWidth	; dx = half-width char width
	segmov	ds, es				; ds:si = text
	mov	si, ss:[headPtr]
checkChar:
	add	di, dx				; add in half-width char
	lodsw					; ax = char
	call	CheckHalfWidth
	jc	halfWidth
	add	di, dx				; else, full-width char
halfWidth:
	loop	checkChar
	mov	ax, di
	pop	ds, si, di
else	;----------------------------------------------------------------------
	mov	cx, ds:[si][SI_charWidth]	;#chars * char width
	mul	cl				;
endif	;----------------------------------------------------------------------
;change for broder width = 0
;	dec	ax				;HACK MASTER
	push	ax				;save area width
	mov	al, ds:[si][SI_backColor]	;get background color
	mov	ah, CF_INDEX			;
	call	GrSetAreaColor			;
	pop	cx				;get area width
	pop	ax				;get left bound	
	add	cx, ax				;get right bound
;	inc	bx				;HACK MASTER (top bound)
	mov	dx, bx
	add	dx, ds:[si][SI_lineHeight]
;change for broder width = 0
;	dec	dx				;get bottom bound
	call	GrFillRect
	pop	ax, bx, cx
exit:
	ret
EraseScrollLine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawScrollText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	erase text in the scroll buffer

CALLED BY:	DrawScrollLine

PASS:		ds:si	- ptr to instance data
		ax, bx	- position to start printing 
		cx	- # chars to print
		es:dx	- ptr to string to print
		di	- handle of gState

RETURN:		ax, bx	- next position to print	
		
DESTROYED:	cx, dx
	
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	--------	-----------
	dennis	03/07/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawScrollText	proc	near
	class	ScreenClass

	push	ds, si				;save  object instance data
	push	bx				; save Y pos
	add	bx, ds:[si].SI_leading		; adjust Y pos
if HALF_AND_FULL_WIDTH
	push	ds:[si].SI_charWidth
endif
	segmov	ds, es, si
	mov	si, dx				;ds:si->string to print
if HALF_AND_FULL_WIDTH	;------------------------------------------------------
	;
	; figure width of text
	;	ds:si = text
	;	cx = # chars
	;	(on stack) = half-width char width
	;	di = gstate
	;	(ax, bx) = draw text pos
	;
	pop	dx				; dx = half-width char width
	push	ax, si, di, cx
	clr	di
checkChar:
	add	di, dx				; add in half-width char
	lodsw					; ax = char
	call	CheckHalfWidth
	jc	halfWidth
	add	di, dx				; else, full-width char
halfWidth:
	loop	checkChar
	mov	dx, di
	pop	ax, si, di, cx
	push	dx				; save width
endif	;----------------------------------------------------------------------
	cmp	di, BOGUS_VAL
	je	noPrint
	call	GrDrawText
noPrint:
	add	ss:[headPtr], cx
DBCS <	add	ss:[headPtr], cx		; char offset -> byte offset>

if HALF_AND_FULL_WIDTH	;------------------------------------------------------
	pop	dx				; dx = width
	add	ax, dx				; ax = next X position
	pop	bx				; restore Y pos
	pop	ds, si
else	;----------------------------------------------------------------------
	pop	bx				; restore Y pos
	pop	ds, si
	mov	dx, ax				;save current offset
	mov	ax, ds:[si][SI_charWidth]
	mul	cl				;(ax,bx) offset to next
	add	ax, dx				;  print position
endif	;----------------------------------------------------------------------
	ret
DrawScrollText	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return ptr to text of the line selected

CALLED BY:	(INTERNAL) CopySelectText, GetSelectSize
PASS:		ds:si	- ptr to instance data
		dx	- number of selected line 

RETURN:		es:[bx]	- line text
		ss:[selLinePtr] - ptr to text
		
DESTROYED:	ax, bx
	
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	--------	-----------
	dennis	03/08/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSelectLine	proc	near
	class	ScreenClass

	cmp	dx, ds:[si][SI_winTopLine]	
	jae	inScreen	
	call	GetScrollLine
	jmp	short exit
inScreen:
	call	GetScreenLine
exit:
	mov	ss:[selLinePtr], bx		;save ptr to line data
	ret
GetSelectLine	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeSelectLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if scroll segment should be unlocked

CALLED BY:	any routine that calls 'GetSelectLine'

PASS:		ds:si	- ptr to instance data
		di	- GState	
		ss	- dgroup

RETURN:		
		
DESTROYED:	
	
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	--------	-----------
	dennis	03/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeSelectLine	proc	near
	class	ScreenClass

	tst	ss:[scrollLocked]
	jz	exit
	mov	bx, ds:[si][SI_scrollHandle]	;unlock scroll segment
	call	MemUnlock
	mov	ss:[scrollLocked], FALSE
exit:
	ret
FreeSelectLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PasteText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle when text object scrap is dropped on us

CALLED BY:	(INTERNAL) ScreenEndMoveCopy, ScreenPaste
PASS:		ds:*si	- screen instance data
		es	- dgroup
		cx	- transfer flags
			if cx = CIF_QUICK:
				bp = button info from MSG_META_END_MOVE_COPY

RETURN:		ax = ClipboardQuickNotifyFlags

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteParams	struct
	PCP_owner		dword
	PCP_transferParams	CommonTransferParams
	PCP_header		word			;VM block of 
							;	transfer header
	PCP_quickFlags		ClipboardQuickNotifyFlags

	PCP_uifa		word
	PCP_flags		ClipboardItemFlags
PasteParams	ends

PasteText	proc	near
	class	ScreenClass			;we're friends with ScreenClass

	push	cx				;PCP_flags
	push	bp				;PCP_uifa (used if CIF_QUICK)
	sub	sp, size PasteParams - 4	;alloc local var space
	mov	bp, sp				;  and set ptr to it
						; in case item rejected
	mov	ss:[bp].PCP_quickFlags, mask CQNF_NO_OPERATION

	cmp	ss:[canPaste], TRUE
	jne	exitJMP

if	_TELNET
	PrintMessage <"Allow paste text when no connection?">
	jmp	10$
else
	cmp     ss:[serialPort], NO_PORT        ;don't paste text if no port 
	jne	10$				;	opened
	segmov	ds, ss, cx
	clr	cx				;flag that String resouce should
	mov	dx, offset pasteErr		;	be stuffed into cx
	push	bp				; save locals
	mov     bp, ERR_NO_COM
	CallMod DisplayErrorMessage
	pop	bp				; retrieve locals
endif	; _TELNET
		
exitJMP:
	jmp     exit
10$:
	mov	ss:[bp].PCP_owner.handle, 0	; in case no transfer item

	push	bp				;save ptr to local vars
	mov	bp, ss:[bp].PCP_flags		;pass transfer flag
	call	ClipboardQueryItem
	mov	di, bp				; di = # formats
	pop     bp				; retrieve locals
	mov     ss:[bp].PCP_transferParams.CTP_vmFile, bx	; save header
	mov     ss:[bp].PCP_header, ax
	tst	di
	jz	done				; if no transfer item, done

	mov     ss:[bp].PCP_owner.handle, cx	;store owner of selection
	mov     ss:[bp].PCP_owner.chunk,  dx

	; does CIF_TEXT format exist ?
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov     dx, CIF_TEXT                    ;format to search for
	call	ClipboardTestItemFormat
	jc	done
	push    bp
	mov     bx, ss:[bp].PCP_transferParams.CTP_vmFile
	mov     ax, ss:[bp].PCP_header
	mov     bp, ss:[bp].PCP_flags
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov     dx, CIF_TEXT                    ;formats to get
	call    ClipboardRequestItemFormat             ;bx = VM file, ax = VM block
	tst	bp				;ax:bp = VM chain
	pop     bp
	jnz	done				;ignore if DB Item
	mov     ss:[bp].PCP_transferParams.CTP_vmBlock, ax
	call    PasteTransferItem
	;
	; let's resolve the move/copy behavior now
	;
	mov	ax, mask CQNF_COPY		; assume copy
	test	ss:[bp].PCP_uifa, mask UIFA_MOVE shl 8	; forced-move?
							; (this can't come in
							;  if source is copy-
							;	only)
	jz	haveQNF				; nope, use copy
	mov	ax, mask CQNF_MOVE		; else, do move
haveQNF:
	mov	ss:[bp].PCP_quickFlags, ax	; store move/copy flag
done:
	mov	ax, ss:[bp].PCP_header
	mov	bx, ss:[bp].PCP_transferParams.CTP_vmFile
	call	ClipboardDoneWithItem
exit:
	mov	ax, ss:[bp].PCP_quickFlags	; return ClipboardQuickNotifyFlags
	add	sp, size PasteParams		;de-alloc local var space
	ret
PasteText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PasteTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the text portion of the transfer item out the port

CALLED BY:	ScreenTransferCopy

PASS:		ds:*si	- screen instance data
		es	- dgroup
		bp 	- CommonTransferParams
		bx:ax	- (VM file):(VM block handle) of transfer data item

RETURN: 	none (the block handle is not freed)

DESTROYED:	ds, si, ax, bx, cx

PSEUDO CODE/STRATEGY:
	if in half duplex-mode then have to echo what we send out to the
	screen.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PasteTransferItem	proc	near	uses	dx, bp
	class	ScreenClass			;we're friends with ScreenClass

	.enter

	call	VMLock				;ax = segment, bp = handle
	push	bp
	push	es				;save dgroup
	mov	es, ax
	mov	di, es:[TTBH_text].high		;bx/di = huge array file/block
	pop	es				;restore dgroup
	clr	ax				;start from first element
	mov	dx, ax
pasteLoop:
	pushdw	dxax				;save dx:ax = position
	call	HugeArrayLock			;ds:si = text, ax = # chars
	mov	cx, ax				;cx = # chars
EC <	tst	cx							>
EC <	ERROR_Z	TERM_ERROR						>
	popdw	dxax				;restore dx:ax = position
	mov	bp, cx
	dec	bp				;bp = offset to last char
DBCS <	shl	bp, 1				;char offset -> byte offset>
SBCS <	cmp	{byte} ds:[si][bp], 0		;is this the end?	>
DBCS <	cmp	{wchar} ds:[si][bp], 0		;is this the end?	>
	pushf					;save flag
	jne	afterEndCheck			;no, continue
	dec	cx				;else, don't send null-term
afterEndCheck:
	segxchg	es, ds				;es:si = text (in huge array)
						;ds = dgroup
	call	BufferedSendBuffer		;send 'em out
	segxchg	es, ds				;es = dgroup
						;ds = huge array segment
	call	HugeArrayUnlock
	add	ax, cx				;update position with # chars
	adc	dx, 0				;	just sent
	popf					;restore end-flag
	jne	pasteLoop			;not the end, continue
	pop	bp
	call	VMUnlock

	.leave
	ret
PasteTransferItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the selected text into a transfer item

CALLED BY:	(INTERNAL) ScreenCopy, ScreenStartCopy
PASS:		ds:si	- screen instance data
		es	- dgroup

RETURN: 	ax	- VM block of transfer iterm (in clipboard's VM file)
		bx 	- VM file

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/13/90	Initial version
	ted	12/1/92		HAF_NO_ERR passed to MemAlloc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MakeTransferItem	proc	near
class	ScreenClass				;we're friends with ScreenClass

	sub     sp, size CommonTransferParams	;alloc space for local vars 
	mov     bp, sp
	call    ClipboardGetClipboardFile           ;bx = VM file
	mov     ss:[bp].CTP_vmFile, bx

	; get the selected text into a block
	call	CreateTransferItem		;cx = transfer format
	push	cx

	; allocate block for transfer structure

	mov	dx,ds:[LMBH_handle]
	mov	ax, size ClipboardItemHeader
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	mov	ds, ax				;ds = transfer item

	; set up header

	mov	ds:[CIH_owner].handle,dx
	mov	ds:[CIH_owner].chunk,si
	mov	ds:[CIH_flags],mask CIF_QUICK
	mov	ds:[CIH_sourceID].handle, 0	; no associated document
	mov	ds:[CIH_sourceID].chunk, 0
	mov	ds:[CIH_formatCount],1
	mov	ds:[CIH_formats][0].CIFI_format.CIFID_manufacturer, \
							MANUFACTURER_ID_GEOWORKS
	mov	ds:[CIH_formats][0].CIFI_format.CIFID_type,CIF_TEXT
	pop	ds:[CIH_formats][0].CIFI_vmChain.high
	mov	ds:[CIH_formats][0].CIFI_vmChain.low, 0

	; copy name

	segmov	es, ds, di
	mov	di, offset CIH_name		;es:di = dest 
	push	bx				; save transfer block handle
	GetResourceHandleNS	textTransferItemString, bx
	call	MemLock		; ax = string segment
	mov	ds, ax
	mov	si, offset textTransferItemString
	mov	si, ds:[si]			; ds:si = string
	mov	cx, CLIPBOARD_ITEM_NAME_LENGTH+1
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>
	call	MemUnlock			; unlock string block
	pop	bx				; bx = transfer block

	call	MemUnlock			; unlock tranfser header

	mov	cx, bx				;cx = memory handle
	mov	bx, ss:[bp].CTP_vmFile		;bx = VM file
	clr	ax				;allocate new VM block
	call	VMAttach			;ax = VM block
	add	sp, size CommonTransferParams	;free up local stack 
	.leave
	ret
MakeTransferItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create a transfer item 

CALLED BY:	MakeTransferItem

PASS:		ds:si	- screen instance data
		es	- dgroup
		ss:bp	- CommonTransferParams
				CTP_vmFile - file to create transfer item in

RETURN: 	cx - VM block of transfer format


DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateTransferItem	proc near	uses	si, bp
class	ScreenClass				;we're friends with ScreenClass

	.enter

	;
	; create text object to do transfer stuff for us
	;
	push	si				;save instance
	mov	al, 0				;no styles, etc
	mov	ah, 0				;no regions
	mov	bx, ss:[bp].CTP_vmFile		;create in this VM file
	push	ds:[LMBH_handle]		;save object block handle
	call	TextAllocClipboardObject	;^lbx:si = xfer text object
						; ds may be trashed
	mov	cx, bx
	mov	dx, si
	pop	bx
	call	MemDerefDS			;ds<-sptr of screen obj	
	;
	; copy text from our screen buffers into the text object
	;
	pop	si				;*ds:si = screen object
	mov	si, ds:[si]
	mov	bx, ds:[si][SI_screenHandle]
	call	MemLock
	mov	ds:[si][SI_screenBuf], ax
	call	CopySelectText
	mov	bx, ds:[si][SI_screenHandle]	;unlock screen buffer
	call	MemUnlock	
EC <	call	NullScreenBuf			; stuff bogus segment	>
	;
	; tell the text object that we are done with it
	;
	mov	bx, cx				;^lbx:si = xfer text object
	mov	si, dx
	mov	ax, TCO_RETURN_TRANSFER_FORMAT	;return data only
	call	TextFinishWithClipboardObject	;ax = text transfer format
	mov     cx, ax				;return cx = block handle
exit:
	.leave
	ret
CreateTransferItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopySelectText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy the selected text into a buffer

CALLED BY:	(INTERNAL) CreateTransferItem
PASS:		ds:si	- screen instance data
		cx:dx	- xfer text object
		SI_screenBuf	- locked segment

RETURN: 	
	
DESTROYED:	

PSEUDO CODE/STRATEGY:
		For all lines but the last
			Find end of line by eliminating trailing 
				white space	(spaces, tabs)
		copy the line data into buffer and append a CR.

		For last line
			copy the data into the buffer
			append a CR only if the complete line is selected

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopySelectText	proc	near	uses	cx, dx, bp
	.enter
	mov	ss:[vmSegment], cx		;save ptr to place to copy
	mov	ss:[vmOffset], dx		;  selected text to.

	mov	dx, ss:[selStartLine]		;if startLine == endLine
	cmp	dx, ss:[selEndLine]		;then single line selected
	je	singleLine
doFirst:
	mov	dx, ss:[selStartLine]		;dx - start line
	call	GetSelectLine			;bx->start of line
	mov	bp, bx				;copy ptr to start of line
	mov	cx, MAX_LINE_CHARS
SBCS <	add	bp, MAX_LINE_CHARS-1		;es:bp->end of line	>
DBCS <	add	bp, (MAX_LINE_CHARS-1)*(size wchar)			>
	add	bx, ss:[selStartCol]		;es:bx->line of text to copy
DBCS <	add	bx, ss:[selStartCol]		;char offset -> byte offset>
	sub	cx, ss:[selStartCol]		;get #chars to dork
	call	SkipTrailWhiteSpace
SBCS <	mov	al, CHAR_CR			;append text with a CR	>
DBCS <	mov	ax, CHAR_CR			;append text with a CR	>
	call	CopyText
doBody:
	inc	dx				;done with line
	cmp	dx, ss:[selEndLine]		;
	je	doLast				;
	call	GetSelectLine			;
	mov	bp, bx				;
	mov	cx, MAX_LINE_CHARS		;
SBCS <	add	bp, MAX_LINE_CHARS-1		;			>
DBCS <	add	bp, (MAX_LINE_CHARS-1)*(size wchar)			>
	call	SkipTrailWhiteSpace		;
SBCS <	mov	al, CHAR_CR			;append text with a CR	>
DBCS <	mov	ax, CHAR_CR			;append text with a CR	>
	call	CopyText			;
	jmp	short doBody			;
doLast:
	call	GetSelectLine			;
	mov	bp, bx				;es:bx->start of line
	mov	cx, ss:[selEndCol]		;pass line length
	jcxz	exit				; 
	add	bp, cx				;
DBCS <	add	bp, cx							>
	dec	bp				;es:bp->end of line
DBCS <	dec	bp							>
SBCS <	clr	al				;assume don't append text>
DBCS <	clr	ax				;assume don't append text>
	cmp	cx, MAX_LINE_CHARS		;but if full line then 
	jne	50$				;append with CR
SBCS <	mov	al, CHAR_CR						>
DBCS <	mov	ax, CHAR_CR						>
50$:
	call	SkipTrailWhiteSpace		;
	call	CopyText			;
	jmp	short exit			;

singleLine:
	call	GetSelectLine
	mov	bp, bx
	add	bx, ss:[selStartCol]		;es:bx->start of string
DBCS <	add	bx, ss:[selStartCol]		;char offset -> byte offset>
	mov	cx, ss:[selEndCol]	
	add	bp, cx				;
DBCS <	add	bp, cx				;char offset -> byte offset>
	dec	bp				;es:bp->end of string
DBCS <	dec	bp							>
	sub	cx, ss:[selStartCol]		;cx - string length  
SBCS <	clr	al				;assume no char to append>
DBCS <	clr	ax				;assume no char to append>
	cmp	cx, MAX_LINE_CHARS		;if full line
	jne	70$				;
SBCS <	mov	al, CHAR_CR			;then append a CR	>
DBCS <	mov	ax, CHAR_CR			;then append a CR	>
70$:
	call	SkipTrailWhiteSpace
	call	CopyText		
exit:
	call	FreeSelectLine
	.leave
	ret
CopySelectText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipTrailWhiteSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	delete trailing white space

CALLED BY:	TextAppendToTransferItem

PASS:		es:bp	- ptr to end of line
		cx	- string length

RETURN: 	es:bp	- point to last non-whitespace char in line
		cx	- #chars in the line

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SkipTrailWhiteSpace	proc
	push	ax
	jcxz	exit
checkMore:
if DBCS_PCGEOS
	mov	ax, es:[bp]
	call	LocalGetWordPartType
	cmp	ax, WPT_SPACE
	jne	exit
else
	mov	ah, es:[bp]
	cmp	ah, CHAR_SPACE
	je	skip
	cmp	ah, CHAR_TAB
	jne	exit
endif
skip:
	dec	bp
DBCS <	dec	bp							>
	loop	checkMore
exit:
	pop	ax
	ret
SkipTrailWhiteSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy text into vm segment

CALLED BY:	(INTERNAL) CopySelectText
PASS:		ds:si	- screen instance data
		es:bx	- ptr to line to copy
		cx	- string length
		ss	- dgroup
		al	- char to append to text
		   	  0 : if no char to append
RETURN: 	
	
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CopyText 	proc	near	uses	bx, cx, dx, si, bp
	.enter
	jcxz	exit				;no chars
	push	ax				;save char to append
	mov	dx, es				;dx:bp = text to copy
	mov	bp, bx
	mov	bx, ss:[vmSegment]		;^lbx:si-> xfer text obj
	mov	si, ss:[vmOffset]
	mov	ax, MSG_VIS_TEXT_APPEND
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax				;restore char to append
SBCS <	tst	al				;check if char to append>
DBCS <	tst	ax				;check if char to append>
	jz	exit
	push	ax
	mov	dx, ss				; append 1 char from stack
	mov	bp, sp
	mov	cx, 1
	mov	ax, MSG_VIS_TEXT_APPEND
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax
exit:
	.leave
	ret
CopyText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSelectTopBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ensures that selectStartLine is above selectEndLine 

CALLED BY:	GetSelectSize

PASS:		ds:si	- screen instance data
		ss	- dgroup
RETURN: 	
	
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckSelectTopBottom	proc	near

	mov	dx, ss:[selStartLine]		;figure out top and bottom
	cmp	dx, ss:[selEndLine]		;lines of selected region
	je	checkCol			; same line, adjust start/end
						;	column
	jb	exit				; start line is above end line,
						;	leave start/end columns
growUp:
	mov	cx, ss:[selEndLine]
	mov	ss:[selStartLine], cx
	mov	ss:[selEndLine], dx

	mov	dx, ss:[selStartCol]
	mov	cx, ss:[selEndCol]
	mov	ss:[selStartCol], cx
	mov	ss:[selEndCol], dx
	jmp	short exit
checkCol:
	mov	dx, ss:[selStartCol]
	cmp	dx, ss:[selEndCol]
	jbe	exit
	mov	cx, ss:[selEndCol]
	mov	ss:[selEndCol], dx
	mov	ss:[selStartCol], cx
exit:	
	ret
CheckSelectTopBottom	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get number chars in selected area

CALLED BY:	(INTERNAL)
PASS:		ds:si	- screen instance data
		es	- dgroup
		ss:bp	- CommonTransferParams
		ax:bx	- VM block
		dx	- VM file handle

RETURN: 	ds:si	- screen instance data
		cx


DESTROYED:

PSEUDO CODE/STRATEGY:
	Want to find out how many actual chars are here so know how big
	to make the LMem block.  Don't want to count trailing white space.
	need to add a one byte for CR at the end of each line 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSelectSize	proc	near
	push	bp, ax, bx, dx
	call	CheckSelectTopBottom		;check select region pointers	
	clr	ss:[selectSize]			;reset counter

	mov	dx, ss:[selStartLine]		;if startLine == endLine
	cmp	dx, ss:[selEndLine]		;then single line selected
	je	singleLine
doFirst:
	call	GetSelectLine
	mov	bp, bx
	add	bx, ss:[selStartCol]		;es:bx->start of text
DBCS <	add	bx, ss:[selStartCol]		;char offset -> byte offset>
	mov	cx, MAX_LINE_CHARS
SBCS <	add	bp, MAX_LINE_CHARS-1		;es:bp->end of line	>
DBCS <	add	bp, (MAX_LINE_CHARS-1)*(size wchar)			>
	sub	cx, ss:[selStartCol]		;get length of selected text
	call	SkipTrailWhiteSpace		;get length of string
	inc	cx				;add one byte for CR
	add	ss:[selectSize], cx
doBody:
	inc	dx
	cmp	dx, ss:[selEndLine]
	je	doLast
	call	GetSelectLine			;get ptr to line data
	mov	bp, bx
	mov	cx, MAX_LINE_CHARS		;
SBCS <	add	bp, MAX_LINE_CHARS-1		;offset to end of line	>
DBCS <	add	bp, (MAX_LINE_CHARS-1)*(size wchar)			>
	call	SkipTrailWhiteSpace
	inc	cx				;add one byte for CR
	add	ss:[selectSize], cx
	jmp	short doBody
doLast:
	mov	cx, ss:[selEndCol]		;get #chars in last line
	cmp	ss:[selEndCol], MAX_LINE_CHARS	;if full line selected
	jne	noCR				;then 
	inc	ss:[selectSize]			;add byte for CR	
noCR:
	call	GetSelectLine
	add	bx, ss:[selEndCol]		;
DBCS <	add	bx, ss:[selEndCol]		;char offset -> byte offset>
	dec	bx				;offset to end of line
DBCS <	dec	bx							>
	mov	bp, bx				;es:bp->end of line
	call	SkipTrailWhiteSpace
	add	ss:[selectSize], cx
	jmp	short done
singleLine:
	call	GetSelectLine			;
	add	bx, ss:[selEndCol]		;
DBCS <	add	bx, ss:[selEndCol]		;char offset -> byte offset>
	dec	bx				;es:bx->end of string
DBCS <	dec	bx							>
	mov	cx, ss:[selEndCol]		;	
	sub	cx, ss:[selStartCol]		;cx - string length  
	cmp	cx, MAX_LINE_CHARS		;if whole string selected
	jb	70$				;then
	inc	ss:[selectSize]			;  add space for CR 
70$:
	mov	bp, bx				;es:bp->end of string
	call	SkipTrailWhiteSpace		;
	add	ss:[selectSize], cx
done:
	mov	cx, ss:[selectSize]		;pass size of selected text
	call	FreeSelectLine
	pop	bp, ax, bx, dx
	ret
GetSelectSize	endp

if	not _CHAR_SET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrollSelectRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	adjust selected region when have to scroll the document

CALLED BY:	ScrollSaveLine

PASS:		ds:si	- screen instance data
		es	- dgroup
		ax	- #lines to scroll select region by	
RETURN: 	

DESTROYED:

PSEUDO CODE/STRATEGY:
	Assume that this code is called once for every line scrolled off
	the screen.  Now when the document lines shift then we have to
	shift the pointers to the selected area.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrollSelectRegion	proc	near	;adjust selected region
	tst	ss:[textSelected]
	jz	exit
	tst	ss:[selStartLine]	;if scrolling selected region off	
	jz	unselect		;then unselect it
	sub	ss:[selStartLine], ax
	sub	ss:[selEndLine], ax
	jmp	short exit
unselect:
	call	UnSelectArea	
exit:
	ret
ScrollSelectRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSelectRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	adjust selected region when have to scroll the document

CALLED BY:	(INTERNAL)
PASS:		ds:si	- screen instance data
		es	- dgroup

RETURN: 	

DESTROYED:

PSEUDO CODE/STRATEGY:
	If cursor ever gets moved while its above the selected text
	or if the cursor ever enter a line containing selected text
	then the selected data becomes unselected.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckSelectRegion	proc	near		;adjust selected region
	class	ScreenClass

	tst	ss:[textSelected]		
	jz	exit
	mov	ax, ds:[si][SI_curLine]
	add	ax, ds:[si][SI_winTopLine]	;get document line position
	cmp	ax, ss:[selEndLine]		;if cursor above or in
	ja	exit				;selected region 
	call	UnSelectArea			;then unselect area
exit:
	ret
CheckSelectRegion	endp
endif	; if _CHAR_SET
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	adjust selected region when have to scroll the document

CALLED BY:	ScrollSaveLine

PASS:		ds:si	- screen instance data
		ss	- dgroup
		cx	- new window width size
		dx	- new window height size

RETURN: 	

DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetWindow	proc	near				;
	push	cx, dx

	sub	sp, size SetSizeArgs
	mov	bp, sp
	mov	ss:[bp].SSA_updateMode, VUM_NOW
	mov	ss:[bp].SSA_width, cx
	mov	ss:[bp].SSA_height, dx
	clr	ss:[bp].SSA_count
	mov	ax, MSG_GEN_SET_MAXIMUM_SIZE		;restrict window to this
	GetResourceHandleNS	TermView, bx
	mov	si, offset TermView
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	mov	dx, size SetSizeArgs
	call	ObjMessage
	add	sp, size SetSizeArgs

if 0
	pop	cx, dx
	mov	ax, MSG_SET_DOC_SIZE
	CallScreenView
endif

	pop	cx, dx

	sub	sp, size SetSizeArgs
	mov	bp, sp
	mov	ss:[bp].SSA_updateMode, VUM_NOW
	mov	ss:[bp].SSA_width, cx
	mov	ss:[bp].SSA_height, dx
	clr	ss:[bp].SSA_count
	GetResourceHandleNS	TermView, bx
	mov	si, offset TermView
	mov	dx, size SetSizeArgs
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	mov     ax, MSG_GEN_SET_INITIAL_SIZE		;  
	call	ObjMessage
	add	sp, size SetSizeArgs
	
	mov     dl, VUM_NOW
	mov     ax, MSG_GEN_RESET_TO_INITIAL_SIZE
	CallPrimary
if 0
	pop	si					;ds:si-> screen obj
	push	si
	mov	cx, ds:[si][SI_docWidth]		;restore window max
	mov	dx, ds:[si][SI_docHeight]
	mov	ax, MSG_SET_DOC_SIZE
	CallScreenView
	pop	si
	mov	cx, ds:[si][SI_charWidth]		;restore window min
	mov	dx, ds:[si][SI_lineHeight]		;
	sub	sp, size SetSizeArgs
	mov	bp, sp
	mov	ss:[bp].SSA_updateMode, VUM_NOW
	mov	ss:[bp].SSA_width, cx
	mov	ss:[bp].SSA_height, dx
	clr	ss:[bp].SSA_count
	mov	ax, MSG_GEN_SET_MINIMUM_SIZE			;
	GetResourceHandleNS	TermView, bx
	mov	dx, size SetSizeArgs
	mov	si, offset TermView
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size SetSizeArgs
endif
	ret
ResetWindow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckWinWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the view width is a multiple of the character width

CALLED BY:	(INTERNAL)
PASS:		ds:si	- screen instance data
		ss	- dgroup
		cx	- new window width size
		dx	- new window height size

RETURN: 	bp (low byte) - #lines used

DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckWinWidth	proc	near			;
	class	ScreenClass

	mov	ax, cx				;is screen width
	mov	bx, ds:[si][SI_charWidth]	;a multiple
	div	bl				;of char width	?	
	mov	bp, ax				;save #cols used
	tst	ah
	je	exit				;yes, no adjustment needed
	mov	al, ah				;else shrink screen width
	clr	ah				;
	sub	bx, ax				;get amount to bump
	add	cx, bx				;increase screen width
	inc	bp				;inc #cols used
exit:
	ret
CheckWinWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckWinHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the view height is a multiple of the character height

CALLED BY:	ScreenSubviewChange

PASS:		ds:si	- screen instance data
		ss	- dgroup
		cx	- new window width size
		dx	- new window height size

RETURN: 	di (low byte) - #lines used

DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckWinHeight	proc	near			;
	class	ScreenClass

if PZ_PCGEOS
	; Don't need to restrict maximum because it never changes.
else	
	cmp	ds:[si][SI_lineHeight], BISON_9_HEIGHT	
	je	5$				;
	cmp	dx, MAX_BISON_12_WIN		;check bison 12 window size
	jb	10$
	mov	dx, MAX_BISON_12_WIN
	jmp	short 10$
5$:
	cmp	dx, MAX_BISON_9_WIN		;check bison 9 window size
	jb	10$
	mov	dx, MAX_BISON_9_WIN
10$:
endif	
	mov	ax, dx				;is screen width
	mov	bx, ds:[si][SI_lineHeight]	;a multiple
	div	bl				;of char height	?	
	mov	di, ax				;save #lines used		
	tst	ah
	je	exit				;yes no adjustment needed
	mov	al, ah				;else bump up screen height
	clr	ah				;
	sub	bx, ax				;get amount to bump
	add	dx, bx				;increase screen height
	inc	di				;inc #lines used
exit:
	ret
CheckWinHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateWinDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set text in window range objects to reflect window size 

CALLED BY:	(INTERNAL)
PASS:		ds:si	- screen instance data
		ss, es	- dgroup
		cx	- #cols to set
		dx	- #lines to set

RETURN: 	

DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateWinDisplay	proc	near		;
	push	si
	push	dx
	mov	dx, cx
	clr	cx
	mov	ax, MSG_GEN_VALUE_SET_VALUE	;set col # (dx.cx)
	clr	bp
	mov	si, offset WinColsRange
	mov	bx, ss:[interfaceHandle]
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	dx				;set line # (dx.cx)
	clr	cx
	mov	ax, MSG_GEN_VALUE_SET_VALUE	
	clr	bp
	mov	si, offset WinLinesRange
	mov	bx, ss:[interfaceHandle]
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
exit:
	pop	si
	ret
UpdateWinDisplay	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLineLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get line length

CALLED BY:	WriteToFileCache, LinesToDisk

PASS:		ds:bp	- start of line 

RETURN: 	cx	- #chars in the line

DESTROYED:

PSEUDO CODE/STRATEGY:
	Hard code that max line length is MAX_LINE_CHARS

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/20/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetLineLength	proc	near
	mov	cx, MAX_LINE_CHARS		;get #chars to copy	
	add	bp, cx				;ds:bp->one past end of line
DBCS <	add	bp, cx				;char offset -> byte offset>
scanTop:				
	dec	bp				;find end of line
DBCS <	dec	bp							>
if DBCS_PCGEOS
	push	ax
	mov	ax, {wchar} ds:[bp]
	call	LocalGetWordPartType
	cmp	ax, WPT_SPACE
	pop	ax
	jne	exit
else
	cmp	{byte} ds:[bp], CHAR_SPACE	;ignore spaces
	je	skipChar
	cmp	{byte} ds:[bp], CHAR_NULL	;ignore nulls
	je	skipChar
	cmp	{byte} ds:[bp], CHAR_CR		;ignore CR
	je	skipChar
	cmp	{byte} ds:[bp], CHAR_LF		;ignore LFs
	je	skipChar
	jmp	short exit
endif
skipChar:
	loop	scanTop
exit:
	ret
GetLineLength	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckViewSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get line length

CALLED BY:	(INTERNAL)
PASS:		ds:si	- screen instance data
		cx	- width of view
		dx	- height of view

RETURN: 	

DESTROYED:

PSEUDO CODE/STRATEGY:
	Hard code that max line length is MAX_LINE_CHARS

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/20/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckViewSize	proc	near
	class	ScreenClass
	
	cmp	cx, ds:[si][SI_winWidth]
	jne	checkWidth
	cmp	dx, ds:[si][SI_winHeight]
	je	exit
checkWidth:
	push	cx, dx				;save new window size
	call	CheckWinWidth
checkHeight:
	call	CheckWinHeight
	mov	ds:[si][SI_winWidth], cx	
	mov	ds:[si][SI_winHeight], dx	
	push	cx, dx				;save pixel for line and height
	mov	cx, bp				;update #cols and lines for
	mov	dx, di				;  the window
	clr	ch				;
	clr	dh				;
	mov	ds:[si][SI_maxCols], cl 	;update #cols
	mov	ds:[si][SI_maxLines], dl	;update #lines
	mov	{byte} ds:[si][SI_scrollRegBot], dl	;update bottom off
	dec	ds:[si][SI_scrollRegBot]
	call	UpdateWinDisplay		;
	pop	cx, dx
	pop	ax, bx
	cmp	cx, ax
	jne	resetWin
	cmp	dx, bx
	je	exit	
resetWin:
	call	ResetWindow
exit:
	ret
CheckViewSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcTextLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check how many lines of text can be displayed on the screen

CALLED BY:	SetFontNewScreen

PASS:		ds:si	- screen instance data

RETURN: 	cl	- max lines that can be	displayed

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	04/10/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcTextLines	proc	near
	class	ScreenClass

if PZ_PCGEOS
	mov	cl, MAX_LINES			; maximum never changes
else
	push	si
	mov	ax, ss:[fieldWinHeight]		;get size of our screen
	mov	cx, ds:[si][SI_lineHeight]	;  and the size of our text
	div	cl				;
	cmp	al, MAX_LINES			;set the max # of lines
	jbe	setMax				;
	mov	al, MAX_LINES
setMax:
	mov	cl, al				;pass new max #of text lines
	push	cx				;save max lines
	mov	dx, cx				;dx.cx = lines
	clr	cx
	mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
	mov	si, offset WinLinesRange
	mov	bx, ss:[interfaceHandle]
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx
	pop	si
endif	; if !_BULLET or PZ_PCGEOS
	ret
CalcTextLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreScreenState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check state of screen UI objects

CALLED BY:	(INTERNAL) ScreenDraw, ScreenInitialize
PASS:		

RETURN: 	

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	04/25/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RestoreScreenState	proc	near
	call	RestoreFontSize
	call	RestoreAutoLinefeed
	call	RestoreAutoWrap
	ret
RestoreScreenState	endp

ResetView	proc	near
	uses	si, di
	.enter
	mov	dx, size PointDWord
	sub	sp, dx
	mov	bp, sp
	clr     ax                              
	mov	ss:[bp].PD_x.low, ax		;zero x origin
	mov	ss:[bp].PD_x.high, ax
	mov	ss:[bp].PD_y.low, ax		;zero y origin 
	mov	ss:[bp].PD_y.high, ax
	GetResourceHandleNS	TermView, bx
	mov	si, offset TermView
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	mov	ax, MSG_GEN_VIEW_SET_ORIGIN
	call	ObjMessage
	add	sp, size PointDWord
	.leave
	ret
ResetView	endp
;
; Returns 	ds:si	- object ptr
;		di	- gState ptr
;
RestoreFontSize		proc	near
	push	si, di
	GetResourceHandleNS	FontList, bx
	mov	si, offset FontList		;if 'big font' not set
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; ax = selection
	cmp	ax, 12
	pop	si, di
	jne	bison9
	call	setBison12 
	jmp	short exit
bison9:
	call	setBison9
exit:
	ret
RestoreFontSize		endp

RestoreAutoWrap		proc	near
	class	ScreenClass
	push	si, di				;save screen obj and gState
	GetResourceHandleNS	VideoList, bx
	mov	si, offset VideoList
	mov	cx, mask LAW_WRAP
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; carry set if selected
	pop	si, di
	jnc	exit
        mov     ds:[si][SI_autoWrap], TRUE
exit:
	ret
RestoreAutoWrap		endp

RestoreAutoLinefeed	proc	near
	class	ScreenClass
	push	si, di
	GetResourceHandleNS	VideoList, bx
	mov	si, offset VideoList
	mov	cx, mask LAW_LINEFEED
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; carry set if selected
	pop	si, di
	jnc	exit
        mov     ds:[si][SI_autoLinefeed], TRUE
exit:
	ret
RestoreAutoLinefeed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCursorInSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if cursor in selected region

CALLED BY:	UnHighlightArea

PASS:		ss	- dgroup	
		ds:si	- screen obj

RETURN: 	C	- set if cursor in select region	

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/08/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckCursorInSelect	proc	near
	class	ScreenClass

	uses	cx, dx
	.enter
	tst	ss:[textSelected]		;check if text selected
	jz	notCursor			;
	mov	dx, ds:[si][SI_winTopLine]	;calculate document line
	add	dx, ds:[si][SI_curLine]		;  of the cursor
	mov	cx, ds:[si][SI_curChar]		; CX = column; DX = line
	call	CheckCoordInSelect
	jmp	short exit
notCursor:
	clc
exit:
	.leave
	ret
CheckCursorInSelect	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCoordInSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if passed coordinates are in the selected region

CALLED BY:	(INTERNAL) CheckCursorInSelect, ScreenStartCopy
PASS:		ss	- dgroup	
		cx, dx	- coordinates to check against selected region	

RETURN: 	C	- set if cursor in select region	

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/08/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckCoordInSelect	proc	near
	mov	ax, ss:[selStartLine]		;is this multi line	
	cmp	ax, ss:[selEndLine]		;	selected region
	je	oneLine				;
	cmp	dx, ax				;is cursor above region?
	jb	notCursor			;yep	
	ja	checkBot			;nope check region bottom
onTop:
	mov	ax, ss:[selStartCol]		;cursor is on top line
	cmp	ax, cx				;is cursor before region
	ja	notCursor			;	start
	jmp	inCursor

checkBot:
	mov	ax, ss:[selEndLine]		;
	cmp	dx, ax				;is cursor past region
	ja	notCursor			;yep
	jb	inCursor			;cursor below top and above bot
onBot:
	mov	ax, ss:[selEndCol]		;cursor on bottom line of
	cmp	ax, cx				;  select region
	jae	inCursor			;
	jmp	notCursor			;

oneLine:
	cmp	dx, ax				;is cursor on selected line?
	jne	notCursor
	cmp	cx, ss:[selStartCol]		;cursor left of region?
	jb	notCursor
	cmp	cx, ss:[selEndCol]		;cursor right of region?
	jae	notCursor			;
						;fall through	
inCursor:					;cursor in region
	stc	
	jmp	short exit

notCursor:					;cursor not in region
	clc
exit:
	.leave
	ret
CheckCoordInSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCursorErased
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if cursor erased when selecting region

CALLED BY:	ScreenDragSelect

PASS:		ss	- dgroup	
		ds:si	- screen obj

RETURN: 	

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
	okay the case we're looking for is when the cursor was in the 
	selected regin and now is in it no longer.  When this happens
	the cursor has been erased and we want to flag that accordingly

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckCursorErased	proc	near
	class	ScreenClass

	tst	ss:[textSelected]		;if not text selected then
	jz	exit				;  cursor can't be dorked
	call	IsCursorInDragSelect
	jnc	notIn
						;cursor in region
	tst	ss:[curInSelect]		;exit, if cursor was previously
	jnz	exit 				;  in select region
	mov	ss:[curInSelect], TRUE		;
	mov	ds:[si][SI_cursorDrawn], TRUE	;
	jmp	short exit
notIn:						;cursor not in region
						;was cursor previously 
	tst	ss:[curInSelect]		;  in region?	
	jz	exit				;nope, so exit			
	mov	ds:[si][SI_cursorDrawn], FALSE	;yep, so cursor got erased
	mov	ss:[curInSelect], FALSE		;  reset cursor flag
exit:
	ret
CheckCursorErased	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsCursorInDragSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if cursor in drag select region

CALLED BY:	(INTERNAL) CheckCursorErased
PASS:		ss	- dgroup	
		ds:si	- screen obj

RETURN: 	C	- set if cursor in drag select

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine differs from 'CheckCursorInSelect' because this routine
	can't assume that selStartLine is above selEndLine.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IsCursorInDragSelect	proc	near
	push	ss:[selStartCol]
	push	ss:[selEndCol]
	push	ss:[selStartLine]
	push	ss:[selEndLine]
	call	CheckSelectTopBottom
	call	CheckCursorInSelect
	pop	ss:[selEndLine]
	pop	ss:[selStartLine]
	pop	ss:[selEndCol]
	pop	ss:[selStartCol]
exit:
	ret
IsCursorInDragSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartCapture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start capturing stuff 

CALLED BY:	ScreenRecordOn

PASS:		ss	- dgroup	
		ds:si	- screen obj
		[SI_screenBuf]	- unlocked segment
		bx	- handle of file to write to

RETURN: 	ds	- dgroup	

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/19/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartCapture	proc	near
	class	ScreenClass

	push	ds,si				;disable the capture ox
	mov	ds:[si][SI_capHandle], bx	;save file handle
      	mov     bx, ds:[si][SI_screenHandle]	;lock screen buffer
	call    MemLock
	mov     ds:[si][SI_screenBuf], ax

	segmov	ds, es, ax			;ds -> dgroup
	mov     ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	GetResourceHandleNS	CaptureBox, bx
	mov     si, offset CaptureBox
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	ds:[capScroll], FALSE		;initialize flags	
	mov	ds:[capScreen], FALSE
	GetResourceHandleNS	SaveAsOptions, bx
	mov	si, offset SaveAsOptions
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;ax = option
	cmp	ax, CSO_BOTH
	jne	10$
	mov	ds:[capScroll], TRUE
	mov	ds:[capScreen], TRUE
	jmp	short doCap
10$:
 	cmp    	ax, CSO_SCROLL_BACK
	jne     20$                              ;yes
	mov	ds:[capScroll], TRUE
	jmp	short doCap
20$:
	mov	ds:[capScreen], TRUE
doCap:
	pop	ds, si
	tst	es:[capScroll]
	jz	doScreen
	mov	bx, ds:[si][SI_capHandle]
	mov     ah,{byte}ds:[si][SI_scrollTop]  ;set first line to write out
	mov     al,{byte}ds:[si][SI_scrollLines];set #lines to print
	call	ScrollLinesToDisk
doScreen:
	tst	es:[capScreen]
	jz	done
	call	ScreenLinesToDisk
done:
	call	CaptureDone
exit:
      	mov     bx, ds:[si][SI_screenHandle]	;lock screen buffer
	call    MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>
	ret
StartCapture	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenLinesToDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write screen buffer to disk

CALLED BY:	(INTERNAL)
PASS:		ss		- dgroup	
		ds:si		- screen obj
		[SI_screenBuf]	- locked segment

RETURN: 	

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/20/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenLinesToDisk	proc	near
	class	ScreenClass

	push	ds
	mov	bx, ds:[si][SI_capHandle]	;pass file handle
	mov     ss:[saveScroll], FALSE          ;flag screen buffer being saved
	clr     ah                              ;set first line to write
	mov     al, MAX_LINES                   ;set last line
EC <	call	CheckScreenBuf						>
	mov     ds, ds:[si][SI_screenBuf]
	clr     dx                              ;ds:dx->first line to save
	call    LinesToDisk                     ;write out screen lines to dis
	pop	ds	
	ret
ScreenLinesToDisk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CaptureDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Screen or Scroll capture done

CALLED BY:	StartCapture

PASS:		ss	- dgroup	
		ds:si	- screen obj

RETURN: 	

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/20/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CaptureDone	proc	near
		class	ScreenClass
	;
	; Unregister document with IACP.  Do it first because FileClose
	; frees file handle.
	;
		mov	bx, ds:[si][SI_capHandle]
		call	UnregisterDocumentFar
	;
	; Close the file.
	;
		mov	al, FILE_NO_ERRORS 
		call	FileClose
		mov	ds:[si][SI_capHandle], BOGUS_VAL
		call	SendFileCloseFileChange

		ret
CaptureDone	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc new size for window based on new font

CALLED BY:	(INTERNAL) SetFontNewScreen
PASS:		ss	- dgroup	
		ds:si	- screen obj

RETURN: 	cx, dx	- what the window size should be
		bh	- #cols to display	
		bl	- #lines to display

DESTROYED:	

PSEUDO CODE/STRATEGY:
	get current #lines and #cols and attempt to size window to those
	coordinates

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/23/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RecalcSize	proc	near
if PZ_PCGEOS
	call	GetDefaultScreenHeight
else	
	call	GetScreenHeight
endif	
	
	push	ax				;save new screenHeight
	push	cx				; save #lines to display (CL)

if PZ_PCGEOS
	call	GetDefaultScreenWidth
else	
	call	GetScreenWidth
endif	
	
	pop	bx				; restore #lines (BL)
	mov	bh, cl				;save #cols to display
	mov	cx, ax				;save pixel width
	pop	dx				;retrieve pixel height
	ret
RecalcSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetScreenHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc new size for window based on new font

CALLED BY:	SetFontNewScreen

PASS:		ss	- dgroup	
		ds:si	- screen obj

RETURN: 	ax	- what screen width should be
		cl	- #lines to display

DESTROYED:	

PSEUDO CODE/STRATEGY:
	get #cols displayed and calculate window size 
	based on font size

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	05/23/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetScreenHeight	proc	near
	class	ScreenClass

	push	si
	mov     ax, MSG_GEN_VALUE_GET_VALUE
	mov     si, offset WinLinesRange
	mov     bx, ss:[interfaceHandle]
	mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage                      ;get current # cols (dx.cx)
	mov	cl, dl				;cl = # cols
	pop     si                              ;restore ptr to instance data
	mov     ax, ds:[si][SI_lineHeight]      ;convert it to window height
	mul     dl                              ;
	ret
GetScreenHeight	endp

GetScreenWidth	proc	near
	class	ScreenClass

	push	si				 ;save ptr to instance data
	mov     ax, MSG_GEN_VALUE_GET_VALUE
	mov     si, offset WinColsRange
	mov     bx, ss:[interfaceHandle]
	mov     di, mask MF_CALL or mask MF_FIXUP_DS
	call    ObjMessage                      ;get current # cols (dx.cx)
	mov	cl, dl				;cl = # cols
	pop     si                              ;restore ptr to instance data
	mov     ax, ds:[si][SI_charWidth]       ;convert that to window width
	mul     dl
	ret
GetScreenWidth	endp

if PZ_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDefaultScreenHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc default height for window based on new font.

CALLED BY:	(INTERNAL)
PASS:		ss	-> dgroup
		ds:si	-> screen obj

RETURN:		ax	-> what screen height should be
		cl	-> # lines to display

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	get #cols to display based on font and calculate window size
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/22/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDefaultScreenHeight	proc	near
	class	ScreenClass
	uses	dx
	.enter
	;	
	; Want screen to be 80x24 if small font, else 80x20 if large font
	; when fonts are changed.  
	;
	mov	dl, MAX_LINES			; assume small font
	mov	ax, ds:[si].[SI_lineHeight]
if not PZ_PCGEOS
	cmp	ax, BISON_9_HEIGHT
	je	haveHeight
	mov	dl, NUM_LINES_BISON_12		; it's large font
haveHeight:
endif
	mov	cl, dl				; set up return value
	mul	dl
	.leave
	ret
GetDefaultScreenHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDefaultScreenWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc default width for window.

CALLED BY:	RecalcSize

PASS:		ss	-> dgroup
		ds:si	-> screen obj

RETURN:		ax 	<- what screen width should be
		cl	<- # lines to display

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Default width is always MAX_LINE_CHARS regardless of font.
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/22/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDefaultScreenWidth	proc	near
	class	ScreenClass
	uses	dx
	.enter
	;
	; Want screen to be 80x24 if small font, else 80x20 when fonts
	; are changed.  --jwu 9/21/93
	;
	mov	dl, INIT_LINE_CHARS
	mov	cl, dl				; set up return value
	mov     ax, ds:[si][SI_charWidth]       ;convert that to window width
	mul     dl	
	.leave
	ret
GetDefaultScreenWidth	endp

endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableEditMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable the edit menu caus focus back in screen object

CALLED BY:	(INTERNAL)
PASS:		ss	- dgroup	

RETURN: 	
	
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	06/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EnableEditMenu	proc	near
	mov     ax, MSG_GEN_SET_ENABLED      ;enable file transfer triggers
	call    DorkEditMenu
	ret
EnableEditMenu	endp

DisableEditMenu	proc	near
	mov     ax, MSG_GEN_SET_NOT_ENABLED	;enable file transfer triggers
	call    DorkEditMenu
	ret
DisableEditMenu	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DorkEditMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send each entry in the edit menu a method

CALLED BY:	ScreenGainFocusExcl

PASS:		ss	- dgroup	
		ax	- method to send

RETURN: 	
	
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	06/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; must be in MenuInteface
;
EditMenuTable		label   word
	dw      offset  MenuInterface:CopySelect     		;Edit Menu/Copy
	dw      offset  MenuInterface:PasteSelect         	;Edit Menu/Paste
EditMenuTableEnd	label   word

DorkEditMenu	proc	near
	mov     cx, offset EditMenuTableEnd	;if table empty exit
	sub     cx, offset EditMenuTable	;
	jcxz    exit                            ;
	mov     bp, offset EditMenuTable	;
topLoop:
	mov     dl, VUM_NOW                     
	GetResourceHandleNS	MenuInterface, bx
	mov     si, cs:[bp]                     ;bx:[si] ui object to dork
	mov     di, mask MF_CALL or mask MF_FIXUP_DS 
	push  ax, bp                          ;save method and ptr into table
	call    ObjMessage                      ;
	pop ax, bp
	add     bp, 2                           ;advance table ptr
	cmp     bp, offset EditMenuTableEnd
	jb      topLoop                         ;       exit
exit:
	ret
DorkEditMenu	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	enable the Copy entry of the Edit Menu

CALLED BY:	(INTERNAL)
PASS:		ss	- dgroup	

RETURN: 	
	
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	07/03/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DisableCopy	proc	near
        mov     ax, MSG_GEN_SET_NOT_ENABLED
	call	DorkCopy
	ret
DisableCopy	endp

EnableCopy	proc	near
        mov     ax, MSG_GEN_SET_ENABLED
	call	DorkCopy
	ret
EnableCopy	endp

DorkCopy	proc	near
	uses	si, di, dx
	.enter
	GetResourceHandleNS	CopySelect, bx
	mov	si, offset CopySelect
	mov     dl, VUM_NOW
	mov     di, mask MF_FORCE_QUEUE
	call    ObjMessage
	.leave	
	ret
DorkCopy	endp

if ERROR_CHECK

CheckScreenBuf	proc	near
	class	ScreenClass

	uses	ax, bx, cx, dx, si, di
	.enter
	pushf
	mov	bx, ds:[si].SI_screenHandle

	mov	ax, MGIT_ADDRESS
	call	MemGetInfo

	cmp	ax, ds:[si].SI_screenBuf
	ERROR_NZ	TERM_USING_UNLOCKED_SCREEN_BUF
	popf
	.leave
	ret
CheckScreenBuf	endp

NullScreenBuf	proc	near
	class	ScreenClass

	uses	ax, bx, cx, dx, di
	.enter
	pushf
	mov	bx, ds:[si].SI_screenHandle

	mov	ax, MGIT_FLAGS_AND_LOCK_COUNT
	call	MemGetInfo
	tst	ah
	jnz	done
	mov	ds:[si].SI_screenBuf, -1
done:
	popf
	.leave
	ret
NullScreenBuf	endp

endif

if HALF_AND_FULL_WIDTH
CheckHalfWidth	proc	near
	;
	; always halfwidth, remote system should send corret cursor movements
	; for fullwith characters
	;
	; UNLESS half-duplex
	;
;	push	ds
;	GetResourceSegmentNS	halfDuplex, ds
;	cmp	ds:[halfDuplex], TRUE
;	pop	ds
;	stc					; assume halfwidth (full-dup)
;	jne	done
	cmp	ax, 80h
	jb	halfWidth			; C set
	cmp	ax, C_HALFWIDTH_IDEOGRAPHIC_PERIOD
	jb	fullWidth
	cmp	ax, C_FULLWIDTH_CENT_SIGN
	jb	halfWidth			; C set
fullWidth:
	clc
halfWidth:
done:
	ret
CheckHalfWidth	endp
endif

if	_SPECIAL_KEY

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSendSpecialControlKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a control character from the special key list

CALLED BY:	(INTERNAL) ScreenSpecialKeyInsert
PASS:		al	= selection from TermSpecialKeyList
		es	= dgroup
		*ds:si	= screenObject 
		ds:di	= screenObject instance data
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	3/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenSendSpecialControlKey	proc	near

EC <		Assert_dgroup	es					>
	;
	; Convert KOMBI to Ascii FS-US
	;
		Assert	urange, al, KOMBI_CTRL28, KOMBI_CTRL28+3

		add	al, C_FS-KOMBI_CTRL28
DBCS <		clr	ah						>
SBCS <		mov	ah, CS_BSW					>
		mov_tr	cx, ax
		GOTO	SendKeyCommon

ScreenSendSpecialControlKey	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSendNumKeypadKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out the keypad keys as typed in keyboard

CALLED BY:	(INTERNAL) ScreenSpecialKeyInsert
PASS:		al	= selection from TermSpecialKeyList
		es	= dgroup
		*ds:si	= screenObject 
		ds:di	= screenObject instance data
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenSendNumKeypadKey	proc	near
	;
	; Map from selection to actual key pressed as typed from keyboard
	;
		CheckHack <KOMBI_PF lt KOMBI_ENTER>
		CheckHack <KOMBI_ENTER+1 eq KOMBI_COMMA>
		CheckHack <KOMBI_COMMA+1 eq KOMBI_DOT>
		CheckHack <KOMBI_DOT lt KOMBI_NUMBER>
		CheckHack <KOMBI_NUMBER lt KOMBI_MINUS>
DBCS <		clr	ah						>
		cmp	al, KOMBI_COMMA
		jb	enterKey
		je	commaKey

		cmp	al, KOMBI_DOT
		je	dotKey

		cmp	al, KOMBI_MINUS
		jb	numberKey		; 0-9

SBCS <		mov	al, KONMBC_MINUS				>
DBCS <		mov	ax, KONMBC_MINUS				>
		jmp	getKey
commaKey:
SBCS <		mov	al, KONMBC_COMMA				>
DBCS <		mov	ax, KONMBC_COMMA				>
		jmp	getKey
dotKey:
SBCS <		mov	al, KONMBC_DOT					>
DBCS <		mov	ax, KONMBC_DOT					>

getKey:
if	DBCS_PCGEOS
		clr	ch
		mov_tr	cx, ax			; cx <- Chars
EC <		Assert_etype	cx, Chars				>
else
		mov_tr	cl, al
		mov	ch, CS_BSW		; any key other than Enter
						; belongs to BSW char set
endif

sendKey:
		GOTO	SendKeyCommon

enterKey:
SBCS <		mov	cl, KONMBC_ENTER				>
		mov	ch, CS_CONTROL		; Enter is a control key
DBCS <		mov	cx, KONMBC_ENTER	; cx<- chars		>
		jmp	sendKey
numberKey:
		sub	al, KOMBI_NUMBER	; al <- digit
		add	ax, KONMBC_NUMBER	; ax <- Chars
		jmp	getKey

ScreenSendNumKeypadKey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendKeyCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine for sending simulated keypresses
		to the screen object.

CALLED BY:	(INTERNAL)
			ScreenSendNumKeypadKey,
			ScreenSendSpecialControlKey
PASS:		al/ax	= Character to send
		es	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	3/ 8/96    	Broken out from 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendKeyCommon	proc	near
	.enter

		push	cx, si, di, bp
		clr	dh			; no ShiftState
		mov	dl, mask CF_FIRST_PRESS
EC <		Assert_dgroup	es					>
		call	ScreenKeyboard		; ax,bx,cx,dx,si,di destroyed
		pop	cx, si, di, bp	; restore key
	;
	; Send out release key
	;
		clr	dh			; no ShiftState
		mov	dl, mask CF_RELEASE
		call	ScreenKeyboard
		
	.leave
	Destroy	ax, bx, cx, dx, si, di
	ret
SendKeyCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSendAppKeypadKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out keypad key codes in Application mode

CALLED BY:	(INTERNAL) ScreenSpecialKeyInsert
PASS:		al	= selection from TermSpecialKeyList
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, es, ds, si, di, bp (everything)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppKeyOutCodePrefix	char	C_ESCAPE, 'O'

ScreenSendAppKeypadKey	proc	near
		.enter
		CheckHack <KOMBI_PF lt KOMBI_ENTER>
		CheckHack <KOMBI_DOT lt KOMBI_NUMBER>
		CheckHack <KOMBI_NUMBER lt KOMBI_MINUS>
        ;
        ; Send out prefix first
        ;
                push    ax
                GetResourceSegmentNS    dgroup, ds
                segmov  es, cs, ax
                mov     si, offset AppKeyOutCodePrefix
                mov     cx, size AppKeyOutCodePrefix
                call    SendBuffer              ; es:si<-past text
                                                ; carry set if error
                pop     ax
                jc      error                   ; no need to send anything else
        ;
        ; Find out what to send out according to selection. Here it defines
        ; what code to send
        ;
                cmp     al, KOMBI_ENTER
                jb      PF1to4
                je      keypadEnter

                cmp     al, KOMBI_DOT
                jb      commaKey
                je      dotKey

                cmp     al, KOMBI_MINUS
                jb      number
EC <            ERROR_NE TERM_INVALID_SPECIAL_KEY_SELECTION             >

SBCS <          mov     al, KOMBC_MINUS                 >
DBCS <          mov     ax, KOMBC_MINUS                 >
                jmp     sendLastChar

commaKey:
SBCS <          mov     al, KOMBC_COMMA                         >
DBCS <          mov     ax, KOMBC_COMMA                         >
                jmp     sendLastChar
dotKey:
SBCS <          mov     al, KOMBC_DOT                           >
DBCS <          mov     ax, KOMBC_DOT                           >

sendLastChar:
        ;
        ; Send the character(s)
        ;
                mov_tr  cl, al
                call    SendChar                ; carry set if error
error:
                .leave
                ret
keypadEnter:
                mov     al, KOMBC_ENTER
                jmp     sendLastChar
PF1to4:
                sub     al, KOMBI_PF            ; al<-index in PF category
                add     al, KOMBC_PF            ; al <- charcter to send
                jmp     sendLastChar
number:
                sub     al, KOMBI_NUMBER        ; al<-index in 0-9 category
                add     al, KOMBC_NUMBER        ; al <- character to send
                jmp     sendLastChar
ScreenSendAppKeypadKey	endp

endif	; if _SPECIAL_KEY



