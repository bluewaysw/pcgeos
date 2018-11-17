COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Screen
FILE:		screenMain.asm

AUTHOR:		Dennis Chow, September 8, 1989

ROUTINES:
	Name			Description
	----			-----------
 ?? INT ScreenResetInitialValues
				When we are in a Lazarus state (opening up
				again before we have completely closed),
				the screenObject still has all of its old
				instance data.  TermDetach frees all the
				buffers, but some of the values can still
				be problematic. Reset all the instance data
				to what it would be if we had started with
				a freshly instantiated object. Make sure
				this agrees with termui.ui

    MTD MSG_SCR_DISPLAY_DATA_FROM_REMOTE
				Display data sent from remote connection

    MTD MSG_SCR_DISPLAY_INTL_CHAR
				Display an international character as local
				echo

    MTD MSG_SCR_ERASE_INTL_CHAR	Erase the current international character

 ?? INT ScreenCheckCursorPos	Checks to make sure the cursor is in a
				valid position

 ?? INT AssertCurCharCurPos	Process the data in auxilary buffer

 ?? INT ScreenSetViewSize	Set the screen font to Bison 9 or Bison 12

 ?? INT ScreenBison12		Set the screen font to Bison 12

    MTD MSG_SCR_CURSOR_UP_OR_SCROLL
				Move cursor up 1 row.  If already at top of
				scroll region, scroll region down.  If
				cursor is above the scroll region will not
				scroll (VT100 behavior)

    MTD MSG_SCR_CURSOR_DOWN_OR_SCROLL
				Move cursor down 1 row.  If already at
				bottom of scroll region, scroll the region
				up.  If cursor is below the scroll region,
				will not scroll (VT100 behavior)

    MTD MSG_SCR_CLEAR_SCREEN_AND_SCROLL_BUF
				Clear screen and scroll buffer

    MTD MSG_SCR_CLEAR_TO_BEG_LINE
				Clears current line from first column to
				cursor (inclusive)

    MTD MSG_SCR_CLEAR_TO_BEG_DISP
				Clears chars from upper left of disp to
				cursor (inclusive)

    MTD MSG_SCR_CLEAR_LINE	Clears entire current line

    MTD MSG_SCR_RESET_SCROLLREG	Reset the scroll region

    MTD MSG_META_LOST_FOCUS_EXCL
				

    MTD MSG_META_LOST_SYS_FOCUS_EXCL
				

    MTD MSG_META_GAINED_FOCUS_EXCL
				

    MTD MSG_META_GAINED_SYS_FOCUS_EXCL
				

    INT SendScreenFocusNotification
				Sends the
				GWNT_EDITABLE_TEXT_OBJECT_HAS_FOCUS
				notification.

 ?? INT CheckForTextItem	check if current quick-transfer item
				supports CIF_TEXT format

 ?? INT ScreenViewClosingQT	handle closing of window, stop
				drag-selection and stop quick transfer

    MTD MSG_SCR_SEND_BREAK	Send a BREAK signal out the serial line.

    MTD MSG_SCR_IGNORE_ESC_SEQ	Do nothing for the parsed escape sequence

    MTD MSG_SCR_RENEW_GRAPHICS_ON
				Reset graphics attributes and then set the
				new ones

    MTD MSG_SCR_RENEW_SCROLL_REG_BOTTOM
				Reset the top of scroll region and set the
				bottom to new value

    MTD MSG_META_BRING_UP_HELP	MSG_META_BRING_UP_HELP must be handled be a
				GenClass object

 ?? INT ScreenFepCallBack	callback routine for FEP

 ?? INT ScreenFepGetTempTextBounds
				suggest bounds for the temp text window

 ?? INT ScreenFepGetTempTextAttr
				get temp text attributes for FEP

 ?? INT ScreenFepInsertTempText	send the passed text to the serial port

 ?? INT ScreenFepDeleteText	delete the N characters immediately before
				the current cursor position

    MTD MSG_SCR_GET_FEP_TEMP_TEXT_ATTR
				return character attributes of text at
				current position

    MTD MSG_SCR_GET_FEP_TEMP_TEXT_BOUNDS
				return bounds of text at current position

    MTD MSG_SCR_ZOOM		Changes "zoom in" moniker to "zoom out",
				and sends change font size message to
				ourselves.

    MTD MSG_SCR_UNZOOM		Changes "zoom out" moniker to "zoom in",
				and sends message to ourselves to reduce
				font size.

 ?? INT SetNotUsable		Set a certain Object usable or not usable

 ?? INT SetUsable		Set a certain Object usable or not usable

    MTD MSG_SCR_SPECIAL_KEY_INSERT
				Insert a special key

    MTD MSG_SCR_RESPOND_WHAT_ARE_YOU
				Respond to What Are You request

    MTD MSG_SCR_RESPOND_CURSOR_POSITION
				Sends current cursor position back to host

 ?? INT SendResponse		Sends a string to the host, inserting
				numeric arguments as needed.

    MTD MSG_SCR_SELECT_G	Select character set designator to G0

    MTD MSG_SCR_SELECT_G	Select character set designator to G1

    MTD MSG_SCR_G		Choose Special graphics character set for
				G0

    MTD MSG_SCR_G		Choose Special graphics character set for
				G1

    MTD MSG_SCR_SAVE_INTL_CHAR	Save the current editing international
				character

    MTD MSG_SCR_RESTORE_INTL_CHAR
				Restore the international character being
				edited

    MTD MSG_SCR_SAVE_CUR_CHAR	Save the character at the current cursor
				position

    MTD MSG_SCR_RESTORE_CUR_CHAR
				Restore the character at cursor position
				saved by ScreenSaveCurChar

    MTD MSG_SCR_RESUME_KEYBOARD_INPUT
				Resume regular keyboard input sequence

    MTD MSG_SCR_SYNC		Synchronize with sender of this message

    MTD MSG_SCR_RESET_VT	Reset the Virtual Terminal settings

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc       9/ 8/89        Initial revision.

DESCRIPTION:

	There are a few method handlers in here that may seem
	obsolete, inconsistenly-named, or even downright buggy
	(check out the CURSOR_UP/DOWN messages).  This was done
	to preserve any behavior that terminals other than VT100
	might rely on.  Someone with more time can go back through
	and figure out the minimal feature set the screen object
	must provide to implement all the desired terminal types.

	$Id: screenMain.asm,v 1.1 97/04/04 16:55:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a screen object

CALLED BY:	MSG_META_INITIALIZE via TermAttach

PASS:		ds:*si	- screen instance data
		es	- dgroup

RETURN:		C	- set if not enough memory to create screen obj

DESTROYED:	es, ax, cx, di, si

PSEUDO CODE/STRATEGY:
		set default values for screen object
		allocate buffers

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 8/24/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenInitialize	method	ScreenClass, MSG_META_INITIALIZE
	mov	si, ds:[si]			;dereference the ptr

	tst	es:[termLazarusing]
	jz	startingFresh	

	call	ScreenResetInitialValues

startingFresh:
	mov	ax, FILE_CACHE_SIZE		;get 1K swappable
	mov	cx, ALLOC_DYNAMIC 		;  file cache
	call	MemAlloc
	jc	error_JC			;if no memory, flag error
	mov	ds:[si][SI_cacheHandle], bx	;save handle to file cache
	mov	ax, SCROLL_BUF_SIZE		;get swappable 25K buffer to 
	mov	cx, ALLOC_DYNAMIC		;  hold scroll data
	call	MemAlloc			;
	jc	error_JC			;if no memory, flag error
	mov	ds:[si][SI_scrollHandle], bx	;save handle to buffer
	mov	ax, SCREEN_SIZE			;get memory for screen buffer
	mov	cx, (mask HAF_ZERO_INIT shl 8) or ALLOC_DYNAMIC 
	call	MemAlloc			;	
error_JC:
	LONG jc	error 				;exit if can't get memory
	mov	ds:[si][SI_screenHandle], bx	;store handle to segment
	call	BufClear

	push	si				;save ptr to instance data	
	sub	sp, size RectDWord
	mov	dx, sp				;pass buffer in cx:dx
	mov	cx, ss
	GetResourceHandleNS	TermView, bx
	
	mov	si, offset TermView
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_VIEW_GET_DOC_BOUNDS
	call	ObjMessage
	mov	bp, dx
	mov	cx, ss:[bp].RD_right.low	;put size in cx, dx
	mov	dx, ss:[bp].RD_bottom.low
	add	sp, size RectDWord
	pop	si				;restore ptr to instance data
	mov	ds:[si][SI_docWidth], cx	;cx - width of doc
	mov	ds:[si][SI_docHeight], dx	;dx - height of doc

if	_MODEM_STATUS
	;
	; Allocate the GState now
	;
	push	bp
	clr	di				; no window yet
	call	GrCreateState			; ^hdi <- GState
	mov	ds:[si][SI_gState], di
	call	RestoreScreenState
	pop	bp
endif
	push	si				;save ptr to screen instance
	mov	ax, MSG_VIS_GET_SIZE
	mov	di, mask MF_RECORD
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	call	ObjMessage
	mov	cx, di				;event in cx
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	GetResourceHandleNS	MyApp, bx
	mov	si, offset MyApp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ss:[fieldWinWidth], cx
	mov	ss:[fieldWinHeight], dx
	;
	; force height to 12 if starting on CGA from scratch
	;
	cmp	ss:[restoreFromState], TRUE
	je	noForce
	GetResourceHandleNS	MyApp, bx
	mov	si, offset MyApp
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME	; ah - display type
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	al, ah				; al = ah = display type
	andnf	al, mask DT_DISP_CLASS
	cmp	al, DC_GRAY_1 shl offset DT_DISP_CLASS	; mono?
	jne	noForce				; nope
	cmp	ah, CGA_DISPLAY_TYPE		; CGA?
	jne	noForce
	mov	dx, 12				; #lines = (dx.cx)
	clr	cx
	GetResourceHandleNS	WinLinesRange, bx
	mov	si, offset WinLinesRange
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	clr	bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
noForce:

	pop	si

	mov	dl, FALSE
	mov	ss:[inCopy], dl			;clear QUICK_COPY flag
	mov	ss:[curInSelect], dl		;clear cursor in select region
	mov	ss:[inDragSelect], dl		;	flag
	mov	ss:[scrollLocked], dl
	call	ResetView
	CallMod	DisableSaveScroll		
	clc					;clear error flag
	jmp	short exit
error:
	segmov	ds, ss, bp
	mov	bp, ERR_NO_MEM_ABORT
	CallMod	DisplayErrorMessage	
	stc					;set error flag
exit:
	ret
ScreenInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenResetInitialValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When we are in a Lazarus state (opening up again before we
		have completely closed), the screenObject still has all of
		its old instance data.  TermDetach frees all the buffers,
		but some of the values can still be problematic.
			Reset all the instance data to what it would be if
		we had started with a freshly instantiated object.
			Make sure this agrees with termui.ui

CALLED BY:	ScreenInitialize

PASS:		ds:si	- ScreenClass object
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/18/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenResetInitialValues	proc	near
	class ScreenClass
	uses	ax, cx, es, di
	.enter

	segmov	es, ds, di
	mov	di, si			; es:di is ScreenClass instance data
	add	di, offset SI_fontColor	; first instance data field

	;
	; Clear all of the instance data, then go back and set certain values
	;
	clr	ax
	;
	; the size of the instance data is the offset of the last instance
	; field (plus the size of that field) minus the offset of the first.
	;
	mov	cx, (offset SI_intFlags) + \
		(size ScreenInternalFlags) - \
		(offset SI_fontColor)
	shr	cx, 1			; divide by two for # of words
	jnc	evenAmount
	stosb				; account for odd byte, if there is one
evenAmount:
	rep	stosw

	;
	; set all the exceptions
	;
CheckHack< FALSE eq 0>		; all fields set to FALSE are already 0
	mov	ds:[si].SI_fontColor, C_BLACK
	mov	ds:[si].SI_gState, BOGUS_VAL
	mov	ds:[si].SI_lineHeight, DEF_FONT_HEIGHT
	mov	ds:[si].SI_leading, DEF_FONT_LEADING
	mov	ds:[si].SI_charWidth, DEF_FONT_WIDTH
	mov	ds:[si].SI_backColor, C_WHITE
	mov	ds:[si].SI_scrollRegBot, (MAX_LINES - 1)
	mov	ds:[si].SI_autoWrap, TRUE
	mov	ds:[si].SI_winWidth, INIT_WIDTH
	mov	ds:[si].SI_winHeight, INIT_HEIGHT
	mov	ds:[si].SI_capHandle, BOGUS_VAL
	mov	ds:[si].SI_maxLines, MAX_LINES
	mov	ds:[si].SI_maxCols, INIT_LINE_CHARS
	.leave
	ret
ScreenResetInitialValues	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the screen object

CALLED BY:	MSG_META_EXPOSED

PASS:		ds:*si	- screen instance data	
		es	- dgroup
		cx	- window to draw to
		[SI_screenBuf]	- pointing to unlocked segment

RETURN:		---

DESTROYED:	---

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 8/24/89	Initial version
	dennis	12/06/89	transfered from TermClass to ScreenClass

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenDraw	method	ScreenClass, MSG_META_EXPOSED
	cmp	ss:[termStatus], DORKED		;if this is bogus method
	je	exit				;	exit
	cmp	ss:[termStatus], OFF_LINE	;if this is bogus method	
	je	exit				;	exit
	mov	si, ds:[si]			;get ptr to instance data
	cmp	ds:[si][SI_iconified], TRUE	;if we've shrunk don't need to
	je	exit				;	update
	mov	di, ds:[si][SI_gState]		;get gState
	cmp	di, BOGUS_VAL			;is gState valid? 
	
	jne	SD_ok				;yes, continue	
	mov	ds:[si][SI_winHandle], cx	;else
	mov	di, cx				;store  the window and 
	call	GrCreateState			;create a GState
	mov	ds:[si][SI_gState], di		;  
	call	RestoreScreenState

SD_ok:
	call	GrBeginUpdate
	call	DrawDocument		;draw document on top
	call	GrEndUpdate
;-----------------------------------------------------------------------------
;moved here from ScreenViewClosing
	call	GrGetWinBounds			;  
	mov	cx, ds:[si][SI_lineHeight]	;The way scrolling is handle
	shl	cx, 1				;  is that we compare the bottom
	sub	dx, cx				;  of the cursor against the
	inc	dx				;  bottom of the window.  When
	mov	ds:[si][SI_winBottom], dx	;  we're iconified we have no
;-----------------------------------------------------------------------------
exit:
	ret
ScreenDraw	endm

ScreenViewOpening	method	ScreenClass, MSG_META_CONTENT_VIEW_OPENING
	mov	ds:[di][SI_iconified], FALSE
	ret
ScreenViewOpening	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenViewClosing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Window being closed, destroy the GState 

CALLED BY:	

PASS:		ds:*si 		- instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenViewClosing	method	ScreenClass, MSG_META_CONTENT_VIEW_CLOSING
	call	ScreenViewClosingQT		; handle ending QT, if needed
	;if shutting down application cauz of lack of memory then
	;we don't have a Gstate to destroy
	cmp	ss:[termStatus], DORKED
	je	exit
	mov	si, ds:[si]			;dereference object pointer
	mov	di, ds:[si][SI_gState]		;destroy our gstate
;
;brianc found a bug where if he launched all the applications and then
;quickly exited to DOS, geoComm crashed in this method handler
;because I expect to have a valid gState and conceiveably I may never have
;gotten a MSG_META_EXPOSED (which is where I create my gState.
;
	cmp	di, BOGUS_VAL
	je	exit
;too late to do this here, window is hosed, so do in ScreenDraw instead,
;slower but no crash - brianc 2/24/94
if 0
	call	GrGetWinBounds			;  
	mov	cx, ds:[si][SI_lineHeight]	;The way scrolling is handle
	shl	cx, 1				;  is that we compare the bottom
	sub	dx, cx				;  of the cursor against the
	inc	dx				;  bottom of the window.  When
	mov	ds:[si][SI_winBottom], dx	;  we're iconified we have no
endif

	call    GrDestroyState			;  window, so we store the 
						;  bottom of the window now.
	mov     ds:[si][SI_gState], BOGUS_VAL   ;flag gState dorked
	
	mov     ds:[si][SI_iconified], TRUE   	;we've shrunk
exit:
	ret
ScreenViewClosing	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenCheckCursorPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to make sure the cursor is in a valid position

CALLED BY:	DrawCursor
PASS:		ds:si = ScreenClass instance data
RETURN:		nothing
DESTROYED:	nothing (not even flags)
SIDE EFFECTS:	

		FatalError's if invalid position

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/21/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
ScreenCheckCursorPos	proc	near
	class	ScreenClass
	pushf
	.enter

		cmp	ds:[si][SI_curChar], MAX_LINE_CHARS
		jae	problem
;		ERROR_AE TERM_ERROR_INVALID_CURSOR_POSITION

		cmp	ds:[si][SI_curLine], MAX_LINES
		jb	exit
;		ERROR_AE TERM_ERROR_INVALID_CURSOR_POSITION
problem:
		nop
exit:		
	.leave
	popf
	ret
ScreenCheckCursorPos	endp
endif ; ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the data in auxilary buffer

CALLED BY:	SerialInThread, TermScreenDraw

PASS:		*ds:si 		- instance data
		ss		- dgroup (because the term:0 thread is running
					this object)
		*ds:si[SI_screenBuf] - pointing to unlocked segment
		cx		- if 0, it means that the characters have been
				passed on the stack. Else, cx = handle of block
				which contains characters. Must free block
				when done with it!
		dx		- number of bytes to process

		ss:bp	= data on stack (if cx = 0)

		OLD:
		cx		- number of chars in buffer
		dx:bp		- buffer to read chars from 

RETURN:		ds, dx	= same

DESTROYED:	ax, bx, cx, bp, es, si

PSEUDO CODE/STRATEGY:
		Create GState
		if character printable
			store it in buffer 

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	8/22/89		Initial version
	eric	10/90		Updated to accept data from stack or
				a block on the global heap, but NOT auxBuf,
				allowing asynchronous operation.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenData	method	ScreenClass, MSG_SCR_DATA		

	;we will push DX as soon as we set bp = sp!
if DBCS_PCGEOS
	mov	ax, dx			;ax = # bytes
	shr	ax, 1			;ax = # chars
	mov	ss:[scrNumChars], ax	;save num of chars to process
	
else
	mov	ss:[scrNumChars], dx	;save num of chars to process
endif
	mov	ss:[scrBlockToFree], cx	;save handle of block to free
					;when exit handler. (0 means none)
	mov	si, ds:[si]		;dereference object pointer
	tst	cx
	jnz	readFromBlock

readFromStack:
	ForceRef readFromStack

	;the characters have been passed on the stack.

	;
	; In Responder, not only FSM calls MSG_SCR_DATA, but also
	; TermBogusGenText object. So it doesn't usually have
	; dgroup:fsmStackDataID pushed for EC. Therefore, just ignore this
	; check in Responder. 
	;
EC <	sub	dx, 2			;remove ID from count		>
EC <	dec	ss:[scrNumChars]					>

if not DBCS_PCGEOS
; if DBCS'd, error occurs here since in previous routine, the ID is treated
; as a word.  Under SBCS, the # of bytes = # of chars, and # chars is
; decremented twice in the EC code below.  However, under DBCS, the char
; count is reduced by one since the buffer size is div'd by 2.  This leads
; to the problem of subtracting one too many characters from the actual
; length when decrementing below.  So decrement again only if in SBCS.
EC <    dec     ss:[scrNumChars]                                        >
endif ; ! DBCS_PCGEOS


if ERROR_CHECK
	mov	di, bp
	add	di, dx
	mov	ax, ss:[di]		;get ID
	cmp	ax, ss:[scrStackDataID]	;compare to what we expect
	ERROR_NE TERM_ERROR		;bail if error

	inc	ss:[scrStackDataID]	;prepare for next
endif	; ERROR_CHECK

	segmov	es, ss, bx		;set es:bp = data on stack
	jmp	short readyToProcess	;skip to process chars...

readFromBlock:
	;the characters have been passed in a block on the global heap
	;Point to the block (we will free it before exiting this handler)

	mov	bx, cx			;bx = handle of block on global heap
	call	MemLock			;lock block, set ax = segment
	mov	es, ax			;set es:bp = data in block
	clr	bp

readyToProcess:
	;es:bp = pointer to first character to process.

if      _CAPTURE_CLEAN_TEXT
        ;
        ; Capture text if necessary, otherwise, FileCaptureText just does
        ; nothing. 
        ;
        call    FileCaptureText         ;nothing destroyed
endif   ; _CAPTURE_CLEAN_TEXT

	push	dx			;MUST return same DX, or ObjMessage
					;will screw up!

	mov	bx, ds:[si][SI_screenHandle]	;lock screen buffer
	call	MemLock				;

	mov	ds:[si][SI_screenBuf], ax	;
	
if	_MODEM_STATUS
	;
	; Since the window hasn't been displayed yet, winHandle is null. But
	; we still want to draw the data. So, test on GState instead.
	;
	cmp	ds:[si][SI_gState], BOGUS_VAL
	LONG je	SD_ret
else	; if !_MODEM_STATUS
	tst	ds:[si][SI_winHandle]		;get pane window from core block
	jnz	SD_winOK			;no	
	jmp	SD_ret				;yes, exit
endif	; if _MODEM_STATUS
	
SD_winOK:
	mov	di, ds:[si][SI_gState]		;get gState for the window
	call	EraseCursor			;nuke cursor before print
NCUR <	cmp	ds:[si][SI_curChar], MAX_LINE_CHARS ;are we at end of line?>
CUR <	cmp	ds:[si][SI_curPos], MAX_LINE_CHARS			>
	jb	printChars			;nope

	tst	ds:[si][SI_autoWrap]
	jnz	doWrap

	;
	; VT100 no-wrap mode puts overflow chars in 80th column
	;
	cmp	ss:[termType], VT100
	jne	SD_ret				;yep, bogus and bail.	
NCUR <	dec	ds:[si][SI_curChar]		  ; back up to 80th column >
CUR <	dec	ds:[si][SI_curPos]					>
	jmp	printChars

doWrap:
	call	DoNewLine			;if at end of line insert line
	
printChars:
	cmp	ds:[si][SI_inScroll], FALSE	;if we scrolled away from
	je	saveCursor			;  window, then reset the

	call	ScrollResetView			;  view
	
saveCursor:
	push	ds:[si][SI_curChar]		;save the old cursor position
CUR <	push	ds:[si][SI_curPos]					>
CUR <EC <call	AssertCurCharCurPos					>>
	
SD_getChar:
SBCS <	mov	dl, es:[bp]			;get char to process	>
DBCS <	mov	dx, es:[bp]			;get char to process	>
SBCS <	cmp	dl, CHAR_PRINT 			;is this a printable char>
DBCS <	cmp	dx, CHAR_PRINT 			;is this a printable char>
	jae	SD_store			;yep, store it
						; (allow high-ASCII chars)
	jmp	SD_next				;get next char

SD_store:
	cmp	ds:[si][SI_insertMode], TRUE
	jne	SD_stuff

	call	BufShiftLineRight

SD_stuff:
	tst	ds:[si][SI_ignoreNL]		;if VT100 don't wrap until write
	jz	10$				;  on 81st column

NCUR <	cmp	ds:[si][SI_curChar], MAX_LINE_CHARS			>
CUR <	cmp	ds:[si][SI_curPos], MAX_LINE_CHARS			>
	jb	10$				;continue

	tst	ds:[si][SI_autoWrap]		;else is wrapping set?
	je	drawText			;no, quit storing stuff

	call	DoNewLine			;yes, wrap to next line

10$:
	call	BufStoreData			;stuff char into screen buf

	inc	ds:[si][SI_curChar]		;increment cursor
CUR <	inc	ds:[si][SI_curPos]					>
CUR <	mov	ax, dx				;ax = char		>
CUR <	call	CheckHalfWidth			;carry set if halfwidth	>
CUR <	jc	haveWidth						>
CUR <	inc	ds:[si][SI_curPos]		;full-width char	>
CUR <haveWidth:								>
CUR <EC <call	AssertCurCharCurPos					>>
	tst	ds:[si][SI_ignoreNL]		;if this is VT100
	jnz	SD_next				;then don't wrap till later

NCUR <	cmp	ds:[si][SI_curChar], MAX_LINE_CHARS			>
CUR <	cmp	ds:[si][SI_curPos], MAX_LINE_CHARS			>
	jb	SD_next				;

	tst	ds:[si][SI_autoWrap]		;then wrap immediately
	je	SD_next				;

	call	DoNewLine			;

SD_next:	
	inc	bp				;pt to next char
DBCS <	inc	bp							>
	dec	ss:[scrNumChars]		;done with buffer?

	jne	SD_getChar			;nope, do next char	

drawText:
	mov	bp, ds:[si][SI_curChar]		;save updated cursor
CUR <	mov	dx, ds:[si][SI_curPos]					>
CUR <	pop	ds:[si][SI_curPos]
	pop	ds:[si][SI_curChar]		;get old cursor
	tst	ss:[wrapped]
	jz	noWrap

	clr	ds:[si][SI_curChar]		;if wrap, reset cursor
CUR <	clr	ds:[si][SI_curPos]					>
	mov	ss:[wrapped], FALSE

noWrap:
	mov	ax, bp				;
	sub	ax, ds:[si][SI_curChar]		;calc #chars to erase
	tst	ax
	jz	done

	tst	ds:[si][SI_insertMode]		;are we in insertmode?
	je	50$

	mov	ax, MAX_LINE_CHARS		;if in insert mode
	sub	ax, ds:[si][SI_curChar]		;have to redraw whole line

50$:
CUR <	push	dx							>
	call	EraseDrawLine
	call	DrawRemLine			;   and print current line
CUR <	pop	dx							>

done:
CUR <	mov	ds:[si][SI_curPos], dx					>
	mov	ds:[si][SI_curChar], bp		;restore updated cursor 
CUR <EC <call	AssertCurCharCurPos					>>
	call	DrawCursor	

SD_ret:
	mov	bx, ds:[si][SI_screenHandle]	;unlock screen buffer
	call	MemUnlock			;
EC <	call	NullScreenBuf			; stuff bogus segment	>

	;now, if we were passed data in a block on the global heap,
	;free that block now.

	mov	bx, ss:[scrBlockToFree]	;get handle of block to free
	tst	bx
	jz	exit			;skip if none...
	call	MemFree
	
exit:
	pop	dx
EC <	add	dx, 2			;make room for ID		>
	ret
ScreenData	endm						

if CURSOR
AssertCurCharCurPos	proc	near
	class	ScreenClass
	mov	ax, ds:[si].SI_curChar
	call	GetCurCharFromCurPos
	cmp	ax, ds:[si].SI_curChar
	WARNING_NE	0
	ret
AssertCurCharCurPos	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenBison9Or12
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the screen font to Bison 9 or Bison 12

CALLED BY:	TermSetBison9

PASS:		ds:*si	- screen instance data
		es	- dgroup
		cx	- 9 or 12

RETURN:		di	- GState

DESTROYED:	cx, dx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 8/29/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenBison9Or12	method	ScreenClass, MSG_SCR_BISON_9_OR_12
	cmp	cx, 9
	je	set9
	call	ScreenBison12
	jmp	short exit
set9:
	mov     si, ds:[si]                     ;dereference ptr
	cmp	ds:[si][SI_lineHeight], BISON_9_HEIGHT
	je	exit				;if already using Bison 9, exit
setBison9	label	far
	mov	di, ds:[si][SI_gState]		;get our gstate
	call	EraseCursor
	mov	cx, TERM_FONT			;else use non-proportional 
	mov	dx, TERM_FONT_9			;     9 point BISON font
	clr	ah				;     no fractional pt sizes
	call	ScreenSetFont
	mov	ds:[si][SI_docHeight], BISON_9_DOC_HEIGHT
	mov	ds:[si][SI_docWidth], BISON_9_DOC_WIDTH
	mov	cx, BISON_9_DOC_WIDTH		;set Bison 9 doc size
	mov     dx, BISON_9_DOC_HEIGHT
	call	ScreenSetViewSize
	
	call	SetFontNewScreen		;reset the view for new font
exit:
	ret
ScreenBison9Or12	endm

ScreenSetViewSize	proc	near
	uses	si
	.enter
	GetResourceHandleNS	TermView, bx
	mov	si, offset TermView
	mov	di, mask MF_FIXUP_DS
	call	GenViewSetSimpleBounds
	.leave
	ret
ScreenSetViewSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenBison12
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the screen font to Bison 12

CALLED BY:	TermSetBison12

PASS:		ds:*si	- screen instance data
		es	- dgroup

RETURN:		---

DESTROYED:	cx, dx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/07/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenBison12	proc	far
	class	ScreenClass

	mov     si, ds:[si]                     ;dereference ptr
	cmp	ds:[si][SI_lineHeight], BISON_12_HEIGHT
	je	exit				;if we are using Bison 12, exit
setBison12	label	far
	mov	di, ds:[si][SI_gState]		;get our gstate
	call	EraseCursor
	mov	cx, TERM_FONT			;else use non-proportional 
	mov	dx, 12				;     12 point BISON font
	call	ScreenSetFont
	mov	ds:[si][SI_docHeight], BISON_12_DOC_HEIGHT
	mov	ds:[si][SI_docWidth], BISON_12_DOC_WIDTH

	mov	cx, BISON_12_DOC_WIDTH		;set Bison 12 doc size
	mov     dx, BISON_12_DOC_HEIGHT
	call	ScreenSetViewSize		; (preserves si)
	call	SetFontNewScreen		;reset the view for new font
exit:
	ret
ScreenBison12	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenKeyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle a press on the keyboard 

CALLED BY:	MSG_META_KBD_CHAR
PASS:		cx - character value
			SBCS: ch = CharacterSet, cl = Chars
			DBCS: cx = Chars
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code
		es	- dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:
	 user pressed on the keyboard.  
	 take the character and write it out the com port 
	 Send all Ctrl chars under x20h and all printable chars
	 >= 0x20h and <= x80h.  Only send out when CharFlags 
	 is first press

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	When in local echo mode, I only echo those characters that get
	sent out the modem in contrast to those characters the user
	has pressed.  Is this a problem?
	*** Don't do half duplex for arrow keys chars.

	To handle the cursor keys I have to intercept all the accelerator
	chars.  So the events that I don't handle have to be sent back
	the the view

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 8/24/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenKeyboard		method	ScreenClass, 		MSG_META_KBD_CHAR
if USE_FEP
	tst	es:[fepStrategy].segment
	jz	noFep
	;
	; If it is a press send it to the FEP.
	;
	test	dl, mask CF_RELEASE
	jnz	noFep
	;
	; Initialize error flag
	;
	mov	es:[scrKbdFepNoPortErr], BB_FALSE
	;
	; Pass call back information on the stack.
	;
	sub	sp, size FepCallBackInfo
	mov	di, sp
	mov 	ax, segment ScreenFepCallBack
	mov	bx, offset ScreenFepCallBack
	movdw	ss:[di].FCBI_function, axbx
	mov	ax, ds:[LMBH_handle]
	movdw	ss:[di].FCBI_data, axsi
	movdw	axbx, ssdi
	mov	di, DR_FEP_KBD_CHAR
	call	es:[fepStrategy]
	add 	sp, size FepCallBackInfo
	;
	; Check return value: iff al = 0 consume the character.
	;
	tst	al
	LONG jz	exitFepConsumed
noFep:
endif
	test	dl, mask CF_TEMP_ACCENT		; accent char pending?
	jnz	jmpUnused			; yes, ignore it
	test	dl, mask CF_FIRST_PRESS		;if not FIRST or REPEAT
	jnz	checkState			;  keypress then 
	test	dl, mask CF_REPEAT_PRESS	;  exit
	jnz	checkState			;else, process it
jmpUnused:
	jmp	unused
checkState:
SBCS <	cmp	ch, CS_CONTROL			;if this is a CTRL char then>
DBCS <	cmp	ch, CS_CONTROL_HB		;if this is a CTRL char then>
	je	checkArrow			; check for ARROW or NUM key
						; else this is regular char
	and	dh, mask SS_LCTRL or mask SS_RCTRL
						;  if CTRL key pressed
;	jz	10$ 				;  then convert it
;allow all characters to be sent from keyboard - brianc 1/3/91
	jz	writeIt
if DBCS_PCGEOS	;-------------------------------------------------------------
	and	cx, CTRL_MASK			; cx = control char
checkArrow:
	cmp	cx, C_SYS_UP
	jb	checkCtrl
	cmp	cx, C_SYS_HOME
	LONG ja	checkBreak
	call	DoArrowKey
	jmp	exit
checkCtrl:
	cmp	cx, C_SPACE			; allow true control chars
	jb	writeIt
	cmp	cx, C_SYS_F1
	jae	jmpUnused
	mov	ax, cx				; ax = control char
	push	es, di, cx
	segmov	es, cs
	mov	di, offset mapKeyTable		; table of keys to map
	mov	cx, length mapKeyTable
	repne	scasw
	pop	es, di, cx
	jne	jmpUnused			; not found, send it back up
						; else, map and process
	mov	ch, 0				; cx = control char - 0xee00
else	;---------------------------------------------------------------------

	and	cl, CTRL_MASK			; convert char to Ctrl char
						; if applied
RSP <	jmp	checkArrowWithoutKeymap					>
;10$:
;	cmp	cl, 080h
;	jb	writeIt
;	jmp	unused

checkArrow:
RSP <	call	InputKeyMap			; cx = mapped key	>

checkArrowWithoutKeymap::
	cmp	cl, VC_UP
	jb	checkCtrl
	cmp	cl, VC_HOME
	ja	checkBreak
	call	DoArrowKey			;
	jmp	exit				;
checkCtrl:
	cmp	cl, 080h			;if illegal char, forget it
	LONG jae unused
endif	;---------------------------------------------------------------------
writeIt:
	mov	si, ds:[si]			;deref obj ptr
	mov	di, ds:[si][SI_gState]		;  and get gState	
	cmp	ds:[si][SI_inScroll], FALSE	;if we scrolled away from
	je	noScroll			;  window, then reset the
	push	cx, dx				;  view before sending output
	call	ScrollResetView			;
	pop	cx, dx				;restore keyboard char flags  
noScroll:
	;
	; convert char from GEOS code page to BBS code page, if needed
	;	cx = GEOS char
	;
if DBCS_PCGEOS	;-------------------------------------------------------------
	mov	bx, es:[serialPort]		; check port first
	cmp	bx, NO_PORT
	LONG je	noPort
	push	ds, si
	segmov	ds, ss, si
EC <	mov	di, es							>
EC <	cmp	di, si							>
EC <	ERROR_NE	-1						>
	push	cx				; put GEOS character on stack
	mov	si, sp				; ds:si = source
	sub	sp, 6				; plenty of room for expansion
	mov	di, sp				; es:di = dest
	mov	cx, 1				; 1 GEOS char
	mov	ax, MAPPING_DEFAULT_CHAR
	mov	bx, ds:[bbsSendCP]
;don't do this as it sends unnecessary things though - brianc 11/29/94
if 0
	;
	; force synchronization to SB mode if CR
	;
	cmp	bx, CODE_PAGE_JIS		; think we are in SB mode?
	jne	noSync				; nope, continue
	cmp	{wchar} ds:[si], CHAR_CR	; will be sending CR?
	jne	noSync				; nope, continue
	mov	bx, CODE_PAGE_JIS_DB		; else, pretend we are in DB
						;	mode, so we will turn
						;	on SB mode
noSync:
endif

	clr	dx
	call	LocalGeosToDos			; cx = new size of text (bytes)
EC <	WARNING_C	KBD_CONVERSION_ERROR				>
	jc	dbcsErr
	mov	ds:[bbsSendCP], bx

	;
	; write bytes one at a time in loop, can't write bytes all at once,
	; cause there's nowhere safe to store them
	;
	mov	si, di				; ds:si = BBS chars
	push	si, cx				; save count for echo
sendLoop:
if	_TELNET
	lodsb					; al <- char
	mov_tr	cl, al
	call	SendChar			; carry set if error
else
	push	cx				; save count
	lodsb					; al <- char
	mov	cl, al				; cl = BBS char
	mov	bx, ds:[serialPort]
	mov	ax, STREAM_BLOCK
	CallSer	DR_STREAM_WRITE_BYTE, ds
	pop	cx
endif	; _TELNET
		
	loop	sendLoop
	pop	si, cx				; si = offset, cx = count

	;
	; echo if half-duplex, echo bytes one at a time in loop, can't echo
	; bytes all at once, cause there's nowhere safe to store them
	;	ds = dgroup
	;	ds:si = chars
	;	cx = # chars
	;
	cmp	ds:[halfDuplex], TRUE
	jne	noEcho
	;
	; maintain current bbsRecvCP by switching into mode of character to
	; send (i.e. bbsSendCP) and then switching back
	;
	push	ds:[bbsRecvCP]			; save bbsRecvCP because it
						;	will be modified by
						;	FSMParseString sometime
						;	after echoEscape
	call	StartEcho
echoLoop:
	push	cx
	lodsb
	mov	cl, al				; cl = byte to echo
	mov	ax, MSG_READ_CHAR
	SendSerialThread
	pop	cx
	loop	echoLoop
	;
	; escape back to bbsRecvCP
	;
	pop	ax				; ax = desired CP (bbsRecvCP)
	call	EndEcho
noEcho:

dbcsErr:
	add	sp, 8				; clear stack
	pop	ds, si
else	;---------------------------------------------------------------------
	mov	al, cl				; al = character
	cmp	al, MIN_MAP_CHAR		; any conversion needed?
	jb	noConv				; nope
	clr	ah
	mov	bx, MAPPING_DEFAULT_CHAR	; default character
	push	cx
	mov	cx, es:[bbsCP]			; bx = destination code page
	call	LocalGeosToCodePageChar
	pop	cx
noConv:
if INPUT_OUTPUT_MAPPING
	call	OutputMapChar
endif

	clr	ah
	test	ds:[si].SI_modeFlags, mask SVTMF_LF_NEWLINE
	jz	crLfLoop
	mov	ah, TRUE	
crLfLoop:
if	_TELNET
	cmp	al, C_CR
	jne	sendNonCR
	call	SendCR
	jmp	sentOneChar
	
sendNonCR:
	push	ax				; ah = crlf mode, al = char
	mov_tr	cl, al
	push	ds
	segmov	ds, es, ax			; ds <- dgroup
	call	SendChar			; carry set if error
	pop	ds
	
else	; _TELNET
	mov	bx, es:[serialPort]
	cmp	bx, NO_PORT			;if no port opened?
	je	noPort				;   then exit 

	push	ax				; ah = crlf mode, al = char
	mov_tr	cl, al				; cl = char to send
	mov	ax, STREAM_BLOCK		;block, if necessary
	CallSer	DR_STREAM_WRITE_BYTE, es	;else  write char out the line	
endif	; !_TELNET
	pop	ax				  ; get crlf mode, char

sentOneChar::
	cmp	al, C_CR			  ; IF just sent CR,
	jne	doneSending
	tst	ah				  ; AND in LF mode,
	jz	doneSending			  
	mov	al, C_LF			  ; THEN send an LF
	jmp	crLfLoop
doneSending:
			
	cmp	es:[halfDuplex], TRUE		;
	jne	exit				;
if	not _TELNET
	mov	ax, MSG_READ_CHAR		;if in local echo
	SendSerialThread
endif	; !_TELNET
	
endif	;---------------------------------------------------------------------
	jmp	short exit
checkBreak:
SBCS <	cmp	cl, VC_BREAK			;if BREAK key was pressed>
DBCS <	cmp	cx, C_SYS_BREAK			;if BREAK key was pressed>
	jne	unused				;then send Serial Break Signal
	segmov	ds, es, bx			;ds->dgroup
	
if	not _TELNET
	CallMod	SendSerialBreak
endif
	
	jmp	exit
noPort:
	call	noPortError
unused:						;keyboard chars we don't
	mov	ax,MSG_META_FUP_KBD_CHAR 		;handle should be passed
RSP <	SendScreenView							>
NRSP <	CallScreenView				;back to the view	>
exit:
	ret

if USE_FEP
exitFepConsumed:
	tst	es:[scrKbdFepNoPortErr]
	jz	exit
	call	noPortError
	ret
endif

noPortError	label	near
	push	cx, dx				;save character flags
	clr	cx				;flag that String resource
	mov	dx, offset keyCharErr		;	should be stuffed  
	mov	bp, ERR_NO_COM
	segmov	ds, es, ax			;make ds- dgrup
	CallMod	DisplayErrorMessage	
	pop	cx, dx	
	retn

RSP < ScreenKbdCharReal	endm						>
NRSP < ScreenKeyboard	endm						>

if DBCS_PCGEOS
mapKeyTable	wchar	C_SYS_BACKSPACE, C_SYS_TAB, C_SYS_ENTER, C_SYS_ESCAPE,
			C_SYS_NUMPAD_ENTER, C_SYS_NUMPAD_DIVIDE,
			C_SYS_NUMPAD_MULTIPLY, C_SYS_NUMPAD_PLUS,
			C_SYS_NUMPAD_MINUS, C_SYS_NUMPAD_PERIOD,
			C_SYS_NUMPAD_0, C_SYS_NUMPAD_2, C_SYS_NUMPAD_2,
			C_SYS_NUMPAD_3, C_SYS_NUMPAD_4, C_SYS_NUMPAD_5,
			C_SYS_NUMPAD_6, C_SYS_NUMPAD_7, C_SYS_NUMPAD_8,
			C_SYS_NUMPAD_9
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenNormalizePos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure scroll bar scrolls by lines, not pixels

CALLED BY:	MSG_META_CONTENT_TRACK_SCROLLING

PASS:		*ds:si			- instance data
		ss:bp			- TrackScrollingParams
		dx			- size TrackScrollingParams
		cx			- Chunk Handle of scroll bar

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		look at OLTextDisplayNormalizePosition for example

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Only normalizes dragging in vertical direction.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/23/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
ScreenNormalizePos 	method	ScreenClass, 	MSG_META_CONTENT_TRACK_SCROLLING
	call	GenSetupTrackingArgs		;set up all the normalize stuff
	mov     si, ds:[si]                     ;dereference ptr to screen obj
	mov	ax, ss:[bp].TSP_change.PD_y		;get scroll amount
	cmp	ax, 0				;if negative scroll amount
	je	doScroll
	jg	10$				;
	neg	ax				;convert to positive #
10$:
	mov	bx, ds:[si][SI_lineHeight]	;is scroll a multiple of
	div	bl				;line height?
	tst	ah				;	
	jz	doScroll			;yes, exit
	sub	bl, ah				;no,
	cmp	ss:[bp].TSP_change.PD_y, 0		;
	jl	scrollUp			;
	add	ss:[bp].TSP_change.PD_y, bx		;normalize downward scroll
	jmp	short doScroll			;
scrollUp:					;
	sub	ss:[bp].TSP_change.PD_y, bx		;normalize upward scroll
doScroll:					;
	call	GenReturnTrackingArgs		;return the arguments
	ret
ScreenNormalizePos	endm
endif 


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	kill screen object program

CALLED BY:	MSG_SCR_EXIT

PASS:		nothing

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		free memory blocks

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 8/22/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenExit	method	ScreenClass, MSG_SCR_EXIT
	mov	si, ds:[si]
	mov	bx, ds:[si][SI_cacheHandle]	;nuke our file cache
	tst	bx
	jz	noCache
	call	MemFree
noCache:
	mov	bx, ds:[si][SI_screenHandle]	;nuke our screen buffer
	tst	bx
	jz	noScreen
	call	MemFree
noScreen:
	mov	bx, ds:[si][SI_scrollHandle]	;nuke the scroll buffer	
	tst	bx
	jz	noScroll
	call	MemFree
noScroll:
	ret
ScreenExit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSoundBell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ring a bell 

CALLED BY:	MSG_SCR_SOUND_BELL

PASS:		ds:*si		- screen instance data
		es		- dgroup
		[SI_screenBuf]	- pointing to unlocked segment

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/24/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
							
ScreenSoundBell	method	ScreenClass, MSG_SCR_SOUND_BELL
	mov	si, ds:[si]			;deref to instance data
	cmp	ds:[si][SI_visualBell], TRUE
	je	visBell
	mov	ax, SST_CUSTOM_NOTE
	mov	cx, BELL_FREQ
	mov	dx, BELL_DUR

	call	UserStandardSound
	jmp	short exit
visBell:
	mov	di, ds:[si][SI_gState]		;get GState
	call	DoVisualBell	
exit:
	ret
ScreenSoundBell		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenVisualBell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	make screen flash a bell 

CALLED BY:	MSG_SCR_VISUAL_BELL

PASS:		ds:*si		- screen instance data
		es		- dgroup
		[SI_screenBuf]	- pointing to unlocked segment

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		Calling audio bell temporarily

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
							
ScreenVisualBell	method	ScreenClass, MSG_SCR_VISUAL_BELL
;;	call	ScreenSoundBell	
;;they are using visual for a reason... - brianc 8/17/90
	mov	si, ds:[si]		; deref.
	mov	di, ds:[si].SI_gState
	call	DoVisualBell
	ret
ScreenVisualBell		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenCursorLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a backspace character

CALLED BY:	MSG_SCR_CURSOR_LEFT

PASS:		ds:*si		- screen instance data
		es		- dgroup
		[SI_screenBuf]	- pointing to unlocked segment

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/04/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenCursorLeft	method	ScreenClass, MSG_SCR_CURSOR_LEFT
	mov	si, ds:[si]			;deref to instance data
NCUR <	tst	ds:[si][SI_curChar]		;if cursor at start of line>
CUR <	tst	ds:[si][SI_curPos]					>
	jz	exit				;	don't decrement it
	mov	di, ds:[si][SI_gState]
	call	EraseCursor
NCUR <	dec	ds:[si][SI_curChar]		;adjust cursor position	>
CUR <	dec	ds:[si][SI_curPos]					>
CUR <	call	GetCurCharFromCurPos					>
	call	DrawCursor
exit:
	ret
ScreenCursorLeft	endm

ScreenCursorLeftN	method	ScreenClass, MSG_SCR_CURSOR_LEFT_N
	clr	cl
	xchg	cl, ch				; cx = N
	tst	cx
	jnz	doIt
	inc	cx				; move even when arg=0
doIt:
	mov	si, bx
NCUR <	tst	ds:[si].SI_curChar					>
CUR <	tst	ds:[si][SI_curPos]					>
	jz	exit
	mov	di, ds:[si].SI_gState
	push	cx				; save N
	call	EraseCursor
	pop	cx				; restore N
NCUR <	sub	ds:[si].SI_curChar, cx					>
CUR <	sub	ds:[si].SI_curPos, cx					>
	jge	onScreen
NCUR <	clr	ds:[si].SI_curChar		; else, force to 0	>
CUR <	clr	ds:[si].SI_curPos					>
onScreen:
CUR <	call	GetCurCharFromCurPos					>
	call	DrawCursor
exit:
	ret
ScreenCursorLeftN	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a tab character

CALLED BY:	MSG_SCR_TAB

PASS:		ds:*si		- screen instance data
		es		- dgroup
		[SI_screenBuf]	- pointing to unlocked segment

RETURN:		nothing

DESTROYED:	si, di, cx

PSEUDO CODE/STRATEGY:
		Assume Tab stops set every TAB_STOP places so
		want to calculate how many cols till next tab
		and advance cursor that many columns.
		# spaces to add = TABSTOP - (column pos / TAB_STOP)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Don't allow user to tab past the end of line

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/04/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenTab	method	ScreenClass, MSG_SCR_TAB
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]
	call	EraseCursor
if HALF_AND_FULL_WIDTH	;-----------------------------------------------------
if CURSOR
	mov	ch, {byte} ds:[si][SI_curPos]	;get current col # (only byte)
	and	ch, DIV_8_MASK 			;find out how many space)
	mov	cl, TAB_STOP			;till next tab stop
	sub	cl, ch
	clr	ch
	add	cx, ds:[si][SI_curPos]		;get new cursor position
	cmp	cx, MAX_LINE_CHARS		;if cursor past end of line
	jg	exit				;don't update it
	mov	ds:[si][SI_curPos], cx		;
	call	GetCurCharFromCurPos
exit:
else
	push	ax, bx, dx
	call	CalcCursorPos			; ax = X pos, bx = Y pos
	mov	dx, bx				; dx = Y pos
	mov	cl, {byte} ds:[si].SI_charWidth
	div	cl				; ax = char column
	and	ax, not 7
	add	ax, 8
	cmp	ax, MAX_LINE_CHARS		; past end?
	jg	exit				; yes, do nothing
	mov	cl, {byte} ds:[si].SI_charWidth
	mul	cl				; ax = desired X pos
	mov	cx, ax				; cx = desired X pos
	call	ConvertToTextCoords		; cx = text column, dx = text
						;	line
EC <	mov	ax, ds:[si].SI_curLine					>
EC <	add	ax, ds:[si].SI_winTopLine				>
EC <	cmp	ax, dx							>
EC <	ERROR_NE	-1						>
	mov	ds:[si].SI_curChar, cx		; new cursor position
exit:
	pop	ax, bx, dx
endif
else	;---------------------------------------------------------------------
	mov	ch, {byte} ds:[si][SI_curChar];get current col # (only byte)	
	and	ch, DIV_8_MASK 			;find out how many spaces	
	mov	cl, TAB_STOP			;till next tab stop
	sub	cl, ch
	clr	ch
	add	cx, ds:[si][SI_curChar]		;get new cursor position
	cmp	cx, MAX_LINE_CHARS		;if cursor past end of line
	jg	exit				;don't update it
	mov	ds:[si][SI_curChar], cx		;
exit:
endif	;---------------------------------------------------------------------
	call	DrawCursor
	ret
ScreenTab	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenCursorDownOrScroll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move cursor down 1 row.  If already at bottom of
		scroll region, scroll the region up.  If cursor is
		below the scroll region, will not scroll (VT100 behavior)

CALLED BY:	MSG_SCR_CURSOR_DOWN

PASS:		ds:*si		- screen instance data
		es		- dgroup
		[SI_screenBuf]	- pointing to unlocked segment

RETURN:		nothing

DESTROYED:	es

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

	This was formerly MSG_SCR_CURSOR_DOWN, but it does more
	than just move the cursor down. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/04/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenCursorDownOrScroll	method	ScreenClass, MSG_SCR_CURSOR_DOWN_OR_SCROLL
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]
NCUR <	cmp	ds:[si][SI_curChar], MAX_LINE_CHARS			>
CUR <	cmp	ds:[si][SI_curPos], MAX_LINE_CHARS			>
	jne	10$
	clr	ds:[si][SI_curChar]		;if LF comes in at 81 column
						;then autowrap
CUR <	clr	ds:[si][SI_curPos]					>
10$:
	call	EraseCursor
if (HALF_AND_FULL_WIDTH and not CURSOR)
	call	CalcCursorPos			;ax = X pos, bx = Y pos
	push	ax, bx
	call	DoCursorDown
	pop	cx, dx
	add	dx, ds:[si].SI_lineHeight
	call	ConvertToTextCoords		;cx = column, dx = line
	mov	ds:[si].SI_curChar, cx		;store new column
else
	call	DoCursorDown
endif
CUR <	call	GetCurCharFromCurPos					>
	call	DrawCursor
exit:
	ret
ScreenCursorDownOrScroll	endm

ScreenCursorDownOrScrollN	method	ScreenClass, MSG_SCR_CURSOR_DOWN_OR_SCROLL_N
	clr	cl
	xchg	cl, ch				; cx = N
	jcxz	exit
	mov	si, bx
	mov	di, ds:[si].SI_gState
	push	cx				; save N
	call	EraseCursor
	pop	cx				; restore N
if (HALF_AND_FULL_WIDTH and not CURSOR)
	call	CalcCursorPos			;ax = X pos, bx = Y pos
	push	ax, bx, cx
downLoop:
	push	cx
	call	DoCursorDown
	pop	cx
	loop	downLoop
	pop	cx, dx, bx			;cx = X pos, dx = Y pos, bx = N
	mov	ax, ds:[si].SI_lineHeight
	mul	bl				;ax = height of N lines
	add	dx, ax
	call	ConvertToTextCoords		;cx = column, dx = line
	mov	ds:[si].SI_curChar, cx		;store new column
else
downLoop:
	push	cx
	call	DoCursorDown
	pop	cx
	loop	downLoop
endif
CUR <	call	GetCurCharFromCurPos					>
	call	DrawCursor
exit:
	ret
ScreenCursorDownOrScrollN	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenCR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a CR character

CALLED BY:	MSG_SCR_CR

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		Move cursor to far left

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/04/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenCR	method	ScreenClass, MSG_SCR_CR
CCT <	GetResourceSegmentNS	dgroup, es				>
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]
	call	EraseCursor
	clr	ds:[si][SI_curChar]
CUR <	clr	ds:[si][SI_curPos]					>
	tst	ds:[si][SI_autoLinefeed]	;is auto line feed set
	jz	draw				;nope
	call	DoCursorDown			;yep, insert a CR
;always redraw cursor, as DoCursorDown doesn't do it - brianc
;	jnc	exit				;if scrolled don't draw cursor
draw:
	call	DrawCursor
	
DBCS <	mov	ax, CHAR_CR						>
SBCS <	mov	al, CHAR_CR						>

if	_CAPTURE_CLEAN_TEXT	;------------------------------------------
CaptureCR	label	far
	cmp	es:[fileHandle], BOGUS_VAL
	je	dontCapture
if	ERROR_CHECK
SBCS <	mov	ah, -1				; make high byte null	>
endif	
	call	FileCaptureTextChar		; destroy ax,bx,cx,dx,si,di,
						;   ds, es
dontCapture:
	
endif	; _CAPTURE_CLEAN_TEXT	-------------------------------------------
	
exit:
	ret
ScreenCR	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenLF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles a linefeed character

CALLED BY:	MSG_SCR_LF
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		ds:bx	= ScreenClass object (same as *ds:si)
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	4/ 4/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenLF	method dynamic ScreenClass, 
					MSG_SCR_LF
CCT <	GetResourceSegmentNS	dgroup, es				>
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]
	call	EraseCursor
	call	DoCursorDown

	;
	; If linefeed/newline mode, append a newline
	;
	test	ds:[si][SI_modeFlags], mask SVTMF_LF_NEWLINE
	jz	afterNewline
	clr	ds:[si][SI_curChar]
CUR <	clr	ds:[si][SI_curPos]					>
afterNewline:
	call	DrawCursor
	
if	_CAPTURE_CLEAN_TEXT	;------------------------------------------

DBCS <	mov	ax, CHAR_LF						>
SBCS <	mov	al, CHAR_LF						>
	GOTO	CaptureCR
	
else	; _CAPTURE_CLEAN_TEXT	-------------------------------------------
	
	ret

endif
ScreenLF	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenNextLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves cursor down (scrolling if necessary), and
		puts cursor on first position.

CALLED BY:	MSG_SCR_NEXT_LINE
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		ds:bx	= ScreenClass object (same as *ds:si)
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenNextLine	method dynamic ScreenClass, 
					MSG_SCR_NEXT_LINE
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]
	call	EraseCursor
	clr	ds:[si][SI_curChar]		  ; Beginning of line
	call	DoCursorDown			  ; next line
	call	DrawCursor

	ret
ScreenNextLine	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenScrollTextDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a scroll down character

CALLED BY:	MSG_SCR_SCROLL_DOWN

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		Should combine this routine and CheckForScroll routines
		to make a common srollNLines routine.	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/04/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenScrollTextDown	method	ScreenClass, MSG_SCR_SCROLL_DOWN
	call	ScreenInsLine
	ret
ScreenScrollTextDown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenScrollTextUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a scroll up character

CALLED BY:	MSG_SCR_SCROLL_UP

PASS:		ds:*si		- screen instance data
		es		- dgroup
		[SI_screenBuf]  - unlocked segment


RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/02/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenScrollTextUp	method	ScreenClass, MSG_SCR_SCROLL_UP
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	push	di				; save it
	call	EraseCursor
	mov	bx, ds:[si][SI_screenHandle]	
	call	MemLock
	mov	ds:[si][SI_screenBuf], ax
	call	BufScrollUp			;scroll screen buf up
	call	BufClearLine			;clear out buffer line
	call	WinScrollUp			;scroll screen image up
	mov	bx, ds:[si][SI_screenHandle]	
	call	MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>
	pop	di				; retrieve gState
	call	DrawCursor			; show cursor
	ret
ScreenScrollTextUp	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenCursorUpOrScroll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move cursor up 1 row.  If already at top of scroll
		region, scroll region down.  If cursor is above
		the scroll region will not scroll (VT100 behavior)

CALLED BY:	MSG_SCR_CURSOR_UP_OR_SCROLL
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		ds:bx	= ScreenClass object (same as *ds:si)
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenCursorUpOrScroll	method dynamic ScreenClass, 
					MSG_SCR_CURSOR_UP_OR_SCROLL
	;
	; Cursor on top line of scroll region?
	;
		mov	ax, ds:[di].SI_curLine
		cmp	ax, ds:[di].SI_scrollRegTop
		je	scroll
	;
	; NO: just move up
		GOTO	ScreenCursorUp
scroll:
	;
	; YES: scroll region down (by inserting blank line on top)
	;
		call	ScreenInsLine
	ret
ScreenCursorUpOrScroll	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenCursorDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move cursor down 1 row, with no scrolling when it gets
		to the bootom of the screen or scorll area

CALLED BY:	MSG_SCR_CURSOR_DOWN
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		ds:bx	= ScreenClass object (same as *ds:si)
		es 	= segment of ScreenClass
		ax	= message #
		ch	= # lines to move down (if DOWN_N)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Currently only implements the VT100 behavior of the
	cursor-down commands.  You may have to modify this if
	your terminal does something different.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenCursorDown	method dynamic ScreenClass, 
					MSG_SCR_CURSOR_DOWN, MSG_SCR_CURSOR_DOWN_N
		cmp	ax, MSG_SCR_CURSOR_DOWN
		jne	haveN
		mov	ch, 1			; N = 1 for CURSOR_DOWN
haveN:
		clr	cl
		xchg	cl, ch			; cx = N
		tst	cx
		jnz	doIt
		inc	cx			; an argument of 0 still moves
						; the cursor
doIt:
		mov	si, ds:[si]
		add	cx, ds:[si][SI_curLine]	; cx = desired destination
	;
	; If original position is outside the scroll area, then downward
	; movement isn't constrained by it.
	;
		mov	ax, ds:[si][SI_curLine]
		cmp	ax, ds:[si][SI_scrollRegBot]
		ja	checkScreen
	;
	; Constrain to scroll area
	;
		cmp	cx, ds:[si][SI_scrollRegBot]
		jbe	checkScreen
		mov	cx, ds:[si][SI_scrollRegBot]
checkScreen:
	;
	; Constrain to physical screen
	;
		cmp	cx, MAX_LINES
		jb	newPos
		mov	cx, MAX_LINES-1
newPos:
		GOTO	CursorUpDownCommon

ScreenCursorDown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenCursorUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move cursor up 1 row, with no scrolling when it gets
		to the bootom of the screen or scorll area

CALLED BY:	MSG_SCR_CURSOR_UP
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		ds:bx	= ScreenClass object (same as *ds:si)
		es 	= segment of ScreenClass
		ax	= message #
		ch	= # lines to move up (if UP_N)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Currently only implements the VT100 behavior of the
	cursor-up commands.  You may have to modify this if
	your terminal does something different.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenCursorUp	method ScreenClass, 
				MSG_SCR_CURSOR_UP, MSG_SCR_CURSOR_UP_N
		cmp	ax, MSG_SCR_CURSOR_UP
		jne	haveN
		mov	ch, 1			; N = 1 for CURSOR_UP
haveN:
		clr	cl
		xchg	cl, ch			; cx = N
		tst	cx
		jnz	doIt
		inc	cx			; an argument of 0 still moves
						; the cursor
doIt:
		mov	si, ds:[si]
		sub	cx, ds:[si][SI_curLine]
		neg	cx			; cx = desired destination
	;
	; Constrain to screen
	;
		jns	constrainScroll		;   If < 0,
		clr	cx			; make 0
constrainScroll:
	;
	; If original position is outside the scroll area, then upward
	; movement isn't constrained by it.
	;
		mov	ax, ds:[si][SI_curLine]
		cmp	ax, ds:[si][SI_scrollRegTop]
		jb	newPos
	;
	; Constrain to scroll area
	;
		cmp	cx, ds:[si][SI_scrollRegTop]
		jae	newPos
		mov	cx, ds:[si][SI_scrollRegTop]
newPos:
		FALL_THRU	CursorUpDownCommon
ScreenCursorUp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CursorUpDownCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Completes cursor positioning for UP/DOWN commands

CALLED BY:	(INTERNAL) ScreenCursorUp, ScreenCursorDown
PASS:		ds:si	= ScreenClass instance data
		cx	= new value for SI_curLine
RETURN:		nothing
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CursorUpDownCommon	proc	far
	class	ScreenClass

	;
	; If the cursor is in the phantom 81'st column, 
	; an up/down ALWAYS puts it back in the 80th (even if
	; the cursor didn't actually move up or down)
	;
		cmp	ds:[si][SI_curChar], MAX_LINE_CHARS
		jb	doDraw
EC <		ERROR_A	TERM_ERROR_INVALID_CURSOR_POSITION		>
		mov	ds:[si][SI_curChar], MAX_LINE_CHARS-1
doDraw:
	;
	; Optimization: If cursor didn't physically move, don't bother
	; drawing it.
	;
		cmp	cx, ds:[si][SI_curLine]
		je	exit

		mov	di, ds:[si][SI_gState]
		push	cx
		call	EraseCursor
		pop	cx

		mov	ds:[si][SI_curLine], cx
		call	DrawCursor
exit:
		ret
CursorUpDownCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenClearHomeCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a clear screen and home cursor terminal sequence

CALLED BY:	MSG_SCR_CLEAR_HOME_CURSOR

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		We want to clear the screen and home the cursor, 
		already have method handlers to do this so just call them

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/04/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenClearHomeCursor	method	ScreenClass, MSG_SCR_CLEAR_HOME_CURSOR
	push	si				;save ptr to instance data
	call	ScreenHomeCursor
	pop	si				;restore ptr 
	call	ScreenClearToEndDisplay		;  and call method handler
	ret
ScreenClearHomeCursor	endm

if	_CLEAR_SCR_BUF

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenClearScreenAndScrollBuf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear screen and scroll buffer

CALLED BY:	MSG_SCR_CLEAR_SCREEN_AND_SCROLL_BUF
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		carry set if not enough memory
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Clear screen;
	Clear scroll buffer;
	Set view to the top;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	10/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenClearScreenAndScrollBuf	method dynamic ScreenClass, 
					MSG_SCR_CLEAR_SCREEN_AND_SCROLL_BUF
	.enter
	
	call	ScreenClearHomeCursor		; clear screen
	call	ScreenClearScreenAndScrollBufResetParams	
	
	;
	; Clear scroll buffer
	;
	call	ScreenClearScrollBuf		; carry set if can't realloc
						; scroll buffer
	pushf
	call	ResetView			; set view to top of doc
	popf
	
	.leave
	ret
ScreenClearScreenAndScrollBuf	endm

endif	; _CLEAR_SCR_BUF


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenCursorUpUnconstrained
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves cursor up <n> lines in the same column, without
		regard for the scroll area.

CALLED BY:	MSG_SCR_CURSOR_UP_UNCONSTRAINED

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/04/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenCursorUpUnconstrained	method	ScreenClass, MSG_SCR_CURSOR_UP_UNCONSTRAINED

	mov	si, ds:[si]			;deref to instance data
	tst	ds:[si][SI_curLine]		;if cursor at top of screen
	je	exit				; bug out
	mov	di, ds:[si][SI_gState]		;get GState
	call	EraseCursor
if (HALF_AND_FULL_WIDTH and not CURSOR)
	call	CalcCursorPos			;ax = X pos, bx = Y pos
	dec	ds:[si].SI_curLine		;move cursor up one line
	mov	cx, ax
	mov	dx, bx
	sub	dx, ds:[si].SI_lineHeight
	call	ConvertToTextCoords		;cx = column, dx = line
EC <	mov	ax, ds:[si].SI_curLine					>
EC <	add	ax, ds:[si].SI_winTopLine				>
EC <	cmp	ax, dx							>
EC <	ERROR_NE	-1						>
	mov	ds:[si].SI_curChar, cx		;store new column
else
	dec	ds:[si][SI_curLine]		;move cursor up one line
endif
CUR <	call	GetCurCharFromCurPos					>
	call	DrawCursor
exit:
	ret
ScreenCursorUpUnconstrained	endm

ScreenCursorUpNUnconstrained	method	ScreenClass, MSG_SCR_CURSOR_UP_N_UNCONSTRAINED
	clr	cl
	xchg	cl, ch				; cx = N
	jcxz	exit
	mov	si, bx
	tst	ds:[si].SI_curLine
	jz	exit
	mov	di, ds:[si].SI_gState
	push	cx				; save N
	call	EraseCursor
	pop	cx				; restore N
if (HALF_AND_FULL_WIDTH and not CURSOR)
	call	CalcCursorPos			;ax = X pos, bx = Y pos
	sub	ds:[si].SI_curLine, cx
	jge	onScreen
	clr	ds:[si].SI_curLine		; else, force to 0
onScreen:
	mov	dx, cx				;dx = N
	mov	cx, ds:[si].SI_lineHeight
	xchg	cx, ax				;ax = line height, cx = X pos
	xchg	dx, bx				;dx = Y pos, bx = N
	mul	bl				;ax = height of N lines
	sub	dx, ax
	call	ConvertToTextCoords		;cx = column, dx = line
EC <	mov	ax, ds:[si].SI_curLine					>
EC <	add	ax, ds:[si].SI_winTopLine				>
EC <	cmp	ax, dx							>
EC <	ERROR_NE	-1						>
	mov	ds:[si].SI_curChar, cx		;store new column
else
	sub	ds:[si].SI_curLine, cx
	jge	onScreen
	clr	ds:[si].SI_curLine		; else, force to 0
onScreen:
endif
CUR <	call	GetCurCharFromCurPos					>
	call	DrawCursor
exit:
	ret
ScreenCursorUpNUnconstrained	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenCursorRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a cursor right terminal sequence

CALLED BY:	MSG_SCR_CURSOR_RIGHT

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	If cursor already at end of line can't advance it any more.
	If in phantom 81'st column, bring it back to the 80th
		(VT100 behavior)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/04/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenCursorRight	method	ScreenClass, MSG_SCR_CURSOR_RIGHT
	mov	si, ds:[si]			;deref to instance data
NCUR <	cmp	ds:[si][SI_curChar], MAX_LINE_CHARS-1			>
CUR <	cmp	ds:[si][SI_curPos], MAX_LINE_CHARS-1			>
	je	exit
	jl	moveIt
NCUR <	mov	ds:[si][SI_curChar], MAX_LINE_CHARS-2			>
CUR <	mov	ds:[si][SI_curPos], MAX_LINE_CHARS-2			>
moveIt:
	mov	di, ds:[si][SI_gState]		;get GState
	call	EraseCursor
NCUR <	inc	ds:[si][SI_curChar]					>
CUR <	inc	ds:[si][SI_curPos]					>
CUR <	call	GetCurCharFromCurPos					>
	call	DrawCursor
exit:
	ret
ScreenCursorRight	endm

ScreenCursorRightN	method	ScreenClass, MSG_SCR_CURSOR_RIGHT_N
	clr	cl
	xchg	cl, ch				; cx = N

	tst	cx
	jnz	doIt
	inc	cx				; move even when arg=0
doIt:
	mov	si, bx

NCUR <	cmp	ds:[si].SI_curChar, MAX_LINE_CHARS-1	; valid?	>
CUR <	cmp	ds:[si].SI_curPos, MAX_LINE_CHARS-1			>
	je	exit

	mov	di, ds:[si].SI_gState
	push	cx				; save N
	call	EraseCursor
	pop	cx				; restore N
NCUR <	add	ds:[si].SI_curChar, cx					>
NCUR <	cmp	ds:[si].SI_curChar, MAX_LINE_CHARS	; valid?	>
CUR <	add	ds:[si].SI_curPos, cx					>
CUR <	cmp	ds:[si].SI_curPos, MAX_LINE_CHARS			>
	jl	onScreen				; yes
NCUR <	mov	ds:[si].SI_curChar, MAX_LINE_CHARS-1	; force on screen>
CUR <	mov	ds:[si].SI_curPos, MAX_LINE_CHARS-1			>
CUR <	call	GetCurCharFromCurPos					>
onScreen:
	call	DrawCursor
exit:
	ret
ScreenCursorRightN	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenHomeCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a home cursor terminal sequence

CALLED BY:	MSG_SCR_HOME_CURSOR

PASS:		ds:*si		- screen instance data

RETURN:		nothing

DESTROYED:	ax, bp, es

PSEUDO CODE/STRATEGY:
		Delete the diplayed lines from scroll buffer
		Adjust cursor position

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Should be modified to clear tabstops

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenHomeCursor	method	ScreenClass, MSG_SCR_HOME_CURSOR
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	call	EraseCursor
	clr	cx
	mov	ds:[si][SI_curChar], cx
CUR <	mov	ds:[si][SI_curPos], cx					>
	mov	ds:[si][SI_curLine], cx
	call	DrawCursor
	ret
ScreenHomeCursor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenClearToEndDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear screen from cursor to end of display

CALLED BY:	MSG_SCR_CLEAR_TO_END_DISP

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/04/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenClearToEndDisplay	method	ScreenClass, MSG_SCR_CLEAR_TO_END_DISP
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	push	di				; save it
	call	EraseCursor			;flag cursor nuked
	call	WinClearToEnd			;clear the screen display

      	mov     bx, ds:[si][SI_screenHandle]	;lock screen buffer
	call    MemLock
	mov     ds:[si][SI_screenBuf], ax
	call	BufClearToEndLine		; clear rest of current line
	mov     bx, ds:[si][SI_screenHandle]    ;unlock stinking block
	call    MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>


	inc	ds:[si][SI_curLine]		
	call	BufClear			;clear all lines below
	dec	ds:[si][SI_curLine]
	pop	di				; retrieve gState
	call	DrawCursor			; show cursor
	ret
ScreenClearToEndDisplay	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenClearToEndLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear screen from cursor to end of current line

CALLED BY:	MSG_SCR_CLEAR_TO_END_LINE

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		To clear the line we blank out the rest of the line.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/04/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenClearToEndLine	method	ScreenClass, MSG_SCR_CLEAR_TO_END_LINE
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	call	EraseCursor

	mov	bx, ds:[si][SI_screenHandle]	
	call	MemLock
	mov	ds:[si][SI_screenBuf], ax

	call	EraseRemLine			;erase the line on the screen
	call	BufClearToEndLine
	mov     ax, MAX_LINE_CHARS		;pass #chars to draw
	sub	ax, ds:[si][SI_curChar]	
	call	DrawRemLine			;draw the line of blanks
	mov	bx, ds:[si][SI_screenHandle]	
	call	MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>
	call	DrawCursor
	ret
ScreenClearToEndLine	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenClearToBegLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears current line from first column to cursor (inclusive)

CALLED BY:	MSG_SCR_CLEAR_TO_BEG_LINE
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		ds:bx	= ScreenClass object (same as *ds:si)
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenClearToBegLine	method dynamic ScreenClass, 
					MSG_SCR_CLEAR_TO_BEG_LINE
	.enter

	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	call	EraseCursor

	mov	bx, ds:[si][SI_screenHandle]	
	call	MemLock
	mov	ds:[si][SI_screenBuf], ax

	call	EraseBegLine			;erase the line on the screen
	call	BufClearToBegLine

	mov	bx, ds:[si][SI_screenHandle]	
	call	MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>
	call	DrawCursor

	.leave
	ret

ScreenClearToBegLine	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenClearToBegDisp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears chars from upper left of disp to cursor (inclusive)

CALLED BY:	MSG_SCR_CLEAR_TO_BEG_DISP
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		ds:bx	= ScreenClass object (same as *ds:si)
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenClearToBegDisp	method dynamic ScreenClass, 
					MSG_SCR_CLEAR_TO_BEG_DISP
	.enter

	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	push	di				; save it
	call	EraseCursor			;flag cursor nuked
	call	WinClearToBeg			;clear the screen display

      	mov     bx, ds:[si][SI_screenHandle]	;lock screen buffer
	call    MemLock
	mov     ds:[si][SI_screenBuf], ax
	call	BufClearToBegLine		; clear rest of current line
	mov     bx, ds:[si][SI_screenHandle]    ;unlock stinking block
	call    MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>

	dec	ds:[si][SI_curLine]
	js	resetLine
	call	BufClearUpward			;clear all lines above
resetLine:
	inc	ds:[si][SI_curLine]
	pop	di				; retrieve gState
	call	DrawCursor			; show cursor

	.leave
	ret

ScreenClearToBegDisp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenClearLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears entire current line

CALLED BY:	MSG_SCR_CLEAR_LINE
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		ds:bx	= ScreenClass object (same as *ds:si)
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenClearLine	method dynamic ScreenClass, 
					MSG_SCR_CLEAR_LINE
	.enter

	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	push	di				; save it
	call	EraseCursor
	mov	bx, ds:[si][SI_screenHandle]	
	call	MemLock
	mov	ds:[si][SI_screenBuf], ax

	call	BufClearLine			;clear cur line in buffer
	call	WinClearLine			; clear line in window

	mov	bx, ds:[si][SI_screenHandle]	
	call	MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>
	pop	di				; retrieve gState
	call	DrawCursor			; redraw cursor

	.leave
	ret

ScreenClearLine	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Screen(Save/Restore)Curosr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	save cursor position, display enhancements, character set,
		end-of-line wrap state, selective erase state, and
		origin mode.
		
CALLED BY:	MSG_SCR_SAVE_CURSOR, MSG_SCR_RESTORE_CURSOR

PASS:		ds:*si		- screen instance data

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		DORKED : currently just save the character position	
		this is supposed to be vt220 only.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/31/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenSaveCursor	method	ScreenClass, MSG_SCR_SAVE_CURSOR
	mov	si, ds:[si]			;deref to instance data
	mov	ax, ds:[si][SI_curLine]
	mov	ds:[si][SI_saveCursorY], ax
NCUR <	mov	ax, ds:[si][SI_curChar]					>
CUR <	mov	ax, ds:[si][SI_curPos]					>
	mov	ds:[si][SI_saveCursorX], ax
	ret
ScreenSaveCursor	endm

ScreenRestoreCursor	method	ScreenClass, MSG_SCR_RESTORE_CURSOR
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	call	EraseCursor
	mov	ax, ds:[si][SI_saveCursorX]
EC <	cmp	ax, MAX_LINE_CHARS					>
EC <	ERROR_AE TERM_ERROR_INVALID_CURSOR_POSITION			>
NCUR <	mov	ds:[si][SI_curChar], ax					>
CUR <	mov	ds:[si][SI_curPos], ax					>
CUR <	call	GetCurCharFromCurPos					>
	mov	ax, ds:[si][SI_saveCursorY]
EC <	cmp	ax, MAX_LINES						>
EC <	ERROR_AE TERM_ERROR_INVALID_CURSOR_POSITION			>
	mov	ds:[si][SI_curLine], ax
	call	DrawCursor
	ret
ScreenRestoreCursor	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenChangeScrollReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scrolling region is the area between top and bottom 
		margins that moves during vertical scrolling.

CALLED BY:	MSG_SCR_CHANGE_SCROLLREG

PASS:		ds:*si		- screen instance data
		es		- dgroup
		ch		- scroll reg top 
		cl		- scroll reg bottom

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/31/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenChangeScrollReg	method	ScreenClass, MSG_SCR_CHANGE_SCROLLREG
	;
	; Scroll region bottom must be greater than scroll region top. If
	; not, skip operation.
	;
	cmp	ch, cl				;top >= bottom ?
	jae	done
	
	mov	si, ds:[si]			;deref to instance data
	clr	ah				;scroll region is byte value
	mov	al, ch			
	mov	ds:[si][SI_scrollRegTop], ax	;store scroll reg top
	mov	al, cl
	mov	ds:[si][SI_scrollRegBot], ax	;store scroll reg bot
done:
	ret
ScreenChangeScrollReg	endm
							;func 26

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenResetScrollReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the scroll region

CALLED BY:	MSG_SCR_RESET_SCROLLREG
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Reset object instance's data SI_scrollRegTop and SI_scrollRegBot

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	1/16/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenResetScrollReg	method dynamic ScreenClass, 
					MSG_SCR_RESET_SCROLLREG
		.enter

		mov	si, ds:[si]		; dssi <- instance data
	;
	; Default scroll region is whole screen
	;
		clr	ds:[si][SI_scrollRegTop]
		mov	ds:[si][SI_scrollRegBot], (MAX_LINES - 1)
	
		.leave
		ret
ScreenResetScrollReg	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenRelCursorMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the cursor relative to the screen

CALLED BY:	MSG_SCR_REL_CURSOR_MOVE

PASS:		ds:*si		- screen instance data
		es		- dgroup
		ch		- row position
		cl		- column position

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		Should I check for illegal (> 24,80) cursor coordinates, yes
		But not printing error message.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/04/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenRelCursorMove	method	ScreenClass, MSG_SCR_REL_CURSOR_MOVE
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	cmp	ch, MAX_LINES 			;is col value okay?
	jb	checkCol			;yep
	;
	; Since the arguments can \E[0;0H, LoadArgs may change deliver it as
	; -1, -1. So, we change it 0, 0 by default.
	;
	cmp	ch, -1				;set to zero row? 
	jne	setDefRow
	clr	ch				; default to 1st row
	jmp	checkCol
	
setDefRow:
	mov	ch, MAX_LINES - 1		;nope
	
checkCol:
	cmp	cl, MAX_LINE_CHARS		;is row value okay?
	jb	moveCursor
	cmp	cl, -1				;line# zero? (converted to -1)
	jne	setDefCol
	clr	cl				;default to 1st col
	jmp	moveCursor

setDefCol:
	mov	cl, MAX_LINE_CHARS - 1

;	jmp	short moveCursor
;error:
;	mov	bp, ERR_CURSOR_MOVE
;	segmov	ds, es, cx
;	CallMod	DisplayErrorMessage	
;	jmp	short exit
moveCursor:	
	mov	bp, cx				;save cursor coordinates
	call	EraseCursor			;erase the old cursor
	mov	cx, bp				;restore cursor pos
	clr	dh				
	mov	dl, ch				;get cursor's row position
	mov	ds:[si][SI_curLine], dx		;  and store it
	mov	dl, cl				;get cursor's col position
NCUR <	mov	ds:[si][SI_curChar], dx		;  and store it		>
CUR <	mov	ds:[si][SI_curPos], dx					>
CUR <	call	GetCurCharFromCurPos					>
	call	DrawCursor
CUR <EC <call	AssertCurCharCurPos					>>
exit:
	ret
ScreenRelCursorMove	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenInsLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a line at the current cursor position

CALLED BY:	MSG_SCR_INS_LINE

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		scroll rest of the window down one line

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenInsLine	method	ScreenClass, MSG_SCR_INS_LINE
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	push	di				; save it
	call	EraseCursor
	mov	bx, ds:[si][SI_screenHandle]	
	call	MemLock
	mov	ds:[si][SI_screenBuf], ax
	call	BufScrollDown			;add blank line to screen buf
	call	BufClearLine			;clear cur line in buffer
	call	WinScrollDown			;insert a line on the screen
	mov	bx, ds:[si][SI_screenHandle]	
	call	MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>
	pop	di				; retrieve gState
	call	DrawCursor			; redraw cursor
	ret
ScreenInsLine	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenBackTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the cursor backwards to the preceding tab position

CALLED BY:	MSG_SCR_BACK_TAB

PASS:		ds:*si		- screen instance data
		es		- dgroup
		ch		- # of tabs to back up

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		Move the cursor back to the prev tab stop

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/31/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenBackTab	method	ScreenClass, MSG_SCR_BACK_TAB
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]
NCUR <	tst	ds:[si][SI_curChar]		;if cursor at col 0 exit>
CUR <	tst	ds:[si][SI_curPos]					>
	je	SBT_ret
	call	EraseCursor
if HALF_AND_FULL_WIDTH	;-----------------------------------------------------
if CURSOR
	mov	cx, ds:[si][SI_curPos]		;get current col # 
	andnf	cl, DIV_8_MASK 			;how many spaces past tab
	tst	cl				;if not on tab then
	jne	SBT_sub				;	go to prev tab
	mov	cl, TAB_STOP			;till next tab stop
SBT_sub:
	mov	dx, ds:[si][SI_curPos]
	sub	dx, cx				;get new cursor position
	tst	dx				;make sure its valid	
	jl	exit
	mov	ds:[si][SI_curPos], dx		;update cursor position
	call	GetCurCharFromCurPos
exit:
else
	push	ax, bx, dx
	call	CalcCursorPos			; ax = X pos, bx = Y pos
	mov	dx, bx				; dx = Y pos
	mov	cl, {byte} ds:[si].SI_charWidth
	div	cl				; ax = char column
	mov	bx, ax
	and	ax, not 7
	tst	ax				; at beginning?
	jz	exit				; yes, do nothing
	test	bx, 7				; at tab stop before?
	jnz	haveTab				; nope, move to this tab stop
	sub	ax, 8				; else, move to previous stop
haveTab:
	mov	cl, {byte} ds:[si].SI_charWidth
	mul	cl				; ax = desired X pos
	mov	cx, ax				; cx = desired X pos
	call	ConvertToTextCoords		; cx = text column, dx = text
						;	line
EC <	mov	ax, ds:[si].SI_curLine					>
EC <	add	ax, ds:[si].SI_winTopLine				>
EC <	cmp	ax, dx							>
EC <	ERROR_NE	-1						>
	mov	ds:[si].SI_curChar, cx		; new cursor position
exit:
	pop	ax, bx, dx
endif
else	;---------------------------------------------------------------------
	mov	cx, ds:[si][SI_curChar]		;get current col # 
	andnf	cl, DIV_8_MASK 			;how many spaces past tab
	tst	cl				;if not on tab then
	jne	SBT_sub				;	go to prev tab
	mov	cl, TAB_STOP			;till next tab stop
SBT_sub:
	mov	dx, ds:[si][SI_curChar]
	sub	dx, cx				;get new cursor position
	tst	dx				;make sure its valid	
	jl	exit
	mov	ds:[si][SI_curChar], dx		;update cursor position
exit:
endif	;---------------------------------------------------------------------
	call	DrawCursor
SBT_ret:
	ret
ScreenBackTab	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenDelLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the line at the current cursor position

CALLED BY:	MSG_SCR_DEL_LINE

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		Scroll the rest of the window up one line to overwrite
		the current line.
	  ***	Blank out the bottom line, cause even if VI puts stuff
		to write there, with graphics not overwriting it'll
		look dorked.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenDelLine	method	ScreenClass, MSG_SCR_DEL_LINE
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	push	di				; save it
	call	EraseCursor		
	call	BufDelLine
	call	WinDelLine	
	pop	di				; retreive gState
	call	DrawCursor			; show cursor
	ret
ScreenDelLine	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenDelChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the char at the current cursor position

CALLED BY:	MSG_SCR_DEL_CHAR

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		Shift the current line starting from one past the 
		cursor postion back one character.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenDelChar	method	ScreenClass, MSG_SCR_DEL_CHAR
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	call	EraseCursor

	mov	bx, ds:[si][SI_screenHandle]	
	call	MemLock
	mov	ds:[si][SI_screenBuf], ax
	
	call	BufShiftLineLeft
	call	EraseRemLine			;HACK-no overstrike
	mov	ax, MAX_LINE_CHARS 
	sub	ax, ds:[si][SI_curChar]	
	call	DrawRemLine

	mov	bx, ds:[si][SI_screenHandle]	
	call	MemUnlock
EC <	call	NullScreenBuf			; stuff bogus segment	>

	call	DrawCursor
	ret
ScreenDelChar	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenInsChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a char at the current cursor position

CALLED BY:	MSG_SCR_INS_CHAR

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		Shift the line from the cursor on one postion to the right.
		Stick char at the current cursor position.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Is there a problem of the cursor being past the 80th char 	
		on a line?  Test wyse with a long line.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenInsChar	method	ScreenClass, MSG_SCR_INS_CHAR
	call	ScreenEnterInsMode
	ret
ScreenInsChar	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenEnterInsMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enter mode that inserts the following characters onto the
		screen.

CALLED BY:	MSG_SCR_ENTER_INS_MODE

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/26/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenEnterInsMode	method	ScreenClass, MSG_SCR_ENTER_INS_MODE
	mov	si, ds:[si]			;deref to instance data
	mov	ds:[si][SI_insertMode], TRUE 
	ret
ScreenEnterInsMode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenExitInsMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit mode that inserts the following characters onto the
		screen.

CALLED BY:	MSG_SCR_EXIT_INS_MODE

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenExitInsMode	method	ScreenClass, MSG_SCR_EXIT_INS_MODE
	mov	si, ds:[si]
	mov	ds:[si][SI_insertMode], FALSE
	ret
ScreenExitInsMode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Screen(Up,Down,Left,Right)Arrow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call routines to handle arrow movement keys

CALLED BY:	MSG_SCR_ARROW_(UP, DOWN, LEFT, RIGHT)

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenUpArrow	method	ScreenClass, MSG_SCR_UP_ARROW
	call	ScreenCursorUpUnconstrained
	ret
ScreenUpArrow	endm

ScreenDownArrow	method	ScreenClass, MSG_SCR_DOWN_ARROW
	call	ScreenCursorDownOrScroll
	ret
ScreenDownArrow	endm

ScreenRightArrow	method	ScreenClass, MSG_SCR_RIGHT_ARROW
	call	ScreenCursorRight
	ret
ScreenRightArrow	endm
							;func 9
ScreenLeftArrow	method	ScreenClass, MSG_SCR_LEFT_ARROW
	call	ScreenCursorLeft
	ret
ScreenLeftArrow	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenFunc(1,2,3,4)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call routines asscoiated with vt100 Function keys

CALLED BY:	MSG_SCR_FUNC_(1,2,3,4)

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenFunc1	method	ScreenClass, MSG_SCR_FUNC_1
	ret
ScreenFunc1	endm

							;func 11
ScreenFunc2	method	ScreenClass, MSG_SCR_FUNC_2
	ret
ScreenFunc2	endm

							;func 12
ScreenFunc3	method	ScreenClass, MSG_SCR_FUNC_3
	ret
ScreenFunc3	endm

							;func 13
ScreenFunc4	method	ScreenClass, MSG_SCR_FUNC_4
	ret
ScreenFunc4	endm

ScreenApplicationKeypad	method	ScreenClass, MSG_SCR_APPLICATION_KEYPAD
	BitSet	ds:[di][SI_modeFlags], SVTMF_KEYPAD
	ret
ScreenApplicationKeypad	endm

ScreenNumericKeypad	method	ScreenClass, MSG_SCR_NUMERIC_KEYPAD
	BitClr	ds:[di][SI_modeFlags], SVTMF_KEYPAD
	ret
ScreenNumericKeypad	endm

ScreenCursorOff	method	ScreenClass, MSG_SCR_CURSOR_OFF
	ret
ScreenCursorOff	endm

ScreenCursorOn	method	ScreenClass, MSG_SCR_CURSOR_ON
	ret
ScreenCursorOn	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenBoldOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn on BOLD screen attribute

CALLED BY:	MSG_SCR_BOLD_ON

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/04/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenBoldOn	method	ScreenClass, MSG_SCR_BOLD_ON
	mov	si, ds:[si]			;deref to instance data
	or	ds:[si][SI_attributes], mask CA_BOLD_LO
	ret
ScreenBoldOn	endm

ScreenUnderScoreOn	method	ScreenClass, MSG_SCR_UNDERSCORE_ON
	mov	si, ds:[si]			;deref to instance data
	or	ds:[si][SI_attributes], mask CA_UNDER_LO
	ret
ScreenUnderScoreOn	endm

ScreenBlinkOn	method	ScreenClass, MSG_SCR_BLINK_ON
;;replaced with CA_SELECTED - 8/21/90 brianc
;;(CA_BLINK has no effect anyway)
if 0
	mov	si, ds:[si]			;deref to instance data
	or	ds:[si][SI_attributes], mask CA_BLINK_LO
endif
	ret
ScreenBlinkOn	endm

ScreenReverseOn	method	ScreenClass, MSG_SCR_REV_ON
	mov	si, ds:[si]			;deref to instance data
	or	ds:[si][SI_attributes], mask CA_REV_LO
	ret
ScreenReverseOn	endm

ScreenUnderScoreOff	method	ScreenClass, MSG_SCR_UNDERSCORE_OFF
	mov	si, ds:[si]			;deref to instance data
	and	ds:[si][SI_attributes], not mask CA_UNDER_LO
	ret
ScreenUnderScoreOff	endm

ScreenReverseOff	method	ScreenClass, MSG_SCR_REV_OFF
	mov	si, ds:[si]			;deref to instance data
	and	ds:[si][SI_attributes], not mask CA_REV_LO
	ret
ScreenReverseOff	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenNormalMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put Term in normal mode

CALLED BY:	MSG_SCR_NORMAL_MODE

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	Brian Chin suggested that the GState not be changed to reflect the
	attribute byte.  He thought that the GState should only be changed
	when writing to the screen.  Well there was a bug cause 
	WinClearToEnd and WinClear both didn't check the attributes.  
	I think that when setting the mode to normal the GState can be
	changed immediately.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenNormalMode	method	ScreenClass, MSG_SCR_NORMAL_MODE
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
if	_CHAR_SET
	;
	; Normal mode only resets the character style attr, but not character
	; set. It clears all these attrs.
	;
	andnf	ds:[si][SI_attributes], \
		not (mask CA_BOLD_LO or mask CA_UNDER_LO or mask CA_REV_LO)
	call	SetTextStyleNormalAttr
else
	clr	ds:[si][SI_attributes]
	call	SetNormalAttribute
endif	; _CHAR_SET
	ret
ScreenNormalMode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenGoStatusCol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the given column in the status line

CALLED BY:	MSG_SCR_GO_STATUS_COL

PASS:		ds:*si		- screen instance data
		es		- dgroup
		ch		- col # to go to

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenGoStatusCol	method	ScreenClass, MSG_SCR_GO_STATUS_COL
	ret
ScreenGoStatusCol	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenTermInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Terminal initialization string

CALLED BY:	MSG_SCR_TERM_INIT

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/03/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenTermInit	method	ScreenClass, MSG_SCR_TERM_INIT
	ret
ScreenTermInit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSaneReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset terminal completely to sane modes

CALLED BY:	MSG_SCR_SANE_RESET

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	11/03/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenSaneReset	method	ScreenClass, MSG_SCR_SANE_RESET
	ret
ScreenSaneReset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenScrollBufEmpty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Empty out the scroll buffer 

CALLED BY:	MSG_SCR_SCROLLBUF_EMPTY

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		* When empty out the scroll buffer do you want to 
		* clear out the current screen?  currently doesn't do that 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/05/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenScrollBufEmpty	method	ScreenClass, MSG_SCR_SCROLLBUF_EMPTY
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	call	EraseCursor
if	not _CHAR_SET
	mov	ax, ds:[si][SI_scrollLines]	;scroll selected text
	call	ScrollSelectRegion
endif
	clr	ax	
	mov	ds:[si][SI_scrollLines], ax	;nuke scroll variables
	mov	ds:[si][SI_scrollTop], ax
	mov	ds:[si][SI_winTopLine], ax	;reposition current screen
	mov	ds:[si][SI_wrap], FALSE		;let ui scroll

	cmp	di, BOGUS_VAL
	je	exit
	call	GrGetWinBounds			;get top of window position
	neg	bx				;scroll back this amount
	push	di
	mov	dx, size PointDWord
	sub	sp, dx
	mov	bp, sp
	clr	ax				;don't scroll horizontally
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
	mov	ax, MSG_GEN_VIEW_SCROLL
	call	ObjMessage
	add	sp, size PointDWord
	pop	di
	call	WinInvalScreen			;redraw the whole screen
exit:
	ret
ScreenScrollBufEmpty	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenGraphicsOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn on graphics features

CALLED BY:	MSG_SCR_GRAPHICS_ON

PASS:		ds:*si		- screen instance data
		es		- dgroup

		if RESPONDER
			ch	- 1st arg
			cl	- 2nd arg
			dh	- 3rd arg
			dl	- 4th arg
			bp	- Number of arguments passed
		else
			dgroup:[argArray] arguments:
		endif
	
		Character attribute in arguments:
			0	: Turn off all attributes
			1 	: Bold Mode on
			4	: Underscore on	
			5	: ScreenBlinkOn
			7	: ScreenReverseOn

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
	for (each numeric argument) {
		Set the character attribute accordingly;
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/05/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenGraphicsOn	method	ScreenClass, MSG_SCR_GRAPHICS_ON
	
EC <	Assert_dgroup	es						>
	mov	cx, es:[argNum]			; arg counter
	mov	di, offset argArray		; es:di <- argArray

setAttrLoop:
	CheckHack <(size argArray) eq MAX_EMULATION_ARG>
EC <	push	di							>
EC <	sub	di, offset argArray					>
EC <	cmp	di, MAX_EMULATION_ARG					>
EC <	ERROR_AE TERM_TOO_MANY_ARGS_TO_FUNCTIONS			>
EC <	pop	di							>
	mov	ah, es:[di]				
	;
	; Set the graphics attribute according to the arguments. If arg
	; is not one of graphics attributes, ignore the argument and move on.
	;
	push	si, di
	cmp	ah, 1
	je	boldOn
	cmp	ah, 4
	je	underScoreOn
	cmp	ah, 5
	je	blinkOn
	cmp	ah, 7
	je	reverseOn
	tst	ah
	jz	normal
	jmp	endOfLoop
boldOn:
	call	ScreenBoldOn	
	jmp	short endOfLoop
underScoreOn:
	call	ScreenUnderScoreOn
	jmp	short endOfLoop
blinkOn:
	call	ScreenBlinkOn
	jmp	short endOfLoop
reverseOn:
	call	ScreenReverseOn
	jmp	short endOfLoop
normal:
	call	ScreenNormalMode		; si destroyed

endOfLoop:
	pop	si, di				; *ds:si<- screenObject
	inc	di				; es:di <- next argArray arg
	loop	setAttrLoop
	ret

ScreenGraphicsOn	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenMacro[1,2,3,4]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Execute user defined macros 

CALLED BY:	MSG_SCR_MACRO_[1,2,3,4]

PASS:		ds:*si		- screen instance data
		es		- dgroup

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	12/11/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenMacro1	method	ScreenClass, MSG_SCR_MACRO_1
	ret
ScreenMacro1	endm

ScreenMacro2	method	ScreenClass, MSG_SCR_MACRO_2
	ret
ScreenMacro2	endm

ScreenMacro3	method	ScreenClass, MSG_SCR_MACRO_3
	ret
ScreenMacro3	endm

ScreenMacro4	method	ScreenClass, MSG_SCR_MACRO_4
	ret
ScreenMacro4	endm

ScreenMacro5	method	ScreenClass, MSG_SCR_MACRO_5
	ret
ScreenMacro5	endm

ScreenMacro6	method	ScreenClass, MSG_SCR_MACRO_6
	ret
ScreenMacro6	endm

ScreenMacro7	method	ScreenClass, MSG_SCR_MACRO_7
	ret
ScreenMacro7	endm

ScreenMacro8	method	ScreenClass, MSG_SCR_MACRO_8
	ret
ScreenMacro8	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenAutoLinefeed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggle Auto Linefeed option.

CALLED BY:	MSG_SCR_AUTO_LINEFEED

PASS:		ds:*si		- screen instance data
		es		- dgroup
		cx		- selected booleans
		bp		- modified booleans

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/19/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenAutoLinefeedAndWrap	method	ScreenClass,
						MSG_SCR_AUTO_LINEFEED_AND_WRAP
	mov	es:[termOptions], cx
	mov	si, ds:[si]			;deref to instance data

	test	cx, mask LAW_WRAP
	jnz	wrapSet
	mov	ds:[si][SI_autoWrap], FALSE
	jmp	short skip
wrapSet:
	mov	ds:[si][SI_autoWrap], TRUE
skip:
	test	cx, mask LAW_LINEFEED
	jnz	feedSet
	mov	ds:[si][SI_autoLinefeed], FALSE
	jmp	short exit
feedSet:
	mov	ds:[si][SI_autoLinefeed], TRUE
exit:
	ret
ScreenAutoLinefeedAndWrap	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSetRow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set #lines of text displayed

CALLED BY:	MSG_SCR_SET_ROW

PASS:		ds:*si		- screen instance data
		es		- dgroup
		ch		- row position

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenSetRow	method	ScreenClass, MSG_SCR_SET_ROW
	;
	; CalcNumber may change 0 to -1.
	;
	cmp	ch, MAX_LINES
	jb	setRow
	cmp	ch, -1				; is it first row? \E[0H
	je	setDefRow
	mov	ch, MAX_LINES - 1		; max line#
	jmp	setRow	
	
setDefRow:
	clr	ch				; set default row
	
setRow:
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	mov	{byte} ds:[si][SI_curLine], ch
	clr	{byte}ds:[si][SI_curChar]	;default col is 1 if not
						;specified in this case
	call	EraseCursor			;erase the old cursor
	call	DrawCursor
	ret
ScreenSetRow	endm

ScreenSetCol	method	ScreenClass, MSG_SCR_SET_COL
	;
	; CalcNumber may change 0 to -1.
	;
	cmp	ch, MAX_LINE_CHARS
	jb	setCol
	cmp	ch, -1				; is it default col? \E[;0H?
	jne	setDefCol
	clr	ch				;set default col.
	jmp	setCol

setDefCol:
	mov	ch, MAX_LINE_CHARS - 1
	
setCol:
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
NCUR <	mov	{byte} ds:[si][SI_curChar], ch				>
CUR <	mov	{byte} ds:[si][SI_curPos], ch				>
CUR <	call	GetCurCharFromCurPos					>
	clr	{byte}ds:[si][SI_curLine]	;default row is 1 if not
						;specified in this case
	call	EraseCursor			;erase the old cursor
	call	DrawCursor
	ret
ScreenSetCol	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSetXN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Either clear or set flag that checks if Newlines at end of line
			should be ignored or not.

CALLED BY:	MSG_SCR_SET_XN

PASS:		ds:*si		- screen instance data
		es		- dgroup
		dh		- value to set flag with (TRUE/FALSE)

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/26/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenSetXN	method	ScreenClass, MSG_SCR_SET_XN
	mov	si, ds:[si]			;deref to instance data
	mov	ds:[si][SI_ignoreNL], dh
	ret
ScreenSetXN	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSetTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_SCR_SET_TAB

PASS:		ds:*si		- screen instance data

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/30/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenSetTab	method	ScreenClass, MSG_SCR_SET_TAB
	ret
ScreenSetTab	endm

ScreenClearTab	method	ScreenClass, MSG_SCR_CLEAR_TAB
	ret
ScreenClearTab	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenLostFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_LOST_FOCUS_EXCL

PASS:		ds:*si		- screen instance data

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	01/30/90	Initial version
	martin	8/18/93		Added SendTextFocusNotification

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenLostFocusExcl	method	dynamic	ScreenClass, 	MSG_META_LOST_FOCUS_EXCL
	.enter
	push	si
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	cmp	di, BOGUS_VAL			;if dorked forget this
	je	exit
	call	CheckCursorInSelect		;if cursor in select region
	jc	10$				;	don't dork it
	call	EraseCursor
10$:
	mov	ds:[si][SI_gotFocus], FALSE
	call	DrawSelectCursor		;unselect the text just	
exit:
	pop	si
	clr	bp
	call	SendScreenFocusNotification

	.leave
	ret
ScreenLostFocusExcl	endm

ScreenLostSysFocusExcl	method	dynamic	ScreenClass, MSG_META_LOST_SYS_FOCUS_EXCL
if USE_FEP
	tst	es:[fepStrategy].segment
	jz	noFep
	;
	; Call the FEP
	;
	sub	sp, size FepCallBackInfo
	mov	bp, sp
	mov 	cx, segment ScreenFepCallBack
	mov	dx, offset ScreenFepCallBack
	movdw	ss:[bp].FCBI_function, cxdx
	mov	cx, ds:[LMBH_handle]
	movdw	ss:[bp].FCBI_data, cxsi
	movdw	cxdx, ssbp
	mov	di, DR_FEP_LOST_FOCUS
	call	es:[fepStrategy]
	add	sp, size FepCallBackInfo
noFep:
endif
	ret
ScreenLostSysFocusExcl	endm

ScreenGainFocusExcl	method	dynamic	ScreenClass, 	MSG_META_GAINED_FOCUS_EXCL
	.enter
	push	si
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	call	CheckCursorInSelect		;if cursor in select region
	jc	10$				;	don't dork it
	call	EraseCursor
10$:
	mov	ds:[si][SI_gotFocus], TRUE
	call	DrawSelectCursor
	
	pop	si
	mov	bp, mask TFF_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	call	SendScreenFocusNotification

	.leave
	ret
ScreenGainFocusExcl	endm

ScreenGainedSysFocusExcl	method	dynamic	ScreenClass, MSG_META_GAINED_SYS_FOCUS_EXCL
if USE_FEP
	tst	es:[fepStrategy].segment
	jz	noFep
	;
	; Call the FEP
	;
	mov 	ax, segment ScreenFepCallBack
	mov	bx, offset ScreenFepCallBack
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	di, DR_FEP_GAIN_FOCUS
	call	es:[fepStrategy]
noFep:
endif
	ret
ScreenGainedSysFocusExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendScreenFocusNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the GWNT_EDITABLE_TEXT_OBJECT_HAS_FOCUS notification.

CALLED BY:	INTERNAL
PASS:		bp - data to send out
		*ds:si - ink obj
RETURN:
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	8/18/93		Initial revision (copied from text

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendScreenFocusNotification	proc	far	uses	si
	class	ScreenClass
	.enter

;	Check to see if the object is run by the UI thread - if so, set the
;	appropriate bit.

	clr	bx
	call	GeodeGetAppObject
	call	ObjTestIfObjBlockRunByCurThread
	jnz	notRunByUIThread
	ornf	bp, mask TFF_OBJECT_RUN_BY_UI_THREAD
notRunByUIThread:

;	Record event to send to ink controller

	mov	ax, MSG_META_NOTIFY
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	mov	di, mask MF_RECORD
	call	ObjMessage

	mov	ax, mask GCNLSF_SET_STATUS
	test	bp, mask  TFF_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	jnz	10$
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
10$:

;	Send it to the appropriate gcn list

	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_NOTIFY_FOCUS_TEXT_OBJECT
	clr	ss:[bp].GCNLMP_block
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, ax



;	If a UserDoDialog is running, the process thread could be blocked, so
;	send this directly to the app object.

	mov	ax, MSG_GEN_APPLICATION_CHECK_IF_RUNNING_USER_DO_DIALOG

	push	cx, dx, bp
	call	UserCallApplication
	pop	cx, dx, bp

	tst	ax			;If a UserDoDialog is active, send
	jnz	sendDirectly		; this directly on.
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	call	GeodeGetProcessHandle
common:
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, dx

	.leave
	ret
sendDirectly:
	clr	bx
	call	GeodeGetAppObject
	mov	ax, MSG_META_GCN_LIST_SEND
	jmp	common
SendScreenFocusNotification	endp

if	not _CHAR_SET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenLostTargetWinExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Visibily unselect the text because we lost the target excl

CALLED BY:	MSG_META_LOST_TARGET_EXCL

PASS:		ds:*si		- screen instance data

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenLostTargetWinExcl	method	ScreenClass, 	MSG_META_LOST_TARGET_EXCL
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	mov	cx, ss:[selEndLine]		;restore endline ptr
	call	UnHighlightArea			;unselect the area
	mov	ss:[selEndLine], cx		;restore endline ptr
	call	CheckCursorInSelect		;if cursor in select region
	jnc	exit				;	then its been erased
	mov	ds:[si][SI_cursorDrawn], FALSE	;	so redraw it
	call	DrawSelectCursor		;
exit:
	ret
ScreenLostTargetWinExcl	endm

ScreenGainTargetWinExcl	method	ScreenClass, 	MSG_META_GAINED_TARGET_EXCL
	tst	ss:[textSelected]		;if no area to re-select 
	je	exit				;then bail	
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	mov	cx, ss:[selEndCol]		;pass the area to select
	mov	dx, ss:[selEndLine]

	mov	ax, ss:[selStartCol]		;nuke the old selected area
	mov	ss:[selEndCol], ax
	mov	ax, ss:[selStartLine]
	mov	ss:[selEndLine], ax

	call	AdjustSelection			;select the new area
exit:
	ret
ScreenGainTargetWinExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle button presses

CALLED BY:	MSG_META_START_SELECT

PASS:		ds:*si	- screen instance data
		es	- dgroup
		ax	- MSG_META_START_SELECT
		cx	- x position (document coord)
		dx	- y position (document coord)
		bp	- button info

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		Unhighlight any selected area
		If was not a double click then
			Find nearest valid position to the press.
			Position cursor.
		else if was a double click then
			Find nearest character position to press.
			Find the word around the click.
			Set selection to surround word.
		endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	02/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenStartSelect	method	ScreenClass, 	MSG_META_START_SELECT
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState

	call	UnSelectArea			;unselect text
	call	ConvertToTextCoords		;
	mov	ss:[selStartCol], cx 		;save select start position
	mov	ss:[selEndCol], cx 		;save select start position
	mov	ss:[selStartLine], dx	;
	mov	ss:[selEndLine], dx 		;
	test	bp, mask BI_DOUBLE_PRESS	;
	jz	quit				;

	inc	ss:[dblClickCtr]
	cmp	ss:[dblClickCtr], CLICK_SELECT_WORD
	je	selWord
	cmp	ss:[dblClickCtr], CLICK_SELECT_LINE
	jne	done
	call	SelectLine			;select the current Line
	jmp	short done
selWord:
	call	SelectWord			;is there a word at mouse pos
	jmp	short done
quit:
	clr	ss:[dblClickCtr]		;reset ctr for consecutive
done:
	mov	ax, mask MRF_PROCESSED		;flag the mouse event handled
	ret
ScreenStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenDragSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle mouse dragging

CALLED BY:	MSG_META_DRAG_SELECT

PASS:		ds:*si	- screen instance data
		es	- dgroup
		ax	- MSG_META_DRAG_SELECT
		cx	- x position
		dx	- y position
		bp	- button info

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		Find the nearest coordinate for drag select

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	02/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenDragSelect	method	ScreenClass, 	MSG_META_DRAG_SELECT
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	mov	ss:[inDragSelect], TRUE		;
	call	ConvertToTextCoords		;
	call	AdjustSelection			;
	mov	ax, mask MRF_PROCESSED		;flag the mouse event handled
	ret
ScreenDragSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle mouse dragging

CALLED BY:	MSG_META_PTR

PASS:		ds:*si	- screen instance data
		es	- dgroup
		ax	- MSG_META_PTR
		cx	- x position
		dx	- y position
		bp low	- button info
		bp high	- UIFunctionsActive

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
	Make sure that text has been selected.
	This means that lastAddr contains the address of the last
	mouse position and lastPos contains the true position (for selecting)
	of that address.

	Since drag selecting can only mean inverting between the last
	position and the current one the basic selecting algorithm looks like
	this:
		bx     <- address of current drag position.
		cx, dx <- new true position.
		if (new drag address != old drag address) {
		    TextInvRangeCoords( new true position, old true position );
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/06/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenPtr	method	ScreenClass, 	MSG_META_PTR
	tst	ss:[inDragSelect]		; drag selection?
	jnz	dragSelect			; yes
	test	bp, mask UIFA_MOVE_COPY shl 8	; quick-transfer active?
	jz	exit				; nope
	call	ClipboardGetQuickTransferStatus	; actually in progress?
	jz	exit				; nope
;no more MSG_META_VIS_ENTER/MSG_META_VIS_LEAVE - brianc 4/6/92
;						; are we in the view?
;	test	ds:[bx].SI_intFlags, mask SIF_IN_VIEW
;	jz	exit				; no, skip feedback
	;
	; quick-transfer is active, provide feedback
	;
	call	CheckForTextItem	; check if CIF_TEXT supported
	;
	; assume so, do copy (if we are the source, we do copy because we
	; can't delete source text; if some other text object is the source,
	; default behavior is to do copy because source and destination are
	; different)
	; (move override is handled in ClipboardSetQuickTransferFeedback)
	;
	mov	ax, CQTF_COPY		; assume so
	jnc	haveCursor		; yes
	mov	ax, CQTF_CLEAR		; else, clear copy cursor
haveCursor:
	call	ClipboardSetQuickTransferFeedback	; pass bp
	ornf	ds:[bx].SI_intFlags, mask SIF_FEEDBACK_ON
	jmp	short exit
	
dragSelect:
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	call	ConvertToTextCoords		;
	call	AdjustSelection
	call	CheckCursorErased		;check if adjusting the select
exit:						; region erased the cursor
						;flag the mouse event handled
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	ret
ScreenPtr	endm
endif	; if !_CHAR_SET
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForTextItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if current quick-transfer item supports CIF_TEXT format

CALLED BY:	ScreenPtr

PASS:		nothing

RETURN:		carry clear if CIF_TEXT supported
		carry set if not

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/02/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForTextItem	proc	near
	uses	bx, cx, di, si, bp, es
	.enter
	mov	bp, mask CIF_QUICK
	call	ClipboardQueryItem		; bp = # formats, cx:dx = owner
						; bx:ax = VM file:VM block
	tst	bp
	stc					; in case no item
	jz	done				; no item (carry set)
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_TEXT
	call	ClipboardTestItemFormat		; is CIF_TEXT there?
						; (carry clear if so)
done:
	pushf					; save result flag
	call	ClipboardDoneWithItem
	popf					; retreive result flag
	.leave
	ret
CheckForTextItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle mouse dragging

CALLED BY:	MSG_META_END_SELECT

PASS:		ds:*si	- screen instance data
		es	- dgroup
		ax	- MSG_META_END_SELECT
		cx	- x position
		dx	- y position
		bp 	- button info

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	02/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenEndSelect	method	ScreenClass, 	MSG_META_END_SELECT
	mov	si, ds:[si]			;deref to instance data
	mov	di, ds:[si][SI_gState]		;get GState
	mov	ss:[inDragSelect], FALSE	;
	call    CheckSelectTopBottom            ;check select region pointers
	call	CheckCursorErased		;check if cursor got erased
	mov	ax, mask MRF_PROCESSED		;flag the mouse event handled
	ret
ScreenEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenEndMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle when selected text object scrap is dropped on us

CALLED BY:	MSG_META_END_MOVE_COPY

PASS:		ds:*si	- screen instance data
		es	- dgroup
		ax	- MSG_META_END_MOVE_COPY
		cx	- x position
		dx	- y position
		bp 	- button info

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	02/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenEndMoveCopy	method	ScreenClass, 	MSG_META_END_MOVE_COPY
	mov	cx, mask CIF_QUICK
	call	PasteText			; pass bp
						; returns ax = ClipboardQuickNotifyFlags
	mov	bp, ax
	call	ClipboardEndQuickTransfer		; stop quick transfer
	mov	ax, mask MRF_PROCESSED		;flag the mouse event handled
	ret
ScreenEndMoveCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenStartCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start a quick copy

CALLED BY:	MSG_META_START_MOVE_COPY

PASS:		ds:*si	- screen instance data
		es	- dgroup
		ax	- MSG_META_START_MOVE_COPY
		cx	- x mouse position
		dx	- y mouse position
		bp low 	- UIButtonFlags
		bp high - UIFunctionsActive

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	02/22/90	Initial version
	ted	12/1/92		MakeTransferItem doesn't return errors

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenStartCopy	method	ScreenClass, 	MSG_META_START_MOVE_COPY
	test	bp, mask UIFA_MOVE_COPY shl 8	;is this a move/copy event
	jz	exitJMP
	test	bp, mask UIFA_MOVE shl 8	;ignore if this is a move 
	LONG jnz	noCopy
	tst     ss:[textSelected]		;exit if no text selected
	jz      exitJMP
	push	si				;save ptr to instance data
	mov	si, ds:[si]
	call	ConvertToTextCoords
	call	CheckCoordInSelect		; C set if in selected region
	pop	si				;restore ptr to object data
	jnc	noCopy

if 	_TELNET
	jmp	10$
else
	cmp     ss:[serialPort], NO_PORT        ;don't start copy if no port
	jne     10$                             ;       opened
	segmov  ds, ss, bp
	clr     cx                              ;flag that String resouce should
	mov     dx, offset pasteErr             ;       be stuffed into cx
	mov     bp, ERR_NO_COM
	CallMod DisplayErrorMessage
endif	; !_TELNET
exitJMP:
	jmp     exit

10$:
	;
	;start the UI part of the quick move
	;
	push	si				; save instance handle
	mov	si, mask CQTF_COPY_ONLY		;set for copy preference
	mov	ax, CQTF_COPY			; set initial cursor
	call	ClipboardStartQuickTransfer
	pop	si				; retrieve instance handle
	jc	noCopy				; if quick-transfer already
						;	in progress, abort
	mov	bx, ds:[si]			; deref. instance handle
	ornf	ds:[bx].SI_intFlags, mask SIF_FEEDBACK_ON
	;
	; create and register quick-transfer item
	;
	call	MakeTransferItem		;ax = VM block, bx = VM file
	mov	ss:[inCopy], TRUE		;flag registering COPY item
	mov     bp, mask CIF_QUICK              ;not RAW, QUICK
	call    ClipboardRegisterItem
	jc	error				; handle error
	;
	; successfully started quick-transfer, allow mouse to roam to all
	; quick-transfer destinations
	;
	GetResourceHandleNS	TermView, bx
	mov	si, offset TermView
	mov	ax, MSG_GEN_VIEW_ALLOW_GLOBAL_TRANSFER
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	jmp	short exit

error:
	call	ScreenStopQuickTransferFeedback	; stop feedback
	segmov	ds, ss, bp			;we're dorked
	mov	bp, ERR_NO_MEM_TRANS_OBJ 
	CallMod	DisplayErrorMessage
noCopy:
	mov	ss:[inCopy], FALSE
exit:
	mov	ax, mask MRF_PROCESSED		;flag the mouse event handled
	ret
ScreenStartCopy	endm

;
; needed because View has 'grabWhilePressed' set and grabs on both
; MSG_META_START_MOVE_COPY and MSG_META_DRAG_MOVE_COPY, so we want to make
; sure that it is released
;
ScreenDragMoveCopy	method	ScreenClass, MSG_META_DRAG_MOVE_COPY
	cmp	ss:[inCopy], TRUE
	jne	done
	GetResourceHandleNS	TermView, bx
	mov	si, offset TermView
	mov	ax, MSG_GEN_VIEW_ALLOW_GLOBAL_TRANSFER
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
done:
	ret
ScreenDragMoveCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send selected text to UI 

CALLED BY:	MSG_META_CLIPBOARD_COPY

PASS:		ds:*si	- screen instance data
		es	- dgroup
		ax	- MSG_META_CLIPBOARD_COPY

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenCut	method	ScreenClass, 	MSG_META_CLIPBOARD_CUT
	ret
ScreenCut	endm

ScreenCopy	method	ScreenClass, 	MSG_META_CLIPBOARD_COPY
	tst     ss:[textSelected]               ;exit if no text selected
	jz      exit                            ;
	call	MakeTransferItem		;ax = VM block, bx = VM file
	clr     bp				;not RAW, not QUICK
	call    ClipboardRegisterItem
exit:
	ret
ScreenCopy	endm

ScreenPaste	method	ScreenClass, 	MSG_META_CLIPBOARD_PASTE
	clr	cx				;normal transfer
	call	PasteText
	ret
ScreenPaste	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenViewClosingQT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle closing of window, stop drag-selection and
		stop quick transfer

CALLED BY:	MSG_META_CONTENT_VIEW_CLOSING handler

PASS:		ds:*si - screen object

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/10/90	Initial version
	brianc	3/25/91		Updated for 2.0 quick-transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenViewClosingQT	proc	near
	uses	si
	.enter
	tst	ss:[inCopy]		; doing quick transfer?
	jz	notCopy			; nope
	call	ClipboardAbortQuickTransfer	; if so, stop quick transfer
	jmp	short done

notCopy:
	tst	ss:[inDragSelect]	; doing drag selection?
	jz	done			; nope
	call	ScreenEndSelect		; else, end drag selection
done:
	.leave
	ret
ScreenViewClosingQT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenStopQuickTransferFeedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL -
		clear move/copy cursor if doing quick transfer

CALLED BY:	MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL

PASS:		ds:bx - instance data

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/25/91	Initial version for 2.0 quick-transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenStopQuickTransferFeedback	method	ScreenClass, \
						MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL
	test	ds:[bx].SI_intFlags, mask SIF_FEEDBACK_ON
	jz	done			; feedback not occuring
;no more MSG_META_VIS_LEAVE - brianc 3/6/92
;	cmp	ax, MSG_META_VIS_LEAVE
;	jne	notVisLeave
;	;
;	; indicate that we have left the view, in case we get a few lingering
;	; MSG_PTRs, while waiting for MSG_GEN_VIEW_ALLOW_GLOBAL_TRANSFER
;	; to take effect
;	;
;	andnf	ds:[bx].SI_intFlags, not mask SIF_IN_VIEW
;notVisLeave:
	mov	ax, CQTF_CLEAR		; clear any move/copy cursor
	call	ClipboardSetQuickTransferFeedback
	andnf	ds:[bx].SI_intFlags, not mask SIF_FEEDBACK_ON
done:
	ret
ScreenStopQuickTransferFeedback	endm

;ScreenVisEnter	method	ScreenClass, MSG_META_VIS_ENTER
;	ornf	ds:[bx].SI_intFlags, mask SIF_IN_VIEW
;	ret
;ScreenVisEnter	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSetWinLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change #lines fit in a view	

CALLED BY:	MSG_SCR_SET_WIN_LINES

PASS:		ds:*si	- screen instance data
		es	- dgroup
		ax	- MSG_SCR_SET_WIN_LINES
		dx	- #lines to set

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
	if window doesn't need to be resized, 
		then exit
	else
		calc the new height
		(to save time) if window width has changed set that too
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenSetWinLines	method	ScreenClass, 	MSG_SCR_SET_WIN_LINES
	mov	cx, dx				; cx - number of lines
	mov	si, ds:[si]
	mov	ds:[si][SI_maxLines], cl	;store #lines in screen
	mov	{byte} ds:[si][SI_scrollRegBot], cl	;store bottom (0-CL)
	dec	ds:[si][SI_scrollRegBot]	;	line of scroll region
	mov	ax, ds:[si][SI_lineHeight]	;if window height hasn't changed
	mul	cl				;then
	cmp	ax, ds:[si][SI_winHeight]	; can exit
	je	exit				;
	mov	ds:[si][SI_winHeight], ax	;store the new window width
	push	ax				;and save it
	
	call	GetScreenWidth
	mov	cx, ax				;
	mov	ds:[si][SI_winWidth], cx	;  store it
	pop	dx				;  and resize the window
	call	ResetWindow
exit:
	ret
ScreenSetWinLines	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSetWinCols
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Changed #cols fit in a view

CALLED BY:	MSG_SCR_SET_WIN_COLS

PASS:		ds:*si	- screen instance data
		es	- dgroup
		ax	- MSG_SCR_SET_WIN_COLS
		dx	- #cols to set

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
	if window doesn't need to be resized
	then exit
	else	
		calc the new window height
		(to save time) if window width has changed set that too

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScreenSetWinCols	method	ScreenClass, 	MSG_SCR_SET_WIN_COLS
	mov	cx, dx				; cx - number of lines
	mov	si, ds:[si]
	mov	ds:[si][SI_maxCols], cl		;store #cols in screen
	mov	ax, ds:[si][SI_charWidth]	;if window width hasn't changed
	mul	cl				;then
	cmp	ax, ds:[si][SI_winWidth]	; can exit
	je	exit				;
	mov	ds:[si][SI_winWidth], ax
	push	ax				;save new width

	call	GetScreenHeight
	mov	dx, ax				;
	mov	ds:[si][SI_winHeight], dx	;and store it
	pop	cx				;get new width 
	call	ResetWindow			;and reset the window
exit:
	ret
ScreenSetWinCols	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSubviewChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle when the view size changes.

CALLED BY:	MSG_META_CONTENT_VIEW_SIZE_CHANGED

PASS:		ds:*si	- screen instance data
		es	- dgroup
		ax	- MSG_META_CONTENT_VIEW_SIZE_CHANGED
		cx	- document width
		dx	- document height

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	03/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenSubviewChange	method	ScreenClass, 	MSG_META_CONTENT_VIEW_SIZE_CHANGED
	mov	si, ds:[si]
	call	CheckViewSize
	ret
ScreenSubviewChange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenRecordOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bring up dialog box to ask user what he wants to capture 

CALLED BY:	MSG_SCR_RECORD_ON

PASS:		ds:*si	- screen instance data
		es	- dgroup
		ax	- MSG_SCR_RECORD_ON

RETURN:		ds:[si][SI_capHandle] != BOGUS_VAL if recording

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	04/24/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenRecordOn	method	ScreenClass, 	MSG_SCR_RECORD_ON
	push	ds, si
	segmov	ds, es, si			;set ds to dgroup
	GetResourceHandleNS	SaveAsFileSelector, dx	; dx:si = file selector
	mov	si, offset SaveAsFileSelector 	
	CallMod	SetFilePath			;set path of the selected file 
	jc	exit				;exit if path dorked
	GetResourceHandleNS	SaveAsTextEdit, dx	; dx:si = text object
	mov	si, offset SaveAsTextEdit	;
	CallMod	GetFileName			;
	jc	exit				;exit if filename dorked
	
	push	bx				; save filename block handle
	CallMod	CheckFileStatus
	pop	bx
	pushf
	call	MemFree				; free filename block
	popf
	jc	exit
	mov	cx, FILE_OVERWRITE
	GetResourceHandleNS	SaveAsTextEdit, dx	; dx:si = text object
	mov	si, offset SaveAsTextEdit
	CallMod	GetFileHandle			;get the file handle 
	jc	exit				;exit if can't 
	pop	ds, si
	mov	si, ds:[si]
	call	StartCapture
	jmp	short bye
exit:
	pop	ds, si	
bye:
	ret
ScreenRecordOn	endm

	



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              ScreenIgnoreEscapeSeq
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:     Do nothing for the parsed escape sequence

CALLED BY:    MSG_SCR_IGNORE_ESC_SEQ
PASS:         *ds:si  = ScreenClass object
              ds:di   = ScreenClass instance data
              es      = segment of ScreenClass
              ax      = message #
RETURN:               nothing
DESTROYED:    ax
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
      Name    Date            Description
      ----    ----            -----------
      simon   4/ 3/95         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenIgnoreEscapeSeq method dynamic ScreenClass, MSG_SCR_IGNORE_ESC_SEQ
              ret
ScreenIgnoreEscapeSeq endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenRenewGraphicsOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset graphics attributes and then set the new ones

CALLED BY:	MSG_SCR_RENEW_GRAPHICS_ON
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		es 	= segment of ScreenClass
		ax	= message #
		dgroup:[argArray] arguments:
			0	: Turn off all attributes
			1 	: Bold Mode on
			4	: Underscore on	
			5	: ScreenBlinkOn
			7	: ScreenReverseOn
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Reset graphics attributes;
	Set to the new ones;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	2/ 8/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenRenewGraphicsOn	method dynamic ScreenClass, 
					MSG_SCR_RENEW_GRAPHICS_ON
		.enter

		push	si, di
		call	ScreenNormalMode
		pop	si, di
		call	ScreenGraphicsOn

		.leave
		ret
ScreenRenewGraphicsOn	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenRenewScrollRegBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the top of scroll region and set the bottom to new
		value 

CALLED BY:	MSG_SCR_RENEW_SCROLL_REG_BOTTOM
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		es 	= segment of ScreenClass
		ax	= message #
		ch	= scroll reg bottom
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Use default scroll region top;
	Set the scroll region;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	2/ 9/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenRenewScrollRegBottom	method dynamic ScreenClass, 
					MSG_SCR_RENEW_SCROLL_REG_BOTTOM
		.enter

		clr	cl		; default scroll region top line
		xchg	cl, ch		; ch <- scroll region top
					; cl <- new scroll region bottom
		call	ScreenChangeScrollReg
	
		.leave
		ret
ScreenRenewScrollRegBottom	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenBringUpHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_BRING_UP_HELP must be handled be a GenClass object

CALLED BY:	MSG_META_BRING_UP_HELP
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		ds:bx	= ScreenClass object (same as *ds:si)
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	6/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenBringUpHelp	method dynamic ScreenClass, 
					MSG_META_BRING_UP_HELP
	GetResourceHandleNS TermPrimary, bx
	mov	si, offset TermPrimary
	clr	di
	GOTO	ObjMessage

ScreenBringUpHelp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenFepCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine for FEP

CALLED BY:	

PASS:		cx:dx	= optr of Screen object
		di	= FepCallBackFunction
		ss:sp	= FEP stack

RETURN:		depends on passed di

DESTROYED:	bx, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if USE_FEP
Fixed	segment	resource

ScreenFepCallBack	proc	far
	movdw	bxsi, cxdx			; ^lbx:si = Screen object
	call	cs:[ScreenFepCallBackTable][di]
	ret
ScreenFepCallBack	endp

ScreenFepCallBackTable	nptr.near	\
		ScreenFepGetTempTextBounds,	;FCBF_GET_TEMP_TEXT_BOUNDS
		ScreenFepGetTempTextAttr,	;FCBF_GET_TEMP_TEXT_ATTR
		ScreenFepInsertTempText,	;FCBF_INSERT_TEMP_TEXT
		ScreenFepDeleteText		;FCBF_DELETE_TEXT
.assert (size ScreenFepCallBackTable	eq FepCallBackFunction)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenFepGetTempTextBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	suggest bounds for the temp text window

CALLED BY:	ScreenFepCallBack

PASS:		^lbx:si = Screen object
		?

RETURN:		ax, bx = top left
		cx, dx  = bottom right
		si = layer ID
		bp = baseline offset
		carry = set iff bounds are invalid
		?

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenFepGetTempTextBounds	proc	near
	mov	ax, MSG_SCR_GET_FEP_TEMP_TEXT_BOUNDS
	mov	di, mask MF_CALL
	call	ObjMessage			; returns status in carry flag
	ret
ScreenFepGetTempTextBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenFepGetTempTextAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get temp text attributes for FEP

CALLED BY:	ScreenFepCallBack

PASS:		ss:bp = FepTempTextAttr to fill in
		^lbx:si = Screen object

RETURN:		ss:bp = FepTempTextAttr filled in
		carry = set iff data invalid

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenFepGetTempTextAttr	proc	near
	mov	ax, MSG_SCR_GET_FEP_TEMP_TEXT_ATTR
	mov	cx, ss				; cx:dx = FepTempTextAttr
	mov	dx, bp
	mov	di, mask MF_CALL
	call	ObjMessage			; returns status in carry flag
	ret
ScreenFepGetTempTextAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenFepInsertTempText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send the passed text to the serial port

CALLED BY:	ScreenFepCallBack

PASS:		^lbx:si = Screen object
		es:bp = text string to insert (Unicode)
		ax = number of characters

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenFepInsertTempText	proc	near
	push	ds, ax, cx, si
	mov	cx, ax				; cx = # chars
	GetResourceSegmentNS	dgroup, ds, ax	; ds = dgroup
	cmp	ds:[serialPort], NO_PORT
	jne	continue
	mov	ds:[scrKbdFepNoPortErr], BB_TRUE
	jmp	short done

continue:
	mov	si, bp				; es:si = text
	call	BufferedSendBuffer
done:
	pop	ds, ax, cx, si
	ret
ScreenFepInsertTempText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenFepDeleteText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	delete the N characters immediately before the current
		cursor position

CALLED BY:	ScreenFepCallBack

PASS:		^lbx:si = Screen object
		ax = number of characters to delete

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenFepDeleteText	proc	near
	;
	; nothing to do
	;
	ret
ScreenFepDeleteText	endp

Fixed	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenGetFepTempTextAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return character attributes of text at current position

CALLED BY:	MSG_SCR_GET_FEP_TEMP_TEXT_ATTR

PASS:		*ds:si - Screen object
		cx:dx - FepTempTextAttr to fill in
		ax - MSG_SCR_GET_FEP_TEMP_TEXT_ATTR

RETURN:		cx:dx - FepTempTextAttr filled in
		carry set if info not available

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/4/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenGetFepTempTextAttr	method	dynamic ScreenClass,
						MSG_SCR_GET_FEP_TEMP_TEXT_ATTR
	mov	si, ds:[si]			; ds:si = Screen object
	clr	ax
	mov	ah, {byte} ds:[si].SI_curLine	; ds:ax = start of line
SBCS <	shr	ax, 1							>
	add	ax, LINE_GRAFX_START		; ds:ax = start of line attrs
	add	ax, ds:[si].SI_curChar		; ds:ax = cur char attr
	mov	bx, ds:[si].SI_screenHandle
	mov	si, ax
	call	MemLock
	mov	ds, ax				; ds:si = cur char attr
	mov	al, ds:[si]			; al = cur char CharAttributes
	call	MemUnlock
	mov	es, cx				; es:di = FepTempTextAttr
	mov	di, dx
	segmov	ds, cs
	mov	si, offset screenFepTempTextAttr
	mov	cx, size FepTempTextAttr
	rep movsb				; copy over defaults
	mov	di, dx
	clr	ah
	test	al, mask CA_UNDER_LO
	jz	noUnder
	ornf	ah, mask TS_UNDERLINE
noUnder:
	test	al, mask CA_BOLD_LO
	jz	noBold
	ornf	ah, mask TS_BOLD
noBold:
	mov	es:[di].FTTA_textCharAttr.VTCA_textStyles, ah
	clc					; indicate info available
	ret
ScreenGetFepTempTextAttr	endm

screenFepTempTextAttr FepTempTextAttr <
	;FTTA_winAttributes (FepTempWindowAttr)
	<
		<0, 1>,			;FTWA_xScale (WWFixed)
		<0, 1>,			;FTWA_yScale (WWFixed)
		0,			;FTWA_winColorFlags (WinColorFlags)
		C_WHITE,		;FTWA_redOrIndex (byte)
		0,			;FTWA_green (byte)
		0			;FTWA_blue (byte)
	>,
	<
	;FTTA_textCharAttr (VisTextCharAttr)
		<>,			;VTCA_meta (StyleSheetElementHeader)
		TERM_FONT,		;VTCA_fontID (FontID)
		<0, 16>,		;VTCA_pointSize (WBFixed)
		0,			;VTCA_textStyles (TextStyle)
		<C_BLACK,CF_INDEX,0,0>,	;VTCA_color (ColorQuad)
		0,			;VTCA_trackKerning (sword)
		100,			;VTCA_fontWeight (byte)
		100,			;VTCA_fontWidth (byte)
		0,		;VTCA_extendedStyles (VisTextExtendedStyles)
		SDM_50,			;VTCA_grayScreen (SystemDrawMask)
		<PT_SOLID,0>,		;VTCA_pattern (GraphicPattern)
		<C_WHITE,CF_INDEX,0,0>,	;VTCA_bgColor (ColorQuad)
		SDM_50,			;VTCA_bgGrayScreen (SystemDrawMask)
		<PT_SOLID,0>,		;VTCA_bgPattern (GraphicPattern)
		0			;VTCA_reserved (byte 7 dup (0))
	>
>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenGetFepTempTextBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return bounds of text at current position

CALLED BY:	MSG_SCR_GET_FEP_TEMP_TEXT_BOUNDS

PASS:		*ds:si - Screen object
		ax - MSG_SCR_GET_FEP_TEMP_TEXT_BOUNDS
		?

RETURN:		?

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/4/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenGetFepTempTextBounds	method	dynamic ScreenClass,
					MSG_SCR_GET_FEP_TEMP_TEXT_BOUNDS
	stc
	ret
ScreenGetFepTempTextBounds	endm
endif


if	_SPECIAL_KEY

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSpecialKeyInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a special key

CALLED BY:	MSG_SCR_SPECIAL_KEY_INSERT
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenSpecialKeyInsert	method dynamic ScreenClass, 
					MSG_SCR_SPECIAL_KEY_INSERT
		.enter
	;
	; Query SpecialKeyList for the entry selected
	;
		push	si
		GetResourceHandleNS	TermSpecialKeyList, bx
		mov	si, offset TermSpecialKeyList
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage		; ax <- selection
EC <		tst	ah						>
EC <		ERROR_NZ TERM_INVALID_SPECIAL_KEY_SELECTION		>

		call	SpecialKeyListEntryToKOMBI  ; al <- KOMBI

		pop	si
		mov	di, ds:[si]
if	_TELNET
	;
	; If it is a telnet command, send it.
	;
		cmp	al, KOMBI_PF
		jae	nonTelnetCmd
		call	TelnetSendCommandKey	; carry set if error
		jmp	exit
	
nonTelnetCmd:
endif	; _TELNET
		
	;
	; If it is PF1-4, it sends out same escape codes no matter what
	;
		CheckHack <KOMBI_PF lt KOMBI_ENTER>
		cmp	al, KOMBI_ENTER
		jb 	sendAppKeys		; jmp if PF
	;
	; Reset terminal special key?
	;
		CheckHack < KOMBI_MINUS lt KOMBI_RESET>
		cmp	al, KOMBI_RESET
		je	resetTerm
	;
	; Ctrl character?
	;
		CheckHack <KOMBI_CTRL28 eq (KeypadOutMapBeginIndex-1)>
		cmp	al, KOMBI_CTRL28
		jb	testKeypadMode

		call	ScreenSendSpecialControlKey
		jmp	exit

resetTerm:
	;
	; Reset Terminal settings
	;
		call	ScreenResetVT		; ax,cx,dx,bp,si,di destroyed
		jmp	exit
	
testKeypadMode:
	;
	; Check out what keypad mode we are in and determine if we should
	; send out regular keys or escape codes.
	;
		CheckHack	<FALSE eq 0>
		BitTest	ds:[di][SI_modeFlags], SVTMF_KEYPAD
		jnz	sendAppKeys
	
		call	ScreenSendNumKeypadKey	; ax,bx,cx,dx,di,bp destroyed
		jmp	exit
	
sendAppKeys:
		call	ScreenSendAppKeypadKey
exit:
		.leave
		ret
ScreenSpecialKeyInsert	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpecialKeyListEntryToKOMBI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maps a selection number from the special keys list
		to the coresponding KeypadOutMapBeginEntry value

CALLED BY:	INTERNAL ScreenSpecialKeyInsert
PASS:		ax	= selection #
RETURN:		al	= KeypadOutMapBeginEntry
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	3/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpecialKeyListEntryToKOMBI	proc	near
	uses	bx,bp,si,ds
	.enter
		CheckHack <KOMBI_CTRL28+3 eq NUM_SPECIAL_KEYS-1>
					; Num special key is valid
	;
	; Deref the entry string block
	;
		mov_tr	bp, ax
		GetResourceHandleNS	SpecialKeyEntryStrings, bx
		call	MemLock			; ax<-stpr of string blk
		mov	ds, ax
		mov	si, offset SpecialKeyEntryStringsTable
		mov	si, ds:[si]		; ds:si<-fptr key string table
	;
	; calc offset to KOMBI entry for given selection
	;
		stc
		rcl	bp			; bp = index*2+1
		shl	bp			; bp = index*4+2
	;
	; Fetch KOMBI
	;
		mov 	al, {byte}ds:[si][bp]
	;
	; unlock string block
	;
		call	MemUnlock

	.leave
	ret
SpecialKeyListEntryToKOMBI	endp

endif	; if _SPECIAL_KEY

EmulationCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenRespondWhatAreYou
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to What Are You request

CALLED BY:	MSG_SCR_RESPOND_WHAT_ARE_YOU
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	ONLY VALID FOR VT100

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	4/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	;
	; The response is to Advanced Video Option (AVO) as default
	;
WhatAreYouResponseSeq	char	C_ESCAPE, "[?1;2c"

ScreenRespondWhatAreYou	method dynamic ScreenClass, 
					MSG_SCR_RESPOND_WHAT_ARE_YOU
		WAYEscCode	local	(size WhatAreYouResponseSeq) \
					dup (char)
						; Code to send (XIP happy)
		.enter
	;
	; Copy argument to send
	;
		segmov	ds, cs, ax
		mov	si, offset WhatAreYouResponseSeq
		segmov	es, ss, ax
		lea	di, ss:[WAYEscCode]
		copybuf <size WhatAreYouResponseSeq>
	;
	; Write the default response to this question.
	;
		lea	si, ss:[WAYEscCode]	; essi<-code to send
		mov	cx, size WhatAreYouResponseSeq
		GetResourceSegmentNS	dgroup, ds
		CallMod	SendBuffer		; es:si<-past text 
						; carry set if error
		.leave
		ret
ScreenRespondWhatAreYou	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenRespondCursorPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends current cursor position back to host

CALLED BY:	MSG_SCR_RESPOND_CURSOR_POSITION
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		ds:bx	= ScreenClass object (same as *ds:si)
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	For all terminal types:
		Arg 0 is the column (1-based)
		Arg 1 is row (1-based)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/18/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

vt100CursorPosReply	char	C_ESCAPE, "[%0;%1R", C_NULL
nullCursorPosReply	char	C_NULL

termCursorReplies	word	\
	offset	nullCursorPosReply,		; TTY
	offset	nullCursorPosReply,		; VT52
	offset	vt100CursorPosReply,		; VT100
	offset	nullCursorPosReply,		; WYSE50
	offset	nullCursorPosReply,		; ANSI
	offset	nullCursorPosReply,		; IBM3101
	offset	nullCursorPosReply		; TVI950

ScreenRespondCursorPosition	method dynamic ScreenClass, 
					MSG_SCR_RESPOND_CURSOR_POSITION
	.enter

	;
	; Load Col, Row into arg registers
	;
		mov	al, {byte}ds:[di].SI_curLine
		mov	ah, {byte}ds:[di].SI_curChar
		inc	al
		inc	ah
	;
	; Load up cursor position reply template for current terminal
	; type
	;
		segmov	ds, cs, bx
		GetResourceSegmentNS	dgroup, es, TRASH_BX
		mov	bl, es:[termType]
		clr	bh
		shl	bx, 1
		mov	si, ds:termCursorReplies[bx] ; ds:si <- reply template
	;
	; And spit out the reply
	;
		call	SendResponse
	.leave
	ret
ScreenRespondCursorPosition	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a string to the host, inserting numeric
		arguments as needed.

CALLED BY:	
PASS:		ds:si	= template buffer to send (null terminated)
				%0 - %7  = insert n'th argument
					as ascii decimal
		al,ah,bl,bh,cl,ch,dl,ch = args 0-7
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendResponse	proc	near
	uses	ax,bx,cx,dx,si,di

	SEND_RESPONSE_BUF_SIZE	equ	20
	SEND_MAX_ARG_SIZE	equ	4
	argsArray	local	8 dup (byte)
	sendBuf		local	SEND_RESPONSE_BUF_SIZE dup (char)

	.enter

	;
	; Load args into arg array
	;
		mov	{word}ss:argsArray[0], ax
		mov	{word}ss:argsArray[2], bx
		mov	{word}ss:argsArray[4], cx
		mov	{word}ss:argsArray[6], dx
	;
	; Set up to start stuffing the template into the send buffer
	;
		clr	cx			; cx = chars in output buf
		segmov	es, ss, ax
		lea	di, sendBuf		; es:di = next pos in output
stuffLoop:
		lodsb				; al = template char
		tst	al
		jz	endLoop
		cmp	al, '%'
		je	handleEsc
	;
	; Copy char from template to output
	;
		stosb
		inc	cx
		jmp	next
handleEsc:
	;
	; Insert argument N in output
	;
		lodsb				; al = N (ascii)
		sub	al, '0'
		Assert_urange	al, 0, 7
		clr	dx
		mov	bh, dl			; bx = N
		mov	bl, al
		xchg	bx, di
		mov	ah, dl
		mov	al, ss:argsArray[di]	; dx.ax = dword arg
		xchg	bx, di
		push	cx
		clr	cx			; no leading zeros, null
		call	UtilHex32ToAscii	; cx = length
EC <		cmp	cx, SEND_MAX_ARG_SIZE				>
EC <		ERROR_A	TERM_RESPONSE_ARGUMENT_TOO_LONG			>
		mov_tr	ax, cx
		add	di, ax
		pop	cx
		add	cx, ax
next:
	;
	; send buffer full?
	;
		cmp	cx, SEND_RESPONSE_BUF_SIZE-SEND_MAX_ARG_SIZE
		jle	stuffLoop
		call	sendBuffer
		jmp	stuffLoop
endLoop:
		call	sendBuffer

	.leave
	ret

;
; PASS: cx = # chars to send from sendBuf
;       es = segment sendBuf (ss)
;
; Return: cx = 0, di = reset to offset sendBuf
; 
sendBuffer	label	near

		lea	di, sendBuf		; reset output to beginning
		jcxz	sbExit
		push	ds, si
		segmov	ds, ss, si
		mov	si, di			; es:si = buffer
		CallMod	SendBuffer
		pop	ds, si			; ds:si = template
		clr	cx			; reset buffer to nothing
sbExit:
	ret

SendResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenResetMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To reset the modes like ANSI/VT52, Cursor key mode, etc

CALLED BY:	MSG_SCR_RESET_MODE
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		es 	= segment of ScreenClass
		ax	= message #
		ch	= TermVTModeType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Find out which mode flags to set/reset in tables indexed by
		TermType and TermMode
	Get the argument (which mode to reset);
	Set/Clear the internal flag according to the mode;

	This was written with VT100 in mind.  In particular, it
	assumes that the terminal mode values are fairly dense,
	and that "Set" means "turn the corresponding flag ON"
	When adding new terminal types, if this doesn't serve
	your purposes, feel free to change it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	2/23/96   	Initial version
	cthomas 4/2/96		rewrote to be table-driven

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DiddleInstanceParams	struct
	DIP_mode	word			  ; mode enum
	DIP_offset	word			  ; instance data field offset
	DIP_set		word			  ; bits to set/clear
DiddleInstanceParams	ends

ScreenResetMode	method dynamic ScreenClass,
					MSG_SCR_SET_MODE, 
					MSG_SCR_RESET_MODE
					
		.enter
		GetResourceSegmentNS	dgroup, es, TRASH_BX

	;
	; Find the mode flag table for the current terminal emulation
	;
		mov	bl, es:[termType]
		clr	bh
		shl	bx, 1
		mov	bx, cs:[vtModeTables][bx] ; cs:bx = mode table for term
		tst	bx
EC <		WARNING_Z TERM_FUNCTION_NOT_SUPPORTED			>
		jz	done
	;
	; Get the mode flags that correspond to the mode to set/reset
	;
		clr	cl
		xchg	ch, cl			  ; cx <- Mode type
		mov	dx, cs:[bx-(size word)]
		xchg	cx, dx			  ; cx <- list length
						  ; dx <- mode
		jcxz	done
		mov	si, bx
modeLoop:
		cmp	dx, cs:[si].DIP_mode
		jne	next
	;
	; Found an entry for this mode.  Diddle the instance data.
	;
		mov	bx, cs:[si].DIP_offset
		mov	bp, cs:[si].DIP_set
	;
	; Set / reset the mode flags as appropriate
	;
		cmp	ax, MSG_SCR_RESET_MODE
		je	reset

		ornf	ds:[di][bx], bp
		jmp	next
reset:
		not	bp
		andnf	ds:[di][bx], bp
next:
		add	si, size DiddleInstanceParams
		loop	modeLoop


done:
		.leave
		ret

ScreenResetMode	endm

.warn -private

vtModeTables	nptr.DiddleInstanceParams \
	0,					; TTY
	0,					; VT50
	offset vt100ModeTable,			; VT100
	0,					; WYSE50
	0,					; ANSI
	0,					; IBM3101
	0					; TVI950

CheckHack <length vtModeTables eq Terminals>

;
; These ModeTables map a mode enumeration to mode flags that should
; be turned on/off when the mode is set & reset.  The word before
; each table is the length of the table.  Don't separate them!
;

vt100ModeTableLength	word	length vt100ModeTable
vt100ModeTable	DiddleInstanceParams \
	<TVTMT_CURSOR_KEY,	SI_modeFlags,	mask SVTMF_CURSOR_KEY>,
	<TVTMT_ANSI_VT52,	SI_modeFlags,	mask SVTMF_ANSI_VT52>,
	<TVTMT_COLUMN,		SI_modeFlags,	mask SVTMF_COLUMN>,
	<TVTMT_SCROLLING,	SI_modeFlags,	mask SVTMF_SCROLLING>,
	<TVTMT_SCREEN,		SI_modeFlags,	mask SVTMF_SCREEN>,
	<TVTMT_ORIGIN,		SI_modeFlags,	mask SVTMF_ORIGIN>,
	<TVTMT_WRAPAROUND,	SI_autoWrap,	BB_TRUE>,
	<TVTMT_LINEFEED,	SI_modeFlags,	mask SVTMF_LF_NEWLINE>,
	<TVTMT_INTERLACE,	SI_modeFlags,	mask SVTMF_INTERLACE>,
	<TVTMT_AUTO_REPEAT,	SI_modeFlags,	mask SVTMF_AUTO_REPEAT>

.warn @private

EmulationCode	ends

if	_CHAR_SET
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSelectG0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select character set designator to G0

CALLED BY:	MSG_SCR_SELECT_G0
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenSelectG0	method dynamic ScreenClass, 
					MSG_SCR_SELECT_G0
		.enter
		mov	ds:[di][SI_charSetDesignator], CSD_G0
	;
	; See what character set G0 is having and set attr according
	;
		cmp	ds:[di][SI_G0CharSet], TCS_GRAPHICS
		je	graphics		; set graphics char
EC <		cmp	ds:[di][SI_G0CharSet], TCS_USASCII		>
EC <		ERROR_NE TERM_INVALID_CHARACTER_SET			>
	;
	; Set non-graphics font
	;
		call	ScreenSetUSASCIICommon
		jmp	exit
graphics:
	;
	; Set graphics font
	;
		call	ScreenSetGraphicsCommon
exit:
		.leave
		ret
ScreenSelectG0	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenSelectG1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select character set designator to G1

CALLED BY:	MSG_SCR_SELECT_G1
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenSelectG1	method dynamic ScreenClass, 
					MSG_SCR_SELECT_G1
		.enter
		mov	ds:[di][SI_charSetDesignator], CSD_G1
	;
	; See what character set G1 is having and set attr according
	;
		cmp	ds:[di][SI_G1CharSet], TCS_GRAPHICS
		je	graphics		; set graphics char
EC <		cmp	ds:[di][SI_G1CharSet], TCS_USASCII		>
EC <		ERROR_NE TERM_INVALID_CHARACTER_SET			>
	;
	; Set non-graphics font
	;
		call	ScreenSetUSASCIICommon
		jmp	exit
graphics:
	;
	; Set graphics font
	;
		call	ScreenSetGraphicsCommon
exit:
		.leave
		ret
ScreenSelectG1	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenG0SelectUSASCII
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Choose USASCII character set for G0

CALLED BY:	MSG_SCR_G0_SELECT_USASCII
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenG0SelectUSASCII	method ScreenClass, 
					MSG_SCR_G0_SELECT_USASCII
		.enter
		mov	ds:[di][SI_G0CharSet], TCS_USASCII
	;
	; If we are in G1, ignore
	;
		CheckHack	<CSD_G0 eq 0>	; assuming G0 is 0
		tst	ds:[di][SI_charSetDesignator]
		jnz	exit
		call	ScreenSetUSASCIICommon
exit:
		.leave
		ret
ScreenG0SelectUSASCII	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenG0SelectGraphics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Choose Special graphics character set for G0

CALLED BY:	MSG_SCR_G0_SELECT_GRAPHICS
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenG0SelectGraphics	method dynamic ScreenClass, 
					MSG_SCR_G0_SELECT_GRAPHICS
		.enter
		mov	ds:[di][SI_G0CharSet], TCS_GRAPHICS
	;
	; Check if we are in G1. If so, ignore
	;
		tst	ds:[di][SI_charSetDesignator]
		jnz	exit
		call	ScreenSetGraphicsCommon
exit:
		.leave
		ret
ScreenG0SelectGraphics	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenG1SelectUSASCII
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Choose USASCII character set for G1

CALLED BY:	MSG_SCR_G1_SELECT_USASCII
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenG1SelectUSASCII	method ScreenClass, 
					MSG_SCR_G1_SELECT_USASCII
		.enter
		mov	ds:[di][SI_G1CharSet], TCS_USASCII
	;
	; Check if we are in G1. If not, ignore chaging char attr
	;
		tst	ds:[di][SI_charSetDesignator]
		jz	exit			; G0, ignore
		call	ScreenSetUSASCIICommon
exit:
		.leave
		ret
ScreenG1SelectUSASCII	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenG1SelectGraphics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Choose Special graphics character set for G1

CALLED BY:	MSG_SCR_G1_SELECT_GRAPHICS
PASS:		*ds:si	= ScreenClass object
		ds:di	= ScreenClass instance data
		es 	= segment of ScreenClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	5/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenG1SelectGraphics	method dynamic ScreenClass, 
					MSG_SCR_G1_SELECT_GRAPHICS
		.enter
		mov	ds:[di][SI_G1CharSet], TCS_GRAPHICS
	;
	; If we are in G1, change the attr so that information can be stored.
	;
		tst	ds:[di][SI_charSetDesignator]
		jz	exit			; G0, ignore
		call	ScreenSetGraphicsCommon
exit:
		.leave
		ret
ScreenG1SelectGraphics	endm
		
endif	; if _CHAR_SET


